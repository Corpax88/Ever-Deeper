# One return-tool trajectory study

The original recovery at .8125 and both fixed-wrist elbow swivels remain
rejected. This separate study moves the rigid tool and both real grips by one
fixed actor-space displacement outside the original .125-.625 work window.
The original body/head/feet, tool orientation, geometry and contact stay intact.

The displacement is half the original .145 grip span toward the hero's right
and one span upward. The frozen target heading determines that right axis.
Its only amplitude is 1.0; the unchanged ff96066 pose is the control. The offset
eases in from .625 to .8125, stays at full weight through .82 and the 1/0 seam,
and eases out before .125. No orientation or elbow-pole adjustment is combined.
The cap contract during recovery intentionally becomes old_cap + offset.

`return_tool_offset_pose.py` consumes the original hinge pose and re-solves
the actual arms. Only rear, grips and arms are copied from the solution.
`probe_return_tool_offset.py` first executes the unchanged original control,
then measures all 135 actual native rig phases with the original 1e-5 and
reach < .71 limits. It checks protected bones, translated tool/hand frames,
true grips, arm lengths, cap centroid, exact work window and the 0/1 seam.
Its sole candidate scene measurement is .8125 with all 629 original objects
and 2,714,340 triangles. It does not render images.

If the hand/tool connection remains absent or fragmented, stop. If promising,
independent review must authorize the same candidate's late/end geometry
before image review: 0, .6875, .75, .78125, .82, .828125, .875, .90625,
.9375 and .9921875, plus original critical phases. Endpoint equality alone
does not prove idle/walk transition compatibility or continuous IK anatomy.

Preparation is unrun. Seven exact original JSON inputs are currently missing
from the retired scratch location; supported archive recovery returned HTTP
502. Do not rebuild those payloads from summaries or use missing old paths.
Recover and hash-bind them before any engine execution. Source/parser review
is separate from geometry and native-image acceptance. No production assets,
runtime code, atlas, publishing workflow, score or FPS claim changes here.
