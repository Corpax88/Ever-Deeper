// Run against immutable original and patched folders; uses actual exported classes.
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import os from 'node:os';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const [originalDir, suppliedCandidateDir] = process.argv.slice(2);
assert(originalDir, 'Usage: node audio-test.mjs ORIGINAL_DIR [CANDIDATE_DIR]');
const candidateDir = suppliedCandidateDir ?? fs.mkdtempSync(path.join(os.tmpdir(), 'ever-deeper-audio-test-'));
if (!suppliedCandidateDir) execFileSync('python3', [fileURLToPath(new URL('./audio_patch.py', import.meta.url)), originalDir, candidateDir]);
const read = (dir, name) => fs.readFileSync(path.join(dir, name), 'utf8');
const originalJS = read(originalDir, 'index.js');
const candidateJS = read(candidateDir, 'index.js');
const originalWorklet = read(originalDir, 'index.audio.position.worklet.js');
const candidateWorklet = read(candidateDir, 'index.audio.position.worklet.js');
const runtime = fs.readFileSync(new URL('./audio-runtime.js', import.meta.url), 'utf8');
const checks = [];
function check(name, data = {}) { checks.push({ name, ...data }); }

function processorFactory(code, rate) {
  let Processor;
  const context = {
    sampleRate: rate,
    AudioWorkletProcessor: class {
      constructor() { this.messages = []; this.port = { onmessage: null, postMessage: data => this.messages.push(data) }; }
    },
    registerProcessor(name, Class) { assert.equal(name, 'godot-position-reporting-processor'); Processor = Class; },
  };
  vm.runInNewContext(code, context);
  return () => new Processor();
}
const positions = p => p.messages.filter(m => m.type === 'position');
const latest = p => {
  for (let i = p.messages.length - 1; i >= 0; i--) if (p.messages[i].type === 'position') return p.messages[i].data;
  return 0;
};
const configure = (p, hz, version = 1) => p.port.onmessage?.({ data: { type: 'fps-fix-reporting', hz, version } });
function tick(p, frames = 128, reset = 0, input = true) {
  const output = new Float32Array([0.125, -0.25]);
  const keepAlive = p.process(input ? [[new Float32Array(frames)]] : [[]], [[output]], { reset: new Float32Array([reset]) });
  assert.equal(keepAlive, true);
  assert.deepEqual([...output], [0.125, -0.25], 'Position tap must not change output samples');
}

// An unconfigured node and configured short-SFX node both preserve every original quantum.
for (const hz of [null, 0]) {
  const a = processorFactory(originalWorklet, 48000)();
  const b = processorFactory(candidateWorklet, 48000)();
  if (hz !== null) configure(b, hz);
  for (let i = 0; i < 400; i++) {
    const reset = i < 120 || (i > 250 && i < 260) ? 1 : 0;
    const input = !(i >= 190 && i < 210);
    tick(a, 128, reset, input); tick(b, 128, reset, input);
    assert.equal(b.position, a.position);
    assert.equal(latest(b), latest(a));
  }
  assert.deepEqual(positions(b).map(x => x.data), positions(a).map(x => x.data));
  check(hz === null ? 'unconfigured-original-cadence-exact' : 'short-sfx-original-cadence-exact');
}

// Compare exact accumulated samples and bounded reporting age at several real sample rates/quanta.
for (const rate of [44100, 48000, 96000]) for (const quantum of [64, 128, 256]) {
  const a = processorFactory(originalWorklet, rate)();
  const b = processorFactory(candidateWorklet, rate)();
  configure(b, 60);
  let maximumLag = 0;
  const total = Math.ceil(rate * 6 / quantum);
  for (let i = 0; i < total; i++) {
    const reset = i * quantum < rate ? 1 : 0; // Original one-second reset pulse.
    const paused = i > total * 0.4 && i < total * 0.5;
    tick(a, quantum, reset, !paused); tick(b, quantum, reset, !paused);
    assert.equal(b.position, a.position, 'Must accumulate all frames, even between reports');
    const lag = latest(a) - latest(b);
    maximumLag = Math.max(maximumLag, lag);
    assert(lag >= 0 && lag <= rate / 60 + quantum, `Unbounded/stale position ${lag}`);
    if (paused) assert.equal(latest(b), latest(a), 'Pause must flush final input position');
  }
  tick(a, quantum, 0, false); tick(b, quantum, 0, false);
  assert.equal(latest(b), latest(a), 'Final partial cadence must flush on no input');
  assert(positions(b).length < positions(a).length * 0.4, 'Cadence must materially reduce messages');
  check('exact-sample-accumulation-and-bounded-age', { rate, quantum, originalMessages: positions(a).length, candidateMessages: positions(b).length, maximumLagMs: maximumLag / rate * 1000 });
}

// One minute including crossfade threshold: exact sample reports, no accumulated clock drift.
for (const rate of [44100, 48000]) {
  const a = processorFactory(originalWorklet, rate)();
  const b = processorFactory(candidateWorklet, rate)();
  configure(b, 60);
  let originalThreshold = null, candidateThreshold = null;
  const quantum = 128, total = Math.ceil(rate * 62 / quantum);
  for (let i = 0; i < total; i++) {
    const reset = i * quantum < rate ? 1 : 0;
    tick(a, quantum, reset); tick(b, quantum, reset);
    if (60 - latest(a) / rate <= 4 && originalThreshold === null) originalThreshold = i;
    if (60 - latest(b) / rate <= 4 && candidateThreshold === null) candidateThreshold = i;
  }
  const delayMs = (candidateThreshold - originalThreshold) * quantum / rate * 1000;
  assert(originalThreshold !== null && candidateThreshold !== null);
  assert(delayMs >= 0 && delayMs <= (1 / 60 + quantum / rate) * 1000);
  assert.equal(b.position, a.position);
  const prior = b.position;
  b.port.onmessage({ data: { type: 'clear' } });
  assert.equal(b.position, prior, 'Do not silently change original ignored restart clear');
  check('minute-crossfade-threshold-no-drift', { rate, delayMs, originalMessages: positions(a).length, candidateMessages: positions(b).length });
}

// Extract the real engine classes, including their actual pause/restart/end handlers.
function extract(source, name, next) {
  const start = source.indexOf(`${name}:class ${name}`) + name.length + 1;
  assert(start > name.length);
  const end = source.indexOf(next, start);
  assert(end > start);
  return source.slice(start, end);
}
function makeEnvironment(source, workletCode, patched) {
  const logs = [], worklets = [];
  const rate = 48000;
  const createProcessor = processorFactory(workletCode, rate);
  function buffer(channels, frames, sampleRate) {
    const data = Array.from({ length: channels }, () => new Float32Array(frames));
    data[0][0] = 0.25;
    return { duration: frames / sampleRate, length: frames, sampleRate, numberOfChannels: channels,
      getChannelData: i => data[i], copyToChannel: (a, i) => data[i].set(a) };
  }
  class Source {
    constructor() { this.playbackRate = { value: 1 }; this.listeners = new Map(); }
    connect(node) { logs.push(['connect', node.kind ?? 'bus']); return node; }
    disconnect() { logs.push(['disconnect']); }
    start(...args) { logs.push(['start', ...args]); }
    stop() { logs.push(['stop']); this.listeners.get('ended')?.(); }
    addEventListener(name, fn) { this.listeners.set(name, fn); }
    removeEventListener(name) { this.listeners.delete(name); }
    end() { this.listeners.get('ended')?.(); }
  }
  class Worklet {
    constructor() {
      this.kind = 'position-worklet'; this.processor = createProcessor(); this.reset = [];
      this.port = { onmessage: null, postMessage: data => this.processor.port.onmessage?.({ data }) };
      this.processor.port.postMessage = data => { this.processor.messages.push(data); this.port.onmessage?.({ data }); };
      this.parameters = { get: key => { assert.equal(key, 'reset'); return { setValueAtTime: (value, time) => this.reset.push([value, time]) }; } };
      worklets.push(this);
    }
    disconnect() { logs.push(['worklet-disconnect']); }
  }
  const ctx = { currentTime: 0, sampleRate: rate, createBuffer: buffer, createBufferSource: () => new Source() };
  const audio = { ctx, samples: new Map(), sampleNodes: new Map(), audioPositionWorkletPromise: Promise.resolve(), audioPositionWorkletNodes: [],
    Bus: { getBus: () => ({}) }, SampleNodeBus: { create: () => ({ getInputNode: () => ({ kind: 'bus' }), setVolume: () => {}, clear: () => {} }) },
    deleteSampleNode: id => audio.sampleNodes.delete(id) };
  const context = vm.createContext({ GodotAudio: audio, GodotRuntime: { error: e => { throw e; } }, AudioWorkletNode: Worklet });
  if (patched) vm.runInContext(runtime, context);
  audio.Sample = vm.runInContext(`(${extract(source, 'Sample', ',SampleNodeBus:')})`, context);
  audio.SampleNode = vm.runInContext(`(${extract(source, 'SampleNode', ',deleteSampleNode:')})`, context);
  const musicBuffer = buffer(2, rate * 12, rate), fxBuffer = buffer(2, rate / 10, rate);
  audio.Sample.create({ id: 'music', audioBuffer: musicBuffer }, { sampleRate: rate, loopMode: 'disabled' });
  audio.Sample.create({ id: 'fx', audioBuffer: fxBuffer }, { sampleRate: rate, loopMode: 'disabled' });
  assert.equal(audio.samples.get('music').getAudioBuffer(), musicBuffer, 'Music PCM reuse remains exact');
  const copiedFX = audio.samples.get('fx').getAudioBuffer();
  assert.notEqual(copiedFX, fxBuffer, 'Short SFX duplication remains unchanged');
  assert.deepEqual([...copiedFX.getChannelData(0)], [...fxBuffer.getChannelData(0)]);
  return { audio, logs, worklets, context, api: context.FPS_FIX_AUDIO, tick: (node, input = true) => tick(node._positionWorklet.processor, 128, 0, input) };
}
async function lifecycle(source, worklet, patched) {
  const env = makeEnvironment(source, worklet, patched), { audio, logs, api } = env;
  const create = (id, stream = 'music', offset = 0) => audio.SampleNode.create({ id, streamObjectId: stream, busIndex: 0 }, { start: true, offset, playbackRate: 1 });
  const settle = () => new Promise(resolve => setImmediate(resolve));
  const first = create('first'); await settle();
  assert.equal(first._source.buffer, audio.samples.get('music')._audioBuffer);
  const firstWorklet = first._positionWorklet;
  for (let i = 0; i < 32; i++) env.tick(first);
  audio.ctx.currentTime = 2;
  first.pause(true); env.tick(first, false);
  const pausedPosition = first.getPlaybackPosition();
  for (let i = 0; i < 12; i++) env.tick(first, false);
  assert.equal(first.getPlaybackPosition(), pausedPosition);
  // Suspended AudioContext delivers no process calls; no wall-clock extrapolation occurs.
  assert.equal(first.getPlaybackPosition(), pausedPosition);
  first.pause(false); env.tick(first);
  audio.samples.get('music').loopMode = 'forward';
  first._source.end(); env.tick(first);
  audio.samples.get('music').loopMode = 'disabled';
  const second = create('crossfade'); await settle();
  const fx = create('sfx', 'fx'); await settle();
  if (patched) {
    let state = api.snapshot();
    assert.equal(state.active, 3); assert.equal(state.nodes.filter(n => n.hz === 60).length, 2);
    assert.equal(state.nodes.find(n => !n.music).receivedHz, 0);
    api.setEnabled(false);
    assert(api.snapshot().nodes.every(n => n.receivedHz === 0));
    api.setEnabled(true);
    state = api.snapshot();
    assert.equal(state.configurationsSent, state.configurationsReceived);
    assert(state.nodes.every(n => n.version === n.confirmedVersion));
  }
  second.stop(); fx.stop(); first.stop();
  assert.equal(audio.sampleNodes.size, 0);
  if (patched) assert.equal(api.snapshot().active, 0);
  const reused = create('reused-fx', 'fx', 0.01); await settle();
  assert.equal(reused._positionWorklet, firstWorklet, 'Existing pool reuse retained');
  if (patched) {
    assert.equal(api.snapshot().nodes[0].receivedHz, 0, 'Pooled music worklet restored to SFX cadence');
    const position = reused.getPlaybackPosition();
    reused._positionWorklet.port.onmessage({ data: { type: 'position', data: 999999, fpsFixVersion: -1 } });
    assert.equal(reused.getPlaybackPosition(), position, 'Old-owner messages must not alter the new stream');
  }
  env.tick(reused); reused._source.end();
  let resolve;
  audio.audioPositionWorkletPromise = new Promise(r => { resolve = r; });
  const pending = create('canceled-before-worklet'); pending.stop(); resolve(); await settle();
  assert.equal(audio.sampleNodes.size, 0);
  if (patched) assert.equal(api.snapshot().active, 0);
  return { logs, positions: [pausedPosition], counters: api?.snapshot() ?? null };
}
const originalLifecycle = await lifecycle(originalJS, originalWorklet, false);
const candidateLifecycle = await lifecycle(candidateJS, candidateWorklet, true);
assert.deepEqual(candidateLifecycle.logs, originalLifecycle.logs, 'All audible source/graph/start/stop/offset lifecycle calls must be unchanged');
assert.deepEqual(candidateLifecycle.positions, originalLifecycle.positions, 'Paused final position must be exact');
check('real-export-class-lifecycle-parity', { operations: candidateLifecycle.logs.length, counters: candidateLifecycle.counters });
check('music-pcm-identity-and-sfx-copy-preserved');
console.log(JSON.stringify({ passed: true, checks, scope: 'Deterministic exact exported worklet and Sample/SampleNode lifecycle tests; not browser scheduling or audible device proof.' }, null, 2));
if (!suppliedCandidateDir) fs.rmSync(candidateDir, { recursive: true });
