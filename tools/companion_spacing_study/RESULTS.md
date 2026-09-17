# Follow separation pilot — source readiness

This tools-only pilot uses the exact published DEV12 package. No shipped script, art, player input, mining owner, task clock, save or publisher is edited.

The companion updates its follow destination from the current resolved hero position, yields through terrain-valid local steps, and waits safely beside the hero until it passes. A 64 px comfort gap retains the existing 50 px exclusion distance. Each physics tick has one movement budget, bounded by the existing 580 px/s catch-up ceiling. Other task movement delegates to the original owner. Foot depth is refreshed through the existing world owner after movement.

Current headless evidence: 260 geometric checks across 51 traces, all 50 unchanged packaged companion-autonomy assertions, 11 actual packaged lifecycle checks and 24 recorded-wall regression checks pass. Initial overlap must actually recover in open ground. A dead-end corridor may trap the companion; player authority and terrain validity take priority. These results do not establish visual clearance, ordinary natural-route parity or performance.

Preserved earlier trials: the 82 px comfort gap delayed one real automatic impact beyond the original test window, causing three assertions to fail; no assertion was relaxed. Earlier local steering alternated sideways on constrained paths; the successful variant retains an escape direction and waits for the hero to pass. The first integration driver queried a deferred node too early; that log is preserved and the driver now waits for installation. Raw logs and reports remain under evidence/companion-spacing in the session evidence collection.

The first actual right A/B at `a6534b1e` preserved all 195 hero/damage samples and six events, with minimum center gap improved from 5.46 to 54.17 px. Independent review nevertheless rejected a visible steering/facing reversal at frame 135. The unchanged original comparison and failed images are retained.

The correction gives a safe stationary hold priority over inward following only while avoidance is active and the hero is still approaching. An unsafe hold still permits the existing safe preferred escape. The new `check_recorded_wall.gd` injects the actual measured 130–138 hero trace into the same packaged seed/depth terrain, with the floor hash checked. The old helper reproduces every recorded companion position exactly and fails the two reversal assertions; the corrected helper passes all 24 checks, including an unsafe-hold/safe-escape counterexample. The corrected sequence keeps at least 67.02 px swept separation. These explicitly injected states are not an ordinary-input or visual acceptance.

Fresh rendered right and up A/B comparisons remain required. No DEV adoption, mobile FPS improvement or complete avoidance guarantee is claimed.

## Exact tested files

- follow_separation.gd: SHA256 `6cd2d6f3baa1f302cd0c1ba4596185b7281af174e52f302dc4e48566fe885358`.
- pilot_mole.gd: SHA256 `10af22c2c4881e4bd4a5b706a4c4b9adc19f76e216f4a43d30398c2a0135bbec`.
- pilot_main.gd: SHA256 `8d8945a51a512d0bd9e2182e5fd3523f2dc2138ce31662bea8278e953da2d48f`.
- pack_overlay.gd: SHA256 `6db8f857bbb817c9d1f133dfb3c3463eeb827c3531d674994059ec2c59431017`.
- trace_mole.gd: SHA256 `8c56f1aac2b68f48cdfb2afc6d0203e4ce58ef3cab2d11bbd99a9a0e3cf0edca`.
- check_geometry.gd: SHA256 `579f954745c2878b626ea1c1362254135f82ac281f51ac6fcfc942b6cffe2238`.
- check_integration.gd: SHA256 `b5084fb1aa902261c8500770c1a592a3466acc55e0804e309635f8e8763cd030`.
- check_lifecycle.gd: SHA256 `b84c2f45c0c4d8a29cf52069d43c979236fc1bedbc8c850bf7a7512b42fe99fb`.

- check_recorded_wall.gd: SHA256 `76e8393001d5f8dd82230406b6fefdd532edad70cbb79a03bb89f1e74bf0f1d8`.
