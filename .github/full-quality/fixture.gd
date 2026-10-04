extends "res://scripts/qa/suites/full_quality_base.gd"
## QA-only fixture: original published runtime and original QA base are retained.
func _command(data: Dictionary) -> void:
	match String(data.kind):
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
			main.hub_world.restore_position(Vector2(210,1660))
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
	var ui: Dictionary = {
		"tutorial": main.quick_tutorial.debug_snapshot(),
		"commerce": main.commerce_panel.interaction_snapshot(),
		"cargo": RunState.cargo.duplicate(),
		"menu_detail_title": main.premium_menu.detail_title.text
	}
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE.buttons,"+JSON.stringify(buttons)+");window.DEV14_STATE.quality="+JSON.stringify(ui),true)
