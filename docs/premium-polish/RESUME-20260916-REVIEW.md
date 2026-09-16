# Continued premium review — 16 September 2026

This supersedes the pending checks in `HANDOFF-20260916-PREMIUM.md`, while
retaining its native assets, private archives, user mandate and release limits.
Work resumed from remote `856d4cfa001a1f969bd1c6427aa846e3b4718e7f`, exact tree
`af4ea85deb68ecd6a25172eacd8d649781f323e3`. Nothing has been deployed.

## Completed scoped changes

- The full surface matrix now passes **29/29**, with **54 actual 1696×780 captures**.
  The Hub route targets its doorway, instead of the solid left support. Native
  masonry remains opaque and stationary; only its inlay/glow pulses.
- Wayfarer increased 12% and Starforge 20%, with grounded bases and matching
  collision footprints. Assay/Forge remain unchanged after the critic identified
  them correctly as open workstations. The two-resource mobile objective now
  uses one row, uncovering Starfall's summit. Surface metadata/tests describe
  the actual native split arches, replacing stale 150px atlas expectations.
- An independent critic inspected 16 final surface captures and found no
  remaining blocker within that scope. This is not whole-game approval.
- The current 1.0 world journey now routes actual movement/mining around solid
  ruins, preserving collision, resource bounds, seam continuity and all relic,
  construction and save assertions. Seed 57988582 reproduces the old straight
  route's obstruction. Both isolated and broad headless runs pass **461 checks**.
  `--qa-world-seed=` allows other explicit seeds; route PNG capture is opt-in.

## Measurements and limits

`resume-20260916/save-cost.json`: isolated version-3 binary saves measure
0.815–1.017ms at 3 bands, 1.529–1.841ms at 100, and 7.807–8.718ms at 1,000.
These are local native measurements, not browser/physical-device durability.

`resume-20260916/receiver-timing.json`: corrected fresh-process A/B/A fixtures
all start with seed 4608, terrain hash 683738058 and player (1440,1504).
The mask candidate preserves exact pixels in 20 A/B/A cases, but averages
36.344 / 36.345 / 37.429 FPS on llvmpipe. Its roughly 1.56ms CPU update cost
consumes the GPU saving. **No net gain; production default remains off.**
Earlier wrong-seed and failed process-pause attempts are explicitly invalid.

The latest complete 15-case run passes 14; Overhaul hit an intermittent Godot
dummy-renderer `texture_2d_initialize: Parameter "t" is null` during a mine
texture load. Its unchanged isolated rerun passes 1,251 checks. An earlier
touch run exited 0 without its completion marker; isolated and latest broad
touch runs pass 123 checks. Preserve these failed attempts: this is not yet a
clean, reliable whole-suite acceptance. Do not merely suppress engine errors.

The optional rendered world journey captured 24 real ruin-approach/detour
images, but exited 0 without the final completion marker. The inspected pair
shows physical passage around the ruin; the full rendered journey is **not**
accepted. Its automated-mode HUD contains legacy QA controls, so those images
are route evidence only, not production HUD approval.

Protected-file review still reports the earlier intentional
`scripts/player/player_visual.gd` mismatch. Do not blanket-refresh hashes.
Stable minimum 50 FPS, final native animation, Deep wall joins, exported mobile
gates and overall 9/10 remain open. Previous virtual Mac measurements and all
physical-iPhone limitations in the premium handoff still apply.

## Current environment and next work

- Canonical checkout: `/workspace/scratch/5a78be25fc28/Ever-Deeper`.
- Godot: `/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64`.
- Blender: `/tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender`.
- Restored Xvfb: `/workspace/scratch/4e99473f21fc/runtime/xvfb/usr/bin/Xvfb`.
- Fresh evidence root: `/workspace/scratch/4e99473f21fc/evidence`.
- Use `tools/run_rendered_isolated.py` for an authenticated private display and
  isolated startup saves. One graphical process at a time; no heavy overlap
  during timings. Never count exit 0 alone as successful QA completion.

The wall critic is examining the unused native mapper; it must preserve upright
lighting, continuous edge sampling, and separately calibrated bedrock. The
animation critic is preparing an opt-in constant-material donor bake helper.
Neither is a production replacement. The private prepared native .blend and
all originals remain outside the public repository and in the prior archives.
