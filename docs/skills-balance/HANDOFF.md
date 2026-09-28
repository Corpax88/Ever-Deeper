# DEV15.19 — approved mobile skill balance

28 September 2026. Mats approved the proposed mining curve and stamina recovery, with activity-paced other skills. FPS investigation is parked by explicit user decision: DEV15.18 report averaged56.16FPS over227.708s; the user independently observed53–60FPS without recording. This does not establish a root cause or a general FPS fix. Keep diagnostics and all render/audio quality unchanged. No more performance matrices are part of this task.

## Balance

- Mining retains4XP per registered mining swing. Next level costs80+8L XP, exactly20+2L registered swings. At current level25 this is70 swings; at50,120. The existing game awards on registered swings, not only successful ore breakage.
- Running and loaded Carrying retain distance/64 XP with80+8L thresholds. Their progression is paced by actual travel, not frame count or teleports. Exact time varies with speed, fatigue and collisions.
- Prospecting retains1XP per genuinely mined resource, with10+L resource requirements. Resource yield varies by tool and ore; this is an initial activity-paced balance, not a claim of identical seconds per skill level. Grants never train it.
- Recovery25/s after0.4s continuous rest: empty-to-full4.4 active seconds. Moving/mining and paused-menu rules, drain and fatigue penalties remain unchanged.
- Every skill caps at100; curve thresholds also drive cached-level invalidation and level-up signals.

## Saves

New optional state field `miner_skills_balance=2`. Old saves preserve each skill's level and fractional progress by converting old cumulative XP; stamina and other state remain intact. New saves do not migrate twice. No-skill historical saves use recorded swings/resources through the same old-curve conversion. Raw XP numbers change representation; no level loss or sudden retroactive level jump is intended.

## Package and validation

Patch exact DEV15.18 artifact10985222333/run36454484995, verifying all nine file hashes and all PCK resource MD5s. Only skill definition, RunState, its named QA suite and version resource change. HTML file size is updated; JS/WASM/audio/assets/other gameplay resources remain byte-identical. Main remains publication carrier. No new exports of historical main.

`.github/workflows/skills-balance.yml` verifies boundary/migration/cached-level/recovery tests on the actual pack, selected existing core cases, graphical real-input mining/Skills/recovery and ordinary WebKit new/save startup. Inspect actual captures before accepting immutable package. Physical-phone balance acceptance remains user testing after publication.

## Accepted validation

Source ba3ddb8a104e471d05b79752dd3d6cd555709875; run36468821047: core and browser passed.1249 skill/migration/recovery assertions, four existing core suites, ten browser checks/captures;9 actual images inspected. Native Godot4.7.2; Chromium Metal Apple GPU, CSS844x390/render DPR2; ordinary MacWebKit. Candidate10991241204, ZIP SHA25667828565c01aa7fdaaf7e5009253b90556be6ee2a87b14fc592c44814dc4a325. Source invariant checker is not green: sparse checkout omitted its old manifest. PCK per-resource preservation passed. First run36468678575 failed only because the wrapper used unregistered short case names; corrected names passed. No source/game fix was required after the initial balance patch. Published7abbd960a2456ac131d072b74d38221b88167fa6/run36469426862: package/deploy/verify passed; all27 public hashes match;9 LIVE and9 Worn preserved. Receipt10991118134. No jobs remain pending.
