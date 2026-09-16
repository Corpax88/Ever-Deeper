# Surface polish handoff — 2026-09-16

Work stopped at the user's **SAVE FOR NEW CHAT** instruction. No surface runtime is active. No release or deployment was made. The current source includes a final, **unrendered** movement/collision refinement; do not treat the earlier captures as verification of those last edits.

Repository: `/workspace/scratch/5a78be25fc28/Ever-Deeper`.
Read `AGENTS.md`, the main premium-polish handoff, and this file before continuing.

## Evidence and acceptance, precisely

| Evidence directory under `/workspace/scratch/5a78be25fc28/evidence/` | Actual result | Scope |
| --- | --- | --- |
| `surface-supported` | Rejected | Stacked duplicate cliffs and thin dark approaches looked pasted onto vertical faces. |
| `surface-native-floor` | Superseded | First native-floor layout; Star cave was occluded and the right resource cluster needed moving inward. |
| `surface-native-floor-final` | Superseded by full surface set | Corrected Ember/Star native floor, before replacing the floating Moon branch. |
| `surface-all-native` | **36 images, 23/23 checks passed** | All four mountains at full/half/depleted; eight mine/resource/Starforge/Hub approaches; 144 drop landing samples. Native Moon/Ember/Star shelf integration accepted visually. |
| `surface-contact-v1` | **52 images, 26/29 checks passed; overall false** | All mountain states, eight local approaches and 144 drop destinations passed. All three actual mining/contact tests passed. Three newly added long trunk routes failed. |

`surface-polish.json` in each successful capture directory records exact source hashes, viewport, renderer, every image, and functional checks. Images are 1696×780 actual Godot renders using llvmpipe. Fixed-step controller walks are functional evidence, **not physical iPhone FPS evidence**.

The contact set is **52 images, not an accepted 54-frame set**. Two intermediate route images were absent because routes stopped early. The latest harness should produce 54 if all three long walks complete.

Independently inspected contact images include Moon front/behind/depleted, Ember front, Star behind, Ember mountain full, and Starforge approach. Feet sorting is visibly correct: a rear actor is occluded by the mineral base; a front actor appears in front. The mole no longer sits visually on top of an intact crystal when its feet are behind it. The native shelf remains coherent. This is not an overall-game 9/10 sign-off.

## Implemented native terrain/layout work

The rejected extra shelf stack and all lower thin branch ribbons were removed. Each later biome now uses one complete native terrace, preserving native material and projection:

| Biome | Native asset | World rectangle |
| --- | --- | --- |
| Moon | `assets/surface/v2/moon-road-shelf.png` | `(1070,425,1220,620)` |
| Ember | `assets/surface/v3/ember-road-shelf.png` | `(2200,425,1220,610)` |
| Star | `assets/surface/v3/star-road-shelf.png` | `(3320,425,1220,610)` |

The authored Moss ramp remains. Three attempted generated slope assets failed real alpha (RGB checkerboards) and were rejected outside the repository. No failed image-generation asset was integrated.

Mine mouths and return points are on the upper terrace floor:

| Mine | Mouth | Return / public guide point |
| --- | --- | --- |
| Moon | `(1430,626)` | `(1430,666)` |
| Ember | `(2460,626)` | `(2460,664)` |
| Star | `(3740,620)` | `(3740,664)` |

Star's earlier x3520 mouth was rejected because the gate/Starforge occluded it. The current x3740 mouth is integrated into the left mountain flank.

Hub lift: visual position `(4200,563)`, approach/public guide `(4200,650)`, interaction radius105. Architecture owner updated `RunState.HUB_SURFACE_ENTRANCE` to `(4200,650)`. Main guide proposals now use `mine_guide_position()` and `hub_guide_position()` instead of old lower approaches.

Moon's former floating five-piece cyan platform is gone. The seam uses one full native bloom bed. Ember and Star similarly use their native mineral beds on the terrace. Timed/Moon/mountain loot landings are projected onto valid collision-free floor rather than scattering into the void. Ember ground-creature anchors are on the walk floor.

## Mountain stages and contact

Persistent half-reserve translucency was a real defect: HP directly controlled stage blending, leaving a half-mined mountain ghosted indefinitely. `_apply_mountain_stage()` now selects the authored solid stage and blends only during a 140ms stage transition. Settled stage mixing returns to zero. Full/half/depleted images of all four mountains passed and were inspected across the surface sets. Hidden duplicate blend sprites were removed.

The contact pass moved the later physical mountain ellipses down to their visible base:

| Mountain | Ground center | Uninflated half size |
| --- | --- | --- |
| Moon | `(1665,565)` | `(168,62)` |
| Ember | `(2820,575)` | `(185,60)` |
| Star | `(3900,575)` | `(192,60)` |

Moss retains center `(555,565)` and half size `(198,51)`. Later mountain approach fixtures use y662. Before this, later collision centers near y490 allowed feet through the front apron.

## Resource / actor contact pass

Current strike positions:

| Cluster | Native node strike positions |
| --- | --- |
| Moon | `(1910,584)`, `(2000,616)`, `(2090,586)` |
| Ember | `(3050,584)`, `(3130,616)`, `(3210,586)` |
| Star | `(4280,581)`, `(4400,586)`, `(4340,616)` |

The 98×94 maximum node artwork keeps its real rock base: ground center is strike position + `(0,28)`, uninflated footprint `(34,13)`, inflated by player radius24. Front movement approaches remain around y677–686. Animation pulses/scaling are anchored to the native sprite bottom, avoiding base drift.

`actor_draw_depth(position)` returns `100 + roundi(y*0.5)`. Hero updates on movement/context/restoration. The shared mole already calls a world's `actor_draw_depth()` automatically; **no mole source was edited by this agent**. Native nodes, mountains, stations, mine mouths, Hub lift, split arch pieces and effects use the same depth space. Portal transition children retain their back/front offsets relative to a depth-adjusted parent. Native parallax foreground remains above the world at z2048.

Only intact nodes collide. Actual mining removes their footprint. Regrowth waits until both hero and visible mole leave the base. Contact tests use real damage/yield functions (42/74/325 HP with the worn tool), check movement stops at intact bases, walk through the depleted base, and verify deferred regrowth under each actor.

All three contact tests passed in `surface-contact-v1`, as did all eight local gameplay approaches.

## Latest edits: not yet rendered or parsed after final changes

These were written **after** the `surface-contact-v1` runtime exited, then authoring was frozen for the user:

1. Static station/gate/mountain footprints are now built once into `surface_solid_footprints`; collision queries share those definitions and use a cheap rectangle rejection before ellipse math. This replaces per-query temporary shape arrays/dictionaries.
2. Solid sliding now projects input onto an actual ellipse tangent before the old axis fallback. It preserves forward input energy and should remove diagonal snagging around native rocks/pillars. A direct head-on input still stops.
3. Starforge received a ground footprint at station position + `(0,32)`, radii `(78,42)` including actor clearance. The Hub lift received two side support footprints, preserving its center approach. **These new shapes need the next approach matrix.**
4. Public `gate_approach_route(gate_id)` follows the real space between the arch's rear-left and front-right feet. Relative waypoints are `(-120,30)`, `(0,0)`, `(80,-22)`, `(160,-20)`, `(230,0)`.
5. `tools/review_surface_polish.gd` now advances each real gate opening for 2 seconds before freezing automatic processing. Previously its freeze left gates opening and its restore moved the player outside the blocked seam.
6. The harness's new `TERRACE_TRAVEL` paths follow the visible front lane around crystals. The previous trunk test mistakenly targeted `(2010,642)`, which is inside the newly solid Moon center node. It failed correctly. Local approaches were already passing.
7. The harness clears deferred achievement/tutorial overlays again just before capture; a queued book/blueprint feedback icon had appeared in one depleted screenshot after the earlier clear.
8. `overhaul_qa.gd` surface section now uses `gate_approach_route()` and y662 mountain approaches. Its old Ember/Star route started among moved solid resource clusters. Only these two surface lines were changed by this agent; architecture owns the other modifications in that file.

No second render or parser check was started after these edits. First continuation action should verify these changes, not assume the last candidate's pass applies.

## Owned files and shared-file limits

- `scripts/world/surface_world.gd` — full surface terrain/contact scope.
- `tools/review_surface_polish.gd` — new opt-in rendered harness, untracked until root's checkpoint.
- `scripts/world/world_catalog.gd` — only revised surface approach/bed metadata.
- `scripts/main.gd` — only public surface mine/Hub guide positions; root owns other edits.
- `scripts/qa/suites/layout.gd` — surface coordinates/steering and effective portal depth comparison.
- `scripts/qa/suites/smoke.gd` — surface mountain/resource target coordinates.
- `scripts/qa/suites/world_fixtures.gd` — surface route/resource/Hub coordinates.
- `scripts/qa/overhaul_qa.gd` — only surface gate route and mountain approach lines; architecture owns save/D1/other changes.
- This handoff.

Last `git diff --check` passed. No commit was made by this agent.

Frozen owner-file SHA256:

| File | SHA256 |
| --- | --- |
| `scripts/world/surface_world.gd` | `1ee64b908b7423912494fb251b66e897eb52e41039afe4f70227194104074421` |
| `tools/review_surface_polish.gd` | `5232637b5d8bea42b068341427ff815b2875358fc76a8786c39f90360e533d0c` |
| `scripts/world/world_catalog.gd` | `77bfb0b366595897857f011d4b228cdc85d38a7f75fc6cc7d76faa5315841c26` |

Hashes above were recorded after the last surface mutation. Shared QA files may still change under their owners before root's checkpoint.

## Next checks and exact command

Coordinate one graphical runtime at a time with root/performance. Do not run headless CPU checks during timing. Current runtime paths:

```sh
python3 tools/run_rendered_isolated.py \
  --godot /tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64 \
  --xvfb /workspace/scratch/02374ae65f32/runtime/xvfb/usr/bin/Xvfb \
  --project /workspace/scratch/5a78be25fc28/Ever-Deeper \
  --output /workspace/scratch/5a78be25fc28/evidence/surface-contact-v2 \
  --resolution 1696x780 --timeout 240 -- \
  --script res://tools/review_surface_polish.gd -- \
  --output=/workspace/scratch/5a78be25fc28/evidence/surface-contact-v2
```

The harness supports `--case=all|mountains|routes|contact` after the final `--`. `all` is needed after the unverified shared-depth/collision edits. Inspect the images, including all mountain stages, gate crossings, native foreground, Starforge/Hub approaches, and all node sides/depleted states. Correct any real travel regression rather than weakening collision or skipping its state.

Then ask architecture/root to rerun the `overhaul` case. The reported prior failure is at `evidence/schema-three-legacy-cleanup/overhaul.log`, surface arch passage Ember/Star; new D1 barrier checks had passed.

`layout.gd` still contains older generator assertions expecting a 150px cropped AtlasTexture, no external arch, and no player split. Those predate the authored 360px split arch and are stale independently of the current contact fix. The new effective-Z comparison is correct, but those remaining visual-contract assertions need proper updating to the authored arch rather than being ignored. Parser-only `--check-only --script surface_world.gd` does not initialize autoloads and can falsely report missing RunState; use project startup/QA.

## Independent critique supplied to root

Root owns all Hub/Deep changes; none were edited here.

- `relic-grounding-v4`: inspected `site_sequence_start`, `site_seal_1`, `hub_arrival_with_relic`, `hub_relic_placement_ready`, `hub_relic_placed`. Site resource exclusion and grounding are visibly better. The opaque native archive worksite is a clear improvement over the phantom unbuilt building. Actual 18-step relic journey passed under root's harness.
- Seals at 88×59 still read like dark gravel. The real `emberdeep-seal-mark.png` contains an engraved stone ring; supported root's 112×75 proposal and slightly stronger native inlay lighting while keeping the stone opaque. No generic enlarged ring is needed.
- `deep-boundaries-v1` still has a major wall projection/scale issue despite much better floor blending. Horizontal cave strips are rotated 90° on side walls, making stacked stones sideways. The authored corner PNG already includes correctly lit upright vertical legs; use those native regions with uniform, calibrated scale for straight side walls.
- Corner canvases are both 1024px but occupied stone thickness/elbow pivots differ greatly: Moss vertical leg roughly x450–800/y720–1024 with elbow near(650,400); Void vertical leg roughly x455–565/y700–1024 with elbow near(510,520). Fixed 192px full-canvas mapping creates inconsistent height and exposed joins. Calibrate native opaque thickness and elbow placement, keep actual corners complete, and avoid drawing a full overlapping corner for every stair cell. Root owns the implementation.
- Blend boundary wall material by interleaving whole opaque native modules only after geometry agrees; transparent overlapping cliffs would reintroduce ghosting. Deep walls remain the larger overall visual acceptance blocker.

