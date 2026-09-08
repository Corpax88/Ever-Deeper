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
	if "--perf-floor-pass" in OS.get_cmdline_user_args():
		var reviewer = load("res://scripts/qa/suites/floor_pass_review.gd").new(main, output_dir)
		await reviewer.run()
		return
	if "--perf-lighting-release" in OS.get_cmdline_user_args():
		var reviewer = load("res://scripts/qa/suites/lighting_release_review.gd").new(main, output_dir)
		await reviewer.run()
		return
	if "--perf-lit-chunks" in OS.get_cmdline_user_args():
		var reviewer = load("res://scripts/qa/suites/lit_chunks_review.gd").new(main, output_dir)
		await reviewer.run()
		return
	if "--perf-light-cost" in OS.get_cmdline_user_args():
		var reviewer = load("res://scripts/qa/suites/light_cost.gd").new(main, output_dir)
		await reviewer.run()
		return
	if "--perf-render-probe-review" in OS.get_cmdline_user_args():
		var reviewer = load("res://scripts/qa/suites/render_probe_review.gd").new(main, output_dir)
		await reviewer.run()
		return
	if "--perf-floor-review" in OS.get_cmdline_user_args():
		await review_floor_release()
		return
	if "--perf-meter-review" in OS.get_cmdline_user_args():
		await review_meter()
		return
	if "--perf-mossvein" in OS.get_cmdline_user_args():
		await probe_mossvein("--perf-hub" in OS.get_cmdline_user_args())
		return
	if "--perf-review" in OS.get_cmdline_user_args():
		await review()
		return
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

## Diagnostic ablations run only in isolated QA, never in ordinary play.
func probe_mossvein(is_hub: bool = false) -> void:
	seed(4608)
	RunState.reset_run(false)
	RunState.world_seed = 4608
	main.game_started = true
	var entered: bool = main._dev_jump_hub() if is_hub else main._dev_jump_mine("mossMine", 2)
	if not entered:
		fail("Cannot enter diagnostic area"); return
	var world: Node2D = main.hub_world if is_hub else main.depth_world
	var player: Node2D = world.player
	player.camera.position_smoothing_enabled = false
	var origin: Vector2 = player.global_position
	var lights: Array[Node] = world.find_children("*", "PointLight2D", true, false)
	var shadow_state: Dictionary = {}
	for light in lights: shadow_state[light] = light.shadow_enabled
	var probe_rows: Array[Dictionary] = []
	for stage in ["cold_idle", "walk_1", "walk_2", "walk_3", "warm_idle", "no_shadows", "restored_shadows", "cached_world_draw", "half_resolution", "restored_resolution", "no_world_draw", "restored_draw"]:
		world.set_process(stage != "cached_world_draw")
		if stage != "cached_world_draw": world.queue_redraw()
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(Vector2i(422, 195) if stage == "half_resolution" else Vector2i(844, 390))
		var hide_draw: bool = stage == "no_world_draw"
		RenderingServer.canvas_item_set_visible(world.get_canvas_item(), not hide_draw)
		for light in lights:
			if not is_instance_valid(light): continue
			light.shadow_enabled = false if stage == "no_shadows" else shadow_state[light]
		player.set_external_movement(Vector2.ZERO)
		await main.get_tree().create_timer(0.3).timeout
		var intervals: Array[float] = []
		var draw_calls: Array[float] = []
		var begin: int = Time.get_ticks_usec()
		var previous: int = begin
		var distance: float = 0.0
		var last_position: Vector2 = player.global_position
		while Time.get_ticks_usec() - begin < 4000000:
			var elapsed: float = float(Time.get_ticks_usec() - begin) / 1000000.0
			if not String(stage).ends_with("idle"):
				# Follow a compact route around the actual entrance/stations.
				var target: Vector2 = origin + Vector2(sin(elapsed * TAU / 4.0) * 120.0, -100.0 + cos(elapsed * TAU / 4.0) * 90.0)
				player.set_external_movement(player.global_position.direction_to(target))
			await main.get_tree().process_frame
			var now: int = Time.get_ticks_usec()
			intervals.append(float(now - previous) / 1000.0)
			previous = now
			distance += last_position.distance_to(player.global_position)
			last_position = player.global_position
			draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var stats: Dictionary = _journey_performance_frame_stats(intervals)
		draw_calls.sort()
		stats.merge({"stage": stage, "walked_pixels": distance,
			"draw_calls_p95": _journey_percentile(draw_calls, 0.95),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"static_mib": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
			"video_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			"light_nodes": world.find_children("*", "PointLight2D", true, false).size(),
			"occluders": world.get_node("CaveLightOccluders").active_count if world.has_node("CaveLightOccluders") else 0})
		probe_rows.append(stats)
		print("MOSSVEIN_PROBE " + JSON.stringify(stats))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			main.get_viewport().get_texture().get_image().save_png(output_dir.path_join(String(stage) + ".png"))
	player.set_external_movement(Vector2.ZERO)
	FileAccess.open(output_dir.path_join("mossvein.json"), FileAccess.WRITE).store_string(JSON.stringify({"rendered": DisplayServer.get_name() != "headless", "physical_iphone": false, "area": "hub" if is_hub else "mossvein_depth_2", "stages": probe_rows}, "\t"))
	print("MOSSVEIN_PROBE_COMPLETE")
	main.get_tree().quit(0)

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

func review() -> void:
	if DisplayServer.get_name() == "headless": fail("Review requires rendering"); return
	main.game_started = true
	main._dev_jump_surface()
	driver = load("res://scripts/dev/visual_capture_driver.gd").new()
	main.add_child(driver)
	driver.set("_main", main)
	driver.call("_prepare_light_state", {"level": 1, "variant": "missing"})
	if not await settle_fixed_light_fixture(): return
	var preview: Node = main.commerce_panel.hero_well.get_node("LightPreview")
	preview.show_level(1)
	await capture_review("light-current")
	var before: int = hash(preview.viewport.get_texture().get_image().get_data())
	preview.show_level(2)
	await capture_review("light-upgraded")
	var after: int = hash(preview.viewport.get_texture().get_image().get_data())
	if before == after: fail("Light level selection did not repaint preview"); return
	preview.show_level(1)
	await capture_review("light-current-restored")
	if hash(preview.viewport.get_texture().get_image().get_data()) != before:
		fail("Returning to the same light level changed its pixels"); return
	for style in ["standard", "focused", "wide", "prismatic", "deepheart"]:
		driver.call("_prepare_light_state", {"level": 5, "style": style})
		await capture_review("light-style-" + style)
		preview = main.commerce_panel.hero_well.get_node("LightPreview")
		if preview.lamp.applied_style_id != style: fail("Wrong light style"); return
	main.commerce_panel.close_commerce()
	for fixture in ["forge_final_mixed_cost_ready", "wayfarer_baseline", "starforge_ready_crusher", "workshop_tool_forge_baseline", "workshop_wardrobe_baseline"]:
		driver.call("_prepare_commerce_capture", fixture)
		await capture_review(fixture)
		main.commerce_panel.close_commerce()
	main._dev_jump_surface()
	var meter: Dictionary = {}
	if main.developer_menu != null:
		main.developer_menu.open_menu()
		await capture_review("dev-fps-button")
		main.developer_menu.frame_meter_button.pressed.emit()
		await main.get_tree().create_timer(2.1).timeout
		meter = main.developer_menu.frame_meter.latest
		if meter.is_empty() or float(meter.fps) <= 0 or main.developer_menu.is_open():
			fail("DEV FPS meter did not measure frames after closing the drawer"); return
		await capture_review("dev-fps-meter")
		main.developer_menu.toggle_frame_meter()
		if main.developer_menu.frame_meter.visible or main.developer_menu.frame_meter.is_processing():
			fail("Disabled FPS meter keeps processing"); return
	FileAccess.open(output_dir.path_join("review.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "preview_repaints": true, "preview_restores_exact_pixels": true, "meter": meter, "version": ProjectSettings.get_setting("application/config/version")}, "\t"))
	print("EVER_DEEPER_MOBILE_REVIEW_COMPLETE")
	main.get_tree().quit(0)

func settle_fixed_light_fixture() -> bool:
	# Fixed-light baking adds a texture after frame_post_draw. The GLES3 light
	# atlas then repacks on the next draw, including this separate preview's
	# existing light textures. Capture both levels against the same settled
	# renderer state, without relaxing the exact-pixel restoration assertion.
	for frame in 120:
		var pending := false
		for field in main.get_tree().root.find_children("StaticLightField", "", true, false):
			pending = pending or field.baking or field._scheduled
		if not pending:
			await RenderingServer.frame_post_draw
			return true
		await main.get_tree().process_frame
	fail("Fixed-light fixture did not settle before preview review")
	return false

func capture_review(label: String) -> void:
	await main.get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	main.get_viewport().get_texture().get_image().save_png(output_dir.path_join(label + ".png"))
	if label.begins_with("light-"):
		var preview: Node = main.commerce_panel.hero_well.get_node("LightPreview")
		preview.viewport.get_texture().get_image().save_png(output_dir.path_join(label + "-viewport.png"))

func review_meter() -> void:
	if main.developer_menu == null: fail("DEV meter missing"); return
	main.game_started = true
	main._dev_seed_hub_state()
	RunState.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	main._dev_jump_hub()
	main.developer_menu.toggle_frame_meter()
	await main.get_tree().create_timer(35.0).timeout
	var meter: Control = main.developer_menu.frame_meter
	var reading: Dictionary = meter.latest
	if int(reading.get("meter_revision", 0)) != 2 or int(reading.get("canvas_width", 0)) <= 0:
		fail("Detailed meter did not collect valid dimensions"); return
	if not main.get_viewport().get_visible_rect().encloses(meter.get_global_rect()):
		fail("Meter extends beyond viewport"); return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(output_dir.path_join("meter-hub.png"))
	print("METER_READING " + JSON.stringify(reading))
	main.developer_menu.toggle_frame_meter()
	if meter.is_processing() or meter.visible: fail("Hidden meter still active"); return
	main._dev_jump_mine("mossMine", 2)
	main.developer_menu.toggle_frame_meter()
	if not meter.history.is_empty(): fail("Restart did not reset history"); return
	await main.get_tree().create_timer(2.2).timeout
	if meter.history.is_empty() or meter.history.size() > 60: fail("Invalid bounded history"); return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(output_dir.path_join("meter-mossvein.png"))
	print("METER_READING " + JSON.stringify(meter.latest))
	print("METER_REVIEW_OK")
	main.get_tree().quit(0)

## Final exported-package review of every affected floor profile.
func review_floor_release() -> void:
	if DisplayServer.get_name() == "headless": fail("Floor review requires rendering"); return
	main.game_started = true
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state(): fail("Mature hub fixture failed"); return
	for workshop_id in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop_id).next_upgrade
			RunState.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not bool(RunState.upgrade_workshop(workshop_id).get("ok", false)):
				fail("Mature hub upgrade failed"); return
	RunState.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	main._dev_jump_hub()
	for point in [Vector2(430,820), Vector2(1200,480), Vector2(720,200)]:
		main.hub_world.restore_position(point)
		await capture_review("floor-hub-%d-%d" % [point.x,point.y])
	for mine_id in main.MINE_IDS:
		if not main._dev_jump_mine(mine_id, 2): fail("Depth fixture failed"); return
		await capture_review("floor-" + String(mine_id) + "-entrance")
		main.depth_world.set_mine_held(true)
		await main.get_tree().create_timer(1.0).timeout
		main.depth_world.set_mine_held(false)
		await capture_review("floor-" + String(mine_id) + "-terrain")
	print("FLOOR_RELEASE_REVIEW_OK captures=11 version=0.46.9-dev.5")
	main.get_tree().quit(0)
