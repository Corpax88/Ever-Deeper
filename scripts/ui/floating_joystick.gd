extends Control

signal movement_changed(direction: Vector2)
signal build_pointer(screen_position: Vector2, pressed: bool, dragging: bool)

const DESIGN_OUTER_RADIUS: = 52.0
const DESIGN_INPUT_RADIUS: = 32.0
const IPHONE_OUTER_RADIUS: = 76.0
const IPHONE_INPUT_RADIUS: = 48.0
const LANDSCAPE_ACTIVE_WIDTH: = 0.46
const LANDSCAPE_ACTIVE_TOP: = 0.36
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const MINIMUM_TOUCH_TARGET: = 44.0
const MOSS_DEEP: = Color("071a11")
const MOSS: = Color("83b176")
const GOLD: = Color("d7b45a")
const GOLD_BRIGHT: = Color("ffe3a0")

var active_pointer: = -2
var input_origin: = Vector2.ZERO
var origin: = Vector2.ZERO
var knob: = Vector2.ZERO
var build_mode: = false
var active_build_pointer: = -2
var outer_radius: = DESIGN_OUTER_RADIUS
var input_radius: = DESIGN_INPUT_RADIUS
var knob_radius: = 22.0
var edge_margin_x: = 0.0
var edge_margin_y: = 0.0


func _ready() -> void :
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process_unhandled_input(false)
	resized.connect(_apply_responsive_geometry)
	_apply_responsive_geometry()


func _gui_input(event: InputEvent) -> void :
	if build_mode:
		_handle_build_input(event)
		return
	if event is InputEventScreenTouch:
		var touch: = event as InputEventScreenTouch
		if touch.pressed and active_pointer == -2 and _is_in_movement_zone(touch.position):
			_begin(touch.index, touch.position)
			accept_event()
		elif not touch.pressed and touch.index == active_pointer:
			_end()
			accept_event()
	elif event is InputEventScreenDrag:
		var drag: = event as InputEventScreenDrag
		if drag.index == active_pointer:
			_update_knob(drag.position)
			accept_event()
	elif event is InputEventMouseButton:
		var button: = event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed and active_pointer == -2 and _is_in_movement_zone(button.position):
			_begin(-1, button.position)
			accept_event()
		elif not button.pressed and active_pointer == -1:
			_end()
			accept_event()
	elif event is InputEventMouseMotion and active_pointer == -1:
		var motion: = event as InputEventMouseMotion
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_update_knob(motion.position)
			accept_event()


func cancel() -> void :
	if active_pointer != -2:
		_end()


func set_build_mode(enabled: bool) -> void :
	if build_mode == enabled:
		return
	cancel()
	build_mode = enabled
	active_build_pointer = -2
	queue_redraw()


func _handle_build_input(event: InputEvent) -> void :
	if event is InputEventScreenTouch:
		var touch: = event as InputEventScreenTouch
		if touch.pressed and active_build_pointer == -2:
			active_build_pointer = touch.index
			build_pointer.emit(touch.position, true, false)
			accept_event()
		elif not touch.pressed and touch.index == active_build_pointer:
			build_pointer.emit(touch.position, false, false)
			active_build_pointer = -2
			accept_event()
	elif event is InputEventScreenDrag:
		var drag: = event as InputEventScreenDrag
		if drag.index == active_build_pointer:
			build_pointer.emit(drag.position, true, true)
			accept_event()
	elif event is InputEventMouseButton:
		var button: = event as InputEventMouseButton
		if button.button_index != MOUSE_BUTTON_LEFT:
			return
		if button.pressed and active_build_pointer == -2:
			active_build_pointer = -1
			build_pointer.emit(button.position, true, false)
			accept_event()
		elif not button.pressed and active_build_pointer == -1:
			build_pointer.emit(button.position, false, false)
			active_build_pointer = -2
			accept_event()
	elif event is InputEventMouseMotion and active_build_pointer == -1:
		var motion: = event as InputEventMouseMotion
		build_pointer.emit(motion.position, true, true)
		accept_event()


func _begin(pointer: int, position: Vector2) -> void :
	active_pointer = pointer
	input_origin = position
	origin = _clamped_visual_origin(position)
	knob = Vector2.ZERO
	movement_changed.emit(Vector2.ZERO)
	queue_redraw()


func _is_in_movement_zone(screen_position: Vector2) -> bool:
	if size.x <= 1.0 or size.y <= 1.0:
		return true
	var zone: = movement_zone_rect(size)
	return (
		screen_position.x >= zone.position.x
		and screen_position.x <= zone.end.x
		and screen_position.y >= zone.position.y
		and screen_position.y <= zone.end.y
	)


func movement_zone_rect(viewport_size: Vector2) -> Rect2:
	return Rect2(
		0.0,
		viewport_size.y * LANDSCAPE_ACTIVE_TOP,
		viewport_size.x * LANDSCAPE_ACTIVE_WIDTH,
		viewport_size.y * (1.0 - LANDSCAPE_ACTIVE_TOP)
	)


func minimum_touch_target_is_valid(viewport_size: Vector2, minimum_size: float = MINIMUM_TOUCH_TARGET) -> bool:
	var zone: = movement_zone_rect(viewport_size)
	return zone.size.x >= minimum_size and zone.size.y >= minimum_size


func _update_knob(position: Vector2) -> void :
	var offset: = position - input_origin
	knob = offset.limit_length(input_radius)
	var direction: = (offset / input_radius).limit_length(1.0)
	movement_changed.emit(direction)
	queue_redraw()


func _end() -> void :
	active_pointer = -2
	input_origin = Vector2.ZERO
	origin = Vector2.ZERO
	knob = Vector2.ZERO
	movement_changed.emit(Vector2.ZERO)
	queue_redraw()


func _draw() -> void :
	if build_mode or active_pointer == -2:
		return

	draw_circle(origin + Vector2(0.0, 4.0), outer_radius, Color(MOSS_DEEP, 0.3))
	draw_circle(origin, outer_radius, Color(MOSS_DEEP, 0.34))
	draw_circle(origin, input_radius, Color(MOSS, 0.075))
	draw_arc(origin, outer_radius - 2.0, 0.0, TAU, 64, Color(MOSS, 0.4), 1.5, true)
	for cardinal in range(4):
		var angle: = float(cardinal) * PI * 0.5
		draw_arc(origin, outer_radius - 5.0, angle - 0.22, angle + 0.22, 8, Color(GOLD, 0.62), 2.5, true)
	var strength: = clampf(knob.length() / maxf(input_radius, 1.0), 0.0, 1.0)
	if strength > 0.06:
		var direction_angle: = knob.angle()
		draw_arc(origin, outer_radius - 3.0, direction_angle - 0.34, direction_angle + 0.34, 12, Color(GOLD_BRIGHT, 0.38 + strength * 0.52), 4.0, true)
	var knob_center: = origin + knob
	draw_circle(knob_center + Vector2(0.0, 3.0), knob_radius, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(knob_center, knob_radius, Color(0.055, 0.16, 0.09, 0.9))
	draw_circle(knob_center, knob_radius * 0.62, Color(MOSS, 0.13 + strength * 0.08))
	draw_arc(knob_center, knob_radius, 0.0, TAU, 36, Color(GOLD, 0.9), 2.2, true)
	draw_arc(knob_center, knob_radius - 4.0, PI * 1.08, PI * 1.72, 12, Color(GOLD_BRIGHT, 0.64), 1.5, true)


func _apply_responsive_geometry() -> void :
	var iphone: = size.x / maxf(size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	outer_radius = IPHONE_OUTER_RADIUS if iphone else DESIGN_OUTER_RADIUS
	input_radius = IPHONE_INPUT_RADIUS if iphone else DESIGN_INPUT_RADIUS
	knob_radius = 31.0 if iphone else 22.0
	edge_margin_x = 116.0 if iphone else 0.0
	edge_margin_y = 42.0 if iphone else 0.0
	if active_pointer != -2:
		origin = _clamped_visual_origin(input_origin)
	queue_redraw()


func _clamped_visual_origin(position: Vector2) -> Vector2:
	if size.x <= 1.0 or size.y <= 1.0:
		return position
	var minimum_x: = edge_margin_x + outer_radius
	var maximum_x: = maxf(minimum_x, size.x * LANDSCAPE_ACTIVE_WIDTH - outer_radius)
	var minimum_y: = maxf(size.y * LANDSCAPE_ACTIVE_TOP, edge_margin_y + outer_radius)
	var maximum_y: = maxf(minimum_y, size.y - edge_margin_y - outer_radius)
	return Vector2(
		clampf(position.x, minimum_x, maximum_x),
		clampf(position.y, minimum_y, maximum_y)
	)
