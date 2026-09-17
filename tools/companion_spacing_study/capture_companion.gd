extends "hero_capture_base.gd"
## The runner stages this subclass beside the hash-pinned 72f11bc hero fixture.
## Only a before-add_child hook and an extra report field are added to that base.
const EXPECTED_PACK := "9dfcf913c867e36e6a16f4f5123fd5cce7654cfb435a753f9eb7bca12f574bd9"
var companion_variant := ""
var overlay_path := ""
var expected_overlay_sha := ""
var binding: Dictionary = {}
var health_properties: Dictionary = {}


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--companion-variant="): companion_variant = arg.trim_prefix("--companion-variant=")
		elif arg.begins_with("--companion-overlay="): overlay_path = arg.trim_prefix("--companion-overlay=")
		elif arg.begins_with("--companion-overlay-sha256="): expected_overlay_sha = arg.trim_prefix("--companion-overlay-sha256=")
	if companion_variant not in ["baseline", "candidate"] or "--trace-companion" in OS.get_cmdline_user_args():
		push_error("Companion capture requires baseline/candidate without a trace replacement")
		quit(2)
		return
	if companion_variant == "candidate":
		if not overlay_path.is_absolute_path() or expected_overlay_sha.length() != 64 or FileAccess.get_sha256(overlay_path) != expected_overlay_sha:
			push_error("Candidate overlay identity differs")
			quit(2)
			return
		if not ProjectSettings.load_resource_pack(overlay_path, false):
			push_error("Candidate tools-only overlay could not be mounted")
			quit(2)
			return
	super._initialize()


func _companion_prepare_main(node: Node) -> void:
	binding = {"variant": companion_variant, "before_add_child": not node.is_inside_tree(),
		"original_main_script": node.get_script().resource_path,
		"overlay_loaded": companion_variant == "candidate",
		"overlay_sha256": FileAccess.get_sha256(overlay_path) if companion_variant == "candidate" else ""}
	if companion_variant == "candidate":
		var script: Script = load("res://tools/companion_spacing_study/pilot_main.gd")
		if script == null or not script.can_instantiate():
			_check(false, "Candidate main subclass can instantiate")
			return
		node.set_script(script)
	binding["installed_main_script"] = node.get_script().resource_path
	for label in ["player", "runstate"]: health_properties[label] = []
	# The player is created by main._ready, so its real properties are inspected
	# lazily in the first post-draw snapshot, never synthesized as zero HP.


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
	if companion_variant == "candidate":
		var steering: RefCounted = mole.separation
		result["separation"] = {"choice": steering.choice, "trapped": steering.trapped,
			"attempts": steering.attempts, "avoidance_active": steering.avoidance_active,
			"yield_axis": _xy(steering.yield_axis), "ticks": mole.separation_ticks,
			"trapped_ticks": mole.trapped_ticks, "observed_hero_velocity": _xy(mole.observed_velocity)}
	return result


func _companion_report() -> Dictionary:
	return {"schema": 1, "binding": binding, "variant": companion_variant,
		"expected_pack_sha256": EXPECTED_PACK, "base_fixture_commit": "72f11bcd33ff129f8f0f694106bef509b68fd0f3",
		"post_draw_samples": samples.size(), "health_properties_observed": health_properties,
		"logical_to_native_pixels": {"scale": [1.1, 1.1], "offset": [0, 0]},
		"telemetry_source": "Read live companion and hero immediately after the inherited frame_post_draw wait.",
		"original_depth_order_preserved": true, "companion_repositioned_by_fixture": false,
		"manual_process_steps": false, "visual_acceptance": false,
		"limits": "Full sprite-cell rectangles are conservative geometry, not opaque-pixel occlusion. Inspect original frames and the independent A/B mechanics report."}


func _finish() -> void:
	_check(FileAccess.get_sha256(pack_source) == EXPECTED_PACK, "Exact DEV12 PCK used for companion comparison")
	var expected_main := "res://tools/companion_spacing_study/pilot_main.gd" if companion_variant == "candidate" else "res://scripts/main.gd"
	_check(bool(binding.get("before_add_child", false)) and binding.get("original_main_script") == "res://scripts/main.gd" and binding.get("installed_main_script") == expected_main,
		"Declared main owner installed before entering the tree")
	var expected_mole := "res://tools/companion_spacing_study/pilot_mole.gd" if companion_variant == "candidate" else "res://scripts/companion/mole_companion.gd"
	var telemetry_ok := not samples.is_empty()
	for sample in samples:
		telemetry_ok = telemetry_ok and sample.companion.get("present", false) and sample.companion.get("script") == expected_mole
	_check(telemetry_ok, "Every post-draw sample records the actual declared companion owner")
	_check(gear == "worn" and direction_name in ["right", "up"] and samples.size() == 195,
		"Bounded Worn comparison retains all 195 rendered motion samples")
	super._finish()
