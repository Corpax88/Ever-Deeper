# Current handoff — 20 September 2026, user requested a new chat

Mats explicitly requested a new chat. Stop at this saved checkpoint; do not publish merely to complete the handoff. On continuation the task remains a controlled playable Worn trial, not full game/LIVE adoption.

## Exact source and retained bytes

Runtime/test/publisher source is aa4362aaeff03be9013a1da3f090634f7f0b35fc, tree e378452ac5e0bb888c5ea927ec0ca1ab629b54b8, branch codex/hero-loop-flow-20260918.
This handoff commit changes documentation only.
Saved private file Ever-Deeper-Fortsett-her.md version96 contains full recovery instructions and prior decisions.
Saved exact candidate/evidence: Ever-Deeper-Worn-nettleser-kontrollpunkt-20260920.zip, 308813023 bytes, SHA256 110aa9f714145a6e6e457c122464bbed3ea98952dfc654721ee13031f34f47bd.
All16 archive members were CRC-checked and data-member hashes rechecked after closure.
web-g/ contains all9 actual exported web files. index.pck is327093776 bytes, SHA256 1bce497a6858ecda944152bfa9ba9d98fbd135429a5aa12266ee1ff2666f91dc.
candidate-g.xdelta is33126284 bytes, SHA256 7fc4f8808c8b342f322cd0e7c37f0c71ae27a21440ea28e4d40a659496164111.
Round-trip reconstruction against pinned DEV13 PCK 5016e16791f51790f7a10dfabe0719b308de82a80627aca8d740b0e355e6cdc3 was executed and yielded the exact g PCK hash.

## Actual final browser result: incomplete, not passing

Chromium151.0.7922.34, Linux/headless ANGLE SwiftShader, Godot4.7.2, CSS844x390/DPR2.
01-ready.png is an actual1688x780 game screenshot. Native loading, isolated save path and Space mining worked.
The last captured state has65frames,8impacts, ore17 HP500->468, failed=false and errors=[].
The harness nonetheless ended with page.waitForFunction Timeout120000ms during held mining.
failure.json, telemetry.json, console and run logs are retained unedited. Only01-ready is a completed checkpoint; no passed report.json.
Walking, release, reset, touch mining and touch joystick are not yet fully verified.
The final HP was already below the awaited480 threshold. rAF polling starvation / periodic screenshot stalls are hypotheses, not proven root cause.
Remove periodic screenshots, prefer bounded time-based polling/JSON telemetry and rerun the exact g candidate, preserving actual input/assertions.
Do not repeatedly restart heavy renderers because software rendering looks stalled. One heavy engine at a time.
This is not physical-device, sustained50FPS, normal-speed motion or9/10 evidence.

## Already solved; do not reopen blindly

Release web uses a real entry.tscn/Node, not ignored --script or an empty main scene.
Release-stripped side-effect asserts were removed. Exact native GLB/PNG are raw-loaded and hash checked; no original Blender is published.
Direct window.EVER_DEEPER_TRIAL_JSON telemetry works. g hides DEV and companion HUD.
Staged main, state, achievements, audio and quick-tutorial save paths are isolated; ordinary game is unchanged.
Native capture c at175915ed53b0486fa12c056fa991bed995b5dbb8 passed120actual game+hero frames, all12mechanical fields matched baseline, and contacts22/55/92 were pixel-identical to settled references.
Independent critic accepted only a bounded Worn interactive trial. Exact v28/study20, support-hand release and ordinary flow_graph_enabled=false remain protected.
Full c evidence is saved in Ever-Deeper-native-spilltest-20260920.zip; native material and motion archives are identified in Ever-Deeper-Fortsett-her.md.

## Restore and continue

Workspace pruning removed the local checkout, uncommitted payload/bundle and diagnostic harness edits, not committed aa436 source.
The new exact web/delta/evidence archive preserves the costly candidate. Rebuild metadata/43 delta parts from those bytes when needed.
Some unreferenced payload Git blobs were uploaded; no complete payload commit or review.json exists. Do not assume upload completion.
No new DEV/LIVE has been published. Existing DEV13/LIVE remain the baseline.
.github/native-flow-trial/publish.py and its workflow are saved in aa436, with save-isolation and all9served-file evidence binding fixed.
Before publication: complete all6control checkpoints, inspect final g images with an independent critic, bind exact review/bundle/evidence and preserve all18existing files; verify27files afterward.
Planned additive destination dev/worn is not currently claimed live.

Recover branch and npm ci. Chromium151 executable previously:
/tmp/ever-deeper-runtime-20260920/chrome151/chrome-headless-shell-linux64/chrome-headless-shell
Official download:
https://storage.googleapis.com/chrome-for-testing-public/151.0.7922.34/linux64/chrome-headless-shell-linux64.zip
Chromium134 crashed with this Godot WASM; do not repeat that route.
Run one corrected harness with:
node tools/hero_v28/runtime_pilot/review_trial.mjs /absolute/web-g /absolute/fresh-review /absolute/chrome-headless-shell
Godot4.7.2 ed1daf0bf and matching webtemplates were used; Blender4.5.3 only for necessary native regeneration.
Local /tmp paths survived this pruning but are not durable identities. Old sessions62396/279 are gone; the browser test closed with timeout.
Use the established Mac graphical route from game-test-environment if needed, without inventing credentials or hardware.
Short Norwegian updates, maximum5lines. FPS stays paused.

---

Historical environment records follow.

Latest verified run: [21 exact entry/brake](premium-polish/hero-transitions-21-20260919.md).
Source restored to /workspace/scratch/c58aae856e15/ever-deeper on codex/hero-loop-flow-20260918.
Original native/runtime paths under/tmp survived and were SHA/version/graphical checked.
Blender4.5.3 rendered24native frames after bounded geometry/temporal review.
Godot4.7.2/X11/Mesa:126+106actual1696x780frames, both runner0 with completion markers;
all232mechanical rows match baseline,2hits/8damage per case. Input QA passes.
Evidence /tmp/ever-deeper21-native-g and /tmp/ever-deeper21-candidate-{interrupt,walk-entry}.
No physical-device/FPS claim. Protected runtime/assets are unchanged; known player_visual invariant persists.

Previous verified run: [20 held-mining flow](premium-polish/hero-flow-20-20260919.md).
Godot4.7.2/X11/Mesa: fresh150-frame1696x780 capture, runner0, completion marker, four hits/16damage.
Verified preserved20 rapid110-frame capture, original native63-frame bank and unchanged gameplay.
Evidence: /tmp/ever-deeper20-resumed-continuous; original runtime/native paths still work.
MP4/GIF are encoded to closed temporary files, completely decoded, then atomically installed.
No physical-device/FPS claim. Input QA passes; the known player_visual.gd invariant mismatch remains.

Previous verified run: [19C transition test](premium-polish/hero-transitions-19-20260919.md).
Blender4.5.3:13native bridge images. Godot4.7.2/X11: final110actual1696×780frames,
runner0, hits47/76,8damage, source hashes verified. Five rendered scope checks pass.
The earlier180-frame walk capture had a missing completion log; retain that failure.
Final output was /tmp/ever-deeper-transition19-final, copied after closure to
/workspace/scratch/eb19e34b942d/swing19-final-game. No physical-device/FPS claim.

Latest verified run: [overhead18B](premium-polish/hero-overhead-swing-18-20260919.md).
Blender4.5.3:50native loop frames; Godot4.7.2/X11:150actual1696×780frames,
four real hits/16damage. Internal image-sequence preview pass, no physical-device
or continuous-video claim. Runtime paths remain those restored under/tmp/ever-deeper-runtime-20260918/.

CURRENT ANIMATION REVIEW: [Local independent critic workflow](premium-polish/hero-local-review-20260919.md). Use the existing actual16G119-frame capture and internal critic without waiting for optional Gemini sign-in. Mechanical and pixel-binding checks pass; actual ore-pulse clearance fails1.63px versus2px. Local sequence/timing diagnosis is not continuous-video viewing, production approval or physical-iPhone evidence.

LATEST RENDERED ANGLE CHECK: [Closed camera-angle trial](premium-polish/hero-view-angle-20260918.md). Blender4.5.3 and Godot4.7.2/X11/Mesa25.2.8 llvmpipe succeeded;119 actual frames, unchanged inputs/world/hits50/90, and only76 newly rendered cells presented. Xvfb restored at `/tmp/ever-deeper-runtime-20260918/angle-xvfb/root/usr/bin/Xvfb`. No production or physical-device acceptance.

LATEST OFFLINE STUDY: [Stock-motion compatibility](premium-polish/hero-retarget-20260918/ATTEMPTS.md). Blender4.5.3 loaded the actual native models and rendered16 diagnostic images; no new Godot graphical test was needed or claimed for this rejected source study. Native originals were re-extracted to `/tmp/ever-deeper-retarget-20260918/native` after a workspace copy was observed truncated. Restore from the saved originals if paths are missing; cause of truncation is unestablished.

CURRENT VERIFIED ANIMATION CHECKPOINT: [Four-case complete-return review](premium-polish/hero-return-20260918.md).
Godot4.7.2/X11 llvmpipe and Blender4.5.3 were exercised on18September; all runs are closed. Mats approved the public-source upload; all ten reviewed files are verified on GitHub at `16bda4413cf9c5c9f98232f1df96e17e3346944e`. Scratch/runtime paths below are historical locations and must be checked or restored before a new run.

CURRENT VERIFIED MILESTONE: [Published DEV10](premium-polish/dev10-20260917/PUBLISHED.md).
Exact browser/native QA35181119505, Mac WebKit35181878479 and publication35182372885 pass. Linux WebKit framebuffer failure remains retained; Mac uses Actions step timeouts, since GNUtimeout is absent. Virtual-Mac sustained performance still fails50FPS. Existing root Godot/Xvfb route remains valid; never run heavy renderers concurrently.

Current unpublished candidate: [DEV10](premium-polish/dev10-20260917/HANDOFF.md).

## Runtime verified 17 September 2026

Godot `/tmp/ever-deeper-runtime-20260917/Godot_v4.7.2-stable_linux.x86_64`
returns `4.7.2.stable.official.ed1daf0bf`; the matching web templates are installed.
Xvfb is `/workspace/scratch/d5437d917805/runtime/xvfb/usr/bin/Xvfb`.
Use the authenticated `tools/run_rendered_isolated.py` route and an empty project
directory for exact-PCK tests. The actual 1696×780 hazard/menu/return route passes
47 checks on the exported DEV10 candidate; the 15 current package suites also pass.
Local execution is Linux Mesa llvmpipe, not Apple or physical iPhone evidence.
The browser service denied the loopback preview; existing Mac/browser CI remains
the next route. The candidate has not been published or run in that CI yet.

Historical continuation: [CURRENT-POLISH.md](premium-polish/CURRENT-POLISH.md).

## Runtime restored 15 September, continuation

Verified Godot: `/tmp/ever-deeper-runtime-20260915/Godot_v4.7.2-stable_linux.x86_64`. Extract the validated ZIP under `/tmp`, then run `--version`; a workspace extraction later appeared truncated/mode 644 despite an earlier successful version call. Do not execute incomplete bytes or solve this by changing access controls.
Verified Xvfb: `/workspace/scratch/02374ae65f32/runtime/xvfb/usr/bin/Xvfb`; extracted ordinary Ubuntu packages plus xkbcomp.
Verified Blender: `/tmp/ever-deeper-runtime-20260915/blender-4.5.3-linux-x64/blender` (`67807e1800cc`).
Current source checkout: `/workspace/scratch/02374ae65f32/Ever-Deeper`, work branch from START-HER.
Evidence: `/workspace/scratch/02374ae65f32/evidence/`; all paths are disposable, remote reports/source are authoritative.
Native models remain at the existing saved identities from START-HER; task-local copies are outside the git tree.

# Test environment — premium-polish source recovery

Canonical source is the complete root project in `Corpax88/Ever-Deeper`.
This recovery is based on `d4619e5429326b880c4da2d466a2bf5351f0f46c`.
Read `premium-polish/HANDOFF.md`, `AGENTS.md` and `verification.md` first.

## Verified local route

- Official Godot 4.7.2 Linux binary, version `4.7.2.stable.official.ed1daf0bf`.
- Xvfb 21.1.12, libXfont2 and libxkbfile downloaded as Ubuntu packages and
  extracted without changing access controls. `/usr/bin/xkbcomp` is required.
- `tools/run_rendered_isolated.py` starts authenticated Xvfb and Godot together,
  isolates saves, supplies extracted libraries and captures complete logs.
- `tools/capture_recovery.gd` captures actual source states using the existing
  game fixtures. Example, with verified executable paths supplied locally:

```sh
python3 tools/run_rendered_isolated.py --godot /path/to/Godot \
  --xvfb /path/to/xvfb/usr/bin/Xvfb --output /absolute/review \
  --resolution 1696x780 --timeout 300 -- \
  --script tools/capture_recovery.gd -- --output=/absolute/review
python3 tools/qa.py --godot /path/to/Godot
python3 tools/check_invariants.py
```

31 source captures were inspected. Software rendering is useful visual evidence,
not Apple-device performance evidence. The source gate has 14 current cases;
do not count the lost candidate's additional premium suite as present.

## Restore rather than assume

Probe execution and actual files on each continuation. Old scratch locations
and process IDs can disappear. Verify executable versions after downloading.
Do not use the older truncated Godot ZIP as a runtime. Blender 4.5.3 LTS is the
native hero exporter; keep approved v28/v9 binary originals outside the public
source payload. Never rebuild the model from reference imagery or memory.

The established Apple route uses GitHub Actions macOS runners and the repository's
review workflows. It is not a reserved Mac mini. Read current workflow files
before use, keep source changes on the game's own work branch, and preserve
contents-read permissions and isolated saves. Mac WebKit, Safari in an iPhone
Simulator, and physical iPhone performance are different evidence categories.

The full premium-polish workflow was part of the lost source and must be restored
and reviewed before relying on it. No exported package, browser performance,
Safari Simulator or physical iPhone result is asserted by this checkpoint.

## Preservation checkpoint, 15 September 2026

[START-HER.md](../START-HER.md) is the continuation entry. Current game source
was verified remotely as 39f21724deb78c4c6d6103fedb1fba04a2135c32, tree
67e69417d18ad29d4862968564a3d60333b99426. Documentation/evidence additions
do not change the game source. The invariant check was rerun and passed.

Working local executables at preservation time were:
- /workspace/scratch/3f78a50e0974/runtime/Godot_v4.7.2-stable_linux.x86_64
- /workspace/scratch/3f78a50e0974/runtime/xvfb/usr/bin/Xvfb
- /tmp/ever-deeper-blender-runtime/blender-4.5.3-linux-x64/blender

Godot --version returned 4.7.2.stable.official.ed1daf0bf; Blender --version
returned 4.5.3 LTS, build 67807e1800cc. Paths are disposable; recover the
verified versions if absent. Historical Mac/Safari instructions are in the
game-test-environment skill's tested-routes.md. Restore the game-specific
workflow before relying on that route.

The current source QA reports, logs, 31-image report and four inspected contact
sheets are saved in premium-polish/checkpoint-evidence. The original report
has a layout failure; the separate corrected-layout result passes. Full-size
PNGs can be regenerated by tools/capture_recovery.gd. Historical motion evidence
and partial patches in premium-polish/recovery belong to the lost candidate.
No exact-package or device performance approval is implied by this save.
