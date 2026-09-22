# Skills DEV15 independent review — round 2

Reviewed `/workspace/scratch/15556b9375f7/runtime/skills-native-v2/skills.png`
and its native log, then the corrected map and training integration source.

**Code/state integration: 8.3/10. Narrow Skills screen visual fidelity: 8.0/10.**
The rendered Skills screen clears this narrow visual review. This does not certify
all game visuals, final exported web bytes, touch behavior, or physical iPhone FPS.

## Closed findings

- The skill icons now have their own square frames. The text/progress hierarchy
  reads clearly and progress captions clear the row borders in the V2 image.
  Copper remains more textured than the approved target, but the hero, mole,
  warm cave, serif type, framed rows and principal composition are recognizable.
- `scripts/ui/miner_skills_panel.gd:show_map()` now disconnects the embedded
  minimap's `_apply_layout` viewport callback. An isolated Godot probe emitted
  the viewport `size_changed` signal with the embedded map open; its rectangle
  remained `[P: (32.0, 94.0), S: (447.632, 480.0)]` before and after. This verifies
  the previously conflicting callback no longer overwrites panel placement.
  It is a callback/layout check, not a physical orientation capture.
- `scripts/progression/miner_training.gd` now samples in `_physics_process`
  at `process_physics_priority = 100`, after the default-priority players.
  This fixes the mismatched render/physics sampling boundary. No extra frame
  work or per-frame save writes were introduced.
- `git diff --check` passes. No additional concrete save/state blocker found.

## Small remaining improvements

- Increase the close button hit area from72 design pixels to at least82. At a
  typical844×390 CSS landscape viewport, its current hit size is approximately
 39pixels, smaller than a44pixel touch target. Its visible art need not grow.
- The ambercore thumbnail is still very small inside its assigned area. Copper
  highlights are busier and lunacore is more purple than in the reference strip.
  These are remaining visual differences, not a claim of exact pixel parity.

## Evidence limits

The V2 native log ends with `MINER_SKILLS_COMPLETE 30`; its assertions use direct
methods/signals. Actual touch routes, short real movement/mining and low-stamina
behavior remain the appropriate narrow integration checks. Inspect the exact
final exported candidate at the mobile viewport before publication, as required
by AGENTS.md. Physical iPhone smoothness remains unverified here.

The usable executable for the isolated probe was
`/tmp/ever-deeper-skills-tools/Godot_v4.7.2-stable_linux.x86_64`; the earlier
workspace copy was merely truncated, not evidence of a game defect.
