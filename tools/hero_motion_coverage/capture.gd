extends SceneTree
## Opt-in extension of review_hero_gameplay.gd: one approved gear/direction,
## untouched generated terrain, real held input, and observations after drawing.
## No production pose, mining tick, terrain, or hazard clock is substituted.
const Gear = preload("res://scripts/player/hero_gear.gd")
const SIZE := Vector2i(1696, 780)
const SEED := 4608
const DIRECTIONS := {"down": Vector2i.DOWN, "left": Vector2i.LEFT, "up": Vector2i.UP, "right": Vector2i.RIGHT}
const FRAME_LIMIT := 1200
const PNG_LIMIT := 360
var output := ""
var source_sha := ""
var pack_source := ""
var gear := ""
var direction_name := ""
var main: Node
var world: Node
var player: Node
var state: Node
var route: Dictionary = {}
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var stages: Array[Dictionary] = []
var events: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var stage := "setup"
var stage_frame := 0
var simulated_seconds := 0.0
var initial_serial := 0
var expected_serial := 0
var packed := false


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, name: String) -> bool:
	checks.append({"name": name, "passed": ok})
	if not ok:
		failures.append(name)
		print("HERO_COVERAGE_ASSERT_FAIL ", name)
	return ok


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--source-sha="): source_sha = arg.trim_prefix("--source-sha=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		elif arg.begins_with("--gear="): gear = arg.trim_prefix("--gear=")
		elif arg.begins_with("--direction="): direction_name = arg.trim_prefix("--direction=")
	packed = FileAccess.file_exists("res://project.binary")
	if not output.is_absolute_path() or gear not in Gear.TOOLS or not DIRECTIONS.has(direction_name) or source_sha.length() != 40 or DisplayServer.get_name() == "headless":
		print("HERO_COVERAGE_USAGE requires rendered display, absolute --output, --source-sha, approved --gear and --direction")
		quit(2)
		return
	if packed and (not pack_source.is_absolute_path() or not FileAccess.file_exists(pack_source)):
		print("HERO_COVERAGE_USAGE exported capture requires --pack-source")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = SIZE
	root.content_scale_size = SIZE
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = SEED
	seed(SEED)
	if not _check(main._dev_jump_endless(1), "Enter generated Deep with the normal world active"):
		_finish()
		return
	world = main.endless_world
	player = world.player
	_equip()
	var deadline: int = Time.get_ticks_msec() + 20000
	while String(player.visual.active_gear) != gear and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _check(String(player.visual.active_gear) == gear, "Requested approved production atlas loaded"):
		_finish()
		return
	var manifest: Dictionary = player.visual.get("_manifest")
	_check(String(manifest.get("source", "")) == "approved native Gruvepappa v28", "Approved v28 source retained")
	route = _find_route(DIRECTIONS[direction_name])
	if not _check(not route.is_empty(), "Natural first-band corridor supports the exact requested direction"):
		_finish()
		return
	world.restore_position(route.start)
	player.set_facing(Vector2(DIRECTIONS[direction_name]))
	player.control_enabled = true
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	main._refresh_hud()
	initial_serial = int(player._mining_impact_serial)
	expected_serial = initial_serial
	if not await _observe("idle", 0.2):
		_finish()
		return
	var direction: Vector2 = Vector2(DIRECTIONS[direction_name])
	var started: Vector2 = player.global_position
	_event("hold_mine_and_walk_toward_wall")
	main._set_mine_held(true)
	main._on_joystick_movement(direction)
	if not await _observe("walk_with_mine_held", 0.25):
		_finish()
		return
	_check(player.global_position.distance_to(started) >= 68.0, "Held mining retains at least 80 percent of the 340 px/s approach")
	_check(int(player._mining_impact_serial) == initial_serial, "Moving approach applies no strike")
	if not await _until("blocked_windup", "windup", 1.5):
		_finish()
		return
	_check(String(world.mining_target_id) == _target_id(), "Blocked input targets the original wall in the requested direction")
	if not _check(_before_hit(), "Release fixture reaches a visible pre-contact windup"):
		_finish()
		return
	var undamaged: Dictionary = _target_state()
	_event("release_before_contact")
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	if not await _observe("cancel_release", 0.35):
		_finish()
		return
	_check(int(player._mining_impact_serial) == initial_serial and _target_state() == undamaged, "Pre-contact release applies no impact or terrain damage")
	_check(String(player.visual.tool_visual_snapshot().state) == "idle", "Canceled anticipation settles to idle")
	main._set_mine_held(true)
	if not await _until("movement_cancel_windup", "windup", 0.9):
		_finish()
		return
	if not _check(_before_hit(), "Movement cancellation begins before mechanical contact"):
		_finish()
		return
	_event("move_away_during_anticipation")
	started = player.global_position
	main._on_joystick_movement(-direction)
	if not await _observe("cancel_by_movement", 0.25):
		_finish()
		return
	_check(player.global_position.distance_to(started) >= 68.0, "Mine-to-walk applies immediate body movement")
	_check(int(player._mining_impact_serial) == initial_serial and _target_state() == undamaged, "Mine-to-walk cancels the undelivered hit")
	_check(_moving_frames_walk("cancel_by_movement"), "Every observed moving cancellation frame uses locomotion")
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	if not await _observe("walk_stop", 0.3):
		_finish()
		return
	_check(String(player.visual.tool_visual_snapshot().state) == "idle", "Walk settles back to idle")
	_event("walk_back_to_original_contact")
	main._on_joystick_movement(direction)
	if not await _until("return_to_wall", "contact", 1.5):
		_finish()
		return
	main._on_joystick_movement(Vector2.ZERO)
	main._set_mine_held(true)
	expected_serial = initial_serial + 1
	if not await _until("impact_windup", "impact", 1.2):
		_finish()
		return
	_event("first_real_impact")
	_check(_target_state() != undamaged, "Actual impact damages or excavates the original wall")
	_check(int(player._mining_impact_serial) == expected_serial, "First contact produces exactly one impact event")
	var hit_pose: Dictionary = player.visual.tool_visual_snapshot()
	if String(manifest.family) == "pickaxe":
		var tolerance: float = 1.0 / float(manifest.states.mine.count) + 0.005
		_check(absf(float(hit_pose.native_phase) - float(manifest.native_impact)) <= tolerance, "Real presented impact uses the authored pickaxe contact sample")
	if not await _until("held_follow_through", "follow_through", 0.9):
		_finish()
		return
	_check(int(player._mining_impact_serial) == expected_serial, "Delivered swing follows through without a second strike")
	var delivered: Dictionary = _target_state()
	_event("release_after_delivered_contact")
	main._set_mine_held(false)
	if not await _observe("post_hit_release", 0.4):
		_finish()
		return
	_check(int(player._mining_impact_serial) == expected_serial and _target_state() == delivered, "Post-contact release cannot add damage")
	_check(String(player.visual.tool_visual_snapshot().state) == "idle", "Delivered-hit recovery returns to idle")
	_check(world.is_processing() and world.is_physics_processing() and player.is_physics_processing(), "World and player used normal processing throughout capture")
	_finish()


func _equip() -> void:
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.endless_workshops["tool_forge"] = {"built": false, "level": 0}
	match gear:
		"iron": state.pickaxe_level = 2
		"runed": state.pickaxe_level = 3
		"moonglass": state.pickaxe_level = 4
		"ember": state.pickaxe_level = 5
		"crusher": state.starforge_variant = "crusher"
		"comet": state.starforge_variant = "swift"
		"crown": state.starforge_variant = "prospector"
		"burrower": state.drill_level = 1
		"pulse": state.drill_level = 2
		"deepcore": state.drill_level = 3
	player.movement_speed = 340.0
	player.prepare_visual_cache()


func _find_route(direction: Vector2i) -> Dictionary:
	# Like the existing gameplay fixture, inspect generated cells. Do not erase
	# terrain, insert a high-HP test rock, or silently fall back to another facing.
	for y in range(2, 21):
		for x in range(3, 37):
			var wall := Vector2i(x, y)
			if world._is_floor(wall) or not world._cell_diggable(wall): continue
			var open := true
			for step in range(1, 17):
				var point: Vector2 = world._cell_center(wall) - Vector2(direction) * float(step) * 12.0
				if step < 4: continue
				if int(world.depth_at_position(point)) != 1 or world.collision_at(point):
					open = false
					break
				for hazard in world.resonance_hazards:
					if point.distance_to(Vector2(hazard.position)) <= float(hazard.radius) + 24.0:
						open = false
						break
			if not open: continue
			player.global_position = world._cell_center(wall - direction)
			player.set_facing(Vector2(direction))
			if world._nearest_diggable_wall() != wall or world._nearest_resource_index() >= 0: continue
			return {"wall": wall, "start": world._cell_center(wall - direction * 4), "direction": direction}
	return {}


func _target_id() -> String:
	return "wall:" + String(world._cell_key(route.wall))


func _target_state() -> Dictionary:
	return {"damage": int(world.dig_damage.get(route.wall, 0)), "excavated": bool(world._is_floor(route.wall))}


func _before_hit() -> bool:
	return bool(world.mining_active) and float(player.mining_visual_progress) < float(world.MINING_HIT_PROGRESS) and int(player._mining_impact_serial) == initial_serial


func _begin_stage(name: String) -> void:
	stage = name
	stage_frame = 0
	stages.append({"name": name, "start_sample": samples.size(), "simulated_seconds": simulated_seconds})
	print("HERO_COVERAGE_STAGE ", gear, " ", direction_name, " ", name)


func _observe(name: String, seconds: float) -> bool:
	_begin_stage(name)
	var end: float = simulated_seconds + seconds
	var deadline: int = Time.get_ticks_msec() + 20000
	while simulated_seconds < end and Time.get_ticks_msec() < deadline:
		if not await _frame(): return false
	return _check(simulated_seconds >= end, "Bounded observation completes: " + name)


func _until(name: String, condition: String, seconds: float) -> bool:
	_begin_stage(name)
	var end: float = simulated_seconds + seconds
	var deadline: int = Time.get_ticks_msec() + 20000
	while simulated_seconds < end and Time.get_ticks_msec() < deadline:
		if not await _frame(): return false
		match condition:
			"windup":
				if bool(world.mining_active) and float(player.mining_visual_progress) >= float(world.MINING_HIT_PROGRESS) * 0.45: return true
			"contact":
				if not player.is_actually_moving() and player.global_position.distance_to(Vector2(world._cell_center(route.wall))) < 64.0: return true
			"impact":
				if int(player._mining_impact_serial) >= expected_serial: return true
			"follow_through":
				if bool(world.mining_active) and float(player.mining_visual_progress) >= 0.78: return true
	return _check(false, "Bounded condition reached: " + name)


func _frame() -> bool:
	await RenderingServer.frame_post_draw
	if samples.size() >= FRAME_LIMIT:
		return _check(false, "Rendered sample budget exceeded")
	simulated_seconds += root.get_process_delta_time()
	var sample: Dictionary = _snapshot()
	sample["sample"] = samples.size()
	var dense: bool = stage in ["blocked_windup", "cancel_release", "movement_cancel_windup", "cancel_by_movement", "impact_windup", "held_follow_through", "post_hit_release"]
	if dense or stage_frame % 6 == 0:
		if captures.size() >= PNG_LIMIT:
			return _check(false, "Rendered PNG budget exceeded")
		var filename: String = "%04d_%s.png" % [samples.size(), stage]
		var frame_image: Image = root.get_texture().get_image()
		if frame_image.get_size() != SIZE:
			return _check(false, "Actual rendered frame differs from 1696x780")
		if frame_image.save_png(output.path_join(filename)) != OK:
			return _check(false, "Rendered frame could not be saved")
		sample["png"] = filename
		captures.append({"file": filename, "sample": samples.size(), "stage": stage, "drawn_frame": Engine.get_frames_drawn()})
	samples.append(sample)
	stage_frame += 1
	return true


func _snapshot() -> Dictionary:
	var pose: Dictionary = player.visual.tool_visual_snapshot().duplicate(true)
	return {"stage": stage, "simulated_seconds": simulated_seconds, "wall_ms": Time.get_ticks_msec(),
		"drawn_frame": Engine.get_frames_drawn(), "physics_frame": Engine.get_physics_frames(),
		"position": [player.global_position.x, player.global_position.y], "pose": pose,
		"moving": player.is_actually_moving(), "mining": world.mining_active,
		"mine_held": bool(main.mine_held), "movement_input": [player.external_movement.x, player.external_movement.y],
		"progress": player.mining_visual_progress, "impact_serial": int(player._mining_impact_serial),
		"target_id": String(world.mining_target_id), "target": _target_state(),
		"recover_phase": float(player.visual.get("_recover_phase")), "recover_direction": float(player.visual.get("_recover_direction"))}


func _event(name: String) -> void:
	var event: Dictionary = _snapshot()
	event["name"] = name
	event["after_sample"] = samples.size() - 1
	events.append(event)


func _moving_frames_walk(name: String) -> bool:
	var found := false
	for sample in samples:
		if String(sample.stage) == name and bool(sample.moving):
			found = true
			if String(sample.pose.state) != "walk" or bool(sample.mining): return false
	return found


func _finish() -> void:
	if is_instance_valid(main):
		main._set_mine_held(false)
		main._on_joystick_movement(Vector2.ZERO)
	var fixture: Dictionary = {}
	if not route.is_empty():
		fixture = {"seed": SEED, "depth": 1, "wall": [route.wall.x, route.wall.y], "start": [route.start.x, route.start.y], "direction": direction_name}
	var report := {"schema": 1, "passed": failures.is_empty(), "checks": checks, "failures": failures,
		"gear": gear, "direction": direction_name, "source_sha": source_sha,
		"packed": packed, "pack_sha256": FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else "",
		"engine": Engine.get_version_info().string, "display": DisplayServer.get_name(),
		"rendered": DisplayServer.get_name() != "headless", "actual_viewport": [root.size.x, root.size.y],
		"fixture": fixture, "stages": stages, "events": events, "samples": samples, "captures": captures,
		"manual_process_steps": false, "terrain_replaced": false, "fixed_movement_speed": 340.0,
		"visual_acceptance": false, "physical_iphone": false, "fps_claim": false,
		"limits": "One original first-band wall, miner outfit and 340 px/s. Fixed-step native capture is not browser, audio-output, device or FPS acceptance. Inspect the actual PNG sequences before accepting motion."}
	var file: FileAccess = FileAccess.open(output.path_join("hero-motion-coverage.json"), FileAccess.WRITE)
	if file == null:
		print("HERO_COVERAGE_REPORT_WRITE_FAILED")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("HERO_COVERAGE_COMPLETE failures=", failures.size(), " gear=", gear, " direction=", direction_name)
	quit(0 if failures.is_empty() else 1)
