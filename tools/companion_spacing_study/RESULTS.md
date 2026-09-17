# Follow separation pilot — source readiness

This tools-only pilot uses the exact published DEV12 package. No shipped script, art, player input, mining owner, task clock, save or publisher is edited.

The companion updates its follow destination from the current resolved hero position, yields through terrain-valid local steps, and waits safely beside the hero until it passes. A 64 px comfort gap retains the existing 50 px exclusion distance. Each physics tick has one movement budget, bounded by the existing 580 px/s catch-up ceiling. Other task movement delegates to the original owner. Foot depth is refreshed through the existing world owner after movement.

Current headless evidence: 260 geometric checks across 51 traces, all 50 unchanged packaged companion-autonomy assertions, and 11 actual packaged lifecycle checks pass. Initial overlap must actually recover in open ground. A dead-end corridor may trap the companion; player authority and terrain validity take priority. These results do not establish visual clearance, ordinary natural-route parity or performance.

Preserved earlier trials: the 82 px comfort gap delayed one real automatic impact beyond the original test window, causing three assertions to fail; no assertion was relaxed. Earlier local steering alternated sideways on constrained paths; the successful variant retains an escape direction and waits for the hero to pass. The first integration driver queried a deferred node too early; that log is preserved and the driver now waits for installation. Raw logs and reports remain under evidence/companion-spacing in the session evidence collection.

A before/after rendered comparison with the published package is the next gate. No visual acceptance, DEV adoption, mobile FPS improvement or complete avoidance guarantee is claimed.

## Exact tested files

- follow_separation.gd: SHA256 `39c4bbf5f940c530062734536306f3e820476d834ba99b7b9c2e4769aeca49bd`.
- pilot_mole.gd: SHA256 `10af22c2c4881e4bd4a5b706a4c4b9adc19f76e216f4a43d30398c2a0135bbec`.
- pilot_main.gd: SHA256 `8d8945a51a512d0bd9e2182e5fd3523f2dc2138ce31662bea8278e953da2d48f`.
- pack_overlay.gd: SHA256 `6db8f857bbb817c9d1f133dfb3c3463eeb827c3531d674994059ec2c59431017`.
- trace_mole.gd: SHA256 `8c56f1aac2b68f48cdfb2afc6d0203e4ce58ef3cab2d11bbd99a9a0e3cf0edca`.
- check_geometry.gd: SHA256 `579f954745c2878b626ea1c1362254135f82ac281f51ac6fcfc942b6cffe2238`.
- check_integration.gd: SHA256 `b5084fb1aa902261c8500770c1a592a3466acc55e0804e309635f8e8763cd030`.
- check_lifecycle.gd: SHA256 `b84c2f45c0c4d8a29cf52069d43c979236fc1bedbc8c850bf7a7512b42fe99fb`.
