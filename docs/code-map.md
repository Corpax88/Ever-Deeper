# Where to change what

Read this map, then the named owner. You should not need to read the whole game for a small fix.

| Task | Start here | Related owner |
|---|---|---|
| Startup, travel, input routing, station transactions | `scripts/main.gd` | The active world and UI component |
| Save/load, run progression, upgrade transactions | `scripts/state/run_state.gd` | `scripts/state/save_epoch.gd` |
| Mine IDs, world mapping, shared presentation definitions | `scripts/world/world_catalog.gd` | Aliases in callers preserve the existing API |
| Prices, rewards, resource definitions | `data/ever_deeper_v0381.json` | `scripts/autoload/game_data.gd`; filename is historical |
| Surface routes, mining, ambient art | `scripts/world/surface_world.gd` | Surface parallax and transition components |
| Depth 1 blocks, barriers, drops | `scripts/world/mossvein_mine.gd` | `cave_edge_asset_drawer.gd` |
| Depth 2 geology and gates | `scripts/world/depth/rootwound_world.gd` | `rootwound_layout.gd` |
| Base hub and workshop placement | `scripts/world/hub_world.gd` | `station_transaction_fx.gd`, `belt_network.gd` |
| Endless layers, relics and rope | `scripts/world/endless_descent_world.gd` | RunState endless state |
| Shop entries, costs and descriptions | `scripts/ui/commerce_catalog.gd` | RunState is the transaction authority |
| Shop layout, browsing and touch | `scripts/ui/commerce_panel.gd` | `inertial_carousel.gd`, `swipe_pager.gd` |
| Outfit and light previews | `scripts/ui/outfit_preview.gd`, `light_preview.gd` | Actual hero and headlamp renderers |
| Hero movement, animation and equipment | `scripts/player/` | Production art under `assets/hero/dad/` |
| Light effects | `scripts/lighting/` | RunState supplies the selected style and level |
| Terrain cutouts, blending and parallax clipping | `shaders/` | World components bind each shader |
| Companion and its skills | `scripts/companion/` | `mole_skills.gd` owns skill definitions |
| Menu, HUD, inventory and tutorial | `scripts/ui/` | Named components own their presentation |
| Achievements, guide and progression | `scripts/progression/` | RunState persistence |
| Sound and music | `scripts/audio/audio_director.gd` | Authored audio assets |
| FPS, frame-time captures and physical DEV meter | `tools/run_performance.py`, `scripts/qa/suites/mobile_performance.gd` | `docs/performance.md`; meter in `scripts/dev/developer_menu.gd` |
| Automatic DEV lighting comparison | `scripts/dev/render_probe.gd`, `tools/render-probe-web.mjs` | Seven-stage, two-minute test; `docs/performance-diagnosis/render-probe/README.md` |
| Automated startup flags | `scripts/qa/qa_launcher.gd` | Ordered first-match registry |
| Older scene fixtures and regression checks | `scripts/qa/suites/` | Named suites with explicit `main` access |
| Current gameplay and touch checks | `scripts/qa/overhaul_qa.gd`, `menu_touch_qa.gd` | Visual capture driver provides fixtures |
| Deterministic mobile captures | `scripts/dev/visual_capture_driver.gd` | `tools/capture-web.mjs` |

## Boundaries

`main.gd` coordinates components; it does not own world balance. `RunState` owns persisted
state and transaction accounting. Catalogs describe choices; panels preview or emit actions.
Do not move save migration or purchase rules into a visual component.

QA is invoked through `qa_launcher.gd`; normal gameplay does not create a QA session.
The registry preserves the original command precedence and deferred startup. Suite code
uses `main.property` or `main.method()` explicitly; there is no generic proxy that hides
which object owns a value. The launch node owns performance sampling and test-suite lifetime.

## Remaining debt

RunState and the world scripts are still large and combine several related responsibilities.
A future change may justify extracting one coherent catalog or render component with its own
parity evidence. This cleanup deliberately does not redesign progression, saves or simulation.
`docs/dead-code-removals.json` records the closed private implementations removed here;
public/debug APIs, active fallbacks and legacy save support remain.

### DEV6 lighting cost

`scripts/lighting/lit_floor_chunks.gd` and `lit_draw_sections.gd` bound lighting work
for the hub and Depth 2 while the world owners retain drawing and gameplay state.
`headlamp_beam.gd` removes only transparent texture margins with a compensated offset.
`scripts/qa/suites/lighting_release_review.gd` compares the exported package with
the original draw paths and reconstructed original cone, including mining and corners.
`.github/workflows/dev-lighting.yml` builds both flavors, runs current gameplay gates,
then native visual cases and the 120-second Chromium DPR3 probe.


The DEV6 package receipt lives in `.github/dev-lighting/review.json`; DEV-only publication
uses `.github/workflows/publish-dev-lighting.yml` and its sibling publisher.
`tools/review-lit-gates.gd` and `.github/workflows/dev-lighting-gates.yml` verify actual
visible, intact/struck gates from the unchanged exported PCK. Run this alongside the
package suite because its initial gate positions can fall back to the entrance.

### DEV7 floor lighting

`shaders/lit_floor_composite.gdshader` combines the existing floor tint and wash
before shared lighting. `lit_floor_chunks.gd` retains the DEV6 two-pass reference
through `composite_pass`. The exact-package review toggles only this choice.
`dev-lighting.yml` includes visible and struck gate coverage in the same package run.
The physical DEV6 report and isolated studies are recorded under
`docs/performance-diagnosis/light-cost/`.
