# Completed shader identity diagnostic — 17 September 2026

The single authorized Mac WebKit run identified a 288.34 ms `LINK_STATUS` wait
on new program 45. Its original GLSL matches the lit `USE_ATTRIBUTES` variant
of the existing `lit_visible_pixels` shader family. A separate 240.70 ms callback
has no selected host-call overlap and remains unattributed. This is attribution
evidence, not an optimization, presented-FPS measurement or stable-50-FPS pass.

## Exact completed run

- [Run 35232918221](https://github.com/Corpax88/Ever-Deeper/actions/runs/35232918221),
  Mac job `105241392607`, attempt 1, success.
- Reviewed preparation `f51304083e3ce33097be3da40453de4955d8d84d`, tree
  `3ae5447ba586cbb2a31abade7e93a13d57fc484c`.
- Sole-request child `6eb65feb970a4a935ca9c4497e086145cdb43e4c`, tree
  `d54a712ebf773fd5c9cadbadafe09e174ae614ee`. Root independently verified its
  one-file diff and advanced the ref. No retry occurred.
- Original DEV11 source `8f5680defb9083bbe1e044d39a10612f2186e7f3`, original
  candidate artifact `10481858878` from run `35186932201`; all nine exported
  files and identity matched. PCK SHA256:
  `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9`.
- WebKit 26.5, ordinary Mac process 3912, exit 0/no signal. Session step ran
  14:21:27–14:23:55 UTC. One explicit completion marker, no runtime/recorder
  errors or drops, all nine descriptors and original observer restored.

The original result ZIP, artifact `10502243075`, is **22,113,133 bytes**, SHA256
`c1303cc0e4329e65c99a31bce4942c33f3c7a089e920c91830491c8a8a8cbb00`.
Its size and digest match the GitHub API. ZIP CRC and all 58 closed-file hashes
pass. It was downloaded and checked in `/tmp` before its closed atomic move.

## Actual one-minute observation

There are 3,059 chronological callbacks and 3,058 intervals over 60.01540 seconds.
Mean callback cadence is **50.95359 Hz**, not displayed frame rate. The original
observer and measurement block are unchanged. The two 30-second callback-budget
windows fail their p95 ≤20 ms criterion.

| Quantity | Median | p95 | p99 | Maximum |
|---|---:|---:|---:|---:|
| Start-to-start interval | 17.21 ms | 33.28 ms | 51.28 ms | 571.68 ms |
| Synchronous callback | 8.56 ms | 17.82 ms | 25.88 ms | 450.62 ms |

Intervals strictly above 20/33.3/50/100 ms: **850/151/34/2**. Callback durations
strictly above those thresholds: **98/11/3/2**. Summed callback wall time is
29.69056 seconds, 49.47157% of the observation window; this is not CPU utilization.
The raw chronology and every interval over 20 ms are retained.

| Callback / relative start | Interval | Callback | Selected union | Unwrapped callback | Following gap |
|---|---:|---:|---:|---:|---:|
| 30 / 0.63990 s | 571.68 ms | 450.62 ms | 356.68 ms | 93.94 ms | 121.06 ms |
| 1722 / 33.29436 s | 262.36 ms | 240.70 ms | 0 ms | 240.70 ms | 21.66 ms |

In callback 30, the selected union comprises 288.34 ms of `LINK_STATUS`,
60.68 ms of the two `COMPILE_STATUS` calls, 7.64 ms of texture uploads and
0.02 ms of the link call. It covers 79.15317% of that callback. The status calls
alone cover 349.02 ms. These are synchronous host-call wall times, not isolated
compiler work or GPU execution. The callback's unwrapped portion and following
gap are not assigned to a cause.

| Selected method | Calls | Inclusive duration | Maximum |
|---|---:|---:|---:|
| `texImage2D` | 161 | 11.58 ms | 0.58 ms |
| `compressedTexImage2D` / `texStorage2D` | 0 / 0 | 0 ms | 0 ms |
| `compileShader` | 2 | 0.00 ms at clock precision | 0.00 ms |
| `linkProgram` | 1 | 0.02 ms | 0.02 ms |
| `getShaderParameter(COMPILE_STATUS)` | 2 | 60.68 ms | 45.76 ms |
| `getProgramParameter(LINK_STATUS)` | 1 | 288.34 ms | 288.34 ms |

All 167 selected spans lie within callbacks. Their union is 360.62 ms: only
1.21459% of summed callback wall time and 0.60088% of the whole window. Thus this
finding explains a large isolated hitch, not the overall sustained performance.

## Program and source identity

The recorder retained 90 shader IDs/source versions, 45 program IDs/links and
447 association events, including startup; 1,500,521 UTF-16 source code units.
All limits passed, with zero drops/errors and no extra GL query. Startup had
88 shader sources, 44 programs and 437 events. Only the final two sources and
one program were introduced during the measured window.

| Timed association | Record | Event | Duration |
|---|---:|---:|---:|
| Compile shader 89 | 52 | 439 | 0.00 ms at clock precision |
| Shader 89 `COMPILE_STATUS` | 53 | 440 | 45.76 ms |
| Compile shader 90 | 54 | 442 | 0.00 ms at clock precision |
| Shader 90 `COMPILE_STATUS` | 55 | 443 | 14.92 ms |
| Link program 45 | 56 | 446 | 0.02 ms |
| Program 45 `LINK_STATUS` | 57 | 447 | 288.34 ms |

Program 45's source-pair hash is
`51e583de0862d6689a4d1a90edccc9aa704e4944df052d19686dd1238a74447e`.
Its two original UTF-8 source hashes are:

- Source 89: `aecaa8e92eb4a09192a1cb4733e3a7d0edc9fc1af266c1a41147073fc107967f`
- Source 90: `8b9380594232f57892a2833bcb3295135416357c1c0bc2fde73fa32bc0092b7a`

All 45 complete source pairs are distinct. No program was relinked, and no exact
pair repeated. Programs 40/41/42/43/45 share both complete shader-stage texts
after removing only their leading `DISABLE_LIGHTING`, `USE_PRIMITIVE` and
`USE_ATTRIBUTES` defines. Program 45 adds the previously unobserved lit
attributes variant. [SOURCE_TRACE.md](SOURCE_TRACE.md) binds the original
material and engine paths. The exact first CanvasItem/draw is not captured.
This result does not retrospectively assign identities to the prior run's two
unidentified waits.

## Functional and independent checks

The normal UI route, trusted taps and held mining/movement keys passed. Untimed
drawer drags remain explicitly untrusted DOM TouchEvents. Before/after actual
draw censuses restored their hooks before timing. The retained 1696×780 entry
and final original PNGs were inspected; no same-pixel comparison is claimed.

Seed 2283034825 is preserved. Depth progressed 12→22, metres 493→956, mined
resources +4,715, swings +58, stream anchor 11→21. The actual save has Crusher,
drill level 3, standard light style, miner outfit and original tool appearance.
All three binary save envelopes/checksums and decoded JSON values match.

`analyze_results.py` independently recomputes integer-microsecond span unions,
chronology, thresholds and gates. `verify_closed.mjs` reproduces both actual
Node analyses exactly and compares decoded saves after the same JSON boundary
used by the harness. An initial ad hoc strict comparison rejected the codec's
null-prototype dictionaries against parsed JSON objects; the retained receipt
records that representation mismatch and its correctly scoped recheck.

Root separately verified the ZIP, 58 hashes, all intervals/unions, every source's
UTF-8/UTF-16 hash, all 447 events/45 links/six timed associations, nine restorations,
exit and progression. Root report: **2,764 bytes**, SHA256
`8b86fabd640ab2790297a684bbe20fa308ad8106b0f662a925015ac98b0fc44d`.
Its independent verifier is retained: **8,737 bytes**, SHA256
`334f1eeca9b20c72bd28ef93a498e9627bbe125cbf7aaa0528be8b16dc4517cb`.

The metadata hooks have unmeasured overhead and retain strings longer. This
single random-seed run cannot establish a regression, speedup, physical iPhone
performance, or stable minimum 50 FPS. No runtime, warm-up or deployment change
was made. [NEXT_PROBE.md](NEXT_PROBE.md) is a source-only proposal requiring a
separate review before any implementation or run.
