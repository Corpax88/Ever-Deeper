extends SceneTree
## Actual context, controller, collision, rope and placement review.
## The fixture chooses an existing discovery; it never awards a relic/cache.
var output: String
var main: Node
var world: Node
var state: Node
var checks: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var passed: bool = true

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_jump_endless(1)
	world = main.endless_world
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	world.player.prepare_visual_cache()
	while world.player.visual.active_gear != "worn": await process_frame
	_freeze(world)
	await _review_site()
	await _review_relic()
	FileAccess.open(output.path_join("relic-journey.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"passed": passed, "rendered": true, "physical_iphone": false,
		"performance_evidence": false, "fixture_seed": 4608,
		"controller_step": 1.0 / 60.0, "checks": checks, "captures": captures,
	}, "\t"))
	print("RELIC_JOURNEY_COMPLETE passed=", passed)
	quit(0 if passed else 1)

func _review_site() -> void:
	var site: Dictionary = world.discovery_sites[0]
	world.restore_position(Vector2(site.position) + Vector2(-75, 45))
	world._update_discoveries()
	world._update_context(world.player.position)
	await _capture("site_discovered")
	var context: String = world.current_context()
	_check(context.begins_with("endless_site:"), "Discovery choice reachable", {"context": context})
	if not context.begins_with("endless_site:"): return
	world.perform_context()
	_check(not world.site_activity.is_empty(), "Real context starts seal sequence")
	await _capture("site_sequence_start")
	var rune_count: int = int(world.site_activity.get("rune_count", 0))
	for index in rune_count:
		var target: Vector2 = Vector2(site.rune_positions[index])
		await _walk_to(world, target, 180, 20.0, false)
		await _capture("site_seal_%d" % index)
	_check(bool(world.discovery_sites[0].get("resolved", false)), "Walking actual seals resolves cache")

func _review_relic() -> void:
	world._select_native_relic()
	var relic_id: String = String(world.native_relic_id)
	_check(not relic_id.is_empty(), "A real generated relic exists")
	if relic_id.is_empty(): return
	world.restore_position(Vector2(world.native_relic_position) + Vector2(75, 60))
	world._update_discoveries()
	world._update_context(world.player.position)
	await _capture("relic_discovered")
	_check(String(world.current_context()) == "endless_relic:" + relic_id, "Relic attachment context reachable")
	world.perform_context()
	_check(bool(state.relic_status(relic_id).attached), "Context attaches physical relic")
	await _capture("relic_attached")
	var start: Vector2 = world.player.position
	var target: Vector2 = world._nearest_walkable_position(start + Vector2(0, 160))
	await _walk_to(world, target, 240, 22.0, true)
	var rope: Dictionary = world.rope_debug_snapshot()
	_check(bool(rope.get("finite", false)), "Hauling through real terrain preserves finite rope", rope)
	await _capture("relic_hauled")
	_check(main.request_tunnel_home(), "Real Tunnel Home request accepted")
	await create_timer(1.6).timeout
	_check(main.phase == "hub", "Tunnel Home arrives in hub")
	if main.phase != "hub": return
	world = main.hub_world
	_freeze(world)
	await _capture("hub_arrival_with_relic")
	# Walk across the open forecourt, then above the placement area. The trailing
	# relic must reach the pedestal under the real rope solver, with no endpoint fixture.
	var pedestal: Vector2 = world.RELIC_PEDESTAL_POSITION
	await _walk_to(world, Vector2(pedestal.x + 135, 490), 300, 14.0, false)
	await _walk_to(world, Vector2(pedestal.x, 540), 180, 14.0, false)
	await _walk_to(world, pedestal + Vector2(0, -85), 180, 10.0, false)
	for tick in 120: _step(world, Vector2.ZERO, false)
	world._update_context(world.player.position)
	var endpoint: Vector2 = world._relic_rope_points[-1] if not world._relic_rope_points.is_empty() else Vector2(INF, INF)
	_check(String(world.current_context()) == "relicPedestal", "Physical pedestal approach offers placement", {"context":world.current_context(), "endpoint": str(endpoint), "player": str(world.player.position)})
	await _capture("hub_relic_placement_ready")
	world.perform_context()
	_check(bool(state.relic_status(relic_id).placed), "Real hauled endpoint permits placement")
	await _capture("hub_relic_placed")

func _freeze(target: Node) -> void:
	target.set_process(false)
	target.set_physics_process(false)
	target.player.set_physics_process(false)
	target.player.control_enabled = true
	target.player.camera.position_smoothing_enabled = false
	var mole: Node = target.get_node_or_null("MoleCompanion")
	if mole != null: mole.set_physics_process(false)

func _walk_to(target_world: Node, target: Vector2, ticks: int, tolerance: float, mining: bool) -> bool:
	var clear: bool = true
	for tick in ticks:
		var remaining: Vector2 = target - Vector2(target_world.player.position)
		if remaining.length() <= tolerance:
			_step(target_world, Vector2.ZERO, false)
			_check(clear, "Controller respects terrain while approaching " + str(target))
			return true
		_step(target_world, remaining.normalized(), mining)
		clear = clear and not target_world.collision_at(target_world.player.position)
		if tick % 8 == 0: await process_frame
	_step(target_world, Vector2.ZERO, false)
	_check(false, "Controller reaches " + str(target), {"stopped":str(target_world.player.position)})
	return false

func _step(target: Node, movement: Vector2, mining: bool) -> void:
	target.player.set_external_movement(movement)
	if target.has_method("set_mine_held"): target.set_mine_held(mining)
	target.player._physics_process(1.0 / 60.0)
	target._process(1.0 / 60.0)
	if target.has_method("_physics_process"): target._physics_process(1.0 / 60.0)

func _capture(id: String) -> void:
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.queue_redraw()
	for frame in 4: await process_frame
	await RenderingServer.frame_post_draw
	var shot: Image = root.get_texture().get_image()
	shot.save_png(output.path_join(id + ".png"))
	captures.append({"id":id, "framebuffer":str(shot.get_size()), "player":str(world.player.position), "context":world.current_context()})

func _check(ok: bool, id: String, detail: Dictionary = {}) -> void:
	checks.append({"id":id, "passed":ok, "detail":detail})
	passed = passed and ok
	if not ok:
		FileAccess.open(output.path_join("relic-journey-partial.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed":false,"checks":checks,"captures":captures}, "\t"))
		print("RELIC_JOURNEY_CHECK_FAILED ", id, " ", detail)
