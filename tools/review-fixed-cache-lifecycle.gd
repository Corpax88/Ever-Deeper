extends SceneTree
## Inspect lifecycle and memory using an unchanged exported PCK.
var output_dir := ""
var main: Node
var report: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, message: String) -> bool:
	if not ok:
		push_error("FIXED_CACHE_LIFECYCLE_FAIL " + message)
		quit(2)
	return ok

func memory() -> Dictionary:
	return {"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"texture_mib":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0}

func settle(field: Node) -> bool:
	for frame in 120:
		if not field._scheduled and not field.baking and not field._waiting_for_probe:
			for draw in 3: await process_frame
			await RenderingServer.frame_post_draw
			return true
		await process_frame
	return check(false, "Timed out waiting for field")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-cache-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	if not check(main._dev_build_all_workshops_state(), "Mature hub fixture"): return
	for area in ["hub","mossvein"]:
		if not check(main._dev_jump_hub() if area == "hub" else main._dev_jump_mine("mossMine",2), "Enter area"): return
		var world: Node = main.hub_world if area == "hub" else main.depth_world
		var field: Node = world.static_light_field
		world.set_meta(&"fixed_light_probe_lock",true)
		for frame in 6: await process_frame
		var before: Dictionary = memory()
		if not check(not field.ready_for_use and not field.baking and field._waiting_for_probe, "Probe lock retains originals before bake"): return
		var actor_masks: Array[Dictionary] = []
		for light in world.find_children("*","PointLight2D",true,false):
			if field._is_actor(light): actor_masks.append({"node":light,"mask":light.range_item_cull_mask,"shadow_mask":light.shadow_item_cull_mask})
		world.remove_meta(&"fixed_light_probe_lock")
		var begin := Time.get_ticks_usec()
		var peak: float = float(before.video_mib)
		for frame in 120:
			await process_frame
			peak = maxf(peak,float(memory().video_mib))
			if field.ready_for_use and not field.baking: break
		if not await settle(field): return
		var elapsed: float = float(Time.get_ticks_usec()-begin)/1000.0
		if not check(field.ready_for_use and field._applied and field.find_children("*","SubViewport",true,false).is_empty(), "Cache activates and temporary viewport is freed"): return
		var after: Dictionary = memory()
		peak = maxf(peak,float(after.video_mib))
		var snapshot: Dictionary = field.debug_snapshot()
		for source in field._sources:
			if not check(not source.node.enabled,"Original source replaced once"): return
		field.enabled = false
		for source in field._sources:
			if not check(source.node.enabled == source.enabled,"Disable restores source flags"): return
		for actor in actor_masks:
			if not check(actor.node.range_item_cull_mask == actor.mask and actor.node.shadow_item_cull_mask == actor.shadow_mask,"Disable restores actor masks"): return
		field.enabled = true
		if not check(field._applied,"Re-enable uses cache"): return
		# A newly unsupported shadow-casting source must use the original path.
		var source: Node = field._sources[0].node
		var source_root: Node = field._source_root
		source.shadow_enabled = true
		field.configure(world,source_root)
		if not await settle(field): return
		if not check(not field.ready_for_use and not field._applied,"Unsupported source falls back"): return
		if not check(source.enabled,"Fallback leaves the original visible"): return
		for actor in actor_masks:
			if not check(actor.node.range_item_cull_mask == actor.mask and actor.node.shadow_item_cull_mask == actor.shadow_mask,"Fallback restores actor masks"): return
		source.shadow_enabled = false
		field.configure(world,source_root)
		field.configure(world,source_root)
		if not await settle(field): return
		if not check(field.ready_for_use and field._applied and field.find_children("*","SubViewport",true,false).is_empty(),"Reconfigure coalesces and recovers"): return
		report.append({"area":area,"pre_bake":before,"active":after,"observed_peak_video_mib":peak,"settled_bake_and_upload_ms":elapsed,"cache":snapshot,"restored_cache":field.debug_snapshot(),"after_reconfigure":memory(),"lock_deferred":true,"temporary_viewport_freed":true,"disable_restores_originals_and_actor_masks":true,"unsupported_source_fallback":true,"reconfigure_recovers":true})
	FileAccess.open(output_dir.path_join("cache-lifecycle.json"),FileAccess.WRITE).store_string(JSON.stringify({"physical_iphone":false,"renderer":"Mesa software","cases":report},"\t"))
	print("FIXED_CACHE_LIFECYCLE_OK " + JSON.stringify(report))
	quit(0)
