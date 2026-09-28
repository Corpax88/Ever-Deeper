# Native hero CPU results — round 2

Run `36407069342`, source `c8c3eed57606c8131d1dc33666595f7b59e66381`, two passing Mac Apple GPU/WebKit workers. Evidence: `/tmp/ever-deeper-round2-evidence/fps-round2-{1,2}/report.json`. Both report `error: null`. This review performed no new tests and changed no game code.

## Decision

**Retain contact pitch reuse as a bounded CPU/stutter candidate, not an overworld FPS fix. Reject inverse-rest caching as a demonstrated performance candidate for promotion: its direct benchmark is neutral on worker 1 and slower on worker 2.** Neither is ready for physical-iPhone acceptance or publication on these results. Depth prepass remains parked and was not changed.

## Exact contact-search benefit

The cold exhaustive search keeps the original 51,300 candidate evaluations and search order, while reusing the 19 pitch bases per point/height. All 24 old/new result checks across both workers were exact for success/failure, tool Transform3D, yaw and chosen contact point. Each worker ran three synthetic 12-point contour cases in ABBA order; only case 0 was reachable, and cases 1 and 2 were unreachable in both implementations.

| Worker | Baseline total, six calls | Candidate total, six calls | Change | Mean cold call |
|---|---:|---:|---:|---:|
| 1 | 163 ms | 146 ms | 10.43% lower | 27.17 → 24.33 ms |
| 2 | 101 ms | 83 ms | 17.82% lower | 16.83 → 13.83 ms |

| Worker / case | Baseline mean | Candidate mean | Interpretation |
|---|---:|---:|---|
| 1 / reachable 0 | 30.5 ms | 22.5 ms | 26.23% lower |
| 1 / unreachable 1 | 24.5 ms | 26.5 ms | **8.16% slower; retained** |
| 1 / unreachable 2 | 26.5 ms | 24.0 ms | 9.43% lower |
| 2 / reachable 0 | 16.0 ms | 14.0 ms | 12.50% lower |
| 2 / unreachable 1 | 16.5 ms | 13.5 ms | 18.18% lower |
| 2 / unreachable 2 | 18.0 ms | 14.0 ms | 22.22% lower |

The sample supports a useful direction at one synchronous CPU hotspot. It does not establish stable improvement for every contact: worker 1 case 1 regressed, sample count is small, and reported wall-clock times are quantized to whole milliseconds. The candidate still takes 20–30 ms for some tested cold calls. Do not translate the 10–18% helper saving into a whole-game FPS percentage.

All live windows recorded **zero contact calls**, and contact hoist was false in those windows. Consequently the natural gameplay frequency and actual stutter reduction were not measured. The benchmark uses the active Ember tool/stance data, not every gear or natural contour. Preserve it as an unpromoted candidate; it cannot explain this run's stationary overworld FPS.

## Inverse-rest cache: neutral/negative direct benchmark

Both workers checked all 17 submitted bone matrices exactly, with zero mismatches. ABBA benchmark rows each submit the same pose 1000 times.

| Worker | Baseline runs | Candidate runs | Summed baseline → candidate | Per submission |
|---|---|---|---|---|
| 1 | 15, 13 ms | 14, 14 ms | 28 → 28 ms, neutral | 14 → 14 µs |
| 2 | 15, 14 ms | 25, 18 ms | 29 → 43 ms, **48.28% slower** | 14.5 → 21.5 µs |

This is not a demonstrated optimization. Removing inverse calculations is insufficient if array access/caching overhead offsets them. Do not promote or describe it as an FPS solution because some live windows are faster.

The instrumented live helper timing is tiny and mixed. Differences below are computed from after-minus-before counters, excluding settling counts:

| Worker / state | Baseline µs per bind call | Candidate µs per bind call |
|---|---:|---:|
| 1 / idle | 39.47 | 18.97 |
| 1 / walking | 27.18 | **31.78** |
| 2 / idle | 27.17 | 16.65 |
| 2 / walking | 35.56 | 23.12 |

These coarse per-frame timers cannot support a precise microsecond speed claim; the scale is only hundredths of a millisecond per frame. It cannot explain the multi-millisecond whole-frame differences seen in the worker-1 idle windows.

## Whole-game windows do not isolate a hero fix

Live candidate mode switches bind caching AND a separate surface path cache together. The search workload also varies. Contact hoist is off. Total FPS therefore is contextual evidence, not attribution to this hero candidate.

| Worker / state | Weighted baseline FPS | Weighted candidate FPS |
|---|---:|---:|
| 1 / idle | 41.360 | 53.925 |
| 1 / walking | 39.589 | 42.082 |
| 2 / idle | 56.276 | 58.047 |
| 2 / walking | 56.158 | **55.243** |

Both idle orders show an aggregate increase, but the direct bind cost cannot explain its magnitude; worker 2 walking regresses. Drift and combined candidates preclude a reliable phone prediction. Keep the slow frames, including 166 ms baseline maxima; do not drop them. No global smooth-60 or solved-FPS claim is justified.

## Visual review actually performed

Opened and inspected the actual PNGs with image viewer:

- Worker 1: `reference-down`, all four `candidate-{down,right,up,left}`, `restored-down`, `restored-live` (seven captures).
- Worker 2: `reference-down`, `restored-live` (two captures).

The visible world, purple crystalline mountain, portal, companion, HUD, lighting and visible hero portions retain the same materials and spatial relationships. Candidate directions show the expected front, side and back orientation; I observed no new detached visible limbs, obvious material change or disappearing visible hero. Restored live captures render the world and hero after the modes are switched back.

All **eight candidate frozen comparisons** and **eight restored frozen comparisons** in the two JSON reports have changed pixels = 0 and max difference = 0. This is same-package, same-source visual parity in the captured directions.

**Scope limitation:** the hero is at the far right viewport edge in all these captures; part of the figure/tool falls outside the image, most conspicuously facing right. The same framing limitation is present in the reference. Thus these images establish equality of captured pixels, not a fully framed hero/weapon, full animation fidelity, all-gear fidelity, or a new acceptance gate for release. Contact benchmarks are synthetic math comparisons and are not rendered contact/impact playback. Live restored images are not frozen pair checks; a transient bottom status label differs in opacity between workers and is not attributed to a candidate.

## Provenance and acceptance boundary

Both variants run inside the same source-substituted QA package built from immutable DEV15.16. Native rig/task-motion source replaces compiled scripts in this diagnostic; the current stance runtime is retained. This permits the narrow A/B helper comparison and same-source image parity. It does **not** independently prove complete compiled-original parity, production release safety, physical iPhone improvement or natural contact-stutter reduction. The run is useful for candidate triage, not publication.
