extends Node2D
## Keep each floor draw's light list local instead of lighting one world-sized item.
## Texture coordinates, two-pass tint, material and world draw order stay unchanged.
var enabled: bool = true
var chunk_size: int = 256
var _pool: Array[FloorChunk] = []

class FloorChunk extends Node2D:
	var floor_texture: Texture2D
	var area: Rect2
	var source: Rect2
	var tint: Color
	var wash: Color

	func configure(texture: Texture2D, rect: Rect2, uv: Rect2, color: Color, overlay: Color, mask: int) -> void:
		light_mask = mask
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		if floor_texture == texture and area == rect and source == uv and tint == color and wash == overlay:
			return
		floor_texture = texture
		area = rect
		source = uv
		tint = color
		wash = overlay
		queue_redraw()

	func _draw() -> void:
		draw_texture_rect_region(floor_texture, area, source, tint, false, false)
		draw_rect(area, wash, true)

func _init() -> void:
	name = "LitFloorChunks"
	show_behind_parent = true

func draw_floor(owner_canvas: CanvasItem, texture: Texture2D, bounds: Rect2, tint: Color, wash: Color) -> void:
	if not enabled:
		hide()
		owner_canvas.draw_texture_rect(texture, bounds, true, tint)
		owner_canvas.draw_rect(bounds, wash, true)
		return
	show()
	var view_bounds: Rect2 = owner_canvas.get_global_transform_with_canvas().affine_inverse() * owner_canvas.get_viewport_rect()
	view_bounds = view_bounds.grow(float(chunk_size)).intersection(bounds)
	if not view_bounds.has_area():
		for node in _pool: node.hide()
		return
	var first: Vector2i = Vector2i(((view_bounds.position - bounds.position) / float(chunk_size)).floor())
	var last: Vector2i = Vector2i(((view_bounds.end - bounds.position) / float(chunk_size)).ceil())
	var used: int = 0
	for y in range(first.y, last.y):
		for x in range(first.x, last.x):
			var rect: Rect2 = Rect2(bounds.position + Vector2(x, y) * float(chunk_size), Vector2.ONE * float(chunk_size)).intersection(bounds)
			if not rect.has_area(): continue
			if used == _pool.size():
				var created: FloorChunk = FloorChunk.new()
				_pool.append(created)
				add_child(created)
			var chunk: FloorChunk = _pool[used]
			chunk.configure(texture, rect, Rect2(rect.position - bounds.position, rect.size), tint, wash, owner_canvas.light_mask)
			chunk.show()
			used += 1
	for index in range(used, _pool.size()): _pool[index].hide()
