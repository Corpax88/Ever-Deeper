# Native depth-one lighting shader — candidate study

Based on public DEV15.8 source2ae03c75e2c7a9b4473f6e08a917ee9f2ffb57c2. Physical iPhone report showed47.83FPS original,59.94 all lights off,48.18 restored; petlights/shadows off individually50.9. Full private report stays in the private receiver.

One candidate only: stop forcing the exact-zero-alpha discard ShaderMaterial onto standard depth-one terrain. Native transparent blending produces the same visible result; the shared owner retains the previous default for all other worlds. Assets, light definitions, shadows, draw partitioning/caching, resolution and saves are unchanged. Runtime owners: scripts/lighting/lit_draw_sections.gd and scripts/world/mossvein_mine.gd.

This follows the older documented observation that discard could lose more than it saves; that history is a reason to test, not proof of current Apple improvement. Official Godot GLES3 canvas shader source explains that lighting loops follow fragment work; no custom engine/WebGL shader patch is used. Reference: https://github.com/godotengine/godot/blob/master/drivers/gles3/shaders/canvas.glsl .

Source c63aabd3e3e5120579285ce6e8b0b59a75f2727a, run36043919958. Prior e98714 export attempt superseded by QA-only clearing stress preview parameters before ordinary timings. Published DEV15.9. Publication commit57c22c4f1d6ce5a24bbaa897995d013c80623071, run36045901828 passed package/deploy/verify. All27 public hashes verified:DEV9,LIVE9,Worn9; LIVE/Worn unchanged. Receipt artifact10828806004; DEV15.8 rollback10827904871.

QA: same exported package, cache always on, only discard flag toggled. Four depth-one biomes, intact/damaged/broken/restored terrain, all five light styles at stress range/energy, camera movement. Exact restored control required; candidate per-channel difference<=1/255 required. Original PNGs retained. Held mining uses one shared durable target and six12s A/B/B/A/B/A windows after20s warm-up. GPU extension, when supported, measures GPU command interval from first draw to RAF callback end, not hardware-wide GPU load or phone FPS; disjoint samples invalidate it. Normal frame time remains a separate measure.

Acceptance pending repeatable measured benefit, current-package visual critic, exported input/touch/save-flavor, light report recovery and ordinary WebKit startup. Existing check_invariants.py QA registry/documentation mismatch remains known. DEV15.8 stays public until all acceptance gates and a deliberate DEV-only publisher complete.

## Accepted measured result

Run36043919958 passed all build/browser steps. All22 A/B/A image cases were exactly equal (zero changed channels), including restoration. Native21 files unchanged, input/touch125 checks/save flavor passed,24 WebKit light/report checks and ordinary WebKit startup/save passed. Existing tools/check_invariants.py failed its historical QA flag documentation assertion; workflow labels its continue-on-error step success, so do not call this invariant passed.

Mac Apple Paravirtual/Metal,2532x1170 DPR3: reference windows55.606/53.949/53.855FPS; candidate57.403/57.810/56.842. Weighted54.467001→57.351904FPS (+5.30%). Candidate p95 25.1–25.5ms vs reference26.8–30.4ms. Slow frames>33.333ms66→46 across three windows each. All windows220 draw calls and54–55 actual impacts. One shared scene, alternating A/B/B/A/B/A; all candidate window FPS beat all reference window FPS. This is a bounded local improvement, not an independently replicated phone result.

GPU timer available,1396 samples,zero disjoint. Aggregate mean4.412610→4.279654ms, median5.176291→5.222166ms; first reference median2.60 differs strongly from later windows. GPU interval result is inconclusive: do not claim a proven GPU reduction. Engine CPU process monitor values are noisy and not used for acceptance.

Independent critic accepted code9/10,visual preservation9/10,DEV validation readiness8/10 after all six contact sheets, full Ember A/B and WebKit captures. Publisher independently accepted after review;13 pinned files, all9 candidate files,27 public final hashes. Physical iPhone performance,thermal behavior and stable60FPS remain unverified.

Artifacts: candidate10827118862; build10827353775; full browser10827893905; compact evidence10827974061. Export source c63aabd3e3e5120579285ce6e8b0b59a75f2727a is immutable; later commits only update documentation/publication. No re-export needed.

Next: on DEV15.9 run LIGHT TEST + REPORT in same Emberdeep depth1,stand still3minutes,SEND REPORT. Read the private report directly and compare settled original/restored phases against15.8 physical baseline47.83/48.18FPS at2328x1260DPR3. Different scenes/canvas/thermal conditions limit direct comparisons. No manual JSON upload needed.
