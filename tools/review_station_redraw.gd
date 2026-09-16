extends SceneTree
## Real station animation versus a freshly redrawn terrain frame at the same clock.
var output: String
var main: Node
var world: Node
var results: Array[Dictionary] = []
var sample_seconds: float = 20.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument.begins_with("--seconds="): sample_seconds = float(argument.trim_prefix("--seconds="))
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_mine("emberMine", 2)
	world = main.depth_world
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	await create_timer(4.0).timeout
	world.lit_draw_sections.profile_draws = true
	var initial: Dictionary = world.lit_draw_sections.debug_snapshot()
	var frames: Array[float] = []
	var started: int = Time.get_ticks_usec()
	var previous: int = started
	while Time.get_ticks_usec() - started < int(sample_seconds * 1000000.0):
		await process_frame
		var now: int = Time.get_ticks_usec()
		frames.append(float(now - previous) / 1000.0)
		previous = now
	var total: float = float(Time.get_ticks_usec() - started) / 1000.0
	frames.sort()
	var final: Dictionary = world.lit_draw_sections.debug_snapshot()
	var timing: Dictionary = {"seconds":total / 1000.0,"fps":1000.0 * frames.size() / total,"p95_ms":frames[floori(frames.size() * 0.95)],"before":initial,"after":final,"station_distance":world.player.global_position.distance_to(world.wayfarer_position)}
	# Freeze gameplay without traversing transient/freed child nodes. Drawing
	# still runs; the normal world process below advances the station manually.
	main.process_mode = Node.PROCESS_MODE_DISABLED
	main.get_node("HUD").hide()
	for tween in get_processed_tweens(): tween.pause()
	world.player.set_external_movement(Vector2.ZERO)
	# The timing uses the real entry. The visual pairs must include the animated
	# boots, which can sit just outside that initial camera's upper edge.
	world.player.position = world._nearest_safe_position(world.wayfarer_position + Vector2(0, 100))
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.position = Vector2.ZERO
	world.player.camera.offset = Vector2.ZERO
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.queue_redraw()
	await _settle()
	for clock in [0.0, 0.25, 0.75, 1.5, 3.5, 5.75]:
		world.station_animation_clock = clock
		world.station_redraw_clock = 0.05
		world.redraw_elapsed = world.REDRAW_INTERVAL
		var before: Dictionary = world.lit_draw_sections.debug_snapshot()
		world._process(0.001)
		await _settle()
		var animated: Image = root.get_texture().get_image()
		var after: Dictionary = world.lit_draw_sections.debug_snapshot()
		world.queue_redraw()
		await _settle()
		var fresh: Image = root.get_texture().get_image()
		var equal: bool = animated.get_data() == fresh.get_data()
		var id: String = "clock_%s" % str(clock).replace(".", "_")
		animated.save_png(output.path_join(id + "-animated.png"))
		fresh.save_png(output.path_join(id + "-fresh.png"))
		results.append({"id":id,"exact_rgba":equal,"framebuffer_size":[animated.get_width(),animated.get_height()],"terrain_reuses_during_animation":int(after.reuses) - int(before.reuses),"setup_us_during_animation":int(after.setup_usec) - int(before.setup_usec),"draw_callbacks_during_animation":int(after.draw_callbacks) - int(before.draw_callbacks)})
		assert(equal, "Station-only frame must exactly match a fresh full redraw")
	var hashes: Dictionary = {}
	for path in ["scripts/lighting/lit_draw_sections.gd", "scripts/world/depth/rootwound_world.gd", "tools/review_station_redraw.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report: Dictionary = {"renderer":RenderingServer.get_video_adapter_name(),"physical_iphone":false,"seed":state.world_seed,"terrain_hash":hash(world.terrain_hp),"player":str(world.player.position),"timing":timing,"pairs":results,"source_sha256":hashes}
	FileAccess.open(output.path_join("station-redraw.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("STATION_REDRAW_COMPLETE " + JSON.stringify(report))
	quit()

func _settle() -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
