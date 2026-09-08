extends RefCounted
## Exact package comparison: DEV8 separate fixed lamps versus cached fixed lighting.
## Keep the one-pass floor, moving lights, shadows, geometry, artwork and framebuffer.
var main: Node
var output_dir: String
var area := "hub"
var world: Node2D
var cases: Array[Dictionary] = []
var cone_state: Array[Dictionary] = []
var failed := false

func _init(game: Node, output: String) -> void:
	main = game
	output_dir = output

func require(ok: bool, message: String) -> bool:
	if not ok:
		failed = true
		push_error("LIGHTING_RELEASE_FAIL " + message)
		main.get_tree().quit(2)
	return ok

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-area="): area = arg.get_slice("=", 1)
	if not require(OS.has_feature("ever_deeper_dev") and DisplayServer.get_name() != "headless", "Rendered DEV pack required"): return
	seed(4608)
	RunState.initialize_persistence(output_dir.path_join("isolated-lighting-save.json"))
	RunState.reset_run(false)
	RunState.world_seed = 4608
	main.game_started = true
	main._dev_seed_victory_state()
	if not require(main._dev_build_all_workshops_state(), "Workshops"): return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop).next_upgrade
			RunState.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not require(bool(RunState.upgrade_workshop(workshop).get("ok", false)), "Upgrade"): return
	RunState.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if area == "other":
		await other_worlds()
	elif area == "hub":
		if not require(main._dev_jump_hub(), "Hub"): return
		world = main.hub_world
		var styles := ["standard", "wide", "focused", "prismatic", "deepheart"]
		var directions := [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN, Vector2(-1,-1)]
		var points := [Vector2(1200,480), Vector2(430,820), Vector2(720,200), Vector2(1200,480), Vector2(430,820)]
		for index in styles.size():
			world.restore_position(points[index])
			await paired("hub-" + styles[index], styles[index], directions[index])
	else:
		var mines := {"mossvein":"mossMine", "moonglass":"moonMine", "emberdeep":"emberMine", "starfall":"starMine"}
		if not require(mines.has(area) and main._dev_jump_mine(String(mines.get(area, "")), 2), "Depth area"): return
		world = main.depth_world
		await paired(area + "-entrance", "standard", Vector2.RIGHT)
		var edge := nearest_mineable_edge()
		if not require(not edge.is_empty(), "Mineable terrain beside an open cell"): return
		world.restore_position(edge.stand)
		world.player.set_facing(Vector2(edge.direction))
		world.current_target_cell = edge.cell
		world.current_target_kind = "terrain"
		var mined := false
		for hit in 32:
			if not require(world.mine_once(), "Terrain hit"): return
			if not world._terrain_is_solid(edge.cell):
				mined = true
				break
		if not require(mined and RunState.dug_cells(String(mines[area]), 2).has(world._cell_index(edge.cell)), "Mining opens and persists the cell"): return
		await paired(area + "-mined-corner", "wide", Vector2(edge.direction))
		var gates: Array = world.get_drill_gates()
		if area == "starfall":
			# Starfall's authored Depth 2 has no drillGated deposits. Review its
			# actual forge courtyard; the other three profiles cover drill gates.
			if not require(gates.is_empty(), "Starfall has no authored drill gate"): return
			var forge: Dictionary = world.station_positions.forge
			world.restore_position(Vector2(float(forge.x), float(forge.y)) + Vector2(0, 100))
			await paired(area + "-forge", "focused", Vector2.UP)
		else:
			if not require(not gates.is_empty() and not gates[0].positions.is_empty(), "Drill gate fixture"): return
			world.restore_position(Vector2(gates[0].positions[0]) + Vector2(0, 100))
			await paired(area + "-gate", "focused", Vector2.UP)
		# Isolated reached-corner fixture: retain the permanent outer wall unchanged.
		for row in range(1, 5):
			for col in range(1, 5):
				world.terrain_hp[world._cell_index(Vector2i(col, row))] = 0
		world.restore_position(world._cell_center(Vector2i(2, 2)))
		world._request_redraw()
		if not require(not world._hit_terrain(Vector2i(0, 1)) and world._terrain_is_solid(Vector2i(0, 1)), "Permanent wall survives mining"): return
		await paired(area + "-permanent-corner", "prismatic", Vector2(-1,-1))
	if failed: return
	var report := {"version":preload("res://scripts/ui/premium_menu.gd").release_version(), "area":area, "rendered":true, "physical_iphone":false, "window":str(DisplayServer.window_get_size()), "cases":cases, "candidate_restored":true}
	FileAccess.open(output_dir.path_join("lighting-release.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("LIGHTING_RELEASE_REVIEW_OK " + JSON.stringify(report))
	main.get_tree().quit(0)

func other_worlds() -> void:
	main._dev_jump_surface()
	world = main.surface_world
	await paired("surface", "wide", Vector2.UP)
	for mine_id in main.MINE_IDS:
		if not require(main._dev_jump_mine(mine_id, 1), "Depth 1"): return
		world = main.mine_world
		await paired(String(mine_id) + "-depth1", "wide", Vector2.LEFT)
	# This mature fixture has already won. Use the existing saved-location restore
	# path; ordinary post-victory entry correctly routes to Endless instead.
	main._enter_deepheart(false, false, true)
	if not require(main.phase == "deepheart", "Restored Deepheart fixture"): return
	world = main.deepheart_world
	await paired("deepheart", "deepheart", Vector2.RIGHT)
	for depth in [1, 12]:
		if not require(main._dev_jump_endless(depth), "Endless"): return
		world = main.endless_world
		await paired("endless-" + str(depth), "focused", Vector2.DOWN)

func nearest_mineable_edge() -> Dictionary:
	var best := {}
	var distance := INF
	for row in range(1, int(world.rows) - 1):
		for col in range(1, int(world.cols) - 1):
			var cell := Vector2i(col, row)
			if not world._terrain_is_solid(cell): continue
			for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
				var neighbor: Vector2i = cell - direction
				if world._terrain_is_solid(neighbor): continue
				var stand: Vector2 = world._cell_center(neighbor)
				var next_distance: float = stand.distance_squared_to(world.player.global_position)
				if next_distance >= distance or world._player_collides(stand): continue
				distance = next_distance
				best = {"cell":cell, "stand":stand, "direction":direction}
	return best

func paired(label: String, style: String, direction: Vector2) -> void:
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	world.player.set_facing(direction)
	for node in world.find_children("HelmetCone", "PointLight2D", true, false):
		var lamp: HeadlampBeam = node.get_parent()
		lamp.preview_settings = {"style":style, "range_multiplier":1.4, "energy_multiplier":1.3}
		lamp.refresh_workshop_effects()
		lamp.set_direction(direction)
	for frame in 5: await main.get_tree().process_frame
	if world.get("static_light_field") != null:
		for frame in 20:
			if not world.static_light_field.baking: break
			await main.get_tree().process_frame
		if world.static_light_field._sources.size() >= 2 and world.static_light_field.field_bounds.size.x <= 2048 and world.static_light_field.field_bounds.size.y <= 2048:
			if not require(world.static_light_field.ready_for_use, "Fixed field prepared " + label): return
	if cases.is_empty() and area in ["hub", "mossvein"]:
		var meter: RefCounted = load("res://scripts/qa/suites/light_cost.gd").new(main, output_dir)
		set_variant(false)
		await meter.measure("dev8_reference", 45.0)
		set_variant(true)
		await meter.measure("fixed_field", 45.0)
		set_variant(false)
		await meter.measure("restored_reference", 20.0)
		FileAccess.open(output_dir.path_join("fixed-field-performance.json"), FileAccess.WRITE).store_string(JSON.stringify({"physical_iphone":false,"area":area,"stages":meter.rows}, "\t"))
	var prior_scale: float = Engine.time_scale
	main.get_tree().paused = true
	Engine.time_scale = 0.0
	cone_state.clear()
	for node in world.find_children("HelmetCone", "PointLight2D", true, false):
		var lamp: HeadlampBeam = node.get_parent()
		var info: Dictionary = lamp.debug_snapshot()
		var region: Rect2i = info.source_texture_region
		var cropped: Image = node.texture.get_image()
		var full := Image.create(256, 256, false, Image.FORMAT_RGBA8)
		full.fill(Color.TRANSPARENT)
		full.blit_rect(cropped, Rect2i(Vector2i.ZERO, cropped.get_size()), region.position)
		if not require(cropped.get_size() == Vector2i(127,103) and full.get_region(region).get_data() == cropped.get_data(), "Lossless cone reconstruction"): return
		if not require(info.shadow_origin_preserved and info.occluded and is_zero_approx(float(info.border_alpha_max)), "Shadow emitter and transparent border"): return
		cone_state.append({"node":node, "cropped":node.texture, "offset":node.offset, "full":ImageTexture.create_from_image(full), "shadow":node.shadow_enabled, "enabled":node.enabled, "energy":node.energy, "position":node.global_position})
	if area != "other" and not require(not cone_state.is_empty(), "Active headlamp in " + label): return
	for variant in ["baseline", "candidate", "baseline-control"]:
		set_variant(variant == "candidate")
		for frame in 4: await main.get_tree().process_frame
		if world.get("static_light_field") != null and world.static_light_field.ready_for_use:
			if not require(world.static_light_field.debug_snapshot().applied == (variant == "candidate"), "Requested fixed-field state " + variant): return
			for source in world.static_light_field._sources:
				if not require(is_instance_valid(source.node) and source.node.enabled == (bool(source.enabled) and variant != "candidate"), "Original lamp state " + variant): return
		await RenderingServer.frame_post_draw
		var capture: Image = main.get_viewport().get_texture().get_image()
		if not require(capture.get_size() == DisplayServer.window_get_size(), "Physical render buffer"): return
		capture.save_png(output_dir.path_join(label + "-" + variant + ".png"))
	set_variant(true)
	for entry in cone_state:
		if not require(entry.node.texture == entry.cropped and entry.node.offset == entry.offset and entry.node.shadow_enabled == entry.shadow and entry.node.enabled == entry.enabled and entry.node.energy == entry.energy and entry.node.global_position == entry.position, "Candidate and lights restored"): return
	Engine.time_scale = prior_scale
	main.get_tree().paused = false
	for node in world.find_children("HelmetCone", "PointLight2D", true, false):
		var lamp: HeadlampBeam = node.get_parent()
		lamp.preview_settings = {}
		lamp.refresh_workshop_effects()
	cases.append({"id":label, "style":style, "direction":str(direction), "cones":cone_state.size(), "position":str(world.player.global_position), "fixed_field":world.static_light_field.debug_snapshot() if world.get("static_light_field") != null else {}})
	print("LIGHTING_RELEASE_CASE " + JSON.stringify(cases.back()))

func set_variant(optimized: bool) -> void:
	if world.get("static_light_field") != null: world.static_light_field.enabled = optimized
	if world.get("lit_floor_chunks") != null:
		world.lit_floor_chunks.enabled = true
		world.lit_floor_chunks.composite_pass = true
	if world.get("lit_draw_sections") != null: world.lit_draw_sections.enabled = true
	for entry in cone_state:
		entry.node.texture = entry.cropped
		entry.node.offset = entry.offset
	world.queue_redraw()
