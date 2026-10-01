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
	for amount in [1000]:
		for kind in room.Ledger.keys(): state.treasury_totals[kind]=amount
		room.refresh_piles()
		for index in [0]:
			var aim: Vector2=room.bay(index)
			hub.player.global_position=aim+Vector2(155,90)
			hub._on_player_moved(hub.player.global_position)
			hub.player.camera.reset_smoothing()
			await capture("treasury-%d-%d" % [amount,index])
	verify(not room.collision(room.ZONE),"central delivery remains walkable")
	verify(not room.collision(room.ENTRY),"entry remains walkable")
	for i in room.Ledger.keys().size():
		verify(room.collision(room.bay(i)),"pedestal collision %d" % i)

	room.leave()
	hub.set_process(true)
	hub.player.set_physics_process(true)
	var qa = load("res://scripts/qa/suites/skills_browser_review.gd").new(main,main)
	for index in [0,1,2,3]:
		await qa._scale_command({"kind":"scale_surface","index":index})
		await capture("surface-%d" % index)
	await qa._scale_command({"kind":"scale_surface","index":0})
	await qa._scale_command({"kind":"scale_drops"})
	await capture("all-drops")
	for mine_id in ["mossMine","moonMine","emberMine","starMine"]:
		await qa._scale_command({"kind":"scale_depth1","mine_id":mine_id})
		await capture("depth1-"+mine_id)
		await qa._node_asset_fixture(mine_id)
		await capture("depth2-"+mine_id+"-covered")
		for stage in ["exposed","respawn","reenter"]:
			qa._node_asset_stage(stage)
			await capture("depth2-"+mine_id+"-"+stage)
	await qa._scale_command({"kind":"scale_deep"})
	await capture("deep-node")
	print("WORLD_SCALE_RENDER_OK")
	quit(0)
