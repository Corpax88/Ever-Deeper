# FPS recovery — independent provisional review

Date: 2026-09-09. **The initial D1 gain estimate is withdrawn pending correction
of its reference draw path. Physical iPhone performance, final 1.0 and LIVE
approval remain open.** This reviews current source changes, two measured
triplets and a broader source visual preflight. It does not approve an immutable
exported release or the whole game. The inspected visual comparisons remain
useful; pixel agreement alone does not establish an equivalent performance baseline.

The latest supplied phone screenshot records 19.9 FPS and P95 56 ms in active
play. The exact build is not visible. `D2` is frame-meter revision 2; 554 seconds
is elapsed meter time, while the displayed FPS summarizes approximately two
seconds. The image does not establish thermal throttling or a memory leak.
See `../one-point-zero/iphone-performance.md` for the complete observation.

## Diagnosis and implementation review

The earlier immutable-baseline Emberdeep attribution measured 5.48 FPS with
normal updates, 5.16 with updates frozen, 18.22 with the root draw's light
contribution excluded, 5.54 after restoring it, 20.50 with all lights off and
5.58 after restoring them. This strongly supports investigating the broad D1
light receiver. It does not justify removing the player's or mole's lighting.

The reviewed D1 change draws the existing artwork through bounded sections and
draws the original two-layer floor only where it can be exposed. Static review
found the following:

- The original block, edge, bedrock masking and concealed-chamber passes remain
  in row/column order. Empty-section predicates match their drawing predicates.
- Floor regions retain empty cells and exposed resource cutouts. Cells excluded
  from the floor are covered by the existing opaque rock or bedrock undercoat.
  Region runs are limited to six cells and preserve the original floor UV origin.
- The original floor color followed by the texture at alpha 0.94 remains intact;
  D1 explicitly disables the composite shader. Existing Hub/D2 callers retain
  their default unrestricted floor behavior and transparent optional underlay.
- Barrier and cave-edge transforms still reset. Target, drop, impact and Crusher
  debris drawing consistently uses the selected section.

The Deep similarly preserves its base pass followed by edge/corner pass. It
selects each row's original stratum and restores the current gameplay stratum
after each draw callback. Removing the covered background has a concrete asset
basis: independent inspection confirms all five floor PNGs are RGB without an
alpha channel, as is `assets/surface/v3/cave-rock-mass.png`. Floor fallback colors
and wall texture draws are opaque. The visible grid covers the former background.
This assumption must remain true if these production assets are changed later.

No confirmed paint-order or gameplay-state defect was found in the inspected
changes. The section/floor pools retain their peak allocation rather than growing
per frame; repeated movement, viewport changes and streaming still need runtime
verification of bounded node counts and correct redraws.

## Independently inspected paired evidence

Working evidence is under
`/workspace/scratch/6604552ab244/fps-investigation/compare-ember-cull/` and
`/workspace/scratch/6604552ab244/fps-investigation/compare-deep/`.
The critic read both `comparison.json` reports and the attribution harness,
viewed all six `broad.png`, `narrow.png`, `restored.png` files, and independently
recomputed image differences and SHA-256 identities.

Both triplets use native Godot with **llvmpipe**, a **2328×1260** physical window,
one second of settling and eight seconds per measurement. The comparison stages
freeze simulation and switch the bounded draw paths in the same process. They
are short source-level rendering comparisons, not sustained mining, a browser
benchmark or physical-device measurements. The reported engine process monitor
is not exclusive script CPU time. Original/restored paths retain allocated but
hidden section nodes in these same-process comparisons.

### Correction: the initial D1 reference emitted extra work

A subsequent audit, prompted by the root implementer, found that the disabled
`LitFloorChunks` fallback unconditionally draws its wash rectangle even when
the wash is `Color.TRANSPARENT`. The critic verified against source `246ee70`
that original D1 emitted exactly an opaque background rectangle followed by
the floor texture. The new fallback used in the source `broad` and `restored`
stages added a third, world-sized transparent rectangle. The active chunk path
already skipped this rectangle when its alpha was zero.

That additional command may incur lit fragment work while preserving every
output pixel. It invalidates the initial D1 timing reference and the previously
reported **176.47% / approximately 2.7× gain**. The critic's earlier interpretation
of that estimate as a valid improvement is superseded here. Matching restored
pixels and small timing drift did not detect this difference in submitted work.

The proposed `wash.a > 0.0` fallback guard restores the original D1 floor command
sequence. Existing Hub/D2 washes have alpha 0.12 and retain their original draws.
The Deep does not use this fallback, so this specific defect does not invalidate
its reference. The size of the D1 overstatement cannot be inferred by comparing
unmatched baseline and source runs. Corrected paired measurement and the planned
unchanged-PCK baseline versus final-PCK sustained comparison are required before
reporting a D1 improvement. The immutable baseline package is not changed by
this source-reference correction.

The old observations below are retained transparently, **not as accepted D1
performance evidence**:

| Fixture | Source broad FPS | Candidate FPS | Restored FPS | Gain interpretation | Control drift |
|---|---:|---:|---:|---:|---:|
| Emberdeep D1 | 4.543 | 12.196 | 4.280 | Invalid reference; withdrawn | 5.97% |
| The Deep | 5.612 | 7.190 | 5.216 | 32.79%; short source fixture only | 7.32% |

The Deep's observed gain exceeds the drift between its controls; it remains
a short software-renderer result. Its P95 is 211.950 → 169.558 → 234.029 ms and
draw calls fall from 693 to 512. The invalid D1 triplet recorded P95
247.183 → 97.748 → 281.701 ms and 171 → 206 → 171 draw calls; those numbers
do not establish its improvement. Draw-call count alone is not the performance
acceptance criterion.

| Image comparison | Changed pixels | Maximum channel difference | Original/restored |
|---|---:|---:|---|
| Emberdeep D1 | 583 of 2,933,280 (0.01988%) | 4/255 at one pixel; 1/255 at the other 582 | Byte-identical |
| The Deep | 0 | 0 | Byte-identical |

No introduced loss of material detail, changed lighting appearance or seam is
visible in these pairs. The Emberdeep view includes permanent rock, a barrier,
the textured entrance, lamps, hero and mole. The Deep view includes the blue/ember
stratum boundary, floor, wall corners, permanent rock, resource art, hero and mole.
It does not cover all biomes, all equipment/light styles, motion or excavated states.

| PNG identity | SHA-256 |
|---|---|
| Emberdeep original and restored | `903b66c38b787104d095a628b19ac088a495efdae24ba8dccef580875d13d527` |
| Emberdeep candidate | `e8203708f2ac48d697ed6359fdaeeae76c0204f5572a36e6b3eec562995cc37c` |
| All three The Deep PNGs | `2dfe066ecbaf64865aa78601f24d39a3e8bac25c33a61648f7b598c0aa58208e` |

## Broader source visual preflight

The subsequent `fps-investigation/visual-source/` run contains 75 PNGs from 25
triplets: four D1 mines with all five light styles, plus five Deep strata with
one style each. Its `pack_sha256` explicitly says `editable-source-preflight`.
The half-second samples in this run are **visual verification only** and must
not be cited as performance measurements.

The critic read the harness and its zero-failure terrain/light-state report,
independently recomputed all 25 image comparisons and all 75 PNG hashes, and
confirmed they match `pixel-comparison.json` (SHA-256
`d970459cc8b6772183dbd29685b4222303cba5ab7e017969030bb92939ef3367`).
All 25 original/restored pairs are byte-identical. Every Deep triplet is entirely
pixel-identical. D1 differences never exceed 2/255 in any channel.

| D1 biome | Largest changed-pixel count among its five styles | Maximum channel difference |
|---|---:|---:|
| Mossvein | 1,249 | 2/255 |
| Moonglass | 890 | 2/255 |
| Emberdeep | 782 | 2/255 |
| Starfall | 1,351 (0.0461% of the frame) | 2/255 |

Actual visual inspection covered 14 representative frames: both original and
candidate for `mossMine-deepheart`, `moonMine-wide`, `emberMine-wide` and
`starMine-deepheart`; all five Deep candidates; and `mossMine-prismatic-narrow`.
These include each biome's largest numerical difference, the five Deep strata,
normal terrain, permanent rock, visible intact barriers, resource cutouts, lamps,
hero/mole poses, stratum joins and one visible damaged stone/impact fixture.
No new visible seam, lost material detail or changed lighting appearance was
found. This is representative visual inspection, not a claim to have visually
viewed all 75 PNGs.

The inspected source preflight passes its bounded visual comparison. Coverage
still has a concrete limitation: `restore_position()` can choose a safe fallback
at the entrance, so a requested distant camera position alone does not prove an
outer corner or other specific geometry was shown. Final package coverage must
assert and capture the intended mined corner, exposed resource, and affected
barrier/impact states. Sustained motion and streaming are separate checks.

## Related changes and remaining acceptance

The resource owner's final headless lifecycle report was inspected at
`/workspace/scratch/6604552ab244/fps-resources/final/commerce-residency.json`.
Its 122 passing assertions cover repeated Light Lab/Wardrobe opening and closing,
worn → Crusher → Deepcore → worn equipment, identical reopened selection/catalog,
unchanged loadout/resources and final loading-queue drainage. Closed Light Lab
releases all six preview viewports; the unchanged full-resolution Wardrobe PNG
is no longer retained after closing. This is valid lifecycle evidence, not a
measurement of GPU savings or the cause of the phone's 19.9 FPS.

Before DEV publication, the final combined source/package needs the affected
mobile visual matrix, gameplay regressions and sustained rendering checks. Key
remaining risks are camera/chunk-boundary redraws, exposed resource-floor cutouts,
mining and broken barriers, all D1 biomes and Deep strata, lighting styles, repeated
travel/rebase, returning with a relic, and shop preview reopening. These are checks
of the agreed game, not requests for additional features.

Sustained comparison must include actual active Emberdeep D1 mining, the completed
Hub and post-fifth-relic The Deep, with unchanged graphics and matching fixtures.
Keep per-window frame timings and first/last windows, record actual movement,
mining/pickups and bounded memory/node trends, and do not hide streaming or save
spikes. A successful harness exit alone does not mean its FPS target passed.

Final physical acceptance requires the actual candidate on the phone, including
longer ordinary play after startup. The existing smooth-60 target is mean at least
58 FPS, P95 at most 20 ms and no frames over 33.34 ms in measured steady windows;
loading/transition behavior must be reported separately. Neither this review nor
the previous 8.4/10 DEV assessment establishes a final 9/10 overall or performance
score. No LIVE publication is approved by this report.

The critic changed documentation only and launched no native rendering workload
during this review.
