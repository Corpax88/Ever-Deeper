extends "res://scripts/qa/qa_context.gd"
## Input release checks moved intact from main.gd.


func _run_input_release_qa() -> void :
	main.phase = "surface"
	main.surface_context = "ore_mountain"
	main._refresh_context_button()
	if not _qa_input_release_check(main.mine_button.visible, "Surface mining context must show the mining button"):
		return

	main._on_mine_button_gui_input(_qa_input_touch(7, true))
	if not _qa_input_release_check(_qa_input_phase_is_held("surface"), "Touch press must hold only the active Surface world"):
		return
	main.surface_context = ""
	main._refresh_context_button()
	if not _qa_input_release_check( not main.mine_button.visible, "Leaving mining context must hide the mining button"):
		return
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Hiding the button without button_up must cancel every mining state"):
		return

	main.surface_context = "ore_mountain"
	main._refresh_context_button()
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Showing the button again must not resume mining"):
		return
	main._on_mine_button_gui_input(_qa_input_touch(7, true))
	main._input(_qa_input_touch(3, false))
	if not _qa_input_release_check(_qa_input_phase_is_held("surface") and main.mine_touch_index == 7, "An unrelated touch release must not cancel mining"):
		return
	main._input(_qa_input_touch(7, false))
	if not _qa_input_release_check(_qa_input_is_fully_released(), "The matching root touch release must cancel mining"):
		return

	main._on_mine_button_gui_input(_qa_input_touch(9, true))
	main._input(_qa_input_touch(9, false, true))
	if not _qa_input_release_check(_qa_input_is_fully_released(), "A canceled matching touch must cancel mining"):
		return

	var touch_index= 20
	for phase_value in ["surface", "mine", "depth", "deepheart", "endless"]:
		main.phase = String(phase_value)
		main._on_mine_button_gui_input(_qa_input_touch(touch_index, true))
		if not _qa_input_release_check(_qa_input_phase_is_held(main.phase), "%s touch must hold only its active world" % main.phase):
			return
		main._input(_qa_input_touch(touch_index, false))
		if not _qa_input_release_check(_qa_input_is_fully_released(), "%s touch release must clear every world" % main.phase):
			return
		touch_index += 1

	main.phase = "mine"
	main._on_mine_button_gui_input(_qa_input_mouse_button(MOUSE_BUTTON_LEFT, true))
	if not _qa_input_release_check(main.mine_mouse_held and _qa_input_phase_is_held("mine"), "Mouse press must hold only the active Mine world"):
		return
	main._input(_qa_input_mouse_button(MOUSE_BUTTON_RIGHT, false))
	if not _qa_input_release_check(main.mine_mouse_held and _qa_input_phase_is_held("mine"), "An unrelated mouse release must not cancel mining"):
		return
	main._input(_qa_input_mouse_button(MOUSE_BUTTON_LEFT, false))
	if not _qa_input_release_check(_qa_input_is_fully_released(), "The matching root mouse release must cancel mining"):
		return

	main.phase = "surface"
	main._on_mine_button_gui_input(_qa_input_touch(30, true))
	main._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Application focus loss must cancel mining without persistence"):
		return
	main._on_mine_button_gui_input(_qa_input_touch(31, true))
	main._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	if not _qa_input_release_check(_qa_input_is_fully_released(), "Application pause must cancel mining without persistence"):
		return

	print("EVER_DEEPER_INPUT_RELEASE_OK hide=true matching_touch=true canceled_touch=true unrelated_touch_ignored=true mouse=true worlds=5 focus_pause=true")
	main.get_tree().quit(0)


func _qa_input_touch(index: int, pressed: bool, canceled: bool = false) -> InputEventScreenTouch:
	var event= InputEventScreenTouch.new()
	event.index = index
	event.pressed = pressed
	event.canceled = canceled
	return event


func _qa_input_mouse_button(button_index: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event= InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = pressed
	return event


func _qa_input_phase_is_held(expected_phase: String) -> bool:
	return (
		main.mine_held
		and main.surface_world.external_mine_held == (expected_phase == "surface")
		and main.mine_world.external_mine_held == (expected_phase == "mine")
		and main.depth_world.external_mine_held == (expected_phase == "depth")
		and main.deepheart_world.external_mine_held == (expected_phase == "deepheart")
		and main.endless_world.external_mine_held == (expected_phase == "endless")
	)


func _qa_input_is_fully_released() -> bool:
	return (
		not main.mine_held
		and main.mine_touch_index == -1
		and not main.mine_mouse_held
		and not main.surface_world.external_mine_held
		and not main.mine_world.external_mine_held
		and not main.depth_world.external_mine_held
		and not main.deepheart_world.external_mine_held
		and not main.endless_world.external_mine_held
	)


func _qa_input_release_check(condition: bool, message: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_INPUT_RELEASE_FAILED: %s" % message)
	main.get_tree().quit(2)
	return false

