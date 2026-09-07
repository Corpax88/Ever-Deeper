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
Final source availability, browser evidence and critic scores are recorded below.
No build has been published as part of this cleanup.

## Round 2 — 7.9/10

The critic independently verified all 53 relocated QA methods and unchanged retained
save/simulation/render method bodies. Remaining gaps were source delivery, clean-checkout
verification and the promoted capture tool. Obsolete usage text and an ignored --motion
flag were corrected; runtime badge initialization was already present and is now documented.

Scores: boundaries 1.6, clarity 1.6, reuse 1.2, state/save 1.2, regression 1.7, discovery 0.6.

## Final round 3 of 3 — 8.3/10

The independent critic confirmed the target was met. No fourth round was performed.

| Criterion | Maximum | Final |
|---|---:|---:|
| Responsibility boundaries and runtime navigation | 2.0 | 1.6 |
| Local clarity, dead paths, control flow | 2.0 | 1.6 |
| Reuse and explicit contracts | 1.5 | 1.2 |
| State and save discipline | 1.5 | 1.2 |
| Executable regression confidence | 2.0 | 1.8 |
| Source and build discoverability | 1.0 | 0.9 |
| Total | 10.0 | 8.3 |

The critic independently compared all 1,280 delivered runtime files with the reviewed
candidate and reran the 1,139-file invariant check. Retained save, simulation, transaction
and active rendering method bodies remain unchanged apart from the reviewed orchestration
and no-op removal. Main is reduced from 7,441 to 4,216 lines.

The root now contains the complete source, assets, scenes, shaders and import settings.
The first clean-checkout run caught a missing shader directory in source delivery; all
18 original shader/UID files were restored unchanged and protected before the passing run.
The reusable source workflow tests the event's actual commit for future source PRs and main
changes. It has read-only permissions and does not publish a game build.

### Verification evidence

- [Complete source and mobile comparison, run 34139995656](https://github.com/Corpax88/Ever-Deeper/actions/runs/34139995656): clean import, ten native suites, 859 gameplay assertions, 121 touch assertions, LIVE/DEV exports and flavor/save isolation checks passed.
- [Reusable source PR check, run 34140624731](https://github.com/Corpax88/Ever-Deeper/actions/runs/34140624731): passed on the tested event checkout.
- Both browser runs completed 303 matching states in WebKit at 844×390. Primary and critic
  inspections of paired shop, surface, D1/D2 barrier/bedrock/transition, endless and hub
  frames found the same authored assets, geometry, layout and composition.
- Frames are not pixel-identical: two match exactly, while animation, guide, particles
  and lighting are captured at different phases. Median mean RGB difference is 0.0343/255;
  the largest is 5.54243/255. This evidence supports visual parity, not frozen-frame identity.

Machine-readable evidence is in [cleanup-verification.json](cleanup-verification.json) and
[cleanup-visual-comparison.json](cleanup-visual-comparison.json). Capture artifacts and their
original manifests are attached to the linked run. The game remains v0.46.8; gameplay,
art, balance, saves and the published LIVE/DEV files were not changed by this cleanup.

### Remaining debt

Main, RunState and the world scripts remain large and mix responsibilities. Some dynamic
contracts and duplication remain. Four pre-existing legacy QA failures are preserved and
documented in verification.md, not counted as passes. These are the critic's remaining
deductions; no further runtime changes were requested in this review.
