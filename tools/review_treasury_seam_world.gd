extends SceneTree
## Real generated bands, ore assets and extraction. Optional SEAM_RENDER=1 captures.
var main: Node
var world: Node
var state: Node
var seams: Script
var goals: Script
var checks: Array = []
var output: String

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool, detail: Dictionary = {}) -> void:
	checks.append({"name":label,"passed":passed,"detail":detail})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not passed: print("TREASURY_SEAM_WORLD_MISMATCH " + label)

func fresh(kind: String, depth: int = 1, seed_value: int = 77411) -> void:
	state.world_seed = seed_value
	state.endless_chunks = {}
	state.endless_treasury_seam_start_depth = 1
	state.endless_current_depth = depth
	state.endless_deepest_depth = depth
	state.endless_descent_active = true
	state.treasury_goals = {"pinned":kind}
	state.treasury_totals = {}
	state.cargo = state._empty_resource_store()
	state.deep_events = {}
	state.starforge_variant = "prospector"
	state.miner_skills = state.MinerSkills.defaults()
	state._miner_level_cache.clear()
	world.current_depth = depth
	world.resources.clear()
	world.session_mined_nodes.clear()
	world.session_discovered_sites.clear()
	world._generate_stream_window(depth)
	var feedback: Node = world.player.get_node_or_null("ResourcePickupBurst")
	if feedback != null:
		while not feedback.entries.is_empty(): feedback._remove_entry(0)
		feedback.queue_redraw()

func ordinary() -> Dictionary:
	var nodes: Array = []
	for ore in world.resources:
		if not bool(ore.get("treasury_seam",false)):
			nodes.append({"id":ore.id,"kind":ore.kind,"cell":ore.cell,"amount":ore.amount,"max_hp":ore.max_hp})
	var sites: Array = []
	for site in world.discovery_sites: sites.append({"id":site.id,"position":site.position,"title":site.title,"reward_kind":site.reward_kind,"base_reward":site.base_reward,"rune_positions":site.rune_positions})
	return {"nodes":nodes,"sites":sites,"relics":world._native_relics.duplicate(true),"floor":world.floor_cells.duplicate()}

func captures_enabled() -> bool: return OS.get_environment("SEAM_RENDER") == "1"

func capture(name: String) -> void:
	if not captures_enabled(): return
	world.queue_redraw()
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	for _frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): output = "/tmp/ever-deeper-seam-world"
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	seams = load("res://scripts/state/treasury_seams.gd")
	goals = load("res://scripts/state/treasury_goals.gd")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated.sav"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._dev_grant_max_tools_state()
	main._dev_jump_endless(1)
	world = main.endless_world
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	main.get_node("MinerTraining").set_physics_process(false)
	var mole: Node = main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled = false
	mole.recall()
	world.resonance_drill.set_enabled(false)
	main.achievement_toast.hide()

	var generation_unchanged: bool = true
	var deposit_counts: Array = []
	for seed_value in [7,77411,991832]:
		for depth in [1,12,35]:
			fresh("",depth,seed_value)
			var baseline: Dictionary = ordinary()
			fresh("rootiron",depth,seed_value)
			generation_unchanged = generation_unchanged and ordinary() == baseline
			var count: int = 0
			for ore in world.resources:
				if bool(ore.get("treasury_seam",false)): count += 1
			deposit_counts.append(count)
	check("ordinary-geology-ore-sites-relics-unchanged-for-nine-world-windows",generation_unchanged)
	check("three-deposits-per-band-in-sampled-worlds",deposit_counts == [9,9,9,9,9,9,9,9,9],{"counts":deposit_counts})

	for kind in seams.MOD_BY_KIND:
		fresh(kind)
		var index: int = -1
		for i in world.resources.size():
			if bool(world.resources[i].get("treasury_seam",false)) and int(world.resources[i].depth) == 1: index = i; break
		check("bound-material-generated-"+kind,index >= 0)
		if index < 0: continue
		var ore: Dictionary = world.resources[index]
		var cell: Vector2i = Vector2i(ore.cell)
		var visual: Node2D = world.resource_visuals[String(ore.id)]
		var sprite: Sprite2D = visual.get_node("PremiumNode")
		check("matching-authored-node-is-hidden-before-dig-"+kind,sprite.texture != null and String(sprite.texture.get_meta("scale_source",sprite.texture.resource_path)) == String(world.RESOURCE_TEXTURE_PATHS[kind]) and not visual.visible and not world._is_floor(cell))
		# Expose a real one-cell approach without touching the covered deposit.
		world._break_diggable_cell(cell+Vector2i.UP)
		world.player.global_position = world._cell_center(cell+Vector2i.UP)
		world.player.set_facing(Vector2.DOWN)
		world._update_discoveries()
		await capture(kind+"-covered")
		var original_hp: int = int(ore.hp)
		world._strike_resource(index,100000,false)
		check("ordinary-strike-cannot-mine-covered-node-"+kind,int(world.resources[index].hp) == original_hp and not bool(world.resources[index].mined))
		check("covering-rock-excavates-"+kind,world._break_diggable_cell(cell))
		world._update_buried_visibility()
		world._update_discoveries()
		check("reveal-is-separate-from-extraction-"+kind,visual.visible and int(world.resources[index].hp) == original_hp and int(state.cargo[kind]) == 0)
		await capture(kind+"-revealed")
		world._strike_resource(index,100000,false)
		var drop_id: String = "n%d" % int(ore.node_index)
		var expected: int = int(ore.amount)*2
		var drops: Dictionary = state.endless_loose_drops(1)
		check("crown-applies-once-to-extracted-deposit-"+kind,drops.has(drop_id) and int(drops[drop_id].amount) == expected and int(state.cargo[kind]) == 0)
		var loose_sprite: Sprite2D = world.loose_drops["1:"+drop_id].visual
		check("matching-authored-drop-"+kind,loose_sprite.texture != null and String(loose_sprite.texture.get_meta("scale_source",loose_sprite.texture.resource_path)) == state._resource_drop_texture_path(kind))
		await capture(kind+"-drop")
		check("mined-node-and-drop-save-"+kind,state.save_game(output.path_join("world.sav")) and state.load_game(output.path_join("world.sav")))
		state.treasury_goals.pinned = "prismite" if kind != "prismite" else "rootiron"
		world._generate_stream_window(1)
		var retained: Dictionary = {}
		for reloaded in world.resources:
			if String(reloaded.id) == String(ore.id): retained = reloaded; break
		check("reload-and-repin-preserve-mined-kind-and-cell-"+kind,not retained.is_empty() and retained.kind == kind and retained.cell == cell and bool(retained.mined))
		world.player.global_position = world._cell_center(cell)
		world._update_loose_drops(0.6)
		check("real-pickup-conserves-resource-"+kind,int(state.cargo[kind]) == expected and not state.endless_loose_drops(1).has(drop_id))
		world._strike_resource(index,100000,false)
		check("repeat-hit-cannot-renew-resource-"+kind,int(state.cargo[kind]) == expected and not state.endless_loose_drops(1).has(drop_id))

	# Exercise the same generated entitlement through each real alternate impact.
	for mode in ["crusher","resonance","bore_rush","laser","twin_auger","chainbreaker","ricochet","corebreaker","vortex","mole"]:
		fresh("rootiron")
		var index: int = -1
		for i in world.resources.size():
			if bool(world.resources[i].get("treasury_seam",false)) and int(world.resources[i].depth) == 1: index = i; break
		var ore: Dictionary = world.resources[index]
		var cell: Vector2i = Vector2i(ore.cell)
		var front: Vector2i = cell+Vector2i.UP
		world._break_diggable_cell(front)
		world.player.global_position = world._cell_center(front)
		world.player.control_enabled = true
		world.player.external_movement = Vector2.DOWN
		world.player.set_facing(Vector2.DOWN)
		world.player.animation_bearing = Vector2.DOWN
		world.set_mine_held(true)
		world.drill_modes.reset()
		world.drill_modes.five.reset()
		world.drill_modes.dev_override = mode if mode in ["bore_rush","laser","twin_auger","chainbreaker","ricochet","corebreaker","vortex"] else ""
		world.resonance_drill.set_enabled(mode == "resonance")
		var exposed: bool = false
		for step in 180:
			if mode == "crusher":
				state.starforge_variant = "crusher"
				world._apply_crusher_wave(front,world._current_endless_tool())
			elif mode == "resonance":
				if step == 0:
					world.resonance_drill.charge = 1.0
					world.resonance_drill.on_hit(0.1)
				world.resonance_drill.tick(0.05)
			elif mode == "mole": world.companion_dig(world._cell_center(cell),false)
			else: world.drill_modes.tick(0.05)
			if world._is_floor(cell): exposed = true; break
		check("real-"+mode+"-reveals-bound-deposit-without-extracting",exposed and not bool(world.resources[index].mined) and int(world.resources[index].hp) == int(ore.max_hp))
		if mode == "resonance":
			for _step in 30: world.resonance_drill.tick(0.05)
			check("resonance-entire-wave-keeps-new-deposit-intact",not bool(world.resources[index].mined))
			world.resonance_drill.reset()
			world.resonance_drill.charge = 1.0
			world.resonance_drill.on_hit(0.1)
		for _step in 180:
			if bool(world.resources[index].mined): break
			if mode == "crusher": world._apply_crusher_wave(front,world._current_endless_tool())
			elif mode == "resonance": world.resonance_drill.tick(0.05)
			elif mode == "mole": world.companion_work_hit(world.companion_work_target(world._cell_center(cell)))
			else: world.drill_modes.tick(0.05)
		check("real-"+mode+"-extracts-on-later-action",bool(world.resources[index].mined) and state.endless_loose_drops(1).has("n%d" % int(ore.node_index)))
	world.set_mine_held(false)
	world.player.external_movement = Vector2.ZERO
	world.drill_modes.dev_override = ""
	world.drill_modes.reset()
	world.resonance_drill.set_enabled(false)

	fresh("rootiron",2)
	var band_two: Dictionary = state.endless_chunks["2"].treasury_seam.duplicate(true)
	var band_three: Dictionary = state.endless_chunks["3"].treasury_seam.duplicate(true)
	state.treasury_goals.pinned = "prismite"
	state.endless_current_depth = 3
	state.endless_deepest_depth = 3
	world.current_depth = 3
	world._rebase_stream_window(3)
	check("real-stream-rebase-preserves-existing-descriptor",state.endless_chunks["3"].treasury_seam == band_three and state.endless_chunks["2"].treasury_seam == band_two)
	check("newly-loaded-band-uses-new-pin",state.endless_chunks["5"].treasury_seam.kind == "prismite")
	world._rebase_stream_window(2)
	check("real-revisit-never-rerolls-original-band",state.endless_chunks["2"].treasury_seam == band_two)
	check("source-hint-retains-original-mine-route",goals.sources("rootiron").contains("follow the marker") and goals.sources("rootiron").contains("keep descending after changing goals") and goals.sources("rootiron").contains("Mossvein"))
	state.treasury_goals.pinned = "rootiron"
	state.cargo.rootiron = 100000
	check("completed-cargo-guides-to-donation",goals.hud_goal().treasury_route == "donate" and goals.hud_goal().hud_action == "Donate · Treasury plate")
	for row in checks:
		if not row.passed: quit(1); return
	print("TREASURY_SEAM_WORLD_OK "+str(checks.size()))
	quit(0)
