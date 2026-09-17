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
const MIN_ROUTE_Y := 320.0
const FRAMING_MARGIN := 8.0
const STARTUP_SIMULATION_LIMIT := 110.0
const STARTUP_WALL_LIMIT_MSEC := 180000
var output := ""
var source_sha := ""
var pack_source := ""
var gear := ""
var direction_name := ""
var requested_wall := Vector2i(-1, -1)
var explicit_wall_requested := false
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
var all_frames := false
var capture_format := "png"
var critical_pngs: Array[Dictionary] = []
var framing_failures: Array[int] = []
var minimum_framing_clearance := 1000000.0
var startup_feedback: Dictionary = {}
var achievement_profile: Dictionary = {"used": false}
var profile_records_file := ""
var profile_records_sha := ""
var profile_provenance_sha := ""


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
		elif arg.begins_with("--natural-wall="):
			explicit_wall_requested = true
			var coordinates := arg.trim_prefix("--natural-wall=").split(",")
			if coordinates.size() == 2 and coordinates[0].is_valid_int() and coordinates[1].is_valid_int():
				requested_wall = Vector2i(int(coordinates[0]), int(coordinates[1]))
		elif arg == "--all-frames": all_frames = true
		elif arg.begins_with("--capture-format="): capture_format = arg.trim_prefix("--capture-format=")
		elif arg.begins_with("--achievement-profile-records="): profile_records_file = arg.trim_prefix("--achievement-profile-records=")
		elif arg.begins_with("--achievement-profile-sha256="): profile_records_sha = arg.trim_prefix("--achievement-profile-sha256=")
		elif arg.begins_with("--achievement-provenance-sha256="): profile_provenance_sha = arg.trim_prefix("--achievement-provenance-sha256=")
	if capture_format == "rgba8": all_frames = true
	if explicit_wall_requested and (direction_name != "up" or requested_wall.x < 3 or requested_wall.x >= 37 or requested_wall.y < 2 or requested_wall.y >= 21):
		print("HERO_COVERAGE_USAGE --natural-wall requires an explicit up candidate within the ordinary route search")
		quit(2)
		return
	packed = FileAccess.file_exists("res://project.binary")
	if capture_format not in ["png", "rgba8"] or not output.is_absolute_path() or gear not in Gear.TOOLS or not DIRECTIONS.has(direction_name) or source_sha.length() != 40 or DisplayServer.get_name() == "headless":
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
	if not _verify_loaded_achievement_profile():
		_finish()
		return
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	call("_companion_prepare_main", main)
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
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	main._refresh_hud()
	if not await _settle_startup_feedback():
		_finish()
		return
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


func _verify_loaded_achievement_profile() -> bool:
	if profile_records_file.is_empty() and profile_records_sha.is_empty() and profile_provenance_sha.is_empty(): return true
	# The runner stages the unmodified earned save before engine startup. Read
	# the normal autoload's result; do not assign records or invoke its loader.
	var service = root.get_node("AchievementService")
	var storage_path: String = service._storage_path()
	var expected: Dictionary = {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(profile_records_file)) if FileAccess.file_exists(profile_records_file) else null
	if parsed is Dictionary and parsed.get("records") is Dictionary:
		for id in parsed.records: expected[String(id)] = int(parsed.records[id])
	var storage_sha: String = FileAccess.get_sha256(storage_path) if FileAccess.file_exists(storage_path) else ""
	var verified: bool = profile_records_file.is_absolute_path() and profile_records_sha.length() == 64 and profile_provenance_sha.length() == 64 and not expected.is_empty() and FileAccess.get_sha256(profile_records_file) == profile_records_sha and storage_path == "user://ever_deeper_dev_achievements_v2.json" and storage_sha == profile_records_sha and service.records == expected
	achievement_profile = {"used": true, "load_verified": verified, "records_source_file": profile_records_file,
		"profile_sha256": profile_records_sha, "provenance_sha256": profile_provenance_sha,
		"storage_user_path": storage_path, "loaded_storage_sha256": storage_sha,
		"loaded_records": service.records.duplicate(true), "loaded_record_count": service.records.size(),
		"loaded_wall_ms": Time.get_ticks_msec(), "checked_before_main_instantiation": true,
		"manual_record_assignment_or_loading": false}
	return _check(verified, "Normally earned achievement starting profile loads with exact records and file identity")


func _settle_startup_feedback() -> bool:
	# DEV entry seeds progression before its batched achievement evaluation.
	# Observe the ordinary queue/lifetimes; never award, clear or dismiss a toast.
	var service = root.get_node("AchievementService")
	var evaluation_seconds: float = float(service.EVALUATION_BATCH_SECONDS)
	var quiet_required: float = maxf(0.5, evaluation_seconds * 2.0)
	var started_ms: int = Time.get_ticks_msec()
	var elapsed := 0.0
	var quiet := 0.0
	var last_recorded := -1.0
	var previous_signature := ""
	startup_feedback = {"passed": false, "phase": "settling", "started_wall_ms": started_ms,
		"simulation_limit_seconds": STARTUP_SIMULATION_LIMIT, "wall_limit_seconds": STARTUP_WALL_LIMIT_MSEC / 1000.0,
		"evaluation_batch_seconds": evaluation_seconds, "quiet_required_seconds": quiet_required,
		"toast_spin_seconds": main.achievement_toast.SPIN_SECONDS, "toast_hold_seconds": main.achievement_toast.HOLD_SECONDS,
		"toast_fade_seconds": main.achievement_toast.FADE_SECONDS,
		"feedback_forcibly_cleared": false, "manual_evaluation_or_clock_steps": false,
		"observation_origin": "frame_post_draw_state_only", "rendered_frames_observed": 0,
		"timeline_scope": "Startup diagnostics precede and are excluded from the measured motion movie.", "observations": []}
	if not _write_startup_feedback(): return false
	while elapsed < STARTUP_SIMULATION_LIMIT and Time.get_ticks_msec() - started_ms < STARTUP_WALL_LIMIT_MSEC:
		await RenderingServer.frame_post_draw
		var delta: float = root.get_process_delta_time()
		elapsed += delta
		var toast: Dictionary = main.achievement_toast.debug_snapshot()
		var content: Control = main.achievement_toast.get("_toast") as Control
		var visible: bool = content != null and content.is_visible_in_tree()
		var pickup: Node = player.get_node_or_null("ResourcePickupBurst")
		var pickup_entries: Array = []
		if pickup != null:
			for entry in pickup.entries:
				pickup_entries.append({"kind": String(entry.kind), "amount": int(entry.amount), "age": float(entry.age)})
		var busy: bool = bool(service.evaluation_pending) or int(state.get("_state_batch_depth")) > 0 or bool(state.get("_state_batch_dirty")) or bool(main.hud_refresh_pending) or bool(toast.active) or int(toast.queue_size) > 0 or visible or not pickup_entries.is_empty()
		quiet = 0.0 if busy else quiet + delta
		var snapshot := {"wall_ms": Time.get_ticks_msec(), "elapsed_wall_seconds": (Time.get_ticks_msec() - started_ms) / 1000.0,
			"elapsed_simulation_seconds": elapsed, "quiet_seconds": quiet, "drawn_frame": Engine.get_frames_drawn(),
			"physics_frame": Engine.get_physics_frames(), "evaluation_pending": bool(service.evaluation_pending),
			"state_batch_depth": int(state.get("_state_batch_depth")), "state_batch_dirty": bool(state.get("_state_batch_dirty")),
			"hud_refresh_pending": bool(main.hud_refresh_pending), "unlocked_count": service.unlocked_count(),
			"toast_active": bool(toast.active), "toast_visible": visible, "active_id": String(toast.active_id),
			"phase": String(toast.phase), "phase_elapsed": float(toast.phase_elapsed), "queue_size": int(toast.queue_size),
			"queued_ids": toast.queued_ids, "toast_rect": _rect_array(Rect2(toast.toast_rect)), "pickups": pickup_entries}
		startup_feedback["rendered_frames_observed"] += 1
		startup_feedback["last_snapshot"] = snapshot
		var signature: String = str([snapshot.evaluation_pending, snapshot.state_batch_depth, snapshot.state_batch_dirty,
			snapshot.hud_refresh_pending, snapshot.unlocked_count, snapshot.toast_active, snapshot.toast_visible,
			snapshot.active_id, snapshot.phase, snapshot.queued_ids, pickup_entries.size(), busy])
		if signature != previous_signature or elapsed - last_recorded >= 1.0 or quiet >= quiet_required:
			startup_feedback.observations.append(snapshot)
			previous_signature = signature
			last_recorded = elapsed
			if not _write_startup_feedback(): return false
		if quiet >= quiet_required:
			startup_feedback["passed"] = true
			startup_feedback["phase"] = "settled"
			startup_feedback["completed_wall_ms"] = Time.get_ticks_msec()
			if not _write_startup_feedback(): return false
			return _check(true, "Startup feedback naturally drains and remains quiet before measured motion")
	startup_feedback["phase"] = "timeout"
	startup_feedback["completed_wall_ms"] = Time.get_ticks_msec()
	_write_startup_feedback()
	return _check(false, "Startup feedback naturally drains and remains quiet before measured motion")


func _write_startup_feedback() -> bool:
	var file: FileAccess = FileAccess.open(output.path_join("startup-feedback.json"), FileAccess.WRITE)
	if file == null: return _check(false, "Startup feedback diagnostics could not be written")
	file.store_string(JSON.stringify(startup_feedback, "\t"))
	file.flush()
	var ok: bool = file.get_error() == OK
	file.close()
	return ok or _check(false, "Startup feedback diagnostics could not be written")


func _find_route(direction: Vector2i) -> Dictionary:
	# Like the existing gameplay fixture, inspect generated cells. Do not erase
	# terrain, insert a high-HP test rock, or silently fall back to another facing.
	for y in range(2, 21):
		for x in range(3, 37):
			var wall := Vector2i(x, y)
			# An opt-in candidate still passes every original natural-route rule.
			# No fallback: an obstructed or changed requested route fails setup.
			if explicit_wall_requested and wall != requested_wall: continue
			if world._is_floor(wall) or not world._cell_diggable(wall): continue
			var contact: Vector2 = world._cell_center(wall - direction)
			var start: Vector2 = world._cell_center(wall - direction * 4)
			var target: Vector2 = world._cell_center(wall)
			if minf(target.y, minf(contact.y, start.y)) < MIN_ROUTE_Y: continue
			var segments: int = maxi(1, ceili(contact.distance_to(start) / 12.0))
			var open := true
			# Include both actual cell centers: 64px contact through 256px start
			# on today's terrain, with no unchecked gap larger than 12px.
			for step in range(segments + 1):
				var point: Vector2 = contact.lerp(start, float(step) / float(segments))
				if int(world.depth_at_position(point)) != 1 or world.collision_at(point):
					open = false
					break
				for hazard in world.resonance_hazards:
					if point.distance_to(Vector2(hazard.position)) <= float(hazard.radius) + 24.0:
						open = false
						break
			if not open: continue
			player.global_position = contact
			player.set_facing(Vector2(direction))
			if world._nearest_diggable_wall() != wall or world._nearest_resource_index() >= 0: continue
			return {"wall": wall, "start": start, "direction": direction}
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
	var framing: Dictionary = _framing_snapshot()
	sample["framing"] = framing
	minimum_framing_clearance = minf(minimum_framing_clearance, float(framing.minimum_axis_clearance_px))
	if not bool(framing.passed): framing_failures.append(samples.size())
	var dense: bool = stage in ["blocked_windup", "cancel_release", "movement_cancel_windup", "cancel_by_movement", "impact_windup", "held_follow_through", "post_hit_release"]
	if all_frames or dense or stage_frame % 6 == 0 or not bool(framing.passed):
		if captures.size() >= PNG_LIMIT:
			return _check(false, "Rendered PNG budget exceeded")
		var frame_image: Image = root.get_texture().get_image()
		if frame_image.get_size() != SIZE:
			return _check(false, "Actual rendered frame differs from 1696x780")
		if capture_format == "rgba8":
			if frame_image.has_mipmaps():
				return _check(false, "Raw capture unexpectedly contains mipmaps")
			var original_format: int = frame_image.get_format()
			frame_image.convert(Image.FORMAT_RGBA8)
			var pixels: PackedByteArray = frame_image.get_data()
			var expected_bytes: int = SIZE.x * SIZE.y * 4
			if pixels.size() != expected_bytes:
				return _check(false, "Raw RGBA8 frame byte count differs from declared dimensions")
			var filename: String = "%04d_%s.rgba" % [samples.size(), stage]
			var raw_file: FileAccess = FileAccess.open(output.path_join(filename), FileAccess.WRITE)
			if raw_file == null:
				return _check(false, "Raw rendered frame could not be opened")
			raw_file.store_buffer(pixels)
			raw_file.flush()
			var stored_ok: bool = raw_file.get_error() == OK and raw_file.get_length() == expected_bytes
			raw_file.close()
			if not stored_ok:
				return _check(false, "Raw rendered frame could not be saved completely")
			sample["raw_frame"] = filename
			captures.append({"file": filename, "sample": samples.size(), "stage": stage,
				"drawn_frame": Engine.get_frames_drawn(), "format": "rgba8", "width": SIZE.x,
				"height": SIZE.y, "byte_count": expected_bytes, "row_stride_bytes": SIZE.x * 4,
				"row_order": "top_to_bottom", "channel_order": "RGBA", "origin": "godot_frame_post_draw",
				"godot_image_format_before": original_format, "converted_to_rgba8": original_format != Image.FORMAT_RGBA8})
		else:
			var filename: String = "%04d_%s.png" % [samples.size(), stage]
			if frame_image.save_png(output.path_join(filename)) != OK:
				return _check(false, "Rendered frame could not be saved")
			sample["png"] = filename
			captures.append({"file": filename, "sample": samples.size(), "stage": stage, "drawn_frame": Engine.get_frames_drawn()})
	samples.append(sample)
	stage_frame += 1
	return true


func _save_raw_critical_pngs() -> bool:
	# Encode only the event boundaries and recovery endpoints. Every source byte
	# comes from the stored post-draw RGBA8 frame, never a later viewport readback.
	var selected: Dictionary = {}
	var names: Array[String] = ["release_before_contact", "move_away_during_anticipation", "first_real_impact", "release_after_delivered_contact"]
	for event in events:
		if String(event.name) not in names: continue
		var before: int = int(event.after_sample)
		if before >= 0 and before < captures.size(): selected[before] = true
		if before + 1 < captures.size(): selected[before + 1] = true
	for name in ["cancel_release", "walk_stop", "post_hit_release"]:
		var last := -1
		for capture in captures:
			if String(capture.stage) == name: last = int(capture.sample)
		if last >= 0: selected[last] = true
	for capture in captures:
		if not selected.has(int(capture.sample)): continue
		var raw_path: String = output.path_join(String(capture.file))
		var pixels: PackedByteArray = FileAccess.get_file_as_bytes(raw_path)
		if pixels.size() != SIZE.x * SIZE.y * 4:
			return _check(false, "Critical stored RGBA8 frame is incomplete")
		var frame_image: Image = Image.create_from_data(SIZE.x, SIZE.y, false, Image.FORMAT_RGBA8, pixels)
		var filename: String = String(capture.file).get_basename() + ".png"
		if frame_image.save_png(output.path_join(filename)) != OK:
			return _check(false, "Critical native PNG could not be encoded from its stored frame")
		critical_pngs.append({"file": filename, "sample": capture.sample,
			"origin": "godot_png_from_stored_rgba8", "generated_from_raw": true,
			"source_raw_file": capture.file, "source_raw_sha256": FileAccess.get_sha256(raw_path),
			"png_sha256": FileAccess.get_sha256(output.path_join(filename))})
	return true


func _framing_snapshot() -> Dictionary:
	# A conservative full sprite-cell rectangle includes both the native body
	# and tool; their pixels share one atlas and cannot be independently hidden.
	var subjects: Dictionary = {}
	for child in player.visual.get_children():
		if child is Sprite2D and child.texture != null and child.is_visible_in_tree():
			subjects["hero_and_tool"] = child.get_global_transform_with_canvas() * child.get_rect()
	var target_world: Rect2 = Rect2(Vector2(world._cell_center(route.wall)) - Vector2.ONE * float(world.TILE_SIZE) * 0.5, Vector2.ONE * float(world.TILE_SIZE))
	subjects["target_cell"] = world.get_global_transform_with_canvas() * target_world
	var overlays: Dictionary = {}
	var controls: Array = [main.mine_button]
	var hud: Node = main.premium_hud
	controls.append_array([hud.menu_button, hud.guide_button, hud.gold_cluster,
		hud.bag_button, hud.context_button, hud.progression_goal_panel, hud.objective_chip, hud.status_panel])
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
	if main.achievement_toast != null and main.achievement_toast.is_presenting():
		overlays["achievement"] = main.achievement_toast.get_global_transform_with_canvas() * Rect2(main.achievement_toast.debug_snapshot().toast_rect)
	var pickup: Node = player.get_node_or_null("ResourcePickupBurst")
	if pickup != null:
		var index := 0
		for rect in pickup.screen_rects():
			overlays["pickup_%d" % index] = rect
			index += 1
	var viewport: Rect2 = root.get_visible_rect()
	var violations: Array[Dictionary] = []
	var minimum := 1000000.0
	if not subjects.has("hero_and_tool"):
		violations.append({"subject": "hero_and_tool", "obstruction": "missing_sprite"})
	for key in subjects:
		var rect: Rect2 = subjects[key]
		var viewport_gap: float = minf(minf(rect.position.x - viewport.position.x, rect.position.y - viewport.position.y), minf(viewport.end.x - rect.end.x, viewport.end.y - rect.end.y))
		minimum = minf(minimum, viewport_gap)
		if viewport_gap < FRAMING_MARGIN:
			violations.append({"subject": key, "obstruction": "viewport", "axis_clearance_px": viewport_gap})
		for overlay in overlays:
			var gap: float = _rect_axis_gap(rect, overlays[overlay])
			minimum = minf(minimum, gap)
			if gap < FRAMING_MARGIN:
				violations.append({"subject": key, "obstruction": overlay, "axis_clearance_px": gap})
	var serialized_subjects: Dictionary = {}
	var serialized_overlays: Dictionary = {}
	for key in subjects: serialized_subjects[key] = _rect_array(subjects[key])
	for key in overlays: serialized_overlays[key] = _rect_array(overlays[key])
	return {"passed": violations.is_empty(), "required_margin_px": FRAMING_MARGIN,
		"minimum_axis_clearance_px": minimum, "subjects": serialized_subjects,
		"overlays": serialized_overlays, "violations": violations}


func _rect_axis_gap(first: Rect2, second: Rect2) -> float:
	return maxf(maxf(first.position.x - second.end.x, second.position.x - first.end.x), maxf(first.position.y - second.end.y, second.position.y - first.end.y))


func _rect_array(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


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
	if capture_format == "rgba8": _save_raw_critical_pngs()
	var fixture: Dictionary = {}
	if not route.is_empty():
		fixture = {"seed": SEED, "depth": 1, "wall": [route.wall.x, route.wall.y], "start": [route.start.x, route.start.y], "direction": direction_name}
	fixture["selection"] = "explicit_natural_wall" if explicit_wall_requested else "first_valid_natural_wall"
	fixture["requested_wall"] = [requested_wall.x, requested_wall.y] if explicit_wall_requested else []
	_check(not samples.is_empty() and framing_failures.is_empty(), "Hero/tool and target retain declared viewport/HUD clearance in every observed frame")
	var report := {"schema": 1, "passed": failures.is_empty(), "checks": checks, "failures": failures,
		"gear": gear, "direction": direction_name, "source_sha": source_sha,
		"packed": packed, "pack_sha256": FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else "",
		"engine": Engine.get_version_info().string, "display": DisplayServer.get_name(),
		"rendered": DisplayServer.get_name() != "headless", "actual_viewport": [root.size.x, root.size.y],
		"fixture": fixture, "achievement_profile": achievement_profile, "startup_feedback": startup_feedback, "stages": stages, "events": events, "samples": samples, "captures": captures,
		"capture_format": capture_format, "capture_origin": "godot_frame_post_draw", "critical_pngs": critical_pngs,
		"all_frames_requested": all_frames, "all_observed_frames_captured": captures.size() == samples.size(),
		"framing": {"passed": not samples.is_empty() and framing_failures.is_empty(),
			"required_margin_px": FRAMING_MARGIN, "minimum_axis_clearance_px": minimum_framing_clearance,
			"failed_samples": framing_failures, "contract": "Entire combined hero/tool sprite cell and target tile inside viewport, at least 8 px clear of current named HUD/minimap/achievement/pickup bounds. Natural-world occlusion still requires image review."},
		"manual_process_steps": false, "terrain_replaced": false, "fixed_movement_speed": 340.0,
		"visual_acceptance": false, "physical_iphone": false, "fps_claim": false,
		"limits": "One original first-band wall, miner outfit and 340 px/s. Fixed-step native capture is not browser, audio-output, device or FPS acceptance. Inspect the actual PNG sequences before accepting motion."}
	report["companion_comparison"] = call("_companion_report")
	var file: FileAccess = FileAccess.open(output.path_join("hero-motion-coverage.json"), FileAccess.WRITE)
	if file == null:
		print("HERO_COVERAGE_REPORT_WRITE_FAILED")
		quit(2)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("HERO_COVERAGE_COMPLETE failures=", failures.size(), " gear=", gear, " direction=", direction_name)
	quit(0 if failures.is_empty() else 1)
