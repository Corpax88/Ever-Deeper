extends SceneTree
## Actual interaction approaches and full mobile recipes; no replacement terrain.
var output: String
var main: Node
var state: Node
var captures: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for frame in 5: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed=4608
	seed(4608)
	main._dev_jump_surface()
	for station in ["sell","forge","speedShop"]:
		var world: Node=main.surface_world
		world.restore_position(world.station_interaction_position(station))
		world.player.set_facing(Vector2.UP)
		await _capture("surface_approach_"+station,world)
	main._dev_jump_hub()
	await _capture("hub_fresh_entrance",main.hub_world)
	main._dev_seed_victory_state()
	main._dev_build_all_workshops_state()
	main._dev_jump_hub()
	await create_timer(4.0).timeout
	for position in [Vector2(720,480),Vector2(180,200),Vector2(1240,780)]:
		main.hub_world.restore_position(position)
		await _capture("hub_built_%d_%d" % [position.x,position.y],main.hub_world)
	for workshop in ["tool_forge", "light_lab", "wardrobe", "lift_workshop"]:
		main.hub_world.restore_position(main.hub_world._workshop_position(workshop)+Vector2(0,105))
		main.hub_world.player.set_facing(Vector2.UP)
		await _capture("hub_approach_"+workshop,main.hub_world)
	main._dev_jump_mine("emberMine",2)
	state.victory=false
	state.singularity_secured=false
	state.set_drill_level(2)
	state.gold=17320
	for resource in state.cargo: state.cargo[resource]=0
	for requirement in state.next_drill_recipe().requirements:
		state.cargo[String(requirement.type)]=int(requirement.amount)/3
	state.cargo["copper"]=14
	state.changed.emit()
	await _capture("final_drill_five_costs",main.depth_world)
	main.premium_hud._toggle_objective()
	await _capture("final_drill_guide_open",main.depth_world)
	FileAccess.open(output.path_join("composition.json"),FileAccess.WRITE).store_string(JSON.stringify({"rendered":true,"physical_iphone":false,"source_only":true,"captures":captures},"\t"))
	print("PREMIUM_COMPOSITION_COMPLETE captures=",captures.size())
	quit()

func _capture(id: String,world: Node) -> void:
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled=false
	world.player.camera.reset_smoothing()
	main._refresh_hud()
	await create_timer(0.6).timeout
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var picture: Image=root.get_texture().get_image()
	picture.save_png(output.path_join(id+".png"))
	var context: String=world.current_context() if world.has_method("current_context") else main.surface_context
	captures.append({"id":id,"size":str(picture.get_size()),"player":str(world.player.global_position),"context":context,"goal":main.premium_hud.progression_goal_snapshot(),"touch_layout":main.premium_hud.layout_snapshot(root.get_visible_rect().size)})
