extends "res://tools/review_terrain_cache.gd"
## Same warm-cache/fresh-draw method as the existing terrain review, limited to
## Depth 2. Reference overrides only the original draw dispatch/fingerprint.
var variant: String = "local"
var timing_seconds: float = 20.0
var timing: Dictionary = {}
var failures: Array[String] = []
var world: Node
var reference_source: String = "0623b63bc9ddb449c8b46d98e483c6b164a619f9"

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument.begins_with("--variant="): variant = argument.trim_prefix("--variant=")
		elif argument.begins_with("--timing-seconds="): timing_seconds = float(argument.trim_prefix("--timing-seconds="))
	if not output.is_absolute_path() or variant not in ["local", "reference"] or DisplayServer.get_name() == "headless" or timing_seconds < 0.0 or timing_seconds > 60.0:
		push_error("Require rendered --output=/absolute, --variant=local|reference and timing 0–60 seconds")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	if variant == "reference":
		main.get_node("RootwoundWorld").set_script(load("res://tools/depth_strip_pilot/global_reference.gd"))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	_check(main._dev_jump_mine("emberMine", 2), "Ember Depth 2 entered")
	world = main.depth_world
	await create_timer(4.0).timeout
	_freeze(main)
	main.get_node("CompanionInterface").hide()
	world.station_animation_clock = 0.0
	world.player.set_facing(Vector2.RIGHT)
	world.player.visual._idle_clock = 0.0
	world.player.visual._last_frame = -1
	world.player.visual.set_state("right", 0, false)
	var mole: Node = world.get_node("MoleCompanion")
	mole._spawn_beside_hero()
	mole.facing = Vector2.RIGHT
	mole.animation_clock = 0.0
	mole.idle_clock = 0.0
	mole.feedback_time = 0.0
	mole._draw_pose()
	# Terrain comparison leaves all light nodes active. Freeze the actor visuals
	# too; the comparison is within each run, not a claim about animation.
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.position = Vector2.ZERO
	world.player.camera.offset = Vector2.ZERO
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	await _pair(world, "ember_initial")
	if timing_seconds > 0.0: await _measure_fixed_damage()

	var cell: Vector2i = _near_wall(world, false)
	_check(cell.x >= 0, "A genuine terrain cell is available")
	if cell.x < 0:
		_finish()
		return
	var hp_before: int = int(world.terrain_hp[world._cell_index(cell)])
	world._hit_terrain(cell)
	_check(int(world.terrain_hp[world._cell_index(cell)]) < hp_before, "Real terrain hit changes HP")
	await _pair(world, "ember_hit")
	cell = _near_wall(world, false)
	var terrain_before: int = hash(world.terrain_hp)
	world._apply_depth_crusher_wave(cell, {"power":9999})
	_check(hash(world.terrain_hp) != terrain_before, "Crusher wave changes actual terrain")
	await _pair(world, "ember_crusher")
	cell = _near_pet_wall()
	_check(cell.x >= 0, "Pet has a legal exposed dig cell")
	if cell.x >= 0:
		_check(world.companion_dig(world._cell_center(cell), true) > 0, "Real companion dig removes terrain")
		await _pair(world, "ember_pet")

	var discovery_tested: bool = false
	for cavern in world.caverns:
		if bool(cavern.discovered): continue
		_set_camera(Vector2(cavern.x, cavern.y))
		await _pair(world, "ember_chamber_concealed")
		world._discover_cavern_from_cell(int(cavern.boundary[0]))
		_check(world._cavern_is_discovered(String(cavern.id)), "Real chamber discovery completes")
		await _pair(world, "ember_chamber_discovered")
		discovery_tested = true
		break
	_check(discovery_tested, "Concealed/discovered chamber fixture ran")

	var resource_tested: bool = false
	for index in world.rocks.size():
		var rock: Dictionary = world.rocks[index]
		if bool(rock.drill_gated) or not String(rock.pocket_reward_id).is_empty() or bool(rock.broken): continue
		if not String(rock.cavern_id).is_empty() and not world._cavern_is_discovered(String(rock.cavern_id)): continue
		var resource_cell: Vector2i = Vector2i(rock.cell)
		# Explicit diagnostic setup, outside timing: open a real two-cell approach.
		for offset in [Vector2i.ZERO, Vector2i.DOWN, Vector2i(0, 2)]:
			var opening: Vector2i = resource_cell + offset
			if not world._cell_in_bounds(opening) or world._terrain_is_bedrock(opening): continue
			world.terrain_hp[world._cell_index(opening)] = 0
		if not world._rock_is_exposed(index): continue
		_set_camera(world._cell_center(resource_cell + Vector2i(0, 2)))
		await _pair(world, "ember_resource_intact")
		world._break_rock(index)
		_check(bool(world.rocks[index].broken), "Real resource depletion completes")
		await _pair(world, "ember_resource_depleted")
		world.rocks[index].respawn_until_unix = 1.0
		world.rocks[index].respawn_remaining = 0.0
		world._update_rocks()
		_check(not bool(world.rocks[index].broken), "Expired resource respawns away from player")
		await _pair(world, "ember_resource_respawned")
		# Covered ore uses the same local rock flags to decide its mineral hint.
		world.terrain_hp[world._cell_index(resource_cell)] = world.terrain_max_hp
		await _pair(world, "ember_hint_intact")
		world.rocks[index].broken = true
		await _pair(world, "ember_hint_depleted")
		world.rocks[index].broken = false
		world.rocks[index].drill_gated = true
		await _pair(world, "ember_hint_gated")
		world.rocks[index].drill_gated = false
		await _pair(world, "ember_hint_restored")
		resource_tested = true
		break
	_check(resource_tested, "Depletion, respawn and mineral-hint fixtures ran")
	await _review_strip_boundary_and_camera()
	# The same strip keys can survive a rebuilt world with different native art.
	for mine_id in ["moonMine", "mossMine", "starMine", "emberMine"]:
		_check(main._dev_jump_mine(mine_id, 2), "Entered " + mine_id)
		_freeze(main)
		world.station_animation_clock = 0.0
		_set_camera(world.player.position)
		await _pair(world, "mine_switch_" + mine_id)
	_finish()

func _pair(target_world: Node, id: String) -> void:
	await super._pair(target_world, id)
	var cached: Image = Image.load_from_file(output.path_join(id + "-cached.png"))
	var fresh: Image = Image.load_from_file(output.path_join(id + "-fresh.png"))
	var equal: bool = cached.get_size() == fresh.get_size() and cached.get_data() == fresh.get_data()
	var row: Dictionary = samples.back()
	row["exact_rgba"] = equal
	row["framebuffer_size"] = [cached.get_width(), cached.get_height()]
	row["mine"] = world.mine_id
	row["player"] = str(world.player.position)
	row["terrain_hash"] = hash(world.terrain_hp)
	row["concealment_hash"] = hash(world.concealed_cells)
	_check(equal, "Warm cache equals fresh draw: " + id)
	_write_report(false)

func _set_camera(position: Vector2) -> void:
	world.player.position = position
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()

func _near_pet_wall() -> Vector2i:
	var center: Vector2i = world._world_to_cell(world.player.position)
	for radius in range(1, 10):
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var cell: Vector2i = center + Vector2i(x, y)
				if world.companion_can_dig(world._cell_center(cell)): return cell
	return Vector2i(-1, -1)

func _review_strip_boundary_and_camera() -> void:
	var center: Vector2i = world._world_to_cell(world.player.position)
	var boundary: Vector2i = Vector2i(clampi(center.x / 6 * 6, 6, int(world.cols) - 7), clampi(center.y, 2, int(world.rows) - 3))
	# Direct array restoration intentionally bypasses every gameplay mutator.
	# The center lies at column 6*n, so its two sides occupy different strips.
	for y in range(boundary.y - 1, boundary.y + 2):
		for x in range(boundary.x - 1, boundary.x + 2):
			world.terrain_hp[world._cell_index(Vector2i(x, y))] = world.terrain_max_hp
	_set_camera(world._cell_center(boundary + Vector2i(0, 2)))
	await _pair(world, "strip_boundary_intact")
	world.terrain_hp[world._cell_index(boundary)] = 0
	await _pair(world, "strip_boundary_open")
	world.concealed_cells[world._cell_index(boundary)] = true
	await _pair(world, "strip_boundary_concealed")
	world.concealed_cells.erase(world._cell_index(boundary))
	await _pair(world, "strip_boundary_revealed")
	var original_position: Vector2 = world.player.position
	var original_zoom: Vector2 = world.player.camera.zoom
	_set_camera(original_position + Vector2(96, 48))
	await _pair(world, "camera_neighbor")
	world.player.camera.zoom = original_zoom * 0.8
	world.player.camera.force_update_scroll()
	await _pair(world, "camera_zoom_out")
	world.player.camera.zoom = original_zoom
	_set_camera(Vector2(original_position.x, clampf(original_position.y + 1700.0, 96.0, float(world.world_size.y) - 96.0)))
	await _pair(world, "camera_far")
	world.terrain_hp[world._cell_index(boundary)] = maxi(1, int(world.terrain_max_hp) / 3)
	await _pair(world, "offscreen_edit")
	_set_camera(original_position)
	await _pair(world, "camera_return_after_edit")

func _measure_fixed_damage() -> void:
	# An isolated redraw-cost diagnostic, not ordinary gameplay or minimum-FPS
	# acceptance. Four HP states change one real cell at 5 Hz; all samples remain.
	var cell: Vector2i = _near_wall(world, false)
	_check(cell.x >= 0, "Fixed-damage cell exists")
	if cell.x < 0: return
	var index: int = world._cell_index(cell)
	var original_hp: int = int(world.terrain_hp[index])
	var original_terrain_hash: int = hash(world.terrain_hp)
	var before: Dictionary = world.lit_draw_sections.debug_snapshot()
	var lights: Array[Dictionary] = []
	for light in world.find_children("*", "PointLight2D", true, false):
		lights.append({"path":str(world.get_path_to(light)), "position":str(light.global_position), "energy":light.energy, "enabled":light.enabled, "visible":light.visible, "rotation":light.global_rotation, "texture_scale":light.texture_scale})
	var intervals: Array[float] = []
	var began: int = Time.get_ticks_usec()
	var previous: int = began
	var previous_step: int = -1
	var mutations: int = 0
	while float(Time.get_ticks_usec() - began) < timing_seconds * 1000000.0:
		var step: int = int((Time.get_ticks_usec() - began) / 200000)
		if step != previous_step:
			world.terrain_hp[index] = maxi(1, original_hp - (step % 4) * maxi(1, original_hp / 5))
			world.queue_redraw()
			previous_step = step
			mutations += 1
		await process_frame
		var now: int = Time.get_ticks_usec()
		intervals.append(float(now - previous) / 1000.0)
		previous = now
	var after: Dictionary = world.lit_draw_sections.debug_snapshot()
	var total_ms: float = float(previous - began) / 1000.0
	var sorted: Array[float] = intervals.duplicate()
	sorted.sort()
	timing = {"scope":"Frozen one-cell damage redraw at 5 Hz; not sustained gameplay", "seconds":total_ms / 1000.0, "frames":intervals.size(), "intervals_ms":intervals, "fps":1000.0 * intervals.size() / total_ms, "p95_ms":sorted[floori(sorted.size() * 0.95)], "mutations":mutations, "cell":str(cell), "terrain_hash_at_start":original_terrain_hash, "terrain_hash_at_end":hash(world.terrain_hp), "lights":lights, "before":before, "after":after}
	world.terrain_hp[index] = original_hp
	await _pair(world, "fixed_damage_restored")

func _check(condition: bool, label: String) -> void:
	if condition: return
	failures.append(label)
	# Keep an explicit failed verdict/exit code while allowing subsequent pairs
	# to expose independent stale-cache cases. The first aborted control remains.
	print("DEPTH_STRIP_ASSERTION_MISMATCH: ", label)

func _write_report(complete: bool) -> void:
	var hashes: Dictionary = {}
	for path in ["scripts/world/depth/rootwound_world.gd", "scripts/lighting/lit_draw_sections.gd", "tools/review_terrain_cache.gd", "tools/depth_strip_pilot/global_reference.gd", "tools/depth_strip_pilot/review_depth_strip_cache.gd"]:
		hashes[path] = FileAccess.get_sha256("res://" + path)
	var report: Dictionary = {"complete":complete, "passed":complete and failures.is_empty(), "failures":failures, "variant":variant, "reference_source":reference_source, "physical_iphone":false, "rendered":true, "renderer":RenderingServer.get_video_adapter_name(), "seed":state.world_seed, "pairs":samples, "timing":timing, "source_sha256":hashes}
	FileAccess.open(output.path_join("depth-strip-review.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))

func _finish() -> void:
	_write_report(true)
	print("DEPTH_STRIP_REVIEW_FINISHED variant=", variant, " pairs=", samples.size(), " failures=", failures.size())
	if failures.is_empty(): print("DEPTH_STRIP_REVIEW_COMPLETE variant=", variant, " pairs=", samples.size())
	quit(0 if failures.is_empty() else 4)
