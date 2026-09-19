# Simple mining swing 17: improved preview, acceptance still open

The new study replaces the previous correction stack with four authored poses:
ready, raised, impact and withdrawal. It retains Gruvepappa v28, the worn pickaxe,
the .68-second cycle and the .42 impact event. Production and LIVE are unchanged;
FPS work remains paused. No paid service or external critic sign-in was used.

Source and reproducible commands:
[`simple_swing_17`](../../tools/native_motion_ingame_pilot/studies/simple_swing_17/README.md).

## What was actually attempted

Three complete native loops and three actual gameplay captures were produced,
17A, 17B and 17C, with four-pose checks before expensive captures. Early pose
checks included two pre-render reach/assembly failures, several visibility
corrections, and 45/90/135-degree views. These are not one single successful try.
There was no numerical search over the old spline/clearance optimization stack.

- **17A:** real two-hand grip and contact, but the head appeared edge-on and the
  preparation was weak. Four real hits caused 16 total damage.
- **17B:** broadened head, lower ready pose, longer withdrawal. Holding the
  working cap fixed during all poses pulled the grips behind the helmet; this
  was corrected by preserving the cap only at impact. The 135-degree camera
  then made the head miss the visible ore. Four correct damage events did not
  establish visual contact. This candidate was rejected.
- **17C:** restored camera90 and derived the raised direction from that
  camera's up/right axes, replacing the stale camera45 basis. This reveals a
  recognisable head beside the helmet while preserving the verified impact.
  The internal critic confirms visible contact and improved lift/return
  readability, but does not grant final visual acceptance.

## Actual selected-candidate checks

The approved native model hashes are enforced by the renderer. The selected
loop contains 50 actual 200px Blender renders; no generated or interpolated
frames were substituted. The source hashes for the motion, anchor data and
renderer match the captured report. Across 121 native poses, maximum grip
error is 8.199701603e-7 model units and maximum shoulder-to-wrist reach is
0.690001251, below the .70 gate. These are geometric checks, not a quality score.

Atlas SHA256: `ac7395f5f32b092457b7890b520b7a62d27661da68b4526a40b7faff340631dd`.

The isolated Godot 4.7.2 capture contains 150 actual rendered gameplay frames
at fixed60Hz. It uses the real world, held mining, ordinary feedback and isolated
save data. Player position stays (1696,1648), target stays
`endless_d000002_node_006`, and the same atlas is verified by hash.

| Frame | Simulation seconds | Presented cell | Ore HP after hit |
|---:|---:|---:|---:|
|17|0.300000|21|946|
|57|0.966667|21|942|
|98|1.650000|21|938|
|139|2.333333|21|934|

Initial HP was950: four hits caused exactly four damage each. This checks the
real impact latch and damage clock; it does not prove visible contact by itself.

## Independent image review

The existing internal critic inspected actual ordered native/game images and
the enlarged original impact crop. It did not watch continuous video.

1. At all four impacts, the head reaches the ore's lower-left outline. The
   clear gap present in17B is gone.
2. The head reads as a pickaxe, and lift and return can be distinguished.
   The shaft is more visible, but both hand grips remain partly obscured at
   gameplay size.
3. The main unresolved issue is withdrawal: especially game27/.467s and
   game40/.683s, the head is visually close to the ore edge. Clear separation
   over the whole return and convincing weight have not been established.

This is an improved, reviewable checkpoint, not a9/10 result. The last external
continuous-video score still belongs to study15, not this candidate. No score
is transferred between versions and no continuous-video review is claimed.

## Saved outputs and continuation

- `Ever-Deeper-hakking-i-spillet-17C.mp4`: original game frames41-122, two recorded
  cycles at60fps, repeated four times for viewing. The crop includes the hero,
  target and ordinary feedback. No invented in-between frames or speed change.
- `Ever-Deeper-hakkeloekke-17C.mp4`: all50 native frames at1250/17fps, eight cycles.
- `Ever-Deeper-animasjon-17-bevis.zip`: selected native originals/masks/atlas,
  all150 lossless gameplay crops, ten full game originals, full-frame hashes,
  reports/timestamps, earlier diagnostic evidence and the source commit.
- `Ever-Deeper-Fortsett-her.md`: current checkpoint and preserved prior history.

Next work must address the observed withdrawal near the ore with a new simple,
readable path, preserving actual contact. Check the exact cited return poses
against the ore before spending another full render. Do not resurrect the old
optimizer or sweep camera angles. Show the current video as the concrete result
before committing to another substantial round.

This study covers only worn/base-green/up/stationary held mining. Entry/exit,
movement, other headings/equipment/outfits, other resource placements and camera
consistency across states are still outside acceptance. Do not adopt it into
production or publish LIVE on the strength of this loop-only capture.
