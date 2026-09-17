# Current DEV13 status

Published and verified; read [PUBLISHED.md](PUBLISHED.md) for exact source, package, QA and publication receipts. The earlier preparation notes below are preserved history and no longer describe a pending export.

---

# DEV13 companion follow candidate

Status: preparing the first actual DEV13 export from checkpoint 50aeccea391163826a1c3ab5e474f394eacd7546. DEV12 remains published. This candidate is not yet package-reviewed or published.

The companion can be overtaken by the player and overlap the character. Follow mode now observes the player's resolved movement, chooses terrain-valid separation steps within one movement budget, waits safely while the player passes and derives draw depth from its final foot position. Existing companion task selection, mining, loot, save data and all original art remain in their existing owners.

The helper is the exact reviewed pilot at01409145. The transfer inlines that pilot's wrappers around the original task owner; all27 other functions and the original renamed physics/task-move bodies remain byte-exact. The corrected exported-package fixture verifies the proposed source on six actual world owners/helpers and passes all50 existing autonomy and11 lifecycle checks. An older fixture loaded the old compiled owner through its export remap; that failed identity check remains rejected.

Fresh Worn/right and Worn/up both have independent visual approval and each preserves195 mechanics samples/six events. Up removes the recorded overlaps and stale foot-depth states; right removes the observed wrong-facing reversal. Source checks and these pilot approvals are not final-package visual approval. The new export must pass the existing full exact-package workflow and focused actual-production companion captures before DEV-only publication. Native hero animation, unexplained browser hitches and physical-iPhone performance remain separate open work.

Production owner SHA256: `5c485b1e41ad40fe6c71368c7824b92932bc9a1f0114e732ed1300b9e6d7be73`.
Helper SHA256: `6cd2d6f3baa1f302cd0c1ba4596185b7281af174e52f302dc4e48566fe885358`.
Both are unchanged from the saved preparation checkpoint; only this status and the workflow trigger comment changed for the first QA request.
