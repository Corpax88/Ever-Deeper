# Native corner quad study — 16 September 2026

Isolated base: `ec8976622231bc70c5413775291e841d0e543353`.
Branch: `codex/corner-quad-crop-study-20260916`.
This is a candidate, not a demonstrated performance win or approved release.

## Concrete scope

The only proposed runtime edit is the non-compact branch of
`CaveEdgeAssetDrawer._draw_corner`. Depth 2 calls this for its four mine profiles
and permanent bedrock; the Deep calls it for five native strata and bedrock.
Existing 48px Depth 1 corners always select `compact_join` and retain their
exact current implementation. No PNG, import setting, edge drawer, geology,
gameplay owner, cache signature, light, draw order or primitive count changes.

All active corner PNGs are 1024×1024. Offline inspection includes every nonzero
alpha value, then adds two source pixels plus one bilinear-filter pixel. Each
discarded margin has maximum alpha zero. The verified imports are lossless,
unscaled, straight-alpha and without mipmaps. `asset-bounds.json` records exact
PNG/import SHA-256 identities, settings, bounds and ownership.

| Native texture | Padded source `(x, y, width, height)` | Full quad retained |
| --- | --- | ---: |
| Ancient bedrock | 0, 364, 653, 660 | 41.10% |
| Rootwound | 0, 424, 630, 600 | 36.05% |
| Prismatic | 0, 425, 585, 599 | 33.42% |
| Molten | 0, 398, 613, 626 | 36.60% |
| Voidstar | 0, 432, 590, 592 | 33.31% |
| Mossvein v2 | 0, 232, 796, 792 | 60.12% |
| Moonglass | 0, 49, 978, 975 | 90.94% |
| Emberdeep | 0, 99, 976, 925 | 86.10% |
| Starfall D1 | 0, 436, 582, 588 | Not applied: compact joins |

For a full destination `D`, original texture size `T` and padded source `S`,
the compensated destination is `(D.position + S.position * D.size / T,
S.size * D.size / T)`. This preserves every retained texel's world location
and sampling scale. The existing corner origin, rotation, modulation and
transform reset remain unchanged. Region drawing explicitly uses `clip_uv=false`
because the original full-image call did not enable region UV clipping.
Unknown paths or mismatched texture sizes retain full-image drawing.

The rectangle area reduction is a hypothesis about fragment/light work, not a
measured GPU or FPS saving. The existing exact-zero-alpha discard shader already
avoids some per-light work, and the crop adds a small amount of redraw CPU.

## Validation sequence

1. Native asset matrix: eight affected textures, all four corner rotations,
   real 48/64px tile scales, bilinear and nearest sampling, integer/fractional
   view placement and zoom. Include overlapping native edges and compact joins
   as unchanged controls. Compare full decoded RGBA, preserving the first
   discrepancy. Stop before timing if exact pixel parity is not established.
2. Integrated frozen views: all four Depth 2 mines with ordinary excavation,
   adjacent permanent walls, real struck/open barriers and chamber transitions;
   five Deep strata with mineable/bedrock joins, damage/removal and stream-band
   boundaries; Depth 1 compact-join/gate regression views. All native lighting
   remains enabled. Record visible affected corners and actual state coverage.
3. Compare warm and forced-fresh cached commands and their counters. Corner
   geometry may narrow CanvasItem bounds; cache ownership, invalidators and
   required redraw/reuse behavior must remain identical.
4. Only after parity, run serialized baseline/candidate/restored-control timing
   on one renderer with no competing render/Blender/archive jobs. Retain every
   frame interval and actual elapsed time, p95/p99, draw counts, render setup/CPU
   and terrain callback counters. GPU time is reported only if valid and
   supported; zero/invalid values remain explicitly unsupported.
5. Complement a stationary native Deep view with real moving Ember excavation
   through the existing 60-second observer. Require travel, mined resources and
   removed terrain in every ten-second window. Do not promote a frozen-only or
   software-renderer result to physical-iPhone acceptance.

The reference drawer will be generated from the exact base commit into the
study output directory and injected only by the excluded harness before world
scripts load. Record and verify the actual bound drawer source in each owner;
production gains no reference switch or duplicate drawer implementation.

No render has run for this study yet. The surface/UI review owns the current
graphical slot; root must release it before this study starts rendering.
