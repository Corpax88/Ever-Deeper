extends Node

# This driver is exported only by the "Web DEV" preset.  It never changes the
# normal game path; scripts/main.gd loads it dynamically only when the explicit
# --visual-capture-suite argument is present.

const FIXED_WORLD_SEED := 424242
const EXPECTED_CAPTURE_COUNT := 121
const ACK_TIMEOUT_MSEC := 45000
const SETTLE_PROCESS_FRAMES := 5
const AUTO_ACK_ARG := "--visual-capture-auto-ack"

const CARDINALS := [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const ADJACENT_SIDE_PAIRS := [[0, 1], [1, 2], [2, 3], [3, 0]]
const CAPTURE_VIEWPORT := Vector2i(932, 430)

const MINE_PROFILES := [
	{"tag": "moss", "mine_id": "mossMine", "gate_count": 4},
	{"tag": "moon", "mine_id": "moonMine", "gate_count": 4},
	{"tag": "ember", "mine_id": "emberMine", "gate_count": 4},
	{"tag": "star", "mine_id": "starMine", "gate_count": 0},
]

const DEPTH_ONE_BARRIERS := [
	{"mine_id": "mossMine", "barrier_id": "outer_rubble"},
	{"mine_id": "mossMine", "barrier_id": "iron_seam"},
	{"mine_id": "moonMine", "barrier_id": "moon_prism_gate"},
	{"mine_id": "moonMine", "barrier_id": "moon_star_lock"},
	{"mine_id": "emberMine", "barrier_id": "ember_bulkhead"},
	{"mine_id": "emberMine", "barrier_id": "ember_crucible_lock"},
	{"mine_id": "starMine", "barrier_id": "star_bridge_lock"},
	{"mine_id": "starMine", "barrier_id": "star_crown_lock"},
]

var _main: Node
var _waiting_for_ack := false
var _acknowledged := false
var _auto_ack := false


func run(main_node: Node) -> void:
	_main = main_node
	_auto_ack = AUTO_ACK_ARG in OS.get_cmdline_user_args()
	set_process_input(true)
	var states := _build_capture_states()
	if states.size() != EXPECTED_CAPTURE_COUNT:
		_fail("matrix_count_%d_expected_%d" % [states.size(), EXPECTED_CAPTURE_COUNT])
		return
	var viewport_size := get_viewport().get_visible_rect().size
	print(
		"EVER_DEEPER_VISUAL_CAPTURE_BEGIN count=%d viewport=%dx%d logical=%dx%d seed=%d"
		% [
			states.size(),
			CAPTURE_VIEWPORT.x,
			CAPTURE_VIEWPORT.y,
			roundi(viewport_size.x),
			roundi(viewport_size.y),
			FIXED_WORLD_SEED,
		]
	)
	for state_index in states.size():
		var state: Dictionary = states[state_index]
		if not _prepare_state(state):
			_fail("state_setup_%s" % String(state.id))
			return
		for _frame in SETTLE_PROCESS_FRAMES:
			await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().create_timer(0.12, true, false, true).timeout
		_waiting_for_ack = true
		_acknowledged = false
		print(
			"EVER_DEEPER_VISUAL_CAPTURE_READY state=%s index=%d total=%d"
			% [String(state.id), state_index + 1, states.size()]
		)
		if _auto_ack:
			_acknowledged = true
			_waiting_for_ack = false
			await get_tree().process_frame
		elif not await _wait_for_ack():
			_fail("ack_timeout_%s" % String(state.id))
			return
	print("EVER_DEEPER_VISUAL_CAPTURE_COMPLETE count=%d" % states.size())
	get_tree().quit(0)


func _input(event: InputEvent) -> void:
	if not _waiting_for_ack or not (event is InputEventKey):
		return
	var key := event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode not in [KEY_ENTER, KEY_KP_ENTER] and key.physical_keycode not in [KEY_ENTER, KEY_KP_ENTER]:
		return
	_acknowledged = true
	_waiting_for_ack = false
	get_viewport().set_input_as_handled()


func _wait_for_ack() -> bool:
	var deadline := Time.get_ticks_msec() + ACK_TIMEOUT_MSEC
	while not _acknowledged and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_waiting_for_ack = false
	return _acknowledged


func _build_capture_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for profile_value in MINE_PROFILES:
		var profile: Dictionary = Dictionary(profile_value)
		var tag := String(profile.tag)
		var mine_id := String(profile.mine_id)
		states.append({"id": "d1_%s_edges_corners" % tag, "kind": "d1_edges", "mine_id": mine_id})
		states.append({"id": "d1_%s_bedrock" % tag, "kind": "d1_bedrock", "mine_id": mine_id})
		states.append({"id": "d1_%s_transition" % tag, "kind": "d1_transition", "mine_id": mine_id})
	for barrier_value in DEPTH_ONE_BARRIERS:
		var barrier: Dictionary = Dictionary(barrier_value)
		for variant in [
			"locked",
			"ready",
			"damaged",
			"partial_first",
			"partial_middle",
			"partial_last",
			"cleared",
		]:
			states.append(
				{
					"id": "d1_%s_%s" % [String(barrier.barrier_id), variant],
					"kind": "d1_barrier",
					"mine_id": String(barrier.mine_id),
					"barrier_id": String(barrier.barrier_id),
					"variant": variant,
				}
			)
	for profile_value in MINE_PROFILES:
		var profile: Dictionary = Dictionary(profile_value)
		var tag := String(profile.tag)
		var mine_id := String(profile.mine_id)
		states.append({"id": "d2_%s_edges_corners" % tag, "kind": "d2_edges", "mine_id": mine_id})
		states.append({"id": "d2_%s_bedrock" % tag, "kind": "d2_bedrock", "mine_id": mine_id})
		states.append({"id": "d2_%s_transition" % tag, "kind": "d2_transition", "mine_id": mine_id})
		for gate_index in int(profile.gate_count):
			for variant in ["intact", "partial", "cleared"]:
				states.append(
					{
						"id": "d2_%s_gate_%02d_%s" % [tag, gate_index + 1, variant],
						"kind": "d2_gate",
						"mine_id": mine_id,
						"gate_index": gate_index,
						"variant": variant,
					}
				)
	for layer in range(1, 6):
		states.append(
			{
				"id": "endless_layer_%02d_permanent_walls" % layer,
				"kind": "endless_walls",
				"layer": layer,
			}
		)
	return states


func _prepare_state(state: Dictionary) -> bool:
	match String(state.kind):
		"d1_edges":
			return _prepare_d1_edges(String(state.mine_id), false)
		"d1_bedrock":
			return _prepare_d1_edges(String(state.mine_id), true)
		"d1_transition":
			return _prepare_d1_transition(String(state.mine_id))
		"d1_barrier":
			return _prepare_d1_barrier(
				String(state.mine_id), String(state.barrier_id), String(state.variant)
			)
		"d2_edges":
			return _prepare_d2_edges(String(state.mine_id))
		"d2_bedrock":
			return _prepare_d2_bedrock(String(state.mine_id))
		"d2_transition":
			return _prepare_d2_transition(String(state.mine_id))
		"d2_gate":
			return _prepare_d2_gate(
				String(state.mine_id), int(state.gate_index), String(state.variant)
			)
		"endless_walls":
			return _prepare_endless_walls(int(state.layer))
	return false


func _reset_run() -> void:
	RunState.reset_run(false)
	RunState.world_seed = FIXED_WORLD_SEED
	_main.call("_dev_ensure_playing")
	_main.set("button_move", Vector2.ZERO)
	_main.call("_apply_button_movement")


func _load_d1(mine_id: String, reveal_transition: bool = false) -> Node:
	_reset_run()
	if reveal_transition:
		RunState.mark_depth_entrance_discovered(mine_id)
	if not bool(_main.call("_dev_jump_mine", mine_id, 1)):
		return null
	var world := _main.get("mine_world") as Node
	if world == null:
		return null
	# load_mine() deliberately caches an unchanged cavern.  Captures must not
	# inherit mutations from the preceding state, so rebuild the local runtime.
	world.call("_configure_mine", mine_id)
	world.call("_rebuild_work_lamps")
	world.call("_request_redraw")
	return world


func _load_d2(mine_id: String) -> Node:
	_reset_run()
	if not bool(_main.call("_dev_jump_mine", mine_id, 2)):
		return null
	var world := _main.get("depth_world") as Node
	if world == null:
		return null
	world.call("rebuild_from_run_state")
	world.call("_request_redraw")
	return world


func _prepare_d1_edges(mine_id: String, bedrock: bool) -> bool:
	var world := _load_d1(mine_id)
	if world == null:
		return false
	var view := _find_d1_wall_view(world, bedrock, true)
	if view.is_empty() and bedrock:
		view = _find_d1_wall_view(world, true, false)
	if view.is_empty():
		return false
	_frame_world(world, Vector2(view.player), Vector2(view.target))
	return true


func _prepare_d1_transition(mine_id: String) -> bool:
	var world := _load_d1(mine_id, true)
	if world == null:
		return false
	var target := Vector2(world.get("depth_entrance"))
	_frame_world(world, target + Vector2(118.0, 0.0), target)
	return true


func _prepare_d1_barrier(mine_id: String, barrier_id: String, variant: String) -> bool:
	var world := _load_d1(mine_id)
	if world == null:
		return false
	var barrier := _d1_barrier_definition(world, barrier_id)
	if barrier.is_empty():
		return false
	var required := int(barrier.requiresPickaxe)
	RunState.pickaxe_level = maxi(0, required - 1) if variant == "locked" else required
	if variant == "damaged":
		var blocks: Dictionary = Dictionary(world.get("blocks"))
		for cell_value in blocks.keys():
			var cell := Vector2i(cell_value)
			var block: Dictionary = Dictionary(blocks[cell])
			if String(block.get("role", "")) != barrier_id:
				continue
			block["hp"] = maxi(1, roundi(float(block.get("max_hp", 1)) * 0.45))
			blocks[cell] = block
		world.set("blocks", blocks)
	elif variant in ["partial_first", "partial_middle", "partial_last"]:
		var vertical := float(barrier.h) >= float(barrier.w)
		var role_cells := _d1_barrier_cells(world, barrier_id, vertical)
		if role_cells.size() < 3:
			return false
		var remove_index := 0
		if variant == "partial_middle":
			remove_index = role_cells.size() / 2
		elif variant == "partial_last":
			remove_index = role_cells.size() - 1
		var blocks: Dictionary = Dictionary(world.get("blocks"))
		blocks.erase(role_cells[remove_index])
		world.set("blocks", blocks)
		world.call("_rebuild_role_counts")
	elif variant == "cleared":
		world.call("_erase_role", barrier_id)
	elif variant not in ["locked", "ready"]:
		return false
	world.call("_request_redraw")
	var rect := Rect2(
		float(barrier.x), float(barrier.y), float(barrier.w), float(barrier.h)
	)
	var target := rect.get_center()
	var approach := Vector2(-145.0, 0.0) if rect.size.y >= rect.size.x else Vector2(0.0, -145.0)
	_frame_world(world, target + approach, target)
	return true


func _d1_barrier_cells(world: Node, barrier_id: String, vertical: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var blocks: Dictionary = Dictionary(world.get("blocks"))
	for cell_value in blocks.keys():
		var cell := Vector2i(cell_value)
		var block: Dictionary = Dictionary(blocks[cell])
		if String(block.get("role", "")) == barrier_id:
			result.append(cell)
	result.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		if vertical:
			return a.y < b.y if a.y != b.y else a.x < b.x
		return a.x < b.x if a.x != b.x else a.y < b.y
	)
	return result


func _d1_barrier_definition(world: Node, barrier_id: String) -> Dictionary:
	var mine: Dictionary = Dictionary(world.get("mine"))
	for barrier_value in Array(mine.get("barriers", [])):
		var barrier: Dictionary = Dictionary(barrier_value)
		if String(barrier.get("id", "")) == barrier_id:
			return barrier
	return {}


func _find_d1_wall_view(world: Node, bedrock: bool, require_corner: bool) -> Dictionary:
	var blocks: Dictionary = Dictionary(world.get("blocks"))
	var cols := int(world.get("cols"))
	var rows := int(world.get("rows"))
	var world_center := Vector2(world.get("world_size")) * 0.5
	var best: Dictionary = {}
	var best_score := INF
	for row in range(1, rows - 1):
		for col in range(1, cols - 1):
			var cell := Vector2i(col, row)
			if not blocks.has(cell):
				continue
			var block: Dictionary = Dictionary(blocks[cell])
			var matches := String(block.get("kind", "")) == "bedrock" if bedrock else (
				String(block.get("kind", "")) != "bedrock"
				and String(block.get("role", "")) == "terrain"
			)
			if not matches:
				continue
			var open_sides: Array[bool] = []
			for offset in CARDINALS:
				open_sides.append(not blocks.has(cell + Vector2i(offset)))
			var open_side := -1
			if require_corner:
				for pair_value in ADJACENT_SIDE_PAIRS:
					var pair: Array = Array(pair_value)
					if bool(open_sides[int(pair[0])]) and bool(open_sides[int(pair[1])]):
						open_side = int(pair[0])
						break
			else:
				for side in open_sides.size():
					if bool(open_sides[side]):
						open_side = side
						break
			if open_side < 0:
				continue
			var target := Vector2(world.call("_cell_center", cell))
			var score := target.distance_squared_to(world_center)
			if score >= best_score:
				continue
			best_score = score
			best = {
				"target": target,
				"player": Vector2(world.call("_cell_center", cell + Vector2i(CARDINALS[open_side]))),
			}
	return best


func _prepare_d2_edges(mine_id: String) -> bool:
	var world := _load_d2(mine_id)
	if world == null:
		return false
	var view := _find_d2_wall_view(world)
	if view.is_empty():
		return false
	_frame_world(world, Vector2(view.player), Vector2(view.target))
	return true


func _prepare_d2_bedrock(mine_id: String) -> bool:
	var world := _load_d2(mine_id)
	if world == null:
		return false
	# Depth 2's permanent bedrock is the outer ring.  Excavate a deterministic
	# room that a player can genuinely mine up to, then frame its top-left join.
	var terrain_hp: PackedInt32Array = world.get("terrain_hp")
	var concealed: Dictionary = Dictionary(world.get("concealed_cells"))
	for row in range(1, 8):
		for col in range(1, 9):
			var cell := Vector2i(col, row)
			var index := int(world.call("_cell_index", cell))
			terrain_hp[index] = 0
			concealed.erase(index)
	world.set("terrain_hp", terrain_hp)
	world.set("concealed_cells", concealed)
	world.call("_request_redraw")
	var player_position := Vector2(world.call("_cell_center", Vector2i(4, 4)))
	var target := Vector2(world.call("_cell_center", Vector2i(0, 0)))
	_frame_world(world, player_position, target)
	return true


func _find_d2_wall_view(world: Node) -> Dictionary:
	var cols := int(world.get("cols"))
	var rows := int(world.get("rows"))
	var world_center := Vector2(world.get("world_size")) * 0.5
	var best: Dictionary = {}
	var best_score := INF
	for row in range(1, rows - 1):
		for col in range(1, cols - 1):
			var cell := Vector2i(col, row)
			if bool(world.call("_terrain_is_bedrock", cell)) or not bool(world.call("_visual_is_solid", cell)):
				continue
			var open_sides: Array[bool] = []
			for offset in CARDINALS:
				open_sides.append(not bool(world.call("_visual_is_solid", cell + Vector2i(offset))))
			var open_side := -1
			for pair_value in ADJACENT_SIDE_PAIRS:
				var pair: Array = Array(pair_value)
				if bool(open_sides[int(pair[0])]) and bool(open_sides[int(pair[1])]):
					open_side = int(pair[0])
					break
			if open_side < 0:
				continue
			var target := Vector2(world.call("_cell_center", cell))
			var score := target.distance_squared_to(world_center)
			if score >= best_score:
				continue
			best_score = score
			best = {
				"target": target,
				"player": Vector2(world.call("_cell_center", cell + Vector2i(CARDINALS[open_side]))),
			}
	return best


func _prepare_d2_transition(mine_id: String) -> bool:
	var world := _load_d2(mine_id)
	if world == null:
		return false
	var target := Vector2(world.get("depth_entrance"))
	_frame_world(world, target + Vector2(125.0, 0.0), target)
	return true


func _prepare_d2_gate(mine_id: String, gate_index: int, variant: String) -> bool:
	var world := _load_d2(mine_id)
	if world == null:
		return false
	var gates: Array = world.call("get_drill_gates")
	if gate_index < 0 or gate_index >= gates.size():
		return false
	var gate: Dictionary = Dictionary(gates[gate_index])
	var gate_id := String(gate.id)
	var rocks: Array = world.get("rocks")
	var discovered_cavern := false
	for rock_value in rocks:
		var rock: Dictionary = Dictionary(rock_value)
		if not bool(rock.get("drill_gated", false)) or String(rock.get("deposit_id", "")) != gate_id:
			continue
		var cavern_id := String(rock.get("cavern_id", ""))
		if not cavern_id.is_empty():
			discovered_cavern = RunState.mark_cavern_discovered(cavern_id) or discovered_cavern
	if discovered_cavern:
		world.call("rebuild_from_run_state")
		gates = world.call("get_drill_gates")
		gate = Dictionary(gates[gate_index])
		gate_id = String(gate.id)
		rocks = world.get("rocks")
	var matching_indices: Array[int] = []
	for rock_index in rocks.size():
		var rock: Dictionary = Dictionary(rocks[rock_index])
		if bool(rock.get("drill_gated", false)) and String(rock.get("deposit_id", "")) == gate_id:
			matching_indices.append(rock_index)
	if matching_indices.is_empty():
		return false
	var positions: Array = Array(gate.get("positions", []))
	if positions.is_empty():
		return false
	var min_position := Vector2(positions[0])
	var max_position := min_position
	for position_value in positions:
		var position := Vector2(position_value)
		min_position = min_position.min(position)
		max_position = max_position.max(position)
	var vertical := (max_position.y - min_position.y) > (max_position.x - min_position.x)
	matching_indices.sort_custom(
		func(left: int, right: int) -> bool:
			var left_position := Vector2(Dictionary(rocks[left]).position)
			var right_position := Vector2(Dictionary(rocks[right]).position)
			return left_position.y < right_position.y if vertical else left_position.x < right_position.x
	)
	var gate_cells: Array[Vector2i] = []
	for rock_index in matching_indices:
		gate_cells.append(Vector2i(Dictionary(rocks[rock_index]).cell))
	var staging := _stage_d2_gate_view(world, rocks, matching_indices, gate_cells, vertical)
	if staging.is_empty():
		return false
	rocks = Array(staging.rocks)
	var indices_to_break: Array[int] = []
	if variant == "partial":
		indices_to_break.append(matching_indices[floori(float(matching_indices.size()) * 0.5)])
	elif variant == "cleared":
		indices_to_break.assign(matching_indices)
	elif variant != "intact":
		return false
	for rock_index in indices_to_break:
		var rock: Dictionary = Dictionary(rocks[rock_index])
		rock["broken"] = true
		rock["hp"] = 0
		rock["shell"] = 0
		rock["respawn_remaining"] = INF
		rock["respawn_until_unix"] = 0.0
		rocks[rock_index] = rock
	world.set("rocks", rocks)
	world.call("_request_redraw")
	var target := (min_position + max_position) * 0.5
	_frame_world(world, Vector2(staging.player), target)
	return true


func _stage_d2_gate_view(
	world: Node,
	rocks: Array,
	matching_indices: Array[int],
	gate_cells: Array[Vector2i],
	vertical: bool
) -> Dictionary:
	# Drill gates normally reveal only after the player excavates up to their
	# boundary.  Build that exact presentation deterministically for QA instead
	# of asking restore_position() to find a route through untouched terrain.
	# The previous fixed offset could fall back to the entry hub, producing a
	# technically successful screenshot in which the gate was not visible.
	if gate_cells.is_empty():
		return {}
	var min_cell := gate_cells[0]
	var max_cell := gate_cells[0]
	for cell in gate_cells:
		min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
		max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
	var clear_min := min_cell - (Vector2i(4, 2) if vertical else Vector2i(2, 4))
	var clear_max := max_cell + (Vector2i(0, 2) if vertical else Vector2i(2, 0))
	var cols := int(world.get("cols"))
	var rows := int(world.get("rows"))
	clear_min.x = clampi(clear_min.x, 1, cols - 2)
	clear_min.y = clampi(clear_min.y, 1, rows - 2)
	clear_max.x = clampi(clear_max.x, 1, cols - 2)
	clear_max.y = clampi(clear_max.y, 1, rows - 2)
	var terrain_hp: PackedInt32Array = world.get("terrain_hp")
	var concealed: Dictionary = Dictionary(world.get("concealed_cells"))
	var staged_cells: Dictionary = {}
	for row in range(clear_min.y, clear_max.y + 1):
		for col in range(clear_min.x, clear_max.x + 1):
			var cell := Vector2i(col, row)
			if bool(world.call("_terrain_is_bedrock", cell)):
				continue
			var cell_index := int(world.call("_cell_index", cell))
			terrain_hp[cell_index] = 0
			concealed.erase(cell_index)
			staged_cells[cell] = true
	world.set("terrain_hp", terrain_hp)
	world.set("concealed_cells", concealed)
	var matching_set: Dictionary = {}
	for rock_index in matching_indices:
		matching_set[rock_index] = true
	for rock_index in rocks.size():
		if matching_set.has(rock_index):
			continue
		var rock: Dictionary = Dictionary(rocks[rock_index])
		if not staged_cells.has(Vector2i(rock.cell)):
			continue
		rock["broken"] = true
		rock["hp"] = 0
		rock["shell"] = 0
		rock["respawn_remaining"] = INF
		rock["respawn_until_unix"] = 0.0
		rocks[rock_index] = rock
	world.set("rocks", rocks)
	var player_cell := Vector2i(
		min_cell.x - 3 if vertical else floori(float(min_cell.x + max_cell.x) * 0.5),
		floori(float(min_cell.y + max_cell.y) * 0.5) if vertical else min_cell.y - 3
	)
	player_cell.x = clampi(player_cell.x, clear_min.x, clear_max.x)
	player_cell.y = clampi(player_cell.y, clear_min.y, clear_max.y)
	var player_position := Vector2(world.call("_cell_center", player_cell))
	var safe_position := Vector2(world.call("_nearest_safe_position", player_position))
	if safe_position.distance_to(player_position) > 1.0:
		return {}
	return {"player": player_position, "rocks": rocks}


func _prepare_endless_walls(layer: int) -> bool:
	_reset_run()
	# reset_run() clears the authoritative descent state but main.phase is a
	# runtime field.  Leave the previous layer explicitly so _enter_endless()
	# cannot take its normal same-world early return on the next capture.
	var previous_world := _main.get("endless_world") as Node
	if previous_world != null:
		previous_world.call("set_active", false)
	_main.set("phase", "surface")
	if not bool(_main.call("_dev_jump_endless", layer)):
		return false
	var world := _main.get("endless_world") as Node
	if world == null:
		return false
	var floor_cells: PackedByteArray = world.get("floor_cells")
	var grid_size := Vector2i(40, 22)
	var world_center := Vector2(grid_size) * 32.0
	var best: Dictionary = {}
	var best_score := INF
	# Prefer a true convex corner.  Some generated layers contain only long
	# wall runs near their central route, so fall back to the closest natural
	# permanent-wall face while still covering that layer's unique stratum.
	for require_corner in [true, false]:
		for row in range(1, grid_size.y - 1):
			for col in range(1, grid_size.x - 1):
				var cell := Vector2i(col, row)
				var index := row * grid_size.x + col
				if floor_cells[index] != 0:
					continue
				var floor_sides: Array[bool] = []
				for offset in CARDINALS:
					var neighbour := cell + Vector2i(offset)
					var neighbour_index := neighbour.y * grid_size.x + neighbour.x
					floor_sides.append(floor_cells[neighbour_index] != 0)
				var floor_side := -1
				if require_corner:
					for pair_value in ADJACENT_SIDE_PAIRS:
						var pair: Array = Array(pair_value)
						if bool(floor_sides[int(pair[0])]) and bool(floor_sides[int(pair[1])]):
							floor_side = int(pair[0])
							break
				else:
					for side in floor_sides.size():
						if bool(floor_sides[side]):
							floor_side = side
							break
				if floor_side < 0:
					continue
				var target := Vector2(world.call("_cell_center", cell))
				var score := target.distance_squared_to(world_center)
				if score >= best_score:
					continue
				best_score = score
				best = {
					"target": target,
					"player": Vector2(world.call("_cell_center", cell + Vector2i(CARDINALS[floor_side]))),
				}
		if not best.is_empty():
			break
	if best.is_empty():
		return false
	_frame_world(world, Vector2(best.player), Vector2(best.target))
	return true


func _frame_world(world: Node, player_position: Vector2, target: Vector2) -> void:
	world.call("restore_position", player_position)
	if world.has_method("set_external_movement"):
		world.call("set_external_movement", Vector2.ZERO)
	var player := world.get("player") as Node
	if player != null:
		player.set("control_enabled", false)
		if player.has_method("set_external_movement"):
			player.call("set_external_movement", Vector2.ZERO)
		var direction := target - Vector2(player.get("global_position"))
		if not direction.is_zero_approx() and player.has_method("set_facing"):
			player.call("set_facing", direction.normalized())
		var camera := player.get("camera") as Camera2D
		if camera != null:
			camera.position_smoothing_enabled = false
			camera.make_current()
			camera.reset_smoothing()
	_main.call("_refresh_hud")
	if world.has_method("_request_redraw"):
		world.call("_request_redraw")
	else:
		world.queue_redraw()


func _fail(reason: String) -> void:
	_waiting_for_ack = false
	print("EVER_DEEPER_VISUAL_CAPTURE_FAILED reason=%s" % reason.replace(" ", "_"))
	push_error("Visual capture suite failed: %s" % reason)
	get_tree().quit(72)
