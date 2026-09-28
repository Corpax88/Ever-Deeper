# World / companion CPU result — round 2

**Disposition: correct, small helper optimization; not a credible explanation or
fix for the measured sustained surface FPS loss.** No production promotion on
this evidence. Mac run `36407069342`, source
`c8c3eed57606c8131d1dc33666595f7b59e66381`; both report errors are null.

Sources: `/tmp/ever-deeper-round2-evidence/fps-round2-{1,2}/report.json`.
Both workers: Apple GPU, WebKit26.5, DPR3, canvas2328×1260. These are Mac results,
not physical iPhone results. No new tests were run for this analysis.

## Forced path benchmark

Each of seven cases runs A/B/B/A. All28 candidate path arrays across the two
workers exactly equal their corresponding original arrays; restoration outputs
also match. Every one of the56 search returns leaves the cache empty and inactive.
Only moss_branch, moss_quarry and moon_bend return nonempty paths. Four cases,
including star_route, return empty paths in both modes; those are retained.

| Case | Output points | Queries → actual evaluations per search | W1 A/B total ms | W2 A/B total ms |
|---|---:|---:|---:|---:|
| moss_branch | 6 | 79 → 63 | 3 / 3 | 3 / 3 |
| moss_quarry | 6 | 100 → 80 | 4 / 4 | 4 / 3 |
| moon_bend | 9 | 128 → 102 | 8 / 4 | 4 / 4 |
| ember_route | 0 | 5 → 5 | 0 / 1 | 0 / 0 |
| ember_resource | 0 | 4 → 4 | 0 / 0 | 0 / 0 |
| star_route | 0 | 60 → 50 | 2 / 1 | 2 / 1 |
| unreachable | 0 | 4 → 4 | 0 / 0 | 0 / 0 |

Totals per worker and mode are14 forced searches: actual collision evaluations
760→616 (144 saved,18.95%). Helper CPU totals17→13ms in W1 and13→11ms in W2.
The clock is visibly quantized to1ms; a recorded0 is below timer resolution, not
proof of no CPU cost. The moon_bend improvement does not repeat on W2, the two
moss cases mostly tie, and W1 ember_route becomes1ms slower. This is modest,
noisy helper evidence, not an aggregate FPS result.

## Natural windows

All eight idle windows recorded **zero path searches**, so this cache cannot
explain any idle FPS difference. Natural walking recorded4–7 searches per~6s
window and0–5ms total measured search CPU. Across both walking windows per mode,
W1 baseline/candidate costs are3/7ms; W2 costs7/1ms. Search counts and exact starts
differ, and frame performance drifts between measurement phases, so these totals
are not matched-workload speedups. Candidate hit totals
are31 in W1 and14 in W2; W2's first candidate walking window has zero hits.

The end-to-end windows toggle binding-cache and companion-path-cache together;
`review.mjs` explicitly keeps the separate contact candidate off. Their FPS
differences cannot be attributed to the companion cache. All windows/outliers
are retained below; p95 uses nearest rank over raw rAF intervals, slow means
strictly greater than33⅓ms. Node count stays815 before and after every window.

| Worker / order | Mode / scene | rAF / engine FPS | p95 / max ms | Slow frames | Search calls / total ms / hits |
|---|---|---:|---:|---:|---:|
| 1 / 1 | A idle | 39.65 / 39.21 | 51 / 90 | 65 | 0 / 0 / 0 |
| 1 / 2 | B idle | 53.90 / 52.43 | 29 / 82 | 15 | 0 / 0 / 0 |
| 1 / 3 | B idle | 55.34 / 55.46 | 24 / 78 | 8 | 0 / 0 / 0 |
| 1 / 4 | A idle | 43.77 / 43.55 | 43 / 70 | 37 | 0 / 0 / 0 |
| 1 / 5 | A walk | 40.30 / 39.52 | 47 / 166 | 38 | 5 / 1 / 0 |
| 1 / 6 | B walk | 42.03 / 40.73 | 41 / 62 | 34 | 6 / 3 / 14 |
| 1 / 7 | B walk | 43.41 / 43.43 | 42 / 78 | 34 | 7 / 4 / 17 |
| 1 / 8 | A walk | 40.73 / 39.66 | 46 / 72 | 36 | 7 / 2 / 0 |
| 2 / 1 | B idle | 59.16 / 59.03 | 19 / 49 | 3 | 0 / 0 / 0 |
| 2 / 2 | A idle | 54.24 / 54.30 | 26 / 166 | 11 | 0 / 0 / 0 |
| 2 / 3 | A idle | 58.36 / 58.30 | 21 / 35 | 1 | 0 / 0 / 0 |
| 2 / 4 | B idle | 57.34 / 57.06 | 22 / 51 | 2 | 0 / 0 / 0 |
| 2 / 5 | B walk | 56.96 / 56.84 | 22 / 71 | 2 | 4 / 0 / 0 |
| 2 / 6 | A walk | 58.74 / 58.60 | 19 / 63 | 1 | 6 / 2 / 0 |
| 2 / 7 | A walk | 54.12 / 53.74 | 26 / 33 | 0 | 6 / 5 / 0 |
| 2 / 8 | B walk | 54.08 / 53.68 | 25 / 53 | 5 | 6 / 1 / 14 |

W2 illustrates the negative cases: its first walking baseline exceeds the
candidate in FPS and has fewer slow frames; its final candidate has five slow
frames versus zero in the preceding baseline, despite similar FPS. Its final
idle candidate is slower than the preceding baseline. W1 includes the166ms
baseline walking stall; W2 includes the166ms baseline idle stall. Neither those
stalls nor their absence in some candidate windows can be assigned to pathfinding
from the aggregate counters.

The measured query reduction is real. The natural search duty cycle is far too
small to explain the large W1 idle difference or sustained phone40FPS. Keep this
as a low-priority efficiency candidate and prioritize the other independent
findings; do not ask Mats to retest the phone for this cache alone.
