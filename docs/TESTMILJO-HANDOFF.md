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
