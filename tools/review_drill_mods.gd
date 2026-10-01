extends SceneTree
var Goals
var main: Node
var world: Node
var state: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func verify(ok: bool,label: String) -> void:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	assert(ok,label)
func capture(label: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	output=OS.get_environment("MODS_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main);current_scene=main
	for i in 5: await process_frame
	state=root.get_node("RunState")
	Goals=load("res://scripts/state/treasury_goals.gd")
	state.initialize_persistence(output.path_join("save.json"));state.reset_run(false)
	main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_jump_hub()
	var p: Control=main.treasury_goal_panel
	state.treasury_goals=Goals.clean({"resonance_claimed":true,"resonance_enabled":true})
	verify(Goals.active_mod()=="resonance","old-save-resonance-retained")
	for kind in ["burrowsteel","prismite"]:
		for amount in [0,56000,100000]:
			state.treasury_totals[kind]=amount
			p.open_goal(kind)
			verify(p.preview.texture!=null,"art-"+kind+str(amount))
			verify(p.progress_bar.value==amount,"progress-"+kind+str(amount))
			verify(p.claim_button.disabled==(amount<100000),"gate-"+kind+str(amount))
			if amount<100000: verify(not Goals.claim(kind),"deny-unearned-"+kind+str(amount))
			Goals.pin(kind);verify(Goals.hud_goal().hud_title==Goals.NAMES[Goals.mod_id(kind)],"tracked-name-"+kind+str(amount));Goals.pin(kind)
			await capture(kind+"-"+str(amount));p.close_panel()
		p.open_goal(kind);p._claim()
		verify(Goals.active_mod()==Goals.mod_id(kind),"claim-equips-"+kind)
		verify(not state.treasury_goals.resonance_enabled,"exclusive-"+kind)
		verify(int(state.treasury_totals[kind])==100000,"claim-keeps-pile-"+kind)
		verify(not Goals.claim(kind),"no-double-claim-"+kind)
		await capture(kind+"-claimed")
		p._claim();verify(Goals.active_mod()=="","disable-"+kind)
		p.close_panel()
	var clean: Dictionary=Goals.clean(state.treasury_goals)
	verify(clean.bore_rush_claimed and clean.laser_claimed and clean.resonance_claimed,"all-unlocks-sanitize")
	main._dev_jump_endless(1);main._dev_grant_max_tools_state()
	world=main.endless_world
	world.resonance_drill.set_enabled(false)
	var mole: Node=main.get_node("CompanionInterface").active_mole();mole.autonomous_enabled=false;mole.recall()
	main.achievement_toast.hide()
	Goals.toggle("prismite")
	world.player.set_facing(Vector2.RIGHT)
	var start: Vector2i=Vector2i(12,8)
	for y in range(7,10):
		for x in range(11,28): world._set_floor(Vector2i(x,y),x<14)
	world.player.global_position=world._cell_center(start)
	world.player.camera.reset_smoothing()
	await create_timer(0.2).timeout
	world.set_mine_held(true)
	await create_timer(0.08).timeout
	verify(not world._is_floor(start+Vector2i(2,0)),"laser-not-instant")
	await create_timer(1.0).timeout
	await capture("laser-cutting")
	verify(world.drill_modes.impacts>=2,"laser-cuts-sequentially")
	verify(not world._is_floor(start+Vector2i(3,1)) and not world._is_floor(start+Vector2i(3,-1)),"laser-one-cell-width-no-crusher")
	world.set_mine_held(false)
	var impacts: int=world.drill_modes.impacts
	await create_timer(0.35).timeout
	verify(world.drill_modes.impacts==impacts and not world.drill_modes.firing,"laser-release-stops")
	main.laser_button.pressed.emit()
	verify(not state.treasury_goals.laser_mode,"HUD-toggle-off")
	main.laser_button.pressed.emit()
	verify(state.treasury_goals.laser_mode,"HUD-toggle-on")
	await capture("laser-button")
	Goals.toggle("burrowsteel");world.drill_modes.reset()
	world.player.set_facing(Vector2.RIGHT)
	var before: Vector2=world.player.global_position
	world.set_mine_held(true)
	await create_timer(1.2).timeout
	verify(world.player.global_position.x>before.x+40,"bore-hold-advances")
	await capture("bore-advancing")
	world.set_mine_held(false)
	before=world.player.global_position
	await create_timer(0.3).timeout
	verify(world.player.global_position.distance_to(before)<0.1,"bore-release-stops")
	world.set_mine_held(true)
	main._open_start_menu()
	before=world.player.global_position
	await create_timer(0.25).timeout
	verify(world.player.global_position.distance_to(before)<0.1,"menu-stops-bore")
	main._continue_from_menu()
	world.set_mine_held(false)
	# Both modes must reveal a real buried node before separately mining it.
	world.set_process(false);world.player.set_physics_process(false)
	for id in ["laser","bore_rush"]:
		world.drill_modes.dev_override=id
		var idx: int=-1
		for i in world.resources.size():
			var c: Vector2i=world.resources[i].cell
			if not world.resources[i].mined and c.x>4 and c.x<30 and c.y>3 and c.y<18:
				idx=i;break
		verify(idx>=0,"real-node-fixture-"+id)
		var ore: Dictionary=world.resources[idx]
		var cell: Vector2i=ore.cell
		for y in range(-1,2):
			for x in range(-2,0): world._set_floor(cell+Vector2i(x,y),true)
		world._set_floor(cell,false)
		world.player.global_position=world._cell_center(cell-Vector2i.RIGHT)
		world.player.set_facing(Vector2.RIGHT)
		world.set_mine_held(true)
		for i in 8:
			world.drill_modes.tick(0.05)
			if world._is_floor(cell): break
		verify(world._is_floor(cell),"rock-revealed-"+id)
		verify(not world.resources[idx].mined and world.resources[idx].hp==ore.hp,"node-survives-reveal-"+id)
		await capture("node-revealed-"+id)
		for i in 8: world.drill_modes.tick(0.05)
		verify(world.resources[idx].mined,"node-separate-hit-"+id)
		world.set_mine_held(false)
	world.drill_modes.dev_override=""
	world.set_process(true);world.player.set_physics_process(true)
	Goals.pin("prismite");state.flush_save()
	var saved: Dictionary=state.treasury_goals.duplicate(true)
	state.treasury_goals={}
	verify(state.load_game(),"load-real-save")
	verify(state.treasury_goals==Goals.clean(saved),"save-retains-unlocks-active-pin")
	main._on_developer_command_requested("test_laser")
	verify(world.drill_modes.selected()=="laser","dev-laser-with-earned-bore")
	main._on_developer_command_requested("test_resonance")
	verify(world.drill_modes.selected()=="" and world.resonance_drill.enabled,"dev-resonance-with-earned-bore")
	main._on_developer_command_requested("test_bore_rush")
	verify(world.drill_modes.selected()=="bore_rush","dev-bore")
	world.set_mine_held(true);world.drill_modes.tick(0.02)
	world.set_active(false)
	verify(not world.player.drill_motion_override,"exit-clears-auto-motion")
	world.set_active(true)
	await capture("final")
	print("DRILL_MODS_OK");quit(0)
