extends "res://scripts/qa/suites/dev14_review.gd"
## Explicit fixture only; browser uses actual touch against observed control bounds.
func run() -> void:
	super.run()

var shared_reference_layer: CanvasLayer

func _reload_scene() -> void:
	var tree: SceneTree = main.get_tree()
	tree.process_frame.disconnect(_frame)
	JavaScriptBridge.eval("window.DEV14_STATE=null;window.DEV14_COMMAND=''",true)
	tree.reload_current_scene()

func _command(data: Dictionary) -> void:
	if String(data.kind).begins_with("shared_"):
		command_id = int(data.id)
		var controller: Node = main.get_node("CompanionInterface")
		match String(data.kind):
			"shared_reference":
				if not is_instance_valid(shared_reference_layer):
					shared_reference_layer = CanvasLayer.new()
					shared_reference_layer.layer = 18
					main.add_child(shared_reference_layer)
					controller.ui_root.reparent(shared_reference_layer,false)
					controller.ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			"shared_candidate":
				if is_instance_valid(shared_reference_layer):
					controller.ui_root.reparent(main.get_node("HUD"),false)
					controller.ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					shared_reference_layer.queue_free()
			"shared_freeze":
				Engine.time_scale = 0.0
				main.get_tree().paused = true
				for node in main.get_tree().root.find_children("*", "", true, false):
					if node.can_process() and node.is_processing():
						canvas_observers.append(node)
						node.set_process(false)
			"shared_resume":
				Engine.time_scale = 1.0
				for node in canvas_observers:
					if is_instance_valid(node): node.set_process(true)
				canvas_observers.clear()
				main.get_tree().paused = false
			"shared_presentation_on": main._set_deepheart_presentation(true)
			"shared_presentation_off": main._set_deepheart_presentation(false)
			"shared_reload": call_deferred("_reload_scene")
		return
	if String(data.kind) not in ["skills_fixture", "skills_edge_fixture", "skill_level_up", "fatigue_fixture"]:
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
	elif fixture == "skills_edge_fixture":
		RunState.miner_skills = {"mining": 0.0, "running": 99.0, "carrying": 257500.0, "prospecting": 257499.0, "stamina": 72.0}
		RunState._miner_level_cache.clear()
	elif fixture == "skill_level_up":
		RunState._earn_miner_xp("running", 1.0)
	else:
		RunState.miner_skills.stamina = 0.0
		RunState._stamina_rest = 0.0
	main.miner_skills_panel.refresh()

func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var panel: Control = main.miner_skills_panel
	var progress: Array = []
	for row in panel.rows:
		progress.append({"level": row.level.text, "level_value": row.bar.value,
			"level_fits": row.level.get_theme_font("font").get_string_size(row.level.text, HORIZONTAL_ALIGNMENT_LEFT, -1, row.level.get_theme_font_size("font_size")).x <= row.level.size.x,
			"xp_value": row.xp_bar.value, "level_rect": _bounds(row.bar),
			"xp_rect": _bounds(row.xp_bar), "numeric_xp": row.xp != null})
	var bounds: Dictionary = {"hud_menu": _bounds(main.premium_hud.menu_button),
		"new_game": _bounds(main.premium_menu.main_card.get_node("NewGame")),
		"continue": _bounds(main.premium_menu.continue_button),
		"settings_back": _bounds(main.premium_menu.detail_card.get_node("Back")),
		"skills_close": _bounds(panel.close_button),
		"joystick": _bounds(main.movement_pad),
		"hud_mine": _bounds(main.mine_button), "hud_bag": _bounds(main.premium_hud.bag_button),
		"hud_guide": _bounds(main.premium_hud.guide_button),
		"hud_mole": _bounds(main.get_node("CompanionInterface").button),
		"mole_close": _bounds(main.get_node("CompanionInterface").journal.content.get_node("CloseJournal"))}
	for row in panel.rows + [panel.stamina_row]:
		bounds["stat_" + String(row.node.name).to_lower()] = _bounds(row.node)
	for i in 4: bounds[["inventory", "skills", "map", "settings"][i]] = _bounds(panel.nav[i])
	var close: Control = main.resource_inventory.get_node_or_null("Card/Layout/Header/Close")
	if close != null: bounds.inventory_close = _bounds(close)
	var ui: Node = main.get_node("CompanionInterface")
	for i in ui.journal.tabs.size(): bounds["mole_tab_"+str(i)] = _bounds(ui.journal.tabs[i])
	var saved_ui: int = 0
	for saved in main.presentation_hud_state:
		if saved.item == ui.ui_root: saved_ui += 1
	var state: Dictionary = {"journal_tab":ui.journal.tab,"shared_ui_visible":ui.ui_root.visible,
		"shared_ui_saved":saved_ui,"shared_ui_roots":main.get_node("HUD").find_children("CompanionUI","Control",true,false).size(),
		"skills_open": panel.visible, "map_open": panel._map_active,
		"inventory_open": main.inventory_open, "settings_open": main.premium_menu.detail_view.is_visible_in_tree(),
		"developer_tools_visible": is_instance_valid(main.developer_menu) and main.developer_menu.is_visible_in_tree(),
		"mine_input_held": main.mine_held or Input.is_action_pressed("mine"),
		"player_controls_enabled": main._active_player_node().control_enabled,
		"stamina": RunState.stamina_value(), "skill_xp": RunState.miner_skills.duplicate(true),
		"skills": RunState.miner_skill_rows(), "skill_progress": progress, "effort": RunState.stamina_effort_multiplier(),
		"buttons": bounds, "skills_plate": _bounds(panel.plate),
		"mole_open": main._companion_panel_is_open(), "guide_open": main.premium_hud._objective_open,
		"tooltip_visible": panel.stat_tip.visible, "tooltip_id": panel._tip_id,
		"tooltip_text": panel._tip_body.text, "tooltip_rect": _bounds(panel.stat_tip),
		"hud_context": _bounds(main.premium_hud.context_button),
		"hud_context_visible": main.premium_hud.context_button.is_visible_in_tree(),
		"hud_mine_visible": main.mine_button.is_visible_in_tree(),
		"hud_gold": _bounds(main.premium_hud.gold_cluster),
		"hud_map": _rect_bounds(main.premium_hud.minimap_layout_rect()),
		"hud_goal": _bounds(main.premium_hud.progression_goal_panel)}
	if is_instance_valid(panel.map_view):
		var rect: Rect2 = panel.map_view._map_rect
		state.map_rect = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE," + JSON.stringify(state) + ")", true)

func _bounds(control: Control) -> Array:
	var rect: Rect2 = control.get_global_rect()
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func _rect_bounds(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
