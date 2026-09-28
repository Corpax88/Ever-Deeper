# Overworld idle FPS investigation — 28 September

User reports low FPS in the overworld at Balanced/DPR2 on DEV15.15. Private phone reports remain private and are not copied into this repository. Do not claim a root cause from constant draw/light counts or stable allocation alone, and do not infer thermal throttling from the report.

Canonical gameplay baseline: DEV15.15 source08af3b8526b88ba2764fa36860d52d7e0eba5bbe, immutable skill-level-candidate from run36376489306. Hero15.14 was visually approved by user; skill notifications and graphics settings retained. LIVE1.0.1 must remain unchanged.

## Narrow background isolation

Source78bc90bd14afe97f6980a052d36104fd0d0d3beb on codex/surface-idle-focus-20260928, run36379299476, artifact10951119323. Exact DEV15.15 package, isolated QA changes only. Surface near Ember Fault, DPR2, frozen visual state to isolate continuing rendering. 15-second background-on/off/restored samples in Mac WebKit:

- On:59.53FPS,106 draws.
- Off:59.28FPS,102 draws; two biome backdrops plus the parallax root hidden.
- Restored:59.91FPS,106 draws; PNG restoration byte-identical.

Actual captures inspected. The run is at the display ceiling and does not reproduce the phone slowdown. It neither proves nor excludes a phone background bottleneck. No graphics removal/cropping was accepted or published. Large background rectangles and stage blending remain possible costs, not established root causes. Do not repeat this unchanged Mac comparison or claim a FPS fix.

## Concrete measurement blocker and minimal correction

Existing `LIGHT TEST + REPORT · 3 MIN` explicitly rejected phase `surface`. The probe already records a sustained baseline, pet-lights-off/restored, shadows-off/restored, all-lights-off/restored and a long restoration interval, with report markers and automatic restoration.

The minimal DEV15.16 change admits surface, selects surface_world and labels results SURFACE. Existing duration, cancellation, private-report transport and gameplay are unchanged. The full surface validation exposed a portal writer that re-enabled its light during the all-lights-off stage. The diagnostic now also temporarily hides targeted lights, snapshots/restores their original visibility, and counts enabled visible lights; this avoids changing the portal gameplay writer. Tooltip includes surface. No new diagnostics menu or automatic graphics reduction. This is diagnostic enablement, NOT a proven FPS fix.

Source4e7e7d47d4695da137885fe7b3087e7afc9e3003 on codex/surface-light-probe-20260928. Exact package builder and a full real seven-stage Mac test are under `.github/surface-light-probe/`; publication details follow after verification.

Next unavoidable measurement: user runs the existing opt-in test on the actual phone in the slow overworld area and sends its resulting report. Read latest_report/latest_windows privately, correlate reversible stages against their restorations, then choose the smallest production optimization supported by that result. An unchanged Mac at60FPS cannot establish the phone cause.

Rejected first surface-probe validation: source4e7e7d47d4695da137885fe7b3087e7afc9e3003/run36379629974 completed but correctly failed isolation: one portal light remained enabled during all-lights-off. No candidate published. Corrected source0225855d5b243fadf75c5267898ac2cd6edb3d0b ensures effective visibility override and exact restoration.

## Accepted diagnostic validation
Source 0225855d5b243fadf75c5267898ac2cd6edb3d0b; run 36380070907; candidate artifact 10952875555, digest sha256:06e46692f2224518997516a9c14cfe32a82ef611cafa23da5f503ca585ab8c18. All seven real 180-second Mac WebKit stages passed; effective lights-off count is zero and graphics restore. Original, lights-off and result captures inspected. FPS 56.43, 58.24, 57.14, 59.90, 59.87, 59.86, 59.86 across stages does not establish a cause: restored stages also reach the ceiling. Diagnostic only, not an FPS fix or physical-iPhone verification.

## Published DEV only
Publication commit4061443170b88e37432672c9d32a90be2078ed47, run36380584402 passed. All27 public file hashes verified. LIVE1.0.1 and Worn unchanged. Receipt artifact10952850603; rollback10952850482 preserves DEV15.15. DEV15.16 is diagnostic only. Next: one actual-device surface light test and private report; do not claim root cause before reversible evidence.
