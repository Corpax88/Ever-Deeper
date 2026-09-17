# Native Worn in-game pilot

This is an opt-in diagnostic based on published DEV11 source
`8f5680defb9083bbe1e044d39a10612f2186e7f3`. Only this study directory is added.
The production player, world, collision, input, mining, save owners, atlases,
materials, camera, shadow and HUD remain unchanged. Nothing here is adopted or
published, and headless success is not visual acceptance.

`capture.gd` instantiates the ordinary main scene. Candidate mode replaces only
the instance script on `EndlessDescentWorld/Player/Visual`, before the scene
enters the tree. Baseline mode keeps the production visual and replays the
candidate's actual normal input schedule. Geometry mode loads the consumer
unarmed through the real project (so its autoload dependencies resolve), and
checks natural route selection, one real hit and actual movement headlessly.
It does not claim any source pose was displayed. Setup placement and developer
entry are recorded fixture setup;
no terrain, prop or resource HP is manufactured. All action after setup uses
the main scene's ordinary mining and joystick input methods.

## Exact bank

The five files under `assets/worn/` are unchanged outputs of the native schema-2
pilot. The source is the approved v28 model/materials and native equipment;
these new motions are an unapproved study. There are 96 actual native poses:
48 each for right and up, with separate genuine cloth masks. Packing uses
160px cells on one 1280×960 page per view. The consumer loads only its active
view's page and preserves the existing linear sampler, cloth shader/color
mapping, ground anchor and scale 1.

Fingerprint:
`c0e7d6a1d7b25ed4fbcfba6270685346c978889f22d75d40a98fa28d38de4bc7`.

| File | SHA256 |
|---|---|
| manifest.json | `9a7dd27227512941adbe61a87bd70c4ef6666b9de56606dff7b5f9e97bac4376` |
| right.png | `7ed5d73c5c3d94c7438efde183399ebc723374112cfeb2e2cc1e8aa624a7d857` |
| right-cloth.png | `26f7c1da8b5ceae391ff9ae41cabe2eacd1a019d6097f74b454f4787fda9cc3e` |
| up.png | `cac5c1bdb82d69f9fa2779243d69e3d23b9a72912582449424f7338f66beee91` |
| up-cloth.png | `36d4bf2221762ea35c440605baf9f820485606b08d24fc3f38be275757574d5b` |

The capture harness checks all five hashes before scene setup. The raw 200px
manifest SHA256 is
`70cba0fc654335801273f63b5e537975344eaf3f2eefa35bee2938d38961bc0f`;
raw native files are separately preserved and are not recreated by this study.

## Bounded consumer

The only sequence is supported idle → walk → mine → walk, separately for right
and up. A bridge must start from the exact canonical sample confirmed after
an actual draw: idle 0, walk .625 or mine .625. Unsupported direction, source
phase or mid-bridge interruption fails the fixture. Input is never held back
until a convenient pose. The scripted fixture deliberately dispatches its next
normal input after the required source sample was actually shown.

State requests are coalesced before one late visual update, preserving the
normal world's final state when a physics update briefly reports idle before
mining begins. Gait advances from actual distance/88 at the real requested
340px/s. Mining uses the normal .68s cycle and .42 mechanical hit progress,
mapped piecewise to native .55. The manifest's older `mine.duration=1.45` is
not the gameplay clock. A real impact serial latches .55 for one presented
frame; HP change and presentation must agree in that actual frame.

Bridge duration is read per view. Its elapsed clock includes movement or
mining already advanced in the first packet. After a bridge, the actual game
clock continues; no endpoint hold or slower playback inserts idealized poses.
The incoming retained offset stays constant inside the bridge. Its destination
offset is added exactly once afterward; these offsets already use 160px game
coordinates, so no second .8 scale is applied. They never move the physical
player, camera or shadow. The final offset remains constant through the final
walking segment. Offset release is explicitly outside this first pilot.

## Quantization that must be judged in game

Canonical samples use the declared phases, not atlas frame arithmetic. Exact
bridge endpoint poses are present in the clip, but those phases are absent
from the canonical loop banks. At the exact nominal destination:

| Handoff | Target phase | Nearest canonical phase |
|---|---:|---:|
| Either view, target walk | .4 | .375 |
| Right, target mine | .1718739936 | .1875 |
| Up, target mine | .0989003863 | .125 |

The actual next frame may request a later phase; the report records both its
requested and selected phase, elapsed overrun and retained offset. Each bridge
has five samples, but its real duration differs by view. Rendering at fixed
60Hz does not guarantee all five samples will be displayed. The short up
walk-to-mine bridge particularly needs actual adjacent-frame review.

Raw source-to-bridge starts are not pixel-identical (16–567 changed pixels,
maximum channel differences 1–19 across the six comparisons). Analytic native
C1 checks therefore do not certify packed-frame or in-game pixel continuity.
The exporter and packed assets remain unchanged for this first review.

## Running the gated study

Use Godot 4.7.2 with an isolated data directory and an immutable source
checkpoint. Never run a heavy renderer while another study owns that slot.
First import and parse headlessly, then run both geometry cases:

```sh
godot --headless --editor --path /absolute/study --import --quit
godot --headless --path /absolute/study --check-only --script tools/native_motion_ingame_pilot/capture.gd
godot --headless --path /absolute/study --fixed-fps 60 --script tools/native_motion_ingame_pilot/capture.gd -- --mode=geometry --direction=right --source-sha=CHECKPOINT_SHA --output=/absolute/right-geometry
```

Repeat geometry for `up`. It searches unchanged generated seed 4608, depth 1
for an off-axis natural resource with a collision-clear 136px approach and
136px same-heading exit. It checks 4px-spaced route points with the actual
world collision resolver, natural nearest-target selection and hazard
clearance, then proves the route with actual normal movement and a real hit.
No alternate view, inserted rock or cleared wall is a fallback.
The initial production-visual route probes passed both directions. A direct
standalone `--check-only` invocation of the visual could not resolve the normal
`RunState` autoload; that failed attempt is preserved. The geometry command
loads it through the actual project scene and checks the real owner interface.

Only after remote checkpoint and the renderer grant, use the repository's
authenticated `run_rendered_isolated.py` route at 1696×780, adding `--fixed-fps
60` to the Godot arguments. Leave project content scaling and normal camera
behavior intact. Run candidate first, inspect its gate result, then baseline:

```text
--script tools/native_motion_ingame_pilot/capture.gd -- --mode=candidate --direction=right --source-sha=CHECKPOINT_SHA --output=/absolute/right-candidate
--script tools/native_motion_ingame_pilot/capture.gd -- --mode=baseline --direction=right --source-sha=CHECKPOINT_SHA --replay=/absolute/right-candidate/native-ingame.json --output=/absolute/right-baseline
```

Repeat for up. A failed gate stops the case; preserve its original files before
any correction. Every observed action frame has a full native PNG and SHA256.
The report binds source/file/asset identities, actual input ticks, position,
world mining clock/HP/impact, every presented sample, source bridge and
canonical handoff. Baseline replay compares actual frame-by-frame mechanics
before the pair can be treated as a visual comparison. This is controlled
fixed-step in-game input, not manual pose playback or unrestricted live play.
It measures no sustained FPS.

## Still outside acceptance

Graphical review is pending. A passing route/parser gate does not approve the
motion, material integration, foot sliding, strike contact or normal occlusion.
Inspect full frames and ordered adjacent states at actual simulated speed.
Arbitrary interrupts, pre-hit cancellation, stopping to idle, turns, left/down,
other tools/outfits, variable speed/tempo, drills, offset return, repeated chains,
full idle animation, exact export/web/device behavior and stable iPhone FPS are
not covered. The pilot ends while walking; cleanup is not a tested stop bridge.
