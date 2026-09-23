extends "res://scripts/qa/suites/dev14_review.gd"
## Explicit fixture only; browser uses actual touch against observed control bounds.
func run() -> void:
	super.run()

func _command(data: Dictionary) -> void:
	if String(data.kind) not in ["skills_fixture", "fatigue_fixture"]:
		super._command(data)
		return
	command_id = int(data.id)
	fixture = String(data.kind)
	if fixture == "skills_fixture":
		RunState.miner_skills = {"mining": 21424.0, "running": 6280.0, "carrying": 10125.0, "prospecting": 3020.0, "stamina": 72.0}
		RunState.cargo.copper = 1240
		RunState.cargo.ambercore = 317
		RunState.cargo.lunacore = 86
		RunState._miner_level_cache.clear()
	else:
		RunState.miner_skills.stamina = 0.0
		RunState._stamina_rest = 0.0
	main.miner_skills_panel.refresh()

func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var panel: Control = main.miner_skills_panel
	var bounds: Dictionary = {"hud_menu": _bounds(main.premium_hud.menu_button),
		"new_game": _bounds(main.premium_menu.main_card.get_node("NewGame")),
		"continue": _bounds(main.premium_menu.continue_button),
		"settings_back": _bounds(main.premium_menu.detail_card.get_node("Back")),
		"skills_close": _bounds(panel.close_button),
		"joystick": _bounds(main.movement_pad),
		"hud_mine": _bounds(main.mine_button), "hud_bag": _bounds(main.premium_hud.bag_button),
		"hud_guide": _bounds(main.premium_hud.guide_button),
		"hud_mole": _bounds(main.get_node("CompanionInterface").button)}
	for row in panel.rows + [panel.stamina_row]:
		bounds["stat_" + String(row.node.name).to_lower()] = _bounds(row.node)
	for i in 4: bounds[["inventory", "skills", "map", "settings"][i]] = _bounds(panel.nav[i])
	var close: Control = main.resource_inventory.get_node_or_null("Card/Layout/Header/Close")
	if close != null: bounds.inventory_close = _bounds(close)
	var state: Dictionary = {"skills_open": panel.visible, "map_open": panel._map_active,
		"inventory_open": main.inventory_open, "settings_open": main.premium_menu.detail_view.is_visible_in_tree(),
		"developer_tools_visible": is_instance_valid(main.developer_menu) and main.developer_menu.is_visible_in_tree(),
		"mine_input_held": main.mine_held or Input.is_action_pressed("mine"),
		"player_controls_enabled": main._active_player_node().control_enabled,
		"stamina": RunState.stamina_value(), "skill_xp": RunState.miner_skills.duplicate(true),
		"skills": RunState.miner_skill_rows(), "effort": RunState.stamina_effort_multiplier(),
		"buttons": bounds, "skills_plate": _bounds(panel.plate),
		"tooltip_visible": panel.stat_tip.visible, "tooltip_id": panel._tip_id,
		"tooltip_text": panel._tip_body.text, "tooltip_rect": _bounds(panel.stat_tip),
		"hud_context": _bounds(main.premium_hud.context_button),
		"hud_context_visible": main.premium_hud.context_button.is_visible_in_tree(),
		"hud_mine_visible": main.mine_button.is_visible_in_tree(),
		"hud_gold": _bounds(main.premium_hud.gold_cluster),
		"hud_map": _bounds(main.minimap_overlay),
		"hud_goal": _bounds(main.premium_hud.progression_goal_panel)}
	if is_instance_valid(panel.map_view):
		var rect: Rect2 = panel.map_view._map_rect
		state.map_rect = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE," + JSON.stringify(state) + ")", true)

func _bounds(control: Control) -> Array:
	var rect: Rect2 = control.get_global_rect()
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
