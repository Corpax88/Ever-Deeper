extends Node
## Study candidate: submit the shared lit-polygon variant in the first render.
## Main stays synchronous. This does not promise to precede every input event.

const DrawSections := preload("res://scripts/lighting/lit_draw_sections.gd")
static var _started: bool = false
var _viewport: SubViewport


class WarmupTriangles:
	extends Node2D

	func _draw() -> void:
		# Direct canvas triangles avoid Polygon2D's mesh index-update path.
		# Empty indices and default count=-1 retain nonindexed submission.
		var color := Color(0.2, 0.2, 0.2, 1.0)
		RenderingServer.canvas_item_add_triangle_array(
			get_canvas_item(), PackedInt32Array(),
			PackedVector2Array([
				Vector2(2, 2), Vector2(14, 2), Vector2(14, 14),
				Vector2(2, 2), Vector2(14, 14), Vector2(2, 14),
			]),
			PackedColorArray([color, color, color, color, color, color]),
			PackedVector2Array()
		)


func _ready() -> void:
	name = "FirstFrameLitWarmup"
	if _started or DisplayServer.get_name() == "headless":
		queue_free()
		return
	_started = true
	_viewport = SubViewport.new()
	_viewport.name = "LitWarmupViewport"
	_viewport.size = Vector2i(16, 16)
	_viewport.disable_3d = true
	_viewport.gui_disable_input = true
	_viewport.handle_input_locally = false
	_viewport.world_2d = World2D.new()
	_viewport.transparent_bg = true
	_viewport.use_hdr_2d = get_viewport().use_hdr_2d
	_viewport.msaa_2d = get_viewport().msaa_2d
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	var polygon := WarmupTriangles.new()
	polygon.name = "LitWarmupPolygon"
	polygon.material = DrawSections.VISIBLE_PIXELS_MATERIAL
	polygon.light_mask = 1
	_viewport.add_child(polygon)
	var light_image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	light_image.fill(Color.WHITE)
	var light := PointLight2D.new()
	light.name = "LitWarmupLight"
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
