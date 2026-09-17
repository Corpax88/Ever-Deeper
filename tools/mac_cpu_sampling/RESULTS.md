# Exact DEV11 Mac CPU sample — completed 17 September 2026

One authorized session completed successfully in [Actions run 35196739519](https://github.com/Corpax88/Ever-Deeper/actions/runs/35196739519), attempt 1. There was no second profile or alternate attach. This establishes a concrete ANGLE/Metal wait path; it does not establish exclusive GPU time or a performance improvement.

## Binding and validation

| Item | Identity or result |
| --- | --- |
| Production source | `8f5680defb9083bbe1e044d39a10612f2186e7f3` |
| Published DEV11 PCK | 221,013,680 bytes; SHA256 `5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9` |
| Preparation commit / tree | `788856517ae8f74b915fee611bbe89d868e1bd43` / `7d6db484dbce9b3ec1727b195bc1536fbc36a84c` |
| Authorized request commit / tree | `d26208de4b7b5b83dd02724b0ded010cfdafdfbd` / `54a102637db4f7b0892e510d2e763dbf224a04ca` |
| Generator SHA256 | `a17802e2e2b7e87536c79defdf8e7e8ced8e9daa1b4015a2b1461a3551d05ba3` |
| Original route SHA256 | `c3a787767ff0dbfc5c13b2d9283ce0ae7b5a1a77d287a1a5c5e49512ef5b9edb` |
| Generated harness SHA256 | `b7e10b813711427a04b1b853082c782c8aba638cbb17c1b17896ac4f5f65ffab` |
| Native Godot binary SHA256 | `c7cccbf8fb143e34e02fd6521e09be2c2b974f0d5db080b19071c9c570718ccf` |
| Artifact | `10486471482`, 2,391,709 bytes |
| Raw ZIP SHA256 | `bc07d4c0a5e3029b4425902f59294d7d1c5d711521a6c87efbda7e326e6c993f` |

Remote preparation/request refs and trees matched independently computed local trees before the request triggered this one run. The downloaded ZIP matched GitHub's digest, all CRCs passed, and every one of the 22 diagnostic-manifest members matched its byte count and SHA256 after closed-file copying. An independent local Python review repeated those checks, regenerated the exact retained harness from the retained original, and reran the original completion/PID/functional/duration/raw-frame validators. Both Godot and sample exited 0. All original logs remain.

Ordinary UID 501 launched Godot PID 1521 (Python parent 1489). Receipts, both `ps` observations and the sample Process header agree. Engine stdout/stderr were enabled; original and mirrored completion markers were present. The game loaded the exact existing PCK from an empty project directory. No production script, shader, art, light, effect, input policy or native v28 hero changed.

## Actual workload and hardware

The seed-4608, depth-12, Deep `held_mining_v1` route ran for **60.026911 seconds**, with 2,071 raw frames spanning 60.023399 seconds, 14,665.396 pixels of travel, 3,909 mined rewards, a persisted 18,508-byte save, zero orphan nodes and released mining input at completion. Its two 30-second windows had 1,131 / 940 frames, 37.677 / 31.328 FPS and p95 38.489 / 49.195 ms. Whole-route throughput was **34.503 FPS**. These are diagnostic-session observations, not unsampled baseline estimates or stable-50 acceptance.

The host was ARM64 macOS 15.7.9 (24G830), with Godot 4.7.2 official and **ANGLE Metal Renderer: Apple Paravirtual device**. The log explicitly reports VM detection and ANGLE `aaebda1c5a40`. Effective rendering thread model was 1; the observed canvas GL submission/wait stacks are on the main thread. The final original 1696×780 PNG was visually inspected: real Deep terrain, native hero, pet, lighting, resources and HUD are present. It was captured after settling at the end; it does not depict the sampling instant or constitute an A/B pixel comparison.

The normal companion and its two lights remained active. Companion path-search counters stayed 0 at both route boundaries, so this route supplies no evidence about expensive companion pathfinding.

## What the sampler measured

`/usr/bin/time -l /usr/bin/sample 1521 10 5 -file sample.txt` ran once. Invocation timestamps were 07:54:06.399112–07:54:18.007959 UTC; monotonic elapsed time was 11.603027 seconds including symbolication. The raw sample header starts at 07:54:06.594 UTC. Requested stack collection was ten seconds with five milliseconds between samples; the main thread actually has **1,179 snapshots**, not a presumed 2,000.

Four disjoint main-thread branches terminate in the same blocking path:

| Raw sample line | Draw / conversion | Metal-wait snapshots |
| --- | --- | ---: |
| 55 | `GL_DrawElementsInstanced` → `preconditionIndexBuffer` | 624 |
| 366 | `GL_DrawArraysInstanced` → `generateIndexBuffer` | 93 |
| 423 | second indexed draw branch → `preconditionIndexBuffer` | 70 |
| 492 | second arrays draw branch → `generateIndexBuffer` | 23 |

All four pass through `BufferPool::allocateNewBuffer` → `CommandQueue::ensureResourceReadyForCPU` → `-[MTLCommandBuffer waitUntilCompleted]` → condition-variable wait. Their **810 / 1,179 = 68.70% main-thread stack occupancy** is the strongest new attribution. This sum excludes nested parents and other threads. It is blocked stack occupancy, not CPU execution share, GPU pass duration, or a claim that removing a particular game owner would recover 68.70% of a frame.

The three named Godot workers and three ANGLE workers were sampled waiting on condition variables. A Metal command-submission dispatch queue had 429 snapshots, including 424 in the IOGPU submission trap. That confirms driver submission activity, not its exclusive GPU cost. Many Godot frames remain unnamed addresses, so the capture cannot assign the indexed branches to terrain versus sprites/UI or identify an exact per-owner draw count. Raw addresses and binary images are retained.

## Perturbation and limits

The sampler/symbolicator itself reports 11.52 seconds wall time, 2.09 user CPU seconds, 0.73 system CPU seconds, 350,470,144 bytes maximum RSS and 162,302,016 bytes peak footprint. This is meaningful overhead. With one sampled run and no unsampled control, no FPS correction or causal before/during/after comparison is justified.

The game log contains 64 warnings: one VM-to-ANGLE message and 63 Dummy-audio sample-playback warnings with backtraces. There are no rejected runtime/parse/GL errors, but warning output can perturb timing and remains part of this exact-PCK diagnostic. `xctrace` availability was recorded; it was never used. No GPU time comes from this CPU sampler. Apple Paravirtual native execution does not establish Safari or physical-iPhone behavior.

The read-only mechanism trace and the smallest distinct app-level hypothesis are in [SOURCE-TRACE.md](SOURCE-TRACE.md). Neither is an adopted optimization.

## Preserved evidence

Local evidence root: `evidence/mac-cpu-sampling-20260917/`. It contains the untouched raw ZIP, run/job/artifact API receipts, original job log, checkpoint/download receipts, extracted original stacks and session PNG/JSONs, and `review-findings.json` with machine-extracted wait ancestors. The diagnostic's own file manifest binds all original diagnostic members. GitHub's artifact expires on 17 October 2026; the closed raw ZIP and supplemental review are ready for durable archival.
