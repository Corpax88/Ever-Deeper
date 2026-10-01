extends "res://scripts/qa/suites/dev14_review.gd"
## Explicit fixture only; browser uses actual touch against observed control bounds.
func run() -> void:
	super.run()

var exposure_id: String = ""
var exposure_hp: int = 0
var deep_checks: Dictionary = {}
var deep_before: int = 0
var deep_drop_key: String = ""
var deep_drop_amount: int = 0
var deep_drop_kind: String = ""
var deep_cargo_before: int = 0

var node_asset_state: Dictionary = {}
var node_asset_index: int = -1
var node_asset_origin: Vector2

var shared_reference_layer: CanvasLayer
var prospect_checks: Dictionary = {}
var prospect_results: Dictionary = {}

func _reload_scene() -> void:
	var tree: SceneTree = main.get_tree()
	tree.process_frame.disconnect(_frame)
	JavaScriptBridge.eval("window.DEV14_STATE=null;window.DEV14_COMMAND=''",true)
	tree.reload_current_scene()

var mole_target: Vector2 = Vector2.ZERO
var mole_task_key: String = ""
var mole_case: String = ""
var mole_checks: Dictionary = {}
var ore_escape_origin: Vector2
var ore_escape_goal: Vector2
var ore_escape_active: bool=false

func _command(data: Dictionary) -> void:
	if String(data.kind)=="exposure_fixture":
		main._dev_jump_endless(1)
		main._on_developer_command_requested("test_resonance")
		var w: Node=main.endless_world
		var mole: Node=main.get_node("CompanionInterface").active_mole()
		mole.autonomous_enabled=false
		mole.recall()
		for resource in w.resources:
			if int(resource.depth)!=1 or bool(resource.mined) or w._is_floor(Vector2i(resource.cell)): continue
			var cell: Vector2i=resource.cell
			if cell.x<4 or cell.x>35 or cell.y<3: continue
			exposure_id=String(resource.id)
			exposure_hp=int(resource.hp)
			for offset in [Vector2i.UP,Vector2i(-1,-1),Vector2i(1,-1),Vector2i(0,-2)]:
				w._set_floor(cell+offset,true)
			w.player.global_position=w._cell_center(cell+Vector2i.UP)
			w.player.set_facing(Vector2.DOWN)
			w._on_player_moved(w.player.global_position)
			w.player.camera.reset_smoothing()
			break
		_require(not exposure_id.is_empty(),"buried browser node")
		w._update_buried_visibility()
		var event: Dictionary=w.deep_events.state()
		event.kind=""
		event.remaining=0.0
		event.next=2000000
		w.resonance_drill.reset()
		main._update_minimap()
		command_id=int(data.id)
		return
	if String(data.kind).begins_with("scale_"):
		await _scale_command(data)
		command_id=int(data.id)
		return
	if String(data.kind).begins_with("resonance_"):
		_resonance_command(data)
		command_id=int(data.id)
		return
	if String(data.kind).begins_with("treasury_"):
		await _treasury_command(data)
		command_id=int(data.id)
		return
	if String(data.kind).begins_with("deep_"):
		await _deep_command(String(data.kind))
		command_id=int(data.id)
		return
	if String(data.kind)=="node_asset_fixture":
		await _node_asset_fixture(String(data.mine_id))
		command_id=int(data.id)
		return
	if String(data.kind)=="node_asset_stage":
		_node_asset_stage(String(data.stage))
		command_id=int(data.id)
		return
	if String(data.kind)=="prospecting_tests":
		_test_prospecting()
		command_id=int(data.id)
		return
	if String(data.kind)=="prospecting_level":
		_set_prospect_level(int(data.level))
		main.miner_skills_panel.refresh()
		command_id=int(data.id)
		return
	if String(data.kind)=="ore_respawn_fixture":
		await _ore_respawn_fixture(String(data.mine_id))
		command_id=int(data.id)
		return
	if String(data.kind)=="ore_escape":
		command_id=int(data.id)
		var mole: Node=main.get_node("CompanionInterface").active_mole()
		_require(mole.command(ore_escape_goal),"escape command")
		return
	if String(data.kind)=="mole_auto":
		command_id=int(data.id)
		var mole: Node=main.get_node("CompanionInterface").active_mole()
		mole.recall()
		mole.autonomous_enabled=true
		mole.auto_work_clock=0.0
		return
	if String(data.kind)=="worm_fixture":
		command_id=int(data.id)
		var mole: Node=main.get_node("CompanionInterface").active_mole()
		mole.autonomous_enabled=false
		mole.recall()
		for worm in mole.worm_patch.worms:
			worm.queue_free()
		mole.worm_patch.worms.clear()
		mole.worm_patch.spawn_clock=999.0
		var worm: Node2D=mole.worm_patch.spawn_nearby()
		_require(worm!=null,"reachable worm")
		return
	if String(data.kind)=="worm_random":
		command_id=int(data.id)
		var mole: Node=main.get_node("CompanionInterface").active_mole()
		mole.worm_patch.spawn_clock=0.0
		return
	if String(data.kind)=="shrine_test":
		command_id=int(data.id)
		_test_shrines()
		return
	if String(data.kind) == "mole_fixture":
		command_id = int(data.id)
		_mole_fixture(String(data.scenario))
		return
	if String(data.kind) == "mole_shake":
		command_id = int(data.id)
		RunState.overhaul_progress["skills"] = {"shake":1}
		_require(main.get_node("CompanionInterface").active_mole().shake_nearby(),"Earthshaker command")
		return
	if String(data.kind) == "mole_recall":
		command_id = int(data.id)
		main.get_node("CompanionInterface").active_mole().recall()
		return
	if String(data.kind) == "menu_stamina_forge":
		command_id = int(data.id)
		main._open_forge_commerce()
		return
	if String(data.kind) == "menu_stamina_reset":
		command_id = int(data.id)
		RunState.miner_skills.stamina = 0.0
		RunState._stamina_rest = 0.0
		return
	if String(data.kind).begins_with("shared_"):
		command_id = int(data.id)
		var controller: Node = main.get_node("CompanionInterface")
		match String(data.kind):
			"shared_reference":
				if not is_instance_valid(shared_reference_layer):
					shared_reference_layer = CanvasLayer.new()
					shared_reference_layer.layer = 18
					main.add_child(shared_reference_layer)
					controller.ui_root.reparent(shared_reference_layer,false)
					controller.ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			"shared_candidate":
				if is_instance_valid(shared_reference_layer):
					controller.ui_root.reparent(main.get_node("HUD"),false)
					controller.ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
					shared_reference_layer.queue_free()
			"shared_freeze":
				Engine.time_scale = 0.0
				main.get_tree().paused = true
				for node in main.get_tree().root.find_children("*", "", true, false):
					if node.can_process() and node.is_processing():
						canvas_observers.append(node)
						node.set_process(false)
			"shared_resume":
				Engine.time_scale = 1.0
				for node in canvas_observers:
					if is_instance_valid(node): node.set_process(true)
				canvas_observers.clear()
				main.get_tree().paused = false
			"shared_presentation_on": main._set_deepheart_presentation(true)
			"shared_presentation_off": main._set_deepheart_presentation(false)
			"shared_reload": call_deferred("_reload_scene")
		return
	if String(data.kind) not in ["skills_fixture", "skills_edge_fixture", "skill_level_up", "fatigue_fixture"]:
		super._command(data)
		return
	command_id = int(data.id)
	fixture = String(data.kind)
	if fixture == "skills_fixture":
		RunState.miner_skills = {"mining": 21424.0, "running": 6280.0, "carrying": 10125.0, "prospecting": 3020.0, "stamina": 72.0}
		RunState.cargo.copper = 1240
		RunState.cargo.ambercore = 317
		RunState.cargo.lunacore = 86
		RunState._miner_level_cache.clear()
	elif fixture == "skills_edge_fixture":
		RunState.miner_skills = {"mining": 0.0, "running": 99.0, "carrying": 257500.0, "prospecting": 257499.0, "stamina": 72.0}
		RunState._miner_level_cache.clear()
	elif fixture == "skill_level_up":
		RunState._earn_miner_xp("running", 1.0)
	else:
		RunState.miner_skills.stamina = 0.0
		RunState._stamina_rest = 0.0
	main.miner_skills_panel.refresh()

func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var panel: Control = main.miner_skills_panel
	var progress: Array = []
	for row in panel.rows:
		progress.append({"level": row.level.text, "level_value": row.bar.value,
			"level_fits": row.level.get_theme_font("font").get_string_size(row.level.text, HORIZONTAL_ALIGNMENT_LEFT, -1, row.level.get_theme_font_size("font_size")).x <= row.level.size.x,
			"xp_value": row.xp_bar.value, "level_rect": _bounds(row.bar),
			"xp_rect": _bounds(row.xp_bar), "numeric_xp": row.xp != null})
	var bounds: Dictionary = {"prospecting_row": _bounds(panel.rows[3].node),"hud_menu": _bounds(main.premium_hud.menu_button),
		"dev_toggle": (_bounds(main.developer_menu.toggle_button) if is_instance_valid(main.developer_menu) else []),
		"new_game": _bounds(main.premium_menu.main_card.get_node("NewGame")),
		"continue": _bounds(main.premium_menu.continue_button),
		"shop_close": _bounds(main.commerce_panel.close_button),
		"settings_back": _bounds(main.premium_menu.detail_card.get_node("Back")),
		"skills_close": _bounds(panel.close_button),
		"joystick": _bounds(main.movement_pad),
		"hud_context":_bounds(main.premium_hud.context_button), "hud_mine": _bounds(main.mine_button), "hud_bag": _bounds(main.premium_hud.bag_button),
		"hud_guide": _bounds(main.premium_hud.guide_button),
		"hud_mole": _bounds(main.get_node("CompanionInterface").button),
		"mole_close": _bounds(main.get_node("CompanionInterface").journal.content.get_node("CloseJournal"))}
	var goal_panel: Control=main.treasury_goal_panel
	bounds["treasury_pin"]=_bounds(goal_panel.pin_button)
	bounds["treasury_claim"]=_bounds(goal_panel.claim_button)
	bounds["treasury_close"]=_bounds(goal_panel.close_button)
	bounds["minimap"]=_rect_bounds(main.minimap_overlay._map_rect)
	var gold_at: Vector2=main.hub_world.get_canvas_transform()*(main.hub_world.treasury.bay(26)+Vector2(0,-30))
	bounds["gold_podium"]=[gold_at.x-12,gold_at.y-12,24,24]
	for row in panel.rows + [panel.stamina_row]:
		bounds["stat_" + String(row.node.name).to_lower()] = _bounds(row.node)
	for i in 4: bounds[["inventory", "skills", "map", "settings"][i]] = _bounds(panel.nav[i])
	var close: Control = main.resource_inventory.get_node_or_null("Card/Layout/Header/Close")
	if close != null: bounds.inventory_close = _bounds(close)
	var ui: Node = main.get_node("CompanionInterface")
	for i in ui.journal.tabs.size(): bounds["mole_tab_"+str(i)] = _bounds(ui.journal.tabs[i])
	var saved_ui: int = 0
	for saved in main.presentation_hud_state:
		if saved.item == ui.ui_root: saved_ui += 1
	var state: Dictionary = {"journal_tab":ui.journal.tab,"shared_ui_visible":ui.ui_root.visible,
		"shared_ui_saved":saved_ui,"shared_ui_roots":main.get_node("HUD").find_children("CompanionUI","Control",true,false).size(),
		"skills_open": panel.visible, "map_open": panel._map_active,
		"inventory_open": main.inventory_open, "settings_open": main.premium_menu.detail_view.is_visible_in_tree(),
		"developer_tools_visible": is_instance_valid(main.developer_menu) and main.developer_menu.is_visible_in_tree(),
		"mine_input_held": main.mine_held or Input.is_action_pressed("mine"),
		"player_controls_enabled": main._active_player_node().control_enabled,
		"stamina": RunState.stamina_value(), "stamina_bar": panel.stamina_row.bar.value,
		"physics_frame": Engine.get_physics_frames(), "stamina_rest": RunState._stamina_rest,
		"game_started": main.game_started, "shop_open": main._shop_panel_is_open(),
		"modal_active": main.menu_open or main.inventory_open or main._shop_panel_is_open() or main._companion_panel_is_open(), "skill_xp": RunState.miner_skills.duplicate(true),
		"skills": RunState.miner_skill_rows(), "skill_progress": progress, "effort": RunState.stamina_effort_multiplier(),
		"buttons": bounds, "skills_plate": _bounds(panel.plate),
		"mole_open": main._companion_panel_is_open(), "guide_open": main.premium_hud._objective_open,
		"tooltip_visible": panel.stat_tip.visible, "tooltip_id": panel._tip_id,
		"tooltip_text": panel._tip_body.text, "tooltip_rect": _bounds(panel.stat_tip),
		"hud_caption": _bounds(main.premium_hud.menu_caption),
		"hud_caption_text": main.premium_hud.menu_caption.text,
		"hud_caption_visible": main.premium_hud.menu_caption.is_visible_in_tree(),
		"dev_drawer_open": (main.developer_menu.drawer.visible if is_instance_valid(main.developer_menu) else false),
		"hud_guide_visible": main.premium_hud.guide_button.is_visible_in_tree(),
		"hud_menu_icon": main.premium_hud.menu_button.icon.resource_path,
		"hud_context": _bounds(main.premium_hud.context_button),
		"hud_context_visible": main.premium_hud.context_button.is_visible_in_tree(),
		"hud_mine_visible": main.mine_button.is_visible_in_tree(),
		"hud_gold": _bounds(main.premium_hud.gold_cluster),
		"hud_map": _rect_bounds(main.premium_hud.minimap_layout_rect()),
		"hud_goal": _bounds(main.premium_hud.progression_goal_panel)}
	if is_instance_valid(panel.map_view):
		var rect: Rect2 = panel.map_view._map_rect
		state.map_rect = [rect.position.x, rect.position.y, rect.size.x, rect.size.y]
	if not mole_case.is_empty():
		var mole: Node2D = ui.active_mole()
		var world: Node2D = mole.world
		var p: Vector2 = world.get_canvas_transform()*mole_target
		var cancel: Vector2 = world.get_canvas_transform()*world.player.global_position
		var current: Dictionary = world.companion_work_target(mole_target)
		state["work"] = {"scenario":mole_case,"target":[p.x,p.y],"cancel":[cancel.x,cancel.y],"key":mole_task_key,"remaining":current.get("key","")==mole_task_key,"mole":mole.debug_snapshot(),"period":world.companion_work_period(),"power":world._mountain_tool().get("power",1) if world.has_method("_mountain_tool") else 0,"checks":mole_checks,"feedback":mole.feedback,"hero_period":world.companion_hero_period(mole.work_task)}
	if ore_escape_active:
		var mole: Node2D=ui.active_mole()
		state["ore_escape"]={"distance":mole.global_position.distance_to(ore_escape_origin),"remaining":mole.global_position.distance_to(ore_escape_goal),"checks":mole_checks,"mode":mole.mode}
	state["resonance"]=main.endless_world.resonance_drill.snapshot()
	state["resonance"]["dug"]=RunState.endless_dug_cells(main.endless_world.current_depth).size()
	state["resonance"]["variant"]=String(RunState.starforge_variant)
	state["treasury"]=main.hub_world.treasury.snapshot()
	state["treasury_goal"]={"open":goal_panel.visible,"kind":goal_panel.kind,"claim_disabled":goal_panel.claim_button.disabled,"claim_text":goal_panel.claim_button.text,"saved":RunState.treasury_goals.duplicate(true),"hud":main._progression_goal(),"rendered":main.premium_hud.progression_goal_snapshot()}
	state["actual_map"]={"markers":main._map_markers().size(),"known":WorldCatalog.WORLD_ORDER.map(func(w): return RunState.is_world_unlocked(w)),"expanded":is_instance_valid(panel.map_view) and panel.map_view.visible}
	var active_world: Node={"surface":main.surface_world,"mine":main.mine_world,"depth":main.depth_world,"hub":main.hub_world,"deepheart":main.deepheart_world,"endless":main.endless_world}.get(main.phase,main.surface_world)
	state["actual_map"]["world_active"]=active_world.is_visible_in_tree() and active_world.can_process()

	state["deep_events"]=main.endless_world.deep_events.snapshot()
	var rewards_world: Node=main.endless_world
	state["exposure"]={}
	for resource in rewards_world.resources:
		if String(resource.id)!=exposure_id: continue
		state["exposure"]={"id":exposure_id,"hp":int(resource.hp),"initial_hp":exposure_hp,"mined":bool(resource.mined),"floor":rewards_world._is_floor(Vector2i(resource.cell)),"visible":is_instance_valid(rewards_world.resource_visuals.get(exposure_id)) and rewards_world.resource_visuals[exposure_id].visible,"claimed":(int(RunState.endless_floor_resource_state(int(resource.depth)).mined_mask)&(1<<int(resource.node_index)))!=0}
	state["hub_context"]=main.hub_context
	state["hud_goal_visible"]=main.premium_hud.progression_goal_panel.visible
	state["hub_player"]=[main.hub_world.player.position.x,main.hub_world.player.position.y]
	state["deep_dig"]={"checks":deep_checks,"held":main.endless_world.external_mine_held,"movement":[main.endless_world.player.external_movement.x,main.endless_world.player.external_movement.y]}
	state["node_assets"]=node_asset_state
	state["prospecting"]={"checks":prospect_checks,"results":prospect_results,"level":RunState.miner_skill_level("prospecting")}
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE," + JSON.stringify(state) + ")", true)

func _bounds(control: Control) -> Array:
	var rect: Rect2 = control.get_global_rect()
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func _rect_bounds(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _mole_fixture(scenario: String) -> void:
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	RunState.overhaul_progress["skills"] = {}
	mole_case=scenario
	mole_checks={}
	var world: Node2D
	if scenario.begins_with("moss"):
		main._dev_jump_mine("mossMine",1)
		_gear("worn")
		world=main.mine_world
		_require(_place_moss(Vector2.RIGHT),"moss placement")
		var cell: Vector2i = world._find_mine_target()
		mole_target=world._cell_center(cell)
		var block: Dictionary = world._make_block("copper" if scenario=="moss_ore" else "stone",int(world._current_tool().power)*3,1,"resource" if scenario=="moss_ore" else "terrain")
		world._set_block(cell,block)
		world.target_dirty=true
		mole_checks["legacy_rejected_ore"]=not world.companion_can_dig(mole_target) if scenario=="moss_ore" else true
		block.requires_tool=99
		world._set_block(cell,block)
		mole_checks["tool_gate"]=world.companion_work_target(mole_target).is_empty()
		block.requires_tool=1
		block.kind="bedrock"
		world._set_block(cell,block)
		mole_checks["bedrock"]=world.companion_work_target(mole_target).is_empty()
		block.kind="copper" if scenario=="moss_ore" else "stone"
		world._set_block(cell,block)
	elif scenario=="endless_ore":
		main._dev_jump_endless(1)
		_gear("deepcore")
		world=main.endless_world
		_require(_place_endless(Vector2.RIGHT),"endless placement")
		var index: int = world._nearest_resource_index()
		mole_target=Vector2(world.resources[index].position)
		world.resources[index].hp=int(world._current_endless_tool().power)*3
	elif scenario=="depth_ore":
		main._dev_jump_mine("mossMine",2)
		_gear("deepcore")
		world=main.depth_world
		RunState.pickaxe_level=GameData.data.PICKAXES.size()-1
		# Explicitly reveal a real buried deposit for this isolated QA fixture.
		for index in world.rocks.size():
			var rock: Dictionary=world.rocks[index]
			if bool(rock.drill_gated) or bool(rock.broken): continue
			var center: Vector2i=rock.cell
			for y in range(-2,3):
				for x in range(-2,3):
					var cell: Vector2i=center+Vector2i(x,y)
					if not world._cell_in_bounds(cell) or world._terrain_is_bedrock(cell): continue
					world.terrain_hp[world._cell_index(cell)]=0
					world.concealed_cells.erase(world._cell_index(cell))
			for cavern in world.caverns:
				if String(cavern.id)==String(rock.cavern_id): cavern.discovered=true
			world._request_redraw()
			break
		var found: bool=false
		for index in world.rocks.size():
			if not world._rock_is_exposed(index): continue
			var point: Vector2=world.rocks[index].position
			if world.companion_work_target(point).is_empty(): continue
			for direction in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				var position: Vector2=point+direction*64.0
				world.restore_position(position)
				if world.player.global_position.distance_to(position)>2.0: continue
				world.player.set_facing(-direction)
				mole_target=point
				world.rocks[index].hp=int(world._current_tool().power)*3
				world.rocks[index].shell=0
				found=true
				break
			if found: break
		_require(found,"exposed depth resource")
	else:
		main._dev_jump_surface()
		_gear("worn")
		world=main.surface_world
		world.restore_position(Vector2(812,650))
		world.player.set_facing(Vector2.UP)
		world.ore_mountain_hp=int(world._mountain_tool().power)*3
		mole_target=world._ore_mountain_hit_point(world.player.global_position)
	var task: Dictionary=world.companion_work_target(mole_target)
	_require(not task.is_empty(),"manual target accepted: "+scenario)
	mole_task_key=String(task.get("key",""))
	var mole: Node2D=world.get_node("MoleCompanion")
	mole._spawn_beside_hero()
	mole.work_hits=0
	mole.autonomous_enabled=false
	mole.auto_work_clock=0.0
	main.get_node("CompanionInterface").worm_power_remaining=0.0
	if is_instance_valid(mole.worm_patch): mole.worm_patch.spawn_clock=999.0
	main._refresh_hud()

func _test_shrines() -> void:
	var timers=load("res://scripts/world/shrine_respawn.gd")
	mole_checks={}
	for depth in [1,2]:
		main._dev_jump_mine("mossMine",depth)
		var world: Node=main.mine_world if depth==1 else main.depth_world
		var caverns: Array=world.cavern_by_id.values() if depth==1 else world.caverns
		for index in caverns.size():
			var cavern: Dictionary=caverns[index]
			if String(cavern.reward.kind)!="shrine": continue
			var id: String=String(cavern.reward.id)
			RunState.mark_cavern_discovered(String(cavern.id))
			RunState.claimed_pocket_rewards[id]=true
			RunState.overhaul_progress["shrine_respawn"]={}
			if depth==2: world.shrine_cooldowns.clear()
			mole_checks["old-shrine-revives-"+str(depth)]=not world._pocket_reward_is_claimed(id)
			var plan: Dictionary=world._claim_pocket_reward(String(cavern.id)) if depth==1 else world._claim_pocket_reward(index)
			mole_checks["claim-"+str(depth)]=bool(plan.get("ok",false)) and world.mining_rush_remaining>0.0
			mole_checks["120-seconds-"+str(depth)]=timers.remaining(id)>119.0 and timers.remaining(id)<=120.0
			var clean: Dictionary=RunState._sanitize_overhaul(RunState.overhaul_progress)
			mole_checks["save-timer-"+str(depth)]=Dictionary(clean.get("shrine_respawn",{})).has(id)
			RunState.overhaul_progress["shrine_respawn"][id]=Time.get_unix_time_from_system()+0.2
			if depth==2: world.shrine_cooldowns[id]=0.2
			mole_checks["before-expiry-"+str(depth)]=world._pocket_reward_is_claimed(id)
			RunState.overhaul_progress["shrine_respawn"][id]=Time.get_unix_time_from_system()-0.1
			if depth==2: world._update_shrine_cooldowns(0.3)
			mole_checks["after-expiry-"+str(depth)]=not world._pocket_reward_is_claimed(id)
			break

func _ore_respawn_fixture(mine_id: String) -> void:
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	main._dev_jump_mine(mine_id,1)
	_gear("deepcore")
	# Let the normal world-change companion spawn finish before placing it.
	await main.get_tree().create_timer(0.2).timeout
	RunState.overhaul_progress["skills"]={}
	var world: Node2D=main.mine_world
	var mole: Node2D=world.get_node("MoleCompanion")
	var center:=Vector2i(-1,-1)
	# Use a genuine resource cell in this biome, clearing only fixture approaches.
	for cell in world.blocks:
		if String(world.blocks[cell].get("role",""))=="resource":
			center=cell
			break
	_require(center.x>=0,"resource in "+mine_id)
	var original: Dictionary=world.blocks[center].duplicate(true)
	for y in range(-4,5):
		for x in range(-4,5):
			world._erase_block(center+Vector2i(x,y))
	ore_escape_origin=world._cell_center(center)
	ore_escape_goal=ore_escape_origin+Vector2.RIGHT*world.TILE_SIZE*3.0
	world.player.global_position=ore_escape_origin+Vector2.LEFT*world.TILE_SIZE*3.0
	world.player.camera.reset_smoothing()
	mole._spawn_beside_hero()
	mole.global_position=ore_escape_origin
	mole.autonomous_enabled=false
	mole.mode="hold"
	mole.hold_time=0.0
	mole.destination=ore_escape_origin
	mole.worm_patch.spawn_clock=999.0
	world.drops.clear()
	world.respawns.clear()
	world.respawns.append({"cell":center,"block":original,"node_id":world._resource_node_id(center),"respawn_until_unix":Time.get_unix_time_from_system()-1.0,"remaining":0.0})
	world._update_respawns(0.0)
	mole_checks={"actual-respawn":world.blocks.has(center),"hero-still-blocked":world._player_collides(ore_escape_origin),"mole-not-blocked":not mole._blocked(ore_escape_origin),"escape-segment":mole._segment_clear(ore_escape_origin,ore_escape_goal)}
	var probe: Vector2i=center+Vector2i(0,3)
	for role in ["terrain","bedrock","test_barrier"]:
		var block: Dictionary=world._make_block("bedrock" if role=="bedrock" else "stone",5,1,role)
		world._set_block(probe,block)
		mole_checks[role+"-blocks-mole"]=mole._blocked(world._cell_center(probe))
		world._erase_block(probe)
	mole_checks["world-edge-blocked"]=mole._blocked(Vector2.ZERO)
	world._request_redraw()
	ore_escape_active=true
	mole_case=""
	main._refresh_hud()

func _set_prospect_level(level: int) -> void:
	var skills=load("res://scripts/progression/miner_skills.gd")
	RunState.miner_skills.prospecting=skills.threshold("prospecting",level)
	RunState._miner_level_cache.clear()

func _prospect_check(name: String, value: bool) -> void:
	prospect_checks[name]=value
	_require(value,"prospecting: "+name)

func _test_prospecting() -> void:
	prospect_checks={}
	prospect_results={}
	var skills=load("res://scripts/progression/miner_skills.gd")
	for level in [0,1,25,50,100]:
		var chance: float=float(level)*0.005
		_prospect_check("chance-"+str(level),is_equal_approx(skills.prospecting_chance(level),chance))
		_prospect_check("boundary-"+str(level),skills.prospecting_bonus(level,chance)==0)
		if level>0: _prospect_check("below-boundary-"+str(level),skills.prospecting_bonus(level,chance-0.000001)==1)
		var wins: int=0
		for sample in 2000: wins+=skills.prospecting_bonus(level,(float(sample)+0.5)/2000.0)
		_prospect_check("distribution-"+str(level),wins==level*10)
	_prospect_check("clamped-levels",skills.prospecting_chance(-3)==0.0 and skills.prospecting_chance(300)==0.5)
	_prospect_check("invalid-samples",skills.prospecting_bonus(100,NAN)==0 and skills.prospecting_bonus(100,-0.01)==0 and skills.prospecting_bonus(100,1.0)==0)
	_set_prospect_level(100)
	for kind in ["stone","deepstone","unknown"]:
		_prospect_check("no-bonus-"+kind,RunState.prospecting_yield(kind,2)==2)
	_prospect_check("empty-and-limit",RunState.prospecting_yield("copper",0)==0 and RunState.prospecting_yield("copper",RunState.MAX_MINE_LOOSE_DROP_AMOUNT)==RunState.MAX_MINE_LOOSE_DROP_AMOUNT)
	var cargo_before: int=int(RunState.cargo.get("copper",0))
	RunState.add_resource("copper",3,false)
	_prospect_check("pickup-no-reroll",int(RunState.cargo.copper)==cargo_before+3)
	cargo_before=int(RunState.cargo.copper)
	RunState.add_resource("copper",3,true)
	_prospect_check("grant-no-reroll",int(RunState.cargo.copper)==cargo_before+3)
	# Exercise real yield owners with the same seed at level0 and level100.
	for scenario in ["moss_ore","depth_ore"]:
		_mole_fixture(scenario)
		var world: Node2D=main.get_node("CompanionInterface").active_mole().world
		var cell: Vector2i=world._world_to_cell(mole_target)
		var template: Dictionary={}
		var rock_index: int=-1
		if scenario=="moss_ore": template=world.blocks[cell].duplicate(true)
		else:
			for index in world.rocks.size():
				if Vector2(world.rocks[index].position).distance_to(mole_target)<1.0:
					rock_index=index
					template=world.rocks[index].duplicate(true)
					break
		var kind: String=String(template.kind if scenario=="moss_ore" else template.type)
		for gear in (["worn","crown"] if scenario=="moss_ore" else ["deepcore"]):
			_gear(gear)
			var bonuses: int=0
			for trial in 16:
				var yields: Array[int]=[]
				for level in [0,100]:
					_set_prospect_level(level)
					var before: int=int(RunState.mined.get(kind,0))
					seed(100+trial)
					if scenario=="moss_ore":
						var block: Dictionary=template.duplicate(true)
						block.hp=1
						block.shell=0
						world._set_block(cell,block)
						world.companion_work_hit(world.companion_work_target(mole_target))
					else:
						world.rocks[rock_index]=template.duplicate(true)
						world._break_rock(rock_index)
					yields.append(int(RunState.mined.get(kind,0))-before)
				_prospect_check(scenario+gear+str(trial),yields[0]>0 and yields[1]>=yields[0] and yields[1]<=yields[0]+1)
				bonuses+=yields[1]-yields[0]
			_prospect_check(scenario+gear+"-bonus-observed",bonuses>0)
			prospect_results[scenario+gear]=bonuses
	_mole_fixture("surface")
	var surface: Node2D=main.surface_world
	RunState.area_unlocked=true
	RunState.emberdeep_unlocked=true
	RunState.fourth_unlocked=true
	for vein in ["moon","ember_fault","starfall_lattice","mountain"]:
		var bonuses: int=0
		for trial in 16:
			var yields: Array[int]=[]
			for level in [0,100]:
				_set_prospect_level(level)
				seed(100+trial)
				if vein=="mountain":
					for drop in surface.ore_drops: drop.sprite.queue_free()
					surface.ore_drops.clear()
					surface.ore_mountain_hp=100
					surface.ore_mountain_copper_yield_buffer=1.0
					var before: int=surface.ore_drops.size()
					surface._mine_ore_mountain_once(true)
					yields.append(surface.ore_drops.size()-before)
				else:
					var kind: String="moonglass" if vein=="moon" else String(surface._timed_surface_config(vein).resource)
					var before: int=int(RunState.mined.get(kind,0))
					if vein=="moon":
						for index in surface.moon_bloom_nodes.size(): surface.moon_bloom_nodes[index].hp=10
						surface.moon_bloom_nodes[0].hp=1
						surface.moon_bloom_target_index=0
						surface._mine_moonglass_resource_once(true)
					else:
						var runtime: Dictionary=surface.timed_surface_veins[vein]
						for index in runtime.nodes.size(): runtime.nodes[index].hp=10
						runtime.nodes[0].hp=1
						runtime.nodes[0].shell=0
						runtime.target_index=0
						surface.timed_surface_veins[vein]=runtime
						surface._mine_timed_surface_resource_once(vein,true)
					yields.append(int(RunState.mined.get(kind,0))-before)
			_prospect_check(vein+str(trial),yields[0]>0 and yields[1]>=yields[0] and yields[1]<=yields[0]+1)
			bonuses+=yields[1]-yields[0]
		_prospect_check(vein+"-bonus-observed",bonuses>0)
		prospect_results[vein]=bonuses
	RunState.victory=true
	RunState.endless_descent_active=true
	RunState.endless_current_depth=1
	for method in ["claim_endless_resource_node","claim_endless_rock_cell"]:
		var bonuses: int=0
		for trial in 16:
			RunState.endless_chunks={}
			_set_prospect_level(100)
			seed(100+trial)
			var before: int=int(RunState.cargo.get("lumenstone",0))
			var result: Dictionary=RunState.call(method,1,0,"lumenstone",2)
			_prospect_check(method+str(trial),bool(result.ok) and int(result.amount) in [2,3] and int(RunState.cargo.lumenstone)==before+int(result.amount))
			bonuses+=int(result.amount)-2
			var repeated: Dictionary=RunState.call(method,1,0,"lumenstone",2)
			_prospect_check(method+"-once-"+str(trial),not bool(repeated.ok) and int(RunState.cargo.lumenstone)==before+int(result.amount))
		_prospect_check(method+"-bonus-observed",bonuses>0)
		prospect_results[method]=bonuses
	# Existing save schema stores the skill XP; restoration keeps earned level/bonus.
	_set_prospect_level(50)
	var clean: Dictionary=skills.restore(RunState.miner_skills,skills.BALANCE_REVISION)
	_prospect_check("existing-level-preserved",skills.level("prospecting",clean)==50 and skills.prospecting_chance(skills.level("prospecting",clean))==0.25)
	_mole_fixture("moss_ore")
	_set_prospect_level(50)


func _node_asset_fixture(mine_id: String) -> void:
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	_gear("deepcore")
	_require(main._dev_jump_mine(mine_id,2),"depth node entry")
	await main.get_tree().process_frame
	await main.get_tree().process_frame
	var world: Node2D=main.depth_world
	var mole: Node=main.get_node("CompanionInterface").active_mole()
	mole.recall()
	mole.autonomous_enabled=false
	mole.worm_patch.spawn_clock=999.0
	node_asset_index=-1
	for i in world.rocks.size():
		var rock: Dictionary=world.rocks[i]
		if rock.drill_gated or rock.broken or String(rock.type)=="deepstone" or not String(rock.pocket_reward_id).is_empty(): continue
		if not world._terrain_is_solid(rock.cell): continue
		node_asset_index=i
		break
	_require(node_asset_index>=0,"authored buried renewable ore")
	var rock: Dictionary=world.rocks[node_asset_index]
	var cell: Vector2i=rock.cell
	# Isolated reached corridor; preserve the actual target and its covering rock.
	for y in range(1,5):
		for x in range(-5,6):
			var c: Vector2i=cell+Vector2i(x,y)
			if not world._cell_in_bounds(c) or world._terrain_is_bedrock(c): continue
			var index: int=world._cell_index(c)
			world.terrain_hp[index]=0
			world.concealed_cells.erase(index)
			RunState.mark_terrain_dug(mine_id,index,2)
	if not String(rock.cavern_id).is_empty():
		RunState.mark_cavern_discovered(String(rock.cavern_id))
		for cavern in world.caverns:
			if String(cavern.id)==String(rock.cavern_id):
				cavern.discovered=true
				for index in cavern.cells: world.concealed_cells.erase(int(index))
	node_asset_origin=world._cell_center(cell+Vector2i(2,2))
	world.restore_position(node_asset_origin)
	world.player.set_facing(Vector2.UP)
	world.player.camera.reset_smoothing()
	world._request_redraw()
	node_asset_state={"mine":mine_id,"type":String(rock.type),"state_id":String(rock.state_id),"stage":"first","checks":{},"node_asset":world.resource_textures[String(rock.type)].resource_path,"old_hint_asset":world.wall_hint_textures.get(String(rock.type),world.resource_textures[String(rock.type)]).resource_path}
	_node_asset_check("initial-covered",world._terrain_is_solid(cell) and not world._rock_is_exposed(node_asset_index))
	_node_asset_check("initial-intact",int(rock.hp)==int(rock.max_hp) and not bool(rock.broken))
	_node_asset_check("ore-asset-exists",world.resource_textures[String(rock.type)]!=null)
	_node_asset_check("bedrock-preserved",world._terrain_is_bedrock(Vector2i(0,1)) and world._terrain_is_solid(Vector2i(0,1)))

func _node_asset_check(key: String, value: bool) -> void:
	node_asset_state.checks[key]=value
	_require(value,"node assets: "+key)

func _node_asset_stage(stage: String) -> void:
	var world: Node2D=main.depth_world
	var rock: Dictionary=world.rocks[node_asset_index]
	if stage=="exposed":
		for hit in 200:
			if not world._terrain_is_solid(rock.cell): break
			world._hit_terrain(rock.cell,true)
		_node_asset_check("excavation-exposes-node",world._rock_is_exposed(node_asset_index))
		_node_asset_check("excavation-keeps-ore",not bool(rock.broken) and int(rock.hp)==int(rock.max_hp))
	elif stage=="respawn":
		for hit in 200:
			if bool(world.rocks[node_asset_index].broken): break
			world._hit_rock(node_asset_index,true)
		_node_asset_check("mining-depletes-node",bool(world.rocks[node_asset_index].broken))
		world.rocks[node_asset_index].respawn_until_unix=Time.get_unix_time_from_system()-1.0
		world.restore_position(node_asset_origin+Vector2(0,240))
		world._update_rocks()
		world.restore_position(node_asset_origin)
		rock=world.rocks[node_asset_index]
		_node_asset_check("respawn-restores-node",not bool(rock.broken) and int(rock.hp)==int(rock.max_hp) and world._rock_is_exposed(node_asset_index))
		_node_asset_check("same-node-asset",world.resource_textures[String(rock.type)].resource_path==node_asset_state.node_asset)
	elif stage=="reenter":
		world._build_world()
		world.restore_position(node_asset_origin)
		rock=world.rocks[node_asset_index]
		_node_asset_check("reentry-keeps-node",not bool(rock.broken) and world._rock_is_exposed(node_asset_index) and String(rock.state_id)==node_asset_state.state_id)
	world.impacts.clear()
	world.drops.clear()
	world.player.camera.reset_smoothing()
	world._request_redraw()
	node_asset_state.stage=stage


func _deep_check(name_value: String, passed: bool) -> void:
	deep_checks[name_value]=passed
	_require(passed, "deep: " + name_value)


func _deep_command(kind: String) -> void:
	var w: Node = main.endless_world
	if kind == "deep_hub":
		main._dev_jump_hub()
		main._dev_seed_victory_state()
		main.hub_world._refresh_backend_state()
		main.hub_world.restore_position(main.hub_world.DEEP_ELEVATOR+Vector2(-74,96))
		_deep_check("hub-elevator-complete",bool(main.hub_world.elevator_status.powered) and bool(main.hub_world.elevator_status.victory))
	elif kind == "deep_fixture":
		main._dev_jump_endless(1)
		_gear("deepcore")
		await main.get_tree().process_frame
		var mole: Node = main.get_node("CompanionInterface").active_mole()
		mole.autonomous_enabled=false
		mole.recall()
		w.player.set_facing(Vector2.DOWN)
		var layout: Dictionary = w.DeepLayout.generate(int(RunState.world_seed), 2)
		_deep_check("new-band-solid", PackedByteArray(layout.cells).count(1)==0)
		_deep_check("entrance-walkable",w._position_walkable(w.player.global_position))
		_deep_check("resources-retained",w.resources.size()>0)
		_deep_check("buried-sites-hidden",not w.discovery_visuals.values()[0].visible)
		deep_before=RunState.endless_dug_cells(1).size()
	elif kind == "deep_mine":
		w.set_external_movement(Vector2(0.03,1.0))
		w.set_mine_held(true)
	elif kind == "deep_stop":
		w.set_external_movement(Vector2.ZERO)
		w.set_mine_held(false)
		_deep_check("held-direction-excavates",RunState.endless_dug_cells(1).size()>deep_before+1)
		_deep_check("released-hold",not w.external_mine_held)
	elif kind == "deep_drop_test":
		w.player.set_facing(Vector2.DOWN)
		var cell: Vector2i=w._nearest_diggable_wall()
		# The held sequence may end between walls. Walk up to the next one.
		w.player.external_movement=Vector2.DOWN
		for tick in 240:
			if cell.x>=0: break
			w.player._physics_process(1.0/120.0)
			cell=w._nearest_diggable_wall()
		w.player.external_movement=Vector2.ZERO
		_deep_check("next-rock-reachable",cell.x>=0)
		if cell.x<0: return
		var depth: int=w.depth_at_position(w._cell_center(cell))
		var index: int=w._chunk_cell_index(cell)
		var reward: Dictionary=w.DeepLayout.ore_for_cell(int(RunState.world_seed),depth,index)
		deep_drop_kind=String(reward.kind)
		deep_cargo_before=int(RunState.cargo.get(deep_drop_kind,0))
		_deep_check("rock-breaks",w._break_diggable_cell(cell))
		deep_drop_key="%d:c%d" % [depth,index]
		deep_drop_amount=int(RunState.endless_loose_drops(depth)["c%d" % index].amount)
		_deep_check("drop-before-cargo",int(RunState.cargo.get(deep_drop_kind,0))==deep_cargo_before)
		_deep_check("no-double-rock-claim",not w._break_diggable_cell(cell))
		var clean: Dictionary=RunState.EndlessTerrainStateScript.sanitize(RunState.endless_chunks,100000)
		_deep_check("drop-survives-save-sanitizer",clean[str(depth)].drops.has("c%d" % index))
		w.set_process(false)
	elif kind == "deep_reload_test":
		var before: Dictionary=RunState.endless_loose_drops(1)
		_deep_check("save-with-loose-drop",RunState.save_game("user://deep-dig-qa.sav"))
		RunState.endless_chunks.clear()
		_deep_check("reload-with-loose-drop",RunState.load_game("user://deep-dig-qa.sav"))
		_deep_check("saved-drops-exact",RunState.endless_loose_drops(1)==before)
		w.load_depth(1,"from_above")
		w.set_process(false)
		_deep_check("reloaded-drop-visible",w.loose_drops.has(deep_drop_key))
	elif kind == "deep_collect_test":
		if not w.loose_drops.has(deep_drop_key):
			_deep_check("drop-available-for-pickup",false)
			return
		var drop: Dictionary=w.loose_drops[deep_drop_key]
		w.player.global_position=drop.visual.position
		w._update_loose_drops(0.6)
		_deep_check("pickup-adds-cargo",int(RunState.cargo.get(deep_drop_kind,0))>=deep_cargo_before+deep_drop_amount)
		_deep_check("pickup-once",RunState.collect_endless_drop(int(drop.depth),String(drop.id)).is_empty())
		w.set_process(true)
	elif kind == "deep_discovery_test":
		main._dev_jump_endless(1)
		await main.get_tree().process_frame
		var relic: Dictionary=w._native_relics[0]
		var visual: Node2D=w._native_relic_visuals[String(relic.id)]
		_deep_check("relic-buried",not w._is_floor(w._world_to_cell(relic.position)))
		_deep_check("relic-invisible",not visual.visible)
		# Camera-only inspection fixture: no discovery or terrain override yet.
		w.player.camera.position=Vector2(relic.position)-w.player.position
		w.player.camera.reset_smoothing()
	elif kind == "deep_reveal_test":
		var relic: Dictionary=w._native_relics[0]
		var center: Vector2i=w._world_to_cell(relic.position)
		# Excavate through the production atomic claim, not a visual visibility flag.
		for y in range(center.y-2,center.y+3):
			for x in range(center.x-2,center.x+3): w._break_diggable_cell(Vector2i(x,y))
		w.player.camera.position=Vector2.ZERO
		w.restore_position(Vector2(relic.position)+Vector2(0,64))
		w._update_discoveries()
		w._update_buried_visibility()
		_deep_check("excavation-reveals-relic",w._native_relic_visuals[String(relic.id)].visible)
		_deep_check("relic-discovered",RunState.relic_status(String(relic.id)).get("discovered",false))

	elif kind == "deep_stream_test":
		w.set_process(false)
		w.player.set_physics_process(false)
		for next_depth in [2,3,4]:
			var seam: int=(next_depth-w.window_start_depth)*w.DeepLayout.CHUNK_ROWS
			for row in range(seam-2,seam+3):
				for col in range(18,21): w._break_diggable_cell(Vector2i(col,row))
			var point: Vector2=w._cell_center(Vector2i(19,seam+1))
			w.player.global_position=point
			w._on_player_moved(point)
			_deep_check("stream-depth-%d" % next_depth,w.current_depth==next_depth)
			_deep_check("stream-walkable-%d" % next_depth,w._position_walkable(w.player.global_position))
			_deep_check("stream-bounded-%d" % next_depth,w.floor_cells.size()==2640)
		var anchor: Vector2=w.player.global_position
		w._store_stream_anchor()
		w.load_depth(4,"from_above")
		_deep_check("deep-anchor-reload",w.player.global_position.distance_to(anchor)<1.0)
		w.set_process(true)
		w.player.set_physics_process(true)


func _treasury_command(data: Dictionary) -> void:
	var room: Node=main.hub_world.treasury
	match String(data.kind):
		"treasury_fixture":
			main._dev_jump_hub()
			main._dev_seed_victory_state()
			await main.get_tree().process_frame
			RunState.treasury_totals={}
			RunState.cargo=RunState._empty_resource_store()
			RunState.cargo.stone=8000
			RunState.cargo.copper=4000
			RunState.cargo.echo_crystal=1800
			RunState.cargo.prismite=2400
			RunState.cargo.starshard=3200
			RunState.gold=20000
			main.hub_world.restore_position(main.hub_world.TREASURY_DOOR+Vector2(-65,0))
			main.hub_world._refresh_backend_state()
		"treasury_map_first":
			if room.inside: room.leave()
			main._dev_jump_surface()
			RunState.area_unlocked=false
			RunState.emberdeep_unlocked=false
			RunState.fourth_unlocked=false
			main._update_minimap()
		"treasury_map_all":
			main._dev_seed_victory_state()
			main._update_minimap()
		"treasury_earned_drill":
			_require(bool(RunState.treasury_goals.get("resonance_claimed",false)),"mod earned through actual podium")
			main.endless_world.resonance_drill.dev_override=false
			main._dev_jump_endless(1)
			main._dev_grant_max_tools_state()
			var mole: Node=main.get_node("CompanionInterface").active_mole()
			mole.autonomous_enabled=false
			mole.recall()
			main.endless_world.player.set_facing(Vector2.DOWN)
		"treasury_door":
			main.hub_world.restore_position(main.hub_world.TREASURY_DOOR+Vector2(-65,0))
		"treasury_zone":
			main.hub_world.restore_position(room.ZONE+Vector2(-115,0))
		"treasury_exit_approach":
			main.hub_world.restore_position(room.EXIT+Vector2(70,0))
		"treasury_save":
			RunState.set_location("hub",main.hub_world.player.global_position)
			_require(RunState.flush_save(),"treasury actual save")
		"treasury_restore":
			room.stop()
			_require(RunState.load_game(),"treasury actual load")
			main.hub_world.restore_position(RunState.current_position)
			room.refresh_piles()
		"treasury_milestones":
			room.stop()
			RunState.treasury_totals={"stone":990}
			RunState.cargo=RunState._empty_resource_store()
			RunState.cargo.stone=2020
			RunState.cargo.copper=20
			RunState.gold=0
			room.refresh_piles()
			main.hub_world.restore_position(room.ZONE+Vector2(-115,0))
			room.armed=true
		"treasury_visual":
			room.stop()
			room.armed=false
			for kind in room.Ledger.keys(): RunState.treasury_totals[kind]=int(data.amount)
			room.refresh_piles()
			var aim: Vector2=room.bay(int(data.get("index",0)))
			main.hub_world.restore_position(aim+(room.ZONE-aim).normalized()*200.0+Vector2(0,40))
			_require(main.hub_world.player.global_position.distance_to(aim)<320.0,"scale camera reaches requested bay")
			main.hub_world.player.camera.reset_smoothing()
		"treasury_full":
			room.stop()
			room.armed=false
			main.hub_world.restore_position(room.ZONE)
			for kind in room.Ledger.keys(): RunState.treasury_totals[kind]=10000
			room.refresh_piles()
		"treasury_shop":
			if room.inside: room.leave()
			RunState.cargo.stone=100
			main.hub_world.restore_position(main.hub_world.HUB_SHOP+Vector2(0,85))
		"treasury_event":
			main._dev_jump_endless(1)
			_gear("deepcore")
			await main.get_tree().process_frame
			var w: Node=main.endless_world
			var state: Dictionary=w.deep_events.state()
			state.next=int(state.mined)+1
			state.remaining=0.0
			w.deep_events.on_rock(w._world_to_cell(w.player.global_position))
			state.kind=String(data.get("event","ancient_core"))
			w.deep_events._refresh_visuals()

func _resonance_command(data: Dictionary) -> void:
	var w: Node = main.endless_world
	var fx: Node = w.resonance_drill
	match String(data.kind):
		"resonance_fixture":
			main._on_developer_command_requested("test_resonance")
			var mole: Node=main.get_node("CompanionInterface").active_mole()
			mole.autonomous_enabled=false
			mole.recall()
			w.player.set_facing(Vector2.DOWN)
		"resonance_aim":
			main._cancel_mine_hold()
			main._on_joystick_movement(Vector2.ZERO)
			fx.reset()
			w.player.set_facing(Vector2(float(data.x),float(data.y)))
			fx.charge=1.0
		"resonance_fire":
			fx.on_hit(0.1)
		"resonance_freeze":
			w.set_process(false)
			w.set_physics_process(false)
			w.player.set_physics_process(false)
		"resonance_resume":
			w.set_process(true)
			w.set_physics_process(true)
			w.player.set_physics_process(true)
		"resonance_off":
			fx.set_enabled(false)


func _scale_command(data: Dictionary) -> void:
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	var mode: String = String(data.kind)
	if mode == "scale_surface":
		main._dev_seed_victory_state()
		main._dev_jump_surface()
		_gear("worn")
		var world: Node2D = main.surface_world
		var positions: Array = [Vector2(812,680),Vector2(2000,705),Vector2(3130,705),Vector2(4340,705)]
		world.restore_position(positions[int(data.get("index",0))])
		world.player.set_facing(Vector2.UP)
		world.player.camera.reset_smoothing()
	elif mode == "scale_depth1":
		main._dev_jump_mine(String(data.mine_id),1)
		_gear("deepcore")
		_require(_place_moss(Vector2.UP),"scale depth-one mining target")
		main.mine_world.player.camera.reset_smoothing()
	elif mode == "scale_deep":
		main._dev_jump_endless(1)
		_gear("deepcore")
		var world: Node2D = main.endless_world
		var selected: Dictionary = {}
		for resource in world.resources:
			if not bool(resource.mined):
				selected=resource
				break
		_require(not selected.is_empty(),"scale Deep authored resource exists")
		if selected.is_empty(): return
		# The continuous Deep keeps ore buried. Explicit QA reached pocket,
		# rather than assuming a random seed offers an already walkable node.
		var cell: Vector2i = Vector2i(selected.cell)
		for y in range(-2,4):
			for x in range(-3,4):
				var at: Vector2i=cell+Vector2i(x,y)
				if world._cell_diggable(at): world._set_floor(at,true)
		world._update_buried_visibility()
		world.queue_redraw()
		world.restore_position(world._cell_center(cell+Vector2i(2,2)))
		world.player.set_facing(Vector2(-1,-1).normalized())
		world.player.camera.reset_smoothing()
		var visual: Node2D=world.resource_visuals[String(selected.id)]
		_require(visual.visible and world._is_floor(cell),"scale Deep node visibly exposed")
		var mole: Node=main.get_node("CompanionInterface").active_mole()
		mole.recall()
		mole.autonomous_enabled=false
	elif mode == "scale_drops":
		# Real material textures in a clearly isolated scale fixture, beside the real hero.
		var world: Node2D = main._active_player_node().get_parent()
		var actor: Node2D = main._active_player_node()
		var drop_style = load("res://scripts/world/drop_visuals.gd")
		for i in RunState.RESOURCE_IDS.size():
			var kind: String = String(RunState.RESOURCE_IDS[i])
			var texture: Texture2D = load(RunState._resource_drop_texture_path(kind))
			var sprite: Sprite2D = Sprite2D.new()
			sprite.texture=texture
			sprite.scale=drop_style.sprite_scale(kind,texture)
			sprite.offset=drop_style.sprite_offset(kind,texture)
			sprite.position=actor.position+Vector2(110+(i%7)*48,-100+(i/7)*48)
			sprite.z_index=3500
			world.add_child(sprite)
	elif mode == "scale_walk_bay":
		var room: Node=main.hub_world.treasury
		var index: int=int(data.get("index",0))
		main.hub_world.restore_position(room.bay(index)+Vector2(0,130))
		main.hub_world.player.camera.reset_smoothing()
	await main.get_tree().process_frame
