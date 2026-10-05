extends SceneTree
## Exact-pack functional/rendered review. Teleports/funding are explicit fixtures;
## movement, mining, pickup, inventory, menu and purchases use their real owners.
var main: Node
var state: Node
var out: String
var checks: Array = []
var screenshots: Array = []
func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"name":label,"passed":ok})
	FileAccess.open(out.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"images":screenshots,"passed":checks.all(func(c):return c.passed),"physical_iphone":false},"\t"))
	if not ok: print("CHECK_FAILED "+label+" "+JSON.stringify(main.quick_tutorial.debug_snapshot())+" distance="+str(main.quick_tutorial._distance))
func settle(seconds: float = 0.3) -> void: await create_timer(seconds).timeout
func shot(_label: String) -> void:
	await settle(0.1)
func run() -> void:
	out=OS.get_environment("MODS_OUT")
	DirAccess.make_dir_recursive_absolute(out)
	state=root.get_node("RunState")
	main=load("res://scenes/main/main.tscn").instantiate();root.add_child(main);current_scene=main
	await settle(2.0)
	main._start_new_game();await settle()
	main.quick_tutorial.open(true)
	check("fresh touch is one nonblocking task",main.quick_tutorial._step==0 and main.quick_tutorial.debug_snapshot().item_count==1 and not main.quick_tutorial.debug_snapshot().input_blocking)
	await shot("01-touch-move")
	await settle(10.0)
	check("idle never completes movement",main.quick_tutorial._step==0 and not main.quick_tutorial.has_been_seen())
	main._open_start_menu();await settle();main._continue_from_menu();await settle()
	check("menu resumes current task",main.quick_tutorial._step==0 and main.quick_tutorial._running)
	main.quick_tutorial._touch_mode=true
	Input.action_press("move_right");await settle(1.4);Input.action_release("move_right");await settle()
	check("actual movement advances task",main.quick_tutorial._step==1)
	main.surface_world.restore_position(main.surface_world.mine_guide_position("mossMine"));await settle()
	main._update_visual_guide()
	check("lesson route matches Mossvein",String(main.guide_director.locked_target_key).contains("mossMine"))
	check("near entrance says DESCEND",main.quick_tutorial.goal_override({}).hud_action=="Tap DESCEND")
	await shot("02-descend")
	main._perform_context();await settle(0.6)
	check("real entrance advances mine lesson",main.phase=="mine" and main.quick_tutorial._step==2)
	state.record_mined("stone",1);await settle()
	check("mined counter without pickup cannot complete collect",main.quick_tutorial._step==2)
	var world: Node = main.mine_world
	var target_found := false
	for cell in world.blocks:
		var block: Dictionary=world.blocks[cell]
		if String(block.get("role",""))!="resource" or int(block.get("requires_tool",0))>state.pickaxe_level: continue
		for distance in [96.0,80.0,64.0]:
			var pos: Vector2=world._cell_center(cell)-Vector2.RIGHT*distance
			world.restore_position(pos);world.player.set_facing(Vector2.RIGHT)
			if world.player.global_position.distance_to(pos)<2.0 and world._find_mine_target()==cell:
				target_found=true;break
		if target_found: break
	check("natural mineable ore fixture",target_found)
	await settle();await shot("03-mine-focus")
	main._set_mine_held(true)
	for i in range(200):
		await settle(0.1)
		if not world.drops.is_empty() or state.cargo_count()>0: break
	main._set_mine_held(false)
	Input.action_press("move_right")
	for i in range(40):
		await settle(0.1)
		if state.cargo_count()>0: break
	Input.action_release("move_right");await settle()
	check("real pickup advances Bag lesson",state.cargo_count()>0 and main.quick_tutorial._step==3)
	await shot("04-bag-focus")
	main.premium_hud.bag_button.pressed.emit();await settle()
	check("opening actual Bag advances without losing guide",main.inventory_open and main.quick_tutorial._step==4 and main.quick_tutorial._running)
	await shot("05-bag-open")
	main._close_inventory();await settle()
	check("closing Bag restores upgrade lesson",main.quick_tutorial.is_teaching() and main.quick_tutorial._step==4)
	await shot("06-upgrade-goal")
	main._open_start_menu();main._continue_from_menu();await settle()
	check("upgrade task survives menu",main.quick_tutorial._step==4 and main.quick_tutorial.is_teaching())
	var saved: Dictionary=state.serialize()
	main.quick_tutorial.dismiss();check("save roundtrip",state.deserialize(saved));main._maybe_show_quick_tutorial();await settle()
	check("lesson resumes after state roundtrip",main.quick_tutorial._step==4)
	state.gold=int(state.next_pickaxe().cost)
	check("real upgrade transaction",state.upgrade_pickaxe());await settle()
	check("earned first upgrade completes tutorial",not main.quick_tutorial._running and main.quick_tutorial.has_been_seen())
	main._open_start_menu();main._replay_guidance();await settle()
	for direction in ["move_left", "move_down", "move_right", "move_up", "move_left", "move_down"]:
		Input.action_press(direction);await settle(0.8);Input.action_release(direction)
		if main.quick_tutorial._step >= 2: break
	await settle()
	check("advanced voluntary replay enters relevant mine task",main.quick_tutorial._step in [2,3] and (main.quick_tutorial._step==2 or (main.quick_tutorial._collected and state.cargo_count()>0)))
	var replay_step: int=main.quick_tutorial._step
	main._open_start_menu();main._continue_from_menu();await settle()
	check("advanced replay resumes through menu",main.quick_tutorial._replay and main.quick_tutorial._step==replay_step and main.quick_tutorial._running)
	main.quick_tutorial._skip.pressed.emit();await settle()
	check("skip ends guide without resetting expedition",not main.quick_tutorial._running and state.pickaxe_level==2)
	main._start_new_game();await settle()
	check("new run resets tutorial",main.quick_tutorial._step==0 and main.quick_tutorial._running)
	main.quick_tutorial.open(true)
	for dimensions in [Vector2i(1688,780),Vector2i(1864,860)]:
		root.size=dimensions;await settle(0.7);await shot("07-touch-"+str(dimensions.x/2))
	check("all checks recorded",true)
	print("GUIDANCE_LOGIC_OK" if checks.all(func(c):return c.passed) else "GUIDANCE_FAILED")
	quit(0 if checks.all(func(c):return c.passed) else 1)
