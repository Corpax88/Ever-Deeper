class_name SurfaceParallaxLayer
extends Node2D








@export_range(0.0, 1.25, 0.01) var scroll_factor: = 0.35
@export var culling_enabled: = true
@export_range(0.0, 1024.0, 8.0) var extra_cull_margin: = 0.0
@export var auto_register_direct_children: = true
@export var fallback_chunk_size: = Vector2(1024.0, 720.0)
@export_group("Authored World Range")
@export var fade_out_start_x: = INF
@export var fade_out_end_x: = INF
@export var hide_when_faded: = false

var _authoring_position: = Vector2.ZERO
var _authoring_position_captured: = false
var _authoring_modulate_alpha: = 1.0
var _range_alpha: = 1.0
var _hidden_by_range: = false
var _chunks: Array[Dictionary] = []


func _ready() -> void :
	capture_authoring_position()
	refresh_chunks()


func capture_authoring_position(force: = false) -> void :
	if _authoring_position_captured and not force:
		return
	_authoring_position = position
	_authoring_modulate_alpha = modulate.a
	_authoring_position_captured = true


func apply_tracking_x(tracking_x: float, reference_x: float, reduced_motion_blend: float) -> void :
	if not _authoring_position_captured:
		capture_authoring_position()


	var effective_factor: = lerpf(scroll_factor, 1.0, clampf(reduced_motion_blend, 0.0, 1.0))
	position.x = _authoring_position.x + (tracking_x - reference_x) * (1.0 - effective_factor)
	position.y = _authoring_position.y
	_apply_authored_world_range(tracking_x)


func reset_to_authoring_position() -> void :
	if not _authoring_position_captured:
		capture_authoring_position()
	position = _authoring_position
	_apply_authored_world_range(0.0)


func authored_world_range_alpha() -> float:
	return _range_alpha


func is_hidden_by_authored_world_range() -> bool:
	return _hidden_by_range


func refresh_chunks() -> void :
	_restore_culled_items()
	_chunks.clear()
	if not auto_register_direct_children:
		return
	for child in get_children():
		if child is CanvasItem:
			register_chunk(child as CanvasItem)


func register_chunk(item: CanvasItem, explicit_bounds: = Rect2()) -> void :
	if not is_instance_valid(item):
		return
	for chunk in _chunks:
		if chunk.item == item:
			chunk.bounds = explicit_bounds if explicit_bounds.has_area() else _bounds_for_chunk(item)
			return
	var bounds: = explicit_bounds if explicit_bounds.has_area() else _bounds_for_chunk(item)
	_chunks.append({
		"item": item,
		"bounds": bounds,
		"hidden_by_culler": false,
	})


func unregister_chunk(item: CanvasItem) -> void :
	for index in range(_chunks.size() - 1, -1, -1):
		var chunk: Dictionary = _chunks[index]
		if chunk.item != item:
			continue
		if bool(chunk.hidden_by_culler) and is_instance_valid(item):
			item.visible = true
		_chunks.remove_at(index)


func update_culling(view_center_x: float, view_half_width: float, shared_margin: float) -> void :
	if not culling_enabled:
		_restore_culled_items()
		return
	var left_edge: = view_center_x - view_half_width - shared_margin - extra_cull_margin
	var right_edge: = view_center_x + view_half_width + shared_margin + extra_cull_margin
	for index in range(_chunks.size() - 1, -1, -1):
		var chunk: Dictionary = _chunks[index]
		var item: CanvasItem = chunk.item
		if not is_instance_valid(item):
			_chunks.remove_at(index)
			continue
		var bounds: Rect2 = chunk.bounds
		var displayed_left: = position.x + bounds.position.x
		var displayed_right: = displayed_left + bounds.size.x
		var inside: = displayed_right >= left_edge and displayed_left <= right_edge
		if inside:
			if bool(chunk.hidden_by_culler):
				item.visible = true
				chunk.hidden_by_culler = false
		else:


			if item.visible:
				item.visible = false
				chunk.hidden_by_culler = true


func visible_chunk_count() -> int:
	var count: = 0
	for chunk in _chunks:
		var item: CanvasItem = chunk.item
		if is_instance_valid(item) and item.visible:
			count += 1
	return count


func chunk_count() -> int:
	return _chunks.size()


func debug_snapshot() -> Dictionary:
	return {
		"name": name,
		"scroll_factor": scroll_factor,
		"authoring_position": _authoring_position,
		"display_position": position,
		"chunk_count": chunk_count(),
		"visible_chunk_count": visible_chunk_count(),
		"culling_enabled": culling_enabled,
		"fade_out_start_x": fade_out_start_x,
		"fade_out_end_x": fade_out_end_x,
		"range_alpha": _range_alpha,
		"hidden_by_range": _hidden_by_range,
	}


func _apply_authored_world_range(tracking_x: float) -> void :




	if not is_finite(fade_out_start_x) or not is_finite(fade_out_end_x) or fade_out_end_x <= fade_out_start_x:
		_range_alpha = 1.0
	else:
		var fade_progress: = clampf(
			(tracking_x - fade_out_start_x) / (fade_out_end_x - fade_out_start_x),
			0.0,
			1.0
		)
		var smooth_progress: = fade_progress * fade_progress * (3.0 - 2.0 * fade_progress)
		_range_alpha = 1.0 - smooth_progress
	modulate.a = _authoring_modulate_alpha * _range_alpha
	_hidden_by_range = hide_when_faded and _range_alpha <= 0.001
	visible = not _hidden_by_range


func _restore_culled_items() -> void :
	for chunk in _chunks:
		var item: CanvasItem = chunk.item
		if bool(chunk.hidden_by_culler) and is_instance_valid(item):
			item.visible = true
			chunk.hidden_by_culler = false


func _bounds_for_chunk(item: CanvasItem) -> Rect2:
	if item.has_meta("parallax_bounds"):
		var authored_bounds: Variant = item.get_meta("parallax_bounds")
		if authored_bounds is Rect2 and (authored_bounds as Rect2).has_area():
			return authored_bounds
	var result: = Rect2()
	var has_bounds: = false
	var stack: Array[Node] = [item]
	while not stack.is_empty():
		var current: Node = stack.pop_back()
		if current is Sprite2D:
			var sprite: = current as Sprite2D
			var sprite_rect: = sprite.get_rect()
			for point in _rect_corners(sprite_rect):
				var layer_point: = to_local(sprite.to_global(point))
				if not has_bounds:
					result = Rect2(layer_point, Vector2.ZERO)
					has_bounds = true
				else:
					result = result.expand(layer_point)
		elif current is Polygon2D:
			var polygon: = current as Polygon2D
			for point in polygon.polygon:
				var layer_point: = to_local(polygon.to_global(point))
				if not has_bounds:
					result = Rect2(layer_point, Vector2.ZERO)
					has_bounds = true
				else:
					result = result.expand(layer_point)
		elif current is Line2D:
			var line: = current as Line2D
			for point in line.points:
				var layer_point: = to_local(line.to_global(point))
				if not has_bounds:
					result = Rect2(layer_point, Vector2.ZERO)
					has_bounds = true
				else:
					result = result.expand(layer_point)
		for child in current.get_children():
			if child is CanvasItem:
				stack.append(child)
	if has_bounds:


		result.size.x = maxf(1.0, result.size.x)
		result.size.y = maxf(1.0, result.size.y)
		return result
	var center: = Vector2.ZERO
	if item is Node2D:
		center = (item as Node2D).position
	return Rect2(center - fallback_chunk_size * 0.5, fallback_chunk_size)


func _rect_corners(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0.0),
		rect.end,
		rect.position + Vector2(0.0, rect.size.y),
	])
