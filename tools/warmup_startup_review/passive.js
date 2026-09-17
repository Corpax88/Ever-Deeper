(() => {
  if (location.pathname !== '/index.html') return;
  const out = window.__startupReview = {
    schema: 1, events: [], frames: [], active_samples: [], status_seen: false,
    status_removed_ms: null, splash_seen: false, frames_stopped: false, overflow: false,
    scope: 'Passive DOM lifecycle and trusted-event receipts; no engine-listener observation.'
  };
  const push = row => {
    if (out.events.length < 2000) out.events.push({time_ms: performance.now(), ...row});
    else out.overflow = true;
  };
  const status = () => {
    const s = document.getElementById('status'), splash = document.getElementById('status-splash');
    if (s) out.status_seen = true;
    if (out.status_seen && !s && out.status_removed_ms === null) {
      out.status_removed_ms = performance.now(); push({type: 'status_removed'});
    }
    const visible = !!s && getComputedStyle(s).visibility !== 'hidden';
    const loaded = !!splash?.complete && splash.naturalWidth > 0;
    if (visible && loaded) out.splash_seen = true;
    return {status_present: !!s, status_visible: visible, splash_loaded: loaded,
      progress: document.getElementById('status-progress')?.value ?? null};
  };
  new MutationObserver(status).observe(document, {subtree: true, childList: true, attributes: true});
  for (const type of ['keydown', 'keyup', 'touchstart', 'touchend', 'touchcancel', 'focus', 'blur', 'visibilitychange', 'pagehide', 'resize']) {
    addEventListener(type, e => push({type, phase:'capture', default_prevented:e.defaultPrevented, trusted: e.isTrusted, target: e.target?.id ?? null,
      key: e.key ?? null, code: e.code ?? null, repeat: e.repeat ?? null,
      active: document.activeElement?.id ?? null, focused: document.hasFocus(),
      visibility: document.visibilityState,
      touches: e.changedTouches ? Array.from(e.changedTouches, t => ({id:t.identifier,x:t.clientX,y:t.clientY})) : null,
      ...status()}), {capture: true, passive: true});
  }
  for (const type of ['keydown','keyup']) addEventListener(type,e=>push({type,phase:'bubble',
    default_prevented:e.defaultPrevented,trusted:e.isTrusted,target:e.target?.id??null,
    key:e.key,code:e.code,repeat:e.repeat,active:document.activeElement?.id??null,
    focused:document.hasFocus(),visibility:document.visibilityState,...status()}),{passive:true});
  addEventListener('DOMContentLoaded', () => push({type: 'domcontentloaded', ...status()}), {once: true});
  const frame = time => {
    if (out.frames_stopped) return;
    if (out.frames.length >= 1800) { out.overflow = true; return; }
    out.frames.push({time_ms:time,...status(),active:document.activeElement?.id??null,visibility:document.visibilityState});
    requestAnimationFrame(frame);
  };
  requestAnimationFrame(frame);
  // This passive DOM sample is not an engine-loop or presented-frame counter.
  setInterval(() => {
    if (out.active_samples.length >= 2400) { out.overflow = true; return; }
    out.active_samples.push({time_ms:performance.now(),focused:document.hasFocus(),
      active:document.activeElement?.id??null,visibility:document.visibilityState});
  },250);
})();
