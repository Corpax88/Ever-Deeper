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
const SAVE_RETRY_SECONDS: = 6.0

var records: Dictionary = {}
var definition_cache: Array = []
var evaluation_pending: = false
var last_save_error: int = OK
var last_load_status: String = "not_initialized"
var _record_save_pending: bool = false
var _record_save_timer_serial: int = 0


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not _dev_storage_active():
		apply_storage_epoch_reset(LEGACY_STORAGE_PATH, STORAGE_EPOCH_MARKER_PATH)
	_load_records()
	definition_cache = Array(GameData.data.get("ACHIEVEMENT_DEFINITIONS", [])).duplicate(true)
	RunState.changed.connect(_queue_evaluation)
	RunState.miner_skill_increased.connect(_on_miner_skill_increased)
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


func _on_miner_skill_increased(id: String, _level: int) -> void:
	if id == "running": _queue_evaluation()


func _flush_queued_evaluation() -> void :
	if not evaluation_pending:
		return
	evaluation_pending = false
	evaluate()


func _condition_met(id: String, metrics: Dictionary) -> bool:
	var total_mined: = int(metrics.total_mined)
	var terrain_tiles: = int(metrics.terrain_tiles)
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
		"vein_runner": return vein_total >= 1
		"fourfold_veins": return _completed_all_veins(vein_counts)
		"vein_veteran": return vein_total >= 10
		"quick_step": return RunState.miner_skill_level("running") >= 1 or int(RunState.movement_speed_level) >= 1
		"roadrunner": return RunState.miner_skill_level("running") >= 10 or int(RunState.movement_speed_level) >= 10
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


func _load_records() -> void :
	var path: String = _storage_path()
	var document: Variant = _read_record_document(path)
	var recovered: bool = false
	if document == null:
		document = _read_record_document(path + ".bak")
		recovered = document != null
	if document == null:
		last_load_status = "corrupt" if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak") else "missing"
		return
	records.merge(Dictionary(document.records), true)
	last_load_status = "recovered_backup" if recovered else "loaded"
	if recovered: _queue_record_save()


func _read_record_document(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return null
	var parsed: Variant = parser.data
	if not parsed is Dictionary or not parsed.get("records") is Dictionary:
		return null
	var restored: Dictionary = {}
	for id in parsed.records:
		if not Dictionary(GameData.data.ACHIEVEMENT_BY_ID).has(String(id)): continue
		var timestamp: Variant = parsed.records[id]
		if not (timestamp is int or timestamp is float) or not is_finite(float(timestamp)): return null
		restored[String(id)] = maxi(0, int(timestamp))
	return {"records":restored}


func _save_records() -> bool:
	_record_save_timer_serial += 1
	_record_save_pending = false
	last_save_error = OK
	var saved: bool = _write_records(_storage_path())
	if not saved: _queue_record_save()
	return saved


func _write_records(path: String) -> bool:
	var temporary: String = path + ".tmp"
	var backup: String = path + ".bak"
	var payload: PackedByteArray = JSON.stringify({"records":records}).to_utf8_buffer()
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_save_error = FileAccess.get_open_error()
		return false
	file.store_buffer(payload)
	file.flush()
	last_save_error = file.get_error()
	file = null
	if last_save_error != OK or FileAccess.get_file_as_bytes(temporary) != payload or _read_record_document(temporary) == null:
		if last_save_error == OK: last_save_error = ERR_FILE_CORRUPT
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	# Only a valid committed primary can replace the previous good generation.
	var rotate: bool = _read_record_document(path) != null
	if rotate:
		if FileAccess.file_exists(backup):
			last_save_error = DirAccess.remove_absolute(ProjectSettings.globalize_path(backup))
			if last_save_error != OK:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
				return false
		last_save_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(backup))
		if last_save_error != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
			return false
	last_save_error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if last_save_error != OK:
		if rotate: DirAccess.rename_absolute(ProjectSettings.globalize_path(backup), ProjectSettings.globalize_path(path))
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return false
	return true


func _queue_record_save() -> void:
	if _record_save_pending: return
	_record_save_pending = true
	_record_save_timer_serial += 1
	get_tree().create_timer(SAVE_RETRY_SECONDS, true, false, true).timeout.connect(_retry_record_save.bind(_record_save_timer_serial))


func _retry_record_save(serial: int) -> void:
	if not _record_save_pending or serial != _record_save_timer_serial: return
	_save_records()


func _storage_path() -> String:
	return DEV_STORAGE_PATH if _dev_storage_active() else STORAGE_PATH


func _dev_storage_active() -> bool:
	return OS.has_feature("ever_deeper_dev") or "--qa-dev-tools" in OS.get_cmdline_user_args()
