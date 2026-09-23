Current verified release: [DEV15.3 Skills level and XP bars](docs/premium-polish/skills-dev15-3/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source30a2aff088d2e2219382c765a74bf37804f9ad73 on codex/skills-xp-bars-20260923; main holds publication/evidence. Test35846632446 and publication35847446465 passed, all27 public hashes verified. Gold bars show level/100; thin red bars replace numeric XP. Full level100 text verified.35 Chromium checks and ordinary WebKit passed, scoped independent9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate. Standing DEV publication authorization persists.

Current verified release: [DEV15.2 approved tools icon](docs/premium-polish/hud-dev15-2/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source d21215650f165c81e14ad0d56d202679eab740d5 on codex/approved-tools-icon-20260923; main holds publication/evidence. Test35830513108 and publication35831303971 passed, all27 public hashes verified. Approved PNG replaces only the HUD menu icon;104 image cap preserves120 touch target. Skills internal layout, saves and21 native files unchanged. Independent scoped review9/10. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate.

Current verified release: [DEV15.1 larger gameplay icons and stat tooltips](docs/premium-polish/hud-dev15-1/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact game source51e2c58ce8806d11c9fc608c6d6a9e48b74507c8 on codex/gameplay-icons-tooltips-20260923; main holds publication/evidence. Test run35822513557 and publication run35823540837 passed, all27 public hashes verified. Skills icon/layout sizes are unchanged by explicit user instruction; gameplay buttons are larger, stats explain themselves on hover/held touch. DEV saves, LIVE and retained trial preserved. No physical iPhone claim. Do not rebuild/retest/reupload this unchanged accepted candidate. Standing publication authorization persists; no new login is needed.

Current verified release: [DEV15 locked Skills menu and active stamina](docs/premium-polish/skills-dev15/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact game source b788ca7484bc99bb210255851dacca35db501d5f on codex/locked-skills-ui-20260922; main holds publication/evidence. Test run35795605519 and publication run35796692140 passed. All27 public hashes verified; DEV save identity, LIVE and historical trial retained. Physical iPhone remains unverified. Do not rebuild/reupload/retest this unchanged accepted candidate. Mats's standing publication authorization persists; no new login is needed.

Current verified release: [DEV14.3 upgraded pickaxe motion](docs/premium-polish/dev14-native-worn/DEV14.3.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Publication run35708487161 passed and all27 public hashes are verified. Exact game source1632526b0cb675e5efd5709b0e55a6ab7ef970d9; passing validation49668d1139dd44118f333c775b4b4c02881e7722/run35706535761 reused the immutable export from35704702742. All eight original pickaxes use the approved native hero/motion; fast Comet transitions are corrected. Independent narrow review8.5/10; Mac DPR3 windows56.27–59.32rAF FPS, worst stall184ms. Physical iPhone/Simulator FPS and the previous phone crash remain unverified. Preserve DEV saves and LIVE/trial bytes. Use the existing authenticated GitHub connection: no new login is needed. Mats approved public upload/publication after gates ("Alltid"). Do not repeat this unchanged export or its passing tests.

Current verified release: ordinary DEV14.2 is published at https://corpax88.github.io/Ever-Deeper/dev/. Publication run 35618558489 passed; all 27 public hashes are verified, including unchanged LIVE and retained trial bytes. Exact game source is bee888fe36d6b8285e1198384d40694d3154956a, passing candidate run 35616856586. Continuous steering clipping is fixed; the same hero uses an indexed LOD preserving skin, materials and motion. Mac DPR3 window averages were 53.60–59.76 rAF FPS, with stalls up to 400 ms; physical iPhone FPS and the prior phone startup crash remain unverified. Preserve the DEV save namespace. See docs/premium-polish/dev14-native-worn/DEV14.2.md. Do not repeat exports or tests for this unchanged candidate.

Current verified release: ordinary [DEV14.1](docs/premium-polish/dev14-native-worn/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/ (menu version 1.0.0-dev.14.1).
Publication run 35610110028 passed and all 27 public file hashes are verified. Exact game source is 6d6e1b8d98ecae6661b514fff92e28447715dd33 on codex/hero-loop-flow-20260918; main holds publication and evidence. The same hero is loaded from a prepared PackedScene; animation is retained. Mac Chromium/WebKit checks passed; the physical iPhone crash is NOT confirmed fixed and the native Simulator attempt was inconclusive. Preserve the DEV save namespace and LIVE bytes. The current handoff supersedes older checkpoint and pending-publication statements below. Do not repeat exports/uploads/tests for this unchanged candidate.

# Ever Deeper project rules

## Visual release gate

These rules are mandatory for every visual change, in every chat and for every agent.

1. An approved mockup is the visual acceptance target. Preserve its material quality, silhouette, depth, lighting, palette, and integration with the game.
2. A mockup is concept art, not a production asset. Build the result with proper production assets and integration.
3. Do not replace an asset-led design with procedural polygons, generic shapes, placeholders, stretched crops, or a lower-detail approximation unless Mats explicitly approves that exact change first.
4. Before publishing, capture the final build at the target mobile viewport and compare it visually with the approved mockup. Source review, parser tests, headless startup, and FPS tests do not count as visual verification.
5. Check every affected visual state, including normal terrain, corners, barriers, permanent walls, transitions, and relevant biomes or depths.
6. If the final build cannot be rendered and inspected, stop. Do not publish and do not describe the work as finished.
7. Publish only after both visual fidelity and gameplay checks pass. Never infer visual quality from successful code or automated tests.
8. Any exception requires Mats's explicit approval before implementation or publication.

## Asset definitions

- Asset: one production PNG with transparency, no text, no background, and no mockup composition.
- Mockup: a concept sheet used as a visual target.
- Sprite sheet: real animation frames, not a collage of concepts.

## Finding and verifying code

Start with README.md and docs/code-map.md, then read the named owner of the change.
The root Godot project is authoritative. Historical JS code and release patches are not
current runtime source. QA startup belongs in scripts/qa/qa_launcher.gd and named suites.
Keep gameplay/save changes separate from structural cleanup. Run tools/qa.py and
check_invariants.py as described in docs/verification.md; report known legacy failures
honestly. Do not remove debug/save compatibility APIs based only on textual reference counts.
