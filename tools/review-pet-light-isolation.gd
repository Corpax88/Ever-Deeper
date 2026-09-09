extends SceneTree
## Diagnostic only: unchanged published DEV9 package, reversible light isolation.
var output_dir := ""
var main: Node
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=",1)
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	if not main._dev_build_all_workshops_state():
		quit(2); return
	var cases: Array[Dictionary] = []
	for area in ["hub","mossvein"]:
		if not (main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine",2)):
			quit(2); return
		var world: Node = main.hub_world if area == "hub" else main.depth_world
		var field: Node = world.static_light_field
		for frame in 120:
			await process_frame
			if field.ready_for_use and not field.baking and not field._scheduled: break
		if not field.ready_for_use:
			push_error("Field not ready"); quit(2); return
		for frame in 8: await process_frame
		var pet: Node = world.find_child("MoleCompanion",true,false)
		if pet == null:
			push_error("Missing pet"); quit(2); return
		var lamps: Array[Dictionary] = []
		for light in pet.find_children("*","PointLight2D",true,false):
			lamps.append({"node":light,"enabled":light.enabled,"shadow":light.shadow_enabled})
		if lamps.size() != 2:
			push_error("Expected pet cone and bounce"); quit(2); return
		world.set_meta(&"fixed_light_probe_lock",true)
		for stage in ["original","cone_off","restore_cone","bounce_off","restore_bounce","pet_off","restored"]:
			for entry in lamps:
				entry.node.enabled = entry.enabled
				if stage == "pet_off" or (stage == "cone_off" and entry.node.name == "HelmetCone") or (stage == "bounce_off" and entry.node.name == "HelmetBounce"):
					entry.node.enabled = false
			for frame in 8: await process_frame
			var values: Array[float] = []
			var previous: int = Time.get_ticks_usec()
			var begin: int = previous
			while Time.get_ticks_usec() - begin < 8000000:
				await process_frame
				var now: int = Time.get_ticks_usec()
				values.append(float(now - previous) / 1000.0)
				previous = now
			var total: float = 0.0
			for value in values: total += value
			values.sort()
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output_dir.path_join(area+"-"+stage+".png"))
			var lights: Array[Dictionary] = []
			for entry in lamps:
				var light: PointLight2D = entry.node
				lights.append({"name":light.name,"enabled":light.enabled,"energy":light.energy,"scale":light.texture_scale,"texture_size":light.texture.get_size(),"position":light.global_position,"rotation":light.global_rotation,"mask":light.range_item_cull_mask,"shadow":light.shadow_enabled})
			var row: Dictionary = {"area":area,"stage":stage,"fps":values.size()*1000.0/total,"p95_ms":values[clampi(ceili(values.size()*0.95)-1,0,values.size()-1)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"cpu_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"lights":lights}
			cases.append(row)
			print("PET_LIGHT_ROW "+JSON.stringify(row))
		for entry in lamps:
			if entry.node.enabled != entry.enabled or entry.node.shadow_enabled != entry.shadow:
				push_error("Restoration failed"); quit(2); return
		world.remove_meta(&"fixed_light_probe_lock")
	FileAccess.open(output_dir.path_join("pet-light-isolation.json"),FileAccess.WRITE).store_string(JSON.stringify({"physical_iphone":false,"renderer":"Mesa software","package_sha256":"78fde726ddc232060827c2500460a81224c90476b63922ee73c6f4d6cbb927f2","cases":cases},"\t"))
	print("PET_LIGHT_ISOLATION_OK")
	quit(0)
