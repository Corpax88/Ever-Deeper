# First-frame shared-material warmup — isolated study

Base: published DEV13 runtime5ca6f0f77a1f87eaead777613062208159325068. This branch is not a published candidate. The only intended runtime changes are one add_child at the end of synchronous Main._ready and the transient scripts/lighting/first_frame_lit_warmup.gd helper. The helper uses the actual shared LitDrawSections material, one isolated16x16 UPDATE_ONCE viewport with a lit polygon, and ordinary post-draw queue_free cleanup. No Main await, bootstrap, autoload, render setting, art, shader or input change. Static_started means attempted, not verified warmed; early teardown must remain inconclusive. Script-resource lifetime bounds that guard.

Independent source review accepts a bounded graphical diagnostic only (shader-first-frame-implementation-review.json SHA0880629fd75e8ee2e5ed66e9cba4decb30799bf910d934a90d85d6524d55962b). Helper check-only parsing succeeds against the original DEV13 PCK. A separate standalone check-only of Main stopped at missing RunState autoload context; its error is retained and is not a green whole-candidate parse or proof of a candidate bug. Actual complete-project export remains mandatory.

## First bounded mechanism fixture

probe_helper.gd loads the exact original DEV13 compiled Main and installs the new helper from Main.ready immediately after original_ready. This source hook differs from the candidate insertion before Main.ready: candidate_main_hook_exercised is explicitly false. There is no replacement Main, modified autoload, input, fixture seed or persistence flag. Main uses normal fresh startup in the launcher's isolated user directory.

Two fresh processes: lit, then no_light. The second disables only the helper PointLight2D after helper_ready and before first draw. Read back the actual16x16 target after post-draw before queued deletion and retain an actual root1696x780 image; compare the opaque unsaturated interior across controls. These readbacks are diagnostic, untimed and may stall the renderer. No presented-FPS or target-WebGL-source assertion is made.

The observer snapshots an already-existing original LitDrawSections owner's shared material and shader scalar IDs/RIDs before loading the helper, then compares them with the helper and after cleanup. It stores scalar IDs/RIDs and WeakRefs, not owned strong material/shader/texture references. After normal queue flushing, all helper nodes/temporary texture and helper draw connection must be gone while original shared material/shader identities remain alive through the real Main. No World2D resource-release assertion is made. The synchronous RunState comparison covers script scalar properties during helper installation only; it does not establish full game/save/input parity. Results require actual engine exit, error-free logs, process-closed delayed file hashes and independent image review. Lit/no_light pixel comparison must prove that lighting changes the same opaque unsaturated target interior; two completion markers alone are insufficient.

The initial preflight was rejected before rendering because the fixture incorrectly expected the SubViewport getter to change from UPDATE_ONCE to UPDATE_DISABLED. Godot retains the requested getter value; only the renderer's internal mode changes. The corrected fixture records and checks UPDATE_ONCE and makes no claim to observe that internal state. Keep the original rejected preflight as evidence.

Run from an empty project with the original PCKSHA5016e16791f51790f7a10dfabe0719b308de82a80627aca8d740b0e355e6cdc3 and existing authenticated tools/run_rendered_isolated.py. Preserve3424134400-byte image-start guard,1.5GBreserve and one heavy local renderer. Each case uses --variant=lit/no_light, --helper=<absolute exact helper>, --output=<new isolated output>; Godot uses --fixed-fps60. No prototype PNG/model creation is involved.

## Still required before adoption

The real rebuilt candidate must exercise its exact Main hook and preserve original relative startup/input/autoload behavior, fresh/valid-save semantics, splash/menu/game pixels and normal/early held/released input. Observe original material/shader IDs and the actual full WebGL GLSL pair across cleanup and real mining; ensure no later same-pair compile. Existing target hashes are aecaa8e92eb4a09192a1cb4733e3a7d0edc9fc1af266c1a41147073fc107967f and8b9380594232f57892a2833bcb3295135416357c1c0bc2fde73fa32bc0092b7a from the original MacWebKit study1a85baf. Revalidate recorder/export bindings; do not blindly reuse old request approvals or DEV11 pins.

Only after mechanism, exact specialization, cleanup and game/pixel/input gates pass should a controlled timing comparison include startup-to-ready/first-frame cost and the same real route. No50FPS, physical-iPhone or unrelated-hitch conclusion follows from moving one compilation. Full premium polish remains open. The existing production DEV13 game is unchanged.

## Nonindexed avoidance candidate after actual WebGL rejection

Full Polygon2D candidate5e48e4e failed seven touch suites in35248670186 with the
WebGL element-buffer rebind and following bufferSubData errors; pause's nine
logical checks passed. All original artifacts are retained in the rejected archive.
The exact two-package trace35252779454/requestf84d196b reproduced a clean original
DEV13 and one conflicting bind on rejected5e: original object38, ELEMENT_ARRAY_BUFFER
34963 to ARRAY_BUFFER34962, followed by the same raw error pair. Its stack contains
unsymbolicated WASM function IDs; it does not identify a C++ function or scene node.

The matching Godot4.7.2 source defect is Polygon2D's internal mesh index-region
update. This avoidance candidate changes only the hidden helper's draw component:
a Node2D _draw submits two nonindexed canvas triangles using empty indices, six
vertices/colors, empty UVs and the default count=-1. There is no Polygon2D/internal
mesh or index buffer in that command path. The original shared production material,
light,16x16 separate World2D, UPDATE_ONCE, ordinary post-draw cleanup and synchronous
Main call are preserved. No visible production art or shader is changed.

The mechanism observer changes only its component annotation Polygon2D to Node2D;
all existing lit/no_light pixel, identity, cleanup and scalar-state checks remain.
Re-run the two actual native controls, then a fresh full export and original WebGL
error gates. The older native pass does not approve this new draw component. Full
GLSL identity, normal startup/input/save parity and timing remain separate gates.
