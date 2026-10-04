extends SceneTree
## Real sale/claim/save paths against the exported PCK; no rendering claim.
var state: Node
var goals: Script
var ledger: Script
var seed_state: Dictionary
var checks: Array = []
var output: String

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("TREASURY_SALE_RESERVE_MISMATCH " + label)

func fresh() -> void:
	state.deserialize(seed_state.duplicate(true))
	state.cargo = state._empty_resource_store()
	state.gold = 17
	state.treasury_goals = goals.clean({})
	state.treasury_totals = {}

func sale_row(kind: String) -> Dictionary:
	for row in state.assay_sale_snapshot().rows:
		if row.kind == kind: return row
	return {"protected":0,"sellable":0,"carried":0}

func unit_value(kind: String) -> int:
	return int(root.get_node("GameData").data.ROCK_TYPES[kind].value)

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-treasury-sale-reserve"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	goals = load("res://scripts/state/treasury_goals.gd")
	ledger = load("res://scripts/state/treasury_state.gd")
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
	seed_state = state.serialize().duplicate(true)

	# Every non-Deep mod material can have >100k cargo. The earned goal keeps
	# only its outstanding balance; unrelated cargo and surplus still sell.
	for kind in ["rootiron","burrowsteel","prismite","phasecrystal","singularity"]:
		fresh()
		state.cargo[kind] = 100005
		state.cargo.copper = 7
		state.treasury_totals[kind] = 62500
		goals.pin(kind)
		var row: Dictionary = sale_row(kind)
		check(kind + "-reserves-only-37500-needed",row.protected == 37500 and row.sellable == 62505)
		var expected: int = 62505 * unit_value(kind) + 7 * unit_value("copper")
		check(kind + "-real-sale-sells-surplus-and-unrelated-ore",state.sell_all() == expected and state.cargo[kind] == 37500 and state.cargo.copper == 0 and state.gold == 17 + expected)
		check(kind + "-protected-only-sale-does-not-credit-gold",state.sell_all() == 0 and state.cargo[kind] == 37500 and state.gold == 17 + expected)
		goals.pin(kind)
		check(kind + "-untracking-releases-material",state.treasury_goals.pinned == "" and sale_row(kind).protected == 0)
		check(kind + "-released-material-sells-at-original-value",state.sell_all() == 37500 * unit_value(kind) and state.cargo[kind] == 0)

	fresh()
	state.cargo.copper = 9
	state.treasury_totals.copper = 99995
	goals.pin("copper")
	check("generic-collection-reserves-five-sells-four",sale_row("copper").protected == 5 and state.sell_all() == 4 * unit_value("copper") and state.cargo.copper == 5)
	check("partial-real-donation-reduces-held-and-needed-together",ledger.land("copper",2) == 2 and sale_row("copper").protected == 3 and state.treasury_totals.copper == 99997)
	check("completed-real-collection-retires-pin",ledger.land("copper",3) == 3 and state.treasury_goals.pinned == "")
	state.cargo.copper = 6
	check("completed-collection-new-cargo-sells",state.sell_all() == 6 * unit_value("copper") and state.cargo.copper == 0)

	fresh()
	state.cargo.prismite = 12
	state.treasury_totals.prismite = 100000
	goals.pin("prismite")
	check("full-unclaimed-mod-needs-no-extra-reserve",sale_row("prismite").protected == 0 and state.sell_all() == 12 * unit_value("prismite"))
	check("earned-mod-can-still-be-claimed",goals.claim("prismite"))
	state.treasury_goals.pinned = "prismite"
	state.treasury_totals.prismite = 0
	state.cargo.prismite = 12
	check("stale-claimed-pin-cannot-lock-cargo",sale_row("prismite").protected == 0 and state.sell_all() == 12 * unit_value("prismite"))

	fresh()
	state.cargo.rootiron = 10
	goals.pin("wallet_gold")
	check("currency-pin-does-not-reserve-ore-or-spend-gold",sale_row("rootiron").protected == 0 and state.sell_all() == 10 * unit_value("rootiron") and state.gold == 17 + 10 * unit_value("rootiron"))
	for kind in state.ENDLESS_RESOURCE_IDS:
		fresh()
		state.cargo[kind] = 19
		check(kind + "-existing-deep-material-policy-unchanged",sale_row(kind).protected == 19 and state.sell_all() == 0 and state.cargo[kind] == 19)

	fresh()
	state.cargo.rootiron = 12
	state.treasury_goals.pinned = "rootiron"
	state.victory = false
	check("stale-pre-victory-pin-does-not-reserve",sale_row("rootiron").protected == 0 and state.sell_all() == 12 * unit_value("rootiron"))
	fresh()
	state.cargo.rootiron = 12
	state.treasury_goals.pinned = "unknown_resource"
	check("invalid-pin-leaves-normal-sale-unchanged",state.sell_all() == 12 * unit_value("rootiron"))

	# Use the real next drill recipe to verify max(existing, goal), not a sum.
	fresh()
	state.drill_level = 0
	var recipe: Dictionary = state.next_drill_recipe()
	var requirement: Dictionary = recipe.requirements[0]
	var drill_kind: String = String(requirement.type)
	var drill_cost: int = int(requirement.amount)
	state.cargo[drill_kind] = drill_cost + 20
	state.treasury_totals[drill_kind] = 100000 - drill_cost - 5
	goals.pin(drill_kind)
	check("overlapping-drill-and-goal-reserve-uses-larger-balance",sale_row(drill_kind).protected == drill_cost + 5 and state.sell_all() == 15 * unit_value(drill_kind) and state.cargo[drill_kind] == drill_cost + 5)
	goals.pin(drill_kind)
	check("untracking-keeps-existing-drill-reserve",sale_row(drill_kind).protected == drill_cost and state.sell_all() == 5 * unit_value(drill_kind) and state.cargo[drill_kind] == drill_cost)
	state.treasury_totals[drill_kind] = 99999
	goals.pin(drill_kind)
	check("smaller-goal-never-weakens-drill-reserve",sale_row(drill_kind).protected == drill_cost and state.sell_all() == 0)

	# Older saves can contain an unlocked, partially funded workshop.
	fresh()
	state.endless_relics.forge_heart.placed = true
	state.endless_workshops.tool_forge.delivered = 50
	state.cargo.deep_alloy = 300
	state.treasury_totals.deep_alloy = 99900
	goals.pin("deep_alloy")
	check("larger-existing-workshop-reserve-is-preserved",state.protected_progress_cargo().deep_alloy == 150)
	goals.pin("deep_alloy")
	check("untracking-retains-workshop-and-deep-sale-policy",state.protected_progress_cargo().deep_alloy == 150 and state.sell_all() == 0 and state.cargo.deep_alloy == 300)

	# Commit recalculates reserves, protecting a goal pinned after sale preview.
	fresh()
	state.cargo.rootiron = 40
	var begun: Dictionary = state.begin_assay_sale()
	goals.pin("rootiron")
	var committed: Dictionary = state.commit_assay_sale(String(begun.transaction_id))
	check("pinning-after-preview-rejects-stale-sale",not bool(committed.ok) and committed.reason == "stale_sale" and state.cargo.rootiron == 40 and state.gold == 17)

	fresh()
	state.cargo.phasecrystal = 225
	state.treasury_totals.phasecrystal = 99800
	goals.pin("phasecrystal")
	check("tracked-state-saves",state.save_game(output.path_join("tracked.sav")))
	state.cargo.phasecrystal = 0
	state.treasury_goals.pinned = ""
	check("tracked-state-loads",state.load_game(output.path_join("tracked.sav")))
	check("reload-preserves-pin-deposit-and-cargo",state.treasury_goals.pinned == "phasecrystal" and state.treasury_totals.phasecrystal == 99800 and state.cargo.phasecrystal == 225)
	check("real-sale-after-reload-sells-only-25-surplus",state.sell_all() == 25 * unit_value("phasecrystal") and state.cargo.phasecrystal == 200)
	check("reserve-never-credits-treasury-implicitly",state.treasury_totals.phasecrystal == 99800)
	for row in checks:
		if not row.passed: quit(1); return
	print("TREASURY_SALE_RESERVE_OK " + str(checks.size()))
	quit(0)
