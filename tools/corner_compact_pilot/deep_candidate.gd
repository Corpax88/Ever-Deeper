extends "res://scripts/world/endless_descent_world.gd"
## Standalone review substitution only. Ordinary scenes never load this script.
var compact_join_study_enabled: bool = false

func _draw_permanent_wall_corners(cell: Vector2i, rect: Rect2, open_sides: Array) -> void:
	if not compact_join_study_enabled:
		super._draw_permanent_wall_corners(cell, rect, open_sides)
		return
	# Exact production order, eligibility, textures, scale and permanent branch.
	var adjacent_pairs: = [[0, 1], [1, 2], [2, 3], [3, 0]]
	for corner in 4:
		var pair: Array = adjacent_pairs[corner]
		if not bool(open_sides[int(pair[0])]) or not bool(open_sides[int(pair[1])]):
			continue
		if _cell_diggable(cell):
			CaveEdgeAssetDrawer.draw_mineable_corner(
				_draw_canvas, diggable_corner_texture, cell, corner, TILE_SIZE, Color.WHITE, true
			)
			continue
		CaveEdgeAssetDrawer.draw_bedrock_corner(
			_draw_canvas, cave_wall_corner_texture, cell, corner, TILE_SIZE
		)
