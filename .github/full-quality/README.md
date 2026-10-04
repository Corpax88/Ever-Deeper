# Full game quality review — 4 October 2026

Baseline is published DEV15.54, source `be3a698e0ad8bedb91e877b9932a7bb05b80684a`, immutable artifact `11284088414` from run `37151451383`. The root repository is incomplete and historical main must not be rebuilt.

`prepare.py ORIGINAL OUT [overrides.json]` verifies the baseline PCK SHA256, copies its nine distribution files and appends only the explicit source overrides and isolated QA fixture. With no list, every production payload remains byte-identical. Existing packed QA is copied into `full_quality_base.gd`; the new fixture inherits it. Generated QA packages are **not publishable**: the production pack must omit the fixture remaps and be checked separately.

`review.mjs` exercises real Chromium touch in the actual candidate, storing a JPEG plus exact game state for every capture. It records GPU/browser/viewport/DPR/source/package identity, first-run 0–10s, movement, Skills/settings/achievements/full inventory/companion, surface and underground maps, commerce families, treasury entry/delivery/exit, mod previews and all four biomes at 667/844/932 CSS widths. Fixtures seed explicit progression states; this is not a blind player journey or physical iPhone/FPS evidence. The unchanged ordinary WebKit startup is a separate capture set. Review screenshots, not only job status.

For candidate source changes, list **only** intended production resource paths in `overrides.json`; later builders must preserve unlisted originals. Save retry regression runs only if `run_state.gd` is listed. The user requested a checkpoint after each source change; the parent agent owns those commits and publication.

The independent recovery job produces SHA256-verified chunks of at most28MiB, each uploaded separately. Download each small artifact; concatenate `.bin` in manifest order, verify the archive hash and unzip. Future review pushes can use `[qa-no-recovery]` in the commit title to avoid repeating immutable recovery. No credentials or real player saves are captured.
