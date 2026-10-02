extends SceneTree
var main: Node
var world: Node
var state: Node
var five: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func capture(label: String) -> void:
	world.player.camera.reset_smoothing();world.player.camera.force_update_scroll()
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
	var data: Dictionary={"native":world.player.visual.native_worn_snapshot(),"five":five.snapshot(),"anchor":world.player.visual._native_worn.mod_anchor()}
	FileAccess.open(output.path_join(label+".json"),FileAccess.WRITE).store_string(JSON.stringify(data,"\t"))
func run() -> void:
	output=OS.get_environment("MODS_OUT");DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
	for i in 5: await process_frame
	state=root.get_node("RunState");state.initialize_persistence(output.path_join("save.json"));state.reset_run(false)
	main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_jump_endless(1);main._dev_grant_max_tools_state()
	world=main.endless_world;five=world.drill_modes.five;world.resonance_drill.set_enabled(false)
	var mole: Node=main.get_node("CompanionInterface").active_mole();mole.autonomous_enabled=false;mole.recall()
	main.achievement_toast.hide();world.set_process(false);world.player.set_physics_process(false)
	world._ground_props.clear();world.discovery_sites.clear();world.resources.clear()
	for y in range(2,27):
		for x in range(3,37): world._set_floor(Vector2i(x,y),true)
	world.player.global_position=world._cell_center(Vector2i(18,12))
	for id in five.IDS:
		world.set_mine_held(false);five.reset();world.drill_modes.dev_override=id;world.set_mine_held(true)
		for bearing in 8:
			world.player.set_facing(Vector2.RIGHT.rotated(TAU*bearing/8.0));world.drill_modes.tick(0.016)
			await create_timer(0.22).timeout
			await capture("held-"+id+"-"+str(bearing))
			var snap: Dictionary=world.player.visual.native_worn_snapshot()
			checks.append({"name":id+str(bearing),"passed":bool(snap.get("mod_active",false)) and bool(snap.active) and not bool(snap.failed)})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	for check in checks:
		if not check.passed: quit(1);return
	print("FIVE_VISUAL_OK");quit(0)
