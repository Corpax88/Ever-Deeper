extends SceneTree
## Save authority and conservation; rendering/integration is a separate gate.
const Seams = preload("res://scripts/state/treasury_seams.gd")
const Terrain = preload("res://scripts/state/endless_terrain_state.gd")
var state: Node
var checks: Array = []
var output: String
var candidates: Array = [[171,172,173], [450,451,452], [730,731,732]]

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("TREASURY_SEAMS_MISMATCH " + label)

func fresh(kind: String = "rootiron") -> void:
	state.victory = true
	state.endless_descent_active = true
	state.endless_current_depth = 1
	state.endless_deepest_depth = 1
	state.endless_treasury_seam_start_depth = 1
	state.endless_chunks = {}
	state.world_seed = 77411
	state.treasury_goals = {"pinned":kind}
	state.treasury_totals = {}
	state.cargo = state._empty_resource_store()
	state.miner_skills = state.MinerSkills.defaults()
	state._miner_level_cache.clear()

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-treasury-seams"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated.sav"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main.set_process(false)

	seed(819)
	var expected_random: float = randf()
	seed(819)
	var deterministic: Dictionary = Seams.generate(77411,1,"rootiron",candidates)
	check("generator-never-consumes-global-rng",randf() == expected_random)
	check("generator-stable-despite-candidate-enumeration",deterministic == Seams.generate(77411,1,"rootiron",[[173,171,172],[452,451,450],[731,732,730]]))
	check("fewer-valid-placements-keep-exact-slot-identity",Seams.generate(77411,1,"rootiron",[[],[451],[]]).cells == [-1,451,-1])
	var kinds_valid: bool = true
	for kind in Seams.MOD_BY_KIND:
		var seam: Dictionary = Seams.generate(77411,1,kind,candidates)
		for index in range(24,27):
			var deposit: Dictionary = Seams.deposit(seam,77411,1,index)
			kinds_valid = kinds_valid and deposit.kind == kind and int(deposit.amount) >= 350 and int(deposit.amount) <= 450
	check("all-seven-authored-materials-have-bounded-deposits",kinds_valid)
	check("collection-only-and-currency-have-no-deposits",Seams.generate(1,1,"stone",candidates).is_empty() and Seams.generate(1,1,"wallet_gold",candidates).is_empty())

	fresh()
	state.victory = false
	check("pre-victory-never-binds",state.bind_endless_treasury_seam(1,candidates).is_empty() and state.endless_chunks.is_empty())
	fresh()
	state.cargo.rootiron = 100000
	check("carried-complete-goal-stops-new-binding",state.bind_endless_treasury_seam(1,candidates).is_empty())
	state.cargo.rootiron = 45000
	state.treasury_totals.rootiron = 55000
	check("carried-plus-delivered-complete-goal-stops-binding",state.bind_endless_treasury_seam(1,candidates).is_empty())
	state.treasury_totals.clear()
	state.treasury_goals.twin_auger_claimed = true
	check("claimed-mod-never-binds",state.bind_endless_treasury_seam(1,candidates).is_empty())
	fresh()
	state.mark_endless_dug(1,160)
	check("previously-excavated-band-never-binds",state.bind_endless_treasury_seam(1,candidates).is_empty())
	fresh()
	state.endless_chunks["1"] = {"treasury_seam":{}}
	check("invalid-descriptor-tombstone-never-rerolls",state.bind_endless_treasury_seam(1,candidates).is_empty())
	fresh()
	var bound: Dictionary = state.bind_endless_treasury_seam(1,candidates)
	check("fresh-band-binds-and-stores-before-extraction",bound == deterministic and state.endless_chunks["1"].treasury_seam == bound)
	state.treasury_goals.pinned = "prismite"
	check("repinning-cannot-change-kind-or-cell",state.bind_endless_treasury_seam(1,[[],[],[]]) == bound)
	state.treasury_goals.pinned = ""
	check("unpinning-preserves-bound-deposits",state.bind_endless_treasury_seam(1,candidates) == bound)
	var deposit: Dictionary = Seams.deposit(bound,state.world_seed,1,24)
	var base: int = int(deposit.amount)
	var cell: int = int(deposit.cell)
	check("buried-ore-cannot-be-extracted",not state.claim_endless_resource_node(1,24,"rootiron",base,cell).ok)
	state.mark_endless_dug(1,cell)
	check("wrong-material-rejected",not state.claim_endless_resource_node(1,24,"prismite",base,cell).ok)
	check("wrong-cell-rejected",not state.claim_endless_resource_node(1,24,"rootiron",base,cell+1).ok)
	check("invented-amount-rejected",not state.claim_endless_resource_node(1,24,"rootiron",base+7,cell).ok)
	check("direct-cargo-bypass-rejected",not state.claim_endless_resource_node(1,24,"rootiron",base).ok)
	check("legacy-material-normal-slot-rejected",not state.claim_endless_resource_node(1,0,"rootiron",base,cell).ok)
	check("unbound-native-material-reserved-slot-rejected",not state.claim_endless_resource_node(2,24,"deep_alloy",base,cell).ok)
	var claim: Dictionary = state.claim_endless_resource_node(1,24,"rootiron",base*2,cell)
	check("real-extraction-creates-one-persistent-drop",claim.ok and state.endless_loose_drops(1).n24.amount == base*2)
	check("extraction-does-not-credit-cargo",int(state.cargo.rootiron) == 0)
	check("duplicate-strike-cannot-add-loot",not state.claim_endless_resource_node(1,24,"rootiron",base*2,cell).ok and state.endless_loose_drops(1).size() == 1)
	var saved_chunk: Dictionary = state.endless_chunks["1"].duplicate(true)
	check("physical-drop-saves",state.save_game(output.path_join("dropped.sav")))
	check("physical-drop-loads",state.load_game(output.path_join("dropped.sav")))
	check("reload-preserves-exact-descriptor-and-drop",state.endless_chunks["1"] == saved_chunk and int(state.cargo.rootiron) == 0)
	state.treasury_goals = {"pinned":"singularity","twin_auger_claimed":true}
	var picked_up: Dictionary = state.collect_endless_drop(1,"n24")
	check("pickup-conserves-amount-after-goal-change",picked_up.amount == base*2 and int(state.cargo.rootiron) == base*2 and state.endless_loose_drops(1).is_empty())
	check("double-pickup-is-empty",state.collect_endless_drop(1,"n24").is_empty() and int(state.cargo.rootiron) == base*2)
	check("pickup-state-saves-and-loads",state.save_game(output.path_join("collected.sav")) and state.load_game(output.path_join("collected.sav")))
	check("reload-cannot-renew-collected-node",state.endless_loose_drops(1).is_empty() and not state.claim_endless_resource_node(1,24,"rootiron",base*2,cell).ok)

	var corruptions: Array = [
		{"revision":2}, {"kind":"copper"}, {"kind":17}, {"cells":[cell,cell,731]},
		{"cells":[-2,451,731]}, {"cells":[171.5,451,731]}, {"cells":[1,451,731]}, {"cells":[]},
	]
	var refused: bool = true
	for change in corruptions:
		var bad: Dictionary = saved_chunk.duplicate(true)
		bad.treasury_seam.merge(change,true)
		var clean: Dictionary = Terrain.sanitize({"1":bad},1000,state.world_seed)["1"]
		refused = refused and clean.has("treasury_seam") and clean.treasury_seam.is_empty() and clean.drops.is_empty()
	check("malformed-descriptors-refuse-reward-and-preserve-tombstone",refused)
	var bad_drops: Array = [{"kind":"prismite"},{"cell":cell+1},{"cell":-1},{"amount":base*2+7},{"amount":1000000},{"amount":float(base*2)+0.5}]
	refused = true
	for change in bad_drops:
		var bad: Dictionary = saved_chunk.duplicate(true)
		bad.drops.n24.merge(change,true)
		refused = refused and Terrain.sanitize({"1":bad},1000,state.world_seed)["1"].drops.is_empty()
	var no_claim: Dictionary = saved_chunk.duplicate(true)
	no_claim.nodes = 0
	refused = refused and Terrain.sanitize({"1":no_claim},1000,state.world_seed)["1"].drops.is_empty()
	var no_dig: Dictionary = saved_chunk.duplicate(true)
	no_dig.dug = ""
	refused = refused and Terrain.sanitize({"1":no_dig},1000,state.world_seed)["1"].drops.is_empty()
	check("pending-drops-require-exact-valid-entitlement",refused)
	var normal: Dictionary = {"dug":"000f","nodes":1,"sites":3,"seen":2,"drops":{"n0":{"kind":"deep_alloy","amount":27,"cell":14},"c15":{"kind":"stone","amount":3,"cell":15}}}
	check("ordinary-legacy-journals-stay-identical",Terrain.sanitize({"7":normal},1000,state.world_seed)["7"] == normal)
	var conserved: bool = true
	for kind in Seams.MOD_BY_KIND:
		fresh(kind)
		var seam: Dictionary = state.bind_endless_treasury_seam(1,candidates)
		var entitlement: Dictionary = Seams.deposit(seam,state.world_seed,1,26)
		state.mark_endless_dug(1,int(entitlement.cell))
		var result: Dictionary = state.claim_endless_resource_node(1,26,kind,int(entitlement.amount)*4,int(entitlement.cell))
		# Prospecting's only possible bonus is one; preserve that earned unit too.
		state.endless_chunks["1"].drops.n26.amount += 1
		var before: int = int(entitlement.amount)*4+1
		conserved = conserved and result.ok and state.save_game(output.path_join("all-kinds.sav")) and state.load_game(output.path_join("all-kinds.sav"))
		var drop: Dictionary = state.collect_endless_drop(1,"n26")
		conserved = conserved and int(drop.get("amount",0)) == before and int(state.cargo[kind]) == before
	check("all-seven-materials-conserve-multiplied-and-prospected-drops-through-file-reload",conserved)
	fresh()
	state.endless_chunks["1"] = saved_chunk.duplicate(true)
	state.endless_chunks["1"].treasury_seam = {}
	check("corrupt-live-binding-cannot-credit-cargo",state.collect_endless_drop(1,"n24").is_empty() and int(state.cargo.rootiron) == 0)

	fresh()
	state.endless_deepest_depth = 12
	var legacy: Dictionary = state.serialize()
	legacy.state.endless_descent.erase("treasury_seam_start_depth")
	check("older-save-migrates-without-reset",state.deserialize(legacy) and state.endless_treasury_seam_start_depth == 13)
	state.endless_current_depth = 12
	check("previously-reached-untouched-bands-stay-unchanged",state.bind_endless_treasury_seam(12,candidates).is_empty())
	check("future-preloaded-ground-can-bind",not state.bind_endless_treasury_seam(13,candidates).is_empty())
	check("new-frontier-survives-save-load",state.save_game(output.path_join("frontier.sav")) and state.load_game(output.path_join("frontier.sav")) and state.endless_treasury_seam_start_depth == 13)
	for row in checks:
		if not row.passed: quit(1); return
	print("TREASURY_SEAMS_OK " + str(checks.size()))
	quit(0)
