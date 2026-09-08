# FPS release handoff — 2026-09-08

DEV 0.46.9-dev.3: clean covered-floor optimization, published and public bytes verified after successful
exact-package QA run 34190767917. See .github/dev-floor/review.json.
The native test improvement (~25%) is not a physical iPhone result.

Change: retain only the hub background borders and remove the fully covered
background rectangle under opaque depth-2 floors. Lights, shadows, textures,
resolution and gameplay retained. No test metadata/time-freeze hooks shipped.

Validation: current gameplay suite and build flavor passed; 11 final native
mobile captures reviewed across hub and all four depth profiles; WebKit D2 meter
review passed. Previous pixel-identical experiments and reports remain on
codex-sustained-hub-probe under docs/performance-diagnosis/.

Mats uses iPhone Air. Previous symptom: ~50 -> ~14 FPS while stationary in hub
and Mossvein D2; also without recording. Device CPU 6 -> 8ms, physics1ms,
canvas2328x1260 DPR3, GPU488MiB, nodes703, draws140 stayed stable.
Do not claim the delayed drop fixed before physical confirmation.

Next: user opens DEV with ?v=0.46.9-dev.3, checks version, tests sustained FPS
in the same hub. No new recording is required unless it adds useful evidence.
No critic/other agents. Keep responses to five lines.

Publication 34191148253 passed: all 18 public files verified, LIVE byte-identical.
See .github/dev-floor/publication-receipt.json. Ready for physical iPhone testing.
