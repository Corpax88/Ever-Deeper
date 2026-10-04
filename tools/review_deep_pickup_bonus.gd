extends SceneTree
## Real loose-drop flight/collection at the base and earned chamber radii.
var main: Node
var world: Node
var state: Node
var checks: Array = []
var output: String

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("DEEP_PICKUP_MISMATCH "+label)

func chamber(enabled: bool) -> void:
	state.endless_relics.echo_coffer.placed = true
	state.endless_workshops.treasure_chamber.built = enabled
	state.endless_workshops.treasure_chamber.level = 1 if enabled else 0

func drop_at(cell: Vector2i) -> String:
	world._clear_loose_drop_visuals()
	var chunk: Dictionary = state._endless_chunk(1)
	chunk.drops = {}
	state.endless_chunks["1"] = chunk
	var index: int = cell.y*world.DeepLayout.CHUNK_COLS+cell.x
	var id: String = "c"+str(index)
	state._register_endless_drop(1,id,index,"deep_alloy",7)
	world._sync_loose_drops()
	var key: String = "1:"+id
	world.loose_drops[key].age = 1.0
	return key

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-pickup-bonus"
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
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.global_position = world._cell_center(Vector2i(18,12))
	world.player.control_enabled = true
	world.drill_modes.reset()
	world.drill_modes.five.reset()
	world._ground_props.clear()
	world.resources.clear()
	for y in range(10,15):
		for x in range(15,28): world._set_floor(Vector2i(x,y),true)
	var mole: Node = main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled = false
	mole.recall()

	chamber(false)
	check("existing-base-radii-preserved",world.loose_drop_pickup_radius()==140.0 and world.loose_drop_pickup_radius(256.0)==256.0)
	var key: String = drop_at(Vector2i(21,12))
	var origin: Vector2 = world.loose_drops[key].visual.position
	world._update_loose_drops(0.1)
	check("base-pickup-does-not-reach-192px",world.loose_drops[key].visual.position==origin)
	chamber(true)
	check("earned-chamber-applies-on-top-of-each-base",world.loose_drop_pickup_radius()==212.0 and world.loose_drop_pickup_radius(256.0)==328.0)
	world._update_loose_drops(0.1)
	check("chamber-attracts-real-drop-beyond-base",world.loose_drops[key].visual.position.distance_to(world.player.global_position)<192.0)
	var cargo_before: int = state.cargo.deep_alloy
	for _step in 20: world._update_loose_drops(0.1)
	check("upgraded-pickup-collects-exactly-once",int(state.cargo.deep_alloy)==cargo_before+7 and not world.loose_drops.has(key))

	key = drop_at(Vector2i(21,12))
	origin = world.loose_drops[key].visual.position
	world._set_floor(Vector2i(20,12),false)
	world._update_loose_drops(0.1)
	check("earned-radius-cannot-collect-through-rock",world.loose_drops[key].visual.position==origin)
	world._set_floor(Vector2i(20,12),true)

	world.drill_modes.five.mode = "vortex"
	chamber(false)
	key = drop_at(Vector2i(23,12))
	origin = world.loose_drops[key].visual.position
	world.drill_modes.five.collect_vortex(0.1)
	check("base-vortex-does-not-reach-320px",world.loose_drops[key].visual.position==origin)
	chamber(true)
	world.drill_modes.five.collect_vortex(0.1)
	check("vortex-keeps-earned-chamber-bonus",world.loose_drops[key].visual.position.distance_to(world.player.global_position)<320.0)
	cargo_before = state.cargo.deep_alloy
	for _step in 30: world.drill_modes.five.collect_vortex(0.05)
	check("upgraded-vortex-collects-exactly-once",int(state.cargo.deep_alloy)==cargo_before+7 and not world.loose_drops.has(key))
	key = drop_at(Vector2i(23,12))
	origin = world.loose_drops[key].visual.position
	world._set_floor(Vector2i(20,12),false)
	world.drill_modes.five.collect_vortex(0.1)
	check("vortex-bonus-cannot-collect-through-rock",world.loose_drops[key].visual.position==origin)
	for row in checks:
		if not row.passed:
			quit(1)
			return
	print("DEEP_PICKUP_BONUS_OK "+str(checks.size()))
	quit(0)
