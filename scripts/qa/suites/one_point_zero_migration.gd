extends "res://scripts/qa/suites/one_point_zero.gd"
## Explicit pre-1.0 schema fixtures taken from v0.46.9 serialize() field names.
## They contain no stream anchor or compact chunk journal.


func _old_relic(depth: int, placed: bool) -> Dictionary:
	return {"discovered": true, "collected": true, "placed": placed, "found_depth": depth}


func _legacy_payload(mature: bool) -> Dictionary:
	var save: Dictionary = RunState.serialize()
	var state: Dictionary = Dictionary(save.state)
	var relics: Dictionary = {}
	var workshops: Dictionary = {}
	for id in RunState.ENDLESS_RELIC_IDS:
		relics[String(id)] = {"discovered": false, "collected": false, "placed": false, "found_depth": 0}
	for id in RunState.ENDLESS_WORKSHOP_IDS:
		workshops[String(id)] = {"built": false, "level": 0, "style": "original", "delivered": 0}
	relics["forge_heart"] = _old_relic(1, true)
	workshops["tool_forge"] = {"built": true, "level": 2, "style": "riveted", "delivered": 200}
	var carried: Dictionary = {"id": "ancient_lens", "origin_depth": 3, "current_depth": 3, "attached": true}
	relics["ancient_lens"] = _old_relic(3, false)
	if mature:
		for index in 5:
			relics[String(RunState.ENDLESS_RELIC_IDS[index])] = _old_relic([1, 3, 5, 8, 12][index], true)
			workshops[String(RunState.ENDLESS_WORKSHOP_IDS[index])] = {"built": true, "level": 5, "style": "deepheart", "delivered": 200}
		carried = {"id": "", "origin_depth": 0, "current_depth": 0, "attached": false}
	state["endless_descent"] = {
		"active": not mature, "current_depth": 0 if mature else 3,
		"deepest_depth": 12 if mature else 3, "start_depth_checkpoint": 12 if mature else 1,
		"resource_exhausted_through": 12 if mature else 2,
		"active_floor_depth": 0 if mature else 3,
		"active_floor_mined_mask": 0 if mature else 16,
		"active_floor_site_mask": 0 if mature else 34,
		"relics": relics, "carried_relic": carried, "workshops": workshops,
		"light_style": "deepheart" if mature else "standard",
		"outfit": "deepheart" if mature else "miner",
		"tool_style": "deepheart" if mature else "crusher",
	}
	var overhaul: Dictionary = Dictionary(state.get("overhaul", {}))
	overhaul["dug"] = {"1": [253], "3": [294, 335]}
	state["overhaul"] = overhaul
	var location: Dictionary = Dictionary(state.location)
	location["scene"] = "hub" if mature else "endless"
	location["depth"] = 1
	location["x"] = 700.0
	location["y"] = 700.0
	state["location"] = location
	state["cargo"]["deep_alloy"] = 73
	state["cargo"]["lumenstone"] = 19
	save["state"] = state
	return save


func run() -> void:
	if not _new_player_to_deep():
		_finish("migration")
		return
	var partial: Dictionary = _legacy_payload(false)
	RunState.reset_run(false)
	if not _check(RunState.deserialize(partial), "Prior active floor schema loads"):
		_finish("migration")
		return
	_check(RunState.current_scene == "endless", "Prior active scene retained")
	_check(int(RunState.endless_descent_status().current_depth) == 3, "Prior active depth retained")
	_check(bool(RunState.relic_status("ancient_lens").attached), "Prior carried relic remains attached")
	_check(bool(RunState.relic_status("forge_heart").placed), "Prior placed relic retained")
	_check(bool(RunState.workshop_status("tool_forge").built) and int(RunState.workshop_status("tool_forge").level) == 2, "Prior paid workshop level retained")
	_check(String(RunState.endless_loadout_status().tool) == "crusher", "Prior unlocked equipment style retained")
	_check(RunState.endless_dug_cells(1).has(253) and RunState.endless_dug_cells(3).has(294) and RunState.endless_dug_cells(3).has(335), "Legacy excavation arrays survive compact migration")
	_check((int(RunState.endless_floor_resource_state(3).mined_mask) & 16) != 0, "Legacy active resource depletion retained")
	var site: Dictionary = RunState.endless_floor_site_state(3, 1)
	_check(bool(site.resolved) and String(site.choice) == "overload", "Legacy claimed cache cannot be reclaimed")
	_check(bool(RunState.endless_floor_resource_state(2).exhausted), "Legacy exhausted floors cannot duplicate resources")
	main._restore_saved_location()
	var world: Node = main.endless_world
	_check(main.phase == "endless" and bool(world.active), "Prior active save restores live continuous world")
	_check(int(RunState.endless_descent_status().current_depth) == 3 and int(world.current_depth) == 3, "Actual legacy scene restoration preserves original depth band")
	_check(not world.collision_at(world.player.global_position), "Legacy position migrates to safe walkable space")
	var saved: Dictionary = RunState.serialize()
	RunState.reset_run(false)
	_check(RunState.deserialize(saved), "Migrated save round trips")
	_check(int(RunState.cargo.deep_alloy) == 73 and int(RunState.cargo.lumenstone) == 19, "Migration preserves exact resource inventory")
	_check(RunState.reach_endless_depth(4), "Attached relic can move deeper in continuous terrain")
	RunState.set_location("endless", Vector2(960, 1700))
	saved = RunState.serialize()
	RunState.reset_run(false)
	_check(RunState.deserialize(saved), "Deeper carrying save reloads")
	_check(int(RunState.relic_status("ancient_lens").current_depth) == 4 and int(RunState.endless_descent_status().current_depth) == 4, "Deeper carrying is not clamped back to original relic band")
	RunState.detach_carried_relic()
	var detached: Dictionary = RunState.serialize()
	var rejected: Dictionary = RunState.tunnel_home_endless_descent()
	_check(not bool(rejected.get("ok", true)), "Detached relic blocks Tunnel Home")
	_check(RunState.relic_status("ancient_lens").carried and int(RunState.endless_descent_status().current_depth) == 4, "Rejected Tunnel Home loses neither relic nor location")
	_check(Dictionary(detached.state).get("cargo") == Dictionary(RunState.serialize().state).get("cargo"), "Rejected Tunnel Home preserves cargo")
	var mature: Dictionary = _legacy_payload(true)
	world.set_active(false)
	main.phase = "surface"
	RunState.reset_run(false)
	_check(RunState.deserialize(mature), "Prior complete-Hub schema loads")
	var status: Dictionary = RunState.endless_descent_status()
	_check(int(status.placed_relic_count) == 5 and int(status.built_workshop_count) == 5, "Prior five relics and complete Hub preserved")
	_check(String(RunState.endless_loadout_status().outfit) == "deepheart", "Prior wardrobe selection preserved")
	_check(not bool(status.exploration_complete), "Prior complete Hub can keep mining")
	main._restore_saved_location()
	main._enter_endless(true, false)
	_check(main.phase == "endless" and int(RunState.endless_descent_status().current_depth) == 12, "Prior final workshop checkpoint becomes usable tunnel resume")
	_check(not main.endless_world.collision_at(main.endless_world.player.global_position), "Prior checkpoint resumes safely")
	_finish("migration")
