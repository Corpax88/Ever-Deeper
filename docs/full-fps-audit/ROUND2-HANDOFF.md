# Ever-Deeper — FPS audit round 2, 28 September 2026

Mats explicitly requested a second team investigation for other candidates. The depth-prepass candidate is PARKED: do not enable, publish, or repeat it as part of this round. Keep its prior evidence: branch `codex/depth-prepass-audit-20260928`, source `1c3f5c552cff462cb0da74041e85e16762a524ce`, run `36392214186`; fourteen pixel-identical pairs, mixed browser timing, no physical-iPhone acceptance.

## Exact baseline

Public DEV remains 15.16. Immutable `surface-probe-candidate` artifact 10952875555, run 36380070907, source 0225855d5b243fadf75c5267898ac2cd6edb3d0b. Artifact ZIP SHA256: 06e46692f2224518997516a9c14cfe32a82ef611cafa23da5f503ca585ab8c18. PCK: 262003869 bytes, SHA256 ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72. Current public PCK and engine JS were retrieved and verified against the immutable baseline; all 1427 PCK resource digests passed.

The audit uses a separate branch `codex/fps-round2-20260928`. The root repository runtime can be older than the additive PCK patches. Resolve active remaps before attributing a finding; in particular, DEV15.14 installs the stance runtime from `.github/hero-stance/runtime_motion.gd`.

## Scope

Investigate hero CPU work, world/companion CPU work, and browser/render synchronization. Preserve approved graphics, resolution, lights, animation, gameplay and saves. Diagnostic source substitutions are isolated in the QA package. No production publishing is requested by this round.

## Candidate status

- Hero contact-search invariant calculations: code-backed hypothesis for mining-start/retarget hitches; not an explanation of stationary surface FPS.
- Immutable inverse-rest transforms: code-backed candidate for per-frame CPU work; total FPS benefit unmeasured.
- Companion collision queries inside one synchronous path search: code-backed candidate for navigation hitches; retain identical path/search order.
- Repeated framebuffer validation: separate read-only call/mutation/timing profile; do not bypass WebGL validation speculatively.

## Finished investigation and ranking

Both Mac workers completed successfully in run **36407069342**, exact QA commit **c8c3eed57606c8131d1dc33666595f7b59e66381**. WebKit26.5, Apple GPU, 776×420 logical viewport, DPR3, 2328×1260 actual canvas. Sixteen live timing windows retained, with opposite ABBA/BAAB orders. These are diagnostic, instrumented same-source comparisons, not a release approval or a physical-iPhone FPS result. The depth-prepass setting is unchanged. No jobs remain waiting.

| Candidate | Actual evidence | Disposition |
| --- | --- | --- |
| Repeated framebuffer validation | One observed complete depth-stencil-only400×400 framebuffer; 227/296 checks per worker and all226/295 repeat signatures unchanged. Summed native-call wall time101/95ms over about5s; averages0.445/0.321ms/check, max2ms. | **Priority1 new engine candidate.** Investigate an allocation/attachment-change-scoped validation path. Exact originating material is not established. No checks have been skipped and no FPS benefit is established. |
| Audio position message cadence | One active48kHz music stream delivered1948messages/5.049s and1903/5.019s:385.8/379.2messages/s. Consecutive positions differ by128 audio frames. | **Priority2 new audio candidate.** Study bounded position-report frequency while preserving sound, sample position accumulation, crossfade, pause/resume and SFX lifecycle. Message volume is measured; its CPU/FPS impact is not. |
| Contact-search pitch-basis reuse | Same exhaustive cold search, six calls/mode/worker:163→146ms and101→83ms total,10.43%/17.82% less time. All24 returned outputs exact. Worker1's middle case regressed8.16%. | **Retain as a limited mining-start/retarget hitch candidate.** Zero natural contact calls in these idle/walking windows; not a stationary-surface FPS explanation or fully accepted production motion change. |
| Companion per-search collision cache | Seven paths/worker, four repeats each, all56 path arrays equal and cache empty on return. Actual collision evaluations760→616 per mode/worker (~19% less). Total forced-search time17→13ms /13→11ms. | **Low priority helper candidate.** All8 idle windows had zero searches. Natural walking spent0–5ms total per~6s window with unequal search counts; no persistent-FPS explanation. |
| Cached inverse-rest bone matrices |17 submitted bone matrices compare exactly. Repeated1000-call CPU batches:28→28ms total on worker1,29→43ms on worker2. | **Reject promotion of this prototype.** Neutral/worse isolated timing; apparent large live FPS gaps cannot be attributed to this tiny helper. |

The contact and path methods operate on original source bodies preserved behind QA toggles. Native rig/task motion and companion originate as compiled scripts in the immutable package; the diagnostic substitutes guarded source text for BOTH compared modes. This establishes local output parity, not full equality with every original compiled game state. The approved DEV15.14 stance runtime remains intact.

## Live-window results and limits

| Worker / scene | Weighted engine FPS baseline→candidate | Frames >33ms baseline→candidate | Worst frame ms baseline→candidate |
| --- | ---: | ---: | ---: |
|1 idle |41.360→53.925 |111→29 |91→81 |
|1 walking |39.589→42.082 |88→78 |174→78 |
|2 idle |56.276→58.047 |12→5 |167→52 |
|2 walking |56.158→55.243 |1→7 |60→72 |

Live windows toggled bind+path together; contact optimization stayed false. Workloads differ while walking, scheduling/phase drift is substantial, and the helper timings cannot explain worker1's large idle difference. **Do not advertise those FPS gaps as proven improvement.** Every window/outlier is retained. Godot web helper times in this run are quantized to1ms, so tiny per-search differences are weak evidence. FBO native-call wall time is not GPU elapsed time. The read-only GL/audio wrappers were uninstalled before live timing.

Eight candidate image pairs plus eight restoration comparisons were pixel-identical. Root inspected two actual captures and an independent reviewer inspected nine, including all four candidate directions and both workers. Visible art/lighting/HUD are intact. The hero/tool reaches the right image edge after walking, so these captures do not provide full hero framing/visual-release acceptance. There is no production publication from this audit.

## Durable evidence and next step

- Full JSON reports (all windows and benchmarks) and build receipts are under `round2-evidence/`. Specialist analyses: `HERO-CPU-RESULTS.md`, `WORLD-CPU-RESULTS.md`, `FRAME-MEMORY-RESULTS.md`; source investigations remain in the adjacent uppercase reports.
- Worker1 artifact10962842603,46894055bytes,SHA256efc851d7ff77eabc9116f2326f49d15254d4be41c2f630abc582e3bfc0e84a53.
- Worker2 artifact10963170103,46920731bytes,SHA2568dbfeff01b984e3976cbaf70eb1928b02bc1541ad9c20eb4a5e21c99166bb2ac.
- Both downloaded ZIP sizes/SHA256/CRC were verified before reading. Original images/logs remain in those30-day workflow artifacts. Do not claim indefinite retention of the raw screenshots.
- Current-source QA code: `.github/fps-round2/`; workflow `.github/workflows/fps-round2.yml`. It downloads the immutable baseline and never publishes. Do not repeat this unchanged matrix.
- Established graphical route worked: macos-15, Node22, Playwright1.62.0, Apple WebKit/Apple GPU. Large local binaries/PCKs must live under a task-specific `/tmp` directory; scratch large-file copies were truncated after initial creation. The corrected `/tmp` Godot4.7.2 binary and pack verified. Standalone `--check-only` on a QA suite lacks autoload context (`RunState`), so it is not an acceptance gate; actual exported-game Mac execution passed.

Next distinct work, if continuing FPS optimization: isolate the redundant framebuffer validation or audio position reporting with original checks/audio semantics preserved, then perform one controlled comparison. Keep the depth-prepass candidate parked until Mats revisits it. No phone test is required of Mats for this completed investigation. DEV15.16 and LIVE remain unchanged; **the physical40-FPS issue is not declared solved**.
