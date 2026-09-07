extends "res://scripts/qa/qa_context.gd"
## Layout checks moved intact from main.gd.


func _start_qa_version_menu() -> void :
	main.menu_open = true
	main.premium_menu.modulate = Color.WHITE
	main.premium_menu.open_menu(false, "NO EXPEDITION", false, false)
	print("EVER_DEEPER_VERSION_MENU_READY label=%s" % main.premium_menu.displayed_release_label())


func _run_landscape_qa() -> void :
	var viewport_size= main.get_viewport().get_visible_rect().size
	var configured_size= Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width")),
		float(ProjectSettings.get_setting("display/window/size/viewport_height")),
	)
	assert (configured_size.is_equal_approx(Vector2(1280, 720)))
	assert (int(ProjectSettings.get_setting("display/window/handheld/orientation")) == DisplayServer.SCREEN_SENSOR_LANDSCAPE)
	assert (String(ProjectSettings.get_setting("display/window/stretch/aspect")) == "expand")
	assert (is_equal_approx(float(ProjectSettings.get_setting("display/window/stretch/scale")), 1.1))
	main._sync_orientation_guard(Vector2(720, 1280), true)
	assert (main.orientation_guard_active and main.orientation_guard.visible)
	main._sync_orientation_guard(Vector2(1280, 720), true)
	assert ( not main.orientation_guard_active and not main.orientation_guard.visible)
	assert (main.premium_hud.minimum_touch_targets_are_valid())
	assert (main.mine_button.keep_pressed_outside)
	assert (main.mine_button.icon != null and main.mine_button.icon.resource_path == "res://assets/ui/hud-mine-impact-v1.png")
	for sprite_button in [
		main.mine_button, main.premium_hud.menu_button, main.premium_hud.guide_button,
			main.premium_hud.bag_button,
	]:
		assert ((sprite_button as Button).text.is_empty())
		for state in ["normal", "hover", "pressed", "focus", "disabled"]:
			var stylebox= (sprite_button as Button).get_theme_stylebox(state)
			assert (stylebox is StyleBoxEmpty, "%s.%s resolved to %s" % [sprite_button.name, state, stylebox.get_class()])


	assert (main.premium_hud.context_button.get_theme_stylebox("normal") is StyleBoxFlat)
	assert (main.premium_hud.context_button.get_theme_stylebox("focus") is StyleBoxEmpty)
	assert (main.resource_inventory.item_grid.columns == 4)
	assert (main.movement_pad._is_in_movement_zone(Vector2(220, 610)))
	assert ( not main.movement_pad._is_in_movement_zone(Vector2(1080, 610)))
	var landscape_menu_card: Control = main.premium_menu.main_view.get_child(0) as Control
	assert (landscape_menu_card != null and landscape_menu_card.size.is_equal_approx(Vector2(1040, 600)))
	main.surface_world.set_active(true)
	await main.get_tree().physics_frame
	var landscape_camera: CinematicCamera2D = main.surface_world.player.camera as CinematicCamera2D
	var surface_parallax: SurfaceParallax = main.surface_world.surface_parallax
	var surface_routes: Dictionary = main.surface_world.surface_route_snapshot()
	var moss_branch: Dictionary = Dictionary(surface_routes.branches.mossMine)
	var moon_branch: Dictionary = Dictionary(surface_routes.branches.moonMine)
	var moonglass_boundary: Dictionary = Dictionary(Array(surface_routes.boundaries)[0])
	var moss_gate_overlap: Rect2 = Rect2(moss_branch.entrance_visual_rect).intersection(Rect2(moonglass_boundary.gate_visual_rect))
	assert (moss_gate_overlap.get_area() <= 160.0, "The Moonglass seal must not cover the Mossvein entrance")
	assert ( not Rect2(moon_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.gate_visual_rect)))
	assert ( not Rect2(moss_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.generator_rect)))
	assert ( not Rect2(moon_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.generator_rect)))
	assert ( not Rect2(moss_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.seam_rect)))
	assert ( not Rect2(moon_branch.entrance_visual_rect).intersects(Rect2(moonglass_boundary.seam_rect)))
	assert (Vector2(moonglass_boundary.travel_axis) == Vector2.RIGHT)
	assert (
		Vector2(moonglass_boundary.station_position).distance_to(Vector2(moss_branch.entrance))
		> float(moonglass_boundary.station_radius) + float(moss_branch.interaction_radius)
	)
	var expected_portal_colors= {
		"moonglass": PackedColorArray([Color("82ad62"), Color("69e8ff")]),
		"emberdeep": PackedColorArray([Color("69e8ff"), Color("ff6a2a")]),
		"starfall": PackedColorArray([Color("ff6a2a"), Color("a879ff")]),
	}
	var expected_gate_assets= {
		"moonglass": "res://assets/surface/moonglass-gate.png",
		"emberdeep": "res://assets/surface/emberdeep-seal.png",
		"starfall": "res://assets/surface/starfall-seal.png",
	}
	var expected_mark_assets= {
		"moonglass": "res://assets/surface/moonglass-open-threshold.png",
		"emberdeep": "res://assets/surface/emberdeep-seal-mark.png",
		"starfall": "res://assets/surface/starfall-seal-mark.png",
	}
	var boundary_rows: Dictionary = {}
	for boundary_value in Array(surface_routes.boundaries):
		var boundary: Dictionary = Dictionary(boundary_value)
		var boundary_id= String(boundary.id)
		var anchor= Vector2(boundary.anchor)
		var seam_rect= Rect2(boundary.seam_rect)
		var generator_rect= Rect2(boundary.generator_rect)
		var transition_debug: Dictionary = Dictionary(boundary.transition_debug)
		var transition: WorldTransitionVisual = main.surface_world.portal_transitions[boundary_id] as WorldTransitionVisual
		var generator: Dictionary = Dictionary(main.surface_world.portal_generator_nodes[boundary_id])
		var generator_sprite: Sprite2D = generator.sprite as Sprite2D
		assert (is_instance_valid(transition) and transition.position == anchor)
		assert (bool(boundary.seam_present) and seam_rect.size == Vector2(24, 184))
		assert (is_equal_approx(seam_rect.get_center().x, anchor.x))
		assert (bool(boundary.generator_visual_present) and generator_rect.size == Vector2(150, 150))
		assert (is_equal_approx(generator_rect.get_center().x, anchor.x))
		assert (is_equal_approx(generator_rect.end.y, anchor.y - main.surface_world.GATE_HALF_GAP))
		assert (generator_sprite.texture is AtlasTexture)
		assert ((generator_sprite.texture as AtlasTexture).region == Rect2(181, 25, 150, 150))
		assert (bool(transition_debug.seam_mode) and not bool(transition_debug.external_arch_mode))
		assert ( not bool(transition_debug.legacy_frame_visible) and not bool(boundary.legacy_arch_present))
		assert (Vector2(transition_debug.seam_back_size) == Vector2(24, 184))
		assert (Vector2(transition_debug.seam_front_size) == Vector2(8, 190))
		assert (int(transition_debug.seam_back_z) < main.surface_world.player.z_index)
		assert (int(transition_debug.seam_front_z) > main.surface_world.player.z_index)
		assert (is_equal_approx(float(transition_debug.crossing_pulse_duration), 0.42))
		assert (is_equal_approx(float(transition_debug.effective_transition_duration), 0.42))
		assert (int(transition_debug.particle_capacity) == 8)
		assert (String(transition_debug.gate_texture) == String(expected_gate_assets[boundary_id]))
		assert (String(transition_debug.threshold_texture) == String(expected_mark_assets[boundary_id]))
		assert (PackedColorArray(boundary.seam_palette) == PackedColorArray(expected_portal_colors[boundary_id]))
		assert ( not bool(boundary.player_occlusion_split) and Rect2(boundary.portal_arch_rect).size == Vector2.ZERO)
		assert (Vector2(boundary.travel_axis) == Vector2.RIGHT)
		boundary_rows[boundary_id] = boundary
	assert (boundary_rows.size() == 3)
	for boundary_id in ["moonglass", "emberdeep", "starfall"]:
		var transition: WorldTransitionVisual = main.surface_world.portal_transitions[boundary_id] as WorldTransitionVisual
		var anchor= Vector2(Dictionary(boundary_rows[boundary_id]).anchor)
		transition.set_gate_open(false, false)
		assert (main.surface_world._surface_collides(anchor))
		assert (main.surface_world._surface_collides(anchor + Vector2(0, main.surface_world.GATE_HALF_GAP + main.surface_world.PLAYER_RADIUS + 1.0)))
	RunState.area_unlocked = true
	RunState.emberdeep_unlocked = true
	RunState.fourth_unlocked = true
	var player_position_before_portals: Vector2 = main.surface_world.player.global_position
	var player_control_before_portals: bool = main.surface_world.player.control_enabled
	for boundary_id in ["moonglass", "emberdeep", "starfall"]:
		var transition: WorldTransitionVisual = main.surface_world.portal_transitions[boundary_id] as WorldTransitionVisual
		var anchor= Vector2(Dictionary(boundary_rows[boundary_id]).anchor)
		transition.set_gate_open(true, false)
		assert ( not main.surface_world._surface_collides(anchor))
		assert (main.surface_world._surface_collides(anchor + Vector2(0, main.surface_world.GATE_HALF_GAP + main.surface_world.PLAYER_RADIUS + 1.0)))
		transition.reset_actor_observation(anchor + Vector2(-60, 0))
		transition.observe_actor_position(anchor + Vector2(60, 0))
		assert (bool(transition.debug_snapshot().crossing))
		transition._process(0.21)
		assert (bool(transition.debug_snapshot().front_sweep_visible))
		transition._process(0.22)
		assert ( not bool(transition.debug_snapshot().crossing))
		transition.reset_actor_observation(anchor + Vector2(60, 0))
		transition.observe_actor_position(anchor + Vector2(-60, 0))
		assert (bool(transition.debug_snapshot().crossing))
		transition.cancel_crossing()
	assert (main.surface_world.player.global_position == player_position_before_portals)
	assert (main.surface_world.player.control_enabled == player_control_before_portals)
	assert (main.deepheart_world.EXIT_POSITION.x >= 400.0 and main.deepheart_world.EXIT_POSITION.x <= 500.0)
	assert (main.deepheart_world.PLAYER_SPAWN.distance_to(main.deepheart_world.EXIT_POSITION) > main.deepheart_world.EXIT_RADIUS)
	surface_parallax.force_update()
	var parallax_snapshot: Dictionary = surface_parallax.debug_snapshot()
	assert (int(parallax_snapshot.layer_count) == 4)
	assert (bool(parallax_snapshot.collision_neutral))
	assert (is_equal_approx(float(parallax_snapshot.reference_x), 640.0))
	var expected_effective_reference= 640.0 + 0.5 * (float(parallax_snapshot.viewport_width_world) - 1280.0)
	assert (is_equal_approx(float(parallax_snapshot.effective_reference_x), expected_effective_reference))
	assert (is_equal_approx(surface_parallax._effective_reference_x(1563.4286), 781.7143))
	var parallax_layers: Dictionary = {}
	for layer_snapshot_value in Array(parallax_snapshot.layers):
		var layer_snapshot: Dictionary = Dictionary(layer_snapshot_value)
		parallax_layers[String(layer_snapshot.name)] = layer_snapshot
	assert (is_equal_approx(float(parallax_layers.FarSky.scroll_factor), 0.02))
	assert (is_equal_approx(float(parallax_layers.FarCanopy.scroll_factor), 0.05))
	assert (is_equal_approx(float(parallax_layers.MidForest.scroll_factor), 0.08))
	assert (is_equal_approx(float(parallax_layers.NearSilhouette.scroll_factor), 0.12))
	assert (int(parallax_layers.MidForest.visible_chunk_count) >= 1)
	assert (int(parallax_layers.NearSilhouette.visible_chunk_count) >= 1)
	var far_background_sprite: Sprite2D = surface_parallax.get_node("FarSky/MossMoonPanorama") as Sprite2D
	var midground_sprite: Sprite2D = surface_parallax.get_node("MidForest/MossveinMidground") as Sprite2D
	var foreground_sprite: Sprite2D = surface_parallax.get_node("NearSilhouette/MossveinCameraFrame") as Sprite2D
	var floor_frame_sprite: Sprite2D = surface_parallax.get_node("NearSilhouette/MossveinFloorFrame") as Sprite2D
	var continuous_floor: Sprite2D = surface_parallax.get_node("NearSilhouette/ContinuousForestFloor") as Sprite2D
	assert (midground_sprite.texture != null and midground_sprite.texture.get_size() == Vector2(1983, 793))
	for clipped_parallax_sprite in [far_background_sprite, midground_sprite]:
		var clip_material: ShaderMaterial = (clipped_parallax_sprite as Sprite2D).material as ShaderMaterial
		assert (clip_material != null and clip_material.shader != null)
		assert (clip_material.shader.resource_path == "res://shaders/surface_parallax_world_clip.gdshader")
		assert (is_equal_approx(float(clip_material.get_shader_parameter("world_right")), 2240.0))
	var expected_boundary_regions= {
		"emberdeep": Rect2(192, 0, 297, 1024),
		"starfall": Rect2(186, 0, 318, 1024),
	}
	for boundary_id in ["emberdeep", "starfall"]:
		var boundary_sprite: Sprite2D = main.surface_world.boundary_backing_nodes[boundary_id] as Sprite2D
		assert (boundary_sprite.texture is AtlasTexture)
		var boundary_atlas: AtlasTexture = boundary_sprite.texture as AtlasTexture
		var expected_region= Rect2(expected_boundary_regions[boundary_id])
		assert (boundary_atlas.region == expected_region)
		var source_scale= Vector2(320.0 / 682.0, 1280.0 / 1024.0)
		var expected_rect= Rect2(
			Vector2(float(Dictionary(boundary_rows[boundary_id]).anchor.x) - 160.0, 0.0) + expected_region.position * source_scale,
			expected_region.size * source_scale
		)
		assert (boundary_sprite.position.is_equal_approx(expected_rect.position))
		assert ((Vector2(boundary_atlas.get_size()) * boundary_sprite.scale.abs()).is_equal_approx(expected_rect.size))
	var surface_performance: Dictionary = main.surface_world.mobile_performance_snapshot()
	assert (is_equal_approx(float(surface_performance.dynamic_visual_hz), 30.0))
	assert (foreground_sprite.texture != null and foreground_sprite.texture.get_size() == Vector2(1672, 941))
	assert (foreground_sprite.region_enabled and foreground_sprite.region_rect == Rect2(0, 0, 1672, 430))
	assert (is_equal_approx(foreground_sprite.position.y, 215.0))
	var foreground_rect= foreground_sprite.get_rect()
	var foreground_top= minf(
		foreground_sprite.to_global(foreground_rect.position).y,
		foreground_sprite.to_global(foreground_rect.end).y
	)
	assert (is_equal_approx(foreground_top, 0.0), "The Mossvein canopy foreground must start at the world top without a horizontal mid-screen seam")
	assert (floor_frame_sprite.texture == foreground_sprite.texture)
	assert (floor_frame_sprite.region_enabled and floor_frame_sprite.region_rect == Rect2(0, 430, 1672, 511))
	assert (floor_frame_sprite.position.y >= 960.0, "The dense Mossvein foreground must stay anchored at the bottom of the landscape view")
	assert (continuous_floor.texture != null and continuous_floor.texture.get_size() == Vector2(2172, 724))
	var continuous_floor_image: Image = continuous_floor.texture.get_image()
	assert (continuous_floor_image != null)
	assert (continuous_floor_image.get_pixel(1086, 300).a <= 0.01, "The parallax floor background must be genuinely transparent")
	assert (continuous_floor_image.get_pixel(1086, 650).a >= 0.95, "The parallax floor artwork must remain opaque")
	assert (continuous_floor.material == null, "True-alpha parallax art must not depend on checkerboard keying")
	var floor_rect: Rect2 = continuous_floor.get_rect()
	var floor_top: Vector2 = continuous_floor.to_global(floor_rect.position)
	var floor_bottom: Vector2 = continuous_floor.to_global(floor_rect.end)
	assert (maxf(floor_top.y, floor_bottom.y) >= main.surface_world._world_size().y - 1.0)
	assert ((surface_parallax.get_node("NearSilhouette") as Node2D).z_index > main.surface_world.player.z_index)
	var chest_ids: Dictionary = {}
	var chest_positions: Dictionary = {}
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: String = String(chest.id)
		var chest_position: Vector2 = main.surface_world.surface_chest_position(chest_id)
		assert ( not chest_ids.has(chest_id))
		assert ( not chest_positions.has(chest_position))
		chest_ids[chest_id] = true
		chest_positions[chest_position] = chest_id
	assert (chest_ids.size() == 8)
	assert (main.surface_world.surface_chest_position("moss_supply") == Vector2(750, 640))
	assert (main.surface_world.surface_chest_position("moss_ironbound") == Vector2(700, 720))
	for routed_chest in Array(surface_routes.chests):
		var routed_chest_row= Dictionary(routed_chest)
		assert ( not main.surface_world._surface_collides(Vector2(routed_chest_row.position)), "Surface chest must remain on visible walkable terrain: %s at %s" % [String(routed_chest_row.id), Vector2(routed_chest_row.position)])
	assert ( not main.surface_world._surface_collides(Vector2(2860, 788)), "The Ember collision must follow the visible mine path")
	assert (main.surface_world._surface_collides(Vector2(2860, 700)), "Open Ember ground outside the path must not be invisibly walkable")
	assert ( not main.surface_world._surface_collides(Vector2(3890, 930)), "The Starfall collision must follow the visible mine path")
	assert (main.surface_world._surface_collides(Vector2(3890, 735)), "Open Starfall ground outside the path must not be invisibly walkable")
	for routed_mine_id in main.surface_world.MINE_IDS:
		assert ( not main.surface_world._surface_collides(main.surface_world._mine_entrance(String(routed_mine_id))), "Every mine entrance must meet its visible path: %s" % String(routed_mine_id))
	assert (main.surface_world._surface_collides(Vector2(300, 940)))
	assert (main.surface_world._surface_collides(Vector2(1285, 1110)))
	assert (main.surface_world._surface_collides(Vector2(600, 930)), "The annotated foliage below the road must not be walkable")
	var steering_contract: Dictionary = main.surface_world.route_steering_snapshot()
	assert (bool(steering_contract.enabled) and bool(steering_contract.projected_speed) and bool(steering_contract.tangent_fallback))
	assert (is_equal_approx(float(steering_contract.angle_step), 8.0))
	assert (is_equal_approx(float(steering_contract.maximum_angle), 72.0))
	assert (int(steering_contract.refine_steps) == 3)
	assert (bool(steering_contract.never_reverses_input) and bool(steering_contract.visible_solids_remain_blocking))
	var steering_cases: Array[Dictionary] = [
		{"label": "Moonglass", "route": Array(main.surface_world.LATER_MINE_BRANCH_ROUTES.moonMine), "segment": 2},
		{"label": "Emberdeep", "route": Array(main.surface_world.LATER_MINE_BRANCH_ROUTES.emberMine), "segment": 3},
		{"label": "Starfall", "route": Array(main.surface_world.LATER_MINE_BRANCH_ROUTES.starMine), "segment": 2},
	]
	var steering_events_before: int = int(main.surface_world.route_steering_snapshot().events)
	for steering_case_value in steering_cases:
		var steering_case: Dictionary = steering_case_value
		var steering_route: Array = steering_case.route
		var steering_segment: int = int(steering_case.segment)
		var steering_start: Vector2 = Vector2(steering_route[steering_segment])
		var steering_end: Vector2 = Vector2(steering_route[steering_segment + 1])
		var steering_tangent: Vector2 = (steering_end - steering_start).normalized()
		var steering_normal: Vector2 = Vector2( - steering_tangent.y, steering_tangent.x)
		var steering_position: Vector2 = (steering_start + steering_end) * 0.5 + steering_normal * (main.surface_world.LATER_BRANCH_ROUTE_HALF_WIDTH - 0.25)
		var steering_intent: Vector2 = (steering_tangent + steering_normal * 0.65).normalized() * 8.0
		assert ( not main.surface_world._surface_collides(steering_position), "%s soft-rail fixture must start on its visible road" % String(steering_case.label))
		assert (main.surface_world._surface_collides(steering_position + steering_intent), "%s fixture must press outward through the invisible route edge" % String(steering_case.label))
		main.surface_world._reset_surface_route_steering()
		main.surface_world.surface_last_motion_direction = steering_tangent
		for steering_step in range(6):
			var steered_position: Vector2 = main.surface_world._resolve_motion(steering_position, steering_intent)
			var steering_delta: Vector2 = steered_position - steering_position
			assert (steering_delta.length() >= 2.0, "%s soft rails must preserve visible progress" % String(steering_case.label))
			assert (steering_delta.dot(steering_intent) > 0.0 and steering_delta.dot(steering_tangent) > 0.0)
			assert (steering_delta.length() <= steering_intent.length() + 0.01, "Route steering must never boost movement speed")
			assert (main.surface_world._is_on_surface_route(steered_position) and not main.surface_world._surface_collides(steered_position))
			steering_position = steered_position
	assert (int(main.surface_world.route_steering_snapshot().events) >= steering_events_before + steering_cases.size())
	var ember_route: Array = main.surface_world.LATER_MINE_BRANCH_ROUTES.emberMine
	var ember_start: Vector2 = Vector2(ember_route[3])
	var ember_end: Vector2 = Vector2(ember_route[4])
	var ember_tangent: Vector2 = (ember_end - ember_start).normalized()
	var ember_normal: Vector2 = Vector2( - ember_tangent.y, ember_tangent.x)
	main.surface_world._reset_surface_route_steering()
	var outward_position: Vector2 = (ember_start + ember_end) * 0.5 + ember_normal * (main.surface_world.LATER_BRANCH_ROUTE_HALF_WIDTH - 0.25)
	var outward_result: Vector2 = main.surface_world._resolve_motion(outward_position, ember_normal * 8.0)
	var outward_delta: Vector2 = outward_result - outward_position
	assert (outward_delta.length() >= 2.0, "A pure outward press must glide along the road instead of hard-stopping")
	assert (outward_delta.dot(ember_normal) >= -0.01 and outward_delta.dot(ember_tangent) > 0.0)
	assert (outward_delta.length() <= 8.01 and not main.surface_world._surface_collides(outward_result))
	var moonglass_transition: WorldTransitionVisual = main.surface_world.portal_transitions.moonglass as WorldTransitionVisual
	RunState.area_unlocked = false
	moonglass_transition.set_gate_open(false, false)
	var locked_gate_position: Vector2 = main.surface_world._resolve_motion(Vector2(1038, 650), Vector2(160, 70))
	assert (locked_gate_position.x <= 1110.0 - (main.surface_world.BOUNDARY_HALF_WIDTH + main.surface_world.PLAYER_RADIUS) + 0.01)
	assert ( not main.surface_world._surface_collides(locked_gate_position), "Soft rails must never bypass a locked visible portal")
	RunState.area_unlocked = true
	moonglass_transition.set_gate_open(true, false)
	var camera_half_width= viewport_size.x / (2.0 * maxf(absf(landscape_camera.zoom.x), 0.001))
	var camera_center_x= landscape_camera.get_screen_center_position().x
	var camera_left= camera_center_x - camera_half_width
	var camera_right= camera_center_x + camera_half_width
	var coverage_sprites: Array[Sprite2D] = [far_background_sprite, midground_sprite, foreground_sprite]
	for coverage_sprite: Sprite2D in coverage_sprites:
		var coverage_rect: Rect2 = coverage_sprite.get_rect()
		var coverage_left: float = coverage_sprite.to_global(coverage_rect.position).x
		var coverage_right: float = coverage_sprite.to_global(coverage_rect.end).x
		assert (minf(coverage_left, coverage_right) <= camera_left + 1.0)
		assert (maxf(coverage_left, coverage_right) >= camera_right - 1.0)
	var expected_camera_y= landscape_camera.framing_offset_for_viewport(viewport_size.y, landscape_camera.zoom.y)
	assert (is_equal_approx(landscape_camera.position.y, expected_camera_y))
	var design_camera_y= landscape_camera.framing_offset_for_viewport(720.0)
	assert (is_equal_approx(design_camera_y, -129.6))
	var mine_lighting: Dictionary = main.mine_world.lighting_snapshot()
	var headlamp_snapshot: Dictionary = Dictionary(mine_lighting.headlamp)
	var cave_camera_snapshot: Dictionary = Dictionary(mine_lighting.camera)
	assert (bool(headlamp_snapshot.cone_only) and int(headlamp_snapshot.light_count) == 1)
	assert (Vector2i(headlamp_snapshot.texture_size) == Vector2i(256, 256))
	assert (float(headlamp_snapshot.border_alpha_max) <= 0.001)
	assert (is_equal_approx(float(headlamp_snapshot.beam_length), 600.0))
	assert (float(headlamp_snapshot.energy) >= 1.8)
	assert (bool(cave_camera_snapshot.enabled) and float(cave_camera_snapshot.maximum_forward_room) >= 460.0)
	var pickup_feedback: ResourcePickupBurst = main.surface_world.player.get_node("ResourcePickupBurst") as ResourcePickupBurst
	var pickup_contract: Dictionary = pickup_feedback.debug_snapshot()
	assert ( not pickup_feedback.is_processing(), "Idle pickup feedback must not consume an always-on frame callback")
	assert (bool(pickup_contract.transparent) and not bool(pickup_contract.has_panel) and not bool(pickup_contract.has_icon))
	assert (String(pickup_contract.presentation) == "color_coded_text" and bool(pickup_contract.color_coded))
	assert (int(pickup_contract.text_font_size) >= 28)
	assert (float(pickup_contract.hold_seconds) >= 2.6 and float(pickup_contract.fade_seconds) >= 0.7)
	pickup_feedback.show_pickup("stone", 1)
	assert (pickup_feedback.is_processing())
	pickup_feedback.show_pickup("stone", 2)
	var merged_pickup: Dictionary = pickup_feedback.debug_snapshot()
	assert (Array(merged_pickup.entries).size() == 1 and int(Dictionary(Array(merged_pickup.entries)[0]).amount) == 3)
	var stone_pickup: Dictionary = pickup_feedback.entries[0]
	var stone_label: Label = stone_pickup.label as Label
	assert (stone_label.text == "+3 STONE")
	assert (stone_label.get_theme_color("font_color") == Color("e6dfcf"))
	pickup_feedback.show_pickup("copper", 1)
	assert (Array(pickup_feedback.debug_snapshot().entries).size() == 2)
	var copper_pickup: Dictionary = pickup_feedback.entries[1]
	var copper_label: Label = copper_pickup.label as Label
	assert (copper_label.text == "+1 COPPER")
	assert (copper_label.get_theme_color("font_color") == Color("f0a35c"))
	assert (copper_label.get_theme_color("font_color") != stone_label.get_theme_color("font_color"))
	pickup_feedback._process(0.09)
	var pickup_root: Node2D = copper_pickup.root as Node2D
	assert (pickup_root.position.y <= -100.0 and pickup_root.modulate.a > 0.0 and pickup_root.modulate.a < 1.0)
	assert (pickup_root.scale.x >= 0.9 and pickup_root.scale.x <= 1.07)
	pickup_feedback._process(float(pickup_contract.hold_seconds) + float(pickup_contract.fade_seconds) + 0.1)
	assert (Array(pickup_feedback.debug_snapshot().entries).is_empty())
	assert ( not pickup_feedback.is_processing())
	print("EVER_DEEPER_LANDSCAPE_OK config=%dx%d canvas=%dx%d camera_y=%.1f/%.1f menu=%dx%d parallax=%d/%d" % [
		roundi(configured_size.x), roundi(configured_size.y),
		roundi(viewport_size.x), roundi(viewport_size.y), landscape_camera.position.y, design_camera_y,
		roundi(landscape_menu_card.size.x), roundi(landscape_menu_card.size.y),
		int(parallax_snapshot.visible_chunk_count), int(parallax_snapshot.chunk_count),
	])
	main.get_tree().quit(0)


func _run_onboarding_qa() -> void :
	RunState.reset_run(false)
	main.game_started = true
	main.menu_open = false
	main.inventory_open = false
	main.phase = "surface"
	main.surface_world.set_active(true)
	main._update_minimap()
	var map_snapshot: Dictionary = main.minimap_overlay.debug_snapshot()
	assert (bool(map_snapshot.visible) and String(map_snapshot.phase) == "surface")
	assert (float(map_snapshot.redraw_hz) <= 10.0)
	assert (bool(map_snapshot.transparent) and bool(map_snapshot.organic_style) and bool(map_snapshot.overlap_fade))
	assert (Rect2(map_snapshot.map_rect).size.x >= 180.0)
	main.quick_tutorial.open(false)
	var pc_snapshot: Dictionary = main.quick_tutorial.debug_snapshot()
	assert (int(pc_snapshot.item_count) == 5 and not bool(pc_snapshot.has_background) and not bool(pc_snapshot.input_blocking))
	main.quick_tutorial.open(true)
	var mobile_snapshot: Dictionary = main.quick_tutorial.debug_snapshot()
	assert (int(mobile_snapshot.item_count) == 5 and not bool(mobile_snapshot.has_background) and not bool(mobile_snapshot.input_blocking))
	assert (is_equal_approx(float(main.depth_world.SHRINE_RESPAWN_SECONDS), 75.0))
	main.depth_world.shrine_cooldowns["qa-shrine"] = 1.0
	main.depth_world._update_shrine_cooldowns(1.1)
	assert ( not main.depth_world.shrine_cooldowns.has("qa-shrine"))
	print("EVER_DEEPER_ONBOARDING_OK minimap=transparent_organic_overlap_fade tutorial=nonblocking shrine_respawn=75")
	main.get_tree().quit(0)


func _run_iphone_layout_qa() -> void :
	var css_viewports= [
		Vector2(844, 390), Vector2(852, 393), Vector2(874, 402),
		Vector2(912, 420), Vector2(932, 430), Vector2(956, 440),
	]
	for css_size_value in css_viewports:
		var css_size: Vector2 = css_size_value
		var scale_to_css: float = css_size.y / 720.0
		var logical_size: Vector2 = Vector2(720.0 * css_size.x / css_size.y, 720.0)
		main.premium_hud.set_context_action("OPEN", true)
		main._apply_responsive_ui_layout(logical_size)
		var hud: Dictionary = main.premium_hud.apply_iphone_layout_for_test(logical_size)
		var menu: Dictionary = main.premium_menu.apply_iphone_layout_for_test(logical_size)
		var inventory: Dictionary = main.resource_inventory.apply_iphone_layout_for_test(logical_size)
		var main_metrics: Dictionary = main._iphone_layout_metrics(logical_size)
		var icons: Dictionary = Dictionary(hud.icons)
		assert (bool(hud.iphone) and bool(menu.iphone) and bool(inventory.iphone))
		assert (Rect2(hud.menu).size.is_equal_approx(Vector2(96, 96)))
		assert (Rect2(hud.context).size.is_equal_approx(Vector2(206, 104)))
		assert (int(icons.menu_cap) == 96)
		assert (int(icons.guide_cap) == 84)
		assert (int(icons.bag_cap) == 104)
		assert (Vector2(icons.gold).is_equal_approx(Vector2(60, 60)))
		assert (String(menu.version_label) == main.premium_menu.release_label())
		assert (float(menu.version_font_size) * scale_to_css >= 9.0)
		var top_icon_extents: Array[float] = []
		for icon_name in ["menu", "guide"]:
			var visual_size= Vector2(icons[icon_name]) * scale_to_css
			top_icon_extents.append(maxf(visual_size.x, visual_size.y))
		assert (top_icon_extents.min() >= 39.0)
		assert (top_icon_extents.max() - top_icon_extents.min() <= 3.0)
		var bag_visual_size= Vector2(icons.bag) * scale_to_css
		var bag_extent= maxf(bag_visual_size.x, bag_visual_size.y)
		assert (bag_extent >= 48.0)
		var context_variants= {
			"OPEN": 108, "FORGE": 104, "DESCEND": 104, "SELL": 96,
			"BUILD": 104, "DELIVER": 104, "PLACE": 108, "ATTACH ROPE": 108,
		}
		var context_captions= {"ATTACH ROPE": "ATTACH"}
		for context_label in context_variants:
			main.premium_hud.set_context_action(String(context_label), true)
			var variant_icons: Dictionary = main.premium_hud.icon_size_snapshot()
			assert (int(variant_icons.context_cap) == int(context_variants[context_label]))
			assert (main.premium_hud.context_button.text == String(context_captions.get(context_label, context_label)))
			var context_visual_size= Vector2(variant_icons.context) * scale_to_css
			var context_extent= maxf(context_visual_size.x, context_visual_size.y)
			assert (context_extent >= 48.0)
			assert (context_extent / bag_extent <= 1.12)
		main.premium_hud.set_context_action("OPEN", true)
		var mine_visual_size: Vector2 = main.premium_hud.button_icon_visual_size(main.mine_button) * scale_to_css
		assert (maxf(mine_visual_size.x, mine_visual_size.y) >= 67.0)
		for target_name in ["menu", "guide", "bag", "context"]:
			var target_rect: Rect2 = hud[target_name]
			assert (target_rect.size.x * scale_to_css >= 44.0)
			assert (target_rect.size.y * scale_to_css >= 44.0)
		for target_name in ["continue", "new_game", "achievements", "settings", "back", "confirm_cancel", "confirm_accept"]:
			var target_rect: Rect2 = menu[target_name]
			assert (target_rect.size.y * scale_to_css >= 44.0)
		assert (float(inventory.close_height) * scale_to_css >= 44.0)
		assert (float(inventory.auto_sort_height) * scale_to_css >= 44.0)
		assert (int(inventory.columns) == 4)
		assert (Rect2(menu.safe_rect).encloses(Rect2(menu.main)))
		assert (Rect2(menu.safe_rect).encloses(Rect2(menu.detail)))
		assert (Rect2(menu.safe_rect).encloses(Rect2(menu.confirm)))
		assert (Rect2(inventory.safe_rect).encloses(Rect2(inventory.card)))
		assert (Rect2(main_metrics.safe_rect).encloses(Rect2(main_metrics.mine)))
		assert (Rect2(hud.safe_rect).encloses(Rect2(hud.context)))
		assert (Rect2(hud.mine).is_equal_approx(Rect2(main_metrics.mine)))
		assert (main.movement_pad._is_in_movement_zone(Vector2(0.0, logical_size.y)))
		assert (main.movement_pad._is_in_movement_zone(Vector2(1.0, logical_size.y - 1.0)))
		main.movement_pad._begin(77, Vector2(0.0, logical_size.y - 1.0))
		main.movement_pad._update_knob(Vector2(48.0, logical_size.y - 1.0))
		assert (main.button_move.is_equal_approx(Vector2.RIGHT))
		main.movement_pad._end()
		assert (Rect2(main_metrics.safe_rect).encloses(Rect2(main_metrics.conclusion)))
		assert (Rect2(main_metrics.mine).size.y * scale_to_css >= 80.0)
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.menu)))
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.guide)))
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.gold)))
		assert ( not Rect2(hud.objective).intersects(Rect2(hud.bag)))
		assert ( not Rect2(hud.context).intersects(Rect2(main_metrics.mine)))
		assert ( not Rect2(hud.context).intersects(Rect2(hud.bag)))
		assert ( not Rect2(hud.bag).intersects(Rect2(main_metrics.mine)))
		assert (is_equal_approx(Rect2(main_metrics.mine).position.x - Rect2(hud.bag).end.x, 18.0))
		assert (Rect2(hud.bag).position.y > logical_size.y * 0.5)
		var guide_safe: Rect2 = main.guide_overlay.safe_rect_for_viewport(logical_size)
		assert (guide_safe.position.x >= 110.0)
		assert (guide_safe.position.y >= Rect2(hud.menu).end.y + 36.0)
		assert (guide_safe.end.x <= Rect2(hud.bag).position.x - 30.0)
		assert (main.premium_hud.context_button.text == "OPEN")
		assert ((main.get_node("HUD/TouchControls/Mine/Caption") as Label).text == "MINE")
		assert (main.premium_hud.objective_title.get_theme_font_size("font_size") * scale_to_css >= 10.5)
		assert (main.premium_hud.status_label.get_theme_font_size("font_size") * scale_to_css >= 10.5)
		assert (main.premium_menu.continue_button.get_theme_font_size("font_size") * scale_to_css >= 13.0)
		assert ((main.premium_menu.main_card.get_node("NewGame") as Button).get_theme_font_size("font_size") * scale_to_css >= 11.0)
		for variant_id in main.STARFORGE_VARIANT_IDS:
			var starforge_button: Button = main.starforge_buttons[variant_id]
			assert (starforge_button.size.y * scale_to_css >= 44.0)
			assert (Rect2(Vector2.ZERO, main.starforge_panel.size).encloses(Rect2(starforge_button.position, starforge_button.size)))
		assert (main.conclusion_continue_button.size.y * scale_to_css >= 44.0)
		assert (main.conclusion_hub_button.size.y * scale_to_css >= 44.0)
		assert ( not main.premium_hud.build_button.visible and main.premium_hud.build_button.disabled)
	print("EVER_DEEPER_IPHONE_LAYOUT_OK devices=844x390,852x393,874x402,912x420,932x430,956x440 touch=44css icons=optically-normalized safe=notch/home overlays=menu,bag,museum,starforge,conclusion")
	main.get_tree().quit(0)


func _run_portrait_qa() -> void :
	var portrait_logical= Vector2(1280, 2770)
	main._apply_responsive_ui_layout(portrait_logical)
	main._sync_orientation_guard(portrait_logical, true)
	var card: Panel = main.orientation_guard.get_node("Card") as Panel
	var phone: Panel = card.get_node("Phone") as Panel
	assert (main.orientation_guard_active and main.orientation_guard.visible)
	assert (card.size.x >= 1000.0 and card.size.y >= 700.0)
	assert (phone.size.is_equal_approx(Vector2(100, 58)))
	assert (phone.scale.is_equal_approx(Vector2(3, 3)))
	var landscape_logical= Vector2(1558, 720)
	main._apply_responsive_ui_layout(landscape_logical)
	main._sync_orientation_guard(landscape_logical, true)
	assert ( not main.orientation_guard_active and not main.orientation_guard.visible)
	print("EVER_DEEPER_PORTRAIT_GUARD_OK portrait=1280x2770 landscape=1558x720 card=%dx%d" % [roundi(card.size.x), roundi(card.size.y)])
	main.get_tree().quit(0)

