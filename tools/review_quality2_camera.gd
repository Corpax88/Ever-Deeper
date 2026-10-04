extends SceneTree
## Quality round2: actual hero frame must also clear the visible HUD.
var main: Node
var world: Node
var state: Node
var checks: Array = []
var output: String = OS.get_environment("FINISH_OUTPUT")
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool, detail: Dictionary = {}) -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
func settle(frames: int = 12) -> void:
	for i in frames: await process_frame
	await RenderingServer.frame_post_draw
func capture(label: String) -> void:
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	world.queue_redraw()
	await settle()
	main.achievement_toast.clear()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await settle(8)
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	main.persistence_active = false
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_grant_max_tools_state()
	main._dev_jump_endless(1)
	world = main.endless_world
	world.set_process(false)
	world.player.set_physics_process(false)
	main.get_node("MinerTraining").set_physics_process(false)
	var mole: Node = main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled = false
	mole.recall()
	mole.set_physics_process(false)
	await settle()
	main.achievement_toast.clear()
	world.player.camera.position_smoothing_enabled = false
	world.restore_position(Vector2(1280, 25.5))
	world.player.set_facing(Vector2.DOWN)
	world.player.camera.set_headlamp_direction(Vector2.DOWN)
	var boundary_position: Vector2 = world.player.global_position
	check("valid-north-walking-position", boundary_position.y < 50 and world._resolve_motion(boundary_position, Vector2.ZERO).distance_to(boundary_position) < 0.01, {"position": str(boundary_position)})
	check("north-collision-remains-inside-world", world._resolve_motion(boundary_position, Vector2(0,-100)).y >= world.PLAYER_RADIUS)
	var floor_before: PackedByteArray = world.floor_cells.duplicate()
	var chunks_before: Dictionary = state.endless_chunks.duplicate(true)
	for width in [667, 844, 932]:
		root.size = Vector2i(width * 2, 750 if width == 667 else 780 if width == 844 else 860)
		DisplayServer.window_set_size(root.size)
		for style in (["original", "crusher", "comet", "crownseeker"] if width == 667 else ["original"]):
			state.endless_tool_style = style
			world.player.visual.prepare_visual_cache()
			await settle(30)
			await capture("north-" + style + "-" + str(width))
			var native: Node = world.player.visual.get("_native_worn")
			var rig: Node = native.get("rig") if native != null else null
			var bounds: Rect2 = Rect2()
			if rig != null:
				var sprite: Sprite2D = rig.get("sprite")
				bounds = sprite.get_global_transform_with_canvas() * sprite.get_rect()
			else:
				var sprite: Sprite2D = world.player.visual.get("_sprite")
				bounds = sprite.get_global_transform_with_canvas() * sprite.get_rect()
			check("whole-hero-frame-visible-" + style + "-" + str(width), bounds.size.x > 0 and root.get_visible_rect().encloses(bounds), {"bounds": str(bounds), "viewport": str(root.get_visible_rect()), "camera_top": world.player.camera.limit_top})
			var map_rect: Rect2=main.minimap_overlay.get_global_transform_with_canvas()*main.premium_hud.minimap_layout_rect()
			check("hero-clears-minimap-"+style+"-"+str(width),not bounds.intersects(map_rect),{"hero":str(bounds),"map":str(map_rect)})
	check("render-margin-does-not-mutate-geology", world.floor_cells == floor_before)
	check("render-margin-does-not-mutate-saved-chunks", state.endless_chunks == chunks_before)
	main._dev_jump_hub()
	check("hub-camera-keeps-normal-top-boundary", main.hub_world.player.camera.limit_top == 0)
	FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify(checks, "\t"))
	var passed: bool = true
	for result in checks: passed = passed and result.passed
	print("DEEP_CAMERA_MARGIN_OK" if passed else "DEEP_CAMERA_MARGIN_FAILED")
	quit(0 if passed else 2)
