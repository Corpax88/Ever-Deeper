extends SceneTree

var game: Node
var output: String
var checks: Dictionary = {}
var frames: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func capture(name: String) -> void:
	await create_timer(0.25).timeout
	await RenderingServer.frame_post_draw
	checks[name + ":capture"] = root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK
	frames.append(name)


func run() -> void:
	output = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	game._start_new_game()
	await create_timer(0.25).timeout
	game.quick_tutorial.dismiss()
	var surface: Node = game.surface_world
	checks["locked surface lamps stay hidden"] = not surface.entrance_nodes["starMine_lantern"].visible
	var state := root.get_node("RunState")
	for mine_id in ["mossMine", "moonMine", "emberMine", "starMine"]:
		state.unlock_world(String(game.WORLD_BY_MINE[mine_id]))
		surface._refresh_unlock_visibility()
		var post: Sprite2D = surface.entrance_nodes[mine_id + "_lantern"]
		checks[mine_id + ":surface lantern"] = post.visible and post.texture.resource_path.ends_with("timber-post-lantern.png")
		if mine_id in ["mossMine", "emberMine"]:
			surface.restore_position(surface._mine_entrance(mine_id) + Vector2(-55, 52))
			await capture(mine_id + "-surface")

	for mine_id in ["mossMine", "moonMine", "emberMine", "starMine"]:
		checks[mine_id + ":enter mine"] = game._dev_jump_mine(mine_id, 1)
		var mine: Node = game.mine_world
		var entrance_seen := false
		for spec in mine.work_light_anchors:
			if not spec.with_lamp:
				continue
			var feet: Vector2 = spec.position
			checks[mine_id + ":" + spec.id + ":floor"] = not mine._player_collides(feet)
			if spec.id == "route:quarry_entrance":
				entrance_seen = true
				var lamp: Node2D = mine.get_node_or_null("WorkLight_route_quarry_entrance")
				checks[mine_id + ":entrance matches its pool of light"] = lamp != null and fixture_matches(lamp)
		checks[mine_id + ":entry has light"] = entrance_seen
		checks[mine_id + ":depth 1 light budget"] = mine.work_lamps.size() <= mine.MAX_VISIBLE_WORK_LIGHTS
		await capture(mine_id + "-d1-entry")
		mine._handle_discovery_at(int(mine.depth_entrance_boundary.keys()[0]))
		var shaft_lamp_present := false
		for spec in mine.work_light_anchors:
			if spec.id == "depth_entrance":
				shaft_lamp_present = spec.with_lamp and not mine._player_collides(Vector2(spec.position))
		checks[mine_id + ":depth 1 shaft has a lamp on the floor"] = shaft_lamp_present
		if mine_id == "emberMine":
			mine.restore_position(mine.depth_entrance + Vector2(0, 42))
			await capture("emberMine-d1-shaft")
		checks[mine_id + ":descend"] = game._dev_jump_mine(mine_id, 2)
		var depth: Node = game.depth_world
		var lamp_count := 0
		for spec in depth.landmark_light_specs:
			if not spec.with_lamp:
				continue
			var feet: Vector2 = spec.position
			checks[spec.id + ":floor"] = not depth._player_collides(feet)
			lamp_count += 1
			var lamp: Node2D = depth.landmark_lights.get_node_or_null("LandmarkLight_" + String(spec.id).replace(":", "_"))
			checks[spec.id + ":fixture"] = lamp != null and fixture_matches(lamp)
		checks[mine_id + ":three depth 2 lamps"] = lamp_count == 3
		checks[mine_id + ":depth 2 light budget"] = depth.landmark_lights.get_child_count() <= depth.MAX_ACTIVE_LANDMARK_LIGHTS
		depth.restore_position(depth.depth_entrance + Vector2(0, 42))
		await capture(mine_id + "-d2-landing")

	checks["enter hub"] = game._dev_jump_hub()
	var hub: Node = game.hub_world
	for index in hub.FOUNDATION_LIGHT_POSITIONS.size():
		var feet: Vector2 = hub.FOUNDATION_LIGHT_POSITIONS[index]
		var light: PointLight2D = hub.world_lights.get_node("FoundationSconce_%d" % index)
		checks["hub post %d on floor" % index] = not hub.collision_at(feet)
		checks["hub light %d follows post flame" % index] = light.position.is_equal_approx(feet + hub.HUB_LAMP_FLAME_OFFSET)
	hub.restore_position(hub.SURFACE_LIFT + Vector2(24, -28))
	await capture("hub-surface-lift")
	hub.restore_position(hub.DEEP_ELEVATOR + Vector2(0, 165))
	await capture("hub-deep-elevator")
	hub.restore_position(hub.HUB_SHOP + Vector2(-170, 38))
	await capture("hub-stations")

	var passed := not checks.values().has(false)
	var report := {
		"passed": passed, "checks": checks, "frames": frames,
		"viewport": [root.size.x, root.size.y],
		"renderer": RenderingServer.get_video_adapter_name(),
	}
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	quit(0 if passed else 1)


func fixture_matches(anchor: Node2D) -> bool:
	var sprite := anchor.get_child(0) as Sprite2D
	var light := anchor.get_child(1) as PointLight2D
	return sprite != null and sprite.texture.resource_path.ends_with("mine-oil-lantern.png") and light != null and light.position.y < 0
