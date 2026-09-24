extends "res://scripts/qa/suites/dev14_review.gd"
func _command(data: Dictionary) -> void:
	if String(data.kind) == "light_hide":
		command_id = int(data.id)
		main.developer_menu.render_probe.hide()
		return
	if String(data.kind) == "light_setup":
		command_id = int(data.id)
		main._dev_jump_mine("emberMine", 1)
		return
	if String(data.kind) == "light_advance":
		command_id = int(data.id)
		var probe: Node = main.developer_menu.render_probe
		probe.stage_started = Time.get_ticks_usec() - int(float(probe.STAGES[probe.stage_index].seconds) * 1000000.0) - 1000
		return
	if String(data.kind) == "light_cancel":
		command_id = int(data.id)
		main.developer_menu.render_probe.cancel("Test cancellation")
		return
	if String(data.kind) == "light_interrupt":
		command_id = int(data.id)
		main.developer_menu.render_probe._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		return
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
	for name_value in ["SessionReport", "SendReport", "ClearReport", "AutoFPSTest"]:
		var button: Control = menu.find_child(name_value, true, false)
		if button != null:
			var r := button.get_global_rect()
			buttons[name_value] = [r.position.x + r.size.x / 2, r.position.y + r.size.y / 2]
	var probe_state: Dictionary = {}
	if menu.render_probe != null:
		var probe: Node = menu.render_probe
		probe_state = {"running":probe.running,"stage":probe.stage_index,"result":probe.result,"restored":probe.settings_restored()}
		var send: Control = probe.find_child("SendLightReport",true,false)
		if send != null:
			var r := send.get_global_rect()
			probe_state["send"] = [r.get_center().x,r.get_center().y]
			probe_state["panel"] = [probe.result_panel.position.x,probe.result_panel.position.y,probe.result_panel.size.x,probe.result_panel.size.y]
	JavaScriptBridge.eval("window.LIGHT_TEST_STATE=" + JSON.stringify(probe_state),true)
	JavaScriptBridge.eval("window.REPORT_UI=" + JSON.stringify({"buttons":buttons, "running":menu.session_recorder.running, "status":menu.status_label.text}),true)
