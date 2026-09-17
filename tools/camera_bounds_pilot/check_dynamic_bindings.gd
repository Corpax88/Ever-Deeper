extends SceneTree
## Headless identity/lifecycle guard checks only; not draw or visual evidence.
var output: String = ""
var subject: Node
var sections: Node
var checks: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_absolute_path(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	subject = load("res://tools/camera_bounds_pilot/candidate_dynamic.gd").new()
	sections = load("res://scripts/lighting/lit_draw_sections.gd").new()
	subject.lit_draw_sections = sections
	subject.add_child(sections)
	sections._world = subject
	_check(subject._study_dynamic_bindings_match(), "Empty dynamic list is consistent")
	var impact_a: Dictionary = {"position":Vector2(100,100),"age":.1,"life":.85}
	var impact_b: Dictionary = {"position":Vector2(120,100),"age":.2,"life":.85}
	subject._crusher_impacts.append(impact_a)
	_check(not subject._study_dynamic_bindings_match(), "Appended impact requires full pool update")
	_add_section(impact_a)
	_check(subject._study_dynamic_bindings_match(), "Original bound dictionary is accepted")
	impact_a.age = .15
	_check(subject._study_dynamic_bindings_match(), "Age mutation retains live dictionary binding")
	var bound: Dictionary = sections._pool[0].paint.get_bound_arguments()[0]
	_check(is_same(bound, impact_a) and float(bound.age) == .15, "Callable bind exposes current age by identity")
	impact_a.position += Vector2(0,-1408)
	_check(subject._study_dynamic_bindings_match() and bound.position == impact_a.position, "Rebase mutation remains live in existing bound dictionary")
	subject._crusher_impacts.append(impact_b)
	_check(not subject._study_dynamic_bindings_match(), "Second append falls back until parent draw updates pool")
	_add_section(impact_b)
	_check(subject._study_dynamic_bindings_match(), "Two original bindings preserve order")
	subject._crusher_impacts.pop_front()
	_check(not subject._study_dynamic_bindings_match(), "Expiry/removal requires inherited pool update")
	subject._crusher_impacts.push_front(impact_a)
	var replacement: Dictionary = impact_a.duplicate(true)
	subject._crusher_impacts[0] = replacement
	_check(not subject._study_dynamic_bindings_match(), "Equal-valued replacement cannot reuse stale dictionary identity")
	subject._crusher_impacts[0] = impact_a
	subject._crusher_impacts.reverse()
	_check(not subject._study_dynamic_bindings_match(), "Reorder or fixed-size ring eviction falls back")
	subject._crusher_impacts.reverse()
	sections._pool[0].hide()
	_check(not subject._study_dynamic_bindings_match(), "Hidden active section falls back")
	sections._pool[0].show()
	sections._pool[0].paint = subject._draw_floor_detail.bind(Vector2i.ZERO, Rect2())
	_check(not subject._study_dynamic_bindings_match(), "Unexpected paint method cannot enter dynamic fast path")
	sections._pool[0].paint = subject._draw_impact_section.bind(impact_a)
	_check(subject._study_dynamic_bindings_match(), "Restored ordered bindings are valid")
	_check(not subject._study_cached_set_valid(), "Empty cache cannot pass vacuously")
	var cached: Node = sections.DrawSection.new()
	cached.revision = 123
	sections.add_child(cached)
	sections._cached[Vector3i.ZERO] = cached
	subject._study_cached_count = 1
	subject._study_cached_epoch = sections._epoch
	_check(subject._study_cached_set_valid(), "Expected visible cached set is accepted")
	sections._cached.clear()
	_check(not subject._study_cached_set_valid(), "Clearing expected cached set forces full setup")
	sections._cached[Vector3i.ZERO] = cached
	cached.revision = -1
	_check(not subject._study_cached_set_valid(), "Fresh-command invalidation forces full setup")
	cached.revision = 123
	sections._epoch += 1
	_check(not subject._study_cached_set_valid(), "Intervening cache epoch forces full setup")
	var passed: bool = true
	for row in checks: passed = passed and bool(row.passed)
	FileAccess.open(output.path_join("dynamic-binding-guards.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"passed":passed,"rendered":false,"callback_order_verified":false,"checks":checks,
		"candidate_sha256":FileAccess.get_sha256("res://tools/camera_bounds_pilot/candidate_dynamic.gd"),
		"limit":"Checks live Callable-bound Dictionary identity and pool lifecycle guards. Godot draw callback scheduling/pixels still require a graphical cadence fixture before any performance measurement."},"\t"))
	subject.free()
	print("CAMERA_DYNAMIC_GUARDS_COMPLETE passed=", passed, " checks=", checks.size())
	quit(0 if passed else 4)

func _add_section(impact: Dictionary) -> void:
	var section: Node = sections.DrawSection.new()
	section.world = subject
	section.paint = subject._draw_impact_section.bind(impact)
	sections._pool.append(section)
	sections.add_child(section)
	sections._used += 1

func _check(ok: bool, name: String) -> void:
	checks.append({"passed":ok,"name":name})
