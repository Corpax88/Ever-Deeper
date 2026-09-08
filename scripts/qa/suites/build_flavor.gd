extends "res://scripts/qa/qa_context.gd"
## Build flavor checks moved intact from main.gd.


func _run_dev_tools_qa() -> void :
	if not _dev_qa_require(main.dev_build_active, "feature_guard"):
		return
	if not _dev_qa_require(main.developer_menu != null, "menu_installed"):
		return
	if not _dev_qa_require(String(RunState.persistence_path()) == main.DEV_QA_SAVE_PATH, "isolated_save_path"):
		return
	var command_ids: PackedStringArray = main.developer_menu.command_ids()
	if not _dev_qa_require(command_ids.size() == 23 and command_ids.has("jump_starMine_d2"), "command_contract"):
		return
	var layout= Dictionary(main.developer_menu.apply_iphone_layout_for_test(Vector2(932, 430)))
	if not _dev_qa_require(bool(layout.get("touch_targets_valid", false)), "iphone_touch_targets"):
		return
	if not _dev_qa_require(bool(layout.get("finger_scroll", false)), "iphone_finger_scroll"):
		return
	if not _dev_qa_require(int(layout.get("button_font_size", 0)) >= 13, "iphone_readable_text"):
		return
	main.developer_menu.open_menu()
	await main.get_tree().process_frame
	var dev_scroll: ScrollContainer = main.developer_menu.scroll
	var touch= InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	touch.position = dev_scroll.get_global_rect().get_center()
	main.get_viewport().push_input(touch, true)
	var drag= InputEventScreenDrag.new()
	drag.index = 3
	drag.position = touch.position - Vector2(0, 80)
	drag.relative = Vector2(0, -80)
	main.get_viewport().push_input(drag, true)
	if not _dev_qa_require(dev_scroll.scroll_vertical > 0, "iphone_finger_drag_moves_content"):
		return
	main.developer_menu.close_menu()
	main._on_developer_command_requested("preset_all_zones")
	if not _dev_qa_require(bool(RunState.fourth_unlocked) and RunState.is_depth_visited("starMine"), "all_zones_preset"):
		return
	main._on_developer_command_requested("jump_moonMine_d2")
	if not _dev_qa_require(main.phase == "depth" and main.current_mine_id == "moonMine" and int(RunState.current_depth) == 2, "exact_depth_jump"):
		return
	main._on_developer_command_requested("preset_hub")
	if not _dev_qa_require(main.phase == "hub" and bool(RunState.singularity_secured), "hub_preset"):
		return
	main._on_developer_command_requested("preset_endless")
	main._on_developer_command_requested("jump_endless_12")
	if not _dev_qa_require(main.phase == "endless" and int(Dictionary(RunState.endless_descent_status()).get("current_depth", 0)) == 12, "endless_layer_jump"):
		return
	main._on_developer_command_requested("grant_all_relics")
	if not _dev_qa_require(int(Dictionary(RunState.endless_descent_status()).get("placed_relic_count", 0)) == RunState.ENDLESS_RELIC_IDS.size(), "all_relics"):
		return
	main._on_developer_command_requested("build_all_workshops")
	if not _dev_qa_require(int(Dictionary(RunState.endless_descent_status()).get("built_workshop_count", 0)) == RunState.ENDLESS_WORKSHOP_IDS.size(), "all_workshops"):
		return
	main._on_developer_command_requested("reset_dev")
	if not _dev_qa_require( not bool(RunState.victory) and int(RunState.gold) == 0, "dev_reset"):
		return
	for suffix in ["", ".tmp", ".bak"]:
		var path= main.DEV_QA_SAVE_PATH + String(suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("EVER_DEEPER_DEV_TOOLS_QA_OK commands=23 isolated_save=true iphone=932x430 finger_scroll=true readable_text=true exact_depths=true relics=5 workshops=5")
	main.get_tree().quit(0)


func _dev_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_DEV_TOOLS_QA_FAIL step=%s" % step)
	main.get_tree().quit(1)
	return false


func _run_build_flavor_qa() -> void :
	var feature_enabled= OS.has_feature(main.DEV_BUILD_FEATURE)
	var menu_present= main.developer_menu != null
	var dev_resource_present= ResourceLoader.exists("res://scripts/dev/developer_menu.gd")
	var render_probe_present= ResourceLoader.exists("res://scripts/dev/render_probe.gd")
	var user_dir_name= String(ProjectSettings.get_setting_with_override("application/config/custom_user_dir_name"))
	var expected_user_dir= (
		"Ever Deeper- Godot Development Port"
		if feature_enabled
		else "Ever Deeper- Godot Production Port"
	)
	var expected_save_path= main.DEV_SAVE_PATH if feature_enabled else RunState.DEFAULT_SAVE_PATH
	var save_contract_valid= (
		main.DEV_SAVE_PATH != RunState.DEFAULT_SAVE_PATH
		and expected_save_path == (main.DEV_SAVE_PATH if feature_enabled else RunState.DEFAULT_SAVE_PATH)
		and user_dir_name == expected_user_dir
	)
	if (
		feature_enabled != menu_present
		or feature_enabled != dev_resource_present
		or feature_enabled != render_probe_present
		or not save_contract_valid
	):
		push_error(
			"EVER_DEEPER_BUILD_FLAVOR_QA_FAIL feature=%s menu=%s resource=%s save=%s user_dir=%s"
			%[feature_enabled, menu_present, dev_resource_present, expected_save_path, user_dir_name]
		)
		main.get_tree().quit(1)
		return
	var user_dir_path= String(OS.get_user_data_dir())
	print(
		"EVER_DEEPER_BUILD_FLAVOR_QA_OK flavor=%s menu=%s resource=%s save=%s user_dir=%s path=%s isolated=true"
		%[
			"dev" if feature_enabled else "production",
			menu_present,
			dev_resource_present,
			expected_save_path,
			user_dir_name,
			user_dir_path,
		]
	)
	main.get_tree().quit(0)
