extends SceneTree
## Opt-in rendered attribution and reversible broad/narrow receiver comparison.
## Run with --script; deliberately separate from normal QA startup and player saves.
const DIAGNOSTIC_MASK: int = 1 << 18
var output_dir: String = ""
var main: Node
var state: Node
var world: Node2D
var lights: Array[Dictionary] = []
var rows: Array[Dictionary] = []
var attribution: bool = false
var failed: bool = false
var selected_fixture: String = ""

func _initialize() -> void:
	_run.call_deferred()

func require(ok: bool, message: String) -> bool:
	if not ok:
		failed = true
		push_error("HUB_RECEIVER_REVIEW_FAIL " + message)
		quit(2)
	return ok

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=", 1)
		if arg == "--attribute": attribution = true
		if arg.begins_with("--fixture="): selected_fixture = arg.get_slice("=", 1)
	if not require(DisplayServer.get_name() != "headless", "Rendered viewport required"): return
	if not require(not output_dir.is_empty(), "Explicit output directory required"): return
	DirAccess.make_dir_recursive_absolute(output_dir)
	state = root.get_node("RunState")
	seed(4608)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	# Main initializes persistence in _ready; install the isolated fixture after it.
	state.initialize_persistence(output_dir.path_join("isolated-receiver-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	for frame in 5: await process_frame
	main.game_started = true
	main._dev_seed_victory_state()
	if not require(main._dev_build_all_workshops_state(), "Built workshop fixture"): return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = state.workshop_status(workshop).next_upgrade
			state.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not require(bool(state.upgrade_workshop(workshop).get("ok", false)), "Fixture upgrade"): return
	state.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if not require(main._dev_jump_hub(), "Hub fixture"): return
	world = main.hub_world
	world.restore_position(Vector2(430, 820))
	world.player.set_external_movement(Vector2.ZERO)
	world.player.set_facing(Vector2.RIGHT)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	await _settle(10.0)
	if not require(world.static_light_field.ready_for_use and not world.static_light_field.baking, "Static field finished"): return
	main.achievement_toast.clear()
	await process_frame
	paused = true
	Engine.time_scale = 0.0
	for node in world.find_children("*", "PointLight2D", true, false):
		lights.append({"node":node,"mask":node.range_item_cull_mask,"shadow_mask":node.shadow_item_cull_mask,"enabled":node.enabled,"shadow":node.shadow_enabled,"shadow_filter":node.shadow_filter,"shadow_smooth":node.shadow_filter_smooth,"energy":node.energy,"color":node.color,"texture":node.texture,"offset":node.offset,"position":node.global_position,"rotation":node.global_rotation,"global_scale":node.global_scale,"scale":node.texture_scale})
	if attribution:
		await _attribute()
	else:
		if not require(world.get("trimmed_hub_texture_margins") != null, "Candidate texture-margin switch required"): return
		await _compare()
	if failed: return
	_restore_masks()
	if not require(_lights_preserved(), "Original lights and shadows preserved"): return
	var report: Dictionary = {"physical_iphone":false,"rendered":true,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"window":str(DisplayServer.window_get_size()),"mode":"attribution" if attribution else "comparison","candidate":"transparent texture margins only","terminal_visual_fixture":"complete" if attribution else "repaired","stages":rows,"lights_preserved":true}
	var file: FileAccess = FileAccess.open(output_dir.path_join("hub-light-receivers.json"), FileAccess.WRITE)
	if not require(file != null, "Report opened"): return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	Engine.time_scale = 1.0
	paused = false
	print("HUB_RECEIVER_REVIEW_OK " + JSON.stringify({"stages":rows.size(),"physical_iphone":false}))
	quit(0)

func _attribute() -> void:
	if world.get("trimmed_hub_texture_margins") != null:
		world.trimmed_hub_texture_margins = false
		world.queue_redraw()
	await _settle(1.0)
	await _measure("original", 8.0)
	for method in ["_draw_ground_border", "_draw_hub_wall_frame", "_draw_foundation_route", "_draw_relic_museum", "_draw_lift", "_draw_workshop_site"]:
		var receivers: Array[Dictionary] = []
		for section in world.lit_draw_sections._pool:
			if section.visible and section.paint.get_method() == method:
				receivers.append({"node":section,"mask":section.light_mask})
		if not require(not receivers.is_empty(), "Receiver group " + method): return
		# All lights still illuminate this group except the pet's cone. This is
		# attribution only; neither the cone nor any receiver is removed from play.
		for entry in lights:
			var pet_cone: bool = entry.node.name == "HelmetCone" and "MoleCompanion" in str(world.get_path_to(entry.node))
			entry.node.range_item_cull_mask = entry.mask if pet_cone else int(entry.mask) | DIAGNOSTIC_MASK
		for receiver in receivers: receiver.node.light_mask = DIAGNOSTIC_MASK
		await _measure(method.trim_prefix("_draw_") + "-pet-cone-excluded", 8.0)
		for receiver in receivers: receiver.node.light_mask = receiver.mask
		_restore_masks()
		await _measure("restore-" + method.trim_prefix("_draw_"), 6.0)

func _compare() -> void:
	# The unrelated terminal pulse reads wall-clock time on every redraw. Exercise
	# its existing repaired artwork for deterministic comparisons; no lights change.
	world.elevator_status = world.elevator_status.duplicate(true)
	world.elevator_status["victory"] = false
	world.elevator_status["powered"] = false
	world.elevator_status["repaired"] = true
	var positions: Array[Vector2] = [Vector2(430,820),Vector2(1200,480),Vector2(720,200),Vector2(90,90),Vector2(1200,800)]
	var styles: Array[String] = ["standard","wide","focused","prismatic","deepheart"]
	var directions: Array[Vector2] = [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2(-1,-1),Vector2.DOWN]
	if not require(selected_fixture.is_empty() or selected_fixture in styles, "Known fixture name"): return
	var receiver_capacity: int = 0
	for index in positions.size():
		if not selected_fixture.is_empty() and styles[index] != selected_fixture:
			continue
		var previous_position: Vector2 = world.player.global_position
		world.restore_position(positions[index])
		world.get_node("MoleCompanion").global_position += world.player.global_position - previous_position
		world.player.camera.reset_smoothing()
		world.player.camera.force_update_scroll()
		world.player.set_facing(directions[index])
		for node in world.find_children("HelmetCone", "PointLight2D", true, false):
			var beam: Node2D = node.get_parent()
			beam.preview_settings = {"style":styles[index],"range_multiplier":1.4,"energy_multiplier":1.3}
			beam.refresh_workshop_effects()
			beam.set_direction(directions[index])
		# Capture after the same intentional fixture transform for all variants.
		for entry in lights:
			entry.position = entry.node.global_position
			entry.rotation = entry.node.global_rotation
			entry.scale = entry.node.texture_scale
			entry.offset = entry.node.offset
			entry.energy = entry.node.energy
			entry.color = entry.node.color
			entry.global_scale = entry.node.global_scale
		for variant in ["broad","narrow","restored"]:
			world.trimmed_hub_texture_margins = variant == "narrow"
			world.queue_redraw()
			await _measure("%02d-%s-%s" % [index,styles[index],variant], 8.0)
			if not require(_lights_preserved(), "No light mutations in " + variant): return
			if variant == "narrow":
				if receiver_capacity == 0: receiver_capacity = world.lit_draw_sections._pool.size()
				if not require(world.lit_draw_sections._pool.size() == receiver_capacity, "Stable section pool"): return
			for unused in range(world.lit_draw_sections._used, world.lit_draw_sections._pool.size()):
				if not require(not world.lit_draw_sections._pool[unused].visible, "Inactive section hidden"): return
	world.trimmed_hub_texture_margins = true
	world.queue_redraw()

func _restore_masks() -> void:
	for entry in lights:
		entry.node.range_item_cull_mask = entry.mask
		entry.node.shadow_item_cull_mask = entry.shadow_mask

func _lights_preserved() -> bool:
	if world.find_children("*", "PointLight2D", true, false).size() != lights.size(): return false
	for entry in lights:
		var node: PointLight2D = entry.node
		if not is_instance_valid(node): return false
		if node.range_item_cull_mask != entry.mask or node.shadow_item_cull_mask != entry.shadow_mask: return false
		if node.enabled != entry.enabled or node.shadow_enabled != entry.shadow: return false
		if node.shadow_filter != entry.shadow_filter or node.shadow_filter_smooth != entry.shadow_smooth: return false
		if node.energy != entry.energy or node.texture != entry.texture or node.offset != entry.offset: return false
		if node.color != entry.color or node.global_scale != entry.global_scale: return false
		if node.global_position != entry.position or node.global_rotation != entry.rotation or node.texture_scale != entry.scale: return false
	return true

func _settle(seconds: float) -> void:
	var begun: int = Time.get_ticks_usec()
	while Time.get_ticks_usec() - begun < int(seconds * 1000000.0): await process_frame
	await RenderingServer.frame_post_draw

func _measure(label: String, seconds: float) -> void:
	await _settle(1.0)
	var begun: int = Time.get_ticks_usec()
	var previous: int = begun
	var samples: Array[float] = []
	var draws: Array[float] = []
	while Time.get_ticks_usec() - begun < int(seconds * 1000000.0):
		await process_frame
		var now: int = Time.get_ticks_usec()
		samples.append(float(now - previous) / 1000.0)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		previous = now
	if not require(samples.size() >= 3, "Enough rendered frames " + label): return
	var total: float = 0.0
	for value in samples: total += value
	samples.sort()
	draws.sort()
	var row: Dictionary = {"stage":label,"frames":samples.size(),"fps":samples.size() * 1000.0 / total,"p95_ms":samples[clampi(ceili(samples.size() * 0.95)-1,0,samples.size()-1)],"draw_calls":draws[draws.size()/2],"visible_sections":world.lit_draw_sections._used}
	rows.append(row)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join(label + ".png"))
	print("HUB_RECEIVER_STAGE " + JSON.stringify(row))
