# Isolated opaque-floor blend pilot

Status: the four-state and full 22-state frozen gates passed with exact pixels. The first moving attempt stopped at original A's missing completion marker; no candidate timing exists. Reporting hardening is prepared for a fresh checkpoint, with no graphical retry yet. See `RESULTS.md`. No production file is changed. This is a hypothesis, not a measured dominant cost, an accepted optimization, or a 50 FPS claim.

## Source and question

The study is based on DEV11 `8f5680defb9083bbe1e044d39a10612f2186e7f3`, tree `48b24a93faaa6f77d7a53c404cfb1228d7f825e0`. The Deep world, floor shader, section implementation, and Deep scene are byte-identical to the earlier DEV10 camera study. Main includes DEV11 feedback changes.

| Production source | SHA-256 |
| --- | --- |
| `scripts/world/endless_descent_world.gd` | `5115995cf0b1b531d51a65af832a9a818f2e14136abee3bc922b2f47fb3667ac` |
| `scripts/lighting/lit_draw_sections.gd` | `260dc901a518ee71f18451bd9e1025889d1bb5fbce46f678aaf13a47a1f64eac` |
| `shaders/lit_biome_floor.gdshader` | `b45f9fff49a5eeeaa31f12b167290088c99ea36aa652a155df82797695a465c7` |
| `scripts/main.gd` | `82410858baa28fe034fec345eac3e52d885d96d778d8918a2c603e81fc5d9cb0` |
| `scenes/endless/endless_descent_world.tscn` | `f72be328e1e6bf7cc349d4ab3339abd14babe275178e6f25ad22ccf7db37a8e1` |

Question: does disabling fixed-function alpha blending for the existing opaque floor pass reduce actual frame cost while preserving every framebuffer pixel? `controller.gd` makes a duplicate shader with only `render_mode blend_disabled;` added. The original vertex, fragment, and light calculations, materials' parameters, textures, geometry, command order, light lists, and dynamic callbacks remain in place.

Existing evidence establishes rendering as the largest measured category. It does not identify alpha blending as the cause. The previous moving camera A/B/A2 medians were 18.586 / 18.843 / 18.785 ms renderer CPU and 18.463 / 18.745 / 18.663 ms software GPU; reducing setup work did not establish an FPS gain. Native Mac GPU timing was unsupported and its frozen profiles had substantial drift. No result here should be extrapolated to physical iPhone hardware.

Godot 4.7.2's [GLES3 canvas renderer](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp) disables `GL_BLEND` for `BLEND_MODE_DISABLED`; ordinary MIX uses source alpha and one minus source alpha. This removes a specific operation only when the shader's final alpha is exactly one. Pixel and timing gates must decide whether it helps on the measured renderer.

## Conservative opacity proof and fallback

The helper recognizes the exact source world and shader. The five actual imported floor textures are proved opaque; a changed texture invalidates the image proof. All native/previous/next floor textures and boundary noise must be known and finite. Floor tint alpha must be one, and every wash alpha must equal the source's float32 0.28. Native floor alpha and adjacent floor alpha therefore remain one in the interior and both seam branches; the existing alpha expression `(1 - wash.a) + wash.a` is retained. Exact framebuffer comparison still tests compiler and blend rounding.

The guard checks actual CanvasItem parent and self modulation through the world/section ancestry, each visible floor section's own modulation, and visible same-canvas CanvasModulate nodes. Their alphas must all be one. It also checks the actual floor material, original floor paint callable and bounds, an initialized nonempty section set, finite material colors/coordinates, and the standard opaque root framebuffer. Unknown shaders, textures, paint, canvas, HDR mode, or alpha state restore the source blend shader. An external shader replacement is preserved.

Checks run at `RenderingServer.frame_pre_draw`, after normal scene/draw updates and before rendering is submitted. An alpha tween need not trigger a terrain rebuild for fallback. The audited DEV11 source has no existing `frame_pre_draw` callback or direct `canvas_set_modulate` call. Direct RenderingServer mutation or a later callback introduced outside this audited source would require a new proof. The helper reads private section/material state only inside this isolated experiment; any adoption would need a reviewed owner API.

The [engine canvas shader](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shaders/canvas.glsl) applies canvas modulation after the user fragment shader. Checking the floor PNGs alone would therefore be insufficient. The [render submission source](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/rendering_server_default.cpp) establishes the chosen pre-draw barrier.

## Prepared gates

1. `check_opacity.gd` uses the actual DEV11 scene/resources and genuine section setup in headless mode. All 18 checks passed: normal opaque, opaque RGB tint, material/parent/world/world-self/section-owner/item/item-self/canvas alpha, unknown wash, replaced neighbor texture, missing noise, external shader preservation, transparent target, unknown paint, wrong paint bounds, and restored opaque state. Source shaders restored on exit. This proves guard behavior only; it does not execute or verify framebuffer blending.
2. The first graphical run is bounded to `review.gd --quick-gate`: four frozen A/B/A2 states at 1696 × 780 covering normal floor, a real inherited-alpha fallback without terrain redraw, previous seam, and next seam. It stops at the first failure and cannot unlock timing. Only if this key claim passes may the prepared full 22-pair matrix follow: normal; material RGB/alpha; inherited, self, item, canvas and target alpha transitions; external shader; all five floor families; previous/next seams; strong grazing hero/pet lighting; actual wall damage; fractional camera/zoom; actual down/up rebases. Every A/B and A/A2 image must match exactly. Eligible B states must actually activate the candidate. Ineligible states must fall back. Visible alpha controls must alter pixels, branch/family coverage is recorded, and no-redraw transitions must have zero new terrain setup. An identity parent, shader TIME lock, paused scene/tweens, and fixed camera are applied equally to all variants; this is visual QA, not FPS evidence.
3. Only after the complete pixel gate and root's checkpoint/release may one serialized 60-second moving A/B/A2 triplet run. `run_session.py` composes the unchanged production held-mining route with the bundled observer and helper. The helper is disabled in A/A2 and active in B. Its full per-frame guard and shader-state cost is included and recorded separately. Genuine route clocks, input, physics, mining, and dynamic callbacks remain live. Both control restoration and each successful process/completion marker are required. Any failed/incomplete run is retained; a pixel difference rejects the pilot before timing.

The timing generator refuses to run without a successful 22-pair `parity-gate.json`, matching controller hash, and both graphical completion markers. `--generate-only` prepares and parses a harness without rendering.

## Local preparation evidence

Evidence resides in the session's sibling `evidence/` directory, separate from production:

- `floor-blend-guards/`: first headless fixture error, caused by incorrectly treating Main (a Node) as a CanvasItem. It was interrupted with exit 130, retained, and is not a successful comparison.
- `floor-blend-guards-parent/`: corrected actual-parent fixture, 16/16 checks; exact tested sources retained.
- `floor-blend-guards-complete/`: final 18/18 checks, exit 0 and success marker; exact controller/fixture snapshots and source identity retained. `rendered` and `pixel_or_blend_equivalence_proved` are false.
- `floor-blend-generated-check/`: generated moving harness and source hashes, parser check only.

The original failed A remains untouched and excluded from comparison. The hardened generator retains the original final stdout print, adds a stderr mirror at the same final completion point, and records entry/final print settings and source/variant hashes in `execution-receipt.json`. Both receipt writes occur outside timed windows. The runner requires the receipt after the existing explicit-marker/error/process-exit gate; duration, functional, workload and raw-sample checks still apply. It does not force print flags or infer why the original output was missing. Controller, observer, pixel fixture, production code and timed route remain unchanged.

Candidate timing, physical-device performance, and production adoption remain pending. No earlier rejected camera, receiver-mask, contour, shadow, or quad experiment is included in this change.
