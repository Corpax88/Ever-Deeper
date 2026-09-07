# Ever-Deeper FPS handoff — v0.46.9

No critic or other agents used. One optimization round.

Implemented: static Light Lab preview renders only when changed; unchanged
companion/action UI avoids repeated invalidation; optional DEV TOOLS → SHOW FPS.
The frame meter shows FPS, p95, maximum frame and count over 33.34 ms.
Gameplay, artwork, world geometry, saves and hero animation are preserved.

22 rendered scenarios were measured. In the paired software-renderer test,
Light Lab improved 12.0→17.0 FPS, p95 88.00→61.82 ms. Other areas were roughly
unchanged. These are not physical-iPhone FPS results; do not claim 10/10 or
verified 60 FPS on iPhone. The headless 442 MiB memory result is not comparable
to the rendered CPU/GPU memory split; GPU usage reached about 566 MiB.

Final exact-package QA and visual review succeeded in run 34155202247; source
a3293f7527e57fb5c8fe80556c44ebc454fd8118. Source checks run 34155338470 passed.
Review, raw metrics and hashes: `.github/performance-v0469/`. PR #9.

Publication is being finalized; consult the publication receipt for its result.
LIVE: https://corpax88.github.io/Ever-Deeper/
DEV: https://corpax88.github.io/Ever-Deeper/dev/

Next: Mats loads v0.46.9-dev.1, enables SHOW FPS, revisits the reported choppy
area and tests mining and shops. Request the meter readings and location; a
screen recording can help diagnose motion but may itself affect performance.
Do not redesign assets or gameplay to improve a synthetic benchmark.
