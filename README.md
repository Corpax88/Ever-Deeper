Current verified release: [DEV15.6 terrain CPU improvement](docs/performance-diagnosis/dev15-6/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Canonical source6073b9d4dc11034d60305d5eb49785c033e836ed on codex/fps-dev15-6-20260923. Run35926247469 passed: five exported core cases,28 Skills/save checks,25 Chromium checks including17 exact full-frame pairs and ordinary WebKit startup. Measured section setup/draw CPU27.94% lower in Mac A/B/A; physical iPhone FPS and recorded250ms stall remain unverified. Scoped independent code9/10,visual8/10 accepted. Publication35927487060 verified all27 public hashes; LIVE1.0.0 and Worn unchanged. Approved hero/assets/animation/gameplay/saves unchanged. Do not repeat export/testing/publication for this unchanged candidate.

Current verified release: [LIVE1.0.0 production promotion](docs/premium-polish/live-1-0/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/ under Mats's explicit LIVE authorization. Current approved DEV content is now production without developer-menu/probe resources. Native hero/animation and required assets promoted together. Exact source 28667f9796d386472f021771ed9336223efe0a48 on codex/live-1-0-20260923. Test 35858775472 and publication 35859887837 passed; all27 public hashes verified. Six core cases,26 Skills checks,69 Chromium checks and ordinary WebKit passed;10 final images accepted (scoped code9/10,visual8/10). Production save identity retained; DEV saves remain separate. DEV15.5 and Worn bytes unchanged. No physical-iPhone claim. Do not repeat export/test/publication for this unchanged candidate.

Current verified release: [DEV15.5 retired Wayfarer shops and relocated quarry](docs/premium-polish/world-dev15-5/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. All five stores and ordinary purchase routes removed; Copper Ridge moved to (812,600), approach (812,650). Previously purchased speed retained. Exact source 57ab001fe2f4d1b9d37c608c290d05c668f6848a on codex/remove-wayfarer-20260923. Test 35855675070 and publication 35856567685 passed; all27 public hashes verified. Nine final images independently accepted, scoped code9/10 and visual8/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not repeat export/test/publication for this unchanged candidate.

Current verified release: [DEV15.4 silver tooltip headings](docs/premium-polish/skills-dev15-4/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Only the five Skills tooltip headings use light steel/silver; body and right-hand list text unchanged. Exact source 666cecf24214c2b144c5bc8403cfd526e625c416 on codex/skills-silver-headings-20260923. Test35848817678 and publication35849562311 passed; all27 public hashes verified. Five final tooltip captures accepted, scoped code10/10 and visual9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not repeat exports/tests/publication for this unchanged candidate.

Current verified release: [DEV15.3 Skills level and XP bars](docs/premium-polish/skills-dev15-3/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source30a2aff088d2e2219382c765a74bf37804f9ad73 on codex/skills-xp-bars-20260923; main holds publication/evidence. Test35846632446 and publication35847446465 passed, all27 public hashes verified. Gold bars show level/100; thin red bars replace numeric XP. Full level100 text verified.35 Chromium checks and ordinary WebKit passed, scoped independent9/10. Saves,21 native files,LIVE and trial preserved. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate. Standing DEV publication authorization persists.

Current verified release: [DEV15.2 approved tools icon](docs/premium-polish/hud-dev15-2/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact source d21215650f165c81e14ad0d56d202679eab740d5 on codex/approved-tools-icon-20260923; main holds publication/evidence. Test35830513108 and publication35831303971 passed, all27 public hashes verified. Approved PNG replaces only the HUD menu icon;104 image cap preserves120 touch target. Skills internal layout, saves and21 native files unchanged. Independent scoped review9/10. No physical-iPhone claim. Do not rebuild/retest/reupload this unchanged candidate.

Current verified release: [DEV15.1 larger gameplay icons and stat tooltips](docs/premium-polish/hud-dev15-1/HANDOFF.md) is published at https://corpax88.github.io/Ever-Deeper/dev/. Exact game source51e2c58ce8806d11c9fc608c6d6a9e48b74507c8 on codex/gameplay-icons-tooltips-20260923; main holds publication/evidence. Test run35822513557 and publication run35823540837 passed, all27 public hashes verified. Skills icon/layout sizes are unchanged by explicit user instruction; gameplay buttons are larger, stats explain themselves on hover/held touch. DEV saves, LIVE and retained trial preserved. No physical iPhone claim. Do not rebuild/retest/reupload this unchanged accepted candidate. Standing publication authorization persists; no new login is needed.

# Ever Deeper

The current game is a **Godot 4.7.2** project. Open `project.godot` in this directory.
The current candidate is `1.0.0-rc.1`; its DEV label is `1.0.0-dev.8`.
Tool Forge appearances now select their advertised models even when a drill is owned.
Read [the tool skin handoff](docs/tool-skin-HANDOFF.md) for DEV8 validation status.
The post-drill guide targets required ore, and opened drill barriers retain renewable ore.
Read [the drill guide handoff](docs/drill-guide-HANDOFF.md) for DEV7 validation and publication status.
The Starforge Hub visit now stays completed across checkpoints, exit and reload; older affected saves recover automatically.
Read [the Hub guide handoff](docs/hub-guide-HANDOFF.md) for DEV6.
Discoveries supply their first Hub building, nearby finds get visible clues, and Starfall opens after Ember mastery 1.
Read [the discovery-loop handoff](docs/discovery-loop-HANDOFF.md) for this change and [the 1.0 handoff](docs/one-point-zero/HANDOFF.md) for earlier work and remaining acceptance gates.
LIVE remains the separate published 0.46.9 package until explicitly accepted.

## Start here

- [Code map](docs/code-map.md): where to make each kind of change.
- [Verification](docs/verification.md): current checks, mobile review and known older failures.
- [Project rules](AGENTS.md): approved art and the mandatory visual release gate.
- [Cleanup review](docs/cleanup-review.md): independent scores, changes and remaining debt.

## Run and check

Install the standard Godot **4.7.2** editor. From this directory:

```sh
godot --editor --path .
python3 tools/qa.py --godot /path/to/Godot
python3 tools/check_invariants.py
```

`GODOT_BIN` can supply the executable instead of `--godot`.
The QA launcher isolates test save files, checks exit codes and completion markers,
and fails on runtime errors or timeouts. Its default is the current source suite;
older failing checks remain available explicitly, with their failures documented.

## Web builds

Install matching Godot 4.7.2 export templates, create the output directories, then:

```sh
godot --headless --path . --export-release 'Web DEV' builds/dev/index.html
godot --headless --path . --export-release 'Web Production' builds/live/index.html
python3 tools/qa.py --godot /path/to/Godot --pack builds/live/index.pck --cases build-flavor
```

DEV retains its developer menu and isolated saves. Production excludes the developer-menu
resource. Publishing is a separate, reviewed step; exporting or changing source does not
publish a build. The historical release workflows under `.github/` record prior releases.

Older JavaScript-prototype instructions are historical, not instructions for this game.
No source archive or chain of release patches is needed to open this complete project.
