class_name CinematicCamera2D
extends Camera2D




@export_category("Framing")
@export_range(0.5, 0.8, 0.01) var player_screen_y_ratio: float = 0.68
@export_range(0.0, 256.0, 1.0, "or_greater") var maximum_vertical_offset: float = 180.0

@export_category("Horizontal Lookahead")
@export_range(0.0, 160.0, 1.0, "or_greater") var lookahead_distance: float = 48.0
@export_range(1.0, 800.0, 1.0, "or_greater") var full_lookahead_speed: float = 260.0
@export_range(0.0, 100.0, 1.0, "or_greater") var lookahead_deadzone_speed: float = 18.0
@export_range(0.1, 20.0, 0.1, "or_greater") var lookahead_response: float = 5.0
@export_range(24.0, 512.0, 1.0, "or_greater") var teleport_reset_distance: float = 128.0

@export_category("Cave Headlamp Framing")
@export_range(0.0, 180.0, 1.0, "or_greater") var headlamp_vertical_lookahead: float = 112.0
@export_range(0.1, 20.0, 0.1, "or_greater") var headlamp_lookahead_response: float = 6.0

var _target: Node2D
var _last_target_position: Vector2 = Vector2.ZERO
var _lookahead_x: float = 0.0
var _framing_y: float = 0.0
var _last_viewport_height: float = -1.0
var _last_zoom_y: float = -1.0
var _cave_headlamp_framing: bool = false
var _headlamp_target_y: float = 0.0
var _headlamp_lookahead_y: float = 0.0


func _ready() -> void :
	_target = get_parent() as Node2D
	if _target == null:
		set_physics_process(false)
		return
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	_last_target_position = _target.global_position
	_refresh_vertical_framing(true)
	_apply_rig_position()


func _physics_process(delta: float) -> void :
	if _target == null or delta <= 0.0:
		return

	_refresh_vertical_framing()
	var target_position: Vector2 = _target.global_position
	var displacement: Vector2 = target_position - _last_target_position
	_last_target_position = target_position

	if displacement.length() >= teleport_reset_distance:
		_lookahead_x = 0.0
		_apply_rig_position()
		return

	var horizontal_speed: float = displacement.x / delta
	var target_lookahead: float = _lookahead_for_speed(horizontal_speed)
	var response_weight: float = 1.0 - exp( - lookahead_response * delta)
	_lookahead_x = lerpf(_lookahead_x, target_lookahead, response_weight)
	var vertical_weight: float = 1.0 - exp( - headlamp_lookahead_response * delta)
	_headlamp_lookahead_y = lerpf(_headlamp_lookahead_y, _headlamp_target_y, vertical_weight)
	_apply_rig_position()


func _lookahead_for_speed(horizontal_speed: float) -> float:
	var speed_magnitude: float = absf(horizontal_speed)
	if speed_magnitude <= lookahead_deadzone_speed:
		return 0.0
	var response_range: float = maxf(full_lookahead_speed - lookahead_deadzone_speed, 1.0)
	var strength: float = clampf(
		(speed_magnitude - lookahead_deadzone_speed) / response_range,
		0.0,
		1.0
	)
	return signf(horizontal_speed) * lookahead_distance * strength


func framing_offset_for_viewport(viewport_height: float, zoom_y: float = 1.0) -> float:
	var safe_zoom_y: float = maxf(absf(zoom_y), 0.001)
	var visible_world_height: float = viewport_height / safe_zoom_y
	var framing_ratio: = 0.5 if _cave_headlamp_framing else player_screen_y_ratio
	var desired_offset: float = - (framing_ratio - 0.5) * visible_world_height
	return clampf(desired_offset, - maximum_vertical_offset, maximum_vertical_offset)


func set_cave_headlamp_framing(enabled: bool, direction: Vector2 = Vector2.DOWN) -> void :
	_cave_headlamp_framing = enabled
	set_headlamp_direction(direction)
	_refresh_vertical_framing(true)
	_apply_rig_position()


func set_headlamp_direction(direction: Vector2) -> void :
	_headlamp_target_y = 0.0
	if _cave_headlamp_framing and absf(direction.y) > absf(direction.x):
		_headlamp_target_y = signf(direction.y) * headlamp_vertical_lookahead


func _refresh_vertical_framing(force: bool = false) -> void :
	var viewport_height: float = get_viewport_rect().size.y
	var zoom_y: float = maxf(absf(zoom.y), 0.001)
	if not force and is_equal_approx(viewport_height, _last_viewport_height) and is_equal_approx(zoom_y, _last_zoom_y):
		return
	_last_viewport_height = viewport_height
	_last_zoom_y = zoom_y
	_framing_y = framing_offset_for_viewport(viewport_height, zoom_y)


func _apply_rig_position() -> void :
	position = Vector2(_lookahead_x, _framing_y + _headlamp_lookahead_y)


func headlamp_framing_snapshot() -> Dictionary:
	return {
		"enabled": _cave_headlamp_framing,
		"target_y": _headlamp_target_y,
		"lookahead_y": _headlamp_lookahead_y,
		"base_framing_y": _framing_y,
		"maximum_forward_room": 360.0 + headlamp_vertical_lookahead,
	}
