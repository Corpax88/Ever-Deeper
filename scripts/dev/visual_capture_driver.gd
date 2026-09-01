extends Node





const PremiumMenuScript = preload("res://scripts/ui/premium_menu.gd")
const CommerceCatalogScript = preload("res://scripts/ui/commerce_catalog.gd")

const FIXED_WORLD_SEED: = 424242
const EXPECTED_CAPTURE_COUNT: = 133
const ACK_TIMEOUT_MSEC: = 45000
const SETTLE_PROCESS_FRAMES: = 5
const AUTO_ACK_ARG: = "--visual-capture-auto-ack"

const CARDINALS: = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
const ADJACENT_SIDE_PAIRS: = [[0, 1], [1, 2], [2, 3], [3, 0]]
const CAPTURE_VIEWPORT: = Vector2i(932, 430)

const MINE_PROFILES: = [
	{"tag": "moss", "mine_id": "mossMine", "gate_count": 4},
	{"tag": "moon", "mine_id": "moonMine", "gate_count": 4},
	{"tag": "ember", "mine_id": "emberMine", "gate_count": 4},
	{"tag": "star", "mine_id": "starMine", "gate_count": 0},
]

const DEPTH_ONE_BARRIERS: = [
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
var _waiting_for_ack: = false
var _acknowledged: = false
var _auto_ack: = false


func run(main_node: Node) -> void :
	_main = main_node
	_auto_ack = AUTO_ACK_ARG in OS.get_cmdline_user_args()
	set_process_input(true)
	var build_contract: = _verify_build_contract()
	if build_contract.is_empty():
		return
	var states: = _build_capture_states()
	if states.size() != EXPECTED_CAPTURE_COUNT:
		_fail("matrix_count_%d_expected_%d" % [states.size(), EXPECTED_CAPTURE_COUNT])
		return
	var viewport_size: = get_viewport().get_visible_rect().size
	print(
		"EVER_DEEPER_VISUAL_CAPTURE_BEGIN count=%d viewport=%dx%d logical=%dx%d seed=%d flavor=%s version=%s dev_menu=%s"
		%[
			states.size(),
			CAPTURE_VIEWPORT.x,
			CAPTURE_VIEWPORT.y,
			roundi(viewport_size.x),
			roundi(viewport_size.y),
			FIXED_WORLD_SEED,
			String(build_contract.flavor),
			String(build_contract.version),
			str(bool(build_contract.dev_menu)),
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
			%[String(state.id), state_index + 1, states.size()]
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


func _verify_build_contract() -> Dictionary:
	var dev_feature: = OS.has_feature("ever_deeper_dev")
	var expected_version: = "0.43.1-dev.3" if dev_feature else "0.43.1"
	var expected_flavor: = "dev" if dev_feature else "production"
	var actual_version: = String(PremiumMenuScript.release_version())
	var developer_menu: Variant = _main.get("developer_menu")
	var menu_present: = developer_menu != null and is_instance_valid(developer_menu)
	var premium_menu: Variant = _main.get("premium_menu")
	var displayed_label: = ""
	if premium_menu != null and is_instance_valid(premium_menu):
		displayed_label = String(premium_menu.call("displayed_release_label"))
	if (
		actual_version != expected_version
		or menu_present != dev_feature
		or displayed_label != String(PremiumMenuScript.release_label())
	):
		_fail(
			"build_contract_flavor_%s_version_%s_menu_%s_label_%s"
			%[
				expected_flavor,
				actual_version,
				str(menu_present),
				displayed_label,
			]
		)
		return {}
	return {
		"flavor": expected_flavor,
		"version": actual_version,
		"dev_menu": menu_present,
	}


func _input(event: InputEvent) -> void :
	if not _waiting_for_ack or not (event is InputEventKey):
		return
	var key: = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.keycode not in [KEY_ENTER, KEY_KP_ENTER] and key.physical_keycode not in [KEY_ENTER, KEY_KP_ENTER]:
		return
	_acknowledged = true
	_waiting_for_ack = false
	get_viewport().set_input_as_handled()


func _wait_for_ack() -> bool:
	var deadline: = Time.get_ticks_msec() + ACK_TIMEOUT_MSEC
	while not _acknowledged and Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
	_waiting_for_ack = false
	return _acknowledged


func _build_capture_states() -> Array[Dictionary]:
	var states: Array[Dictionary] = []
	for profile_value in MINE_PROFILES:
		var profile: Dictionary = Dictionary(profile_value)
		var tag: = String(profile.tag)
		var mine_id: = String(profile.mine_id)
		states.append(
			{
				"id": "d1_%s_barrier_clearance_compact_join" % tag,
				"kind": "d1_edges",
				"mine_id": mine_id,
			}
		)
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
		var tag: = String(profile.tag)
		var mine_id: = String(profile.mine_id)
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
	for fixture_id in [
		"forge_ordinary_ready",
		"forge_ordinary_missing_gold",
		"forge_final_missing_resource",
		"forge_final_missing_both",
		"forge_final_mixed_cost_ready",
		"forge_final_world_locked_funded",
		"forge_mastery_rank_five_ready",
		"forge_mastery_insufficient",
		"forge_complete_mastered",
		"forge_icon_fallback",
		"wayfarer_baseline",
		"workshop_tool_forge_baseline",
	]:
		states.append(
			{
				"id": "shop_%s" % fixture_id,
				"kind": "commerce",
				"fixture_id": fixture_id,
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
		"commerce":
			return _prepare_commerce_capture(String(state.fixture_id))
	return false


func _reset_run() -> void :
	_main.call("_settle_commerce_before_world_change")
	RunState.reset_run(false)
	RunState.world_seed = FIXED_WORLD_SEED
	_main.call("_dev_ensure_playing")
	_main.set("button_move", Vector2.ZERO)
	_main.call("_apply_button_movement")


func _prepare_commerce_capture(fixture_id: String) -> bool:
	_reset_run()
	_main.call("_dev_jump_surface")
	var config: Dictionary = {}
	var context_id: = ""
	match fixture_id:
		"forge_ordinary_ready":
			config = _forge_capture_config(1, 0, true, true, true)
			context_id = "forge"
		"forge_ordinary_missing_gold":
			config = _forge_capture_config(1, 0, true, false, true)
			context_id = "forge"
		"forge_final_missing_resource":
			config = _forge_capture_config(4, 0, true, true, false)
			context_id = "forge"
		"forge_final_missing_both":
			config = _forge_capture_config(4, 0, true, false, false)
			context_id = "forge"
		"forge_final_mixed_cost_ready":
			config = _forge_capture_config(4, 0, true, true, true)
			context_id = "forge"
		"forge_final_world_locked_funded":
			config = _forge_capture_config(4, 0, false, true, true)
			context_id = "forge"
		"forge_mastery_rank_five_ready":
			config = _forge_capture_config(5, 4, true, true, true)
			context_id = "forge"
		"forge_mastery_insufficient":
			config = _forge_capture_config(5, 4, true, false, false)
			context_id = "forge"
		"forge_complete_mastered":
			config = _forge_capture_config(
				Array(GameData.data.PICKAXES).size() - 1,
				Array(GameData.data.EMBER_MASTERY).size() - 1,
				true,
				true,
				true
			)
			context_id = "forge"
		"forge_icon_fallback":
			config = _forge_capture_config(1, 0, true, true, true)
			config = _with_missing_commerce_icons(config)
			context_id = "forge"
		"wayfarer_baseline":
			RunState.gold = int(RunState.movement_speed_upgrade_cost())
			config = CommerceCatalogScript.wayfarer_config()
			context_id = "wayfarer"
		"workshop_tool_forge_baseline":
			config = _tool_forge_capture_config()
			context_id = "workshop:tool_forge"
		_:
			return false
	if config.is_empty():
		return false
	_main.call("_open_commerce", config, context_id)
	var commerce_panel: Variant = _main.get("commerce_panel")
	if commerce_panel == null or not is_instance_valid(commerce_panel):
		return false
	var snapshot: Dictionary = Dictionary(commerce_panel.call("interaction_snapshot"))
	return (
		bool(snapshot.get("open", false))
		and String(snapshot.get("panel_id", "")) == String(config.get("panel_id", ""))
		and int(snapshot.get("item_count", 0)) > 0
	)


func _forge_capture_config(
	pickaxe_level: int,
	ember_mastery: int,
	emberdeep_unlocked: bool,
	fund_gold: bool,
	fund_resources: bool
) -> Dictionary:
	RunState.pickaxe_level = clampi(pickaxe_level, 1, Array(GameData.data.PICKAXES).size() - 1)
	RunState.ember_mastery = clampi(
		ember_mastery, 0, Array(GameData.data.EMBER_MASTERY).size() - 1
	)
	RunState.emberdeep_unlocked = emberdeep_unlocked
	RunState.gold = 1_000_000
	for resource_id in ["emberstone", "sunslag"]:
		RunState.cargo[resource_id] = 1_000_000
	var funded_snapshot: Dictionary = Dictionary(RunState.forge_purchase_snapshot())
	var gold_requirement: Dictionary = Dictionary(
		Dictionary(funded_snapshot.get("cost", {})).get("gold", {})
	)
	RunState.gold = int(gold_requirement.get("required", 0)) if fund_gold else 0
	for requirement_value in Array(
		Dictionary(funded_snapshot.get("cost", {})).get("resources", [])
	):
		var requirement: Dictionary = Dictionary(requirement_value)
		var resource_id: = String(requirement.get("kind", ""))
		if not resource_id.is_empty():
			RunState.cargo[resource_id] = (
				int(requirement.get("required", 0)) if fund_resources else 0
			)
	return CommerceCatalogScript.forge_config(Dictionary(RunState.forge_purchase_snapshot()))


func _with_missing_commerce_icons(source: Dictionary) -> Dictionary:
	var config: Dictionary = source.duplicate(true)
	var items: Array = Array(config.get("items", [])).duplicate(true)
	if items.is_empty():
		return config
	var item: Dictionary = Dictionary(items[0]).duplicate(true)
	item["texture"] = "res://assets/ui/visual-capture-missing-item.png"
	var costs: Array = Array(item.get("costs", [])).duplicate(true)
	for cost_index in costs.size():
		var cost: Dictionary = Dictionary(costs[cost_index]).duplicate(true)
		cost["icon_path"] = "res://assets/ui/visual-capture-missing-cost.png"
		costs[cost_index] = cost
	item["costs"] = costs
	items[0] = item
	config["items"] = items
	return config


func _tool_forge_capture_config() -> Dictionary:
	_main.call("_dev_seed_victory_state")
	if not bool(_main.call("_dev_build_all_workshops_state")):
		return {}
	if not bool(_main.call("_dev_jump_hub")):
		return {}
	var status: Dictionary = Dictionary(RunState.workshop_status("tool_forge"))
	var upgrade: Dictionary = Dictionary(status.get("next_upgrade", {}))
	if not upgrade.is_empty():
		var resource_id: = String(upgrade.get("resource", ""))
		var required: = int(upgrade.get("cost", 0))
		if not resource_id.is_empty() and required > 0:
			RunState.cargo[resource_id] = required
			status = Dictionary(RunState.workshop_status("tool_forge"))
	var hub_world: Variant = _main.get("hub_world")
	if hub_world == null or not is_instance_valid(hub_world):
		return {}
	var selection: Dictionary = Dictionary(
		hub_world.call("workshop_selection_preview", "tool_forge")
	)
	return CommerceCatalogScript.workshop_config("tool_forge", status, selection)


func _load_d1(mine_id: String, reveal_transition: bool = false) -> Node:
	_reset_run()
	if reveal_transition:
		RunState.mark_depth_entrance_discovered(mine_id)
	if not bool(_main.call("_dev_jump_mine", mine_id, 1)):
		return null
	var world: = _main.get("mine_world") as Node
	if world == null:
		return null


	world.call("_configure_mine", mine_id)
	world.call("_rebuild_work_lamps")
	world.call("_request_redraw")
	return world


func _load_d2(mine_id: String) -> Node:
	_reset_run()
	if not bool(_main.call("_dev_jump_mine", mine_id, 2)):
		return null
	var world: = _main.get("depth_world") as Node
	if world == null:
		return null
	world.call("rebuild_from_run_state")
	world.call("_request_redraw")
	return world


func _prepare_d1_edges(mine_id: String, bedrock: bool) -> bool:
	var world: = _load_d1(mine_id)
	if world == null:
		return false
	if bedrock:
		return _prepare_d1_bedrock_stage(world)
	return _prepare_d1_edge_regression_stage(world)


func _prepare_d1_edge_regression_stage(world: Node) -> bool:
	# This deterministic room keeps both reported regressions in one frame for
	# every D1 biome. The left terrain tongue is surrounded by untracked authored
	# clearance: it used to receive a false U-shaped mineable rim. The right stair
	# is genuine player-dug space: its two-side corner must retain a compact join
	# without the authored corner texture dangling below the one-tile turn.
	#
	# T = mineable terrain, . = open, B = bedrock. Local 21 x 8 layout:
	#   ..TTTT............BBB
	#   ..TTTT............BBB
	#   ..TTTT.......TTTTTBBB
	#   ..TTTT......TTTTTTBBB
	#   ..TTTT......TTTTTTBBB
	#   ............TTTTTTBBB
	#   ............TTTTTTBBB
	#   ............TTTTTTBBB
	var active_mine_id: = String(world.get("mine_id"))
	var cols: = int(world.get("cols"))
	var rows: = int(world.get("rows"))
	if cols < 25 or rows < 14:
		return false
	var center_col: = floori(float(cols) * 0.5)
	var center_row: = floori(float(rows) * 0.5)
	var stage_left: = center_col - 10
	var stage_right: = center_col + 10
	var stage_top: = center_row - 4
	var stage_bottom: = center_row + 3
	if stage_left < 1 or stage_right >= cols - 1 or stage_top < 1 or stage_bottom >= rows - 1:
		return false

	var bedrock_left: = stage_left + 18
	var bedrock_right: = stage_right
	var capture_mine: = Dictionary(world.get("mine")).duplicate(true)
	var solids: = Array(capture_mine.get("solids", [])).duplicate(true)
	var solid_index: = solids.size()
	solids.append(
		{
			"x": float(bedrock_left) * 48.0,
			"y": float(stage_top) * 48.0,
			"w": float(bedrock_right - bedrock_left + 1) * 48.0,
			"h": float(stage_bottom - stage_top + 1) * 48.0,
			"role": "visual_capture_edge_regression_bedrock",
		}
	)
	capture_mine["solids"] = solids
	world.set("mine", capture_mine)

	var blocks: = Dictionary(world.get("blocks"))
	var mineable_edge_voids: = Dictionary(world.get("mineable_edge_void_cells"))
	var terrain_hp: = int(GameData.data.MINE_TERRAIN_HP)
	for row in range(stage_top, stage_bottom + 1):
		for col in range(stage_left, stage_right + 1):
			var cell: = Vector2i(col, row)
			blocks.erase(cell)
			mineable_edge_voids.erase(cell)

	for local_row in range(0, 8):
		for local_col in range(0, 21):
			var cell: = Vector2i(stage_left + local_col, stage_top + local_row)
			var terrain: = (
				(local_col >= 2 and local_col <= 5 and local_row <= 4)
				or (
					local_col >= 13
					and local_col <= 17
					and local_row == 2
				)
				or (
					local_col >= 12
					and local_col <= 17
					and local_row >= 3
				)
			)
			if local_col >= 18:
				var bedrock_block: = Dictionary(
					world.call(
						"_make_block", "bedrock", 1, 99, "visual_capture_edge_regression_bedrock"
					)
				)
				bedrock_block["bedrock_solid_index"] = solid_index
				blocks[cell] = bedrock_block
			elif terrain:
				blocks[cell] = world.call("_make_block", "stone", terrain_hp, 0, "terrain")
			elif local_col <= 8:
				# Intentionally absent and untracked: this is authored walkable
				# clearance, not an excavation that may expose mineable edge art.
				pass
			elif local_col >= 10:
				# The right fixture is actual excavation. Recording it makes that
				# provenance explicit; only these missing cells may expose a rim.
				RunState.mark_terrain_dug(active_mine_id, cell.y * cols + cell.x, 1)
				mineable_edge_voids[cell] = true

	world.set("blocks", blocks)
	world.set("mineable_edge_void_cells", mineable_edge_voids)
	_clear_d1_capture_overlays(world, stage_left, stage_right, stage_top, stage_bottom)
	world.call("_rebuild_role_counts")

	var u_left: = Vector2i(stage_left + 2, stage_top + 4)
	var u_right: = Vector2i(stage_left + 5, stage_top + 4)
	var u_left_sides: Array[bool] = world.call("_mineable_edge_open_sides", u_left)
	var u_right_sides: Array[bool] = world.call("_mineable_edge_open_sides", u_right)
	if u_left_sides.has(true) or u_right_sides.has(true):
		return false

	var compact_join: = Vector2i(stage_left + 13, stage_top + 2)
	var compact_sides: Array[bool] = world.call("_mineable_edge_open_sides", compact_join)
	var expected_compact_sides: Array[bool] = [true, false, false, true]
	if compact_sides != expected_compact_sides:
		return false
	var compact_block: = Dictionary(blocks[compact_join])
	if (
		not bool(world.call("_block_emits_mineable_corner", compact_block, compact_sides))
		or not bool(world.call("_mineable_corner_uses_compact_join", compact_sides))
	):
		return false
	var below_sides: Array[bool] = world.call(
		"_mineable_edge_open_sides", compact_join + Vector2i.DOWN
	)
	if bool(below_sides[3]):
		return false
	var bedrock_probe: = Vector2i(bedrock_left, stage_top + 2)
	if bool(world.call("_block_emits_mineable_edge", Dictionary(blocks[bedrock_probe]))):
		return false

	world.call("_request_redraw")
	_frame_world(
		world,
		Vector2(world.call("_cell_center", Vector2i(stage_left + 10, stage_top + 4))),
		Vector2(world.call("_cell_center", compact_join)),
		Vector2(0.0, -24.0)
	)
	return true


func _prepare_d1_bedrock_stage(world: Node) -> bool:
	# Every D1 biome gets the same authored-material comparison room: ordinary
	# mineable terrain above, player-dug space below, and a central bedrock mass.
	# The mineable lower rim terminates flush against the bedrock on both sides.
	var cols: = int(world.get("cols"))
	var rows: = int(world.get("rows"))
	if cols < 24 or rows < 24:
		return false
	var center_col: = floori(float(cols) * 0.5)
	var seam_row: = floori(float(rows) * 0.5)
	var stage_left: = center_col - 11
	var stage_right: = center_col + 10
	var stage_top: = seam_row - 8
	var stage_bottom: = seam_row + 6
	var bedrock_left: = center_col - 3
	var bedrock_right: = center_col + 2
	var bedrock_top: = stage_top
	var bedrock_bottom: = seam_row + 1
	if stage_left < 1 or stage_right >= cols - 1 or stage_top < 1 or stage_bottom >= rows - 1:
		return false

	# The renderer samples each bedrock surface in the local UV space of its
	# owning solid, so the QA block is registered as a real capture-only solid.
	var capture_mine: = Dictionary(world.get("mine")).duplicate(true)
	var solids: = Array(capture_mine.get("solids", [])).duplicate(true)
	var solid_index: = solids.size()
	solids.append(
		{
			"x": float(bedrock_left) * 48.0,
			"y": float(bedrock_top) * 48.0,
			"w": float(bedrock_right - bedrock_left + 1) * 48.0,
			"h": float(bedrock_bottom - bedrock_top + 1) * 48.0,
			"role": "visual_capture_bedrock",
		}
	)
	capture_mine["solids"] = solids
	world.set("mine", capture_mine)

	var blocks: = Dictionary(world.get("blocks"))
	var mineable_edge_voids: = Dictionary(world.get("mineable_edge_void_cells"))
	var terrain_hp: = int(GameData.data.MINE_TERRAIN_HP)
	for row in range(stage_top, stage_bottom + 1):
		for col in range(stage_left, stage_right + 1):
			var cell: = Vector2i(col, row)
			if (
				col >= bedrock_left
				and col <= bedrock_right
				and row >= bedrock_top
				and row <= bedrock_bottom
			):
				var bedrock_block: = Dictionary(
					world.call("_make_block", "bedrock", 1, 99, "visual_capture_bedrock")
				)
				bedrock_block["bedrock_solid_index"] = solid_index
				blocks[cell] = bedrock_block
				mineable_edge_voids.erase(cell)
			elif row <= seam_row - 1:
				blocks[cell] = world.call("_make_block", "stone", terrain_hp, 0, "terrain")
				mineable_edge_voids.erase(cell)
			else:
				blocks.erase(cell)
				mineable_edge_voids[cell] = true
	world.set("blocks", blocks)
	world.set("mineable_edge_void_cells", mineable_edge_voids)
	_clear_d1_capture_overlays(world, stage_left, stage_right, stage_top, stage_bottom)
	world.call("_rebuild_role_counts")
	world.call("_request_redraw")
	_frame_world(
		world,
		Vector2(world.call("_cell_center", Vector2i(center_col, seam_row + 3))),
		Vector2(world.call("_cell_center", Vector2i(center_col, seam_row - 1))),
		Vector2(0.0, -96.0)
	)
	return true


func _clear_d1_capture_overlays(
	world: Node,
	stage_left: int,
	stage_right: int,
	stage_top: int,
	stage_bottom: int
) -> void :
	var cols: = int(world.get("cols"))
	for property_name in [
		"depth_entrance_cells",
		"depth_entrance_boundary",
		"concealed_cavern_cells",
		"cavern_boundary_by_index",
		"pocket_reward_cells",
	]:
		var index_map: = Dictionary(world.get(String(property_name)))
		for row in range(stage_top, stage_bottom + 1):
			for col in range(stage_left, stage_right + 1):
				index_map.erase(row * cols + col)
		world.set(String(property_name), index_map)
	world.set("drops", [])
	world.set("impacts", [])
	world.set("current_target", Vector2i(-1, -1))


func _prepare_d1_transition(mine_id: String) -> bool:
	var world: = _load_d1(mine_id, true)
	if world == null:
		return false
	var target: = Vector2(world.get("depth_entrance"))
	_frame_world(world, target + Vector2(118.0, 0.0), target)
	return true


func _prepare_d1_barrier(mine_id: String, barrier_id: String, variant: String) -> bool:
	var world: = _load_d1(mine_id)
	if world == null:
		return false
	var barrier: = _d1_barrier_definition(world, barrier_id)
	if barrier.is_empty():
		return false
	var required: = int(barrier.requiresPickaxe)
	RunState.pickaxe_level = maxi(0, required - 1) if variant == "locked" else required
	if variant == "damaged":
		var blocks: Dictionary = Dictionary(world.get("blocks"))
		for cell_value in blocks.keys():
			var cell: = Vector2i(cell_value)
			var block: Dictionary = Dictionary(blocks[cell])
			if String(block.get("role", "")) != barrier_id:
				continue
			block["hp"] = maxi(1, roundi(float(block.get("max_hp", 1)) * 0.45))
			blocks[cell] = block
		world.set("blocks", blocks)
	elif variant in ["partial_first", "partial_middle", "partial_last"]:
		var vertical: = float(barrier.h) >= float(barrier.w)
		var role_cells: = _d1_barrier_cells(world, barrier_id, vertical)
		if role_cells.size() < 3:
			return false
		var remove_index: = 0
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
	var rect: = Rect2(
		float(barrier.x), float(barrier.y), float(barrier.w), float(barrier.h)
	)
	var target: = rect.get_center()
	var approach: = Vector2(-145.0, 0.0) if rect.size.y >= rect.size.x else Vector2(0.0, -145.0)
	_frame_world(world, target + approach, target)
	return true


func _d1_barrier_cells(world: Node, barrier_id: String, vertical: bool) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var blocks: Dictionary = Dictionary(world.get("blocks"))
	for cell_value in blocks.keys():
		var cell: = Vector2i(cell_value)
		var block: Dictionary = Dictionary(blocks[cell])
		if String(block.get("role", "")) == barrier_id:
			result.append(cell)
	result.sort_custom( func(a: Vector2i, b: Vector2i) -> bool:
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
	var cols: = int(world.get("cols"))
	var rows: = int(world.get("rows"))
	var world_center: = Vector2(world.get("world_size")) * 0.5
	var best: Dictionary = {}
	var best_score: = INF
	for row in range(1, rows - 1):
		for col in range(1, cols - 1):
			var cell: = Vector2i(col, row)
			if not blocks.has(cell):
				continue
			var block: Dictionary = Dictionary(blocks[cell])
			var matches: = String(block.get("kind", "")) == "bedrock" if bedrock else (
				String(block.get("kind", "")) != "bedrock"
				and String(block.get("role", "")) == "terrain"
			)
			if not matches:
				continue
			var open_sides: Array[bool] = []
			for offset in CARDINALS:
				open_sides.append( not blocks.has(cell + Vector2i(offset)))
			var open_side: = -1
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
			var target: = Vector2(world.call("_cell_center", cell))
			var score: = target.distance_squared_to(world_center)
			if score >= best_score:
				continue
			best_score = score
			best = {
				"target": target,
				"player": Vector2(world.call("_cell_center", cell + Vector2i(CARDINALS[open_side]))),
			}
	return best


func _prepare_d2_edges(mine_id: String) -> bool:
	var world: = _load_d2(mine_id)
	if world == null:
		return false
	var view: = _find_d2_wall_view(world)
	if view.is_empty():
		return false
	_frame_world(world, Vector2(view.player), Vector2(view.target))
	return true


func _prepare_d2_bedrock(mine_id: String) -> bool:
	var world: = _load_d2(mine_id)
	if world == null:
		return false


	var terrain_hp: PackedInt32Array = world.get("terrain_hp")
	var concealed: Dictionary = Dictionary(world.get("concealed_cells"))
	for row in range(1, 8):
		for col in range(1, 9):
			var cell: = Vector2i(col, row)
			var index: = int(world.call("_cell_index", cell))
			terrain_hp[index] = 0
			concealed.erase(index)
	world.set("terrain_hp", terrain_hp)
	world.set("concealed_cells", concealed)
	world.call("_request_redraw")
	var player_position: = Vector2(world.call("_cell_center", Vector2i(4, 4)))
	var target: = Vector2(world.call("_cell_center", Vector2i(0, 0)))
	_frame_world(world, player_position, target)
	return true


func _find_d2_wall_view(world: Node) -> Dictionary:
	var cols: = int(world.get("cols"))
	var rows: = int(world.get("rows"))
	var world_center: = Vector2(world.get("world_size")) * 0.5
	var best: Dictionary = {}
	var best_score: = INF
	for row in range(1, rows - 1):
		for col in range(1, cols - 1):
			var cell: = Vector2i(col, row)
			if bool(world.call("_terrain_is_bedrock", cell)) or not bool(world.call("_visual_is_solid", cell)):
				continue
			var open_sides: Array[bool] = []
			for offset in CARDINALS:
				open_sides.append( not bool(world.call("_visual_is_solid", cell + Vector2i(offset))))
			var open_side: = -1
			for pair_value in ADJACENT_SIDE_PAIRS:
				var pair: Array = Array(pair_value)
				if bool(open_sides[int(pair[0])]) and bool(open_sides[int(pair[1])]):
					open_side = int(pair[0])
					break
			if open_side < 0:
				continue
			var target: = Vector2(world.call("_cell_center", cell))
			var score: = target.distance_squared_to(world_center)
			if score >= best_score:
				continue
			best_score = score
			best = {
				"target": target,
				"player": Vector2(world.call("_cell_center", cell + Vector2i(CARDINALS[open_side]))),
			}
	return best


func _prepare_d2_transition(mine_id: String) -> bool:
	var world: = _load_d2(mine_id)
	if world == null:
		return false
	var target: = Vector2(world.get("depth_entrance"))
	_frame_world(world, target + Vector2(125.0, 0.0), target)
	return true


func _prepare_d2_gate(mine_id: String, gate_index: int, variant: String) -> bool:
	var world: = _load_d2(mine_id)
	if world == null:
		return false
	var gates: Array = world.call("get_drill_gates")
	if gate_index < 0 or gate_index >= gates.size():
		return false
	var gate: Dictionary = Dictionary(gates[gate_index])
	var gate_id: = String(gate.id)
	var rocks: Array = world.get("rocks")
	var discovered_cavern: = false
	for rock_value in rocks:
		var rock: Dictionary = Dictionary(rock_value)
		if not bool(rock.get("drill_gated", false)) or String(rock.get("deposit_id", "")) != gate_id:
			continue
		var cavern_id: = String(rock.get("cavern_id", ""))
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
	var min_position: = Vector2(positions[0])
	var max_position: = min_position
	for position_value in positions:
		var position: = Vector2(position_value)
		min_position = min_position.min(position)
		max_position = max_position.max(position)
	var vertical: = (max_position.y - min_position.y) > (max_position.x - min_position.x)
	matching_indices.sort_custom(
		func(left: int, right: int) -> bool:
			var left_position: = Vector2(Dictionary(rocks[left]).position)
			var right_position: = Vector2(Dictionary(rocks[right]).position)
			return left_position.y < right_position.y if vertical else left_position.x < right_position.x
	)
	var gate_cells: Array[Vector2i] = []
	for rock_index in matching_indices:
		gate_cells.append(Vector2i(Dictionary(rocks[rock_index]).cell))
	var staging: = _stage_d2_gate_view(world, rocks, matching_indices, gate_cells, vertical)
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
	var target: = (min_position + max_position) * 0.5
	_frame_world(world, Vector2(staging.player), target)
	return true


func _stage_d2_gate_view(
	world: Node,
	rocks: Array,
	matching_indices: Array[int],
	gate_cells: Array[Vector2i],
	vertical: bool
) -> Dictionary:





	if gate_cells.is_empty():
		return {}
	var min_cell: = gate_cells[0]
	var max_cell: = gate_cells[0]
	for cell in gate_cells:
		min_cell = Vector2i(mini(min_cell.x, cell.x), mini(min_cell.y, cell.y))
		max_cell = Vector2i(maxi(max_cell.x, cell.x), maxi(max_cell.y, cell.y))
	var clear_min: = min_cell - (Vector2i(4, 2) if vertical else Vector2i(2, 4))
	var clear_max: = max_cell + (Vector2i(0, 2) if vertical else Vector2i(2, 0))
	var cols: = int(world.get("cols"))
	var rows: = int(world.get("rows"))
	clear_min.x = clampi(clear_min.x, 1, cols - 2)
	clear_min.y = clampi(clear_min.y, 1, rows - 2)
	clear_max.x = clampi(clear_max.x, 1, cols - 2)
	clear_max.y = clampi(clear_max.y, 1, rows - 2)
	var terrain_hp: PackedInt32Array = world.get("terrain_hp")
	var concealed: Dictionary = Dictionary(world.get("concealed_cells"))
	var staged_cells: Dictionary = {}
	for row in range(clear_min.y, clear_max.y + 1):
		for col in range(clear_min.x, clear_max.x + 1):
			var cell: = Vector2i(col, row)
			if bool(world.call("_terrain_is_bedrock", cell)):
				continue
			var cell_index: = int(world.call("_cell_index", cell))
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
	var player_cell: = Vector2i(
		min_cell.x - 3 if vertical else floori(float(min_cell.x + max_cell.x) * 0.5),
		floori(float(min_cell.y + max_cell.y) * 0.5) if vertical else min_cell.y - 3
	)
	player_cell.x = clampi(player_cell.x, clear_min.x, clear_max.x)
	player_cell.y = clampi(player_cell.y, clear_min.y, clear_max.y)
	var player_position: = Vector2(world.call("_cell_center", player_cell))
	var safe_position: = Vector2(world.call("_nearest_safe_position", player_position))
	if safe_position.distance_to(player_position) > 1.0:
		return {}
	return {"player": player_position, "rocks": rocks}


func _prepare_endless_walls(layer: int) -> bool:
	_reset_run()



	var previous_world: = _main.get("endless_world") as Node
	if previous_world != null:
		previous_world.call("set_active", false)
	_main.set("phase", "surface")
	if not bool(_main.call("_dev_jump_endless", layer)):
		return false
	var world: = _main.get("endless_world") as Node
	if world == null:
		return false
	var floor_cells: PackedByteArray = world.get("floor_cells")
	var grid_size: = Vector2i(40, 22)
	var world_center: = Vector2(grid_size) * 32.0
	var best: Dictionary = {}
	var best_score: = INF



	for require_corner in [true, false]:
		for row in range(1, grid_size.y - 1):
			for col in range(1, grid_size.x - 1):
				var cell: = Vector2i(col, row)
				var index: = row * grid_size.x + col
				if floor_cells[index] != 0:
					continue
				var floor_sides: Array[bool] = []
				for offset in CARDINALS:
					var neighbour: = cell + Vector2i(offset)
					var neighbour_index: = neighbour.y * grid_size.x + neighbour.x
					floor_sides.append(floor_cells[neighbour_index] != 0)
				var floor_side: = -1
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
				var target: = Vector2(world.call("_cell_center", cell))
				var score: = target.distance_squared_to(world_center)
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


func _frame_world(
	world: Node,
	player_position: Vector2,
	target: Vector2,
	camera_offset: Vector2 = Vector2.ZERO
) -> void :
	world.call("restore_position", player_position)
	if world.has_method("set_external_movement"):
		world.call("set_external_movement", Vector2.ZERO)
	var player: = world.get("player") as Node
	if player != null:
		player.set("control_enabled", false)
		if player.has_method("set_external_movement"):
			player.call("set_external_movement", Vector2.ZERO)
		var direction: = target - Vector2(player.get("global_position"))
		if not direction.is_zero_approx() and player.has_method("set_facing"):
			player.call("set_facing", direction.normalized())
		var camera: = player.get("camera") as Camera2D
		if camera != null:
			camera.position = camera_offset
			camera.position_smoothing_enabled = false
			camera.make_current()
			camera.reset_smoothing()
	_main.call("_refresh_hud")
	if world.has_method("_request_redraw"):
		world.call("_request_redraw")
	else:
		world.queue_redraw()


func _fail(reason: String) -> void :
	_waiting_for_ack = false
	print("EVER_DEEPER_VISUAL_CAPTURE_FAILED reason=%s" % reason.replace(" ", "_"))
	push_error("Visual capture suite failed: %s" % reason)
	get_tree().quit(72)
