extends SceneTree

var game: Node
var state: Node
var surface: Node
var output: String
var checks := {}
var frames: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func capture(name: String) -> void:
	await create_timer(0.16).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	checks[name + ":capture"] = image.save_png(output.path_join(name + ".png")) == OK
	frames.append(name)


func walk_to(target: Vector2) -> bool:
	for tick in range(180):
		if surface.player.global_position.distance_to(target) < 4.0:
			break
		surface.player.set_external_movement(surface.player.global_position.direction_to(target))
		surface.player._physics_process(1.0 / 60.0)
	surface.player.set_external_movement(Vector2.ZERO)
	return surface.player.global_position.distance_to(target) < 4.0


func run() -> void:
	output = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	game._start_new_game()
	await create_timer(0.45).timeout
	surface = game.surface_world
	checks["new game offers Mara without overlay"] = not game.quick_tutorial.is_teaching() and game._progression_goal().objective_id == "camp:mara_meet"
	checks["walk from spawn to Mara"] = walk_to(surface.MARA_APPROACH)
	surface._evaluate_context(surface.player.global_position)
	checks["TALK reachable"] = game.surface_context == "mara" and game.premium_hud.context_button.text == "TALK"
	await capture("01-meet-mara")
	game.premium_hud.context_button.pressed.emit()
	checks["TALK accepts task and routes to mine"] = state.camp_quest == state.CampQuest.ACTIVE and game._progression_goal().objective_id == "camp:mine"
	await capture("02-first-haul")
	var accepted: Dictionary = state.serialize()
	checks["accepted task survives save roundtrip"] = state.deserialize(accepted) and state.camp_quest == state.CampQuest.ACTIVE

	surface.restore_position(surface._mine_entrance("mossMine"))
	game.premium_hud.context_button.pressed.emit()
	checks["enter Mossvein via context"] = game.phase == "mine"
	state.add_resource("stone", 1)
	state.add_resource("copper", 2)
	checks["ore directs player to SELL stall"] = game._progression_goal().objective_id == "camp:sell"
	game.mine_world.restore_position(game.mine_world._entry_spawn())
	await process_frame
	game.premium_hud.context_button.pressed.emit()
	checks["return to surface via context"] = game.phase == "surface"

	var gold_before: int = state.gold
	surface.restore_position(surface.station_interaction_position("sell"))
	await process_frame
	checks["automatic sale uses Selling copy"] = game.premium_hud.context_button.text == "SELLING" and game.premium_hud.status_label.text.begins_with("Selling")
	await capture("03-selling")
	game.station_transaction_fx.complete_immediately()
	checks["sale advances only after commit"] = state.gold > gold_before and state.camp_ore_sold == 3 and state.camp_quest == state.CampQuest.RETURN_TO_MARA
	checks["sale completion uses plain language"] = game.premium_hud.status_label.text.begins_with("Sold")
	surface.restore_position(surface.MARA_APPROACH)
	game.premium_hud.context_button.pressed.emit()
	checks["return completes task and restores upgrade guide"] = state.camp_quest == state.CampQuest.COMPLETE and not String(game._progression_goal().get("objective_id", "")).begins_with("camp:")
	await capture("04-complete")
	var completed: Dictionary = state.serialize()
	checks["completed task survives save roundtrip"] = state.deserialize(completed) and state.camp_quest == state.CampQuest.COMPLETE
	completed.state.erase("camp_quest")
	completed.state.erase("camp_ore_sold")
	completed.state.pickaxe_level = 2
	checks["old upgraded expedition skips beginner quest"] = state.deserialize(completed) and state.camp_quest == state.CampQuest.COMPLETE
	game._start_new_game()
	checks["new expedition resets quest"] = state.camp_quest == state.CampQuest.OFFER and state.camp_ore_sold == 0

	surface.restore_position(surface.MARA_APPROACH)
	game.premium_hud.context_button.pressed.emit()
	state.add_resource("stone", 1)
	var first: Dictionary = state.begin_assay_sale()
	state.commit_assay_sale(first.transaction_id)
	state.commit_assay_sale(first.transaction_id)
	checks["partial sale counts only once"] = state.camp_ore_sold == 1 and state.camp_quest == state.CampQuest.ACTIVE
	var partial: Dictionary = state.serialize()
	checks["partial progress survives save roundtrip"] = state.deserialize(partial) and state.camp_ore_sold == 1
	state.add_resource("copper", 2)
	var second: Dictionary = state.begin_assay_sale()
	state.commit_assay_sale(second.transaction_id)
	checks["later sales complete the same task"] = state.camp_ore_sold == 3 and state.camp_quest == state.CampQuest.RETURN_TO_MARA

	var passed := not checks.values().has(false)
	var report := {"passed": passed, "checks": checks, "frames": frames, "viewport": [root.size.x, root.size.y]}
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	quit(0 if passed else 1)
