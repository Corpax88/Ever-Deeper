extends "res://scripts/world/endless_descent_world.gd"
## A/A2 replay DEV11's edge owner. B calls the current production owner.
var north_edge_study_enabled: bool = false
var study_north_draw_calls: int = 0
var study_north_drawn_cells: Dictionary = {}

func _draw_permanent_wall_face(cell: Vector2i, rect: Rect2, side: int) -> void:
	if north_edge_study_enabled:
		super._draw_permanent_wall_face(cell, rect, side)
		if side == 0 and _cell_diggable(cell) and diggable_wall_texture != null and diggable_wall_texture.resource_path == MOSS_EDGE_TEXTURE_PATH:
			study_north_draw_calls += 1
			study_north_drawn_cells[cell] = true
		return
	if _cell_diggable(cell):
		CaveEdgeAssetDrawer.draw_mineable_edge(_draw_canvas, diggable_wall_texture, cell, side, TILE_SIZE, depth_at_position(_cell_center(cell)) % 11)
		return
	CaveEdgeAssetDrawer.draw_bedrock_edge(
		_draw_canvas, cave_wall_texture, cell, side, TILE_SIZE, depth_at_position(_cell_center(cell)) % 11
	)
