extends SceneTree
## Compare exact footprint coverage against a deliberately oversized reference.
class ReferenceCasters extends "res://scripts/lighting/cave_light_occluders.gd":
	func _source_cell_bounds(world: Node2D, light: PointLight2D, tile: float) -> Rect2i:
		return super._source_cell_bounds(world, light, tile).grow(8)

class EmitterMotion extends Node:
	var apply_motion: Callable
	var executed_frame: int = -1
	func _process(_delta: float) -> void:
		apply_motion.call()
		executed_frame = Engine.get_process_frames()
		set_process(false)

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
		world.player.camera.position_smoothing_enabled = false
		world.player.camera.reset_smoothing()
		world.player.camera.force_update_scroll()
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
		# Maximum actual Long Beam at a distant companion, then crossing a
		# cell boundary with moving emitters. Keep each lamp's union distinct.
		var hero_lamp: Node = world.player.get_node("PremiumHeadlamp")
		var pet: Node2D = world.get_node_or_null("MoleCompanion")
		assert(pet != null)
		var pet_lamp: Node = pet.get_node("PremiumHeadlamp")
		pet.position = world.player.position + Vector2(840, 130)
		for step in 2:
			pet.position += Vector2(world.TILE_SIZE + 0.5, 0)
			world.player.position += Vector2(0, world.TILE_SIZE + 0.5)
			world.player.camera.reset_smoothing()
			world.player.camera.force_update_scroll()
			for style in ["focused", "wide"]:
				hero_lamp.preview_settings = {"style":style, "range_multiplier":1.4, "energy_multiplier":1.28}
				pet_lamp.preview_settings = hero_lamp.preview_settings
				pet_lamp.configure(Color("ffe0a0"), Vector2.LEFT.rotated(.37), 0.0, 440.0)
				hero_lamp.set_direction(Vector2.RIGHT.rotated(.21))
				candidate.refresh()
				reference.refresh()
				var id: String = "%s_long_beam_%s_crossing_%d" % [area, style, step]
				await _capture(id+"-candidate")
				candidate.hide()
				reference.show()
				await _capture(id+"-reference")
				reports.append({"id":id,"scanned":candidate.scanned_cells,"reference_scanned":reference.scanned_cells,"casters":candidate.active_count,"reference_casters":reference.active_count,"pet_base_reach":pet_lamp.base_beam_length,"pet_range_multiplier":pet_lamp.effective_range_multiplier,"pet_distance":pet.position.distance_to(world.player.position)})
				reference.hide()
				candidate.show()
		# The live candidate must refresh after priority-0 movement and before
		# that same frame reaches the screen; no manual candidate refresh here.
		var before_rebuilds: int = candidate.rebuild_count
		var mover := EmitterMotion.new()
		mover.process_priority = 0
		mover.apply_motion = func():
			pet.position += Vector2(world.TILE_SIZE + .5, 0)
			world.player.position += Vector2(0, world.TILE_SIZE + .5)
			world.player.camera.reset_smoothing()
			world.player.camera.force_update_scroll()
		candidate.set_process(true)
		world.add_child(mover)
		await process_frame
		await RenderingServer.frame_post_draw
		assert(mover.executed_frame == Engine.get_process_frames(), "Capture must be the first moved frame")
		assert(candidate.rebuild_count > before_rebuilds, "Automatic casters must follow movement before drawing")
		var live_id: String = area + "_automatic_same_frame"
		root.get_texture().get_image().save_png(output.path_join(live_id+"-candidate.png"))
		candidate.set_process(false)
		candidate.hide()
		reference.refresh()
		reference.show()
		await _capture(live_id+"-reference")
		reports.append({"id":live_id,"automatic_same_frame":true,"motion_frame":mover.executed_frame,"rebuilds_before":before_rebuilds,"rebuilds_after":candidate.rebuild_count,"scanned":candidate.scanned_cells,"reference_scanned":reference.scanned_cells})
		mover.queue_free()
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
