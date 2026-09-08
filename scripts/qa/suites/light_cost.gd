extends RefCounted
## Isolated rendered ablations. No release behavior or save migration changes.
var main: Node
var output_dir: String
var area: String = "hub"
var world: Node2D
var lights: Array[Dictionary] = []
var original_mask: int
var rows: Array[Dictionary] = []

func _init(game: Node, output: String) -> void:
	main = game
	output_dir = output

func fail(message: String) -> void:
	push_error("LIGHT_COST_FAIL " + message)
	main.get_tree().quit(2)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--probe-area="): area = arg.get_slice("=", 1)
	if DisplayServer.get_name() == "headless":
		fail("Rendered check required"); return
	seed(4608)
	RunState.initialize_persistence(output_dir.path_join("isolated-light-cost-save.json"))
	RunState.reset_run(false)
	RunState.world_seed = 4608
	main.game_started = true
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state():
		fail("Workshops"); return
	for workshop in ["light_lab", "wardrobe"]:
		for level in 3:
			var upgrade: Dictionary = RunState.workshop_status(workshop).next_upgrade
			RunState.add_resource(String(upgrade.resource), int(upgrade.cost), false)
			if not bool(RunState.upgrade_workshop(workshop).get("ok", false)):
				fail("Upgrade"); return
	RunState.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if not (main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine", 2)):
		fail("Area"); return
	world = main.hub_world if area == "hub" else main.depth_world
	if area == "hub": world.restore_position(Vector2(1200, 480))
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	for frame in 5: await main.get_tree().process_frame
	original_mask = world.light_mask
	for node in world.find_children("*", "Light2D", true, false):
		var path: String = str(world.get_path_to(node))
		var group: String = "pet" if "MoleCompanion" in path else "hero" if path.begins_with("Player/") else "world"
		lights.append({"node":node,"enabled":node.enabled,"shadow":node.shadow_enabled,"path":path,"group":group})
	var inventory: Array[Dictionary] = []
	for entry in lights:
		var light: PointLight2D = entry.node
		inventory.append({"path":entry.path,"group":entry.group,"enabled":entry.enabled,"shadow":entry.shadow,"energy":light.energy,"color":str(light.color),"position":str(light.global_position),"texture_size":str(light.texture.get_size()),"texture_scale":light.texture_scale,"scale":str(light.global_scale),"item_mask":light.range_item_cull_mask})
	print("LIGHT_COST_INVENTORY " + JSON.stringify(inventory))
	await measure("original", 45.0)
	for id in ["all_off", "hero_only", "pet_only", "world_only", "hero_pet", "root_unlit", "restored"]:
		apply_stage(id)
		await measure(id, 8.0)
	for index in lights.size():
		apply_stage("all_off")
		lights[index].node.enabled = lights[index].enabled
		await measure("single_%02d" % index, 6.0)
	apply_stage("restored")
	await measure("final", 15.0)
	var report: Dictionary = {"area":area,"physical_iphone":false,"rendered":true,"viewport":str(main.get_viewport().get_visible_rect().size),"window":str(DisplayServer.window_get_size()),"renderer":RenderingServer.get_current_rendering_method(),"inventory":inventory,"stages":rows,"restored":world.light_mask == original_mask}
	for entry in lights:
		report.restored = report.restored and entry.node.enabled == entry.enabled and entry.node.shadow_enabled == entry.shadow
	FileAccess.open(output_dir.path_join("light-cost.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	if not report.restored:
		fail("Restoration"); return
	print("LIGHT_COST_COMPLETE " + JSON.stringify({"area":area,"stages":rows.size(),"restored":report.restored}))
	main.get_tree().quit(0)

func apply_stage(id: String) -> void:
	world.light_mask = 0 if id == "root_unlit" else original_mask
	for entry in lights:
		var enabled: bool = bool(entry.enabled)
		if id == "all_off": enabled = false
		elif id.ends_with("_only"): enabled = enabled and entry.group == id.trim_suffix("_only")
		elif id == "hero_pet": enabled = enabled and entry.group != "world"
		entry.node.enabled = enabled
		entry.node.shadow_enabled = entry.shadow

func measure(id: String, seconds: float) -> void:
	var begun: int = Time.get_ticks_usec()
	var previous: int = begun
	var samples: Array[float] = []
	var cpu: Array[float] = []
	var draws: Array[float] = []
	while Time.get_ticks_usec() - begun < int(seconds * 1000000.0):
		await main.get_tree().process_frame
		var now: int = Time.get_ticks_usec()
		if now - begun >= 2000000:
			samples.append(float(now - previous) / 1000.0)
			cpu.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		previous = now
	if samples.size() < 3:
		fail("Too few frames " + id); return
	var total: float = 0.0
	for value in samples: total += value
	samples.sort(); cpu.sort(); draws.sort()
	var row: Dictionary = {"stage":id,"seconds":float(Time.get_ticks_usec() - begun) / 1000000.0,"frames":samples.size(),"fps":samples.size() * 1000.0 / total,"p95_ms":samples[clampi(ceili(samples.size() * 0.95) - 1, 0, samples.size()-1)],"cpu_median_ms":cpu[cpu.size()/2],"draw_calls":draws[draws.size()/2],"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0}
	rows.append(row)
	print("LIGHT_COST_STAGE " + JSON.stringify(row))
	if id in ["original", "all_off", "hero_only", "world_only", "root_unlit", "final"]:
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(output_dir.path_join(id + ".png"))
