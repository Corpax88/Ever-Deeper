extends SceneTree
## Regression for the actual JSON replay failure; no renderer or game ticks.
const Capture = preload("res://tools/native_motion_ingame_pilot/capture.gd")
var checks: Array[Dictionary] = []


func _initialize() -> void:
	var output := ""
	var replay_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--replay="): replay_path = arg.trim_prefix("--replay=")
	if not output.is_absolute_path() or not replay_path.is_absolute_path():
		print("--output=<absolute JSON report> --replay=<retained actual candidate report>")
		quit(2)
		return
	var original: Dictionary = {
		"resource_index": 5, "resource_id": "endless_d000001_node_005",
		"target": [2208.0, 1184.0], "start": [1992.0, 1248.0],
		"contact": [2128.0, 1248.0], "end": [2264.0, 1248.0],
		"target_depth": 1, "start_depth": 1, "end_depth": 1,
		"initial_hp": 998, "max_hp": 998, "direction": "right",
		"approach_pixels": 136.0, "exit_pixels": 136.0, "sample_gap_px": 4.0,
	}
	var decoded: Dictionary = JSON.parse_string(JSON.stringify(original))
	var actual: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(replay_path))
	_check(typeof(original.resource_index) == TYPE_INT and typeof(decoded.resource_index) == TYPE_FLOAT and original != decoded, "Reproduces the retained int/float Dictionary failure")
	_check(Capture.routes_equal(original, decoded), "Accepts full unchanged JSON round trip")
	_check(Capture.routes_equal(original, actual.route), "Accepts the exact retained real candidate route")
	for key in original:
		var changed: Dictionary = decoded.duplicate(true)
		match typeof(changed[key]):
			TYPE_ARRAY: changed[key][0] += 0.001
			TYPE_STRING: changed[key] += "_different"
			TYPE_FLOAT: changed[key] += 1.0
		_check(not Capture.routes_equal(original, changed), "Rejects real difference in " + key)
	var fractional: Dictionary = decoded.duplicate(true)
	fractional.resource_index += 0.5
	_check(not Capture.routes_equal(original, fractional), "Rejects fractional resource index without truncation")
	var small_delta: Dictionary = decoded.duplicate(true)
	small_delta.contact[0] += 0.000000001
	_check(not Capture.routes_equal(original, small_delta), "Rejects subpixel coordinate difference without tolerance")
	var wrong_type: Dictionary = decoded.duplicate(true)
	wrong_type.initial_hp = "998"
	_check(not Capture.routes_equal(original, wrong_type), "Rejects numeric string in HP")
	var missing: Dictionary = decoded.duplicate(true)
	missing.erase("max_hp")
	_check(not Capture.routes_equal(original, missing), "Rejects missing field")
	var extra: Dictionary = decoded.duplicate(true)
	extra["extra"] = true
	_check(not Capture.routes_equal(original, extra), "Rejects added field")
	var passed := true
	for check in checks: passed = passed and bool(check.passed)
	var report := {"passed": passed, "checks": checks, "engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "replay_sha256": FileAccess.get_sha256(replay_path), "fixture_sha256": FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/capture.gd"), "test_sha256": FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/check_route_comparison.gd"), "route_field_count": original.size(), "rendered": false}
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("NATIVE_ROUTE_COMPARISON checks=", checks.size(), " passed=", passed)
	quit(0 if passed else 1)


func _check(passed: bool, label: String) -> void:
	checks.append({"check": label, "passed": passed})
	if not passed: print("NATIVE_ROUTE_COMPARISON_FAIL ", label)
