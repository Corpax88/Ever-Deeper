# Device follow-up after DEV 0.46.9-dev.4

User confirms the same delayed FPS collapse in both home-screen launch and direct Safari. Do not repeat that comparison. Screenshot IMG_1734.jpeg shows 32 seconds, 19.4 FPS, p95 53 ms, CPU monitor 8 ms, physics 1 ms, canvas 2328x1260, DPR3, 140 draw calls, 488 MiB video memory and 703 nodes. This is a user report of dev.4, not a screenshot-verifiable version string.

Teamwork fix remains valid but does not solve the device issue. Do not label the iPhone FPS issue fixed. DEV remains 0.46.9-dev.4, LIVE unchanged.

## Filled test gap: real browser audio

Previous native and WebKit tests selected the Dummy audio driver. The new test downloads the exact reviewed/published dev.4 artifact from run 34198922230 and runs mobile WebKit with actual Web Audio, then Dummy on the same runner. Browser context is unlocked with a real test-button click; instrumentation observes AudioContext time and buffer-source starts. No runtime or production files changed.

Run 34201509210 passed both measurement steps. Real audio: two source starts, running context observed beyond 30 seconds, final context time 71.93 seconds. After startup, hub requestAnimationFrame frequency stays about 4.0–4.38 FPS; final hub meter 4.355 FPS. Dummy: zero audio contexts/starts, hub about 4.40–4.48 FPS; final meter 4.497 FPS. There is no abrupt decline near 30 seconds in either trace. Later frequency reductions coincide with the scripted switch to Depth 2, not stationary hub degradation. These software-renderer rates cannot be compared with the physical phone.

This does not eliminate device-specific audio behavior, but the actual browser audio path no longer remains wholly untested.

## Test limitations exposed

The first audio attempt (34201095250) correctly failed because a JavaScript error occurred after METER_REVIEW_OK and engine quit: GodotAudio.ctx.currentTime accessed after audio teardown. The second harness explicitly retains this as a post-completion shutdown error, while continuing to fail on errors during the measurement. It does not suppress the message or claim error-free shutdown.

Both audio and Dummy produce 16 WebGL INVALID_OPERATION glBlitFramebuffer messages (read/write same image). The older dev.4 Dummy release check also contains these messages. They were not included by the earlier SCRIPT ERROR/pageerror-only gate. Their origin (capture/readback, test environment or ordinary rendering) is not isolated; do not infer they reproduce the user's phone failure. The new harness retains them separately. A passed audio comparison does not certify clean WebGL rendering.

## Next targeted diagnostic

Device-only delayed slowdown remains unresolved. The useful next diagnostic is a DEV-only automatic, reversible rendering ablation started after the slowdown: baseline, pet lights off, restored, all shadows off, restored, reduced render pixel count, restored. Capture browser RAF as well as engine timings, exact canvas dimensions and stage labels. Restore all settings on completion/cancel and never write diagnostic choices into the save. Desktop lighting/pixel-cost ablations were already done; repeating those alone will not explain the phone's delay. User should need one start and one result screenshot, rather than many manual toggles. No new mobile test is requested yet because that diagnostic is not implemented.
