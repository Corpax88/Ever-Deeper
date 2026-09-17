extends SceneTree
## Frozen same-scene A/B/A2. Only the floor blend state differs in B.
var output: String
var main: Node
var world: Node
var controller: Node
var alpha_parent: Node2D
var pairs: Array[Dictionary] = []
var failure: String = ""
var first_normal: Image
var external_shader: Shader
var source_revision: String
var quick_gate: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--source-revision="): source_revision = arg.trim_prefix("--source-revision=")
		elif arg == "--quick-gate": quick_gate = true
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	var seal: Shader = load("res://shaders/lit_relic_seal.gdshader")
	seal.code = seal.code.replace("TIME", "0.0")
	root.get_node("RunState").initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	root.get_node("RunState").reset_run(false)
	root.get_node("RunState").world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(12): failure = "Cannot enter Deep"; _finish(); return
	world = main.endless_world
	world.player.set_external_movement(Vector2.ZERO)
	await create_timer(4.0).timeout
	_freeze_scene()
	paused = true
	Engine.time_scale = 0.0
	# Main is a Node. An identity CanvasItem parent supplies a real inherited-
	# alpha transition for the conservative fallback test, equally in A/B/A2.
	alpha_parent = Node2D.new()
	alpha_parent.name = "OpacityFixtureParent"
	main.add_child(alpha_parent)
	world.reparent(alpha_parent, true)
	controller = load("res://tools/floor_blend_pilot/controller.gd").new()
	root.add_child(controller)
	controller.configure(world)
	external_shader = Shader.new()
	external_shader.code = controller.source_shader.code
	_configure_camera()
	world.lit_draw_sections.profile_draws = true
	world.queue_redraw()
	await _settle()
	if not await _pair("normal-depth-12", true, Callable(), Callable(), "interior"): _finish(); return
	# Establish the key blend/opacity claim before spending a broader matrix.
	# This short gate is deliberately insufficient to unlock moving timing.
	if quick_gate:
		if not await _pair("world-fade-without-terrain-redraw", false, _set_world_alpha.bind(.65), _set_world_alpha.bind(1.0), "", true): _finish(); return
		var horizontal: float = world.player.position.x
		_set_position(Vector2(horizontal, world.CHUNK_HEIGHT + 16.0))
		if not await _pair("previous-neighbor-seam", true, Callable(), Callable(), "previous"): _finish(); return
		_set_position(Vector2(horizontal, world.CHUNK_HEIGHT * 2.0 - 16.0))
		if not await _pair("next-neighbor-seam", true, Callable(), Callable(), "next"): _finish(); return
		_finish()
		return
	if not await _pair("opaque-rgb-material", true, _set_floor_tint.bind(Color(.81,.92,.99,1)), _reset_tint): _finish(); return
	if not await _pair("material-alpha-fallback", false, _set_floor_tint.bind(Color(.88,.9,.92,.65)), _reset_tint, "", true): _finish(); return
	if not await _pair("parent-fade-without-terrain-redraw", false, _set_parent_alpha.bind(.65), _set_parent_alpha.bind(1.0), "", true): _finish(); return
	if not await _pair("world-fade-without-terrain-redraw", false, _set_world_alpha.bind(.65), _set_world_alpha.bind(1.0), "", true): _finish(); return
	if not await _pair("world-self-alpha-with-redraw", false, _set_world_self_alpha.bind(.65), _set_world_self_alpha.bind(1.0)): _finish(); return
	if not await _pair("floor-item-alpha-without-redraw", false, _set_floor_item_alpha.bind(.65,false), _set_floor_item_alpha.bind(1.0,false), "", true): _finish(); return
	if not await _pair("floor-item-self-alpha-without-redraw", false, _set_floor_item_alpha.bind(.65,true), _set_floor_item_alpha.bind(1.0,true), "", true): _finish(); return
	if not await _pair("canvas-alpha-without-terrain-redraw", false, _set_canvas_alpha.bind(.65), _set_canvas_alpha.bind(1.0), "", true): _finish(); return
	if not await _pair("external-material-shader-fallback", false, _set_external_shader, _reset_shaders, "", true): _finish(); return
	if not await _pair("transparent-target-fallback", false, _set_target_alpha.bind(true), _set_target_alpha.bind(false), "", true): _finish(); return
	# Every authored floor family is represented. Depth 12 already covers index 2.
	for depth in [1,3,4,5]:
		if not await _enter_depth(depth): _finish(); return
		_set_position(Vector2(world.player.position.x, (depth-world.window_start_depth+.5)*world.CHUNK_HEIGHT))
		if not await _pair("floor-family-depth-%d" % depth, true, Callable(), Callable(), "interior"): _finish(); return
	if not await _enter_depth(12): _finish(); return
	var anchor: Vector2 = world.player.position
	_set_position(Vector2(anchor.x, world.CHUNK_HEIGHT + 16.0))
	if not await _pair("previous-neighbor-seam", true, Callable(), Callable(), "previous"): _finish(); return
	_set_position(Vector2(anchor.x, world.CHUNK_HEIGHT * 2.0 - 16.0))
	if not await _pair("next-neighbor-seam", true, Callable(), Callable(), "next"): _finish(); return
	var hero: Node = world.player.get_node("PremiumHeadlamp")
	var pet: Node = world.get_node("MoleCompanion/PremiumHeadlamp")
	for lamp in [hero,pet]:
		lamp.preview_settings = {"style":"wide","range_multiplier":1.4,"energy_multiplier":1.28}
		lamp.refresh_workshop_effects()
	hero.set_direction(Vector2.RIGHT.rotated(.017))
	pet.set_direction(Vector2.LEFT.rotated(-.37))
	world.get_node("CaveLightOccluders").refresh()
	if not await _pair("maximum-wide-grazing-light", true): _finish(); return
	var cell: Vector2i = _near_wall(world.player.position)
	if cell.x < 0: failure = "No actual visible wall for damage"; _finish(); return
	world._strike_wall(cell, .66)
	_freeze_scene()
	if not await _pair("after-real-wall-strike", true): _finish(); return
	world.player.camera.zoom *= 1.17
	_set_position(world.player.position + Vector2(.375,.625))
	if not await _pair("fractional-camera-and-zoom", true): _finish(); return
	var previous: int = world.window_start_depth
	world.player.position.y = world.CHUNK_HEIGHT * 2.0 + 64.0
	world._update_stream_depth()
	_freeze_scene()
	_configure_camera()
	if previous == world.window_start_depth: failure = "Down rebase did not occur"; _finish(); return
	_set_position(world.player.position)
	if not await _pair("after-real-rebase-down", true): _finish(); return
	previous = world.window_start_depth
	world.player.position.y = world.CHUNK_HEIGHT - 64.0
	world._update_stream_depth()
	_freeze_scene()
	_configure_camera()
	if previous == world.window_start_depth: failure = "Up rebase did not occur"; _finish(); return
	_set_position(world.player.position)
	if not await _pair("after-real-rebase-up", true): _finish(); return
	_finish()

func _pair(label: String, eligible: bool, mutate: Callable = Callable(), reset: Callable = Callable(), required_branch: String = "", require_no_setup: bool = false) -> bool:
	var pictures: Array[Image] = []
	var row: Dictionary = {"id":label,"expected_candidate_eligible":eligible,"histories":[],"required_visible_branch":required_branch}
	for index in 3:
		controller.candidate_enabled = false
		controller._before_render()
		if reset.is_valid(): reset.call()
		controller.candidate_enabled = index == 1
		world.queue_redraw()
		await _settle()
		var before: Dictionary = world.lit_draw_sections.debug_snapshot()
		if mutate.is_valid(): mutate.call()
		await _settle()
		var after: Dictionary = world.lit_draw_sections.debug_snapshot()
		var state: Dictionary = controller.study_snapshot()
		state["mode"] = ["A","B","A2"][index]
		state["setup_after_mutation_usec"] = int(after.setup_usec) - int(before.setup_usec)
		state["cached_redraws_after_mutation"] = int(after.redraws) - int(before.redraws)
		state["camera"] = str(world.player.camera.get_screen_center_position())
		state["band"] = world.window_start_depth
		state["visible_floor_branches"] = _visible_floor_branches()
		state["alpha"] = {"parent":alpha_parent.modulate.a,"world":world.modulate.a,
			"world_self":world.self_modulate.a,"sections":world.lit_draw_sections.modulate.a,
			"canvas":world.darkness.color.a,"transparent_target":root.transparent_bg}
		var picture: Image = root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		picture.save_png(output.path_join(label + "-" + state.mode + ".png"))
		pictures.append(picture)
		row.histories.append(state)
		if picture.get_size() != Vector2i(1696,780): failure = "Unexpected framebuffer: " + label
		if require_no_setup and int(state.setup_after_mutation_usec) != 0: failure = "Transition unexpectedly rebuilt terrain: " + label
		if index == 1 and (int(state.active_materials) > 0) != eligible: failure = "Opacity eligibility not exercised: " + label
		if index != 1 and int(state.active_materials) != 0: failure = "Control blend state not restored: " + label
		if not required_branch.is_empty() and int(state.visible_floor_branches.get(required_branch,0)) <= 0: failure = "No visible floor in required branch: " + label
		if label.begins_with("floor-family-depth-"):
			var family: int = posmod(label.trim_prefix("floor-family-depth-").to_int(),5)
			if int(state.visible_floor_branches.floor_families[family]) <= 0: failure = "Requested floor family is not visible: " + label
		if not failure.is_empty(): break
	if pictures.size() == 3:
		row["candidate_diff"] = _difference(pictures[0], pictures[1])
		row["restored_diff"] = _difference(pictures[0], pictures[2])
		if first_normal == null: first_normal = pictures[0]
		row["reference_difference_from_initial"] = _difference(first_normal, pictures[0])
		if int(row.candidate_diff.changed_pixels) != 0: failure = "Candidate pixels differ: " + label
		elif int(row.restored_diff.changed_pixels) != 0: failure = "Restored pixels differ: " + label
		if label in ["material-alpha-fallback","parent-fade-without-terrain-redraw","world-fade-without-terrain-redraw","floor-item-alpha-without-redraw","canvas-alpha-without-terrain-redraw"] and int(row.reference_difference_from_initial.changed_pixels) == 0:
			failure = "Opacity change was not visible: " + label
	controller.candidate_enabled = false
	controller._before_render()
	if reset.is_valid(): reset.call()
	world.queue_redraw()
	pairs.append(row)
	_save()
	print("FLOOR_BLEND_PAIR ",label," failure=",failure)
	return failure.is_empty()

func _enter_depth(depth: int) -> bool:
	controller.candidate_enabled = false
	controller._before_render()
	if not main._dev_jump_endless(depth): failure = "Cannot enter depth " + str(depth); return false
	_freeze_scene()
	_configure_camera()
	world.queue_redraw()
	await _settle()
	return true

func _freeze_scene() -> void:
	_freeze(root)
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	for tween in get_processed_tweens(): tween.pause()

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _configure_camera() -> void:
	var camera: Camera2D = world.player.camera
	camera.position_smoothing_enabled = false
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	camera.limit_smoothed = false
	camera.limit_left = -1000000
	camera.limit_top = -1000000
	camera.limit_right = 1000000
	camera.limit_bottom = 1000000

func _set_position(point: Vector2) -> void:
	world.player.position = point
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.get_node("CaveLightOccluders").refresh()
	world.queue_redraw()

func _settle() -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw

func _set_floor_tint(value: Color) -> void:
	for material in world._floor_materials.values(): material.set_shader_parameter("floor_tint", value)

func _reset_tint() -> void:
	_set_floor_tint(Color(.88,.9,.92,1))

func _set_parent_alpha(value: float) -> void:
	alpha_parent.modulate.a = value

func _set_world_alpha(value: float) -> void:
	world.modulate.a = value

func _set_world_self_alpha(value: float) -> void:
	world.self_modulate.a = value
	world.queue_redraw()

func _set_canvas_alpha(value: float) -> void:
	world.darkness.color.a = value

func _set_target_alpha(value: bool) -> void:
	root.transparent_bg = value

func _set_external_shader() -> void:
	for material in world._floor_materials.values(): material.shader = external_shader

func _reset_shaders() -> void:
	for material in world._floor_materials.values(): material.shader = controller.source_shader

func _set_floor_item_alpha(value: float, self_alpha: bool) -> void:
	var chosen: CanvasItem
	var distance: float = INF
	for key in world.lit_draw_sections._cached:
		if key.z != 0: continue
		var rect: Rect2 = Rect2(Vector2(key.y,key.x) * world.TILE_SIZE, Vector2(4,1) * world.TILE_SIZE)
		var has_floor: bool = false
		for column in range(key.y, mini(key.y+4,world.GRID_SIZE.x)):
			if world._is_floor(Vector2i(column,key.x)): has_floor = true
		if not has_floor or not rect.intersects(world._visual_visible_rect(Vector2.ZERO)): continue
		var candidate_distance: float = rect.get_center().distance_squared_to(world.player.position)
		if candidate_distance < distance:
			chosen = world.lit_draw_sections._cached[key]
			distance = candidate_distance
	if chosen == null: failure = "No visible floor item for alpha transition"; return
	if self_alpha: chosen.self_modulate.a = value
	else: chosen.modulate.a = value

func _visible_floor_branches() -> Dictionary:
	var visible: Rect2 = world._visual_visible_rect(Vector2.ZERO)
	var result: Dictionary = {"interior":0,"previous":0,"next":0,"first_band":0,"floor_families":[0,0,0,0,0]}
	var first: Vector2i = world._world_to_cell(visible.position)
	var last: Vector2i = world._world_to_cell(visible.end)
	for y in range(maxi(0,first.y), mini(world.GRID_SIZE.y-1,last.y)+1):
		for x in range(maxi(0,first.x), mini(world.GRID_SIZE.x-1,last.x)+1):
			if not world._is_floor(Vector2i(x,y)): continue
			var local_y: float = fposmod((float(y)+.5)*world.TILE_SIZE,world.CHUNK_HEIGHT)
			var depth: int = world.window_start_depth + y / world.DeepLayout.CHUNK_ROWS
			result.floor_families[posmod(depth,5)] += 1
			if depth == 1: result.first_band += 1
			if depth != 1 and local_y < 200.0: result.previous += 1
			elif local_y > world.CHUNK_HEIGHT - 200.0: result.next += 1
			else: result.interior += 1
	return result

func _near_wall(anchor: Vector2) -> Vector2i:
	var center: Vector2i = world._world_to_cell(anchor)
	for radius in range(1,8):
		for y in range(center.y-radius,center.y+radius+1):
			for x in range(center.x-radius,center.x+radius+1):
				var cell: Vector2i = Vector2i(x,y)
				if not world._is_floor(cell) and world._cell_diggable(cell) and world._has_floor_neighbor(cell): return cell
	return Vector2i(-1,-1)

func _difference(a: Image, b: Image) -> Dictionary:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	if left == right: return {"changed_pixels":0,"max_channel_delta":0}
	var changed: int = 0
	var maximum: int = 0
	for pixel in range(0,left.size(),4):
		var peak: int = 0
		for channel in 4: peak = maxi(peak,absi(int(left[pixel+channel])-int(right[pixel+channel])))
		if peak > 0: changed += 1
		maximum = maxi(maximum,peak)
	return {"changed_pixels":changed,"max_channel_delta":maximum}

func _save() -> void:
	FileAccess.open(output.path_join("floor-blend-review.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"source_revision":source_revision,"world_sha256":FileAccess.get_sha256("res://scripts/world/endless_descent_world.gd"),
		"main_sha256":FileAccess.get_sha256("res://scripts/main.gd"),
		"shader_sha256":FileAccess.get_sha256("res://shaders/lit_biome_floor.gdshader"),
		"controller_sha256":FileAccess.get_sha256("res://tools/floor_blend_pilot/controller.gd"),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"pairs":pairs,"failure":failure,
		"scope":"quick-four" if quick_gate else "full-twenty-two",
		"renderer":RenderingServer.get_video_adapter_name(),"rendered":true,"physical_iphone":false,"adopted":false,
		"limit":"Same frozen A/B/A2 per state. Only the existing floor blend state differs. Explicit shader TIME lock, paused processing/tweens, and equal camera fixture settings are not gameplay FPS evidence. Identity parent exists equally in all modes to test actual inherited-alpha transitions."},"\t"))

func _finish() -> void:
	if failure.is_empty() and pairs.size() != (4 if quick_gate else 22): failure = "Incomplete fixture matrix"
	if is_instance_valid(controller): controller.candidate_enabled = false; controller._before_render()
	_save()
	print("FLOOR_BLEND_REVIEW_FINISHED pairs=",pairs.size()," failure=",failure)
	if failure.is_empty(): print("FLOOR_BLEND_REVIEW_COMPLETE")
	quit(0 if failure.is_empty() else 4)
