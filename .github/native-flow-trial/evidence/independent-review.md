# Independent review — DEV Worn trial

**Decision: accepted for the narrow additive `dev/worn` trial.** All six original PNGs were inspected. This accepts static trial readiness and the reported controls only. Production animation, ordinary-game adoption, LIVE authorization, physical iPhone performance and FPS remain open.

Candidate runtime source: `e32a03e620913a76f3bee9083b2e9b1d66eef972`. Mac run [35553114935](https://github.com/Corpax88/Ever-Deeper/actions/runs/35553114935) on `fd95be111fde7b2599bfbae5239f66c2bc6a3cbb` is identified by the supplied project handoff, not by fields within the report. Artifact ID: 10619416142. No suite, export or publication was run by this critic.

The local report SHA256 is `b4dc1a5312bd71a6334ad3d6a83c6ec9f9c4ebfb1f44bed05d11b6f8ab92993a`. Its nine exact file size/hash entries equal the bundle; PCK SHA256 is `74db0719dc5d151e0ad9491e9c5e90769c6f85ff8f8db07fe55c4b825277da05` (327093712 bytes).

| Inspected file | SHA256 |
|---|---|
| bundle.json | `26209f2eeeefa1688d8fd954b701dd02e4a00dbba74274271b4f3aa5d55765dd` |
| baseline.json | `eed30911a77a31727d09333330f43599d0db479af2ccf4de7166ffcd8c966212` |
| publish.py | `4e3a831721da26edf61948013166ec55f37f2e5978fe424a390517e627ca9959` |
| publish-native-worn-trial.yml | `e3ecb4e42ff87d342e9de4672c0faf9d18988e94338b14af6d6463bf4e5e3855` |

Runtime: headless Chromium 151.0.7922.34 on macOS arm64, ANGLE Metal / Apple Paravirtual device. CSS/PNG 844×390, DPR 2, drawing buffer 1688×780. Two recorded UID warning lines remain visible in the report.

## Observed findings

1. **Supported trial readiness:** No blocking static rendering or report-state inconsistency was observed across the six required control checkpoints. All six originals show the hero, companion, ore, textured terrain and trial HUD. Individual observations and original state windows are listed per image. HP17 is 500 initially, 476 after six held-mining impacts; reset restores 500 and resets=1; touch mining leaves 492 and impact_serial=8. Keyboard release position is identical at frames 430/490; touch release position is identical at 780/840, with mining=false.

   Cause/inference: The existing candidate renders the trial fixture and responds to the exercised controls; no defect cause is inferred. Uncertainty: A static appearance cannot independently prove HP changes, input timing or all animation phases; those conclusions use the recorded state report. No approved-target fidelity comparison or broader production coverage was performed. Smallest next step: Bind these reviewed bytes in the existing small review gate and proceed only with the already authorized additive trial workflow and its 27-file public verification.

2. **Evidence boundary:** These are six asynchronous control checkpoints, not a motion-quality sequence. The touch-mining image is a post-release pose; report mining=false at both frames 645 and 655. No image is assigned an exact impact frame. CDP captures take 114–171 ms and are bracketed by state counters 9 or 10 frames apart. Telemetry elapsed_ms is local to labeled waits; no global synchronized capture timestamp is supplied.

   Cause/inference: The harness captures control checkpoints through CDP while the game continues running. Uncertainty: Continuous playback, return clearance throughout a cycle, timing smoothness, physical iPhone behavior, sustained FPS and a numeric animation score remain unverified. Smallest next step: Keep production acceptance open; use the additive trial for the intended iPhone user check. Do not rerun the unchanged Mac suite to turn these stills into motion evidence.

3. **Minor ui wording mismatch:** The upper-left instruction says HUGG while the visible lower-right action control is labeled MINE. Visible in all six 844×390 originals: instruction near x12,y38 and button label near x729,y354. Touch interaction nevertheless produces two recorded impacts before release.

   Cause/inference: Likely mixed wording between the trial hint and existing action control; this is an inference from the pixels, not a source diagnosis. Uncertainty: Possible first-use hesitation was not measured and does not block the narrow supervised trial. Smallest next step: If the user reports confusion, align the hint/control wording in a separate minimal revision; do not rebuild this passing package for the review.

## Original image evidence

The frame pairs are the recorded states before/after CDP capture, not exact image frame numbers. Durations describe screenshot calls, not game FPS. Phase-local telemetry times are retained verbatim in the JSON; global synchronized image timestamps are unavailable.

| Original PNG | State-frame window; capture ms | Pixel observation | SHA256 |
|---|---|---|---|
| 01-ready.png | 1–10; 160 ms | Hero and companion are visible beside ore; textured terrain and the complete trial HUD render. | `7b87ba0bced0479bbadf7f6bbfacaf095e6b6e13e7f761ead3e64936527110d9` |
| 02-held-mining.png | 245–255; 164 ms | Hero pose changes beside the same ore while the scene and controls remain visible; this still does not establish a contact frame. | `272d0ed83a5b26cacf00875f19524d46a8343bd70a7e86c4a6ea3d6cba3aa94c` |
| 03-walk-exit.png | 490–500; 121 ms | Hero faces left in a visibly shifted world view, with companion and ore still rendered. | `a7515530ad627f3115a3713089eeb2b94d0fbdbc1bf996f54663cfda4f87ffd7` |
| 04-reset.png | 505–515; 171 ms | Hero returns to the ore-side setup; the reset button is highlighted. Companion/camera placement differs from the first capture. | `0c5fd9b5478168db53f62bf69a05d35a2e303d523471336a593a4cb6378db4d1` |
| 05-touch-mining.png | 645–655; 117 ms | Hero is back in a ready-looking pose beside ore after touch release; the screenshot itself does not show active mining. | `eff66cddc5a86bc22dc3872a0863034448ea11feb98539c60ead7e8e4c7031fe` |
| 06-touch-walk.png | 840–850; 114 ms | Hero faces right beside a terrain corner in a shifted world view; HUD and companion remain visible. | `26a15628e25dc5eb9ba67d876bf8b2c8d41197b29ed105e29f779683515009ba` |

## Narrow publisher review

Accepted by source inspection. `reviewed()` binds the exact baseline, bundle, report, source and nine tested file identities and requires the six passing checkpoints plus narrow review flags. `prepare()` verifies the 18 pinned public LIVE/DEV13 files before staging, retains rollback bytes, verifies each delta part and reconstructed candidate, then permits exactly those 18 files plus nine files under `dev/worn` and `.nojekyll`. The seven candidate runtime files other than HTML/PCK must match DEV13. Baseline files are rechecked after copying.

The workflow gates deploy on packaging and serializes Pages work. Its subsequent `verify()` checks exact size/SHA256 for all 27 public game files before writing a success receipt. This review has not executed staging or public verification and does not claim publication success. Rollback bytes are retained; a failed public check does not automatically roll back.

Current bundle bytes match the canonical handoff SHA256. The original report has no trailing newline and matches its recorded hash; preserve it exactly. The next step is the parent’s hash-bound review gate, followed by the existing authorized additive workflow and a successful 27-file public receipt.
