# Mining-only terrain redraw: measured waste, not an accepted FPS fix

27 September 2026. LIVE and public DEV15.11 are unchanged. No jobs remain pending
for this bounded investigation. The user's authorization covers this test branch
and Mac execution; do not ask again for the same operations. Private phone report
payloads and derived session details are excluded from this public checkpoint.

## Source and result

Baseline runtime ba396beeed9e587a8dc700edef7b28b79f1095d6, immutable music-candidate
10925867913 from run36303234754. Preserve its JS long-music PCM sharing patch.
Main/publication commits are not the canonical runtime source.

Profile source17c742a61a831df1ef4b2496e222b5ebbc1a6af0/run36338574574,
artifact10938530438. Mac WebKit26.5 Apple GPU,2328x1260/DPR3; four10s windows,
idle/mining/mining/idle. Actual native hero, lights and held mining were retained.
Full-image start capture inspected. Terrain setup consumed approximately92–94ms
per second during mining, while native presentation and shadow-helper CPU were
much smaller. Lifetime max counters include startup and are NOT window stalls.
Timing is quantized and instrumented; this is not an exclusive whole-engine CPU
profile, GPU duration or physical-phone result.

Cause of this specific avoidable cost: animated impacts/drops called the world
redraw request, repeatedly recomputing all visible terrain-strip fingerprints
and section configuration even when only an effect age changed.

Candidate a85bb446ac10f93d46164f18ad80cfbb0fa17a98/run36338815907,
artifact10938098773. Two runtime files change: mossvein_mine.gd directs effect-only
updates to lit_draw_sections.gd's existing dynamic pool. Camera/terrain/gameplay
invalidations retain the full redraw path; removing impacts invalidates the
section list. The cache_dynamic_redraws switch retains the original comparison
path, including original impact-removal invalidation behavior when false.

Four10s held-mining windows reference/candidate/candidate/reference. Setup CPU
91.70→28.89ms/s (~68.5% lower); four frozen comparisons (effect age update,
damage,break,restore) have exactly zero changed channels. Candidate effect image
inspected at original resolution. Same light/shadow/actor/resolution settings.
This is a small, concrete CPU-work reduction, not a demonstrated FPS solution.

Weighted total FPS58.96→56.91; slow frames3→15; worst frame80→71ms. All four
windows retained. Order/drift and one Mac prohibit a confident regression estimate,
but these results do NOT support a sustained FPS improvement or promotion.
Do not publish, request a phone retest, or repeat this unchanged test to obtain a
favorable number. Code remains an isolated experimental candidate.

## Scope still open

The complete persistent phone FPS cause is NOT established. The demonstrated
terrain-setup waste is insufficient to explain it. Lighting/render submission
remains an investigation lead, not a proven exact cause. Existing earlier
light-off experiments likewise did not distinguish GPU work from submission.
No blanket graphics/resolution/light reduction is authorized.

Current evidence does not justify calling this task's FPS goal complete.
If work continues, require a distinct measured mechanism; preserve this failed
FPS screen and reuse existing accepted package rather than a broad test matrix.
