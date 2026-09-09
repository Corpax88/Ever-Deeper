# DEV 2: clear access to Settings

Source candidate: `246ee70cca3cff2eae0fe417800cf2d1724c6417`.
Validation run: [34349012950](https://github.com/Corpax88/Ever-Deeper/actions/runs/34349012950).
DEV version: **1.0.0-dev.2**. Exact-package review passed; approved for DEV publication.

## Scope

The DEV toggle obscured the gameplay menu. It now follows the HUD's responsive
menu bounds and sits below the top button row. Pausing retains the existing
corner position; returning to play restores the separate row. Native safe-area
insets remain respected. Gameplay, saves, artwork, lighting and audio are unchanged.

Visual review also found a pre-existing first-open drawer sizing race. Child
layout could leave a 640-unit drawer extending off a small phone even after its
minimum size fell to 147. Relayout on `minimum_size_changed` fits the panel after
its content settles. At 844×390 it now measures 720×450.5454 logical units and
ends 12 logical units above the bottom edge. All lower commands are visible at
maximum scroll, including relics, workshops and Reset DEV Save.

## Local checks

Existing source menu/touch, developer tools, iPhone layout and orientation cases
passed. Native captures at 844×390, 932×430 and 1280×720 cover gameplay, a routed
tap on Menu, a routed tap on DEV, and the bottom of the scrolled drawer.
These are software-rendered captures, not physical iPhone measurements.

The first CI run, 34348288176, correctly rejected the old hardcoded DEV version
expectation in the capture driver. Its source cases passed; two exported cases
stopped at the version check. Expected versions now explicitly match DEV 2.
One concurrent local packed touch run exited without its completion marker and
was counted as failed; the same unchanged PCK passed all 123 touch assertions
when run sequentially. All six final exact-package CI jobs subsequently passed. Mobile WebKit passed 869
gameplay and 193 menu/touch assertions; the native journey produced 34 captures
and 431 successful assertions. Both browser audio checks and hero-motion checks
passed against the same candidate.

## Independent acceptance

The critic inspected all 12 final layout images and accepted this bounded fix at
**9/10**, with no remaining critical bug or code/layout blocker in its scope.
The original whole-game provisional score remains **8.4/10**. No physical iPhone,
final 1.0 or LIVE approval is implied. The immutable candidate is artifact
**10102987319**, ZIP SHA-256
`eb5d344c9368192c345637640dfc3fc3697ec84e373339daaefa7a0322e6a38f`.
PCK SHA-256: `c331cde35f64edf26a9d10c921e46ad1ef9bd3001aea225b521a38c86ea0ca36`.
See `dev-button-evidence.json` and `dev-button-ci-jobs.json`.

## Physical test after DEV publication

Open the DEV page in Safari and confirm **1.0.0-dev.2**. Verify that Menu/Settings
and the relocated DEV button open independently. In the Hub, choose
**DEV TOOLS → AUTO FPS TEST · 3 MIN**. Stand still and keep the game visible for
the entire test. It temporarily compares lighting configurations, restores the
original graphics, and displays a results table; send a screenshot and phone model.
This diagnostic does not write gameplay state or graphics options into saves.

Then play normally for 10–15 minutes with **SHOW FPS**: mine continuously, collect
resources, return using Tunnel Home, and use a workshop. Send the FPS readout
near the end and describe any stutter, missed taps, or weak upgrade feedback.
A screen recording can help assess animation/UX, but measure FPS without recording.
The stationary lighting test alone cannot certify mining/travel performance or
human progression pacing. Final 1.0 and LIVE approval remain pending.
