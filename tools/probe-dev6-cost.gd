extends SceneTree
## Diagnose the published DEV6 package without modifying or rebuilding it.
var output_dir := ""
var area := "hub"
var world: Node2D
var stage := "original"
var light_state: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("DEV6_COST_FAIL " + message)
		quit(2)
	return ok

func apply_masks() -> void:
	if not is_instance_valid(world): return
	for child in world.lit_floor_chunks.get_children():
		child.light_mask = 0 if stage == "floor_unlit" else world.light_mask
	for child in world.lit_draw_sections.get_children():
		child.light_mask = 0 if stage == "sections_unlit" else world.light_mask

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=", 1)
		if arg.begins_with("--area="): area = arg.get_slice("=", 1)
	if not check(not output_dir.is_empty() and OS.has_feature("ever_deeper_dev") and DisplayServer.get_name() != "headless", "Rendered DEV package required"): return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-dev6-cost-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	if not check(main._dev_build_all_workshops_state(), "Workshops"): return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = state.workshop_status(workshop).next_upgrade
			state.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not check(bool(state.upgrade_workshop(workshop).get("ok", false)), "Upgrade"): return
	state.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if not check(main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine", 2), "Enter area"): return
	world = main.hub_world if area == "hub" else main.depth_world
	if area == "hub": world.restore_position(Vector2(1200, 480))
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	for frame in 5: await process_frame
	for node in world.find_children("*", "PointLight2D", true, false):
		var path: String = str(world.get_path_to(node))
		light_state.append({"node":node,"enabled":node.enabled,"world":not (path.begins_with("Player/") or "MoleCompanion" in path),"path":path})
	RenderingServer.frame_pre_draw.connect(apply_masks)
	var meter: RefCounted = load("res://scripts/qa/suites/light_cost.gd").new(main, output_dir)
	for id in ["original", "floor_unlit", "sections_unlit", "world_lights_off", "actor_lights_off", "all_off", "chunks_64", "chunks_128", "chunks_512", "restored"]:
		stage = id
		world.lit_floor_chunks.chunk_size = int(id.trim_prefix("chunks_")) if id.begins_with("chunks_") else 256
		for entry in light_state:
			entry.node.enabled = entry.enabled and id != "all_off" and not (id == "world_lights_off" and entry.world) and not (id == "actor_lights_off" and not entry.world)
		world.queue_redraw()
		apply_masks()
		await meter.measure(id, 45.0 if id == "original" else 16.0)
		if id.begins_with("chunks_") or id == "restored":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output_dir.path_join(id + ".png"))
	var report := {"package_version":"0.46.9-dev.6", "area":area, "physical_iphone":false,"stages":meter.rows,"floor_chunks":world.lit_floor_chunks.get_child_count(),"sections":world.lit_draw_sections.get_child_count(),"restored":true}
	for entry in light_state:
		if not check(entry.node.enabled == entry.enabled, "Lights restored"): return
	FileAccess.open(output_dir.path_join("dev6-cost.json"), FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("DEV6_COST_OK " + JSON.stringify(report))
	quit(0)
