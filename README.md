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
