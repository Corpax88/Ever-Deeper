extends SceneTree
## One fixed real-layout A/B/A2 pair. No topology, asset or corner substitution.
const BASE_REVISION: String = "8f5680defb9083bbe1e044d39a10612f2186e7f3"
const SEED: int = 4608
const DEPTH: int = 14
const PLAYER_POSITION := Vector2(1056.0, 1696.0)
const CAMERA_CENTER := Vector2(1056.0, 1808.0)
const CORNER_CELL := Vector2i(16, 27)
const STRAIGHT_CELLS: Array[Vector2i] = [Vector2i(12, 27), Vector2i(13, 27), Vector2i(14, 27)]
const DIRECTIONS: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const IDENTITY_PATHS: Array[String] = [
	"res://project.godot",
	"res://scripts/world/endless_descent_world.gd",
	"res://scripts/world/cave_edge_asset_drawer.gd",
	"res://scripts/lighting/lit_draw_sections.gd",
	"res://shaders/lit_relic_seal.gdshader",
	"res://assets/mossvein/cave-edge-loop-v2.png",
	"res://assets/mossvein/cave-corner-v2.png",
]
var output: String = ""
var pack_source: String = ""
var expected_pack_sha256: String = ""
var report_ready: bool = false
var source_revision: String = ""
var main: Node
var world: Node
var state: Node
var pair: Dictionary = {}
var topology: Dictionary = {}
var review_regions: Dictionary = {}
var failures: Array[String] = []
var seal: Shader
var original_seal_code: String = ""
var original_time_scale: float = 1.0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--source-revision="): source_revision = arg.trim_prefix("--source-revision=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		else: _reject("Unknown argument: " + arg); return
	if not output.is_absolute_path() or source_revision.length() != 40 or not source_revision.is_valid_hex_number():
		_reject("Use an absolute output path and the exact 40-character checkpoint revision"); return
	if DisplayServer.get_name() == "headless": _reject("An actual rendered framebuffer is required"); return
	if DirAccess.make_dir_recursive_absolute(output) != OK: _reject("Could not create output directory"); return
	report_ready = true
	if not pack_source.is_empty():
		expected_pack_sha256 = OS.get_environment("PCK_SHA256")
		if not pack_source.is_absolute_path() or not FileAccess.file_exists(pack_source):
			_reject("Pack identity requires an existing absolute package path"); return
		if expected_pack_sha256.length() != 64 or not expected_pack_sha256.is_valid_hex_number() or FileAccess.get_sha256(pack_source) != expected_pack_sha256:
			_reject("Package hash must match the immutable build's PCK_SHA256"); return
		# Godot removes --main-pack from its exposed arguments. The pinned workflow
		# supplies this same path to --main-pack and launches from an empty host.
	# Match the retained corner smoke's frozen controls. TIME otherwise keeps
	# moving even while the scene tree is paused. Restore the cached shader at exit.
	seal = load("res://shaders/lit_relic_seal.gdshader")
	original_seal_code = seal.code
	seal.code = original_seal_code.replace("TIME", "0.0")
	original_time_scale = Engine.time_scale
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load(get_script().resource_path.get_base_dir().path_join("deep_reference.gd")))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = SEED
	seed(SEED)
	if not main._dev_jump_endless(DEPTH): _reject("Cannot enter the production Deep world"); return
	world = main.endless_world
	state.set_drill_level(1)
	state.set_starforge_variant("")
	world.player.set_external_movement(Vector2.ZERO)
	world.player.prepare_visual_cache()
	await create_timer(4.0).timeout
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	# Retain production zoom, content size, offsets and limits. Disable only the
	# fixture's transient drag/smoothing, equally for A, B and A2.
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.drag_horizontal_enabled = false
	world.player.camera.drag_vertical_enabled = false
	world.restore_position(PLAYER_POSITION)
	if not world.player.position.is_equal_approx(PLAYER_POSITION) or not world._position_walkable(PLAYER_POSITION):
		_reject("The retained player anchor is blocked or clamped"); return
	world.player.set_facing(Vector2.DOWN)
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.player._update_visual(false)
	world.player.visual._draw_frame(0.0)
	if not world.player.camera.get_screen_center_position().is_equal_approx(CAMERA_CENTER):
		_reject("The actual camera does not match the retained held pose"); return
	if not _verify_topology(): return
	# The periodic owner selects actual camera lights. Refresh once, then freeze
	# all three modes at this same world/light/animation state.
	world._update_resource_pulses()
	world.lit_draw_sections.profile_draws = true
	_freeze()
	world.get_node("CaveLightOccluders").refresh()
	if not await _capture_pair(): return
	if not _save_report(): _reject("Could not write the final report"); return
	_restore_controls()
	print("NORTH_EDGE_RELEASE_REVIEW_COMPLETE " + JSON.stringify({"pairs":1, "failures":failures, "visual_approval":false}))
	quit()

func _verify_topology() -> bool:
	if world.current_depth != DEPTH or world.window_start_depth != 13 or state.world_seed != SEED:
		_reject("The native layout identity changed"); return false
	if not world._cell_diggable(CORNER_CELL) or world._is_floor(CORNER_CELL) or _open_sides(CORNER_CELL) != [true, true, false, false]:
		_reject("The retained northeast corner no longer has its generated topology"); return false
	for cell in STRAIGHT_CELLS:
		if not _north_edge(cell): _reject("Missing retained north run at " + str(cell)); return false
	var west: Vector2i = STRAIGHT_CELLS[0]
	var east: Vector2i = STRAIGHT_CELLS[2]
	while _north_edge(west + Vector2i.LEFT): west += Vector2i.LEFT
	while _north_edge(east + Vector2i.RIGHT): east += Vector2i.RIGHT
	if east != CORNER_CELL: _reject("The held north run no longer ends at the reviewed northeast corner"); return false
	topology = {
		"corner_cell":str(CORNER_CELL), "corner_open_sides":_open_sides(CORNER_CELL),
		"straight_cells":str(STRAIGHT_CELLS), "run_west_cell":str(west), "run_east_cell":str(east),
		"west_open_sides":_open_sides(west), "east_open_sides":_open_sides(east),
		"current_depth":world.current_depth, "window_start_depth":world.window_start_depth,
		"fixture_teleport_to_walkable_floor":true, "terrain_mutations":0,
	}
	var tile: float = world.TILE_SIZE
	var inset: float = tile * (10.0 / 48.0)
	# These are review bounds, never clip or render geometry. Endpoints include
	# the entire three-tile elbow and the adjacent strip continuation.
	review_regions = {
		"straight_band":Rect2(Vector2(STRAIGHT_CELLS[0]) * tile + Vector2(0.0, -inset), Vector2(tile * 3.0, tile)),
		"west_endpoint":Rect2(Vector2(west) * tile - Vector2.ONE * tile * 2.0, Vector2.ONE * tile * 4.0),
		"east_endpoint":Rect2(Vector2(east + Vector2i.RIGHT) * tile - Vector2.ONE * tile * 2.0, Vector2.ONE * tile * 4.0),
	}
	return true

func _north_edge(cell: Vector2i) -> bool:
	return world._cell_in_bounds(cell) and world._cell_diggable(cell) and not world._is_floor(cell) and world._is_floor(cell + Vector2i.UP) and world.depth_at_position(world._cell_center(cell)) == DEPTH

func _open_sides(cell: Vector2i) -> Array[bool]:
	var result: Array[bool] = []
	for direction in DIRECTIONS: result.append(world._is_floor(cell + direction))
	return result

func _capture_pair() -> bool:
	var original_state: int = _geometry_fingerprint()
	var save_name: String = "moss-north-held-state.json"
	var save_file: FileAccess = FileAccess.open(output.path_join(save_name), FileAccess.WRITE)
	if save_file == null: _reject("Could not save the actual held state"); return false
	save_file.store_string(JSON.stringify(state.serialize()))
	save_file.close()
	pair = {"id":"moss-north-held", "player":str(world.player.position), "topology":topology, "state_file":save_name, "state_sha256":FileAccess.get_sha256(output.path_join(save_name)), "captures":[]}
	var pictures: Array[Image] = []
	var reference_view: Array = []
	for mode in [false, true, false]:
		world.north_edge_study_enabled = mode
		world.study_north_draw_calls = 0
		world.study_north_drawn_cells.clear()
		# Mode does not belong to the production terrain cache fingerprint. Force
		# repaint in all controls so B cannot pass using retained A draw commands.
		for section in world.lit_draw_sections._cached.values(): section.revision = -1
		var callbacks: int = world.lit_draw_sections.draw_callbacks
		world.queue_redraw()
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		if _geometry_fingerprint() != original_state: _reject("World geometry changed within A/B/A2"); return false
		if world.lit_draw_sections.draw_callbacks <= callbacks: _reject("Cached terrain was not repainted"); return false
		if mode:
			for cell in STRAIGHT_CELLS:
				if not world.study_north_drawn_cells.has(cell): _reject("B did not redraw required north cell " + str(cell)); return false
		elif world.study_north_draw_calls != 0: _reject("A control entered the candidate branch"); return false
		var viewport_rect: Rect2 = root.get_visible_rect()
		var canvas_transform: Transform2D = world.get_global_transform_with_canvas()
		var camera: Camera2D = world.player.camera
		var culling_rect: Rect2 = world._visual_visible_rect(Vector2.ONE * world.TILE_SIZE * 3.0)
		if not camera.get_screen_center_position().is_equal_approx(CAMERA_CENTER) or _camera_limits() != [0, 0, 2560, 4224]:
			_reject("Actual held camera center or production limits changed"); return false
		if not world.last_draw_camera_center.is_equal_approx(camera.get_screen_center_position()) or not world.last_draw_viewport_size.is_equal_approx(viewport_rect.size) or not world.last_draw_camera_zoom.is_equal_approx(camera.zoom.abs()):
			_reject("Terrain culling and the actual presented camera disagree"); return false
		var view: Array = [viewport_rect, canvas_transform, camera.get_screen_center_position(), camera.zoom, _camera_limits(), culling_rect]
		if not reference_view.is_empty() and view != reference_view: _reject("Camera/viewport changed within A/B/A2"); return false
		reference_view = view
		var picture: Image = root.get_texture().get_image()
		if picture.get_size() != Vector2i(1696, 780): _reject("Expected the native 1696x780 framebuffer"); return false
		if root.content_scale_size != Vector2i(1280, 720): _reject("Production logical content size changed"); return false
		var regions: Dictionary = {}
		for label in review_regions:
			var world_rect: Rect2 = review_regions[label]
			var viewport_region: Rect2 = canvas_transform * world_rect
			if not viewport_rect.encloses(viewport_region) or not culling_rect.encloses(world_rect):
				_reject("Required review region outside actual viewport/culling: " + label); return false
			var native_scale: Vector2 = Vector2(picture.get_size()) / viewport_rect.size
			regions[label] = {"world":str(world_rect), "viewport":str(viewport_region), "framebuffer":str(Rect2((viewport_region.position - viewport_rect.position) * native_scale, viewport_region.size * native_scale))}
		picture.convert(Image.FORMAT_RGBA8)
		var filename: String = "moss-north-held-" + ["A", "B", "A2"][pictures.size()] + ".png"
		if picture.save_png(output.path_join(filename)) != OK: _reject("Could not save " + filename); return false
		var drawn_cells: Array[String] = []
		for cell in world.study_north_drawn_cells: drawn_cells.append(str(cell))
		drawn_cells.sort()
		pair.captures.append({"filename":filename, "sha256":FileAccess.get_sha256(output.path_join(filename)), "candidate":mode, "camera":str(camera.get_screen_center_position()), "zoom":str(camera.zoom), "camera_limits":_camera_limits(), "culling_world_rect":str(culling_rect), "regions":regions, "redrawn_sections":world.lit_draw_sections.draw_callbacks - callbacks, "candidate_draw_calls":world.study_north_draw_calls, "candidate_cells":drawn_cells})
		pictures.append(picture)
		if not _save_report(): _reject("Could not write the capture report"); return false
	pair["candidate_diff"] = _difference(pictures[0], pictures[1])
	pair["restored_diff"] = _difference(pictures[0], pictures[2])
	pair["geometry_fingerprint"] = original_state
	if not _save_report(): _reject("Could not write the comparison report"); return false
	if int(pair.restored_diff.changed_rgba_pixels) != 0: _reject("Restored A2 differs from A"); return false
	if int(pair.candidate_diff.changed_rgba_pixels) == 0: _reject("B has no visible effect"); return false
	print("NORTH_EDGE_ORIENTATION_PAIR " + JSON.stringify({"candidate_diff":pair.candidate_diff, "restored_diff":pair.restored_diff}))
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

func _geometry_fingerprint() -> int:
	return hash([world.floor_cells, world.dig_damage, world.current_depth, world.window_start_depth])

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

func _restore_controls() -> void:
	if is_instance_valid(world): world.north_edge_study_enabled = false
	if seal != null: seal.code = original_seal_code
	Engine.time_scale = original_time_scale

func _save_report() -> bool:
	if not report_ready: return true
	var hashes: Dictionary = {}
	var packed_only: Array[String] = []
	for path in IDENTITY_PATHS:
		if FileAccess.file_exists(path): hashes[path] = FileAccess.get_sha256(path)
		elif not pack_source.is_empty(): packed_only.append(path)
		else: hashes[path] = "missing"
	var fixture_directory: String = get_script().resource_path.get_base_dir()
	for filename in ["review.gd", "deep_reference.gd", "README.md"]:
		var path: String = fixture_directory.path_join(filename)
		hashes[path] = FileAccess.get_sha256(path)
	var report: Dictionary = {"base_revision":BASE_REVISION, "source_revision":source_revision, "files_sha256":hashes, "seed":SEED, "depth":DEPTH, "scope":"production integration of the accepted north-edge orientation", "rendered":not pair.get("captures", []).is_empty(), "physical_iphone":false, "performance_evidence":false, "visual_approval":false, "endpoint_visual_review":"pending independent inspection of both original-resolution endpoints", "content_scale_size":str(root.content_scale_size), "viewport_size":str(root.get_visible_rect().size), "pair":pair, "failures":failures, "limits":"Frozen source-project pose with a valid-floor fixture teleport. This tests upright strip perspective only; it does not complete short corners or pillars. Inspect the full original frame and both reported endpoint regions. Exact restoration and nonzero B pixels are not visual acceptance."}
	report["pack_source"] = pack_source
	report["pack_sha256"] = FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else ""
	report["expected_pack_sha256"] = expected_pack_sha256
	report["original_files_bound_by_pack"] = packed_only
	var file: FileAccess = FileAccess.open(output.path_join("north-edge-orientation.json"), FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	return true

func _reject(message: String) -> void:
	failures.append(message)
	_save_report()
	_restore_controls()
	push_error("NORTH_EDGE_RELEASE_REVIEW_FAIL " + message)
	quit(2)
