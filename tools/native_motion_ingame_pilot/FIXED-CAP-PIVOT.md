# Fixed-cap rigid-tool proposal after the rejected 7b images

The five native beauty/cloth pairs at `7b1a5dda` were rejected independently
by root and the performance critic: the working head cleared the helmet, but
most shaft and the hand-to-tool connection remained hidden. The exact failed
trial is preserved separately. Its source, contact selection, model/materials,
camera, original images and review files remain unchanged.

This next proposal consists only of three new study scripts and this note.
It has passed analytic reach/pose checks; actual rig, occluder and image gates
are still pending. No runtime, export bank or production asset changes exist.

## One constrained change

The actual native terminal-cap centroid is already bound in the saved7b
selection. For every phase, `fixed_cap_pivot_pose.py` computes that same
centroid from the saved arc, rotates the complete tool frame, then solves the
rear position so the centroid follows exactly the old path. It re-solves both
real arm chains and hands. The torso, head, root, leg chains, sole matrices and
contact flags remain the original objects. There is no actor/ore/camera move,
screen offset, image deformation or target reselection.

The centroid is preserved; the terminal patch's orientation and its other
vertices are not fixed. Their actual ore-alpha approach must be measured again.
The source is one frozen selected target, not a general aiming controller.

`probe_fixed_cap_pivot.py` checks the saved30° control and nine explicit native
orientations: 0°,15°,30° additional world-Z yaw with45°,60°,75° contact shaft
pitch. A constant genuine rotation is applied about the moving cap centroid
through windup, impact and recovery. All failures are retained. Four cases
including the control pass135 calls (134 distinct normalized phases).

The one selected candidate is +15° world-Z yaw /45° contact pitch. The same
contact cap centroid stays at native pixel approximately `(138.765,47.550)`;
the rear grip moves from `(120.036,77.152)` to `(131.793,86.437)`. This moves the
handle right and below the helmet while preserving the actual contact point.
Maximum analytic arm reach is `.67106 < .71`; cap-centroid drift is below
`1e-6`. The geometric working-face normal continues to lead the incoming
centroid velocity. These numbers do not establish visibility or image quality.

## Next bounded gate

`probe_fixed_cap_occlusion.py` requires a clean saved checkpoint and the exact
math report. It is restricted to that one15°/45° case. It loads the unchanged
native rig and measures135 actual pose records, real hand attachment, original
body/head/foot matrices and the transported source cap centroid. It then checks
actual shaft/head/hands/forearms at windup `.375` and contact `.55` using the
original629 mesh objects /2,714,340 evaluated triangles. The changed cap patch
gets a fresh301-sample projected ore-alpha trace.

No images follow automatically. An independent geometry review must first
judge whether the resulting full tool has enough unoccluded shaft, working
head and hand connection to justify another small native image gate. Actual
images, ordinary-world contact/HP timing, motion transitions, arbitrary input,
other targets/gear and browser/device cost remain open.
