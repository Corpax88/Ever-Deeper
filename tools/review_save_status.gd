extends SceneTree
## Actual failed new-game/menu writes must not advertise a committed save.
var main: Node
var state: Node
var checks: Array=[]
var output_dir: String="user://quality-save-status"

func _initialize() -> void:
	call_deferred("review")

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("SAVE_STATUS_CHECK_FAILED ",label)

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
	var path: String=output_dir.path_join("save-status-%d.sav" % Time.get_ticks_usec())
	state.initialize_persistence(path)
	main.save_available=false
	main.persistence_active=true
	check("fresh menu has no save-error warning",not main.premium_menu.save_hint.text.contains("COULD NOT SAVE"))
	check("real write obstruction created",DirAccess.make_dir_absolute(path+".tmp")==OK)
	main._start_new_game()
	check("failed new-run write does not claim disk save",not main.save_available and state.last_save_error!=OK and not FileAccess.file_exists(path))
	main._open_start_menu()
	check("pause remains available from memory",main.game_started and not main.premium_menu.continue_button.disabled)
	check("failed menu write does not claim disk save",not main.save_available)
	check("visible menu reports actual retry",main.premium_menu.save_hint.text=="COULD NOT SAVE · RETRYING AUTOMATICALLY")
	check("fallback menu does not promise autosave",main.menu_hint.text=="COULD NOT SAVE · RETRYING AUTOMATICALLY")
	check("real write obstruction removed",DirAccess.remove_absolute(path+".tmp")==OK)
	await create_timer(state.AUTOSAVE_BATCH_SECONDS+0.4,true,false,true).timeout
	check("automatic recovery commits a real file",FileAccess.file_exists(path) and state.last_save_error==OK and main.save_available)
	check("menu clears warning after recovery",main.premium_menu.save_hint.text=="YOUR EXPEDITION SAVES AUTOMATICALLY")
	check("recovery status is honest",main.status_label.text=="Saving restored · progress saved")
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	var report: Dictionary={"passed":passed,"checks":checks,"scope":"Real isolated headless new-game and pause-menu disk failure/recovery; graphical text fit needs final mobile capture"}
	var file: FileAccess=FileAccess.open(output_dir.path_join("save-status.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("EVER_DEEPER_SAVE_STATUS_OK" if passed else "EVER_DEEPER_SAVE_STATUS_FAILED")
	quit(0 if passed else 2)
