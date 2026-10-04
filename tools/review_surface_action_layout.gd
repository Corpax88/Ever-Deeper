extends SceneTree
var main: Node
var output: String=OS.get_environment("MODS_OUT")
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func check(name: String,passed: bool,detail: Dictionary={}) -> void:
	checks.append({"name":name,"passed":passed,"detail":detail})
func settle(frames: int=20) -> void:
	for i in frames: await process_frame
	await RenderingServer.frame_post_draw
func bounds(control: Control) -> Rect2:
	return control.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,control.size)
func tap(button: Button) -> void:
	var at: Vector2=root.get_final_transform()*button.get_global_transform_with_canvas()*(button.size*0.5)
	var down: InputEventScreenTouch=InputEventScreenTouch.new()
	down.index=7;down.position=at;down.pressed=true
	Input.parse_input_event(down)
	await process_frame
	var up: InputEventScreenTouch=InputEventScreenTouch.new()
	up.index=7;up.position=at;up.pressed=false
	Input.parse_input_event(up)
func hero_bounds() -> Rect2:
	var visual: Node=main.surface_world.player.visual
	var native: Node=visual.get("_native_worn")
	var rig: Node=native.get("rig") if is_instance_valid(native) else null
	var sprite: Sprite2D=rig.get("sprite") if is_instance_valid(rig) else visual.get("_sprite")
	return sprite.get_global_transform_with_canvas()*sprite.get_rect()
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	await settle()
	main.persistence_active=false
	main._dev_ensure_playing()
	var state: Node=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	for width in [667,844,932]:
		root.size=Vector2i(width*2,750 if width==667 else 780 if width==844 else 860)
		DisplayServer.window_set_size(root.size)
		main._dev_jump_surface()
		main.surface_world.restore_position(main.surface_world._mine_entrance("mossMine"))
		main.surface_world.player.camera.position_smoothing_enabled=false
		main.surface_world.player.camera.reset_smoothing()
		main.surface_world.player.camera.force_update_scroll()
		await settle()
		main.achievement_toast.clear()
		var action: Rect2=bounds(main.premium_hud.context_button)
		var bag: Rect2=bounds(main.premium_hud.bag_button)
		var hero: Rect2=hero_bounds()
		check("actual-descend-context-"+str(width),main.surface_context=="enter:mossMine" and main.premium_hud.context_button.visible and main.premium_hud.context_button.text=="DESCEND" and not main.mine_button.visible)
		check("descend-clears-whole-hero-"+str(width),not action.intersects(hero),{"action":str(action),"hero":str(hero)})
		check("bag-and-descend-separate-"+str(width),not action.intersects(bag))
		check("actions-remain-inside-screen-"+str(width),root.get_visible_rect().encloses(action) and root.get_visible_rect().encloses(bag))
		check("descend-touch-target-preserved-"+str(width),action.size.x>=226 and action.size.y>=116)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join("descend-"+str(width)+".png"))
		# A real touch must still enter the mine and restore mining controls.
		await tap(main.premium_hud.context_button)
		await settle(30)
		check("descend-still-enters-mine-"+str(width),main.phase=="mine" and main.mine_button.visible,{"phase":main.phase,"context":main.surface_context,"enabled":not main.premium_hud.context_button.disabled})
		var mine: Rect2=bounds(main.mine_button)
		bag=bounds(main.premium_hud.bag_button)
		check("mining-slot-and-bag-restored-"+str(width),not mine.intersects(bag) and is_equal_approx(bag.end.x+18,mine.position.x))
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	var passed: bool=true
	for c in checks:passed=passed and c.passed
	print("SURFACE_ACTION_LAYOUT_OK" if passed else "SURFACE_ACTION_LAYOUT_FAILED")
	quit(0 if passed else 2)
