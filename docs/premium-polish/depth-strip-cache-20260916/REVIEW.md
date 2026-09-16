Adoption note: the reviewed runtime and evidence were restored into the canonical work branch after the interruption. This bounded correctness and modest moving-cost improvement does not satisfy the minimum-50-FPS goal.

# Isolated Depth 2 strip-cache study — 16 September 2026

Base: `0623b63bc9ddb449c8b46d98e483c6b164a619f9`.
Study branch: `codex/depth-strip-cache-study-20260916`.
Nothing here is merged into the canonical checkout or published.

The runtime change narrows Depth 2 terrain-cache invalidation to each existing
six-cell strip. Its one-cell halo includes HP and chamber concealment; local
ordered mineral hints include depletion, gating, type and discovery. A rebuild
identity invalidates reused strip keys when a mine or its assets/layout change.
The whole-world `_terrain_draw_fingerprint()` remains unchanged for its separate
`CaveLightOccluders` caller. Gameplay and all native art are unchanged.

## Actual rendered result

Three fresh, serialized Godot 4.7.2/llvmpipe processes rendered at 1696×780.
Each completed 27 warm-cache/fresh-draw pairs. The candidate passes every pair
with exact RGBA equality. All 27 fresh images also match exactly across all
three runs; source hashes, starting terrain and recorded light inventories
match. `comparison.json` independently recomputes timings and all image pairs.

The controls deliberately retain an existing cache dependency omission: after
the diagnostic toggles covered ore's `drill_gated` flag back off, its hint is not
redrawn. Both controls differ at the same 330 pixels (bounds 788,299–810,322;
maximum channel delta 76). The candidate updates two sections and exactly
matches fresh drawing. This is a direct-state fixture finding, not evidence of
a player-reported live failure. Both complete controls retain failed verdicts
and exit 4; only the candidate reports a successful completion and exit 0.

The first reference run stopped at this mismatch after 14 pairs. Its incomplete
report is retained as `depth-strip-A.json`. Its `terrain_hash_at_start` field was
actually sampled after timing; it is not used for A/B provenance. The subsequent
harness records starting/ending hashes separately, preserves every discrepancy
in its report, completes the remaining independent cases, and still exits
nonzero if any case fails. `FINISHED` records completion; `COMPLETE` records
successful completion. Neither a failed control nor an incomplete run is green.

## Bounded timing and limits

This is a 20-second frozen one-cell HP-change diagnostic at 5 Hz, with every
frame retained. It isolates redraw cost; it is not sustained gameplay.

| Measurement | Reference A | Local B | Reference A2 |
| --- | ---: | ---: | ---: |
| Actual seconds | 20.000010 | 20.005653 | 20.015118 |
| Frames | 838 | 888 | 914 |
| FPS | 41.899979 | 44.387454 | 45.665481 |
| Frame p95, ms | 33.060 | 27.403 | 30.385 |
| Terrain redraws | 24,948 | 594 | 24,948 |
| Setup CPU, microseconds | 144,739 | 174,795 | 138,353 |
| Draw callback CPU, microseconds | 739,820 | 127,831 | 726,401 |
| Combined setup/draw CPU, microseconds | 884,559 | 302,626 | 864,754 |

The narrower cache reduces measured setup-plus-draw CPU by about 65%, including
the increased signature setup cost. P95 is lower than both controls. Average
FPS does not beat the second control, so this does **not** establish a causal
average-FPS gain. Moving ordinary excavation is measured separately below;
physical-device FPS remains open.

The actual mutation cases redraw 28 versus 252 terrain sections for the
entry's real hit, 12 versus 252 for pet digging, and 2 versus 240 for resource
depletion or respawn. New camera coverage still creates/reconfigures sections:
the far-camera case redraws 294 in every variant. This preserves required work.

## Moving real-time Ember excavation

The same native renderer and viewport ran a fresh reference/local/reference
triplet, **60 seconds per run**, with one renderer at a time and no Blender,
source-gate job or archive compression overlapping the measurements. All three
processes exited 0 with `PREMIUM_SESSION_COMPLETE ... functional=true`.
`live-comparison.json` independently recalculates every frame and verifies
observer/runtime hashes, reported timings and progress. The unchanged original
session harness is extended only into a generated script outside the project;
the production runtime gains no testing branch or input override.

A read-only planner drives ordinary Main joystick and held-mining methods
toward nearby walls, following existing floor through normal physics. It makes
no terrain edits and uses no teleport, freeze or forced stepping. Every one of
the **18 ten-second windows** travels 1,960–2,043 world pixels, mines 168–329
resources and removes 167–320 terrain cells. This is ongoing excavation,
unlike the stalled final 90 seconds of the prior five-minute Deep session.

| Measurement | Reference A | Local B | Reference A2 |
| --- | ---: | ---: | ---: |
| Actual seconds | 60.027519 | 60.018642 | 60.025235 |
| Frames | 2,443 | 2,491 | 2,433 |
| FPS | 40.698 | 41.504 | 40.533 |
| Frame p95, ms | 32.699 | 30.172 | 32.690 |
| Frame p99, ms | 41.080 | 35.485 | 38.405 |
| Distance, world pixels | 12,033 | 12,041 | 12,001 |
| Mined resources | 1,583 | 1,579 | 1,559 |
| Removed terrain cells | 1,554 | 1,550 | 1,532 |

The observer starts cache profiling before the four-second warmup, so its
cumulative totals are not a clean 60-second delta. Subtracting the first
measured snapshot from the last yields these **last-five-window** counters:

| Measurement | Reference A | Local B | Reference A2 |
| --- | ---: | ---: | ---: |
| Counter interval, seconds | 50.009470 | 50.005991 | 50.018112 |
| Terrain redraws | 33,032 | 3,646 | 32,564 |
| Setup CPU, microseconds | 1,233,547 | 1,721,805 | 1,233,681 |
| Draw callback CPU, microseconds | 1,969,429 | 1,348,032 | 1,951,925 |
| Combined setup/draw CPU, microseconds | 3,202,976 | 3,069,837 | 3,185,606 |
| Combined CPU, ms per elapsed second | 64.047 | 61.389 | 63.689 |

Terrain redraws fall about **89%**, but local signature setup costs about 40%
more. Combined setup/draw CPU falls only **3.6–4.2% in moving play**. The frozen
diagnostic's 65% reduction must not be generalized to real excavation. This
single triplet observes a 2.0–2.4% FPS increase and lower p95/p99; differing
real-time trajectories and one software renderer do not establish a general
or physical-device FPS gain. None of the three passes the minimum-50-FPS gate.

All runs share exact generated-observer and runtime bytes, seed, renderer and
resolution. Each makes 79 route plans; total planner CPU is 11.1–11.4 ms and
its longest call is 421 microseconds. The observer and report writes stay in
the frame intervals. There are no script/runtime errors, but existing
Dummy-audio sample warnings occur 169/167/167 times and remain included in
timing. `Performance.TIME_PROCESS` is not exclusive script CPU and is not used
to attribute this result. All mined resources reconcile with the six windows;
the first route target records zero previously mined resources.

The candidate's initial/final and restored control's final full-size PNGs were
inspected. They show the entrance and subsequent excavation, hero, pet, native
terrain, lights, resources and ordinary HUD. Live trajectories differ slightly,
so these screenshots are not pixel-parity claims; the separate 27-state
warm/fresh study supplies that check. This remains bounded terrain-cache
validation, not overall game-feel, animation or premium visual approval.

## Verification and inspection

- Candidate warm/fresh coverage: real hit, Crusher, pet, chamber concealment
  and discovery, resource depletion and respawn, mineral-hint flags, direct
  strip-boundary HP/concealment changes, camera/zoom/cache recycling/offscreen
  changes, and all four Depth 2 native mine profiles.
- Actual full-size images inspected: reference hit; candidate restored mineral
  hint, revealed strip boundary and Starfall mine-switch view. Exact full-frame
  comparisons cover all 27 states in all three runs. These are terrain-drawing
  checks, not whole-game art or animation approval.
- Serialized source gate: **15/15 pass**, explicit markers, no runtime errors.
- Protected-file check: only the prior `scripts/player/player_visual.gd` hash
  mismatch. No hashes were refreshed.
- Raw PNGs/logs are under `/workspace/scratch/4e99473f21fc/evidence/depth-strip-*`.
  Their independent comparison is retained here; root owns the private archive
  checkpoint containing the full evidence.

The candidate is ready for root review on the strength of exact rendered
cache correctness, reduced redraw work and bounded real excavation. A modest
measured cost improvement is supported; physical-device performance, the
minimum-50-FPS target and whole-game acceptance remain open. No release or
canonical merge is authorized by this study report itself.
