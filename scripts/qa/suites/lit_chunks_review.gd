extends "res://scripts/qa/suites/light_cost.gd"
## Factorial performance and same-state visual comparison of floor chunks and tight cones.
var cone_state: Array[Dictionary] = []
var original_material: Material
var cutout_material: ShaderMaterial

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-area="): area = arg.get_slice("=", 1)
	if DisplayServer.get_name() == "headless":
		fail("Rendered check required"); return
	seed(4608)
	RunState.initialize_persistence(output_dir.path_join("isolated-light-cost-save.json"))
	RunState.reset_run(false)
	RunState.world_seed = 4608
	main.game_started = true
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state():
		fail("Workshops"); return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop).next_upgrade
			RunState.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not bool(RunState.upgrade_workshop(workshop).get("ok", false)):
				fail("Upgrade"); return
	RunState.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if not (main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine", 2)):
		fail("Area"); return
	world = main.hub_world if area == "hub" else main.depth_world
	if area == "hub": world.restore_position(Vector2(1200, 480))
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	for frame in 5: await main.get_tree().process_frame
	original_material = world.material
	var shader: Shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment() { if (COLOR.a <= 0.0) { discard; } }"
	cutout_material = ShaderMaterial.new()
	cutout_material.shader = shader
	for node in world.find_children("HelmetCone", "PointLight2D", true, false):
		var image: Image = node.texture.get_image()
		var used: Rect2i = image.get_used_rect().grow(1).intersection(Rect2i(Vector2i.ZERO, image.get_size()))
		var trimmed: ImageTexture = ImageTexture.create_from_image(image.get_region(used))
		var offset: Vector2 = (Vector2(used.position) + Vector2(used.size) * 0.5 - Vector2(image.get_size()) * 0.5) * float(node.texture_scale)
		cone_state.append({"node":node,"texture":node.texture,"offset":node.offset,"cropped":trimmed,"crop_offset":offset,"before":str(image.get_size()),"after":str(used)})
	for id in ["baseline", "combined", "sections", "optimized", "restored"]:
		set_variant(id)
		await measure(id, 45.0 if id == "baseline" else 20.0)
	# Freeze simulation and time for paired pixels; time spent capturing is not measured.
	var prior_scale: float = Engine.time_scale
	Engine.time_scale = 0.0
	main.get_tree().paused = true
	for id in ["baseline", "combined", "sections", "optimized", "restored"]:
		set_variant(id)
		world.queue_redraw()
		for frame in 4: await main.get_tree().process_frame
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(output_dir.path_join(id + "-paired.png"))
	main.get_tree().paused = false
	Engine.time_scale = prior_scale
	var cropped: Array[Dictionary] = []
	for entry in cone_state: cropped.append({"before":entry.before,"after":entry.after,"offset":str(entry.crop_offset)})
	var report: Dictionary = {"area":area,"physical_iphone":false,"rendered":true,"window":str(DisplayServer.window_get_size()),"stages":rows,"cones":cropped}
	FileAccess.open(output_dir.path_join("lit-chunks.json"), FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("LIT_CHUNKS_COMPLETE " + JSON.stringify(report))
	main.get_tree().quit(0)

func set_variant(id: String) -> void:
	world.lit_floor_chunks.enabled = id in ["floor", "combined", "sections", "optimized"]
	world.lit_draw_sections.enabled = id in ["sections", "optimized"]
	world.material = cutout_material if id in ["cutout", "combined_cutout"] else original_material
	for entry in cone_state:
		entry.node.texture = entry.cropped if id in ["cones", "combined", "optimized"] else entry.texture
		entry.node.offset = entry.crop_offset if id in ["cones", "combined", "optimized"] else entry.offset
	world.queue_redraw()
