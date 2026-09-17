extends SceneTree
## Render real pickup/achievement UI together; judge observable bounds and input.
## No production substitutions, manual animation ticks or altered feedback timers.
const DEFINITION := {"id": "rune_ready", "title": "Rune Ready", "asset": "assets/achievements/rune_ready.png"}
const FIRST_SIZE := Vector2i(1696, 780)
var output := ""
var pack_source := ""
var main: Node
var world: Node
var player: Node2D
var feedback: Node
var toast: Control
var camera: Camera2D
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var captures: Array[Dictionary] = []
var activations: Array[String] = []
var layout_costs: Array[Dictionary] = []
var motion_samples: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(ok: bool, name: String) -> void:
	checks.append({"name": name, "passed": ok})
	if not ok:
		failures.append(name)
		print("FEEDBACK_OVERLAP_ASSERT_FAIL ", name)


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless":
		print("FEEDBACK_OVERLAP_USAGE requires a rendered display and absolute --output")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = FIRST_SIZE
	root.content_scale_size = FIRST_SIZE
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	_check(main._dev_jump_endless(1), "Enter the actual generated Deep")
	world = main.endless_world
	player = world.player
	feedback = player.get_node("ResourcePickupBurst")
	toast = main.achievement_toast
	main.quick_tutorial.dismiss()
	main._refresh_hud()
	# Freeze only the scene beneath the feedback. The real feedback nodes and
	# GUI retain their normal process/input paths and animation clocks.
	world.set_process(false)
	world.set_physics_process(false)
	player.set_physics_process(false)
	player.set_external_movement(Vector2.ZERO)
	player.camera.enabled = false
	camera = Camera2D.new()
	camera.position_smoothing_enabled = false
	world.add_child(camera)
	camera.make_current()
	toast.activated.connect(func(id: String): activations.append(id))
	for frame in 5: await process_frame
	toast.clear()
	var cases: Array[Dictionary] = [
		{"id": "01_simultaneous", "size": FIRST_SIZE, "zoom": 1.0, "hero": Vector2(0.54, 0.46)},
		{"id": "02_zoomed", "size": FIRST_SIZE, "zoom": 1.35, "hero": Vector2(0.54, 0.46)},
		{"id": "03_left_edge", "size": Vector2i(1688, 780), "zoom": 0.8, "hero": Vector2(0.12, 0.42)},
		{"id": "05_lower_edge", "size": FIRST_SIZE, "zoom": 1.0, "hero": Vector2(0.54, 0.86)},
		{"id": "04_right_edge", "size": Vector2i(1688, 780), "zoom": 1.15, "hero": Vector2(0.88, 0.42)},
	]
	for spec in cases:
		await _run_case(spec)
	_measure_crowded_cost()
	_finish()


func _run_case(spec: Dictionary) -> void:
	toast.clear()
	# Let the previous pickup's actual lifetime end, never clear it by hand.
	var old_deadline: int = Time.get_ticks_msec() + 15000
	while not feedback.entries.is_empty() and Time.get_ticks_msec() < old_deadline:
		await process_frame
	_check(feedback.entries.is_empty(), String(spec.id) + ": previous pickup expires normally")
	root.size = Vector2i(spec.size)
	root.content_scale_size = Vector2i(spec.size)
	for frame in 3: await process_frame
	var viewport_size: Vector2 = root.get_visible_rect().size
	camera.zoom = Vector2.ONE * float(spec.zoom)
	camera.global_position = player.global_position - (viewport_size * Vector2(spec.hero) - viewport_size * 0.5) / float(spec.zoom)
	camera.force_update_scroll()
	for frame in 3: await process_frame
	main._on_resource_collected("waystone", 3)
	main._on_resource_collected("memory_silk", 3)
	main._on_resource_collected("deep_alloy", 3)
	main._on_resource_collected("waystone", 2)
	var event_started: int = Time.get_ticks_usec()
	main._on_achievement_unlocked(DEFINITION)
	var event_usec: int = Time.get_ticks_usec() - event_started
	var born_ms: int = Time.get_ticks_msec()
	var ready_deadline: int = born_ms + 15000
	while String(toast.debug_snapshot().phase) == "spin" and Time.get_ticks_msec() < ready_deadline:
		await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var snapshot: Dictionary = toast.debug_snapshot()
	_check(String(snapshot.phase) == "hold", String(spec.id) + ": achievement reaches its real hold phase")
	_check(feedback.entries.size() == 3, String(spec.id) + ": three real pickup labels coexist")
	var values: Dictionary = {}
	for entry in feedback.entries: values[String(entry.kind)] = int(entry.amount)
	_check(values == {"waystone": 5, "memory_silk": 3, "deep_alloy": 3}, String(spec.id) + ": resource merging preserves all amounts")
	var button: Button = toast.get_node("AchievementToastContent/ActivationTarget")
	var toast_rect: Rect2 = button.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, button.size)
	var pickup_rects: Array[Rect2] = []
	for entry in feedback.entries:
		var label: Label = entry.label as Label
		# Label's own minimum size supplies its shaped line size independently of
		# the production coordinator. Check its visible outline in canvas space.
		var ink_size: Vector2 = label.get_minimum_size()
		var ink_rect: = Rect2((label.size - ink_size) * 0.5, ink_size).grow(float(label.get_theme_constant("outline_size")))
		pickup_rects.append(label.get_global_transform_with_canvas() * ink_rect)
	for index in pickup_rects.size():
		_check(not toast_rect.intersects(pickup_rects[index]), String(spec.id) + ": achievement stays clear of pickup " + str(index + 1))
	var hero_sprite: Sprite2D = player.get_node("Visual").get_child(0) as Sprite2D
	var hero_rect: Rect2 = hero_sprite.get_global_transform_with_canvas() * hero_sprite.get_rect()
	_check(not toast_rect.intersects(hero_rect), String(spec.id) + ": hero remains unobscured")
	_check(Rect2(snapshot.safe_rect).encloses(toast_rect), String(spec.id) + ": complete activation target stays in mobile safe bounds")
	_check(button.size.x >= 96.0 and button.size.y >= 96.0, String(spec.id) + ": touch target is retained")
	var hud_controls: Array[Control] = [main.premium_hud.menu_button, main.premium_hud.guide_button, main.premium_hud.bag_button, main.premium_hud.context_button, main.premium_hud.progression_goal_panel, main.mine_button]
	for control in hud_controls:
		if control.is_visible_in_tree():
			var control_rect: Rect2 = control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size)
			_check(not toast_rect.intersects(control_rect), String(spec.id) + ": HUD " + String(control.name) + " remains clear")
	await _capture(String(spec.id), {"zoom": float(spec.zoom), "hero": hero_rect, "toast": toast_rect, "pickups": pickup_rects, "values": values})
	var costs: Array[int] = []
	for repeat in 100:
		var start: int = Time.get_ticks_usec()
		main._update_achievement_toast_anchor()
		costs.append(Time.get_ticks_usec() - start)
	layout_costs.append({"case": spec.id, "achievement_event_usec": event_usec, "steady_update_usec": _cost_summary(costs)})
	if String(spec.id) == "01_simultaneous":
		await _move_camera(button)
		toast_rect = button.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, button.size)
	if String(spec.id) == "04_right_edge":
		var before: int = activations.size()
		await _tap(button)
		_check(activations.size() == before + 1 and activations.back() == "rune_ready", "Actual tap activates the repositioned achievement exactly once")
		_check(not toast.is_presenting(), "Activation dismisses the actual toast")
		_check(main.menu_open, "Actual activation opens the achievement menu")
	else:
		var lifetime_deadline: int = Time.get_ticks_msec() + 20000
		while not feedback.entries.is_empty() and Time.get_ticks_msec() < lifetime_deadline:
			await process_frame
		_check(feedback.entries.is_empty() and not feedback.is_processing(), String(spec.id) + ": pickup fades and releases its frame callback")
		if String(spec.id) == "01_simultaneous":
			_check(toast.is_presenting(), "Achievement survives the shorter pickup lifetime")
			var after: Rect2 = button.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, button.size)
			_check(after.position.distance_to(toast_rect.position) <= 1.0, "Pickup expiry does not make the same achievement jump")
			await _capture("06_pickups_expired", {"toast": after, "active": toast.is_presenting()})
		while toast.is_presenting() and Time.get_ticks_msec() < lifetime_deadline:
			await process_frame
		_check(not toast.is_presenting() and not button.is_visible_in_tree(), String(spec.id) + ": achievement expires and releases its activation target")
		_check(Time.get_ticks_msec() - born_ms >= 3500, String(spec.id) + ": feedback does not disappear prematurely")


func _move_camera(button: Button) -> void:
	var from: Vector2 = camera.global_position
	var tween: Tween = create_tween()
	tween.tween_property(camera, "global_position", from + Vector2(150.0, -32.0) / camera.zoom, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var pickup_contacts: int = 0
	var hero_contacts: int = 0
	var unsafe_samples: int = 0
	while tween.is_running():
		await process_frame
		await RenderingServer.frame_post_draw
		var rect: Rect2 = button.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, button.size)
		var contacts: int = 0
		for entry in feedback.entries:
			var label: Label = entry.label as Label
			var ink_size: Vector2 = label.get_minimum_size()
			var ink_rect: = Rect2((label.size - ink_size) * 0.5, ink_size).grow(float(label.get_theme_constant("outline_size")))
			if rect.intersects(label.get_global_transform_with_canvas() * ink_rect): contacts += 1
		pickup_contacts += contacts
		var sprite: Sprite2D = player.get_node("Visual").get_child(0) as Sprite2D
		var hero_contact: bool = rect.intersects(sprite.get_global_transform_with_canvas() * sprite.get_rect())
		if hero_contact: hero_contacts += 1
		if not Rect2(toast.debug_snapshot().safe_rect).encloses(rect): unsafe_samples += 1
		motion_samples.append({"time_msec": Time.get_ticks_msec(), "camera": camera.global_position, "toast": rect, "pickup_count": feedback.entries.size(), "pickup_contacts": contacts, "hero_contact": hero_contact})
	_check(camera.global_position.distance_to(from) >= 149.0, "Actual camera moves while three pickups and achievement are active")
	_check(motion_samples.size() >= 3, "Moving camera is checked across rendered frames")
	_check(pickup_contacts == 0, "Achievement remains clear of pickup flow throughout sampled camera movement")
	_check(hero_contacts == 0 and unsafe_samples == 0, "Moving feedback keeps the hero and mobile safe bounds clear")
	_check(feedback.entries.size() == 3 and toast.is_presenting(), "Camera movement preserves all concurrent feedback")
	await _capture("07_camera_moved", {"samples": motion_samples.size(), "camera": camera.global_position, "pickup_contacts": pickup_contacts, "hero_contacts": hero_contacts})


func _measure_crowded_cost() -> void:
	if not feedback.has_method("screen_rects"):
		return # Old-package negative control has no placement coordinator.
	var probe: Control = load("res://scripts/ui/achievement_toast.gd").new()
	root.add_child(probe)
	probe.show_achievement(DEFINITION)
	var area: Rect2 = root.get_visible_rect()
	var obstacles: Array[Rect2] = []
	for row in 4:
		for column in 6:
			obstacles.append(Rect2(area.position + Vector2(column, row) * area.size / Vector2(6, 4), area.size / Vector2(6, 4)))
	var costs: Array[int] = []
	for repeat in 100:
		var start: int = Time.get_ticks_usec()
		probe.set_screen_anchor(area.get_center(), obstacles)
		costs.append(Time.get_ticks_usec() - start)
	layout_costs.append({"case": "no_free_area_24_obstacles", "first_update_usec": costs[0], "all_updates_usec": _cost_summary(costs)})
	probe.queue_free()


func _cost_summary(values: Array[int]) -> Dictionary:
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	var total: int = 0
	for value in sorted: total += value
	return {"calls": sorted.size(), "mean": float(total) / maxf(1, sorted.size()), "p95": sorted[mini(sorted.size() - 1, floori(sorted.size() * 0.95))], "max": sorted.back()}


func _tap(control: Control) -> void:
	var point: Vector2 = control.get_global_transform_with_canvas() * (control.size * 0.5)
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.position = point
		event.global_position = point
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame


func _capture(id: String, observation: Dictionary) -> void:
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	var path: String = output.path_join(id + ".png")
	_check(frame.save_png(path) == OK, id + ": actual image saved")
	captures.append({"id": id, "path": path, "size": [frame.get_width(), frame.get_height()], "sha256": FileAccess.get_sha256(path), "observation": observation})


func _finish() -> void:
	var report: Dictionary = {"passed": failures.is_empty(), "checks": checks, "failures": failures, "captures": captures, "activations": activations, "layout_costs": layout_costs, "motion_samples": motion_samples, "pack_sha256": FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else "", "rendered": true, "physical_iphone": false, "fps_claim": false, "manual_feedback_ticks": false}
	var file := FileAccess.open(output.path_join("feedback-overlap.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("FEEDBACK_OVERLAP_COMPLETE passed=%s checks=%d captures=%d" % [str(failures.is_empty()), checks.size(), captures.size()])
	quit(0 if failures.is_empty() else 1)
