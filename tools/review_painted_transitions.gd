extends SceneTree

var scene: Node
var surface: Node
var state: Node
var checks := {}
var output: String

func _initialize() -> void:
	run.call_deferred()

func walk_to(target: Vector2) -> bool:
	for tick in range(240):
		if surface.player.global_position.distance_to(target) < 4.0:
			break
		surface.player.set_external_movement(surface.player.global_position.direction_to(target))
		surface.player._physics_process(1.0 / 60.0)
	surface.player.set_external_movement(Vector2.ZERO)
	return surface.player.global_position.distance_to(target) < 4.0

func shot(label: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	checks[label + ":image"] = root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK

func run() -> void:
	output = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	scene = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await create_timer(1.0).timeout
	scene._start_new_game()
	await create_timer(0.35).timeout
	scene.quick_tutorial.dismiss()
	surface = scene.surface_world
	for gate in ["moonglass", "emberdeep", "starfall"]:
		var anchor: Vector2 = surface.gate_interaction_position(gate)
		var west := anchor + Vector2(-100, 10)
		var east := anchor + Vector2(90, 0)
		surface.restore_position(west)
		checks[gate + ":blocked"] = not walk_to(east) and surface.player.global_position.x < anchor.x
		await shot(gate + "-closed")
		state.unlock_world(gate)
		var transition: Node = surface.portal_transitions[gate]
		for frame in range(180):
			if transition.is_passage_open():
				break
			await process_frame
		checks[gate + ":open"] = transition.is_passage_open()
		var reached_arch := walk_to(anchor)
		checks[gate + ":eastbound"] = reached_arch and walk_to(east)
		await shot(gate + "-open")
		var returned_to_arch := walk_to(anchor)
		checks[gate + ":westbound"] = returned_to_arch and walk_to(west)
	for mine in surface.MINE_IDS:
		surface.restore_position(surface._mine_return_position(mine))
		var entrance: Vector2 = surface._mine_entrance(mine)
		surface.restore_position(entrance)
		checks[mine + ":entrance_action"] = surface.active_context == "enter:" + mine
		scene._perform_context()
		checks[mine + ":descended"] = scene.phase == "mine" and scene.current_mine_id == mine
		if scene.phase != "mine":
			continue
		await create_timer(0.35).timeout
		scene.mine_world.restore_position(scene.mine_world._entry_spawn())
		await process_frame
		checks[mine + ":exit_action"] = scene.mine_exit_context
		scene._perform_context()
		checks[mine + ":ascended"] = scene.phase == "surface" and not surface._surface_collides(surface.player.global_position)
		if scene.phase != "surface":
			scene._exit_mine()
	var report := {"checks": checks, "passed": not checks.values().has(false), "viewport": [root.size.x, root.size.y]}
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	quit(0 if report.passed else 1)
