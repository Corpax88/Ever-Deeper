extends SceneTree
## Focused phase/action review. Rewards, terrain and finale timing are unchanged.
var main: Node
var state: Node
var world: Node
var output: String
var reference: bool = false
var capture: bool = true
var checks: Array = []
var samples: Array = []

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool, detail: Dictionary = {}) -> void:
	checks.append({"name": label, "passed": passed, "detail": detail})
	if not passed: print("DEEPHEART_GOAL_MISMATCH " + label)

func seal_action() -> String:
	return "Follow the sealed path" if reference else "Hold MINE · open the seal"

func core_action() -> String:
	return "Deepheart passage · Hub" if reference else "Attune the core"

func take_sample(label: String, image: bool = false) -> void:
	main._update_visual_guide()
	for _frame in 8: await process_frame
	main.quick_tutorial.dismiss()
	main.achievement_toast.clear()
	var goal: Dictionary = main._progression_goal()
	var proposal: Dictionary = main._guide_route_proposal(goal)
	var visible: Dictionary = main.premium_hud.progression_goal_snapshot()
	var action: Label = main.premium_hud.progression_goal_panel._action
	var width: float = action.get_theme_font("font").get_string_size(action.text, HORIZONTAL_ALIGNMENT_LEFT, -1, action.get_theme_font_size("font_size")).x
	samples.append({"case": label, "phase": main.phase, "saved_scene": state.current_scene,
		"objective_id": goal.get("objective_id", ""), "action": goal.get("hud_action", ""),
		"visible_action": visible.get("action_text", ""), "waypoint_id": proposal.get("waypoint_id", ""),
		"action_text_width": width, "action_box_width": action.size.x,
		"viewport": [root.get_visible_rect().size.x, root.get_visible_rect().size.y]})
	check(label + " visible HUD agrees with active goal", visible.get("action_text", "") == goal.get("hud_action", ""))
	check(label + " action fits at 667", width <= action.size.x)
	if image and capture:
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty(): quit(2); return
	reference = "--reference" in OS.get_cmdline_user_args()
	capture = DisplayServer.get_name() != "headless"
	if not capture and "--goal-assertions-only" not in OS.get_cmdline_user_args(): quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("isolated.sav"))
	state.reset_run(false)
	state.world_seed = 4608
	seed(4608)
	main.persistence_active = false
	main._dev_ensure_playing()
	main.get_node("MinerTraining").set_process(false)
	main.get_node("MinerTraining").set_physics_process(false)
	var mole: Node = main.get_node("CompanionInterface").active_mole()
	mole.autonomous_enabled = false
	mole.set_physics_process(false)
	root.size = Vector2i(1334, 750)
	if capture: DisplayServer.window_set_size(root.size)
	var ordinary: Dictionary = main.guide_director.goal_for_state()
	check("ordinary progression keeps its action", main._progression_goal().get("hud_action", "") == ordinary.get("hud_action", ""))
	main._dev_jump_hub()
	main._dev_seed_deepheart_state()
	# Ready passage before the first entry; no seal/core completion is seeded.
	state.final_expedition_begun = false
	state.changed.emit()
	var before_entry: Dictionary = main._progression_goal()
	check("first entry retains Hub passage", before_entry.get("objective_id", "") == "endgame:final_descent" and before_entry.get("hud_action", "") == "Deepheart passage · Hub")
	main._enter_deepheart(true, false)
	world = main.deepheart_world
	world.player.set_physics_process(false)
	world.player.camera.position_smoothing_enabled = false
	check("entry phase precedes checkpoint in fixture", main.phase == "deepheart" and state.current_scene == "hub")
	check("active seal action before location checkpoint", main._progression_goal().get("hud_action", "") == seal_action())
	check("Deepheart checkpoint accepted", state.set_location("deepheart", world.player.global_position))
	main.premium_hud._refresh_progression_goal()
	check("state-driven HUD uses seal action", main.premium_hud.progression_goal_snapshot().get("action_text", "") == seal_action())
	for seal_id in ["mossvein", "moonglass", "emberdeep", "starfall"]:
		world.restore_position(Vector2(world.SEAL_POSITIONS[seal_id]) + Vector2(0, 75))
		world.player.set_facing(Vector2.UP)
		var goal: Dictionary = main._progression_goal()
		var route: Dictionary = main._guide_route_proposal(goal)
		check(seal_id + " retains canonical objective and seal route", goal.get("objective_id", "") == "endgame:seal:" + seal_id and route.get("waypoint_id", "") == "deepheart:seal:" + seal_id)
		check(seal_id + " describes the seal action", goal.get("hud_action", "") == seal_action())
		if seal_id in ["mossvein", "starfall"]: await take_sample("seal-" + seal_id + "-667", true)
		check(seal_id + " opens through state owner", state.open_deepheart_seal(seal_id))
		world._restore_finale_state()
	check("four seals unlock the core", state.deepheart_seal_status().all_open and not state.victory)
	world.restore_position(Vector2(world.CORE_CONTEXT_POSITION))
	world.player.set_facing(Vector2.DOWN)
	var core: Dictionary = main._progression_goal()
	var core_route: Dictionary = main._guide_route_proposal(core)
	check("core retains canonical objective and core route", core.get("objective_id", "") == "endgame:core" and core_route.get("waypoint_id", "") == "deepheart:core")
	check("ready core describes attunement", core.get("hud_action", "") == core_action())
	main.premium_hud._refresh_progression_goal()
	check("state-driven HUD uses core action", main.premium_hud.progression_goal_snapshot().get("action_text", "") == core_action())
	await take_sample("core-ready-667", true)
	main._exit_deepheart()
	check("Hub return before checkpoint restores passage action", main.phase == "hub" and main._progression_goal().get("hud_action", "") == "Deepheart passage · Hub")
	state.set_location("hub", main.hub_world.player.global_position)
	main.premium_hud._refresh_progression_goal()
	check("state-driven Hub HUD retains passage", main.premium_hud.progression_goal_snapshot().get("action_text", "") == "Deepheart passage · Hub")
	main._enter_deepheart(false, false)
	check("core re-entry before checkpoint restores attunement", main._progression_goal().get("hud_action", "") == core_action())
	state.set_location("deepheart", world.player.global_position)
	check("canonical victory still completes", state.complete_final_expedition())
	var after: Dictionary = main._progression_goal()
	check("victory uses unchanged endless progression", not String(after.get("objective_id", "")).begins_with("endgame:") and after.get("hud_action", "") == main.guide_director.goal_for_state().get("hud_action", ""))
	var failed: int = 0
	for item in checks:
		if not bool(item.passed): failed += 1
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"reference": reference, "captured": capture, "checks": checks, "samples": samples, "failed": failed}, "\t"))
	print("DEEPHEART_GOAL_FAILED" if failed else "DEEPHEART_GOAL_REFERENCE_REPRODUCED" if reference else "DEEPHEART_GOAL_OK")
	quit(1 if failed else 0)
