# Render-resolution diagnostic — completed, no release

2026-09-24. User authorized automated testing to reduce phone-test burden. Public DEV15.9 remains unchanged. This is a diagnosis, not a proven iPhone optimization.

## Evidence

Unmodified export `c63aabd3e3e5120579285ce6e8b0b59a75f2727a`, existing build36043919958/artifact10827118862; all nine package hashes verified. No re-export or zero-alpha shader hook. Harness `9dc75b209d58a554bd8aafe64797c1a98afa505c` on `codex/resolution-study-20260924`; successful run36053276102, macos-15 Chromium and WebKit jobs. Original screenshots/reports: resolution-chromium10831292770 and resolution-webkit10830589819.

Same seeded stationary Ember scene, lights on, CSS776×420, actual canvas and GL drawing buffer checked at DPR3/2/1. Position and logical viewport fixed. Each size prewarmed,45s additional warmup, nine12s windows in order3/2/1/1/3/2/2/1/3,1.8s settling. Both browsers completed all9 windows and59 checks, including movement after restoration and no script errors. These are separate Mac runners; compare within browsers only.

| Browser | DPR / framebuffer | Weighted FPS | Individual windows FPS | >33ms frames | Draw calls |
|---|---|---:|---|---:|---:|
| WebKit26.5 | 3 /2328×1260 |46.55|37.03,52.83,49.95|88|174|
| WebKit26.5 | 2 /1552×840 |54.86|47.67,58.70,58.19|47|174|
| WebKit26.5 | 1 /776×420 |55.46|55.36,55.61,55.41|57|171|
| Chromium151 | 3 /2328×1260 |58.07|58.12,56.51,59.58|15|174|
| Chromium151 | 2 /1552×840 |59.21|58.37,59.53,59.73|14|174|
| Chromium151 | 1 /776×420 |58.99|58.68,58.85,59.44|22|171|

WebKit renderer Apple GPU; Chromium Apple Paravirtual/Metal. WebKit has no supported GPU timer here. Chromium GPU intervals DPR3/2/1 mean5.464/5.294/4.938ms, median6.597/6.543/6.217ms,725/736/732 samples, zero disjoint. They time instrumented GPU command intervals, not lighting alone or physical device utilization.

## Interpretation and visual checks

WebKit suggests meaningful total-resolution sensitivity, but large early drift persists despite prewarming (DPR3 37→53→50). Aggregate +17.8% at DPR2 is not a reliable projected phone improvement. Later DPR2 windows58.70/58.19 exceed later DPR3 52.83/49.95, supporting further focused investigation. DPR1 does not consistently beat DPR2. Chromium is near the60Hz ceiling and gives no decisive comparable bottleneck reproduction. Never transfer these FPS values to iPhone.

Root inspected all eight original full screenshots. Framing, terrain, light placement and silhouettes remain aligned. DPR2 visibly softens fine detail and text; DPR1 is clearly coarse/pixelated and unsuitable as an automatic quality choice. Browser screenshots remain at contextDPR3 and show the upscaled lower-resolution canvas. Changing DPR scales UI/native viewports/postprocessing as well as terrain; draw calls also fall174→171 at DPR1. Do not attribute the result exclusively to light shading.

Full-resolution restoration is NOT pixel-exact: WebKit1608 changed RGBA channels/max36,682 pixels within x1414–1445,y83–177; Chromium889/max29,431 pixels within x1416–1443,y85–181. All changes are confined to the minimap marker area; the world and remaining HUD restore exactly. Existing freeze does not freeze this marker. Raw differences were retained rather than silently masked.

## Decision / next step

Accept as a useful bounded diagnostic; do not publish a blanket resolution reduction or request another phone report now. A follow-up candidate should preserve sharp HUD and approved asset detail while reducing the cost of the illuminated world; feasibility is unproven. A narrower world-render-scale prototype would need same-scene visual comparison, repeated WebKit timing with a stable baseline, and only then a short phone validation if worth the user's time. Do not promise60FPS or call lighting the sole bottleneck. No new prototype was built in this task. Earlier floor merging and zero-alpha hook remain rejected.

Canonical game source branch is `codex/native-light-dev15-9-20260924`; results are documentation only. Reproduction harness stays on its separate branch. Do not rerun this unchanged experiment or republish the unchanged15.9 package. Full original evidence is in the two Actions artifacts; report JSON and grouped analysis are committed beside this handoff.
