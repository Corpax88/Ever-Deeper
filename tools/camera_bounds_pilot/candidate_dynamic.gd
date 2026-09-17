extends "res://scripts/world/endless_descent_world.gd"
## Untested v2: retain camera queue timing; refresh dynamic commands at _draw.
var camera_bounds_enabled: bool = true
var _study_camera_pending: bool = false
var _study_key_valid: bool = false
var _study_draw_key: Array = []
var _study_floor: PackedByteArray = PackedByteArray()
var _study_damage: Dictionary = {}
var _study_cached_count: int = 0
var _study_cached_epoch: int = -1
var study_camera_checks: int = 0
var study_original_requests: int = 0
var study_skipped_setups: int = 0
var study_dynamic_requeues: int = 0
var study_key_usec: int = 0

func _camera_draw_bounds_changed() -> bool:
	study_camera_checks += 1
	var requested: bool = super._camera_draw_bounds_changed()
	if requested:
		study_original_requests += 1
		_study_camera_pending = true
	return requested

func _draw() -> void:
	var camera_requested: bool = _study_camera_pending
	_study_camera_pending = false
	if camera_bounds_enabled and camera_requested and _study_key_valid and not floor_cells.is_empty() and not stratum.is_empty() and last_draw_camera_center.is_finite() and is_instance_valid(lit_draw_sections) and lit_draw_sections.enabled and lit_draw_sections.visible:
		var started: int = Time.get_ticks_usec()
		var unchanged: bool = _study_current_key() == _study_draw_key and floor_cells == _study_floor and dig_damage == _study_damage
		if unchanged: unchanged = _study_dynamic_bindings_match()
		if unchanged: unchanged = _study_cached_set_valid()
		study_key_usec += Time.get_ticks_usec() - started
		if unchanged:
			_draw_canvas = self
			# This is the same queued parent draw barrier as the original. No
			# dynamic callback is queued early from physics before age/removal.
			super._remember_draw_camera_bounds()
			for index in lit_draw_sections._used:
				lit_draw_sections._pool[index].queue_redraw()
				study_dynamic_requeues += 1
			study_skipped_setups += 1
			return
	super._draw()
	if is_instance_valid(lit_draw_sections):
		_study_cached_count = lit_draw_sections._cached.size()
		_study_cached_epoch = lit_draw_sections._epoch

func _remember_draw_camera_bounds() -> void:
	super._remember_draw_camera_bounds()
	if not camera_bounds_enabled: return
	var started: int = Time.get_ticks_usec()
	_study_draw_key = _study_current_key()
	_study_floor = floor_cells.duplicate()
	_study_damage = dig_damage.duplicate(true)
	_study_key_valid = true
	study_key_usec += Time.get_ticks_usec() - started

func _study_dynamic_bindings_match() -> bool:
	if lit_draw_sections._used != _crusher_impacts.size() or lit_draw_sections._pool.size() < lit_draw_sections._used: return false
	for index in lit_draw_sections._used:
		var section: Node = lit_draw_sections._pool[index]
		if not section.visible or section.world != self: return false
		var paint: Callable = section.paint
		if paint.get_object() != self or paint.get_method() != &"_draw_impact_section": return false
		var arguments: Array = paint.get_bound_arguments()
		if arguments.size() != 1 or not is_same(arguments[0], _crusher_impacts[index]): return false
	return true

func _study_cached_set_valid() -> bool:
	# A cleared/partially invalidated cache is never valid by an empty foreach.
	if _study_cached_count <= 0 or lit_draw_sections._cached.size() != _study_cached_count or lit_draw_sections._epoch != _study_cached_epoch: return false
	for section in lit_draw_sections._cached.values():
		if section.revision == -1 or not section.visible: return false
	return true

func _study_current_key() -> Array:
	var visible_rect: Rect2 = _visual_visible_rect(Vector2.ONE * TILE_SIZE * 3.0)
	var first: Vector2i = _world_to_cell(visible_rect.position)
	var last: Vector2i = _world_to_cell(visible_rect.end)
	first.x = clampi(first.x, 0, GRID_SIZE.x - 1)
	first.y = clampi(first.y, 0, GRID_SIZE.y - 1)
	last.x = clampi(last.x, 0, GRID_SIZE.x - 1)
	last.y = clampi(last.y, 0, GRID_SIZE.y - 1)
	var camera_zoom: Vector2 = Vector2.ONE
	if is_instance_valid(player) and is_instance_valid(player.camera): camera_zoom = player.camera.zoom.abs()
	return [first, last, get_viewport_rect().size, camera_zoom,
		window_start_depth, current_depth, int(RunState.world_seed), material,
		use_parent_material, light_mask, self_modulate]

func study_snapshot() -> Dictionary:
	return {"candidate":camera_bounds_enabled,"variant":"dynamic-at-parent-draw-v2",
		"camera_checks":study_camera_checks,"original_requests":study_original_requests,
		"skipped_setups":study_skipped_setups,"dynamic_requeues":study_dynamic_requeues,
		"key_usec":study_key_usec,"key_valid":_study_key_valid,"key":str(_study_current_key())}
