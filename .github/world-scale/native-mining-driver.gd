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

	var qa = load("res://scripts/qa/suites/skills_browser_review.gd").new(main,main)
	for scenario in ["surface","moss_ore","depth_ore","endless_ore"]:
		qa._mole_fixture(scenario)
		for frame in 5: await process_frame
		var world: Node2D=main._active_player_node().get_parent()
		await capture(scenario+"-before")
		Input.action_press("mine")
		var deadline: int=Time.get_ticks_msec()+15000
		while not world.companion_work_target(qa.mole_target).is_empty() and Time.get_ticks_msec()<deadline:
			await process_frame
		Input.action_release("mine")
		if not verify(world.companion_work_target(qa.mole_target).is_empty(),"held mining depletes "+scenario): return
		await capture(scenario+"-after")
	print("WORLD_SCALE_MINING_OK")
	quit(0)
