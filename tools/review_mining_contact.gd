extends SceneTree
## Verify damage and the impact sprite survive an actual presented frame.
var output: String
var main: Node
var results: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
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
	main._dev_jump_endless(1)
	var world: Node = main.endless_world
	var player: Node = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	player.prepare_visual_cache()
	while player.visual.active_gear != "worn": await process_frame
	_freeze(world)
	var visual: Node = player.visual
	var origin: Vector2 = player.position
	var center: Vector2i = world._world_to_cell(origin)
	for y in range(-2, 3):
		for x in range(-2, 3): world.floor_cells[world._cell_index(center + Vector2i(x, y))] = 1
	for index in world.resources.size():
		world.resources[index].mined = index >= 2
		if index < 2:
			world.resources[index].position = origin + (Vector2(40, 0) if index == 0 else Vector2(0, 40))
			world.resources[index].hp = 1
	player.set_facing(Vector2.RIGHT)
	player._actual_moving = false
	world.external_mine_held = true
	world._update_mining(world._mining_cycle_duration() * 1.1)
	assert(bool(world.resources[0].mined))
	assert(player.direction_name == "down", "Fixture must automatically aim the next stone elsewhere")
	await _contact(visual, "deep_overshoot_retarget", "right")
	# A deliberate input turn still owns facing immediately.
	player.set_mining_visual(true, .9, 1.0, world.MINING_HIT_PROGRESS)
	player._update_aim(Vector2.UP, true)
	player._update_visual(false)
	visual._draw_frame(0.0)
	assert(not visual._impact_pending and visual._last_direction == "up")
	results.append({"id":"explicit_turn", "passed":true})
	# Native contact remains one presented frame even if gameplay stops mining.
	player.set_facing(Vector2.RIGHT)
	player.set_mining_visual(true, .95, 1.0, world.MINING_HIT_PROGRESS)
	player.set_mining_visual(false)
	await _contact(visual, "completion_cancels_cycle", "right")
	visual.release_visual_cache()
	assert(not visual._impact_pending)
	await _deepheart_contacts(state)
	FileAccess.open(output.path_join("mining-contact.json"), FileAccess.WRITE).store_string(JSON.stringify({"rendered":true,"physical_iphone":false,"checks":results}, "\t"))
	quit()

func _deepheart_contacts(state: Node) -> void:
	# The Deep fixture seeded victory; Deepheart is deliberately gated after it.
	state.reset_run(false)
	assert(main._dev_jump_deepheart())
	var world: Node = main.deepheart_world
	var player: Node = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	player.prepare_visual_cache()
	while player.visual.active_gear != "worn": await process_frame
	_freeze(world)
	player.camera.position_smoothing_enabled = false
	main.achievement_toast.clear()
	main.achievement_toast.hide()
	for seal_id in world.SEAL_ORDER:
		await _approach_seal(world, String(seal_id))
	await _approach_seal(world, "mossvein", false)
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	player._actual_moving = false
	world.external_mine_held = true
	var duration: float = world._seal_mining_duration(world._current_tool())
	world._update_mining(duration * .4)
	assert(world.seal_state.mossvein.hits == 1 and not world.seal_state.mossvein.opened)
	await _contact(player.visual, "deepheart_normal_contact", "up")
	world._cancel_mining()
	for id in ["mossvein", "moonglass", "emberdeep"]:
		assert(state.open_deepheart_seal(id))
		world.seal_state[id].opened = true
		world.seal_state[id].hp = 0
	world.seal_state.starfall.hp = 1
	await _approach_seal(world, "starfall", false)
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	world.external_mine_held = true
	world._update_mining(duration * .4)
	assert(world.seal_state.starfall.opened and world._all_seals_open())
	assert(world.mining_active and world.mining_target == "starfall", "Opening must retain the committed follow-through")
	await _contact(player.visual, "deepheart_final_opening_contact", "up")
	world._update_mining(duration * .35)
	assert(world.mining_active and world.mining_target == "starfall")
	world._update_visuals()
	player.visual._draw_frame(0.0)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("deepheart_final_recovery.png"))
	world._update_mining(duration * .3)
	assert(not world.mining_active and not player.visual._impact_pending)
	results.append({"id":"deepheart_complete_final_swing", "passed":true})
	# Walk along the open front lane to the machine's staircase.
	player.position.y = world.WALKABLE_RECT.end.y
	player.set_external_movement(Vector2.RIGHT)
	for tick in 50:
		player._physics_process(1.0 / 60.0)
		if world.active_context == "deepheart_core": break
	player.set_external_movement(Vector2.ZERO)
	player._physics_process(1.0 / 60.0)
	world._update_context(player.global_position)
	assert(not world._fixture_blocks(player.position), "The hero must reach the core from clear decking")
	assert(world.active_context == "deepheart_core")
	assert(world.interact())
	main._open_start_menu()
	main._open_inventory()
	assert(not main.menu_open and not main.inventory_open, "Hidden menu controls must not interrupt the finale")
	var camera_samples: Array[Dictionary] = []
	for frame in 42:
		world._advance_finale(1.0 / 30.0)
		world._update_visuals()
		await RenderingServer.frame_post_draw
		if frame % 10 == 0:
			camera_samples.append({"time":world.finale_elapsed,"center":str(world.finale_camera.get_screen_center_position()),"zoom":str(world.finale_camera.zoom)})
	results.append({"id":"deepheart_camera_sequence", "passed":true,"samples":camera_samples,"fixed_simulation_step":true,"physical_fps_evidence":false})
	world._update_visuals()
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("deepheart_resonance_transfer.png"))
	main._set_orientation_guard_active(true)
	assert(not world.active and main.orientation_guard.visible)
	main._set_orientation_guard_active(false)
	assert(world.active and world.finale_active and main.deepheart_presentation)
	assert(world.finale_camera.enabled and not main.premium_hud.is_visible_in_tree())
	results.append({"id":"deepheart_finale_rotation_resume", "passed":true})
	world._advance_finale(world.FINALE_BUILD_DURATION - 1.4)
	world._update_visuals()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("deepheart_core_reveal.png"))
	assert(main.deepheart_presentation and not main.premium_hud.is_visible_in_tree())
	assert(not main.minimap_overlay.is_visible_in_tree())
	var machine_on_screen: Rect2 = world.core_sprite.get_global_transform_with_canvas() * world.core_sprite.get_rect()
	assert(root.get_visible_rect().encloses(machine_on_screen), "The complete native machine must fit the finale camera")
	results.append({"id":"deepheart_core_reachable", "passed":true})
	world._advance_finale(world.FINALE_REVEAL_HOLD)
	assert(world.finale_committed and main.conclusion_overlay.visible)
	main._set_orientation_guard_active(true)
	main._set_orientation_guard_active(false)
	main._stay_in_deepheart_from_conclusion()
	assert(not main.deepheart_presentation and not world.finale_camera.enabled)
	assert(world.active and world.player.control_enabled and main.premium_hud.is_visible_in_tree())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join("deepheart_resume_play.png"))
	results.append({"id":"deepheart_cinematic_restores_play", "passed":true})
	world.restore_position(Vector2(world.SEAL_POSITIONS.starfall) + Vector2(0, 96))
	assert(not world._fixture_blocks(player.position))
	world.restore_position(Vector2(1800, 820))
	assert(not world._fixture_blocks(player.position))
	results.append({"id":"deepheart_restore_clear_ground", "passed":true})

func _approach_seal(world: Node, seal_id: String, capture: bool = true) -> void:
	var player: Node = world.player
	var seal: Vector2 = world.SEAL_POSITIONS[seal_id]
	player.position = Vector2(seal.x, world.WALKABLE_RECT.end.y)
	world._update_context(player.position)
	player.set_external_movement(Vector2.UP)
	# Exercise the actual player/controller/resolver, including oversize motion.
	for tick in 45:
		player._physics_process(1.0 / 60.0)
		world._update_visuals()
	player.set_external_movement(Vector2.ZERO)
	player._physics_process(1.0 / 60.0)
	assert(not world._fixture_blocks(player.position), "The hero must stand outside the physical base")
	assert(player.position.distance_to(seal) <= world._effective_seal_range(), "The base must not prevent mining")
	assert(world.active_context == "deepheart_seal:" + seal_id, "Wrong approach context %s at %s for %s" % [world.active_context, player.position, seal_id])
	player.camera.reset_smoothing()
	player.camera.force_update_scroll()
	player.visual._draw_frame(0.0)
	if capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("deepheart_approach_"+seal_id+".png"))
		results.append({"id":"deepheart_approach_"+seal_id,"passed":true,"position":str(player.position),"distance":player.position.distance_to(seal)})

func _contact(visual: Node, id: String, direction: String) -> void:
	if id.begins_with("deepheart_"): main.deepheart_world._update_visuals()
	visual._draw_frame(0.0)
	assert(visual._last_state == "mine" and visual._last_local_frame == 26)
	assert(visual._last_direction == direction)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
	await process_frame
	visual._draw_frame(1.0 / 60.0)
	assert(not visual._impact_pending, "A presented contact is consumed")
	results.append({"id":id,"passed":true,"frame":26,"direction":direction})

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)
