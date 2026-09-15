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
	FileAccess.open(output.path_join("mining-contact.json"), FileAccess.WRITE).store_string(JSON.stringify({"rendered":true,"physical_iphone":false,"checks":results}, "\t"))
	quit()

func _contact(visual: Node, id: String, direction: String) -> void:
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
