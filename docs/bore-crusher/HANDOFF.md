# Crusher skin during Bore Rush — DEV15.46 candidate

User confirmed DEV15.45 Rush flow on physical phone, then reported rigid pickaxe held forward when Crusher cosmetic is equipped. Approved direction: retain Crusher, rotate its head, lean forward with both hands. User requested independent critic before publication.

Base: f79c19a8f534aa90616468c64a9fc1e1b9c2e491; immutable DEV15.45 artifact11193870007 from36923988208. Main is publication carrier only. `.github/bore-crusher/build.py` verifies all nine baseline hashes and every retained PCK payload. Four source/remap replacements plus version label; no gameplay, asset, save or balance changes.

Native rig keeps authored feet/gait; presentation-only upper-body lean and rigid hand IK. Original Crusher triangle/vertex/material data partitions into static shaft and rotating relief head, no replacement geometry. Spins2.4rev/s, blends pose140ms, settles head on release. Original mesh restored outside Rush; equipment change resets overlay.

Validation in progress; do not publish before actual candidate captures and critic acceptance. Local runtime Godot4.7.2 in /tmp/bore-runtime, extracted Xvfb in runtime/xvfb. `tools/review_bore_crusher.gd` renders 8 bearings/four head phases, checks travel, native rigidity, grip/foot preservation and release. Initial fixture did not unlock skin; corrected by building real workshop. Native captures are not physical phone/FPS evidence. Existing invariant flag-order debt remains. Mac input/core/browser/WebKit gate pending. Standing DEV upload/publication authorized; LIVE separate.
