extends SceneTree
## Deterministic oracle route. Measures real movement/mining/pickup game time,
## not human search, enjoyment, device FPS or a complete 100k donation session.
var main: Node
var world: Node
var state: Node
var training: Node
var output: String
var results: Array = []
var full_hunt: bool = false
const STEP: float = 1.0 / 60.0
const SAMPLE_DEPOSITS: int = 18

func _initialize() -> void: run.call_deferred()

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-treasury-rate"
	DirAccess.make_dir_recursive_absolute(output)
	full_hunt = OS.get_environment("HUNT_FULL") == "1"
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated.sav"))
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
	var mole: Node = main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled = false
	mole.recall()
	mole.set_process(false)
	mole.set_physics_process(false)
	for config in [{"variant":"prospector","mod":""},{"variant":"crusher","mod":""},{"variant":"swift","mod":"corebreaker"}]:
		if not OS.get_environment("HUNT_VARIANT").is_empty() and String(config.variant) != OS.get_environment("HUNT_VARIANT"): continue
		await measure(config)
	FileAccess.open(output.path_join("rate.json"),FileAccess.WRITE).store_string(JSON.stringify({"method":"100k known-deposit route" if full_hunt else "18 known deposits", "simulation":"fixed-step real player collision, tool cadence, stamina and loose pickup; no teleport or pre-excavation; human search and donation excluded","results":results},"\t"))
	var passed: bool = true
	for result in results: passed = passed and (result.units >= 100000 if full_hunt else result.completed_deposits == SAMPLE_DEPOSITS)
	print("TREASURY_HUNT_RATE_OK" if passed else "TREASURY_HUNT_RATE_INCOMPLETE")
	quit(0 if passed else 1)

func measure(config: Dictionary) -> void:
	state.world_seed = 77411
	state.endless_chunks = {}
	state.endless_stream_anchor = {}
	state.endless_treasury_seam_start_depth = 1
	state.endless_current_depth = 1
	state.endless_deepest_depth = 1
	state.endless_descent_active = true
	state.treasury_goals = {"pinned":"rootiron"}
	if not String(config.mod).is_empty():
		state.treasury_goals[String(config.mod)+"_claimed"] = true
		state.treasury_goals[String(config.mod)+"_enabled"] = true
	state.treasury_totals = {}
	state.cargo = state._empty_resource_store()
	state.deep_events = {}
	state.starforge_variant = String(config.variant)
	state.endless_relics.forge_heart = {"discovered":true,"collected":true,"placed":true,"found_depth":1}
	state.endless_workshops.tool_forge.built = true
	state.endless_workshops.tool_forge.level = 5
	state.endless_relics.echo_coffer = {"discovered":true,"collected":true,"placed":true,"found_depth":8}
	state.endless_workshops.treasure_chamber.built = true
	state.endless_workshops.treasure_chamber.level = 1
	state.miner_skills = state.MinerSkills.defaults()
	for id in state.MinerSkills.IDS: state.miner_skills[id] = state.MinerSkills.threshold(id,25)
	state._miner_level_cache.clear()
	world.current_depth = 1
	world.resources.clear()
	world.session_mined_nodes.clear()
	world.session_discovered_sites.clear()
	world.drill_modes.dev_override = ""
	world.drill_modes.reset()
	world.resonance_drill.set_enabled(false)
	world._generate_stream_window(1)
	world._resume_position = Vector2(INF,INF)
	var entrance: Vector2i = Vector2i(world.DeepLayout.entrance_column(state.world_seed,1),2)
	world._configure_player(world._cell_center(entrance))
	world.player.control_enabled = true
	world.active = true
	world.set_mine_held(true)
	var completed: Dictionary = {}
	var target_id: String = ""
	var elapsed: float = 0.0
	var target_elapsed: float = 0.0
	var samples: Array = []
	var final_target: Dictionary = {}
	var path: Array[Vector2i] = []
	for step_index in 90000:
		var target: Dictionary = {}
		for ore in world.resources:
			if not bool(ore.get("treasury_seam",false)) or completed.has(String(ore.id)): continue
			if target_id.is_empty() or String(ore.id) == target_id:
				target = ore
				if target_id.is_empty(): path = route_to(Vector2i(ore.cell))
				target_id = String(ore.id)
				break
		if target.is_empty(): break
		var drop_id: String = "n%d" % int(target.node_index)
		if bool(target.mined) and not state.endless_loose_drops(int(target.depth)).has(drop_id):
			completed[target_id] = true
			samples.append({"deposit":target_id,"seconds":elapsed,"cargo":int(state.cargo.rootiron)})
			if (full_hunt and int(state.cargo.rootiron) >= 100000) or (not full_hunt and completed.size() >= SAMPLE_DEPOSITS): break
			target_id = ""
			target_elapsed = 0.0
			continue
		var offset: Vector2 = Vector2(target.position)-world.player.global_position
		while not path.is_empty() and world.player.global_position.distance_to(world._cell_center(path[0]-world.absolute_cell(Vector2i.ZERO))) < 7.0: path.pop_front()
		var destination: Vector2 = Vector2(target.position) if path.is_empty() else world._cell_center(path[0]-world.absolute_cell(Vector2i.ZERO))
		var steering: Vector2 = destination-world.player.global_position
		world.player.external_movement = steering.normalized() if steering.length() > 6.0 else Vector2.ZERO
		world.set_mine_held(not bool(target.mined))
		world.player.set_facing(steering.normalized())
		world.player.animation_bearing = steering.normalized()
		if not world.drill_modes.tick(STEP): world._update_mining(STEP)
		world.player._physics_process(STEP)
		world._update_loose_drops(STEP)
		training._physics_process(STEP)
		elapsed += STEP
		target_elapsed += STEP
		if target_elapsed > 120.0:
			var nearest: int = world._nearest_resource_index()
			final_target = {"id":target_id,"mined":target.mined,"hp":target.hp,"distance":offset.length(),"position":str(world.player.global_position),"target":str(target.position),"nearest_node":world.resources[nearest] if nearest >= 0 else {},"nearest_wall":str(world._nearest_diggable_wall()),"mining_active":world.mining_active,"mining_target":world.mining_target_id,"mining_elapsed":world.mining_elapsed,"actual_motion":str(world.player.animation_actual_motion),"tool":world._current_endless_tool(),"state_depth":state.endless_current_depth,"world_depth":world.current_depth,"direction":str(offset.normalized())}
			break
		if step_index % 600 == 0: await process_frame
	world.set_mine_held(false)
	world.player.external_movement = Vector2.ZERO
	var amount: int = int(state.cargo.rootiron)
	var result: Dictionary = {"variant":config.variant,"mod":config.mod,"seed":state.world_seed,"forge_level":state._built_workshop_level("tool_forge"),"initial_skill_levels":25,"player_base_speed":world.player.movement_speed,"full_hunt":full_hunt,"completed_deposits":completed.size(),"game_seconds":elapsed,"units":amount,"units_per_minute":float(amount)*60.0/maxf(elapsed,0.01),"extrapolated_100k_minutes":100000.0*elapsed/float(maxi(1,amount))/60.0,"depth":state.endless_current_depth,"final_stamina":state.stamina_value(),"samples":samples,"stalled_target":final_target}
	results.append(result)
	FileAccess.open(output.path_join("rate.json"),FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	print("TREASURY_RATE "+JSON.stringify({"variant":config.variant,"mod":config.mod,"seconds":elapsed,"units":amount,"completed":completed.size(),"stalled":final_target}))

func route_to(destination: Vector2i) -> Array[Vector2i]:
	# This solver knows the deposit locations. Cardinal centres avoid clipping
	# against diagonal ore/ruin bases; it still has to excavate and walk every step.
	var grid: AStarGrid2D = AStarGrid2D.new()
	grid.region = Rect2i(Vector2i.ZERO,world.GRID_SIZE)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	grid.update()
	var props: Array = []
	for group in world._ground_props.values():
		for prop in group:
			if int(prop.resource) < 0: props.append(prop)
	for y in world.GRID_SIZE.y:
		for x in world.GRID_SIZE.x:
			var cell: Vector2i = Vector2i(x,y)
			var solid: bool = not world._cell_diggable(cell)
			for prop in props:
				var local: Vector2 = (world._cell_center(cell)-Vector2(prop.center))/(Vector2(prop.radii)+Vector2.ONE*world.PLAYER_RADIUS)
				if local.length_squared() < 1.0: solid = true; break
			grid.set_point_solid(cell,solid)
			grid.set_point_weight_scale(cell,1.0 if world._is_floor(cell) else 1.5)
	var start: Vector2i = world._world_to_cell(world.player.global_position)
	grid.set_point_solid(start,false)
	var result: Array[Vector2i] = []
	for cell in grid.get_id_path(start,destination): result.append(world.absolute_cell(cell))
	if not result.is_empty(): result.pop_front()
	return result
