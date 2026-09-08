extends RefCounted
## Tests the shipped diagnostic itself, including real durations and restoration.
var main: Node
var output_dir: String
var area := "hub"

func _init(game: Node, output: String) -> void:
	main = game
	output_dir = output

func require(ok: bool, message: String) -> bool:
	if not ok:
		push_error("RENDER_PROBE_REVIEW_FAIL " + message)
		main.get_tree().quit(2)
	return ok

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-area="): area = arg.get_slice("=", 1)
	if not require(main.developer_menu != null and OS.has_feature("ever_deeper_dev"), "DEV pack required"): return
	if not require(DisplayServer.get_name() != "headless", "Rendered check required"): return
	RunState.initialize_persistence(output_dir.path_join("isolated-probe-save.json"))
	main.persistence_active = true
	main.game_started = true
	main._dev_seed_victory_state()
	if not require(main._dev_build_all_workshops_state(), "Workshops"): return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop).next_upgrade
			RunState.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not require(bool(RunState.upgrade_workshop(workshop).get("ok", false)), "Workshop upgrade"): return
	var skills := {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	RunState.overhaul_progress["skills"] = skills.duplicate()
	if not require(main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine", 2), "Area"): return
	if area == "hub": main.hub_world.restore_position(Vector2(1200, 480))
	for frame in 3: await main.get_tree().process_frame
	main.developer_menu.toggle_frame_meter()
	main.developer_menu.open_menu()
	main.developer_menu.render_probe_button.pressed.emit()
	var probe: Control = main.developer_menu.render_probe
	print("PROBE_START_STATE " + JSON.stringify({"running":probe.running,"drawer":main.developer_menu.is_open(),"meter_processing":main.developer_menu.frame_meter.is_processing(),"error":probe.start_error,"browser":probe._browser_snapshot()}))
	if not require(probe.running and not main.developer_menu.is_open() and not main.developer_menu.frame_meter.is_processing(), "Button starts and closes drawer"): return
	var previous_stage := -1
	var started := Time.get_ticks_usec()
	while probe.running:
		await main.get_tree().process_frame
		if not probe.running: break
		if Time.get_ticks_usec() - started > 140000000:
			require(false, "Timeout"); return
		if probe.stage_index != previous_stage:
			previous_stage = probe.stage_index
			for frame in 3: await main.get_tree().process_frame
			var id: String = probe.STAGES[previous_stage].id
			print("PROBE_STAGE_READY " + JSON.stringify({"area":area,"stage":id,"state":probe._snapshot()}))
			if not OS.has_feature("web"):
				await RenderingServer.frame_post_draw
				var capture: Image = main.get_viewport().get_texture().get_image()
				if not require(capture.get_size() == DisplayServer.window_get_size(), "Native framebuffer matches window " + id): return
				capture.save_png(output_dir.path_join(area + "-" + id + ".png"))
	while not probe.result.has("graphics_restored"): await main.get_tree().process_frame
	var full: Dictionary = probe.result.duplicate(true)
	if not require(not full.cancelled and full.graphics_restored and full.rows.size() == 7 and float(full.duration_seconds) >= 120.0, "Complete original-duration run"): return
	if not require(float(full.rows[0].elapsed_seconds) >= 60.0, "Baseline crosses delayed-failure threshold"): return
	var baseline: Dictionary = full.baseline
	for row in full.rows:
		if not require(row.frames >= 3 and row.fps > 0, "Valid frame sample " + row.stage): return
		if row.stage == "pet_off":
			if not require(row.pet_lights == 0 and row.lights == baseline.lights - baseline.pet_lights, "Only pet lights disabled"): return
		elif row.stage == "shadows_off":
			if not require(row.shadows == 0 and row.lights == baseline.lights, "Only shadows disabled"): return
		elif row.stage == "lights_off":
			if not require(row.lights == 0, "All lights disabled"): return

		else:
			if not require(row.lights == baseline.lights and row.shadows == baseline.shadows and row.canvas_width == baseline.canvas_width and row.canvas_height == baseline.canvas_height, "Original settings restored " + row.stage): return
	if not require(RunState.overhaul_progress.skills == skills and main.developer_menu.frame_meter.is_processing() and not main.developer_menu.toggle_button.disabled, "Skills and prior meter state restored"): return
	FileAccess.open(output_dir.path_join(area + "-probe.json"), FileAccess.WRITE).store_string(JSON.stringify(full, "\t"))
	for stage in [1, 3, 5]:
		if not require(main.developer_menu.start_render_probe(), "Cancel run starts"): return
		while probe.stage_index < stage: probe._next_stage()
		for frame in 3: await main.get_tree().process_frame
		probe.cancel_button.pressed.emit()
		while not probe.result.has("graphics_restored"): await main.get_tree().process_frame
		if not require(probe.result.cancelled and probe.settings_restored(), "Cancel restores stage %d" % stage): return
	if not require(main.developer_menu.start_render_probe(), "Focus run starts"): return
	probe._next_stage()
	probe._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	while not probe.result.has("graphics_restored"): await main.get_tree().process_frame
	if not require(probe.result.cancelled and probe.settings_restored(), "Focus loss restores"): return
	if OS.has_feature("web"):
		if not require(main.developer_menu.start_render_probe(), "Touch run starts"): return
		while probe.stage_index < 5: probe._next_stage()
		for frame in 4: await main.get_tree().process_frame
		var canvas: Dictionary = probe._browser_snapshot()
		var point: Vector2 = main.get_viewport().get_screen_transform() * probe.cancel_button.get_global_rect().get_center()
		point *= Vector2(float(canvas.css_width) / float(canvas.width), float(canvas.css_height) / float(canvas.height))
		JavaScriptBridge.eval("window.__renderProbeTouchTarget=" + JSON.stringify({"x":point.x,"y":point.y}))
		print("PROBE_TOUCH_READY")
		await probe.completed
		if not require(probe.result.cancelled and probe.settings_restored(), "Real mobile tap while lights are disabled"): return

	probe.result = full
	probe.rows.assign(full.rows)
	probe.early = full.early
	probe._show_result()
	for frame in 4: await main.get_tree().process_frame
	if not require(main.get_viewport().get_visible_rect().encloses(probe.result_panel.get_global_rect()), "Result panel fits viewport"): return
	print("RENDER_PROBE_REVIEW_OK " + JSON.stringify({"area":area,"report":full,"cancel_stages":3,"focus":true,"mobile_tap":OS.has_feature("web")}))
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.everDeeperRenderProbeResult=" + JSON.stringify(full))
	else:
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(output_dir.path_join(area + "-result.png"))
		main.get_tree().quit(0)
