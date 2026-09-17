extends "check_integration.gd"
## Actual packaged companion lifecycle; no rendered-motion claim.
var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _check(ok: bool, label: String) -> void:
	checks.append({"label": label, "passed": ok})
	if not ok: failures.append(label)

func _run() -> void:
	await super._run()
	if current_scene == null: return
	var main: Node = current_scene
	var state: Node = root.get_node("RunState")
	state.reset_run(false)
	state.world_seed = 4608
	main._dev_jump_endless(1)
	await process_frame
	var world: Node = main.endless_world
	var hero: Node2D = world.player
	var mole: Node = world.get_node("MoleCompanion")
	world.set_process(false)
	hero.set_physics_process(false)
	mole.set_physics_process(false)
	state.overhaul_progress = {"skills": {}}
	main._on_joystick_movement(Vector2.ZERO)
	main._set_mine_held(false)
	hero.control_enabled = true
	mole._spawn_beside_hero()
	mole.was_active = true
	var dt := 1.0 / 60.0
	mole._physics_process(dt)
	_check(mole.observed_velocity.is_zero_approx(), "Spawn starts without fictitious hero velocity")
	_check(mole.hero_before_step.is_equal_approx(hero.global_position), "Spawn uses actual current hero origin")
	var original_hero: Vector2 = hero.global_position
	var before_pause: Vector2 = mole.global_position
	hero.control_enabled = false
	mole._physics_process(dt)
	# Explicit fixture teleport while controls are disabled tests stale-history
	# rejection. It is not a natural movement or collision assertion.
	hero.global_position += Vector2(12, 0)
	mole._physics_process(dt)
	_check(Vector2(mole.global_position).is_equal_approx(before_pause), "Disabled controls prevent follow and yield movement")
	hero.control_enabled = true
	mole._physics_process(dt)
	_check(mole.observed_velocity.is_zero_approx(), "Resume discards movement during the paused interval")
	hero.global_position = original_hero
	mole._spawn_beside_hero()
	mole._physics_process(dt)
	var remembered: Vector2 = mole.observed_hero
	var before_record: Vector2 = mole.hero_before_step
	var mole_before: Vector2 = mole.global_position
	var offset := Vector2(0, -512)
	mole.rebase_world(offset)
	hero.global_position += offset
	_check(Vector2(mole.observed_hero).is_equal_approx(remembered + offset), "Rebase translates prior observed hero with the actual owner")
	_check(Vector2(mole.hero_before_step).is_equal_approx(before_record + offset), "Rebase translates relative-sweep start")
	_check(Vector2(mole.global_position).is_equal_approx(mole_before + offset), "Base companion rebase is still applied exactly once")
	# Restore both explicit fixture translations before another movement call.
	mole.rebase_world(-offset)
	hero.global_position -= offset
	mole._physics_process(dt)
	_check(mole.observed_velocity.is_zero_approx(), "Rebased history does not manufacture a velocity on the next tick")
	var one_step_before: Vector2 = mole.global_position
	mole.recall()
	mole._physics_process(dt)
	_check(Vector2(mole.global_position).distance_to(one_step_before) <= 580.0 * dt + 0.001, "Recall uses at most one follow movement budget")
	_check(mole.z_index == world.actor_draw_depth(mole.position), "Follow depth is derived from the final actual foot position")
	_check(Vector2(hero.global_position).is_equal_approx(original_hero), "Companion never changes the player's position")
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var report := {"schema": 1, "kind": "packaged_companion_lifecycle", "passed": failures.is_empty(), "checks": checks,
		"failures": failures, "pack_sha256": PACK_SHA, "limits": ["Headless actual packaged owner, with explicit fixture teleport/rebase; no natural travel or visual acceptance."]}
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("COMPANION_LIFECYCLE ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)
