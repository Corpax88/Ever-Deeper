extends "res://scripts/world/depth/rootwound_world.gd"
## Standalone review substitution only. Ordinary scenes never load this script.
var compact_join_study_enabled: bool = false

func _draw_wall_corner_joins(cell: Vector2i, rect: Rect2, open_sides: Array, noise: float) -> void:
	if not compact_join_study_enabled:
		super._draw_wall_corner_joins(cell, rect, open_sides, noise)
		return
	# Exact production order, eligibility, textures, scale and permanent branch.
	var adjacent_pairs: = [[0, 1], [1, 2], [2, 3], [3, 0]]
	var bedrock: = _terrain_is_bedrock(cell)
	for corner in 4:
		var pair: Array = adjacent_pairs[corner]
		if not bool(open_sides[int(pair[0])]) or not bool(open_sides[int(pair[1])]):
			continue
		if bedrock:
			CaveEdgeAssetDrawer.draw_bedrock_corner(
				_draw_canvas, bedrock_corner_texture, cell, corner, TILE_SIZE
			)
		else:
			CaveEdgeAssetDrawer.draw_mineable_corner(
				_draw_canvas, cave_corner_texture, cell, corner, TILE_SIZE, Color.WHITE, true
			)
