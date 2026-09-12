extends "res://scripts/qa/suites/one_point_zero.gd"
## Real generated terrain + held mining + player motion, with fixture placement
## only when inspecting a relic/pedestal. No force-granted relics or workshops.

var world: Node
var travelled_metres: Array[int] = []
var seam_positions: Array[Vector2] = []


func _claim_integrity() -> bool:
	_freeze_world()
	var entrance: Vector2 = world.player.global_position
	if not _check(not Array(world.resources).is_empty(), "Generated ore deposits exist"):
		return false
	var resource: Dictionary = Dictionary(world.resources[0]).duplicate(true)
	var target_id: String = String(resource.id)
	for _hit in 80:
		if bool(world.resources[0].mined):
			break
		world._strike_resource(0)
	if not _check(bool(world.resources[0].mined), "Real strike damage mines generated deposit"):
		return false
	var cargo_once: Dictionary = RunState.cargo.duplicate(true)
	world._strike_resource(0)
	_check(RunState.cargo == cargo_once, "Repeated finished strike cannot duplicate payout")
	var depth: int = int(resource.depth)
	var node_index: int = int(resource.node_index)
	_check((int(RunState.endless_floor_resource_state(depth).mined_mask) & (1 << node_index)) != 0, "Mined node belongs to its own persistent band")
	var intact: Dictionary = {}
	for value in world.resources:
		if not bool(value.mined):
			intact[String(value.id)] = {"kind": String(value.kind), "amount": int(value.amount), "position": Vector2(value.position)}
	var site: Dictionary = Dictionary(world.discovery_sites[1]).duplicate(true)
	var site_index: int = int(site.index)
	var result: Dictionary = world.qa_complete_site_activity(site_index, "overload")
	if not _check(bool(result.get("ok", false)), "Actual generated cache rune activity can complete"):
		return false
	var claimed: Dictionary = RunState.cargo.duplicate(true)
	_check(not bool(world.qa_complete_site_activity(site_index, "overload").get("ok", true)), "Cache cannot complete twice")
	_check(RunState.cargo == claimed, "Cache replay cannot duplicate resources")
	world.load_depth(int(world.current_depth), "from_above")
	var claimed_respawned: bool = false
	for value in world.resources:
		if String(value.id) == target_id and not bool(value.mined):
			claimed_respawned = true
		if intact.has(String(value.id)):
			var prior: Dictionary = intact[String(value.id)]
			_check(String(value.kind) == String(prior.kind) and int(value.amount) == int(prior.amount) and Vector2(value.position) == Vector2(prior.position), "Unmined deposit identity/position survives reentry")
	_check(not claimed_respawned, "Mined deposit never regenerates on reentry")
	_check(not bool(world.qa_complete_site_activity(site_index, "overload").get("ok", true)), "Claimed cache stays closed after regeneration")
	_check(RunState.cargo == claimed, "Reloaded cache remains one claim")
	world.restore_position(entrance)
	return true


func _discovery_guidance() -> void:
	_freeze_world()
	var saved_position: Vector2 = world.player.global_position
	var saved_cells: PackedByteArray = world.floor_cells.duplicate()
	var site: Dictionary = world.discovery_sites[0]
	var position: Vector2 = Vector2(site.position)
	world.player.global_position = position + Vector2(128, 0)
	var wall: Vector2i = world._world_to_cell(position + Vector2(64, 0))
	world.floor_cells[world._cell_index(wall)] = 0
	world._update_discoveries()
	_check(not bool(world.discovery_sites[0].discovered), "Rock between player and cache prevents discovery through walls")
	_check(String(world.discovery_goal().get("objective_id", "")) != "endless:discovery:" + String(site.id), "Hidden cache cannot become a guide target")
	world.floor_cells = saved_cells
	world.player.global_position = position
	world._update_discoveries()
	_check(bool(world.discovery_sites[0].discovered), "Exposed cache is discovered by actual exploration")
	var local: Dictionary = world.discovery_goal()
	_check(String(local.get("objective_id", "")) == "endless:discovery:" + String(site.id), "Nearby discovery replaces the generic deeper objective")
	var cargo: Dictionary = RunState.cargo.duplicate(true)
	var goal: Dictionary = main.guide_director.goal_for_state(local)
	_check(goal.has("discovery_target") and Array(goal.get("requirements", [])).is_empty(), "Local opportunity is a route choice without a resource bill")
	_check(RunState.cargo == cargo, "Reading a discovery hint awards no cache resources")
	_check(world._start_site_activity(int(site.index), "stabilize"), "Discovered site starts its real activity")
	var rune_goal: Dictionary = world.discovery_goal()
	_check(String(rune_goal.get("objective_id", "")).contains(":rune:0"), "Active recovery points to its first authored rune")
	world._cancel_site_activity()
	world.player.global_position = saved_position
	world.load_depth(int(world.current_depth), "from_above")
	world.restore_position(saved_position)
	_freeze_world()


func _freeze_world() -> void:
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.player.control_enabled = true
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null:
		mole.set_physics_process(false)


func _absolute_position() -> Vector2:
	return Vector2(world.player.global_position) + Vector2(0, float(world.window_start_depth - 1) * world.CHUNK_HEIGHT)


func _walk_and_mine_to(target: Vector2, max_steps: int = 2400) -> bool:
	_freeze_world()
	var collision_free: bool = true
	var highest_nodes: int = 0
	var before_depth: int = int(world.current_depth)
	world.set_mine_held(true)
	for step in max_steps:
		var before: Vector2 = _absolute_position()
		var remaining: Vector2 = target - before
		if remaining.length() <= 28.0:
			world.set_mine_held(false)
			world.set_external_movement(Vector2.ZERO)
			_check(collision_free, "Real held movement never crosses solid terrain")
			_check(highest_nodes <= 90, "Active resource objects bounded during long walk")
			return true
		var direction: Vector2 = Vector2(signf(remaining.x), 0) if absf(remaining.x) > 20.0 else Vector2(0, signf(remaining.y))
		world.set_external_movement(direction)
		world.player._physics_process(0.1)
		world._process(0.1)
		world._physics_process(0.1)
		collision_free = collision_free and not world.collision_at(world.player.global_position)
		highest_nodes = maxi(highest_nodes, Array(world.resources).size())
		var current: int = int(world.current_depth)
		if current != before_depth:
			var after: Vector2 = _absolute_position()
			_check(after.distance_to(before) <= 64.0, "Chunk crossing preserves continuous absolute motion")
			_check(String(world.current_context()) not in ["endless_up", "endless_down"], "Walking seam exposes no floor/shaft action")
			_check(main.phase == "endless", "Walking seam remains in same world")
			travelled_metres.append(int(world.stream_snapshot().depth_metres))
			seam_positions.append(after)
			before_depth = current
		if step % 12 == 0:
			await main.get_tree().process_frame
	world.set_mine_held(false)
	world.set_external_movement(Vector2.ZERO)
	_check(false, "Held mining/movement reaches target; stopped at %s toward %s" % [_absolute_position(), target])
	return false


func _return_home(relic_id: String) -> bool:
	var position_before: Vector2 = _absolute_position()
	var cargo_before: Dictionary = RunState.cargo.duplicate(true)
	if not _check(main.request_tunnel_home(), "Actual Tunnel Home request accepted"):
		return false
	_check(not main.request_tunnel_home(), "Repeated Tunnel Home request blocked during animation")
	_check(not world.player.control_enabled and not bool(world.external_mine_held), "Tunnel Home releases movement and mining")
	await main.get_tree().create_timer(1.45).timeout
	if not _check(main.phase == "hub", "Tunnel Home reaches Hub after authored delay"):
		return false
	_check(RunState.cargo == cargo_before, "Tunnel Home preserves all cargo")
	_check(not bool(RunState.endless_descent_status().active), "Home clears active descent")
	if not relic_id.is_empty():
		var relic: Dictionary = RunState.relic_status(relic_id)
		_check(bool(relic.carried) and bool(relic.attached) and int(relic.current_depth) == 0, "Tunnel Home preserves attached relic")
		_check(String(main.hub_world._rope_relic_id) == relic_id and main.hub_world._relic_rope_points.size() > 2, "Actual Hub rope restored")
	journey.append({"step": "Tunnel Home", "relic": relic_id, "absolute_departure": position_before})
	return true


func _place_and_build(relic_id: String) -> bool:
	var hub: Node = main.hub_world
	var pedestal: Vector2 = Vector2(hub.RELIC_PEDESTAL_POSITION)
	hub.restore_position(pedestal)
	_check(String(hub.current_context()) == "relicPedestal", "Relic pedestal is actually in range")
	hub.qa_set_hub_relic_endpoint(pedestal + Vector2(180, -16))
	hub.perform_context()
	_check(not bool(RunState.relic_status(relic_id).placed), "Distant relic endpoint cannot be placed")
	hub.qa_set_hub_relic_endpoint(pedestal + Vector2(0, -16))
	hub.perform_context()
	if not _check(bool(RunState.relic_status(relic_id).placed), "Physical relic placement unlocks its workshop"):
		return false
	var relic: Dictionary = RunState.relic_status(relic_id)
	var workshop_id: String = String(relic.workshop_id)
	var resource_id: String = String(relic.build_resource)
	var price: int = int(relic.build_cost)
	_check(price == 200, "Existing construction value retained")
	var cargo_before: Dictionary = RunState.cargo.duplicate(true)
	var status: Dictionary = RunState.workshop_status(workshop_id)
	_check(bool(status.ready_to_build) and int(status.delivered) == price, "Delivered relic supplies its complete construction value")
	_check(not bool(RunState.deliver_workshop_material(workshop_id, resource_id, 500).get("ok", true)), "Supplied construction rejects an unnecessary extra payment")
	_check(not bool(RunState.place_carried_relic().get("ok", true)), "Relic placement cannot be replayed for more credit")
	_goal(workshop_id + " ready from discovery")
	_check(bool(RunState.build_workshop(workshop_id).get("ok", false)), "Workshop builds through real transaction")
	_check(not bool(RunState.build_workshop(workshop_id).get("ok", true)), "Workshop cannot be built twice")
	_check(RunState.cargo == cargo_before, "Relic construction neither consumes nor grants pocket materials")
	var upgrade: Dictionary = Dictionary(RunState.workshop_status(workshop_id).next_upgrade)
	if not upgrade.is_empty():
		var upgrade_resource: String = String(upgrade.resource)
		var saved_amount: int = int(RunState.cargo.get(upgrade_resource, 0))
		RunState.cargo[upgrade_resource] = int(upgrade.cost) - 1
		_check(not bool(RunState.upgrade_workshop(workshop_id).get("ok", true)), "Optional upgrade still rejects one material short")
		RunState.cargo[upgrade_resource] = saved_amount
	_goal(workshop_id + " built")
	return true


func _claim_generated_relic(relic_id: String) -> bool:
	var depth: int = int(RunState.next_endless_relic_depth())
	var current_abs: Vector2 = _absolute_position()
	var target: Vector2 = Vector2(current_abs.x, float(depth - 1) * world.CHUNK_HEIGHT + 320.0)
	if depth > int(world.current_depth) and not await _walk_and_mine_to(target):
		return false
	world._select_native_relic()
	if not _check(String(world.native_relic_id) == relic_id, "Actual generated milestone " + relic_id):
		return false
	world.restore_position(Vector2(world.native_relic_position))
	world._update_discoveries()
	if not _check(String(world.current_context()) == "endless_relic:" + relic_id, "Generated relic interaction reachable"):
		return false
	world.perform_context()
	if not _check(bool(RunState.relic_status(relic_id).attached), "Actual context attaches " + relic_id):
		return false
	_check(String(main.guide_director.goal_for_state({"kind": "endless_explore", "objective_id": "ignored-local-cache"}).get("kind", "")) == "endless_return", "Hauling a relic keeps priority over optional cache hints")
	var rope: Dictionary = world.rope_debug_snapshot()
	_check(bool(rope.get("finite", false)) and int(rope.get("point_count", 0)) > 2, "Relic uses finite physical rope")
	world.qa_step_rope(45, Vector2(0.2, -0.2))
	_check(bool(world.rope_debug_snapshot().get("finite", false)), "Hauling simulation remains finite")
	_goal("Hauling " + relic_id)
	if not await _return_home(relic_id):
		return false
	main.hub_world.restore_position(Vector2(main.hub_world.DEEP_ELEVATOR_POSITION))
	main.hub_world.perform_context()
	_check(main.phase == "hub", "Unplaced relic cannot be abandoned through descent")
	return _place_and_build(relic_id)


func run() -> void:
	if not _new_player_to_deep():
		_finish("world")
		return
	main._enter_endless(true, false)
	world = main.endless_world
	if not _check(world.has_method("stream_snapshot"), "Continuous-world contract exists"):
		_finish("world")
		return
	var first: Dictionary = world.stream_snapshot()
	_check(bool(first.get("continuous", false)), "Deep declares continuous coordinates")
	_check(int(first.get("active_chunk_count", 0)) == 3 and int(first.get("active_cells", 0)) == 2640, "Only three chunks resident")
	var navigation: Dictionary = preload("res://scripts/qa/suites/one_point_zero_terrain.gd").connectivity(world)
	_check(bool(navigation.spawn_clear) and bool(navigation.all_targets_reachable), "Generated relics, sites and ores reachable through mineable terrain")
	if not _claim_integrity():
		_finish("world")
		return
	_discovery_guidance()
	for relic_id in RunState.ENDLESS_RELIC_IDS:
		if main.phase == "hub":
			main._enter_endless(true, false)
		_freeze_world()
		if not await _claim_generated_relic(String(relic_id)):
			_finish("world")
			return
	var complete: Dictionary = RunState.endless_descent_status()
	_check(int(complete.placed_relic_count) == 5 and int(complete.built_workshop_count) == 5, "Five real relics complete existing Hub")
	_check(not bool(complete.exploration_complete), "Fifth relic does not finish The Deep")
	main._enter_endless(true, false)
	var mined_before: int = RunState.total_mined_resources()
	var target: Vector2 = _absolute_position() + Vector2(0, world.CHUNK_HEIGHT * 2.0)
	if await _walk_and_mine_to(target):
		_check(RunState.total_mined_resources() > mined_before, "Real mining yields resources after fifth relic")
		_check(int(world.current_depth) > 12, "Player advances beyond final relic depth")
		_check(int(world.stream_snapshot().origin_shift_count) >= 4, "Long journey actually rebases")
		var absolute_before: Vector2 = _absolute_position()
		var cargo_before: Dictionary = RunState.cargo.duplicate(true)
		RunState.set_location("endless", world.player.global_position)
		var save: Dictionary = RunState.serialize()
		main.phase = "surface"
		world.set_active(false)
		RunState.reset_run(false)
		_check(RunState.deserialize(save), "Mature continuous save reloads")
		main._restore_saved_location()
		_check(main.phase == "endless", "Mature save restores Deep scene")
		_check(_absolute_position().distance_to(absolute_before) <= 1.0, "Mature save preserves exact absolute location")
		_check(RunState.cargo == cargo_before, "Mature save preserves earned resources")
		_check(int(RunState.endless_descent_status().built_workshop_count) == 5, "Mature save retains all built workshops")
		_goal("Continued infinite mining after reload")
	journey.append({"step": "walked seams", "metres": travelled_metres, "positions": seam_positions})
	_finish("world")
