class_name GuideOverlay
extends Control

const REDRAW_INTERVAL: = 1.0 / 30.0
const IPHONE_LANDSCAPE_ASPECT: = 1.95

var target_camera: Camera2D
var target_world: = Vector2.ZERO
var accent: = Color("e9c86d")
var has_target: = false
var elapsed: = 0.0
var redraw_elapsed: = REDRAW_INTERVAL
var redraw_request_count: = 0


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 25


func set_world_target(camera: Camera2D, world_position: Vector2, color: Color = Color("e9c86d")) -> void :
	var target_changed: = (
		camera != target_camera
		or not world_position.is_equal_approx(target_world)
		or color != accent
		or not has_target
	)
	target_camera = camera
	target_world = world_position
	accent = color
	has_target = is_instance_valid(camera)
	if target_changed:
		_request_redraw()


func clear_target() -> void :
	if not has_target and target_camera == null:
		return
	has_target = false
	target_camera = null
	_request_redraw()


func _process(delta: float) -> void :
	if not has_target or not visible:
		return
	redraw_elapsed += maxf(0.0, delta)
	if redraw_elapsed < REDRAW_INTERVAL:
		return
	elapsed += redraw_elapsed
	redraw_elapsed = fmod(redraw_elapsed, REDRAW_INTERVAL)
	_request_redraw()


func mobile_render_budget_snapshot() -> Dictionary:
	return {
		"redraw_hz": 30.0,
		"redraw_requests": redraw_request_count,
		"target_active": has_target,
	}


func _request_redraw() -> void :
	redraw_request_count += 1
	queue_redraw()


func _draw() -> void :
	if not has_target or not is_instance_valid(target_camera):
		return
	var viewport_size: = get_viewport_rect().size
	var center: = target_camera.get_screen_center_position()
	var zoom: = target_camera.zoom
	var screen: = (target_world - center) * zoom + viewport_size * 0.5


	var safe: = safe_rect_for_viewport(viewport_size)
	var pulse: = 0.5 + sin(elapsed * 3.6) * 0.5
	if safe.has_point(screen):
		_draw_world_marker(screen, pulse)
	else:
		var clamped: = Vector2(
			clampf(screen.x, safe.position.x, safe.end.x),
			clampf(screen.y, safe.position.y, safe.end.y)
		)
		_draw_edge_marker(clamped, (screen - viewport_size * 0.5).normalized(), pulse)


func safe_rect_for_viewport(viewport_size: Vector2) -> Rect2:
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	if iphone:

		return Rect2(Vector2(136, 152), viewport_size - Vector2(572, 326))
	return Rect2(Vector2(28, 66), viewport_size - Vector2(56, 256))


func _draw_world_marker(position: Vector2, pulse: float) -> void :
	var radius: = 19.0 + pulse * 3.0
	draw_circle(position, radius + 10.0, Color(accent, 0.045 + pulse * 0.035))
	draw_arc(position, radius, - PI * 0.7, - PI * 0.3, 10, Color(accent, 0.82), 2.2)
	draw_arc(position, radius, PI * 0.3, PI * 0.7, 10, Color(accent, 0.82), 2.2)
	draw_arc(position, radius, PI * 0.8, PI * 1.2, 10, Color(accent, 0.82), 2.2)
	draw_arc(position, radius, - PI * 0.2, PI * 0.2, 10, Color(accent, 0.82), 2.2)
	var diamond: = PackedVector2Array([
		position + Vector2(0, -7), position + Vector2(7, 0),
		position + Vector2(0, 7), position + Vector2(-7, 0),
	])
	draw_colored_polygon(diamond, Color(accent, 0.38 + pulse * 0.28))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color(accent, 0.98), 1.5)


func _draw_edge_marker(position: Vector2, direction: Vector2, pulse: float) -> void :
	var angle: = direction.angle()
	var forward: = Vector2.RIGHT.rotated(angle)
	var side: = forward.rotated(PI * 0.5)
	var glow: = Color(accent, 0.08 + pulse * 0.05)
	draw_circle(position, 24.0 + pulse * 3.0, glow)
	for offset_value in [0.0, -9.0]:
		var offset: = float(offset_value)
		var tip: Vector2 = position + forward * (12.0 + offset)
		var back: Vector2 = position - forward * (8.0 - offset)
		draw_polyline(PackedVector2Array([back + side * 8.0, tip, back - side * 8.0]), Color(accent, 0.72 + pulse * 0.26), 3.0)
