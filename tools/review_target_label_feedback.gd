extends SceneTree
## Isolated real-package presentation review; no terrain or reward mutation.
var main: Node
var world: Node2D
var state: Node
var output: String
var records: Array = []
var checks: Array = []

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed: print("TARGET_LABEL_MISMATCH " + label)

func select_case(kind: String) -> bool:
	var cells: Array = world.blocks.keys()
	var entrance: Vector2 = world._entry_spawn()
	cells.sort_custom(func(a, b): return world._cell_center(a).distance_squared_to(entrance) < world._cell_center(b).distance_squared_to(entrance))
	for cell in cells:
		var block: Dictionary = world.blocks[cell]
		var matches: bool = (kind == "stone" and String(block.kind) == "stone" and String(block.role) == "terrain") or (kind == "ore" and String(block.kind) != "stone" and String(block.role) == "resource" and int(block.requires_tool) <= state.pickaxe_level) or (kind == "locked" and int(block.requires_tool) > state.pickaxe_level) or (kind == "bedrock" and String(block.kind) == "bedrock" and cell.x > 5 and cell.y > 5)
		if not matches: continue
		for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]:
			for distance in [64.0, 80.0, 96.0]:
				var position: Vector2 = world._cell_center(cell) - direction * distance
				if world._player_collides(position): continue
				world.restore_position(position)
				if world.player.global_position.distance_to(position) > 2: continue
				world.player.set_facing(direction)
				if kind != "bedrock" and world._find_mine_target() != cell: continue
				# Bedrock is intentionally not selectable in ordinary play. Its
				# existing fallback words are inspected without changing selection.
				world.current_target = cell
				world.target_dirty = false
				return true
	return false

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	main._dev_jump_mine("mossMine", 1)
	main.quick_tutorial.dismiss()
	main.get_node("MinerTraining").set_process(false)
	world = main.mine_world
	world.set_process(false)
	world.player.set_physics_process(false)
	world.get_node("MoleCompanion").set_process(false)
	world.get_node("MoleCompanion").set_physics_process(false)
	root.size = Vector2i(1334,750)
	root.content_scale_size = root.size
	for _frame in 5: await process_frame
	check("known crowded bedrock target located", select_case("bedrock"))
	world.player._update_visual(false)
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	for _frame in 10: await process_frame
	world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var label: Label = world.get_node("TargetLabel")
	var label_rect: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,label.size)
	var target_cell: Vector2i = world.current_target
	var toast: Node = main.achievement_toast
	var skill: Node = toast.get_node("SkillLevelToast")
	var pickups: Node = world.player.get_node("ResourcePickupBurst")
	for notice in ["achievement", "skill", "pickup", "simultaneous"]:
		world.current_target = target_cell
		world.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		toast.clear()
		skill.clear()
		while not pickups.entries.is_empty(): pickups._remove_entry(0)
		if notice in ["achievement", "simultaneous"]:
			main._on_achievement_unlocked(root.get_node("GameData").data.ACHIEVEMENT_BY_ID.first_chip)
		if notice in ["skill", "simultaneous"]:
			skill._earned("mining",2)
		if notice in ["pickup", "simultaneous"]:
			main._on_resource_collected("copper",5)
			main._on_resource_collected("moonglass",3)
			main._on_resource_collected("gold",1)
		await create_timer(0.6).timeout
		main._update_achievement_toast_anchor()
		await process_frame
		await RenderingServer.frame_post_draw
		var toast_rect: Rect2 = toast._toast.get_global_transform_with_canvas() * Rect2(Vector2.ZERO,toast._toast.size)
		var skill_rect: Rect2 = skill.reserved_screen_rect()
		if notice == "skill": check("skill actually presented", skill.is_visible_in_tree())
		if toast._toast.is_visible_in_tree(): check(notice+" achievement clears target label",not label_rect.intersects(toast_rect))
		if skill.is_visible_in_tree() and skill_rect.has_area(): check(notice+" skill clears target label",not label_rect.intersects(skill_rect))
		for rect in pickups.screen_rects(): check(notice+" pickup clears target label",not label_rect.intersects(rect))
		root.get_texture().get_image().save_png(output.path_join(notice+"-667.png"))
		records.append({"state":notice,"label":label_rect,"achievement":toast.debug_snapshot(),"skill":skill.snapshot(),"pickups":pickups.screen_rects()})
		if notice == "achievement" and not toast._toast.is_visible_in_tree():
			var paused_phase: float = toast._phase_elapsed
			check("crowded achievement is explicitly deferred", toast._placement_blocked and toast.is_presenting())
			await create_timer(0.3).timeout
			check("deferred achievement retains its phase", is_equal_approx(paused_phase,toast._phase_elapsed))
			world.current_target = Vector2i(-1,-1)
			world.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var deadline: int = Time.get_ticks_msec()+5000
			while Time.get_ticks_msec()<deadline and (not toast._toast.is_visible_in_tree() or toast._phase_elapsed<=paused_phase):
				await process_frame
				main._update_achievement_toast_anchor()
				await RenderingServer.frame_post_draw
			check("deferred achievement resumes visibly with advancing phase after target clears", toast._toast.is_visible_in_tree() and not toast._placement_blocked and toast._phase_elapsed>paused_phase)
			while Time.get_ticks_msec()<deadline and String(toast.debug_snapshot().phase)=="spin":
				await process_frame
				await RenderingServer.frame_post_draw
			check("resumed achievement reaches readable hold", toast._toast.is_visible_in_tree() and String(toast.debug_snapshot().phase)=="hold")
			root.get_texture().get_image().save_png(output.path_join("achievement-resumed-667.png"))
			records.append({"state":"achievement-resumed","achievement":toast.debug_snapshot(),"target_label_visible":label.is_visible_in_tree()})
		elif notice == "achievement":
			check("achievement actually presented", true)
	var passed: bool = true
	for row in checks: passed = passed and row.passed
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks,"records":records},"  "))
	print("TARGET_LABEL_OVERLAP_OK" if passed else "TARGET_LABEL_OVERLAP_FAILED")
	quit(0 if passed else 1)
