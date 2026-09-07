extends "res://scripts/qa/suites/mobile_performance.gd"
## Native rendered control, not an iPhone emulator. No ordinary-play changes.
const FULL_SIZE := Vector2i(2328, 1260)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-output="): output_dir = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(output_dir)
	if DisplayServer.get_name() == "headless":
		fail("Sustained hub requires actual rendering"); return
	seed(4608)
	RunState.reset_run(false)
	RunState.world_seed = 4608
	# Exercise normal checkpoint/autosave paths against a disposable QA file.
	RunState.initialize_persistence(output_dir.path_join("isolated-save.json"))
	main.persistence_active = true
	main.game_started = true
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state():
		fail("Could not build mature hub"); return
	for workshop_id in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop_id).next_upgrade
			RunState.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not bool(RunState.upgrade_workshop(workshop_id).get("ok", false)):
				fail("Workshop fixture upgrade failed"); return
	if not main._dev_jump_hub():
		fail("Could not enter mature hub"); return
	main.hub_world.restore_position(Vector2(1200, 480))
	var player: Node2D = main.hub_world.player
	player.set_external_movement(Vector2.ZERO)
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()
	var window: Window = main.get_window()
	window.min_size = Vector2i.ZERO
	if "--perf-effects" in OS.get_cmdline_user_args():
		await probe_effects()
		return
	var dimensions: Dictionary = {}
	for stage in ["full", "half", "restored"]:
		var expected: Vector2i = FULL_SIZE / 2 if stage == "half" else FULL_SIZE
		window.size = expected
		await main.get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = window.get_texture().get_image()
		if shot.get_size() != expected:
			fail("Invalid resolution comparison: expected %s, got %s" % [expected, shot.get_size()]); return
		dimensions[stage] = {"width": shot.get_width(), "height": shot.get_height()}
		shot.save_png(output_dir.path_join(stage + ".png"))
		# Six consecutive ten-second baseline buckets cover the phone's delayed drop.
		for bucket in (6 if stage == "full" else 2):
			var intervals: Array[float] = []
			var begin: int = Time.get_ticks_usec()
			var previous: int = begin
			while Time.get_ticks_usec() - begin < 10000000:
				await main.get_tree().process_frame
				var now: int = Time.get_ticks_usec()
				intervals.append(float(now - previous) / 1000.0)
				previous = now
			var stats: Dictionary = _journey_performance_frame_stats(intervals)
			stats.merge({"stage": stage, "bucket": bucket,
				"width": expected.x, "height": expected.y,
				"cpu_monitor_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
				"physics_monitor_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
				"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
				"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
				"video_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
				"static_mib": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0})
			rows.append(stats)
			print("SUSTAINED_HUB_ROW " + JSON.stringify(stats))
	var report: Dictionary = {"physical_iphone": false, "renderer": RenderingServer.get_video_adapter_name(),
		"fixture": "all relics and workshops, light lab 4, wardrobe 4; not the user's exact save",
		"persistence_enabled": RunState.persistence_enabled(), "audio_driver": AudioServer.get_driver_name(),
		"dimensions": dimensions, "stages": rows}
	FileAccess.open(output_dir.path_join("results.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("SUSTAINED_HUB_COMPLETE")
	main.get_tree().quit(0)

func probe_effects() -> void:
	var world: Node2D = main.hub_world
	var window: Window = main.get_window()
	window.size = FULL_SIZE
	for frame in 4: await main.get_tree().process_frame
	var lights: Array[Node] = world.find_children("*", "PointLight2D", true, false)
	var original: Dictionary = {}
	var inventory: Array[Dictionary] = []
	for light in lights:
		original[light] = {"enabled": light.enabled, "shadow": light.shadow_enabled}
		inventory.append({"path": str(world.get_path_to(light)), "enabled": light.enabled,
			"shadow": light.shadow_enabled, "scale": str(light.texture_scale)})
	var original_mask: int = world.light_mask
	var interventions: Array[String] = ["no_shadows", "no_station_lights", "no_hero_lights", "no_companion_lights", "no_lights", "world_light_mask_zero"]
	var stages: Array[String] = ["baseline"]
	for intervention in interventions:
		stages.append(intervention)
		stages.append("restored_" + intervention)
	for stage in stages:
		world.light_mask = 0 if stage == "world_light_mask_zero" else original_mask
		var changed: int = 0
		for light in lights:
			if not is_instance_valid(light):
				fail("Light graph changed during controlled probe"); return
			light.enabled = original[light].enabled
			light.shadow_enabled = original[light].shadow
			var is_station: bool = world.world_lights.is_ancestor_of(light)
			var is_hero: bool = world.player.is_ancestor_of(light)
			var disable: bool = stage == "no_lights" or (stage == "no_station_lights" and is_station) or (stage == "no_hero_lights" and is_hero) or (stage == "no_companion_lights" and not is_station and not is_hero)
			if disable and light.enabled:
				light.enabled = false
				changed += 1
			if stage == "no_shadows" and light.shadow_enabled:
				light.shadow_enabled = false
				changed += 1
		if stage in interventions and stage != "world_light_mask_zero" and changed == 0:
			fail("No matching effect for " + stage); return
		for frame in 2: await main.get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = window.get_texture().get_image()
		if shot.get_size() != FULL_SIZE:
			fail("Effect comparison changed pixel dimensions"); return
		shot.save_png(output_dir.path_join(stage + ".png"))
		var intervals: Array[float] = []
		var begin: int = Time.get_ticks_usec()
		var previous: int = begin
		while Time.get_ticks_usec() - begin < 10000000:
			await main.get_tree().process_frame
			var now: int = Time.get_ticks_usec()
			intervals.append(float(now - previous) / 1000.0)
			previous = now
		var enabled: int = 0
		var shadowed: int = 0
		for light in lights:
			if not is_instance_valid(light):
				fail("Light was replaced during measurement"); return
			if light.enabled: enabled += 1
			if light.enabled and light.shadow_enabled: shadowed += 1
		var stats: Dictionary = _journey_performance_frame_stats(intervals)
		stats.merge({"stage": stage, "changed_lights": changed, "enabled_lights": enabled,
			"shadowed_lights": shadowed, "world_light_mask": world.light_mask,
			"width": FULL_SIZE.x, "height": FULL_SIZE.y,
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT)})
		rows.append(stats)
		print("SUSTAINED_HUB_ROW " + JSON.stringify(stats))
	var report: Dictionary = {"physical_iphone": false, "renderer": RenderingServer.get_video_adapter_name(),
		"lights": inventory, "stages": rows, "persistence_enabled": RunState.persistence_enabled(),
		"audio_driver": AudioServer.get_driver_name(), "test": "one lighting intervention at a time, restored after each"}
	FileAccess.open(output_dir.path_join("effects.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("SUSTAINED_HUB_COMPLETE")
	main.get_tree().quit(0)
