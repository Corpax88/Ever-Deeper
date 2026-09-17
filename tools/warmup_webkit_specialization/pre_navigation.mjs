// Node-only analysis of original recorded calls; never executes in the game page.
import { analyzeIdentity } from './identity.mjs';

export const EXPECTED = Object.freeze({
  sources: [
    'aecaa8e92eb4a09192a1cb4733e3a7d0edc9fc1af266c1a41147073fc107967f',
    '8b9380594232f57892a2833bcb3295135416357c1c0bc2fde73fa32bc0092b7a',
  ],
  pair: '51e583de0862d6689a4d1a90edccc9aa704e4944df052d19686dd1238a74447e',
});
const requireThat = (ok, message) => { if (!ok) throw Error('Pre-navigation identity: ' + message); };

export function validateMenuBoundary(boundary) {
  const resource = boundary.resource, observer = boundary.observer;
  requireThat(resource && observer && resource.installed === 9 && !resource.active &&
    !resource.ever_started && !resource.restored && resource.error_mask === 0 &&
    resource.extra_context === false && resource.identity.error_mask === 0 &&
    resource.identity.dropped === 0, 'invalid menu recorder state');
  requireThat(observer.contexts === 1 && observer.selected === true && observer.calls > 30 &&
    observer.version === '1.0.0-dev.13' && observer.hidden === false &&
    observer.keys.ArrowDown === false && observer.keys.Space === false &&
    boundary.action_count === 0 && Array.isArray(boundary.touches) && boundary.touches.length === 0 &&
    Array.isArray(boundary.events) && !boundary.events.some(e => ['keydown', 'keyup'].includes(e.kind)) &&
    Number.isFinite(boundary.now_ms), 'menu is not before declared gameplay navigation input');
  return true;
}

export function classifyPreNavigation(capture, boundary, continuity, expected = EXPECTED) {
  // Validates the complete source/event history against the separate, unchanged
  // later measurement-start boundary, including original compiled versions.
  const analysis = analyzeIdentity(capture);
  validateMenuBoundary(boundary);
  const resource = boundary.resource;
  const B = resource.identity.event_count;
  requireThat(Number.isInteger(B) && B > 0 && B <= capture.start_receipt.identity_at_start.event_count &&
    capture.started_ms >= boundary.now_ms && capture.stopped_ms >= capture.started_ms,
    'invalid menu/measurement/stop boundaries');
  requireThat(expected.sources.length === 2 && new Set(expected.sources).size === 2 &&
    expected.sources.every(s => /^[a-f0-9]{64}$/.test(s)) && /^[a-f0-9]{64}$/.test(expected.pair),
    'invalid complete-source target');

  const shaders = new Set(), programs = new Set(), prefixSources = new Set();
  for (const e of capture.identity.events.slice(0, B)) {
    ([2, 3, 5].includes(e.kind) ? programs : shaders).add(e.object);
    if (e.kind === 2) shaders.add(e.other);
    if (e.kind === 0) prefixSources.add(e.other);
  }
  requireThat(shaders.size === resource.identity.shader_count && programs.size === resource.identity.program_count &&
    prefixSources.size === resource.identity.source_count, 'menu prefix identity counts differ');
  const targetHashes = [...expected.sources].sort();
  const targetLinks = analysis.program_links.filter(link =>
    JSON.stringify(link.shaders.map(s => s.sha256_utf8).sort()) === JSON.stringify(targetHashes));
  requireThat(targetLinks.length === 1, 'expected exactly one complete target-pair link');
  const target = targetLinks[0];
  requireThat(target.source_pair_sha256 === expected.pair, 'full UTF-16 pair fingerprint differs');
  requireThat(target.event <= B, 'target link first appears after menu boundary');

  const assigned = new Map(), latestLinks = new Map();
  const linksByEvent = new Map(analysis.program_links.map(link => [link.event, link]));
  const targetCompiles = [], targetStatus = [];
  capture.identity.events.forEach((event, index) => {
    const number = index + 1;
    if (event.kind === 0) assigned.set(event.object, event.other);
    if (event.kind === 1) {
      const source = assigned.get(event.object), hash = analysis.sources[source - 1]?.sha256_utf8;
      if (targetHashes.includes(hash)) targetCompiles.push({event: number, shader: event.object,
        source, sha256_utf8: hash, after_menu: number > B, during_timed_window: !!event.during_window});
    }
    if (event.kind === 3) latestLinks.set(event.object, linksByEvent.get(number));
    if (event.kind === 5 && latestLinks.get(event.object)?.event === target.event)
      targetStatus.push({event: number, program: event.object, before_or_at_menu: number <= B});
  });
  requireThat(targetHashes.every(hash => targetCompiles.some(e => e.sha256_utf8 === hash && e.event <= B)),
    'both target source compile calls were not present by menu boundary');
  requireThat(!targetCompiles.some(e => e.after_menu), 'matching stage compiled again after menu boundary');
  requireThat(targetStatus.some(e => e.before_or_at_menu), 'target linked-program status query missing by menu boundary');

  requireThat(continuity.observer.contexts === 1 && Array.isArray(continuity.events) &&
    continuity.navigation_urls.length === 1 && continuity.navigation_urls[0] === continuity.expected_url,
    'context count or main-page navigation changed');
  const coveredEvents = continuity.events.filter(e => {
    requireThat(Number.isFinite(e.time) && e.time >= 0, 'invalid event clock');
    return e.time <= capture.stopped_ms;
  });
  requireThat(!coveredEvents.some(e => ['contextlost', 'pagehide', 'engine_callback_changed'].includes(e.kind)),
    'context/page/callback continuity lost before recording endpoint');
  requireThat(!coveredEvents.some(e => e.time >= boundary.now_ms && ['hidden', 'blur', 'resize'].includes(e.kind)),
    'visibility or surface changed after menu boundary');
  const restore = continuity.resource_restoration, rawRestore = continuity.observer_restoration;
  requireThat(restore.all_methods_restored === true && restore.descriptors_restored === true &&
    restore.get_context_restored_to_observer === true && restore.method_count === 9 && restore.error_mask === 0 &&
    rawRestore.raf_restored === true && rawRestore.get_context_restored === true, 'recorder restoration failed');
  return {
    schema: 1, passed: true, claim: 'Exact target API history before ordinary menu navigation; no later matching compile/link through recorded endpoint.',
    menu_event_count: B, measurement_start_event_count: capture.start_receipt.identity_at_start.event_count,
    final_event_count: capture.identity.event_count, coverage_ends_ms: capture.stopped_ms,
    exact_target: expected, target_link: target, target_compile_calls: targetCompiles,
    target_program_status_calls: targetStatus, covered_observer_events: coveredEvents.length,
    extra_gl_queries: 0, first_frame_or_helper_attribution: false,
    status_return_booleans_recorded: false, gameplay_program_use_or_driver_cache_proven: false,
    post_stop_shader_events_covered: false, performance_or_physical_iphone_acceptance: false,
    limits: 'success=1 means the original call returned without throwing. No useProgram, deleteProgram or draw-to-program association. The menu boundary is after initial focus and rendered startup; later key release/save/restoration is outside identity coverage.',
  };
}
