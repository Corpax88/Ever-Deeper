extends SceneTree
## Compare exact footprint coverage against a deliberately oversized reference.
class ReferenceCasters extends "res://scripts/lighting/cave_light_occluders.gd":
	func _source_cell_bounds(world: Node2D, light: PointLight2D, tile: float) -> Rect2i:
		return super._source_cell_bounds(world, light, tile).grow(8)

var output: String
var main: Node
var reports: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	for area in ["ember", "deep"]:
		if area == "ember": main._dev_jump_mine("emberMine", 2)
		else: main._dev_jump_endless(12)
		var world: Node = main.depth_world if area == "ember" else main.endless_world
		await create_timer(3.0).timeout
		_freeze(world)
		main.achievement_toast.clear()
		main.quick_tutorial.dismiss()
		var candidate: Node = world.get_node("CaveLightOccluders")
		var reference: Node = ReferenceCasters.new()
		reference.name = "ReferenceCasters"
		world.add_child(reference)
		reference.set_process(false)
		reference.hide()
		for style in ["focused", "wide"]:
			var hero_lamp: Node = world.player.get_node("PremiumHeadlamp")
			var pet_lamp: Node = world.get_node_or_null("MoleCompanion/PremiumHeadlamp")
			hero_lamp.preview_settings = {"style":style, "range_multiplier":1.4, "energy_multiplier":1.28}
			if pet_lamp != null:
				pet_lamp.preview_settings = hero_lamp.preview_settings
			for direction in [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]:
				hero_lamp.set_direction(direction)
				if pet_lamp != null: pet_lamp.set_direction(direction.rotated(0.37))
				candidate.refresh()
				reference.refresh()
				var id: String = "%s_%s_%d_%d" % [area, style, direction.x, direction.y]
				await _capture(id+"-candidate")
				candidate.hide()
				reference.show()
				await _capture(id+"-reference")
				reports.append({"id":id,"scanned":candidate.scanned_cells,"reference_scanned":reference.scanned_cells,"casters":candidate.active_count,"reference_casters":reference.active_count})
				reference.hide()
				candidate.show()
		reference.queue_free()
	FileAccess.open(output.path_join("shadow-coverage.json"), FileAccess.WRITE).store_string(JSON.stringify({"rendered":true,"physical_iphone":false,"pairs":reports}, "\t"))
	quit()

func _freeze(node: Node) -> void:
	node.set_process(false)
	node.set_physics_process(false)
	for child in node.get_children(): _freeze(child)

func _capture(id: String) -> void:
	for frame in 2: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(id+".png"))
