# Stamina recovery while browsing menus

Mats requested that players keep regenerating stamina while viewing Skills and other menus. Latest approved baseline is LIVE1.0.1 plus DEV15.21. FPS investigation remains PARKED; preserve all existing art, animation, audio, performance work and save identities.

## Implementation

`scripts/progression/miner_training.gd` owns physics sampling. It previously returned before calling RunState whenever a menu, inventory or shop was open, so recovery stopped too. The fix keeps ordinary readiness guards (started game, valid player, no orientation guard, cinematic, travel or conclusion), samples travel even during menus, then calls the existing training authority with zero distance and mining=false while browsing menus. This permits rest without movement/carrying XP or stale mining stamina costs. No changes to world pause/control behavior, skill curves, stamina formula, saves or UI.

The existing 0.4-second recovery delay, 25 stamina/second and 100 cap stay intact. The Skills screen already refreshes the stamina bar every0.2 seconds. No recovery before starting/continuing an expedition, and no wall-clock/offline catch-up added.

## Build and validation

Build patches immutable LIVE1.0.1 artifact11014496819 and DEV15.21 artifact11007955681. Every untouched resource payload is checked byte-for-byte. Main remains a publication carrier, not a re-export source. Intended versions: LIVE1.0.2 / DEV15.22.

First run36540744346 proved seven menu recovery rates and unchanged XP/player position/impact in both flavors, but stopped when the test tapped a hidden Forge footer Cancel control. This was a QA locator error; screenshot showed the visible top-right X. Observer now exposes the real close_button. Gameplay code did not change. First optional legacy invariant invocation lacked its historical docs in sparse checkout; docs restored for the final run. No failed candidate was published.

Final source bde8ead03852ed9722d217af0b50d01269eb362c on codex/menu-stamina-20260929; validation36541177604 passed both builds and both Mac browser workers. Exported input/premium-core/build-flavor passed per flavor;34 DEV and35 LIVE browser observations passed, plus ordinary WebKit startup/save/reload/confirmation. All26 actual captures were inspected (10 DEV,16 LIVE). Both reported Apple Metal renderer, DPR2; no physical-iPhone claim.

The optional historical invariant checker still fails its pre-existing QA-registry/documentation comparison (`QA flag order or arguments changed`), as documented in earlier releases. Neither qa_launcher nor its registry/documentation is modified here. This is not reported as a passing invariant suite; exported input/premium-core/build-flavor and exact package parity are the scoped release gates.

## Accepted artifacts

- LIVE candidate11020836697, ZIPsha2561487eee26b5b10b8cd5c957683d998df31c119440a5a16a86e464ef42ff465f3; core11020876542; browser11020252905.
- DEV candidate11021180959, ZIPsha25687faa2e758e223c8d22b36216acdd0acf9cc87687c3c72c0e5a06342fda9e425; core11020636972; browser11020432137.
- Gameplay script is identical in both flavors; exact original pack resources are retained except training source/remap, explicit QA observer/remap and release versions.
- Final reports normalize JSON whitespace in repository; original raw reports and actual PNGs are retained in the pinned browser artifacts.
- Publication commit7a0aa07aa8389d6c8c31c18c50190c03aae197b8. Publication36541871974 passed package/deploy/verify, all27 public hashes verified. Worn retained byte-for-byte. Publication receipt11020388270; rollback of LIVE1.0.1/DEV15.21 artifact11020902882. Nothing remains running.

LIVE PCK: {"size": 263959750, "sha256": "b861dae2e663fef14be7d5ce6d39e551136554b44f6ce11322057e847e9b39e8"}

DEV PCK: {"size": 264037622, "sha256": "cdc76ffa95bcd8497c3c889d852dff0f7fc3896abe1b0ff1446cf0dacacb7f82"}
