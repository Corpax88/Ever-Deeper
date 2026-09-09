class_name MinimapOverlay
extends Control

const REDRAW_INTERVAL: = 0.1
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const GOLD: = Color("e9c86d")
const INK: = Color("07100b")
const MAP_FILL: = Color(0.025, 0.055, 0.04, 0.16)

var _phase: = "surface"
var _location_name: = "SURFACE"
var _player_position: = Vector2.ZERO
var _world_rect: = Rect2(Vector2.ZERO, Vector2(4480, 1280))
var _view_rect: = Rect2()
var _objective_position: = Vector2.ZERO
var _has_objective: = false
var _elapsed: = 0.0
var _redraw_elapsed: = REDRAW_INTERVAL
var _map_rect: = Rect2()
var _panel_style: = StyleBoxFlat.new()
var _premium_hud: Control


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 24
	_panel_style.bg_color = Color(0.012, 0.026, 0.019, 0.2)
	_panel_style.border_color = Color(GOLD, 0.26)
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(24)
	_premium_hud = get_parent().get_node_or_null("PremiumHud") as Control
	if _premium_hud != null and _premium_hud.has_signal("minimap_layout_changed"):
		_premium_hud.minimap_layout_changed.connect(_place_map)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()


func set_snapshot(
	phase: String,
	location_name: String,
	player_position: Vector2,
	world_rect: Rect2,
	view_rect: Rect2,
	objective_position: Vector2 = Vector2.ZERO,
	has_objective: bool = false
) -> void :
	_phase = phase
	_location_name = location_name.to_upper()
	_player_position = player_position
	_world_rect = world_rect if world_rect.has_area() else Rect2(Vector2.ZERO, Vector2.ONE)
	_view_rect = view_rect
	_objective_position = objective_position
	_has_objective = has_objective
	visible = true
	queue_redraw()


func hide_map() -> void :
	visible = false


func debug_snapshot() -> Dictionary:
	return {
		"visible": visible,
		"phase": _phase,
		"location": _location_name,
		"map_rect": _map_rect,
		"world_rect": _world_rect,
		"player_inside": _world_rect.has_point(_player_position),
		"redraw_hz": 1.0 / REDRAW_INTERVAL,
		"transparent": true,
		"organic_style": true,
		"overlap_fade": true,
	}


func _process(delta: float) -> void :
	if not visible:
		return
	var target_alpha: = 0.24 if _player_overlaps_map() else 1.0
	modulate.a = move_toward(modulate.a, target_alpha, maxf(0.0, delta) * 3.6)
	_elapsed += maxf(0.0, delta)
	_redraw_elapsed += maxf(0.0, delta)
	if _redraw_elapsed >= REDRAW_INTERVAL:
		_redraw_elapsed = fmod(_redraw_elapsed, REDRAW_INTERVAL)
		queue_redraw()


func _apply_layout() -> void :
	if _premium_hud != null and _premium_hud.has_method("minimap_layout_rect"):
		var shared_rect: Rect2 = _premium_hud.minimap_layout_rect()
		if shared_rect.has_area():
			_place_map(shared_rect)
			return
	var viewport_size: = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	var size: = Vector2(246, 136) if iphone else Vector2(184, 106)
	var right: = 116.0 if iphone else 8.0
	var top: = 126.0 if iphone else 68.0
	_map_rect = Rect2(viewport_size.x - right - size.x, top, size.x, size.y)
	queue_redraw()


func _place_map(map_rect: Rect2) -> void:
	_map_rect = map_rect
	queue_redraw()


func _draw() -> void :
	if _map_rect.size.x <= 1.0:
		return
	draw_style_box(_panel_style, _map_rect)
	var font: = ThemeDB.fallback_font
	var title_size: = 13 if _map_rect.size.x > 220.0 else 10
	draw_string(font, _map_rect.position + Vector2(13, 18), _location_name, HORIZONTAL_ALIGNMENT_LEFT, _map_rect.size.x - 26.0, title_size, Color(GOLD, 0.76))
	var content: = Rect2(_map_rect.position + Vector2(10, 27), _map_rect.size - Vector2(20, 37))
	draw_rect(content, MAP_FILL, true)
	var fitted: = _fit_world_rect(content.grow(-4.0))
	draw_rect(fitted, Color(0.09, 0.12, 0.08, 0.12), true)
	draw_rect(fitted, Color(GOLD, 0.18), false, 1.0)
	_draw_ambient_sparks(fitted)
	if _view_rect.has_area():
		var view_on_map: = _world_rect_to_map(_view_rect, fitted)
		draw_rect(view_on_map, Color(0.9, 0.82, 0.52, 0.24), false, 1.0)
	if _has_objective:
		_draw_objective(_world_to_map(_objective_position, fitted))
	var player: = _world_to_map(_player_position, fitted)
	var pulse: = 0.5 + sin(_elapsed * 4.2) * 0.5
	draw_circle(player, 7.0 + pulse * 2.0, Color(GOLD, 0.1 + pulse * 0.08))
	draw_circle(player, 4.2, GOLD)
	draw_circle(player, 1.6, INK)


func _fit_world_rect(available: Rect2) -> Rect2:
	var world_aspect: = _world_rect.size.x / maxf(_world_rect.size.y, 1.0)
	var available_aspect: = available.size.x / maxf(available.size.y, 1.0)
	var size: = available.size
	if world_aspect > available_aspect:
		size.y = size.x / world_aspect
	else:
		size.x = size.y * world_aspect
	return Rect2(available.position + (available.size - size) * 0.5, size)


func _draw_ambient_sparks(rect: Rect2) -> void :
	for index in range(7):
		var seed: = float(index) * 2.37
		var position: = Vector2(
			lerpf(rect.position.x + 5.0, rect.end.x - 5.0, fposmod(seed * 0.31, 1.0)),
			lerpf(rect.position.y + 4.0, rect.end.y - 4.0, fposmod(seed * 0.67, 1.0))
		)
		var pulse: = 0.35 + sin(_elapsed * 1.6 + seed) * 0.2
		draw_circle(position, 1.0 + pulse, Color(GOLD, 0.09 + pulse * 0.12))


func _player_overlaps_map() -> bool:
	if not _view_rect.has_area() or _map_rect.size.x <= 1.0:
		return false
	var normalized: = (_player_position - _view_rect.position) / _view_rect.size
	if normalized.x < 0.0 or normalized.x > 1.0 or normalized.y < 0.0 or normalized.y > 1.0:
		return false
	var screen_position: = normalized * get_viewport_rect().size
	return _map_rect.grow(30.0).has_point(screen_position)


func _draw_objective(position: Vector2) -> void :
	var diamond: = PackedVector2Array([
		position + Vector2(0, -5),
		position + Vector2(5, 0),
		position + Vector2(0, 5),
		position + Vector2(-5, 0),
	])
	draw_colored_polygon(diamond, Color(0.58, 0.95, 0.72, 0.9))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color.WHITE, 1.0)


func _world_to_map(world_position: Vector2, map_rect: Rect2) -> Vector2:
	var normalized: = (world_position - _world_rect.position) / _world_rect.size
	normalized = normalized.clamp(Vector2.ZERO, Vector2.ONE)
	return map_rect.position + normalized * map_rect.size


func _world_rect_to_map(world_rect: Rect2, map_rect: Rect2) -> Rect2:
	var start: = _world_to_map(world_rect.position, map_rect)
	var finish: = _world_to_map(world_rect.end, map_rect)
	return Rect2(start, finish - start)
