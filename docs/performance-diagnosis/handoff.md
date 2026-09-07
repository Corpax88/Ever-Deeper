# Sustained FPS drop investigation — 2026-09-07

Status: FPS diagnosis remains unresolved. Detailed meter published on DEV
v0.46.9-dev.2; LIVE v0.46.9 is byte-identical. See dev-meter.md and
.github/dev-meter/publication-receipt.json. The requested D2 recording has now been analyzed; do not request another idle
recording. User identifies the test device as iPhone Air (called iPhone 17 Air).
Sustained mature-hub control completed; results and next step are below.
No critic or other agents used.

User evidence: Mossvein Depth 2 recording starts near 56 FPS, declines to about
15–16 FPS within seconds, then stays low. Equally choppy without recording.
User separately reports the same drop in the base hub. The second attached
recording remains the Mossvein recording; it does not independently show hub.

## Completed

Added an isolated QA route, repeated walking/idle measurements, node/light/memory
counts, and temporary shadow / cached-draw / hidden-world comparisons. These
changes execute only with --qa-mobile-performance --perf-mossvein; --perf-hub
selects hub. Normal gameplay, artwork, saves and all rendering settings unchanged.
Godot import and the 1,139 protected-file invariant checks passed locally.
Rendered workflow 34157764697 passed on source
1cd9f30ba4cba32fb766546f78fa92ff0d17683c. Artifact 10031609608,
SHA256 ea6d4f22df1ca51ba2aca9280a94ed3e27d4737d695d0531e61d9e8253552892.
Native baseline screenshots inspected for both areas, 844x390.

Same-runner native llvmpipe results (NOT iPhone performance):
- Mossvein walking approximately 14 FPS; shadows off 18; cached world drawing 16.
- Hub walking approximately 28 FPS; shadows off 30; cached world drawing 28.
- Hiding the entire world subtree gives 60 FPS in both; this also hides hero,
  companion and lights, so it does not identify a specific renderer component.
- Lights remain 7 in Mossvein / 9 in hub; object counts plateau. No continuing
  memory growth observed across these short routes. This does not rule out other
  save-dependent or longer-lived leaks.
- Headless Mossvein remains near 60 FPS. Rendering is expensive on the software
  renderer, but the phone's abrupt high-to-low transition is NOT reproduced.

## Invalid comparison and harness caveat

The stage named half_resolution did NOT change actual render resolution: PNGs
remain 844x390. Do not interpret its FPS as evidence about pixel load. Repair this
probe with root Window size control and assert screenshot/viewport dimensions
before using it to choose an optimization. No production resolution change made.
The first run 34157419216 completed measurements but failed its final shell gate
because ripgrep was absent; the second workflow installs it and passed.

## New physical-device evidence — idle test confirmed

User answered yes and supplied ScreenRecording_09-07-2026 22-09-56_1.mp4,
40.97 seconds. Fresh loading screen, Continue Base Hub, enables FPS meter, then
stands still beside Wardrobe. Sampled visible readings: about 50 FPS at recording
16–28 seconds, 43 FPS around 32 seconds, 14.4 FPS with p95 76 ms around 36 seconds.
This is the developed hub (Treasure Chamber 5/5, active workshops), unlike the
fresh automated hub fixture. User movement is NOT required. Companion animations,
lighting, audio and normal background processing are still active.

Earlier native route tests do not reproduce this high-to-low time-dependent
transition and do not match the user's mature save. No root cause confirmed.
Source review found an eight-second location checkpoint and six-second batched
autosave; these timings alone do not explain sustained low FPS. No evidence was
found for a timed FPS cap. Do not claim thermal throttling or a leak as fact.

Next implementation should instrument actual WebGL render dimensions, CPU frame
cost and resource counts over at least 60 seconds in a mature-hub DEV fixture.
Keep persistence/audio active in the diagnostic: prior isolated QA differs from
normal play here. Also repair the resolution probe before interpreting it.
Preserve approved visual appearance; no speculative shadow removal or resolution
downgrade. No more movement/no-recording/idle confirmations needed from Mats.

## D2 recording and sustained control — latest evidence

ScreenRecording_09-07-2026 22-44-03_1.mp4 (64.30 seconds) shows:
- Meter elapsed 10s: 49.9 FPS, p95 22ms, max 23ms, CPU monitor 6ms, physics 1ms.
- Elapsed 22s: 30.3 FPS, p95 53ms, CPU 7ms.
- Elapsed 26s: 15.0 FPS, p95 73ms, CPU 8ms, physics 1ms.
- Elapsed 28s: 14.5 FPS, p95 74ms; elapsed 32s: 13.7 FPS, p95 92ms.
- Canvas 2328x1260, DPR 3, draw calls 140, GPU memory 488 MiB and nodes 703
  remain constant across these readings. Static memory is unavailable, not zero.

Stable counters and a modest CPU-monitor increase narrow investigation toward
rendering/frame scheduling but do not identify GPU timing, thermal throttling,
or rule out allocations invisible to the meter. Last sample also has an iOS
Sleep focus banner; the drop precedes the banner.

New isolated suite: --qa-sustained-hub, scripts/qa/suites/sustained_hub.gd.
All relics/workshops are built; Light Lab and Wardrobe level 4; hero stationary
beside Wardrobe. This approximates visible progression, not the user's exact save.
Persistence/checkpoints run against a disposable save. Audio uses Dummy in CI;
this is native llvmpipe, not Safari/iOS hardware emulation.
Window.size replaces the ineffective DisplayServer-only resize. Actual rendered
image dimensions must equal 2328x1260, then 1164x630, then 2328x1260 or the test
fails. Six 10-second baseline buckets, two at half linear resolution, two restored.
No runtime graphics change, release deployment or claimed FPS fix accompanies it.

### Sustained rendered control result

GitHub Actions 34161550415 succeeded on 87d9254ef64e3eef4b9ad4432cd53008130e6675.
Artifact 10032814382, SHA256 067bb6e928542658bf4e39295dca2df31a4dceac32994069399035b7b49166d9.
Machine-readable results: sustained-hub-native.json.

Actual rendered dimensions passed all three assertions. At full resolution,
steady buckets stayed near 1.70 FPS throughout 60 wall-clock seconds; half linear
resolution gave 6.28–6.37 FPS; restored full resolution returned to about 1.70 FPS.
This ~3.7x sensitivity to a 4x pixel-count change shows this software-rendered
scene is strongly pixel-cost-bound. It does NOT demonstrate the physical iPhone
cause or promise a 3.7x gain on Apple hardware. No high-to-low transition reproduced.
Node counts settle at 651 and draws near 147. Graphics memory is ~483 MiB full,
~465 MiB half, returning to ~483 MiB; no continuing growth observed in these buckets.
The synthetic scene has fewer nodes than the user's 703 and lacks exact outfit,
equipment, companion progress and save history. Physics/simulation advances more
slowly under the overloaded native renderer, so 60 wall-clock seconds are not
necessarily 60 seconds of every game timer. CPU monitor includes native render
waiting and cannot be compared directly with the phone's 6–8ms monitor.

Next: isolate pixel-heavy effects under equal, verified render dimensions before
choosing a DEV-only reversible scaling experiment. Keep native and physical-device
claims separate. No additional user recording requested; LIVE/DEV unchanged.

All three screenshots inspected. World framing is retained at both pixel sizes;
fixture achievement banners and the near-shop interaction overlay differ from
the phone recording. This was diagnostic visual review, not a release approval.
Source and evidence are on codex-sustained-hub-probe; main was not overwritten.
