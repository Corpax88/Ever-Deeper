extends RefCounted
## Shared presentation for Depth 1/2 target text. World owners retain targeting,
## mining rules and their authored brackets, rings and contact markers.

static func hide_for(world: Node2D) -> void:
	var label: Label = world.get_node_or_null("TargetLabel")
	if label != null:
		label.hide()


static func present(world: Node2D, canvas: Transform2D, world_rect: Rect2, text: String, hero_rects: Array[Rect2], label_name: String = "TargetLabel") -> void:
	# Project placement first, then cancel world zoom on the one reused Label.
	# Its unshaded material keeps action requirements legible in dark mines.
	var target_screen: Rect2 = canvas * world_rect
	var font: Font = ThemeDB.fallback_font
	var font_size: = 24
	var text_size: = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var safe_screen: = world.get_viewport_rect().grow(-12.0)
	var gap: = 9.0
	var above: = Vector2(target_screen.get_center().x - text_size.x * 0.5, target_screen.position.y - text_size.y - gap)
	var below: = Vector2(above.x, target_screen.end.y + gap)
	var right: = Vector2(target_screen.end.x + gap, target_screen.get_center().y - text_size.y * 0.5)
	var left: = Vector2(target_screen.position.x - text_size.x - gap, right.y)
	var exclusions: Array[Rect2] = hero_rects.duplicate()
	var main: Node = world.get_tree().current_scene
	if main != null and main.get("premium_hud") != null:
		var hud: Control = main.premium_hud
		for control in [hud.progression_goal_panel, hud.bag_button, main.mine_button, hud.context_button]:
			if is_instance_valid(control) and control.is_visible_in_tree():
				exclusions.append(control.get_global_transform_with_canvas() * Rect2(Vector2.ZERO, control.size))
		exclusions.append(hud.minimap_layout_rect())
	var label_position: = above.clamp(safe_screen.position, safe_screen.end - text_size)
	for candidate in [above, below, right, left, above - Vector2(0, 48), below + Vector2(0, 48)]:
		var candidate_position: = Vector2(
			clampf(candidate.x, safe_screen.position.x, safe_screen.end.x - text_size.x),
			clampf(candidate.y, safe_screen.position.y, safe_screen.end.y - text_size.y)
		)
		var clear: = true
		for hero_rect in exclusions:
			if Rect2(candidate_position, text_size).grow(4.0).intersects(hero_rect):
				clear = false
				break
		if clear:
			label_position = candidate_position
			break
	var label: Label = world.get_node_or_null(label_name)
	if label == null:
		label = Label.new()
		label.name = label_name
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.z_as_relative = false
		label.z_index = RenderingServer.CANVAS_ITEM_Z_MAX - 1
		var text_material: = CanvasItemMaterial.new()
		text_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		label.material = text_material
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", Color("ffdc4d"))
		label.add_theme_color_override("font_outline_color", Color("08121c"))
		label.add_theme_constant_override("outline_size", 6)
		world.add_child(label)
	label.text = text
	label.size = text_size
	var label_canvas: = world.get_global_transform_with_canvas()
	label.position = label_canvas.affine_inverse() * label_position
	label.scale = Vector2(1.0 / label_canvas.x.length(), 1.0 / label_canvas.y.length())
	label.show()


static func passage_open(world: Node2D, canvas: Transform2D, world_rect: Rect2, hero_rects: Array[Rect2]) -> void:
	present(world, canvas, world_rect, "PASSAGE OPEN · 10 / 10", hero_rects, "PassageFeedback")
	var label: Label = world.get_node("PassageFeedback")
	var previous: Tween = label.get_meta("fade") if label.has_meta("fade") else null
	if previous != null and previous.is_valid(): previous.kill()
	label.modulate.a = 1.0
	var fade: Tween = world.create_tween()
	label.set_meta("fade", fade)
	fade.tween_interval(1.2)
	fade.tween_property(label, "modulate:a", 0.0, 0.3)
	fade.tween_callback(label.hide)
