extends SceneTree
## Opt-in source-only art review. Never changes production textures or saves.
var output: String = ""
var candidate_dir: String = ""
var main: Node
var driver: Node
var report: Array = []

func _initialize() -> void:
	start.call_deferred()

func settle(n: int = 3) -> void:
	for _i in n: await process_frame
	await RenderingServer.frame_post_draw

func save_frame(name: String) -> void:
	await settle()
	var img := root.get_texture().get_image()
	assert(not img.is_empty())
	assert(img.save_png(output.path_join(name + ".png")) == OK)
	print("CAPTURE_OK ", name, " ", img.get_size())

func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--candidate="): candidate_dir = arg.trim_prefix("--candidate=")
	assert(not output.is_empty())
	DirAccess.make_dir_recursive_absolute(output)
	assert(DisplayServer.get_name() != "headless")
	root.size = Vector2i(1864,860)
	root.content_scale_size = Vector2i(1560,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await settle(8)
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	main._start_new_game()
	main._dev_ensure_playing()
	driver = load("res://scripts/dev/visual_capture_driver.gd").new()
	root.add_child(driver)
	driver._main = main
	var cases: Array = [
		{"id":"mossvein","kind":"hero","gear":"iron","direction":"down","pose":"idle","mine_id":"mossMine","depth":1},
		{"id":"moonglass","kind":"hero","gear":"iron","direction":"down","pose":"idle","mine_id":"moonMine","depth":1},
		{"id":"surface","kind":"hero","gear":"iron","direction":"down","pose":"idle","location":"surface"},
		{"id":"hub","kind":"hero","gear":"iron","direction":"down","pose":"idle","location":"hub"}]
	for fixture in cases:
		paused = false
		driver._resume_capture_nodes()
		assert(driver._prepare_hero_state(fixture))
		assert(await driver._settle_hero_state(fixture))
		await settle(8)
		var visual: Node = driver._capture_player.visual
		var sprite: Sprite2D = visual._sprite
		var original: Dictionary = {"texture":sprite.texture,"material":sprite.material,"region_enabled":sprite.region_enabled,"region_rect":sprite.region_rect,"position":sprite.position,"scale":sprite.scale}
		main.quick_tutorial.dismiss()
		main.get_node("HUD").hide()
		paused = true
		await save_frame(fixture.id + "-before")
		var entry: Dictionary = {"case":fixture,"hero_global":str(driver._capture_player.global_position),"texture":sprite.texture.resource_path,"region":str(sprite.region_rect),"position":str(sprite.position),"scale":str(sprite.scale)}
		if not candidate_dir.is_empty():
			var file: String = candidate_dir.path_join("down-idle-000.png")
			var img := Image.load_from_file(file)
			assert(not img.is_empty())
			img.resize(160,160,Image.INTERPOLATE_LANCZOS)
			# Candidate is rendered at 480px using the same 2.9 orthographic camera.
			# Match the original 160px atlas cell; keep original ground anchor.
			sprite.texture = ImageTexture.create_from_image(img)
			sprite.region_enabled = false
			sprite.scale = Vector2.ONE * (160.0 / float(img.get_width()))
			sprite.material = null
			await save_frame(fixture.id + "-after")
			entry.candidate_sha256 = FileAccess.get_sha256(file)
		for property in original: sprite.set(property,original[property])
		report.append(entry)
	paused = false
	var f := FileAccess.open(output.path_join("capture-report.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"source_review_only":true,"production_assets_replaced":false,"engine":Engine.get_version_info(),"display":DisplayServer.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"viewport":[root.get_texture().get_width(),root.get_texture().get_height()],"window":[root.size.x,root.size.y],"logical":[1560,720],"hud_hidden_for_art_review":true,"cases":report},"\t"))
	quit(0)
