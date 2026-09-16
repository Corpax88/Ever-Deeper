# Isolated Deep native wall study

This is an unpromoted rendering study, based on source tree
`6810ea1cd4b6990ca6ee0adebebb9fbe02322c4b`. The candidate defaults off. Only the
isolated worktree's Deep world invokes it; `CaveEdgeAssetDrawer` is unchanged.

Continuation from exact saved study `90ac772232b8506f7146a495e8ae613cd178f663`:
[V4 native elbow feasibility](NATIVE-ELBOW-V4-FEASIBILITY.md) rejects a measured
upright NE elbow placement before integration. The mapper and artwork remain
the preserved V3 bytes; no rendered V4 or newly accepted wall is claimed.

The mapper uses the existing horizontal strip and the upright lower leg of each
native corner PNG. Every individual piece scales uniformly. All sampling is
anchored to absolute world coordinates and splits at source wrap boundaries.
It never rotates or flips artwork. Bedrock has its own measured profile.
The second source candidate replaces rectangular endpoint caps with joins clipped
to the adjoining face's measured native opaque contour. Long runs retain the
same absolute UV sampling. Both pieces overlap inside the other piece's actual
opaque rock, without adding fades, translucent masks, or new colored shapes.

Mineable visible thickness is 48 world pixels; the third candidate reduces
bedrock to a 55-pixel median at a 64-pixel tile. Its measured maximum opaque
horizontal/vertical spans are 63.59/60.21 pixels, compared with the oversized
96-pixel median in the rejected second candidate.
These are study values, not accepted production proportions. In particular, the
vertical source bands were not authored as seamless loops: inspect their repeat
joins closely.

`build_native_contours.py` measures 16,088 alpha >= 250 source contour samples
across the six materials. It writes contour data and a source-only validation
report, and never writes artwork. The mapper clips textured meshes to these
native contours; texture scale and orientation remain uniform. The report
validates the source samples, not runtime triangulation or rendered appearance.
Run it with `python tools/wall_pilot/build_native_contours.py` after any approved
source-artwork change. No new native artwork was required for this iteration.

## Third candidate

Reviewed v2 is preserved in commit `83eb590c8953cbdf26b4a83c46ec4f849f51a263`.
Its complete 36-image review accepted the bounded Moonglass, Emberdeep and
Mossvein topology boards, but rejected Rootwound/Voidstar repetition, bedrock
bulk/directional joins and every flat stratum cutoff. It was not promoted.

The third candidate preserves all three accepted profile constants and native
contour arrays. Rootwound, Voidstar and bedrock use quantitatively selected
native leg bands. `select_native_bands.py` records the full search parameters
and metric in `native_band_selection.json`:

| Material | Native rows, end exclusive | Seam score before → after | World repeat length |
| --- | --- | --- | --- |
| Rootwound | 669–1021 | 67.99 → 53.86 | 149.52 px |
| Voidstar | 670–990 | 72.43 → 37.75 | 165.16 px |
| Bedrock | 708–1024 | 41.10 → 36.02 | 71.52 px at the smaller scale |

The score is three-row premultiplied RGB MAE plus 0.6 times alpha MAE on occupied
source columns. It measures endpoint difference, not visual quality. The finite
native assets still contain recognizable repeating motifs, and their authored
bedrock/crystal grain remains directional. Longer source bands cannot establish
nonrepeating, coherent long walls by themselves.

At stratum boundaries the two adjacent rims and both native wall-mass tints use
one shared contour taken from the incoming material's opaque native top edge.
The contour keeps that edge's uniform scale and absolute X phase. Both sides
sample the same half-pixel grid and overlap by 0.25 pixels; no fade or new pixels
are painted. Floor art and gameplay terrain remain unchanged.

`validate_native_wall_v3.py` verifies the source parameters, preserved profiles,
bedrock spans, five non-flat mask shapes, exact wall-mass partition areas, rim
mask matching, and rebase invariance. Results are in `native_wall_v3_proof.json`.
This file is source/geometry proof only. The completed graphical run and its
separate, scoped visual verdict are recorded below. Gameplay and performance
remain unverified for this study.

## V3 review checkpoint

The successful capture set is
`/workspace/scratch/4e99473f21fc/evidence/deep-wall-study-v3-fixed2`.
Godot 4.7.2 rendered 36 PNGs at 1696×780 with the software renderer, using
`--verbose --render-thread safe`. The process exited 0, all 19 structural checks
passed, and the log contains no `SCRIPT ERROR`, `Parse Error`, or `ERROR:`.
It includes the explicit completion marker:
`WALL_STUDY_CAPTURED 36 frames; visual review remains required.`
The captured source hashes match this candidate:

- Mapper SHA-256: `fa29ae97baff7e4b41271986bb0ff8aab8a2019660a20e3081c06cf4fb0d352a`.
- Source-proof SHA-256: `71976c61e79b5e8d5b7f4227a13233b9e26b4b9b11142acaf3657db5a52f97e7`.

The independent visual review was bounded to those actual saved frames:

| Captured scope | Verdict | Remaining limitation |
| --- | --- | --- |
| Rootwound intact and excavated topology | Bounded pass | No broader travel, mining or performance claim |
| Moonglass, Emberdeep and Mossvein topology | Prior bounded passes retained | All six candidate PNGs are pixel-identical to v2 |
| All five real stratum boundaries | Bounded pass | This covers the captured boundary views |
| 7/8 boundary rebase | Pictured pass | Paired fixed viewpoints, not a continuous traversal |
| Voidstar topology | Rejected | Large repeated vertical clusters at x620–696/y100–610 and the narrow column at x1496–1592/y98–311 |
| Bedrock topology | Rejected | Grain crosses straight corner joins at x105–122/y98–164 and x389–409/y98–164 |

V3 remains default-off and unpromoted. Structural success is not overall visual
acceptance, and this checkpoint is not whole-game, performance, or device approval.

Both failed attempts are preserved beside the successful set:

- `deep-wall-study-v3`: exited 3 after one PNG. The log contains the typed
  conditional-array assignment error plus wall-mass polygon triangulation
  failures. The array now initializes separately; wall-mass transitions use
  explicit native-textured triangles with the same contour and UV mapping.
- `deep-wall-study-v3-fixed`: exited 3 after 33 PNGs. A remaining bedrock-rim
  polygon triangulation failure occurred in topology coverage. Bedrock now uses
  explicit convex contour strips split at native UV wraps. The three accepted
  materials retain their existing rim renderer.

The final run's `wall-study.json` records all source hashes and capture pairs;
`godot.log` records successful completion. No production drawer or source artwork
was changed, and no V4 geometry is included in this checkpoint.

## Native source-art brief for the remaining rejected joins

This is an authoring specification, not approval of replacement artwork or a V4
implementation. Further crops of the present L-shaped sources cannot supply
long nonrepeating Voidstar faces or all correctly lit bedrock turns.

| Material | Exact native references | Required complementary artwork |
| --- | --- | --- |
| Voidstar | `assets/voidstar/cave-edge-loop-v1.png` (1024×128 RGBA), `assets/voidstar/cave-corner-v1.png` (1024×1024 RGBA) | At least two upright vertical loop variants with finer, less dominant clusters, matching the existing purple mineral, rock detail and world-up highlights. Author complementary left/right-facing contours where needed; do not mirror the lighting. |
| Bedrock | `assets/caves/ancient-bedrock-edge-loop-v1.png` (1024×256 RGBA), `assets/caves/ancient-bedrock-corner-v1.png` (1024×1024 RGBA) | Four direction-authored convex elbows (NE, SE, SW, NW) and the four matching concave excavation joins. Carry the native facet grain continuously from each horizontal edge into its upright vertical face; retain the dark heavy bedrock material. |

Use one transparent production PNG per asset with genuine RGBA alpha, no text,
background, baked checkerboard or mockup composition. Keep native pixel detail,
palette, local contrast and world-up light direction. Each piece must use one
uniform scale; no stretched axes, rotated/mirrored lighting, painted seam masks
or added translucent fades may conceal a mismatch.

At a 64-pixel world tile, match the study's 48-pixel median visible Voidstar rim
and 55-pixel bedrock rim. Measure the visible alpha footprint, not the padded
canvas size. Bedrock's maximum opaque horizontal and vertical spans must remain
within one 64-pixel solid (V3 measured 63.59 and 60.21 pixels). Retain the current
5.33-pixel mineable and 8-pixel bedrock floor overlap. Source detail should be
authored at a common texel density that reaches these dimensions by uniform
scaling, with enough transparent padding for the native silhouette.

Every connecting end must match its neighbor in RGBA, silhouette, grain
direction and feature scale across a shared overlap band. Vertical variants
must join A→A, A→B, B→A and B→B without an abrupt tone/alpha step or an obvious
repeated large crystal. Test at least eight tiles of uninterrupted wall: the
current 165.16-pixel Voidstar repeat is the rejected reference, not a target.
For bedrock, verify all eight joins against the actual horizontal/vertical
profiles; a rectangular crop meeting a cross-grained face does not pass.
Measure the final alpha contours from the exact delivered PNGs and use those
same contours for clipping and mass coverage, including the current irregular
stratum overlap and absolute-coordinate phase after rebase.

Acceptance requires actual target-resolution comparisons of all four turns,
stairs, single-cell pillar, narrow column and excavated shapes, plus the five
stratum boundaries and rebase pair. There must be no straight crop seams,
floor leaks, swollen corner stamps or loss of the approved material detail.
Rootwound, Moonglass, Emberdeep and Mossvein profiles/artwork stay unchanged.
Gameplay clearance, performance and device quality require separate evidence.

The two ImageGen previews `exec-bf784955-6915-4ee4-b22f-320cd220f0b6.png` and
`exec-32b541d2-bf46-4140-8a3a-586aa9ec5e8b.png` in the sibling
`generated_images` directory are 1254×1254 RGB images with a baked checkerboard,
including the attempted transparency edit. They are unaccepted previews and
must not be integrated or treated as transparent production assets. This brief
adds no artwork, geometry, render, or change to the preserved V3 study.

## Capture

Run one renderer at a time. The main task owns that renderer slot. From this
worktree, the first two-image boundary comparison can be captured with:

```sh
python tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/4e99473f21fc/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/4e99473f21fc/deep-wall-study \
  --output /workspace/scratch/4e99473f21fc/evidence/deep-wall-study-first \
  --resolution 1696x780 --timeout 480 -- \
  --script res://tools/wall_pilot/review_deep_wall_study.gd -- \
  --output=/workspace/scratch/4e99473f21fc/evidence/deep-wall-study-first \
  --case=boundary_9_10 --variant=both
```

For the complete 36-image set, use a fresh output directory and `--case=all`.
Other filters are `boundaries`, `topology`, an individual boundary ID, or a
material prefix such as `topology_mossvein`. Individual shape IDs append
`_intact` or `_excavated`. `--variant` accepts `baseline`, `candidate`, or `both`.
`--hold` leaves the last scene open with working Baseline/Candidate buttons.

The matrix contains five real stratum boundaries, a rebase at the same absolute
7/8 viewpoint, and both intact/excavated topology boards for five mineable
materials plus bedrock. Each board exposes four turns, stairs, a single-cell
pillar, a narrow column, and a three-cell excavation. The topology board is
explicitly synthetic, uses a render-only material override, and is not a mining
or travel test. Boundaries use generated terrain and ordinary material rules.
The hero pose, camera, terrain and lighting processes are frozen across each
pair. The report records source SHA-256s, framebuffer, renderer, player/camera,
geometry checks, and profile scales. It does not award visual acceptance.

## Required visual review

- Top highlights must remain upright on all four sides and turns.
- Long native faces must remain continuous at cell seams and after rebase;
  judge the source-band repeat seam independently of the cell seam.
- Join caps must close corners without the original oversized L stamps,
  rectangular crop edges, visible floor leaks, or excess intrusion into paths.
- The one-cell pillar, thin column, stairs and excavation must still read as
  coherent solid rock; bedrock must retain its heavier native identity.
- All five materials and their real boundaries must retain the native artwork's
  detail, material, silhouette, and lighting. Inspect actual target-size PNGs.

This fixture cannot establish performance, physical iPhone quality, playability,
or animation quality. Any candidate promoted later needs the applicable real
rendered gameplay checks and measured performance evidence.
