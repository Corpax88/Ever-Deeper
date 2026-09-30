extends "res://scripts/qa/suites/one_point_zero.gd"
## Regressions for committed mining cadence, real movement and live equipment.

func run() -> void:
	if not _new_player_to_deep():
		_finish("premium_core")
		return
	main._enter_endless(true, false)
	var world: Node = main.endless_world
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null:
		mole.set_process(false)
		mole.set_physics_process(false)
	RunState.starforge_variant = ""
	RunState.drill_level = 0
	RunState.pickaxe_level = 1
	var origin: Vector2 = world.player.global_position
	var center: Vector2i = world._world_to_cell(origin)
	for y in range(-2, 3):
		for x in range(-2, 3):
			world.floor_cells[world._cell_index(center + Vector2i(x, y))] = 1
	for index in world.resources.size():
		world.resources[index].mined = index >= 2
		if index < 2:
			world.resources[index].position = origin + Vector2(40 + index * 28, 0)
			world.resources[index].hp = 1
	world.player.set_facing(Vector2.RIGHT)
	world.player._actual_moving = false
	world.external_mine_held = true
	var duration: float = world._mining_cycle_duration()
	var step: float = 1.0 / 120.0
	var first_hit: float = -1.0
	var second_hit: float = -1.0
	var first_target: String = String(world.resources[0].id)
	var retained: bool = true
	for tick in range(1, ceili(duration * 3.0 / step)):
		world._update_mining(step)
		if bool(world.resources[0].mined) and first_hit < 0.0:
			first_hit = tick * step
		if first_hit >= 0.0 and tick * step < duration - step:
			retained = retained and String(world.mining_target_id) == first_target
		if bool(world.resources[1].mined):
			second_hit = tick * step
			break
	_check(first_hit > 0.0 and second_hit > first_hit, "Held mining actually breaks two adjacent deposits")
	_check(retained, "Destroyed deposit retains the committed follow-through")
	_check(second_hit - first_hit >= duration - step * 1.1, "Adjacent one-hit deposits respect full equipment cadence")
	journey.append({"step": "adjacent ore cadence", "cycle": duration, "first_hit": first_hit, "second_hit": second_hit})
	world._cancel_mining()
	world.resources[1].mined = false
	world.resources[1].hp = 999
	world.player._actual_moving = true
	for tick in 100:
		world._update_mining(step)
	_check(int(world.resources[1].hp) == 999 and not bool(world.mining_active), "Actual walking cancels mining and cannot inflict a moving hit")
	world.player._actual_moving = false
	world.player.external_movement = Vector2.RIGHT
	for tick in 100:
		world._update_mining(step)
	_check(int(world.resources[1].hp) < 999, "Pushing into an immovable wall still permits mining")
	world.external_mine_held = false
	world._update_mining(step)
	_check(not bool(world.mining_active), "Releasing the mining button cancels the committed target")
	world.player.external_movement = Vector2.ZERO
	_check_terrain_cadence(world)
	var visual: Node = world.player.visual
	RunState.endless_outfit = "expedition"
	world.player._update_visual(false)
	_check(String(visual.active_endless_outfit_style) == "expedition", "Direct loadout changes update the rendered outfit")
	_check(float(visual._cloth.get_shader_parameter("recolor")) == 1.0, "Selected outfit enables actual cloth recoloring")
	_check(Color(visual._cloth.get_shader_parameter("cloth_color")).is_equal_approx(Color("226d8a")), "Selected outfit writes the real shader color")
	RunState.endless_outfit = "miner"
	world.player._update_visual(false)
	_check(String(visual.active_endless_outfit_style) == "miner", "Resetting the outfit restores its original colors")
	_check(float(visual._cloth.get_shader_parameter("recolor")) == 0.0, "Original outfit disables actual shader recoloring")
	var lamp: Node = load("res://scripts/lighting/headlamp_beam.gd").new()
	main.add_child(lamp)
	lamp.configure_preview("wide", 1)
	var before: float = float(lamp.effective_range_multiplier)
	lamp.configure_preview("wide", 5)
	_check(float(lamp.effective_range_multiplier) > before, "Same-style lighting level changes invalidate the preview")
	lamp.preview_settings.clear()
	RunState.endless_light_style = "focused"
	lamp.set_direction(Vector2.UP)
	_check(String(lamp.applied_style_id) == "focused", "Leaving preview immediately restores live light style")
	var relic: String = RunState._relic_id_for_workshop("light_lab")
	RunState.endless_relics[relic]["placed"] = true
	RunState.endless_workshops["light_lab"]["built"] = true
	RunState.endless_workshops["light_lab"]["level"] = 1
	lamp.set_direction(Vector2.UP)
	before = float(lamp.effective_range_multiplier)
	var prior_energy: float = float(lamp.effective_energy_multiplier)
	RunState.endless_workshops["light_lab"]["level"] = 5
	lamp.set_direction(Vector2.UP)
	_check(float(lamp.effective_range_multiplier) > before and float(lamp.effective_energy_multiplier) > prior_energy, "Live same-style level change updates cached range and energy without forced refresh")
	RunState.endless_workshops["light_lab"]["built"] = false
	lamp.set_direction(Vector2.UP)
	_check(is_equal_approx(float(lamp.effective_range_multiplier), 1.0), "Reset or unbuilt workshop invalidates cached light effects")
	lamp.queue_free()
	await _check_deep_excavation()
	await _check_deep_treasury()
	_finish("premium_core")


func _check_terrain_cadence(world: Node) -> void:
	for resource in world.resources:
		resource.mined = true
	var center: Vector2i = world._world_to_cell(world.player.global_position)
	world.player.global_position = world._cell_center(center)
	world.player._actual_moving = false
	world.player.set_facing(Vector2.RIGHT)
	var a: Vector2i = center + Vector2i.RIGHT
	var b: Vector2i = center + Vector2i.ONE
	for cell in [a, b]:
		world.floor_cells[world._cell_index(cell)] = 0
		world.dig_damage[cell] = 519
	world.external_mine_held = true
	var duration: float = world._mining_cycle_duration()
	var step: float = 1.0 / 120.0
	var first: float = -1.0
	var second: float = -1.0
	for tick in range(1, ceili(duration * 3.0 / step)):
		world._update_mining(step)
		if world._is_floor(a) and first < 0.0:
			first = tick * step
		if world._is_floor(b):
			second = tick * step
			break
	_check(first > 0.0 and second > first, "Held mining actually opens two one-hit terrain cells")
	_check(second - first >= duration - step * 1.1, "Successive terrain breaks retain full swing recovery")
	journey.append({"step": "adjacent terrain cadence", "cycle": duration, "first_hit": first, "second_hit": second})
	world._cancel_mining()
	world.floor_cells[world._cell_index(a)] = 0
	world.dig_damage[a] = 0
	world.player.global_position = world._cell_center(a) - Vector2(32 + world.PLAYER_RADIUS + 0.1, 0)
	world.player.external_movement = Vector2.RIGHT
	world.player._physics_process(0.02)
	world.player._physics_process(0.02)
	_check(not bool(world.player._actual_moving), "Real collision stops translation while joystick remains held")
	world._update_mining(duration * 0.2)
	_check(bool(world.mining_active), "Actual blocked joystick permits the mining wind-up")
	world.player.external_movement = Vector2.UP
	world.player._physics_process(0.0)
	world._update_mining(duration * 0.25)
	_check(int(world.dig_damage.get(a, 0)) == 0, "Turning at a blocked corner never damages the stone behind the tool")
	world.player.set_facing(Vector2.RIGHT)
	world.player.external_movement = Vector2.RIGHT
	world._update_mining(duration * 0.1)
	world.player.external_movement = Vector2.LEFT
	world.player._physics_process(0.02)
	world.player.external_movement = Vector2.ZERO
	world.player._physics_process(0.02)
	_check(not bool(world.mining_active), "Movement followed by an idle physics tick still cancels the old swing")
	world.external_mine_held = false
	world._cancel_mining()


func _check_deep_excavation() -> void:
	RunState.endless_chunks.clear()
	RunState.endless_stream_anchor.clear()
	RunState.endless_relics = RunState._default_endless_relics() if RunState.has_method("_default_endless_relics") else RunState.endless_relics
	var probe: RefCounted = load("res://scripts/qa/suites/skills_browser_review.gd").new(main,session)
	await probe._deep_command("deep_fixture")
	var world: Node = main.endless_world
	world.set_process(false)
	world.player.set_physics_process(false)
	await probe._deep_command("deep_mine")
	for tick in 600:
		world.player._physics_process(1.0/120.0)
		world._update_mining(1.0/120.0)
		world._update_loose_drops(1.0/120.0)
	await probe._deep_command("deep_stop")
	await probe._deep_command("deep_drop_test")
	await probe._deep_command("deep_reload_test")
	await probe._deep_command("deep_collect_test")
	await probe._deep_command("deep_discovery_test")
	await probe._deep_command("deep_reveal_test")
	await probe._deep_command("deep_stream_test")
	for key in probe.deep_checks:
		_check(bool(probe.deep_checks[key]),"Deep excavation: "+String(key))


func _check_deep_treasury() -> void:
	var ledger: GDScript = load("res://scripts/state/treasury_state.gd")
	var original: Dictionary = RunState.serialize()
	RunState.treasury_totals={}
	RunState.cargo=RunState._empty_resource_store()
	RunState.cargo.stone=80
	RunState.cargo.gold=12
	RunState.gold=200
	_check(ledger.keys().size()==27,"Treasury has 26 resources plus a separate currency bay")
	_check(ledger.land("stone",25)==25 and RunState.cargo.stone==55 and RunState.treasury_totals.stone==25,"Landing atomically debits cargo and credits matching pile")
	_check(ledger.land("wallet_gold",40)==40 and RunState.gold==160 and RunState.cargo.gold==12,"Currency donation does not confuse mined gold ore")
	_check(ledger.land("gold",4)==4 and RunState.cargo.gold==8 and RunState.gold==160,"Gold ore has its own independent bay")
	_check(ledger.land("bad",500)==0 and ledger.land("stone",-1)==0,"Invalid and negative donations rejected")
	var saved: Dictionary=RunState.serialize()
	_check(RunState.deserialize(saved),"Treasury round-trip accepts additive schema")
	_check(RunState.treasury_totals.stone==25 and RunState.gold==160 and RunState.cargo.gold==8,"Reload retains exact debit and credit")
	var legacy: Dictionary=saved.duplicate(true)
	legacy.state.erase("treasury")
	legacy.state.erase("treasury_inside")
	legacy.state.erase("deep_events")
	_check(RunState.deserialize(legacy) and RunState.treasury_totals.is_empty(),"Old schema-3 saves migrate to empty treasury without losing cargo")
	_check(ledger.clean({"stone":-1,"copper":"900","unknown":5,"wallet_gold":400})=={"wallet_gold":400},"Treasury sanitizer rejects corrupt and unknown counts")
	_check(ledger.stage(0)==0 and ledger.stage(24)==1 and ledger.stage(25)==2 and ledger.stage(250)==3 and ledger.stage(2500)==4,"Bounded visual pile upgrade thresholds")
	RunState.treasury_totals.stone=ledger.MAX_TOTAL-2
	RunState.cargo.stone=50
	_check(ledger.land("stone",50)==2 and RunState.cargo.stone==48 and RunState.treasury_totals.stone==ledger.MAX_TOTAL,"Overflow cannot destroy undeliverable cargo")
	RunState.deserialize(original)
	main._dev_jump_hub()
	await main.get_tree().process_frame
	var hub: Node=main.hub_world
	var room: Node=hub.treasury
	RunState.cargo=RunState._empty_resource_store()
	RunState.cargo.stone=80
	RunState.gold=200
	RunState.treasury_totals={}
	hub.set_process(false)
	hub.player.set_physics_process(false)
	room.enter()
	room.stop()
	for kind in ledger.keys():
		_check(room.material(kind)!=null and room.specimen(kind)!=null,"Treasury art exists for "+kind)
	await _treasury_capture("01-empty-room")
	hub.player.control_enabled=true
	hub.player.global_position=room.ZONE
	room.start()
	room.tick(0.5)
	await _treasury_capture("02-airborne")
	_check(room.particles.size()>0 and RunState.cargo.stone==80 and RunState.gold==200,"Airborne packets reserve without consuming cargo or gold")
	room.leave()
	_check(room.particles.is_empty() and room.batches.is_empty() and RunState.cargo.stone==80 and RunState.gold==200,"Exit cancels all undelivered packets without debit")
	room.enter()
	hub.player.global_position=room.ZONE
	room.start()
	hub.player.control_enabled=false
	room.tick(4.0)
	_check(room.particles.is_empty() and RunState.cargo.stone==80,"Menu pauses launch and accounting")
	hub.player.control_enabled=true
	for i in 30: room.tick(0.1)
	await _treasury_capture("03-partial")
	var banked: int=int(RunState.treasury_totals.get("stone",0))
	_check(banked>0 and banked<80 and int(RunState.cargo.stone)+banked==80,"Long delivery has meaningful partial progress and conserves total")
	room.leave()
	var pending_cargo: int=RunState.cargo.stone
	for i in 100: room.tick(0.1)
	_check(RunState.cargo.stone==pending_cargo and int(RunState.treasury_totals.stone)==banked,"Exited room cannot land stale packets")
	room.enter()
	hub.player.global_position=room.ZONE
	room.start()
	for i in 500: room.tick(0.1)
	_check(RunState.cargo.stone==0 and RunState.gold==0 and int(RunState.treasury_totals.stone)==80 and int(RunState.treasury_totals.wallet_gold)==200,"Reentry delivers the remainder exactly once including wallet")
	_check(not room.delivering and room.particles.is_empty(),"Completed donation leaves no continuing particle work")
	await _treasury_capture("04-complete")
	for kind in ledger.keys(): RunState.treasury_totals[kind]=10000
	room.refresh_piles()
	await _treasury_capture("05-mature")
	room.leave()
	RunState.cargo=RunState._empty_resource_store()
	RunState.cargo.stone=10
	RunState.gold=0
	hub.restore_position(hub.HUB_SHOP+Vector2(0,85))
	_check(hub.current_context()=="hubSell","Permanent hub shop is reachable")
	hub.perform_context()
	_check(RunState.gold>0,"Hub shop converts sellable resources into currency")
	hub.restore_position(hub.TREASURY_DOOR+Vector2(-30,0))
	_check(not hub.collision_at(hub.TREASURY_DOOR+Vector2(10,0)),"Right-hand doorway permits walking through")
	_check(hub.collision_at(hub.TREASURY_DOOR+Vector2(10,-150)),"Solid wall beside the doorway still blocks movement")
	_check(hub.current_context()=="","Doorway needs no context action")
	await _treasury_capture("06-hub-shop-door")
	room.leave(false)
	RunState.deserialize(original)
	main._dev_jump_endless(1)
	await main.get_tree().process_frame
	var w: Node=main.endless_world
	w.set_process(false)
	w.player.set_physics_process(false)
	RunState.deep_events={}
	var events: Node=w.deep_events
	var event_state: Dictionary=events.state()
	event_state.next=1
	events.on_rock(w._world_to_cell(w.player.global_position))
	_check(String(event_state.kind) in events.KINDS and float(event_state.remaining)==28.0,"New excavation triggers a bounded unpredictable event")
	var event_saved: Dictionary=RunState.serialize()
	var expected: Dictionary=event_state.duplicate(true)
	_check(RunState.deserialize(event_saved) and RunState.deep_events==expected,"Reload preserves event identity, cooldown and remaining duration")
	for kind in events.KINDS:
		RunState.deep_events.kind=kind
		RunState.deep_events.remaining=28.0
		events._refresh_visuals()
		await _treasury_capture("event-"+kind)
		var enhanced: Dictionary=events.reward(w._world_to_cell(w.player.global_position),{"kind":"deepstone","amount":1})
		_check((enhanced.kind!="deepstone" and int(enhanced.amount)>1) if kind!="unstable_seam" else events.speed()==2.0,"Event changes mining yield or speed: "+kind)
	w.player.control_enabled=false
	events.tick(5.0)
	_check(float(RunState.deep_events.remaining)==28.0,"Menus pause Deep Event duration")
	w.player.control_enabled=true
	var event_gap: int=int(RunState.deep_events.next)-int(RunState.deep_events.mined)
	var event_serial: int=int(RunState.deep_events.serial)
	for i in 750: events.on_rock(Vector2i(i+100,200))
	_check(int(RunState.deep_events.next)-int(RunState.deep_events.mined)==event_gap,"Powerful mining during an event retains the rare-event discovery gap")
	events.tick(29.0)
	_check(float(RunState.deep_events.remaining)==0.0 and events.speed()==1.0,"Event expires cleanly without keeping a permanent boost")
	events.on_rock(Vector2i(900,200))
	_check(int(RunState.deep_events.serial)==event_serial,"Event cannot immediately repeat after a large excavation burst")
	RunState.deserialize(original)


func _treasury_capture(label: String) -> void:
	var folder: String=OS.get_environment("TREASURY_CAPTURE_DIR")
	if folder.is_empty(): return
	DirAccess.make_dir_recursive_absolute(folder)
	# Let seed-only achievement and pickup popups expire before visual inspection.
	if label=="01-empty-room": await main.get_tree().create_timer(7.0).timeout
	main.action_button.hide() # QA-only duplicate; ordinary gameplay hides this too.
	for frame in 4:
		await main.get_tree().process_frame
		main.action_button.hide()
		main.achievement_toast.hide() # Suppress only the accelerated fixture backlog.
	await RenderingServer.frame_post_draw
	var err: int=main.get_viewport().get_texture().get_image().save_png(folder.path_join(label+".png"))
	_check(err==OK,"Rendered capture: "+label)
