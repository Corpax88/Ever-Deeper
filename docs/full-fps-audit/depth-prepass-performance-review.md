# Independent depth-prepass evidence review

Decision: **mechanism and sampled image-equivalence gates pass; performance acceptance is unresolved. Do not promote this as the proven phone FPS fix or a universal production web default.** It is a bounded, image-checked DEV candidate, not a demonstrated GPU-time reduction. LIVE remains unchanged.

Reviewed existing artifacts only; no new runtime tests or workflows launched.

## Identity and scope

- Diagnostic source: `1c3f5c552cff462cb0da74041e85e16762a524ce`.
- Exact underlying DEV15.16 source: `0225855d5b243fadf75c5267898ac2cd6edb3d0b`.
- Reports: `depth-prepass-evidence-webkit/report.json` and `depth-prepass-evidence-chromium/report.json`.
- Build manifest says the sole candidate runtime difference is startup `override.cfg: rendering/driver/depth_prepass/enable.web=false`. Both share the QA helpers, shipped JS/WASM and all 1,425 original resources verified unchanged.
- Both actual DPR 2, canvas 1552 × 840, Apple-backed graphics. WebKit reports Apple GPU; Chromium reports ANGLE Metal Apple Paravirtual device. Both masked renderer strings are `WebKit WebGL`.
- All report/stage errors are null. GL inventory ends with `installed:false`; timing explicitly refuses installed GL wrappers. GPU queries are separate from normal timing.
- Every stage is a fresh context. WebKit order is baseline/candidate/baseline; Chromium candidate/baseline/candidate. These are short, near-60-FPS Mac observations, not independent repeated physical-iPhone runs. Different-browser opposite orders do not by themselves supply both orders within either browser.

## The removed pass is now directly identified

Baseline's 400 × 400, two-sample native color/depth framebuffer has:

| Pass | Color mask | Depth write | Depth function | Draw buffers | Geometry/frame |
| --- | --- | --- | --- | --- | --- |
| Depth prepass | all false | true | GEQUAL (518) | NONE (0) | 106,057 triangles, 2 draws |
| Visible color | all true | false | GEQUAL (518) | COLOR_ATTACHMENT0 | 106,057 triangles, 2 draws |
| Candidate visible color | all true | true | GEQUAL (518) | COLOR_ATTACHMENT0 | 106,057 triangles, 2 draws |

All these draws have depth testing enabled and rasterizer discard disabled. Candidate has no depth-only row. The shadow geometry remains 106,057 triangles/frame and the transform-feedback skinning remains 124,069 POINTS/frame, with discard enabled and feedback active. The actual removal is exactly one full depth geometry submission; it is not elimination of skinning, shadows or visible geometry.

This corrects the earlier tentative explanation of two visible lighting passes. It also does **not** establish that the removed pass was universally wasted work: prepasses can trade additional geometry work for less later fragment shading. Here the color pass also changes from no depth writes to depth writes.

The standard Godot draw-count monitor stays 101 in both variants, illustrating why that counter alone missed this pass. No reduced model detail, atlas resolution, MSAA, 2D light state or animation update rate was used.

## Normal cadence: all six windows retained

Quantiles below are nearest-rank quantiles recomputed from every recorded engine interval. No outliers were removed. `drawn == process` in every window. Physics cadence remains approximately 60 Hz, so the candidate does not achieve its results by slowing simulation.

| Browser/order | Setting | Drawn/process | Elapsed ms | Actual FPS | Physics frames / Hz | p95 / p99 / max ms | Frames >33 ms | Callback mean / max ms |
| --- | --- | ---: | ---: | ---: | --- | --- | ---: | --- |
| WebKit 0 | baseline | 887 | 15305 | 57.955 | 918 / 59.980 | 23 / 40 / 86 | 13 | 5.261 / 27 |
| WebKit 1 | candidate | 915 | 15253 | 59.988 | 915 / 59.988 | 18 / 20 / 25 | 0 | 4.733 / 9 |
| WebKit 2 | baseline restored | 887 | 15201 | 58.351 | 913 / 60.062 | 19 / 42 / 74 | 10 | 5.040 / 11 |
| Chromium 0 | candidate | 912 | 15234.7 | 59.863 | 915 / 60.060 | 18.4 / 22.2 / 34.5 | 2 | 10.018 / 33.8 |
| Chromium 1 | baseline | 897 | 15207.9 | 58.983 | 912 / 59.969 | 19.6 / 31.7 / 75.9 | 6 | 7.924 / 59.8 |
| Chromium 2 | candidate restored | 923 | 15382.8 | 60.002 | 923 / 60.002 | 18.2 / 19.0 / 37.7 | 1 | 10.750 / 26.7 |

The normal-window cadence signal favors the candidate in both browsers, including tails. WebKit gains 1.64–2.03 FPS against its bracketing baselines; Chromium candidates gain 0.88–1.02 FPS against baseline. This is evidence of a small Mac cadence improvement in these windows, not evidence of a sustained 40s-to-60 phone recovery.

Important contrary result: normal Chromium callback means are **2.09–2.83 ms higher** in candidate windows. A callback includes engine-side waiting/submission, not just useful CPU computation; the exact shipped cap-60 scheduling path has already been shown to contain frame-delay waiting. The higher durations cannot be relabeled a CPU win or explained away without a measurement separating that waiting.

Normal rAF observations independently track the same broad cadence pattern: WebKit 58.255 / 60.063 / 58.400 Hz; Chromium 59.917 / 59.130 / 60.036 Hz. They are not interchangeable with Godot-drawn FPS: their start/end windows differ by command-delivery overhead and they count browser callbacks.

## GPU-command query counterevidence must remain visible

WebKit has no timer-query extension. Chromium's separate four-second callback intervals report:

| Stage | Samples | Mean ms | Median ms | p95 ms | p99 ms | Max ms | Instrumented engine FPS |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Candidate 0 | 238 | 10.258 | 10.576 | 12.966 | 23.022 | 25.018 | 59.301 |
| Baseline 1 | 240 | 8.611 | 8.579 | 10.979 | 21.764 | 27.135 | 59.536 |
| Candidate 2 | 236 | 10.026 | 10.506 | 12.121 | 18.249 | 19.608 | 58.691 |

Every query sample is retained, including short samples. All samples have been collected (`pending=0`), all stages report `disjoint=false`, and sample counts exactly match the respective instrumented callback counts. There is no basis to discard these measurements as unavailable/disjoint.

Both candidate means are **1.42–1.65 ms (16–19%) longer**, not shorter, and both medians and p95 values are also worse. The candidate's lower extreme maximum in these tiny samples does not reverse that finding. Instrumented FPS does not improve either.

These queries enclose the whole engine callback, not individual native passes. They include command submission gaps and can span CPU/frame-cap waiting before the ending GPU query is submitted. Therefore they do not establish a pure-GPU regression, but they decisively forbid claiming a measured GPU-time saving from these results. The discrepancy with normal cadence remains unresolved. Removing geometry submissions is a proven work-count change, not a proven GPU-time change.

## Image/state checks and their boundaries

- Seven fixed native-viewport poses per browser: four idle directions and three mining phases/directions with Ember gear.
- Fourteen cross-setting image comparisons and fourteen same-setting restoration comparisons across both browsers report zero changed channels, maximum difference zero, mean zero.
- Independent SHA-256 comparison of the actual captured PNG bytes also matches across all three stages for every pose in each browser.
- This proves exact image equivalence for those sampled 400 × 400 native renders, not every possible material, equipment item, pose, browser or physical phone.
- Native generation count is stable at one; animation updates continue. 2D-light state is unchanged within each timing window; shadow remains enabled, atlas 4096, native viewport 400 × 400 with 2× MSAA. Node count is 815 throughout.
- Video-memory monitor values are stable within each window. The first Chromium candidate context reports ~4 MiB more than the other two contexts; no memory saving is established. This monitor is not complete instantaneous GL storage accounting (the preceding shadow-atlas experiment already demonstrated that limitation).

## Promotion decision

1. Accept **identification/removal of the extra depth-only submission** and the **sampled lossless rendering check**.
2. Describe the normal Mac cadence result exactly, with the small near-cap gain and tail improvement.
3. Retain the contrary callback/query data; do not claim this is a demonstrated GPU optimization or the phone root cause.
4. Keep production/default promotion and LIVE on hold. If the parent chooses to advance the candidate, its appropriate status is an isolated DEV phone-proof candidate, not an accepted universal fix. No new tests were launched by this audit.
