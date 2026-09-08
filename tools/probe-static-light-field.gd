extends SceneTree
## Study only: combine unchanged, shadow-free fixed lamps in the published DEV8 PCK.
var output_dir := ""
var area := "hub"
var world: Node2D
var main: Node
var sources: Array[Dictionary] = []
var fields: Array[PointLight2D] = []
var bake_info: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("STATIC_FIELD_FAIL " + message)
		quit(2)
	return ok

func set_variant(index: int) -> void:
	for entry in sources:
		if is_instance_valid(entry.node): entry.node.enabled = entry.enabled and index < 0
	for i in fields.size(): fields[i].enabled = i == index

func bake(density: float) -> PointLight2D:
	var bounds := Rect2()
	for entry in sources:
		var light: PointLight2D = entry.node
		var local_transform: Transform2D = world.global_transform.affine_inverse() * light.global_transform
		var size: Vector2 = light.texture.get_size() * light.texture_scale
		var rect: Rect2 = local_transform * Rect2(light.offset - size * 0.5, size)
		bounds = bounds.merge(rect) if bounds.has_area() else rect
	bounds = Rect2(bounds.position.floor() - Vector2.ONE * 2.0, bounds.end.ceil() - bounds.position.floor() + Vector2.ONE * 4.0)
	var size := Vector2i((bounds.size * density).ceil())
	if not check(size.x <= 8192 and size.y <= 8192, "Bounded field texture"): return null
	var viewport := SubViewport.new()
	viewport.size = size
	viewport.world_2d = World2D.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.canvas_transform = Transform2D(Vector2(density, 0), Vector2(0, density), -bounds.position * density)
	root.add_child(viewport)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([bounds.position, Vector2(bounds.end.x, bounds.position.y), bounds.end, Vector2(bounds.position.x, bounds.end.y)])
	background.color = Color.BLACK
	viewport.add_child(background)
	var shader := Shader.new()
	shader.code = "shader_type canvas_item; render_mode unshaded, blend_add; void fragment() { COLOR = vec4(COLOR.rgb * COLOR.a, 1.0); }"
	var material := ShaderMaterial.new()
	material.shader = shader
	var sprites: Array[Sprite2D] = []
	for entry in sources:
		var light: PointLight2D = entry.node
		var sprite := Sprite2D.new()
		sprite.texture = light.texture
		sprite.transform = world.global_transform.affine_inverse() * light.global_transform
		sprite.scale *= light.texture_scale
		sprite.offset = light.offset / light.texture_scale
		sprite.material = material
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		viewport.add_child(sprite)
		sprites.append(sprite)
	var normalization := 2.0
	var image: Image
	var maximum := 1.0
	while maximum >= 0.98 and normalization <= 16.0:
		for i in sources.size():
			var light: PointLight2D = sources[i].node
			sprites[i].modulate = Color(light.color.r * light.energy / normalization, light.color.g * light.energy / normalization, light.color.b * light.energy / normalization, light.color.a)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
		await RenderingServer.frame_post_draw
		image = viewport.get_texture().get_image()
		maximum = 0.0
		# All channels are scanned once; reject saturated irradiance instead of clipping it.
		var bytes := image.get_data()
		for i in range(0, bytes.size(), 4):
			maximum = maxf(maximum, float(maxi(bytes[i], maxi(bytes[i + 1], bytes[i + 2]))) / 255.0)
		if maximum >= 0.98: normalization *= 2.0
	if not check(maximum < 0.98, "Unclipped irradiance"): return null
	var field := PointLight2D.new()
	field.name = "StaticFieldStudy_%d" % fields.size()
	field.texture = ImageTexture.create_from_image(image)
	field.texture_scale = 1.0 / density
	field.position = bounds.get_center()
	field.color = Color.WHITE
	field.energy = normalization
	field.enabled = false
	world.add_child(field)
	viewport.queue_free()
	fields.append(field)
	bake_info.append({"density":density,"size":str(size),"bounds":str(bounds),"normalization":normalization,"maximum":maximum,"sources":sources.size()})
	return field

func capture(id: String) -> void:
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join(id + ".png"))

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=", 1)
		if arg.begins_with("--area="): area = arg.get_slice("=", 1)
	if not check(not output_dir.is_empty() and OS.has_feature("ever_deeper_dev") and DisplayServer.get_name() != "headless", "Rendered DEV package required"): return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-static-field-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	if not check(main._dev_build_all_workshops_state(), "Workshops"): return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = state.workshop_status(workshop).next_upgrade
			state.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not check(bool(state.upgrade_workshop(workshop).get("ok", false)), "Upgrade"): return
	state.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if not check(main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine", 2), "Enter area"): return
	world = main.hub_world if area == "hub" else main.depth_world
	if area == "hub": world.restore_position(Vector2(1200, 480))
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	for frame in 5: await process_frame
	for node in world.find_children("*", "PointLight2D", true, false):
		var path: String = str(world.get_path_to(node))
		if path.begins_with("Player/") or "MoleCompanion" in path or not node.enabled: continue
		if not check(not node.shadow_enabled and node.blend_mode == Light2D.BLEND_MODE_ADD and node.range_item_cull_mask == 1 and node.height == 0.0, "Fixed flat additive source " + path): return
		sources.append({"node":node,"enabled":node.enabled,"path":path})
	if not check(not sources.is_empty(), "Fixed lamps found"): return
	var meter: RefCounted = load("res://scripts/qa/suites/light_cost.gd").new(main, output_dir)
	await meter.measure("original", 45.0)
	if await bake(1.0) == null: return
	if await bake(2.0) == null: return
	for index in fields.size():
		set_variant(index)
		await meter.measure("field_%d" % index, 25.0)
	set_variant(-1)
	await meter.measure("restored", 20.0)
	var prior_scale: float = Engine.time_scale
	Engine.time_scale = 0.0
	paused = true
	await capture("baseline-paired")
	for index in fields.size():
		set_variant(index)
		await capture("field_%d-paired" % index)
	set_variant(-1)
	await capture("restored-paired")
	paused = false
	Engine.time_scale = prior_scale
	for entry in sources:
		if not check(is_instance_valid(entry.node) and entry.node.enabled == entry.enabled, "Source restored " + entry.path): return
	var report := {"package_version":"0.46.9-dev.8","area":area,"physical_iphone":false,"stages":meter.rows,"bakes":bake_info,"restored":true}
	FileAccess.open(output_dir.path_join("static-field.json"), FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("STATIC_FIELD_OK " + JSON.stringify(report))
	quit(0)
