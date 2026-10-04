extends SceneTree
## Real modal lifecycles retain notification phases and never block panel input.
var main: Node
var toast: Node
var skill: Node
var checks: Array = []
var output: String

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("NOTIFICATION_MODAL_MISMATCH "+label)

func sample_modal(label: String) -> void:
	main._process(0.0)
	var before: float=toast._phase_elapsed
	var skill_before: float=skill.elapsed
	toast._process(1.0)
	skill._process(1.0)
	check(label+" hides notification input and graphics",not toast._toast.is_visible_in_tree() and not skill.is_visible_in_tree())
	check(label+" preserves earned notices and phase time",toast._phase_elapsed==before and skill.elapsed==skill_before and toast.debug_snapshot().active_id=="first_chip" and toast._queue.size()==1)
	if is_instance_valid(main.developer_menu):
		check(label+" hides the gameplay DEV shortcut",not main.developer_menu.toggle_button.is_visible_in_tree())

func run() -> void:
	output=OS.get_environment("MODS_OUT")
	if output.is_empty() or OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Set disposable MODS_OUT and XDG_DATA_HOME")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for _frame in 5: await process_frame
	main.automated_mode=false
	main._dev_ensure_playing()
	var state: Node=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	toast=main.achievement_toast
	skill=toast.get_node("SkillLevelToast")
	toast.clear()
	skill.clear()
	toast.set_process(false)
	skill.set_process(false)
	var definitions: Dictionary=root.get_node("GameData").data.ACHIEVEMENT_BY_ID
	toast.show_achievement(definitions.first_chip)
	toast.show_achievement(definitions.quick_step)
	skill._earned("mining",1)
	skill.set_process(false)
	toast._process(0.2)
	check("ordinary play presents the earned notice",toast._toast.is_visible_in_tree() and toast._phase_elapsed>0.0)
	main._open_miner_skills()
	check("real Skills modal opened",main.menu_open and main.miner_skills_panel.visible)
	sample_modal("Skills")
	main.miner_skills_panel.show_map(main.minimap_overlay)
	check("real expanded map opened",is_instance_valid(main.miner_skills_panel.map_view))
	sample_modal("Map")
	main._hide_start_menu()
	main._open_inventory()
	check("real inventory opened",main.inventory_open)
	sample_modal("Bag")
	main._close_inventory()
	var companion: Node=main.get_node("CompanionInterface")
	companion.open_skills()
	check("real companion journal opened",main._companion_panel_is_open())
	sample_modal("Companion")
	companion.journal.close_journal()
	main.treasury_goal_panel.open_goal("wallet_gold")
	check("real mod preview opened",main.treasury_goal_panel.visible)
	sample_modal("Mod preview")
	main.treasury_goal_panel.close_panel()
	main._process(0.0)
	toast._process(0.1)
	skill._process(0.1)
	check("returning to play resumes both notices",toast._toast.is_visible_in_tree() and skill.is_visible_in_tree())
	if is_instance_valid(main.developer_menu):
		check("returning to play restores DEV access",main.developer_menu.toggle_button.is_visible_in_tree())
	var before: float=toast._phase_elapsed
	toast._process(0.1)
	check("presentation continues instead of restarting",toast._phase_elapsed>before and toast.debug_snapshot().active_id=="first_chip")
	toast._process(1.0)
	toast._process(3.1)
	toast._process(0.6)
	check("next queued achievement still appears",toast.debug_snapshot().active_id=="quick_step" and toast._queue.is_empty())
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	FileAccess.open(output.path_join("notification-modals.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	print("NOTIFICATION_MODALS_OK" if passed else "NOTIFICATION_MODALS_FAILED")
	quit(0 if passed else 1)
