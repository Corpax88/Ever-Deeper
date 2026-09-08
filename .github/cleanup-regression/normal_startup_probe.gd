extends SceneTree
## External harness: deliberately uses ordinary startup, not either version's QA launcher.
var game: Node
var world: Node
var area := "hub"
var output := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--audit-area="): area = arg.get_slice("=", 1)
		if arg.begins_with("--audit-output="): output = arg.get_slice("=", 1)
	assert(area in ["hub", "mossvein"] and not output.is_empty())
	assert(DisplayServer.get_name() != "headless")
	root.size = Vector2i(844, 390)
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 3: await process_frame
	assert(not bool(game.get("automated_mode")))
	var launcher_present := false
	for property in game.get_property_list():
		if property.name == "qa_launcher": launcher_present = game.get("qa_launcher") != null
	assert(not launcher_present)
	var state: Node = root.get_node("RunState")
	seed(4608)
	state.reset_run(false)
	state.world_seed = 4608
	game._dev_seed_victory_state()
	assert(game._dev_build_all_workshops_state())
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = state.workshop_status(workshop).next_upgrade
			state.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			assert(bool(state.upgrade_workshop(workshop).get("ok", false)))
	var learned: Dictionary = {}
	for entry in load("res://scripts/companion/mole_skills.gd").SKILLS:
		learned[String(entry.id)] = 0 if String(entry.id) == "teamwork" else 1
	state.overhaul_progress["skills"] = learned
	assert(game._dev_jump_hub() if area == "hub" else game._dev_jump_mine("mossMine", 2))
	world = game.hub_world if area == "hub" else game.depth_world
	if area == "hub": world.restore_position(Vector2(1200, 480))
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	for frame in 3: await process_frame
	var mole: Node = world.get_node_or_null("MoleCompanion")
	assert(mole != null)
	mole._spawn_beside_hero()
	assert(bool(game.persistence_active) and not bool(game.menu_open))
	assert(root.size == Vector2i(844, 390))
	var started := Time.get_ticks_usec()
	var previous := started
	var bucket_start := started
	var samples: Array[float] = []
	var buckets: Array[Dictionary] = []
	var first := snapshot()
	while Time.get_ticks_usec() - started < 90000000:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now - previous) / 1000.0)
		previous = now
		if now - bucket_start >= 5000000:
			var row := snapshot()
			row["end_seconds"] = float(now - started) / 1000000.0
			row["frames"] = samples.size()
			row["fps"] = float(samples.size()) * 1000000.0 / float(now - bucket_start)
			samples.sort()
			row["p95_ms"] = samples[mini(samples.size() - 1, int(ceil(samples.size() * 0.95)) - 1)]
			row["max_ms"] = samples[-1]
			buckets.append(row)
			print("CLEANUP_BUCKET " + JSON.stringify(row))
			samples.clear()
			bucket_start = now
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output + ".png")
	var report := {"area": area, "physical_iphone": false, "renderer": RenderingServer.get_video_adapter_name(),
		"duration_seconds": float(Time.get_ticks_usec() - started) / 1000000.0,
		"automated_mode": game.automated_mode, "qa_launcher_present": launcher_present,
		"persistence_active": game.persistence_active, "skills": learned,
		"teamwork_note": "Disabled identically: its pre-existing hub bool(null) error is present in both sources. The production fix is later DEV4.",
		"initial": first, "final": snapshot(), "buckets": buckets}
	FileAccess.open(output + ".json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("CLEANUP_NORMAL_STARTUP_COMPLETE")
	quit(0)

func snapshot() -> Dictionary:
	return {"cpu_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"window": [root.size.x, root.size.y], "phase": game.phase}
