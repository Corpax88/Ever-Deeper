extends SceneTree
## Real claim/save/load and panel state; run with MODS_OUT=<evidence dir>.
var Goals: Script
var main: Node
var state: Node
var checks: Array = []
var output: String

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("TREASURY_GOAL_MISMATCH "+label)

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-treasury-goal"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	# SceneTree scripts parse before project autoload names are registered.
	# Load the real helper after startup so its RunState reference resolves.
	Goals = load("res://scripts/state/treasury_goals.gd")
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
	state.treasury_goals = Goals.clean({})
	state.treasury_totals = {"wallet_gold":100000,"prismite":100000}

	Goals.pin("wallet_gold")
	check("ready-unclaimed-goal-still-guides-home",Goals.hud_goal().get("hud_action","")=="Return to your podium")
	check("real-mod-claim-succeeds",Goals.claim("wallet_gold"))
	check("claim-clears-matching-goal",state.treasury_goals.pinned=="" and Goals.hud_goal().is_empty())
	check("claimed-mod-remains-equipped",Goals.active_mod()=="resonance")
	check("normal-progression-goal-resumes",not String(main.guide_director.goal_for_state().get("objective_id","")).begins_with("treasury:") and not main.guide_director.goal_for_state().is_empty())
	main.treasury_goal_panel.kind = "wallet_gold"
	main.treasury_goal_panel.refresh()
	check("claimed-mod-tracking-control-is-clear",main.treasury_goal_panel.pin_button.disabled and main.treasury_goal_panel.pin_button.text=="MOD UNLOCKED")
	Goals.pin("wallet_gold")
	check("claimed-mod-cannot-be-repinned",state.treasury_goals.pinned=="")
	check("claim-state-saves",state.save_game(output.path_join("claimed.sav")))
	check("claim-state-loads",state.load_game(output.path_join("claimed.sav")))
	check("reload-preserves-unlock-without-stale-goal",bool(state.treasury_goals.resonance_claimed) and Goals.hud_goal().is_empty())

	Goals.pin("prismite")
	var pinned: String = state.treasury_goals.pinned
	check("duplicate-claim-is-rejected",not Goals.claim("wallet_gold"))
	check("failed-claim-preserves-unrelated-pin",state.treasury_goals.pinned==pinned)
	state.treasury_totals.rootiron = 100000
	check("different-mod-claim-succeeds",Goals.claim("rootiron"))
	check("different-mod-claim-preserves-pin",state.treasury_goals.pinned=="prismite")
	main.treasury_goal_panel.kind = "prismite"
	main.treasury_goal_panel.refresh()
	check("unclaimed-goal-remains-trackable",not main.treasury_goal_panel.pin_button.disabled and main.treasury_goal_panel.pin_button.text=="UNTRACK GOAL")

	var legacy: Dictionary = state.treasury_goals.duplicate(true)
	legacy.pinned = "wallet_gold"
	var cleaned: Dictionary = Goals.clean(legacy)
	check("legacy-claimed-pin-is-retired",cleaned.pinned=="" and bool(cleaned.resonance_claimed))
	state.treasury_goals = legacy
	check("stale-in-memory-pin-cannot-obscure-next-goal",Goals.hud_goal().is_empty())
	Goals.pin("stone")
	check("collection-only-goals-remain-available",state.treasury_goals.pinned=="stone" and not Goals.hud_goal().is_empty())
	for row in checks:
		if not row.passed:
			quit(1)
			return
	print("TREASURY_GOAL_COMPLETION_OK "+str(checks.size()))
	quit(0)
