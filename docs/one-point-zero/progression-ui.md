# 1.0 progression HUD

Implemented a persistent, compact goal area on the right using the existing green/gold HUD palette, approved Chakra typography, and original resource textures. The mine control and matching tutorial hint now use the original `assets/tools/pickaxe-iron.png`. Tunnel Home uses the existing mole HUD asset and a compact HOME caption. No art was generated or replaced.

## Integration

- `GuideDirector.goal_for_state()` retains all route IDs/kinds and adds `hud_title`, `hud_action`, `requirements`, and `requirements_ready`.
- `PremiumHud.set_progression_goal(goal)` replaces the old title/detail call in `main._update_visual_guide()`; it also preserves the existing optional guide popover.
- `PremiumHud` listens to `RunState.changed` and resolves the same goal synchronously, so collecting, selling, delivering, crafting, placing a relic, and building a workshop immediately update its counts and next step. World waypoint resolution remains on the existing slower route timer.
- `PremiumHud.progression_goal_snapshot()` reports actual rendered rows, panel rectangle, title/action, and input blocking. `layout_snapshot(viewport).progression_goal` reports its layout bounds.
- All new HUD controls use `MOUSE_FILTER_IGNORE`; no touch handlers, timers, animation loops, or modal bypass paths were added.

## Requirement contract

Each row contains `id`, `resource_id`, `name`, `texture_path`, `owned`, `in_pouch`, `delivered`, `pending_sale`, `required`, `ready`, and `is_currency`. Currency and mined gold have distinct IDs. Delivered construction materials remain included in progress after leaving the pouch. Gold displays e.g. `0 (+14) / 20` when the haul is worth 14: `owned` and `ready` still refer to actual banked gold; `pending_sale` comes from the real sale snapshot and excludes protected resources.

| Goal | Price / inventory authority |
| --- | --- |
| Pickaxe and Ember Mastery | `RunState.forge_purchase_snapshot()` |
| Campaign gates | `GameData.GATE_COST`, `EMBER_GATE_COST` (main transaction aligned) |
| First Starforge form | `RunState.starforge_crafting_status().variant.cost` |
| Drills | `RunState.next_drill_recipe()` |
| Deepheart passage restoration | `RunState.deep_elevator_status().recipe` and `.deliveries` |
| Workshop construction and upgrades | `RunState.workshop_status()` |
| Sellable haul | `RunState.assay_sale_snapshot()` |

No purchase, resource, save, unlock, or price authority is implemented in the HUD. Commerce preview stats now consume `RunState.workshop_effects_at_level()` for actual Forge power/speed/mining reach, Light Lab effects, Treasure pickup/cache yield, and the Tunnel Workshop preparation benefit (1.25s → 0.45s).

## Progression behavior

Existing campaign and Deepheart prerequisites remain. Post-Deepheart goals prioritize carrying a relic home, placing it, completing the workshop it unlocks, then the next of five relics. After the fifth Hub build, available workshop upgrades continue as concrete goals; after actual upgrade caps, the goal remains deeper mining. Internal `deepElevator` / `lift_workshop` IDs remain compatible; visible goal copy says The Deep, Tunnel Home, or Deepheart passage.

The state pouch has no hard capacity limit, so no fictional full-bag blocker was added. New node textures are cached and only labels whose values change are rewritten.

## Verification and outstanding review

Godot 4.7.2 `layout` and `onboarding` suites passed (844×390 through 956×440; clear pickaxe, 44-CSS-pixel controls, nonblocking tutorial). The independent 1.0 state suite passed 240 accelerated checks. The critic subsequently reported all 13 source gates green, 261 UI checks, 515 world checks, and 260 migration checks; rendered package and physical-device acceptance remain separate. Parent/critic own final in-game captures, modal and full progression review, and physical iPhone performance acceptance. This implementation report is not release approval; no publishing was performed.
# Round 1 mobile spacing correction

Rendered inspection found the new goal overlapping the existing minimap. Both now use `PremiumHud.layout_snapshot(viewport)` rectangles: the unchanged minimap sits immediately left of the right-side goal with a 12-unit mobile gap. `minimap_layout_changed` carries the applied native safe-area position to the map. No minimap drawing or assets changed.

The largest campaign recipe has five rows. On mobile only, that recipe omits the location/action subtitle while retaining the title and every full-size resource row; full action detail remains in Guide. A live PanelContainer check across 844×390, 852×393, 896×414, 926×428 and 956×440 with the configured 1.1 content scale confirms a 340×215 panel, 7.55 logical units above the context control, no map overlap, and both panels inside safe bounds. The desktop aspect also passes. Native final-package review captures both four- and five-row recipes; geometry checks do not replace that visual gate.
