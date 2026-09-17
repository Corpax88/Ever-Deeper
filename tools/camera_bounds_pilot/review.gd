extends SceneTree
## Same frozen world, original/candidate/restored camera invalidation histories.
var output: String = ""
var main: Node
var world: Node
var pairs: Array[Dictionary] = []
var failure: String = ""
var _base_zoom: Vector2
var _base_content_size: Vector2i
var _source_revision: String = ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--source-revision="): _source_revision = arg.trim_prefix("--source-revision=")
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	var seal: Shader = load("res://shaders/lit_relic_seal.gdshader")
	seal.code = seal.code.replace("TIME", "0.0")
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load("res://tools/camera_bounds_pilot/candidate.gd"))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(12): failure = "Cannot enter Deep"; _finish(); return
	world = main.endless_world
	world.player.set_external_movement(Vector2.ZERO)
	await create_timer(4.0).timeout
	_freeze(root)
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	world.player.camera.position_smoothing_enabled = false
	# Each history must move the same actual camera. Drag memory otherwise makes
	# later modes retrace a dead zone and produces vacuous zero-redraw cases.
	world.player.camera.drag_horizontal_enabled = false
	world.player.camera.drag_vertical_enabled = false
	world.player.camera.limit_smoothed = false
	world.player.camera.limit_left = -1000000
	world.player.camera.limit_top = -1000000
	world.player.camera.limit_right = 1000000
	world.player.camera.limit_bottom = 1000000
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	for tween in get_processed_tweens(): tween.pause()
	paused = true
	Engine.time_scale = 0.0
	_base_zoom = world.player.camera.zoom
	_base_content_size = root.content_scale_size
	world.lit_draw_sections.profile_draws = true
	var anchor: Vector2 = world.player.position
	var x_path: Array[Vector2] = _path(Vector2.RIGHT, 12)
	var y_path: Array[Vector2] = _path(Vector2.DOWN, 12)
	if not await _pair("same-tile-and-x-boundary", anchor, x_path): _finish(); return
	if not await _pair("same-tile-and-y-boundary", anchor, y_path): _finish(); return
	if not await _pair("diagonal-boundary", anchor, _path(Vector2(1, 1), 12)): _finish(); return
	var hero_lamp: Node = world.player.get_node("PremiumHeadlamp")
	var pet_lamp: Node = world.get_node("MoleCompanion/PremiumHeadlamp")
	for lamp in [hero_lamp, pet_lamp]:
		lamp.preview_settings = {"style":"wide", "range_multiplier":1.4, "energy_multiplier":1.28}
		lamp.refresh_workshop_effects()
	hero_lamp.set_direction(Vector2.RIGHT.rotated(.017))
	pet_lamp.set_direction(Vector2.LEFT.rotated(-.37))
	if not await _pair("wide-lamp-grazing-boundary", anchor, x_path): _finish(); return
	if not await _pair("left-clamped-bound", Vector2(160, anchor.y), _path(Vector2.LEFT, 8)): _finish(); return
	if not await _pair("right-clamped-bound", Vector2(world.WORLD_SIZE.x - 160, anchor.y), _path(Vector2.RIGHT, 8)): _finish(); return
	if not await _pair("upper-clamped-bound", Vector2(anchor.x, 160), _path(Vector2.UP, 8)): _finish(); return
	if not await _pair("lower-clamped-bound", Vector2(anchor.x, world.WORLD_SIZE.y - 160), _path(Vector2.DOWN, 8)): _finish(); return
	if not await _pair("zoom-change", anchor, _path(Vector2.RIGHT, 3), _change_zoom): _finish(); return
	if not await _pair("viewport-change", anchor, _path(Vector2.RIGHT, 3), _change_viewport): _finish(); return
	var cell: Vector2i = _near_wall(anchor)
	if cell.x < 0: failure = "No visible diggable wall"; _finish(); return
	var damage: int = int(world.dig_damage.get(cell, 0))
	if not await _pair("direct-damage-restore", anchor, _path(Vector2.RIGHT, 3), _change_damage.bind(cell, damage + 25)): _finish(); return
	if not await _pair("direct-floor-restore", anchor, _path(Vector2.RIGHT, 3), _change_floor.bind(cell)): _finish(); return
	if not await _pair("material-state-change", anchor, _path(Vector2.RIGHT, 3), _change_modulate): _finish(); return
	# Real production mutators retain their independent queue_redraw calls.
	world._strike_wall(cell, .66)
	_freeze(root)
	for tween in get_processed_tweens(): tween.pause()
	if not await _pair("after-real-wall-hit", anchor, x_path): _finish(); return
	cell = _near_wall(anchor)
	if cell.x < 0 or world.companion_dig(world._cell_center(cell), true) <= 0:
		failure = "Real companion dig did not remove terrain"; _finish(); return
	_freeze(root)
	for tween in get_processed_tweens(): tween.pause()
	if not await _pair("after-real-companion-dig", anchor, x_path): _finish(); return
	var previous_band: int = world.window_start_depth
	world.player.position.y = world.CHUNK_HEIGHT * 2.0 + 64.0
	world._update_stream_depth()
	_freeze(root)
	for tween in get_processed_tweens(): tween.pause()
	if world.window_start_depth == previous_band: failure = "Downward rebase did not occur"; _finish(); return
	anchor = world.player.position
	if not await _pair("after-real-rebase-down", anchor, y_path): _finish(); return
	previous_band = world.window_start_depth
	world.player.position.y = world.CHUNK_HEIGHT - 64.0
	world._update_stream_depth()
	_freeze(root)
	for tween in get_processed_tweens(): tween.pause()
	if world.window_start_depth == previous_band: failure = "Upward rebase did not occur"; _finish(); return
	anchor = world.player.position
	if not await _pair("after-real-rebase-up", anchor, y_path): _finish(); return
	_finish()

func _pair(label: String, anchor: Vector2, offsets: Array[Vector2], mutation: Callable = Callable()) -> bool:
	var floor_before: PackedByteArray = world.floor_cells.duplicate()
	var damage_before: Dictionary = world.dig_damage.duplicate(true)
	var modulate_before: Color = world.self_modulate
	var pictures: Array[Image] = []
	var row: Dictionary = {"id":label, "histories":[], "source_band":world.window_start_depth}
	for mode in [false, true, false]:
		world.camera_bounds_enabled = mode
		world.floor_cells = floor_before.duplicate()
		world.dig_damage = damage_before.duplicate(true)
		world.self_modulate = modulate_before
		world.player.camera.zoom = _base_zoom
		root.content_scale_size = _base_content_size
		_set_position(anchor)
		world.queue_redraw()
		await _settle()
		var before: Dictionary = world.lit_draw_sections.debug_snapshot()
		var before_study: Dictionary = world.study_snapshot()
		var camera_before: Vector2 = world.player.camera.get_screen_center_position()
		var viewport_before: Vector2 = world.get_viewport_rect().size
		if mutation.is_valid(): mutation.call()
		var decisions: Array[Dictionary] = []
		for offset in offsets:
			_set_position(anchor + offset)
			var redraw: bool = world._camera_draw_bounds_changed()
			if redraw: world.queue_redraw()
			decisions.append({"offset":str(offset),"requested_redraw":redraw,
				"camera":str(world.player.camera.get_screen_center_position()),
				"viewport":str(world.get_viewport_rect().size),"key":str(world._study_current_key())})
			await _settle()
		var after: Dictionary = world.lit_draw_sections.debug_snapshot()
		var after_study: Dictionary = world.study_snapshot()
		row.histories.append({"candidate":mode,"decisions":decisions,
			"camera_before":str(camera_before),"viewport_before":str(viewport_before),
			"setup_usec":int(after.setup_usec)-int(before.setup_usec),
			"draw_usec":int(after.draw_callback_usec)-int(before.draw_callback_usec),
			"redraws":int(after.redraws)-int(before.redraws),
			"reuses":int(after.reuses)-int(before.reuses),
			"skipped":int(after_study.skipped_requests)-int(before_study.skipped_requests),
			"key_usec":int(after_study.key_usec)-int(before_study.key_usec),
			"key":after_study.key})
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		if picture.get_size() != Vector2i(1696,780): failure = "Unexpected framebuffer"; return false
		picture.convert(Image.FORMAT_RGBA8)
		var name: String = label + "-" + ["A","B","A2"][pictures.size()] + ".png"
		picture.save_png(output.path_join(name))
		pictures.append(picture)
	row["candidate_diff"] = _difference(pictures[0], pictures[1])
	row["restored_diff"] = _difference(pictures[0], pictures[2])
	world.floor_cells = floor_before
	world.dig_damage = damage_before
	world.self_modulate = modulate_before
	world.player.camera.zoom = _base_zoom
	root.content_scale_size = _base_content_size
	world.queue_redraw()
	pairs.append(row)
	if int(row.restored_diff.changed_pixels) != 0: failure = "Restored control unstable: " + label
	elif int(row.candidate_diff.changed_pixels) != 0: failure = "Candidate pixels differ: " + label
	elif int(row.histories[0].setup_usec) <= 0 or int(row.histories[2].setup_usec) <= 0:
		failure = "Control did not exercise camera setup: " + label
	elif row.histories[0].camera_before != row.histories[1].camera_before or row.histories[0].camera_before != row.histories[2].camera_before:
		failure = "Actual camera histories did not start identically: " + label
	elif row.histories[0].decisions[-1].camera != row.histories[1].decisions[-1].camera or row.histories[0].decisions[-1].camera != row.histories[2].decisions[-1].camera:
		failure = "Actual camera histories did not end identically: " + label
	elif label == "viewport-change" and row.histories[0].viewport_before == row.histories[0].decisions[-1].viewport:
		failure = "Viewport mutation did not change the actual viewport"
	_save_report()
	print("CAMERA_BOUNDS_PAIR " + JSON.stringify({"id":label,"candidate_diff":row.candidate_diff,"restored_diff":row.restored_diff,"failure":failure}))
	return failure.is_empty()

func _set_position(point: Vector2) -> void:
	world.player.position = point
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.get_node("CaveLightOccluders").refresh()

func _settle() -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw

func _path(direction: Vector2, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for index in range(1, count + 1): result.append(direction * (8.125 * index))
	return result

func _change_zoom() -> void:
	world.player.camera.zoom = _base_zoom * 1.035

func _change_viewport() -> void:
	root.content_scale_size = Vector2i(1584, 728)

func _change_damage(cell: Vector2i, value: int) -> void:
	world.dig_damage[cell] = value

func _change_floor(cell: Vector2i) -> void:
	world._set_floor(cell, true)

func _change_modulate() -> void:
	world.self_modulate = Color(.98, .99, 1.0, 1.0)

func _near_wall(anchor: Vector2) -> Vector2i:
	var center: Vector2i = world._world_to_cell(anchor)
	for radius in range(1, 8):
		for y in range(center.y-radius, center.y+radius+1):
			for x in range(center.x-radius, center.x+radius+1):
				var cell := Vector2i(x,y)
				if not world._is_floor(cell) and world._cell_diggable(cell) and world._has_floor_neighbor(cell): return cell
	return Vector2i(-1,-1)

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _difference(a: Image, b: Image) -> Dictionary:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	if left == right: return {"changed_pixels":0,"max_channel_delta":0}
	var changed: int = 0
	var maximum: int = 0
	for pixel in range(0,left.size(),4):
		var peak: int = 0
		for channel in 4: peak = maxi(peak, absi(int(left[pixel+channel])-int(right[pixel+channel])))
		if peak > 0: changed += 1
		maximum = maxi(maximum, peak)
	return {"changed_pixels":changed,"max_channel_delta":maximum}

func _save_report() -> void:
	FileAccess.open(output.path_join("camera-bounds-review.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"source_revision":_source_revision,"production_sha256":FileAccess.get_sha256("res://scripts/world/endless_descent_world.gd"),
		"candidate_sha256":FileAccess.get_sha256("res://tools/camera_bounds_pilot/candidate.gd"),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),
		"renderer":RenderingServer.get_video_adapter_name(),"physical_iphone":false,"adopted":false,
		"frozen":true,"shader_time_lock":"lit_relic_seal TIME=0, in memory only",
		"camera_fixture":"Smoothing/drag disabled and limits widened identically for every mode, so each actual frozen camera history is identical and clamped terrain bounds are exercised. Moving sessions retain original camera behavior.",
		"comparison":"A/B/A2 in the same frozen scene; original/candidate camera request decisions drive ordinary queue_redraw over each exact camera history",
		"limit":"Frozen camera moves are a render invalidation test, not real-time movement or FPS. Hit/pet/rebase are real mutators applied before their compared camera histories; direct state and configuration mutations occur inside each history.",
		"pairs":pairs,"failure":failure},"\t"))

func _finish() -> void:
	_save_report()
	print("CAMERA_BOUNDS_REVIEW_FINISHED " + JSON.stringify({"pairs":pairs.size(),"failure":failure}))
	if failure.is_empty(): print("CAMERA_BOUNDS_REVIEW_COMPLETE")
	quit(0 if failure.is_empty() else 4)
