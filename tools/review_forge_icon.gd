extends SceneTree
var main: Node
var world: Node
var state: Node
var output: String
var checks: Array = []
func _initialize(): run.call_deferred()
func verify(ok: bool, label: String):
	checks.append({"name": label, "passed": ok})
	FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify(checks, "\t"))
func capture(label: String):
	world.player.camera.reset_smoothing()
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
func run():
	output = OS.get_environment("MODS_OUT"); DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate(); root.add_child(main); current_scene = main
	for i in 8: await process_frame
	state = root.get_node("RunState"); state.initialize_persistence(output.path_join("save.json")); state.reset_run(false)
	main._dev_ensure_playing(); main._dev_seed_victory_state(); main._dev_build_all_workshops_state(); main._dev_jump_hub()
	world = main.hub_world
	world.restore_position(world._workshop_position("tool_forge") + Vector2(0,85))
	main.achievement_toast.hide()
	await create_timer(1.0).timeout
	var button: Button = main.premium_hud.context_button
	verify(world.current_context() == "workshop:tool_forge", "real-forge-context")
	verify(button.text == "TOOL\nFORGE", "caption-retained")
	verify(button.icon.resource_path == "res://assets/ui/tool-forge-approved-v1.png", "approved-icon")
	verify(button.visible and not button.disabled, "enabled-target")
	await capture("forge-normal")
	button.button_down.emit(); button.pressed.emit(); button.button_up.emit()
	await create_timer(0.3).timeout
	verify(main.commerce_context == "workshop:tool_forge" and main._commerce_panel_is_open(), "opens-tool-forge")
	await capture("forge-open")
	main.commerce_panel.close_commerce()
	await create_timer(0.2).timeout
	world.restore_position(world._workshop_position("light_lab") + Vector2(0,85))
	await create_timer(0.4).timeout
	verify(button.icon.resource_path == "res://assets/ui/hud-interact-v1.png", "adjacent-workshop-keeps-icon")
	await capture("light-lab-unchanged")
	main.premium_hud.set_context_action("TOOL FORGE", false)
	verify(button.disabled, "disabled-state-retained")
	main.premium_hud.set_context_action("", false)
	verify(not button.visible, "empty-context-hidden")
	for row in checks:
		if not row.passed: quit(1); return
	await process_frame
	print("FORGE_ICON_REVIEW_PASSED"); quit(0)
