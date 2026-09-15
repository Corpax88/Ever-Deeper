# Premium polish recovery — 15 September 2026

## Current source

The approved upload target is the public repository `Corpax88/Ever-Deeper`, work
branch `codex/premium-polish-recovery-20260915`. Mats explicitly approved uploading
the source and animation checkpoint to this branch on 15 September.

The previous checkout at `/workspace/scratch/bcf004da8655/ever-deeper` is now empty.
The last locally recorded commit was `71034d4`, following
`277215ecf7688bc6379b627dc51b9ace88344cea` and
`2b5539413a64f12e3193e147a5960fcdfbc50ea6`. Those commits were never uploaded:
the earlier upload was blocked by automatic approval review. Direct GitHub reads
now confirm that the last checkpoint is unavailable. The local render supervisor
is also gone. Do not describe that checkpoint as uploaded or recoverable in full.

This recovery starts with the complete canonical source at
`d4619e5429326b880c4da2d466a2bf5351f0f46c`. Its published DEV label is 1.0.0-dev.8.
The preserved patches are partial and do not apply cleanly to that baseline.
Historical test evidence below describes the lost candidate, not this restored tree.

## Preserved evidence and inputs

- `recovery/pre-resume.patch`: exact surviving binary patch, originally based on
  the interrupted polish checkout. It is not a replacement for its missing base.
- `recovery/pre-resume-untracked.tar.gz`: exact surviving untracked-file backup.
- `recovery/scripts/`: surviving chest and terrain migration scripts, retained
  byte for byte for review. Their old hardcoded paths must be reconciled before use.
- `recovery/motion-final-{worn,crusher,deepcore}/`: actual native gameplay reports
  and recordings from the lost source. All three reports say passed. Recordings
  are fixed-step 1280×720 movies, not physical iPhone or real-time FPS evidence.
- `recovery/evidence-sha256.json`: hashes of the preserved recovery files.

The approved v28 Blender original, native v9 equipment sources and material-v2
study have been recovered separately from their existing saved originals. Personal
reference photos and Blender originals are not part of the public code payload.

## Where the lost candidate had reached

Previous session records reported 15/15 source cases, 24 hero runtime checks,
40 rendered game states, and integration of five new sets: worn, iron, Crusher,
Burrower and Deepcore (2,592 genuine poses plus masks). The source, production
atlases and raw frames for those new sets are no longer present. The other six
sets were unfinished. Do not attribute those results to the baseline or rebuilt
source; new code and sprites must be tested again.

## Continue

1. Preserve this recovery checkpoint on the approved work branch.
2. Restore code changes only from verifiable inputs and re-run current source
   checks; inspect actual captures for each restored visual change.
3. Recreate animation work from the approved native model and documented exporter,
   maintaining real frames, tool identities, grip alignment and outfit masks.
4. Reconcile protected-file hashes only for reviewed intentional changes.
5. Resume package/Mac/Safari review and physical iPhone performance acceptance.

No recovered-source upload is a game release. Existing visual release rules in
`AGENTS.md` still apply, and LIVE 1.0 acceptance remains open.
