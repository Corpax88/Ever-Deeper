import {webkit} from '@playwright/test';
import http from 'node:http';
import {readFile, writeFile, mkdir} from 'node:fs/promises';
import path from 'node:path';
const [rootArg, outputArg, area = 'hub'] = process.argv.slice(2);
const root = path.resolve(rootArg), output = path.resolve(outputArg);
await mkdir(output, {recursive: true});
const logs = [], errors = [], captures = [];
const takeCaptures = false;
const control = process.env.PROBE_SKIP_CONTEXT === '1';
let complete = false, touchDone = false, resizeStarted = false, resizeRestored = false;
const server = http.createServer(async (req, res) => {
  try {
    const name = new URL(req.url, 'http://localhost').pathname;
    const file = path.resolve(root, '.' + (name === '/' ? '/index.html' : name));
    if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
    let data = await readFile(file);
    if (file.endsWith('.html') && control) data = Buffer.from(data.toString().replace("gl = canvas.getContext('webgl2');", '/* Control: omit context observer; reported buffer dimensions remain zero. */'));
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
  if (process.env.PROBE_GL_TRACE === '1') await page.addInitScript(() => {
    const proto = WebGL2RenderingContext.prototype, original = proto.blitFramebuffer;
    const ids = new WeakMap(); let nextId = 1, calls = 0;
    const id = value => { if (!value) return null; if (!ids.has(value)) ids.set(value, nextId++); return ids.get(value); };
    proto.blitFramebuffer = function(...args) {
      const read = this.getParameter(this.READ_FRAMEBUFFER_BINDING), draw = this.getParameter(this.DRAW_FRAMEBUFFER_BINDING);
      const readImage = read ? this.getFramebufferAttachmentParameter(this.READ_FRAMEBUFFER, this.COLOR_ATTACHMENT0, this.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME) : null;
      const drawImage = draw ? this.getFramebufferAttachmentParameter(this.DRAW_FRAMEBUFFER, this.COLOR_ATTACHMENT0, this.FRAMEBUFFER_ATTACHMENT_OBJECT_NAME) : null;
      if (++calls <= 12) console.log('PROBE_GL_BLIT ' + JSON.stringify({calls,read:id(read),draw:id(draw),readImage:id(readImage),drawImage:id(drawImage),args,stack:new Error().stack}));
      return original.apply(this,args);
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
    if (/^PROBE_(START_STATE|BROWSER_BEGIN|GL_BLIT)/.test(value)) console.log(value);
    if (/SCRIPT ERROR|Parse Error|^ERROR:|INVALID_OPERATION|INVALID_FRAMEBUFFER_OPERATION|WebGL.*error/i.test(value)) errors.push(value);
    if (value.startsWith('RENDER_PROBE_REVIEW_OK ')) complete = true;
    if (takeCaptures && value.startsWith('PROBE_STAGE_READY ')) {
      const event = JSON.parse(value.slice('PROBE_STAGE_READY '.length));
      captures.push(page.screenshot({path: path.join(output, `${area}-${event.stage}.png`)}).catch(error => errors.push(String(error))));
    }
  });
  await page.goto(`http://127.0.0.1:${server.address().port}/`);
  const began = Date.now();
  const deadline = began + 20000;
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
  const observation = {control_without_context_observer: control, seconds: (Date.now()-began)/1000, errors, complete,
    phase: await page.evaluate(() => window.everDeeperRenderProbe?.snapshot())};
  await writeFile(path.join(output, 'control.json'), JSON.stringify(observation,null,2));
  console.log('GL_CONTEXT_CONTROL ' + JSON.stringify(observation));
  if (errors.length) process.exitCode = 1;

} finally {
  await writeFile(path.join(output, 'browser-console.json'), JSON.stringify({complete, errors, logs}, null, 2));
  if (page && takeCaptures) await page.screenshot({path: path.join(output, 'browser-last.png')}).catch(() => {});
  await browser.close(); server.close();
}
