extends "res://scripts/qa/suites/full_quality_base.gd"
## QA-only fixture: original published runtime and original QA base are retained.
var quality_mod_result: Dictionary={}

func run() -> void:
	if "--quality-mod-persistence" in OS.get_cmdline_user_args():
		# An isolated persistent fixture has a real fresh-boot/resume distinction.
		# The inherited general review intentionally resets every boot instead.
		main.save_available=RunState.initialize_persistence("user://quality-ricochet-lifecycle.sav")
		main.persistence_active=true
		main.automated_mode=false
		main._open_start_menu()
		main.get_tree().process_frame.connect(_frame)
		previous_usec=Time.get_ticks_usec()
		return
	super.run()

func _command(data: Dictionary) -> void:
	match String(data.kind):
		"quality_mod_setup":
			main._dev_seed_victory_state()
			var built: bool=main._dev_build_all_workshops_state()
			var upgrades: Array=[]
			for i in 4:
				var status: Dictionary=RunState.workshop_status("tool_forge")
				var recipe: Dictionary=status.get("next_upgrade",{})
				if recipe.is_empty(): break
				RunState.add_resource(String(recipe.resource),int(recipe.cost),false)
				upgrades.append(RunState.upgrade_workshop("tool_forge"))
			main._dev_jump_hub()
			main._dev_jump_endless(1)
			main._on_developer_command_requested("test_ricochet")
			RunState.set_movement_speed_level(20)
			main._apply_global_movement_speed()
			quality_mod_result={"built":built,"upgrades":upgrades,"forge_level":RunState._built_workshop_level("tool_forge")}
			command_id=int(data.id)
			return
		"quality_mod_skin":
			var requested: String=String(data.skin)
			var accepted: bool=RunState.set_endless_tool_style(requested)
			var saved: bool=RunState.flush_save()
			quality_mod_result={"requested":requested,"accepted":accepted,"saved":saved,"stored":RunState.endless_tool_style}
			command_id=int(data.id)
			return
		"quality_mod_action":
			quality_mod_result={"action":String(data.action)}
			match String(data.action):
				"pause": main._open_start_menu()
				"resume": main._continue_from_menu()
				"travel":
					quality_mod_result.hub=main._dev_jump_hub()
					quality_mod_result.endless=main._dev_jump_endless(1)
				"earned":
					RunState.treasury_totals.phasecrystal=100000
					main.treasury_goal_panel.kind="phasecrystal"
					main.treasury_goal_panel._claim()
				"unequip":
					main.treasury_goal_panel.kind="phasecrystal"
					main.treasury_goal_panel._claim()
				"checkpoint":
					main._checkpoint_location()
					quality_mod_result.saved=RunState.flush_save()
			command_id=int(data.id)
			return
		"quality_goal":
			RunState.reset_run(false)
			var scenario: String = String(data.scenario)
			if scenario == "recipe":
				RunState.area_unlocked = true
				RunState.emberdeep_unlocked = true
				RunState.fourth_unlocked = true
				RunState.pickaxe_level = 5
				RunState.ember_mastery = 1
			elif scenario == "pinned":
				RunState.victory = true
				RunState.treasury_totals["prismite"] = 23000
				preload("res://scripts/state/treasury_goals.gd").pin("prismite")
			main._dev_jump_surface()
			main._refresh_hud()
			command_id = int(data.id)
			return
		"quality_preview_state":
			main._dev_seed_victory_state()
			var goals = preload("res://scripts/state/treasury_goals.gd")
			var resource: String = String(data.resource)
			RunState.treasury_goals = goals.clean({})
			RunState.treasury_totals[resource] = int(data.amount)
			main.treasury_goal_panel.open_goal(resource)
			command_id = int(data.id)
			return
		"quality_inventory":
			for index in RunState.RESOURCE_IDS.size():
				RunState.cargo[String(RunState.RESOURCE_IDS[index])] = 1000 + index * 137
			main._refresh_hud()
			command_id = int(data.id)
			return
		"quality_commerce":
			main._dev_seed_victory_state()
			var family: String = String(data.family)
			if family == "depth_forge":
				main._dev_jump_mine("mossMine",2)
				main._open_commerce(main.CommerceCatalogScript.depth_forge_config("mossMine"),"depth_forge")
			else:
				main._dev_jump_surface()
				if family == "forge": main._open_forge_commerce()
				elif family == "starforge": main._open_starforge_commerce()
			command_id = int(data.id)
			return
		"quality_exit":
			main.hub_world.restore_position(main.hub_world.treasury.ENTRY)
			main.hub_world.player.camera.reset_smoothing()
			command_id = int(data.id)
			return
	await super._command(data)

func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var buttons: Dictionary = {
		"menu_settings": _bounds(main.premium_menu.main_card.get_node("Settings")),
		"menu_achievements": _bounds(main.premium_menu.achievements_button)
	}
	if main.premium_menu.detail_card.has_node("Controls"):
		buttons["settings_controls"] = _screen_bounds(main.premium_menu.detail_card.get_node("Controls"))
	var ui: Dictionary = {
		"tutorial": main.quick_tutorial.debug_snapshot(),
		"commerce": main.commerce_panel.interaction_snapshot(),
		"cargo": RunState.cargo.duplicate(),
		"menu_detail_title": main.premium_menu.detail_title.text,
		"geometry": _quality_geometry(),
		"mod": _quality_mod_snapshot()
	}
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE.buttons,"+JSON.stringify(buttons)+");window.DEV14_STATE.quality="+JSON.stringify(ui),true)

func _quality_mod_snapshot() -> Dictionary:
	var world: Node=main.endless_world
	var visual: Node=world.player.visual
	var native: Node=visual.get("_native_worn")
	return {"result":quality_mod_result,"skin":RunState.endless_tool_style,"forge_level":RunState._built_workshop_level("tool_forge"),
		"selected":world.drill_modes.selected(),"saved":preload("res://scripts/state/treasury_goals.gd").active_mod(),"override":world.drill_modes.dev_override,
		"native":visual.native_worn_snapshot(),"sprite_visible":visual._sprite.visible,"tool_visible":is_instance_valid(native) and is_instance_valid(native.equipment) and is_instance_valid(native.equipment.tool) and native.equipment.tool.visible,
		"five_mode":world.drill_modes.five.mode,"save_available":main.save_available,"save_error":RunState.last_save_error,"load_status":RunState.last_load_status}

func _screen_bounds(control: Control) -> Array:
	var rect: Rect2 = control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,control.size)
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _label_geometry(label: Label) -> Dictionary:
	var transform: Transform2D = label.get_global_transform_with_canvas()
	return {"rect":_screen_bounds(label),"text":label.text,"visible":label.is_visible_in_tree(),
		"font_viewport":label.get_theme_font_size("font_size")*transform.y.length(),
		"lines":label.get_line_count(),"visible_lines":label.get_visible_line_count()}

func _quality_geometry() -> Dictionary:
	var goal: Control = main.premium_hud.progression_goal_panel
	var panel: Control = main.treasury_goal_panel
	var skills: Control = main.miner_skills_panel
	var result: Dictionary = {
		"goal":{"rect":_screen_bounds(goal),"action":_label_geometry(goal._action),"title":_label_geometry(goal._title),"snapshot":goal.snapshot()},
		"controls":{},"preview":{},
		"skills":{"plate":_screen_bounds(skills.plate),"portrait_visible":skills.portrait.is_visible_in_tree(),"map":skills._map_active}
	}
	for pair in [["menu",main.premium_hud.menu_button],["mine",main.mine_button],["bag",main.premium_hud.bag_button],["context",main.premium_hud.context_button],["mole",main.get_node("CompanionInterface").button]]:
		result.controls[pair[0]]={"rect":_screen_bounds(pair[1]),"visible":pair[1].is_visible_in_tree()}
	result.preview={"panel":_screen_bounds(panel.panel),"detail":_label_geometry(panel.detail),"source":_label_geometry(panel.source),"title":_label_geometry(panel.title),
		"claim":{"rect":_screen_bounds(panel.claim_button),"visible":panel.claim_button.is_visible_in_tree(),"disabled":panel.claim_button.disabled},
		"pin":{"rect":_screen_bounds(panel.pin_button),"visible":panel.pin_button.is_visible_in_tree(),"disabled":panel.pin_button.disabled},
		"close":{"rect":_screen_bounds(panel.close_button),"visible":panel.close_button.is_visible_in_tree()}}
	if is_instance_valid(skills.map_view):
		var rect: Rect2 = skills.map_view.get_global_transform_with_canvas() * skills.map_view._map_rect
		result.skills["map_rect"] = [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
		result.skills["map_snapshot"] = skills.map_view.debug_snapshot()
	return result
