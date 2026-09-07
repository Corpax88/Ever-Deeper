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
