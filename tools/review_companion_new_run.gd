extends SceneTree
## Reused world companions must not retain the previous expedition's work.
var main: Node
var checks: Array=[]
var output_dir: String="user://quality-companion-new-run"

func _initialize() -> void:
	call_deferred("review")

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: print("COMPANION_NEW_RUN_CHECK_FAILED ",label)

func review() -> void:
	if OS.get_environment("XDG_DATA_HOME").is_empty():
		push_error("Set XDG_DATA_HOME to a disposable QA directory before this new-run test")
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
	main.automated_mode=true
	main._start_new_game()
	for i in 3: await process_frame
	main.automated_mode=false
	var state: Node=root.get_node("RunState")
	var ui: Node=main.get_node("CompanionInterface")
	var mole: Node=ui.active_mole()
	var patch: Node=mole.worm_patch
	var worm: Node=patch.spawn_at(mole.global_position)
	check("real surface worm is available",worm!=null)
	if worm==null:
		finish()
		return
	patch.eat(worm)
	check("real worm consumption starts twenty-second boost",ui.worm_power_remaining==20.0 and patch.eaten==1)
	mole.shake_cooldown=7.0
	main._open_start_menu()
	check("pause menu actually opens and suspends hero",main.menu_open and not mole.hero.control_enabled)
	await create_timer(0.2,true,false,true).timeout
	check("pause preserves boost and cooldown",ui.worm_power_remaining==20.0 and mole.shake_cooldown==7.0)
	main._continue_from_menu()
	main._dev_jump_mine("mossMine",1)
	check("ordinary travel preserves active boost",ui.worm_power_remaining==20.0)
	main._dev_jump_surface()
	check("return travel retains previous companion cooldown",mole.shake_cooldown==7.0)
	var previous_seed: int=state.world_seed
	var companions: Array=[]
	var patches: Array=[]
	for phase in ["surface","mine","depth","hub","deepheart","endless"]:
		var world: Node=main.get(phase+"_world")
		var companion: Node=world.get_node("MoleCompanion")
		companions.append({"phase":phase,"node":companion})
		companion.shake_cooldown=7.0
		companion.assist_cooldown=2.0
		companion.collected_total=11
		companion.dug_total=12
		companion.work_hits=13
		companion.path_searches=14
		companion.mode="work"
		companion.work_task={"key":"previous-expedition"}
		companion.work_clock=0.4
		companion.action_clock=0.5
		companion.guide_kind="homeward"
		companion.guide_time=17.0
		companion.marker_time=17.0
		companion.marker.visible=true
		companion.failed_loot={"old-drop":true}
		if is_instance_valid(companion.worm_patch):
			var worms: Node=companion.worm_patch
			# A real retained sprite is sufficient; all other patches still test clocks.
			if phase=="surface": check("old expedition retains a real loose worm",worms.spawn_at(companion.global_position)!=null)
			worms.spawn_clock=0.1
			worms.eaten=3
			patches.append({"phase":phase,"node":worms})
	var achievements: Node=root.get_node("AchievementService")
	achievements.records["first_chip"]=1234567890
	var audio: Node=root.get_node("AudioDirector")
	var music: float=audio.music_volume
	var sfx: float=audio.sfx_volume
	ui.touch_index=9
	ui.web_canceled_touches={9:true}
	main._open_start_menu()
	main._start_new_game()
	check("new expedition has fresh seed",state.world_seed!=previous_seed and main.phase=="surface")
	check("new expedition clears temporary worm boost",ui.worm_power_remaining==0.0)
	check("new expedition clears companion touch ownership",ui.touch_index==-1 and ui.web_canceled_touches.is_empty())
	check("all six loaded companion worlds are covered",companions.size()==6)
	for row in companions:
		var companion: Node=row.node
		check("%s resets action and cooldowns" % row.phase,companion.mode=="follow" and companion.action=="idle" and companion.work_task.is_empty() and companion.work_clock==0.0 and companion.action_clock==0.0 and companion.shake_cooldown==0.0 and companion.assist_cooldown==0.0)
		check("%s resets counters and previous route hints" % row.phase,companion.collected_total==0 and companion.dug_total==0 and companion.work_hits==0 and companion.path_searches==0 and companion.guide_kind.is_empty() and companion.guide_time==0.0 and companion.marker_time==0.0 and not companion.marker.visible and companion.failed_loot.is_empty())
	for row in patches:
		var worms: Node=row.node
		check("%s clears worms and restarts spawn clock" % row.phase,worms.worms.is_empty() and worms.get_child_count()==0 and worms.eaten==0 and worms.spawned==0 and worms.spawn_clock>=4.0 and worms.spawn_clock<=8.0)
	check("lifetime achievement timestamp is retained",achievements.records.get("first_chip")==1234567890)
	check("audio preferences are retained",audio.music_volume==music and audio.sfx_volume==sfx)
	await process_frame
	check("fresh companion rejoins the new hero",ui.active_mole().global_position.distance_to(main.surface_world.player.global_position)<100.0 and ui.worm_power_remaining==0.0)
	finish()

func finish() -> void:
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	var file: FileAccess=FileAccess.open(output_dir.path_join("companion-new-run.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":passed,"checks":checks,"scope":"Real worm consumption, pause/travel retention and New Game reset in all six loaded world companions; lifetime records/audio untouched"},"  "))
	file.close()
	print("EVER_DEEPER_COMPANION_NEW_RUN_OK" if passed else "EVER_DEEPER_COMPANION_NEW_RUN_FAILED")
	quit(0 if passed else 2)
