# Isolated world framebuffer prototype — QA only

Mats requested autonomous repeated tests, with no phone retest until a strong candidate exists. Do not imply Mac WebKit establishes iPhone performance. No production change is approved here.

Baseline: immutable DEV15.9 public export c63aabd3e3e5120579285ce6e8b0b59a75f2727a, original run36043919958, artifact10827118862. Canonical branch codex/native-light-dev15-9-20260924 contains documentation head b0db535e084e76bdc02b1fae6a01155746806f67. Experimental source branch codex/world-scale-study-20260924.

The existing world remains in its original scene tree. A QA-only shared-world SubViewport renders the 2D world at 80% on each axis; root HUD remains full resolution. A root CanvasLayer displays the world texture. The original root World2D render canvas is moved outside the root clip in frame_pre_draw, avoiding a second shadow pass; the logical camera/input transform is preserved. Restoring explicitly reapplies the logical transform. No viewport canvas is detached.

Exact Godot4.7.2 source inspection established that canvas item cull masks alone do not prevent duplicate viewport shadow updates, and Viewport.set_canvas_transform unconditionally updates RenderingServer. Prototype does not have production scene-exit/interruption lifecycle handling and must not be published without it and separate gameplay/visual validation.

## Build recovery

- 947c5a45f2e56f7edf783598c4d3ef70e71e1d55 / run36057029295: large sparse asset checkout stalled; superseded and cancelled. No export or browser evidence.
- f6d795a7de588cc56ec48fa64bfeefe90ca43fe1 / run36057968965: full fetch hit explicit8min timeout. No export or browser evidence.
- 3fe1f68653276746c4c775db2e590b4750338c38 / run36059009147: switched to small source checkout plus exact original DEV15.9 artifact. QA-only packager appends raw source fixture/helper and replaces only scripts/qa/suites/fps_review.gd.remap. Verifies all nine baseline file hashes and every PCK resource MD5, preserves1401 original resource entries/bytes/offsets, replaces one remap, adds two source files. Rejects unknown format versions, encryption, sparse packs, unexpected flags and duplicate paths. Uses documented v3/v4 layout from exact engine source, not bytecode rewriting. Original compiled fixture remains unused in pack. Independent critic found no packaging blocker; this does not approve publication.
- Build/input/touch125/save-flavor passed. Original experiment candidate10833641481, build10833821297, Mac reports10833801489/10834280465. Both Mac runs stopped before timing at first full-scale framebuffer dimension gate. No performance claim possible.
- 5325bb94a2fdac599c2f27e8c5bfa076797e27ea / run36059410093: corrected physical size source to root Window.size. ViewportTexture.get_size in4.7.2 multiplies non-SubViewport size by stretch transform again; it was unsuitable for physical canvas sizing. Strengthened harness to record failing state and assert actual subview dimensions. Did not weaken pixel parity gates. Candidate10833359013, build10833179253; core/input/touch125/save passed again.

## Measurement design

Two separate macos-15 / Apple GPU WebKit26.5 runners. CSS776×420, DPR3, actual root2328×1260. Same seeded durable Ember mining target. Freeze and capture original, full-scale composite,80% composite, restored original. Full-scale composite maximum channel difference must be<=1 and restoration exactly0 before measuring. All modes must keep camera/player/logical viewport fixed. The80% framebuffer must be1862×1008; root remains2328×1260.

Prewarm all modes, then60s extra warmup. Each repeat measures six12s stationary and six12s actual browser mouse-held mining windows; repeat2 changes balanced order. Require>200 frames/window and>=20 mining impacts/window. Afterwards move using real keyboard input and retain actual moved-world screenshot. Mouse input is not physical phone/touch performance verification. No performance conclusion if quality gates fail; no claimed phone percentage from desktop aggregate.

Final reports and visual review are required to complete acceptance; this provenance alone is not a result.
