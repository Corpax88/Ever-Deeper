# Fourth premium-polish milestone — 15 September 2026

Work in progress after source `4e1bb94531318ebe7a68d2ccd6eddf9a6df9bae7`.
No deployment. No overall 9/10 or sustained 50-FPS acceptance.

## Actual gameplay changes

- One world-deactivation owner replaces 17 repeated world lists. Entering Deepheart
  previously left The Deep visible/active in a direct transition. Actual captured
  gameplay exposed that overlap; the chamber now has one active world.
- Deepheart retains its final committed swing after a seal opens. Hiding MINE
  releases its touch, which previously cut recovery off on the following frame.
  Post-impact recovery now survives this UI release; actual movement cancels at once.
- Flat seal plates are replaced by the existing full native brass/stone pedestal.
  Crystal bottoms meet their tops. All four stations occupy the clear forecourt,
  with collision footprints, front approaches and depth relative to the hero.
  The core's stone foundation blocks feet while its staircase remains accessible.
  Restored positions are moved to nearby clear decking if they intersect hardware.
- The machine stays rigid. Prototype lines crossing the floor and machine are gone;
  transient soft motes carry each resonance above the hardware to its intake.
  The same five fixed lights remain, with restrained finale exposure.
- A separate camera eases into a complete view of the machine, seals and bridge.
  Gameplay HUD is suppressed during the finale and restored on return to play.
  Rotation pauses/resumes the sequence; leaving the conclusion after rotation
  reactivates the chamber and controls. Hidden menu controls cannot interrupt it.
- Hub workstations sit against cave walls with varied wall overlaps, soft contact
  shadows and light placed at their thresholds. Critics still want connected work
  foundations and a better floor/hero/workshop lighting balance.
- The retired HTML runtime and its old tests/tools are deleted (21 tracked files,
  over 15,000 lines). History retains them. Two dead chest assertions/fixture calls
  are removed. Active code, scenes and assets contain no chest-system references.
  Existing relic/cache systems still have gameplay functions and are retained.

## Rendering: accepted change and rejected experiments

`lit_visible_pixels` discards only exactly zero-alpha samples before lighting.
It retains filtered fringes, native texture resolution, geometry, shadows and
explicit/inherited materials. It adds no atlas or secondary render target.

Controlled local A/B/A uses the same frozen scene with default lighting, the new
material, then the default again. This is Mesa llvmpipe, not physical-device proof:

| Area | Default FPS | Visible-pixels FPS | Restored FPS | GPU medians, ms |
| --- | ---: | ---: | ---: | --- |
| Deep | 40.44 | 44.88 | 41.01 | 19.26 / 17.16 / 18.84 |
| Ember D2 | 41.34 | 41.96 | 40.31 | 18.84 / 17.64 / 18.90 |
| Built hub | 38.40 | 40.11 | 38.20 | 20.76 / 19.50 / 20.54 |

The paired pixel reports retain excluded animated marker/minimap rectangles and
baseline animation differences explicitly. All compared native-world pixels that
are identical across the default controls are identical with the new material.
The live Deep profile remains only 39.8–42.8 FPS. Do not call this a 50-FPS pass.
Reproduce with `tools/review_visible_pixels.gd -- --output=... --area=deep|ember|hub`
under `tools/run_rendered_isolated.py`.

Rejected trials are retained as reports, not parallel runtime paths:

- Frozen 2× albedo cache: about 39→55 FPS, but stone gradients lost 12–15%, initial
  bake cost ~374 ms and video memory rose ~85 MB. Rejected for fidelity and cost.
- 3× cache: about 38→44 FPS and much more memory. Native gradients still softened.
- Native edges over 2× base: about 39→38 FPS. Reconstruction filter: about 38→40.
- Exact-pixel native texture atlas: draw calls 188→149 but FPS 39.7→38.6 and ~90 MB
  extra memory. Trim-only bounds gave no reliable gain. Neither is in gameplay.

The experimental implementations have been removed from the repository. Their
small rendering-only split of permanent-wall drawing was also removed.

## Sustained performance still fails

Actions run `35028787739` tested source `4e1bb94531318ebe7a68d2ccd6eddf9a6df9bae7`
for 300 seconds per area with autosaves and companion. Functional results pass.
All strict sustained 50-FPS results fail:

| Area | 30-second window average FPS | Worst p95 frame, ms |
| --- | --- | ---: |
| Built hub | 41.401–55.450 | 53.460 |
| Ember D2 | 25.466–31.947 | 70.981 |
| Deep | 20.111–22.023 | 100.133 |

Source-bound reports are `../session-review-20260915/mac-cached-*.json`.
The renderer is ANGLE Metal on an Apple Paravirtual device. GPU time is unsupported
and reported as zero; it is not zero GPU cost. These are not iPhone results.

## Verified scope

- Full current source gate: all 15 cases pass after the room/world/shader changes.
- Six affected source cases pass after the cinematic-camera/UI changes.
- Rendered contact/approach harness verifies real held movement into all four
  stations, normal/final impact, final follow-through after MINE hides, a reachable
  core, whole-machine framing, camera progression, orientation pause/resume,
  conclusion return and clear-ground position recovery.
- Shadow fixture has 26 candidate/reference pairs, including maximum 440×1.4
  pet range at 892–969 px distance and two cell crossings. The eight maximum-range
  static-world comparisons are exact outside animated UI/markers. Two additional
  captures enable the candidate's real priority-100 processing and move emitters at
  priority 0; rebuilds occur before the first presented moved frame.
- Existing protected invariant gate: 1,095 protected files / 57 QA entries pass.
- Native gait C: 192 real Blender frames, four directions. Numeric reports explicitly
  distinguish 35,376 sampled IK poses from rendered/evaluated meshes. Raw boot sole
  support has near-zero slip; evaluated bevel support differs by at most .001095
  native units. These do not certify gameplay motion or transitions.

The JPGs are convenient overviews of inspected 1696×780 captures, not pixel-proof
inputs or replacement assets. Numeric/pixel reports come from lossless PNGs.

## Critic result and next work

Deepheart reaches **9/10 visually** in the final room captures. This is deliberately
limited to that room. Hub is 7.5/10, surface 7.5/10 and Deep about 6.5/10.
Gait C is 7.5/10 as an isolated continuous run. Production v28 atlases are unchanged.

1. Continue performance work with the current source on an actual device/renderer.
   Shadows and lighting remain substantial costs; no quality-reducing cache passed.
2. Give native idle/run/mining the same heading (C-up currently differs by ~44.5°).
   Implement phase-aware, foot-contact-preserving C1 transitions and forward-only
   drill coast. Soften early toe lift and add delayed body/tool load response.
3. Build continuous support beneath Ember/Starfall surface branches; they currently
   read as narrow floating ribbons. Integrate hub workshop foundations with wall/floor.
4. Improve the Deep's repeated right-angle excavation silhouette while preserving
   approved native rock material. Capture actual large excavations, all four surface
   mountains at full/half/depleted states, and relic before/active/return.
5. Exact exported mobile and physical iPhone long-session acceptance remains open.
   Do not publish this checkpoint as finished premium polish.
