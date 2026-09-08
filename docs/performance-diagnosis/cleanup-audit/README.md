# Cleanup regression investigation — 2026-09-08

Mats reports the iPhone Air FPS collapse started after code cleanup. This review compares
the actual pre-cleanup v0.46.8 source with cleanup merge `988d9aeed77a1be27d7daebdb7d03cd4d67e51e2`.
It does not compare against the obsolete source previously at the distribution repository root.

**Result:** no removed active performance control, render cache, object cleanup or simulation
step was found. Native before/after runs do not reproduce the delayed collapse. This supports
keeping the cleanup; it does not establish the cause of the physical iPhone failure.
No game source was changed and no build was published for this investigation.

## Source evidence

The original v0.46.3 source archive was recovered and checked against its recorded SHA-256
`4a1d0c6ae4955df9281d64aa8fbbd934ca34ad3cec50a569a115ec6ed279d6ec`.
The recorded v0.46.4 through v0.46.8 source patches were applied in order, including the
separate v0.46.5 shader/icon source. All 12 final v0.46.8 release source hashes match.
The old `c71ff97` label was a local source baseline, not an available GitHub commit.

- 1,237 reconstructed runtime files match the cleanup commit's Git blob hashes exactly.
  Nine files differ: eight GDScript files and the export exclusion list. The five separately
  delivered v0.46.5 art/font files have the same Git blob identities at their final paths;
  their import/UID additions are distinguished from cleanup's new QA files in the report.
- Across the eight changed scripts, 1,481 retained methods have identical bodies.
  This includes all 173 retained hub methods, all 164 retained Depth 2 methods and all
  320 RunState methods. Player, pet, audio, lighting, shader, scene and project files match.
- All 48 removed method bodies match the original removal inventory hashes. Full-token
  references in GDScript, scenes and resources have no callers outside the removed group,
  except `_draw_barrier_backplates()`. Its original body was only `return`; its call in
  Depth 1 `_draw()` was removed too. No live render/update cleanup was removed there.
- The other changed method bodies are `main._ready()` and the QA branch of `main._process()`.
  Normal save checkpoints, HUD/guide throttles, signals, world activation and processing
  remain. The old and new automated-mode flag sets contain the same 56 flags. With ordinary
  startup, the new launcher remains null. Shared WorldCatalog constants have identical values.
- The export preset only adds exclusions for docs, archive, tests and QA output. Rendering,
  viewport, frame cap, compression, threads, script export mode and save settings are unchanged.
- The Teamwork hub `bool(null)` bug is present in the original pre-cleanup pet code too;
  it was fixed separately in DEV4 and is not evidence of code lost in cleanup.

## Sustained ordinary-startup comparison

[Run 34206534221](https://github.com/Corpax88/Ever-Deeper/actions/runs/34206534221), source
`50aa17fcf14d53d8740e8e8b3a8e31be1012247c`, passed both jobs without script errors.
The harness and exact restoration patch are on
[codex-cleanup-regression](https://github.com/Corpax88/Ever-Deeper/tree/codex-cleanup-regression/.github/cleanup-regression).

Each job ran original and cleaned code sequentially on the same Linux software renderer,
Godot 4.7.2, native 844×390, for 90 wall-clock seconds per side. Ordinary main-scene startup
is used; assertions verify automated mode is false, no QA launcher exists, persistence stays
active, the pet exists and the requested world is entered. Mature hub: five relics, all
workshops, Light Lab/Wardrobe L4. Skills are identical on both sides: all learned except
Teamwork, to avoid its known pre-existing error. Dummy audio; no user save is accessed.

| Area | Early FPS before / after | Late FPS before / after | Nodes before / after | GPU estimate before / after |
| --- | --- | --- | --- | --- |
| Hub | 12.430 / 12.433 | 12.480 / 12.471 | 650 / 650 | 463.80 / 463.80 MiB |
| Mossvein Depth 2 | 10.353 / 10.301 | 10.423 / 10.429 | 687 / 687 | 486.39 / 486.39 MiB |

Early/late are median 5-second buckets ending before 20 seconds / after 60 seconds.
Neither side develops a 30-second cliff. Node counts and GPU estimates stay constant;
late FPS differs by less than 0.1% between source versions. Static memory is about 1.39 MiB
lower after cleanup. CPU monitor readings include this software renderer's frame work and
must not be compared directly to the phone's CPU timings.

The four final native captures were inspected: same composition, authored assets and UI,
with animation phase differences. These are source runs at lower pixel load, not physical
iPhone or WebKit measurements. The baseline control restores the nine altered source files;
unused extracted QA files remain on disk in both checkouts, but are not instantiated.
Raw bucket data are retained in `native-hub.json` and `native-mossvein.json`.

## Actual published package check

The exact v0.46.8 rollback and v0.46.9 Pages artifacts from publication run `34155871163`
were downloaded and their recorded ZIP digests verified. Their IDs are `10030946553` and
`10030951631`. The original LIVE PCK matches
`d95621dcda43a2245aa0d21be60c1a309383a19a0f1f4b92d2ee34e86cbcf3a2`.
Every PCK resource payload was checked against its directory MD5, then compared by SHA-256.

Both flavors contain **538 unchanged texture entries**. Scenes, audio, shaders and their
imported payloads are unchanged too; the engine WASM, JavaScript and audio worklets are
byte-identical. Changed entries are the expected compiled scripts, UID cache and project
binary; added entries are QA scripts and remaps. The removed `version.json` is the retired
prototype's file. The HTML and PCK differ; the other seven published files per flavor match.
This check covers the first release after cleanup, so it also includes the separately
reviewed v0.46.9 HUD/shop performance changes. It is not a cleanup-only binary comparison.
See `published-packages.json` and the reproducible parser `compare_published_packs.py`.

## Handoff

DEV remains 0.46.9-dev.4; LIVE remains 0.46.9. The user's ~30-second failure is still
unresolved, with the same behavior in Safari and home-screen mode. Do not revert cleanup
or reduce visual quality on the basis of this audit. If further work targets rendering,
use a reversible, timed diagnostic on the affected device to measure restoration after
independently changing lights, shadows and pixel load. That mobile diagnostic has not been
built or published. An old/new comparison on the affected phone also remains unperformed.
