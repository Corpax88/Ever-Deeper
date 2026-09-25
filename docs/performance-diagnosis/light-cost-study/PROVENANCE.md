# DEV15.9 lighting cost isolation

2026-09-25. Mats explicitly deprioritizes the companion and asks to locate the expensive lighting/shadow component. This diagnostic leaves the companion and native hero visible and animated, and retains full resolution. It changes light features only in an isolated QA pack; it is not a proposed production quality reduction.

Canonical source cc7cedb161570a29dab3e2480df02ad5d73b1af1, branch codex/native-light-dev15-9-20260924. Baseline exact public15.9 export c63aabd3e3e5120579285ce6e8b0b59a75f2727a, immutable original run36043919958. Experimental branch codex/light-cost-study-20260925, source435898130a7a178878bf9975583ff507f873be1e, run36096144264. Candidate10847004182, build10847363745.

The proven PCK append packager verifies nine original file hashes and all original resource MD5 values.1401 resources remain unchanged, one FPS-fixture remap is replaced, two QA source scripts added. Original compiled fixture remains in the pack but its remap selects the diagnostic source fixture. Native assets, original lighting code, gameplay and save paths are retained. Exported input,125 touch/gameplay checks and DEV save-flavor passed before browser jobs.

Two macos-15 WebKit / Apple GPU runs, CSS776×420,DPR3,2328×1260 framebuffer. Same seeded Ember depth-one durable target and actual held browser mouse mining. Seven modes: instrumented baseline; helper-driven occlusion refresh paused; nearest/hard shadow filtering; shadows disabled; both helmet cones disabled; both helmet bounce lights disabled; all PointLight2D nodes disabled. Node flags/filter and paths are recorded in each result, not inferred from mode labels. Three balanced blocks produce21 ten-second mining windows per runner; repeat2 reverses each block. All modes prewarmed followed by30 seconds baseline and12 seconds held mining warmup. Changed modes settle before each measurement. Require>150 frames and>=20 impacts/window.

Helper runs at original occlusion priority100, disables original automatic processing and calls the unchanged refresh method once per frame, timing only that call. CPU pause mode omits that helper call; it does not change shader filter or disable lights. Frozen baseline, instrumented baseline, paused-update mode and restored light settings must yield exact pixels before performance measurement. Four retained captures per runner: original, hard shadows, no shadows and all lights off. Other altered-light modes are expected to change appearance and are diagnostic only.

## Interpretation limits raised by independent design review

- Refresh timing/counts cover helper calls. They do not intercept arbitrary direct refresh calls. Original occlusion _process simply calls refresh every frame; active Moss world source has no direct occlusion/refresh calls. End rebuild counts still need checking before claiming no geometry updates. Frozen mode is not a safe gameplay optimization: movement/terrain changes can invalidate retained geometry.
- The original occlusion node and helper share priority100. Any transient duplicate call while restoring processing is outside measured warmup windows. Baseline remains instrumented, not an uninstrumented FPS baseline.
- Validate every window's recorded end light states, because mode selection acknowledgement precedes the1.5second settle. Animation must not silently reenable an ablated light or filter.
- GPU timer queries have no final completion drain; pending queries could cross boundaries. Treat GPU telemetry as secondary/inconclusive, even if available. A faster shadow mode alone does not prove an exact GPU/CPU percentage.
- Shadows-off can change occluder coverage and rendering submission together; cones/bounce ablations affect light coverage, shadow work and shading together. Paired differences are not additive independent components.
- Mac WebKit is not physical iPhone Safari. No phone FPS, thermal conclusion, publication or production quality change is established by this test.
