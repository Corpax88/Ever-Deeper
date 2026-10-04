extends SceneTree
## Actual production panel rendering at the smallest reviewed landscape width.
var main: Node
var state: Node
var output: String = OS.get_environment("FINISH_OUTPUT")
var checks: Array = []
func _initialize() -> void: run.call_deferred()
func settle() -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
func check(label: String, passed: bool, detail: Dictionary = {}) -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
func inspect(family: String) -> void:
	await settle()
	var panel: Control = main.commerce_panel
	main.achievement_toast.clear()
	await settle()
	root.get_texture().get_image().save_png(output.path_join(family + "-667.png"))
	var title: Label = panel.title_label
	var width: float = title.get_theme_font("font").get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
	check(family + "-header-full-text", width <= title.size.x + 1, {"text": title.text, "text_width": width, "width": title.size.x})
	if panel.primary_button.visible:
		var action: Label = panel.primary_copy
		var action_width: float = action.get_theme_font("font").get_string_size(action.text, HORIZONTAL_ALIGNMENT_LEFT, -1, action.get_theme_font_size("font_size")).x
		check(family + "-action-within-inset", action_width <= action.size.x + 1, {"text": action.text, "text_width": action_width, "width": action.size.x, "inset": action.offset_left, "font": action.get_theme_font_size("font_size")})
	for next_copy in panel.find_children("NextStepCopy", "Label", true, false):
		check(family + "-helper-wraps", next_copy.get_line_count() == next_copy.get_visible_line_count(), {"font": next_copy.get_theme_font_size("font_size"), "lines": next_copy.get_line_count()})
	panel.close_commerce()
	await settle()
	check(family + "-close-works", not panel.visible)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await settle()
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_grant_max_tools_state()
	main._dev_jump_surface()
	main._open_forge_commerce()
	await inspect("forge")
	main._open_starforge_commerce()
	await inspect("starforge")
	main._dev_jump_mine("mossMine", 2)
	main._open_commerce(main.CommerceCatalogScript.depth_forge_config("mossMine"), "depth_forge")
	await inspect("depth-forge")
	main._dev_build_all_workshops_state()
	main._dev_jump_hub()
	for workshop in ["tool_forge", "light_lab", "wardrobe", "lift_workshop"]:
		var config: Dictionary = main.CommerceCatalogScript.workshop_config(workshop, state.workshop_status(workshop), main.hub_world.workshop_selection_preview(workshop))
		main._open_commerce(config, "workshop:" + workshop)
		await inspect(workshop)
	state.cargo["deep_alloy"] = 100
	var ready_config: Dictionary = main.CommerceCatalogScript.workshop_config("tool_forge", state.workshop_status("tool_forge"), main.hub_world.workshop_selection_preview("tool_forge"))
	main._open_commerce(ready_config, "workshop:tool_forge")
	check("ready-upgrade-enabled", not main.commerce_panel.primary_button.disabled and main.commerce_panel.primary_button.text == "Upgrade workshop")
	await inspect("tool-forge-ready")
	FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify(checks, "\t"))
	var passed: bool = true
	for result in checks: passed = passed and result.passed
	print("COMMERCE_TEXT_FIT_OK" if passed else "COMMERCE_TEXT_FIT_FAILED")
	quit(0 if passed else 2)
