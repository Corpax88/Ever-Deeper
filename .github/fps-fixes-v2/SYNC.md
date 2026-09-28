# Sync investigation, 28 September 2026

Status: QA observation only, default disabled, excluded from the v2 release. No actual-game fresh-sync hit or performance benefit has yet been established. Preserve the original fence, buffer, draw and wait operations. The accepted FBO file is unchanged (SHA256 `5322b622762de251bfbc386cec604a22794e73189b494f8a108f7607ded3b751`); root parked that candidate because its measured FPS benefit was inconsistent.

## Primary-source result

[Current WebGL 2 editor's draft, sync objects](https://registry.khronos.org/webgl/specs/latest/2.0/#3.7.14) requires sync status to stay unchanged during one task. A newly created sync cannot report completion before the browser regains control. This is an API-observable constraint, not a statement that the GPU cannot already have finished. The older 2017 2.0.0 snapshot does not contain this particular explicit sync wording; do not cite that snapshot as the proof.

[HTML microtask processing](https://html.spec.whatwg.org/multipage/webappapis.html#perform-a-microtask-checkpoint) supports conservative early expiry at a microtask checkpoint. However, an already queued microtask can precede the expiry callback. The prototype's freshness counter is therefore an opportunity probe, not by itself a universal proof of a single synchronous stack. Before enabling this candidate after a positive trace, explicitly bound it to the engine's synchronous rendering callback and exclude a nested event-loop yield. The current harness runs it disabled and removes all wrappers before FPS measurement.

The [current WebKit WebGLSync implementation](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/html/canvas/WebGLSync.cpp) already avoids reading driver status until a queued WebGL task permits refreshing its cached value. [WebGL2RenderingContext](https://github.com/WebKit/WebKit/blob/main/Source/WebCore/html/canvas/WebGL2RenderingContext.cpp) schedules that task on fence creation and consults the sync's cache when queried. Thus a fresh-sync shortcut is likely to remove only a JS/native binding call, rather than the costly later driver-status query. These are current upstream sources, not an identity proof of the tested WebKit binary.

## Exact game/engine path

The immutable DEV15.16 `index.js` in `/tmp/ever-deeper-round2-original` was reverified: SHA256 `4cb9a7427e6528dd04c42bfad1433fd88ddd4f27e49450cced41694ee54cda7f`. Its `_emscripten_glGetSynciv` directly invokes `GLctx.getSyncParameter(GL.syncs[sync], pname)`; creation and deletion likewise use `GLctx.fenceSync` and `GLctx.deleteSync`. The wrapper therefore observes the actual exported imports without modifying WASM or PCK.

[Godot 4.7.2 canvas renderer](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp) queries `GL_SYNC_STATUS` before reusing an instance-data buffer (`canvas_render_items`, approximately line 120), inserts a fence at the end (568), and advances its buffer ring. Initialization creates three buffers; an unsignaled recent buffer causes the ring to grow. Successfully reused buffers have their fence deleted. This predicts few same-task creation/query pairs after warmup and little opportunity for repeated-query caching. It does not prove the actual runtime hit count. Removing fences or assuming older fences signaled would change buffer-reuse decisions and is excluded.

## Probe API

Load `sync-candidate.js` before `index.js`. No dependencies. `EVER_DEEPER_SYNC` exposes:

```js
EVER_DEEPER_SYNC.setEnabled(false); // keep this for the current QA run
EVER_DEEPER_SYNC.setValidation(true);
EVER_DEEPER_SYNC.resetCounters();
// Run an ordinary surface/mining workload for a bounded observation window.
const trace = EVER_DEEPER_SYNC.snapshot();
EVER_DEEPER_SYNC.uninstall(); // before all performance windows
```

`freshChecks` is the opportunity count; `nativeFreshUnsignaled` must match it, with zero `validationMismatches`, before investigating activation. `failed` permanently latches on any native discrepancy, surviving counter reset and toggles. `checks`, `statusChecks` and `staleChecks` show whether there was a meaningful trace; zero fresh checks means no observed opportunity, not proven optimization. `staleAgeBatches` counts elapsed expiry/toggle epochs, not engine frames or milliseconds. Samples contain at most eight numeric IDs/statuses. There are no per-call clocks or stacks. Require `supported`, `installed`, and nonzero `statusChecks` when evaluating an observation.

The prototype tracks successful native creations in a WeakMap, ownership, deletion, context generations, and microtask expiry. It uses native `isContextLost` before a potential shortcut, including loss before DOM-event delivery. Non-status queries, coercible non-number enum arguments, unknown/foreign/deleted/old-generation syncs, failed creation and expired syncs remain native. Invalid arguments preserve native handling. Unsupported environments install no prototype changes. A single queued expiry callback covers a burst of fences. Disabled reference mode still incurs wrapper, metadata, counter and microtask overhead and must not be treated as a clean original performance page.

`node .github/fps-fixes-v2/sync-test.mjs`: 19 independent task/lifecycle-oracle cases pass. They cover same-burst/expired status, native fence preservation, arity and enum errors, foreign/deleted/unknown syncs, context loss and restoration, toggles, validation discrepancy fail-closed behavior, pending errors, bounded samples, missing capability and uninstall. These establish the prototype's described mechanics; they are not browser conformance, proof of a universal task boundary, actual hit evidence, GPU-time measurement, or a physical-iPhone FPS result.
