# Round 2 results — synchronization and audio observations

Run 36407069342, exact QA commit `c8c3eed57606c8131d1dc33666595f7b59e66381`. Both Mac jobs completed with `error: null`. Reports read directly from `/tmp/ever-deeper-round2-evidence/fps-round2-1/report.json` and `fps-round2-2/report.json`. Runtime: Apple GPU, WebKit/Safari 26.5, DPR 3, canvas 2328×1260. These are Mac observations, not physical iPhone measurements.

The FBO and audio scripts were active together during one nominal five-second surface-idle diagnostic per worker. Both were uninstalled before the subsequent FPS windows. No FBO caching, audio-report throttling, depth-prepass change, runtime release, or publication occurred.

## 1. The repeated framebuffer validation is real and its observed configuration is invariant

| Observation | Worker 1 | Worker 2 |
|---|---:|---:|
| Native completeness checks | 227 | 296 |
| Checks after the first with unchanged tracked configuration | 226/226 | 295/295 |
| Native-call wall time summed | 101 ms | 95 ms |
| Mean native-call wall time per check | 0.444934 ms | 0.320946 ms |
| Maximum individual native-call wall time | 2 ms | 2 ms |
| FBO groups / dropped groups | 1 / 0 | 1 / 0 |

Both workers observe `checkFramebufferStatus(GL_FRAMEBUFFER)` (target 36160), returning `GL_FRAMEBUFFER_COMPLETE` (36053), on FBO trace ID 269. Its sole attachment is `GL_DEPTH_STENCIL_ATTACHMENT` (33306): texture ID 270, target `GL_TEXTURE_2D`, level 0, `GL_DEPTH_STENCIL` format, 400×400, nearest filtering and clamp-to-edge. Creation of both objects was observed. The attachment version stays 1 and resource version stays 5; first/last snapshots are identical. The one “changed” count is the first check establishing a reference, not evidence of a mutation inside the observation window. No framebuffer reattachment call appears in either active window. No multiview/attachment-mutating extension appears in the observed extension list.

This is strong evidence for a redundant **steady-state validation of the same native depth backbuffer**. Its dimensions match the native hero viewport. It is consistent with the previously traced engine `RenderSceneBuffersGLES3::check_backbuffer()` path: depth-texture use makes that function run, while allocation is conditional and `glCheckFramebufferStatus` is unconditional. The recorded WASM call stack is the same on both workers (`wasm-function[67276]` then `[18635]` etc.), but is not symbolized. Therefore the exact source-function attribution remains supported inference, not a symbol-resolved stack proof.

The trace also narrows the hidden-copy lead: this FBO has a depth-stencil attachment and no color attachment. If the inferred engine path is correct, the native view requests a depth copy rather than a color/screen-texture copy. The material that requests depth still needs identification. Do not assume the ordinary hero surface shader is responsible; the audited `native_surface.gdshader` does not declare a depth texture.

**What the cost means:** the averages are CPU-thread/native-call **wall time**, including possible browser/driver synchronization, at coarse approximately millisecond timing resolution. They are neither GPU elapsed time nor guaranteed recoverable frame time. GL wrappers also add surrounding observer work. There is no no-check variant in this run, so no FPS gain is established. The trace has no exact elapsed/frame denominator of its own: do not divide its totals by frame counts from the later helper/FPS windows, or call its check count an exact engine FPS measurement. The captured cost is modest and does not on its own establish the user's large FPS drop.

**Candidate status:** promote this from speculative to a supported target for a narrow engine-owning-function experiment. Preserve actual completeness validation at creation/attachment changes and failure cleanup; cover resize/DPR, reconfiguration, tools/world/menu lifecycle, and context recreation. Observing stable surface idle is not proof that an arbitrary JavaScript cache is safe in those states. No further test was run here.

## 2. One music stream produces hundreds of position messages each second

| Observation | Worker 1 | Worker 2 |
|---|---:|---:|
| Exact observer elapsed | 5,049 ms | 5,019 ms |
| Position messages received | 1,948 | 1,903 |
| Observed message delivery rate | 385.819/s | 379.159/s |
| Audio context sample rate | 48,000 Hz | 48,000 Hz |
| Mean position advance per adjacent received message | 128 frames | 128 frames |
| Active position-reporting nodes | 1 | 1 |
| Other created node messages / nonmonotonic position changes | 0 / 0 | 0 / 0 |

The baseline worklet is hash-verified (`be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8`) and sends one message on every nonempty processing quantum. The two observed position spans, divided by `(messages − 1)`, are exactly 128 frames, consistent with that source and a 128-frame quantum. Nominal audio-block cadence at 48 kHz is 375/s. Received rates slightly above 375/s are message-delivery-window observations; they can include scheduling/queue boundary effects, especially with simultaneous GL profiling. They must not be interpreted as an audio playback speed measurement or a precise stable-rate estimate.

This confirms the code-backed lead: despite music PCM reuse, the active music position still causes hundreds of MessagePort deliveries per second on the main thread. The second allocated node is inactive in both windows. These runs do not exercise overlapping effects or music crossfades, so their traffic cannot be extrapolated as measured totals for ten voices or two simultaneous music tracks.

**What remains unmeasured:** no CPU cost per message, queue age, garbage collection correlation, audio glitch rate, reduced-cadence comparison, or resulting FPS gain. Passive listeners add observer work and share this window with FBO instrumentation. The lead merits a bounded later reporting-cadence experiment, but is not a confirmed FPS cause. Any candidate must preserve audio samples/graph/speed and test position lag, crossfade timing, pause/resume and effects. Do not disable position reporting outright.

## 3. Relation to the CPU helper/FPS windows

These observations occurred before the helper candidates, so neither the measured FBO work nor audio cadence explains a difference **between** their baseline and candidate modes: both modes retain the same framebuffer checks and audio traffic.

The helper window results themselves require restraint. Idle windows have **zero path calls and zero contact calls in both workers**. The only active candidate is the bind-transform cache. In-window measured bind CPU averages are small:

| Idle mode | Worker 1 | Worker 2 |
|---|---:|---:|
| Baseline bind wall time per counted call | 0.039474 ms | 0.027174 ms |
| Candidate bind wall time per counted call | 0.018973 ms | 0.016649 ms |
| Weighted baseline → candidate idle FPS | 41.360 → 53.925 | 56.276 → 58.047 |

The roughly 0.011–0.021 ms measured bind difference does not substantiate a causal attribution of worker 1's 12.6-FPS idle gap. Browser timing/threshold effects and drift remain possible; the measured windows are useful observations but do not establish a stable full-game FPS gain of that magnitude. The synchronous bind benchmark further remains mixed: worker 1's two 1,000-call controls and candidates both total 28 ms; worker 2's controls total 29 ms and candidates 43 ms. Do not promote the bind cache as a proven performance win based solely on aggregate FPS.

Walking windows also have unequal path workloads: worker 1's first baseline window has 5 searches/22 blocked checks versus 6–7 searches/108–126 checks in later windows; worker 2's first candidate has 4 searches/18 checks versus 6 searches/108 checks later. The player is repositioned for each walk but the pet's state is not equivalently reset in the harness. Hence those are not identical pathfinding workload timings. Total walking FPS is mixed across workers (worker 1 weighted 39.589→42.082; worker 2 56.158→55.243).

All FPS windows still use per-helper profiling (`profile:true`) and periodic QA state serialization. `_round2_hero_stats()` as run also recomputes parity every ~200 ms. These are same-source, instrumented windows, not an uninstrumented production benchmark. Before/after helper counters come from periodic snapshots rather than the exact engine begin/end timestamps, so dividing them by each other is appropriate for approximate helper time per counted call, but treating them as exact per-render-frame CPU accounting is not.

No invalid native call or false FBO status was observed; the diagnostic observations remain useful. The invalid **interpretations** would be: calling wall time GPU time, treating hundreds of messages as measured FPS loss, claiming the idle gap is caused by pathfinding, claiming the small bind change proved a large gain, or carrying any Mac result across as an iPhone fix.

## Result to carry forward

Retain two distinct new supported investigation candidates: (1) repeated validation of an unchanged native 400×400 depth backbuffer, now observed twice; (2) audio-position reporting at one message per audio quantum, now observed twice. Neither has been changed or shown to improve FPS yet. The third code cleanup (unchanged per-frame music volume assignment) was not measured in this run and stays low priority.
