# Lighting cost isolation — measured CPU waste, broader bottleneck unresolved

2026-09-25. Mats asks to isolate lighting/shadows and deprioritize the companion. Companion and avatar remain visible and animated in every mode. Two macos-15 Apple GPU / WebKit26.5 runs passed127 checks each and42 held-mining timing windows total. Six exact full-image comparisons passed: instrumented baseline, paused helper-driven refresh and restored light settings on each runner. All eight retained screenshots independently inspected. Every timing window's final light flags/filter matches its intended mode. No GPU timer extension was available.

| Mode | Repeat1 weighted FPS | Repeat2 weighted FPS |
|---|---:|---:|
| Instrumented baseline |50.41|49.74|
| Pause helper-driven occlusion refresh |53.76|50.31|
| Hard shadow filter |51.54|50.95|
| Shadows off |51.30|53.99|
| Helmet cones off |54.54|52.60|
| Helmet bounce lights off |52.69|45.36|
| All PointLight2D off |58.89|50.41|

Each cell contains three10s windows. Preserve all measurements: repeat2 lights-off is35.70/58.04/57.79FPS; its early slow window must not be discarded to claim a guaranteed improvement. Baselines also vary. Several windows demonstrate lighting cost, and changing PCF filtering alone shows only small average gains, but these data cannot prove the main remaining bottleneck or rank components confidently. No GPU-versus-render-submission percentage is established. No-shadows leaks light through terrain; all-off removes intended illumination. Neither is an acceptable visual-preserving solution.

## Concrete measured target

The unchanged occlusion refresh method itself costs approximately0.94 and1.02ms per rendered frame in the two baseline runs. It still costs0.86/1.01ms with all PointLight2D nodes off. Baseline performs44–45 geometry-input rebuilds per10s while the durable mining target remains present. The helper-disabled mode records zero helper refresh calls and zero rebuilds. This is an instrumented function measurement, not a complete CPU profile or physical-iPhone number.

Source explains a plausible avoidable component: the final terrain-signature fallback hashes the entire blocks dictionary every frame, including HP/value data. Its matching solidity fallback only checks blocks.has(cell). Thus damage-only value changes trigger signature rebuilds despite unchanged occupancy. Independent critic accepts this as the strongest actionable result and supports a bounded keys-only signature trial. Any world using _terrain_is_solid, _is_floor or _terrain_draw_fingerprint must retain its existing dependency semantics; a count-only signature would be insufficient for equal-count key replacements. The proposed full keys hash still has O(n) cost and its benefit must be measured.

Next distinct trial: codex/occupancy-study-20260925, e18194eccfb13977dafb9a697bd49c2faf521393 / run36096889341. QA-only flag compares original nested-value hash with occupancy-key hash where solidity only uses key presence. Required actual-image damage/break/restore, mines/styles/movement comparison and repeated mining measurements. No acceptance is implied here.

## Provenance and status

Experiment source435898130a7a178878bf9975583ff507f873be1e, branch codex/light-cost-study-20260925, run36096144264. Candidate10847004182, build10847363745, WebKit1 evidence10847971144, WebKit2 evidence10847897030. Both ZIPs verified by successful extraction; initially incomplete local downloads were resumed to exact artifact sizes17162174/17160345 bytes. Full reports, analysis, source/workflow and original screenshot artifacts retained. See PROVENANCE.md for immutable original pack hash checks, helper ownership limits and measurement design.

Six baseline lights: hero cone/bounce, companion cone/bounce (all four shadowed PCF5), and two unshadowed fixed worklights. Companion artwork/animation was never disabled. Static-light-field baking was not active in this fixture inventory. Cones-off/bounce-off affect both helmet light sources, not the companion renderer. No separate fixed-worklight-only timing mode was measured; contributions are not independently additive.

No production change, publication or phone test. Canonical/public DEV15.9 remains unchanged. Mac evidence does not identify a proven physical-iPhone root cause. Do not repeat the entire unchanged diagnostic merely to accumulate more passing checks.
