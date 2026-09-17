# Isolated Moss north-edge orientation study

**Held pilot rendered; independently approved for the affected-state matrix.**
The seven-case extension below is prepared, not rendered or visually accepted.
The coordinator owns the single-renderer schedule. This study tests an
upside-down straight-strip perspective defect, not short-turn or pillar
completion. Do not broaden it into the rejected compact-corner mapper.

Base runtime: `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
Worktree: `/workspace/scratch/d5437d917805/north-edge-study`.
Branch: `codex/north-edge-orientation-study-20260917`.
The original three files are `deep_candidate.gd`, `review.gd`, and this
`README.md`. The opt-in extension adds `affected_review.gd` and
`retained_held_evidence.json`; candidate and original held harness remain
byte-identical. No production file, scene, asset, import setting or earlier
study is changed. Ordinary scenes do not load the candidate; its switch
defaults to false.

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

The original harness has no area, depth, matrix or excavation flags. It runs
only the one named held pose. Do not rerun it for the extension below.

## Seven-case affected-state extension

The retained pilot ran checkpoint
`0e53f74983681d85954cfe799a712bf5b3f0c1bc`, tree
`69fbde0828c8d8100360b66298a37e3a66a09c93`. A/A2 have identical PNG bytes and
zero changed RGBA pixels. B changes53137pixels; the long strip reads upright,
but the existing stepped/full-elbow endpoints remain. Root and the independent
release critic approved proceeding to this matrix, not production adoption.

`retained_held_evidence.json` preserves the original PNG/report/save hashes,
19protected source/asset hashes, and one fully visible changed cell for every
source phase0–7. The new harness verifies those hashes and recomputes the
eight recorded pixel counts from the actual old originals. It does not render
the old pose again. The phase counts are respectively4766,3767,5289,398,5037,
5014,4734,4818; these are inset source-quad pixel counts, not draw-call claims.

Exactly seven new A/B/A2 cases produce21full native PNGs:

| Case | Required actual state |
|---|---|
| `approach` | Start on verified floor at(864,1632), then six real controller/resolver ticks toward cell(13,27), retaining clearance before contact. |
| `contact-strong` | Continue40controller ticks; require blocked motion at the native23px collision radius. Apply an explicitly labelled isolated Light Lab level5loadout fixture, through the unchanged production headlamp settings. |
| `struck` | The held-mining clock must select that exact wall, apply a real hit, and retain it with increased damage. No HP or terrain edits. |
| `mined-opening` | Continue the actual committed mining clock until the cell becomes floor; require the newly revealed north edge at(13,28). |
| `short-steps-grazing` | Retain the real stair at(16,27),(17,28),(18,29), face right from clear floor at(864,1696), and verify the target ray lies0.25–0.52radians off the native headlamp axis. This keeps the level5loadout and tests two actual changed stair cells. |
| `boundary-13-14` | Restore the ordinary native entrance corridor on the Moss side of the Voidstar/Moss boundary. Require a visible affected Moss north edge and both sides of the actual seam. |
| `boundary-14-15` | Restore the native exit corridor on the Moss side of the Moss/Rootwound boundary with the same gates. |

The original normal-light held evidence is reused. The strong cases use real
level5energy/range multipliers1.3/1.4; fixture workshop/relic records are saved
and restored before boundary cases. This is a loadout fixture, not a purchase
or progression test. No lamp, shadow, material or candidate drawing code is
changed. The normal camera owner settles its own framing before each case;
no viewport, camera offset, zoom or limit is invented. Corridor placements
are labelled fixture teleports, not traversal/rebase claims. Every placement
and every controller step must remain collision-free.

Each case forces fresh terrain draws, freezes actual light/camera/game state
equally across A/B/A2, preserves the state save and original full PNGs, and
requires zero A/A2changed pixels. Every named affected north cell must have
nonzero A/Bpixels inside its fully visible source quad, inset one native pixel.
Changes outside the union of actual candidate north quads, with a two-pixel
raster guard, fail. The report records per-cell phase/pixel evidence, actual
camera/culling/ROI bounds, headlamp settings, controller samples and real
mining mutations. Missing targets, blocked poses, invisible seams/endpoints,
unchanged B pixels or incomplete case/phase coverage fail; no coverage fallback
silently passes. Files already written remain available on any failure.

After a remote source checkpoint and an explicit renderer grant, import/parser
checks precede this bounded run. A lightweight headless parser may run earlier
only when the coordinator permits it. Run from the isolated study worktree:

```sh
NORTH_EDGE_STUDY_REVISION=$(git rev-parse HEAD)
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260917/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/d5437d917805/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/d5437d917805/north-edge-study \
  --output /workspace/scratch/d5437d917805/evidence/north-edge-affected-moss \
  --resolution 1696x780 --timeout 360 \
  --completion-marker NORTH_EDGE_AFFECTED_REVIEW_COMPLETE \
  -- --script res://tools/north_edge_orientation_pilot/affected_review.gd \
  -- --output=/workspace/scratch/d5437d917805/evidence/north-edge-affected-moss \
  --retained-output=/workspace/scratch/d5437d917805/evidence/north-edge-orientation-moss \
  --source-revision="$NORTH_EDGE_STUDY_REVISION"
```

The coordinator and independent release critic must inspect the original
full images, struck/opened contact, both step endpoints and biome joins.
Mechanical success is not visual acceptance, an FPS result or short-corner
completion. Any new compact-asset study remains separate and is not loaded.
