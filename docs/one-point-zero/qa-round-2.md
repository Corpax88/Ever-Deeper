# Independent critic — improvement round 2 of at most 4

Date: 2026-09-09. **Ready for DEV testing on an actual iPhone.** The independently
assessed DEV score is **8.4/10**, with zero critical bugs observed in the exercised
paths. This is not final 1.0 or LIVE approval. Performance and final overall
quality remain unverified; the required overall 9/10 has not been established.

## Final exact-package assessment

- Source: `f19c0ea61402c860fab60eae3560579aeed6ff21`.
- Tree: `871f7574a23d89403117a3456ba0b7d556a712b4`.
- Build run: `34334701244`; version: `1.0.0-dev.1`.
- DEV PCK SHA-256:
  `7757ec55406704ce613ced7c34e51581e2f1e06eb1cae893ab7486c03d5e5260`.
- The critic independently viewed **all 34 final native PNGs**, including the
  seven 844×390 captures, at
  `/workspace/scratch/6604552ab244/qa-10097465893/`. Native job `102412213654`,
  artifact `10097465893`, records **431 assertions and zero failures**. Every
  image hash matches its receipt, and the PCK hash was independently checked.
- All thirteen source and all thirteen exact DEV-package cases pass in the
  candidate's `validation.json`, together with both flavor checks. Native
  rendering uses Godot 4.7.2 and llvmpipe, not an iPhone.

The tutorial and action-caption corrections remain intact in this final
package. Both touch and keyboard instructions are complete at the small
viewport and clear the goal, minimap and controls. Four- and five-row resource
goals remain readable, as does the isolated new mining reward. All five strata,
mined corners, the permanent boundary, the five relics, Tunnel Home digging and
cargo arrival, partial/complete museum states, upgrade previews and mining at
567 m retain the authored art. No remaining concrete design or art blocker was
identified in this matrix.

Matching WebKit job `102412213518`, artifact `10097467957`, records **869
gameplay checks and 193 menu/touch checks**, both with `failures=[]` and the
final PCK hash. The critic read both receipts and the actual gesture records
under `/workspace/scratch/6604552ab244/qa-10097467957/`. The out-and-back sequence
now spans browser frames **70/72/74/76**; cancellation spans **86/88**. These
complex gestures are explicitly synthetic. Simple taps have trusted browser
events. The exercised command, drag-return, cancellation, portrait-menu and
coordinate checks pass; automated WebKit 26.5 at 844×390 does not establish
physical iPhone behavior.

The b061c4d→f19c0ea change only separates QA gesture phases across animation
frames and gives cancellation an independent starting state. The critic
audited that change: original assertions remain, and gameplay/art are unchanged.
The earlier failure came from the fixture's same-frame out-and-back events
being accumulated to zero excursion. It is now closed by the matching passing
browser run, rather than silently relabeled a pass.

Both final WebAudio reports pass all five output checks: trusted unlock,
common/rare output, protected discovery overlap, mute and unmute. WebKit
artifact `10097377877` and Chromium artifact `10097362558` both carry the final
PCK hash and no errors. Subjective listening and physical iPhone audio remain
unverified. Hero artifact `10097508925` has the matching hash and actual damage
in all twelve worn/Crusher/Deepcore direction combinations. The critic also
viewed six extracted final video frames; this is sampled motion evidence,
not a sustained player session.

## Final lighting comparison

The critic independently viewed **all 15 final original/trimmed/restored PNGs**
at 2532×1170 under
`/workspace/scratch/6604552ab244/margin-final-f19c0ea/`. All fifteen hashes match
the exact-package receipt. All five restored images are byte-identical to their
original controls. No trim-induced clipping, seams, material-detail loss or
lighting-appearance change is visible across these Hub headlamp fixtures.

| Headlamp | Changed pixels | Changed area | Maximum channel delta |
|---|---:|---:|---:|
| Standard | 2,077 | 0.070111% | 2/255 |
| Wide | 882 | 0.029773% | 2/255 |
| Focused | 1,078 | 0.036389% | 2/255 |
| Prismatic | 1,106 | 0.037334% | 2/255 |
| Deepheart | 3,272 | 0.110449% | 2/255 |

These are the final f19c0ea results; the earlier source-only and b061c4d bounds
are not substituted for them. The short llvmpipe samples show gains of
3.13–7.01% against the mean controls, with control drift of 0.39–4.17%. Wide
and Deepheart gains are no greater than their control drift. This supports
visual acceptance of the trim, not a claim of a measured iPhone FPS gain.
Light sources and the approved artwork remain present. The lightweight
receipts are in `performance-evidence/hub-margin-final-f19c0ea-receipt.json`
and `performance-evidence/hub-margin-final-f19c0ea-comparison.json`.

## Current scores and limits

| Category | Score / 10 | Evidence and limit |
|---|---:|---|
| Gameplay loop | 8 | Continuous mining, five returns, Home with cargo and post-fifth continuation pass. Accelerated fixtures do not establish long-form pacing or hauling feel. |
| Progression feel | 8 | Paid transactions, real cadence gains, resource goals and explicit upgrade comparisons pass. Extended satisfaction from earning those upgrades remains unmeasured. |
| UX | 9 | Corrected keyboard/touch onboarding, readable small-screen goals and matching browser input/menu checks pass in the inspected states. Actual phone touch feel remains unverified. |
| Visual premium | 9 | Detailed authored mine, hero, relic, shop and museum art is retained; all final affected captures and five lighting comparisons were viewed. |
| Code quality | 8 | Regression coverage verifies transactions, bounded streaming, migration and save identity. Large existing owners and historical suite debt remain; no unrelated cleanup is requested. |
| Performance | Unverified | No sustained physical iPhone measurement exists for this candidate. |
| Final overall | Unverified | Requires actual iPhone acceptance and the user's overall 9/10 gate. |

**DEV assessment: (8 + 8 + 9 + 9 + 8) / 5 = 8.4/10.** This mean covers the
five assessable categories only. It excludes performance and is not the final
overall score. Zero observed critical defects is limited to exercised paths.
There is no remaining confirmed design bug requiring a new feature or another
speculative redesign. Pacing, hauling, subjective audio and sustained phone
behavior are remaining evidence limits, not invented defects.

## Intermediate corrected-package review, retained as history

The critic independently viewed **all 34 PNGs** from source
`b061c4df1dab575d02e436bbc798e638c4dd2c72`, tree
`a544c6231935d29496d194adee185b2ba8724c54`, build run `34333668790`.
Native job `102408916314`, artifact `10097051620`, produced the exact PCK hash
`06c7a50758e4a87a2b5bd0e27bbc92c500e5560540c35fe98aeac5732807de84`.
Its `review.json` records **431 passing assertions, zero failures**. Evidence is
at `/workspace/scratch/6604552ab244/qa-10097051620/`.

Both concrete visual findings below are **resolved in this package**. Keyboard
and touch tutorial hints remain complete and separate from companion, minimap,
goal and action controls at both 2532×1170 and 844×390. The contextual `BOOST`
caption is fully visible for Memory Loom and Echo Coffer. The matching tooltip
hint names the visible action; gameplay IDs and effects are unchanged.

The clean captures retain all five strata, mined corners and the permanent
boundary, all five relics, the mole digging/Hub return, partial and complete
museum art, both workshop previews and continued mining at 567 m. One isolated
new reward from actual held mining shows readable `+3 DEEP ALLOY` and
`+5 LUMENSTONE`; it does not reproduce the accelerated campaign backlog. No
remaining concrete design or art deficit was identified in this matrix.

Matching WebKit audio artifact `10096981484` and Chromium audio artifact
`10096954166` both pass with this PCK hash. Output measurement is established;
subjective listening and physical iPhone audio remain explicitly unverified.

The critic also independently viewed original, trimmed and restored Hub images
under the Deepheart headlamp at
`/workspace/scratch/6604552ab244/deepheart-b061c4d/`. Original/restored are
byte-identical. The trimmed image changes 3,205 pixels (0.109263%), with maximum
channel delta 3/255 on one pixel; 2,914 pixels differ by 1 and 290 by 2. This is
above the previous four fixtures' numeric bounds and must not be described as
2/255 or below 0.073%. Full-frame inspection finds no visible clipping, seams,
material-detail loss or lighting-appearance change. **Visual fidelity of this
pair is acceptable for DEV testing.** Its short software-renderer timing does
not establish any iPhone FPS improvement.

At that stage the browser out-and-back/cancel failures were still unresolved;
the critic withheld DEV readiness until the final native matrix, all five
exported-PCK lighting pairs and matching browser checks had passed. The final
assessment above closes those gates and supersedes this intermediate status.

## Initial exact evidence inspected

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
The failed WebKit gesture helper required a separate correction. Both harness
failures were retained as failures until their corrected matching gates passed;
neither was relabeled a gameplay defect.

## Initial scoped findings and their resolution

1. **Resolved in b061c4d: tutorial overlaps the goal and map.**
   `01-new-player-hud.png` and its 844×390 counterpart show the keyboard tutorial
   over the companion, minimap and Iron Pickaxe title. `02-4-row-recipe.png`
   repeated the collision. The correction required fresh captures covering
   both keyboard and touch hints.
   Passing goal/map geometry alone did not catch this separate overlay.
2. **Resolved in b061c4d: minor context-label clipping.** In
   `relic-memory_loom-on-rope.png` and `relic-echo_coffer-on-rope.png`, the actual
   context is `OVERLOAD`, but the narrow button visibly clips the final letter.
   This did not prevent the action or lose cargo. The final caption correction
   preserves the HUD and action behavior.
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

## Initial provisional scores, retained as review history

| Category | Score / 10 | Evidence and limit |
|---|---:|---|
| Gameplay loop | 8 | Continuous excavation, five returns and continuation pass in the exact package. Fixtures accelerate travel and gathering; long-form human pacing/hauling is not established. |
| Progression feel | 8 | Paid progression, strict tool cadence gains and readable actual upgrade comparisons are verified. A multiplier or automated mining run cannot alone establish satisfying player feel. |
| UX | 8 | Live right-side requirements and compact recipes work; the old package still has the confirmed tutorial collision and minor long-action clipping. Corrected final captures are pending. |
| Visual premium | 8 | Detailed authored hero, mine, relic, shop and museum art is retained across the inspected states. Clean final terrain/feedback and corrected onboarding captures remain required. |
| Performance | Unverified | This candidate has no sustained physical iPhone measurement. Native/software browser timing cannot be substituted. |
| Code quality | 8 | Source and exact-package regressions cover transactions, bounded streaming, migration and save identity. Large existing state/world owners and historical suite debt remain; no runtime cleanup is requested by this review. |

No final overall 9/10 rating is justified by the current evidence. The last physical
baseline remains DEV9 **52.1 FPS with normal pet lighting**, **60 FPS with pet
lights disabled**, and **52.1 FPS** in the final restored stage. It does not
certify this candidate or require repeating the same DEV9 test.

## Remaining decision

The exact f19c0ea package is ready for DEV testing on an actual iPhone. Final
1.0 and LIVE remain unapproved: they require at least 9/10, zero critical bugs
and sustained stable physical iPhone behavior. The last DEV9 measurement is a
baseline, not acceptance of this candidate.
The critic has not changed runtime files, committed, pushed or published.
