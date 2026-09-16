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
- Depth workshop clock ticks now redraw their existing landmark section instead
  of reconfiguring the unchanged terrain and exposed floor. The normal full
  redraw remains responsible for terrain, camera, target and gameplay changes;
  a missing section or disabled partitioning falls back to that path. Six
  visible animation states match a fresh full redraw in every RGBA pixel.
  The boots visibly move between states (4,202 changed pixels), so this is not
  a comparison of an offscreen or frozen animation.

## Measurements and limits

`resume-20260916/save-cost.json`: isolated version-3 binary saves measure
0.815–1.017ms at 3 bands, 1.529–1.841ms at 100, and 7.807–8.718ms at 1,000.
These are local native measurements, not browser/physical-device durability.

`resume-20260916/station-redraw.json`: fresh 20-second entry sessions with the
same seed, terrain and position measure **39.157 / 40.592 / 39.305 FPS** for
control/candidate/control. Frame p95 is 30.430 / 29.637 / 30.097ms. In the candidate,
station animation invokes one draw callback instead of five, with no terrain
setup work. This is a small local llvmpipe improvement, not a sustained 50 FPS
claim. The first control's parity camera missed the boots; both later runs
explicitly frame the visible animation after their unchanged timing workload.

`resume-20260916/receiver-timing.json`: corrected fresh-process A/B/A fixtures
all start with seed 4608, terrain hash 683738058 and player (1440,1504).
The original mask candidate preserves exact pixels in 20 A/B/A cases, but averages
36.344 / 36.345 / 37.429 FPS on llvmpipe. Its roughly 1.56ms CPU update cost
consumes the GPU saving. A conservative 24px support cache also preserves all
20 exact A/B/A pairs and reduces update cost to 0.857ms, but averages
37.592 / 36.703 / 38.163 FPS. **Both candidates are rejected.** The experiment
now lives entirely in the excluded `tools/light_receiver_pilot/` snapshot;
production no longer creates its controller or maintains receiver metadata.
The archived tool still passes its initial exact A/B/A smoke check. After
removal, premium core (200), Overhaul (1,253), and world (461) checks pass.
See `resume-20260916/receiver-cache-rejected.json` for the complete measurements.
Earlier wrong-seed and failed process-pause attempts are explicitly invalid.

The earlier complete 15-case run passed 14; Overhaul hit an intermittent Godot
dummy-renderer `texture_2d_initialize: Parameter "t" is null` during a mine
texture load. Its unchanged isolated rerun passes 1,251 checks. An earlier
touch run exited 0 without its completion marker; isolated and latest broad
touch runs pass 123 checks. Preserve these failed attempts. After the station
change, a fresh serialized source gate passes **15/15**, including Overhaul
(1,257), touch (123), world (461) and migration (341), with explicit completion
markers and no runtime errors. See `source-gate-station-final.json`. That clean
run does not establish the cause or resolution of the earlier intermittent
engine failures. Do not merely suppress them.

The first optional rendered world journey captured 24 ruin-approach/detour
images but exited 0 without the final completion marker. Preserve that failure.
A later run completed **461 checks with the explicit success marker**, retaining
24 actual 1696×780 route images in `world-routes-rendered-marker`. Opt-in capture
now uses the gameplay HUD. Fast fixture events still produce transient tutorial
and achievement effects: these images prove the route, not final HUD approval.
The successful run used verbose logging and the safe render thread; this does
not establish the cause of the earlier exit. `run_rendered_isolated.py` accepts
`--completion-marker` and rejects missing completion even when the engine exits 0.

Virtual Mac workflow **35066932420**, source `3a0ef1c`, completed all three
five-minute functional sessions at actual 1696×780. Thirty-second window FPS:

| Area | Minimum–maximum | Every window ≥50 FPS |
| --- | --- | --- |
| Hub | 47.71–58.79 | No |
| The Deep | 16.66–31.99 | No |
| Ember | 17.67–32.75 | No |

This is Apple Paravirtual/ANGLE, not physical iPhone evidence. Raw reports are
in `resume-20260916/mac-current.json`; the earlier completed run is preserved
separately. The Deep profiler returned invalid GPU timestamps near 1.84e13ms.
Those values cannot support a GPU bottleneck claim. Both profiling tools now
reject negative, non-finite or ≥1000ms GPU samples and mark the GPU timing
unsupported, while preserving frame timing and the invalid-sample count.

Protected-file review still reports the earlier intentional
`scripts/player/player_visual.gd` mismatch. Do not blanket-refresh hashes.
Stable minimum 50 FPS, final native animation, Deep wall joins, exported mobile
gates and overall 9/10 remain open. Previous virtual Mac measurements and all
physical-iPhone limitations in the premium handoff still apply. The new virtual
Mac result above supersedes the previously pending Mac session.

## Current environment and next work

- Canonical checkout: `/workspace/scratch/5a78be25fc28/Ever-Deeper`.
- Godot: `/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64`.
- Blender: `/tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender`.
- Restored Xvfb: `/workspace/scratch/4e99473f21fc/runtime/xvfb/usr/bin/Xvfb`.
- Fresh evidence root: `/workspace/scratch/4e99473f21fc/evidence`.
- Use `tools/run_rendered_isolated.py` for an authenticated private display and
  isolated startup saves. One graphical process at a time; no heavy overlap
  during timings. Never count exit 0 alone as successful QA completion.

The wall study remains isolated in
`/workspace/scratch/4e99473f21fc/deep-wall-study`. Its first rendered A/B improves
upright stone orientation but has visibly rectangular cropped joins; it is not
accepted. It must preserve native opaque contours and separately calibrated
bedrock before any promotion.

The opt-in native constant-material donor helper is also unaccepted. Its first
four-donor separate bake completed in 33.658s; merged geometry stopped before
baking because the maximum corner-normal error (0.002452) exceeded 0.0003.
Forcing smooth faces did not help: the sampled corners were already smooth.
Unchanged polygon copies preserved normals within 1.79e-7; triangulation caused
the larger error. The corrected helper preserves evaluated polygons, loops and
edges, checking exact tessellation and the unchanged normal tolerance. Geometry
validation passes for the sample and all 369 constant donors; full-group maximum
normal error is 0.0000425875, with source/target/rig restoration verified. Fresh
paired albedo, normal and AO bakes are still required. Neither the exporter nor
the production character has been replaced.
Private prepared native .blend files and all originals remain outside the
public repository and in the prior archives.
