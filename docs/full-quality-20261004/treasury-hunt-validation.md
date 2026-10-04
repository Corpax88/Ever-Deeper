# Tracked-material hunt validation

The new post-victory hunt keeps the established 100,000-unit collection goal and the initial 350–450 base units per rich deposit. The measured route is feasible with three different endgame tool choices. This is a simulation result, not a measured player session or a judgement that the hunt is fun enough for 9.5/10.

## World and save evidence

The isolated overlay uses the verified DEV15.54 package and seven explicit source overrides. Its final package SHA-256 is `847285e3748fd928663a537165b421ff46569d0100ddaa53c91ab0428f95bae7`; its receipt is in `evidence/treasury-phase2/package-receipt.json`. Native and rendered world gates both pass all 105 assertions. Nine generated windows preserve ordinary geology, ore, sites and relics while adding three bound deposits per band. Tests exercise all seven materials, reveal-before-extract, real mod and mole interactions, loose pickup, save/load, repinning and stream rebasing. The separate save-authority gate passed 40 assertions; an independent adversarial review passed 27.

All 21 rendered images were inspected individually: covered, revealed and dropped states for each material. Covered nodes remain hidden. Revealed nodes and physical drops use their corresponding authored material assets. The nearby text remains legible with the longest name, Singularity Core. The final image paths and SHA-256 hashes are recorded in `evidence/treasury-phase2/render-manifest.json`. These 2328×1260 native captures establish artwork and state visibility; current mobile WebKit verification belongs to the full candidate gate.

## Measured route

`tools/review_treasury_hunt_rate.gd` drives the actual player collision resolver, real tool cadence, stamina/training and physical pickup in fixed 1/60-second steps. It knows the locations of rich deposits and uses cardinal A* waypoints around permanent terrain and grounded ruins. It neither teleports nor pre-excavates the route. The test uses seed 77411, valid placed relics, Forge level 5, Treasure Chamber level 1 and initial mining/running/prospecting levels 25. The pet is recalled. Search, navigation mistakes, return travel and donation are excluded.

| Tool configuration | Collected Rootiron | Deposits picked up | Final band | Simulated movement/mining/pickup minutes |
| --- | ---: | ---: | ---: | ---: |
| Crownseeker | 100,009 | 124 | 42 | 13.63 |
| Crusher | 100,313 | 250 | 84 | 13.88 |
| Comet with earned Corebreaker | 100,316 | 250 | 84 | 14.34 |

All three finish with Forge level 5 intact and depleted stamina; ordinary effort penalties were applied. Deposit count and the final pickup are included. Small Prospecting yield variations do not change the observed route completion times. Results and per-deposit progress are retained in `evidence/treasury-phase2/full-rate-final.json`, with the success marker in `full-rate-final-log.txt`.

The earlier six-band sample is retained but is not valid evidence for constant Forge level 5: its fixture set only `placed`, so normal save sanitization correctly removed an unearned relic prerequisite. The first full run also stalled because the straight-line solver pressed against a grounded ruin outside its mining aim; diagnostics show zero movement, no active mining and a distant target. The corrected route completes all three hunts through real collision without changing production collision, ore placement or yield. Both the incomplete run and diagnostic log remain beside the successful result. This was a solver defect, not evidence that deposits were unreachable.

## Balance decision and remaining gate

Retain the initial yield revision. Crown trades slower strikes for twice the material; Crusher and Corebreaker travel more bands but excavate faster. The similar ideal-route times suggest meaningful alternative choices, rather than one compulsory tool. They do not establish a 15–35-minute human completion time. An unassisted mobile hunt is still needed to judge discovery clarity, fatigue, search effort and whether 124–250 repeated deposits remain enjoyable. No additional reward multiplier, early-game recipe change or generic replacement mod is justified by these measurements.

The completed generic collection follow-up separately passes 12 checks (`evidence/completed-collection/checks.json`): the final capped donation clears only its matching pin, complete collections cannot be re-pinned, stale saves retire their pin, ordinary cargo/cap behaviour stays intact, and a completed unclaimed mod still guides the player to claim it.
