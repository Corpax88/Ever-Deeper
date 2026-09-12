extends RefCounted

var failures: Array[String]=[]
var checks: int=0
var driver: Node
var main: Node

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures.append(label)
		print("OVERHAUL_CHECK_FAILED ",label)

func run(capture_driver: Node,main_node: Node) -> bool:
	driver=capture_driver
	main=main_node
	if "--qa-mobile-layout" in OS.get_cmdline_user_args():
		driver.get_tree().root.content_scale_size=Vector2i(1560,720)
		driver.get_tree().root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	await driver.get_tree().process_frame
	check(driver.call("_check_surface_gameplay"),"Approved Mossvein surface route/mining/regrowth")
	_test_skills()
	_test_d1_barriers()
	_test_d2_barriers()
	_test_depth_commerce()
	_test_surface_and_guide()
	_test_endless_dig()
	_test_companion()
	_test_pet_revision()
	await _test_path_and_touch()
	print("EVER_DEEPER_OVERHAUL_GAMEPLAY_%s checks=%d failures=%s" % ["OK" if failures.is_empty() else "FAILED",checks,JSON.stringify(failures)])
	return failures.is_empty()

func _test_skills() -> void:
	driver.call("_reset_run")
	check(MoleSkills.SKILLS.size()==10,"Ten distinct skills")
	check(MoleSkills.has_skill("fetch") and MoleSkills.has_skill("lantern"),"Useful companion from start")
	check(not MoleSkills.learn("shake"),"Cannot bypass prerequisites or price")
	RunState.gold=10000
	MoleSkills.earn(1000)
	var expected_gold: int=RunState.gold
	var expected_bond: int=MoleSkills.bond()
	for skill in MoleSkills.SKILLS:
		var id: String=String(skill.id)
		if id in ["lantern","fetch"]: continue
		expected_gold-=int(skill.gold)
		expected_bond-=int(skill.bond)
		check(MoleSkills.learn(id),"Learn "+id)
		check(not MoleSkills.learn(id),"No duplicate purchase "+id)
		check(RunState.gold==expected_gold and MoleSkills.bond()==expected_bond,"Exact skill accounting "+id)
	var saved: Dictionary=RunState.serialize()
	RunState.reset_run(false)
	check(RunState.deserialize(saved),"Skill save reload")
	for skill in MoleSkills.SKILLS: check(MoleSkills.has_skill(String(skill.id)),"Learned skill persists "+String(skill.id))
	check(MoleSkills.bond()==expected_bond,"Bond persists")
	var legacy: Dictionary=saved.duplicate(true)
	legacy.state.erase("overhaul")
	check(RunState.deserialize(legacy) and MoleSkills.has_skill("fetch"),"Legacy save has working starter companion")

func _test_d1_barriers() -> void:
	for definition in driver.DEPTH_ONE_BARRIERS:
		var id: String=String(definition.barrier_id)
		var mine_id: String=String(definition.mine_id)
		var world: Node=driver.call("_load_d1",mine_id)
		world.set_process(false)
		var cells: Array[Vector2i]=driver.call("_d1_barrier_cells",world,id,true)
		check(not cells.is_empty(),"D1 barrier exists "+id)
		if cells.is_empty(): continue
		var cell: Vector2i=cells[0]
		var required: int=int(world.blocks[cell].requires_tool)
		world.current_target=cell
		RunState.pickaxe_level=maxi(0,required-1)
		world.call("_mine_once")
		check(RunState.barrier_hits(mine_id+":d1:"+id)==0,"D1 lock respected "+id)
		for level in range(1,6):
			RunState.pickaxe_level=level
			world.call("_start_swing")
			check(is_equal_approx(world.swing_duration,0.60),"Fixed D1 cadence "+id+":"+str(level))
		RunState.pickaxe_level=5
		for variant in ["crusher","swift","prospector"]:
			RunState.starforge_variant=variant
			world.call("_start_swing")
			check(is_equal_approx(world.swing_duration,0.60),"Core cannot accelerate barrier "+variant)
		for level in range(1,4):
			RunState.drill_level=level
			world.call("_start_swing")
			check(is_equal_approx(world.swing_duration,0.60),"Drill cannot accelerate barrier "+str(level))
		RunState.drill_level=0
		for hit in range(1,11):
			world.current_target=cell
			world.call("_mine_once")
			var remaining: Array[Vector2i]=driver.call("_d1_barrier_cells",world,id,true)
			check((remaining.size()==cells.size()) if hit<10 else remaining.is_empty(),"D1 opens exactly at ten "+id+":"+str(hit))
			if hit==4:
				var saved: Dictionary=RunState.serialize()
				check(RunState.deserialize(saved) and RunState.barrier_hits(mine_id+":d1:"+id)==4,"Partial D1 save "+id)
		world.call("_configure_mine",mine_id)
		var restored: Array[Vector2i]=driver.call("_d1_barrier_cells",world,id,true)
		check(restored.is_empty(),"D1 cleared barrier stays open "+id)

func _test_d2_barriers() -> void:
	for profile in driver.MINE_PROFILES:
		var mine_id: String=String(profile.mine_id)
		for gate_index in int(profile.gate_count):
			check(driver.call("_prepare_d2_gate",mine_id,gate_index,"intact"),"D2 gate reachable fixture")
			var world: Node=main.depth_world
			world.set_process(false)
			var gates: Array=world.call("get_drill_gates")
			var gate: Dictionary=gates[gate_index]
			var id: String=String(gate.id)
			var target: int=-1
			for i in world.rocks.size():
				if String(world.rocks[i].deposit_id)==id and world.call("_rock_is_exposed",i):
					target=i
					break
			check(target>=0,"D2 gate exposed "+id)
			if target<0: continue
			RunState.pickaxe_level=5
			RunState.starforge_variant="crusher"
			RunState.drill_level=maxi(0,int(gate.required_drill_level)-1)
			check(not world.call("_hit_rock",target),"D2 drill lock "+id)
			RunState.drill_level=int(gate.required_drill_level)
			world.current_target_kind="rock"
			world.current_target_rock=target
			for variant in ["crusher","swift","prospector"]:
				RunState.starforge_variant=variant
				world.call("_start_swing",true)
				check(is_equal_approx(world.swing_duration,0.60),"D2 fixed cadence "+id+":"+variant)
			for hit in range(1,11):
				check(world.call("_hit_rock",target),"D2 actual hit "+id+":"+str(hit))
				var current: Dictionary=world.call("get_drill_gates")[gate_index]
				check(int(current.remaining)>0 if hit<10 else int(current.remaining)==0,"D2 opens exactly at ten "+id+":"+str(hit))
				if hit==4:
					var saved: Dictionary=RunState.serialize()
					check(RunState.deserialize(saved) and RunState.barrier_hits(mine_id+":d2:"+id)==4,"Partial D2 save "+id)
					world.call("_build_rocks")
					check(int(world.rocks[target].hp)<int(world.rocks[target].max_hp),"Partial D2 damage restored "+id)
			world.call("_build_rocks")
			world.call("_update_rocks")
			check(int(world.call("get_drill_gates")[gate_index].remaining)==0,"D2 cleared gate never regrows "+id)

func _test_depth_commerce() -> void:
	for profile in driver.MINE_PROFILES:
		var world: Node=driver.call("_load_d2",String(profile.mine_id))
		world.set_process(false)
		check(not world.call("collision_at",world.wayfarer_position),"Walkable Depth 2 boots "+String(profile.tag))
		RunState.starforge_variant="crusher"
		RunState.drill_level=0
		RunState.gold=100000
		for kind in RunState.cargo: RunState.cargo[kind]=10000
		for level in range(1,4):
			var config: Dictionary=CommerceCatalog.depth_forge_config(String(profile.mine_id))
			check(ResourceLoader.exists(String(config.items[0].texture)),"Authored drill texture "+str(level))
			var status: Dictionary=RunState.drill_upgrade_status()
			var before_gold: int=RunState.gold
			check(RunState.upgrade_drill(),"Buy drill "+str(level))
			check(RunState.drill_level==level and RunState.gold==before_gold-int(status.recipe.gold),"Exact drill cost "+str(level))
		check(not RunState.upgrade_drill(),"Completed drills cannot charge again")
		main.call("_open_commerce",CommerceCatalog.depth_forge_config(String(profile.mine_id)),"depth_forge")
		check(not bool(world.player.control_enabled) and not world.is_processing(),"Depth store pauses mining")
		main.commerce_panel.close_commerce()
		check(bool(world.player.control_enabled),"Closing depth store restores control")
		RunState.cargo["deep_alloy"]=5
		RunState.cargo["stone"]=4
		var value: int=int(RunState.assay_sale_snapshot().total)
		var gold: int=RunState.gold
		world.active_context="depthSell"
		main.call("_on_depth_context_changed","depthSell")
		check(RunState.gold==gold+value and int(RunState.cargo.deep_alloy)==5,"Walkover assay sells once and protects progression")
		main.call("_on_depth_context_changed","depthSell")
		check(RunState.gold==gold+value,"No duplicate walkover sale")

func _test_endless_dig() -> void:
	for layer in [1,2,3,4,5]:
		check(driver.call("_prepare_endless_walls",layer),"The Deep layer setup "+str(layer))
		var world: Node=main.endless_world
		world.set_process(false)
		var cell: Vector2i=world.call("_nearest_diggable_wall")
		check(cell.x>=0,"Ordinary wall can be targeted "+str(layer))
		if cell.x<0: continue
		var resources: Dictionary=_endless_resource_identities(world)
		# 1.0 ordinary rock responds to actual upgraded tool damage. The prior
		# fixed three-hit rule intentionally no longer applies (see QA review).
		var duration: float = float(world.call("_mining_cycle_duration"))
		world.call("_cancel_mining")
		world.call("_update_wall_mining", duration * 0.2)
		check(not bool(world.call("_is_floor",cell)) and int(world.dig_damage.get(cell,0)) == 0,"Free dig waits for physical contact "+str(layer))
		world.call("_update_wall_mining", duration * 0.65)
		check(bool(world.call("_is_floor",cell)) or int(world.dig_damage.get(cell,0)) > 0,"Physical impact applies real tool damage "+str(layer))
		for _hit in range(16):
			if bool(world.call("_is_floor",cell)): break
			world.call("_update_wall_mining",duration+0.01)
		check(bool(world.call("_is_floor",cell)),"Equipped tool opens ordinary rock "+str(layer))
		var depth: int=int(world.call("depth_at_position",world.call("_cell_center",cell)))
		var index: int=int(world.call("_chunk_cell_index",cell))
		var absolute: Vector2i=Vector2i(world.call("absolute_cell",cell))
		check(RunState.endless_dug_cells(depth).has(index),"Free dig saved "+str(layer))
		var saved: Dictionary=RunState.serialize()
		check(RunState.deserialize(saved),"The Deep save reload")
		world.call("_generate_depth",depth,"up")
		var restored_cell: Vector2i=absolute-Vector2i(0,(int(world.window_start_depth)-1)*22)
		check(bool(world.call("_is_floor",restored_cell)),"Free dig survives reentry "+str(layer))
		check(_endless_resource_identities(world)==resources,"Free dig preserves resource identities "+str(layer))
		check(not world.call("companion_can_dig",Vector2(32,32)),"Permanent outer wall protected")

func _endless_resource_identities(world: Node) -> Dictionary:
	# HP/depletion legitimately change when the restored Crusher shockwave hits
	# nearby deposits; their generated identity and absolute position must not.
	var result: Dictionary = {}
	for value in world.resources:
		result[String(value.id)] = {"kind":String(value.kind),"amount":int(value.amount),
			"cell":Vector2i(world.call("absolute_cell",Vector2i(value.cell)))}
	return result

func _test_companion() -> void:
	var world: Node=driver.call("_load_d1","mossMine")
	world.set_process(false)
	world.player.set_physics_process(false)
	world.player.control_enabled=true
	var mole: MoleCompanion=world.get_node("MoleCompanion")
	mole.set_physics_process(false)
	mole.call("_spawn_beside_hero")
	mole.was_active=true
	check(not mole.call("_blocked",mole.global_position),"Companion spawns on walkable floor")
	check(not mole.command(world.player.global_position+Vector2(900,0)),"Companion command range respected")
	var barrier: Array[Vector2i]=driver.call("_d1_barrier_cells",world,"outer_rubble",true)
	if not barrier.is_empty():
		check(not world.call("companion_can_dig",world.call("_cell_center",barrier[0])),"Companion cannot bypass sealed barriers")
	var cell: Vector2i=world.call("_world_to_cell",mole.global_position)
	world.call("_spawn_drop",cell,"copper",3)
	for i in world.drops.size(): world.drops[i].age=1.0
	var position: Vector2=world.drops[-1].position
	mole.global_position=position
	mole.mode="fetch"
	mole.action="pickup"
	mole.action_clock=0.0
	var before: int=int(RunState.cargo.copper)
	mole.call("_update_action",0.49)
	check(int(RunState.cargo.copper)==before,"Pickup animation precedes credit")
	mole.call("_update_action",0.02)
	check(int(RunState.cargo.copper)==before+3 and mole.collected_total>=3,"Pickup secures actual ore")
	mole.call("_update_action",0.1)
	check(int(RunState.cargo.copper)==before+3,"Pickup cannot credit twice")
	check(int(world.call("companion_collect_loot",position,64.0))==0,"Shared loot claim cannot duplicate")
	check(MoleSkills.bond()==3,"Bond earned only from collected ore")
	var light: Dictionary=mole.lamp.debug_snapshot()
	check(bool(light.occluded) and bool(light.shadow_origin_preserved),"Mole helmet shadow emitter stays at the helmet; texture margins may be cropped")
	check(is_equal_approx(mole.lamp.beam_light.energy,0.72),"Companion lamp energy stable")
	for action in ["walk","pickup","shake"]:
		for direction in [Vector2.DOWN,Vector2.RIGHT,Vector2.UP,Vector2.LEFT]:
			mole.action=action
			mole.facing=direction
			var seen: Dictionary={}
			for frame in range(4):
				mole.animation_clock=float(frame)/8.0
				mole.action_clock=float(frame)*(0.18 if action=="pickup" else 0.21)+0.01
				mole.call("_draw_pose")
				seen[mole.sprite.frame]=true
			check(seen.size()==4,"Four authored directional frames "+action+str(direction))

func _test_path_and_touch() -> void:
	var world: Node=driver.call("_load_d1","mossMine")
	world.set_process(false)
	world.player.set_physics_process(false)
	world.player.control_enabled=true
	# An ordinary room and one rock partition exercise the real collision/path code.
	var center: Vector2i=Vector2i(int(world.cols)/2,int(world.rows)/2)
	world.mine.barriers=[]
	for y in range(center.y-4,center.y+5):
		for x in range(center.x-6,center.x+7):
			world.blocks.erase(Vector2i(x,y))
	for y in range(center.y-3,center.y+2):
		world.blocks[Vector2i(center.x,y)]=world.call("_make_block","stone",20,0,"terrain")
	world.call("_rebuild_role_counts")
	var start: Vector2=world.call("_cell_center",center+Vector2i(-3,0))
	var goal: Vector2=world.call("_cell_center",center+Vector2i(3,0))
	world.player.global_position=start
	world.player.camera.position_smoothing_enabled=false
	world.player.camera.reset_smoothing()
	var mole: MoleCompanion=world.get_node("MoleCompanion")
	mole.set_physics_process(false)
	mole.global_position=start
	mole.was_active=true
	mole.visible=true
	check(not mole.call("_segment_clear",start,goal),"Rock partition blocks direct companion travel")
	check(mole.command(goal),"Accept reachable command")
	var crossed_wall: bool=false
	for step in range(420):
		mole.call("_physics_process",1.0/60.0)
		if world.call("_player_collides",mole.global_position): crossed_wall=true
	check(not crossed_wall,"Companion never crosses solid wall")
	check(mole.global_position.distance_to(goal)<12.0,"Companion follows tunnel around partition")
	var ui: Node=main.get_node("CompanionInterface")
	await driver.get_tree().process_frame
	ui.call("_process",0.0)
	for frame in range(3): await driver.get_tree().process_frame
	world.player.camera.force_update_scroll()
	# Earlier fixtures award achievements; isolate ground gestures from their UI.
	main.achievement_toast.clear()
	mole.call("recall")
	var click_target: Vector2=start+Vector2(48,-144)
	var command_canvas: Transform2D=world.get_canvas_transform()
	var screen_point: Vector2=command_canvas*click_target
	var dispatched_point: Vector2=await _send_gesture(screen_point,"tap")
	click_target=command_canvas.affine_inverse()*dispatched_point
	check(mole.mode=="command" and mole.destination.distance_to(click_target)<1.0,"Real screen tap routes through UI to companion")
	mole.call("recall")
	await _send_gesture(screen_point,"drag_return")
	check(mole.mode=="follow","Dragging back to the start does not command companion")
	# Keep cancellation independent even when the preceding drag assertion fails.
	mole.call("recall")
	await _send_gesture(screen_point,"cancel")
	check(mole.mode=="follow","Canceled touch does not command companion")
	var left_target: Vector2=start+Vector2(-144,144)
	command_canvas=world.get_canvas_transform()
	dispatched_point=await _send_gesture(command_canvas*left_target,"tap")
	left_target=command_canvas.affine_inverse()*dispatched_point
	check(mole.mode=="command" and mole.destination.distance_to(left_target)<1.0,"Tap inside movement zone commands companion")
	check(main.movement_pad.active_pointer==-2 and main.button_move==Vector2.ZERO,"Companion command also releases the movement joystick")
	mole.call("recall")
	var portrait_point: Vector2=ui.button.get_global_transform_with_canvas()*(ui.button.size*0.5)
	check(ui.button.is_visible_in_tree(),"Companion portrait is available on the touch HUD")
	await _send_gesture(portrait_point,"tap")
	check(mole.mode=="follow" and main.call("_companion_panel_is_open") and not main.call("_commerce_panel_is_open") and String(main.commerce_context)=="companion","UI tap opens skills without commanding companion")
	ui.journal.close_journal()
	var point: Vector2=world.call("_cell_center",center+Vector2i(0,1))
	check(not mole.command(point),"Earthshaker is locked before learning")
	RunState.overhaul_progress={"skills":{"shake":1}}
	mole.global_position=world.call("_cell_center",center+Vector2i(-1,1))
	check(mole.command(point),"Learned Earthshaker accepts ordinary wall")
	for step in range(180): mole.call("_physics_process",1.0/60.0)
	check(mole.dug_total>=1 and mole.dug_total<=4,"Earthshaker opens at most 2x2 ordinary cells")
	check(mole.shake_cooldown>0.0 and mole.shake_cooldown<=8.0,"Earthshaker has a real recharge")

func _send_gesture(point: Vector2,kind: String) -> Vector2:
	if OS.has_feature("web"):
		# Actual browser touch events exercise the same route as an iPhone.
		driver.set("_acknowledged",false)
		driver.set("_waiting_for_ack",true)
		var size: Vector2=driver.get_viewport().get_visible_rect().size
		# Browser touch dispatch quantizes client coordinates to CSS pixels. Choose
		# that actual pixel before dispatch, then assert its exact world identity.
		# This preserves the strict command tolerance instead of relaxing the gate.
		var raw: Variant=JSON.parse_string(String(JavaScriptBridge.eval("JSON.stringify((()=>{const r=document.getElementById('canvas').getBoundingClientRect();return {x:r.x,y:r.y,width:r.width,height:r.height};})())",true)))
		check(raw is Dictionary,"Browser gesture has actual canvas CSS bounds")
		if raw is Dictionary:
			var canvas: Rect2=Rect2(float(raw.get("x",0)),float(raw.get("y",0)),float(raw.get("width",0)),float(raw.get("height",0)))
			check(canvas.has_area(),"Browser canvas CSS bounds have area")
			if canvas.has_area():
				var client: Vector2=(canvas.position+point/size*canvas.size).round()
				point=(client-canvas.position)/canvas.size*size
		print("EVER_DEEPER_OVERHAUL_INPUT_READY ",JSON.stringify({"kind":kind,"x":point.x,"y":point.y,"width":size.x,"height":size.y}))
		if not await driver.call("_wait_for_ack"): failures.append("Browser gesture acknowledgement timed out")
		var ui: Node=main.get_node("CompanionInterface")
		var mole: MoleCompanion=ui.call("active_mole")
		print("OVERHAUL_INPUT_RESULT ",JSON.stringify({"kind":kind,"touch_start":str(ui.touch_start),"mode":mole.mode,"destination":str(mole.destination),"visible":ui.button.visible}))
		return point
	var press: InputEventScreenTouch=InputEventScreenTouch.new()
	press.index=12
	press.pressed=true
	press.position=point
	driver.get_viewport().push_input(press,true)
	if kind=="drag_return":
		for offset in [Vector2(48,0),Vector2.ZERO]:
			var motion: InputEventScreenDrag=InputEventScreenDrag.new()
			motion.index=12
			motion.position=point+offset
			motion.relative=Vector2(48,0) if offset!=Vector2.ZERO else Vector2(-48,0)
			driver.get_viewport().push_input(motion,true)
	var release: InputEventScreenTouch=InputEventScreenTouch.new()
	release.index=12
	release.position=point
	release.canceled=kind=="cancel"
	driver.get_viewport().push_input(release,true)
	return point

func _test_surface_and_guide() -> void:
	for gate in ["moonglass","emberdeep","starfall"]:
		driver.call("_reset_run")
		main.call("_dev_jump_surface")
		var world: Node=main.surface_world
		world.reset_for_new_run()
		var x: float={"moonglass":1110.0,"emberdeep":2240.0,"starfall":3360.0}[gate]
		check(world.call("_surface_collides",Vector2(x,650)),"Locked surface gate blocks "+gate)
		for zone in ["moonglass","emberdeep","starfall"]:
			RunState.unlock_world(zone)
			world.call("_sync_portal_transition",zone,true,false)
			world.portal_transitions[zone].call("_process",2.0)
		var route: Array=[Vector2(x-270,650),Vector2(x-120,680),Vector2(x,650),Vector2(x+160,610),Vector2(x+250,650)]
		for backwards in [false,true]:
			var points: Array=route.duplicate()
			if backwards: points.reverse()
			var position: Vector2=points[0]
			for target in points.slice(1):
				position=world.call("_resolve_motion",position,Vector2(target)-position)
				check(position.distance_to(Vector2(target))<1.0,"Surface arch passage "+gate+":"+str(backwards))
		var id: String=gate+"_mountain"
		var mountain_x: float={"moonglass":1665.0,"emberdeep":2820.0,"starfall":3900.0}[gate]
		world.restore_position(Vector2(mountain_x,620.0 if gate=="moonglass" else 650.0))
		world.call("_evaluate_context",world.player.global_position)
		check(String(world.active_context)==id,"Later mountain target is reachable "+gate)
		var limit: int=1000
		while int(world.surface_resource_mountains[id].hp)>0 and limit>0:
			world.call("_mine_surface_resource_mountain_once",id)
			limit-=1
		check(limit>0 and int(world.surface_resource_mountains[id].hp)==0,"Later mountain mines completely "+gate)
		world.call("_apply_surface_resource_mountain_regrowth",id,150.0)
		check(int(world.surface_resource_mountains[id].hp)==360,"Later mountain regrows "+gate)
	var guide: GuideDirector=GuideDirector.new()
	driver.call("_reset_run")
	main.call("_dev_seed_all_zones_state")
	RunState.drill_level=0
	RunState.starforge_variant="crusher"
	RunState.hub["visited"]=false
	RunState.hub["tutorialSeen"]=false
	var first: Dictionary=guide.goal_for_state()
	check(String(first.get("objective_id",""))=="hub:first_visit","Starforge leads to the hub first")
	main.call("_dev_jump_surface")
	var stale_hub: Dictionary=RunState.hub_state_snapshot()
	main.call("_enter_hub")
	check(String(main.phase)=="hub","Starforge player enters the actual Hub")
	check(not RunState.hub_tutorial_pending(),"Entering the Hub completes its guide step")
	check(String(guide.goal_for_state().get("objective_id",""))=="drill:1","Hub visit immediately guides toward the first drill")
	main.call("_checkpoint_location")
	check(not RunState.hub_tutorial_pending(),"Hub checkpoint cannot reset its completed guide")
	main.call("_exit_hub")
	check(String(main.phase)=="surface" and not RunState.hub_tutorial_pending(),"Leaving the Hub does not restart its guide")
	main.call("_enter_hub")
	check(not RunState.hub_tutorial_pending(),"Reentering the Hub keeps its guide complete")
	RunState.mark_hub_build_tutorial_seen()
	RunState.commit_hub_runtime_state(stale_hub,RunState.base_state_snapshot(),RunState.hub_economy_snapshot())
	check(bool(RunState.hub.get("visited",false)) and not RunState.hub_tutorial_pending(),"Stale runtime state cannot erase the Hub visit")
	check(bool(RunState.hub.get("buildTutorialSeen",false)),"Stale runtime state cannot erase the building tutorial")
	var hub_save: Dictionary=RunState.serialize()
	RunState.reset_run(false)
	check(RunState.deserialize(hub_save) and not RunState.hub_tutorial_pending(),"Completed Hub guide survives save reload")
	hub_save.state.hub["tutorialSeen"]=false
	check(RunState.deserialize(hub_save) and not RunState.hub_tutorial_pending(),"Already visited legacy save recovers from the Hub loop")
	check(String(RunState.starforge_variant)=="crusher" and RunState.gold==int(hub_save.state.gold),"Hub recovery preserves equipment and gold")
	hub_save.state.hub["visited"]=false
	check(RunState.deserialize(hub_save) and RunState.hub_tutorial_pending(),"An unvisited Hub still receives its first guide step")
	main.call("_enter_hub",false,false)
	check(not RunState.hub_tutorial_pending(),"Restoring inside the Hub completes a pending visit")
	main.call("_exit_hub")
	RunState.gold=10000
	for kind in RunState.cargo: RunState.cargo[kind]=0
	for level in range(3):
		RunState.drill_level=level
		var next: Dictionary=guide.goal_for_state()
		check(String(next.get("subtitle",next.get("detail",""))).contains("Depth 2"),"Guide names exact depth for drill "+str(level+1))

func _test_pet_revision() -> void:
	var world: Node=driver.call("_load_d1","mossMine")
	world.set_process(false)
	world.player.set_physics_process(false)
	world.player.control_enabled=true
	var mole: MoleCompanion=world.get_node("MoleCompanion")
	mole.set_physics_process(false)
	mole.call("_spawn_beside_hero")
	var before: int=MoleSkills.bond()
	RunState.record_mined("copper",5)
	check(MoleSkills.bond()==before+5,"Hero mining earns paw points even when hero claims the drops")
	check(not RunState.record_mined("fake_ore",20) and MoleSkills.bond()==before+5,"Invalid mining cannot award paw points")
	var save: Dictionary=RunState.serialize()
	RunState.overhaul_progress={}
	check(RunState.deserialize(save) and MoleSkills.bond()==before+5,"New paw progress persists in existing save schema")
	RunState.overhaul_progress={"skills":{"long_beam":1,"big_paws":1,"trailrunner":1,"shake":1}}
	mole.call("_think")
	check(is_equal_approx(mole.lamp.base_beam_length,440.0),"Long Beam doubles actual light reach")
	var origin: Vector2=mole.global_position
	var cell: Vector2i=world.call("_world_to_cell",origin)
	world.call("_spawn_drop",cell,"copper",2)
	world.drops[-1].position=origin+Vector2(75,0)
	world.drops[-1].age=1.0
	var before_ore: int=int(RunState.cargo.copper)
	mole.action="pickup";mole.action_clock=0.0
	mole.call("_update_action",0.51)
	check(int(RunState.cargo.copper)==before_ore+2,"Big Paws really collects an ore cluster 75 units away")
	mole.call("_update_action",0.10)
	check(int(RunState.cargo.copper)==before_ore+2,"Celebration cannot duplicate pickup")
	check(mole.feedback.contains("Got 2"),"Pickup explains its actual result")
	mole.mode="hold";mole.hold_time=6.5;mole.call("_think")
	check(mole.mode!="hold","Mole resumes helping after lighting a commanded spot")
	mole.recall();mole.shake_cooldown=3.0
	check(not mole.shake_nearby(),"Command cannot bypass dig recharge")
	var ui: Node=main.get_node("CompanionInterface")
	ui.open_skills()
	check(ui.journal.visible and not main.commerce_panel.visible,"Companion owns a separate journal, not the shop")
	check(not world.player.control_enabled and not ui.call("_ground_input_enabled"),"Journal pauses movement and prevents commands behind it")
	for tab in ["together","skills","how"]:
		ui.journal.select_tab(tab)
		check(ui.journal.tab==tab and ui.journal.body.get_child_count()>0,"Journal tab renders "+tab)
	var journal = ui.journal
	var pet_progress: Dictionary = RunState.overhaul_progress.duplicate(true)
	for reaction in journal.PET_REACTIONS.size():
		journal.play_pet_reaction(reaction)
		check(journal.pet_frames.size() == 8 and journal.portrait.texture_normal is AtlasTexture, "Pet reaction has eight real frames: " + journal.PET_REACTIONS[reaction])
		journal.call("_advance_pet_reaction", 0.40)
		check(journal.portrait.texture_normal == journal.pet_frames[2], "Pet animation advances its actual portrait: " + journal.PET_REACTIONS[reaction])
		journal.call("_pet")
		check(journal.pet_reaction == reaction and is_equal_approx(journal.pet_elapsed, 0.40), "Rapid pet taps cannot restart or queue animations")
		journal.call("_advance_pet_reaction", 2.0)
		check(journal.pet_reaction == -1 and not journal.portrait.texture_normal is AtlasTexture, "Pet animation returns to the original portrait")
	journal.pet_bag.clear()
	for cycle in 2:
		var seen: Array[int] = []
		for tap in 10:
			var previous: int = journal.pet_last
			journal.call("_pet")
			check(journal.pet_reaction != previous and not seen.has(journal.pet_reaction), "All ten pet reactions play without repeats")
			seen.append(journal.pet_reaction)
			journal.call("_advance_pet_reaction", 3.0)
	check(RunState.overhaul_progress == pet_progress, "Petting does not change skills or award paw points")
	journal.call("_pet")
	journal.close_journal()
	check(journal.pet_reaction == -1 and journal.pet_frames.is_empty(), "Closing the journal cancels its reaction and releases frames")
	ui.open_skills()
	check(journal.pet_reaction == -1, "Reopening the journal starts with the original calm portrait")
	ui.journal.close_journal()
	check(world.player.control_enabled and not main.call("_shop_panel_is_open"),"Closing journal restores world controls")
	RunState.overhaul_progress={"skills":{"teamwork":1}}
	world.mine.barriers=[]
	var target: Vector2i=Vector2i(12,12)
	world.blocks[target]=world.call("_make_block","stone",20,0,"terrain")
	world.blocks.erase(target+Vector2i.LEFT)
	world.player.global_position=world.call("_cell_center",target+Vector2i.LEFT)
	world.player.set_facing(Vector2.RIGHT)
	mole.global_position=world.player.global_position
	mole.mode="fetch";mole.action="idle";mole.assist_cooldown=0.0
	world.external_mine_held=true
	var dug_before: int=mole.dug_total
	mole.call("_think")
	check(mole.action=="shake" and mole.assist_action,"Teamwork gets a turn even while fetching")
	check(world.blocks.has(target),"Teamwork waits for animation impact")
	mole.call("_update_action",0.45)
	check(not world.blocks.has(target) and mole.dug_total==dug_before+1,"Teamwork opens exactly one ordinary block at impact")
	mole.call("_update_action",0.1)
	check(mole.dug_total==dug_before+1 and mole.assist_cooldown>0.0,"Teamwork cannot credit twice or bypass recharge")
	world.external_mine_held=false
	RunState.overhaul_progress={}
	check(not mole.scout("homeward"),"Unlearned command cannot bypass its skill")
