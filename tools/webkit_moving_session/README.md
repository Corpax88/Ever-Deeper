# Exact DEV11 WebKit moving baseline

Authorized by root on 2026-09-17 after reviewing the concrete ownership/metric plan.
One existing-runner session, no production modification or publishing.
The native Mac bounded ANGLE pool finding does not establish a WebKit bottleneck;
see PLAN.md and source-bindings.json for exact ownership evidence.

The workflow runs only on codex/dev11-webkit-moving-study-20260917 and only when
the new REQUEST.json is committed after verified preparation. No manual dispatch
or rerun fallback is configured. Request must name its direct preparation parent.

run.mjs verifies the immutable QA35186932201 candidate identity and all nine files,
then serves them byte-for-byte to Playwright1.62.0 WebKit. Ordinary DEV UI opens
Deep12; real ArrowDown and Space hold for at least60 seconds. Built-in macOS Vision
reads only untimed screenshots to locate buttons; it cannot issue game commands.
The untouched shipped FrameMeter has no JS interval/frames-drawn export or copy
report. The shipped render probe cannot measure normal moving endless play.

The measurement is engine-loop callback cadence, never presented-frame FPS.
Two actual WebGL draw censuses run outside timing, restore original methods, and
stop at the first nonempty engine callback (at most eight callbacks, because the
runner can skip a draw). During timing the observer stores bounded raw timestamps
and callback durations only. No draw wrapper, screenshot, OCR, video, trace,
sample, readback, save extraction or percentile calculation runs in that window.
Normal autosave and audio remain enabled.

Original before/after EVDR saves are read with read-only IndexedDB transactions,
checksum-verified and decoded without constructing Objects. Mining, swings and
descent must increase with an unchanged seed and actual active endless state.
The seed is recorded, not forced to4608. This is a browser baseline, not numerical
cross-platform parity with the native route.

If cadence misses the50Hz/20ms-window budget, at most one ordinary5-second sample
per uniquely owned WebContent/GPU process runs after timing, in a30-second total
extension. PIDs require fresh process identity and library paths inside this
Playwright bundle; ambiguous/denied sampling is retained as unavailable. No
privilege changes, driver flags, alternative attach or second attempt.
Stacks measure occupancy including waits; no exclusive GPU time is inferred.

Validation before checkpoint: node syntax checks; pure observer-forwarding,
draw-restoration and metric-duration tests; actual retained save checksum/decode
checked against Godot's own codec. These are not a graphical or browser run.
Swift/Vision compilation is a runtime capability gate on the actual Mac.

All failures retain logs, action receipts, partial observations and a failure PNG
when available. Success requires the explicit new completion marker, functional
save proof, identity/canvas/input/event gates and successful graceful browser exit.
The ordinary game does not expose native orphan/world-input counters; those native
gates are not claimed. No optional second session is authorized.

Evidence remains in RUNNER_TEMP until the engine/browser has closed. The internal
manifest excludes the still-open runner.log. A separate workflow step hashes every
closed file afterward, before artifact upload. The artifact excludes browser caches
and the already retained exact package; it includes original screenshots and saves.

