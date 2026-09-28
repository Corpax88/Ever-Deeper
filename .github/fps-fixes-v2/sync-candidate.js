/* Ever-Deeper: conservative WebGL 2 same-stack sync-status candidate.
 * Install before index.js. Native fence creation, deletion, rendering and all
 * waits remain unchanged. A fresh sync can only answer UNSIGNALED until the
 * next microtask checkpoint. Default OFF pending actual-game trace evidence.
 * https://registry.khronos.org/webgl/specs/latest/2.0/#3.7.14
 */
(() => {
  'use strict';
  if (globalThis.EVER_DEEPER_SYNC) return;
  const P = globalThis.WebGL2RenderingContext?.prototype;
  const schedule = globalThis.queueMicrotask;
  const STATUS = 37140, UNSIGNALED = 37144, SIGNALED = 37145;
  const names = ['fenceSync', 'getSyncParameter', 'deleteSync', 'isContextLost'];
  const native = Object.fromEntries(names.map(name => [name, P?.[name]]));
  let supported = !!P && typeof schedule === 'function' && names.every(name => typeof native[name] === 'function');
  let installed = false, enabled = globalThis.EVER_DEEPER_SYNC_START_ENABLED === true;
  let validation = false, failed = false, batch = 1, pendingClear = false;
  let syncs = new WeakMap(), nextSync = 1, nextContext = 1;
  const contexts = new WeakMap(), listeners = [], patches = [];
  const counterNames = ['fences', 'created', 'fenceNull', 'checks', 'statusChecks',
    'nativeChecks', 'hits', 'freshChecks', 'staleChecks', 'unknownChecks', 'foreignChecks',
    'generationFallbacks', 'lostFallbacks', 'nativeFreshUnsignaled', 'nativeFreshSignaled',
    'nativeFreshNull', 'nativeFreshOther', 'validationChecks', 'validationMismatches',
    'deletes', 'clearBatches', 'contextLosses', 'contextRestores', 'uninstallConflicts'];
  let totals = Object.fromEntries(counterNames.map(name => [name, 0]));
  let samples = [], ages = {};

  // One queued callback per synchronous burst, not one per fence. Expiring at
  // the first microtask is deliberately earlier than the end of the full task.
  function expire() {
    pendingClear = false;
    batch++;
    if (installed) totals.clearBatches++;
  }
  function context(gl) {
    let c = contexts.get(gl);
    if (c) return c;
    c = { id: nextContext++, generation: 0 };
    contexts.set(gl, c);
    const canvas = gl.canvas;
    if (canvas && typeof canvas.addEventListener === 'function') {
      const lost = () => { c.generation++; totals.contextLosses++; };
      const restored = () => { c.generation++; totals.contextRestores++; };
      canvas.addEventListener('webglcontextlost', lost);
      canvas.addEventListener('webglcontextrestored', restored);
      listeners.push({ canvas, lost, restored });
    }
    return c;
  }
  function fenceSync(condition, flags) {
    totals.fences++;
    const result = Reflect.apply(native.fenceSync, this, arguments);
    if (result) {
      totals.created++;
      const c = context(this);
      syncs.set(result, { gl: this, c, generation: c.generation, batch, id: nextSync++ });
      if (!pendingClear) {
        pendingClear = true;
        schedule(expire);
      }
    } else totals.fenceNull++;
    return result;
  }
  function getSyncParameter(sync, pname) {
    totals.checks++;
    let fresh = false, r;
    if (pname === STATUS && arguments.length >= 2) {
      totals.statusChecks++;
      r = syncs.get(sync);
      if (!r) totals.unknownChecks++;
      else if (r.gl !== this) totals.foreignChecks++;
      else if (r.generation !== r.c.generation) totals.generationFallbacks++;
      else if (r.batch !== batch) {
        totals.staleChecks++;
        const age = Math.min(4, batch - r.batch);
        ages[age] = (ages[age] || 0) + 1;
      } else if (native.isContextLost.call(this)) totals.lostFallbacks++;
      else { fresh = true; totals.freshChecks++; }
    }
    if (fresh && enabled && !validation && !failed) {
      totals.hits++;
      return UNSIGNALED;
    }
    totals.nativeChecks++;
    const result = Reflect.apply(native.getSyncParameter, this, arguments);
    if (fresh) {
      if (validation) totals.validationChecks++;
      if (result === UNSIGNALED) totals.nativeFreshUnsignaled++;
      else {
        if (result === SIGNALED) totals.nativeFreshSignaled++;
        else if (result === null) totals.nativeFreshNull++;
        else totals.nativeFreshOther++;
        // A browser/lifecycle discrepancy permanently fails this installation
        // closed. Keep returning the actual native answer even during probes.
        totals.validationMismatches++;
        failed = true;
      }
      if (samples.length < 8) samples.push({ sync: r.id, context: r.c.id, result });
    }
    return result;
  }
  function deleteSync(sync) {
    totals.deletes++;
    const result = Reflect.apply(native.deleteSync, this, arguments);
    const r = syncs.get(sync);
    // A failed foreign-context delete must not delete the owner's metadata.
    if (r?.gl === this) syncs.delete(sync);
    return result;
  }
  function restoreMethods() {
    for (const { name, descriptor, wrapper } of patches) {
      if (P[name] !== wrapper) { totals.uninstallConflicts++; continue; }
      if (descriptor) Object.defineProperty(P, name, descriptor);
      else delete P[name];
    }
  }
  if (supported) {
    try {
      for (const [name, wrapper] of Object.entries({ fenceSync, getSyncParameter, deleteSync })) {
        const descriptor = Object.getOwnPropertyDescriptor(P, name);
        Object.defineProperty(P, name, { configurable: true, writable: true,
          enumerable: descriptor?.enumerable ?? false, value: wrapper });
        patches.push({ name, descriptor, wrapper });
      }
      installed = true;
    } catch {
      supported = false;
      restoreMethods();
    }
  }
  globalThis.EVER_DEEPER_SYNC = {
    version: 1,
    setEnabled(value) { enabled = !!value; batch++; return enabled; },
    setValidation(value) { validation = !!value; batch++; return validation; },
    resetCounters() {
      totals = Object.fromEntries(counterNames.map(name => [name, 0]));
      samples = []; ages = {};
    },
    snapshot() { return { version: 1, supported, installed, enabled, validation, failed,
      ...totals, nativeFreshSamples: samples.slice(), staleAgeBatches: { ...ages },
      scope: 'Same synchronous burst only; all fences remain native; no per-call timing' }; },
    uninstall() {
      enabled = false; batch++; syncs = new WeakMap();
      if (installed) restoreMethods();
      installed = false;
      for (const { canvas, lost, restored } of listeners) {
        canvas.removeEventListener('webglcontextlost', lost);
        canvas.removeEventListener('webglcontextrestored', restored);
      }
      return this.snapshot();
    },
  };
})();
