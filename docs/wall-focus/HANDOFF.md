# DEV15.59 — published and verified, 5 October 2026

Wall progress now appears at the target wall as 0/10 through 9/10, with local 10/10 passage-open feedback. Quest text has no background box and sits mid-right, with an outline for contrast. Minimap remains top-right and Skip clears the quest. Saves, ten-hit mechanics, tool requirements and approved assets are unchanged. Refresh DEV and Continue; no reset needed.

Canonical source `4e5cb9339bf2be49596d2ab7ced2f92e13639786` on `codex/wall-focus-20261005`; runtime payload unchanged from602878cf. Exact production artifact11371552790, successful Mac QA37375569164. Native667×375,844×390,932×430 each passed37checks; all30PNG sizes verified. Retained input and ordinary Apple WebKit startup/save/reload passed. Root and critic inspected actual final images; exact lists are in root-review.json and critic-review.json. No physical-iPhone performance or human eye-tracking claim.

Publication commit5f28a68ddec294a55db507617fb5694cd2376680/run37376834552 succeeded. Receipt artifact11371618905 verifies all26public file identities, preserving8LIVE1.0.5 and9Worn files plus unchanged shared DEV engine. Rollback artifact11371768408 retains DEV15.58. Production PCK327928258bytes, SHA256 dac0bb17dd40eff5449ab1a844134b0e5282aea8a0951f742537162d9a39e087. Main remains a publication carrier; never export its historical runtime.

Website source6171ed3df22f4e80f322b5bbe9986fdee8e43fe2, version12, deploymentappgdep_6ac418cd3f648191b6201857dd445e47 succeeded at https://ever-deeper-game.corpax88.chatgpt.site.85release records, all84historical records preserved;244local links checked. No pending jobs or approvals. Do not repeat accepted unchanged tests or publication. Preserve parked FPS/rotation work. Bright Surface at667px is the weakest contrast but reviewed as readable; existing narrow secondary hint truncation remains.

## Historical work log — superseded status, retained test limitations

# DEV15.59 — wall hits and quest visibility

Candidate source4e5cb9339bf2be49596d2ab7ced2f92e13639786 (runtime unchanged from602878cf5a8bddff7cb2faecfe8636ba99db5639) on codex/wall-focus-20261005; based on verified DEV15.58/d564e79. QA37374874149 completed but native-size evidence rejected: requested1334/1688/1864 windows were clamped to1024×654/656. No publication accepted. Corrected QA uses667×375,844×390,932×430 with actual framebuffer and image-size assertions; production bytes remain identical. Not yet published.

User asks for wall-hit text at the wall, explicit ten-hit progress, and transparent quest text mid-right. Seven runtime files changed: D1/D2 target text now reads shared persistent barrier hits after existing tool requirements; repeated bottom WALL messages removed; a reused local completion label fades after10/10. Quest panel uses StyleBoxEmpty with4px text outline; its right-middle position clears controls, minimap is independently top-right, Replay/Skip stays above quest. Shared target placement excludes hero, quest, map and active action controls. No gameplay, save, asset or balance change.

Native Linux Godot4.7.2, authenticated Xvfb/Mesa llvmpipe,1334x750:36checks and10actual images passed; independent critic inspected all10. This is not physical iPhone/FPS or human gaze measurement. Mac exact-pack three mobile aspects and ordinary Apple WebKit checks are in .github/workflows/wall-focus.yml. Tests use explicit teleports, tool grants, fixed selection and D2 approach/cavern exposure; damage and barrier counters use real production owners. Test step2 uses companion flag. Prior native attempts are retained: first found an unguarded missing metadata lookup (fixed); later fixture needed queue_redraw after freezing processing and explicit D2 exposure. Those earlier images do not validate wall placement.

Canonical editable source restored in /workspace/scratch/ada1db9371d3/game-wall; old game worktree points into a vanished git directory and is not authoritative. Native runtime /workspace/scratch/ada1db9371d3/runtime/Godot_v4.7.2-stable_linux.x86_64; extracted Xvfb under runtime/xvfb/usr/bin/Xvfb. Build production from immutable15.58 artifact11366866551/run37360610341 using .github/wall-focus/prepare.py, which verifies baseline PCK and every unchanged payload. Local candidate wall-candidate matches uploaded source by individual git blob identities. Local evidence evidence/wall-native4-667.

Protected-file invariant tool still fails for7historically changed files (data/ever_deeper_v0381.json,data/source_manifest.json,project.godot,cave_light_occluders.gd,hero_gear.gd,player_controller.gd,player_visual.gd); none changed against canonical15.58. Not counted green. Do not alter old invariant baselines to silence this.

Publication must use reviewed immutable artifact bytes, preserve8LIVE1.0.5 and9Worn plus unchanged shared DEV engine. Main is publication carrier only. .github/wall-focus/publish.py reuses only the previous proven transfer/staging/verify transport with new exact-source/report/artifact acceptance. After public26-file verification, publish prepared Site update (85records,84historical retained,244local links checked). Do not mark complete before Site succeeds. Preserve parked FPS/rotation work.

## Rejected Mac size claim
Initial Mac source602878cf passed36checks per run and ordinaryWebKit, but exact PNG dimensions exposed window-manager clamping. Root and critic independently found the mismatch before acceptance. Three native runs are not three mobile aspects; do not use them to claim that. Corrected QA4e5cb933 records actual root.size and each capture size and asserts exact requested dimensions. No gameplay edit or gate removal.

Current corrected QA37375569164 queued (Mac job111983288800); no runner/steps assigned yet. Local667×375 exact-size proof passed37checks. Website source6171ed3df22f4e80f322b5bbe9986fdee8e43fe2 saved as version12/appgver_26e8683697e08191948b02fa89f92778; not deployed until game publication.

## Corrected QA completed
Run37375569164 passed on source4e5cb933. Native667×375,844×390,932×430 each passed37checks and produced10PNG images; actual image dimensions verified independently. Five downloaded evidence ZIPs match their immutable artifact digests. Retained input and ordinary Mac Apple WebKit startup/save/reload passed. Production artifact11371552790 has PCK327928258bytes, SHA256 dac0bb17dd40eff5449ab1a844134b0e5282aea8a0951f742537162d9a39e087. Root actual-image list and independent critic report are stored beside this handoff. Publication and website deployment remain pending until their receipts are recorded below.
