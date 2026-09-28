/* Read-only WebGL pass inventory. Load before the engine with addInitScript.
 * Initially installed to observe startup allocations. For later inventories:
 * install(); regenerate changed atlas/resources; settle at least one frame;
 * begin(label); ...; end() [stops AND restores exact native prototypes].
 * begin also installs if necessary, but cannot recover allocations made while
 * uninstalled; missing attachment storage stays null rather than being guessed.
 * No GPU queries, getParameter, pixel readback or per-call timers. Diagnostic
 * wrappers still have CPU overhead; do not treat instrumented FPS as acceptance.
 * Clear ignores the viewport; clear scope is the framebuffer or enabled scissor.
 */
(() => {
  const ids = new WeakMap(), contexts = new WeakMap(), textures = new Map(), buffers = new Map(), fbos = new Map();
  let nextId = 0, nextContext = 0, epoch = 0, active = false, installed = false, label = '', bins = new Map();
  const methods = [];
  const id = object => {
    if (!object) return 0;
    if (!ids.has(object)) ids.set(object, ++nextId);
    return ids.get(object);
  };
  const state = gl => {
    let s = contexts.get(gl);
    if (!s) {
      s = {id: ++nextContext, gl, unit: 33984, bound: new Map(), renderbuffer: 0, draw: 0, read: 0,
        viewport: [0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight],
        scissor: [0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight], scissorEnabled: false, bin: null, epoch: -1};
      contexts.set(gl, s);
    }
    return s;
  };
  const textureTarget = target => target >= 34069 && target <= 34074 ? 34067 : target;
  const boundTexture = (s, target) => s.bound.get(s.unit + ':' + textureTarget(target)) || 0;
  const framebuffer = (s, target) => target === 36008 ? s.read : s.draw;
  const invalidate = s => { s.bin = null; };
  const attachment = (s, target, slot, value) => {
    const key = framebuffer(s, target);
    if (!fbos.has(key)) fbos.set(key, {});
    if (value.id) fbos.get(key)[slot] = value; else delete fbos.get(key)[slot];
    invalidate(s);
  };
  const attachments = s => {
    if (!s.draw) return {default: {width: s.gl.drawingBufferWidth, height: s.gl.drawingBufferHeight}};
    const result = {};
    for (const [slot, a] of Object.entries(fbos.get(s.draw) || {})) {
      const storage = (a.kind === 'texture' ? textures : buffers).get(a.id);
      result[slot] = {...a, storage: storage ? {...storage} : null};
    }
    return result;
  };
  const bin = s => {
    if (s.bin && s.epoch === epoch) return s.bin;
    const key = [s.id, s.draw, ...s.viewport, s.scissorEnabled ? s.scissor.join(',') : 'off'].join('/');
    if (!bins.has(key)) bins.set(key, {context: s.id, framebuffer: s.draw, viewport: [...s.viewport],
      scissor: s.scissorEnabled ? [...s.scissor] : null, attachments: attachments(s),
      draw_calls: 0, submitted_elements: 0, submitted_instances: 0, draw_modes: {},
      clears: 0, clear_color: 0, clear_depth: 0, clear_stencil: 0,
      clear_scope: s.scissorEnabled ? 'scissor' : 'entire_framebuffer'});
    s.epoch = epoch; s.bin = bins.get(key); return s.bin;
  };
  const patch = (proto, name, after) => {
    const original = proto[name];
    if (typeof original !== 'function') return;
    const descriptor = Object.getOwnPropertyDescriptor(proto, name);
    const wrapper = function (...args) { const result = original.apply(this, args); after(state(this), args); return result; };
    methods.push({proto, name, original, descriptor, wrapper});
  };
  const install = () => {
    if (installed) return;
    for (const e of methods) if (e.proto[e.name] !== e.original) throw Error('VIEWPORT_TRACE refuses to replace another wrapper: '+e.name);
    for (const e of methods) Object.defineProperty(e.proto, e.name, e.descriptor ? {...e.descriptor, value:e.wrapper} : {configurable:true, writable:true, value:e.wrapper});
    installed = true; epoch++;
  };
  const uninstall = () => {
    active = false;
    if (!installed) return;
    for (const e of methods) if (e.proto[e.name] !== e.wrapper) throw Error('VIEWPORT_TRACE refuses to overwrite another wrapper: '+e.name);
    for (const e of methods) { if (e.descriptor) Object.defineProperty(e.proto, e.name, e.descriptor); else delete e.proto[e.name]; }
    installed = false; epoch++;
  };
  // The shipped Godot export uses WebGL2. Patch only its prototype to avoid
  // double wrapping inherited methods through WebGL1 and WebGL2 prototypes.
  const p = window.WebGL2RenderingContext?.prototype;
  if (!p) { window.VIEWPORT_TRACE = {supported: false}; return; }
  patch(p, 'activeTexture', (s, a) => { s.unit = a[0]; });
  patch(p, 'bindTexture', (s, a) => { s.bound.set(s.unit + ':' + a[0], id(a[1])); });
  patch(p, 'texImage2D', (s, a) => {
    if (a[1] !== 0) return;
    const width = a.length >= 9 ? a[3] : a[5]?.width, height = a.length >= 9 ? a[4] : a[5]?.height;
    textures.set(boundTexture(s, a[0]), {width, height, internal_format: a[2], levels: 1}); invalidate(s);
  });
  patch(p, 'texStorage2D', (s, a) => { textures.set(boundTexture(s, a[0]), {width: a[3], height: a[4], internal_format: a[2], levels: a[1]}); invalidate(s); });
  patch(p, 'texImage3D', (s, a) => { if (a[1] === 0) { textures.set(boundTexture(s, a[0]), {width: a[3], height: a[4], depth: a[5], internal_format: a[2], levels: 1}); invalidate(s); } });
  patch(p, 'texStorage3D', (s, a) => { textures.set(boundTexture(s, a[0]), {width: a[3], height: a[4], depth: a[5], internal_format: a[2], levels: a[1]}); invalidate(s); });
  patch(p, 'bindRenderbuffer', (s, a) => { s.renderbuffer = id(a[1]); });
  patch(p, 'renderbufferStorage', (s, a) => { buffers.set(s.renderbuffer, {width: a[2], height: a[3], internal_format: a[1], samples: 0}); invalidate(s); });
  patch(p, 'renderbufferStorageMultisample', (s, a) => { buffers.set(s.renderbuffer, {width: a[3], height: a[4], internal_format: a[2], samples: a[1]}); invalidate(s); });
  patch(p, 'bindFramebuffer', (s, a) => { const f = id(a[1]); if (a[0] === 36160 || a[0] === 36009) s.draw = f; if (a[0] === 36160 || a[0] === 36008) s.read = f; invalidate(s); });
  patch(p, 'framebufferTexture2D', (s, a) => attachment(s, a[0], a[1], {kind: 'texture', id: id(a[3]), level: a[4], target: a[2]}));
  patch(p, 'framebufferTextureLayer', (s, a) => attachment(s, a[0], a[1], {kind: 'texture', id: id(a[2]), level: a[3], layer: a[4]}));
  patch(p, 'framebufferRenderbuffer', (s, a) => attachment(s, a[0], a[1], {kind: 'renderbuffer', id: id(a[3])}));
  patch(p, 'viewport', (s, a) => { s.viewport = a.slice(0, 4); invalidate(s); });
  patch(p, 'scissor', (s, a) => { s.scissor = a.slice(0, 4); invalidate(s); });
  patch(p, 'enable', (s, a) => { if (a[0] === 3089) { s.scissorEnabled = true; invalidate(s); } });
  patch(p, 'disable', (s, a) => { if (a[0] === 3089) { s.scissorEnabled = false; invalidate(s); } });
  const draw = (s, mode, count, instances) => { if (!active) return; const b = bin(s); b.draw_calls++; b.submitted_elements += count * instances; b.submitted_instances += instances; b.draw_modes[mode] = (b.draw_modes[mode] || 0) + 1; };
  patch(p, 'drawArrays', (s, a) => draw(s, a[0], a[2], 1));
  patch(p, 'drawElements', (s, a) => draw(s, a[0], a[1], 1));
  patch(p, 'drawArraysInstanced', (s, a) => draw(s, a[0], a[2], a[3]));
  patch(p, 'drawElementsInstanced', (s, a) => draw(s, a[0], a[1], a[4]));
  patch(p, 'clear', (s, a) => { if (!active) return; const b = bin(s); b.clears++; if (a[0] & 16384) b.clear_color++; if (a[0] & 256) b.clear_depth++; if (a[0] & 1024) b.clear_stencil++; });
  for (const name of ['clearBufferfv', 'clearBufferiv', 'clearBufferuiv', 'clearBufferfi']) patch(p, name, (s, a) => {
    if (!active) return; const b = bin(s); b.clears++;
    if (a[0] === 6144) b.clear_color++; if (a[0] === 6145 || a[0] === 34041) b.clear_depth++; if (a[0] === 6146 || a[0] === 34041) b.clear_stencil++;
  });
  const snapshot = () => ({supported: true, label, active, installed, scope: 'Read-only WebGL2 viewport/FBO/clear inventory; no GPU duration claim', rows: [...bins.values()]});
  window.VIEWPORT_TRACE = {supported: true,
    get installed() { return installed; }, install, uninstall,
    begin(value = '') { install(); epoch++; bins = new Map(); label = value; active = true; },
    end(keepInstalled = false) { active = false; if (!keepInstalled) uninstall(); return snapshot(); }, snapshot};
  install();
})();

