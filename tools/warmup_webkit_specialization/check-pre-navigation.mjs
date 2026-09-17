import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { fixture } from './fixture.mjs';
import { classifyPreNavigation } from './pre_navigation.mjs';
const plain = x => JSON.parse(JSON.stringify(x));
const hash = (s, encoding = 'utf8') => createHash('sha256').update(s, encoding).digest('hex');
const texts = ['#define VERTEX\nvoid main(){}', '#define FRAGMENT\nvoid main(){}'];
const expected = {sources: texts.map(s => hash(s)), pair: hash(JSON.stringify(texts.map(s => hash(s, 'utf16le')).sort()))};
let checks = 0;
function setup() {
  const f = fixture(), pair = f.warm();
  const boundary = {resource: plain(f.api.ready()), observer: {contexts: 1, selected: true, calls: 31,
    version: '1.0.0-dev.13', hidden: false, keys: {ArrowDown: false, Space: false}},
    events: [], touches: [], action_count: 0, now_ms: f.clock};
  return {f, pair, boundary};
}
function close(s) {
  s.f.api.stop();
  const capture = plain(s.f.api.capture()), restoration = plain(s.f.api.restore());
  const continuity = {events: [], observer: {contexts: 1}, navigation_urls: ['http://fixture/index.html'],
    expected_url: 'http://fixture/index.html', resource_restoration: restoration,
    observer_restoration: {raf_restored: true, get_context_restored: true}};
  return {capture, boundary: s.boundary, continuity};
}
const classify = (r, target = expected) => classifyPreNavigation(r.capture, r.boundary, r.continuity, target);
function valid() {const s = setup(); s.f.api.start(); return close(s);}
function rejects(r, pattern) {assert.throws(() => classify(r), pattern); checks++;}

{
  const r = valid(), result = classify(r);
  assert.equal(result.target_link.event, 9);
  assert.equal(result.target_program_status_calls[0].event, r.boundary.resource.identity.event_count);
  assert.equal(result.post_stop_shader_events_covered, false); checks++;
  for (const B of [9, 8]) {
    const bad = plain(r); bad.boundary.resource.identity.event_count = B;
    rejects(bad, /status query missing|target link first appears/);
  }
}
for (const mutation of [
  s => s.f.pair(), // Fresh program duplicate before the timed window.
  s => s.f.gl.linkProgram(s.pair.program), // Same-program relink before timing.
  s => s.f.gl.compileShader(s.pair.shaders[0]), // Recompile, with no link at all.
]) {
  const s = setup(); mutation(s); s.f.api.start(); rejects(close(s), /exactly one|compiled again/);
}
{
  const s = setup(); s.f.api.start(); s.f.gl.compileShader(s.pair.shaders[1]);
  rejects(close(s), /compiled again/);
}
{
  // Changing an assigned source must not retroactively rewrite an old linked
  // compiled version when there is no new compile or link.
  const s = setup(); s.f.gl.shaderSource(s.pair.shaders[0], 'uncompiled new source'); s.f.api.start();
  const result = classify(close(s)); assert.equal(result.target_link.shaders[0].source, 1); checks++;
}
{
  const s = setup(); s.f.pair(['different full vertex', 'different full fragment']); s.f.api.start();
  assert.equal(classify(close(s)).passed, true); checks++;
}
for (const target of [
  {...expected, sources: [hash('absent'), expected.sources[1]]},
  {...expected, sources: [hash(texts[0].replace('#define VERTEX\n', '')), expected.sources[1]]},
  {...expected, pair: hash('wrong UTF-16 pair')},
]) {assert.throws(() => classify(valid(), target), /exactly one|fingerprint differs/); checks++;}
for (const mutation of [
  r => {r.boundary.resource.identity.event_count = 0;},
  r => {r.boundary.resource.identity.event_count = r.capture.identity.event_count + 1;},
  r => {r.boundary.resource.identity.shader_count++;},
  r => {r.boundary.resource.identity.dropped = 1;},
  r => {r.capture.identity.dropped = 1;},
  r => {r.boundary.observer.keys.Space = true;},
  r => {r.boundary.action_count = 1;},
  r => {r.boundary.touches.push({type: 'touchstart'});},
  r => {r.continuity.events.push({kind: 'contextlost', time: 1});}, // Before timed window.
  r => {r.continuity.events.push({kind: 'pagehide', time: 2});},
  r => {r.continuity.events.push({kind: 'engine_callback_changed', time: 3});},
  r => {r.continuity.navigation_urls.push('http://fixture/reload');},
  r => {r.continuity.resource_restoration.descriptors_restored = false;},
  r => {r.continuity.observer_restoration.raf_restored = false;},
]) {const r = valid(); mutation(r); rejects(r, /Pre-navigation identity|Shader identity/);}
{
  const s = setup(); s.f.api.start(); s.f.api.stop();
  const frozen = JSON.stringify(plain(s.f.api.capture()).identity);
  s.f.gl.compileShader(s.pair.shaders[0]); s.f.gl.linkProgram(s.pair.program);
  assert.equal(JSON.stringify(plain(s.f.api.capture()).identity), frozen);
  const r = close(s); r.continuity.events.push({kind: 'contextlost', time: r.capture.stopped_ms + 1});
  const result = classify(r); assert.equal(result.post_stop_shader_events_covered, false); checks++;
}
console.log('PRE_NAVIGATION_IDENTITY_NEGATIVE_CHECKS_OK checks=' + checks);
