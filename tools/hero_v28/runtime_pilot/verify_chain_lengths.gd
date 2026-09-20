extends SceneTree
## Dense phase coverage for the browser-only native limb rejection.
var repo := ""
var candidate := ""
var tasks := ""
var output := ""
var worst := 0.0
var failures: Array = []
var checked := 0
func _initialize() -> void: _run.call_deferred()
func inspect(motion: RefCounted, pose: Dictionary, label: String, phase: float) -> void:
	for transform in pose.bones.values():
		if not Transform3D(transform).is_finite():
			failures.append({"case":label,"phase":phase,"error":"non-finite transform"})
			return
	for side in ["R","L"]:
		for family in ["arm","leg"]:
			var chain: Array = motion._chain(pose.bones,family,side)
			var lengths := Vector2(.36,.35) if family == "arm" else Vector2(.180,.184)
			for segment in 2:
				var error: float = absf(chain[segment].distance_to(chain[segment+1])-lengths[segment])
				if not is_finite(error):
					failures.append({"case":label,"phase":phase,"error":"non-finite length"})
					return
				worst = maxf(worst,error)
				if error > .0001 and failures.size() < 20:
					failures.append({"case":label,"phase":phase,"chain":family+side,"segment":segment,"error":error})
	checked += 1
func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--repo="): repo = arg.trim_prefix("--repo=")
		if arg.begins_with("--candidate="): candidate = arg.trim_prefix("--candidate=")
		if arg.begins_with("--tasks="): tasks = arg.trim_prefix("--tasks=")
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	var rig = load(repo.path_join("tools/hero_v28/runtime_pilot/native_rig.gd")).new()
	root.add_child(rig)
	assert(rig.configure(candidate,true))
	var motion = load(repo.path_join("tools/hero_v28/runtime_pilot/task_motion.gd")).new()
	assert(motion.configure(rig,tasks,candidate.path_join("motion.json")))
	var reference_error := 0.0
	for cell in 50:
		var pose: Dictionary = motion.sample("mine",float(cell)/50.)
		for name in pose.bones:
			var actual: Transform3D = pose.bones[name]
			var expected: Transform3D = rig.curves.mine[cell].bones[name]
			reference_error = maxf(reference_error,actual.origin.distance_to(expected.origin))
			for column in 3: reference_error = maxf(reference_error,actual.basis[column].distance_to(expected.basis[column]))
	for family in ["idle","walk","mine"]:
		for cell in 5001: inspect(motion,motion.sample(family,float(cell)/5001.),family,float(cell)/5001.)
	var sprite := Sprite2D.new()
	sprite.texture = ImageTexture.create_from_image(Image.load_from_file(repo.path_join("assets/endless/node-lumen-shard-v1.png")))
	sprite.position = Vector2(0,-3)
	sprite.scale = Vector2.ONE*96.0/maxf(sprite.texture.get_width(),sprite.texture.get_height())
	var interior: Array = load(repo.path_join("tools/hero_v28/runtime_pilot/contact_surface.gd")).points(sprite)
	sprite.free()
	for bearing in [Vector2.UP,Vector2.RIGHT,Vector2.DOWN,Vector2.LEFT]:
		var target: Vector2 = bearing*64.0
		var surface: Array = []
		for point in interior: surface.append(target+point)
		assert(motion.plan_contact(target,surface))
		for cell in 5001: inspect(motion,motion.aimed(float(cell)/5001.),"aimed "+str(bearing),float(cell)/5001.)
	var report := {"passed":failures.is_empty() and reference_error < .000001,"checked_poses":checked,"maximum_length_error":worst,"exact_reference_matrix_error":reference_error,"failures":failures,"source_sha256":FileAccess.get_sha256(repo.path_join("tools/hero_v28/runtime_pilot/task_motion.gd")),"physical_device":false}
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("CHAIN_LENGTH_CHECK ",JSON.stringify(report))
	quit(0 if report.passed else 1)
