extends SceneTree
## A real Earthshaker excavation must train the mole, not fabricate hero swings.
var main: Node
var state: Node
var checks: Array = []
var output: String

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("COMPANION_TRAINING_MISMATCH "+label)

func run() -> void:
	output=OS.get_environment("MODS_OUT")
	if output.is_empty() or OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Use disposable MODS_OUT and XDG_DATA_HOME for this review")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for _frame in 5: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_grant_max_tools_state()
	main._dev_jump_endless(1)
	var world: Node=main.endless_world
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.global_position=world._cell_center(Vector2i(18,12))
	world.player.control_enabled=true
	world._ground_props.clear()
	world.resources.clear()
	world.dig_damage.clear()
	for y in range(10,16):
		for x in range(16,27): world._set_floor(Vector2i(x,y),true)
	for y in [12,13]:
		for x in [20,21]: world._set_floor(Vector2i(x,y),false)
	var mole: Node=main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled=false
	mole.set_physics_process(false)
	mole.recall()
	mole.action="shake"
	mole.mode="dig"
	mole.action_clock=0.0
	mole.automatic_task=false
	mole.assist_action=false
	mole.task_point=world._cell_center(Vector2i(20,12))
	state.miner_skills.mining=0.0
	state.total_swings=0
	state.precision_hits=0
	var dug_before: int=mole.dug_total
	mole._update_action(0.5)
	check("Earthshaker actually excavates four reachable cells",mole.dug_total==dug_before+4 and world._is_floor(Vector2i(20,12)) and world._is_floor(Vector2i(21,13)))
	check("companion feedback preserves the hero's mining XP",float(state.miner_skills.mining)==0.0)
	check("companion feedback preserves hero swing and precision counters",int(state.total_swings)==0 and int(state.precision_hits)==0)
	world._set_floor(Vector2i(20,12),false)
	world._strike_wall(Vector2i(20,12),0.5,false)
	check("actual hero mining still earns XP and one swing",float(state.miner_skills.mining)==4.0 and int(state.total_swings)==1 and int(state.precision_hits)==1)
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	FileAccess.open(output.path_join("companion-training.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	print("COMPANION_TRAINING_OK" if passed else "COMPANION_TRAINING_FAILED")
	quit(0 if passed else 1)
