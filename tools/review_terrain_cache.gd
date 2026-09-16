extends SceneTree
## Compare a warm cache after real mutations with freshly issued draw commands.
var main: Node
var state: Node
var output: String
var samples: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_mine("emberMine", 2)
	await create_timer(4.0).timeout
	var world: Node = main.depth_world
	_freeze(world)
	await _pair(world, "ember_initial")
	var cell: Vector2i = _near_wall(world, false)
	assert(cell.x >= 0)
	world._hit_terrain(cell)
	await _pair(world, "ember_hit")
	world._apply_depth_crusher_wave(cell, {"power":9999})
	await _pair(world, "ember_crusher")
	cell = _near_wall(world, false)
	world.companion_dig(world._cell_center(cell), true)
	await _pair(world, "ember_pet")
	for cavern in world.caverns:
		if not bool(cavern.discovered):
			world._discover_cavern_from_cell(int(cavern.boundary[0]))
			world.player.global_position = Vector2(cavern.x, cavern.y)
			break
	await _pair(world, "ember_discovery")
	for index in world.rocks.size():
		var rock: Dictionary = world.rocks[index]
		if bool(rock.drill_gated) or not String(rock.pocket_reward_id).is_empty() or bool(rock.broken): continue
		var resource_cell: Vector2i = world._world_to_cell(Vector2(rock.position))
		# Open a genuine two-cell approach; do not stand inside the resource.
		for offset in [Vector2i.ZERO, Vector2i.DOWN, Vector2i(0, 2)]:
			var opening: Vector2i = resource_cell + offset
			if world._terrain_is_bedrock(opening): continue
			world.terrain_hp[world._cell_index(opening)] = 0
		if not world._rock_is_exposed(index): continue
		world.player.global_position = world._cell_center(resource_cell + Vector2i(0, 2))
		await _pair(world, "ember_resource_intact")
		world._break_rock(index)
		await _pair(world, "ember_depleted")
		world.rocks[index].respawn_until_unix = 1.0
		world.rocks[index].respawn_remaining = 0.0
		world._update_rocks()
		assert(not bool(world.rocks[index].broken), "Expired resource really respawns away from the player")
		await _pair(world, "ember_respawn")
		break
	main._dev_jump_endless(12)
	await create_timer(4.0).timeout
	world = main.endless_world
	_freeze(world)
	await _pair(world, "deep_initial")
	cell = _near_wall(world, true)
	assert(cell.x >= 0)
	world._strike_wall(cell, .66)
	await _pair(world, "deep_hit")
	world._apply_crusher_wave(cell, {"power":9999})
	await _pair(world, "deep_crusher")
	cell = _near_wall(world, true)
	world.companion_dig(world._cell_center(cell), true)
	await _pair(world, "deep_pet")
	# Cross the real band boundary. The stream owner keeps one complete band
	# behind the player; a forced start+1 at the old position is not gameplay.
	world.player.position.y = world.CHUNK_HEIGHT * 2.0 + 64.0
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world._update_stream_depth()
	await _pair(world, "deep_rebase_down")
	world.player.position.y = world.CHUNK_HEIGHT - 64.0
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world._update_stream_depth()
	await _pair(world, "deep_rebase_up")
	# Direct state replacement must update both sides of strip/row boundaries.
	# This deliberately bypasses mutator callbacks, like a restored terrain array.
	for row in [1, world.DeepLayout.CHUNK_ROWS - 1, world.GRID_SIZE.y - 2]:
		var boundary: Vector2i = Vector2i(19, row)
		world.player.position = world._cell_center(boundary + Vector2i(0, 2 if row < world.GRID_SIZE.y - 2 else -2))
		for y in range(row - 1, row + 2):
			for x in range(18, 22): world._set_floor(Vector2i(x, y), false)
		world.dig_damage[boundary] = 40
		await _pair(world, "deep_boundary_%d_intact" % row)
		world._set_floor(boundary, true)
		world.dig_damage.erase(boundary)
		await _pair(world, "deep_boundary_%d_open" % row)
	FileAccess.open(output.path_join("cache-review.json"), FileAccess.WRITE).store_string(JSON.stringify({"rendered":true,"physical_iphone":false,"pairs":samples}, "\t"))
	quit()

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _pair(world: Node, id: String) -> void:
	# This is terrain-command parity, not a UI animation comparison. Keep
	# transient pickup tweens and guide markers from changing between captures.
	main.get_node("HUD").hide()
	world.player.get_node("ResourcePickupBurst").hide()
	for tween in get_processed_tweens(): tween.pause()
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	world.lit_draw_sections.profile_draws = true
	var requested: Dictionary = world.lit_draw_sections.debug_snapshot()
	world.queue_redraw()
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+"-cached.png"))
	var before: Dictionary = world.lit_draw_sections.debug_snapshot()
	for section in world.lit_draw_sections._cached.values(): section.revision = -1
	world.queue_redraw()
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+"-fresh.png"))
	samples.append({"id":id,"requested":requested,"before":before,"after":world.lit_draw_sections.debug_snapshot(), "mutation_redraws":int(before.redraws)-int(requested.redraws), "mutation_draw_usec":int(before.draw_callback_usec)-int(requested.draw_callback_usec), "mutation_setup_usec":int(before.setup_usec)-int(requested.setup_usec)})

func _near_wall(world: Node, deep: bool) -> Vector2i:
	var center: Vector2i = world._world_to_cell(world.player.position)
	for radius in range(1, 9):
		for y in range(-radius, radius+1):
			for x in range(-radius, radius+1):
				var cell: Vector2i = center + Vector2i(x,y)
				if not world._cell_in_bounds(cell): continue
				if deep:
					if world._cell_diggable(cell) and not world._is_floor(cell) and world._has_floor_neighbor(cell): return cell
				elif world._terrain_is_solid(cell) and not world._terrain_is_bedrock(cell):
					return cell
	return Vector2i(-1,-1)
