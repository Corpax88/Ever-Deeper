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
	for kind in load("res://scripts/state/treasury_state.gd").keys():
		if kind != "wallet_gold": state.cargo[kind]=25000
	main._open_inventory()
	await capture("inventory-full-667")
	var labels: Array=[]
	for node in main.resource_inventory.find_children("ResourceName","Label",true,false):
		labels.append({"text":node.text,"size":str(node.size),"minimum":str(node.get_minimum_size()),"line_count":node.get_line_count(),"visible_lines":node.get_visible_line_count(),"no_trim":node.text_overrun_behavior==TextServer.OVERRUN_NO_TRIMMING})
	FileAccess.open(output.path_join("inventory-names.json"),FileAccess.WRITE).store_string(JSON.stringify(labels,"\t"))
	var passed: bool=labels.size()>=26
	for label in labels: passed=passed and label.line_count==label.visible_lines and label.no_trim
	print("UX_INVENTORY_NAMES_OK" if passed else "UX_INVENTORY_NAMES_FAILED")
	quit(0 if passed else 2)
