extends SceneTree
var main: Node
var world: Node
var state: Node
var fx: Node
var output: String
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func verify(ok: bool, label: String) -> void:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not ok:
		push_error("RESONANCE_FAIL "+label)
		quit(2)
func capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	output=OS.get_environment("RESONANCE_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 4: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_jump_endless(1)
	main._dev_grant_max_tools_state()
	world=main.endless_world
	fx=world.resonance_drill
	verify(not fx.enabled,"ordinary game defaults off")
	main._on_developer_command_requested("test_resonance")
	verify(fx.enabled,"DEV command enables resonance")
	var mole: Node=main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled=false
	mole.recall()
	verify(state.starforge_variant=="crusher","actual max-tools Crusher equipped")
	world.player.set_facing(Vector2.DOWN)
	main.achievement_toast.hide()
	await create_timer(1.0).timeout
	await capture("01-ready")
	var dug_before: int=state.endless_dug_cells(world.current_depth).size()
	Input.action_press("move_down")
	Input.action_press("mine")
	var deadline: int=Time.get_ticks_msec()+25000
	var charged: bool=false
	var captured: bool=false
	while Time.get_ticks_msec()<deadline and int(fx.bursts)<1:
		await process_frame
		if float(fx.charge)>0.65 and not charged:
			verify(state.endless_dug_cells(world.current_depth).size()==dug_before,"Crusher leaves rock intact during charge")
			charged=true
			await capture("02-charging")
	verify(int(fx.bursts)==1,"held mining automatically fires")
	Input.action_release("move_down")
	Input.action_release("mine")
	while float(fx.age)>=0.0 and Time.get_ticks_msec()<deadline:
		await process_frame
		if int(fx.row)>=6 and not captured:
			captured=true
			await capture("03-wave")
	verify(captured,"visible wave has temporal frames")
	verify(int(fx.excavated)>20,"wave excavates broad tunnel")
	verify(fx.rings.is_empty(),"effects expire")
	await capture("04-tunnel")
	verify(world._position_walkable(world._cell_center(fx.origin+fx.direction*8)),"new tunnel walkable")
	var before: int=int(fx.bursts)
	for i in 100: fx.tick(0.1)
	verify(int(fx.bursts)==before,"idle never recharges or fires")
	fx.charge=1.0
	world.player.set_facing(Vector2.RIGHT)
	fx.on_hit(0.1)
	world.player.control_enabled=false
	var age: float=float(fx.age)
	for i in 30: fx.tick(0.1)
	verify(float(fx.age)==age,"menus pause active burst")
	world.player.control_enabled=true
	for i in 30: fx.tick(0.1)
	verify(fx.rings.size()<=8 and fx.debris.size()<=64,"bounded VFX")
	var original: Vector2i=fx.origin
	fx.rebase(Vector2(0,-world.CHUNK_HEIGHT))
	verify(fx.origin.y==original.y-world.DeepLayout.CHUNK_ROWS,"stream rebase preserves wave coordinates")
	fx.rebase(Vector2(0,world.CHUNK_HEIGHT))
	fx.reset()
	fx.charge=1.0
	world.player.set_facing(Vector2.LEFT)
	fx.on_hit(0.1)
	fx.origin=Vector2i(2,fx.origin.y)
	fx.tick(0.1)
	verify(fx.blocked and not world._cell_diggable(Vector2i(1,fx.origin.y)),"permanent boundary blocks blast")
	fx.reset()
	print("RESONANCE_REVIEW_OK checks=",checks.size())
	quit(0)
