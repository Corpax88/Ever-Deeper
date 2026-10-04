extends SceneTree
## Actual charged impacts, normal power, exposed-ore snapshots and cancellation.
var main: Node
var world: Node
var state: Node
var five: Node
var checks: Array = []
var output: String

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("COREBREAKER_MISMATCH "+label)

func fresh(variant: String = "crusher", forge_level: int = 5) -> void:
	five.reset(); five.mode = "corebreaker"; five.direction = Vector2.RIGHT
	five.hits = 0; five.hit_log.clear(); five.held_last = true
	world.resources.clear(); world.dig_damage.clear(); world._clear_loose_drop_visuals()
	world.session_mined_nodes.clear(); state.endless_chunks.clear()
	state.starforge_variant = variant
	state.endless_relics.forge_heart.placed = true
	state.endless_workshops.tool_forge.built = forge_level>0
	state.endless_workshops.tool_forge.level = forge_level
	state.miner_skills.stamina = 100.0
	world.player.global_position = world._cell_center(Vector2i(18,12))
	world.player.external_movement = Vector2.ZERO
	world.player.set_facing(Vector2.RIGHT)
	world.player.animation_bearing = Vector2.RIGHT
	world.drill_modes.dev_override = "corebreaker"
	world.set_mine_held(true)
	for y in range(10,15):
		for x in range(15,39): world._set_floor(Vector2i(x,y),true)
	for x in range(20,26): world._set_floor(Vector2i(x,12),false)

func add_node(cell: Vector2i, hp: int = 1022) -> void:
	world.resources.append({"id":"core_fixture","cell":cell,"position":world._cell_center(cell),"hp":hp,"max_hp":hp,"mined":false,"kind":"deep_alloy","amount":10,"depth":1,"node_index":0})

func finish_burst() -> void:
	for _step in 8: five._update_core(0.05)

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-corebreaker"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate(); root.add_child(main); current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState"); state.initialize_persistence(output.path_join("save.json")); state.reset_run(false)
	main._dev_ensure_playing(); main._dev_seed_victory_state(); main._dev_grant_max_tools_state(); main._dev_jump_endless(1)
	world = main.endless_world; five = world.drill_modes.five
	world.set_process(false); world.set_physics_process(false); world.player.set_physics_process(false)
	world.resonance_drill.set_enabled(false); world._ground_props.clear(); world.discovery_sites.clear()
	var mole: Node = main.get_node("CompanionInterface").active_mole(); mole.autonomous_enabled=false; mole.recall()
	for variant in ["crusher","swift","prospector"]:
		fresh(variant)
		add_node(Vector2i(19,12))
		check("actual-max-power-one-hits-"+variant,five._power()>=1022)
		five.charge = 3.0; five._impact({"node":0},world._mining_cycle_duration()); finish_burst()
		check("charged-ore-break-is-real-"+variant,bool(world.resources[0].mined))
		check("unused-strokes-bore-two-more-cells-"+variant,world._is_floor(Vector2i(20,12)) and world._is_floor(Vector2i(21,12)))
		check("burst-is-three-strokes-only-"+variant,five.hits==3 and not world._is_floor(Vector2i(22,12)) and five.core_left==0 and five.charge==0.0)

	fresh("swift",0); add_node(Vector2i(19,12),2000)
	var power: int = five._power()
	five.charge=3.0; five._impact({"node":0},world._mining_cycle_duration()); finish_burst()
	check("hard-node-retains-three-normal-power-hits",int(world.resources[0].hp)==2000-power*3 and five.hit_log.size()==3)
	check("hard-node-blocks-followthrough",not world._is_floor(Vector2i(20,12)))

	fresh(); world._set_floor(Vector2i(19,12),false)
	five.charge=3.0; five._impact({"cell":Vector2i(19,12)},world._mining_cycle_duration()); finish_burst()
	check("charge-also-bursts-through-ordinary-rock",world._is_floor(Vector2i(19,12)) and world._is_floor(Vector2i(20,12)) and world._is_floor(Vector2i(21,12)))
	check("rock-burst-does-not-widen",not world._is_floor(Vector2i(22,12)) and five.hits==3)

	fresh(); world._set_floor(Vector2i(19,12),false); add_node(Vector2i(20,12))
	five.charge=3.0; five._impact({"cell":Vector2i(19,12)},world._mining_cycle_duration()); finish_burst()
	check("burst-reveals-new-ore-without-hitting-it",world._is_floor(Vector2i(20,12)) and int(world.resources[0].hp)==1022 and not bool(world.resources[0].mined))
	check("newly-revealed-ore-stops-this-burst",not world._is_floor(Vector2i(21,12)) and five.hits==2)

	fresh(); world._set_floor(Vector2i(19,12),false)
	five.charge=3.0; five._impact({"cell":Vector2i(19,12)},world._mining_cycle_duration())
	five.tick(0.05,"corebreaker",false); finish_burst()
	check("release-cancels-followthrough",five.hits==1 and not world._is_floor(Vector2i(20,12)))

	fresh(); world._set_floor(Vector2i(19,12),false)
	five.charge=3.0; five._impact({"cell":Vector2i(19,12)},world._mining_cycle_duration())
	five._update_core(10.0)
	check("stall-never-batches-remaining-strokes",five.hits==2 and five.core_left==1)
	five.reset(); finish_burst()
	check("reset-cancels-remaining-work",five.hits==2 and five.core_left==0)

	fresh(); add_node(Vector2i(19,12))
	five.charge=3.0; five._impact({"node":0},world._mining_cycle_duration())
	var shift: Vector2 = Vector2(0,world.TILE_SIZE)
	five.rebase(shift); world.player.global_position+=shift
	for node in world.resources:
		node.position=Vector2(node.position)+shift; node.cell=Vector2i(node.cell)+Vector2i(0,1)
	for x in range(20,26): world._set_floor(Vector2i(x,13),false)
	finish_burst()
	check("rebase-continues-at-shifted-rock-front",five.hits==3 and world._is_floor(Vector2i(20,13)) and world._is_floor(Vector2i(21,13)) and not world._is_floor(Vector2i(20,12)))

	fresh(); world.player.global_position=world._cell_center(Vector2i(36,12)); world._set_floor(Vector2i(37,12),false); world._set_floor(Vector2i(38,12),false)
	five.charge=3.0; five._impact({"cell":Vector2i(37,12)},world._mining_cycle_duration()); finish_burst()
	check("permanent-boundary-blocks-followthrough",world._is_floor(Vector2i(37,12)) and not world._is_floor(Vector2i(38,12)) and five.hits==1)
	for row in checks:
		if not row.passed: quit(1); return
	print("COREBREAKER_BURST_OK "+str(checks.size())); quit(0)
