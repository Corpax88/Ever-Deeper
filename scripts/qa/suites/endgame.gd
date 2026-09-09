extends "res://scripts/qa/qa_context.gd"
## Endgame checks moved intact from main.gd.


func _run_endgame_qa() -> void :
	RunState.reset_run(false)
	main.game_started = true
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.add_resource("singularity", 1, true)
	if not _endgame_qa_require(bool(RunState.singularity_secured), "singularity_pickup"):
		return
	if not _endgame_qa_require(int(RunState.cargo.get("singularity", 0)) == 1, "singularity_cargo"):
		return

	var recipe= Dictionary(RunState.deep_elevator_recipe())
	for resource_id_value in recipe:
		var resource_id= String(resource_id_value)
		var required= int(recipe[resource_id])
		var carried= int(RunState.cargo.get(resource_id, 0))
		if carried < required:
			RunState.add_resource(resource_id, required - carried, true)
		var delivery= Dictionary(RunState.deliver_deep_elevator_material(resource_id, required))
		if not _endgame_qa_require(bool(delivery.get("ok", false)), "deliver_%s" % resource_id):
			return
	if not _endgame_qa_require(bool(RunState.deep_elevator_status().get("repaired", false)), "elevator_repaired"):
		return
	if not _endgame_qa_require(RunState.power_deep_elevator(), "elevator_powered"):
		return

	main._enter_hub(false, false)
	if not _endgame_qa_require(main.phase == "hub", "enter_hub"):
		return
	main._enter_deepheart(true, false)
	if not _endgame_qa_require(main.phase == "deepheart" and bool(RunState.final_expedition_begun), "enter_deepheart"):
		return
	for seal_id_value in RunState.DEEPHEART_SEAL_IDS:
		var seal_id= String(seal_id_value)
		if not _endgame_qa_require(RunState.open_deepheart_seal(seal_id), "seal_%s" % seal_id):
			return
	if not _endgame_qa_require(bool(RunState.deepheart_seal_status().get("all_open", false)), "all_seals"):
		return
	if not _endgame_qa_require(RunState.complete_final_expedition(), "complete_final_expedition"):
		return
	if not _endgame_qa_require(bool(RunState.victory), "victory"):
		return

	main._on_deepheart_finale_completed()
	if not _endgame_qa_require(main.conclusion_overlay.visible and not bool(RunState.conclusion_seen), "conclusion_unseen"):
		return
	main._stay_in_deepheart_from_conclusion()
	if not _endgame_qa_require(bool(RunState.conclusion_seen) and not main.conclusion_overlay.visible and main.phase == "deepheart", "conclusion_stay"):
		return

	var endless= Dictionary(RunState.endless_descent_status())
	if not _endgame_qa_require(bool(endless.get("unlocked", false)) and not bool(endless.get("active", false)), "endless_unlock"):
		return
	var goal= Dictionary(main.guide_director.goal_for_state())
	if not _endgame_qa_require(String(goal.get("kind", "")) == "endless_enter" and String(goal.get("station_id", "")) == "deepElevator", "endless_guide"):
		return

	main._open_deepheart_conclusion()
	if not _endgame_qa_require(main.conclusion_overlay.visible, "conclusion_reopen"):
		return
	main._return_to_hub_from_conclusion()
	if not _endgame_qa_require(main.phase == "hub" and not main.conclusion_overlay.visible, "conclusion_return_hub"):
		return
	main._enter_deepheart()
	if not _endgame_qa_require(main.phase == "hub", "victory_reentry_blocked"):
		return
	main._on_deep_elevator_enter_requested()
	if not _endgame_qa_require(main.phase == "endless" and bool(Dictionary(RunState.endless_descent_status()).get("active", false)), "postgame_elevator_enters_endless"):
		return
	var world_snapshot= Dictionary(main.endless_world.debug_snapshot())
	# 1.0 requires mining through ordinary strata; a clear walking route is no
	# longer the design. Verify every generated target is reachable by real digging.
	var navigation: Dictionary = preload("res://scripts/qa/suites/one_point_zero_terrain.gd").connectivity(main.endless_world)
	if not _endgame_qa_require(bool(navigation.spawn_clear) and bool(navigation.all_targets_reachable) and int(navigation.target_count) > 1 and not bool(world_snapshot.get("health_required", true)), "endless_world_safe_mineable_connected"):
		return
	main._on_endless_depth_change_requested(0, "from_below")
	main._on_endless_hub_exit_requested()
	if not _endgame_qa_require(main.phase == "hub" and not bool(Dictionary(RunState.endless_descent_status()).get("active", true)), "endless_return_hub"):
		return

	RunState.set_location("hub", main.hub_world.player.global_position, 1)
	var saved= Dictionary(RunState.serialize())
	RunState.reset_run(false)
	if not _endgame_qa_require(RunState.deserialize(saved), "deserialize"):
		return
	var restored_endless= Dictionary(RunState.endless_descent_status())
	var restored_goal= Dictionary(main.guide_director.goal_for_state())
	if not _endgame_qa_require(
		bool(RunState.victory)
		and bool(RunState.conclusion_seen)
		and bool(restored_endless.get("unlocked", false))
		and int(restored_endless.get("deepest_depth", 0)) >= 1
		and String(restored_goal.get("kind", "")) == "endless_enter",
		"persistence"
	):
		return
	print("EVER_DEEPER_ENDGAME_OK seals=4 endless=unlocked gateway=true persistence=true conclusion=true deepheart_reentry=blocked")
	main.get_tree().quit(0)


func _endgame_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	print("EVER_DEEPER_ENDGAME_FAIL step=%s" % step)
	push_error("Endgame QA failed: %s" % step)
	main.get_tree().quit(3)
	return false
