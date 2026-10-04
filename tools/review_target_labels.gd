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

func capture(width: int, kind: String, zoom_scale: float = 1.0) -> void:
	var selected: bool = select_case(kind)
	check(str(width) + " " + kind + " real terrain case found", selected)
	if not selected: return
	world.player._update_visual(false)
	world.player.camera.zoom *= zoom_scale
	world.player.camera.reset_smoothing()
	world.player.camera.force_update_scroll()
	main._refresh_hud()
	for _frame in 10: await process_frame
	world.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var block: Dictionary = world.blocks[world.current_target]
	var text: String = world._target_label(block)
	check(str(width) + " " + kind + " label explains target", (text == "BEDROCK" if kind == "bedrock" else text.ends_with(" REQUIRED") if kind == "locked" else "HIT" in text))
	var label: Label = world.get_node("TargetLabel")
	var label_rect: Rect2 = label.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, label.size)
	var projected_font_size: float = label.get_global_transform_with_canvas().y.length() * label.get_theme_font_size("font_size")
	check(str(width) + " " + kind + " readable 24px font independent of zoom", absf(projected_font_size - 24.0) < 0.05)
	check(str(width) + " " + kind + " text bypasses terrain lighting", label.material.light_mode == CanvasItemMaterial.LIGHT_MODE_UNSHADED)
	for hero_rect in world.player.visual.feedback_screen_rects():
		check(str(width) + " " + kind + " text clears hero", not label_rect.intersects(hero_rect))
	var rig: Node = world.player.visual._native_worn.rig
	check(str(width) + " " + kind + " approved native hero visible", rig != null and rig.sprite.is_visible_in_tree())
	var filename: String = "%s-%d%s.png" % [kind, width, "-zoom" if zoom_scale != 1.0 else ""]
	root.get_texture().get_image().save_png(output.path_join(filename))
	records.append({"image": filename, "label": text, "label_rect": label_rect, "font_pixels_in_logical_viewport": projected_font_size, "cell": world.current_target, "block": block, "viewport": world.get_viewport_rect(), "canvas": world.get_global_transform_with_canvas(), "hero": world.player.visual.feedback_screen_rects(), "camera_zoom": world.player.camera.zoom, "natural_selection": kind != "bedrock"})
	world.player.camera.zoom /= zoom_scale

func run() -> void:
	output = OS.get_environment("MODS_OUT")
	if output.is_empty() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for _frame in 5: await process_frame
	state = root.get_node("RunState")
	state.initialize_persistence(output.path_join("save.json"))
	state.reset_run(false)
	state.cargo = {"copper": 50}
	main._dev_jump_mine("mossMine", 1)
	main.quick_tutorial.dismiss()
	main.get_node("MinerTraining").set_process(false)
	main.achievement_toast.clear()
	world = main.mine_world
	world.set_process(false)
	world.player.set_physics_process(false)
	world.get_node("MoleCompanion").set_process(false)
	world.get_node("MoleCompanion").set_physics_process(false)
	for width in [667, 844]:
		root.size = Vector2i(width * 2, 750 if width == 667 else 780)
		root.content_scale_size = root.size
		for _frame in 5: await process_frame
		for kind in ["stone", "ore", "bedrock", "locked"]:
			await capture(width, kind)
		await capture(width, "ore", 1.6)
		world.current_target = Vector2i(-1, -1)
		world.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		check(str(width) + " cleared target leaves no stale label", not world.get_node("TargetLabel").visible)
	var passed: bool = true
	for row in checks: passed = passed and row.passed
	FileAccess.open(output.path_join("report.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "checks": checks, "records": records}, "  "))
	print("TARGET_LABEL_RENDER_OK" if passed else "TARGET_LABEL_RENDER_FAILED")
	quit(0 if passed else 1)
