# Treasury reward card review — 4 October 2026

The scoped reward-card change passes native rendering and real touch interaction
at 667 × 375 and 844 × 390 CSS-equivalent landscape sizes. The run retained 32
screenshots and passed 5,052 geometry and state assertions across 86 card states.
These repeated layout assertions are not a whole-game quality score.

The panel now names each ordinary material collection and describes its permanent
Treasury display. Progress reports delivered, held and still-to-deliver amounts.
Mod buttons say `CLAIM & EQUIP`, `EQUIP` or `UNEQUIP`; the card names the currently
equipped mod and explains that equipping another replaces it. Existing success
and confirmation audio is used after the state owner accepts the action.

The target remains 100,000. All approved art, mod descriptions, reward identities,
claim authority and persistence owners are retained. Only
`scripts/ui/treasury_goal_panel.gd` is replaced in the locally reviewed package.
`package-receipt.json` records the base/candidate PCK hashes and verifies every
unrelated PCK payload was retained. The base is published DEV15.55, source
`befb9eabfc1ff424fe20c4db34eeea19cc8b0301`.

## Evidence

- `checks.json` is the byte-for-byte raw successful report from `render3`.
- `images.json` names and hashes all 32 PNGs and binds the panel/probe sources.
  The PNGs themselves are deliberately not duplicated into the repository.
- Raw captures: `/workspace/scratch/72d2364e7fd1/reward-ui2/render3/`.
- Probe: `tools/review_treasury_rewards.gd`, using Godot 4.7.2, an isolated save
  directory and an authenticated Xvfb render session. It requires rendering;
  it is not a headless test.

Coverage includes partial, fully held and completed ordinary collections, all
eight mod previews, ready/unclaimed, claimed/equipped, claimed/unequipped and
replacement of another active mod. Every one of the 27 real catalog entries is
checked for text fit, on-screen geometry and separation at both widths. Actual
touch events claim Resonance, unequip it, re-equip it, then claim Twin Auger and
verify that Resonance stays unlocked but is no longer active.

Representative images inspected include `667-collection-56000.png`,
`667-collection-100000.png`, `667-mod-deep_alloy.png`, `844-mod-deep_alloy.png`,
`667-claim-ready.png`, `667-equipped.png`, `667-unequipped.png`,
`667-replace-equipped.png`, `844-replace-equipped.png` and
`844-replacement-active.png`. Some preceding iteration images were also inspected;
the retained successful report and hash manifest identify the final third run.
Native rendering preserves the existing portrait `LANDSCAPE MODE` pause overlay.
This is landscape acceptance, not portrait play or physical-phone acceptance.

Earlier local attempts exposed overlapping new label bounds and a stale Godot
minimum label height after switching from a collection to a mod. Spacing and the
font-before-placement order were corrected. The geometry probe also applies the
viewport's final transform and a 0.05 px inset per rectangle to avoid treating a
floating-point rounding difference at a shared header edge as a real overlap.
Those earlier failed reports remain in `reward-ui2/render` and `render2`; they are
not included in the passing total.

## Final source critique

No concrete material blocker remains in this panel's new user flow. The button
labels match `TreasuryGoals.claim()` and `toggle()`: claiming equips, equipping
replaces the active mod, and unequipping retains ownership. Ordinary collections
do not expose invented mod rewards. Completed collections and claimed mods keep
their existing disabled tracking controls. Held gold is correctly distinguished
from mined gold ore by the ledger and material label owner.

The failed-claim path now returns before drill reset or success audio. Successful
claims and toggles continue through the existing world reset and refresh path.
The modal pauses gameplay, so the displayed held/delivered snapshot does not
need a polling loop while the card is open. No save or balance logic moved into
the panel.

The remaining gate is the release agent's integrated browser review, including
the new `equipped` label and real claim/equip/replacement interactions. Dummy
audio in the native runner does not prove audible playback. This local review
does not establish a 9.5/10 whole-game rating or physical-device performance.
