extends SceneTree
## Real JSON writes, failed commits and corrupt-primary backup recovery.
var achievements: Node
var checks: Array=[]
var output_dir: String="user://quality-achievement-recovery"

func _initialize() -> void:
	call_deferred("review")

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("ACHIEVEMENT_RECOVERY_CHECK_FAILED ",label)

func write_text(path: String, value: String) -> void:
	var file: FileAccess=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(value)
	file.flush()
	file.close()

func disk_records(path: String) -> Dictionary:
	var value: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	return Dictionary(value.get("records",{})) if value is Dictionary else {}

func review() -> void:
	if OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Set XDG_DATA_HOME to a disposable QA directory before achievement persistence tests")
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_dir=argument.trim_prefix("--output=")
	output_dir=ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.get_node("RunState").reset_run(false)
	await create_timer(0.3,true,false,true).timeout
	achievements=root.get_node("AchievementService")
	var path: String=ProjectSettings.globalize_path(achievements._storage_path())
	achievements.records={"quick_step":1234567890}
	check("first lifetime record commits",achievements._save_records())
	achievements.records["roadrunner"]=1234567891
	check("second lifetime record commits",achievements._save_records())
	var primary: PackedByteArray=FileAccess.get_file_as_bytes(path)
	var backup: PackedByteArray=FileAccess.get_file_as_bytes(path+".bak")
	check("JSON schema and old timestamps retained",disk_records(path).size()==2 and int(disk_records(path).quick_step)==1234567890 and int(disk_records(path+".bak").quick_step)==1234567890)
	check("temporary-path obstruction created",DirAccess.make_dir_absolute(path+".tmp")==OK)
	achievements.records["first_chip"]=1234567892
	for attempt in 3:
		check("failed write %d is reported" % attempt,not achievements._save_records() and achievements.last_save_error!=OK)
	check("failed writes retain previous primary and backup",FileAccess.get_file_as_bytes(path)==primary and FileAccess.get_file_as_bytes(path+".bak")==backup)
	check("failed writes retain new in-memory record for retry",achievements.records.size()==3 and achievements._record_save_pending)
	var old_serial: int=achievements._record_save_timer_serial
	check("temporary-path obstruction removed",DirAccess.remove_absolute(path+".tmp")==OK)
	await create_timer(achievements.SAVE_RETRY_SECONDS+0.4,true,false,true).timeout
	check("automatic retry commits without new achievement",disk_records(path).size()==3 and achievements.last_save_error==OK and not achievements._record_save_pending)
	check("retry rotates one valid backup only",FileAccess.get_file_as_bytes(path+".bak")==primary)
	primary=FileAccess.get_file_as_bytes(path)
	backup=FileAccess.get_file_as_bytes(path+".bak")
	achievements._retry_record_save(old_serial)
	check("superseded retry cannot rotate committed generations",FileAccess.get_file_as_bytes(path)==primary and FileAccess.get_file_as_bytes(path+".bak")==backup)
	write_text(path,"{\"records\":{")
	achievements.records.clear()
	achievements._load_records()
	check("truncated primary recovers previous lifetime records",achievements.last_load_status=="recovered_backup" and achievements.records.get("quick_step")==1234567890 and achievements.records.get("roadrunner")==1234567891)
	check("backup recovery schedules primary repair",achievements._record_save_pending)
	check("repair obstruction created",DirAccess.make_dir_absolute(path+".tmp")==OK)
	check("failed repair preserves good backup",not achievements._save_records() and FileAccess.get_file_as_bytes(path+".bak")==backup)
	check("repair obstruction removed",DirAccess.remove_absolute(path+".tmp")==OK)
	check("repair commits recovered document",achievements._save_records() and disk_records(path).size()==2)
	check("corrupt primary never replaces recovery backup",FileAccess.get_file_as_bytes(path+".bak")==backup)
	write_text(path,"{\"records\":{\"quick_step\":{}}}")
	achievements.records.clear()
	achievements._load_records()
	check("invalid timestamp recovers backup without partial record merge",achievements.last_load_status=="recovered_backup" and achievements.records.size()==2 and achievements.records.get("quick_step")==1234567890)
	check("second corruption can be repaired",achievements._save_records())
	write_text(path+".tmp","{\"records\":{\"first_chip\":999}}")
	achievements.records.clear()
	achievements._load_records()
	check("uncommitted temporary document is never loaded",achievements.last_load_status=="loaded" and not achievements.records.has("first_chip") and achievements.records.size()==2)
	DirAccess.remove_absolute(path+".tmp")
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	var file: FileAccess=FileAccess.open(output_dir.path_join("achievement-recovery.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Real isolated JSON disk faults, bounded retry and previous-good-generation recovery; cannot recover both generations lost or browser storage evicted"},"  "))
	file.close()
	print("EVER_DEEPER_ACHIEVEMENT_RECOVERY_OK" if passed else "EVER_DEEPER_ACHIEVEMENT_RECOVERY_FAILED")
	quit(0 if passed else 2)
