extends SceneTree
## Real main/developer/podium paths in an isolated headless user directory.
var main: Node
var state: Node
var checks: Array=[]
var output_dir: String="user://quality-mod-lifecycle"

func _initialize() -> void:
	call_deferred("review")

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("MOD_LIFECYCLE_CHECK_FAILED ",label)

func review() -> void:
	if OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Set XDG_DATA_HOME to a disposable QA directory before this main-scene test")
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_dir=argument.trim_prefix("--output=")
	output_dir=ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 5: await process_frame
	state=root.get_node("RunState")
	main.dev_build_active=true
	main._on_developer_command_requested("test_ricochet")
	var modes: Node=main.endless_world.drill_modes
	check("actual developer command selects Ricochet",modes.dev_override=="ricochet" and modes.selected()=="ricochet")
	main._open_start_menu()
	main._continue_from_menu()
	check("pause resume preserves test selection",modes.selected()=="ricochet")
	main._cancel_mine_hold()
	check("release preserves selection and cancels projectile",modes.selected()=="ricochet" and modes.five.projectile.is_empty())
	state.treasury_goals.chainbreaker_claimed=true
	main.treasury_goal_panel.kind="echo_crystal"
	main.treasury_goal_panel._claim()
	check("real earned podium selection clears test override",modes.dev_override.is_empty() and modes.selected()=="chainbreaker")
	main._dev_jump_hub()
	main._dev_jump_endless(1)
	check("earned selection survives travel",modes.selected()=="chainbreaker")
	main._on_developer_command_requested("test_ricochet")
	modes.five.charge=3.0
	main._start_new_game()
	check("new game clears Ricochet test override",modes.dev_override.is_empty())
	check("new game clears transient five mod charge",modes.five.charge==0.0 and modes.five.mode.is_empty())
	main._dev_seed_victory_state()
	main._dev_jump_endless(1)
	main._dev_grant_max_tools_state()
	check("new run returns to ordinary tool on reentry",modes.selected().is_empty())
	main._on_developer_command_requested("test_laser")
	modes.dev_laser_on=false
	main._start_new_game()
	check("new game clears laser override and test toggle",modes.dev_override.is_empty() and modes.dev_laser_on)
	check("new game retains Resonance reset",not main.endless_world.resonance_drill.dev_override and not main.endless_world.resonance_drill.enabled)
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	var report: Dictionary={"passed":passed,"checks":checks,"scope":"Real headless main, DEV command and podium lifecycle; not native weapon appearance or phone reproduction","main_sha256":FileAccess.get_sha256("res://scripts/main.gd")}
	var file: FileAccess=FileAccess.open(output_dir.path_join("mod-lifecycle.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("EVER_DEEPER_MOD_LIFECYCLE_OK" if passed else "EVER_DEEPER_MOD_LIFECYCLE_FAILED")
	quit(0 if passed else 2)
