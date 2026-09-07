extends "res://scripts/qa/qa_context.gd"
## Endless checks moved intact from main.gd.


func _run_endless_qa() -> void :
	if not _prepare_endless_qa_victory():
		_endless_qa_require(false, "victory_setup")
		return
	RunState.mark_conclusion_seen()
	RunState.set_location("hub", Vector2(main.hub_world.entry_spawn()))
	var legacy_save= Dictionary(RunState.serialize())
	var legacy_state= Dictionary(legacy_save.get("state", {}))
	legacy_state.erase("endless_descent")
	legacy_save["state"] = legacy_state
	RunState.reset_run(false)
	if not _endless_qa_require(RunState.deserialize(legacy_save), "legacy_victory_deserialize"):
		return
	var legacy_status= Dictionary(RunState.endless_descent_status())
	if not _endless_qa_require(bool(RunState.victory) and bool(legacy_status.get("unlocked", false)) and int(legacy_status.get("start_depth", 0)) == 1, "legacy_victory_unlock"):
		return

	main.game_started = true
	main._enter_hub(false, false)
	main.hub_world.restore_position(Vector2(main.hub_world.DEEP_ELEVATOR_POSITION))
	if not _endless_qa_require(String(main.hub_world.current_context()) == "deepElevator", "endless_elevator_context"):
		return
	main.hub_world.perform_context()
	var entered= Dictionary(RunState.endless_descent_status())
	if not _endless_qa_require(main.phase == "endless" and bool(entered.get("active", false)) and int(entered.get("current_depth", 0)) == 1, "enter_endless"):
		return
	if not _endless_qa_require(_endless_premium_asset_contract(), "premium_assets_20"):
		return
	var layout= Dictionary(main.endless_world.debug_snapshot())
	var signature= String(layout.get("signature", ""))
	if not _endless_qa_require(
		not signature.is_empty()
		and bool(layout.get("path_connected", false))
		and bool(layout.get("spawn_clear", false))
		and int(layout.get("branch_count", 0)) >= 1
		and int(layout.get("site_count", 0)) >= 2
		and int(layout.get("hazards", 0)) >= 1
		and int(layout.get("enemies", -1)) == 0
		and not bool(layout.get("health_required", true))
		and not bool(layout.get("timer", true))
		and String(layout.get("ruin_gameplay", "")) == "choose_path_then_cross_ordered_floor_seals"
		and String(layout.get("hazard_model", "")) == "telegraphed_resonance_push_no_damage",
		"exploration_layout"
	):
		return
	main.endless_world.load_depth(1, "from_above")
	if not _endless_qa_require(String(Dictionary(main.endless_world.debug_snapshot()).get("signature", "")) == signature, "deterministic_layout"):
		return
	var site_result= Dictionary(main.endless_world.qa_complete_site_activity(1, "overload"))
	var site_kind= String(site_result.get("reward_kind", ""))
	var site_reward_after= int(RunState.cargo.get(site_kind, 0))
	var site_replay= Dictionary(main.endless_world.qa_complete_site_activity(1, "overload"))
	var site_state= Dictionary(RunState.endless_floor_site_state(1, 1))
	if not _endless_qa_require(
		bool(site_result.get("ok", false))
		and String(site_result.get("choice", "")) == "overload"
		and not site_kind.is_empty()
		and site_reward_after > 0
		and not bool(site_replay.get("ok", false))
		and int(RunState.cargo.get(site_kind, 0)) == site_reward_after
		and bool(site_state.get("resolved", false))
		and String(site_state.get("choice", "")) == "overload",
		"site_activity_one_claim"
	):
		return
	var hazard_probe= Dictionary(main.endless_world.qa_resonance_hazard_probe())
	if not _endless_qa_require(
		bool(hazard_probe.get("found", false))
		and bool(hazard_probe.get("telegraphed", false))
		and bool(hazard_probe.get("triggered", false))
		and bool(hazard_probe.get("pushed", false))
		and bool(hazard_probe.get("player_clear", false)),
		"resonance_hazard"
	):
		return
	if not _endless_qa_require(RunState.collect_endless_resource("deep_alloy", 199) and int(RunState.cargo.get("deep_alloy", 0)) == 199, "resource_199"):
		return

	main.endless_world.restore_position(Vector2(main.endless_world.native_relic_position))
	main.endless_world._update_discoveries()
	if not _endless_qa_require(String(main.endless_world.current_context()) == "endless_relic:forge_heart", "relic_context"):
		return
	main.endless_world.perform_context()
	if not _endless_qa_require(bool(Dictionary(RunState.relic_status("forge_heart")).get("attached", false)), "relic_attach"):
		return
	var rope= Dictionary(Dictionary(main.endless_world.debug_snapshot()).get("rope", {}))
	if not _endless_qa_require(bool(rope.get("attached", false)) and bool(rope.get("finite", false)) and int(rope.get("point_count", 0)) > 2, "rope_physics"):
		return
	if not _endless_qa_require(String(Dictionary(main.guide_director.goal_for_state()).get("kind", "")) == "endless_return", "haul_guide"):
		return
	main._on_endless_depth_change_requested(0, "from_below")
	main._on_endless_hub_exit_requested()
	var hauled= Dictionary(RunState.relic_status("forge_heart"))
	if not _endless_qa_require(main.phase == "hub" and bool(hauled.get("carried", false)) and bool(hauled.get("attached", false)), "haul_to_hub"):
		return
	if not _endless_qa_require(String(Dictionary(main.guide_director.goal_for_state()).get("kind", "")) == "relic_place", "placement_guide"):
		return
	main.hub_world.restore_position(Vector2(main.hub_world.DEEP_ELEVATOR_POSITION))
	main.hub_world.perform_context()
	if not _endless_qa_require(main.phase == "hub", "carried_relic_blocks_descent"):
		return
	main.hub_world.restore_position(Vector2(main.hub_world.RELIC_PEDESTAL_POSITION))
	if not _endless_qa_require(String(main.hub_world.current_context()) == "relicPedestal", "relic_pedestal_context"):
		return
	if not _endless_qa_require(
		main.hub_world.qa_set_hub_relic_endpoint(
			Vector2(main.hub_world.RELIC_PEDESTAL_POSITION) + Vector2(180, -16)
		),
		"relic_endpoint_far_setup"
	):
		return
	main.hub_world.perform_context()
	if not _endless_qa_require(
		not bool(Dictionary(RunState.relic_status("forge_heart")).get("placed", false)),
		"relic_endpoint_gate"
	):
		return
	if not _endless_qa_require(
		main.hub_world.qa_set_hub_relic_endpoint(
			Vector2(main.hub_world.RELIC_PEDESTAL_POSITION) + Vector2(0, -16)
		),
		"relic_endpoint_near_setup"
	):
		return
	main.hub_world.perform_context()
	var placement= Dictionary(RunState.relic_status("forge_heart"))
	if not _endless_qa_require(bool(placement.get("placed", false)) and bool(Dictionary(RunState.workshop_status("tool_forge")).get("blueprint_unlocked", false)), "place_and_blueprint"):
		return
	var partial= Dictionary(RunState.deliver_workshop_material("tool_forge", "deep_alloy", 199))
	var early_build= Dictionary(RunState.build_workshop("tool_forge"))
	if not _endless_qa_require(bool(partial.get("ok", false)) and int(partial.get("remaining", -1)) == 1 and not bool(early_build.get("ok", true)), "workshop_199_fails"):
		return

	main._enter_endless(true, false)
	if not _endless_qa_require(
		int(Dictionary(main.endless_world.debug_snapshot()).get("resource_count", -1)) == 0
		and int(Dictionary(RunState.endless_descent_status()).get("resource_exhausted_through", 0)) >= 1,
		"exhausted_floor_does_not_respawn"
	):
		return
	if not _endless_qa_require(RunState.collect_endless_resource("deep_alloy", 1), "resource_200"):
		return
	main._on_endless_depth_change_requested(0, "from_below")
	main._on_endless_hub_exit_requested()
	main.hub_world.restore_position(Vector2(main.hub_world.WORKSHOP_POSITIONS.tool_forge))
	if not _endless_qa_require(String(main.hub_world.current_context()) == "workshop:tool_forge", "tool_forge_context"):
		return
	main.hub_world.perform_context()
	var ready_tool_forge= Dictionary(RunState.workshop_status("tool_forge"))
	if not _endless_qa_require(
		bool(ready_tool_forge.get("ready_to_build", false))
		and not bool(ready_tool_forge.get("built", false))
		and int(ready_tool_forge.get("delivered", 0)) == 200,
		"workshop_200_delivered_not_built"
	):
		return
	main.hub_world.perform_context()
	if not _endless_qa_require(bool(Dictionary(RunState.workshop_status("tool_forge")).get("built", false)), "workshop_second_press_builds"):
		return


	main._enter_endless(true, false)
	main._on_endless_depth_change_requested(2, "from_above")
	main._on_endless_depth_change_requested(1, "from_below")
	main._on_endless_depth_change_requested(0, "from_below")
	main._on_endless_hub_exit_requested()
	main._enter_endless(true, false)
	if not _endless_qa_require(int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 1, "lift_checkpoint_locked"):
		return
	if not _endless_qa_require(RunState.collect_endless_resource("waystone", 200), "waystone_200"):
		return
	for next_depth in range(2, 13):
		main._on_endless_depth_change_requested(next_depth, "from_above")
	if not _endless_qa_require(RunState.discover_endless_relic("wayfinder_core", 12), "wayfinder_discover"):
		return
	if not _endless_qa_require(bool(Dictionary(RunState.collect_endless_relic("wayfinder_core", 12)).get("ok", false)) and RunState.attach_carried_relic("wayfinder_core"), "wayfinder_attach"):
		return
	for next_depth in range(11, -1, -1):
		main._on_endless_depth_change_requested(next_depth, "from_below")
	main._on_endless_hub_exit_requested()
	if not _endless_qa_require(bool(Dictionary(RunState.place_carried_relic()).get("ok", false)), "wayfinder_place"):
		return
	if not _endless_qa_require(bool(Dictionary(RunState.deliver_workshop_material("lift_workshop", "waystone", 200)).get("ok", false)), "lift_materials"):
		return
	if not _endless_qa_require(bool(Dictionary(RunState.build_workshop("lift_workshop")).get("ok", false)), "lift_build"):
		return
	main._enter_endless(true, false)
	main._on_endless_depth_change_requested(2, "from_above")
	main._on_endless_depth_change_requested(3, "from_above")
	if not _endless_qa_require(int(Dictionary(RunState.endless_descent_status()).get("start_depth", 0)) == 3, "lift_checkpoint_saved"):
		return
	main._on_endless_depth_change_requested(2, "from_below")
	main._on_endless_depth_change_requested(1, "from_below")
	main._on_endless_depth_change_requested(0, "from_below")
	main._on_endless_hub_exit_requested()
	main._enter_endless(true, false)
	if not _endless_qa_require(int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 3, "lift_checkpoint_restored"):
		return

	RunState.set_location("endless", main.endless_world.player.global_position)
	var saved= Dictionary(RunState.serialize())
	RunState.reset_run(false)
	if not _endless_qa_require(RunState.deserialize(saved), "save_reload"):
		return
	var restored= Dictionary(RunState.endless_descent_status())
	if not _endless_qa_require(
		String(RunState.current_scene) == "endless"
		and bool(restored.get("active", false))
		and int(restored.get("current_depth", 0)) == 3
		and bool(Dictionary(RunState.workshop_status("tool_forge")).get("built", false))
		and bool(Dictionary(RunState.workshop_status("lift_workshop")).get("built", false)),
		"persistent_endless_run"
	):
		return
	main.phase = "surface"
	main.endless_world.set_active(false)
	main._restore_saved_location()
	if not _endless_qa_require(main.phase == "endless" and int(main.endless_world.configured_depth()) == 3, "restore_scene"):
		return
	print("EVER_DEEPER_ENDLESS_OK legacy=true depth=3 deterministic=true hazards=telegraphed sites=active cache=one_claim rope=true relic=physical assets=20 blueprint=tool_forge materials=200 workshop=two_press lift_checkpoint=true persistence=true")
	main.get_tree().quit(0)


func _endless_premium_asset_contract() -> bool:
	var paths: Array[String] = [
		"res://assets/endless/node-lumen-shard-v1.png",
		"res://assets/endless/node-deep-alloy-v1.png",
		"res://assets/endless/node-memory-silk-v1.png",
		"res://assets/endless/node-echo-crystal-v1.png",
		"res://assets/endless/node-waystone-v1.png",
		"res://assets/endless/relic-forge-heart-v1.png",
		"res://assets/endless/relic-ancient-lens-v1.png",
		"res://assets/endless/relic-memory-loom-v1.png",
		"res://assets/endless/relic-echo-coffer-v1.png",
		"res://assets/endless/relic-wayfinder-core-v1.png",
		"res://assets/endless/ruin-survey-camp-v1.png",
		"res://assets/endless/ruin-archive-v1.png",
		"res://assets/endless/ruin-silent-machine-v1.png",
		"res://assets/endless/ruin-mineral-shrine-v1.png",
		"res://assets/endless/workshop-tool-forge-v1.png",
		"res://assets/endless/workshop-light-lab-v1.png",
		"res://assets/endless/workshop-wardrobe-v1.png",
		"res://assets/endless/workshop-lift-v1.png",
		"res://assets/endless/treasure-chamber-v1.png",
		"res://assets/endless/relic-pedestal-v1.png",
	]
	if paths.size() != 20:
		return false
	for path in paths:
		if not ResourceLoader.exists(path):
			return false
		var texture: Texture2D = load(path) as Texture2D
		if texture == null or texture.get_width() <= 0 or texture.get_height() <= 0:
			return false
	return true


func _prepare_endless_qa_victory() -> bool:
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.add_resource("singularity", 1, true)
	var recipe= Dictionary(RunState.deep_elevator_recipe())
	for resource_id_value in recipe:
		var resource_id= String(resource_id_value)
		var required= int(recipe[resource_id])
		var carried= int(RunState.cargo.get(resource_id, 0))
		if carried < required:
			RunState.add_resource(resource_id, required - carried, true)
		if not bool(Dictionary(RunState.deliver_deep_elevator_material(resource_id, required)).get("ok", false)):
			return false
	if not RunState.power_deep_elevator() or not RunState.begin_final_expedition():
		return false
	for seal_id_value in RunState.DEEPHEART_SEAL_IDS:
		if not RunState.open_deepheart_seal(String(seal_id_value)):
			return false
	return RunState.complete_final_expedition()


func _endless_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	print("EVER_DEEPER_ENDLESS_FAIL step=%s" % step)
	push_error("Endless QA failed: %s" % step)
	main.get_tree().quit(4)
	return false

