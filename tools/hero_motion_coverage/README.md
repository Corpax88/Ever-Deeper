# Native hero motion coverage

This opt-in study extends `tools/review_hero_gameplay.gd` without changing its
historical evidence, the production capture driver, browser harness, or approved
v28 assets. It has not yet been rendered. Mechanical passes require separate
inspection of the actual ordered PNGs before accepting animation.
Godot 4.7.2 `--headless --check-only` passes against the exact downloaded DEV11
PCK from source `8f5680defb9083bbe1e044d39a10612f2186e7f3` in an empty project.
This validates parsing and packed resource resolution, not gameplay or imagery.

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
