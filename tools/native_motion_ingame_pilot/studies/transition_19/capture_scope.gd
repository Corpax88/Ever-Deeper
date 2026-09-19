extends SceneTree
## Verify unsupported view/gear/outfit fallback with actual rendered sprites.
var output := ""
var frames := ""
var main: Node
var world: Node
var player: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--frames="): frames = arg.trim_prefix("--frames=")
	assert(output.is_absolute_path() and frames.is_absolute_path())
	assert(DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(output)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld/Player/Visual").set_script(load("res://tools/native_motion_ingame_pilot/studies/transition_19/transition_visual.gd"))
	root.add_child(main)
	current_scene = main
	for i in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	assert(main._dev_jump_endless(1))
	world = main.endless_world
	player = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.endless_workshops["tool_forge"] = {"built":false,"level":0}
	player.prepare_visual_cache()
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	world.restore_position(Vector2(1696,1648))
	player.set_facing(Vector2.UP)
	player.control_enabled = true
	main.quick_tutorial.dismiss()
	player.visual.configure(frames)
	# Keep ordinary feedback; wait for actual asset loading, not a fabricated flag.
	for i in 120:
		await RenderingServer.frame_post_draw
		if player.visual.active_gear == "worn" and i > 15: break
	assert(player.visual.active_gear == "worn")
	assert(is_equal_approx(float(world._mining_cycle_duration()),.68))
	player.visual.study_enabled = true
	var cases := [
		{"name":"worn-up-miner","pick":1,"drill":0,"variant":"","gear":"worn","direction":"up","outfit":"miner","expected":true},
		{"name":"worn-right-miner","pick":1,"drill":0,"variant":"","gear":"worn","direction":"right","outfit":"miner","expected":false},
		{"name":"worn-up-expedition","pick":1,"drill":0,"variant":"","gear":"worn","direction":"up","outfit":"expedition","expected":false},
		{"name":"crusher-up-miner","pick":1,"drill":0,"variant":"crusher","gear":"crusher","direction":"up","outfit":"miner","expected":false},
		{"name":"deepcore-up-miner","pick":1,"drill":3,"variant":"","gear":"deepcore","direction":"up","outfit":"miner","expected":false}]
	var results: Array = []
	for test in cases:
		state.pickaxe_level = test.pick
		state.drill_level = test.drill
		state.starforge_variant = test.variant
		state.endless_outfit = test.outfit
		player.prepare_visual_cache()
		for i in 240:
			await RenderingServer.frame_post_draw
			if player.visual.active_gear == test.gear and i>3: break
		assert(player.visual.active_gear == test.gear)
		player.visual.set_state(test.direction,0,false,true,.30,0.0,.42,0)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var actual: bool = player.visual.study_visible
		root.get_texture().get_image().save_png(output.path_join(test.name+".png"))
		results.append({"case":test,"study_visible":actual,"pass":actual==bool(test.expected),"active_gear":player.visual.active_gear,"texture":player.visual._sprite.texture.resource_path})
		assert(actual==bool(test.expected))
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"complete":true,"results":results,"scope":"Rendered fallback selection only; not new animation coverage for other gears/views.","source_sha256":FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/studies/transition_19/transition_visual.gd")},"\t"))
	file.close()
	print("TRANSITION_SCOPE_COMPLETE ",results.size())
	quit(0)
