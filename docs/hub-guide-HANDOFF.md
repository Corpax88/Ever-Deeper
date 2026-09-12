# Starforge Hub guide loop — local fix, publication blocked

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
- Actual rendered review and GitHub candidate validation have not run. All
  release acceptance flags remain false. Nothing has been published.

## Blocking authorization and next step

Automatic approval review rejected pushing to `codex-ever-deeper-1-0`, stating
that the bug report did not authorize public disclosure of changed source.
Do not retry through a different tool to bypass the rejection. Ask Mats to
authorize uploading this fix and publishing DEV after normal release checks.

After authorization, push the prepared commit to the existing DEV candidate
branch, run the established `one-point-zero.yml` checks, inspect the exact-pack
Hub captures, and record the actual artifact identities in review.json before
merging and publishing. The baseline now pins the verified DEV5 receipt. DEV6
version checks are synchronized; LIVE remains the separately approved 0.46.9.
Do not ship the locally exported PCK as though it were an accepted CI artifact.

Phone acceptance: continue the existing Starforge save. Enter and leave the Hub,
reload, and confirm the guide continues toward the first drill without resetting.
