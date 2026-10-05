extends "res://scripts/qa/suites/guidance_quality_base.gd"
## QA-only observability and explicit fixture placement. Inputs remain real CDP touch.
func _review_clear_toasts() -> bool:
	return false if "--guidance-review" in OS.get_cmdline_user_args() else super._review_clear_toasts()
func _command(data: Dictionary) -> void:
	match String(data.kind):
		"guidance_record_only":
			RunState.record_mined("stone",1)
			command_id=int(data.id);return
		"guidance_resume":
			main._open_start_menu();main._continue_from_menu()
			command_id=int(data.id);return
		"guidance_fund":
			RunState.gold=int(RunState.next_pickaxe().cost)
			RunState._state_changed()
			command_id=int(data.id);return
		"guidance_reload":
			main.persistence_active=true
			RunState.initialize_persistence("user://guidance-review.sav")
			main._checkpoint_location();RunState.flush_save()
			command_id=int(data.id);return
	super._command(data)
func run() -> void:
	if "--guidance-persistence" in OS.get_cmdline_user_args():
		main.save_available=RunState.initialize_persistence("user://guidance-review.sav")
		main.persistence_active=true;main.automated_mode=false
		main._open_start_menu();main.get_tree().process_frame.connect(_frame)
		previous_usec=Time.get_ticks_usec();return
	super.run()
func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var t: Node=main.quick_tutorial
	var g: Dictionary=t.debug_snapshot()
	g["focus"]=_guidance_rect(g.focus_rect);g.erase("focus_rect")
	g["panel"]=_guidance_rect(g.strip_rect);g.erase("strip_rect")
	g["skip"]=_guidance_rect(g.skip_rect);g.erase("skip_rect")
	g["seen"]=t.has_been_seen()
	g["goal"]=main.premium_hud.progression_goal_panel.snapshot()
	g["distance"]=t._distance
	g["cargo"]=RunState.cargo_count()
	g["mined"]=RunState.total_mined_resources()
	g["pickaxe"]=RunState.pickaxe_level
	g["context"]=main.premium_hud.context_button.text
	g["world_target"]=main.guide_director.locked_target_key
	g["local_action"]=is_instance_valid(main.guide_overlay.action_control)
	g["achievement"]=main.achievement_toast.debug_snapshot()
	g["texts"]={}
	for pair in [["title",main.premium_hud.progression_goal_panel._title],["action",main.premium_hud.progression_goal_panel._action]]:
		var label: Label=pair[1]
		g.texts[pair[0]]={"text":label.text,"rect":_screen_bounds(label),"fits":label.get_theme_font("font").get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,label.get_theme_font_size("font_size")).x<=label.size.x}
	JavaScriptBridge.eval("window.DEV14_STATE.guidance="+JSON.stringify(g)+";window.DEV14_STATE.buttons.guidance_skip="+JSON.stringify(g.skip)+";",true)

func _guidance_rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
