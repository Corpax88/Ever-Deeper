extends Node2D
## Keep each floor draw's light list local instead of lighting one world-sized item.
## Share lighting across the floor and color wash; retain two passes for comparison.
var enabled: bool = true
var chunk_size: int = 256
# Optional conservative opaque-terrain culling; callers own the visible regions.
var restrict_to_regions: bool = false
var visible_regions: Array[Rect2] = []
var composite_pass: bool = true
var _composite_material: ShaderMaterial
var _composite_tint := Color.TRANSPARENT
var _composite_wash := Color.TRANSPARENT
var _pool: Array[FloorChunk] = []
var _fixed_field_material: ShaderMaterial
var _fixed_field_mask: int = 0
var _owner_light_mask: int = 1

func set_fixed_field(draw_material: ShaderMaterial, mask: int) -> void:
	_fixed_field_material = draw_material
	_fixed_field_mask = mask
	if draw_material != null:
		draw_material.set_shader_parameter("floor_tint", _composite_tint)
		draw_material.set_shader_parameter("floor_wash", _composite_wash)
	for node in _pool: node.light_mask = mask if draw_material != null else _owner_light_mask
	if get_parent() is CanvasItem: get_parent().queue_redraw()

class FloorChunk extends Node2D:
	var floor_texture: Texture2D
	var area: Rect2
	var source: Rect2
	var tint: Color
	var wash: Color
	var underlay: Color

	func configure(texture: Texture2D, rect: Rect2, uv: Rect2, color: Color, overlay: Color, mask: int, draw_material: ShaderMaterial, background: Color) -> void:
		light_mask = mask
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		if floor_texture == texture and area == rect and source == uv and tint == color and wash == overlay and material == draw_material and underlay == background:
			return
		material = draw_material
		floor_texture = texture
		area = rect
		source = uv
		tint = color
		wash = overlay
		underlay = background
		queue_redraw()

	func _draw() -> void:
		if underlay.a > 0.0: draw_rect(area, underlay, true)
		draw_texture_rect_region(floor_texture, area, source, Color.WHITE if material != null else tint, false, false)
		if material == null and wash.a > 0.0: draw_rect(area, wash, true)

func _init() -> void:
	name = "LitFloorChunks"
	show_behind_parent = true

func draw_floor(owner_canvas: CanvasItem, texture: Texture2D, bounds: Rect2, tint: Color, wash: Color, underlay: Color = Color.TRANSPARENT) -> void:
	_owner_light_mask = owner_canvas.light_mask
	if not enabled:
		hide()
		if underlay.a > 0.0: owner_canvas.draw_rect(bounds, underlay, true)
		owner_canvas.draw_texture_rect(texture, bounds, true, tint)
		if wash.a > 0.0: owner_canvas.draw_rect(bounds, wash, true)
		return
	show()
	if composite_pass:
		if _composite_material == null:
			_composite_material = ShaderMaterial.new()
			_composite_material.shader = load("res://shaders/lit_floor_composite.gdshader")
		if _composite_tint != tint:
			_composite_tint = tint
			_composite_material.set_shader_parameter("floor_tint", tint)
			if _fixed_field_material != null: _fixed_field_material.set_shader_parameter("floor_tint", tint)
		if _composite_wash != wash:
			_composite_wash = wash
			_composite_material.set_shader_parameter("floor_wash", wash)
			if _fixed_field_material != null: _fixed_field_material.set_shader_parameter("floor_wash", wash)
	var view_bounds: Rect2 = owner_canvas.get_global_transform_with_canvas().affine_inverse() * owner_canvas.get_viewport_rect()
	view_bounds = view_bounds.grow(float(chunk_size)).intersection(bounds)
	if not view_bounds.has_area():
		for node in _pool: node.hide()
		return
	var first: Vector2i = Vector2i(((view_bounds.position - bounds.position) / float(chunk_size)).floor())
	var last: Vector2i = Vector2i(((view_bounds.end - bounds.position) / float(chunk_size)).ceil())
	var areas: Array[Rect2] = []
	if restrict_to_regions:
		for region in visible_regions:
			var clipped: Rect2 = region.intersection(bounds)
			if clipped.has_area() and clipped.intersects(view_bounds): areas.append(clipped)
	else:
		for y in range(first.y, last.y):
			for x in range(first.x, last.x):
				var rect: Rect2 = Rect2(bounds.position + Vector2(x, y) * float(chunk_size), Vector2.ONE * float(chunk_size)).intersection(bounds)
				if rect.has_area(): areas.append(rect)
	var used: int = 0
	for rect in areas:
		if used == _pool.size():
			var created: FloorChunk = FloorChunk.new()
			_pool.append(created)
			add_child(created)
		var chunk: FloorChunk = _pool[used]
		var draw_material: ShaderMaterial = _fixed_field_material if _fixed_field_material != null else _composite_material
		var mask: int = _fixed_field_mask if composite_pass and _fixed_field_material != null else owner_canvas.light_mask
		chunk.configure(texture, rect, Rect2(rect.position - bounds.position, rect.size), tint, wash, mask, draw_material if composite_pass else null, underlay)
		chunk.show()
		used += 1
	for index in range(used, _pool.size()): _pool[index].hide()
