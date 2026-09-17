# Read-only ANGLE wait trace and one bounded app-level hypothesis

This follows the completed, unchanged-DEV11 CPU sample in [RESULTS.md](RESULTS.md). No candidate implementation, renderer run, driver setting, engine patch or production change was made for this trace.

## The observed conversion has a specific trigger

The running engine reports ANGLE `aaebda1c5a40`. At the corresponding full upstream revision, [`ContextMtl::requiresIndexRewrite`](https://github.com/google/angle/blob/aaebda1c5a40c15340d7a01a935a7c5398443272/src/libANGLE/renderer/metal/ContextMtl.mm#L2214) requires all three conditions: a non-point primitive, an active flat shader attribute, and last-vertex provoking convention. Indexed draws call `preconditionIndexBuffer`; arrays draws call `generateIndexBuffer`. Replacing indexed triangles with unindexed triangles does not escape the second path.

[`ProvokingVertexHelper`](https://github.com/google/angle/blob/aaebda1c5a40c15340d7a01a935a7c5398443272/src/libANGLE/renderer/metal/ProvokingVertexHelper.mm#L191) allocates output indices and submits a compute conversion on each applicable draw. Its input-buffer argument does not provide a persistent conversion cache. Strips are expanded into independent primitives as necessary to preserve which vertex supplies a flat value.

The apparent discrepancy between upstream's unlimited helper pool and the sampled wait is resolved by the Godot ANGLE build source. [`godot-angle-static` commit 68b4dde6](https://github.com/godotengine/godot-angle-static/tree/68b4dde66053be27da88f7a891e576a923a7f9b4) pins the same full ANGLE revision. Its [`patch_metal_cmd_buf_leak.diff`](https://github.com/godotengine/godot-angle-static/blob/68b4dde66053be27da88f7a891e576a923a7f9b4/godot-patches/patch_metal_cmd_buf_leak.diff) changes the helper pool maximum from 0 to 10; [`update_angle.sh`](https://github.com/godotengine/godot-angle-static/blob/68b4dde66053be27da88f7a891e576a923a7f9b4/update_angle.sh) applies those patches. This is build-source evidence, not an independently read runtime pool counter.

When a bounded pool has no retired buffer available, [`BufferPool::allocateNewBuffer`](https://github.com/google/angle/blob/aaebda1c5a40c15340d7a01a935a7c5398443272/src/libANGLE/renderer/metal/mtl_buffer_pool.mm#L123) flushes submitted work and waits before reusing the oldest in-flight buffer. That is the named path seen in all four disjoint sampled wait branches. The capture does not measure the queue's GPU execution time, actual buffer size, conversion count per frame, or which game owner exhausted the pool. Do not change this memory-leak mitigation or claim that every tenth draw necessarily stalls.

## Canvas versus persistent mesh

Godot 4.7.2's [canvas shader](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/shaders/canvas.glsl#L90) carries flat instance state for transforms, texture dimensions, flags and lighting. The attributes/mesh specialization retains flat fields; it is not a way to remove the required semantics.

The [canvas renderer](https://github.com/godotengine/godot/blob/4.7.2-stable/drivers/gles3/rasterizer_canvas_gles3.cpp) already creates a persistent six-index quad with `GL_STATIC_DRAW` (2815–2823). Rectangle batches use that same buffer with `glDrawElementsInstanced(GL_TRIANGLES, 6, ...)` (1308–1321). A rectangle's GDScript draw command is therefore not evidence that its index buffer is rebuilt each frame. Persistent meshes still use indexed/arrays instanced draws (1513–1520); mesh and polygon commands explicitly start their own batches (1091–1117, 1175–1183). A one-for-one rectangle-to-mesh replacement cannot eliminate the observed conversion, and may destroy existing rectangle batching.

The meaningful app-level lever is **fewer equivalent submitted batches**, not merely longer-lived input geometry. An instanced rectangle batch converts six indices for the whole draw, independent of its instance count. This is a mechanism-based hypothesis, not evidence that reducing the current game's draw count will produce a particular FPS gain.

## Current game ownership and distinct hypothesis

At exact production source `8f5680d`, `endless_descent_world.gd::_draw_terrain_section` interleaves two command families during pass 1 of each existing four-cell cached strip:

- A floor cell may add one 2-pixel, non-antialiased detail line through `_draw_floor_detail`.
- A solid cell adds its native rock rectangle and, when applicable, the existing rare-ore rectangle and damage polyline, in that order.

The engine turns the floor line into two triangle instances in its primitive path ([canvas-item line construction](https://github.com/godotengine/godot/blob/4.7.2-stable/servers/rendering/renderer_canvas_cull.cpp#L747)). Alternation between that primitive and textured rectangles breaks batches. The sampled arrays path is consistent with such primitives but is not uniquely attributable to these lines; UI and other owners use the same engine path.

**Hypothesis:** defer only the floor-detail calls until after the solid-cell calls **within the same existing four-cell section**, preserving floor-line order and every rock/ore/damage call's relative order. Keep the exact original line and rectangle functions, vertices, colors, textures, materials, section identity and complete command bounds. No mesh, atlas, cropped geometry, new light region or widened cache is required.

The local ordering change has a narrow geometric justification. Tiles are 64 pixels. The detail line's endpoints and one-pixel perpendicular half-width keep it strictly inside its floor cell (minimum horizontal inset about 2.68 pixels, minimum vertical inset about 8.05). Adjacent solid mass extends only 0.5 pixels into that cell. Rare-ore sprites stay inside solid cells; current damage polyline vertices and widths also stay away from these floor details. The floor and projecting-edge passes remain in their original positions before/after pass 1. Since the same commands stay in the same CanvasItem, its union bounds and light-culling inputs remain unchanged. Original alpha/color quantization paths remain unchanged as well.

Use the unchanged order as fallback for nonstandard/inherited world materials or any shader that displaces geometry or depends on screen/ordering state. Mathematical disjointness is only a reason to try exact pixel comparison; it is not acceptance at fractional zoom or under lighting.

This is deliberately smaller than global pass reordering. It may save very few actual draws: nearby sections can already batch across boundaries, sparse floor lines may not split a useful run, and ore/damage texture changes remain. There is no measured per-owner opportunity yet and no predicted FPS gain. The retained 810 wait samples must not be assigned to this candidate.

## Previous studies and bounded decision gate

The [rejected native-mass mesh study](../../docs/premium-polish/native-mass-rejected-20260916.md) lowered 146 to 115 draws without material frame-time improvement; even its corrected fixed images retained 21–36 differing pixels, and that correction was not timed. The [native atlas study](../../docs/premium-polish/iteration-four-20260915/README.md) lowered 188 to 149 draws while FPS fell about 39.7 to 38.6 and memory rose about 90 MB. Neither supports repeating mesh/atlas substitution. Camera, floor-blend, receiver-mask and crop results remain rejected or unadopted. The proposed command-order-only change does not recreate those representations, but those results require caution about draw-count-only claims.

If root authorizes a pilot, the smallest falsifiable sequence is:

1. Instrument only an isolated study harness to count the existing pass-1 command-family interleavings on representative saved Deep states and the established moving route. Compare predicted batch breaks and actual renderer draw counters with source/route identity. Include cross-section batching; do not equate cached-node count with draws. **Stop if the real workload offers no material draw-count reduction.** This precondition has not yet been measured.
2. One fail-first same-state A/B/A2 pixel gate at 1696×780: an actual mixed floor/rock strip, partial damage and visible rare ore, each neighboring stratum boundary, maximum hero/pet grazing illumination, and fractional zoom/rebase. Restore the exact state between variants. Retain all originals and require zero RGBA differences plus exact restored A2. Exercise any material fallback without weakening it. Stop at the first mismatch; no timings for a failing candidate.
3. Only after useful draw reduction and exact parity, one serialized same-host Mac A/B/A2 of the established 60-second real Deep route, with all effects, assets, package hashes, functional/exit/marker/raw-window gates and restoration retained. Put the same single bounded sampling window in all three variants if root authorizes sampled mechanism validation. Report its overhead and compare blocked-stack occupancy only as supporting attribution. Require total frame throughput and p95 improvement against both controls beyond control drift, with no functional regression; reduced draw count or fewer wait snapshots alone is insufficient.

No additional profile is authorized by this document. This Mac-only mechanism also requires current browser and physical-device validation before extrapolation. If the first workload-count gate is negligible, the present evidence justifies stopping app-level changes rather than another broad mesh experiment.
