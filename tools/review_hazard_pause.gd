extends SceneTree
## Opt-in rendered regression: an actual Deep surge must pause with its journal.
## The fixture seeds the start of a complete telegraph, then only awaits normal
## process/physics frames. It never calls hazard, mining or physics ticks itself.
const TARGET_SIZE := Vector2i(1696, 780)
const SEED := 4608
const PAUSE_SECONDS := 0.5
const RESUME_MAX_PHYSICS_FRAMES := 120
const RESUME_MAX_WALL_MS := 20000
var output := ""
var pack_source := ""
var main: Node
var world: Node
var player: Node
var state: Node
var companion: Node
var fixture: Dictionary = {}
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var samples: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var events: Array[Dictionary] = []
var stage := "setup"
var armed := false
var pulse_seen := false
var recording := false
var pulse_position := Vector2.ZERO
var pulse_damage: Dictionary = {}
var pulse_clock := 0.0
var pulse_push := Vector2.ZERO
var maximum_paused_drift := 0.0
var observed_telegraph := false
var mining_seen_before_pulse := false
var observation_started_ms := 0
var resume_settlement: Dictionary = {}


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, name: String) -> bool:
	checks.append({"name": name, "passed": ok})
	if not ok:
		failures.append(name)
		# Keep collecting the failing baseline instead of triggering the runner's
		# immediate runtime-error stop before the report/screenshots are written.
		print("HAZARD_PAUSE_ASSERT_FAIL ", name)
	return ok


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless":
		print("HAZARD_PAUSE_USAGE requires a rendered display and absolute --output")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = TARGET_SIZE
	root.content_scale_size = TARGET_SIZE
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = SEED
	seed(SEED)
	if not _check(main._dev_jump_endless(1), "Enter original generated Deep"):
		_finish()
		return
	world = main.endless_world
	player = world.player
	companion = main.get_node("CompanionInterface")
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.endless_workshops["tool_forge"] = {"built": false, "level": 0}
	state.overhaul_progress = {}
	player.prepare_visual_cache()
	if not await _wait_for_gear():
		_finish()
		return
	fixture = _find_natural_fixture()
	if not _check(not fixture.is_empty(), "Natural hazard has a mineable wall and a clear outward push"):
		_finish()
		return
	world.restore_position(fixture.position)
	player.set_facing(fixture.facing)
	player.set_external_movement(Vector2.ZERO)
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main._refresh_hud()
	var hazard: Dictionary = world.resonance_hazards[int(fixture.hazard_index)]
	var cycle: float = float(fixture.cycle)
	# This is the beginning of the 1.35-second warning, not a pulse shortcut.
	world.hazard_clock = cycle * 10.0 + cycle - float(world.HAZARD_TELEGRAPH_DURATION) - float(hazard.phase_offset)
	world.resonance_surge_triggered.connect(_on_surge)
	process_frame.connect(_sample)
	observation_started_ms = Time.get_ticks_msec()
	recording = true
	armed = true
	stage = "telegraph_and_held_mining"
	main._set_mine_held(true)
	await _capture("01_telegraph_start")
	await create_timer(0.45).timeout
	await _capture("02_telegraph_progress")
	var pulse_deadline: int = Time.get_ticks_msec() + 20000
	while not pulse_seen and Time.get_ticks_msec() < pulse_deadline:
		await process_frame
	if not _check(pulse_seen, "Actual warning advances into an emitted surge"):
		_finish()
		return
	_check(observed_telegraph, "At least one ordinary frame shows a nonzero pre-pulse warning")
	_check(mining_seen_before_pulse, "Actual held mining runs before the surge")
	_check(companion.journal.is_open(), "Surge opens the actual companion journal")
	await _capture("03_pulse_journal_open")
	await create_timer(PAUSE_SECONDS).timeout
	await _capture("04_journal_after_pause")
	maximum_paused_drift = maxf(maximum_paused_drift, player.global_position.distance_to(pulse_position))
	_check(maximum_paused_drift <= 0.001, "Journal pauses the pending physical push")
	_check(is_equal_approx(float(world.hazard_clock), pulse_clock), "Journal pauses the hazard clock")
	_check(_damage_snapshot() == pulse_damage, "No wall or resource damage occurs behind the journal")
	_check(not world.mining_active and not world.external_mine_held, "Journal releases held mining")
	_check(Vector2(world.hazard_push_remaining).is_equal_approx(pulse_push), "Paused impulse remains available for normal resume")
	stage = "close_and_resume_push"
	companion.journal.close_journal()
	_check(not companion.journal.is_open(), "Actual journal close route completes")
	var resume_started_ms: int = Time.get_ticks_msec()
	var resume_started_physics: int = Engine.get_physics_frames()
	await create_timer(0.45).timeout
	# Preserve the old observation point. The .45-second timer is not a
	# gameplay settlement contract: an obstructed axis remains in the impulse
	# while the other axis slides along the real wall and approaches its cutoff.
	var original_resume_observation: Dictionary = _snapshot()
	original_resume_observation["event"] = "resume_original_450ms_observation"
	events.append(original_resume_observation)
	var resumed_settled: bool = await _wait_for_push_settlement(resume_started_ms, resume_started_physics)
	await _capture("05_push_resumed")
	_check(player.global_position.distance_to(pulse_position) >= 18.0, "Closing resumes the real outward displacement")
	_check(resumed_settled, "Resumed impulse settles within the bounded normal-physics wait")
	_check(world._position_walkable(player.global_position), "Resumed hero remains on clear floor")
	_check(not world.mining_active and not world.external_mine_held, "Closing does not restart a canceled hold")
	_check(_damage_snapshot() == pulse_damage, "Closing alone causes no new strike")
	if not resumed_settled:
		# Do not teleport an unconsumed impulse into the following mining case.
		_finish()
		return
	# Return to the same unedited wall and exercise a new real input hold.
	stage = "fresh_mining_after_close"
	world.restore_position(fixture.position)
	player.set_facing(fixture.facing)
	var damage_before: int = int(world.dig_damage.get(fixture.wall, 0))
	var impact_before: int = int(player._mining_impact_serial)
	main._set_mine_held(true)
	await create_timer(float(world._mining_cycle_duration()) * 0.8).timeout
	main._set_mine_held(false)
	_check(int(world.dig_damage.get(fixture.wall, 0)) > damage_before, "A fresh hold damages the same original wall")
	_check(int(player._mining_impact_serial) > impact_before, "A fresh hit reaches the real hero contact path")
	await create_timer(0.3).timeout
	await _capture("06_fresh_hit_recovered")
	_check(not world.mining_active and not player.visual._impact_pending, "Fresh release recovers without a pending contact")
	stage = "tunnel_home"
	var tunnel_started: bool = main.request_tunnel_home()
	_check(tunnel_started, "Actual Tunnel Home action starts")
	var travel_deadline: int = Time.get_ticks_msec() + 20000
	while main.phase == "endless" and Time.get_ticks_msec() < travel_deadline:
		await process_frame
	if not _check(main.phase == "hub", "Tunnel Home completes through the normal timer"):
		_finish()
		return
	await _capture("07_hub_return")
	_check(not world.active and int(player.visual.tool_visual_snapshot().textures_loaded) == 0, "Leaving releases inactive Deep hero textures")
	stage = "deep_reentry"
	main._enter_endless(true, false, false)
	_check(main.phase == "endless" and world.active, "Normal Deep entry reactivates the world")
	if not await _wait_for_gear():
		_finish()
		return
	await create_timer(0.3).timeout
	var reentry_damage: Dictionary = _damage_snapshot()
	var reentry_impacts: int = int(player._mining_impact_serial)
	await create_timer(0.35).timeout
	await _capture("08_deep_reentry_idle")
	_check(Vector2(world.hazard_push_remaining).is_zero_approx(), "Reentry has no leftover impulse")
	_check(not world.mining_active and not world.external_mine_held, "Reentry has no phantom held mining")
	_check(_damage_snapshot() == reentry_damage and int(player._mining_impact_serial) == reentry_impacts, "Reentry produces no phantom damage or impact")
	_check(player.visual.active_gear == "worn" and player.visual._last_state == "idle", "Reentry restores the approved Worn idle pose")
	_check(world._position_walkable(player.global_position), "Reentry places the hero on clear floor")
	_finish()


func _wait_for_gear() -> bool:
	var deadline: int = Time.get_ticks_msec() + 30000
	while player.visual.active_gear != "worn" and Time.get_ticks_msec() < deadline:
		await process_frame
	return _check(player.visual.active_gear == "worn", "Approved Worn atlas loads during normal processing")


func _wait_for_push_settlement(start_ms: int, start_physics: int) -> bool:
	while (
		Vector2(world.hazard_push_remaining).length() > 0.5
		and Engine.get_physics_frames() - start_physics < RESUME_MAX_PHYSICS_FRAMES
		and Time.get_ticks_msec() - start_ms < RESUME_MAX_WALL_MS
	):
		await physics_frame
	var settled: bool = Vector2(world.hazard_push_remaining).length() <= 0.5
	resume_settlement = {
		"settled": settled,
		"physics_frames": Engine.get_physics_frames() - start_physics,
		"maximum_physics_frames": RESUME_MAX_PHYSICS_FRAMES,
		"wall_ms": Time.get_ticks_msec() - start_ms,
		"maximum_wall_ms": RESUME_MAX_WALL_MS,
		"remaining_push": _xy(world.hazard_push_remaining),
		"position": _xy(player.global_position),
		"reason": "Wait for collision-constrained normal physics; do not assume an arbitrary .45-second timer consumes a blocked impulse.",
	}
	return settled


func _find_natural_fixture() -> Dictionary:
	var original_position: Vector2 = player.global_position
	var original_facing: Vector2 = player.facing_vector
	var found: Dictionary = {}
	for index in world.resonance_hazards.size():
		var hazard: Dictionary = world.resonance_hazards[index]
		if bool(hazard.disabled) or int(hazard.get("depth", 1)) != 1: continue
		var center: Vector2 = hazard.position
		for radius in [0.0, 32.0, 64.0, 88.0, 100.0]:
			for angle_index in (1 if radius == 0.0 else 16):
				var position: Vector2 = center + Vector2.from_angle(TAU * float(angle_index) / 16.0) * float(radius)
				if not world._position_walkable(position): continue
				player.global_position = position
				for facing in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
					player.set_facing(facing)
					if int(world._nearest_resource_index()) >= 0: continue
					var wall: Vector2i = world._nearest_diggable_wall()
					if wall.x < 0: continue
					var away: Vector2 = (position - center).normalized() if radius > 0.0 else -facing
					var projected: Vector2 = position
					for step in 16:
						projected = world._resolve_motion(projected, away * float(world.HAZARD_PUSH_DISTANCE) / 16.0)
					if projected.distance_to(position) < 40.0: continue
					found = {"hazard_index": index, "hazard_id": String(hazard.id), "position": position, "facing": facing, "wall": wall,
						"hazard_position": center, "cycle": float(world.HAZARD_CYCLE) * (0.72 if bool(hazard.empowered) else 1.0),
						"predicted_clear_displacement": projected.distance_to(position), "phase_offset": hazard.phase_offset}
					break
				if not found.is_empty(): break
			if not found.is_empty(): break
		if not found.is_empty(): break
	player.global_position = original_position
	player.set_facing(original_facing)
	return found


func _on_surge(hazard_id: String, depth: int) -> void:
	if not armed or hazard_id != String(fixture.hazard_id): return
	armed = false
	pulse_seen = true
	pulse_position = player.global_position
	pulse_damage = _damage_snapshot()
	pulse_clock = float(world.hazard_clock)
	pulse_push = world.hazard_push_remaining
	events.append({"event": "actual_resonance_surge", "hazard_id": hazard_id, "depth": depth, "frame": Engine.get_frames_drawn(),
		"position": _xy(pulse_position), "pending_push": _xy(pulse_push), "damage": pulse_damage, "mining_canceled": not world.mining_active})
	stage = "journal_paused"
	companion.open_skills()
	events.append({"event": "actual_companion_open", "frame": Engine.get_frames_drawn(), "open": companion.journal.is_open(),
		"world_process": world.is_processing(), "world_physics": world.is_physics_processing()})


func _sample() -> void:
	if not recording: return
	if stage == "journal_paused":
		maximum_paused_drift = maxf(maximum_paused_drift, player.global_position.distance_to(pulse_position))
	if armed:
		var cycle: float = float(fixture.cycle)
		var phase: float = fposmod(float(world.hazard_clock) + float(fixture.phase_offset), cycle)
		observed_telegraph = observed_telegraph or (phase > cycle - float(world.HAZARD_TELEGRAPH_DURATION) and phase < cycle)
		mining_seen_before_pulse = mining_seen_before_pulse or bool(world.mining_active)
	samples.append(_snapshot())


func _snapshot() -> Dictionary:
	return {"stage": stage, "wall_ms": Time.get_ticks_msec() - observation_started_ms,
		"frame": Engine.get_frames_drawn(), "physics_frame": Engine.get_physics_frames(), "phase": String(main.phase),
		"position": _xy(player.global_position), "hazard_clock": world.hazard_clock, "pending_push": _xy(world.hazard_push_remaining),
		"surges": world.hazard_surge_count, "world_active": world.active, "world_process": world.is_processing(),
		"world_physics": world.is_physics_processing(), "journal_open": companion.journal.is_open(),
		"mining": world.mining_active, "held": world.external_mine_held, "impact_serial": player._mining_impact_serial,
		"target_damage": int(world.dig_damage.get(fixture.wall, 0)), "pose": player.visual.tool_visual_snapshot()}


func _damage_snapshot() -> Dictionary:
	var walls: Dictionary = {}
	for cell in world.dig_damage: walls[str(cell)] = int(world.dig_damage[cell])
	var resources: Array[Dictionary] = []
	for resource in world.resources:
		resources.append({"id": String(resource.id), "hp": int(resource.hp), "mined": bool(resource.mined)})
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(PackedByteArray(world.floor_cells))
	return {"wall_damage": walls, "resource_damage_sha256": JSON.stringify(resources).sha256_text(), "floor_sha256": digest.finish().hex_encode()}


func _capture(id: String) -> void:
	await RenderingServer.frame_post_draw
	var rendered: Image = root.get_texture().get_image()
	_check(rendered.get_size() == TARGET_SIZE, "Exact framebuffer for " + id)
	var path: String = output.path_join(id + ".png")
	_check(rendered.save_png(path) == OK, "Save actual framebuffer " + id)
	var row: Dictionary = _snapshot()
	row["id"] = id
	row["path"] = path
	row["size"] = [rendered.get_width(), rendered.get_height()]
	row["sha256"] = FileAccess.get_sha256(path)
	captures.append(row)


func _xy(value: Vector2) -> Array:
	return [value.x, value.y]


func _finish() -> void:
	recording = false
	var source_hashes: Dictionary = {}
	for path in ["res://scripts/main.gd", "res://scripts/world/endless_descent_world.gd", "res://scripts/player/player_visual.gd", "res://tools/review_hazard_pause.gd"]:
		if FileAccess.file_exists(path): source_hashes[path] = FileAccess.get_sha256(path)
	var report := {"passed": failures.is_empty(), "failures": failures, "checks": checks, "fixture": fixture,
		"seed": SEED, "gear": "worn", "engine": Engine.get_version_info().string, "rendered": true,
		"manual_process_steps": false, "terrain_replaced": false, "physical_iphone": false, "fps_claim": false,
		"visual_acceptance_claim": false, "intended_viewport": [TARGET_SIZE.x, TARGET_SIZE.y],
		"source_sha256": source_hashes, "pack_sha256": FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else "",
		"maximum_paused_drift_px": maximum_paused_drift, "pause_seconds": PAUSE_SECONDS,
		"resume_settlement": resume_settlement,
		"events": events, "captures": captures, "samples": samples}
	var report_file := FileAccess.open(output.path_join("hazard-pause.json"), FileAccess.WRITE)
	if report_file == null:
		print("HAZARD_PAUSE_REPORT_WRITE_FAILED")
		quit(2)
		return
	report_file.store_string(JSON.stringify(report, "\t"))
	report_file.close()
	print("HAZARD_PAUSE_COMPLETE passed=%s failures=%d max_paused_drift=%.4f" % [str(failures.is_empty()), failures.size(), maximum_paused_drift])
	quit(0 if failures.is_empty() else 1)
