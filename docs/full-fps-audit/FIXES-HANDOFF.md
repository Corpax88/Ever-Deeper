# Concrete FPS fixes — 28 September 2026

Mats requested a series of implemented optimizations while preserving the current game, after finding the previous investigation insufficient. Standing DEV publication permission remains; publication still requires actual gameplay and image acceptance. The depth-prepass experiment stays parked. Preserve DEV15.16's appearance, native hero stance/animation, lighting, resolution, gameplay and saved games. LIVE is outside this task.

Four implementations are committed on `codex/fps-fixes-20260928`, initial source `6834643708348ceb6002287325a6e01d4fe8cccd`; Mac run `36410803352`. The first set was fully tested and revised as described below. The candidate version is DEV15.17; public DEV15.16 has not changed at this checkpoint.

## Implemented candidates

- Narrow framebuffer validation cache: only an observed 400×400 depth-stencil-only framebuffer with a preceding native COMPLETE result; tracked mutations, resource disposal, resize and context restoration invalidate it. Unknown state falls back to native. See `FIXES-FBO.md`.
- Music position messages at60Hz instead of every audio quantum; sample accumulation, PCM reuse and playback graph retained. Report freshness can lag by approximately one frame; tested crossfade threshold timing differs by5–6ms, so do not describe position reporting as bit-identical. SFX cadence remains unchanged. See `FIXES-AUDIO.md`.
- Hoisted invariant pitch bases inside the existing contact search, with unchanged order/scoring; aimed at mining-start/retarget hitches. See `FIXES-CPU.md`.
- Companion collision results local to one synchronous path search; subsequent searches and ordinary movement read fresh world state. See `FIXES-CPU.md`.

The neutral/worse inverse-rest prototype is excluded. No speculative old-code deletion is included: deleting unused files is not itself a frame-time improvement.

## Build and verification contract

`.github/fps-fixes/build.py` verifies the exact nine-file DEV15.16 artifact from run36380070907 (source0225855). It verifies all original PCK resource hashes, active task/pet remaps and the current DEV15.14 stance source. It produces baseline and candidate QA packages plus a clean release package without the new QA scripts. Both timing packages share only the fixture additions; baseline gameplay and browser engine are original. The final original-package comparison accounts for the FBO/audio wrapper cost. No depth-prepass override is present.

Local Godot4.7.2 checks passed on the clean candidate: input, premium-core, mole-autonomy, Crusher, state, migration. Full result: `fixes-evidence/core.json`. Twenty-five FBO lifecycle test cases and fifteen audio groups passed. The old protected-invariant entrypoint still fails its pre-existing QA flag documentation assertion; this is not counted as a passing invariant gate. The PCK resource identity checks are separate and pass.

The two Mac WebKit jobs isolate FBO/audio toggles, then compare fresh original/candidate pages in opposite ABBA/BAAB orders. They retain all frame intervals/outliers; actual FBO hits and received music cadence must be observed. They also verify frozen images, exact CPU outputs, companion obstacle replanning, actual held mining, contour motion replay/retarget/cancel, full hero framing, world transitions, pause/resume and resize. No physical-iPhone claim follows from those Mac results.

## Current checkpoint

Both first-set Mac jobs passed 143 checks and exact native/frozen image comparisons. Independent review opened 60 actual PNGs; see `FIXES-INDEPENDENT-REVIEW.md`. All raw first-set reports and intervals are retained under `fixes-evidence/`.

First-set overall rAF FPS: worker1 43.162→44.959, worker2 48.396→47.752. Worker2 mining regressed and slow frames increased. No reliable total-package FPS improvement is established. The contact hoist cost about6% more in both actual-production helper benchmarks and is excluded. The FBO cache had real hits and exact images but no reliable isolated benefit; it is also excluded from the revised release. The companion cache retains exact paths and reduces obstruction collision queries574→457. Music message coalescing retains its measured reduction and explicit reporting-latency limitation.

Revised candidate source `21e415af523d497f6ec37706e42694b7f9c5302b`, workflow `36413947044`, has completed graphical validation on both workers. It starts again from original DEV15.16 and contains private fresh-pose ownership, exact unchanged music-gain suppression, music position-message coalescing and the companion search cache. It does not contain the rejected FBO/contact changes, sync candidate or depth-prepass experiment. The sync wrapper runs only as a read-only separate census and is uninstalled before FPS measurement. See `FIXES-MOTION-V2.md` and `.github/fps-fixes-v2/SYNC.md`.

The revised clean PCK passes six fresh core gameplay/save cases. Both Mac workers pass94 gates each, including exact ownership/alias guards, actual-packet full-state replay with distinct mined resource IDs, both music slots/crossfade directions,21 exact native image comparisons each and ordinary clean startup/save flow. All16 original/candidate FPS windows are retained. Mining improves7.75%/10.37%; overall FPS changes+5.00%/−1.76% and surface remains mixed. The motion CPU benchmark is also mixed; fresh-pose ownership is retained only as verified allocation cleanup. All2900 sync polls were stale; no sync optimization is included. See `FIXES-V2-RESULTS.md` and its independent reviews. This is bounded overhead reduction, not an established complete FPS fix. Public verification is pending; no physical-phone claim.
