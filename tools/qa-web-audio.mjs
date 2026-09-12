#!/usr/bin/env node
// Exact-package Web Audio lifecycle and nonzero output audit; no listening claim.
import { chromium, webkit } from '@playwright/test';
import { createHash } from 'node:crypto';
import { createReadStream } from 'node:fs';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import http from 'node:http';
import path from 'node:path';
import assert from 'node:assert/strict';

const [directory, outputDirectory, browserName] = process.argv.slice(2);
assert(directory && outputDirectory && ['webkit', 'chromium'].includes(browserName), 'Usage: qa-web-audio.mjs WEB_DIR OUTPUT_DIR webkit|chromium');
const root = path.resolve(directory), output = path.resolve(outputDirectory);
await mkdir(output, { recursive: true });
const hash = async name => createHash('sha256').update(await readFile(path.join(root, name))).digest('hex');
const identity = { pckSha256: await hash('index.pck'), htmlSha256: await hash('index.html') };
const logs = [], errors = [];
const report = { passed: false, browser: browserName, ...identity, checks: {}, subjective_listening_verified: false, physical_iphone_verified: false };
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm', '.png': 'image/png' };
const server = http.createServer(async (request, response) => {
  try {
    const pathname = decodeURIComponent(new URL(request.url, 'http://localhost').pathname);
    const filename = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
    if (!filename.startsWith(root + path.sep)) { response.writeHead(403).end(); return; }
    response.setHeader('Content-Type', mime[path.extname(filename)] || 'application/octet-stream');
    response.setHeader('Cross-Origin-Opener-Policy', 'same-origin');
    response.setHeader('Cross-Origin-Embedder-Policy', 'require-corp');
    response.setHeader('Cache-Control', 'no-store');
    if (filename.endsWith('/index.html')) {
      const html = (await readFile(filename, 'utf8')).replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/, (_, raw) => {
        const config = JSON.parse(raw);
        // Keep the production Audio backend. Only the opt-in QA arguments change.
        config.args = ['--', '--visual-capture-suite', '--web-audio-review'];
        return 'const GODOT_CONFIG = ' + JSON.stringify(config) + ';';
      });
      response.end(html);
    } else {
      const stream = createReadStream(filename);
      stream.on('error', () => response.destroy());
      stream.pipe(response);
    }
  } catch (error) { response.writeHead(500).end(String(error)); }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const browser = await (browserName === 'webkit' ? webkit : chromium).launch({ headless: true });
let page;
try {
  page = await browser.newPage({ viewport: { width: 844, height: 390 }, hasTouch: true, isMobile: true });
  report.browser_version = browser.version();
  page.on('pageerror', error => errors.push(String(error)));
  page.on('console', message => {
    const line = message.text(); logs.push(line);
    if (/SCRIPT ERROR|Parse Error|(^|\n)ERROR:/.test(line)) errors.push(line);
  });
  await page.addInitScript(() => {
    const probe = window.__webAudioQA = { contexts: [], sources: [], samples: [], phase: 'boot', trustedUnlock: false, unlocked: false };
    const Native = window.AudioContext || window.webkitAudioContext;
    probe.supported = !!Native && !!window.AudioNode && !!window.AnalyserNode;
    if (!probe.supported) return;
    const connect = AudioNode.prototype.connect;
    AudioNode.prototype.connect = function (destination, ...rest) {
      const entry = probe.contexts.find(item => item.context === this.context);
      if (entry && destination === this.context.destination && this !== entry.analyser) {
        connect.call(this, entry.analyser, ...rest);
        return destination;
      }
      return connect.call(this, destination, ...rest);
    };
    const instrument = context => {
      const analyser = context.createAnalyser();
      analyser.fftSize = 2048;
      connect.call(analyser, context.destination);
      const entry = { context, analyser, values: new Float32Array(2048), id: probe.contexts.length };
      probe.contexts.push(entry);
      const makeSource = context.createBufferSource.bind(context);
      context.createBufferSource = (...args) => {
        const source = makeSource(...args);
        const start = source.start.bind(source), stop = source.stop.bind(source);
        let record;
        source.start = (...startArgs) => {
          const buffer = source.buffer;
          let square = 0, peak = 0, count = 0;
          if (buffer) for (let channel = 0; channel < buffer.numberOfChannels; channel++) {
            const pcm = buffer.getChannelData(channel);
            for (const value of pcm) { square += value * value; peak = Math.max(peak, Math.abs(value)); count++; }
          }
          record = { id: probe.sources.length, context: entry.id, phase: probe.phase, start: context.currentTime, wallStart: performance.now(), duration: buffer?.duration || 0, rate: source.playbackRate.value, loop: source.loop, pcmRms: Math.sqrt(square / Math.max(1, count)), pcmPeak: peak, stop: null, end: null };
          probe.sources.push(record);
          source.addEventListener('ended', () => { record.end = context.currentTime; });
          return start(...startArgs);
        };
        source.stop = (...stopArgs) => { if (record) record.stop = context.currentTime; return stop(...stopArgs); };
        return source;
      };
      return context;
    };
    const Wrapped = new Proxy(Native, { construct(target, args) { return instrument(Reflect.construct(target, args, target)); } });
    window.AudioContext = Wrapped;
    if (window.webkitAudioContext) window.webkitAudioContext = Wrapped;
    setInterval(() => {
      for (const entry of probe.contexts) {
        entry.analyser.getFloatTimeDomainData(entry.values);
        let square = 0, peak = 0;
        for (const value of entry.values) { square += value * value; peak = Math.max(peak, Math.abs(value)); }
        if (probe.samples.length < 5000) probe.samples.push({ phase: probe.phase, context: entry.id, time: entry.context.currentTime, rms: Math.sqrt(square / entry.values.length), peak });
      }
    }, 15);
  });
  await page.goto(`http://127.0.0.1:${server.address().port}/`, { waitUntil: 'domcontentloaded', timeout: 180000 });
  await page.waitForFunction(() => typeof window.everDeeperAudioReviewCommand === 'function', undefined, { timeout: 180000 });
  const initial = await page.evaluate(() => ({ state: window.everDeeperAudioReviewState, supported: window.__webAudioQA.supported, contexts: window.__webAudioQA.contexts.length }));
  assert(initial.supported && initial.contexts > 0, 'Browser created no supported real AudioContext');
  assert(initial.state.sample_backend && !initial.state.headless && initial.state.voices === 10, 'Actual ten-voice SAMPLE backend required');
  assert.equal(initial.state.version, process.env.EXPECTED_VERSION || '1.0.0-dev.6');
  report.initial = initial;
  await page.evaluate(() => {
    const button = document.createElement('button'); button.id = 'audio-review-unlock'; button.textContent = 'Start audio review';
    Object.assign(button.style, { position: 'fixed', top: '10px', left: '10px', zIndex: 100000, padding: '20px' });
    button.addEventListener('click', async event => {
      window.__webAudioQA.trustedUnlock = event.isTrusted;
      window.__webAudioQA.samples = [];
      await Promise.all(window.__webAudioQA.contexts.map(entry => entry.context.resume()));
      window.__webAudioQA.unlocked = true;
      button.remove();
    });
    document.body.appendChild(button);
  });
  await page.locator('#audio-review-unlock').tap();
  await page.waitForFunction(() => window.__webAudioQA.unlocked && window.__webAudioQA.contexts.every(entry => entry.context.state === 'running'));
  assert(await page.evaluate(() => window.__webAudioQA.trustedUnlock), 'Unlock must originate in a trusted touch gesture');
  report.checks.trusted_gesture_unlock = true;
  const command = async (operation, phase = operation) => page.evaluate(({ operation, phase }) => {
    window.__webAudioQA.phase = phase;
    window.everDeeperAudioReviewCommand(operation);
    return window.everDeeperAudioReviewState;
  }, { operation, phase });
  const sample = () => page.evaluate(() => ({ sources: window.__webAudioQA.sources, samples: window.__webAudioQA.samples, state: window.everDeeperAudioReviewState, contexts: window.__webAudioQA.contexts.map(entry => ({ state: entry.context.state, time: entry.context.currentTime, sampleRate: entry.context.sampleRate })) }));
  const audible = (snapshot, phase) => snapshot.samples.some(row => row.phase === phase && row.rms > 0.00005);
  await command('reset', 'baseline');
  await page.waitForTimeout(150);
  let state = await command('cluster');
  assert.equal(state.playing.filter(voice => voice.group === 'pickup').length, 1);
  assert.equal(state.playing.filter(voice => voice.group === 'pickup_rare').length, 1);
  await page.waitForTimeout(450);
  let measured = await sample();
  const cluster = measured.sources.filter(source => source.phase === 'cluster');
  assert.equal(cluster.length, 2, 'Common and rare collection must create two actual sources, with rare burst throttled');
  assert(cluster.every(source => source.pcmRms > 0 && source.end !== null), 'Both pickup samples must contain and complete real audio');
  assert(audible(measured, 'cluster'), 'Pickup calls produced no nonzero destination signal');
  report.checks.same_cluster_common_and_rare_output = true;
  await command('reset');
  await command('discovery');
  await page.waitForFunction(() => window.__webAudioQA.sources.some(source => source.phase === 'discovery'));
  await page.waitForTimeout(70);
  measured = await sample();
  const discovery = measured.sources.filter(source => source.phase === 'discovery').at(-1);
  assert(discovery.duration > 0.85 && discovery.pcmRms > 0 && audible(measured, 'discovery'), 'Discovery must create audible authored sample');
  state = await page.evaluate(async () => {
    window.__webAudioQA.phase = 'overlap';
    for (let index = 0; index < 12; index++) {
      window.everDeeperAudioReviewCommand(index % 2 ? 'pickup' : 'mining');
      await new Promise(resolve => setTimeout(resolve, 60));
    }
    window.everDeeperAudioReviewCommand('snapshot');
    return window.everDeeperAudioReviewState;
  });
  measured = await sample();
  const ongoing = measured.sources.find(source => source.id === discovery.id);
  assert(state.playing.some(voice => voice.group === 'discovery'), 'Mining/pickup overlap cut the real discovery voice');
  assert(ongoing.stop === null && ongoing.end === null, 'Browser discovery source stopped early');
  assert(measured.sources.filter(source => source.phase === 'overlap').length >= 10, 'Overlap fixture did not start enough actual effects');
  assert(audible(measured, 'overlap'), 'Overlapping effects produced no destination signal');
  await page.waitForFunction(id => window.__webAudioQA.sources.find(source => source.id === id)?.end !== null, discovery.id);
  measured = await sample();
  const ended = measured.sources.find(source => source.id === discovery.id);
  assert(ended.end - ended.start >= ended.duration / ended.rate - 0.06, 'Discovery did not reach its natural duration');
  report.checks.discovery_survives_actual_effect_overlap = true;
  report.discovery = ended;
  await command('reset');
  await command('upgrade');
  await page.waitForTimeout(100);
  measured = await sample();
  assert(audible(measured, 'upgrade'), 'Upgrade cue produced no nonzero output');
  state = await command('mute');
  assert(state.muted && state.playing.length === 0, 'Mute did not stop active actual players');
  await page.waitForTimeout(150);
  const beforeMutedAttempt = (await sample()).sources.length;
  await command('pickup', 'muted');
  await page.waitForTimeout(150);
  measured = await sample();
  assert.equal(measured.sources.length, beforeMutedAttempt, 'Muted pickup created a new source');
  const mutedSamples = measured.samples.filter(row => row.phase === 'muted');
  assert(mutedSamples.length >= 3 && mutedSamples.every(row => row.rms < 0.00001), 'Mute did not leave the destination signal silent');
  report.checks.mute_stops_output_and_blocks_new_effects = true;
  await command('unmute');
  await command('pickup', 'unmuted');
  await page.waitForTimeout(150);
  measured = await sample();
  assert(audible(measured, 'unmuted'), 'Feedback did not resume after unmute');
  report.checks.unmute_restores_actual_output = true;
  await command('finish');
  assert(measured.contexts.every(context => context.state === 'running' && context.time > 1), 'AudioContext did not advance');
  assert.equal(await hash('index.pck'), identity.pckSha256);
  assert.equal(await hash('index.html'), identity.htmlSha256);
  assert.deepEqual(errors, []);
  report.passed = true;
} catch (error) {
  report.failure = String(error.stack || error);
  process.exitCode = 1;
} finally {
  if (page && !page.isClosed()) {
    report.measurements = await page.evaluate(() => {
      const probe = window.__webAudioQA;
      if (!probe) return null;
      return { supported: probe.supported, sources: probe.sources, samples: probe.samples, trustedUnlock: probe.trustedUnlock, contexts: probe.contexts.map(entry => ({ state: entry.context.state, time: entry.context.currentTime, sampleRate: entry.context.sampleRate })) };
    }).catch(error => ({ unavailable: String(error) }));
  }
  report.errors = errors;
  await writeFile(path.join(output, 'web-audio.json'), JSON.stringify(report, null, 2));
  await writeFile(path.join(output, 'browser-console.json'), JSON.stringify(logs, null, 2));
  await browser.close();
  await new Promise(resolve => server.close(resolve));
  console.log(`WEB_AUDIO_REVIEW_${report.passed ? 'OK' : 'FAIL'} browser=${browserName} ${JSON.stringify(report.checks)}`);
}
