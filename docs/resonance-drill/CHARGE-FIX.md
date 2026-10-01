# DEV15.35 — charge/excavation ordering fix

Mats reported that Crusher 5x5 removed the mountain before the resonance shot.
Root cause: the ordinary resource/terrain impact ran before on_hit; the DEV command
retains Crusher, but the previous QA fixture replaced that loadout with Deepcore.

When resonance is enabled with a drill, the hero impact now charges/fires only.
Ordinary resource and Crusher terrain strikes remain the disabled-mod path.
The existing advancing wave owns terrain destruction and persisted loot.
No asset, save format, shop price, normal tool balance, or LIVE change.

QA must use the real DEV-command Crusher loadout and assert unchanged dug cells
at visible charge, followed by actual automatic excavation. Native Godot4.7.2
Xvfb/Mesa passed14 checks; all four actual candidate images were inspected.
Mac/browser run36815973823 validates source8bc0fcc65a15a8852c7fcd405d0e1c5fb6c79e51.
Publication status is owned by the immutable acceptance and public receipt.
Physical iPhone/FPS not certified; historical invariant debt remains.

Mac QA passed20 browser gates plus input/404 core and ordinary WebKit. All14 Mac PNGs inspected; manifest equals native candidate. Immutable candidate11141178271, evidence11141282844. Publication pending.
