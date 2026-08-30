class_name EndlessDescentWorld
extends Node2D

signal context_changed(context: String)
signal message_changed(message: String)
signal depth_changed(depth: int)
signal depth_change_requested(target_depth: int, arrival: String)
signal hub_exit_requested
signal resource_collected(kind: String, amount: int, depth: int)
signal resource_mined(kind: String, amount: int)
signal discovery_found(site_id: String, title: String, depth: int)
signal site_activity_started(site_id: String, choice: String, depth: int)
signal site_cache_recovered(site_id: String, choice: String, kind: String, amount: int, depth: int)
signal resonance_surge_triggered(hazard_id: String, depth: int)
signal relic_discovered(relic_id: String, depth: int)
signal relic_attached(relic_id: String, depth: int)
signal relic_hauled_to_hub(relic_id: String, discovery_depth: int)
signal rope_state_changed(attached: bool, relic_id: String)

const HeadlampBeamScript = preload("res://scripts/lighting/headlamp_beam.gd")

const RESOURCE_TEXTURE_PATHS := {
	"lumenstone": "res://assets/endless/node-lumen-shard-v1.png",
	"deep_alloy": "res://assets/endless/node-deep-alloy-v1.png",
	"memory_silk": "res://assets/endless/node-memory-silk-v1.png",
	"echo_crystal": "res://assets/endless/node-echo-crystal-v1.png",
	"waystone": "res://assets/endless/node-waystone-v1.png",
}
const RELIC_TEXTURE_PATHS := {
	"forge_heart": "res://assets/endless/relic-forge-heart-v1.png",
	"ancient_lens": "res://assets/endless/relic-ancient-lens-v1.png",
	"memory_loom": "res://assets/endless/relic-memory-loom-v1.png",
	"echo_coffer": "res://assets/endless/relic-echo-coffer-v1.png",
	"wayfinder_core": "res://assets/endless/relic-wayfinder-core-v1.png",
}
const SITE_TEXTURE_PATHS := {
	"survey": "res://assets/endless/ruin-survey-camp-v1.png",
	"archive": "res://assets/endless/ruin-archive-v1.png",
	"machine": "res://assets/endless/ruin-silent-machine-v1.png",
	"shrine": "res://assets/endless/ruin-mineral-shrine-v1.png",
}
const STRATUM_FLOOR_TEXTURE_PATHS := [
	"res://assets/rootwound/floor.png",
	"res://assets/moonglass/floor.png",
	"res://assets/emberdeep/floor.png",
	"res://assets/voidstar/floor.png",
	"res://assets/mossvein/cave-floor.png",
]
const STRATUM_WALL_TEXTURE_PATHS := [
	"res://assets/rootwound/wall.png",
	"res://assets/moonglass/wall.png",
	"res://assets/emberdeep/wall.png",
	"res://assets/voidstar/wall.png",
	"res://assets/mossvein/cave-wall.png",
]
const SHAFT_TEXTURE_PATH := "res://assets/rootwound/depth-shaft.png"

const TILE_SIZE := 64.0
const GRID_SIZE := Vector2i(40, 22)
const WORLD_SIZE := Vector2(GRID_SIZE) * TILE_SIZE
const PLAYER_RADIUS := 23.0
const PLAYER_SPAWN_OFFSET := Vector2(0.0, 62.0)
const SHAFT_CONTEXT_RADIUS := 108.0
const RESOURCE_MINING_RANGE := 122.0
const RESOURCE_DISCOVERY_RADIUS := 185.0
const SITE_DISCOVERY_RADIUS := 174.0
const RELIC_CONTEXT_RADIUS := 122.0
const RELIC_RADIUS := 27.0
const ROPE_SEGMENTS := 12
const ROPE_SEGMENT_LENGTH := 20.0
const ROPE_FIXED_STEP := 1.0 / 60.0
const ROPE_MAX_STEPS_PER_FRAME := 3
const ROPE_SOLVER_ITERATIONS := 7
const ROPE_POINT_RADIUS := 4.5
const ROPE_LINEAR_DAMPING := 0.955
const RELIC_LINEAR_DAMPING := 0.875
const REDRAW_INTERVAL := 1.0 / 30.0
const MINING_HIT_PROGRESS := 0.42
const MINING_DURATION := 0.62
const SITE_CONTEXT_RADIUS := 132.0
const SITE_PAD_OFFSET := 72.0
const SITE_RUNE_RADIUS := 34.0
const SITE_RUNE_DISTANCE := 94.0
const HAZARD_RADIUS := 112.0
const HAZARD_CYCLE := 4.6
const HAZARD_TELEGRAPH_DURATION := 1.35
const HAZARD_PULSE_DURATION := 0.5
const HAZARD_PUSH_DISTANCE := 104.0

const RESOURCE_IDS := [
	"lumenstone", "deep_alloy", "memory_silk", "echo_crystal", "waystone",
]
const RELIC_IDS := [
	"forge_heart", "ancient_lens", "memory_loom", "echo_coffer", "wayfinder_core",
]
const RELIC_DEPTHS := [1, 3, 5, 8, 12]
const RELIC_NAMES := {
	"forge_heart": "FORGE HEART",
	"ancient_lens": "ANCIENT LENS",
	"memory_loom": "MEMORY LOOM",
	"echo_coffer": "ECHO COFFER",
	"wayfinder_core": "WAYFINDER CORE",
}
const RESOURCE_COLORS := {
	"lumenstone": Color("8ff4d7"),
	"deep_alloy": Color("e5a85d"),
	"memory_silk": Color("e49bea"),
	"echo_crystal": Color("78cfff"),
	"waystone": Color("a9e56b"),
}
const STRATA := [
	{
		"name": "ROOT MEMORY",
		"floor": Color("263933"),
		"floor_alt": Color("2d4239"),
		"wall": Color("101c1a"),
		"wall_edge": Color("4d715d"),
		"accent": Color("8de0a9"),
	},
	{
		"name": "LUMEN GROTTO",
		"floor": Color("23343e"),
		"floor_alt": Color("2b3e49"),
		"wall": Color("101b24"),
		"wall_edge": Color("55798d"),
		"accent": Color("8de8ff"),
	},
	{
		"name": "OLD ALLOY",
		"floor": Color("3b352d"),
		"floor_alt": Color("463e33"),
		"wall": Color("211b17"),
		"wall_edge": Color("8c6d4b"),
		"accent": Color("ffc878"),
	},
	{
		"name": "ECHO VEIL",
		"floor": Color("302d43"),
		"floor_alt": Color("39344e"),
		"wall": Color("1a1727"),
		"wall_edge": Color("786d9c"),
		"accent": Color("c4a6ff"),
	},
	{
		"name": "WAYSTONE BED",
		"floor": Color("34372d"),
		"floor_alt": Color("3e4234"),
		"wall": Color("1a1d17"),
		"wall_edge": Color("778457"),
		"accent": Color("c5eb78"),
	},
]

@export var standalone_interaction_enabled := false

@onready var player: CharacterBody2D = $Player
@onready var darkness: CanvasModulate = $Darkness
@onready var world_lights: Node2D = $WorldLights
@onready var rope_visual: Line2D = $RopeVisual
@onready var rope_shadow: Line2D = $RopeShadow

var active := false
var active_context := ""
var external_mine_held := false
var current_depth := 0
var arrival_side := "from_above"
var generation_seed := 0
var generation_signature := ""
var stratum: Dictionary = {}
var floor_cells := PackedByteArray()
var rooms: Array[Dictionary] = []
var branch_rooms: Array[Dictionary] = []
var up_shaft_cell := Vector2i.ZERO
var down_shaft_cell := Vector2i.ZERO
var up_shaft_position := Vector2.ZERO
var down_shaft_position := Vector2.ZERO
var resources: Array[Dictionary] = []
var resource_visuals: Dictionary = {}
var discovery_sites: Array[Dictionary] = []
var discovery_visuals: Dictionary = {}
var resonance_hazards: Array[Dictionary] = []
var hazard_visuals: Dictionary = {}
var session_mined_nodes: Dictionary = {}
var session_discovered_sites: Dictionary = {}
var native_relic_id := ""
var native_relic_depth := -1
var native_relic_position := Vector2.ZERO
var native_relic_visual: Node2D
var native_relic_discovered := false

var cave_floor_texture: Texture2D
var cave_wall_texture: Texture2D
var shaft_texture: Texture2D

var rope_attached := false
var carried_relic_id := ""
var carried_relic_discovery_depth := -1
var rope_points := PackedVector2Array()
var rope_previous := PackedVector2Array()
var rope_accumulator := 0.0
var relic_visual: Node2D
var relic_rotation := 0.0
var rope_simulation_steps := 0
var rope_collision_responses := 0
var rope_constraint_peak_error := 0.0
var rope_recovery_count := 0
var last_safe_relic_position := Vector2.ZERO

var mining_active := false
var mining_elapsed := 0.0
var mining_hit := false
var mining_target_id := ""
var site_activity: Dictionary = {}
var hazard_clock := 0.0
var hazard_push_remaining := Vector2.ZERO
var hazard_surge_count := 0
var redraw_elapsed := REDRAW_INTERVAL
var last_draw_cell := Vector2i(-9999, -9999)
var initialized := false
var generation_count := 0
var generated_depth := -1


func _ready() -> void:
	player.process_physics_priority = -10
	player.moved.connect(_on_player_moved)
	player.facing_changed.connect(_on_player_facing_changed)
	rope_visual.visible = false
	rope_shadow.visible = false
	_configure_rope_lines()
	if "--qa-endless-world" in OS.get_cmdline_user_args():
		call_deferred("_run_headless_qa")


func _ensure_initialized() -> void:
	if initialized:
		return
	_restore_carried_relic_from_state()
	_generate_depth(current_depth, arrival_side)
	_build_headlamp()
	initialized = true


func set_active(enabled: bool, entering: bool = false) -> void:
	if enabled:
		_ensure_initialized()
	active = enabled
	visible = enabled
	process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	player.control_enabled = enabled
	player.camera.enabled = enabled
	external_mine_held = false
	_cancel_mining()
	if enabled:
		_build_headlamp()
		player.prepare_visual_cache()
		player.camera.make_current()
		player.camera.reset_smoothing()
		if entering:
			_place_player_for_arrival(arrival_side)
		_update_context(player.global_position)
		message_changed.emit(_depth_arrival_message())
	else:
		player.camera.offset = Vector2.ZERO
		player.release_visual_cache()
		_set_context("")


func load_depth(next_depth: int, next_arrival: String = "from_above") -> bool:
	if next_depth < 0:
		return false
	_restore_carried_relic_from_state()
	current_depth = next_depth
	arrival_side = _sanitize_arrival(next_arrival)
	if rope_attached and RunState.has_method("update_carried_relic_transport"):
		RunState.update_carried_relic_transport(current_depth)
	_generate_depth(current_depth, arrival_side)
	_build_headlamp()
	initialized = true
	depth_changed.emit(current_depth)
	message_changed.emit(_depth_arrival_message())
	return true


func set_depth(next_depth: int, next_arrival: String = "from_above") -> bool:
	return load_depth(next_depth, next_arrival)


func enter_depth(next_depth: int, next_arrival: String = "from_above") -> bool:
	return load_depth(next_depth, next_arrival)


func configured_depth() -> int:
	return current_depth


func entry_spawn() -> Vector2:
	return _spawn_for_arrival(arrival_side)


func restore_position(position: Vector2) -> void:
	player.global_position = _nearest_walkable_position(position)
	if rope_attached:
		_initialize_carried_rope(player.global_position)
	player.camera.reset_smoothing()
	_on_player_moved(player.global_position)


func set_external_movement(direction: Vector2) -> void:
	player.set_external_movement(direction)


func set_mine_held(held: bool) -> void:
	external_mine_held = held
	if not held:
		_cancel_mining()


func current_context() -> String:
	return active_context


func interact() -> bool:
	return not perform_context().is_empty()


func perform_context() -> String:
	if not active and not standalone_interaction_enabled:
		return ""
	match active_context:
		"endless_up":
			if current_depth == 0:
				_prepare_hub_exit()
			else:
				_request_depth_change(current_depth - 1, "from_below")
			return "endless_up"
		"endless_down":
			_request_depth_change(current_depth + 1, "from_above")
			return "endless_down"
	if active_context.begins_with("endless_site:"):
		var site_context := active_context
		var pieces := site_context.split(":")
		if pieces.size() == 3 and _start_site_activity(int(pieces[1]), String(pieces[2])):
			return site_context
	if active_context.begins_with("endless_relic:"):
		# Attaching refreshes context immediately, so preserve the action result
		# before `_attach_native_relic()` clears the nearby-relic context.
		var relic_context := active_context
		var relic_id := relic_context.trim_prefix("endless_relic:")
		if _attach_native_relic(relic_id):
			return relic_context
	return ""


func guide_target(kind: String = "") -> Vector2:
	if kind == "up" or rope_attached:
		return up_shaft_position
	if kind == "down":
		return down_shaft_position
	if kind == "relic" and not native_relic_id.is_empty():
		return native_relic_position
	for resource in resources:
		if bool(resource.get("mined", false)):
			continue
		if kind.is_empty() or String(resource.kind) == kind:
			return Vector2(resource.position)
	return down_shaft_position


func get_runtime_contract() -> Dictionary:
	return {
		"depth": current_depth,
		"up_position": up_shaft_position,
		"down_position": down_shaft_position,
		"context": active_context,
		"rope_attached": rope_attached,
		"carried_relic_id": carried_relic_id,
		"resource_ids": RESOURCE_IDS.duplicate(),
		"signals": [
			"depth_change_requested", "hub_exit_requested", "resource_collected",
			"discovery_found", "site_activity_started", "site_cache_recovered",
			"resonance_surge_triggered", "relic_discovered", "relic_attached", "relic_hauled_to_hub",
		],
	}


func export_runtime_state() -> Dictionary:
	return {
		"depth": current_depth,
		"arrival": arrival_side,
		"session_mined_nodes": session_mined_nodes.duplicate(true),
		"session_discovered_sites": session_discovered_sites.duplicate(true),
		"rope_attached": rope_attached,
		"carried_relic_id": carried_relic_id,
		"carried_relic_discovery_depth": carried_relic_discovery_depth,
	}


func import_runtime_state(state: Dictionary) -> void:
	session_mined_nodes = Dictionary(state.get("session_mined_nodes", {})).duplicate(true)
	session_discovered_sites = Dictionary(state.get("session_discovered_sites", {})).duplicate(true)
	carried_relic_id = String(state.get("carried_relic_id", carried_relic_id))
	carried_relic_discovery_depth = int(state.get("carried_relic_discovery_depth", carried_relic_discovery_depth))
	rope_attached = bool(state.get("rope_attached", rope_attached)) and not carried_relic_id.is_empty()
	var restored_depth := maxi(0, int(state.get("depth", current_depth)))
	generated_depth = restored_depth
	load_depth(restored_depth, String(state.get("arrival", arrival_side)))


func _process(delta: float) -> void:
	if not active:
		return
	_update_mining(delta)
	_update_discoveries()
	_update_site_activity(delta)
	_update_resonance_hazards(delta)
	redraw_elapsed += maxf(0.0, delta)
	if redraw_elapsed >= REDRAW_INTERVAL:
		redraw_elapsed = fposmod(redraw_elapsed, REDRAW_INTERVAL)
		_update_resource_pulses()
	if standalone_interaction_enabled and Input.is_action_just_pressed("interact"):
		perform_context()


func _physics_process(delta: float) -> void:
	if not active:
		return
	_apply_hazard_push(delta)
	_update_haul_camera(delta)
	if not rope_attached:
		return
	rope_accumulator += minf(maxf(0.0, delta), ROPE_FIXED_STEP * ROPE_MAX_STEPS_PER_FRAME)
	var steps := 0
	while rope_accumulator >= ROPE_FIXED_STEP and steps < ROPE_MAX_STEPS_PER_FRAME:
		_simulate_rope_step(ROPE_FIXED_STEP)
		rope_accumulator -= ROPE_FIXED_STEP
		steps += 1
	_update_rope_visual()


func _generate_depth(depth: int, next_arrival: String) -> void:
	_clear_generated_visuals()
	_cancel_site_activity()
	hazard_clock = 0.0
	hazard_push_remaining = Vector2.ZERO
	current_depth = maxi(0, depth)
	# RunState keeps compact authoritative floor depletion. These dictionaries
	# only cache the active floor, so an actually endless descent cannot grow
	# transient world memory without bound.
	if current_depth != generated_depth:
		session_mined_nodes.clear()
		session_discovered_sites.clear()
	generated_depth = current_depth
	arrival_side = _sanitize_arrival(next_arrival)
	stratum = Dictionary(STRATA[current_depth % STRATA.size()]).duplicate(true)
	_load_stratum_textures()
	generation_seed = _seed_for_depth(current_depth)
	var rng := RandomNumberGenerator.new()
	rng.seed = generation_seed
	_generate_cave_layout(rng)
	_generate_discovery_sites(rng)
	_generate_resource_nodes(rng)
	_generate_native_relic(rng)
	_generate_resonance_hazards()
	_apply_resolved_site_outcomes()
	_build_depth_lights()
	_configure_player(_spawn_for_arrival(arrival_side))
	player.set_facing(Vector2.RIGHT if down_shaft_position.x >= up_shaft_position.x else Vector2.LEFT)
	if rope_attached and not carried_relic_id.is_empty():
		_initialize_carried_rope(_spawn_for_arrival(arrival_side))
	else:
		_clear_rope(false)
	darkness.color = Color(0.64, 0.64, 0.70, 1.0).lerp(Color(stratum.accent), 0.045)
	generation_signature = _calculate_generation_signature()
	generation_count += 1
	last_draw_cell = Vector2i(-9999, -9999)
	redraw_elapsed = REDRAW_INTERVAL
	queue_redraw()
	_update_context(player.global_position)


func _generate_cave_layout(rng: RandomNumberGenerator) -> void:
	floor_cells = PackedByteArray()
	floor_cells.resize(GRID_SIZE.x * GRID_SIZE.y)
	floor_cells.fill(0)
	rooms.clear()
	branch_rooms.clear()
	var route: Array[Vector2i] = []
	var route_count := 7
	for index in route_count:
		var t := float(index) / float(route_count - 1)
		var col := roundi(lerpf(4.0, float(GRID_SIZE.x - 5), t))
		var row := rng.randi_range(5, GRID_SIZE.y - 6)
		if index > 0:
			row = clampi(row, route[index - 1].y - 5, route[index - 1].y + 5)
		route.append(Vector2i(col, row))
	if current_depth % 2 == 1:
		route.reverse()
	for index in route.size():
		var radius := rng.randi_range(3, 4) if index == 0 or index == route.size() - 1 else 3
		_carve_circle(route[index], radius)
		rooms.append({"cell": route[index], "radius": radius, "main": true})
		if index > 0:
			_carve_corridor(route[index - 1], route[index], rng.randf() < 0.5, 2)
	up_shaft_cell = route[0]
	down_shaft_cell = route[route.size() - 1]
	up_shaft_position = _cell_center(up_shaft_cell)
	down_shaft_position = _cell_center(down_shaft_cell)
	var branch_indices := [1, 2, 4, 5]
	for branch_number in branch_indices.size():
		var route_index: int = branch_indices[branch_number]
		var origin: Vector2i = route[route_index]
		var direction := -1 if (branch_number + current_depth) % 2 == 0 else 1
		var target_row := clampi(origin.y + direction * rng.randi_range(5, 7), 3, GRID_SIZE.y - 4)
		if absi(target_row - origin.y) < 4:
			target_row = clampi(origin.y - direction * 5, 3, GRID_SIZE.y - 4)
		var target_col := clampi(origin.x + rng.randi_range(-2, 2), 3, GRID_SIZE.x - 4)
		var target := Vector2i(target_col, target_row)
		_carve_corridor(origin, target, rng.randf() < 0.5, 2)
		_carve_circle(target, 3)
		var room := {"cell": target, "radius": 3, "main": false, "branch": branch_number}
		branch_rooms.append(room)
		rooms.append(room)
	# The aperture and its first rope-length of floor are always generous.
	_carve_circle(up_shaft_cell, 4)
	_carve_circle(down_shaft_cell, 4)


func _carve_circle(center: Vector2i, radius: int) -> void:
	for row in range(center.y - radius, center.y + radius + 1):
		for col in range(center.x - radius, center.x + radius + 1):
			var cell := Vector2i(col, row)
			if not _cell_in_bounds(cell, 1):
				continue
			if Vector2(cell - center).length() <= float(radius) + 0.35:
				_set_floor(cell, true)


func _carve_corridor(from: Vector2i, to: Vector2i, horizontal_first: bool, half_width: int) -> void:
	var corner := Vector2i(to.x, from.y) if horizontal_first else Vector2i(from.x, to.y)
	_carve_line(from, corner, half_width)
	_carve_line(corner, to, half_width)


func _carve_line(from: Vector2i, to: Vector2i, half_width: int) -> void:
	var cursor := from
	var guard := 0
	while cursor != to and guard < GRID_SIZE.x + GRID_SIZE.y + 8:
		_carve_circle(cursor, half_width)
		if cursor.x != to.x:
			cursor.x += signi(to.x - cursor.x)
		elif cursor.y != to.y:
			cursor.y += signi(to.y - cursor.y)
		guard += 1
	_carve_circle(to, half_width)


func _generate_discovery_sites(rng: RandomNumberGenerator) -> void:
	discovery_sites.clear()
	if current_depth == 0:
		return
	var site_titles := [
		"ABANDONED SURVEY", "ROOT ARCHIVE", "SILENT MACHINE",
		"MINERAL GARDEN", "LOST CAMP", "ANCIENT LIFTWORKS",
		"STONE CHOIR", "CARTOGRAPHER'S REST", "FOSSIL HOLLOW",
	]
	var count := mini(branch_rooms.size(), 2 + current_depth % 3)
	for index in count:
		var room: Dictionary = branch_rooms[index]
		var cell := Vector2i(room.cell)
		var site_id := "endless_d%06d_site_%02d" % [current_depth, index]
		var title: String = site_titles[(rng.randi() + current_depth + index) % site_titles.size()]
		var position := _cell_center(cell) + Vector2(rng.randf_range(-34.0, 34.0), rng.randf_range(-30.0, 30.0))
		var persisted: Dictionary = {}
		if RunState.has_method("endless_floor_site_state"):
			persisted = Dictionary(RunState.endless_floor_site_state(current_depth, index))
		var variant := (current_depth + index) % 4
		var site := {
			"id": site_id,
			"index": index,
			"title": title,
			"position": position,
			"discovered": (
				bool(session_discovered_sites.get(site_id, false))
				or bool(persisted.get("resolved", false))
			),
			"resolved": bool(persisted.get("resolved", false)),
			"choice": String(persisted.get("choice", "")),
			"variant": variant,
			"reward_kind": _site_reward_kind(index, variant),
			"base_reward": clampi(34 + current_depth * 3 + variant * 3, 34, 96),
			"rune_positions": _site_rune_positions(position, index),
		}
		discovery_sites.append(site)
		_build_site_visual(site)


func _generate_resource_nodes(rng: RandomNumberGenerator) -> void:
	resources.clear()
	if current_depth == 0:
		return
	var floor_state: Dictionary = {}
	if RunState.has_method("endless_floor_resource_state"):
		floor_state = Dictionary(RunState.endless_floor_resource_state(current_depth))
	if bool(floor_state.get("exhausted", false)):
		return
	var persisted_mined_mask: = maxi(0, int(floor_state.get("mined_mask", 0)))
	var occupied: Dictionary = {
		_cell_key(up_shaft_cell): true,
		_cell_key(down_shaft_cell): true,
	}
	for site in discovery_sites:
		occupied[_cell_key(_world_to_cell(Vector2(site.position)))] = true
	var target_count := 11 + mini(6, current_depth / 4)
	var available_count := clampi(2 + current_depth / 3, 2, RESOURCE_IDS.size())
	var candidates: Array[Vector2i] = []
	for room in rooms:
		var center := Vector2i(room.cell)
		var radius := int(room.radius)
		for row_offset in range(-radius + 1, radius):
			for col_offset in range(-radius + 1, radius):
				var cell := center + Vector2i(col_offset, row_offset)
				if not _is_floor(cell) or occupied.has(_cell_key(cell)):
					continue
				if cell.distance_to(up_shaft_cell) < 3.2 or cell.distance_to(down_shaft_cell) < 3.2:
					continue
				candidates.append(cell)
	_shuffle_cells(candidates, rng)
	for index in mini(target_count, candidates.size()):
		var cell: Vector2i = candidates[index]
		occupied[_cell_key(cell)] = true
		var kind_index := (index + rng.randi_range(0, available_count - 1) + current_depth) % available_count
		var kind: String = RESOURCE_IDS[kind_index]
		var node_id := "endless_d%06d_node_%03d" % [current_depth, index]
		var mined := (
			bool(session_mined_nodes.get(node_id, false))
			or (persisted_mined_mask & (1 << index)) != 0
		)
		var amount := clampi(12 + current_depth / 2 + rng.randi_range(0, 6), 12, 28)
		var hardness := 430 + ((index + current_depth) % 4) * 24
		var resource := {
			"id": node_id,
			"node_index": index,
			"kind": kind,
			"cell": cell,
			"position": _cell_center(cell),
			"amount": amount,
			"hp": hardness,
			"max_hp": hardness,
			"mined": mined,
			"revealed": false,
			"phase": float((index * 37 + current_depth * 11) % 100) * 0.061,
		}
		resources.append(resource)
		if not mined:
			_build_resource_visual(resource)


func _generate_native_relic(rng: RandomNumberGenerator) -> void:
	native_relic_id = _relic_for_depth(current_depth)
	native_relic_depth = current_depth if not native_relic_id.is_empty() else -1
	native_relic_position = Vector2.ZERO
	native_relic_discovered = false
	if native_relic_id.is_empty() or _relic_already_claimed(native_relic_id):
		native_relic_id = ""
		return
	if branch_rooms.is_empty():
		return
	var room: Dictionary = branch_rooms[branch_rooms.size() - 1]
	var direction := Vector2(-1.0, 0.0) if int(room.cell.x) > GRID_SIZE.x / 2 else Vector2.RIGHT
	native_relic_position = _cell_center(Vector2i(room.cell)) + direction * rng.randf_range(28.0, 52.0)
	native_relic_position = _nearest_walkable_position(native_relic_position, RELIC_RADIUS)
	native_relic_visual = _build_relic_visual(native_relic_id, native_relic_position, false)


func _relic_for_depth(depth: int) -> String:
	for index in RELIC_DEPTHS.size():
		if depth == int(RELIC_DEPTHS[index]):
			return String(RELIC_IDS[index])
	return ""


func _seed_for_depth(depth: int) -> int:
	var world_seed := int(RunState.get("world_seed"))
	var mixed := (world_seed * 73856093) ^ ((depth + 1) * 19349663) ^ 0x5F3759DF
	return absi(mixed) & 0x7fffffff


func _shuffle_cells(values: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := values[index]
		values[index] = values[swap_index]
		values[swap_index] = held


func _calculate_generation_signature() -> String:
	var value := 146959810
	for index in floor_cells.size():
		if floor_cells[index] == 0:
			continue
		value = int((value * 16777619 + index * 31 + 1) % 2147483629)
	for resource in resources:
		var cell := Vector2i(resource.cell)
		value = int((value * 131 + cell.x * 17 + cell.y * 29 + RESOURCE_IDS.find(String(resource.kind)) + 7) % 2147483629)
	for site in discovery_sites:
		var cell := _world_to_cell(Vector2(site.position))
		value = int((
			value * 137
			+ cell.x * 19
			+ cell.y * 23
			+ int(site.variant)
			+ RESOURCE_IDS.find(String(site.get("reward_kind", ""))) * 7
			+ int(site.get("base_reward", 0))
		) % 2147483629)
	for hazard in resonance_hazards:
		var cell := _world_to_cell(Vector2(hazard.position))
		value = int((
			value * 149
			+ cell.x * 31
			+ cell.y * 37
			+ roundi(float(hazard.phase_offset) * 1000.0)
		) % 2147483629)
	value = int((value * 139 + RELIC_IDS.find(native_relic_id) + 13) % 2147483629)
	return "%08x" % value


func _clear_generated_visuals() -> void:
	for visual_value in resource_visuals.values():
		var visual := visual_value as Node
		if is_instance_valid(visual):
			visual.queue_free()
	resource_visuals.clear()
	for visual_value in discovery_visuals.values():
		var visual := visual_value as Node
		if is_instance_valid(visual):
			visual.queue_free()
	discovery_visuals.clear()
	for visual_value in hazard_visuals.values():
		var visual := visual_value as Node
		if is_instance_valid(visual):
			visual.queue_free()
	hazard_visuals.clear()
	resonance_hazards.clear()
	if is_instance_valid(native_relic_visual):
		native_relic_visual.queue_free()
	native_relic_visual = null
	if is_instance_valid(relic_visual):
		relic_visual.queue_free()
	relic_visual = null
	for child in world_lights.get_children():
		child.queue_free()


func _build_resource_visual(resource: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "Resource_%s" % String(resource.id)
	root.position = Vector2(resource.position)
	root.z_index = 4
	var kind := String(resource.kind)
	var sprite := Sprite2D.new()
	sprite.name = "PremiumNode"
	sprite.texture = _load_texture(String(RESOURCE_TEXTURE_PATHS.get(kind, "")))
	sprite.position = Vector2(0.0, -3.0)
	_fit_sprite(sprite, Vector2(96.0, 96.0))
	root.add_child(sprite)
	add_child(root)
	resource_visuals[String(resource.id)] = root


func _build_site_visual(site: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "Discovery_%s" % String(site.id)
	root.position = Vector2(site.position)
	root.z_index = 2
	var sprite := Sprite2D.new()
	sprite.name = "PremiumRuin"
	sprite.texture = _load_texture(_site_texture_path(String(site.title)))
	sprite.position = Vector2(0.0, -8.0)
	_fit_sprite(sprite, Vector2(196.0, 122.0))
	root.add_child(sprite)
	var choice_pads := Node2D.new()
	choice_pads.name = "ChoicePads"
	_add_site_pad(choice_pads, "StabilizePad", Vector2(-SITE_PAD_OFFSET, 36.0), Color("7be6d0"))
	_add_site_pad(choice_pads, "OverloadPad", Vector2(SITE_PAD_OFFSET, 36.0), Color("ffad5b"))
	choice_pads.visible = not bool(site.get("resolved", false))
	root.add_child(choice_pads)
	var runes := Node2D.new()
	runes.name = "RuneSequence"
	runes.visible = false
	var rune_positions: Array = Array(site.get("rune_positions", []))
	for rune_index in rune_positions.size():
		var rune := Node2D.new()
		rune.name = "Rune_%d" % rune_index
		rune.position = Vector2(rune_positions[rune_index]) - Vector2(site.position)
		var fill := Polygon2D.new()
		fill.name = "Fill"
		fill.polygon = _circle_points(SITE_RUNE_RADIUS - 8.0, 24)
		fill.color = Color(0.2, 0.8, 0.72, 0.08)
		rune.add_child(fill)
		var ring := Line2D.new()
		ring.name = "Ring"
		ring.closed = true
		ring.points = _circle_points(SITE_RUNE_RADIUS, 28)
		ring.width = 4.0
		ring.default_color = Color(0.45, 0.92, 0.84, 0.24)
		ring.antialiased = true
		rune.add_child(ring)
		runes.add_child(rune)
	root.add_child(runes)
	if bool(site.discovered) or bool(site.get("resolved", false)):
		root.modulate = Color(1.08, 1.08, 1.08, 1.0)
	if bool(site.get("resolved", false)):
		root.modulate = Color(0.76, 0.82, 0.8, 0.72)
	add_child(root)
	discovery_visuals[String(site.id)] = root


func _add_site_pad(parent: Node2D, name_value: String, position: Vector2, color: Color) -> void:
	var pad := Node2D.new()
	pad.name = name_value
	pad.position = position
	var fill := Polygon2D.new()
	fill.polygon = _circle_points(27.0, 24)
	fill.color = Color(color, 0.09)
	pad.add_child(fill)
	var ring := Line2D.new()
	ring.closed = true
	ring.points = _circle_points(31.0, 28)
	ring.width = 4.0
	ring.default_color = Color(color, 0.72)
	ring.antialiased = true
	pad.add_child(ring)
	parent.add_child(pad)


func _circle_points(radius: float, count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in maxi(8, count):
		points.append(Vector2.RIGHT.rotated(TAU * float(index) / float(maxi(8, count))) * radius)
	return points


func _site_reward_kind(site_index: int, variant: int) -> String:
	var available_count := clampi(2 + current_depth / 3, 2, RESOURCE_IDS.size())
	return String(RESOURCE_IDS[(current_depth + site_index + variant * 2) % available_count])


func _site_rune_positions(site_position: Vector2, site_index: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var quarter_turn := float((generation_seed + site_index * 17) & 3) * PI * 0.5
	for rune_index in 4:
		var direction := Vector2.RIGHT.rotated(quarter_turn + float(rune_index) * PI * 0.5)
		result.append(_nearest_walkable_position(site_position + direction * SITE_RUNE_DISTANCE))
	return result


func _build_relic_visual(relic_id: String, position: Vector2, carried: bool) -> Node2D:
	var root := Node2D.new()
	root.name = "CarriedRelic" if carried else "Relic_%s" % relic_id
	root.position = position
	root.z_index = 7 if carried else 5
	root.set_meta("rope_offset", _relic_rope_offset(relic_id))
	var sprite := Sprite2D.new()
	sprite.name = "PremiumRelic"
	sprite.texture = _load_texture(String(RELIC_TEXTURE_PATHS.get(relic_id, "")))
	sprite.position = Vector2(0.0, -4.0)
	_fit_sprite(sprite, Vector2.ONE * (108.0 if carried else 120.0))
	root.add_child(sprite)
	if carried:
		var carried_light := PointLight2D.new()
		carried_light.name = "CarriedRelicLight"
		carried_light.position = Vector2(0.0, -8.0)
		carried_light.color = _relic_color(relic_id)
		carried_light.energy = 0.48
		carried_light.texture = _make_radial_texture()
		carried_light.texture_scale = 178.0 / 256.0
		root.add_child(carried_light)
	add_child(root)
	return root


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _fit_sprite(sprite: Sprite2D, target_size: Vector2) -> void:
	if sprite.texture == null:
		return
	var texture_size := sprite.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var factor := minf(target_size.x / texture_size.x, target_size.y / texture_size.y)
	sprite.scale = Vector2.ONE * factor


func _site_texture_path(title: String) -> String:
	var lowered := title.to_lower()
	if "archive" in lowered or "fossil" in lowered or "root" in lowered:
		return String(SITE_TEXTURE_PATHS.archive)
	if "machine" in lowered or "lift" in lowered:
		return String(SITE_TEXTURE_PATHS.machine)
	if "garden" in lowered or "choir" in lowered:
		return String(SITE_TEXTURE_PATHS.shrine)
	return String(SITE_TEXTURE_PATHS.survey)


func _relic_rope_offset(relic_id: String) -> Vector2:
	match relic_id:
		"forge_heart": return Vector2(15.0, -45.0)
		"ancient_lens": return Vector2(15.0, -46.0)
		"memory_loom": return Vector2(4.0, -43.0)
		"echo_coffer": return Vector2(-8.0, -42.0)
		_: return Vector2(17.0, -46.0)


func _relic_color(relic_id: String) -> Color:
	match relic_id:
		"forge_heart": return Color("ff8b52")
		"ancient_lens": return Color("83e9ff")
		"memory_loom": return Color("df9bff")
		"echo_coffer": return Color("ffd36e")
		_: return Color("acee83")


func _build_headlamp() -> void:
	var headlamp = player.get_node_or_null("PremiumHeadlamp")
	if headlamp == null:
		headlamp = HeadlampBeamScript.new()
		headlamp.name = "PremiumHeadlamp"
		headlamp.position = Vector2(0, -48)
		player.add_child(headlamp)
	# HeadlampBeam owns the workshop multipliers. Pass only the authored base
	# length here so Light Lab range is applied exactly once.
	headlamp.configure(Color("ffe2a1"), Vector2(player.facing_vector), 0.0, 660.0)
	if player.camera.has_method("set_cave_headlamp_framing"):
		var camera_direction := Vector2(player.facing_vector)
		if rope_attached:
			camera_direction.y = 0.0
		player.camera.set_cave_headlamp_framing(true, camera_direction)


func _build_depth_lights() -> void:
	var radial := _make_radial_texture()
	for specification in [
		{"position": up_shaft_position, "color": Color("92d9ff"), "energy": 0.58},
		{"position": down_shaft_position, "color": Color(stratum.accent), "energy": 0.5},
	]:
		var light := PointLight2D.new()
		light.position = Vector2(specification.position)
		light.color = Color(specification.color)
		light.energy = float(specification.energy)
		light.texture = radial
		light.texture_scale = 260.0 / 256.0
		world_lights.add_child(light)
	if not native_relic_id.is_empty():
		var relic_light := PointLight2D.new()
		relic_light.name = "NativeRelicLight"
		relic_light.position = native_relic_position
		relic_light.color = _relic_color(native_relic_id)
		relic_light.energy = 0.52
		relic_light.texture = radial
		relic_light.texture_scale = 190.0 / 256.0
		world_lights.add_child(relic_light)


func _generate_resonance_hazards() -> void:
	resonance_hazards.clear()
	if current_depth <= 0:
		return
	var candidates: Array[Dictionary] = []
	for room in rooms:
		if not bool(room.get("main", false)):
			continue
		var center := _cell_center(Vector2i(room.cell))
		if center.distance_to(up_shaft_position) < 220.0 or center.distance_to(down_shaft_position) < 220.0:
			continue
		candidates.append(room)
	if candidates.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = (generation_seed ^ 0x36d1f27b) & 0x7fffffff
	_shuffle_hazard_rooms(candidates, rng)
	var count := mini(candidates.size(), 1 + mini(1, current_depth / 6))
	for index in count:
		var room: Dictionary = candidates[index]
		var center := _cell_center(Vector2i(room.cell))
		var position := _nearest_walkable_position(
			center + Vector2(rng.randf_range(-34.0, 34.0), rng.randf_range(-28.0, 28.0))
		)
		var hazard := {
			"id": "endless_d%06d_surge_%02d" % [current_depth, index],
			"index": index,
			"position": position,
			"radius": HAZARD_RADIUS,
			"phase_offset": rng.randf_range(0.0, HAZARD_CYCLE),
			"last_pulse_cycle": -999999,
			"disabled": false,
			"empowered": false,
		}
		resonance_hazards.append(hazard)
		_build_hazard_visual(hazard)


func _shuffle_hazard_rooms(values: Array[Dictionary], rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var held := values[index]
		values[index] = values[swap_index]
		values[swap_index] = held


func _build_hazard_visual(hazard: Dictionary) -> void:
	var root := Node2D.new()
	root.name = "Resonance_%s" % String(hazard.id)
	root.position = Vector2(hazard.position)
	root.z_index = 1
	var fill := Polygon2D.new()
	fill.name = "FieldFill"
	fill.polygon = _circle_points(float(hazard.radius), 36)
	fill.color = Color("62d8d0", 0.035)
	root.add_child(fill)
	var outer := Line2D.new()
	outer.name = "OuterRing"
	outer.closed = true
	outer.points = _circle_points(float(hazard.radius), 40)
	outer.width = 3.0
	outer.default_color = Color("72e5dc", 0.34)
	outer.antialiased = true
	root.add_child(outer)
	var telegraph := Line2D.new()
	telegraph.name = "TelegraphRing"
	telegraph.closed = true
	telegraph.points = _circle_points(float(hazard.radius) * 0.72, 36)
	telegraph.width = 6.0
	telegraph.default_color = Color("ffc568", 0.0)
	telegraph.antialiased = true
	root.add_child(telegraph)
	add_child(root)
	hazard_visuals[String(hazard.id)] = root


func _update_resonance_hazards(delta: float) -> void:
	hazard_clock += maxf(0.0, delta)
	for index in resonance_hazards.size():
		var hazard: Dictionary = resonance_hazards[index]
		var visual := hazard_visuals.get(String(hazard.id)) as Node2D
		if bool(hazard.get("disabled", false)):
			if is_instance_valid(visual):
				visual.modulate = Color(0.42, 0.64, 0.62, 0.2)
			continue
		var cycle := HAZARD_CYCLE * (0.72 if bool(hazard.get("empowered", false)) else 1.0)
		var absolute_phase := hazard_clock + float(hazard.phase_offset)
		var phase := fposmod(absolute_phase, cycle)
		var telegraph_progress := clampf(
			(phase - (cycle - HAZARD_TELEGRAPH_DURATION)) / HAZARD_TELEGRAPH_DURATION,
			0.0,
			1.0
		)
		var pulsing := phase < HAZARD_PULSE_DURATION
		_update_hazard_visual(visual, telegraph_progress, pulsing, bool(hazard.get("empowered", false)))
		var pulse_cycle := floori(absolute_phase / cycle)
		if pulsing and pulse_cycle != int(hazard.get("last_pulse_cycle", -999999)):
			hazard["last_pulse_cycle"] = pulse_cycle
			if player.global_position.distance_to(Vector2(hazard.position)) <= float(hazard.radius):
				_trigger_resonance_surge(hazard)
		resonance_hazards[index] = hazard


func _update_hazard_visual(
	visual: Node2D, telegraph_progress: float, pulsing: bool, empowered: bool
) -> void:
	if not is_instance_valid(visual):
		return
	visual.modulate = Color.WHITE
	var fill := visual.get_node_or_null("FieldFill") as Polygon2D
	var outer := visual.get_node_or_null("OuterRing") as Line2D
	var telegraph := visual.get_node_or_null("TelegraphRing") as Line2D
	var danger_color := Color("ff8a52") if empowered else Color("ffc568")
	if is_instance_valid(fill):
		fill.color = Color(danger_color, 0.16 if pulsing else 0.035 + telegraph_progress * 0.08)
	if is_instance_valid(outer):
		outer.default_color = Color(danger_color, 0.82 if pulsing else 0.28 + telegraph_progress * 0.34)
	if is_instance_valid(telegraph):
		telegraph.default_color = Color(danger_color, 0.92 if pulsing else telegraph_progress * 0.82)
		telegraph.scale = Vector2.ONE * lerpf(1.35, 1.0, telegraph_progress)


func _trigger_resonance_surge(hazard: Dictionary) -> void:
	var direction := player.global_position - Vector2(hazard.position)
	if direction.length_squared() <= 0.001:
		direction = -Vector2(player.facing_vector)
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	var push := HAZARD_PUSH_DISTANCE * (1.22 if bool(hazard.get("empowered", false)) else 1.0)
	hazard_push_remaining += direction.normalized() * push
	hazard_surge_count += 1
	_cancel_mining()
	message_changed.emit("RESONANCE SURGE · move outside the glowing ring")
	resonance_surge_triggered.emit(String(hazard.id), current_depth)


func _apply_hazard_push(delta: float) -> void:
	if hazard_push_remaining.length_squared() <= 0.25:
		hazard_push_remaining = Vector2.ZERO
		return
	var step_length := minf(hazard_push_remaining.length(), 410.0 * maxf(0.0, delta))
	var step := hazard_push_remaining.normalized() * step_length
	var before := player.global_position
	player.global_position = _resolve_motion(before, step)
	var actual := player.global_position - before
	if actual.length_squared() <= 0.001:
		hazard_push_remaining = Vector2.ZERO
		return
	hazard_push_remaining -= actual
	_on_player_moved(player.global_position)


func _apply_resolved_site_outcomes() -> void:
	for site in discovery_sites:
		if not bool(site.get("resolved", false)):
			continue
		if String(site.get("choice", "stabilize")) == "overload":
			_empower_nearest_hazard(Vector2(site.position))
		else:
			_disable_nearest_hazard(Vector2(site.position))


func _disable_nearest_hazard(position: Vector2) -> void:
	var nearest := _nearest_hazard_index(position)
	if nearest < 0:
		return
	var hazard: Dictionary = resonance_hazards[nearest]
	hazard["disabled"] = true
	hazard["empowered"] = false
	resonance_hazards[nearest] = hazard


func _empower_nearest_hazard(position: Vector2) -> void:
	var nearest := _nearest_hazard_index(position)
	if nearest < 0:
		return
	var hazard: Dictionary = resonance_hazards[nearest]
	if not bool(hazard.get("disabled", false)):
		hazard["empowered"] = true
	resonance_hazards[nearest] = hazard


func _nearest_hazard_index(position: Vector2) -> int:
	var best := -1
	var best_distance := INF
	for index in resonance_hazards.size():
		var distance := position.distance_squared_to(Vector2(resonance_hazards[index].position))
		if distance < best_distance:
			best_distance = distance
			best = index
	return best


func _make_radial_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.38, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.42), Color(1, 1, 1, 0)])
	var texture := GradientTexture2D.new()
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _configure_player(position: Vector2) -> void:
	var speed := float(GameData.data.PLAYER_SPEED)
	if RunState.has_method("movement_speed_multiplier"):
		speed *= float(RunState.movement_speed_multiplier())
	player.configure(position, WORLD_SIZE, speed, _resolve_motion)


func _resolve_motion(origin: Vector2, motion: Vector2) -> Vector2:
	var result := origin
	var next_x := Vector2(origin.x + motion.x, origin.y)
	if not _circle_collides_walls(next_x, PLAYER_RADIUS):
		result.x = next_x.x
	var next_y := Vector2(result.x, origin.y + motion.y)
	if not _circle_collides_walls(next_y, PLAYER_RADIUS):
		result.y = next_y.y
	result = result.clamp(Vector2.ONE * PLAYER_RADIUS, WORLD_SIZE - Vector2.ONE * PLAYER_RADIUS)
	if rope_attached and rope_points.size() > 1:
		var anchor := result + Vector2(0, 7)
		var toward_anchor := anchor - rope_points[1]
		var limit := ROPE_SEGMENT_LENGTH * 1.18
		if toward_anchor.length() > limit:
			anchor = rope_points[1] + toward_anchor.normalized() * limit
			var limited := anchor - Vector2(0, 7)
			if not _circle_collides_walls(limited, PLAYER_RADIUS):
				result = limited
	return result


func collision_at(position: Vector2) -> bool:
	return _circle_collides_walls(position, PLAYER_RADIUS)


func _on_player_moved(world_position: Vector2) -> void:
	var cell := _world_to_cell(world_position)
	if cell != last_draw_cell:
		last_draw_cell = cell
		queue_redraw()
	_update_context(world_position)


func _on_player_facing_changed(direction: Vector2) -> void:
	var headlamp := player.get_node_or_null("PremiumHeadlamp")
	if headlamp != null and headlamp.has_method("set_direction"):
		headlamp.set_direction(direction)
	if player.camera.has_method("set_headlamp_direction"):
		var camera_direction := direction
		if rope_attached:
			camera_direction.y = 0.0
		player.camera.set_headlamp_direction(camera_direction)


func _update_haul_camera(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.camera):
		return
	var target_offset := Vector2.ZERO
	if rope_attached and not rope_points.is_empty():
		var relic_position := rope_points[rope_points.size() - 1]
		target_offset = (relic_position - player.global_position) * 0.42
		target_offset.x = clampf(target_offset.x, -105.0, 105.0)
		target_offset.y = clampf(target_offset.y, -88.0, 88.0)
		if player.camera.has_method("set_headlamp_direction"):
			player.camera.set_headlamp_direction(Vector2.ZERO)
	var response := 1.0 - exp(-7.0 * maxf(delta, 0.0))
	player.camera.offset = player.camera.offset.lerp(target_offset, response)


func _update_context(world_position: Vector2) -> void:
	var next := ""
	if world_position.distance_to(up_shaft_position) <= SHAFT_CONTEXT_RADIUS:
		next = "endless_up"
	elif world_position.distance_to(down_shaft_position) <= SHAFT_CONTEXT_RADIUS:
		next = "endless_down"
	elif not native_relic_id.is_empty() and not rope_attached and world_position.distance_to(native_relic_position) <= RELIC_CONTEXT_RADIUS:
		next = "endless_relic:%s" % native_relic_id
	elif site_activity.is_empty():
		var nearest_site := -1
		var nearest_distance := INF
		for index in discovery_sites.size():
			var site: Dictionary = discovery_sites[index]
			if bool(site.get("resolved", false)):
				continue
			var distance := world_position.distance_to(Vector2(site.position))
			if distance <= SITE_CONTEXT_RADIUS and distance < nearest_distance:
				nearest_distance = distance
				nearest_site = index
		if nearest_site >= 0:
			var site: Dictionary = discovery_sites[nearest_site]
			var local := world_position - Vector2(site.position)
			var choice := "overload" if local.x > 0.0 else "stabilize"
			next = "endless_site:%d:%s" % [int(site.get("index", nearest_site)), choice]
	_set_context(next)


func _set_context(next: String) -> void:
	if next == active_context:
		return
	active_context = next
	context_changed.emit(active_context)
	match active_context:
		"endless_up":
			message_changed.emit("HUB SHAFT · haul upward" if current_depth == 0 else "ASCENT SHAFT · depth %d" % (current_depth - 1))
		"endless_down":
			message_changed.emit("EVER DEEPER · descend to depth %d" % (current_depth + 1))
		_:
			if active_context.begins_with("endless_relic:"):
				message_changed.emit("RELIC FOUND · attach the recovery rope")
			elif active_context.begins_with("endless_site:"):
				var choice := String(active_context.get_slice(":", 2))
				message_changed.emit(
					"CALM SEAL · stabilize the cache and quiet a surge"
					if choice == "stabilize"
					else "POWER SEAL · double cache, stronger surge"
				)


func _update_discoveries() -> void:
	for index in discovery_sites.size():
		var site: Dictionary = discovery_sites[index]
		if bool(site.discovered):
			continue
		if player.global_position.distance_to(Vector2(site.position)) > SITE_DISCOVERY_RADIUS:
			continue
		site.discovered = true
		discovery_sites[index] = site
		session_discovered_sites[String(site.id)] = true
		var visual := discovery_visuals.get(String(site.id)) as Node2D
		if is_instance_valid(visual):
			visual.modulate = Color(1.12, 1.12, 1.12, 1.0)
		discovery_found.emit(String(site.id), String(site.title), current_depth)
		message_changed.emit("%s · depth %d" % [String(site.title), current_depth])
		if RunState.has_method("discover_endless_site"):
			RunState.discover_endless_site(String(site.id), current_depth)
	if not native_relic_id.is_empty() and not native_relic_discovered:
		if player.global_position.distance_to(native_relic_position) <= RESOURCE_DISCOVERY_RADIUS:
			native_relic_discovered = true
			if RunState.has_method("discover_endless_relic"):
				RunState.discover_endless_relic(native_relic_id, current_depth)
			relic_discovered.emit(native_relic_id, current_depth)
			message_changed.emit("%s DISCOVERED · bring it home" % String(RELIC_NAMES.get(native_relic_id, "RELIC")))


func _start_site_activity(site_index: int, choice: String) -> bool:
	if not site_activity.is_empty() or choice not in ["stabilize", "overload"]:
		return false
	var array_index := _site_array_index(site_index)
	if array_index < 0:
		return false
	var site: Dictionary = discovery_sites[array_index]
	if (
		bool(site.get("resolved", false))
		or player.global_position.distance_to(Vector2(site.position)) > SITE_CONTEXT_RADIUS + 14.0
	):
		return false
	site["discovered"] = true
	discovery_sites[array_index] = site
	session_discovered_sites[String(site.id)] = true
	site_activity = {
		"site_index": site_index,
		"array_index": array_index,
		"site_id": String(site.id),
		"choice": choice,
		"next_rune": 0,
		"rune_count": 4 if choice == "overload" else 3,
		"elapsed": 0.0,
	}
	_cancel_mining()
	_set_context("")
	_update_site_activity_visual()
	site_activity_started.emit(String(site.id), choice, current_depth)
	message_changed.emit(
		"POWER PATH · cross four lit seals · the cache doubles"
		if choice == "overload"
		else "CALM PATH · cross three lit seals · the surge will quiet"
	)
	return true


func _update_site_activity(delta: float) -> void:
	if site_activity.is_empty():
		return
	var array_index := int(site_activity.get("array_index", -1))
	if array_index < 0 or array_index >= discovery_sites.size():
		_cancel_site_activity()
		return
	site_activity["elapsed"] = float(site_activity.get("elapsed", 0.0)) + maxf(0.0, delta)
	_update_site_activity_visual()
	var site: Dictionary = discovery_sites[array_index]
	var rune_positions: Array = Array(site.get("rune_positions", []))
	var next_rune := int(site_activity.get("next_rune", 0))
	var rune_count := int(site_activity.get("rune_count", 0))
	if next_rune < 0 or next_rune >= mini(rune_count, rune_positions.size()):
		_complete_site_activity()
		return
	if player.global_position.distance_to(Vector2(rune_positions[next_rune])) > SITE_RUNE_RADIUS:
		return
	next_rune += 1
	site_activity["next_rune"] = next_rune
	if next_rune >= rune_count:
		_complete_site_activity()
	else:
		_update_site_activity_visual()
		message_changed.emit("RESONANCE LINKED · %d seal%s remaining" % [rune_count - next_rune, "" if rune_count - next_rune == 1 else "s"])


func _complete_site_activity() -> void:
	if site_activity.is_empty():
		return
	var activity := site_activity.duplicate(true)
	var array_index := int(activity.get("array_index", -1))
	if array_index < 0 or array_index >= discovery_sites.size():
		_cancel_site_activity()
		return
	var site: Dictionary = discovery_sites[array_index]
	var result: Dictionary = {}
	if RunState.has_method("claim_endless_site_cache"):
		result = Dictionary(RunState.claim_endless_site_cache(
			current_depth,
			int(site.get("index", array_index)),
			String(activity.get("choice", "stabilize")),
			String(site.get("reward_kind", "lumenstone")),
			int(site.get("base_reward", 34))
		))
	if not bool(result.get("ok", false)):
		_cancel_site_activity()
		message_changed.emit("THIS CACHE HAS ALREADY GONE QUIET")
		return
	var choice := String(activity.get("choice", "stabilize"))
	var kind := String(result.get("resource", site.get("reward_kind", "lumenstone")))
	var amount := int(result.get("amount", 0))
	site["resolved"] = true
	site["choice"] = choice
	site["discovered"] = true
	discovery_sites[array_index] = site
	site_activity.clear()
	if choice == "overload":
		_empower_nearest_hazard(Vector2(site.position))
	else:
		_disable_nearest_hazard(Vector2(site.position))
	_set_site_visual_resolved(site)
	_show_site_cache_reward(site, kind)
	_update_context(player.global_position)
	site_cache_recovered.emit(String(site.id), choice, kind, amount, current_depth)
	resource_collected.emit(kind, amount, current_depth)
	message_changed.emit(
		"OVERLOAD CACHE · +%d %s · nearby surge empowered" % [amount, kind.replace("_", " ").to_upper()]
		if choice == "overload"
		else "STABLE CACHE · +%d %s · nearby surge silenced" % [amount, kind.replace("_", " ").to_upper()]
	)


func _cancel_site_activity() -> void:
	site_activity.clear()
	for site in discovery_sites:
		var visual := discovery_visuals.get(String(site.id)) as Node2D
		if not is_instance_valid(visual):
			continue
		var choice_pads := visual.get_node_or_null("ChoicePads") as Node2D
		var runes := visual.get_node_or_null("RuneSequence") as Node2D
		if is_instance_valid(choice_pads):
			choice_pads.visible = not bool(site.get("resolved", false))
		if is_instance_valid(runes):
			runes.visible = false


func _update_site_activity_visual() -> void:
	if site_activity.is_empty():
		return
	var array_index := int(site_activity.get("array_index", -1))
	if array_index < 0 or array_index >= discovery_sites.size():
		return
	var site: Dictionary = discovery_sites[array_index]
	var visual := discovery_visuals.get(String(site.id)) as Node2D
	if not is_instance_valid(visual):
		return
	var choice_pads := visual.get_node_or_null("ChoicePads") as Node2D
	var runes := visual.get_node_or_null("RuneSequence") as Node2D
	if is_instance_valid(choice_pads):
		choice_pads.visible = false
	if not is_instance_valid(runes):
		return
	runes.visible = true
	var next_rune := int(site_activity.get("next_rune", 0))
	var rune_count := int(site_activity.get("rune_count", 0))
	var elapsed := float(site_activity.get("elapsed", 0.0))
	var active_color := Color("ffb45f") if String(site_activity.get("choice", "")) == "overload" else Color("7ff1d7")
	for index in runes.get_child_count():
		var rune := runes.get_child(index) as Node2D
		rune.visible = index < rune_count
		if not rune.visible:
			continue
		var ring := rune.get_node_or_null("Ring") as Line2D
		var fill := rune.get_node_or_null("Fill") as Polygon2D
		if index < next_rune:
			rune.scale = Vector2.ONE * 0.86
			if is_instance_valid(ring):
				ring.default_color = Color("86e6ae", 0.42)
			if is_instance_valid(fill):
				fill.color = Color("86e6ae", 0.08)
		elif index == next_rune:
			var pulse := 1.0 + sin(elapsed * 6.0) * 0.09
			rune.scale = Vector2.ONE * pulse
			if is_instance_valid(ring):
				ring.default_color = Color(active_color, 0.96)
			if is_instance_valid(fill):
				fill.color = Color(active_color, 0.18)
		else:
			rune.scale = Vector2.ONE * 0.9
			if is_instance_valid(ring):
				ring.default_color = Color(active_color, 0.18)
			if is_instance_valid(fill):
				fill.color = Color(active_color, 0.025)


func _set_site_visual_resolved(site: Dictionary) -> void:
	var visual := discovery_visuals.get(String(site.id)) as Node2D
	if not is_instance_valid(visual):
		return
	visual.modulate = Color(0.76, 0.82, 0.8, 0.72)
	var choice_pads := visual.get_node_or_null("ChoicePads") as Node2D
	var runes := visual.get_node_or_null("RuneSequence") as Node2D
	if is_instance_valid(choice_pads):
		choice_pads.visible = false
	if is_instance_valid(runes):
		runes.visible = false


func _show_site_cache_reward(site: Dictionary, kind: String) -> void:
	var visual := discovery_visuals.get(String(site.id)) as Node2D
	if not is_instance_valid(visual):
		return
	var reward := Sprite2D.new()
	reward.name = "RecoveredCache"
	reward.texture = _load_texture(String(RESOURCE_TEXTURE_PATHS.get(kind, "")))
	reward.position = Vector2(0.0, -44.0)
	reward.z_index = 8
	_fit_sprite(reward, Vector2.ONE * 76.0)
	visual.add_child(reward)
	var tween := create_tween()
	tween.tween_property(reward, "position:y", -92.0, 0.42)
	tween.tween_interval(0.32)
	tween.tween_property(reward, "modulate:a", 0.0, 0.38)
	tween.tween_callback(reward.queue_free)


func _site_array_index(site_index: int) -> int:
	for index in discovery_sites.size():
		if int(discovery_sites[index].get("index", index)) == site_index:
			return index
	return -1


func _update_mining(delta: float) -> void:
	var held := external_mine_held or Input.is_action_pressed("mine")
	if not held:
		_cancel_mining()
		return
	var target_index := _nearest_resource_index()
	if target_index < 0:
		_cancel_mining()
		return
	var target: Dictionary = resources[target_index]
	var target_id := String(target.id)
	if not mining_active or mining_target_id != target_id:
		mining_active = true
		mining_elapsed = 0.0
		mining_hit = false
		mining_target_id = target_id
		player.set_facing((Vector2(target.position) - player.global_position).normalized())
	mining_elapsed += maxf(0.0, delta)
	var duration := _mining_cycle_duration()
	var progress := clampf(mining_elapsed / duration, 0.0, 1.0)
	player.set_mining_visual(true, progress)
	if not mining_hit and progress >= MINING_HIT_PROGRESS:
		mining_hit = true
		_strike_resource(target_index)
	if progress >= 1.0:
		var overflow := maxf(0.0, mining_elapsed - duration)
		mining_elapsed = fposmod(overflow, duration)
		mining_hit = false
		if _nearest_resource_index() < 0:
			_cancel_mining()


func _nearest_resource_index() -> int:
	var facing := Vector2(player.facing_vector).normalized()
	var mining_range := RESOURCE_MINING_RANGE * float(_current_endless_tool().get("range_multiplier", 1.0))
	var best_index := -1
	var best_score := INF
	for index in resources.size():
		var resource: Dictionary = resources[index]
		if bool(resource.mined):
			continue
		var offset := Vector2(resource.position) - player.global_position
		var distance := offset.length()
		if distance > mining_range:
			continue
		var direction_score := facing.dot(offset.normalized()) if distance > 0.001 else 1.0
		if direction_score < -0.12:
			continue
		var score := distance - direction_score * 38.0
		if score < best_score:
			best_score = score
			best_index = index
	return best_index


func _strike_resource(index: int) -> void:
	if index < 0 or index >= resources.size():
		return
	var resource: Dictionary = resources[index]
	if bool(resource.mined):
		return
	var tool := _current_endless_tool()
	resource.hp = maxi(0, int(resource.hp) - maxi(1, int(tool.get("power", 1))))
	var finished := int(resource.hp) <= 0
	if finished:
		var collected_amount := int(resource.amount) * maxi(1, int(tool.get("yield_multiplier", 1)))
		var accepted := true
		if RunState.has_method("collect_endless_resource"):
			accepted = bool(RunState.collect_endless_resource(String(resource.kind), collected_amount))
		elif RunState.has_method("add_resource"):
			RunState.add_resource(String(resource.kind), collected_amount, true)
		if not accepted:
			resource.hp = 1
			resources[index] = resource
			message_changed.emit("The recovery pouch cannot secure this material yet")
			return
		resource.mined = true
		session_mined_nodes[String(resource.id)] = true
		if RunState.has_method("mark_endless_resource_node_mined"):
			RunState.mark_endless_resource_node_mined(
				current_depth, int(resource.get("node_index", index))
			)
		message_changed.emit("+%d %s" % [collected_amount, String(resource.kind).replace("_", " ").to_upper()])
		resource_collected.emit(String(resource.kind), collected_amount, current_depth)
		resource_mined.emit(String(resource.kind), collected_amount)
		var visual := resource_visuals.get(String(resource.id)) as Node2D
		if is_instance_valid(visual):
			visual.queue_free()
		resource_visuals.erase(String(resource.id))
	else:
		var visual := resource_visuals.get(String(resource.id)) as Node2D
		if is_instance_valid(visual):
			visual.scale = Vector2.ONE * 0.91
		if AudioDirector.has_method("play_mining"):
			AudioDirector.play_mining(String(resource.kind), false, false)
	resources[index] = resource


func _mining_cycle_duration() -> float:
	return clampf(float(_current_endless_tool().get("cooldown", MINING_DURATION)) * 7.0, 0.24, 0.68)


func _current_endless_tool() -> Dictionary:
	var tool: Dictionary = {}
	if int(RunState.get("drill_level")) > 0 and GameData.data.has("DRILLS"):
		var drill_level := clampi(int(RunState.get("drill_level")), 0, int(GameData.data.DRILLS.size()) - 1)
		tool = Dictionary(GameData.data.DRILLS[drill_level]).duplicate(true)
	elif RunState.has_method("current_pickaxe"):
		tool = Dictionary(RunState.current_pickaxe()).duplicate(true)
	if tool.is_empty():
		tool = {"power": 1, "cooldown": MINING_DURATION, "range_multiplier": 1.0}
	if RunState.has_method("attune_tool_with_starforge"):
		tool = Dictionary(RunState.attune_tool_with_starforge(tool))
	return tool


func _cancel_mining() -> void:
	mining_active = false
	mining_elapsed = 0.0
	mining_hit = false
	mining_target_id = ""
	if is_instance_valid(player):
		player.set_mining_visual(false)


func _update_resource_pulses() -> void:
	var time := Time.get_ticks_msec() * 0.001
	for resource in resources:
		if bool(resource.mined):
			continue
		var visual := resource_visuals.get(String(resource.id)) as Node2D
		if not is_instance_valid(visual):
			continue
		var pulse := 1.0 + sin(time * 2.1 + float(resource.phase)) * 0.035
		if visual.scale.x < 0.96:
			visual.scale = visual.scale.lerp(Vector2.ONE * pulse, 0.35)
		else:
			visual.scale = Vector2.ONE * pulse


func _attach_native_relic(relic_id: String) -> bool:
	if rope_attached or relic_id.is_empty() or relic_id != native_relic_id:
		return false
	if player.global_position.distance_to(native_relic_position) > RELIC_CONTEXT_RADIUS + 12.0:
		return false
	if RunState.has_method("discover_endless_relic"):
		RunState.discover_endless_relic(relic_id, current_depth)
	var collected := true
	if RunState.has_method("collect_endless_relic"):
		var result = RunState.collect_endless_relic(relic_id, current_depth)
		if result is Dictionary:
			collected = bool(Dictionary(result).get("ok", true))
		else:
			collected = bool(result)
	if not collected:
		message_changed.emit("The recovery rig cannot claim this relic")
		return false
	var attached := true
	if RunState.has_method("attach_carried_relic"):
		attached = bool(RunState.attach_carried_relic(relic_id))
	if not attached:
		message_changed.emit("Attach the recovery rope before moving the relic")
		return false
	carried_relic_id = relic_id
	carried_relic_discovery_depth = current_depth
	rope_attached = true
	if is_instance_valid(native_relic_visual):
		native_relic_visual.queue_free()
	native_relic_visual = null
	var native_light := world_lights.get_node_or_null("NativeRelicLight")
	if is_instance_valid(native_light):
		native_light.queue_free()
	native_relic_id = ""
	_initialize_rope(player.global_position + Vector2(0, 7), native_relic_position)
	relic_attached.emit(carried_relic_id, current_depth)
	rope_state_changed.emit(true, carried_relic_id)
	message_changed.emit("ROPE ATTACHED · haul %s to depth 0" % String(RELIC_NAMES.get(carried_relic_id, "RELIC")))
	_update_context(player.global_position)
	return true


func _restore_carried_relic_from_state() -> void:
	if not RunState.has_method("endless_descent_status"):
		return
	var status := Dictionary(RunState.endless_descent_status())
	if bool(status.get("active", false)):
		current_depth = maxi(0, int(status.get("current_depth", current_depth)))
	var carried := Dictionary(status.get("carried_relic", {}))
	var status_id := String(carried.get("id", status.get("carried_relic_id", "")))
	if status_id.is_empty():
		rope_attached = false
		carried_relic_id = ""
		carried_relic_discovery_depth = -1
		return
	carried_relic_id = status_id
	carried_relic_discovery_depth = int(carried.get("origin_depth", current_depth))
	rope_attached = bool(carried.get("attached", false))
	if not rope_attached and RunState.has_method("attach_carried_relic"):
		rope_attached = bool(RunState.attach_carried_relic(status_id))


func _relic_already_claimed(relic_id: String) -> bool:
	if relic_id == carried_relic_id:
		return true
	if RunState.has_method("relic_status"):
		var relic_state := Dictionary(RunState.relic_status(relic_id))
		return bool(relic_state.get("placed", false)) or bool(relic_state.get("carried", false))
	if RunState.has_method("endless_descent_status"):
		var status := Dictionary(RunState.endless_descent_status())
		for key in ["placed_relic_ids", "returned_relic_ids", "relic_ids"]:
			var values: Array = Array(status.get(key, []))
			if relic_id in values:
				return true
	return false


func _request_depth_change(target_depth: int, next_arrival: String) -> void:
	var shaft_position := up_shaft_position if target_depth < current_depth else down_shaft_position
	if rope_attached and not _relic_inside_shaft(shaft_position):
		message_changed.emit("HAUL THE RELIC INTO THE SHAFT · the rope is still outside")
		return
	if rope_attached and target_depth > current_depth:
		message_changed.emit("RELIC RECOVERY ROUTE · haul upward before exploring deeper")
		return
	depth_change_requested.emit(target_depth, next_arrival)


func _prepare_hub_exit() -> void:
	if rope_attached and not _relic_inside_shaft(up_shaft_position):
		message_changed.emit("HAUL THE RELIC FULLY INTO THE HUB SHAFT")
		return
	if rope_attached:
		relic_hauled_to_hub.emit(carried_relic_id, carried_relic_discovery_depth)
	hub_exit_requested.emit()


func _relic_inside_shaft(shaft_position: Vector2) -> bool:
	if not rope_attached:
		return true
	if rope_points.size() != ROPE_SEGMENTS + 1:
		return false
	return rope_points[rope_points.size() - 1].distance_to(shaft_position) <= SHAFT_CONTEXT_RADIUS


func _depth_arrival_message() -> String:
	if current_depth == 0:
		return "ENDLESS THRESHOLD · Hub above, the unknown below"
	return "DEPTH %d · %s" % [current_depth, String(stratum.name)]


func _sanitize_arrival(value: String) -> String:
	return "from_below" if value in ["from_below", "below", "down"] else "from_above"


func _spawn_for_arrival(value: String) -> Vector2:
	var shaft := down_shaft_position if _sanitize_arrival(value) == "from_below" else up_shaft_position
	var toward := up_shaft_position if shaft == down_shaft_position else down_shaft_position
	var direction := (toward - shaft).normalized()
	return _nearest_walkable_position(shaft + direction * PLAYER_SPAWN_OFFSET.y)


func _place_player_for_arrival(value: String) -> void:
	player.global_position = _spawn_for_arrival(value)
	player.camera.reset_smoothing()
	if rope_attached:
		_initialize_carried_rope(player.global_position)
	_on_player_moved(player.global_position)


func _configure_rope_lines() -> void:
	rope_shadow.width = 8.0
	rope_shadow.default_color = Color(0.015, 0.012, 0.009, 0.55)
	rope_shadow.antialiased = true
	rope_shadow.joint_mode = Line2D.LINE_JOINT_ROUND
	rope_shadow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	rope_shadow.end_cap_mode = Line2D.LINE_CAP_ROUND
	rope_visual.width = 5.5
	rope_visual.default_color = Color("c79b62")
	rope_visual.antialiased = true
	var fiber_gradient := Gradient.new()
	fiber_gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	fiber_gradient.colors = PackedColorArray([
		Color("b27b43"), Color("edc887"), Color("c08a50"),
	])
	rope_visual.gradient = fiber_gradient
	rope_visual.joint_mode = Line2D.LINE_JOINT_ROUND
	rope_visual.begin_cap_mode = Line2D.LINE_CAP_ROUND
	rope_visual.end_cap_mode = Line2D.LINE_CAP_ROUND


func _initialize_carried_rope(spawn_position: Vector2) -> void:
	if carried_relic_id.is_empty():
		_clear_rope(false)
		return
	var toward_room := (down_shaft_position - up_shaft_position).normalized()
	if arrival_side == "from_below":
		toward_room = -toward_room
	var relic_start := _nearest_walkable_position(spawn_position - toward_room * 86.0 + Vector2(0, 38), RELIC_RADIUS)
	_initialize_rope(spawn_position + Vector2(0, 7), relic_start)


func _initialize_rope(anchor: Vector2, relic_start: Vector2) -> void:
	rope_attached = not carried_relic_id.is_empty()
	if not rope_attached:
		_clear_rope(false)
		return
	rope_points = PackedVector2Array()
	rope_previous = PackedVector2Array()
	var direct := relic_start - anchor
	var direction := direct.normalized() if direct.length() > 0.001 else Vector2.RIGHT
	var perpendicular := Vector2(-direction.y, direction.x)
	var slack := maxf(42.0, float(ROPE_SEGMENTS) * ROPE_SEGMENT_LENGTH - direct.length()) * 0.52
	for index in ROPE_SEGMENTS + 1:
		var t := float(index) / float(ROPE_SEGMENTS)
		var point := anchor.lerp(relic_start, t) + perpendicular * sin(t * PI) * slack
		point = _resolve_circle_from_walls(point, RELIC_RADIUS if index == ROPE_SEGMENTS else ROPE_POINT_RADIUS)
		rope_points.append(point)
		rope_previous.append(point)
	rope_points[0] = anchor
	rope_previous[0] = anchor
	for iteration in ROPE_SOLVER_ITERATIONS * 2:
		_solve_rope_constraints(anchor, false)
	last_safe_relic_position = rope_points[ROPE_SEGMENTS]
	rope_accumulator = 0.0
	if is_instance_valid(relic_visual):
		relic_visual.queue_free()
	relic_visual = _build_relic_visual(carried_relic_id, last_safe_relic_position, true)
	rope_visual.visible = true
	rope_shadow.visible = true
	_update_rope_visual()


func _clear_rope(clear_identity: bool = true) -> void:
	rope_points = PackedVector2Array()
	rope_previous = PackedVector2Array()
	rope_accumulator = 0.0
	rope_visual.points = PackedVector2Array()
	rope_shadow.points = PackedVector2Array()
	rope_visual.visible = false
	rope_shadow.visible = false
	if is_instance_valid(relic_visual):
		relic_visual.queue_free()
	relic_visual = null
	if clear_identity:
		rope_attached = false
		carried_relic_id = ""
		carried_relic_discovery_depth = -1


func _simulate_rope_step(delta: float) -> void:
	if rope_points.size() != ROPE_SEGMENTS + 1 or rope_previous.size() != rope_points.size():
		_initialize_carried_rope(player.global_position)
		return
	var anchor := player.global_position + Vector2(0, 7)
	rope_points[0] = anchor
	rope_previous[0] = anchor
	for index in range(1, rope_points.size()):
		var position := rope_points[index]
		var previous := rope_previous[index]
		var damping := RELIC_LINEAR_DAMPING if index == rope_points.size() - 1 else ROPE_LINEAR_DAMPING
		var velocity := (position - previous) * damping
		rope_previous[index] = position
		# A tiny screen-down bias makes slack readable without turning the top-down cave into a platformer.
		var drift := Vector2(0.0, 7.0 if index < rope_points.size() - 1 else 2.0) * delta * delta
		rope_points[index] = position + velocity + drift
	for iteration in ROPE_SOLVER_ITERATIONS:
		_solve_rope_constraints(anchor, true)
	if not _rope_state_is_finite() or not _position_walkable(rope_points[ROPE_SEGMENTS], RELIC_RADIUS + 1.0):
		_recover_relic(anchor)
	else:
		last_safe_relic_position = rope_points[ROPE_SEGMENTS]
	rope_simulation_steps += 1


func _solve_rope_constraints(anchor: Vector2, collide: bool) -> void:
	rope_points[0] = anchor
	for index in ROPE_SEGMENTS:
		var left := rope_points[index]
		var right := rope_points[index + 1]
		var delta := right - left
		var distance := delta.length()
		if distance <= 0.0001:
			delta = Vector2.RIGHT * 0.0001
			distance = 0.0001
		var error := distance - ROPE_SEGMENT_LENGTH
		rope_constraint_peak_error = maxf(rope_constraint_peak_error, absf(error))
		var correction := delta / distance * error
		var left_inverse_mass := 0.0 if index == 0 else 1.0
		var right_inverse_mass := 0.28 if index + 1 == ROPE_SEGMENTS else 1.0
		var inverse_total := left_inverse_mass + right_inverse_mass
		if inverse_total > 0.0:
			if left_inverse_mass > 0.0:
				rope_points[index] += correction * (left_inverse_mass / inverse_total)
			if right_inverse_mass > 0.0:
				rope_points[index + 1] -= correction * (right_inverse_mass / inverse_total)
		rope_points[0] = anchor
	if not collide:
		return
	for index in range(1, rope_points.size()):
		var radius := RELIC_RADIUS if index == ROPE_SEGMENTS else ROPE_POINT_RADIUS
		var before := rope_points[index]
		var resolved := _resolve_circle_from_walls(before, radius)
		if not resolved.is_equal_approx(before):
			var correction := resolved - before
			rope_points[index] = resolved
			rope_previous[index] += correction
			rope_collision_responses += 1


func _recover_relic(anchor: Vector2) -> void:
	var safe := last_safe_relic_position
	if not _position_walkable(safe, RELIC_RADIUS + 1.0):
		safe = _nearest_walkable_position(anchor + Vector2(0, 70), RELIC_RADIUS)
	rope_recovery_count += 1
	_initialize_rope(anchor, safe)


func _rope_state_is_finite() -> bool:
	for point in rope_points:
		if not is_finite(point.x) or not is_finite(point.y):
			return false
	return true


func _update_rope_visual() -> void:
	if not rope_attached or rope_points.is_empty():
		return
	var end := rope_points[rope_points.size() - 1]
	var before_end := rope_points[rope_points.size() - 2]
	var velocity := end - rope_previous[rope_previous.size() - 1]
	var target_rotation := (before_end - end).angle() + PI * 0.5
	relic_rotation = lerp_angle(relic_rotation, target_rotation + clampf(velocity.x * 0.012, -0.22, 0.22), 0.16)
	var visual_points := rope_points.duplicate()
	var hook_offset := _relic_rope_offset(carried_relic_id).rotated(relic_rotation)
	visual_points[visual_points.size() - 1] = end + hook_offset
	var shadow_points := visual_points.duplicate()
	for index in shadow_points.size():
		shadow_points[index] += Vector2(2.0, 3.0)
	rope_visual.points = visual_points
	rope_shadow.points = shadow_points
	if is_instance_valid(relic_visual):
		relic_visual.position = end
		relic_visual.rotation = relic_rotation


func _circle_collides_walls(position: Vector2, radius: float) -> bool:
	if position.x - radius < 0.0 or position.y - radius < 0.0 or position.x + radius > WORLD_SIZE.x or position.y + radius > WORLD_SIZE.y:
		return true
	var min_cell := _world_to_cell(position - Vector2.ONE * radius)
	var max_cell := _world_to_cell(position + Vector2.ONE * radius)
	for row in range(min_cell.y, max_cell.y + 1):
		for col in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(col, row)
			if _is_floor(cell):
				continue
			var rect := Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			var nearest := Vector2(
				clampf(position.x, rect.position.x, rect.end.x),
				clampf(position.y, rect.position.y, rect.end.y)
			)
			if position.distance_squared_to(nearest) < radius * radius:
				return true
	return false


func _resolve_circle_from_walls(position: Vector2, radius: float) -> Vector2:
	var result := position.clamp(Vector2.ONE * radius, WORLD_SIZE - Vector2.ONE * radius)
	for iteration in 4:
		var changed := false
		var min_cell := _world_to_cell(result - Vector2.ONE * radius) - Vector2i.ONE
		var max_cell := _world_to_cell(result + Vector2.ONE * radius) + Vector2i.ONE
		for row in range(min_cell.y, max_cell.y + 1):
			for col in range(min_cell.x, max_cell.x + 1):
				var cell := Vector2i(col, row)
				if _is_floor(cell):
					continue
				var rect := Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
				var nearest := Vector2(
					clampf(result.x, rect.position.x, rect.end.x),
					clampf(result.y, rect.position.y, rect.end.y)
				)
				var separation := result - nearest
				var distance := separation.length()
				if distance >= radius:
					continue
				if distance > 0.0001:
					result += separation / distance * (radius - distance + 0.05)
				else:
					var left := absf(result.x - rect.position.x)
					var right := absf(rect.end.x - result.x)
					var top := absf(result.y - rect.position.y)
					var bottom := absf(rect.end.y - result.y)
					var nearest_edge := minf(minf(left, right), minf(top, bottom))
					if nearest_edge == left:
						result.x = rect.position.x - radius - 0.05
					elif nearest_edge == right:
						result.x = rect.end.x + radius + 0.05
					elif nearest_edge == top:
						result.y = rect.position.y - radius - 0.05
					else:
						result.y = rect.end.y + radius + 0.05
				changed = true
				rope_collision_responses += 1
		if not changed:
			break
	return result.clamp(Vector2.ONE * radius, WORLD_SIZE - Vector2.ONE * radius)


func _position_walkable(position: Vector2, radius: float = PLAYER_RADIUS) -> bool:
	return not _circle_collides_walls(position, radius)


func _nearest_walkable_position(position: Vector2, radius: float = PLAYER_RADIUS) -> Vector2:
	var preferred := position.clamp(Vector2.ONE * radius, WORLD_SIZE - Vector2.ONE * radius)
	if _position_walkable(preferred, radius):
		return preferred
	var origin := _world_to_cell(preferred)
	for distance in range(0, 15):
		for row_offset in range(-distance, distance + 1):
			var col_distance := distance - absi(row_offset)
			for col_offset in ([0] if col_distance == 0 else [-col_distance, col_distance]):
				var cell := origin + Vector2i(int(col_offset), row_offset)
				if not _is_floor(cell):
					continue
				var candidate := _cell_center(cell)
				if _position_walkable(candidate, radius):
					return candidate
	return _cell_center(up_shaft_cell)


func _load_stratum_textures() -> void:
	var texture_index := current_depth % STRATUM_FLOOR_TEXTURE_PATHS.size()
	cave_floor_texture = _load_texture(String(STRATUM_FLOOR_TEXTURE_PATHS[texture_index]))
	cave_wall_texture = _load_texture(String(STRATUM_WALL_TEXTURE_PATHS[texture_index]))
	if shaft_texture == null:
		shaft_texture = _load_texture(SHAFT_TEXTURE_PATH)


func _floor_texture_region(cell: Vector2i) -> Rect2:
	if cave_floor_texture == null:
		return Rect2(Vector2.ZERO, Vector2.ONE * TILE_SIZE)
	var source_width := maxi(roundi(cave_floor_texture.get_width()), roundi(TILE_SIZE))
	var source_height := maxi(roundi(cave_floor_texture.get_height()), roundi(TILE_SIZE))
	var span_x := maxi(1, source_width - roundi(TILE_SIZE) + 1)
	var span_y := maxi(1, source_height - roundi(TILE_SIZE) + 1)
	var key := absi(cell.x * 92821 + cell.y * 68917 + generation_seed * 3)
	var source_x := float(key % span_x)
	var source_y := float((key / 11) % span_y)
	return Rect2(Vector2(source_x, source_y), Vector2.ONE * TILE_SIZE)


func _draw() -> void:
	if floor_cells.is_empty() or stratum.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color(stratum.wall).darkened(0.42), true)
	var center := player.global_position if is_instance_valid(player) else WORLD_SIZE * 0.5
	var min_cell := _world_to_cell(center - Vector2(820, 520))
	var max_cell := _world_to_cell(center + Vector2(820, 520))
	min_cell.x = clampi(min_cell.x, 0, GRID_SIZE.x - 1)
	min_cell.y = clampi(min_cell.y, 0, GRID_SIZE.y - 1)
	max_cell.x = clampi(max_cell.x, 0, GRID_SIZE.x - 1)
	max_cell.y = clampi(max_cell.y, 0, GRID_SIZE.y - 1)
	# Ground and permanent wall mass are laid down first.  Edge faces overlap
	# the walkable floor, so they live in a second pass and can never be cut up
	# by whichever neighbouring tile happened to draw last.
	for row in range(min_cell.y, max_cell.y + 1):
		for col in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(col, row)
			var rect := Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			if _is_floor(cell):
				var alternate := ((col * 17 + row * 31 + generation_seed) & 3) == 0
				if cave_floor_texture != null:
					draw_texture_rect_region(
						cave_floor_texture, rect, _floor_texture_region(cell), Color(0.88, 0.9, 0.92, 1.0)
					)
					draw_rect(rect, Color(stratum.floor_alt if alternate else stratum.floor, 0.28), true)
				else:
					draw_rect(rect, Color(stratum.floor_alt if alternate else stratum.floor), true)
				_draw_floor_detail(cell, rect)
			elif _has_floor_neighbor(cell):
				_draw_permanent_wall_mass(cell, rect)
	for row in range(min_cell.y, max_cell.y + 1):
		for col in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(col, row)
			if _is_floor(cell) or not _has_floor_neighbor(cell):
				continue
			var rect := Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			_draw_wall_edges(cell, rect)
	_draw_shaft(up_shaft_position, true)
	_draw_shaft(down_shaft_position, false)


func _draw_permanent_wall_mass(_cell: Vector2i, rect: Rect2) -> void:
	var wall := Color(stratum.wall)
	draw_rect(rect.grow(0.7), wall.darkened(0.06), true)


func _draw_floor_detail(cell: Vector2i, rect: Rect2) -> void:
	var key := absi(cell.x * 92821 + cell.y * 68917 + generation_seed * 3)
	if key % 5 != 0:
		return
	var offset := Vector2(float(10 + key % 39), float(11 + (key / 7) % 37))
	var color := Color(stratum.wall_edge)
	color.a = 0.17
	draw_line(rect.position + offset - Vector2(7, 2), rect.position + offset + Vector2(8, 3), color, 2.0)


func _draw_wall_edges(cell: Vector2i, rect: Rect2) -> void:
	var open_sides := [
		_is_floor(cell + Vector2i.UP),
		_is_floor(cell + Vector2i.RIGHT),
		_is_floor(cell + Vector2i.DOWN),
		_is_floor(cell + Vector2i.LEFT),
	]
	for side in 4:
		if bool(open_sides[side]):
			_draw_permanent_wall_face(cell, rect, side)
	_draw_permanent_wall_corners(cell, rect, open_sides)


func _draw_permanent_wall_face(cell: Vector2i, rect: Rect2, side: int) -> void:
	var starts := [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
	]
	var finishes := [
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
		rect.position,
	]
	var outward_directions := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
	var start: Vector2 = starts[side]
	var finish: Vector2 = finishes[side]
	var outward: Vector2 = outward_directions[side]
	var inward := -outward
	var outer := _endless_edge_profile(start, finish, outward, side, 2.0, 5.4, 0)
	var inner := _endless_edge_profile(start, finish, inward, side, 25.0, 8.0, 43)
	var shadow_outer := _endless_offset_profile(outer, outward * 12.0)
	var wall := Color(stratum.wall)
	var edge := Color(stratum.wall_edge)
	var face := wall.lerp(edge, 0.28).darkened(0.02)
	draw_colored_polygon(
		_endless_edge_strip(shadow_outer, outer),
		Color(0.004, 0.006, 0.006, 0.94)
	)
	draw_colored_polygon(_endless_edge_strip(outer, inner), Color(face, 0.99))
	draw_polyline(inner, Color(wall.darkened(0.38), 0.78), 5.2, true)
	draw_polyline(outer, Color(0.004, 0.006, 0.006, 0.98), 7.4, true)
	draw_polyline(
		PackedVector2Array([outer[1], outer[2], outer[3]]),
		Color(edge.lightened(0.08), 0.56),
		2.8,
		true
	)
	_draw_permanent_wall_strata(cell, start, finish, inward, side)


func _draw_permanent_wall_strata(
	cell: Vector2i,
	start: Vector2,
	finish: Vector2,
	inward: Vector2,
	side: int
) -> void:
	var key := absi(cell.x * 73819 + cell.y * 19391 + side * 83401 + generation_seed)
	var axis := 0 if side % 2 == 0 else 1
	var middle := PackedVector2Array()
	for step in 5:
		var point := start.lerp(finish, float(step) / 4.0)
		var drift := _endless_edge_noise(point, axis, 181) * 3.0
		middle.append(point + inward * (13.0 + drift))
	# Endless walls are one fused world mass.  A broad geological band adds
	# scale without the thin branches that would read as mineable damage.
	draw_polyline(
		middle,
		Color(Color(stratum.wall_edge), 0.12 + float(key % 3) * 0.018),
		5.6,
		true
	)


func _draw_permanent_wall_corners(cell: Vector2i, rect: Rect2, open_sides: Array) -> void:
	var corners := [
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
	]
	var pairs := [[3, 0], [0, 1], [1, 2], [2, 3]]
	for corner_index in 4:
		var pair: Array = pairs[corner_index]
		if not bool(open_sides[int(pair[0])]) or not bool(open_sides[int(pair[1])]):
			continue
		var key := absi(cell.x * 77213 + cell.y * 48611 + corner_index * 31337 + generation_seed)
		var point: Vector2 = corners[corner_index]
		var shadow := _endless_angular_plate(point, 20.0, key)
		var face := _endless_angular_plate(point, 13.5, key + 19)
		draw_colored_polygon(shadow, Color(0.003, 0.005, 0.004, 0.94))
		draw_colored_polygon(
			face,
			Color(Color(stratum.wall).lerp(Color(stratum.wall_edge), 0.31), 0.99)
		)


func _endless_edge_profile(
	start: Vector2,
	finish: Vector2,
	direction: Vector2,
	side: int,
	base: float,
	amplitude: float,
	salt: int
) -> PackedVector2Array:
	var result := PackedVector2Array()
	var axis := 0 if side % 2 == 0 else 1
	for step in 5:
		var point := start.lerp(finish, float(step) / 4.0)
		result.append(point + direction * (base + _endless_edge_noise(point, axis, salt) * amplitude))
	return result


func _endless_edge_noise(point: Vector2, axis: int, salt: int) -> float:
	var sample_x := roundi(point.x / (TILE_SIZE * 0.25))
	var sample_y := roundi(point.y / (TILE_SIZE * 0.25))
	var key := absi(
		sample_x * 92821 + sample_y * 68917 + axis * 31337
		+ salt * 1999 + generation_seed
	)
	return fposmod(sin(float(key)) * 43758.5453, 1.0)


func _endless_offset_profile(points: PackedVector2Array, offset: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in points:
		result.append(point + offset)
	return result


func _endless_edge_strip(first: PackedVector2Array, second: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point in first:
		result.append(point)
	for index in range(second.size() - 1, -1, -1):
		result.append(second[index])
	return result


func _endless_angular_plate(center: Vector2, radius: float, key: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for vertex in 7:
		var angle := TAU * float(vertex) / 7.0 + float(key % 19) * 0.017
		var scale := 0.76 + _endless_edge_noise(
			center + Vector2(float(vertex) * 3.0, float(key % 13)),
			vertex % 2,
			key + vertex
		) * 0.38
		points.append(center + Vector2(cos(angle), sin(angle)) * radius * scale)
	return points


func _draw_shaft(position: Vector2, upward: bool) -> void:
	var color := Color("91dcff") if upward else Color(stratum.accent)
	draw_circle(position, 74.0, Color(0.025, 0.035, 0.045, 0.96))
	if shaft_texture != null:
		var shaft_rect := Rect2(position - Vector2(85.0, 61.0), Vector2(170.0, 122.0))
		var shaft_modulate := Color(0.92, 0.97, 1.0, 0.98) if upward else Color.WHITE.lerp(color, 0.18)
		draw_texture_rect(shaft_texture, shaft_rect, false, shaft_modulate)
	draw_arc(position, 74.0, 0.0, TAU, 32, Color(color, 0.48), 8.0, true)
	draw_arc(position, 52.0, 0.0, TAU, 28, Color(color, 0.24), 5.0, true)
	var direction := Vector2.UP if upward else Vector2.DOWN
	var side := Vector2(-direction.y, direction.x)
	var tip := position + direction * 25.0
	var back := position - direction * 17.0
	draw_colored_polygon(PackedVector2Array([tip, back + side * 23.0, back - side * 23.0]), Color(color, 0.76))


func _cell_index(cell: Vector2i) -> int:
	return cell.y * GRID_SIZE.x + cell.x


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _cell_in_bounds(cell: Vector2i, margin: int = 0) -> bool:
	return cell.x >= margin and cell.y >= margin and cell.x < GRID_SIZE.x - margin and cell.y < GRID_SIZE.y - margin


func _is_floor(cell: Vector2i) -> bool:
	return _cell_in_bounds(cell) and floor_cells[_cell_index(cell)] != 0


func _set_floor(cell: Vector2i, enabled: bool) -> void:
	if _cell_in_bounds(cell):
		floor_cells[_cell_index(cell)] = 1 if enabled else 0


func _has_floor_neighbor(cell: Vector2i) -> bool:
	for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		if _is_floor(cell + offset):
			return true
	return false


func _world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / TILE_SIZE), floori(position.y / TILE_SIZE))


func _cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


func _walkable_cell_count() -> int:
	var count := 0
	for value in floor_cells:
		if value != 0:
			count += 1
	return count


func _site_activity_layout_clear() -> bool:
	for site in discovery_sites:
		var runes: Array = Array(site.get("rune_positions", []))
		if runes.size() < 4:
			return false
		for index in runes.size():
			var position := Vector2(runes[index])
			if not _position_walkable(position):
				return false
			for other_index in range(index + 1, runes.size()):
				if position.distance_to(Vector2(runes[other_index])) < SITE_RUNE_RADIUS * 1.35:
					return false
	return true


func _path_is_connected() -> bool:
	if not _is_floor(up_shaft_cell) or not _is_floor(down_shaft_cell):
		return false
	var visited := PackedByteArray()
	visited.resize(floor_cells.size())
	visited.fill(0)
	var frontier: Array[Vector2i] = [up_shaft_cell]
	visited[_cell_index(up_shaft_cell)] = 1
	var cursor := 0
	while cursor < frontier.size():
		var cell := frontier[cursor]
		cursor += 1
		if cell == down_shaft_cell:
			return true
		for offset_value in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next_cell: Vector2i = cell + Vector2i(offset_value)
			if not _is_floor(next_cell):
				continue
			var index := _cell_index(next_cell)
			if visited[index] != 0:
				continue
			visited[index] = 1
			frontier.append(next_cell)
	return false


func _rope_max_segment_error() -> float:
	if rope_points.size() < 2:
		return 0.0
	var maximum := 0.0
	for index in rope_points.size() - 1:
		maximum = maxf(maximum, absf(rope_points[index].distance_to(rope_points[index + 1]) - ROPE_SEGMENT_LENGTH))
	return maximum


func rope_debug_snapshot() -> Dictionary:
	var endpoint := rope_points[rope_points.size() - 1] if not rope_points.is_empty() else Vector2.ZERO
	return {
		"attached": rope_attached,
		"relic_id": carried_relic_id,
		"discovery_depth": carried_relic_discovery_depth,
		"point_count": rope_points.size(),
		"segment_count": maxi(0, rope_points.size() - 1),
		"segment_length": ROPE_SEGMENT_LENGTH,
		"solver_iterations": ROPE_SOLVER_ITERATIONS,
		"fixed_step": ROPE_FIXED_STEP,
		"endpoint": endpoint,
		"endpoint_walkable": not rope_attached or _position_walkable(endpoint, RELIC_RADIUS),
		"max_segment_error": _rope_max_segment_error(),
		"peak_error_seen": rope_constraint_peak_error,
		"simulation_steps": rope_simulation_steps,
		"collision_responses": rope_collision_responses,
		"recovery_count": rope_recovery_count,
		"finite": _rope_state_is_finite(),
		"transition_ready_up": _relic_inside_shaft(up_shaft_position),
	}


func _premium_visual_snapshot() -> Dictionary:
	var textured_resources := 0
	for visual_value in resource_visuals.values():
		var visual := visual_value as Node2D
		if not is_instance_valid(visual):
			continue
		var sprite := visual.get_node_or_null("PremiumNode") as Sprite2D
		if is_instance_valid(sprite) and sprite.texture != null:
			textured_resources += 1
	var textured_sites := 0
	for visual_value in discovery_visuals.values():
		var visual := visual_value as Node2D
		if not is_instance_valid(visual):
			continue
		var sprite := visual.get_node_or_null("PremiumRuin") as Sprite2D
		if is_instance_valid(sprite) and sprite.texture != null:
			textured_sites += 1
	var carried_sprite: Sprite2D
	var carried_light: PointLight2D
	if is_instance_valid(relic_visual):
		carried_sprite = relic_visual.get_node_or_null("PremiumRelic") as Sprite2D
		carried_light = relic_visual.get_node_or_null("CarriedRelicLight") as PointLight2D
	return {
		"terrain": cave_floor_texture != null and cave_wall_texture != null and shaft_texture != null,
		"resource_count": textured_resources,
		"resource_expected": resource_visuals.size(),
		"site_count": textured_sites,
		"site_expected": discovery_visuals.size(),
		"carried_relic": is_instance_valid(carried_sprite) and carried_sprite.texture != null,
		"carried_light": is_instance_valid(carried_light) and carried_light.texture != null,
	}


func debug_snapshot() -> Dictionary:
	var resource_counts: Dictionary = {}
	var remaining := 0
	var resolved_sites := 0
	for resource in resources:
		if bool(resource.mined):
			continue
		var kind := String(resource.kind)
		resource_counts[kind] = int(resource_counts.get(kind, 0)) + 1
		remaining += 1
	for site in discovery_sites:
		if bool(site.get("resolved", false)):
			resolved_sites += 1
	return {
		"initialized": initialized,
		"generation_count": generation_count,
		"depth": current_depth,
		"seed": generation_seed,
		"signature": generation_signature,
		"stratum": String(stratum.get("name", "")),
		"world_size": WORLD_SIZE,
		"grid_size": GRID_SIZE,
		"tile_size": TILE_SIZE,
		"walkable_cells": _walkable_cell_count(),
		"path_connected": _path_is_connected(),
		"up_cell": up_shaft_cell,
		"down_cell": down_shaft_cell,
		"up_position": up_shaft_position,
		"down_position": down_shaft_position,
		"spawn": entry_spawn(),
		"spawn_clear": not collision_at(entry_spawn()),
		"up_clear": _position_walkable(up_shaft_position, RELIC_RADIUS),
		"down_clear": _position_walkable(down_shaft_position, RELIC_RADIUS),
		"room_count": rooms.size(),
		"branch_count": branch_rooms.size(),
		"resource_count": remaining,
		"resource_counts": resource_counts,
		"site_count": discovery_sites.size(),
		"resolved_site_count": resolved_sites,
		"site_runes_clear": _site_activity_layout_clear(),
		"site_activity": site_activity.duplicate(true),
		"native_relic_id": native_relic_id,
		"native_relic_depth": native_relic_depth,
		"context": active_context,
		"rope": rope_debug_snapshot(),
		"premium_visuals": _premium_visual_snapshot(),
		"hazards": resonance_hazards.size(),
		"hazard_surges": hazard_surge_count,
		"enemies": 0,
		"health_required": false,
		"timer": false,
		"route_closing": false,
		"ruin_gameplay": "choose_path_then_cross_ordered_floor_seals",
		"hazard_model": "telegraphed_resonance_push_no_damage",
		"treasure_model": "persistent_one_claim_resource_caches",
		"generation_model": "deterministic_connected_rooms_and_branches",
		"resource_regeneration": "none_compact_floor_exhaustion",
		"mobile_draw_model": "culled_tiles_static_nodes_single_line_rope",
	}


func get_headless_qa_snapshot() -> Dictionary:
	return debug_snapshot()


func qa_generate_depth(depth: int) -> Dictionary:
	load_depth(maxi(0, depth), "from_above")
	return debug_snapshot()


func qa_determinism_probe(depth: int) -> Dictionary:
	load_depth(maxi(0, depth), "from_above")
	var first_signature := generation_signature
	var first_up := up_shaft_cell
	var first_down := down_shaft_cell
	var first_manifest := qa_interaction_manifest()
	load_depth(maxi(0, depth), "from_above")
	return {
		"depth": depth,
		"signature": generation_signature,
		"same_signature": first_signature == generation_signature,
		"same_shafts": first_up == up_shaft_cell and first_down == down_shaft_cell,
		"same_interactions": first_manifest == qa_interaction_manifest(),
		"path_connected": _path_is_connected(),
	}


func qa_interaction_manifest() -> Dictionary:
	var sites: Array[Dictionary] = []
	for site in discovery_sites:
		sites.append({
			"id": String(site.id),
			"index": int(site.get("index", 0)),
			"variant": int(site.variant),
			"cell": _world_to_cell(Vector2(site.position)),
			"reward_kind": String(site.get("reward_kind", "")),
			"base_reward": int(site.get("base_reward", 0)),
			"runes": Array(site.get("rune_positions", [])).duplicate(true),
		})
	var hazards: Array[Dictionary] = []
	for hazard in resonance_hazards:
		hazards.append({
			"id": String(hazard.id),
			"cell": _world_to_cell(Vector2(hazard.position)),
			"phase_millis": roundi(float(hazard.phase_offset) * 1000.0),
		})
	return {"depth": current_depth, "sites": sites, "hazards": hazards}


func qa_complete_site_activity(site_index: int = 0, choice: String = "stabilize") -> Dictionary:
	var array_index := _site_array_index(site_index)
	if array_index < 0:
		return {"ok": false, "reason": "site_missing"}
	var site: Dictionary = discovery_sites[array_index]
	var approach := Vector2(site.position) + Vector2(
		SITE_PAD_OFFSET if choice == "overload" else -SITE_PAD_OFFSET,
		36.0
	)
	restore_position(approach)
	var context_before := current_context()
	var started := not perform_context().is_empty()
	if not started:
		return {"ok": false, "reason": "activity_not_started", "context": context_before}
	var runes: Array = Array(site.get("rune_positions", []))
	var required := 4 if choice == "overload" else 3
	for index in mini(required, runes.size()):
		restore_position(Vector2(runes[index]))
		_update_site_activity(1.0 / 60.0)
	var refreshed: Dictionary = discovery_sites[array_index]
	return {
		"ok": bool(refreshed.get("resolved", false)),
		"context": context_before,
		"choice": String(refreshed.get("choice", "")),
		"reward_kind": String(refreshed.get("reward_kind", "")),
		"resolved": bool(refreshed.get("resolved", false)),
	}


func qa_resonance_hazard_probe(index: int = 0) -> Dictionary:
	if index < 0 or index >= resonance_hazards.size():
		return {"found": false}
	var hazard: Dictionary = resonance_hazards[index]
	hazard["disabled"] = false
	hazard["last_pulse_cycle"] = -999999
	resonance_hazards[index] = hazard
	restore_position(Vector2(hazard.position))
	var before_position := player.global_position
	var before_surges := hazard_surge_count
	var cycle := HAZARD_CYCLE * (0.72 if bool(hazard.get("empowered", false)) else 1.0)
	hazard_clock = cycle * 10.0 - float(hazard.phase_offset) + 0.05
	_update_resonance_hazards(0.0)
	for step in 20:
		_apply_hazard_push(1.0 / 60.0)
	return {
		"found": true,
		"telegraphed": hazard_visuals.has(String(hazard.id)),
		"triggered": hazard_surge_count == before_surges + 1,
		"pushed": player.global_position.distance_to(before_position) > 18.0,
		"player_clear": _position_walkable(player.global_position),
	}


func qa_force_attach_relic(relic_id: String = "forge_heart") -> Dictionary:
	if relic_id not in RELIC_IDS:
		relic_id = "forge_heart"
	carried_relic_id = relic_id
	carried_relic_discovery_depth = current_depth
	rope_attached = true
	var start := _nearest_walkable_position(player.global_position + Vector2(74, 34), RELIC_RADIUS)
	_initialize_rope(player.global_position + Vector2(0, 7), start)
	return rope_debug_snapshot()


func qa_step_rope(steps: int = 120, movement_per_step: Vector2 = Vector2(1.6, 0.6)) -> Dictionary:
	for index in maxi(0, steps):
		player.global_position = _resolve_motion(player.global_position, movement_per_step)
		_simulate_rope_step(ROPE_FIXED_STEP)
	_update_rope_visual()
	return rope_debug_snapshot()


func qa_rope_wall_probe() -> Dictionary:
	var contact := Vector2.ZERO
	var found := false
	for row in range(1, GRID_SIZE.y - 1):
		for col in range(1, GRID_SIZE.x - 1):
			var cell := Vector2i(col, row)
			if not _is_floor(cell) or _is_floor(cell + Vector2i.RIGHT):
				continue
			var boundary_x := float(cell.x + 1) * TILE_SIZE
			contact = Vector2(boundary_x - RELIC_RADIUS + 8.0, _cell_center(cell).y)
			found = true
			break
		if found:
			break
	var before_count := rope_collision_responses
	var resolved := _resolve_circle_from_walls(contact, RELIC_RADIUS) if found else Vector2.ZERO
	return {
		"found_wall": found,
		"penetrating_position": contact,
		"resolved_position": resolved,
		"moved_out": found and not resolved.is_equal_approx(contact),
		"resolved_walkable": found and _position_walkable(resolved, RELIC_RADIUS),
		"collision_responses": rope_collision_responses - before_count,
	}


func qa_transition_gate_snapshot() -> Dictionary:
	if not rope_attached:
		qa_force_attach_relic("forge_heart")
	var saved_end := rope_points[ROPE_SEGMENTS]
	rope_points[ROPE_SEGMENTS] = up_shaft_position + Vector2(SHAFT_CONTEXT_RADIUS + 40.0, 0)
	var blocked_outside := not _relic_inside_shaft(up_shaft_position)
	rope_points[ROPE_SEGMENTS] = up_shaft_position
	var allowed_inside := _relic_inside_shaft(up_shaft_position)
	rope_points[ROPE_SEGMENTS] = saved_end
	return {"blocked_outside": blocked_outside, "allowed_inside": allowed_inside}


func _qa_prepare_endless_state() -> bool:
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.add_resource("singularity", 1, true)
	var singularity_status: = Dictionary(RunState.singularity_extraction_status("singularity"))
	# The full Main scene secures the singularity from RunState's collection
	# signal; the isolated world QA secures it directly here.
	if (
		not bool(singularity_status.get("secured", false))
		and not RunState.secure_singularity("singularity")
	):
		push_error("Site persistence QA setup failed at singularity secure: %s" % singularity_status)
		return false
	var recipe := Dictionary(RunState.deep_elevator_recipe())
	for resource_id_value in recipe:
		var resource_id := String(resource_id_value)
		var required := int(recipe[resource_id])
		var carried := int(RunState.cargo.get(resource_id, 0))
		if carried < required:
			RunState.add_resource(resource_id, required - carried, true)
		if not bool(Dictionary(RunState.deliver_deep_elevator_material(resource_id, required)).get("ok", false)):
			push_error("Site persistence QA setup failed at elevator delivery: %s" % resource_id)
			return false
	if not RunState.power_deep_elevator() or not RunState.begin_final_expedition():
		push_error("Site persistence QA setup failed at elevator power/final start")
		return false
	for seal_id_value in RunState.DEEPHEART_SEAL_IDS:
		if not RunState.open_deepheart_seal(String(seal_id_value)):
			push_error("Site persistence QA setup failed at seal: %s" % seal_id_value)
			return false
	if not RunState.complete_final_expedition():
		push_error("Site persistence QA setup failed at final completion")
		return false
	var started := Dictionary(RunState.start_endless_descent(1))
	if not bool(started.get("ok", false)):
		push_error("Site persistence QA setup failed at endless start: %s" % started)
		return false
	return true


func _qa_site_persistence_probe() -> Dictionary:
	if not _qa_prepare_endless_state():
		return {"ok": false, "reason": "setup"}
	load_depth(1, "from_above")
	if discovery_sites.is_empty():
		return {"ok": false, "reason": "site_missing"}
	var site: Dictionary = discovery_sites[0]
	var kind := String(site.get("reward_kind", ""))
	var before := int(RunState.cargo.get(kind, 0))
	var completed := qa_complete_site_activity(0, "overload")
	var after_claim := int(RunState.cargo.get(kind, 0))
	if not bool(completed.get("ok", false)) or after_claim <= before:
		return {"ok": false, "reason": "claim"}
	RunState.set_location("endless", player.global_position)
	var saved := Dictionary(RunState.serialize())
	RunState.reset_run(false)
	if not RunState.deserialize(saved):
		return {"ok": false, "reason": "deserialize"}
	load_depth(1, "from_above")
	var after_reload := int(RunState.cargo.get(kind, 0))
	var replay := qa_complete_site_activity(0, "overload")
	var after_replay := int(RunState.cargo.get(kind, 0))
	var floor_state := Dictionary(RunState.endless_floor_site_state(1, 0))
	return {
		"ok": (
			after_reload == after_claim
			and after_replay == after_reload
			and not bool(replay.get("ok", false))
			and bool(floor_state.get("resolved", false))
			and String(floor_state.get("choice", "")) == "overload"
			and bool(discovery_sites[0].get("resolved", false))
		),
		"reward": after_claim - before,
		"mask": int(floor_state.get("mask", 0)),
	}


func _run_headless_qa() -> void:
	set_active(true, true)
	var ok := true
	var signatures: Array[String] = []
	for depth in [0, 1, 2, 50, 1000]:
		var probe := qa_determinism_probe(depth)
		ok = (
			ok
			and bool(probe.same_signature)
			and bool(probe.same_shafts)
			and bool(probe.same_interactions)
			and bool(probe.path_connected)
		)
		signatures.append(String(probe.signature))
		var layer := debug_snapshot()
		if depth == 0:
			ok = ok and int(layer.resource_count) == 0 and int(layer.site_count) == 0
			ok = ok and int(layer.hazards) == 0 and String(layer.native_relic_id).is_empty()
		else:
			ok = ok and int(layer.site_count) >= 2 and int(layer.hazards) >= 1
			ok = ok and bool(layer.site_runes_clear)
			ok = ok and not bool(layer.health_required) and not bool(layer.timer)
	load_depth(50, "from_above")
	var hazard_probe := qa_resonance_hazard_probe()
	qa_force_attach_relic("wayfinder_core")
	var premium := _premium_visual_snapshot()
	var rope := qa_step_rope(240, Vector2(1.2, 0.45))
	var wall_probe := qa_rope_wall_probe()
	var gate_probe := qa_transition_gate_snapshot()
	ok = ok and bool(rope.finite) and bool(rope.endpoint_walkable)
	ok = ok and bool(premium.terrain)
	ok = ok and int(premium.resource_count) == int(premium.resource_expected)
	ok = ok and int(premium.site_count) == int(premium.site_expected)
	ok = ok and bool(premium.carried_relic) and bool(premium.carried_light)
	ok = ok and int(rope.segment_count) == ROPE_SEGMENTS and float(rope.max_segment_error) < 5.0
	ok = ok and bool(wall_probe.found_wall) and bool(wall_probe.moved_out) and bool(wall_probe.resolved_walkable)
	ok = ok and bool(gate_probe.blocked_outside) and bool(gate_probe.allowed_inside)
	ok = ok and bool(hazard_probe.found) and bool(hazard_probe.telegraphed)
	ok = ok and bool(hazard_probe.triggered) and bool(hazard_probe.pushed) and bool(hazard_probe.player_clear)
	var persistence_probe := _qa_site_persistence_probe()
	ok = ok and bool(persistence_probe.get("ok", false)) and int(persistence_probe.get("reward", 0)) > 0
	if ok:
		print("EVER_DEEPER_ENDLESS_WORLD_OK depths=5 interactions=deterministic hazards=telegraphed sites=active one_claim=true persistence=true signatures=%s rope_segments=%d wall_responses=%d" % [",".join(signatures), ROPE_SEGMENTS, int(wall_probe.collision_responses)])
		get_tree().quit(0)
	else:
		push_error("Endless Descent world QA failed: persistence=%s world=%s" % [persistence_probe, debug_snapshot()])
		get_tree().quit(3)
