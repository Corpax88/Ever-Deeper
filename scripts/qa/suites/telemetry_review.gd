extends "res://scripts/qa/suites/dev14_review.gd"
func _command(data: Dictionary) -> void:
	if String(data.kind) == "report_focus":
		command_id = int(data.id)
		var button: Control = main.developer_menu.find_child(String(data.button), true, false)
		main.developer_menu.scroll.ensure_control_visible(button)
		return
	if String(data.kind) == "report_menu":
		command_id = int(data.id)
		main.developer_menu.open_menu()
		return
	if String(data.kind) == "report_close":
		command_id = int(data.id)
		main.developer_menu.close_menu()
		return
	super._command(data)

func _frame() -> void:
	super._frame()
	if not is_instance_valid(main.developer_menu): return
	var menu: Node = main.developer_menu
	var buttons: Dictionary = {}
	for name_value in ["SessionReport", "SendReport", "ClearReport"]:
		var button: Control = menu.find_child(name_value, true, false)
		if button != null:
			var r := button.get_global_rect()
			buttons[name_value] = [r.position.x + r.size.x / 2, r.position.y + r.size.y / 2]
	JavaScriptBridge.eval("window.REPORT_UI=" + JSON.stringify({"buttons":buttons, "running":menu.session_recorder.running, "status":menu.status_label.text}),true)
