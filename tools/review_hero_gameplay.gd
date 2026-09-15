extends SceneTree
## Real input/physics motion through unchanged generated The Deep terrain.
## Use --write-movie for a deterministic native film; this is not an FPS test.
const Gear = preload("res://scripts/player/hero_gear.gd")
var output := ""
var pack_source := ""
var selected_gear := "worn"
var main: Node
var world: Node
var player: Node
var stage := "prepare"
var recording := false
var elapsed := 0.0
var samples: Array[Dictionary] = []
var stages: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error("HERO_GAMEPLAY_FAIL " + message)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		elif arg.begins_with("--gear="): selected_gear = arg.trim_prefix("--gear=")
	if not output.is_absolute_path() or selected_gear not in ["worn", "crusher", "deepcore"]:
		push_error("Require absolute --output and --gear=worn|crusher|deepcore")
		quit(2)
		return
	var packed := FileAccess.file_exists("res://project.binary")
	if packed and (not pack_source.is_absolute_path() or not FileAccess.file_exists(pack_source)):
		push_error("Exported capture requires --pack-source")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1696, 780)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(1):
		_check(false, "Enter generated The Deep")
		_finish(packed)
		return
	world = main.endless_world
	player = world.player
	state.pickaxe_level = 1
	state.drill_level = 3 if selected_gear == "deepcore" else 0
	state.starforge_variant = "crusher" if selected_gear == "crusher" else ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.endless_workshops["tool_forge"] = {"built": false, "level": 0}
	player.movement_speed = 340.0
	player.prepare_visual_cache()
	var deadline := Time.get_ticks_msec() + 20000
	while player.visual.active_gear != selected_gear and Time.get_ticks_msec() < deadline:
		player.visual._poll_equipment()
		await process_frame
	_check(player.visual.active_gear == selected_gear, "Selected production atlas is loaded")
	var route := _find_route()
	_check(not route.is_empty(), "Original terrain supplies an unobstructed approach to a diggable wall")
	if route.is_empty():
		_finish(packed)
		return
	var direction: Vector2 = route.direction
	var wall: Vector2i = route.wall
	world.restore_position(route.start)
	player.control_enabled = true
	player.set_facing(direction)
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	main._refresh_hud()
	process_frame.connect(_sample)
	recording = true
	await _stage("idle", 0.5)
	var started: Vector2 = player.global_position
	main._set_mine_held(true)
	main._on_joystick_movement(direction)
	await _stage("full_speed_with_mine_held", 0.45)
	_check(player.global_position.distance_to(started) > 140.0, "Held mining does not delay full-speed movement")
	_check(player.is_actually_moving() and not world.mining_active, "Moving body owns locomotion instead of sliding in a mining pose")
	await _stage("push_into_wall_and_mine", 1.6)
	_check(not player.is_actually_moving() and world.mining_active, "Blocked joystick continues physical mining")
	_check(int(world.dig_damage.get(wall, 0)) > 0, "Standing contact damages the original wall")
	main._on_joystick_movement(Vector2.ZERO)
	await _stage("stationary_contact_and_recovery", 0.9)
	main._set_mine_held(false)
	await _stage("release_to_idle", 0.3)
	var damage_before: int = int(world.dig_damage.get(wall, 0))
	main._set_mine_held(true)
	await _stage("anticipation", world._mining_cycle_duration() * world.MINING_HIT_PROGRESS * 0.45)
	main._set_mine_held(false)
	await _stage("released_anticipation", 0.3)
	_check(int(world.dig_damage.get(wall, 0)) == damage_before, "Released anticipation never applies damage")
	main._set_mine_held(true)
	await _stage("second_anticipation", world._mining_cycle_duration() * world.MINING_HIT_PROGRESS * 0.45)
	started = player.global_position
	main._on_joystick_movement(-direction)
	await _stage("mine_to_full_speed_walk", 0.5)
	_check(player.global_position.distance_to(started) > 150.0, "Mining-to-walk keeps immediate full movement speed")
	_check(not world.mining_active and player.is_actually_moving(), "Movement interrupts the actual mining cycle")
	main._on_joystick_movement(Vector2.ZERO)
	main._set_mine_held(false)
	await _stage("walk_stop_and_idle", 0.6)
	recording = false
	_finish(packed)

func _find_route() -> Dictionary:
	for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]:
		for y in range(3, 19):
			for x in range(3, 37):
				var wall := Vector2i(x, y)
				if world._is_floor(wall) or not world._cell_diggable(wall): continue
				var open := true
				for step in range(1, 5):
					var cell: Vector2i = wall - direction * step
					if not world._is_floor(cell) or world.collision_at(world._cell_center(cell)):
						open = false
						break
				if not open: continue
				player.global_position = world._cell_center(wall - direction)
				player.set_facing(Vector2(direction))
				if world._nearest_diggable_wall() != wall or world._nearest_resource_index() >= 0: continue
				return {"wall": wall, "direction": Vector2(direction), "start": world._cell_center(wall - direction * 4)}
	return {}

func _stage(name: String, duration: float) -> void:
	stage = name
	stages.append({"name": name, "start_seconds": elapsed, "duration": duration})
	print("HERO_GAMEPLAY_STAGE ", name)
	await create_timer(duration).timeout

func _sample() -> void:
	if not recording: return
	elapsed += root.get_process_delta_time()
	var pose: Dictionary = player.visual.tool_visual_snapshot()
	samples.append({"time": elapsed, "stage": stage, "position": [player.global_position.x, player.global_position.y],
		"moving": player.is_actually_moving(), "mining": world.mining_active, "progress": player.mining_visual_progress,
		"pose": pose.state, "frame": pose.local_frame, "gear": pose.gear})

func _finish(packed: bool) -> void:
	var report := {"passed": failures.is_empty(), "failures": failures, "gear": selected_gear, "stages": stages, "samples": samples,
		"packed": packed, "pack_sha256": FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else "",
		"rendered": DisplayServer.get_name() != "headless", "physical_iphone": false, "actual_viewport": [root.size.x, root.size.y],
		"manual_process_steps": false, "terrain_replaced": false, "fixed_movement_speed": 340,
		"limits": "Movie mode verifies native artwork and real input/physics timing; it does not measure frame rate."}
	FileAccess.open(output.path_join("hero-gameplay.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("HERO_GAMEPLAY_COMPLETE failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
