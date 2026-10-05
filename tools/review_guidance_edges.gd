extends SceneTree
var main: Node
var state: Node
var out: String
var checks: Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	if not ok: print("CHECK_FAILED "+label)
func wait() -> void: await create_timer(0.6).timeout
func shot(label: String) -> void:
	await wait();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(label+".png"))
func run() -> void:
	out=OS.get_environment("GUIDANCE_OUT");DirAccess.make_dir_recursive_absolute(out)
	state=root.get_node("RunState")
	main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
	await create_timer(2.0).timeout;main._start_new_game();await wait()
	main.quick_tutorial._step=4;state.gold=int(state.next_pickaxe().cost);state._state_changed()
	main.surface_world.restore_position(main.surface_world.station_interaction_position("forge") + Vector2(150,0));await wait()
	main.surface_world.restore_position(main.surface_world.station_interaction_position("forge"));await wait();main._update_visual_guide()
	print("FORGE_DEBUG ",main.guide_director.debug_snapshot()," pos=",main.surface_world.player.global_position," active=",main.surface_world.active_context," phase=",main.phase," context=",main.surface_context," button=",main.premium_hud.context_button.visible," disabled=",main.premium_hud.context_button.disabled," lesson=",main.quick_tutorial.debug_snapshot())
	check("last lesson hands attention to matching Forge",main.guide_overlay.action_control==main.premium_hud.context_button)
	check("nearby unrelated action never highlighted",main._matching_guide_control("surface:mine:mossMine")==null)
	await shot("01-forge-lesson-handoff")
	main.quick_tutorial._skip.pressed.emit();main._update_visual_guide();await shot("02-forge-ordinary-handoff")
	main._dev_seed_victory_state();main._dev_jump_hub();main.hub_world.treasury.enter();await wait()
	main.quick_tutorial.replay(true);await wait();await shot("03-treasury-replay-move")
	main.quick_tutorial._step=1;await wait();main._update_visual_guide()
	check("Treasury replay route is actual exit",main.guide_overlay.target_world==main.hub_world.treasury.EXIT)
	var shown:=true
	for i in range(30):
		await process_frame
		shown=shown and main.premium_hud.progression_goal_panel.is_visible_in_tree()
	check("Treasury goal stays visible across competing frame updates",shown)
	await shot("04-treasury-replay-route")
	main.quick_tutorial._step=3;await wait()
	check("Treasury Bag lesson has reachable Bag",main.premium_hud.bag_button.is_visible_in_tree())
	await shot("05-treasury-bag")
	main.premium_hud.bag_button.pressed.emit();await wait()
	check("Treasury advanced replay completes by actual Bag action",main.inventory_open and not main.quick_tutorial._running)
	main._close_inventory();await wait()
	check("normal Treasury HUD restored after guide",not main.premium_hud.bag_button.visible and not main.premium_hud.progression_goal_panel.visible)
	print("GUIDANCE_EDGES_OK" if checks.all(func(c):return c.passed) else "GUIDANCE_EDGES_FAILED")
	quit(0 if checks.all(func(c):return c.passed) else 1)
