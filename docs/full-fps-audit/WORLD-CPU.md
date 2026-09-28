# Ever-Deeper FPS round 2: world / companion / UI audit

2026-09-28. Read-only source audit plus isolated QA candidate. The parked native
depth-prepass candidate is untouched. No runtime source, release, or public build
was changed by this agent. No measured performance gain is claimed yet.

## Source provenance

Public DEV15.16 is immutable `surface-probe-candidate`, run `36380070907`.
The exact downloaded PCK lives at `baseline/index.pck` in the shared scratch root.
The `.github/surface-light-probe/build.py` chain preserves the game source from
DEV15.10 (`ab0c12ff579134e0a092946bd92973e4599a073c`) except the explicitly named
audio/UI/native-motion/training changes in later pack patches.

- `scripts/main.gd`: public PCK resolves to raw `scripts/main.gd`; byte-identical
  to the current checkout.
- `scripts/state/run_state.gd`: public PCK resolves to raw source; byte-identical
  to the current checkout and `.github/skill-level-up/run_state.gd`.
- Surface and companion still resolve to original compiled `.gdc` entries. The
  root surface and companion source are byte-identical to the DEV15.10 source;
  no later patch in the traced chain replaces either owner.
- Companion source SHA256:
  `5c485b1e41ad40fe6c71368c7824b92932bc9a1f0114e732ed1300b9e6d7be73`.
- Exact active companion PCK entry `scripts/companion/mole_companion.gdc`, 21195
  bytes, SHA256 `5fe20072148eea2f9f8970bfca594a511f89a1fd71561e11417f0460b81e4067`.
- Original remap SHA256:
  `ac73e224f4fe5b2f676b549a8ff565d72d014dfbab8fb31d2696482d18572946`.

## First candidate to measure: repeated companion path collision queries

Active methods: `scripts/companion/mole_companion.gd:_path_to` (line 570),
`_blocked` (465), `_segment_clear` (476), `_move` (492), `_move_task` (537);
`scripts/world/surface_world.gd:_surface_collides` (4529), `_is_on_surface_route`
(4796). Line numbers refer to unchanged original source.

The breadth-first search can expand 2600 cells. Each candidate is checked at its
center, then checked again through the segment validator, which samples every
12px. Neighbour expansions query identical centers and intermediate points
repeatedly. Each real surface collision query traverses live resource nodes,
static ellipse footprints, route bounds/segments, and relevant portal boundaries.
An obstructed companion can request another search every 0.9 seconds.

The proposed cache exists only during one synchronous `_path_to` invocation,
keys exact `Vector2` points, and discards every entry before returning. It keeps
the original search body, frontier order, collision answers, route output, direct
following, animation, and world appearance. There is no cross-frame or persistent
geometry assumption, and no change to collision shape sizes or path grid size.
This is distinct from occupancy revision/shadow geometry caching: it reduces
redundant CPU collision queries during pet navigation, not lighting rebuilds.

Artifacts:

- `world-candidate.py`: `transform(text) -> str` with exact source hash guard and
  exact immutable PCK entry identities. Adds `qa_world_cache_enabled` (false by
  default), `qa_world_reset_counters()`, `qa_world_snapshot()`.
- `world-cpu-fixture.gd`: `run(main)` after normal surface setup. Seven surface
  route/resource/mine-approach cases, including an unreachable destination, run
  A/B/B/A. It compares exact `Array[Vector2]` results, records elapsed helper CPU,
  query/evaluation/hit counts, verifies empty cache on every return, and restores
  the temporary position and existing diagnostic counters.

The original `_path_to` body is textually byte-identical after renaming its entry
point. Cache misses always use the original `_blocked` body.

### Required interpretation

Forced-search microbenchmarks do not establish gameplay FPS improvement. Record
`qa_world_snapshot()` during ordinary surface travel and mining, especially the
same area where the phone slowed. If natural windows have zero searches, this
candidate cannot explain those windows. Prefer a normal movement route with
actual obstructed companion following, and retain frame outliers. Compare full
FPS only after the counter proves meaningful work occurs. A stationary idle
surface slowdown has a different cause unless the pet is repeatedly navigating.

Cache invalidation is bounded by the synchronous call itself. Later validation
should repeat a route after node destruction/regrowth or portal state changes and
confirm that the changed geometry is read afresh. No gameplay mutation can occur
between the calls of one non-yielding search.

## Lower-priority observations

### Duplicate close-companion pose update

`mole_companion.gd:_update_companion_actions` ends with `_draw_pose()`. On a
following frame where the hero is inside the 50px stop radius, `_physics_process`
then performs supplemental separation `_move(delta)` and calls `_draw_pose()`
again. `_draw_pose` writes the texture, atlas frame, scale, position, rotation, and
lamp direction. Only the final pose can reach the renderer in that physics tick.
The minimum change would defer the first pose write to the end of the owner tick
while preserving early-return states. However ordinary settled following rests
at the 64px comfort distance, where only one call usually runs; therefore this is
not a strong sustained-idle candidate without real counters.

### HUD layout allocations

`GuideOverlay._draw` asks `safe_rect_for_viewport`, which calls
`PremiumHud.layout_snapshot -> _layout_metrics`, building a 17-entry layout
dictionary at the overlay's 30Hz redraw rate. The metrics are purely arithmetic;
there is no display-server query or control rebuild in this path. Caching the
safe rectangle by viewport dimensions and progression row count could preserve
all visuals, but expected savings are small. Profile before promoting it.

`ProgressionGoalPanel.present` duplicates goal data and assembles a row signature
at 5Hz and state-change notifications, but `_rebuild_rows` only runs when the
signature changes. No evidence of an unbounded per-frame control leak was found.

## Findings that are already handled or not new

- All six world owners disable their entire subtree through
  `PROCESS_MODE_DISABLED` when inactive. Ordinary hidden-world simulation is not
  an unguarded candidate in the inspected source.
- Surface portal ticks already use `needs_runtime_tick`, with distance and gate
  state guards; unlocked nearby visuals are throttled to their visual interval.
- Surface ambient creatures/drifts already cull by position and update at 30Hz.
  Surface parallax culls at 0.12s and avoids tracking transforms below its epsilon.
- Offscreen resources already use a 0.25s passive cadence; active resource
  mountains/timed veins use a 30Hz visual tick. Continuous regrowth bookkeeping
  still runs, but only across a small fixed collection.
- Material sprays are capped at 30 nodes and live for 0.46–0.58s. Loose resources
  have a 50s lifetime and the existing cross-source budget. There is no source
  evidence of unbounded surface particle growth during ordinary idle play.
- `_apply_mountain_stage` already stops shader parameter changes outside actual
  stage transitions. Replacing it with a new cache would mostly duplicate its
  existing guard.
- Autosaving remains synchronous on the six-second batched cadence during
  running/mining XP changes. This is already documented as unresolved in
  `docs/performance-diagnosis/dev15-6/HANDOFF.md`, and earlier save-cost work exists.
  It must not be advertised as a new discovery. Many performance fixtures disable
  persistence, so only direct timestamped save spans in ordinary gameplay can
  settle whether it causes the phone's isolated stalls. It does not explain
  continuous 40FPS without supporting measured save duty cycle.

## Validation performed in this audit

Read project rules, code map and active build chain; compared owner bytes against
DEV15.10 and inspected exact public PCK remaps. Python transform/source identity
and original search body preservation passed. Godot 4.7.2 local parse attempts
initially found a missing executable bit; after fixing the bit, the recovered
binary exited139 before output. This is an environment failure, not a passing
parser check. The combined Mac runner owns actual parse/runtime validation.
