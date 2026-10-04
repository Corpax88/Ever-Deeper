extends SceneTree
## Actual DrillModes + MinerTraining integration; no fabricated mining animation.
## Run with MODS_OUT=<dir> Godot --headless --path <project> --script res://tools/review_laser_stamina.gd
var main: Node
var world: Node
var state: Node
var training: Node
var checks: Array = []
var output: String

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool, details: Dictionary = {}) -> void:
	checks.append({"name":label,"passed":passed,"details":details})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("LASER_STAMINA_MISMATCH "+label)

func fresh() -> void:
	world.drill_modes.reset()
	world.drill_modes.dev_override = "laser"
	world.drill_modes.dev_laser_on = true
	world.resources.clear()
	world.dig_damage.clear()
	world._clear_loose_drop_visuals()
	world.active = true
	world.player.control_enabled = true
	world.player.external_movement = Vector2.ZERO
	world.player.global_position = world._cell_center(Vector2i(18,12))
	world.player.set_facing(Vector2.RIGHT)
	world.player.animation_bearing = Vector2.RIGHT
	world._cancel_mining()
	for y in range(1,32):
		for x in range(2,38): world._set_floor(Vector2i(x,y),true)
	for x in range(19,37): world._set_floor(Vector2i(x,12),false)
	state.miner_skills = {"mining":0.0,"running":0.0,"carrying":0.0,"prospecting":0.0,"stamina":50.0}
	state._miner_level_cache.clear()
	state._stamina_rest = 0.0
	main.menu_open = false
	main.inventory_open = false
	world.set_mine_held(true)

func advance(seconds: float, tick_modes: bool = true) -> void:
	for _step in roundi(seconds/0.05):
		if tick_modes: world.drill_modes.tick(0.05)
		training._physics_process(0.05)

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-laser-stamina"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_grant_max_tools_state()
	main._dev_jump_endless(1)
	world = main.endless_world
	training = main.get_node("MinerTraining")
	training.set_physics_process(false)
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.resonance_drill.dev_override = false
	world.resonance_drill.set_enabled(false)
	var mole: Node = main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled = false
	mole.recall()
	world._ground_props.clear()
	world.discovery_sites.clear()
	main.achievement_toast.hide()

	fresh()
	var impacts: int = world.drill_modes.impacts
	advance(1.0)
	check("real-laser-clears-rock",world.drill_modes.impacts>impacts and world._is_floor(Vector2i(19,12)))
	check("laser-needs-no-pickaxe-animation",not world.player.mining_visual_active)
	check("targeted-laser-drains-real-stamina",absf(state.stamina_value()-46.0)<0.01,{"stamina":state.stamina_value()})
	check("real-hits-still-earn-mining-xp",float(state.miner_skills.mining)>0.0)

	fresh()
	for x in range(19,37): world._set_floor(Vector2i(x,12),true)
	advance(1.0)
	check("empty-ray-allows-rest",state.stamina_value()>50.0 and not world.drill_modes.is_mining_work_active())
	check("empty-ray-earns-no-mining-xp",float(state.miner_skills.mining)==0.0)

	fresh()
	world.drill_modes.tick(0.01)
	world.set_mine_held(false)
	advance(1.0,false)
	check("release-invalidates-work-before-next-draw-tick",state.stamina_value()>50.0 and not world.drill_modes.is_mining_work_active())

	fresh()
	world.drill_modes.tick(0.01)
	world.drill_modes.dev_laser_on = false
	advance(1.0,false)
	check("laser-toggle-off-invalidates-stale-work",state.stamina_value()>50.0 and not world.drill_modes.is_mining_work_active())

	fresh()
	world.drill_modes.tick(0.01)
	main.menu_open = true
	world.player.control_enabled = false
	var before_xp: float = state.miner_skills.mining
	advance(1.0,false)
	check("menu-rests-with-no-laser-training",state.stamina_value()>50.0 and state.miner_skills.mining==before_xp)
	check("disabled-controls-invalidate-stale-work",not world.drill_modes.is_mining_work_active())

	fresh()
	world.drill_modes.tick(0.01)
	world.active = false
	check("inactive-world-invalidates-stale-work",not world.drill_modes.is_mining_work_active())
	world.drill_modes.reset()
	check("reset-clears-work-state",not world.drill_modes.mining_work_active)

	for row in checks:
		if not row.passed:
			quit(1)
			return
	print("LASER_STAMINA_OK "+str(checks.size()))
	quit(0)
