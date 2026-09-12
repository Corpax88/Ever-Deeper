# Discovery loop correction — DEV5 candidate

Mats asked on 2026-09-12 to fix Ever-Deeper using the critic's findings. The
retrieved source is the 2026-09-11 *Finding the Fun* handoff, summarizing that
conversation's design/code review. It is a design hypothesis, not a human
playtest or proof of enjoyment. The earlier technical/FPS reviews remain separate.

## Implemented changes

- Starfall requires the Ember pickaxe and the first Ember mastery purchase.
  Four further mastery purchases remain available for optional power and Heat
  Streak, rather than being repeated prerequisites for another environment.
  The gate and guide read the same WorldCatalog requirement.
- Physically delivering each of the five relics supplies its workshop's initial
  200-material construction credit. The player visits the workshop to build it
  through the existing animation and collision-safe construction path. Ordinary
  mined resources stay available for subsequent paid upgrades.
- An already displayed relic in an older save receives any missing construction
  credit. Earned buildings, paid levels, outfits and pocket resources survive.
  Credit stays in construction and cannot become a repeatable pocket payout.
- The HUD and guide prioritize nearby discoveries during exploration, then the
  authored rune route while recovering a cache. Hauling a relic and building an
  earned workshop retain priority. Completed or distant discoveries drop away.
  Hidden relic locations are not exposed by the generic guide; solid rock also
  prevents cache discovery through walls.

## Boundaries

Existing art, lighting, tool traits, automatic mole behavior, generation seeds,
terrain IDs and save schema remain unchanged. This does not add progression
trees, new menus, new currencies or procedurally approximated artwork. The
existing cache risk/reward actions remain the local choices being surfaced.
Room variety and voluntary return still need human evidence; this change does
not claim to solve unlimited late-game variety or certify iPhone FPS.

## Verification and release

In progress. Source diffs, protected-file checks and eight offline release tests
pass. First CI run 34699520146 imported cleanly and passed 12/14 source cases,
including all four revised 1.0 cases and automatic mole behavior. Touch and DEV
tools exposed a shared developer-fixture bug: its workshop helper rejected an
already supplied building. That helper now proceeds directly to construction;
the original touch and DEV-tool assertions remain intact. Full revalidation and
final-package captures are pending. The local cached Godot ZIP is incomplete and
a fresh release download timed out; validation uses the established GitHub jobs.
Never publish this candidate before its tests and actual mobile captures pass.
Keep the existing LIVE 0.46.9 package. Review flags must remain false until the
new immutable artifact has been inspected; DEV4's receipt is historical evidence.

Acceptance includes actual early gate transactions, all five generated relics,
construction without extra pocket spending, paid upgrade boundaries, no replay,
legacy partial-construction migration, blocked/visible discovery, rune guidance,
and the current gameplay/touch/package suites. Inspect the new relic-ready HUD
on small iPhone viewports in the exported build.

Phone playtest after publication: continue an existing save, return a relic and
build its workshop without another material trip. Explore a side discovery and
return to mining. On an earlier save, try Starfall after Ember mastery 1. Judge
whether these discoveries actually make you want another trip; keep normal
lighting and the FPS meter on for the sustained device check.
