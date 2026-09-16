extends SceneTree
## A reversible diagnostic of the same captured scene, never release settings.
var output: String
var area: String = "deep"
var main: Node
var world: Node
var lights: Array[Dictionary] = []
var process_nodes: Array[Dictionary] = []
var results: Array[Dictionary] = []
var field: Node
var fixed_enabled: bool = false
var last_capture_size: Vector2i

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output=argument.trim_prefix("--output=")
		elif argument.begins_with("--area="): area=argument.trim_prefix("--area=")
	if output.is_empty() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for frame in 5: await process_frame
	root.get_node("RunState").initialize_persistence(output.path_join("isolated-save.json"))
	root.get_node("RunState").reset_run(false)
	root.get_node("RunState").world_seed=4608
	seed(4608)
	if area=="deep": main._dev_jump_endless(12)
	elif area=="hub":
		main._dev_seed_victory_state()
		main._dev_build_all_workshops_state()
		main._dev_jump_hub()
	else: main._dev_jump_mine("emberMine",2)
	world=main.endless_world if area=="deep" else main.hub_world if area=="hub" else main.depth_world
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	await create_timer(4.0).timeout
	RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(),true)
	field=world.get_node_or_null("StaticLightField")
	if field!=null and field._floor_material!=null:
		fixed_enabled=bool(field._floor_material.get_shader_parameter("fixed_enabled"))
	for node in world.find_children("*","PointLight2D",true,false):
		lights.append({"node":node,"visible":node.visible,"shadow":node.shadow_enabled})
	await _review()
	var occluders: Node = world.get_node_or_null("CaveLightOccluders")
	var refresh_mean_us: float = 0.0
	if occluders != null:
		var start_us: int = Time.get_ticks_usec()
		for sample in 500: occluders.refresh()
		refresh_mean_us = float(Time.get_ticks_usec() - start_us) / 500.0
	var report: Dictionary={"area":area,"seed":root.get_node("RunState").world_seed,"terrain_hash":hash(world.floor_cells) if area=="deep" else 0 if area=="hub" else hash(world.terrain_hp),"player":str(world.player.position),"camera":str(world.player.camera.get_screen_center_position()),"renderer":RenderingServer.get_video_adapter_name(),"physical_iphone":false,"light_count":lights.size(),"stages":results}
	report["occlusion_refresh_mean_us"] = refresh_mean_us
	report["window_pixels"] = [root.size.x, root.size.y]
	report["framebuffer_size"] = [last_capture_size.x, last_capture_size.y]
	FileAccess.open(output.path_join("render-profile.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PREMIUM_RENDER_PROFILE_COMPLETE "+JSON.stringify(report))
	quit()

func _review() -> void:
	await _measure("live_idle")
	_freeze(world)
	await _measure("frozen_scripts")
	for entry in lights: entry.node.shadow_enabled=false
	await _measure("frozen_no_shadows")
	for entry in lights: entry.node.visible=false
	if field!=null and field._floor_material!=null: field._floor_material.set_shader_parameter("fixed_enabled",false)
	await _measure("frozen_no_lights")
	for entry in lights:
		entry.node.visible=entry.visible
		entry.node.shadow_enabled=entry.shadow
	if field!=null and field._floor_material!=null: field._floor_material.set_shader_parameter("fixed_enabled",fixed_enabled)
	await _measure("frozen_restored")
	for entry in process_nodes:
		entry.node.set_process(entry.process)
		entry.node.set_physics_process(entry.physics)
	await _measure("live_restored")

func _freeze(node: Node) -> void:
	process_nodes.append({"node":node,"process":node.is_processing(),"physics":node.is_physics_processing()})
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _measure(id: String) -> void:
	await create_timer(1.0).timeout
	var frames: Array[float]=[]
	var draws: Array[float]=[]
	var cpu: Array[float]=[]
	var gpu: Array[float]=[]
	var started: int=Time.get_ticks_usec()
	var previous: int=started
	while Time.get_ticks_usec()-started<8000000:
		await process_frame
		var now: int=Time.get_ticks_usec()
		frames.append(float(now-previous)/1000.0)
		draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid())+RenderingServer.get_frame_setup_time_cpu())
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()))
		previous=now
	var total: float=0.0
	for value in frames: total+=value
	frames.sort(); draws.sort(); cpu.sort(); gpu.sort()
	var row: Dictionary={"stage":id,"fps":1000.0*frames.size()/total,"p95_ms":frames[mini(frames.size()-1,floori(frames.size()*.95))],"draws":draws[draws.size()/2],"render_cpu_median_ms":cpu[cpu.size()/2],"render_gpu_median_ms":gpu[gpu.size()/2],"gpu_timing_supported":gpu[gpu.size()/2]>0.0,"fixed_field":field.debug_snapshot() if field!=null else {}}
	results.append(row)
	row["terrain_cache"] = world.lit_draw_sections.debug_snapshot() if world.lit_draw_sections.has_method("debug_snapshot") else {}
	print("PREMIUM_RENDER_STAGE "+JSON.stringify(row))
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	last_capture_size = picture.get_size()
	picture.save_png(output.path_join(id+".png"))
