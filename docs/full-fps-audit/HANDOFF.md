# Whole-game FPS audit — 28 September 2026

User explicitly authorized three parallel specialists and a bounded deeper investigation across rendering, CPU/gameplay and resources/runtime. LIVE must remain unchanged. Public DEV remains15.16; no optimization from this audit is accepted or published. Private phone reports and derived session details are not copied here.

Strongest concrete candidate found: WebGL masks the GPU name, so Godot's Apple exclusion misses an active native depth prepass. The one-line startup setting `driver/depth_prepass/enable.web=false` removes106,057 extra native triangles/frame with14 exact native image comparisons. Normal Mac cadence improves modestly, but Chromium's separately instrumented query intervals worsen. **Mechanism and bounded image parity are proven; physical-phone root cause and overall performance acceptance are not.** Keep this candidate, not a claimed completed FPS fix.

## Exact baseline and environment

Canonical game source0225855d5b243fadf75c5267898ac2cd6edb3d0b, immutable surface-probe-candidate artifact10952875555/run36380070907. Builders verify all9 baseline file hashes and every original PCK resource digest. First three experiments change only QA entries; the fourth candidate additionally adds the explicitly measured startup override. Never rebuild main's historical runtime. Current ordinary hero15.14, skills notices15.15, music fix and saved graphics settings remain intact.

Mac15 GitHub Actions, actual Apple GPU/WebKit26.5 and Chromium151/ANGLE Metal. Exact Godot4.7.2/Emscripten4.0.20 single-thread bytes. Local shell and authenticated GitHub connector worked; no new credentials or service required. Browser/runtime evidence is not physical-phone performance.

## Completed cap isolation — rejected as FPS fix

Source5def01e8756010627094c22c1ee78b58e7489f0a on codex/frame-pacing-audit-20260928; run36388096341; artifacts10955332342 and10955510234. Two Mac WebKit workers,1552x840/DPR2; actual Godot drawn/process/physics counters AND external rAF. Sixteen windows across surface, hub and Moss, with counterbalanced cap60/0. Source and exact WASM contain a possible main-thread busy-wait cap path, but its existence is not evidence of significant runtime cost.

Surface weighted60→0:59.350→59.309 and56.646→57.867FPS. Moss worsened on both; hub small gains. Physics59.506–60.720ticks/s; actual process=drawn in all16windows. No hidden47-game/60-browser split reproduced. Surface frozen60/0/60 images exactly equal on both workers. Actual surface/hub/Moss captures inspected. No repeatable gain; do not remove cap or claim this was the phone root cause. Keep all outliers (worst96ms).

## Completed transparent backdrop crop — not accepted as FPS fix

Sourcef4a0570abf52219be56567f00884260af895f235 on codex/backdrop-audit-20260928; run36388980502. Artifacts10956010774(WebKit) and10955795817(Chromium). Reversible crop of geometry whose authored shader output alpha is identically zero, preserving texture RID, fade extents and all potentially visible texels. Supported Quality mode/DPR3,2328x1260 throughout both modes.

Six exact restored comparisons per browser; candidate differences max1/255 from rasterization rounding. WebKit original53.455/56.828FPS versus crop55.026/53.400: no reversible gain. Chromium all~60. Optional Chromium GPU-command intervals baseline9.995/10.083ms versus crop9.860ms,241samples each, zero pending/disjoint. Those include command/submission gaps, not pure GPU busy time; not a sustained FPS or phone result. Do not promote this candidate merely for source-level work reduction or repeat unchanged timing to obtain a favorable number.

## Completed native-3D isolation — contribution found, no accepted fix

Source4c9318aa5d40623c1af8b30a72b3b6248bd17d0c on codex/native-gpu-audit-20260928; run36389950349 succeeded. Artifacts10956500683(WebKit) and10956435565(Chromium); .github/native-gpu-audit and its workflow. Exact baseline with QA-only controls. Existing Light2D diagnostics leave native hero3D lighting/shadows and400x400MSAA2X viewport active. Native gear is Ember; the Starforge HUD text is the next upgrade, not equipped gear.

Seven live stages baseline/shadow-off/baseline/atlas2048/baseline/render-off/baseline; pose CPU continues in render-off, last hero texture retained only diagnostically. Actual process/drawn/physics cadence, owner IDs/generation, updates, Light2D signatures and primitive counts recorded. Separate startup/per-mode WebGL framebuffer inventory captures real4096/2048/400 dimensions and submitted work. Tracing wrappers are uninstalled for all normal timing windows. Optional Chromium GPU-command intervals are separately labelled. Four frozen facing comparisons quantify2048 shadow-map appearance and require exact restoration; off-shadow/off-render are not visual candidates.

Actual GL inventory confirms a4096x4096 DEPTH_COMPONENT16 directional shadow texture, with full depth clear every rendered frame. It is independent of the400x400 color target. Changing atlas2048 really reallocates to2048x2048 but leaves106,057 shadow triangles/frame unchanged. There are two shadow draws/frame and four400x400 color-target draws/frame, submitting212,114 triangles in that target. The full-canvas FBO also receives124,069 POINTS/frame, consistent with skinning transform feedback: without rasterizer-discard/transform-feedback state this is NOT evidence that the hero is drawn full-screen. Render-off removes all native400/shadow passes and the POINTS draw, while pose CPU continues. Native per-viewport shadow counts remain stale when disabled; aggregate total primitives fall to2,072. All2D light signatures, owner identities and generation counts remain stable.

| Normal timing mode | WebKit DPR3 FPS | Chromium DPR2 FPS |
| --- | ---: | ---: |
| Baseline | 59.681 | 59.756 |
| Shadow off | 60.002 | 58.345 |
| Restored | 60.005 | 58.849 |
| Atlas2048 | 59.919 | 59.253 |
| Restored | 59.750 | 59.269 |
| Render off | 59.094 | 60.000 |
| Restored | 59.887 | 57.620 |

Separate Chromium GPU-command interval means: baseline9.959ms, shadow-off9.865ms, atlas2048 9.982ms, render-off6.599ms, restored9.701ms. Respectively239/236/234/232/240samples; all zero pending and no disjoint. These query intervals include submission gaps, not pure GPU busy time. The3.10–3.36ms interval reduction supports a native-rendering contribution in this Mac runtime, **not** a proven iPhone FPS cause or a shadow-map-resolution fix. Shadow-off and2048 neither recover repeatable normal FPS nor reduce this diagnostic interval materially. All native-render-off timing from both browsers is retained, including the WebKit non-improvement and lower instrumented Chromium FPS. No selective favorable rerun.

Four atlas2048 facing comparisons/browser restore exactly to4096; candidate differences are not lossless (max54–109/255 across browsers). Parent inspected actual reference/candidate, independent visual review also inspected all four facings and diagnostic modes. The mole occludes much of the hero across these captures; mining/transition poses and temporal shimmer are not covered. Atlas2048 is **not** visually or performance accepted. Off-shadow/off-render are deliberately changed diagnostic presentations and cannot ship as optimizations.

The GPU-MiB overlay remains597.769 in every WebKit native mode despite actual4096-to2048 depth-allocation changes (nominal32-to8MiB). It is not a complete instantaneous GL-allocation inventory. Stable overlay memory alone does not exclude all memory pressure or leaks; this experiment itself does not establish a leak.

## Completed WebGL depth-prepass candidate — image exact, timing mixed

Independent examination of the double400x400 geometry submission identified a distinct startup-only candidate. Exact Godot4.7.2 source enables the depth prepass by default but disables it for GPU vendor names including Apple. Its check uses the masked GL_RENDERER string, and both actual browsers return `WebKit WebGL` despite their Apple/Metal unmasked identity, so that exclusion does not match. The extra pass is now directly confirmed by actual color/depth masks, not guessed from counts.

Source1c3f5c552cff462cb0da74041e85e16762a524ce on codex/depth-prepass-audit-20260928; run36392214186 succeeded, artifacts10956534568(WebKit) and10956559298(Chromium). Exact baseline plus the same QA in both variants. Candidate adds only a PCK-root override.cfg with `rendering/driver/depth_prepass/enable.web=false`, loaded before the renderer caches the flag. Original project.binary and all original runtime resources are preserved. Changing ProjectSettings from GDScript after startup would not test this mechanism.

Counterbalanced fresh launches: WebKit original/off/original; Chromium off/original/off. Each records15s ordinary actual Godot FPS without GL wrappers, plus a separate optional4s command-interval diagnostic. A separate one-second trace requires the native depth-only draw state (color writes off, depth write/test on, GEQUAL, draw buffer NONE) to disappear while the normal color pass writes depth and the4096 shadow pass remains. Seven unobscured400x400 native PNG comparisons cover four idle facings and three samples from the current approved mining-pose bank. No resolution, shadow, mesh, texture, lighting or animation replacement.

All six launch inventories pass the exact GL-state gate. Original has two depth-only plus two color geometry draws/frame in the400x400 MSAA target. Candidate removes the depth-only draws and retains the two color draws, unchanged4096 shadow work,124,069-point skinning,400x400/MSAA2 and all light/pose guards. Removed depth submission is106,057 triangles/frame. Ordinary Godot counters omit this prepass, which explains why normal draw-count telemetry could not identify it.

| Browser / ordered variant | Normal actual FPS | p95 ms | p99 ms | Frames >33ms | Max ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| WebKit original | 57.955 | 23 | 40 | 13 | 86 |
| WebKit off | 59.988 | 18 | 20 | 0 | 25 |
| WebKit original | 58.351 | 19 | 42 | 10 | 74 |
| Chromium off | 59.863 | 18.4 | 22.2 | 2 | 34.5 |
| Chromium original | 58.983 | 19.6 | 31.7 | 6 | 75.9 |
| Chromium off | 60.002 | 18.2 | 19.0 | 1 | 37.7 |

Both browsers use1552x840/DPR2. Actual process=drawn throughout; physics stays near60Hz. Normal cadence/tails favor the candidate in these short windows, not a demonstrated recovery from the phone's sustained slowdown.

**Contrary evidence retained:** Chromium's normal callback means are10.018/10.750ms with prepass off versus7.924ms original. Separate GPU-command query means are10.258/10.026ms off versus8.611ms original (238/236 versus240samples; zero pending/disjoint). Instrumented FPS is59.301/58.691 off versus59.536 original. Those query intervals include CPU submission gaps/frame-cap effects; neither a pure GPU regression nor a GPU saving is established. Do not discard these windows or claim a universal performance win from the normal FPS rows.

All14 candidate pose comparisons and14 same-setting repeat comparisons have **zero changed channels**. Independent review inspected all14 candidate images and both ordinary game captures; parent also inspected idle/mining/game images. All42 native PNGs are nonblank, unobscured and unclipped (at least52px border clearance); each corresponding pose is also byte-identical across browsers. This is bounded visual acceptance for these current Ember idle/mining samples, not an all-tools/moving-device certificate. No animation, material, resolution or shadow downgrade. No publication.

## Decision and exact remaining blocker

No optimization or version change is promoted. Public DEV15.16, LIVE1.0.1 and Worn are untouched. Keep the accepted hero/motion, audio patch and graphics preferences. Source audit and tests eliminated several plausible local candidates but have **not** established one complete cause of the physical-phone slowdown. Do not turn the new native3D observation into a claimed fix or lower mesh/shadow/animation quality without approval.

The strongest targeted next comparison is this exact depth-prepass setting **on the affected phone**, keeping pose CPU,2D lighting, graphics setting and scene constant. It requires fresh renderer startup per variant; a live GDScript setting toggle is invalid. Current public Light2D diagnostics do not provide this control. Do not request another broad gameplay tour or repeat an unchanged Mac matrix. If a DEV-only phone comparison is prepared next, keep its report private, label startup variants accurately and preserve the approved baseline. No LIVE change. Native-render on/off remains a broader diagnostic alternative, not a production fix.

## Other audit findings

No dominant AI/gameplay leak found: inactive worlds disabled, HUD predominantly event-driven, native outfit uniforms equality-guarded. Previous stationary moleAI, audio-message, small-texture-allocation and sync-elision tests were not repeated. Native pose CPU was previously~0.25–0.29ms/call, not native GPU duration. Checkpoints can cause discrete stalls but don't alone explain sustained low cadence. Performance.TIME_PROCESS is a rolling engine maximum, not full-frame CPU mean; it excludes later frame delay and is not a GPU timer.

This investigation does not erase the retained546ms DEV15.10 stall or convert the accepted DEV15.11 audio.play improvement into a sustained FPS claim. The first six new worker reports contain46 total windows (including separate GPU diagnostics), all retained, with maximum intervals20.9–101ms by worker. Their short synthetic windows cannot establish that rare stalls are fixed. The source audit found no recurring portal asset-loading path during idle; portal lighting/rendering remains distinct from loading.

Prior blockers were measurement coverage/ceiling, not missing Mac access. Do not ask the user to reauthorize the already authorized QA routes or recreate accepted assets. Keep results and limitations distinct.

## Durable evidence

[evidence-summary.json](evidence-summary.json) preserves every timing window, actual engine/process/physics counts, interval tails, native state, query health and image differences for all six workers. It includes original report SHA256 values and exact artifact/run/source IDs. Full raw logs/images remain in the linked workflow artifacts; do not infer image acceptance solely from JSON. All data in this folder is synthetic Mac QA, not private phone-session output.

[depth-prepass-evidence.json](depth-prepass-evidence.json) adds all nine timing windows from the final two workers, GL pass states/attachments, image hashes, setting guards and exact report identities. Total audit: eight workers,55 windows; four targeted hypotheses, not a full-game performance certification. Source/visual review and performance interpretation remain separate.

Independent reviews: [mechanism/source](depth-prepass-source.md), [startup loading](depth-prepass-loading.md), [actual image/pass review](depth-prepass-visual-review.md), [timing interpretation and contrary evidence](depth-prepass-performance-review.md). Earlier source notes describe their pre-test state; completed evidence and the hold decision above supersede those proposals.
