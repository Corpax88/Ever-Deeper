extends Node2D
# QA-only cached sum of fixed, flat ADD lights. Original lights remain reversible.
var ready_for_use: bool = false
var active: bool = false
var sources: Array[PointLight2D] = []
var original: Array[bool] = []
var entries: Array[Dictionary] = []
var field: PointLight2D
var bounds: Rect2
var normalization: float = 1.0
var bake_usec: int = 0
const DENSITY: float = 2.0

func configure(world: Node2D, lights: Array[PointLight2D]) -> void:
	var begin: int = Time.get_ticks_usec()
	for light in lights:
		if not str(light.get_parent().name).begins_with("WorkLight_"): continue
		if light.shadow_enabled or light.blend_mode != Light2D.BLEND_MODE_ADD or light.height != 0.0 or light.range_item_cull_mask != 1: return
		if not light.texture is GradientTexture2D: return
		sources.append(light)
		original.append(light.enabled)
		var transform: Transform2D = world.global_transform.affine_inverse() * light.global_transform
		var size: Vector2 = light.texture.get_size() * light.texture_scale
		var rect: Rect2 = transform * Rect2(light.offset-size*0.5,size)
		bounds = bounds.merge(rect) if bounds.has_area() else rect
		entries.append({"rect":rect,"weight":maxf(light.color.r,maxf(light.color.g,light.color.b))*light.color.a*light.energy})
	if sources.size() < 2: return
	bounds = Rect2(bounds.position.floor()-Vector2.ONE*2,bounds.end.ceil()-bounds.position.floor()+Vector2.ONE*4)
	normalization = _energy_bound()
	var pixels: Vector2i = Vector2i(bounds.size*DENSITY)
	if pixels.x>4096 or pixels.y>4096: return
	var viewport: SubViewport = SubViewport.new()
	viewport.size = pixels
	viewport.world_2d = World2D.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	viewport.canvas_transform = Transform2D(0.0,Vector2.ONE*DENSITY,0.0,-bounds.position*DENSITY)
	var background: Polygon2D = Polygon2D.new()
	background.polygon = PackedVector2Array([bounds.position,Vector2(bounds.end.x,bounds.position.y),bounds.end,Vector2(bounds.position.x,bounds.end.y)])
	background.color = Color.BLACK
	viewport.add_child(background)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://shaders/static_light_bake.gdshader")
	for light in sources:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture = light.texture
		sprite.transform = world.global_transform.affine_inverse()*light.global_transform
		sprite.scale *= light.texture_scale
		sprite.offset = light.offset/light.texture_scale
		sprite.material = material
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.modulate = Color(light.color.r*light.energy/normalization,light.color.g*light.energy/normalization,light.color.b*light.energy/normalization,light.color.a)
		viewport.add_child(sprite)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	if not is_instance_valid(viewport): return
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	if image.is_empty(): return
	field = PointLight2D.new()
	field.name = "QAMergedFixedLight"
	field.enabled = false
	field.texture = ImageTexture.create_from_image(image)
	field.texture_scale = 1.0/DENSITY
	field.position = bounds.get_center()
	field.energy = normalization
	add_child(field)
	bake_usec = Time.get_ticks_usec()-begin
	ready_for_use = true

func select(value: bool) -> void:
	active = value and ready_for_use
	for i in sources.size():
		if is_instance_valid(sources[i]): sources[i].enabled = false if active else original[i]
	if is_instance_valid(field): field.enabled = active

func snapshot() -> Dictionary:
	return {"ready":ready_for_use,"active":active,"field_enabled":field.enabled if is_instance_valid(field) else false,"sources":sources.size(),"density":DENSITY,"bounds":bounds,"normalization":normalization,"texture_size":field.texture.get_size() if is_instance_valid(field) else Vector2.ZERO,"bake_usec":bake_usec}

func _energy_bound() -> float:
	var xs: Array[float] = []
	var ys: Array[float] = []
	for entry in entries:
		xs.append(entry.rect.position.x); xs.append(entry.rect.end.x)
		ys.append(entry.rect.position.y); ys.append(entry.rect.end.y)
	xs.sort(); ys.sort()
	var maximum: float = 1.0
	for xi in range(xs.size() - 1):
		for yi in range(ys.size() - 1):
			var point := Vector2((xs[xi] + xs[xi + 1]) * 0.5, (ys[yi] + ys[yi + 1]) * 0.5)
			var weight: float = 0.0
			for entry in entries:
				if entry.rect.has_point(point): weight += entry.weight
			maximum = maxf(maximum, weight)
	return ceilf(maximum * 1.01)

