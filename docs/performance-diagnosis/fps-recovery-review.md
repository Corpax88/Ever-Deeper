# FPS recovery — independent DEV test verdict

Date: 2026-09-09. **The reviewed immutable 1.0.0-dev.3 candidate is ready for
physical-phone testing. Final iPhone performance, overall 1.0 acceptance and
LIVE publication are not approved.** This verdict applies to source
`42fffc163c940db2ab9df2e1924608e2d1659793`, PCK
`6ec691604a060bcad3a21ac2666385e3d1a0c0ac07822c6b74c2a31e33dc5d6d`.

All six exact-package 180-second workloads pass their activity criteria, with
independently reconciled raw data. Sustained software-renderer FPS improves
77.20% in progressed Emberdeep and 49.69% in post-fifth-relic The Deep. The Hub
pair contains an unexplained baseline transient and does not establish a causal
speedup. Final receiver, excavated-corner/gate and reopened-commerce visual
checks pass their stated coverage; the native shop lifecycle measurements show
actual texture and preview-viewport release. No critical regression was found
in the reviewed paths. None of these results measures the phone GPU.

The earlier short-fixture 2.7× D1 estimate remains withdrawn. Its corrected
control supports approximately 2.2× only in that frozen software-renderer
fixture, separately from the sustained package comparison.

## Six-category assessment and limits

These retain the provisional scores from the earlier DEV review, supported by
the current package's regression evidence. They are not a new claim that a
human has completed the campaign or that the device feels smooth.

| Category | Provisional score | Current evidence and remaining limit |
|---|---:|---|
| Gameplay loop | 8/10 | Current state/world and accelerated journey checks retain five physical relic returns, completed shops, Tunnel Home and continued mining. Both post-fifth-relic runs mine onward to depth 52/53. Ordinary full-campaign pacing and enjoyment remain human checks. |
| Progression feel | 8/10 | Paid transactions, upgrade effects, resource goals, carried relics and post-hub goals pass the current regression/journey coverage. Accelerated funding and fixture placement do not establish the time-to-upgrade or subjective feeling of growing stronger. |
| UX | 9/10 | Current mobile/layout/input checks and reviewed small-viewport HUD/tutorial/shop captures pass; the DEV button is visibly separate from Settings. Actual finger comfort, device responsiveness and subjective audio quality remain unverified. |
| Visual quality | 9/10 | Authored artwork and lighting remain intact in the reviewed final 25 receiver triplets, five excavation triplets, journey/Hub images and commerce reopening pairs. This is bounded visual evidence, with no graphics-quality reduction; it does not score phone animation smoothness. |
| Performance | Unverified | Substantial native mining improvement and measured shop-resource release are demonstrated. There is no final-candidate physical iPhone run; the screenshot's 19.9 FPS remains an unresolved device failure. An Ember maximum-frame regression and unexplained Hub baseline transient are retained below. |
| Code quality | 8/10 | Bounded receiver pools, preserved paint/state order, target-selection parity and explicit preview cleanup are covered by review and current regression checks. Existing large world/UI owners and longer-session lifetime behavior limit a stronger maintainability claim. |

The five scored categories average **8.4/10**. This excludes performance and
**is not an overall game score**. Overall 9/10 and stable/smooth iPhone performance
are unverified. DEV test readiness is true; physical iPhone verification, final
1.0 approval and LIVE publication approval are false. This closes the local
performance-fix review without approving the premium 1.0 release.

Current evidence provenance is recorded in `fps-final-ci-evidence.json` and
`fps-final-gameplay-evidence.json`: CI run `34361743735` passed all six jobs,
including the current build, mobile, hero-motion, native-visual and two web-audio
jobs. The root reviewer owns the archive/package verification and reviewed
journey images; `fps-root-final-visual-review.json` and
`fps-hub-wardrobe-review.json` distinguish each reviewer's actual visual coverage.
Those current receipts, not historical WebKit results from another package,
support this DEV verdict. Accelerated journeys, browser device emulation and
audio playback assertions retain their documented limitations.

The latest supplied phone screenshot records 19.9 FPS and P95 56 ms in active
play. The exact build is not visible. `D2` is frame-meter revision 2; 554 seconds
is elapsed meter time, while the displayed FPS summarizes approximately two
seconds. The image does not establish thermal throttling or a memory leak.
See `../one-point-zero/iphone-performance.md` for the complete observation.

## Diagnosis and implementation review

The earlier immutable-baseline Emberdeep attribution measured 5.48 FPS with
normal updates, 5.16 with updates frozen, 18.22 with the root draw's light
contribution excluded, 5.54 after restoring it, 20.50 with all lights off and
5.58 after restoring them. This strongly supports investigating the broad D1
light receiver. It does not justify removing the player's or mole's lighting.

The reviewed D1 change draws the existing artwork through bounded sections and
draws the original two-layer floor only where it can be exposed. Static review
found the following:

- The original block, edge, bedrock masking and concealed-chamber passes remain
  in row/column order. Empty-section predicates match their drawing predicates.
- Floor regions retain empty cells and exposed resource cutouts. Cells excluded
  from the floor are covered by the existing opaque rock or bedrock undercoat.
  Region runs are limited to six cells and preserve the original floor UV origin.
- The original floor color followed by the texture at alpha 0.94 remains intact;
  D1 explicitly disables the composite shader. Existing Hub/D2 callers retain
  their default unrestricted floor behavior and transparent optional underlay.
- Barrier and cave-edge transforms still reset. Target, drop, impact and Crusher
  debris drawing consistently uses the selected section.

The Deep similarly preserves its base pass followed by edge/corner pass. It
selects each row's original stratum and restores the current gameplay stratum
after each draw callback. Removing the covered background has a concrete asset
basis: independent inspection confirms all five floor PNGs are RGB without an
alpha channel, as is `assets/surface/v3/cave-rock-mass.png`. Floor fallback colors
and wall texture draws are opaque. The visible grid covers the former background.
This assumption must remain true if these production assets are changed later.

No confirmed paint-order or gameplay-state defect was found in the inspected
changes. The section/floor pools retain their peak allocation rather than growing
per frame. The completed sustained runs below support bounded use during their
actual movement/streaming routes; they do not establish every longer-session or
viewport-change case.

## Independently inspected paired evidence

Working evidence is under
`/workspace/scratch/6604552ab244/fps-investigation/compare-ember-cull/` and
`/workspace/scratch/6604552ab244/fps-investigation/compare-deep/`.
The critic read both `comparison.json` reports and the attribution harness,
viewed all six `broad.png`, `narrow.png`, `restored.png` files, and independently
recomputed image differences and SHA-256 identities.

Both triplets use native Godot with **llvmpipe**, a **2328×1260** physical window,
one second of settling and eight seconds per measurement. The comparison stages
freeze simulation and switch the bounded draw paths in the same process. They
are short source-level rendering comparisons, not sustained mining, a browser
benchmark or physical-device measurements. The reported engine process monitor
is not exclusive script CPU time. Original/restored paths retain allocated but
hidden section nodes in these same-process comparisons.

### Correction: the initial D1 reference emitted extra work

A subsequent audit, prompted by the root implementer, found that the disabled
`LitFloorChunks` fallback unconditionally draws its wash rectangle even when
the wash is `Color.TRANSPARENT`. The critic verified against source `246ee70`
that original D1 emitted exactly an opaque background rectangle followed by
the floor texture. The new fallback used in the source `broad` and `restored`
stages added a third, world-sized transparent rectangle. The active chunk path
already skipped this rectangle when its alpha was zero.

That additional command may incur lit fragment work while preserving every
output pixel. It invalidates the initial D1 timing reference and the previously
reported **176.47% / approximately 2.7× gain**. The critic's earlier interpretation
of that estimate as a valid improvement is superseded here. Matching restored
pixels and small timing drift did not detect this difference in submitted work.

The current source now includes the `wash.a > 0.0` fallback guard, restoring the
original D1 floor command sequence. Existing Hub/D2 washes have alpha 0.12 and
retain their original draws.
The Deep does not use this fallback, so this specific defect does not invalidate
its reference. The size of the D1 overstatement cannot be inferred by comparing
unmatched baseline and source runs. Corrected paired measurement and the planned
unchanged-PCK baseline versus final-PCK sustained comparison are required before
reporting a D1 improvement. The immutable baseline package is not changed by
this source-reference correction.

The old observations below are retained transparently, **not as accepted D1
performance evidence**:

| Fixture | Source broad FPS | Candidate FPS | Restored FPS | Gain interpretation | Control drift |
|---|---:|---:|---:|---:|---:|
| Emberdeep D1 | 4.543 | 12.196 | 4.280 | Invalid reference; withdrawn | 5.97% |
| The Deep | 5.612 | 7.190 | 5.216 | 32.79%; short source fixture only | 7.32% |

The Deep's observed gain exceeds the drift between its controls; it remains
a short software-renderer result. Its P95 is 211.950 → 169.558 → 234.029 ms and
draw calls fall from 693 to 512. The invalid D1 triplet recorded P95
247.183 → 97.748 → 281.701 ms and 171 → 206 → 171 draw calls; those numbers
do not establish its improvement. Draw-call count alone is not the performance
acceptance criterion.

| Image comparison | Changed pixels | Maximum channel difference | Original/restored |
|---|---:|---:|---|
| Emberdeep D1 | 583 of 2,933,280 (0.01988%) | 4/255 at one pixel; 1/255 at the other 582 | Byte-identical |
| The Deep | 0 | 0 | Byte-identical |

No introduced loss of material detail, changed lighting appearance or seam is
visible in these pairs. The Emberdeep view includes permanent rock, a barrier,
the textured entrance, lamps, hero and mole. The Deep view includes the blue/ember
stratum boundary, floor, wall corners, permanent rock, resource art, hero and mole.
It does not cover all biomes, all equipment/light styles, motion or excavated states.

| PNG identity | SHA-256 |
|---|---|
| Emberdeep original and restored | `903b66c38b787104d095a628b19ac088a495efdae24ba8dccef580875d13d527` |
| Emberdeep candidate | `e8203708f2ac48d697ed6359fdaeeae76c0204f5572a36e6b3eec562995cc37c` |
| All three The Deep PNGs | `2dfe066ecbaf64865aa78601f24d39a3e8bac25c33a61648f7b598c0aa58208e` |

### Corrected D1 control comparison

The replacement source comparison is in
`fps-investigation/compare-ember-correct-reference/`. It uses the corrected
zero-alpha wash guard, the same native llvmpipe renderer, 2328×1260 window, one
second of settling and eight seconds per measured stage. The critic inspected
the harness, all three paired PNGs and the complete JSON, independently
recomputed FPS/P95 from every raw interval and checked image differences/hashes.

| Stage | FPS | P95, ms | Frames | Median draw calls |
|---|---:|---:|---:|---:|
| Corrected broad reference | 5.220861 | 226.478 | 42 | 170 |
| Bounded candidate | 11.850517 | 100.785 | 95 | 206 |
| Restored corrected reference | 5.320723 | 232.157 | 43 | 170 |

The candidate divided by the arithmetic mean of the two control FPS values is
**2.24834×**, or **124.83% higher FPS**. The absolute difference between the two
controls divided by that same mean is **1.89462% drift**. Comparing against the
faster control alone still gives **2.22724×**. This supports approximately **2.2×
in this short, frozen, software-rendered fixture**; the effect is much larger
than the measured control drift. It replaces the invalid D1 gain interpretation,
without reinstating the old 2.7× estimate or certifying phone performance.

Each frozen stage's first interval is less than one millisecond because
measurement starts just after the preceding draw. All reported raw intervals are retained
in the figures above. Treating that first partial interval separately would
slightly increase the observed relative gain; it does not explain away the
improvement. Eight-second samples still do not establish sustained behavior.
The normal-updates candidate stage separately records 11.146854 FPS; it is not
an active-mining workload or a paired normal-updates baseline.

The corrected candidate differs from its broad image at **585 of 2,933,280
pixels (0.01994%)**: 584 pixels differ by at most 1/255, and one by 5/255.
Broad/restored files are byte-identical. Actual inspection found no introduced
loss of floor/rock detail, lamp or hero/mole lighting, barrier appearance or
visible seam. This remains a single Emberdeep view, not complete visual coverage.

| Corrected evidence | SHA-256 |
|---|---|
| `comparison.json` | `c49b023f8a60447bd5d5e195d5b89cebae1aff71774d306d522481abce444cc3` |
| Broad and restored PNGs | `71fe07673c5f3b6c6e19bf5c43a1c2a382ecb29494baaf724d9e38bcf9963e04` |
| Candidate PNG | `8b5225a2f87d5559dca50d3da85c392d99d93ce5950a857e777e0b92d4ef659d` |

This comparison's JSON does not bind itself to an exported PCK hash. It is
accepted as corrected source-level attribution, while the final immutable
package, sustained workload and physical-phone gates remain separate.

## Broader source visual preflight

The subsequent `fps-investigation/visual-source/` run contains 75 PNGs from 25
triplets: four D1 mines with all five light styles, plus five Deep strata with
one style each. Its `pack_sha256` explicitly says `editable-source-preflight`.
The half-second samples in this run are **visual verification only** and must
not be cited as performance measurements.

The critic read the harness and its zero-failure terrain/light-state report,
independently recomputed all 25 image comparisons and all 75 PNG hashes, and
confirmed they match `pixel-comparison.json` (SHA-256
`d970459cc8b6772183dbd29685b4222303cba5ab7e017969030bb92939ef3367`).
All 25 original/restored pairs are byte-identical. Every Deep triplet is entirely
pixel-identical. D1 differences never exceed 2/255 in any channel.

| D1 biome | Largest changed-pixel count among its five styles | Maximum channel difference |
|---|---:|---:|
| Mossvein | 1,249 | 2/255 |
| Moonglass | 890 | 2/255 |
| Emberdeep | 782 | 2/255 |
| Starfall | 1,351 (0.0461% of the frame) | 2/255 |

Actual visual inspection covered 14 representative frames: both original and
candidate for `mossMine-deepheart`, `moonMine-wide`, `emberMine-wide` and
`starMine-deepheart`; all five Deep candidates; and `mossMine-prismatic-narrow`.
These include each biome's largest numerical difference, the five Deep strata,
normal terrain, permanent rock, visible intact barriers, resource cutouts, lamps,
hero/mole poses, stratum joins and one visible damaged stone/impact fixture.
No new visible seam, lost material detail or changed lighting appearance was
found. This is representative visual inspection, not a claim to have visually
viewed all 75 PNGs.

The inspected source preflight passes its bounded visual comparison. Coverage
still has a concrete limitation: `restore_position()` can choose a safe fallback
at the entrance, so a requested distant camera position alone does not prove an
outer corner or other specific geometry was shown. Final package coverage must
assert and capture the intended mined corner, exposed resource, and affected
barrier/impact states. Sustained motion and streaming are separate checks.

## Final immutable-package receiver review

The critic independently reviewed the receiver captures from CI run
`34361743735`, artifact `10108704344`, extracted under
`/workspace/scratch/6604552ab244/fps-final-10108704344/receivers/`.
Its report identifies the final candidate PCK as
`6ec691604a060bcad3a21ac2666385e3d1a0c0ac07822c6b74c2a31e33dc5d6d`.
The root reviewer verified that all six CI jobs passed for source `42fffc1` and
owns verification of the CI archive/package provenance and the separate
journey/touch captures. This section covers the receiver evidence.

All **25 triplets / 75 PNGs** were independently decoded and compared, and every
PNG's SHA-256 was computed. The fixture set exactly covers four D1 mines with
all five light styles and five Deep strata. Every image is 2328×1260. The
capture report records no light-state, terrain-state or unused-section visibility
failure. It explicitly records `physical_iphone: false` and llvmpipe with the
compatibility renderer. Its half-second samples are **visual checks only**.

All 25 broad/restored image pairs are byte-identical. All five Deep triplets are
entirely pixel-identical. D1 changed-pixel counts are below; the maximum channel
difference across every comparison is **2/255**.

| D1 biome | Standard | Wide | Focused | Prismatic | Deepheart |
|---|---:|---:|---:|---:|---:|
| Mossvein | 683 | 374 | 438 | 215 | 700 |
| Moonglass | 943 | 884 | 493 | 0 | 58 |
| Emberdeep | 441 | 782 | 265 | 0 | 114 |
| Starfall | 600 | 252 | 690 | 678 | 1,303 |

The largest count, 1,303 pixels, is **0.04442%** of a frame. Actual visual
inspection covered **15 frames**: both broad and candidate for each biome's
largest numerical difference (`mossMine-deepheart`, `moonMine-standard`,
`emberMine-wide`, `starMine-deepheart`), all five Deep candidates, plus
`mossMine-prismatic-narrow` and `starMine-focused-narrow`. These show floor/rock
detail, intact barriers, lamps, hero/mole lighting, exposed resource surrounds,
all five light styles, Deep stratum boundaries and the prepared damaged-block
and impact fixture. No introduced material loss, lighting change or visible seam
was found. This is representative viewing, not a claim to have viewed all 75.

The earlier resource-cutout coverage concern is improved: the four focused D1
fixtures now explicitly record visible exposed resource cells (Moss 2, Moon 3,
Ember 2, Star 1), and the inspected Star frame shows its clear ore silhouette.
However, every D1 fixture records `visible_mineable_corners: 0`. Those captures
alone therefore do not establish newly excavated D1 corner or broken-barrier
transition coverage. The damaged-block/impact case is prepared by the visual
harness; it is not evidence of successful control-driven mining. Actual mining,
movement/streaming, transitions and progression remain separate runtime gates.

| Audit identity | SHA-256 |
|---|---|
| Final `mining-receivers.json` | `c6e9aaf76829ad142f93ca426ae252ab8bb87d549d08864fb7b34261c58afdaa` |
| Independent 25-triplet / 75-hash audit | `69f5e008d476d797136dae7c3c1c878aea04b47153869eda1d1ce516cfaca62a` |

The independent audit is retained in `fps-critic-final-receivers.json` (with its
original scratch copy at `fps-investigation/critic-final-receivers.json`). **This
exact package passes the bounded receiver visual comparison.** The additional
excavation review below closes the identified corner/broken-gate coverage gap.
The combined DEV verdict is stated above; neither visual comparison certifies
physical iPhone performance or LIVE approval.

### Final actual-excavation visual gap closure

The exact candidate's completed 180-second Ember run supplies real initial/final
saves to `tools/review_d1_excavation.gd`, SHA-256
`e78555c14fc29e5000556cc81d7e19736c45ce8228516d5f802801966b04f87d`.
The critic statically reviewed this external diagnostic. An initial fixture
restoration-order problem was found and corrected before the accepted run:
cancel held input and leave the old mine before deserializing the next save,
so old terrain cannot be reused against the newly restored state fingerprint.
No runtime candidate change was required.

The accepted report is `fps-d1-excavation-review.json`; original report and
15 PNGs are in `fps-investigation/final-d1-excavation/`. The original report SHA-256
is `d7c75e7b9f9fe3459e30892c9bed6ba105df86691b8d6e67e541fc22e5f671c1`.
Its final-save SHA-256 is
`b8084c8313319ac5829e57776e8b1d8e8d3a5ab39ab03ec12661a1b04db96339`.
It verifies an actual mineable corner at cell (31, 7), with two visible corners
and three exposed resource cells. Both barriers removed during real sustained
mining are captured as open passages. The initial save supplies the intact
bulkhead, and one real `_mine_once()` call advances its recorded damage 0 → 1.
That single strike uses direct target selection and accelerated fixture timing;
it verifies the damage draw path, not normal-input target reachability. The
earlier sustained run separately demonstrates both gates being mined normally.

All five 2328×1260 triplets were independently decoded, diffed and hashed.
Every broad/restored pair is byte-identical, and the maximum candidate channel
difference is 2/255 throughout.

| Excavation state | Changed pixels, broad versus candidate |
|---|---:|
| Actual mined corner | 499 |
| Actual broken bulkhead | 2,139 |
| Actual broken Crucible lock | 1,585 |
| Intact bulkhead | 297 |
| Bulkhead after one actual strike | 304 |

The largest count is 0.07292% of the frame. The critic actually viewed eight
images: all five candidate states and the broad references for the mined corner,
broken bulkhead and struck bulkhead. The intended opened passages, excavated
joins, resource silhouettes, retained materials and lighting are coherent, with
no introduced seam or loss of detail visible. This closes the concrete D1
visual gap from the 25-triplet matrix. These half-second stages are explicitly
**visual checks only**, with no frame-time or physical-phone acceptance claim.

## Sustained-workload harness audit

The critic independently inspected `tools/review_sustained_mining.gd` at SHA-256
`abb9729c01592dc13ddb67937b46d9d3af1df0bfc7135cf2997c65b04709ab2a`, its actual
Main/player control path, and the corrected baseline's Emberdeep summary/raw
windows in `fps-investigation/sustained-baseline-corrected/`. This audit applies
to that harness revision; a revised traversal requires its own identity and
matching baseline/candidate runs.

The harness drives the ordinary Main joystick and held-mine entry points, with
normal physics/process timing. Fractional joystick input remains proportional
through the player's actual collision resolver. Route preparation excludes
bedrock, tools above the fixture's pickaxe, and whole locked-gate rectangles with
player-radius clearance. Setup repositioning occurs before measurement. No
measured-phase teleport, terrain replacement or forced process stepping was found.
The Deep uses absolute depth coordinates for distance, preserving the position
across its ordinary floating-origin rebase.

The corrected baseline ran **180.029155 seconds** and its **883 raw frame
intervals sum to exactly the same elapsed time**. It moved 22,896 pixels, recorded
255 mined and picked resources, and observed 254 removed cells. However, window
index **14**, from **142.208536 to 152.377002 seconds**, moved 2,346.33 pixels while
recording zero mined resources, zero removed cells and zero pickups. The other
17 reported windows include mining; one of those is the final partial window.
This is a walking/backtracking gap in the selected route, not evidence that the
player stalled. It correctly leaves `valid_workload` and `sustained_180s` false.
The run is retained as a failed workload attempt; it does not pass sustained
mining acceptance. The `all` run stops on that failure and therefore supplies no
completed Hub or Deep measurement.

The inspected measurement accounting has the following acceptance limits:

- Every complete ten-second window must show movement and actual mined/removed
  outcomes for a 180-second mining pass; Hub requires movement. A final partial
  window remains in the raw results but is not covered by this full-window gate.
  A positive window proves some mining, not uninterrupted mining throughout it;
  inspect activity counts and outcomes alongside frame times.
- D1 removed/respawned counts observe net changes in block count at state
  notifications. They are evidence of terrain changes, not an exact count of
  pickaxe impacts or a one-to-one resource payout. Deep counts persisted dug/node
  bits. Outcomes must be interpreted with the initial/final state and pickups.
- Per-window snapshot and JSON-writing time is included in the next frame
  interval. The harness does not silently discard those spikes. Setup and final
  screenshots are outside the steady measurement and need separate loading/UX
  coverage. The final elapsed interval can exceed the requested duration by the
  final frame; its exact duration is reported.
- Retained raw frame arrays and snapshots grow the harness's own static memory
  with sample count. `MEMORY_STATIC` slope alone cannot diagnose a game leak;
  node/GPU trends and repeated lifecycle evidence must be evaluated separately.
- Aggregate FPS must use all frames divided by their summed elapsed time, and
  aggregate percentiles must use the combined raw intervals. Averaging per-window
  FPS or percentiles gives a different, potentially misleading result.
- Successful exit certifies the workload predicate, not the smooth-FPS target.
  Duration below 180 seconds is explicitly a smoke test. Preserve first/last and
  all intervening windows, including any failed attempts.
- Runtime/package/harness hashes help provenance, but matching the mounted PCK
  inside the script is conditional on Godot exposing `--main-pack` in its
  arguments. Preserve the external exact launch command and package receipt.
  A failed fixture returns before the final aggregate hash manifest is written.
- Use the same harness revision, seed, loadout, resolution and fixture order for
  both packages. `all` is a warm Ember → Hub → Deep sequence in one process,
  rather than three cold launches. The rendering wrapper's default 480-second
  timeout is too short for three 180-second fixtures; set it explicitly longer.

A faster build can traverse and excavate more terrain in the same wall-clock
duration; the two live runs therefore do not render identical state every frame.
They test sustained ordinary control-driven work. Corrected fixed-state visual
and rendering comparisons provide the complementary isolation of drawing cost.
Neither kind of native/software-renderer result certifies physical iPhone FPS.

### Revised external D1 traversal

Static review also covered the external
`fps-investigation/review_sustained_mining_active.gd` at SHA-256
`963ee80aeababa343365b029c7646cf47ae1437b4e642db5f7ce8043d83b5e6a`.
It replaces D1's empty-corridor DFS backtracking with deterministic breadth-first
paths to the nearest currently existing mineable block, replanning only after
the player physically arrives. The legal graph retains tool/gate exclusions;
ordinary respawns remain eligible. No terrain/save mutation or bypass of actual
controls/collision was found, and the strict full-window predicate is unchanged.
This is suitable for functional and sustained workload validation, subject to
using identical external bytes for both unchanged packages. It is not yet a
sustained pass. Planner time is measured and remains part of the frame workload.

`route_hash` and `route_points` now describe only the final planned segment;
they must not be presented as the identity of the full traversal. Use the
recorded target sequence as additional coverage evidence. Nearest-block mining
tests active excavation; it does not establish objective progression or broad
camera coverage, which require their separate existing gates.

## Exact-package sustained Ember result

The critic independently audited the completed reports and all 36 individual
window files under `fps-investigation/sustained-progressed-baseline-ember/` and
`fps-investigation/sustained-progressed-candidate-ember/`. Both manifests identify
the same unchanged external driver, SHA-256
`fc43bb4f3c32fda561c37bb4766f4dc5332dbc666a51470b89e7d43551097588`.
Inspection of its difference from the previously reviewed BFS driver confirms
that the only setup change is pickaxe level 5, plus an explicit fixture-stage
label. Gates and terrain start intact and are removed through ordinary mining.

This is **progressed Emberdeep D1**, not the earlier pickaxe-4 comparison fixture;
the screenshot's exact equipped level is unverified. The earlier pickaxe-4 BFS
attempt exhausted naturally reachable rock at
about 101 seconds and correctly failed; that attempt is not promoted to a pass.
The progressed fixture gives the actual equipped tool access to the lower mine.
Both initial gameplay snapshots match exactly apart from memory monitors: seed
4608, pickaxe 5, drill 0, no Starforge variant, the same ten companion skills and
original tool/outfit with standard light. Both use native Godot 4.7.2, llvmpipe,
2328×1260 pixels and unchanged graphics; `physical_iphone` remains false.

The critic independently recomputed all metrics below from the combined raw
intervals, checked each window's metrics and raw-array lengths, confirmed
contiguous window boundaries and exact equality of individual/aggregate window
records, and verified outcome sums against initial/final snapshots. The derived
summary agrees with the raw evidence; no engine/script error was found in either
log. Both runs pass the unchanged strict 180-second workload predicate: 17 full
windows plus a final partial window, **all 18 containing mining and movement**.

| Metric | DEV 1.0.0-dev.2 | Candidate 1.0.0-dev.3 |
|---|---:|---:|
| Actual duration, seconds | 180.023311 | 180.007378 |
| Sampled frames | 1,762 | 3,122 |
| Weighted FPS | 9.787621 | 17.343734 |
| P95 frame time, ms | 136.368 | 76.201 |
| P99 frame time, ms | 157.803 | 93.013 |
| Maximum frame time, ms | 188.786 | 233.086 |
| Frames over 33.34 ms | 1,761 | 3,121 |
| Mined resources | 673 | 696 |
| Removed cells | 674 | 697 |
| Travel, pixels | 33,264 | 34,608 |
| First / last window FPS | 8.072 / 11.262 | 16.343 / 17.318 |

Weighted FPS improves **77.2007%** and P95 falls **44.1211%**. The candidate's
worst frame is **44.300 ms worse** and remains in the data (window 16); this
comparison does not establish elimination of hitches. It is one serial run per
package, not a repeated statistical confidence estimate. The software renderer
remains slow in absolute terms; those native timings cannot be extrapolated
quantitatively to Safari or the phone GPU.

Both runs actually clear `ember_bulkhead` and `ember_crucible_lock`, retain
667 / 690 dug cells in their respective final saves, and plan targets over the
same grid bounds, x 2–37 and y 4–129. The candidate travels 4.04% farther and mines
3.42% more resources, so state at equal wall-clock times is not identical.
This validates sustained active excavation rather than isolated draw cost.
The baseline picks up 672 resources and retains one loose stone in its final
save; the candidate picks up all 696. These counts do not indicate a lost reward.

| Footprint / observer cost | DEV 1.0.0-dev.2 | Candidate 1.0.0-dev.3 |
|---|---:|---:|
| Initial → final GPU monitor, MiB | 497.845 → 500.489 | 481.569 → 484.314 |
| Initial → final node count | 760 → 789 | 974 → 1,103 |
| Peak sampled node count | 799 | 1,111 |
| Initial → final static memory, MiB | 82.982 → 85.643 | 84.341 → 87.993 |
| Planner calls | 659 | 688 |
| Total planner time, ms | 13.909 | 18.953 |
| Maximum planner call, ms | 0.570 | 0.255 |
| Initial → final save bytes | 14,889 → 21,629 | 14,889 → 21,729 |

The candidate uses about 16.2 MiB less GPU memory in this fixture. Its added
receiver nodes remain higher in number but settle at approximately 1,101–1,103
late in the run, rather than growing per frame. This supports bounded node use
within the observed route; it does not prove every longer-session lifetime.
Static memory grows by 2.66 / 3.65 MiB and includes the observer's retained raw
samples, snapshots and target history. The candidate records more frames and
planner entries. That static slope alone is not evidence of a game leak.
Planner work totals less than 0.011% of elapsed time in both runs and remains
included in frame timings. Save growth includes real persistent excavation.

| Identity | SHA-256 |
|---|---|
| Baseline PCK | `c331cde35f64edf26a9d10c921e46ad1ef9bd3001aea225b521a38c86ea0ca36` |
| Candidate PCK | `6ec691604a060bcad3a21ac2666385e3d1a0c0ac07822c6b74c2a31e33dc5d6d` |
| Baseline `sustained-mining.json` | `d25a42ca0f0c197276c44f9bf5b552a1f6340ed7722293208676eb15768c5315` |
| Candidate `sustained-mining.json` | `5dee562c9a90bcb45b20a9b13e15fbcc59af455b74558927eca4acfa0eb5fe07` |

**Performance assessment: substantial, sustained improvement is demonstrated
for this progressed Ember fixture.** The remaining exact-package scenarios are
completed and audited below. Final phone smoothness, hitch acceptance and a
final performance/overall 9/10 score remain unproven.

## Completed six-run sustained audit

The final bundle is `fps-investigation/sustained-final-evidence/`, with root
report SHA-256
`e94e339520e0f1791ca713ddbbd242b485d75739c3dfaeb4e90b687681ee8997`.
The repository retains `fps-sustained-results.json`, `fps-sustained-receipt.json`
and `fps-sustained-evidence.zip`; failed earlier workloads remain separate in
`fps-sustained-failed-fixtures.zip`. Each final fixture was launched in its own
process, serially, against the two unchanged PCKs. These are not a single warm
Ember → Hub → Deep session. The same final external driver, seed, loadout,
resolution and fixture setup were used for each matching pair.

The critic reconciled **all six raw report hashes and all 108 raw windows**:
frame counts/arrays, elapsed sums, contiguous boundaries, weighted FPS, combined
percentiles, maxima, frames over 33.34 ms, activity outcomes and initial/final
snapshots. There were **zero discrepancies**. All six runs meet the unchanged
180-second activity predicate, with 17 full windows plus the final partial
window each; all mining windows actually mine and move. Hub windows correctly
require movement rather than mining. All keep their complete raw intervals.

| Fixture and package | Frames | Seconds | Weighted FPS | P95, ms | P99, ms | Maximum, ms |
|---|---:|---:|---:|---:|---:|---:|
| Ember DEV2 | 1,762 | 180.023311 | 9.787621 | 136.368 | 157.803 | 188.786 |
| Ember DEV3 | 3,122 | 180.007378 | 17.343734 | 76.201 | 93.013 | 233.086 |
| Completed Hub DEV2 | 2,640 | 180.007391 | 14.666064 | 78.709 | 404.491 | 3,115.465 |
| Completed Hub DEV3 | 3,203 | 180.026193 | 17.791855 | 68.087 | 83.596 | 148.383 |
| Post-fifth-relic Deep DEV2 | 1,387 | 180.019400 | 7.704725 | 154.611 | 180.277 | 259.477 |
| Post-fifth-relic Deep DEV3 | 2,077 | 180.089509 | 11.533154 | 105.704 | 120.341 | 166.350 |

The Deep's weighted FPS improves **49.6894%** and P95 falls **31.6323%**.
Actual mined resources are 16,804 → 17,456; removed dug/node bits 1,944 → 1,972;
travel 55,000.922 → 56,210.344 pixels. Both start at depth 13 and end at depth
52 / 53, retaining all five placed relics and five built shops. This establishes
continued ordinary mining/streaming beyond the fifth relic in these routes.
It does not prove organic campaign pacing or mathematically limitless storage.
First/last window FPS is 6.850 / 7.726 for DEV2 and 11.251 / 11.671 for DEV3.

**No causal Hub speedup is claimed.** DEV2 has an unexplained transient from
approximately 40.140 to 73.342 seconds, with three windows at 7.947, 2.568 and
1.249 FPS and the retained 3,115.465 ms maximum. Its other windows range from
15.13 to 18.58 FPS, overlapping the candidate's 16.527–19.094 range. The report
does not assign that transient to the game or the host without evidence, and
the full-run average does not isolate a Hub improvement. Actual Hub travel is
50,315.333 → 57,659.333 pixels, with zero mining as expected. First/last window
FPS is 15.852 / 18.205 versus 18.493 / 17.415.

| Additional footprint | DEV2 initial → final | DEV3 initial → final |
|---|---:|---:|
| Hub GPU monitor, MiB | 523.944 → 524.071 | 507.668 → 507.795 |
| Hub node count | 767 → 761 | 770 → 764 |
| Hub static memory, MiB | 76.170 → 77.288 | 76.229 → 77.438 |
| Deep GPU monitor, MiB | 525.324 → 527.949 | 509.048 → 511.681 |
| Deep node count | 1,071 → 1,096 | 1,250 → 1,293 |
| Deep static memory, MiB | 78.498 → 81.127 | 79.626 → 82.493 |

Late Hub nodes stabilize. Candidate Deep nodes vary around 1,285–1,293 during
streaming, while GPU allocation oscillates with the strata; neither grows per
frame in the observed route. Receiver nodes are intentionally more numerous in
the candidate. The approximately 16.3 MiB smaller GPU allocation is consistent
across these fixtures, but the static memory monitor includes the diagnostic's
retained samples and snapshots. Three-minute routes do not certify every
long-session lifetime or resolve the screenshot's 554-second device observation.

Every run uses Godot 4.7.2, native llvmpipe, 2328×1260 and unchanged graphics.
All but the first partial frame of each run exceed 33.34 ms: absolute native
FPS is not smooth. These results demonstrate relative work reduction under a
software renderer. One run per package/scenario does not supply statistical
confidence, and different progress at equal elapsed times prevents exact-state
attribution. The corrected frozen comparison supplies separate bounded evidence
of the D1 draw-cost change. Physical phone FPS, thermal behavior and WebKit GPU
cost remain unmeasured for this candidate.

## Commerce lifetime and visual acceptance

The resource owner's final headless lifecycle report was inspected at
`/workspace/scratch/6604552ab244/fps-resources/final/commerce-residency.json`.
Its 122 passing assertions cover repeated Light Lab/Wardrobe opening and closing,
worn → Crusher → Deepcore → worn equipment, identical reopened selection/catalog,
unchanged loadout/resources and final loading-queue drainage. Closed Light Lab
releases all six preview viewports; the unchanged full-resolution Wardrobe PNG
is no longer retained after closing. That initial headless report alone did not
measure GPU savings; the final native comparison below now supplies that evidence.

The resource owner completed exact DEV2/DEV3 native comparisons in
`fps-resources/commerce-queue/rendered/{baseline,candidate}/`, using unchanged
external harness SHA-256
`756055c344db1c09eb320cce023075d5f1393a0978ebb46156f1c0eb4c413c49`.
The critic read both reports and the full image-comparison result. DEV2 passes
44 expected-behavior assertions with release not required; DEV3 passes 58 with
release required. Both have zero engine errors/failures and use fresh saves.
The baseline's expected retention is not misrepresented as a cleanup pass.

| Actual close operation | DEV2 | DEV3 |
|---|---|---|
| Wardrobe | Keeps portrait cached and all 107 shop nodes | Releases 16.3000 MiB GPU, portrait uncached, 107 → 58 nodes |
| Light Lab | Keeps six preview viewports and all 188 shop nodes | Releases 20.3365 MiB GPU, six → zero viewports, 188 → 58 nodes |

Candidate reopening restores the same catalog/selection and the same open
allocation; closing again returns to the same closed allocation. Render buffers
retain some capacity after use, so the evidence does not claim every byte
returns to its cold-start value. The actual detached preview nodes and textures
are released. These are twelve-frame-settled resource-lifetime observations,
not a sustained FPS comparison or a physical GPU memory measurement.

Each package has six actual captures. Within each package, Wardrobe open/reopen,
Light Lab open/reopen and their 1100×1200 beam captures are pixel-identical.
The direct beam is also pixel-identical between packages. Full 2532×1170 windows
differ only at 635 exposed Hub pixels in bounds (1214,18)–(1361,54), maximum
channel difference 6/255, outside the commerce content. The resource owner
reviewed the full set. The critic separately viewed DEV2 opened and DEV3 reopened
Wardrobe, DEV2 opened and DEV3 reopened Light Lab, and DEV3's reopened direct beam
(five images). Portrait detail, tint, thumbnails, selected entries, text and
beam presentation remain intact. No introduced reopening defect was found.
The repository record is `fps-commerce-residency.json`.

## Remaining physical acceptance

Final physical acceptance requires the actual candidate on the phone, including
longer ordinary play after startup. The existing smooth-60 target is mean at least
58 FPS, P95 at most 20 ms and no frames over 33.34 ms in measured steady windows;
loading/transition behavior must be reported separately. Exercise the candidate
on the affected phone in the Hub, normal D1 mining including the reported
Emberdeep progression, and post-fifth-relic The Deep, with hero/mole/light active.
Record the exact DEV version and sustained windows after several minutes of
ordinary play; verify Settings/DEV touch separation, shop close/reopen and
relic/Tunnel Home transitions while retaining graphics quality. These are tests
of the agreed game and the reported failure, not additional features.

**Final local verdict: the reviewed exact DEV3 package is ready for this phone
test.** The immutable-package gameplay, sustained-workload and affected visual
reviews are completed, with the limitations above. The provisional five-category
mean remains 8.4/10; performance and overall are unverified. A final 9/10 premium
1.0, stable/smooth physical iPhone performance and LIVE publication remain
unapproved. The user's low-FPS report must not be marked fixed on the phone
until the actual candidate satisfies that remaining evidence gate.

The critic changed documentation only and launched no native rendering workload
during this review.
