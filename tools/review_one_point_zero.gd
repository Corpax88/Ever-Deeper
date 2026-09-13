extends SceneTree
## External acceptance harness for the immutable exported DEV PCK.
## Fixture funding accelerates campaign transactions; relics are generated,
## hauled, placed and built through their real runtime owners. No release claim.
const LARGE_VIEW: = Vector2i(2532, 1170)
const SMALL_VIEW: = Vector2i(844, 390)
const FIXTURE_SEED: int = 4608
var output_dir: String = ""
var pack_source: String = ""
var main: Node
var state: Node
var world: Node
var journey: RefCounted
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var failures: Array[String] = []
var seen_strata: Dictionary = {}
var frame_size: Vector2i = LARGE_VIEW
var started_usec: int = 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> bool:
	checks.append({"passed": ok, "assertion": message})
	if not ok:
		failures.append(message)
		print("ONE_POINT_ZERO_RENDER_FAIL " + message)
	return ok

func _run() -> void:
	started_usec = Time.get_ticks_usec()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.trim_prefix("--output=")
		if arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
	if not _check(not output_dir.is_empty(), "Explicit isolated output directory required"): quit(3); return
	DirAccess.make_dir_recursive_absolute(output_dir)
	if not _check(DisplayServer.get_name() != "headless", "Rendered display required"): _finish(); return
	# Godot consumes --main-pack before exposing its arguments to scripts. The
	# launcher verifies that exact invocation; the loaded resource root must be
	# an exported project, and its supplied immutable package is hashed below.
	if not _check(FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot"), "Exported resource root required; editable source refused"): _finish(); return
	if not _check(FileAccess.file_exists(pack_source) and FileAccess.get_sha256(pack_source).length() == 64, "Explicit hashable package artifact required"): _finish(); return
	if not _check(OS.has_feature("ever_deeper_dev"), "DEV export required; source execution is not release evidence"): _finish(); return
	await _resize(LARGE_VIEW)
	state = root.get_node("RunState")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _settle(5)
	state.initialize_persistence(output_dir.path_join("isolated-capture-save.json"))
	state.reset_run(false)
	state.world_seed = FIXTURE_SEED
	seed(FIXTURE_SEED)
	main._start_new_game()
	main._dev_ensure_playing()
	if "--drill-guide-only" in OS.get_cmdline_user_args():
		await _drill_resource_guide_capture()
		_finish()
		return
	main._enter_mine("mossMine", false, false)
	await _settle(8)
	_check(String(main.mine_button.icon.resource_path) == "res://assets/tools/pickaxe-iron.png", "Mine action uses approved pickaxe asset")
	main.quick_tutorial.open(false)
	await _capture("01-new-player-keyboard-tutorial", {"fixture": "Existing keyboard tutorial explicitly opened; ordinary native input detection unchanged"}, true)
	main.quick_tutorial.open(true)
	await _capture("01-new-player-touch-tutorial", {"fixture": "Existing touch tutorial explicitly opened for mobile acceptance; ordinary input detection unchanged"}, true)
	main.quick_tutorial.dismiss()
	await _capture("01-new-player-hud", {"fixture": "Fresh player inside first mine"}, true)
	if not await _recipe_capture(): _finish(); return
	if not await _hub_guide_capture(): _finish(); return
	if not await _drill_resource_guide_capture(): _finish(); return

	journey = load("res://scripts/qa/suites/one_point_zero_world.gd").new(main, null)
	if not _check(journey._new_player_to_deep(), "Campaign prerequisites completed through real transactions"): _finish(); return
	state.world_seed = FIXTURE_SEED
	main._enter_endless(true, false)
	world = main.endless_world
	journey.world = world
	await _settle(8)
	_check(bool(world.stream_snapshot().continuous), "The Deep uses a continuous resident window")
	await _capture("03-deep-entrance", {"fixture": "First entry; ordinary approved camera"})
	if not await _local_discovery_capture(): _finish(); return
	if not await _mine_corner("04-deep-mined-corner"): _finish(); return
	if not _bedrock_fixture(): _finish(); return
	await _capture("05-diggable-and-bedrock", {"fixture": "Approach excavated through actual wall owner; boundary intact"})
	seen_strata[1] = true

	for relic_value in state.ENDLESS_RELIC_IDS:
		var relic_id: String = String(relic_value)
		if main.phase == "hub": main._enter_endless(true, false)
		world = main.endless_world
		journey.world = world
		var target_depth: int = int(state.next_endless_relic_depth())
		while int(world.current_depth) < target_depth:
			var next_depth: int = int(world.current_depth) + 1
			var absolute: Vector2 = _absolute_position()
			var target: Vector2 = Vector2(absolute.x, float(next_depth - 1) * float(world.CHUNK_HEIGHT) + 320.0)
			if not _check(await journey._walk_and_mine_to(target), "Held mining reaches continuous band %d" % next_depth): _finish(); return
			_thaw()
			if next_depth <= 5 and not seen_strata.has(next_depth):
				seen_strata[next_depth] = true
				if not await _mine_corner("stratum-%d-mined-edge" % next_depth): _finish(); return
		if not await _relic_cycle(relic_id, relic_id == "forge_heart"): _finish(); return

	var complete: Dictionary = state.endless_descent_status()
	_check(int(complete.placed_relic_count) == 5 and int(complete.built_workshop_count) == 5, "Five generated relics complete five Hub workshops")
	main._sync_hub_runtime()
	main.hub_world.restore_position(Vector2(720, 495))
	main.hub_world.player.set_facing(Vector2.UP)
	await _settle_hub()
	await _capture("hub-five-workshops-complete", {"fixture": "Five actual relic placements and workshop transactions"}, true)
	main.hub_world.restore_position(Vector2(main.hub_world.RELIC_PEDESTAL_POSITION))
	await _capture("hub-museum-complete-selected", {"fixture": "Completed museum with actual pedestal proximity selection"})
	await _workshop_capture("tool_forge", "hub-tool-forge-upgrade")
	await _workshop_capture("lift_workshop", "hub-tunnel-workshop-bonus")
	if not await _tool_skin_capture(): _finish(); return
	main._enter_endless(true, false)
	world = main.endless_world
	journey.world = world
	var before: int = int(state.total_mined_resources())
	var farther: Vector2 = _absolute_position() + Vector2(0, float(world.CHUNK_HEIGHT) * 1.1)
	if not _check(await journey._walk_and_mine_to(farther), "Mining continues beyond fifth relic"): _finish(); return
	_thaw()
	_check(int(state.total_mined_resources()) > before, "Post-fifth excavation grants real materials")
	_check(not bool(state.endless_descent_status().exploration_complete), "The Deep never reports a final floor")
	await _capture("post-fifth-deeper-mining", {"fixture": "Actual held mining beyond the fifth relic"})
	_check(Array(journey.failures).is_empty(), "Reused journey assertions remain clean")
	_finish()

func _recipe_capture() -> bool:
	main._dev_seed_all_zones_state()
	state.victory = false
	state.singularity_secured = false
	state.mark_hub_tutorial_seen()
	for drill_level in [1, 2]:
		state.set_drill_level(drill_level)
		var recipe: Dictionary = state.next_drill_recipe()
		var requirements: Array = Array(recipe.get("requirements", []))
		var expected_rows: int = drill_level + 3
		if not _check(requirements.size() + 1 == expected_rows, "Actual %d-row campaign recipe exists" % expected_rows): return false
		for resource_id in state.cargo:
			state.cargo[resource_id] = 0
		state.gold = int(recipe.gold) * 2 / 3
		for index in requirements.size():
			var row: Dictionary = requirements[index]
			state.cargo[String(row.type)] = int(row.amount) if index == 1 else maxi(1, int(row.amount) / 3)
		state.cargo["copper"] = 14
		state.changed.emit()
		main._enter_mine("emberMine", false, false)
		main._enter_depth(false, false)
		await _settle(6)
		var snapshot: Dictionary = main.premium_hud.progression_goal_snapshot()
		if not _check(Array(snapshot.get("requirements", [])).size() == expected_rows, "HUD displays all %d real drill requirements" % expected_rows): return false
		await _capture("02-%d-row-recipe" % expected_rows, {"fixture": "Partial recipe materials; banked gold and explicitly pending sale value", "recipe_rows": expected_rows}, true)
	return true

func _hub_guide_capture() -> bool:
	main._dev_seed_all_zones_state()
	state.victory = false
	state.singularity_secured = false
	state.drill_level = 0
	state.starforge_variant = "crusher"
	state.hub["visited"] = false
	state.hub["tutorialSeen"] = false
	for resource_id in state.cargo: state.cargo[resource_id] = 0
	main._dev_jump_surface()
	main.surface_world.restore_position(Vector2(state.HUB_SURFACE_ENTRANCE))
	if not _check(String(main.guide_director.goal_for_state().objective_id) == "hub:first_visit", "Unvisited Starforge player is guided to the Hub"): return false
	await _capture("02-hub-guide-before-entry", {"fixture": "Starforge Crusher, no drill, first Hub visit"}, true)
	main._enter_hub()
	main._checkpoint_location()
	if not _check(not state.hub_tutorial_pending() and String(main.guide_director.goal_for_state().objective_id) == "drill:1", "Actual Hub entry and checkpoint advance the guide"): return false
	await _capture("02-hub-guide-after-entry", {"fixture": "Real Hub entry followed by checkpoint; next drill is active"}, true)
	main._exit_hub()
	if not _check(String(main.guide_director.goal_for_state().objective_id) == "drill:1", "Exiting the Hub retains the drill goal"): return false
	await _capture("02-hub-guide-after-exit", {"fixture": "Real Hub exit; no return-to-Hub loop"}, true)
	return true

func _drill_resource_guide_capture() -> bool:
	var fixture: Node = load("res://scripts/dev/visual_capture_driver.gd").new()
	main.add_child(fixture)
	fixture.set("_main", main)
	for mine_id in ["mossMine", "moonMine", "emberMine"]:
		if not _check(fixture._prepare_d2_gate(mine_id, 0, "intact"), "Gate ore render fixture " + mine_id): return false
		main._dev_seed_all_zones_state()
		var depth: Node = main.depth_world
		depth.set_process(false)
		var gate: Dictionary = depth.get_drill_gates()[0]
		state.drill_level = int(gate.required_drill_level)
		state.pickaxe_level = 5
		state.starforge_variant = "crusher"
		state.hub["visited"] = true
		state.hub["tutorialSeen"] = true
		for resource_id in state.cargo: state.cargo[resource_id] = 0
		state.gold = 22618
		var target: int = -1
		for i in depth.rocks.size():
			if String(depth.rocks[i].deposit_id) == String(gate.id) and depth._rock_is_exposed(i): target = i; break
		if not _check(target >= 0, "Exposed ore gate " + mine_id): return false
		var ore_position: Vector2 = Vector2(depth.rocks[target].position)
		var approach: Vector2 = (ore_position - depth.player.global_position).normalized()
		depth.restore_position(ore_position - approach * 72.0)
		await _capture("02-drill-guide-" + mine_id + "-barrier", {"fixture":"First required drill, intact authored gate"}, true)
		for hit in 10: depth._hit_rock(target)
		if not _check(int(depth.get_drill_gates()[0].remaining) == 0, "Gate opens through actual strikes " + mine_id): return false
		for drop in depth.drops: drop.age = 1.0
		depth.companion_collect_loot(depth.player.global_position, 10000.0)
		var stand: Vector2 = depth.player.global_position
		depth.player.global_position = stand + Vector2(1000, 0)
		for rock in depth.rocks:
			if String(rock.state_id).begins_with("seam:"): rock.respawn_until_unix = Time.get_unix_time_from_system() - 1.0
		depth._update_rocks()
		depth.player.global_position = stand
		depth._request_redraw()
		await _capture("02-drill-guide-" + mine_id + "-renewable-ore", {"fixture":"Actual cleared gate; only ore regrowth clock accelerated"}, true)
		if mine_id == "mossMine":
			for i in depth.rocks.size():
				if String(depth.rocks[i].state_id).begins_with("seam:") and depth._rock_is_exposed(i):
					for hit in 100:
						depth._hit_rock(i)
						if bool(depth.rocks[i].broken): break
					break
			await _capture("02-drill-guide-moss-loot", {"fixture":"Actual mined Burrowsteel pickup"}, true)
			for i in depth.rocks.size():
				if bool(depth.rocks[i].drill_gated) and not bool(depth.rocks[i].broken):
					for hit in 10: depth._strike_drill_gate(i)
			for i in depth.rocks.size():
				if String(depth.rocks[i].state_id).begins_with("seam:") and not bool(depth.rocks[i].broken): depth._break_rock(i)
			for drop in depth.drops: drop.age = 1.0
			depth.companion_collect_loot(stand, 10000.0)
			state.cargo.burrowsteel = 25
			var pending: Dictionary = main._guide_route_proposal(main._progression_goal())
			if not _check(String(pending.get("hud_action", "")).begins_with("Regrowing"), "Exhausted Burrowsteel displays regrowth instead of Rootiron"): return false
			await _capture("02-drill-guide-moss-regrowing", {"fixture":"All barriers completed via barrier transaction; depleted seams; cargo set to screenshot's 25"}, true)
			state.cargo.burrowsteel = 60
			var next: Dictionary = main._progression_goal()
			if not _check(String(next.get("resource_id", "")) == "prismite", "Satisfied Burrowsteel advances to Prismite"): return false
			await _capture("02-drill-guide-next-mine", {"fixture":"Burrowsteel requirement funded to isolate next-mine route"}, true)
	fixture.queue_free()
	return true

func _mine_corner(label: String) -> bool:
	_thaw()
	var edge: Dictionary = _find_diggable_edge()
	if not _check(not edge.is_empty(), "Mineable rock beside open floor for " + label): return false
	world.restore_position(Vector2(edge.stand))
	world.player.set_facing(Vector2(edge.facing))
	await _settle(4)
	var backlog: Dictionary = _clear_fixture_feedback()
	var cell: Vector2i = edge.cell
	var before: int = int(state.total_mined_resources())
	var before_floor: bool = bool(world._is_floor(cell))
	_mouse_button(main.mine_button, true)
	await process_frame
	if not _check(bool(main.mine_held) and bool(world.external_mine_held), "Viewport input starts held mine action"):
		var hovered: Control = root.gui_get_hovered_control()
		await _capture(label + "-input-failure", {"phase":main.phase, "held":main.mine_held, "world_held":world.external_mine_held, "mouse_held":main.mine_mouse_held, "touch_index":main.mine_touch_index, "shop_open":main._shop_panel_is_open(), "tunnel_home":main.tunnel_home_in_progress, "mine_visible":main.mine_button.is_visible_in_tree(), "hovered":str(hovered.get_path()) if hovered != null else "none"})
		return false
	# The input is held normally; repeated gameplay ticks accelerate the wait.
	journey._freeze_world()
	for step in 120:
		world._process(0.10)
		world._physics_process(0.10)
		if bool(world._is_floor(cell)): break
		if step % 6 == 0: await process_frame
	_mouse_button(main.mine_button, false)
	await process_frame
	_thaw()
	_check(not bool(main.mine_held), "Releasing pointer releases mine action")
	if not _check(not before_floor and bool(world._is_floor(cell)), "Real held mining opens selected rock"): return false
	_check(int(state.total_mined_resources()) > before, "Excavated rock grants materials")
	if label == "04-deep-mined-corner":
		# Keep one newly earned pickup visible separately from clean terrain views.
		# Slow software rendering must not age this real transient offscreen.
		Engine.time_scale = 0.0
		var feedback: Node = main._active_player_node().get_node_or_null("ResourcePickupBurst")
		if feedback != null: feedback._process(0.20)
		_check(feedback != null and not Array(feedback.debug_snapshot().entries).is_empty(), "Fresh held-mining pickup feedback remains visible")
		await _capture(label + "-fresh-pickup", {"fixture": "New reward from the immediately preceding real mine-button action", "preserve_fresh_feedback": true, "fixture_backlog_before_action": backlog, "frozen_time_for_transient_capture": true}, true)
		Engine.time_scale = 1.0
	await _capture(label, {"fixture": "Actual mine-button input; simulation wait accelerated", "cell": str(cell), "stratum_index": int(world.current_depth) % 5})
	return true

func _find_diggable_edge() -> Dictionary:
	var center: Vector2i = world._world_to_cell(world.player.global_position)
	for radius in range(1, 24):
		for y in range(maxi(2, center.y - radius), mini(int(world.GRID_SIZE.y) - 2, center.y + radius + 1)):
			for x in range(maxi(3, center.x - radius), mini(int(world.GRID_SIZE.x) - 3, center.x + radius + 1)):
				var cell: Vector2i = Vector2i(x, y)
				if not world._cell_diggable(cell) or world._is_floor(cell): continue
				if int(world.depth_at_position(world._cell_center(cell))) != int(world.current_depth): continue
				for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var stand_cell: Vector2i = cell + offset
					if world._is_floor(stand_cell):
						return {"cell": cell, "stand": world._cell_center(stand_cell), "facing": -Vector2(offset)}
	return {}

func _bedrock_fixture() -> bool:
	for y in range(1, 5):
		for x in range(2, 6):
			var cell: Vector2i = Vector2i(x, y)
			if not world._is_floor(cell): world._break_diggable_cell(cell)
	var boundary: Vector2i = Vector2i(1, 2)
	if not _check(not world._cell_diggable(boundary) and not world._break_diggable_cell(boundary), "Permanent boundary cannot be mined"): return false
	world.restore_position(world._cell_center(Vector2i(3, 2)))
	world.player.set_facing(Vector2.LEFT)
	world.queue_redraw()
	return true

func _relic_cycle(relic_id: String, capture_return: bool) -> bool:
	_thaw()
	world._select_native_relic()
	if not _check(String(world.native_relic_id) == relic_id, "Generated milestone present: " + relic_id): return false
	world.restore_position(Vector2(world.native_relic_position) + Vector2(64, 32))
	world._update_discoveries()
	world._update_context(world.player.global_position)
	main.endless_context = String(world.current_context())
	main._refresh_context_button()
	await _settle(3)
	if not _check(String(world.current_context()) == "endless_relic:" + relic_id, "Relic reached through actual proximity context"): return false
	await _tap(main.premium_hud.context_button)
	if not _check(bool(state.relic_status(relic_id).attached), "Action-button input attaches physical relic: " + relic_id): return false
	world.qa_step_rope(20, Vector2(0.2, -0.2))
	_check(bool(world.rope_debug_snapshot().finite), "Rope remains finite")
	await _capture("relic-" + relic_id + "-on-rope", {"fixture": "Generated relic; position accelerated, real context attachment"})
	var cargo: Dictionary = state.cargo.duplicate(true)
	# Context fallback is naturally available away from discovery interactions.
	if String(main.premium_hud.context_button.text) == "HOME":
		await _tap(main.premium_hud.context_button)
	else:
		_check(main.request_tunnel_home(), "Tunnel Home action owner accepts request")
	if not _check(bool(main.tunnel_home_in_progress), "Tunnel Home preparation is observable"): return false
	if capture_return:
		Engine.time_scale = 0.0
		var mole: Node = world.get_node_or_null("MoleCompanion")
		if mole != null: mole._physics_process(0.18)
		_check(mole != null and String(mole.action) == "tunnel", "Authored mole digging action active")
		await _capture("tunnel-home-digging", {"frozen_time_for_transient_capture": true, "mole": mole.debug_snapshot() if mole != null else {}})
		Engine.time_scale = 1.0
	for frame in 120:
		if main.phase == "hub": break
		await process_frame
	if not _check(main.phase == "hub", "Tunnel Home reaches Hub"): return false
	_check(state.cargo == cargo, "Home keeps collected materials")
	_check(bool(state.relic_status(relic_id).attached), "Home retains relic and rope")
	if capture_return:
		await _settle_hub()
		await _capture("tunnel-home-hub-arrival", {"fixture": "Actual completed Tunnel Home with attached relic"})
	var hub: Node = main.hub_world
	var pedestal: Vector2 = hub.RELIC_PEDESTAL_POSITION
	hub.restore_position(pedestal)
	hub.qa_set_hub_relic_endpoint(pedestal + Vector2(0, -16))
	if capture_return:
		await _capture("hub-pedestal-ready-unbuilt-museum", {"fixture": "First generated relic at real pedestal; selection visible before placement"})
	hub.perform_context()
	if not _check(bool(state.relic_status(relic_id).placed), "Pedestal physically places " + relic_id): return false
	var relic: Dictionary = state.relic_status(relic_id)
	var workshop_id: String = String(relic.workshop_id)
	var status: Dictionary = state.workshop_status(workshop_id)
	if not _check(bool(status.ready_to_build) and int(status.remaining) == 0, "Actual relic return supplies construction"): return false
	await _capture("relic-powered-" + workshop_id, {"fixture": "Generated relic physically delivered; workshop ready without additional resource funding"}, true)
	var before_build: Dictionary = state.cargo.duplicate(true)
	if not _check(bool(state.build_workshop(workshop_id).get("ok", false)), "Real workshop construction"): return false
	_check(state.cargo == before_build, "Relic-powered construction preserves gathered resources")
	main._sync_hub_runtime()
	if relic_id == "memory_loom":
		hub.restore_position(pedestal)
		await _capture("hub-museum-three-relics", {"fixture": "Three actual placed relics; chamber still unbuilt"})
	return true

func _local_discovery_capture() -> bool:
	var position: Vector2 = world.player.global_position
	var relic: Dictionary = world._native_relics[0]
	world.restore_position(Vector2(relic.position) + Vector2(-512, -64))
	await _settle(4)
	if not _check(String(main._progression_goal().get("hud_title", "")) == "A buried signal", "Undiscovered relic offers an excavation clue"): return false
	await _capture("03-buried-relic-signal", {"fixture": "Player positioned on nearby walkable ground; relic remains undiscovered"}, true)
	var site: Dictionary = world.discovery_sites[0]
	world.restore_position(Vector2(site.position))
	world._update_discoveries()
	await _settle(4)
	var goal: Dictionary = main._progression_goal()
	if not _check(String(goal.get("objective_id", "")).begins_with("endless:discovery:"), "Actual exposed discovery supplies the local goal"): return false
	await _capture("03-local-cache-choice", {"fixture": "Player positioned at generated cache; ordinary proximity/line-of-sight discovery"}, true)
	if not _check(world._start_site_activity(int(site.index), "stabilize"), "Actual cache recovery begins"): return false
	await _capture("03-local-cache-rune", {"fixture": "Actual active cache activity; guide follows the authored next rune"}, true)
	world._cancel_site_activity()
	world.restore_position(position)
	await _settle(4)
	return true


func _workshop_capture(workshop_id: String, label: String) -> void:
	var hub: Node = main.hub_world
	hub.restore_position(Vector2(hub.WORKSHOP_POSITIONS[workshop_id]) + Vector2(0, 70))
	var status: Dictionary = state.workshop_status(workshop_id)
	var recipe: Dictionary = Dictionary(status.get("next_upgrade", {}))
	if not recipe.is_empty():
		state.add_resource(String(recipe.resource), int(recipe.cost), false)
		status = state.workshop_status(workshop_id)
	var catalog: Script = load("res://scripts/ui/commerce_catalog.gd")
	var config: Dictionary = catalog.workshop_config(workshop_id, status, hub.workshop_selection_preview(workshop_id))
	main._open_commerce(config, "workshop:" + workshop_id)
	await _settle(8)
	_check(bool(main.commerce_panel.visible), "Existing premium workshop shop opens")
	await _capture(label, {"fixture": "Real workshop status and transaction-backed upgrade preview"})
	main.commerce_panel.close_commerce()
	await _settle(3)

func _tool_skin_capture() -> bool:
	var appearances: Dictionary = {"crusher":"crusher", "comet":"comet", "crownseeker":"crown", "deepheart":"ember", "original":"deepcore"}
	var catalog: Script = load("res://scripts/ui/commerce_catalog.gd")
	for style in appearances:
		var required_level: int = ["original", "crusher", "comet", "crownseeker", "deepheart"].find(style) + 1
		while int(state.workshop_status("tool_forge").level) < required_level:
			var recipe: Dictionary = state.workshop_status("tool_forge").next_upgrade
			state.add_resource(String(recipe.resource), int(recipe.cost), false)
			if not _check(bool(state.upgrade_workshop("tool_forge").get("ok", false)), "Paid skin unlock level"): return false
		main._sync_hub_runtime()
		main.hub_world.restore_position(Vector2(main.hub_world.WORKSHOP_POSITIONS.tool_forge) + Vector2(0, 100))
		main.hub_world.player.set_facing(Vector2.DOWN)
		var config: Dictionary = catalog.workshop_config("tool_forge", state.workshop_status("tool_forge"), main.hub_world.workshop_selection_preview("tool_forge"))
		config.selected_item_id = "workshop:equip:" + style
		main._open_commerce(config, "workshop:tool_forge")
		main._confirm_workshop_commerce_action("workshop:equip:" + style)
		if not _check(String(state.endless_loadout_status().tool) == style, "Actual shop action equips " + style): return false
		if not await _wait_for_skin(appearances[style]): return false
		await _capture("skin-hub-" + style, {"fixture":"Actual shop equip; existing native model; ordinary gameplay camera"}, true)
		main.hub_world.player.set_facing(Vector2.LEFT)
		await _capture("skin-hub-side-" + style, {"fixture":"Actual equipped skin silhouette from the side"})
		if style == "crusher":
			config = catalog.workshop_config("tool_forge", state.workshop_status("tool_forge"), main.hub_world.workshop_selection_preview("tool_forge"))
			config.selected_item_id = "workshop:equip:crusher"
			main._open_commerce(config, "workshop:tool_forge")
			await _capture("skin-shop-crusher-equipped", {"fixture":"Level 2 Tool Forge after real equip action"}, true)
			main.commerce_panel.close_commerce()
		main._enter_endless(true, false)
		if not _check(main.phase == "endless", "Skin fixture enters The Deep " + style): return false
		world = main.endless_world
		journey.world = world
		if not await _wait_for_skin(appearances[style]): return false
		await _settle(8)
		if not await _mine_corner("skin-mining-" + style): return false
		# Use the real return transaction so the descent ends before re-entry.
		if not _check(main.request_tunnel_home(), "Skin fixture requests Tunnel Home " + style): return false
		for frame in 120:
			if main.phase == "hub": break
			await process_frame
		if not _check(main.phase == "hub" and not bool(state.endless_descent_status().active), "Skin fixture completes return " + style): return false
		await _settle_hub()
	return true

func _wait_for_skin(expected: String) -> bool:
	var visual: Node = main._active_player_node().visual
	for frame in 300:
		await process_frame
		if String(visual.tool_visual_snapshot().gear) == expected: return true
	return _check(false, "Hero loads equipped appearance " + expected)

func _absolute_position() -> Vector2:
	return Vector2(world.player.global_position) + Vector2(0, float(world.window_start_depth - 1) * float(world.CHUNK_HEIGHT))

func _thaw() -> void:
	world.set_process(true)
	world.set_physics_process(true)
	world.player.set_physics_process(true)
	world.player.set_external_movement(Vector2.ZERO)
	world.set_external_movement(Vector2.ZERO)
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null: mole.set_physics_process(true)

func _mouse_button(control: Control, pressed: bool) -> void:
	var point: Vector2 = control.get_global_transform_with_canvas() * (control.size * 0.5)
	var move: = InputEventMouseMotion.new()
	move.position = point
	move.global_position = point
	root.push_input(move, true)
	var event: = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.position = point
	event.global_position = point
	event.pressed = pressed
	root.push_input(event, true)

func _tap(control: Control) -> void:
	_mouse_button(control, true)
	await process_frame
	_mouse_button(control, false)
	await process_frame

func _resize(dimensions: Vector2i) -> void:
	root.position = Vector2i.ZERO
	root.size = dimensions
	DisplayServer.window_set_size(dimensions)
	frame_size = dimensions
	await _settle(5)

func _settle(frames: int = 6) -> void:
	for frame in frames: await process_frame
	await RenderingServer.frame_post_draw

func _settle_hub() -> void:
	await _settle(8)
	var field: Node = main.hub_world.get("static_light_field")
	if field == null: return
	for frame in 200:
		if bool(field.get("ready_for_use")) and not bool(field.get("baking")): return
		await process_frame
	_check(false, "Hub fixed lighting finishes before capture")

func _capture(label: String, details: Dictionary = {}, also_small: bool = false) -> void:
	main._refresh_hud()
	main._update_visual_guide()
	main.premium_hud.set_status("")
	await _settle(6)
	var capture_details: Dictionary = details.duplicate(true)
	if not bool(details.get("preserve_fresh_feedback", false)):
		capture_details["fixture_backlog_cleared"] = _clear_fixture_feedback()
	var hover: = InputEventMouseMotion.new()
	hover.position = Vector2(-100, -100)
	hover.global_position = hover.position
	root.push_input(hover, true)
	await _save_frame(label, capture_details)
	if also_small:
		await _resize(SMALL_VIEW)
		await _save_frame(label + "-small", capture_details)
		await _resize(LARGE_VIEW)

func _clear_fixture_feedback() -> Dictionary:
	# Only this external accelerated-journey fixture discards its old feedback.
	# Normal runtime signals, processing and future notifications stay enabled.
	var discarded: Dictionary = {"reason": "Accelerated fixture transactions and mining backlog", "achievement": main.achievement_toast.debug_snapshot()}
	main.achievement_toast.clear()
	var player: Node = main._active_player_node()
	var feedback: Node = player.get_node_or_null("ResourcePickupBurst") if player != null else null
	if feedback != null:
		var snapshot: Dictionary = feedback.debug_snapshot()
		discarded["pickup"] = snapshot
		feedback._process(float(snapshot.hold_seconds) + float(snapshot.fade_seconds) + 0.1)
	return discarded

func _save_frame(label: String, details: Dictionary) -> void:
	if label.begins_with("02-drill-guide-"):
		# The gate fixture can be near a camera limit. Center the reviewed action,
		# and flush drawings explicitly because its simulation clock is frozen.
		var depth: Node = main.depth_world
		var camera: Camera2D = depth.player.camera
		camera.set_physics_process(false)
		camera.drag_horizontal_enabled = false
		camera.drag_vertical_enabled = false
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(depth.world_size.x)
		camera.limit_bottom = int(depth.world_size.y)
		camera.zoom = Vector2(2.5, 2.5)
		camera.position = Vector2.ZERO
		camera.offset = Vector2.ZERO
		camera.reset_smoothing()
		camera.force_update_scroll()
		main.quick_tutorial.visible = false
		depth.queue_redraw()
		await _settle(6)
		main._update_visual_guide()
		var player_screen: Vector2 = depth.player.get_global_transform_with_canvas().origin
		_check(player_screen.distance_to(root.get_visible_rect().get_center()) < 60.0, "Guide capture keeps player centered: " + label)
		var current_goal: Dictionary = main._progression_goal()
		if String(current_goal.get("mine_id", "")) == String(main.current_mine_id):
			var guide: Dictionary = main.guide_director.debug_snapshot()
			var target_screen: Vector2 = depth.get_global_transform_with_canvas() * Vector2(guide.target_position)
			_check(root.get_visible_rect().grow(-48).has_point(target_screen), "Required local ore stays visible: " + label)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var filename: String = label + ".png"
	_check(image.get_size() == frame_size, "Exact framebuffer " + filename)
	_check(image.save_png(output_dir.path_join(filename)) == OK, "Saved " + filename)
	var goal: Dictionary = main.premium_hud.progression_goal_snapshot()
	var metrics: Dictionary = main.premium_hud.layout_snapshot(root.get_visible_rect().size)
	var goal_rect: Rect2 = goal.get("panel_rect", Rect2())
	var minimap: Dictionary = main.minimap_overlay.debug_snapshot()
	var minimap_rect: Rect2 = minimap.get("map_rect", Rect2())
	var tutorial: Dictionary = main.quick_tutorial.debug_snapshot()
	var player: Node = main._active_player_node()
	var feedback: Node = player.get_node_or_null("ResourcePickupBurst") if player != null else null
	if label.contains("-tutorial"):
		_check(bool(tutorial.get("visible", false)) and int(tutorial.get("item_count", 0)) == 5, "All five tutorial hints remain visible: " + label)
		_check(bool(tutorial.get("touch_mode", false)) == label.contains("-touch-"), "Captured tutorial uses requested input hints: " + label)
	if bool(goal.get("visible", false)) and not bool(main.commerce_panel.visible):
		_check(Rect2(metrics.safe_rect).encloses(goal_rect), "Goal stays inside mobile safe area: " + label)
		_check(not goal_rect.intersects(Rect2(metrics.mine)) and not goal_rect.intersects(Rect2(metrics.context)), "Goal clears touch actions: " + label)
		_check(not bool(goal.get("input_blocking", true)), "Goal never blocks touch: " + label)
		if bool(minimap.get("visible", false)):
			_check(not goal_rect.intersects(minimap_rect), "Minimap and progression goal stay separate: " + label)
			_check(Rect2(metrics.safe_rect).encloses(minimap_rect), "Minimap stays inside mobile safe area: " + label)
			_check(not minimap_rect.intersects(Rect2(metrics.mine)) and not minimap_rect.intersects(Rect2(metrics.context)), "Minimap clears touch actions: " + label)
	if bool(tutorial.get("visible", false)):
		var tutorial_rect: Rect2 = tutorial.get("strip_rect", Rect2())
		_check(not bool(tutorial.get("input_blocking", true)), "Tutorial remains touch transparent: " + label)
		_check(Rect2(metrics.safe_rect).encloses(tutorial_rect), "Tutorial stays inside safe area: " + label)
		for name in ["progression_goal", "minimap", "menu", "guide", "build", "gold", "mine", "bag", "context"]:
			_check(not tutorial_rect.intersects(Rect2(metrics[name])), "Tutorial clears " + name + ": " + label)
		var companion: Node = main.get_node("CompanionInterface")
		_check(not tutorial_rect.intersects(companion.button.get_global_rect()) and not tutorial_rect.intersects(companion.activity.get_global_rect()), "Tutorial clears companion: " + label)
	var record: Dictionary = details.duplicate(true)
	record.merge({
		"file": filename, "sha256": FileAccess.get_sha256(output_dir.path_join(filename)),
		"framebuffer": {"width": image.get_width(), "height": image.get_height()},
		"logical_viewport": str(root.get_visible_rect().size), "phase": String(main.phase),
		"goal": goal, "minimap": minimap, "tutorial": tutorial, "mine_icon": String(main.mine_button.icon.resource_path),
		"context_caption": String(main.premium_hud.context_button.text),
		"stream": world.stream_snapshot() if world != null and main.phase == "endless" else {},
		"achievement_feedback": main.achievement_toast.debug_snapshot(), "pickup_feedback": feedback.debug_snapshot() if feedback != null else {},
		"physical_iphone": false, "native_mouse_hover_cleared": true,
	}, true)
	captures.append(record)
	print("ONE_POINT_ZERO_CAPTURE " + filename)

func _finish() -> void:
	Engine.time_scale = 1.0
	var report: Dictionary = {
		"automated_assertions_passed": failures.is_empty() and not captures.is_empty(),
		"visual_review_pending": true, "physical_iphone": false, "rendered": DisplayServer.get_name() != "headless",
		"artifact": {"path": pack_source, "sha256": FileAccess.get_sha256(pack_source) if FileAccess.file_exists(pack_source) else "", "version": str(ProjectSettings.get_setting("application/config/version", "")), "project_binary_sha256": FileAccess.get_sha256("res://project.binary") if FileAccess.file_exists("res://project.binary") else "", "source_project_config_present": FileAccess.file_exists("res://project.godot"), "external_harness_sha256": FileAccess.get_sha256(get_script().resource_path), "invocation_verified_by": "Exact --main-pack launcher/workflow; Godot consumes this switch before script arguments"},
		"engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"fixture_seed": FIXTURE_SEED, "captures": captures, "assertions": checks, "failures": failures,
		"elapsed_seconds": float(Time.get_ticks_usec() - started_usec) / 1000000.0,
		"limitations": "Native software renderer; accelerated campaign funding and held-gameplay waits; no pacing, browser or physical-device performance certification.",
	}
	var file: FileAccess = FileAccess.open(output_dir.path_join("review.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("ONE_POINT_ZERO_RENDER_COMPLETE captures=%d failures=%d" % [captures.size(), failures.size()])
	quit(0 if failures.is_empty() and not captures.is_empty() else 4)
