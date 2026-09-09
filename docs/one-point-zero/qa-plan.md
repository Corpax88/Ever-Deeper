# Independent 1.0 acceptance plan

Scope: the approved FULL BUILD brief only. Existing artwork, equipment, five
relic/shop identities and early gameplay remain the acceptance baseline. No new
systems are requested by this review.

## Evidence requirements

| Area | Meaningful check | Evidence limit |
|---|---|---|
| Fresh progression | Start with reset state; follow actual purchase/gate/Deepheart transactions; assert costs and goal changes at every milestone. | Accelerated material fixtures test correctness, not the hours of player pacing. |
| Continuous mining | Walk across both sides of chunk boundaries without context actions; mine ordinary walls at seams; retain absolute position, companion and rope after rebasing. | Native headless timing cannot certify rendered smoothness. |
| Infinite continuation | Visit procedural bands past relic five, at large coordinates and after save/reload; mine fresh walls and valuable resources; assert bounded active geometry. | A bounded sample cannot prove mathematical infinity; it can catch a final-room cap and coordinate exhaustion. |
| Five relics and hub | Discover each actual generated relic, attach rope, move it, return through Tunnel Home, gate placement on endpoint proximity, deliver 199+1 materials, build its existing workshop. | Direct fixture positioning does not substitute for manually judging the hauling feel. |
| Stronger upgrades | Measure real tool strikes/time, reach, pickup and light before/after relevant purchases; consume exact recipe once; preserve effects on reload. | A multiplier alone does not establish visible or audible feedback. |
| Resource goal | Compare every displayed requirement with its authoritative transaction; resource pickup updates synchronously; spending/delivery never leaves a stale ready state. | Typography, visual balance and obstructed play area require rendered inspection. |
| Save migration | Load prior active floor, partial depletion, dug cells, attached relic, completed shops and wardrobe choice; resume safely; no resource duplication or lost placed relics. | Keep compatibility assertions independent from new serialized field names where possible. |
| Touch | Use screen touch press/move/release/cancel; goal panel passes through; settings/shop modal cancels mining and movement; Tunnel Home fires once. | Browser emulation does not reproduce every physical iPhone input quirk. |
| Sustained rendering | Inspect the exact candidate at mobile viewport, terrain/corners/transition/deep relic/workshops; measure 180 seconds with lights, pet, motion, mining and menu return. | Browser/software renderer figures must never be relabeled iPhone FPS. |

## Baseline findings

- `scripts/qa/suites/endless.gd` asserts layer changes, elevator contexts and a
  fifth-shop checkpoint. Keep these historical assertions available while adding
  the distinct 1.0 contract; a green old suite is not 1.0 acceptance.
- Existing overhaul free-dig checks require exactly three strikes per wall. The
  new brief intentionally requests perceptible strength gains; test actual
  before/after performance separately and explain any reconciled old assertion.
- DEV9 physical iPhone evidence is 52.1 FPS with normal lighting and 60.0 FPS
  with pet lights off. The last restored stage was 70 seconds. This is an
  unresolved 1.0 performance gate, not a new failure caused by this build.
- The approved wardrobe portrait is already shipped and must remain intact.

## Improvement rounds and scoring

At most four rounds. Every round records concrete failures, fixes and the exact
candidate/evidence inspected. Score gameplay loop, progression feel, UX, visual
premium quality, performance and code quality from 1 to 10 only to the extent
observed; label unverified areas explicitly. Do not assign an aspirational 9.
Critical defects, missing rendered review or missing stable physical iPhone
evidence prevent final 1.0 approval regardless of averaged score.

No LIVE publication is authorized by a passing automated suite alone. DEV is
the candidate/testing destination.
