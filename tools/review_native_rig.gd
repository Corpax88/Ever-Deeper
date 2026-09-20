extends SceneTree
## Isolated native-derived runtime feasibility gates. Production remains intact.
const NativeRig = preload("res://tools/hero_v28/runtime_pilot/native_rig.gd")
var candidate: String
var output: String
var mode: String = "poses"
var material_view: String = "baked"
var clip_range: Vector2 = Vector2(.01, 100.0)
var import_flags: int = 0
var raster_size: int = 200
var shadow_diagnostic: bool = false
var lighting_profile: String = "legacy"
var main: Node
var world: Node
var player: Node
var rig: Node2D
var phase_clock: float = 0.0
var wanted: String = "idle"
var recording: bool = false
var rig_enabled: bool = true
var samples: Array[Dictionary] = []
var stages: Array[Dictionary] = []
var failures: Array[String] = []
var stage: String = "prepare"
var cost_seconds: float = 20.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--candidate="): candidate = arg.trim_prefix("--candidate=")
		elif arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
		elif arg.begins_with("--material-view="): material_view = arg.trim_prefix("--material-view=")
		elif arg.begins_with("--import-flags="): import_flags = int(arg.trim_prefix("--import-flags="))
		elif arg.begins_with("--raster-size="): raster_size = int(arg.trim_prefix("--raster-size="))
		elif arg == "--shadow-diagnostic": shadow_diagnostic = true
		elif arg.begins_with("--lighting-profile="): lighting_profile = arg.trim_prefix("--lighting-profile=")
		elif arg.begins_with("--clip-range="):
			var values: PackedStringArray = arg.trim_prefix("--clip-range=").split(",")
			if values.size() != 2:
				quit(2)
				return
			clip_range = Vector2(float(values[0]), float(values[1]))
		elif arg.begins_with("--cost-seconds="): cost_seconds = maxf(5.0, float(arg.trim_prefix("--cost-seconds=")))
	if not candidate.is_absolute_path() or not output.is_absolute_path() or mode not in ["poses", "motion", "cost"]:
		push_error("Require absolute native --candidate/--output and poses|motion|cost --mode")
		quit(2)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Native rig acceptance requires rendered frames")
		quit(2)
		return
	if mode == "cost" and "--write-movie" in OS.get_cmdline_args():
		push_error("A movie cannot measure runtime cost")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1696, 780)
	if mode != "poses" and not await _enter_hub():
		quit(3)
		return
	rig = NativeRig.new()
	if (material_view != "baked" or clip_range != Vector2(.01, 100.0) or import_flags != 0 or raster_size != 200 or shadow_diagnostic or lighting_profile != "legacy") and mode != "poses":
		push_error("Material diagnostics require isolated poses")
		quit(3)
		return
	rig.material_view = material_view
	rig.clip_range = clip_range
	rig.import_flags = import_flags
	rig.raster_size = raster_size
	rig.shadow_diagnostic = shadow_diagnostic
	rig.lighting_profile = lighting_profile
	if mode == "poses": root.add_child(rig)
	else: player.visual.add_child(rig)
	if not rig.configure(candidate):
		push_error("Cannot load native-derived runtime candidate")
		quit(3)
		return
	if bool(rig.data.get("reference_only", false)) and mode != "poses":
		push_error("Reference-only Flow20 payload cannot exercise the legacy motion solver")
		quit(3)
		return
	if mode == "poses":
		await _reference_poses()
	else:
		player.visual._sprite.hide()
		player.visual.set_process(false)
		rig.reset_motion(player.global_position)
		process_frame.connect(_motion_frame)
		if mode == "motion": await _motion_cases()
		else: await _cost_cases()
	_finish()


func _enter_hub() -> bool:
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state() or not main._dev_jump_hub(): return false
	world = main.hub_world
	player = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	player.prepare_visual_cache()
	var deadline: int = Time.get_ticks_msec() + 20000
	while player.visual.active_gear != "worn" and Time.get_ticks_msec() < deadline:
		player.visual._poll_equipment()
		await process_frame
	if player.visual.active_gear != "worn": return false
	world.restore_position(Vector2(360, 448))
	player.movement_speed = 260.0
	player.control_enabled = true
	player.set_facing(Vector2.RIGHT)
	main.achievement_toast.clear()
	main.achievement_toast.hide()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	main._refresh_hud()
	return true


func _reference_poses() -> void:
	for specimen in Array(rig.data.reference_poses):
		var id: String = "%s_%06d" % [String(specimen.state), roundi(float(specimen.phase)*1000000)]
		rig.set_reference_pose(String(specimen.state), float(specimen.phase))
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = rig.viewport.get_texture().get_image()
		if raster_size != 200:
			picture.save_png(output.path_join(id + "-raw.png"))
			picture.resize(200, 200, Image.INTERPOLATE_LANCZOS)
		picture.save_png(output.path_join(id + ".png"))
		var pose_error: float = rig.reference_pose_error()
		if pose_error > .00001: failures.append("Imported skeleton differs from native pose: " + id)
		stages.append({"id": id, "state": specimen.state, "phase": specimen.phase,
			"size": [picture.get_width(), picture.get_height()],
			"clip_range": [clip_range.x, clip_range.y], "material_view": material_view,
			"import_flags": import_flags, "surface_formats": rig.surface_formats,
			"raw_raster_size": raster_size, "shadow_diagnostic": shadow_diagnostic,
			"lighting_profile": lighting_profile,
			"resampling": "none" if raster_size == 200 else "400px raw retained; Lanczos to 200px for comparison",
			"native_pose_error": pose_error,
			"source": "exact native pose; derived geometry; " + material_view + " material"})
		print("NATIVE_RIG_REFERENCE ", id)


func _motion_cases() -> void:
	recording = true
	await _stage("initial_idle", "idle", .25)
	for index in 8:
		# Eight distinct requested exits, plus another intent inside an unfinished
		# 85 ms blend. No source phase bank is selected or approximated.
		var target_phase: float = float(index)/8.0
		var duration: float = fposmod(target_phase-float(rig.data.flat_entry_phase), 1.0)*88.0/260.0
		await _stage("walk_exit_%d" % index, "walk", maxf(.025, duration))
		await _stage("mine_entry_%d" % index, "mine", .68*(.1+.105*float(index)))
		await _stage("interrupt_run_%d" % index, "walk", .034)
		await _stage("interrupt_idle_%d" % index, "idle", .034)
		await _stage("interrupt_mine_%d" % index, "mine", .034)
	await _stage("final_walk", "walk", .25)
	await _stage("final_idle", "idle", .25)
	recording = false
	main._on_joystick_movement(Vector2.ZERO)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("motion-final.png"))
	var detail: Dictionary = rig.snapshot()
	if float(detail.unreachable_max) > .0001: failures.append("Native limb reach violated during interrupted motion")
	if float(detail.reach_correction_max) > .035: failures.append("Contact preservation requires excessive pelvis correction")
	stages.append({"id": "motion_summary", "detail": detail})


func _stage(id: String, next: String, seconds: float) -> void:
	stage = id
	wanted = next
	if wanted == "mine": phase_clock = 0.0
	main._on_joystick_movement(Vector2.RIGHT if wanted == "walk" else Vector2.ZERO)
	stages.append({"id": id, "state": next, "seconds": seconds, "start": rig.snapshot()})
	await create_timer(seconds).timeout
	print("NATIVE_RIG_STAGE ", id)


func _motion_frame() -> void:
	if player == null: return
	var delta: float = root.get_process_delta_time()
	var moving: bool = player.is_actually_moving()
	var actual: String = "walk" if moving else wanted if wanted != "walk" else "idle"
	if actual == "mine": phase_clock += delta
	var progress: float = fposmod(phase_clock/.68, 1.0)
	player.set_mining_visual(actual == "mine", progress, 0.0, .42)
	if rig_enabled: rig.advance(delta, player.global_position, actual, progress, .68, .42)
	if recording:
		samples.append({"stage": stage, "frame": Engine.get_frames_drawn(), "delta": delta,
			"position": [player.global_position.x, player.global_position.y], "moving": moving,
			"pose": rig.snapshot()})


func _cost_cases() -> void:
	# Same stationary, animated Worn fixture and real hub, with the candidate
	# resident throughout. This isolates its incremental rendering/pose cost.
	# It is not a sustained complete-game or physical-device performance gate.
	wanted = "mine"
	main._on_joystick_movement(Vector2.ZERO)
	for label in ["atlas_before", "native_rig", "atlas_after"]:
		rig_enabled = label == "native_rig"
		rig.sprite.visible = rig_enabled
		rig.viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if rig_enabled else SubViewport.UPDATE_DISABLED
		player.visual._sprite.visible = not rig_enabled
		player.visual.set_process(not rig_enabled)
		if rig_enabled: rig.reset_motion(player.global_position)
		await create_timer(2.0).timeout
		var start: int = Time.get_ticks_usec()
		var previous: int = start
		var durations: Array[float] = []
		var draws: Array[float] = []
		while float(Time.get_ticks_usec()-start)/1000000.0 < cost_seconds:
			await process_frame
			var now: int = Time.get_ticks_usec()
			durations.append(float(now-previous)/1000.0)
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			previous = now
		var total: float = 0.0
		for value in durations: total += value
		durations.sort()
		draws.sort()
		var detail: Dictionary = {"id": label, "frames": durations.size(), "seconds": total/1000.0,
			"average_fps": 1000.0*float(durations.size())/total,
			"p95_ms": durations[mini(durations.size()-1, floori(.95*durations.size()))],
			"draws_p95": draws[mini(draws.size()-1, floori(.95*draws.size()))],
			"static_mib": Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,
			"video_mib": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0}
		stages.append(detail)
		print("NATIVE_RIG_COST ", JSON.stringify(detail))


func _finish() -> void:
	var source: Dictionary = {}
	for path in ["tools/review_native_rig.gd", "tools/hero_v28/runtime_pilot/native_rig.gd", "scripts/player/player_controller.gd", "scripts/world/hub_world.gd"]:
		source[path] = FileAccess.get_sha256("res://" + path)
	FileAccess.open(output.path_join("native-rig-review.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"mode": mode, "passed": failures.is_empty(), "failures": failures, "stages": stages, "samples": samples,
		"material_view": material_view, "material_diagnostic": material_view != "baked",
		"rendered": true, "production_changed": false, "physical_iphone": false,
		"direction": String(rig.data.direction), "action": String(rig.data.get("action", "legacy_native")),
		"reference_only": bool(rig.data.get("reference_only", false)), "candidate_files_verified": true,
		"source_sha256": source, "candidate_sha256": FileAccess.get_sha256(candidate.path_join("candidate.json")),
		"renderer": RenderingServer.get_video_adapter_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"runtime": Engine.get_version_info(), "viewport": [root.size.x, root.size.y], "actor_target": [200, 200],
		"gameplay_damage_tested": false, "complete_game_performance_gate": false,
		"limits": "Worn native-derived feasibility only; see direction/action/reference_only. Pose mode renders exact native samples outside gameplay. Motion mode uses an explicit hub fixture with no gameplay damage. Movie cadence does not measure FPS; cost mode is isolated A/B/A overhead. Visual fidelity remains a separate critic judgment."
	}, "\t"))
	print("NATIVE_RIG_REVIEW_COMPLETE mode=", mode, " failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
