class_name SurfaceParallax
extends Node2D







const SurfaceParallaxLayerScript: = preload("res://scripts/world/surface_parallax_layer.gd")

enum TrackingSource{
	AUTO,
	CAMERA,
	TARGET,
}

@export_node_path("Node2D") var target_path: = NodePath("../Player")
@export_node_path("Camera2D") var camera_path: = NodePath("../Player/Camera2D")
@export var tracking_source: = TrackingSource.AUTO
@export var reference_x: = 0.0
@export var active: = true
@export var culling_enabled: = true
@export_range(0.0, 1024.0, 8.0) var cull_margin: = 256.0
@export_range(0.04, 0.5, 0.01) var cull_interval: = 0.12
@export_range(0.0, 4.0, 0.05) var movement_epsilon: = 0.25
@export_range(1.0, 4096.0, 1.0) var fallback_viewport_width: = 1280.0
@export var reduced_motion: = false
@export_range(0.0, 1.0, 0.05) var reduced_motion_strength: = 1.0

var _target: Node2D
var _camera: Camera2D
var _layers: Array[Node2D] = []
var _last_tracking_x: = INF
var _last_viewport_width_world: = INF
var _cull_elapsed: = INF


func _ready() -> void :
	_resolve_exported_paths()
	refresh_layers()
	set_process(active)
	visible = active
	if active:
		force_update()


func _process(delta: float) -> void :
	if not active:
		return
	var tracking_x: = _tracking_x()
	var viewport_width_world: = _viewport_width_world()
	if is_finite(tracking_x) and (
		not is_finite(_last_tracking_x)
		or absf(tracking_x - _last_tracking_x) >= movement_epsilon
		or not is_equal_approx(viewport_width_world, _last_viewport_width_world)
	):
		_apply_tracking_x(tracking_x, viewport_width_world)
	_cull_elapsed += delta
	if _cull_elapsed >= cull_interval:
		_cull_elapsed = 0.0
		_update_culling()


func bind_to(target: Node2D, camera: Camera2D = null) -> void :
	_target = target
	_camera = camera
	_last_tracking_x = INF
	_last_viewport_width_world = INF
	_cull_elapsed = INF
	if is_inside_tree() and active:
		force_update()


func set_active(enabled: bool) -> void :
	active = enabled
	visible = enabled
	set_process(enabled)
	if enabled:
		_last_tracking_x = INF
		_last_viewport_width_world = INF
		_cull_elapsed = INF
		force_update()


func set_reduced_motion(enabled: bool) -> void :
	reduced_motion = enabled
	_last_tracking_x = INF
	_last_viewport_width_world = INF
	if is_inside_tree() and active:
		force_update()


func set_reference_x(value: float) -> void :
	reference_x = value
	_last_tracking_x = INF
	_last_viewport_width_world = INF
	if is_inside_tree() and active:
		force_update()


func refresh_layers() -> void :
	_layers.clear()
	for child in get_children():
		if child.get_script() == SurfaceParallaxLayerScript or (
			child.has_method("apply_tracking_x")
			and child.has_method("update_culling")
		):
			_layers.append(child as Node2D)
			child.capture_authoring_position()
			child.refresh_chunks()
	_last_tracking_x = INF
	_last_viewport_width_world = INF
	_cull_elapsed = INF


func force_update() -> void :
	if _layers.is_empty():
		refresh_layers()
	var tracking_x: = _tracking_x()
	if not is_finite(tracking_x):
		return
	_apply_tracking_x(tracking_x, _viewport_width_world())
	_update_culling()
	_cull_elapsed = 0.0


func force_cull() -> void :
	_update_culling()
	_cull_elapsed = 0.0


func layer(layer_name: StringName) -> Node2D:
	for item in _layers:
		if item.name == layer_name:
			return item
	return null


func register_chunk(layer_name: StringName, item: CanvasItem, bounds: = Rect2()) -> bool:
	var target_layer: = layer(layer_name)
	if target_layer == null:
		return false
	target_layer.register_chunk(item, bounds)
	_cull_elapsed = INF
	return true


func debug_snapshot() -> Dictionary:
	var snapshots: Array[Dictionary] = []
	var visible_chunks: = 0
	var total_chunks: = 0
	for item in _layers:
		var snapshot: Dictionary = item.debug_snapshot()
		snapshots.append(snapshot)
		visible_chunks += int(snapshot.visible_chunk_count)
		total_chunks += int(snapshot.chunk_count)
	return {
		"active": active,
		"tracking_x": _last_tracking_x,
		"reference_x": reference_x,
		"effective_reference_x": _effective_reference_x(_viewport_width_world()),
		"viewport_width_world": _viewport_width_world(),
		"reduced_motion": reduced_motion,
		"layer_count": _layers.size(),
		"chunk_count": total_chunks,
		"visible_chunk_count": visible_chunks,
		"layers": snapshots,
		"collision_neutral": find_children("", "CollisionObject2D", true, false).is_empty(),
	}


func _resolve_exported_paths() -> void :
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node2D
	if not camera_path.is_empty():
		_camera = get_node_or_null(camera_path) as Camera2D


func _tracking_x() -> float:
	match tracking_source:
		TrackingSource.CAMERA:
			return _camera_x_or_fallback()
		TrackingSource.TARGET:
			return _target.global_position.x if is_instance_valid(_target) else _camera_x_or_fallback()
		_:
			if is_instance_valid(_camera) and _camera.enabled and _camera.is_inside_tree():
				return _camera.get_screen_center_position().x
			if is_instance_valid(_target):
				return _target.global_position.x
			var viewport_camera: = get_viewport().get_camera_2d()
			if is_instance_valid(viewport_camera):
				return viewport_camera.get_screen_center_position().x
	return reference_x


func _camera_x_or_fallback() -> float:
	if is_instance_valid(_camera) and _camera.is_inside_tree():
		return _camera.get_screen_center_position().x
	if is_instance_valid(_target):
		return _target.global_position.x
	return reference_x


func _apply_tracking_x(tracking_x: float, viewport_width_world: float) -> void :
	var motion_blend: = reduced_motion_strength if reduced_motion else 0.0
	var effective_reference_x: = _effective_reference_x(viewport_width_world)
	for item in _layers:
		item.apply_tracking_x(tracking_x, effective_reference_x, motion_blend)
	_last_tracking_x = tracking_x
	_last_viewport_width_world = viewport_width_world


func _effective_reference_x(viewport_width_world: float) -> float:
	return reference_x + 0.5 * (viewport_width_world - fallback_viewport_width)


func _update_culling() -> void :
	if _layers.is_empty():
		return
	var view_center_x: = _tracking_x()
	if not is_finite(view_center_x):
		return

	view_center_x = to_local(Vector2(view_center_x, global_position.y)).x
	var half_width: = _viewport_width_world() * 0.5
	for item in _layers:
		if culling_enabled:
			item.update_culling(view_center_x, half_width, cull_margin)
		else:
			item.update_culling(view_center_x, INF, INF)


func _viewport_width_world() -> float:
	var width: = fallback_viewport_width
	if is_inside_tree():
		var viewport_width: = get_viewport().get_visible_rect().size.x
		if viewport_width > 1.0:
			width = viewport_width
	if is_instance_valid(_camera):
		width /= maxf(0.001, absf(_camera.zoom.x))
	return width
