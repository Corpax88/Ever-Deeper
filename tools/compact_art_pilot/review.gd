extends SceneTree
## One unapproved whole-image art study at one native generated NE corner.
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
	"res://tools/compact_art_pilot/deep_candidate.gd",
	"res://tools/compact_art_pilot/north_reference.gd",
	"res://tools/compact_art_pilot/asset-audit.json",
	"res://tools/compact_art_pilot/baseline-files.json",
	"res://tools/compact_art_pilot/generation-metadata.json",
	"res://tools/compact_art_pilot/assets/moss-ne-initial-unapproved.png",
	"res://tools/compact_art_pilot/assets/moss-ne-three-boulder-unapproved.png",
	"res://tools/compact_art_pilot/review.gd",
	"res://tools/compact_art_pilot/README.md",
]
var output: String = ""
var report_ready: bool = false
var source_revision: String = ""
var main: Node
var world: Node
var state: Node
var sequence: Dictionary = {}
var identity_hashes: Dictionary = {}
var frozen_visual_hash: String = ""
var frozen_visual_file: String = ""
var rendered_assets: Dictionary = {}
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
		else: _reject("Unknown argument: " + arg); return
	if not output.is_absolute_path() or source_revision.length() != 40 or not source_revision.is_valid_hex_number():
		_reject("Use an absolute output path and the exact 40-character checkpoint revision"); return
	if DisplayServer.get_name() == "headless": _reject("An actual rendered framebuffer is required"); return
	if DirAccess.make_dir_recursive_absolute(output) != OK: _reject("Could not create output directory"); return
	report_ready = true
	if not _verify_source_assets(): return
	# Match the retained corner smoke's frozen controls. TIME otherwise keeps
	# moving even while the scene tree is paused. Restore the cached shader at exit.
	seal = load("res://shaders/lit_relic_seal.gdshader")
	original_seal_code = seal.code
	seal.code = original_seal_code.replace("TIME", "0.0")
	original_time_scale = Engine.time_scale
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load("res://tools/compact_art_pilot/deep_candidate.gd"))
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
	# fixture's transient drag/smoothing, equally for A, B, C and A2.
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
	# all four modes at this same world/light/animation state.
	world._update_resource_pulses()
	world.lit_draw_sections.profile_draws = true
	_freeze()
	world.get_node("CaveLightOccluders").refresh()
	if not await _capture_sequence(): return
	if not _save_report(): _reject("Could not write the final report"); return
	_restore_controls()
	print("COMPACT_ART_REVIEW_COMPLETE " + JSON.stringify({"sequences":1, "failures":failures, "visual_approval":false}))
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
		"new_full_png_canvas":Rect2(Vector2(CORNER_CELL) * tile + Vector2(-32.0, -32.0), Vector2(128.0, 128.0)),
		"native_full_corner_canvas":Rect2(Vector2(CORNER_CELL) * tile + Vector2(-50.6666666667, -77.3333333333), Vector2(192.0, 192.0)),
	}
	return true

func _north_edge(cell: Vector2i) -> bool:
	return world._cell_in_bounds(cell) and world._cell_diggable(cell) and not world._is_floor(cell) and world._is_floor(cell + Vector2i.UP) and world.depth_at_position(world._cell_center(cell)) == DEPTH

func _open_sides(cell: Vector2i) -> Array[bool]:
	var result: Array[bool] = []
	for direction in DIRECTIONS: result.append(world._is_floor(cell + direction))
	return result

func _capture_sequence() -> bool:
	var original_geometry: int = _geometry_fingerprint()
	var serialized_state: String = JSON.stringify(state.serialize())
	var save_name: String = "moss-compact-held-state.json"
	if not _write_text(save_name, serialized_state): _reject("Could not save the actual held state"); return false
	sequence = {"id":"moss-compact-held", "player":str(world.player.position), "topology":topology, "state_file":save_name, "state_sha256":FileAccess.get_sha256(output.path_join(save_name)), "captures":[]}
	var pictures: Array[Image] = []
	var reference_view: Array = []
	var reference_contexts: String = ""
	var corner_pixel_bounds := Rect2()
	var modes: Array[Dictionary] = [
		{"name":"A", "north":false, "corner":false},
		{"name":"B", "north":true, "corner":false},
		{"name":"C", "north":true, "corner":true},
		{"name":"A2", "north":false, "corner":false},
	]
	for mode in modes:
		world.north_edge_study_enabled = mode.north
		world.compact_art_study_enabled = mode.corner
		world.study_north_draw_calls = 0
		world.study_north_drawn_cells.clear()
		world.study_corner_draw_calls = 0
		world.study_corner_drawn_cells.clear()
		world.study_corner_contexts.clear()
		# Both candidate switches are outside production's cache fingerprint.
		# Repaint all four controls; retained commands cannot masquerade as C.
		for section in world.lit_draw_sections._cached.values(): section.revision = -1
		var callbacks: int = world.lit_draw_sections.draw_callbacks
		world.queue_redraw()
		for frame in 4: await process_frame
		await RenderingServer.frame_post_draw
		if _geometry_fingerprint() != original_geometry: _reject("World geometry changed within A/B/C/A2"); return false
		if JSON.stringify(state.serialize()) != serialized_state: _reject("Saved game state changed within A/B/C/A2"); return false
		if world.lit_draw_sections.draw_callbacks <= callbacks: _reject("Cached terrain was not repainted"); return false
		if mode.north:
			for cell in STRAIGHT_CELLS:
				if not world.study_north_drawn_cells.has(cell): _reject("Missing audited north draw at " + str(cell)); return false
		elif world.study_north_draw_calls != 0: _reject("A control entered the north candidate branch"); return false
		if mode.corner:
			if world.study_corner_draw_calls < 1 or world.study_corner_drawn_cells.size() != 1 or not world.study_corner_drawn_cells.has(CORNER_CELL):
				_reject("C did not replace exactly the named NE corner"); return false
		elif world.study_corner_draw_calls != 0: _reject("A or B entered the unapproved-art branch"); return false
		var contexts: String = JSON.stringify(world.study_corner_contexts)
		if not reference_contexts.is_empty() and contexts != reference_contexts: _reject("Visited corner topology or native asset selection changed"); return false
		reference_contexts = contexts
		var visual_text: String = JSON.stringify(_visual_state())
		var visual_hash: String = visual_text.sha256_text()
		if frozen_visual_hash.is_empty():
			frozen_visual_hash = visual_hash
			frozen_visual_file = "moss-compact-held-visual-state.json"
			if not _write_text(frozen_visual_file, visual_text): _reject("Could not save actual visual-state properties"); return false
		elif visual_hash != frozen_visual_hash: _reject("Held visual properties changed across modes"); return false
		var viewport_rect: Rect2 = root.get_visible_rect()
		var canvas_transform: Transform2D = world.get_global_transform_with_canvas()
		var camera: Camera2D = world.player.camera
		var culling_rect: Rect2 = world._visual_visible_rect(Vector2.ONE * world.TILE_SIZE * 3.0)
		if not camera.get_screen_center_position().is_equal_approx(CAMERA_CENTER) or _camera_limits() != [0, 0, 2560, 4224]:
			_reject("Actual camera center or production limits changed"); return false
		if not world.last_draw_camera_center.is_equal_approx(camera.get_screen_center_position()) or not world.last_draw_viewport_size.is_equal_approx(viewport_rect.size) or not world.last_draw_camera_zoom.is_equal_approx(camera.zoom.abs()):
			_reject("Terrain culling and the actual presented camera disagree"); return false
		var view: Array = [viewport_rect, canvas_transform, camera.get_screen_center_position(), camera.zoom, _camera_limits(), culling_rect]
		if not reference_view.is_empty() and view != reference_view: _reject("Camera/viewport changed within A/B/C/A2"); return false
		reference_view = view
		var picture: Image = root.get_texture().get_image()
		if picture.get_size() != Vector2i(1696, 780): _reject("Expected the native 1696x780 framebuffer"); return false
		if root.content_scale_size != Vector2i(1280, 720): _reject("Production logical content size changed"); return false
		var regions: Dictionary = {}
		var native_scale: Vector2 = Vector2(picture.get_size()) / viewport_rect.size
		for label in review_regions:
			var world_rect: Rect2 = review_regions[label]
			var viewport_region: Rect2 = canvas_transform * world_rect
			if not viewport_rect.encloses(viewport_region) or not culling_rect.encloses(world_rect):
				_reject("Required review region outside actual viewport/culling: " + label); return false
			regions[label] = {"world":str(world_rect), "viewport":str(viewport_region), "framebuffer":str(Rect2((viewport_region.position - viewport_rect.position) * native_scale, viewport_region.size * native_scale))}
		var union_world: Rect2 = Rect2(review_regions.native_full_corner_canvas).merge(Rect2(review_regions.new_full_png_canvas))
		var union_view: Rect2 = canvas_transform * union_world
		# Two native pixels allow only boundary filtering/rasterization. This is a
		# comparison mask, never a crop, drawing mask, material or world mutation.
		corner_pixel_bounds = Rect2((union_view.position - viewport_rect.position) * native_scale, union_view.size * native_scale).grow(2.0)
		picture.convert(Image.FORMAT_RGBA8)
		var filename: String = "moss-compact-held-" + String(mode.name) + ".png"
		if picture.save_png(output.path_join(filename)) != OK: _reject("Could not save " + filename); return false
		sequence.captures.append({
			"mode":mode.name, "filename":filename, "sha256":FileAccess.get_sha256(output.path_join(filename)),
			"north_candidate":mode.north, "compact_art_candidate":mode.corner,
			"camera":str(camera.get_screen_center_position()), "zoom":str(camera.zoom), "camera_limits":_camera_limits(),
			"culling_world_rect":str(culling_rect), "regions":regions, "corner_difference_allowed_framebuffer_rect":str(corner_pixel_bounds),
			"redrawn_sections":world.lit_draw_sections.draw_callbacks - callbacks,
			"north_draw_calls":world.study_north_draw_calls, "north_drawn_cells":_cell_names(world.study_north_drawn_cells),
			"compact_corner_draw_calls":world.study_corner_draw_calls, "compact_corner_drawn_cells":_cell_names(world.study_corner_drawn_cells),
			"corner_contexts_sha256":contexts.sha256_text(), "visual_properties_sha256":visual_hash,
			"save_state_sha256":serialized_state.sha256_text(), "geometry_fingerprint":original_geometry,
		})
		pictures.append(picture)
		if not _save_report(): _reject("Could not write the capture report"); return false
	sequence["north_only_diff_A_B"] = _difference(pictures[0], pictures[1])
	sequence["compact_art_diff_B_C"] = _difference(pictures[1], pictures[2], corner_pixel_bounds)
	sequence["restored_diff_A_A2"] = _difference(pictures[0], pictures[3])
	sequence["geometry_fingerprint"] = original_geometry
	sequence["corner_contexts"] = world.study_corner_contexts
	if not _save_report(): _reject("Could not write the comparison report"); return false
	if int(sequence.restored_diff_A_A2.changed_rgba_pixels) != 0: _reject("Restored A2 differs from A"); return false
	if int(sequence.north_only_diff_A_B.changed_rgba_pixels) == 0: _reject("Audited north branch has no visible effect"); return false
	if int(sequence.compact_art_diff_B_C.changed_rgba_pixels) == 0: _reject("New whole corner image has no visible effect"); return false
	if int(sequence.compact_art_diff_B_C.changed_pixels_outside_allowed_rect) != 0: _reject("B/C changes pixels beyond the old/new corner quad union"); return false
	print("COMPACT_ART_SEQUENCE " + JSON.stringify({"north_diff":sequence.north_only_diff_A_B, "art_diff":sequence.compact_art_diff_B_C, "restored_diff":sequence.restored_diff_A_A2}))
	return true

func _difference(a: Image, b: Image, allowed_rect: Rect2 = Rect2()) -> Dictionary:
	var left: PackedByteArray = a.get_data()
	var right: PackedByteArray = b.get_data()
	var changed: int = 0
	var outside: int = 0
	var maximum: int = 0
	var minimum_pixel := Vector2i(a.get_width(), a.get_height())
	var maximum_pixel := Vector2i(-1, -1)
	for offset in range(0, left.size(), 4):
		var different: bool = false
		for channel in 4:
			var delta: int = absi(int(left[offset + channel]) - int(right[offset + channel]))
			maximum = maxi(maximum, delta)
			different = different or delta != 0
		if not different: continue
		changed += 1
		var index: int = offset / 4
		var pixel := Vector2i(index % a.get_width(), index / a.get_width())
		minimum_pixel = minimum_pixel.min(pixel)
		maximum_pixel = maximum_pixel.max(pixel)
		if allowed_rect.has_area() and not allowed_rect.has_point(Vector2(pixel) + Vector2(0.5, 0.5)): outside += 1
	var bounds: Rect2i = Rect2i(minimum_pixel, maximum_pixel - minimum_pixel + Vector2i.ONE) if changed > 0 else Rect2i()
	return {"changed_rgba_pixels":changed, "maximum_channel_delta":maximum, "changed_pixel_bounds":str(bounds), "changed_pixels_outside_allowed_rect":outside}

func _cell_names(cells: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for cell in cells: names.append(str(cell))
	names.sort()
	return names

func _visual_state() -> Dictionary:
	# Snapshot actual node presentation properties, not candidate mode switches
	# or draw counters. Terrain content itself is bound by topology/save state.
	var nodes: Array = []
	_collect_visual_nodes(main, nodes)
	return {"nodes":nodes, "hero_tool":world.player.visual.tool_visual_snapshot(), "hero_grounding":world.player.visual.grounding_snapshot(), "held_seal_shader_code_sha256":seal.code.sha256_text(), "engine_time_scale":Engine.time_scale}

func _collect_visual_nodes(node: Node, rows: Array) -> void:
	if node is CanvasItem or node is CanvasLayer:
		var fields: Array[String] = ["transform", "visible", "modulate", "self_modulate", "z_index", "z_as_relative", "light_mask", "material", "use_parent_material", "texture_filter", "texture_repeat", "show_behind_parent", "clip_children", "texture", "texture_scale", "texture_offset", "centered", "offset", "hframes", "vframes", "frame", "frame_coords", "region_enabled", "region_rect", "region_filter_clip_enabled", "flip_h", "flip_v", "text", "size", "position", "rotation", "scale", "layer", "follow_viewport_enabled", "enabled", "color", "energy", "height", "shadow_enabled", "shadow_color", "range_z_min", "range_z_max", "range_layer_min", "range_layer_max", "range_item_cull_mask", "shadow_item_cull_mask", "occluder", "occluder_light_mask", "light_only", "animation", "frame_progress", "sprite_frames"]
		var row: Dictionary = {"path":str(main.get_path_to(node)), "class":node.get_class()}
		for property in node.get_property_list():
			var key: String = String(property.name)
			if key in fields: row[key] = _visual_value(node.get(key))
		rows.append(row)
	for child in node.get_children(): _collect_visual_nodes(child, rows)

func _visual_value(value: Variant) -> Variant:
	if value is Resource:
		var resource: Resource = value
		var path: String = resource.resource_path
		var source_file: String = path.get_slice("::", 0)
		if source_file.begins_with("res://") and FileAccess.file_exists(source_file) and not rendered_assets.has(source_file):
			rendered_assets[source_file] = FileAccess.get_sha256(source_file)
		var result: Dictionary = {"class":resource.get_class(), "path":path}
		if resource is ShaderMaterial:
			var shader_material: ShaderMaterial = resource as ShaderMaterial
			result["shader"] = _visual_value(shader_material.shader)
			var uniforms: Dictionary = {}
			if shader_material.shader != null:
				for uniform in shader_material.shader.get_shader_uniform_list():
					uniforms[String(uniform.name)] = _visual_value(shader_material.get_shader_parameter(uniform.name))
			result["uniforms"] = uniforms
		elif resource is OccluderPolygon2D:
			var occluder: OccluderPolygon2D = resource as OccluderPolygon2D
			result["polygon"] = str(occluder.polygon)
			result["closed"] = occluder.closed
			result["cull_mode"] = occluder.cull_mode
		return result
	if value == null or value is bool or value is int or value is float or value is String: return value
	return str(value)

func _write_text(filename: String, content: String) -> bool:
	var file: FileAccess = FileAccess.open(output.path_join(filename), FileAccess.WRITE)
	if file == null: return false
	file.store_string(content)
	file.close()
	return true

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
	if is_instance_valid(world):
		world.north_edge_study_enabled = false
		world.compact_art_study_enabled = false
	if seal != null: seal.code = original_seal_code
	Engine.time_scale = original_time_scale

func _verify_source_assets() -> bool:
	var baseline: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/compact_art_pilot/baseline-files.json"))
	var audit: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tools/compact_art_pilot/asset-audit.json"))
	if not baseline is Dictionary or not audit is Dictionary:
		_reject("Missing baseline or asset provenance manifest"); return false
	if String(baseline.get("base_revision", "")) != BASE_REVISION or String(audit.get("base_revision", "")) != BASE_REVISION:
		_reject("Study base revision does not match exact DEV11"); return false
	for relative_path in Dictionary(baseline.get("files", {})):
		var path: String = "res://" + String(relative_path)
		var actual: String = FileAccess.get_sha256(path)
		if actual != String(baseline.files[relative_path]): _reject("Production baseline file changed: " + path); return false
		identity_hashes[path] = actual
	for item in Array(audit.get("assets", [])):
		var path: String = String(item.path)
		var actual: String = FileAccess.get_sha256(path)
		if actual != String(item.sha256): _reject("Original PNG bytes changed: " + path); return false
		identity_hashes[path] = actual
	if FileAccess.get_sha256("res://tools/compact_art_pilot/north_reference.gd") != "100ed61d1e37f121306c2c6d06ac246e4cbb5bdd5c0dc16fd9a4ec3aad15890f":
		_reject("North-only override differs from the audited original"); return false
	for path in IDENTITY_PATHS:
		var digest: String = FileAccess.get_sha256(path)
		if digest.length() != 64: _reject("Missing source or provenance file: " + path); return false
		identity_hashes[path] = digest
	return true

func _save_report() -> bool:
	if not report_ready: return true
	var report: Dictionary = {
		"base_revision":BASE_REVISION, "base_tree":"48b24a93faaa6f77d7a53c404cfb1228d7f825e0", "source_revision":source_revision,
		"files_sha256":identity_hashes, "node_resource_files_sha256":rendered_assets,
		"engine":Engine.get_version_info(), "display_server":DisplayServer.get_name(),
		"seed":SEED, "depth":DEPTH, "scope":"one held A/B/C/A2 whole-PNG art study at Moss NE cell (16, 27)",
		"rendered":not sequence.get("captures", []).is_empty(), "physical_iphone":false, "performance_evidence":false, "visual_approval":false,
		"visual_properties_file":frozen_visual_file, "visual_properties_sha256":frozen_visual_hash,
		"content_scale_size":str(root.content_scale_size), "viewport_size":str(root.get_visible_rect().size),
		"sequence":sequence, "failures":failures,
		"candidate_png":"res://tools/compact_art_pilot/assets/moss-ne-three-boulder-unapproved.png",
		"candidate_full_canvas_relative_cell":"Rect2(-32, -32, 128, 128)", "bitmap_mutations":0, "terrain_mutations":0,
		"independent_visual_review":"pending root and another critic examining all original images, joins, material and stone scale",
		"limits":"Frozen source-project pose with a valid-floor fixture teleport. A/B isolates the previously audited north orientation; B/C isolates one unapproved generated full corner PNG. Both the native and generated full quads are included in the bounded pixel-isolation test. Exact restoration and localized changed pixels do not constitute visual acceptance. No movement, mining, other corners, other biomes, permanent walls, full-world or FPS acceptance follows.",
	}
	return _write_text("compact-art-study.json", JSON.stringify(report, "\t"))

func _reject(message: String) -> void:
	failures.append(message)
	_save_report()
	_restore_controls()
	push_error("COMPACT_ART_REVIEW_FAIL " + message)
	quit(2)
