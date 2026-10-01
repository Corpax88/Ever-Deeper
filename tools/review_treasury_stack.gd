extends SceneTree
var output: String
var checks: Array = []
var main: Node
var hub: Node
var room: Node
var state: Node
func _initialize() -> void:
	run.call_deferred()
func verify(ok: bool, label: String) -> bool:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(output.path_join("interaction.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not ok:
		push_error("CIRCULAR_TREASURY_FAIL "+label)
		quit(2)
	return ok
func capture(label: String) -> void:
	main.achievement_toast.hide()
	main.action_button.hide()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func walk(action: String, target: Callable, label: String) -> bool:
	Input.action_press(action)
	var deadline: int = Time.get_ticks_msec()+20000
	while not target.call() and Time.get_ticks_msec()<deadline: await process_frame
	Input.action_release(action)
	return verify(bool(target.call()),label)
func run() -> void:
	output=OS.get_environment("CIRCULAR_REVIEW_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 4: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_jump_hub()
	for i in 5: await process_frame
	hub=main.hub_world
	room=hub.treasury
	state.cargo=state._empty_resource_store()
	for kind in state.RESOURCE_IDS: state.cargo[kind]=800
	state.gold=800
	room.enter()

	hub.set_process(false)
	hub.player.set_physics_process(false)
	room.stop()
	for amount in [1,555,556,10000,30000,60000,100000]:
		for kind in room.Ledger.keys(): state.treasury_totals[kind]=amount
		room.refresh_piles()
		for index in [0,12,26]:
			var aim: Vector2=room.bay(index)
			hub.player.global_position=aim+(room.ZONE-aim).normalized()*200.0+Vector2(0,40)
			hub._on_player_moved(hub.player.global_position)
			room._refresh_camera()
			hub.player.camera.reset_smoothing()
			await capture("stack-%d-%d" % [amount,index])
	main.treasury_goal_panel.open_goal("wallet_gold")
	await capture("goal-full-gold")
	main.treasury_goal_panel._claim()
	verify(bool(state.treasury_goals.get("resonance_claimed",false)),"Full gold grants Resonance")
	main.treasury_goal_panel.Goals.pin("wallet_gold")
	await capture("goal-claimed-gold")
	main.treasury_goal_panel.close_panel()
	room.leave()
	hub.set_process(true)
	hub.player.set_physics_process(true)
	main._dev_jump_surface()
	for i in 5: await process_frame
	main._update_minimap()
	main._open_miner_skills()
	main.miner_skills_panel.show_map(main.minimap_overlay)
	await capture("map-all-discovered")
	main._close_miner_skills()
	state.area_unlocked=false
	state.emberdeep_unlocked=false
	state.fourth_unlocked=false
	main._update_minimap()
	main._open_miner_skills()
	main.miner_skills_panel.show_map(main.minimap_overlay)
	await capture("map-first-world")
	print("TREASURY_STACK_RENDER_OK")
	quit(0)
