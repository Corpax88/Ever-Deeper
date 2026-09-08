# Automatic DEV rendering probe

The physical iPhone Air slowdown remains unresolved after DEV4. It starts about 30 seconds
into both hub and Mossvein Depth 2, including stationary play, Safari and home-screen mode.
Cleanup audit found no lost active performance behavior. Software-renderer tests cannot
reproduce the phone's delayed collapse. This tool collects a controlled comparison on the
affected device with one start and one result screenshot; it is not a performance fix.

## User flow

DEV TOOLS → AUTO FPS TEST · 2 MIN, while in the hub or Depth 2. Stand still and leave the app
visible. The original configuration runs for 40 seconds, including an early reading after
10 seconds. Then each intervention runs for 10 seconds and is followed by 10 seconds of
the restored configuration: pet lights off, shadows off, all lights off, half resolution.
Results show engine FPS, independent browser RAF frequency and p95 frame time per stage.
Send one screenshot of the result. The version appears on the result screen.

The first two seconds of each stage settle; only its final eight seconds are measured.
The half-resolution stage halves each canvas dimension, producing one quarter of the
pixels. It is temporary and explicitly labelled. No diagnostic choices are written into
the game save, no art is replaced, and ordinary full-DPR rendering is restored.

## Boundaries and restoration

`scripts/dev/render_probe.gd` owns the opt-in state machine and bounded measurements.
It captures each light's enabled/shadow state and the original native window size.
Between trials it restores light properties; completion, Cancel, focus loss, area/menu
changes and tree exit restore the original configuration. The browser additionally restores
full DPR on window resize, page hiding, context loss and a 150-second watchdog. Resize aborts
the test and restores the current window dimensions, rather than stale old dimensions.
The normal developer toggle and previous FPS meter state return after the test.

Production exports exclude the diagnostic resource as well as the developer menu.
No per-frame JavaScript sampling runs outside the opt-in test; normal resizing is event-driven.
Only the latest report is retained in `window.everDeeperRenderProbeResult`; no telemetry is sent.

## Browser canvas ownership

The DEV candidate's HTML receives `tools/render-probe-browser.js` through
`python3 tools/install-render-probe-shell.py <candidate/index.html>` before its hashes and
review. It uses Godot's documented canvas resize policy 0 to own the canvas dimensions.
At scale 1, canvas width/height equal window CSS dimensions multiplied by the real DPR;
the DPR property itself is never changed. Canvas CSS dimensions stay fixed during the
half-resolution stage. The exact exported WASM/engine JavaScript are not modified.

Reference: [Godot HTML shell configuration](https://docs.godotengine.org/en/stable/tutorials/platform/web/html5_shell_classref.html#canvasresizepolicy).
The docs flag their 4.7 text as potentially outdated, so actual exported-package dimensions
and touch mapping are gates. Plain exports retain Godot's normal adaptive policy; the
diagnostic refuses to start in a web shell that lacks its controller.

## Verification

`.github/workflows/dev-render-probe.yml` builds one candidate and tests its exact PCK.
The ten current gameplay cases, protected hashes and both flavor checks run before rendered
tests. Both hub and Depth 2 run the full 120-second diagnostic natively and in mobile WebKit
at CSS 844×390, DPR3. Assertions verify each independent intervention, every restoration,
early/late timings, resource counts, and cancellation during all four altered configurations.
Additional checks exercise focus cancellation, a real mobile Cancel tap at half resolution,
resize cancellation, and result-panel bounds. Native and browser captures require inspection.

The WebKit test performs no Godot GPU readback. It retains and fails on WebGL errors as
well as script/page errors; previously missed glBlitFramebuffer warnings must not be ignored.
Browser screenshots come from Playwright. Test audio uses Dummy; actual Web Audio was
separately compared during the DEV4 investigation. The ordinary game keeps its usual audio.

## Status

Implementation prepared; package, rendered review and deployment pending. LIVE must remain
byte-identical to 0.46.9. Only an exact reviewed DEV candidate may be published as dev.5.
