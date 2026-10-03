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
		push_error("TREASURY_FAIL "+label)
		quit(2)
	return ok
func capture(label: String) -> void:
	main.achievement_toast.clear()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func walk(action: String, target: Callable, label: String) -> bool:
	Input.action_press(action)
	var deadline: int = Time.get_ticks_msec()+15000
	while not target.call() and Time.get_ticks_msec()<deadline: await process_frame
	Input.action_release(action)
	return verify(bool(target.call()),label)
func run() -> void:
	output=OS.get_environment("TREASURY_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 5: await process_frame
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
	state.cargo.stone=8000
	state.cargo.copper=4000
	state.gold=3000
	hub.restore_position(hub.TREASURY_DOOR+Vector2(-65,0))
	await capture("01-hub-entrance")
	if not await walk("move_right",func():return room.inside,"walk into treasury"): return
	await capture("02-interior-entry")
	verify(room.display_nodes.size()==27,"all 27 podiums retained")
	verify(room.collision(Vector2(310,1590)),"right jamb blocks movement")
	hub.restore_position(room.DONATION+Vector2(-115,0))
	if not await walk("move_right",func():return room.delivering,"walk onto donation plate"):return
	await create_timer(1.0).timeout
	await capture("03-mixed-flight")
	var deadline: int=Time.get_ticks_msec()+20000
	while room.delivering and Time.get_ticks_msec()<deadline:await process_frame
	if not verify(not room.delivering and state.cargo.stone==0 and state.cargo.copper==0 and state.gold==0 and state.treasury_totals.stone==8000 and state.treasury_totals.copper==4000 and state.treasury_totals.wallet_gold==3000,"exact resource conservation"):return
	await capture("04-landed")
	state.cargo.stone=8000
	room.start()
	await create_timer(0.4).timeout
	room.stop()
	var kept: int=state.cargo.stone
	room.armed=false
	await create_timer(0.5).timeout
	verify(state.cargo.stone==kept,"interrupted deliveries retain cargo")
	for index in [0,7,13,20,26]:
		state.treasury_totals[room.Ledger.keys()[index]]=100000
		room.refresh_piles()
		var aim: Vector2=room.bay(index)
		hub.restore_position(aim+(room.ZONE-aim).normalized()*220.0+Vector2(0,40))
		hub.player.camera.reset_smoothing()
		await capture("05-bay-%02d"%index)
	verify(state.flush_save(),"save succeeds")
	var totals: Dictionary=state.treasury_totals.duplicate(true)
	verify(state.load_game() and state.treasury_totals==totals,"save reload preserves totals")
	hub.restore_position(Vector2(210,1660))
	hub.player.camera.reset_smoothing()
	await capture("06-exit-approach")
	if not await walk("move_up",func():return not room.inside,"walk up through matching interior door"):return
	await capture("07-returned-hub")
	verify(hub.player.global_position.distance_to(hub.TREASURY_DOOR+Vector2(-130,0))<30,"returns beside hub entrance")
	print("TREASURY_ATMOSPHERE_OK")
	quit(0)
