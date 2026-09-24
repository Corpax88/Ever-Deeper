# Narrower terrain light bounds — rejected

2026-09-24. Mats authorized autonomous targeted experiments and asks for a phone test only after a strong candidate. Continue without repeated confirmation; do not describe Mac evidence as physical iPhone verification.

Two independent macos-15 WebKit26.5 / Apple GPU runners,2328×1260 actual framebuffer,CSS776×420,DPR3. Same seeded Ember scene, all lights/native resolution retained. Compare original six-cell terrain strips against three-cell and single-cell strips. Same authored draw functions/pass order; changing width invalidates caches. Each run prewarms all variants and waits60s, then measures nine12s stationary windows and nine12s actual mouse-held mining windows. Repeat2 changes the balanced order. Mouse input is real browser input, not proof of physical touch performance.

Both completed284 checks,66 full-image comparisons and18 timing windows. All132 comparisons across two runs were pixel-exact, including four mines, intact/damaged/broken/restored terrain, five upgraded light styles, and moved camera. All eight retained PNGs independently inspected; visuals unchanged. Exported input,125 touch/gameplay checks and DEV save-flavor passed.

| Repeat/workload | Original6 FPS | Width3 FPS | Width1 FPS |
|---|---:|---:|---:|
| 1 stationary |36.77|44.30|44.83|
| 1 mining |36.16|33.77|31.51|
| 2 stationary |59.23|59.00|59.78|
| 2 mining |56.29|54.98|51.17|

These are weighted means, not predicted phone results. Repeat1 has substantial drift (stationary original31.83/29.69/48.82FPS), so its stationary mean cannot prove benefit. Repeat2 stationary is at the60Hz ceiling. Mining is worse for both candidates in both runs; stable repeat2 has approximately54 impacts/window and original p95 21/22/21ms versus width3 23/22/22 and width1 25/26/25. Width3 lowers draw calls178→162 during mining but increases measured section setup/draw CPU~1.22→1.44 seconds per12s window; width1~2.15s. This is a concrete tradeoff, not a reason to chase draw-call counts alone.

Independent critic rejects promotion; retain original width6. No production change, no phone retest, no publication. Do not repeat this unchanged experiment. Next distinct experiment is a QA-only world framebuffer with root HUD at native resolution; it must first establish full-scale composition parity and later pass quality/performance review. No quality reduction is accepted by this handoff.

## Immutable provenance

- Canonical source before study:2245173cb3360ae6eeed5ba66478f69002ce6bba on codex/native-light-dev15-9-20260924; public15.9 export remains c63aabd3e3e5120579285ce6e8b0b59a75f2727a.
- Experiment branch codex/terrain-light-study-20260924; exported PCK source8739b8c438ccbe2c979f6f92f79aad2f7814e067.
- Initial run36054823975 completed import/export and locked native-resource validation, then rejected the HTML because the reused builder pinned15.8 rather than15.9. No gameplay parse failure. Retained candidate10831309877.
- Recovery51f1ae2cba2606b0927c32a4cac6b82cfe1e3710 / run36055342877 succeeded. It reused that exact PCK, verified all other runtime files against published15.9, then updated only HTML's declared PCK size and wrote the manifest. No re-export. Report.source_commit is the recovery/harness commit; build.json records actual export provenance.
- Reviewed candidate10832321824; core/build evidence10832291740; full original screenshots/reports10832696845 (repeat1),10832916404 (repeat2).90-day artifact retention.
- Local evidence /workspace/scratch/41a58a9f2ec4/terrain-light-study. The original builder's old pin is superseded by the recovery finish.py; if doing a genuinely new export, use the explicit15.9 baseline rather than blindly invoking that historical builder.
