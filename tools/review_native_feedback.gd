extends SceneTree
## Actual native-rendered hero and real notice owners, including steering.
var main: Node
var output: String
var checks: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(name: String, passed: bool) -> void:
	checks.append({"name":name,"passed":passed})
	if not passed: print("NATIVE_FEEDBACK_MISMATCH "+name)

func run() -> void:
	output=OS.get_environment("MODS_OUT")
	if output.is_empty() or DisplayServer.get_name()=="headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for _frame in 5: await process_frame
	var state: Node=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	main._dev_jump_endless(2)
	# Presentation fixture only; earned ownership is tested by the browser
	# lifecycle suite. Select a native tool instead of the 2D original drill.
	state.endless_tool_style="crusher"
	main.quick_tutorial.dismiss()
	main.get_node("MinerTraining").set_process(false)
	var world: Node=main.endless_world
	var player: Node2D=world.player
	player._update_visual(false)
	world.restore_position(Vector2(world.WORLD_SIZE)*0.5)
	world.set_process(false)
	player.set_physics_process(false)
	var skill: Node=main.achievement_toast.get_node("SkillLevelToast")
	var toast: Node=main.achievement_toast
	var feedback: Node=player.get_node("ResourcePickupBurst")
	for width in [667,844]:
		root.size=Vector2i(width*2,750 if width==667 else 780)
		root.content_scale_size=root.size
		for _frame in 8: await process_frame
		toast.clear()
		skill.clear()
		while not feedback.entries.is_empty(): feedback._remove_entry(0)
		main.movement_pad._begin(7,Vector2(240,600))
		main._on_resource_collected("waystone",38)
		main._on_resource_collected("memory_silk",19)
		main._on_resource_collected("deep_alloy",27)
		skill._earned("prospecting",19)
		main._on_achievement_unlocked(root.get_node("GameData").data.ACHIEVEMENT_BY_ID.first_chip)
		await create_timer(0.6).timeout
		main._update_achievement_toast_anchor()
		await process_frame
		await RenderingServer.frame_post_draw
		var rig: Node=player.visual._native_worn.rig
		check(str(width)+" actual native hero visible",is_instance_valid(rig) and rig.sprite.is_visible_in_tree() and not player.visual._sprite.visible)
		var hero: Rect2=rig.sprite.get_global_transform_with_canvas()*rig.sprite.get_rect()
		var skill_rect: Rect2=skill.get_global_transform_with_canvas()*Rect2(skill.card.position,skill.SIZE)
		check(str(width)+" skill visible and clear of hero",skill.is_visible_in_tree() and not skill_rect.intersects(hero))
		var pickup_rects: Array=feedback.screen_rects()
		check(str(width)+" all pickups remain present",pickup_rects.size()==3)
		for index in pickup_rects.size():
			check(str(width)+" pickup "+str(index)+" clears hero and skill",not pickup_rects[index].intersects(hero) and not pickup_rects[index].intersects(skill_rect))
			for other in range(index+1,pickup_rects.size()):
				check(str(width)+" pickup ink frames "+str(index)+" and "+str(other)+" stay separate",not pickup_rects[index].intersects(pickup_rects[other]))
		var toast_rect: Rect2=toast._toast.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,toast._toast.size)
		var steering: Rect2=main.movement_pad.get_global_transform_with_canvas()*main.movement_pad.movement_zone_rect(main.movement_pad.size)
		var was_deferred: bool=not toast._toast.is_visible_in_tree()
		if not was_deferred:
			check(str(width)+" achievement clears hero skill and steering",not toast_rect.intersects(hero) and not toast_rect.intersects(skill_rect) and not toast_rect.intersects(steering))
			for rect in pickup_rects: check(str(width)+" achievement clears pickup",not toast_rect.intersects(rect))
		else:
			var elapsed: float=toast._phase_elapsed
			toast._process(0.5)
			check(str(width)+" crowded achievement retains phase",toast._phase_elapsed==elapsed and toast.is_presenting() and toast._placement_blocked)
		root.get_texture().get_image().save_png(output.path_join("feedback-"+str(width)+".png"))
		FileAccess.open(output.path_join("geometry-"+str(width)+".json"),FileAccess.WRITE).store_string(JSON.stringify({"hero":hero,"skill":skill.snapshot(),"pickups":pickup_rects,"achievement":toast.debug_snapshot(),"steering":steering},"  "))
		main.movement_pad.cancel()
		# A clear slot can open before every notice expires (including when
		# steering is released). Observe rendered resumption independently of
		# notice expiry; waiting for both at once can miss the entire toast.
		var resumed: bool=false
		var notices_expired: bool=false
		var timeline: Array=[]
		var observation_start: int=Time.get_ticks_msec()
		var deadline: int=observation_start+20000
		while Time.get_ticks_msec()<deadline:
			await process_frame
			main._update_achievement_toast_anchor()
			await RenderingServer.frame_post_draw
			var snapshot: Dictionary=toast.debug_snapshot()
			var visible: bool=toast._toast.is_visible_in_tree()
			var clear: bool=not toast._placement_blocked and bool(snapshot.placement_clear)
			var expired_now: bool=feedback.entries.is_empty() and skill.active.is_empty()
			notices_expired=notices_expired or expired_now
			timeline.append({"msec":Time.get_ticks_msec()-observation_start,"visible":visible,"clear":clear,"phase":snapshot.phase,"phase_elapsed":toast._phase_elapsed,"pickups":feedback.entries.size(),"skill_active":not skill.active.is_empty(),"presenting":toast.is_presenting()})
			if visible and clear and toast._phase_elapsed>0.0 and not resumed:
				resumed=true
				root.get_texture().get_image().save_png(output.path_join("feedback-resumed-"+str(width)+".png"))
			if notices_expired and not toast.is_presenting(): break
		FileAccess.open(output.path_join("timeline-"+str(width)+".json"),FileAccess.WRITE).store_string(JSON.stringify({"initially_deferred":was_deferred,"frames":timeline},"  "))
		check(str(width)+" achievement observed visible with advancing phase and clear placement",resumed)
		check(str(width)+" pickups and skill independently expire",notices_expired)
		check(str(width)+" achievement completes normally",not toast.is_presenting())

	var passed: bool=true
	for row in checks: passed=passed and row.passed
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	print("NATIVE_FEEDBACK_OK" if passed else "NATIVE_FEEDBACK_FAILED")
	quit(0 if passed else 1)
