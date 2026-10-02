extends SceneTree
## Focused production-code checks; isolated save, no rendering/FPS claim.
var main: Node
var world: Node
var state: Node
var five: Node
var checks: Array = []
var output: String
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: push_error("FIVE_MECHANICS_FAIL " + label)
func node_at(id: String, cell: Vector2i, hp: int = 1022) -> Dictionary:
	return {"id":id,"cell":cell,"position":world._cell_center(cell),"hp":hp,"max_hp":hp,"mined":false,"kind":"rootiron","amount":1,"depth":1,"node_index":0}
func fresh() -> void:
	five.reset(); five.hit_log.clear(); five.hits = 0
	world.resources.clear(); world._clear_loose_drop_visuals()
	world.player.global_position = world._cell_center(Vector2i(18,12))
	world.player.set_facing(Vector2.RIGHT)
	for y in range(2,27):
		for x in range(3,37): world._set_floor(Vector2i(x,y),true)
func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/five-mechanics"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate(); root.add_child(main); current_scene = main
	for i in 5: await process_frame
	state = root.get_node("RunState"); state.initialize_persistence(output.path_join("isolated-save.json")); state.reset_run(false)
	main._dev_ensure_playing(); main._dev_seed_victory_state(); main._dev_jump_endless(1)
	world = main.endless_world; five = world.drill_modes.five
	world.set_process(false); world.player.set_physics_process(false); world.resonance_drill.set_enabled(false)
	var mole: Node = main.get_node("CompanionInterface").active_mole(); mole.autonomous_enabled = false; mole.recall()
	world._ground_props.clear(); world.discovery_sites.clear()
	state.drill_level = 1; state.starforge_variant = ""
	fresh()
	world.player.camera.reset_smoothing(); world.player.camera.force_update_scroll()
	for i in 3: await process_frame
	var view: Rect2 = world.get_viewport_rect()
	var transform: Transform2D = world.get_viewport().get_canvas_transform()
	for y in range(9,16):
		for x in range(14,23):
			var cell: Vector2i = Vector2i(x,y)
			if view.has_point(transform * world._cell_center(cell)): world.resources.append(node_at("chain"+str(world.resources.size()),cell))
	var expected: int = world.resources.size()
	check("chain-fixture-exceeds-three",expected > 3)
	world.resources.append(node_at("buried",Vector2i(24,12))); world._set_floor(Vector2i(24,12),false)
	world.resources.append(node_at("offscreen",Vector2i(35,25)))
	five.mode = "chainbreaker"; five._start_chain(0); five._hit_node(0,"direct")
	world.player.global_position += Vector2(128,0)
	for i in expected + 4: five._update_chain(0.1)
	var ids: Dictionary = {}
	for hit in five.hit_log: ids[String(hit.id)] = true
	check("chain-all-snapshot-nodes-after-motion",ids.size() == expected and five.chain.is_empty())
	check("chain-excludes-buried-and-offscreen",not ids.has("buried") and not ids.has("offscreen"))
	for hp in [950,974,998,1022]:
		fresh(); five.mode = "corebreaker"; five.charge = 3.0
		world.resources.append(node_at("core",Vector2i(19,12),hp))
		var period: float = world._mining_cycle_duration()
		five._impact({"node":0},period)
		for i in 8: five._update_core(period/10.0)
		check("core-three-hits-before-next-ordinary-hit-"+str(hp),five.hit_log.size() == 3)
	fresh(); five.mode = "twin_auger"; five.direction = Vector2.RIGHT
	var wall: Vector2i = Vector2i(19,12)
	world._set_floor(wall,false); world.resources.append(node_at("buried-twin",wall))
	for i in 8: five._impact({"cell":wall,"point":world._cell_center(wall)},0.08)
	check("twin-reveals-without-mining-node",world._is_floor(wall) and int(world.resources[0].hp) == 1022)
	fresh(); state.endless_chunks.clear(); five.mode = "vortex"
	var before: int = int(state.cargo.get("rootiron",0))
	for i in 40: state._register_endless_drop(1,"vortex-"+str(i),world._chunk_cell_index(Vector2i(19,12)),"rootiron",2)
	world._sync_loose_drops()
	for i in 7: five.collect_vortex(0.016)
	check("vortex-bounded-work",five.scanned_last <= 32 and five.flights.size() <= 12)
	five.reset()
	check("vortex-reset-preserves-uncollected-ledger",state.endless_loose_drops(1).size()*2 + int(state.cargo.get("rootiron",0))-before == 80)
	five.mode = "vortex"
	for i in 300: five.collect_vortex(0.016)
	check("vortex-exact-once-loot",state.endless_loose_drops(1).is_empty() and int(state.cargo.get("rootiron",0))-before == 80 and world.loose_drops.is_empty())
	FileAccess.open(output.path_join("mechanics.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	for result in checks:
		if not bool(result.passed): quit(1); return
	print("FIVE_MECHANICS_OK "+str(checks.size())); quit(0)
