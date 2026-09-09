extends "review_mining_receivers.gd"
## External exact-package visual check; saved excavation comes from real held input.
## Gate strikes use the real world mining owner with accelerated fixture timing.
var saved_before := ""
var saved_after := ""
var evidence: Array[Dictionary] = []
var package_hash := ""

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.trim_prefix("--output=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		elif arg.begins_with("--save-before="): saved_before = arg.trim_prefix("--save-before=")
		elif arg.begins_with("--save-after="): saved_after = arg.trim_prefix("--save-after=")
		else: _reject("Unknown argument"); return
	if not OS.has_feature("ever_deeper_dev") or DisplayServer.get_name() == "headless" or not FileAccess.file_exists("res://project.binary"):
		_reject("Rendered immutable DEV PCK required"); return
	for path in [output_dir,pack_source,saved_before,saved_after]:
		if not String(path).is_absolute_path(): _reject("Absolute paths required"); return
	package_hash = FileAccess.get_sha256(pack_source)
	if package_hash != "6ec691604a060bcad3a21ac2666385e3d1a0c0ac07822c6b74c2a31e33dc5d6d":
		_reject("Wrong final PCK"); return
	DirAccess.make_dir_recursive_absolute(output_dir)
	seconds = 0.5 # visual settling only, not a frame-time benchmark
	state = root.get_node("RunState")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	state.initialize_persistence(output_dir.path_join("isolated-save.json"))
	main._dev_ensure_playing()
	if not await _restore(saved_after): return
	var corner := Vector2i(-1,-1)
	for cell in world.blocks:
		if world._block_emits_mineable_corner(world.blocks[cell],world._mineable_edge_open_sides(cell)):
			corner = cell
			break
	if corner.x < 0 or not _place_near(world._cell_center(corner)):
		_reject("Actual excavation must contain a visible mineable corner"); return
	await _fixture_lights(1)
	if int(_coverage().get("visible_mineable_corners",0)) <= 0:
		_reject("Mined corner not in framebuffer"); return
	evidence.append({"fixture":"saved-actual-mined-corner","cell":[corner.x,corner.y],"coverage":_coverage(),"save_sha256":FileAccess.get_sha256(saved_after)})
	await _triplet("ember-actual-mined-corner")
	# Inspect both gate states from actual sustained excavation, including the new floor.
	for value in world.mine.barriers:
		var barrier: Dictionary = value
		if world._role_has_blocks(String(barrier.id)):
			_reject("Actual sustained run did not clear " + String(barrier.id)); return
		if not _place_near(_barrier_center(barrier)): _reject("Broken gate camera unreachable"); return
		await _fixture_lights(0)
		evidence.append({"fixture":"saved-broken-gate","gate":barrier.id,"coverage":_coverage()})
		await _triplet(String(barrier.id)+"-actual-broken")
	if not await _restore(saved_before): return
	var gate: Dictionary = world.mine.barriers[0]
	if not world._role_has_blocks(String(gate.id)) or not _place_near(_barrier_center(gate)):
		_reject("Initial gate must be intact and in view"); return
	await _fixture_lights(0)
	await _triplet(String(gate.id)+"-intact")
	var gate_target := Vector2i(-1,-1)
	for cell in world.blocks:
		if String(world.blocks[cell].get("role","")) == String(gate.id): gate_target = cell; break
	if gate_target.x < 0: _reject("Missing real gate target"); return
	var progress_key: String = "emberMine:d1:" + String(gate.id)
	var hits_before: int = state.barrier_hits(progress_key)
	world.current_target = gate_target
	world._mine_once()
	world.queue_redraw()
	if int(state.barrier_hits(progress_key)) != hits_before+1:
		_reject("Real mining owner did not advance gate damage"); return
	await _fixture_lights(0)
	evidence.append({"fixture":"actual-struck-gate","gate":gate.id,"hits_before":hits_before,"hits_after":state.barrier_hits(progress_key)})
	await _triplet(String(gate.id)+"-struck")
	if FileAccess.get_sha256(pack_source) != package_hash: _reject("PCK changed"); return
	var result: Dictionary = {"pack_sha256":package_hash,"harness_sha256":FileAccess.get_sha256(get_script().resource_path),"base_harness_sha256":FileAccess.get_sha256(get_script().resource_path.get_base_dir().path_join("review_mining_receivers.gd")),"physical_iphone":false,"frame_time_benchmark":false,"evidence":evidence,"stages":rows,"failures":failures,"limits":"Saved corner/broken gates arise from real sustained controls; struck gate uses real mining damage with accelerated fixture timing. Same-package broad/narrow/restored visual comparison only."}
	FileAccess.open(output_dir.path_join("d1-excavation.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("D1_EXCAVATION_REVIEW_COMPLETE "+JSON.stringify({"stages":rows.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 2)

func _restore(path: String) -> bool:
	# Capture/deactivate the old mine against its matching state before loading
	# a different recorded fixture; otherwise its cache can match the wrong save.
	main._cancel_held_input()
	main._dev_jump_surface()
	if not FileAccess.file_exists(path) or not state.deserialize(JSON.parse_string(FileAccess.get_file_as_string(path))):
		_reject("Failed to restore recorded actual gameplay state"); return false
	if not main._dev_jump_mine("emberMine",1): _reject("Mine entry failed"); return false
	world = main.mine_world
	await _settle(1.0)
	return true

func _place_near(point: Vector2) -> bool:
	var best := Vector2(INF,INF)
	var best_distance := INF
	var center: Vector2i = world._world_to_cell(point)
	for y in range(center.y-8,center.y+9):
		for x in range(center.x-8,center.x+9):
			var cell := Vector2i(x,y)
			if world.blocks.has(cell): continue
			var position: Vector2 = world._cell_center(cell)
			if world._player_collides(position): continue
			var distance: float = position.distance_squared_to(point)
			if distance < best_distance: best_distance = distance; best = position
	if not is_finite(best.x): return false
	world.restore_position(best)
	world.player.set_facing((point-best).normalized())
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	return world.player.global_position.distance_to(best) < 1.0 and world._visual_visible_rect(Vector2.ZERO).grow(-50.0).has_point(point)

func _barrier_center(barrier: Dictionary) -> Vector2:
	return Vector2(float(barrier.x)+float(barrier.w)*0.5,float(barrier.y)+float(barrier.h)*0.5)

func _reject(message: String) -> void:
	push_error("D1_EXCAVATION_REVIEW_FAIL "+message)
	quit(2)
