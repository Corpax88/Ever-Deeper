extends RefCounted
## Bounded native-art mapping review. No replacement textures or stretched axes.+## The visible thickness of each authored strip/leg sets one uniform scale.
const PROFILES: Array[Dictionary] = [
	{"edge_height":65.0, "edge_center":58.25, "leg_width":113.0, "leg_center":512.0, "elbow":Vector2(512,525), "leg_x":420.0, "leg_right":635.0},
	{"edge_height":98.0, "edge_center":61.25, "leg_width":110.5, "leg_center":557.25, "elbow":Vector2(555,476), "leg_x":460.0, "leg_right":650.0},
	{"edge_height":55.5, "edge_center":57.5, "leg_width":117.5, "leg_center":555.25, "elbow":Vector2(553,508), "leg_x":455.0, "leg_right":650.0},
	{"edge_height":54.5, "edge_center":50.5, "leg_width":89.0, "leg_center":512.5, "elbow":Vector2(510,535), "leg_x":425.0, "leg_right":600.0},
	{"edge_height":102.0, "edge_center":66.5, "leg_width":284.0, "leg_center":604.0, "elbow":Vector2(620,440), "leg_x":385.0, "leg_right":820.0},
]

static func edge(canvas: CanvasItem, strip: Texture2D, corner: Texture2D, cell: Vector2i, side: int, tile: float, profile: int, seed: int = 0) -> void:
	var p: Dictionary = PROFILES[posmod(profile, PROFILES.size())]
	var thickness: float = tile * 0.75
	var bias: float = tile * (0.5 - 10.0 / 48.0)
	var top_left: Vector2 = Vector2(cell) * tile
	if side == 0 or side == 2:
		var native_scale: float = thickness / float(p.edge_height)
		var source_width: float = tile / native_scale
		var start: float = fposmod(float(cell.x + seed) * source_width, float(strip.get_width()))
		var origin: Vector2 = top_left + Vector2(tile * 0.5, 0 if side == 0 else tile)
		var center_y: float = bias if side == 0 else -bias
		var target: Vector2 = Vector2(-tile * 0.5, center_y - float(p.edge_center) * native_scale)
		canvas.draw_set_transform(origin)
		var first: float = minf(source_width, float(strip.get_width()) - start)
		canvas.draw_texture_rect_region(strip, Rect2(target, Vector2(first, 128) * native_scale), Rect2(start, 0, first, 128))
		if first < source_width:
			canvas.draw_texture_rect_region(strip, Rect2(target + Vector2(first * native_scale, 0), Vector2(source_width - first, 128) * native_scale), Rect2(0, 0, source_width - first, 128))
	else:
		# The corner contains an authored upright vertical face. Rotating the
		# horizontal strip instead would turn every top-lit boulder on its side.
		var native_scale: float = thickness / float(p.leg_width)
		var source_height: float = tile / native_scale
		var leg_start: float = 620.0
		var spare: float = maxf(0.0, 1024.0 - leg_start - source_height)
		var source_y: float = leg_start + fposmod(float(cell.y * 47 + seed * 19), maxf(1.0, spare))
		var source: Rect2 = Rect2(float(p.leg_x), source_y, float(p.leg_right) - float(p.leg_x), source_height)
		var origin: Vector2 = top_left + Vector2(tile if side == 1 else 0, tile * 0.5)
		var target: Rect2 = Rect2(Vector2(-bias + (source.position.x - float(p.leg_center)) * native_scale, -tile * 0.5), source.size * native_scale)
		canvas.draw_set_transform(origin, 0.0, Vector2(1 if side == 1 else -1, 1))
		canvas.draw_texture_rect_region(corner, target, source)
	canvas.draw_set_transform(Vector2.ZERO)

static func corner(canvas: CanvasItem, texture: Texture2D, cell: Vector2i, corner_index: int, tile: float, profile: int) -> void:
	var p: Dictionary = PROFILES[posmod(profile, PROFILES.size())]
	var native_scale: float = tile * 0.75 / float(p.leg_width)
	var bias: float = tile * (0.5 - 10.0 / 48.0)
	var inset: float = tile * 10.0 / 48.0
	var overlap: float = 4.0
	var destination: Rect2 = Rect2(Vector2(-tile * 0.5 - overlap, -inset - overlap), Vector2.ONE * (tile * 0.5 + inset + overlap * 2.0))
	var artwork_anchor: Vector2 = Vector2(p.elbow)
	var center: Vector2 = Vector2(-bias, bias)
	var source: Rect2 = Rect2(artwork_anchor + (destination.position - center) / native_scale, destination.size / native_scale)
	var top_left: Vector2 = Vector2(cell) * tile
	var origins: Array[Vector2] = [top_left + Vector2(tile,0), top_left + Vector2(tile,tile), top_left + Vector2(0,tile), top_left]
	var mirrors: Array[Vector2] = [Vector2(1,1), Vector2(1,-1), Vector2(-1,-1), Vector2(-1,1)]
	canvas.draw_set_transform(origins[corner_index], 0.0, mirrors[corner_index])
	canvas.draw_texture_rect_region(texture, destination, source)
	canvas.draw_set_transform(Vector2.ZERO)
