# Native hero motion coverage

This opt-in study extends `tools/review_hero_gameplay.gd` without changing its
historical evidence, the production capture driver, browser harness, or approved
v28 assets. The first exact-DEV11 Worn/right pilot passes its mechanical checks;
the other combinations remain unrendered. Mechanical passes require separate
inspection of the actual ordered PNGs before accepting animation.
Godot 4.7.2 `--headless --check-only` passes against the exact downloaded DEV11
PCK from source `8f5680defb9083bbe1e044d39a10612f2186e7f3` in an empty project.
This validates parsing and packed resource resolution, not gameplay or imagery.

## First exact DEV11 pilot

Study checkpoint `cda1e41a68c25cd48212b4f2f443f727175e0144` ran against source
`8f5680defb9083bbe1e044d39a10612f2186e7f3`, exact PCK SHA-256
`5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
Evidence directory: `/workspace/scratch/d5437d917805/evidence/hero-motion-coverage/dev11-worn-right-cda1e41/worn-right/`.
`hero-motion-coverage.json` SHA-256:
`89c0865239590dd3d832a79eef513872263a261a3a29880e15bc098643558af2`.

The process exits 0: 28 checks, 195 rendered samples and 143 actual 1696x780 PNGs.
Pre-contact release and movement cancellation retain zero impact events/damage.
The actual contact at sample 155 delivers damage 4, impact serial 1 and authored
native phase 0.55. Held follow-through reaches progress 0.7843 before release;
the following tail adds no damage and returns to idle.

Critical images inspected: `0055_blocked_windup.png`, `0060_cancel_release.png`,
`0086_cancel_by_movement.png`, `0155_impact_windup.png`,
`0169_held_follow_through.png`, and `0194_post_hit_release.png`.
The hero remains intact through the observed poses and reverses into locomotion.
However, the first natural wall is cell (22, 2), keeping the hero at world Y=160.
The upper tool/target area reaches the minimap overlay. This is a coverage-framing
limitation: select a lower natural corridor with the ordinary HUD/camera before
widening the matrix or accepting full swing clearance. No broad animation,
browser, audio-output or performance acceptance follows from this pilot.

The pending fixture now requires the start, adjacent contact and target cell
centers to be at world Y>=320. Every rendered sample records a framing check:
the full combined hero/tool sprite rectangle and complete target tile must be
inside the viewport and at least 8 px clear of the current visible HUD, minimap,
achievement and pickup-text bounds. It uses actual canvas transforms and records
the rectangles, minimum axis clearance, obstructions and failed sample indices.
An obscured sample is retained as a PNG and fails the case; mechanical assertions
remain unchanged. Full sprite-cell bounds are conservative. Natural world
occlusion and the appearance of motion still need actual image review.

## Existing coverage at the DEV11 checkpoint

`HeroGear.TOOLS` defines exactly: `worn`, `iron`, `runed`, `moonglass`, `ember`,
`crusher`, `comet`, `crown`, `burrower`, `pulse`, `deepcore`. Directions are
`down`, `left`, `up`, `right`. `crownseeker`/`prospector` resolve to `crown`;
`swift` resolves to `comet`. They are aliases, not additional atlas keys.

| Evidence | What it establishes | Remaining gap |
| --- | --- | --- |
| `docs/premium-polish/dev10-20260917/package-motion-readiness-dev10.json`; `../evidence/dev10-ci/hero-motion/` | Exact DEV10 PCK `8b83ed55d62841eac8e891ad6c224b101665d98f5ead63a022e66589d6266c3b`: Worn, Crusher and Deepcore, each mining left/up/right/down; twelve positive damage cases. Left/right walking and reversal precede each gear's mining. | Browser video is 848x390 at encoded 25 FPS while the PNG/WebGL buffer is 1696x780. Event timestamps are absent, direction windows are approximate, and 0.25-second release tails have no cancellation assertions. |
| `tools/qa-hero-transitions.gd` | All eleven gears/four directions load, authored frame indices and recovery resolve, five cloth styles work. | Manual visual ticks and no actual terrain damage; not rendered motion acceptance. |
| `docs/premium-polish/dev9-20260916/animation-source-readiness.json` and `package-animation-readiness.json` | Narrow Worn/Crusher pre/post-contact recovery correction and exact DEV9 reproduction. Current `player_visual.gd` still has reviewed hash `caaa2e411f9b83a3bbf5ac82bfe8801ec033f52f14734478725897bce02e8061`. | Controlled study; no all-tool/direction or browser cancellation coverage. Some original scratch captures are historical paths. |
| `docs/premium-polish/recovery/motion-final-*/` | Retained historical Worn/Crusher/Deepcore films. | Lost source/atlas candidate; these cannot clear the current animation delta. |

At cleanup revision `cb1b865`, the player/controller/Gear owner, Deep world,
Mossvein world, capture driver, and all 99 gear atlas/mask/manifest files are unchanged from
DEV10 source `23076019b53819c6c7f213b7e55d24a2f6194f83`. This preserves the relevance
of that bounded evidence; it is not an exact DEV11 package run. The full v28
still-image matrix exists in code but is not proof that its 176 hero poses were
captured on the present candidate.

Actual DEV10 Worn-left, Crusher-up and Deepcore-down sequence sheets were viewed
for this audit. They show changing native tool/body poses, but their approximate
time windows include neighboring directions and achievement overlays. They do
not resolve contact-frame timing or cancellation on their own.

## Bounded extension

Each invocation captures one tool/direction at 1696x780 on a naturally generated
first-band corridor, seed 4608, miner outfit and 340 px/s. It never substitutes
terrain, calls mining/physics ticks, or changes production poses. It uses main's
held-mine/movement routes while world, companion, lights and physics remain active.
Route selection avoids naturally present hazard radii, without disabling hazards.
Corridor checks interpolate between the actual adjacent-cell and start-cell
centers, including both endpoints at intervals no larger than 12 px. With the
current 64 px tiles this checks the full 64–256 px approach; it does not assume
that four cells span only 192 px.

The sequence observes held-mine approach, blocked anticipation, release before
contact, anticipation interrupted by movement, walk-to-idle, real return to the
same wall, delivered contact, held follow-through, and release after contact.
Drills retain their existing rotor/idle behavior; the fixture records it without
inventing an authored coast or applying pickaxe-contact assumptions to drills.

Every observation follows `RenderingServer.frame_post_draw`. Samples link pose,
requested direction, body position, mining progress, actual impact serial and
wall damage/excavation to drawn/physics frames and PNG filenames. Critical motion
windows save every presented frame; approach/idle save every sixth. Input events
identify the last preceding rendered sample. There are bounded stage, PNG and
sample limits, and failure evidence is retained.

No original terrain route in a requested direction is a fixture failure, not a
silent direction substitution. A destroyed wall counts through its actual floor
state, so high-power drill excavation does not falsely appear to be zero damage.

## Run through the existing renderer

Wait for the shared renderer owner. The new runner launches cases **serially**;
it never triggers workflows, exports a build, or publishes. Use a fresh output
directory. Start with one representative exact-package case before a matrix.

```sh
python3 tools/hero_motion_coverage/run.py \
  --output /absolute/evidence/hero-coverage-plan --plan-only

python3 tools/hero_motion_coverage/run.py \
  --godot /verified/path/to/Godot --xvfb /verified/path/to/Xvfb \
  --pack /absolute/accepted-candidate/index.pck --source-sha COMMIT_SHA \
  --gear worn --direction right --output /absolute/evidence/hero-worn-right
```

The default selection is the eight gears missing browser motion, in all four
directions (32 cases). `--gear all` captures all 44 combinations and supplies
the cancellation/follow-through observations also missing for the previous three.
Use `--gear worn crusher deepcore` for just those twelve cases. Omit `--pack`
only for an explicitly labeled source run.

`--fixed-fps 60` keeps the simulation repeatable while normal engine processing
drives gameplay. This is not an FPS test or an audio-output recording. Receipts
include source/PCK identity, harness hashes and the relevant runtime/99 hero-file
hashes. Runtime dirtiness is checked separately from CI/docs/tools changes.
The external standalone fixture loads production resources from the exact PCK;
it has no inheritance dependency on excluded `res://tools/` scripts.

Exit 0 requires all requested cases, positive real contact, negative pre-contact
damage assertions, exact image dimensions and successful native process exits.
Exit 1 retains the first failed case and stops. Usage/setup errors exit 2. The
plan-only mode exits 0 after writing commands and identity, with execution pending.
Visual acceptance remains false until a critic reviews the actual PNG sequences.

Browser integration is intentionally pending coordination: current
`_run_hero_motion()` hardcodes three gears, and `capture-web.mjs` requires exactly
twelve damage markers. Adding timestamps/cancellation and more gears needs a
separate coordinated change to both owners and a freshly exported package.

## Verified lossless storage

The original pilot's 143 PNGs occupy 330,461,965 bytes. Keeping that volume for
44 cases would use 13.54 GiB; saving all 195 observed frames at the same average
PNG size projects 18.47 GiB. These are storage estimates from one route, not
measurements of the unrun combinations.

`archive.py` was tested on all 143 retained pilot PNGs using local ffmpeg 6.1.1,
`libx264rgb -crf 0`, RGB24 input and two CPU threads. The 1696x780 video occupies
29,481,486 bytes. Decoding produced **143/143 matching RGB SHA-256 hashes**, with
no dropped, additional or mismatched frames. All original PNG hashes remain
unchanged. The bundle also retains 11 byte-identical critical PNGs (25,417,532
bytes), original sample/event JSON, the source plan and per-frame PNG/RGB hashes.
The completed benchmark bundle totals 55,186,073 bytes and took 17.052 seconds.

Benchmark folder: `/workspace/scratch/d5437d917805/evidence/hero-motion-coverage/dev11-worn-right-lossless-pilot/`.
Video SHA-256: `c9fd1ad0d1de762ea4aa771d5dca1fec89645763e5ddd1353a36e44f3a0cdad0`.
Its `archive.json` and `decoded-rgb.framehash` retain the complete comparison.
The initial pilot has 195 observations but only 143 PNGs: its archive is an
ordered frame sequence with explicitly recorded gaps, not continuous playback.

For the next checkpointed Worn/right and Deepcore/right pilots, use:

```sh
python3 tools/hero_motion_coverage/run.py \
  --godot /verified/path/to/Godot --xvfb /verified/path/to/Xvfb \
  --pack /absolute/accepted-candidate/index.pck --source-sha COMMIT_SHA \
  --gear worn deepcore --direction right --archive-lossless \
  --output /absolute/evidence/hero-lower-corridor-pilot
```

`--archive-lossless` implies `--all-frames`. For each case, the runner captures,
encodes and verifies before starting the next case. The archive uses
`--require-complete`, which rejects missing PNG samples or a mismatching fixed
60 Hz simulation timeline. A failed case or archive stops the sequence with
its evidence retained. No unverified archive can clear a case. This option
has passed plan validation; the corrected native pilots await their checkpoint.

Existing captured images can be archived separately with:

```sh
python3 tools/hero_motion_coverage/archive.py \
  --input /absolute/evidence/case --output /absolute/evidence/case/lossless \
  --require-complete --threads 2
```

The default codec prefers available `libx264rgb`; RGB FFV1 is an available fallback.
Every codec must independently pass decoded RGB hashes for every frame. Encoder
and decoder have bounded timeouts, and all frame copies retain original hashes.
The benchmark verified `libx264rgb`; it did not separately benchmark FFV1.

The durable representation is the verified lossless video, critical original
PNGs, source/sample/event JSON and both original-PNG and RGB hash manifests.
Full-frame captures retain the exact sampled simulation timeline. Opaque RGB
pixels can be regenerated from the video; re-encoded PNG compression/metadata
and therefore PNG file hashes may differ from the original, while decoded RGB
hashes must match. Alpha was checked to be 255 for every source pixel. Critical
PNG files remain byte-identical originals.

Original pilot PNGs remain local. The tools perform no source-PNG deletion or
external upload. Once the owner verifies that each lossless bundle is durably
saved, noncritical PNGs from later cases may be treated as a regenerable local
cache. Preserve the verified archive and hash/timeline manifests before such
cleanup. Lossless verification does not replace reviewing the actual motion.
