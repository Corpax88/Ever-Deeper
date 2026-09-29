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

var mole_target: Vector2 = Vector2.ZERO
var mole_task_key: String = ""
var mole_case: String = ""
var mole_checks: Dictionary = {}

func _command(data: Dictionary) -> void:
	if String(data.kind) == "mole_fixture":
		command_id = int(data.id)
		_mole_fixture(String(data.scenario))
		return
	if String(data.kind) == "mole_recall":
		command_id = int(data.id)
		main.get_node("CompanionInterface").active_mole().recall()
		return
	if String(data.kind) == "menu_stamina_forge":
		command_id = int(data.id)
		main._open_forge_commerce()
		return
	if String(data.kind) == "menu_stamina_reset":
		command_id = int(data.id)
		RunState.miner_skills.stamina = 0.0
		RunState._stamina_rest = 0.0
		return
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
		"dev_toggle": (_bounds(main.developer_menu.toggle_button) if is_instance_valid(main.developer_menu) else []),
		"new_game": _bounds(main.premium_menu.main_card.get_node("NewGame")),
		"continue": _bounds(main.premium_menu.continue_button),
		"shop_close": _bounds(main.commerce_panel.close_button),
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
		"stamina": RunState.stamina_value(), "stamina_bar": panel.stamina_row.bar.value,
		"physics_frame": Engine.get_physics_frames(), "stamina_rest": RunState._stamina_rest,
		"game_started": main.game_started, "shop_open": main._shop_panel_is_open(),
		"modal_active": main.menu_open or main.inventory_open or main._shop_panel_is_open() or main._companion_panel_is_open(), "skill_xp": RunState.miner_skills.duplicate(true),
		"skills": RunState.miner_skill_rows(), "skill_progress": progress, "effort": RunState.stamina_effort_multiplier(),
		"buttons": bounds, "skills_plate": _bounds(panel.plate),
		"mole_open": main._companion_panel_is_open(), "guide_open": main.premium_hud._objective_open,
		"tooltip_visible": panel.stat_tip.visible, "tooltip_id": panel._tip_id,
		"tooltip_text": panel._tip_body.text, "tooltip_rect": _bounds(panel.stat_tip),
		"hud_caption": _bounds(main.premium_hud.menu_caption),
		"hud_caption_text": main.premium_hud.menu_caption.text,
		"hud_caption_visible": main.premium_hud.menu_caption.is_visible_in_tree(),
		"dev_drawer_open": (main.developer_menu.drawer.visible if is_instance_valid(main.developer_menu) else false),
		"hud_guide_visible": main.premium_hud.guide_button.is_visible_in_tree(),
		"hud_menu_icon": main.premium_hud.menu_button.icon.resource_path,
		"hud_context": _bounds(main.premium_hud.context_button),
		"hud_context_visible": main.premium_hud.context_button.is_visible_in_tree(),
		"hud_mine_visible": main.mine_button.is_visible_in_tree(),
		"hud_gold": _bounds(main.premium_hud.gold_cluster),
		"hud_map": _rect_bounds(main.premium_hud.minimap_layout_rect()),
		"hud_goal": _bounds(main.premium_hud.progression_goal_panel)}
	if is_instance_valid(panel.map_view):
		var rect: Rect2 = panel.map_view._map_rect
		state.map_rect = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	if not mole_case.is_empty():
		var mole: Node2D = ui.active_mole()
		var world: Node2D = mole.world
		var p: Vector2 = world.get_canvas_transform()*mole_target
		var current: Dictionary = world.companion_work_target(mole_target)
		state["work"] = {"scenario":mole_case,"target":[p.x,p.y],"key":mole_task_key,"remaining":current.get("key","")==mole_task_key,"mole":mole.debug_snapshot(),"period":world.companion_work_period(),"checks":mole_checks,"feedback":mole.feedback}
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE," + JSON.stringify(state) + ")", true)

func _bounds(control: Control) -> Array:
	var rect: Rect2 = control.get_global_rect()
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func _rect_bounds(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _mole_fixture(scenario: String) -> void:
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	RunState.overhaul_progress["skills"] = {}
	mole_case=scenario
	mole_checks={}
	var world: Node2D
	if scenario.begins_with("moss"):
		main._dev_jump_mine("mossMine",1)
		_gear("worn")
		world=main.mine_world
		_require(_place_moss(Vector2.RIGHT),"moss placement")
		var cell: Vector2i = world._find_mine_target()
		mole_target=world._cell_center(cell)
		var block: Dictionary = world._make_block("copper" if scenario=="moss_ore" else "stone",int(world._current_tool().power)*3,1,"resource" if scenario=="moss_ore" else "terrain")
		world._set_block(cell,block)
		world.target_dirty=true
		mole_checks["legacy_rejected_ore"]=not world.companion_can_dig(mole_target) if scenario=="moss_ore" else true
		block.requires_tool=99
		world._set_block(cell,block)
		mole_checks["tool_gate"]=world.companion_work_target(mole_target).is_empty()
		block.requires_tool=1
		block.kind="bedrock"
		world._set_block(cell,block)
		mole_checks["bedrock"]=world.companion_work_target(mole_target).is_empty()
		block.kind="copper" if scenario=="moss_ore" else "stone"
		world._set_block(cell,block)
	elif scenario=="endless_ore":
		main._dev_jump_endless(1)
		_gear("deepcore")
		world=main.endless_world
		_require(_place_endless(Vector2.RIGHT),"endless placement")
		var index: int = world._nearest_resource_index()
		mole_target=Vector2(world.resources[index].position)
		world.resources[index].hp=int(world._current_endless_tool().power)*3
	elif scenario=="depth_ore":
		main._dev_jump_mine("mossMine",2)
		_gear("deepcore")
		world=main.depth_world
		var found: bool=false
		for index in world.rocks.size():
			if not world._rock_is_exposed(index): continue
			var point: Vector2=world.rocks[index].position
			if world.companion_work_target(point).is_empty(): continue
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				var position: Vector2=point+direction*64.0
				world.restore_position(position)
				if world.player.global_position.distance_to(position)>2.0: continue
				world.player.set_facing(-direction)
				mole_target=point
				world.rocks[index].hp=int(world._current_tool().power)*3
				world.rocks[index].shell=0
				found=true
				break
			if found: break
		_require(found,"exposed depth resource")
	else:
		main._dev_jump_surface()
		_gear("worn")
		world=main.surface_world
		world.restore_position(Vector2(812,650))
		world.player.set_facing(Vector2.UP)
		world.ore_mountain_hp=int(world._mountain_tool().power)*3
		mole_target=world._ore_mountain_hit_point(world.player.global_position)
	var task: Dictionary=world.companion_work_target(mole_target)
	_require(not task.is_empty(),"manual target accepted: "+scenario)
	mole_task_key=String(task.get("key",""))
	var mole: Node2D=world.get_node("MoleCompanion")
	mole._spawn_beside_hero()
	mole.work_hits=0
	main._refresh_hud()
