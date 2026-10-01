# DEV15.41 — reveal buried nodes before mining

Mats requested that mining rock first uncovers any buried node; that node must remain visible and require a separate attack. Existing node art, placement, resource identity and rewards are retained. No save reset or migration is required.

`endless_descent_world.gd` now rejects damage to a node while its cell is solid. Crusher snapshots exposed node IDs before its excavation and only damages those pre-existing exposed nodes. `resonance_drill.gd` snapshots once before the entire 12-row burst; nodes revealed by any row remain intact until a later attack. There is no arbitrary delay or extra button requirement: holding mine continues into the next ordinary attack/burst.

Local rendered fixture: 28 checks pass across direct strikes, Crusher and Resonance, including hidden-node damage rejection, first-attack full HP/visibility, separate second-attack payout, serialization and duplicate-claim prevention. Nine captured images inspected. Input and 414 premium-core checks pass. The core cadence fixture now records the cell when moving a fake node so it is truly exposed. Ordinary rock/event rewards remain as published in DEV15.40.

Native production payload parity is checked against the final browser candidate; only the opt-in QA suite changes after native verification. Browser fixture uses actual mining touch input with max gear and a real buried node, releases after the first burst, saves/reloads and performs the next separate burst. Ordinary WebKit startup observes real New Game, saved-run menu, confirmation and reload without QA startup. Known invariant flag-order debt is recorded separately, not reported as passed. No physical iPhone or FPS claim.

Main is a publication carrier with historical runtime. Continue development from the canonical source branch recorded below. Publish the accepted immutable candidate, never rebuild main. LIVE1.0.3 and Worn remain pinned. Rotation issue is parked at Mats's request; it recovered after rotating again.

Accepted DEV source01d038834f6b8977ca008d0babf4f9c4ed9589a2 on codex/deep-node-reveal-20261001. Mac36866530044 passes input/414core,9 browser checks/captures and ordinary WebKit. All9 final Mac images inspected. Immutable candidate11163717515; evidence11163747419. DEV publication pending. Mats additionally authorized LIVE hotfix publication on1October after verification.
