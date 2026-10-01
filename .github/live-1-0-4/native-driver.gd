extends SceneTree
var main: Node
var state: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func verify(ok: bool,label: String) -> void:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not ok:
		push_error("EXPOSURE_CHECK_FAILED "+label)
		quit(2)
func capture(label: String) -> void:
	main.achievement_toast.clear()
	main._update_minimap()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	output=OS.get_environment("EXPOSURE_REVIEW_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 5: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_jump_endless(1)
	for i in 6: await process_frame
	var w: Node=main.endless_world
	var mole: Node=main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled=false
	mole.set_process(false)
	mole.set_physics_process(false)
	w.set_process(false)
	w.player.set_physics_process(false)
	state.deep_events={}
	var events: Node=w.deep_events
	events.state().next=2000000
	var chosen: Array=[]
	for i in w.resources.size():
		if int(w.resources[i].depth)==1 and not bool(w.resources[i].mined): chosen.append(i)
	verify(chosen.size()>=3,"three real buried nodes available")
	if chosen.size()<3:return
	for mode in ["crusher","resonance","direct"]:
		var index: int=int(chosen[["crusher","resonance","direct"].find(mode)])
		var resource: Dictionary=w.resources[index]
		var cell: Vector2i=resource.cell
		var hp: int=int(resource.hp)
		state.endless_current_depth=int(resource.depth)
		w._set_floor(cell,false)
		w._update_buried_visibility()
		verify(not w.resource_visuals[String(resource.id)].visible,"buried node hidden: "+mode)
		w._strike_resource(index,999999,false)
		verify(not resource.mined and int(resource.hp)==hp,"buried node rejects direct damage: "+mode)
		w.player.global_position=w._cell_center(cell+Vector2i.UP)
		w._set_floor(cell+Vector2i.UP,true)
		w.player.set_facing(Vector2.DOWN)
		w.player.camera.reset_smoothing()
		await capture(mode+"-buried")
		if mode=="crusher":
			w._apply_crusher_wave(cell+Vector2i.LEFT,{"power":999999})
		elif mode=="resonance":
			state.drill_level=3
			w.resonance_drill.set_enabled(true)
			w.resonance_drill.charge=1.0
			w.resonance_drill.on_hit(0.1)
			for row in 12:w.resonance_drill._advance_row()
		else:w._break_diggable_cell(cell)
		w._update_buried_visibility()
		verify(w._is_floor(cell) and w.resource_visuals[String(resource.id)].visible,"first attack exposes node: "+mode)
		verify(not resource.mined and int(resource.hp)==hp,"first attack leaves node fully intact: "+mode)
		var node_key: String="n%d"%int(resource.node_index)
		verify(not state.endless_loose_drops(int(resource.depth)).has(node_key),"no valuable payout on reveal: "+mode)
		await capture(mode+"-exposed")
		var saved: Dictionary=state.serialize()
		verify(state.deserialize(saved),"exposed save loads: "+mode)
		verify((int(state.endless_floor_resource_state(int(resource.depth)).mined_mask) & (1<<int(resource.node_index)))==0,"save retains unmined node: "+mode)
		if mode=="resonance":
			w.resonance_drill.reset()
			w.resonance_drill.charge=1.0
			w.resonance_drill.on_hit(0.1)
			w.resonance_drill._advance_row()
		elif mode=="crusher":w._apply_crusher_wave(cell+Vector2i.LEFT,{"power":999999})
		else:w._strike_resource(index,999999,false)
		verify(resource.mined and state.endless_loose_drops(int(resource.depth)).has(node_key),"second attack mines exposed node: "+mode)
		var drop: Dictionary=state.endless_loose_drops(int(resource.depth))[node_key].duplicate(true)
		w._strike_resource(index,999999,false)
		verify(state.endless_loose_drops(int(resource.depth))[node_key]==drop,"node rewards cannot duplicate: "+mode)
		await capture(mode+"-mined")
	print("DEEP_EXPOSURE_OK ",checks.size())
	quit(0)
