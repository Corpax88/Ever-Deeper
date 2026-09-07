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

## Next discriminating device check

After a fresh reload, leave the game completely untouched for about 30 seconds.
Does FPS fall while standing still, or only after movement? This separates an
elapsed-time/warm-up trigger from movement activation. Do not claim a memory leak,
thermal throttling, or a fixed iPhone regression without evidence.

If movement is necessary, next compare camera movement, companion movement, and
headlamp turning separately. If time alone triggers it, instrument actual WebGL
render dimensions and long-session frame/CPU/resource counters in DEV. Preserve
approved visual appearance; no speculative shadow removal or resolution downgrade.
