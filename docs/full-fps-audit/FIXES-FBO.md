# Concrete FBO validation candidate

## Scope and ownership

This candidate changes only repeated framebuffer-completeness validation in the browser glue. It does not change any draw, attachment, allocation, shader, light, depth prepass, texture dimensions, resolution, hero update, game state, or saved data. No publication is authorized by this document.

Files owned by this subtask:

- `.github/fps-fixes/fbo-candidate.js` — independent startup script, no dependencies.
- `.github/fps-fixes/fbo-test.mjs` — bounded semantic/lifecycle test.
- This document.

Parent's `build.py` inserts the script inline before `index.js`; no separate installer is needed. Baseline files at `/tmp/ever-deeper-round2-original` were independently checked: engine JS `4cb9a7427e6528dd04c42bfad1433fd88ddd4f27e49450cced41694ee54cda7f`, WASM `fc74679e3b97f76878947fcd4fbe1268cbfa6188182a2e33bbc3f5dc9bfa57d0`, PCK `ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72`.

## Why this precise configuration

Run 36407069342 observed exactly one repeating FBO-validation group on both Mac WebKit workers: framebuffer target 36160, native COMPLETE result 36053, one depth-stencil texture attachment, level 0, 400×400, no color attachment. Every repeat after the first had the same tracked state (226/226 and 295/295). Native call wall time averaged approximately 0.445/0.321 ms; this is not GPU time or a demonstrated saving.

The Godot 4.7.2 source `drivers/gles3/storage/render_scene_buffers_gles3.cpp::check_backbuffer` creates/attaches missing color/depth textures conditionally, but checks completeness unconditionally. The call from `rasterizer_scene_gles3.cpp` occurs for native screen/depth texture use. This is a supported source explanation of the trace, though its WASM stack was not symbol-resolved. Modifying/rebuilding the complete engine would widen the exported binary change; the narrow browser guard can be tested against the existing byte-bound WASM.

## Contract and fail-safe behavior

Only `checkFramebufferStatus(GL_FRAMEBUFFER)` on an **observed, live, offscreen FBO with exactly one level-zero 400×400 TEXTURE_2D depth-stencil attachment** is eligible. The attachment must have a recognized depth-stencil allocation format. Its first result always comes from the native browser function. Only a native `FRAMEBUFFER_COMPLETE` result is retained; an incomplete/error result is never cached. Default framebuffer, color/mixed attachments, renderbuffers, layered textures, other sizes, and READ/DRAW query targets always use native validation.

A hit requires unchanged framebuffer revision, attached-resource identity and revision, context epoch, and API-toggle epoch. Ordinary binds and uploads to unrelated textures do not invalidate it. It is not a time-based or “assume complete” shortcut.

| Event | Behavior |
|---|---|
| Texture 2D/layer/renderbuffer attachment changes or detach | Invalidate that FBO; any nonmatching attachment shape becomes ineligible. |
| Attached texture `texImage*`, `texStorage*`, compressed image definition, `copyTexImage2D` | Invalidate resource; unrecognized formats/layouts become ineligible. |
| Attached texture parameter or mipmap generation | Invalidate resource, including base/max mip levels. |
| Renderbuffer storage/reallocation/multisample | Track invalidation; an attached renderbuffer is never eligible. |
| Texture/renderbuffer delete | Mark resource dead; no cache hit can use it. |
| Framebuffer delete | Mark FBO dead and discard its cached status. |
| Read/draw buffer selection | Invalidate the affected read/draw-bound FBO. |
| Canvas size change | Advance context cache epoch; require a native check. |
| Context loss, including before the DOM event | Check native `isContextLost` before any possible hit; clear tracked resource/FBO state and use native validation. |
| Context restoration | Clear state again, read initial bindings, and require newly observed resources/native results. |
| Unknown/suspicious bind or attachment state | Disable caching for that context and retain native validation. |
| Supported extension outside the explicit safe list | Disable caching for the context permanently; do not guess extension mutation behavior. |
| Missing required WebGL2 methods | Disable cache support, retaining native behavior. |

`texSubImage*`, compressed subimages and copy-subimages change contents, not image format/dimensions/attachment completeness, so they require no cache invalidation. Context loss caused by any operation is checked before a hit. Draw/shader/blend/viewport changes do not change FBO completeness and are not intercepted.

The safe-extension list contains the read-only, enum-enabling, query, draw and rasterization extensions used by this exact WebKit export, plus explicit equivalents. Attachment-changing extensions such as multiview or multisampled-render-to-texture are deliberately not accepted: a non-null result makes the context use native checks. A null unsupported extension changes no state. The context-loss extension is handled by native loss detection plus DOM events. This is conservative; a future unrelated extension can disable the optimization without affecting graphics.

This is a **startup-only installer**, loaded before the engine obtains/caches GL methods or extensions. It must not be injected late into an arbitrary third-party renderer. Unobserved resources/bindings encountered by the installed engine fail to native rather than being trusted. All intercepted GL mutations still call the original browser method with the original arguments. Failed or suspicious binding attempts fail closed instead of following guessed state.

## Toggle and evidence API

Default: enabled. To start a reference page with tracking but native validation, set `globalThis.EVER_DEEPER_FBO_START_ENABLED = false` before loading the script.

```js
EVER_DEEPER_FBO.setEnabled(false); // native checks, tracking remains current
EVER_DEEPER_FBO.setEnabled(true);  // first eligible check is native again
EVER_DEEPER_FBO.resetCounters();
const evidence = EVER_DEEPER_FBO.snapshot();
EVER_DEEPER_FBO.uninstall();       // restore prototype methods if still owned
```

Snapshot exposes `supported`, `enabled`, `checks`, `nativeChecks`, `hits`, `stores`, `misses`, invalidation/reset counts, fallback counts, and `lastFallback`. Absent counters mean zero. No per-call timer, stack collection, JSON serialization, network operation, or frame observer exists in the runtime. Hot bind methods use fixed-arity wrappers to avoid rest-array allocation. Initial binding queries occur once per context/restoration; ordinary calls do not query bindings back from the driver. Native `isContextLost` is checked before an eligible cached status could be used.

Tracking wrappers have a real cost even with the optimization disabled. Therefore the decisive test must also compare a fresh original page with no script against a fresh complete candidate page, as parent's harness does. Do not claim speed from only on/off comparisons within the wrapped page.

## Validation completed and acceptance still required

`node --check .github/fps-fixes/fbo-candidate.js` passed. `node .github/fps-fixes/fbo-test.mjs` passed 25 cases, covering actual native-call preservation for disabled reference/incomplete states; every allocation/mipmap/parameter/attachment invalidation category; texture/renderbuffer/FBO deletion; unrelated uploads retaining hits; size changes; context loss before its event and restoration; unsupported extensions; invalid/foreign bindings; query target separation; narrow eligibility and uninstall. Its independent fake native status changes when attachment storage/deletion changes, so it detects stale COMPLETE results. These are semantic tests, not proof of real GPU behavior or Safari performance.

Parent's Mac acceptance must require:

1. FBO-enabled windows produce actual cache hits, with zero unsafe fallbacks; disabled windows produce zero hit deltas. Otherwise the candidate can silently fall back and a timing comparison would not exercise the fix.
2. Exact images and unchanged native viewport/light/depth-prepass state, including gameplay mining and supported world/hero lifecycle.
3. Native validation resumes after mutations/resize, then stable hits resume. Semantic tests already cover these; one real browser resize/DPR roundtrip is useful lifecycle evidence.
4. Unwrapped original-package versus production-candidate timing retains all windows/outliers and accounts for wrapper overhead. No iPhone claim from Mac evidence.

No test result at the time of this document establishes the candidate's end-to-end FPS gain or accepts it for publication.

## Primary sources reviewed

- https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/storage/render_scene_buffers_gles3.cpp
- https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_scene_gles3.cpp
- Exact immutable export `index.js` directly invokes `GLctx.checkFramebufferStatus(x0)`; the candidate preserves that native call for every miss/fallback.
