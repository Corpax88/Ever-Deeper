# DEV15.10 — published and verified

Publication `36119229397` completed package, deploy and verification successfully on25September2026. All27 public file hashes match the pinned result:9 DEV files from the independently reviewed final package,9 unchanged LIVE files and9 unchanged Worn trial files. Receipt artifact10856177342 (1392bytes) downloaded, exact-size and ZIP checked, and its27-file map independently compared with the accepted manifest and preserved baselines.

Play: https://corpax88.github.io/Ever-Deeper/dev/

Exact runtime source remains `ab0c12ff579134e0a092946bd92973e4599a073c` on `codex/canvas-cpu-dev15-10-20260925`, validation36118561266. Publishing commit2cc6fd5a8905f714eb4ef126ec7b0155327a145d onmain carried reviewed metadata only; main's historical runtime source was not overwritten. Canonical game code is the release branch. DEV save identity is unchanged. Rollback artifact10856566595 retains previousDEV15.9.

Two independent Mac Apple/WebKit runs of the exact original package versus the accepted optimization showed11.25% and12.72% higher weightedFPS, with lower slowframe counts inboth. Graphics/lights/native assets/resolution retained; all24windows including the546ms candidate stall are preserved. Final source differs from that comparison only in the version constant and QA expected-version pin. Native/UI lifecycle and pixel parity, final six core cases, ordinary saved-game flow and six actual final screenshots were independently accepted.

This is a verified DEV performance improvement, not a proven physical-iPhone fix or eliminated stutter. Physical phone validation is the remaining external confirmation. No further unchanged tests, re-export or re-publication are needed. All work and known workflows in this task are complete. Width6 remainsproduction; wider/narrower groups and prior rejected GPU/quality experiments must not be silently promoted or repeated unchanged.

The complete evidence and publication receipt are retained beside this file. Earlier pending-publication paragraphs below are historical and superseded.

# DEV15.10 — approved final package, publication running

Exact final source: `ab0c12ff579134e0a092946bd92973e4599a073c` on `codex/canvas-cpu-dev15-10-20260925`. Final validation `36118561266` passed six exported core cases and ordinary WebKit startup/save. All six final screenshots independently inspected; menu footer shows15.10. Independent scores9/9/8/9, publication accepted within the DEV scope. Publisher check-review passed locally against16 pinned files.

Publication commit `2cc6fd5a8905f714eb4ef126ec7b0155327a145d` on main, workflow `36119229397`, is running. Do not call publication complete until its27 public file hash checks pass. Main is the historical publication carrier; its runtime files were deliberately not overwritten. Canonical playable source is the named release branch. Candidate artifact10856366758,268863935bytes; build10856501423,7459bytes; ordinary startup10856560884,14509259bytes. Build/startup ZIP sizes and integrity verified. Publisher downloads/pins the candidate artifact itself.

The final ordinary source differs from comparison candidate4f27644 only in the15.9→15.10 version constant. QA expected-version assertion updated too. GitHub compare proves the four changed paths; native/world/lighting code separately matches94f3302. All original imported resources and engine/assets preserved, except15 explicit source remaps plus appended scripts. Production terrain width remains6. Original-version415 attempt correctly failed the stale QA version pin, then was corrected without weakening the check.

Accepted changes: block membership revisions prevent redundant shadow-geometry scans for damage-only updates; zero-CanvasItem native3D viewport omits its empty2D pass; companion UI shares the existing HUD canvas while retaining its full-rect layout and lifecycle. Graphics, lights, actors and render resolution retained. Source/gameplay, real browser input, native tool/world lifecycle, journal layout, Deepheart hide/restore, actual scene reload and saves were verified.

Performance: exact original package versus complete candidate, two Mac AppleGPU/WebKit workers at2328x1260. Weighted FPS44.7046→49.734(+11.25%) and33.9936→38.3174(+12.72%). Slowframe totals287→217 and545→355. All24 windows retained, including a546ms candidate stall; large order drift and unequal total counter overhead remain disclosed. This is an accepted bounded DEV improvement, not a proven physical-iPhone fix or eliminated stutter. No additional unchanged benchmark repeats are needed.

Wider strip widths12/24 were separately tested with132 exact image pairs and18 windows; width24 lowers setup CPU but only+3.27%/+2.07% totalFPS with mixed tails, so neither is included. Preserve width6 and do not repeat the rejected narrow/wide, fixed-light merge, alpha-hook or framebuffer studies unchanged.

Native Safari Simulator route remains unavailable: last attempt failed before opening the game. Mac emulation is not a phone result. Existing legacy invariant QA-registry documentation mismatch was previously recorded on unchanged baseline; do not relabel it as a new passing invariant gate.

## Earlier checkpoint — historical

# DEV15.10 final candidate — publication pending

Final sourceab0c12ff579134e0a092946bd92973e4599a073c, branchcodex/canvas-cpu-dev15-10-20260925, run36118561266. Same ordinary optimization code as4f27644; only premium_menu version constant changes15.9→15.10. QA visual_capture_driver expected version updated too. First415/run36118341051 correctly failed the oldQAversionassert; no gameplay regression, first log retained. Corrected final source passes all6 exported core cases; ordinary startup/save is completing.

GitHub compare proof binds four changed files vs4f (version constant, QAexpectedversion, append helper, validation workflow). Native/CPU threefiles separately compared against94f3302: unchanged. Original engine/resources/assets preserved;15 explicit remaps and appendedsources, including new version source; allresourceMD5 verified. Original ordinary effects: occupancy revisions replace redundant damage-only shadow scans; empty2Dpass disabled only in a native3Dviewport with zeroCanvasItems; companioncontrols share existingHUD instead of extraCanvasLayer. No lighting/quality/actor/resolution reduction. Productionterrainwidth6 retained; widerstudy rejected for marginal totalbenefit.

Full-package Mac comparison1128d17/run36117283336: +11.25%/+12.72% weightedFPS, slowerframetotals287→217/545→355, all24windows retained, knowncandidate546msstall. Independent reviewer calls this credible boundedDEVimprovement, conditional finalversion/publishergates. Not proven phonefix orstutterremoval. UI122checks/24exactpairs + native184checks/26exactpairs + ordinary finalsave/core evidence support correctness.

Publisher drafted locally atpublisher/. It will preserve exact publicLIVE/Worn, savepreviousDEVrollback, require exactartifacts/manifests/lineage/reviews, and verify all27publichashes. Mustnotpublishbefore finalsiximages inspected and publisherreviewaccepted. StandinguserDEVauthorizationAlltid exists; no newpermissionneeded aftergates. PublicDEV15.9 unchanged atthischeckpoint.
