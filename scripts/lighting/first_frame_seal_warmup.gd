extends Node
## Isolated study helper; not yet installed by Main.
## Submit the existing relic-seal shader through a lit sprite once.
const SealShader := preload("res://shaders/lit_relic_seal.gdshader")
const SealTexture := preload("res://assets/surface/emberdeep-seal-mark.png")
static var _started: bool = false
var _viewport: SubViewport


func _ready() -> void:
	name = "FirstFrameSealWarmup"
	if _started or DisplayServer.get_name() == "headless":
		queue_free()
		return
	_started = true
	_viewport = SubViewport.new()
	_viewport.name = "SealWarmupViewport"
	_viewport.size = Vector2i(16, 16)
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.handle_input_locally = false
	_viewport.world_2d = World2D.new()
	_viewport.transparent_bg = true
	_viewport.use_hdr_2d = get_viewport().use_hdr_2d
	_viewport.msaa_2d = get_viewport().msaa_2d
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var sprite := Sprite2D.new()
	sprite.name = "SealWarmupSprite"
	sprite.texture = SealTexture
	sprite.position = Vector2(8, 8)
	sprite.scale = Vector2.ONE * (12.0 / maxf(SealTexture.get_width(), SealTexture.get_height()))
	sprite.light_mask = 1
	var material := ShaderMaterial.new()
	material.shader = SealShader
	material.set_shader_parameter("resonance", Color("7be6d0"))
	material.set_shader_parameter("strength", 0.65)
	sprite.material = material
	_viewport.add_child(sprite)
	var light_image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	light_image.fill(Color.WHITE)
	var light := PointLight2D.new()
	light.name = "SealWarmupLight"
	light.texture = ImageTexture.create_from_image(light_image)
	light.position = Vector2(8, 8)
	light.energy = 0.5
	light.range_item_cull_mask = 1
	light.range_z_min = -1
	light.range_z_max = 1
	light.shadow_enabled = false
	_viewport.add_child(light)
	add_child(_viewport)
	RenderingServer.frame_post_draw.connect(_after_draw, CONNECT_ONE_SHOT)
	_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func _after_draw() -> void:
	queue_free()


func _exit_tree() -> void:
	if RenderingServer.frame_post_draw.is_connected(_after_draw):
		RenderingServer.frame_post_draw.disconnect(_after_draw)
