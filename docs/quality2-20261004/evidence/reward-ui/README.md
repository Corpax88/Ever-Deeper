# Treasury reward card review — 4 October 2026

The corrected panel passes the scoped native readability review: 20 rendered
states, 20 PNG captures and 1,458 assertions at 667 × 375 and 844 × 390
CSS-equivalent landscape sizes. Source, equipped status, progress and description
measure at least **14.5725 CSS px at 667** and **15.1767 CSS px at 844**, against
the unchanged **13.8 CSS px** gate. These checks are not a whole-game score.

The previous font-24 version is **superseded and is not accepted for readability**.
Its 5,052 geometry/state assertions did not measure minimum font size. Integration
review correctly caught the source-text regression. Its original report, image
hashes, package receipt and review remain unchanged under
`history/font24-before-readability/` for traceability.

## Change and evidence

The panel names each material collection and its permanent Treasury display,
shows delivered/held/remaining quantities, and uses `CLAIM & EQUIP`, `EQUIP` and
`UNEQUIP`. It identifies the active mod and explains replacement. The correction
uses font 29 for source, equipped status and progress. Compact footer copy retains
all source locations and the requirement to explore new ground for tracked rich
veins. Approved art, the 100,000 target, reward identities and state authority are
unchanged.

- `checks.json` and `snapshots.json` are byte-for-byte raw successful reports.
- `images.json` names and hashes all 20 PNGs, binds panel/probe source hashes,
  and records measured CSS fonts. No PNGs are duplicated into the repository.
- `package-receipt.json` records the base/candidate PCK and verifies all unrelated
  payloads were retained. Only the panel and its source remap were replaced.
- Raw output: `/workspace/scratch/72d2364e7fd1/reward-ui2/readability/`.
- Base: DEV15.55, source `befb9eabfc1ff424fe20c4db34eeea19cc8b0301`.
- Probe: `tools/review_treasury_rewards.gd`, with
  `TREASURY_REWARDS_SCOPE=readability`, Godot 4.7.2, authenticated Xvfb and an
  isolated save. The probe requires rendering, not a headless runner.

The scoped rerun covers collection-to-mod transitions, long descriptions and
sources, ready/unclaimed, equipped, unequipped, replacement of Resonance, and the
longest active name, Chainbreaker. Real touch events claim, unequip, re-equip and
replace an active mod. The native probe now requires 13.8 CSS px for title,
description, progress, equipped status and source in addition to text fit and
separation.

Final captures inspected include `667-mod-deep_alloy.png`,
`667-replace-chainbreaker.png`, `844-replace-chainbreaker.png` and
`667-replacement-active.png`. They show clear footer text without overlap at the
small width and after claim. The earlier 27-entry catalog and transaction review
is retained as historical coverage; it is not claimed as a new full run of this
font revision. Release browser checks cover the combined candidate.

## Final critique and limits

No further concrete material defect was found in the corrected card flow. Button
copy matches `TreasuryGoals.claim()` and `toggle()`, ownership survives unequip,
replacement is explicit, ordinary collections do not invent mod rewards, and
completed goals retain their disabled tracking controls. Failed claims return
before drill reset or success audio. Save and balance logic remain with their
existing owners.

Integrated browser verification remains the release gate. Native Dummy audio
does not establish audible playback; these screenshots do not establish physical
phone performance. The existing portrait `LANDSCAPE MODE` pause overlay remains.
The native geometry probe uses the viewport's final transform and a 0.05 px inset
per rectangle solely to avoid false overlap from floating-point rounding at an
exactly shared header edge. No readability threshold was lowered.
