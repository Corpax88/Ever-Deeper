extends SceneTree
## Rendered comparison only; synthetic topology is not a mining/playability test.
## Run in the isolated wall-study worktree. No production mode is enabled by default.
const Mapper = preload("res://tools/wall_pilot/native_wall_mapper.gd")
const BASE_TREE: String = "6810ea1cd4b6990ca6ee0adebebb9fbe02322c4b"
const MATERIAL_NAMES: Array[String] = [
	"rootwound", "moonglass", "emberdeep", "voidstar", "mossvein", "bedrock",
]
const EXCAVATED_CELLS: Array[Vector2i] = [Vector2i(29, 12), Vector2i(29, 13), Vector2i(30, 13)]

var output: String = ""
var case_filter: String = "all"
var variant_filter: String = "both"
var hold: bool = false
var main: Node
var world: Node
var captures: Array[Dictionary] = []
var checks: Array[Dictionary] = []
var current_case: String = ""
var current_fixture: String = ""
var case_label: Label
var baseline_button: Button
var candidate_button: Button
var topology_labels: Node2D
var capture_failed: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--case="): case_filter = arg.trim_prefix("--case=")
		elif arg.begins_with("--variant="): variant_filter = arg.trim_prefix("--variant=")
		elif arg == "--hold": hold = true
	if output.is_empty() or DisplayServer.get_name() == "headless":
		printerr("Wall study requires --output and a graphical display.")
		quit(2)
		return
	if variant_filter not in ["both", "baseline", "candidate"]:
		printerr("--variant must be both, baseline, or candidate.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_endless(6)
	world = main.endless_world
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	world.player.prepare_visual_cache()
	for frame in 600:
		if world.player.visual.active_gear == "worn": break
		await process_frame
	if world.player.visual.active_gear != "worn":
		printerr("Wall study could not prepare the fixed hero pose.")
		quit(3)
		return
	# Freeze the scene, including lights and camera scripts. The root harness and
	# its separate CanvasLayer stay active; draw callbacks still use the real game.
	main.process_mode = Node.PROCESS_MODE_DISABLED
	world.player.control_enabled = false
	main.get_node("HUD").hide()
	main.get_node("CompanionInterface").hide()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null: mole.hide()
	var camera: Camera2D = world.player.camera
	camera.position_smoothing_enabled = false
	camera.limit_smoothed = false
	camera.drag_horizontal_enabled = false
	camera.drag_vertical_enabled = false
	_build_overlay()
	await _capture_boundaries()
	await _capture_topologies()
	if captures.is_empty():
		printerr("No study case matched: " + case_filter)
		quit(2)
		return
	_write_report()
	print("WALL_STUDY_CAPTURED ", captures.size(), " frames; visual review remains required.")
	if not hold:
		quit(3 if capture_failed else 0)


func _build_overlay() -> void:
	var overlay: CanvasLayer = CanvasLayer.new()
	overlay.name = "WallStudyComparisonControls"
	overlay.layer = 120
	root.add_child(overlay)
	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(12, 12)
	overlay.add_child(panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var group: ButtonGroup = ButtonGroup.new()
	baseline_button = Button.new()
	baseline_button.text = "Baseline"
	baseline_button.toggle_mode = true
	baseline_button.button_group = group
	baseline_button.pressed.connect(_set_variant.bind(false))
	row.add_child(baseline_button)
	candidate_button = Button.new()
	candidate_button.text = "Candidate"
	candidate_button.toggle_mode = true
	candidate_button.button_group = group
	candidate_button.pressed.connect(_set_variant.bind(true))
	row.add_child(candidate_button)
	case_label = Label.new()
	case_label.add_theme_font_size_override("font_size", 16)
	row.add_child(case_label)


func _set_variant(candidate: bool) -> void:
	world.set_wall_study_mode(candidate, world.wall_study_force_material)
	baseline_button.set_pressed_no_signal(not candidate)
	candidate_button.set_pressed_no_signal(candidate)
	case_label.text = "%s | %s | unreviewed study" % [current_case, current_fixture]


func _wants(id: String, group: String) -> bool:
	return case_filter == "all" or case_filter == group or case_filter == id


func _capture_boundaries() -> void:
	for depth in range(5, 10):
		var id: String = "boundary_%d_%d" % [depth, depth + 1]
		var wants_rebase: bool = depth == 7 and _wants("boundary_7_8_rebased", "boundaries")
		if not _wants(id, "boundaries") and not wants_rebase: continue
		world.current_depth = depth
		world.set_wall_study_mode(false)
		world._generate_stream_window(depth)
		var column: int = world.DeepLayout.entrance_column(4608, depth + 1)
		_pose_hero(world._nearest_walkable_position(Vector2(column * 64 + 32, 1388)))
		_fixed_camera(world.player.position, Vector2.ONE)
		if _wants(id, "boundaries"):
			await _capture_pair(id, "real generated boundary")
		if wants_rebase:
			var before_absolute: Vector2 = _absolute_player()
			world._rebase_stream_window(depth - 1)
			_fixed_camera(world.player.position, Vector2.ONE)
			checks.append({"id": "boundary_rebase_keeps_absolute_player",
				"passed": before_absolute.is_equal_approx(_absolute_player())})
			await _capture_pair("boundary_7_8_rebased", "same absolute location after rebase")


func _capture_topologies() -> void:
	for material_index in MATERIAL_NAMES.size():
		var prefix: String = "topology_" + MATERIAL_NAMES[material_index]
		var wants_before: bool = _wants(prefix + "_intact", "topology") or case_filter == prefix
		var wants_after: bool = _wants(prefix + "_excavated", "topology") or case_filter == prefix
		if not wants_before and not wants_after: continue
		var depth: int = 5 + material_index if material_index < 5 else 5
		world.current_depth = depth
		world._generate_stream_window(depth)
		world._clear_generated_visuals()
		world.resources.clear()
		world.discovery_sites.clear()
		world._native_relics.clear()
		world._ground_props.clear()
		world.dig_damage.clear()
		world._crusher_impacts.clear()
		world.floor_cells.fill(1)
		# One native rock block exposes all four turn orientations. Stair steps,
		# a one-cell pillar, a narrow column, and an excavation provide other joins.
		_solid_rect(Rect2i(8, 7, 6, 4))
		for col in range(17, 24):
			var top: int = 7 + col - 17
			_solid_rect(Rect2i(col, top, 1, 15 - top))
		_solid_rect(Rect2i(28, 7, 1, 1))
		_solid_rect(Rect2i(31, 7, 1, 3))
		_solid_rect(Rect2i(27, 12, 6, 4))
		world._base_floor_cells = world.floor_cells.duplicate()
		world.set_wall_study_mode(false, 1 if material_index == 5 else 0)
		_build_topology_labels()
		_pose_hero(Vector2(1000, 916))
		_fixed_camera(Vector2(1312, 736), Vector2.ONE * 0.82)
		if wants_before:
			await _capture_pair(prefix + "_intact", "synthetic shape fixture; native game renderer")
		for cell in EXCAVATED_CELLS: world._set_floor(cell, true)
		if wants_after:
			await _capture_pair(prefix + "_excavated", "synthetic excavation; not a mining test")
		if is_instance_valid(topology_labels):
			topology_labels.queue_free()
			topology_labels = null


func _solid_rect(rect: Rect2i) -> void:
	for row in range(rect.position.y, rect.end.y):
		for col in range(rect.position.x, rect.end.x):
			world._set_floor(Vector2i(col, row), false)


func _build_topology_labels() -> void:
	topology_labels = Node2D.new()
	topology_labels.name = "SyntheticTopologyLabels"
	topology_labels.z_index = 4095
	world.add_child(topology_labels)
	_add_world_label("Four turns", Vector2(8 * 64, 6 * 64))
	_add_world_label("Stairs", Vector2(17 * 64, 6 * 64))
	_add_world_label("Pillar / narrow column", Vector2(27 * 64, 6 * 64))
	_add_world_label("Excavation", Vector2(27 * 64, 11 * 64))


func _add_world_label(title: String, position: Vector2) -> void:
	var label: Label = Label.new()
	label.text = title
	label.position = position
	label.add_theme_font_size_override("font_size", 21)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 5)
	topology_labels.add_child(label)


func _pose_hero(position: Vector2) -> void:
	world.player.position = position
	world.player.velocity = Vector2.ZERO
	world.player.z_index = world.actor_draw_depth(position)
	world.player.set_facing(Vector2.DOWN)
	world.player._update_visual(false)
	world.player.visual._draw_frame(0.0)


func _fixed_camera(center: Vector2, zoom: Vector2) -> void:
	var camera: Camera2D = world.player.camera
	camera.zoom = zoom
	camera.offset = Vector2.ZERO
	camera.position = center - world.player.global_position
	camera.reset_smoothing()
	camera.force_update_scroll()


func _absolute_player() -> Vector2:
	return world.player.position + Vector2(0, (world.window_start_depth - 1) * world.CHUNK_HEIGHT)


func _geometry_hash() -> String:
	var hashing: HashingContext = HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(world.floor_cells)
	return hashing.finish().hex_encode()


func _capture_pair(id: String, fixture: String) -> void:
	current_case = id
	current_fixture = fixture
	var terrain_before: String = _geometry_hash()
	var absolute_before: Vector2 = _absolute_player()
	var camera_before: Vector2 = world.player.camera.get_screen_center_position()
	for candidate in [false, true]:
		if variant_filter == "baseline" and candidate: continue
		if variant_filter == "candidate" and not candidate: continue
		_set_variant(candidate)
		await _capture(id, candidate, fixture)
	var stable: bool = terrain_before == _geometry_hash() and absolute_before.is_equal_approx(_absolute_player())
	stable = stable and camera_before.is_equal_approx(world.player.camera.get_screen_center_position())
	checks.append({"id": id + "_toggle_keeps_terrain_and_camera", "passed": stable})
	if not stable: capture_failed = true


func _capture(id: String, candidate: bool, fixture: String) -> void:
	world.queue_redraw()
	for frame in 5: await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var variant: String = "candidate" if candidate else "baseline"
	var filename: String = id + "_" + variant + ".png"
	var error: Error = image.save_png(output.path_join(filename))
	if error != OK:
		printerr("Wall study PNG failed: ", filename, " code ", error)
		capture_failed = true
	captures.append({
		"id": id, "variant": variant, "file": filename, "fixture": fixture,
		"framebuffer": str(image.get_size()), "player": str(world.player.position),
		"absolute_player": str(_absolute_player()), "window_start_depth": world.window_start_depth,
		"camera": str(world.player.camera.get_screen_center_position()),
		"zoom": str(world.player.camera.zoom), "floor_sha256": _geometry_hash(),
		"forced_material": world.wall_study_force_material,
		"png_saved": error == OK,
	})


func _write_report() -> void:
	var source_paths: Array[String] = [
		"res://tools/wall_pilot/native_wall_mapper.gd",
		"res://tools/wall_pilot/native_wall_contours.json",
		"res://tools/wall_pilot/build_native_contours.py",
		"res://tools/wall_pilot/select_native_bands.py",
		"res://tools/wall_pilot/native_band_selection.json",
		"res://tools/wall_pilot/validate_native_wall_v3.py",
		"res://tools/wall_pilot/native_wall_v3_proof.json",
		"res://tools/wall_pilot/review_deep_wall_study.gd",
		"res://scripts/world/endless_descent_world.gd",
		"res://scripts/world/cave_edge_asset_drawer.gd",
	]
	var source_hashes: Dictionary = {}
	for path in source_paths: source_hashes[path] = FileAccess.get_sha256(path)
	var report: Dictionary = {
		"base_tree": BASE_TREE, "source_sha256": source_hashes,
		"rendered": true, "review_status": "unreviewed", "visual_acceptance": false,
		"physical_iphone": false, "performance_evidence": false, "gameplay_evidence": false,
		"godot": Engine.get_version_info(), "display": DisplayServer.get_name(),
		"video_adapter": RenderingServer.get_video_adapter_name(),
		"case_filter": case_filter, "variant_filter": variant_filter, "seed": 4608,
		"profiles": Mapper.profile_report(64.0), "checks": checks, "captures": captures,
		"limitations": [
			"Native leg source bands are not authored seamless loops; inspect every repeat join.",
			"Topology terrain is synthetic and uses a render-only material override.",
			"Captured poses are frozen; this does not verify travel, mining, animation, or device performance.",
			"Study defaults off and does not change the shared CaveEdgeAssetDrawer.",
		],
	}
	var file: FileAccess = FileAccess.open(output.path_join("wall-study.json"), FileAccess.WRITE)
	if file == null:
		printerr("Could not write wall-study.json")
		capture_failed = true
		return
	file.store_string(JSON.stringify(report, "\t"))
