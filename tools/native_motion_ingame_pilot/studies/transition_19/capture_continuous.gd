extends SceneTree
## Continuous19C gameplay preview; no injected cancellation/restart inputs.
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
	var original_position: Vector2 = player.global_position
	var initial_hp: int = int(world.resources[17].hp)
	var initial_serial: int = int(player._mining_impact_serial)
	var samples: Array = []
	player.visual.study_enabled = true
	main._set_mine_held(true)
	var start_tick: int = Engine.get_physics_frames()
	for i in 150:
		await RenderingServer.frame_post_draw
		var sample := {"screen_position":[player.get_global_transform_with_canvas().origin.x,player.get_global_transform_with_canvas().origin.y],"screen_transform":[root.get_final_transform().x.x,root.get_final_transform().y.y,root.get_final_transform().origin.x,root.get_final_transform().origin.y],"frame":i,"seconds":float(Engine.get_physics_frames()-start_tick)/60.0,
			"progress":player.mining_visual_progress,"cell":player.visual.study_frame,
			"presenting_impact":player.visual.study_impact,"hp":int(world.resources[17].hp),
			"serial":int(player._mining_impact_serial)-initial_serial,"target":world.mining_target_id,
			"position":[player.global_position.x,player.global_position.y]}
		samples.append(sample)
		assert(Vector2(player.global_position).distance_to(original_position)<.001)
		root.get_texture().get_image().save_png(output.path_join("frame-%04d.png" % i))
	main._set_mine_held(false)
	var damage: int = initial_hp-int(world.resources[17].hp)
	var hits: int = int(player._mining_impact_serial)-initial_serial
	var report := {"complete":true,"samples":samples,"initial_hp":initial_hp,"damage":damage,"hits":hits,
		"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),
		"viewport":[root.size.x,root.size.y],"mechanical_pass":hits>=3 and damage==hits*4,
		"scope":"Repeated real held mining only. Entry, exit, foot projection and visual contact remain review gates.",
		"visual_accepted":false,"production_accepted":false,"source_frames":frames,
		"visual_source_sha256":FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/studies/transition_19/transition_visual.gd"),
		"atlas_sha256":FileAccess.get_sha256(frames.path_join("atlas.png"))}
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("CONTINUOUS19_COMPLETE ",hits," ",damage)
	quit(0 if bool(report.mechanical_pass) else 1)
