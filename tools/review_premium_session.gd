extends SceneTree
## Real-time sustained gameplay. Movie/fixed-step recordings are not FPS tests.
var output: String
var area: String = "deep"
var seconds: float = 180.0
var main: Node
var world: Node
var state: Node
var windows: Array[Dictionary] = []
var require_fps: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--area="): area = arg.trim_prefix("--area=")
		elif arg.begins_with("--seconds="): seconds = maxf(30.0, float(arg.trim_prefix("--seconds=")))
		elif arg == "--require-fps": require_fps = true
	if output.is_empty() or area not in ["hub", "ember", "deep"] or DisplayServer.get_name() == "headless":
		push_error("Sustained session requires a renderer, output and hub/ember/deep area")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	var entered: bool = false
	match area:
		"hub":
			main._dev_seed_victory_state()
			entered = main._dev_build_all_workshops_state() and main._dev_jump_hub()
		"ember": entered = main._dev_jump_mine("emberMine", 2)
		"deep": entered = main._dev_jump_endless(12)
	if not entered:
		push_error("Cannot enter sustained session area")
		quit(3)
		return
	world = main.hub_world if area == "hub" else main.depth_world if area == "ember" else main.endless_world
	if area == "hub":
		for id in state.ENDLESS_WORKSHOP_IDS:
			state.endless_workshops[id] = {"built": true, "level": 5}
			state.endless_relics[state._relic_id_for_workshop(id)]["placed"] = true
		state._state_changed()
	main.persistence_active = true
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	var player: Node = world.player
	var start: Vector2 = player.global_position
	var distance: float = 0.0
	var mined_before: int = state.total_mined_resources()
	await create_timer(4.0).timeout
	var started: int = Time.get_ticks_usec()
	var window_start: int = started
	var previous: int = started
	var frames: Array[float] = []
	var cpu: Array[float] = []
	var draws: Array[float] = []
	var prior_position: Vector2 = player.global_position
	while float(Time.get_ticks_usec() - started) / 1000000.0 < seconds:
		var elapsed: float = float(Time.get_ticks_usec() - started) / 1000000.0
		if area == "hub":
			var target: Vector2 = start + Vector2(sin(elapsed * 0.3) * 240.0, cos(elapsed * 0.3) * 100.0 - 130.0)
			world.player.set_external_movement(player.global_position.direction_to(target))
		else:
			world.set_mine_held(true)
			var direction: Vector2 = Vector2.DOWN if area == "deep" else [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP][int(elapsed / 25.0) % 4]
			world.player.set_external_movement(direction)
		await process_frame
		var now: int = Time.get_ticks_usec()
		frames.append(float(now - previous) / 1000.0)
		cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var moved: float = prior_position.distance_to(player.global_position)
		if moved < 100.0: distance += moved
		prior_position = player.global_position
		previous = now
		if now - window_start >= 30000000:
			_record_window(frames, cpu, draws, elapsed, distance)
			frames.clear()
			cpu.clear()
			draws.clear()
			window_start = now
	if not frames.is_empty(): _record_window(frames, cpu, draws, seconds, distance)
	player.set_external_movement(Vector2.ZERO)
	if area != "hub": world.set_mine_held(false)
	state.flush_save()
	await create_timer(4.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("final.png"))
	var meets: bool = not windows.is_empty()
	for window in windows:
		meets = meets and float(window.average_fps) >= 50.0 and float(window.p95_ms) <= 20.0
	var mined: int = state.total_mined_resources() - mined_before
	var functional: bool = distance > 100.0 and (area == "hub" or mined > 0)
	var report: Dictionary = {
		"seed": state.world_seed, "area": area, "seconds": seconds, "windows": windows, "distance": distance, "mined_resources": mined,
		"built_hub_visible": bool(state.victory) and area == "hub",
		"functional": functional, "meets_50_fps": meets, "rendered": true, "physical_iphone": false,
		"display": DisplayServer.get_name(), "renderer": RenderingServer.get_video_adapter_name(),
		"rendering_method": RenderingServer.get_current_rendering_method(), "os": OS.get_name(),
		"window_pixels": [root.size.x, root.size.y], "persistence_enabled": state.persistence_enabled(),
		"save_bytes": FileAccess.get_file_as_bytes(state.persistence_path()).size(),
		"end_nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"end_orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"limit": "Real-time native workload; physical iPhone heat/battery/Safari acceptance remains separate."
	}
	FileAccess.open(output.path_join("session.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("PREMIUM_SESSION_COMPLETE area=", area, " functional=", functional, " meets_50_fps=", meets)
	quit(0 if functional and (not require_fps or meets) else 4)

func _record_window(frames: Array[float], cpu: Array[float], draws: Array[float], elapsed: float, distance: float) -> void:
	var total: float = 0.0
	for value in frames: total += value
	frames.sort()
	cpu.sort()
	draws.sort()
	var row: Dictionary = {
		"elapsed": elapsed, "frames": frames.size(), "average_fps": 1000.0 * frames.size() / maxf(total, 0.001),
		"p95_ms": frames[mini(frames.size() - 1, floori(frames.size() * 0.95))],
		"p99_ms": frames[mini(frames.size() - 1, floori(frames.size() * 0.99))],
		"cpu_p95_ms": cpu[mini(cpu.size() - 1, floori(cpu.size() * 0.95))],
		"draws_p95": draws[mini(draws.size() - 1, floori(draws.size() * 0.95))],
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"static_mib": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, "distance": distance,
	}
	windows.append(row)
	FileAccess.open(output.path_join("windows.json"), FileAccess.WRITE).store_string(JSON.stringify(windows, "\t"))
	print("PREMIUM_SESSION_WINDOW " + JSON.stringify(row))
