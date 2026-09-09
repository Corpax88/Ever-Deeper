# Independent critic — improvement round 2 of at most 4

Date: 2026-09-09. **Provisional review; final corrected package is pending.**
This review does not approve final 1.0 or LIVE publication. DEV testing and physical
iPhone acceptance are separate decisions.

## Exact evidence inspected

- Source commit: `787f6d5fc3795557f3a6c44a2e9ea3c061f48d92`.
- Source tree: `4a6c4ef955a72919c8257d95e0f5d5634ee14f53`.
- Candidate build run: `34330585865`.
- DEV PCK SHA-256:
  `0ec875a41ae1c941821257f6332a9dc93e3baf718afdf2fe05874831c691f8b7`.
- Independently viewed all 28 PNGs in the corrected native capture at
  `/workspace/scratch/6604552ab244/native-787f6d5/`.
  Its `review.json` matches the candidate hash and records 326 passing assertions,
  zero failures, Godot 4.7.2 and the llvmpipe software renderer. It is explicitly
  not a physical iPhone run.
- Read the candidate's immutable `validation.json`: all thirteen source and all
  thirteen DEV-package cases pass, as do both flavor checks. This includes the
  859-check overhaul, 240 paid progression, 515 continuous-world, 260 migration
  and 357 live-goal/UI checks.
- Read the matching hero motion manifest: actual damage in twelve worn/Crusher/
  Deepcore direction combinations. Read both WebKit and Chromium audio reports:
  trusted-gesture unlock, common/rare output, protected discovery overlap,
  mute and unmute pass. These reports explicitly do not verify subjective
  listening or physical iPhone behavior.

The native CI harness initially rejected its own invocation because Godot consumes
`--main-pack` before exposing script arguments. The corrected external harness
rendered the unchanged PCK and recorded its hash and exported resource root.
The failed WebKit gesture helper is being corrected separately. Neither failure
should be relabeled a gameplay defect or silently counted as a passing CI gate.

## Scoped findings

1. **Confirmed visual correction required: tutorial overlaps the goal and map.**
   `01-new-player-hud.png` and its 844×390 counterpart show the keyboard tutorial
   over the companion, minimap and Iron Pickaxe title. `02-4-row-recipe.png`
   repeats the collision. The candidate must be recaptured with the proposed
   shared-layout correction, explicitly covering both keyboard and touch hints.
   Passing goal/map geometry alone did not catch this separate overlay.
2. **Minor context-label clipping.** In
   `relic-memory_loom-on-rope.png` and `relic-echo_coffer-on-rope.png`, the actual
   context is `OVERLOAD`, but the narrow button visibly clips the final letter.
   This does not prevent the action or lose cargo. Check long action labels at
   the final small viewport without redesigning the HUD.
3. **Fixture feedback must not be mistaken for ordinary density.** The raw
   journey awards many campaign achievements and large material bundles in
   seconds. Persistent achievement/pickup layers obscure several screenshots;
   this establishes a need for clean terrain captures and one isolated newly
   earned pickup, not that a normal player sees this backlog. The long POWER
   SEAL banner is the native mouse-hover tooltip left by the capture driver's
   mouse tap; it is not evidence of ordinary physical-touch presentation.

No critical gameplay, save, missing-art or terrain-closure defect was identified
in the exercised paths. Zero observed critical defects is not a claim that
unexercised paths are proven bug-free.

## Visual and gameplay observations

| State | Independent observation |
|---|---|
| Four- and five-row recipes | Full resource names, ready colors, counts and pending gold value remain legible at 844×390. The largest recipe clears the mine/context region. |
| Deep entrance, corners and permanent boundary | Detailed authored walls and floor textures remain present. Ordinary excavated rock and the permanent outer rock have distinct silhouettes. No final chamber or shaft action blocks the demonstrated continuation. |
| All five strata | Blue, ember, violet, stone and root bands retain their distinct textured presentation. Cross-band transitions and mined edges render without missing resources. |
| Five generated relics | Forge Heart, Ancient Lens, Memory Loom, Echo Coffer and Wayfinder Core retain their distinct production art and attach to physical rope. A still capture cannot establish the subjective hauling feel. |
| Tunnel Home | The mole has a visible digging state, the action disables during preparation, and real Hub arrival retains the attached relic. Cache proximity can temporarily own the context action; Home's owner still accepts the validated return. |
| Museum and shops | Empty pedestal selection, three placed relics, five completed relics and the selected completed museum retain the premium artwork. Tool Forge and Tunnel Workshop previews are readable. |
| Tangible upgrades | Forge preview shows power 135%→170%, speed 112%→124% and reach 110%→120%, consistent with the transaction authority. Tunnel Workshop shows preparation 1.25s→0.45s. Runtime cadence checks establish an actual speed effect; extended player feel remains unmeasured. |
| After relic five | Actual held mining continues at 567 m with three active bands / 2,640 cells. The goal offers the next existing workshop upgrade and its required Deep Alloy; it does not announce the end of mining. |

## Provisional scores

| Category | Score / 10 | Evidence and limit |
|---|---:|---|
| Gameplay loop | 8 | Continuous excavation, five returns and continuation pass in the exact package. Fixtures accelerate travel and gathering; long-form human pacing/hauling is not established. |
| Progression feel | 8 | Paid progression, strict tool cadence gains and readable actual upgrade comparisons are verified. A multiplier or automated mining run cannot alone establish satisfying player feel. |
| UX | 8 | Live right-side requirements and compact recipes work; the old package still has the confirmed tutorial collision and minor long-action clipping. Corrected final captures are pending. |
| Visual premium | 8 | Detailed authored hero, mine, relic, shop and museum art is retained across the inspected states. Clean final terrain/feedback and corrected onboarding captures remain required. |
| Performance | Unverified | This candidate has no sustained physical iPhone measurement. Native/software browser timing cannot be substituted. |
| Code quality | 8 | Source and exact-package regressions cover transactions, bounded streaming, migration and save identity. Large existing state/world owners and historical suite debt remain; no runtime cleanup is requested by this review. |

No overall 9/10 rating is justified by the current evidence. The last physical
baseline remains DEV9 **52.1 FPS with normal pet lighting**, **60 FPS with pet
lights disabled**, and **52.1 FPS** in the final restored stage. It does not
certify this candidate or require repeating the same DEV9 test.

## Remaining decision

Inspect the next immutable PCK after the scoped UI/capture fixes, including all
new tutorial states and a fresh pickup without fixture backlog. Require a green
matching WebKit touch run and complete exact-package lighting review before a
DEV test-readiness recommendation. Final 1.0 approval additionally requires
at least 9/10, zero critical bugs and sustained stable physical iPhone behavior.
The critic has not changed runtime files, committed, pushed or published.
