extends SceneTree
## Exact native raster comparison of the three untextured Polygon2D use cases.
var output: String
var results: Array[Dictionary] = []
var holder: Node2D

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.content_scale_size = Vector2i(1696, 780)
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = load("res://assets/mossvein/cave-floor.png")
	floor_sprite.centered = false
	floor_sprite.region_enabled = true
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.region_rect = Rect2(0, 0, 1696, 780)
	root.add_child(floor_sprite)
	holder = Node2D.new()
	holder.position = Vector2(848, 390)
	root.add_child(holder)
	var shadow := PackedVector2Array([-Vector2(23,6), Vector2(23,-6), Vector2(29,1), Vector2(21,8), Vector2(-21,8), Vector2(-29,1)])
	await _pair("shadow", shadow, Color(0.025,0.02,0.012,0.32))
	holder.scale = Vector2(2.75,2.75)
	await _pair("shadow_scaled", shadow, Color(0.025,0.02,0.012,0.32))
	holder.scale = Vector2(-1.0,1.0)
	await _pair("shadow_mirrored", shadow, Color(0.025,0.02,0.012,0.32))
	holder.scale = Vector2.ONE
	holder.modulate = Color(0.68,0.72,0.81,0.75)
	await _pair("shadow_modulated", shadow, Color(0.025,0.02,0.012,0.32))
	holder.modulate = Color.WHITE
	await _pair("bake_black_quad", PackedVector2Array([Vector2(-140,-90),Vector2(140,-90),Vector2(140,90),Vector2(-140,90)]), Color.BLACK)
	var circle := PackedVector2Array()
	for index in 36:
		circle.append(Vector2.from_angle(TAU * float(index) / 36.0) * 86.0)
	for empowered in [false,true]:
		for alpha in [0.035,0.075,0.115,0.16]:
			await _pair("hazard_%s_%s" % [str(empowered),str(alpha).replace(".","_")],circle,Color(Color("ff8a52") if empowered else Color("ffc568"),alpha))
	var ambient := CanvasModulate.new()
	ambient.color = Color(0.42,0.44,0.48)
	root.add_child(ambient)
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1,1,1,0)])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	var lamp := PointLight2D.new()
	lamp.texture = texture
	lamp.position = Vector2(820,350)
	lamp.texture_scale = 3.0
	lamp.energy = 0.8
	lamp.color = Color("ffe2a1")
	root.add_child(lamp)
	await _pair("shadow_lit",shadow,Color(0.025,0.02,0.012,0.32))
	await _pair("hazard_lit",circle,Color(Color("ffc568"),0.16))
	var ok := true
	for item in results: ok = ok and bool(item.exact_rgba) and bool(item.visible)
	var report := {"ok":ok,"renderer":RenderingServer.get_video_adapter_name(),"physical_iphone":false,"pairs":results,
		"source_sha256":FileAccess.get_sha256("res://scripts/rendering/flat_polygon_2d.gd"),"harness_sha256":FileAccess.get_sha256("res://tools/webgl_polygon_pilot/review_flat_polygon.gd")}
	FileAccess.open(output.path_join("flat-polygon.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("FLAT_POLYGON_REVIEW_FINISHED " + JSON.stringify(report))
	quit(0 if ok else 4)

func _pair(id: String, points: PackedVector2Array, tint: Color) -> void:
	await _settle()
	var empty := root.get_texture().get_image()
	var native := Polygon2D.new()
	native.polygon = points
	native.color = tint
	holder.add_child(native)
	await _settle()
	# Exercise the existing repeated-draw path, including hide/show visibility.
	native.hide()
	await _settle()
	native.show()
	native.queue_redraw()
	await _settle()
	var reference := root.get_texture().get_image()
	holder.remove_child(native)
	native.free()
	var flat := FlatPolygon2D.new()
	flat.polygon = points
	flat.color = tint
	holder.add_child(flat)
	await _settle()
	flat.hide()
	await _settle()
	flat.show()
	flat.queue_redraw()
	await _settle()
	var candidate := root.get_texture().get_image()
	reference.save_png(output.path_join(id + "-reference.png"))
	candidate.save_png(output.path_join(id + "-candidate.png"))
	results.append({"id":id,"exact_rgba":reference.get_data()==candidate.get_data(),"visible":empty.get_data()!=reference.get_data(),"framebuffer_size":[candidate.get_width(),candidate.get_height()]})
	holder.remove_child(flat)
	flat.free()

func _settle() -> void:
	for frame in 2: await process_frame
	await RenderingServer.frame_post_draw
