extends "check_integration.gd"
## A measured-state regression, not ordinary-input or rendered acceptance.
const RECORD_SHA := "6464b65860bb53e622f061a633a2e154cb5f0b0d90893f28d06b1c69d41baa02"
var checks: Array[Dictionary] = []
var failures: Array[String] = []


func _check(ok: bool, label: String) -> void:
	checks.append({"label": label, "passed": ok})
	if not ok: failures.append(label)


func _xy(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


func _escape_corridor(a: Vector2, b: Vector2) -> bool:
	return minf(a.x, b.x) >= 0.0 and maxf(a.x, b.x) <= 65.0 and maxf(absf(a.y), absf(b.y)) <= 0.5


func _run() -> void:
	var recorded := ""
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--recorded="): recorded = arg.trim_prefix("--recorded=")
		elif arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if FileAccess.get_sha256(recorded) != RECORD_SHA:
		push_error("Requires the closed rejected right-candidate record")
		quit(6)
		return
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(recorded))
	await super._run()
	if current_scene == null: return
	var main: Node = current_scene
	var state: Node = root.get_node("RunState")
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_endless(1)
	await process_frame
	var world: Node = main.endless_world
	var hero: Node2D = world.player
	var mole: Node = world.get_node("MoleCompanion")
	world.set_process(false)
	world.set_physics_process(false)
	hero.set_physics_process(false)
	mole.set_physics_process(false)
	state.overhaul_progress = {"skills": {}}
	main._on_joystick_movement(Vector2.ZERO)
	main._set_mine_held(false)
	hero.control_enabled = true
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(PackedByteArray(world.floor_cells))
	_check(digest.finish().hex_encode() == record.samples[129].world_damage.floor_sha256,
		"Real seed/depth terrain exactly matches the rejected capture")
	var initial: Dictionary = record.samples[129]
	mole.global_position = _xy(initial.companion.position)
	mole.facing = _xy(initial.companion.facing)
	mole.mode = "follow"
	mole.route.clear()
	mole.separation.reset()
	mole.separation.avoidance_active = bool(initial.companion.separation.avoidance_active)
	mole.separation.yield_axis = _xy(initial.companion.separation.yield_axis)
	var trace: Array[Dictionary] = []
	var dt := 1.0 / 60.0
	var inward_steps := 0
	var minimum_gap := INF
	for frame in range(130, 139):
		var sample: Dictionary = record.samples[frame]
		hero.global_position = _xy(sample.position)
		mole.hero_before_step = _xy(record.samples[frame - 1].position)
		mole.observed_velocity = _xy(sample.companion.separation.observed_hero_velocity)
		var before: Vector2 = mole.global_position
		mole.moving = false
		mole._move(dt)
		var step: Vector2 = mole.global_position - before
		var gap: float = mole.separation.segment_distance(before - mole.hero_before_step, mole.global_position - hero.global_position)
		minimum_gap = minf(minimum_gap, gap)
		if frame <= 136 and step.y > 0.001: inward_steps += 1
		_check(step.length() <= 580.0 * dt + 0.001 and mole._segment_clear(before, mole.global_position),
			"Recorded frame %s keeps one terrain-valid movement budget" % frame)
		_check(hero.global_position.is_equal_approx(_xy(sample.position)), "Recorded frame %s leaves hero position untouched" % frame)
		if frame == 135:
			_check(step.is_zero_approx() and mole.separation.choice == "wait", "Frame 135 holds safely instead of reversing inward")
		trace.append({"frame": frame, "position": [mole.global_position.x, mole.global_position.y],
			"step": [step.x, step.y], "choice": mole.separation.choice, "swept_gap": gap,
			"hero": [hero.global_position.x, hero.global_position.y]})
	_check(inward_steps == 0, "Approaching 130–136 trace has no inward step between retreats")
	_check(minimum_gap >= 50.0 - 0.001, "Recorded sequence retains swept exclusion distance")
	# Holding here is unsafe because the hero is approaching in a narrow corridor.
	# A normal 280px/s preferred step remains safe; faster retreat hits its end.
	var steering: RefCounted = mole.separation.get_script().new()
	steering.avoidance_active = true
	var origin := Vector2(60, 0)
	var preferred := Vector2(280.0 * dt, 0)
	_check(not steering._safe(origin, Vector2(-340.0 * dt, 0), Vector2.ZERO, Vector2(340, 0), Vector2.ZERO, dt, _escape_corridor),
		"Counterexample genuinely makes a stationary hold unsafe")
	var escape: Vector2 = steering.choose(origin, Vector2(-340.0 * dt, 0), Vector2.ZERO, Vector2(340, 0), preferred, 280.0, dt, _escape_corridor)
	_check(escape.is_equal_approx(preferred) and steering.choice == "route_fallback" and not steering.trapped,
		"Unsafe hold retains the safe preferred escape")
	var report := {"schema": 1, "kind": "recorded_state_real_terrain_regression", "passed": failures.is_empty(),
		"checks": checks, "failures": failures, "record_sha256": RECORD_SHA, "pack_sha256": PACK_SHA,
		"trace": trace, "minimum_swept_gap": minimum_gap, "unsafe_hold_escape": [escape.x, escape.y],
		"limits": ["Recorded hero/companion state is explicitly injected into the actual seeded world; this is not ordinary-input replay or a rendered visual verdict.",
			"Nine follow calls isolate the rejected 135 steering reversal. Separate unchanged autonomy/lifecycle and fresh rendered A/B gates remain required."]}
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("COMPANION_RECORDED_WALL ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
