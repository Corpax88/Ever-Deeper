extends "res://scripts/qa/suites/one_point_zero.gd"
## Visible HUD counters are inspected synchronously after state transactions.


func _snapshot() -> Dictionary:
	return main.premium_hud.progression_goal_snapshot()


func _row(resource_id: String, snapshot: Dictionary) -> Dictionary:
	for value in Array(snapshot.get("requirements", [])):
		if String(Dictionary(value).get("resource_id", "")) == resource_id:
			return Dictionary(value)
	return {}


func _rendered(id: String, snapshot: Dictionary) -> Dictionary:
	for value in Array(snapshot.get("rendered_rows", [])):
		if String(Dictionary(value).get("id", "")) == id:
			return Dictionary(value)
	return {}


func _touch(index: int, pressed: bool, position: Vector2, canceled: bool = false) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.position = position
	event.canceled = canceled
	main.get_viewport().push_input(event, true)


func _recipe_geometry(drill_level: int, expected_rows: int) -> void:
	# Funding is a fixture; goal choice and all rendered recipe rows are real.
	main._dev_seed_all_zones_state()
	RunState.victory = false
	RunState.singularity_secured = false
	RunState.set_drill_level(drill_level)
	RunState.mark_hub_tutorial_seen()
	RunState.gold = 17320
	var recipe: Dictionary = RunState.next_drill_recipe()
	for value in Array(recipe.get("requirements", [])):
		var requirement: Dictionary = Dictionary(value)
		RunState.cargo[String(requirement.type)] = maxi(1, int(requirement.amount) / 3)
	RunState.cargo["copper"] = 14
	RunState.changed.emit()
	main._enter_mine("emberMine", false, false)
	main._enter_depth(false, false)
	main._refresh_hud()
	_check(Array(_snapshot().get("requirements", [])).size() == expected_rows, "Geometry fixture uses complete %d-row drill recipe" % expected_rows)
	var hud: Control = main.premium_hud
	var content_scale: float = float(ProjectSettings.get_setting("display/window/stretch/scale", 1.0))
	var logical_height: float = float(ProjectSettings.get_setting("display/window/size/viewport_height", 720)) / content_scale
	for css_size in [Vector2(844, 390), Vector2(956, 440)]:
		var logical_size: Vector2 = Vector2(logical_height * css_size.x / css_size.y, logical_height)
		var layout: Dictionary = hud.apply_iphone_layout_for_test(logical_size)
		await main.get_tree().process_frame
		await main.get_tree().process_frame
		var panel: Rect2 = Rect2(_snapshot().panel_rect)
		var map: Rect2 = Rect2(main.minimap_overlay.debug_snapshot().map_rect)
		_check(panel.has_area() and Rect2(layout.safe_rect).encloses(panel), "Actual recipe panel stays inside scaled iPhone safe area")
		_check(Rect2(layout.progression_goal).grow(1.0).encloses(panel), "Container sizing cannot silently expand the assigned goal rect")
		_check(map.is_equal_approx(Rect2(layout.minimap)), "Rendered minimap consumes same applied safe-area layout")
		_check(not panel.intersects(map), "Actual recipe goal never overlays minimap")
		_check(Rect2(layout.safe_rect).encloses(map), "Relocated minimap remains inside iPhone safe area")
		for action in ["gold", "context", "bag", "mine"]:
			_check(not panel.intersects(Rect2(layout[action])), "%d-row goal clears %s" % [expected_rows, action])
		var controls: Dictionary = hud.progression_goal_panel._row_controls
		_check(controls.size() == expected_rows, "All recipe requirement controls remain present")
		for value in controls.values():
			var row: Dictionary = Dictionary(value)
			for name in ["icon", "label", "counter"]:
				var control: Control = row[name]
				_check(control.size.x > 0.0 and control.size.y > 0.0 and panel.grow(1.0).encloses(control.get_global_rect()), "Visible goal " + name + " stays within panel")
	hud._apply_platform_safe_area()


func run() -> void:
	main._start_new_game()
	main._refresh_hud()
	var initial: Dictionary = _snapshot()
	_check(bool(initial.get("visible", false)), "Fresh player sees goal panel")
	_check(not bool(initial.get("input_blocking", true)), "Goal and all descendants pass touch input")
	_check(main.mine_button.icon != null and String(main.mine_button.icon.resource_path).contains("pickaxe"), "Mining action uses actual pickaxe asset")
	var cost: int = int(_row("gold", initial).get("required", 0))
	_check(cost > 0, "Fresh upgrade displays real currency cost")
	RunState.add_resource("copper", 1, true)
	var pickup: Dictionary = _snapshot()
	var currency: Dictionary = _row("gold", pickup)
	var pending: int = int(RunState.assay_sale_snapshot().total)
	_check(int(currency.get("pending_sale", -1)) == pending and pending > 0, "Ore pickup immediately shows actual pending assay value")
	_check(int(currency.get("owned", -1)) == 0 and not bool(currency.get("ready", true)), "Unsold ore never counts as spendable gold")
	_check(String(_rendered("currency:gold", pickup).get("text", "")).contains("(+%d)" % pending), "Rendered currency counter changes on same signal")
	RunState.add_resource("deep_alloy", 200, false)
	_check(int(_row("gold", _snapshot()).get("pending_sale", -1)) == pending, "Protected progression materials excluded from sale preview")
	RunState.add_resource("copper", cost, true)
	var ready_to_sell: Dictionary = _snapshot()
	_check(int(_row("gold", ready_to_sell).get("pending_sale", 0)) >= cost, "Live haul can close next purchase cost")
	_check(not bool(ready_to_sell.get("requirements_ready", true)), "Sale needed before purchase is marked ready")
	RunState.sell_all()
	var sold: Dictionary = _snapshot()
	_check(bool(sold.get("requirements_ready", false)) == bool(RunState.forge_purchase_snapshot("pickaxe").ready), "Displayed readiness agrees with purchase authority after sale")
	_check(int(_row("gold", sold).get("owned", -1)) == RunState.gold, "Sold gold immediately replaces pending value")
	_check(int(_row("gold", sold).get("pending_sale", -1)) == 0, "Pending value clears after sale")
	var old_goal: String = String(sold.get("objective_id", ""))
	_check(RunState.upgrade_pickaxe(), "Ready goal can perform its purchase")
	_check(String(_snapshot().get("objective_id", "")) != old_goal, "Successful purchase immediately advances goal")
	if not _new_player_to_deep():
		_finish("ui")
		return
	RunState.start_endless_descent()
	RunState.discover_endless_relic("forge_heart", 1)
	RunState.collect_endless_relic("forge_heart", 1)
	RunState.attach_carried_relic("forge_heart")
	RunState.tunnel_home_endless_descent()
	RunState.set_location("hub", main.hub_world.entry_spawn())
	_check(bool(RunState.place_carried_relic().get("ok", false)), "Workshop HUD fixture places real relic state")
	RunState.cargo.deep_alloy = 0
	RunState.add_resource("deep_alloy", 199, true)
	var supplied: Dictionary = _snapshot()
	_check(Array(supplied.get("requirements", [])).is_empty(), "Relic-ready workshop has no repeat material bill")
	_check(String(supplied.get("hud_action", "")).contains("materials supplied"), "HUD explains the earned construction immediately")
	_check(String(supplied.get("kind", "")) == "workshop", "Guide leads to the ready workshop instead of another mining trip")
	_check(bool(RunState.workshop_status("tool_forge").ready_to_build), "Relic construction is already funded")
	RunState.build_workshop("tool_forge")
	_check(int(RunState.cargo.deep_alloy) == 199, "Building from a relic leaves mined upgrade materials intact")
	_check(RunState.endless_tool_power_multiplier() > 1.0 and RunState.endless_tool_speed_multiplier() > 1.0, "First discovery improves real tool power and speed")
	_check(String(_snapshot().get("workshop_id", "")) != "tool_forge" or String(_snapshot().get("kind", "")) != "workshop", "Build removes completed build goal")
	main._enter_endless(true, false)
	main.endless_world.restore_position(main.endless_world.entry_spawn())
	main._refresh_hud()
	main._refresh_context_button()
	await main.get_tree().process_frame
	var mine: Button = main.mine_button
	var point: Vector2 = mine.get_global_rect().get_center()
	_touch(21, true, point)
	_check(main.mine_held and main.endless_world.external_mine_held, "Real touch holds mining in The Deep")
	_touch(21, false, point, true)
	_check(not main.mine_held and not main.endless_world.external_mine_held, "Canceled touch releases Deep mining")
	main.automated_mode = false
	_touch(22, true, point)
	main._open_start_menu()
	_check(main.menu_open and not main.mine_held and not main.endless_world.external_mine_held, "Opening settings cancels held mining")
	_check(not main.request_tunnel_home(), "Paused menu blocks Tunnel Home")
	main._perform_context()
	_check(not main.tunnel_home_in_progress, "Hidden context action cannot tunnel behind settings")
	_touch(22, false, point)
	main._continue_from_menu()
	main.automated_mode = true
	_check(not main.mine_held and not main.endless_world.external_mine_held, "Closing menu never resumes stale held touch")
	_check(not bool(_snapshot().get("input_blocking", true)), "Late-game goal remains touch transparent")
	await _recipe_geometry(1, 4)
	await _recipe_geometry(2, 5)
	_finish("ui")
