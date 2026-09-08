extends SceneTree
## Diagnosis only: exercise unchanged exported previews and save their native pixels.
var output_dir := ""
var mode := ""
var main: Node
var preview: Node
var samples: Array[Dictionary] = []

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.get_slice("=", 1)
		if arg.begins_with("--mode="): mode = arg.get_slice("=", 1)
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for frame in 4: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-preview-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main.game_started = true
	main._dev_jump_surface()
	var driver: Node = load("res://scripts/dev/visual_capture_driver.gd").new()
	main.add_child(driver)
	driver.set("_main", main)
	driver.call("_prepare_light_state", {"level":1,"variant":"missing"})
	preview = main.commerce_panel.hero_well.get_node("LightPreview")
	if mode == "dev9-originals":
		for field in root.find_children("StaticLightField", "", true, false):
			field.enabled = false
			field.queue_free()
	# Match the production gate, then test repeated redraws and settled restoration.
	for level in [1,2,1,1,2,1]:
		await sample(level)
	await create_timer(3.0).timeout
	for level in [1,2,1,1]:
		await sample(level)
	FileAccess.open(output_dir.path_join("diagnosis.json"), FileAccess.WRITE).store_string(JSON.stringify({"mode":mode,"samples":samples}, "\t"))
	print("PREVIEW_DIAG_COMPLETE " + JSON.stringify(samples))
	quit(0)

func sample(level: int) -> void:
	preview.show_level(level)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	var prefix: String = "%02d-level-%d" % [samples.size(), level]
	var picture: Image = preview.viewport.get_texture().get_image()
	picture.save_png(output_dir.path_join(prefix + "-viewport.png"))
	root.get_texture().get_image().save_png(output_dir.path_join(prefix + "-screen.png"))
	var lights: Array[Dictionary] = []
	for light in preview.find_children("*", "PointLight2D", true, false):
		lights.append({"name":light.name,"enabled":light.enabled,"position":light.global_position,"scale":light.global_scale,"offset":light.offset,"energy":light.energy,"color":light.color,"mask":light.range_item_cull_mask,"shadow":light.shadow_enabled,"texture_size":light.texture.get_size()})
	var fields: Array[Dictionary] = []
	for field in root.find_children("StaticLightField", "", true, false): fields.append(field.debug_snapshot())
	samples.append({"prefix":prefix,"level":level,"pixels_hash":hash(picture.get_data()),"lamp":preview.lamp.debug_snapshot(),"lights":lights,"fields":fields,"viewport_world":str(preview.viewport.world_2d.canvas)})
