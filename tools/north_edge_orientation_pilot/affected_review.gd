extends "res://tools/north_edge_orientation_pilot/review.gd"
## Seven affected poses only. The already reviewed held pair is read, not rerun.
const REQUIRED_CASES: Array[String] = ["approach", "contact-strong", "struck", "mined-opening", "short-steps-grazing", "boundary-13-14", "boundary-14-15"]
const WALL := Vector2i(13, 27)
var retained_output: String = "/workspace/scratch/d5437d917805/evidence/north-edge-orientation-moss"
var held_reference: Dictionary = {}
var completed: Array[Dictionary] = []
var phase_coverage: Dictionary = {}
var movement_samples: Array[Dictionary] = []
var mutations: Array[Dictionary] = []
var saved_light_workshop: Dictionary = {}
var saved_light_relic: Dictionary = {}

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--source-revision="): source_revision = arg.trim_prefix("--source-revision=")
		elif arg.begins_with("--retained-output="): retained_output = arg.trim_prefix("--retained-output=")
		else: _reject("Unknown argument: " + arg); return
	if not output.is_absolute_path() or output == retained_output or not retained_output.is_absolute_path() or source_revision.length() != 40 or not source_revision.is_valid_hex_number():
		_reject("Use separate absolute output/retained paths and the exact checkpoint revision"); return
	if DisplayServer.get_name() == "headless": _reject("A rendered framebuffer is required"); return
	if DirAccess.make_dir_recursive_absolute(output) != OK: _reject("Cannot create output directory"); return
	report_ready = true
	if not _verify_retained_evidence(): return
	seal = load("res://shaders/lit_relic_seal.gdshader")
	original_seal_code = seal.code
	seal.code = original_seal_code.replace("TIME", "0.0")
	original_time_scale = Engine.time_scale
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load("res://tools/north_edge_orientation_pilot/deep_candidate.gd"))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = SEED
	seed(SEED)
	if not main._dev_jump_endless(DEPTH): _reject("Cannot enter Deep14"); return
	world = main.endless_world
	state.set_drill_level(1)
	state.set_starforge_variant("")
	world.player.set_external_movement(Vector2.ZERO)
	world.player.prepare_visual_cache()
	await create_timer(4.0).timeout
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.drag_horizontal_enabled = false
	world.player.camera.drag_vertical_enabled = false
	world.lit_draw_sections.profile_draws = true
	_freeze()
	if not _verify_topology(): return
	if not _place(Vector2(864.0, 1632.0), Vector2.DOWN): return
	if not _drive_down(6): return
	var clearance: float = float(WALL.y) * world.TILE_SIZE - world.player.position.y
	if clearance <= world.PLAYER_RADIUS + 12.0 or movement_samples.size() < 6:
		_reject("Approach did not retain clear floor before contact"); return
	if not await _capture_case("approach", [WALL], {"wall":_cell_review_rect(WALL)}, {"clearance":clearance, "owner":"player._physics_process -> world._resolve_motion"}): return
	if not _drive_down(40): return
	clearance = float(WALL.y) * world.TILE_SIZE - world.player.position.y
	if bool(world.player._actual_moving) or absf(clearance - float(world.PLAYER_RADIUS)) > 0.2:
		_reject("The real controller did not stop outside the north wall"); return
	if not _set_max_light_fixture(): return
	if not await _capture_case("contact-strong", [WALL], {"wall":_cell_review_rect(WALL)}, {"clearance":clearance, "max_light_lab_fixture":true}): return
	if world._nearest_resource_index() >= 0 or world._nearest_diggable_wall() != WALL:
		_reject("Actual held mining would select a different target"); return
	var before_damage: int = int(world.dig_damage.get(WALL, 0))
	world.set_mine_held(true)
	world._update_mining(world._mining_cycle_duration() * (world.MINING_HIT_PROGRESS + 0.01))
	if world._is_floor(WALL) or int(world.dig_damage.get(WALL, 0)) <= before_damage or world._swing_wall != WALL:
		_reject("The production mining clock did not strike and retain the wall"); return
	mutations.append({"owner":"_update_mining -> _strike_wall", "cell":str(WALL), "damage_before":before_damage, "damage_after":int(world.dig_damage[WALL])})
	if not await _capture_case("struck", [WALL], {"wall":_cell_review_rect(WALL)}, {"damage":int(world.dig_damage[WALL]), "committed_target":world.mining_target_id}): return
	for tick in 16:
		if world._is_floor(WALL): break
		if world._swing_wall != WALL: _reject("Mining changed target before the opening"); return
		world._update_mining(world._mining_cycle_duration() * 0.51)
	if not world._is_floor(WALL) or world.dig_damage.has(WALL): _reject("Real mining did not excavate the target"); return
	mutations.append({"owner":"_update_mining -> _strike_wall -> _break_diggable_cell", "cell":str(WALL), "now_floor":true})
	var revealed: Vector2i = WALL + Vector2i.DOWN
	if not _north_edge(revealed): _reject("Excavation did not reveal the required new Moss north edge"); return
	if not await _capture_case("mined-opening", [revealed], {"opening":_cell_review_rect(WALL).merge(_cell_review_rect(revealed))}, {"excavated_cell":str(WALL), "new_north_cell":str(revealed)}): return
	world.set_mine_held(false)
	if not _place(Vector2(864.0, 1696.0), Vector2.RIGHT): return
	var steps: Array[Vector2i] = [Vector2i(16, 27), Vector2i(17, 28), Vector2i(18, 29)]
	for cell in steps:
		if not _north_edge(cell): _reject("The retained one-cell stair changed"); return
	var lamp: Node2D = world.player.get_node("PremiumHeadlamp")
	var ray: Vector2 = Vector2(1056.0, 1728.0) - lamp.global_position
	var grazing_angle: float = absf(Vector2.RIGHT.angle_to(ray.normalized()))
	if grazing_angle < 0.25 or grazing_angle > 0.52: _reject("The north rim is not in the grazing cone"); return
	if not await _capture_case("short-steps-grazing", [steps[0], steps[1]], {"steps":Rect2(Vector2(960, 1600), Vector2(384, 384))}, {"step_cells":str(steps), "grazing_angle_radians":grazing_angle, "max_light_lab_fixture":true}): return
	_restore_light_fixture()
	if not await _boundary_case(false): return
	if not await _boundary_case(true): return
	if completed.size() != REQUIRED_CASES.size(): _reject("Affected-state case count is incomplete"); return
	for phase in 8:
		if not phase_coverage.has(str(phase)): _reject("Missing actual changed pixels for source phase " + str(phase)); return
	if not _save_report(): _reject("Cannot write final affected-state report"); return
	_restore_controls()
	print("NORTH_EDGE_AFFECTED_REVIEW_COMPLETE " + JSON.stringify({"cases":completed.size(), "source_phases":phase_coverage.keys(), "failures":failures, "visual_approval":false}))
	quit()

func _verify_retained_evidence() -> bool:
	held_reference = JSON.parse_string(FileAccess.get_file_as_string("res://tools/north_edge_orientation_pilot/retained_held_evidence.json"))
	if held_reference.is_empty(): _reject("Missing retained evidence identity"); return false
	for path in held_reference.protected_sources:
		if FileAccess.get_sha256(path) != String(held_reference.protected_sources[path]):
			_reject("Protected production/candidate source changed: " + path); return false
	for name in held_reference.files_sha256:
		if FileAccess.get_sha256(retained_output.path_join(name)) != String(held_reference.files_sha256[name]):
			_reject("Retained held evidence changed: " + name); return false
	var a: Image = Image.load_from_file(retained_output.path_join("moss-north-held-A.png"))
	var b: Image = Image.load_from_file(retained_output.path_join("moss-north-held-B.png"))
	a.convert(Image.FORMAT_RGBA8)
	b.convert(Image.FORMAT_RGBA8)
	for item in held_reference.phase_samples:
		var r: Array = item.inset_roi_xywh
		var count: int = _changed_in_rect(a.get_data(), b.get_data(), a.get_width(), Rect2i(r[0], r[1], r[2], r[3]))
		if count <= 0 or count != int(item.changed_rgba_pixels): _reject("Retained phase pixels do not match the originals"); return false
		phase_coverage[str(item.phase)] = {"case":"retained-held", "cell":item.cell, "changed_rgba_pixels":count}
	return true

func _place(point: Vector2, direction: Vector2) -> bool:
	if not world._position_walkable(point) or world.depth_at_position(point) != DEPTH:
		_reject("Fixture placement is blocked or outside Moss14: " + str(point)); return false
	world.player.set_external_movement(Vector2.ZERO)
	world.restore_position(point)
	if not world.player.position.is_equal_approx(point): _reject("Fixture placement was clamped"); return false
	world.player._physics_process(1.0 / 60.0)
	world.player.set_facing(direction)
	return true

func _drive_down(ticks: int) -> bool:
	world.player.set_external_movement(Vector2.DOWN)
	var started: Vector2 = world.player.position
	for tick in ticks:
		world.player._physics_process(1.0 / 60.0)
		if not world._position_walkable(world.player.position): _reject("Controller entered wall/prop collision"); return false
		movement_samples.append({"position":str(world.player.position), "moving":world.player._actual_moving, "tick_seconds":1.0 / 60.0})
	if ticks == 6 and world.player.position.distance_to(started) < 20.0:
		_reject("Actual approach did not move far enough"); return false
	return true

func _set_max_light_fixture() -> bool:
	var relic_id: String = state._relic_id_for_workshop("light_lab")
	saved_light_workshop = Dictionary(state.endless_workshops.light_lab).duplicate(true)
	saved_light_relic = Dictionary(state.endless_relics[relic_id]).duplicate(true)
	# Explicit isolated loadout fixture; do not pretend this is a purchase test.
	state.endless_relics[relic_id]["placed"] = true
	state.endless_workshops.light_lab["built"] = true
	state.endless_workshops.light_lab["level"] = 5
	state._state_changed()
	_refresh_lamps()
	var lamp: Node = world.player.get_node("PremiumHeadlamp")
	if not is_equal_approx(lamp.effective_energy_multiplier, 1.3) or not is_equal_approx(lamp.effective_range_multiplier, 1.4):
		_reject("The production headlamp did not apply level5"); return false
	return true

func _restore_light_fixture() -> void:
	state.endless_workshops.light_lab = saved_light_workshop.duplicate(true)
	state.endless_relics[state._relic_id_for_workshop("light_lab")] = saved_light_relic.duplicate(true)
	state._state_changed()
	_refresh_lamps()

func _refresh_lamps() -> void:
	for node in world.find_children("*", "Node", true, false):
		if node.has_method("refresh_workshop_effects"): node.refresh_workshop_effects()

func _settle_camera() -> void:
	# Advance the unchanged camera owner, without manufacturing offset/zoom.
	for tick in 90: world.player.camera._physics_process(1.0 / 60.0)
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()

func _cell_review_rect(cell: Vector2i) -> Rect2:
	return Rect2(Vector2(cell) * world.TILE_SIZE - Vector2.ONE * 64.0, Vector2.ONE * 192.0)

func _boundary_case(next: bool) -> bool:
	var seam_depth: int = 15 if next else 14
	var seam_y: float = float(seam_depth - world.window_start_depth) * world.CHUNK_HEIGHT
	var column: int = world.DeepLayout.entrance_column(SEED, seam_depth)
	var point := Vector2(float(column) * 64.0 + 32.0, seam_y + (-32.0 if next else 32.0))
	if not _place(point, Vector2.DOWN): return false
	_settle_camera()
	var transform: Transform2D = world.get_global_transform_with_canvas()
	var visible: Rect2 = root.get_visible_rect().grow(-32.0)
	var chosen := Vector2i(-1, -1)
	var best: float = INF
	for y in range(22, 44):
		for x in range(2, 38):
			var cell := Vector2i(x, y)
			if not _north_edge(cell) or not visible.encloses(transform * _cell_review_rect(cell)): continue
			var score: float = absf(float(y) * 64.0 - seam_y) + absf(float(x - column)) * 8.0
			if score < best: best = score; chosen = cell
	if chosen.x < 0: _reject("No visible affected Moss north edge beside the biome boundary"); return false
	var seam_rect := Rect2(Vector2(point.x - 96.0, seam_y - 96.0), Vector2(192.0, 192.0))
	return await _capture_case("boundary-14-15" if next else "boundary-13-14", [chosen], {"biome_join":seam_rect, "moss_north_edge":_cell_review_rect(chosen)}, {"boundary_depths":[14, 15] if next else [13, 14], "seam_world_y":seam_y, "fixture_teleport_to_native_seam_corridor":true, "stream_rebase":false})

func _capture_case(id: String, required_cells: Array[Vector2i], regions_world: Dictionary, details: Dictionary) -> bool:
	for cell in required_cells:
		if not _north_edge(cell): _reject("Required cell is not an exposed Moss north edge: " + str(cell)); return false
	_settle_camera()
	# Drain deferred reward/UI work before freezing this new state. Refresh
	# actual camera light culling once, never between A/B/A2 controls.
	for frame in 2: await process_frame
	world._update_resource_pulses()
	world.player._update_visual(bool(world.player._actual_moving))
	world.player.visual._draw_frame(0.0)
	_freeze()
	world.get_node("CaveLightOccluders").refresh()
	var geometry: int = _geometry_fingerprint()
	var save_name: String = id + "-state.json"
	var save: FileAccess = FileAccess.open(output.path_join(save_name), FileAccess.WRITE)
	if save == null: _reject("Cannot save case state"); return false
	save.store_string(JSON.stringify(state.serialize()))
	save.close()
	pair = {"id":id, "details":details, "player":str(world.player.position), "facing":str(world.player.facing_vector), "headlamp":world.player.get_node("PremiumHeadlamp").debug_snapshot(), "state_file":save_name, "state_sha256":FileAccess.get_sha256(output.path_join(save_name)), "required_cells":str(required_cells), "captures":[]}
	var pictures: Array[Image] = []
	var reference_view: Array = []
	var north_regions: Array[Dictionary] = []
	for mode in [false, true, false]:
		world.north_edge_study_enabled = mode
		world.study_north_draw_calls = 0
		world.study_north_drawn_cells.clear()
		for section in world.lit_draw_sections._cached.values(): section.revision = -1
		var callbacks: int = world.lit_draw_sections.draw_callbacks
		world.queue_redraw()
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		if _geometry_fingerprint() != geometry or not world._position_walkable(world.player.position): _reject("Geometry or safe hero placement changed in " + id); return false
		if world.lit_draw_sections.draw_callbacks <= callbacks: _reject("Terrain was not freshly redrawn in " + id); return false
		if mode:
			for cell in required_cells:
				if not world.study_north_drawn_cells.has(cell): _reject("B did not draw a required cell in " + id); return false
		elif world.study_north_draw_calls != 0: _reject("A control entered the candidate branch"); return false
		var viewport: Rect2 = root.get_visible_rect()
		var canvas: Transform2D = world.get_global_transform_with_canvas()
		var camera: Camera2D = world.player.camera
		var culling: Rect2 = world._visual_visible_rect(Vector2.ONE * world.TILE_SIZE * 3.0)
		if not world.last_draw_camera_center.is_equal_approx(camera.get_screen_center_position()) or not world.last_draw_viewport_size.is_equal_approx(viewport.size) or not world.last_draw_camera_zoom.is_equal_approx(camera.zoom.abs()): _reject("Camera/culling mismatch in " + id); return false
		if _camera_limits() != [0, 0, 2560, 4224] or not camera.zoom.is_equal_approx(Vector2.ONE) or root.content_scale_size != Vector2i(1280, 720): _reject("Production camera/content settings changed"); return false
		var view: Array = [viewport, canvas, camera.get_screen_center_position(), camera.zoom, _camera_limits(), culling]
		if not reference_view.is_empty() and reference_view != view: _reject("View changed within " + id); return false
		reference_view = view
		var picture: Image = root.get_texture().get_image()
		if picture.get_size() != Vector2i(1696, 780): _reject("Unexpected native framebuffer"); return false
		picture.convert(Image.FORMAT_RGBA8)
		var scale: Vector2 = Vector2(picture.get_size()) / viewport.size
		var regions: Dictionary = {}
		for key in regions_world:
			var r: Rect2 = regions_world[key]
			var presented: Rect2 = canvas * r
			if not viewport.encloses(presented) or not culling.encloses(r): _reject("Required region outside viewport/culling: " + id + "/" + key); return false
			regions[key] = {"world":str(r), "framebuffer":str(Rect2((presented.position - viewport.position) * scale, presented.size * scale))}
		if mode:
			for cell in world.study_north_drawn_cells:
				var quad := Rect2(Vector2(cell) * 64.0 + Vector2(0.0, -64.0 * 10.0 / 48.0), Vector2.ONE * 64.0)
				var presented: Rect2 = canvas * quad
				var native := Rect2((presented.position - viewport.position) * scale, presented.size * scale)
				var start: Vector2i = Vector2i(native.position.ceil()) + Vector2i.ONE
				var end: Vector2i = Vector2i(native.end.floor()) - Vector2i.ONE
				north_regions.append({"cell":cell, "phase":posmod(-cell.x + DEPTH % 11, 8), "native":native, "inset":Rect2i(start, end - start), "fully_visible":viewport.encloses(presented)})
		var filename: String = id + "-" + ["A", "B", "A2"][pictures.size()] + ".png"
		if picture.save_png(output.path_join(filename)) != OK: _reject("Cannot save " + filename); return false
		pair.captures.append({"filename":filename, "sha256":FileAccess.get_sha256(output.path_join(filename)), "candidate":mode, "camera":str(camera.get_screen_center_position()), "viewport":str(viewport), "culling":str(culling), "regions":regions, "candidate_draw_calls":world.study_north_draw_calls, "redrawn_sections":world.lit_draw_sections.draw_callbacks - callbacks})
		pictures.append(picture)
		if not _save_report(): _reject("Cannot preserve capture report"); return false
	pair["restored_diff"] = _difference(pictures[0], pictures[2])
	pair["candidate_diff"] = _difference(pictures[0], pictures[1])
	pair["geometry_fingerprint"] = geometry
	if int(pair.restored_diff.changed_rgba_pixels) != 0: _reject("A/A2 restoration mismatch in " + id); return false
	if not _gate_north_pixels(pictures[0], pictures[1], north_regions, required_cells, id): return false
	completed.append(pair.duplicate(true))
	if not _save_report(): _reject("Cannot preserve completed case"); return false
	print("NORTH_EDGE_AFFECTED_PAIR " + JSON.stringify({"id":id, "candidate_diff":pair.candidate_diff, "restored_diff":pair.restored_diff}))
	return true

func _gate_north_pixels(a: Image, b: Image, north: Array[Dictionary], required: Array[Vector2i], id: String) -> bool:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	var allowed: PackedByteArray = []
	allowed.resize(a.get_width() * a.get_height())
	allowed.fill(0)
	var frame := Rect2i(Vector2i.ZERO, a.get_size())
	var evidence: Array[Dictionary] = []
	var changed_cells: Dictionary = {}
	for record in north:
		var native: Rect2 = record.native
		var start: Vector2i = Vector2i(native.position.floor()) - Vector2i.ONE * 2
		var end: Vector2i = Vector2i(native.end.ceil()) + Vector2i.ONE * 2
		var bounds: Rect2i = Rect2i(start, end - start).intersection(frame)
		for y in range(bounds.position.y, bounds.end.y):
			for x in range(bounds.position.x, bounds.end.x): allowed[y * a.get_width() + x] = 1
		if not bool(record.fully_visible): continue
		var roi: Rect2i = record.inset
		var count: int = _changed_in_rect(left, right, a.get_width(), roi)
		evidence.append({"cell":str(record.cell), "phase":record.phase, "inset_framebuffer":str(roi), "changed_rgba_pixels":count})
		if count > 0:
			changed_cells[record.cell] = count
			phase_coverage[str(record.phase)] = {"case":id, "cell":str(record.cell), "changed_rgba_pixels":count}
	var outside: int = 0
	for pixel in allowed.size():
		if allowed[pixel] != 0: continue
		var offset: int = pixel * 4
		if left[offset] != right[offset] or left[offset + 1] != right[offset + 1] or left[offset + 2] != right[offset + 2] or left[offset + 3] != right[offset + 3]: outside += 1
	pair["affected_cell_pixels"] = evidence
	pair["changed_pixels_outside_moss_north_quads_plus_2px"] = outside
	if outside != 0: _reject("Pixels changed outside eligible north quads in " + id); return false
	for cell in required:
		if not changed_cells.has(cell): _reject("No actual changed north pixels for required cell " + str(cell) + " in " + id); return false
	return true

func _changed_in_rect(left: PackedByteArray, right: PackedByteArray, width: int, region: Rect2i) -> int:
	var count: int = 0
	for y in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var i: int = (y * width + x) * 4
			if left[i] != right[i] or left[i + 1] != right[i + 1] or left[i + 2] != right[i + 2] or left[i + 3] != right[i + 3]: count += 1
	return count

func _save_report() -> bool:
	if not report_ready: return true
	var hashes: Dictionary = {}
	for path in IDENTITY_PATHS: hashes[path] = FileAccess.get_sha256(path)
	for path in [get_script().resource_path, "res://tools/north_edge_orientation_pilot/retained_held_evidence.json"]: hashes[path] = FileAccess.get_sha256(path)
	var report: Dictionary = {"base_revision":BASE_REVISION, "source_revision":source_revision, "files_sha256":hashes, "scope":"seven affected states; held pair reused", "required_cases":REQUIRED_CASES, "completed_cases":completed, "current_pair":pair, "retained_evidence":held_reference, "retained_output":retained_output, "actual_changed_phase_coverage":phase_coverage, "movement_samples":movement_samples, "terrain_mutations":mutations, "failures":failures, "visual_approval":false, "performance_evidence":false, "physical_iphone":false, "limits":"Fixed-step real controller/mining owners and labelled valid-floor/loadout fixtures. Original full PNGs require independent review. This unchanged orientation candidate does not solve short corners, author new art or establish FPS."}
	var file: FileAccess = FileAccess.open(output.path_join("north-edge-affected.json"), FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true
