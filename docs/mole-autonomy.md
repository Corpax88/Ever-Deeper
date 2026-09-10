# Automatic mole help — DEV4

Mats requested learned skills that work without micromanagement. Routine mining,
collection and exploration now choose appropriate learned skills automatically.
The existing purchases, prerequisites, costs, art and saves remain intact.

| Skill | Behavior |
|---|---|
| Little Lantern | Existing helmet light follows the companion. |
| Fetch | Nearby loose ore goes straight to the backpack. |
| Trailrunner | Existing speed bonus applies to movement. |
| Big Paws | Existing cluster pickup reach applies to automatic collection. |
| Ore Nose | Checks every 10 seconds during available exploration, marks nearby ore and approaches reachable ground beside it. Mining cancels the errand. |
| Long Beam | Existing double light reach stays active. |
| Earthshaker | Opens up to 2×2 ordinary cells at the wall being mined, with an 8-second recharge. |
| Teamwork | Helps with one ordinary cell between shakes, with its own 2.5-second recharge. |
| Echo Scout | Points deeper during exploration. Hints last 20 seconds; standing still does not repeat them. |
| Tunnel Home | The player chooses when to go home; the mole handles the existing transport and attached relic. Never activated unsolicited. |

Automatic errands remain within 300 world units of the player. Releasing mining,
turning away, leaving or finishing the target first cancels an obsolete dig.
Successful impacts retain authored recovery frames. World authority still protects
gates, bedrock, resource deposits and tool/progression restrictions. Menus pause work.

Manual commands remain optional and have a brief uninterrupted turn. Routine speech
is limited to one reaction per eight seconds. Decisions run every 0.30 seconds and
unreachable path searches retry at most every 0.9 seconds. No new lights, particles
or per-frame terrain scans are added. Physical iPhone FPS is not established.

## Verification and publication

The `mole-autonomy` QA case exercises 50 checks through real world, collision,
animation, collection and accounting code. It covers four directions, independent
cooldowns, cancellation, menu pauses, restrictions, optional commands, fetching,
ore discovery, Echo, staying close, feedback limits, bounded pathfinding and
natural Depth 2/The Deep terrain. It joins the ordinary and exported-package gates.
`tools/review_mole_autonomy.gd` captures actual autonomous work and all revised
journal pages from the exported DEV package at a mobile viewport.

On 2026-09-10 Mats explicitly approved uploading this DEV4 change to public
`Corpax88/Ever-Deeper` and using the normal flow for future work. This resolves
the previous automatic approval rejection. The source workspace was pruned before
upload; this implementation was reconstructed from the same conversation and is
revalidated as a new commit, not represented as the lost commit's identical bytes.

Normal flow: upload the source branch; complete all six existing DEV validation
jobs; inspect final-package images; update the exact artifact review receipt;
publish DEV and verify all nine DEV files while preserving all existing LIVE files.
The unreviewed receipt cannot publish. Final LIVE 1.0 approval remains separate.

Phone test after publication: use learned Earthshaker/Teamwork and hold Mine in
Depth 1, Depth 2 and The Deep without touching the mole. Stop, turn, walk away and
open a menu. Explore near ore and loose drops. He should help and rejoin you.
Play at least three minutes with normal lighting and SHOW FPS enabled.
