# Automatic DEV lighting probe

The physical iPhone Air slowdown remains unresolved. It begins around 30 seconds in the
hub and Mossvein Depth 2. Cleanup audit found no removed active runtime behavior.

## Device flow

DEV TOOLS → AUTO FPS TEST · 2 MIN. Stand still in the hub or Depth 2. The original
configuration runs for 60 seconds, with an early reading after 10 seconds. Then pet lights,
shadows and all world lights are disabled separately for 10 seconds each, with a 10-second
restored interval after each intervention. Seven rows report FPS, browser RAF frequency
and p95. Only each stage's final eight seconds are measured; its first two seconds settle.

The probe preserves every captured light/shadow state and all skill/save values. Completion,
Cancel, focus loss, area/menu changes and scene exit restore the captured properties.
Browser hiding, window changes, context loss and a bounded watchdog also end the test.
No canvas sizing, devicePixelRatio, engine JavaScript, WASM or presentation behavior is
changed. The standard Godot adaptive canvas policy remains 2. The probe is DEV-only.

## Verification and limits

The exact candidate is checked by the existing ten gameplay cases, protected hashes and
both build flavors, then full native and mobile-browser hub/Depth 2 runs. Assertions check
all seven stages, original durations, every restoration, cancellation during all three
interventions, focus handling, actual mobile Cancel input and report bounds. Browser GPU
readback is performed after timing, with buffer dimensions checked during the separate
Cancel trial. Native stage captures and final browser images require visual review.

WebKit in this CI environment emits same-image glBlitFramebuffer warnings even in the
ordinary menu with the original adaptive policy and the diagnostic inactive. A standalone
WebGL framebuffer control runs clean. Omitting screenshots or a context observer did not
remove the warnings. A bundled alternative presentation path removed that warning but
exposed other resize errors; it was not adopted. The engine files remain unchanged.

The proposed resolution intervention was removed after WebGL resize errors. This release
concentrates on the user's pet-light suspicion and on separating lighting from shadow cost.
It is a diagnostic release, not a verified fix for the physical phone.

SwiftShader was too slow at full DPR3 (6–8 seconds per frame) to honor measurement timing.
Browser review uses Chromium with Mesa under Xvfb. The phone's GPU/thermal behavior is not
reproduced or certified by these software-renderer checks.

## Evidence

- Cleanup audit: `docs/performance-diagnosis/cleanup-audit/`.
- Native prototype: run 34223377725, both areas passed all original controls/restorations.
- Screenshot control: 34224072357; context-observer control: 34224795796.
- Ordinary menu/probe/standalone controls: 34225327227.
- Original adaptive-policy menu control: 34227575304; same WebKit warnings persisted.
- Alternative presentation control: 34225846204; not adopted.
- Resize trace: 34226736488; not adopted.

## Reviewed lighting-only candidate

Source: `25216ecf9809914b3b6271fe9b5804620dafa403`, version `0.46.9-dev.5`.
Final QA: [run 34231779653](https://github.com/Corpax88/Ever-Deeper/actions/runs/34231779653).
All five jobs passed, including ten core gameplay cases, 1139 protected-file hashes,
both build flavors and both areas on native and Chromium/Mesa.

Native hub/Depth 2 sequences completed in 120.161926/120.084402 seconds; browser sequences
in 121.463095/122.149355 seconds. Every report has seven rows and restored graphics.
Actual mobile Cancel input passed at CSS 844×390 / DPR3, with the unchanged physical
2532×1170 drawing buffer. Both browser runs recorded zero script or WebGL errors.
The four final result screenshots were inspected and are readable above the companion UI.

All nine candidate files were checked against the manifest in
`.github/dev-render-probe/review.json`. Engine JS/WASM remain byte-identical to DEV4;
only HTML and PCK changed. Candidate artifact: `10058173775`.
The physical phone issue is unresolved; these checks validate the diagnostic sequence.

Publication prepared; DEV deployment and public-file verification pending. LIVE stays 0.46.9.
