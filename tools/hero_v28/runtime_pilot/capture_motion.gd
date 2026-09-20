extends SceneTree
## Actual controls and world clock, isolated native Worn visual, fixed-step capture.
var output := ""
var candidate := ""
var tasks := ""
var baseline := false
var main: Node
var world: Node
var player: Node
var rig: Node
var motion: RefCounted
var surfaces: Dictionary = {}
var samples: Array = []
var failed := false
var recording := false
var start_tick := 0
var frame_id := -1
var event := ""
func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--candidate="): candidate = arg.trim_prefix("--candidate=")
		if arg.begins_with("--tasks="): tasks = arg.trim_prefix("--tasks=")
		if arg == "--baseline": baseline = true
	assert(output.is_absolute_path() and DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(output)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	assert(main._dev_jump_endless(1))
	world = main.endless_world
	player = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	state.discover_endless_relic("forge_heart",1)
	state.collect_endless_relic("forge_heart",1)
	state.attach_carried_relic("forge_heart")
	state.endless_workshops["tool_forge"] = {"built":true,"level":5}
	assert(is_equal_approx(world._mining_cycle_duration(),.425))
	player.prepare_visual_cache()
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	world.restore_position(Vector2(1696,1648))
	player.set_facing(Vector2.UP)
	player.control_enabled = true
	player.visual.flow_graph_enabled = false
	main.quick_tutorial.dismiss()
	for index in [17,18]:
		world.resources[index].position = player.global_position+Vector2(0,-64 if index == 17 else 64)
		world.resources[index].hp = 500
		var resource_node: Node2D = world.resource_visuals[String(world.resources[index].id)]
		resource_node.position = world.resources[index].position
		resource_node.z_index = world.actor_draw_depth(resource_node.position+Vector2(0,25))
	for resource in world.resources:
		var resource_node: Node2D = world.resource_visuals.get(String(resource.id))
		if resource_node == null: continue
		var sprite: Sprite2D = resource_node.get_node("PremiumNode")
		surfaces[str(Vector2(resource.position))] = load("res://tools/hero_v28/runtime_pilot/contact_surface.gd").points(sprite)
	for i in 180:
		await RenderingServer.frame_post_draw
		if player.visual.active_gear == "worn" and i > 15: break
	assert(player.visual.active_gear == "worn")
	if not baseline:
		rig = load("res://tools/hero_v28/runtime_pilot/native_rig.gd").new()
		rig.material_view = "baked_response"
		rig.lighting_profile = "native_key_shadow"
		rig.raster_size = 400
		player.visual.add_child(rig)
		assert(rig.configure(candidate))
		motion = load("res://tools/hero_v28/runtime_pilot/task_motion.gd").new()
		assert(motion.configure(rig,tasks,candidate.path_join("motion.json")))
		player.visual._sprite.hide()
		player.visual.set_process(false)
	RenderingServer.frame_pre_draw.connect(_pose_frame)
	start_tick = Engine.get_physics_frames()
	recording = true
	var events := {12:"start_up",45:"reverse_down",72:"walk_left",78:"idle",82:"start_up",110:"release"}
	for i in 120:
		frame_id = i
		event = events.get(i,"")
		if event in ["start_up","reverse_down"]:
			player.set_facing(Vector2.UP if event == "start_up" else Vector2.DOWN)
			main._set_mine_held(true)
		if event == "walk_left": main._on_joystick_movement(Vector2.LEFT)
		if event in ["idle","release"]:
			main._on_joystick_movement(Vector2.ZERO)
			main._set_mine_held(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("frame-%04d.png" % i))
		if not baseline: rig.viewport.get_texture().get_image().save_png(output.path_join("hero-%04d.png" % i))
		if failed: break
	recording = false
	main._set_mine_held(false)
	var hashes: Dictionary = {}
	for path in ["tools/hero_v28/runtime_pilot/task_motion.gd","tools/hero_v28/runtime_pilot/capture_motion.gd","tools/hero_v28/runtime_pilot/contact_surface.gd","scripts/player/player_controller.gd","scripts/world/endless_descent_world.gd"]:
		hashes[path] = FileAccess.get_sha256("res://"+path)
	var report := {"complete":not failed,"samples":samples,"baseline":baseline,"cycle":world._mining_cycle_duration(),
		"source_sha256":hashes,"engine":Engine.get_version_info().string,"visual_accepted":false,"production_accepted":false,
		"fixtures":"Real seed4608 world; two existing ore positions moved to +/-64px and HP500; Forge5 with attached relic",
		"native_source":FileAccess.get_sha256(candidate.path_join("motion.json")),"tasks_sha256":FileAccess.get_sha256(tasks)}
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("NATIVE_TASK_GAME_COMPLETE ",not failed," frames ",samples.size())
	quit(3 if failed else 0)

func _surface(target: Vector2,position: Vector2) -> Array:
	var points: Array = []
	for point in surfaces.get(str(target),[]): points.append(target-position+Vector2(point))
	return points

func _pose_frame() -> void:
	if not recording or failed: return
	var packet: Dictionary = player.animation_packet()
	packet.contact_surfaces = _surface(packet.target_position,packet.world_position)
	packet.impact_surfaces = _surface(packet.impact_target_position,packet.world_position)
	if not baseline and not motion.advance(1.0/60.0,packet): failed = true
	var bones: Dictionary = {}
	if not baseline:
		for name in rig.shown:
			var t: Transform3D = rig.shown[name]
			bones[name] = {"position":[t.origin.x,t.origin.y,t.origin.z],"quaternion":[t.basis.get_rotation_quaternion().x,t.basis.get_rotation_quaternion().y,t.basis.get_rotation_quaternion().z,t.basis.get_rotation_quaternion().w]}
	samples.append({"frame":frame_id,"event":event,"seconds":float(Engine.get_physics_frames()-start_tick)/60.,
		"position":[player.global_position.x,player.global_position.y],"moving":player.is_actually_moving(),
		"target":world.mining_target_id,"hp17":int(world.resources[17].hp),"hp18":int(world.resources[18].hp),
		"impact_serial":packet.impact_serial,"swing_serial":packet.swing_serial,"progress":packet.progress,"active":packet.mining,
		"screen_position":[player.get_global_transform_with_canvas().origin.x,player.get_global_transform_with_canvas().origin.y],
		"detail":{} if baseline else motion.snapshot(),"bones":bones})
