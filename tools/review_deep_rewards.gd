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
		push_error("REWARD_CHECK_FAILED "+label)
		quit(2)
func capture(label: String) -> void:
	main.achievement_toast.clear()
	main._update_minimap()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	output=OS.get_environment("REWARD_REVIEW_OUTPUT")
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
	w.set_process(false)
	w.player.set_physics_process(false)
	state.deep_events={}
	var events: Node=w.deep_events
	events.state().next=2000000
	var all_stone: bool=true
	for depth in [1,9,100,10000]:
		for cell in 880:
			var reward: Dictionary=w.DeepLayout.ore_for_cell(7381,depth,cell)
			all_stone=all_stone and reward.kind=="stone" and int(reward.amount)>0 and not reward.rare
	verify(all_stone,"3520 ordinary rock cells yield only stone across depths")
	var target:=Vector2i(18,5)
	verify(w._break_diggable_cell(target),"actual excavation accepts stone claim")
	var drops: Dictionary=state.endless_loose_drops(1)
	var id: String="c%d" % w._chunk_cell_index(target)
	verify(drops.has(id) and drops[id].kind=="stone","real stone drop registered")
	verify(w.loose_drops["1:"+id].visual.texture!=null,"stone drop has visible texture")
	var saved: Dictionary=state.serialize()
	verify(state.deserialize(saved) and state.endless_loose_drops(1)==drops,"stone drops survive save reload")
	verify(not w._break_diggable_cell(target),"same rock cannot pay twice")
	var cargo_before: int=int(state.cargo.stone)
	var collected: Dictionary=state.collect_endless_drop(1,id)
	verify(int(state.cargo.stone)==cargo_before+int(collected.amount),"stone pickup reaches inventory")
	verify(state.collect_endless_drop(1,id).is_empty(),"stone pickup cannot repeat")
	state._register_endless_drop(1,"c201",201,"echo_crystal",13)
	var legacy: Dictionary=state.serialize()
	verify(state.deserialize(legacy) and state.endless_loose_drops(1).c201.kind=="echo_crystal","existing valuable drops remain through reload")
	w.player.global_position=w._cell_center(Vector2i(18,4))
	for y in range(3,7):
		for x in range(16,21): w._break_diggable_cell(Vector2i(x,y))
	await capture("ordinary-stone")
	var s: Dictionary=events.state()
	s.kind="unstable_seam"
	s.remaining=28.0
	s.x=18
	s.y=5
	verify(events.speed()==1.0,"Unstable Seam has no redundant speed boost")
	verify(events.reward(Vector2i(18,5),{"kind":"stone","amount":7}).amount==14,"seam doubles stone")
	verify(events.node_amount(events.center(),17)==34,"seam doubles valuable node amount")
	verify(events.node_amount(events.center()+Vector2(421,0),17)==17,"node bonus stops at local radius")
	verify(events.reward(Vector2i(30,5),{"kind":"stone","amount":7}).amount==7,"rock outside seam unchanged")
	events._refresh_visuals()
	await capture("unstable-seam")
	var resource: Dictionary=w.resources[0]
	var node_cell: Vector2i=resource.cell
	s.x=node_cell.x
	s.y=w.absolute_cell(node_cell).y
	var node_depth: int=int(resource.depth)
	state.endless_current_depth=node_depth
	var expected: int=state.prospecting_yield(String(resource.kind),int(resource.amount)*2*maxi(1,int(w._current_endless_tool().get("yield_multiplier",1))))
	w._strike_resource(0,999999,false)
	var node_id: String="n%d" % int(resource.node_index)
	verify(state.endless_loose_drops(node_depth)[node_id].amount==expected,"actual node strike applies double reward exactly once")
	var node_saved: Dictionary=state.serialize()
	verify(state.deserialize(node_saved) and state.endless_loose_drops(node_depth)[node_id].amount==expected,"doubled node reward persists")
	w._strike_resource(0,999999,false)
	verify(state.endless_loose_drops(node_depth)[node_id].amount==expected,"node cannot claim twice")
	for kind in ["ancient_core","crystal_bloom"]:
		s=events.state()
		s.kind=kind
		s.remaining=28.0
		s.x=18
		s.y=5
		var reward: Dictionary=events.reward(Vector2i(18,5),{"kind":"stone","amount":2})
		verify(reward.kind!="stone" and int(reward.amount)>2,"marked event deposit remains valuable: "+kind)
		events._refresh_visuals()
		await capture(kind)
	s=events.state()
	s.kind="unstable_seam"
	s.remaining=0.0
	verify(events.node_amount(events.center(),17)==17,"expired event bonus removed")
	print("DEEP_REWARDS_OK ",checks.size())
	quit(0)
