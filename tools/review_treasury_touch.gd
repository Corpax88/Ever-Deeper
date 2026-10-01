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
func tap(at: Vector2) -> void:
	var down: InputEventScreenTouch=InputEventScreenTouch.new()
	down.index=9;down.position=at;down.pressed=true
	Input.parse_input_event(down)
	await process_frame
	var up: InputEventScreenTouch=InputEventScreenTouch.new()
	up.index=9;up.position=at;up.pressed=false
	Input.parse_input_event(up)
	for i in 4: await process_frame
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
	state.treasury_totals.wallet_gold=100000
	room.refresh_piles()
	var aim: Vector2=room.bay(26)
	hub.restore_position(aim+(room.ZONE-aim).normalized()*200.0+Vector2(0,40))
	hub.player.camera.reset_smoothing()
	for i in 6: await process_frame
	var at: Vector2=hub.get_canvas_transform()*(aim+Vector2(0,-30))
	var down: InputEventScreenTouch=InputEventScreenTouch.new()
	down.index=6;down.position=at;down.pressed=true
	Input.parse_input_event(down)
	await process_frame
	var up: InputEventScreenTouch=InputEventScreenTouch.new()
	up.index=6;up.position=at;up.pressed=false
	Input.parse_input_event(up)
	for i in 4: await process_frame
	if not verify(main.treasury_goal_panel.visible,"Actual touch opens gold podium"): return
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
	await tap(main.minimap_overlay._map_rect.get_center())
	if not verify(main.miner_skills_panel.visible and main.miner_skills_panel.map_view.visible,"Actual minimap touch opens map"): return
	await capture("map-all-discovered")
	main._close_miner_skills()
	state.area_unlocked=false
	state.emberdeep_unlocked=false
	state.fourth_unlocked=false
	main._update_minimap()
	await tap(main.minimap_overlay._map_rect.get_center())
	if not verify(main.miner_skills_panel.visible and main.miner_skills_panel.map_view.visible,"Actual minimap touch opens map"): return
	await capture("map-first-world")
	print("TREASURY_STACK_RENDER_OK")
	quit(0)
