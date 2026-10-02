DEV15.46 published and verified: publication02699fd32280d07aa87ecc40e443a38656c0b592/run36982408035; receipt11216152475 confirms27 public hashes, LIVE1.0.4 and Worn preserved. Rollback11215424940 retains DEV15.45. No pending jobs. Refresh → Continue; no reset. 

# Crusher skin during Bore Rush — DEV15.46 published

User confirmed DEV15.45 Rush flow on physical phone, then reported rigid pickaxe held forward when Crusher cosmetic is equipped. Approved direction: retain Crusher, rotate its head, lean forward with both hands. User requested independent critic before publication.

Base: f79c19a8f534aa90616468c64a9fc1e1b9c2e491; immutable DEV15.45 artifact11193870007 from36923988208. Main is publication carrier only. `.github/bore-crusher/build.py` verifies all nine baseline hashes and every retained PCK payload. Four source/remap replacements plus version label; no gameplay, asset, save or balance changes.

Native rig keeps authored feet/gait; presentation-only upper-body lean and rigid hand IK. Original Crusher triangle/vertex/material data partitions into static shaft and rotating relief head, no replacement geometry. Spins2.4rev/s, blends pose140ms, settles head on release. Original mesh restored outside Rush; equipment change resets overlay.

Canonical candidate source74d63df43fbc2a6054280a384a34e2eb9b9f810b on codex/bore-crusher-20261002. Final immutable package validated; publication acceptance is recorded in .github/bore-crusher/accepted.json. Local runtime Godot4.7.2 in /tmp/bore-runtime, extracted Xvfb in runtime/xvfb. `tools/review_bore_crusher.gd` renders 8 bearings/four head phases, checks travel, native rigidity, grip/foot preservation and release. Initial fixture did not unlock skin; corrected by building real workshop. Native captures are not physical phone/FPS evidence. Existing invariant flag-order debt remains. Mac input, 414 premium-core checks,75 browser checks and ordinary WebKit startup/save/reload all passed. Standing DEV upload/publication authorized; LIVE separate.

## Regressions found before publication

- First browser fixture ran hub/relic travel to unlock the skin and produced zero movement in a displaced state. Fixture now unlocks only the forge cosmetic, preserving world setup.
- Actual ore impacts injected ordinary pickaxe poses into Rush. Presentation packet now consumes impact serials while suppressing the ordinary swing during the bore brace; gameplay impacts remain authoritative.
- Quick turns and walk/stop transitions exposed unreachable grips because the logical heading/root moved ahead of the displayed body. Tool heading AND position now follow the displayed torso. Existing rigid-length rejection remains enabled.
- Targeted impacts fixture reproduces rejection before the fix. Final candidate7 passes22 actual rock hits and four impact/turn directions (6checks). Older impacts4/5/6 also had an incorrect hub-travel fixture for the terrain-count assertion; only corrected impacts7 is accepted.

Final local native evidence targets candidate7: render7 (8bearings/48captures/56assertions), transitions7b (10captures/5assertions), impacts7 (5captures/6assertions). Matching Godot4.7.2, Xvfb/Mesa,1688x780; transition harness uses a separate authenticated display90 after occupied display89. These results require completion markers and zero script errors. Mac36981607422 passed with identical nine-file manifest; candidate artifact11216365939, evidence11216081603. Known invariant flag-order assertion remains inherited and is not claimed green. No physical-phone/FPS claim.
