extends "res://scripts/world/endless_descent_world.gd"
## Isolated camera-only invalidation study. All paint/gameplay methods inherit.
var camera_bounds_enabled: bool = true
var _study_draw_key: Array = []
var _study_key_valid: bool = false
var _study_floor: PackedByteArray = PackedByteArray()
var _study_damage: Dictionary = {}
var study_camera_checks: int = 0
var study_original_requests: int = 0
var study_skipped_requests: int = 0
var study_key_usec: int = 0

func _camera_draw_bounds_changed() -> bool:
	study_camera_checks += 1
	if not super._camera_draw_bounds_changed(): return false
	study_original_requests += 1
	if not camera_bounds_enabled or not _study_key_valid or not last_draw_camera_center.is_finite(): return true
	if not is_instance_valid(lit_draw_sections) or not lit_draw_sections.enabled: return true
	# Preserve viewport/zoom invalidation even when rounding gives the same cells.
	if not get_viewport_rect().size.is_equal_approx(last_draw_viewport_size): return true
	if is_instance_valid(player) and is_instance_valid(player.camera):
		if not player.camera.zoom.abs().is_equal_approx(last_draw_camera_zoom): return true
	var started: int = Time.get_ticks_usec()
	var unchanged: bool = _study_current_key() == _study_draw_key and floor_cells == _study_floor and dig_damage == _study_damage
	study_key_usec += Time.get_ticks_usec() - started
	if unchanged: study_skipped_requests += 1
	return not unchanged

func _remember_draw_camera_bounds() -> void:
	super._remember_draw_camera_bounds()
	if not camera_bounds_enabled: return
	var started: int = Time.get_ticks_usec()
	_study_draw_key = _study_current_key()
	_study_floor = floor_cells.duplicate()
	_study_damage = dig_damage.duplicate(true)
	study_key_usec += Time.get_ticks_usec() - started
	_study_key_valid = true

func _study_current_key() -> Array:
	# Exactly the selection in production _draw(), including clamped end cells.
	var visible_rect: Rect2 = _visual_visible_rect(Vector2.ONE * TILE_SIZE * 3.0)
	var first: Vector2i = _world_to_cell(visible_rect.position)
	var last: Vector2i = _world_to_cell(visible_rect.end)
	first.x = clampi(first.x, 0, GRID_SIZE.x - 1)
	first.y = clampi(first.y, 0, GRID_SIZE.y - 1)
	last.x = clampi(last.x, 0, GRID_SIZE.x - 1)
	last.y = clampi(last.y, 0, GRID_SIZE.y - 1)
	# Exact terrain/damage snapshots are checked separately: no hash collision
	# can hide a direct restore that omitted an explicit redraw request.
	return [first, last, window_start_depth,
		current_depth, int(RunState.world_seed), material, use_parent_material,
		light_mask, self_modulate]

func study_snapshot() -> Dictionary:
	return {"candidate": camera_bounds_enabled, "camera_checks": study_camera_checks,
		"original_requests": study_original_requests, "skipped_requests": study_skipped_requests,
		"key_usec": study_key_usec, "key_valid": _study_key_valid,
		"key": str(_study_current_key())}
