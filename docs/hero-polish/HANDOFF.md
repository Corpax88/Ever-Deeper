# Hero polish — candidate under review

Base: DEV15.49, source a329c45dd26d535e7cd224452e5845585c68b3bb.
Exact baseline PCK: a6ee6055fadd66082b42fc54063c24203f674fd4db8694f88e53591829834852 (316990886 bytes).

Preserve approved v28 pappa identity, clothing design, original rest mesh and 17-bone rig. Original private Blender source/reference photos are not part of this public change.

Changes: authored two-handed tool-space mining at existing .42 hit phase; both wrist reach constraints in contact retargeting; original fitted boot trajectories with cyclic torso motion derived from Quaternius Jog_Fwd_Loop; ground-distance stride matching; sleeve weight fitting and matte cloth response. Gameplay speed/damage/mining clock remain unchanged. Eight native pickaxes share this body. Three drill skins still use their existing sprite fallback.

Source motion: Quaternius Universal Animation Library Standard, CC0-1.0. Downloaded archive SHA256 18ff1a7215f4852b320203e8aaf02a1578b5c8eef9027fbaedfcedc7b85a3ac2, https://opengameart.org/sites/default/files/universal_animation_librarystandard.zip . Only cyclic torso motion is retained: the first full human-leg retarget was rejected after actual render review because it lifted this stocky hero too far above the fitted stance.

Critic rounds 1–2 rejected close-to-face one-handed mining, compressed sleeve and lifted gait. Candidate 2 rebuilds the swing around fixed shaft grips and retains the approved short-leg contact path. Final critic/render gates still pending at this commit; no production acceptance claim.

Verification: .github/hero-polish/build.py preserves and byte-checks every non-replaced PCK resource. tools/review_hero_polish.gd uses actual Endless mining owner, damage and impact serial, real ore texture, eight gear switches, stopping transitions and measured two-hand grip error. Fixed 30fps captures are motion evidence, not FPS measurements. macos-15 workflow adds ordinary WebKit startup; no physical iPhone claim.

Publication target, if all gates pass: DEV15.50 only, preserving LIVE and existing Worn preview. Never rebuild main; it is a publication carrier. Permanent GitHub/DEV authorization remains in force. The task is not complete until actual visual evidence, final critic disposition and exact publication/source receipts are recorded.
