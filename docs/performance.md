# Mobile performance verification

Baseline: production v0.46.8 and complete-source commit
`988d9aeed77a1be27d7daebdb7d03cd4d67e51e2`.

The earlier headless journey measured 55.6–60.1 FPS and then failed its old
256 MiB static-memory assertion (peak 442.1 MiB). That run did not render graphics
and cannot establish iPhone performance. The old assertion remains unchanged.

## Reproduce

```sh
python3 tools/run_performance.py --godot /path/to/Godot --output qa-results/performance --capture
```

Use Godot 4.7.2 and an 844×390 window. The runner isolates saves, uses the dummy
audio driver on test machines, stops on script errors or timeout, and retains
raw logs, per-stage JSON and optional rendered PNGs. `--headless` measures CPU
execution only; its nominal FPS must never be called a rendered result.

The suite exercises all surface biomes and a portal seam, mining in all eight
D1/D2 areas, the hub, Deepheart, The Deep layers 1/12, shops and the companion
journal. Every row includes wall-clock average FPS, p95/p99, worst frame, frames
over 33.34 ms, movement distance, draw calls and memory. Engine CPU monitors are
sampled separately and may retain scene-loading spikes; they are diagnostic,
not a substitute for wall-clock frame timing.

The 60 FPS target flag requires mean >=58 FPS, p95 <=20 ms, and no sampled
frames over 33.34 ms. Completing a capture does not imply that this target passed.
No headless or desktop software renderer result certifies a physical iPhone.

## Candidate changes

- Render the static Light Lab preview once when its level or style changes.
  Its original size, pixels, headlamp, hero and selectable settings remain.
- Compose the companion HUD message before assigning it, avoiding repeated
  intermediate text changes while the final message is unchanged.
- Update shop button theme overrides only when a theme actually changes.
  The metallic action label and all existing item animations remain.

Gameplay, economy, saved-data code, world geometry, artwork, shaders, player
animation and light effects are untouched. `check_invariants.py` still verifies
1,138 unchanged protected files plus the intentional version-only project update; the documented QA registry includes the new suite.

## Physical iPhone acceptance

Still required: test the reported choppy area, continuous mining, each shop,
portal travel and a longer play session on Mats’s iPhone Safari. Device pixel
ratio, GPU, temperature and battery state differ from the automated renderer.

## Measured comparison, 2026-09-07

Same-runner native OpenGL/llvmpipe, 844×390 physical window, 22 stages.
Baseline and candidate use identical graphics settings, audio dummy driver,
scenarios and sample durations. The engine's stretched logical viewport is
1416.364×654.5454; this is not a high-DPI iPhone GPU benchmark.

Light Lab: **12.0 → 17.0 FPS**, frame p95 **88.00 → 61.82 ms** (about 42%
higher throughput, 30% shorter p95). Other scenes are essentially unchanged
within run-to-run variation; the full game is not certified 60 FPS.

All ten current gameplay/source checks passed. Source visuals were inspected
side by side for Light Lab, Tool Forge, Wardrobe, the companion journal and
the surface. GPU memory peaked around 566 MiB; native static memory stayed
under 98 MiB. The old 442 MiB headless static-memory result is not equivalent
to this rendered memory split. Memory remains a physical-device test concern.

Evidence: run 34154067921, tested commit
`8b49747a127720e2c133d9f8b3ccc09e386a897b`, artifact 10030456366, ZIP SHA-256
`22577ffb02f9e4f73e21ea6a07d17ae64f160455031091afd7e07485df100ad8`.
The initial attempt 34153781794 failed because its runner had no audio device;
the explicit dummy audio driver fixed the harness. No game audio was changed.

The DEV-only SHOW FPS button adds a read-only, optional two-second frame meter.
It shows FPS, p95, worst frame and count over 33.34 ms. It stops processing
when hidden, clears its interval on app focus return, and is excluded from LIVE.
Final exact-PCK visual and gameplay verification is recorded separately.
