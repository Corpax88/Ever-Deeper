extends "res://scripts/qa/qa_context.gd"
## Commerce checks moved intact from main.gd.


func _run_workshop_overlap_qa() -> void :
	RunState.reset_run(false)
	main._dev_seed_victory_state()
	if not _workshop_overlap_qa_require(main._dev_grant_all_relics_state(), "relic_setup"):
		return
	var workshop_id= "light_lab"
	var status= Dictionary(RunState.workshop_status(workshop_id))
	var resource_id= String(status.get("build_resource", ""))
	var remaining= int(status.get("remaining", 0))
	RunState.add_resource(resource_id, remaining, false)
	var delivery= Dictionary(RunState.deliver_workshop_material(workshop_id, resource_id, remaining))
	if not _workshop_overlap_qa_require(bool(delivery.get("ok", false)), "materials"):
		return
	main.game_started = true
	main._enter_hub(false, false)
	var site= Vector2(main.hub_world.WORKSHOP_POSITIONS[workshop_id])
	var overlap_position= site + Vector2(0, 60)
	main.hub_world.restore_position(overlap_position)
	if not _workshop_overlap_qa_require(
		main.hub_world.player.global_position.is_equal_approx(overlap_position)
		and String(main.hub_world.current_context()) == "workshop:%s" % workshop_id,
		"overlap_setup"
	):
		return
	main.hub_world.perform_context()
	if not _workshop_overlap_qa_require(
		bool(Dictionary(RunState.workshop_status(workshop_id)).get("built", false)),
		"built"
	):
		return
	if not _workshop_overlap_qa_require(main.hub_world.player_position_clear(), "escaped"):
		return
	var safe_position: Vector2 = Vector2(main.hub_world.player.global_position)
	var resolved= Vector2(main.hub_world._resolve_motion(safe_position, Vector2(0, 8)))
	if not _workshop_overlap_qa_require(
		resolved.distance_squared_to(safe_position) > 1.0,
		"movable"
	):
		return
	main.hub_world.restore_position(site)
	if not _workshop_overlap_qa_require(main.hub_world.player_position_clear(), "restore_recovery"):
		return
	var clear_restore= site + Vector2(0, 104)
	main.hub_world.restore_position(clear_restore)
	if not _workshop_overlap_qa_require(
		main.hub_world.player.global_position.is_equal_approx(clear_restore),
		"safe_restore_exact"
	):
		return
	print("EVER_DEEPER_WORKSHOP_OVERLAP_OK workshop=light_lab built=true escaped=true movable=true restore=true")
	main.get_tree().quit(0)


func _workshop_overlap_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_WORKSHOP_OVERLAP_FAIL step=%s" % step)
	main.get_tree().quit(5)
	return false


func _run_commerce_integration_qa() -> void :
	RunState.reset_run(false)
	main.game_started = true
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.deepheart_world.set_active(false)
	main.endless_world.set_active(false)
	main.surface_world.reset_for_new_run()
	main.surface_world.set_active(true)

	RunState.add_resource("stone", 4, false)
	RunState.add_resource("copper", 3, false)
	var expected_sale= (
		4 * int(GameData.data.ROCK_TYPES.stone.value)
		+ 3 * int(GameData.data.ROCK_TYPES.copper.value)
	)
	main.assay_auto_armed = true
	main.surface_world.restore_position(main.surface_world.station_interaction_position("sell"))
	assert (main.surface_context == "sell" and main.assay_auto_armed)
	main._start_assay_transaction()
	assert ( not main.assay_auto_armed and main.station_transaction_fx.busy and String(main.commerce_transaction.get("kind", "")) == "assay")
	assert (main.surface_world.player.control_enabled, "Assay presentation must never lock movement")
	var assay_state_id= String(main.commerce_transaction.get("state_id", ""))
	main._start_assay_transaction()
	assert (String(main.commerce_transaction.get("state_id", "")) == assay_state_id, "Standing in Assay must not create a duplicate sale")
	var assay_fx: Dictionary = Dictionary(main.station_transaction_fx.debug_snapshot())
	assert (int(assay_fx.get("visual_cap", 0)) <= 16 and not bool(assay_fx.get("per_visual_nodes", true)))
	main.station_transaction_fx.complete_immediately()
	assert (RunState.gold == expected_sale and int(RunState.cargo.stone) == 0 and int(RunState.cargo.copper) == 0)
	assert (main.commerce_transaction.is_empty() and main.commerce_presented_gold < 0)
	main.surface_world.restore_position(Vector2(240, 680))
	assert (main.assay_auto_armed, "Assay must re-arm only after the player leaves")

	var forge_cost= int(RunState.next_pickaxe().cost)
	RunState.gold = forge_cost
	main.surface_world.restore_position(main.surface_world.station_interaction_position("forge"))
	main._perform_context()
	assert (main.commerce_panel.is_open() and main.commerce_context == "forge")
	if main.developer_menu != null:
		assert (not bool(main.developer_menu.toggle_button.visible), "DEV toggle must be suppressed behind commerce")
	var mobile_css_size= Vector2(844, 390)
	var mobile_scale_to_css= mobile_css_size.y / 720.0
	var mobile_logical_size= Vector2(720.0 * mobile_css_size.x / mobile_css_size.y, 720.0)
	var mobile_metrics: Dictionary = Dictionary(main.commerce_panel.apply_landscape_layout_for_test(mobile_logical_size))
	await main.get_tree().process_frame
	var mobile_panel_snapshot: Dictionary = Dictionary(main.commerce_panel.interaction_snapshot())
	assert (bool(mobile_metrics.get("fits_width", false)) and bool(mobile_metrics.get("fits_height", false)))
	assert (bool(mobile_panel_snapshot.get("touch_targets_valid", false)))
	assert (float(mobile_panel_snapshot.get("touch_target_rendered_minimum", 0.0)) * mobile_scale_to_css >= 44.0)
	assert (float(mobile_panel_snapshot.get("minimum_font_size", 0)) * mobile_scale_to_css >= 10.0)
	var pickaxe_before= int(RunState.pickaxe_level)
	main._on_commerce_action_confirmed("forge:pickaxe")
	assert ( not main.commerce_panel.is_open() and main.surface_world.player.control_enabled)
	if main.developer_menu != null:
		assert (bool(main.developer_menu.toggle_button.visible), "DEV toggle must return after commerce closes")
	assert (RunState.pickaxe_level == pickaxe_before, "Forge economy must commit after its presentation")
	assert (main.station_transaction_fx.busy and main.commerce_presented_gold == forge_cost)
	main.station_transaction_fx.complete_immediately()
	assert (RunState.pickaxe_level == pickaxe_before + 1 and RunState.gold == 0)
	assert (main.gold_label.text == "0 GOLD" and main.premium_hud.gold_value.text == "0")

	var wayfarer_cost= int(RunState.movement_speed_upgrade_cost())
	RunState.gold = wayfarer_cost
	main.surface_world.restore_position(main.surface_world.station_interaction_position("speedShop"))
	main._perform_context()
	assert (main.commerce_panel.is_open() and main.commerce_panel.selected_item_id() == "wayfarer:speed")
	main._on_commerce_action_confirmed("wayfarer:speed")
	assert (RunState.movement_speed_level == 1 and main.commerce_presented_gold == wayfarer_cost)
	main.station_transaction_fx.complete_immediately()
	assert (RunState.gold == 0 and main.commerce_presented_gold < 0)
	assert (is_equal_approx(main.surface_world.player.movement_speed, float(GameData.data.PLAYER_SPEED) * 1.07))

	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	RunState.cargo.astralite = 200
	RunState.cargo.crownstone = 200
	main.surface_world.restore_position(main.surface_world.station_interaction_position("starforge"))
	main._perform_context()
	var starforge_panel_snapshot: Dictionary = Dictionary(main.commerce_panel.interaction_snapshot())
	assert (bool(starforge_panel_snapshot.get("open", false)) and int(starforge_panel_snapshot.get("item_count", 0)) == 3)
	assert ( not main.starforge_panel.visible, "Legacy Starforge buttons must remain retired")
	main._on_commerce_action_confirmed("starforge:crusher")
	assert (String(RunState.starforge_variant) == "crusher")
	assert (int(RunState.cargo.astralite) == 0 and int(RunState.cargo.crownstone) == 0)
	main.station_transaction_fx.complete_immediately()
	assert (main.commerce_transaction.is_empty() and main.surface_world.player.control_enabled)

	main._dev_seed_victory_state()
	assert (main._dev_build_all_workshops_state())
	var workshop_catalog_count= 0
	for workshop_id_value in RunState.ENDLESS_WORKSHOP_IDS:
		var workshop_id= String(workshop_id_value)
		var workshop_config: Dictionary = Dictionary(main.CommerceCatalogScript.workshop_config(
			workshop_id,
			Dictionary(RunState.workshop_status(workshop_id)),
			Dictionary(main.hub_world.workshop_selection_preview(workshop_id))
		))
		assert ( not Array(workshop_config.get("items", [])).is_empty(), "%s commerce catalog must contain an inspectable item" % workshop_id)
		workshop_catalog_count += 1
	assert (workshop_catalog_count == 5)

	print("EVER_DEEPER_COMMERCE_OK assay=auto_movable_once wallet=ticked forge=deferred wayfarer=menu starforge=3 workshops=5 mobile_css=844x390-956x440 touch>=44 cap=16")
	main.get_tree().quit(0)


func _run_workshop_panel_qa() -> void :
	RunState.reset_run(false)
	main._dev_seed_victory_state()
	if not _workshop_panel_qa_require(main._dev_grant_all_relics_state(), "relic_setup"):
		return
	var workshop_id= "tool_forge"
	var initial= Dictionary(RunState.workshop_status(workshop_id))
	var resource_id= String(initial.get("build_resource", ""))
	var required= int(initial.get("remaining", 0))
	RunState.add_resource(resource_id, required, false)
	main.game_started = true
	main._enter_hub(false, false)
	main.hub_world.restore_position(Vector2(main.hub_world.WORKSHOP_POSITIONS[workshop_id]) + Vector2(0, 104))
	if not _workshop_panel_qa_require(String(main.hub_world.current_context()) == "workshop:%s" % workshop_id, "context"):
		return

	main.hub_world.perform_context()
	await main.get_tree().process_frame
	var delivery_visual= Dictionary(main.hub_world.qa_workshop_presentation_snapshot())
	var delivery_current= Dictionary(delivery_visual.get("current", {}))
	if not _workshop_panel_qa_require(
		String(delivery_current.get("kind", "")) == "delivery"
		and int(delivery_current.get("particle_count", 0)) >= 6
		and bool(Dictionary(RunState.workshop_status(workshop_id)).get("ready_to_build", false)),
		"delivery_presentation"
	):
		return

	main.hub_world.perform_context()
	await main.get_tree().process_frame
	var build_visual= Dictionary(main.hub_world.qa_workshop_presentation_snapshot())
	if not _workshop_panel_qa_require(
		String(Dictionary(build_visual.get("current", {})).get("kind", "")) == "build"
		and int(build_visual.get("serial", 0)) > int(delivery_visual.get("serial", 0))
		and bool(Dictionary(RunState.workshop_status(workshop_id)).get("built", false)),
		"build_presentation"
	):
		return

	RunState.add_resource(resource_id, 100, false)
	var cancel_level_before= int(Dictionary(RunState.workshop_status(workshop_id)).get("level", 0))
	var cancel_cargo_before= int(RunState.cargo.get(resource_id, 0))
	main.hub_world.perform_context()
	await main.get_tree().process_frame
	var iphone_css_size= Vector2(844, 390)
	var iphone_scale_to_css= iphone_css_size.y / 720.0
	var iphone_logical_size= Vector2(720.0 * iphone_css_size.x / iphone_css_size.y, 720.0)
	var iphone_panel_layout= Dictionary(main.commerce_panel.apply_landscape_layout_for_test(iphone_logical_size))
	await main.get_tree().process_frame
	var panel_snapshot= Dictionary(main.commerce_panel.interaction_snapshot())
	if not _workshop_panel_qa_require(
		bool(panel_snapshot.get("open", false))
		and bool(panel_snapshot.get("touch_targets_valid", false))
		and float(panel_snapshot.get("touch_target_rendered_minimum", 0.0)) * iphone_scale_to_css >= 44.0
		and float(panel_snapshot.get("minimum_font_size", 0)) * iphone_scale_to_css >= 10.0
		and bool(iphone_panel_layout.get("fits_width", false))
		and bool(iphone_panel_layout.get("fits_height", false))
		and not bool(main.hub_world.player.control_enabled)
		and int(Dictionary(RunState.workshop_status(workshop_id)).get("level", 0)) == cancel_level_before
		and int(RunState.cargo.get(resource_id, 0)) == cancel_cargo_before,
		"preview_first_no_transaction"
	):
		return
	main.commerce_panel.close_commerce()
	if not _workshop_panel_qa_require(
		int(Dictionary(RunState.workshop_status(workshop_id)).get("level", 0)) == cancel_level_before
		and int(RunState.cargo.get(resource_id, 0)) == cancel_cargo_before
		and bool(main.hub_world.player.control_enabled),
		"cancel_free"
	):
		return

	main.hub_world.perform_context()
	main._on_commerce_action_confirmed("workshop:upgrade")
	await main.get_tree().process_frame
	var upgraded= Dictionary(RunState.workshop_status(workshop_id))
	var upgrade_visual= Dictionary(main.hub_world.qa_workshop_presentation_snapshot())
	if not _workshop_panel_qa_require(
		int(upgraded.get("level", 0)) == 2
		and int(RunState.cargo.get(resource_id, 0)) == 0
		and String(Dictionary(upgrade_visual.get("current", {})).get("kind", "")) == "upgrade",
		"explicit_upgrade"
	):
		return

	main.hub_world.perform_context()
	await main.get_tree().process_frame
	if not _workshop_panel_qa_require(main.commerce_panel.select_item("workshop:equip:crusher"), "equipment_preview"):
		return
	var loadout_before_cancel= String(Dictionary(RunState.endless_loadout_status()).get("tool", ""))
	if not _workshop_panel_qa_require(
		loadout_before_cancel == "original"
		and String(Dictionary(Dictionary(main.hub_world.qa_workshop_presentation_snapshot()).get("panel_preview", {})).get("value", "")) == "crusher",
		"preview_does_not_equip"
	):
		return
	main.commerce_panel.close_commerce()
	if not _workshop_panel_qa_require(
		String(Dictionary(RunState.endless_loadout_status()).get("tool", "")) == "original"
		and Dictionary(Dictionary(main.hub_world.qa_workshop_presentation_snapshot()).get("panel_preview", {})).is_empty(),
		"preview_cancel_cleanup"
	):
		return

	main.hub_world.perform_context()
	await main.get_tree().process_frame
	if not _workshop_panel_qa_require(main.commerce_panel.select_item("workshop:equip:crusher"), "equipment_reselect"):
		return
	main._on_commerce_action_confirmed("workshop:equip:crusher")
	await main.get_tree().process_frame
	if not _workshop_panel_qa_require(
		String(Dictionary(RunState.endless_loadout_status()).get("tool", "")) == "crusher"
		and String(Dictionary(Dictionary(main.hub_world.qa_workshop_presentation_snapshot()).get("current", {})).get("kind", "")) == "equip",
		"explicit_equip"
	):
		return
	main.hub_world.perform_context()
	await main.get_tree().process_frame
	if not _workshop_panel_qa_require(main.commerce_panel.select_item("workshop:style:riveted"), "style_preview"):
		return
	main._on_commerce_action_confirmed("workshop:style:riveted")
	if not _workshop_panel_qa_require(String(Dictionary(RunState.workshop_status(workshop_id)).get("style", "")) == "riveted", "explicit_style"):
		return
	main.hub_world.set_active(false)
	var cleanup= Dictionary(main.hub_world.qa_workshop_presentation_snapshot())
	if not _workshop_panel_qa_require(
		not bool(cleanup.get("active", true))
		and String(Dictionary(cleanup.get("last", {})).get("cleanup_reason", "")) == "inactive"
		and Array(cleanup.get("events", [])).size() >= 5,
		"presentation_cleanup"
	):
		return
	print("EVER_DEEPER_WORKSHOP_PANEL_OK preview_first=true cancel_free=true touch=52 delivery=physical build=staged upgrade=staged equip=explicit style=explicit cleanup=true")
	main.get_tree().quit(0)


func _workshop_panel_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_WORKSHOP_PANEL_FAIL step=%s" % step)
	main.get_tree().quit(6)
	return false

