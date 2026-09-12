# Post-drill resource guide — DEV7

Mats reported the primary guide marking Rootiron after obtaining Burrower Drill,
although the next Pulse Drill recipe requires Burrowsteel, Prismite and Lunacore.

## Cause and correction

`main._depth_guide_proposal` fell back to all unbroken ore when none matched the
current requirement. It now returns only matching pickups, mineable matching ore,
or matching renewable ore awaiting regrowth, in that order. The HUD identifies
pickup and regrowth actions; a missing source never sends the player to unrelated
ore or into an exit/reentry loop. Other-mine requirements still route to the exit.

There was also a supply dead end: Mossvein's four permanent drill barriers contain
20 Burrowsteel pieces, while Pulse Drill requires 60. Permanent barrier progress
removed their old regrowth source. Each opened gate now retains an ordinary ore
node at each original authored position, using the existing production ore PNG.
The original barrier stays cleared; ore uses ordinary tool damage and respawn.
This also restores the same renewable supply for Moonhollow and Emberdeep gates.

Stable `seam:rock:<definition index>` IDs use the existing resource depletion save
records. The validator accepts these IDs only for authored drill-gated nodes.
Newly opened gates wait for normal regrowth before their first ordinary ore spawn.
Previously cleared saves recover the ore automatically when rebuilding Depth 2.
No inventory credit, recipe change, asset replacement or save reset is involved.
Seams cannot repeat pocket rewards. Rebuilding cannot duplicate the seam nodes.
The Mole's general Ore Nose is a separate nearby-ore scout; it remains unchanged.

## Verification and publication

Local: all 14 active suites pass, including 1,236 overhaul checks; all 1,139
protected files retain their expected hashes; eight release-protection tests pass.
Regression coverage mines through real tool damage, collects actual drops,
reaches the 60-unit quantity, checks all twelve gates, and reloads depletion.
Respawn clocks are accelerated in fixtures; these checks do not measure pacing.
Guide tests cover exact resource identity, pickup priority, regrowth and no source.

Candidate source: `0bdad8b065dc38b0e8f65414e3756968f8417878`.
Candidate tree: `2825889deb8ad9b6cc5590ef990c8988433a61e7`.
Validation run: `34723555713`. Pull request: 17.
The initial run 34723443535 was superseded to seed the render fixture's completed
campaign prerequisites before testing the post-drill objective.
All six candidate jobs pass. Exact candidate artifact: 10307350837, PCK SHA-256
`a3885cc33cc80174d961df0c2149180e6b9ea7cb2f63158b6c4302bdc9329dd6`.
WebKit passes 1,248 gameplay and 195 touch checks. Original native review passes
773 assertions, with 74 journey images, seven companion images and 75 receiver stages.
Supplemental run 34724674299 renders the same immutable PCK with corrected fixture
framing: 190 assertions and eighteen images pass. The author inspected twelve
images at both mobile sizes. See drill-guide-review.md and drill-guide-evidence/.
Author DEV readiness is 8/10; independent review and physical iPhone FPS are not
claimed. Review metadata now authorizes publication of that exact artifact only.

Mats's authorization to upload and publish DEV after release checks persists.
The baseline pins the verified DEV6 receipt from publication run 34717418294.
Use the immutable accepted artifact; preserve all nine published LIVE 0.46.9 files.
Final LIVE 1.0 acceptance and physical iPhone performance remain outside this fix.
