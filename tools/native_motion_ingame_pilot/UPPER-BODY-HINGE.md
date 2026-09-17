# Native up: anatomical body-hinge diagnostic

This isolated study follows the rejected fixed-cap orientation at `66bb10e1`.
No production animation, model, material, camera, world or mining owner changes.
The fixed-cap arc remains unchanged, including the actual working-surface
centroid path and its terminal orientation. The study changes only a genuine
body-joint bend and solves the two arms again to the existing tool grips.

`inspect_upper_body_joints.py` reads the approved armature without loading any
mesh. Its measured body head is `(0, 0, 0.5849999785423279)`, parented to `root`.
This is the hinge; the older authored `0.6` pivot is not substituted for it.

`upper_body_hinge_pose.py` first applies a rest-local Z twist, then rest-local Y
side lean, around that measured joint, after the original target-facing pose.
The complete head receives the same world delta as the body. Their relative
transform and the actual body joint stay fixed. Real arm IK uses unchanged
0.36/0.35 segments and the exact existing grips. All other pose fields, including
the full leg chains, sole matrices, root-related data, contacts and tool fields,
are retained from the prior pose by identity. Smooth weight reaches one at
phase `.125`, stays through `.625`, and returns to zero by `.82`.

`probe_upper_body_hinge.py` evaluates a small analytic shortlist: side lean
6/10/14 degrees crossed with twist -12/0/+12 degrees, plus the unchanged
control. Every outcome is retained. The first run passed six of ten cases;
four failed actual analytic reach without stretching bones. This is neither
evaluated native-rig nor visibility approval.

Before selecting an arc, `cache_upper_body_geometry.py` evaluates the unchanged
approved scene once. It records **all 179 head-bound objects and 2,217,334 actual
triangles**, including the full ears, face, beard, hair and helmet. Every source
vertex, including generated vertices, must have exactly one full head weight.
The exact complete modifier inventory is pinned to the second retained cache
attempt: 171 armature-only objects, one pre-armature solidify, three pre-armature
bevels, and four post-armature beard/hair/spectacle stacks. Both earlier strict
assumption failures are retained, not treated as native-scene defects. Nothing
is disabled or simplified. The cache then compares every vertex against a
second actual evaluated 14-degree-lean/-12-degree-twist head pose; the maximum
world error must remain below `1e-5`. This bounded transport check does not
replace the later selected pose's full-scene rig/occlusion gate.
Its private point cache is analysis evidence, not a replacement mesh,
LOD, image or public native-source export. Conservative hull projection may
screen the shortlist but cannot prove shaft visibility, body/arm occlusion,
material appearance or readable motion.

Only one feasible arc may advance to a separate actual full-scene rig/occlusion
check. No new images, full bank or in-game trial are authorized by these
headless results. Native originals must later show a recognizable shaft, hand
connection and working head at windup/contact before any wider continuation.
