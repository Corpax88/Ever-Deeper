# One unapproved compact Moss corner art study

Unapproved study. The first checkpoint passed import/parser but stopped after
its original A capture: its save comparison wrongly included the serializer's
wall-clock `saved_at_unix`. Complete failed evidence is preserved at
`evidence/compact-art-moss/attempt-01-5c690dbe/`. It captured no candidate art.
This fixture correction retains all raw per-mode saves and excludes only that
envelope timestamp from equality. Every gameplay field and schema/version
still must match. The first failing payload was not saved, so its other fields
cannot retrospectively be certified equal. The coordinator must checkpoint
this correction and grant a renderer slot before retrying. No art acceptance
or export has occurred.

Base runtime: `8f5680defb9083bbe1e044d39a10612f2186e7f3`.
Base tree: `48b24a93faaa6f77d7a53c404cfb1228d7f825e0`.
Isolated worktree: `/workspace/scratch/d5437d917805/compact-art-study`.
Only `tools/compact_art_pilot/` is added. Production source, scenes, native
assets, the existing north-edge study and prior rejected studies are untouched.
Ordinary scenes never load these subclasses; both switches default to false.

## Exact scope and original art

The only new-art substitution is the genuine generated mineable Moss NE
corner at cell `(16, 27)`, seed `4608`, Deep `14`, window start `13`, with
open sides `[north=true, east=true, south=false, west=false]`. Every other
corner and all permanent walls delegate to the exact production owner.
The override additionally requires both native Moss texture paths and the
expected seed/depth. It cannot draw the new art in another biome or cell.

`north_reference.gd` is a byte-identical copy of the already audited north-only
override, SHA256
`100ed61d1e37f121306c2c6d06ac246e4cbb5bdd5c0dc16fd9a4ec3aad15890f`.
It changes only the mineable Moss NORTH strip's Y orientation while preserving
its complete source segment, phase, X reflection, world quad and material.
The new `deep_candidate.gd` extends that reference and replaces the one NE
corner draw only in C. It uses the same drawing CanvasItem, light/shadow
configuration, material, transform and order as that corner's native draw.

Both generated PNG byte streams are preserved in `assets/`:

| File | Role | SHA256 |
| --- | --- | --- |
| `moss-ne-initial-unapproved.png` | Initial generation; provenance only, never drawn | `41e59116919f83a1f8a2e30484ac5cc165defc6cfa159a70a185195354c75146` |
| `moss-ne-three-boulder-unapproved.png` | Revised three-cap candidate, drawn only in C | `af283ca7b418846f042af4fe318930fb23d5a7976181bd1f837cd04333de589f` |

The exact generation prompts and reference metadata are retained unchanged
in `generation-metadata.json`. Prompt specifications are provenance, not a
claim that every requested dimension or shape was achieved. Both actual
PNGs are 1254 × 1254 RGBA. `asset-audit.json` records their actual dimensions,
bytes, hashes and measured alpha bounds, plus the two approved native assets.
No image has been edited, trimmed, cropped, masked, recolored or re-encoded.

## Fixed placement and footprint audit

C draws the entire revised PNG once into a 128 × 128 world rectangle at
`cell_top_left + (-32, -32)`: absolute world rectangle `(992, 1696, 128, 128)`.
Both axes use exactly `128 / 1254` scale. There is no rotation or reflection,
no source-region draw, no source/alpha trimming and no custom material.
All source alpha, including faint pixels beyond the principal form, remains.

The revised significant-alpha footprint (`alpha > 8`, analysis only) is
source bounds `[207, 273, 1053, 1055)` and world rectangle approximately
`(-10.871, -4.134, 86.354, 79.821)` relative to the cell top-left. Any nonzero
alpha extends to source `[65, 32, 1172, 1182)`, about 113 × 117 world pixels.
The rasterizer is not given either threshold; it draws the full original.
The native corner is drawn on a 192 × 192 world canvas with a roughly
149 × 148 world nonzero-alpha footprint. Thus the candidate changes the
authored extent without reducing the native artwork through a crop.

Native-resolution inspection finds three dominant broad cracked caps with
warm gray/olive stone, layered dark faces and moss seams. Estimated candidate
cap widths are about 36–42 world pixels; larger native strip caps are about
43–58 world pixels. These are approximate visual landmarks, not segmented
measurements or an art approval. The generated rim lighting is warmer and
brighter. Whole-stone rounded termini may fail to join the continuing strip,
and low-alpha fringes may become visible under actual game lighting. Only
the B/C game comparison can judge these risks. Do not call the image accepted.

## Exactly four frozen captures

The retained native pose uses the normal Deep owner, player `(1056, 1696)`
on verified walkable floor, facing down, with actual camera `(1056, 1808)`.
This is an explicit fixture teleport, not continuous gameplay evidence.
The unchanged production camera zoom, offsets, limits, content 1280 × 720
and native 1696 × 780 framebuffer are required. The three north focus cells
are `(12, 27)`, `(13, 27)` and `(14, 27)`; both real endpoints remain visible.
Camera drag/smoothing and process/physics/tweens are frozen equally in all
four captures. The seal shader's TIME is fixed only in memory and restored.

| Capture | North strip | NE corner |
| --- | --- | --- |
| `moss-compact-held-A.png` | Exact production path | Exact production path |
| `moss-compact-held-B.png` | Audited upright Y orientation | Exact production path |
| `moss-compact-held-C.png` | Same audited orientation as B | Whole unapproved revised PNG at the one target cell |
| `moss-compact-held-A2.png` | Restored production path | Restored production path |

The harness invalidates the actual draw caches for every mode and requires
fresh callbacks. It checks target draws, exact visited corner topology and
native texture selections, unchanged geometry fingerprints and serialized
save content/schema/version, and unchanged camera/culling. The sole ignored
save field is the wall-clock `saved_at_unix` envelope timestamp. Every raw
per-mode save and timestamp is retained before comparison, including failures.
It saves and hashes actual node
presentation properties, hero pose, material uniforms and occluder polygons;
source resources referenced by those properties are hashed too. These are
registered property snapshots, not a claim to serialize every GPU state.

`baseline-files.json` pins critical production owners/assets to exact8f,
while its base Git tree identifies the remaining unchanged tracked content.
The original generated/native PNGs and copied north override must match their
recorded hashes. All study source/provenance hashes go into the rendered report.
The initial held save, all four raw per-mode saves and the visual-property
snapshot are saved beside the images, with raw and comparable-content hashes.

A/A2 must have zero changed RGBA pixels. A/B and B/C must have visible effect.
B/C must have zero changed pixels outside the union of the old and new full
corner drawing quads, enlarged by only two native pixels for edge filtering.
This rectangle is a comparison bound; it never crops or masks the bitmap.
The full image and both endpoints remain authoritative for visual review.
The report includes actual projected regions, difference counts/bounds and
all four original PNG hashes. Failures retain existing output and exit nonzero.

The coordinator and a second critic must inspect all four original images,
especially B/C west and south joins, cap scale, cliff depth, outer silhouette,
lighting, moss color, faint alpha, and newly exposed side strips. A restored
control or localized difference does not imply good artwork. This one pose
cannot approve other corners, stairs, pillars, biomes, permanent walls,
movement/mining, physical devices, world completion or FPS. No broad matrix
or production adoption is part of this study.

## Commands only after checkpoint and renderer grant

Use the approved Godot 4.7.2 runtime. Initial imports/parser checks are also
forbidden until the coordinator saves the source remotely and grants a slot.
No export is needed. Preserve the first output directory if a failure occurs.

```sh
COMPACT_ART_STUDY_REVISION=$(git rev-parse HEAD)
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260917/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/d5437d917805/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/d5437d917805/compact-art-study \
  --output /workspace/scratch/d5437d917805/evidence/compact-art-moss \
  --resolution 1696x780 --timeout 180 \
  --completion-marker COMPACT_ART_REVIEW_COMPLETE \
  -- --script res://tools/compact_art_pilot/review.gd \
  -- --output=/workspace/scratch/d5437d917805/evidence/compact-art-moss \
  --source-revision="$COMPACT_ART_STUDY_REVISION"
```

There are no area, depth, matrix, excavation or candidate-placement arguments.
The harness can run only the named fixed pose and fixed unapproved placement.
