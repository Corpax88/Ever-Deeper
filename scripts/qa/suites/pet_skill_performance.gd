extends "res://scripts/qa/suites/mobile_performance.gd"
## Isolated off/on/restored trials. Each trial: 60s idle + 45s exercised.
const Skills = preload("res://scripts/companion/mole_skills.gd")
var area: String = "hub"
var skill: String = "all"
var world: Node2D
var mole: Node2D
var commands: Array[Dictionary] = []
var events_done: int = 0
var exercise_point: Vector2 = Vector2(INF, INF)
var exercise_wall: Vector2 = Vector2(INF, INF)
var alternate_point: Vector2
var exercise_supported: bool = false
var job_start: int

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--perf-output="): output_dir = arg.get_slice("=",1)
		if arg.begins_with("--pet-area="): area = arg.get_slice("=",1)
		if arg.begins_with("--pet-skill="): skill = arg.get_slice("=",1)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var valid: Array[String] = ["all"]
	for entry in Skills.SKILLS: valid.append(String(entry.id))
	if skill not in valid or area not in ["hub","mossvein"]:
		fail("Unknown pet test selection"); return
	job_start = Time.get_ticks_usec()
	var trials: Array[Dictionary] = []
	for state in ["off","on","restored_off"]:
		if not await prepare_trial(state): return
		var initial: Dictionary = snapshot()
		var idle: Array[Dictionary] = await sample_phase("idle",12)
		prepare_exercise()
		var active: Array[Dictionary] = await sample_phase("active",9)
		if world.has_method("set_mine_held"): world.set_mine_held(false)
		trials.append({"state":state,"initial":initial,"final":snapshot(),"idle":idle,"active":active,
			"exercise_supported":exercise_supported,"commands":commands.duplicate(true)})
		if state=="on" and area=="mossvein" and skill in ["shake","teamwork"] and mole.dug_total<=int(initial.dug):
			fail("Pet digging was not exercised"); return
		print("PET_TRIAL_DONE " + JSON.stringify({"area":area,"skill":skill,"state":state,"final":snapshot()}))
	var report: Dictionary = {"area":area,"skill":skill,"trials":trials,
		"rendered":DisplayServer.get_name()!="headless","renderer":RenderingServer.get_video_adapter_name(),
		"physical_iphone":false,"viewport":"844x390 native; software renderer",
		"elapsed_seconds":float(Time.get_ticks_usec()-job_start)/1000000.0,
		"design":"All other skills learned; target off/on/restored-off. All means every skill toggled together.",
		"core_skill_control":"Lantern off hides only pet lamp; Fetch off skips only automatic fetch decisions. These core skills have no real off switch.",
		"save":"Disposable per-trial save; normal checkpoint/autosave enabled; Dummy audio.",
		"profile":"Pet physics, think, path, loot and ore scan microseconds; QA-only instrumentation."}
	FileAccess.open(output_dir.path_join("result.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PET_SKILL_PERFORMANCE_COMPLETE area=%s skill=%s" % [area,skill])
	main.get_tree().quit(0)

func prepare_trial(state: String) -> bool:
	seed(4608)
	RunState.reset_run(false)
	RunState.world_seed = 4608
	RunState.initialize_persistence(output_dir.path_join(state+"-save.json"))
	main.persistence_active = true
	main.game_started = true
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state(): fail("Workshop fixture failed"); return false
	for workshop_id in ["light_lab","wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop_id).next_upgrade
			RunState.add_resource(String(upgrade.resource),int(upgrade.cost),false)
			if not bool(RunState.upgrade_workshop(workshop_id).get("ok",false)):
				fail("Workshop upgrade failed"); return false
	var learned: Dictionary = {}
	for entry in Skills.SKILLS:
		var enabled: bool = state=="on" if skill=="all" else (String(entry.id)!=skill or state=="on")
		learned[String(entry.id)] = 1 if enabled else 0
	RunState.overhaul_progress["skills"] = learned
	var entered: bool = main._dev_jump_hub() if area=="hub" else main._dev_jump_mine("mossMine",2)
	if not entered: fail("Area fixture failed"); return false
	world = main.hub_world if area=="hub" else main.depth_world
	if area=="hub": world.restore_position(Vector2(1200,480))
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	for frame in 3: await main.get_tree().process_frame
	mole = world.get_node_or_null("MoleCompanion")
	if mole==null: fail("Pet missing"); return false
	mole._spawn_beside_hero()
	mole.set_meta("qa_fetch_disabled",int(learned.fetch)==0)
	mole.lamp.visible = int(learned.lantern)==1
	mole._think()
	# Warm-up uses wall clock; reports separately track simulated pet seconds.
	var deadline: int = Time.get_ticks_msec()+2000
	while Time.get_ticks_msec()<deadline: await main.get_tree().process_frame
	commands.clear()
	events_done=0
	if DisplayServer.get_name()!="headless":
		main.get_window().size = Vector2i(844,390)
		await main.get_tree().process_frame
		await RenderingServer.frame_post_draw
		var shot: Image = main.get_window().get_texture().get_image()
		if shot.get_size()!=Vector2i(844,390): fail("Unexpected render dimensions"); return false
		shot.save_png(output_dir.path_join(state+".png"))
	return true

func sample_phase(phase: String, buckets: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var phase_start: int = Time.get_ticks_usec()
	for bucket in buckets:
		var intervals: Array[float] = []
		var before: Dictionary = mole.qa_stats.duplicate()
		mole.qa_stats.physics_max_usec=0
		mole.qa_stats.path_max_usec=0
		var sim_start: float = mole.qa_sim_seconds
		var begin: int = Time.get_ticks_usec()
		var previous: int = begin
		while Time.get_ticks_usec()-begin<5000000:
			if phase=="active": exercise_tick(float(Time.get_ticks_usec()-phase_start)/1000000.0)
			await main.get_tree().process_frame
			var now: int = Time.get_ticks_usec()
			intervals.append(float(now-previous)/1000.0)
			previous=now
		var row: Dictionary = _journey_performance_frame_stats(intervals)
		var profile: Dictionary = {}
		for key in mole.qa_stats:
			profile[key] = mole.qa_stats[key] if String(key).ends_with("max_usec") else mole.qa_stats[key]-before[key]
		row.merge({"phase":phase,"bucket":bucket,"start_seconds":float(begin-phase_start)/1000000.0,
			"end_seconds":float(Time.get_ticks_usec()-phase_start)/1000000.0,
			"sim_seconds":mole.qa_sim_seconds-sim_start,"profile":profile,
			"process_monitor_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,
			"physics_monitor_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,
			"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"objects":Performance.get_monitor(Performance.OBJECT_COUNT),
			"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"static_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,
			"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,
			"pet":snapshot()})
		result.append(row)
	return result

func snapshot() -> Dictionary:
	return {"mode":mole.mode,"action":mole.action,"position":str(mole.global_position),
		"collected":mole.collected_total,"dug":mole.dug_total,"route_nodes":mole.route.size(),
		"failed_loot":mole.failed_loot.size(),"guide":mole.guide_kind,
		"beam_length":mole.lamp.base_beam_length,"lamp_visible":mole.lamp.is_visible_in_tree(),
		"fetch_enabled":not bool(mole.get_meta("qa_fetch_disabled",false)),
		"skills":Dictionary(RunState.overhaul_progress.skills).duplicate()}

func open_point() -> Vector2:
	var origin: Vector2 = world.player.global_position
	for distance in [300.0,240.0,180.0,120.0]:
		for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			var point: Vector2 = origin+direction*distance
			if not mole._blocked(point) and mole._segment_clear(origin,point): return point
	return Vector2(INF,INF)

func dig_target() -> Vector2:
	if not world.has_method("companion_can_dig"): return Vector2(INF,INF)
	var center: Vector2i = world._world_to_cell(world.player.global_position)
	for radius in range(1,10):
		for y in range(-radius,radius+1):
			for x in range(-radius,radius+1):
				var point: Vector2 = world._cell_center(center+Vector2i(x,y))
				if world.companion_can_dig(point) and is_finite(mole._nearby_floor(point).x): return point
	return Vector2(INF,INF)

func prepare_exercise() -> void:
	exercise_point=open_point()
	alternate_point=world.player.global_position
	exercise_wall=Vector2(INF,INF)
	exercise_supported=true
	if skill in ["shake","teamwork","all"]:
		exercise_wall=dig_target()
		if is_finite(exercise_wall.x):
			var floor_point: Vector2 = mole._nearby_floor(exercise_wall)
			for direction in ([Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN] if skill=="teamwork" else []):
				var candidate: Vector2 = exercise_wall+direction*52.0
				if not mole._blocked(candidate):
					floor_point=candidate
					break
			world.restore_position(floor_point)
			world.player.facing_vector=(exercise_wall-floor_point).normalized()
			mole._spawn_beside_hero()
		elif skill!="all": exercise_supported=false
	if skill in ["fetch","big_paws"]:
		exercise_supported=world.has_method("_spawn_drop") and is_finite(exercise_point.x)
	if skill in ["echo","homeward","ore_nose"]:
		exercise_supported=area=="mossvein"
	if skill in ["homeward","echo"] and is_finite(exercise_point.x):
		world.restore_position(exercise_point)
		mole._spawn_beside_hero()
	events_done=0

func exercise_tick(elapsed: float) -> void:
	var repeat: bool = skill in ["trailrunner","shake","all"]
	var due: int = mini(4,int(elapsed/10.0)) if repeat else 0
	if events_done>due: return
	var event: int = events_done
	events_done+=1
	var action_id: String = skill
	if skill=="all": action_id=["fetch","shake","ore_nose","echo","homeward"][event]
	var ok: bool = false
	match action_id:
		"lantern","long_beam","trailrunner":
			if is_finite(exercise_point.x): ok=mole.command(exercise_point if event%2==0 else alternate_point)
		"fetch","big_paws":
			if world.has_method("_spawn_drop") and is_finite(exercise_point.x):
				for i in 24:
					var point: Vector2 = exercise_point+Vector2((i%5-2)*12,(i/5-2)*12)
					if not mole._blocked(point): world._spawn_drop(point,"deepstone",1)
				ok=true
		"ore_nose":
			if area=="mossvein": prepare_ore_fixture()
			ok=mole.scout(action_id)
		"echo","homeward": ok=mole.scout(action_id)
		"shake": ok=mole.shake_nearby()
		"teamwork":
			if exercise_supported:
				world.set_mine_held(true)
				# Keep the player swing pending so the pet can land its own assist.
				world.swing_active=true
				world.swing_elapsed=0.0
				world.swing_duration=1000.0
				world.swing_hit=false
				mole.global_position=world.player.global_position
				mole.assist_cooldown=0.0
				mole._think()
				ok=world.companion_can_dig(world.player.global_position+world.player.facing_vector*52.0)
	commands.append({"at_seconds":elapsed,"command":action_id,"accepted":ok})

func prepare_ore_fixture() -> void:
	# Expose one real, ungated deposit in a disposable 7x7 chamber.
	for rock in world.rocks:
		if bool(rock.broken) or bool(rock.drill_gated) or not String(rock.cavern_id).is_empty(): continue
		var center: Vector2i = rock.cell
		for y in range(-3,4):
			for x in range(-3,4):
				var cell: Vector2i = center+Vector2i(x,y)
				var index: int = world._cell_index(cell)
				if index<0 or index>=world.terrain_hp.size(): continue
				world.terrain_hp[index]=0
				world.dug_indices[index]=true
		world.restore_position(Vector2(rock.position)+Vector2(0,100))
		mole._spawn_beside_hero()
		world.target_dirty=true
		world._request_redraw()
		return
