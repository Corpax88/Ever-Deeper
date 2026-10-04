extends SceneTree
var state: Node
var goals: Script
var ledger: Script
var checks: Array = []
var output: String
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	if not ok: print("COMPLETED_COLLECTION_MISMATCH "+label)
func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-completed-collection"
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
	state.treasury_goals = goals.clean({})
	state.treasury_totals = {"copper":99998}
	state.cargo.copper = 5
	goals.pin("copper")
	check("unfinished-generic-collection-is-trackable",state.treasury_goals.pinned == "copper")
	check("partial-donation-keeps-existing-goal",ledger.land("copper",1) == 1 and state.treasury_goals.pinned == "copper")
	check("capped-final-donation-preserves-cargo",ledger.land("copper",5) == 1 and state.cargo.copper == 3 and state.treasury_totals.copper == 100000)
	check("completed-collection-clears-matching-pin",state.treasury_goals.pinned == "" and goals.hud_goal().is_empty())
	goals.pin("copper")
	check("completed-generic-collection-cannot-repin",state.treasury_goals.pinned == "")
	check("further-donation-cap-is-unchanged",ledger.land("copper",2) == 0 and state.cargo.copper == 3)
	state.treasury_goals.pinned = "copper"
	check("stale-live-completed-goal-is-hidden",goals.hud_goal().is_empty())
	check("legacy-save-with-completed-pin-saves-and-loads",state.save_game(output.path_join("legacy.sav")) and state.load_game(output.path_join("legacy.sav")))
	check("legacy-completed-pin-retires-on-load",state.treasury_goals.pinned == "" and state.treasury_totals.copper == 100000 and state.cargo.copper == 3)
	goals.pin("prismite")
	state.cargo.stone = 1
	state.treasury_totals.stone = 99999
	check("other-collection-completion-preserves-current-pin",ledger.land("stone",1) == 1 and state.treasury_goals.pinned == "prismite")
	state.cargo.prismite = 1
	state.treasury_totals.prismite = 99999
	check("unclaimed-mod-completion-still-guides-to-claim",ledger.land("prismite",1) == 1 and state.treasury_goals.pinned == "prismite" and goals.hud_goal().hud_action == "Return to your podium")
	check("claimed-mod-still-clears-pin",goals.claim("prismite") and state.treasury_goals.pinned == "")
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	for row in checks:
		if not row.passed: quit(1); return
	print("COMPLETED_COLLECTION_OK "+str(checks.size()))
	quit(0)
