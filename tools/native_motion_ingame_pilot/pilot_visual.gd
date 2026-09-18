extends Node2D
## Bounded opt-in consumer for the actual schema-2 Worn/up return bank.
## This does not replace production assets or buffer unsupported player input.
const Gear = preload("res://scripts/player/hero_gear.gd")
const ClothShader = preload("res://scripts/player/dad_cloth.gdshader")
const ROOT := "res://tools/native_motion_ingame_pilot/assets/worn/"
const GROUND_Y := 2.8125
const SPEED := 340.0
const STRIDE := 88.0
const MINE_SECONDS := 0.68
const HIT_PROGRESS := 0.42
const OUTFIT_COLORS := {"miner": Color("254833"), "expedition": Color("226d8a"), "archivist": Color("676653"), "starweave": Color("67458a"), "deepheart": Color("8f3435")}
var selected_direction := "up"
var direction_name := ""
var moving := false
var mining := false
var mining_progress := 0.0
var strike_phase := HIT_PROGRESS
var active_gear := "worn"
var active_endless_outfit_style := "miner"
var active_endless_tool_style := "original"
var redraw_request_count := 0
var state_update_count := 0
var state_skip_count := 0
var fatal_error := ""
var transitions: Array[Dictionary] = []
var _manifest: Dictionary = {}
var _sprite: Sprite2D
var _cloth: ShaderMaterial
var _atlases: Dictionary = {}
var _page_key := ""
var _released := false
var _armed := false
var _state := "idle"
var _bridge: Dictionary = {}
var _offset := Vector2.ZERO
var _incoming_offset := Vector2.ZERO
var _distance := 0.0
var _walk_origin_distance := 0.0
var _walk_origin_phase := 0.0
var _bridge_origin_distance := 0.0
var _last_motion_speed := 0.0
var _last_motion_tick := -1
var _last_frame := -1
var _last_selected: Dictionary = {}
var _last_presented: Dictionary = {}
var _impact_serial := 0
var _impact_pending := false
var _pending_requests := 0
var _last_request_process_frame := 0


func _ready() -> void:
	# World/controller state packets settle before one presentation decision.
	process_priority = 1000
	_manifest = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.region_enabled = true
	_sprite.region_filter_clip_enabled = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_cloth = ShaderMaterial.new()
	_cloth.shader = ClothShader
	_sprite.material = _cloth
	add_child(_sprite)
	RenderingServer.frame_post_draw.connect(_confirm_presented)
	prepare_visual_cache()


func arm() -> bool:
	if DisplayServer.get_name() == "headless":
		_fail("Headless state cannot certify a presented native source pose")
		return false
	if direction_name != selected_direction or moving or mining:
		_fail("Arm requires actual supported idle direction")
		return false
	_armed = true
	_state = "idle"
	_distance = 0.0
	_offset = Vector2.ZERO
	_last_selected = {}
	_last_presented = {}
	return true


func disarm() -> void:
	_armed = false


func advance_motion(distance: float, delta: float) -> void:
	_distance += distance
	_last_motion_speed = distance / delta if delta > 0.0 else 0.0
	_last_motion_tick = Engine.get_physics_frames()


func set_state(direction: String, _frame: int, walking: bool, active: bool = false, progress: float = 0.0, _recoil: float = 0.0, hit_phase: float = -1.0, impact_serial: int = 0) -> void:
	state_update_count += 1
	_pending_requests += 1
	_last_request_process_frame = Engine.get_process_frames()
	if impact_serial != _impact_serial:
		_impact_serial = impact_serial
		_impact_pending = true
	direction_name = direction
	moving = walking
	mining = active
	mining_progress = clampf(progress, 0.0, 1.0)
	strike_phase = hit_phase


func _process(_delta: float) -> void:
	if not _armed or _released or not fatal_error.is_empty() or not is_visible_in_tree(): return
	if direction_name != selected_direction:
		_fail("Direction outside this one-view case: " + direction_name)
		return
	if Gear.resolve_tool(int(RunState.pickaxe_level), int(RunState.drill_level), String(RunState.starforge_variant), String(RunState.endless_tool_style)) != "worn":
		_fail("Gear is outside the actual Worn bank")
		return
	if mining and (moving or not is_equal_approx(strike_phase, HIT_PROGRESS)):
		_fail("Incompatible normal mining state or mechanical hit clock")
		return
	if moving and absf(_last_motion_speed - SPEED) > 0.1:
		_fail("Actual movement differs from the authored 340 px/s")
		return
	var wanted := "mine" if mining else "walk" if moving else "idle"
	if wanted != _state:
		if not _bridge.is_empty():
			_fail("Input interrupted an active bridge; no authored coverage")
			return
		if not _start_bridge(wanted): return
	var state := _state
	var phase := _canonical_phase()
	var elapsed := 0.0
	var crossing: Dictionary = {}
	if not _bridge.is_empty():
		elapsed = mining_progress * MINE_SECONDS if _state == "mine" else (_distance - _bridge_origin_distance) / SPEED
		if elapsed < float(_bridge.duration):
			state = String(_bridge.name)
			phase = clampf(elapsed / float(_bridge.duration), 0.0, 1.0)
		else:
			var destination: Array = _bridge.destination_offset_pixels
			_offset = _incoming_offset + Vector2(float(destination[0]), float(destination[1]))
			crossing = {"event": "canonical_handoff", "name": _bridge.name, "duration": _bridge.duration, "actual_elapsed": elapsed, "nominal_destination_phase": _bridge.destination_phase, "requested_phase": phase, "offset": _array(_offset)}
			_bridge = {}
	var presenting_impact := _impact_pending and mining
	if presenting_impact:
		if not _bridge.is_empty():
			_fail("Actual hit unexpectedly occurs inside the entry bridge")
			return
		state = "mine"
		phase = 0.55
	_draw_sample(state, phase, elapsed, presenting_impact)
	if not crossing.is_empty():
		crossing["selected_phase"] = _last_selected.sample_phase
		crossing["sample"] = _last_selected.duplicate(true)
		transitions.append(crossing)
	_pending_requests = 0


func _start_bridge(wanted: String) -> bool:
	if _last_presented.is_empty() or bool(_last_presented.is_bridge):
		_fail("Bridge source was not a presented canonical native sample")
		return false
	var source_state: String = _last_presented.state
	var source_phase: float = float(_last_presented.sample_phase)
	var name := "%s_to_%s-%06d" % [source_state, wanted, roundi(source_phase * 1000000.0)]
	var bank: Dictionary = _manifest.directions[selected_direction].transitions
	if not bank.has(name):
		_fail("No exact authored bridge for displayed source: " + name)
		return false
	var info: Dictionary = bank[name]
	if source_state != _state or not is_equal_approx(float(info.source_phase), source_phase):
		_fail("Exact source state/phase mismatch")
		return false
	_bridge = info.duplicate(true)
	_bridge["name"] = name
	_state = wanted
	_incoming_offset = _offset
	_bridge_origin_distance = float(_last_presented.total_distance)
	if wanted == "walk":
		_walk_origin_distance = _bridge_origin_distance
		_walk_origin_phase = float(info.target_start_phase)
	transitions.append({"event": "bridge_start", "name": name, "source": _last_presented.duplicate(true), "incoming_offset": _array(_offset), "pending_request_count": _pending_requests, "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames()})
	return true


func _canonical_phase() -> float:
	if _state == "walk": return fposmod(_walk_origin_phase + (_distance - _walk_origin_distance) / STRIDE, 1.0)
	if _state == "mine":
		if mining_progress <= HIT_PROGRESS: return mining_progress / HIT_PROGRESS * 0.55
		return 0.55 + (mining_progress - HIT_PROGRESS) / (1.0 - HIT_PROGRESS) * 0.45
	return 0.0


func _draw_sample(state: String, phase: float, elapsed: float, impact: bool) -> void:
	var info: Dictionary = _manifest.states[state]
	var local := 0
	var best := INF
	for index in int(info.count):
		# Nearest-frame rounding must not present contact before gameplay hits.
		# Contact is held throughout .55--.625; excluding only .55 would
		# select the next hold cell early. Pre-hit selection stays in windup.
		if state == "mine" and not impact and mining_progress < HIT_PROGRESS and float(info.phases[index]) >= 0.55:
			continue
		var difference := absf(float(info.phases[index]) - phase)
		if state in ["walk", "mine"]: difference = minf(difference, 1.0 - difference)
		if difference < best:
			best = difference
			local = index
	if not _load_page(int(info.page)): return
	active_endless_outfit_style = String(RunState.endless_outfit)
	active_endless_tool_style = String(RunState.endless_tool_style)
	_cloth.set_shader_parameter("cloth_color", OUTFIT_COLORS.get(active_endless_outfit_style, OUTFIT_COLORS.miner))
	_cloth.set_shader_parameter("recolor", 0.0 if active_endless_outfit_style == "miner" else 1.0)
	var cell := Vector2(float(_manifest.cell[0]), float(_manifest.cell[1]))
	var index := int(info.offset) + local
	var columns := int(_manifest.columns)
	_sprite.region_rect = Rect2(Vector2(index % columns, floori(float(index) / columns)) * cell, cell)
	var anchor: Array = _manifest.directions[selected_direction].ground_anchor
	_sprite.scale = Vector2.ONE
	var placement := _incoming_offset if not _bridge.is_empty() else _offset
	_sprite.position = Vector2(0.0, GROUND_Y) - Vector2(float(anchor[0]), float(anchor[1])) + placement
	if _last_frame == index: state_skip_count += 1
	else: redraw_request_count += 1
	_last_frame = index
	_last_selected = {"state": state, "logical_state": _state, "direction": selected_direction, "requested_phase": phase, "sample_phase": float(info.phases[local]), "local_frame": local, "atlas_frame": index, "page": int(info.page), "region": [_sprite.region_rect.position.x, _sprite.region_rect.position.y, cell.x, cell.y], "is_bridge": not _bridge.is_empty(), "bridge_elapsed": elapsed, "retained_offset": _array(placement), "sprite_position": _array(_sprite.position), "ground_anchor": anchor, "total_distance": _distance, "actual_speed": _last_motion_speed, "motion_physics_frame": _last_motion_tick, "mining_progress": mining_progress, "impact_serial": _impact_serial, "presenting_impact": impact, "coalesced_request_count": _pending_requests, "last_request_process_frame": _last_request_process_frame, "selection_process_frame": Engine.get_process_frames(), "selection_physics_frame": Engine.get_physics_frames(), "actually_presented": false}


func _load_page(page: int) -> bool:
	var key := selected_direction + ":" + str(page)
	if key == _page_key: return true
	_atlases.clear()
	var pages: Array = _manifest.directions[selected_direction].pages
	if page < 0 or page >= pages.size():
		_fail("Unknown native atlas page")
		return false
	var spec: Dictionary = pages[page]
	var beauty := load(ROOT + String(spec.texture)) as Texture2D
	var cloth := load(ROOT + String(spec.cloth)) as Texture2D
	if beauty == null or cloth == null:
		_fail("Native beauty/cloth page failed to load")
		return false
	_atlases = {"beauty": beauty, "cloth": cloth}
	_sprite.texture = beauty
	_cloth.set_shader_parameter("cloth_mask", cloth)
	_page_key = key
	return true


func _confirm_presented() -> void:
	if not _armed or _released or _last_selected.is_empty() or DisplayServer.get_name() == "headless": return
	_last_presented = _last_selected.duplicate(true)
	_last_presented["actually_presented"] = true
	_last_presented["drawn_frame"] = Engine.get_frames_drawn()
	if bool(_last_presented.presenting_impact): _impact_pending = false


func presented_snapshot() -> Dictionary:
	return _last_presented.duplicate(true)


func cancel_pending_impact() -> void:
	_impact_pending = false


func prepare_visual_cache() -> void:
	_released = false
	active_gear = "worn"
	if _sprite != null and not _manifest.is_empty(): _load_page(0)


func release_visual_cache() -> void:
	_released = true
	_atlases.clear()
	_page_key = ""
	if _sprite != null: _sprite.texture = null
	if _cloth != null: _cloth.set_shader_parameter("cloth_mask", null)


func grounding_snapshot() -> Dictionary:
	return {"walk": GROUND_Y, "side_mining": GROUND_Y, "up_mining": GROUND_Y}


func tool_visual_snapshot() -> Dictionary:
	return {"gear": active_gear, "state": _last_selected.get("state", "idle"), "direction": direction_name, "frame": _last_frame, "native_phase": _last_selected.get("sample_phase", 0.0), "textures_loaded": _atlases.size(), "native_two_handed": true, "hit_phase": strike_phase}


func mobile_render_budget_snapshot() -> Dictionary:
	return {"redraw_requests": redraw_request_count, "state_updates": state_update_count, "state_skips": state_skip_count, "textures_loaded": _atlases.size(), "tool_signature": active_gear, "runtime_3d": false}


func _array(value: Vector2) -> Array:
	return [value.x, value.y]


func _fail(reason: String) -> void:
	if fatal_error.is_empty():
		fatal_error = reason
		# The harness saves the failing draw and exits nonzero with its report.
		# Do not let the outer runtime-error watchdog kill it before that write.
		print("NATIVE_PILOT_UNSUPPORTED: " + reason)
