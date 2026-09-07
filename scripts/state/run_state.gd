extends Node

signal changed
signal resource_collected(resource_id: String, amount: int)

const MossveinProgressionScript: = preload("res://scripts/progression/mossvein_progression.gd")
const BeltNetworkScript: = preload("res://scripts/progression/belt_network.gd")
const SaveEpochScript: = preload("res://scripts/state/save_epoch.gd")

const SAVE_SCHEMA_ID: = "ever_deeper_run_state"
const SAVE_SCHEMA_VERSION: = 2
const DEFAULT_SAVE_PATH: = "user://ever_deeper_run_v2.json"
const LEGACY_SAVE_PATH: = "user://ever_deeper_run_v1.json"
const SAVE_EPOCH_MARKER_PATH: = "user://ever_deeper_save_epoch_v2.applied"
const GAME_DATA_PATH: = "res://data/ever_deeper_v0381.json"
const COMMERCE_TRANSACTION_HISTORY_LIMIT: = 24
const GOLD_TEXTURE_PATH: = "res://assets/ui/gold-bars-v1.png"
const PICKAXE_TEXTURE_PATHS: = [
	"",
	"res://assets/tools/pickaxe-worn.png",
	"res://assets/tools/pickaxe-iron.png",
	"res://assets/tools/pickaxe-runed.png",
	"res://assets/tools/pickaxe-moonglass.png",
	"res://assets/tools/pickaxe-ember.png",
]
const RESOURCE_TEXTURE_FALLBACKS: = {
	"deep_alloy": "res://assets/endless/node-deep-alloy-v1.png",
	"lumenstone": "res://assets/endless/node-lumen-shard-v1.png",
	"memory_silk": "res://assets/endless/node-memory-silk-v1.png",
	"echo_crystal": "res://assets/endless/node-echo-crystal-v1.png",
	"waystone": "res://assets/endless/node-waystone-v1.png",
}

const RESOURCE_IDS: = [
	"stone", "copper", "moonglass", "gold", "starshard", "emberstone", "sunslag",
	"astralite", "crownstone", "deepstone", "rootiron", "ambercore", "prismite",
	"lunacore", "magmaite", "furnaceheart", "voidglass", "singularity",
	"burrowsteel", "phasecrystal", "infernium", "deep_alloy", "lumenstone",
	"memory_silk", "echo_crystal", "waystone",
]
const ENDLESS_RESOURCE_IDS: = [
	"deep_alloy", "lumenstone", "memory_silk", "echo_crystal", "waystone",
]
const MINE_IDS: = WorldCatalog.MINE_ORDER
const WORLD_IDS: = ["mossvein", "moonglass", "emberdeep", "starfall"]
const WORLD_BY_MINE = WorldCatalog.WORLD_BY_MINE
const STARFORGE_VARIANT_IDS: = ["crusher", "swift", "prospector"]
const VALID_SCENES: = ["surface", "hub", "deepheart", "endless", "mossMine", "moonMine", "emberMine", "starMine"]
const DEFAULT_SURFACE_POSITION: = Vector2(240.0, 680.0)
const SURFACE_WORLD_SIZE: = Vector2(4480.0, 1280.0)
const HUB_WORLD_SIZE: = Vector2(1440.0, 960.0)
const DEEPHEART_WORLD_SIZE: = Vector2(2400.0, 1080.0)
const DEEPHEART_PLAYER_SPAWN: = Vector2(590.0, 776.0)
const HUB_GRID_ORIGIN: = Vector2(192.0, 240.0)
const HUB_GRID_TILE_SIZE: = 48.0
const HUB_GRID_COLS: = 22
const HUB_GRID_ROWS: = 10
const HUB_SURFACE_ENTRANCE: = Vector2(4245.0, 650.0)
const HUB_SURFACE_LIFT: = Vector2(240.0, 820.0)
const HUB_PLAYER_SPAWN: = Vector2(332.0, 820.0)
const BASE_MODULE_INTERACT_RADIUS: = 118.0
const AUTO_SORT_RADIUS: = 360.0
const DRILL_PICKUP_RADIUS_STEP: = 32.0
const STORAGE_CHEST_CAPACITY: = 20
const MINE_TILE_SIZE: = 48.0
const MAX_MINE_LOOSE_DROPS_PER_SCOPE: = 32
const MAX_MINE_LOOSE_DROP_AMOUNT: = 1000000
const HUB_PLAYER_BUILD_CLEARANCE: = 68.0
const HUB_WALL_STONE_COST: = 5
const HUB_LAMP_GOLD_COST: = 80
const DEEP_ELEVATOR_SINK_ID: = "deep_elevator"
const DEEP_ELEVATOR_RECIPE: = {
	"ambercore": 3,
	"lunacore": 3,
	"furnaceheart": 3,
	"singularity": 1,
}
const DEEPHEART_SEAL_IDS: = ["mossvein", "moonglass", "emberdeep", "starfall"]
const ENDLESS_RELIC_IDS: = [
	"forge_heart", "ancient_lens", "memory_loom", "echo_coffer", "wayfinder_core",
]
const ENDLESS_WORKSHOP_IDS: = [
	"tool_forge", "light_lab", "wardrobe", "treasure_chamber", "lift_workshop",
]
const ENDLESS_WORKSHOP_MAX_LEVEL: = 5
const ENDLESS_MAX_SAVED_DEPTH: = 2147483647
const ENDLESS_SITE_LIMIT: = 4
const ENDLESS_SITE_OVERLOAD_SHIFT: = 4
const ENDLESS_RELIC_CATALOG: = {
	"forge_heart": {
		"id": "forge_heart", "display_name": "Forge Heart",
		"workshop_id": "tool_forge", "blueprint_id": "tool_forge_blueprint",
		"build_resource": "deep_alloy", "build_cost": 200,
	},
	"ancient_lens": {
		"id": "ancient_lens", "display_name": "Ancient Lens",
		"workshop_id": "light_lab", "blueprint_id": "light_lab_blueprint",
		"build_resource": "lumenstone", "build_cost": 200,
	},
	"memory_loom": {
		"id": "memory_loom", "display_name": "Memory Loom",
		"workshop_id": "wardrobe", "blueprint_id": "wardrobe_blueprint",
		"build_resource": "memory_silk", "build_cost": 200,
	},
	"echo_coffer": {
		"id": "echo_coffer", "display_name": "Echo Coffer",
		"workshop_id": "treasure_chamber", "blueprint_id": "treasure_chamber_blueprint",
		"build_resource": "echo_crystal", "build_cost": 200,
	},
	"wayfinder_core": {
		"id": "wayfinder_core", "display_name": "Wayfinder Core",
		"workshop_id": "lift_workshop", "blueprint_id": "lift_workshop_blueprint",
		"build_resource": "waystone", "build_cost": 200,
	},
}
const ENDLESS_WORKSHOP_NAMES: = {
	"tool_forge": "Tool Forge",
	"light_lab": "Light Lab",
	"wardrobe": "Wardrobe",
	"treasure_chamber": "Treasure Chamber",
	"lift_workshop": "Lift Workshop",
}
const ENDLESS_WORKSHOP_STYLE_IDS: = [
	"original", "riveted", "crystal", "starforged", "deepheart",
]
const ENDLESS_LIGHT_STYLE_IDS: = [
	"standard", "focused", "wide", "prismatic", "deepheart",
]
const ENDLESS_OUTFIT_IDS: = [
	"miner", "expedition", "archivist", "starweave", "deepheart",
]
const ENDLESS_TOOL_STYLE_IDS: = [
	"original", "crusher", "comet", "crownseeker", "deepheart",
]
const SURFACE_VEIN_IDS: = ["moonglass_bloom", "ember_fault", "starfall_lattice"]
const SURFACE_MOUNTAIN_IDS: = ["moonglass_mountain", "emberdeep_mountain", "starfall_mountain"]
const SURFACE_MOUNTAIN_PROFILES: = {
	"moonglass_mountain": {"ground_resources": ["moonglass", "starshard"]},
	"emberdeep_mountain": {"ground_resources": ["emberstone", "sunslag"]},
	"starfall_mountain": {"ground_resources": ["astralite", "crownstone"]},
}
const SURFACE_VEIN_PROFILES: = {
	"moonglass_bloom": {
		"node_hp": 42, "node_shell": 0, "node_count": 3, "time_limit": 18.0, "respawn": 32.0,
		"ground_resources": ["moonglass", "starshard"],
	},
	"ember_fault": {
		"node_hp": 74, "node_shell": 32, "node_count": 3, "time_limit": 22.0, "respawn": 38.0,
		"ground_resources": ["emberstone", "sunslag"],
	},
	"starfall_lattice": {
		"node_hp": 325, "node_shell": 72, "node_count": 3, "time_limit": 20.0, "respawn": 42.0,
		"ground_resources": ["astralite", "crownstone"],
	},
}

var overhaul_progress: Dictionary = {}
var gold: = 0
var pickaxe_level: = 1
var ember_mastery: = 0
var drill_level: = 0
var drill_goal_scene: = ""
var movement_speed_level: = 0
var total_swings: = 0
var precision_hits: = 0
var total_gold_earned: = 0
var starforge_variant: = ""
var starforge_unlocked: Dictionary = _default_starforge_unlocked()

var cargo: Dictionary = _empty_resource_store()
var mined: Dictionary = _empty_resource_store()



var area_unlocked: = false
var emberdeep_unlocked: = false
var fourth_unlocked: = false
var victory: = false
var conclusion_seen: = false
var singularity_secured: = false
var hub_unlocked_early: = false
var deep_elevator_deliveries: Dictionary = _default_deep_elevator_deliveries()
var deep_elevator_repaired: = false
var deep_elevator_powered: = false
var final_expedition_begun: = false
var deepheart_seals: Dictionary = _default_deepheart_seals()
var deepheart_awakened_at_mined: = 0
var endless_descent_active: = false
var endless_current_depth: = 0
var endless_deepest_depth: = 0
var endless_start_depth_checkpoint: = 1
var endless_resource_exhausted_through: = 0
var endless_active_floor_depth: = 0
var endless_active_floor_mined_mask: = 0
var endless_active_floor_site_mask: = 0
var endless_relics: Dictionary = _default_endless_relics()
var carried_relic: Dictionary = _default_carried_relic()
var endless_workshops: Dictionary = _default_endless_workshops()
var endless_light_style: = "standard"
var endless_outfit: = "miner"
var endless_tool_style: = "original"
var belt_state: Dictionary = {}
var world_seed: = 0
var hub: Dictionary = _default_hub_state()
var base: Dictionary = _default_base_state()

var discovered_mines: Dictionary = _default_discovered_mines()
var discovered_caverns: Dictionary = {}
var discovered_depth_entrances: Dictionary = _default_discovered_mines()
var visited_depths: Dictionary = _default_discovered_mines()
var claimed_pocket_rewards: Dictionary = {}
var pending_pocket_loot: Dictionary = {}
var opened_chests: Dictionary = {}
var pending_chest_loot: Dictionary = {}
var cleared_mine_barriers: Dictionary = {}
var terrain_dug: Dictionary = _default_terrain_dug()
var terrain_dug_lookup: Dictionary = {}
var mine_resource_runtime: Dictionary = _default_mine_resource_runtime()

var current_scene: = "surface"
var current_depth: = 1
var current_position: = DEFAULT_SURFACE_POSITION
var last_surface_position: = DEFAULT_SURFACE_POSITION
var surface_ore_reserve: = 1.0
var surface_ore_yield_buffer: = 0.0
var surface_ore_gold_ready: = true
var surface_ore_updated_unix: = 0
var surface_ore_ground_loot: = {"copper": 0, "gold": 0}
var surface_mountains: Dictionary = _default_surface_mountains()
var surface_veins: Dictionary = _default_surface_veins()
var surface_moonglass_nodes: Array = [
	{"hp": 42, "respawn": 0.0},
	{"hp": 42, "respawn": 0.0},
	{"hp": 42, "respawn": 0.0},
]
var surface_moonglass_vein_status: = "idle"
var surface_moonglass_vein_timer: = 0.0
var surface_moonglass_completions: = 0
var surface_moonglass_updated_unix: = 0
var surface_moonglass_ground_loot: = {"moonglass": 0, "starshard": 0}

var last_load_status: = "not_initialized"
var last_save_error: = OK

var _persistence_enabled: = false
var _save_path: = DEFAULT_SAVE_PATH
var _autosave_pending: = false



const AUTOSAVE_BATCH_SECONDS: = 6.0
var _state_batch_depth: = 0
var _state_batch_dirty: = false
var _game_data_cache: Dictionary = {}
var _mossvein_progression: RefCounted
var _belt_network: RefCounted
var _commerce_transactions: Dictionary = {}
var _commerce_transaction_order: Array = []
var _next_commerce_transaction_id: = 1
var _active_assay_transaction_id: = ""
var _active_forge_transaction_id: = ""


func _init() -> void :


	discovered_caverns = _default_discovered_caverns()
	claimed_pocket_rewards = _default_claimed_pocket_rewards()
	opened_chests = _default_opened_chests()
	belt_state = _belt_rules().default_state()


func initialize_persistence(path: String = DEFAULT_SAVE_PATH) -> bool:
	_save_path = path if not path.is_empty() else DEFAULT_SAVE_PATH
	if _save_path == DEFAULT_SAVE_PATH:
		apply_save_epoch_reset(LEGACY_SAVE_PATH, SAVE_EPOCH_MARKER_PATH)
	_persistence_enabled = true
	return load_game(_save_path)


func apply_save_epoch_reset(legacy_path: String, marker_path: String) -> bool:



	return SaveEpochScript.apply_once(
		legacy_path,
		marker_path,
		"ever_deeper_save_epoch=2\n"
	)


func persistence_enabled() -> bool:
	return _persistence_enabled


func persistence_path() -> String:
	return _save_path


func current_pickaxe() -> Dictionary:
	var pickaxes: Array = Array(_game_data().PICKAXES)
	var safe_level: = clampi(pickaxe_level, 1, pickaxes.size() - 1)
	var result: Dictionary = Dictionary(pickaxes[safe_level]).duplicate(true)
	if safe_level == pickaxes.size() - 1:
		var mastery_rows: Array = Array(_game_data().EMBER_MASTERY)
		var mastery: Dictionary = Dictionary(mastery_rows[clampi(ember_mastery, 0, mastery_rows.size() - 1)])
		result["power"] = int(mastery.power)
		result["cooldown"] = float(mastery.cooldown)
		result["name"] = "%s +%d" % [String(result.name), ember_mastery] if ember_mastery > 0 else String(result.name)
	return result


func next_pickaxe() -> Dictionary:
	var pickaxes: Array = Array(_game_data().PICKAXES)
	var next_level: = pickaxe_level + 1
	if next_level >= pickaxes.size():
		return {}
	return Dictionary(pickaxes[next_level])


func next_ember_mastery() -> Dictionary:
	var mastery_rows: Array = Array(_game_data().EMBER_MASTERY)
	if pickaxe_level < Array(_game_data().PICKAXES).size() - 1 or ember_mastery >= mastery_rows.size() - 1:
		return {}
	return Dictionary(mastery_rows[ember_mastery + 1])


func add_resource(kind: String, amount: int = 1, count_as_mined: bool = true) -> void :
	if amount <= 0:
		return
	if not cargo.has(kind):
		cargo[kind] = 0
	cargo[kind] = int(cargo.get(kind, 0)) + amount
	if count_as_mined:
		if not mined.has(kind):
			mined[kind] = 0
		mined[kind] = int(mined.get(kind, 0)) + amount
		if kind in RESOURCE_IDS:
			overhaul_progress["companion_xp"] = mini(10000000, int(overhaul_progress.get("companion_xp",0)) + amount)
	_state_changed()
	resource_collected.emit(kind, amount)


func record_mined(kind: String, amount: int = 1) -> bool:
	if amount <= 0 or kind not in RESOURCE_IDS:
		return false
	mined[kind] = int(mined.get(kind, 0)) + amount
	# Earn through mining even when the hero reaches the drop before the mole.
	overhaul_progress["companion_xp"] = mini(10000000, int(overhaul_progress.get("companion_xp",0)) + amount)
	_state_changed()
	return true


func record_mining_swing(precision: bool = true) -> void :
	total_swings += 1
	if precision:
		precision_hits += 1



	if total_swings % 10 == 0:
		_state_changed()


func assay_sale_snapshot() -> Dictionary:
	var rows: Array = []
	var sellable_pieces: = 0
	var protected_pieces: = 0
	var sale_total: = 0
	var rock_types: Dictionary = Dictionary(_game_data().ROCK_TYPES)
	var protected: = _protected_progress_cargo()
	var resource_order: Array = RESOURCE_IDS.duplicate()
	for kind_value in cargo:
		var extra_kind: = String(kind_value)
		if not resource_order.has(extra_kind):
			resource_order.append(extra_kind)
	for kind_value in resource_order:
		var kind: = String(kind_value)
		var carried: = maxi(0, int(cargo.get(kind, 0)))
		if carried <= 0:
			continue
		var protected_amount: = mini(carried, maxi(0, int(protected.get(kind, 0))))
		if kind in ENDLESS_RESOURCE_IDS:
			protected_amount = carried
		var sellable: = maxi(0, carried - protected_amount)
		var rock: Dictionary = Dictionary(rock_types.get(kind, {}))
		var unit_value: = maxi(0, int(rock.get("value", 0)))
		var row_total: = sellable * unit_value
		var texture_path: = _resource_drop_texture_path(kind)
		rows.append({
			"kind": kind,
			"name": String(rock.get("label", kind.capitalize())),
			"texture_path": texture_path,
			"texture_name": texture_path.get_file() if not texture_path.is_empty() else "",
			"carried": carried,
			"amount": sellable,
			"sellable": sellable,
			"protected": protected_amount,
			"unit_value": unit_value,
			"total": row_total,
		})
		sellable_pieces += sellable
		protected_pieces += protected_amount
		sale_total += row_total
	var can_sell: = sellable_pieces > 0
	var reason: = "ready" if can_sell else "protected" if not rows.is_empty() else "empty"
	return {
		"transaction_kind": "assay_sale",
		"rows": rows,
		"sellable_pieces": sellable_pieces,
		"protected_pieces": protected_pieces,
		"total": sale_total,
		"gold_before": gold,
		"gold_after": gold + sale_total,
		"can_sell": can_sell,
		"reason": reason,
	}


func begin_assay_sale() -> Dictionary:
	var existing: = _pending_commerce_transaction(_active_assay_transaction_id, "assay_sale")
	if not existing.is_empty():
		return _commerce_begin_result(existing, true)
	var snapshot: = assay_sale_snapshot()
	if not bool(snapshot.get("can_sell", false)):
		var unavailable: = snapshot.duplicate(true)
		unavailable["ok"] = false
		unavailable["transaction_id"] = ""
		unavailable["state"] = "unavailable"
		unavailable["reused"] = false
		return unavailable
	var transaction: = _create_commerce_transaction("assay_sale", snapshot)
	_active_assay_transaction_id = String(transaction.id)
	return _commerce_begin_result(transaction, false)


func commit_assay_sale(transaction_id: String) -> Dictionary:
	var transaction: Dictionary = _commerce_transactions.get(transaction_id, {})
	if not transaction is Dictionary or Dictionary(transaction).is_empty():
		return _commerce_error(transaction_id, "unknown_transaction")
	transaction = Dictionary(transaction)
	if String(transaction.get("kind", "")) != "assay_sale":
		return _commerce_error(transaction_id, "wrong_transaction_kind")
	if String(transaction.get("state", "")) == "committed":
		return _commerce_commit_result(transaction, true)
	if String(transaction.get("state", "")) != "pending":
		return _commerce_error(transaction_id, String(transaction.get("reason", "cancelled")))
	var snapshot: Dictionary = Dictionary(transaction.get("snapshot", {}))
	var rows: Array = Array(snapshot.get("rows", []))
	var current_protected: = _protected_progress_cargo()
	for row_value in rows:
		var row: Dictionary = Dictionary(row_value)
		var amount: = maxi(0, int(row.get("sellable", row.get("amount", 0))))
		if amount <= 0:
			continue
		var kind: = String(row.get("kind", ""))
		var carried: = maxi(0, int(cargo.get(kind, 0)))
		var protected_amount: = mini(carried, maxi(0, int(current_protected.get(kind, 0))))
		if kind in ENDLESS_RESOURCE_IDS or carried - protected_amount < amount:
			_cancel_commerce_transaction(transaction_id, "stale_sale")
			return _commerce_error(transaction_id, "stale_sale")
	for row_value in rows:
		var row: Dictionary = Dictionary(row_value)
		var amount: = maxi(0, int(row.get("sellable", row.get("amount", 0))))
		if amount > 0:
			var kind: = String(row.get("kind", ""))
			cargo[kind] = int(cargo.get(kind, 0)) - amount
	var earned: = maxi(0, int(snapshot.get("total", 0)))
	var gold_before_commit: = gold
	gold += earned
	total_gold_earned += earned
	transaction["state"] = "committed"
	transaction["result"] = {
		"earned": earned,
		"rows": rows.duplicate(true),
		"gold_before_commit": gold_before_commit,
		"gold_after_commit": gold,
	}
	_commerce_transactions[transaction_id] = transaction
	if _active_assay_transaction_id == transaction_id:
		_active_assay_transaction_id = ""


	_state_changed()
	return _commerce_commit_result(transaction, false)


func cancel_assay_sale(transaction_id: String) -> bool:
	return _cancel_pending_commerce_transaction(transaction_id, "assay_sale", "cancelled")


func sell_all() -> int:
	var begun: = begin_assay_sale()
	if not bool(begun.get("ok", false)):


		_state_changed()
		return 0
	var committed: = commit_assay_sale(String(begun.get("transaction_id", "")))
	return int(committed.get("earned", 0)) if bool(committed.get("ok", false)) else 0


func forge_purchase_snapshot(purchase_kind: String = "") -> Dictionary:
	return _forge_purchase_snapshot_for_kind(purchase_kind)


func begin_forge_purchase(purchase_kind: String = "") -> Dictionary:
	var existing: = _pending_commerce_transaction(_active_forge_transaction_id, "forge_purchase")
	if not existing.is_empty():
		var existing_snapshot: Dictionary = Dictionary(existing.get("snapshot", {}))
		if purchase_kind.is_empty() or String(existing_snapshot.get("purchase_kind", "")) == purchase_kind:
			return _commerce_begin_result(existing, true)
		return _commerce_error(String(existing.get("id", "")), "transaction_pending")
	var snapshot: = _forge_purchase_snapshot_for_kind(purchase_kind)
	if not bool(snapshot.get("ready", false)):
		var unavailable: = snapshot.duplicate(true)
		unavailable["ok"] = false
		unavailable["transaction_id"] = ""
		unavailable["state"] = "unavailable"
		unavailable["reused"] = false
		return unavailable
	var transaction: = _create_commerce_transaction("forge_purchase", snapshot)
	_active_forge_transaction_id = String(transaction.id)
	return _commerce_begin_result(transaction, false)


func commit_forge_purchase(transaction_id: String) -> Dictionary:
	var transaction: Dictionary = _commerce_transactions.get(transaction_id, {})
	if not transaction is Dictionary or Dictionary(transaction).is_empty():
		return _commerce_error(transaction_id, "unknown_transaction")
	transaction = Dictionary(transaction)
	if String(transaction.get("kind", "")) != "forge_purchase":
		return _commerce_error(transaction_id, "wrong_transaction_kind")
	if String(transaction.get("state", "")) == "committed":
		return _commerce_commit_result(transaction, true)
	if String(transaction.get("state", "")) != "pending":
		return _commerce_error(transaction_id, String(transaction.get("reason", "cancelled")))
	var snapshot: Dictionary = Dictionary(transaction.get("snapshot", {}))
	var purchase_kind: = String(snapshot.get("purchase_kind", ""))
	if purchase_kind not in ["pickaxe", "ember_mastery"]:
		_cancel_commerce_transaction(transaction_id, "invalid_purchase_kind")
		return _commerce_error(transaction_id, "invalid_purchase_kind")
	if (
		int(snapshot.get("pickaxe_level_before", -1)) != pickaxe_level
		or int(snapshot.get("ember_mastery_before", -1)) != ember_mastery
	):
		_cancel_commerce_transaction(transaction_id, "stale_forge")
		return _commerce_error(transaction_id, "stale_forge")
	var current: = _forge_purchase_snapshot_for_kind(purchase_kind)
	if (
		not bool(current.get("ready", false))
		or int(current.get("target_level", -1)) != int(snapshot.get("target_level", -1))
		or int(current.get("target_rank", -1)) != int(snapshot.get("target_rank", -1))
	):
		_cancel_commerce_transaction(transaction_id, "requirements_changed")
		return _commerce_error(transaction_id, "requirements_changed")
	var cost: Dictionary = Dictionary(snapshot.get("cost", {}))
	var gold_cost: = maxi(0, int(Dictionary(cost.get("gold", {})).get("required", 0)))
	var resource_costs: Array = Array(cost.get("resources", []))
	if gold < gold_cost:
		_cancel_commerce_transaction(transaction_id, "requirements_changed")
		return _commerce_error(transaction_id, "requirements_changed")
	for requirement_value in resource_costs:
		var requirement: Dictionary = Dictionary(requirement_value)
		if int(cargo.get(String(requirement.get("kind", "")), 0)) < int(requirement.get("required", 0)):
			_cancel_commerce_transaction(transaction_id, "requirements_changed")
			return _commerce_error(transaction_id, "requirements_changed")
	var gold_before_commit: = gold
	gold -= gold_cost
	for requirement_value in resource_costs:
		var requirement: Dictionary = Dictionary(requirement_value)
		var kind: = String(requirement.get("kind", ""))
		cargo[kind] = int(cargo.get(kind, 0)) - int(requirement.get("required", 0))
	if purchase_kind == "pickaxe":
		pickaxe_level = int(snapshot.get("target_level", pickaxe_level + 1))
	else:
		ember_mastery = int(snapshot.get("target_rank", ember_mastery + 1))
	transaction["state"] = "committed"
	transaction["result"] = {
		"purchase_kind": purchase_kind,
		"purchased": Dictionary(snapshot.get("next", {})).duplicate(true),
		"gold_spent": gold_cost,
		"resources_spent": resource_costs.duplicate(true),
		"gold_before_commit": gold_before_commit,
		"gold_after_commit": gold,
		"pickaxe_level": pickaxe_level,
		"ember_mastery": ember_mastery,
	}
	_commerce_transactions[transaction_id] = transaction
	if _active_forge_transaction_id == transaction_id:
		_active_forge_transaction_id = ""
	_state_changed()
	return _commerce_commit_result(transaction, false)


func cancel_forge_purchase(transaction_id: String) -> bool:
	return _cancel_pending_commerce_transaction(transaction_id, "forge_purchase", "cancelled")


func upgrade_pickaxe() -> bool:
	var begun: = begin_forge_purchase("pickaxe")
	if not bool(begun.get("ok", false)):
		return false
	return bool(commit_forge_purchase(String(begun.get("transaction_id", ""))).get("ok", false))


func upgrade_ember_mastery() -> bool:
	var begun: = begin_forge_purchase("ember_mastery")
	if not bool(begun.get("ok", false)):
		return false
	return bool(commit_forge_purchase(String(begun.get("transaction_id", ""))).get("ok", false))


func has_deep_tool() -> bool:
	return drill_level > 0 or not starforge_variant.is_empty()


func set_starforge_variant(variant_id: String, unlock: bool = true) -> bool:
	if variant_id.is_empty():
		if starforge_variant.is_empty():
			return false
		starforge_variant = ""
		_state_changed()
		return true
	if not STARFORGE_VARIANT_IDS.has(variant_id):
		return false
	if not unlock and not bool(starforge_unlocked.get(variant_id, false)):
		return false
	var did_change: = false
	if unlock and not bool(starforge_unlocked.get(variant_id, false)):
		starforge_unlocked[variant_id] = true
		did_change = true
	if starforge_variant != variant_id:
		starforge_variant = variant_id
		did_change = true
	if unlock and _unlock_hub_early_without_emit():
		did_change = true
	if did_change:
		_state_changed()
	return did_change


func starforge_crafting_status(variant_id: String) -> Dictionary:
	return _moss_rules().starforge_crafting_status(
		variant_id,
		cargo,
		bool(starforge_unlocked.get(variant_id, false)),
		drill_level,
		fourth_unlocked
	)


func can_forge_starforge_variant(variant_id: String) -> bool:
	return bool(starforge_crafting_status(variant_id).get("ready", false))


func forge_starforge_variant(variant_id: String) -> bool:
	var status: = starforge_crafting_status(variant_id)
	if not bool(status.get("ready", false)):
		return false
	var variant: Dictionary = status.variant
	for resource_id in Dictionary(variant.cost):
		cargo[resource_id] = int(cargo.get(resource_id, 0)) - int(variant.cost[resource_id])
	starforge_unlocked[variant_id] = true
	starforge_variant = variant_id
	_unlock_hub_early_without_emit()
	_state_changed()
	return true


func equip_starforge_variant(variant_id: String) -> bool:
	if not STARFORGE_VARIANT_IDS.has(variant_id):
		return false
	if not bool(starforge_unlocked.get(variant_id, false)) or starforge_variant == variant_id:
		return false
	starforge_variant = variant_id
	_state_changed()
	return true


func current_drill() -> Dictionary:
	var result: Dictionary = _moss_rules().current_drill(drill_level)
	if not result.is_empty():
		result["level"] = drill_level
	return result


func resource_pickup_radius(base_radius: float = 48.0, resource_id: String = "") -> float:
	if resource_id == "singularity":
		return maxf(0.0, base_radius)
	var safe_level: = clampi(drill_level, 0, Array(_game_data().DRILLS).size() - 1)
	return maxf(0.0, base_radius) + float(safe_level) * DRILL_PICKUP_RADIUS_STEP


func attune_tool_with_starforge(tool: Dictionary) -> Dictionary:
	var result: = tool.duplicate(true)
	var variant_id: = String(starforge_variant)
	if not variant_id.is_empty() and Dictionary(_game_data().STARFORGE_VARIANTS).has(variant_id):
		var variant: Dictionary = Dictionary(_game_data().STARFORGE_VARIANTS[variant_id])
		result["name"] = String(variant.get("name", result.get("name", "Tool")))
		result["power"] = roundi(
			float(result.get("power", 1)) * float(variant.get("powerMultiplier", 1.0))
		)
		result["cooldown"] = (
			float(result.get("cooldown", 0.72))
			* float(variant.get("cooldownMultiplier", 1.0))
		)
		if result.has("shell_power") or result.has("shellPower"):
			result["shell_power"] = (
				float(result.get("shell_power", result.get("shellPower", 1.0)))
				* float(variant.get("shellMultiplier", 1.0))
			)
		result["yield_bonus"] = minf(
			0.92,
			float(result.get("yield_bonus", result.get("yieldBonus", 0.0)))
			+ float(variant.get("yieldBonus", 0.0))
		)
		result["yield_multiplier"] = (
			maxi(1, int(result.get("yield_multiplier", result.get("yieldMultiplier", 1))))
			* maxi(1, int(variant.get("yieldMultiplier", 1)))
		)
		result["starforge_variant"] = variant_id
	return apply_tool_forge_effects(result)


func apply_tool_forge_effects(tool: Dictionary, minimum_cooldown: float = 0.02) -> Dictionary:
	var result: = tool.duplicate(true)
	var power_multiplier: = endless_tool_power_multiplier()
	var speed_multiplier: = endless_tool_speed_multiplier()
	var range_multiplier: = endless_tool_range_multiplier()
	result["power"] = maxi(1, roundi(float(result.get("power", 1)) * power_multiplier))
	if result.has("shell_power") or result.has("shellPower"):
		result["shell_power"] = maxf(
			0.01,
			float(result.get("shell_power", result.get("shellPower", 1.0))) * power_multiplier
		)
	result["cooldown"] = maxf(
		maxf(0.01, minimum_cooldown),
		float(result.get("cooldown", 0.72)) / speed_multiplier
	)
	result["range_multiplier"] = (
		float(result.get("range_multiplier", 1.0)) * range_multiplier
	)
	result["endless_tool_style"] = endless_tool_style
	return result


func endless_tool_power_multiplier() -> float:
	return 1.0 + 0.04 * float(_built_workshop_level("tool_forge"))


func endless_tool_speed_multiplier() -> float:
	return 1.0 + 0.025 * float(_built_workshop_level("tool_forge"))


func endless_tool_range_multiplier() -> float:
	return 1.0 + 0.03 * float(_built_workshop_level("tool_forge"))


func endless_light_range_multiplier() -> float:
	return light_range_for_level(_built_workshop_level("light_lab"))


func endless_light_energy_multiplier() -> float:
	return light_energy_for_level(_built_workshop_level("light_lab"))


func next_drill() -> Dictionary:
	var result: Dictionary = _moss_rules().next_drill(drill_level)
	if not result.is_empty():
		result["level"] = drill_level + 1
	return result


func next_drill_recipe() -> Dictionary:
	return _moss_rules().next_drill_recipe(drill_level)


func drill_upgrade_status() -> Dictionary:
	return _moss_rules().drill_upgrade_status(
		drill_level,
		gold,
		cargo,
		not starforge_variant.is_empty()
	)


func upgrade_drill() -> bool:
	var status: = drill_upgrade_status()
	if not bool(status.get("ready", false)):
		return false
	var recipe: Dictionary = status.recipe
	gold -= int(recipe.gold)
	for requirement_value in Array(recipe.requirements):
		var requirement: Dictionary = requirement_value
		var resource_id: = String(requirement.type)
		cargo[resource_id] = int(cargo.get(resource_id, 0)) - int(requirement.amount)
	drill_level = int(recipe.level)
	_state_changed()
	return true


func set_drill_level(level: int) -> void :
	var maximum: int = maxi(0, Array(_game_data().DRILLS).size() - 1)
	var normalized: int = clampi(level, 0, maximum)
	if drill_level == normalized:
		return
	drill_level = normalized
	if drill_level > 0:
		_unlock_hub_early_without_emit()
	_state_changed()


func rootwound_resource_profile() -> Dictionary:
	return depth_resource_profile("mossMine")


func depth_resource_profile(mine_id: String) -> Dictionary:
	return _moss_rules().depth_profile(mine_id)


func depth_resource_access(mine_id: String, resource_id: String) -> Dictionary:
	return _moss_rules().depth_resource_access(
		mine_id,
		resource_id,
		pickaxe_level,
		has_deep_tool(),
		drill_level
	)


func can_mine_depth_resource(mine_id: String, resource_id: String) -> bool:
	return bool(depth_resource_access(mine_id, resource_id).get("can_mine", false))


func set_ember_mastery(rank: int) -> void :
	var maximum: int = maxi(0, Array(_game_data().EMBER_MASTERY).size() - 1)
	var normalized: = clampi(rank, 0, maximum)
	if pickaxe_level < Array(_game_data().PICKAXES).size() - 1:
		normalized = 0
	if ember_mastery == normalized:
		return
	ember_mastery = normalized
	_state_changed()


func _protected_progress_cargo() -> Dictionary:
	var protected: Dictionary = _moss_rules().protected_drill_cargo(drill_level, cargo)
	if pickaxe_level == Array(_game_data().PICKAXES).size() - 2:
		var emberstone_required: = int(_game_data().EMBER_PICKAXE_ORE_REQUIRED)
		protected["emberstone"] = maxi(
			int(protected.get("emberstone", 0)),
			mini(emberstone_required, int(cargo.get("emberstone", 0)))
		)
	var mastery: = next_ember_mastery()
	if not mastery.is_empty():
		protected["sunslag"] = maxi(
			int(protected.get("sunslag", 0)),
			mini(int(mastery.sunslag), int(cargo.get("sunslag", 0)))
		)



	var drill_route_active: = ( not drill_goal_scene.is_empty() or drill_level > 0) and ( not starforge_variant.is_empty() or drill_level > 0)
	if fourth_unlocked and not drill_route_active:
		for variant_id in STARFORGE_VARIANT_IDS:
			if bool(starforge_unlocked.get(variant_id, false)):
				continue
			var variant: Dictionary = _moss_rules().starforge_variant(String(variant_id))
			for resource_id in Dictionary(variant.cost):
				protected[resource_id] = maxi(
					int(protected.get(resource_id, 0)),
					mini(int(variant.cost[resource_id]), int(cargo.get(resource_id, 0)))
				)
			break



	if is_hub_unlocked() and not deep_elevator_repaired:
		for resource_value in DEEP_ELEVATOR_RECIPE:
			var resource_id: = String(resource_value)
			var missing: = maxi(
				0,
				int(DEEP_ELEVATOR_RECIPE[resource_id])
				- int(deep_elevator_deliveries.get(resource_id, 0))
			)
			protected[resource_id] = maxi(
				int(protected.get(resource_id, 0)),
				mini(missing, int(cargo.get(resource_id, 0)))
			)
	for workshop_id_value in ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var status: = workshop_status(workshop_id)
		if not bool(status.get("blueprint_unlocked", false)) or bool(status.get("built", false)):
			continue
		var resource_id: = String(status.get("build_resource", ""))
		var remaining: = maxi(0, int(status.get("remaining", 0)))
		if resource_id.is_empty() or remaining <= 0:
			continue
		protected[resource_id] = maxi(
			int(protected.get(resource_id, 0)),
			mini(remaining, int(cargo.get(resource_id, 0)))
		)
	return protected


func protected_progress_cargo() -> Dictionary:
	return _protected_progress_cargo().duplicate(true)


func deep_elevator_deliverable_amount(resource_id: String) -> int:
	if not DEEP_ELEVATOR_RECIPE.has(resource_id):
		return 0
	var carried: = maxi(0, int(cargo.get(resource_id, 0)))
	var drill_reserve: Dictionary = _moss_rules().protected_drill_cargo(
		drill_level, cargo
	)
	return maxi(0, carried - int(drill_reserve.get(resource_id, 0)))


func singularity_extraction_status(resource_id: String) -> Dictionary:
	if singularity_secured:
		return {"ready": false, "reason": "already_secured", "secured": true}
	if resource_id != "singularity":
		return {"ready": false, "reason": "wrong_resource", "secured": false}
	if current_scene != "starMine" or current_depth != 2:
		return {"ready": false, "reason": "wrong_location", "secured": false}
	var maximum_drill_level: = maxi(0, Array(_game_data().DRILLS).size() - 1)
	if drill_level != maximum_drill_level:
		return {"ready": false, "reason": "deepcore_required", "secured": false}
	if int(mined.get("singularity", 0)) <= 0:
		return {"ready": false, "reason": "resource_not_recorded", "secured": false}
	return {
		"ready": true,
		"reason": "ready",
		"secured": false,
		"resource": "singularity",
		"scene": "starMine",
		"depth": 2,
	}


func victory_completion_status(resource_id: String) -> Dictionary:


	return singularity_extraction_status(resource_id)


func secure_singularity(resource_id: String = "singularity") -> bool:
	var status: = singularity_extraction_status(resource_id)
	if not bool(status.get("ready", false)):
		return false
	singularity_secured = true
	_unlock_hub_early_without_emit()
	_state_changed()
	return true


func complete_victory(resource_id: String) -> bool:



	return secure_singularity(resource_id)


func deep_elevator_recipe() -> Dictionary:
	return DEEP_ELEVATOR_RECIPE.duplicate(true)


func deep_elevator_status() -> Dictionary:
	var missing: = {}
	for resource_value in DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_value)
		var required: = int(DEEP_ELEVATOR_RECIPE[resource_id])
		var delivered: = int(deep_elevator_deliveries.get(resource_id, 0))
		if delivered < required:
			missing[resource_id] = required - delivered
	return {
		"hub_unlocked": is_hub_unlocked(),
		"singularity_secured": singularity_secured,
		"deliveries": deep_elevator_deliveries.duplicate(true),
		"recipe": deep_elevator_recipe(),
		"missing": missing,
		"repaired": deep_elevator_repaired,
		"powered": deep_elevator_powered,
		"final_expedition_begun": final_expedition_begun,
		"deepheart_seals": deepheart_seals.duplicate(true),
		"victory": victory,
		"ready_to_power": deep_elevator_repaired and singularity_secured and not deep_elevator_powered,
		"ready_to_begin": deep_elevator_powered and not final_expedition_begun and not victory,
		"ready_to_enter": can_enter_final_expedition(),
	}


func deliver_deep_elevator_material(resource_id: String, amount: int) -> Dictionary:
	if not DEEP_ELEVATOR_RECIPE.has(resource_id) or amount <= 0:
		return {"ok": false, "reason": "invalid_resource", "delivered": 0}
	if resource_id == "singularity" and not singularity_secured:
		return {"ok": false, "reason": "singularity_not_secured", "delivered": 0}
	var required: = int(DEEP_ELEVATOR_RECIPE[resource_id])
	var committed: = int(deep_elevator_deliveries.get(resource_id, 0))
	var accepted: = mini(mini(amount, int(cargo.get(resource_id, 0))), maxi(0, required - committed))
	if accepted <= 0:
		return {
			"ok": false,
			"reason": "complete" if committed >= required else "cargo_missing",
			"delivered": 0,
		}
	cargo[resource_id] = int(cargo.get(resource_id, 0)) - accepted
	_commit_deep_elevator_material_without_emit(resource_id, accepted)
	_state_changed()
	return {
		"ok": true,
		"reason": "repaired" if deep_elevator_repaired else "delivered",
		"delivered": accepted,
		"remaining": maxi(0, required - int(deep_elevator_deliveries.get(resource_id, 0))),
		"repaired": deep_elevator_repaired,
	}


func power_deep_elevator() -> bool:
	if deep_elevator_powered or not deep_elevator_repaired or not singularity_secured:
		return false
	deep_elevator_powered = true
	_state_changed()
	return true


func begin_final_expedition() -> bool:
	if victory or final_expedition_begun or not deep_elevator_powered:
		return false
	final_expedition_begun = true
	_state_changed()
	return true


func can_enter_final_expedition() -> bool:


	return deep_elevator_powered and not victory


func deepheart_seal_status() -> Dictionary:
	var missing: Array[String] = []
	var opened: = 0
	for seal_value in DEEPHEART_SEAL_IDS:
		var seal_id: = String(seal_value)
		if bool(deepheart_seals.get(seal_id, false)):
			opened += 1
		else:
			missing.append(seal_id)
	return {
		"begun": final_expedition_begun,
		"seals": deepheart_seals.duplicate(true),
		"opened": opened,
		"total": DEEPHEART_SEAL_IDS.size(),
		"missing": missing,
		"all_open": missing.is_empty(),
	}


func open_deepheart_seal(seal_id: String) -> bool:
	if (
		seal_id not in DEEPHEART_SEAL_IDS
		or not deep_elevator_powered
		or not final_expedition_begun
		or bool(deepheart_seals.get(seal_id, false))
	):
		return false
	deepheart_seals[seal_id] = true
	_state_changed()
	return true


func all_deepheart_seals_open() -> bool:
	return bool(deepheart_seal_status().all_open)


func total_mined_resources() -> int:
	var total: = 0
	for amount_value in mined.values():
		total += maxi(0, int(amount_value))
	return total


func endless_resource_ids() -> Array:
	return ENDLESS_RESOURCE_IDS.duplicate()


func collect_endless_resource(resource_id: String, amount: int = 1) -> bool:
	if (
		not victory
		or not endless_descent_active
		or endless_current_depth <= 0
		or resource_id not in ENDLESS_RESOURCE_IDS
		or amount <= 0
		or amount > MAX_MINE_LOOSE_DROP_AMOUNT
	):
		return false
	add_resource(resource_id, amount, true)
	return true


func endless_floor_resource_state(depth: int) -> Dictionary:
	var bounded_depth: = clampi(depth, 0, ENDLESS_MAX_SAVED_DEPTH)
	var exhausted: = bounded_depth > 0 and bounded_depth <= endless_resource_exhausted_through
	var mined_mask: = (
		endless_active_floor_mined_mask
		if bounded_depth == endless_active_floor_depth and not exhausted
		else 0
	)
	return {
		"depth": bounded_depth,
		"exhausted": exhausted,
		"mined_mask": mined_mask,
		"exhausted_through": endless_resource_exhausted_through,
	}


func mark_endless_resource_node_mined(depth: int, node_index: int) -> bool:
	if (
		not victory
		or not endless_descent_active
		or depth <= 0
		or depth != endless_current_depth
		or depth <= endless_resource_exhausted_through
		or node_index < 0
		or node_index >= 31
	):
		return false
	if endless_active_floor_depth != depth:
		endless_active_floor_depth = depth
		endless_active_floor_mined_mask = 0
	var bit: = 1 << node_index
	if (endless_active_floor_mined_mask & bit) != 0:
		return true
	endless_active_floor_mined_mask |= bit
	_state_changed()
	return true


func endless_floor_site_state(depth: int, site_index: int = -1) -> Dictionary:
	var bounded_depth: = clampi(depth, 0, ENDLESS_MAX_SAVED_DEPTH)
	var exhausted: = bounded_depth > 0 and bounded_depth <= endless_resource_exhausted_through
	var mask: = (
		endless_active_floor_site_mask
		if bounded_depth == endless_active_floor_depth and not exhausted
		else 0
	)
	var resolved: = false
	var choice: = ""
	if site_index >= 0 and site_index < ENDLESS_SITE_LIMIT:
		resolved = exhausted or (mask & (1 << site_index)) != 0
		if resolved:
			choice = (
				"overload"
				if (mask & (1 << (site_index + ENDLESS_SITE_OVERLOAD_SHIFT))) != 0
				else "stabilize"
			)
	return {
		"depth": bounded_depth,
		"site_index": site_index,
		"exhausted": exhausted,
		"mask": mask,
		"resolved": resolved,
		"choice": choice,
	}


func claim_endless_site_cache(
	depth: int,
	site_index: int,
	choice: String,
	resource_id: String,
	base_amount: int
) -> Dictionary:
	if (
		not victory
		or not endless_descent_active
		or depth <= 0
		or depth != endless_current_depth
		or depth <= endless_resource_exhausted_through
		or site_index < 0
		or site_index >= ENDLESS_SITE_LIMIT
		or choice not in ["stabilize", "overload"]
		or resource_id not in ENDLESS_RESOURCE_IDS
		or base_amount <= 0
		or base_amount > 120
	):
		return {"ok": false, "reason": "invalid_site_cache"}
	if endless_active_floor_depth != depth:
		endless_active_floor_depth = depth
		endless_active_floor_mined_mask = 0
		endless_active_floor_site_mask = 0
	var resolved_bit: = 1 << site_index
	if (endless_active_floor_site_mask & resolved_bit) != 0:
		return {"ok": false, "reason": "already_claimed"}
	endless_active_floor_site_mask |= resolved_bit
	if choice == "overload":
		endless_active_floor_site_mask |= 1 << (site_index + ENDLESS_SITE_OVERLOAD_SHIFT)
	var reward_multiplier: = 2.0 if choice == "overload" else 1.0
	var chamber_built: = _built_workshop_level("treasure_chamber") > 0
	if chamber_built:
		reward_multiplier *= 1.25
	var amount: = maxi(1, roundi(float(base_amount) * reward_multiplier))
	add_resource(resource_id, amount, true)
	return {
		"ok": true,
		"reason": "cache_recovered",
		"depth": depth,
		"site_index": site_index,
		"choice": choice,
		"resource": resource_id,
		"amount": amount,
		"treasure_chamber_bonus": chamber_built,
	}


func endless_descent_status() -> Dictionary:
	var discovered_count: = 0
	var placed_count: = 0
	for relic_id_value in ENDLESS_RELIC_IDS:
		var relic: Dictionary = Dictionary(endless_relics.get(
			String(relic_id_value), _default_endless_relic_state()
		))
		if bool(relic.get("discovered", false)):
			discovered_count += 1
		if bool(relic.get("placed", false)):
			placed_count += 1
	var built_count: = 0
	for workshop_id_value in ENDLESS_WORKSHOP_IDS:
		if bool(Dictionary(endless_workshops.get(
			String(workshop_id_value), _default_endless_workshop_state()
		)).get("built", false)):
			built_count += 1
	var carried_id: = String(carried_relic.get("id", ""))
	return {
		"unlocked": victory,
		"active": victory and endless_descent_active,
		"current_depth": endless_current_depth if victory else 0,
		"deepest_depth": endless_deepest_depth if victory else 0,
		"start_depth": endless_start_depth_checkpoint if victory else 1,
		"start_depth_checkpoint": endless_start_depth_checkpoint if victory else 1,
		"next_unknown_depth": mini(ENDLESS_MAX_SAVED_DEPTH, endless_deepest_depth + 1) if victory else 1,
		"resource_exhausted_through": endless_resource_exhausted_through if victory else 0,
		"resource_frontier_depth": clampi(endless_resource_exhausted_through + 1, 1, ENDLESS_MAX_SAVED_DEPTH) if victory else 1,
		"active_floor_site_mask": endless_active_floor_site_mask if victory else 0,
		"carried_relic_id": carried_id if victory else "",
		"carried_relic": carried_relic.duplicate(true) if victory else _default_carried_relic(),
		"discovered_relic_count": discovered_count if victory else 0,
		"placed_relic_count": placed_count if victory else 0,
		"total_relics": ENDLESS_RELIC_IDS.size(),
		"built_workshop_count": built_count if victory else 0,
		"total_workshops": ENDLESS_WORKSHOP_IDS.size(),
		"resources": _endless_resource_snapshot() if victory else _empty_endless_resource_snapshot(),
		"museum": true,
		"exploration_complete": false,
	}


func deep_hoard_status() -> Dictionary:
	return endless_descent_status()


func start_endless_descent(depth: int = 0) -> Dictionary:
	if not victory:
		return {"ok": false, "reason": "deepheart_required"}
	if endless_descent_active:
		return {
			"ok": false, "reason": "already_active",
			"depth": endless_current_depth,
		}
	if not String(carried_relic.get("id", "")).is_empty():
		return {"ok": false, "reason": "carried_relic_must_be_placed"}
	var target: = endless_start_depth_checkpoint if depth <= 0 else depth
	if target != endless_start_depth_checkpoint or target > ENDLESS_MAX_SAVED_DEPTH:
		return {
			"ok": false, "reason": "checkpoint_unavailable",
			"available_start_depth": endless_start_depth_checkpoint,
		}
	endless_current_depth = target
	endless_deepest_depth = maxi(endless_deepest_depth, target)
	endless_descent_active = true
	endless_active_floor_depth = target
	endless_active_floor_mined_mask = 0
	endless_active_floor_site_mask = 0
	_state_changed()
	return {
		"ok": true, "reason": "started", "depth": target,
		"deepest_depth": endless_deepest_depth,
	}


func reach_endless_depth(depth: int) -> bool:
	if (
		not victory
		or not endless_descent_active
		or depth < 0
		or depth > ENDLESS_MAX_SAVED_DEPTH
	):
		return false
	if depth == endless_current_depth:
		return true
	if absi(depth - endless_current_depth) != 1 or depth > endless_deepest_depth + 1:
		return false
	var previous_depth: = endless_current_depth
	var carried_id: = String(carried_relic.get("id", ""))
	if not carried_id.is_empty():
		if not bool(carried_relic.get("attached", false)):
			return false
		if depth > int(carried_relic.get("current_depth", endless_current_depth)):
			return false
		carried_relic["current_depth"] = depth
	if previous_depth > 0:
		endless_resource_exhausted_through = maxi(
			endless_resource_exhausted_through, previous_depth
		)
	endless_current_depth = depth
	endless_deepest_depth = maxi(endless_deepest_depth, depth)
	endless_active_floor_depth = depth
	endless_active_floor_mined_mask = 0
	endless_active_floor_site_mask = 0
	_state_changed()
	return true


func checkpoint_endless_depth(depth: int = 0) -> bool:
	if not victory or not endless_descent_active or endless_current_depth <= 0:
		return false
	if _built_workshop_level("lift_workshop") <= 0:
		return false
	var target: = endless_current_depth if depth <= 0 else depth
	if target != endless_current_depth or target < 1 or target > endless_deepest_depth:
		return false
	if endless_start_depth_checkpoint == target:
		return true
	endless_start_depth_checkpoint = target
	_state_changed()
	return true


func leave_endless_descent_to_hub() -> Dictionary:
	if not victory or not endless_descent_active or endless_current_depth != 0:
		return {"ok": false, "reason": "surface_lift_required"}
	var carried_id: = String(carried_relic.get("id", ""))
	if not carried_id.is_empty():
		if not bool(carried_relic.get("attached", false)):
			return {"ok": false, "reason": "relic_rope_required"}
		carried_relic["current_depth"] = 0
	endless_descent_active = false
	_state_changed()
	return {
		"ok": true, "reason": "returned_to_hub",
		"carried_relic_id": carried_id,
	}


func relic_catalog() -> Dictionary:
	return ENDLESS_RELIC_CATALOG.duplicate(true)


func relic_status(relic_id: String) -> Dictionary:
	if relic_id not in ENDLESS_RELIC_IDS:
		return {"valid": false, "id": relic_id}
	var definition: Dictionary = Dictionary(ENDLESS_RELIC_CATALOG[relic_id])
	var state: Dictionary = Dictionary(endless_relics.get(
		relic_id, _default_endless_relic_state()
	))
	var carried: = String(carried_relic.get("id", "")) == relic_id
	return {
		"valid": true,
		"id": relic_id,
		"display_name": String(definition.display_name),
		"discovered": bool(state.get("discovered", false)),
		"collected": bool(state.get("collected", false)),
		"placed": bool(state.get("placed", false)),
		"found_depth": int(state.get("found_depth", 0)),
		"carried": carried,
		"attached": carried and bool(carried_relic.get("attached", false)),
		"current_depth": int(carried_relic.get("current_depth", 0)) if carried else 0,
		"workshop_id": String(definition.workshop_id),
		"blueprint_id": String(definition.blueprint_id),
		"build_resource": String(definition.build_resource),
		"build_cost": int(definition.build_cost),
	}


func discover_endless_relic(relic_id: String, depth: int) -> bool:
	if (
		not victory
		or not endless_descent_active
		or relic_id not in ENDLESS_RELIC_IDS
		or depth < 1
		or depth > ENDLESS_MAX_SAVED_DEPTH
		or depth != endless_current_depth
	):
		return false
	var state: Dictionary = Dictionary(endless_relics.get(
		relic_id, _default_endless_relic_state()
	))
	if bool(state.get("discovered", false)) or bool(state.get("placed", false)):
		return false
	state["discovered"] = true
	state["found_depth"] = depth
	endless_relics[relic_id] = state
	_state_changed()
	return true


func collect_endless_relic(relic_id: String, depth: int = 0) -> Dictionary:
	if not victory or relic_id not in ENDLESS_RELIC_IDS:
		return {"ok": false, "reason": "invalid_relic", "relic_id": relic_id}
	if not String(carried_relic.get("id", "")).is_empty():
		return {"ok": false, "reason": "already_carrying", "relic_id": relic_id}
	var state: Dictionary = Dictionary(endless_relics.get(
		relic_id, _default_endless_relic_state()
	))
	if bool(state.get("placed", false)):
		return {"ok": false, "reason": "already_placed", "relic_id": relic_id}
	if not bool(state.get("discovered", false)):
		return {"ok": false, "reason": "not_discovered", "relic_id": relic_id}
	var target_depth: = endless_current_depth if depth <= 0 else depth
	if (
		target_depth < 1
		or target_depth != endless_current_depth
		or target_depth != int(state.get("found_depth", 0))
	):
		return {"ok": false, "reason": "wrong_depth", "relic_id": relic_id}
	state["collected"] = true
	endless_relics[relic_id] = state
	carried_relic = {
		"id": relic_id,
		"origin_depth": target_depth,
		"current_depth": target_depth,
		"attached": false,
	}
	_state_changed()
	return {
		"ok": true, "reason": "collected", "relic_id": relic_id,
		"depth": target_depth, "rope_required": true,
	}


func attach_carried_relic(relic_id: String = "") -> bool:
	var carried_id: = String(carried_relic.get("id", ""))
	if carried_id.is_empty() or ( not relic_id.is_empty() and relic_id != carried_id):
		return false
	if bool(carried_relic.get("attached", false)):
		return true
	carried_relic["attached"] = true
	_state_changed()
	return true


func detach_carried_relic() -> bool:
	if String(carried_relic.get("id", "")).is_empty() or not bool(carried_relic.get("attached", false)):
		return false
	carried_relic["attached"] = false
	_state_changed()
	return true


func update_carried_relic_transport(depth: int) -> bool:
	if (
		String(carried_relic.get("id", "")).is_empty()
		or not bool(carried_relic.get("attached", false))
		or depth < 0
	):
		return false
	var previous: = int(carried_relic.get("current_depth", 0))
	if depth > previous or previous - depth > 1:
		return false
	if depth > 0 and ( not endless_descent_active or depth != endless_current_depth):
		return false
	if depth == 0 and ( not endless_descent_active or endless_current_depth != 0):
		return false
	carried_relic["current_depth"] = depth
	_state_changed()
	return true


func place_carried_relic() -> Dictionary:
	var relic_id: = String(carried_relic.get("id", ""))
	if relic_id.is_empty():
		return {"ok": false, "reason": "no_carried_relic"}
	if not bool(carried_relic.get("attached", false)):
		return {"ok": false, "reason": "relic_rope_required", "relic_id": relic_id}
	if (
		int(carried_relic.get("current_depth", -1)) != 0
		or endless_descent_active
		or endless_current_depth != 0
		or current_scene != "hub"
	):
		return {"ok": false, "reason": "hub_required", "relic_id": relic_id}
	var state: Dictionary = Dictionary(endless_relics.get(
		relic_id, _default_endless_relic_state()
	))
	state["discovered"] = true
	state["collected"] = true
	state["placed"] = true
	endless_relics[relic_id] = state
	var definition: Dictionary = Dictionary(ENDLESS_RELIC_CATALOG[relic_id])
	carried_relic = _default_carried_relic()
	_state_changed()
	return {
		"ok": true,
		"reason": "placed",
		"relic_id": relic_id,
		"workshop_id": String(definition.workshop_id),
		"blueprint_id": String(definition.blueprint_id),
		"build_resource": String(definition.build_resource),
		"build_cost": int(definition.build_cost),
	}


func workshop_catalog() -> Dictionary:
	var result: = {}
	for relic_id_value in ENDLESS_RELIC_IDS:
		var definition: Dictionary = Dictionary(ENDLESS_RELIC_CATALOG[String(relic_id_value)])
		var workshop_id: = String(definition.workshop_id)
		result[workshop_id] = {
			"id": workshop_id,
			"display_name": String(ENDLESS_WORKSHOP_NAMES[workshop_id]),
			"relic_id": String(relic_id_value),
			"blueprint_id": String(definition.blueprint_id),
			"build_resource": String(definition.build_resource),
			"build_cost": int(definition.build_cost),
		}
	return result


func workshop_status(workshop_id: String) -> Dictionary:
	var relic_id: = _relic_id_for_workshop(workshop_id)
	if relic_id.is_empty():
		return {"valid": false, "id": workshop_id}
	var definition: Dictionary = Dictionary(ENDLESS_RELIC_CATALOG[relic_id])
	var state: Dictionary = Dictionary(endless_workshops.get(
		workshop_id, _default_endless_workshop_state()
	))
	var relic: Dictionary = Dictionary(endless_relics.get(
		relic_id, _default_endless_relic_state()
	))
	var blueprint_unlocked: = bool(relic.get("placed", false))
	var built: = bool(state.get("built", false)) and blueprint_unlocked
	var max_level: = _workshop_max_level(workshop_id)
	var level: = clampi(int(state.get("level", 0)), 1, max_level) if built else 0
	var delivered: = clampi(int(state.get("delivered", 0)), 0, int(definition.build_cost))
	var upgrade: = _workshop_upgrade_recipe(workshop_id, level) if built else {}
	return {
		"valid": true,
		"id": workshop_id,
		"display_name": String(ENDLESS_WORKSHOP_NAMES[workshop_id]),
		"relic_id": relic_id,
		"blueprint_id": String(definition.blueprint_id),
		"blueprint_unlocked": blueprint_unlocked,
		"built": built,
		"level": level,
		"max_level": max_level,
		"style": String(state.get("style", "original")),
		"available_styles": ENDLESS_WORKSHOP_STYLE_IDS.slice(0, level),
		"build_resource": String(definition.build_resource),
		"build_cost": int(definition.build_cost),
		"delivered": delivered,
		"remaining": maxi(0, int(definition.build_cost) - delivered),
		"ready_to_build": blueprint_unlocked and not built and delivered >= int(definition.build_cost),
		"next_upgrade": upgrade,
		"ready_to_upgrade": (
			built
			and not upgrade.is_empty()
			and int(cargo.get(String(upgrade.get("resource", "")), 0)) >= int(upgrade.get("cost", 0))
		),
	}


func deliver_workshop_material(
	workshop_id: String, resource_id: String, amount: int
) -> Dictionary:
	var status: = workshop_status(workshop_id)
	if not bool(status.get("valid", false)) or amount <= 0:
		return {"ok": false, "reason": "invalid_workshop", "accepted": 0}
	if not bool(status.get("blueprint_unlocked", false)):
		return {"ok": false, "reason": "blueprint_locked", "accepted": 0}
	if bool(status.get("built", false)):
		return {"ok": false, "reason": "already_built", "accepted": 0}
	if resource_id != String(status.build_resource):
		return {"ok": false, "reason": "wrong_resource", "accepted": 0}
	var accepted: = mini(
		mini(amount, int(cargo.get(resource_id, 0))), int(status.remaining)
	)
	if accepted <= 0:
		return {"ok": false, "reason": "cargo_missing", "accepted": 0}
	var state: Dictionary = Dictionary(endless_workshops.get(
		workshop_id, _default_endless_workshop_state()
	))
	cargo[resource_id] = int(cargo.get(resource_id, 0)) - accepted
	state["delivered"] = int(state.get("delivered", 0)) + accepted
	endless_workshops[workshop_id] = state
	_state_changed()
	var remaining: = maxi(0, int(status.build_cost) - int(state.delivered))
	return {
		"ok": true,
		"reason": "ready_to_build" if remaining == 0 else "delivered",
		"accepted": accepted,
		"delivered": int(state.delivered),
		"remaining": remaining,
		"ready_to_build": remaining == 0,
	}


func build_workshop(workshop_id: String) -> Dictionary:
	var status: = workshop_status(workshop_id)
	if not bool(status.get("valid", false)):
		return {"ok": false, "reason": "invalid_workshop"}
	if bool(status.get("built", false)):
		return {"ok": false, "reason": "already_built", "workshop_id": workshop_id}
	if not bool(status.get("blueprint_unlocked", false)):
		return {"ok": false, "reason": "blueprint_locked", "workshop_id": workshop_id}
	if not bool(status.get("ready_to_build", false)):
		return {
			"ok": false, "reason": "materials_required",
			"workshop_id": workshop_id, "remaining": int(status.remaining),
		}
	var state: Dictionary = Dictionary(endless_workshops.get(
		workshop_id, _default_endless_workshop_state()
	))
	state["built"] = true
	state["level"] = 1
	state["style"] = "original"
	endless_workshops[workshop_id] = state
	_state_changed()
	return {
		"ok": true, "reason": "built", "workshop_id": workshop_id,
		"level": 1,
	}


func upgrade_workshop(workshop_id: String) -> Dictionary:
	var status: = workshop_status(workshop_id)
	if not bool(status.get("valid", false)):
		return {"ok": false, "reason": "invalid_workshop"}
	if not bool(status.get("built", false)):
		return {"ok": false, "reason": "workshop_not_built", "workshop_id": workshop_id}
	var recipe: Dictionary = Dictionary(status.get("next_upgrade", {}))
	if recipe.is_empty():
		return {"ok": false, "reason": "max_level", "workshop_id": workshop_id}
	var resource_id: = String(recipe.resource)
	var cost: = int(recipe.cost)
	if int(cargo.get(resource_id, 0)) < cost:
		return {
			"ok": false, "reason": "materials_required",
			"workshop_id": workshop_id, "resource": resource_id, "cost": cost,
		}
	var state: Dictionary = Dictionary(endless_workshops[workshop_id])
	cargo[resource_id] = int(cargo.get(resource_id, 0)) - cost
	state["level"] = int(recipe.level)
	endless_workshops[workshop_id] = state
	_state_changed()
	return {
		"ok": true, "reason": "upgraded", "workshop_id": workshop_id,
		"level": int(recipe.level), "resource": resource_id, "cost": cost,
	}


func set_workshop_style(workshop_id: String, style_id: String) -> bool:
	var status: = workshop_status(workshop_id)
	if (
		not bool(status.get("built", false))
		or style_id not in Array(status.get("available_styles", []))
	):
		return false
	var state: Dictionary = Dictionary(endless_workshops[workshop_id])
	if String(state.get("style", "original")) == style_id:
		return true
	state["style"] = style_id
	endless_workshops[workshop_id] = state
	_state_changed()
	return true


func endless_loadout_status() -> Dictionary:
	return {
		"light": endless_light_style,
		"outfit": endless_outfit,
		"tool": endless_tool_style,
		"light_options": _available_selection_options("light_lab", ENDLESS_LIGHT_STYLE_IDS),
		"outfit_options": _available_selection_options("wardrobe", ENDLESS_OUTFIT_IDS),
		"tool_options": _available_selection_options("tool_forge", ENDLESS_TOOL_STYLE_IDS),
	}


func set_endless_light_style(style_id: String) -> bool:
	if style_id not in _available_selection_options("light_lab", ENDLESS_LIGHT_STYLE_IDS):
		return false
	if endless_light_style == style_id:
		return true
	endless_light_style = style_id
	_state_changed()
	return true


func set_endless_outfit(outfit_id: String) -> bool:
	if outfit_id not in _available_selection_options("wardrobe", ENDLESS_OUTFIT_IDS):
		return false
	if endless_outfit == outfit_id:
		return true
	endless_outfit = outfit_id
	_state_changed()
	return true


func set_endless_tool_style(style_id: String) -> bool:
	if style_id not in _available_selection_options("tool_forge", ENDLESS_TOOL_STYLE_IDS):
		return false
	if endless_tool_style == style_id:
		return true
	endless_tool_style = style_id
	_state_changed()
	return true


func final_completion_status() -> Dictionary:
	if victory:
		return {"ready": false, "reason": "already_complete", "completed": true}
	if not singularity_secured:
		return {"ready": false, "reason": "singularity_required", "completed": false}
	if not deep_elevator_repaired:
		return {"ready": false, "reason": "elevator_repair_required", "completed": false}
	if not deep_elevator_powered:
		return {"ready": false, "reason": "elevator_power_required", "completed": false}
	if not final_expedition_begun:
		return {"ready": false, "reason": "final_expedition_not_begun", "completed": false}
	if not all_deepheart_seals_open():
		return {
			"ready": false,
			"reason": "deepheart_seals_required",
			"completed": false,
			"seals": deepheart_seal_status(),
		}
	return {
		"ready": true,
		"reason": "core_attunement_ready",
		"completed": false,
		"seals": deepheart_seal_status(),
	}


func complete_final_expedition() -> bool:
	if not bool(final_completion_status().get("ready", false)):
		return false
	deepheart_awakened_at_mined = total_mined_resources()
	victory = true
	_state_changed()
	return true


func mark_conclusion_seen() -> bool:
	if not victory or conclusion_seen:
		return false
	conclusion_seen = true
	_state_changed()
	return true


func _commit_deep_elevator_material_without_emit(resource_id: String, amount: int) -> int:
	if not DEEP_ELEVATOR_RECIPE.has(resource_id) or amount <= 0:
		return 0
	var required: = int(DEEP_ELEVATOR_RECIPE[resource_id])
	var current: = int(deep_elevator_deliveries.get(resource_id, 0))
	var accepted: = mini(amount, maxi(0, required - current))
	if accepted <= 0:
		return 0
	deep_elevator_deliveries[resource_id] = current + accepted
	deep_elevator_repaired = _deep_elevator_recipe_complete()
	if not deep_elevator_repaired:
		deep_elevator_powered = false
		final_expedition_begun = false
		deepheart_seals = _default_deepheart_seals()
		victory = false
	return accepted


func _deep_elevator_recipe_complete() -> bool:
	for resource_value in DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_value)
		if int(deep_elevator_deliveries.get(resource_id, 0)) < int(DEEP_ELEVATOR_RECIPE[resource_id]):
			return false
	return true


func _unlock_hub_early_without_emit() -> bool:
	var changed_state: = false
	if not hub_unlocked_early:
		hub_unlocked_early = true
		changed_state = true
	if not bool(hub.get("unlocked", false)):
		hub["unlocked"] = true
		changed_state = true
	return changed_state


func hub_contract() -> Dictionary:
	return {
		"world_size": HUB_WORLD_SIZE,
		"grid": {
			"origin": HUB_GRID_ORIGIN,
			"tile_size": HUB_GRID_TILE_SIZE,
			"cols": HUB_GRID_COLS,
			"rows": HUB_GRID_ROWS,
		},
		"stations": {
			"surface_entrance": HUB_SURFACE_ENTRANCE,
			"surface_lift": HUB_SURFACE_LIFT,
		},
		"player_spawn": HUB_PLAYER_SPAWN,
		"module_interact_radius": BASE_MODULE_INTERACT_RADIUS,
		"auto_sort_radius": AUTO_SORT_RADIUS,
		"storage_type_capacity": STORAGE_CHEST_CAPACITY,
		"player_build_clearance": HUB_PLAYER_BUILD_CLEARANCE,
		"costs": {
			"wall": {"resource": "stone", "amount": HUB_WALL_STONE_COST},
			"lamp": {"gold": HUB_LAMP_GOLD_COST},
			"storage": {"gold": storage_chest_cost()},
		},
		"full_refund": true,
		"deep_elevator_online": deep_elevator_powered,
		"deep_elevator_repaired": deep_elevator_repaired,
		"deep_elevator_recipe": deep_elevator_recipe(),
	}


func hub_state_snapshot() -> Dictionary:
	return hub.duplicate(true)


func base_state_snapshot() -> Dictionary:
	return base.duplicate(true)


func hub_economy_snapshot() -> Dictionary:
	return {"gold": gold, "cargo": cargo.duplicate(true)}


func hub_runtime_snapshot() -> Dictionary:
	return {
		"hub": hub_state_snapshot(),
		"base": base_state_snapshot(),
		"economy": hub_economy_snapshot(),
	}


func hub_belt_snapshot() -> Dictionary:
	belt_state = _belt_rules().sanitize_state(belt_state)
	return belt_state.duplicate(true)


func configure_hub_belt_segment(
	col: int,
	row: int,
	direction: String,
	capacity: int = 4
) -> Dictionary:
	if not is_hub_unlocked():
		return {"ok": false, "reason": "hub_locked"}
	var result: Dictionary = _belt_rules().set_segment(
		belt_state, col, row, direction, capacity
	)
	if bool(result.get("ok", false)):
		_state_changed()
	return result


func remove_hub_belt_segment(col: int, row: int) -> Dictionary:
	if not is_hub_unlocked():
		return {"ok": false, "reason": "hub_locked"}
	var result: Dictionary = _belt_rules().remove_segment(belt_state, col, row)
	if bool(result.get("ok", false)):
		_state_changed()
	return result


func configure_hub_belt_endpoint(
	endpoint_id: String,
	kind: String,
	col: int,
	row: int,
	direction: String = "right",
	accepts: Array = [],
	capacity: int = 64
) -> Dictionary:
	if not is_hub_unlocked():
		return {"ok": false, "reason": "hub_locked"}
	var result: Dictionary = _belt_rules().set_endpoint(
		belt_state,
		endpoint_id,
		kind,
		col,
		row,
		direction,
		accepts,
		capacity
	)
	if bool(result.get("ok", false)):
		_state_changed()
	return result


func remove_hub_belt_endpoint(endpoint_id: String) -> Dictionary:
	if not is_hub_unlocked():
		return {"ok": false, "reason": "hub_locked"}
	var result: Dictionary = _belt_rules().remove_endpoint(belt_state, endpoint_id)
	if bool(result.get("ok", false)):
		_state_changed()
	return result


func enqueue_hub_belt_from_cargo(
	source_id: String,
	resource_id: String,
	amount: int
) -> Dictionary:
	if not is_hub_unlocked():
		return {"ok": false, "reason": "hub_locked", "accepted": 0}
	if resource_id not in RESOURCE_IDS or amount <= 0:
		return {"ok": false, "reason": "invalid_resource", "accepted": 0}
	var offered: = mini(amount, int(cargo.get(resource_id, 0)))
	if offered <= 0:
		return {"ok": false, "reason": "cargo_missing", "accepted": 0}
	var result: Dictionary = _belt_rules().enqueue(
		belt_state, source_id, resource_id, offered
	)
	var accepted: = int(result.get("accepted", 0))
	if accepted > 0:
		cargo[resource_id] = int(cargo.get(resource_id, 0)) - accepted
		_state_changed()
	return result


func process_hub_belts(steps: int = 1) -> Dictionary:
	if not is_hub_unlocked():
		return {"ok": false, "reason": "hub_locked", "moved": 0, "delivered": 0}
	var tick_result: Dictionary = _belt_rules().tick(belt_state, steps)
	var committed: = 0
	for resource_value in DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_value)
		var missing: = maxi(
			0,
			int(DEEP_ELEVATOR_RECIPE[resource_id])
			- int(deep_elevator_deliveries.get(resource_id, 0))
		)
		if missing <= 0:
			continue
		if resource_id == "singularity" and not singularity_secured:
			continue
		var taken: int = _belt_rules().take_delivered(
			belt_state, DEEP_ELEVATOR_SINK_ID, resource_id, missing
		)
		committed += _commit_deep_elevator_material_without_emit(resource_id, taken)



	if int(tick_result.get("delivered", 0)) > 0 or committed > 0:
		_state_changed()
	return {
		"ok": true,
		"reason": "processed",
		"steps": int(tick_result.get("steps", 0)),
		"moved": int(tick_result.get("moved", 0)),
		"delivered": int(tick_result.get("delivered", 0)),
		"committed": committed,
		"elevator": deep_elevator_status(),
	}


func hub_belt_delivered_snapshot(sink_id: String = "") -> Dictionary:
	return _belt_rules().delivered_snapshot(belt_state, sink_id)


func take_hub_belt_delivery(sink_id: String, resource_id: String, amount: int) -> int:


	return collect_hub_belt_delivery(sink_id, resource_id, amount)


func collect_hub_belt_delivery(
	sink_id: String,
	resource_id: String,
	amount: int
) -> int:
	if resource_id not in RESOURCE_IDS or amount <= 0:
		return 0
	var taken: int = _belt_rules().take_delivered(
		belt_state, sink_id, resource_id, amount
	)
	if taken > 0:
		cargo[resource_id] = int(cargo.get(resource_id, 0)) + taken
		_state_changed()
	return taken


func is_hub_unlocked() -> bool:
	return hub_unlocked_early or bool(hub.get("unlocked", false))


func hub_tutorial_pending() -> bool:
	return is_hub_unlocked() and not bool(hub.get("tutorialSeen", false))


func mark_hub_tutorial_seen() -> bool:
	if not is_hub_unlocked() or bool(hub.get("tutorialSeen", false)):
		return false
	hub["tutorialSeen"] = true
	_state_changed()
	return true


func mark_hub_build_tutorial_seen() -> bool:
	if not is_hub_unlocked() or bool(hub.get("buildTutorialSeen", false)):
		return false
	hub["buildTutorialSeen"] = true
	_state_changed()
	return true


func hub_surface_return_position() -> Vector2:
	return Vector2(
		float(hub.get("surfaceX", HUB_SURFACE_ENTRANCE.x)),
		float(hub.get("surfaceY", HUB_SURFACE_ENTRANCE.y))
	)


func enter_hub(surface_position: Variant = null) -> bool:
	if not is_hub_unlocked() or current_scene != "surface":
		return false
	var return_position: = current_position
	if surface_position is Vector2 and _valid_vector(surface_position):
		return_position = surface_position
	return_position = _clamp_surface_position(return_position)
	hub["surfaceX"] = return_position.x
	hub["surfaceY"] = return_position.y
	hub["visited"] = true
	last_surface_position = return_position
	current_scene = "hub"
	current_depth = 1
	current_position = HUB_PLAYER_SPAWN
	_state_changed()
	return true


func exit_hub() -> bool:
	if current_scene != "hub":
		return false
	var return_position: = _clamp_surface_position(hub_surface_return_position())
	current_scene = "surface"
	current_depth = 1
	current_position = return_position
	last_surface_position = return_position
	_state_changed()
	return true


func hub_cell_center(col: int, row: int) -> Vector2:
	return HUB_GRID_ORIGIN + (Vector2(col, row) + Vector2(0.5, 0.5)) * HUB_GRID_TILE_SIZE


func hub_cell_at_world(world_position: Vector2) -> Vector2i:
	if not _valid_vector(world_position):
		return Vector2i(-1, -1)
	var cell: = Vector2i(
		floori((world_position.x - HUB_GRID_ORIGIN.x) / HUB_GRID_TILE_SIZE),
		floori((world_position.y - HUB_GRID_ORIGIN.y) / HUB_GRID_TILE_SIZE)
	)
	return cell if _hub_cell_in_bounds(cell.x, cell.y) else Vector2i(-1, -1)


func hub_build_cost(kind: String) -> Dictionary:
	match kind:
		"wall":
			return {"resource": "stone", "amount": HUB_WALL_STONE_COST}
		"lamp":
			return {"gold": HUB_LAMP_GOLD_COST}
		"storage":
			return {"gold": storage_chest_cost()}
	return {}


func hub_build_status(
	kind: String,
	col: int,
	row: int,
	player_position: Variant = null
) -> Dictionary:
	var request: = {"kind": kind, "col": col, "row": row}
	if not is_hub_unlocked() or current_scene != "hub":
		return {"ok": false, "reason": "hub_unavailable", "request": request}
	if kind not in ["wall", "lamp", "storage"]:
		return {"ok": false, "reason": "unsupported_building", "request": request}
	if not _hub_cell_in_bounds(col, row):
		return {"ok": false, "reason": "outside_grid", "request": request}
	if not _hub_occupant_at_cell(col, row).is_empty():
		return {"ok": false, "reason": "occupied", "request": request}
	var actor_position: = current_position
	if player_position is Vector2 and _valid_vector(player_position):
		actor_position = player_position
	if hub_cell_center(col, row).distance_to(actor_position) < HUB_PLAYER_BUILD_CLEARANCE:
		return {"ok": false, "reason": "player_clearance", "request": request}
	var cost: = hub_build_cost(kind)
	if cost.has("resource") and int(cargo.get(String(cost.resource), 0)) < int(cost.amount):
		return {"ok": false, "reason": "insufficient_resource", "request": request, "cost": cost}
	if cost.has("gold") and gold < int(cost.gold):
		return {"ok": false, "reason": "insufficient_gold", "request": request, "cost": cost}
	return {
		"ok": true,
		"reason": "ready",
		"request": request,
		"cost": cost,
		"position": hub_cell_center(col, row),
	}


func build_hub_cell(
	kind: String,
	col: int,
	row: int,
	player_position: Variant = null
) -> Dictionary:
	var status: = hub_build_status(kind, col, row, player_position)
	if not bool(status.get("ok", false)):
		return status
	var cost: Dictionary = Dictionary(status.cost)
	if cost.has("resource"):
		var resource_id: = String(cost.resource)
		cargo[resource_id] = int(cargo.get(resource_id, 0)) - int(cost.amount)
	else:
		gold -= int(cost.gold)
	var result: = {
		"ok": true,
		"reason": "built",
		"kind": kind,
		"cell": Vector2i(col, row),
		"position": hub_cell_center(col, row),
		"cost": cost.duplicate(true),
	}
	if kind in ["wall", "lamp"]:
		var tiles: Array = Array(hub.get("tiles", [])).duplicate(true)
		tiles.append({"col": col, "row": row, "kind": kind})
		hub["tiles"] = tiles
	else:
		var chest: = _new_storage_chest("hub", 1, hub_cell_center(col, row), false)
		var chests: Array = Array(base.get("chests", [])).duplicate(true)
		chests.append(chest)
		base["chests"] = chests
		result["module"] = chest.duplicate(true)
	_state_changed()
	return result


func remove_hub_cell(col: int, row: int) -> Dictionary:
	if not is_hub_unlocked() or current_scene != "hub":
		return {"ok": false, "reason": "hub_unavailable"}
	if not _hub_cell_in_bounds(col, row):
		return {"ok": false, "reason": "outside_grid"}
	var tiles: Array = Array(hub.get("tiles", [])).duplicate(true)
	for index in tiles.size():
		var tile: Dictionary = Dictionary(tiles[index])
		if int(tile.get("col", -1)) != col or int(tile.get("row", -1)) != row:
			continue
		tiles.remove_at(index)
		hub["tiles"] = tiles
		var refund: = {"resource": "stone", "amount": HUB_WALL_STONE_COST} if String(tile.kind) == "wall" else {"gold": HUB_LAMP_GOLD_COST}
		if refund.has("resource"):
			var resource_id: = String(refund.resource)
			cargo[resource_id] = int(cargo.get(resource_id, 0)) + int(refund.amount)
		else:
			gold += int(refund.gold)
		_state_changed()
		return {"ok": true, "reason": "refunded", "kind": String(tile.kind), "refund": refund}
	var module: = _hub_module_at_cell(col, row)
	if module.is_empty():
		return {"ok": false, "reason": "empty_cell"}
	module["packed"] = true
	_write_base_module(module)
	_state_changed()
	return {
		"ok": true,
		"reason": "packed",
		"kind": String(module.kind),
		"module_id": String(module.id),
		"lossless": true,
	}


func commit_hub_runtime_state(
	next_hub_state: Dictionary,
	next_base_state: Dictionary,
	next_economy_state: Dictionary
) -> bool:
	if not is_hub_unlocked():
		return false
	var clean_hub: = _sanitize_hub_state(next_hub_state, victory or is_hub_unlocked())
	var clean_base: = _sanitize_base_state(next_base_state, bool(clean_hub.unlocked))
	var clean_gold: = _nonnegative_int(next_economy_state.get("gold", gold), gold)
	var clean_cargo: = _sanitize_resource_store(next_economy_state.get("cargo", cargo))
	if hub == clean_hub and base == clean_base and gold == clean_gold and cargo == clean_cargo:
		return false
	hub = clean_hub
	base = clean_base
	gold = clean_gold
	cargo = clean_cargo
	_state_changed()
	return true


func all_base_modules() -> Array:
	return _all_base_modules_internal().duplicate(true)


func base_module_by_id(module_id: String) -> Dictionary:
	return _base_module_by_id_internal(module_id).duplicate(true)


func storage_chest_cost() -> int:
	var existing: = Array(base.get("chests", [])).size()
	return roundi(250.0 * pow(1.65, float(maxi(0, existing - 1))) / 10.0) * 10


func storage_chest_type_count(chest_id: String) -> int:
	var chest: = _base_module_by_id_internal(chest_id)
	if String(chest.get("kind", "")) != "storage":
		return 0
	return _storage_type_count(chest)


func buy_storage_chest(
	scene: String = "",
	depth: int = 0,
	position: Variant = null
) -> Dictionary:
	var cost: = storage_chest_cost()
	if gold < cost:
		return {"ok": false, "reason": "insufficient_gold", "cost": cost}
	var target_scene: = current_scene if scene.is_empty() else scene
	var target_depth: = current_depth if depth <= 0 else depth
	var target_position: = current_position
	if position is Vector2 and _valid_vector(position):
		target_position = position
	if not _base_location_allowed(target_scene, target_depth):
		return {"ok": false, "reason": "invalid_location", "cost": cost}
	var chest: = _new_storage_chest(target_scene, target_depth, target_position, true)
	var chests: Array = Array(base.get("chests", [])).duplicate(true)
	chests.append(chest)
	base["chests"] = chests
	gold -= cost
	_state_changed()
	return {"ok": true, "reason": "purchased", "cost": cost, "module": chest.duplicate(true)}


func place_base_module(
	module_id: String,
	scene: String = "",
	depth: int = 0,
	position: Variant = null
) -> bool:
	var module: = _base_module_by_id_internal(module_id)
	if module.is_empty() or not bool(module.get("packed", false)):
		return false
	var target_scene: = current_scene if scene.is_empty() else scene
	var target_depth: = current_depth if depth <= 0 else depth
	var target_position: = current_position
	if position is Vector2 and _valid_vector(position):
		target_position = position
	if not _base_location_allowed(target_scene, target_depth):
		return false
	if target_scene == "hub":
		var cell: = hub_cell_at_world(target_position)
		if cell == Vector2i(-1, -1) or not _hub_occupant_at_cell(cell.x, cell.y).is_empty():
			return false
		target_position = hub_cell_center(cell.x, cell.y)
	module["scene"] = target_scene
	module["depth"] = 1 if target_scene in ["surface", "hub"] else (2 if target_depth == 2 else 1)
	module["x"] = target_position.x
	module["y"] = target_position.y
	module["packed"] = false
	_write_base_module(module)
	_state_changed()
	return true


func pack_base_module(
	module_id: String,
	player_position: Variant = null,
	require_nearby: bool = true
) -> bool:
	var module: = _base_module_by_id_internal(module_id)
	if module.is_empty() or not _module_is_at_location(module, current_scene, current_depth):
		return false
	var actor_position: = current_position
	if player_position is Vector2 and _valid_vector(player_position):
		actor_position = player_position
	if require_nearby and actor_position.distance_to(Vector2(float(module.x), float(module.y))) > BASE_MODULE_INTERACT_RADIUS:
		return false
	module["packed"] = true
	_write_base_module(module)
	_state_changed()
	return true


func nearby_storage_chests(
	player_position: Variant = null,
	scene: String = "",
	depth: int = 0,
	radius: float = AUTO_SORT_RADIUS
) -> Array:
	var target_position: = current_position
	if player_position is Vector2 and _valid_vector(player_position):
		target_position = player_position
	var target_scene: = current_scene if scene.is_empty() else scene
	var target_depth: = current_depth if depth <= 0 else depth
	var result: Array = []
	for chest_value in Array(base.get("chests", [])):
		var chest: Dictionary = Dictionary(chest_value)
		if not _module_is_at_location(chest, target_scene, target_depth):
			continue
		if target_position.distance_to(Vector2(float(chest.x), float(chest.y))) <= maxf(0.0, radius):
			result.append(chest.duplicate(true))
	return result


func auto_sort_resources(
	player_position: Variant = null,
	scene: String = "",
	depth: int = 0,
	radius: float = AUTO_SORT_RADIUS
) -> int:
	var target_position: = current_position
	if player_position is Vector2 and _valid_vector(player_position):
		target_position = player_position
	var target_scene: = current_scene if scene.is_empty() else scene
	var target_depth: = current_depth if depth <= 0 else depth
	var chests: Array = Array(base.get("chests", [])).duplicate(true)
	var nearby_indices: Array[int] = []
	for index in chests.size():
		var chest: Dictionary = Dictionary(chests[index])
		if _module_is_at_location(chest, target_scene, target_depth) and target_position.distance_to(Vector2(float(chest.x), float(chest.y))) <= maxf(0.0, radius):
			nearby_indices.append(index)
	if nearby_indices.is_empty():
		return 0
	var protected: = _protected_progress_cargo()
	var moved: = 0
	for resource_id_value in RESOURCE_IDS:
		var resource_id: = String(resource_id_value)
		var remaining: = maxi(0, int(cargo.get(resource_id, 0)) - int(protected.get(resource_id, 0)))
		if remaining <= 0:
			continue
		var target_index: = -1
		for index in nearby_indices:
			var existing: Dictionary = Dictionary(chests[index])
			if int(Dictionary(existing.items).get(resource_id, 0)) > 0:
				target_index = index
				break
		if target_index < 0:
			for index in nearby_indices:
				if _storage_type_count(Dictionary(chests[index])) < STORAGE_CHEST_CAPACITY:
					target_index = index
					break
		if target_index < 0:
			continue
		var target: Dictionary = Dictionary(chests[target_index])
		var items: Dictionary = Dictionary(target.get("items", _empty_resource_store()))
		items[resource_id] = int(items.get(resource_id, 0)) + remaining
		target["items"] = items
		chests[target_index] = target
		cargo[resource_id] = int(cargo.get(resource_id, 0)) - remaining
		moved += remaining
	if moved > 0:
		base["chests"] = chests
		_state_changed()
	return moved


func take_all_from_storage(
	chest_id: String,
	player_position: Variant = null,
	scene: String = "",
	depth: int = 0,
	radius: float = AUTO_SORT_RADIUS
) -> int:
	var chest: = _base_module_by_id_internal(chest_id)
	if String(chest.get("kind", "")) != "storage":
		return 0
	var target_position: = current_position
	if player_position is Vector2 and _valid_vector(player_position):
		target_position = player_position
	var target_scene: = current_scene if scene.is_empty() else scene
	var target_depth: = current_depth if depth <= 0 else depth
	if not _module_is_at_location(chest, target_scene, target_depth):
		return 0
	if target_position.distance_to(Vector2(float(chest.x), float(chest.y))) > maxf(0.0, radius):
		return 0
	var items: Dictionary = Dictionary(chest.get("items", {}))
	var moved: = 0
	for resource_id_value in RESOURCE_IDS:
		var resource_id: = String(resource_id_value)
		var amount: = int(items.get(resource_id, 0))
		if amount <= 0:
			continue
		cargo[resource_id] = int(cargo.get(resource_id, 0)) + amount
		items[resource_id] = 0
		moved += amount
	if moved > 0:
		chest["items"] = items
		_write_base_module(chest)
		_state_changed()
	return moved


func set_movement_speed_level(level: int) -> void :
	var normalized: = maxi(0, level)
	if movement_speed_level == normalized:
		return
	movement_speed_level = normalized
	_state_changed()


func movement_speed_multiplier(level: int = -1) -> float:
	var resolved_level: = movement_speed_level if level < 0 else maxi(0, level)
	return 1.0 + float(resolved_level) * float(_game_data().MOVEMENT_SPEED_GAIN)


func movement_speed_upgrade_cost(level: int = -1) -> int:
	var resolved_level: = movement_speed_level if level < 0 else maxi(0, level)


	return roundi(
		(150.0 + 75.0 * float(resolved_level) + 25.0 * float(resolved_level * resolved_level))
		/ 10.0
	) * 10


func buy_movement_speed() -> Dictionary:
	var cost: = movement_speed_upgrade_cost()
	if gold < cost:
		return {
			"ok": false,
			"reason": "insufficient_gold",
			"cost": cost,
			"missing_gold": cost - gold,
			"level": movement_speed_level,
			"multiplier": movement_speed_multiplier(),
		}
	gold -= cost
	movement_speed_level += 1
	_state_changed()
	return {
		"ok": true,
		"reason": "purchased",
		"cost": cost,
		"level": movement_speed_level,
		"multiplier": movement_speed_multiplier(),
		"next_cost": movement_speed_upgrade_cost(),
	}


func is_world_unlocked(world_id: String) -> bool:
	match world_id:
		"mossvein":
			return true
		"moonglass":
			return area_unlocked
		"emberdeep":
			return emberdeep_unlocked
		"starfall":
			return fourth_unlocked
	return false


func unlock_world(world_id: String) -> bool:
	var did_change: = false
	match world_id:
		"mossvein":
			return false
		"moonglass":
			if not area_unlocked:
				area_unlocked = true
				did_change = true
		"emberdeep":
			if not area_unlocked or not emberdeep_unlocked:
				area_unlocked = true
				emberdeep_unlocked = true
				did_change = true
		"starfall":
			if not area_unlocked or not emberdeep_unlocked or not fourth_unlocked:
				area_unlocked = true
				emberdeep_unlocked = true
				fourth_unlocked = true
				did_change = true
		_:
			return false
	if did_change:
		_state_changed()
	return did_change


func mark_mine_discovered(mine_id: String) -> bool:
	if not MINE_IDS.has(mine_id) or bool(discovered_mines.get(mine_id, false)):
		return false
	discovered_mines[mine_id] = true
	_state_changed()
	return true


func mark_depth_entrance_discovered(mine_id: String) -> bool:
	if not MINE_IDS.has(mine_id) or bool(discovered_depth_entrances.get(mine_id, false)):
		return false
	discovered_depth_entrances[mine_id] = true
	_state_changed()
	return true


func is_depth_entrance_discovered(mine_id: String) -> bool:
	return MINE_IDS.has(mine_id) and bool(discovered_depth_entrances.get(mine_id, false))


func depth_entry_status(mine_id: String) -> Dictionary:
	if not MINE_IDS.has(mine_id):
		return {"can_enter": false, "reason": "unknown_mine", "mine_id": mine_id}
	var world_id: = String(WORLD_BY_MINE[mine_id])
	if not is_world_unlocked(world_id):
		return {"can_enter": false, "reason": "world_locked", "mine_id": mine_id, "depth": 2}
	if not is_depth_entrance_discovered(mine_id):
		return {"can_enter": false, "reason": "entrance_hidden", "mine_id": mine_id, "depth": 2}
	var maximum_drill_level: = maxi(0, Array(_game_data().DRILLS).size() - 1)
	if mine_id == "starMine" and drill_level < maximum_drill_level:
		return {
			"can_enter": false,
			"reason": "deepcore_required",
			"mine_id": mine_id,
			"depth": 2,
		}
	return {
		"can_enter": true,
		"reason": "ready",
		"mine_id": mine_id,
		"depth": 2,
		"name": String(_game_data().MINE_DEPTH_PROFILES[mine_id].name),
		"deep_tool_ready": has_deep_tool(),
	}


func enter_depth(mine_id: String) -> bool:
	var status: = depth_entry_status(mine_id)
	if not bool(status.get("can_enter", false)):
		return false
	var did_change: = false
	if not bool(visited_depths.get(mine_id, false)):
		visited_depths[mine_id] = true
		did_change = true
	if drill_goal_scene.is_empty():
		drill_goal_scene = mine_id
		did_change = true
	if did_change:
		_state_changed()
	return true


func is_depth_visited(mine_id: String) -> bool:
	return MINE_IDS.has(mine_id) and bool(visited_depths.get(mine_id, false))


func mark_cavern_discovered(cavern_id: String) -> bool:
	if not _all_cavern_ids().has(cavern_id) or bool(discovered_caverns.get(cavern_id, false)):
		return false
	discovered_caverns[cavern_id] = true
	_state_changed()
	return true


func is_cavern_discovered(cavern_id: String) -> bool:
	return _all_cavern_ids().has(cavern_id) and bool(discovered_caverns.get(cavern_id, false))


func is_pocket_reward_claimed(reward_id: String) -> bool:
	return _all_pocket_reward_ids().has(reward_id) and bool(claimed_pocket_rewards.get(reward_id, false))


func claim_pocket_reward(reward_id: String) -> Dictionary:
	return _commit_pocket_reward(reward_id, false)


func complete_pocket_deposit(reward_id: String) -> Dictionary:
	return _commit_pocket_reward(reward_id, true)


func pending_pocket_reward_loot(reward_id: String) -> Dictionary:
	return Dictionary(pending_pocket_loot.get(reward_id, {})).duplicate(true)


func collect_pocket_loot(reward_id: String, resource_id: String, amount: int) -> int:
	if amount <= 0 or not RESOURCE_IDS.has(resource_id):
		return 0
	var pending: Dictionary = Dictionary(pending_pocket_loot.get(reward_id, {}))
	var collected: = mini(amount, int(pending.get(resource_id, 0)))
	if collected <= 0:
		return 0
	cargo[resource_id] = int(cargo.get(resource_id, 0)) + collected
	pending[resource_id] = int(pending.get(resource_id, 0)) - collected
	if int(pending[resource_id]) <= 0:
		pending.erase(resource_id)
	if pending.is_empty():
		pending_pocket_loot.erase(reward_id)
	else:
		pending_pocket_loot[reward_id] = pending
	_state_changed()
	resource_collected.emit(resource_id, collected)
	return collected


func is_surface_chest_opened(chest_id: String) -> bool:
	return _all_chest_ids().has(chest_id) and bool(opened_chests.get(chest_id, false))


func open_surface_chest(chest_id: String) -> Dictionary:
	if is_surface_chest_opened(chest_id):
		return {"ok": false, "reason": "already_opened"}
	var plan: Dictionary = _moss_rules().surface_chest_claim_plan(
		chest_id,
		pickaxe_level,
		not starforge_variant.is_empty()
	)
	if not bool(plan.get("ok", false)):
		return plan
	opened_chests[chest_id] = true
	pending_chest_loot[chest_id] = Dictionary(plan.pending_loot).duplicate(true)
	_state_changed()
	return plan


func open_mossvein_chest(chest_id: String) -> Dictionary:

	return open_surface_chest(chest_id)


func pending_chest_reward_loot(chest_id: String) -> Dictionary:
	return Dictionary(pending_chest_loot.get(chest_id, {})).duplicate(true)


func collect_chest_loot(chest_id: String, reward_id: String, amount: int) -> int:
	if amount <= 0 or (reward_id != "coin" and not RESOURCE_IDS.has(reward_id)):
		return 0
	var pending: Dictionary = Dictionary(pending_chest_loot.get(chest_id, {}))
	var collected: = mini(amount, int(pending.get(reward_id, 0)))
	if collected <= 0:
		return 0
	if reward_id == "coin":
		gold += collected
		total_gold_earned += collected
	else:
		cargo[reward_id] = int(cargo.get(reward_id, 0)) + collected
	pending[reward_id] = int(pending.get(reward_id, 0)) - collected
	if int(pending[reward_id]) <= 0:
		pending.erase(reward_id)
	if pending.is_empty():
		pending_chest_loot.erase(chest_id)
	else:
		pending_chest_loot[chest_id] = pending
	_state_changed()
	resource_collected.emit("gold" if reward_id == "coin" else reward_id, collected)
	return collected


func mark_barrier_cleared(barrier_id: String) -> bool:
	if barrier_id.is_empty() or bool(cleared_mine_barriers.get(barrier_id, false)):
		return false
	cleared_mine_barriers[barrier_id] = true
	_state_changed()
	return true


func mark_mine_barrier_cleared(barrier_id: String) -> bool:
	return mark_barrier_cleared(barrier_id)


func is_mine_barrier_cleared(barrier_id: String) -> bool:
	return bool(cleared_mine_barriers.get(barrier_id, false))


func mark_terrain_dug(mine_id: String, cell_index: int, depth: int = 1) -> bool:
	if not MINE_IDS.has(mine_id) or cell_index < 0:
		return false
	var key: = _terrain_key(mine_id, depth)
	if not terrain_dug_lookup.has(key):
		_rebuild_terrain_dug_lookup()
	var lookup: Dictionary = Dictionary(terrain_dug_lookup.get(key, {}))
	if lookup.has(cell_index):
		return false
	var cells: Array = Array(terrain_dug.get(key, []))
	cells.append(cell_index)
	terrain_dug[key] = cells
	lookup[cell_index] = true
	terrain_dug_lookup[key] = lookup
	_state_changed()
	return true


func record_dug_cell(mine_id: String, cell_index: int, depth: int = 1) -> bool:
	return mark_terrain_dug(mine_id, cell_index, depth)


func dug_cells(mine_id: String, depth: int = 1) -> Array:
	if not MINE_IDS.has(mine_id):
		return []
	return Array(terrain_dug.get(_terrain_key(mine_id, depth), [])).duplicate()


func mine_resource_scope_state(mine_id: String, depth: int = 1) -> Dictionary:
	if not MINE_IDS.has(mine_id):
		return {}
	var key: = _mine_runtime_key(mine_id, depth)
	return Dictionary(mine_resource_runtime.get(key, _default_mine_runtime_scope())).duplicate(true)


func mine_resource_depletions(mine_id: String, depth: int = 1) -> Dictionary:
	return Dictionary(mine_resource_scope_state(mine_id, depth).get("depleted", {})).duplicate(true)


func mine_loose_loot(mine_id: String, depth: int = 1) -> Array:
	return Array(mine_resource_scope_state(mine_id, depth).get("loose_loot", [])).duplicate(true)


func deplete_mine_resource_node(
	mine_id: String,
	depth: int,
	node_id: String,
	respawn_seconds: float
) -> float:
	var kind: = _mine_resource_node_kind(mine_id, depth, node_id)
	if kind.is_empty():
		return 0.0
	var profile: Dictionary = Dictionary(_game_data().ROCK_TYPES.get(kind, {}))
	var maximum: = maxf(0.0, float(profile.get("respawn", respawn_seconds)))
	var duration: = clampf(respawn_seconds, 0.0, maximum)
	var respawn_until: = ceili(Time.get_unix_time_from_system() + duration)
	var key: = _mine_runtime_key(mine_id, depth)
	var scope: Dictionary = Dictionary(mine_resource_runtime.get(key, _default_mine_runtime_scope()))
	var depleted: Dictionary = Dictionary(scope.get("depleted", {}))
	depleted[node_id] = {"kind": kind, "respawn_until_unix": respawn_until}
	scope["depleted"] = depleted
	mine_resource_runtime[key] = scope
	_state_changed()
	return respawn_until


func clear_mine_resource_depletion(mine_id: String, depth: int, node_id: String) -> bool:
	if not MINE_IDS.has(mine_id):
		return false
	var key: = _mine_runtime_key(mine_id, depth)
	var scope: Dictionary = Dictionary(mine_resource_runtime.get(key, _default_mine_runtime_scope()))
	var depleted: Dictionary = Dictionary(scope.get("depleted", {}))
	if not depleted.has(node_id):
		return false
	depleted.erase(node_id)
	scope["depleted"] = depleted
	mine_resource_runtime[key] = scope
	_state_changed()
	return true


func register_mine_loose_loot(
	mine_id: String,
	depth: int,
	kind: String,
	amount: int,
	position: Vector2,
	merge_drop_id: String = ""
) -> Dictionary:
	if not MINE_IDS.has(mine_id) or kind not in RESOURCE_IDS or amount <= 0 or not _valid_vector(position):
		return {}
	var key: = _mine_runtime_key(mine_id, depth)
	var scope: Dictionary = Dictionary(mine_resource_runtime.get(key, _default_mine_runtime_scope()))
	var loose_loot: Array = Array(scope.get("loose_loot", []))
	var safe_amount: = mini(MAX_MINE_LOOSE_DROP_AMOUNT, amount)
	var safe_position: = _clamp_mine_runtime_position(mine_id, position)



	if not merge_drop_id.is_empty():
		for index in loose_loot.size():
			var preferred: Dictionary = Dictionary(loose_loot[index])
			if (
				String(preferred.get("id", "")) != merge_drop_id
				or String(preferred.get("kind", "")) != kind
			):
				continue
			preferred["amount"] = mini(
				MAX_MINE_LOOSE_DROP_AMOUNT,
				int(preferred.get("amount", 0)) + safe_amount
			)
			loose_loot[index] = preferred
			scope["loose_loot"] = loose_loot
			mine_resource_runtime[key] = scope
			_state_changed()
			var preferred_result: = preferred.duplicate(true)
			preferred_result["merged"] = true
			preferred_result["resync"] = false
			return preferred_result

	if loose_loot.size() >= MAX_MINE_LOOSE_DROPS_PER_SCOPE:
		for index in loose_loot.size():
			var existing: Dictionary = Dictionary(loose_loot[index])
			if String(existing.get("kind", "")) != kind:
				continue
			existing["amount"] = mini(
				MAX_MINE_LOOSE_DROP_AMOUNT,
				int(existing.get("amount", 0)) + safe_amount
			)
			loose_loot[index] = existing
			scope["loose_loot"] = loose_loot
			mine_resource_runtime[key] = scope
			_state_changed()
			var merged: = existing.duplicate(true)
			merged["merged"] = true
			merged["resync"] = false
			return merged




		var first_by_kind: = {}
		for index in loose_loot.size():
			var existing: Dictionary = Dictionary(loose_loot[index])
			var existing_kind: = String(existing.get("kind", ""))
			if not first_by_kind.has(existing_kind):
				first_by_kind[existing_kind] = index
				continue
			var first_index: = int(first_by_kind[existing_kind])
			var first: Dictionary = Dictionary(loose_loot[first_index])
			first["amount"] = mini(
				MAX_MINE_LOOSE_DROP_AMOUNT,
				int(first.get("amount", 0)) + int(existing.get("amount", 0))
			)
			loose_loot[first_index] = first
			loose_loot.remove_at(index)
			break

	var next_drop_id: = maxi(1, int(scope.get("next_drop_id", 1)))
	var drop: = {
		"id": str(next_drop_id),
		"kind": kind,
		"amount": safe_amount,
		"x": safe_position.x,
		"y": safe_position.y,
	}
	loose_loot.append(drop)
	scope["next_drop_id"] = next_drop_id + 1
	scope["loose_loot"] = loose_loot
	mine_resource_runtime[key] = scope
	_state_changed()
	var result: = drop.duplicate(true)
	result["merged"] = false
	result["resync"] = loose_loot.size() >= MAX_MINE_LOOSE_DROPS_PER_SCOPE
	return result


func update_mine_loose_loot_position(
	mine_id: String,
	depth: int,
	drop_id: String,
	position: Vector2
) -> bool:
	if not MINE_IDS.has(mine_id) or drop_id.is_empty() or not _valid_vector(position):
		return false
	var key: = _mine_runtime_key(mine_id, depth)
	var scope: Dictionary = Dictionary(mine_resource_runtime.get(key, _default_mine_runtime_scope()))
	var loose_loot: Array = Array(scope.get("loose_loot", []))
	var safe_position: = _clamp_mine_runtime_position(mine_id, position)
	for index in loose_loot.size():
		var drop: Dictionary = Dictionary(loose_loot[index])
		if String(drop.get("id", "")) != drop_id:
			continue
		if Vector2(float(drop.get("x", 0.0)), float(drop.get("y", 0.0))).distance_squared_to(safe_position) <= 0.01:
			return true
		drop["x"] = safe_position.x
		drop["y"] = safe_position.y
		loose_loot[index] = drop
		scope["loose_loot"] = loose_loot
		mine_resource_runtime[key] = scope
		_state_changed()
		return true
	return false


func collect_mine_loose_loot(
	mine_id: String,
	depth: int,
	drop_id: String,
	requested_amount: int = 0
) -> Dictionary:
	if not MINE_IDS.has(mine_id) or drop_id.is_empty():
		return {"amount": 0, "remaining": 0, "kind": ""}
	var key: = _mine_runtime_key(mine_id, depth)
	var scope: Dictionary = Dictionary(mine_resource_runtime.get(key, _default_mine_runtime_scope()))
	var loose_loot: Array = Array(scope.get("loose_loot", []))
	for index in loose_loot.size():
		var drop: Dictionary = Dictionary(loose_loot[index])
		if String(drop.get("id", "")) != drop_id:
			continue
		var kind: = String(drop.get("kind", ""))
		var available: = maxi(0, int(drop.get("amount", 0)))
		if kind not in RESOURCE_IDS or available <= 0:
			loose_loot.remove_at(index)
			scope["loose_loot"] = loose_loot
			mine_resource_runtime[key] = scope
			_state_changed()
			return {"amount": 0, "remaining": 0, "kind": kind}
		var collected: = available if requested_amount <= 0 else mini(available, requested_amount)
		var remaining: = available - collected
		if remaining <= 0:
			loose_loot.remove_at(index)
		else:
			drop["amount"] = remaining
			loose_loot[index] = drop
		scope["loose_loot"] = loose_loot
		mine_resource_runtime[key] = scope
		cargo[kind] = int(cargo.get(kind, 0)) + collected
		_state_changed()
		resource_collected.emit(kind, collected)
		return {"amount": collected, "remaining": remaining, "kind": kind}
	return {"amount": 0, "remaining": 0, "kind": ""}


func set_location(scene: String, position: Vector2, depth: int = 1) -> bool:
	if not VALID_SCENES.has(scene) or not _valid_vector(position):
		return false
	if scene == "hub" and not is_hub_unlocked():
		return false
	if scene == "deepheart" and not _deepheart_restore_allowed():
		return false
	if scene == "endless" and ( not victory or not endless_descent_active):
		return false
	var next_depth: = 2 if MINE_IDS.has(scene) and depth == 2 else 1
	var next_position: = position
	if scene == "hub":
		next_position = position.clamp(
			Vector2(52.0, 70.0), HUB_WORLD_SIZE - Vector2(52.0, 58.0)
		)
	elif scene == "deepheart":
		next_position = position.clamp(
			Vector2(52.0, 70.0), DEEPHEART_WORLD_SIZE - Vector2(52.0, 58.0)
		)
	if current_scene == scene and current_depth == next_depth and current_position.distance_squared_to(next_position) < 1.0:
		return true
	current_scene = scene
	current_depth = next_depth
	current_position = next_position
	if scene == "surface":
		last_surface_position = next_position
	_state_changed()
	return true


func cargo_count() -> int:
	var total: = 0
	for amount in cargo.values():
		total += int(amount)
	return total


func cargo_label() -> String:
	return "STONE %d  ·  COPPER %d  ·  GOLD %d" % [
		int(cargo.get("stone", 0)),
		int(cargo.get("copper", 0)),
		int(cargo.get("gold", 0)),
	]


func set_surface_ore_state(reserve: float, yield_buffer: float, gold_ready: bool, updated_unix: int, ground_loot: Dictionary = {}) -> void :
	surface_ore_reserve = clampf(reserve, 0.0, 1.0)
	surface_ore_yield_buffer = clampf(yield_buffer, 0.0, 0.999999)
	surface_ore_gold_ready = gold_ready
	surface_ore_updated_unix = maxi(0, updated_unix)
	surface_ore_ground_loot = {
		"copper": _nonnegative_int(ground_loot.get("copper", 0), 0),
		"gold": _nonnegative_int(ground_loot.get("gold", 0), 0),
	}
	_state_changed()


func surface_mountain_ids() -> Array:
	return SURFACE_MOUNTAIN_IDS.duplicate()


func surface_mountain_state(mountain_id: String) -> Dictionary:
	if not SURFACE_MOUNTAIN_IDS.has(mountain_id):
		return {}
	return _sanitize_surface_mountain(
		mountain_id, surface_mountains.get(mountain_id, {})
	).duplicate(true)


func surface_mountains_snapshot() -> Dictionary:
	var snapshot: = {}
	for mountain_id_value in SURFACE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		snapshot[mountain_id] = _sanitize_surface_mountain(
			mountain_id, surface_mountains.get(mountain_id, {})
		)
	return snapshot


func set_surface_mountain_state(
	mountain_id: String,
	reserve: float,
	yield_buffer: float,
	rare_ready: bool,
	updated_unix: int,
	ground_loot: Dictionary = {}
) -> bool:
	if not SURFACE_MOUNTAIN_IDS.has(mountain_id):
		return false
	surface_mountains[mountain_id] = _sanitize_surface_mountain(mountain_id, {
		"reserve": reserve,
		"yield_buffer": yield_buffer,
		"rare_ready": rare_ready,
		"updated_unix": updated_unix,
		"ground_loot": ground_loot,
	})
	_state_changed()
	return true


func surface_vein_ids() -> Array:
	return SURFACE_VEIN_IDS.duplicate()


func surface_vein_profile(vein_id: String) -> Dictionary:
	if not SURFACE_VEIN_PROFILES.has(vein_id):
		return {}
	var result: Dictionary = Dictionary(SURFACE_VEIN_PROFILES[vein_id]).duplicate(true)
	result["id"] = vein_id
	result["node_total"] = int(result.node_hp) + int(result.node_shell)
	return result


func surface_vein_state(vein_id: String) -> Dictionary:
	if not SURFACE_VEIN_IDS.has(vein_id):
		return {}
	return Dictionary(surface_veins.get(vein_id, _default_surface_vein(vein_id))).duplicate(true)


func surface_veins_snapshot() -> Dictionary:
	_sync_surface_veins_from_legacy_moonglass()
	return surface_veins.duplicate(true)


func set_surface_vein_state(
	vein_id: String,
	nodes: Array,
	status: String,
	timer: float,
	completions: int,
	updated_unix: int,
	ground_loot: Dictionary = {}
) -> bool:
	if not SURFACE_VEIN_IDS.has(vein_id):
		return false
	var raw: = {
		"nodes": nodes,
		"status": status,
		"timer": timer,
		"completions": completions,
		"updated_unix": updated_unix,
		"ground_loot": ground_loot,
	}
	surface_veins[vein_id] = _sanitize_surface_vein(vein_id, raw)
	if vein_id == "moonglass_bloom":
		_sync_moonglass_legacy_from_surface_veins()
	_state_changed()
	return true


func set_surface_moonglass_state(
	nodes: Array,
	vein_status: String,
	vein_timer: float,
	completions: int,
	updated_unix: int,
	ground_loot: Dictionary = {}
) -> void :
	set_surface_vein_state(
		"moonglass_bloom",
		nodes,
		vein_status,
		vein_timer,
		completions,
		updated_unix,
		ground_loot
	)


func serialize() -> Dictionary:
	_sync_surface_veins_from_legacy_moonglass()
	_normalize_endless_state()
	var saved_depth_entrances: = discovered_depth_entrances.duplicate(true)
	var saved_visited_depths: = visited_depths.duplicate(true)
	var saved_drill_goal_scene: = drill_goal_scene
	var saved_singularity_secured: = singularity_secured
	var saved_deliveries: = _sanitize_deep_elevator_deliveries(deep_elevator_deliveries)
	var saved_repaired: = _deep_elevator_deliveries_complete(saved_deliveries)
	var saved_powered: = deep_elevator_powered and saved_repaired and saved_singularity_secured
	var saved_final_begun: = final_expedition_begun and saved_powered
	var saved_deepheart_seals: = _sanitize_bool_map(
		deepheart_seals, DEEPHEART_SEAL_IDS
	)
	if not saved_final_begun:
		saved_deepheart_seals = _default_deepheart_seals()
	var saved_victory: = (
		victory
		and saved_powered
		and saved_final_begun
		and _deepheart_seals_complete(saved_deepheart_seals)
	)
	var saved_deepheart_awakened_at_mined: = 0
	if saved_victory:
		saved_deepheart_awakened_at_mined = clampi(
			deepheart_awakened_at_mined, 0, total_mined_resources()
		)
	var saved_conclusion_seen: = conclusion_seen and saved_victory
	var saved_hub_early: = (
		hub_unlocked_early
		or bool(hub.get("unlocked", false))
		or not starforge_variant.is_empty()
		or drill_level > 0
		or saved_singularity_secured
		or saved_victory
	)
	var saved_hub: = _sanitize_hub_state(hub, saved_hub_early)
	var saved_base: = _sanitize_base_state(base, bool(saved_hub.unlocked))
	var saved_belt_state: Dictionary = _belt_rules().sanitize_state(belt_state)
	var saved_mine_resource_runtime: = _sanitize_mine_resource_runtime(mine_resource_runtime)
	var saved_surface_mountains: = {}
	for mountain_id_value in SURFACE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		saved_surface_mountains[mountain_id] = _sanitize_surface_mountain(
			mountain_id, surface_mountains.get(mountain_id, {})
		)
	var saved_surface_veins: = {}
	for vein_id in SURFACE_VEIN_IDS:
		saved_surface_veins[vein_id] = _sanitize_surface_vein(
			String(vein_id), surface_veins.get(vein_id, {})
		)



	if current_depth == 2 and MINE_IDS.has(current_scene):
		saved_depth_entrances[current_scene] = true
		saved_visited_depths[current_scene] = true
		if saved_drill_goal_scene.is_empty():
			saved_drill_goal_scene = current_scene
	return {
		"schema": SAVE_SCHEMA_ID,
		"version": SAVE_SCHEMA_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"state": {
			"overhaul": overhaul_progress.duplicate(true),
			"gold": gold,
			"pickaxe_level": pickaxe_level,
			"ember_mastery": ember_mastery,
			"drill_level": drill_level,
			"drill_goal_scene": saved_drill_goal_scene,
			"movement_speed_level": movement_speed_level,
			"total_swings": total_swings,
			"precision_hits": precision_hits,
			"total_gold_earned": total_gold_earned,
			"starforge_variant": starforge_variant,
			"starforge_unlocked": starforge_unlocked.duplicate(true),
			"cargo": cargo.duplicate(true),
			"mined": mined.duplicate(true),
			"area_unlocked": area_unlocked,
			"emberdeep_unlocked": emberdeep_unlocked,
			"fourth_unlocked": fourth_unlocked,
			"victory": saved_victory,
			"conclusion_seen": saved_conclusion_seen,
			"singularity_secured": saved_singularity_secured,
			"hub_unlocked_early": saved_hub_early,
			"deep_elevator_deliveries": saved_deliveries,
			"deep_elevator_repaired": saved_repaired,
			"deep_elevator_powered": saved_powered,
			"final_expedition_begun": saved_final_begun,
			"deepheart_seals": saved_deepheart_seals,
			"deepheart_awakened_at_mined": saved_deepheart_awakened_at_mined,
			"endless_descent": {
				"active": endless_descent_active and saved_victory,
				"current_depth": endless_current_depth if saved_victory else 0,
				"deepest_depth": endless_deepest_depth if saved_victory else 0,
				"start_depth_checkpoint": endless_start_depth_checkpoint if saved_victory else 1,
				"resource_exhausted_through": endless_resource_exhausted_through if saved_victory else 0,
				"active_floor_depth": endless_active_floor_depth if saved_victory else 0,
				"active_floor_mined_mask": endless_active_floor_mined_mask if saved_victory else 0,
				"active_floor_site_mask": endless_active_floor_site_mask if saved_victory else 0,
				"relics": endless_relics.duplicate(true) if saved_victory else _default_endless_relics(),
				"carried_relic": carried_relic.duplicate(true) if saved_victory else _default_carried_relic(),
				"workshops": endless_workshops.duplicate(true) if saved_victory else _default_endless_workshops(),
				"light_style": endless_light_style if saved_victory else "standard",
				"outfit": endless_outfit if saved_victory else "miner",
				"tool_style": endless_tool_style if saved_victory else "original",
			},
			"belt_state": saved_belt_state,
			"world_seed": world_seed,
			"hub": saved_hub,
			"base": saved_base,
			"discovered_mines": discovered_mines.duplicate(true),
			"discovered_caverns": discovered_caverns.duplicate(true),
			"discovered_depth_entrances": saved_depth_entrances,
			"visited_depths": saved_visited_depths,
			"claimed_pocket_rewards": claimed_pocket_rewards.duplicate(true),
			"pending_pocket_loot": pending_pocket_loot.duplicate(true),
			"opened_chests": opened_chests.duplicate(true),
			"pending_chest_loot": pending_chest_loot.duplicate(true),
			"cleared_mine_barriers": cleared_mine_barriers.duplicate(true),
			"terrain_dug": terrain_dug.duplicate(true),
			"mine_resource_runtime": saved_mine_resource_runtime,
			"surface_ore": {
				"reserve": surface_ore_reserve,
				"yield_buffer": surface_ore_yield_buffer,
				"gold_ready": surface_ore_gold_ready,
				"updated_unix": surface_ore_updated_unix,
				"ground_loot": surface_ore_ground_loot.duplicate(true),
			},
			"surface_mountains": saved_surface_mountains,
			"surface_veins": saved_surface_veins,
			"surface_moonglass": {
				"nodes": surface_moonglass_nodes.duplicate(true),
				"vein_status": surface_moonglass_vein_status,
				"vein_timer": surface_moonglass_vein_timer,
				"completions": surface_moonglass_completions,
				"updated_unix": surface_moonglass_updated_unix,
				"ground_loot": surface_moonglass_ground_loot.duplicate(true),
			},
			"location": {
				"scene": current_scene,
				"depth": current_depth,
				"x": current_position.x,
				"y": current_position.y,
				"surface_x": last_surface_position.x,
				"surface_y": last_surface_position.y,
			},
		},
	}


func deserialize(raw: Variant) -> bool:
	if not raw is Dictionary:
		_apply_defaults()
		return false
	var document: Dictionary = raw
	var source: Dictionary
	var versioned_v2: = false
	if document.get("schema", "") == SAVE_SCHEMA_ID:
		var version: = _nonnegative_int(document.get("version", 0), 0)
		if version != SAVE_SCHEMA_VERSION or not document.get("state") is Dictionary:
			_apply_defaults()
			return false
		source = Dictionary(document.state)
		versioned_v2 = true
	else:



		source = document

	_apply_defaults(false)
	overhaul_progress = _sanitize_overhaul(source.get("overhaul", {}))
	gold = _nonnegative_int(_first_value(source, "gold"), 0)
	var data: = _game_data()
	pickaxe_level = clampi(
		_nonnegative_int(_first_value(source, "pickaxe_level", "pickaxeLevel"), 1),
		1,
		maxi(1, Array(data.PICKAXES).size() - 1)
	)
	ember_mastery = clampi(
		_nonnegative_int(_first_value(source, "ember_mastery", "emberMastery"), 0),
		0,
		maxi(0, Array(data.EMBER_MASTERY).size() - 1)
	)
	if pickaxe_level < Array(data.PICKAXES).size() - 1:
		ember_mastery = 0
	drill_level = clampi(
		_nonnegative_int(_first_value(source, "drill_level", "drillLevel"), 0),
		0,
		maxi(0, Array(data.DRILLS).size() - 1)
	)
	starforge_unlocked = _sanitize_bool_map(
		source.get("starforge_unlocked", source.get("starforgeUnlocked", {})),
		STARFORGE_VARIANT_IDS
	)
	starforge_variant = _sanitize_allowed_id(
		_first_value(source, "starforge_variant", "starforgeVariant"),
		STARFORGE_VARIANT_IDS
	)
	if not bool(starforge_unlocked.get(starforge_variant, false)):
		starforge_variant = ""
	movement_speed_level = _nonnegative_int(
		_first_value(source, "movement_speed_level", "movementSpeedLevel"), 0
	)
	total_swings = _nonnegative_int(_first_value(source, "total_swings", "totalSwings"), 0)
	precision_hits = _nonnegative_int(_first_value(source, "precision_hits", "precisionHits"), 0)
	total_gold_earned = _nonnegative_int(_first_value(source, "total_gold_earned", "totalGold"), gold)
	cargo = _sanitize_resource_store(source.get("cargo", {}))
	mined = _sanitize_resource_store(source.get("mined", {}))

	area_unlocked = _strict_bool(_first_value(source, "area_unlocked", "areaUnlocked"))
	emberdeep_unlocked = _strict_bool(_first_value(source, "emberdeep_unlocked", "emberdeepUnlocked"))
	fourth_unlocked = _strict_bool(_first_value(source, "fourth_unlocked", "fourthUnlocked"))

	if fourth_unlocked:
		emberdeep_unlocked = true
	if emberdeep_unlocked:
		area_unlocked = true
	var maximum_drill_level: = maxi(0, Array(data.DRILLS).size() - 1)
	var imported_legacy_victory: = (
		not versioned_v2 and _strict_bool(source.get("victory", false))
	)
	singularity_secured = (
		_strict_bool(source.get("singularity_secured", false))
		or (
			not versioned_v2
			and drill_level == maximum_drill_level
			and int(mined.get("singularity", 0)) > 0
		)
		or imported_legacy_victory
	)
	deep_elevator_deliveries = _sanitize_deep_elevator_deliveries(
		source.get("deep_elevator_deliveries", {})
	)
	if imported_legacy_victory:
		deep_elevator_deliveries = _default_deep_elevator_deliveries(true)
	deep_elevator_repaired = _deep_elevator_deliveries_complete(deep_elevator_deliveries)
	deep_elevator_powered = (
		(imported_legacy_victory or _strict_bool(source.get("deep_elevator_powered", false)))
		and deep_elevator_repaired
		and singularity_secured
	)
	final_expedition_begun = (
		(imported_legacy_victory or _strict_bool(source.get("final_expedition_begun", false)))
		and deep_elevator_powered
	)
	deepheart_seals = _sanitize_bool_map(
		source.get("deepheart_seals", {}), DEEPHEART_SEAL_IDS
	)
	if imported_legacy_victory:
		deepheart_seals = _default_deepheart_seals(true)
	elif not final_expedition_begun:
		deepheart_seals = _default_deepheart_seals()
	victory = (
		(imported_legacy_victory or _strict_bool(source.get("victory", false)))
		and deep_elevator_powered
		and final_expedition_begun
		and _deepheart_seals_complete(deepheart_seals)
	)
	deepheart_awakened_at_mined = 0
	conclusion_seen = false
	if victory:
		deepheart_awakened_at_mined = clampi(
			_nonnegative_int(
				source.get("deepheart_awakened_at_mined", total_mined_resources()),
				total_mined_resources()
			),
			0,
			total_mined_resources()
		)
		conclusion_seen = _strict_bool(source.get("conclusion_seen", false))
	var endless_raw: Variant = source.get(
		"endless_descent", source.get("endlessDescent", {})
	)
	if victory and endless_raw is Dictionary:
		var endless_source: Dictionary = endless_raw
		endless_descent_active = _strict_bool(endless_source.get("active", false))
		endless_current_depth = clampi(_nonnegative_int(
			endless_source.get("current_depth", endless_source.get("currentDepth", 0)), 0
		), 0, ENDLESS_MAX_SAVED_DEPTH)
		endless_deepest_depth = clampi(_nonnegative_int(
			endless_source.get("deepest_depth", endless_source.get("deepestDepth", 0)), 0
		), 0, ENDLESS_MAX_SAVED_DEPTH)
		endless_start_depth_checkpoint = clampi(_nonnegative_int(
			endless_source.get(
				"start_depth_checkpoint", endless_source.get("startDepthCheckpoint", 1)
			),
			1
		), 1, ENDLESS_MAX_SAVED_DEPTH)
		endless_resource_exhausted_through = clampi(_nonnegative_int(
			endless_source.get(
				"resource_exhausted_through",
				endless_source.get("resourceExhaustedThrough", 0)
			),
			0
		), 0, ENDLESS_MAX_SAVED_DEPTH)
		endless_active_floor_depth = clampi(_nonnegative_int(
			endless_source.get("active_floor_depth", endless_current_depth),
			endless_current_depth
		), 0, ENDLESS_MAX_SAVED_DEPTH)
		endless_active_floor_mined_mask = clampi(_nonnegative_int(
			endless_source.get("active_floor_mined_mask", 0), 0
		), 0, 2147483647)
		endless_active_floor_site_mask = clampi(_nonnegative_int(
			endless_source.get(
				"active_floor_site_mask",
				endless_source.get("activeFloorSiteMask", 0)
			),
			0
		), 0, 255)
		endless_relics = _sanitize_endless_relics(endless_source.get("relics", {}))
		carried_relic = _sanitize_carried_relic(
			endless_source.get("carried_relic", endless_source.get("carriedRelic", {})),
			endless_relics
		)
		endless_workshops = _sanitize_endless_workshops(
			endless_source.get("workshops", {}), endless_relics
		)
		endless_light_style = _sanitize_allowed_id(
			endless_source.get("light_style", endless_source.get("lightStyle", "standard")),
			ENDLESS_LIGHT_STYLE_IDS
		)
		endless_outfit = _sanitize_allowed_id(
			endless_source.get("outfit", "miner"), ENDLESS_OUTFIT_IDS
		)
		endless_tool_style = _sanitize_allowed_id(
			endless_source.get("tool_style", endless_source.get("toolStyle", "original")),
			ENDLESS_TOOL_STYLE_IDS
		)
	_normalize_endless_state()
	var raw_hub: Variant = source.get("hub", source.get("hub_state", {}))
	var saved_hub_unlocked: = (
		raw_hub is Dictionary and _strict_bool(Dictionary(raw_hub).get("unlocked", false))
	)
	hub_unlocked_early = (
		_strict_bool(source.get("hub_unlocked_early", false))
		or saved_hub_unlocked
		or not starforge_variant.is_empty()
		or drill_level > 0
		or singularity_secured
		or victory
	)
	hub = _sanitize_hub_state(raw_hub, hub_unlocked_early)
	base = _sanitize_base_state(
		source.get("base", source.get("base_state", {})),
		bool(hub.unlocked)
	)
	belt_state = _belt_rules().sanitize_state(source.get("belt_state", {}))
	world_seed = _nonnegative_int(_first_value(source, "world_seed", "worldSeed"), 0)
	discovered_mines = _sanitize_bool_map(source.get("discovered_mines", source.get("discoveredMines", {})), MINE_IDS)
	discovered_caverns = _sanitize_bool_map(
		source.get("discovered_caverns", source.get("discoveredCaverns", {})),
		_all_cavern_ids()
	)
	discovered_depth_entrances = _sanitize_bool_map(
		source.get("discovered_depth_entrances", source.get("discoveredDepthEntrances", {})),
		MINE_IDS
	)
	visited_depths = _sanitize_bool_map(
		source.get("visited_depths", source.get("visitedDepths", {})),
		MINE_IDS
	)
	claimed_pocket_rewards = _sanitize_bool_map(
		source.get("claimed_pocket_rewards", source.get("claimedPocketRewards", {})),
		_all_pocket_reward_ids()
	)
	pending_pocket_loot = _sanitize_pending_loot(
		source.get("pending_pocket_loot", source.get("pendingPocketLoot", {})),
		_all_pocket_reward_ids(),
		RESOURCE_IDS
	)
	opened_chests = _sanitize_bool_map(
		source.get("opened_chests", source.get("openedChests", {})),
		_all_chest_ids()
	)
	var chest_reward_ids: Array = RESOURCE_IDS.duplicate()
	chest_reward_ids.append("coin")
	pending_chest_loot = _sanitize_pending_loot(
		source.get("pending_chest_loot", source.get("pendingChestLoot", {})),
		_all_chest_ids(),
		chest_reward_ids
	)
	drill_goal_scene = _sanitize_allowed_id(
		_first_value(source, "drill_goal_scene", "drillGoalScene"),
		MINE_IDS
	)
	if drill_goal_scene.is_empty():
		for mine_id in MINE_IDS:
			if bool(visited_depths.get(mine_id, false)):
				drill_goal_scene = String(mine_id)
				break
	cleared_mine_barriers = _sanitize_true_flags(source.get("cleared_mine_barriers", source.get("clearedMineBarriers", {})))
	terrain_dug = _sanitize_terrain(source.get("terrain_dug", source.get("terrainDug", {})))
	_rebuild_terrain_dug_lookup()
	mine_resource_runtime = _sanitize_mine_resource_runtime(
		source.get("mine_resource_runtime", source.get("mineResourceRuntime", {}))
	)
	var surface_ore_raw: Variant = source.get("surface_ore", source.get("surfaceOre", {}))
	if surface_ore_raw is Dictionary:
		var surface_ore: Dictionary = surface_ore_raw
		surface_ore_reserve = _bounded_float(surface_ore.get("reserve", 1.0), 1.0, 0.0, 1.0)
		surface_ore_yield_buffer = _bounded_float(surface_ore.get("yield_buffer", surface_ore.get("yieldBuffer", 0.0)), 0.0, 0.0, 0.999999)
		surface_ore_gold_ready = _strict_bool(surface_ore.get("gold_ready", surface_ore.get("goldReady", true)))
		surface_ore_updated_unix = _nonnegative_int(surface_ore.get("updated_unix", surface_ore.get("updatedUnix", 0)), 0)
		var ground_loot_raw: Variant = surface_ore.get("ground_loot", surface_ore.get("groundLoot", {}))
		if ground_loot_raw is Dictionary:
			var ground_loot: Dictionary = ground_loot_raw
			surface_ore_ground_loot = {
				"copper": _nonnegative_int(ground_loot.get("copper", 0), 0),
				"gold": _nonnegative_int(ground_loot.get("gold", 0), 0),
			}
	var surface_mountains_raw: Variant = source.get(
		"surface_mountains", source.get("surfaceMountains", {})
	)
	if surface_mountains_raw is Dictionary:
		var raw_mountains: Dictionary = surface_mountains_raw
		for mountain_id_value in SURFACE_MOUNTAIN_IDS:
			var mountain_id: = String(mountain_id_value)
			if raw_mountains.has(mountain_id):
				surface_mountains[mountain_id] = _sanitize_surface_mountain(
					mountain_id, raw_mountains[mountain_id]
				)
	var canonical_vein_ids: = {}
	var surface_veins_raw: Variant = source.get("surface_veins", source.get("surfaceVeins", {}))
	if surface_veins_raw is Dictionary:
		var raw_veins: Dictionary = surface_veins_raw
		for vein_id_value in SURFACE_VEIN_IDS:
			var vein_id: = String(vein_id_value)
			if raw_veins.get(vein_id) is Dictionary:
				surface_veins[vein_id] = _sanitize_surface_vein(vein_id, raw_veins[vein_id])
				canonical_vein_ids[vein_id] = true
	var surface_moonglass_raw: Variant = source.get(
		"surface_moonglass",
		source.get("surfaceMoonglass", {})
	)
	if surface_moonglass_raw is Dictionary and not canonical_vein_ids.has("moonglass_bloom"):
		surface_veins["moonglass_bloom"] = _sanitize_surface_vein(
			"moonglass_bloom", surface_moonglass_raw
		)
	var legacy_veins_raw: Variant = source.get(
		"veins_completed",
		source.get("veinsCompleted", {})
	)
	if legacy_veins_raw is Dictionary:
		for vein_id_value in SURFACE_VEIN_IDS:
			var vein_id: = String(vein_id_value)
			var vein: Dictionary = Dictionary(surface_veins[vein_id])
			vein["completions"] = maxi(
				int(vein.completions),
				_nonnegative_int(Dictionary(legacy_veins_raw).get(vein_id, 0), 0)
			)
			surface_veins[vein_id] = vein
	_sync_moonglass_legacy_from_surface_veins()
	_load_location(source.get("location", {}))
	changed.emit()
	return true


func save_game(path: String = "") -> bool:
	var target: = path if not path.is_empty() else _save_path
	last_save_error = OK
	var encoded: = JSON.stringify(serialize(), "", true)
	if encoded.is_empty():
		last_save_error = ERR_INVALID_DATA
		return false
	var temp_path: = target + ".tmp"
	var backup_path: = target + ".bak"
	var file: = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		last_save_error = FileAccess.get_open_error()
		return false
	file.store_string(encoded)
	file.flush()
	file = null

	var target_absolute: = ProjectSettings.globalize_path(target)
	var temp_absolute: = ProjectSettings.globalize_path(temp_path)
	var backup_absolute: = ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	var had_previous: = FileAccess.file_exists(target)
	if had_previous:
		last_save_error = DirAccess.rename_absolute(target_absolute, backup_absolute)
		if last_save_error != OK:
			DirAccess.remove_absolute(temp_absolute)
			return false
	last_save_error = DirAccess.rename_absolute(temp_absolute, target_absolute)
	if last_save_error != OK:
		if had_previous and FileAccess.file_exists(backup_path):
			DirAccess.rename_absolute(backup_absolute, target_absolute)
		DirAccess.remove_absolute(temp_absolute)
		return false
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	return true


func load_game(path: String = "") -> bool:
	var target: String = path if not path.is_empty() else _save_path
	var primary: Variant = _read_save_document(target)
	if primary is Dictionary and deserialize(primary):
		last_load_status = "loaded"
		return true
	var backup_path: String = target + ".bak"
	var backup: Variant = _read_save_document(backup_path)
	if backup is Dictionary and deserialize(backup):
		last_load_status = "recovered_backup"
		return true
	_apply_defaults(false)
	world_seed = _new_world_seed()
	changed.emit()
	last_load_status = "missing" if not FileAccess.file_exists(target) else "corrupt"
	return false


func flush_save() -> bool:
	_autosave_pending = false
	return save_game()


func reset_run(persist: bool = true) -> void :
	_apply_defaults()
	if persist:
		_queue_autosave()


func start_new_run() -> void :
	_apply_defaults(false)
	world_seed = _new_world_seed()
	last_load_status = "new_game"
	changed.emit()
	if _persistence_enabled:
		save_game()


func _state_changed() -> void :
	if _state_batch_depth > 0:
		_state_batch_dirty = true
		return
	changed.emit()
	_queue_autosave()


func begin_state_batch() -> void :
	_state_batch_depth += 1


func end_state_batch() -> void :
	assert (_state_batch_depth > 0, "RunState batch underflow")
	_state_batch_depth -= 1
	if _state_batch_depth > 0 or not _state_batch_dirty:
		return
	_state_batch_dirty = false
	changed.emit()
	_queue_autosave()


func _queue_autosave() -> void :
	if not _persistence_enabled or _autosave_pending:
		return
	_autosave_pending = true
	get_tree().create_timer(AUTOSAVE_BATCH_SECONDS, true, false, true).timeout.connect(_flush_queued_autosave)


func _flush_queued_autosave() -> void :
	if not _autosave_pending:
		return
	_autosave_pending = false
	if _persistence_enabled:
		save_game()


func _apply_defaults(emit_change: bool = true) -> void :
	overhaul_progress = {}
	_commerce_transactions.clear()
	_commerce_transaction_order.clear()
	_next_commerce_transaction_id = 1
	_active_assay_transaction_id = ""
	_active_forge_transaction_id = ""
	gold = 0
	pickaxe_level = 1
	ember_mastery = 0
	drill_level = 0
	drill_goal_scene = ""
	movement_speed_level = 0
	total_swings = 0
	precision_hits = 0
	total_gold_earned = 0
	starforge_variant = ""
	starforge_unlocked = _default_starforge_unlocked()
	cargo = _empty_resource_store()
	mined = _empty_resource_store()
	area_unlocked = false
	emberdeep_unlocked = false
	fourth_unlocked = false
	victory = false
	conclusion_seen = false
	singularity_secured = false
	hub_unlocked_early = false
	deep_elevator_deliveries = _default_deep_elevator_deliveries()
	deep_elevator_repaired = false
	deep_elevator_powered = false
	final_expedition_begun = false
	deepheart_seals = _default_deepheart_seals()
	deepheart_awakened_at_mined = 0
	endless_descent_active = false
	endless_current_depth = 0
	endless_deepest_depth = 0
	endless_start_depth_checkpoint = 1
	endless_resource_exhausted_through = 0
	endless_active_floor_depth = 0
	endless_active_floor_mined_mask = 0
	endless_active_floor_site_mask = 0
	endless_relics = _default_endless_relics()
	carried_relic = _default_carried_relic()
	endless_workshops = _default_endless_workshops()
	endless_light_style = "standard"
	endless_outfit = "miner"
	endless_tool_style = "original"
	belt_state = _belt_rules().default_state()
	world_seed = 0
	hub = _default_hub_state()
	base = _default_base_state()
	discovered_mines = _default_discovered_mines()
	discovered_caverns = _default_discovered_caverns()
	discovered_depth_entrances = _default_discovered_mines()
	visited_depths = _default_discovered_mines()
	claimed_pocket_rewards = _default_claimed_pocket_rewards()
	pending_pocket_loot = {}
	opened_chests = _default_opened_chests()
	pending_chest_loot = {}
	cleared_mine_barriers = {}
	terrain_dug = _default_terrain_dug()
	_rebuild_terrain_dug_lookup()
	mine_resource_runtime = _default_mine_resource_runtime()
	current_scene = "surface"
	current_depth = 1
	current_position = DEFAULT_SURFACE_POSITION
	last_surface_position = DEFAULT_SURFACE_POSITION
	surface_ore_reserve = 1.0
	surface_ore_yield_buffer = 0.0
	surface_ore_gold_ready = true
	surface_ore_updated_unix = 0
	surface_ore_ground_loot = {"copper": 0, "gold": 0}
	surface_mountains = _default_surface_mountains()
	surface_veins = _default_surface_veins()
	_sync_moonglass_legacy_from_surface_veins()
	if emit_change:
		changed.emit()


func _new_world_seed() -> int:
	var random: = RandomNumberGenerator.new()
	random.randomize()
	var generated: = int(random.randi()) & 4294967295
	return generated if generated > 0 else 1


func _empty_resource_store() -> Dictionary:
	var store: = {}
	for resource_id in RESOURCE_IDS:
		store[resource_id] = 0
	return store


func _default_hub_state() -> Dictionary:
	return {
		"unlocked": false,
		"visited": false,
		"tutorialSeen": false,
		"buildTutorialSeen": false,
		"surfaceX": HUB_SURFACE_ENTRANCE.x,
		"surfaceY": HUB_SURFACE_ENTRANCE.y,
		"tiles": [],
	}


func _default_deep_elevator_deliveries(completed: bool = false) -> Dictionary:
	var result: = {}
	for resource_value in DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_value)
		result[resource_id] = int(DEEP_ELEVATOR_RECIPE[resource_id]) if completed else 0
	return result


func _sanitize_deep_elevator_deliveries(raw: Variant) -> Dictionary:
	var result: = _default_deep_elevator_deliveries()
	var source: Dictionary = raw if raw is Dictionary else {}
	for resource_value in DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_value)
		result[resource_id] = clampi(
			_nonnegative_int(source.get(resource_id, 0), 0),
			0,
			int(DEEP_ELEVATOR_RECIPE[resource_id])
		)
	return result


func _deep_elevator_deliveries_complete(deliveries: Dictionary) -> bool:
	for resource_value in DEEP_ELEVATOR_RECIPE:
		var resource_id: = String(resource_value)
		if int(deliveries.get(resource_id, 0)) < int(DEEP_ELEVATOR_RECIPE[resource_id]):
			return false
	return true


func _default_deepheart_seals(completed: bool = false) -> Dictionary:
	var result: = {}
	for seal_value in DEEPHEART_SEAL_IDS:
		result[String(seal_value)] = completed
	return result


func _deepheart_seals_complete(seals: Dictionary) -> bool:
	for seal_value in DEEPHEART_SEAL_IDS:
		if not bool(seals.get(String(seal_value), false)):
			return false
	return true


func _default_endless_relic_state() -> Dictionary:
	return {
		"discovered": false,
		"collected": false,
		"placed": false,
		"found_depth": 0,
	}


func _default_endless_relics() -> Dictionary:
	var result: = {}
	for relic_id_value in ENDLESS_RELIC_IDS:
		result[String(relic_id_value)] = _default_endless_relic_state()
	return result


func _default_carried_relic() -> Dictionary:
	return {
		"id": "",
		"origin_depth": 0,
		"current_depth": 0,
		"attached": false,
	}


func _default_endless_workshop_state() -> Dictionary:
	return {
		"built": false,
		"level": 0,
		"style": "original",
		"delivered": 0,
	}


func _default_endless_workshops() -> Dictionary:
	var result: = {}
	for workshop_id_value in ENDLESS_WORKSHOP_IDS:
		result[String(workshop_id_value)] = _default_endless_workshop_state()
	return result


func _sanitize_endless_relics(raw: Variant) -> Dictionary:
	var result: = _default_endless_relics()
	var source: Dictionary = raw if raw is Dictionary else {}
	for relic_id_value in ENDLESS_RELIC_IDS:
		var relic_id: = String(relic_id_value)
		var raw_state: Variant = source.get(relic_id, {})
		if not raw_state is Dictionary:
			continue
		var state_source: Dictionary = raw_state
		var discovered: = _strict_bool(state_source.get("discovered", false))
		var collected: = discovered and _strict_bool(state_source.get("collected", false))
		var placed: = collected and _strict_bool(state_source.get("placed", false))
		var found_depth: = clampi(
			_nonnegative_int(
				state_source.get("found_depth", state_source.get("foundDepth", 0)), 0
			),
			0,
			ENDLESS_MAX_SAVED_DEPTH
		)
		if discovered and found_depth <= 0:
			discovered = false
			collected = false
			placed = false
		result[relic_id] = {
			"discovered": discovered,
			"collected": collected,
			"placed": placed,
			"found_depth": found_depth if discovered else 0,
		}
	return result


func _sanitize_carried_relic(raw: Variant, relics: Dictionary) -> Dictionary:
	if not raw is Dictionary:
		return _default_carried_relic()
	var source: Dictionary = raw
	var relic_id: = _sanitize_allowed_id(source.get("id", ""), ENDLESS_RELIC_IDS)
	if relic_id.is_empty():
		return _default_carried_relic()
	var relic: Dictionary = Dictionary(relics.get(
		relic_id, _default_endless_relic_state()
	))
	if not bool(relic.get("discovered", false)) or bool(relic.get("placed", false)):
		return _default_carried_relic()
	var found_depth: = clampi(
		int(relic.get("found_depth", 0)), 1, ENDLESS_MAX_SAVED_DEPTH
	)
	var origin_depth: = clampi(
		_nonnegative_int(
			source.get("origin_depth", source.get("originDepth", found_depth)), found_depth
		),
		1,
		ENDLESS_MAX_SAVED_DEPTH
	)
	if origin_depth != found_depth:
		origin_depth = found_depth
	var current_transport_depth: = clampi(
		_nonnegative_int(
			source.get("current_depth", source.get("currentDepth", origin_depth)), origin_depth
		),
		0,
		origin_depth
	)
	relic["collected"] = true
	relics[relic_id] = relic
	return {
		"id": relic_id,
		"origin_depth": origin_depth,
		"current_depth": current_transport_depth,
		"attached": _strict_bool(source.get("attached", false)),
	}


func _sanitize_endless_workshops(raw: Variant, relics: Dictionary) -> Dictionary:
	var result: = _default_endless_workshops()
	var source: Dictionary = raw if raw is Dictionary else {}
	for workshop_id_value in ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var relic_id: = _relic_id_for_workshop(workshop_id)
		var definition: Dictionary = Dictionary(ENDLESS_RELIC_CATALOG[relic_id])
		var raw_state: Variant = source.get(workshop_id, {})
		var state_source: Dictionary = raw_state if raw_state is Dictionary else {}
		var blueprint_unlocked: = bool(Dictionary(relics.get(
			relic_id, _default_endless_relic_state()
		)).get("placed", false))
		var delivered: = clampi(
			_nonnegative_int(state_source.get("delivered", 0), 0),
			0,
			int(definition.build_cost)
		)
		var built: = blueprint_unlocked and _strict_bool(state_source.get("built", false))
		var level: = 0
		if built:
			delivered = int(definition.build_cost)
			level = clampi(
				_nonnegative_int(state_source.get("level", 1), 1),
				1,
				_workshop_max_level(workshop_id)
			)
		var style: = _sanitize_allowed_id(
			state_source.get("style", "original"), ENDLESS_WORKSHOP_STYLE_IDS
		)
		if style.is_empty() or not built or ENDLESS_WORKSHOP_STYLE_IDS.find(style) >= level:
			style = "original"
		result[workshop_id] = {
			"built": built,
			"level": level,
			"style": style,
			"delivered": delivered,
		}
	return result


func _normalize_endless_state() -> void :
	if not victory:
		endless_descent_active = false
		endless_current_depth = 0
		endless_deepest_depth = 0
		endless_start_depth_checkpoint = 1
		endless_resource_exhausted_through = 0
		endless_active_floor_depth = 0
		endless_active_floor_mined_mask = 0
		endless_active_floor_site_mask = 0
		endless_relics = _default_endless_relics()
		carried_relic = _default_carried_relic()
		endless_workshops = _default_endless_workshops()
		endless_light_style = "standard"
		endless_outfit = "miner"
		endless_tool_style = "original"
		return
	endless_deepest_depth = clampi(
		endless_deepest_depth, 0, ENDLESS_MAX_SAVED_DEPTH
	)
	endless_current_depth = clampi(
		endless_current_depth, 0, ENDLESS_MAX_SAVED_DEPTH
	)
	if endless_current_depth > endless_deepest_depth:
		endless_deepest_depth = endless_current_depth
	if endless_descent_active and endless_deepest_depth <= 0:
		endless_descent_active = false
	if not endless_descent_active:
		endless_current_depth = 0
	endless_start_depth_checkpoint = clampi(
		endless_start_depth_checkpoint, 1, maxi(1, endless_deepest_depth)
	)
	endless_resource_exhausted_through = clampi(
		endless_resource_exhausted_through, 0, endless_deepest_depth
	)
	endless_active_floor_mined_mask = clampi(
		endless_active_floor_mined_mask, 0, 2147483647
	)
	endless_active_floor_site_mask = clampi(
		endless_active_floor_site_mask, 0, 255
	)
	if not endless_descent_active or endless_current_depth <= 0:
		endless_active_floor_depth = 0
		endless_active_floor_mined_mask = 0
		endless_active_floor_site_mask = 0
	elif endless_active_floor_depth != endless_current_depth:
		endless_active_floor_depth = endless_current_depth
		endless_active_floor_mined_mask = 0
		endless_active_floor_site_mask = 0
	endless_relics = _sanitize_endless_relics(endless_relics)
	carried_relic = _sanitize_carried_relic(carried_relic, endless_relics)
	var carried_id: = String(carried_relic.get("id", ""))
	if not carried_id.is_empty():
		var transport_depth: = int(carried_relic.get("current_depth", 0))
		if not bool(carried_relic.get("attached", false)):
			transport_depth = int(carried_relic.get("origin_depth", transport_depth))
			carried_relic["current_depth"] = transport_depth
		if transport_depth > 0:
			endless_descent_active = true
			endless_current_depth = transport_depth
			endless_deepest_depth = maxi(endless_deepest_depth, transport_depth)
		elif endless_descent_active:
			endless_current_depth = 0
	endless_workshops = _sanitize_endless_workshops(
		endless_workshops, endless_relics
	)
	if _built_workshop_level("lift_workshop") <= 0:
		endless_start_depth_checkpoint = 1
	if endless_light_style not in _available_selection_options(
		"light_lab", ENDLESS_LIGHT_STYLE_IDS
	):
		endless_light_style = "standard"
	if endless_outfit not in _available_selection_options(
		"wardrobe", ENDLESS_OUTFIT_IDS
	):
		endless_outfit = "miner"
	if endless_tool_style not in _available_selection_options(
		"tool_forge", ENDLESS_TOOL_STYLE_IDS
	):
		endless_tool_style = "original"


func _relic_id_for_workshop(workshop_id: String) -> String:
	if workshop_id not in ENDLESS_WORKSHOP_IDS:
		return ""
	for relic_id_value in ENDLESS_RELIC_IDS:
		var relic_id: = String(relic_id_value)
		if String(Dictionary(ENDLESS_RELIC_CATALOG[relic_id]).workshop_id) == workshop_id:
			return relic_id
	return ""


func _workshop_upgrade_recipe(workshop_id: String, current_level: int) -> Dictionary:
	var relic_id: = _relic_id_for_workshop(workshop_id)
	var max_level: = _workshop_max_level(workshop_id)
	if relic_id.is_empty() or current_level < 1 or current_level >= max_level:
		return {}
	var definition: Dictionary = Dictionary(ENDLESS_RELIC_CATALOG[relic_id])
	var next_level: = current_level + 1
	return {
		"level": next_level,
		"resource": String(definition.build_resource),
		"cost": 50 * next_level,
	}


func _built_workshop_level(workshop_id: String) -> int:
	var relic_id: = _relic_id_for_workshop(workshop_id)
	if relic_id.is_empty():
		return 0
	var relic: Dictionary = Dictionary(endless_relics.get(
		relic_id, _default_endless_relic_state()
	))
	var workshop: Dictionary = Dictionary(endless_workshops.get(
		workshop_id, _default_endless_workshop_state()
	))
	if not bool(relic.get("placed", false)) or not bool(workshop.get("built", false)):
		return 0
	return clampi(
		int(workshop.get("level", 0)), 1, _workshop_max_level(workshop_id)
	)


func _workshop_max_level(workshop_id: String) -> int:


	return 1 if workshop_id in ["treasure_chamber", "lift_workshop"] else ENDLESS_WORKSHOP_MAX_LEVEL


func _available_selection_options(workshop_id: String, options: Array) -> Array:
	var level: = _built_workshop_level(workshop_id)
	return options.slice(0, mini(level, options.size())) if level > 0 else []


func _empty_endless_resource_snapshot() -> Dictionary:
	var carried: = {}
	var recovered: = {}
	for resource_id_value in ENDLESS_RESOURCE_IDS:
		var resource_id: = String(resource_id_value)
		carried[resource_id] = 0
		recovered[resource_id] = 0
	return {"cargo": carried, "mined": recovered}


func _endless_resource_snapshot() -> Dictionary:
	var result: = _empty_endless_resource_snapshot()
	for resource_id_value in ENDLESS_RESOURCE_IDS:
		var resource_id: = String(resource_id_value)
		result.cargo[resource_id] = maxi(0, int(cargo.get(resource_id, 0)))
		result.mined[resource_id] = maxi(0, int(mined.get(resource_id, 0)))
	return result


func _default_base_state() -> Dictionary:
	return {
		"forge": {
			"id": "forge", "kind": "forge", "scene": "surface", "depth": 1,
			"x": 455.0, "y": 250.0, "packed": false,
		},
		"sell": {
			"id": "sell", "kind": "sell", "scene": "surface", "depth": 1,
			"x": 205.0, "y": 250.0, "packed": false,
		},
		"chests": [{
			"id": "storage-1", "kind": "storage", "scene": "surface", "depth": 1,
			"x": 335.0, "y": 390.0, "packed": false, "items": _empty_resource_store(),
		}],
		"nextChestId": 2,
	}


func _sanitize_hub_state(raw: Variant, unlock_allowed: bool = false) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: = _default_hub_state()
	result["unlocked"] = unlock_allowed or _strict_bool(source.get("unlocked", false))
	result["visited"] = _strict_bool(source.get("visited", false))
	result["tutorialSeen"] = _strict_bool(source.get(
		"tutorialSeen", source.get("tutorial_seen", false)
	))
	result["buildTutorialSeen"] = _strict_bool(source.get(
		"buildTutorialSeen", source.get("build_tutorial_seen", false)
	))
	result["surfaceX"] = clampf(
		_source_coordinate(source.get("surfaceX", source.get("surface_x", HUB_SURFACE_ENTRANCE.x)), HUB_SURFACE_ENTRANCE.x),
		52.0,
		SURFACE_WORLD_SIZE.x - 52.0
	)
	result["surfaceY"] = clampf(
		_source_coordinate(source.get("surfaceY", source.get("surface_y", HUB_SURFACE_ENTRANCE.y)), HUB_SURFACE_ENTRANCE.y),
		70.0,
		SURFACE_WORLD_SIZE.y - 58.0
	)
	var clean_tiles: Array = []
	var occupied: = {}
	var raw_tiles: Variant = source.get("tiles", [])
	if raw_tiles is Array:
		for tile_value in raw_tiles:
			if not tile_value is Dictionary:
				continue
			var tile: Dictionary = tile_value
			var kind: = String(tile.get("kind", ""))
			var col: = _floor_int(tile.get("col", -1), -1)
			var row: = _floor_int(tile.get("row", -1), -1)
			var key: = "%d:%d" % [col, row]
			if kind not in ["wall", "lamp"] or not _hub_cell_in_bounds(col, row) or occupied.has(key):
				continue
			occupied[key] = true
			clean_tiles.append({"col": col, "row": row, "kind": kind})
	result["tiles"] = clean_tiles
	return result


func _sanitize_base_state(raw: Variant, hub_unlocked: bool = false) -> Dictionary:
	var fallback: = _default_base_state()
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: = fallback.duplicate(true)
	result["forge"] = _sanitize_base_module(source.get("forge", {}), fallback.forge, hub_unlocked)
	result["sell"] = _sanitize_base_module(source.get("sell", {}), fallback.sell, hub_unlocked)
	var raw_chests: Variant = source.get("chests", [])
	if raw_chests is Array and not Array(raw_chests).is_empty():
		var clean_chests: Array = []
		var seen_ids: = {"forge": true, "sell": true}
		for index in Array(raw_chests).size():
			var raw_chest: Variant = Array(raw_chests)[index]
			var chest_fallback: = {
				"id": "storage-%d" % (index + 1),
				"kind": "storage",
				"scene": "surface",
				"depth": 1,
				"x": 335.0,
				"y": 390.0,
				"packed": true,
			}
			var chest: = _sanitize_base_module(raw_chest, chest_fallback, hub_unlocked)
			var source_chest: Dictionary = raw_chest if raw_chest is Dictionary else {}
			var requested_id: = String(source_chest.get("id", "")) if source_chest.get("id", null) is String else ""
			var chest_id: = requested_id if not requested_id.is_empty() else String(chest_fallback.id)
			var suffix: = index + 1
			while seen_ids.has(chest_id):
				suffix += 1
				chest_id = "storage-%d" % suffix
			seen_ids[chest_id] = true
			chest["id"] = chest_id
			chest["kind"] = "storage"
			chest["items"] = _sanitize_resource_store(source_chest.get("items", {}))
			clean_chests.append(chest)
		result["chests"] = clean_chests
	var requested_next: = _nonnegative_int(
		source.get("nextChestId", source.get("next_chest_id", 0)), 0
	)
	result["nextChestId"] = maxi(2, maxi(Array(result.chests).size() + 1, requested_next))
	return result


func _sanitize_base_module(raw: Variant, fallback: Dictionary, hub_unlocked: bool) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: = fallback.duplicate(true)
	var scene: = String(source.get("scene", fallback.scene)) if source.get("scene", null) is String else String(fallback.scene)
	if not VALID_SCENES.has(scene):
		scene = String(fallback.scene)
	var depth: = 1 if scene in ["surface", "hub"] else (2 if _nonnegative_int(source.get("depth", 1), 1) == 2 else 1)
	var fallback_position: = Vector2(float(fallback.x), float(fallback.y))
	var position: = Vector2(
		_source_coordinate(source.get("x", fallback_position.x), fallback_position.x),
		_source_coordinate(source.get("y", fallback_position.y), fallback_position.y)
	)
	position = _clamp_module_position(scene, position)
	result["scene"] = scene
	result["depth"] = depth
	result["x"] = position.x
	result["y"] = position.y
	result["packed"] = _strict_bool(source.get("packed", fallback.get("packed", false)))
	if scene == "hub" and not hub_unlocked:
		result["packed"] = true
	return result


func _clamp_module_position(scene: String, position: Vector2) -> Vector2:
	if scene == "hub":
		return position.clamp(Vector2(52.0, 70.0), HUB_WORLD_SIZE - Vector2(52.0, 58.0))
	if scene == "surface":
		return _clamp_surface_position(position)
	if MINE_IDS.has(scene):
		var mine: Dictionary = _game_data().MINE_DEFINITIONS[scene]
		return position.clamp(Vector2(52.0, 70.0), Vector2(float(mine.width) - 52.0, float(mine.height) - 58.0))
	return position


func _clamp_surface_position(position: Vector2) -> Vector2:
	return position.clamp(Vector2(52.0, 70.0), SURFACE_WORLD_SIZE - Vector2(52.0, 58.0))


func _hub_cell_in_bounds(col: int, row: int) -> bool:
	return col >= 0 and row >= 0 and col < HUB_GRID_COLS and row < HUB_GRID_ROWS


func _hub_tile_at_cell(col: int, row: int) -> Dictionary:
	for tile_value in Array(hub.get("tiles", [])):
		var tile: Dictionary = Dictionary(tile_value)
		if int(tile.get("col", -1)) == col and int(tile.get("row", -1)) == row:
			return tile
	return {}


func _hub_module_at_cell(col: int, row: int) -> Dictionary:
	for module in _all_base_modules_internal():
		if not _module_is_at_location(module, "hub", 1):
			continue
		if hub_cell_at_world(Vector2(float(module.x), float(module.y))) == Vector2i(col, row):
			return module
	return {}


func _hub_occupant_at_cell(col: int, row: int) -> Dictionary:
	var tile: = _hub_tile_at_cell(col, row)
	return tile if not tile.is_empty() else _hub_module_at_cell(col, row)


func _all_base_modules_internal() -> Array:
	var result: Array = []
	for module_id in ["forge", "sell"]:
		var module: Variant = base.get(module_id, {})
		if module is Dictionary and not Dictionary(module).is_empty():
			result.append(module)
	for chest_value in Array(base.get("chests", [])):
		if chest_value is Dictionary:
			result.append(chest_value)
	return result


func _base_module_by_id_internal(module_id: String) -> Dictionary:
	for module in _all_base_modules_internal():
		if String(Dictionary(module).get("id", "")) == module_id:
			return Dictionary(module)
	return {}


func _write_base_module(module: Dictionary) -> void :
	var module_id: = String(module.get("id", ""))
	if module_id in ["forge", "sell"]:
		base[module_id] = module
		return
	var chests: Array = Array(base.get("chests", [])).duplicate(true)
	for index in chests.size():
		if String(Dictionary(chests[index]).get("id", "")) == module_id:
			chests[index] = module
			base["chests"] = chests
			return


func _new_storage_chest(scene: String, depth: int, position: Vector2, packed: bool) -> Dictionary:
	var next_id: = maxi(2, int(base.get("nextChestId", 2)))
	var module_id: = "storage-%d" % next_id
	while not _base_module_by_id_internal(module_id).is_empty():
		next_id += 1
		module_id = "storage-%d" % next_id
	base["nextChestId"] = next_id + 1
	return {
		"id": module_id,
		"kind": "storage",
		"scene": scene,
		"depth": 1 if scene in ["surface", "hub"] else (2 if depth == 2 else 1),
		"x": position.x,
		"y": position.y,
		"packed": packed,
		"items": _empty_resource_store(),
	}


func _module_is_at_location(module: Dictionary, scene: String, depth: int) -> bool:
	var normalized_depth: = 1 if scene in ["surface", "hub"] else (2 if depth == 2 else 1)
	return (
		not bool(module.get("packed", true))
		and String(module.get("scene", "")) == scene
		and int(module.get("depth", 1)) == normalized_depth
	)


func _base_location_allowed(scene: String, depth: int) -> bool:
	if scene == "surface":
		return true
	if scene == "hub":
		return is_hub_unlocked()
	if not MINE_IDS.has(scene) or not is_world_unlocked(String(WORLD_BY_MINE[scene])):
		return false
	return depth != 2 or _depth_restore_allowed(scene) or (current_scene == scene and current_depth == 2)


func _storage_type_count(chest: Dictionary) -> int:
	var items: Dictionary = Dictionary(chest.get("items", {}))
	var count: = 0
	for resource_id in RESOURCE_IDS:
		if int(items.get(resource_id, 0)) > 0:
			count += 1
	return count


func _default_surface_mountains() -> Dictionary:
	var result: = {}
	for mountain_id_value in SURFACE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		result[mountain_id] = _default_surface_mountain(mountain_id)
	return result


func _default_surface_mountain(mountain_id: String) -> Dictionary:
	var profile: Dictionary = Dictionary(SURFACE_MOUNTAIN_PROFILES.get(mountain_id, {}))
	if profile.is_empty():
		return {}
	var ground_loot: = {}
	for resource_id_value in Array(profile.ground_resources):
		ground_loot[String(resource_id_value)] = 0
	return {
		"reserve": 1.0,
		"yield_buffer": 0.0,
		"rare_ready": true,
		"updated_unix": 0,
		"ground_loot": ground_loot,
	}


func _sanitize_surface_mountain(mountain_id: String, raw: Variant) -> Dictionary:
	var profile: Dictionary = Dictionary(SURFACE_MOUNTAIN_PROFILES.get(mountain_id, {}))
	if profile.is_empty():
		return {}
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: = _default_surface_mountain(mountain_id)
	result["reserve"] = _bounded_float(
		source.get("reserve", 1.0), 1.0, 0.0, 1.0
	)
	result["yield_buffer"] = _bounded_float(
		source.get("yield_buffer", source.get("yieldBuffer", 0.0)),
		0.0,
		0.0,
		0.999999
	)
	var rare_ready_raw: Variant = source.get(
		"rare_ready", source.get("rareReady", true)
	)
	result["rare_ready"] = rare_ready_raw if rare_ready_raw is bool else true
	result["updated_unix"] = _nonnegative_int(
		source.get("updated_unix", source.get("updatedUnix", 0)), 0
	)
	var raw_ground: Variant = source.get("ground_loot", source.get("groundLoot", {}))
	var ground: Dictionary = raw_ground if raw_ground is Dictionary else {}
	var clean_ground_loot: = {}
	for resource_id_value in Array(profile.ground_resources):
		var resource_id: = String(resource_id_value)
		clean_ground_loot[resource_id] = _nonnegative_int(
			ground.get(resource_id, 0), 0
		)
	result["ground_loot"] = clean_ground_loot
	return result


func _default_surface_veins() -> Dictionary:
	var result: = {}
	for vein_id in SURFACE_VEIN_IDS:
		result[vein_id] = _default_surface_vein(String(vein_id))
	return result


func _default_surface_vein(vein_id: String) -> Dictionary:
	var profile: Dictionary = Dictionary(SURFACE_VEIN_PROFILES.get(vein_id, {}))
	if profile.is_empty():
		return {}
	var nodes: Array = []
	for _index in range(int(profile.node_count)):
		var node: = {"hp": int(profile.node_hp), "respawn": 0.0}
		if int(profile.node_shell) > 0:
			node["shell"] = int(profile.node_shell)
		nodes.append(node)
	var ground_loot: = {}
	for resource_id in Array(profile.ground_resources):
		ground_loot[String(resource_id)] = 0
	return {
		"nodes": nodes,
		"status": "idle",
		"timer": 0.0,
		"completions": 0,
		"updated_unix": 0,
		"ground_loot": ground_loot,
	}


func _sanitize_surface_vein(vein_id: String, raw: Variant) -> Dictionary:
	var profile: Dictionary = Dictionary(SURFACE_VEIN_PROFILES.get(vein_id, {}))
	if profile.is_empty():
		return {}
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: = _default_surface_vein(vein_id)
	var raw_nodes: Variant = source.get("nodes", [])
	if raw_nodes is Array:
		var clean_nodes: Array = Array(result.nodes)
		for index in range(mini(clean_nodes.size(), Array(raw_nodes).size())):
			if not Array(raw_nodes)[index] is Dictionary:
				continue
			var raw_node: Dictionary = Array(raw_nodes)[index]
			var raw_hp: = _nonnegative_int(raw_node.get("hp", profile.node_hp), int(profile.node_hp))
			var raw_shell: int
			if raw_node.has("shell"):
				raw_shell = _nonnegative_int(raw_node.get("shell", profile.node_shell), int(profile.node_shell))
			else:

				raw_shell = maxi(0, raw_hp - int(profile.node_hp))
				raw_hp = mini(raw_hp, int(profile.node_hp))
			var hp: = clampi(
				raw_hp,
				0,
				int(profile.node_hp)
			)
			var shell: = clampi(raw_shell, 0, int(profile.node_shell))
			if hp <= 0:
				shell = 0
			var respawn: = _bounded_float(
				raw_node.get("respawn", 0.0),
				0.0,
				0.0,
				float(profile.respawn)
			)
			var clean_node: = {"hp": hp, "respawn": respawn if hp <= 0 else 0.0}
			if int(profile.node_shell) > 0:
				clean_node["shell"] = shell
			clean_nodes[index] = clean_node
		result["nodes"] = clean_nodes
	var status: = String(source.get("status", source.get(
		"vein_status", source.get("veinStatus", "idle")
	)))
	result["status"] = status if status in ["idle", "active", "completed", "failed"] else "idle"
	result["timer"] = _bounded_float(
		source.get("timer", source.get("vein_timer", source.get("veinTimer", 0.0))),
		0.0,
		0.0,
		float(profile.time_limit)
	)
	result["completions"] = _nonnegative_int(source.get("completions", 0), 0)
	result["updated_unix"] = _nonnegative_int(
		source.get("updated_unix", source.get("updatedUnix", 0)),
		0
	)
	var clean_ground_loot: = {}
	var raw_ground: Variant = source.get("ground_loot", source.get("groundLoot", {}))
	var ground: Dictionary = raw_ground if raw_ground is Dictionary else {}
	for resource_id in Array(profile.ground_resources):
		clean_ground_loot[String(resource_id)] = _nonnegative_int(
			ground.get(String(resource_id), 0), 0
		)
	result["ground_loot"] = clean_ground_loot
	return result


func _sync_moonglass_legacy_from_surface_veins() -> void :
	var moon: = _sanitize_surface_vein(
		"moonglass_bloom",
		surface_veins.get("moonglass_bloom", {})
	)
	surface_veins["moonglass_bloom"] = moon
	surface_moonglass_nodes = []
	for node_value in Array(moon.nodes):
		var node: Dictionary = Dictionary(node_value)
		surface_moonglass_nodes.append({
			"hp": int(node.hp),
			"respawn": float(node.respawn),
		})
	surface_moonglass_vein_status = String(moon.status)
	surface_moonglass_vein_timer = float(moon.timer)
	surface_moonglass_completions = int(moon.completions)
	surface_moonglass_updated_unix = int(moon.updated_unix)
	surface_moonglass_ground_loot = Dictionary(moon.ground_loot).duplicate(true)


func _sync_surface_veins_from_legacy_moonglass() -> void :
	surface_veins["moonglass_bloom"] = _sanitize_surface_vein("moonglass_bloom", {
		"nodes": surface_moonglass_nodes,
		"status": surface_moonglass_vein_status,
		"timer": surface_moonglass_vein_timer,
		"completions": surface_moonglass_completions,
		"updated_unix": surface_moonglass_updated_unix,
		"ground_loot": surface_moonglass_ground_loot,
	})


func _default_surface_moonglass_nodes() -> Array:
	return Array(_default_surface_vein("moonglass_bloom").nodes).duplicate(true)


func _sanitize_surface_moonglass_nodes(raw: Array) -> Array:
	var result: Array = []
	for node_value in Array(_sanitize_surface_vein("moonglass_bloom", {"nodes": raw}).nodes):
		var node: Dictionary = Dictionary(node_value)
		result.append({"hp": int(node.hp), "respawn": float(node.respawn)})
	return result


func _default_discovered_mines() -> Dictionary:
	var result: = {}
	for mine_id in MINE_IDS:
		result[mine_id] = false
	return result


func _default_starforge_unlocked() -> Dictionary:
	var result: = {}
	for variant_id in STARFORGE_VARIANT_IDS:
		result[variant_id] = false
	return result


func _default_discovered_caverns() -> Dictionary:
	var result: = {}
	for cavern_id in _all_cavern_ids():
		result[cavern_id] = false
	return result


func _default_claimed_pocket_rewards() -> Dictionary:
	var result: = {}
	for reward_id in _all_pocket_reward_ids():
		result[reward_id] = false
	return result


func _default_opened_chests() -> Dictionary:
	var result: = {}
	for chest_id in _all_chest_ids():
		result[chest_id] = false
	return result


func _default_terrain_dug() -> Dictionary:
	var result: = {}
	for mine_id in MINE_IDS:
		result[mine_id] = []
		result[_terrain_key(mine_id, 2)] = []
	return result


func _rebuild_terrain_dug_lookup() -> void :
	terrain_dug_lookup.clear()
	for key_value in terrain_dug:
		var key: = String(key_value)
		var lookup: = {}
		for cell_index_value in Array(terrain_dug[key]):
			lookup[int(cell_index_value)] = true
		terrain_dug_lookup[key] = lookup


func _default_mine_runtime_scope() -> Dictionary:
	return {"depleted": {}, "loose_loot": [], "next_drop_id": 1}


func _default_mine_resource_runtime() -> Dictionary:
	var result: = {}
	for mine_id in MINE_IDS:
		for depth in [1, 2]:
			result[_mine_runtime_key(String(mine_id), depth)] = _default_mine_runtime_scope()
	return result


func _mine_runtime_key(mine_id: String, depth: int) -> String:
	return "%s:%d" % [mine_id, 2 if depth == 2 else 1]


func _depth_one_resource_node_kinds(mine_id: String) -> Dictionary:
	if not MINE_IDS.has(mine_id):
		return {}
	var data: = _game_data()
	var mine: Dictionary = Dictionary(Dictionary(data.MINE_DEFINITIONS).get(mine_id, {}))
	if mine.is_empty():
		return {}
	var cols: = ceili(float(mine.get("width", 0.0)) / MINE_TILE_SIZE)
	if cols <= 0:
		return {}
	var result: = {}



	for rock_value in Array(mine.get("rocks", [])):
		var rock: Array = Array(rock_value)
		if rock.size() < 3:
			continue
		var col: = floori(float(rock[1]) / MINE_TILE_SIZE)
		var row: = floori(float(rock[2]) / MINE_TILE_SIZE)
		var node_id: = "cell:%d" % (row * cols + col)
		var role: = String(rock[3]) if rock.size() > 3 else "resource"
		if role == "resource":
			result[node_id] = String(rock[0])
		else:
			result.erase(node_id)
	var discoveries: Dictionary = Dictionary(Dictionary(data.MINE_DISCOVERIES).get(mine_id, {}))
	for rock_value in Array(discoveries.get("rocks", [])):
		var rock: Dictionary = Dictionary(rock_value)
		var col: = floori(float(rock.get("x", 0.0)) / MINE_TILE_SIZE)
		var row: = floori(float(rock.get("y", 0.0)) / MINE_TILE_SIZE)
		result["cell:%d" % (row * cols + col)] = String(rock.get("type", ""))
	return result


func _mine_resource_node_kind(mine_id: String, depth: int, node_id: String) -> String:
	if not MINE_IDS.has(mine_id):
		return ""
	if depth != 2:
		return String(_depth_one_resource_node_kinds(mine_id).get(node_id, ""))
	if not node_id.begins_with("rock:"):
		return ""
	var raw_index: = node_id.trim_prefix("rock:")
	if not raw_index.is_valid_int():
		return ""
	var index: = int(raw_index)
	var discoveries: Dictionary = Dictionary(
		Dictionary(_game_data().MINE_DEPTH_DISCOVERIES).get(mine_id, {})
	)
	var rocks: Array = Array(discoveries.get("rocks", []))
	if index < 0 or index >= rocks.size():
		return ""
	return String(Dictionary(rocks[index]).get("type", ""))


func _clamp_mine_runtime_position(mine_id: String, position: Vector2) -> Vector2:
	var mine: Dictionary = Dictionary(Dictionary(_game_data().MINE_DEFINITIONS).get(mine_id, {}))
	var bounds: = Vector2(
		maxf(0.0, float(mine.get("width", 0.0))),
		maxf(0.0, float(mine.get("height", 0.0)))
	)
	return position.clamp(Vector2.ZERO, bounds)


func _sanitize_mine_resource_runtime(raw: Variant) -> Dictionary:
	var result: = _default_mine_resource_runtime()
	if not raw is Dictionary:
		return result
	var source: Dictionary = raw
	var now: = int(Time.get_unix_time_from_system())
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		for depth in [1, 2]:
			var key: = _mine_runtime_key(mine_id, depth)
			var raw_scope: Variant = source.get(key, {})
			if not raw_scope is Dictionary:
				continue
			var scope_source: Dictionary = raw_scope
			var scope: = _default_mine_runtime_scope()
			var depleted: = {}
			var raw_depleted: Variant = scope_source.get("depleted", {})
			if raw_depleted is Dictionary:
				for node_id_value in Dictionary(raw_depleted):
					var node_id: = String(node_id_value)
					var kind: = _mine_resource_node_kind(mine_id, depth, node_id)
					if kind.is_empty():
						continue
					var raw_record: Variant = Dictionary(raw_depleted)[node_id_value]
					var raw_until: Variant = (
						Dictionary(raw_record).get("respawn_until_unix", 0)
						if raw_record is Dictionary
						else raw_record
					)
					var respawn_until: = _nonnegative_int(raw_until, 0)
					if raw_record is Dictionary:
						var saved_kind: = String(Dictionary(raw_record).get("kind", kind))
						if saved_kind != kind:
							continue
					if respawn_until <= now:
						continue
					var rock_profile: Dictionary = Dictionary(_game_data().ROCK_TYPES.get(kind, {}))
					var maximum_until: = now + maxi(0, int(rock_profile.get("respawn", 0)))
					depleted[node_id] = {
						"kind": kind,
						"respawn_until_unix": mini(respawn_until, maximum_until)
					}
			scope["depleted"] = depleted

			var loose_loot: Array = []
			var highest_drop_id: = 0
			var raw_loot: Variant = scope_source.get("loose_loot", [])
			if raw_loot is Array:
				for raw_drop in Array(raw_loot):
					if not raw_drop is Dictionary:
						continue
					var drop_source: Dictionary = raw_drop
					var drop_id: = String(drop_source.get("id", ""))
					var kind: = String(drop_source.get("kind", ""))
					if not drop_id.is_valid_int() or int(drop_id) <= 0 or kind not in RESOURCE_IDS:
						continue
					var amount: = clampi(
						_nonnegative_int(drop_source.get("amount", 0), 0),
						0,
						MAX_MINE_LOOSE_DROP_AMOUNT
					)
					if amount <= 0:
						continue
					var position: = _clamp_mine_runtime_position(mine_id, Vector2(
						_safe_coordinate(drop_source.get("x", 0.0), 0.0),
						_safe_coordinate(drop_source.get("y", 0.0), 0.0)
					))
					var duplicate_id: = false
					for existing_value in loose_loot:
						if String(Dictionary(existing_value).get("id", "")) == drop_id:
							duplicate_id = true
							break
					if duplicate_id:
						continue
					var clean_drop: = {
						"id": drop_id,
						"kind": kind,
						"amount": amount,
						"x": position.x,
						"y": position.y,
					}
					if loose_loot.size() < MAX_MINE_LOOSE_DROPS_PER_SCOPE:
						loose_loot.append(clean_drop)
					else:


						var merged: = false
						for index in loose_loot.size():
							var existing: Dictionary = Dictionary(loose_loot[index])
							if String(existing.kind) != kind:
								continue
							existing.amount = mini(
								MAX_MINE_LOOSE_DROP_AMOUNT,
								int(existing.amount) + amount
							)
							loose_loot[index] = existing
							merged = true
							break
						if not merged:
							var first_by_kind: = {}
							for index in loose_loot.size():
								var existing: Dictionary = Dictionary(loose_loot[index])
								var existing_kind: = String(existing.kind)
								if not first_by_kind.has(existing_kind):
									first_by_kind[existing_kind] = index
									continue
								var first_index: = int(first_by_kind[existing_kind])
								var first: Dictionary = Dictionary(loose_loot[first_index])
								first.amount = mini(
									MAX_MINE_LOOSE_DROP_AMOUNT,
									int(first.amount) + int(existing.amount)
								)
								loose_loot[first_index] = first
								loose_loot.remove_at(index)
								loose_loot.append(clean_drop)
								break
					highest_drop_id = maxi(highest_drop_id, int(drop_id))
			scope["loose_loot"] = loose_loot
			scope["next_drop_id"] = maxi(
				highest_drop_id + 1,
				_nonnegative_int(scope_source.get("next_drop_id", 1), 1)
			)
			result[key] = scope
	return result


func _terrain_key(mine_id: String, depth: int) -> String:
	return mine_id + "Depth2" if depth == 2 else mine_id


func _moss_rules() -> RefCounted:
	if _mossvein_progression == null:
		_mossvein_progression = MossveinProgressionScript.new(_game_data())
	return _mossvein_progression


func _belt_rules() -> RefCounted:
	if _belt_network == null:
		_belt_network = BeltNetworkScript.new(HUB_GRID_COLS, HUB_GRID_ROWS)
	return _belt_network


func _all_cavern_ids() -> Array:
	var result: Array = []
	var data: = _game_data()
	for mine_id in MINE_IDS:
		for discoveries_key in ["MINE_DISCOVERIES", "MINE_DEPTH_DISCOVERIES"]:
			for cavern_value in Array(data[discoveries_key][mine_id].caverns):
				result.append(String(Dictionary(cavern_value).id))
	return result


func _all_pocket_reward_ids() -> Array:
	var result: Array = []
	var data: = _game_data()
	for mine_id in MINE_IDS:
		for discoveries_key in ["MINE_DISCOVERIES", "MINE_DEPTH_DISCOVERIES"]:
			for cavern_value in Array(data[discoveries_key][mine_id].caverns):
				result.append(String(Dictionary(cavern_value).reward.id))
	return result


func _all_chest_ids() -> Array:
	var result: Array = []
	for chest_value in Array(_game_data().CHEST_DEFINITIONS):
		result.append(String(Dictionary(chest_value).id))
	return result


func _commit_pocket_reward(reward_id: String, deposit_cleared: bool) -> Dictionary:
	if is_pocket_reward_claimed(reward_id):
		return {"ok": false, "reason": "already_claimed", "reward_id": reward_id}
	var definition: Dictionary = _moss_rules().pocket_reward(reward_id)
	if definition.is_empty():
		return {"ok": false, "reason": "unknown_reward", "reward_id": reward_id}
	var cavern_id: = String(definition.cavern_id)
	if not is_cavern_discovered(cavern_id):
		return {
			"ok": false,
			"reason": "cavern_hidden",
			"reward_id": reward_id,
			"cavern_id": cavern_id,
		}
	var plan: Dictionary = _moss_rules().pocket_claim_plan(reward_id, deposit_cleared)
	if not bool(plan.get("ok", false)):
		return plan
	claimed_pocket_rewards[reward_id] = true
	var pending: Dictionary = Dictionary(plan.pending_loot).duplicate(true)
	if not pending.is_empty():
		pending_pocket_loot[reward_id] = pending
	_state_changed()
	return plan


func _commit_mossvein_pocket_reward(reward_id: String, deposit_cleared: bool) -> Dictionary:

	return _commit_pocket_reward(reward_id, deposit_cleared)


func _sanitize_resource_store(raw: Variant) -> Dictionary:
	var result: = _empty_resource_store()
	if not raw is Dictionary:
		return result
	var source: Dictionary = raw
	for resource_id in RESOURCE_IDS:
		result[resource_id] = _nonnegative_int(source.get(resource_id, 0), 0)
	return result


func _sanitize_bool_map(raw: Variant, allowed_keys: Array) -> Dictionary:
	var result: = {}
	var source: Dictionary = raw if raw is Dictionary else {}
	for key in allowed_keys:
		result[key] = _strict_bool(source.get(key, false))
	return result


func _sanitize_allowed_id(raw: Variant, allowed_ids: Array) -> String:
	if not raw is String:
		return ""
	var value: = String(raw)
	return value if allowed_ids.has(value) else ""


func _sanitize_pending_loot(
	raw: Variant,
	allowed_container_ids: Array,
	allowed_reward_ids: Array
) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary:
		return result
	var source: Dictionary = raw
	for container_id in allowed_container_ids:
		var raw_loot: Variant = source.get(container_id, {})
		if not raw_loot is Dictionary:
			continue
		var sanitized: Dictionary = {}
		for reward_id in allowed_reward_ids:
			var amount: = _nonnegative_int(Dictionary(raw_loot).get(reward_id, 0), 0)
			if amount > 0:
				sanitized[reward_id] = amount
		if not sanitized.is_empty():
			result[container_id] = sanitized
	return result


func _sanitize_true_flags(raw: Variant) -> Dictionary:
	var result: = {}
	if not raw is Dictionary:
		return result
	for key in raw:
		if key is String and not String(key).is_empty() and _strict_bool(raw[key]):
			result[key] = true
	return result


func _sanitize_terrain(raw: Variant) -> Dictionary:
	var result: = _default_terrain_dug()
	if not raw is Dictionary:
		return result
	for key in result:
		var raw_cells = raw.get(key, [])
		if not raw_cells is Array:
			continue
		var seen: = {}
		var cells: Array[int] = []
		for raw_index in raw_cells:
			var index: = -1
			if raw_index is int or raw_index is float:
				var numeric_index: = float(raw_index)
				if is_finite(numeric_index) and numeric_index >= 0.0:
					index = int(numeric_index)
			if index >= 0 and not seen.has(index):
				seen[index] = true
				cells.append(index)
		cells.sort()
		result[key] = cells
	return result


func _load_location(raw: Variant) -> void :
	if not raw is Dictionary:
		return
	var location: Dictionary = raw
	var requested_scene: = String(location.get("scene", "surface"))
	var requested_depth: = _nonnegative_int(location.get("depth", 1), 1)
	var requested_position: = Vector2(
		_safe_coordinate(location.get("x", DEFAULT_SURFACE_POSITION.x), DEFAULT_SURFACE_POSITION.x),
		_safe_coordinate(location.get("y", DEFAULT_SURFACE_POSITION.y), DEFAULT_SURFACE_POSITION.y)
	)
	var surface_position: = Vector2(
		_safe_coordinate(location.get("surface_x", location.get("surfaceX", DEFAULT_SURFACE_POSITION.x)), DEFAULT_SURFACE_POSITION.x),
		_safe_coordinate(location.get("surface_y", location.get("surfaceY", DEFAULT_SURFACE_POSITION.y)), DEFAULT_SURFACE_POSITION.y)
	)
	if _valid_vector(surface_position):
		last_surface_position = _clamp_surface_position(surface_position)

	current_scene = "surface"
	current_depth = 1
	if MINE_IDS.has(requested_scene):
		var requested_world: = String(WORLD_BY_MINE[requested_scene])
		if is_world_unlocked(requested_world):
			current_scene = requested_scene
	elif requested_scene == "hub" and is_hub_unlocked():
		current_scene = "hub"
	elif requested_scene == "deepheart" and _deepheart_restore_allowed():
		current_scene = "deepheart"
	elif requested_scene == "endless" and victory and endless_descent_active:
		current_scene = "endless"

	if MINE_IDS.has(current_scene):
		if requested_depth == 2 and _depth_restore_allowed(current_scene):
			current_depth = 2
			current_position = requested_position
		elif requested_depth == 2:


			var mine: Dictionary = _game_data().MINE_DEFINITIONS[current_scene]
			current_position = Vector2(float(mine.entrance.x) + 85.0, float(mine.entrance.y))
		else:
			current_position = requested_position
	elif current_scene == "hub":
		var hub_position: = Vector2(
			_source_coordinate(location.get("x", HUB_PLAYER_SPAWN.x), HUB_PLAYER_SPAWN.x),
			_source_coordinate(location.get("y", HUB_PLAYER_SPAWN.y), HUB_PLAYER_SPAWN.y)
		)
		current_position = hub_position.clamp(
			Vector2(52.0, 70.0),
			HUB_WORLD_SIZE - Vector2(52.0, 58.0)
		)
	elif current_scene == "deepheart":
		var deepheart_position: = Vector2(
			_source_coordinate(
				location.get("x", DEEPHEART_PLAYER_SPAWN.x),
				DEEPHEART_PLAYER_SPAWN.x
			),
			_source_coordinate(
				location.get("y", DEEPHEART_PLAYER_SPAWN.y),
				DEEPHEART_PLAYER_SPAWN.y
			)
		)
		current_position = deepheart_position.clamp(
			Vector2(52.0, 70.0),
			DEEPHEART_WORLD_SIZE - Vector2(52.0, 58.0)
		)
	elif current_scene == "endless":
		current_position = requested_position
	elif requested_scene == "surface" or not VALID_SCENES.has(requested_scene):
		current_position = requested_position
	else:

		current_position = last_surface_position

	if current_scene == "surface" and (requested_scene == "surface" or not VALID_SCENES.has(requested_scene)):
		last_surface_position = current_position


func _depth_restore_allowed(mine_id: String) -> bool:
	if not MINE_IDS.has(mine_id):
		return false
	if not is_world_unlocked(String(WORLD_BY_MINE[mine_id])):
		return false
	if not is_depth_entrance_discovered(mine_id) or not is_depth_visited(mine_id):
		return false
	if mine_id == "starMine":
		return drill_level == Array(_game_data().DRILLS).size() - 1
	return true


func _deepheart_restore_allowed() -> bool:
	return victory or (deep_elevator_powered and final_expedition_begun)


func _read_save_document(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var file: = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser: = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return null
	var parsed: Variant = parser.data
	return parsed if parsed is Dictionary else null


func _forge_purchase_snapshot_for_kind(requested_kind: String) -> Dictionary:
	var purchase_kind: = requested_kind
	var pickaxe_upgrade: = next_pickaxe()
	var mastery_upgrade: = next_ember_mastery()
	if purchase_kind.is_empty():
		purchase_kind = (
			"pickaxe" if not pickaxe_upgrade.is_empty()
			else "ember_mastery" if not mastery_upgrade.is_empty()
			else "complete"
		)
	var current_card: Dictionary
	var next_card: Dictionary = {}
	var target_level: = pickaxe_level
	var target_rank: = ember_mastery
	var gold_required: = 0
	var resource_requirements: Array = []
	var locked: = false
	var lock_reason: = ""
	if purchase_kind == "pickaxe":
		if pickaxe_upgrade.is_empty():
			return _empty_forge_purchase_snapshot("pickaxe", "pickaxe_complete")
		target_level = pickaxe_level + 1
		current_card = _forge_pickaxe_card(current_pickaxe(), pickaxe_level)
		next_card = _forge_pickaxe_card(pickaxe_upgrade, target_level)
		gold_required = maxi(0, int(pickaxe_upgrade.get("cost", 0)))
		var final_pickaxe_level: = Array(_game_data().PICKAXES).size() - 1
		if target_level == final_pickaxe_level:
			var emberstone_required: = maxi(0, int(_game_data().EMBER_PICKAXE_ORE_REQUIRED))
			resource_requirements.append(_commerce_resource_cost_row(
				"emberstone", emberstone_required
			))
			locked = not emberdeep_unlocked
			lock_reason = "emberdeep_locked" if locked else ""
	elif purchase_kind == "ember_mastery":
		if mastery_upgrade.is_empty():
			return _empty_forge_purchase_snapshot("ember_mastery", "mastery_complete")
		var mastery_rows: Array = Array(_game_data().EMBER_MASTERY)
		var current_mastery: Dictionary = Dictionary(
			mastery_rows[clampi(ember_mastery, 0, mastery_rows.size() - 1)]
		)
		current_card = _forge_mastery_card(current_mastery)
		next_card = _forge_mastery_card(mastery_upgrade)
		target_rank = int(mastery_upgrade.get("rank", ember_mastery + 1))
		gold_required = maxi(0, int(mastery_upgrade.get("gold", 0)))
		resource_requirements.append(_commerce_resource_cost_row(
			"sunslag", maxi(0, int(mastery_upgrade.get("sunslag", 0)))
		))
	elif purchase_kind == "complete":
		return _empty_forge_purchase_snapshot("complete", "complete")
	else:
		return _empty_forge_purchase_snapshot(purchase_kind, "invalid_purchase_kind")
	var gold_row: = _commerce_gold_cost_row(gold_required)
	var resources_ready: = true
	for requirement_value in resource_requirements:
		if not bool(Dictionary(requirement_value).get("enough", false)):
			resources_ready = false
			break
	var gold_ready: = bool(gold_row.get("enough", false))
	var ready: = not locked and gold_ready and resources_ready
	var reason: = "ready"
	if locked:
		reason = lock_reason
	elif not gold_ready and not resources_ready:
		reason = "missing_gold_and_resources"
	elif not resources_ready:
		reason = "missing_resources"
	elif not gold_ready:
		reason = "missing_gold"
	var requirements: Array = [gold_row.duplicate(true)]
	for resource_value in resource_requirements:
		requirements.append(Dictionary(resource_value).duplicate(true))
	return {
		"transaction_kind": "forge_purchase",
		"purchase_kind": purchase_kind,
		"pickaxe_level_before": pickaxe_level,
		"ember_mastery_before": ember_mastery,
		"target_level": target_level,
		"target_rank": target_rank,
		"current": current_card,
		"next": next_card,
		"stats": _forge_stat_rows(current_card, next_card),
		"cost": {
			"gold": gold_row,
			"resources": resource_requirements,
			"requirements": requirements,
		},
		"gold_owned": int(gold_row.owned),
		"gold_required": int(gold_row.required),
		"gold_missing": int(gold_row.missing),
		"ready": ready,
		"locked": locked,
		"lock_reason": lock_reason,
		"reason": reason,
	}


func _empty_forge_purchase_snapshot(purchase_kind: String, reason: String) -> Dictionary:
	var current_card: = _forge_pickaxe_card(current_pickaxe(), pickaxe_level)
	var gold_row: = _commerce_gold_cost_row(0)
	return {
		"transaction_kind": "forge_purchase",
		"purchase_kind": purchase_kind,
		"pickaxe_level_before": pickaxe_level,
		"ember_mastery_before": ember_mastery,
		"target_level": pickaxe_level,
		"target_rank": ember_mastery,
		"current": current_card,
		"next": {},
		"stats": [],
		"cost": {"gold": gold_row, "resources": [], "requirements": []},
		"gold_owned": gold,
		"gold_required": 0,
		"gold_missing": 0,
		"ready": false,
		"locked": false,
		"lock_reason": "",
		"reason": reason,
	}


func _forge_pickaxe_card(tool: Dictionary, level: int) -> Dictionary:
	if tool.is_empty():
		return {}
	var texture_path: = _pickaxe_texture_path(level)
	return {
		"id": "pickaxe:%d" % level,
		"name": String(tool.get("name", "Pickaxe")),
		"level": level,
		"rank": ember_mastery if level == pickaxe_level else 0,
		"power": maxi(0, int(tool.get("power", 0))),
		"cooldown": maxf(0.0, float(tool.get("cooldown", 0.0))),
		"texture_path": texture_path,
		"texture_name": texture_path.get_file() if not texture_path.is_empty() else "",
	}


func _forge_mastery_card(mastery: Dictionary) -> Dictionary:
	var rank: = maxi(0, int(mastery.get("rank", 0)))
	var texture_path: = _pickaxe_texture_path(Array(_game_data().PICKAXES).size() - 1)
	return {
		"id": "ember_mastery:%d" % rank,
		"name": "Ember Pickaxe · %s" % String(mastery.get("label", "Mastery %d" % rank)),
		"level": Array(_game_data().PICKAXES).size() - 1,
		"rank": rank,
		"power": maxi(0, int(mastery.get("power", 0))),
		"cooldown": maxf(0.0, float(mastery.get("cooldown", 0.0))),
		"shell_power": maxf(0.0, float(mastery.get("shellPower", mastery.get("shell_power", 0.0)))),
		"yield_bonus": maxf(0.0, float(mastery.get("bonusYield", mastery.get("yield_bonus", 0.0)))),
		"precision_delay": maxf(0.0, float(mastery.get("precisionDelay", mastery.get("precision_delay", 0.0)))),
		"texture_path": texture_path,
		"texture_name": texture_path.get_file() if not texture_path.is_empty() else "",
	}


func _forge_stat_rows(current_card: Dictionary, next_card: Dictionary) -> Array:
	var rows: Array = []
	var specs: Array = [
		{"id": "power", "label": "POWER", "higher_is_better": true},
		{"id": "cooldown", "label": "SWING TIME", "higher_is_better": false},
		{"id": "shell_power", "label": "SHELL POWER", "higher_is_better": true},
		{"id": "yield_bonus", "label": "BONUS YIELD", "higher_is_better": true},
		{"id": "precision_delay", "label": "PRECISION DELAY", "higher_is_better": false},
	]
	for spec_value in specs:
		var spec: Dictionary = Dictionary(spec_value)
		var stat_id: = String(spec.id)
		if not current_card.has(stat_id) and not next_card.has(stat_id):
			continue
		var current_value: = float(current_card.get(stat_id, 0.0))
		var next_value: = float(next_card.get(stat_id, 0.0))
		var delta: = next_value - current_value
		var higher_is_better: = bool(spec.higher_is_better)
		rows.append({
			"id": stat_id,
			"label": String(spec.label),
			"current": current_value,
			"next": next_value,
			"delta": delta,
			"higher_is_better": higher_is_better,
			"improves": delta > 0.0 if higher_is_better else delta < 0.0,
		})
	return rows


func _commerce_gold_cost_row(required: int) -> Dictionary:
	var safe_required: = maxi(0, required)
	var texture_path: = GOLD_TEXTURE_PATH if ResourceLoader.exists(GOLD_TEXTURE_PATH) else ""
	return {
		"kind": "gold",
		"name": "Gold",
		"texture_path": texture_path,
		"texture_name": texture_path.get_file() if not texture_path.is_empty() else "",
		"owned": gold,
		"required": safe_required,
		"missing": maxi(0, safe_required - gold),
		"enough": gold >= safe_required,
	}


func _commerce_resource_cost_row(kind: String, required: int) -> Dictionary:
	var safe_required: = maxi(0, required)
	var owned: = maxi(0, int(cargo.get(kind, 0)))
	var rock: Dictionary = Dictionary(Dictionary(_game_data().ROCK_TYPES).get(kind, {}))
	var texture_path: = _resource_drop_texture_path(kind)
	return {
		"kind": kind,
		"name": String(rock.get("label", kind.capitalize())),
		"texture_path": texture_path,
		"texture_name": texture_path.get_file() if not texture_path.is_empty() else "",
		"owned": owned,
		"required": safe_required,
		"missing": maxi(0, safe_required - owned),
		"enough": owned >= safe_required,
	}


func _resource_drop_texture_path(kind: String) -> String:
	var texture_path: = "res://assets/drops/%s-drop.png" % kind
	if ResourceLoader.exists(texture_path):
		return texture_path
	var fallback_path: = String(RESOURCE_TEXTURE_FALLBACKS.get(kind, ""))
	return fallback_path if not fallback_path.is_empty() and ResourceLoader.exists(fallback_path) else ""


func _pickaxe_texture_path(level: int) -> String:
	if level < 0 or level >= PICKAXE_TEXTURE_PATHS.size():
		return ""
	var texture_path: = String(PICKAXE_TEXTURE_PATHS[level])
	return texture_path if not texture_path.is_empty() and ResourceLoader.exists(texture_path) else ""


func _create_commerce_transaction(kind: String, snapshot: Dictionary) -> Dictionary:
	var transaction_id: = "%s:%d" % [kind, _next_commerce_transaction_id]
	_next_commerce_transaction_id += 1
	var transaction: = {
		"id": transaction_id,
		"kind": kind,
		"state": "pending",
		"snapshot": snapshot.duplicate(true),
		"result": {},
	}
	_commerce_transactions[transaction_id] = transaction
	_commerce_transaction_order.append(transaction_id)
	_prune_commerce_transactions()
	return transaction


func _pending_commerce_transaction(transaction_id: String, kind: String) -> Dictionary:
	if transaction_id.is_empty():
		return {}
	var value: Variant = _commerce_transactions.get(transaction_id, {})
	if not value is Dictionary:
		return {}
	var transaction: Dictionary = value
	if String(transaction.get("kind", "")) != kind or String(transaction.get("state", "")) != "pending":
		return {}
	return transaction


func _commerce_begin_result(transaction: Dictionary, reused: bool) -> Dictionary:
	var result: Dictionary = Dictionary(transaction.get("snapshot", {})).duplicate(true)
	result["ok"] = true
	result["transaction_id"] = String(transaction.get("id", ""))
	result["state"] = String(transaction.get("state", "pending"))
	result["reused"] = reused
	return result


func _commerce_commit_result(transaction: Dictionary, already_committed: bool) -> Dictionary:
	var result: Dictionary = Dictionary(transaction.get("snapshot", {})).duplicate(true)
	result.merge(Dictionary(transaction.get("result", {})).duplicate(true), true)
	result["ok"] = true
	result["transaction_id"] = String(transaction.get("id", ""))
	result["state"] = "committed"
	result["already_committed"] = already_committed
	return result


func _commerce_error(transaction_id: String, reason: String) -> Dictionary:
	return {
		"ok": false,
		"transaction_id": transaction_id,
		"state": "failed",
		"reason": reason,
		"already_committed": false,
	}


func _cancel_commerce_transaction(transaction_id: String, reason: String) -> void :
	var value: Variant = _commerce_transactions.get(transaction_id, {})
	if not value is Dictionary:
		return
	var transaction: Dictionary = value
	transaction["state"] = "cancelled"
	transaction["reason"] = reason
	_commerce_transactions[transaction_id] = transaction
	if _active_assay_transaction_id == transaction_id:
		_active_assay_transaction_id = ""
	if _active_forge_transaction_id == transaction_id:
		_active_forge_transaction_id = ""


func _cancel_pending_commerce_transaction(
	transaction_id: String,
	kind: String,
	reason: String
) -> bool:
	var transaction: = _pending_commerce_transaction(transaction_id, kind)
	if transaction.is_empty():
		return false
	_cancel_commerce_transaction(transaction_id, reason)
	return true


func _prune_commerce_transactions() -> void :
	while _commerce_transaction_order.size() > COMMERCE_TRANSACTION_HISTORY_LIMIT:
		var removable_index: = -1
		for index in _commerce_transaction_order.size():
			var transaction_id: = String(_commerce_transaction_order[index])
			var transaction: Dictionary = Dictionary(_commerce_transactions.get(transaction_id, {}))
			if String(transaction.get("state", "")) != "pending":
				removable_index = index
				break
		if removable_index < 0:
			return
		var removed_id: = String(_commerce_transaction_order[removable_index])
		_commerce_transaction_order.remove_at(removable_index)
		_commerce_transactions.erase(removed_id)


func _game_data() -> Dictionary:
	if not _game_data_cache.is_empty():
		return _game_data_cache
	var file: = FileAccess.open(GAME_DATA_PATH, FileAccess.READ)
	assert (file != null, "Missing production data: %s" % GAME_DATA_PATH)
	var parsed = JSON.parse_string(file.get_as_text())
	assert (parsed is Dictionary, "Invalid production data: %s" % GAME_DATA_PATH)
	_game_data_cache = Dictionary(parsed)
	return _game_data_cache


func _first_value(source: Dictionary, snake_key: String, camel_key: String = "") -> Variant:
	if source.has(snake_key):
		return source[snake_key]
	if not camel_key.is_empty() and source.has(camel_key):
		return source[camel_key]
	return null


func _nonnegative_int(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		var number: = float(value)
		if is_finite(number):
			return maxi(0, int(number))
	return fallback


func _floor_int(value: Variant, fallback: int) -> int:
	if value is int or value is float:
		var number: = float(value)
		if is_finite(number):
			return floori(number)
	return fallback


func _strict_bool(value: Variant) -> bool:
	return value is bool and value


func _safe_coordinate(value: Variant, fallback: float) -> float:
	if value is int or value is float:
		var number: = float(value)
		if is_finite(number) and absf(number) <= 10000000.0:
			return number
	return fallback


func _source_coordinate(value: Variant, fallback: float) -> float:
	var number: = _safe_coordinate(value, fallback)
	return fallback if is_zero_approx(number) else number


func _bounded_float(value: Variant, fallback: float, minimum: float, maximum: float) -> float:
	if value is int or value is float:
		var number: = float(value)
		if is_finite(number):
			return clampf(number, minimum, maximum)
	return fallback


func _valid_vector(value: Vector2) -> bool:
	return is_finite(value.x) and is_finite(value.y) and absf(value.x) <= 10000000.0 and absf(value.y) <= 10000000.0


func _sanitize_overhaul(raw: Variant) -> Dictionary:
	if not raw is Dictionary:
		return {}
	var result: Dictionary = {}
	for key in ["barriers", "dug", "skills"]:
		var source: Variant = raw.get(key, {})
		var rows: Dictionary = {}
		if source is Dictionary:
			for id in source:
				if rows.size() >= 20000:
					break
				if key == "dug" and source[id] is Array:
					var cells: Array = []
					for value in source[id]:
						var cell: int = clampi(int(value),0,879)
						if not cells.has(cell): cells.append(cell)
					rows[String(id)] = cells
				elif key != "dug":
					rows[String(id)] = clampi(int(source[id]),0,10 if key == "barriers" else 1)
		result[key] = rows
	result["companion_xp"] = clampi(int(raw.get("companion_xp",0)),0,10000000)
	return result


func barrier_hits(key: String) -> int:
	return int(Dictionary(overhaul_progress.get("barriers",{})).get(key,0))


func strike_barrier(key: String) -> int:
	var rows: Dictionary = overhaul_progress.get("barriers",{})
	var hits: int = mini(10,int(rows.get(key,0))+1)
	rows[key] = hits
	overhaul_progress["barriers"] = rows
	_state_changed()
	return hits


func endless_dug_cells(depth: int) -> Array:
	return Array(Dictionary(overhaul_progress.get("dug",{})).get(str(depth),[])).duplicate()


func mark_endless_dug(depth: int, cell: int) -> void:
	var depths: Dictionary = overhaul_progress.get("dug",{})
	var cells: Array = depths.get(str(depth),[])
	if not cells.has(cell): cells.append(cell)
	depths[str(depth)] = cells
	overhaul_progress["dug"] = depths
	_state_changed()


static func light_range_for_level(level: int) -> float:
	return 1.0 + 0.08 * float(clampi(level, 0, 5))

static func light_energy_for_level(level: int) -> float:
	return 1.0 + 0.06 * float(clampi(level, 0, 5))
