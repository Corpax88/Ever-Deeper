# Discovery loop correction — reviewed DEV5 candidate

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
  A nearby buried relic gives a short directional excavation signal before its
  real reveal, so the main route does not lead the player past every side find.
  Its identity and exact hidden position stay concealed; solid rock also prevents
  cache discovery through walls.

## Boundaries

Existing art, lighting, tool traits, automatic mole behavior, generation seeds,
terrain IDs and save schema remain unchanged. This does not add progression
trees, new menus, new currencies or procedurally approximated artwork. The
existing cache risk/reward actions remain the local choices being surfaced.
Room variety and voluntary return still need human evidence; this change does
not claim to solve unlimited late-game variety or certify iPhone FPS.

## Verification and release

Source diffs, protected-file checks and eight offline release tests pass.
First CI run 34699520146 imported cleanly and passed 12/14 source cases,
including all four revised 1.0 cases and automatic mole behavior. Touch and DEV
tools exposed a shared developer-fixture bug: its workshop helper rejected an
already supplied building. That helper now proceeds directly to construction;
the original touch and DEV-tool assertions remain intact. Second CI run
34699791396 passed all 14 source cases and both exports. Two packaged cases
correctly rejected an old DEV4 expectation in the capture harness; the DEV5
version pins are now synchronized without weakening the exact-version check.
Final run [34700053177](https://github.com/Corpax88/Ever-Deeper/actions/runs/34700053177)
passed all six jobs at runtime source `256dec9a688801e22bd23c4e946215f957eec578`.
Fourteen source and fourteen exported-DEV cases pass, alongside both export
flavors. Native journey validation passes 567 assertions / 50 captures; WebKit
passes 869 gameplay and 195 touch assertions. Both browser audio jobs, hero
motion, automatic-companion checks and 75 lighting-receiver stages pass.
The local cached Godot ZIP is incomplete and a fresh release download timed out;
the established GitHub jobs provide these actual engine and browser results.

The author inspected all eight new small mobile states, the large ready Forge,
a mined corner, the completed Hub and two WebKit menu/wardrobe images from the
exact package. See [the scoped review](discovery-loop-review.md) and the image
identities in `discovery-loop-evidence/review-index.json`.
Immutable candidate artifact: **10299643209**. DEV PCK SHA-256:
`0f5462e4fadb3b0292dfdf0643f594f37c05cfcad95355789f44edaaaade847c`.
Later review/docs commits do not alter this runtime artifact. The author accepts
DEV testing with a provisional bounded 8/10; no new independent or full-game
approval is claimed. PR #15 is merged. Publication run
[34701246397](https://github.com/Corpax88/Ever-Deeper/actions/runs/34701246397)
passed package, deployment and public verification. All nine DEV files match
the reviewed artifact and all nine LIVE files remain 0.46.9. The verified
receipt is `.github/one-point-zero/discovery-publication-receipt.json`; rollback
artifact **10299504564** retains both previous public packages. The additional
source check after merge, run **34701246402**, also passed all fourteen cases.

Acceptance includes actual early gate transactions, all five generated relics,
construction without extra pocket spending, paid upgrade boundaries, no replay,
legacy partial-construction migration, blocked/visible discovery, rune guidance,
and the current gameplay/touch/package suites. These checks and the rendered
small-mobile relic-ready HUD review are complete; accelerated fixtures do not
establish enjoyable pacing or physical-device performance.

Phone playtest: open [DEV5](https://corpax88.github.io/Ever-Deeper/dev/?v=1.0.0-dev.5)
and check the menu says `1.0.0-dev.5`. Continue an existing save, return a relic and
build its workshop without another material trip. Explore a side discovery and
return to mining. On an earlier save, try Starfall after Ember mastery 1. Judge
whether these discoveries actually make you want another trip; keep normal
lighting and the FPS meter on for the sustained device check.
