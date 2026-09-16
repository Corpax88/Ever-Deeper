extends SceneTree
## Actual native A/B/A pixels first; optional real-time mining A/B/A only on exact parity.
var output: String
var initial_only: bool = false
var benchmark: bool = false
var timing_mode: String = ""
var parity_report: String = ""
var reference_verified: bool = false
var seconds: float = 30.0
var main: Node
var world: Node2D
var state: Node
var pairs: Array[Dictionary] = []
var timings: Array[Dictionary] = []
var failure: String = ""
var prepared_world_mode: int
var prepared_visual_mode: int

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg == "--initial-only": initial_only = true
		elif arg == "--benchmark": benchmark = true
		elif arg.begins_with("--timing-mode="): timing_mode = arg.trim_prefix("--timing-mode=")
		elif arg.begins_with("--parity-report="): parity_report = arg.trim_prefix("--parity-report=")
		elif arg.begins_with("--seconds="): seconds = maxf(30.0, float(arg.trim_prefix("--seconds=")))
	if output.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	if benchmark:
		failure = "Run timing stages in separate isolated processes: --timing-mode=native|receiver --parity-report=PATH. reset_run(false) preserves excavation."
		_write_report(); quit(3); return
	if not timing_mode.is_empty() and not _verify_reference():
		_write_report(); quit(3); return
	await _new_deep(timing_mode == "receiver")
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().get_size() != Vector2i(1696, 780):
		failure = "Actual framebuffer must be 1696x780."
		_write_report(); quit(3); return
	if not timing_mode.is_empty():
		root.get_texture().get_image().save_png(output.path_join("initial.png"))
		_resume_prepared_world()
		await _measure(timing_mode == "receiver")
		_write_report()
		quit()
		return
	_freeze(world)
	await _pair("initial")
	if not initial_only:
		var hero_lamp: Node = world.player.get_node("PremiumHeadlamp")
		var mole_lamp: Node = world.get_node("MoleCompanion/PremiumHeadlamp")
		for lamp in [hero_lamp, mole_lamp]:
			lamp.preview_settings = {"style": "wide", "range_multiplier": 1.4, "energy_multiplier": 1.3}
			lamp.refresh_workshop_effects()
		for direction in 8:
			hero_lamp.set_direction(Vector2.RIGHT.rotated(direction * PI / 4.0))
			mole_lamp.set_direction(Vector2.RIGHT.rotated(direction * PI / 4.0 + 0.31))
			await _pair("max_wide_%d" % direction)
		for lamp in [hero_lamp, mole_lamp]:
			lamp.preview_settings = {"style": "focused", "range_multiplier": 1.4, "energy_multiplier": 1.3}
			lamp.refresh_workshop_effects()
		hero_lamp.set_direction(Vector2(1.0, -0.37))
		await _pair("max_focused_first_frame", true)
		for lamp in [hero_lamp, mole_lamp]:
			lamp.preview_settings = {}
			lamp.refresh_workshop_effects()
		var cell: Vector2i = _near_wall()
		if cell.x >= 0:
			world._strike_wall(cell, 0.66)
			await _pair("hit")
			world._apply_crusher_wave(cell, {"power": 9999})
			await _pair("crusher")
		cell = _near_wall()
		if cell.x >= 0:
			world.companion_dig(world._cell_center(cell), true)
			await _pair("pet_opening")
		world.player.camera.offset += Vector2(0.375, 0.625)
		await _pair("fractional_camera")
		world.player.camera.offset -= Vector2(0.375, 0.625)
		root.size = Vector2i(1536, 864)
		await _pair("resize_1536x864")
		root.size = Vector2i(1696, 780)
		# Exercise a new non-helmet light and removal on the same frame.
		var extra: PointLight2D = PointLight2D.new()
		extra.texture = hero_lamp.beam_light.texture
		extra.texture_scale = 2.1
		extra.position = world.player.position + Vector2(120, -90)
		extra.color = Color(0.18, 0.3, 0.45)
		world.add_child(extra)
		await _pair("new_nonhelmet_light", true)
		extra.queue_free()
		await process_frame
		await _pair("removed_nonhelmet_light", true)
		world.player.position.y = world.CHUNK_HEIGHT * 2.0 + 64.0
		world._update_stream_depth()
		_freeze(world)
		await _pair("rebase_down")
		world.player.position.y = world.CHUNK_HEIGHT - 64.0
		world._update_stream_depth()
		_freeze(world)
		await _pair("rebase_up")
		main._dev_seed_victory_state()
		main._dev_build_all_workshops_state()
		main._dev_jump_hub()
		world = main.hub_world
		await create_timer(3.0).timeout
		_freeze(world)
		await _pair("hub_empty_shadows", false, true)
	_write_report()
	quit(0 if _parity() else 4)

func _new_deep(mode: bool) -> void:
	if is_instance_valid(main):
		main.queue_free()
		for frame in 3: await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	# Main initializes persistence in _ready and can reset an absent save.
	# Apply the isolated fixture afterwards, before any procedural generation.
	state.initialize_persistence(output.path_join("isolated-save.sav"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	# Rejected experimental renderer lives only in tools; production has no receiver controller.
	world = main.endless_world
	var previous_sections: Node2D = world.lit_draw_sections
	world.remove_child(previous_sections)
	previous_sections.queue_free()
	world.lit_draw_sections = load("res://tools/light_receiver_pilot/lit_draw_sections.gd").new()
	world.add_child(world.lit_draw_sections)
	main._dev_jump_endless(12)
	world.lit_draw_sections.receiver_masks_enabled = mode
	world.queue_redraw()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	# Warm renderer/texture loading without letting autonomous digging change
	# the starting terrain by a frame-rate-dependent number of warm-up ticks.
	prepared_world_mode = world.process_mode
	prepared_visual_mode = world.player.visual.process_mode
	world.process_mode = Node.PROCESS_MODE_DISABLED
	world.player.visual.process_mode = Node.PROCESS_MODE_ALWAYS
	await create_timer(4.0).timeout
	world.player.visual.process_mode = prepared_visual_mode

func _resume_prepared_world() -> void:
	# Parent process mode preserves every child's existing processing flags
	# and needs no references to transient effects freed during the warm-up.
	world.process_mode = prepared_world_mode

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _pair(id: String, first_frame: bool = false, hub: bool = false) -> void:
	main.get_node("HUD").hide()
	world.player.get_node("ResourcePickupBurst").hide()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	for tween in get_processed_tweens(): tween.pause()
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	var occlusion: Node = world.get_node_or_null("CaveLightOccluders")
	if occlusion != null: occlusion.refresh()
	var pictures: Array[Image] = []
	var snapshots: Array[Dictionary] = []
	for mode in [false, true, false]:
		if hub:
			for light in world.get_node("MoleCompanion/PremiumHeadlamp").get_children():
				if light is PointLight2D: light.shadow_enabled = not mode
		else:
			world.lit_draw_sections.receiver_masks_enabled = mode
		world.queue_redraw()
		if first_frame and not hub:
			var lamp: Node2D = world.player.get_node("PremiumHeadlamp")
			var wanted: float = lamp.rotation
			lamp.rotation += 0.21
			await process_frame
			await RenderingServer.frame_post_draw
			lamp.rotation = wanted
			if occlusion != null: occlusion.refresh()
		for frame in (1 if first_frame else 4): await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		picture.save_png(output.path_join(id + "-" + ["A", "B", "A2"][pictures.size()] + ".png"))
		pictures.append(picture)
		snapshots.append(world.lit_draw_sections.receiver_masks.debug_snapshot() if not hub else {})
	var candidate: Dictionary = _difference(pictures[0], pictures[1])
	var controls: Dictionary = _difference(pictures[0], pictures[2])
	pairs.append({"id": id, "framebuffer_size": [pictures[0].get_width(), pictures[0].get_height()], "first_frame": first_frame,
		"candidate": candidate, "controls": controls, "receiver_states": snapshots})
	print("RECEIVER_PAIR " + JSON.stringify(pairs[-1]))

func _difference(a: Image, b: Image) -> Dictionary:
	if a.get_size() != b.get_size(): return {"changed_pixels": -1, "size_mismatch": true}
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	if left == right: return {"changed_pixels": 0, "max_channel_delta": 0}
	var changed: int = 0
	var maximum: int = 0
	for pixel in range(0, left.size(), 4):
		var peak: int = 0
		for channel in 4: peak = maxi(peak, absi(int(left[pixel + channel]) - int(right[pixel + channel])))
		if peak > 0: changed += 1
		maximum = maxi(maximum, peak)
	return {"changed_pixels": changed, "max_channel_delta": maximum}

func _parity() -> bool:
	if pairs.is_empty() or not failure.is_empty(): return false
	for pair in pairs:
		if int(pair.candidate.changed_pixels) != 0 or int(pair.controls.changed_pixels) != 0: return false
	return true

func _measure(mode: bool) -> void:
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
	var frames: Array[float] = []
	var gpu: Array[float] = []
	var invalid_gpu_samples: int = 0
	var cpu: Array[float] = []
	var draws: Array[float] = []
	var distance: float = 0.0
	var previous_position: Vector2 = world.player.global_position
	var mined_before: int = state.total_mined_resources()
	var start_hash: int = hash(world.floor_cells)
	var start_player: Vector2 = world.player.position
	var start_depth: int = world.current_depth
	var start_window: int = world.window_start_depth
	var start_gear: Array = [state.pickaxe_level, state.drill_level, state.starforge_variant]
	var before: Dictionary = world.lit_draw_sections.receiver_masks.debug_snapshot()
	var started: int = Time.get_ticks_usec()
	var previous: int = started
	while float(Time.get_ticks_usec() - started) / 1000000.0 < seconds:
		world.set_mine_held(true)
		world.player.set_external_movement(Vector2.DOWN)
		await process_frame
		var now: int = Time.get_ticks_usec()
		frames.append(float(now - previous) / 1000.0)
		cpu.append(RenderingServer.get_frame_setup_time_cpu() + RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()))
		var gpu_ms: float = RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid())
		if not is_finite(gpu_ms) or gpu_ms < 0.0 or gpu_ms >= 1000.0:
			invalid_gpu_samples += 1
			gpu_ms = 0.0
		gpu.append(gpu_ms)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var moved: float = previous_position.distance_to(world.player.global_position)
		if moved < 100.0: distance += moved
		previous_position = world.player.global_position
		previous = now
	world.player.set_external_movement(Vector2.ZERO)
	world.set_mine_held(false)
	var total: float = 0.0
	for ms in frames: total += ms
	frames.sort(); cpu.sort(); gpu.sort(); draws.sort()
	var after: Dictionary = world.lit_draw_sections.receiver_masks.debug_snapshot()
	timings.append({"mode": "receiver_masks" if mode else "native", "actors_and_gameplay_frozen": false,
		"workload": "held_mining_down_v1", "seconds": total / 1000.0, "fps": frames.size() * 1000.0 / total,
		"p95_ms": frames[floori(frames.size() * 0.95)], "render_cpu_median_ms": cpu[cpu.size() / 2],
		"render_gpu_median_ms": gpu[gpu.size() / 2] if invalid_gpu_samples == 0 else 0.0,
		"gpu_timing_supported": invalid_gpu_samples == 0 and gpu[gpu.size() / 2] > 0.0,
		"invalid_gpu_samples": invalid_gpu_samples,
		"draws_median": draws[draws.size() / 2], "distance": distance,
		"mined_resources": state.total_mined_resources() - mined_before, "start_terrain_hash": start_hash,
		"start_player": str(start_player), "start_depth": start_depth, "start_window": start_window, "start_gear": start_gear,
		"actual_world_seed": state.world_seed,
		"end_terrain_hash": hash(world.floor_cells), "masks_before": before, "masks_after": after,
		"receiver_update_mean_us_per_frame": float(int(after.update_usec) - int(before.update_usec)) / frames.size()})
	print("RECEIVER_TIMING " + JSON.stringify(timings[-1]))

func _verify_reference() -> bool:
	if timing_mode not in ["native", "receiver"] or parity_report.is_empty():
		failure = "A single native/receiver timing stage requires a passed full parity report."
		return false
	var reference: Variant = JSON.parse_string(FileAccess.get_file_as_string(parity_report))
	if not reference is Dictionary or not bool(reference.get("exact_pixel_parity", false)) or Array(reference.get("pairs", [])).size() < 20:
		failure = "The reference must contain the full exact pixel matrix."
		return false
	for path in reference.source_sha256:
		if FileAccess.get_sha256("res://" + path) != String(reference.source_sha256[path]):
			failure = "Source changed since the passed pixel matrix: " + String(path)
			return false
	reference_verified = true
	return true

func _near_wall() -> Vector2i:
	var center: Vector2i = world._world_to_cell(world.player.position)
	for radius in range(1, 9):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell: Vector2i = center + Vector2i(x, y)
				if world._cell_in_bounds(cell) and world._cell_diggable(cell) and not world._is_floor(cell) and world._has_floor_neighbor(cell): return cell
	return Vector2i(-1, -1)

func _write_report() -> void:
	var hashes: Dictionary = {}
	for path in ["tools/light_receiver_pilot/terrain_light_receivers.gd", "tools/light_receiver_pilot/lit_draw_sections.gd", "scripts/lighting/lit_draw_sections.gd", "scripts/world/endless_descent_world.gd", "scripts/companion/mole_companion.gd", "tools/review_terrain_light_receivers.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report: Dictionary = {"rendered": true, "physical_iphone": false, "failure": failure,
		"engine": Engine.get_version_info(), "renderer": RenderingServer.get_video_adapter_name(),
		"source_sha256": hashes, "seed": 4608, "exact_pixel_parity": _parity(), "pairs": pairs,
		"timing_mode": timing_mode, "parity_report": parity_report, "reference_verified": reference_verified,
		"timing_requested": not timing_mode.is_empty(), "timings": timings,
		"timing_skipped_for_pixel_difference": not timing_mode.is_empty() and not reference_verified}
	FileAccess.open(output.path_join("terrain-light-receivers.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
