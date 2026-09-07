# FPS investigation — handoff, 2026-09-07

**Status:** a visually lossless optimization candidate is measured; the physical
iPhone FPS drop is not confirmed fixed. No game build published in this round.

## User evidence
- Mats uses iPhone Air (called iPhone 17 Air), Safari, developed hub / Mossvein D2.
- Fresh start ~50 FPS, then ~14 while stationary; also happens without recording.
- D2 meter: CPU 6 -> 8ms; physics 1ms; canvas 2328x1260 / DPR3; GPU 488MiB,
  nodes703 and draws140 stay stable. Static memory unavailable.
- No more idle/no-recording confirmations or phone recordings needed now.

## Tested findings
- Fixed-resolution ablations locate large native rendering cost in lighting the
  root world drawing in BOTH hub and Mossvein. Removing lighting is not a fix.
- A background rectangle is completely covered by the opaque floor texture.
  Skipping its covered portion gives about **25% higher native FPS** in both.
- Baseline/control/candidate/restored captures are **byte-identical**, 2328x1260.
  All lights, shadows, textures and resolution retained. Both CI jobs passed.
- Native llvmpipe is not iPhone hardware; delayed drop still not reproduced.

## Code, evidence and next step
- Repo: /workspace/scratch/85365910283d/ever-deeper
- Remote branch: codex-sustained-hub-probe. Main not overwritten.
- QA: scripts/qa/suites/sustained_hub.gd; --qa-sustained-hub --perf-effects
  --perf-covered-floor; add --perf-effects-mossvein for Mossvein.
- Success: Actions 34163890969. lighting-runs.json has source/artifact digests;
  covered-floor-hub.json and covered-floor-mossvein.json have measurements.
- Detailed evidence/limitations: lighting-investigation.md.
- Next: turn the covered-floor experiment into a clean production candidate,
  removing temporary metadata/time-freeze hooks from game code; verify affected
  depth profiles and normal gameplay, then review a DEV build. Preserve lighting
  and artwork. Do not claim the iPhone issue solved without physical confirmation.

No critic or other agents. Latest FPS-thread publication remains DEV dev.2;
this round only saved test code and evidence. Keep user updates to five lines.
