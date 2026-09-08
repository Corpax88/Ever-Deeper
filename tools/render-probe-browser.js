// DEV diagnostic shell. Normal scale reproduces adaptive full-window HiDPI sizing.
// canvasResizePolicy=0 is the documented hook for owning canvas dimensions in JS.
(() => {
  const canvas = document.getElementById('canvas');
  let scale = 1, active = false, raf = 0, previous = 0, began = 0, abortReason = '';
  let count = 0, cursor = 0, watchdog = 0;
  const times = new Float64Array(4096), durations = new Float64Array(4096);
  function resize() {
    const dpr = window.devicePixelRatio || 1;
    const w = Math.max(1, Math.round(window.innerWidth * dpr * scale));
    const h = Math.max(1, Math.round(window.innerHeight * dpr * scale));
    canvas.style.width = `${window.innerWidth}px`;
    canvas.style.height = `${window.innerHeight}px`;
    if (canvas.width !== w) canvas.width = w;
    if (canvas.height !== h) canvas.height = h;
  }
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
    active = false; abortReason = reason; scale = 1;
    cancelAnimationFrame(raf); clearTimeout(watchdog); resize();
  }
  const api = {
    begin() {
      if (active || document.hidden) return false;
      active = true; abortReason = ''; scale = 1; resize();
      previous = 0; count = 0; cursor = 0; began = performance.now();
      watchdog = setTimeout(() => stop('Diagnostic timed out'), 150000);
      raf = requestAnimationFrame(tick); return true;
    },
    stage(nextScale) {
      if (!active || ![0.5, 1].includes(nextScale)) return false;
      scale = nextScale; resize(); previous = 0; count = 0; cursor = 0; began = performance.now();
      return true;
    },
    snapshot() {
      const values = [], limit = performance.now() - 8000;
      for (let i = 0; i < count; i++) if (times[i] >= limit) values.push(durations[i]);
      const elapsed = values.reduce((a, b) => a + b, 0); values.sort((a, b) => a - b);
      return {active, abort_reason: abortReason, scale, width: canvas.width, height: canvas.height,
        css_width: window.innerWidth, css_height: window.innerHeight, dpr: devicePixelRatio || 1,
        raf_fps: elapsed ? values.length * 1000 / elapsed : 0, raf_frames: values.length,
        raf_p95_ms: values.length ? values[Math.ceil(values.length * 0.95) - 1] : 0};
    },
    finish(report) { stop(); window.everDeeperRenderProbeResult = report; },
    cancel(reason) { stop(reason); }
  };
  window.addEventListener('resize', () => { if (active) stop('Window resized'); else resize(); });
  document.addEventListener('visibilitychange', () => { if (active && document.hidden) stop('App hidden'); });
  window.addEventListener('pagehide', () => { if (active) stop('Page closed'); });
  canvas.addEventListener('webglcontextlost', () => { if (active) stop('Graphics context lost'); });
  window.everDeeperRenderProbe = api;
  resize();
})();
