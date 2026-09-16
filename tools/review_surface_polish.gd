extends SceneTree
## Source-bound surface artwork and actual controller/collision approaches.
## Fixed-step walks are functional checks, not measured frame-rate evidence.

var output: String
var selection: String = "all"
var main: Node
var world: Node
var state: Node
var captures: Array[Dictionary] = []
var checks: Array[Dictionary] = []
var passed: bool = true
const TERRACE_TRAVEL: = {
	"moonglass": [Vector2(990, 680), Vector2(1110, 650), Vector2(1200, 635), Vector2(1270, 610), Vector2(1360, 650), Vector2(1540, 654), Vector2(1770, 658), Vector2(1850, 674), Vector2(1910, 677), Vector2(2000, 684), Vector2(2090, 680), Vector2(2140, 675)],
	"emberdeep": [Vector2(2140, 675), Vector2(2240, 650), Vector2(2320, 630), Vector2(2460, 644), Vector2(2690, 662), Vector2(2910, 664), Vector2(2980, 674), Vector2(3050, 678), Vector2(3130, 684), Vector2(3210, 684), Vector2(3260, 675)],
	"starfall": [Vector2(3260, 675), Vector2(3360, 650), Vector2(3440, 630), Vector2(3520, 646), Vector2(3600, 662), Vector2(3810, 670), Vector2(4030, 667), Vector2(4210, 674), Vector2(4280, 680), Vector2(4340, 684), Vector2(4390, 686)],
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		if argument.begins_with("--case="):
			selection = argument.trim_prefix("--case=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5:
		await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	for biome in ["moonglass", "emberdeep", "starfall"]:
		state.unlock_world(biome)
	state.hub_unlocked_early = true
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.changed.emit()
	main._dev_jump_surface()
	world = main.surface_world
	world._refresh_unlock_visibility()
	while world.player.visual.active_gear != "worn":
		await process_frame
	# Unlock uses the real opening animation, which must finish before the
	# fixed-step capture suspends automatic world processing.
	for transition in world.portal_transitions.values():
		transition._process(2.0)
	world.set_process(false)
	world.player.set_physics_process(false)
	world.player.visual.set_process(false)
	world.player.camera.position_smoothing_enabled = false
	if selection in ["all", "mountains"]:
		await _mountain_states()
	if selection in ["all", "routes"]:
		for biome in ["moonglass", "emberdeep", "starfall"]:
			await _walk_route("trunk_" + biome, Array(TERRACE_TRAVEL[biome]))
		for id in ["moonMine", "emberMine", "starMine"]:
			await _walk_route(id, Array(world.LATER_MINE_BRANCH_ROUTES[id]))
		for id in ["moonglass_bloom", "ember_fault", "starfall_lattice"]:
			await _walk_route(id, Array(world.LATER_RESOURCE_ACCESS_ROUTES[id]))
		await _walk_route("starforge", [Vector2(3690, 662), Vector2(3640, 662), Vector2(3600, 662)])
		# Aim at the actual doorway; the former intermediate point (4130,650)
		# was inside the left support's physical footprint. The real controller
		# must slide around that support without weakening its collision.
		await _walk_route("hub_lift", [Vector2(4050, 650), world.hub_guide_position()])
	if selection in ["all", "contact"]:
		await _resource_contact_checks()
	if selection in ["all", "routes"]:
		_drop_landing_checks()
	var source_hashes: = {}
	for path in ["scripts/world/surface_world.gd", "scripts/world/world_catalog.gd", "scripts/main.gd", "tools/review_surface_polish.gd", "shaders/resource_mountain_blend.gdshader", "shaders/surface_mountain_blend.gdshader"]:
		source_hashes[path] = FileAccess.get_sha256("res://" + path)
	var report: = {
		"rendered": true, "physical_iphone": false, "source_only": true,
		"controller_fixed_step": 1.0 / 60.0, "performance_evidence": false,
		"runtime": Engine.get_version_info(), "os": OS.get_name(),
		"renderer": RenderingServer.get_video_adapter_name(), "source_sha256": source_hashes,
		"passed": passed, "checks": checks, "captures": captures,
	}
	FileAccess.open(output.path_join("surface-polish.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("SURFACE_POLISH_COMPLETE captures=", captures.size(), " passed=", passed)
	quit(0 if passed else 1)


func _mountain_states() -> void:
	var specimens: = [
		{"id": "mossvein", "mountain": "", "position": Vector2(555, 662)},
		{"id": "moonglass", "mountain": "moonglass_mountain", "position": Vector2(1665, 662)},
		{"id": "emberdeep", "mountain": "emberdeep_mountain", "position": Vector2(2820, 662)},
		{"id": "starfall", "mountain": "starfall_mountain", "position": Vector2(3900, 662)},
	]
	for specimen in specimens:
		world.restore_position(Vector2(specimen.position))
		world.player.set_facing(Vector2.UP)
		for condition in [{"id": "full", "hp": 360}, {"id": "half", "hp": 180}, {"id": "depleted", "hp": 0}]:
			var mountain_id: = String(specimen.mountain)
			_set_mountain_state(mountain_id, int(condition.hp))
			var snapshot: Dictionary = world.ore_mountain_snapshot() if mountain_id.is_empty() else world.surface_resource_mountain_snapshot(mountain_id)
			var sprite: Sprite2D = world.ore_mountain_sprite if mountain_id.is_empty() else world.surface_resource_mountains[mountain_id].sprite
			var settled: = is_zero_approx(float(sprite.material.get_shader_parameter("stage_mix")))
			var id: = "mountain_%s_%s" % [specimen.id, condition.id]
			checks.append({"id": id, "state_fixture": true, "hp": snapshot.hp, "settled_opaque_stage": settled, "passed": settled and int(snapshot.hp) == int(condition.hp)})
			passed = passed and settled and int(snapshot.hp) == int(condition.hp)
			await _capture(id, snapshot)
		_set_mountain_state(String(specimen.mountain), 360)


func _set_mountain_state(mountain_id: String, hp: int) -> void:
	if mountain_id.is_empty():
		world.ore_mountain_hp = hp
		world.ore_mountain_growth_buffer = 0.0
		world.ore_mountain_hit_flash = 0.0
		world.ore_mountain_collapse_elapsed = 0.0
		world._update_ore_mountain_visual(float(hp) / 360.0, true)
		return
	var entry: Dictionary = world.surface_resource_mountains[mountain_id]
	entry.hp = hp
	entry.growth_buffer = 0.0
	entry.hit_flash = 0.0
	entry.hit_elapsed = 0.0
	entry.collapse_elapsed = 0.0
	world.surface_resource_mountains[mountain_id] = entry
	world._update_surface_resource_mountain_visual(mountain_id, true)


func _walk_route(id: String, route: Array) -> void:
	world.restore_position(Vector2(route[0]))
	world.player.control_enabled = true
	world.player.set_external_movement(Vector2.ZERO)
	await _capture("route_%s_start" % id)
	var route_ok: = true
	var points: Array[Dictionary] = []
	for index in range(1, route.size()):
		var target: = Vector2(route[index])
		var ticks: = 0
		while world.player.global_position.distance_to(target) > 4.0 and ticks < 360:
			world.player.set_external_movement(world.player.global_position.direction_to(target))
			world.player._physics_process(1.0 / 60.0)
			ticks += 1
		world.player.set_external_movement(Vector2.ZERO)
		world.player._physics_process(1.0 / 60.0)
		var distance: float = world.player.global_position.distance_to(target)
		var reached: = distance <= 4.0
		route_ok = route_ok and reached
		points.append({"waypoint": str(target), "actual": str(world.player.global_position), "distance": distance, "ticks": ticks, "reached": reached})
		if index == route.size() / 2:
			await _capture("route_%s_middle" % id)
		if not reached:
			break
	await _capture("route_%s_end" % id)
	var expected: = {"moonMine": "enter:moonMine", "emberMine": "enter:emberMine", "starMine": "enter:starMine", "moonglass_bloom": "moonglass_resource", "ember_fault": "ember_resource", "starfall_lattice": "starfall_resource", "starforge": "starforge", "hub_lift": "hubEntrance"}
	var context_ok: bool = not expected.has(id) or world.active_context == expected[id]
	route_ok = route_ok and context_ok
	checks.append({"id": "controller_route_" + id, "passed": route_ok, "points": points, "context": world.active_context, "expected_context": expected.get(id, "free travel")})
	passed = passed and route_ok


func _resource_contact_checks() -> void:
	var mole: Node = world.get_node("MoleCompanion")
	mole.set_physics_process(false)
	for vein_id in ["moonglass_bloom", "ember_fault", "starfall_lattice"]:
		var moon: bool = vein_id == "moonglass_bloom"
		var node_index: = 2 if vein_id == "starfall_lattice" else 1
		var nodes: Array = world.moon_bloom_nodes if moon else world.timed_surface_veins[vein_id].nodes
		var node_position: = Vector2(nodes[node_index].position)
		var base: = node_position + Vector2(world.SURFACE_NODE_GROUND_OFFSET)
		var front: = base + Vector2(0, 40)
		var behind: = base - Vector2(0, 42)
		var sprite: Sprite2D = world.moon_bloom_sprites[node_index] if moon else world.timed_surface_veins[vein_id].sprites[node_index]
		var contact_ok: bool = world._surface_collides(base) and mole._blocked(base)
		contact_ok = contact_ok and not world._surface_collides(front) and not world._surface_collides(behind)
		for side in ["front", "behind"]:
			var target: = front if side == "front" else behind
			world.restore_position(target)
			world.player.set_facing(Vector2.UP if side == "front" else Vector2.DOWN)
			mole.global_position = behind if side == "front" else front
			mole.visible = true
			mole.z_index = world.actor_draw_depth(mole.global_position)
			mole._draw_pose()
			var sorted: bool = world.player.z_index > sprite.z_index if side == "front" else world.player.z_index < sprite.z_index
			var mole_sorted: bool = mole.z_index < sprite.z_index if side == "front" else mole.z_index > sprite.z_index
			contact_ok = contact_ok and sorted and mole_sorted and world.player.global_position.distance_to(target) < 1.0
			await _capture("contact_%s_%s" % [vein_id, side], {"ground_base": str(base), "hero_depth": world.player.z_index, "mole_depth": mole.z_index, "node_depth": sprite.z_index})
		# Movement really meets the intact base instead of passing through it.
		world.restore_position(front)
		for tick in 90:
			world.player.set_external_movement(world.player.global_position.direction_to(base))
			world.player._physics_process(1.0 / 60.0)
			contact_ok = contact_ok and not world._surface_collides(world.player.global_position)
		var blocked_distance: float = world.player.global_position.distance_to(base)
		contact_ok = contact_ok and blocked_distance > 24.0
		world.restore_position(front)
		mole.global_position = base + Vector2(70, 40)
		mole.z_index = world.actor_draw_depth(mole.global_position)
		world.player.set_external_movement(Vector2.ZERO)
		world.player.set_facing(Vector2.UP)
		# Exercise the real tool damage and yield path until this single base clears.
		var strikes: = 0
		while int(nodes[node_index].hp) > 0 and strikes < 800:
			if moon:
				world.moon_bloom_target_index = node_index
				world._mine_moonglass_resource_once()
				nodes = world.moon_bloom_nodes
			else:
				world.timed_surface_veins[vein_id].target_index = node_index
				world._mine_timed_surface_resource_once(vein_id)
				nodes = world.timed_surface_veins[vein_id].nodes
			strikes += 1
		if moon:
			world._update_moonglass_visual()
			world._update_moonglass_effects(1.0)
		else:
			world._update_timed_surface_visual(vein_id)
			world._update_timed_surface_effects(vein_id, 1.0)
		world._update_surface_material_sprays(1.0)
		var cleared: bool = int(nodes[node_index].hp) == 0 and not world._surface_collides(base) and not mole._blocked(base)
		contact_ok = contact_ok and cleared
		var crossing_reached: = await _walk_contact_target(base)
		contact_ok = contact_ok and crossing_reached
		# A returning crystal must wait for either actor's feet to leave its base.
		if moon:
			world._advance_moonglass_bloom(60.0)
		else:
			world._advance_timed_surface_resource(vein_id, 60.0)
		nodes = world.moon_bloom_nodes if moon else world.timed_surface_veins[vein_id].nodes
		var regrowth_waits: bool = int(nodes[node_index].hp) == 0
		contact_ok = contact_ok and regrowth_waits
		await _capture("contact_%s_depleted" % vein_id, {"ground_base": str(base), "real_tool_strikes": strikes, "intact_stopping_distance": blocked_distance, "depleted_base_reached": crossing_reached, "regrowth_waits_for_actor": regrowth_waits})
		contact_ok = contact_ok and await _walk_contact_target(behind)
		world.restore_position(front)
		mole.global_position = base
		if moon:
			world._advance_moonglass_bloom(1.0)
		else:
			world._advance_timed_surface_resource(vein_id, 1.0)
		nodes = world.moon_bloom_nodes if moon else world.timed_surface_veins[vein_id].nodes
		contact_ok = contact_ok and int(nodes[node_index].hp) == 0
		mole.global_position = base + Vector2(70, 40)
		if moon:
			world._advance_moonglass_bloom(1.0)
			world._update_moonglass_visual()
		else:
			world._advance_timed_surface_resource(vein_id, 1.0)
			world._update_timed_surface_visual(vein_id)
		nodes = world.moon_bloom_nodes if moon else world.timed_surface_veins[vein_id].nodes
		contact_ok = contact_ok and int(nodes[node_index].hp) > 0 and world._surface_collides(base)
		checks.append({"id": "physical_contact_" + vein_id, "passed": contact_ok, "actual_tool_strikes": strikes, "depleted_walk": crossing_reached, "regrowth_waits": regrowth_waits})
		passed = passed and contact_ok
	mole.set_physics_process(true)


func _walk_contact_target(target: Vector2) -> bool:
	for tick in 240:
		if world.player.global_position.distance_to(target) < 3.0:
			world.player.set_external_movement(Vector2.ZERO)
			return true
		world.player.set_external_movement(world.player.global_position.direction_to(target))
		world.player._physics_process(1.0 / 60.0)
	world.player.set_external_movement(Vector2.ZERO)
	return false


func _drop_landing_checks() -> void:
	var moon_accessible: = true
	for position in world.MOON_BLOOM_NODE_POSITIONS:
		for spread in 16:
			world._spawn_moonglass_drop("moonglass", 1, spread, position)
			var drops: Array = world.moon_bloom_drops
			moon_accessible = moon_accessible and not world._surface_collides(Vector2(drops.back().landing_position))
	checks.append({"id": "accessible_drops_moonglass_bloom", "passed": moon_accessible, "drop_trajectories": 48})
	passed = passed and moon_accessible
	for vein_id in ["ember_fault", "starfall_lattice"]:
		var config: Dictionary = world._timed_surface_config(vein_id)
		var accessible: = true
		var checked: = 0
		for position in config.positions:
			for spread in 16:
				world._spawn_timed_surface_drop(vein_id, config.resource, 1, spread, position)
				var drops: Array = world.timed_surface_veins[vein_id].drops
				accessible = accessible and not world._surface_collides(Vector2(drops.back().landing_position))
				checked += 1
		checks.append({"id": "accessible_drops_" + vein_id, "passed": accessible, "drop_trajectories": checked})
		passed = passed and accessible


func _capture(id: String, subject: Dictionary = {}) -> void:
	world.player.set_external_movement(Vector2.ZERO)
	world.player._update_visual(false)
	world.player.visual._draw_frame(0.0)
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world._update_mossvein_environment(0.0)
	main._refresh_hud()
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	main.premium_hud.set_status("")
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null:
		mole.recall()
	for frame in 3:
		await process_frame
	# Mining may enqueue achievements on the next frame; isolate the world
	# capture from that deferred overlay without muting gameplay events.
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	picture.save_png(output.path_join(id + ".png"))
	captures.append({"id": id, "size": str(picture.get_size()), "player": str(world.player.global_position), "context": world.active_context, "subject": subject})
