# Exact-zero light early-out — isolated experiment

Source branch codex/zero-light-study-20260924, experiment246a358dda80fbe8dd7d5150bfa4ba534d01e4aa, run36050986108. Based on canonical source15839d317092e02644fcd4d3b14898c233794f0a and exact existing public DEV15.9 exportc63aabd3e3e5120579285ce6e8b0b59a75f2727a. Candidate artifact10827118862 from36043919958 is reused with all nine public file hashes pinned. No re-export, no gameplay change, no production publication.

Physical15.9 result: sustained47.87FPS original and47.86 restored,59.99 all lights off; no lasting improvement from the prior native shader change. The next hypothesis is avoiding shadow/filter/normal/blend work for an exactly transparent positional-light sample.

Browser-only QA interceptor recognizes one exact Godot GLES3 positional-light texture sample and complete shadow alpha handling. It inserts a uniform-controlled continue only when sampled alpha equals exactly zero. No epsilon; custom light code and LIGHT_ONLY are excluded. Uniform defaults to false. Remaining default loop only transformsRGB, preserves light alpha, scales shadow alpha by light alpha, then adds/subtracts RGB*alpha or mixes with alpha: all contribute zero when alpha0, assuming finite normal rendering inputs. No loop state other than pixel color is changed. Approved visible pixels, light sources, shadows and resolution must remain equal.

The hook is an experiment, not a general engine patch: engine/WASM and manifest are pinned; unique source guards fail closed. First actual patched shader source is retained in the original artifact for inspection. Shader-stage identities need final binding before any production use. Program uniform locations are cached; records invalidated on relink; mode switches update currently bound program without changing binding. Context restoration uses newprogram records. Do not promote a brittle unverified browser hook solely from source reasoning.

Mac Metal test: same existing QA fixture stays in public15.9 native terrain mode throughout. Only the new uniform toggles for22 A/B/A frozen cases and six12s held-mining windows after20s warm-up. Four biomes intact/damaged/broken/restored, five stress lamp styles and movement. GPU query data is auxiliary; real frame times and exact restored controls matter. Separate untouched-engine timing would be required before promotion if the experiment looks beneficial, because uniformfalse is instrumented control, not the unmodified compiled shader. Mac data is not physical-iPhone performance.

Current state: rejected for promotion. No newly published DEV version. Keep full report private; this record contains only aggregate findings.

## Completed result — do not publish this experiment

Run36050986108 passed54existing checks plus4shader-activation checks.22 A/B/A cases were pixel-exact:0 changed channels,maxdifference0. All four biome activation snapshots report5matched/5patched shader sources,3activeprograms; final mode returnsfalse. These counts establish observed coverage,not a productionapproved shader-hash catalog. Camera movement and53–54 impacts per timing window passed.2532x1170,DPR3,Apple Paravirtual/Metal;220drawcalls in everywindow.

Six12s windows: A44.7695,B55.3685,B53.0721,A57.5396,B57.9208,A58.8587FPS. Aggregate53.7071→55.4407FPS (+3.23%) is not a repeatable gain: firstA had647.2ms outlier and38.1ms p95,while laterA windows average58.1991FPS withp9525.1/21.6ms. Candidatep9528.2/29.2/23.3ms. Large ordering drift makes causal interpretation inappropriate; the test fails the consistency gate. Do not call the method categorically slower from this run either.

GPU1355samples,zero disjoint; mean4.4710→4.3223ms,median5.2167→5.1478ms,also insufficient evidence of a worthwhile overall gain. EngineCPU monitor is not reliable per-frameCPU evidence here. No extra unhookedbaseline run or physical-phone request is justified after this screeningfailure.

Artifacts: originals10830877413 (includes exactpatched GLSL and allfullscreenshots); compact10830612560. Localzero-light-study/evidence containsfullreport andsixcontact sheets. Reused contact labels say native shader, but rightcolumn means this experiment's zero-alpha early-out; both modes use public15.9 native terrain. All22 zero-diff numbers come from decoded originalfullRGBAimages,notdownsampledsheets.

PublicDEV15.9 remains unchanged. Next research should examine reusing stationary light/shadow work with correct invalidation for camera,emitters,style and terrain changes,or a substantially different lighting architecture; feasibility and exact visual parity are not established. Do not automatically repeat this hook, rejectedfloor merging,or another marginal Mac-only release.
