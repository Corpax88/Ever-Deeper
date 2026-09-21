# DEV14.2 steering and render cost

Game source: bee888fe36d6b8285e1198384d40694d3154956a. The preceding 9810c4c9 implements the gameplay/render changes; bee888 aligns the test version assertion. Candidate run35616856586.

Continuous touch corrections restarted each turn at age0. The previous pose then remained in world space while the viewport followed movement, causing rectangular clipping and complete disappearance. Preserve an unfinished turn deadline and keep retargeting its destination. Action changes retain their existing transition behavior. No new animation assets or curves.

Build-time indexed LOD2 derives from the hash-bound approved mesh. Selected positions, normals, tangents, UVs, bone indices and weights are byte-for-byte preserved. Skeleton, skin, transforms, materials and animation remain unchanged. Vertices1,033,415→124,069; triangles1,017,723→86,653. This is a measured rendering optimization of the same hero. The receipt explicitly marks geometry as derived rather than identical.

Native diagnostic runs used the exact published DEV14.1 PCK, with the updated motion script substituted for the fixed comparison.72 steering samples:24 fully empty before,0 clipped after, minimum viewport margin55px.36 paired geometry poses:minimum silhouette IoU99.688%. Independent critic found no visible fidelity regression in inspected ordered/full-resolution frames. These are native rendered sequences, not continuous-video or physical-iPhone certification.

Exported input,1255 gameplay checks,125 touch checks and DEV/save-flavor pass. Known protected-file differences remain project.godot,hero_gear.gd,player_controller.gd and player_visual.gd; invariant status is not clean. Initial run35616450072 stopped because the QA version assertion still expected14.1; this was corrected before the passing candidate run.

Final browser and publication results are recorded separately and remain required. Physical iPhone FPS and the earlier New Game crash are not certified by the Mac tests. The other visual quality observations in the user's video are not declared resolved by these fixes.

Final exported run35616856586 passed both jobs. Chromium/ANGLE Metal at844x390 DPR3:22 screenshots,72 continuous steering samples without clipping(min35px margin),equipment/world/touch/pause/resume checks. Eight15-second rendering windows measured53.60–59.76 browser animation frames/s, with native updates advancing and about176,500–176,800 total rendered primitives/frame. This measures Mac browser cadence, not physical iPhone presentation. Normal Mac WebKit New Game and saved-run replacement passed with6 screenshots.

Independent critic accepted this narrow DEV release after final Chromium/WebKit screenshots and publisher review. Window averages exceed50rAF FPS on Mac; individual stalls reach400ms and physical iPhone FPS remain unverified. Publication uses the exact candidate artifact10646730333 from run35616856586, digest5fe8eee6a1a2fa004e184ee2c36707d4cfa9e43a3b3c60030105cbc8943b7a90. The previous DEV14.1, LIVE and retained Worn trial manifests are pinned. Confirm the new publication receipt before marking the rollout complete.
