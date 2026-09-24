extends Node
## Isolated QA prototype. Existing world/input/camera remain in their original tree.
## Share only their canvas with a smaller framebuffer; HUD stays on the root window.
var root_view: Viewport
var world: Node2D
var sub: SubViewport
var layer: CanvasLayer
var image: TextureRect
var original_mask: int
var original_layers: int
var scale_factor: float = 1.0

func configure(owner_world: Node2D, factor: float) -> void:
	world = owner_world
	root_view = world.get_viewport()
	original_mask = root_view.canvas_cull_mask
	original_layers = world.visibility_layer
	scale_factor = factor
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = 200
	sub = SubViewport.new()
	sub.name = "QAWorldFramebuffer"
	sub.disable_3d = true
	sub.world_2d = root_view.find_world_2d()
	sub.canvas_cull_mask = 3
	sub.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub)
	layer = CanvasLayer.new()
	layer.layer = -100
	add_child(layer)
	image = TextureRect.new()
	image.texture = sub.get_texture()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_SCALE
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	image.material = material
	layer.add_child(image)
	world.visibility_layer = 2
	root_view.canvas_cull_mask = original_mask & ~2
	_process(0.0)

func _process(_delta: float) -> void:
	if not is_instance_valid(sub): return
	var size: Vector2 = root_view.get_texture().get_size()
	var target := Vector2i((size * scale_factor).round())
	if sub.size != target: sub.size = target
	var ratio := Vector2(target) / size
	sub.global_canvas_transform = Transform2D.IDENTITY.scaled(ratio) * root_view.get_stretch_transform() * root_view.global_canvas_transform
	sub.canvas_transform = root_view.canvas_transform
	image.size = root_view.get_visible_rect().size

func restore() -> void:
	if is_instance_valid(root_view): root_view.canvas_cull_mask = original_mask
	if is_instance_valid(world): world.visibility_layer = original_layers
	if is_instance_valid(layer): layer.hide()
	if is_instance_valid(sub): sub.render_target_update_mode = SubViewport.UPDATE_DISABLED
	queue_free()

func snapshot() -> Dictionary:
	return {"scale":scale_factor,"size":[sub.size.x,sub.size.y],"root_size":[root_view.get_texture().get_width(),root_view.get_texture().get_height()],"logical":[image.size.x,image.size.y]}
