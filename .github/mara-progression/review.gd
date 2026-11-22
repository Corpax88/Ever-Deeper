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
	await create_timer(0.18).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	checks[name + ":capture"] = image.save_png(output.path_join(name + ".png")) == OK
	frames.append(name)


func marker_at(world: String) -> Label:
	return game.mara.actors[world].get_node("QuestMark")


func approach(world: Node) -> void:
	game._update_visual_guide()
	world.restore_position(game.mara.approach())
	game._update_visual_guide()


func talk() -> void:
	game.premium_hud.context_button.pressed.emit()


func walk_to(point: Vector2) -> bool:
	for tick in range(180):
		if surface.player.global_position.distance_to(point) < 4.0:
			break
		surface.player.set_external_movement(surface.player.global_position.direction_to(point))
		surface.player._physics_process(1.0 / 60.0)
	surface.player.set_external_movement(Vector2.ZERO)
	return surface.player.global_position.distance_to(point) < 4.0


func run() -> void:
	output = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	game._start_new_game()
	await create_timer(0.4).timeout
	surface = game.surface_world
	checks["walk from spawn to her physical offer"] = walk_to(game.mara.approach())
	game._update_visual_guide()
	checks["new camp offer is a yellow exclamation mark"] = marker_at("surface").text == "!" and marker_at("surface").get_theme_color("font_color") == game.MaraQuests.GOLD
	checks["nearby player gets TALK"] = game.premium_hud.context_button.text == "TALK"
	await capture("01-available")
	talk()
	checks["accepted turn-in task shows gray question mark"] = marker_at("surface").text == "?" and marker_at("surface").get_theme_color("font_color") == game.MaraQuests.GRAY
	await capture("02-in-progress")

	state.add_resource("copper", 3)
	surface.restore_position(surface.station_interaction_position("sell"))
	await process_frame
	checks["selling is still shown while the stall works"] = game.premium_hud.context_button.text == "SELLING"
	game.station_transaction_fx.complete_immediately()
	approach(surface)
	checks["ready turn-in shows gold question mark"] = marker_at("surface").text == "?" and marker_at("surface").get_theme_color("font_color") == game.MaraQuests.GOLD
	await capture("03-ready")
	talk()
	checks["physical return offers forge next"] = game.mara.current.id == "forge" and marker_at("surface").text == "!"
	talk()
	checks["forge quest accepted through TALK"] = bool(state.mara_quests_seen.get("forge")) and game._progression_goal().objective_id == "pickaxe:2"
	checks["accepted quest has no available marker"] = marker_at("surface").text.is_empty()
	var saved: Dictionary = state.serialize()
	checks["acceptance survives save and load"] = state.deserialize(saved) and bool(state.mara_quests_seen.get("forge"))

	state.gold = int(state.next_pickaxe().cost)
	var forged: Dictionary = state.begin_forge_purchase()
	var forge_result: Dictionary = state.commit_forge_purchase(forged.get("transaction_id", ""))
	game._update_visual_guide()
	checks["actual forge purchase advances to Moonglass"] = bool(forge_result.get("ok", false)) and game.mara.current.id == "moonglass"
	state.pickaxe_level = 3
	state.gold = int(root.get_node("GameData").data.GATE_COST)
	surface.restore_position(surface.gate_interaction_position("moonglass") + Vector2(-70, 10))
	game._perform_context()
	approach(surface)
	checks["opening the actual gate moves Mara to Moonglass"] = state.area_unlocked and game.mara.current.id == "emberdeep" and game.mara_in_range
	surface.restore_position(game.MaraQuests.CAMP)
	game._update_visual_guide()
	checks["Mara cannot be talked to from the previous camp"] = not game.mara_in_range
	approach(surface)
	await capture("04-moonglass")

	state.mark_depth_entrance_discovered("moonMine")
	approach(surface)
	checks["discovered shaft gets an offer"] = game.mara.current.id == "shaft"
	talk()
	checks["accepted shaft quest routes to correct mine"] = game._progression_goal().mine_id == "moonMine"
	state.enter_depth("moonMine")
	game._update_visual_guide()
	checks["visiting the shaft resumes regional progression"] = game.mara.current.id == "emberdeep"

	state.unlock_world("emberdeep")
	state.pickaxe_level = 4
	approach(surface)
	checks["Mara can be reached in Emberdeep"] = game.mara.current.id == "starfall" and game.mara_in_range
	state.unlock_world("starfall")
	approach(surface)
	checks["Mara can be reached in Starfall"] = game.mara.current.id == "starforge" and game.mara_in_range

	var reached_hub: bool = game._dev_jump_hub()
	approach(game.hub_world)
	checks["Mara is physical and reachable at the Hub"] = reached_hub and game.mara.actors.hub.visible and game.premium_hud.context_button.text == "TALK"
	await capture("05-hub")
	var reached_heart: bool = game._dev_jump_deepheart()
	approach(game.deepheart_world)
	checks["Mara explains seals inside Deepheart"] = reached_heart and game.mara.current.id == "deepheart" and game.premium_hud.context_button.text == "TALK"
	await capture("06-deepheart")
	game._dev_seed_victory_state()
	game._dev_jump_hub()
	approach(game.hub_world)
	checks["victory offers The Deep at the Hub"] = game.mara.current.id == "the_deep" and game.mara_in_range
	talk()
	checks["The Deep accepts from physical TALK"] = bool(state.mara_quests_seen.get("the_deep"))
	var entered: bool = game._dev_jump_endless(1)
	game._update_visual_guide()
	checks["actual descent hands off to the relic quest"] = entered and game.mara.current.id == "first_relic"

	var passed := not checks.values().has(false)
	var report := {"passed": passed, "checks": checks, "frames": frames, "viewport": [root.size.x, root.size.y]}
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	quit(0 if passed else 1)
