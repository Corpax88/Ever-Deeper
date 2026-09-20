extends SceneTree
## Headless contract check in the real world: coalesced restart/rollover/impact.
## This is not a rendered-animation acceptance test.
var output: String = ""
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition: failures.append(label)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_absolute_path():
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(1):
		quit(3)
		return
	var world: Node = main.endless_world
	var player: Node = world.player
	main.set_process(false)
	world.set_process(false)
	world.set_physics_process(false)
	player.set_physics_process(false)
	player.visual.set_process(false)
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	world.restore_position(Vector2(1688,1648))
	player.set_external_movement(Vector2.ZERO)
	player._actual_moving = false
	player.set_facing(Vector2.UP)
	world._cancel_mining()
	world.external_mine_held = true
	world._update_mining(0.0)
	var first: Dictionary = player.animation_packet()
	_check(bool(first.mining_timing_valid), "Initial committed clock available")
	_check(float(first.progress) == 0.0, "Initial clock starts at zero")
	_check(not bool(first.swing_continuation), "Initial swing is not continuation")
	_check(Vector2(first.bearing).is_equal_approx((Vector2(first.target_position)-player.global_position).normalized()), "Exact target bearing")
	_check(not Vector2(first.bearing).is_equal_approx(player.facing_vector), "Fixture distinguishes continuous and cardinal bearing")
	var old_index: int = int(world._swing_resource_index)
	if old_index < 0:
		failures.append("Fixture requires a resource")
		_finish()
		return
	world.resources[old_index].hp = 500
	var hp_before: int = int(world.resources[old_index].hp)
	var duration: float = float(first.cycle_duration)
	world._update_mining(duration + .013)
	var rolled: Dictionary = player.animation_packet()
	_check(int(rolled.swing_serial) == int(first.swing_serial)+1, "Rollover assigns a new swing")
	_check(bool(rolled.swing_continuation), "Held same-target rollover is continuation")
	_check(is_equal_approx(float(rolled.progress), .013/duration), "Rollover carries new overflow, never old progress one")
	_check(int(rolled.impact_serial) == int(first.impact_serial)+1, "Slow update earns exactly one impact")
	_check(int(rolled.impact_swing_serial) == int(first.swing_serial), "Earned impact belongs to old swing")
	_check(Vector2(rolled.impact_target_position).is_equal_approx(first.target_position), "Earned impact retains old target")
	_check(Vector2(rolled.impact_bearing).is_equal_approx(first.bearing), "Earned impact retains old bearing")
	_check(int(world.resources[old_index].hp) < hp_before, "Real world damage occurred")
	world._cancel_mining()
	world._update_mining(0.0)
	var restarted: Dictionary = player.animation_packet()
	_check(int(restarted.swing_serial) == int(rolled.swing_serial)+1, "Same-draw cancel/restart remains identifiable")
	_check(not bool(restarted.swing_continuation), "Cancel/restart is never held continuation")
	_check(bool(restarted.mining) and float(restarted.progress) == 0.0, "Restart packet is coherent")
	_check(int(restarted.impact_serial) == int(rolled.impact_serial), "Restart invents no impact")
	world._cancel_mining()
	player.set_external_movement(Vector2.DOWN)
	player.control_enabled = true
	var before: Dictionary = player.animation_packet()
	var measured_distance: float = 0.0
	for tick in 2:
		var position_before: Vector2 = player.global_position
		player._physics_process(1.0/60.0)
		measured_distance += position_before.distance_to(player.global_position)
	var walked: Dictionary = player.animation_packet()
	_check(measured_distance > 0.0, "Fixture has actual resolved movement")
	_check(int(walked.physics_tick) == int(before.physics_tick)+2, "Physics sampling identity")
	_check(is_equal_approx(float(walked.travelled_distance)-float(before.travelled_distance), measured_distance), "Cumulative path includes both physics steps")
	_check(player.animation_packet().travelled_distance == walked.travelled_distance, "Repeated render reads do not consume distance")
	player.set_mining_visual(true,.25)
	var fallback: Dictionary = player.animation_packet()
	_check(not bool(fallback.mining_timing_valid), "Unadapted world clock is explicitly unavailable")
	_finish()

func _finish() -> void:
	var sources: Dictionary = {}
	for path in ["scripts/player/player_controller.gd", "scripts/world/endless_descent_world.gd", "tools/hero_flow_graph/verify_presentation_packet.gd"]:
		sources[path] = FileAccess.get_sha256("res://"+path)
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": failures.is_empty(), "checks": checks, "failures": failures,
		"source_sha256": sources, "rendered_acceptance": false}, "\t"))
	if failures.is_empty(): print("PRESENTATION_PACKET_COMPLETE checks=", checks)
	else: push_error("Presentation packet failures: " + str(failures))
	quit(0 if failures.is_empty() else 3)
