extends SceneTree
const Steering = preload("follow_separation.gd")
var failures: Array[String] = []
var checks := 0
var cases: Array[Dictionary] = []
var terrain := "open"


func _initialize() -> void:
	for hz in [30, 60, 120]:
		for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP, Vector2(1, 1).normalized()]:
			for gap in [50.0, 82.0, 120.0]:
				_run_case("approach", direction, gap, hz, "open", false)
	_run_case("left_side_blocked", Vector2.RIGHT, 50.0, 60, "one_side", false)
	_run_case("narrow_corridor", Vector2.RIGHT, 50.0, 60, "corridor", false)
	_run_case("corridor_dead_end", Vector2.RIGHT, 50.0, 60, "dead_end", true)
	_run_case("initial_overlap", Vector2.RIGHT, 15.0, 60, "open", true)
	_run_case("stationary_restore", Vector2.ZERO, 50.0, 60, "open", false)
	_run_case("reversal", Vector2.RIGHT, 82.0, 60, "reversal", false)
	var baseline_gap := 50.0 + 280.0 / 60.0 - 340.0 / 60.0
	_check(is_equal_approx(baseline_gap, 49.0), "Original speed cannot preserve initial separation during approach")
	var report := {"schema": 1, "kind": "synthetic_follow_geometry", "passed": failures.is_empty(),
		"checks": checks, "failures": failures, "cases": cases,
		"limits": ["Synthetic resolved hero traces and explicit terrain center bounds, not actual gameplay or visual clearance.",
			"An enclosed dead end is intentionally allowed to trap the follower; player authority is never changed."]}
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_empty():
		var file := FileAccess.open(output, FileAccess.WRITE)
		file.store_string(JSON.stringify(report, "\t") + "\n")
	print("COMPANION_GEOMETRY ", "PASS" if failures.is_empty() else "FAIL", " checks=", checks, " cases=", cases.size(), " failures=", failures)
	quit(0 if failures.is_empty() else 1)


func _check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label)


func _clear(a: Vector2, b: Vector2) -> bool:
	var count := maxi(1, ceili(a.distance_to(b)))
	for i in range(count + 1):
		var p := a.lerp(b, float(i) / float(count))
		if terrain in ["corridor", "dead_end"] and absf(p.y) > 9.0 + 0.001:
			return false
		if terrain == "dead_end" and p.x > 300.0 + 0.001:
			return false
		if terrain == "one_side" and p.y > 2.0:
			return false
	return true


func _run_case(label: String, direction: Vector2, gap: float, hz: int, terrain_name: String, may_overlap: bool) -> void:
	terrain = terrain_name
	var steering := Steering.new()
	var hero := Vector2.ZERO
	var mole := (direction if not direction.is_zero_approx() else Vector2.RIGHT) * gap
	var minimum := gap
	var trapped := 0
	var max_step := 0.0
	var max_attempts := 0
	var choices: Dictionary = {}
	var prior_lateral_sign := 0
	var lateral_reversals := 0
	var choice_changes: Array[Dictionary] = []
	var previous_choice := ""
	var dt := 1.0 / float(hz)
	var path_valid := true
	var separation_valid := true
	var budget_valid := true
	for frame in hz * 2:
		var hero_before := hero
		var motion := direction * 340.0 * dt
		if terrain_name == "reversal" and frame >= hz:
			motion = -motion
		hero += motion
		if terrain_name == "dead_end": hero.x = minf(hero.x, 300.0)
		var velocity := (hero - hero_before) / dt
		var speed := 580.0 if mole.distance_to(hero) > 240.0 else 280.0
		var preferred := (hero - mole).limit_length(minf(speed * dt, maxf(0.0, mole.distance_to(hero) - Steering.COMFORT)))
		var step: Vector2 = steering.choose(mole, hero_before, hero, velocity, preferred, speed, dt, _clear)
		if steering.choice != previous_choice:
			choice_changes.append({"frame": frame, "choice": steering.choice, "mole": [mole.x, mole.y], "step": [step.x, step.y]})
			previous_choice = steering.choice
		if absf(step.y) > 0.01:
			var lateral_sign := 1 if step.y > 0.0 else -1
			if prior_lateral_sign != 0 and lateral_sign != prior_lateral_sign:
				lateral_reversals += 1
			prior_lateral_sign = lateral_sign
		var swept := Steering.segment_distance(mole - hero_before, mole + step - hero)
		minimum = minf(minimum, swept)
		path_valid = path_valid and _clear(mole, mole + step)
		separation_valid = separation_valid and swept >= Steering.EXCLUSION - 0.001
		budget_valid = budget_valid and step.length() <= Steering.ESCAPE_SPEED * dt + 0.001
		max_step = maxf(max_step, step.length())
		max_attempts = maxi(max_attempts, steering.attempts)
		choices[steering.choice] = int(choices.get(steering.choice, 0)) + 1
		if steering.trapped: trapped += 1
		mole += step
	var name := "%s/%s/%s/%sHz" % [label, direction, gap, hz]
	_check(path_valid, name + " entire mole path remains inside terrain")
	_check(budget_valid, name + " one bounded movement budget")
	_check(max_attempts <= 7, name + " bounded local candidate work")
	if not may_overlap:
		_check(separation_valid, name + " actual relative sweep preserves 50px")
		_check(trapped == 0, name + " feasible path does not trap")
	if terrain_name == "dead_end":
		_check(trapped > 0, name + " impossible escape is explicitly reported")
	if terrain_name in ["corridor", "dead_end"]:
		_check(lateral_reversals == 0, name + " no alternating lateral escape in constrained passage")
	if terrain_name == "one_side":
		_check(lateral_reversals <= 1, name + " one sidestep and rejoin without repeated lateral reversals")
	if label == "stationary_restore":
		_check(absf(mole.distance_to(hero) - Steering.COMFORT) < 0.01, name + " stationary companion restores comfortable gap")
	if label == "initial_overlap":
		_check(minimum >= gap - 0.001, name + " initial overlap never becomes deeper")
		_check(trapped == 0, name + " open floor permits overlap recovery")
		_check(mole.distance_to(hero) >= Steering.EXCLUSION, name + " overlap actually recovers")
	cases.append({"name": name, "minimum_swept_gap": minimum, "final_gap": mole.distance_to(hero),
		"terrain_valid": path_valid, "budget_valid": budget_valid, "max_step": max_step,
		"max_candidate_safety_checks": max_attempts, "trapped_ticks": trapped, "lateral_reversals": lateral_reversals, "choices": choices,
		"choice_changes": choice_changes})
