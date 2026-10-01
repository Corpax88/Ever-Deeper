# Treasury critic — round 1 of 3

Score: 7.5/10 overall; pile fit 8.2/10. Independent static code and native screenshot review, not physical iPhone certification.

Reviewed native1 entrance; full-00, full-03, full-12, full-20, full-26; gold at 556 and 30000; approved entrance mockup; stack and delivery draw/landing code.

- Blocking visual defect: entrance.png crops the right door and much of the inviting interior at the viewport edge. The approved concept presents the entire opening. Root has already identified placement correction; confirm with a fresh in-game approach screenshot.
- Strong improvement: inspected full piles remain inside podium side/front borders; stone, gold, glass and crystals retain identifiable material silhouettes. Gold starts with a single visible bar and grows into a broad mound. Podium ownership reads clearly.
- Minor polish: full glass/stone piles still have repeated tier bands and relatively flat tops, since all materials share six concentric tapered layers. This is an acceptable deterministic approximation; subtle material-specific height variation could soften it, but is not required to fix rim spilling.
- Static landing check: packet and persistent item share Stack.offset(slot,kind), extent and final rotation. The resource reservation and landing-only Ledger.land path remain intact; stable kind/slot placement avoids reshuffling on refresh. This supports exact landing by construction, but screenshots cannot prove animated continuity or save/reload accounting. Use focused existing runtime checks for those claims.
- Fixture toasts were excluded from scoring as requested. No claim about phone frame rate, Safari input or physical-device validation.

Round 2 should inspect the corrected entrance framing and focused landing/save evidence, plus clean pile images if available. Do not broaden gameplay scope.
