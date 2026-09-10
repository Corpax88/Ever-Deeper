# DEV4 companion review — 2026-09-10

Runtime source: `15c5cf464a2449166637348cded89f8cfb80ca2e`.
Candidate run: [34439447936](https://github.com/Corpax88/Ever-Deeper/actions/runs/34439447936).
Immutable candidate artifact: **10137430221**.

The author reviewed this bounded companion change. This is not an independent
review or a new overall game rating. The physical iPhone performance and final
LIVE 1.0 acceptance gates remain open.

## Behavior and failure review

The 50 real-world companion checks pass in source and the exported package. They
exercise mining in four directions, authored windup/impact timing, independent
cooldowns, release/turn/distance cancellation, menu suspension, learned-skill and
terrain restrictions, actual pickup accounting, the player's manual priority,
nearby exploration hints, Homeward choice and bounded failed path searches.
Natural Depth 2 and continuous-Deep terrain both receive actual automatic digs.

The author checked scheduling and ownership: ordinary help cannot cross the
world's digging restrictions; completed impacts retain recovery frames; a stale
dig is re-evaluated before impact; exploration cannot move the player or trigger
Homeward. Base Fetch/Lantern are already learned by design. Purchased skills use
the existing save, prerequisite, gold and bond rules. No approved asset changed.

Fourteen active suites pass on source and exact DEV PCK. WebKit passes 869 gameplay
and 195 touch assertions. Both WebKit and Chromium pass real WebAudio unlock,
overlap, discovery, mute and unmute checks. Hero motion and all twelve real damage
combinations pass. Legacy suites listed in `docs/verification.md` remain test debt;
they are not reported as passing. Accelerated progression fixtures establish
functional behavior, not human pacing.

## Visual review

All six required jobs passed; the author accepts the bounded change for DEV
with a provisional 8/10 and no critical issue reproduced in the tested paths.
Native artifact **10137619297** passed 431 journey assertions / 34 captures,
75 receiver stages and the new seven-image companion fixture. The latter records
four actual automatic digs and four collected units at 2532×1170. All seven
companion/journal images were inspected, plus mined corners across five Deep
strata, bedrock, post-fifth mining and standard-light views in all four D1 mines.
Terrain depth, material, palette, the companion, authored journal and mobile
controls remain consistent with the existing approved assets. Image identities
and artifact ZIP digests are in `mole-autonomy-evidence/review-index.json`.

The windup fixture places the hero directly over the mole, so it does not show
an unobstructed full animation. Its paused world drawing retains cached drop
sprites after collection; actual inventory and collection counters prove pickup.
The impact image does show the newly opened four-cell area and recharge status.
These fixture limitations are not described as physical-device visual defects.

The actual small WebKit images
`touch/pet-skills-swiped.png`, `touch/pet-text-swiped.png` and
`touch/input-before-first-tap.png` have been inspected. The authored journal,
portrait and menu remain intact; skill details wrap inside the scroll region;
learning changes the visible state to "Always helping" and the menu says DEV4.

## Evidence and limits

Candidate ZIP SHA-256:
`b3c6fc0131b03fd1dd49eaa6e200e2cfb208656404c5aa6a597f8d89cf8c9fc4`.
Candidate manifest SHA-256:
`ed51f9ed7bbf57d1d5df0abe8097939c575153fb7c8f279de1c6ebe76e383169`.
PCK SHA-256:
`1c511229ba168f54a828d7e5bab00f9d18d2000fa0e602f1c7ca4b70dbf31327`.
WebKit artifact **10137496905**, ZIP SHA-256:
`21b9bb566147e54fdcf214fa348499b3d965cfee0a67e15cabef8848d1100121`.

The first run, `34439071042`, correctly rejected a stale DEV3 expectation in the
exported visual test driver. The two affected package cases passed after the
expectation was updated to DEV4; all fourteen then passed in the candidate run.
No failing assertion was removed or weakened.

The rollback baseline is the actual DEV3 publication from successful run
`34368126228`, receipt artifact `10110857762`. Its 18-file receipt is persisted as
`.github/one-point-zero/dev3-publication-receipt.json`; all nine LIVE identities
match the prior baseline. This fixes the old DEV2 baseline before staging DEV4.

Native software rendering and automated browser checks cannot establish sustained
iPhone FPS, touch comfort, perceived helpfulness over a full human session or
subjective audio quality. The task adds no lights or particles; its scheduler and
path-search bounds are tested, but no new performance improvement is claimed.
The three-minute phone steps are in `mole-autonomy.md`.
