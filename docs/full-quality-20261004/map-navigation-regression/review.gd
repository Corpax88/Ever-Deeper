extends SceneTree
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: push_error(label)
func run() -> void:
	await process_frame
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 6: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence("/workspace/scratch/72d2364e7fd1/ux-map-check/isolated-save.json")
	state.reset_run(false)
	main._dev_ensure_playing()
	main._open_miner_skills()
	main._show_expanded_map()
	var map: Control = main.miner_skills_panel.map_view
	check("fresh surface routes and camps",map._phase=="surface" and map.navigation_routes.size()==2 and map.navigation_areas.size()==3)
	check("locked territory not mapped",map.navigation_bounds.end.x<1500)
	check("map snapshot does not label original mini markers",main.minimap_overlay.markers.all(func(m): return not m.has("label")))
	main._close_miner_skills()
	main._dev_seed_victory_state()
	main._dev_jump_hub()
	main.hub_world.treasury.enter()
	state.treasury_goals.pinned="wallet_gold"
	main._open_miner_skills()
	main._show_expanded_map()
	map=main.miner_skills_panel.map_view
	check("treasury actual snapshot and no terrain",map._phase=="treasury" and map.cartography==null and map._world_rect.size==Vector2(4000,3200))
	check("treasury exact podiums exit and deposit",map.markers.size()==29 and map.markers.filter(func(m): return m.kind=="podium").size()==27)
	check("treasury actual room outline and no stale surface routes",map.navigation_areas.size()==1 and map.navigation_routes.is_empty() and not map.navigation_bounds.has_area())
	check("treasury real player and pinned objective",map._player_position==main.hub_world.player.global_position and map._has_objective and map._objective_position==main.hub_world.treasury.bay(26))
	check("map pauses treasury world",main.menu_open and not main.hub_world.active)
	main._close_miner_skills()
	main.hub_world.treasury.leave()
	main._dev_jump_surface()
	main._open_miner_skills()
	main._show_expanded_map()
	map=main.miner_skills_panel.map_view
	check("unlocked surface draws all authored branches",map._phase=="surface" and map.navigation_routes.size()==11 and map.navigation_areas.size()==3)
	check("treasury podiums do not leak into surface",map.markers.all(func(m): return m.kind!="podium") and not map.markers.any(func(m): return m.kind=="locked"))
	main._close_miner_skills()
	main._dev_jump_mine("moonMine",2)
	main._open_miner_skills()
	main._show_expanded_map()
	map=main.miner_skills_panel.map_view
	check("underground keeps exploration owner",map._phase=="depth" and map.cartography==main.exploration_map and map.cartography.texture!=null)
	check("underground has no stale surface metadata",map.navigation_routes.is_empty() and map.navigation_areas.is_empty() and not map.navigation_bounds.has_area())
	main._close_miner_skills()
	check("map close resumes correct depth world",not main.menu_open and main.depth_world.active)
	var passed: bool = checks.all(func(c): return c.passed)
	FileAccess.open("/workspace/scratch/72d2364e7fd1/ux-map-check/checks.json",FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	print("UX_MAP_CHECKS_OK" if passed else "UX_MAP_CHECKS_FAILED")
	quit(0 if passed else 2)
