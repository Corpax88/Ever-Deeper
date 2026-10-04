extends SceneTree
## Independent actual-deposit disk-fault and adversarial save-identity review.
const Terrain=preload("res://scripts/state/endless_terrain_state.gd")
const Seams=preload("res://scripts/state/treasury_seams.gd")
var checks: Array=[]
var output: String

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("TREASURY_SEAM_INTEGRITY_MISMATCH ",label)

func run() -> void:
	if OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Set XDG_DATA_HOME to a disposable directory")
		quit(2)
		return
	output=OS.get_environment("MODS_OUT")
	if output.is_empty(): output="user://quality-seam-integrity"
	output=ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	var main: Node=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 5: await process_frame
	var state: Node=root.get_node("RunState")
	var path: String=output.path_join("real-deposit.sav")
	state.initialize_persistence(path)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_grant_max_tools_state()
	state.world_seed=77411
	state.endless_chunks={}
	state.endless_treasury_seam_start_depth=1
	state.treasury_goals={"pinned":"phasecrystal"}
	state.treasury_totals={}
	state.cargo=state._empty_resource_store()
	state.deep_events={}
	main._dev_jump_endless(1)
	var world: Node=main.endless_world
	main.set_process(false)
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.control_enabled=false
	main.get_node("MinerTraining").set_physics_process(false)
	state.starforge_variant="prospector"
	state.miner_skills=state.MinerSkills.defaults()
	state._miner_level_cache.clear()
	var index: int=-1
	for i in world.resources.size():
		if bool(world.resources[i].get("treasury_seam",false)) and int(world.resources[i].depth)==1:
			index=i
			break
	check("actual pinned phase-crystal deposit exists",index>=0)
	if index<0: finish(); return
	var ore: Dictionary=world.resources[index]
	var cell: Vector2i=Vector2i(ore.cell)
	var descriptor: Dictionary=state.endless_chunks["1"].treasury_seam.duplicate(true)
	check("descriptor committed before any extraction",state.flush_save())
	var primary: PackedByteArray=FileAccess.get_file_as_bytes(path)
	var backup: PackedByteArray=FileAccess.get_file_as_bytes(path+".bak")
	check("actual covering rock excavates",world._break_diggable_cell(cell))
	state.miner_skills.prospecting=state.MinerSkills.max_xp("prospecting")
	state._miner_level_cache.clear()
	# Fix only the test's next real Prospecting sample; no synthetic reward edit.
	for random_seed in 100:
		seed(random_seed)
		if randf()<0.5:
			seed(random_seed)
			break
	world._strike_resource(index,100000,false)
	var id: String="n%d" % int(ore.node_index)
	var amount: int=int(ore.amount)*2+1
	check("real Crown extraction includes one actual Prospecting bonus",state.endless_loose_drops(1).get(id,{}).get("amount",0)==amount and state.cargo.phasecrystal==0)
	var committed_drop: Dictionary=state.endless_chunks["1"].duplicate(true)
	check("real write obstruction created",DirAccess.make_dir_absolute(path+".tmp")==OK)
	check("deposit save failure is reported and remains dirty",not state.flush_save() and state.last_save_error!=OK and state._autosave_pending)
	check("failed extraction checkpoint preserves both disk generations",FileAccess.get_file_as_bytes(path)==primary and FileAccess.get_file_as_bytes(path+".bak")==backup)
	state.treasury_goals={"pinned":"rootiron","ricochet_claimed":true}
	world._generate_stream_window(1)
	check("failed-write retry window keeps same descriptor and one pending deposit",state.endless_chunks["1"].treasury_seam==descriptor and state.endless_loose_drops(1).get(id,{}).get("amount",0)==amount and state.cargo.phasecrystal==0)
	check("real write obstruction removed",DirAccess.remove_absolute(path+".tmp")==OK)
	await create_timer(state.AUTOSAVE_BATCH_SECONDS+0.4,true,false,true).timeout
	check("automatic retry commits without another mining action",state.last_save_error==OK and not state._autosave_pending and FileAccess.get_file_as_bytes(path)!=primary)
	check("actual disk reload retains pending drop and old selection identity",state.load_game(path) and state.endless_chunks["1"].treasury_seam==descriptor and state.endless_loose_drops(1).get(id,{}).get("amount",0)==amount)
	world._generate_stream_window(1)
	world.player.global_position=world._cell_center(cell)
	world._update_loose_drops(0.6)
	check("actual pickup after repin and claim credits exact saved amount once",state.cargo.phasecrystal==amount and not state.endless_loose_drops(1).has(id))
	check("duplicate delivery cannot credit another amount",state.collect_endless_drop(1,id).is_empty() and state.cargo.phasecrystal==amount)
	check("collection checkpoint and reload retain depletion",state.flush_save() and state.load_game(path) and state.cargo.phasecrystal==amount and not state.endless_loose_drops(1).has(id))
	world._generate_stream_window(1)
	var retained: Dictionary={}
	for resource in world.resources:
		if String(resource.id)==String(ore.id): retained=resource
	check("same authored node remains depleted after second reload",not retained.is_empty() and retained.mined and retained.kind=="phasecrystal" and retained.cell==cell)
	for alias in ["n024","n+24","n24 ","n-24"]:
		var bad: Dictionary=committed_drop.duplicate(true)
		bad.drops={alias:committed_drop.drops[id]}
		check("noncanonical drop key rejected "+alias,Terrain.sanitize({"1":bad},1000,state.world_seed)["1"].drops.is_empty())
	for change in [{"revision":true},{"revision":NAN},{"cells":[INF,451,731]},{"cells":[171,451,880]},{"cells":[171,451,171]}]:
		var bad: Dictionary=committed_drop.duplicate(true)
		bad.treasury_seam.merge(change,true)
		var cleaned: Dictionary=Terrain.sanitize({"1":bad},1000,state.world_seed)["1"]
		var ordinary_drops: Dictionary=committed_drop.drops.duplicate(true)
		ordinary_drops.erase(id)
		check("malformed descriptor rejects only its deposit and retains ordinary loot "+str(change),cleaned.has("treasury_seam") and cleaned.treasury_seam.is_empty() and cleaned.drops==ordinary_drops)
	var old_journal: Dictionary={"dug":"000f","nodes":65535,"sites":3,"seen":2,"drops":{"n16":{"kind":"deep_alloy","amount":27,"cell":14},"c15":{"kind":"stone","amount":3,"cell":15}}}
	var legacy: Dictionary=state.serialize()
	legacy.state.endless_descent.erase("treasury_seam_start_depth")
	legacy.state.endless_descent.current_depth=12
	legacy.state.endless_descent.deepest_depth=12
	legacy.state.endless_descent.chunks={"13":old_journal}
	check("legacy future preloaded journal restores byte-equivalent authority",state.deserialize(legacy) and state.endless_chunks["13"]==old_journal)
	state.treasury_goals={"pinned":"rootiron"}
	check("legacy preloaded journal cannot be overwritten by new binding",state.bind_endless_treasury_seam(13,[[171],[451],[731]]).is_empty() and state.endless_chunks["13"]==old_journal)
	check("legacy reached unjournaled band cannot receive retrofit",state.endless_treasury_seam_start_depth==13 and state.bind_endless_treasury_seam(12,[[171],[451],[731]]).is_empty())
	finish()

func finish() -> void:
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"\t"))
	print("TREASURY_SEAM_INTEGRITY_OK "+str(checks.size()) if passed else "TREASURY_SEAM_INTEGRITY_FAILED")
	quit(0 if passed else 2)
