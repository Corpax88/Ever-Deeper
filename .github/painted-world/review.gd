extends SceneTree

var main: Node
var out: String
var checks: Dictionary = {}
var frames: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func capture(name: String) -> void:
	await create_timer(0.26).timeout
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	checks[name + ":capture"] = frame.save_png(out.path_join(name + ".png")) == OK
	frames.append(name)


func run() -> void:
	out = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await create_timer(1.5).timeout
	await capture("00-menu")
	main._start_new_game()
	await create_timer(0.35).timeout
	main.quick_tutorial.dismiss()
	main._open_inventory()
	checks["inventory:open"] = main.inventory_open
	await capture("inventory")
	main._close_inventory(false)
	var state := root.get_node("RunState")
	state.unlock_world("starfall")
	var surface: Node = main.surface_world
	for item in [
		["01-mossvein", Vector2(415, 650)],
		["02-moonglass", Vector2(1420, 642)],
		["03-emberdeep", Vector2(2600, 650)],
		["04-starfall", Vector2(3710, 650)],
	]:
		surface.restore_position(item[1])
		checks[item[0]+":position"] = surface.player.global_position.distance_to(item[1]) < 150.0
		await capture(item[0])
	for item in [["mossMine","mossvein"],["moonMine","moonglass"],["emberMine","emberdeep"],["starMine","starfall"]]:
		for depth in [1, 2]:
			var name: String = "%s-depth-%s" % [item[1], depth]
			checks[name+":enter"] = main._dev_jump_mine(item[0],depth)
			await capture(name)
	checks["hub:enter"] = main._dev_jump_hub()
	await capture("hub")
	checks["deepheart:enter"] = main._dev_jump_deepheart()
	await capture("deepheart")
	for depth in range(1, 6):
		var name := "the-deep-%s" % depth
		checks[name+":enter"] = main._dev_jump_endless(depth)
		main.endless_world.restore_position(main.endless_world.entry_spawn())
		await capture(name)
	checks["treasury:hub_return"] = main._dev_jump_hub()
	main.hub_world.treasury.enter()
	checks["treasury:enter"] = main.hub_world.treasury.inside
	main.hub_world.restore_position(main.hub_world.treasury.DONATION + Vector2(160, 0))
	await capture("treasury")
	main.hub_world.treasury.leave()
	var passed := not checks.values().has(false)
	var report := {"passed":passed,"frames":frames,"checks":checks,"viewport":[root.size.x,root.size.y]}
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	quit(0 if passed else 1)
