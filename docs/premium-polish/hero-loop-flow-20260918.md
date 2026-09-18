# One bounded loop-flow experiment

User goal: continue toward an independently supported 9/10. Original approved
v28 hero, no new costs, FPS work paused. A rejected attempt must produce a cause
analysis and one revised plan before another render. A high score for this one
Worn/up sequence does not certify other tools, directions or interruptions.

## Restored starting point

Source: `219faf5f1d485bf86b1c125bd81d69cdf2df999f`, DEV13-based study branch.
The main branch is not an interchangeable runtime. Original model and Worn gear
hashes were verified against the prior proof. Exact archived pivot report was
restored and checked, not reconstructed. LIVE and published DEV remain unchanged.

## Cause and acceptance criteria

CompleteReturnMotion intentionally stops translation and rotation at idle rest
on every mining wrap. The return and new-load directions reverse roughly 140
degrees. Recorded video frames 65–80 use distinct cells: this is not a stuck
image. The independent critic supported a single local corner-rounding trial.

Replace only native phases (.85,1) and [0,.15) using cubic Hermite curves in
actual game seconds and one fixed quaternion-log chart. Keep the .68-second
cycle, .42 mechanical hit, .55 native contact, protected body/feet and rigid
two-hand grip unchanged. Changed phase zero requires fresh affected bridges.

Judge normal-speed game video for a continuous, weighted cycle without a stall,
pop or rushed stroke; readable windup/contact/return at the target viewport;
attached hands and correct ore contact; and clean entry/exit and walking direction.
Geometry and damage logs are necessary checks, not visual approval.

## Trial 01 measurements

`probe_loop_flow_kinematics.py`: 401 clock samples and 24 actual selected video
phases. Protected pose error zero, maximum reach 0.703621 against a .71 limit.
The 209.36ms rounded segment increases projected cap movement into video frames
72/73/74 from .083/.013/.354px to .355/.522/.757px at +25 degrees. Maximum cap
displacement from the baseline is only .795px in a 160px cell. The independent
critic approved one render to determine whether rasterization hides the gain.

`rebuild_loop_flow_probe.py` reconstructed all 218 reference poses and checked
12 bridges at 73 times each on the original rig. Model, source and baseline bone
bindings passed; maximum frame hand-binding error was 0.000000667. Only 15 changed
cells used by the closed 76-cell route needed new rendering; unchanged route cells
reuse exact images. All other cells are forbidden by the existing capture guard.
This is a diagnostic mixed bank and must never be adopted as production assets.

The first native invocation stopped before posing because the tracked production
manifest had not yet finished restoring. The exact Git blob was materialized;
the second invocation completed. This was a setup failure, not another motion trial.

## Video review status

Gemini Flash previously misread the short video's action sequence. The available
Pro mode was selected without an upgrade, subscription or API. Its independent
baseline review scored the right-hand +25-degree reference 5/10, identifying a
stiff pause and unclear contact. It correctly found two strikes and walking on
both sides but described walking down/away, while the actual trace travels up.
Treat that score and its motion-cause guesses cautiously; direction readability
and dense temporal observation are not established by its answer.

## Trial 01 result and revised plan

Actual gameplay passed: 119 captures, 76 authorized cells, identical input,
mechanics and setup/final world; hits at frames50/90; contact precedes squash.
Native and game evidence is saved as
`libfile_b1133fdc8be481918b9f7167677fb1fa` (270535471-byte ZIP).
Normal video: `libfile_70deacf7203c8191be90097aa221cbc1`; identical-frame 24x video:
`libfile_4b7c0a6a5ad88191afa374a4511c3b58`.

Gemini Pro received both new MP4s with neutral A/B labels and no statement of
which should improve. It reported no visible difference and scored both 5/10.
Its claim that every pose is identical is factually too strong: changed native
images and actual selected cells are proven. The useful result is that it did
not perceive a benefit. The subpixel change was too small for this review route.
The critic again described a stop near26–30s in the slowed sequence. Its suggested
independent tool overshoot was not applied because both hands must stay attached.

The source/math critic also identified a separate camera regression: retaining
the original ground vector under the +25-degree camera projects walking to
[+.73445,-.90631] instead of [0,-1], about39.02 degrees off the actual up direction.
That candidate camera is therefore rejected for adoption. Use the original view
for both sides of the next comparison, preserving valid feet and contact framing.

Trial02 changes only the rounded return window to native [.70→1→.30], still
outside the protected .40→.625 load/contact/hold interval. Cheap preflight passed
401 samples with unchanged body/legs and maximum reach .703621. It produces
11.129px maximum cap-path change in the original160px view, versus the first
trial's subpixel change. Require visible continuity at normal speed without a
new hitch, floating tool, grip error or contact regression before further work.
The dedicated --loop-flow-probe guard permits only the same closed original-view
route and records the exact bank identity. No production runtime has changed.

## Trial02 result and Trial03 visibility preflight

Trial02 passed the actual119-frame game replay against original0 control.
Input, mechanics, world and hits50/90 match. Gemini Pro again scored A5/B5
and alleged identical poses, despite31 verified new native cells. The helmet
and backpack still hide most of the mathematical11px cap-path difference.
Its negative perception is useful; its frozen-pose diagnosis is not established.

A fresh Gemini context correctly distinguished a frozen control from the119
actual moving frames and counted two hits/upward walking. It incorrectly
described ore destruction although HP remained. This calibrates gross event
recognition, not exact temporal/contact grading. No paid API was introduced.

Trial03 changes the load shaft to normalize(up+.35*shoulder_right), carrying
the normal by the shortest rigid rotation. Initial dz=-.04 failed reach at
construction; tool-only analysis found maximum reach.800 and dz<=-.204822
for a.68 budget. Selected dz=-.21 preserves the original.71 IK solver and
passes401 samples. Four real-rig visibility stills at .953448,0,.40,.523810
are assessed before any full bank or game capture. Frozen contact stays intact.

The independent critic rejected those four stills for full-bank rendering:
the wrap still hides the tool and hands. Only the load pose improves locally.
Next diagnosis tested a side-carry point at native200[142,108]. Without body
rotation it needs.936 left-arm reach, so translating the hands alone cannot
meet the silhouette and anatomical constraints simultaneously.

Trial04 gives the original torso/head one extra-40-degree local-Z turn about
the measured body joint during the return window, smoothly zero at.70/.30.
At the side point, analytic depth selection minimizes the worse of the two
wrist distances: both.65805. Original bones/arm lengths remain untouched.
Two Hermite segments pass through this point with shared nonzero velocity;
the original clock, hips/legs/feet and contact.55-.70 remain fixed.
401 actual IK samples pass (max.676537). The first real-rig waypoint image
makes shaft/tool and hand gesture readable, without an obvious waist gap.
The independent critic supports one cheap50-pose native cycle video at the
actual.68-second timing before any full bank. Large fast torso unturn and
intermediate hand/pack intersections remain explicit visual risks.

This native prototype is not an actual game test. No bridge, whole-scene
contact, other direction/tool or production approval follows from it.

Trial04 native video received3/10 in fresh Gemini Pro context. Its claim of
almost no body rotation is inaccurate for the full40-degree return, but weak
stroke readability is independently corroborated by actual poses and math.
The outward load projects the cap only5.38px from contact versus28.69px for
the original overhead load. The local critic inspected8 new native frames
plus the original load, and supports restoring that overhead load while
retaining the visible side return. Trial05 rebuilds the end conditions from
that source, not a pasted image splice;401 IK/feet/joint checks pass before
the next bounded50-frame native video. No full-bank work yet.

Trial05 also received3/10 from fresh Gemini Pro video review. It recognizes
clearer phases/loop continuity but again claims almost no torso rotation.
That statement is not accurate for the40-degree return; lack of convincing
weight through the strike remains a concrete visual question, not a reliable
overall numeric certification. Trial05 native source36ec9757 and locald4ddbbb
have identical treea761af48c38052e42f62f9bebc3dbc6eb8e19810.

Trial06 tests body loading/compression with the05 tool and soles fixed.
An initial extra translation/twist/backbend version failed reach.7125 at
native.324107 and stopped before rendering. Independent projection analysis
showed forward translation would cancel most visible vertical compression.
The revised candidate therefore changes only vertical shift+.020 at.38,
-.030 at.55, -.045 at.59 and forwardbend0/8/12degrees. Body compression peaks
about35ms after contact and returns to zero by.86. Actual401 IK samples pass:
maximum arm.689104, leg.330045; exact original tool/grips/soles and limb lengths.
Three native rig stills at.38/.55/.59 precede any further cycle video.

An inspected source hypothesis about a fixed hips bone was rejected: the
original model has no hips-weighted meshes. No rig adapter/common rig edit
was made. Torso/head and leg hip endpoints move together; original root and
sole placements remain. No acceptance follows from the geometry pass.

Independent still review rejected06 for another50-frame video: anatomy is
plausible, but compression stays subtle and the forward lean keeps the head
high in projection. One contact-pose experiment07 then rephased torso turning
into the strike. Total extra local turns are0:-40,.30:0,.55:-30,.70:-35,1:-40,
with quintic joins. The original40-degree side-return knot remains reachable.
The06 compression and exact05 tool/sole paths remain.401 actual IK samples
pass (arm.688990, leg.330045). A single native contact image shows more face
profile and lateral backpack movement without an obvious waist/shoulder gap.
The independent critic supports one07 native cycle film; hands/shaft still
sit close to the face. Visible driving of the strike and smooth continuation
through the side return must be assessed in motion. No full bank yet.

No visual acceptance, 9/10 claim, full-input coverage or game publication is
recorded here. Trial01 local test commit0b1706c and remote commitbdcad8b have
the identical treefd839378e0b8e6e7bd477e7497ef53a493ccca22; the connector supplied
the remote commit because the shell has read access but no push credentials.
