LIVE1.0.3 is published at https://corpax88.github.io/Ever-Deeper/ under Mats's explicit 1 October request. Publication0f508915a108bbf55f1b2dac2e699c57f82e1a69/run36854969249 succeeded; receipt11158481002 verifies all27 public hashes, preserving DEV15.38/Worn nine each. Previous LIVE1.0.2 rollback11158985394. Canonical production source8b7f913b6a6703f2f238605e02a01df95ead7103 on codex/live-1-0-3-20261001; immutable DEV15.38 promotion plus version/flavor and retained loading-rotation fix. QA36854385131 passed input,414 core,341 migration,production flavor,38 Chromium checks and ordinary WebKit. All21 final captures inspected. Existing LIVE1.0.2 save continues; no DEV save copying. Candidate11157241499; browser11158195999/core11156982110. Main is publication carrier, never rebuild its historical runtime.

Public website https://ever-deeper-game.corpax88.chatgpt.site updated successfully: six new release records (63 total), history milestone, current LIVE link and three real DEV15.38 images (39 gallery steps). Site appgprj_6abcf3a6e07481918afb1c03f29caec0, source e295a033d7337126f67898fd340a7c8e91cbb609, version5, deployment appgdep_6abe4364b02c819195c6b2db5829e453 succeeded. Source checkout /workspace/sites/ever-deeper-game; retain existing public audience and preserve historical gallery. No recurring automation requested. See docs/live-1-0-3/HANDOFF.md.

No pending jobs or approvals. Other26 mod effects remain undefined;100000 target provisional. No physical-iPhone/FPS claim; FPS remains parked. Existing QA flag-order invariant debt remains. Do not repeat accepted unchanged matrices or publication. Next is player feedback on LIVE feel, or defining further mod effects when requested.

DEV15.38 is published at https://corpax88.github.io/Ever-Deeper/dev/ and all 27 public hashes verified. Canonical gameplay `5afb6af4bdcf59aa551476218c33be7668b7f012` on `codex/treasury-stacking-20261001`; QA `36846647651` passed input, 414 core checks, 113 browser checks and ordinary WebKit; 57 final images inspected. Publication `ddf0deb312d0ebdd43f11fa9636968c1bceb80e5` / run `36847637116` succeeded; receipt `11154147013`, rollback `11153723737`. LIVE9/Worn9 retained. 180-slot layered stacks, all 27 saved collection goals and source hints, earned Resonance claim/toggle and actual map markers with blurred locked worlds. Other 26 mod effects remain undefined; 100000 is provisional goal balance. No pending jobs or approvals. No physical-iPhone/FPS claim; FPS remains parked; inherited QA flag-order invariant debt remains. Main is publication carrier only; do not rebuild its historical runtime or repeat accepted unchanged QA. See docs/treasury-stacking/HANDOFF.md.

Current verified release: [DEV15.17 CPU and audio fixes](docs/full-fps-audit/FIXES-V2-RESULTS.md), source21e415af523d497f6ec37706e42694b7f9c5302b on codex/fps-fixes-20260928. Validation36413947044 passed both Mac workers (94 gates each), exact sampled images, actual contour replay across two resource IDs, six core cases and clean ordinary startup/save flow. Four scoped reductions: fresh-pose copies, unchanged music gains, music position messages and per-search companion collision work. Mining FPS +7.75%/+10.37%, total +5.00%/−1.76%; surface and motion-helper timing remain mixed. Not a complete FPS fix or physical-phone acceptance. Depth-prepass remains parked; FBO/contact-hoist/sync experiments excluded. Preserve approved game/hero/lighting/resolution/saves, LIVE and Worn. Published by fe50e75345a394a7c7979f8429d27961c4ebf86d /36415959436 using reviewed immutable artifact10967022774; all27 public hashes pass, LIVE/Worn preserved. No jobs remain pending. Main is publication carrier; do not rebuild its historical runtime or repeat completed unchanged matrices.

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
| Continuous The Deep, relics and rope | `scripts/world/endless_descent_world.gd` | `endless_deep_layout.gd`, `scripts/state/endless_terrain_state.gd`, RunState |
| Shop entries, costs and descriptions | `scripts/ui/commerce_catalog.gd` | RunState is the transaction authority |
| Shop layout, browsing and touch | `scripts/ui/commerce_panel.gd` | `inertial_carousel.gd`, `swipe_pager.gd` |
| Wardrobe portrait | `scripts/ui/wardrobe_portrait.gd` | Approved PNG under `assets/hero/dad/wardrobe/`; release in `.github/wardrobe-portrait/` |
| Outfit and light previews | `scripts/ui/outfit_preview.gd`, `light_preview.gd` | Actual hero and headlamp renderers |
| Hero movement, animation and equipment | `scripts/player/` | Production art under `assets/hero/dad/` |
| Light effects | `scripts/lighting/` | RunState supplies the selected style and level |
| Terrain cutouts, blending and parallax clipping | `shaders/` | World components bind each shader |
| Companion and its skills | `scripts/companion/` | `mole_skills.gd` owns skill definitions |
| Menu, HUD, inventory and tutorial | `scripts/ui/` | Named components own their presentation |
| Achievements, guide and progression | `scripts/progression/` | RunState persistence |
| Live next-goal resource requirements | `scripts/progression/progression_goal.gd` | `guide_director.gd`, `scripts/ui/progression_goal_panel.gd`; costs remain in RunState/GameData |
| Sound and music | `scripts/audio/audio_director.gd` | Authored audio assets |
| FPS, frame-time captures and physical DEV meter | `tools/run_performance.py`, `scripts/qa/suites/mobile_performance.gd` | `docs/performance.md`; meter in `scripts/dev/developer_menu.gd` |
| Automatic DEV lighting comparison | `scripts/dev/render_probe.gd`, `tools/render-probe-web.mjs` | Seven-stage, two-minute test; `docs/performance-diagnosis/render-probe/README.md` |
| Automated startup flags | `scripts/qa/qa_launcher.gd` | Ordered first-match registry |
| Older scene fixtures and regression checks | `scripts/qa/suites/` | Named suites with explicit `main` access |
| Current gameplay and touch checks | `scripts/qa/overhaul_qa.gd`, `menu_touch_qa.gd` | Visual capture driver provides fixtures |
| Deterministic mobile captures | `scripts/dev/visual_capture_driver.gd` | `tools/capture-web.mjs` |
| 1.0 continuous-world acceptance | `scripts/qa/suites/one_point_zero.gd` | Named world, terrain, migration and UI suites; `docs/one-point-zero/` |
| Exact 1.0 DEV build and publication | `.github/one-point-zero/` | Immutable candidate review; preserves all current LIVE files |

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

## Approved Gruvepappa v28

Native Blender export and atomic atlas packaging live in `tools/hero_v28/`.
`assets/hero/dad/<gear>/` holds the real 160px animation cells and garment masks.
`visual_capture_driver.gd` owns the opt-in v28 mobile matrix; ordinary play retains
the existing player, equipment, outfit and save behavior. Release evidence and the
DEV-only publisher live in `.github/hero-v28/`.
