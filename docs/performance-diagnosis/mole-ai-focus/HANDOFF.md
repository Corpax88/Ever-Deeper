# Mole AI isolation — 27 September 2026

User explicitly requested AI-only on/off comparison. Public DEV15.11 and LIVE
remain unchanged. QA source c3a03670df135419d1d3dff648fcdf6bcfa3471d,
run36350025804, artifact10942305392. Test branch codex/fps-mining-focus-20260927.
Reuses immutable music-candidate10925867913 (runtime ba396beeed9e587a8dc700edef7b28b79f1095d6).

Mac WebKit26.5 Apple GPU,2328x1260,DPR3. Starfall durable-block held mining.
12s warmup, on/off/on20s measurements, original terrain redraw and audio path.
AI off bypasses companion physics/actions/steering but continues pose drawing
and animation clock. Both pet lights remain visible, enabled, shadowed and at
unchanged energies. Pet position is unchanged in all measured endpoints.
AI off capture inspected; frozen toggle comparison has zero changed channels.

FPS49.092 ->51.630 ->54.461. Improvement continues when AI returns, so the
middle-window improvement cannot be attributed to disabling AI. No reversible
FPS recovery demonstrated. First/last AI-on physics CPU245/211ms per20s;
approximately0.204/0.175ms per physics tick, INCLUDING pose rendering.
Think63calls/window consumed1/4ms total. Path searches ZERO in all windows.
AI-off counters verify no physics/think/move calls and1201pose calls.
Max counters are lifetime maxima, not per-window maxima. Timings include
instrumentation and millisecond quantization; nested costs must not be summed.

Conclusion: ordinary stationary follow AI does not explain a large sustained
FPS loss in this fixture. This does NOT exclude pathfinding, collecting drops,
autonomous digging, unlocked skills, or the physical phone's particular state.
No production AI behavior was changed and no fix is accepted. The toggle is
QA-only, not available at the public DEV address. If phone-specific AI remains
suspect, the next distinct check is the same reversible switch in the actual
slow session (preserve visuals/lights and label the report), or profiling an
identified active task; do not repeat this stationary fixture unchanged.
