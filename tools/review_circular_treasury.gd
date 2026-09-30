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
	hub.restore_position(hub.TREASURY_DOOR+Vector2(-70,0))
	if OS.get_environment("CIRCULAR_VISUAL_ONLY")=="1":
		room.enter()
		hub.player.global_position=room.ZONE
		room.armed=false
		room.stop()
		for kind in room.Ledger.keys(): state.treasury_totals[kind]=10000
		room.refresh_piles()
		await create_timer(8.0).timeout
		await capture("mature-final")
		print("CIRCULAR_TREASURY_INTERACTION_OK visual-only")
		quit(0)
		return
	await capture("01-opening")
	if not await walk("move_right",func():return room.inside,"held movement enters without interaction"): return
	await capture("02-entered")
	if not await walk("move_right",func():return room.delivering,"held movement reaches central donation zone"): return
	await create_timer(2.5).timeout
	await capture("03-radial-delivery")
	var before: Dictionary=state.treasury_totals.duplicate(true)
	verify(not before.is_empty() and not room.particles.is_empty(),"landed piles and flying parcels coexist")
	if not await walk("move_left",func():return not room.inside,"held movement walks back through west opening"):return
	verify(room.particles.is_empty() and room.batches.is_empty(),"walk-out cancels outstanding parcels")
	var remaining: Dictionary=state.cargo.duplicate(true)
	await create_timer(1.8).timeout
	verify(state.cargo==remaining,"walk-out retains undelivered cargo")
	await capture("04-returned-hub")
	if not await walk("move_right",func():return room.inside,"held movement reenters through same opening"):return
	verify(room.collision(room.ZONE+Vector2(870,0)),"round wall blocks movement outside chamber")
	verify(not room.collision(room.ZONE),"centre remains walkable")
	await capture("05-reentered")
	room.stop()
	for kind in room.Ledger.keys(): state.treasury_totals[kind]=10000
	room.refresh_piles()
	await capture("06-mature")
	print("CIRCULAR_TREASURY_INTERACTION_OK checks=",checks.size())
	quit(0)
