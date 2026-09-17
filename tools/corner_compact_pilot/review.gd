extends SceneTree
## Opt-in A/B/A2 study of authored corner footprint, not a parity optimization.
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const CORNER_OFFSETS: Array[Vector2i] = [Vector2i(1, 0), Vector2i.ONE, Vector2i(0, 1), Vector2i.ZERO]
const BASE_REVISION: String = "fec3185e7aa78b644bfa1c1ddc2ebd5cd10b5cd3"
var output: String = ""
var area: String = "deep"
var depth: int = 14 # Moss's broad elbow is the first risk to inspect.
var mine_id: String = "mossMine"
var scope: String = "smoke"
var main: Node
var world: Node
var state: Node
var pairs: Array[Dictionary] = []
var mutations: Array[Dictionary] = []
var failures: Array[String] = []
var source_revision: String = BASE_REVISION

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--area="): area = arg.trim_prefix("--area=")
		elif arg.begins_with("--depth="): depth = int(arg.trim_prefix("--depth="))
		elif arg.begins_with("--mine="): mine_id = arg.trim_prefix("--mine=")
		elif arg.begins_with("--scope="): scope = arg.trim_prefix("--scope=")
		elif arg.begins_with("--source-revision="): source_revision = arg.trim_prefix("--source-revision=")
		else: _reject("Unknown argument: " + arg); return
	if not output.is_absolute_path() or area not in ["deep", "d2"] or scope not in ["smoke", "matrix"] or depth < 2:
		_reject("Use an absolute output path, deep/d2, smoke/matrix and depth >= 2"); return
	if DisplayServer.get_name() == "headless": _reject("An actual rendered framebuffer is required"); return
	DirAccess.make_dir_recursive_absolute(output)
	# Same clock lock as the existing camera study, in memory in both variants.
	var seal: Shader = load("res://shaders/lit_relic_seal.gdshader")
	seal.code = seal.code.replace("TIME", "0.0")
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load("res://tools/corner_compact_pilot/deep_candidate.gd"))
	main.get_node("RootwoundWorld").set_script(load("res://tools/corner_compact_pilot/depth_candidate.gd"))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	var entered: bool = main._dev_jump_endless(depth) if area == "deep" else main._dev_jump_mine(mine_id, 2)
	if not entered: _reject("Cannot enter the requested production world"); return
	world = main.endless_world if area == "deep" else main.depth_world
	# A real unlocked tool whose one hit leaves Deep/D2 terrain intact.
	state.set_drill_level(1)
	state.set_starforge_variant("")
	world.player.set_external_movement(Vector2.ZERO)
	world.player.prepare_visual_cache()
	await create_timer(4.0).timeout
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	# Deterministic positioning; retain native zoom, content size and all limits.
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.drag_horizontal_enabled = false
	world.player.camera.drag_vertical_enabled = false
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.lit_draw_sections.profile_draws = true
	_freeze()
	if not await _pair("generated-arrival", world.player.position, {"origin":"native generated layout"}): return
	var convex: Vector2i = _nearest_generated_convex()
	if convex.x < 0: _reject("No actual generated mineable convex corner"); return
	if not await _case("generated-convex", convex, {"origin":"native generated layout", "open_sides":_open_sides(convex)}): return
	if scope == "smoke": _finish(); return
	if not await _excavation_matrix(): return
	if not await _permanent_boundary(): return
	if area == "deep" and not await _stream_matrix(): return
	_finish()

func _excavation_matrix() -> bool:
	# Begin with an actual solid, resource-free 9x9 patch bordering clear floor.
	# Only companion_dig opens it; no geometry, HP or save arrays are fabricated.
	var patch: Dictionary = _find_patch()
	if patch.is_empty(): _reject("No eligible actual 9x9 excavation patch; fixture coverage incomplete"); return false
	var origin: Vector2i = patch.origin
	if not _dig_cells([patch.entry]): return false
	var ring: Array[Vector2i] = []
	for y in range(1, 8):
		for x in range(1, 8):
			if x in [1, 7] or y in [1, 7]: ring.append(origin + Vector2i(x, y))
	if not _dig_cells(ring): return false
	var convex_cells: Array[Vector2i] = [Vector2i(6, 2), Vector2i(6, 6), Vector2i(2, 6), Vector2i(2, 2)]
	var concave_cells: Array[Vector2i] = [Vector2i(7, 1), Vector2i(7, 7), Vector2i(1, 7), Vector2i(1, 1)]
	var straight_cells: Array[Vector2i] = [Vector2i(4, 2), Vector2i(6, 4), Vector2i(4, 6), Vector2i(2, 4)]
	for corner in 4:
		var convex_cell: Vector2i = origin + convex_cells[corner]
		var concave_cell: Vector2i = origin + concave_cells[corner]
		if _vertex_solid_count(convex_cell + CORNER_OFFSETS[corner]) != 1 or _vertex_solid_count(concave_cell + CORNER_OFFSETS[corner]) != 3:
			_reject("Excavated ring did not produce the required convex/concave topology"); return false
		if not await _case("excavated-convex-%d" % corner, convex_cell, {"origin":"real companion excavation", "corner":corner, "vertex_solid_count":1}): return false
		if not await _case("excavated-concave-%d" % corner, concave_cell, {"origin":"real companion excavation", "corner":corner, "vertex_solid_count":3}): return false
		var straight: Vector2i = origin + straight_cells[corner]
		if _open_sides(straight).count(true) != 1: _reject("Missing straight edge"); return false
		if not await _case("excavated-straight-%d" % corner, straight, {"origin":"real companion excavation", "side":corner}): return false
	var kept: Array[Vector2i] = [origin + Vector2i(3, 2), origin + Vector2i(3, 3), origin + Vector2i(4, 3), origin + Vector2i(4, 4), origin + Vector2i(5, 4)]
	var remove: Array[Vector2i] = []
	for y in range(2, 7):
		for x in range(2, 7):
			var cell: Vector2i = origin + Vector2i(x, y)
			if cell not in kept: remove.append(cell)
	if not _dig_cells(remove): return false
	var pillar: Vector2i = origin + Vector2i(4, 3)
	if not await _case("excavated-one-cell-zigzag", pillar, {"origin":"real companion excavation", "retained_cells":str(kept)}): return false
	kept.erase(pillar)
	if not _dig_cells(kept): return false
	if _open_sides(pillar).count(true) != 4: _reject("Pillar must expose all four sides"); return false
	if not await _case("excavated-one-cell-pillar", pillar, {"origin":"real companion excavation", "open_sides":_open_sides(pillar)}): return false
	var damage_before: int = _terrain_health(pillar)
	if area == "deep": world._strike_wall(pillar, .66)
	else:
		world.current_target_kind = "terrain"
		world.current_target_cell = pillar
		if not world._hit_terrain(pillar): _reject("Real wall strike was rejected"); return false
	if not _solid(pillar) or _terrain_health(pillar) >= damage_before:
		_reject("Real strike must damage and retain the pillar"); return false
	mutations.append({"owner":"_strike_wall" if area == "deep" else "_hit_terrain", "cell":str(pillar), "health_before":damage_before, "health_after":_terrain_health(pillar)})
	if not await _case("struck-one-cell-pillar", pillar, {"origin":"real mining damage", "health":_terrain_health(pillar)}): return false
	if not _dig_cells([pillar]): return false
	if not await _case("excavated-pillar-floor", pillar, {"origin":"real companion excavation", "floor":not _solid(pillar)}): return false
	return true

func _find_patch() -> Dictionary:
	var result: Dictionary = {}
	var best: float = INF
	var bounds: Rect2i = _active_bounds()
	for y in range(bounds.position.y + 1, bounds.end.y - 9):
		for x in range(3, bounds.end.x - 10):
			var origin := Vector2i(x, y)
			var score: float = world._cell_center(origin + Vector2i(4, 4)).distance_squared_to(world.player.position)
			if score >= best: continue
			var entry: Vector2i = Vector2i(-1, -1)
			for side in 4:
				for offset in range(2, 7):
					var edge: Vector2i = [Vector2i(offset, 0), Vector2i(8, offset), Vector2i(offset, 8), Vector2i(0, offset)][side]
					var outside: Vector2i = origin + edge + DIRECTIONS[side]
					if _walkable(world._cell_center(outside)) and world.companion_can_dig(world._cell_center(origin + edge)):
						entry = origin + edge
			if entry.x < 0: continue
			var valid: bool = true
			for py in 9:
				for px in 9:
					var cell: Vector2i = origin + Vector2i(px, py)
					if not _can_excavate(cell) or not _physical_solid(cell): valid = false; break
				if not valid: break
			if valid: result = {"origin":origin, "entry":entry}; best = score
	return result

func _dig_cells(cells: Array) -> bool:
	var pending: Array = cells.duplicate()
	while not pending.is_empty():
		var progressed: bool = false
		for value in pending.duplicate():
			var cell: Vector2i = value
			if not _solid(cell): pending.erase(value); progressed = true; continue
			if not world.companion_can_dig(world._cell_center(cell)): continue
			if world.companion_dig(world._cell_center(cell), false) != 1 or _solid(cell):
				_reject("Production excavation failed at " + str(cell)); return false
			mutations.append({"owner":"companion_dig", "cell":str(cell), "square":false})
			pending.erase(value)
			progressed = true
		if not progressed: _reject("Excavation path is blocked; no artificial fallback: " + str(pending)); return false
	return true

func _permanent_boundary() -> bool:
	# Shortest traversable tunnel to the actual shell, using the same dig owner.
	var start: Vector2i = world._world_to_cell(world.player.position)
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start:start}
	var target: Vector2i = Vector2i(-1, -1)
	var bounds: Rect2i = _active_bounds()
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		for offset in DIRECTIONS:
			var neighbor: Vector2i = cell + offset
			if bounds.has_point(neighbor) and _solid(neighbor) and not _mineable(neighbor): target = cell; break
		if target.x >= 0: break
		for offset in DIRECTIONS:
			var next: Vector2i = cell + offset
			if not bounds.has_point(next) or previous.has(next): continue
			if _solid(next) and not _can_excavate(next): continue
			previous[next] = cell
			queue.append(next)
	if target.x < 0: _reject("No legal route to a permanent boundary"); return false
	var path: Array[Vector2i] = []
	var cursor_cell: Vector2i = target
	while cursor_cell != start: path.push_front(cursor_cell); cursor_cell = previous[cursor_cell]
	if not _dig_cells(path): return false
	return await _case("mineable-permanent-boundary", target, {"origin":"real companion tunnel", "permanent_branch_unchanged":true})

func _stream_matrix() -> bool:
	# Use a valid native seam corridor and the actual player-move stream owner.
	# Positioning is a fixture teleport, not evidence of uninterrupted input.
	for down in [true, false]:
		var before: int = world.window_start_depth
		var next_depth: int = world.current_depth + (1 if down else -1)
		var column: int = world.DeepLayout.entrance_column(4608, next_depth if down else world.current_depth)
		var seam_row: int = (next_depth - before) * world.DeepLayout.CHUNK_ROWS
		if not down: seam_row += world.DeepLayout.CHUNK_ROWS - 1
		var point: Vector2 = world._nearest_walkable_position(world._cell_center(Vector2i(column, seam_row)))
		if not _walkable(point): _reject("Stream seam fixture is not walkable"); return false
		# Present the valid seam camera before the production rebase preserves
		# its center. Otherwise an old fixture camera could be carried across.
		world.player.position = point
		world.player.camera.reset_smoothing()
		world.player.camera.force_update_scroll()
		world._on_player_moved(point)
		if world.window_start_depth == before or world.current_depth != next_depth:
			_reject("Actual stream owner did not perform the requested rebase"); return false
		mutations.append({"owner":"_on_player_moved -> _update_stream_depth", "fixture_teleport":true, "window_before":before, "window_after":world.window_start_depth})
		world.player.camera.force_update_scroll()
		if not await _pair("after-rebase-down" if down else "after-rebase-up", world.player.position, {"origin":"native stratum corridor after actual stream rebase", "current_depth":world.current_depth, "window_start_depth":world.window_start_depth}): return false
	return true

func _nearest_generated_convex() -> Vector2i:
	var result := Vector2i(-1, -1)
	var score: float = INF
	var bounds: Rect2i = _active_bounds()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			var cell := Vector2i(x, y)
			if not _mineable(cell) or not _physical_solid(cell): continue
			for corner in 4:
				if _vertex_solid_count(cell + CORNER_OFFSETS[corner]) != 1: continue
				var distance: float = world._cell_center(cell).distance_squared_to(world.player.position)
				if distance < score: result = cell; score = distance
	return result

func _case(label: String, cell: Vector2i, details: Dictionary) -> bool:
	var point: Vector2 = world._cell_center(cell)
	var best := Vector2(INF, INF)
	var distance: float = INF
	for y in range(cell.y - 6, cell.y + 7):
		for x in range(cell.x - 6, cell.x + 7):
			var candidate := Vector2i(x, y)
			if not _active_bounds().has_point(candidate): continue
			var position: Vector2 = world._cell_center(candidate)
			if _walkable(position) and position.distance_squared_to(point) < distance:
				best = position; distance = position.distance_squared_to(point)
	if not is_finite(best.x): _reject("No walkable camera anchor: " + label); return false
	world.restore_position(best)
	if not world.player.position.is_equal_approx(best) or not _walkable(world.player.position):
		_reject("Camera anchor was clamped away or is blocked: " + label); return false
	world.player.set_facing((point - best).normalized())
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.player._update_visual(false)
	world.player.visual._draw_frame(0.0)
	details["cell"] = str(cell)
	details["fixture_teleport_to_walkable_floor"] = true
	return await _pair(label, point, details)

func _pair(label: String, focus: Vector2, details: Dictionary) -> bool:
	# Deep's periodic owner also enables lights for the actual camera bounds.
	# Refresh once at the new fixture pose, before all three frozen captures.
	if area == "deep": world._update_resource_pulses()
	_freeze()
	world.get_node("CaveLightOccluders").refresh()
	var original_state: int = _geometry_fingerprint()
	var save_name: String = label + "-state.json"
	var save_file: FileAccess = FileAccess.open(output.path_join(save_name), FileAccess.WRITE)
	if save_file == null: _reject("Could not save the actual fixture state"); return false
	save_file.store_string(JSON.stringify(state.serialize()))
	save_file.close()
	var row: Dictionary = {"id":label, "details":details, "focus_world":str(focus), "player":str(world.player.position), "camera_limits":_camera_limits(), "state_file":save_name, "state_sha256":FileAccess.get_sha256(output.path_join(save_name)), "captures":[]}
	var pictures: Array[Image] = []
	var reference_view: Array = []
	for mode in [false, true, false]:
		world.compact_join_study_enabled = mode
		# Mode is not in production terrain fingerprints. Force cached paints
		# for every control as well as B, preventing a vacuous unchanged capture.
		for section in world.lit_draw_sections._cached.values(): section.revision = -1
		var callbacks: int = world.lit_draw_sections.draw_callbacks
		world.queue_redraw()
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		if _geometry_fingerprint() != original_state: _reject("Geometry changed within pair: " + label); return false
		if world.lit_draw_sections.draw_callbacks <= callbacks: _reject("Cached terrain was not repainted: " + label); return false
		var viewport_rect: Rect2 = root.get_visible_rect()
		var canvas_transform: Transform2D = world.get_global_transform_with_canvas()
		var viewport_point: Vector2 = canvas_transform * focus
		var camera: Camera2D = world.player.camera
		var culling_rect: Rect2 = world._visual_visible_rect(Vector2.ONE * world.TILE_SIZE * 3.0) if area == "deep" else world._resource_visible_rect(Vector2.ONE * world.TILE_SIZE * 3.0)
		if not world.last_draw_camera_center.is_equal_approx(camera.get_screen_center_position()) or not world.last_draw_viewport_size.is_equal_approx(viewport_rect.size) or not world.last_draw_camera_zoom.is_equal_approx(camera.zoom.abs()):
			_reject("Terrain culling and presented camera disagree: " + label); return false
		var view: Array = [viewport_rect, canvas_transform, camera.get_screen_center_position(), camera.zoom, _camera_limits(), culling_rect]
		if not reference_view.is_empty() and view != reference_view: _reject("Camera/viewport changed within pair: " + label); return false
		reference_view = view
		if not viewport_rect.grow(-28.0).has_point(viewport_point) or not culling_rect.has_point(focus): _reject("Required focus outside actual viewport/culling: " + label); return false
		var picture: Image = root.get_texture().get_image()
		if picture.get_size() != Vector2i(1696, 780): _reject("Expected native 1696x780 framebuffer"); return false
		# canvas_items + expand fills this root framebuffer. Canvas coordinates
		# are logical viewport units; keep their PNG pixel mapping explicit.
		var framebuffer_point: Vector2 = (viewport_point - viewport_rect.position) / viewport_rect.size * Vector2(picture.get_size())
		picture.convert(Image.FORMAT_RGBA8)
		var filename: String = label + "-" + ["A", "B", "A2"][pictures.size()] + ".png"
		if picture.save_png(output.path_join(filename)) != OK: _reject("Could not save " + filename); return false
		row.captures.append({"filename":filename, "candidate":mode, "focus_viewport":str(viewport_point), "focus_framebuffer":str(framebuffer_point), "camera":str(camera.get_screen_center_position()), "culling_world_rect":str(culling_rect), "redrawn_sections":world.lit_draw_sections.draw_callbacks - callbacks})
		pictures.append(picture)
	row["candidate_diff"] = _difference(pictures[0], pictures[1])
	row["restored_diff"] = _difference(pictures[0], pictures[2])
	row["geometry_fingerprint"] = original_state
	row["mutation_count"] = mutations.size()
	pairs.append(row)
	_save_report()
	if int(row.restored_diff.changed_rgba_pixels) != 0: _reject("Restored A2 control differs: " + label); return false
	print("CORNER_COMPACT_PAIR " + JSON.stringify({"id":label, "candidate_diff":row.candidate_diff, "restored_diff":row.restored_diff}))
	return true

func _difference(a: Image, b: Image) -> Dictionary:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	var changed: int = 0
	var maximum: int = 0
	for offset in range(0, left.size(), 4):
		var different: bool = false
		for channel in 4:
			var delta: int = absi(int(left[offset + channel]) - int(right[offset + channel]))
			maximum = maxi(maximum, delta)
			different = different or delta != 0
		if different: changed += 1
	return {"changed_rgba_pixels":changed, "maximum_channel_delta":maximum}

func _active_bounds() -> Rect2i:
	if area == "deep": return Rect2i(0, (world.current_depth - world.window_start_depth) * world.DeepLayout.CHUNK_ROWS, world.GRID_SIZE.x, world.DeepLayout.CHUNK_ROWS)
	return Rect2i(0, 0, world.cols, world.rows)

func _solid(cell: Vector2i) -> bool:
	return not world._is_floor(cell) if area == "deep" else world._visual_is_solid(cell)

func _physical_solid(cell: Vector2i) -> bool:
	return not world._is_floor(cell) if area == "deep" else world._terrain_is_solid(cell)

func _mineable(cell: Vector2i) -> bool:
	return world._cell_diggable(cell) if area == "deep" else world._cell_in_bounds(cell) and not world._terrain_is_bedrock(cell)

func _can_excavate(cell: Vector2i) -> bool:
	if not _mineable(cell): return false
	if area == "deep":
		for resource in world.resources:
			if not bool(resource.mined) and Vector2i(resource.cell) == cell: return false
	elif area == "d2":
		if world.concealed_cells.has(world._cell_index(cell)): return false
		for index in world.rocks_by_cell.get(cell, []):
			if not bool(world.rocks[int(index)].broken): return false
	return true

func _walkable(point: Vector2) -> bool:
	if not world._cell_in_bounds(world._world_to_cell(point)): return false
	return world._position_walkable(point) if area == "deep" else not world._player_collides(point)

func _terrain_health(cell: Vector2i) -> int:
	return 520 - int(world.dig_damage.get(cell, 0)) if area == "deep" else int(world.terrain_hp[world._cell_index(cell)])

func _open_sides(cell: Vector2i) -> Array[bool]:
	var result: Array[bool] = []
	for direction in DIRECTIONS: result.append(not _solid(cell + direction))
	return result

func _vertex_solid_count(vertex: Vector2i) -> int:
	var count: int = 0
	for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		if _solid(vertex + offset): count += 1
	return count

func _geometry_fingerprint() -> int:
	return hash([world.floor_cells, world.dig_damage, world.current_depth, world.window_start_depth]) if area == "deep" else hash([world.terrain_hp, world.concealed_cells, world.dug_indices])

func _camera_limits() -> Array:
	var camera: Camera2D = world.player.camera
	return [camera.limit_left, camera.limit_top, camera.limit_right, camera.limit_bottom]

func _freeze() -> void:
	_freeze_node(root)
	for tween in get_processed_tweens(): tween.pause()
	paused = true
	Engine.time_scale = 0.0

func _freeze_node(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze_node(child)

func _save_report() -> void:
	if output.is_empty(): return
	var hashes: Dictionary = {}
	for path in ["res://scripts/world/cave_edge_asset_drawer.gd", "res://scripts/world/endless_descent_world.gd", "res://scripts/world/depth/rootwound_world.gd", "res://tools/corner_compact_pilot/deep_candidate.gd", "res://tools/corner_compact_pilot/depth_candidate.gd", get_script().resource_path]:
		hashes[path] = FileAccess.get_sha256(path)
	var report: Dictionary = {"base_revision":BASE_REVISION, "source_revision":source_revision, "files_sha256":hashes, "area":area, "depth":depth, "mine":mine_id, "scope":scope, "seed":4608, "rendered":not pairs.is_empty(), "physical_iphone":false, "performance_evidence":false, "visual_approval":false, "content_scale_size":str(root.content_scale_size), "viewport_size":str(root.get_visible_rect().size), "pairs":pairs, "mutations":mutations, "failures":failures, "limits":"Frozen source-project study; valid-floor fixture teleports and accelerated real excavation owners. Inspect all original PNGs for material, scale, clipping and gaps. B is intentionally different; only A/A2 must be pixel-identical."}
	var file: FileAccess = FileAccess.open(output.path_join("corner-compact.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t"))

func _reject(message: String) -> void:
	failures.append(message)
	_save_report()
	push_error("CORNER_COMPACT_REVIEW_FAIL " + message)
	quit(2)

func _finish() -> void:
	_save_report()
	print("CORNER_COMPACT_REVIEW_COMPLETE " + JSON.stringify({"scope":scope, "pairs":pairs.size(), "failures":failures, "visual_approval":false}))
	quit()
