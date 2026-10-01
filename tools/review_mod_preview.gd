extends SceneTree
var main: Node
var output: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func verify(ok: bool,label: String) -> void:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not ok: push_error("PREVIEW_CHECK_FAILED "+label);quit(2)
func capture(label: String) -> void:
	for i in 5: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label+".png"))
func run() -> void:
	output=OS.get_environment("MOD_REVIEW_OUTPUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main=load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main);current_scene=main
	for i in 5: await process_frame
	var state: Node=root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"));state.reset_run(false)
	main._dev_ensure_playing();main._dev_seed_victory_state();main._dev_jump_hub()
	var p: Control=main.treasury_goal_panel
	state.treasury_goals={}
	for amount in [0,56000,100000]:
		state.treasury_totals={"wallet_gold":amount}
		p.open_goal("wallet_gold")
		verify(p.visible and p.preview.texture!=null,"preview-visible-%d"%amount)
		verify(p.progress_bar.value==amount,"progress-%d"%amount)
		verify(p.claim_button.disabled==(amount<100000),"claim-gate-%d"%amount)
		await capture("gold-%d"%amount)
		p.close_panel()
	p.open_goal("wallet_gold");p._claim()
	verify(state.treasury_goals.get("resonance_claimed",false),"real-claim")
	await capture("claimed-on")
	p._claim();verify(not state.treasury_goals.resonance_enabled,"toggle-off")
	await capture("claimed-off")
	p.close_panel();p.open_goal("copper")
	verify(not p.preview.visible and not p.claim_button.visible,"undefined-mod-not-invented")
	await capture("copper-collection")
	p.close_panel();verify(not main.menu_open,"close-resumes")
	print("MOD_PREVIEW_OK");quit(0)
