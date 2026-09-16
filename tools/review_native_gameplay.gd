extends SceneTree
## Genuine native pilot artwork over real hub/controller movement.
## Movie mode is a cadence comparison, never an FPS measurement. The 260 case
## retimes the rendered 340-authored poses; it is not an approved 260 animation.

const ClothShader = preload("res://scripts/player/dad_cloth.gdshader")
var output: String
var candidate: String
var main: Node
var world: Node
var player: Node
var manifest: Dictionary
var native_sprite: Sprite2D
var cloth: ShaderMaterial
var pages: Dictionary = {}
var title: Label
var caption: Label
var recording: bool = false
var direction: String = "right"
var speed: float = 340.0
var phase: float = 0.0
var elapsed: float = 0.0
var previous: Vector2
var distance: float = 0.0
var samples: Array[Dictionary] = []
var cases: Array[Dictionary] = []
var failures: Array[String] = []
var current_case: String


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--candidate="): candidate = arg.trim_prefix("--candidate=")
	if not output.is_absolute_path() or not candidate.is_absolute_path() or DisplayServer.get_name() == "headless":
		push_error("Native gameplay review requires renderer, absolute --output and --candidate Worn directory")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	var data = JSON.parse_string(FileAccess.get_file_as_string(candidate.path_join("manifest.json")))
	if not data is Dictionary:
		push_error("Native pilot manifest is unreadable")
		quit(2)
		return
	manifest = data
	if String(manifest.get("gear", "")) != "worn" or not bool(manifest.get("rendered", false)) or int(manifest.get("schema_version", 0)) != 2:
		push_error("Review requires genuine rendered Worn schema-2 candidate")
		quit(2)
		return
	for view in ["right", "up"]:
		for page in Array(manifest.directions[view].pages):
			var id: String = view + ":" + str(int(page.page))
			var art: Image = Image.load_from_file(candidate.path_join(String(page.texture)))
			var mask: Image = Image.load_from_file(candidate.path_join(String(page.cloth)))
			if art == null or art.is_empty() or mask == null or mask.is_empty():
				push_error("Native candidate page is missing: " + id)
				quit(2)
				return
			pages[id] = {"texture": ImageTexture.create_from_image(art), "cloth": ImageTexture.create_from_image(mask),
				"texture_sha256": FileAccess.get_sha256(candidate.path_join(String(page.texture))),
				"cloth_sha256": FileAccess.get_sha256(candidate.path_join(String(page.cloth)))}
	root.size = Vector2i(1696, 780)
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
	if not main._dev_build_all_workshops_state() or not main._dev_jump_hub():
		push_error("Native gameplay review cannot enter the real built hub")
		quit(3)
		return
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
	if player.visual.active_gear != "worn":
		push_error("Production Worn setup did not load")
		quit(3)
		return
	# Only this review fixture hides the production sprite. All controller,
	# collision, camera, world lighting and original ground shadow remain active.
	player.visual._sprite.hide()
	player.visual.set_process(false)
	native_sprite = Sprite2D.new()
	native_sprite.name = "NativePilotReview"
	native_sprite.centered = false
	native_sprite.region_enabled = true
	native_sprite.region_filter_clip_enabled = true
	native_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	cloth = ShaderMaterial.new()
	cloth.shader = ClothShader
	cloth.set_shader_parameter("recolor", 0.0)
	native_sprite.material = cloth
	player.visual.add_child(native_sprite)
	player.control_enabled = true
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	main._refresh_hud()
	_make_caption()
	process_frame.connect(_sample)
	for view in ["right", "up"]:
		for fixture_speed in [260.0, 340.0]:
			await _case(view, fixture_speed)
	_finish()


func _make_caption() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	title = Label.new()
	title.position = Vector2(24, 104)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_shadow_color", Color.BLACK)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 2)
	layer.add_child(title)
	caption = Label.new()
	caption.position = Vector2(24, 135)
	caption.add_theme_font_size_override("font_size", 15)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 1)
	caption.add_theme_constant_override("shadow_offset_y", 1)
	caption.text = "Native pilot / 16 real poses / cadence comparison / no FPS claim"
	layer.add_child(caption)


func _case(view: String, fixture_speed: float) -> void:
	recording = false
	main._on_joystick_movement(Vector2.ZERO)
	direction = view
	speed = fixture_speed
	phase = 0.0
	elapsed = 0.0
	distance = 0.0
	current_case = "%s_%d" % [view, int(speed)]
	var start: Vector2 = Vector2(380, 448) if view == "right" else Vector2(1040, 805)
	var movement: Vector2 = Vector2.RIGHT if view == "right" else Vector2.UP
	world.restore_position(start)
	player.movement_speed = speed
	player.set_facing(movement)
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	_draw_pose()
	title.text = "%s / %d px/s / %.2f footfalls/s / SETUP" % [view.to_upper(), int(speed), speed * 2.0 / float(manifest.motion.stride_pixels)]
	await create_timer(0.30).timeout
	previous = player.global_position
	var first_sample: int = samples.size()
	var started: Vector2 = player.global_position
	title.text = "%s / %d px/s / %.2f footfalls/s" % [view.to_upper(), int(speed), speed * 2.0 / float(manifest.motion.stride_pixels)]
	main._on_joystick_movement(movement)
	recording = true
	await create_timer(1.8 if view == "right" else 1.5).timeout
	recording = false
	main._on_joystick_movement(Vector2.ZERO)
	var position: Vector2 = player.global_position
	var expected: float = speed * elapsed
	var passed: bool = absf(distance - expected) < speed / 30.0 and world.player_position_clear()
	if not passed: failures.append(current_case + " controller route or distance failed")
	cases.append({"id": current_case, "direction": view, "fixture_speed": speed,
		"sample_start": first_sample, "sample_count": samples.size() - first_sample,
		"seconds": elapsed, "distance": distance, "expected_distance": expected,
		"start": [started.x, started.y], "end": [position.x, position.y], "passed": passed})
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(current_case + ".png"))
	print("NATIVE_GAMEPLAY_CASE ", current_case, " distance=", distance, " seconds=", elapsed, " passed=", passed)


func _sample() -> void:
	if not recording: return
	var position: Vector2 = player.global_position
	var travelled: float = previous.distance_to(position)
	previous = position
	distance += travelled
	elapsed += root.get_process_delta_time()
	phase = fposmod(phase + travelled / float(manifest.motion.stride_pixels), 1.0)
	var local_frame: int = _draw_pose()
	samples.append({"case": current_case, "time": elapsed, "position": [position.x, position.y],
		"travelled": travelled, "distance": distance, "phase": phase, "local_frame": local_frame,
		"authored_phase": manifest.states.walk.phases[local_frame], "controller_moving": player.is_actually_moving()})


func _draw_pose() -> int:
	var info: Dictionary = manifest.states.walk
	var local_frame: int = 0
	var error: float = INF
	for index in int(info.count):
		var difference: float = absf(float(info.phases[index]) - phase)
		difference = minf(difference, 1.0 - difference)
		if difference < error:
			error = difference
			local_frame = index
	var page: Dictionary = pages[direction + ":" + str(int(info.page))]
	native_sprite.texture = page.texture
	cloth.set_shader_parameter("cloth_mask", page.cloth)
	var atlas_frame: int = int(info.offset) + local_frame
	var cell: Vector2 = Vector2(float(manifest.cell[0]), float(manifest.cell[1]))
	var columns: int = int(manifest.columns)
	native_sprite.region_rect = Rect2(Vector2(atlas_frame % columns, atlas_frame / columns) * cell, cell)
	var anchor: Array = manifest.directions[direction].ground_anchor
	native_sprite.position = Vector2(0, 2.8125) - Vector2(float(anchor[0]), float(anchor[1]))
	return local_frame


func _finish() -> void:
	var hashes: Dictionary = {}
	for path in ["tools/review_native_gameplay.gd", "scripts/player/player_controller.gd", "scripts/world/hub_world.gd", "scripts/player/dad_cloth.gdshader"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var page_hashes: Dictionary = {}
	for id in pages:
		page_hashes[id] = {"texture": pages[id].texture_sha256, "cloth": pages[id].cloth_sha256}
	FileAccess.open(output.path_join("native-gameplay.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": failures.is_empty(), "failures": failures, "cases": cases, "samples": samples,
		"rendered": true, "actual_controller": true, "terrain_replaced": false, "manual_process_steps": false,
		"production_atlases_changed": false, "transitions_tested": false, "performance_evidence": false,
		"physical_iphone": false, "viewport": [root.size.x, root.size.y], "runtime": Engine.get_version_info(),
		"renderer": RenderingServer.get_video_adapter_name(), "rendering_method": RenderingServer.get_current_rendering_method(),
		"authored_pose_speed": manifest.motion.reference_speed, "stride_pixels": manifest.motion.stride_pixels,
		"render_fingerprint": manifest.render_fingerprint, "candidate_sha256": FileAccess.get_sha256(candidate.path_join("manifest.json")),
		"page_sha256": page_hashes, "source_sha256": hashes,
		"limits": "260 retimes genuine 340-authored poses; 16-frame pilot cannot approve final foot contact. Movie cadence is not measured FPS. Setup cuts are not transitions."
	}, "\t"))
	print("NATIVE_GAMEPLAY_COMPLETE failures=", failures.size())
	quit(0 if failures.is_empty() else 1)
