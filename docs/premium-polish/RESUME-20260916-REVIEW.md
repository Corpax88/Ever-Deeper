# Continued premium review — 16 September 2026

## DEV published for Mats's current device test

Mats explicitly requested publishing the integrated work now for DEV testing.
This supersedes the save-only/no-publication and pending-CI status below.
The exact **c8906f1** candidate is now playable at
<https://corpax88.github.io/Ever-Deeper/dev/?build=c8906f1>.
Publication run **35093477972**, commit
`4b9663a6ea9b8bc291c35dba02028edc2796afa1`, passed package, deploy and verify.
The final receipt verifies all **nine exact DEV files and nine unchanged LIVE
files** on the public site, with no errors, on the first verification attempt.
The package retains its old displayed DEV8 label; source/PCK hashes identify it.
Save schema 3 deliberately starts new progress, as previously authorized.

Exact-package QA **35088488455** passed all 12 jobs: 15 DEV core cases, both
flavors, nine browser suites (19 shop states, gameplay and six touch sections),
and 58 native preview residency checks. The ordinary gameplay run has **1263**
checks. Independent current static-image review found no DEV blocker.
Current exact-PCK hero review additionally passes **27 checks** for Worn,
Crusher and Deepcore, with **982 actual 1696×780 post-draw frames** and 54 PNG
keyframes. All 90 actually moving mine-to-walk frames use walking. The Deepcore
fixture's old damage-only expectation was narrowly corrected: the same initially
solid cell [11,3] is excavated and therefore has no retained damage. Failed/invalid
captures and the exact harness difference are preserved; no runtime/PCK changed.
The old protected player_visual baseline remains unchanged. This bounded DEV
observation is not a complete baseline A/B or final animation acceptance.

Sustained run **35088488292** completes three 300-second functional sessions with
movement in every 30-second window. Virtual-Mac FPS ranges: Hub 44.98–56.60,
Ember 20.79–39.54, Deep 18.01–30.91. All still fail sustained minimum 50. No physical
iPhone, new browser-audio, full active-hazard/re-entry, or final 9/10 claim exists.
Unaccepted wall/corner/native-model studies remain separate and are not in DEV.

Receipts and bounded reviews are in `dev-published-20260916/`. The separate
publication adapter lives on main in `.github/premium-dev/`; it checks immutable
candidate 10442929350 and complete 10443378936, pins the former DEV8 baseline,
retains rollback artifact 10444774565, and cannot replace LIVE with a new build.
Do not rerun its now-obsolete baseline stage to publish another version; prepare
and review a new immutable candidate against the current publication receipt.


## Explicit upload checkpoint

Mats requested saving the current work after repeated chat streaming failures.
Further local studies were paused. The integration was verified remotely as
`c8906f1d46309227344f101a6b0ae7c1a9b1e69b`, tree
`0802080c2a35a6a5b45185192cfe634fdc86fb7a`. Subsequent documentation-only commits
add these preservation receipts; no new game version was deployed.

At the saved status check, exact web review **35088488455** and sustained gameplay
**35088488292** are running on that immutable integration. Read their actual
conclusions on continuation. No outcome is asserted in advance.

The unverified corner-crop study is separately saved on
`codex/corner-quad-crop-study-20260916`, source
`c113f86169460d3092a63a3e63d79f381028c39b`, tree
`780adf5cec8c53c983c284405fbda909db43f4ed`. Its one runtime change and exact
preflight harness were recovered, but no rendered or timing result exists yet.
Do not adopt it without the listed parity and cost gates.

The wall study's latest README is saved on its existing branch as
`90ac772232b8506f7146a495e8ae613cd178f663`, tree
`f0301bf69cd4586d715fcb9ef789d14fad899865`; the V3 mapper remains unaccepted.

The separate protected player_visual mismatch now has a history/evidence audit
and exact patch in `resume-20260916/pending-animation-audit.json` and
`pending-player-visual.patch`. Historical lost-candidate movies do not verify its
current stride/sample/recovery changes. Preserve the old baseline until a faithful
current rendered gate clears those differences. A full browser active-hazard and
re-entry cycle is also not established by the synchronous gameplay assertions.

## Latest integration after the app interruption

The old canonical scratch directory disappeared. The remote `774f889` source
and surviving reviewed worktrees restored the approved cache, polygon, UI and
sectioned-QA bytes in `/workspace/scratch/4e99473f21fc/Ever-Deeper`. The older
unpublished commit objects are not available. Recovery identities and exact
runtime hashes are in `resume-20260916/recovered-source-20260916.json`.

- **WebGL repair adopted:** official-engine repeated Polygon2D index updates
  reproduce the original buffer-target error. A narrowly scoped CanvasItem draw
  replacement preserves all 15 isolated native RGBA pairs. Browser workflow
  35077842852 reproduces the control failure and passes the same two candidate
  shop fixtures without graphics errors. All native assets remain unchanged.
  See `webgl-polygon-20260916/`. Full hazard-cycle browser coverage remains open.
- **Light and completed-workshop UI adopted:** four direct 1696×780 station
  captures and eight light states pass independent bounded criticism. Completed
  stations show active values; Light Lab previews now read at a fixed scale.
  Original source hashes and the failed cropped capture attempt are retained in
  `ui-completion-light-20260916/`. Combined browser and refreshed residency tests
  are pending; the residency expectation is explicitly updated to 1100×900.
- **Depth strip caching adopted:** all 27 candidate warm/fresh images and the
  27 fresh A/B/A2 images are exact. This also fixes an older missed drill-gated
  invalidation. Sustained moving A/B/A2 records 40.698/41.504/40.533 FPS, with
  actual excavation in every 10-second window; combined setup/draw cost falls
  only 3.6–4.2%. Do not turn the frozen 65% cost reduction into an FPS claim.
  See `depth-strip-cache-20260916/` for all raw summaries and failed controls.
- **Touch sections preserve coverage:** default and explicit all both pass 123;
  pause 5, wardrobe 26, light 25, lists 10, starforge 31, workshops 26 reconcile exactly.
  Four invalid selector forms reject with exit 4 before any section starts.
  Browser acknowledgements and DEV-only assertions can increase these totals.
  See `menu-touch-sections-20260916/`. The immutable browser gate now runs six
  independent sections and requires every section to complete; splitting cannot
  turn cancellation or partial coverage into a pass.
- The earlier browser package 774 completed 1267 gameplay checks, but its visual
  job failed the GL gate and the monolithic touch job was cancelled at 15 minutes.
  Those failures remain evidence. The combined new integration is not yet green.

Two additional raw-evidence archives are durably saved: `web-wall-uv-cache`
(libfile_ac39156d2edc8191976e822707ffdbdb) and `browser-depth-native`
(libfile_63092e5a531c8191b8bf134996f49a9f). Exact file hashes and scope are in
`resume-20260916/` receipts. New UI and controlled-browser raw captures are now saved in the additional
`Ever-Deeper-checkpoint-20260916-ui-browser-touch.tar.gz` archive, identity
`libfile_025bc58c9a8481919f6146a047a460d1`; its exact receipt is
`resume-20260916/ui-browser-touch-archive.json`. Native UV component diagnosis is in `native-uv-20260916/`;
no UV repair or full bake is approved. The latest unpublished transfer guard was
not recovered; do not treat earlier guarded audit results as current runnable code.

Stable minimum 50 FPS, final animation, Deep joins, physical-iPhone evidence and
independently demonstrated whole-game 9/10 remain open. Nothing is deployed.
The protected player_visual mismatch remains separate from the reviewed scene
change. The historical checkpoints below retain their original scoped findings.

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

## Exact package and subsequent Mac checkpoint

Source `82c0f9b7be30c9049c6d6dea34056dfd2656aa5d`, tree
`afddf873828e1f8e318257a45c41e10ea019d1aa`, exports both Web DEV and Web Production
with matching official 4.7.2 templates and no import/export errors. The exact DEV
package passes all **15/15** current core cases. Both packages pass their own
build-flavor gate. `resume-20260916/export-82c0f9b.json` binds all nine files per
build to SHA-256 and retains every gate result. Browser rendering is a separate
pending check at this checkpoint; neither build was published.

The subsequent virtual Mac workflow **35070886032**, on the same `82c0f9b` source,
also completed all three five-minute functional sessions. Hub windows measured
41.35–52.98 FPS, The Deep 16.61–24.48 and Ember 27.32–33.72. Every area still
fails the minimum-50 gate. All new profile GPU timings are marked unsupported,
without interpreting zero as a fast GPU result. The Deep stopped accumulating
travel during its final roughly 90 seconds, so those windows do not represent
continuous moving excavation. This run is not a controlled cross-host A/B of
the station change. Reports are in `resume-20260916/mac-station-completed.json`;
the earlier Mac reports remain unchanged.

The additional private evidence archive is saved as
`Ever-Deeper-review-20260916-station-native-walls.tar.gz`, Library identity
`libfile_dbce3d22f1c8819199e272c714e19776`, 437,649,538 bytes, SHA-256
`a2ae6c44489fcd2c355b36dd9cbd92a56636a63506a3ba42178bd66fd3f13ea6`.
Its 356 members preserve receiver-cache rejection, the completed world route,
station A/B/A, the source gate, V2 wall evidence and bounded native donor probes.
It excludes subsequent V3 wall captures and the new web exports. The receipt is
`resume-20260916/station-native-walls-archive.json`.

## Current environment and next work

- Canonical checkout: `/workspace/scratch/4e99473f21fc/Ever-Deeper`.
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
normal error is 0.0000425875, with source/target/rig restoration verified.

The corrected four-donor albedo pair preserves raw RGB exactly, but fails the
unchanged 1e-6 raw-RGBA criterion because alpha differs. Blender's legacy float
PNG serialization also changes 126 colored padding texels. A live audit proves
all 32 native materials and the pilot target are opaque (Alpha 1, Transmission
0), and the pilot consumes RGB maps with geometric viewport transparency.
The isolated helper now writes explicitly guarded opaque RGB PNGs; it preserves
the failed raw arrays and legacy PNGs separately. Numeric swatches, decoding,
orientation and rejection checks pass, and the corrected albedo files are exact.

Fresh normal and AO sample pairs also produce exact encoded RGB PNGs. Normal's
raw RGBA maximum is 1.19209e-7; AO still fails raw RGBA on alpha alone. Including
helper preparation, normal and AO samples take longer than the four separate
donors. The sparse AO sample has only 243 nonblack pixels, so it does not prove
whole-character fidelity. The full reports and 60 evidence-file hashes are in
`resume-20260916/native-donor-rgb-review.json`; usage and limits are in
`tools/hero_v28/runtime_pilot/CONSTANT-DONOR-PROBE.md`.
No full-scope bake, GLB, production exporter or production character replacement
has been accepted. Native emission, SSS, coat and runtime lighting fidelity
remain material blockers to a 3D switch, in addition to animation and cost.
Private prepared native .blend files and all originals remain outside the
public repository and in the prior archives.
