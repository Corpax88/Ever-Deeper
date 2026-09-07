extends "res://scripts/qa/suites/journey_performance.gd"
## Wall-clock frames and engine CPU counters are separate. Headless is CPU-only.
## Runs only in isolated QA saves; exported release builds retain the checks.
var rows: Array[Dictionary] = []
var driver: Node
var output_dir: String = "user://mobile-performance"
var captures: bool = false

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-output="): output_dir = arg.get_slice("=", 1)
		if arg == "--perf-capture": captures = true
	DirAccess.make_dir_recursive_absolute(output_dir)
	seed(4608)
	RunState.reset_run(false)
	RunState.world_seed = 4608
	main.game_started = true
	main._dev_jump_surface()
	for world_id in ["moonglass", "emberdeep", "starfall"]: RunState.unlock_world(world_id)
	for item in [["mossvein", 420], ["portal_seam", 1070], ["moonglass", 1760], ["emberdeep", 2800], ["starfall", 3930]]:
		main.surface_world.restore_position(Vector2(float(item[1]), 650))
		await measure("surface_" + String(item[0]), main.surface_world, true)
	for mine_id in main.MINE_IDS:
		_prepare_journey_mine_performance(mine_id)
		main.mine_world.player.set_external_movement(Vector2.ZERO)
		await measure(String(mine_id) + "_depth_1_mining", main.mine_world, true, true)
	for mine_id in main.MINE_IDS:
		if not main._dev_jump_mine(mine_id, 2):
			fail("Cannot enter " + String(mine_id)); return
		await measure(String(mine_id) + "_depth_2_mining", main.depth_world, true, true)
	if not main._dev_jump_hub(): fail("Cannot enter hub"); return
	await measure("base_hub", main.hub_world, true)
	if not main._dev_jump_deepheart(): fail("Cannot enter Deepheart"); return
	await measure("deepheart", main.deepheart_world, true)
	for depth in [1, 12]:
		if not main._dev_jump_endless(depth): fail("Cannot enter The Deep"); return
		await measure("the_deep_" + str(depth), main.endless_world, true, true)
	driver = load("res://scripts/dev/visual_capture_driver.gd").new()
	main.add_child(driver)
	driver.set("_main", main)
	for fixture in ["starforge_ready_crusher", "workshop_tool_forge_baseline", "workshop_light_lab_baseline", "workshop_wardrobe_baseline"]:
		driver.call("_prepare_commerce_capture", fixture)
		await measure(fixture, main.get(String(main.phase) + "_world"))
		main.commerce_panel.close_commerce()
	main._dev_jump_surface()
	main.get_node("CompanionInterface").open_skills()
	await measure("companion_journal", main.surface_world)
	var save: Dictionary = _measure_journey_mature_save()
	var report: Dictionary = {
		"version": ProjectSettings.get_setting("application/config/version"),
		"display_driver": DisplayServer.get_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(),
		"rendered": DisplayServer.get_name() != "headless",
		"viewport": str(main.get_viewport().get_visible_rect().size),
		"physical_iphone": false,
		"save": save, "stages": rows,
	}
	FileAccess.open(output_dir.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("EVER_DEEPER_MOBILE_PERFORMANCE_COMPLETE stages=%d rendered=%s physical_iphone=false" % [rows.size(), str(report.rendered)])
	main.get_tree().quit(0)

func fail(message: String) -> void:
	push_error("MOBILE_PERFORMANCE_FAILED: " + message)
	main.get_tree().quit(2)

func measure(label: String, world: Node, moving: bool = false, mining: bool = false) -> void:
	var player: Node2D = world.get("player")
	player.set_external_movement(Vector2.ZERO)
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()
	await main.get_tree().create_timer(2.0).timeout
	if captures and DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(output_dir.path_join(label + ".png"))
	var start_position: Vector2 = player.global_position
	if moving: player.set_external_movement(Vector2.RIGHT)
	if mining and world.has_method("set_mine_held"): world.set_mine_held(true)
	var frame_ms: Array[float] = []
	var cpu_ms: Array[float] = []
	var physics_ms: Array[float] = []
	var draw_calls: Array[float] = []
	var now: int = Time.get_ticks_usec()
	var deadline: int = now + 3000000
	while now < deadline:
		var previous: int = now
		await main.get_tree().process_frame
		now = Time.get_ticks_usec()
		frame_ms.append(float(now - previous) / 1000.0)
		cpu_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	player.set_external_movement(Vector2.ZERO)
	if mining and world.has_method("set_mine_held"): world.set_mine_held(false)
	var stats: Dictionary = _journey_performance_frame_stats(frame_ms)
	cpu_ms.sort(); physics_ms.sort(); draw_calls.sort()
	stats.merge({"stage": label, "process_p95_ms": _journey_percentile(cpu_ms, 0.95),
		"physics_p95_ms": _journey_percentile(physics_ms, 0.95),
		"draw_calls_p95": _journey_percentile(draw_calls, 0.95),
		"static_mib": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"moved_pixels": start_position.distance_to(player.global_position),
		"smooth_60_target_met": float(stats.average_fps) >= 58.0 and float(stats.p95_ms) <= 20.0 and int(stats.slow_frames) == 0,
	})
	# These diagnostic calls are outside the frame sample and leave game state intact.
	var occluders: Node = world.get_node_or_null("CaveLightOccluders")
	if occluders != null:
		var begin: int = Time.get_ticks_usec()
		for i in 40: occluders.refresh()
		stats["occlusion_refresh_mean_ms"] = float(Time.get_ticks_usec() - begin) / 40000.0
	var lamp: Node = player.get_node_or_null("PremiumHeadlamp")
	if lamp != null:
		var begin: int = Time.get_ticks_usec()
		for i in 100: lamp.set_direction(player.facing_vector)
		stats["lamp_refresh_mean_ms"] = float(Time.get_ticks_usec() - begin) / 100000.0
	rows.append(stats)
	print("EVER_DEEPER_MOBILE_STAGE " + JSON.stringify(stats))
