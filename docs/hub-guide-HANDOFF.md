# Starforge Hub guide loop — DEV6 published

Mats reports that after crafting Starforge Crusher, the guide repeatedly asks
him to inspect the Hub and sends him back whenever he leaves.

## Cause and correction

`main._enter_hub()` loaded a Hub runtime snapshot before marking the tutorial
complete. Checkpoints and exit subsequently committed that older snapshot,
overwriting `tutorialSeen`. RunState now marks the visit complete atomically on
entry. Runtime construction commits preserve completed visit/tutorial flags.
Save sanitization recovers an already visited Hub whose tutorial flag was lost.
Unvisited saves retain their introduction. No art, prices or save schema change.

The gameplay suite now uses actual main entry, checkpoint, exit and reentry,
checks stale runtime commits, save reload, old-save recovery, equipment/gold
preservation and the next `drill:1` goal. The external exact-package visual
harness includes before-entry, after-entry and after-exit at both mobile sizes.

## Local verification

- Runtime fix and DEV6 release preparation: commit `61b91eb`.
- Godot 4.7.2 import succeeded; all 1,139 protected-file invariants passed.
- All fourteen current source cases passed across the full run and isolated
  touch rerun. The first full run's touch case hit the headless dummy renderer's
  `texture_2d_initialize` null-texture error; the unchanged isolated rerun passed.
  An earlier overhaul attempt hit the same renderer error; two later source
  runs and the exported-package run passed. These retries are not hidden.
- Eight offline publication-contract tests passed.
- DEV6 pack exported without errors. Exact-pack overhaul and build-flavor pass.
- Local PCK SHA-256:
  `150f717f18d69663fa147b7ef84656b466d267de0be47432b4c25bb8163c6bff`.
- GitHub validation run 34716507336 passes all six jobs and fourteen source plus
  fourteen packaged cases. Small WebKit: 882 gameplay / 195 touch assertions.
- Exact native artifact: 618 assertions / 56 journey captures, seven companion
  captures and 75 receiver stages. All pass. Seven images were inspected; see
  hub-guide-review.md and hub-guide-evidence/review-index.json.
- Accepted DEV6 artifact: 10304559817. Its PCK hash is
  `02e8d59d1c1f2ddf53de4128763559b59ec89aaabc78b41ba907720d32de37a0`.
  This is the CI artifact, distinct from the earlier local export.
- DEV6 publication run 34717418294 passed packaging, deployment and verification.
  All nine DEV files match the accepted artifact; all nine LIVE files retain 0.46.9.

## Authorization and release progress

Mats explicitly authorized uploading this fix and publishing DEV after the normal
release checks in this conversation. The earlier automated approval rejection is
resolved. Shell Git has no credentials, so the authenticated GitHub connector
uploaded the identical source tree `e8588e2c5b2970415a5749c3a851eeb7f4ceea06`.
Validation source: `d60922cb13a4ad521ef5d1721434574e097fdc7f`.
Validation run: `34716507336`.

PR #16 is merged at `bf51e54ab2cadd8a462c8afcbb0fe603f9a6f0df`.
Publication receipt: `.github/one-point-zero/hub-guide-publication-receipt.json`.
Receipt artifact: `10305650934`. Rollback artifact: `10305735709` (previous DEV5
and LIVE packages). The exact 18-file receipt was downloaded and checked against
the accepted candidate and previous LIVE identities. No release task remains.

Test URL: https://corpax88.github.io/Ever-Deeper/dev/?v=1.0.0-dev.6
The menu must show `1.0.0-dev.6`. Use the current save; no reset is needed.

Phone acceptance: continue the existing Starforge save. Enter and leave the Hub,
reload, and confirm the guide continues toward the first drill without resetting.
