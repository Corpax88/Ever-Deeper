extends SceneTree
## Reversible, rendered comparison. No diagnostic switch is exposed to players.
var output_dir := ""
var pack_source := ""
var main: Node
var state: Node
var world: Node2D
var rows: Array[Dictionary] = []
var failures: Array[String] = []
var seconds := 3.0
const STYLES = ["standard", "wide", "focused", "prismatic", "deepheart"]
const MINES = ["mossMine", "moonMine", "emberMine", "starMine"]

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output_dir = arg.trim_prefix("--output=")
		if arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		if arg.begins_with("--seconds="): seconds = maxf(0.5, float(arg.trim_prefix("--seconds=")))
	if output_dir.is_empty() or DisplayServer.get_name() == "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output_dir)
	state = root.get_node("RunState")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	state.initialize_persistence(output_dir.path_join("isolated-save.json"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main._dev_ensure_playing()
	main._dev_grant_max_tools_state()
	for mine_id in MINES:
		main._dev_jump_mine(mine_id, 1)
		world = main.mine_world
		await _settle(2.0)
		for index in STYLES.size():
			var barrier: Dictionary = world.mine.barriers[index % world.mine.barriers.size()]
			var positions: Array[Vector2] = [Vector2(850,800), Vector2(float(barrier.x)-100,float(barrier.y)), world._entry_spawn(), world.world_size * 0.5, world.world_size-Vector2(240,240)]
			world.restore_position(positions[index])
			if index == 2: _place_by_exposed_resource()
			await _fixture_lights(index)
			# Include damaged terrain and real transient draw data in one fixture.
			if index == 3:
				world.current_target = world._find_mine_target()
				if world.blocks.has(world.current_target):
					var block: Dictionary = world.blocks[world.current_target]
					block.hp = maxf(1.0, float(block.max_hp)*0.5)
					world.blocks[world.current_target] = block
				world.impacts.append({"position":world.player.global_position+Vector2(50,0),"age":0.05,"life":0.32,"broken":true,"style":"standard"})
			world.queue_redraw()
			await _triplet(mine_id+"-"+String(STYLES[index]))
	for depth in range(10,15):
		main._dev_jump_endless(depth)
		world = main.endless_world
		await _settle(2.0)
		await _fixture_lights(depth % STYLES.size())
		await _triplet("deep-%d-%s" % [depth,STYLES[depth % STYLES.size()]])
	Engine.time_scale = 1.0
	paused = false
	var file = FileAccess.open(output_dir.path_join("mining-receivers.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"physical_iphone":false,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"window":str(DisplayServer.window_get_size()),"pack_sha256":FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else "editable-source-preflight","stages":rows,"failures":failures},"\t"))
	file.close()
	print("MINING_RECEIVER_REVIEW_COMPLETE " + JSON.stringify({"stages":rows.size(),"failures":failures}))
	quit(0 if failures.is_empty() else 2)

func _place_by_exposed_resource() -> void:
	for cell in world.blocks:
		if not world._resource_node_uses_transparent_surround(world.blocks[cell], world._open_block_sides(cell)): continue
		var cell_index: int = cell.y * world.cols + cell.x
		if world.concealed_cavern_cells.has(cell_index): continue
		for offset in [Vector2i.RIGHT,Vector2i.DOWN,Vector2i.LEFT,Vector2i.UP]:
			if world.blocks.has(cell+offset): continue
			var position: Vector2 = world._cell_center(cell+offset)
			if world._player_collides(position): continue
			world.restore_position(position)
			return
	failures.append(String(world.mine_id)+" no reachable exposed resource fixture")


func _coverage() -> Dictionary:
	var result: Dictionary = {"player_position":str(world.player.global_position)}
	if world != main.mine_world: return result
	var view: Rect2 = world._visual_visible_rect(Vector2.ZERO)
	var resources := 0
	var corners := 0
	for cell in world.blocks:
		if not view.has_point(world._cell_center(cell)): continue
		if world._resource_node_uses_transparent_surround(world.blocks[cell],world._open_block_sides(cell)): resources += 1
		if world._block_emits_mineable_edge(world.blocks[cell]):
			var sides: Array[bool] = world._mineable_edge_open_sides(cell)
			for side in 4:
				if sides[side] and sides[(side+1)%4]: corners += 1
	result.merge({"visible_exposed_resource_cells":resources,"visible_mineable_corners":corners})
	return result


func _fixture_lights(index: int) -> void:
	world.player.set_external_movement(Vector2.ZERO)
	world.player.camera.position_smoothing_enabled = false
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	var direction: Vector2 = [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2(-1,-1),Vector2.DOWN][index]
	world.player.set_facing(direction)
	for node in world.find_children("HelmetCone","PointLight2D",true,false):
		var beam: Node2D = node.get_parent()
		beam.preview_settings = {"style":STYLES[index],"range_multiplier":1.4,"energy_multiplier":1.3}
		beam.refresh_workshop_effects()
		beam.set_direction(direction)
	await _settle(0.7)
	main.achievement_toast.clear()
	paused = true
	Engine.time_scale = 0.0

func _triplet(label: String) -> void:
	var lights_before: int = _light_signature()
	var terrain_before: int = hash(world.blocks) if world == main.mine_world else hash([world.floor_cells,world.dig_damage])
	for variant in ["broad","narrow","restored"]:
		if world.get("lit_floor_chunks") != null: world.lit_floor_chunks.enabled = variant == "narrow"
		world.lit_draw_sections.enabled = variant == "narrow"
		world.queue_redraw()
		await _settle(0.7)
		await _measure(label+"-"+variant)
		if _light_signature() != lights_before: failures.append(label+" lights changed")
		var terrain_after: int = hash(world.blocks) if world == main.mine_world else hash([world.floor_cells,world.dig_damage])
		if terrain_after != terrain_before: failures.append(label+" terrain changed during drawing")
		for unused in range(world.lit_draw_sections._used,world.lit_draw_sections._pool.size()):
			if world.lit_draw_sections._pool[unused].visible: failures.append(label+" unused section visible")
	if world.get("lit_floor_chunks") != null: world.lit_floor_chunks.enabled = true
	world.lit_draw_sections.enabled = true
	world.queue_redraw()
	Engine.time_scale = 1.0
	paused = false

func _light_signature() -> int:
	var properties: Array = []
	for light in world.find_children("*","PointLight2D",true,false):
		properties.append([light.get_instance_id(),light.enabled,light.texture,light.energy,light.color,light.texture_scale,light.global_transform,light.offset,light.range_item_cull_mask,light.shadow_enabled,light.shadow_item_cull_mask,light.shadow_filter,light.shadow_filter_smooth])
	return hash(properties)

func _settle(duration: float) -> void:
	var begun := Time.get_ticks_usec()
	while Time.get_ticks_usec()-begun < duration*1000000.0: await process_frame
	await RenderingServer.frame_post_draw

func _measure(label: String) -> void:
	var begun := Time.get_ticks_usec()
	var previous := begun
	var samples: Array[float] = []
	while Time.get_ticks_usec()-begun < seconds*1000000.0:
		await process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now-previous)/1000.0)
		previous = now
	var ordered := samples.duplicate(); ordered.sort()
	var total := 0.0
	for sample in samples: total += sample
	var row: Dictionary = {"label":label,"frames":samples.size(),"fps":samples.size()*1000.0/total,"p95_ms":ordered[clampi(ceili(samples.size()*0.95)-1,0,samples.size()-1)],"raw_frame_ms":samples,"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"gpu_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"sections":world.lit_draw_sections._pool.size()}
	row["coverage"] = _coverage()
	rows.append(row)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir.path_join(label+".png"))
	var brief := row.duplicate(); brief.erase("raw_frame_ms")
	print("MINING_RECEIVER_STAGE "+JSON.stringify(brief))
