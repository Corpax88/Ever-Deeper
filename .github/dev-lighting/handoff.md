# DEV6 lighting handoff

DEV6 is published and all 18 public files were verified at 2026-09-08T17:40:31Z.
LIVE remains byte-identical 0.46.9. See publication-receipt.json and review.json.

## Current result

The physical DEV5 screenshot in the hub gave 19.8 FPS original, 22.9 pet lights off,
20.7 shadows off and 60 all lights off; restoring lights returned to 19.9. This
isolates lighting-dependent rendering work but does not prove a thermal explanation
for the approximately 30-second delay.

DEV6 partitions floor/station/terrain drawing into bounded CanvasItems, and crops
transparent cone margins with compensated offset and unchanged shadow emitter.
All light colors, energy, ranges, shadows, artwork, gameplay and save APIs are retained.
No DPR/resolution/presentation patch or transparent-discard material was adopted.

At 2328x1260 the paired software-renderer study improved hub 2.01 to 3.03 FPS and
Mossvein 1.72 to 3.27, each restoring to baseline. This is not physical iPhone FPS.
Final exported PCK: source cdfd85360fe8707225ded2e0a52ef3870a5f4ec4,
artifact 10068112526, run 34256408421 (all ten jobs successful).
35 native pairs plus preview/browser images inspected. The actual visible/struck
gate supplement is run 34257483120 and uses the same PCK; do not count the original
gate-position cases alone, since those can fall back to the entrance.

## Next step

Await the user's existing two-minute AUTO FPS TEST report from DEV6 on the affected
iPhone Air (hub is sufficient first). The result panel identifies 0.46.9-dev.6.
Do not claim the physical slowdown is fixed before that report. Both hub and Mossvein
Depth 2 were affected; Safari and the home-screen icon behaved alike. Pet skills
were already tested individually earlier, and all ten were active in current fixtures.

Keep user updates short. No critic/subagents. Keep the audited code cleanup.
Do not repeat resolution, stock-engine presentation or audio-driver experiments
without new evidence; preserve visuals. The main QA, exact-package core/flavor checks,
two full 120-second Chromium DPR3 probes and public byte verification have passed.
