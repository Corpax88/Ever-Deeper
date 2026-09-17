# Floor blend pilot results — 2026-09-17

The complete frozen pixel gate passed. Performance remains unmeasured: the first authorized moving triplet stopped because original A did not emit its required completion marker. Candidate B and restored control A2 were never launched. A reporting-only hardening is now prepared for checkpoint; no fresh graphical run has started. The helper is not adopted.

## Immutable tested source

Production was detached DEV11 `8f5680defb9083bbe1e044d39a10612f2186e7f3`, with no tracked changes. Root independently verified the study checkpoint `codex/floor-blend-study-20260917` at `d6c02e618cefc3704c9106107e526251716af271`, tree `52b9d773a5ec0015cca2f4172b0e348a51eea94d`. All ten checkpointed files stayed unchanged through both graphical gates and the attempted timing.

- Controller SHA-256: `086e67bae5bc1072adee5d967c8db27baffd41ea7bd1b69b7ccb2f4a02081df7`
- Pixel fixture SHA-256: `563dcc037d905ac367d158fd2847cebd7199ad888763ebaab44275d9f25954da`
- Timing generator SHA-256: `e3172370da88b55092a9f69fb1bc8f8de2777acba78a205a8542884cc9219cbb`
- Generated moving script SHA-256: `b800ecc5c2bf98377a3f794e451dcef3ec69228417e9360dfdd63cd35978bb53`

## Pixel results

Godot 4.7.2 stable ran via authenticated isolated Xvfb at 1696 × 780 on Mesa llvmpipe (LLVM 20.1.2). The four-state quick gate and the full 22-state matrix both exited 0 and emitted both completion markers. An independent comparison of saved RGBA data confirmed every image pair.

| Gate | Original PNGs | A/B comparisons | A/A2 comparisons | Changed pixels |
| --- | ---: | ---: | ---: | ---: |
| Initial four states | 12 | 4 | 4 | 0 in every comparison |
| Full 22 states | 66 | 22 | 22 | 0 in every comparison |

The full matrix covers normal/changed opaque material, material alpha, actual ancestor/world/self/item/canvas alpha, external shader replacement, transparent target, all five floor families, both seam branches, grazing hero/pet lighting, a real wall strike, fractional camera/zoom, and down/up rebases. Expected candidate activation and fallback were verified from each B state. No-redraw transitions had zero terrain setup delta. The parent/world fades changed 1,289,728 pixels, floor-item alpha changed 15,201 pixels, and canvas alpha changed 1,290,181 pixels relative to the original normal state; those fallback controls were not visually vacuous. Requested floor families and seam branches had visible floor cells. Rebase bands were 11 → 12 → 11.

The real strike changed 110,177 pixels between successive reference states, including geometry and reward output. That figure is a state difference, not damage-only attribution. Fixed camera coverage fixtures occasionally place the hero inside rock; those identical A/B/A2 poses do not constitute gameplay-quality evidence.

Root inspected the four quick B originals and additional full-matrix lighting, strike, zoom and rebase images and accepted extension to one moving triplet. This proves the examined frozen states on this renderer, not an FPS or device benefit.

## Moving attempt: failed completion gate

The one sequential 60-second A/B/A2 attempt began at 06:41:13 UTC. Original A ran the real seed-4608 held-mining route and wrote two 30-second windows, 2,202 raw samples, both moving images, final.png and a functional final session report. Its frame intervals total 60,009.783 ms; it recorded 14,858.065 world units traveled and 4,228 mined resources with persistence enabled. Candidate-active samples were zero, as required for A.

However, both Godot logs contain only startup output. The required `PREMIUM_SESSION_COMPLETE` marker is absent. The wrapper returned 4 at 06:42:27 UTC and the orchestrator stopped immediately. It did not launch B/A2 or repeat A. The existing wrapper does not retain the raw child exit separately on this failure path, so the final report's intended `quit(0)` is not a captured successful process exit.

No source code or launch flag disables stdout, and cgroup OOM counters were zero. The cause of the missing output remains unproved. Complete-looking JSON is retained as provisional evidence and does not waive the failed completion gate. A later, separately authorized logging diagnosis would need raw child exit capture and a reliable completion channel before any fresh timing trial.

A subsequent minimal headless logging probe exited 0 and printed every stdout/stderr marker. Effective settings before Main, after Main, and after real Deep entry were `disable_stdout=false`, `disable_stderr=false`, `Engine.print_to_stdout=true`, and debug `flush_stdout_on_print=true`. No custom feature or project override was active; launch/user arguments were separated correctly and contained no quiet flag. The failure was not reproduced and no concrete logging correction was found. Those headless flags do not establish the failed X11 process’s runtime flags.

There is no measured candidate gain or loss, no valid control comparison, and no 50 FPS claim. Renderer ownership was explicitly released after failure; no pilot source or fallback was changed.

## Reporting hardening prepared after the failure

Root authorized a narrowly scoped change to the timing generator. The original stdout completion print is retained. Immediately after that same final point, after the final image and session report, a separate receipt records actual `Engine.print_to_stdout`, `Engine.print_error_messages`, effective stdout/stderr-disable and flush settings, source hashes, source revision, variant and functional status. A stderr mirror emits the same completion marker with this identity. A matching entry receipt is written before scene setup; neither adds work inside the timed windows.

The existing renderer wrapper still rejects errors, nonzero process exits and missing explicit completion. The generator adds receipt validation after that gate. Duration, functional gameplay, input/counter/raw-sample identity and candidate activation/restoration checks remain required for a complete fresh A/B/A2. The old A is not reused or reclassified.

Only `run_session.py`, this result document and the README change. Controller, observer, production route, production world and pixel fixture are unchanged. This is completion-reporting hardening, not an established causal fix or a timing optimization. The generated GDScript passed headless parsing. A remote checkpoint and renderer grant are still required before a fresh triplet; if reporting fails again, this avenue stops.

## Evidence locations

All logs, state, original PNGs, exact tested tool snapshots and source bindings remain in the session's sibling `evidence/` directory:

- `floor-blend-quick/parity-gate.json`: four-state image hashes and exact comparison audit.
- `floor-blend-full/parity-gate.json`: all 66 image hashes, 44 exact comparisons and state coverage.
- `floor-blend-moving-triplet/execution.json`: single attempt, wrapper status and stop.
- `floor-blend-moving-triplet/failure-analysis.json`: bounded read-only failure analysis and artifact hashes.
- `floor-blend-moving-triplet/A/`: untouched failed-run logs, raw windows/samples, generated script, images and session report.

This results file is a later documentation addition. The hashes above describe the original checkpoint and failed attempt; the reporting-only generator revision is recorded separately in `floor-blend-reporting-parser/harness-generation.json` and its checkpoint manifest.
