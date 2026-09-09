# Reviewed FPS recovery candidate — 1.0.0-dev.3

Runtime source: `42fffc163c940db2ab9df2e1924608e2d1659793`.
All six jobs in [34361743735](https://github.com/Corpax88/Ever-Deeper/actions/runs/34361743735)
passed. Exact DEV artifact **10108229398**, PCK SHA-256:
`6ec691604a060bcad3a21ac2666385e3d1a0c0ac07822c6b74c2a31e33dc5d6d`.

This changes D1 and continuous-Deep light receivers, releases closed shop previews
and the wardrobe portrait, and avoids redundant guide sorting. Approved artwork,
lighting strength, output resolution, gameplay and saves are retained. The relocated
DEV button remains clear of the menu; the FPS display now identifies **DEV3**.

The latest player screenshot reports **19.9 FPS** during Emberdeep mining. Its
exact build is unknown. No physical iPhone recovery is established yet, and no
final 1.0 or LIVE acceptance is granted. Independent review approves the exact
package for DEV device testing. All six 180-second native comparisons completed:
progressed Ember FPS improves 77.20% and post-fifth Deep FPS improves 49.69% on
llvmpipe. Ember's worst frame worsens, and an unexplained old-Hub transient
prevents clean Hub FPS attribution. Closed commerce previews release their GPU
allocations; the final closed-shop fixture uses 30.52 MiB less. These figures
are not iPhone FPS estimates. The provisional five-category critic mean remains
8.4/10, with performance excluded and overall 1.0 approval unverified. See
[the FPS critic review](../performance-diagnosis/fps-recovery-review.md) and
[physical-device evidence](iphone-performance.md).

DEV publication is pending. The publisher must use artifact **10108229398**
without rebuilding and preserve all nine existing LIVE files. Later review and
external diagnostic updates do not change the runtime source above. Raw sustained
evidence, failed fixture histories and image review identities are persisted under
`docs/performance-diagnosis/`. Source/review:
[pull request 13](https://github.com/Corpax88/Ever-Deeper/pull/13).

# Previous DEV correction — 1.0.0-dev.2

Reviewed source: `246ee70cca3cff2eae0fe417800cf2d1724c6417`.
All six jobs in [34349012950](https://github.com/Corpax88/Ever-Deeper/actions/runs/34349012950)
passed. DEV now sits below the gameplay menu row, and its drawer fits on first
open. Independent critic acceptance is 9/10 for this bounded fix; the game's
provisional 8.4/10 and physical-iPhone/final-1.0 limitations remain unchanged.
See [the correction and phone test steps](dev-button-review.md).

Published and verified by [34350088172](https://github.com/Corpax88/Ever-Deeper/actions/runs/34350088172).
All nine DEV files match approved artifact **10102987319**; all nine LIVE files
retain their existing 0.46.9 bytes. Receipt:
`.github/one-point-zero/dev-button-publication-receipt.json`. Rollback artifact:
**10103344125**. The prior 1.0-dev.1 baseline acceptance is recorded below.

# Ever-Deeper 1.0 — DEV acceptance candidate

DEV version: **1.0.0-dev.1**. Reviewed source:
`f19c0ea61402c860fab60eae3560579aeed6ff21`, validation run
[34334701244](https://github.com/Corpax88/Ever-Deeper/actions/runs/34334701244).
The six required jobs passed. This is a candidate for device testing, not final
1.0 approval. LIVE remains the existing `0.46.9` package.

Published and verified by [run 34337134929](https://github.com/Corpax88/Ever-Deeper/actions/runs/34337134929).
All nine DEV files match the reviewed artifact; all nine LIVE files remain unchanged.
The durable receipt is `.github/one-point-zero/publication-receipt.json`; rollback
artifact **10098196867** contains both previous public packages.

## Implemented scope

- The Deep is a continuous procedural mountain. Three resident geology bands
  stream around the player, with camera/companion rebasing and persistent excavation.
  Mining continues after the fifth relic without floor selection or lift travel.
- Five existing relics appear at increasing depths. Physical rope attachment,
  return, Museum placement and paid workshop construction remain intact.
- The right-hand goal shows the actual next recipe and updates on collection,
  sale, delivery and purchase. Four- and five-resource recipes clear the minimap
  and mobile controls; keyboard/touch onboarding has its own clear space.
- Existing upgrades change real mining cadence, power, reach, pickup and lighting.
  The completed Tunnel Workshop shortens the mole's Tunnel Home preparation.
  No new miner skill tree or unrelated system was added.
- Tunnel Home returns the player and attached relic to the Hub and preserves
  the exact dig site. Save migration covers old layers and detached/relocated relics.
- The mine action uses the approved pickaxe. Approved Gruvepappa v28 artwork is
  preserved. Discovery audio survives rapid common mining sounds.

## Verified candidate

Artifact **10097319961**, immutable ZIP SHA-256:
`633a8a54d12efb6bd1831cd60c69f56c6cb94c298af96d8c832bf47d83690a48`.
DEV PCK SHA-256:
`7757ec55406704ce613ced7c34e51581e2f1e06eb1cae893ab7486c03d5e5260`.

All thirteen active source and exact-DEV-package suites pass, including the
new-player progression, all five generated relics, paid Hub completion, continued
mining, streaming, save recovery, migration and live-goal checks. The journeys
accelerate gathering and positioning; they do not substitute for human pacing.
Both export flavors preserve their version, save and developer-resource boundaries.
The production candidate was checked but is not included in the DEV publisher.

Actual WebKit checks pass **869 gameplay** and **193 menu/touch** assertions.
Native finger taps are trusted browser events; simulated drag/cancel events are
recorded explicitly and span separate animation frames. The initial harness failures
and their causes are retained in the round-2 report, not relabeled as passing runs.

The exact PCK produced **34 native mobile captures / 431 assertions**, independently
inspected for onboarding, recipes, terrain, all five strata/relics, Home, Museum,
shops and post-fifth mining. Fifteen further images cover all five lighting styles
at 2532×1170. All restored controls are byte-identical; the compensated margin trim
has sparse differences up to 2/255 on at most 0.11045% of pixels with no visible
detail loss. Measured software gains of 3.13–7.01% include 0.39–4.17% control drift;
they do not establish an iPhone performance fix.

Hero validation includes 44 transition cases and real damage in twelve
worn/Crusher/Deepcore direction combinations. WebKit and Chromium audio checks
confirm trusted-gesture unlock, real output, protected discovery overlap and mute/
unmute. Subjective listening and physical-device smoothness remain unverified.

## Review and remaining acceptance

Two design improvement rounds corrected legacy save defects, a paid-speed cap,
goal/map/tutorial collisions and clipped action captions. Independent review finds
no critical bug or remaining concrete design blocker in the exercised paths.
The provisional DEV assessment is **8.4/10**, the mean of gameplay 8, progression 8,
UX 9, visual presentation 9 and code 8. Performance and the overall 1.0 score are
explicitly unverified and excluded from that mean. See `qa-round-2.md/json`.

The last physical measurement is still **DEV9: 52.1 FPS with normal pet lighting,
60 with pet lighting disabled**. It is not a measurement of this new candidate.
The new DEV needs sustained iPhone testing with normal lighting, mining, travel and
shop use; a brief cold 60 FPS peak is insufficient. Do not repeat the old DEV9 test.
Final 1.0 approval still requires at least 9/10 overall, no critical bugs and stable,
smooth physical iPhone behavior. LIVE publication is not authorized by this review.

## Publication contract

The reviewed identity and DEV-only flags are in `.github/one-point-zero/review.json`.
The publisher downloads those exact artifact bytes, verifies all six matching jobs,
preserves all nine LIVE files, archives the previous DEV/LIVE package and verifies
all eighteen public files. It performs no rebuild and cannot include the new
production package. The publication workflow's receipt records the actual outcome.

DEV: [corpax88.github.io/Ever-Deeper/dev/](https://corpax88.github.io/Ever-Deeper/dev/).
Source/review: [pull request 11](https://github.com/Corpax88/Ever-Deeper/pull/11).
Older failing historical suites remain documented in `docs/verification.md`; they
were neither weakened nor silently counted as passing current gates.
