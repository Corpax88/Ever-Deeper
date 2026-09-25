# Occupancy-only shadow invalidation — lossless CPU improvement, not a complete FPS fix

2026-09-25. This follows the measured~1ms/frame occlusion refresh cost in the lighting-isolation study. It leaves all light settings, artwork, companion/hero animation, gameplay and resolution intact. QA-only comparison; no release or phone retest.

## Actual result

Two macos-15 Apple GPU WebKit26.5 repeats at2328×1260,DPR3,CSS776×420. Each passed181 checks,44 full-image comparisons and six12s actual held-mining windows. All88 image pairs are pixel-exact (maximum channel difference0). Matrix covers four mines, intact/damaged/broken/restored terrain, five upgraded light styles and actual camera/player movement. Optimized mode is first and last in each comparison, so mutations made between comparisons exercise its retained input signature. Twelve full PNGs retained for independent review. Exported input,125 touch/gameplay checks and DEV save-flavor passed.

| Repeat | Original FPS | Keys-only FPS | Original refresh ms/frame | Keys-only refresh ms/frame |
|---|---:|---:|---:|---:|
| 1 |38.98|40.15|0.932|0.769|
| 2 |49.32|51.48|1.200|0.682|

Weighted FPS gains are approximately3.0% and4.4%; refresh work falls17.4% and43.1%. These percentages describe these Mac runs only. Timing drift is substantial, windows overlap, and p95 changes are mixed. Original FPS windows: repeat1 41.08/36.86/38.98; repeat2 53.46/43.76/50.76. Candidate: repeat1 43.36/37.66/39.45; repeat2 51.67/44.49/58.22. Do not convert the weighted improvement into a stable phone forecast or claim it explains the entire reported FPS drop.

The precise mechanical result is stronger: original input-signature rebuild scans occur52–54 times per12s durable-target window; optimized mode has zero in all six candidate windows. The refresh function still runs each frame, checks lights/emitter coverage and hashes keys. Geometry updates are retained on real occupancy changes. Draw calls remain178 in all windows; no light/quality reduction is used to obtain the improvement.

## Change and semantic boundary

Original final terrain-signature fallback is hash(world.blocks), including nested HP/value data. The guarded alternative is hash(world.blocks.keys()) only where _solid ultimately uses blocks.has(cell). Worlds implementing _is_floor or _terrain_draw_fingerprint retain their original branches; worlds implementing _terrain_is_solid are explicitly excluded from the new fallback. Coverage and emitter-cell hashes remain unchanged. Full key hashing detects equal-count key replacements by design; that specific replacement case was not separately exercised in the browser matrix. Key-order changes may cause harmless extra invalidations. Allocation and scanning remain O(n).

Independent source review found no geometry-dependency blocker. This demonstrates avoidable CPU work and a tested way to remove damage-only rebuilds. Retain it as a useful candidate rather than discard it with prior negative experiments, but do not present it as the strong final FPS solution Mats requested. Do not request another phone test for this small isolated improvement yet.

## Immutable evidence and reuse

- Baseline canonical cc7cedb161570a29dab3e2480df02ad5d73b1af1; public runtime/export remains DEV15.9 c63aabd3e3e5120579285ce6e8b0b59a75f2727a.
- QA branch codex/occupancy-study-20260925, source e18194eccfb13977dafb9a697bd49c2faf521393, run36096889341. Both build and Mac jobs completed successfully.
- Candidate10847488109; build10846973717; WebKit1 evidence10848260568 (27520418 bytes), WebKit2 evidence10847068985 (27518007 bytes). Both ZIPs extracted successfully. Artifacts retained90days; full JSON reports and build identity retained beside this handoff.
- Same immutable original PCK append route as the preceding study. All original file hashes and resource MD5 values checked;1400 original resource entries preserved. Two remaps replaced (FPS QA fixture and occluder), three raw source scripts added. The original compiled scripts remain present but replaced remaps select the QA versions. Approved binary artwork/native assets remain identical.
- QA flag qa_use_occupancy_keys defaults false. The original and optimized branches are selected by the test helper. Ordinary source/public gameplay has not been changed or published. Source/workflow/packager live on the QA branch; proposed production-only diff is retained in this documentation separately.

## Remaining work

The primary physical-iPhone bottleneck remains unresolved. Prior light ablations suggest rendering/submission cost but do not establish dominant GPU work or isolate fixed worklights independently. Preserve Mats's instruction to keep the companion unchanged and wait for a strong candidate before phone validation.

A distinct next CPU hypothesis could replace repeated full key hashing with an explicit occupancy revision owned by the world and updated at every key mutation. That requires auditing every addition/removal/replacement/configure path and proving invalidation; do not substitute block count or a time delay as an unsafe shortcut. Alternatively isolate the two fixed worklights and combined cone/bounce contribution. Do not repeat the unchanged seven-mode diagnostic or this already verified visual matrix solely to accumulate test counts. No background execution is promised after a turn ends.

## Independent final review

The critic inspected both full reports and all12 actual PNG captures, verified unchanged light inventories and variant modes, and confirmed all88 exact-image comparisons. Verdict: retain the isolated lossless CPU candidate; no release, phone-fix claim or phone retest justified by these modest/drifting FPS results. Full review and evidence hashes are in independent-review.json.
