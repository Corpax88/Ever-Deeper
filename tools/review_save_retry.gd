extends SceneTree
## Real isolated disk failures and later automatic recovery, not mocked save returns.
const Codec = preload("res://scripts/state/run_save_codec.gd")
var state: Node
var output_dir: String = "user://quality-save-retry"
var save_path: String
var checks: Array = []
var expect_baseline: bool = false

func _initialize() -> void:
	call_deferred("review")

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("SAVE_RETRY_CHECK_FAILED ",label)

func document() -> Dictionary:
	var decoded: Variant = Codec.decode(FileAccess.get_file_as_bytes(save_path))
	return decoded if decoded is Dictionary else {}

func saved_gold() -> int:
	return int(Dictionary(document().get("state",{})).get("gold",-1))

func obstruct() -> void:
	check("temporary-path obstruction created",DirAccess.make_dir_absolute(save_path+".tmp")==OK)

func unblock() -> void:
	check("temporary-path obstruction removed",DirAccess.remove_absolute(save_path+".tmp")==OK)

func review() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_dir=argument.trim_prefix("--output=")
		if argument=="--expect-missing-retry": expect_baseline=true
	output_dir=ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	# Never use, replace or delete the player's ordinary namespace.
	save_path=output_dir.path_join("save-retry-%d.sav" % Time.get_ticks_usec())
	state=root.get_node("RunState")
	state.initialize_persistence(save_path)
	state.gold=101
	check("first good generation",state.flush_save())
	state.gold=202
	check("second good generation",state.flush_save())
	var primary: PackedByteArray=FileAccess.get_file_as_bytes(save_path)
	var backup: PackedByteArray=FileAccess.get_file_as_bytes(save_path+".bak")
	obstruct()
	state.gold=303
	state._state_changed()
	state._flush_queued_autosave()
	check("autosave reports actual disk failure",state.last_save_error!=OK)
	check("failed autosave preserves primary",FileAccess.get_file_as_bytes(save_path)==primary)
	check("failed autosave preserves backup",FileAccess.get_file_as_bytes(save_path+".bak")==backup)
	check("failed autosave remains pending",state._autosave_pending)
	unblock()
	await create_timer(state.AUTOSAVE_BATCH_SECONDS+0.4,true,false,true).timeout
	check("automatic recovery commits without another mutation",saved_gold()==303)
	check("successful recovery clears pending and error",not state._autosave_pending and state.last_save_error==OK)
	if expect_baseline:
		finish()
		return

	# Explicit checkpoints must keep the same recovery guarantees. Repeated
	# failures invalidate old callbacks rather than multiply active retry chains.
	primary=FileAccess.get_file_as_bytes(save_path)
	backup=FileAccess.get_file_as_bytes(save_path+".bak")
	obstruct()
	state.gold=404
	for attempt in 3:
		check("explicit failure %d is reported" % attempt,not state.flush_save())
	check("explicit failure remains pending",state._autosave_pending)
	check("explicit failures preserve both generations",FileAccess.get_file_as_bytes(save_path)==primary and FileAccess.get_file_as_bytes(save_path+".bak")==backup)
	var superseded_serial: int=state._autosave_timer_serial
	unblock()
	await create_timer(state.AUTOSAVE_BATCH_SECONDS+0.4,true,false,true).timeout
	check("explicit failure automatically recovers",saved_gold()==404 and not state._autosave_pending)
	check("repeated failures commit only one backup generation",FileAccess.get_file_as_bytes(save_path+".bak")==primary)

	state.gold=505
	state._state_changed()
	state._flush_queued_autosave(superseded_serial)
	check("stale callback cannot commit newer dirty work",saved_gold()==404 and state._autosave_pending)
	check("explicit success still commits new state",state.flush_save() and saved_gold()==505)
	backup=FileAccess.get_file_as_bytes(save_path+".bak")
	state._flush_queued_autosave(superseded_serial)
	check("stale callback cannot rotate valid backup",FileAccess.get_file_as_bytes(save_path+".bak")==backup and not state._autosave_pending)

	obstruct()
	state.start_new_run()
	var new_seed: int=state.world_seed
	check("failed new-run checkpoint remains pending",state._autosave_pending and state.last_save_error!=OK)
	unblock()
	await create_timer(state.AUTOSAVE_BATCH_SECONDS+0.4,true,false,true).timeout
	check("new-run checkpoint automatically recovers",saved_gold()==0 and int(Dictionary(document().get("state",{})).get("world_seed",-1))==new_seed)
	finish()

func finish() -> void:
	var failed: Array=[]
	for row in checks:
		if not row.passed: failed.append(row.name)
	var expected_failures: Array=["failed autosave remains pending","automatic recovery commits without another mutation","successful recovery clears pending and error"]
	var accepted: bool=failed==expected_failures if expect_baseline else failed.is_empty()
	var report: Dictionary={"passed":accepted,"expected_baseline_failure":expect_baseline,"checks":checks,"run_state_sha256":FileAccess.get_sha256("res://scripts/state/run_state.gd"),"scope":"Native real isolated filesystem failure, bounded retry and good-generation protection; not browser storage or phone evidence"}
	var file: FileAccess=FileAccess.open(output_dir.path_join("save-retry.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(save_path+suffix): DirAccess.remove_absolute(save_path+suffix)
	print("EVER_DEEPER_SAVE_RETRY_OK" if accepted else "EVER_DEEPER_SAVE_RETRY_FAILED")
	quit(0 if accepted else 2)
