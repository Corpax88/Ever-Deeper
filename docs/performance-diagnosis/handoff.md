# Sustained FPS drop investigation — 2026-09-07

Status: diagnosis only. No runtime fix or deployment. DEV/LIVE remain v0.46.9.
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
