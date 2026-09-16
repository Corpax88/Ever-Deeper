extends SceneTree

const Candidate = preload("res://tools/shadow_contour_pilot/candidate.gd")
var output: String = ""
var initial_only: bool = false
var main: Node
var world: Node2D
var original: Node2D
var candidate: Node2D
var pairs: Array[Dictionary] = []
var failure: String = ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg == "--initial-only": initial_only = true
	if output.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	# This is the only production shader using TIME. Lock the shared resource
	# at one explicit phase for every A/B/A2 frame, without writing its file.
	var seal: Shader = load("res://shaders/lit_relic_seal.gdshader")
	seal.code = seal.code.replace("TIME", "0.0")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_endless(12)
	world = main.endless_world
	world.player.set_external_movement(Vector2.ZERO)
	for frame in 3: await process_frame
	# Freeze after the entry visuals have initialized, so texture warm-up cannot cause extra pet digging.
	_freeze(root)
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	for tween in get_processed_tweens(): tween.pause()
	paused = true
	Engine.time_scale = 0.0
	original = world.get_node("CaveLightOccluders")
	candidate = Candidate.new()
	candidate.name = "ContourStudy"
	world.add_child(candidate)
	candidate.set_process(false)
	candidate.hide()
	for frame in 8: await process_frame
	await _pair("deep12-initial")
	if not failure.is_empty() or initial_only: _finish(); return
	var hero_lamp: Node2D = world.player.get_node("PremiumHeadlamp")
	var pet: Node2D = world.get_node("MoleCompanion")
	var pet_lamp: Node2D = pet.get_node("PremiumHeadlamp")
	for lamp in [hero_lamp, pet_lamp]:
		lamp.preview_settings = {"style":"wide", "range_multiplier":1.4, "energy_multiplier":1.28}
		lamp.refresh_workshop_effects()
	for direction in [Vector2.RIGHT.rotated(0.21), Vector2.DOWN.rotated(0.017), Vector2.LEFT, Vector2.UP.rotated(-0.37)]:
		hero_lamp.set_direction(direction)
		pet_lamp.set_direction(direction.rotated(0.37))
		await _pair("deep12-aim-%d" % pairs.size())
		if not failure.is_empty(): _finish(); return
	pet.position = world.player.position + Vector2(840, 130)
	pet_lamp.configure(Color("ffe0a0"), Vector2.LEFT.rotated(0.37), 0.0, 440.0)
	for step in 2:
		pet.position += Vector2(world.TILE_SIZE + 0.5, 0)
		world.player.position += Vector2(0, world.TILE_SIZE + 0.5)
		world.player.camera.reset_smoothing()
		world.player.camera.force_update_scroll()
		await _pair("deep12-long-beam-crossing-%d" % step)
		if not failure.is_empty(): _finish(); return
	# Real wall depletion must update the same silhouette query.
	var target := Vector2i(-1, -1)
	var player_cell: Vector2i = world._world_to_cell(world.player.position)
	for y in range(player_cell.y - 6, player_cell.y + 7):
		for x in range(player_cell.x - 6, player_cell.x + 7):
			var cell := Vector2i(x, y)
			if world._is_floor(cell) or not world._cell_diggable(cell): continue
			for delta in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				if world._is_floor(cell + delta): target = cell; break
			if target.x >= 0: break
		if target.x >= 0: break
	if target.x < 0: failure = "No diggable boundary cell found"; _finish(); return
	world._break_diggable_cell(target)
	if not world._is_floor(target): failure = "Real depletion fixture did not excavate target"; _finish(); return
	_freeze(root)
	for tween in get_processed_tweens(): tween.pause()
	await _pair("deep12-real-depletion")
	_finish()

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _pair(label: String) -> void:
	original.refresh()
	candidate.refresh()
	var row: Dictionary = {"id":label, "original_count":original.active_count, "contour_count":candidate.active_count,
		"scanned_cells":original.scanned_cells, "contour_build_usec":candidate.contour_usec,
		"original_polygons":_polygons(original), "contour_polygons":_polygons(candidate)}
	print("CONTOUR_COUNTS " + JSON.stringify({"id":label,"original":original.active_count,"contours":candidate.active_count,"build_usec":candidate.contour_usec}))
	if candidate.active_count >= original.active_count:
		failure = "No caster-count reduction; timing skipped"
		pairs.append(row)
		return
	var pictures: Array[Image] = []
	for mode in [0, 1, 0]:
		original.visible = mode == 0
		candidate.visible = mode == 1
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		if picture.get_size() != Vector2i(1696,780):
			failure = "Actual framebuffer must be 1696x780"
			pairs.append(row)
			return
		picture.convert(Image.FORMAT_RGBA8)
		picture.save_png(output.path_join(label + "-" + ["A","B","A2"][pictures.size()] + ".png"))
		pictures.append(picture)
	row.candidate = _difference(pictures[0],pictures[1])
	row.restored = _difference(pictures[0],pictures[2])
	row.framebuffer = [1696,780]
	pairs.append(row)
	if row.restored.changed_pixels != 0: failure = "Restored control is unstable; no candidate conclusion or timing"
	elif row.candidate.changed_pixels != 0: failure = "Candidate pixel parity failed; timing skipped"
	print("CONTOUR_PAIR " + JSON.stringify({"id":label,"candidate":row.candidate,"restored":row.restored,"failure":failure}))

func _polygons(owner: Node) -> Array:
	var result: Array = []
	for index in owner.active_count:
		var points: Array = []
		for point: Vector2 in owner._pool[index].occluder.polygon: points.append([point.x,point.y])
		result.append(points)
	return result

func _difference(a: Image, b: Image) -> Dictionary:
	var left := a.get_data()
	var right := b.get_data()
	if left == right: return {"changed_pixels":0,"max_channel_delta":0}
	var changed := 0
	var maximum := 0
	for pixel in range(0,left.size(),4):
		var peak := 0
		for channel in 4: peak = maxi(peak,absi(int(left[pixel+channel])-int(right[pixel+channel])))
		if peak > 0: changed += 1
		maximum = maxi(maximum,peak)
	return {"changed_pixels":changed,"max_channel_delta":maximum}

func _finish() -> void:
	FileAccess.open(output.path_join("contour-review.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"physical_iphone":false,"adopted":false,"baseline":"c8906f1","renderer":RenderingServer.get_video_adapter_name(),
		"shader_time_lock":"lit_relic_seal TIME replaced in memory by 0.0 for all variants",
		"all_processes_frozen":true,"tweens_paused":true,"pairs":pairs,"failure":failure},"\t"))
	print("SHADOW_CONTOUR_REVIEW_COMPLETE " + JSON.stringify({"pairs":pairs.size(),"failure":failure}))
	quit(0 if failure.is_empty() else 4)
