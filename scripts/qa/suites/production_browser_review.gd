extends "res://scripts/qa/suites/wayfarer_browser_review.gd"
## Explicit production QA: real production feature/save identity, no developer UI.
func run() -> void:
	if OS.has_feature("ever_deeper_dev") or not OS.has_feature("web"):
		push_error("Production browser review requires the production web export")
		main.get_tree().quit(2)
		return
	main.save_available = RunState.initialize_persistence(RunState.DEFAULT_SAVE_PATH)
	main.persistence_active = true
	main.automated_mode = false
	main._open_start_menu()
	main.get_tree().process_frame.connect(_frame)
	previous_usec = Time.get_ticks_usec()

func _command(data: Dictionary) -> void:
	if String(data.kind) != "checkpoint":
		super._command(data)
		return
	command_id = int(data.id)
	main._checkpoint_location()
	RunState.flush_save()

func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var state: Dictionary = {
		"dev_feature": OS.has_feature("ever_deeper_dev"),
		"dev_menu_present": main.developer_menu != null,
		"dev_menu_resource": ResourceLoader.exists("res://scripts/dev/developer_menu.gd"),
		"render_probe_resource": ResourceLoader.exists("res://scripts/dev/render_probe.gd"),
		"save_path": RunState.persistence_path(),
		"save_available": main.save_available,
		"save_file_present": FileAccess.file_exists(RunState.persistence_path()),
		"save_error": RunState.last_save_error,
		"seed": RunState.world_seed,
		"gold": RunState.gold,
		"user_dir_name": ProjectSettings.get_setting_with_override("application/config/custom_user_dir_name"),
		"release_label": main.PremiumMenuScript.release_label(),
	}
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE," + JSON.stringify(state) + ")", true)
