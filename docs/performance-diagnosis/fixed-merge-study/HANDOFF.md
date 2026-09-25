# Fixed-light precomposition — rejected for production

2026-09-25. Source aa3b87ffd79130d0796aed6592d8f6a02f9a6481, branch codex/fixed-merge-study-20260925, run36110170882. Two Mac15 / Apple GPU / WebKit26.5 workers, native2328×1260/DPR3. Each passed118 runtime/workload/restoration checks. The original DEV15.9 package was patched only for QA and the separately audited occupancy revision; no public release.

Two unshadowed fixed lights were baked into one cached PointLight2D texture without changing world materials, masks, actor art or render resolution. Original lights were restored between comparisons. The bake used the existing additive static-light shader and WebGL-safe FlatPolygon2D background. The first uncorrected run36110029575 was cancelled; do not use it as evidence.

Twelve12-second held-mining windows: repeat1 weightedFPS44.8581→44.5982 (−0.58%); repeat2 42.2293→42.8258 (+1.41%). No consistent gain. Keep all slow windows and spikes: baseline770ms and candidate328ms maximum frame gaps occurred. Initialization bake/readback87/114ms was excluded from timing and is an additional production concern, not a demonstrated per-frame cost.

Independent end-snapshot audit verifies every window's mode, active/enabled merged field, identical two fixed-source paths, bounds, normalization and texture dimensions. Four helmet lights retained their original flags. The field was2108×1368 texels, density2, normalization2; the minimum1 followed by ceil(1.01×value) produces2 even for disjoint0.92-energy lamps. This conservatively wastes precision but does not clip this fixture.

Eighteen candidate comparisons across four mines/intact/broken and moved views differ by at most1–2/255 per channel. All18 restored-original comparisons are exact. All12 retained PNGs were independently inspected. Only Ember-intact and moved images were retained; other cases have numeric comparisons, not retained visual review. Workflow success deliberately does not claim candidate pixel identity or general visual acceptance.

Decision: reject further production integration of this prototype. Do not invest in invalidation/readback optimization without new evidence: steady-state FPS does not justify it. Known unimplemented production requirements include source lifecycle tracking, disabled source handling and guards for alternate light properties/materials. No phone test requested. The fixed-off experiment still demonstrates lighting cost; combining lights into a wider field does not prove reduced GPU work.

Artifacts: candidate10853310018, build10851924677, WebKit1 10853275646 (27520012bytes), WebKit2 10852822287 (27475087bytes). Downloaded ZIP byte counts and integrity verified. Raw reports and analysis are retained beside this file; screenshots in90-day CI artifacts. Independent review is independent-review.json. Full source remains on the QA branch and is copied here for reconstruction.

Next distinct investigation is render submission profiling, not another unchanged light merge: branch codex/render-profile-20260925, source525a55be87f6650d0221cf260a51093688628fbd, run36111016427. It reuses fixed-light candidate from run36109186370 and measures CPU wall time inside WebGL calls/rAF, with uninstrumented windows to expose observer overhead. This is not GPU elapsed time. Safari recovery run36110103989 remains pending at this checkpoint.
