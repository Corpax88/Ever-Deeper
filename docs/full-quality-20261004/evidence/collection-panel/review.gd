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
	var goals=load("res://scripts/state/treasury_goals.gd")
	var panel: Control=main.treasury_goal_panel
	var results: Array=[]
	state.treasury_totals["copper"]=99999
	panel.open_goal("copper")
	await capture("copper-in-progress-667")
	results.append({"case":"collection_in_progress","passed":not panel.claim_button.visible and not panel.pin_button.disabled and panel.pin_button.text=="TRACK GOAL"})
	state.treasury_totals["copper"]=100000
	panel.refresh()
	await capture("copper-complete-667")
	results.append({"case":"collection_complete","passed":not panel.claim_button.visible and panel.detail.text=="COLLECTION COMPLETE" and panel.pin_button.disabled and panel.pin_button.text=="COLLECTION COMPLETE","art_size":str(panel.collection_icon.texture.get_size()),"art_source":str(panel.collection_icon.texture.atlas.resource_path)})
	panel.close_panel()
	for kind in goals.MODS:
		state.treasury_totals[kind]=100000
		var id: String=goals.mod_id(kind)
		state.treasury_goals[id+"_claimed"]=false
		panel.open_goal(kind)
		await capture(kind+"-ready-667")
		results.append({"case":kind+"_ready","passed":panel.claim_button.visible and not panel.claim_button.disabled and panel.claim_button.text.begins_with("CLAIM ") and not panel.pin_button.disabled,"source_size":str(panel.source.size),"source_minimum":str(panel.source.get_minimum_size()),"source_lines":panel.source.get_line_count(),"source_text":panel.source.text})
		panel.close_panel()
	panel.open_goal("wallet_gold")
	panel._claim()
	await capture("gold-claimed-667")
	results.append({"case":"mod_claimed","passed":panel.claim_button.visible and not panel.claim_button.disabled and panel.pin_button.disabled and panel.pin_button.text=="MOD UNLOCKED"})
	var passed: bool=true
	for result in results: passed=passed and result.passed
	FileAccess.open(output.path_join("collection-panel.json"),FileAccess.WRITE).store_string(JSON.stringify(results,"\t"))
	print("UX_COLLECTION_PANEL_OK" if passed else "UX_COLLECTION_PANEL_FAILED")
	quit(0 if passed else 2)
