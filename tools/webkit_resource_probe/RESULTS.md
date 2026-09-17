# Completed WebKit resource-call diagnostic

Two major callbacks in the actual browser contain long
`getProgramParameter(..., LINK_STATUS)` host calls. They last **449.70 ms** and
**260.02 ms**. The third major callback contains no selected calls and remains
unattributed. These are synchronous WebGL host-call wall times, not exclusive GPU
execution or proven compiler-only cost. No optimization was implemented.

[Mac run 35225485863](https://github.com/Corpax88/Ever-Deeper/actions/runs/35225485863)
and job 105215864958 completed successfully on attempt 1. The measured request is
`f311ec95fd43018c0e2747c9113fce3d882d9610`, a REQUEST-only child of independently
reviewed preparation `667b293f240fe350e7530586c531549d46310926`.
Root verified every reviewed file before advancing the branch. The pre-run review
SHA256 is `08e8bc0c3563f6900c60cb3293f994f7d969439a0c138099756d64358a4e6627`;
the root REQUEST-only verification SHA256 is
`4f04db7e8e9518a8d6880c704eff1b01d4b09d19ad5063de1dc794c5371f5172`.

## Exact measured package and completion

The original DEV11 export is unchanged: production source
`8f5680defb9083bbe1e044d39a10612f2186e7f3`, original artifact 10481858878 from
run 35186932201. Its identity SHA256 is
`027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a` and PCK SHA256
is `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
All nine exported files passed exact size/hash checks. No Godot build ran.
The raw observer remains SHA256
`35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424`.
The actual host's 13 tool/request hashes match the reviewed files and request.

Mac arm64, Darwin 24.6.0, ordinary uid 501, WebKit 26.5, browser process 1679.
The browser exited with code 0 and no signal. The closed runner log contains
exactly one explicit completion marker. Functional, visibility, input, error,
recording-capacity and descriptor-restoration gates all passed. There was no
second attempt, CPU sampler, changed renderer or local graphical run.

## Raw callback cadence and hitches

**3,090 callbacks / 3,089 intervals / 60.00166 seconds**. Mean callback cadence is
**51.4819 Hz**, median interval 17.38 ms, p95 **29.68 ms**, p99 43.12 ms and maximum
**657.82 ms**. This is engine-loop cadence, not presented frames or physical-iPhone
FPS. Both 30-second windows fail the existing p95 ≤20 ms callback-budget gate.

| Relative callback start | Index | Start-to-start interval | Callback wall time | LINK_STATUS call | All selected-call union | Outside selected calls |
|---:|---:|---:|---:|---:|---:|---:|
| 0.24778 s | 14 | 657.82 ms | 557.54 ms | 449.70 ms | 467.62 ms | 89.92 ms |
| 10.68134 s | 515 | 338.14 ms | 305.48 ms | 260.02 ms | 269.50 ms | 35.98 ms |
| 28.50210 s | 1454 | 281.58 ms | 264.00 ms | 0 ms | 0 ms | 264.00 ms |

The following gaps from callback return to next callback start are respectively
100.28, 32.66 and 17.58 ms. They are outside callback wall time and are not
assigned to the selected APIs. Selected spans cover **83.872%** and **88.222%**
of the first two callback durations. The two LINK_STATUS calls begin 0.31274 s
and 10.71230 s after the first measured callback. Each directly follows the
observed sequence compile → COMPILE_STATUS, compile → COMPILE_STATUS, link →
LINK_STATUS. No method or resource identity was inferred from screenshots.

The hitches occur inside the observation period, away from its end. Exact depth
at each event was not recorded, so no biome-transition correlation is claimed.

| Strict threshold | Intervals above threshold |
|---:|---:|
| 20 ms | 876 |
| 25 ms | 338 |
| 33.3 ms | 88 |
| 50 ms | 17 |
| 100 ms | 3 |
| 250 ms | 3 |

Callback duration mean is 10.3677 ms, median 9.10 ms, p95 17.82 ms, p99 25.82 ms
and maximum 557.54 ms. There are 205 callbacks over 16.667 ms, 88 over 20 ms,
15 over 33.3 ms, 5 over 50 ms and 3 over 100 ms. Summed callback wall time is
32.03616 s, **53.392%** of the observation window; that ratio is not CPU utilization.

## Selected-call evidence

All **181 records** fit the preallocated 8,192-slot buffer, with zero drops,
error bits or failed calls. The shared `performance.now()` clock and identical
timeOrigin were verified before/after; the recorder brackets every callback.
An independent integer-microsecond recomputation matches all retained unions.

| Method | Calls | Inclusive wall time | Maximum call |
|---|---:|---:|---:|
| texImage2D | 169 | 9.60 ms | 0.26 ms |
| compressedTexImage2D | 0 | 0 ms | 0 ms |
| texStorage2D | 0 | 0 ms | 0 ms |
| compileShader | 4 | 0.08 ms | 0.02 ms |
| linkProgram | 2 | 0.02 ms | 0.02 ms |
| getShaderParameter, COMPILE_STATUS | 4 | 21.84 ms | 9.98 ms |
| getProgramParameter, LINK_STATUS | 2 | 709.72 ms | 449.70 ms |

The selected-call union is **741.26 ms**, entirely within callbacks: 2.314% of
total callback wall time or 1.235% of the observation window. It explains much
of two rare stalls, not the whole sustained-frame problem. Startup counters
prove non-vacuous hooks: 1,118 texture images, 86 compile calls, 43 link calls,
84 compile-status reads and 42 link-status reads before timing. Calls smaller
than the browser clock quantum can report zero; those raw values are retained.

Program handles, texture bindings and source strings were deliberately not
recorded. **The capture cannot establish whether the same programs or textures
repeat**, nor identify an exact shader variant. The [source trace](SOURCE_TRACE.md)
separates engine facts from that evidence limit and describes a conditional,
bounded initialization experiment without implementing or running it.

## Real play, visual evidence and limits

The ordinary NEW GAME and settled surface/DEV/Layer 12 route passed all saved
navigation gates. Taps and ArrowDown+Space were trusted input; the small untimed
drawer drags remain explicitly untrusted DOM TouchEvents. Seed 1131954258 stayed
unchanged. The persisted route advances depth **12→22**, mined count **+3,937**,
swings **+49**, metres **489→966**, and stream anchor start **11→21**. Those save
receipts bracket a slightly wider period than the exact timed window. All three
closed binary saves decode to their retained JSON receipts.

Untimed draw census: 423 actual calls before and 399 after, each at 1696×780.
All draw wrappers were restored before timing. Entry/final originals were viewed
at full resolution; they show the native approved hero and normal lit Deep
terrain. Ten original PNGs are retained. This is not a pixel-equality experiment.

The seed, runner conditions and instrumentation differ from the earlier 59 Hz
baseline and phase probe. The 51.48 Hz mean must not be called an optimization
regression or a measured gain. Wrappers add overhead, and the observed host calls
may include validation, driver work or synchronization. The third major event
and unwrapped draw, buffer, state, 3D/array, simulation and other work remain
unattributed. This result does not certify stable 50 FPS or justify a shader,
material, quality, program-status or renderer change.

## Closed evidence

Raw artifact **10497908993** is **21,914,453 bytes**, SHA256
`e6feb376e8078ada2f88a3afee9fd7125e677d7ea58e704551583412b71404c2`.
Its ZIP CRC and every one of **56 closed file hashes** were verified. It preserves
raw loop/resource rows, clocks, startup counts, screenshots, errors, actions,
saves, exact identities, source hashes, process receipts and restoration.
`review.json`, all 181 `resource-spans.csv` rows, all 876 `slow-intervals.csv` rows
and the inspected `hitch-host-attribution.png` preserve independent arithmetic.
The analysis/plot scripts were added only after the measured run completed.

Root separately recomputed all 56 closed hashes, all 3,090 callbacks and 181
spans, unions and three major events. Its closed review agrees with the scoped
finding: `root-independent-resource-review.json`, 4,435 bytes, SHA256
`0268c1dc40bb9f5d4531b16ed484d66d8a5aad95754e07ec6bdecf564e0a9412`.
That review is included in the final evidence archive.
