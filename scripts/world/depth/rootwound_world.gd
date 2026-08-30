class_name RootwoundWorld
extends Node2D

signal exit_context_changed(active: bool)
signal context_changed(context: String)
signal station_context_changed(kind: String)
signal depth_exit_requested
signal station_activated(kind: String)
signal message_changed(message: String)
signal resource_revealed(kind: String, deposit_id: String)
signal resource_mined(kind: String, amount: int)
signal cavern_discovered(cavern_id: String, cavern_name: String)
signal pocket_reward_claimed(reward_id: String, reward_kind: String)
signal depth_loaded(mine_id: String)
signal drill_gate_cleared(gate_id: String, required_drill_level: int)
signal final_resource_mined(resource_id: String)

const RootwoundLayoutScript = preload("res://scripts/world/depth/rootwound_layout.gd")
const HeadlampBeamScript = preload("res://scripts/lighting/headlamp_beam.gd")
const DropVisuals = preload("res://scripts/world/drop_visuals.gd")
const CrusherDebrisScript = preload("res://scripts/world/crusher_debris.gd")
const CrusherLootBurstScript = preload("res://scripts/world/crusher_loot_burst.gd")

const MINE_ID: = "mossMine"
const SUPPORTED_MINE_IDS: = ["mossMine", "moonMine", "emberMine", "starMine"]
const DEPTH: = 2
const TILE_SIZE: = 48.0
const PLAYER_RADIUS: = 23.0
const MINING_RANGE: = 116.0
const REDRAW_INTERVAL: = 1.0 / 30.0
const ROCK_RESPAWN_CHECK_INTERVAL: = 0.1
const SHAFT_CONTEXT_RADIUS: = 118.0
const MINING_RUSH_DURATION: = 30.0
const SHRINE_RESPAWN_SECONDS: = 75.0
const MINING_RUSH_COOLDOWN_MULTIPLIER: = 0.65
const HEAT_STREAK_BUILD_SECONDS: = 5.0
const HEAT_STREAK_MAX_SPEED: = 1.3
const UPWARD_MINING_VISUAL_CYCLE: = 0.5
const LOOSE_RESOURCE_LIFETIME: = 50.0
const LOOSE_RESOURCE_FADE_SECONDS: = 3.0
const DROP_MAGNET_DELAY: = 0.16
const DROP_MAGNET_SPEED: = 720.0
const DROP_MAGNET_COLLECT_RADIUS: = 28.0
const MAX_ACTIVE_IMPACTS: = 6
const MAX_ACTIVE_LANDMARK_LIGHTS: = 4
const LANDMARK_LIGHT_ENTER_RADIUS: = 640.0
const LANDMARK_LIGHT_EXIT_RADIUS: = 760.0
const LANDMARK_LIGHT_REFRESH_DISTANCE: = 120.0
const LANDMARK_LIGHT_HYSTERESIS_BONUS: = 105.0

const UNIQUE_CAVERN_NAMES: = {
	"mossMine": [
		"Deep Forgotten Pocket", "Deep Rootbound Hollow", "Deep Old Prospector Room", 
		"Deep Echo Chamber", "Deep Buried Camp", "Deep Gilded Hollow", 
		"Taproot Reliquary", "Amberwake Vault", 
	], 
	"moonMine": [
		"Deep Prism Pocket", "Deep Silent Grotto", "Deep Glasswater Hollow", 
		"Deep Moonlit Fault", "Deep Crystal Nest", "Deep Lost Survey", 
		"Deep Starshard Grotto", "Refraction Archive", "Lunar Prism Vault", 
	], 
	"emberMine": [
		"Deep Cinder Pocket", "Deep Ashen Vault", "Deep Collapsed Furnace", 
		"Deep Heatwell Hollow", "Deep Old Smelter", "Deep Burning Grotto", 
		"Deep Magma Scar", "Deep Crucible Pocket", "Furnaceheart Reliquary", 
		"Cinder Crown Vault", 
	], 
	"starMine": [
		"Deep Fallen Pocket", "Deep Silent Orbit", "Deep Astral Hollow", 
		"Deep Void Grotto", "Deep Lost Observatory", "Deep Starlight Vault", 
		"Deep Crown Scar", "Deep Celestial Nest", "Deep Last Light Chamber", 
		"Eventide Reliquary", "Singularity Antechamber", 
	], 
}

const LAMP_TEXTURE: = preload("res://assets/entrances/depth-work-lamp.png")

@export var standalone_interaction_enabled: = false

@onready var player: CharacterBody2D = $Player
@onready var darkness: CanvasModulate = $Darkness
@onready var landmark_lights: Node2D = $LandmarkLights

var mine: Dictionary = {}
var mine_id: = MINE_ID
var depth_profile: Dictionary = {}
var discoveries: Dictionary = {}
var world_size: = Vector2.ZERO
var cols: = 0
var rows: = 0
var terrain_max_hp: = 320
var terrain_hp: = PackedInt32Array()
var dug_indices: Dictionary = {}
var caverns: Array[Dictionary] = []
var concealed_cells: Dictionary = {}
var rocks: Array[Dictionary] = []
var rocks_by_cell: Dictionary = {}
var drops: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var claimed_rewards: Dictionary = {}
var shrine_cooldowns: Dictionary = {}

var depth_entrance: = Vector2.ZERO
var station_positions: Dictionary = {}
var exit_context: = false
var station_context: = ""
var active_context: = ""
var active: = false
var external_mine_held: = false
var swing_active: = false
var swing_elapsed: = 0.0
var swing_duration: = 0.72
var swing_hit: = false
var mining_rush_remaining: = 0.0
var heat_streak_elapsed: = 0.0
var heat_streak_active: = false
var mining_visual_elapsed: = 0.0
var mining_visual_running: = false

var current_target_kind: = ""
var current_target_cell: = Vector2i(-1, -1)
var current_target_rock: = -1
var target_dirty: = true
var redraw_requested: = true
var redraw_elapsed: = REDRAW_INTERVAL
var rock_respawn_check_elapsed: = ROCK_RESPAWN_CHECK_INTERVAL
var last_draw_cell: = Vector2i(-9999, -9999)
var manual_depth_entrance: = Vector2.ZERO
var manual_depth_entrance_enabled: = false
var deep_tool_override_enabled: = false
var deep_tool_override_value: = false
var tool_stats_override: Dictionary = {}
var floor_texture: Texture2D
var wall_texture: Texture2D
var shaft_texture: Texture2D
var sell_texture: Texture2D
var forge_texture: Texture2D
var impact_texture: Texture2D
var pocket_texture: Texture2D
var cache_texture: Texture2D
var shrine_texture: Texture2D
var resource_textures: Dictionary = {}
var wall_hint_textures: Dictionary = {}
var drop_textures: Dictionary = {}
var landmark_light_specs: Array[Dictionary] = []
var active_landmark_light_ids: Array[String] = []
var last_landmark_light_refresh_position: = Vector2(INF, INF)
var landmark_light_refresh_count: = 0
var landmark_light_rebuild_count: = 0
var shared_landmark_light_texture: Texture2D
var interior_initialized: = false
var interior_build_count: = 0
var configured_world_seed: = -1
var inactive_state_fingerprint: = 0
var inactive_state_fingerprint_valid: = false


func _ready() -> void :
	player.moved.connect(_on_player_moved)
	player.facing_changed.connect(_on_player_facing_changed)


func _ensure_interior_initialized() -> void :
	if interior_initialized:
		return
	_build_world()
	_configure_player(entry_spawn())
	player.set_facing(Vector2.RIGHT)
	_build_lighting()
	interior_initialized = true
	queue_redraw()


func load_depth(next_mine_id: String, entrance: Vector2 = Vector2(INF, INF)) -> bool:
	if next_mine_id not in SUPPORTED_MINE_IDS:
		push_warning("Unsupported Depth 2 mine: %s" % next_mine_id)
		return false
	var next_manual_entrance_enabled: = is_finite(entrance.x) and is_finite(entrance.y)
	var next_manual_entrance: = manual_depth_entrance
	if next_manual_entrance_enabled:
		var next_mine_data: Dictionary = GameData.mine(next_mine_id)
		var next_bounds: = Vector2(float(next_mine_data.width), float(next_mine_data.height))
		var next_cell: = Vector2i(floori(entrance.x / TILE_SIZE), floori(entrance.y / TILE_SIZE))
		next_manual_entrance = ((Vector2(next_cell) + Vector2(0.5, 0.5)) * TILE_SIZE).clamp(
			Vector2.ONE * TILE_SIZE * 0.5, next_bounds - Vector2.ONE * TILE_SIZE * 0.5
		)
	var can_reuse_interior: = (
		interior_initialized
		and not active
		and next_mine_id == mine_id
		and configured_world_seed == int(RunState.world_seed)
		and next_manual_entrance_enabled == manual_depth_entrance_enabled
		and ( not next_manual_entrance_enabled or next_manual_entrance.is_equal_approx(manual_depth_entrance))
		and inactive_state_fingerprint_valid
		and inactive_state_fingerprint == _persistent_state_fingerprint()
	)
	if can_reuse_interior:
		depth_loaded.emit(mine_id)
		return true
	mine_id = next_mine_id
	manual_depth_entrance_enabled = next_manual_entrance_enabled
	if manual_depth_entrance_enabled:
		manual_depth_entrance = next_manual_entrance
	_reset_heat_streak()
	_reset_mining_visual_phase()
	if interior_initialized:
		_rebuild_after_layout_change()
	else:
		_ensure_interior_initialized()
	depth_loaded.emit(mine_id)
	return true


func configure_mine(next_mine_id: String) -> bool:
	return load_depth(next_mine_id)


func configured_mine_id() -> String:
	return mine_id


func configure_depth_entrance(position: Vector2) -> void :
	manual_depth_entrance_enabled = true
	manual_depth_entrance = _snap_to_cell_center(position)
	_rebuild_after_layout_change()


func use_deterministic_depth_entrance() -> void :
	manual_depth_entrance_enabled = false
	_rebuild_after_layout_change()


func rebuild_from_run_state() -> void :
	if not interior_initialized:
		return
	_build_world()
	if is_node_ready():
		_configure_player(entry_spawn())
		_build_lighting()
	_request_redraw()


func set_deep_tool_available(enabled: bool) -> void :
	deep_tool_override_enabled = true
	deep_tool_override_value = enabled
	target_dirty = true


func use_run_state_deep_tool() -> void :
	deep_tool_override_enabled = false
	target_dirty = true


func set_tool_stats(stats: Dictionary) -> void :
	tool_stats_override = stats.duplicate(true)


func clear_tool_stats() -> void :
	tool_stats_override.clear()


func set_active(enabled: bool, entering: bool = false) -> void :
	if enabled:
		_ensure_interior_initialized()
	if active and not enabled:
		_persist_loose_drop_positions()
		_capture_inactive_state_fingerprint()
	active = enabled
	visible = enabled
	process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	player.control_enabled = enabled
	player.camera.enabled = enabled
	if enabled:
		player.prepare_visual_cache()
	else:
		player.release_visual_cache()
	external_mine_held = false
	if not enabled:
		_reset_heat_streak()
		_reset_mining_visual_phase()
		player.set_mining_visual(false)
	if entering:
		player.global_position = entry_spawn()
		player.set_facing(Vector2.RIGHT)
		_set_context("")
	if enabled:
		player.camera.make_current()
		player.camera.reset_smoothing()
		_update_context(player.global_position)
		_refresh_landmark_lights(true)
	_request_redraw()


func restore_position(position: Vector2) -> void :
	player.global_position = _nearest_safe_position(position)
	player.camera.reset_smoothing()
	_on_player_moved(player.global_position)


func _nearest_safe_position(position: Vector2) -> Vector2:
	var preferred: = position.clamp(Vector2.ONE * PLAYER_RADIUS, world_size - Vector2.ONE * PLAYER_RADIUS)
	if not _player_collides(preferred):
		return preferred
	var origin_cell: = _world_to_cell(preferred)
	for distance in range(1, 13):
		for row_offset in range( - distance, distance + 1):
			var col_distance: = distance - absi(row_offset)
			for col_offset in ([0] if col_distance == 0 else [ - col_distance, col_distance]):
				var cell: = origin_cell + Vector2i(int(col_offset), row_offset)
				if not _cell_in_bounds(cell):
					continue
				var candidate: = _cell_center(cell)
				if not _player_collides(candidate):
					return candidate
	var fallback: = entry_spawn().clamp(Vector2.ONE * PLAYER_RADIUS, world_size - Vector2.ONE * PLAYER_RADIUS)
	return fallback


func set_mine_held(held: bool) -> void :
	external_mine_held = held
	if not held:
		_reset_heat_streak()


func set_external_movement(direction: Vector2) -> void :
	player.set_external_movement(direction)


func entry_spawn() -> Vector2:
	return RootwoundLayoutScript.entry_spawn(GameData.data, depth_entrance, mine_id)


func current_context() -> String:
	return active_context


func get_station_positions() -> Dictionary:
	return station_positions.duplicate(true)


func guide_target(resource_id: String = "") -> Vector2:
	if RunState.victory and mine_id == "starMine":
		return depth_entrance
	var best: = Vector2.ZERO
	var best_distance: = INF
	for index in rocks.size():
		if not _rock_is_exposed(index):
			continue
		var rock: Dictionary = rocks[index]
		if not resource_id.is_empty() and String(rock.type) != resource_id:
			continue
		var position: = Vector2(rock.position)
		var distance: = player.global_position.distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best = position
	if best != Vector2.ZERO:
		return best
	var status: Dictionary = RunState.drill_upgrade_status()
	if bool(status.get("ready", false)) or int(status.get("missing_gold", 0)) > 0:
		return Vector2(station_positions.forge if bool(status.get("ready", false)) else station_positions.sell)
	return depth_entrance


func get_drill_gates() -> Array[Dictionary]:
	var gates_by_id: = {}
	for rock in rocks:
		if not bool(rock.drill_gated):
			continue
		var gate_id: = String(rock.deposit_id)
		if not gates_by_id.has(gate_id):
			gates_by_id[gate_id] = {
				"id": gate_id, 
				"type": String(rock.type), 
				"required_drill_level": int(rock.requires_drill_level), 
				"positions": [], 
				"remaining": 0, 
			}
		var gate: Dictionary = Dictionary(gates_by_id[gate_id])
		gate.positions.append(Vector2(rock.position))
		if not bool(rock.broken):
			gate.remaining = int(gate.remaining) + 1
		gates_by_id[gate_id] = gate
	var result: Array[Dictionary] = []
	for gate_id in gates_by_id:
		result.append(Dictionary(gates_by_id[gate_id]).duplicate(true))
	result.sort_custom( func(left: Dictionary, right: Dictionary) -> bool: return String(left.id) < String(right.id))
	return result


func perform_context() -> String:
	match active_context:
		"depthExit":
			depth_exit_requested.emit()
			return "depthExit"
		"depthSell":
			station_activated.emit("sell")
			var earned: = RunState.sell_all()
			message_changed.emit("ORE EXCHANGED · %d GOLD" % earned if earned > 0 else "NO SELLABLE ORE")
			return "depthSell"
		"drillForge":
			station_activated.emit("forge")
			message_changed.emit("DRILL FORGE · choose the next drill upgrade")
			return "drillForge"
	return ""


func mine_once() -> bool:
	if current_target_kind.is_empty():
		_apply_target(_find_mine_target())
	match current_target_kind:
		"terrain":
			return _hit_terrain(current_target_cell)
		"rock":
			return _hit_rock(current_target_rock)
	message_changed.emit("Face a nearby %s wall before mining" % _depth_short_name())
	return false


func collision_at(position: Vector2) -> bool:
	return _player_collides(position)


func export_runtime_state() -> Dictionary:
	return {
		"mining_rush_remaining": mining_rush_remaining, 
		"shrine_cooldowns": shrine_cooldowns.duplicate(true),
	}


func import_runtime_state(state: Dictionary) -> void :
	mining_rush_remaining = maxf(0.0, float(state.get("mining_rush_remaining", 0.0)))
	shrine_cooldowns.clear()
	var saved_cooldowns: Dictionary = Dictionary(state.get("shrine_cooldowns", {}))
	for reward_id_value in saved_cooldowns:
		var reward_id: = String(reward_id_value)
		var remaining: = clampf(float(saved_cooldowns[reward_id_value]), 0.0, SHRINE_RESPAWN_SECONDS)
		if remaining > 0.0 and String(_reward_by_id(reward_id).get("kind", "")) == "shrine":
			shrine_cooldowns[reward_id] = remaining
	_reset_heat_streak()
	_sync_claimed_rewards_from_run_state()
	_apply_claimed_pocket_rocks()
	_request_redraw()


func _process(delta: float) -> void :
	if not active:
		return
	if target_dirty:
		_apply_target(_find_mine_target())
		target_dirty = false
	_update_mining(delta)
	rock_respawn_check_elapsed += maxf(0.0, delta)
	if rock_respawn_check_elapsed >= ROCK_RESPAWN_CHECK_INTERVAL:
		rock_respawn_check_elapsed = fposmod(rock_respawn_check_elapsed, ROCK_RESPAWN_CHECK_INTERVAL)
		_update_rocks()
	_update_drops(delta)
	_update_impacts(delta)
	_update_shrine_cooldowns(delta)
	_update_pocket_rewards()
	if mining_rush_remaining > 0.0:
		mining_rush_remaining = maxf(0.0, mining_rush_remaining - delta)
	if standalone_interaction_enabled and Input.is_action_just_pressed("interact"):
		perform_context()


func _update_shrine_cooldowns(delta: float) -> void:
	var changed: = false
	for reward_id_value in shrine_cooldowns.keys():
		var reward_id: = String(reward_id_value)
		var remaining: = maxf(0.0, float(shrine_cooldowns[reward_id]) - maxf(0.0, delta))
		if remaining <= 0.0:
			shrine_cooldowns.erase(reward_id)
			changed = true
		else:
			shrine_cooldowns[reward_id] = remaining
	if changed:
		_request_redraw()



	if not impacts.is_empty() or _drops_are_moving() or _drops_are_expiring():
		_request_redraw()
	redraw_elapsed += delta
	if redraw_requested and redraw_elapsed >= REDRAW_INTERVAL:
		redraw_requested = false
		redraw_elapsed = 0.0
		queue_redraw()


func _rebuild_after_layout_change() -> void :
	if not interior_initialized:
		return
	_build_world()
	if is_node_ready():
		_configure_player(entry_spawn())
		_build_lighting()
	_request_redraw()


func _build_world() -> void :


	_set_context("")
	mine = GameData.mine(mine_id)
	depth_profile = Dictionary(GameData.data.MINE_DEPTH_PROFILES[mine_id])
	discoveries = Dictionary(GameData.data.MINE_DEPTH_DISCOVERIES[mine_id])
	_configure_depth_assets()
	world_size = Vector2(float(mine.width), float(mine.height))
	cols = ceili(world_size.x / TILE_SIZE)
	rows = ceili(world_size.y / TILE_SIZE)
	terrain_max_hp = int(depth_profile.terrainHp)
	depth_entrance = (
		manual_depth_entrance
		if manual_depth_entrance_enabled
		else RootwoundLayoutScript.depth_entrance(GameData.data, int(RunState.world_seed), mine_id)
	)
	station_positions = RootwoundLayoutScript.stations(GameData.data, depth_entrance, mine_id)
	drops.clear()
	impacts.clear()
	_build_terrain()
	_build_rocks()
	_restore_persistent_loose_loot()
	_spawn_pending_pocket_loot()
	current_target_kind = ""
	current_target_cell = Vector2i(-1, -1)
	current_target_rock = -1
	target_dirty = true
	last_draw_cell = Vector2i(-9999, -9999)
	configured_world_seed = int(RunState.world_seed)
	interior_build_count += 1
	if not active:
		_capture_inactive_state_fingerprint()


func _persistent_state_fingerprint() -> int:
	var cavern_state: Dictionary = {}
	var reward_state: Dictionary = {}
	for cavern_value in caverns:
		var cavern: Dictionary = Dictionary(cavern_value)
		var cavern_id: = String(cavern.id)
		var reward_id: = String(Dictionary(cavern.reward).id)
		cavern_state[cavern_id] = RunState.is_cavern_discovered(cavern_id)
		reward_state[reward_id] = {
			"claimed": RunState.is_pocket_reward_claimed(reward_id), 
			"pending": RunState.pending_pocket_reward_loot(reward_id), 
		}
	return hash([
		RunState.dug_cells(mine_id, DEPTH), 
		Dictionary(RunState.mine_resource_runtime.get("%s:%d" % [mine_id, DEPTH], {})), 
		cavern_state, 
		reward_state, 
	])


func _capture_inactive_state_fingerprint() -> void :
	inactive_state_fingerprint = _persistent_state_fingerprint()
	inactive_state_fingerprint_valid = true


func _build_terrain() -> void :
	terrain_hp.resize(cols * rows)
	terrain_hp.fill(terrain_max_hp)
	dug_indices.clear()
	caverns.clear()
	concealed_cells.clear()
	_clear_circle(depth_entrance, 215.0)
	var sell_station: Dictionary = Dictionary(station_positions.sell)
	var forge_station: Dictionary = Dictionary(station_positions.forge)
	var sell_position: = Vector2(float(sell_station.x), float(sell_station.y))
	var forge_position: = Vector2(float(forge_station.x), float(forge_station.y))
	_clear_circle(sell_position, 126.0)
	_clear_circle(forge_position, 126.0)
	_clear_circle((sell_position + forge_position) * 0.5, 112.0)

	for definition_index in Array(discoveries.caverns).size():
		var cavern_value: Variant = Array(discoveries.caverns)[definition_index]
		var definition: Dictionary = Dictionary(cavern_value).duplicate(true)
		definition["source_name"] = String(definition.name)
		definition["name"] = _cavern_display_name(definition_index, String(definition.name))
		var cells: Array[int] = []
		var cell_lookup: Dictionary = {}
		var min_col: = maxi(0, floori((float(definition.x) - float(definition.rx)) / TILE_SIZE))
		var max_col: = mini(cols - 1, floori((float(definition.x) + float(definition.rx)) / TILE_SIZE))
		var min_row: = maxi(0, floori((float(definition.y) - float(definition.ry)) / TILE_SIZE))
		var max_row: = mini(rows - 1, floori((float(definition.y) + float(definition.ry)) / TILE_SIZE))
		for row in range(min_row, max_row + 1):
			for col in range(min_col, max_col + 1):
				var center: = _cell_center(Vector2i(col, row))
				var normalized: = (
					pow((center.x - float(definition.x)) / float(definition.rx), 2.0)
					+ pow((center.y - float(definition.y)) / float(definition.ry), 2.0)
				)
				if normalized > 1.0:
					continue
				var index: = row * cols + col
				cells.append(index)
				cell_lookup[index] = true
				terrain_hp[index] = 0
		definition["cells"] = cells
		definition["cell_lookup"] = cell_lookup
		definition["boundary"] = []
		definition["discovered"] = false
		caverns.append(definition)

	for cavern_index in caverns.size():
		var cavern: = caverns[cavern_index]
		var boundary: Array[int] = []
		var boundary_lookup: Dictionary = {}
		var cell_lookup: Dictionary = Dictionary(cavern.cell_lookup)
		for index_value in cavern.cells:
			var index: = int(index_value)
			var cell: = Vector2i(index % cols, floori(float(index) / float(cols)))
			for offset in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var neighbor: Vector2i = cell + Vector2i(offset)
				if not _cell_in_bounds(neighbor):
					continue
				var neighbor_index: = _cell_index(neighbor)
				if not cell_lookup.has(neighbor_index) and terrain_hp[neighbor_index] > 0 and not boundary_lookup.has(neighbor_index):
					boundary_lookup[neighbor_index] = true
					boundary.append(neighbor_index)
		cavern["boundary"] = boundary
		cavern.erase("cell_lookup")
		caverns[cavern_index] = cavern

	if RunState.has_method("dug_cells"):
		for index_value in RunState.dug_cells(mine_id, DEPTH):
			var index: = int(index_value)
			if index >= 0 and index < terrain_hp.size():
				dug_indices[index] = true
				terrain_hp[index] = 0

	for cavern_index in caverns.size():
		var cavern: = caverns[cavern_index]
		var cavern_id: = String(cavern.id)
		var discovered: = RunState.is_cavern_discovered(cavern_id) if RunState.has_method("is_cavern_discovered") else false
		for boundary_index in cavern.boundary:
			if dug_indices.has(int(boundary_index)):
				discovered = true
				break
		if discovered and RunState.has_method("mark_cavern_discovered"):
			RunState.mark_cavern_discovered(cavern_id)
		cavern["discovered"] = discovered
		caverns[cavern_index] = cavern
		if not discovered:
			for cell_index in cavern.cells:
				concealed_cells[int(cell_index)] = true


func _cavern_display_name(definition_index: int, fallback: String) -> String:
	var names: Array = Array(UNIQUE_CAVERN_NAMES.get(mine_id, []))
	if definition_index >= 0 and definition_index < names.size():
		return String(names[definition_index])
	return fallback


func _build_rocks() -> void :
	rocks.clear()
	rocks_by_cell.clear()
	_sync_claimed_rewards_from_run_state()
	for definition_index in Array(discoveries.rocks).size():
		var rock_value: Variant = Array(discoveries.rocks)[definition_index]
		var source: Dictionary = Dictionary(rock_value)
		var kind: = String(source.type)
		var type_data: Dictionary = Dictionary(GameData.data.ROCK_TYPES[kind])
		var cell: = _world_to_cell(Vector2(float(source.x), float(source.y)))
		var rock: = {
			"id": 1000 + rocks.size(), 
			"state_id": "rock:%d" % definition_index, 
			"type": kind, 
			"position": Vector2(float(source.x), float(source.y)), 
			"cell": cell, 
			"deposit_id": String(source.get("depositId", "")), 
			"cavern_id": String(source.get("cavernId", "")), 
			"pocket_reward_id": String(source.get("pocketRewardId", "")), 
			"rare_find": bool(source.get("rareFind", false)), 
			"drill_gated": bool(source.get("drillGated", false)), 
			"required_pickaxe": int(source.get("requiredPickaxe", 2)), 
			"requires_deep_tool": bool(source.get("requiresDeepTool", true)), 
			"requires_drill_level": int(source.get("requiresDrillLevel", 0)), 
			"hp": int(type_data.hp), 
			"max_hp": int(type_data.hp), 
			"shell": int(type_data.get("shell", 0)), 
			"max_shell": int(type_data.get("shell", 0)), 
			"broken": false, 
			"respawn_remaining": 0.0, 
			"respawn_until_unix": 0.0, 
		}
		var rock_index: = rocks.size()
		rocks.append(rock)
		if not rocks_by_cell.has(cell):
			rocks_by_cell[cell] = []
		var indices: Array = Array(rocks_by_cell[cell])
		indices.append(rock_index)
		rocks_by_cell[cell] = indices
	_restore_persistent_resource_depletion()
	_apply_claimed_pocket_rocks()


func _apply_claimed_pocket_rocks() -> void :
	for index in rocks.size():
		var rock: = rocks[index]
		var reward_id: = String(rock.pocket_reward_id)
		if not reward_id.is_empty() and bool(claimed_rewards.get(reward_id, false)):
			rock.broken = true
			rock.respawn_remaining = INF
			rock.respawn_until_unix = 0.0
			rocks[index] = rock


func _restore_persistent_resource_depletion() -> void :
	var now: = int(Time.get_unix_time_from_system())
	var depleted: Dictionary = RunState.mine_resource_depletions(mine_id, DEPTH)
	for index in rocks.size():
		var rock: Dictionary = Dictionary(rocks[index])
		var state_id: = String(rock.get("state_id", ""))
		if not depleted.has(state_id):
			continue
		var record: Dictionary = Dictionary(depleted[state_id])
		if String(record.get("kind", "")) != String(rock.get("type", "")):
			continue
		var respawn_until: = int(record.get("respawn_until_unix", 0))
		if respawn_until <= now:
			RunState.clear_mine_resource_depletion(mine_id, DEPTH, state_id)
			continue
		rock.broken = true
		rock.hp = 0
		rock.shell = 0
		rock.respawn_until_unix = float(respawn_until)
		rock.respawn_remaining = maxf(0.0, float(respawn_until - now))
		rocks[index] = rock


func _sync_claimed_rewards_from_run_state() -> void :
	claimed_rewards.clear()
	for cavern_value in discoveries.get("caverns", []):
		var cavern: Dictionary = Dictionary(cavern_value)
		var reward_id: = String(cavern.reward.id)
		claimed_rewards[reward_id] = (
			RunState.is_pocket_reward_claimed(reward_id)
			if RunState.has_method("is_pocket_reward_claimed")
			else false
		)


func _spawn_pending_pocket_loot() -> void :
	if not RunState.has_method("pending_pocket_reward_loot"):
		return
	for cavern in caverns:
		var reward_id: = String(Dictionary(cavern.reward).id)
		var pending: Dictionary = RunState.pending_pocket_reward_loot(reward_id)
		_spawn_reward_plan_loot(reward_id, pending, Vector2(float(cavern.x), float(cavern.y) + 12.0))


func _configure_player(position: Vector2) -> void :
	var speed: = float(GameData.data.PLAYER_SPEED) * RunState.movement_speed_multiplier()
	player.configure(position, world_size, speed, _resolve_motion)


func _clear_circle(center: Vector2, radius: float) -> void :
	var min_col: = maxi(0, floori((center.x - radius) / TILE_SIZE))
	var max_col: = mini(cols - 1, floori((center.x + radius) / TILE_SIZE))
	var min_row: = maxi(0, floori((center.y - radius) / TILE_SIZE))
	var max_row: = mini(rows - 1, floori((center.y + radius) / TILE_SIZE))
	for row in range(min_row, max_row + 1):
		for col in range(min_col, max_col + 1):
			var cell: = Vector2i(col, row)
			if _cell_center(cell).distance_to(center) <= radius:
				terrain_hp[_cell_index(cell)] = 0


func _resolve_motion(origin: Vector2, motion: Vector2) -> Vector2:
	var result: = origin
	var next_x: = Vector2(origin.x + motion.x, origin.y)
	if not _player_collides(next_x):
		result.x = next_x.x
	var next_y: = Vector2(result.x, origin.y + motion.y)
	if not _player_collides(next_y):
		result.y = next_y.y
	return result.clamp(Vector2.ONE * PLAYER_RADIUS, world_size - Vector2.ONE * PLAYER_RADIUS)


func _player_collides(position: Vector2) -> bool:
	var min_cell: = _world_to_cell(position - Vector2.ONE * PLAYER_RADIUS)
	var max_cell: = _world_to_cell(position + Vector2.ONE * PLAYER_RADIUS)
	for row in range(min_cell.y, max_cell.y + 1):
		for col in range(min_cell.x, max_cell.x + 1):
			var cell: = Vector2i(col, row)
			if not _visual_is_solid(cell):
				continue
			var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			var nearest: = Vector2(
				clampf(position.x, rect.position.x, rect.end.x), 
				clampf(position.y, rect.position.y, rect.end.y)
			)
			if position.distance_squared_to(nearest) < PLAYER_RADIUS * PLAYER_RADIUS:
				return true
	return false


func _on_player_moved(world_position: Vector2) -> void :
	target_dirty = true
	var draw_cell: = _world_to_cell(world_position)
	if draw_cell != last_draw_cell:
		last_draw_cell = draw_cell
		_request_redraw()
	_refresh_landmark_lights()
	_update_context(world_position)


func _on_player_facing_changed(direction: Vector2) -> void :
	var headlamp: = player.get_node_or_null("PremiumHeadlamp")
	if headlamp != null and headlamp.has_method("set_direction"):
		headlamp.set_direction(direction)
	if player.camera.has_method("set_headlamp_direction"):
		player.camera.set_headlamp_direction(direction)
	target_dirty = true


func _update_context(world_position: Vector2) -> void :
	var next_context: = ""
	if world_position.distance_to(depth_entrance) <= SHAFT_CONTEXT_RADIUS:
		next_context = "depthExit"
	else:
		var sell: Dictionary = Dictionary(station_positions.sell)
		var forge: Dictionary = Dictionary(station_positions.forge)
		if world_position.distance_to(Vector2(float(sell.x), float(sell.y))) <= float(sell.radius):
			next_context = "depthSell"
		elif world_position.distance_to(Vector2(float(forge.x), float(forge.y))) <= float(forge.radius):
			next_context = "drillForge"
	_set_context(next_context)


func _set_context(next_context: String) -> void :
	if next_context == active_context:
		return
	var previous_exit: = exit_context
	var previous_station: = station_context
	active_context = next_context
	exit_context = active_context == "depthExit"
	station_context = "sell" if active_context == "depthSell" else "forge" if active_context == "drillForge" else ""
	context_changed.emit(active_context)
	if exit_context != previous_exit:
		exit_context_changed.emit(exit_context)
	if station_context != previous_station:
		station_context_changed.emit(station_context)
	match active_context:
		"depthExit":
			message_changed.emit("ASCEND TO %s · return to Depth 1" % _depth_one_return_name())
		"depthSell":
			message_changed.emit("%s ORE EXCHANGE · sell carried ore" % _depth_short_name().to_upper())
		"drillForge":
			message_changed.emit("%s DRILL FORGE · inspect the next upgrade" % _depth_short_name().to_upper())
	_request_redraw()


func _update_mining(delta: float) -> void :
	var held: = external_mine_held or Input.is_action_pressed("mine")
	_update_heat_streak(delta, held)
	if not swing_active:
		if held and not current_target_kind.is_empty():
			_start_swing(true)
			player.set_mining_visual(true, _mining_visual_progress())
		else:
			player.set_mining_visual(false)
			_reset_mining_visual_phase()
		return
	mining_visual_elapsed += delta
	swing_elapsed += delta
	var gameplay_progress: = clampf(swing_elapsed / swing_duration, 0.0, 1.0)
	player.set_mining_visual(true, _mining_visual_progress())
	if not swing_hit and gameplay_progress >= _tool_strike_progress():
		swing_hit = true
		mine_once()
	if swing_elapsed >= swing_duration:
		var overflow: = maxf(0.0, swing_elapsed - swing_duration)
		swing_active = false
		if held and not current_target_kind.is_empty():
			_start_swing(true)
			swing_elapsed = fposmod(overflow, maxf(0.001, swing_duration))
			player.set_mining_visual(true, _mining_visual_progress())
		else:
			player.set_mining_visual(false)
			_reset_mining_visual_phase()


func _start_swing(mining_held: bool = false) -> void :
	if not mining_visual_running:
		mining_visual_elapsed = 0.0
		mining_visual_running = true
	swing_active = true
	swing_elapsed = 0.0
	swing_hit = false
	if _heat_streak_unlocked() and mining_held:
		heat_streak_active = true
	var tool: = _current_tool()
	swing_duration = float(tool.get("cooldown", 0.72))
	if mining_rush_remaining > 0.0:
		swing_duration *= MINING_RUSH_COOLDOWN_MULTIPLIER
	swing_duration /= _heat_streak_speed()


func _mining_visual_progress() -> float:
	if player.direction_name == "up":
		var visual_cycle: = maxf(UPWARD_MINING_VISUAL_CYCLE, swing_duration)
		return fposmod(mining_visual_elapsed, visual_cycle) / visual_cycle
	return clampf(swing_elapsed / maxf(0.001, swing_duration), 0.0, 1.0)


func _reset_mining_visual_phase() -> void :
	mining_visual_elapsed = 0.0
	mining_visual_running = false


func _heat_streak_unlocked() -> bool:
	return int(RunState.ember_mastery) >= 5 and int(RunState.drill_level) == 0


func _heat_streak_progress() -> float:
	if not _heat_streak_unlocked():
		return 0.0
	return clampf(heat_streak_elapsed / HEAT_STREAK_BUILD_SECONDS, 0.0, 1.0)


func _heat_streak_speed() -> float:
	return 1.0 + (HEAT_STREAK_MAX_SPEED - 1.0) * _heat_streak_progress()


func _update_heat_streak(delta: float, mining_held: bool) -> void :
	if not _heat_streak_unlocked() or not mining_held:
		_reset_heat_streak()
		return
	if not heat_streak_active:
		return
	if not swing_active and current_target_kind.is_empty():
		return
	heat_streak_elapsed = minf(HEAT_STREAK_BUILD_SECONDS, heat_streak_elapsed + delta)


func _reset_heat_streak() -> void :
	heat_streak_elapsed = 0.0
	heat_streak_active = false


func _hit_terrain(cell: Vector2i) -> bool:
	if not _terrain_is_solid(cell):
		return false
	if not _has_deep_tool():
		AudioDirector.play_blocked()
		message_changed.emit("STARFORGE REQUIRED · Depth 2 stone needs a deep tool")
		return false
	var index: = _cell_index(cell)
	var tool: = _current_tool()
	terrain_hp[index] = maxi(0, terrain_hp[index] - int(tool.get("power", 1)))
	AudioDirector.play_mining("deepstone", terrain_hp[index] <= 0, false)
	var impact: = {
		"position": _target_contact_point(), 
		"age": 0.0, 
		"life": 0.34, 
		"broken": terrain_hp[index] <= 0, 
		"style": _tool_impact_style(tool),
	}
	_attach_crusher_debris(impact, cell)
	_append_impact(impact)
	player.set_mining_visual(true, _mining_visual_progress(), 1.0)
	if terrain_hp[index] <= 0:
		dug_indices[index] = true
		if RunState.has_method("mark_terrain_dug"):
			RunState.mark_terrain_dug(mine_id, index, DEPTH)
		_record_mined("deepstone", 1)
		var crusher_origin: Variant = (
			_cell_center(cell) if String(RunState.starforge_variant) == "crusher" else null
		)
		_spawn_drop(_cell_center(cell), "deepstone", 1, "", crusher_origin)
		_discover_cavern_from_cell(index)
		_emit_revealed_resources(cell)
		message_changed.emit("DEEPSTONE BROKEN · tunnel opened")
	if String(RunState.starforge_variant) == "crusher":
		_apply_depth_crusher_wave(cell, tool)
	target_dirty = true
	_request_redraw()
	return true


func _hit_rock(rock_index: int) -> bool:
	if rock_index < 0 or rock_index >= rocks.size():
		return false
	var rock: = rocks[rock_index]
	if bool(rock.broken) or not _rock_is_exposed(rock_index):
		return false
	var required_drill: = int(rock.requires_drill_level)
	if required_drill > int(RunState.drill_level):
		AudioDirector.play_blocked()
		var required: Dictionary = Dictionary(GameData.data.DRILLS[required_drill])
		message_changed.emit("%s REQUIRED · %s is drill-gated" % [String(required.name).to_upper(), String(rock.type).capitalize()])
		return false
	if bool(rock.requires_deep_tool) and not _has_deep_tool():
		AudioDirector.play_blocked()
		message_changed.emit("STARFORGE REQUIRED · deep ore resists normal pickaxes")
		return false
	if int(rock.required_pickaxe) > int(RunState.pickaxe_level):
		AudioDirector.play_blocked()
		var required_pickaxe: Dictionary = Dictionary(GameData.data.PICKAXES[int(rock.required_pickaxe)])
		message_changed.emit("%s REQUIRED" % String(required_pickaxe.name).to_upper())
		return false

	var tool: = _current_tool()
	var power: = int(tool.get("power", 1))
	var was_armored: = int(rock.shell) > 0
	if int(rock.shell) > 0:
		var shell_multiplier: = maxf(0.01, float(tool.get("shell_power", 0.72)))
		var shell_damage: = ceili(float(power) * shell_multiplier)
		var previous_shell: = int(rock.shell)
		rock.shell = maxi(0, previous_shell - shell_damage)
		var overflow: = maxi(0, shell_damage - previous_shell)
		if overflow > 0:
			rock.hp = maxi(0, int(rock.hp) - floori(float(overflow) / shell_multiplier))
	else:
		rock.hp = maxi(0, int(rock.hp) - power)
	rocks[rock_index] = rock
	AudioDirector.play_mining(String(rock.type), int(rock.shell) <= 0 and int(rock.hp) <= 0, was_armored)
	var impact: = {
		"position": Vector2(rock.position), 
		"age": 0.0, 
		"life": 0.34, 
		"broken": int(rock.shell) <= 0 and int(rock.hp) <= 0, 
		"style": _tool_impact_style(tool),
	}
	_attach_crusher_debris(impact, _world_to_cell(Vector2(rock.position)))
	_append_impact(impact)
	player.set_mining_visual(true, _mining_visual_progress(), 1.0)
	if int(rock.shell) <= 0 and int(rock.hp) <= 0:
		var crusher_origin: Variant = (
			Vector2(rock.position) if String(RunState.starforge_variant) == "crusher" else null
		)
		_break_rock(rock_index, crusher_origin)
	if String(RunState.starforge_variant) == "crusher":
		_apply_depth_crusher_wave(_world_to_cell(Vector2(rock.position)), tool)
	target_dirty = true
	_request_redraw()
	return true


func _break_rock(rock_index: int, crusher_origin: Variant = null) -> void :
	var rock: = rocks[rock_index]
	var type_data: Dictionary = Dictionary(GameData.data.ROCK_TYPES[String(rock.type)])
	var respawn_seconds: = float(type_data.get("respawn", 8.0))
	rock.broken = true
	rock.respawn_remaining = respawn_seconds
	rock.respawn_until_unix = RunState.deplete_mine_resource_node(
		mine_id, DEPTH, String(rock.state_id), respawn_seconds
	)
	var yield_amount: = 1
	var yield_chance: = clampf(float(_current_tool().get("yield_bonus", 0.0)), 0.0, 0.92)
	if randf() < yield_chance:
		yield_amount += 1
	yield_amount *= maxi(1, int(_current_tool().get("yield_multiplier", 1)))
	rocks[rock_index] = rock
	_record_mined(String(rock.type), yield_amount)
	_spawn_drop(Vector2(rock.position), String(rock.type), yield_amount, "", crusher_origin)
	resource_mined.emit(String(rock.type), yield_amount)
	if (
		mine_id == "starMine"
		and String(rock.type) == "singularity"
		and int(RunState.drill_level) == int(GameData.data.DRILLS.size()) - 1
	):
		final_resource_mined.emit("singularity")
	_register_deposit_break(rock_index)
	_register_pocket_deposit_break(String(rock.pocket_reward_id))


func _register_deposit_break(rock_index: int) -> void :
	var rock: = rocks[rock_index]
	var deposit_id: = String(rock.deposit_id)
	if deposit_id.is_empty():
		return
	var total: = 0
	var broken: = 0
	for candidate in rocks:
		if String(candidate.deposit_id) != deposit_id:
			continue
		total += 1
		if bool(candidate.broken):
			broken += 1
	if total > 0 and broken == total:
		if bool(rock.drill_gated):
			drill_gate_cleared.emit(deposit_id, int(rock.requires_drill_level))
		message_changed.emit("RARE FIND!" if bool(rock.rare_find) else "VEIN CLEARED!")


func _register_pocket_deposit_break(reward_id: String) -> Dictionary:
	if reward_id.is_empty() or _pocket_reward_is_claimed(reward_id):
		return {"ok": false, "reason": "not_pending", "reward_id": reward_id}
	var reward_rock_indices: Array[int] = []
	for index in rocks.size():
		if String(rocks[index].pocket_reward_id) == reward_id:
			reward_rock_indices.append(index)
	if reward_rock_indices.is_empty():
		return {"ok": false, "reason": "no_deposit", "reward_id": reward_id}
	for index in reward_rock_indices:
		if not bool(rocks[index].broken):
			return {"ok": false, "reason": "deposit_remaining", "reward_id": reward_id}
	var origin: = Vector2(rocks[reward_rock_indices[-1]].position)
	var plan: Dictionary = RunState.complete_pocket_deposit(reward_id) if RunState.has_method("complete_pocket_deposit") else {}
	if not bool(plan.get("ok", false)):
		return plan
	claimed_rewards[reward_id] = true
	var reward: = _reward_by_id(reward_id)
	var reward_kind: = String(reward.get("kind", "crystal"))
	_spawn_reward_plan_loot(reward_id, Dictionary(plan.get("pending_loot", {})), origin)
	for index in reward_rock_indices:
		var rock: = rocks[index]
		rock.respawn_remaining = INF
		rock.respawn_until_unix = 0.0
		rocks[index] = rock
		RunState.clear_mine_resource_depletion(
			mine_id, DEPTH, String(rock.get("state_id", ""))
		)
	pocket_reward_claimed.emit(reward_id, reward_kind)
	AudioDirector.play_discovery()
	message_changed.emit("CLUSTER CLEARED" if reward_kind == "crystal" else "MOTHERLODE CLEARED")
	return plan


func _update_rocks() -> void :
	var now: = Time.get_unix_time_from_system()
	for index in rocks.size():
		var rock: = rocks[index]
		if not bool(rock.broken) or is_inf(float(rock.respawn_remaining)):
			continue
		var respawn_until: = float(rock.get("respawn_until_unix", now))
		rock.respawn_remaining = maxf(0.0, respawn_until - now)
		if float(rock.respawn_remaining) > 0.0:
			rocks[index] = rock
			continue
		if player.global_position.distance_to(Vector2(rock.position)) < TILE_SIZE * 1.7:
			rock.respawn_remaining = 0.5
			rock.respawn_until_unix = now + 0.5
			rocks[index] = rock
			continue
		rock.broken = false
		rock.hp = int(rock.max_hp)
		rock.shell = int(rock.max_shell)
		rock.respawn_remaining = 0.0
		rock.respawn_until_unix = 0.0
		rocks[index] = rock
		RunState.clear_mine_resource_depletion(
			mine_id, DEPTH, String(rock.get("state_id", ""))
		)
		target_dirty = true
		_request_redraw()


func _restore_persistent_loose_loot() -> void :
	var retained: Array[Dictionary] = []
	for drop in drops:
		if not String(drop.get("pocket_reward_id", "")).is_empty():
			retained.append(Dictionary(drop))
	drops = retained
	for stored_value in RunState.mine_loose_loot(mine_id, DEPTH):
		var stored: Dictionary = Dictionary(stored_value)
		drops.append({
			"kind": String(stored.get("kind", "deepstone")), 
			"amount": maxi(1, int(stored.get("amount", 1))), 
			"position": Vector2(
				float(stored.get("x", 0.0)), 
				float(stored.get("y", 0.0))
			), 
			"velocity": Vector2.ZERO, 
			"age": 1.0, 
			"pocket_reward_id": "", 
			"persistent_id": String(stored.get("id", "")), 
			"settled_persisted": true, 
		})


func _persist_loose_drop_positions() -> void :
	for drop in drops:
		if not String(drop.get("pocket_reward_id", "")).is_empty():
			continue
		var persistent_id: = String(drop.get("persistent_id", ""))
		if persistent_id.is_empty():
			continue
		RunState.update_mine_loose_loot_position(
			mine_id, DEPTH, persistent_id, Vector2(drop.position)
		)


func _spawn_drop(
	position: Vector2,
	kind: String,
	amount: int,
	pocket_reward_id: String = "",
	crusher_origin: Variant = null
) -> void :
	var angle: = float(drops.size() * 47 + floori(position.x) * 3 + floori(position.y)) * 0.013
	var is_crusher_bundle: = pocket_reward_id.is_empty() and crusher_origin is Vector2
	var crusher_sector: = -1
	var merge_drop_id: = ""
	if is_crusher_bundle:
		var seed_value: = (
			floori(position.x) * 73856093
			^ floori(position.y) * 19349663
			^ int(mine_id.hash())
			^ DEPTH
		)
		crusher_sector = CrusherLootBurstScript.sector_for(
			Vector2(crusher_origin), position, seed_value
		)
		var merge_index: = CrusherLootBurstScript.merge_target_index(
			drops, kind, crusher_sector
		)
		if merge_index >= 0:
			merge_drop_id = String(drops[merge_index].get("persistent_id", ""))
	if pocket_reward_id.is_empty():
		var stored: Dictionary = RunState.register_mine_loose_loot(
			mine_id, DEPTH, kind, maxi(1, amount), position, merge_drop_id
		)
		if stored.is_empty():
			return
		if bool(stored.get("resync", false)):
			_restore_persistent_loose_loot()
			return
		var persistent_id: = String(stored.get("id", ""))
		if bool(stored.get("merged", false)):
			for index in drops.size():
				if String(drops[index].get("persistent_id", "")) == persistent_id:
					drops[index].amount = int(stored.get("amount", drops[index].amount))
					if is_crusher_bundle:
						_refresh_crusher_bundle(index, position, crusher_sector)
					return
		var drop: Dictionary = {
			"kind": kind, 
			"amount": int(stored.get("amount", maxi(1, amount))), 
			"position": position, 
			"velocity": (
				CrusherLootBurstScript.direction_for_sector(crusher_sector)
				* CrusherLootBurstScript.LAUNCH_SPEED
				if is_crusher_bundle
				else Vector2.from_angle(angle) * 76.0
			), 
			"age": 0.0, 
			"pocket_reward_id": "", 
			"persistent_id": persistent_id, 
			"settled_persisted": false, 
		}
		if is_crusher_bundle:
			drop["crusher_bundle"] = true
			drop["crusher_sector"] = crusher_sector
			drop["crusher_lift"] = CrusherLootBurstScript.ARC_LIFT
			drop["crusher_flight_age"] = 0.0
			drop["magnet_active"] = false
			drop["visual_suppressed"] = (
				CrusherLootBurstScript.visible_bundle_count(drops)
				>= CrusherLootBurstScript.MAX_VISIBLE_BUNDLES
			)
		drops.append(drop)
		return
	drops.append({
		"kind": kind, 
		"amount": amount, 
		"position": position, 
		"velocity": Vector2.from_angle(angle) * 76.0, 
		"age": 0.0, 
		"pocket_reward_id": pocket_reward_id, 
	})


func _refresh_crusher_bundle(index: int, position: Vector2, sector: int) -> void:
	if index < 0 or index >= drops.size():
		return
	var drop: Dictionary = drops[index]
	var was_crusher_bundle: = bool(drop.get("crusher_bundle", false))
	drop["position"] = position
	drop["velocity"] = (
		CrusherLootBurstScript.direction_for_sector(sector)
		* CrusherLootBurstScript.LAUNCH_SPEED
	)
	drop["crusher_bundle"] = true
	drop["crusher_sector"] = sector
	drop["crusher_lift"] = CrusherLootBurstScript.ARC_LIFT
	drop["crusher_flight_age"] = 0.0
	drop["settled_persisted"] = false
	drop["magnet_active"] = false
	if not was_crusher_bundle:
		drop["visual_suppressed"] = (
			CrusherLootBurstScript.visible_bundle_count(drops)
			>= CrusherLootBurstScript.MAX_VISIBLE_BUNDLES
		)
	drops[index] = drop


func _spawn_reward_plan_loot(reward_id: String, pending: Dictionary, origin: Vector2) -> void :
	var reward_offset: = -0.5 * float(maxi(0, pending.size() - 1))
	for resource_value in pending:
		var resource_id: = String(resource_value)
		var amount: = int(pending[resource_id])
		if amount > 0:
			_spawn_drop(origin + Vector2(reward_offset * 20.0, 0), resource_id, amount, reward_id)
			reward_offset += 1.0


func _update_drops(delta: float) -> void :
	var drops_changed: = false
	for index in range(drops.size() - 1, -1, -1):
		var drop: = drops[index]
		drop.position = Vector2(drop.position) + Vector2(drop.velocity) * delta
		drop.velocity = Vector2(drop.velocity) * pow(0.08, delta)
		drop.age = float(drop.age) + delta
		if bool(drop.get("crusher_bundle", false)):
			drop["crusher_flight_age"] = float(drop.get("crusher_flight_age", 0.0)) + delta
		drop["magnet_active"] = false
		if float(drop.age) >= LOOSE_RESOURCE_LIFETIME:
			var expired_reward_id: = String(drop.get("pocket_reward_id", ""))
			if not expired_reward_id.is_empty():
				RunState.collect_pocket_loot(expired_reward_id, String(drop.kind), maxi(1, int(drop.amount)))
			elif not String(drop.get("persistent_id", "")).is_empty():
				RunState.collect_mine_loose_loot(
					mine_id, 
					DEPTH, 
					String(drop.persistent_id), 
					maxi(1, int(drop.amount))
				)
			else:
				RunState.add_resource(String(drop.kind), maxi(1, int(drop.amount)), false)
			drops.remove_at(index)
			drops_changed = true
			continue
		if (
			String(drop.get("pocket_reward_id", "")).is_empty()
			and Vector2(drop.velocity).length_squared() <= 1.0
			and not bool(drop.get("settled_persisted", false))
		):
			RunState.update_mine_loose_loot_position(
				mine_id, 
				DEPTH, 
				String(drop.get("persistent_id", "")), 
				Vector2(drop.position)
			)
			drop.settled_persisted = true
		drops[index] = drop
		var pickup_radius: = RunState.resource_pickup_radius(48.0, String(drop.kind))
		var pickup_distance: = player.global_position.distance_to(Vector2(drop.position))
		if (
			CrusherLootBurstScript.magnet_age(drop)
			< CrusherLootBurstScript.magnet_delay(drop, DROP_MAGNET_DELAY)
			or pickup_distance > pickup_radius
		):
			continue
		drop.position = Vector2(drop.position).move_toward(
			player.global_position + Vector2(0, -24), DROP_MAGNET_SPEED * delta
		)
		drop.velocity = Vector2.ZERO
		drop["magnet_active"] = true
		drops[index] = drop
		if Vector2(drop.position).distance_to(player.global_position + Vector2(0, -24)) <= DROP_MAGNET_COLLECT_RADIUS:
			var reward_id: = String(drop.get("pocket_reward_id", ""))
			var collected_amount: = 0
			if not reward_id.is_empty() and RunState.has_method("collect_pocket_loot"):
				var collected: = int(RunState.collect_pocket_loot(reward_id, String(drop.kind), int(drop.amount)))
				if collected <= 0:
					drops.remove_at(index)
					drops_changed = true
					continue
				collected_amount = collected
				var remaining: = maxi(0, int(drop.amount) - collected)
				if remaining > 0:
					drop.amount = remaining
					drops[index] = drop
					AudioDirector.play_pickup(String(drop.kind), collected_amount)
					message_changed.emit("%s COLLECTED" % String(drop.kind).to_upper())
					continue
			elif not String(drop.get("persistent_id", "")).is_empty():
				var collected: Dictionary = RunState.collect_mine_loose_loot(
					mine_id, 
					DEPTH, 
					String(drop.persistent_id), 
					int(drop.amount)
				)
				collected_amount = int(collected.get("amount", 0))
				var remaining: = int(collected.get("remaining", 0))
				if remaining > 0:
					drop.amount = remaining
					drops[index] = drop
					continue
				if collected_amount <= 0:
					drops.remove_at(index)
					drops_changed = true
					continue
			else:
				RunState.add_resource(String(drop.kind), int(drop.amount), false)
				collected_amount = int(drop.amount)
			AudioDirector.play_pickup(String(drop.kind), collected_amount)
			drops.remove_at(index)
			drops_changed = true
			message_changed.emit("%s COLLECTED" % String(drop.kind).to_upper())
	if _refresh_suppressed_crusher_bundles():
		drops_changed = true
	if drops_changed:
		_request_redraw()


func _refresh_suppressed_crusher_bundles() -> bool:
	var available_slots: = (
		CrusherLootBurstScript.MAX_VISIBLE_BUNDLES
		- CrusherLootBurstScript.visible_bundle_count(drops)
	)
	if available_slots <= 0:
		return false
	var changed: = false
	for index in drops.size():
		var drop: Dictionary = drops[index]
		if (
			not bool(drop.get("crusher_bundle", false))
			or not bool(drop.get("visual_suppressed", false))
		):
			continue
		drop["visual_suppressed"] = false
		drops[index] = drop
		available_slots -= 1
		changed = true
		if available_slots <= 0:
			break
	return changed


func _update_impacts(delta: float) -> void :
	for index in range(impacts.size() - 1, -1, -1):
		impacts[index].age = float(impacts[index].age) + delta
		if float(impacts[index].age) >= float(impacts[index].life):
			impacts.remove_at(index)


func _drops_are_moving() -> bool:
	for drop in drops:
		if CrusherLootBurstScript.needs_animation(drop):
			return true
	return false


func _drops_are_expiring() -> bool:
	for drop in drops:
		if float(drop.get("age", 0.0)) >= LOOSE_RESOURCE_LIFETIME - LOOSE_RESOURCE_FADE_SECONDS:
			return true
	return false


func _find_mine_target() -> Dictionary:
	if not active:
		return {}
	var aim: Vector2 = Vector2(player.facing_vector).normalized()
	if aim.length_squared() < 0.5:
		return {}
	var origin: = player.global_position
	var best: Dictionary = {}
	var best_entry: = INF
	var side: = Vector2( - aim.y, aim.x)
	var mining_range: = _effective_mining_range()
	var search_radius: = mining_range + TILE_SIZE
	var min_cell: = _world_to_cell(origin - Vector2.ONE * search_radius)
	var max_cell: = _world_to_cell(origin + Vector2.ONE * search_radius)

	for row in range(maxi(0, min_cell.y), mini(rows - 1, max_cell.y) + 1):
		for col in range(maxi(0, min_cell.x), mini(cols - 1, max_cell.x) + 1):
			var cell: = Vector2i(col, row)
			if rocks_by_cell.has(cell):
				for rock_index_value in rocks_by_cell[cell]:
					var rock_index: = int(rock_index_value)
					if not _rock_is_exposed(rock_index):
						continue
					var rock_position: = Vector2(rocks[rock_index].position)
					if origin.distance_to(rock_position) > mining_range:
						continue
					var entry: = _ray_circle_entry(origin, aim, rock_position, 32.0, mining_range)
					if entry < 0.0:
						continue
					var lateral: = absf((rock_position - origin).dot(side))
					if entry < best_entry - 0.01 or (absf(entry - best_entry) <= 0.01 and lateral < float(best.get("lateral", INF))):
						best_entry = entry
						best = {"kind": "rock", "rock_index": rock_index, "cell": cell, "entry": entry, "lateral": lateral}

			if not _terrain_is_solid(cell):
				continue
			var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE).grow(PLAYER_RADIUS)
			var terrain_entry: = _ray_rect_entry(origin, aim, rect, mining_range + TILE_SIZE * 0.65 - PLAYER_RADIUS)
			if terrain_entry <= 0.01:
				continue
			var terrain_lateral: = absf((_cell_center(cell) - origin).dot(side))
			if terrain_entry < best_entry - 0.01 or (absf(terrain_entry - best_entry) <= 0.01 and terrain_lateral < float(best.get("lateral", INF))):
				best_entry = terrain_entry
				best = {"kind": "terrain", "rock_index": -1, "cell": cell, "entry": terrain_entry, "lateral": terrain_lateral}
	return best


func _apply_target(target: Dictionary) -> void :
	var previous_kind: = current_target_kind
	var previous_cell: = current_target_cell
	var previous_rock: = current_target_rock
	current_target_kind = String(target.get("kind", ""))
	current_target_cell = Vector2i(target.get("cell", Vector2i(-1, -1)))
	current_target_rock = int(target.get("rock_index", -1))
	if previous_kind != current_target_kind or previous_cell != current_target_cell or previous_rock != current_target_rock:
		_request_redraw()


func _ray_circle_entry(origin: Vector2, direction: Vector2, center: Vector2, radius: float, max_distance: float) -> float:
	var offset: = origin - center
	var projection: = offset.dot(direction)
	var determinant: = projection * projection - (offset.length_squared() - radius * radius)
	if determinant < 0.0:
		return -1.0
	var entry: = - projection - sqrt(determinant)
	if entry < 0.0:
		entry = - projection + sqrt(determinant)
	return entry if entry >= 0.0 and entry <= max_distance else -1.0


func _ray_rect_entry(origin: Vector2, direction: Vector2, rect: Rect2, max_distance: float) -> float:
	var near_time: = 0.0
	var far_time: = max_distance
	for axis in 2:
		var origin_axis: = origin[axis]
		var direction_axis: = direction[axis]
		var minimum: = rect.position[axis]
		var maximum: = rect.end[axis]
		if absf(direction_axis) < 1e-05:
			if origin_axis < minimum or origin_axis > maximum:
				return -1.0
			continue
		var first: = (minimum - origin_axis) / direction_axis
		var second: = (maximum - origin_axis) / direction_axis
		if first > second:
			var swap: = first
			first = second
			second = swap
		near_time = maxf(near_time, first)
		far_time = minf(far_time, second)
		if near_time > far_time:
			return -1.0
	return near_time if near_time <= max_distance else -1.0


func _target_contact_point() -> Vector2:
	if current_target_kind == "rock" and current_target_rock >= 0 and current_target_rock < rocks.size():
		return Vector2(rocks[current_target_rock].position)
	if current_target_kind != "terrain" or not _cell_in_bounds(current_target_cell):
		return player.global_position
	var aim: Vector2 = Vector2(player.facing_vector).normalized()
	var rect: = Rect2(Vector2(current_target_cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
	var entry: = _ray_rect_entry(player.global_position, aim, rect, _effective_mining_range() + TILE_SIZE)
	if entry >= 0.0:
		return player.global_position + aim * entry
	return Vector2(
		clampf(player.global_position.x, rect.position.x, rect.end.x), 
		clampf(player.global_position.y, rect.position.y, rect.end.y)
	)


func _effective_mining_range() -> float:
	return MINING_RANGE * RunState.endless_tool_range_multiplier()


func _rock_is_exposed(rock_index: int) -> bool:
	if rock_index < 0 or rock_index >= rocks.size():
		return false
	var rock: = rocks[rock_index]
	if bool(rock.broken):
		return false
	var cavern_id: = String(rock.cavern_id)
	if not cavern_id.is_empty() and not _cavern_is_discovered(cavern_id):
		return false
	return not _terrain_is_solid(Vector2i(rock.cell))


func _emit_revealed_resources(cell: Vector2i) -> void :
	if rocks_by_cell.has(cell):
		for rock_index_value in rocks_by_cell[cell]:
			var rock_index: = int(rock_index_value)
			if _rock_is_exposed(rock_index):
				var rock: = rocks[rock_index]
				resource_revealed.emit(String(rock.type), String(rock.deposit_id))


func _discover_cavern_from_cell(dug_index: int) -> void :
	for cavern_index in caverns.size():
		var cavern: = caverns[cavern_index]
		if bool(cavern.discovered) or not (int(dug_index) in cavern.boundary):
			continue
		if RunState.has_method("mark_cavern_discovered"):
			RunState.mark_cavern_discovered(String(cavern.id))
		cavern.discovered = true
		caverns[cavern_index] = cavern
		for cell_index in cavern.cells:
			concealed_cells.erase(int(cell_index))
		cavern_discovered.emit(String(cavern.id), String(cavern.name))
		message_changed.emit("HIDDEN CHAMBER · %s" % String(cavern.name).to_upper())
		for rock_index in rocks.size():
			var rock: = rocks[rock_index]
			if String(rock.cavern_id) == String(cavern.id) and _rock_is_exposed(rock_index):
				resource_revealed.emit(String(rock.type), String(rock.deposit_id))
		if is_node_ready():
			_build_lighting()
		_request_redraw()
		return


func _cavern_is_discovered(cavern_id: String) -> bool:
	if RunState.has_method("is_cavern_discovered") and RunState.is_cavern_discovered(cavern_id):
		return true
	for cavern in caverns:
		if String(cavern.id) == cavern_id:
			return bool(cavern.discovered)
	return false


func _update_pocket_rewards() -> void :
	for cavern_index in caverns.size():
		var cavern: = caverns[cavern_index]
		if not bool(cavern.discovered):
			continue
		var reward: Dictionary = Dictionary(cavern.reward)
		var reward_id: = String(reward.id)
		if _pocket_reward_is_claimed(reward_id):
			continue
		var kind: = String(reward.kind)
		if kind in ["crystal", "motherlode"]:
			continue
		var radius: = minf(float(cavern.rx), float(cavern.ry)) * 0.7
		if player.global_position.distance_to(Vector2(float(cavern.x), float(cavern.y))) <= radius:
			_claim_pocket_reward(cavern_index)


func _claim_pocket_reward(cavern_index: int) -> Dictionary:
	if cavern_index < 0 or cavern_index >= caverns.size():
		return {"ok": false, "reason": "unknown_cavern"}
	var cavern: = caverns[cavern_index]
	var reward: Dictionary = Dictionary(cavern.reward)
	var reward_id: = String(reward.id)
	var kind: = String(reward.kind)
	var plan: Dictionary
	if kind == "shrine":
		var cooldown: = float(shrine_cooldowns.get(reward_id, 0.0))
		if cooldown > 0.0:
			return {"ok": false, "reason": "recharging", "remaining": cooldown}
		plan = {
			"ok": true,
			"reason": "ready",
			"reward_id": reward_id,
			"kind": kind,
			"mining_rush_seconds": MINING_RUSH_DURATION,
		}
	else:
		plan = RunState.claim_pocket_reward(reward_id) if RunState.has_method("claim_pocket_reward") else {}
	if not bool(plan.get("ok", false)):
		return plan
	if kind == "shrine":
		shrine_cooldowns[reward_id] = SHRINE_RESPAWN_SECONDS
	else:
		claimed_rewards[reward_id] = true
	if kind == "cache":
		_spawn_reward_plan_loot(
			reward_id, 
			Dictionary(plan.get("pending_loot", {})), 
			Vector2(float(cavern.x), float(cavern.y) + 12.0)
		)
		message_changed.emit("%s · CACHE OPENED" % String(cavern.name).to_upper())
	else:
		mining_rush_remaining = float(plan.get("mining_rush_seconds", MINING_RUSH_DURATION))
		message_changed.emit("%s · SUPER DIGGING FOR 30 SECONDS" % String(cavern.name).to_upper())
	pocket_reward_claimed.emit(reward_id, kind)
	_request_redraw()
	return plan


func _reward_by_id(reward_id: String) -> Dictionary:
	for cavern in caverns:
		var reward: Dictionary = Dictionary(cavern.reward)
		if String(reward.id) == reward_id:
			return reward
	return {}


func _pocket_reward_is_claimed(reward_id: String) -> bool:
	if String(_reward_by_id(reward_id).get("kind", "")) == "shrine":
		return float(shrine_cooldowns.get(reward_id, 0.0)) > 0.0
	if RunState.has_method("is_pocket_reward_claimed"):
		return RunState.is_pocket_reward_claimed(reward_id)
	return bool(claimed_rewards.get(reward_id, false))


func _record_mined(kind: String, amount: int) -> void :
	if amount <= 0:
		return
	RunState.record_mined(kind, amount)


func _tool_strike_progress() -> float:
	if int(RunState.drill_level) > 0:
		return 0.2
	match String(RunState.starforge_variant):
		"crusher": return 0.66
		"swift": return 0.28
		"prospector": return 0.42
	return 0.36


func _tool_impact_style(tool: Dictionary) -> String:
	if bool(tool.get("is_drill", false)):
		return "drill"
	return String(RunState.starforge_variant)


func _apply_depth_crusher_wave(center: Vector2i, tool: Dictionary) -> void :
	var power: = maxi(1, int(tool.get("power", 1)))
	var crusher_origin: = _cell_center(center)
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			if x_offset == 0 and y_offset == 0:
				continue
			var cell: = center + Vector2i(x_offset, y_offset)
			if not _terrain_is_solid(cell):
				continue
			var index: = _cell_index(cell)
			var distance: = maxi(absi(x_offset), absi(y_offset))
			var wave_power: = maxi(1, roundi(float(power) * (0.72 if distance == 1 else 0.48)))
			terrain_hp[index] = maxi(0, int(terrain_hp[index]) - wave_power)
			if terrain_hp[index] > 0:
				continue
			dug_indices[index] = true
			if RunState.has_method("mark_terrain_dug"):
				RunState.mark_terrain_dug(mine_id, index, DEPTH)
			_record_mined("deepstone", 1)
			_spawn_drop(_cell_center(cell), "deepstone", 1, "", crusher_origin)
			_discover_cavern_from_cell(index)
			_emit_revealed_resources(cell)


func _attach_crusher_debris(impact: Dictionary, _cell: Vector2i) -> void:
	if String(RunState.starforge_variant) != "crusher" or not bool(impact.get("broken", false)):
		return
	# Actual yielded resources now provide the flying pieces. Retain only the
	# short, data-only ground force pass from CrusherDebris (no fake chunks).
	impact["crusher_force"] = true
	impact["life"] = minf(CrusherDebrisScript.LIFE_SECONDS, 0.34)


func _append_impact(impact: Dictionary) -> void:
	impacts.append(impact)
	while impacts.size() > MAX_ACTIVE_IMPACTS:
		impacts.pop_front()


func _crusher_debris_palette() -> Array[Color]:
	match mine_id:
		"moonMine": return [Color("61798b"), Color("a5bac1"), Color("415463")]
		"emberMine": return [Color("80513b"), Color("c37a48"), Color("4b302b")]
		"starMine": return [Color("654f72"), Color("9d7bab"), Color("40364f")]
	return [Color("79654f"), Color("b4976c"), Color("4b4439")]


func _has_deep_tool() -> bool:
	if deep_tool_override_enabled:
		return deep_tool_override_value
	if RunState.has_method("has_deep_tool"):
		return RunState.has_deep_tool()
	return int(RunState.drill_level) > 0


func _current_tool() -> Dictionary:
	if not tool_stats_override.is_empty():
		return _normalized_tool(tool_stats_override)
	var drill_level: = clampi(int(RunState.drill_level), 0, int(GameData.data.DRILLS.size()) - 1)
	if drill_level > 0:
		var drill: Dictionary = Dictionary(GameData.data.DRILLS[drill_level]).duplicate(true)
		drill["shell_power"] = float(drill.get("shellPower", 1.0))
		drill["yield_bonus"] = float(drill.get("yieldBonus", 0.0))
		drill["yield_multiplier"] = 1
		drill["is_drill"] = true
		return RunState.attune_tool_with_starforge(drill)
	var pickaxe: Dictionary = Dictionary(RunState.current_pickaxe()).duplicate(true)
	var base_shell_power: = 0.72
	var base_yield_bonus: = 0.22 if int(RunState.pickaxe_level) >= 4 else 0.0
	if int(RunState.pickaxe_level) == int(GameData.data.PICKAXES.size()) - 1:
		var mastery_rows: Array = Array(GameData.data.EMBER_MASTERY)
		var mastery: Dictionary = Dictionary(mastery_rows[clampi(int(RunState.ember_mastery), 0, mastery_rows.size() - 1)])
		base_shell_power = float(mastery.get("shellPower", base_shell_power))
		base_yield_bonus = float(mastery.get("bonusYield", base_yield_bonus))
	pickaxe["shell_power"] = base_shell_power
	pickaxe["yield_bonus"] = base_yield_bonus
	pickaxe["yield_multiplier"] = 1
	pickaxe["is_drill"] = false
	var variant_id: = String(RunState.starforge_variant)
	if not variant_id.is_empty() and GameData.data.STARFORGE_VARIANTS.has(variant_id):
		var variant: Dictionary = Dictionary(GameData.data.STARFORGE_VARIANTS[variant_id])
		pickaxe["name"] = String(variant.name)
		pickaxe["power"] = roundi(float(pickaxe.power) * float(variant.powerMultiplier))
		pickaxe["cooldown"] = float(pickaxe.cooldown) * float(variant.cooldownMultiplier)
		pickaxe["shell_power"] = base_shell_power * float(variant.shellMultiplier)
		pickaxe["yield_bonus"] = minf(0.92, base_yield_bonus + float(variant.yieldBonus))
		pickaxe["yield_multiplier"] = maxi(1, int(variant.get("yieldMultiplier", 1)))
	return RunState.apply_tool_forge_effects(pickaxe)


func _normalized_tool(stats: Dictionary) -> Dictionary:
	var result: = stats.duplicate(true)
	result["power"] = int(result.get("power", 1))
	result["cooldown"] = float(result.get("cooldown", 0.72))
	result["shell_power"] = float(result.get("shell_power", result.get("shellPower", 0.72)))
	result["yield_bonus"] = float(result.get("yield_bonus", result.get("yieldBonus", 0.0)))
	result["yield_multiplier"] = maxi(1, int(result.get("yield_multiplier", result.get("yieldMultiplier", 1))))
	result["is_drill"] = bool(result.get("is_drill", false))
	return result


func _terrain_is_solid(cell: Vector2i) -> bool:
	return _cell_in_bounds(cell) and terrain_hp[_cell_index(cell)] > 0


func _visual_is_solid(cell: Vector2i) -> bool:
	if not _cell_in_bounds(cell):
		return false
	var index: = _cell_index(cell)
	return terrain_hp[index] > 0 or concealed_cells.has(index)


func _cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


func _cell_index(cell: Vector2i) -> int:
	return cell.y * cols + cell.x


func _world_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE_SIZE), floori(point.y / TILE_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


func _snap_to_cell_center(position: Vector2) -> Vector2:
	var bounds: = world_size
	if bounds.is_zero_approx() and not GameData.data.is_empty():
		var mine_data: Dictionary = GameData.mine(mine_id)
		bounds = Vector2(float(mine_data.width), float(mine_data.height))
	var cell: = Vector2i(floori(position.x / TILE_SIZE), floori(position.y / TILE_SIZE))
	var snapped: = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE
	return snapped.clamp(Vector2.ONE * TILE_SIZE * 0.5, bounds - Vector2.ONE * TILE_SIZE * 0.5)


func _configure_depth_assets() -> void :
	var paths: = _asset_contract_paths()
	floor_texture = _load_depth_texture(String(paths.floor))
	wall_texture = _load_depth_texture(String(paths.wall))
	shaft_texture = _load_depth_texture(String(paths.shaft))
	sell_texture = _load_depth_texture(String(paths.sell))
	forge_texture = _load_depth_texture(String(paths.forge))
	impact_texture = _load_depth_texture(String(paths.impact))
	pocket_texture = _load_depth_texture(String(paths.pocket))
	cache_texture = _load_depth_texture(String(paths.cache))
	shrine_texture = _load_depth_texture(String(paths.shrine))
	resource_textures = _load_depth_texture_map(Dictionary(paths.nodes))
	wall_hint_textures = _load_depth_texture_map(Dictionary(paths.wall_hints))
	drop_textures = _load_depth_texture_map(Dictionary(paths.drops))


func _load_depth_texture(path: String) -> Texture2D:
	var texture: = load(path) as Texture2D
	assert (texture != null, "Missing Depth 2 texture: %s" % path)
	return texture


func _load_depth_texture_map(paths: Dictionary) -> Dictionary:
	var textures: = {}
	for key_value in paths:
		var key: = String(key_value)
		textures[key] = _load_depth_texture(String(paths[key_value]))
	return textures


func _asset_contract_paths() -> Dictionary:
	if mine_id == "moonMine":
		return {
			"floor": "res://assets/prismatic/floor.png", 
			"wall": "res://assets/prismatic/wall.png", 
			"shaft": "res://assets/prismatic/depth-portal.png", 
			"sell": "res://assets/stations/ore-exchange-v1.png", 
			"forge": "res://assets/stations/drill-forge-workshop-v1.png", 
			"pocket": "res://assets/prismatic/crystal-pocket.png", 
			"cache": "res://assets/prismatic/buried-cache.png", 
			"shrine": "res://assets/prismatic/mining-rush-shrine.png", 
			"impact": "res://assets/world-life/moonglass-impact.png", 
			"nodes": {
				"deepstone": "res://assets/prismatic/deepstone-wall.png", 
				"prismite": "res://assets/prismatic/prismite-node.png", 
				"lunacore": "res://assets/prismatic/lunacore-node.png", 
				"phasecrystal": "res://assets/prismatic/phasecrystal-node.png", 
			}, 
			"wall_hints": {
				"deepstone": "res://assets/prismatic/deepstone-wall.png", 
				"prismite": "res://assets/prismatic/prismite-wall.png", 
				"lunacore": "res://assets/prismatic/lunacore-wall.png", 
				"phasecrystal": "res://assets/prismatic/phasecrystal-wall.png", 
			}, 
			"drops": {
				"deepstone": "res://assets/drops/deepstone-drop.png", 
				"prismite": "res://assets/drops/prismite-drop.png", 
				"lunacore": "res://assets/drops/lunacore-drop.png", 
				"phasecrystal": "res://assets/drops/phasecrystal-drop.png", 
			}, 
		}
	if mine_id == "emberMine":
		return {
			"floor": "res://assets/molten/floor.png", 
			"wall": "res://assets/molten/wall.png", 
			"shaft": "res://assets/molten/depth-portal.png", 
			"sell": "res://assets/stations/ore-exchange-v1.png", 
			"forge": "res://assets/stations/drill-forge-workshop-v1.png", 
			"pocket": "res://assets/molten/crystal-pocket.png", 
			"cache": "res://assets/molten/buried-cache.png", 
			"shrine": "res://assets/molten/mining-rush-shrine.png", 
			"impact": "res://assets/world-life/emberdeep-impact.png", 
			"nodes": {
				"deepstone": "res://assets/molten/deepstone-node.png", 
				"magmaite": "res://assets/molten/magmaite-node.png", 
				"furnaceheart": "res://assets/molten/furnaceheart-node.png", 
				"infernium": "res://assets/molten/infernium-node.png", 
			}, 
			"wall_hints": {
				"deepstone": "res://assets/molten/deepstone-wall.png", 
				"magmaite": "res://assets/molten/magmaite-wall.png", 
				"furnaceheart": "res://assets/molten/furnaceheart-wall.png", 
				"infernium": "res://assets/molten/infernium-wall.png", 
			}, 
			"drops": {
				"deepstone": "res://assets/drops/deepstone-drop.png", 
				"magmaite": "res://assets/drops/magmaite-drop.png", 
				"furnaceheart": "res://assets/drops/furnaceheart-drop.png", 
				"infernium": "res://assets/drops/infernium-drop.png", 
			}, 
		}
	if mine_id == "starMine":
		return {
			"floor": "res://assets/voidstar/floor.png", 
			"wall": "res://assets/voidstar/wall.png", 
			"shaft": "res://assets/voidstar/depth-portal.png", 
			"sell": "res://assets/stations/ore-exchange-v1.png", 
			"forge": "res://assets/stations/drill-forge-workshop-v1.png", 
			"pocket": "res://assets/voidstar/crystal-pocket.png", 
			"cache": "res://assets/voidstar/buried-cache.png", 
			"shrine": "res://assets/voidstar/mining-rush-shrine.png", 
			"impact": "res://assets/world-life/starfall-impact.png", 
			"nodes": {
				"deepstone": "res://assets/voidstar/deepstone-node.png", 
				"voidglass": "res://assets/voidstar/voidglass-node.png", 
				"singularity": "res://assets/voidstar/singularity-node.png", 
			}, 
			"wall_hints": {
				"deepstone": "res://assets/voidstar/deepstone-wall.png", 
				"voidglass": "res://assets/voidstar/voidglass-wall.png", 
				"singularity": "res://assets/voidstar/singularity-wall.png", 
			}, 
			"drops": {
				"deepstone": "res://assets/drops/deepstone-drop.png", 
				"voidglass": "res://assets/drops/voidglass-drop.png", 
				"singularity": "res://assets/drops/singularity-drop.png", 
			}, 
		}
	return {
		"floor": "res://assets/rootwound/floor.png", 
		"wall": "res://assets/rootwound/wall.png", 
		"shaft": "res://assets/rootwound/depth-shaft.png", 
		"sell": "res://assets/stations/ore-exchange-v1.png", 
		"forge": "res://assets/stations/drill-forge-workshop-v1.png", 
		"pocket": "res://assets/mossvein/magic-crystal-pocket.png", 
		"cache": "res://assets/mossvein/buried-cache.png", 
		"shrine": "res://assets/mossvein/mining-rush-shrine.png", 
		"impact": "res://assets/world-life/mossvein-impact.png", 
		"nodes": {
			"deepstone": "res://assets/rootwound/deepstone-node.png", 
			"rootiron": "res://assets/rootwound/rootiron-node.png", 
			"ambercore": "res://assets/rootwound/ambercore-node.png", 
			"burrowsteel": "res://assets/rootwound/burrowsteel-node.png", 
		}, 
		"wall_hints": {"rootiron": "res://assets/rootwound/rootiron-wall.png"}, 
		"drops": {
			"deepstone": "res://assets/drops/deepstone-drop.png", 
			"rootiron": "res://assets/drops/rootiron-drop.png", 
			"ambercore": "res://assets/drops/ambercore-drop.png", 
			"burrowsteel": "res://assets/drops/burrowsteel-drop.png", 
		}, 
	}


func _profile_color(key: String, fallback: String) -> Color:
	return Color(String(depth_profile.get(key, fallback)))


func _depth_short_name() -> String:
	return String(depth_profile.get("name", "Depth 2")).replace(" DEPTHS", "").capitalize()


func _depth_one_return_name() -> String:
	return String(mine.get("name", "Depth 1")).to_upper()


func _request_redraw() -> void :
	redraw_requested = true


func _draw() -> void :
	if mine.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, world_size), _profile_color("floor", "100e0c"), true)
	draw_texture_rect(floor_texture, Rect2(Vector2.ZERO, world_size), true, Color(0.68, 0.66, 0.64, 0.9))
	draw_rect(Rect2(Vector2.ZERO, world_size), Color(_profile_color("floor", "100e0c"), 0.3), true)
	var view_radius: = Vector2(330, 490)
	var start: = _world_to_cell(player.global_position - view_radius)
	var finish: = _world_to_cell(player.global_position + view_radius)
	# Terrain tops and excavation edges are separate passes.  A wall ribbon may
	# overlap the neighbouring top by a few pixels, so drawing it inline with
	# each cell made the next cell cut holes into the edge.
	for row in range(maxi(0, start.y), mini(rows - 1, finish.y) + 1):
		for col in range(maxi(0, start.x), mini(cols - 1, finish.x) + 1):
			var cell: = Vector2i(col, row)
			if _visual_is_solid(cell):
				_draw_terrain_top(cell)
	for row in range(maxi(0, start.y), mini(rows - 1, finish.y) + 1):
		for col in range(maxi(0, start.x), mini(cols - 1, finish.x) + 1):
			var cell: = Vector2i(col, row)
			if _visual_is_solid(cell):
				_draw_terrain_edge_details(cell)
	_draw_pocket_landmarks()
	_draw_resources()
	_draw_depth_landmarks()
	for impact in impacts:
		_draw_impact(impact)
	for drop in drops:
		_draw_drop(drop)
	_draw_target()


func _draw_terrain_top(cell: Vector2i) -> void :
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE).grow(0.7)
	draw_rect(rect, _profile_color("dirt", "211710"), true)
	draw_texture_rect(floor_texture, rect, false, Color(0.82, 0.78, 0.72, 0.72))
	var noise: = fposmod(sin(float(cell.x * 31 + cell.y * 17)) * 43758.5453, 1.0)
	draw_circle(rect.position + Vector2(8.0 + noise * 26.0, 9.0 + (1.0 - noise) * 25.0), 1.0 + noise, Color(0.93, 0.67, 0.39, 0.13))


func _draw_terrain_edge_details(cell: Vector2i) -> void :
	var index: = _cell_index(cell)
	if terrain_hp[index] <= 0:
		return
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE).grow(0.7)
	var noise: = fposmod(sin(float(cell.x * 31 + cell.y * 17)) * 43758.5453, 1.0)
	var open_sides: = [
		not _visual_is_solid(cell + Vector2i.UP), 
		not _visual_is_solid(cell + Vector2i.RIGHT), 
		not _visual_is_solid(cell + Vector2i.DOWN), 
		not _visual_is_solid(cell + Vector2i.LEFT), 
	]
	for side in 4:
		if bool(open_sides[side]):
			_draw_wall_ribbon(cell, rect, side, noise)
	_draw_wall_corner_joins(cell, rect, open_sides, noise)
	for side in 4:
		if bool(open_sides[side]):
			_draw_excavation_edge(cell, rect, side, noise)
	var hp_ratio: = float(terrain_hp[index]) / maxf(1.0, float(terrain_max_hp))
	if hp_ratio < 0.999:
		var damage: = 1.0 - hp_ratio
		var center: = rect.get_center()
		draw_line(rect.position + Vector2(9, 8), center, Color(0.07, 0.035, 0.02, 0.84), 1.5 + damage * 2.3)
		if damage > 0.45:
			draw_line(center, rect.end - Vector2(7, 9), Color(0.07, 0.035, 0.02, 0.84), 1.5 + damage * 2.3)
	if open_sides.has(true):
		_draw_mineral_hint(cell, open_sides)


func _draw_wall_ribbon(cell: Vector2i, rect: Rect2, side: int, noise: float) -> void :
	var starts: = [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	var ends: = [rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y), rect.position]
	var outward_directions: = [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var start: Vector2 = starts[side]
	var finish: Vector2 = ends[side]
	var tangent: = (finish - start).normalized()
	var outward: Vector2 = outward_directions[side]
	var inward: = -outward
	var bedrock: = not _cell_in_bounds(cell + Vector2i(outward))
	var edge: = Color("676b64") if bedrock else _profile_color("wallEdge", "a2764d")
	var dirt: = Color("151713") if bedrock else _profile_color("dirt", "211710")
	var face: = dirt.lerp(edge, 0.28).lightened((noise - 0.5) * 0.07)
	var shadow: = Color(0.008, 0.007, 0.006, 0.84)
	var overlap: = tangent * 1.2

	# Every segment has exactly the tile length plus a tiny overlap.  Adjacent
	# segments therefore read as one continuous cut instead of repeated props.
	draw_colored_polygon(PackedVector2Array([
		start - overlap,
		finish + overlap,
		finish + overlap + outward * 12.0,
		start - overlap + outward * 12.0,
	]), shadow)
	draw_colored_polygon(PackedVector2Array([
		start - overlap + inward * 7.5,
		finish + overlap + inward * 7.5,
		finish + overlap + outward * 2.5,
		start - overlap + outward * 2.5,
	]), Color(face, 0.96))
	draw_line(start - overlap + inward * 5.5, finish + overlap + inward * 5.5, Color(dirt.darkened(0.28), 0.72), 3.5, true)
	draw_line(start - overlap + outward * 7.5, finish + overlap + outward * 7.5, Color(0.01, 0.009, 0.008, 0.34), 5.0, true)
	_draw_wall_ribbon_detail(cell, start, finish, outward, side, bedrock)


func _draw_wall_ribbon_detail(
	cell: Vector2i,
	start: Vector2,
	finish: Vector2,
	outward: Vector2,
	side: int,
	bedrock: bool
) -> void :
	var key: = absi(cell.x * 92821 + cell.y * 68917 + side * 31337)
	if key % 3 != 0:
		return
	var along: = 0.22 + float(key % 53) / 100.0
	var position: = start.lerp(finish, clampf(along, 0.22, 0.75)) - outward * (2.5 + float(key % 3))
	var edge: = Color("858a81") if bedrock else _profile_color("wallEdge", "a2764d")
	var detail: = Color("a9aca4") if bedrock else _profile_color("detail", "f0c47d")
	var radius: = 1.7 + float(key % 4) * 0.38
	draw_circle(position, radius + 1.3, Color(0.012, 0.01, 0.009, 0.62))
	draw_circle(position, radius, Color(edge.lerp(detail, 0.28), 0.48))
	if key % 5 == 0:
		var tangent: = (finish - start).normalized()
		draw_line(position - tangent * 4.0, position + tangent * 5.0 + outward * 1.5, Color(detail, 0.24), 1.2, true)


func _draw_wall_corner_joins(cell: Vector2i, rect: Rect2, open_sides: Array, noise: float) -> void :
	var corners: = [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	var pairs: = [[3, 0], [0, 1], [1, 2], [2, 3]]
	var offsets: = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for corner_index in 4:
		var pair: Array = pairs[corner_index]
		if not bool(open_sides[int(pair[0])]) or not bool(open_sides[int(pair[1])]):
			continue
		var bedrock: = (
			not _cell_in_bounds(cell + offsets[int(pair[0])])
			or not _cell_in_bounds(cell + offsets[int(pair[1])])
		)
		var edge: = Color("676b64") if bedrock else _profile_color("wallEdge", "a2764d")
		var dirt: = Color("151713") if bedrock else _profile_color("dirt", "211710")
		var face: = dirt.lerp(edge, 0.28).lightened((noise - 0.5) * 0.07)
		var point: Vector2 = corners[corner_index]
		draw_circle(point, 9.0, Color(0.008, 0.007, 0.006, 0.82))
		draw_circle(point, 5.2, Color(face, 0.96))


func _draw_excavation_edge(cell: Vector2i, rect: Rect2, side: int, noise: float) -> void :
	var starts: = [rect.position, rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y)]
	var ends: = [rect.position + Vector2(rect.size.x, 0), rect.end, rect.position + Vector2(0, rect.size.y), rect.position]
	var offsets: = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	var start: Vector2 = starts[side]
	var finish: Vector2 = ends[side]
	var bedrock: = not _cell_in_bounds(cell + offsets[side])
	var edge: = Color("858a81") if bedrock else _profile_color("wallEdge", "a2764d")
	var detail: = Color("a9aca4") if bedrock else _profile_color("detail", "f0c47d")
	var ridge: = edge.lerp(detail, 0.12 + noise * 0.08)
	draw_line(start, finish, Color(0.01, 0.009, 0.008, 0.94), 5.2, true)
	draw_line(start, finish, Color(ridge, 0.82), 2.2, true)


func _draw_mineral_hint(cell: Vector2i, open_sides: Array) -> void :
	if not rocks_by_cell.has(cell):
		return
	var rock_index: = -1
	for value in rocks_by_cell[cell]:
		var candidate_index: = int(value)
		if not bool(rocks[candidate_index].broken):
			rock_index = candidate_index
			break
	if rock_index < 0:
		return
	var rock: = rocks[rock_index]
	if not String(rock.cavern_id).is_empty() and not _cavern_is_discovered(String(rock.cavern_id)):
		return
	var side: = open_sides.find(true)
	if side < 0:
		return
	var rotations: = [0.0, PI * 0.5, PI, - PI * 0.5]
	var offsets: = [Vector2(0, -17), Vector2(17, 0), Vector2(0, 17), Vector2(-17, 0)]
	var kind: = String(rock.type)
	var texture: Texture2D = wall_hint_textures.get(kind, resource_textures.get(kind))
	if texture == null:
		return
	var max_height: = 84.0 if bool(rock.drill_gated) or wall_hint_textures.has(kind) else 62.0
	var source_size: = Vector2(texture.get_size())
	var scale_factor: = max_height / maxf(1.0, source_size.y)
	var size: = source_size * scale_factor
	draw_set_transform(_cell_center(cell) + offsets[side], rotations[side], Vector2.ONE)
	draw_texture_rect(texture, Rect2( - size * Vector2(0.5, 0.62), size), false, Color(1, 1, 1, 0.88))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_resources() -> void :
	var margin: = Vector2(100, 120)
	var visible_rect: = _resource_visible_rect(margin)
	for index in rocks.size():
		if not _rock_is_exposed(index):
			continue
		var rock: = rocks[index]
		var position: = Vector2(rock.position)
		if not visible_rect.has_point(position):
			continue
		var kind: = String(rock.type)
		var texture: Texture2D = resource_textures.get(kind)
		if texture == null:
			continue
		var source_size: = Vector2(texture.get_size())
		var max_width: = 101.0 if bool(rock.drill_gated) else 96.0
		var scale_factor: = minf(max_width / source_size.x, 92.0 / source_size.y)
		var hit_pulse: = _resource_hit_pulse(position)
		scale_factor *= 1.0 + hit_pulse * 0.075
		var size: = source_size * scale_factor
		var type_data: Dictionary = Dictionary(GameData.data.ROCK_TYPES[kind])
		if bool(type_data.get("rare", false)) or bool(rock.drill_gated):
			draw_circle(position, 52.0 + hit_pulse * 5.0, Color(Color(String(type_data.edge)), 0.09 + hit_pulse * 0.09))
		draw_texture_rect(texture, Rect2(position - size * Vector2(0.5, 0.56), size), false, Color.WHITE)


func _resource_visible_rect(margin: Vector2) -> Rect2:
	var viewport_size: = get_viewport_rect().size
	var view_center: = player.global_position
	var camera_zoom: = Vector2.ONE
	if is_instance_valid(player.camera):
		camera_zoom = Vector2(absf(player.camera.zoom.x), absf(player.camera.zoom.y))
		if player.camera.enabled and player.camera.is_inside_tree():
			view_center = player.camera.get_screen_center_position()
	var world_view_size: = Vector2(
		viewport_size.x / maxf(0.01, camera_zoom.x), 
		viewport_size.y / maxf(0.01, camera_zoom.y)
	)
	return Rect2(
		view_center - world_view_size * 0.5 - margin, 
		world_view_size + margin * 2.0
	)


func _resource_hit_pulse(position: Vector2) -> float:
	var strength: = 0.0
	for impact in impacts:
		if Vector2(impact.position).distance_squared_to(position) > 2500.0:
			continue
		var progress: = clampf(float(impact.age) / maxf(0.001, float(impact.life)), 0.0, 1.0)
		strength = maxf(strength, sin(progress * PI))
	return strength


func _draw_pocket_landmarks() -> void :
	for cavern in caverns:
		if not bool(cavern.discovered):
			continue
		var reward: Dictionary = Dictionary(cavern.reward)
		var reward_id: = String(reward.id)
		var kind: = String(reward.kind)
		var position: = Vector2(float(cavern.x), float(cavern.y))
		if player.global_position.distance_to(position) > 520.0:
			continue
		var claimed: = _pocket_reward_is_claimed(reward_id)
		if kind in ["crystal", "motherlode"]:
			var pocket_size: = Vector2(146, 106)
			draw_texture_rect(
				pocket_texture, 
				Rect2(position - pocket_size * Vector2(0.5, 0.62), pocket_size), 
				false, 
				Color(1, 1, 1, 0.18 if claimed else 0.5)
			)
		else:
			var texture: Texture2D = cache_texture if kind == "cache" else shrine_texture
			var source_size: = Vector2(texture.get_size())
			var scale_factor: = minf(112.0 / source_size.x, 96.0 / source_size.y)
			var size: = source_size * scale_factor
			draw_circle(
				position + Vector2(0, 14), 
				49.0, 
				Color(0.93, 0.64, 0.29, 0.025 if claimed else 0.08)
			)
			draw_texture_rect(
				texture, 
				Rect2(position - size * Vector2(0.5, 0.6), size), 
				false, 
				Color(0.48, 0.47, 0.45, 0.3) if claimed else Color.WHITE
			)
		_draw_pocket_landmark_label(cavern, reward, position, claimed)


func _draw_pocket_landmark_label(
	cavern: Dictionary, 
	reward: Dictionary, 
	position: Vector2, 
	claimed: bool
) -> void :
	var name: = String(cavern.name).to_upper()
	var reward_label: String
	if String(reward.get("kind", "")) == "shrine":
		var remaining: = ceili(float(shrine_cooldowns.get(String(reward.id), 0.0)))
		reward_label = "RECHARGING %dS" % remaining if claimed else "SUPER DIGGING READY"
	else:
		reward_label = "DEPLETED" if claimed else String(reward.get("label", reward.get("kind", "POCKET"))).to_upper()
	var width: = clampf(90.0 + float(maxi(name.length(), reward_label.length())) * 3.8, 158.0, 226.0)
	var rect: = Rect2(position + Vector2( - width * 0.5, 67.0), Vector2(width, 42.0))
	var accent: = _profile_color("detail", "ffd58a")
	draw_rect(rect, Color(0.008, 0.011, 0.015, 0.84), true)
	draw_rect(rect, Color(accent, 0.26 if claimed else 0.58), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 16), name, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 9, Color(accent, 0.72 if claimed else 0.98))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 33), reward_label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8, Color(0.76, 0.78, 0.82, 0.76 if claimed else 0.94))


func _draw_depth_landmarks() -> void :
	_draw_landmark_texture(shaft_texture, depth_entrance, Vector2(158, 138), 40.0)
	draw_string(ThemeDB.fallback_font, depth_entrance + Vector2(-92, 68), "ASCEND TO %s" % _depth_one_return_name(), HORIZONTAL_ALIGNMENT_CENTER, 184, 9, _profile_color("detail", "f0c47d"))
	if active_context == "depthExit":
		draw_arc(depth_entrance + Vector2(0, 5), 76.0, 0, TAU, 48, Color(_profile_color("detail", "f0c47d"), 0.74), 2.0)

	var sell: = Vector2(float(station_positions.sell.x), float(station_positions.sell.y))
	var forge: = Vector2(float(station_positions.forge.x), float(station_positions.forge.y))
	_draw_station(sell_texture, sell, "ORE EXCHANGE", active_context == "depthSell")
	_draw_station(forge_texture, forge, "DRILL FORGE", active_context == "drillForge")


func _draw_station(texture: Texture2D, position: Vector2, label: String, selected: bool) -> void :
	draw_circle(position + Vector2(0, 48), 76.0, Color(0.01, 0.008, 0.005, 0.32))
	_draw_landmark_texture(texture, position, Vector2(220, 154), 57.0)
	if selected:
		draw_arc(position + Vector2(0, 8), 88.0, 0, TAU, 48, Color(_profile_color("detail", "f0c47d"), 0.72), 2.0)
	draw_string(ThemeDB.fallback_font, position + Vector2(-82, 78), label, HORIZONTAL_ALIGNMENT_CENTER, 164, 10, _profile_color("detail", "f0c47d"))


func _draw_landmark_texture(texture: Texture2D, position: Vector2, bounds: Vector2, bottom: float) -> void :
	var source_size: = Vector2(texture.get_size())
	var scale_factor: = minf(bounds.x / source_size.x, bounds.y / source_size.y)
	var size: = source_size * scale_factor
	draw_texture_rect(texture, Rect2(position + Vector2( - size.x * 0.5, bottom - size.y), size), false)


func _draw_drop(drop: Dictionary) -> void :
	if bool(drop.get("visual_suppressed", false)):
		return
	var kind: = String(drop.kind)
	var texture: Texture2D = drop_textures.get(kind, drop_textures.get("deepstone"))
	if texture == null:
		return
	var pulse: = 1.0 + sin(float(drop.age) * 6.0) * 0.06
	var position: = CrusherLootBurstScript.draw_position(drop)
	var alpha: = clampf((LOOSE_RESOURCE_LIFETIME - float(drop.age)) / LOOSE_RESOURCE_FADE_SECONDS, 0.0, 1.0)
	draw_texture_rect(texture, DropVisuals.draw_rect(kind, texture, position, pulse), false, Color(1, 1, 1, alpha))
	var amount: = int(drop.get("amount", 1))
	if amount > 1:
		var label: = "x%d" % amount
		var badge_width: = maxf(24.0, float(label.length() * 6 + 8))
		var badge_rect: = Rect2(position + Vector2(8.0, -25.0), Vector2(badge_width, 16.0))
		draw_rect(badge_rect, Color(0.035, 0.027, 0.02, alpha * 0.9), true)
		draw_rect(badge_rect, Color(0.94, 0.71, 0.31, alpha * 0.82), false, 1.0)
		draw_string(
			ThemeDB.fallback_font,
			badge_rect.position + Vector2(0.0, 12.0),
			label,
			HORIZONTAL_ALIGNMENT_CENTER,
			badge_rect.size.x,
			10,
			Color(1.0, 0.91, 0.66, alpha)
		)


func _draw_impact(impact: Dictionary) -> void :
	var progress: = clampf(float(impact.age) / float(impact.life), 0.0, 1.0)
	var frame: = mini(3, floori(progress * 4.0))
	var source: = Rect2(Vector2(frame * 256, 0), Vector2(256, 256))
	var size: = Vector2.ONE * (76.0 if bool(impact.broken) else 62.0)
	draw_texture_rect_region(impact_texture, Rect2(Vector2(impact.position) - size * 0.5, size), source, Color(1, 1, 1, 1.0 - progress))
	var style: = String(impact.get("style", ""))
	var center: = Vector2(impact.position)
	var alpha: = 1.0 - progress
	match style:
		"crusher":
			pass
		"swift":
			for streak in range(3):
				var y: = float(streak - 1) * 8.0
				draw_line(center + Vector2(-42, y), center + Vector2(42, y - 10), Color(0.38, 0.94, 1.0, alpha * (0.82 - streak * 0.12)), 2.8 - streak * 0.5)
		"prospector":
			for orbit in range(2):
				var phase: = progress * TAU + float(orbit) * PI
				var point: = center + Vector2(cos(phase) * 42.0, sin(phase) * 18.0)
				draw_circle(point, 5.5, Color(1.0, 0.76, 0.22, alpha * 0.86))
		"drill":
			for ring in range(3):
				draw_arc(center, 12.0 + ring * 9.0 + progress * 12.0, progress * TAU * 4.0 + ring, progress * TAU * 4.0 + ring + 4.4, 18, Color(1.0, 0.58, 0.16, alpha * (0.78 - ring * 0.16)), 2.4)
	if bool(impact.get("crusher_force", false)):
		CrusherDebrisScript.draw_burst(self, impact, _crusher_debris_palette())


func _draw_target() -> void :
	if current_target_kind.is_empty():
		return
	var color: = Color("f0c47d")
	var center: = Vector2.ZERO
	var radius: = 30.0
	var label: = ""
	if current_target_kind == "terrain" and _terrain_is_solid(current_target_cell):
		center = _cell_center(current_target_cell)
		var hits: = ceili(float(terrain_hp[_cell_index(current_target_cell)]) / maxf(1.0, float(_current_tool().power)))
		label = "DEEPSTONE · %d HIT%s" % [hits, "" if hits == 1 else "S"] if _has_deep_tool() else "STARFORGE REQUIRED"
		radius = 28.0
	elif current_target_kind == "rock" and _rock_is_exposed(current_target_rock):
		var rock: = rocks[current_target_rock]
		var type_data: Dictionary = Dictionary(GameData.data.ROCK_TYPES[String(rock.type)])
		color = Color(String(type_data.edge))
		center = Vector2(rock.position)
		label = _rock_target_label(rock)
		radius = 39.0
	else:
		return
	draw_arc(center, radius, - PI * 0.82, PI * 0.82, 28, Color(color, 0.78), 2.2)
	draw_circle(_target_contact_point(), 3.5, Color(color, 0.96))
	draw_string(ThemeDB.fallback_font, center + Vector2(-72, - radius - 10), label, HORIZONTAL_ALIGNMENT_CENTER, 144, 10, color)


func _rock_target_label(rock: Dictionary) -> String:
	var required_drill: = int(rock.requires_drill_level)
	if required_drill > int(RunState.drill_level):
		return "%s REQUIRED" % String(GameData.data.DRILLS[required_drill].name).to_upper()
	if bool(rock.requires_deep_tool) and not _has_deep_tool():
		return "STARFORGE REQUIRED"
	if int(rock.required_pickaxe) > int(RunState.pickaxe_level):
		return "%s REQUIRED" % String(GameData.data.PICKAXES[int(rock.required_pickaxe)].name).to_upper()
	var tool: = _current_tool()
	var hits: = 0
	var shell: = int(rock.shell)
	var hp: = int(rock.hp)
	var shell_multiplier: = maxf(0.01, float(tool.shell_power))
	while (shell > 0 or hp > 0) and hits < 999:
		hits += 1
		if shell > 0:
			var shell_damage: = ceili(float(tool.power) * shell_multiplier)
			var overflow: = maxi(0, shell_damage - shell)
			shell = maxi(0, shell - shell_damage)
			if shell == 0 and overflow > 0:
				hp = maxi(0, hp - floori(float(overflow) / shell_multiplier))
		else:
			hp = maxi(0, hp - int(tool.power))
	return "%s · %d HIT%s" % [String(rock.type).to_upper(), hits, "" if hits == 1 else "S"]


func _build_lighting() -> void :
	darkness.color = _ambient_modulate_color()
	var headlamp_color: = _profile_color("detail", "ffd58a")
	var legacy_headlamp: = player.get_node_or_null("RootwoundHeadlamp")
	if legacy_headlamp != null:
		legacy_headlamp.queue_free()
	var existing_headlamp: = player.get_node_or_null("PremiumHeadlamp")
	if existing_headlamp == null:
		var headlamp: = HeadlampBeamScript.new()
		headlamp.name = "PremiumHeadlamp"
		headlamp.position = Vector2(0, -48)
		player.add_child(headlamp)
		headlamp.configure(headlamp_color, Vector2(player.facing_vector), 0.0, 600.0)
	else:
		existing_headlamp.configure(headlamp_color, Vector2(player.facing_vector), 0.0, 600.0)
	if player.camera.has_method("set_cave_headlamp_framing"):
		player.camera.set_cave_headlamp_framing(true, Vector2(player.facing_vector))
	_rebuild_landmark_light_specs()
	_clear_landmark_light_nodes()
	active_landmark_light_ids.clear()
	last_landmark_light_refresh_position = Vector2(INF, INF)
	_refresh_landmark_lights(true)


func _rebuild_landmark_light_specs() -> void :
	landmark_light_specs.clear()
	var headlamp_color: = _profile_color("detail", "ffd58a")
	var accent_color: = _profile_color("accent", "f6b663")
	var edge_color: = _profile_color("wallEdge", "80e0b1")
	landmark_light_specs.append({
		"id": "%s:depth_exit" % mine_id, 
		"kind": "depth_exit", 
		"position": depth_entrance + Vector2(-44, -25), 
		"radius": 238.0, 
		"energy": 1.08, 
		"color": headlamp_color, 
		"with_lamp": true, 
	})
	var sell: = Vector2(float(station_positions.sell.x), float(station_positions.sell.y))
	var forge: = Vector2(float(station_positions.forge.x), float(station_positions.forge.y))
	landmark_light_specs.append({
		"id": "%s:sell" % mine_id, 
		"kind": "sell", 
		"position": sell + Vector2(0, -18), 
		"radius": 188.0, 
		"energy": 0.86, 
		"color": accent_color, 
		"with_lamp": false, 
	})
	landmark_light_specs.append({
		"id": "%s:forge" % mine_id, 
		"kind": "forge", 
		"position": forge + Vector2(0, -18), 
		"radius": 206.0, 
		"energy": 0.98, 
		"color": edge_color, 
		"with_lamp": false, 
	})
	for cavern in caverns:
		if bool(cavern.discovered):
			landmark_light_specs.append({
				"id": "%s:cavern:%s" % [mine_id, String(cavern.id)], 
				"kind": "cavern", 
				"position": Vector2(float(cavern.x), float(cavern.y)), 
				"radius": 164.0, 
				"energy": 0.52, 
				"color": accent_color, 
				"with_lamp": false, 
			})


func _refresh_landmark_lights(force: bool = false) -> void :
	if not is_instance_valid(landmark_lights):
		return
	if (
		not force
		and player.global_position.distance_to(last_landmark_light_refresh_position) < LANDMARK_LIGHT_REFRESH_DISTANCE
	):
		return
	last_landmark_light_refresh_position = player.global_position
	landmark_light_refresh_count += 1
	var previous_ids: = active_landmark_light_ids.duplicate()
	var candidates: Array[Dictionary] = []
	for spec_value in landmark_light_specs:
		var spec: Dictionary = Dictionary(spec_value).duplicate(true)
		var spec_id: = String(spec.id)
		var was_active: = previous_ids.has(spec_id)
		var distance: = player.global_position.distance_to(Vector2(spec.position))
		var eligibility_radius: = LANDMARK_LIGHT_EXIT_RADIUS if was_active else LANDMARK_LIGHT_ENTER_RADIUS
		if distance > eligibility_radius:
			continue
		spec["score"] = distance - (LANDMARK_LIGHT_HYSTERESIS_BONUS if was_active else 0.0)
		candidates.append(spec)
	var selected_specs: Array[Dictionary] = []
	while not candidates.is_empty() and selected_specs.size() < MAX_ACTIVE_LANDMARK_LIGHTS:
		var closest_index: = 0
		var closest_score: = INF
		for index in candidates.size():
			if float(candidates[index].score) < closest_score:
				closest_score = float(candidates[index].score)
				closest_index = index
		selected_specs.append(candidates.pop_at(closest_index))
	var selected_ids: Array[String] = []
	for spec in selected_specs:
		selected_ids.append(String(spec.id))
	if _same_light_id_set(selected_ids, active_landmark_light_ids):
		return
	active_landmark_light_ids = selected_ids
	_clear_landmark_light_nodes()
	for spec in selected_specs:
		_add_landmark_light(Dictionary(spec))
	landmark_light_rebuild_count += 1


func _same_light_id_set(left: Array[String], right: Array[String]) -> bool:
	if left.size() != right.size():
		return false
	for value in left:
		if not right.has(value):
			return false
	return true


func _clear_landmark_light_nodes() -> void :
	for child in landmark_lights.get_children():
		landmark_lights.remove_child(child)
		child.queue_free()


func _ambient_modulate_color() -> Color:
	match mine_id:
		"moonMine":
			return Color(0.36, 0.43, 0.48, 1.0)
		"emberMine":
			return Color(0.5, 0.35, 0.28, 1.0)
		"starMine":
			return Color(0.38, 0.37, 0.52, 1.0)
		_:
			return Color(0.48, 0.43, 0.35, 1.0)


func _add_landmark_light(spec: Dictionary) -> void :
	var anchor: = Node2D.new()
	anchor.name = "LandmarkLight_%s" % String(spec.id).replace(":", "_")
	anchor.position = Vector2(spec.position)
	anchor.set_meta("light_anchor_id", String(spec.id))
	landmark_lights.add_child(anchor)
	if bool(spec.with_lamp):
		var lamp: = Sprite2D.new()
		lamp.texture = LAMP_TEXTURE
		lamp.scale = Vector2.ONE * 0.16
		lamp.position = Vector2.ZERO
		lamp.z_index = 8
		anchor.add_child(lamp)
	anchor.add_child(_make_light(float(spec.radius), float(spec.energy), Color(spec.color)))


func _make_light(radius: float, energy: float, color: Color) -> PointLight2D:
	var light: = PointLight2D.new()
	light.texture = _shared_landmark_radial_texture()
	light.texture_scale = radius / 256.0
	light.energy = energy
	light.color = color
	return light


func _shared_landmark_radial_texture() -> Texture2D:
	if shared_landmark_light_texture != null:
		return shared_landmark_light_texture
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.58, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.62), Color(1, 1, 1, 0)])
	var texture: = GradientTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	shared_landmark_light_texture = texture
	return shared_landmark_light_texture


func contract_snapshot() -> Dictionary:
	var resource_counts: = {}
	var drill_gated: = 0
	var drill_gate_counts: = {}
	var required_drill_counts: = {}
	for rock in rocks:
		resource_counts[String(rock.type)] = int(resource_counts.get(String(rock.type), 0)) + 1
		if bool(rock.drill_gated):
			drill_gated += 1
			var deposit_id: = String(rock.deposit_id)
			drill_gate_counts[deposit_id] = int(drill_gate_counts.get(deposit_id, 0)) + 1
		var required_drill: = int(rock.requires_drill_level)
		required_drill_counts[required_drill] = int(required_drill_counts.get(required_drill, 0)) + 1
	var solid_cells: = 0
	for hp in terrain_hp:
		if int(hp) > 0:
			solid_cells += 1
	return {
		"mine_id": mine_id, 
		"initialized": interior_initialized, 
		"build_count": interior_build_count, 
		"configured_world_seed": configured_world_seed, 
		"depth": DEPTH, 
		"name": String(depth_profile.name), 
		"world_size": world_size, 
		"tile_size": TILE_SIZE, 
		"terrain_hp": terrain_max_hp, 
		"solid_cells": solid_cells, 
		"depth_entrance": depth_entrance, 
		"entry_spawn": entry_spawn(), 
		"stations": station_positions.duplicate(true), 
		"resource_count": rocks.size(), 
		"resource_counts": resource_counts, 
		"drill_gated_count": drill_gated, 
		"drill_gate_counts": drill_gate_counts, 
		"required_drill_counts": required_drill_counts, 
		"cavern_count": caverns.size(), 
		"shrine_respawn_seconds": SHRINE_RESPAWN_SECONDS,
		"shrine_cooldowns": shrine_cooldowns.duplicate(true),
		"asset_contract": _asset_contract_paths(), 
		"palette": {
			"dirt": String(depth_profile.get("dirt", "#211710")), 
			"floor": String(depth_profile.get("floor", "#100e0c")), 
			"wall_edge": String(depth_profile.get("wallEdge", "#80e0b1")), 
			"accent": String(depth_profile.get("accent", "#f6b663")), 
			"detail": String(depth_profile.get("detail", "#ffd58a")), 
		}, 
		"lighting_contract": {
			"ambient": _ambient_modulate_color(), 
			"headlamp": _profile_color("detail", "ffd58a"), 
			"sell_station": _profile_color("accent", "f6b663"), 
			"forge_station": _profile_color("wallEdge", "80e0b1"), 
		}, 
	}


func depth_content_snapshot() -> Dictionary:
	var cavern_rows: Array[Dictionary] = []
	var reward_kind_counts: = {}
	for cavern in caverns:
		var reward: Dictionary = Dictionary(cavern.reward)
		var reward_id: = String(reward.id)
		var linked_rocks: = 0
		var live_linked_rocks: = 0
		for rock in rocks:
			if String(rock.pocket_reward_id) != reward_id:
				continue
			linked_rocks += 1
			if not bool(rock.broken):
				live_linked_rocks += 1
		var kind: = String(reward.kind)
		reward_kind_counts[kind] = int(reward_kind_counts.get(kind, 0)) + 1
		cavern_rows.append({
			"id": String(cavern.id), 
			"name": String(cavern.name), 
			"source_name": String(cavern.get("source_name", cavern.name)), 
			"position": Vector2(float(cavern.x), float(cavern.y)), 
			"radii": Vector2(float(cavern.rx), float(cavern.ry)), 
			"boundary_count": Array(cavern.boundary).size(), 
			"reward_id": reward_id, 
			"reward_kind": kind, 
			"reward_label": String(reward.label), 
			"linked_rocks": linked_rocks, 
			"live_linked_rocks": live_linked_rocks, 
			"discovered": bool(cavern.discovered), 
			"claimed": _pocket_reward_is_claimed(reward_id), 
		})
	return {
		"mine_id": mine_id, 
		"depth_name": String(depth_profile.name), 
		"return_name": _depth_one_return_name(), 
		"route_signature": _route_signature(), 
		"caverns": cavern_rows, 
		"cavern_count": cavern_rows.size(), 
		"reward_kind_counts": reward_kind_counts, 
		"asset_contract": _asset_contract_paths(), 
	}


func _route_signature() -> String:


	var parts: = PackedStringArray([
		"entry:%.4f,%.4f" % [depth_entrance.x / world_size.x, depth_entrance.y / world_size.y], 
	])
	for cavern in caverns:
		parts.append(
			"%.4f,%.4f/%.4f,%.4f" % [
				float(cavern.x) / world_size.x, 
				float(cavern.y) / world_size.y, 
				float(cavern.rx) / world_size.x, 
				float(cavern.ry) / world_size.y, 
			]
		)
	return "|".join(parts)


func lighting_snapshot() -> Dictionary:
	var active_positions: Array[Vector2] = []
	var active_ids: Array[String] = []
	for child in landmark_lights.get_children():
		active_positions.append(Vector2(child.position))
		active_ids.append(String(child.get_meta("light_anchor_id", "")))
	var headlamp: = player.get_node_or_null("PremiumHeadlamp")
	var headlamp_light_count: = 0
	if headlamp != null:
		headlamp_light_count = headlamp.find_children("*", "PointLight2D", true, false).size()
	return {
		"spec_count": landmark_light_specs.size(), 
		"active_count": active_ids.size(), 
		"active_ids": active_ids, 
		"active_positions": active_positions, 
		"max_active": MAX_ACTIVE_LANDMARK_LIGHTS, 
		"enter_radius": LANDMARK_LIGHT_ENTER_RADIUS, 
		"exit_radius": LANDMARK_LIGHT_EXIT_RADIUS, 
		"refresh_distance": LANDMARK_LIGHT_REFRESH_DISTANCE, 
		"hysteresis_bonus": LANDMARK_LIGHT_HYSTERESIS_BONUS, 
		"last_refresh_position": last_landmark_light_refresh_position, 
		"refresh_count": landmark_light_refresh_count, 
		"rebuild_count": landmark_light_rebuild_count, 
		"headlamp_present": headlamp != null, 
		"headlamp_light_count": headlamp_light_count, 
		"headlamp": headlamp.debug_snapshot() if headlamp != null and headlamp.has_method("debug_snapshot") else {}, 
		"camera": player.camera.headlamp_framing_snapshot() if player.camera.has_method("headlamp_framing_snapshot") else {}, 
		"player_position": player.global_position, 
	}


func spawn_safety_snapshot() -> Dictionary:
	var sell: = Vector2(float(station_positions.sell.x), float(station_positions.sell.y))
	var forge: = Vector2(float(station_positions.forge.x), float(station_positions.forge.y))
	var spawn: = entry_spawn()
	return {
		"mine_id": mine_id, 
		"entry_spawn": spawn, 
		"entry_collision": collision_at(spawn), 
		"depth_exit": depth_entrance, 
		"depth_exit_collision": collision_at(depth_entrance), 
		"sell": sell, 
		"sell_collision": collision_at(sell), 
		"forge": forge, 
		"forge_collision": collision_at(forge), 
		"entry_exit_distance": spawn.distance_to(depth_entrance), 
		"exit_context_radius": SHAFT_CONTEXT_RADIUS, 
		"return_name": _depth_one_return_name(), 
	}


func target_snapshot() -> Dictionary:
	return {
		"kind": current_target_kind, 
		"cell": current_target_cell, 
		"rock_index": current_target_rock, 
		"contact": _target_contact_point(), 
	}


func heat_streak_snapshot() -> Dictionary:
	return {
		"unlocked": _heat_streak_unlocked(), 
		"active": heat_streak_active, 
		"elapsed": heat_streak_elapsed, 
		"progress": _heat_streak_progress(), 
		"speed_multiplier": _heat_streak_speed(), 
		"max_speed": HEAT_STREAK_MAX_SPEED, 
		"build_seconds": HEAT_STREAK_BUILD_SECONDS, 
	}
