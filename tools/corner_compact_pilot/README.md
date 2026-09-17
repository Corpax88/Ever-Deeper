# Isolated compact corner integration study

Prepared from `fec3185e7aa78b644bfa1c1ddc2ebd5cd10b5cd3` on
`codex/dev10-corner-compact-study-20260917`. This is an opt-in source-project
experiment. No production script, asset, scene, material, shader, project or
export configuration is changed. `tools/**` is already excluded from both
export flavors. No renderer was run during preparation; no visual result or
performance improvement is claimed.

## Cause and bounded change

The native DEV10 Deep capture has projecting square/T-shaped joins around
`x380–515, y385–535` in
`/workspace/scratch/d5437d917805/evidence/dev10-ci/premium-native-deep/session/final.png`.
The other native Deep capture shows the same construction around
`x720–770, y455–560` in
`/workspace/scratch/d5437d917805/evidence/dev10-ci/premium-native-deep/profile/live_idle.png`.
These are real native gameplay captures, separate from the widened-limit
camera parity fixtures.

Inspection of the actual original-resolution five mineable corner PNGs and
matching edge strips found long authored L-shaped arms. The shared drawer
places the full 1024px corner in a square three tiles wide: 192px in Deep and
144px in D2. This retains texture density but lets the long arms project almost
two cells from every local turn, including one-cell stair turns.

Deep's `_draw_permanent_wall_corners` and D2's `_draw_wall_corner_joins` both
use the full-footprint default. Consequently, compact clipping does not cause
the observed Deep/D2 defect. The adjacent-cardinal test correctly identifies
convex solid turns, but does not distinguish the available run length of each
perimeter arm. Stable draw ordering makes these oversized overlaps more
conspicuous; it is not their primary source.

Depth 1 already uses the shared `compact_join` path for local mineable turns.
This study changes only the two Deep/D2 mineable-corner calls to pass
`Color.WHITE, true`. Subclasses call the exact production method when disabled.
When enabled they keep its loop, eligibility, order, textures, orientation,
anchor, scale and bedrock branch. No concave-neighborhood rule is added.

`CaveEdgeAssetDrawer._draw_corner` crops a source region corresponding to the
existing destination rectangle, retaining UV density. It does **not** shrink
the complete image to the local join. The existing edge strips cover much of
the removed left/down arms. At tile64 the compact source bounds are about
`x430.22..693.33, y330.67..593.78`; at tile48 they are
`x426.67..696.89, y327.11..597.33`. The existing 2px seam overlap is unchanged.

**Known first visual gate:** Mossvein v2 has a much wider elbow and opaque
stone continues beyond the compact region's right edge. Rootwound, Emberdeep,
Moonglass and Voidstar have narrower opaque outer bounds. Moss may therefore
expose a straight cut even if the long T arms improve. Inspect Moss first;
retain the failure and reject this integration if it degrades the silhouette.
Do not silently omit Moss, rescale its artwork, or redefine a cut as a pass.
Permanent-bedrock anchors have a separate recorded mismatch and remain outside
this change.

## Earlier rejected work remains rejected

- The transparent-only quad crop in `docs/premium-polish/dev9-20260916/HANDOFF.md`
  failed its lossless rendering gate (153 RGB pixels by one channel level).
  This study deliberately changes the visible footprint and makes no lossless
  optimization claim. A/B changes require direct visual review; A/A2 must
  still be exactly identical.
- The contour-shadow study failed its original image despite geometric/ray
  equality. This study does not change any shadow geometry, mask or PCF setting.
- The earlier native wall mapping study produced rectangular cropped joins
  and did not receive visual acceptance (`RESUME-20260916-REVIEW.md` and
  `HANDOFF-20260916-PREMIUM.md`). Rotated edge strips, complete bedrock modules,
  material scale and wall-top integration remain unchanged here.
- `surface-HANDOFF-20260916.md` records the different Moss/Void painted leg and
  elbow footprints. The Moss crop risk is a real rejection gate, not new art
  work disguised as a small integration fix.

## Capture matrix

`review.gd` reuses the existing standalone source harness pattern and
`tools/run_rendered_isolated.py`. It installs the subclasses before scene entry
and starts with a fresh isolated save, seed4608 and real development progression
entry. It equips the real Burrower Drill so a normal hit leaves a damaged wall.
The original logical viewport, zoom and camera limits are retained. Smoothing
and drag are disabled identically for deterministic fixture positioning; every
hero anchor must be collision-free, and every required focus must be inside
the actual viewport. No hero-in-wall or camera-outside-world case is accepted.

Every case captures original A, compact B and restored A2 from the same frozen
state at native1696×780. Terrain caches are invalidated in all three modes so B
actually repaints. Geometry fingerprints must remain equal; A/A2 RGBA pixels
must be identical. B differences are measured without visual approval. Each
case saves the actual RunState JSON and SHA256. The report retains source hashes,
camera coordinates, separate logical-viewport and PNG focus coordinates, native
viewport size, mutations and failures. Terrain's remembered camera/viewport/zoom
must match the presented view, and the view must remain unchanged within A/B/A2.
Deep's production `_update_resource_pulses` runs once per new fixture pose before
freezing the triplet, so lamp eligibility follows that camera instead of the
previous pose. D2's `restore_position` already refreshes its landmark light owner.

| State | Fixture and required coverage |
|---|---|
| Normal | Actual generated arrival and nearest generated mineable convex corner; both are included in `smoke`. |
| Convex | An actual solid resource-free9×9 patch is excavated into a7×7 ring through `companion_dig`. Four inner corners must each have exactly one solid quadrant at the vertex. |
| Concave | Four outer ring corners must each have three solid quadrants. They retain production eligibility; no new concave cap is introduced. |
| Straight | All four faces of the retained5×5 island must each expose exactly one cardinal side. |
| One-cell zigzag | Further real excavation leaves five connected cells in a one-cell stair. Check opposing corners, intersections and missing floor. |
| Pillar | A single retained cell exposes all four sides and all four corner rotations. Check scale, depth, caps, shadows and the complete footprint. |
| Struck | `_strike_wall` or `_hit_terrain` applies one real Burrower hit; HP must decrease and the pillar must remain solid. |
| Excavated | `companion_dig` removes the struck pillar; the new floor must be visible without leftover corner artwork. |
| Permanent boundary | The shortest traversable route is excavated to the actual shell; permanent rendering remains the production branch. |
| Rebased / biome join | Deep is positioned on collision-free native seam corridors with the camera updated first. `_on_player_moved → _update_stream_depth` performs actual down/up rebases. The report labels the fixture teleport explicitly. |

Ring, stair and pillar states are accelerated **test excavation using real
production mutators**, not a claim that this seed naturally generates those
shapes, that the companion walked the route, or that held controls were tested.
If an eligible patch, a legal tunnel or a valid seam is missing, the matrix
fails and records the gap; it does not fabricate floor/HP arrays. Lighting and
animation are frozen, with the existing relic shader TIME lock only in memory
in both modes. This is visual integration evidence, not FPS or device evidence.

Run the complete matrix separately for these real material owners:

| Area argument | Depth / mine argument | Production material |
|---|---|---|
| `--area=deep` | `--depth=10` | Rootwound |
| `--area=deep` | `--depth=11` | Moonglass |
| `--area=deep` | `--depth=12` | Emberdeep |
| `--area=deep` | `--depth=13` | Voidstar |
| `--area=deep` | `--depth=14` | Mossvein v2 |
| `--area=d2` | `--mine=mossMine` | Rootwound D2 |
| `--area=d2` | `--mine=moonMine` | Moonglass D2 |
| `--area=d2` | `--mine=emberMine` | Emberdeep D2 |
| `--area=d2` | `--mine=starMine` | Voidstar D2 |

## Commands after renderer ownership is granted

Only the coordinator grants the single renderer slot. Do not run concurrently
with performance or feedback-UI studies. First import the isolated project using
the restored Godot runtime; an import is not visual verification. Then start the
bounded Moss smoke comparison:

```sh
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260917/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/d5437d917805/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/d5437d917805/corner-compact-study \
  --output /workspace/scratch/d5437d917805/evidence/corner-compact-smoke-moss \
  --resolution 1696x780 --timeout 180 \
  --completion-marker CORNER_COMPACT_REVIEW_COMPLETE \
  -- --script res://tools/corner_compact_pilot/review.gd \
  -- --output=/workspace/scratch/d5437d917805/evidence/corner-compact-smoke-moss \
  --area=deep --depth=14 --scope=smoke
```

Inspect A/B/A2 original PNGs before proceeding. For full coverage, use
`--scope=matrix`, a separate output directory per row above, and a longer
bounded timeout such as480s. Keep rejected images and reports. Root independently
reviews scale, material richness, silhouettes, edge continuity, permanent-wall
contacts, grounding and every affected topology before considering adoption.
Exact A/A2 restoration and a green harness are not visual acceptance.
