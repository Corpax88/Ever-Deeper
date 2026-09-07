extends Node2D
## Native, complete-body animation: both hands and tool are in the same frame.
const Gear = preload("res://scripts/player/hero_gear.gd")
const ClothShader = preload("res://scripts/player/dad_cloth.gdshader")
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
var _idle_clock: = 0.0
var _walk_phase: = 0.0
var _walk_settle: = false
var _walk_target: = 0.0
var _drill_clock: = 0.0
var _recover_phase: = -1.0
var _recover_direction: = 1.0
var _last_native_phase: = 0.0
var _last_frame: = -1
var _last_direction: = ""
var _released: = false
var redraw_request_count: = 0
var state_update_count: = 0
var state_skip_count: = 0

func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.region_enabled = true
	_sprite.region_filter_clip_enabled = true
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_cloth = ShaderMaterial.new()
	_cloth.shader = ClothShader
	_sprite.material = _cloth
	add_child(_sprite)
	prepare_visual_cache()

func advance_motion(distance: float, delta: float) -> void:
	if distance > 0.001:
		_walk_phase = fposmod(_walk_phase + minf(distance / WALK_STRIDE, delta * 2.8), 1.0)

func set_state(direction: String, _frame: int, walking: bool, active: bool = false, progress: float = 0.0, _recoil: float = 0.0, hit_phase: float = -1.0) -> void:
	state_update_count += 1
	if moving and not walking and not active:
		_walk_settle = true
		_walk_target = roundf(_walk_phase * 2.0) * 0.5
	if walking or active: _walk_settle = false
	if mining and not active:
		# Settle through real recovery poses instead of snapping to the idle hand.
		_recover_phase = _last_native_phase
		_recover_direction = -1.0 if _last_native_phase < 0.55 else 1.0
	if active:
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
	var status: Dictionary = RunState.endless_loadout_status()
	active_endless_outfit_style = String(status.get("outfit", "miner"))
	active_endless_tool_style = String(status.get("tool", "original"))
	var next: = Gear.resolve_tool(int(RunState.pickaxe_level), int(RunState.drill_level), String(RunState.starforge_variant), active_endless_tool_style)
	if _cloth != null:
		_cloth.set_shader_parameter("cloth_color", OUTFIT_COLORS.get(active_endless_outfit_style, OUTFIT_COLORS.miner))
		_cloth.set_shader_parameter("recolor", 0.0 if active_endless_outfit_style == "miner" else 1.0)
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
	active_gear = _wanted_gear
	_last_frame = -1
	_last_direction = ""

func _process(delta: float) -> void:
	if _released or not is_visible_in_tree(): return
	_poll_equipment()
	_idle_clock = fposmod(_idle_clock + delta, 3.6)
	_drill_clock += delta
	_draw_frame(delta)

func _native_phase(progress: float) -> float:
	# The authored contact is phase .55. Gameplay remains authoritative.
	if progress <= strike_phase:
		return progress / strike_phase * 0.55
	return 0.55 + (progress - strike_phase) / (1.0 - strike_phase) * 0.45

func _draw_frame(delta: float) -> void:
	if _manifest.is_empty() or _sprite == null: return
	var state: = "idle"
	var phase: = _idle_clock / 3.6
	if mining:
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
	var local_frame: = mini(roundi(phase * int(info.count)), int(info.count) - 1)
	if state == "idle":
		local_frame = 0
		for i in Array(info.times).size():
			if float(info.times[i]) <= _idle_clock: local_frame = i
	var index: = int(info.offset) + local_frame
	if index == _last_frame and direction_name == _last_direction:
		state_skip_count += 1
		return
	var base: = ROOT + active_gear + "/" + direction_name
	_sprite.texture = _atlases[base + ".png"]
	_cloth.set_shader_parameter("cloth_mask", _atlases[base + "-cloth.png"])
	var cell: = Vector2(float(_manifest.cell[0]), float(_manifest.cell[1]))
	var columns: = int(_manifest.columns)
	_sprite.region_rect = Rect2(Vector2(index % columns, index / columns) * cell, cell)
	var anchor: Array = _manifest.directions[direction_name].ground_anchor
	# Same feet anchor in every view/state; character size does not affect physics.
	var display_scale: = 1.0
	_sprite.scale = Vector2.ONE * display_scale
	_sprite.position = Vector2(0, GROUND_Y) - Vector2(float(anchor[0]), float(anchor[1])) * display_scale
	_last_frame = index
	_last_direction = direction_name
	redraw_request_count += 1

func prepare_visual_cache() -> void:
	_released = false
	_wanted_gear = ""
	_refresh_equipment()

func release_visual_cache() -> void:
	_released = true
	_atlases = {}
	_manifest = {}
	active_gear = ""
	_wanted_gear = ""
	if _sprite != null: _sprite.texture = null
	if _cloth != null: _cloth.set_shader_parameter("cloth_mask", null)

func grounding_snapshot() -> Dictionary:
	return {"walk": GROUND_Y, "side_mining": GROUND_Y, "up_mining": GROUND_Y, "drill_walk": GROUND_Y, "drill_mining": GROUND_Y}

func tool_visual_snapshot() -> Dictionary:
	return {"gear": active_gear, "pickaxe_level": int(RunState.pickaxe_level), "endless_outfit_style": active_endless_outfit_style, "endless_tool_style": active_endless_tool_style, "native_two_handed": true, "direction": direction_name, "frame": _last_frame, "native_phase": _last_native_phase, "hit_phase": strike_phase, "textures_loaded": _atlases.size()}

func mobile_render_budget_snapshot() -> Dictionary:
	return {"redraw_requests": redraw_request_count, "state_updates": state_update_count, "state_skips": state_skip_count, "tool_signature": active_gear, "walk_fps": 60.0, "state_change_driven": true, "textures_loaded": _atlases.size(), "runtime_3d": false}
