class_name HubWorld
extends Node2D

const LitFloorChunksScript = preload("res://scripts/lighting/lit_floor_chunks.gd")
var lit_floor_chunks: Node2D
const LitDrawSectionsScript = preload("res://scripts/lighting/lit_draw_sections.gd")
var lit_draw_sections: Node2D
const StaticLightFieldScript = preload("res://scripts/lighting/static_light_field.gd")
var static_light_field: Node2D
var _draw_canvas: CanvasItem
var trimmed_hub_texture_margins: bool = true
var _hub_texture_regions: Dictionary = {}

signal context_changed(context: String)
signal hub_exit_context_changed(active: bool)
signal hub_exit_requested
signal deep_elevator_checked
signal deep_elevator_enter_requested
signal deep_elevator_status_changed(status: Dictionary)
signal message_changed(message: String)
signal workshop_panel_requested(workshop_id: String)
signal workshop_action_committed(transaction: Dictionary)

const WORLD_SIZE: = Vector2(1440, 960)
const WALK_MIN: = Vector2(124, 124)
const WALK_MAX: = WORLD_SIZE - Vector2(124, 124)
const SURFACE_LIFT: = Vector2(240, 820)
const SURFACE_LIFT_RADIUS: = 126.0
const DEEP_ELEVATOR: = Vector2(720, 142)
const DEEP_ELEVATOR_POSITION: = DEEP_ELEVATOR
const DEEP_ELEVATOR_RADIUS: = 132.0
const DEEP_HOARD_POSITION: = Vector2(790, 620)
const DEEP_HOARD_RADIUS: = 196.0
const RELIC_PEDESTAL_POSITION: = Vector2(520, 690)
const RELIC_PEDESTAL_RADIUS: = 112.0
const RELIC_PLACEMENT_DISTANCE: = 80.0
const RELIC_ROPE_POINTS: = 9
const RELIC_ROPE_SEGMENT_LENGTH: = 17.0
const RELIC_ROPE_ITERATIONS: = 2
const WORKSHOP_INTERACT_RADIUS: = 116.0
const WORKSHOP_IDS: Array[String] = [
	"tool_forge", "light_lab", "wardrobe", "treasure_chamber", "lift_workshop",
]
const WORKSHOP_NAMES: Dictionary = {
	"tool_forge": "TOOL FORGE",
	"light_lab": "LIGHT LAB",
	"wardrobe": "WARDROBE",
	"treasure_chamber": "TREASURE CHAMBER",
	"lift_workshop": "TUNNEL WORKSHOP",
}
const WORKSHOP_POSITIONS: Dictionary = {
	"tool_forge": Vector2(286, 304),
	"light_lab": Vector2(405, 520),
	"wardrobe": Vector2(1120, 520),
	"treasure_chamber": RELIC_PEDESTAL_POSITION,
	"lift_workshop": Vector2(1120, 290),
}
const WORKSHOP_VISIBLE_SIZES: Dictionary = {
	"tool_forge": Vector2(315, 210),
	"light_lab": Vector2(180, 176),
	"wardrobe": Vector2(228, 166),
	"lift_workshop": Vector2(248, 226),
}
const WORKSHOP_FALLBACK_POSITIONS: Array[Vector2] = [
	Vector2(710, 735), Vector2(860, 292), Vector2(720, 480),
]
const PLAYER_SPAWN: = Vector2(430, 820)
const PLAYER_RADIUS: = 23.0
const SAFE_POSITION_SEARCH_STEP: = 8.0
const SAFE_POSITION_SEARCH_RINGS: = 48
const SAFE_POSITION_SEARCH_SAMPLES: = 32
const WORKSHOP_PRESENTATION_DURATIONS: Dictionary = {
	"delivery": 1.05,
	"build": 1.65,
	"upgrade": 1.25,
	"equip": 0.9,
}
const ELEVATOR_RESOURCE_ORDER: = [
	"ambercore", "lunacore", "furnaceheart", "singularity",
]
const ELEVATOR_RESOURCE_COLORS: = {
	"ambercore": Color("ffbd3f"),
	"lunacore": Color("50ddff"),
	"furnaceheart": Color("ff6438"),
	"singularity": Color("bb72ff"),
}
const ELEVATOR_SOCKET_OFFSETS: = {
	"ambercore": Vector2(-75, -93),
	"lunacore": Vector2(75, -93),
	"furnaceheart": Vector2(-88, 78),
	"singularity": Vector2(88, 78),
}

const PORTAL_TEXTURE: = preload("res://assets/voidstar/depth-portal.png")
const HUB_FLOOR_TEXTURE: = preload("res://assets/voidstar/floor.png")
const HUB_WALL_TEXTURE: = preload("res://assets/voidstar/wall.png")
const HUB_ROUTE_TEXTURE: = preload("res://assets/starfall/route-marker.png")
const HUB_LAMP_TEXTURE: = preload("res://assets/entrances/depth-work-lamp.png")
const DEEP_ELEVATOR_TERMINAL_TEXTURE: = preload("res://assets/hub/deep-elevator-terminal.png")
const TOOL_FORGE_WORKSHOP_TEXTURE_PATH: = "res://assets/endless/workshop-tool-forge-v1.png"
const LIGHT_LAB_WORKSHOP_TEXTURE_PATH: = "res://assets/endless/workshop-light-lab-v1.png"
const WARDROBE_WORKSHOP_TEXTURE_PATH: = "res://assets/endless/workshop-wardrobe-v1.png"
const LIFT_WORKSHOP_TEXTURE_PATH: = "res://assets/endless/workshop-lift-v1.png"
const TREASURE_CHAMBER_TEXTURE_PATH: = "res://assets/endless/treasure-chamber-v1.png"
const RELIC_PEDESTAL_TEXTURE_PATH: = "res://assets/endless/relic-pedestal-v1.png"
const FORGE_HEART_RELIC_TEXTURE_PATH: = "res://assets/endless/relic-forge-heart-v1.png"
const ANCIENT_LENS_RELIC_TEXTURE_PATH: = "res://assets/endless/relic-ancient-lens-v1.png"
const MEMORY_LOOM_RELIC_TEXTURE_PATH: = "res://assets/endless/relic-memory-loom-v1.png"
const ECHO_COFFER_RELIC_TEXTURE_PATH: = "res://assets/endless/relic-echo-coffer-v1.png"
const WAYFINDER_CORE_RELIC_TEXTURE_PATH: = "res://assets/endless/relic-wayfinder-core-v1.png"
const FOUNDATION_LIGHT_POSITIONS: = [
	Vector2(420, 170),
	Vector2(1020, 170),
	Vector2(600, 825),
	Vector2(1040, 825),
]

@onready var player: CharacterBody2D = $Player
@onready var darkness: CanvasModulate = $Darkness
@onready var world_lights: Node2D = $WorldLights

var active: = false
var active_context: = ""
var hub_exit_context: = false
var elevator_status: Dictionary = {}
var movement_speed_multiplier: = 1.0
var shared_hub_light_texture: Texture2D
var interior_initialized: = false
var interior_build_count: = 0
var _relic_rope_points: Array[Vector2] = []
var _relic_rope_previous: Array[Vector2] = []
var _rope_relic_id: = ""
var _endless_status_cache: Dictionary = {}
var _relic_catalog_cache: Array[Dictionary] = []
var _relic_status_cache: Dictionary = {}
var _workshop_status_cache: Dictionary = {}
var _feedback_position: = Vector2.ZERO
var _feedback_color: = Color.TRANSPARENT
var _feedback_elapsed: = 0.0
var _feedback_duration: = 0.0
var _premium_texture_cache: Dictionary = {}
var _workshop_presentation: Dictionary = {}
var _workshop_presentation_last: Dictionary = {}
var _workshop_presentation_events: Array[String] = []
var _workshop_presentation_serial: = 0
var _workshop_presentation_cleanup_count: = 0
var _workshop_panel_preview: Dictionary = {}


func _ready() -> void :
	lit_floor_chunks = LitFloorChunksScript.new()
	add_child(lit_floor_chunks)
	lit_draw_sections = LitDrawSectionsScript.new()
	add_child(lit_draw_sections)
	static_light_field = StaticLightFieldScript.new()
	add_child(static_light_field)
	_draw_canvas = self
	_configure_player(PLAYER_SPAWN)
	player.set_facing(Vector2.RIGHT)
	player.moved.connect(_on_player_moved)
	if not RunState.changed.is_connected(_on_run_state_changed):
		RunState.changed.connect(_on_run_state_changed)


func _ensure_interior_initialized() -> void :
	if interior_initialized:
		return
	_refresh_backend_state(false, false)
	_build_lighting()
	interior_initialized = true
	interior_build_count += 1
	queue_redraw()


func set_active(enabled: bool, entering: bool = false) -> void :
	if enabled:
		_invalidate_endless_cache()
		_ensure_interior_initialized()
	active = enabled
	visible = enabled
	process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	player.control_enabled = enabled
	player.camera.enabled = enabled
	if enabled:
		_refresh_backend_state(false)
		player.prepare_visual_cache()
	else:
		player.release_visual_cache()
	if not enabled:
		_clear_workshop_presentation("inactive")
		clear_workshop_panel_preview()
		player.set_external_movement(Vector2.ZERO)
		_set_context("")
	if entering:
		player.global_position = PLAYER_SPAWN
		player.set_facing(Vector2.RIGHT)
	if enabled:
		_ensure_player_safe(Vector2.RIGHT)
		player.camera.make_current()
		player.camera.reset_smoothing()
		_on_player_moved(player.global_position)
	queue_redraw()


func entry_spawn() -> Vector2:
	return PLAYER_SPAWN


func restore_position(position: Vector2) -> void :
	player.global_position = _nearest_safe_hub_position(position)
	player.camera.reset_smoothing()
	_on_player_moved(player.global_position)


func set_external_movement(direction: Vector2) -> void :
	player.set_external_movement(direction)


func set_movement_speed_multiplier(multiplier: float) -> void :
	movement_speed_multiplier = maxf(1.0, multiplier)
	if is_node_ready():
		player.movement_speed = float(GameData.data.PLAYER_SPEED) * movement_speed_multiplier


func current_context() -> String:
	return active_context


func workshop_selection_preview(workshop_id: String) -> Dictionary:
	var status: = _workshop_status(workshop_id)
	if not bool(status.get("built", false)):
		return {}
	var selection: = _endless_loadout_selection(workshop_id)
	selection.erase("setter")
	return selection


func set_workshop_panel_preview(workshop_id: String, category: String, value: String) -> void :
	_workshop_panel_preview = {
		"workshop_id": workshop_id,
		"category": category,
		"value": value,
	}
	queue_redraw()


func clear_workshop_panel_preview() -> void :
	if _workshop_panel_preview.is_empty():
		return
	_workshop_panel_preview.clear()
	queue_redraw()


func qa_workshop_presentation_snapshot() -> Dictionary:
	var current: = _workshop_presentation.duplicate(true)
	if not current.is_empty():
		var duration: = maxf(0.001, float(current.get("duration", 1.0)))
		var progress: = clampf(float(current.get("elapsed", 0.0)) / duration, 0.0, 1.0)
		current["progress"] = progress
		current["stage"] = _workshop_presentation_stage(String(current.get("kind", "")), progress)
	return {
		"active": not current.is_empty(),
		"current": current,
		"last": _workshop_presentation_last.duplicate(true),
		"events": _workshop_presentation_events.duplicate(),
		"serial": _workshop_presentation_serial,
		"cleanup_count": _workshop_presentation_cleanup_count,
		"panel_preview": _workshop_panel_preview.duplicate(true),
	}


func qa_set_hub_relic_endpoint(position: Vector2) -> bool:


	var carried: = _carried_relic()
	var relic_id: = String(carried.get("id", carried.get("relic_id", "")))
	if relic_id.is_empty():
		return false
	var facing: Vector2 = player.facing_vector if player.facing_vector.length_squared() > 0.01 else Vector2.RIGHT
	var anchor: = player.global_position - facing * 9.0 + Vector2(0, 9)
	_rope_relic_id = relic_id
	_relic_rope_points.clear()
	_relic_rope_previous.clear()
	for index in range(RELIC_ROPE_POINTS):
		var point: = anchor.lerp(position, float(index) / float(RELIC_ROPE_POINTS - 1))
		_relic_rope_points.append(point)
		_relic_rope_previous.append(point)
	queue_redraw()
	return true


func perform_context() -> String:
	match active_context:
		"hubExit":
			hub_exit_requested.emit()
			return "hubExit"
		"deepElevator":
			deep_elevator_checked.emit()
			_use_deep_elevator()
			return "deepElevator"
		"relicPedestal":
			_place_carried_relic()
			return "relicPedestal"
		"deepHoard":
			message_changed.emit(_museum_status_message())
			return "deepHoard"
	if active_context.begins_with("workshop:"):
		var workshop_id: = active_context.trim_prefix("workshop:")
		_use_workshop(workshop_id)
		return workshop_id
	return ""


func deep_elevator_snapshot() -> Dictionary:
	var result: = elevator_status.duplicate(true)
	result["position"] = DEEP_ELEVATOR
	result["radius"] = DEEP_ELEVATOR_RADIUS
	result["visual_stage"] = _deep_elevator_visual_stage()
	return result


func runtime_contract() -> Dictionary:
	return {
		"initialized": interior_initialized,
		"build_count": interior_build_count,
		"world_size": WORLD_SIZE,
		"stations": {
			"surface_lift": {"position": SURFACE_LIFT, "radius": SURFACE_LIFT_RADIUS},
			"deep_elevator": {
				"position": DEEP_ELEVATOR,
				"radius": DEEP_ELEVATOR_RADIUS,
				"online": bool(elevator_status.get("powered", false)),
				"status": deep_elevator_snapshot(),
			},
			"deep_hoard": {
				"position": DEEP_HOARD_POSITION,
				"radius": DEEP_HOARD_RADIUS,
				"kind": "relic_museum",
				"status": _endless_status(),
			},
			"workshops": _workshop_runtime_snapshot(),
		},
		"player_spawn": PLAYER_SPAWN,
		"relic_rope": {"points": RELIC_ROPE_POINTS, "segment_length": RELIC_ROPE_SEGMENT_LENGTH},
		"deep_elevator_online": bool(elevator_status.get("powered", false)),
		"deep_elevator_repaired": bool(elevator_status.get("repaired", false)),
		"deep_elevator_status": deep_elevator_snapshot(),
		"assets": {
			"surface_lift": "res://assets/voidstar/depth-portal.png",
			"deep_elevator": "res://assets/hub/deep-elevator-terminal.png",
			"floor": "res://assets/voidstar/floor.png",
			"wall_frame": "res://assets/voidstar/wall.png",
			"route_inlay": "res://assets/starfall/route-marker.png",
			"foundation_lamp": "res://assets/entrances/depth-work-lamp.png",
		},
		"lighting": lighting_snapshot(),
	}


func lighting_snapshot() -> Dictionary:
	var elevator_light: = _deep_elevator_light_profile()
	var sources: Array[Dictionary] = [
		{"kind": "hubPlayer", "position": player.global_position if is_node_ready() else PLAYER_SPAWN, "radius": 230.0, "color": Color("ffe0a0"), "intensity": 0.72},
		{"kind": "hubLift", "position": SURFACE_LIFT, "radius": 210.0, "color": Color("72e6c7"), "intensity": 0.72},
		{
			"kind": "deepElevator",
			"position": DEEP_ELEVATOR,
			"radius": float(elevator_light.radius),
			"color": Color(elevator_light.color),
			"intensity": float(elevator_light.energy),
		},
	]
	for position_value in FOUNDATION_LIGHT_POSITIONS:
		sources.append({
			"kind": "hubSconce",
			"position": Vector2(position_value),
			"radius": 248.0,
			"color": Color("ffc77d"),
			"intensity": 0.66,
		})
	for workshop_id in _workshop_ids():
		var workshop_status: = _workshop_status(workshop_id)
		if bool(workshop_status.get("built", false)):
			sources.append({
				"kind": "workshop", "id": workshop_id,
				"position": _workshop_position(workshop_id) + Vector2(0, -18),
				"radius": 190.0, "color": _workshop_color(workshop_id), "intensity": 0.58,
			})
	return {
		"ambient": Color(0.8, 0.72, 0.6, 1.0),
		"sources": sources,
		"runtime_light_budget": {
			"fixed_lights": FOUNDATION_LIGHT_POSITIONS.size() + 3,
			"active_workshop_lights": _built_workshop_count(),
			"max_total_lights": FOUNDATION_LIGHT_POSITIONS.size() + 3 + WORKSHOP_IDS.size(),
		},
	}


func collision_at(position: Vector2) -> bool:
	return _hub_wall_collision(position)


func _process(delta: float) -> void :
	if not active:
		return

	_update_relic_rope(delta)
	_update_feedback(delta)
	_update_workshop_presentation(delta)


func _update_feedback(delta: float) -> void :
	if _feedback_duration <= 0.0:
		return
	_feedback_elapsed += maxf(0.0, delta)
	if _feedback_elapsed >= _feedback_duration:
		_feedback_duration = 0.0
	queue_redraw()


func _start_feedback(position: Vector2, color: Color, duration: float = 0.8) -> void :
	_feedback_position = position
	_feedback_color = color
	_feedback_elapsed = 0.0
	_feedback_duration = maxf(0.1, duration)
	queue_redraw()


func _start_workshop_presentation(
	workshop_id: String,
	kind: String,
	origin: Vector2,
	payload: Dictionary = {}
) -> void :
	if not _workshop_presentation.is_empty():
		_clear_workshop_presentation("replaced")
	_workshop_presentation_serial += 1
	var amount: = maxi(0, int(payload.get("amount", payload.get("cost", 0))))
	var particle_count: = 0
	match kind:
		"delivery":
			particle_count = clampi(6 + amount / 25, 6, 14)
		"build":
			particle_count = 10
		"upgrade":
			particle_count = 8
		"equip":
			particle_count = 5
	var presentation: Dictionary = {
		"serial": _workshop_presentation_serial,
		"workshop_id": workshop_id,
		"kind": kind,
		"origin": origin,
		"target": _workshop_visual_position(workshop_id),
		"elapsed": 0.0,
		"duration": float(WORKSHOP_PRESENTATION_DURATIONS.get(kind, 0.8)),
		"particle_count": particle_count,
	}
	presentation.merge(payload, true)
	_workshop_presentation = presentation
	_workshop_presentation_events.append(
		"%d:%s:%s" % [_workshop_presentation_serial, kind, workshop_id]
	)
	while _workshop_presentation_events.size() > 12:
		_workshop_presentation_events.pop_front()
	queue_redraw()


func _update_workshop_presentation(delta: float) -> void :
	if _workshop_presentation.is_empty():
		return
	_workshop_presentation["elapsed"] = (
		float(_workshop_presentation.get("elapsed", 0.0)) + maxf(0.0, delta)
	)
	if float(_workshop_presentation.elapsed) >= float(_workshop_presentation.duration):
		_clear_workshop_presentation("complete")
	queue_redraw()


func _clear_workshop_presentation(reason: String) -> void :
	if _workshop_presentation.is_empty():
		return
	_workshop_presentation_last = _workshop_presentation.duplicate(true)
	_workshop_presentation_last["cleanup_reason"] = reason
	_workshop_presentation_cleanup_count += 1
	_workshop_presentation.clear()
	queue_redraw()


func _workshop_presentation_progress(workshop_id: String = "", kind: String = "") -> float:
	if _workshop_presentation.is_empty():
		return -1.0
	if not workshop_id.is_empty() and String(_workshop_presentation.get("workshop_id", "")) != workshop_id:
		return -1.0
	if not kind.is_empty() and String(_workshop_presentation.get("kind", "")) != kind:
		return -1.0
	return clampf(
		float(_workshop_presentation.get("elapsed", 0.0))
		/ maxf(0.001, float(_workshop_presentation.get("duration", 1.0))),
		0.0,
		1.0
	)


func _workshop_presentation_stage(kind: String, progress: float) -> String:
	match kind:
		"delivery":
			return "transfer" if progress < 0.72 else "seat_materials"
		"build":
			return "foundation" if progress < 0.28 else "assembly" if progress < 0.72 else "commission"
		"upgrade":
			return "parts" if progress < 0.68 else "calibration"
		"equip":
			return "equip"
	return "idle"


func _workshop_visual_position(workshop_id: String) -> Vector2:
	return DEEP_HOARD_POSITION if workshop_id == "treasure_chamber" else _workshop_position(workshop_id)


func _update_relic_rope(delta: float) -> void :
	var carried: = _carried_relic()
	var relic_id: = String(carried.get("id", carried.get("relic_id", "")))
	if relic_id.is_empty():
		_rope_relic_id = ""
		_relic_rope_points.clear()
		_relic_rope_previous.clear()
		return
	var facing: Vector2 = player.facing_vector if player.facing_vector.length_squared() > 0.01 else Vector2.RIGHT
	var anchor: = player.global_position - facing * 9.0 + Vector2(0, 9)
	if relic_id != _rope_relic_id or _relic_rope_points.size() != RELIC_ROPE_POINTS:
		_rope_relic_id = relic_id
		_relic_rope_points.clear()
		_relic_rope_previous.clear()
		var trail_direction: = ( - facing + Vector2(0, 0.34)).normalized()
		for index in range(RELIC_ROPE_POINTS):
			var point: = anchor + trail_direction * RELIC_ROPE_SEGMENT_LENGTH * float(index)
			_relic_rope_points.append(point)
			_relic_rope_previous.append(point)
	var safe_delta: = minf(maxf(delta, 0.0), 1.0 / 30.0)
	_relic_rope_points[0] = anchor
	_relic_rope_previous[0] = anchor
	for index in range(1, _relic_rope_points.size()):
		var current: = _relic_rope_points[index]
		var velocity: = (current - _relic_rope_previous[index]) * 0.91
		_relic_rope_previous[index] = current
		_relic_rope_points[index] = current + velocity + Vector2(0, 210.0) * safe_delta * safe_delta
	for _iteration in range(RELIC_ROPE_ITERATIONS):
		_relic_rope_points[0] = anchor
		for index in range(1, _relic_rope_points.size()):
			var previous: = _relic_rope_points[index - 1]
			var current: = _relic_rope_points[index]
			var delta_vector: = current - previous
			var distance: = maxf(0.001, delta_vector.length())
			var correction: = delta_vector * ((distance - RELIC_ROPE_SEGMENT_LENGTH) / distance)
			if index == 1:
				_relic_rope_points[index] -= correction
			else:
				_relic_rope_points[index - 1] += correction * 0.48
				_relic_rope_points[index] -= correction * 0.52
			_relic_rope_points[index] = _relic_rope_points[index].clamp(Vector2(72, 72), WORLD_SIZE - Vector2(72, 72))
	queue_redraw()


func _on_run_state_changed() -> void :
	_invalidate_endless_cache()
	if not active:
		return
	_refresh_backend_state()



	call_deferred("_ensure_player_safe")
	queue_redraw()


func _invalidate_endless_cache() -> void :
	_endless_status_cache.clear()
	_relic_status_cache.clear()
	_workshop_status_cache.clear()


func _refresh_backend_state(emit_events: bool = true, rebuild_lighting: bool = true) -> void :
	var previous_elevator: = elevator_status.duplicate(true)
	elevator_status = RunState.deep_elevator_status()
	var elevator_changed: = previous_elevator != elevator_status
	if rebuild_lighting and elevator_changed and is_node_ready():
		_build_lighting()
	if not emit_events:
		return
	if elevator_changed:
		deep_elevator_status_changed.emit(deep_elevator_snapshot())


func _use_deep_elevator() -> void :
	_refresh_backend_state(false)
	if bool(elevator_status.get("victory", false)):
		var carried: = _carried_relic()
		if not carried.is_empty():
			message_changed.emit("MUSEUM PEDESTAL · PLACE %s BEFORE DESCENDING" % _relic_name(carried))
			return
		message_changed.emit("THE DEEP · TUNNEL READY")
		deep_elevator_enter_requested.emit()
		return
	if RunState.can_enter_final_expedition():
		message_changed.emit("THE DEEP · DESCENT READY")
		deep_elevator_enter_requested.emit()
		return
	var delivered_total: = 0
	for resource_id in ["ambercore", "lunacore", "furnaceheart", "singularity"]:
		var deliverable: = RunState.deep_elevator_deliverable_amount(resource_id)
		if deliverable <= 0:
			continue
		var delivery: Dictionary = RunState.deliver_deep_elevator_material(
			resource_id, deliverable
		)
		delivered_total += int(delivery.get("delivered", 0))
	_refresh_backend_state(false)
	var powered_now: = false
	if bool(elevator_status.get("ready_to_power", false)):
		powered_now = RunState.power_deep_elevator()
	_refresh_backend_state()
	if powered_now:
		message_changed.emit("DEEPHEART PASSAGE READY · ENTER WHEN READY")
	elif delivered_total > 0:
		message_changed.emit(
			"DEEPHEART PASSAGE · %d MATERIALS DELIVERED" % delivered_total
		)
	else:
		message_changed.emit(_deep_elevator_status_message())
	queue_redraw()


func _deep_elevator_status_message() -> String:
	if bool(elevator_status.get("powered", false)):
		return "DEEPHEART PASSAGE · READY TO ENTER"
	if bool(elevator_status.get("repaired", false)):
		return "DEEPHEART PASSAGE · CORE READY"
	var missing: Dictionary = Dictionary(elevator_status.get("missing", {}))
	if missing.is_empty():
		return "DEEPHEART PASSAGE · AWAITING POWER"
	var parts: Array[String] = []
	for resource_id in ["ambercore", "lunacore", "furnaceheart", "singularity"]:
		var amount: = int(missing.get(resource_id, 0))
		if amount > 0:
			parts.append("%s %d" % [resource_id.to_upper(), amount])
	return "DEEPHEART PASSAGE · NEED " + " · ".join(parts)


func _deep_hoard_status_message() -> String:
	return _museum_status_message()


func _endless_status() -> Dictionary:
	if not _endless_status_cache.is_empty():
		return _endless_status_cache.duplicate(true)
	if RunState.has_method("endless_descent_status"):
		var result: Variant = RunState.call("endless_descent_status")
		if result is Dictionary:
			_endless_status_cache = Dictionary(result).duplicate(true)
			return _endless_status_cache.duplicate(true)
	_endless_status_cache = {"unlocked": RunState.victory}
	return _endless_status_cache.duplicate(true)


func _relic_catalog_entries() -> Array[Dictionary]:
	if not _relic_catalog_cache.is_empty():
		return _relic_catalog_cache.duplicate(true)
	var entries: Array[Dictionary] = []
	if not RunState.has_method("relic_catalog"):
		return entries
	var raw: Variant = RunState.call("relic_catalog")
	if raw is Array:
		for value in Array(raw):
			if value is Dictionary:
				entries.append(Dictionary(value).duplicate(true))
	elif raw is Dictionary:
		for key_value in Dictionary(raw).keys():
			var value: Variant = Dictionary(raw).get(key_value, {})
			if value is Dictionary:
				var entry: Dictionary = Dictionary(value).duplicate(true)
				entry["id"] = String(entry.get("id", key_value))
				entries.append(entry)
	entries.sort_custom( func(left: Dictionary, right: Dictionary) -> bool:
		return String(left.get("id", "")) < String(right.get("id", ""))
	)
	_relic_catalog_cache = entries.duplicate(true)
	return _relic_catalog_cache.duplicate(true)


func _relic_status(relic_id: String) -> Dictionary:
	if relic_id.is_empty() or not RunState.has_method("relic_status"):
		return {}
	if _relic_status_cache.has(relic_id):
		return Dictionary(_relic_status_cache[relic_id]).duplicate(true)
	var result: Variant = RunState.call("relic_status", relic_id)
	var status: Dictionary = Dictionary(result).duplicate(true) if result is Dictionary else {}
	_relic_status_cache[relic_id] = status.duplicate(true)
	return status


func _relic_entry(relic_id: String) -> Dictionary:
	for definition in _relic_catalog_entries():
		if String(definition.get("id", "")) != relic_id:
			continue
		var merged: = definition.duplicate(true)
		merged.merge(_relic_status(relic_id), true)
		return merged
	var fallback: = _relic_status(relic_id)
	fallback["id"] = relic_id
	return fallback


func _carried_relic() -> Dictionary:
	var endless: = _endless_status()
	var raw: Variant = endless.get("carried_relic", endless.get("carried_relic_id", ""))
	if raw is Dictionary:
		var carried: Dictionary = Dictionary(raw).duplicate(true)
		var carried_id: = String(carried.get("id", carried.get("relic_id", "")))
		if not carried_id.is_empty():
			var merged: = _relic_entry(carried_id)
			merged.merge(carried, true)
			return merged
		return {}
	var relic_id: = String(raw)
	if not relic_id.is_empty():
		return _relic_entry(relic_id)
	for definition in _relic_catalog_entries():
		var candidate_id: = String(definition.get("id", ""))
		var status: = _relic_status(candidate_id)
		if bool(status.get("carried", false)):
			var merged: = definition.duplicate(true)
			merged.merge(status, true)
			return merged
	return {}


func _placed_relics() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in _relic_catalog_entries():
		var relic_id: = String(definition.get("id", ""))
		var status: = _relic_status(relic_id)
		if not bool(status.get("placed", status.get("displayed", false))):
			continue
		var merged: = definition.duplicate(true)
		merged.merge(status, true)
		result.append(merged)
	result.sort_custom( func(left: Dictionary, right: Dictionary) -> bool:
		return int(left.get("display_index", left.get("catalog_index", 0))) < int(right.get("display_index", right.get("catalog_index", 0)))
	)
	return result


func _workshop_status(workshop_id: String) -> Dictionary:
	if workshop_id.is_empty() or not RunState.has_method("workshop_status"):
		return {"id": workshop_id, "unlocked": false, "built": false}
	if _workshop_status_cache.has(workshop_id):
		return Dictionary(_workshop_status_cache[workshop_id]).duplicate(true)
	var result: Variant = RunState.call("workshop_status", workshop_id)
	var status: Dictionary = Dictionary(result).duplicate(true) if result is Dictionary else {}
	status["id"] = workshop_id
	_workshop_status_cache[workshop_id] = status.duplicate(true)
	return status


func _workshop_ids() -> Array[String]:
	var result: Array[String] = WORKSHOP_IDS.duplicate()
	for relic in _relic_catalog_entries():
		var workshop_id: = String(relic.get("workshop_id", relic.get("unlocks_workshop", "")))
		if not workshop_id.is_empty() and workshop_id not in result:
			result.append(workshop_id)
	return result


func _workshop_position(workshop_id: String) -> Vector2:
	if WORKSHOP_POSITIONS.has(workshop_id):
		return Vector2(WORKSHOP_POSITIONS[workshop_id])
	var slot: = posmod(workshop_id.hash(), WORKSHOP_FALLBACK_POSITIONS.size())
	return WORKSHOP_FALLBACK_POSITIONS[slot]


func _workshop_runtime_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for workshop_id in _workshop_ids():
		var status: = _workshop_status(workshop_id)
		status["position"] = _workshop_position(workshop_id)
		status["radius"] = WORKSHOP_INTERACT_RADIUS
		result[workshop_id] = status
	return result


func _built_workshop_count() -> int:
	var count: = 0
	for workshop_id in _workshop_ids():
		if bool(_workshop_status(workshop_id).get("built", false)):
			count += 1
	return count


func _nearest_workshop_id(world_position: Vector2) -> String:
	var closest_id: = ""
	var closest_distance: = WORKSHOP_INTERACT_RADIUS
	for workshop_id in _workshop_ids():
		var status: = _workshop_status(workshop_id)
		if not _workshop_unlocked(status) and not bool(status.get("built", false)):
			continue
		var distance: = world_position.distance_to(_workshop_position(workshop_id))
		if distance <= closest_distance:
			closest_id = workshop_id
			closest_distance = distance
	return closest_id


func _workshop_name(workshop_id: String, status: Dictionary = {}) -> String:
	return String(status.get("display_name", status.get("name", WORKSHOP_NAMES.get(workshop_id, workshop_id.replace("_", " ").to_upper()))))


func _workshop_resource(status: Dictionary) -> String:
	var cost: Dictionary = Dictionary(status.get("cost", {}))
	return String(status.get("build_resource", status.get("resource", status.get("resource_id", cost.get("resource", "")))))


func _workshop_required(status: Dictionary) -> int:
	var cost: Dictionary = Dictionary(status.get("cost", {}))
	return maxi(1, int(status.get("build_cost", status.get("required", status.get("required_amount", cost.get("amount", 200))))))


func _workshop_delivered(status: Dictionary) -> int:
	return maxi(0, int(status.get("delivered", status.get("delivered_amount", 0))))


func _workshop_unlocked(status: Dictionary) -> bool:
	return bool(status.get("blueprint_unlocked", status.get("unlocked", status.get("built", false))))


func _museum_status_message() -> String:
	if not RunState.victory:
		return "RELIC CHAMBER · THE DEEPHEART STILL SLEEPS"
	var carried: = _carried_relic()
	if not carried.is_empty():
		return "RELIC PEDESTAL · PRESS INTERACT TO PLACE %s" % _relic_name(carried)
	var endless: = _endless_status()
	var placed: = int(endless.get("placed_relic_count", _placed_relics().size()))
	var total: = int(endless.get("total_relics", _relic_catalog_entries().size()))
	var deepest: = int(endless.get("deepest_depth", 0))
	return "RELIC CHAMBER · %d / %d DISPLAYED · DEEPEST %d" % [placed, total, deepest]


func _relic_name(relic: Dictionary) -> String:
	return String(relic.get("display_name", relic.get("name", relic.get("id", "RELIC")))).to_upper()


func _place_carried_relic() -> void :
	var carried: = _carried_relic()
	if carried.is_empty():
		message_changed.emit("RELIC PEDESTAL · BRING A FIND FROM THE DEEP")
		return
	if _relic_rope_points.size() < 2:
		AudioDirector.play_blocked()
		message_changed.emit("RELIC PEDESTAL · HAUL THE RELIC CLOSER")
		return
	var relic_endpoint: = _relic_rope_points[_relic_rope_points.size() - 1]
	var pedestal_target: = RELIC_PEDESTAL_POSITION + Vector2(0, -16)
	var placement_distance: = relic_endpoint.distance_to(pedestal_target)
	if placement_distance > RELIC_PLACEMENT_DISTANCE:
		AudioDirector.play_blocked()
		message_changed.emit(
			"RELIC PEDESTAL · HAUL THE RELIC CLOSER · %d AWAY" % roundi(placement_distance)
		)
		_start_feedback(pedestal_target, Color("f1c768"), 0.45)
		return
	if not RunState.has_method("place_carried_relic"):
		message_changed.emit("RELIC PEDESTAL · PLACEMENT UNAVAILABLE")
		return
	var result: Variant = RunState.call("place_carried_relic")
	_invalidate_endless_cache()
	var transaction: Dictionary = Dictionary(result) if result is Dictionary else {"ok": bool(result)}
	if not bool(transaction.get("ok", false)):
		message_changed.emit("RELIC PEDESTAL · %s" % String(transaction.get("reason", "PLACEMENT UNAVAILABLE")).replace("_", " ").to_upper())
		return
	var workshop_id: = String(transaction.get("workshop_id", carried.get("workshop_id", "")))
	var workshop_name: = _workshop_name(workshop_id, _workshop_status(workshop_id))
	_rope_relic_id = ""
	_relic_rope_points.clear()
	_relic_rope_previous.clear()
	_build_lighting()
	_update_context(player.global_position)
	AudioDirector.play_discovery(true)
	_start_feedback(RELIC_PEDESTAL_POSITION + Vector2(0, -18), _relic_color(String(carried.get("id", ""))), 1.1)
	message_changed.emit("%s READY TO BUILD · YOUR RELIC SUPPLIES THE MATERIALS" % workshop_name)
	queue_redraw()


func _use_workshop(workshop_id: String) -> void :
	var status: = _workshop_status(workshop_id)
	var workshop_name: = _workshop_name(workshop_id, status)
	if not bool(status.get("valid", true)):
		message_changed.emit("%s · SITE UNAVAILABLE" % workshop_name)
		return
	if bool(status.get("built", false)):
		_open_built_workshop(workshop_id, status)
		return
	if not _workshop_unlocked(status):
		var relic_id: = String(status.get("relic_id", ""))
		var relic_name: = _relic_name(_relic_entry(relic_id)) if not relic_id.is_empty() else "ITS RELIC"
		message_changed.emit("%s · FIND AND DISPLAY %s" % [workshop_name, relic_name])
		return
	var resource_id: = _workshop_resource(status)
	var required: = _workshop_required(status)
	var delivered_before: = _workshop_delivered(status)
	var available: = maxi(0, int(RunState.cargo.get(resource_id, 0)))
	var accepted_now: = 0
	if available > 0 and delivered_before < required and RunState.has_method("deliver_workshop_material"):
		var delivery_result: Variant = RunState.call(
			"deliver_workshop_material", workshop_id, resource_id,
			mini(available, required - delivered_before)
		)
		var delivery: Dictionary = Dictionary(delivery_result) if delivery_result is Dictionary else {}
		accepted_now = maxi(0, int(delivery.get("accepted", 0)))
		_invalidate_endless_cache()
		status = _workshop_status(workshop_id)
	var delivered: = _workshop_delivered(status)
	var ready: = bool(status.get("ready_to_build", delivered >= required))


	if accepted_now > 0:
		AudioDirector.play_pickup(resource_id, accepted_now)
		_start_workshop_presentation(workshop_id, "delivery", player.global_position, {
			"amount": accepted_now,
			"resource_id": resource_id,
		})
		_start_feedback(_workshop_visual_position(workshop_id), _workshop_color(workshop_id), 0.45)
		if ready:
			message_changed.emit("%s · %d / %d DELIVERED · PRESS BUILD" % [workshop_name, delivered, required])
		else:
			message_changed.emit("%s · %d / %d %s DELIVERED" % [workshop_name, delivered, required, resource_id.replace("_", " ").to_upper()])
		queue_redraw()
		return
	if ready and RunState.has_method("build_workshop"):
		var build_origin: = player.global_position
		var build_result: Variant = RunState.call("build_workshop", workshop_id)
		_invalidate_endless_cache()
		var build: Dictionary = Dictionary(build_result) if build_result is Dictionary else {"ok": bool(build_result)}
		if bool(build.get("ok", false)):
			var workshop_position: = _workshop_position(workshop_id)
			var escape_hint: = player.global_position - workshop_position
			if escape_hint.length_squared() <= 0.01:
				escape_hint = - player.facing_vector
			_ensure_player_safe(escape_hint)
			_build_lighting()
			_update_context(player.global_position)
			AudioDirector.play_economy("build")
			_start_workshop_presentation(workshop_id, "build", build_origin, {
				"level": 1,
				"resource_id": resource_id,
			})
			var feedback_position: = _workshop_visual_position(workshop_id)
			_start_feedback(feedback_position, _workshop_color(workshop_id), 1.0)
			message_changed.emit("%s BUILT · HUB EXPANDED" % workshop_name)
			queue_redraw()
			return
	status = _workshop_status(workshop_id)
	delivered = _workshop_delivered(status)
	var remaining: = maxi(0, int(status.get("remaining", required - delivered)))
	if remaining <= 0:
		message_changed.emit("%s · READY TO BUILD" % workshop_name)
	elif available <= 0:
		message_changed.emit("%s · NEED %d %s" % [workshop_name, remaining, resource_id.replace("_", " ").to_upper()])
	else:
		message_changed.emit("%s · %d / %d %s DELIVERED" % [workshop_name, delivered, required, resource_id.replace("_", " ").to_upper()])
	queue_redraw()


func _open_built_workshop(workshop_id: String, status: Dictionary) -> void :
	var workshop_name: = _workshop_name(workshop_id, status)
	workshop_panel_requested.emit(workshop_id)
	message_changed.emit("%s · REVIEW EQUIPMENT, STYLE, AND UPGRADES" % workshop_name)


func confirm_workshop_action(workshop_id: String, action: String, value: String = "") -> Dictionary:
	var status: = _workshop_status(workshop_id)
	var workshop_name: = _workshop_name(workshop_id, status)
	if not bool(status.get("built", false)):
		return {"ok": false, "reason": "workshop_not_built", "action": action}
	var transaction: Dictionary = {
		"ok": false,
		"reason": "invalid_action",
		"workshop_id": workshop_id,
		"action": action,
		"value": value,
	}
	match action:
		"upgrade":
			if RunState.has_method("upgrade_workshop"):
				var raw_upgrade: Variant = RunState.call("upgrade_workshop", workshop_id)
				transaction = Dictionary(raw_upgrade) if raw_upgrade is Dictionary else {"ok": bool(raw_upgrade)}
				transaction["action"] = action
				transaction["workshop_id"] = workshop_id
		"equip":
			transaction = _set_endless_loadout(workshop_id, value)
			transaction["action"] = action
		"style":
			var styles: Array = Array(status.get("available_styles", []))
			if value in styles and RunState.has_method("set_workshop_style"):
				var style_changed: = bool(RunState.call("set_workshop_style", workshop_id, value))
				transaction = {
					"ok": style_changed,
					"reason": "style_applied" if style_changed else "style_unavailable",
					"workshop_id": workshop_id,
					"action": action,
					"value": value,
				}
	if not bool(transaction.get("ok", false)):
		AudioDirector.play_blocked()
		message_changed.emit("%s · %s" % [
			workshop_name,
			String(transaction.get("reason", "ACTION UNAVAILABLE")).replace("_", " ").to_upper(),
		])
		return transaction
	_invalidate_endless_cache()
	_build_lighting()
	var presentation_kind: = "upgrade" if action == "upgrade" else "equip"
	_start_workshop_presentation(workshop_id, presentation_kind, player.global_position, {
		"amount": int(transaction.get("cost", 0)),
		"resource_id": String(transaction.get("resource", "")),
		"level": int(transaction.get("level", status.get("level", 1))),
		"selection_kind": action,
		"selection": value,
	})
	_start_feedback(_workshop_visual_position(workshop_id), _workshop_color(workshop_id), 0.72)
	if action == "upgrade":
		AudioDirector.play_economy("upgrade")
		message_changed.emit("%s · UPGRADED TO LEVEL %d" % [workshop_name, int(transaction.get("level", int(status.get("level", 1)) + 1))])
	elif action == "style":
		AudioDirector.play_ui("confirm")
		message_changed.emit("%s · %s STATION STYLE APPLIED" % [workshop_name, value.replace("_", " ").to_upper()])
	else:
		AudioDirector.play_ui("confirm")
		message_changed.emit("%s · %s EQUIPPED" % [workshop_name, value.replace("_", " ").to_upper()])
	workshop_action_committed.emit(transaction.duplicate(true))
	queue_redraw()
	return transaction


func _endless_loadout_selection(workshop_id: String) -> Dictionary:
	if not RunState.has_method("endless_loadout_status"):
		return {}
	var raw: Variant = RunState.call("endless_loadout_status")
	if not raw is Dictionary:
		return {}
	var loadout: Dictionary = Dictionary(raw)
	var current_key: = ""
	var options_key: = ""
	var setter: = ""
	match workshop_id:
		"tool_forge":
			current_key = "tool"
			options_key = "tool_options"
			setter = "set_endless_tool_style"
		"light_lab":
			current_key = "light"
			options_key = "light_options"
			setter = "set_endless_light_style"
		"wardrobe":
			current_key = "outfit"
			options_key = "outfit_options"
			setter = "set_endless_outfit"
	if setter.is_empty() or not RunState.has_method(setter):
		return {}
	var options: Array = Array(loadout.get(options_key, []))
	if options.is_empty():
		return {}
	var current: = String(loadout.get(current_key, String(options[0])))
	var current_index: = options.find(current)
	var next_value: = String(options[(maxi(0, current_index) + 1) % options.size()])
	return {
		"current": current,
		"next": next_value,
		"options": options.duplicate(),
		"option_count": options.size(),
		"setter": setter,
	}


func _set_endless_loadout(workshop_id: String, value: String) -> Dictionary:
	var selection: = _endless_loadout_selection(workshop_id)
	var options: Array = Array(selection.get("options", []))
	var setter: = String(selection.get("setter", ""))
	if value.is_empty() or value not in options or setter.is_empty():
		return {"ok": false, "reason": "selection_unavailable", "workshop_id": workshop_id, "value": value}
	if value == String(selection.get("current", "")):
		return {"ok": false, "reason": "already_equipped", "workshop_id": workshop_id, "value": value}
	if not bool(RunState.call(setter, value)):
		return {"ok": false, "reason": "selection_unavailable", "workshop_id": workshop_id, "value": value}
	_invalidate_endless_cache()
	return {"ok": true, "reason": "equipped", "workshop_id": workshop_id, "value": value}


func _grouped_number(value: int) -> String:
	var digits: = str(maxi(0, value))
	var grouped: = ""
	while digits.length() > 3:
		grouped = "," + digits.substr(digits.length() - 3, 3) + grouped
		digits = digits.substr(0, digits.length() - 3)
	return digits + grouped


func _deep_elevator_visual_stage() -> String:
	if bool(elevator_status.get("victory", false)):
		return "complete"
	if bool(elevator_status.get("powered", false)):
		return "powered"
	if bool(elevator_status.get("repaired", false)):
		return "repaired"
	return "delivery"


func _configure_player(position: Vector2) -> void :
	var speed: = float(GameData.data.PLAYER_SPEED) * movement_speed_multiplier
	player.configure(position, WORLD_SIZE, speed, _resolve_motion)


func _resolve_motion(origin: Vector2, motion: Vector2) -> Vector2:
	if _hub_wall_collision(origin):
		var escape_hint: = motion
		if escape_hint.length_squared() <= 0.01:
			escape_hint = player.facing_vector
		return _nearest_safe_hub_position(origin, escape_hint)
	var result: = origin
	var next_x: = Vector2(origin.x + motion.x, origin.y)
	if not _hub_wall_collision(next_x):
		result.x = next_x.x
	var next_y: = Vector2(result.x, origin.y + motion.y)
	if not _hub_wall_collision(next_y):
		result.y = next_y.y
	return result.clamp(WALK_MIN, WALK_MAX)


func _hub_wall_collision(position: Vector2) -> bool:
	return position.x < WALK_MIN.x or position.y < WALK_MIN.y or position.x > WALK_MAX.x or position.y > WALK_MAX.y or _station_collision(position)


func player_position_clear() -> bool:
	return is_instance_valid(player) and not _hub_wall_collision(player.global_position)


func _ensure_player_safe(escape_hint: Vector2 = Vector2.ZERO) -> bool:
	if not is_instance_valid(player) or not _hub_wall_collision(player.global_position):
		return false
	var recovered: = _nearest_safe_hub_position(player.global_position, escape_hint)
	if recovered.is_equal_approx(player.global_position):
		return false
	player.global_position = recovered
	player.set_external_movement(Vector2.ZERO)
	if is_instance_valid(player.camera):
		player.camera.reset_smoothing()
	_update_context(player.global_position)
	return true


func _nearest_safe_hub_position(
	preferred: Vector2, escape_hint: Vector2 = Vector2.ZERO
) -> Vector2:
	var minimum: = WALK_MIN
	var maximum: = WALK_MAX
	var origin: = preferred.clamp(minimum, maximum)
	if not _hub_wall_collision(origin):
		return origin
	var preferred_direction: = escape_hint.normalized()
	if preferred_direction.length_squared() <= 0.01:
		preferred_direction = Vector2.RIGHT
	for ring_index in range(1, SAFE_POSITION_SEARCH_RINGS + 1):
		var radius: = float(ring_index) * SAFE_POSITION_SEARCH_STEP
		var found: = false
		var best_candidate: = origin
		var best_alignment: = - INF
		for sample_index in range(SAFE_POSITION_SEARCH_SAMPLES):
			var angle: = TAU * float(sample_index) / float(SAFE_POSITION_SEARCH_SAMPLES)
			var offset: = Vector2.from_angle(angle) * radius
			var candidate: = (origin + offset).clamp(minimum, maximum)
			if candidate.is_equal_approx(origin) or _hub_wall_collision(candidate):
				continue
			var alignment: = offset.normalized().dot(preferred_direction)
			if not found or alignment > best_alignment:
				found = true
				best_alignment = alignment
				best_candidate = candidate
		if found:
			return best_candidate
	var fallback: = PLAYER_SPAWN.clamp(minimum, maximum)
	return fallback if not _hub_wall_collision(fallback) else origin


func _station_collision(position: Vector2) -> bool:
	if RunState.victory and position.distance_to(RELIC_PEDESTAL_POSITION + Vector2(0, 12)) < 48.0 + PLAYER_RADIUS:
		return true
	if RunState.victory and bool(_workshop_status("treasure_chamber").get("built", false)):
		var chamber_offset: = position - (DEEP_HOARD_POSITION + Vector2(0, 22))
		if Vector2(chamber_offset.x / 172.0, chamber_offset.y / 94.0).length_squared() < 1.0:
			return true
	for workshop_id in _workshop_ids():
		var status: = _workshop_status(workshop_id)
		if workshop_id == "treasure_chamber" or not bool(status.get("built", false)):
			continue
		var size: Vector2 = WORKSHOP_VISIBLE_SIZES[workshop_id]
		var offset: Vector2 = position - (_workshop_position(workshop_id) + Vector2(0, 8))
		if (offset / Vector2(size.x * 0.42 + PLAYER_RADIUS, 58)).length_squared() < 1.0:
			return true
	return position.distance_to(DEEP_ELEVATOR + Vector2(0, -18)) < 70.0 + PLAYER_RADIUS


func _on_player_moved(world_position: Vector2) -> void :
	player.z_index = actor_draw_depth(world_position)
	_update_context(world_position)


func actor_draw_depth(world_position: Vector2) -> int:
	return 10 + roundi(world_position.y)


func _update_context(world_position: Vector2) -> void :
	var next: = ""
	if world_position.distance_to(SURFACE_LIFT) <= SURFACE_LIFT_RADIUS:
		next = "hubExit"
	elif world_position.distance_to(DEEP_ELEVATOR) <= DEEP_ELEVATOR_RADIUS:
		next = "deepElevator"
	elif RunState.victory:
		var workshop_id: = _nearest_workshop_id(world_position)
		if world_position.distance_to(RELIC_PEDESTAL_POSITION) <= RELIC_PEDESTAL_RADIUS:
			if not _carried_relic().is_empty():
				next = "relicPedestal"
			elif workshop_id == "treasure_chamber" and not bool(_workshop_status(workshop_id).get("built", false)):
				next = "workshop:%s" % workshop_id
			else:
				next = "deepHoard"
		elif not workshop_id.is_empty():
			next = "workshop:%s" % workshop_id
	_set_context(next)


func _set_context(next: String) -> void :
	if next == active_context:
		return
	var previous_exit: = hub_exit_context
	active_context = next
	hub_exit_context = active_context == "hubExit"
	context_changed.emit(active_context)
	if previous_exit != hub_exit_context:
		hub_exit_context_changed.emit(hub_exit_context)
	queue_redraw()


func _build_lighting() -> void :
	darkness.color = Color(0.8, 0.72, 0.6, 1.0)
	for child in world_lights.get_children():
		world_lights.remove_child(child)
		child.queue_free()
	var player_light: = player.get_node_or_null("HubPlayerLight") as PointLight2D
	if player_light == null:
		player_light = _make_light(230.0, 0.72, Color("ffe0a0"))
		player_light.name = "HubPlayerLight"
		player_light.position = Vector2.ZERO
		player.add_child(player_light)
	_add_world_light(SURFACE_LIFT, 210.0, Color("72e6c7"), "SurfaceLiftLight")
	var elevator_light: = _deep_elevator_light_profile()
	_add_world_light(
		DEEP_ELEVATOR,
		float(elevator_light.radius),
		Color(elevator_light.color),
		"DeepElevatorLight",
		float(elevator_light.energy)
	)
	for index in range(FOUNDATION_LIGHT_POSITIONS.size()):
		_add_world_light(
			Vector2(FOUNDATION_LIGHT_POSITIONS[index]),
			248.0,
			Color("ffc77d"),
			"FoundationSconce_%d" % index
		)
	for workshop_id in _workshop_ids():
		if bool(_workshop_status(workshop_id).get("built", false)):
			var light_position: = DEEP_HOARD_POSITION if workshop_id == "treasure_chamber" else _workshop_position(workshop_id)
			_add_world_light(
				light_position + Vector2(0, -18),
				190.0,
				_workshop_color(workshop_id),
				"Workshop_%s" % workshop_id,
				0.58
			)
	static_light_field.configure(self, world_lights)


func _deep_elevator_light_profile() -> Dictionary:
	match _deep_elevator_visual_stage():
		"complete":
			return {"radius": 246.0, "color": Color("aaf6e6"), "energy": 0.94}
		"powered":
			return {"radius": 230.0, "color": Color("6de8ff"), "energy": 0.88}
		"repaired":
			return {"radius": 205.0, "color": Color("f5c669"), "energy": 0.68}
	return {"radius": 176.0, "color": Color("d7a75a"), "energy": 0.42}


func _add_world_light(
	position: Vector2,
	radius: float,
	color: Color,
	light_name: String,
	energy: float = 0.72
) -> void :
	var light: = _make_light(radius, energy, color)
	light.name = light_name
	light.position = position
	world_lights.add_child(light)


func _make_light(radius: float, energy: float, color: Color) -> PointLight2D:
	var light: = PointLight2D.new()
	light.texture = _shared_hub_light_texture()
	light.texture_scale = radius / 256.0
	light.energy = energy
	light.color = color
	return light


func _shared_hub_light_texture() -> Texture2D:
	if shared_hub_light_texture != null:
		return shared_hub_light_texture
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.62), Color(1, 1, 1, 0)])
	var texture: = GradientTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	shared_hub_light_texture = texture
	return shared_hub_light_texture


func _draw() -> void :
	_draw_canvas = self
	if lit_draw_sections.enabled:
		_draw_partitioned_hub()
		return
	lit_draw_sections.hide()
	_draw_ground()
	_draw_stations()
	_draw_workshop_presentation()
	_draw_feedback()
	_draw_carried_relic()


func _draw_workshop_presentation() -> void :
	if _workshop_presentation.is_empty():
		return
	var workshop_id: = String(_workshop_presentation.get("workshop_id", ""))
	var kind: = String(_workshop_presentation.get("kind", ""))
	var progress: = _workshop_presentation_progress(workshop_id, kind)
	var origin: = Vector2(_workshop_presentation.get("origin", player.global_position))
	var target: = Vector2(_workshop_presentation.get("target", _workshop_visual_position(workshop_id)))
	var color: = _workshop_color(workshop_id)
	match kind:
		"delivery":
			_draw_workshop_delivery(origin, target, progress, color)
		"build":
			_draw_workshop_construction(workshop_id, origin, target, progress, color)
		"upgrade":
			_draw_workshop_upgrade(workshop_id, origin, target, progress, color)
		"equip":
			var alpha: = sin(PI * clampf(progress, 0.0, 1.0))
			_draw_workshop_signature(workshop_id, target + Vector2(0, -12), progress, alpha, 1.0)


func _draw_workshop_delivery(origin: Vector2, target: Vector2, progress: float, color: Color) -> void :
	var particle_count: = maxi(1, int(_workshop_presentation.get("particle_count", 8)))
	var resource_id: = String(_workshop_presentation.get("resource_id", ""))
	var material_texture: = _workshop_material_texture(resource_id)
	for index in range(particle_count):
		var delay: = float(index) / float(particle_count) * 0.42
		var travel: = clampf((progress - delay) / maxf(0.01, 1.0 - delay), 0.0, 1.0)
		if travel <= 0.0 or travel >= 1.0:
			continue
		var lane: = float(posmod(index, 5) - 2)
		var point: = _workshop_travel_point(origin, target, travel, lane)
		var alpha: = sin(PI * travel)
		if material_texture != null:
			_draw_texture_rotated_bounded(
				material_texture,
				point,
				Vector2.ONE * (24.0 + float(index % 3) * 3.0),
				travel * 2.4 + float(index),
				Color(1, 1, 1, 0.68 + alpha * 0.32)
			)
		else:
			_draw_canvas.draw_circle(point, 5.0 + float(index % 3), Color(color, 0.88))
	if progress > 0.64:
		var seat: = clampf((progress - 0.64) / 0.36, 0.0, 1.0)
		for index in range(6):
			var angle: = TAU * float(index) / 6.0 + seat * 0.5
			var start: = target + Vector2.from_angle(angle) * lerpf(38.0, 15.0, seat)
			_draw_canvas.draw_line(start, start + Vector2.from_angle(angle) * 10.0, Color(color, (1.0 - seat) * 0.72), 2.2)


func _draw_workshop_construction(
	workshop_id: String,
	origin: Vector2,
	target: Vector2,
	progress: float,
	color: Color
) -> void :
	var foundation: = clampf(progress / 0.3, 0.0, 1.0)
	var half_width: = lerpf(18.0, 74.0, foundation)
	_draw_canvas.draw_line(target + Vector2( - half_width, 42), target + Vector2(half_width, 42), Color(color, 0.78), 5.0)
	_draw_canvas.draw_line(target + Vector2( - half_width, 36), target + Vector2( - half_width, -50), Color(color, 0.42 * (1.0 - progress)), 3.0)
	_draw_canvas.draw_line(target + Vector2(half_width, 36), target + Vector2(half_width, -50), Color(color, 0.42 * (1.0 - progress)), 3.0)
	var assembly: = clampf((progress - 0.18) / 0.58, 0.0, 1.0)
	var material_texture: = _workshop_material_texture(String(_workshop_presentation.get("resource_id", "")))
	for index in range(10):
		var delay: = float(index) / 10.0 * 0.36
		var travel: = clampf((assembly - delay) / maxf(0.01, 1.0 - delay), 0.0, 1.0)
		if travel <= 0.0 or travel >= 1.0:
			continue
		var angle: = TAU * float(index) / 10.0
		var part_origin: = origin.lerp(target + Vector2.from_angle(angle) * 128.0, 0.68)
		var part_target: = target + Vector2((index % 3 - 1) * 24.0, 22.0 - float(index % 4) * 22.0)
		var point: = _workshop_travel_point(part_origin, part_target, travel, float(index % 3 - 1))
		if material_texture != null and index % 2 == 0:
			_draw_texture_rotated_bounded(material_texture, point, Vector2(27, 27), angle + travel * 2.0, Color(1, 1, 1, 0.9))
		else:
			var part_size: = Vector2(18 + index % 3 * 4, 7 + index % 2 * 4)
			_draw_canvas.draw_set_transform(point, angle + travel * 1.7, Vector2.ONE)
			_draw_canvas.draw_rect(Rect2( - part_size * 0.5, part_size), Color(color, 0.86), true)
			_draw_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if progress > 0.62:
		var commission: = clampf((progress - 0.62) / 0.38, 0.0, 1.0)
		var ghost_alpha: = sin(PI * commission) * 0.46
		_draw_canvas.draw_set_transform(target + Vector2(0, -14), 0.0, Vector2.ONE * lerpf(0.82, 1.04, commission))
		_draw_texture_bounded(_workshop_texture(workshop_id), Vector2.ZERO, Vector2(184, 124), Color(color, ghost_alpha))
		_draw_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		_draw_workshop_signature(workshop_id, target + Vector2(0, -14), commission, 1.0 - commission * 0.35, 1.15)


func _draw_workshop_upgrade(
	workshop_id: String,
	origin: Vector2,
	target: Vector2,
	progress: float,
	color: Color
) -> void :
	var material_texture: = _workshop_material_texture(String(_workshop_presentation.get("resource_id", "")))
	for index in range(8):
		var delay: = float(index) / 8.0 * 0.34
		var travel: = clampf((progress - delay) / maxf(0.01, 0.72 - delay), 0.0, 1.0)
		if travel <= 0.0 or travel >= 1.0:
			continue
		var angle: = TAU * float(index) / 8.0
		var part_origin: = origin.lerp(target + Vector2.from_angle(angle) * 104.0, 0.72)
		var part_target: = target + Vector2.from_angle(angle) * 26.0 + Vector2(0, -12)
		var point: = _workshop_travel_point(part_origin, part_target, travel, float(index % 3 - 1))
		if material_texture != null:
			_draw_texture_rotated_bounded(material_texture, point, Vector2(25, 25), - travel * 2.6 + angle, Color.WHITE)
		else:
			_draw_canvas.draw_circle(point, 6.0, Color(color, 0.92))
	var calibration: = clampf((progress - 0.58) / 0.42, 0.0, 1.0)
	if calibration > 0.0:
		_draw_workshop_signature(workshop_id, target + Vector2(0, -12), calibration, sin(PI * calibration), 1.2)
		var radius: = lerpf(34.0, 76.0, calibration)
		_draw_canvas.draw_arc(target + Vector2(0, -12), radius, - PI * 0.5, - PI * 0.5 + TAU * calibration, 40, Color(color, 0.78 * (1.0 - calibration)), 3.0)


func _draw_workshop_signature(
	workshop_id: String,
	center: Vector2,
	progress: float,
	alpha: float,
	scale: float
) -> void :
	var color: = Color(_workshop_color(workshop_id), clampf(alpha, 0.0, 1.0))
	match workshop_id:
		"tool_forge":
			var swing: = lerpf(-0.8, 0.28, clampf(progress * 1.45, 0.0, 1.0))
			_draw_canvas.draw_set_transform(center, swing, Vector2.ONE * scale)
			_draw_canvas.draw_rect(Rect2(-4, -42, 8, 60), color, true)
			_draw_canvas.draw_rect(Rect2(-23, -48, 46, 15), Color(1.0, 0.84, 0.58, color.a), true)
			_draw_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			for index in range(7):
				var angle: = -2.8 + float(index) * 0.34
				var spark_origin: = center + Vector2(0, 16)
				_draw_canvas.draw_line(spark_origin, spark_origin + Vector2.from_angle(angle) * (18.0 + index * 3.0) * scale, Color(1.0, 0.72, 0.28, color.a), 2.0)
		"light_lab":
			_draw_canvas.draw_circle(center, 19.0 * scale, Color(0.82, 1.0, 0.96, 0.12 * color.a))
			_draw_canvas.draw_arc(center, 22.0 * scale, 0, TAU, 32, color, 3.0)
			for index in range(8):
				var angle: = TAU * float(index) / 8.0 + progress * 0.45
				_draw_canvas.draw_line(center + Vector2.from_angle(angle) * 27.0 * scale, center + Vector2.from_angle(angle) * 62.0 * scale, color, 2.2)
		"wardrobe":
			for ribbon_index in range(2):
				var ribbon: = PackedVector2Array()
				for point_index in range(15):
					var ratio: = float(point_index) / 14.0
					ribbon.append(center + Vector2((ratio - 0.5) * 112.0 * scale, sin(ratio * TAU * 1.5 + progress * 4.0 + ribbon_index * PI) * 15.0 * scale + (ribbon_index * 18.0 - 9.0)))
				_draw_canvas.draw_polyline(ribbon, color, 4.0, true)
		"treasure_chamber":
			for index in range(6):
				var angle: = TAU * float(index) / 6.0 + progress * 0.7
				var point: = center + Vector2.from_angle(angle) * 50.0 * scale
				var diamond: = PackedVector2Array([point + Vector2(0, -7), point + Vector2(6, 0), point + Vector2(0, 7), point + Vector2(-6, 0)])
				_draw_canvas.draw_colored_polygon(diamond, color)
		"lift_workshop":
			_draw_canvas.draw_arc(center, 45.0 * scale, - PI * 0.5, - PI * 0.5 + TAU * clampf(progress * 1.2, 0.0, 1.0), 36, color, 3.0)
			for index in range(4):
				var angle: = PI * 0.5 * index
				_draw_canvas.draw_line(center + Vector2.from_angle(angle) * 16.0 * scale, center + Vector2.from_angle(angle) * 38.0 * scale, color, 3.0)
			var arrow: = PackedVector2Array([center + Vector2(0, -34) * scale, center + Vector2(10, -10) * scale, center, center + Vector2(-10, -10) * scale])
			_draw_canvas.draw_colored_polygon(arrow, color)


func _workshop_travel_point(origin: Vector2, target: Vector2, progress: float, lane: float) -> Vector2:
	var direction: = target - origin
	var perpendicular: = Vector2( - direction.y, direction.x).normalized()
	var control: = origin.lerp(target, 0.5) + perpendicular * lane * 13.0 + Vector2(0, -54.0 - absf(lane) * 5.0)
	var inverse: = 1.0 - progress
	return origin * inverse * inverse + control * 2.0 * inverse * progress + target * progress * progress


func _workshop_material_texture(resource_id: String) -> Texture2D:
	var path: String = String({
		"deep_alloy": "res://assets/endless/node-deep-alloy-v1.png",
		"lumenstone": "res://assets/endless/node-lumen-shard-v1.png",
		"memory_silk": "res://assets/endless/node-memory-silk-v1.png",
		"echo_crystal": "res://assets/endless/node-echo-crystal-v1.png",
		"waystone": "res://assets/endless/node-waystone-v1.png",
	}.get(resource_id, ""))
	return _premium_texture(path) if not path.is_empty() else null


func _draw_feedback() -> void :
	if _feedback_duration <= 0.0:
		return
	var progress: = clampf(_feedback_elapsed / _feedback_duration, 0.0, 1.0)
	var eased: = 1.0 - pow(1.0 - progress, 3.0)
	var alpha: = pow(1.0 - progress, 1.7)
	var radius: = lerpf(28.0, 112.0, eased)
	_draw_canvas.draw_circle(_feedback_position, radius * 0.72, Color(_feedback_color, 0.035 * alpha))
	_draw_canvas.draw_arc(_feedback_position, radius, 0, TAU, 64, Color(_feedback_color, 0.82 * alpha), 3.2)
	_draw_canvas.draw_arc(_feedback_position, radius * 0.72, 0, TAU, 48, Color(1, 0.94, 0.78, 0.34 * alpha), 1.5)


func _draw_ground() -> void :
	_draw_ground_border()
	_draw_floor_surface()
	_draw_hub_wall_frame()
	_draw_foundation_route()
	_draw_foundation_sconces()


func _draw_ground_border() -> void:
	# Opaque floor covers the interior; these borders do not overlap it.
	_draw_canvas.draw_rect(Rect2(0, 0, WORLD_SIZE.x, 48), Color("08090e"), true)
	_draw_canvas.draw_rect(Rect2(0, WORLD_SIZE.y - 48, WORLD_SIZE.x, 48), Color("08090e"), true)
	_draw_canvas.draw_rect(Rect2(0, 48, 54, WORLD_SIZE.y - 96), Color("08090e"), true)
	_draw_canvas.draw_rect(Rect2(WORLD_SIZE.x - 54, 48, 54, WORLD_SIZE.y - 96), Color("08090e"), true)


func _draw_floor_surface() -> void:
	var interior: Rect2 = Rect2(54, 48, WORLD_SIZE.x - 108, WORLD_SIZE.y - 96)
	lit_floor_chunks.draw_floor(self, HUB_FLOOR_TEXTURE, interior, Color(0.96, 0.84, 0.72, 1.0), Color(0.18, 0.075, 0.018, 0.12))


func _draw_partitioned_hub() -> void:
	_draw_floor_surface()
	lit_draw_sections.begin(self)
	lit_draw_sections.add(_draw_ground_border)
	lit_draw_sections.add(_draw_hub_wall_frame)
	lit_draw_sections.add(_draw_foundation_route)
	for position_value in FOUNDATION_LIGHT_POSITIONS:
		lit_draw_sections.add(_draw_foundation_sconce.bind(Vector2(position_value)))
	lit_draw_sections.add(_draw_deep_elevator.bind(active_context == "deepElevator"), null, actor_draw_depth(DEEP_ELEVATOR + Vector2(0, 50)))
	lit_draw_sections.add(_draw_lift.bind(SURFACE_LIFT, false, active_context == "hubExit"), null, actor_draw_depth(SURFACE_LIFT))
	if RunState.victory:
		for workshop_id in _workshop_ids():
			if workshop_id == "treasure_chamber": continue
			var status: Dictionary = _workshop_status(workshop_id)
			if not _workshop_unlocked(status) and not bool(status.get("built", false)): continue
			lit_draw_sections.add(_draw_workshop_site.bind(workshop_id, status, active_context == "workshop:%s" % workshop_id), null, actor_draw_depth(_workshop_position(workshop_id) + Vector2(0, 30)))
		lit_draw_sections.add(_draw_relic_museum.bind(active_context in ["deepHoard", "relicPedestal", "workshop:treasure_chamber"]), null, actor_draw_depth(DEEP_HOARD_POSITION + Vector2(0, 80)))
	lit_draw_sections.add(_draw_workshop_presentation, null, 2000)
	lit_draw_sections.add(_draw_feedback, null, 2000)
	lit_draw_sections.add(_draw_carried_relic, null, actor_draw_depth(player.position))
	lit_draw_sections.finish()


func _draw_hub_wall_frame() -> void :
	_draw_canvas.draw_rect(Rect2(0, 0, WORLD_SIZE.x, 58), Color("111015"), true)
	_draw_canvas.draw_rect(Rect2(0, WORLD_SIZE.y - 54, WORLD_SIZE.x, 54), Color("111015"), true)
	_draw_canvas.draw_rect(Rect2(0, 0, 58, WORLD_SIZE.y), Color("111015"), true)
	_draw_canvas.draw_rect(Rect2(WORLD_SIZE.x - 58, 0, 58, WORLD_SIZE.y), Color("111015"), true)
	for center_x in [236.0, 720.0, 1204.0]:
		_draw_painted_span(HUB_WALL_TEXTURE, Vector2(center_x, 0), 520.0, 0.0, Color(0.9, 0.88, 0.94, 1.0))
		_draw_painted_span(HUB_WALL_TEXTURE, Vector2(center_x, WORLD_SIZE.y), 520.0, PI, Color(0.74, 0.7, 0.78, 1.0))
	for center_y in [250.0, 566.0, 842.0]:
		_draw_painted_span(HUB_WALL_TEXTURE, Vector2(20, center_y), 350.0, -PI * 0.5, Color(0.76, 0.74, 0.8, 1.0))
		_draw_painted_span(HUB_WALL_TEXTURE, Vector2(WORLD_SIZE.x - 20, center_y), 350.0, PI * 0.5, Color(0.76, 0.74, 0.8, 1.0))


func _draw_foundation_route() -> void :
	_draw_painted_span(HUB_ROUTE_TEXTURE, Vector2(336, 821), 250.0, 0.0, Color(0.98, 0.88, 0.66, 0.95))
	_draw_painted_span(HUB_ROUTE_TEXTURE, Vector2(430, 780), 176.0, 0.0, Color(0.88, 0.82, 0.66, 0.86))
	_draw_painted_span(HUB_ROUTE_TEXTURE, Vector2(720, 220), 282.0, 0.0, Color(0.88, 0.78, 0.58, 0.86))
	if not RunState.victory:
		return
	for workshop_id in _workshop_ids():
		var status: = _workshop_status(workshop_id)
		if workshop_id == "treasure_chamber" or not bool(status.get("built", false)):
			continue
		var destination: = _workshop_position(workshop_id)
		var span: float = 126.0 if workshop_id in ["tool_forge", "lift_workshop"] else 106.0
		_draw_painted_span(HUB_ROUTE_TEXTURE, destination + Vector2(0, 48), span, 0.0, Color(0.92, 0.88, 0.8, 0.9))


func _draw_foundation_sconces() -> void :
	for position_value in FOUNDATION_LIGHT_POSITIONS:
		_draw_foundation_sconce(Vector2(position_value))


func _draw_foundation_sconce(at: Vector2) -> void:
	_draw_painted_span(HUB_ROUTE_TEXTURE, at + Vector2(0, 6), 58.0, 0.0, Color(0.9, 0.85, 0.78, 1.0))
	_draw_ellipse_shape(at + Vector2(0, 6), Vector2(23, 7), Color(0, 0, 0, 0.4))
	_draw_texture_grounded(HUB_LAMP_TEXTURE, at + Vector2(0, 7), Vector2(43, 30), Color(1.0, 0.88, 0.68, 1.0))


func _draw_stations() -> void :
	_draw_deep_elevator(active_context == "deepElevator")
	_draw_lift(SURFACE_LIFT, false, active_context == "hubExit")
	if RunState.victory:
		_draw_workshops()
		_draw_relic_museum(active_context in ["deepHoard", "relicPedestal", "workshop:treasure_chamber"])


func _draw_lift(position: Vector2, locked: bool, _selected: bool) -> void :
	_draw_ellipse_shape(position + Vector2(0, 43), Vector2(78, 23), Color(0, 0, 0, 0.45))
	_draw_texture_bounded(PORTAL_TEXTURE, position + Vector2(0, -27), Vector2(178, 154))
	if locked:
		_draw_canvas.draw_rect(Rect2(position + Vector2(-50, -39), Vector2(100, 74)), Color(0.024, 0.035, 0.051, 0.64), true)
		for x in range(-36, 37, 24):
			_draw_canvas.draw_line(position + Vector2(x, -38), position + Vector2(x, 35), Color("8b7540"), 5.0)
		_draw_canvas.draw_circle(position + Vector2(0, -1), 8, Color("d0ae55"))


func _workshop_color(workshop_id: String) -> Color:
	match workshop_id:
		"tool_forge":
			return Color("ef9a52")
		"light_lab":
			return Color("8be7e0")
		"wardrobe":
			return Color("cf8cf0")
		"treasure_chamber":
			return Color("f1c768")
		"lift_workshop":
			return Color("83b8f5")
	return Color("a8d8bd")


func _draw_workshops() -> void :
	for workshop_id in _workshop_ids():
		if workshop_id == "treasure_chamber":
			continue
		var status: = _workshop_status(workshop_id)
		if not _workshop_unlocked(status) and not bool(status.get("built", false)):
			continue
		_draw_workshop_site(
			workshop_id, status,
			active_context == "workshop:%s" % workshop_id
		)


func _draw_workshop_site(workshop_id: String, status: Dictionary, _selected: bool) -> void :
	var interaction_position: = _workshop_position(workshop_id)
	var color: = _workshop_color(workshop_id)
	var built: = bool(status.get("built", false))
	var required: = _workshop_required(status)
	var delivered: = _workshop_delivered(status)
	var progress: = clampf(float(delivered) / float(required), 0.0, 1.0)
	var is_chamber: = workshop_id == "treasure_chamber"
	var position: = DEEP_HOARD_POSITION if is_chamber else interaction_position
	if built:
		var footprint_width: float = 160.0 if is_chamber else float(WORKSHOP_VISIBLE_SIZES[workshop_id].x) * 0.46
		_draw_ellipse_shape(position + Vector2(0, 24), Vector2(footprint_width, 27), Color(0, 0, 0, 0.3))
	else:
		_draw_ellipse_shape(position + Vector2(0, 26), Vector2(76, 25), Color(0, 0, 0, 0.37))
		_draw_ellipse_shape(position + Vector2(0, 17), Vector2(67, 18), Color("302a28"))
		_draw_canvas.draw_arc(position + Vector2(0, 4), 57.0, - PI * 0.5, - PI * 0.5 + TAU * progress, 28, Color(color, 0.86), 5.0)
		var material_texture: = _workshop_material_texture(_workshop_resource(status))
		var staged_parts: = ceili(progress * 5.0)
		var stage_offsets: Array[Vector2] = [
			Vector2(-43, 10), Vector2(-22, 21), Vector2(2, 15), Vector2(27, 19), Vector2(43, 7),
		]
		for stage_index in range(staged_parts):
			var part_position: = position + stage_offsets[stage_index]
			if material_texture != null:
				_draw_texture_rotated_bounded(material_texture, part_position, Vector2(28, 24), float(stage_index) * 0.42, Color(1, 1, 1, 0.76))
			else:
				_draw_canvas.draw_circle(part_position, 7.0, Color(color, 0.72))
	if not is_chamber:
		var build_progress: = _workshop_presentation_progress(workshop_id, "build")
		var workshop_alpha: = 1.0 if build_progress < 0.0 else lerpf(0.16, 1.0, clampf((build_progress - 0.3) / 0.48, 0.0, 1.0))
		_draw_workshop_icon(workshop_id, position, built, color, workshop_alpha, status)
	else:
		_draw_ellipse_shape(interaction_position + Vector2(0, 22), Vector2(34, 11), Color(0, 0, 0, 0.35))
		_draw_canvas.draw_rect(Rect2(interaction_position - Vector2(22, 28), Vector2(44, 54)), Color("302b32"), true)
		_draw_canvas.draw_rect(Rect2(interaction_position - Vector2(22, 28), Vector2(44, 54)), Color(color, 0.62), false, 2.0)
		_draw_canvas.draw_circle(interaction_position + Vector2(0, -7), 7.0, Color(color, 0.82 if built else 0.36))
	if not is_chamber and not built:
		var title_y: float = position.y - float(WORKSHOP_VISIBLE_SIZES[workshop_id].y) + 26.0
		var title: = _workshop_name(workshop_id, status)
		_draw_centered_text(title, Vector2(position.x, title_y), 14, Color(color, 0.96))
		var resource_id: = _workshop_resource(status).replace("_", " ").to_upper()
		_draw_centered_text("%d / %d %s" % [delivered, required, resource_id], Vector2(position.x, title_y + 19), 12, Color(0.91, 0.87, 0.76, 0.86))


func _draw_workshop_icon(
	workshop_id: String,
	position: Vector2,
	built: bool,
	color: Color,
	alpha: float = 1.0,
	status: Dictionary = {}
) -> void :
	var finish_id: = String(status.get("style", "original"))
	if (
		String(_workshop_panel_preview.get("workshop_id", "")) == workshop_id
		and String(_workshop_panel_preview.get("category", "")) == "style"
	):
		finish_id = String(_workshop_panel_preview.get("value", finish_id))
	var finish_tint: Color = Color({
		"original": Color.WHITE,
		"riveted": Color("d7e0e3"),
		"crystal": Color("b7fff4"),
		"starforged": Color("dec8ff"),
		"deepheart": Color("b9ffc8"),
	}.get(finish_id, Color.WHITE))
	var tint: = Color(finish_tint, alpha) if built else Color(0.48, 0.46, 0.43, 0.68)
	if built:
		_draw_canvas.draw_circle(position + Vector2(0, -4), 68.0, Color(color, 0.045 * alpha))
	_draw_texture_grounded(_workshop_texture(workshop_id), position + Vector2(0, 46), WORKSHOP_VISIBLE_SIZES[workshop_id], tint)
	if not built or finish_id == "original":
		return
	var finish_color: Color = {
		"riveted": Color("d8c58f"),
		"crystal": Color("79f3e5"),
		"starforged": Color("c39aff"),
		"deepheart": Color("72f29b"),
	}.get(finish_id, color)
	_draw_canvas.draw_arc(position + Vector2(0, 1), 72.0, PI, TAU, 28, Color(finish_color, 0.42 * alpha), 2.0)
	if finish_id == "riveted":
		for offset in [Vector2(-58, -34), Vector2(58, -34), Vector2(-58, 30), Vector2(58, 30)]:
			_draw_canvas.draw_circle(position + offset, 3.1, Color(finish_color, 0.82 * alpha))
	elif finish_id == "crystal":
		for offset in [Vector2(-63, -9), Vector2(63, -9)]:
			var center: Vector2 = position + Vector2(offset)
			var diamond: PackedVector2Array = PackedVector2Array([center + Vector2(0, -8), center + Vector2(5, 0), center + Vector2(0, 8), center + Vector2(-5, 0)])
			_draw_canvas.draw_colored_polygon(diamond, Color(finish_color, 0.74 * alpha))
	elif finish_id == "starforged":
		for index in range(5):
			var angle: = TAU * float(index) / 5.0 - PI * 0.5
			_draw_canvas.draw_circle(position + Vector2.from_angle(angle) * 72.0, 2.8, Color(finish_color, 0.86 * alpha))
	elif finish_id == "deepheart":
		_draw_canvas.draw_circle(position + Vector2(0, -5), 75.0, Color(finish_color, 0.045 * alpha))


func _workshop_texture(workshop_id: String) -> Texture2D:
	match workshop_id:
		"tool_forge":
			return _premium_texture(TOOL_FORGE_WORKSHOP_TEXTURE_PATH)
		"light_lab":
			return _premium_texture(LIGHT_LAB_WORKSHOP_TEXTURE_PATH)
		"wardrobe":
			return _premium_texture(WARDROBE_WORKSHOP_TEXTURE_PATH)
		"lift_workshop":
			return _premium_texture(LIFT_WORKSHOP_TEXTURE_PATH)
	return _premium_texture(TOOL_FORGE_WORKSHOP_TEXTURE_PATH)


func _premium_texture(path: String) -> Texture2D:
	if _premium_texture_cache.has(path):
		return _premium_texture_cache[path] as Texture2D
	var texture: Texture2D = load(path) as Texture2D
	if texture != null:
		_premium_texture_cache[path] = texture
	return texture


func _draw_centered_text(text: String, center: Vector2, font_size: int, color: Color) -> void :
	if text.is_empty():
		return
	var font: Font = ThemeDB.fallback_font
	_draw_canvas.draw_string(font, center - Vector2(130, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 260.0, font_size, color)


func _draw_relic_museum(selected: bool) -> void :
	var chamber_status: = _workshop_status("treasure_chamber")
	var chamber_built: = bool(chamber_status.get("built", false))
	var museum_color: = _workshop_color("treasure_chamber")
	_draw_ellipse_shape(DEEP_HOARD_POSITION + Vector2(0, 111), Vector2(202, 38), Color(0, 0, 0, 0.44))
	if chamber_built:
		_draw_canvas.draw_circle(DEEP_HOARD_POSITION + Vector2(0, -4), 180.0, Color(museum_color, 0.035))
		_draw_texture_bounded(_premium_texture(TREASURE_CHAMBER_TEXTURE_PATH), DEEP_HOARD_POSITION, Vector2(460, 307))
	else:
		_draw_texture_bounded(
			_premium_texture(TREASURE_CHAMBER_TEXTURE_PATH),
			DEEP_HOARD_POSITION,
			Vector2(460, 307),
			Color(0.42, 0.4, 0.38, 0.3)
		)
		_draw_canvas.draw_arc(DEEP_HOARD_POSITION + Vector2(0, 35), 126.0, - PI * 0.5, PI * 1.5, 56, Color(museum_color, 0.18), 3.0)
	_draw_ellipse_shape(RELIC_PEDESTAL_POSITION + Vector2(0, 40), Vector2(67, 20), Color(0, 0, 0, 0.44))
	_draw_texture_bounded(
		_premium_texture(RELIC_PEDESTAL_TEXTURE_PATH),
		RELIC_PEDESTAL_POSITION + Vector2(0, -4),
		Vector2(148, 111),
		Color.WHITE if chamber_built or not _carried_relic().is_empty() else Color(0.84, 0.8, 0.74, 0.88)
	)
	var relics: = _placed_relics()
	var slots: = _museum_slot_positions(maxi(5, _relic_catalog_entries().size()))
	for index in range(slots.size()):
		var slot: = slots[index]
		if index >= relics.size():
			_draw_canvas.draw_circle(slot + Vector2(0, -21), 15.0, Color(museum_color, 0.025 if chamber_built else 0.012))
			continue
		var relic: Dictionary = relics[index]
		_draw_relic_shape(relic, slot + Vector2(0, -25), 0.56)
	var placed_count: = relics.size()
	var total_count: = _relic_catalog_entries().size()
	var chamber_title: = "TREASURE CHAMBER" if chamber_built else "RELIC CHAMBER"
	if selected:
		_draw_centered_text("%s · %d / %d" % [chamber_title, placed_count, total_count], DEEP_HOARD_POSITION + Vector2(0, -164), 15, Color(museum_color, 0.96))
	if _workshop_unlocked(chamber_status) and not chamber_built:
		var delivered: = _workshop_delivered(chamber_status)
		var required: = _workshop_required(chamber_status)
		var resource_id: = _workshop_resource(chamber_status).replace("_", " ").to_upper()
		_draw_centered_text("BUILD · %d / %d %s" % [delivered, required, resource_id], DEEP_HOARD_POSITION + Vector2(0, -146), 11, Color(museum_color, 0.9))


func _museum_slot_positions(slot_count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var count: = maxi(1, slot_count)
	for index in range(count):
		var x: = DEEP_HOARD_POSITION.x + (float(index) - float(count - 1) * 0.5) * 48.0
		var y: = DEEP_HOARD_POSITION.y + 70.0
		result.append(Vector2(x, y))
	return result


func _relic_color(relic_id: String) -> Color:
	match relic_id:
		"forge_heart":
			return Color("ff8658")
		"ancient_lens":
			return Color("74e4e0")
		"memory_loom":
			return Color("dca2f2")
		"echo_coffer":
			return Color("f0c668")
		"wayfinder_core":
			return Color("76aef5")
	var hue: = float(posmod(relic_id.hash(), 360)) / 360.0
	return Color.from_hsv(hue, 0.48, 0.94)


func _draw_relic_shape(relic: Dictionary, position: Vector2, scale_factor: float = 1.0) -> void :
	var relic_id: = String(relic.get("id", relic.get("relic_id", "relic")))
	var color: = _relic_color(relic_id)
	var shadow_size: = Vector2(30, 9) * scale_factor
	_draw_ellipse_shape(position + Vector2(0, 31) * scale_factor, shadow_size, Color(0, 0, 0, 0.42))
	_draw_canvas.draw_circle(position, 35.0 * scale_factor, Color(color, 0.045))
	var texture: = _relic_texture(relic_id)
	if texture != null:
		_draw_texture_bounded(texture, position, Vector2.ONE * 96.0 * scale_factor)
	else:
		_draw_canvas.draw_circle(position, 24.0 * scale_factor, Color(color, 0.75))
		_draw_canvas.draw_arc(position, 23.0 * scale_factor, 0, TAU, 28, Color(color, 0.98), 3.0 * scale_factor)


func _relic_texture(relic_id: String) -> Texture2D:
	match relic_id:
		"forge_heart":
			return _premium_texture(FORGE_HEART_RELIC_TEXTURE_PATH)
		"ancient_lens":
			return _premium_texture(ANCIENT_LENS_RELIC_TEXTURE_PATH)
		"memory_loom":
			return _premium_texture(MEMORY_LOOM_RELIC_TEXTURE_PATH)
		"echo_coffer":
			return _premium_texture(ECHO_COFFER_RELIC_TEXTURE_PATH)
		"wayfinder_core":
			return _premium_texture(WAYFINDER_CORE_RELIC_TEXTURE_PATH)
	return null


func _draw_carried_relic() -> void :
	if _relic_rope_points.size() < 2:
		return
	var carried: = _carried_relic()
	if carried.is_empty():
		return
	var rope: = PackedVector2Array(_relic_rope_points)
	_draw_canvas.draw_polyline(rope, Color(0.13, 0.08, 0.045, 0.72), 7.0, true)
	_draw_canvas.draw_polyline(rope, Color("c39757"), 3.2, true)
	for index in range(1, _relic_rope_points.size() - 1, 2):
		_draw_canvas.draw_circle(_relic_rope_points[index], 2.4, Color("efd29a"))
	var relic_position: = _relic_rope_points[_relic_rope_points.size() - 1]
	_draw_relic_shape(carried, relic_position, 0.9)
	_draw_centered_text(_relic_name(carried), relic_position + Vector2(0, -57), 11, Color(0.95, 0.84, 0.64, 0.94))


func _draw_deep_elevator(_selected: bool) -> void :
	var stage: = _deep_elevator_visual_stage()
	var modulate: = Color(0.72, 0.73, 0.76, 1.0)
	if stage == "repaired":
		modulate = Color(0.96, 0.9, 0.76, 1.0)
	elif stage == "powered":
		modulate = Color(0.93, 1.0, 1.0, 1.0)
	elif stage == "complete":
		modulate = Color(0.96, 1.0, 0.9, 1.0)
	_draw_ellipse_shape(DEEP_ELEVATOR + Vector2(0, 104), Vector2(135, 31), Color(0, 0, 0, 0.46))
	if stage in ["powered", "complete"]:
		var aura_color: = Color(0.3, 0.92, 1.0, 0.12) if stage == "powered" else Color(0.62, 1.0, 0.76, 0.14)
		_draw_canvas.draw_circle(DEEP_ELEVATOR + Vector2(0, 6), 148, aura_color)
	_draw_texture_bounded(
		DEEP_ELEVATOR_TERMINAL_TEXTURE,
		DEEP_ELEVATOR + Vector2(0, 3),
		Vector2(304, 304),
		modulate
	)
	_draw_elevator_resource_sockets()
	if stage in ["powered", "complete"]:
		var pulse: = 0.62 + sin(float(Time.get_ticks_msec()) * 0.004) * 0.1
		_draw_canvas.draw_arc(
			DEEP_ELEVATOR + Vector2(0, 4),
			52,
			0,
			TAU,
			48,
			Color(0.54, 0.98, 1.0, pulse),
			2.2
		)


func _draw_elevator_resource_sockets() -> void :
	var delivered: Dictionary = Dictionary(elevator_status.get("deliveries", {}))
	var recipe: Dictionary = Dictionary(elevator_status.get("recipe", {}))
	for resource_value in ELEVATOR_RESOURCE_ORDER:
		var resource_id: = String(resource_value)
		var required: = maxi(1, int(recipe.get(resource_id, 1)))
		var progress: = clampf(float(delivered.get(resource_id, 0)) / float(required), 0.0, 1.0)
		var socket_position: = DEEP_ELEVATOR + Vector2(ELEVATOR_SOCKET_OFFSETS[resource_id])
		var resource_color: = Color(ELEVATOR_RESOURCE_COLORS[resource_id])
		_draw_canvas.draw_circle(socket_position, 14.0, Color(resource_color, 0.035 + progress * 0.13))
		_draw_canvas.draw_arc(
			socket_position,
			10.0,
			- PI * 0.5,
			- PI * 0.5 + TAU * progress,
			18,
			Color(resource_color, 0.3 + progress * 0.62),
			2.4
		)
		if progress >= 1.0:
			_draw_canvas.draw_circle(socket_position, 4.2, Color(resource_color, 0.88))


func _draw_painted_span(texture: Texture2D, center: Vector2, span: float, rotation: float, tint: Color) -> void:
	var painted: Rect2 = Rect2(6, 65, 500, 208) if texture == HUB_WALL_TEXTURE else Rect2(15, 132, 482, 121)
	var scale_factor: float = span / painted.size.x
	# Preserve the whole image and its aspect; position by the visible stone,
	# not the large transparent canvas surrounding the authored artwork.
	_draw_canvas.draw_set_transform(center, rotation, Vector2.ONE)
	_draw_hub_texture_rect(texture, Rect2(-painted.get_center() * scale_factor, texture.get_size() * scale_factor), tint)
	_draw_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_texture_bounded(texture: Texture2D, center: Vector2, bounds: Vector2, modulate: Color = Color.WHITE) -> void :
	var source: = Vector2(texture.get_size())
	var scale_factor: = minf(bounds.x / maxf(1.0, source.x), bounds.y / maxf(1.0, source.y))
	var size: = source * scale_factor
	_draw_hub_texture_rect(texture, Rect2(center - size * 0.5, size), modulate)


func _draw_texture_grounded(texture: Texture2D, feet: Vector2, bounds: Vector2, tint: Color) -> void:
	if not _hub_texture_regions.has(texture):
		_hub_texture_regions[texture] = Rect2(texture.get_image().get_used_rect())
	var painted: Rect2 = _hub_texture_regions[texture]
	var scale_factor: float = minf(bounds.x / painted.size.x, bounds.y / painted.size.y)
	var origin: Vector2 = feet - Vector2(painted.get_center().x, painted.end.y) * scale_factor
	_draw_canvas.draw_texture_rect_region(texture, Rect2(origin + painted.position * scale_factor, painted.size * scale_factor), painted, tint, false, false)


func _draw_texture_rotated_bounded(texture: Texture2D, center: Vector2, bounds: Vector2, rotation: float, modulate: Color = Color.WHITE) -> void :
	var source: = Vector2(texture.get_size())
	var scale_factor: = minf(bounds.x / maxf(1.0, source.x), bounds.y / maxf(1.0, source.y))
	var size: = source * scale_factor
	_draw_canvas.draw_set_transform(center, rotation, Vector2.ONE)
	_draw_hub_texture_rect(texture, Rect2( - size * 0.5, size), modulate)
	_draw_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_hub_texture_rect(texture: Texture2D, destination: Rect2, tint: Color) -> void:
	if not trimmed_hub_texture_margins or texture.resource_path not in [
		"res://assets/voidstar/wall.png", "res://assets/starfall/route-marker.png",
		TREASURE_CHAMBER_TEXTURE_PATH, RELIC_PEDESTAL_TEXTURE_PATH,
	]:
		_draw_canvas.draw_texture_rect(texture, destination, false, tint)
		return
	var source_size: Vector2 = texture.get_size()
	if not _hub_texture_regions.has(texture):
		var region: Rect2i = Rect2i(Vector2i.ZERO, Vector2i(source_size))
		var bitmap: Image = texture.get_image()
		# Derive from the actual resource, so later approved art changes cannot be
		# clipped by stale bounds. The two transparent texels retain bilinear edges.
		if bitmap != null and not bitmap.is_empty() and not bitmap.has_mipmaps():
			var painted: Rect2i = bitmap.get_used_rect()
			if painted.has_area():
				region = painted.grow(2).intersection(region)
		_hub_texture_regions[texture] = Rect2(region)
	var source: Rect2 = _hub_texture_regions[texture]
	var ratio: Vector2 = destination.size / source_size
	var trimmed: Rect2 = Rect2(destination.position + source.position * ratio, source.size * ratio)
	_draw_canvas.draw_texture_rect_region(texture, trimmed, source, tint, false, false)


func _draw_ellipse_shape(center: Vector2, radii: Vector2, color: Color) -> void :
	var points: = PackedVector2Array()
	for index in 32:
		var angle: = TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	_draw_canvas.draw_colored_polygon(points, color)
