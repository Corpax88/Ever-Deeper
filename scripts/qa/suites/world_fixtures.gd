extends "res://scripts/qa/qa_context.gd"
## World fixtures checks moved intact from main.gd.


func _start_qa_mine() -> void :


	if "--qa-up" in OS.get_cmdline_user_args():
		RunState.pickaxe_level = 4
	main._enter_mine("mossMine")
	if session.has_any_arg(OS.get_cmdline_user_args(), ["--qa-camera", "--qa-performance"]):
		for col in range(4, 40):
			for row in range(11, 15):
				main.mine_world.blocks.erase(Vector2i(col, row))
		main.mine_world.player.global_position = Vector2(300, 624)
		main.mine_world.player.movement_speed = 80.0
		main.mine_world.player.set_facing(Vector2.RIGHT)
		main.mine_world.player.camera.reset_smoothing()
		main.mine_world.player.set_external_movement(Vector2.RIGHT)
		if "--qa-performance" in OS.get_cmdline_user_args():
			session.performance_qa_active = true
	elif "--qa-up" in OS.get_cmdline_user_args():
		main.mine_world.player.global_position = Vector2(230, 560)
		main.mine_world.player.set_facing(Vector2.UP)
		main.mine_world.player.camera.reset_smoothing()
		main.mine_world.set_mine_held(true)
	elif "--qa-swing" in OS.get_cmdline_user_args():
		main.mine_world.set_mine_held(true)


func _start_qa_barrier() -> void :
	RunState.reset_run(false)
	main._enter_mine("mossMine", false, false)
	main.mine_world.restore_position(Vector2(1165, 640))
	main.mine_world.player.set_facing(Vector2.RIGHT)
	main.mine_world.target_dirty = true
	main.objective_label.text = "IRONBOUND COLLAPSE · THREE AUTHORED ROCKS"
	main._set_status("QA · exact barrier collision · Runed Pickaxe required")
	main._refresh_hud()


func _start_qa_surface_camp() -> void :
	DisplayServer.window_set_title("Ever Deeper · Mossvein Camp QA")
	RunState.reset_run(false)
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.surface_world.set_active(true)
	main.surface_world.restore_position(Vector2(240, 680))
	main.surface_world.player.set_facing(Vector2.RIGHT)
	main.objective_label.text = "MOSSVEIN CAMP · FORGE AND ASSAY"
	main._set_status("QA · camp composition, paths, stations and living environment")
	main._refresh_hud()


func _start_qa_moss_overview() -> void :
	DisplayServer.window_set_title("Ever Deeper · Full Mossvein Composition QA")
	RunState.reset_run(false)
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.surface_world.set_active(true)
	main.surface_world.restore_position(Vector2(567, 640))
	main.surface_world.player.control_enabled = false

	main.surface_world.player.camera.zoom = Vector2.ONE * 0.35
	main.surface_world.player.camera.position_smoothing_enabled = false
	main.surface_world.player.camera.reset_smoothing()
	main.get_node("HUD").visible = false


func _start_qa_surface_context(context: String) -> void :
	DisplayServer.window_set_title("Ever Deeper · Surface Context QA")
	RunState.reset_run(false)
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.surface_world.set_active(true)
	if context == "sell":
		RunState.add_resource("stone", 4)
		RunState.add_resource("copper", 3)
		main.surface_world.restore_position(main.surface_world.station_interaction_position("sell"))
	elif context == "forge":
		RunState.gold = int(RunState.next_pickaxe().cost)
		main.surface_world.restore_position(main.surface_world.station_interaction_position("forge"))
	else:
		main.surface_world.restore_position(main.surface_world._mine_entrance("mossMine"))
	main._refresh_hud()


func _start_qa_surface_decor() -> void :
	DisplayServer.window_set_title("Ever Deeper · Mossvein Decor QA")
	RunState.reset_run(false)
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.surface_world.set_active(true)


	main.surface_world.restore_position(Vector2(790, 820))
	main.surface_world.player.set_facing(Vector2.DOWN)
	main.objective_label.text = "MOSSVEIN · DESCENT TO THE MINE"
	main._set_status("QA · readable branch, living forest edges and a clear mine destination")
	main._refresh_hud()


func _start_qa_surface(mode: String) -> void :
	if mode == "open_gate":
		DisplayServer.window_set_title("Ever Deeper · Open Moonglass Gate QA")
	RunState.reset_run(false)
	if mode == "gate_ready":
		RunState.pickaxe_level = 3
		RunState.gold = 120
	if mode in ["open_gate", "moon_surface", "moon_mine"]:
		RunState.pickaxe_level = 3
		RunState.unlock_world("moonglass")
	if mode == "moon_mine":
		main._enter_mine("moonMine")
		return
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.surface_world.set_active(true)
	var qa_position: Vector2 = (
		Vector2(980, 650)
		if mode in ["gate", "gate_ready"]
		else Vector2(1165, 650)
		if mode == "open_gate"
		else main.surface_world._mine_entrance("moonMine")
	)
	main.surface_world.restore_position(qa_position)
	main.objective_label.text = main._surface_objective()
	main._set_status("QA · gate ready to open" if mode == "gate_ready" else "QA · locked Moonglass Gate" if mode == "gate" else "QA · opened Moonglass passage" if mode == "open_gate" else "QA · Moonglass surface and mine entrance")


func _start_qa_surface_mountain(damaged: bool = false) -> void :
	DisplayServer.window_set_title("Ever Deeper · Copper Ridge Damage QA" if damaged else "Ever Deeper · Copper Ridge QA")
	RunState.reset_run(false)
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.surface_world.set_active(true)
	main.surface_world.restore_position(Vector2(600, 700))
	if damaged:
		main.surface_world.ore_mountain_hp = 108
		main.surface_world._update_ore_mountain(0.0)
	main.surface_world.player.set_facing(Vector2.DOWN)
	main.objective_label.text = "COPPER RIDGE · SURFACE QUARRY"
	main._set_status("QA · hold MINE to quarry Copper and Gold")
	main._refresh_hud()


func _start_qa_surface_mountains(mountain_id: String = "moonglass_mountain") -> void :
	var profiles= {
		"moonglass_mountain": {
			"name": "Moonglass Mountain", "world": "moonglass", "pickaxe": 3,
			"position": Vector2(1665, 575), "vein": "Bloom",
		},
		"emberdeep_mountain": {
			"name": "Emberdeep Mountain", "world": "emberdeep", "pickaxe": 4,
			"position": Vector2(3078, 1030), "vein": "Fault",
		},
		"starfall_mountain": {
			"name": "Starfall Mountain", "world": "starfall", "pickaxe": 5,
			"position": Vector2(4020, 1042), "vein": "Lattice",
		},
	}
	var profile: Dictionary = Dictionary(profiles.get(mountain_id, profiles.moonglass_mountain))
	DisplayServer.window_set_title("Ever Deeper · %s QA" % String(profile.name))
	RunState.reset_run(false)
	RunState.pickaxe_level = int(profile.pickaxe)
	if mountain_id == "starfall_mountain":
		RunState.ember_mastery = 5
	RunState.unlock_world(String(profile.world))
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.deepheart_world.set_active(false)
	main.endless_world.set_active(false)
	main.surface_world.reset_for_new_run()
	main.surface_world.set_active(true)
	main.surface_world.restore_position(Vector2(profile.position))
	main.surface_world.player.set_facing(Vector2.UP)
	main.surface_world.player.camera.position_smoothing_enabled = false
	main.surface_world.player.camera.reset_smoothing()
	main.objective_label.text = "%s · INDEPENDENT QUARRY" % String(profile.name).to_upper()
	main._set_status("QA · the mountain reacts only to its own hits; the %s stays separate" % String(profile.vein))
	main._refresh_hud()


func _start_qa_moon_resource() -> void :
	DisplayServer.window_set_title("Ever Deeper · Moonglass Bloom QA")
	RunState.reset_run(false)
	RunState.unlock_world("moonglass")
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.surface_world.set_active(true)
	main.surface_world.restore_position(Vector2(1820, 800))
	main.surface_world.player.set_facing(Vector2.UP)
	main.objective_label.text = "MOONGLASS BLOOM · BREAK THREE CRYSTALS IN 18 SECONDS"
	main._set_status("QA · original timed Bloom · physical Moonglass and Starshard drops")
	main._refresh_hud()


func _start_qa_surface_resource(resource_id: String) -> void :
	RunState.reset_run(false)
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.surface_world.set_active(true)
	if resource_id == "ember_fault":
		DisplayServer.window_set_title("Ever Deeper · Ember Fault QA")
		RunState.pickaxe_level = 4
		RunState.unlock_world("emberdeep")
		main.surface_world.restore_position(Vector2(3078, 1150))
		main.surface_world.player.set_facing(Vector2.UP)
		main.objective_label.text = "EMBER FAULT · BREAK THE PRESSURE VENTS IN 22 SECONDS"
		main._set_status("QA · armored heat fault · physical Emberstone and Sunslag drops")
	else:
		DisplayServer.window_set_title("Ever Deeper · Starfall Lattice QA")
		RunState.pickaxe_level = 5
		RunState.ember_mastery = 5
		RunState.unlock_world("starfall")
		RunState.set_starforge_variant("crusher")
		main.surface_world.restore_position(Vector2(3810, 1050))
		main.surface_world.player.set_facing(Vector2.UP)
		main.objective_label.text = "STARFALL LATTICE · DISCHARGE THREE ANCHORS IN 20 SECONDS"
		main._set_status("QA · charged astral lattice · physical Astralite and Crownstone drops")
	main._refresh_hud()


func _start_qa_surface_performance() -> void :
	DisplayServer.window_set_title("Ever Deeper · Emberdeep Surface Performance QA")
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.hub_world.set_active(false)
	main.deepheart_world.set_active(false)
	main.endless_world.set_active(false)
	main.surface_world.reset_for_new_run()
	main.surface_world.set_active(true)
	var ember_route: Array = main.surface_world.LATER_MINE_BRANCH_ROUTES.emberMine
	var edge_start: Vector2 = Vector2(ember_route[3])
	var edge_end: Vector2 = Vector2(ember_route[4])
	var edge_tangent: Vector2 = (edge_end - edge_start).normalized()
	var edge_normal: Vector2 = Vector2( - edge_tangent.y, edge_tangent.x)
	var edge_position: Vector2 = (edge_start + edge_end) * 0.5 + edge_normal * (main.surface_world.LATER_BRANCH_ROUTE_HALF_WIDTH - 0.25)
	main.surface_world.restore_position(edge_position)
	main.surface_world.player.set_facing(edge_tangent)
	main.surface_world.player.set_external_movement((edge_tangent + edge_normal * 0.65).normalized())
	main.surface_world.player.camera.position_smoothing_enabled = false
	main.surface_world.player.camera.reset_smoothing()
	session.performance_qa_mode = "ember_surface"
	session.performance_qa_active = true
	main.objective_label.text = "EMBERDEEP WORKS · MOBILE PERFORMANCE"
	main._set_status("QA · mountain, Fault and both biome seams visible together")
	main._refresh_hud()


func _start_qa_starforge() -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.unlock_world("starfall")
	RunState.cargo.astralite = 200
	RunState.cargo.crownstone = 200
	main.phase = "surface"
	main.mine_world.set_active(false)
	main.depth_world.set_active(false)
	main.surface_world.set_active(true)
	main.surface_world.restore_position(main.surface_world._station_position("starforge") + Vector2(0, 70))
	main.objective_label.text = main._surface_objective()
	main._set_status("QA · Starforge ready · choose one final pickaxe form")
	main._refresh_hud()


func _start_qa_rootwound(mode: String) -> void :
	RunState.reset_run(false)
	RunState.mark_depth_entrance_discovered("mossMine")
	if mode != "locked":
		RunState.pickaxe_level = 5
		RunState.ember_mastery = 5
		RunState.set_starforge_variant("crusher")
	if mode == "drill":
		RunState.set_drill_level(1)
	main._enter_mine("mossMine", false, false)
	main.mine_world.restore_position(Vector2(main.mine_world.depth_entrance) + Vector2(92, 0))
	main._enter_depth(true, false)
	if mode == "performance":
		session.performance_qa_mode = "rootwound"
		session.performance_qa_active = true
		main.depth_world.player.set_external_movement(Vector2.LEFT)
	main._set_status("QA · Rootwound locked without Starforge" if mode == "locked" else "QA · Burrower Drill and Burrowsteel" if mode == "drill" else "QA · complete Mossvein to Rootwound transition" if mode == "loop" else "QA · Starforge Rootwound mining")


func _start_qa_prismatic() -> void :
	RunState.reset_run(false)
	RunState.unlock_world("moonglass")
	RunState.mark_depth_entrance_discovered("moonMine")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(1)
	main._enter_mine("moonMine", false, false)
	main.mine_world.restore_position(Vector2(main.mine_world.depth_entrance) + Vector2(92, 0))
	main._enter_depth(true, false)
	main._set_status("QA · Prismatic Depths · Burrower to Pulse Drill route")


func _start_qa_endgame_depth(mine_id: String, qa_drill_level: int, measure_performance: bool = false) -> void :
	RunState.reset_run(false)
	RunState.unlock_world(String(main.WORLD_BY_MINE[mine_id]))
	RunState.mark_depth_entrance_discovered(mine_id)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(qa_drill_level)
	main._enter_mine(mine_id, false, false)
	main.mine_world.restore_position(Vector2(main.mine_world.depth_entrance) + Vector2(92, 0))
	main._enter_depth(true, false)
	RunState.set_location(mine_id, main.depth_world.player.global_position, 2)
	if measure_performance:
		session.performance_qa_mode = "molten"
		session.performance_qa_active = true
		main.depth_world.player.set_external_movement(Vector2.LEFT)
	if mine_id == "starMine":
		DisplayServer.window_set_title("Ever Deeper · Voidstar Deepcore QA")
		main._set_status("QA · Voidstar Deep · mine a true Singularity Core")
	else:
		DisplayServer.window_set_title("Ever Deeper · Molten Depths QA")
		main._set_status("QA · Molten Depths · Pulse Drill and Infernium gates")


func _start_qa_hub() -> void :
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.mark_depth_entrance_discovered("starMine")
	RunState.enter_depth("starMine")
	RunState.set_location("starMine", Vector2(1704, 5160), 2)
	RunState.record_mined("singularity", 1)
	assert (RunState.secure_singularity("singularity"))
	RunState.gold = 1000
	RunState.cargo.stone = 100
	RunState.set_location("surface", Vector2(4245, 650))
	main.surface_world.restore_position(Vector2(4245, 650))
	main._enter_hub(true, false)
	DisplayServer.window_set_title("Ever Deeper · Base Hub QA")
	main._set_status("QA · permanent base · museum, workshops, and return without resetting")


func _start_qa_deepheart() -> void :
	RunState.reset_run(false)
	RunState.unlock_world("starfall")
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.set_drill_level(3)
	RunState.current_scene = "starMine"
	RunState.current_depth = 2
	RunState.record_mined("singularity", 1)
	assert (RunState.secure_singularity("singularity"))
	RunState.cargo.ambercore = 3
	RunState.cargo.lunacore = 3
	RunState.cargo.furnaceheart = 3
	RunState.cargo.singularity = 1
	for resource_id_value in ["ambercore", "lunacore", "furnaceheart", "singularity"]:
		var resource_id= String(resource_id_value)
		assert (bool(RunState.deliver_deep_elevator_material(resource_id, int(RunState.cargo[resource_id])).get("ok", false)))
	assert (RunState.power_deep_elevator())
	main.game_started = true
	main._enter_hub(false, false)
	main.hub_world.restore_position(Vector2(720, 280))
	main._enter_deepheart(true, false)
	RunState.set_location("deepheart", main.deepheart_world.player.global_position, 1)
	DisplayServer.window_set_title("Ever Deeper · Deepheart Finale QA")
	main._set_status("Four worlds are ready · awaken one resonance at a time")

