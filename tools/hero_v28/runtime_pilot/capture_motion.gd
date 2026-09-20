extends SceneTree
## Actual controls and world clock, isolated native Worn visual, fixed-step capture.
var output := ""
var candidate := ""
var tasks := ""
var baseline := false
var interactive := false
var playing := false
var trial_hint: Label
var trial_panel: PanelContainer
var trial_contact_key := ""
var trial_contact_result := false
var trial_frames := 0
var trial_resets := 0
var trial_reset_button: Button
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
var contacts: Array = []
var last_impact := 0
class PoseDriver extends Node:
	var callback: Callable
	func _process(delta: float) -> void: callback.call(delta)
func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--candidate="): candidate = arg.trim_prefix("--candidate=")
		if arg.begins_with("--tasks="): tasks = arg.trim_prefix("--tasks=")
		if arg == "--baseline": baseline = true
		if arg == "--interactive": interactive = true
	if interactive:
		output = "user://native-flow-trial"
		candidate = "res://assets/native-flow-trial"
		tasks = candidate.path_join("tasks.json")
		print("NATIVE_TRIAL_LOADING world")
	assert((output.is_absolute_path() or output.begins_with("user://")) and DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(output)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	if interactive: main.get_node("EndlessDescentWorld").set_script(load(get_script().resource_path.get_base_dir().path_join("trial_world.gd")))
	root.add_child(main)
	current_scene = main
	for i in 5: await process_frame
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(1):
		push_error("Cannot enter native trial world")
		quit(3)
		return
	world = main.endless_world
	player = world.player
	state.pickaxe_level = 1
	state.drill_level = 0
	state.starforge_variant = ""
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	# The actual Forge owner requires the relic placed in the hub. Merely
	# attaching the carried relic does not activate workshop effects.
	state.endless_relics["forge_heart"]["placed"] = true
	state.endless_workshops["tool_forge"] = {"built":true,"level":5}
	if not is_equal_approx(world._mining_cycle_duration(),.425):
		push_error("Fixture did not activate the actual0.425s Forge5 clock")
		quit(3)
		return
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
	var surface_by_texture: Dictionary = {}
	if interactive: print("NATIVE_TRIAL_LOADING contacts")
	for resource in world.resources:
		var resource_node: Node2D = world.resource_visuals.get(String(resource.id))
		if resource_node == null: continue
		var sprite: Sprite2D = resource_node.get_node("PremiumNode")
		var surface_key := str(sprite.texture.get_rid())+str(sprite.scale)+str(sprite.position)
		if not surface_by_texture.has(surface_key):
			surface_by_texture[surface_key] = load(get_script().resource_path.get_base_dir().path_join("contact_surface.gd")).points(sprite)
		surfaces[str(Vector2(resource.position))] = surface_by_texture[surface_key]
	for i in 180:
		await RenderingServer.frame_post_draw
		if player.visual.active_gear == "worn" and i > 15: break
	assert(player.visual.active_gear == "worn")
	if not baseline:
		if interactive: print("NATIVE_TRIAL_LOADING model")
		rig = load(get_script().resource_path.get_base_dir().path_join("native_rig.gd")).new()
		rig.material_view = "baked_response"
		rig.lighting_profile = "native_key_shadow"
		rig.raster_size = 400
		player.visual.add_child(rig)
		if not rig.configure(candidate):
			push_error("Native trial assets failed identity/loading checks")
			quit(3)
			return
		motion = load(get_script().resource_path.get_base_dir().path_join("task_motion.gd")).new()
		if not motion.configure(rig,tasks,candidate.path_join("motion.json")):
			push_error("Native trial motion source did not match")
			quit(3)
			return
		player.visual._sprite.hide()
		player.visual.set_process(false)
	# Run after the world's authoritative mining update, before Skeleton3D's
	# deferred skin upload. frame_pre_draw is already too late for that upload.
	var driver := PoseDriver.new()
	driver.process_priority = 1000
	driver.callback = _pose_frame
	root.add_child(driver)
	if interactive:
		_start_trial()
		return
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
	var reference_frames: Array = []
	if not baseline:
		for contact in contacts:
			rig.root_native = contact.root_native
			rig.shown = contact.bones
			rig._apply(contact.bones)
			for settle in 3: await process_frame
			await RenderingServer.frame_post_draw
			rig.viewport.get_texture().get_image().save_png(output.path_join("contact-reference-%04d.png" % int(contact.frame)))
			reference_frames.append(contact.frame)
	var hashes: Dictionary = {}
	for path in ["tools/hero_v28/runtime_pilot/task_motion.gd","tools/hero_v28/runtime_pilot/capture_motion.gd","tools/hero_v28/runtime_pilot/contact_surface.gd","scripts/player/player_controller.gd","scripts/world/endless_descent_world.gd"]:
		hashes[path] = FileAccess.get_sha256("res://"+path)
	var report := {"complete":not failed,"samples":samples,"baseline":baseline,"cycle":world._mining_cycle_duration(),
		"source_sha256":hashes,"engine":Engine.get_version_info().string,"visual_accepted":false,"production_accepted":false,"contact_reference_frames":reference_frames,
		"fixtures":"Real seed4608 world; two existing ore positions moved to +/-64px and HP500; Forge5 with placed relic",
		"native_source":FileAccess.get_sha256(candidate.path_join("motion.json")),"tasks_sha256":FileAccess.get_sha256(tasks)}
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("NATIVE_TASK_GAME_COMPLETE ",not failed," frames ",samples.size())
	quit(3 if failed else 0)

func _surface(target: Vector2,position: Vector2) -> Array:
	var points: Array = []
	for point in surfaces.get(str(target),[]): points.append(target-position+Vector2(point))
	return points

func _pose_frame(delta: float) -> void:
	if (not recording and not playing) or failed: return
	var packet: Dictionary = player.animation_packet()
	packet.contact_surfaces = _surface(packet.target_position,packet.world_position)
	packet.impact_surfaces = _surface(packet.impact_target_position,packet.world_position)
	if not baseline and not motion.advance(delta if playing else 1.0/60.0,packet): failed = true
	if playing:
		trial_panel.visible = not main.orientation_guard_active
		if failed:
			main._set_mine_held(false)
			trial_hint.text = "Bevegelsen stoppet. Trykk Start på nytt."
		trial_frames += 1
		if OS.has_feature("web") and (trial_frames % 15 == 0 or failed):
			var report := {"ready":true,"failed":failed,"frames":trial_frames,"resets":trial_resets,
				"position":[player.global_position.x,player.global_position.y],"mining":world.mining_active,
				"hp17":world.resources[17].hp,"hp18":world.resources[18].hp,"impact_serial":packet.impact_serial,
				"hint":trial_hint.text,"errors":motion.errors,"viewport":[root.get_visible_rect().size.x,root.get_visible_rect().size.y],
				"mine_button":[main.mine_button.get_global_rect().get_center().x,main.mine_button.get_global_rect().get_center().y],
				"reset_button":[trial_reset_button.get_global_rect().get_center().x,trial_reset_button.get_global_rect().get_center().y],
				"pad":[main.movement_pad.get_global_rect().get_center().x,main.movement_pad.get_global_rect().get_center().y]}
			JavaScriptBridge.eval("window.EVER_DEEPER_TRIAL="+JSON.stringify(report),true)
		return
	if not baseline and int(packet.impact_serial) != last_impact:
		contacts.append({"frame":frame_id,"root_native":rig.root_native,"bones":rig.shown.duplicate(true)})
	last_impact = int(packet.impact_serial)
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
		"screen_transform":[root.get_final_transform().x.x,root.get_final_transform().y.y,root.get_final_transform().origin.x,root.get_final_transform().origin.y],
		"detail":{} if baseline else motion.snapshot(),"bones":bones})

func _start_trial() -> void:
	playing = true
	world.trial_contact_allowed = _trial_contact
	main.achievement_toast.clear()
	main.achievement_toast.hide()
	main.premium_hud.hide()
	main.guide_overlay.hide()
	main.quick_tutorial.dismiss()
	main.set_process_unhandled_input(false)
	InputMap.action_erase_events("interact")
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	var panel := PanelContainer.new()
	trial_panel = panel
	panel.position = Vector2(20,16)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	panel.add_child(row)
	var copy := VBoxContainer.new()
	row.add_child(copy)
	var title := Label.new()
	title.text = "Ever-Deeper · Worn-hakketest"
	title.add_theme_font_size_override("font_size",22)
	copy.add_child(title)
	trial_hint = Label.new()
	trial_hint.text = "Beveg deg, snu og hold HUGG ved malmen."
	trial_hint.add_theme_font_size_override("font_size",16)
	copy.add_child(trial_hint)
	var reset := Button.new()
	trial_reset_button = reset
	reset.text = "Start på nytt"
	reset.custom_minimum_size = Vector2(150,64)
	reset.pressed.connect(_reset_trial)
	row.add_child(reset)
	var exit_button := Button.new()
	exit_button.text = "Til spillet"
	exit_button.custom_minimum_size = Vector2(130,64)
	exit_button.pressed.connect(func(): OS.shell_open("https://corpax88.github.io/Ever-Deeper/dev/"))
	row.add_child(exit_button)
	print("NATIVE_FLOW_TRIAL_READY cycle=",world._mining_cycle_duration())

func _trial_contact(resource: Dictionary) -> bool:
	if not playing or motion == null: return false
	var target := Vector2(resource.position)
	var key := str(target)+str(player.global_position)
	if key == trial_contact_key: return trial_contact_result
	var points := _surface(target,player.global_position)
	if points.is_empty(): return false
	var old_tool: Transform3D = motion.contact_tool
	var old_yaw: float = motion.contact_yaw
	var old_screen: Vector2 = motion.contact_screen
	var allowed: bool = motion.plan_contact(target-player.global_position,points,false)
	motion.contact_tool = old_tool
	motion.contact_yaw = old_yaw
	motion.contact_screen = old_screen
	trial_contact_key = key
	trial_contact_result = allowed
	trial_hint.text = "Beveg deg, snu og hold HUGG ved malmen." if allowed else "Gå litt nærmere malmen for å treffe."
	return allowed

func _reset_trial() -> void:
	main._set_mine_held(false)
	main._on_joystick_movement(Vector2.ZERO)
	world._cancel_mining()
	world.restore_position(Vector2(1696,1648))
	player.set_facing(Vector2.UP)
	var state: Node = root.get_node("RunState")
	for index in [17,18]:
		world.resources[index].hp = 500
		world.resources[index].mined = false
		var resource: Dictionary = world.resources[index]
		var chunk: Dictionary = state.endless_chunks.get(str(resource.depth),{})
		chunk.nodes = int(chunk.get("nodes",0)) & ~(1 << int(resource.node_index))
		state.endless_chunks[str(resource.depth)] = chunk
		world.session_mined_nodes.erase(String(resource.id))
		if not is_instance_valid(world.resource_visuals.get(String(resource.id))):
			world._build_resource_visual(resource)
	motion = load(get_script().resource_path.get_base_dir().path_join("task_motion.gd")).new()
	if not motion.configure(rig,tasks,candidate.path_join("motion.json")):
		failed = true
		trial_hint.text = "Omstart mislyktes. Last siden på nytt."
		return
	failed = false
	trial_resets += 1
	trial_contact_key = ""
	trial_hint.text = "Beveg deg, snu og hold HUGG ved malmen."
