# DEV frame meter revision 2

Build identity: v0.46.9-dev.2. This is instrumentation, not an FPS fix.
Normal production remains v0.46.9. The developer-menu script is excluded from LIVE.

SHOW FPS displays a four-line, non-interactive overlay marked D2:
- Wall-clock FPS, frame p95, max frame and count exceeding 33.34 ms.
- Engine CPU process and physics monitor samples in milliseconds. These are
  engine counters sampled every two seconds, not GPU timing or CPU percentiles;
  do not subtract them from wall-clock p95 to infer GPU duration.
- Actual canvas backing width/height and browser devicePixelRatio, plus draw calls.
- Engine static and reported video memory in MiB, and node count. A memory value of n/a means
  the engine did not report a usable counter; it does not mean zero memory use.

Only the two-second wall-clock frame sample runs per frame. The additional
monitor queries and browser dimension read run once per completed interval.
There is no pixel readback, network request or disk write. Sixty readings are
kept in memory (about two minutes); starting again clears that history. Hiding
the meter disables its processing. Focus return discards the partial interval
so time in another app does not become a false frame stall.

Device reproduction: reload DEV, Continue the existing hub, enable SHOW FPS,
leave hero still and record the overlay through the high-to-low transition.
Compare CPU, canvas, draw count, memory and nodes immediately before/after.
Do not reset or replace Mats's progressed save.

Automated validation uses the exact exported DEV pack: current touch/developer
checks, rendered hub/Mossvein overlay bounds and restart/stop behavior, and WebKit
at 844x390 CSS pixels with device scale 3. The browser checks reported canvas
width, height and DPR against the DOM values, rather than assuming resolution.
Publication identity and exact-package evidence are in .github/dev-meter/review.json.
