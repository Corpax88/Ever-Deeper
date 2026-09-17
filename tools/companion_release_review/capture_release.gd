extends "hero_capture_base.gd"
## Read-only telemetry around the unchanged approved 195-frame choreography.
## Main, world, companion and helper are loaded normally from the actual PCK.
var expected_pack := ""
var binding: Dictionary = {}
var health_properties: Dictionary = {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--expected-pack-sha256="): expected_pack = arg.trim_prefix("--expected-pack-sha256=")
	if expected_pack.length() != 64:
		push_error("Release capture requires the immutable package SHA256")
		quit(2)
		return
	super._initialize()


func _compiled_identity(path: String) -> Dictionary:
	var remap := ConfigFile.new()
	var status := remap.load(path + ".remap")
	var target: String = String(remap.get_value("remap", "path", "")) if status == OK else ""
	return {"logical_path": path, "remap_status": status, "compiled_path": target,
		"remap_sha256": FileAccess.get_sha256(path + ".remap"),
		"compiled_sha256": FileAccess.get_sha256(target) if not target.is_empty() else ""}


func _companion_prepare_main(node: Node) -> void:
	binding = {"before_add_child": not node.is_inside_tree(), "overlay_loaded": false,
		"original_main_script": node.get_script().resource_path,
		"installed_main_script": node.get_script().resource_path,
		"main": _compiled_identity("res://scripts/main.gd"),
		"companion": _compiled_identity("res://scripts/companion/mole_companion.gd"),
		"helper": _compiled_identity("res://scripts/companion/follow_separation.gd")}

func _health_values(owner: Object) -> Dictionary:
	var values: Dictionary = {}
	for property in owner.get_property_list():
		var name: String = String(property.name)
		if name in ["hp", "health", "current_hp", "max_hp", "current_health", "max_health", "hit_points"]:
			values[name] = owner.get(name)
	return values


func _damage_identity() -> Dictionary:
	var walls: Dictionary = {}
	for cell in world.dig_damage: walls[str(cell)] = int(world.dig_damage[cell])
	var resources: Array[Dictionary] = []
	for resource in world.resources:
		resources.append({"id": String(resource.id), "hp": int(resource.hp), "mined": bool(resource.mined)})
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(PackedByteArray(world.floor_cells))
	return {"wall_damage": walls, "resources": resources,
		"resource_damage_sha256": JSON.stringify(resources).sha256_text(), "floor_sha256": digest.finish().hex_encode(),
		"cargo": state.cargo.duplicate(true), "mined_totals": state.mined.duplicate(true),
		"gold": state.gold, "total_gold_earned": state.total_gold_earned,
		"total_swings": state.total_swings, "precision_hits": state.precision_hits,
		"pending_hazard_push": _xy(world.hazard_push_remaining)}


func _snapshot() -> Dictionary:
	var sample: Dictionary = super._snapshot()
	var player_health: Dictionary = _health_values(player)
	var state_health: Dictionary = _health_values(state)
	health_properties = {"player": player_health.keys(), "runstate": state_health.keys()}
	sample["hero_health"] = {"available": not player_health.is_empty() or not state_health.is_empty(),
		"player": player_health, "runstate": state_health,
		"absence_meaning": "No HP/health property on the shipped player or RunState; no invented numeric HP."}
	sample["actual_input"] = {"external_movement": _xy(player.external_movement),
		"keyboard_vector": _xy(Input.get_vector("move_left", "move_right", "move_up", "move_down")),
		"control_enabled": bool(player.control_enabled), "main_mine_held": bool(main.mine_held),
		"world_external_mine_held": bool(world.external_mine_held),
		"resolved_velocity": _xy(player.velocity), "world_processing": world.is_processing(),
		"world_physics_processing": world.is_physics_processing(), "hero_physics_processing": player.is_physics_processing()}
	sample["world_damage"] = _damage_identity()
	sample["companion"] = _companion_snapshot()
	return sample


func _xy(value: Vector2) -> Array:
	return [value.x, value.y]


func _companion_snapshot() -> Dictionary:
	var mole: Node2D = world.get_node_or_null("MoleCompanion")
	if mole == null: return {"present": false}
	var sprite: Sprite2D = mole.sprite
	var rect: Rect2 = sprite.get_global_transform_with_canvas() * sprite.get_rect()
	var result := {"present": true, "script": mole.get_script().resource_path,
		"helper_script": mole.separation.get_script().resource_path,
		"actual_owner_bound": mole.get_script() == load("res://scripts/companion/mole_companion.gd"),
		"actual_helper_bound": mole.separation.get_script() == load("res://scripts/companion/follow_separation.gd"),
		"wrapper_methods": mole.has_method("_update_companion_actions") and mole.has_method("_move_task"),
		"mode": String(mole.mode), "action": String(mole.action), "moving": bool(mole.moving),
		"position": _xy(mole.global_position), "local_position": _xy(mole.position),
		"hero_position": _xy(player.global_position), "hero_distance": mole.global_position.distance_to(player.global_position),
		"relative_to_hero": _xy(mole.global_position - player.global_position), "destination": _xy(mole.destination),
		"facing": _xy(mole.facing), "visible": mole.is_visible_in_tree(), "z_index": mole.z_index,
		"hero_z_index": player.z_index, "expected_foot_depth": world.actor_draw_depth(mole.position),
		"z_as_relative": mole.z_as_relative, "hero_z_as_relative": player.z_as_relative,
		"sprite_cell_rect_logical": _rect_array(rect), "sprite_frame": sprite.frame,
		"sprite_texture": sprite.texture.resource_path, "sprite_rotation": sprite.rotation,
		"sprite_scale": _xy(sprite.scale), "sprite_local_position": _xy(sprite.position),
		"route_length": mole.route.size(), "path_searches": mole.path_searches,
		"think_clock": mole.think_clock, "action_clock": mole.action_clock,
		"animation_clock": mole.animation_clock, "automatic_task": mole.automatic_task,
		"collected_total": mole.collected_total, "dug_total": mole.dug_total,
		"terrain_blocked_at_center": mole._blocked(mole.global_position)}
	if true:
		var steering: RefCounted = mole.separation
		result["separation"] = {"choice": steering.choice, "trapped": steering.trapped,
			"attempts": steering.attempts, "avoidance_active": steering.avoidance_active,
			"yield_axis": _xy(steering.yield_axis), "ticks": mole.separation_ticks,
			"trapped_ticks": mole.trapped_ticks, "observed_hero_velocity": _xy(mole.observed_velocity)}
	return result



func _companion_report() -> Dictionary:
	return {"schema": 2, "binding": binding, "variant": "actual_production",
		"expected_pack_sha256": expected_pack, "base_fixture_commit": "72f11bcd33ff129f8f0f694106bef509b68fd0f3",
		"post_draw_samples": samples.size(), "health_properties_observed": health_properties,
		"logical_to_native_pixels": {"scale": [1.1, 1.1], "offset": [0, 0]},
		"companion_repositioned_by_fixture": false, "manual_process_steps": false,
		"runtime_replacements": [], "visual_acceptance": false}


func _finish() -> void:
	_check(FileAccess.get_sha256(pack_source) == expected_pack, "Exact immutable DEV13 package")
	_check(bool(binding.get("before_add_child", false)) and binding.get("original_main_script") == "res://scripts/main.gd" and binding.get("installed_main_script") == "res://scripts/main.gd",
		"Actual main enters tree without substitution")
	for owner in ["main", "companion", "helper"]:
		var row: Dictionary = binding.get(owner, {})
		_check(row.get("remap_status", -1) == OK and String(row.get("compiled_path", "")).ends_with(".gdc") and String(row.get("compiled_sha256", "")).length() == 64,
			"Compiled package identity bound: " + owner)
	var telemetry_ok := not samples.is_empty()
	for sample in samples:
		var mole: Dictionary = sample.companion
		telemetry_ok = telemetry_ok and mole.get("present", false) and mole.get("script") == "res://scripts/companion/mole_companion.gd" and mole.get("helper_script") == "res://scripts/companion/follow_separation.gd" and mole.get("actual_owner_bound", false) and mole.get("actual_helper_bound", false) and mole.get("wrapper_methods", false)
	_check(telemetry_ok, "Every sample observes the actual production owner and helper")
	_check(gear == "worn" and direction_name in ["right", "up"] and samples.size() == 195,
		"All 195 approved input samples retained")
	super._finish()
