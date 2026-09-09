extends Node
## One ordered source of truth for automated startup. First matching entry wins.
const CASES: Array[Dictionary] = [
	{"flags": ["--qa-mobile-performance"], "method": "run", "suite": "mobile_performance", "surface": false},
	{"flags": ["--qa-input-release"], "method": "_run_input_release_qa", "suite": "input_release", "surface": true},
	{"flags": ["--smoke-test"], "method": "_run_smoke_test", "suite": "smoke", "surface": true},
	{"flags": ["--qa-landscape"], "method": "_run_landscape_qa", "suite": "layout", "surface": false},
	{"flags": ["--qa-iphone-layout"], "method": "_run_iphone_layout_qa", "suite": "layout", "surface": false},
	{"flags": ["--qa-portrait"], "method": "_run_portrait_qa", "suite": "layout", "surface": false},
	{"flags": ["--qa-version-menu"], "method": "_start_qa_version_menu", "suite": "layout", "surface": false},
	{"flags": ["--qa-onboarding"], "method": "_run_onboarding_qa", "suite": "layout", "surface": false},
	{"flags": ["--qa-mine", "--qa-swing", "--qa-up", "--qa-camera", "--qa-performance"], "method": "_start_qa_mine", "suite": "world_fixtures", "surface": true},
	{"flags": ["--qa-barrier"], "method": "_start_qa_barrier", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-moss-overview"], "method": "_start_qa_moss_overview", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-surface-camp"], "method": "_start_qa_surface_camp", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-assay"], "method": "_start_qa_surface_context", "suite": "world_fixtures", "surface": false, "args": ["sell"]},
	{"flags": ["--qa-forge"], "method": "_start_qa_surface_context", "suite": "world_fixtures", "surface": false, "args": ["forge"]},
	{"flags": ["--qa-mine-entrance"], "method": "_start_qa_surface_context", "suite": "world_fixtures", "surface": false, "args": ["mine"]},
	{"flags": ["--qa-surface-decor"], "method": "_start_qa_surface_decor", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-gate"], "method": "_start_qa_surface", "suite": "world_fixtures", "surface": false, "args": ["gate"]},
	{"flags": ["--qa-gate-ready"], "method": "_start_qa_surface", "suite": "world_fixtures", "surface": false, "args": ["gate_ready"]},
	{"flags": ["--qa-open-gate"], "method": "_start_qa_surface", "suite": "world_fixtures", "surface": false, "args": ["open_gate"]},
	{"flags": ["--qa-moon-surface"], "method": "_start_qa_surface", "suite": "world_fixtures", "surface": false, "args": ["moon_surface"]},
	{"flags": ["--qa-moon-mine"], "method": "_start_qa_surface", "suite": "world_fixtures", "surface": false, "args": ["moon_mine"]},
	{"flags": ["--qa-surface-performance"], "method": "_start_qa_surface_performance", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-journey-performance"], "method": "_run_journey_performance_qa", "suite": "journey_performance", "surface": false},
	{"flags": ["--qa-moon-resource"], "method": "_start_qa_moon_resource", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-ember-resource"], "method": "_start_qa_surface_resource", "suite": "world_fixtures", "surface": false, "args": ["ember_fault"]},
	{"flags": ["--qa-starfall-resource"], "method": "_start_qa_surface_resource", "suite": "world_fixtures", "surface": false, "args": ["starfall_lattice"]},
	{"flags": ["--qa-surface-mountain", "--qa-surface-mountain-damage"], "method": "_start_qa_surface_mountain", "suite": "world_fixtures", "surface": false, "args_flag": "--qa-surface-mountain-damage"},
	{"flags": ["--qa-surface-mountains", "--qa-moon-mountain"], "method": "_start_qa_surface_mountains", "suite": "world_fixtures", "surface": false, "args": ["moonglass_mountain"]},
	{"flags": ["--qa-ember-mountain"], "method": "_start_qa_surface_mountains", "suite": "world_fixtures", "surface": false, "args": ["emberdeep_mountain"]},
	{"flags": ["--qa-starfall-mountain"], "method": "_start_qa_surface_mountains", "suite": "world_fixtures", "surface": false, "args": ["starfall_mountain"]},
	{"flags": ["--qa-starforge"], "method": "_start_qa_starforge", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-crusher-impact"], "method": "_run_crusher_impact_qa", "suite": "crusher", "surface": false},
	{"flags": ["--qa-rootwound-locked"], "method": "_start_qa_rootwound", "suite": "world_fixtures", "surface": false, "args": ["locked"]},
	{"flags": ["--qa-drill"], "method": "_start_qa_rootwound", "suite": "world_fixtures", "surface": false, "args": ["drill"]},
	{"flags": ["--qa-depth-loop"], "method": "_start_qa_rootwound", "suite": "world_fixtures", "surface": false, "args": ["loop"]},
	{"flags": ["--qa-rootwound-performance"], "method": "_start_qa_rootwound", "suite": "world_fixtures", "surface": false, "args": ["performance"]},
	{"flags": ["--qa-rootwound"], "method": "_start_qa_rootwound", "suite": "world_fixtures", "surface": false, "args": ["starforge"]},
	{"flags": ["--qa-prismatic"], "method": "_start_qa_prismatic", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-molten-performance"], "method": "_start_qa_endgame_depth", "suite": "world_fixtures", "surface": false, "args": ["emberMine", 2, true]},
	{"flags": ["--qa-molten"], "method": "_start_qa_endgame_depth", "suite": "world_fixtures", "surface": false, "args": ["emberMine", 2]},
	{"flags": ["--qa-voidstar"], "method": "_start_qa_endgame_depth", "suite": "world_fixtures", "surface": false, "args": ["starMine", 3]},
	{"flags": ["--qa-hub"], "method": "_start_qa_hub", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-deepheart"], "method": "_start_qa_deepheart", "suite": "world_fixtures", "surface": false},
	{"flags": ["--qa-endgame"], "method": "_run_endgame_qa", "suite": "endgame", "surface": false},
	{"flags": ["--qa-endless"], "method": "_run_endless_qa", "suite": "endless", "surface": false},
	{"flags": ["--qa-workshop-overlap"], "method": "_run_workshop_overlap_qa", "suite": "commerce", "surface": false},
	{"flags": ["--qa-workshop-panel"], "method": "_run_workshop_panel_qa", "suite": "commerce", "surface": false},
	{"flags": ["--qa-commerce"], "method": "_run_commerce_integration_qa", "suite": "commerce", "surface": false},
	{"flags": ["--visual-capture-suite"], "method": "_start_visual_capture_suite", "suite": "main", "surface": false},
	{"flags": ["--qa-dev-tools"], "method": "_run_dev_tools_qa", "suite": "build_flavor", "surface": false},
	{"flags": ["--qa-build-flavor"], "method": "_run_build_flavor_qa", "suite": "build_flavor", "surface": false},
	{"flags": ["--qa-one-point-zero-state"], "method": "_run_state_qa", "suite": "one_point_zero", "surface": false},
	{"flags": ["--qa-one-point-zero-world"], "method": "run", "suite": "one_point_zero_world", "surface": false},
	{"flags": ["--qa-one-point-zero-migration"], "method": "run", "suite": "one_point_zero_migration", "surface": false},
	{"flags": ["--qa-one-point-zero-ui"], "method": "run", "suite": "one_point_zero_ui", "surface": false},
]

var main: Node
var active_suite: RefCounted
var performance_qa_active: = false
var performance_qa_elapsed: = 0.0
var performance_qa_frames: = 0
var performance_qa_mode: = "mossvein"
var performance_qa_warmup: = 0.0

func _init(game: Node) -> void:
	main = game

static func has_any_arg(args: PackedStringArray, candidates: Array) -> bool:
	for candidate in candidates:
		if candidate in args: return true
	return false

static func is_automated(args: PackedStringArray) -> bool:
	return not selected_case(args).is_empty()

static func selected_case(args: PackedStringArray) -> Dictionary:
	for entry in CASES:
		if has_any_arg(args, entry.flags): return entry
	return {}

func start(args: PackedStringArray) -> bool:
	var entry: Dictionary = selected_case(args)
	if entry.is_empty(): return false
	if entry.surface: main.surface_world.set_active(true)
	var target: Object = main
	if entry.suite != "main":
		active_suite = load("res://scripts/qa/suites/%s.gd" % entry.suite).new(main, self)
		target = active_suite
	var parameters: Array = Array(entry.get("args", [])).duplicate()
	if entry.has("args_flag"): parameters.append(String(entry.args_flag) in args)
	Callable(target, entry.method).bindv(parameters).call_deferred()
	return true

func advance_performance(delta: float) -> bool:
	if not performance_qa_active: return false
	performance_qa_warmup += delta
	if performance_qa_warmup < 1.0:
		return true
	performance_qa_elapsed += delta
	performance_qa_frames += 1
	if performance_qa_elapsed >= 3.0:
		var average_fps: = float(performance_qa_frames) / performance_qa_elapsed
		var surface_detail: = ""
		if performance_qa_mode == "ember_surface":
			var surface_metrics: Dictionary = main.surface_world.mobile_performance_snapshot()
			var route_metrics: Dictionary = main.surface_world.route_steering_snapshot()
			assert (is_equal_approx(float(surface_metrics.dynamic_visual_hz), 30.0))
			assert (int(surface_metrics.dynamic_visual_updates) > 0)
			assert (int(surface_metrics.dynamic_visual_updates_skipped) > int(surface_metrics.dynamic_visual_updates))
			assert (int(route_metrics.events) > 0, "Surface performance QA must exercise soft route steering while moving")
			surface_detail = " dynamic_visuals=%d skipped=%d route_steers=%d" % [
				int(surface_metrics.dynamic_visual_updates),
				int(surface_metrics.dynamic_visual_updates_skipped),
				int(route_metrics.events),
			]
		print("EVER_DEEPER_PERFORMANCE_OK mode=%s average_fps=%.1f frames=%d redraw_interval=30 target=ray_aabb%s" % [performance_qa_mode, average_fps, performance_qa_frames, surface_detail])
		main.get_tree().quit(0)
		return true
	return false
