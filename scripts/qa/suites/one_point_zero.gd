extends "res://scripts/qa/qa_context.gd"
## Material fixtures accelerate waiting; real runtime owners perform transactions.
## These checks do not certify player pacing, rendered art or physical iPhone FPS.

var check_count: int = 0
var failures: Array[String] = []
var journey: Array[Dictionary] = []


func _check(condition: bool, label: String) -> bool:
	check_count += 1
	if not condition:
		failures.append(label)
		print("ONE_POINT_ZERO_CHECK_FAILED %s" % label)
	return condition


func _finish(label: String) -> void:
	print("ONE_POINT_ZERO_RESULT " + JSON.stringify({
		"case": label, "checks": check_count, "failures": failures,
		"journey": journey,
		"limit": "Accelerated fixtures; no physical iPhone or visual certification",
	}))
	if failures.is_empty():
		print("EVER_DEEPER_ONE_POINT_ZERO_%s_OK checks=%d" % [label.to_upper(), check_count])
		main.get_tree().quit(0)
	else:
		main.get_tree().quit(4)


func _goal(label: String) -> Dictionary:
	var goal: Dictionary = main.guide_director.goal_for_state()
	_check(not String(goal.get("objective_id", "")).is_empty(), label + ": objective exists")
	_check(not String(goal.get("hud_title", "")).is_empty(), label + ": concise HUD goal exists")
	for value in Array(goal.get("requirements", [])):
		var row: Dictionary = value
		_check(int(row.get("owned", -1)) >= 0, label + ": nonnegative inventory")
		_check(int(row.get("required", -1)) >= 0, label + ": nonnegative cost")
		var resource: String = String(row.get("resource_id", ""))
		var expected: int = RunState.gold if bool(row.get("is_currency", false)) else int(RunState.cargo.get(resource, 0)) + int(row.get("delivered", 0))
		_check(int(row.get("owned", -1)) == expected, label + ": authoritative available " + resource)
	journey.append({"step": label, "goal": goal})
	return goal


func _fund_resource(resource_id: String, amount: int) -> void:
	var missing: int = maxi(0, amount - int(RunState.cargo.get(resource_id, 0)))
	if missing > 0:
		RunState.add_resource(resource_id, missing, true)


func _purchase_forge(kind: String) -> bool:
	var before: Dictionary = RunState.forge_purchase_snapshot(kind)
	var cost: Dictionary = Dictionary(before.get("cost", {}))
	var currency: int = int(Dictionary(cost.get("gold", {})).get("required", 0))
	for value in Array(cost.get("resources", [])):
		var row: Dictionary = value
		_fund_resource(String(row.kind), int(row.required))
	RunState.gold = maxi(0, currency - 1)
	if currency > 0:
		_check(not bool(RunState.begin_forge_purchase(kind).get("ok", false)), kind + ": one gold short rejected")
	RunState.gold = currency
	_goal(kind + ": recipe ready")
	var transaction: Dictionary = RunState.begin_forge_purchase(kind)
	if not _check(bool(transaction.get("ok", false)), kind + ": begins real purchase"):
		return false
	var id: String = String(transaction.transaction_id)
	if not _check(bool(RunState.commit_forge_purchase(id).get("ok", false)), kind + ": commits purchase"):
		return false
	var spent_state: Dictionary = RunState.serialize()
	RunState.commit_forge_purchase(id)
	var replay_state: Dictionary = RunState.serialize()
	_check(Dictionary(spent_state.state).get("gold") == Dictionary(replay_state.state).get("gold"), kind + ": duplicate commit spends no gold")
	_check(Dictionary(spent_state.state).get("cargo") == Dictionary(replay_state.state).get("cargo"), kind + ": duplicate commit spends no resources")
	_check(RunState.gold == 0, kind + ": exact gold cost")
	return true


func _open_gate(world_id: String) -> bool:
	var rules: Dictionary = Dictionary(main.GATE_REQUIREMENTS[world_id])
	var cost: int = int(rules.gold)
	RunState.gold = maxi(0, cost - 1)
	if cost > 0:
		main._try_unlock_gate(world_id)
		_check(not RunState.is_world_unlocked(world_id), world_id + ": gate rejects insufficient gold")
	RunState.gold = cost
	_goal(world_id + ": gate ready")
	main._try_unlock_gate(world_id)
	if not _check(RunState.is_world_unlocked(world_id), world_id + ": real gate opens"):
		return false
	_check(RunState.gold == 0, world_id + ": gate spends exact gold")
	main._try_unlock_gate(world_id)
	_check(RunState.gold == 0, world_id + ": reopening never spends twice")
	return true


func _new_player_to_deep() -> bool:
	# qa.py supplies an isolated XDG_DATA_HOME; enable the real travel/save path.
	RunState.initialize_persistence("user://one-point-zero.json")
	main.persistence_active = true
	main._start_new_game()
	_check(not bool(RunState.endless_descent_status().get("unlocked", true)), "fresh: Deep locked")
	_check(not bool(RunState.start_endless_descent().get("ok", true)), "fresh: cannot skip early progression")
	_goal("fresh player")
	while RunState.pickaxe_level < 3:
		if not _purchase_forge("pickaxe"):
			return false
	if not _open_gate("moonglass") or not _purchase_forge("pickaxe") or not _open_gate("emberdeep"):
		return false
	if not _purchase_forge("pickaxe"):
		return false
	for _rank in range(5):
		if not _purchase_forge("ember_mastery"):
			return false
	if not _open_gate("starfall"):
		return false
	var starforge: Dictionary = RunState.starforge_crafting_status("crusher")
	var starforge_cost: Dictionary = Dictionary(Dictionary(starforge.get("variant", {})).get("cost", {}))
	for resource_id in starforge_cost:
		_fund_resource(String(resource_id), int(starforge_cost[resource_id]))
	_goal("Starforge ready")
	if not _check(RunState.forge_starforge_variant("crusher"), "Starforge crafted through real transaction"):
		return false
	main._enter_hub(false, false)
	RunState.mark_hub_tutorial_seen()
	for _level in range(3):
		var recipe: Dictionary = RunState.next_drill_recipe()
		if not _check(not recipe.is_empty(), "Next drill recipe exists"):
			return false
		RunState.gold = int(recipe.gold)
		for value in Array(recipe.requirements):
			var row: Dictionary = value
			_fund_resource(String(row.type), int(row.amount))
		_goal("Drill %d ready" % int(recipe.level))
		if not _check(RunState.upgrade_drill(), "Drill upgrades through real recipe"):
			return false
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	_fund_resource("singularity", 1)
	if not _check(RunState.singularity_secured, "Singularity secured by actual resource pickup"):
		return false
	_goal("Deep passage materials")
	for resource_id in RunState.deep_elevator_recipe():
		var required: int = int(RunState.deep_elevator_recipe()[resource_id])
		_fund_resource(String(resource_id), required)
		_check(bool(RunState.deliver_deep_elevator_material(String(resource_id), required).get("ok", false)), "Passage receives " + String(resource_id))
	if not _check(RunState.power_deep_elevator(), "Passage powered after all materials"):
		return false
	if not _check(RunState.begin_final_expedition(), "Final expedition starts"):
		return false
	for seal_id in RunState.DEEPHEART_SEAL_IDS:
		_check(RunState.open_deepheart_seal(String(seal_id)), "Deepheart seal " + String(seal_id))
	if not _check(RunState.complete_final_expedition(), "Deepheart unlocks continuous Deep"):
		return false
	RunState.mark_conclusion_seen()
	main._enter_hub(false, false)
	_goal("First descent available")
	return true


func _run_state_qa() -> void:
	if _new_player_to_deep():
		var expected: Dictionary = {
			"forge_heart": "tool_forge", "ancient_lens": "light_lab",
			"memory_loom": "wardrobe", "echo_coffer": "treasure_chamber",
			"wayfinder_core": "lift_workshop",
		}
		_check(RunState.relic_catalog().size() == 5, "Exactly five existing relics")
		for relic_id in expected:
			_check(String(RunState.relic_status(String(relic_id)).get("workshop_id", "")) == String(expected[relic_id]), "Preserved relic/shop identity " + String(relic_id))
		_check(bool(RunState.endless_descent_status().get("unlocked", false)), "Fresh progression reaches The Deep")
		_check(not bool(RunState.endless_descent_status().get("exploration_complete", true)), "Deep has no final completion state")
	_finish("state")
