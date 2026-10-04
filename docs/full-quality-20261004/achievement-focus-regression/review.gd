extends SceneTree
var main: Node
var output: String = OS.get_environment("UX_MAP_OUTPUT")
func _initialize() -> void: run.call_deferred()
func capture(name: String) -> void:
	for i in 5: await process_frame
	main.achievement_toast.clear()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(name+".png"))
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene=main
	for i in 6: await process_frame
	var state: Node=root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated-save.json"))
	state.reset_run(false)
	main._dev_ensure_playing()
	main._dev_seed_victory_state()
	main._open_miner_skills()
	main._show_expanded_map()
	await capture("surface-labels-667")
	main._close_miner_skills()
	main._open_start_menu()
	main.premium_menu.show_achievements("threefold_star")
	await capture("achievement-highlight-667")
	var menu: Control=main.premium_menu
	var results: Array=[]
	var definitions: Array=menu.achievement_service.definitions()
	for definition in [definitions[0],definitions[28],definitions[-1]]:
		var id: String=String(definition.id)
		menu.show_achievements(id)
		for i in 5: await process_frame
		var row: Control=menu.achievement_rows[id]
		var rect: Rect2=row.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,row.size)
		var scroll_rect: Rect2=menu.achievement_scroll.get_global_transform_with_canvas()*Rect2(Vector2.ZERO,menu.achievement_scroll.size)
		results.append({"id":id,"retained":menu.achievement_highlight_id==id,"visible":scroll_rect.intersection(rect).size.y>=rect.size.y-1.0,"scroll":menu.achievement_scroll.scroll_vertical})
	menu.show_achievements("threefold_star")
	menu.navigate_back()
	for i in 3: await process_frame
	var back_ok: bool=menu.main_view.visible and not menu.detail_view.visible and menu.achievement_scroll==null
	var passed: bool=back_ok
	for result in results: passed=passed and result.retained and result.visible
	FileAccess.open(output.path_join("achievement-focus.json"),FileAccess.WRITE).store_string(JSON.stringify({"targets":results,"back_during_pending_focus":back_ok},"\t"))
	print("UX_FOCUS_MATRIX_OK" if passed else "UX_FOCUS_MATRIX_FAILED")
	quit(0 if passed else 2)
