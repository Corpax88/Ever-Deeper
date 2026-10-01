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
		push_error("MAP_CHECK_FAILED "+label)
		quit(2)
func capture(label: String) -> void:
	main.achievement_toast.clear()
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	output=OS.get_environment("MAP_REVIEW_OUTPUT")
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
	for mine in ["mossMine","moonMine","emberMine","starMine"]:
		for depth in [1,2]:
			verify(main._dev_jump_mine(mine,depth),"enter "+mine+str(depth))
			for i in 6: await process_frame
			main._update_minimap()
			verify(main.exploration_map.texture!=null,"real terrain "+mine+str(depth))
			await capture(mine+str(depth)+"-mini")
			main._open_miner_skills()
			main.miner_skills_panel.show_map(main.minimap_overlay)
			await capture(mine+str(depth)+"-map")
			verify(main.miner_skills_panel.map_view.cartography==main.exploration_map,"shared map "+mine+str(depth))
			main._close_miner_skills()
	main._dev_jump_endless(1)
	for i in 6: await process_frame
	main._update_minimap()
	await capture("deep-mini")
	var world: Node=main.endless_world
	var cart: RefCounted=main.exploration_map
	var origin: Vector2i=world._world_to_cell(world.player.global_position)
	print("MAP_DEBUG ",origin," ",cart.dims," ",world.player.global_position," ",cart._known.size())
	var target:=Vector2i(-1,-1)
	for y in range(-8,9):
		for x in range(-8,9):
			var cell:=origin+Vector2i(x,y)
			if world._cell_in_bounds(cell) and world._cell_diggable(cell) and not world._is_floor(cell) and world._has_floor_neighbor(cell) and cart.discovered(world._cell_center(cell)):
				target=cell
				break
		if target.x>=0: break
	verify(target.x>=0,"visible mining frontier")
	if target.x<0: return
	var before: Color=cart.image.get_pixelv(target)
	verify(world._break_diggable_cell(target),"excavate real terrain")
	main._update_minimap()
	verify(cart.image.get_pixelv(target)!=before and world._is_floor(target),"map updates after excavation")
	# Excavate a meaningful bent corridor through the actual terrain API.
	for y in range(4,17):
		for x in range(14,17): world._break_diggable_cell(Vector2i(x,y))
		world.player.global_position=world._cell_center(Vector2i(15,y))
		main._update_minimap()
	for x in range(16,25):
		for y in range(14,17): world._break_diggable_cell(Vector2i(x,y))
		world.player.global_position=world._cell_center(Vector2i(x,15))
		main._update_minimap()
	await capture("deep-corridor-mini")
	main._open_miner_skills()
	main.miner_skills_panel.show_map(main.minimap_overlay)
	await capture("deep-map")
	main._close_miner_skills()
	var remembered: Dictionary=state.map_explored.endless.duplicate(true)
	for next_depth in [2,3,4]:
		var seam: int=(next_depth-world.window_start_depth)*world.DeepLayout.CHUNK_ROWS
		for row in range(seam-2,seam+3):
			for col in range(18,21): world._break_diggable_cell(Vector2i(col,row))
		var point: Vector2=world._cell_center(Vector2i(19,seam+1))
		world.player.global_position=point
		world._on_player_moved(point)
		main._update_minimap()
	verify(cart.offset.y>0,"Deep streamed window rebased")
	for key in remembered: verify(state.map_explored.endless.has(key),"retained absolute cell "+key)
	await capture("deep-rebased-mini")
	var saved: Dictionary=state.serialize()
	var known: Dictionary=state.map_explored.duplicate(true)
	verify(state.deserialize(saved),"load additive map save")
	verify(state.map_explored==known,"exploration persists")
	main._update_minimap()
	verify(cart._known==state.map_explored.endless,"map rebinds restored save")
	var empty: Dictionary=saved.duplicate(true)
	empty.state.erase("map_explored")
	verify(state.deserialize(empty) and state.map_explored.is_empty(),"legacy save remains compatible")
	main._update_minimap()
	verify(not cart._known.is_empty(),"legacy exploration starts locally")
	state.reset_run(false)
	verify(state.map_explored.is_empty(),"new game clears map")
	print("MAP_REVIEW_OK")
	quit(0)
