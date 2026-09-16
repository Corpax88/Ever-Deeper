extends SceneTree
## Five native geology boundaries, including an origin shift at the same place.
var output: String
var main: Node
var world: Node
var captures: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_endless(6)
	world = main.endless_world
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	world.player.prepare_visual_cache()
	while world.player.visual.active_gear != "worn": await process_frame
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.visual.set_process(false)
	world.player.camera.position_smoothing_enabled = false
	main.get_node("HUD").hide()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null: mole.set_physics_process(false)
	for depth in range(5, 10):
		world.current_depth = depth
		world._generate_stream_window(depth)
		var column: int = world.DeepLayout.entrance_column(4608, depth + 1)
		world.player.position = world._nearest_walkable_position(Vector2(column * 64 + 32, 1388))
		world.player.z_index = world.actor_draw_depth(world.player.position)
		world.player.set_facing(Vector2.DOWN)
		world.player._update_visual(false)
		world.player.visual._draw_frame(0.0)
		await _capture("boundary_%d_%d" % [depth, depth + 1])
		if depth == 7:
			# Shift the resident window while leaving the absolute viewpoint fixed.
			world._rebase_stream_window(depth - 1)
			await _capture("boundary_7_8_rebased")
	FileAccess.open(output.path_join("deep-boundaries.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"rendered":true, "physical_iphone":false, "performance_evidence":false,
		"native_floor_density_preserved":true, "captures":captures,
	}, "\t"))
	quit()

func _capture(id: String) -> void:
	world.queue_redraw()
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.save_png(output.path_join(id + ".png"))
	captures.append({"id":id, "framebuffer":str(image.get_size()),
		"player":str(world.player.position), "window_start_depth":world.window_start_depth,
		"camera":str(world.player.camera.get_screen_center_position()),
		"absolute_player":str(world.player.position + Vector2(0, (world.window_start_depth - 1) * world.CHUNK_HEIGHT)),
	})
