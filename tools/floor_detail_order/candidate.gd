extends "res://scripts/world/endless_descent_world.gd"
## Isolated study: preserve all commands and their CanvasItem; move only floor
## detail lines past disjoint solid-cell commands within one four-cell strip.
var study_enabled: bool = false
var study_source_verified: bool = false
var study_visible_shader_code: String = preload("res://shaders/lit_visible_pixels.gdshader").code
var study_reordered_callbacks: int = 0
var study_fallback_callbacks: int = 0

func study_eligible(first_col: int, last_col: int, canvas: CanvasItem) -> bool:
	return study_source_verified and first_col >= 0 and last_col < GRID_SIZE.x \
		and first_col % 4 == 0 and last_col >= first_col and last_col - first_col <= 3 \
		and material == null and not use_parent_material \
		and canvas != null and canvas.get_parent() == lit_draw_sections \
		and not canvas.use_parent_material \
		and canvas.material == lit_draw_sections.VISIBLE_PIXELS_MATERIAL \
		and canvas.material.shader.code == study_visible_shader_code

func _draw_terrain_section(row: int, first_col: int, last_col: int, pass_index: int) -> void:
	if not study_enabled or pass_index != 1:
		super._draw_terrain_section(row, first_col, last_col, pass_index)
		return
	if not study_eligible(first_col, last_col, _draw_canvas):
		study_fallback_callbacks += 1
		super._draw_terrain_section(row, first_col, last_col, pass_index)
		return
	_select_draw_stratum(window_start_depth + row / DeepLayout.CHUNK_ROWS)
	# Native rock/ore/damage commands keep their original relative order.
	for col in range(first_col, last_col + 1):
		var cell: Vector2i = Vector2i(col, row)
		if not _is_floor(cell):
			_draw_permanent_wall_mass(cell, Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE))
	# The unchanged line function preserves exact vertices, half-float color
	# packing and primitive type. Its ordering among floor cells also survives.
	for col in range(first_col, last_col + 1):
		var cell: Vector2i = Vector2i(col, row)
		if _is_floor(cell):
			_draw_floor_detail(cell, Rect2(Vector2(cell) * TILE_SIZE, Vector2.ONE * TILE_SIZE))
	_select_draw_stratum(maxi(1, current_depth))
	study_reordered_callbacks += 1

func study_redraw_all_cached() -> void:
	for section in lit_draw_sections._cached.values(): section.queue_redraw()

func study_snapshot() -> Dictionary:
	return {"enabled":study_enabled,"source_verified":study_source_verified,
		"reordered_callbacks":study_reordered_callbacks,"fallback_callbacks":study_fallback_callbacks}
