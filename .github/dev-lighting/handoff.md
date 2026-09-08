# DEV7 floor lighting handoff

> Subsequent release: the approved Gruvepappa v28 was published to DEV8 in run 34270405341. All DEV7 floor/FPS changes are retained. The current DEV file hashes and verified publication receipt are in `.github/hero-v28/`; use that DEV8 package as the previous-release baseline for the next deployment. LIVE remains unchanged.


DEV7 is published and all 18 public files were verified at 2026-09-08T18:41:49Z.
LIVE remains byte-identical 0.46.9. See publication-receipt.json and review.json.
The prior DEV6 review and receipt are archived beside them.

## Physical evidence

IMG_1744.jpeg is the user's DEV6 hub report from the same affected iPhone Air:
start 60, original 30.1, pet lights off 32.2, restored 29.7, shadows off 30.1,
restored 30.0, all lights off 60.0, restored 30.0 FPS over 120 seconds.
Compared with DEV5's original 19.8, this verifies roughly 52% improvement, but
the slowdown remains. Full transcription: iphone-dev6.json in the light-cost report.
Do not claim a thermal cause; temperature was not measured. Hub and Mossvein Depth 2,
Safari and home-screen icon were already affected alike. Do not reask those facts.

## DEV7 change and checks

The existing textured floor and translucent color wash share one lighting pass
through shaders/lit_floor_composite.gdshader. lit_floor_chunks.gd retains the DEV6
two-pass reference with composite_pass=false. Chunks remain 256px: 64/128 did not
provide worthwhile gains. Light nodes, energy, color, range, shadows, artwork,
gameplay, saves, resolution, DPR and stock-engine presentation are unchanged.

The controlled paired software study measured hub 2.999 to 3.974 FPS, restored
3.003; Mossvein 3.243 to 4.266, restored 3.258, at 2328x1260. This is about 30%
further improvement on Mesa, not a physical iPhone prediction. Study run 34261843315
and the unchanged-DEV6-package cost isolation run 34261639588 both passed.

Final PCK source 85b808bd2390a2fc81b66a503ab57f0a28eed50c, artifact 10070746874,
run 34262864741: all 11 jobs passed. Ten current gameplay cases, protected-file
invariants and both exported flavor checks passed. All 35 native paired cases,
light/commerce previews and both Chromium report panels were visually inspected.
The reached/struck gate job is now part of that same exact-package workflow.

Rendering is visually equivalent but NOT bit-identical: the original framebuffer
clips each floor pass separately. Isolated bright floor texels can differ by up to
29/255 per channel in static cases, while most differences are 0–1/255. Larger hub
differences are in its animated elevator and also occur in baseline controls.
No visible regression was found. All eight unaffected-world pairs are identical.
Full metrics are in dev7-pixel-comparison.json. Do not call the floor change lossless.

Chromium hub 120.85526s and Mossvein 120.532495s both completed seven valid stages,
restored graphics and mobile touch/focus behavior, and retained 2532x1170/DPR3.
All 12 artifact digests and nine candidate files were checked. Only HTML/PCK differ
from DEV6; JS, WASM, audio worklets and icons are byte-identical. Main QA also passed.

## Next step

Await the user's same two-minute AUTO FPS TEST from DEV7 in the hub. Confirm the
report says 0.46.9-dev.7. Do not claim the physical drop is fixed before that result.
No further work or retesting is pending on the published package.

Keep updates brief and Norwegian. No critic/subagents. Preserve the audited cleanup.
All ten pet skills were already tested; do not repeat that investigation without
new evidence. Do not repeat resolution, presentation or audio experiments.
Another chat is working on a new hero; refetch main before new mutations and keep
that work untouched. DEV-only publication is authorized; LIVE must stay unchanged.
