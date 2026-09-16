# Isolated Deep native wall study

This is an unreviewed rendering experiment, based on source tree
`6810ea1cd4b6990ca6ee0adebebb9fbe02322c4b`. The candidate defaults off. Only the
isolated worktree's Deep world invokes it; `CaveEdgeAssetDrawer` is unchanged.

The mapper uses the existing horizontal strip and the upright lower leg of each
native corner PNG. Every individual piece scales uniformly. All sampling is
anchored to absolute world coordinates and splits at source wrap boundaries.
It never rotates or flips artwork. Bedrock has its own measured profile.
The second source candidate replaces rectangular endpoint caps with joins clipped
to the adjoining face's measured native opaque contour. Long runs retain the
same absolute UV sampling. Both pieces overlap inside the other piece's actual
opaque rock, without adding fades, translucent masks, or new colored shapes.

Mineable visible thickness is 48 world pixels; bedrock is 96 at a 64-pixel tile.
These are study values, not accepted production proportions. In particular, the
304-pixel vertical source bands were
not authored as seamless loops: inspect their repeat joins closely.

`build_native_contours.py` measures 15,936 alpha >= 250 source contour samples
across the six materials. It writes contour data and a source-only validation
report, and never writes artwork. The mapper clips textured meshes to these
native contours; texture scale and orientation remain uniform. The report
validates the source samples, not runtime triangulation or rendered appearance.
Run it with `python tools/wall_pilot/build_native_contours.py` after any approved
source-artwork change. No new native artwork was required for this iteration.

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
