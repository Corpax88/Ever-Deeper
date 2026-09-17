# Ever Deeper

Published milestone: [DEV11 verified, 17 September 2026](docs/premium-polish/dev11-feedback-20260917/PUBLISHED.md).
Current candidate: [DEV12 upright Moss north edges](docs/premium-polish/dev12-north-edge-20260917/HANDOFF.md), not yet published.
This branch now uses a clean version-3 binary save format; older saves are intentionally invalid.
Premium polish continues; stable 50 FPS and final 1.0 acceptance remain open.

The current game is a **Godot 4.7.2** project. Open `project.godot` in this directory.
The production candidate label is `1.0.0-rc.1`; DEV12 is under review.
The published DEV label remains `1.0.0-dev.11`.
Tool Forge appearances now select their advertised models even when a drill is owned.
Read [the tool skin handoff](docs/tool-skin-HANDOFF.md) for DEV8 validation status.
The post-drill guide targets required ore, and opened drill barriers retain renewable ore.
Read [the drill guide handoff](docs/drill-guide-HANDOFF.md) for DEV7 validation and publication status.
The Starforge Hub visit stays completed across checkpoints, exit and reload. The older DEV6 save-recovery notes below describe that historical release, not this branch's new save epoch.
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
