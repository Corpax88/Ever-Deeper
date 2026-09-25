# World-only framebuffer prototype — rejected for promotion

Results collected2026-09-25 after the conversation's wait was interrupted. The external Mac jobs had finished successfully on2026-09-24; no background reasoning or further development continued during the interruption.

Run36059410093, source5325bb94a2fdac599c2f27e8c5bfa076797e27ea on codex/world-scale-study-20260924. Two macos-15 Apple GPU / WebKit26.5 repeats. Each passed61 checks and12 timing windows. Full-resolution composite and restored original were both pixel-exact in both repeats (maximum channel difference0). Actual root2328×1260; reduced world1862×1008. Logical camera/framing and real keyboard movement checks passed. Exported input,125 touch/gameplay checks and DEV save isolation passed. Raw-source QA loading is therefore verified in the actual web runtime.

| Repeat/workload | Original FPS | World80% FPS |
|---|---:|---:|
| 1 stationary |47.62|49.67|
| 1 held mining |39.34|40.13|
| 2 stationary |48.47|48.38|
| 2 held mining |42.66|41.85|

Weighted FPS over three12s windows per cell. Mining had53–55 impacts/window. Candidate mining improvement is approximately+2.0% in repeat1 and-1.9% in repeat2; no repeatable material benefit. Frame-time tails likewise do not establish a consistent win. Variability remains substantial, and lower pixel count alone does not establish net performance gain after the extra rendering/compositing work. This is a rejection of this specific method, not proof that resolution can never help.

Frozen images preserve framing and lighting structure; reduced-world sampling softens world details while root HUD remains sharp. No visual-quality reduction is authorized for production. The absent performance benefit already disqualifies this candidate, regardless of subjective tolerance for softness. No further repetition of the unchanged prototype is warranted.

Decision: do not promote or publish; do not request a phone test. Original DEV15.9 runtime and gameplay source remain unchanged. A strong fix has not been established. Across this session's terrain-strip and world-framebuffer studies:60 timed windows;132 terrain pixel-exact comparisons plus four world-composition/restoration pixel-exact comparisons. Do not present check counts as proof of an iPhone fix.

Original artifacts: world-scale-webkit-1 ID10834625294, world-scale-webkit-2 ID10833897895, candidate10833359013, build10833179253. Full reports retained beside this file; original full-resolution PNGs remain in those90-day artifacts and local world-scale-study/webkit-{1,2}. See PROVENANCE.md for build recovery, exact original PCK reuse and the corrected physical-window size calculation. The prototype remains QA-only and lacks production interruption/scene-exit lifecycle hardening.

Next work must use a distinct, measured hypothesis. The existing phone report shows an all-lights-off benefit but does not isolate GPU lighting from associated CPU/submission cost. Useful next diagnostics would separate lighting/shadow CPU updates from actual GPU rendering work with fixed visual output, and examine render submission plus native avatar/pet costs. Do not repeat rejected narrower strips, floor merging, exact-zero-alpha early-out, or this unchanged shared-world framebuffer prototype. Do not silently lower visual quality. Mats authorizes targeted autonomous testing and wants to be involved only once there is a strong candidate; that preference is not a promise of unattended background work after a turn ends.
