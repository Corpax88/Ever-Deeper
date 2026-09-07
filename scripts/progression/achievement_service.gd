extends Node

signal updated
signal achievement_unlocked(definition: Dictionary)

const STORAGE_PATH: = "user://ever_deeper_achievements_v2.json"
const DEV_STORAGE_PATH: = "user://ever_deeper_dev_achievements_v2.json"
const LEGACY_STORAGE_PATH: = "user://ever_deeper_achievements_v1.json"
const STORAGE_EPOCH_MARKER_PATH: = "user://ever_deeper_achievement_epoch_v2.applied"
const SaveEpochScript: = preload("res://scripts/state/save_epoch.gd")
const MINE_IDS: = ["mossMine", "moonMine", "emberMine", "starMine"]
const DEEP_RESOURCES: = [
	"deepstone", "rootiron", "ambercore", "burrowsteel", "prismite", "lunacore",
	"phasecrystal", "magmaite", "furnaceheart", "infernium", "voidglass", "singularity",
]
const EVALUATION_BATCH_SECONDS: = 0.2

var records: Dictionary = {}
var definition_cache: Array = []
var evaluation_pending: = false


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _dev_storage_active():
		apply_storage_epoch_reset(LEGACY_STORAGE_PATH, STORAGE_EPOCH_MARKER_PATH)
	_load_records()
	definition_cache = Array(GameData.data.get("ACHIEVEMENT_DEFINITIONS", [])).duplicate(true)
	RunState.changed.connect(_queue_evaluation)
	call_deferred("evaluate")


func apply_storage_epoch_reset(legacy_path: String, marker_path: String) -> bool:


	return SaveEpochScript.apply_once(
		legacy_path,
		marker_path,
		"ever_deeper_achievement_epoch=2\n"
	)


func definitions() -> Array:
	if definition_cache.is_empty():
		definition_cache = Array(GameData.data.get("ACHIEVEMENT_DEFINITIONS", [])).duplicate(true)
	return definition_cache.duplicate(true)


func unlocked_count() -> int:
	return records.size()


func is_unlocked(id: String) -> bool:
	return records.has(id)


func evaluate() -> void :
	var vein_counts: = _vein_completion_counts()
	var metrics: = {
		"total_mined": _total_mined(),
		"terrain_tiles": _terrain_tiles_dug(),
		"opened": _true_count(RunState.opened_chests),
		"vein_counts": vein_counts,
		"vein_total": _sum_values(vein_counts),
		"endless": _endless_status(),
	}
	var changed: = false
	for value in definition_cache:
		var definition: = Dictionary(value)
		var id: = String(definition.id)
		if records.has(id) or not _condition_met(id, metrics):
			continue
		records[id] = int(Time.get_unix_time_from_system())
		changed = true
		achievement_unlocked.emit(definition)
	if changed:
		_save_records()
		updated.emit()


func _queue_evaluation() -> void :
	if evaluation_pending:
		return
	evaluation_pending = true
	get_tree().create_timer(EVALUATION_BATCH_SECONDS, true, false, true).timeout.connect(_flush_queued_evaluation)


func _flush_queued_evaluation() -> void :
	if not evaluation_pending:
		return
	evaluation_pending = false
	evaluate()


func _condition_met(id: String, metrics: Dictionary) -> bool:
	var total_mined: = int(metrics.total_mined)
	var terrain_tiles: = int(metrics.terrain_tiles)
	var opened: = int(metrics.opened)
	var vein_counts: Dictionary = metrics.vein_counts
	var vein_total: = int(metrics.vein_total)
	var endless: Dictionary = Dictionary(metrics.get("endless", {}))
	match id:
		"first_chip": return total_mined >= 1
		"first_payday": return int(RunState.total_gold_earned) >= 1
		"moon_unsealed": return bool(RunState.area_unlocked)
		"ember_unsealed": return bool(RunState.emberdeep_unlocked)
		"stars_unsealed": return bool(RunState.fourth_unlocked)
		"four_frontiers": return bool(RunState.area_unlocked) and bool(RunState.emberdeep_unlocked) and bool(RunState.fourth_unlocked)
		"minewalker": return _all_true(RunState.discovered_mines, MINE_IDS)
		"seasoned_arms": return int(RunState.total_swings) >= 100
		"iron_rhythm": return int(RunState.total_swings) >= 1000
		"keen_eye": return int(RunState.precision_hits) >= 10
		"true_aim": return int(RunState.precision_hits) >= 100
		"tunnel_hand": return terrain_tiles >= 100
		"earth_eater": return terrain_tiles >= 1000
		"ore_mountain": return total_mined >= 1000
		"goldspark": return _mined("gold") >= 1
		"fallen_star": return _mined("starshard") >= 1
		"sunstruck": return _mined("sunslag") >= 1
		"crowned": return _mined("crownstone") >= 1
		"into_the_deep": return _mined("deepstone") >= 1
		"three_hearts": return _all_mined(["ambercore", "lunacore", "furnaceheart"])
		"drillborn_ore": return _all_mined(["burrowsteel", "phasecrystal", "infernium"])
		"deep_hoard": return int(endless.get("placed_relic_count", 0)) >= 1
		"ironbound": return int(RunState.pickaxe_level) >= 2
		"rune_ready": return int(RunState.pickaxe_level) >= 3
		"moonforged": return int(RunState.pickaxe_level) >= 4
		"emberforged": return int(RunState.pickaxe_level) >= 5
		"depth_master": return int(RunState.ember_mastery) >= 5
		"starforged": return _true_count(RunState.starforge_unlocked) >= 1
		"threefold_star": return _true_count(RunState.starforge_unlocked) >= 3
		"burrower": return int(RunState.drill_level) >= 1
		"pulse_driver": return int(RunState.drill_level) >= 2
		"deepcore": return int(RunState.drill_level) >= 3
		"moss_below": return bool(RunState.discovered_mines.get("mossMine", false))
		"glass_below": return bool(RunState.discovered_mines.get("moonMine", false))
		"fire_below": return bool(RunState.discovered_mines.get("emberMine", false))
		"stars_below": return bool(RunState.discovered_mines.get("starMine", false))
		"hidden_descent": return _true_count(RunState.discovered_depth_entrances) >= 1
		"every_depth": return _all_true(RunState.visited_depths, MINE_IDS)
		"treasure_found": return opened >= 1
		"cache_hunter": return opened >= 4
		"chestmaster": return opened >= 8
		"vein_runner": return vein_total >= 1
		"fourfold_veins": return _completed_all_veins(vein_counts)
		"vein_veteran": return vein_total >= 10
		"quick_step": return int(RunState.movement_speed_level) >= 1
		"roadrunner": return int(RunState.movement_speed_level) >= 10
		"more_storage": return int(endless.get("built_workshop_count", 0)) >= 1
		"mobile_base": return (
			int(endless.get("total_workshops", 0)) >= 5
			and int(endless.get("built_workshop_count", 0)) >= int(endless.get("total_workshops", 0))
		)
		"mineral_crown": return _all_mined(Array(RunState.RESOURCE_IDS))
		"ever_deeper": return bool(RunState.victory)
	return false


func _total_mined() -> int:
	var result: = 0
	for amount in RunState.mined.values():
		result += int(amount)
	return result


func _sum_mined(ids: Array) -> int:
	var result: = 0
	for id in ids:
		result += _mined(String(id))
	return result


func _endless_status() -> Dictionary:
	if RunState.has_method("endless_descent_status"):
		return Dictionary(RunState.endless_descent_status())
	return {}


func _sum_values(values: Dictionary) -> int:
	var result: = 0
	for amount in values.values():
		result += int(amount)
	return result


func _mined(id: String) -> int:
	return int(RunState.mined.get(id, 0))


func _all_mined(ids: Array) -> bool:
	for id in ids:
		if _mined(String(id)) <= 0:
			return false
	return not ids.is_empty()


func _true_count(values: Dictionary) -> int:
	var result: = 0
	for value in values.values():
		if bool(value):
			result += 1
	return result


func _all_true(values: Dictionary, ids: Array) -> bool:
	for id in ids:
		if not bool(values.get(id, false)):
			return false
	return true


func _terrain_tiles_dug() -> int:
	var result: = 0
	for cells in RunState.terrain_dug.values():
		result += Array(cells).size()
	return result


func _vein_completion_counts() -> Dictionary:
	var result: = {}
	for vein_id in RunState.surface_vein_ids():
		result[String(vein_id)] = int(RunState.surface_vein_state(String(vein_id)).get("completions", 0))
	return result


func _completed_all_veins(counts: Dictionary) -> bool:
	for amount in counts.values():
		if int(amount) <= 0:
			return false
	return counts.size() >= 3


func _has_mobile_base_module() -> bool:
	for value in RunState.all_base_modules():
		var module: = Dictionary(value)
		if not bool(module.get("packed", true)) and String(module.get("scene", "surface")) in MINE_IDS:
			return true
	return false


func _load_records() -> void :
	var storage_path: = _storage_path()
	if not FileAccess.file_exists(storage_path):
		return
	var file: = FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		for id in Dictionary(parsed).get("records", {}):
			records[String(id)] = maxi(0, int(Dictionary(parsed).records[id]))


func _save_records() -> void :
	var file: = FileAccess.open(_storage_path(), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"records": records}))


func _storage_path() -> String:
	return DEV_STORAGE_PATH if _dev_storage_active() else STORAGE_PATH


func _dev_storage_active() -> bool:
	return OS.has_feature("ever_deeper_dev") or "--qa-dev-tools" in OS.get_cmdline_user_args()
