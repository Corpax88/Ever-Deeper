extends SceneTree
## Source-only recovery review. This is not an exported-package or FPS gate.
var output_dir: String
var main: Node
var driver: Node
var rows: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_dir = argument.trim_prefix("--output=")
	if output_dir.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	root.get_node("RunState").initialize_persistence(output_dir.path_join("isolated-save.json"))
	driver = load("res://scripts/dev/visual_capture_driver.gd").new()
	root.add_child(driver)
	driver.set("_main", main)
	driver.set("_overhaul_mode", true)
	driver.set("_hero_mode", true)
	var selected_surface: Array[String] = ["surface_start", "surface_camp_assay", "surface_camp_forge", "surface_wayfarer", "surface_mine_entrance", "surface_gate_under_arch", "surface_moon_surface", "surface_ember_surface", "surface_star_surface"]
	var states: Array = driver.call("_build_overhaul_states")
	for state: Dictionary in states:
		var id: String = String(state.id)
		var selected: bool = id in selected_surface or id in ["overhaul_world_hub", "overhaul_world_deepheart"]
		selected = selected or String(state.kind) in ["d1_edges", "d1_bedrock", "d2_edges", "d2_transition"]
		selected = selected or (String(state.kind) == "overhaul_depth_shop" and String(state.get("station", "")) == "stations")
		if not selected: continue
		driver.call("_resume_capture_nodes")
		if not driver.call("_prepare_state", state):
			push_error("Recovery fixture failed: " + id)
			quit(3)
			return
		if not await driver.call("_settle_hero_state", state):
			push_error("Recovery hero assets failed: " + id)
			quit(4)
			return
		for _frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		var picture: Image = root.get_texture().get_image()
		var destination: String = output_dir.path_join(id + ".png")
		if picture.save_png(destination) != OK:
			quit(5)
			return
		rows.append({"id": id, "file": id + ".png", "width": picture.get_width(), "height": picture.get_height(), "sha256": FileAccess.get_sha256(destination)})
	var report: Dictionary = {"source_only": true, "display": DisplayServer.get_name(), "physical_iphone": false, "performance_test": false, "captures": rows}
	FileAccess.open(output_dir.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("RECOVERY_CAPTURE_OK count=", rows.size())
	quit(0 if rows.size() >= 20 else 6)
