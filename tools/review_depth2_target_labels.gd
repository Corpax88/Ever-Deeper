extends SceneTree
## Real exposed Depth 2 targets, normal terrain lighting and native hero.
## The fresh mine has no exposed ore. Reveal one authored node through ordinary
## terrain damage along a legal grid route; never inject rocks, yields or HP.
var main: Node
var world: Node2D
var state: Node
var output: String
var checks: Array = []
var records: Array = []
var excavation: Dictionary = {}

func _initialize() -> void:
	run.call_deferred()

func check(name: String, passed: bool) -> void:
	checks.append({"name":name,"passed":passed})
	if not passed: print("DEPTH2_TARGET_MISMATCH "+name)

func expose_real_ore() -> bool:
	var start: Vector2i = world._world_to_cell(world.player.global_position)
	var goals: Dictionary = {}
	for index in world.rocks.size():
		var rock: Dictionary = world.rocks[index]
		if int(rock.requires_drill_level)==0 and not bool(rock.broken): goals[Vector2i(rock.cell)]=index
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {start:start}
	var finish: = Vector2i(-1,-1)
	var cursor: = 0
	while cursor<frontier.size():
		var cell: Vector2i = frontier[cursor]
		cursor+=1
		if goals.has(cell): finish=cell; break
		for offset in [Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT]:
			var next: Vector2i = cell+offset
			if parents.has(next) or not world._cell_in_bounds(next) or world._terrain_is_bedrock(next): continue
			parents[next]=cell
			frontier.append(next)
	if finish.x<0: return false
	var route: Array[Vector2i] = []
	var cell: Vector2i = finish
	while cell!=start:
		route.push_front(cell)
		cell=parents[cell]
	world.restore_position(world._cell_center(start))
	var strikes: = 0
	for next in route:
		var direction: Vector2 = (world._cell_center(next)-world.player.global_position).normalized()
		world.player.set_facing(direction)
		while world._terrain_is_solid(next):
			var selected: Dictionary = world._find_mine_target()
			if String(selected.get("kind",""))!="terrain" or Vector2i(selected.get("cell",Vector2i(-1,-1)))!=next: return false
			world._apply_target(selected)
			if not world._hit_terrain(next): return false
			strikes+=1
			if strikes>300: return false
		if next!=finish:
			world.restore_position(world._cell_center(next))
			if world.player.global_position.distance_to(world._cell_center(next))>2.0: return false
	excavation={"route_cells":route.size(),"ordinary_strikes":strikes,"authored_rock_index":goals[finish],"rock":world.rocks[goals[finish]].duplicate(true)}
	world.player.set_mining_visual(false)
	world._update_impacts(10.0)
	return world._rock_is_exposed(int(goals[finish]))

func place_target(kind: String) -> bool:
	var candidates: Array = []
	if kind == "ore":
		for index in world.rocks.size():
			var rock: Dictionary = world.rocks[index]
			if world._rock_is_exposed(index) and int(rock.requires_drill_level) == 0:
				candidates.append({"position":Vector2(rock.position),"kind":"rock","rock_index":index,"cell":Vector2i(rock.cell)})
	else:
		for row in world.rows:
			for col in world.cols:
				var cell: = Vector2i(col,row)
				if not world._terrain_is_solid(cell): continue
				if world._terrain_is_bedrock(cell) != (kind == "bedrock"): continue
				candidates.append({"position":world._cell_center(cell),"kind":"terrain","cell":cell,"rock_index":-1})
	var entrance: Vector2 = world.entry_spawn()
	candidates.sort_custom(func(a,b): return a.position.distance_squared_to(entrance) < b.position.distance_squared_to(entrance))
	for candidate in candidates:
		for direction in [Vector2.RIGHT,Vector2.LEFT,Vector2.DOWN,Vector2.UP]:
			for distance in [64.0,80.0,96.0]:
				var position: Vector2 = candidate.position - direction*distance
				if world._player_collides(position): continue
				world.restore_position(position)
				if world.player.global_position.distance_to(position)>2.0: continue
				world.player.set_facing(direction)
				var selected: Dictionary = world._find_mine_target()
				if String(selected.get("kind","")) != String(candidate.kind): continue
				if candidate.kind == "rock" and int(selected.get("rock_index",-1)) != int(candidate.rock_index): continue
				if candidate.kind == "terrain" and Vector2i(selected.get("cell",Vector2i(-1,-1))) != Vector2i(candidate.cell): continue
				world._apply_target(selected)
				world.target_dirty = false
				return true
	return false

func settle() -> void:
	world.player._update_visual(false)
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	main._refresh_hud()
	for _frame in 8: await process_frame
	world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw

func label_rect() -> Rect2:
	var label: Label = world.get_node("TargetLabel")
	return label.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,label.size)

func return_route() -> Array[Vector2]:
	# Only walk through the entry floor and the passage mined by this fixture.
	var start: Vector2i = world._world_to_cell(world.player.global_position)
	var finish: Vector2i = world._world_to_cell(world.depth_entrance)
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {start:start}
	var cursor: = 0
	while cursor<frontier.size() and not parents.has(finish):
		var cell: Vector2i = frontier[cursor]
		cursor+=1
		for offset in [Vector2i.LEFT,Vector2i.UP,Vector2i.RIGHT,Vector2i.DOWN]:
			var next: Vector2i = cell+offset
			if parents.has(next) or not world._cell_in_bounds(next) or world._player_collides(world._cell_center(next)): continue
			parents[next]=cell
			frontier.append(next)
	var route: Array[Vector2] = []
	if not parents.has(finish): return route
	var cell: Vector2i = finish
	while cell!=start:
		route.push_front(world._cell_center(cell))
		cell=parents[cell]
	return route

func capture(width: int,kind: String,zoom_scale: float=1.0) -> void:
	state.drill_level = 0
	state.starforge_variant = "" if kind == "locked" else "crusher"
	check(str(width)+" "+kind+" natural target found",place_target(kind))
	world.player.camera.zoom *= zoom_scale
	await settle()
	var label: Label = world.get_node_or_null("TargetLabel")
	check(str(width)+" "+kind+" label is present",is_instance_valid(label) and label.is_visible_in_tree())
	if label == null: return
	check(str(width)+" "+kind+" truthful target words",label.text == "ANCIENT BEDROCK" if kind == "bedrock" else label.text == "STARFORGE REQUIRED" if kind == "locked" else "HIT" in label.text)
	var rect: Rect2 = label_rect()
	var projected_size: float = label.get_global_transform_with_canvas().y.length()*label.get_theme_font_size("font_size")
	check(str(width)+" "+kind+" 24 logical pixels across zoom",absf(projected_size-24.0)<0.05)
	check(str(width)+" "+kind+" unshaded text",label.material.light_mode==CanvasItemMaterial.LIGHT_MODE_UNSHADED)
	for hero in world.player.visual.feedback_screen_rects():
		check(str(width)+" "+kind+" text clears native hero",not rect.intersects(hero))
	check(str(width)+" "+kind+" text within viewport",world.get_viewport_rect().encloses(rect))
	main.achievement_toast.clear()
	await process_frame
	await RenderingServer.frame_post_draw
	var filename: String = "%s-%d%s.png" % [kind,width,"-zoom" if zoom_scale != 1.0 else ""]
	root.get_texture().get_image().save_png(output.path_join(filename))
	records.append({"image":filename,"text":label.text,"font_pixels":projected_size,"label":rect,"hero":world.player.visual.feedback_screen_rects(),"target_kind":world.current_target_kind,"target_cell":world.current_target_cell,"target_rock":world.current_target_rock,"zoom":world.player.camera.zoom})
	world.player.camera.zoom /= zoom_scale

func notices(width: int, resume_only: bool = false) -> void:
	state.drill_level = 0
	state.starforge_variant = "crusher"
	check(str(width)+" notice target found",place_target("ore"))
	await settle()
	var target: Dictionary = world._find_mine_target()
	var target_position: Vector2 = world.player.global_position
	var target_facing: Vector2 = world.player.facing_vector
	var toast: Node = main.achievement_toast
	var skill: Node = toast.get_node("SkillLevelToast")
	var pickups: Node = world.player.get_node("ResourcePickupBurst")
	for notice in (["achievement"] if resume_only else ["achievement","skill","pickup","simultaneous"]):
		world.restore_position(target_position)
		world.player.set_facing(target_facing)
		world._apply_target(target)
		await settle()
		toast.clear()
		skill.clear()
		while not pickups.entries.is_empty(): pickups._remove_entry(0)
		if notice in ["achievement","simultaneous"]: main._on_achievement_unlocked(root.get_node("GameData").data.ACHIEVEMENT_BY_ID.first_chip)
		if notice in ["skill","simultaneous"]: skill._earned("mining",2)
		if notice in ["pickup","simultaneous"]:
			main._on_resource_collected("rootiron",5)
			main._on_resource_collected("ambercore",3)
			main._on_resource_collected("gold",1)
		await create_timer(0.6).timeout
		main._update_achievement_toast_anchor()
		await process_frame
		await RenderingServer.frame_post_draw
		var target_rect: Rect2 = label_rect()
		var toast_rect: Rect2 = toast._toast.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,toast._toast.size)
		var skill_rect: Rect2 = skill.reserved_screen_rect()
		if toast._toast.is_visible_in_tree(): check(str(width)+" "+notice+" achievement clears label",not target_rect.intersects(toast_rect))
		if skill.is_visible_in_tree() and skill_rect.has_area(): check(str(width)+" "+notice+" skill clears label",not target_rect.intersects(skill_rect))
		for rect in pickups.screen_rects(): check(str(width)+" "+notice+" pickup clears label",not target_rect.intersects(rect))
		if notice == "pickup": check(str(width)+" actual pickup stack presented",pickups.screen_rects().size()==3)
		if notice == "skill": check(str(width)+" actual skill presented",skill.is_visible_in_tree())
		var filename: String = "%s-%d.png" % [notice,width]
		root.get_texture().get_image().save_png(output.path_join(filename))
		records.append({"image":filename,"label":target_rect,"achievement":toast.debug_snapshot(),"skill":skill.snapshot(),"pickups":pickups.screen_rects()})
		if notice == "achievement" and not toast._toast.is_visible_in_tree():
			var phase: float = toast._phase_elapsed
			check(str(width)+" blocked achievement is retained",toast._placement_blocked and toast.is_presenting())
			await create_timer(0.3).timeout
			check(str(width)+" deferred phase does not expire",is_equal_approx(phase,toast._phase_elapsed))
			world._apply_target({})
			world.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			# Clearing the target does not necessarily free a full toast slot:
			# the native hero, HUD and future steering area remain exclusions.
			# Return through the mined passage and let normal camera framing
			# free space. Do not hide any HUD constraints.
			var before_movement: Dictionary = toast.debug_snapshot()
			var legal_step: = false
			var walked: Array[Vector2] = []
			for next in return_route():
				var direction: Vector2 = next-world.player.global_position
				world.restore_position(next)
				world.player.set_facing(direction)
				walked.append(next)
				world._apply_target({})
				await settle()
				main._update_achievement_toast_anchor()
				await process_frame
				if not toast._placement_blocked:
					legal_step = true
					break
			if not legal_step:
				# At the entry, looking up naturally shifts the hero below the
				# free central band. Allow the camera's normal easing to settle.
				world.player.set_facing(Vector2.UP)
				world._apply_target({})
				await create_timer(1.0).timeout
				await settle()
				main._update_achievement_toast_anchor()
				await process_frame
				legal_step = not toast._placement_blocked
			var resumed_phase: String = String(main.phase)
			if not legal_step:
				# The smallest viewport can remain full even at the shaft.
				# Complete its normal ascent instead of hiding the hero/HUD.
				check(str(width)+" retained notice reaches real ascent context",world.current_context()=="depthExit")
				world.perform_context()
				main.mine_world.player.set_physics_process(false)
				# Its normal process warms the newly visible terrain chunks.
				main.mine_world.set_process(true)
				# The return-route fixture places the miner at the existing D1
				# entrance floor; this is not a proof of traversing the whole D1.
				var exit_position: Vector2 = main.mine_world._entry_spawn()
				check(str(width)+" returned D1 entrance is legal floor",not main.mine_world._player_collides(exit_position))
				main.mine_world.restore_position(exit_position)
				check(str(width)+" returned D1 exit context is real",main.phase=="mine" and main.mine_exit_context)
				main.mine_world.current_target=Vector2i(-1,-1)
				main.mine_world.queue_redraw()
				for _frame in 8: await process_frame
				await RenderingServer.frame_post_draw
				main._update_achievement_toast_anchor()
				await process_frame
				legal_step = not toast._placement_blocked
				resumed_phase = String(main.phase)
			check(str(width)+" normal return frees achievement slot",legal_step)
			var deadline: int = Time.get_ticks_msec()+5000
			while Time.get_ticks_msec()<deadline and (not toast._toast.is_visible_in_tree() or String(toast.debug_snapshot().phase)!="hold"):
				await process_frame
				main._update_achievement_toast_anchor()
				await RenderingServer.frame_post_draw
			check(str(width)+" deferred achievement resumes visibly",toast._toast.is_visible_in_tree() and String(toast.debug_snapshot().phase)=="hold")
			var resume_image: String = "achievement-resumed-%d.png" % width
			root.get_texture().get_image().save_png(output.path_join(resume_image))
			records.append({"image":resume_image,"target_cleared_before_movement":before_movement,"achievement":toast.debug_snapshot(),"hero":main._active_player_node().visual.feedback_screen_rects(),"from_position":target_position,"to_position":world.player.global_position,"facing":world.player.facing_vector,"legal_step":legal_step,"walked_cells":walked,"resumed_world_phase":resumed_phase})
			if main.phase != "depth":
				main._dev_jump_mine("mossMine",2)
				world.set_process(false)
				world.player.set_physics_process(false)
		elif notice == "achievement": check(str(width)+" actual achievement presented",toast._toast.is_visible_in_tree())
	toast.clear()
	skill.clear()
	while not pickups.entries.is_empty(): pickups._remove_entry(0)

func run() -> void:
	output=OS.get_environment("MODS_OUT")
	if output.is_empty() or DisplayServer.get_name()=="headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for _frame in 5: await process_frame
	state=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	main._dev_jump_mine("mossMine",2)
	main.quick_tutorial.dismiss()
	main.get_node("MinerTraining").set_process(false)
	world=main.depth_world
	world.set_process(false)
	world.player.set_physics_process(false)
	world.get_node("MoleCompanion").set_process(false)
	world.get_node("MoleCompanion").set_physics_process(false)
	state.drill_level=0
	state.starforge_variant="crusher"
	check("authored ore exposed through actual terrain mining",expose_real_ore())
	var resume_only: bool = OS.get_environment("DEPTH2_RESUME_ONLY")=="1"
	var widths: Array = [667] if OS.get_environment("DEPTH2_WIDTH")=="667" else [667,844]
	for width in widths:
		root.size=Vector2i(width*2,750 if width==667 else 780)
		root.content_scale_size=root.size
		for _frame in 5: await process_frame
		if not resume_only:
			for kind in ["terrain","ore","bedrock","locked"]: await capture(width,kind)
			await capture(width,"ore",1.6)
		await notices(width,resume_only)
		world._apply_target({})
		world.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		check(str(width)+" target clear hides label",not world.get_node("TargetLabel").visible)
	var passed: bool=true
	for row in checks: passed=passed and row.passed
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"excavation":excavation,"records":records},"  "))
	print("DEPTH2_TARGET_LABEL_OK" if passed else "DEPTH2_TARGET_LABEL_FAILED")
	quit(0 if passed else 1)
