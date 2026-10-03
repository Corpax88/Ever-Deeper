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
	world.resources.clear(); world.dig_damage.clear(); world._clear_loose_drop_visuals()
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
	five.hit_log.clear(); five._start_chain(0)
	var pending: Array = five.chain.duplicate()
	var old_from: Vector2 = five.chain_from
	var shift: Vector2 = Vector2(0,world.TILE_SIZE)
	five.rebase(shift)
	for ore in world.resources:
		ore.position = Vector2(ore.position)+shift
		ore.cell = Vector2i(ore.cell)+Vector2i(0,1)
	check("chain-rebase-preserves-snapshot-and-shifts-origin",five.chain == pending and five.chain_from.is_equal_approx(old_from+shift))
	for i in expected+4: five._update_chain(0.1)
	check("chain-continues-after-coordinate-rebase",five.hit_log.size() == pending.filter(func(item): return item is String).size())
	five._start_chain(0); five.held_last = true
	five.tick(0.016,"chainbreaker",false)
	var cancelled_hits: int = five.hits
	five._update_chain(1.0)
	check("chain-release-cancels-pending-without-extra-hit",five.chain.is_empty() and five.hits == cancelled_hits)
	# Mixed chain: ordinary rock starts it and visible front tiles break once.
	fresh(); five.mode = "chainbreaker"
	var rock_cells: Array[Vector2i] = [Vector2i(19,12),Vector2i(20,10),Vector2i(21,11),Vector2i(21,13),Vector2i(20,14)]
	for cell in rock_cells:
		world._set_floor(cell,false); world.dig_damage[cell]=519
	world.resources.append(node_at("hidden-under-chain-rock",rock_cells[2]))
	world.resources.append(node_at("exposed-mixed",Vector2i(17,11)))
	var far: Vector2i = Vector2i(35,25)
	world._set_floor(far,false); world.dig_damage[far]=519
	var deep_rock: Vector2i = Vector2i(24,12)
	for y in range(11,14):
		for x in range(23,26): world._set_floor(Vector2i(x,y),false)
	world.player.camera.reset_smoothing();world.player.camera.force_update_scroll()
	for i in 3: await process_frame
	five._impact({"cell":rock_cells[0],"point":world._cell_center(rock_cells[0])},0.08)
	check("rock-hit-starts-mixed-chain",not five.chain.is_empty() and five.chain.has("exposed-mixed"))
	check("rock-queue-excludes-first-offscreen-and-interior",not five.chain.has(world.absolute_cell(rock_cells[0])) and not five.chain.has(world.absolute_cell(far)) and not five.chain.has(world.absolute_cell(deep_rock)))
	check("buried-ore-excluded-before-wall-break",not five.chain.has("hidden-under-chain-rock"))
	var queued: int = five.chain.size()
	for i in queued+2: five._update_chain(0.1)
	var broken: bool = true
	for cell in rock_cells: broken = broken and world._is_floor(cell)
	check("chain-breaks-all-visible-rock-fixture",broken)
	check("mixed-chain-hits-exposed-ore",int(world.resources[1].hp)<1022)
	check("chain-reveals-ore-at-full-hp",world._is_floor(Vector2i(world.resources[0].cell)) and int(world.resources[0].hp)==1022)
	check("offscreen-and-interior-rock-not-hit",not world._is_floor(far) and not world.dig_damage.has(deep_rock))
	var hit_count: int = five.hits
	for i in 5: five._update_chain(0.1)
	check("completed-chain-has-no-repeat-hits",five.hits==hit_count and five.chain.is_empty())
	five._start_chain(1)
	check("later-attack-can-select-newly-exposed-ore",five.chain.has("hidden-under-chain-rock"))
	five.held_last=true;five.tick(0.016,"chainbreaker",false)
	check("release-clears-mixed-chain",five.chain.is_empty())
	fresh(); five.mode="chainbreaker"
	for cell in rock_cells: world._set_floor(cell,false)
	five._start_chain_at(world._cell_center(rock_cells[0]),"",world.absolute_cell(rock_cells[0]))
	var absolute_targets: Array = five.chain.duplicate()
	five.rebase(Vector2(0,-world.TILE_SIZE*world.DeepLayout.CHUNK_ROWS))
	check("rock-queue-uses-stable-absolute-cells",five.chain==absolute_targets and absolute_targets.size()>0)
	five.held_last=true; five.tick(0.016,"ricochet",true)
	check("mod-switch-clears-rock-chain",five.chain.is_empty())
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
	fresh(); five.mode = "ricochet"
	for cell in [Vector2i(20,11),Vector2i(20,12),Vector2i(20,13)]:
		world._set_floor(cell,false)
		# Pre-damaged ordinary rock breaks on one real drill strike.
		world.dig_damage[cell] = 519
		world.resources.append(node_at("ricochet-buried-"+str(cell),cell))
	five._launch(Vector2i(20,12))
	for i in 80: five._update_projectile(0.01)
	check("ricochet-three-distinct-rock-contacts",five.hits == 3 and five.projectile.is_empty())
	var revealed: int = 0
	var intact: bool = true
	for ore in world.resources:
		if world._is_floor(Vector2i(ore.cell)): revealed += 1
		intact = intact and int(ore.hp) == 1022
	check("ricochet-reveals-three-without-mining-buried-nodes",revealed == 3 and intact)
	fresh(); state.endless_chunks.clear(); five.mode = "vortex"
	var before: int = int(state.cargo.get("deep_alloy",0))
	for i in 40: state._register_endless_drop(1,"c"+str(i),world._chunk_cell_index(Vector2i(19,12)),"deep_alloy",2)
	world._sync_loose_drops()
	for i in 7: five.collect_vortex(0.016)
	check("vortex-bounded-work",five.scanned_last <= 32 and five.flights.size() <= 12)
	check("vortex-save-during-flight",state.save_game(output.path_join("in-flight.json")))
	world._clear_loose_drop_visuals()
	check("vortex-load-during-flight",state.load_game(output.path_join("in-flight.json")))
	world._sync_loose_drops()
	check("vortex-reload-preserves-ledger",state.endless_loose_drops(1).size()*2 + int(state.cargo.get("deep_alloy",0))-before == 80)
	five.reset()
	check("vortex-reset-preserves-uncollected-ledger",state.endless_loose_drops(1).size()*2 + int(state.cargo.get("deep_alloy",0))-before == 80)
	five.mode = "vortex"
	for i in 300: five.collect_vortex(0.016)
	check("vortex-exact-once-loot",state.endless_loose_drops(1).is_empty() and int(state.cargo.get("deep_alloy",0))-before == 80 and world.loose_drops.is_empty())
	# Compare actual controller physics to ordinary walking, with active mining.
	# 24 bearings are grouped into one meaningful result per mode/speed level.
	fresh(); world.player.control_enabled = true
	for level in [0,3,10,20]:
		state.set_movement_speed_level(level)
		world.player.movement_speed = float(root.get_node("GameData").data.PLAYER_SPEED)*state.movement_speed_multiplier()
		for mod in five.IDS:
			var identical: bool = true
			for bearing in 24:
				var direction: Vector2 = Vector2.RIGHT.rotated(float(bearing)*TAU/24.0)
				var start: Vector2 = world._cell_center(Vector2i(18,12))
				world.resources.clear(); world.set_mine_held(false); world.drill_modes.dev_override = ""; world.drill_modes.reset()
				world.player.global_position = start; world.player.external_movement = direction
				for step in 6: world.player._physics_process(1.0/60.0)
				var baseline: Vector2 = world.player.global_position-start
				world.player.global_position = start; world.player.set_facing(direction)
				var ore: Dictionary = node_at("motion",world._world_to_cell(start+direction*90.0))
				ore.position = start+direction*90.0; world.resources.append(ore)
				world.drill_modes.dev_override = mod; world.set_mine_held(true)
				for step in 6:
					world.drill_modes.tick(1.0/60.0); world.player._physics_process(1.0/60.0)
				identical = identical and (world.player.global_position-start).distance_to(baseline)<0.01 and baseline.length()>0.0
			check("controller-motion-parity-24-bearings-"+mod+"-level-"+str(level),identical)
	world.player.external_movement = Vector2.ZERO; world.set_mine_held(false)
	FileAccess.open(output.path_join("mechanics.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	for result in checks:
		if not bool(result.passed): quit(1); return
	print("CHAINBREAKER_ROCK_OK "+str(checks.size())); quit(0)
