extends "res://scripts/world/endless_descent_world.gd"
## Standalone review substitution. Production scenes never load this script.
const STUDY_MOSS_EDGE_PATH: String = "res://assets/mossvein/cave-edge-loop-v2.png"
var north_edge_study_enabled: bool = false
var study_north_draw_calls: int = 0
var study_north_drawn_cells: Dictionary = {}

func _draw_permanent_wall_face(cell: Vector2i, rect: Rect2, side: int) -> void:
	if not north_edge_study_enabled or side != 0 or not _cell_diggable(cell):
		super._draw_permanent_wall_face(cell, rect, side)
		return
	if diggable_wall_texture == null or diggable_wall_texture.resource_path != STUDY_MOSS_EDGE_PATH:
		super._draw_permanent_wall_face(cell, rect, side)
		return
	# Copy only the production north edge's segment and complete quad. Keep its
	# horizontal reflection/phase, but preserve the authored upright Y axis.
	var segment_count: int = maxi(1, floori(float(diggable_wall_texture.get_width()) / 128.0))
	var seed_offset: int = depth_at_position(_cell_center(cell)) % 11
	var segment: int = posmod(-cell.x + seed_offset, segment_count)
	var source := Rect2(Vector2(float(segment) * 128.0, 0.0), Vector2(128.0, 128.0))
	var origin: Vector2 = Vector2(cell) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, 0.0)
	var inset: float = TILE_SIZE * (10.0 / 48.0)
	var destination := Rect2(Vector2(-TILE_SIZE * 0.5, -inset), Vector2.ONE * TILE_SIZE)
	_draw_canvas.draw_set_transform(origin, 0.0, Vector2(-1.0, 1.0))
	_draw_canvas.draw_texture_rect_region(diggable_wall_texture, destination, source, Color.WHITE)
	_draw_canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	study_north_draw_calls += 1
	study_north_drawn_cells[cell] = true
