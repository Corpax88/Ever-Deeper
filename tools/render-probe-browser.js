// DEV lighting diagnostic: wall-clock RAF samples, no canvas or GPU mutations.
(() => {
  const canvas = document.getElementById('canvas');
  let active = false, raf = 0, previous = 0, began = 0, abortReason = '';
  let count = 0, cursor = 0, watchdog = 0;
  const times = new Float64Array(4096), durations = new Float64Array(4096);
  function tick(now) {
    if (!active) return;
    if (previous && now - began >= 2000) {
      times[cursor] = now; durations[cursor] = now - previous;
      cursor = (cursor + 1) % times.length; count = Math.min(times.length, count + 1);
    }
    previous = now;
    raf = requestAnimationFrame(tick);
  }
  function stop(reason = '') {
    active = false; abortReason = reason;
    cancelAnimationFrame(raf); clearTimeout(watchdog);
  }
  const api = {
    begin() {
      if (active || document.hidden) return false;
      active = true; abortReason = '';
      previous = 0; count = 0; cursor = 0; began = performance.now();
      watchdog = setTimeout(() => stop('Diagnostic timed out'), 150000);
      raf = requestAnimationFrame(tick); return true;
    },
    stage() {
      if (!active) return false;
      previous = 0; count = 0; cursor = 0; began = performance.now();
      return true;
    },
    snapshot() {
      const values = [], limit = performance.now() - 8000;
      for (let i = 0; i < count; i++) if (times[i] >= limit) values.push(durations[i]);
      const elapsed = values.reduce((a, b) => a + b, 0); values.sort((a, b) => a - b);
      return {active, abort_reason: abortReason, width: canvas.width, height: canvas.height,
        css_width: window.innerWidth, css_height: window.innerHeight, dpr: devicePixelRatio || 1,
        raf_fps: elapsed ? values.length * 1000 / elapsed : 0, raf_frames: values.length,
        raf_p95_ms: values.length ? values[Math.ceil(values.length * 0.95) - 1] : 0};
    },
    finish(report) { stop(); window.everDeeperRenderProbeResult = report; },
    cancel(reason) { stop(reason); }
  };
  window.addEventListener('resize', () => { if (active) stop('Window resized'); });
  document.addEventListener('visibilitychange', () => { if (active && document.hidden) stop('App hidden'); });
  window.addEventListener('pagehide', () => { if (active) stop('Page closed'); });
  canvas.addEventListener('webglcontextlost', () => { if (active) stop('Graphics context lost'); });
  window.everDeeperRenderProbe = api;
})();
