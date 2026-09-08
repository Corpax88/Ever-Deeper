import {webkit} from '@playwright/test';
import http from 'node:http';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import path from 'node:path';
const [rootArg, outputArg, area = 'hub'] = process.argv.slice(2);
const root = path.resolve(rootArg), output = path.resolve(outputArg);
await mkdir(output, {recursive: true});
const logs = [], errors = [], glWarnings = [], captures = [], surfaces = [];
const takeCaptures = process.env.PROBE_SCREENSHOTS !== '0';
let complete = false, touchDone = false, resizeStarted = false, resizeRestored = false;
const server = http.createServer(async (req, res) => {
  try {
    const name = new URL(req.url, 'http://localhost').pathname;
    const file = path.resolve(root, '.' + (name === '/' ? '/index.html' : name));
    if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
    let data = await readFile(file);
    if (file.endsWith('/index.js')) {
      const original = data.toString(), needle = 'context.defaultFboForbidBlitFramebuffer=false';
      if (original.split(needle).length !== 2) throw new Error('Unexpected engine; presentation control requires one exact match');
      data = Buffer.from(original.replace(needle,'context.defaultFboForbidBlitFramebuffer=true'));
      console.log('PRESENTATION_CONTROL: built-in textured-quad path, engine package on disk unchanged');
    }
    if (file.endsWith('.html')) data = Buffer.from(data.toString().replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/, (_, raw) => {
      const config = JSON.parse(raw);
      config.args = ['--audio-driver', 'Dummy', '--', '--qa-mobile-performance', '--perf-render-probe-review', `--probe-area=${area}`];
      return 'const GODOT_CONFIG = ' + JSON.stringify(config) + ';';
    }));
    res.writeHead(200, {'Content-Type': file.endsWith('.wasm') ? 'application/wasm' : file.endsWith('.js') ? 'text/javascript' : file.endsWith('.html') ? 'text/html' : 'application/octet-stream',
      'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp'}).end(data);
  } catch { res.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const browser = await webkit.launch({headless: true});
let page;
try {
  page = await browser.newPage({viewport: {width: 844, height: 390}, deviceScaleFactor: 3, isMobile: true, hasTouch: true});
  await page.bringToFront();
  // Observe the engine's initial context creation without requesting a context ourselves.
  await page.addInitScript(() => {
    const proto = HTMLCanvasElement.prototype, original = proto.getContext;
    proto.getContext = function(type, ...args) {
      const context = original.call(this, type, ...args);
      if (this.id === 'canvas' && type === 'webgl2' && context) {
        window.__renderProbeGL = context;
        proto.getContext = original;
      }
      return context;
    };
  });
  await page.addInitScript(() => {
    let api;
    Object.defineProperty(window, 'everDeeperRenderProbe', {configurable: true,
      get: () => api, set(value) {
        api = value;
        const begin = api.begin.bind(api);
        api.begin = () => {
          const result = begin();
          console.log('PROBE_BROWSER_BEGIN ' + JSON.stringify({result, hidden: document.hidden, visibility: document.visibilityState, state: api.snapshot()}));
          return result;
        };
      }});
  });
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => {
    const value = message.text(); logs.push(value);
    if (/^PROBE_(START_STATE|BROWSER_BEGIN)/.test(value)) console.log(value);
    if (value === 'WebGL: INVALID_OPERATION: glBlitFramebuffer: Read and write color attachments cannot be the same image.') glWarnings.push({time:Date.now(),message:value});
    else if (/SCRIPT ERROR|Parse Error|^ERROR:|INVALID_OPERATION|INVALID_FRAMEBUFFER_OPERATION|WebGL.*error/i.test(value)) errors.push(value);
    if (value.startsWith('RENDER_PROBE_REVIEW_OK ')) complete = true;
    if (value.startsWith('PROBE_STAGE_READY ')) {
      const event = JSON.parse(value.slice('PROBE_STAGE_READY '.length));
      captures.push((async () => {
        const surface = await page.evaluate(() => ({width:document.querySelector('canvas').width, height:document.querySelector('canvas').height,
          bufferWidth:window.__renderProbeGL?.drawingBufferWidth, bufferHeight:window.__renderProbeGL?.drawingBufferHeight}));
        surfaces.push({stage:event.stage,...surface});
        if (surface.width !== surface.bufferWidth || surface.height !== surface.bufferHeight) errors.push('Drawing buffer mismatch: '+JSON.stringify(surface));
        if (takeCaptures) await page.screenshot({path: path.join(output, `${area}-${event.stage}.png`)});
      })().catch(error => errors.push(String(error))));
    }
  });
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  const deadline = Date.now() + 300000;
  while (!complete && !errors.length && Date.now() < deadline) {
    const state = await page.evaluate(() => ({target: window.__renderProbeTouchTarget,
      resize: window.__renderProbeResizeReady, resizeDone: window.__renderProbeResizeDone}));
    if (state.target && !touchDone) {
      touchDone = true;
      if (!(state.target.x > 0 && state.target.x < 844 && state.target.y > 0 && state.target.y < 390)) throw new Error('Invalid mobile touch coordinates: ' + JSON.stringify(state.target));
      await page.touchscreen.tap(state.target.x, state.target.y);
    }
    if (state.resize && !resizeStarted) { resizeStarted = true; await page.setViewportSize({width: 852, height: 393}); }
    if (state.resizeDone && !resizeRestored) {
      resizeRestored = true; await page.setViewportSize({width: 844, height: 390});
      await page.waitForTimeout(750);
      await page.evaluate(() => { window.__renderProbeResizeRestored = true; });
    }
    await page.waitForTimeout(200);
  }
  await Promise.all(captures);
  if (!complete || errors.length || !touchDone || !resizeRestored) throw new Error(JSON.stringify({complete, errors, glWarnings, touchDone, resizeRestored}));
  const state = await page.evaluate(() => ({report: window.everDeeperRenderProbeResult,
    canvas: {w: document.querySelector('canvas').width, h: document.querySelector('canvas').height, dpr: devicePixelRatio, bufferWidth:window.__renderProbeGL?.drawingBufferWidth, bufferHeight:window.__renderProbeGL?.drawingBufferHeight}}));
  if (state.canvas.w !== 2532 || state.canvas.h !== 1170 || state.canvas.dpr !== 3) throw new Error('DPR/canvas not restored: ' + JSON.stringify(state.canvas));
  if (surfaces.length !== 9 || state.canvas.bufferWidth !== 2532 || state.canvas.bufferHeight !== 1170) throw new Error('Missing physical drawing-buffer checks');
  if (!state.report.graphics_restored || state.report.rows.length !== 9 || state.report.rows.some(row => row.raf_frames < 3 || row.raf_fps <= 0)) throw new Error('Missing restored settings or RAF samples');
  if (takeCaptures) await page.screenshot({path: path.join(output, `${area}-result.png`)});
  await writeFile(path.join(output, 'webkit.json'), JSON.stringify({passed: glWarnings.length === 0, functional_checks_passed:true, area, ...state, surfaces, touchDone, resizeRestored, glWarnings}, null, 2));
  if (glWarnings.length) throw new Error('WebGL warnings remain a failed review gate: '+JSON.stringify(glWarnings));
  console.log('RENDER_PROBE_WEBKIT_OK ' + JSON.stringify(state.canvas));
} finally {
  await writeFile(path.join(output, 'browser-console.json'), JSON.stringify({complete, errors, glWarnings, logs}, null, 2));
  if (page && takeCaptures) await page.screenshot({path: path.join(output, 'browser-last.png')}).catch(() => {});
  await browser.close(); server.close();
}
