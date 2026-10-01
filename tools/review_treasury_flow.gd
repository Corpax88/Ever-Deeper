extends SceneTree
var output: String
var checks: Array = []
var main: Node
var hub: Node
var room: Node
var state: Node
func _initialize() -> void:
	run.call_deferred()
func verify(ok: bool, label: String) -> bool:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(output.path_join("interaction.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not ok:
		push_error("CIRCULAR_TREASURY_FAIL "+label)
		quit(2)
	return ok
func capture(label: String) -> void:
	main.achievement_toast.hide()
	main.action_button.hide()
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func walk(action: String, target: Callable, label: String) -> bool:
	Input.action_press(action)
	var deadline: int = Time.get_ticks_msec()+20000
	while not target.call() and Time.get_ticks_msec()<deadline: await process_frame
	Input.action_release(action)
	return verify(bool(target.call()),label)
func run() -> void:
	output=OS.get_environment("CIRCULAR_REVIEW_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	for i in 4: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_jump_hub()
	for i in 5: await process_frame
	hub=main.hub_world
	room=hub.treasury
	state.cargo=state._empty_resource_store()
	for kind in state.RESOURCE_IDS: state.cargo[kind]=800
	state.gold=800
	room.enter()
	hub.player.global_position=room.ZONE
	hub.set_process(false)
	room.start()
	var previous_launch: float = -1.0
	var max_gap: float = 0.0
	var mixed: int = 0
	var launches: int = 0
	for frame in 1500:
		var before_next: float = room.next_launch
		room.tick(1.0/60.0)
		if room.next_launch!=before_next:
			if previous_launch>=0.0: max_gap=maxf(max_gap,room.clock-previous_launch)
			previous_launch=room.clock
			launches+=1
		var kinds: Dictionary={}
		for packet in room.particles:
			kinds[packet.kind]=true
			if packet.motes.size()!=1:
				verify(false,"single visible item per packet")
				return
		mixed=maxi(mixed,kinds.size())
		if frame==65: await capture("01-mixed-stream")
		if not room.delivering: break
	verify(mixed>=12,"many resource directions coexist")
	verify(max_gap<=0.084,"continuous launch cadence without pulse gaps")
	verify(launches==216,"all 27 resource types receive eight fair launches")
	for kind in room.Ledger.keys():
		verify(int(state.treasury_totals.get(kind,0))==800 and room.Ledger.available(kind)==0,"exact conservation "+kind)
	verify(not room.delivering,"delivery finishes")
	room.stop()
	state.treasury_totals={"stone":990}
	state.cargo=state._empty_resource_store()
	state.cargo.stone=2020
	state.cargo.copper=2020
	state.gold=0
	room.start()
	var before_upgrades: int=room.upgrades
	var seen: Dictionary={}
	previous_launch=-1.0
	max_gap=0.0
	for frame in 600:
		var before_next: float=room.next_launch
		room.tick(1.0/60.0)
		if room.next_launch!=before_next:
			if previous_launch>=0.0: max_gap=maxf(max_gap,room.clock-previous_launch)
			previous_launch=room.clock
			var kind: String=room.active_kind
			if not seen.has(kind):seen[kind]=[]
		if state.treasury_totals.stone in [1000,2000,3000]:seen[str(state.treasury_totals.stone)]=true
		if not room.delivering:break
	verify(seen.has("1000") and seen.has("2000") and seen.has("3000"),"ordered exact milestone landings")
	verify(room.upgrades-before_upgrades==5,"all mixed-material upgrades celebrated")
	verify(max_gap<=0.084,"upgrades never pause outgoing stream")
	verify(state.treasury_totals.stone==3010 and state.treasury_totals.copper==2020,"mixed milestone conservation")
	state.cargo.stone=1000000
	state.cargo.copper=1000000
	room.start()
	for i in 80:room.tick(1.0/60.0)
	var paused: Dictionary=room.snapshot()
	hub.player.control_enabled=false
	for i in 180:room.tick(1.0/60.0)
	verify(room.snapshot()==paused,"menus pause delivery and accounting")
	hub.player.control_enabled=true
	verify(room.particles.size()<=32 and room.batches.size()==2,"large inventories keep bounded work")
	room.stop()
	var remaining: Dictionary=state.cargo.duplicate(true)
	room.armed=false
	for i in 180:room.tick(1.0/60.0)
	verify(state.cargo==remaining and room.particles.is_empty(),"cancellation preserves undelivered cargo")
	FileAccess.open(output.path_join("timing.json"),FileAccess.WRITE).store_string(JSON.stringify({"mixed_types":mixed,"launches":launches,"maximum_gap":max_gap}))
	for result in checks:
		if not result.passed:
			quit(2)
			return
	print("TREASURY_FLOW_OK")
	quit(0)
