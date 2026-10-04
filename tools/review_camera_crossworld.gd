extends SceneTree
## Independent camera-only review on real worlds; no terrain or runtime edits.
var main: Node
var state: Node
var world: Node
var output: String
var checks: Array = []
var samples: Array = []

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool, detail: Dictionary = {}) -> void:
	checks.append({"name":label,"passed":passed,"detail":detail})
	if not passed: print("CAMERA_CROSSWORLD_MISMATCH "+label)

func vector(value: Vector2) -> Array: return [value.x,value.y]
func rectangle(value: Rect2) -> Array: return [value.position.x,value.position.y,value.size.x,value.size.y]

func limits(camera: Camera2D) -> Array:
	return [camera.limit_left,camera.limit_top,camera.limit_right,camera.limit_bottom]

func settle() -> void:
	for _frame in 90: await physics_frame
	await process_frame
	await RenderingServer.frame_post_draw

func hero_bounds(player: Node) -> Rect2:
	var native: Node=player.visual.get("_native_worn")
	var rig: Node=native.get("rig") if native != null else null
	var sprite: Sprite2D=rig.get("sprite") if rig != null else player.visual.get("_sprite")
	return sprite.get_global_transform_with_canvas()*sprite.get_rect()

func run() -> void:
	output=OS.get_environment("MODS_OUT")
	if output.is_empty() or DisplayServer.get_name()=="headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for _frame in 5: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated.sav"))
	state.reset_run(false)
	state.world_seed=4608
	seed(4608)
	main.persistence_active=false
	main._dev_ensure_playing()
	main._dev_grant_max_tools_state()
	main.get_node("MinerTraining").set_process(false)
	main.get_node("MinerTraining").set_physics_process(false)
	var mole: Node=main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled=false
	mole.set_physics_process(false)
	root.size=Vector2i(1334,750)
	DisplayServer.window_set_size(root.size)
	var selected_area: String=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--area="): selected_area=arg.trim_prefix("--area=")
	for area in ["surface","mossvein","depth2","deepheart","deep"]:
		if not selected_area.is_empty() and selected_area!=area: continue
		match area:
			"surface":
				main._dev_jump_surface()
				world=main.surface_world
				world.restore_position(Vector2(800,650))
			"mossvein":
				main._dev_jump_mine("mossMine",1)
				world=main.mine_world
			"depth2":
				main._dev_jump_mine("mossMine",2)
				world=main.depth_world
			"deepheart":
				main._dev_jump_deepheart()
				world=main.deepheart_world
			"deep":
				# Review the actual entrance, not a debug jump into unexplored
				# lower terrain that has no excavated player route yet.
				main._dev_jump_endless(1)
				world=main.endless_world
		for _frame in 6: await process_frame
		world.set_process(false)
		world.player.set_physics_process(false)
		world.player.camera.position_smoothing_enabled=false
		main.quick_tutorial.dismiss()
		main.achievement_toast.clear()
		var initial_position: Vector2=world.player.global_position
		var original_limits: Array=limits(world.player.camera)
		if area=="deep": check("Deep entrance is actually walkable",not world.collision_at(initial_position))
		var down_offset: float=0.0
		for direction_name in ["down","up"]:
			var direction: Vector2=Vector2.DOWN if direction_name=="down" else Vector2.UP
			world.player.set_facing(direction)
			world.player.camera.set_headlamp_direction(direction)
			await settle()
			world.player.camera.reset_smoothing()
			world.player.camera.force_update_scroll()
			main.achievement_toast.clear()
			await RenderingServer.frame_post_draw
			var label: String=area+"-"+direction_name
			var bounds: Rect2=hero_bounds(world.player)
			var camera: Camera2D=world.player.camera
			var map_rect: Rect2=main.minimap_overlay.get_global_transform_with_canvas()*main.premium_hud.minimap_layout_rect()
			var sample: Dictionary={"case":label,"phase":main.phase,"hero":rectangle(bounds),"map":rectangle(map_rect),"camera_position":vector(camera.position),"camera_center":vector(camera.get_screen_center_position()),"zoom":vector(camera.zoom),"player":vector(world.player.global_position),"limits":limits(camera),"viewport":vector(camera.get_viewport_rect().size),"framing":camera.headlamp_framing_snapshot(),"hero_map_intersection":bounds.intersects(map_rect)}
			samples.append(sample)
			root.get_texture().get_image().save_png(output.path_join(label+".png"))
			check(label+" whole hero remains inside viewport",root.get_visible_rect().encloses(bounds),sample)
			check(label+" camera does not change world limits",limits(camera)==original_limits)
			check(label+" camera does not move player",world.player.global_position.is_equal_approx(initial_position))
			if area=="surface":
				check(label+" surface ratio remains authored",not bool(sample.framing.enabled) and is_equal_approx(camera.position.y,camera.framing_offset_for_viewport(camera.get_viewport_rect().size.y,camera.zoom.y)))
			else:
				check(label+" cave framing remains active",bool(sample.framing.enabled))
				if direction_name=="down": down_offset=camera.position.y
				else: check(area+" UP reverses DOWN lookahead",down_offset>0.0 and camera.position.y<0.0)
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	FileAccess.open(output.path_join("samples.json"),FileAccess.WRITE).store_string(JSON.stringify(samples,"\t"))
	var failed: bool=false
	for item in checks: failed=failed or not bool(item.passed)
	print("CAMERA_CROSSWORLD_FAILED" if failed else "CAMERA_CROSSWORLD_OK")
	quit(1 if failed else 0)
