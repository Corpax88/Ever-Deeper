extends SceneTree
## Mobile captures and actual automatic impacts from the immutable DEV package.
var game: Node
var state: Node
var output: String
var pack_source: String
var captures: Array[String] = []
var failures: Array[String] = []

func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output=arg.trim_prefix("--output=")
		if arg.begins_with("--pack-source="): pack_source=arg.trim_prefix("--pack-source=")
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		print("MOLE_RENDER_CHECK_FAILED "+label)

func settle(frames: int = 3) -> void:
	for frame in range(frames): await process_frame

func capture(label: String) -> void:
	await settle()
	await RenderingServer.frame_post_draw
	var filename: String=label+".png"
	check(root.get_texture().get_image().save_png(output.path_join(filename))==OK,"Capture "+label)
	captures.append(filename)

func run() -> void:
	check(FileAccess.file_exists("res://project.binary") and not FileAccess.file_exists("res://project.godot"),"Exact exported PCK is required")
	check(OS.has_feature("ever_deeper_dev"),"DEV flavor is required")
	check(DisplayServer.get_name()!="headless","A real renderer is required")
	if not failures.is_empty(): quit(4); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size=Vector2i(2532,1170)
	state=root.get_node("RunState")
	game=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene=game
	await settle(8)
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed=410529
	game._start_new_game()
	game._dev_seed_all_zones_state()
	game._dev_ensure_playing()
	game._enter_mine("mossMine",false,false)
	await settle(8)
	game.quick_tutorial.dismiss()
	game.achievement_toast.clear()
	var world: Node=game.mine_world
	var mole: Node=world.get_node("MoleCompanion")
	world.set_process(false)
	world.player.set_physics_process(false)
	mole.set_physics_process(false)
	world.player.control_enabled=true
	state.overhaul_progress={"skills":{"shake":1,"teamwork":1,"fetch":1,"big_paws":1,"trailrunner":1,"ore_nose":1,"echo":1,"lantern":1,"long_beam":1,"homeward":1},"companion_xp":90}
	mole._spawn_beside_hero()
	mole.was_active=true
	var target: Vector2=Vector2(INF,INF)
	var landing: Vector2=Vector2(INF,INF)
	var best: float=INF
	for cell in world.blocks:
		var point: Vector2=world._cell_center(cell)
		if not world.companion_can_dig(point): continue
		var floor_point: Vector2=mole._reachable_floor(point)
		var score: float=floor_point.distance_squared_to(world.player.global_position)
		if is_finite(floor_point.x) and score<best:
			target=point
			landing=floor_point
			best=score
	check(is_finite(target.x),"Natural exposed wall with a reachable work position")
	if is_finite(target.x):
		world.player.global_position=landing
		world.player.set_facing((target-landing).normalized())
		world.player.camera.position_smoothing_enabled=false
		world.player.camera.reset_smoothing()
		world.player.camera.force_update_scroll()
		mole.global_position=landing
		mole.recall()
		mole.think_clock=0.0
		world.external_mine_held=true
		for frame in range(21): mole._physics_process(1.0/60.0)
		check(mole.action=="shake" and mole.automatic_task,"Authored Earthshaker windup begins without a command")
		await capture("01-auto-earthshaker-windup")
		for frame in range(14): mole._physics_process(1.0/60.0)
		check(mole.dug_total>0,"Autonomous impact really mines terrain")
		world.queue_redraw()
		await capture("02-auto-earthshaker-impact")
		world.external_mine_held=false
		for drop in world.drops: drop.age=1.0
		for frame in range(240): mole._physics_process(1.0/60.0)
		check(mole.collected_total>0,"Companion automatically collects its mined drops")
		await capture("03-auto-fetch-result")
	var ui: Node=game.get_node("CompanionInterface")
	ui.open_skills()
	for tab in ["together","how","skills"]:
		ui.journal.select_tab(tab)
		await capture("04-journal-"+tab)
	ui.journal.scroll.scroll_vertical=10000
	await capture("05-journal-skills-bottom")
	var report: Dictionary={"pack_sha256":FileAccess.get_sha256(pack_source),"captures":captures,"failures":failures,"rendered":true,"automatic_digs":mole.dug_total,"automatic_collection":mole.collected_total,"viewport":[2532,1170],"limit":"Native software renderer; physical iPhone performance remains unverified."}
	var report_file: FileAccess=FileAccess.open(output.path_join("mole-review.json"),FileAccess.WRITE)
	report_file.store_string(JSON.stringify(report,"\t"))
	report_file.close()
	if failures.is_empty(): print("MOLE_AUTONOMY_RENDER_COMPLETE")
	quit(0 if failures.is_empty() else 4)
