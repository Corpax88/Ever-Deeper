# Code cleanup review

Constraint: preserve gameplay, visuals, tuning, player-facing version and saves.
Independent critic, fixed rubric, maximum three rounds; target at least 8/10.

## Round 1 — 6.1/10

| Criterion | Maximum | Baseline |
|---|---:|---:|
| Responsibility boundaries and runtime navigation | 2.0 | 1.0 |
| Local clarity, dead paths, control flow | 2.0 | 1.2 |
| Reuse and explicit contracts | 1.5 | 1.0 |
| State and save discipline | 1.5 | 1.2 |
| Executable regression confidence | 2.0 | 1.4 |
| Source and build discoverability | 1.0 | 0.3 |
| Total | 10.0 | 6.1 |

Main findings: tests buried in production orchestration, duplicate QA flag dispatch,
disconnected procedural render helpers, duplicate mine/world definitions, outdated JS
instructions and an authoritative source reachable only through old release patches.

## Implemented changes

- Moved 53 QA methods out of main into ten named suites, with explicit access to the game.
- One ordered registry owns flag recognition and deferred dispatch. Test lifetime and
  performance sampling are owned by the QA launch node, created only in automated mode.
- Removed 48 disconnected private helpers (1,068 lines). Public/debug APIs, active
  fallback paths, artwork, tuning, save serialization and migration remain intact.
- Shared mine order and world mapping now come from WorldCatalog.
- Replaced obsolete entry instructions and test commands with the actual Godot workflow.
- Added a feature ownership map, invariant hashes, a strict QA runner and explicit
  documentation of four pre-existing legacy test failures.

Core native checks pass. The original and refactored source reproduce the same four
legacy failures; none were suppressed inside a check or rewritten to manufacture a pass.
Source availability, final browser evidence and subsequent critic scores are recorded
below when complete. No build has been published as part of this cleanup.

## Round 2 — 7.9/10

The critic independently verified all 53 relocated QA methods and unchanged retained
save/simulation/render method bodies. Remaining gaps were source delivery, clean-checkout
verification and the promoted capture tool. Obsolete usage text and an ignored --motion
flag were corrected; runtime badge initialization was already present and is now documented.

Scores: boundaries1.6, clarity1.6, reuse1.2, state/save1.2, regression1.7, discovery0.6.
Final source and browser validation remain pending.
