extends SceneTree
var output := ""
var candidate := ""
var tasks := ""
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--candidate="): candidate = arg.trim_prefix("--candidate=")
		if arg.begins_with("--tasks="): tasks = arg.trim_prefix("--tasks=")
	var rig = load("res://tools/hero_v28/runtime_pilot/native_rig.gd").new()
	root.add_child(rig)
	assert(rig.configure(candidate,true))
	var motion = load("res://tools/hero_v28/runtime_pilot/task_motion.gd").new()
	assert(motion.configure(rig,tasks,candidate.path_join("motion.json")))
	var poses: Array = []
	var worst := 0.0
	for cell in 50:
		var sample: Dictionary = motion.sample("mine",float(cell)/50.)
		for name in sample.bones:
			var actual: Transform3D = sample.bones[name]
			var expected: Transform3D = rig.curves.mine[cell].bones[name]
			worst = maxf(worst,actual.origin.distance_to(expected.origin))
			for column in 3: worst = maxf(worst,actual.basis[column].distance_to(expected.basis[column]))
	var exact_reference: Vector2 = motion.project(motion.reference_cap)
	assert(worst < .000001)
	var sprite := Sprite2D.new()
	sprite.texture = load("res://assets/endless/node-lumen-shard-v1.png")
	sprite.position = Vector2(0,-3)
	sprite.scale = Vector2.ONE*96.0/maxf(sprite.texture.get_width(),sprite.texture.get_height())
	var interior: Array[Vector2] = load("res://tools/hero_v28/runtime_pilot/contact_surface.gd").points(sprite)
	sprite.free()
	for bearing in [Vector2.UP,Vector2(1,-1).normalized(),Vector2.RIGHT,Vector2(1,1).normalized(),Vector2.DOWN,Vector2(-1,1).normalized(),Vector2.LEFT,Vector2(-1,-1).normalized()]:
		var target: Vector2 = bearing*64.0
		var surface: Array = []
		for point in interior: surface.append(target+point)
		var reachable: bool = motion.plan_contact(target,surface)
		var error := -1.0
		var reach_before: float = motion.max_reach_error
		if reachable:
			for cell in 101:
				var pose: Dictionary = motion.aimed(float(cell)/101.)
				if cell == 0: poses.append({"bearing":bearing,"pose0_tool":pose.bones.tool.origin})
			var contact: Dictionary = motion.aimed(.42)
			error = motion.project(contact.bones.tool*motion.cap_local).distance_to(motion.contact_screen)
		poses.append({"bearing":[bearing.x,bearing.y],"reachable":reachable,"contact_error_px":error,
			"new_max_reach_error":motion.max_reach_error,"prior_max":reach_before,"yaw":motion.contact_yaw})
	var report := {"complete":true,"exact_matrix_error":worst,"reference_contact_screen":[exact_reference.x,exact_reference.y],
		"poses":poses,"errors":motion.errors,"max_reach_error":motion.max_reach_error,
		"source_sha256":FileAccess.get_sha256("res://tools/hero_v28/runtime_pilot/task_motion.gd"),
		"tasks_sha256":FileAccess.get_sha256(tasks),"visual_accepted":false,"production_accepted":false}
	var sequence: Array = []
	var packet := {"world_position":Vector2.ZERO,"travelled_distance":0.0,"physics_tick":0,
		"moving":false,"mining":false,"mining_timing_valid":false,"bearing":Vector2.UP,
		"swing_serial":0,"swing_continuation":false,"target_position":Vector2(0,-64),
		"progress":0.0,"cycle_duration":.425,"hit_phase":.42,"impact_serial":0,
		"impact_target_valid":false,"impact_target_position":Vector2.ZERO}
	var elapsed := 0.0
	var hit := false
	for frame in 145:
		var event := ""
		if frame in [15,74,85]:
			event = "mine"
			packet.moving = false
			packet.mining = true
			packet.mining_timing_valid = true
			packet.bearing = Vector2.UP if frame == 15 else Vector2.DOWN if frame == 74 else Vector2.LEFT
			packet.target_position = packet.world_position+packet.bearing*64
			packet.swing_serial += 1
			packet.swing_continuation = false
			elapsed = 0.0
			hit = false
		if frame in [70,110]:
			event = "walk"
			packet.moving = true
			packet.mining = false
			packet.bearing = Vector2.UP if frame == 70 else Vector2.LEFT
		if frame in [84,125]:
			event = "idle"
			packet.moving = false
			packet.mining = false
		if packet.mining:
			elapsed += 1.0/60.0
			if elapsed >= .425:
				elapsed -= .425
				packet.swing_serial += 1
				packet.swing_continuation = true
				hit = false
			packet.progress = elapsed/.425
			if packet.progress >= .42 and not hit:
				hit = true
				packet.impact_serial += 1
				packet.impact_target_valid = true
				packet.impact_target_position = packet.target_position
		if packet.moving:
			packet.world_position += packet.bearing*(340./60.)
			packet.travelled_distance += 340./60.
		packet.physics_tick = frame
		packet.contact_surfaces = []
		packet.impact_surfaces = []
		for point in interior:
			packet.contact_surfaces.append(packet.target_position-packet.world_position+point)
			packet.impact_surfaces.append(packet.impact_target_position-packet.world_position+point)
		var valid: bool = motion.advance(1./60.,packet)
		sequence.append({"frame":frame,"event":event,"valid":valid,"detail":motion.snapshot()})
	report.sequence = sequence
	report.sequence_valid = sequence.all(func(row): return row.valid)
	report.max_reach_error = motion.max_reach_error
	var prior_display: Dictionary = rig.shown.duplicate(true)
	packet.mining = true
	packet.mining_timing_valid = true
	packet.moving = false
	packet.swing_serial += 1
	packet.swing_continuation = false
	packet.target_position = Vector2(10000,10000)
	packet.contact_surfaces = []
	var rejected: bool = not motion.advance(1./60.,packet)
	report.unreachable_contact_rejected_before_display = rejected and rig.shown == prior_display
	DirAccess.make_dir_recursive_absolute(output)
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("NATIVE_TASK_MOTION_CHECK_COMPLETE ",worst," ",motion.max_reach_error)
	quit()
