extends Node2D

const HeadlampBeamScript = preload("res://scripts/lighting/headlamp_beam.gd")
const DropVisuals = preload("res://scripts/world/drop_visuals.gd")
const CrusherDebrisScript = preload("res://scripts/world/crusher_debris.gd")
const CrusherLootBurstScript = preload("res://scripts/world/crusher_loot_burst.gd")

signal exit_context_changed(active: bool)
signal depth_context_changed(active: bool)
signal depth_discovered(world_position: Vector2)
signal message_changed(message: String)
signal pocket_reward_claimed(reward_id: String, reward_kind: String)

const TILE_SIZE: = 48.0
const PLAYER_RADIUS: = 23.0
const MINING_RANGE: = 116.0
const CORNER_AIM_ASSIST: = PLAYER_RADIUS + 10.0
const REDRAW_INTERVAL: = 1.0 / 30.0
const DEPTH_PORTAL_RADIUS: = 128.0
const DEPTH_CONTEXT_RADIUS: = 118.0
const DEPTH_PORTAL_RESOURCE_CLEARANCE: = 136.0
const DEPTH_STATION_RESOURCE_CLEARANCE: = 132.0
const HEAT_STREAK_BUILD_SECONDS: = 5.0
const HEAT_STREAK_MAX_SPEED: = 1.3
const MINING_RUSH_DURATION: = 30.0
const MINING_RUSH_COOLDOWN_MULTIPLIER: = 0.65
const LOOSE_RESOURCE_LIFETIME: = 50.0
const LOOSE_RESOURCE_FADE_SECONDS: = 3.0
const DROP_MAGNET_DELAY: = 0.16
const DROP_MAGNET_SPEED: = 720.0
const DROP_MAGNET_COLLECT_RADIUS: = 28.0
const MAX_VISIBLE_WORK_LIGHTS: = 4
const WORK_LIGHT_CULL_RADIUS: = 620.0
const WORK_LIGHT_REFRESH_DISTANCE: = 150.0

const LAMP_TEXTURE: = preload("res://assets/entrances/depth-work-lamp.png")
const MINE_ASSETS: = {
	"mossMine": {
		"floor": "res://assets/mossvein/cave-floor.png", "wall": "res://assets/mossvein/cave-wall.png", 
		"bedrock": "res://assets/mossvein/unbreakable-wall.png", "entrance": "res://assets/entrances/mossvein-entrance.png", 
		"impact": "res://assets/world-life/mossvein-impact.png", "style": "mossvein", 
		"pocket": "res://assets/mossvein/magic-crystal-pocket.png", 
		"cache": "res://assets/mossvein/buried-cache.png", 
		"shrine": "res://assets/mossvein/mining-rush-shrine.png"
	}, 
	"moonMine": {
		"floor": "res://assets/moonglass/floor.png", "wall": "res://assets/moonglass/wall.png", 
		"bedrock": "res://assets/moonglass/unbreakable-wall.png", "entrance": "res://assets/entrances/moonglass-entrance.png", 
		"impact": "res://assets/world-life/moonglass-impact.png", "style": "moonglass", 
		"pocket": "res://assets/moonglass/crystal-pocket.png", 
		"cache": "res://assets/moonglass/buried-cache.png", 
		"shrine": "res://assets/moonglass/mining-rush-shrine.png", 
		"route_marker": "res://assets/moonglass/route-marker.png"
	}, 
	"emberMine": {
		"floor": "res://assets/emberdeep/floor.png", "wall": "res://assets/emberdeep/wall.png", 
		"bedrock": "res://assets/emberdeep/unbreakable-wall.png", "entrance": "res://assets/entrances/emberdeep-entrance.png", 
		"impact": "res://assets/world-life/emberdeep-impact.png", "style": "emberdeep", 
		"pocket": "res://assets/emberdeep/crystal-pocket.png", 
		"cache": "res://assets/emberdeep/buried-cache.png", 
		"shrine": "res://assets/emberdeep/mining-rush-shrine.png", 
		"route_marker": "res://assets/emberdeep/route-marker.png"
	}, 
	"starMine": {
		"floor": "res://assets/starfall/floor.png", "wall": "res://assets/starfall/wall.png", 
		"bedrock": "res://assets/starfall/unbreakable-wall.png", "entrance": "res://assets/entrances/starfall-entrance.png", 
		"impact": "res://assets/world-life/starfall-impact.png", "style": "starfall", 
		"pocket": "res://assets/starfall/crystal-pocket.png", 
		"cache": "res://assets/starfall/buried-cache.png", 
		"shrine": "res://assets/starfall/mining-rush-shrine.png", 
		"route_marker": "res://assets/starfall/route-marker.png"
	}
}
const RESOURCE_ASSETS: = {
	"stone": "res://assets/minerals/stone-node.png", 
	"copper": "res://assets/minerals/copper-wall.png", "gold": "res://assets/minerals/gold-wall.png", 
	"moonglass": "res://assets/moonglass/moonglass-wall.png", "starshard": "res://assets/moonglass/starshard-wall.png", 
	"emberstone": "res://assets/emberdeep/emberstone-wall.png", "sunslag": "res://assets/emberdeep/sunslag-wall.png", 
	"astralite": "res://assets/starfall/astralite-wall.png", "crownstone": "res://assets/starfall/crownstone-wall.png"
}
const RESOURCE_NODE_ASSETS: = {
	"stone": "res://assets/minerals/stone-node.png", "copper": "res://assets/minerals/copper-node.png", "gold": "res://assets/minerals/gold-node.png", 
	"moonglass": "res://assets/moonglass/moonglass-node.png", "starshard": "res://assets/moonglass/starshard-node.png", 
	"emberstone": "res://assets/emberdeep/emberstone-node.png", "sunslag": "res://assets/emberdeep/sunslag-node.png", 
	"astralite": "res://assets/starfall/astralite-node.png", "crownstone": "res://assets/starfall/crownstone-node.png"
}
const BARRIER_ASSETS: = {
	"moon_prism_gate": "res://assets/moonglass/prismatic-fault-barrier-core.png", 
	"moon_star_lock": "res://assets/moonglass/starbound-geode-barrier-core.png", 
	"ember_bulkhead": "res://assets/emberdeep/cinder-bulkhead-barrier-core.png", 
	"ember_crucible_lock": "res://assets/emberdeep/crucible-seal-barrier-core.png", 
	"star_bridge_lock": "res://assets/starfall/astral-bridge-lock-barrier-core.png", 
	"star_crown_lock": "res://assets/starfall/crownstone-ward-barrier-core.png", 
}
const BARRIER_ACCENTS: = {
	"mossMine": "d98d2f", 
	"moonMine": "58d4ef", 
	"emberMine": "ff6b25", 
	"starMine": "a978ff", 
}
const DEPTH_SHAFT_ASSETS: = {
	"mossMine": "res://assets/rootwound/depth-shaft.png", 
	"moonMine": "res://assets/prismatic/depth-portal.png", 
	"emberMine": "res://assets/molten/depth-portal.png", 
	"starMine": "res://assets/voidstar/depth-portal.png", 
}

@onready var player: CharacterBody2D = $Player
@onready var darkness: CanvasModulate = $Darkness

var mine_id: = "mossMine"
var mine: Dictionary
var mine_assets: Dictionary
var texture_cache: Dictionary = {}
var floor_texture: Texture2D
var wall_texture: Texture2D
var bedrock_texture: Texture2D
var entrance_texture: Texture2D
var impact_texture: Texture2D
var depth_shaft_texture: Texture2D
var pocket_texture: Texture2D
var cache_texture: Texture2D
var shrine_texture: Texture2D
var route_marker_texture: Texture2D
var world_size: = Vector2.ZERO
var cols: = 0
var rows: = 0
var blocks: Dictionary = {}
var resource_guide_cells: Array[Vector2i] = []
var drops: Array[Dictionary] = []
var impacts: Array[Dictionary] = []
var respawns: Array[Dictionary] = []
var current_target: = Vector2i(-1, -1)
var target_pulse: = 0.0
var exit_near: = false
var depth_near: = false
var depth_entrance: = Vector2.ZERO
var depth_entrance_cells: Dictionary = {}
var depth_entrance_boundary: Dictionary = {}
var concealed_cavern_cells: Dictionary = {}
var cavern_boundary_by_index: Dictionary = {}
var cavern_by_id: Dictionary = {}
var pocket_reward_cells: Dictionary = {}
var active: = false
var external_mine_held: = false
var swing_active: = false
var swing_elapsed: = 0.0
var swing_duration: = 0.72
var swing_hit: = false
var mining_visual_elapsed: = 0.0
var mining_visual_running: = false
var heat_streak_elapsed: = 0.0
var heat_streak_active: = false
var mining_rush_remaining: = 0.0
var work_lamps: Array[Node] = []
var work_light_anchors: Array[Dictionary] = []
var last_light_refresh_position: = Vector2(INF, INF)
var shared_work_light_texture: Texture2D
var active_work_light_ids: Array[String] = []
var role_block_counts: Dictionary = {}
var interior_initialized: = false
var interior_build_count: = 0
var configured_world_seed: = -1
var inactive_state_fingerprint: = 0
var inactive_state_fingerprint_valid: = false
var target_dirty: = true
var redraw_requested: = true
var redraw_elapsed: = REDRAW_INTERVAL
var last_draw_cell: = Vector2i(-9999, -9999)


func _ready() -> void :
	player.moved.connect(_on_player_moved)
	player.facing_changed.connect(_on_player_facing_changed)
	_ensure_headlamp_initialized()


func _ensure_interior_initialized() -> void :
	if interior_initialized:
		return
	_configure_mine(mine_id)
	player.configure(_entry_spawn(), world_size, _movement_speed(), _resolve_motion)
	player.set_facing(Vector2.RIGHT)
	_build_lighting()
	interior_initialized = true
	queue_redraw()


func load_mine(next_mine_id: String) -> void :
	assert (MINE_ASSETS.has(next_mine_id), "Unsupported production mine: %s" % next_mine_id)
	if (
		interior_initialized
		and not active
		and next_mine_id == mine_id
		and configured_world_seed == int(RunState.world_seed)
		and inactive_state_fingerprint_valid
		and inactive_state_fingerprint == _persistent_state_fingerprint()
	):
		return
	if not interior_initialized:
		mine_id = next_mine_id
		_ensure_interior_initialized()
		return
	_configure_mine(next_mine_id)
	player.configure(_entry_spawn(), world_size, _movement_speed(), _resolve_motion)
	player.set_facing(Vector2.RIGHT)
	_rebuild_work_lamps()
	queue_redraw()


func _configure_mine(next_mine_id: String) -> void :
	mine_id = next_mine_id
	mine = GameData.mine(mine_id)
	mine_assets = Dictionary(MINE_ASSETS[mine_id])
	floor_texture = _texture(String(mine_assets.floor))
	wall_texture = _texture(String(mine_assets.wall))
	bedrock_texture = _texture(String(mine_assets.bedrock))
	entrance_texture = _texture(String(mine_assets.entrance))
	impact_texture = _texture(String(mine_assets.impact))
	depth_shaft_texture = _texture(String(DEPTH_SHAFT_ASSETS[mine_id]))
	pocket_texture = _texture(String(mine_assets.pocket))
	cache_texture = _texture(String(mine_assets.cache))
	shrine_texture = _texture(String(mine_assets.shrine))
	route_marker_texture = _texture(String(mine_assets.route_marker)) if mine_assets.has("route_marker") else null
	world_size = Vector2(float(mine.width), float(mine.height))
	cols = ceili(world_size.x / TILE_SIZE)
	rows = ceili(world_size.y / TILE_SIZE)
	depth_entrance = _calculate_depth_entrance()
	_build_original_mossvein()
	drops.clear()
	impacts.clear()
	respawns.clear()
	_restore_persistent_resource_runtime()
	_reset_heat_streak()
	mining_rush_remaining = 0.0
	_reset_mining_visual_phase()
	current_target = Vector2i(-1, -1)
	target_dirty = true
	last_draw_cell = Vector2i(-9999, -9999)
	_rebuild_role_counts()
	_migrate_legacy_barrier_progress()
	_rebuild_resource_guide_cells()
	configured_world_seed = int(RunState.world_seed)
	interior_build_count += 1
	if not active:
		_capture_inactive_state_fingerprint()


func _persistent_state_fingerprint() -> int:
	var cavern_state: Dictionary = {}
	var reward_state: Dictionary = {}
	for cavern_id_value in cavern_by_id:
		var cavern_id: = String(cavern_id_value)
		var reward_id: = String(Dictionary(cavern_by_id[cavern_id]).reward.id)
		cavern_state[cavern_id] = RunState.is_cavern_discovered(cavern_id)
		reward_state[reward_id] = {
			"claimed": RunState.is_pocket_reward_claimed(reward_id), 
			"pending": RunState.pending_pocket_reward_loot(reward_id), 
		}
	var barrier_state: Dictionary = {}
	for barrier_value in Array(mine.get("barriers", [])):
		var barrier_id: = String(Dictionary(barrier_value).id)
		barrier_state[barrier_id] = RunState.is_mine_barrier_cleared(barrier_id)
	return hash([
		RunState.dug_cells(mine_id, 1), 
		Dictionary(RunState.mine_resource_runtime.get("%s:1" % mine_id, {})), 
		RunState.is_depth_entrance_discovered(mine_id), 
		cavern_state, 
		reward_state, 
		barrier_state, 
	])


func _capture_inactive_state_fingerprint() -> void :
	inactive_state_fingerprint = _persistent_state_fingerprint()
	inactive_state_fingerprint_valid = true


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
	if entering:
		player.global_position = _entry_spawn()
		player.set_facing(Vector2.RIGHT)
		exit_near = false
		depth_near = false
		exit_context_changed.emit(false)
		depth_context_changed.emit(false)
	if enabled:
		player.camera.make_current()
		player.camera.reset_smoothing()
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
	for distance in range(0, 8):
		for row_offset in range( - distance, distance + 1):
			var col_distance: = distance - absi(row_offset)
			for col_offset in ([0] if col_distance == 0 else [ - col_distance, col_distance]):
				var cell: = origin_cell + Vector2i(int(col_offset), row_offset)
				if cell.x < 0 or cell.y < 0 or cell.x >= cols or cell.y >= rows:
					continue
				var candidate: = _cell_center(cell)
				if not _player_collides(candidate):
					return candidate
	var fallback: = _entry_spawn().clamp(Vector2.ONE * PLAYER_RADIUS, world_size - Vector2.ONE * PLAYER_RADIUS)
	return fallback


func set_mine_held(held: bool) -> void :
	external_mine_held = held


func _process(delta: float) -> void :
	if not active:
		return
	if target_dirty:
		var previous_target: = current_target
		current_target = _find_mine_target()
		target_dirty = false
		if current_target != previous_target:
			_request_redraw()
	_update_mining(delta)
	_update_pocket_rewards()
	if mining_rush_remaining > 0.0:
		mining_rush_remaining = maxf(0.0, mining_rush_remaining - delta)
	_update_drops(delta)
	_update_impacts(delta)
	_update_respawns(delta)
	if not impacts.is_empty() or _drops_are_moving() or _drops_are_expiring():
		_request_redraw()
	redraw_elapsed += delta
	if redraw_requested and redraw_elapsed >= REDRAW_INTERVAL:
		redraw_requested = false
		redraw_elapsed = 0.0
		queue_redraw()


func _build_original_mossvein() -> void :
	blocks.clear()
	depth_entrance_cells.clear()
	depth_entrance_boundary.clear()
	concealed_cavern_cells.clear()
	cavern_boundary_by_index.clear()
	cavern_by_id.clear()
	pocket_reward_cells.clear()
	var terrain_hp: = int(GameData.data.MINE_TERRAIN_HP)
	for row in rows:
		for col in cols:
			blocks[Vector2i(col, row)] = _make_block("stone", terrain_hp, 0, "terrain")

	_clear_circle(Vector2(float(mine.entrance.x) + 54.0, float(mine.entrance.y)), 142.0)
	_prepare_depth_one_discoveries()
	for solid_value in mine.solids:
		var solid: Dictionary = Dictionary(solid_value)
		_fill_rect_with_block(solid, _make_block("bedrock", 1, 99, String(solid.get("role", "bedrock"))))

	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)



		_clear_rect_from_blocks({
			"x": float(barrier.x) - 125.0, 
			"y": float(barrier.y) - 62.0, 
			"w": float(barrier.w) + 250.0, 
			"h": float(barrier.h) + 124.0, 
		})

	for rock_value in mine.rocks:
		var rock: Array = Array(rock_value)
		var kind: = String(rock[0])
		var cell: = Vector2i(floori(float(rock[1]) / TILE_SIZE), floori(float(rock[2]) / TILE_SIZE))
		var required: = 0
		var role: = "resource"
		if rock.size() > 3:
			role = String(rock[3])
			for barrier_value in mine.barriers:
				var barrier: Dictionary = Dictionary(barrier_value)
				if String(barrier.id) == role:
					required = int(barrier.requiresPickaxe)
		_place_resource_block(cell, kind, required, role, false)
	for rock_value in Array(Dictionary(GameData.data.MINE_DISCOVERIES[mine_id]).rocks):
		var rock: Dictionary = Dictionary(rock_value)
		var cell: = Vector2i(floori(float(rock.x) / TILE_SIZE), floori(float(rock.y) / TILE_SIZE))


		_remove_cell_from_pocket_reward_maps(cell)
		var reward_id: = String(rock.get("pocketRewardId", ""))
		if not reward_id.is_empty():
			if not pocket_reward_cells.has(reward_id):
				pocket_reward_cells[reward_id] = []
			pocket_reward_cells[reward_id].append(cell)
			if _pocket_reward_is_claimed(reward_id):
				continue
		_place_resource_block(cell, String(rock.type), int(rock.get("requiredPickaxe", 0)), "resource", true, rock)
	if RunState.has_method("is_mine_barrier_cleared"):
		for barrier_value in mine.barriers:
			var barrier: Dictionary = Dictionary(barrier_value)
			if RunState.is_mine_barrier_cleared(String(barrier.id)):
				_erase_role(String(barrier.id))
	if RunState.has_method("dug_cells"):
		for index_value in RunState.dug_cells(mine_id, 1):
			var index: = int(index_value)
			blocks.erase(Vector2i(index % cols, floori(float(index) / float(cols))))
			_restore_discovery_from_dug_index(index)


func _remove_cell_from_pocket_reward_maps(cell: Vector2i) -> void :
	for reward_id in pocket_reward_cells:
		var cells: Array = Array(pocket_reward_cells[reward_id])
		while cells.has(cell):
			cells.erase(cell)
		pocket_reward_cells[reward_id] = cells


func _prepare_depth_one_discoveries() -> void :
	var discoveries: Dictionary = Dictionary(GameData.data.MINE_DISCOVERIES[mine_id])
	for cavern_value in Array(discoveries.caverns):
		var cavern: Dictionary = Dictionary(cavern_value)
		var cavern_id: = String(cavern.id)
		var cells: = _clear_ellipse_cells(Vector2(float(cavern.x), float(cavern.y)), Vector2(float(cavern.rx), float(cavern.ry)))
		var boundary: = _boundary_for_cells(cells)
		cavern_by_id[cavern_id] = cavern.duplicate(true)
		for cell_value in cells:
			var cell: Vector2i = Vector2i(cell_value)
			concealed_cavern_cells[cell.y * cols + cell.x] = cavern_id
		for index_value in boundary:
			cavern_boundary_by_index[int(index_value)] = cavern_id

	var shaft_cells: = _clear_circle_cells(depth_entrance, DEPTH_PORTAL_RADIUS)
	for cell_value in shaft_cells:
		var cell: Vector2i = Vector2i(cell_value)
		depth_entrance_cells[cell.y * cols + cell.x] = true
	depth_entrance_boundary = _boundary_for_cells(shaft_cells)


func _clear_ellipse_cells(center: Vector2, radii: Vector2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var min_col: = maxi(0, floori((center.x - radii.x) / TILE_SIZE))
	var max_col: = mini(cols - 1, floori((center.x + radii.x) / TILE_SIZE))
	var min_row: = maxi(0, floori((center.y - radii.y) / TILE_SIZE))
	var max_row: = mini(rows - 1, floori((center.y + radii.y) / TILE_SIZE))
	for row in range(min_row, max_row + 1):
		for col in range(min_col, max_col + 1):
			var offset: = _cell_center(Vector2i(col, row)) - center
			if pow(offset.x / radii.x, 2.0) + pow(offset.y / radii.y, 2.0) > 1.0:
				continue
			var cell: = Vector2i(col, row)
			blocks.erase(cell)
			result.append(cell)
	return result


func _clear_circle_cells(center: Vector2, radius: float) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var min_col: = maxi(0, floori((center.x - radius) / TILE_SIZE))
	var max_col: = mini(cols - 1, floori((center.x + radius) / TILE_SIZE))
	var min_row: = maxi(0, floori((center.y - radius) / TILE_SIZE))
	var max_row: = mini(rows - 1, floori((center.y + radius) / TILE_SIZE))
	for row in range(min_row, max_row + 1):
		for col in range(min_col, max_col + 1):
			var cell: = Vector2i(col, row)
			if _cell_center(cell).distance_to(center) > radius:
				continue
			blocks.erase(cell)
			result.append(cell)
	return result


func _boundary_for_cells(cells: Array[Vector2i]) -> Dictionary:
	var cell_set: = {}
	var result: = {}
	for cell in cells:
		cell_set[cell] = true
	for cell in cells:
		for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbour: Vector2i = cell + offset
			if neighbour.x < 0 or neighbour.y < 0 or neighbour.x >= cols or neighbour.y >= rows:
				continue
			if not cell_set.has(neighbour) and blocks.has(neighbour):
				result[neighbour.y * cols + neighbour.x] = true
	return result


func _place_resource_block(
	cell: Vector2i, 
	kind: String, 
	required: int, 
	role: String, 
	generated: bool, 
	source: Dictionary = {}
) -> void :
	var rock_data: Dictionary = Dictionary(GameData.data.ROCK_TYPES[kind])
	var block: = _make_block(kind, int(rock_data.hp), required, role)
	if generated:
		block["shell"] = int(rock_data.get("shell", 0))
		block["max_shell"] = int(rock_data.get("shell", 0))
		block["deposit_id"] = String(source.get("depositId", ""))
		block["cavern_id"] = String(source.get("cavernId", ""))
		block["pocket_reward_id"] = String(source.get("pocketRewardId", ""))
		block["rare_find"] = bool(source.get("rareFind", false))
	if required > 0 and role != "resource":
		block["barrier_label"] = _barrier_label(role)
		block["barrier_trigger"] = true
	blocks[cell] = block


func _clear_rect_from_blocks(rect_data: Dictionary) -> void :
	var start_col: = maxi(0, floori(float(rect_data.x) / TILE_SIZE))
	var end_col: = mini(cols - 1, floori((float(rect_data.x) + float(rect_data.w) - 0.01) / TILE_SIZE))
	var start_row: = maxi(0, floori(float(rect_data.y) / TILE_SIZE))
	var end_row: = mini(rows - 1, floori((float(rect_data.y) + float(rect_data.h) - 0.01) / TILE_SIZE))
	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			var cell: = Vector2i(col, row)
			if blocks.has(cell) and String(Dictionary(blocks[cell]).get("role", "")) == "terrain":
				blocks.erase(cell)


func _restore_discovery_from_dug_index(index: int) -> void :
	if depth_entrance_boundary.has(index) and not RunState.is_depth_entrance_discovered(mine_id):
		RunState.mark_depth_entrance_discovered(mine_id)
	if cavern_boundary_by_index.has(index):
		RunState.mark_cavern_discovered(String(cavern_boundary_by_index[index]))


func _make_block(kind: String, hp: int, required_tool: int, role: String) -> Dictionary:
	return {"kind": kind, "hp": hp, "max_hp": hp, "shell": 0, "max_shell": 0, "requires_tool": required_tool, "role": role}


func _clear_circle(center: Vector2, radius: float) -> void :
	var min_col: = maxi(0, floori((center.x - radius) / TILE_SIZE))
	var max_col: = mini(cols - 1, floori((center.x + radius) / TILE_SIZE))
	var min_row: = maxi(0, floori((center.y - radius) / TILE_SIZE))
	var max_row: = mini(rows - 1, floori((center.y + radius) / TILE_SIZE))
	for row in range(min_row, max_row + 1):
		for col in range(min_col, max_col + 1):
			if _cell_center(Vector2i(col, row)).distance_to(center) <= radius:
				blocks.erase(Vector2i(col, row))


func _fill_rect_with_block(rect_data: Dictionary, block: Dictionary) -> void :
	var start_col: = maxi(0, floori(float(rect_data.x) / TILE_SIZE))
	var end_col: = mini(cols - 1, floori((float(rect_data.x) + float(rect_data.w) - 0.01) / TILE_SIZE))
	var start_row: = maxi(0, floori(float(rect_data.y) / TILE_SIZE))
	var end_row: = mini(rows - 1, floori((float(rect_data.y) + float(rect_data.h) - 0.01) / TILE_SIZE))
	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			blocks[Vector2i(col, row)] = block.duplicate(true)


func _barrier_label(barrier_id: String) -> String:
	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		if String(barrier.id) == barrier_id:
			return String(barrier.label)
	return "Mine barrier"


func _calculate_depth_entrance() -> Vector2:
	var profile: Dictionary = Dictionary(GameData.data.MINE_DISCOVERY_PROFILES[mine_id])
	var random_state: = (int(RunState.world_seed) ^ int(profile.seed) ^ 2654435769) & 4294967295
	var first_row: = ceili(1700.0 / TILE_SIZE)
	var usable_cols: = maxi(1, cols - 6)
	var usable_rows: = maxi(1, rows - first_row - 7)
	var chosen_col: = floori(float(cols) * 0.5)
	var chosen_row: = floori(float(rows) * 0.72)
	var found: = false
	for _attempt in 240:
		random_state = (random_state * 1664525 + 1013904223) & 4294967295
		var candidate_col: = 3 + floori(float(random_state) / 4294967300.0 * float(usable_cols))
		random_state = (random_state * 1664525 + 1013904223) & 4294967295
		var candidate_row: = first_row + floori(float(random_state) / 4294967300.0 * float(usable_rows))
		if _valid_depth_entrance_candidate(candidate_col, candidate_row):
			chosen_col = candidate_col
			chosen_row = candidate_row
			found = true
			break
	if not found:
		var candidate_count: = usable_cols * usable_rows
		random_state = (random_state * 1664525 + 1013904223) & 4294967295
		var start: = floori(float(random_state) / 4294967300.0 * float(candidate_count))
		for step in candidate_count:
			var candidate_index: = (start + step) % candidate_count
			var candidate_col: = 3 + candidate_index % usable_cols
			var candidate_row: = first_row + floori(float(candidate_index) / float(usable_cols))
			if _valid_depth_entrance_candidate(candidate_col, candidate_row):
				chosen_col = candidate_col
				chosen_row = candidate_row
				break
	return (Vector2(chosen_col, chosen_row) + Vector2(0.5, 0.5)) * TILE_SIZE


func _valid_depth_entrance_candidate(candidate_col: int, candidate_row: int) -> bool:
	var position: = (Vector2(candidate_col, candidate_row) + Vector2(0.5, 0.5)) * TILE_SIZE


	var discoveries: Array = Array(Dictionary(GameData.data.MINE_DISCOVERIES[mine_id]).caverns).duplicate(true)
	discoveries.append_array(Array(Dictionary(GameData.data.MINE_DEPTH_DISCOVERIES[mine_id]).caverns).duplicate(true))
	for cavern_value in discoveries:
		var cavern: Dictionary = Dictionary(cavern_value)
		var normalized: = Vector2(
			(position.x - float(cavern.x)) / (float(cavern.rx) + 190.0), 
			(position.y - float(cavern.y)) / (float(cavern.ry) + 190.0)
		)
		if normalized.length_squared() < 1.0:
			return false
	for solid_value in mine.solids:
		var solid: Dictionary = Dictionary(solid_value)
		if position.x > float(solid.x) - 150.0 and position.x < float(solid.x) + float(solid.w) + 150.0\
		and position.y > float(solid.y) - 150.0 and position.y < float(solid.y) + float(solid.h) + 150.0:
			return false
	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		if position.x > float(barrier.x) - 180.0 and position.x < float(barrier.x) + float(barrier.w) + 180.0\
		and position.y > float(barrier.y) - 180.0 and position.y < float(barrier.y) + float(barrier.h) + 180.0:
			return false
	var depth_stations: = [
		Vector2(clampf(position.x - 112.0, 70.0, world_size.x - 70.0), clampf(position.y - 112.0, 90.0, world_size.y - 90.0)), 
		Vector2(clampf(position.x + 112.0, 70.0, world_size.x - 70.0), clampf(position.y - 112.0, 90.0, world_size.y - 90.0)), 
	]
	var resources: Array[Vector2] = []
	for rock_value in mine.rocks:
		var rock: Array = Array(rock_value)
		resources.append(Vector2(float(rock[1]), float(rock[2])))
	for rock_value in Array(Dictionary(GameData.data.MINE_DISCOVERIES[mine_id]).rocks):
		var rock: Dictionary = Dictionary(rock_value)
		resources.append(Vector2(float(rock.x), float(rock.y)))
	var depth_resources: Array[Vector2] = []
	for rock_value in Array(Dictionary(GameData.data.MINE_DEPTH_DISCOVERIES[mine_id]).rocks):
		var rock: Dictionary = Dictionary(rock_value)
		var resource_position: = Vector2(float(rock.x), float(rock.y))
		resources.append(resource_position)
		depth_resources.append(resource_position)
	for resource_position in resources:
		if position.distance_to(resource_position) < DEPTH_PORTAL_RESOURCE_CLEARANCE:
			return false
	for resource_position in depth_resources:
		for station_position in depth_stations:
			if station_position.distance_to(resource_position) < DEPTH_STATION_RESOURCE_CLEARANCE:
				return false
	var mine_entrance: = Vector2(float(mine.entrance.x), float(mine.entrance.y))
	return position.distance_to(mine_entrance) > 700.0


func _entry_spawn() -> Vector2:
	return Vector2(float(mine.entrance.x) + 85.0, float(mine.entrance.y))


func _movement_speed() -> float:
	return float(GameData.data.PLAYER_SPEED) * RunState.movement_speed_multiplier()


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
	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		if not _role_has_blocks(String(barrier.id)):
			continue
		var barrier_rect: = Rect2(float(barrier.x), float(barrier.y), float(barrier.w), float(barrier.h))
		var nearest_barrier: = Vector2(
			clampf(position.x, barrier_rect.position.x, barrier_rect.end.x), 
			clampf(position.y, barrier_rect.position.y, barrier_rect.end.y)
		)
		if position.distance_squared_to(nearest_barrier) < PLAYER_RADIUS * PLAYER_RADIUS:
			return true
	var min_cell: = _world_to_cell(position - Vector2.ONE * PLAYER_RADIUS)
	var max_cell: = _world_to_cell(position + Vector2.ONE * PLAYER_RADIUS)
	for row in range(min_cell.y, max_cell.y + 1):
		for col in range(min_cell.x, max_cell.x + 1):
			var cell: = Vector2i(col, row)
			if not blocks.has(cell):
				continue
			var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			var nearest: = Vector2(clampf(position.x, rect.position.x, rect.end.x), clampf(position.y, rect.position.y, rect.end.y))
			if position.distance_squared_to(nearest) < PLAYER_RADIUS * PLAYER_RADIUS:
				return true
	return false


func _on_player_moved(world_position: Vector2) -> void :
	target_dirty = true
	var draw_cell: = _world_to_cell(world_position)
	if draw_cell != last_draw_cell:
		last_draw_cell = draw_cell
		_request_redraw()
	if world_position.distance_to(last_light_refresh_position) >= WORK_LIGHT_REFRESH_DISTANCE:
		_refresh_visible_work_lights()
	var entrance: = Vector2(float(mine.entrance.x), float(mine.entrance.y))
	var now_near: = world_position.distance_to(entrance) <= 118.0
	if now_near != exit_near:
		exit_near = now_near
		exit_context_changed.emit(exit_near)
	var now_near_depth: = RunState.is_depth_entrance_discovered(mine_id) and world_position.distance_to(depth_entrance) <= DEPTH_CONTEXT_RADIUS
	if now_near_depth != depth_near:
		depth_near = now_near_depth
		depth_context_changed.emit(depth_near)
		if depth_near:
			message_changed.emit("Hidden descent found · press DESCEND when you choose to enter")


func _on_player_facing_changed(direction: Vector2) -> void :
	var headlamp: = player.get_node_or_null("PremiumHeadlamp")
	if headlamp != null and headlamp.has_method("set_direction"):
		headlamp.set_direction(direction)
	if player.camera.has_method("set_headlamp_direction"):
		player.camera.set_headlamp_direction(direction)
	target_dirty = true


func guide_target() -> Vector2:
	if RunState.is_depth_entrance_discovered(mine_id):
		return depth_entrance
	var best: = Vector2.ZERO
	var best_distance: = INF
	for cell_value in blocks:
		var cell: = Vector2i(cell_value)
		var block: Dictionary = Dictionary(blocks[cell])
		if String(block.get("role", "")) != "resource" or int(block.get("requires_tool", 0)) > int(RunState.pickaxe_level):
			continue
		var position: = Vector2(cell) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5
		var distance: = player.global_position.distance_squared_to(position)
		if distance < best_distance:
			best_distance = distance
			best = position
	return best


func guide_resource_candidates(requested_resource: String = "") -> Array[Dictionary]:
	var all_candidates: Array[Dictionary] = []
	var matching_candidates: Array[Dictionary] = []
	for cell in resource_guide_cells:
		if not blocks.has(cell):
			continue
		var block: Dictionary = Dictionary(blocks[cell])
		if (
			String(block.get("role", "")) != "resource"
			or int(block.get("requires_tool", 0)) > int(RunState.pickaxe_level)
		):
			continue
		var position: = Vector2(cell) * TILE_SIZE + Vector2.ONE * TILE_SIZE * 0.5
		var candidate: = {
			"key": "mine:%s:cell:%d:%d" % [mine_id, cell.x, cell.y], 
			"position": position, 
			"priority": player.global_position.distance_squared_to(position), 
		}
		all_candidates.append(candidate)
		if requested_resource.is_empty() or String(block.get("kind", "")) == requested_resource:
			matching_candidates.append(candidate)
	return matching_candidates if not matching_candidates.is_empty() else all_candidates


func _rebuild_resource_guide_cells() -> void :
	resource_guide_cells.clear()
	for cell_value in blocks:
		var cell: = Vector2i(cell_value)
		if String(Dictionary(blocks[cell]).get("role", "")) == "resource":
			resource_guide_cells.append(cell)
	resource_guide_cells.sort_custom( func(left: Vector2i, right: Vector2i) -> bool:
		return left.y < right.y or (left.y == right.y and left.x < right.x)
	)


func _request_redraw() -> void :
	redraw_requested = true


func _update_mining(delta: float) -> void :
	var held: = external_mine_held or Input.is_action_pressed("mine")
	_update_heat_streak(delta, held)
	if not swing_active:
		if held and current_target.x >= 0 and blocks.has(current_target):
			_start_swing()
			player.set_mining_visual(true, _mining_visual_progress(0.0))
		else:
			player.set_mining_visual(false)
			_reset_mining_visual_phase()
		return
	mining_visual_elapsed += delta
	swing_elapsed += delta
	var progress: = clampf(swing_elapsed / swing_duration, 0.0, 1.0)
	player.set_mining_visual(true, _mining_visual_progress(progress))
	if not swing_hit and progress >= _tool_strike_progress():
		swing_hit = true
		_mine_once()
	if swing_elapsed >= swing_duration:
		var overflow: = maxf(0.0, swing_elapsed - swing_duration)
		swing_active = false
		if held and current_target.x >= 0 and blocks.has(current_target):
			_start_swing()
			swing_elapsed = fposmod(overflow, maxf(0.001, swing_duration))
			player.set_mining_visual(true, _mining_visual_progress(swing_elapsed / maxf(0.001, swing_duration)))
		else:
			player.set_mining_visual(false)
			_reset_mining_visual_phase()


func _start_swing() -> void :
	if not mining_visual_running:
		mining_visual_elapsed = 0.0
		mining_visual_running = true
	swing_active = true
	swing_elapsed = 0.0
	swing_hit = false
	if _heat_streak_unlocked():
		heat_streak_active = true
	swing_duration = float(_current_tool().get("cooldown", 0.72)) / _heat_streak_speed()
	if mining_rush_remaining > 0.0:
		swing_duration *= MINING_RUSH_COOLDOWN_MULTIPLIER


func _mining_visual_progress(gameplay_progress: float) -> float:
	if player.direction_name == "up":
		return fposmod(mining_visual_elapsed / maxf(0.5, swing_duration), 1.0)
	return gameplay_progress


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


func _update_heat_streak(delta: float, held: bool) -> void :
	if not _heat_streak_unlocked() or not held:
		_reset_heat_streak()
		return
	if not heat_streak_active:
		return
	if not swing_active and current_target.x < 0:
		return
	heat_streak_elapsed = minf(HEAT_STREAK_BUILD_SECONDS, heat_streak_elapsed + delta)


func _reset_heat_streak() -> void :
	heat_streak_elapsed = 0.0
	heat_streak_active = false


func _mine_once() -> void :
	var target: = current_target if current_target.x >= 0 else _find_mine_target()
	if target.x < 0 or not blocks.has(target):
		AudioDirector.play_blocked()
		message_changed.emit("Face a nearby mine wall before swinging")
		return
	var block: Dictionary = Dictionary(blocks[target])
	var required_tool: = int(block.get("requires_tool", 0))
	if String(block.kind) == "bedrock":
		AudioDirector.play_blocked()
		message_changed.emit("Ancient bedrock · this route cannot be bypassed")
		return
	if required_tool > RunState.pickaxe_level:
		AudioDirector.play_blocked()
		var required: Dictionary = Dictionary(GameData.data.PICKAXES[required_tool])
		message_changed.emit("%s REQUIRED · sell ore and forge at camp" % String(required.name).to_upper())
		return
	var tool: = _current_tool()
	var power: = int(tool.get("power", 1))
	var was_armored: = int(block.get("shell", 0)) > 0
	if int(block.get("shell", 0)) > 0:
		var shell_multiplier: = maxf(0.01, float(tool.get("shell_power", 0.72)))
		var shell_damage: = ceili(float(power) * shell_multiplier)
		var previous_shell: = int(block.shell)
		block.shell = maxi(0, previous_shell - shell_damage)
		var overflow: = maxi(0, shell_damage - previous_shell)
		if overflow > 0:
			block.hp = maxi(0, int(block.hp) - floori(float(overflow) / shell_multiplier))
	else:
		block.hp = maxi(0, int(block.hp) - power)
	blocks[target] = block
	var broken: = int(block.shell) <= 0 and int(block.hp) <= 0
	var crusher_active: = String(RunState.starforge_variant) == "crusher"
	var impact: = {
		"position": _target_contact_point(target),
		"age": 0.0,
		"life": CrusherDebrisScript.LIFE_SECONDS if crusher_active and broken else 0.34,
		"broken": broken,
		"style": _tool_impact_style(tool),
	}
	_attach_crusher_debris(impact, target)
	while impacts.size() >= 6:
		impacts.remove_at(0)
	impacts.append(impact)
	AudioDirector.play_mining(String(block.kind), broken, was_armored)
	player.set_mining_visual(true, _mining_visual_progress(swing_elapsed / swing_duration), 1.0)
	if broken:
		blocks.erase(target)
		var dug_index: = target.y * cols + target.x
		var role: = String(block.get("role", ""))
		if role_block_counts.has(role):
			role_block_counts[role] = maxi(0, int(role_block_counts[role]) - 1)
		if role == "resource":
			var rock_data: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(String(block.kind), {}))
			var respawn_seconds: = float(rock_data.get("respawn", 8.0))
			var node_id: = _resource_node_id(target)
			var respawn_until: = RunState.deplete_mine_resource_node(
				mine_id, 1, node_id, respawn_seconds
			)
			respawns.append({
				"cell": target, 
				"block": block.duplicate(true), 
				"node_id": node_id, 
				"respawn_until_unix": respawn_until, 
				"remaining": respawn_seconds, 
			})
		elif _is_barrier_role(role):
			if not _role_has_blocks(role) and RunState.has_method("mark_barrier_cleared"):
				_erase_role(role)
				RunState.mark_barrier_cleared(role)
		else:
			if RunState.has_method("mark_terrain_dug"):
				RunState.mark_terrain_dug(mine_id, dug_index, 1)
		_handle_discovery_at(dug_index)
		var yield_amount: = 1
		if role != "terrain" and randf() < clampf(float(tool.get("yield_bonus", 0.0)), 0.0, 0.92):
			yield_amount += 1
		yield_amount *= maxi(1, int(tool.get("yield_multiplier", 1)))
		RunState.record_mined(String(block.kind), yield_amount)
		var crusher_origin: = _cell_center(target) if crusher_active else Vector2(INF, INF)
		_spawn_drop(target, String(block.kind), yield_amount, crusher_origin)
		_register_pocket_deposits_at_cell(target)
		if depth_entrance_boundary.has(dug_index):
			message_changed.emit("HIDDEN DESCENT FOUND · %s waits below" % _depth_name())
		elif cavern_boundary_by_index.has(dug_index):
			message_changed.emit("HIDDEN CHAMBER · a sealed pocket is open")
		else:
			message_changed.emit("%s BROKEN · collect the ore" % String(block.kind).to_upper())
	if crusher_active:
		_apply_crusher_shockwave(target, tool)
	target_dirty = true
	_request_redraw()


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


func _apply_crusher_shockwave(center: Vector2i, tool: Dictionary) -> void :
	var power: = maxi(1, int(tool.get("power", 1)))
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			if x_offset == 0 and y_offset == 0:
				continue
			var cell: = center + Vector2i(x_offset, y_offset)
			if not blocks.has(cell):
				continue
			var block: Dictionary = Dictionary(blocks[cell])
			if String(block.get("role", "")) != "terrain" or String(block.get("kind", "")) == "bedrock":
				continue
			if int(block.get("requires_tool", 0)) > int(RunState.pickaxe_level):
				continue
			var distance: = maxi(absi(x_offset), absi(y_offset))
			var wave_power: = maxi(1, roundi(float(power) * (0.72 if distance == 1 else 0.48)))
			if int(block.get("shell", 0)) > 0:
				var shell_power: = maxf(0.01, float(tool.get("shell_power", 0.72)))
				var shell_damage: = ceili(float(wave_power) * shell_power)
				var previous_shell: = int(block.shell)
				block.shell = maxi(0, previous_shell - shell_damage)
				var overflow: = maxi(0, shell_damage - previous_shell)
				if overflow > 0:
					block.hp = maxi(0, int(block.hp) - floori(float(overflow) / shell_power))
			else:
				block.hp = maxi(0, int(block.hp) - wave_power)
			if int(block.get("shell", 0)) > 0 or int(block.hp) > 0:
				blocks[cell] = block
				continue
			blocks.erase(cell)
			if role_block_counts.has("terrain"):
				role_block_counts["terrain"] = maxi(0, int(role_block_counts["terrain"]) - 1)
			var dug_index: = cell.y * cols + cell.x
			if RunState.has_method("mark_terrain_dug"):
				RunState.mark_terrain_dug(mine_id, dug_index, 1)
			_handle_discovery_at(dug_index)
			RunState.record_mined(String(block.kind), 1)
			_spawn_drop(cell, String(block.kind), 1, _cell_center(center))


func _attach_crusher_force(impact: Dictionary, broken: bool) -> void:
	# The Crusher attunement stays active after a drill upgrade. Only a real
	# break gets the short ground-force effect; the flying pieces are the actual
	# resource bundles spawned below, never decorative rock polygons.
	if broken and String(RunState.starforge_variant) == "crusher":
		impact["crusher_force"] = true
		impact["life"] = minf(
			float(impact.get("life", CrusherDebrisScript.LIFE_SECONDS)),
			CrusherDebrisScript.LIFE_SECONDS
		)


func _attach_crusher_debris(impact: Dictionary, _cell: Vector2i) -> void:
	# Compatibility entry point used by the existing impact QA. It now attaches
	# only force metadata; decorative chunk data is intentionally never created.
	_attach_crusher_force(impact, bool(impact.get("broken", false)))


func _crusher_debris_palette() -> Array[Color]:
	match mine_id:
		"moonMine": return [Color("61798b"), Color("a5bac1"), Color("415463")]
		"emberMine": return [Color("80513b"), Color("c37a48"), Color("4b302b")]
		"starMine": return [Color("654f72"), Color("9d7bab"), Color("40364f")]
	return [Color("79654f"), Color("b4976c"), Color("4b4439")]


func _handle_discovery_at(dug_index: int) -> void :
	if depth_entrance_boundary.has(dug_index):
		var newly_discovered: = RunState.mark_depth_entrance_discovered(mine_id)
		if newly_discovered:
			depth_discovered.emit(depth_entrance)
			_rebuild_work_lamps()
			_on_player_moved(player.global_position)
	if cavern_boundary_by_index.has(dug_index):
		var cavern_id: = String(cavern_boundary_by_index[dug_index])
		if RunState.mark_cavern_discovered(cavern_id):
			_rebuild_work_light_anchors()
			_refresh_visible_work_lights(true)


func _update_pocket_rewards() -> void :
	for cavern_id_value in cavern_by_id:
		var cavern_id: = String(cavern_id_value)
		if not RunState.is_cavern_discovered(cavern_id):
			continue
		var cavern: Dictionary = Dictionary(cavern_by_id[cavern_id])
		var reward: Dictionary = Dictionary(cavern.reward)
		var reward_id: = String(reward.id)
		if _pocket_reward_is_claimed(reward_id):
			continue
		var kind: = String(reward.kind)
		if kind in ["crystal", "motherlode"]:
			continue
		var center: = Vector2(float(cavern.x), float(cavern.y))
		var radius: = minf(float(cavern.rx), float(cavern.ry)) * 0.7
		if player.global_position.distance_to(center) <= radius:
			_claim_pocket_reward(cavern_id)


func _claim_pocket_reward(cavern_id: String) -> Dictionary:
	if not cavern_by_id.has(cavern_id):
		return {"ok": false, "reason": "unknown_cavern"}
	var cavern: Dictionary = Dictionary(cavern_by_id[cavern_id])
	var reward: Dictionary = Dictionary(cavern.reward)
	var reward_id: = String(reward.id)
	var kind: = String(reward.kind)
	if kind in ["crystal", "motherlode"]:
		return {"ok": false, "reason": "deposit_not_cleared", "reward_id": reward_id}
	var plan: Dictionary = RunState.claim_pocket_reward(reward_id)
	if not bool(plan.get("ok", false)):
		return plan
	var center: = Vector2(float(cavern.x), float(cavern.y) + 12.0)
	if kind == "cache":
		_spawn_reward_plan_loot(reward_id, Dictionary(plan.get("pending_loot", {})), center)
		message_changed.emit("CACHE OPENED · collect the find")
	else:
		mining_rush_remaining = float(plan.get("mining_rush_seconds", MINING_RUSH_DURATION))
		message_changed.emit("MINING RUSH · 55% faster for 30 seconds")
	pocket_reward_claimed.emit(reward_id, kind)
	_request_redraw()
	return plan


func _register_pocket_deposit_break(reward_id: String, origin_cell: Vector2i) -> Dictionary:
	if reward_id.is_empty() or _pocket_reward_is_claimed(reward_id):
		return {"ok": false, "reason": "not_pending", "reward_id": reward_id}
	var reward_cells: Array = Array(pocket_reward_cells.get(reward_id, []))
	if reward_cells.is_empty():
		return {"ok": false, "reason": "no_deposit", "reward_id": reward_id}
	for cell_value in reward_cells:
		if blocks.has(Vector2i(cell_value)):
			return {"ok": false, "reason": "deposit_remaining", "reward_id": reward_id}
	var plan: Dictionary = RunState.complete_pocket_deposit(reward_id)
	if not bool(plan.get("ok", false)):
		return plan
	for index in range(respawns.size() - 1, -1, -1):
		var pending: Dictionary = Dictionary(respawns[index])
		if String(Dictionary(pending.get("block", {})).get("pocket_reward_id", "")) == reward_id:
			respawns.remove_at(index)
	for cell_value in reward_cells:
		var cell: = Vector2i(cell_value)
		RunState.clear_mine_resource_depletion(mine_id, 1, _resource_node_id(cell))
	_spawn_reward_plan_loot(
		reward_id, 
		Dictionary(plan.get("pending_loot", {})), 
		_cell_center(origin_cell)
	)
	var reward: = _reward_by_id(reward_id)
	var kind: = String(reward.get("kind", "crystal"))
	pocket_reward_claimed.emit(reward_id, kind)
	AudioDirector.play_discovery()
	message_changed.emit("CLUSTER CLEARED" if kind == "crystal" else "MOTHERLODE CLEARED")
	_request_redraw()
	return plan


func _register_pocket_deposits_at_cell(origin_cell: Vector2i) -> void :
	for reward_id_value in pocket_reward_cells:
		var reward_id: = String(reward_id_value)
		if Array(pocket_reward_cells[reward_id]).has(origin_cell):
			_register_pocket_deposit_break(reward_id, origin_cell)


func _reward_by_id(reward_id: String) -> Dictionary:
	for cavern_value in cavern_by_id.values():
		var reward: Dictionary = Dictionary(Dictionary(cavern_value).reward)
		if String(reward.id) == reward_id:
			return reward
	return {}


func _pocket_reward_is_claimed(reward_id: String) -> bool:
	return RunState.is_pocket_reward_claimed(reward_id)


func _depth_name() -> String:
	var profile: Dictionary = Dictionary(GameData.data.MINE_DEPTH_PROFILES.get(mine_id, {}))
	return String(profile.get("name", "Depth 2")).capitalize()


func _find_mine_target() -> Vector2i:
	if not active:
		return Vector2i(-1, -1)
	var aim: Vector2 = Vector2(player.facing_vector).normalized()
	if aim.length_squared() < 0.5:
		return Vector2i(-1, -1)
	var origin: = player.global_position
	var max_travel: = _effective_mining_range() + TILE_SIZE * 0.65 - PLAYER_RADIUS
	var search_radius: = max_travel + PLAYER_RADIUS + TILE_SIZE
	var min_cell: = _world_to_cell(origin - Vector2.ONE * search_radius)
	var max_cell: = _world_to_cell(origin + Vector2.ONE * search_radius)
	var best_cell: = Vector2i(-1, -1)
	var best_entry: = INF
	var best_lateral: = INF
	var side: = Vector2( - aim.y, aim.x)
	for row in range(maxi(0, min_cell.y), mini(rows - 1, max_cell.y) + 1):
		for col in range(maxi(0, min_cell.x), mini(cols - 1, max_cell.x) + 1):
			var cell: = Vector2i(col, row)
			if not blocks.has(cell):
				continue
			var block: Dictionary = Dictionary(blocks[cell])
			if String(block.get("kind", "")) == "bedrock":
				continue
			var tile_rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			var entry: = _mine_target_entry(origin, aim, tile_rect, max_travel)
			if entry <= 0.01:
				continue
			var lateral: = absf((_cell_center(cell) - origin).dot(side))
			if entry < best_entry - 0.01 or (absf(entry - best_entry) <= 0.01 and lateral < best_lateral):
				best_entry = entry
				best_lateral = lateral
				best_cell = cell
	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		var role: = String(barrier.id)
		if not _role_has_blocks(role):
			continue
		var barrier_rect: = Rect2(float(barrier.x), float(barrier.y), float(barrier.w), float(barrier.h)).grow(PLAYER_RADIUS)
		var barrier_entry: = _ray_rect_entry(origin, aim, barrier_rect, max_travel)
		if barrier_entry <= 0.01 or barrier_entry > best_entry + 0.01:
			continue
		var trigger: = _nearest_barrier_trigger(role, origin)
		if trigger.x >= 0:
			best_entry = barrier_entry
			best_cell = trigger
	if best_cell.x >= 0 and _bedrock_occludes_target(origin, best_cell):
		return Vector2i(-1, -1)
	return best_cell


func _mine_target_entry(origin: Vector2, aim: Vector2, tile_rect: Rect2, max_travel: float) -> float:
	var ray_entry: = _ray_rect_entry(origin, aim, tile_rect.grow(PLAYER_RADIUS), max_travel)
	if ray_entry > 0.01:
		return ray_entry



	var nearest: = Vector2(
		clampf(origin.x, tile_rect.position.x, tile_rect.end.x), 
		clampf(origin.y, tile_rect.position.y, tile_rect.end.y)
	)
	var offset: = nearest - origin
	var forward: = offset.dot(aim)
	var lateral: = absf(offset.dot(Vector2( - aim.y, aim.x)))
	if forward > 0.01 and forward <= max_travel and lateral <= CORNER_AIM_ASSIST and offset.length() <= max_travel:
		return forward
	return -1.0


func _bedrock_occludes_target(origin: Vector2, target: Vector2i) -> bool:
	var target_rect: = Rect2(Vector2(target) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
	var target_point: = Vector2(
		clampf(origin.x, target_rect.position.x, target_rect.end.x), 
		clampf(origin.y, target_rect.position.y, target_rect.end.y)
	)
	var offset: = target_point - origin
	var distance: = offset.length()
	if distance <= 0.01:
		return false
	var direction: = offset / distance
	var bounds_start: = Vector2(minf(origin.x, target_point.x), minf(origin.y, target_point.y)) - Vector2.ONE
	var bounds_end: = Vector2(maxf(origin.x, target_point.x), maxf(origin.y, target_point.y)) + Vector2.ONE
	var min_cell: = _world_to_cell(bounds_start)
	var max_cell: = _world_to_cell(bounds_end)
	for row in range(maxi(0, min_cell.y), mini(rows - 1, max_cell.y) + 1):
		for col in range(maxi(0, min_cell.x), mini(cols - 1, max_cell.x) + 1):
			var cell: = Vector2i(col, row)
			if cell == target or not blocks.has(cell):
				continue
			var block: Dictionary = Dictionary(blocks[cell])
			if String(block.get("kind", "")) != "bedrock":
				continue
			var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			var entry: = _ray_rect_entry(origin, direction, rect, distance)
			if entry > 0.01 and entry < distance - 0.01:
				return true
	return false


func _nearest_barrier_trigger(role: String, origin: Vector2) -> Vector2i:
	var nearest_cell: = Vector2i(-1, -1)
	var nearest_distance: = INF
	for cell_value in blocks:
		var cell: Vector2i = Vector2i(cell_value)
		var block: Dictionary = Dictionary(blocks[cell])
		if String(block.get("role", "")) != role or not bool(block.get("barrier_trigger", false)):
			continue
		var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
		var nearest: = Vector2(clampf(origin.x, rect.position.x, rect.end.x), clampf(origin.y, rect.position.y, rect.end.y))
		var distance: = origin.distance_to(nearest)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = cell
	return nearest_cell if nearest_distance <= _effective_mining_range() + TILE_SIZE * 0.65 else Vector2i(-1, -1)


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


func _target_contact_point(cell: Vector2i) -> Vector2:
	var aim: Vector2 = Vector2(player.facing_vector).normalized()
	var side: = Vector2( - aim.y, aim.x)
	var travel: = PLAYER_RADIUS + 2.0
	while travel <= _effective_mining_range():
		for lateral in [0.0, -7.0, 7.0]:
			var probe: Vector2 = player.global_position + aim * travel + side * float(lateral)
			if _world_to_cell(probe) == cell:
				return probe
		travel += 2.0
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
	return Vector2(clampf(player.global_position.x, rect.position.x, rect.end.x), clampf(player.global_position.y, rect.position.y, rect.end.y))


func _effective_mining_range() -> float:
	return MINING_RANGE * RunState.endless_tool_range_multiplier()


func _current_tool() -> Dictionary:
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


func _resource_node_id(cell: Vector2i) -> String:
	return "cell:%d" % (cell.y * cols + cell.x)


func _restore_persistent_resource_runtime() -> void :
	var now: = int(Time.get_unix_time_from_system())
	var depleted: Dictionary = RunState.mine_resource_depletions(mine_id, 1)
	for node_id_value in depleted:
		var node_id: = String(node_id_value)
		var record: Dictionary = Dictionary(depleted[node_id_value])
		var respawn_until: = int(record.get("respawn_until_unix", 0))
		if respawn_until <= now:
			RunState.clear_mine_resource_depletion(mine_id, 1, node_id)
			continue
		if not node_id.begins_with("cell:"):
			continue
		var raw_index: = node_id.trim_prefix("cell:")
		if not raw_index.is_valid_int():
			continue
		var cell_index: = int(raw_index)
		var cell: = Vector2i(cell_index % cols, floori(float(cell_index) / float(cols)))
		if not blocks.has(cell) or _resource_node_id(cell) != node_id:
			continue
		var block: Dictionary = Dictionary(blocks[cell])
		if (
			String(block.get("role", "")) != "resource"
			or String(record.get("kind", "")) != String(block.get("kind", ""))
		):
			continue
		blocks.erase(cell)
		respawns.append({
			"cell": cell, 
			"block": block.duplicate(true), 
			"node_id": node_id, 
			"respawn_until_unix": respawn_until, 
			"remaining": maxf(0.0, float(respawn_until - now)), 
		})
	_restore_persistent_loose_loot()


func _restore_persistent_loose_loot() -> void :
	drops.clear()
	for stored_value in RunState.mine_loose_loot(mine_id, 1):
		var stored: Dictionary = Dictionary(stored_value)
		drops.append({
			"kind": String(stored.get("kind", "stone")), 
			"amount": maxi(1, int(stored.get("amount", 1))), 
			"position": Vector2(
				float(stored.get("x", 0.0)), 
				float(stored.get("y", 0.0))
			), 
			"velocity": Vector2.ZERO, 
			"age": 1.0, 
			"persistent_id": String(stored.get("id", "")), 
			"settled_persisted": true, 
		})
	_restore_pending_pocket_loot()


func _restore_pending_pocket_loot() -> void :
	for cavern_value in cavern_by_id.values():
		var cavern: Dictionary = Dictionary(cavern_value)
		var reward_id: = String(Dictionary(cavern.reward).id)
		var pending: Dictionary = RunState.pending_pocket_reward_loot(reward_id)
		_spawn_reward_plan_loot(
			reward_id, 
			pending, 
			Vector2(float(cavern.x), float(cavern.y) + 12.0)
		)


func _persist_loose_drop_positions() -> void :
	for drop in drops:
		var persistent_id: = String(drop.get("persistent_id", ""))
		if persistent_id.is_empty():
			continue
		RunState.update_mine_loose_loot_position(
			mine_id, 1, persistent_id, Vector2(drop.position)
		)


func _spawn_drop(
	cell: Vector2i,
	kind: String,
	amount: int = 1,
	crusher_origin: Vector2 = Vector2(INF, INF)
) -> void :
	var yield_kind: = kind if GameData.data.ROCK_TYPES.has(kind) else "stone"
	var center: = _cell_center(cell)
	var crusher_bundle: = crusher_origin.is_finite()
	var crusher_sector: = -1
	var merge_index: = -1
	var preferred_merge_id: = ""
	var direction: = Vector2.from_angle(float(cell.x * 31 + cell.y * 17) * 0.17)
	if crusher_bundle:
		var seed_value: = cell.x * 73856093 ^ cell.y * 19349663 ^ int(mine_id.hash())
		crusher_sector = CrusherLootBurstScript.sector_for(crusher_origin, center, seed_value)
		direction = CrusherLootBurstScript.direction_for_sector(crusher_sector)
		merge_index = CrusherLootBurstScript.merge_target_index(drops, yield_kind, crusher_sector)
		if merge_index >= 0:
			preferred_merge_id = String(drops[merge_index].get("persistent_id", ""))
	var stored: Dictionary = RunState.register_mine_loose_loot(
		mine_id, 1, yield_kind, maxi(1, amount), center, preferred_merge_id
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
				var merged_drop: Dictionary = drops[index]
				merged_drop.amount = int(stored.get("amount", merged_drop.amount))
				if crusher_bundle:
					merged_drop.position = center
					merged_drop.velocity = direction * CrusherLootBurstScript.LAUNCH_SPEED
					merged_drop.crusher_bundle = true
					merged_drop.crusher_sector = crusher_sector
					merged_drop.crusher_lift = CrusherLootBurstScript.ARC_LIFT
					merged_drop.crusher_flight_age = 0.0
					merged_drop.settled_persisted = false
					merged_drop.magnet_active = false
					if not merged_drop.has("visual_suppressed"):
						merged_drop.visual_suppressed = (
							_visible_crusher_bundle_count()
							>= CrusherLootBurstScript.MAX_VISIBLE_BUNDLES
						)
				drops[index] = merged_drop
				return
	var visual_suppressed: = (
		crusher_bundle
		and _visible_crusher_bundle_count() >= CrusherLootBurstScript.MAX_VISIBLE_BUNDLES
	)
	var drop: Dictionary = {
		"kind": yield_kind, 
		"amount": int(stored.get("amount", maxi(1, amount))), 
		"position": center, 
		"velocity": direction * (
			CrusherLootBurstScript.LAUNCH_SPEED if crusher_bundle else 76.0
		), 
		"age": 0.0, 
		"persistent_id": persistent_id, 
		"settled_persisted": false, 
	}
	if crusher_bundle:
		drop["crusher_bundle"] = true
		drop["crusher_sector"] = crusher_sector
		drop["crusher_lift"] = CrusherLootBurstScript.ARC_LIFT
		drop["crusher_flight_age"] = 0.0
		drop["visual_suppressed"] = visual_suppressed
		drop["magnet_active"] = false
	drops.append(drop)


func _visible_crusher_bundle_count() -> int:
	return CrusherLootBurstScript.visible_bundle_count(drops)


func _refresh_suppressed_crusher_bundles() -> bool:
	var visible_count: = _visible_crusher_bundle_count()
	if visible_count >= CrusherLootBurstScript.MAX_VISIBLE_BUNDLES:
		return false
	var changed: = false
	for index in drops.size():
		if visible_count >= CrusherLootBurstScript.MAX_VISIBLE_BUNDLES:
			break
		var drop: Dictionary = drops[index]
		if (
			not bool(drop.get("crusher_bundle", false))
			or not bool(drop.get("visual_suppressed", false))
		):
			continue
		drop.visual_suppressed = false
		drops[index] = drop
		visible_count += 1
		changed = true
	return changed


func _spawn_reward_plan_loot(reward_id: String, pending: Dictionary, origin: Vector2) -> void :
	var reward_offset: = -0.5 * float(maxi(0, pending.size() - 1))
	for resource_value in pending:
		var resource_id: = String(resource_value)
		var amount: = int(pending[resource_id])
		if amount <= 0:
			continue
		var position: = origin + Vector2(reward_offset * 22.0, 0.0)
		var angle: = float(drops.size() * 47 + floori(position.x) * 3 + floori(position.y)) * 0.013
		drops.append({
			"kind": resource_id, 
			"amount": amount, 
			"position": position, 
			"velocity": Vector2.from_angle(angle) * 76.0, 
			"age": 0.0, 
			"pocket_reward_id": reward_id, 
			"persistent_id": "", 
			"settled_persisted": true, 
		})
		reward_offset += 1.0


func _update_drops(delta: float) -> void :
	var drops_changed: = false
	for index in range(drops.size() - 1, -1, -1):
		var drop: Dictionary = drops[index]
		drop.position = Vector2(drop.position) + Vector2(drop.velocity) * delta
		drop.velocity = Vector2(drop.velocity) * pow(0.08, delta)
		drop.age = float(drop.age) + delta
		if bool(drop.get("crusher_bundle", false)):
			drop.crusher_flight_age = float(drop.get("crusher_flight_age", 0.0)) + delta
		drop.magnet_active = false
		if float(drop.age) >= LOOSE_RESOURCE_LIFETIME:
			var expired_reward_id: = String(drop.get("pocket_reward_id", ""))
			if not expired_reward_id.is_empty():
				RunState.collect_pocket_loot(expired_reward_id, String(drop.kind), maxi(1, int(drop.get("amount", 1))))
			else:
				RunState.collect_mine_loose_loot(
					mine_id, 
					1, 
					String(drop.get("persistent_id", "")), 
					maxi(1, int(drop.get("amount", 1)))
				)
			drops.remove_at(index)
			drops_changed = true
			continue
		if (
			String(drop.get("pocket_reward_id", "")).is_empty()
			and not String(drop.get("persistent_id", "")).is_empty()
			and 
			Vector2(drop.velocity).length_squared() <= 1.0
			and not bool(drop.get("settled_persisted", false))
		):
			RunState.update_mine_loose_loot_position(
				mine_id, 1, String(drop.get("persistent_id", "")), Vector2(drop.position)
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
		drop.magnet_active = true
		drop.position = Vector2(drop.position).move_toward(
			player.global_position + Vector2(0, -24), DROP_MAGNET_SPEED * delta
		)
		drop.velocity = Vector2.ZERO
		drops[index] = drop
		if Vector2(drop.position).distance_to(player.global_position + Vector2(0, -24)) <= DROP_MAGNET_COLLECT_RADIUS:
			var reward_id: = String(drop.get("pocket_reward_id", ""))
			if not reward_id.is_empty():
				var collected_amount: = RunState.collect_pocket_loot(
					reward_id, 
					String(drop.kind), 
					maxi(1, int(drop.get("amount", 1)))
				)
				if collected_amount <= 0:
					drops.remove_at(index)
					drops_changed = true
					continue
				var reward_remaining: = maxi(0, int(drop.amount) - collected_amount)
				if reward_remaining > 0:
					drop.amount = reward_remaining
					drops[index] = drop
				else:
					drops.remove_at(index)
					drops_changed = true
				AudioDirector.play_pickup(String(drop.kind), collected_amount)
				message_changed.emit("%s COLLECTED" % String(drop.kind).to_upper())
				continue
			var collected: Dictionary = RunState.collect_mine_loose_loot(
				mine_id, 
				1, 
				String(drop.get("persistent_id", "")), 
				maxi(1, int(drop.get("amount", 1)))
			)
			var amount: = int(collected.get("amount", 0))
			var remaining: = int(collected.get("remaining", 0))
			if remaining > 0:
				drop.amount = remaining
				drops[index] = drop
				if amount > 0:
					AudioDirector.play_pickup(String(drop.kind), amount)
					message_changed.emit("%s COLLECTED" % String(drop.kind).to_upper())
				continue
			drops.remove_at(index)
			drops_changed = true
			if amount > 0:
				AudioDirector.play_pickup(String(drop.kind), amount)
				message_changed.emit("%s COLLECTED" % String(drop.kind).to_upper())
	if _refresh_suppressed_crusher_bundles():
		drops_changed = true
	if drops_changed:
		_request_redraw()


func _update_impacts(delta: float) -> void :
	for index in range(impacts.size() - 1, -1, -1):
		impacts[index].age = float(impacts[index].age) + delta
		if float(impacts[index].age) >= float(impacts[index].life):
			impacts.remove_at(index)


func _update_respawns(delta: float) -> void :
	var now: = Time.get_unix_time_from_system()
	for index in range(respawns.size() - 1, -1, -1):
		var pending: Dictionary = respawns[index]
		var respawn_until: = float(pending.get("respawn_until_unix", now))
		pending.remaining = maxf(0.0, respawn_until - now)
		respawns[index] = pending
		if float(pending.remaining) > 0.0:
			continue
		var cell: Vector2i = Vector2i(pending.cell)
		if blocks.has(cell) or player.global_position.distance_to(_cell_center(cell)) < TILE_SIZE * 1.7:
			pending.respawn_until_unix = now + 0.5
			pending.remaining = 0.5
			respawns[index] = pending
			continue
		var restored: Dictionary = Dictionary(pending.block).duplicate(true)
		restored.hp = int(restored.max_hp)
		restored.shell = int(restored.get("max_shell", 0))
		blocks[cell] = restored
		respawns.remove_at(index)
		RunState.clear_mine_resource_depletion(
			mine_id, 1, String(pending.get("node_id", _resource_node_id(cell)))
		)
		target_dirty = true
		_request_redraw()


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


func _world_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE_SIZE), floori(point.y / TILE_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


func _draw() -> void :
	if mine.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, world_size), Color(String(mine.floor)), true)
	draw_texture_rect(floor_texture, Rect2(Vector2.ZERO, world_size), true, Color(0.7, 0.72, 0.68, 0.94))
	_draw_barrier_backplates()
	var view_radius: = Vector2(310, 470)
	var start: = _world_to_cell(player.global_position - view_radius)
	var finish: = _world_to_cell(player.global_position + view_radius)
	var visible_block_cells: Array[Vector2i] = []
	for row in range(maxi(0, start.y), mini(rows - 1, finish.y) + 1):
		for col in range(maxi(0, start.x), mini(cols - 1, finish.x) + 1):
			var cell: = Vector2i(col, row)
			if blocks.has(cell):
				visible_block_cells.append(cell)
				_draw_block(cell, Dictionary(blocks[cell]))
	# Edge art is a separate pass so later block fills cannot chop up a shared rim.
	for cell in visible_block_cells:
		_draw_block_edges(cell, Dictionary(blocks[cell]))
	_draw_concealed_discoveries(start, finish)
	_draw_barrier_art()
	_draw_route_markers_and_labels()
	_draw_cavern_landmarks()
	_draw_entrance()
	if RunState.is_depth_entrance_discovered(mine_id):
		_draw_depth_entrance()
	for impact in impacts:
		_draw_impact(impact)
	for drop in drops:
		_draw_drop(drop)
	_draw_target()


func _draw_concealed_discoveries(start: Vector2i, finish: Vector2i) -> void :
	var depth_hidden: = not RunState.is_depth_entrance_discovered(mine_id)
	for row in range(maxi(0, start.y), mini(rows - 1, finish.y) + 1):
		for col in range(maxi(0, start.x), mini(cols - 1, finish.x) + 1):
			var cell: = Vector2i(col, row)
			var index: = row * cols + col
			var hidden: = depth_hidden and depth_entrance_cells.has(index)
			if not hidden and concealed_cavern_cells.has(index):
				hidden = not RunState.is_cavern_discovered(String(concealed_cavern_cells[index]))
			if hidden:
				_draw_concealed_cell(cell)


func _draw_concealed_cell(cell: Vector2i) -> void :
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE).grow(0.7)
	var dirt: = Color(String(GameData.data.MINE_DIRT_COLORS.get(mine_id, mine.wall)))
	draw_rect(rect, dirt.darkened(0.22), true)
	var noise: = fposmod(sin(float(cell.x * 31 + cell.y * 17)) * 43758.5453, 1.0)
	draw_circle(rect.position + Vector2(8.0 + noise * 26.0, 9.0 + (1.0 - noise) * 25.0), 1.1 + noise, Color(0.78, 0.68, 0.48, 0.11))


func _draw_block(cell: Vector2i, block: Dictionary) -> void :
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE).grow(0.7)
	var kind: = String(block.kind)
	var bedrock: = kind == "bedrock"
	var base_color: = Color("10130f") if bedrock else Color(String(GameData.data.ROCK_TYPES.get(kind, {"color": mine.wall}).color))
	if String(block.role) in ["terrain", "resource"]:
		base_color = Color(String(GameData.data.MINE_DIRT_COLORS.get(mine_id, mine.wall)))
	if bedrock:
		# Bedrock is one fused foundation mass.  Keep its top quiet and broad so the
		# 48 px gameplay grid never reads as a field of individual mineable tiles.
		var plate_noise: = _bedrock_plate_noise(cell, 0)
		var plate: = Color("111410").lerp(Color("252923"), 0.10 + plate_noise * 0.08)
		draw_rect(rect, plate, true)
	else:
		draw_rect(rect, base_color.darkened(0.22), true)
		var noise: = fposmod(sin(float(cell.x * 31 + cell.y * 17)) * 43758.5453, 1.0)
		draw_circle(rect.position + Vector2(8.0 + noise * 26.0, 9.0 + (1.0 - noise) * 25.0), 1.1 + noise, Color(0.78, 0.68, 0.48, 0.11))
	var open_sides: = _open_block_sides(cell)
	var seam: Texture2D = _resource_node_texture(kind) if String(block.role) == "resource" else _resource_texture(kind)
	if (kind != "stone" or String(block.role) != "terrain") and open_sides.has(true) and kind != "bedrock":
		var inset: = 2.0 if String(block.role) == "resource" else 5.0
		draw_texture_rect(seam, rect.grow( - inset), false, Color(0.98, 0.98, 0.96, 0.96))
	var hp_ratio: = float(block.hp) / maxf(1.0, float(block.max_hp))
	if kind != "bedrock" and hp_ratio < 0.999:
		var center: = rect.get_center()
		draw_line(rect.position + Vector2(9, 8), center, Color(0.08, 0.05, 0.03, 0.8), 3.0)
		draw_line(center, rect.end - Vector2(7, 9), Color(0.08, 0.05, 0.03, 0.8), 3.0)


func _draw_block_edges(cell: Vector2i, block: Dictionary) -> void :
	var open_sides: = _open_block_sides(cell)
	if not open_sides.has(true):
		return
	var bedrock: = String(block.kind) == "bedrock"
	for side in 4:
		if bool(open_sides[side]):
			_draw_wall_face(cell, side, bedrock)
	_draw_wall_corner_caps(cell, open_sides, bedrock)


func _open_block_sides(cell: Vector2i) -> Array[bool]:
	return [
		not blocks.has(cell + Vector2i.UP),
		not blocks.has(cell + Vector2i.RIGHT),
		not blocks.has(cell + Vector2i.DOWN),
		not blocks.has(cell + Vector2i.LEFT),
	]


func _draw_barrier_art() -> void :
	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		var barrier_id: = String(barrier.id)
		if not _role_has_blocks(barrier_id):
			continue
		var rect: = Rect2(float(barrier.x), float(barrier.y), float(barrier.w), float(barrier.h))
		_draw_premium_barrier(barrier, rect)


func _draw_barrier_backplates() -> void :
	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		var barrier_id: = String(barrier.id)
		if not _role_has_blocks(barrier_id):
			continue
		var rect: = Rect2(float(barrier.x), float(barrier.y), float(barrier.w), float(barrier.h))
		var vertical: = rect.size.y >= rect.size.x
		var along: = Vector2.DOWN if vertical else Vector2.RIGHT
		var across: = Vector2.RIGHT if vertical else Vector2.DOWN
		var length: = rect.size.y if vertical else rect.size.x
		var thickness: = rect.size.x if vertical else rect.size.y
		var center: = rect.get_center()
		var wall: = Color(String(mine.wall)).darkened(0.46)
		var shadow_half_length: = length * 0.5 + 14.0
		var shadow_half_width: = thickness * 0.5 + 15.0
		var shadow: = _barrier_quad(center, along, across, shadow_half_length, shadow_half_width)
		draw_colored_polygon(shadow, Color(wall, 0.94))
		for end_sign_value in [-1.0, 1.0]:
			var end_sign: float = float(end_sign_value)
			var root: = center + along * end_sign * (length * 0.5 + 5.0)
			draw_circle(root, thickness * 0.54, Color(wall, 0.9))


func _draw_premium_barrier(barrier: Dictionary, rect: Rect2) -> void :
	var barrier_id: = String(barrier.id)
	var required: = int(barrier.requiresPickaxe)
	var locked: = int(RunState.pickaxe_level) < required
	var vertical: = rect.size.y >= rect.size.x
	var along: = Vector2.DOWN if vertical else Vector2.RIGHT
	var across: = Vector2.RIGHT if vertical else Vector2.DOWN
	var length: = rect.size.y if vertical else rect.size.x
	var thickness: = rect.size.x if vertical else rect.size.y
	var center: = rect.get_center()
	var seed: = absi(barrier_id.hash())
	var wall: = Color(String(mine.wall))
	var edge: = Color(String(mine.get("wallEdge", mine.detail)))
	var stone_dark: = wall.darkened(0.34)
	var stone_mid: = wall.lerp(edge, 0.34).lightened(0.05)
	var stone_light: = edge.lightened(0.11)
	var accent: = Color(String(BARRIER_ACCENTS.get(mine_id, mine.detail)))
	var row_count: = maxi(4, ceili(length / 43.0))
	var row_step: = length / float(row_count)
	for row in row_count:
		for column in 2:
			var stagger: = -0.5 if column == 0 else 0.5
			var row_noise: = _barrier_noise(seed, row * 13 + column * 7)
			var cross_noise: = _barrier_noise(seed, row * 17 + column * 11 + 71)
			var position: = (
				center
				+ along * (-length * 0.5 + (float(row) + 0.5) * row_step + (row_noise - 0.5) * 5.0)
				+ across * (stagger * thickness * 0.48 + (cross_noise - 0.5) * 5.0)
			)
			_draw_barrier_stone(
				position, along, across, row_step * (0.68 + row_noise * 0.08), 
				thickness * (0.39 + cross_noise * 0.045), stone_dark, stone_mid, stone_light, 
				seed + row * 29 + column * 101
			)
	# Wider end stones visually grow the barrier into both adjoining cave walls.
	for end_index in 2:
		var end_sign: = -1.0 if end_index == 0 else 1.0
		for shoulder in 3:
			var shoulder_noise: = _barrier_noise(seed, 311 + end_index * 37 + shoulder * 19)
			var shoulder_position: = (
				center
				+ along * end_sign * (length * 0.5 + 4.0 + shoulder_noise * 5.0)
				+ across * (float(shoulder - 1) * thickness * 0.43)
			)
			_draw_barrier_stone(
				shoulder_position, along, across, 24.0 + shoulder_noise * 5.0, 
				thickness * 0.34, stone_dark, stone_mid, stone_light, 
				seed + 503 + end_index * 83 + shoulder * 41
			)
	if required > 1:
		_draw_barrier_bracing(center, along, across, length, thickness, required, locked, accent, barrier_id)
	var integrity: = _barrier_integrity(barrier_id)
	if integrity < 0.98:
		_draw_barrier_fractures(center, along, across, length, thickness, integrity, accent, seed)


func _draw_barrier_stone(
	center: Vector2, 
	along: Vector2, 
	across: Vector2, 
	along_radius: float, 
	across_radius: float, 
	dark: Color, 
	mid: Color, 
	light: Color, 
	seed: int
) -> void :
	var points: = PackedVector2Array()
	for point_index in 8:
		var angle: = TAU * float(point_index) / 8.0
		var shape_noise: = 0.82 + _barrier_noise(seed, point_index * 23 + 5) * 0.24
		points.append(
			center
			+ across * cos(angle) * across_radius * shape_noise
			+ along * sin(angle) * along_radius * shape_noise
		)
	var shadow_points: = PackedVector2Array()
	for point in points:
		shadow_points.append(point + along * 2.5 + across * 1.5)
	draw_colored_polygon(shadow_points, Color(dark.darkened(0.4), 0.88))
	var shade: = _barrier_noise(seed, 271)
	var body_color: = mid.lerp(dark, shade * 0.32)
	draw_colored_polygon(points, Color(body_color, 0.99))
	# Broad, uneven tonal planes keep the masonry in the painterly world style
	# while preserving the authored outer silhouette.
	var crown: = (
		center
		- along * along_radius * (0.1 + _barrier_noise(seed, 283) * 0.16)
		- across * across_radius * (0.06 + _barrier_noise(seed, 293) * 0.14)
	)
	var upper_plane: = PackedVector2Array([points[4], points[5], points[6], points[7], crown])
	var lit_plane: = PackedVector2Array([points[7], points[0], points[1], crown])
	var lower_plane: = PackedVector2Array([points[1], points[2], points[3], crown])
	var deep_plane: = PackedVector2Array([points[3], points[4], crown])
	draw_colored_polygon(upper_plane, Color(light.lerp(body_color, 0.48), 0.24 + shade * 0.06))
	draw_colored_polygon(lit_plane, Color(light.lerp(body_color, 0.64), 0.14))
	draw_colored_polygon(lower_plane, Color(dark, 0.2 + shade * 0.1))
	draw_colored_polygon(deep_plane, Color(dark.darkened(0.18), 0.17))
	var outline: = PackedVector2Array(points)
	outline.append(points[0])
	draw_polyline(outline, Color(dark, 0.86), 2.1, true)
	draw_line(crown, points[7], Color(light, 0.36), 1.05, true)
	draw_line(crown, points[1], Color(light, 0.25), 0.9, true)
	draw_line(crown, points[3], Color(dark, 0.48), 1.15, true)
	draw_line(crown, points[5], Color(dark, 0.34), 0.9, true)
	var fracture_noise: = _barrier_noise(seed, 347)
	if fracture_noise > 0.48:
		var fracture_mid: = crown + along * along_radius * (0.16 + fracture_noise * 0.15)
		var fracture_end: = fracture_mid + across * across_radius * (fracture_noise - 0.5) * 0.62 + along * along_radius * 0.2
		draw_polyline(PackedVector2Array([crown, fracture_mid, fracture_end]), Color(dark.darkened(0.28), 0.52), 0.85, true)
	_draw_barrier_stone_detail(center, along, across, along_radius, across_radius, light, seed)


func _draw_barrier_stone_detail(
	center: Vector2, 
	along: Vector2, 
	across: Vector2, 
	along_radius: float, 
	across_radius: float, 
	light: Color, 
	seed: int
) -> void :
	var detail_noise: = _barrier_noise(seed, 401)
	if detail_noise < 0.43:
		return
	var detail_color: Color
	match mine_id:
		"moonMine":
			detail_color = Color("78d7e8")
		"emberMine":
			detail_color = Color("d76a31")
		"starMine":
			detail_color = Color("9b85d7")
		_:
			detail_color = Color("7d8a50")
	var detail_position: = (
		center
		+ along * (detail_noise - 0.62) * along_radius * 0.66
		+ across * (_barrier_noise(seed, 419) - 0.5) * across_radius * 0.9
	)
	if mine_id == "mossMine":
		draw_circle(detail_position, 1.15 + detail_noise, Color(detail_color, 0.34))
		draw_circle(detail_position + across * 3.1 + along * 1.2, 0.8, Color(detail_color.lightened(0.12), 0.24))
	else:
		var glint_length: = 3.5 + detail_noise * 4.0
		draw_line(
			detail_position - along * glint_length * 0.5, 
			detail_position + along * glint_length * 0.5 + across * 1.8, 
			Color(detail_color.lerp(light, 0.16), 0.25), 
			0.85, 
			true
		)


func _draw_barrier_bracing(
	center: Vector2, 
	along: Vector2, 
	across: Vector2, 
	length: float, 
	thickness: float, 
	required: int, 
	locked: bool, 
	accent: Color, 
	barrier_id: String
) -> void :
	var metal_dark: = Color("17191a")
	var metal: = Color("34383a").lerp(accent.darkened(0.5), 0.12)
	var metal_edge: = Color("737779")
	var beam_start: = center - along * (length * 0.5 - 13.0)
	var beam_end: = center + along * (length * 0.5 - 13.0)
	for rail_sign_value in [-1.0, 1.0]:
		var rail_sign: float = float(rail_sign_value)
		var offset: = across * rail_sign * thickness * 0.28
		_draw_barrier_beam(beam_start + offset, beam_end + offset, across, metal_dark, metal, metal_edge, 8.0)
	var brace_count: = 2 if required <= 2 else 3
	for brace_index in brace_count:
		var ratio: = (float(brace_index) + 1.0) / (float(brace_count) + 1.0)
		var brace_center: = center - along * length * 0.5 + along * length * ratio
		_draw_barrier_beam(
			brace_center - across * (thickness * 0.5 + 7.0), 
			brace_center + across * (thickness * 0.5 + 7.0), 
			along, metal_dark, metal, metal_edge, 8.5
		)
		for rivet_sign_value in [-1.0, 1.0]:
			var rivet_sign: float = float(rivet_sign_value)
			var rivet: = brace_center + across * rivet_sign * thickness * 0.37
			draw_circle(rivet, 3.2, metal_dark)
			draw_circle(rivet - along * 0.8 - across * 0.5, 1.35, Color(metal_edge, 0.82))
	_draw_barrier_lock(center, along, across, length, thickness, locked, accent, barrier_id)


func _draw_barrier_beam(
	start: Vector2, 
	finish: Vector2, 
	highlight_offset: Vector2, 
	dark: Color, 
	metal: Color, 
	edge: Color, 
	width: float
) -> void :
	draw_line(start, finish, Color(dark, 0.98), width + 4.0, true)
	draw_line(start, finish, Color(metal, 0.99), width, true)
	draw_line(start - highlight_offset * 1.35, finish - highlight_offset * 1.35, Color(edge, 0.62), 1.25, true)


func _draw_barrier_lock(
	center: Vector2, 
	along: Vector2, 
	across: Vector2, 
	length: float, 
	thickness: float, 
	locked: bool, 
	accent: Color, 
	barrier_id: String
) -> void :
	var glow_alpha: = 0.18 if locked else 0.1
	for radius in [25.0, 19.0, 13.0]:
		draw_circle(center, radius, Color(accent, glow_alpha * (1.0 - (radius - 13.0) / 20.0)))
	if BARRIER_ASSETS.has(barrier_id):
		var core_texture: Texture2D = _texture(String(BARRIER_ASSETS[barrier_id]))
		var source_size: = Vector2(core_texture.get_size())
		var core_height: = minf(length * 0.64, 182.0)
		var core_width: = core_height * source_size.x / maxf(1.0, source_size.y)
		var max_width: = thickness * 0.58
		if core_width > max_width:
			core_width = max_width
			core_height = core_width * source_size.y / maxf(1.0, source_size.x)
		var core_size: = Vector2(core_width, core_height)
		var core_tint: = Color(1, 1, 1, 0.98 if locked else 0.72)
		if along.is_equal_approx(Vector2.DOWN):
			draw_texture_rect(core_texture, Rect2(center - core_size * 0.5, core_size), false, core_tint)
		else:
			draw_set_transform(center, PI * 0.5, Vector2.ONE)
			draw_texture_rect(core_texture, Rect2(-core_size * 0.5, core_size), false, core_tint)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var outer: = _barrier_diamond(center, along, across, 25.0, 25.0)
	var inner: = _barrier_diamond(center, along, across, 17.0, 17.0)
	draw_colored_polygon(outer, Color("17191a"))
	draw_polyline(_closed_polygon(outer), Color("74797b"), 2.1, true)
	draw_colored_polygon(inner, Color("292d2e"))
	draw_polyline(_closed_polygon(inner), Color(accent, 0.62 if locked else 0.36), 1.6, true)
	draw_circle(center, 8.3, Color("121516"))
	draw_circle(center, 5.8, Color(accent, 0.96 if locked else 0.48))
	var rune: = PackedVector2Array([
		center + across * -3.4 + along * -3.8, 
		center + across * 3.5 + along * -3.8, 
		center + across * 3.5 + along * 2.5, 
		center + across * -1.0 + along * 2.5, 
		center + across * -1.0 + along * -0.6, 
		center + across * 1.4 + along * -0.6, 
	])
	draw_polyline(rune, Color(accent.lightened(0.28), 0.94 if locked else 0.55), 1.55, true)


func _draw_barrier_fractures(
	center: Vector2, 
	along: Vector2, 
	across: Vector2, 
	length: float, 
	thickness: float, 
	integrity: float, 
	accent: Color, 
	seed: int
) -> void :
	var fracture_count: = clampi(ceili((1.0 - integrity) * 7.0), 1, 6)
	for fracture_index in fracture_count:
		var along_noise: = _barrier_noise(seed, 701 + fracture_index * 31)
		var across_noise: = _barrier_noise(seed, 733 + fracture_index * 43)
		var origin: = (
			center
			+ along * (along_noise - 0.5) * length * 0.72
			+ across * (across_noise - 0.5) * thickness * 0.54
		)
		var bend: = origin + along * (5.0 + along_noise * 6.0) + across * (across_noise - 0.5) * 9.0
		var finish: = bend + along * (4.0 + across_noise * 5.0) - across * (along_noise - 0.5) * 10.0
		draw_polyline(PackedVector2Array([origin, bend, finish]), Color("100c09"), 2.4, true)
		draw_polyline(PackedVector2Array([origin, bend, finish]), Color(accent, 0.28), 0.8, true)


func _barrier_integrity(barrier_id: String) -> float:
	var maximum: = 0.0
	var current: = 0.0
	for rock_value in mine.rocks:
		var rock: Array = Array(rock_value)
		if rock.size() < 4 or String(rock[3]) != barrier_id:
			continue
		var kind: = String(rock[0])
		var max_hp: = float(Dictionary(GameData.data.ROCK_TYPES[kind]).hp)
		maximum += max_hp
		var cell: = Vector2i(floori(float(rock[1]) / TILE_SIZE), floori(float(rock[2]) / TILE_SIZE))
		if blocks.has(cell):
			current += float(Dictionary(blocks[cell]).get("hp", 0))
	return clampf(current / maximum, 0.0, 1.0) if maximum > 0.0 else 1.0


func _barrier_quad(center: Vector2, along: Vector2, across: Vector2, half_length: float, half_width: float) -> PackedVector2Array:
	return PackedVector2Array([
		center - along * half_length - across * half_width, 
		center - along * half_length + across * half_width, 
		center + along * half_length + across * half_width, 
		center + along * half_length - across * half_width, 
	])


func _barrier_diamond(center: Vector2, along: Vector2, across: Vector2, along_radius: float, across_radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		center - along * along_radius, 
		center + across * across_radius, 
		center + along * along_radius, 
		center - across * across_radius, 
	])


func _closed_polygon(points: PackedVector2Array) -> PackedVector2Array:
	var closed: = PackedVector2Array(points)
	if not points.is_empty():
		closed.append(points[0])
	return closed


func _barrier_noise(seed: int, channel: int) -> float:
	var value: = float(seed * 15731 + channel * 789221)
	return fposmod(sin(value * 0.000173) * 43758.5453, 1.0)


func _draw_route_markers_and_labels() -> void :
	for label_value in Array(mine.get("labels", [])):
		var label: Array = Array(label_value)
		if label.size() < 4:
			continue
		var position: = Vector2(float(label[1]), float(label[2]))
		if player.global_position.distance_to(position) > 570.0:
			continue
		var color: = Color(String(label[3]))
		if route_marker_texture != null:
			var marker_size: = Vector2(82, 41)
			draw_texture_rect(
				route_marker_texture, 
				Rect2(position + Vector2( - marker_size.x * 0.5, 9.0), marker_size), 
				false, 
				Color(1, 1, 1, 0.72)
			)
		_draw_route_plaque(position, String(label[0]), color)


func _draw_route_plaque(position: Vector2, text: String, color: Color) -> void :
	var width: = clampf(64.0 + float(text.length()) * 4.6, 112.0, 190.0)
	var rect: = Rect2(position + Vector2( - width * 0.5, -20.0), Vector2(width, 25.0))
	draw_rect(rect, Color(0.012, 0.018, 0.016, 0.84), true)
	draw_line(rect.position + Vector2(7, rect.size.y), rect.end - Vector2(7, 0), Color(color, 0.66), 1.2)
	draw_circle(Vector2(rect.position.x + 6, rect.end.y), 2.2, Color(color, 0.82))
	draw_circle(Vector2(rect.end.x - 6, rect.end.y), 2.2, Color(color, 0.82))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 16), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 9, color)


func _draw_cavern_landmarks() -> void :
	for cavern_id_value in cavern_by_id:
		var cavern_id: = String(cavern_id_value)
		if not RunState.is_cavern_discovered(cavern_id):
			continue
		var cavern: Dictionary = Dictionary(cavern_by_id[cavern_id])
		var position: = Vector2(float(cavern.x), float(cavern.y))
		if player.global_position.distance_to(position) > 570.0:
			continue
		var reward: Dictionary = Dictionary(cavern.reward)
		var reward_id: = String(reward.id)
		var kind: = String(reward.kind)
		var claimed: = _pocket_reward_is_claimed(reward_id)
		var accent: = Color(String(mine.detail))
		if kind in ["crystal", "motherlode"]:
			var pocket_size: = Vector2(150, 84)
			var tint: = Color(1, 1, 1, 0.18 if claimed else 0.58)
			draw_texture_rect(pocket_texture, Rect2(position - pocket_size * Vector2(0.5, 0.6), pocket_size), false, tint)
		elif not claimed:
			var texture: Texture2D = cache_texture if kind == "cache" else shrine_texture
			var source_size: = Vector2(texture.get_size())
			var scale_factor: = minf(116.0 / source_size.x, 102.0 / source_size.y)
			var size: = source_size * scale_factor
			draw_circle(position + Vector2(0, 13), 51.0, Color(accent, 0.09))
			draw_texture_rect(texture, Rect2(position - size * Vector2(0.5, 0.62), size), false)
		var reward_text: = "DEPLETED" if claimed else String(reward.get("label", kind)).to_upper()
		_draw_cavern_label(position, String(cavern.name).to_upper(), reward_text, accent, claimed)


func _draw_cavern_label(
	position: Vector2, 
	name: String, 
	reward_text: String, 
	color: Color, 
	claimed: bool
) -> void :
	var width: = clampf(90.0 + float(maxi(name.length(), reward_text.length())) * 3.8, 150.0, 222.0)
	var rect: = Rect2(position + Vector2( - width * 0.5, 66.0), Vector2(width, 42.0))
	draw_rect(rect, Color(0.008, 0.013, 0.012, 0.82), true)
	draw_rect(rect, Color(color, 0.25 if claimed else 0.56), false, 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 16), name, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 9, Color(color, 0.72 if claimed else 0.98))
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(0, 33), reward_text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 8, Color(0.72, 0.75, 0.7, 0.76 if claimed else 0.94))


func _role_has_blocks(role: String) -> bool:
	return int(role_block_counts.get(role, 0)) > 0


func _rebuild_role_counts() -> void :
	role_block_counts.clear()
	for barrier_value in mine.barriers:
		role_block_counts[String(Dictionary(barrier_value).id)] = 0
	for block_value in blocks.values():
		var block: Dictionary = Dictionary(block_value)
		var role: = String(block.get("role", ""))
		if role_block_counts.has(role):
			if bool(block.get("barrier_trigger", false)):
				role_block_counts[role] = int(role_block_counts[role]) + 1


func _migrate_legacy_barrier_progress() -> void :
	for barrier_value in mine.barriers:
		var barrier_id: = String(Dictionary(barrier_value).id)
		if int(role_block_counts.get(barrier_id, 0)) == 0 and not RunState.is_mine_barrier_cleared(barrier_id):
			RunState.mark_barrier_cleared(barrier_id)


func _erase_role(role: String) -> void :
	var cells: Array = []
	for cell in blocks:
		if String(Dictionary(blocks[cell]).get("role", "")) == role:
			cells.append(cell)
	for cell in cells:
		blocks.erase(cell)
	role_block_counts[role] = 0


func _is_barrier_role(role: String) -> bool:
	for barrier_value in mine.barriers:
		if String(Dictionary(barrier_value).id) == role:
			return true
	return false


func _draw_wall_face(cell: Vector2i, side: int, bedrock: bool) -> void :
	if bedrock:
		_draw_bedrock_face(cell, side)
	else:
		_draw_natural_wall_face(cell, side)


func _wall_edge_basis(cell: Vector2i, side: int) -> Dictionary:
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
	var edge_start: Vector2
	var tangent: Vector2
	var outward: Vector2
	match side:
		0:
			edge_start = rect.position
			tangent = Vector2.RIGHT
			outward = Vector2.UP
		1:
			edge_start = Vector2(rect.end.x, rect.position.y)
			tangent = Vector2.DOWN
			outward = Vector2.RIGHT
		2:
			edge_start = Vector2(rect.position.x, rect.end.y)
			tangent = Vector2.RIGHT
			outward = Vector2.DOWN
		_:
			edge_start = rect.position
			tangent = Vector2.DOWN
			outward = Vector2.LEFT
	return {"start": edge_start, "tangent": tangent, "outward": outward}


func _draw_natural_wall_face(cell: Vector2i, side: int) -> void :
	var basis: = _wall_edge_basis(cell, side)
	var edge_start: Vector2 = Vector2(basis.start)
	var tangent: Vector2 = Vector2(basis.tangent)
	var outward: Vector2 = Vector2(basis.outward)
	var outer_points: = PackedVector2Array()
	var inner_points: = PackedVector2Array()
	for sample in 5:
		var ratio: = float(sample) * 0.25
		var outer_noise: = _wall_edge_noise(cell, side, sample, 0)
		var depth_noise: = _wall_edge_noise(cell, side, sample, 1)
		outer_points.append(edge_start + tangent * (TILE_SIZE * ratio) + outward * (3.0 + outer_noise * 7.5))
		inner_points.append(edge_start + tangent * (TILE_SIZE * ratio) - outward * (13.5 + depth_noise * 8.5))
	var ribbon: = PackedVector2Array(outer_points)
	for index in range(inner_points.size() - 1, -1, -1):
		ribbon.append(inner_points[index])
	var wall_color: = Color(String(mine.wall))
	var edge_color: = Color(String(mine.get("wallEdge", mine.detail)))
	var shadow: = wall_color.darkened(0.52)
	var stone: = wall_color.lerp(edge_color, 0.34).lightened(0.025)
	var ridge: = edge_color.lightened(0.06)
	var highlight: = Color(String(mine.detail)).lerp(Color.WHITE, 0.05)
	var shadow_points: = PackedVector2Array()
	for point in outer_points:
		shadow_points.append(point + outward * 3.8)
	draw_polyline(shadow_points, Color(shadow, 0.78), 9.0, true)
	draw_colored_polygon(ribbon, Color(stone, 0.99))
	# Broad, adjoining facets make the face read as rock grown into the wall.  The
	# shared boundary samples keep every facet continuous across neighbouring cells.
	for sample in range(4):
		var facet_noise: = _wall_edge_noise(cell, side, sample, 4)
		var facet: = PackedVector2Array([
			outer_points[sample], outer_points[sample + 1],
			inner_points[sample + 1], inner_points[sample],
		])
		var facet_color: = stone.lightened((facet_noise - 0.5) * 0.105)
		draw_colored_polygon(facet, Color(facet_color, 0.68))
		if facet_noise > 0.58:
			var crease_start: Vector2 = outer_points[sample].lerp(inner_points[sample], 0.48)
			var crease_end: Vector2 = outer_points[sample + 1].lerp(inner_points[sample + 1], 0.67)
			draw_line(crease_start, crease_end, Color(shadow, 0.34), 1.1, true)
	draw_polyline(inner_points, Color(shadow, 0.5), 2.8, true)
	for sample in range(4):
		if _wall_edge_noise(cell, side, sample, 2) < 0.46:
			continue
		var start_point: Vector2 = outer_points[sample].lerp(inner_points[sample], 0.06)
		var end_point: Vector2 = outer_points[sample + 1].lerp(inner_points[sample + 1], 0.06)
		draw_line(start_point, end_point, Color(highlight, 0.28), 1.1, true)
	_draw_embedded_wall_stone(cell, side, edge_start, tangent, outward, stone, ridge, 0)
	if _wall_edge_noise(cell, side, 2, 7) > 0.52:
		_draw_embedded_wall_stone(cell, side, edge_start, tangent, outward, stone, ridge, 1)


func _draw_embedded_wall_stone(
	cell: Vector2i,
	side: int,
	edge_start: Vector2,
	tangent: Vector2,
	outward: Vector2,
	stone: Color,
	ridge: Color,
	stone_index: int
) -> void :
	var along_noise: = _wall_edge_noise(cell, side, stone_index + 1, 5)
	var shape_noise: = _wall_edge_noise(cell, side, stone_index + 2, 6)
	var along: = 0.18 + along_noise * 0.62
	var center: = edge_start + tangent * (TILE_SIZE * along) - outward * (5.8 + shape_noise * 4.0)
	var half_width: = 4.8 + shape_noise * 4.4
	var half_depth: = 3.8 + along_noise * 3.2
	var rock: = PackedVector2Array([
		center - tangent * half_width + outward * half_depth * 0.12,
		center - tangent * half_width * 0.46 + outward * half_depth,
		center + tangent * half_width * 0.38 + outward * half_depth * 0.82,
		center + tangent * half_width - outward * half_depth * 0.18,
		center + tangent * half_width * 0.28 - outward * half_depth,
		center - tangent * half_width * 0.55 - outward * half_depth * 0.72,
	])
	var rock_color: = stone.lerp(ridge, 0.18 + shape_noise * 0.16).lightened((along_noise - 0.5) * 0.08)
	draw_colored_polygon(rock, Color(rock_color, 0.92))
	draw_line(rock[1], rock[2], Color(ridge, 0.24), 0.9, true)
	draw_line(rock[3], rock[4], Color(stone.darkened(0.35), 0.3), 1.0, true)


func _draw_bedrock_face(cell: Vector2i, side: int) -> void :
	var basis: = _wall_edge_basis(cell, side)
	var edge_start: Vector2 = Vector2(basis.start)
	var tangent: Vector2 = Vector2(basis.tangent)
	var outward: Vector2 = Vector2(basis.outward)
	var outer_points: = PackedVector2Array()
	var inner_points: = PackedVector2Array()
	for sample in 5:
		var ratio: = float(sample) * 0.25
		var outer_noise: = _wall_edge_noise(cell, side, sample, 8)
		var depth_noise: = _wall_edge_noise(cell, side, sample, 9)
		outer_points.append(edge_start + tangent * (TILE_SIZE * ratio) + outward * (2.0 + outer_noise * 3.0))
		inner_points.append(edge_start + tangent * (TILE_SIZE * ratio) - outward * (25.0 + depth_noise * 10.0))
	var face: = PackedVector2Array(outer_points)
	for index in range(inner_points.size() - 1, -1, -1):
		face.append(inner_points[index])
	var outer_shadow: = PackedVector2Array()
	for point in outer_points:
		outer_shadow.append(point + outward * 8.0)
	draw_polyline(outer_shadow, Color(0.004, 0.005, 0.004, 0.82), 18.0, true)
	var foundation: = Color("242821").lerp(Color("343932"), _bedrock_plate_noise(cell, side + 1) * 0.12)
	draw_colored_polygon(face, Color(foundation, 1.0))
	# Wide tonal strata continue from tile to tile.  They deliberately avoid chips,
	# bright rims and damage cracks: this is a permanent geological mass.
	for layer in range(2):
		var stratum: = PackedVector2Array()
		var depth_ratio: = 0.34 + float(layer) * 0.34
		for sample in 5:
			stratum.append(outer_points[sample].lerp(inner_points[sample], depth_ratio))
		var stratum_color: = Color("596057") if layer == 0 else Color("080a08")
		var alpha: = 0.18 if layer == 0 else 0.26
		draw_polyline(stratum, Color(stratum_color, alpha), 4.8 if layer == 0 else 6.2, true)
	var outer_plane: = PackedVector2Array()
	for point in outer_points:
		outer_plane.append(point - outward * 0.8)
	draw_polyline(outer_plane, Color("6f756b", 0.24), 1.4, true)


func _bedrock_plate_noise(cell: Vector2i, channel: int) -> float:
	# Quantising to broad 4x3 regions keeps variation larger than the mining grid.
	var region_x: = floori(float(cell.x) / 4.0)
	var region_y: = floori(float(cell.y) / 3.0)
	var seed: = float(region_x * 19349663 + region_y * 83492791 + channel * 265443576)
	return fposmod(sin(seed * 0.0000137) * 43758.5453, 1.0)


func _wall_edge_noise(cell: Vector2i, side: int, sample: int, channel: int) -> float:
	var along: int
	var boundary: int
	var orientation: int
	if side == 0 or side == 2:
		along = cell.x * 4 + sample
		boundary = cell.y + (1 if side == 2 else 0)
		orientation = 0
	else:
		along = cell.y * 4 + sample
		boundary = cell.x + (1 if side == 1 else 0)
		orientation = 1
	var seed: = float(along * 15731 + boundary * 789221 + orientation * 137 + channel * 1999)
	return fposmod(sin(seed * 0.000173) * 43758.5453, 1.0)


func _draw_wall_corner_caps(cell: Vector2i, open_sides: Array[bool], bedrock: bool) -> void :
	var rect: = Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
	var corner_pairs: = [
		[0, 3, rect.position],
		[0, 1, Vector2(rect.end.x, rect.position.y)],
		[2, 1, rect.end],
		[2, 3, Vector2(rect.position.x, rect.end.y)],
	]
	var edge_color: = Color("697068") if bedrock else Color(String(mine.get("wallEdge", mine.detail))).lightened(0.04)
	var fill_color: = Color("2b302a") if bedrock else Color(String(mine.wall)).lerp(edge_color, 0.3)
	for pair_value in corner_pairs:
		var pair: Array = Array(pair_value)
		if not bool(open_sides[int(pair[0])]) or not bool(open_sides[int(pair[1])]):
			continue
		var corner: Vector2 = Vector2(pair[2])
		var radius: = 14.0 if bedrock else 9.2
		var shadow_points: = PackedVector2Array()
		var stone_points: = PackedVector2Array()
		for point_index in 8:
			var angle: = float(point_index) * TAU / 8.0
			var noise: = _wall_edge_noise(cell, int(pair[0]), point_index % 5, 10 + int(pair[1]))
			var direction: = Vector2(cos(angle), sin(angle))
			shadow_points.append(corner + direction * (radius + 3.0 + noise * 2.5))
			stone_points.append(corner + direction * (radius * (0.78 + noise * 0.22)))
		draw_colored_polygon(shadow_points, Color(0.006, 0.007, 0.006, 0.76))
		draw_colored_polygon(stone_points, Color(fill_color, 0.99))
		if not bedrock:
			draw_line(stone_points[1], stone_points[3], Color(edge_color, 0.28), 1.0, true)
			draw_line(stone_points[4], stone_points[6], Color(fill_color.darkened(0.38), 0.42), 1.2, true)


func _draw_target() -> void :
	if current_target.x < 0 or not blocks.has(current_target):
		return
	var block: Dictionary = Dictionary(blocks[current_target])
	var rect: = Rect2(Vector2(current_target) * TILE_SIZE, Vector2.ONE * TILE_SIZE).grow(-4)
	var pulse: = 0.86
	var color: = Color("9ba39a") if String(block.kind) == "bedrock" else Color(String(GameData.data.ROCK_TYPES.get(String(block.kind), {"edge": mine.detail}).edge))
	draw_rect(rect, Color(color, 0.07 + pulse * 0.03), true)
	var corner: = 10.0
	var width: = 2.2
	draw_line(rect.position, rect.position + Vector2(corner, 0), Color(color, pulse), width)
	draw_line(rect.position, rect.position + Vector2(0, corner), Color(color, pulse), width)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - corner, rect.position.y), Color(color, pulse), width)
	draw_line(Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + corner), Color(color, pulse), width)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x + corner, rect.end.y), Color(color, pulse), width)
	draw_line(Vector2(rect.position.x, rect.end.y), Vector2(rect.position.x, rect.end.y - corner), Color(color, pulse), width)
	draw_line(rect.end, rect.end - Vector2(corner, 0), Color(color, pulse), width)
	draw_line(rect.end, rect.end - Vector2(0, corner), Color(color, pulse), width)
	var contact: = _target_contact_point(current_target)
	draw_circle(contact, 4.0 + pulse * 1.5, Color(color, 0.22))
	draw_circle(contact, 2.0, Color(color, 0.95))
	var label: = _target_label(block)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(-70, -9), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x + 140, 9, color)


func _target_label(block: Dictionary) -> String:
	if String(block.kind) == "bedrock":
		return "BEDROCK"
	var required: = int(block.get("requires_tool", 0))
	if required > RunState.pickaxe_level:
		return "%s REQUIRED" % String(GameData.data.PICKAXES[required].name).to_upper()
	var tool: = _current_tool()
	var hits: = 0
	var shell: = int(block.get("shell", 0))
	var hp: = int(block.hp)
	var shell_multiplier: = maxf(0.01, float(tool.get("shell_power", 0.72)))
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
	return "%s · %d HIT%s" % [String(block.kind).to_upper(), hits, "" if hits == 1 else "S"]


func _draw_entrance() -> void :
	var entrance: = Vector2(float(mine.entrance.x), float(mine.entrance.y))
	var texture_size: = Vector2(entrance_texture.get_size())
	var scale_factor: = minf(174.0 / texture_size.x, 148.0 / texture_size.y)
	var size: = texture_size * scale_factor
	draw_circle(entrance + Vector2(0, 38), 62.0, Color(0.01, 0.01, 0.01, 0.58))
	draw_texture_rect(entrance_texture, Rect2(entrance + Vector2( - size.x * 0.5, 45.0 - size.y), size), false, Color(0.84, 0.87, 0.82))
	draw_string(ThemeDB.fallback_font, entrance + Vector2(-58, 67), "RETURN TO QUARRY", HORIZONTAL_ALIGNMENT_CENTER, 128, 10, Color("e9cf8c"))


func _draw_depth_entrance() -> void :
	var texture_size: = Vector2(depth_shaft_texture.get_size())
	var scale_factor: = minf(158.0 / texture_size.x, 138.0 / texture_size.y)
	var size: = texture_size * scale_factor
	draw_circle(depth_entrance + Vector2(0, 35), 62.0, Color(0.0, 0.0, 0.0, 0.48))
	draw_texture_rect(depth_shaft_texture, Rect2(depth_entrance + Vector2( - size.x * 0.5, 40.0 - size.y), size), false)
	if mine_id in ["mossMine", "moonMine"]:
		var lamp_size: = Vector2(70, 48)
		draw_texture_rect(LAMP_TEXTURE, Rect2(depth_entrance + Vector2(29, -57) - lamp_size * 0.5, lamp_size), false, Color(1.0, 0.96, 0.82, 0.98))
	var color: = Color(String(Dictionary(GameData.data.MINE_DEPTH_PROFILES[mine_id]).detail))
	var selected: = depth_near
	if selected:
		draw_arc(depth_entrance + Vector2(0, 5), 77.0, 0.0, TAU, 48, Color(color, 0.78), 2.0)
	draw_string(ThemeDB.fallback_font, depth_entrance + Vector2(-74, 67), "DESCEND TO DEPTH 2", HORIZONTAL_ALIGNMENT_CENTER, 148, 10, color)


func _draw_drop(drop: Dictionary) -> void :
	if bool(drop.get("visual_suppressed", false)):
		return
	var kind: = String(drop.kind)
	var texture: Texture2D = _drop_texture(kind)
	var pulse: = 1.0 + sin(float(drop.age) * 6.0) * 0.06
	var position: = CrusherLootBurstScript.draw_position(drop)
	var alpha: = clampf((LOOSE_RESOURCE_LIFETIME - float(drop.age)) / LOOSE_RESOURCE_FADE_SECONDS, 0.0, 1.0)
	draw_texture_rect(texture, DropVisuals.draw_rect(kind, texture, position, pulse), false, Color(1, 1, 1, alpha))
	var amount: = maxi(1, int(drop.get("amount", 1)))
	if amount <= 1:
		return
	var label: = "x%d" % amount
	var font: Font = ThemeDB.fallback_font
	var font_size: = 10
	var text_size: = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size)
	var badge: = Rect2(
		position + Vector2(8.0, 7.0),
		Vector2(maxf(22.0, text_size.x + 8.0), 16.0)
	)
	draw_rect(badge, Color(0.018, 0.024, 0.021, alpha * 0.90), true)
	draw_rect(badge, Color(0.94, 0.77, 0.36, alpha * 0.72), false, 1.0)
	draw_string(
		font,
		badge.position + Vector2(4.0, 12.0),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		badge.size.x - 8.0,
		font_size,
		Color(1.0, 0.93, 0.72, alpha)
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


func _build_lighting() -> void :
	_ensure_headlamp_initialized()
	_rebuild_work_lamps()


func _ensure_headlamp_initialized() -> void :
	var legacy_lights: = player.find_children("", "PointLight2D", false, false)
	for legacy_light in legacy_lights:
		legacy_light.queue_free()
	var headlamp: = player.get_node_or_null("PremiumHeadlamp")
	if headlamp == null:
		headlamp = HeadlampBeamScript.new()
		headlamp.name = "PremiumHeadlamp"
		headlamp.position = Vector2(0, -48)
		player.add_child(headlamp)
	headlamp.configure(Color("ffd58a"), Vector2(player.facing_vector), 0.0, 600.0)
	if player.camera.has_method("set_cave_headlamp_framing"):
		player.camera.set_cave_headlamp_framing(true, Vector2(player.facing_vector))


func _rebuild_work_lamps() -> void :
	var darkness_colors: = {
		"mossMine": Color(0.49, 0.52, 0.46, 1), "moonMine": Color(0.42, 0.49, 0.54, 1), 
		"emberMine": Color(0.52, 0.43, 0.38, 1), "starMine": Color(0.4, 0.41, 0.53, 1)
	}
	darkness.color = darkness_colors.get(mine_id, Color(0.49, 0.52, 0.46, 1))
	_rebuild_work_light_anchors()
	last_light_refresh_position = Vector2(INF, INF)
	_refresh_visible_work_lights(true)


func _rebuild_work_light_anchors() -> void :
	work_light_anchors.clear()
	var accent: = Color(String(mine.detail))
	var route_positions: Array = {
		"mossMine": [Vector2(455, 420), Vector2(930, 410), Vector2(1450, 300)], 
		"moonMine": [Vector2(330, 1000), Vector2(790, 720), Vector2(1320, 430)], 
		"emberMine": [Vector2(335, 890), Vector2(900, 650), Vector2(1510, 410)], 
		"starMine": [Vector2(360, 680), Vector2(1260, 650), Vector2(1950, 420)]
	}.get(mine_id, [])
	for index in route_positions.size():
		work_light_anchors.append({
			"id": "route:%d" % index, 
			"kind": "route", 
			"position": Vector2(route_positions[index]), 
			"radius": 220.0, 
			"energy": 0.92, 
			"color": Color("ffc56c"), 
			"with_lamp": true, 
		})
	if RunState.is_depth_entrance_discovered(mine_id):
		work_light_anchors.append({
			"id": "depth_entrance", 
			"kind": "depth", 
			"position": depth_entrance + Vector2(29, -57), 
			"radius": 245.0, 
			"energy": 1.08, 
			"color": accent, 
			"with_lamp": mine_id in ["mossMine", "moonMine"], 
		})
	for cavern_id_value in cavern_by_id:
		var cavern_id: = String(cavern_id_value)
		if not RunState.is_cavern_discovered(cavern_id):
			continue
		var cavern: Dictionary = Dictionary(cavern_by_id[cavern_id])
		work_light_anchors.append({
			"id": "cavern:%s" % cavern_id, 
			"kind": "cavern", 
			"position": Vector2(float(cavern.x), float(cavern.y)), 
			"radius": 188.0, 
			"energy": 0.56, 
			"color": accent, 
			"with_lamp": false, 
		})


func _refresh_visible_work_lights(force: bool = false) -> void :
	if not force and player.global_position.distance_to(last_light_refresh_position) < WORK_LIGHT_REFRESH_DISTANCE:
		return
	last_light_refresh_position = player.global_position
	var candidates: Array[Dictionary] = []
	for anchor in work_light_anchors:
		if player.global_position.distance_to(Vector2(anchor.position)) <= WORK_LIGHT_CULL_RADIUS:
			candidates.append(Dictionary(anchor))
	var selected: Array[Dictionary] = []
	while not candidates.is_empty() and selected.size() < MAX_VISIBLE_WORK_LIGHTS:
		var closest_index: = 0
		var closest_distance: = INF
		for index in candidates.size():
			var distance: = player.global_position.distance_squared_to(Vector2(candidates[index].position))
			if distance < closest_distance:
				closest_distance = distance
				closest_index = index
		selected.append(Dictionary(candidates.pop_at(closest_index)))
	var selected_ids: Array[String] = []
	for anchor_value in selected:
		selected_ids.append(String(Dictionary(anchor_value).id))
	if not force and selected_ids == active_work_light_ids:
		return
	active_work_light_ids = selected_ids
	for lamp in work_lamps:
		if is_instance_valid(lamp):
			if lamp.get_parent() == self:
				remove_child(lamp)
			lamp.queue_free()
	work_lamps.clear()
	for anchor_value in selected:
		var anchor: Dictionary = anchor_value
		var lamp: = Node2D.new()
		lamp.name = "WorkLight_%s" % String(anchor.id).replace(":", "_")
		lamp.set_meta("light_anchor_id", String(anchor.id))
		lamp.position = Vector2(anchor.position)
		lamp.z_index = 8
		if bool(anchor.with_lamp):
			var sprite: = Sprite2D.new()
			sprite.texture = LAMP_TEXTURE
			sprite.scale = Vector2.ONE * 0.16
			lamp.add_child(sprite)
		_add_light(
			lamp, 
			Vector2.ZERO, 
			float(anchor.radius), 
			float(anchor.energy), 
			Color(anchor.color)
		)
		add_child(lamp)
		work_lamps.append(lamp)


func _add_light(parent: Node, offset: Vector2, radius: float, energy: float, color: Color) -> void :
	var light: = PointLight2D.new()
	light.texture = _shared_work_light_texture()
	light.texture_scale = radius / 256.0
	light.energy = energy
	light.color = color
	light.position = offset
	parent.add_child(light)


func _shared_work_light_texture() -> Texture2D:
	if shared_work_light_texture != null:
		return shared_work_light_texture
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
	shared_work_light_texture = texture
	return shared_work_light_texture


func _texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	assert (ResourceLoader.exists(path), "Missing production texture: %s" % path)
	var texture: = ResourceLoader.load(path) as Texture2D
	texture_cache[path] = texture
	return texture


func _resource_texture(kind: String) -> Texture2D:
	return _texture(String(RESOURCE_ASSETS.get(kind, RESOURCE_ASSETS.stone)))


func _resource_node_texture(kind: String) -> Texture2D:
	return _texture(String(RESOURCE_NODE_ASSETS.get(kind, RESOURCE_NODE_ASSETS.stone)))


func _drop_texture(kind: String) -> Texture2D:
	var path: = "res://assets/drops/%s-drop.png" % kind
	if not ResourceLoader.exists(path):
		path = "res://assets/drops/stone-drop.png"
	return _texture(path)


func depth_one_content_snapshot() -> Dictionary:
	var rewards: Array[Dictionary] = []
	var metadata_rocks: = 0
	for block_value in blocks.values():
		if not String(Dictionary(block_value).get("pocket_reward_id", "")).is_empty():
			metadata_rocks += 1
	for cavern_id_value in cavern_by_id:
		var cavern_id: = String(cavern_id_value)
		var cavern: Dictionary = Dictionary(cavern_by_id[cavern_id])
		var reward: Dictionary = Dictionary(cavern.reward)
		var reward_id: = String(reward.id)
		var cells: Array = Array(pocket_reward_cells.get(reward_id, []))
		var live_cells: = 0
		for cell_value in cells:
			var cell: = Vector2i(cell_value)
			if blocks.has(cell) and String(Dictionary(blocks[cell]).get("pocket_reward_id", "")) == reward_id:
				live_cells += 1
		rewards.append({
			"cavern_id": cavern_id, 
			"reward_id": reward_id, 
			"kind": String(reward.kind), 
			"center": Vector2(float(cavern.x), float(cavern.y)), 
			"radii": Vector2(float(cavern.rx), float(cavern.ry)), 
			"boundary_cells": _cavern_boundary_count(cavern_id), 
			"deposit_cells": cells.size(), 
			"live_deposit_cells": live_cells, 
			"discovered": RunState.is_cavern_discovered(cavern_id), 
			"claimed": _pocket_reward_is_claimed(reward_id), 
		})
	return {
		"mine_id": mine_id, 
		"reward_count": rewards.size(), 
		"rewards": rewards, 
		"metadata_rock_count": metadata_rocks, 
		"route_label_count": Array(mine.get("labels", [])).size(), 
		"asset_contract": {
			"pocket": String(mine_assets.pocket), 
			"cache": String(mine_assets.cache), 
			"shrine": String(mine_assets.shrine), 
			"route_marker": String(mine_assets.get("route_marker", "")), 
		}, 
	}


func _cavern_boundary_count(cavern_id: String) -> int:
	var count: = 0
	for value in cavern_boundary_by_index.values():
		if String(value) == cavern_id:
			count += 1
	return count


func lighting_snapshot() -> Dictionary:
	var visible_ids: Array[String] = []
	var visible_positions: Array[Vector2] = []
	for lamp in work_lamps:
		if not is_instance_valid(lamp):
			continue
		visible_ids.append(String(lamp.get_meta("light_anchor_id", "")))
		visible_positions.append(Vector2(lamp.position))
	var headlamp: = player.get_node_or_null("PremiumHeadlamp")
	return {
		"anchor_count": work_light_anchors.size(), 
		"visible_count": visible_positions.size(), 
		"visible_ids": visible_ids, 
		"visible_positions": visible_positions, 
		"max_visible": MAX_VISIBLE_WORK_LIGHTS, 
		"cull_radius": WORK_LIGHT_CULL_RADIUS, 
		"refresh_distance": WORK_LIGHT_REFRESH_DISTANCE, 
		"player_position": player.global_position, 
		"headlamp": headlamp.debug_snapshot() if headlamp != null and headlamp.has_method("debug_snapshot") else {}, 
		"camera": player.camera.headlamp_framing_snapshot() if player.camera.has_method("headlamp_framing_snapshot") else {}, 
	}


func smoke_snapshot() -> Dictionary:
	return {
		"mine_id": mine_id, 
		"initialized": interior_initialized, 
		"build_count": interior_build_count, 
		"configured_world_seed": configured_world_seed, 
		"world_size": world_size, 
		"blocks": blocks.size(), 
		"entry": _entry_spawn(), 
		"outer_barrier": blocks.get(Vector2i(13, 12), {}), 
		"iron_barrier": blocks.get(Vector2i(26, 12), {}), 
		"outer_barrier_rocks": int(role_block_counts.get("outer_rubble", 0)), 
		"iron_barrier_rocks": int(role_block_counts.get("iron_seam", 0))
	}
