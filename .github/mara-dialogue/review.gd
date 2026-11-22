extends SceneTree

var game: Node
var output: String
var checks := {}
var frames: Array[String] = []


func _initialize() -> void:
	run.call_deferred()


func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	checks[name + ":capture"] = root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK
	frames.append(name)


func run() -> void:
	output = OS.get_environment("PAINTED_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await create_timer(0.8).timeout
	game._start_new_game()
	await create_timer(0.4).timeout
	game.surface_world.restore_position(game.mara.approach())
	game._update_visual_guide()
	await create_timer(0.3).timeout
	var action: Button = game.premium_hud.context_button
	checks["actual TALK is reachable"] = action.text == "TALK"
	action.pressed.emit()
	await create_timer(0.3).timeout
	var bubble: Control = game.mara_dialogue
	var actor: Node2D = game.mara.actors.surface
	var marker: Label = actor.get_node("QuestMark")
	checks["Mara is the active speaker"] = bubble.visible and bubble.speaker == actor
	checks["line is in the bubble"] = bubble.get_child(0).text.begins_with("Mine three")
	checks["line no longer writes to status"] = not game.status_label.text.begins_with("Mara")
	checks["bubble wraps on all viewports"] = bubble.get_child(0).get_line_count() > 1
	checks["bubble and tail are inside the visible viewport"] = root.get_visible_rect().encloses(bubble.get_rect())
	checks["tail follows Mara"] = (bubble.position + bubble._tail).is_equal_approx(actor.get_global_transform_with_canvas() * Vector2(0, -132))
	checks["marker gives the dialogue room"] = not marker.visible
	checks["bubble ignores pointer events"] = bubble.mouse_filter == Control.MOUSE_FILTER_IGNORE
	await capture("01-mara-talk")
	game.surface_world.restore_position(game.mara.approach() - Vector2(64, 0))
	await create_timer(0.25).timeout
	checks["bubble follows after camera movement"] = bubble.visible and (bubble.position + bubble._tail).is_equal_approx(actor.get_global_transform_with_canvas() * Vector2(0, -132))
	await capture("02-mara-camera")
	game.surface_world.restore_position(game.mara.approach() + Vector2(230, 0))
	await process_frame
	await process_frame
	checks["walking away closes the line and restores the quest marker"] = not bubble.visible and marker.visible
	game.surface_world.restore_position(game.mara.approach())
	game._update_visual_guide()
	action.pressed.emit()
	checks["TALK can repeat the current instruction"] = bubble.visible and bubble.get_child(0).text.begins_with("Follow the ramp")
	bubble.follow(10.0, true, game.surface_world.player)
	checks["reading timeout restores the quest marker"] = not bubble.visible and marker.visible
	var passed := not checks.values().has(false)
	var report := {"passed": passed, "checks": checks, "frames": frames, "viewport": [root.size.x, root.size.y]}
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	quit(0 if passed else 1)
