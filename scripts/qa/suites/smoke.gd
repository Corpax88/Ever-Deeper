extends "res://scripts/qa/qa_context.gd"
## Smoke checks moved intact from main.gd.


func _run_surface_mountain_independence_smoke() -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	main.phase = "surface"
	main.surface_world.reset_for_new_run()
	main.surface_world.set_active(true)
	var cases: Array[Dictionary] = [
		{
			"mountain_id": "moonglass_mountain", "vein_context": "moonglass_resource",
			"vein_position": Vector2(1820, 700), "mountain_position": Vector2(1580, 650),
			"snapshot_method": "moonglass_resource_snapshot", "mine_method": "_mine_moonglass_resource_once",
			"visual_method": "_update_moonglass_visual",
		},
		{
			"mountain_id": "emberdeep_mountain", "vein_context": "ember_resource",
			"vein_position": Vector2(3078, 1120), "mountain_position": Vector2(2899, 779),
			"snapshot_method": "ember_resource_snapshot", "mine_method": "_mine_timed_surface_resource_once",
			"mine_arg": "ember_fault", "visual_method": "_update_timed_surface_visual",
		},
		{
			"mountain_id": "starfall_mountain", "vein_context": "starfall_resource",
			"vein_position": Vector2(3970, 1130), "mountain_position": Vector2(4300, 770),
			"snapshot_method": "starfall_resource_snapshot", "mine_method": "_mine_timed_surface_resource_once",
			"mine_arg": "starfall_lattice", "visual_method": "_update_timed_surface_visual",
		},
	]
	for case_value in cases:
		var mountain_id= String(case_value.mountain_id)
		var vein_context= String(case_value.vein_context)
		var snapshot_method= String(case_value.snapshot_method)
		main.surface_world.restore_position(Vector2(case_value.vein_position))
		assert (main.surface_context == vein_context, "%s must target its vein independently" % mountain_id)
		var mountain_before_vein: Dictionary = main.surface_world.surface_resource_mountain_snapshot(mountain_id)
		var vein_before: Dictionary = main.surface_world.call(snapshot_method)
		if case_value.has("mine_arg"):
			main.surface_world.call(String(case_value.mine_method), String(case_value.mine_arg))
			main.surface_world.call(String(case_value.visual_method), String(case_value.mine_arg))
		else:
			main.surface_world.call(String(case_value.mine_method))
			main.surface_world.call(String(case_value.visual_method))
		var mountain_after_vein: Dictionary = main.surface_world.surface_resource_mountain_snapshot(mountain_id)
		var vein_after: Dictionary = main.surface_world.call(snapshot_method)
		assert (Array(vein_after.nodes) != Array(vein_before.nodes), "%s vein hit must change a vein node" % mountain_id)
		assert (int(mountain_after_vein.hp) == int(mountain_before_vein.hp), "%s vein hit must not damage the mountain" % mountain_id)
		assert (int(mountain_after_vein.hit_count) == int(mountain_before_vein.hit_count), "%s vein hit must not trigger mountain effects" % mountain_id)
		assert (Vector2(mountain_after_vein.position).is_equal_approx(Vector2(mountain_before_vein.position)), "%s vein hit must not move the mountain" % mountain_id)
		assert (is_equal_approx(float(mountain_after_vein.rotation), float(mountain_before_vein.rotation)), "%s vein hit must not rotate the mountain" % mountain_id)

		main.surface_world.restore_position(Vector2(case_value.mountain_position))
		assert (main.surface_context == mountain_id, "%s must expose its own mining context" % mountain_id)
		assert (main.mine_button.visible, "%s must expose the touch mining control" % mountain_id)
		var vein_before_mountain: Dictionary = main.surface_world.call(snapshot_method)
		var mountain_before_hit: Dictionary = main.surface_world.surface_resource_mountain_snapshot(mountain_id)
		main.surface_world._mine_surface_resource_mountain_once(mountain_id)
		var mountain_after_hit: Dictionary = main.surface_world.surface_resource_mountain_snapshot(mountain_id)
		var vein_after_mountain: Dictionary = main.surface_world.call(snapshot_method)
		assert (int(mountain_after_hit.hp) < int(mountain_before_hit.hp), "%s hit must damage only its mountain" % mountain_id)
		assert (int(mountain_after_hit.hit_count) == int(mountain_before_hit.hit_count) + 1, "%s hit must own its reaction count" % mountain_id)
		assert (int(mountain_after_hit.impact_count) > int(mountain_before_hit.impact_count), "%s hit must spawn its authored material reaction" % mountain_id)
		assert (Array(vein_after_mountain.nodes) == Array(vein_before_mountain.nodes), "%s mountain hit must not alter vein nodes" % mountain_id)
		assert (String(vein_after_mountain.status) == String(vein_before_mountain.status), "%s mountain hit must not alter vein status" % mountain_id)

		main.surface_world._update_surface_resource_mountains(0.2)
		var normalized: Dictionary = main.surface_world.surface_resource_mountain_snapshot(mountain_id)
		var rendered_size= Vector2(normalized.texture_size) * Vector2(normalized.sprite_scale).abs()
		var local_bottom_center= Vector2(normalized.sprite_position) + Vector2(rendered_size.x * 0.5, rendered_size.y)
		assert (Vector2(normalized.display_size).is_equal_approx(Vector2(mountain_before_hit.display_size)), "%s damage frames must retain the authored display size" % mountain_id)
		assert (rendered_size.is_equal_approx(Vector2(normalized.display_size)), "%s damage texture must normalize to the authored frame" % mountain_id)
		assert (local_bottom_center.length() <= 0.01, "%s damage frame must retain its bottom-center anchor" % mountain_id)
		assert (Vector2(normalized.position).is_equal_approx(Vector2(normalized.base_position)), "%s must settle back onto its fixed world anchor" % mountain_id)
		assert (is_equal_approx(float(normalized.rotation), 0.0))
		assert (bool(normalized.fixed_bottom_center_anchor) and bool(normalized.independent_from_vein))
	main.surface_world.reset_for_new_run()


func _run_smoke_test() -> void :
	RunState.reset_run(false)
	var drop_presentation: Dictionary = main.DropVisualsScript.debug_snapshot()
	assert (String(drop_presentation.presentation) == "sprite_only")
	assert (float(drop_presentation.normal_visible_extent) >= 80.0)
	assert (float(drop_presentation.rare_visible_extent) >= 92.0)
	main.movement_pad._begin(41, Vector2(90, 280))
	main.movement_pad._update_knob(Vector2(122, 280))
	assert (main.button_move.is_equal_approx(Vector2.RIGHT))
	assert (main.mine_world.player.external_movement.is_equal_approx(Vector2.RIGHT))
	main.movement_pad._end()
	assert (main.button_move.is_zero_approx())
	assert (int(GameData.manifest.parity_counts.assets) == 263)
	assert (int(GameData.data.BIOMES.size()) == 4)
	assert (int(GameData.data.MINE_DEFINITIONS.size()) == 4)
	main._assert_depth_one_bedrock_contract()
	assert (Vector2(float(GameData.world().width), float(GameData.world().height)) == Vector2(4480, 1280))
	assert (main.surface_world.entrance_position == Vector2(930, 900))
	assert (main.surface_world.player.global_position == Vector2(240, 680))
	assert (main.surface_world._surface_collides(Vector2(1110, 650)))
	assert (main.surface_world._surface_collides(Vector2(600, 500)), "The ore mountain must be a physical surface landmark")
	main.surface_world.restore_position(Vector2(600, 650))
	assert (main.surface_context == "ore_mountain")
	assert (main.mine_button.visible)
	main.surface_world.reset_for_new_run()
	main.surface_world.restore_position(Vector2(600, 650))
	RunState.pickaxe_level = 4
	var surface_copper_before= int(RunState.cargo.copper)
	var surface_mountain_hp_before= int(main.surface_world.ore_mountain_hp)
	main.surface_world._mine_ore_mountain_once()
	assert (int(RunState.cargo.copper) == surface_copper_before, "Surface ore should exist visibly before pickup")
	assert (main.surface_world.ore_drops.size() == 1)
	assert (int(main.surface_world.ore_mountain_hp) < surface_mountain_hp_before)
	main.surface_world._update_ore_drops(0.7)
	assert (int(RunState.cargo.copper) == surface_copper_before, "Surface ore must wait on the ground until the player collects it")
	var landed_surface_drop: Sprite2D = main.surface_world.ore_drops[0].sprite
	main.surface_world.player.global_position = landed_surface_drop.global_position
	main.surface_world._update_ore_drops(0.01)
	main.surface_world._update_ore_drops(0.2)
	assert (int(RunState.cargo.copper) == surface_copper_before + 1)
	main.surface_world.restore_position(Vector2(600, 650))
	for drop in main.surface_world.ore_drops:
		var leftover_drop: Sprite2D = drop.sprite
		if is_instance_valid(leftover_drop):
			leftover_drop.queue_free()
	main.surface_world.ore_drops.clear()
	main.surface_world.reset_for_new_run()
	main.surface_world.restore_position(Vector2(600, 650))
	RunState.pickaxe_level = 4
	for _hit in range(18):
		main.surface_world._mine_ore_mountain_once()
	assert (bool(main.surface_world.ore_mountain_snapshot().depleted))
	assert (main.surface_world.ore_drops.size() == 25, "A full ridge should release 24 copper and one full-growth gold bonus regardless of tool speed")
	var clean_gold_drop: Sprite2D
	for raw_drop in main.surface_world.ore_drops:
		if String(Dictionary(raw_drop).kind) == "gold":
			clean_gold_drop = Dictionary(raw_drop).sprite as Sprite2D
			break
	assert (clean_gold_drop != null and clean_gold_drop.get_child_count() == 0, "Loose gold must render as the resource sprite without a glow circle")
	assert (clean_gold_drop.texture.resource_path == "res://assets/drops/gold-drop-clean-v2.png")
	var embedded_mountain_save_position= Vector2(600, 500)
	assert (main.surface_world._surface_collides(embedded_mountain_save_position), "Copper Ridge collision must never shrink around a future regrowth area")
	main.surface_world.restore_position(embedded_mountain_save_position)
	assert ( not main.surface_world._surface_collides(main.surface_world.player.global_position), "Legacy saves inside Copper Ridge must migrate to a nearby safe position")
	var depleted_drop_count: int = main.surface_world.ore_drops.size()
	main.surface_world._mine_ore_mountain_once()
	assert (main.surface_world.ore_drops.size() == depleted_drop_count, "A bare ridge stays mineable but cannot release ore that has not regrown")
	main.surface_world._apply_ore_mountain_regrowth(75.0)
	assert (abs(int(main.surface_world.ore_mountain_snapshot().hp) - 180) <= 1, "The ridge should regrow continuously instead of popping back after a cooldown")
	assert ( not bool(main.surface_world.ore_mountain_snapshot().gold_ready), "Gold only returns after a complete regrowth cycle")
	main.surface_world._apply_ore_mountain_regrowth(75.0)
	assert (int(main.surface_world.ore_mountain_snapshot().hp) == int(main.surface_world.ore_mountain_snapshot().max_hp))
	assert (bool(main.surface_world.ore_mountain_snapshot().gold_ready))
	main.surface_world.ore_mountain_hp = 90
	main.surface_world.ore_mountain_growth_buffer = 0.5
	main.surface_world.ore_mountain_gold_ready = false
	main.surface_world.persist_ore_mountain_state()
	var living_mountain_save: Dictionary = RunState.serialize()
	RunState.reset_run(false)
	assert (RunState.deserialize(living_mountain_save))
	assert (is_equal_approx(float(RunState.surface_ore_reserve), 90.5 / 360.0))
	assert (int(RunState.surface_ore_ground_loot.copper) == 24 and int(RunState.surface_ore_ground_loot.gold) == 1, "Uncollected quarry loot must survive Continue")
	main.surface_world.restore_ore_mountain_state()
	assert (abs(int(main.surface_world.ore_mountain_snapshot().hp) - 90) <= 2)
	assert (main.surface_world.ore_drops.size() == 25)
	main.surface_world.reset_for_new_run()
	main.surface_world.restore_position(Vector2(240, 680))
	RunState.reset_run(false)
	RunState.pickaxe_level = 3
	RunState.gold = 120
	main._try_unlock_gate("moonglass")
	assert (RunState.gold == 0)
	assert (RunState.area_unlocked)
	assert (main.surface_world._surface_collides(Vector2(1110, 650)))
	main.surface_world._process(2.5)
	assert ( not main.surface_world._surface_collides(Vector2(1110, 650)))
	_run_surface_mountain_independence_smoke()
	RunState.reset_run(false)
	main.mine_world.load_mine("mossMine")
	var snapshot: Dictionary = main.mine_world.smoke_snapshot()
	assert (Vector2(snapshot.world_size) == Vector2(1920, 5120))
	assert (Vector2(main.mine_world.depth_entrance) == Vector2(1752, 2808))
	var shaft_center_cell: Vector2i = main.mine_world._world_to_cell(Vector2(main.mine_world.depth_entrance))
	assert (main.mine_world.depth_entrance_cells.has(shaft_center_cell.y * main.mine_world.cols + shaft_center_cell.x))
	assert ( not main.mine_world._player_collides(Vector2(main.mine_world.depth_entrance) + Vector2(92, 0)), "Depth 1 return pad must be clear before the player ascends")
	assert (int(snapshot.blocks) > 3500)
	assert (int(Dictionary(snapshot.outer_barrier).requires_tool) == 1)
	assert (int(Dictionary(snapshot.iron_barrier).requires_tool) == 2)
	assert (int(snapshot.outer_barrier_rocks) == 3)
	assert (int(snapshot.iron_barrier_rocks) == 3)
	assert (main.mine_world._player_collides(Vector2(658, 505)))
	assert (main.mine_world._player_collides(Vector2(658, 775)))
	assert (main.mine_world._player_collides(Vector2(1263, 505)))
	assert (main.mine_world._player_collides(Vector2(1263, 775)))
	for row in range(3, 10):
		assert (main.mine_world.blocks.has(Vector2i(12, row)))
	for row in range(17, 24):
		assert (main.mine_world.blocks.has(Vector2i(12, row)))
	for row in range(3, 10):
		assert (main.mine_world.blocks.has(Vector2i(25, row)))
	for row in range(17, 24):
		assert (main.mine_world.blocks.has(Vector2i(25, row)))
	main._enter_mossvein()
	assert (main.phase == "mine")
	assert (main.mine_world.player.global_position == Vector2(230, 640))
	assert (main.mine_world.player.camera.is_current())
	assert ( not main.surface_world.player.camera.enabled)
	var diagonal_aim_cases= [
		{"cardinal": Vector2.RIGHT, "diagonal": Vector2(1, 1), "name": "right"},
		{"cardinal": Vector2.LEFT, "diagonal": Vector2(-1, -1), "name": "left"},
		{"cardinal": Vector2.UP, "diagonal": Vector2(1, -1), "name": "up"},
		{"cardinal": Vector2.DOWN, "diagonal": Vector2(-1, 1), "name": "down"},
	]
	for aim_case in diagonal_aim_cases:
		main.mine_world.player.set_facing(Vector2(aim_case.cardinal))
		main.mine_world.player.set_facing(Vector2(aim_case.diagonal))
		assert (main.mine_world.player.direction_name == String(aim_case.name))
		assert (main.mine_world.player.facing_vector == Vector2(aim_case.cardinal), "Diagonal intent must target where the pickaxe is visibly facing")
	var grounding: Dictionary = main.mine_world.player.visual.grounding_snapshot()
	for anchor_value in grounding.values():
		assert (is_equal_approx(float(anchor_value), float(grounding.walk)))
	var animation_target= Vector2i(6, 13)
	var previous_animation_block: Variant = main.mine_world.blocks.get(animation_target)
	main.mine_world.blocks[animation_target] = main.mine_world._make_block("stone", 100, 0, "terrain")
	main.mine_world.current_target = animation_target
	main.mine_world.set_mine_held(true)
	main.mine_world.swing_active = false
	main.mine_world._update_mining(0.0)
	assert (main.mine_world.swing_active and main.mine_world.player.mining_visual_active)
	main.mine_world.swing_hit = true
	main.mine_world.swing_elapsed = main.mine_world.swing_duration
	main.mine_world._update_mining(0.0)
	assert (main.mine_world.swing_active and main.mine_world.player.mining_visual_active, "Held mining must not flash back to the walk asset between swings")
	main.mine_world.set_mine_held(false)
	main.mine_world.swing_active = false
	main.mine_world._update_mining(0.0)
	assert ( not main.mine_world.player.mining_visual_active)
	if previous_animation_block == null:
		main.mine_world.blocks.erase(animation_target)
	else:
		main.mine_world.blocks[animation_target] = previous_animation_block
	for target_row in range(10, 15):
		for target_col in range(7, 13):
			main.mine_world.blocks.erase(Vector2i(target_col, target_row))
	var bedrock_cell= Vector2i(9, 12)
	var blocked_cell= Vector2i(10, 12)
	main.mine_world.blocks[bedrock_cell] = main.mine_world._make_block("bedrock", 1, 99, "bedrock")
	main.mine_world.blocks[blocked_cell] = main.mine_world._make_block("stone", 8, 0, "terrain")
	main.mine_world.player.global_position = Vector2(400, 600)
	main.mine_world.player.set_facing(Vector2.RIGHT)
	assert (main.mine_world._find_mine_target() == Vector2i(-1, -1), "Bedrock must not be targetable or allow mining through it")
	main.mine_world.blocks[bedrock_cell] = main.mine_world._make_block("stone", 8, 0, "terrain")
	assert (main.mine_world._find_mine_target() == bedrock_cell, "A mineable rock in the same position must remain targetable")
	for target_row in range(10, 15):
		for target_col in range(7, 13):
			main.mine_world.blocks.erase(Vector2i(target_col, target_row))
	var corner_front_cell= Vector2i(9, 13)
	var corner_back_cell= Vector2i(9, 14)
	main.mine_world.blocks[corner_front_cell] = main.mine_world._make_block("stone", 8, 0, "terrain")
	main.mine_world.blocks[corner_back_cell] = main.mine_world._make_block("stone", 8, 0, "terrain")
	main.mine_world.player.global_position = Vector2(432, 602)
	main.mine_world.player.set_facing(Vector2.DOWN)
	assert (main.mine_world._find_mine_target() == corner_front_cell, "Mining at a tight corner must target the adjacent block before the block behind it")
	for target_row in range(10, 15):
		for target_col in range(7, 13):
			main.mine_world.blocks.erase(Vector2i(target_col, target_row))
	var lower_left_front_cell= Vector2i(8, 13)
	var lower_left_back_cell= Vector2i(8, 14)
	main.mine_world.blocks[lower_left_front_cell] = main.mine_world._make_block("stone", 8, 0, "terrain")
	main.mine_world.blocks[lower_left_back_cell] = main.mine_world._make_block("stone", 8, 0, "terrain")
	main.mine_world.player.global_position = Vector2(456, 602)
	main.mine_world.player.set_facing(Vector2.DOWN)
	assert (main.mine_world._find_mine_target() == lower_left_front_cell, "Downward mining at a lower-left corner must select the rock beside the player's feet")
	main.mine_world.load_mine("mossMine")
	main.mine_world.player.global_position = (Vector2(Vector2i(24, 12)) + Vector2(0.5, 0.5)) * 48.0
	main.mine_world.player.set_facing(Vector2.RIGHT)
	main.mine_world.current_target = main.mine_world._find_mine_target()
	assert (main.mine_world.current_target == Vector2i(26, 12), "Expected authored barrier rock (26, 12), got %s" % main.mine_world.current_target)
	var locked_hp= int(Dictionary(main.mine_world.blocks[main.mine_world.current_target]).hp)
	main.mine_world._mine_once()
	assert (int(Dictionary(main.mine_world.blocks[main.mine_world.current_target]).hp) == locked_hp)
	RunState.gold = 30
	assert (RunState.upgrade_pickaxe())
	assert (RunState.pickaxe_level == 2)
	main.mine_world._mine_once()
	assert (int(Dictionary(main.mine_world.blocks[main.mine_world.current_target]).hp) == locked_hp - 7)
	for barrier_row in [12, 13, 14]:
		var barrier_cell= Vector2i(26, barrier_row)
		var barrier_rock: Dictionary = Dictionary(main.mine_world.blocks[barrier_cell])
		barrier_rock.hp = 1
		main.mine_world.blocks[barrier_cell] = barrier_rock
		main.mine_world.current_target = barrier_cell
		main.mine_world._mine_once()
	assert (RunState.is_mine_barrier_cleared("iron_seam"))
	assert (int(main.mine_world.role_block_counts.iron_seam) == 0)
	assert ( not main.mine_world._player_collides(Vector2(1263, 640)))
	RunState.reset_run(false)
	for legacy_row in [12, 13, 14]:
		RunState.mark_terrain_dug("mossMine", legacy_row * 40 + 26, 1)
	main.mine_world.load_mine("mossMine")
	assert (RunState.is_mine_barrier_cleared("iron_seam"))
	assert (int(main.mine_world.role_block_counts.iron_seam) == 0)
	RunState.reset_run(false)
	main.mine_world.load_mine("mossMine")
	main.mine_world._on_player_moved(Vector2(230, 640))
	assert (main.phase == "mine")
	assert (main.mine_exit_context)
	main._perform_context()
	assert (main.phase == "surface")
	assert (main.surface_world.player.camera.is_current())
	assert ( not main.mine_world.player.camera.enabled)
	var surface_mine_return: Vector2 = Vector2(main.surface_world.player.global_position)
	assert ( not main.surface_world._surface_collides(surface_mine_return), "Leaving Mossvein Mine must never return the player inside the locked portal boundary")
	assert (main.surface_world._resolve_motion(surface_mine_return, Vector2.LEFT * 8.0).x < surface_mine_return.x, "The player must be able to move immediately after leaving Mossvein Mine")
	main.mine_world.load_mine("mossMine")
	var terrain_no_respawn_cell= Vector2i(6, 7)
	var terrain_no_respawn_index: int = (
		terrain_no_respawn_cell.y * int(main.mine_world.cols) + terrain_no_respawn_cell.x
	)
	main.mine_world.blocks[terrain_no_respawn_cell] = main.mine_world._make_block("stone", 1, 0, "terrain")
	main.mine_world.respawns.clear()
	main.mine_world.current_target = terrain_no_respawn_cell
	main.mine_world._mine_once()
	assert (not main.mine_world.blocks.has(terrain_no_respawn_cell))
	assert (main.mine_world.respawns.is_empty(), "Ordinary mined terrain must never enter the respawn queue")
	assert (
		main.mine_world.mineable_edge_void_cells.has(terrain_no_respawn_cell),
		"Newly mined terrain must expose the mineable rim immediately"
	)
	assert (
		RunState.dug_cells("mossMine", 1).has(terrain_no_respawn_index),
		"Ordinary mined terrain must persist as player-dug space"
	)
	main.mine_world._configure_mine("mossMine")
	assert (
		not main.mine_world.blocks.has(terrain_no_respawn_cell),
		"Ordinary terrain must stay dug after the mine is rebuilt"
	)
	assert (
		main.mine_world.mineable_edge_void_cells.has(terrain_no_respawn_cell),
		"Persisted player-dug terrain must restore its mineable rim provenance"
	)
	var respawn_cell= Vector2i(5, 7)
	var resource_block: Dictionary = Dictionary(main.mine_world.blocks[respawn_cell])
	assert (String(resource_block.role) == "resource")
	resource_block.hp = 1
	main.mine_world.blocks[respawn_cell] = resource_block
	main.mine_world.current_target = respawn_cell
	main.mine_world._mine_once()
	assert ( not main.mine_world.blocks.has(respawn_cell) and main.mine_world.respawns.size() == 1)
	assert (
		not main.mine_world.mineable_edge_void_cells.has(respawn_cell),
		"A temporarily depleted resource node must not expose a terrain rim"
	)
	var expired_respawn: Dictionary = Dictionary(main.mine_world.respawns[0])
	expired_respawn.respawn_until_unix = Time.get_unix_time_from_system() - 1.0
	main.mine_world.respawns[0] = expired_respawn
	var respawn_scope: Dictionary = Dictionary(RunState.mine_resource_runtime["mossMine:1"])
	var respawn_depleted: Dictionary = Dictionary(respawn_scope.depleted)
	var respawn_node_id: String = String(main.mine_world._resource_node_id(respawn_cell))
	var respawn_record: Dictionary = Dictionary(respawn_depleted[respawn_node_id])
	respawn_record.respawn_until_unix = int(Time.get_unix_time_from_system()) - 1
	respawn_depleted[respawn_node_id] = respawn_record
	respawn_scope.depleted = respawn_depleted
	RunState.mine_resource_runtime["mossMine:1"] = respawn_scope
	main.mine_world._update_respawns(0.0)
	assert (main.mine_world.blocks.has(respawn_cell))
	assert (not main.mine_world.mineable_edge_void_cells.has(respawn_cell))
	main.mine_world.load_mine("moonMine")
	var moon_snapshot: Dictionary = main.mine_world.smoke_snapshot()
	assert (String(moon_snapshot.mine_id) == "moonMine")
	assert (Vector2(moon_snapshot.world_size) == Vector2(1680, 5760))



	assert (int(moon_snapshot.blocks) > 3500)
	main.mine_world.load_mine("mossMine")
	RunState.reset_run(false)
	main._enter_mine("mossMine", true, false)
	assert ( not main.mine_world.depth_entrance_boundary.is_empty())
	var shaft_boundary_index= int(main.mine_world.depth_entrance_boundary.keys()[0])
	var shaft_boundary_cell= Vector2i(shaft_boundary_index % main.mine_world.cols, floori(float(shaft_boundary_index) / float(main.mine_world.cols)))
	assert (main.mine_world.blocks.has(shaft_boundary_cell))
	var shaft_boundary_block: Dictionary = Dictionary(main.mine_world.blocks[shaft_boundary_cell])
	shaft_boundary_block.hp = 1
	main.mine_world.blocks[shaft_boundary_cell] = shaft_boundary_block
	main.mine_world.current_target = shaft_boundary_cell
	main.mine_world._mine_once()
	assert (RunState.is_depth_entrance_discovered("mossMine"))
	main.mine_world.restore_position(Vector2(main.mine_world.depth_entrance) + Vector2(92, 0))
	assert (main.mine_depth_context)
	main._perform_context()
	assert (main.phase == "depth" and RunState.is_depth_visited("mossMine"))
	assert (Vector2(main.depth_world.depth_entrance) == Vector2(1752, 2808))
	var station_contract: Dictionary = main.depth_world.contract_snapshot()
	var station_assets: Dictionary = Dictionary(station_contract.asset_contract)
	assert (String(station_assets.sell) == "res://assets/stations/ore-exchange-v1.png")
	assert (String(station_assets.forge) == "res://assets/stations/drill-forge-workshop-v1.png")
	var sell_position: Vector2 = Vector2(float(main.depth_world.station_positions.sell.x), float(main.depth_world.station_positions.sell.y))
	var forge_position: Vector2 = Vector2(float(main.depth_world.station_positions.forge.x), float(main.depth_world.station_positions.forge.y))
	assert (sell_position.distance_to(forge_position) >= 330.0, "Large stations need a player-wide central aisle")
	assert ( not main.depth_world.collision_at((sell_position + forge_position) * 0.5), "Player must fit between exchange and forge")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	var crusher_tool: Dictionary = main.mine_world._current_tool()
	assert (float(crusher_tool.cooldown) > float(RunState.current_pickaxe().cooldown) * 2.0)
	assert (is_equal_approx(main.mine_world._tool_strike_progress(), 0.66))
	var crusher_test_center= Vector2i(20, 20)
	var crusher_previous_blocks: Dictionary = {}
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var crusher_cell= crusher_test_center + Vector2i(x_offset, y_offset)
			crusher_previous_blocks[crusher_cell] = main.mine_world.blocks.get(crusher_cell)
			main.mine_world.blocks[crusher_cell] = main.mine_world._make_block("stone", 999, 0, "terrain")
	main.mine_world._apply_crusher_shockwave(crusher_test_center, crusher_tool)
	var crusher_previous_impacts: Array[Dictionary] = main.mine_world.impacts.duplicate(true)
	var crusher_previous_drop_count: int = main.mine_world.drops.size()
	var crusher_force_impact= {
		"position": main.mine_world._cell_center(crusher_test_center),
		"age": 0.0,
		"life": 0.3,
		"broken": true,
		"style": "crusher",
	}
	main.mine_world._attach_crusher_debris(crusher_force_impact, crusher_test_center)
	assert (bool(crusher_force_impact.get("crusher_force", false)), "Broken Crusher hits need a short dust-and-crack force cue")
	assert ( not crusher_force_impact.has("crusher_chunks"), "Crusher visuals must use the real resource drops, not decorative rock chunks")
	main.mine_world.impacts.clear()
	main.mine_world.impacts.append(crusher_force_impact)
	main.mine_world._update_impacts(0.31)
	assert (main.mine_world.impacts.is_empty(), "Crusher force dust must clean itself up quickly")
	assert (main.mine_world.drops.size() == crusher_previous_drop_count, "The dust cue must never create loot")
	main.mine_world.impacts.assign(crusher_previous_impacts)
	var shocked_cells= 0
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var crusher_cell= crusher_test_center + Vector2i(x_offset, y_offset)
			if crusher_cell != crusher_test_center and int(Dictionary(main.mine_world.blocks[crusher_cell]).hp) < 999:
				shocked_cells += 1
	assert (shocked_cells == 24, "Astral Crusher must hit the full 5x5 footprint")
	for crusher_cell_value in crusher_previous_blocks:
		var crusher_cell: Vector2i = Vector2i(crusher_cell_value)
		var previous_crusher_block: Variant = crusher_previous_blocks[crusher_cell]
		if previous_crusher_block == null:
			main.mine_world.blocks.erase(crusher_cell)
		else:
			main.mine_world.blocks[crusher_cell] = previous_crusher_block
	RunState.set_starforge_variant("swift")
	assert (is_equal_approx(main.mine_world._tool_strike_progress(), 0.28))
	assert (float(main.mine_world._current_tool().cooldown) < float(RunState.current_pickaxe().cooldown))
	RunState.set_starforge_variant("prospector")
	assert (int(main.mine_world._current_tool().yield_multiplier) == 2, "Crownseeker must always double mined resources")
	RunState.set_starforge_variant("crusher")
	RunState.cargo.rootiron = 50
	RunState.cargo.ambercore = 5
	RunState.gold = 5000
	var drill_forge: Dictionary = Dictionary(main.depth_world.station_positions.forge)
	main.depth_world.restore_position(Vector2(float(drill_forge.x), float(drill_forge.y)))
	assert (main.depth_context == "drillForge")
	main._perform_context()
	assert (RunState.drill_level == 1)
	main.depth_world.restore_position(Vector2(main.depth_world.depth_entrance))
	assert (main.depth_context == "depthExit")
	main._perform_context()
	assert (main.phase == "mine")
	var depth_return_position= Vector2(main.mine_world.depth_entrance) + Vector2(92, 0)
	assert (main.mine_world.player.global_position == depth_return_position)
	assert ( not main.mine_world._player_collides(main.mine_world.player.global_position), "Ascending from Depth 2 must never return the player inside rock")
	assert (main.mine_world._resolve_motion(main.mine_world.player.global_position, Vector2(-8, 0)).x < main.mine_world.player.global_position.x, "The player must be able to move immediately after ascending")


	RunState.reset_run(false)
	main.phase = "surface"
	main.current_mine_id = "mossMine"
	main._apply_global_movement_speed()
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.surface_world.reset_for_new_run()
	main.surface_world.set_active(true)
	var moss_ironbound_position: Vector2 = main.surface_world.surface_chest_position("moss_ironbound")
	assert (moss_ironbound_position == Vector2(700, 720))
	assert ( not main.surface_world._surface_collides(moss_ironbound_position))
	assert (main.surface_world._surface_collides(Vector2(300, 940)))
	main.surface_world.restore_position(moss_ironbound_position)
	assert (main.surface_context == "chest:moss_ironbound")
	assert (main.action_button.text == "LOCKED" and main.action_button.disabled, "A tier-locked cache must explain itself without opening")
	RunState.gold = 150
	main.surface_world.restore_position(main.surface_world._station_position("speedShop"))
	assert (main.surface_context == "speedShop")
	main._refresh_context_button()
	assert (main.action_button.text == "BROWSE" and not main.action_button.disabled)
	main._perform_context()
	assert (main.commerce_panel.is_open() and main.commerce_context == "wayfarer")
	main._on_commerce_action_confirmed("wayfarer:speed")
	main.station_transaction_fx.complete_immediately()
	assert (RunState.movement_speed_level == 1 and RunState.gold == 0)
	var upgraded_speed= float(GameData.data.PLAYER_SPEED) * 1.07
	for upgraded_player in [main.surface_world.player, main.mine_world.player, main.depth_world.player, main.hub_world.player]:
		assert (is_equal_approx(upgraded_player.movement_speed, upgraded_speed), "Wayfarer speed must update every world immediately")
	RunState.reset_run(false)
	main._apply_global_movement_speed()
	main.surface_world.reset_for_new_run()
	var moss_supply_position: Vector2 = main.surface_world.surface_chest_position("moss_supply")
	assert (moss_supply_position == Vector2(750, 640))
	assert ( not main.surface_world._surface_collides(moss_supply_position))
	assert (main.surface_world._surface_collides(Vector2(930, 350)))
	main.surface_world.restore_position(moss_supply_position)
	assert (main.surface_world.player.global_position == moss_supply_position)
	assert (main.surface_context == "chest:moss_supply" and main.action_button.text == "OPEN" and not main.action_button.disabled)
	main._perform_context()
	assert (RunState.is_surface_chest_opened("moss_supply") and RunState.gold == 0)
	assert ( not RunState.is_surface_chest_opened("moss_ironbound"))
	assert (RunState.pending_chest_reward_loot("moss_supply") == {"coin": 25})
	assert (main.surface_world.chest_loot_drops.size() == 3, "Starter cache must spray three physical coin pieces")
	for chest_drop in main.surface_world.chest_loot_drops:
		assert ((Dictionary(chest_drop).sprite as Sprite2D).get_child_count() == 0, "Chest gold must use the resource sprite without a glow circle")
	for starter_drop in main.surface_world.chest_loot_drops:
		var starter_sprite: Sprite2D = Dictionary(starter_drop).sprite as Sprite2D
		starter_sprite.queue_free()
	main.surface_world.chest_loot_drops.clear()
	RunState.pending_chest_loot.clear()
	RunState.pickaxe_level = 3
	var moon_cache: Dictionary = main._surface_chest_definition("moon_cache")
	var moon_plan: Dictionary = RunState.open_surface_chest("moon_cache")
	assert (bool(moon_plan.ok))
	main.surface_world._sync_pending_chest_loot_drops()
	assert ( not main.surface_world.chest_loot_drops.is_empty())
	var moon_drop: Dictionary = main.surface_world.chest_loot_drops[0]
	var moon_drop_sprite: Sprite2D = moon_drop.sprite as Sprite2D
	moon_drop.age = main.surface_world.ORE_DROP_FLIGHT_DURATION
	moon_drop.settled = true
	moon_drop_sprite.position = Vector2(moon_drop.landing_position)
	main.surface_world.chest_loot_drops[0] = moon_drop
	main.surface_world.player.global_position = moon_drop_sprite.global_position + Vector2(main.surface_world.CHEST_DROP_PICKUP_RADIUS - 8.0, 0.0)
	main.surface_world._update_chest_loot_drops(0.01)
	assert (bool(Dictionary(main.surface_world.chest_loot_drops[0]).collecting), "Moonglass chest gold must magnetize from the nearby path")
	main.surface_world._update_chest_loot_drops(main.surface_world.ORE_DROP_COLLECT_DURATION + 0.01)
	assert (RunState.gold > 0, "Moonglass chest gold must enter the wallet")
	RunState.cargo.stone = 5
	main.surface_world.restore_position(Vector2(335, 390))
	assert (main.surface_context == "storage:storage-1" and main.action_button.text == "USE")
	main._perform_context()
	assert (int(Dictionary(RunState.base_module_by_id("storage-1").items).stone) == 5, "Starter storage must be functional on Surface")


	RunState.reset_run(false)
	main.surface_world.reset_for_new_run()
	RunState.add_resource("stone", 3)
	RunState.add_resource("copper", 2)
	main.surface_world.restore_position(main.surface_world.station_interaction_position("sell"))
	assert (main.surface_context == "sell" and main.action_button.text == "SELL ORE")
	assert ( not main.context_card.visible and main.premium_hud.context_button.visible and main.premium_hud.context_button.text == "SELL")
	assert (main.premium_hud.context_button.tooltip_text.contains("ASSAY STATION"))
	var expected_sale= 3 * int(GameData.data.ROCK_TYPES.stone.value) + 2 * int(GameData.data.ROCK_TYPES.copper.value)
	main._perform_context()
	assert (main.station_transaction_fx.busy and String(main.commerce_transaction.get("kind", "")) == "assay")
	main.station_transaction_fx.complete_immediately()
	assert (RunState.gold == expected_sale and int(RunState.cargo.stone) == 0 and int(RunState.cargo.copper) == 0, "Assay must sell ore through the shared context action")
	RunState.gold = int(RunState.next_pickaxe().cost)
	main.surface_world.restore_position(main.surface_world.station_interaction_position("forge"))
	assert (main.surface_context == "forge" and main.action_button.text == "FORGE")
	assert ( not main.context_card.visible and main.premium_hud.context_button.visible and main.premium_hud.context_button.text == "FORGE")
	assert (main.premium_hud.context_button.tooltip_text.contains("MOSSVEIN FORGE"))
	main._perform_context()
	assert (main.commerce_panel.is_open() and main.commerce_context == "forge")
	main._on_commerce_action_confirmed("forge:pickaxe")
	main.station_transaction_fx.complete_immediately()
	assert (RunState.pickaxe_level == 2, "Forge must buy the next pickaxe through the shared context action")
	main.surface_world.restore_position(main.surface_world._mine_entrance("mossMine"))
	assert (main.surface_context == "enter:mossMine" and main.action_button.text == "DESCEND" and main.action_button.visible)
	assert ( not main.context_card.visible and main.premium_hud.context_button.visible and main.premium_hud.context_button.text == "DESCEND")
	assert (InputMap.has_action("interact") and not InputMap.action_get_events("interact").is_empty(), "Keyboard interaction must remain bound for E/F")
	print("EVER_DEEPER_MOSS_ROOTWOUND_LOOP_OK source=", GameData.source_label(), " moss_blocks=", snapshot.blocks, " moon_blocks=", moon_snapshot.blocks, " portal=1752,2808 depth=Rootwound drill=Burrower persistence=true explicit_transitions=true")
	main.get_tree().quit(0)

