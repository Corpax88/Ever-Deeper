# DEV5 discovery-loop author review — 2026-09-12

Runtime source: `256dec9a688801e22bd23c4e946215f957eec578`.
Validation: [34700053177](https://github.com/Corpax88/Ever-Deeper/actions/runs/34700053177).
Immutable candidate artifact: **10299643209**. All six required jobs pass.
This is the author's critical review of a bounded correction for DEV testing.
It is not an independent critic review, a new overall game rating or final 1.0
acceptance. The provisional bounded DEV-readiness score is **8/10**, with no
critical issue reproduced in the tested paths.

## Design and failure review

The September 11 *Finding the Fun* review identified repeated payments and weak
discovery payoffs. Returning a real relic now supplies the initial construction
credit for its workshop. The existing build interaction, construction animation
and collision-safe completion still apply. The actual workshop upgrade remains
paid and changes power, cadence or other existing capabilities. Construction
credit never enters the pocket inventory and cannot be claimed twice.

The author checked the placement transaction and save sanitizer together:
older placed relics receive only missing construction credit; pocket resources,
paid levels, outfits and cargo are preserved across repeated save/load cycles.
Tests cover all five real generated relics, replay rejection, old partial
construction and one-unit-short paid upgrades. The developer's build-all helper
also handles an already funded workshop without manufacturing a new payment.

The early Starfall gate and its guide share one WorldCatalog requirement: the
Ember pickaxe and mastery 1. The remaining four mastery upgrades retain their
costs and benefits, including Heat Streak. The tested journey rejects entry
before the requirement and proceeds after the first actual mastery purchase.

Local cache/relic goals replace generic exploration and unmet resource targets.
A carried relic, an earned building and a ready upgrade retain priority. An
active cache points to its next real rune. Hidden relics give a short direction,
without showing a name, exact coordinate or changing discovery state. Sites
behind solid rock do not become discovered through proximity alone. Searches
use the resident world window; no global generation scan or new lighting system
was added. Actual tests cover discovery visibility, clue accounting, the next
rune and hauling priority.

These changes remove concrete repeated gates and connect findings to visible
Hub progress. They do not add new room types. Whether the choices feel varied
over a long session and make the next expedition appealing still requires a
human playtest. Those open design questions explain the provisional 8/10 rather
than a claim that the whole game's original critique is solved.

## Exact-package evidence

Fourteen active source and fourteen exported-DEV cases pass. The four revised
1.0 suites report 187 state, 461 world, 216 migration and 305 UI assertions.
The 50 automatic-companion assertions still pass. Both export flavors, protected
asset/configuration invariants and hero checks pass. WebKit records 869 gameplay
and 195 touch assertions with no failures; WebKit and Chromium both pass actual
audio unlock/playback/overlap/mute checks. Subjective listening is not verified.
Known legacy suites remain documented in `verification.md`, not reported green.

Native artifact **10300017712** reports 567 journey assertions / 50 captures,
75 receiver stages and seven companion captures without failures. Its PCK hash
matches the candidate and all browser evidence. The report's original
`visual_review_pending: true` is preserved: the subsequent author inspection is
recorded here and in `discovery-loop-evidence/review-index.json`.

The author inspected all eight new 844×390 states: buried signal, cache choice,
active cache rune and each of the five supplied workshop goals. The exact
package was also inspected in the larger ready-Forge capture, the small completed
Hub and mined-corner/pickup state. Existing materials, silhouettes, lighting and
art remain consistent with the approved baseline; the changed guide text fits
its panel and clears the controls. Completed construction returns to the paid
upgrade recipe. The in-world blueprint may show its fully supplied 200/200
credit; the ready HUD does not ask the player to gather or pay it again.

Two actual small WebKit captures were inspected: the wardrobe wearing Expedition
and the menu before the first tap. The framed portrait and controls fit, and the
menu shows **1.0.0-dev.5**. The 13 inspected image identities are saved in the
review index; the other unchanged captures are not claimed individually reviewed.

Rendering used native llvmpipe and automated desktop browsers. Accelerated
funding, positions and waits establish functional transitions, not human pacing,
touch comfort or sustained physical iPhone FPS. This patch makes no FPS claim.

## Release scope

Only immutable artifact **10299643209** is approved for DEV testing, without a
rebuild. Candidate ZIP SHA-256:
`2ec0fcedf6cc57ae200c75954ea6930c339a4edc9c4dc27ef6f7f98962f41b2b`.
DEV PCK SHA-256:
`0f5462e4fadb3b0292dfdf0643f594f37c05cfcad95355789f44edaaaade847c`.
The receipt pins all nine DEV files and the exact manifest. Current DEV4/LIVE
baseline bytes come from `mole-publication-receipt.json`. Publication must back
up the existing packages, preserve all nine LIVE 0.46.9 files and verify all 18
public files. Normal GitHub/DEV flow remains authorized as recorded in
`mole-autonomy.md`; no new LIVE acceptance is implied.

The first two CI failures and their fixes remain in the handoff. No failing
assertion was removed or weakened. Later documentation/review commits do not
change the tested runtime source or authorize a different build.

## Publication

[34701246397](https://github.com/Corpax88/Ever-Deeper/actions/runs/34701246397)
passed package, Pages deployment and public verification. All nine DEV files
match artifact **10299643209** and all nine LIVE files retain 0.46.9 bytes.
Receipt artifact **10300193212** was downloaded, its ZIP SHA-256 verified, and
all 18 identities compared with the reviewed candidate and prior baseline.
The original JSON is persisted in `discovery-loop-evidence/publication-receipt-raw.json`;
publication metadata is in `.github/one-point-zero/discovery-publication-receipt.json`.
Rollback artifact **10299504564** retains both earlier public packages.
The additional post-merge source run **34701246402** passed all fourteen cases.
The public test URL is https://corpax88.github.io/Ever-Deeper/dev/?v=1.0.0-dev.5.
