extends SceneTree
## Earn current achievements through real training; retain legacy unlock records.
const Skills=preload("res://scripts/progression/miner_skills.gd")
var state: Node
var achievements: Node
var checks: Array=[]
var unlocks: Array[String]=[]
var output_dir: String="user://quality-running-achievements"

func _initialize() -> void:
	call_deferred("review")

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("RUNNING_ACHIEVEMENT_CHECK_FAILED ",label)

func settle() -> void:
	await create_timer(0.35,true,false,true).timeout

func review() -> void:
	if OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Set XDG_DATA_HOME to a disposable QA directory before achievement persistence tests")
		quit(2)
		return
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output_dir=argument.trim_prefix("--output=")
	output_dir=ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(output_dir)
	state=root.get_node("RunState")
	achievements=root.get_node("AchievementService")
	achievements.achievement_unlocked.connect(func(definition: Dictionary): unlocks.append(String(definition.id)))
	state.reset_run(false)
	achievements.records.clear()
	await settle()
	state._earn_miner_xp("running",Skills.threshold("running",1)-0.25)
	await settle()
	check("no premature Running 1 unlock",not achievements.is_unlocked("quick_step"))
	state._earn_miner_xp("running",0.25)
	await settle()
	check("actual Running 1 event unlocks Quick Step",achievements.is_unlocked("quick_step") and not achievements.is_unlocked("roadrunner"))
	check("Running skill route needs no retired speed purchase",state.movement_speed_level==0)
	state._earn_miner_xp("running",Skills.threshold("running",10)-float(state.miner_skills.running)-0.25)
	await settle()
	check("no premature Running 10 unlock",not achievements.is_unlocked("roadrunner"))
	state._earn_miner_xp("running",0.25)
	await settle()
	check("actual Running 10 event unlocks Roadrunner",achievements.is_unlocked("roadrunner"))
	check("each newly earned achievement fires once",unlocks.count("quick_step")==1 and unlocks.count("roadrunner")==1)
	achievements.records["quick_step"]=1234567890
	achievements.records["roadrunner"]=1234567891
	achievements._save_records()
	achievements.records.clear()
	achievements._load_records()
	state.reset_run(false)
	await settle()
	check("legacy unlock timestamps survive disk reload and new run",achievements.records.get("quick_step")==1234567890 and achievements.records.get("roadrunner")==1234567891)
	achievements.records.clear()
	state.movement_speed_level=1
	achievements.evaluate()
	check("legacy first speed purchase remains eligible",achievements.is_unlocked("quick_step") and not achievements.is_unlocked("roadrunner") and state.miner_skill_level("running")==0)
	state.movement_speed_level=10
	achievements.evaluate()
	check("legacy ten speed purchases remain eligible",achievements.is_unlocked("roadrunner"))
	var descriptions: Dictionary={}
	for definition in achievements.definitions(): descriptions[String(definition.id)]=String(definition.description)
	check("authored descriptions explain current obtainable targets",descriptions.get("quick_step")=="Reach Running level 1." and descriptions.get("roadrunner")=="Reach Running level 10.")
	var data: Dictionary=root.get_node("GameData").data
	check("achievement lookup descriptions agree with display catalog",data.ACHIEVEMENT_BY_ID.quick_step.description==descriptions.quick_step and data.ACHIEVEMENT_BY_ID.roadrunner.description==descriptions.roadrunner)
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	var file: FileAccess=FileAccess.open(output_dir.path_join("running-achievements.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Real level-up event, thresholds, legacy eligibility and isolated record disk persistence; no visual claim"},"  "))
	file.close()
	print("EVER_DEEPER_RUNNING_ACHIEVEMENTS_OK" if passed else "EVER_DEEPER_RUNNING_ACHIEVEMENTS_FAILED")
	quit(0 if passed else 2)
