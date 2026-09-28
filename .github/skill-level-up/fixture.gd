var skill_events: Array = []
func _on_skill_event(id: String, level: int) -> void:
	skill_events.append({"id":id,"level":level})

func _command(data: Dictionary) -> void:
	command_id = int(data.id)
	match String(data.kind):
		"skill_setup":
			_original_command({"kind":"setup","id":data.id,"mine":"starMine","durable":true})
			skill_events.clear()
			RunState.miner_skills.mining = 96.0
			RunState._miner_level_cache.clear()
		"skill_burst":
			RunState._earn_miner_xp("running",100.0)
			RunState._earn_miner_xp("running",150.0)
			RunState._earn_miner_xp("carrying",100.0)
			RunState._earn_miner_xp("prospecting",100.0)
		"skill_load":
			var saved: Dictionary = RunState.serialize()
			_require(RunState.deserialize(saved),"Reload failed")
		"skill_cap":
			RunState._earn_miner_xp("mining",RunState.MinerSkills.MAX_XP)
			RunState._earn_miner_xp("mining",4.0)
		"skill_pause": main._open_start_menu()
		"skill_resume": main._continue_from_menu()
		_: _original_command(data)

func _skill_frame() -> void:
	if not RunState.miner_skill_increased.is_connected(_on_skill_event):
		RunState.miner_skill_increased.connect(_on_skill_event)
	var toast: Node = main.achievement_toast.get_node_or_null("SkillLevelToast")
	if toast != null:
		JavaScriptBridge.eval("window.SKILL_STATE="+JSON.stringify({"toast":toast.snapshot(),"events":skill_events}),true)
