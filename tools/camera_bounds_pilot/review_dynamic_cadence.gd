extends SceneTree
## Frozen, explicitly aged impacts; actual queued parent/section draw callbacks.
var output: String = ""
var main: Node
var world: Node
var rows: Array[Dictionary] = []
var pictures: Array[Image] = []
var failure: String = ""
const STEPS := ["age-only", "scheduled-with-camera", "append-before-camera", "append-after-camera", "expire-before-camera", "age-only-again", "grow-to-four", "fixed-size-eviction", "equal-value-replacement", "position-mutation", "fresh-cache-invalidation", "expire-after-camera", "expire-all", "empty-camera"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	var seal: Shader = load("res://shaders/lit_relic_seal.gdshader")
	seal.code = seal.code.replace("TIME", "0.0")
	main = load("res://scenes/main/main.tscn").instantiate()
	main.get_node("EndlessDescentWorld").set_script(load("res://tools/camera_bounds_pilot/candidate_dynamic.gd"))
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(12): failure="Cannot enter Deep"; _finish(); return
	world = main.endless_world
	await create_timer(4.0).timeout
	_freeze(root)
	main.achievement_toast.clear()
	main.quick_tutorial.dismiss()
	for tween in get_processed_tweens(): tween.pause()
	paused = true
	Engine.time_scale = 0.0
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.drag_horizontal_enabled = false
	world.player.camera.drag_vertical_enabled = false
	world.player.camera.limit_smoothed = false
	world.player.camera.limit_left = -1000000
	world.player.camera.limit_top = -1000000
	world.player.camera.limit_right = 1000000
	world.player.camera.limit_bottom = 1000000
	world.lit_draw_sections.profile_draws = true
	var anchor: Vector2 = world.player.position
	for mode_index in 3:
		world.camera_bounds_enabled = mode_index == 1
		world._study_key_valid = false
		world._study_camera_pending = false
		world._crusher_impacts.clear()
		world._crusher_impacts.append(_impact(anchor, 0))
		_set_position(anchor)
		world.queue_redraw()
		await _settle()
		for index in STEPS.size():
			var before: Dictionary = world.lit_draw_sections.debug_snapshot()
			var before_fast: int = world.study_skipped_setups
			for impact in world._crusher_impacts: impact.age = float(impact.age) + .017
			var step: String = STEPS[index]
			if step == "scheduled-with-camera": world.queue_redraw()
			elif step == "append-before-camera":
				world._crusher_impacts.append(_impact(anchor, 1)); world.queue_redraw()
			elif step == "expire-before-camera":
				world._crusher_impacts.pop_front(); world.queue_redraw()
			elif step == "grow-to-four":
				while world._crusher_impacts.size() < 4: world._crusher_impacts.append(_impact(anchor, world._crusher_impacts.size()+2))
				world.queue_redraw()
			elif step == "fixed-size-eviction":
				world._crusher_impacts.pop_front(); world._crusher_impacts.append(_impact(anchor, 7)); world.queue_redraw()
			elif step == "equal-value-replacement":
				world._crusher_impacts[0] = world._crusher_impacts[0].duplicate(true); world.queue_redraw()
			elif step == "position-mutation":
				for impact in world._crusher_impacts: impact.position += Vector2(3, -4)
			elif step == "fresh-cache-invalidation":
				for section in world.lit_draw_sections._cached.values(): section.revision = -1
				world.queue_redraw()
			elif step == "expire-all": world._crusher_impacts.clear(); world.queue_redraw()
			_set_position(anchor + Vector2(8.125 * (index+1), 0))
			var camera_requested: bool = world._camera_draw_bounds_changed()
			if camera_requested: world.queue_redraw()
			if step == "append-after-camera": world._crusher_impacts.append(_impact(anchor, 2)); world.queue_redraw()
			elif step == "expire-after-camera": world._crusher_impacts.pop_front(); world.queue_redraw()
			await _settle()
			var after: Dictionary = world.lit_draw_sections.debug_snapshot()
			var image: Image = root.get_texture().get_image()
			image.convert(Image.FORMAT_RGBA8)
			var frame: Dictionary = {"mode":["A","B","A2"][mode_index],"step":step,
				"camera_requested":camera_requested,"camera":str(world.player.camera.get_screen_center_position()),
				"impact_count":world._crusher_impacts.size(),"used":world.lit_draw_sections._used,
				"callbacks":int(after.draw_callbacks)-int(before.draw_callbacks),
				"cached_redraws":int(after.redraws)-int(before.redraws),
				"setup_usec":int(after.setup_usec)-int(before.setup_usec),
				"fast_setups":world.study_skipped_setups-before_fast,
				"framebuffer_size":[image.get_width(),image.get_height()],"poses":[]}
			for impact in world._crusher_impacts: frame.poses.append({"position":str(impact.position),"age":impact.age})
			if mode_index == 0: pictures.append(image)
			else:
				var original: Dictionary = rows[index]
				frame["exact_rgba"] = image.get_data() == pictures[index].get_data()
				frame["same_callbacks"] = frame.callbacks == original.callbacks
				frame["same_state"] = frame.poses == original.poses and frame.used == original.used and frame.camera == original.camera and frame.camera_requested == original.camera_requested
				if not frame.exact_rgba or not frame.same_callbacks or not frame.same_state: failure = "Cadence/state/pixel mismatch at %s %s" % [frame.mode,step]
			if image.get_size() != Vector2i(1696,780): failure = "Unexpected framebuffer"
			image.save_png(output.path_join("%02d-%s-%s.png" % [index,step,frame.mode]))
			rows.append(frame)
			_save()
			if not failure.is_empty(): _finish(); return
	var fast: int = 0
	for row in rows:
		if row.mode == "B": fast += int(row.fast_setups)
	if fast == 0: failure = "Candidate fast path not exercised"
	_finish()

func _impact(anchor: Vector2, index: int) -> Dictionary:
	return {"position":anchor + Vector2(-100 + index*24, 100 + index*9),"age":.05,"life":world.CrusherDebrisScript.LIFE_SECONDS}

func _set_position(point: Vector2) -> void:
	world.player.position = point
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.get_node("CaveLightOccluders").refresh()

func _settle() -> void:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw

func _freeze(node: Node) -> void:
	node.set_process(false); node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _save() -> void:
	FileAccess.open(output.path_join("dynamic-cadence.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"failure":failure,"rows":rows,"rendered":true,"physical_iphone":false,
		"candidate_sha256":FileAccess.get_sha256("res://tools/camera_bounds_pilot/candidate_dynamic.gd"),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),
		"limit":"Frozen synthetic ages and lifecycle events deliberately exercise actual queued camera/parent/section draw callbacks. This is a cadence/pixel regression fixture, not ordinary gameplay or FPS. Production mutators are unchanged."},"\t"))

func _finish() -> void:
	_save()
	print("CAMERA_DYNAMIC_CADENCE_FINISHED failure=",failure)
	if failure.is_empty(): print("CAMERA_DYNAMIC_CADENCE_COMPLETE")
	quit(0 if failure.is_empty() else 4)
