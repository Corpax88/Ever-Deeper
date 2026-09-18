extends SceneTree
## Opt-in native-motion study. Normal input, collision and mining own the world.
const BASE_SOURCE := "5ca6f0f77a1f87eaead777613062208159325068"
const ASSETS := "res://tools/native_motion_ingame_pilot/assets/worn/"
const ASSET_HASHES := {
	"manifest.json": "51c01affab7d9d95e90fe6e5bcbf4cad39620b6accf9d492a2b89d5d1103b663",
	"up.png": "f638571197213ba3199075bf65e1d84f902deecd7edbe58aa0f033f89701734e",
	"up-cloth.png": "3ed4b2b67bee9d946af35c368876d17d2898fc5ddfd5a5191dc244ed08790573",
}
const REST_ASSETS := "res://tools/native_motion_ingame_pilot/assets/worn-rest/"
const REST_ASSET_HASHES := {
	"manifest.json": "4d2f0319e0f7902a71f36087ebcc72f40338ac3cab1a5c83610ee55bd71a2af4",
	"up.png": "5f7b94aff057972602456243902953b35662936b044a709ace2ae51ea770fdf7",
	"up-cloth.png": "ef5cf0dc33de6aebe6401f3e237257d265080c79f8905c37ad246676a897cb34",
}
const CANCEL_ASSETS := "res://tools/native_motion_ingame_pilot/assets/worn-cancel/"
const CANCEL_ASSET_HASHES := {
	"manifest.json": "a156b481596a3727c904b47cdc550a6eef070a594d75b9f87014c673fdea3933",
	"up.png": "adb7ecfdb72a564c4e125b580953d12b38e15b0683bdaf0a68596e10885a766b",
	"up-cloth.png": "d3a5437e1881ebe69529d5875b226b9fe834d1787b3396d29004fde0406abb87",
}
const ROUTE_FILE := "res://tools/native_motion_ingame_pilot/frozen-route.json"
const SPEED := 340.0
const APPROACH := 136.0
const EXIT := 136.0
const WORLD_SEED := 4608
const DIRECTIONS := {"up": Vector2.UP}
var output := ""
var source_sha := ""
var mode := "geometry"
var replay_path := ""
var replay: Dictionary = {}
var direction_name := ""
var depth := 1
var main: Node
var world: Node
var player: Node
var state: Node
var direction := Vector2.ZERO
var route: Dictionary = {}
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var events: Array[Dictionary] = []
var samples: Array[Dictionary] = []
var route_search: Dictionary = {}
var initial_world: Dictionary = {}
var started_wall_ms := 0
var captures: Array[Dictionary] = []
var capture_origin_tick := 0
var capture_origin_process := 0
var capture_seconds := 0.0
var initial_serial := 0
var startup_feedback: Dictionary = {}
var rest_cycle := false
var cancel_cycle := false
var continue_framing_diagnostics := false
var consumer_armed := false
var asset_root := ASSETS
var asset_hashes := ASSET_HASHES


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String, detail: Variant = null) -> bool:
	checks.append({"check": label, "passed": ok, "detail": detail})
	if not ok:
		failures.append(label)
		print("NATIVE_INGAME_FAIL ", label, " ", detail)
	return ok


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--source-sha="): source_sha = arg.trim_prefix("--source-sha=")
		elif arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--direction="): direction_name = arg.trim_prefix("--direction=")
		elif arg.begins_with("--depth="): depth = int(arg.trim_prefix("--depth="))
		elif arg.begins_with("--replay="): replay_path = arg.trim_prefix("--replay=")
		elif arg == "--rest-cycle": rest_cycle = true
		elif arg == "--cancel-cycle": cancel_cycle = true
		elif arg == "--continue-framing-diagnostics": continue_framing_diagnostics = true
	if not output.is_absolute_path() or not DIRECTIONS.has(direction_name) or source_sha.length() != 40 or mode not in ["geometry", "candidate", "baseline"] or (mode != "geometry" and DisplayServer.get_name() == "headless") or (rest_cycle and cancel_cycle):
		print("NATIVE_INGAME_USAGE --mode=geometry|candidate|baseline --direction=right|up --source-sha=<40hex> --output=<absolute> [--depth=1] [--replay=<candidate report>]; visual modes require a rendered display")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	started_wall_ms = Time.get_ticks_msec()
	direction = DIRECTIONS[direction_name]
	if rest_cycle:
		asset_root = REST_ASSETS
		asset_hashes = REST_ASSET_HASHES
	if cancel_cycle:
		asset_root = CANCEL_ASSETS
		asset_hashes = CANCEL_ASSET_HASHES
	if mode == "baseline":
		if not replay_path.is_absolute_path() or not FileAccess.file_exists(replay_path):
			_check(false, "Baseline requires an actual candidate input trace")
			_finish()
			return
		replay = JSON.parse_string(FileAccess.get_file_as_string(replay_path))
		var same_source: bool = replay.get("source_sha", "") == source_sha
		var same_runtime: bool = replay.get("production_runtime_source", "") == BASE_SOURCE and replay.get("consumer_sha256", "") == FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/pilot_visual.gd") and replay.get("asset_hashes", {}) == asset_hashes
		if not _check(bool(replay.get("passed", false)) and replay.get("mode", "") == "candidate" and replay.get("direction", "") == direction_name and replay.get("depth", -1) == depth and same_runtime and same_source, "Candidate replay identity matches this case", {"same_source": same_source, "same_runtime_consumer_assets": same_runtime, "candidate_source": replay.get("source_sha", ""), "current_fixture_source": source_sha}):
			_finish()
			return
	if mode != "geometry": root.size = Vector2i(1696, 780)
	for file in asset_hashes:
		if not _check(FileAccess.get_sha256(asset_root + file) == asset_hashes[file], "Exact native packed asset: " + file):
			_finish()
			return
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	if mode in ["candidate", "geometry"]:
		var visual: Node = main.get_node("EndlessDescentWorld/Player/Visual")
		visual.set_script(load("res://tools/native_motion_ingame_pilot/pilot_visual.gd"))
		visual.selected_direction = direction_name
		visual.bank_root = asset_root
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = WORLD_SEED
	seed(WORLD_SEED)
	if not _check(main._dev_jump_endless(depth), "Normal generated Deep entry"):
		_finish()
		return
	world = main.endless_world
	player = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.endless_workshops["tool_forge"] = {"built": false, "level": 0}
	player.movement_speed = SPEED
	player.prepare_visual_cache()
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	initial_world = _world_geometry()
	if not _check(not bool(world.rope_attached) and is_equal_approx(float(world._mining_cycle_duration()), 0.68), "Normal unencumbered Worn clock and movement"):
		_finish()
		return
	route = _find_route()
	if not _check(not route.is_empty(), "Natural target, same-heading approach and exit exist", route_search):
		_finish()
		return
	var frozen_route: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ROUTE_FILE))
	if not _check(depth == 1 and routes_equal(route, frozen_route), "Natural route matches the frozen Worn/up working plane", route):
		_finish()
		return
	if not _check(initial_world == _world_geometry(), "Route search changes no terrain, resource HP or props"):
		_finish()
		return
	world.restore_position(_vec(route.start))
	player.set_facing(direction)
	player.control_enabled = true
	main.quick_tutorial.dismiss()
	for frame in 3: await process_frame
	if not _check(Vector2(player.global_position).distance_to(_vec(route.start)) < 0.01, "Normal restore accepts exact natural start"):
		_finish()
		return
	_write_json("setup-world.json", initial_world)
	if mode == "geometry":
		await _geometry_sequence()
	else:
		if mode == "baseline" and not _check(routes_equal(route, replay.route), "Replay uses identical natural target and path"):
			_finish()
			return
		if not await _settle_feedback():
			_finish()
			return
		if mode == "candidate":
			consumer_armed = player.visual.arm()
			if not _check(consumer_armed, "Native consumer arms from real supported idle"):
				_finish()
				return
		await RenderingServer.frame_post_draw
		capture_origin_tick = Engine.get_physics_frames()
		capture_origin_process = Engine.get_process_frames()
		initial_serial = int(player._mining_impact_serial)
		if mode == "candidate": await _candidate_sequence()
		else: await _baseline_sequence()
	_finish()


static func routes_equal(actual: Dictionary, recorded: Dictionary) -> bool:
	# JSON decodes every number as float; Dictionary equality also compares their
	# Variant types. Normalize both complete route objects without casts, omitted
	# fields or coordinate tolerances. Full precision retains real differences.
	return JSON.parse_string(JSON.stringify(actual, "", true, true)) == JSON.parse_string(JSON.stringify(recorded, "", true, true))


func _settle_feedback() -> bool:
	var service: Node = root.get_node("AchievementService")
	var elapsed := 0.0
	var quiet := 0.0
	var started := Time.get_ticks_msec()
	var observations: Array = []
	# The complete natural toast queue takes72.6 simulated seconds. The
	# software-rendered rest trial reached only71.85s at the old wall watchdog;
	# retain the simulation/quiet criteria and allow the host time to reach them.
	while elapsed < 110.0 and Time.get_ticks_msec() - started < 300000:
		await RenderingServer.frame_post_draw
		var delta := root.get_process_delta_time()
		elapsed += delta
		var toast: Dictionary = main.achievement_toast.debug_snapshot()
		var pickup: Node = player.get_node("ResourcePickupBurst")
		var busy: bool = bool(service.evaluation_pending) or int(state.get("_state_batch_depth")) > 0 or bool(state.get("_state_batch_dirty")) or bool(main.hud_refresh_pending) or bool(toast.active) or int(toast.queue_size) > 0 or not pickup.entries.is_empty() or String(player.visual.active_gear) != "worn"
		quiet = 0.0 if busy else quiet + delta
		if observations.is_empty() or elapsed - float(observations.back().elapsed) > 1.0:
			observations.append({"elapsed": elapsed, "busy": busy, "quiet": quiet, "queue": toast.queue_size})
		if quiet >= 0.5: break
	startup_feedback = {"naturally_settled": quiet >= 0.5, "simulation_seconds": elapsed, "wall_ms": Time.get_ticks_msec() - started, "forced_clear": false, "manual_clock_steps": false, "observations": observations}
	return _check(quiet >= 0.5, "Startup feedback naturally settles before capture", startup_feedback)


func _candidate_sequence() -> void:
	for frame in 9:
		if not await _capture_frame("idle"): return
	_input("approach", direction, false)
	var approached := false
	for frame in 50:
		if not await _capture_frame("approach"): return
		var shown: Dictionary = player.visual.presented_snapshot()
		var travel: float = (Vector2(player.global_position) - _vec(route.start)).dot(direction)
		if not _check(travel <= APPROACH + 6.0, "Approach remains within the verified source-phase entry window", travel): return
		if not bool(shown.is_bridge) and shown.state == "walk" and is_equal_approx(float(shown.sample_phase), 0.625) and travel >= APPROACH - 6.0:
			approached = true
			break
	if not _check(approached, "Actually displayed exact walk .625 source reaches the legal target window"): return
	if not _check(Vector2(player.global_position).distance_to(_vec(route.contact)) < 0.01, "Actual mining position matches frozen contact", _array(player.global_position)): return
	_input("mine", Vector2.ZERO, true)
	if cancel_cycle:
		await _cancel_and_restart()
		return
	var recovered := false
	var cycle_wraps := 0
	var previous_progress := 0.0
	for frame in 95:
		if not await _capture_frame("mine"): return
		var shown: Dictionary = player.visual.presented_snapshot()
		var progress := float(player.mining_visual_progress)
		if previous_progress > 0.9 and progress < 0.1: cycle_wraps += 1
		previous_progress = progress
		if cycle_wraps >= 1 and int(player._mining_impact_serial) == initial_serial + 2 and not bool(shown.is_bridge) and shown.state == "mine" and is_equal_approx(float(shown.sample_phase), 0.625):
			recovered = true
			break
	if not _check(recovered and cycle_wraps >= 1 and int(player._mining_impact_serial) == initial_serial + 2, "Exact presented mine .625 exit follows a complete normal cycle and two real hits"): return
	if not _check(String(world.mining_target_id) == route.resource_id and int(world.resources[int(route.resource_index)].hp) < int(route.initial_hp), "Normal target and HP prove real mining authority"): return
	var expected_impacts := 2
	if rest_cycle:
		if not await _rest_and_restart(): return
		expected_impacts = 3
	var exit_origin: Vector2 = player.global_position
	_input("same_heading_exit", direction, false)
	var exited := false
	for frame in 50:
		if not await _capture_frame("same_heading_exit"): return
		if (Vector2(player.global_position) - exit_origin).dot(direction) >= EXIT - 0.01:
			exited = true
			break
	if not _check(exited and not bool(world.mining_active) and int(player._mining_impact_serial) == initial_serial + expected_impacts, "Immediate normal same-heading exit cancels mining without another hit"): return
	if rest_cycle:
		var shown: Dictionary = player.visual.presented_snapshot()
		if not _check(shown.state == "walk" and is_equal_approx(float(shown.sample_phase), 0.625) and _vec(shown.retained_offset).is_zero_approx(), "Final walk stop starts from actual .625 after airborne offset release"): return
		var stopped_at: Vector2 = player.global_position
		_input("final_walk_stop", Vector2.ZERO, false)
		for frame in 20:
			if not await _capture_frame("final_walk_stop"): return
			if not _check(Vector2(player.global_position).distance_to(stopped_at) < 0.001 and not bool(world.mining_active) and int(player._mining_impact_serial) == initial_serial + expected_impacts, "Normal final stop holds world position and produces no hit"): return
		shown = player.visual.presented_snapshot()
		if not _check(shown.state == "idle" and not bool(shown.is_bridge) and float(shown.state_elapsed) > 0.25, "Final walk-to-idle bridge advances on time and reaches continuing idle"): return
	var bridge_starts := 0
	var handoffs := 0
	for event in player.visual.transitions:
		if event.event == "bridge_start": bridge_starts += 1
		if event.event == "canonical_handoff": handoffs += 1
	var expected_bridges := 6 if rest_cycle else 3
	_check(bridge_starts == expected_bridges and handoffs == expected_bridges, "Every requested exact-source bridge and actual canonical handoff was observed", {"expected": expected_bridges, "starts": bridge_starts, "handoffs": handoffs})
	var impacts := 0
	for sample in samples:
		if bool(sample.visual.get("presenting_impact", false)) and is_equal_approx(float(sample.visual.get("sample_phase", -1.0)), 0.55): impacts += 1
	_check(impacts == expected_impacts, "Every actual drawn native .55 contact accompanies a real impact", {"expected": expected_impacts, "shown": impacts})
	_verify_graphic_motion()


func _cancel_and_restart() -> void:
	var stopped_at: Vector2 = player.global_position
	var hp := int(world.resources[int(route.resource_index)].hp)
	var ready := false
	for frame in 30:
		if not await _capture_frame("pre_hit_windup"): return
		if not _check(int(player._mining_impact_serial) == initial_serial and int(world.resources[int(route.resource_index)].hp) == hp, "Initial windup has no real hit before cancellation"): return
		var shown: Dictionary = player.visual.presented_snapshot()
		if shown.state == "mine" and not bool(shown.is_bridge) and is_equal_approx(float(shown.sample_phase), 0.392857142857143):
			ready = true
			break
	if not _check(ready, "Pre-hit cancel starts from the actual measured .392857 native draw"): return
	_input("cancel_before_hit", Vector2.ZERO, false)
	ready = false
	for frame in 15:
		if not await _capture_frame("cancel_before_hit"): return
		if not _check(Vector2(player.global_position).distance_to(stopped_at) < 0.001 and not bool(world.mining_active) and int(player._mining_impact_serial) == initial_serial and int(world.resources[int(route.resource_index)].hp) == hp, "Normal pre-hit release holds position and cancels damage throughout the stop"): return
		var shown: Dictionary = player.visual.presented_snapshot()
		if shown.state == "idle" and not bool(shown.is_bridge) and is_equal_approx(float(shown.sample_phase), 0.0333333333333333):
			ready = true
			break
	if not _check(ready, "The first actually presented idle .033333 enables the authored restart"): return
	# Input resumes immediately after that real idle draw; no full idle-loop wait.
	_input("restart_after_cancel", Vector2.ZERO, true)
	ready = false
	for frame in 45:
		if not await _capture_frame("restart_after_cancel"): return
		var shown: Dictionary = player.visual.presented_snapshot()
		if int(player._mining_impact_serial) == initial_serial + 1 and shown.state == "mine" and not bool(shown.is_bridge) and is_equal_approx(float(shown.sample_phase), 0.625):
			ready = true
			break
	if not _check(ready and String(world.mining_target_id) == route.resource_id and int(world.resources[int(route.resource_index)].hp) == hp - 4, "Immediate normal restart reaches the same ore and exactly one new real hit"): return
	_input("rest_after_restart", Vector2.ZERO, false)
	for frame in 20:
		if not await _capture_frame("rest_after_restart"): return
		if not _check(Vector2(player.global_position).distance_to(stopped_at) < 0.001 and not bool(world.mining_active) and int(player._mining_impact_serial) == initial_serial + 1 and int(world.resources[int(route.resource_index)].hp) == hp - 4, "Final release after restart keeps position and produces no additional hit"): return
	var shown: Dictionary = player.visual.presented_snapshot()
	if not _check(shown.state == "idle" and not bool(shown.is_bridge) and float(shown.state_elapsed) > 0.25, "Cancelled-and-restarted route ends in continuing native idle"): return
	var starts := 0
	var handoffs := 0
	for event in player.visual.transitions:
		if event.event == "bridge_start": starts += 1
		if event.event == "canonical_handoff": handoffs += 1
	_check(starts == 5 and handoffs == 5, "Every one of the five cancel-route bridges completes", {"starts": starts, "handoffs": handoffs})
	var impacts := 0
	for sample in samples:
		if bool(sample.visual.get("presenting_impact", false)) and is_equal_approx(float(sample.visual.get("sample_phase", -1.0)), 0.55): impacts += 1
	_check(impacts == 1, "Cancelled windup contributes no presented impact; restart contributes exactly one", impacts)
	_verify_graphic_motion()


func _rest_and_restart() -> bool:
	var stopped_at: Vector2 = player.global_position
	var hp := int(world.resources[int(route.resource_index)].hp)
	_input("rest_after_mine", Vector2.ZERO, false)
	var completed := false
	var idle_samples: Dictionary = {}
	for frame in 240:
		if not await _capture_frame("rest_after_mine"): return false
		if not _check(Vector2(player.global_position).distance_to(stopped_at) < 0.001 and not bool(world.mining_active) and int(player._mining_impact_serial) == initial_serial + 2 and int(world.resources[int(route.resource_index)].hp) == hp, "Normal rest cancels mining and holds position without extra damage"): return false
		var shown: Dictionary = player.visual.presented_snapshot()
		if shown.state == "idle" and not bool(shown.is_bridge):
			idle_samples[int(shown.local_frame)] = true
			if float(shown.state_elapsed) >= 3.6 and is_zero_approx(float(shown.sample_phase)):
				completed = true
				break
	if not _check(completed and idle_samples.size() >= 24, "One complete timed idle cycle reaches an actually presented idle-zero restart", {"completed": completed, "different_idle_cells": idle_samples.size()}): return false
	_input("restart_mine", Vector2.ZERO, true)
	for frame in 50:
		if not await _capture_frame("restart_mine"): return false
		var shown: Dictionary = player.visual.presented_snapshot()
		if int(player._mining_impact_serial) == initial_serial + 3 and shown.state == "mine" and not bool(shown.is_bridge) and is_equal_approx(float(shown.sample_phase), 0.625):
			return _check(String(world.mining_target_id) == route.resource_id and int(world.resources[int(route.resource_index)].hp) < hp, "Normal idle-to-mine restart reaches the same target and exactly one new real hit")
	return _check(false, "Timed-out actual mine restart")


func _baseline_sequence() -> void:
	var event_index := 0
	var label := "idle"
	for index in Array(replay.samples).size():
		if not await _capture_frame(label): return
		var actual: Dictionary = samples.back()
		var expected: Dictionary = replay.samples[index]
		if not _check(actual.relative_physics_tick == expected.relative_physics_tick and _vec(actual.position).distance_to(_vec(expected.position)) < 0.02 and actual.direction == expected.direction and actual.mining_active == expected.mining_active and absf(float(actual.mining_elapsed) - float(expected.mining_elapsed)) < 0.0001 and actual.relative_impact_serial == expected.relative_impact_serial and actual.target == expected.target and actual.target_hp == expected.target_hp, "Actual baseline mechanics match candidate frame %d" % index, {"actual": actual, "expected": expected}): return
		while event_index < Array(replay.events).size() and int(replay.events[event_index].relative_physics_tick) == int(actual.relative_physics_tick):
			var event: Dictionary = replay.events[event_index]
			label = String(event.label)
			_input(label, _vec(event.movement), bool(event.mine))
			event_index += 1
	_check(event_index == Array(replay.events).size(), "Every actual candidate input event was replayed")
	_verify_graphic_motion()


func _capture_frame(label: String) -> bool:
	await RenderingServer.frame_post_draw
	if not _check(samples.size() < (540 if rest_cycle else 180), "Bounded original-frame budget"): return false
	capture_seconds += root.get_process_delta_time()
	_record(label)
	var sample: Dictionary = samples.back()
	if bool(world.mining_active) and not _check(is_equal_approx(float(world._swing_duration), 0.68) and is_equal_approx(float(world.MINING_HIT_PROGRESS), 0.42), "Actual normal mining retains the exported mechanical clock"): return false
	var framing := _framing_snapshot()
	sample["framing"] = framing
	var image := root.get_texture().get_image()
	if not _check(not image.is_empty() and image.get_size() == Vector2i(1696, 780), "Original native viewport frame captured"): return false
	var name := "frame-%04d.png" % (samples.size() - 1)
	if not _check(image.save_png(output.path_join(name)) == OK, "Original frame saved: " + name): return false
	captures.append({"path": name, "sample": samples.size() - 1, "sha256": FileAccess.get_sha256(output.path_join(name)), "drawn_frame": Engine.get_frames_drawn(), "stage": label})
	_append_jsonline("frames.jsonl", {"sample": sample, "capture": captures.back()})
	# Preserve every layout failure. Diagnostic continuation only records what
	# follows; it cannot turn a failed capture into a pass or a baseline source.
	if mode == "candidate" and not _check(String(player.visual.fatal_error).is_empty(), "Consumer accepts actual normal state packet", player.visual.fatal_error): return false
	var framing_passed := _check(bool(framing.passed), "Actual hero/tool and resource bounds clear viewport and visible HUD", framing)
	if not framing_passed and not continue_framing_diagnostics: return false
	if mode == "candidate":
		var shown: Dictionary = sample.visual
		if not _check(not shown.is_empty() and bool(shown.actually_presented) and int(shown.drawn_frame) == Engine.get_frames_drawn(), "Native source observation belongs to the actual captured draw"): return false
		if bool(world.mining_active) and float(player.mining_visual_progress) < float(world.MINING_HIT_PROGRESS) and shown.state == "mine" and not bool(shown.presenting_impact):
			if not _check(float(shown.sample_phase) < 0.55, "All native contact and post-hit cells are excluded from pre-hit windup"): return false
		if samples.size() > 1 and int(sample.impact_serial) > int(samples[-2].impact_serial):
			if not _check(bool(shown.presenting_impact) and is_equal_approx(float(shown.sample_phase), 0.55) and int(sample.target_hp) < int(samples[-2].target_hp), "Real HP change, impact serial and presented .55 share this frame"): return false
	return true


func _framing_snapshot() -> Dictionary:
	var subjects: Dictionary = {}
	for child in player.visual.get_children():
		if child is Sprite2D and child.texture != null and child.is_visible_in_tree():
			subjects["hero_and_tool"] = child.get_global_transform_with_canvas() * child.get_rect()
	var resource: Node = world.resource_visuals.get(String(route.resource_id))
	if is_instance_valid(resource):
		var sprite: Sprite2D = resource.get_node_or_null("PremiumNode")
		if sprite != null and sprite.texture != null and sprite.is_visible_in_tree():
			subjects["actual_resource_sprite"] = sprite.get_global_transform_with_canvas() * sprite.get_rect()
	var overlays: Dictionary = {}
	var hud: Node = main.premium_hud
	var controls: Array = [main.mine_button, hud.menu_button, hud.guide_button, hud.gold_cluster, hud.bag_button, hud.context_button, hud.progression_goal_panel, hud.objective_chip, hud.status_panel]
	var companion: Node = main.get_node_or_null("CompanionInterface")
	if companion != null:
		controls.append(companion.button)
		if not String(companion.activity.text).is_empty(): controls.append(companion.activity)
	if main.developer_menu != null: controls.append(main.developer_menu.get("toggle_button"))
	for control in controls:
		if is_instance_valid(control) and control.is_visible_in_tree() and control.modulate.a > 0.01:
			overlays[String(control.get_path())] = control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
	if main.minimap_overlay != null and main.minimap_overlay.is_visible_in_tree():
		overlays["minimap"] = main.minimap_overlay.get_global_transform_with_canvas() * hud.minimap_layout_rect()
	if main.achievement_toast.is_presenting():
		overlays["achievement"] = main.achievement_toast.get_global_transform_with_canvas() * Rect2(main.achievement_toast.debug_snapshot().toast_rect)
	var pickup: Node = player.get_node("ResourcePickupBurst")
	for rect in pickup.screen_rects(): overlays["pickup_%d" % overlays.size()] = rect
	var viewport: Rect2 = root.get_visible_rect()
	var violations: Array = []
	if subjects.size() != 2: violations.append("missing actual subject sprite")
	for key in subjects:
		var rect: Rect2 = subjects[key]
		var gap := minf(minf(rect.position.x - viewport.position.x, rect.position.y - viewport.position.y), minf(viewport.end.x - rect.end.x, viewport.end.y - rect.end.y))
		if gap < 8.0: violations.append({"subject": key, "obstruction": "viewport", "gap": gap})
		for overlay in overlays:
			var other: Rect2 = overlays[overlay]
			gap = maxf(maxf(rect.position.x - other.end.x, other.position.x - rect.end.x), maxf(rect.position.y - other.end.y, other.position.y - rect.end.y))
			if gap < 8.0: violations.append({"subject": key, "obstruction": overlay, "gap": gap})
	var subject_rects: Dictionary = {}
	var overlay_rects: Dictionary = {}
	for key in subjects: subject_rects[key] = _rect_array(subjects[key])
	for key in overlays: overlay_rects[key] = _rect_array(overlays[key])
	return {"passed": violations.is_empty(), "units": "viewport logical coordinates; production content scaling retained", "subjects": subject_rects, "overlays": overlay_rects, "violations": violations, "viewport": _rect_array(viewport)}


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _verify_graphic_motion() -> void:
	var movement_frames := 0
	for index in range(1, samples.size()):
		var before: Dictionary = samples[index - 1]
		var current: Dictionary = samples[index]
		var step := _vec(current.position) - _vec(before.position)
		if step.length() > 0.001:
			movement_frames += 1
			var expected := SPEED * float(int(current.physics_frame) - int(before.physics_frame)) / Engine.physics_ticks_per_second
			if not _check(absf(step.dot(direction) - expected) < 0.02 and absf(step.cross(direction)) < 0.01, "Actual captured movement equals authored speed", {"sample": index, "distance": step.length(), "expected": expected}): return
	_check(movement_frames >= (24 if cancel_cycle else 40), "Actual route contains its complete required gait observation intervals", {"frames": movement_frames, "approach_only": cancel_cycle})
	var final := _world_geometry()
	_check(final.floor_hash == initial_world.floor_hash and final.dig_damage == initial_world.dig_damage and final.resource_layout == initial_world.resource_layout, "Normal captured input preserves terrain and natural resource layout")
	_check(captures.size() == samples.size(), "Every observed frame has an original PNG")
	_write_json("final-world.json", final)


func _find_route() -> Dictionary:
	var original: Vector2 = player.global_position
	var perpendicular := Vector2(-direction.y, direction.x)
	var examined := 0
	var clear_routes := 0
	for index in world.resources.size():
		var resource: Dictionary = world.resources[index]
		if bool(resource.mined): continue
		var target: Vector2 = resource.position
		if target.y < 450.0: continue
		for forward in [80.0, 88.0, 96.0]:
			for sideways in [-64.0, -56.0, -48.0, 48.0, 56.0, 64.0]:
				examined += 1
				var contact: Vector2 = target - direction * forward + perpendicular * sideways
				var start: Vector2 = contact - direction * APPROACH
				var end: Vector2 = contact + direction * EXIT
				if minf(start.y, end.y) < 320.0: continue
				if not _clear_route(start, end): continue
				clear_routes += 1
				player.global_position = contact
				player.set_facing(direction)
				if int(world._nearest_resource_index()) != index: continue
				player.set_facing((target - contact).normalized())
				if String(player.direction_name) != direction_name: continue
				# A one-frame displacement tolerance is still a real legal contact.
				var legal_window := true
				for delta in [-6.0, 0.0, 6.0]:
					player.global_position = contact + direction * delta
					player.set_facing(direction)
					if int(world._nearest_resource_index()) != index: legal_window = false
				if not legal_window: continue
				player.global_position = original
				route_search = {"examined": examined, "collision_clear": clear_routes}
				return {"resource_index": index, "resource_id": String(resource.id), "target": _array(target), "start": _array(start), "contact": _array(contact), "end": _array(end), "target_depth": int(world.depth_at_position(target)), "start_depth": int(world.depth_at_position(start)), "end_depth": int(world.depth_at_position(end)), "initial_hp": int(resource.hp), "max_hp": int(resource.max_hp), "direction": direction_name, "approach_pixels": APPROACH, "exit_pixels": EXIT, "sample_gap_px": 4.0}
	player.global_position = original
	route_search = {"examined": examined, "collision_clear": clear_routes, "resources": world.resources.size()}
	return {}


func _clear_route(start: Vector2, end: Vector2) -> bool:
	var count := ceili(start.distance_to(end) / 4.0)
	var previous := start
	for step in range(count + 1):
		var point: Vector2 = start.lerp(end, float(step) / count)
		if bool(world.collision_at(point)): return false
		if Vector2(world._resolve_motion(previous, point - previous)).distance_to(point) > 0.001: return false
		for hazard in world.resonance_hazards:
			if point.distance_to(Vector2(hazard.position)) <= float(hazard.radius) + 32.0: return false
		previous = point
	return true


func _geometry_sequence() -> void:
	var serial := int(player._mining_impact_serial)
	_input("approach", direction, false)
	if not await _walk_until(APPROACH, "approach", _vec(route.start)): return
	_input("mine", Vector2.ZERO, true)
	var frames := 0
	while float(player.mining_visual_progress) < 0.52 and frames < 80:
		await process_frame
		_record("mine")
		frames += 1
	if not _check(bool(world.mining_active) and String(world.mining_target_id) == route.resource_id, "Normal mining selects the unchanged natural target"): return
	if not _check(String(player.direction_name) == direction_name, "Natural target preserves the tested heading"): return
	if not _check(int(player._mining_impact_serial) == serial + 1, "Exactly one real impact precedes movement"): return
	var resource: Dictionary = world.resources[int(route.resource_index)]
	if not _check(int(resource.hp) < int(route.initial_hp) and not bool(resource.mined), "Real strike damages the original surviving resource", {"before": route.initial_hp, "after": resource.hp}): return
	var exit_origin: Vector2 = player.global_position
	_input("same_heading_exit", direction, false)
	if not await _walk_until(EXIT, "same_heading_exit", exit_origin): return
	_check(int(player._mining_impact_serial) == serial + 1 and not bool(world.mining_active), "Normal movement cancels mining without a second hit")
	var final: Dictionary = _world_geometry()
	_check(final.floor_hash == initial_world.floor_hash and final.dig_damage == initial_world.dig_damage, "Actual approach/hit/exit excavates no terrain")
	_check(final.resource_layout == initial_world.resource_layout, "All natural resource positions and identities remain unchanged")
	_write_json("final-world.json", final)


func _walk_until(distance: float, label: String, origin: Vector2) -> bool:
	var previous: Vector2 = player.global_position
	var previous_tick := Engine.get_physics_frames()
	var moved := 0.0
	for frame in 100:
		await process_frame
		_record(label)
		var tick := Engine.get_physics_frames()
		var position: Vector2 = player.global_position
		if tick > previous_tick:
			var step: Vector2 = position - previous
			var expected := SPEED * float(tick - previous_tick) / Engine.physics_ticks_per_second
			if not _check(absf(step.dot(direction) - expected) < 0.02 and absf(step.cross(direction)) < 0.01, label + " actual normal movement equals 340 px/s", {"distance": step.length(), "expected": expected, "physics_ticks": tick - previous_tick}): return false
			previous = position
			previous_tick = tick
			moved = (position - origin).dot(direction)
		if moved >= distance - 0.01:
			return _check(true, label + " reaches natural endpoint", _array(position))
	return _check(false, label + " bounded movement timeout", moved)


func _input(label: String, movement: Vector2, mine: bool) -> void:
	events.append({"label": label, "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(), "relative_physics_tick": Engine.get_physics_frames() - capture_origin_tick, "movement": _array(movement), "mine": mine, "position": _array(player.global_position), "actual_source_pose": player.visual.presented_snapshot() if mode == "candidate" else {}})
	_append_jsonline("events.jsonl", events.back())
	main._set_mine_held(mine)
	main._on_joystick_movement(movement)


func _record(label: String) -> void:
	samples.append({"label": label, "process_frame": Engine.get_process_frames(), "physics_frame": Engine.get_physics_frames(), "relative_physics_tick": Engine.get_physics_frames() - capture_origin_tick, "simulation_seconds": capture_seconds, "engine_delta": root.get_process_delta_time(), "wall_ms": Time.get_ticks_msec(), "position": _array(player.global_position), "direction": player.direction_name, "mining_active": world.mining_active, "mining_elapsed": world.mining_elapsed, "mining_progress": player.mining_visual_progress, "swing_duration": world._swing_duration, "hit_progress": world.MINING_HIT_PROGRESS, "impact_serial": player._mining_impact_serial, "relative_impact_serial": int(player._mining_impact_serial) - initial_serial, "target": world.mining_target_id, "target_hp": int(world.resources[int(route.resource_index)].hp), "visual": player.visual.presented_snapshot() if mode == "candidate" else player.visual.tool_visual_snapshot()})


func _world_geometry() -> Dictionary:
	var layout: Array = []
	var hp: Array = []
	for resource in world.resources:
		layout.append([String(resource.id), _array(resource.position)])
		hp.append([String(resource.id), int(resource.hp), bool(resource.mined)])
	return {"generation_seed": world.generation_seed, "generation_signature": world.generation_signature, "floor_hash": hash(world.floor_cells), "dig_damage": str(world.dig_damage), "resource_layout": layout, "resource_hp": hp}


func _array(value: Vector2) -> Array:
	return [value.x, value.y]


func _vec(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


func _write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(output.path_join(name), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(value, "\t"))
		file.close()
	else: _check(false, "Write report " + name)


func _append_jsonline(name: String, value: Variant) -> void:
	var path := output.path_join(name)
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file == null:
		_check(false, "Append evidence " + name)
		return
	file.seek_end()
	file.store_line(JSON.stringify(value))
	file.close()


func _finish() -> void:
	if is_instance_valid(main):
		if mode == "candidate" and is_instance_valid(player): player.visual.disarm()
		main._set_mine_held(false)
		main._on_joystick_movement(Vector2.ZERO)
	_write_json("native-ingame.json", {"schema": 1, "passed": failures.is_empty(), "mode": mode, "source_sha": source_sha, "production_runtime_source": BASE_SOURCE, "fixture_sha256": FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/capture.gd"), "consumer_sha256": FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/pilot_visual.gd"), "consumer_installed": mode != "baseline", "consumer_armed": consumer_armed, "continue_framing_diagnostics": continue_framing_diagnostics, "asset_hashes": asset_hashes, "asset_root": asset_root, "rest_cycle": rest_cycle, "cancel_cycle": cancel_cycle, "engine": Engine.get_version_info().string, "display": DisplayServer.get_name(), "rendered": not captures.is_empty(), "viewport": [root.size.x, root.size.y], "content_scale_size": [root.content_scale_size.x, root.content_scale_size.y], "direction": direction_name, "seed": WORLD_SEED, "depth": depth, "route": route, "route_search": route_search, "startup_feedback": startup_feedback, "checks": checks, "failures": failures, "events": events, "samples": samples, "captures": captures, "transitions": player.visual.transitions if mode == "candidate" and is_instance_valid(player) else [], "replay_source_sha": replay.get("source_sha", ""), "replay_binding_reason": "Same actual DEV13-based source, consumer and bank checkpoint", "replay_sha256": FileAccess.get_sha256(replay_path) if not replay_path.is_empty() else "", "elapsed_wall_ms": Time.get_ticks_msec() - started_wall_ms, "manual_world_ticks": false, "manual_pose_playback": false, "visual_acceptance": false, "limits": "Headless geometry loads the consumer unarmed and is not visual evidence. Rendered cases, when present, are controlled fixed-step in-game input, not unrestricted live input, production adoption, all-direction/tool coverage or FPS evidence. Canonical endpoint quantization remains visible. Offset release is covered only in the rendered route; arbitrary interruptions are not covered."})
	print("NATIVE_INGAME_COMPLETE mode=", mode, " direction=", direction_name, " checks=", checks.size(), " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
