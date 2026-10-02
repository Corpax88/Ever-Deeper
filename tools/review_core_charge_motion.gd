extends SceneTree
var main: Node
var world: Node
var state: Node
var five: Node
var output: String
var frames: Array = []
func _initialize() -> void: run.call_deferred()
func run() -> void:
	output = OS.get_environment("MODS_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate(); root.add_child(main); current_scene = main
	for i in 5: await process_frame
	state = root.get_node("RunState"); state.initialize_persistence(output.path_join("isolated-save.json")); state.reset_run(false)
	main._dev_ensure_playing(); main._dev_seed_victory_state(); main._dev_jump_endless(1)
	world = main.endless_world; five = world.drill_modes.five
	world.set_process(false); world.player.set_physics_process(false); world.resonance_drill.set_enabled(false)
	var mole: Node = main.get_node("CompanionInterface").active_mole(); mole.autonomous_enabled=false; mole.recall()
	world._ground_props.clear(); world.discovery_sites.clear(); main.achievement_toast.hide()
	state.drill_level=1; state.starforge_variant=""
	if state.endless_workshops.has("tool_forge"): state.endless_workshops.tool_forge.level=0
	for mod in ["corebreaker"]:
		if not OS.get_environment("MOTION_MODS").is_empty() and mod not in OS.get_environment("MOTION_MODS").split(","): continue
		world.set_mine_held(false); five.reset(); world.resources.clear(); world._clear_loose_drop_visuals()
		for visual in world.resource_visuals.values():
			if is_instance_valid(visual): visual.queue_free()
		world.resource_visuals.clear()
		for y in range(2,27):
			for x in range(3,37): world._set_floor(Vector2i(x,y),true)
		world.player.global_position=world._cell_center(Vector2i(18,12)); world.player.set_facing(Vector2.RIGHT)
		world.player.camera.reset_smoothing(); world.player.camera.force_update_scroll()
		world.drill_modes.dev_override=mod; world.drill_modes.tick(0.016)
		five.hits=0; five.hit_log.clear()
		if mod in ["chainbreaker","corebreaker"]:
			var cells: Array[Vector2i]=[Vector2i(19,12),Vector2i(17,10),Vector2i(19,10),Vector2i(21,11),Vector2i(20,14),Vector2i(17,14)]
			for i in cells.size():
				var ore: Dictionary={"id":"motion-"+mod+str(i),"cell":cells[i],"position":world._cell_center(cells[i]),"hp":99999,"max_hp":99999,"mined":false,"kind":"rootiron","amount":1,"depth":1,"node_index":0}
				world.resources.append(ore); world._build_resource_visual(ore)
			if mod=="corebreaker": five.charge=0.0
		else:
			for y in range(5,20):
				for x in range(20,30): world._set_floor(Vector2i(x,y),false)
		world._update_buried_visibility(); world.queue_redraw()
		for wait_frame in 12: await process_frame
		for frame in 300:
			var held: bool=frame>=18 and frame<270
			world.set_mine_held(held)
			world.drill_modes.tick(1.0/60.0)
			if mod=="vortex":
				if frame in [20,45,70,95]:
					for j in 8:
						var cell: Vector2i=Vector2i(16+j%4,10+j/4*4)
						state._register_endless_drop(1,"motion-"+str(frame)+"-"+str(j),world._chunk_cell_index(cell),"deep_alloy",1)
					world._sync_loose_drops()
				five.collect_vortex(1.0/60.0)
			await process_frame
			if frame%10==0:
				await RenderingServer.frame_post_draw
				var filename: String=mod+"-%03d.jpg"%frame
				root.get_texture().get_image().save_jpg(output.path_join(filename),0.95)
				frames.append({"file":filename,"simulation_seconds":frame/60.0,"five":five.snapshot()})
		world.set_mine_held(false)
	FileAccess.open(output.path_join("sequence.json"),FileAccess.WRITE).store_string(JSON.stringify(frames,"\t"))
	print("MOD_MOTION_CAPTURE_OK")
	await process_frame
	quit(0)
