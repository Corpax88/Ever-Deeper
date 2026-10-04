extends "res://scripts/qa/suites/full_quality_base.gd"
## QA-only fixture: original published runtime and original QA base are retained.
var quality_mod_result: Dictionary={}
var quality_journey_result: Dictionary={}
var quality_achievement_result: Dictionary={}
var quality_notice_active: bool=false
var quality_profile_active: bool=false
var quality_profile_started: int=0
var quality_profile_tick: int=0
var quality_profile_frames: Array[float]=[]
var quality_profile_cpu: Array[float]=[]
var quality_profile_result: Dictionary={}
var quality2_sale_result: Dictionary={}
var quality2_route_result: Dictionary={}
var quality2_target_result: Dictionary={}
var quality2_sale_moles: Array[Dictionary]=[]

func run() -> void:
	if "--quality-mod-persistence" in OS.get_cmdline_user_args():
		# An isolated persistent fixture has a real fresh-boot/resume distinction.
		# The inherited general review intentionally resets every boot instead.
		main.save_available=RunState.initialize_persistence("user://quality-ricochet-lifecycle.sav")
		main.persistence_active=true
		main.automated_mode=false
		main._open_start_menu()
		main.get_tree().process_frame.connect(_frame)
		previous_usec=Time.get_ticks_usec()
		return
	super.run()

func _quality_journey_place_ore() -> bool:
	# Preserve generated ore and HP; only place the fresh player beside a
	# real exposed node the original pickaxe can target.
	var world: Node2D=main.mine_world
	for cell in world.blocks:
		var block: Dictionary=Dictionary(world.blocks[cell])
		if String(block.get("role","")) != "resource" or int(block.get("requires_tool",0)) > RunState.pickaxe_level: continue
		for distance in [64.0,80.0,96.0]:
			var position: Vector2=world._cell_center(cell)-Vector2.RIGHT*distance
			world.restore_position(position)
			if world.player.global_position.distance_to(position)>2.0: continue
			world.player.set_facing(Vector2.RIGHT)
			if world._find_mine_target()==cell:
				world.target_dirty=true
				return true
	return false

func _review_clear_toasts() -> bool:
	return not quality_notice_active

func _quality2_natural_ore() -> bool:
	var world: Node2D=main.mine_world
	var cells: Array=world.blocks.keys()
	var entrance: Vector2=world._entry_spawn()
	cells.sort_custom(func(a,b): return world._cell_center(a).distance_squared_to(entrance)<world._cell_center(b).distance_squared_to(entrance))
	for cell in cells:
		var block: Dictionary=world.blocks[cell]
		if String(block.kind)=="stone" or String(block.role)!="resource" or int(block.requires_tool)>RunState.pickaxe_level: continue
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			for distance in [64.0,80.0,96.0]:
				var position: Vector2=world._cell_center(cell)-direction*distance
				if world._player_collides(position): continue
				world.restore_position(position)
				if world.player.global_position.distance_to(position)>2.0: continue
				world.player.set_facing(direction)
				if world._find_mine_target()!=cell: continue
				world.target_dirty=true
				quality2_target_result={"cell":[cell.x,cell.y],"block":block.duplicate(true),"natural_selection":true}
				return true
	return false

func _quality2_natural_depth_target(kind: String) -> bool:
	var world: Node2D=main.depth_world
	var candidates: Array=[]
	if kind=="ore":
		for index in world.rocks.size():
			var rock: Dictionary=world.rocks[index]
			if world._rock_is_exposed(index) and int(rock.requires_drill_level)==0:
				candidates.append({"position":Vector2(rock.position),"kind":"rock","rock_index":index,"cell":Vector2i(rock.cell)})
	else:
		for row in world.rows:
			for col in world.cols:
				var cell: Vector2i=Vector2i(col,row)
				if world._terrain_is_solid(cell) and not world._terrain_is_bedrock(cell):
					candidates.append({"position":world._cell_center(cell),"kind":"terrain","cell":cell,"rock_index":-1})
	var entrance: Vector2=world.entry_spawn()
	candidates.sort_custom(func(a,b): return a.position.distance_squared_to(entrance)<b.position.distance_squared_to(entrance))
	for candidate in candidates:
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			for distance in [64.0,80.0,96.0]:
				var position: Vector2=candidate.position-direction*distance
				if world._player_collides(position): continue
				world.restore_position(position)
				if world.player.global_position.distance_to(position)>2.0: continue
				world.player.set_facing(direction)
				var selected: Dictionary=world._find_mine_target()
				if String(selected.get("kind",""))!=String(candidate.kind): continue
				if candidate.kind=="rock" and int(selected.get("rock_index",-1))!=int(candidate.rock_index): continue
				if candidate.kind=="terrain" and Vector2i(selected.get("cell",Vector2i(-1,-1)))!=Vector2i(candidate.cell): continue
				world._apply_target(selected)
				world.target_dirty=false
				var cell: Vector2i=Vector2i(candidate.cell)
				quality2_target_result={"depth":2,"case":kind,"cell":[cell.x,cell.y],"target_kind":String(candidate.kind),"rock_index":int(candidate.rock_index),"natural_selection":true}
				return true
	return false

func _quality2_restore_sale_companions() -> void:
	for saved in quality2_sale_moles:
		if not is_instance_valid(saved.node): continue
		saved.node.autonomous_enabled=bool(saved.autonomous)
		saved.node.set_physics_process(bool(saved.physics))
	quality2_sale_moles.clear()

func _quality2_pause_sale_companions() -> void:
	_quality2_restore_sale_companions()
	# This accounting fixture has a declared haul. Autonomous ore added during
	# the sale would change that haul; isolate companions, not sale arithmetic.
	for world in [main.surface_world,main.mine_world,main.depth_world,main.hub_world,main.deepheart_world,main.endless_world]:
		var mole: Node=world.get_node_or_null("MoleCompanion")
		if not is_instance_valid(mole): continue
		quality2_sale_moles.append({"node":mole,"physics":mole.is_physics_processing(),"autonomous":mole.autonomous_enabled})
		mole.recall()
		mole.autonomous_enabled=false
		mole.set_physics_process(false)

func _quality2_route_fixture(scenario: String) -> void:
	var goals: Script=preload("res://scripts/state/treasury_goals.gd")
	if scenario=="cancel-rune":
		main.endless_world._cancel_site_activity()
		quality2_route_result={"scenario":scenario,"fixture":"Explicit activity cancellation; saved collection choice retained"}
		return
	if main.hub_world.treasury.inside: main.hub_world.treasury.leave()
	RunState.reset_run(false)
	main._dev_seed_victory_state()
	main._dev_jump_surface()
	RunState.cargo=RunState._empty_resource_store()
	RunState.gold=0
	RunState.treasury_totals={}
	RunState.treasury_goals=goals.clean({})
	var kind: String="moonglass" if scenario=="source" else "prismite"
	goals.pin(kind)
	quality2_route_result={"scenario":scenario,"fixture":"Explicit prerequisites, cargo and player placement; production goal and route owners"}
	if scenario in ["deep-source","return","rune"]: main._dev_jump_endless(3)
	elif scenario in ["hub-donation","donation","podium"]: main._dev_jump_hub()
	if scenario in ["return","hub-donation","donation"]: RunState.cargo[kind]=100000
	if scenario=="podium": RunState.treasury_totals[kind]=100000
	if scenario in ["donation","podium"]: main.hub_world.treasury.enter()
	if scenario=="rune":
		var world: Node=main.endless_world
		quality2_route_result["site_found"]=false
		for site in world.discovery_sites:
			if int(site.get("depth",-1))!=world.current_depth or bool(site.get("resolved",false)) or Array(site.get("rune_positions",[])).size()<3: continue
			# Expose only this generated choice approach through real wall damage.
			# Starting the activity is reserved for the browser's actual touch.
			var center: Vector2i=world._world_to_cell(Vector2(site.position))
			for dx in range(-2,3):
				for dy in range(-1,2):
					var cell: Vector2i=center+Vector2i(dx,dy)
					for _hit in 520:
						if world._is_floor(cell): break
						world._strike_wall(cell,1.0)
			world.restore_position(Vector2(site.position)+Vector2(-world.SITE_PAD_OFFSET,36.0))
			world._update_context(world.player.global_position)
			quality2_route_result["site_found"]=true
			quality2_route_result["site_index"]=int(site.index)
			quality2_route_result["choice_approach_excavated"]=true
			break
	main._active_player_node().camera.reset_smoothing()
	main._active_player_node().camera.force_update_scroll()
	main._refresh_hud()
	main._update_visual_guide()

func _command(data: Dictionary) -> void:
	if String(data.kind) not in ["quality2_sale","treasury_zone","treasury_save","treasury_restore"]: _quality2_restore_sale_companions()
	quality_notice_active=(String(data.kind)=="quality_achievement" and not bool(data.get("cancel",false))) or (String(data.kind)=="quality_feedback" and not bool(data.get("clear",false)))
	match String(data.kind):
		"hunt_boundary":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			main._dev_seed_victory_state()
			RunState.world_seed=77411
			RunState.endless_chunks={}
			RunState.endless_stream_anchor={}
			RunState.cargo=RunState._empty_resource_store()
			RunState.treasury_totals={}
			RunState.treasury_goals={"pinned":"phasecrystal"}
			main._dev_jump_endless(1)
			RunState.treasury_goals={"pinned":"rootiron"}
			RunState._state_changed()
			main.quick_tutorial.dismiss()
			main._update_visual_guide()
			command_id=int(data.id)
			return
		"quality2_sale":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			main.automated_mode=false
			if String(data.get("action","setup"))=="setup":
				if main.hub_world.treasury.inside: main.hub_world.treasury.leave()
				RunState.reset_run(false)
				main._dev_seed_victory_state()
				main._dev_jump_surface()
				_quality2_pause_sale_companions()
				RunState.cargo=RunState._empty_resource_store()
				RunState.cargo.phasecrystal=225
				RunState.cargo.copper=9
				RunState.gold=17
				RunState.treasury_totals={"phasecrystal":99800}
				RunState.treasury_goals=preload("res://scripts/state/treasury_goals.gd").clean({})
				quality2_sale_result={"seeded_cargo":{"phasecrystal":225,"copper":9},"seeded_gold":17,"seeded_delivered":99800,"isolated_companions":quality2_sale_moles.size(),
					"expected_sale":25*int(GameData.data.ROCK_TYPES.phasecrystal.value)+9*int(GameData.data.ROCK_TYPES.copper.value)}
				main.treasury_goal_panel.open_goal("phasecrystal")
			elif String(data.action)=="open":
				main.treasury_goal_panel.open_goal("phasecrystal")
			elif String(data.action)=="treasury":
				main._dev_jump_hub()
				main.hub_world.restore_position(main.hub_world.TREASURY_DOOR+Vector2(-65,0))
				main.hub_world.player.camera.reset_smoothing()
			elif String(data.action)=="podium":
				var room: Node=main.hub_world.treasury
				var aim: Vector2=room.bay(room.Ledger.keys().find("phasecrystal"))
				main.hub_world.restore_position(aim+(room.ZONE-aim).normalized()*200.0+Vector2(0,40))
				main.hub_world.player.camera.reset_smoothing()
			else:
				main.surface_world.restore_position(main.surface_world.station_interaction_position("sell")+Vector2(140,0))
				main.surface_world.player.camera.reset_smoothing()
			main._refresh_hud()
			command_id=int(data.id)
			return
		"quality2_route":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			_quality2_route_fixture(String(data.scenario))
			command_id=int(data.id)
			return
		"quality2_target":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			RunState.reset_run(false)
			var depth: int=int(data.get("depth",1))
			main._dev_jump_mine("mossMine",depth)
			quality2_target_result={"natural_selection":false}
			if depth==2:
				RunState.drill_level=0
				RunState.starforge_variant="crusher"
			var found: bool=_quality2_natural_depth_target(String(data.get("target","terrain"))) if depth==2 else _quality2_natural_ore()
			quality2_target_result["found"]=found
			var mole: Node=main.get_node("CompanionInterface").active_mole()
			mole.autonomous_enabled=false
			mole.recall()
			var world: Node2D=main.depth_world if depth==2 else main.mine_world
			world.player.camera.reset_smoothing()
			world.player.camera.force_update_scroll()
			world.queue_redraw()
			main._refresh_hud()
			command_id=int(data.id)
			return
		"quality2_surface_context":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			RunState.reset_run(false)
			main._dev_jump_surface()
			main.surface_world.restore_position(main.surface_world._mine_entrance("mossMine"))
			main.surface_world.player.camera.reset_smoothing()
			main.surface_world.player.camera.force_update_scroll()
			main._refresh_hud()
			command_id=int(data.id)
			return
		"quality_boundary":
			main._dev_jump_endless(1)
			main.endless_world.restore_position(Vector2(1280,25.5))
			main.endless_world.player.set_facing(Vector2.DOWN)
			main.endless_world.player.camera.set_headlamp_direction(Vector2.DOWN)
			main.endless_world.player.camera.reset_smoothing()
			main.endless_world.player.camera.force_update_scroll()
			main._refresh_hud()
			command_id=int(data.id)
			return
		"quality_feedback":
			main.achievement_toast.show()
			main.achievement_toast.clear()
			var skill: Node=main.achievement_toast.get_node("SkillLevelToast")
			skill.clear()
			var pickup: Node=main._active_player_node().get_node("ResourcePickupBurst")
			while not pickup.entries.is_empty(): pickup._remove_entry(0)
			if not bool(data.get("clear",false)):
				# Seed presentation events only; owners retain their real timing/layout.
				RunState.miner_skill_increased.emit("mining",2)
				pickup.show_pickup("rootiron",350)
				pickup.show_pickup("prismite",410)
				pickup.show_pickup("singularity",390)
				main._on_achievement_unlocked(main.premium_menu.achievement_service.definitions()[28])
				main._update_achievement_toast_anchor()
			command_id=int(data.id)
			return
		"quality_achievement":
			# General visual fixtures hide this parent. Restore ordinary notice
			# presentation and the real tap route for this interaction review.
			main.achievement_toast.show()
			main.automated_mode=false
			var definitions: Array=main.premium_menu.achievement_service.definitions()
			var selected: int=int(data.get("index",0))
			if selected < 0: selected=definitions.size()-1
			var definition: Dictionary=definitions[selected]
			main.achievement_toast.clear()
			quality_achievement_result={"requested":String(definition.id),"index":selected,"count":definitions.size(),"cancelled_before_deferred":false}
			if bool(data.get("cancel",false)):
				# Deterministic signal-level race; ordinary focus uses real touch.
				main._on_achievement_toast_activated(String(definition.id))
				main.premium_menu.detail_card.get_node("Back").pressed.emit()
				quality_achievement_result.cancelled_before_deferred=true
			else:
				main._on_achievement_unlocked(definition)
			command_id=int(data.id)
			return
		"quality_finale":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			match String(data.action):
				"setup":
					RunState.reset_run(false)
					main._dev_jump_deepheart()
				"seal":
					main.deepheart_world.restore_position(Vector2(main.deepheart_world.SEAL_POSITIONS[String(data.seal)])+Vector2(0,135))
				"core":
					main.deepheart_world.restore_position(main.deepheart_world.CORE_CONTEXT_POSITION)
				"elevator":
					main.hub_world.restore_position(main.hub_world.DEEP_ELEVATOR_POSITION+Vector2(0,112))
			main._active_player_node().camera.reset_smoothing()
			main._refresh_hud()
			command_id=int(data.id)
			return
		"quality_journey":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			quality_journey_result={"step":String(data.step),"seeded":{}}
			match String(data.step):
				"entrance":
					main.surface_world.restore_position(main.surface_world._mine_entrance("mossMine"))
				"target":
					quality_journey_result["natural_target_found"]=_quality_journey_place_ore()
					var cell: Vector2i=main.mine_world._find_mine_target()
					quality_journey_result["target"]=[cell.x,cell.y]
					quality_journey_result["block"]=Dictionary(main.mine_world.blocks.get(cell,{})).duplicate(true)
				"exit":
					main.mine_world.restore_position(main.mine_world._entry_spawn())
				"assay_approach":
					main.surface_world.restore_position(main.surface_world.station_interaction_position("sell")+Vector2(140,0))
				"forge":
					var cost: int=int(RunState.next_pickaxe().cost)
					quality_journey_result.seeded={"gold_added":maxi(0,cost-RunState.gold)}
					RunState.gold=maxi(RunState.gold,cost)
					main.surface_world.restore_position(main.surface_world.station_interaction_position("forge"))
				"gate":
					var requirement: Dictionary=main._gate_requirements("moonglass")
					quality_journey_result.seeded={"gold_added":maxi(0,int(requirement.gold)-RunState.gold)}
					RunState.gold=maxi(RunState.gold,int(requirement.gold))
					main.surface_world.restore_position(main.surface_world.gate_interaction_position("moonglass"))
			main._active_player_node().camera.reset_smoothing()
			main._refresh_hud()
			command_id=int(data.id)
			return
		"quality_profile":
			if String(data.action)=="begin":
				quality_profile_frames.clear()
				quality_profile_cpu.clear()
				quality_profile_started=Time.get_ticks_usec()
				quality_profile_tick=quality_profile_started
				quality_profile_active=true
			else:
				quality_profile_active=false
				var elapsed: float=float(Time.get_ticks_usec()-quality_profile_started)/1000000.0
				quality_profile_result={"frames":quality_profile_frames.size(),"seconds":elapsed,"fps":float(quality_profile_frames.size())/maxf(.001,elapsed),"frame_ms":_quality_stats(quality_profile_frames),"cpu_ms":_quality_stats(quality_profile_cpu),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
			command_id=int(data.id)
			return
		"quality_mod_setup":
			main._dev_seed_victory_state()
			var built: bool=main._dev_build_all_workshops_state()
			var upgrades: Array=[]
			for i in 4:
				var status: Dictionary=RunState.workshop_status("tool_forge")
				var recipe: Dictionary=status.get("next_upgrade",{})
				if recipe.is_empty(): break
				RunState.add_resource(String(recipe.resource),int(recipe.cost),false)
				upgrades.append(RunState.upgrade_workshop("tool_forge"))
			main._dev_jump_hub()
			main._dev_jump_endless(1)
			main._on_developer_command_requested("test_ricochet")
			RunState.set_movement_speed_level(20)
			main._apply_global_movement_speed()
			quality_mod_result={"built":built,"upgrades":upgrades,"forge_level":RunState._built_workshop_level("tool_forge")}
			command_id=int(data.id)
			return
		"quality_mod_skin":
			var requested: String=String(data.skin)
			var accepted: bool=RunState.set_endless_tool_style(requested)
			var saved: bool=RunState.flush_save()
			quality_mod_result={"requested":requested,"accepted":accepted,"saved":saved,"stored":RunState.endless_tool_style}
			command_id=int(data.id)
			return
		"quality_mod_action":
			quality_mod_result={"action":String(data.action)}
			match String(data.action):
				"pause": main._open_start_menu()
				"resume": main._continue_from_menu()
				"travel":
					quality_mod_result.hub=main._dev_jump_hub()
					quality_mod_result.endless=main._dev_jump_endless(1)
				"earned":
					RunState.treasury_totals.phasecrystal=100000
					main.treasury_goal_panel.kind="phasecrystal"
					main.treasury_goal_panel._claim()
				"unequip":
					main.treasury_goal_panel.kind="phasecrystal"
					main.treasury_goal_panel._claim()
				"checkpoint":
					main._checkpoint_location()
					quality_mod_result.saved=RunState.flush_save()
			command_id=int(data.id)
			return
		"quality_goal":
			RunState.reset_run(false)
			var scenario: String = String(data.scenario)
			if scenario == "recipe":
				RunState.area_unlocked = true
				RunState.emberdeep_unlocked = true
				RunState.fourth_unlocked = true
				RunState.pickaxe_level = 5
				RunState.ember_mastery = 1
			elif scenario == "pinned":
				RunState.victory = true
				RunState.treasury_totals["prismite"] = 23000
				preload("res://scripts/state/treasury_goals.gd").pin("prismite")
			main._dev_jump_surface()
			main._refresh_hud()
			command_id = int(data.id)
			return
		"quality_preview_state":
			main._dev_seed_victory_state()
			var goals = preload("res://scripts/state/treasury_goals.gd")
			var resource: String = String(data.resource)
			if not bool(data.get("preserve",false)): RunState.treasury_goals = goals.clean({})
			RunState.treasury_totals[resource] = int(data.amount)
			if data.has("held"):
				if resource==goals.Ledger.WALLET: RunState.gold=int(data.held)
				else: RunState.cargo[resource]=int(data.held)
			main.treasury_goal_panel.open_goal(resource)
			command_id = int(data.id)
			return
		"quality_inventory":
			for index in RunState.RESOURCE_IDS.size():
				RunState.cargo[String(RunState.RESOURCE_IDS[index])] = 1000 + index * 137
			main._refresh_hud()
			command_id = int(data.id)
			return
		"quality_commerce":
			main._dev_seed_victory_state()
			var family: String = String(data.family)
			if family == "depth_forge":
				main._dev_jump_mine("mossMine",2)
				main._open_commerce(main.CommerceCatalogScript.depth_forge_config("mossMine"),"depth_forge")
			else:
				main._dev_jump_surface()
				if family == "forge": main._open_forge_commerce()
				elif family == "starforge": main._open_starforge_commerce()
			command_id = int(data.id)
			return
		"quality_exit":
			main.hub_world.restore_position(main.hub_world.treasury.ENTRY)
			main.hub_world.player.camera.reset_smoothing()
			command_id = int(data.id)
			return
	await super._command(data)

func _frame() -> void:
	if quality_profile_active:
		var now: int=Time.get_ticks_usec()
		quality_profile_frames.append(float(now-quality_profile_tick)/1000.0)
		quality_profile_cpu.append(float(Performance.get_monitor(Performance.TIME_PROCESS))*1000.0)
		quality_profile_tick=now
	super._frame()
	if sample_clock != 0.0: return
	var buttons: Dictionary = {
		"menu_settings": _bounds(main.premium_menu.main_card.get_node("Settings")),
		"menu_achievements": _bounds(main.premium_menu.achievements_button)
	}
	if main.premium_menu.detail_card.has_node("Controls"):
		buttons["settings_controls"] = _screen_bounds(main.premium_menu.detail_card.get_node("Controls"))
	buttons["shop_primary"]=_screen_bounds(main.commerce_panel.primary_button)
	buttons["conclusion_to_hub"]=_screen_bounds(main.conclusion_continue_button)
	buttons["conclusion_stay"]=_screen_bounds(main.conclusion_hub_button)
	buttons["achievement_toast"]=_screen_bounds(main.achievement_toast._activation_target)
	var phasecrystal_at: Vector2=main.hub_world.get_canvas_transform()*(main.hub_world.treasury.bay(main.hub_world.treasury.Ledger.keys().find("phasecrystal"))+Vector2(0,-30))
	buttons["quality2_podium"]=[phasecrystal_at.x-12,phasecrystal_at.y-12,24,24]
	var ui: Dictionary = {
		"tutorial": main.quick_tutorial.debug_snapshot(),
		"commerce": main.commerce_panel.interaction_snapshot(),
		"cargo": RunState.cargo.duplicate(),
		"menu_detail_title": main.premium_menu.detail_title.text,
		"geometry": _quality_geometry(),
		"feedback": _quality_feedback(),
		"mod": _quality_mod_snapshot()
	}
	ui["journey"]={"result":quality_journey_result,"gold":RunState.gold,"pickaxe":RunState.pickaxe_level,"mined":RunState.total_mined_resources(),"surface_context":main.surface_context,"exit_context":main.mine_exit_context,"transaction":main.commerce_transaction.duplicate(true),"moonglass_unlocked":RunState.area_unlocked,"world_seed":RunState.world_seed}
	ui["profile"]=quality_profile_result
	ui["sale"]={"fixture":quality2_sale_result,"snapshot":RunState.assay_sale_snapshot(),"gold":RunState.gold,"cargo":RunState.cargo.duplicate(),"pin":String(RunState.treasury_goals.pinned),"delivered":int(RunState.treasury_totals.get("phasecrystal",0)),"status":main._assay_status(),"presented_status":main.status_label.text}
	ui["route"]=_quality2_route_snapshot()
	ui["hunt"]={"current_depth":main.endless_world.current_depth,"target_depth":main.endless_world.depth_at_position(main.endless_world.guide_target("rootiron")),"action":main.endless_world.treasury_hunt_action("rootiron"),"guide_visible":main.guide_overlay.has_target}

	ui["target"]=_quality2_target_snapshot()
	ui["finale"]={"world":main.deepheart_world.debug_snapshot(),"context":main.deepheart_context,"victory":RunState.victory,"conclusion":main.conclusion_overlay.visible,"conclusion_seen":RunState.conclusion_seen,"seals":RunState.deepheart_seal_status(),"seal_state":main.deepheart_world.seal_state.duplicate(true),"endless":RunState.endless_descent_status()}
	ui.finale.geometry=_quality_conclusion_geometry()
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE.buttons,"+JSON.stringify(buttons)+");window.DEV14_STATE.quality="+JSON.stringify(ui),true)

func _quality_feedback() -> Dictionary:
	var player: Node=main._active_player_node()
	var pickup: Node=player.get_node("ResourcePickupBurst")
	var skill: Node=main.achievement_toast.get_node("SkillLevelToast")
	var visual: Node=player.get_node("Visual")
	var hero: Array=[]
	if visual.has_method("feedback_screen_rects"):
		for rect in visual.feedback_screen_rects(): hero.append(_quality_rect(rect))
	var pickups: Array=[]
	for rect in pickup.screen_rects(): pickups.append(_quality_rect(rect))
	var exclusions: Array=[]
	for rect in main.achievement_toast._screen_exclusions: exclusions.append(_quality_rect(rect))
	return {"hero":hero,"hero_frame":_quality2_hero_frame(player),"minimap":_quality_rect(main.minimap_overlay.get_global_transform_with_canvas()*main.premium_hud.minimap_layout_rect()),"pickups":pickups,"pickup":pickup.debug_snapshot(),"skill":skill.snapshot(),"skill_rect":_quality_rect(skill.reserved_screen_rect()),
		"toast":main.achievement_toast.debug_snapshot(),"toast_rect":_screen_bounds(main.achievement_toast._toast),"safe_rect":_quality_rect(main.achievement_toast.safe_screen_rect()),"exclusions":exclusions}

func _quality2_hero_frame(player: Node) -> Array:
	var visual: Node=player.visual
	var native: Node=visual.get("_native_worn")
	var rig: Node=native.get("rig") if is_instance_valid(native) else null
	var sprite: Sprite2D=rig.get("sprite") if is_instance_valid(rig) else visual.get("_sprite")
	if not is_instance_valid(sprite) or not sprite.is_visible_in_tree(): return []
	return _quality_rect(sprite.get_global_transform_with_canvas()*sprite.get_rect())

func _quality2_target_snapshot() -> Dictionary:
	var result: Dictionary={"fixture":quality2_target_result,"visible":false}
	if main.phase not in ["mine","depth"]: return result
	var world: Node=main.depth_world if main.phase=="depth" else main.mine_world
	var label: Label=world.get_node_or_null("TargetLabel")
	if not is_instance_valid(label): return result
	result["visible"]=label.is_visible_in_tree()
	result["label"]=_label_geometry(label)
	result["ink"]=_quality_rect((label.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,label.size)).grow(4.0))
	result["unshaded"]=label.material is CanvasItemMaterial and label.material.light_mode==CanvasItemMaterial.LIGHT_MODE_UNSHADED
	if main.phase=="mine":
		var cell: Vector2i=world.current_target
		result["depth"]=1
		result["cell"]=[cell.x,cell.y]
		result["natural_selection"]=world._find_mine_target()==cell
		result["block"]=Dictionary(world.blocks.get(cell,{})).duplicate(true)
	else:
		var cell: Vector2i=world.current_target_cell
		var selected: Dictionary=world._find_mine_target()
		result["depth"]=2
		result["cell"]=[cell.x,cell.y]
		result["target_kind"]=String(world.current_target_kind)
		result["natural_selection"]=String(selected.get("kind",""))==String(world.current_target_kind) and Vector2i(selected.get("cell",Vector2i(-1,-1)))==cell and int(selected.get("rock_index",-1))==int(world.current_target_rock)
		if world.current_target_kind=="rock" and world.current_target_rock>=0:
			var rock: Dictionary=world.rocks[world.current_target_rock]
			result["block"]={"role":"resource","kind":String(rock.type),"hp":int(rock.hp),"shell":int(rock.shell),"broken":bool(rock.broken),"exposed":world._rock_is_exposed(world.current_target_rock)}
		elif world.current_target_kind=="terrain" and world._cell_in_bounds(cell):
			result["block"]={"role":"terrain","kind":"deepstone","hp":int(world.terrain_hp[world._cell_index(cell)]),"bedrock":world._terrain_is_bedrock(cell)}
		else: result["block"]={}
	return result

func _quality2_route_snapshot() -> Dictionary:
	var goal: Dictionary=main._progression_goal()
	var proposal: Dictionary=main._guide_route_proposal(goal) if not goal.is_empty() else {}
	var candidates: Array=[]
	for candidate in Array(proposal.get("candidates",[])):
		var point: Vector2=Vector2(candidate.position)
		candidates.append([point.x,point.y])
	var world: Node=main.endless_world
	var next_rune: Array=[]
	if not world.site_activity.is_empty():
		var site: Dictionary=world.discovery_sites[int(world.site_activity.array_index)]
		var point: Vector2=Vector2(site.rune_positions[int(world.site_activity.next_rune)])
		next_rune=[point.x,point.y]
	var treasury: Node=main.hub_world.treasury
	var kind: String=String(RunState.treasury_goals.pinned)
	var targets: Dictionary={"treasury":main.hub_world.TREASURY_DOOR,"donation":treasury.DONATION,"deep_elevator":main.hub_world.DEEP_ELEVATOR_POSITION}
	if kind in treasury.Ledger.keys(): targets["podium"]=treasury.bay(treasury.Ledger.keys().find(kind))
	if main.phase=="endless" and not kind.is_empty(): targets["deep_resource"]=world.guide_target(kind)
	for key in targets:
		var point: Vector2=Vector2(targets[key])
		targets[key]=[point.x,point.y]
	return {"fixture":quality2_route_result,"goal":goal,"waypoint":String(proposal.get("waypoint_id","")),"action":String(proposal.get("hud_action",goal.get("hud_action",""))),"candidates":candidates,"targets":targets,"next_rune":next_rune,
		"pin":kind,"activity":world.site_activity.duplicate(true),"inside":treasury.inside,"context":main.endless_context}

func _quality_rect(rect: Rect2) -> Array:
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _quality_stats(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {}
	var sorted: Array[float]=values.duplicate()
	sorted.sort()
	var sum: float=0.0
	var stalls: int=0
	for value in values:
		sum+=value
		if value>250.0: stalls+=1
	return {"mean":sum/values.size(),"p50":sorted[int((sorted.size()-1)*.50)],"p95":sorted[int((sorted.size()-1)*.95)],"p99":sorted[int((sorted.size()-1)*.99)],"max":sorted.back(),"over_250ms":stalls}

func _quality_mod_snapshot() -> Dictionary:
	var world: Node=main.endless_world
	var visual: Node=world.player.visual
	var native: Node=visual.get("_native_worn")
	var hero_screen: Vector2=world.player.get_global_transform_with_canvas()*Vector2.ZERO
	return {"result":quality_mod_result,"skin":RunState.endless_tool_style,"forge_level":RunState._built_workshop_level("tool_forge"),
		"selected":world.drill_modes.selected(),"saved":preload("res://scripts/state/treasury_goals.gd").active_mod(),"override":world.drill_modes.dev_override,
		"native":visual.native_worn_snapshot(),"sprite_visible":visual._sprite.visible,"tool_visible":is_instance_valid(native) and is_instance_valid(native.equipment) and is_instance_valid(native.equipment.tool) and native.equipment.tool.visible,
		"five_mode":world.drill_modes.five.mode,"save_available":main.save_available,"save_error":RunState.last_save_error,"load_status":RunState.last_load_status,
		"hero_screen":[hero_screen.x,hero_screen.y]}

func _screen_bounds(control: Control) -> Array:
	var rect: Rect2 = control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,control.size)
	return [rect.position.x,rect.position.y,rect.size.x,rect.size.y]

func _label_geometry(label: Label) -> Dictionary:
	var transform: Transform2D = label.get_global_transform_with_canvas()
	var font: Font=label.get_theme_font("font")
	var font_size: int=label.get_theme_font_size("font_size")
	var width: float=0.0
	for line in label.text.split("\n"): width=maxf(width,font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x)
	return {"rect":_screen_bounds(label),"text":label.text,"visible":label.is_visible_in_tree(),
		"font_viewport":label.get_theme_font_size("font_size")*transform.y.length(),
		"lines":label.get_line_count(),"visible_lines":label.get_visible_line_count(),"height_fits":label.get_line_count()*font.get_height(font_size)<=label.size.y+1.0,"width_fits":label.autowrap_mode!=TextServer.AUTOWRAP_OFF or width<=label.size.x+1.0}

func _quality_conclusion_geometry() -> Dictionary:
	var card: Control=main.conclusion_card
	var result: Dictionary={"viewport":_quality_rect(main.get_viewport().get_visible_rect()),"card":_screen_bounds(card),"visible":card.is_visible_in_tree(),"labels":[],"buttons":[]}
	for child in card.get_children():
		if child is Label: result.labels.append(_label_geometry(child))
	for button in [main.conclusion_continue_button,main.conclusion_hub_button]:
		result.buttons.append({"rect":_screen_bounds(button),"text":button.text,"visible":button.is_visible_in_tree(),"disabled":button.disabled})
	return result

func _quality_geometry() -> Dictionary:
	var goal: Control = main.premium_hud.progression_goal_panel
	var panel: Control = main.treasury_goal_panel
	var skills: Control = main.miner_skills_panel
	var result: Dictionary = {
		"goal":{"rect":_screen_bounds(goal),"action":_label_geometry(goal._action),"title":_label_geometry(goal._title),"snapshot":goal.snapshot()},
		"controls":{},"preview":{},
		"skills":{"plate":_screen_bounds(skills.plate),"portrait_visible":skills.portrait.is_visible_in_tree(),"map":skills._map_active}
	}
	var menu: Control=main.premium_menu
	result["menu"]={"panel":_screen_bounds(menu.detail_card),"back":_screen_bounds(menu.detail_card.get_node("Back")),"labels":[]}
	result["achievement"]={"result":quality_achievement_result,"highlighted":menu.achievement_highlight_id,"detail_visible":menu.detail_view.is_visible_in_tree(),"main_visible":menu.main_view.is_visible_in_tree(),"toast":main.achievement_toast.debug_snapshot(),"row":[],"scroll":[],"scroll_value":0}
	if is_instance_valid(menu.achievement_scroll):
		result.achievement.scroll=_screen_bounds(menu.achievement_scroll)
		result.achievement.scroll_value=menu.achievement_scroll.scroll_vertical
		var row: Control=menu.achievement_rows.get(menu.achievement_highlight_id) as Control
		if is_instance_valid(row): result.achievement.row=_screen_bounds(row)
	for label in menu.detail_body.find_children("*","Label",true,false):
		if label.is_visible_in_tree(): result.menu.labels.append(_label_geometry(label))
	var journal: Control=main.get_node("CompanionInterface").journal
	result["journal"]={"tab":journal.tab,"commands":{},"status":journal.status.text if is_instance_valid(journal.status) else "",
		"paper":_screen_bounds(journal.paper),"body":_screen_bounds(journal.body),"mood":_label_geometry(journal.mood),"notice":_label_geometry(journal.notice)}
	for button in journal.body.find_children("Command_*","Button",true,false):
		result.journal.commands[String(button.name)]={"rect":_screen_bounds(button),"disabled":button.disabled,"visible":button.is_visible_in_tree()}
	for pair in [["menu",main.premium_hud.menu_button],["mine",main.mine_button],["bag",main.premium_hud.bag_button],["context",main.premium_hud.context_button],["mole",main.get_node("CompanionInterface").button]]:
		result.controls[pair[0]]={"rect":_screen_bounds(pair[1]),"visible":pair[1].is_visible_in_tree(),"text":pair[1].text if pair[1] is Button else ""}
	result.preview={"panel":_screen_bounds(panel.panel),"heading":_label_geometry(panel.heading),"detail":_label_geometry(panel.detail),"source":_label_geometry(panel.source),"title":_label_geometry(panel.title),"equipped":_label_geometry(panel.equipped),"progress":_label_geometry(panel.progress),"bar":_screen_bounds(panel.progress_bar),
		"claim":{"rect":_screen_bounds(panel.claim_button),"text":panel.claim_button.text,"visible":panel.claim_button.is_visible_in_tree(),"disabled":panel.claim_button.disabled},
		"pin":{"rect":_screen_bounds(panel.pin_button),"text":panel.pin_button.text,"visible":panel.pin_button.is_visible_in_tree(),"disabled":panel.pin_button.disabled},
		"close":{"rect":_screen_bounds(panel.close_button),"text":panel.close_button.text,"visible":panel.close_button.is_visible_in_tree()}}
	var bag: Control=main.resource_inventory
	result["bag"]={"card":_screen_bounds(bag.inventory_card),"note":_label_geometry(bag.inventory_card.get_node("Layout/ProtectedNote")),"footer":_label_geometry(bag.inventory_card.get_node("Layout/Footer")),"rows":[]}
	for card in bag.item_grid.get_children():
		if not card.has_meta("resource_id"): continue
		var labels: Array=[]
		for label in card.find_children("*","Label",true,false): labels.append(_label_geometry(label))
		result.bag.rows.append({"kind":String(card.get_meta("resource_id")),"rect":_screen_bounds(card),"labels":labels})
	if is_instance_valid(skills.map_view):
		var rect: Rect2 = skills.map_view.get_global_transform_with_canvas() * skills.map_view._map_rect
		result.skills["map_rect"] = [rect.position.x,rect.position.y,rect.size.x,rect.size.y]
		result.skills["map_snapshot"] = skills.map_view.debug_snapshot()
	return result
