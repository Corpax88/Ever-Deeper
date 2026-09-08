# FPS handoff — DEV8 still drops; DEV9 candidate blocked

Updated 2026-09-08. Mats explicitly requested a handoff to start a new chat.
Work is paused at this checkpoint. Do not describe the FPS issue or DEV9 as finished.

## Start here

1. Read root `AGENTS.md`, `README.md`, `docs/code-map.md`, and this handoff.
2. Read `.github/dev-lighting/dev9-checkpoint.json` for immutable source/run/artifact IDs, hashes and the latest job results.
3. The next task is the failed DEV9 light-preview restoration check, followed by actual final-package visual review. Do not restart broad FPS diagnosis.
4. Refetch main before any mutation: another chat is working on the approved hero's wardrobe portrait / crossed-arms presentation. Preserve that work.

Communicate briefly in Norwegian (normally no more than five lines per reply).
No critic agents or other subagents. Continue autonomously within the authorized task.
DEV-only publication is authorized after the required checks; LIVE must remain unchanged.
Preserve gameplay, saves, approved artwork, lighting appearance, shadows, output resolution and DPR.
Do not lower rendering resolution, remove visible lights, replace the engine, undo the audited cleanup,
or weaken a test merely to obtain a passing result.

Root AGENTS requires rendering and personally inspecting the final build at the target mobile viewport
before publication. Successful source, headless, gameplay or FPS checks are not visual approval.
If the final build cannot be rendered and inspected, do not publish. The user requested a handoff now,
so no new release was attempted at this checkpoint.

## Published baseline

| Item | Current recorded state |
| --- | --- |
| DEV | 0.46.9-dev.8 — https://corpax88.github.io/Ever-Deeper/dev/ |
| LIVE | 0.46.9 — https://corpax88.github.io/Ever-Deeper/ |
| DEV8 candidate source | `2e8e165b7f236c854357d0440c007d74b03e7f12` |
| DEV8 publication commit | `13aa2ebb5c2acb5b2906ea9701827402a5c644d0` |
| DEV8 publication run | [34270405341](https://github.com/Corpax88/Ever-Deeper/actions/runs/34270405341) |
| DEV8 candidate artifact | `10072521163`, `hero-v28-candidate` |
| DEV8 ZIP SHA-256 | `1fd4fff193acef1a5ce695847b14157f7dc12fab5998091b1a81c1ec2c5aae7f` |
| DEV8 PCK | 219164200 bytes; SHA-256 `d342642443ca76d46f465f1883f68ff9ea226e9e79cea5330e00c74e37e01378` |
| Verified review / receipt | `.github/hero-v28/review.json`, `.github/hero-v28/publication-receipt.json` |
| Main before this docs-only checkpoint | `28d1820eb32702f74c62a206cd179eb24c3c8516` |

The DEV8 receipt records all 18 public files verified and LIVE unchanged at
2026-09-08T19:44:29Z. This handoff did not perform another public deployment.
DEV8 includes the approved Gruvepappa v28 hero and DEV7 shared-floor lighting.
Use DEV8 as the previous-release/rollback baseline, preserving the hero.
The published DEV8 normal-menu source still contains the older dev.5 label; this is
separate from the FPS test's DEV8 title. Label synchronization is prepared on DEV9.

## Latest physical evidence — sustained recovery failed

Mats's device is described as an iPhone 17 Air. The fall occurs after roughly 30 seconds,
in the hub as well as Mossvein Depth 2, including stationary play. Safari and the
home-screen icon were already reported to behave alike. Do not reask those questions.

The DEV8 120-second test in IMG_1745.jpeg:
start 60 FPS; original 34.6; pet lights off 37.4; restored 34.5; shadows off 35.1;
restored 34.7; all lights off 60.0; final restored 59.8.
Full transcription: `docs/performance-diagnosis/light-cost/iphone-dev8.json`.

That last restoration stage was only 10 seconds, sampling its last eight seconds after
two seconds of warmup. Code review confirmed restoration is called and both engine and
RAF samplers reset at each stage. It did not prove sustained recovery or actual active
light counts.

The requested follow-up is now supplied: IMG_1746.jpeg, user: "Jepp, dropper fortsatt."
The hub meter shows **34.7 FPS at 52 seconds**, p95 30.0 ms, max 32.0 ms,
zero frames over 33 ms, CPU 6.0 ms, physics 1.0 ms, canvas 2328×1260, DPR 3.0,
140 draws, GPU 487 MiB, 796 nodes, memory n/a.
Transcription and limitations: `docs/performance-diagnosis/light-cost/iphone-dev8-followup.json`.
The meter's D2 label is pre-existing even in the hub. Its 52 seconds is meter elapsed
time, not an exact measured cliff onset. Do not ask Mats to repeat this DEV8 follow-up.

Earlier tests: DEV5 original 19.8 / all lights off 60.0 / restored 19.9 FPS;
DEV6 original 30.1 / pet off 32.2 / shadows off 30.1 / all off 60.0 / restored 30.0.
The evidence repeatedly implicates lighting cost; it does not establish a thermal,
driver, or device-throttling cause. Those mechanisms have not been measured.

## Current DEV9 candidate — NOT published

| Item | Value |
| --- | --- |
| Branch | [codex-fixed-lighting-dev9](https://github.com/Corpax88/Ever-Deeper/tree/codex-fixed-lighting-dev9) |
| Source | `efd3dc6f37ff7a1c5eeb3c9bbf0c6eb9e0385ed5` |
| Tree | `6ca0d18acebb148367e3d50eebe154b997cb69f4` |
| Exact-package QA | [34278070936](https://github.com/Corpax88/Ever-Deeper/actions/runs/34278070936) — completed, **failure** |
| Jobs | 10 of 11 passed; `native (preview)` failed |
| Candidate artifact | `10076577835`, `dev-lighting-candidate` |
| Candidate ZIP SHA-256 | `2050a321c536161e9404e006fd05090c4955aedf78f7fb716017b344da2b2563` |
| Build-review artifact | `10076578392`, `dev-lighting-build-review` |
| Failed-preview artifact | `10076608721`, `dev-lighting-native-preview` |
| Final visual review | **Not done** |
| Physical iPhone confirmation | **Not done** |

Build/import, protected-file invariants (1139 files / 51 QA cases), all ten current
gameplay cases and both exported DEV/Production flavor checks passed. Native hub,
Mossvein, Emberdeep, Moonglass, Starfall, other worlds, gates and both Chromium jobs passed.
That is automated status only: the current package's paired images and browser reports
have not yet been personally inspected.

The failed preview job is `102236642344`. Its downloaded native.log reports:

> MOBILE_PERFORMANCE_FAILED: Returning to the same light level changed its pixels

The failing assertion is in `scripts/qa/suites/mobile_performance.gd:237`.
Artifact 10076608721 contains `light-current.png`, `light-upgraded.png`,
`light-current-restored.png`, and `native.log`. These images have not yet been viewed.
The cause is unresolved. Start by comparing these captures and tracing the preview state,
fixed-field bake invalidation and restoration timing. Do not assume the difference is
harmless animation or relax the assertion without establishing what changed.

An earlier DEV9 run, 34277656794 at `cc72789328898b5fda40962ca894977b2667489c`,
failed because `visual_capture_driver.gd` still strictly expected dev.5.
Only that expected DEV literal was changed to dev.9; the current run passes those core
checks. This prior version mismatch is fixed and is distinct from the current pixel failure.

Candidate ZIP, build-review ZIP and failed-preview ZIP were downloaded and their archive
digests verified. The candidate manifest was read, but individual package files have not
yet been checked against it. It claims PCK size 219176328 and SHA-256
`3d0d4c5b79ee3db408dcfcafa20f5d793129a41317068e26bd19760d1d2c215f`.
All twelve artifact IDs/digests are preserved in dev9-checkpoint.json.
No DEV9 review approval flags, publisher configuration, publication or public verification
has been completed.

## What DEV9 changes

The candidate reduces repeated fixed-lamp lighting while retaining the original logical
lamp nodes and moving helmet lights/shadows.

- New `scripts/lighting/static_light_field.gd` owns a reversible fixed-light cache.
  Hub sources come from `world_lights`; Depth 2 sources come from `landmark_lights`.
  Selection is limited to enabled, shadow-free, flat, additive, mask-1 lamps with the
  expected gradient textures, SDR colors and default z/layer ranges. Unsupported inputs,
  fewer than two or more than 32 sources, or bounds above 2048 on either axis retain originals.
- A temporary separate-world SubViewport combines the original lamp textures/transforms/colors
  with additive premultiplied sprites. One field texel per world unit is used. This does not
  reduce output framebuffer resolution or DPR. A conservative overlapping-bounds energy
  normalization avoids the study's per-pixel production scan. One post-draw image readback
  produces the cached texture; the bake viewport is freed.
- One cached PointLight2D covers ordinary sprites. The floor samples the same static field
  in its fragment shader; moving lights continue through its original-albedo light function.
  Existing shadow masks are preserved with a reserved floor bit `1 << 19`.
- Original source nodes and flags are retained for fallback and original/candidate/restored
  comparisons. Fixed-source membership changes rebuild explicitly. Deferred generations
  cancel stale bakes; disabled/exiting state restores masks/flags. Headless runs retain
  original sources. SceneTree node-added handling covers later actor lights.
- `fixed_light_probe_lock` prevents switching source sets during the phone diagnostic;
  deferred work resumes after unlock. The shader's fixed_enabled flag follows the cached
  PointLight's visible/enabled state, including the all-lights-off stage.
- New shaders: `shaders/static_light_bake.gdshader`,
  `shaders/lit_floor_fixed_field.gdshader`.
  `scripts/lighting/lit_floor_chunks.gd` gains fixed-field material/mask support and keeps
  the previous DEV8 composite path for comparison. Chunks remain 256 pixels.
  Small integration changes are in `scripts/world/hub_world.gd` and
  `scripts/world/depth/rootwound_world.gd`.

This cache is not proven bit-identical or lossless. Resampling, normalization and
quantization differ slightly. The production candidate differs from the successful
study; its final visual, performance and memory evidence still needs review.
The implementation's generalization comments should not be treated as proof that every
possible future CanvasItem normal-map/HDR setup is covered; current owners use flat art.
Check activation/fallback, source restoration and transient memory in the actual final package.

Version and diagnostic changes are also prepared:
`PremiumMenu.release_version()` is the canonical DEV9 label and the render probe uses it.
The strict visual-capture expected DEV value is dev.9.
The last "Restored · 70s" stage lasts 70 seconds; the complete test is 180 seconds.
Button: "AUTO FPS TEST · 3 MIN"; JS watchdog: 210 seconds.
The suite enforces the longer restoration stage and mobile touch/focus behavior.
An older QA-only log string in mobile_performance.gd still says dev.5; it is not the menu
or FPS report label. The frame meter's hub-as-D2 label was not changed.

QA owner changes: `lighting_release_review.gd`, `render_probe_review.gd`,
`tools/render-probe-web.mjs`, `tools/review-lit-gates.gd`,
`tools/render-probe-browser.js`, and `.github/workflows/dev-lighting.yml`.
The workflow compares 35 native paired cases, includes reached/struck gates and previews,
and adds 45-second original / 45-second candidate / 20-second restored measurements to
the initial hub/Mossvein cases as `fixed-field-performance.json`.
No gameplay/save/artwork files or protected invariant manifest were changed for this candidate.

## Completed controlled study — keep the evidence, do not rerun from scratch

Branch [codex-static-field-dev8](https://github.com/Corpax88/Ever-Deeper/tree/codex-static-field-dev8),
source `5b1ea312111c5603cf599f12b00f07c747dfe37e`,
successful run [34276033718](https://github.com/Corpax88/Ever-Deeper/actions/runs/34276033718).
Study code: `tools/probe-static-light-field.gd`; workflow: `.github/workflows/static-field.yml`.
It runs an external study script against the unchanged published DEV8 PCK.

| Mesa software FPS | Original | One combined field, density 1 | Density 2 | Density 2 + direct floor | Restored |
| --- | ---: | ---: | ---: | ---: | ---: |
| Hub | 4.068 | 5.567 | 5.560 | 5.983 | 4.076 |
| Mossvein | 4.157 | 4.430 | 4.426 | 4.598 | 4.303 |

The best study variant was approximately 47% faster in the hub and 10% in Mossvein on
this test rig. These are controlled software-renderer comparisons, not iPhone FPS predictions.
Both study comparison images were inspected. Hub maximum channel differences were
3/255 at density 1 and 2/255 at density 2/direct floor; Mossvein maxima were 3/255.
Restored pairs were exact. These figures do not validate the different final DEV9 implementation.

Both field densities stayed resident in the study: reported GPU memory grew approximately
483 to 581.5 MiB in the hub and 507 to 526 MiB in Mossvein.
DEV9 keeps one field and uses density 1, but its final memory benefit has not yet been verified.

Successful study artifacts, both ZIP digests verified:
- Hub `10075846099`: `e16b4d65516f86cb4d45b363cd2ccbe9770fe0aee777c711dea618dfafcc9da5`.
- Mossvein `10075850168`: `b67b24e1d397415ddbf0ac279ebb68ce39677c0bece2e70945dc7757a43a69d1`.

The earlier study run 34275130648 failed because canvas_transform was set before attaching
the SubViewport. Attaching first fixed it. Do not count that first run as a passing gate.

## Already investigated — avoid repeating

- Cleanup audit: 47 disconnected helpers, with 1237 runtime files/bodies checked for parity.
  No active runtime code was removed. Preserve the cleanup.
- All ten pet skills were tested individually off/on/restored in the 22-stage investigation.
  A Teamwork null/bool issue in the hub was fixed in DEV4; it did not resolve the delayed cliff.
- Removing a hidden opaque floor layer in DEV3 was pixel-identical but did not resolve the phone drop.
- Audio/WebAudio/Dummy comparisons and presentation/resolution/DPR experiments were already done.
  Do not restart these without new evidence. Transparent-alpha-discard shaders were slower and rejected.
- 64/128 floor chunks did not provide worthwhile gains; 256 was retained.
- DEV6 floor/draw bounding and transparent cone cropping improved physical readings but did not fix the fall.
- DEV7 combined the existing floor texture and color wash into one lighting pass.
  Its final run 34262864741 passed all eleven jobs and its actual images were inspected before publication.
  The roughly 30% software study gain was not a phone prediction.
  DEV7 was visually acceptable but not bit-identical; see the retained DEV7 review/evidence.
- DEV8 added the approved v28 hero while keeping DEV7 lighting. The newest phone evidence still shows the drop.

## Next chat's concrete work

1. Inspect the failed preview artifact and resolve the actual restoration/pixel issue.
   Check the final hub/Mossvein fixed-field performance and memory reports as supporting evidence.
   Do not skip the preview gate because other ten jobs passed.
2. Refetch main and account for concurrent approved hero/wardrobe changes before preparing a
   corrected candidate. Preserve all unrelated runtime changes; do not replace files with stale copies.
3. If runtime source changes, build/test a new immutable candidate and use its exact source/run/artifact
   throughout. Verify package digests and per-file manifests, all required gameplay/flavor gates,
   35 native paired states, gates, light/commerce previews and both mobile Chromium reports.
   Personally inspect final output against the approved assets and unchanged baseline.
4. Verify the longer probe's restoration window and cached light activation/fallback/restoration.
   Record final visual differences, bake/memory costs and controlled FPS without extrapolating to iPhone.
5. Only after the gates pass, prepare the DEV publisher using DEV8 as rollback baseline:
   `.github/dev-lighting/publish.py` still references the old DEV6 baseline;
   `.github/workflows/publish-dev-lighting.yml` still hardcodes DEV7 run/source.
   The active `.github/dev-lighting/review.json` and publication-receipt.json are also DEV7.
   Archive those if replacing them, point the baseline to the verified DEV8 manifest
   (e.g. `.github/hero-v28/review.json`), and set the new review flags truthfully.
6. Publish the reviewed package without rebuilding, preserve all nine LIVE files byte for byte,
   verify all eighteen public LIVE/DEV files, and write the new receipt.
   Do not trigger the existing publisher unchanged or present a speculative DEV9 as ready.

## Persistence and local working state

Authoritative source and evidence are on the immutable GitHub branches/commits/runs above.
Study and candidate runtime files are on their own branches, not main.
This handoff commit only updates documentation/evidence.

The current scratch copy `/workspace/scratch/149424cc3eb9/lighting-cost` is a partial
source collection, not a full git checkout; some local owner files are stale.
Do not reconstruct the candidate from it. There is no usable local Godot/Xvfb install.
Use the established GitHub Actions workflow; do not repeat the truncated local Godot download.

If scratch survives, useful files are:
- `/tmp/dev9-dev-lighting-candidate.zip` — complete, archive digest verified.
- `/tmp/dev9-dev-lighting-build-review.zip` — complete, archive digest verified.
- `/tmp/dev9-native-preview.zip` — complete, archive digest verified; images not yet viewed.
- `/tmp/static-field-hub-r2/`, `/tmp/static-field-mossvein-r2/` — successful study outputs.
- `/tmp/dev9-build1/` — old fixed version-mismatch failure evidence.
- `/tmp/dev7-final/` — prior reviewed DEV7 evidence.

All current jobs have finished. No local download process remains to wait for.
GitHub artifacts are subject to expiration (current candidate artifacts show 2026-10-08);
the checkpoint preserves their IDs and hashes. Do not depend on in-chat tool stores in a new chat.
