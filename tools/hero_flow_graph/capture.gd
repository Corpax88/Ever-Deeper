extends SceneTree
## Real game controls and original world mechanics; only the visual is varied.
var output := ""
var scenario := "interrupt"
var baseline := false
var forge_level := 0
var main: Node
var world: Node
var player: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--scenario="): scenario = arg.trim_prefix("--scenario=")
		if arg.begins_with("--forge="): forge_level = int(arg.trim_prefix("--forge="))
		if arg == "--baseline": baseline = true
	assert(output.is_absolute_path() and DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(output)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	for path in ["Player/Visual", "EndlessDescentWorld/Player/Visual"]:
		var visual: Node = main.get_node_or_null(path)
		if visual != null: visual.flow_graph_enabled = false
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
	state.endless_workshops["tool_forge"] = {"built":forge_level > 0,"level":forge_level}
	player.prepare_visual_cache()
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	world.restore_position(Vector2(1696,1690) if scenario == "walk-entry" else Vector2(1696,1648))
	player.set_facing(Vector2.UP)
	player.control_enabled = true
	main.quick_tutorial.dismiss()
	for i in 180:
		await RenderingServer.frame_post_draw
		if player.visual.active_gear == "worn" and i > 15: break
	assert(player.visual.active_gear == "worn")
	var initial_hp: int = int(world.resources[17].hp)
	var initial_serial: int = int(player._mining_impact_serial)
	var samples: Array = []
	player.visual.flow_graph_enabled = not baseline
	var events := {12:"start",26:"cancel_before_hit",30:"restart",56:"release_after_hit",59:"restart",84:"walk_cancel",90:"stop_walk"}
	var total := 150
	if scenario == "walk-entry":
		events = {0:"walk_up",8:"walk_to_mine",70:"release_after_hit",92:"walk_up",96:"walk_to_mine",128:"release_after_hit"}
	if scenario == "held":
		events = {12:"start",128:"release_after_hit"}
	if scenario == "switches":
		events = {12:"start",32:"outfit",46:"cancel_before_hit",50:"walk_cancel",56:"walk_to_mine",80:"equip",106:"restore",130:"release_after_hit"}
	var start_tick: int = Engine.get_physics_frames()
	for i in total:
		var event: String = events.get(i, "")
		if event == "walk_up": main._on_joystick_movement(Vector2.UP)
		if event == "walk_to_mine":
			main._on_joystick_movement(Vector2.ZERO)
			player.set_facing(Vector2.UP)
			main._set_mine_held(true)
		if event in ["start", "restart"]: main._set_mine_held(true)
		if event in ["cancel_before_hit", "release_after_hit"]: main._set_mine_held(false)
		if event == "walk_cancel": main._on_joystick_movement(Vector2.DOWN)
		if event == "stop_walk":
			main._on_joystick_movement(Vector2.ZERO)
			main._set_mine_held(false)
		if event == "outfit": state.endless_outfit = "expedition"
		if event == "equip": state.pickaxe_level = 2
		if event == "restore": state.pickaxe_level = 1
		await RenderingServer.frame_post_draw
		var graph: Dictionary = player.visual._flow_graph.snapshot()
		var sample := {"frame":i,"seconds":float(Engine.get_physics_frames()-start_tick)/60.0,
			"event":event,"progress":player.mining_visual_progress,"active":player.mining_visual_active,
			"moving":player.is_actually_moving(),"direction":player.direction_name,
			"hp":int(world.resources[17].hp),"serial":int(player._mining_impact_serial)-initial_serial,
			"target":world.mining_target_id,"position":[player.global_position.x,player.global_position.y],
			"screen_position":[player.get_global_transform_with_canvas().origin.x,player.get_global_transform_with_canvas().origin.y],
			"screen_transform":[root.get_final_transform().x.x,root.get_final_transform().y.y,root.get_final_transform().origin.x,root.get_final_transform().origin.y],
			"gear":player.visual.active_gear,"outfit":player.visual.active_endless_outfit_style,
			"flow_visible":player.visual._flow_visible,"graph":graph,
			"production_state":player.visual._last_state,"production_frame":player.visual._last_local_frame,
			"walk_phase":player.visual._walk_phase,"hit_phase":player.visual.strike_phase}
		samples.append(sample)
		root.get_texture().get_image().save_png(output.path_join("frame-%04d.png" % i))
	main._set_mine_held(false)
	var report := {"complete":true,"samples":samples,"initial_hp":initial_hp,
		"damage":initial_hp-int(world.resources[17].hp),"hits":int(player._mining_impact_serial)-initial_serial,
		"scenario":scenario,"baseline":baseline,"forge_level":forge_level,"cycle_seconds":world._mining_cycle_duration(),
		"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),"viewport":[root.size.x,root.size.y],
		"visual_accepted":false,"production_accepted":false,
		"controller_sha256":FileAccess.get_sha256("res://scripts/player/hero_flow_graph.gd"),
		"consumer_sha256":FileAccess.get_sha256("res://scripts/player/player_visual.gd")}
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("FLOW_GRAPH_GAME_COMPLETE ",report.hits," ",report.damage)
	quit()
