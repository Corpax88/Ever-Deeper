# World-owned occupancy revision study — CPU saving retained, full FPS gain unproven

**Final result:** six exported core cases and both graphical workers passed. 108 image pairs are pixel-exact. Helper CPU cost drops about 98%, but total FPS improves in only one repeat. Retain the isolated candidate; no publication or phone retest.

Canonical source: `625021df3724cd1e17f1d5193ee0edd94834bb60`, branch `codex/native-light-dev15-9-20260924`.
QA source: `c9c26ef1f821ab36dc5cf17d94da69ff3d3f7914`, branch `codex/revision-study-20260925`.
Workflow run: `36105429639`. Original immutable DEV15.9 export: run `36043919958`, source `c63aabd3e3e5120579285ce6e8b0b59a75f2727a`.

## Hypothesis and implementation

The previous keys-only candidate removed HP-driven geometry rebuild scans but still allocates and hashes every block key per frame. This separate candidate uses a monotonically increasing world-owned revision. All membership writes use `_set_block`, `_erase_block`, `_clear_blocks`; HP-only updates and absent erases do not advance it. A whole-dictionary setter invalidates even for a same-size replacement. The occluder only uses this accessor under the same fallback-solidity guards; floor/fingerprint worlds remain unchanged.

All 117 canonical scripts were retrieved and audited. Direct external writers in capture and QA scripts were migrated. Synchronous aliased capture edits already assign the dictionary after mutation; an early invalid-resource return was moved before mutation. An independent review found that gap and verified its correction. No companion/hero source or asset changes. The companion terrain API is covered because it can mutate terrain; this is not a companion rendering optimization.

Both timing variants include the new bookkeeping. The comparison isolates original full nested-value hash versus revision retrieval, not unmodified-original end-to-end performance. The QA flag defaults off. No production/runtime publication or phone retest.

## Completed gates

The patched immutable pack verifies all original file hashes and resource MD5s, replaces nine remaps, adds ten raw source scripts, and preserves 1393 original entries unchanged. Candidate artifact `10850173910`; build evidence `10850074179`.

Six exported core cases passed: input, touch (125 checks), DEV build/save flavor, crusher (real loot/depth2/accounting), companion autonomy (50 checks), world (461 checks). Parser/runtime checks are included in each gate. Build evidence is under `build/`.

## Browser gate design

Two macos-15 Apple GPU WebKit repeats at 2328x1260 / CSS776x420 / DPR3. Eleven new checks call actual mining, crusher, companion terrain, respawn, barrier and reload methods. Optimized-first A/B/A full-frame comparisons include equal-count key replacement, dictionary replacement, clear/refill, four mines, damaged/broken/restored terrain, five lamp styles and movement. Twelve-second held-mining windows use balanced six-window orders (opposite across workers). Retain timing drift and all outliers. GPU interval availability is reported, not assumed. Actual PNGs and raw reports are independently reviewed; see `independent-review.json`.

Mac WebKit does not establish physical iPhone FPS. The prior rejected floor merge, zero-alpha, narrower terrain strips and world-scale variants remain rejected; do not repeat them unchanged.

## Final outcome — both workers completed successfully

Both workers passed 221 checks each, including all eleven real gameplay mutation checks. There are **108 pixel-exact full-frame pairs**, zero differing channels, and twelve held-mining measurement windows total. All final light inventories are identical, with expected baseline/revision modes. macOS WebKit 26.5, Apple GPU, full native DPR3; GPU timer extension unavailable.

| Worker | Full-hash FPS | Revision FPS | Full-hash refresh ms/frame | Revision refresh ms/frame |
| --- | ---: | ---: | ---: | ---: |
| 1 | 32.5632 | 35.5930 | 1.58681 | 0.03385 |
| 2 | 45.8419 | 45.6099 | 1.31859 | 0.03304 |

Weighted FPS uses total frames divided by total seconds, without dropping any window. Worker 1 changes +9.30%; worker 2 -0.51%. Refresh time falls 97.87% and 97.49%. Baseline has 52–53 geometry-input rebuild scans per window; all six candidate windows have zero. Draw calls remain 178 and mining impacts 53–55. This proves removal of redundant helper CPU work in this fixture; it does **not** establish a stable full-frame performance gain or solve the phone FPS issue.

Keep worker 2's early optimized 32.57 FPS / p95 53 ms, followed by baseline 39.57 / p95 41 ms, in the results. Subsequent windows rise in both modes. Worker 1's p95 values are also mixed. Do not report only the best late windows or generalize the 98% helper saving to total CPU or GPU time.

Evidence: browser artifacts `10850344285` (repeat1, 27527042 bytes) and `10850828868` (repeat2, 27476874 bytes); build `10850074179`; candidate `10850173910`. All artifact archives were size-checked and parsed. Original export hashes and every original resource MD5 were verified before patching. See `analysis.json`, `source-audit.json`, `PROVENANCE.json`, full browser reports, build results and `independent-review.json`.

Retain this separate CPU candidate, including the proposed production-only patch, **unapplied**. Canonical runtime, public DEV15.9, LIVE and saves remain unchanged. No phone retest requested. The source audit covers current writers; future membership mutations must use the helpers or an explicit whole-dictionary assignment. Count-only shortcuts remain invalid.

Known scope limits: QA fixture timings share revision bookkeeping in both modes; baseline is the original hash decision, not an unmodified original executable. Refill's revision assertion compares against pre-clear; actual pixel parity plus insertion/replacement checks independently cover the return. Historical invariant-registry assertion is unchanged and was not rerun in this partial source checkout; no new invariant success is claimed. Physical iPhone and GPU-stage performance are unverified. All jobs are complete; no background reasoning is continuing.

Next distinct investigation may isolate the two unshadowed fixed work lights or use on-device GPU profiling if an authorized route becomes available. Current evidence does not identify the dominant remaining bottleneck. Do not rerun unchanged matrices or publish merely because helper CPU savings are large. A new phone request still needs a stronger full-frame candidate.
