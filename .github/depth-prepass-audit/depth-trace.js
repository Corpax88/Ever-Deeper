/* Read-only WebGL pass/depth-state inventory. Load with addInitScript before
 * the engine. Initially installed to observe startup allocations and GL state.
 * install(); regenerate changed resources; settle; begin(label); ...; end().
 * end() restores exact native prototype descriptors. Never use instrumented FPS
 * as acceptance. No GPU queries, getParameter, readback, or per-call timing.
 * After reinstallation, pass state is UNKNOWN (null) until a setter is observed;
 * defaults are only trusted during the initial pre-engine installation.
 * Clear ignores viewport; its scope is the framebuffer or enabled scissor.
 */
(() => {
  const ids = new WeakMap(), contexts = new WeakMap(), textures = new Map(), buffers = new Map(), fbos = new Map();
  let nextId = 0, nextContext = 0, epoch = 0, installation = 0, active = false, installed = false, label = '', bins = new Map();
  const methods = [];
  const id = object => {
    if (!object) return 0;
    if (!ids.has(object)) ids.set(object, ++nextId);
    return ids.get(object);
  };
  const initialPass = known => ({
    color_mask: known ? [true, true, true, true] : null,
    depth_mask: known ? true : null, depth_func: known ? 513 : null,
    depth_test: known ? false : null,
    cull_enabled: known ? false : null, cull_face: known ? 1029 : null, front_face: known ? 2305 : null,
    blend_enabled: known ? false : null, rasterizer_discard: known ? false : null,
    transform_feedback: known ? 0 : null, transform_feedback_active: known ? false : null,
    transform_feedback_paused: known ? false : null, transform_feedback_primitive_mode: null
  });
  const state = gl => {
    let s = contexts.get(gl);
    if (!s) {
      s = {id: ++nextContext, gl, unit: 33984, bound: new Map(), renderbuffer: 0, draw: 0, read: 0, drawBuffers: new Map(),
        viewport: [0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight],
        scissor: [0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight], scissorEnabled: false,
        pass: initialPass(installation === 1), installation, bin: null, epoch: -1};
      contexts.set(gl, s);
    } else if (s.installation !== installation) {
      s.pass = initialPass(false); s.installation = installation; s.bin = null;
    }
    return s;
  };
  const textureTarget = target => target >= 34069 && target <= 34074 ? 34067 : target;
  const boundTexture = (s, target) => s.bound.get(s.unit + ':' + textureTarget(target)) || 0;
  const framebuffer = (s, target) => target === 36008 ? s.read : s.draw;
  const invalidate = s => { s.bin = null; };
  const setPass = (s, key, value) => { s.pass[key] = value; invalidate(s); };
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
    const db = s.drawBuffers.get(s.draw);
    const drawBuffers = db?.installation === installation ? db.values : installation === 1 ? [s.draw ? 36064 : 1029] : null;
    const key = JSON.stringify([s.id, s.draw, s.viewport, s.scissorEnabled ? s.scissor : null, s.pass, drawBuffers]);
    if (!bins.has(key)) bins.set(key, {context: s.id, framebuffer: s.draw, viewport: [...s.viewport],
      scissor: s.scissorEnabled ? [...s.scissor] : null, attachments: attachments(s),
      pass_state: {...s.pass, color_mask: s.pass.color_mask ? [...s.pass.color_mask] : null,
        draw_buffers: drawBuffers ? [...drawBuffers] : null},
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
    installed = true; installation++; epoch++;
  };
  const uninstall = () => {
    active = false;
    if (!installed) return;
    for (const e of methods) if (e.proto[e.name] !== e.wrapper) throw Error('VIEWPORT_TRACE refuses to overwrite another wrapper: '+e.name);
    for (const e of methods) { if (e.descriptor) Object.defineProperty(e.proto, e.name, e.descriptor); else delete e.proto[e.name]; }
    installed = false; epoch++;
  };
  // WebGL2 only, avoiding double wrapping inherited WebGL1 methods.
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
  patch(p, 'drawBuffers', (s, a) => { s.drawBuffers.set(s.draw, {installation, values: Array.from(a[0])}); invalidate(s); });
  patch(p, 'framebufferTexture2D', (s, a) => attachment(s, a[0], a[1], {kind: 'texture', id: id(a[3]), level: a[4], target: a[2]}));
  patch(p, 'framebufferTextureLayer', (s, a) => attachment(s, a[0], a[1], {kind: 'texture', id: id(a[2]), level: a[3], layer: a[4]}));
  patch(p, 'framebufferRenderbuffer', (s, a) => attachment(s, a[0], a[1], {kind: 'renderbuffer', id: id(a[3])}));
  patch(p, 'viewport', (s, a) => { s.viewport = a.slice(0, 4); invalidate(s); });
  patch(p, 'scissor', (s, a) => { s.scissor = a.slice(0, 4); invalidate(s); });
  const capabilities = {2929: 'depth_test', 2884: 'cull_enabled', 3042: 'blend_enabled', 35977: 'rasterizer_discard'};
  const capability = (s, cap, enabled) => {
    if (cap === 3089) { s.scissorEnabled = enabled; invalidate(s); }
    if (capabilities[cap]) setPass(s, capabilities[cap], enabled);
  };
  patch(p, 'enable', (s, a) => capability(s, a[0], true));
  patch(p, 'disable', (s, a) => capability(s, a[0], false));
  patch(p, 'colorMask', (s, a) => setPass(s, 'color_mask', a.slice(0, 4).map(Boolean)));
  patch(p, 'depthMask', (s, a) => setPass(s, 'depth_mask', Boolean(a[0])));
  patch(p, 'depthFunc', (s, a) => setPass(s, 'depth_func', a[0]));
  patch(p, 'cullFace', (s, a) => setPass(s, 'cull_face', a[0]));
  patch(p, 'frontFace', (s, a) => setPass(s, 'front_face', a[0]));
  patch(p, 'bindTransformFeedback', (s, a) => setPass(s, 'transform_feedback', id(a[1])));
  patch(p, 'beginTransformFeedback', (s, a) => {
    s.pass.transform_feedback_active = true; s.pass.transform_feedback_paused = false;
    setPass(s, 'transform_feedback_primitive_mode', a[0]);
  });
  patch(p, 'endTransformFeedback', s => {
    s.pass.transform_feedback_active = false; s.pass.transform_feedback_paused = false;
    setPass(s, 'transform_feedback_primitive_mode', null);
  });
  patch(p, 'pauseTransformFeedback', s => setPass(s, 'transform_feedback_paused', true));
  patch(p, 'resumeTransformFeedback', s => setPass(s, 'transform_feedback_paused', false));
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
  const snapshot = () => ({supported: true, label, active, installed,
    scope: 'Read-only WebGL2 FBO/depth/color/cull/blend/transform-feedback inventory; no GPU duration claim',
    state_tracking: 'Initial native defaults; after reinstall null means not reobserved. API calls assumed valid. No getParameter.',
    rows: [...bins.values()]});
  window.VIEWPORT_TRACE = {supported: true,
    get installed() { return installed; }, install, uninstall,
    begin(value = '') { install(); epoch++; bins = new Map(); label = value; active = true; },
    end(keepInstalled = false) { active = false; if (!keepInstalled) uninstall(); return snapshot(); }, snapshot};
  install();
})();
