# Fixed work-light isolation — completed, candidate work continues

Canonical runtime remains DEV15.9, source export c63aabd3e3e5120579285ce6e8b0b59a75f2727a; latest canonical documentation before this study is eb71d74fa7faebd3a29dff1835633e4e4deca4be. User explicitly asks to continue autonomously until solved, not pause for another 'go'.

QA source ef660efba2f17932069fa7cdd85e354fa2a549aa on codex/fixed-light-study-20260925, run36109186370. The audited world occupancy revision is enabled in every mode. This removes the known full-dictionary CPU hash from the comparison. Four modes retain all world/art/animation/resolution: original six lights, two fixed work lights off, four headlamp lights off, all lights off. Disabled lighting is diagnostic, not an accepted visual change.

Three exported core cases passed. Two macos-15 / Apple GPU / WebKit26.5 workers each passed135 checks and12 ten-second held-mining windows. Viewport2328x1260, CSS776x420, DPR3. Both fixed/headlamp group membership and final enabled states are asserted; full-frame baseline/restoration is exact. Eight original captures were independently inspected. See independent-review.json and raw reports.

| Mode | Worker1 weighted FPS | Worker2 weighted FPS |
| --- | ---: | ---: |
| Six original lights |42.8790|47.1952|
| Two fixed lights off |48.3144|51.7804|
| Four headlamp lights off |49.4447|51.1900|
| All six lights off |51.7930|55.0581|

Fixed-off beats baseline in all six four-mode blocks; differences vary from0.25 to14.30FPS. Aggregate increases are12.68% and9.72%, but substantial drift prevents predicting a phone gain or exact component cost. Keep all windows, including late low baseline/headlamp windows. Headlamps-off also empties occluder coverage, so it includes shadow work as well as shading. GPU timer unavailable. Never describe these desktop tests as physical-iPhone measurements.

Artifacts: candidate10851683931; build10851618927; WebKit1 10852815409 (16870016bytes); WebKit2 10852349006 (16869442bytes). Archives were size-checked and parsed. Original immutable export fromrun36043919958 is verified before source-only patching. No production code or public package change.

## Work continuing in the same authorized task

A bounded cached fixed-light field prototype follows because the diagnostic consistently implicates some fixed-light cost. It preserves ordinary world shading and original lamp sprites, combines only fixed unshadowed flat ADD sources, and records quantization/resampling differences without assuming visual acceptance. QA branch codex/fixed-merge-study-20260925, corrected source aa3b87ffd79130d0796aed6592d8f6a02f9a6481 (uses established WebGL-safe FlatPolygon2D), run36110170882. Earlier fabcf384/run36110029575 was cancelled after that correction; do not use it as accepted final evidence. Performance, visual parity, source-set changes and bake stalls are not yet accepted. No production integration.

Separately, a distinct iPhone Simulator Safari recovery uses simctl openurl and an HTTP fixture command/state bridge, addressing the old attempt that remained on Safari Start Page. Source7a236e5147fa4f12da023fb350ca7660479c622a on codex/safari-fps-20260925, run36110103989. Earlier1cb92f9/run36109531664 cancelled because telemetry could create a default GL context before Godot; corrected bridge waits for live fixture state before inspecting it. Simulator results remain pending and never certify physical phone performance. Native session controls orientation; mining is an explicit synthetic Godot action and is not a touch acceptance test.

Full-scene deferred lighting was inspected but not implemented: D1 already omits floor beneath opaque terrain. Remaining overlapping layers do not justify claiming broad floor overdraw. Per-layer clipping/alpha blending and differing material/mask/cull behavior block a blanket algebraic-equivalence claim. Static light merging likewise requires actual images and timing; the existing hub static_light_field.gd is only an implementation precedent.

Continue to completion or a concrete unavoidable dependency. Do not repeat unchanged matrices, reduce quality, alter the hero/pet, or ask Mats to perform routine environment recovery. Results and pending state must be reconciled before the final handoff.
