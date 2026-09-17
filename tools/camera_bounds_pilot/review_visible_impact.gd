extends "res://tools/camera_bounds_pilot/review_dynamic_cadence.gd"
## Non-vacuity control: exact age-only state, real effects present/absent/restored.

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
	if not main._dev_jump_endless(12):
		push_error("Cannot enter Deep"); quit(3); return
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
	world.camera_bounds_enabled = false
	var anchor: Vector2 = world.player.position
	var impact: Dictionary = _impact(anchor, 0)
	impact.age = .067
	_set_position(anchor + Vector2(8.125, 0))
	world._crusher_impacts.clear()
	world.queue_redraw()
	await _settle()
	var records: Array[Dictionary] = []
	for phase in ["with", "without", "restored"]:
		world._crusher_impacts.clear()
		if phase != "without": world._crusher_impacts.append(impact)
		var before: Dictionary = world.lit_draw_sections.debug_snapshot()
		world.queue_redraw()
		await _settle()
		var after: Dictionary = world.lit_draw_sections.debug_snapshot()
		var picture: Image = root.get_texture().get_image()
		picture.convert(Image.FORMAT_RGBA8)
		if picture.get_size() != Vector2i(1696,780): quit(4); return
		picture.save_png(output.path_join(phase + ".png"))
		records.append({"phase":phase,"actual_callbacks":int(after.draw_callbacks)-int(before.draw_callbacks),
			"cached_redraws":int(after.redraws)-int(before.redraws),"used":world.lit_draw_sections._used,
			"impact_position":[impact.position.x,impact.position.y],"age":impact.age,
			"camera":str(world.player.camera.get_screen_center_position()),"framebuffer_size":[picture.get_width(),picture.get_height()]})
	FileAccess.open(output.path_join("visible-impact.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"rows":records,"rendered":true,"physical_iphone":false,"seed":4608,"depth":12,
		"candidate_sha256":FileAccess.get_sha256("res://tools/camera_bounds_pilot/candidate_dynamic.gd"),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),
		"source_effect_sha256":FileAccess.get_sha256("res://scripts/world/crusher_debris.gd"),
		"limit":"Same frozen visible age-only cadence-fixture state; original full draw path in all phases. Only the real impact list changes, then the exact dictionary is restored. No effect strengths, materials or drawing code changes."},"\t"))
	print("CAMERA_VISIBLE_IMPACT_COMPLETE")
	quit(0)
