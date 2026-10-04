# Reliability critic — round 1, 4 October 2026

Baseline: published DEV15.54 gameplay source `be3a698e0ad8bedb91e877b9932a7bb05b80684a`.
Scope: code-grounded save, input, tool/mod lifecycle, streaming and bounded-work audit. This is not a physical iPhone acceptance or a measured performance rating.

## Verdict

Provisional reliability: **7.5/10**, with one concrete persistence fault and a developer-mode lifecycle fault to repair. The implementation has useful safeguards: checksummed binary saves with generation backup; atomic treasury accounting on landing; cancellation of owned touch input; bounded mod effects; stable Chainbreaker identities over streaming. None of these proves a whole-game 9.5/10. The reported intermittent Ricochet-to-pickaxe fault remains open and is not reproduced by the evidence reviewed here.

## R1 — Failed autosave silently loses pending work (P1, confirmed code path)

- `scripts/state/run_state.gd:2929–2931` clears `_autosave_pending` before `save_game()` returns; `2978–2983` does the same and ignores the return value entirely.
- When a write fails and no later gameplay mutation happens, no retry remains scheduled. Player progress exists only in memory. All gameplay `flush_save()` callers ignore failure; the ordinary menu can still report automatic saving, and `main.gd:1248` sets `save_available = true` regardless of the write result.
- `last_save_error` is set, but only QA reads it. The current uncertain-storage warning detects nonpersistent browser storage at startup, not later failed writes.
- Repro: use an isolated real save path, make `<path>.tmp` a directory after a good commit, earn state, let the autosave flush fail, remove the obstruction without another state mutation and wait. Baseline has `_autosave_pending == false` and does not retry. Good primary/backup should remain intact.
- Fix: retain the dirty request until a commit succeeds, retry at the existing bounded six-second cadence, invalidate stale timer callbacks after an explicit flush, and expose failure through existing save/menu state. Do not change schema, namespace, save payload or backup rotation.
- Test: obstruction → failure → unchanged good generations → obstruction removal → automatic commit without another mutation; explicit-flush failure; repeated failure bounded to one schedule; successful flush invalidates older callback; backup recovery and existing migration gate.

## R2 — Developer test override survives a new run and outranks equipped mods (P2, confirmed code path; DEV only)

- `scripts/main.gd:415–435` assigns `endless_world.drill_modes.dev_override` for each test mod.
- `scripts/world/drill_modes.gd:46–51` gives this override priority over `TreasuryGoals.active_mod()`.
- `_start_new_game()` at `scripts/main.gd:1371` resets only `resonance_drill.dev_override`. Neither `drill_modes.reset()` nor the five-mod reset clears the override. Podium `_equip()` changes saved mod flags but never clears the test override.
- Repro: select DEV TOOLS → Ricochet Test; start a fresh run/preset; reach/grant The Deep and equip a different earned mod. The saved selection and actual selected mode disagree; old Ricochet remains selected until another test override or browser reload. Test overrides are intentionally transient and are not persisted.
- Fix: explicit override lifecycle at new-game/reset and ordinary earned equip; keep menu pause, travel and input release from accidentally unequipping a legitimate selection. Add clear indication or exit action if test modes remain separate.
- Test: new run removes every test override; ordinary earned selection wins after testing; ordinary pause/resume/travel preserves the earned selection; release cancels damage while selected weapon presentation remains.

## R3 — Reload test failure is a QA lifecycle error, not demonstrated save loss (P2 evidence defect)

- Existing `/workspace/scratch/6fe59966113d/baseline-evidence/browser/report.json` reports 337/337 passing Mac Metal checks for DEV15.54: Ricochet idle/held/released across four skin fixtures, pause/resume, earned save/load and travel. This is useful scoped evidence, not ordinary browser-reload coverage.
- Parent reports the later run `37154417090` passed continuous turning/firing at speed levels 3, 10 and 20, then timed out after `page.reload()` while waiting for an active game.
- `.github/mod-persistence/review.mjs` loads `--qa-skills-browser`. `main.gd:166–172` skips ordinary persistence initialization under that flag. The inherited `scripts/qa/suites/dev14_review.gd:18–22` calls `RunState.reset_run(false)` every boot and opens the menu. A page reload therefore reconstructs defaults, resets them again and has no valid Continue path.
- Fix the harness to use an isolated persistent QA path with a fresh-boot/resume distinction, or verify reload with the ordinary exported startup. Do not modify production save logic to satisfy this fixture.
- Additional evidence needed for the user's symptom: real gameplay transitions, native renderer failure/fallback, active mod and tool style at the instant of the visible regression. No claim that the complaint is fixed.

## R4 — Historical QA invariants are not an authoritative green release gate (P2 process debt)

- `docs/verification.md` preserves legacy suite failures and protected-hash mismatches. The ordered QA registry has historical flag-order debt. New release records repeatedly say not to call these passing.
- Keep intentional protected changes explicit and update obsolete fixture expectations against the actual production contract in a dedicated change. Do not remove compatibility/debug methods based on text reference counts.
- Candidate acceptance must identify exact source/PCK, passing active cases, inspected mobile captures and each remaining limit. A passing old baseline must not be represented as current candidate evidence.

## Performance review boundaries

- Save writes still synchronously serialize, hash, verify and inspect a previous save generation. `tools/review_save_cost.gd` exists to measure 3/100/1000-band costs. No new timing was measured in this first audit, so no optimization is recommended solely from code size.
- Chainbreaker snapshots a viewport-bounded target front; effects are capped (48 arcs/chips, 18 rings). Ricochet snapshots the bounded maximum route. Native resource contact caches are bounded. Keep these limits when polishing.
- The 327 MB DEV15.54 evidence package and native model costs deserve real startup/memory/device measurements; source inspection cannot determine peak iPhone memory or FPS. Historical notes explicitly park some rejected rendering experiments. Do not reintroduce them without a measured regression and parity proof.

## Safe cleanup

Current ownership boundaries (`RunState` for accounting, world for simulation, visual for appearance) should remain. Refactoring the large state/world owners is not needed to fix R1/R2 and would enlarge migration and render risk. No dead runtime source is nominated without binding/callback and save-compatibility proof. The historical release log at the top of `AGENTS.md` is stale and oversized; updating current acceptance pointers is low-risk documentation work, separate from runtime changes.

## Next checkpoint

Root assigned this critic ownership of `run_state.gd` and a focused save retry QA file. Repair R1, capture baseline failure and candidate pass, then hand off for exact-package verification. R2 and UI save-failure communication need coordination with the main/UI owners.
