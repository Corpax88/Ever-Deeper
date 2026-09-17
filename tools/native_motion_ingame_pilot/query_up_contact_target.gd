extends "res://tools/native_motion_ingame_pilot/capture.gd"
## Headless identity query through the unchanged generated world and route owner.
## It does not move the actor, strike a node, display poses or alter production.


func _geometry_sequence() -> void:
	if not _check(DisplayServer.get_name() == "headless" and direction_name == "up" and depth == 2, "Contact query is headless and uses the retained up case"): return
	var recorded_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--recorded="): recorded_path = arg.trim_prefix("--recorded=")
	if not _check(FileAccess.get_sha256(recorded_path) == "011703e1f3c9af140d169e550b5b88828fce09a7214811c5e58ebb1d295267fd", "Exact original rendered up candidate report"): return
	var recorded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(recorded_path))
	if not _check(routes_equal(route, recorded.route), "Identical generated target and natural approach/contact/exit"): return
	var expected_world: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(recorded_path.get_base_dir().path_join("setup-world.json")))
	if not _check(routes_equal(initial_world, expected_world), "All generated identities, positions, HP and terrain match the actual recorded world"): return
	var resource: Dictionary = world.resources[int(route.resource_index)]
	var resource_visual: Node = world.resource_visuals[String(resource.id)]
	var sprite: Sprite2D = resource_visual.get_node("PremiumNode")
	if not _check(sprite.texture != null, "Actual generated target has its production texture"): return
	_write_json("contact-target-identity.json", {
		"rendered": false,
		"purpose": "Read the exact generated target identity and asset; recorded draw bounds remain authoritative",
		"diagnostic_source_base": source_sha,
		"diagnostic_sha256": FileAccess.get_sha256(get_script().resource_path),
		"original_capture_sha256": FileAccess.get_sha256(recorded_path),
		"runtime_source": BASE_SOURCE,
		"world_script_sha256": FileAccess.get_sha256("res://scripts/world/endless_descent_world.gd"),
		"player_script_sha256": FileAccess.get_sha256("res://scripts/player/player_controller.gd"),
		"route": route,
		"resource": resource,
		"texture_path": sprite.texture.resource_path,
		"texture_sha256": FileAccess.get_sha256(sprite.texture.resource_path),
		"texture_dimensions": _array(sprite.texture.get_size()),
		"sprite_local_position": _array(sprite.position),
		"sprite_local_scale": _array(sprite.scale),
		"world_identity_matches_rendered_case": true,
		"manual_pose_playback": false,
		"new_gameplay_input": false,
		"visual_or_contact_acceptance": false,
	})
