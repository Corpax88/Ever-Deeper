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

The exact original inputs have now been recovered and independently bound.
The first actual eb61cefc run exited 0: 135 rig poses passed, including 69
exactly unchanged work poses. The full unchanged control was reproduced.
At .8125 the candidate exposed 22 pixels of each original hand and joined
both hands, shaft and head in one 181-pixel component; original recovery had
R0/L6 and three components. This is geometric evidence, not image approval.
The closed result SHA256 is
`ee653f7b14212dcce2ba039cd10d5a69cf329824452bb5c975208601fa8d3982`.

`probe_return_tool_offset_late.py` is an additive observer for the same frozen
candidate. It takes the original arguments plus `--reference-result`, bound
to that exact closed result. It replays the unchanged control and all 135 rig
poses, checks the full candidate result against the reference, then evaluates
the 15 declared critical/late/end scenes. Work-window geometry must exactly
match the original control. All results, including occlusion or disconnected
components, are retained for independent review before any image rendering.
No production assets, runtime code, atlas, publishing workflow, score or FPS
claim changes here.

## Closed image and timing observations

The 15-phase geometry run, 26 native keyframe images, and 50 equally timed
samples of both trajectories have now completed. All use the original model
at 200px. The closed loop result is
`d30fdffe5a1782dc847ebef4dfaff8af3b937069ec36dd741b9abc8c90b44770`.
The source clock is .68 seconds, with the .42 gameplay hit mapped to native
.55. The comparison film uses those actual renders without interpolation.
Its encoding cadence is not measured game FPS. Independent sequence review
finds a useful return-grip/shaft visibility gain, but does not approve robust
two-hand readability, real-time motion, gameplay or production integration.

## Mining entry and exit

`return_tool_offset_motion.py` supplies the full frozen mine pose to both
canonical sampling and a study-only `Transition` subclass. Idle and walk use
the original resolver. `Transition.sample`, clock, foot, root and retained
offset logic remain unchanged. The return offset is never added to an old
already-blended bridge.

`probe_return_tool_offset_transitions.py` prepares one bounded check of
walk .625 to mine and mine .625 to walk. It first reproduces all 50 observed
loop matrices with the shared resolver, then applies 65 actual rig poses per
bridge. It checks grips, lengths, reach, unchanged lower body, and exact
endpoints including the destination offset. World endpoint velocities use the
existing native continuity observer with gameplay root motion restored.
Only after these checks does it render exact quarter-clip poses and nearby
continuous 60Hz time samples. This observer is unrun until an actual result
is recorded; no runtime bank or production asset is changed.

Those continuous images do not certify the five-sample bank's quantized
handoffs. The preserved up pilot first shows canonical mine at elapsed
.0666667s and walk at .0999993s, after the nominal .0513563s/.0838055s bridge
ends. An eventual bank and actual input capture must judge their selected
images and placement without inserting an endpoint hold. A 50-time mine bank
also lacks the supported .625 exit phase. Stops to idle, arbitrary interrupts,
other views/targets and production remain outside this two-bridge study.
