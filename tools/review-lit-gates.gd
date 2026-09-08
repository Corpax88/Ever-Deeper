extends SceneTree
## External native harness: inspect the already built PCK, without repacking it.
var output_dir := ""

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("LIT_GATE_REVIEW_FAIL " + message)
		quit(2)
	return ok

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=", 1)
	if not check(not output_dir.is_empty() and OS.has_feature("ever_deeper_dev") and DisplayServer.get_name() != "headless", "Rendered DEV pack and output required"): return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-gates-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	state.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	var reviewer: RefCounted = load("res://scripts/qa/suites/lighting_release_review.gd").new(main, output_dir)
	reviewer.area = "gates"
	var report: Array[Dictionary] = []
	for mine_id in ["mossMine", "moonMine", "emberMine"]:
		if not check(main._dev_jump_mine(mine_id, 2), "Enter " + mine_id): return
		var world: Node2D = main.depth_world
		reviewer.world = world
		var gates: Array = world.get_drill_gates()
		if not check(not gates.is_empty(), "Authored gate"): return
		var gate: Dictionary = gates[0]
		var center := Vector2.ZERO
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		for value in gate.positions:
			var point: Vector2 = value
			center += point
			low = low.min(point)
			high = high.max(point)
		center /= float(gate.positions.size())
		# A reached-gate fixture: clear approach terrain, retain every gate segment.
		world._clear_circle(center, 500.0)
		for cavern in world.caverns:
			if not cavern.discovered and not cavern.boundary.is_empty():
				world._discover_cavern_from_cell(int(cavern.boundary[0]))
		var across: Vector2 = Vector2.RIGHT if high.y - low.y > high.x - low.x else Vector2.DOWN
		world.restore_position(center + across * 180.0)
		world.player.camera.position_smoothing_enabled = false
		world.player.camera.reset_smoothing()
		world.queue_redraw()
		for frame in 5: await process_frame
		if not check(world.player.global_position.distance_to(center) < 300.0, "Player reached gate instead of falling back to entrance"): return
		var screen: Vector2 = world.get_global_transform_with_canvas() * center
		if not check(world.get_viewport_rect().grow(-80).has_point(screen), "Gate centered inside visible framebuffer"): return
		var rock_index := -1
		for index in world.rocks.size():
			var rock: Dictionary = world.rocks[index]
			if String(rock.deposit_id) == String(gate.id) and not rock.broken and world._drill_gate_segment_visible(rock):
				rock_index = index
				break
		if not check(rock_index >= 0, "Actual unbroken gate segment is visible"): return
		await reviewer.paired(mine_id + "-visible-gate", "wide", -across)
		if reviewer.failed: return
		var key: String = mine_id + ":d2:" + String(gate.id)
		var before: int = state.barrier_hits(key)
		world.current_target_kind = "rock"
		world.current_target_rock = rock_index
		if not check(world.mine_once() and int(state.barrier_hits(key)) > before, "Mining advances actual gate progress"): return
		await reviewer.paired(mine_id + "-struck-gate", "focused", -across)
		if reviewer.failed: return
		report.append({"mine":mine_id,"gate":gate.id,"screen_center":str(screen),"player_distance":world.player.global_position.distance_to(center),"visible":true,"hits":state.barrier_hits(key)})
	FileAccess.open(output_dir.path_join("gate-review.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed":true,"package_version":"0.46.9-dev.7","cases":report,"paired":reviewer.cases}, "\t"))
	print("LIT_GATE_REVIEW_OK " + JSON.stringify(report))
	quit(0)
