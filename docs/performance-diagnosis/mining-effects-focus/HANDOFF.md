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


## Follow-up exclusions (same authorized test branch)

All following runs reuse the same immutable DEV15.11 export and retain the
original terrain-redraw path throughout measurement. None is accepted for DEV
or LIVE. These are Mac synthetic fixtures, not private phone sessions.

Allocation trace: source106139a6142b3ce96fe7b846b4896a3a0d73e09f,
run36339264655/artifact10938501877. 460 observed RAFs: repeated texImage2D
is a 256x1 RGBA32F texture update (460 calls), not a repeated full-size render
target allocation. Only one texture creation/deletion during observation.
This rejects the proposed repeated large texture allocation mechanism in this
fixture, not every possible engine leak. See allocation-report/allocations.json.

Sync-elision diagnostic: source6674d0282c46329a4dde194c94f7eccaeb5dc550,
run36339583510/artifact10937743750. ABBA FPS52.28/51.39/50.25/47.54.
The QA shim removes exactly two real fence/query pairs per RAF, without clear
FPS recovery. Three frozen pixel comparisons are identical, and the break image
was inspected. Fake signaled-sync tokens are diagnostic only, NOT a proposed
production engine patch. Do not promote or repeat unchanged for a better score.
A prior harness syntax error was corrected before this successful run; it was
not a game failure. See sync-report/sync-counters/sync-pixels.json.

Audio position cadence: sourcec29d0b824bb83a99bd1bc96e7d8c4bd9a75e8712,
run36340030946/artifact10939005465. Processor posts once per incoming audio
quantum, but only with nonempty input; the idle pooled-worklet message-leak
hypothesis is unsupported by source. QA limits reports to at most60Hz per
processor, leaving audio sample playback untouched. Four worklets existed.
ABBA10s message counts8027/1077/1080/7662 (~86% reduction); FPS
59.63/60.00/60.00/60.01. Three frozen pixel comparisons are identical.
Both modes are near the60FPS ceiling: this establishes message reduction, NOT
sustained recovery from the observed FPS problem. No audio-position semantic
acceptance or physical-phone verification is claimed. See audio-report,
audio-counters and audio-pixels.json. Do not promote this QA server rewrite.

Investigation remains unresolved: a specific dominant sustained FPS cause has
not been isolated. Retain negative results; do not relabel a CPU-work saving as
a proven FPS fix. No new release, phone retest request, or broad matrix follows
from these inconclusive results. Any next experiment requires a distinct,
measured mechanism or representative on-device profiling evidence.
