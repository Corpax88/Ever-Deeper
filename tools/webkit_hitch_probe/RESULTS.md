# Completed diagnostic: the three owners do not directly explain the hitches

[Run 35218778984](https://github.com/Corpax88/Ever-Deeper/actions/runs/35218778984)
completed successfully on its first attempt. Its three large synchronous
callbacks contain **zero overlap** with `_generate_stream_window`,
`_rebase_stream_window` or `save_game`, including the full clock uncertainty.
Those bodies therefore are not the direct duration sources for these three
hitches in this diagnostic session. This does not exclude rendering or resource
work queued earlier by them, and does not identify another engine/driver/GPU owner.
No performance change or production adoption follows from this result.

The exact production base is DEV11
`8f5680defb9083bbe1e044d39a10612f2186e7f3`. Diagnostic runtime code was frozen at
preparation `4f6b479dd0f9c7082982008d54e4c69ee56bc356`; later corrections changed
only tool-side metadata binding and untimed OCR navigation. Final reviewed
preparation is `c8c7cde760ca7b723c8ec39692f70e21ddbdddeb`; measured request is
`f3b9eff96bd992ac11f3a7609b6663f98fc65630`, tree
`ceea6c55bbd231ee9c6931e19d118554b4130764`. All branch refs, trees and parents
were verified against locally computed trees before triggering.

The diagnostic PCK is
`82b8127c7551757c7e8b11e9ec994abeac3a2795543225540e5fa16b22e14b81`
(221,018,384 bytes). All nine exported files match the previous two diagnostic
builds byte-for-byte. The original uninstrumented PCK and its successful run
35207448460 remain preserved separately; this new package is explicitly diagnostic.
Raw `observer.js` stayed
`35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424`.
Recorder stayed `dc2b496b121882b3f390868762315224f32f655a6f8e3474c5209de712533a47`.
The source guard proves byte preservation of the whole original world/save
function bodies and every other runtime/asset input outside the declared wrappers,
autoload and one recorded generated UID sidecar.

## Measured callback and phase data

Ordinary ARM64 macOS15 runner, Playwright WebKit26.5, CSS848×390/DPR2 and actual
1696×780 drawing buffer; this is not a physical iPhone. The raw observer retained
3,558 callbacks and3,557 intervals across60.01644 seconds. Mean engine-loop cadence
was59.2671Hz, interval p95=18.66ms and p99=19.48ms. Mean/p95 cadence is not a
stable50 presented-FPS certificate.

| Start–next-start, seconds | Interval | Synchronous callback | Gap after callback | Possible selected-owner spans |
| --- | ---: | ---: | ---: | ---: |
| 0.46694–0.79784 | 330.90ms | 277.44ms | 53.46ms | 0 |
| 25.73336–25.98192 | 248.56ms | 200.28ms | 48.28ms | 0 |
| 44.50000–44.67676 | 176.76ms | 170.94ms | 5.82ms | 0 |

Strict interval counts: >20ms22, >25ms13, >33.3ms5, >50ms3, >100ms3,
>250ms1. Callback duration mean7.72181ms, median7.04ms, p95=11.34ms,
p99=12.14ms, maximum277.44ms, minimum3.22ms. Thirteen callbacks exceed16.667ms,
eleven exceed20ms, and three exceed50ms. Summed callback wall time27.4742s is
45.7778% of the start-to-last-start span; that is not CPU utilization.

| Owner | Real events | Inclusive sum | Maximum |
| --- | ---: | ---: | ---: |
| Rebase | 10 | 61.74ms | 12.54ms |
| Generate, nested inside rebase | 10 | 60.46ms | 12.44ms |
| Save | 9 | 18.64ms | 2.76ms |

The independent integer-microsecond interval union is **80.38ms**, not the sum
of all three inclusive rows. All29 spans are inside the observer window; none
was dropped, incomplete or out of nesting order. The preallocated buffer is
512×15×8=61,440 bytes. There is no timed JSON/file/log output or per-frame
recorder hook. Costs include wrapper/recorder work and synchronous waits.

Five JS-before/engine-tick/JS-after clock brackets on each side give offset bounds
3192.01–3192.11ms. The reported ±0.05ms includes an explicit timestamp quantization
allowance; it is not a statistical confidence interval. The three major callbacks
remain outside every recorded span even at those bounds. The first rebase is
at4.51490s; the last large callback is about0.628s after the preceding rebase ends.
The timing does not support calling these same-callback streaming or save stalls.

## Functional and completion evidence

Linux job105193520731 passed source, parser, observer, recorder and exact package
identity checks, plus the real packed save/state187 and world461 checks.
Mac job105194172321 has exactly one explicit completion marker, functional=true,
and browserPID23728 exit0 without a signal. The retained console has no runtime,
GL or page errors. Neither visibility nor context changed during timing; inputs
were released and RAF/getContext plus untimed draw wrappers restored.

The ordinary NEW GAME→surface→DEV drawer→ENDLESS · LAYER12 route is proved by
original captures, exact OCR targets, actual trusted taps and committed saves.
Untimed drawer drags use the existing DOM TouchEvent path and are explicitly
untrusted; timed Down+Space key events are trusted. Both loadout and scene gates
passed. Save seed3389930249 stays fixed, depth12→22, mined+3438, swings+48,
metres491→962, and stream anchor start11→21. These save deltas bracket slightly
more than the exact60-second observer window. No game commands or altered
graphics were used by the diagnostic bridge.

Actual restored WebGL census: before376 calls (176 drawElements,178 instanced
elements,21 instanced arrays,1 arrays); after315 (112/177/25/1). These are untimed
draw proofs, not per-callback presentation counts. The10 original PNGs include
both surface confirmations, both Layer12 confirmations and Deep entry/final.
The latter two were inspected at original1696×780; terrain, lighting and the
native approved hero remain visible. This is not an A/B pixel-equality experiment.

## Retained failures and limits

Run35210964673 passed import/export and packed functional tests, then stopped
at the too-strict generated-UID binding gate; Mac was skipped. Run35211444182
had an unchanged valid diagnostic package but stopped at a0.5-confidence exact
DEV toggle during untimed navigation; its original screenshot proves the start
modal did close. It has633 advancing engine callbacks, inactive phase buffer,
zero timed samples, clean exit and no runtime errors. Both original artifacts,
candidate ZIPs, errors and corrections remain retained. Neither failure supplies
accepted performance samples. The completed diagnostic is the first timed probe.

This fresh seed differs from the unchanged baseline's seed2421325703. Its lower
callback mean cannot be called an optimization gain, and the old440ms event has
not been erased or reclassified. The three new hitches provide the exclusion
above; they do not prove the exact causes of the old three hitches. No CPU stack
sampler or exclusive GPU timer ran. Unspanned callbacks still include other
simulation work, render setup, synchronous WebGL/driver calls and waits. Deferred
work may be related to an earlier phase without occupying that phase's span.

Raw Mac artifact10496002655 is21,789,094 bytes/SHA256
`462d024822ab0f893a1f68743dadd6cd29b2cfcbae7987dda96dd2f1024c4465`;
build artifact10495449709 is41,603 bytes/SHA256
`a3d82104d73a37cd5197f48635066913550ff8a71b3f82dff22763cad8f51f4b`.
ZIP CRCs, all53 closed Mac file hashes and the numerical results were independently
verified. `review.json`, `slow-intervals.csv`, `phase-spans.csv`, raw clocks and
`hitch-owner-attribution.png` preserve the arithmetic and every visible hitch.
The post-run plotter is not part of the measured harness and plots all samples.

Root independently recomputed all clocks, spans, nesting, union and hitch overlap;
`root-independent-phase-review.json` SHA256
`987625c602ed0b13a2f4a9998b43e45193aed0fa0c726383a9e458a372b555a2`
agrees with the zero-overlap result. It is a separate closure addendum because
the original evidence archive was already sealed.

The complete archive `Ever-Deeper-DEV11-WebKit-hitch-attribution-20260917.tar`
contains45 verified members,494,305,280 bytes, SHA256
`00cfddb343a1f2f6aedc46dce1102570f61e69ef6b9a80859ea88c40c4783574`.
Both original candidate ZIPs, original success/failure artifacts, all13 original
PNGs inside them, raw clocks/samples and derived results are included. Git-pinned
tested tools are not duplicated. The original and four independently verified
125/125/125/119.305MB reconstruction parts remain intact. Initial whole-file and
part01 client uploads timed out at60 seconds without a returned large-file
receipt; root owns subsequent storage work. The chart, numerical review,
independent review and reconstruction manifest already have durable receipts.
