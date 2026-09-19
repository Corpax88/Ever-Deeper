# Overhead mining18B: clearer actual gameplay preview

Mats asked for the pick to be pulled behind the head and a forceful strike,
using Valheim as reference. The observed official Steam-trailer stroke at
21.80–22.90s informed a new isolated study on the unchanged Gruvepappa v28.
The FPS task remains paused. No production sprite or LIVE file was changed.

Source and reproducible commands: [overhead_swing_18](../../tools/native_motion_ingame_pilot/studies/overhead_swing_18/README.md).
Attempt analysis and exact critic findings: [REVIEW.md](../../tools/native_motion_ingame_pilot/studies/overhead_swing_18/REVIEW.md).

## Result

The new motion has an exposed rearward pick load, backward chest arch, overhead
crest and stronger forward torso bend. The support hand deliberately releases
and regrips late in recovery. This release is earlier than Valheim’s: the
approved helmet and short arms require the gripping hand beside the helmet
rather than literally above the crown. The original hand mesh remains closed.
The contact tip, fixed feet, .68s cycle and .42 impact event are retained.

The independent critic gives a **preview pass, clearer than17C**. Actual game
frames9/.167s→13/.233s→17/.300s distinguish load, crest and forward strike.
All four impact images show the working tip meeting the ore’s lower-left edge.
Frame27/.467s starts withdrawal;34/.583s–40/.683s returns to ready. No further
correction is justified by those images alone. This was ordered-frame review,
not continuous-video viewing, a9/10score or production acceptance.

## What was attempted

18A:121rig checks plus four real pose renders. Rearward load improved, but
the helmet hid the crest and striking forearm. No18Aloop or game capture.
18B: revised crest depth/height, contact shaft about the fixed working tip, and
neck-local gaze counterrotation. One pre-render reach stop at.7096497 was
corrected by reducing apex hand height. Four revised poses then passed the
bounded silhouette gate. One50frame native loop and one150frame real game
capture followed. Study17C was preserved. No camera sweep or numerical solver
search was used.

## Verification

Blender4.5.3 loads the approved private model and tool, with their existing
SHA256 assertions intact.121real rig assemblies: maxreach.6745807979<.70;
maxhand-targeterror8.3446503e-7. The free hand is checked against its authored
position, not an active shaft grip. These checks do not establish physical
clearance or aesthetics. Motion, renderer and anchor hashes match the capture.

Godot4.7.2 / authenticatedX11 / Mesa software rendering,1696×780. Actual held
mining at fixed60Hz,150renderedframes. Position stays(1696,1648), target
`endless_d000002_node_006`. Four hits each cause4damage, HP950→934.

| Game frame | Seconds | Presented cell | HP |
|---:|---:|---:|---:|
|17|.300000|21|946|
|57|.966667|21|942|
|98|1.650000|21|938|
|139|2.333333|21|934|

The existing input/release QA passed (`PASS input`). The invariant checker still
reports its documented protected `scripts/player/player_visual.gd` baseline
mismatch; this task did not edit that file. No physical-iPhone FPS or Safari
claim is made. This fixture isolates repeated worn/base-green/up mining; entry,
exit, movement, other headings/equipment and production adoption remain open.

## Deliverables

- Ever-Deeper-hakkeslag-18B.mp4: actual gameframes41–122 at60fps, repeated four
  times,640×560,328frames,5.466667s. No interpolated frames.
- Ever-Deeper-hakkeslag-18B.gif: same two-cycle excerpt for mobile preview,
  480×420,68frames at50fps,1.36s; resampled from actual frames.
- Ever-Deeper-animasjon-18B-bevis.zip: original native frames/masks/atlas,
  all150lossless gamecrops, selected full originals and all full-frame hashes,
  source identity, reports and pose-attempt evidence.
- Ever-Deeper-Fortsett-her.md: current checkpoint and preserved prior history.

Next: assess normal-speed playback, then verify entry/exit and the remaining
headings/gear before production adoption. Do not restart optional external
login or transfer an older video score to this candidate.
