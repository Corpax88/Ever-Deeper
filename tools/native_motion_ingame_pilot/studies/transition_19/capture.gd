extends SceneTree
## Actual transition inputs in the unchanged world; isolated diagnostic.
var output := ""
var frames := ""
var candidate := false
var walk_frames := ""
var rapid := false
var main: Node
var world: Node
var player: Node

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var source_hashes := {}
	for path in ["res://tools/native_motion_ingame_pilot/studies/transition_19/capture.gd", "res://tools/native_motion_ingame_pilot/studies/transition_19/transition_visual.gd"]:
		source_hashes[path] = FileAccess.get_sha256(path)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--frames="): frames = arg.trim_prefix("--frames=")
		if arg == "--candidate": candidate = true
		if arg.begins_with("--walk-frames="): walk_frames = arg.trim_prefix("--walk-frames=")
		if arg == "--rapid": rapid = true
	assert(output.is_absolute_path() and frames.is_absolute_path())
	assert(DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(output)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld/Player/Visual").set_script(load("res://tools/native_motion_ingame_pilot/studies/transition_19/transition_visual.gd" if candidate else "res://tools/native_motion_ingame_pilot/studies/overhead_swing_18/loop_visual.gd"))
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
	if not walk_frames.is_empty(): player.visual.configure_walk(walk_frames)
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
	var events := {12:"start",26:"cancel_before_hit",44:"restart",70:"release_after_hit",100:"start_again",125:"walk_cancel",148:"stop_walk"}
	if rapid: events = {12:"start",26:"cancel_before_hit",30:"restart",56:"release_after_hit",59:"restart",84:"walk_cancel",107:"stop_walk"}
	var start_tick: int = Engine.get_physics_frames()
	for i in (110 if rapid else 180):
		var event: String = events.get(i, "")
		if event in ["start", "restart", "start_again"]: main._set_mine_held(true)
		if event in ["cancel_before_hit", "release_after_hit"]: main._set_mine_held(false)
		if event == "walk_cancel": main._on_joystick_movement(Vector2.DOWN)
		if event == "stop_walk":
			main._on_joystick_movement(Vector2.ZERO)
			main._set_mine_held(false)
		await RenderingServer.frame_post_draw
		var sample := {"frame":i,"seconds":float(Engine.get_physics_frames()-start_tick)/60.0,
			"event":event,"progress":player.mining_visual_progress,"cell":player.visual.study_frame,
			"study_visible":player.visual.study_visible,"active":player.mining_visual_active,
			"moving":player.is_actually_moving(),"direction":player.direction_name,
			"presenting_impact":player.visual.study_impact,"hp":int(world.resources[17].hp),
			"serial":int(player._mining_impact_serial)-initial_serial,"target":world.mining_target_id,
			"position":[player.global_position.x,player.global_position.y],
			"screen_position":[player.get_global_transform_with_canvas().origin.x,player.get_global_transform_with_canvas().origin.y],
			"screen_transform":[root.get_final_transform().x.x,root.get_final_transform().y.y,root.get_final_transform().origin.x,root.get_final_transform().origin.y],
			"production_state":player.visual._last_state,"production_frame":player.visual._last_local_frame}
		if candidate: sample["transition"] = player.visual.transition_snapshot()
		samples.append(sample)
		root.get_texture().get_image().save_png(output.path_join("frame-%04d.png" % i))
	main._set_mine_held(false)
	var damage: int = initial_hp-int(world.resources[17].hp)
	var hits: int = int(player._mining_impact_serial)-initial_serial
	var report := {"complete":true,"samples":samples,"initial_hp":initial_hp,"damage":damage,"hits":hits,
		"scenario":"rapid" if rapid else "standard",
		"source_hashes_at_start":source_hashes,
		"walk_atlas_sha256":FileAccess.get_sha256(walk_frames.path_join("atlas.png")) if not walk_frames.is_empty() else "",
		"engine":Engine.get_version_info().string,"display":DisplayServer.get_name(),
		"viewport":[root.size.x,root.size.y],"mechanical_pass":hits==2 and damage==8,
		"scope":"Entry, pre-hit cancel/restart, post-hit release and movement interruption. Real inputs, fixed60Hz.",
		"visual_accepted":false,"production_accepted":false,"source_frames":frames,
		"atlas_sha256":FileAccess.get_sha256(frames.path_join("atlas.png"))}
	var file := FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("TRANSITION_STUDY_COMPLETE ",hits," ",damage)
	quit(0 if bool(report.mechanical_pass) else 1)
