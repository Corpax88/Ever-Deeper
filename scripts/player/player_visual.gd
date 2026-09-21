extends Node2D
## Native, complete-body animation: both hands and tool are in the same frame.
const Gear = preload("res://scripts/player/hero_gear.gd")
const ClothShader = preload("res://scripts/player/dad_cloth.gdshader")
const FlowGraph = preload("res://scripts/player/hero_flow_graph.gd")
const NativeWorn = preload("res://scripts/player/native_worn_visual.gd")
const ROOT: = "res://assets/hero/dad/"
const GROUND_Y: = 2.8125
const WALK_STRIDE: = 144.0
const OUTFIT_COLORS: = {
	"miner": Color("254833"), "expedition": Color("226d8a"),
	"archivist": Color("676653"), "starweave": Color("67458a"),
	"deepheart": Color("8f3435"),
}
var direction_name: = "down"
var mining: = false
var moving: = false
var mining_progress: = 0.0
var strike_phase: = 0.36
var active_endless_outfit_style: = "miner"
var active_endless_tool_style: = "original"
var active_gear: = ""
var _wanted_gear: = ""
var _atlases: Dictionary = {}
var _manifest: Dictionary = {}
var _sprite: Sprite2D
var _cloth: ShaderMaterial
var _applied_outfit: = ""
var _idle_clock: = 0.0
var _walk_phase: = 0.0
var _walk_settle: = false
var _walk_target: = 0.0
var _drill_clock: = 0.0
var _recover_phase: = -1.0
var _recover_direction: = 1.0
var _last_native_phase: = 0.0
var _last_requested_native_phase: = 0.0
var _last_frame: = -1
var _last_state: = "idle"
var _last_local_frame: = 0
var _last_direction: = ""
var _released: = false
var _impact_serial: int = 0
var _impact_presented_frame: int = -1
var _impact_direction: String = ""
var _impact_pending: bool = false
var redraw_request_count: = 0
var state_update_count: = 0
var state_skip_count: = 0
var flow_graph_enabled: bool = false
var _flow_graph: RefCounted = FlowGraph.new()
var _flow_manifest: Dictionary = {}
var _flow_visible: bool = false
var _flow_distance: float = 0.0
var _native_worn: Node

func _ready() -> void:
	process_priority = 1000
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.region_enabled = true
	_sprite.region_filter_clip_enabled = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_cloth = ShaderMaterial.new()
	_cloth.shader = ClothShader
	_sprite.material = _cloth
	add_child(_sprite)
	if OS.has_feature("ever_deeper_dev") and DisplayServer.get_name() != "headless" and bool(ProjectSettings.get_setting_with_override("native_worn/enabled")):
		_native_worn = NativeWorn.new()
		_native_worn.setup(self)
		add_child(_native_worn)
	prepare_visual_cache()

func advance_motion(distance: float, _delta: float) -> void:
	_flow_distance += distance
	if distance > 0.001:
		var stride: float = float(Dictionary(_manifest.get("motion", {})).get("stride_pixels", WALK_STRIDE))
		_walk_phase = fposmod(_walk_phase + distance / maxf(1.0, stride), 1.0)

func set_state(direction: String, _frame: int, walking: bool, active: bool = false, progress: float = 0.0, _recoil: float = 0.0, hit_phase: float = -1.0, impact_serial: int = 0) -> void:
	state_update_count += 1
	_flow_graph.note_state(active)
	if impact_serial != _impact_serial:
		_impact_serial = impact_serial
		_impact_presented_frame = Engine.get_frames_drawn()
		_impact_direction = direction
		_impact_pending = DisplayServer.get_name() != "headless"
	if moving and not walking and not active:
		_walk_settle = true
		_walk_target = roundf(_walk_phase * 2.0) * 0.5
	if walking or active: _walk_settle = false
	if mining and not active and not walking:
		# Settle through real recovery poses instead of snapping to the idle hand.
		_recover_phase = _last_native_phase
		_recover_direction = -1.0 if _last_requested_native_phase < 0.55 else 1.0
	if active or walking:
		_recover_phase = -1.0
	direction_name = direction if direction in Gear.DIRECTIONS else "down"
	moving = walking
	mining = active
	mining_progress = clampf(progress, 0.0, 1.0)
	strike_phase = hit_phase if hit_phase > 0.0 else _mechanical_hit_phase()
	_refresh_equipment()
	if not _released:
		_draw_frame(0.0)

func _mechanical_hit_phase() -> float:
	if int(RunState.drill_level) > 0: return 0.2
	match String(RunState.starforge_variant):
		"crusher": return 0.66
		"swift": return 0.28
		"prospector": return 0.42
	return 0.36

func _refresh_equipment() -> void:
	active_endless_outfit_style = RunState.endless_outfit
	active_endless_tool_style = RunState.endless_tool_style
	var next: = Gear.resolve_tool(int(RunState.pickaxe_level), int(RunState.drill_level), String(RunState.starforge_variant), active_endless_tool_style)
	if _cloth != null and active_endless_outfit_style != _applied_outfit:
		_cloth.set_shader_parameter("cloth_color", OUTFIT_COLORS.get(active_endless_outfit_style, OUTFIT_COLORS.miner))
		_cloth.set_shader_parameter("recolor", 0.0 if active_endless_outfit_style == "miner" else 1.0)
		_applied_outfit = active_endless_outfit_style
	if _released or next == _wanted_gear:
		return
	_wanted_gear = next
	Gear.request(next)
	_poll_equipment()

func _poll_equipment() -> void:
	Gear.poll()
	if Gear.current_gear != _wanted_gear or active_gear == _wanted_gear:
		return
	_atlases = Gear.textures
	_manifest = Gear.manifest
	_flow_manifest = Gear.flow_manifest
	_flow_graph.reset()
	_flow_graph.configure(_flow_manifest)
	_flow_visible = false
	active_gear = _wanted_gear
	_last_frame = -1
	_last_direction = ""

func _process(delta: float) -> void:
	if _released or not is_visible_in_tree(): return
	_poll_equipment()
	_idle_clock = fposmod(_idle_clock + delta, 3.6)
	_drill_clock += delta
	_draw_frame(delta)
	if _native_worn != null:
		_sprite.visible = not _native_worn.advance(delta)
	_flow_distance = 0.0

func _native_phase(progress: float) -> float:
	# The authored contact is phase .55. Gameplay remains authoritative.
	if progress <= strike_phase:
		return progress / strike_phase * 0.55
	return 0.55 + (progress - strike_phase) / (1.0 - strike_phase) * 0.45

func _draw_frame(delta: float) -> void:
	if _manifest.is_empty() or _sprite == null: return
	var state: = "idle"
	var phase: = _idle_clock / 3.6
	if _impact_pending and (Engine.get_frames_drawn() != _impact_presented_frame or moving):
		_impact_pending = false
	var presenting_impact: bool = _impact_pending and String(_manifest.family) != "drill"
	var displayed_direction: String = _impact_direction if presenting_impact else direction_name
	if _draw_flow(delta, presenting_impact, displayed_direction):
		return
	if presenting_impact:
		# Damage and its authored contact share one actually presented frame,
		# even when a slow frame advances beyond the contact sample.
		state = "mine"
		phase = float(_manifest.native_impact)
		_last_native_phase = phase
	elif mining:
		state = "mine"
		phase = _native_phase(mining_progress)
		if String(_manifest.family) == "drill":
			phase = fposmod(_drill_clock, 1.0)
		_last_native_phase = phase
	elif _recover_phase >= 0.0 and String(_manifest.family) != "drill":
		state = "mine"
		_recover_phase += delta * 4.0 * _recover_direction
		phase = clampf(_recover_phase, 0.0, 0.9999)
		if _recover_phase >= 1.0 or _recover_phase <= 0.0: _recover_phase = -1.0
	elif moving or _walk_settle:
		state = "walk"
		if _walk_settle:
			_walk_phase = move_toward(_walk_phase, _walk_target, delta * 3.0)
			if is_equal_approx(_walk_phase, _walk_target):
				_walk_settle = false
				_walk_phase = fposmod(_walk_phase, 1.0)
		phase = _walk_phase
	var info: Dictionary = _manifest.states[state]
	var local_frame: int = _sample_frame(info, phase, state == "walk" or (state == "mine" and String(_manifest.family) == "drill"))
	if state == "idle":
		local_frame = 0
		for i in Array(info.times).size():
			if float(info.times[i]) <= _idle_clock: local_frame = i
	if state == "mine":
		# A nearby contact sample does not mean the mechanical strike occurred.
		_last_requested_native_phase = phase
		_last_native_phase = _sample_phase(info, local_frame)
	var index: = int(info.offset) + local_frame
	_last_state = state
	_last_local_frame = local_frame
	if index == _last_frame and displayed_direction == _last_direction:
		state_skip_count += 1
		return
	var base: = ROOT + active_gear + "/" + displayed_direction
	_sprite.texture = _atlases[base + ".png"]
	_cloth.set_shader_parameter("cloth_mask", _atlases[base + "-cloth.png"])
	var cell: = Vector2(float(_manifest.cell[0]), float(_manifest.cell[1]))
	var columns: = int(_manifest.columns)
	_sprite.region_rect = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	var anchor: Array = _manifest.directions[displayed_direction].ground_anchor
	# Same feet anchor in every view/state; character size does not affect physics.
	var display_scale: = 1.0
	_sprite.scale = Vector2.ONE * display_scale
	_sprite.position = Vector2(0, GROUND_Y) - Vector2(float(anchor[0]), float(anchor[1])) * display_scale
	_last_frame = index
	_last_direction = displayed_direction
	redraw_request_count += 1


func _draw_flow(delta: float, impact: bool, direction: String) -> bool:
	if not flow_graph_enabled or active_gear != "worn" or direction != "up" or _flow_manifest.is_empty():
		if _flow_visible:
			_last_frame = -1
			_last_direction = ""
		_flow_visible = false
		_flow_graph.reset()
		return false
	# State packets can arrive several times before one draw. Keep the actual
	# shown source until the single ordered animation update chooses its edge.
	if delta <= 0.0:
		return true
	var selected: Dictionary = _flow_graph.step(delta, mining, moving, mining_progress, strike_phase,
		impact, _walk_phase, _last_state, _last_local_frame, _flow_distance)
	if selected.is_empty():
		_flow_visible = false
		return false
	var bank: String = selected.bank
	var index: int = int(selected.cell)
	var columns: int = int(_flow_manifest.columns)
	var anchor: Array = _flow_manifest.anchor
	var cell := Vector2(float(_flow_manifest.cell[0]), float(_flow_manifest.cell[1]))
	if bank == "exits":
		var profile: Dictionary = _flow_manifest.exit_profile
		index += int(_flow_manifest.exits[selected.edge].offset)
		var page := int(index / int(profile.page_capacity))
		index = index % int(profile.page_capacity)
		columns = int(profile.columns)
		cell = Vector2(float(profile.cell[0]), float(profile.cell[1]))
		anchor = profile.anchor
		var base: String = Gear.FLOW_ROOT + "exits-%02d" % page
		_sprite.texture = _atlases[base + ".png"]
		_cloth.set_shader_parameter("cloth_mask", _atlases[base + "-cloth.png"])
	elif bank == "legacy_walk":
		index += int(_manifest.states.walk.offset)
		columns = int(_manifest.columns)
		anchor = _manifest.directions.up.ground_anchor
		_sprite.texture = _atlases[ROOT + "worn/up.png"]
		_cloth.set_shader_parameter("cloth_mask", _atlases[ROOT + "worn/up-cloth.png"])
	else:
		if bank == "edges": index += int(_flow_manifest.edges[selected.edge].offset)
		_sprite.texture = _atlases[Gear.FLOW_ROOT + bank + ".png"]
		_cloth.set_shader_parameter("cloth_mask", _atlases[Gear.FLOW_ROOT + bank + "-cloth.png"])
	_sprite.material = _cloth
	_sprite.region_rect = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	_sprite.position = Vector2(0, GROUND_Y) - Vector2(float(anchor[0]), float(anchor[1]))
	_sprite.scale = Vector2.ONE
	if delta > 0.0 and selected.has("resume_walk_phase"):
		_walk_phase = float(selected.resume_walk_phase)
	_walk_settle = false
	_recover_phase = -1.0
	_flow_visible = true
	_last_frame = -1
	_last_direction = ""
	_last_state = "mine" if mining else "walk" if moving else "idle"
	_last_local_frame = int(selected.cell)
	if selected.has("resume_walk_phase"):
		_last_state = "walk"
		_last_local_frame = roundi(float(selected.resume_walk_phase) * 48.0)
	redraw_request_count += 1
	return true


func _sample_phase(info: Dictionary, index: int) -> float:
	if info.has("phases"):
		return float(info.phases[index])
	return float(info.times[index]) / maxf(0.001, float(info.duration))


func _sample_frame(info: Dictionary, phase: float, looping: bool) -> int:
	# Nonuniform native samples include the actual impact and authored bridges.
	# Pick the closest declared sample, never infer its time from atlas position.
	var best: int = 0
	var best_distance: float = INF
	for index in int(info.count):
		var distance: float = absf(_sample_phase(info, index) - phase)
		if looping: distance = minf(distance, 1.0 - distance)
		if distance < best_distance:
			best_distance = distance
			best = index
	return best

func cancel_pending_impact() -> void:
	_impact_pending = false


func prepare_visual_cache() -> void:
	_released = false
	_impact_pending = false
	_wanted_gear = ""
	_refresh_equipment()

func release_visual_cache() -> void:
	if _native_worn != null: _native_worn.suspend()
	_released = true
	_impact_pending = false
	_atlases = {}
	_manifest = {}
	_flow_manifest = {}
	_flow_graph.reset()
	_flow_visible = false
	active_gear = ""
	_wanted_gear = ""
	if _sprite != null: _sprite.texture = null
	if _cloth != null: _cloth.set_shader_parameter("cloth_mask", null)

func grounding_snapshot() -> Dictionary:
	return {"walk": GROUND_Y, "side_mining": GROUND_Y, "up_mining": GROUND_Y, "drill_walk": GROUND_Y, "drill_mining": GROUND_Y}

func native_worn_snapshot() -> Dictionary:
	return _native_worn.snapshot() if _native_worn != null else {"active":false,"failed":false}

func tool_visual_snapshot() -> Dictionary:
	return {"gear": active_gear, "pickaxe_level": int(RunState.pickaxe_level), "endless_outfit_style": active_endless_outfit_style, "endless_tool_style": active_endless_tool_style, "native_two_handed": true, "direction": direction_name, "frame": _last_frame, "state": _last_state, "local_frame": _last_local_frame, "native_phase": _last_native_phase, "hit_phase": strike_phase, "textures_loaded": _atlases.size()}

func mobile_render_budget_snapshot() -> Dictionary:
	return {"redraw_requests": redraw_request_count, "state_updates": state_update_count, "state_skips": state_skip_count, "tool_signature": active_gear, "walk_fps": 60.0, "state_change_driven": true, "textures_loaded": _atlases.size(), "runtime_3d": bool(native_worn_snapshot().active)}
