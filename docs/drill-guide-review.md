# DEV7 drill guide author review

Source: `0bdad8b065dc38b0e8f65414e3756968f8417878`.
Candidate run: `34723555713`. Artifact: `10307350837`.
This review is limited to the reported post-drill progression fault.
It is an author review, not an independent critic assessment of the full game.

## Gameplay and save behavior

The primary guide's any-ore fallback was incorrect for a specific drill recipe.
Matching loose loot now takes priority, then matching live ore, then a matching
regrowing node. Depleted or unavailable required ore cannot target Rootiron or send
the player outside and immediately back into the same mine. The HUD distinguishes
collection and regrowth; an actually missing source clears the marker.

The ore shortage was separate from target selection. The four Mossvein barriers
contain twenty Burrowsteel pieces, while Pulse Drill needs sixty Burrowsteel.
The fix preserves the permanent barrier records and creates separate ordinary
ore nodes from the original authored gate definitions after opening. Moonhollow
Phasecrystal and Emberdeep Infernium receive the same correction.

Save identity uses the original definition index, independent of the order in
which barriers are opened. The existing depletion validator checks the underlying
authored gate and resource. Repeated reconstruction cannot append duplicates.
Ore retains drill and pickaxe requirements, uses real damage and drops, and cannot
claim pocket rewards. Existing cleared saves recover without resetting progress.
Mining rewards and respawn timers remain in the existing transaction system.

## Automated evidence

All fourteen active suites pass locally and in both the source and exact-package
CI gates. The packaged overhaul suite passes 1,240 checks. Small WebKit passes
1,248 gameplay and 195 touch checks. Counts vary slightly with actual randomized
ore yield because the supply test stops after collecting the required quantity.
Both browser audio checks pass without reported errors. The existing hero-motion
check passes. All 1,139 protected files retain their expected hashes, and all eight
publication-protection tests pass.

The candidate ZIP was downloaded and verified against its GitHub artifact digest:
`c4feaae44d10d9e20ecb1fa738a7fda57bbab8a0ac1b91cc8b8a58248e347ab0`.
The exact PCK hash is
`a3885cc33cc80174d961df0c2149180e6b9ea7cb2f63158b6c4302bdc9329dd6`.
The manifest hash is
`b7d57c8ac0091dd4b76fde4f2847af8fc6d83be3cd7e1b0152f6bf01180cfb1b`.
Raw validation reports are preserved in `drill-guide-evidence/`.

## Visual acceptance and limits

All six candidate jobs pass. The original native review has 773 passing assertions,
74 journey captures, seven companion captures and 75 light-receiver stages.
Its 553 MB artifact exceeded the connector's 512 MiB download limit. Extraction
run 34724163674 verified the original ZIP digest and copied its exact guide images.

Initial images were rejected for fixture framing and stale frozen-world drawing.
Supplemental run 34724395802 correctly failed its new player-centering assertion.
The cinematic camera was still processing independently of the frozen world.
Run 34724599588 fixed that; the final run additionally stages the player within
72 world units of the ore and asserts that the local guide target stays visible.
No gameplay, camera implementation or candidate bytes changed during this work.

Accepted supplemental run: 34724674299; artifact: 10307531703. All 190 assertions
and eighteen captures pass, using the same PCK hash recorded above. The author
inspected all nine 844x390 states plus the three 2532x1170 renewed-ore images.
The small states cover Mossvein's barrier, renewable ore, pickup, regrowth and
next-mine route, plus intact and opened barriers in Moonhollow and Emberdeep.
The requested ore markers and Collect/Regrowing labels agree. At 60 Burrowsteel,
the HUD changes to Moonhollow/Moonglass Depth 2 and the arrow points to the exit.
The Emberdeep fixture still needs Phasecrystal, so its outbound route is expected.

These are deliberately magnified 2.5x detail fixtures with a static test camera,
not evidence of normal gameplay camera framing. They preserve the existing ore
PNG materials and silhouettes, floor textures, barrier art and biome lighting.
The close-ups magnify the existing hero and overlap some world art with the HUD;
normal mobile input/layout remains covered by the separate WebKit package test.
No art substitution or production camera change is included in this fix.

Bounded author DEV readiness: 8/10, with no critical issue reproduced in the tested
paths. This is not an independent critic score or final 1.0 acceptance. Raw native
reports retain their original `visual_review_pending` fields; the subsequent
inspection and twelve exact image identities are recorded in review-index.json.

Respawn clocks and campaign prerequisites are accelerated in the test fixtures.
These checks establish supply and routing, not human pacing, physical iPhone FPS
or subjective audio quality. Known legacy failures remain in `verification.md`.
The Mole's independent nearby-ore scout is unchanged.

DEV publication is approved for the exact reviewed artifact. Its rollback baseline
is the verified DEV6 receipt, and all nine LIVE
0.46.9 files must remain identical. No new LIVE release is approved here.
