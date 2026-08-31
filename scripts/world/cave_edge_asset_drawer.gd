class_name CaveEdgeAssetDrawer
extends RefCounted


const EDGE_SOURCE_HEIGHT := 128.0
const BEDROCK_SOURCE_HEIGHT := 256.0
const SOURCE_SEGMENT_WIDTH := 128.0


static func draw_mineable_edge(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	side: int,
	tile_size: float,
	seed_offset: int = 0,
	modulate: Color = Color.WHITE
) -> void:
	_draw_edge(
		canvas,
		texture,
		cell,
		side,
		tile_size,
		EDGE_SOURCE_HEIGHT,
		tile_size,
		tile_size * (10.0 / 48.0),
		seed_offset,
		modulate
	)


static func draw_bedrock_edge(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	side: int,
	tile_size: float,
	seed_offset: int = 0,
	modulate: Color = Color.WHITE
) -> void:
	_draw_edge(
		canvas,
		texture,
		cell,
		side,
		tile_size,
		BEDROCK_SOURCE_HEIGHT,
		tile_size * 2.0,
		tile_size * (18.0 / 48.0),
		seed_offset,
		modulate
	)


static func draw_mineable_corner(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	corner: int,
	tile_size: float,
	modulate: Color = Color.WHITE,
	compact_join: bool = false
) -> void:
	_draw_corner(
		canvas,
		texture,
		cell,
		corner,
		tile_size,
		tile_size,
		tile_size * (10.0 / 48.0),
		modulate,
		compact_join
	)


static func draw_bedrock_corner(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	corner: int,
	tile_size: float,
	modulate: Color = Color.WHITE
) -> void:
	_draw_corner(
		canvas,
		texture,
		cell,
		corner,
		tile_size,
		tile_size * 2.0,
		tile_size * (18.0 / 48.0),
		modulate,
		false
	)


static func _draw_edge(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	side: int,
	tile_size: float,
	source_height: float,
	depth: float,
	inset: float,
	seed_offset: int,
	modulate: Color
) -> void:
	if texture == null:
		return
	var segment_count := maxi(1, floori(float(texture.get_width()) / SOURCE_SEGMENT_WIDTH))
	var along := cell.x if side == 0 or side == 2 else cell.y
	if side == 0 or side == 1:
		along = -along
	var segment := posmod(along + seed_offset, segment_count)
	var source := Rect2(
		Vector2(float(segment) * SOURCE_SEGMENT_WIDTH, 0.0),
		Vector2(SOURCE_SEGMENT_WIDTH, source_height)
	)
	var origin := _edge_midpoint(cell, side, tile_size)
	var rotation: float = float([PI, -PI * 0.5, 0.0, PI * 0.5][side])
	# Local +Y is the open cave side after rotation.  Keep only a small lip over
	# the walkable floor; the authored rock mass belongs inside the solid cell.
	var destination := Rect2(
		Vector2(-tile_size * 0.5, -depth + inset), Vector2(tile_size, depth)
	)
	canvas.draw_set_transform(origin, rotation, Vector2.ONE)
	canvas.draw_texture_rect_region(texture, destination, source, modulate)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_corner(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	corner: int,
	tile_size: float,
	depth: float,
	inset: float,
	modulate: Color,
	compact_join: bool
) -> void:
	if texture == null or corner < 0 or corner > 3:
		return
	# The canonical authored turn is UP+RIGHT: open cave occupies the upper-right
	# and the owning solid cell the lower-left.  Its bend is centred in the source.
	# The generated band occupies only the middle third of the square, so a 3x
	# depth destination preserves the same face weight as the straight ribbons.
	var solid_bias := depth * 0.5 - inset
	var center_offset := Vector2(-solid_bias, solid_bias)
	var destination_size := Vector2.ONE * depth * 3.0
	var destination := Rect2(center_offset - destination_size * 0.5, destination_size)
	var origin := _corner_anchor(cell, corner, tile_size)
	var rotation: float = float([0.0, PI * 0.5, PI, -PI * 0.5][corner])
	canvas.draw_set_transform(origin, rotation, Vector2.ONE)
	if compact_join:
		# Tight mined shapes can expose three or four sides of one 48 px block.
		# Drawing a complete 3x-tile L at every turn stacks several large rock
		# masses over the same cell.  Keep the authored scale, but clip each cap
		# to the actual join; the straight edge ribbons already supply both arms.
		var seam_overlap := 2.0
		var compact_destination := Rect2(
			Vector2(-tile_size * 0.5 - seam_overlap, -inset - seam_overlap),
			Vector2(
				tile_size * 0.5 + inset + seam_overlap * 2.0,
				tile_size * 0.5 + inset + seam_overlap * 2.0
			)
		).intersection(destination)
		var texture_size := Vector2(texture.get_size())
		var relative_position := compact_destination.position - destination.position
		var source := Rect2(
			Vector2(
				relative_position.x / destination.size.x * texture_size.x,
				relative_position.y / destination.size.y * texture_size.y
			),
			Vector2(
				compact_destination.size.x / destination.size.x * texture_size.x,
				compact_destination.size.y / destination.size.y * texture_size.y
			)
		)
		canvas.draw_texture_rect_region(texture, compact_destination, source, modulate)
	else:
		canvas.draw_texture_rect(texture, destination, false, modulate)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _edge_midpoint(cell: Vector2i, side: int, tile_size: float) -> Vector2:
	var top_left := Vector2(cell) * tile_size
	match side:
		0:
			return top_left + Vector2(tile_size * 0.5, 0.0)
		1:
			return top_left + Vector2(tile_size, tile_size * 0.5)
		2:
			return top_left + Vector2(tile_size * 0.5, tile_size)
		_:
			return top_left + Vector2(0.0, tile_size * 0.5)


static func _corner_anchor(cell: Vector2i, corner: int, tile_size: float) -> Vector2:
	var top_left := Vector2(cell) * tile_size
	match corner:
		0: # UP + RIGHT
			return top_left + Vector2(tile_size, 0.0)
		1: # RIGHT + DOWN
			return top_left + Vector2(tile_size, tile_size)
		2: # DOWN + LEFT
			return top_left + Vector2(0.0, tile_size)
		_: # LEFT + UP
			return top_left
