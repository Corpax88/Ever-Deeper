# One native working-surface image trial

This continues the saved `bbf18271` contact mapping. It changes only isolated
study tools. The current atlases, native model/materials, gameplay owners,
selection, root, camera, scale and damage clocks are unchanged. No image,
animation bank, runtime contact or ordinary-input controller is accepted here.

The earlier target-math proposal in `contact-arc-readiness.json` remains a
different, unrendered candidate. The old square-up, constant-plane and
torso/roll image rejections remain authoritative. Do not relabel those files.

## Actual working end

`inspect_working_head.py` reads the exact Worn source head. It has 7,540
vertices, 15,076 triangles, one closed component and no nonmanifold edges.
Its supplied face winding is mixed across 932 edges. The first diagnostic
incorrectly assumed consistent winding and stopped; its source/log are retained.

An analysis-only orientation propagation has zero conflicts, reverses 932
triangle signs and gives positive volume `.00117731249`. No source vertex,
normal, material, image or asset is written. A single global normal sign would
have been wrong. The actual lower tapered terminal patch contains 18 connected
coplanar triangles and 20 vertices; its area is `.00104253765`. Its rest-world
centroid is `(-.0300,-1.059173,1.104007)` and geometric outward normal is
approximately `(0,-.564637,-.825339)`.

The combined approved rig's actual tool matrix binds this surface. Using only
the separate equipment rest frame would miss that binding. Three measured
evaluated end-cap vertices agree with the stored tool-local coordinates within
`4.41e-7`; dense tool-matrix transport error is below `5.85e-7`.

## Bounded arc

The first `+10°` shaft trial approached the opaque ore interior too early and
reversed slightly before `.55`. A single arc aimed at its first cap/rim entry
then failed arm reach (`.712825 > .71`), before image generation. Both attempts
remain retained. The selected `+30°` shaft pitch reaches the same frozen rim
with lower arm extension; it is a genuine native tool rotation and solved arm
pose. It does not move the player, ore or camera.

`working_surface_arc.py` keeps the original target-facing windup through `.40`.
One accelerating rigid-tool interpolation reaches the selected contact
transform at `.55`, holds the tool there through `.625`, then returns to native
recovery by `.82`. The torso keeps its original native timing and target-facing
heading. Original cardinal-up leg chains, sole matrices and contact flags are
retained exactly. Real IK solves both arm chains and hands at every sample.
This is one frozen Worn/up case, not a general target or interrupt solver.

The closed headless report checks 135 actual rig poses. Maximum arm reach is
`.587173` against `.71`; grip error is `5.75e-7`; evaluated foot-matrix
difference is zero. The real terminal surface has positive inward approach:
outward-normal dot incoming velocity is `+8.62149` native units per second.

The projected terminal cap first samples ore alpha at `.540`, approximately
`5.19ms` before intended `.55` impact under the unchanged `.68s/.42` clock.
The head's native pixel centers have zero opaque-ore overlap at `.55`; this is
a rim-sized contact, not deep interior intersection. The real ore is a 2D PNG.
Its alpha edge does not prove a 3D surface, material contact or exact displayed
frame timing. Those remain for the actual ordinary-world comparison.

## Gate and limits

`working-surface-selection.json` binds the actual surface, fixed contact pose,
model/gear identities, failed trial and closed 135-pose evidence. The new
`render_working_surface_probe.py` requires its exact clean saved Git checkpoint,
repeats the dense native grip/feet checks, and can produce only five original
200px beauty/cloth pairs at `.125`, `.375`, `.55`, `.625` and `.8125`.

An independent source/geometry review must precede those images. The images
must then show a recognizable working pick at windup and contact, coherent
arms/waist and unchanged art identity. Geometric head visibility of 82/89 pixel
centers at `.55` is not that visual verdict. No full bank follows it alone.
Ordinary-world adjacent poses, actual ore contraction/HP timing, recovery,
transitions, arbitrary input/targets, other gear, denser mining cadence and
browser/device cost all remain open.
