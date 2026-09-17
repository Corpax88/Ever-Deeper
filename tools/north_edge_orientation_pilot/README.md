# Isolated Moss north-edge orientation study

**Prepared, not rendered or visually accepted.** The coordinator owns the
single-renderer schedule; this study has no slot until explicitly granted.
It tests one upside-down straight-strip perspective defect, not short-turn or
pillar completion. Do not broaden it into the rejected compact-corner mapper.

Base runtime: `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
Worktree: `/workspace/scratch/d5437d917805/north-edge-study`.
Branch: `codex/north-edge-orientation-study-20260917`.
Only these three files are added under `tools/north_edge_orientation_pilot/`:
`deep_candidate.gd`, `review.gd`, and this `README.md`. No production file,
scene, asset, import setting or earlier study is changed. Ordinary scenes do
not load the candidate; its switch defaults to false.

## Exact candidate

Production `CaveEdgeAssetDrawer._draw_edge` rotates a north strip by PI. Its
adjoining northeast full corner is upright. This flips the authored cap and
dark face vertically on the real long north run. The candidate substitutes
only `EndlessDescentWorld._draw_permanent_wall_face`, and only when all of
these hold: the study switch is enabled, side is north, the cell is mineable,
and the active texture is exactly `assets/mossvein/cave-edge-loop-v2.png`.
All other calls delegate to the unchanged production implementation. Corner
drawing, eligibility, anchor and full artwork remain completely inherited.

The same full128×128 source region, depth-mod11 seed, negative-X segment
phase, tile64×64 destination, texture filtering and white modulation remain.
The change is rotation0 with scale(-1,1) and destination origin
(-tile/2,-inset), where inset=tile×10/48. Production's PI rotation and
destination(-tile/2,-tile+inset) cover world offsets X[-32,32],
Y[-13.3333,50.6667] relative to the north midpoint. B covers exactly the same
quad. X is still mirrored; only the Y image direction changes. No source
crop, extra clipping, stretch, smaller artwork, leg extraction, replacement
material or topology rewrite is introduced.

The earlier compact-corner Moss result remains rejected. Its full opaque
elbow is about149×148world pixels at tile64 and its open arms extend about
115pixels from the vertex. Reorientation cannot make it fit arbitrary
one-cell stairs or pillars. Corner/edge axis registration also remains open.

## One retained held pose and acceptance pair

The harness enters the ordinary Deep owner with seed4608, depth14,
window_start_depth13, then uses the already reviewed walkable player anchor
(1056,1696), facing down. The actual production camera must be (1056,1808).
The original1696×780 framebuffer, logical content1280×720, native zoom,
camera offsets/limits, geometry, culling and lights are retained. Camera
drag and smoothing are disabled equally for the three frozen captures.
This positioning is explicitly a fixture teleport, not continuous-input
gameplay evidence. The original state is saved alongside the captures.

The target is the genuine generated north run through cells(12..14,27),
ending at corner(16,27) with open sides [north=true,east=true,south=false,
west=false]. The harness derives the west endpoint from this same topology
and rejects a missing or changed run. Both endpoint review rectangles include
the complete corner footprint and adjacent strip. Their framebuffer bounds
are calculated from the actual canvas transform and viewport, never from a
frozen screenshot coordinate. The center strip is approximately native
X505–734,Y279–355 in the retained pose.

Exactly one A/B/A2 triplet is captured as:

- `moss-north-held-A.png`: production path.
- `moss-north-held-B.png`: the one north-edge orientation branch.
- `moss-north-held-A2.png`: restored production path.

Each mode invalidates the actual terrain draw caches. The harness requires
fresh draw callbacks, candidate draws for all three focus cells in B and no
candidate calls in A/A2, unchanged terrain fingerprints, actual matching
camera/culling state, fully visible review regions and the expected native
framebuffer/content size. A/A2 must have zero changed RGBA pixels; B must
change visible pixels. Any failure retains the report and captures already
written and exits nonzero. PNG hashes, source/asset hashes, checkpoint
revision, actual camera and endpoint bounds are recorded. The seal shader's
TIME is locked only in memory equally for A/B/A2, as in the retained smoke,
then restored on exit. No shader file changes.

Inspect all three original images at original resolution, including both
reported endpoints and the full frame. The intended result is an upright cap
and face on the long north band without a new endpoint seam or silhouette
degradation. Reject if it merely trades discontinuities. Exact restoration,
successful import/parser checks and nonzero B pixels are not visual approval.
No performance, physical-device, whole-world, D2 or short-corner claim follows
from this one pose. Preserve the rejected images if it fails; no broad matrix.

Reusable retained reference and its real state:

`/workspace/scratch/d5437d917805/evidence/corner-compact-smoke-moss/generated-convex-A.png`

`/workspace/scratch/d5437d917805/evidence/corner-compact-smoke-moss/generated-convex-state.json`

## Commands only after remote checkpoint and renderer grant

First the coordinator must preserve the source and exact commit/tree identity
remotely. Then import/parser checking may run in this isolated worktree.
Do not start either the import or the actual pair while another agent owns
the renderer slot. Use the approved local Godot4.7.2 runtime and the ordinary
isolated rendered runner; it separates startup user data as well as the
harness save. A parser check is preparation, not visual verification.

```sh
NORTH_EDGE_STUDY_REVISION=$(git rev-parse HEAD)
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260917/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/d5437d917805/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/d5437d917805/north-edge-study \
  --output /workspace/scratch/d5437d917805/evidence/north-edge-orientation-moss \
  --resolution 1696x780 --timeout 180 \
  --completion-marker NORTH_EDGE_ORIENTATION_REVIEW_COMPLETE \
  -- --script res://tools/north_edge_orientation_pilot/review.gd \
  -- --output=/workspace/scratch/d5437d917805/evidence/north-edge-orientation-moss \
  --source-revision="$NORTH_EDGE_STUDY_REVISION"
```

The harness has no area, depth, matrix or excavation flags. It runs only the
one named held pose. The coordinator independently reviews the originals
before considering any further action or production adoption.
