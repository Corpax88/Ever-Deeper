# Ever-Deeper round 2 — native hero CPU audit

Date: 2026-09-28. Read-only audit against `1c3f5c552cff462cb0da74041e85e16762a524ce`; no runtime edits, CI dispatch, publication, or new timing claims. Depth-prepass candidate is parked and excluded. README, code-map, AGENTS and verification instructions were inspected.

## Source provenance

The intended baseline is immutable DEV15.16 `surface-probe-candidate`, run 36380070907. Its builder `.github/surface-light-probe/build.py` preserves inherited hero resources and changes menu/probe/QA only. It starts from DEV15.15 source `08af3b8526b88ba2764fa36860d52d7e0eba5bbe`. DEV15.15 `.github/skill-level-up/build.py` starts from DEV15.14 source `4811f56ca5b524980cebe4ded68f3bcfe2389488` and likewise leaves hero resources intact. DEV15.14 `.github/hero-stance/build.py` explicitly installs `.github/hero-stance/runtime_motion.gd` (NOT the stale repo `runtime_motion.gd`), and repo `native_worn_visual.gd` and `player_visual.gd`.

Verified git blob identity:

| File | Runtime ancestor and current audit agree |
|---|---|
| `scripts/player/native_worn/native_rig.gd` | DEV15.9 c63aabd and audit both `de4d434d242ecd8364b01b6c087370ec939de9e4` |
| `scripts/player/native_worn/task_motion.gd` | DEV15.9 c63aabd and audit both `cf191212ed47a767fff7a103382b6a6cea640d47` |
| `scripts/player/native_worn_visual.gd` | DEV15.14 4811f56 and audit both `e9dfbdd19d2bcef84803186311638bd164001901` |
| `.github/hero-stance/runtime_motion.gd` | 4811f56 and audit SHA256 `2f5594057629eb9e15ad5385155da7cecd0aab3a418eb8648a0116eca311f720` |

The parent subsequently downloaded and verified the immutable DEV15.16 PCK SHA256 `ee5a77d6c0b15d84bb1b44c85f1aa777aeb555293e0ba11747a400d6bc9a4d72`, extracting 1427-resource metadata to `baseline/source-manifest.json`. I inspected its actual hero remaps: runtime_motion and native_worn_visual point to their plaintext `.gd`; runtime_motion exactly matches the SHA above. Native rig and task motion still remap to compiled `.gdc`, so their text is established by the unchanged source ancestry, not a decompilation. Do not accidentally patch repo `runtime_motion.gd` and lose DEV15.14 stance changes. Any timing comparison must use original/candidate toggles inside the SAME source-substituted package; separately check visual/output parity against the immutable compiled-original package.

## Priority 1 — remove repeated work from the contact search, preserving its result

Evidence: `scripts/player/native_worn/task_motion.gd`, `plan_contact` lines 173–227. On a cache miss it retains at most 12 contour points then runs 25 heights × 9 swivels × 19 pitches per point: at most **51,300 candidate poses in one synchronous call**. `advance` invokes it for a new swing (lines 277–281) and earned impact (lines 328–337). Unchanged repeated contact can hit the cache, so this is primarily a mining-start/retarget/stutter candidate, not an explanation of idle overworld FPS by itself.

The inner loop constructs `Basis(pitch_axis,pitch)` on every swivel although pitch axis and pitch do not depend on swivel. Hoist the 19 pitch bases to the height loop, preserving the original surface/height/swivel/pitch order and the exact multiplication/scoring. This reduces pitch axis-angle constructions **51,300 → 5,700 per maximal uncached search** (88.9% fewer of that operation, not 88.9% less total CPU). The 9 world-Z swivel bases can be constructed once and reused; current code can construct 2,700 of them per maximal search. The 25 height projections can also be cached because the camera and heights are fixed during a call. `project()` currently rebuilds the camera matrix from metadata on each call (lines 68–71).

Do NOT quantize target position, reduce search candidates, change scores, stop early, or disable contact validation: those can change approved motion. `contact_cache` includes exact target and point-string coordinates. `native_worn_visual._surfaces` also keys exact player position, so walking into a new target can legitimately miss. The fallback path for absent surfaces is cheap; distinguish it in measurements.

Minimal falsifiable experiment: pure old/new `plan_contact` comparison on the actual stance-modified `bank`, for reachable/unreachable contours, four directions and each upgraded tool. Assert identical success, contact_tool, yaw, screen and cache keys; record candidate counts and separate cold/hot call wall time. Then exact PCK A/B/A with actual moving→mining and cancel→retarget input, retaining slow frames. Reject if cold-call time does not decrease or any pose differs. No FPS estimate is supported yet.

## Priority 2 — precompute immutable inverse bind data in bone submission

Evidence: `native_rig._apply` lines 402–412 loops every skeleton bone each frame, reads its name, retrieves rest/imported-rest dictionaries and computes `Transform3D(rest[name]).affine_inverse()` before `set_bone_global_pose`. `task_motion.advance` calls `_apply` on every accepted frame at line 377.

The rest matrices, mapping and skeleton index/name mapping are fixed after configure. Cache an ordered list of animated bone indices/names and each inverse rest matrix during configure; retain the original matrix multiplication order and subtract root exactly as before. This removes **N affine inverses plus repeated skeleton-name queries per rendered frame**, where N is the actual animated bone count, without changing animation frequency, mesh, material or pose. Determine N from the actual PCK; do not infer its count from a source skeleton comment.

Minimal falsifiable experiment: run both calculations on identical saved poses, compare each submitted Transform3D exactly, then instrument only `_apply` with accumulated microseconds/calls (one report per window) and alternate A/B/A. Include idle/walk/turn/mine/impact and root translations after long travel. Render a small set of exact frozen pairs. Reject if no consistent `_apply` saving or any numerical difference. Expected total-FPS upside is unknown and may be small.

Do not claim that N global setters cause N GPU uploads: engine batching has not been measured. A separate later experiment could precompute parent-local matrices and use local bone setters, but it has more engine/hierarchy risk and is not the first candidate.

## Priority 3 — avoid a provably redundant deep pose copy

Evidence: `task_motion._world` lines 254–257 deep-copies a pose solely to add root translation. Its only two callers (302 and 337) pass newly owned poses returned by `rotate_pose`/`aimed`. `rotate_pose` already deep-copies its input at line 168, and `aimed` starts from that fresh result. Thus the extra `_world` deep copy can be removed by translating this owned pose in place while retaining all arithmetic order. The changed/transition snapshots must remain independent.

Work removed: one deep Dictionary copy of all N bone transforms per regular frame, plus a second copy on an impact override. This is an allocation/CPU candidate, not a proven memory leak or significant FPS gain.

Minimal falsifiable experiment: inject identical packet sequences into old/new motion objects with the current stance module, compare `shown`, `older`, transition_source, serials and metrics every frame; confirm bank poses remain byte/value unchanged and no dictionary alias crosses frame history. Render exact frozen states after a cancel, continued swing, fast Comet impact, turn and pause/resume. Reject on any mutation alias or divergent pose. Instrument allocation/time only after parity passes.

## Checked leads that should NOT be promoted

- `native_worn_visual.advance` calls `set_outfit` each frame, but `native_rig.set_outfit` already returns before shader writes when color/recolor is unchanged (240–245). No per-frame material-upload issue established.
- Tool `apply_pose` updates its transform per frame because the tool actually animates. It only computes one constant AXIS inverse unnecessarily; cacheable, but smaller than the candidates above.
- Empty 2D canvas is already suppressed on creation/gear changes (`_refresh_canvas_pass`); do not repeat that prior optimization.
- Native viewport remains 400×400, MSAA 2×, UPDATE_ALWAYS. Idle itself animates with phase `delta/3.6`, so freezing/throttling the viewport changes approved animation and is not lossless.
- Bounded transition fallback can perform up to eight extra full `mix` calls, but it only runs after rigidity failure. Record `bounded_transition_frames` before pursuing; no evidence yet that it is frequent. Do not disable rigidity checks.
- `suspend()` frees rig/motion/equipment; reentry can recreate/hash/reload them. This may explain transition hitches, not constant visible-overworld FPS. No unbounded retained cache was found: surface cache clears at 32, contact cache at 128, loaded tool scenes at gear change. Cache clearing can add misses, but removing bounds without data is not justified.

## Recommendation

Test contact-search hoisting first as a concrete stutter candidate and cached inverse-rest data as a separate steady CPU candidate. Keep the pose-copy candidate third. These are genuinely different from depth prepass/shadow/viewport-off/backdrop-bounds studies and preserve the approved graphical workload. None is yet a measured fix for Mats's 40-FPS physical-phone state.

## QA deliverables for the parent

- `hero-cpu-patches.py`: `transform(text, 'rig'|'contact') -> str`, SHA-guarded inputs named in `EXPECTED`. Keeps original implementations intact and adds default-false toggles `qa_round2_bind_cache` and `qa_round2_contact_hoist`. The contact variant hoists ONLY the 19 pitch bases, not the other possible optimizations; this isolates one cause.
- `hero-cpu-fixture.gd`: appendable QA methods `_round2_hero_modes(owner,bind_cache,contact_hoist,profile=false)`, `_round2_hero_stats(owner)`, `_round2_hero_contact_benchmark(owner,repeats=1)`. Stats compare exact old/cached per-bone matrices for the current pose. Profile flags are false by default; timed CPU windows must enable them identically in both modes.
- Contact benchmark uses the actual stance-modified motion bank and tool geometry, 3 synthetic contour cases, 12 contour points each, cold cache and ABBA order. It compares success/tool/yaw/contact point exactly, including an unreachable case, and restores saved contact state. Keep the intentionally blocking benchmark outside all live FPS windows. This checks contact search math, not gameplay reach or real-phone FPS.
- Python transforms verified and output has no literal escaped indentation. Godot parse check attempted but the shared downloaded executable was still incomplete (99,614,720 bytes with expected ELF section header near 146,414,320); it exited139 before output. Parent was informed to wait for completed extraction, then parse the combined exact QA package. No failed syntax assertion is being hidden and no parser success is claimed here.
