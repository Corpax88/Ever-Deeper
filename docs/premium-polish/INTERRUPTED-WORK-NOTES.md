# Interrupted premium-polish work — historical engineering notes

These notes come from the interrupted session record. Unless a change appears
in the verified rebuilt source or exact preserved patch, it is NOT saved
implementation. Test counts below belong to the missing candidate and cannot
be used to pass this checkpoint. Reconcile actual files before rebuilding.

## State lost versus state saved

The early local commit `2b5539413a64f12e3193e147a5960fcdfbc50ea6`
(tree `cbe835997d7e21d372685b9adf5f06159dcef09c`, parent `d4619e5`)
was described as 184 files, 6,482 insertions and 17,798 deletions. It was WIP,
not final quality approval. Later notes name `277215ec...` and `71034d4`.
Remote source upload did not complete before the working copy disappeared.
Do not check out a baseline and label it that candidate.

A later independent recovery produced the real saved game source `39f2172`.
Its handoff states exactly what was restored. Earlier recovery input commit
`4706a5903c2c857e924dd7246d30d720c4421370` existed locally; GitHub did not
resolve that exact local SHA during this preservation. Its surviving evidence
is copied byte-for-byte into this checkpoint so it does not rely on that SHA.

## Mining, locomotion and native export leads

The earlier runtime consumed authored `mine.times`, forced the contact frame
when stepping across impact, retained walk phase across facing changes, and
cached loadout scalars. Movement used actual motion, not joystick intent:
walking cancelled mining/damage; pressing into a solid wall at zero actual
velocity still allowed held mining. Full speed remained 340 px/s.

The native experiment coordinated feet, hips, spine, shoulders, hands and
tool. Light/Comet/heavy/drill profiles differed. Supersampled 320 px renders
with 16 samples were packed to existing 160 px cells to retain atlas GPU size.
Walk was reduced from 48 to 32 poses, freeing two eight-pose start/stop
settling ranges. Transitions used real poses rather than crossfade ghosts.
26,521 mathematical boundary checks were reported at about 6e-8 Blender-unit
maximum difference. Those checks alone did not prove gameplay appearance.

The early Worn pilot had 480 frames, eight atlases plus manifest and reported
24 runtime and 44 gear/direction/outfit checks. Later session recovery notes
reported five integrated sets: Worn, Iron, Crusher, Burrower and Deepcore,
2,592 poses plus masks; six tools remained unfinished. The replacement
production atlases and raw frames were lost. Do not mix them with the saved
canonical manifests or claim all eleven tools were rendered.

Exporter leads were `premium_motion.py`, `check_motion.py`,
`export_hero.py`, `pack_frames.py`. Some are absent from the rebuilt source.
Do not change a fingerprinted exporter midway through a resumed batch.
Use approved v28 model + native v9 tools; no recreated face or rig.
Blender was 4.5.3 LTS. Workspace extraction once produced a truncated runtime;
the working binary was extracted under /tmp. Recheck actual bytes/version.

Historical animation movies for Worn, Crusher and Deepcore are preserved.
The movie harness forced 1280×720 despite a requested 1696×780 viewport.
Treat the movies as fixed-step motion evidence, not target-phone or FPS proof.

## Feedback and performance leads

- Cache headlamp loadout data; avoid generating endless equipment arrays per
  frame. Cache light-occluder snapshots; remove per-cell dynamic calls and
  transient allocation. Earlier CPU measurements were about 0.9 to 0.45 ms
  for D2 scans and 0.58 to 0.38 ms in Deep; hardware approval remained open.
- Reuse two of three Deep chunks, generate only the incoming chunk, and retain
  nodes, lamps, resources, sites, hazards and relics. Rebase terrain damage,
  reward ownership, rope/camera/mole positions, hit phase and hazard pulses.
  Earlier streaming CPU median was 3.227 to 1.365 ms in one process.
- Avoid Deep loadout deep copies and eager workshop defaults.
- Preserve the target through impact/follow-through before selecting another
  target, unless released or physically moving. A background Surface mining
  owner had been clearing another active world's pose; only the active owner
  should write shared mining state.
- A bounded reusable `scripts/world/mining_impact_layer.gd` used existing
  biome atlases and tool-specific weight/duration with separate effect canvas.
  It avoided redrawing the whole terrain and replaced a Crusher-only array.
  That new file must be recovered from exact inputs or rebuilt.
- Three historical 180-second workloads covered Ember, hub and Deep. Notes
  reported zero orphan nodes in all 18 measurement windows and empty effects/
  drops/pickups after four seconds of pause. Software FPS was roughly 11–32
  while Blender competed for CPU. This was explicitly NOT a 50 FPS pass.

## Terrain and world leads

Deep floor checkerboards came from a random crop/tint per 64px cell. The old
candidate switched to world-anchored UVs and a common tint in both draw paths.

D1 exposed rims were added to initial corridors as well as mined cells;
the old QA fixture had assumed journal-only rims and required intentional
update. A bedrock face pass restored edge depth. Shared-corner art used
alpha-registered meshes per biome, feathered joins and correct straight-edge
alignment: several images ended visible alpha around y=77–90, not 128.
Bedrock material was blended into rock mass. Inner 90-degree joins between
different cells still showed cap/stripe seams and needed correction.
Preserved terrain migration scripts are leads, not safe baseline patches.

Surface preserved original mountain art and increased some shop scales from
0.28 to 0.43. Earlier proposed contacts were Assay (112,500), Forge (328,505),
Wayfarer (827,515) at 218×200, Starforge at 242×218. These are historical
tuning values, not automatic acceptance for the current geometry.

D2 workplaces used a shared rounded workroom with three alcoves, front
entrance anchors, architecture behind the access point, original footprints/
contact shadows/lamps and small Chakra labels. Floating boots and redundant
20Hz redraw were removed. Wrong D1 fallback for hidden D2 pockets was fixed.
280 functional checks over five seeds × four biomes and 16 front captures/
72 checks were reported. The saved source needs its own review.

The hub experiment used original wall artwork uniformly scaled 360×260 with
contiguous overlap; walk bounds Rect2(124,124,1192,732). Workshop painted
bounds were 264×190 with ground contact +46, per-footprint elliptical
collisions, and a route between surface lift and elevator. Approaches moved
from +110 to +58 to close the foundation gap. Lamps moved to perimeter
(438,105), (1048,105), (416,854), (1180,854). A hard 148-radius light disc at
the powered elevator was removed in favor of the light field.

Depth sorting enabled hub root Y-sort, player/companion z=0, and a shared
`LitDrawSections.add(paint,ground_y)` wrapper: anchor at ground_y with
counter-offset drawing coordinates. Rope endpoints were clamped to walk
bounds and moved clear of stations. Critic rated an intermediate hub 7/10;
last lamp/foundation/disc adjustments had no final recorded 9/10 approval.

## Mobile UI leads

A compact minimap was tuned to 172×112 on iPhone and 150×98 on desktop.
Goal/map occupied a top row between pet and gold; pet status sat under left
icons. Context action moved to the bottom row left of bag/mine, retaining a
206×104 touch region. Statuses had their own bottom-left zone.
The actual 16 D2 station-front captures reportedly kept hero and pet visible.

Carousel resizing clamped/retargeted motion while retaining browse position;
disabled purchases did not trigger an infinite snap. Pet-list touch stopped
momentum without accidental Learn taps, with multi-touch identity and
frame-independent decay. Reported 123 touch, 305 UI, six sizes and 59/59
native mobile checks were from the lost work. A recorded Tool Forge swipe
was visually inspected; do not transfer its approval to rebuilt source.

## Cleanup leads

The first chest removal retired eight Surface chests, Hub storage, spawn/
reward/UI/loot/events, 43 functions, 20 textures/imports and three achievements.
It kept legitimate relic echo_coffer/treasure_chamber and mineral caches.
A historical 224-check progression fixture covered held mine, pouch, sell,
forge and save/load.

Later audit found a disconnected manual base/building mode with no working
entry point, and old saved belts that continued ticking/delivering despite
an enabled=false flag. Roughly 135 functions/2,006 lines plus two belt images
were candidates. The newer verified source has restored the removal, but
audit it against the original full requirement. Preserve modern workshops,
museum, relics, elevators and commerce.

HTML prototype removal (21 files, about 1.2 MB) was part of lost work; the
rebuilt tree still contains an archive directory. Check for real use before
retirement. Deleted legacy images/files sometimes rematerialized as untracked
with their original timestamps. Do not blindly stage all and resurrect them;
use the intentional deletion inventory.

## QA and publication leads

A lost `.github/workflows/premium-polish.yml` and helper directory had been
prepared for branch-scoped source/PCK checks, three 180s Mac-native workloads,
Mac Chromium/WebKit 844×390 DPR3 tests, audio/touch and Safari app smoke.
It was not successfully executed in the historical evidence available here.
A diagnostic job was intentionally not a final release gate.

Preserve read-only workflow permissions and unpersisted checkout credentials.
Actual Apple GPU, Mac WebKit, iPhone Simulator Safari and physical iPhone are
different evidence categories. Read the existing game-testing skill and
current workflows, not these notes alone.

The native wrapper must fail on SCRIPT ERROR/Parse Error/Assertion even if
Godot exits zero. Some interrupted captures incorrectly reported zero
fixture failures while displaying a menu because scripts had failed;
those captures were rejected. Empty directories are not passing evidence.
Use matching Godot 4.7.2 templates and test exact exported PCKs from outside
the source checkout so loose files cannot overlay packaged resources.

Versions 1.0.0-rc.2 and 1.0.0-dev.9 had been used locally in lost work; they
were not proof of publication. The saved branch keeps its actual current
labels. Do not publish or update LIVE on the strength of historical notes.

