class_name PremiumHud
extends Control

signal bag_requested
signal context_requested
signal hub_build_requested
signal menu_requested
signal minimap_layout_changed(map_rect: Rect2)
signal onboarding_layout_changed(available_rect: Rect2)

const ProgressionGoalPanelScript: = preload("res://scripts/ui/progression_goal_panel.gd")
const ProgressionGuideScript: = preload("res://scripts/progression/guide_director.gd")

const BAG_ICON: = preload("res://assets/ui/bag-premium-v1.png")
const MENU_ICON: = preload("res://assets/ui/hud-menu-v1.png")
const GUIDE_ICON: = preload("res://assets/ui/hud-guide-v1.png")
const INTERACT_ICON: = preload("res://assets/ui/hud-interact-v1.png")
const BUILD_ICON: = preload("res://assets/ui/hud-build-v1.png")
const GOLD_ICON: = preload("res://assets/ui/gold-bars-v1.png")
const MOLE_ICON: = preload("res://assets/companion/mole-hud.png")
const GOLD: = Color("d7b45a")
const GOLD_BRIGHT: = Color("ffe3a0")
const MINT: = Color("a8e3bc")
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const IPHONE_TOUCH_TARGET: = 86.0
const IPHONE_TOP_BUTTON_SIZE: = 96.0
const IPHONE_MENU_ICON_MAX: = 96
const IPHONE_TOP_ICON_MAX: = 84
const IPHONE_MINE_SIZE: = 154.0
const IPHONE_MINE_RIGHT: = 116.0
const IPHONE_MINE_BOTTOM: = 42.0
const IPHONE_BAG_SIZE: = 118.0
const IPHONE_BAG_ICON_MAX: = 104
const IPHONE_SECONDARY_ICON_MAX: = 108
const IPHONE_CONTEXT_BUILD_ICON_MAX: = 104
const IPHONE_CONTEXT_GUIDE_ICON_MAX: = 104
const IPHONE_CONTEXT_GOLD_ICON_MAX: = 96
const IPHONE_CONTEXT_SIZE: = Vector2(206.0, 104.0)
const DEFAULT_CONTEXT_SIZE: = Vector2(158.0, 64.0)
const IPHONE_GOLD_ICON_SIZE: = 60.0
const IPHONE_ACTION_GAP: = 18.0

var progression_goal_panel: Control
var _progression_guide: RefCounted = ProgressionGuideScript.new()
var _progression_row_count: = 0
var _minimap_layout_rect: = Rect2()
var _onboarding_layout_rect: = Rect2()

var objective_chip: PanelContainer
var objective_title: Label
var objective_detail: Label
var status_panel: PanelContainer
var status_label: Label
var gold_icon: TextureRect
var gold_value: Label
var gold_cluster: Control
var bag_count: Label
var bag_button: Button
var menu_button: Button
var guide_button: Button
var context_button: Button
var build_button: Button

var _objective_available: = false
var _objective_open: = false
var _objective_tween: Tween
var _status_tween: Tween
var _context_label: = ""
var _context_enabled: = false
var _context_signature_valid: = false
var _objective_title_signature: = ""
var _objective_detail_signature: = ""
var _objective_signature_valid: = false
var _gold_signature: = 0
var _cargo_signature: = 0
var _build_visible_signature: = false
var _hub_build_mode_signature: = false
var _state_signature_valid: = false
var _iphone_layout_active: = false


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	get_viewport().size_changed.connect(_apply_platform_safe_area)
	if OS.has_feature("android") or OS.has_feature("ios"):
		DisplayServer.orientation_changed.connect(_on_display_orientation_changed)
	_build_icon_chrome()
	_build_objective_popover()
	_build_progression_goal()
	_build_context_action()
	_build_status_toast()
	RunState.changed.connect(_refresh_progression_goal)
	_refresh_progression_goal()
	call_deferred("_apply_platform_safe_area")


func refresh_from_state(
	phase: String,
	_current_mine_id: String,
	context_label: String,
	context_enabled: bool,
	hub_build_mode: bool
) -> void :
	var gold: = int(RunState.gold)
	if not _state_signature_valid or gold != _gold_signature:
		_gold_signature = gold
		gold_value.text = str(gold)
		gold_value.tooltip_text = "%d gold" % gold
	var total: = int(RunState.cargo_count())
	if not _state_signature_valid or total != _cargo_signature:
		_cargo_signature = total
		bag_count.text = str(total)
		bag_count.visible = total > 0
		bag_button.tooltip_text = "Bag · %d items" % total
	set_context_action(context_label, context_enabled)


	var build_visible: = false
	if not _state_signature_valid or build_visible != _build_visible_signature:
		_build_visible_signature = build_visible
		build_button.visible = build_visible
	if not _state_signature_valid or hub_build_mode != _hub_build_mode_signature:
		_hub_build_mode_signature = hub_build_mode
		build_button.modulate = Color.WHITE if not hub_build_mode else Color(0.72, 1.0, 0.82, 1.0)
		build_button.tooltip_text = "Finish Hub building" if hub_build_mode else "Build in the Hub"
	_state_signature_valid = true


func set_context_action(label: String, enabled: bool) -> void :
	var label_changed: = not _context_signature_valid or label != _context_label
	var enabled_changed: = not _context_signature_valid or enabled != _context_enabled
	if not label_changed and not enabled_changed:
		return
	_context_label = label
	_context_enabled = enabled
	_context_signature_valid = true
	if label_changed:
		var caption: = _compact_context_caption(label)
		context_button.text = caption
		context_button.visible = not caption.is_empty()
		context_button.tooltip_text = label.replace("\n", " · ").capitalize()
		var upper: = caption.to_upper()
		if upper == "HOME":
			context_button.icon = MOLE_ICON
		elif upper == "SELL":
			context_button.icon = GOLD_ICON
		elif upper in ["FORGE", "UPGRADE", "POWER", "DELIVER", "LOAD", "BUILD"]:
			context_button.icon = BUILD_ICON
		elif upper in ["DESCEND", "ASCEND", "RETURN", "EXIT"]:
			context_button.icon = GUIDE_ICON
		else:
			context_button.icon = INTERACT_ICON
		context_button.add_theme_constant_override("icon_max_width", _context_icon_max_width())
	if enabled_changed:
		context_button.disabled = not enabled


func set_objective(title: String, detail: String) -> void :
	var title_changed: = not _objective_signature_valid or title != _objective_title_signature
	var detail_changed: = not _objective_signature_valid or detail != _objective_detail_signature
	if not title_changed and not detail_changed:
		return
	_objective_title_signature = title
	_objective_detail_signature = detail
	_objective_signature_valid = true
	if title_changed:
		objective_title.text = title.to_upper()
		_objective_available = not title.is_empty()
		guide_button.visible = _objective_available
		guide_button.disabled = not _objective_available
		guide_button.tooltip_text = "Current guide · %s" % title if _objective_available else "No active guide"
		if not _objective_available:
			_hide_objective()
	if detail_changed:
		objective_detail.text = detail


func set_progression_goal(goal: Dictionary) -> void:
	set_objective(String(goal.get("title", "")), String(goal.get("detail", "")))
	if progression_goal_panel == null:
		return
	progression_goal_panel.present(goal)
	var row_count: = Array(goal.get("requirements", [])).size()
	if row_count != _progression_row_count:
		_progression_row_count = row_count
		_apply_platform_safe_area()


func progression_goal_snapshot() -> Dictionary:
	return progression_goal_panel.snapshot() if progression_goal_panel != null else {}


func _refresh_progression_goal() -> void:
	# Updating the visible counts does not wait for the slower world-route timer.
	set_progression_goal(_progression_guide.goal_for_state())


func _build_progression_goal() -> void:
	progression_goal_panel = ProgressionGoalPanelScript.new()
	progression_goal_panel.name = "ProgressionGoal"
	add_child(progression_goal_panel)


func set_status(message: String) -> void :
	if _status_tween != null and _status_tween.is_valid():
		_status_tween.kill()
	status_label.text = message
	status_panel.visible = not message.is_empty()
	status_panel.modulate.a = 1.0
	if message.is_empty():
		return
	_status_tween = create_tween()
	_status_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	var reading_time: = clampf(3.8 + float(message.length()) / 28.0, 4.4, 6.8)
	_status_tween.tween_interval(reading_time)
	_status_tween.tween_property(status_panel, "modulate:a", 0.0, 0.42)
	_status_tween.tween_callback( func():
		status_panel.visible = false
		status_panel.modulate.a = 1.0
	)


func minimum_touch_targets_are_valid() -> bool:
	for button in [menu_button, guide_button, bag_button, context_button, build_button]:
		if button != null and (button.custom_minimum_size.x < 44.0 or button.custom_minimum_size.y < 44.0):
			return false
	return true


func _apply_platform_safe_area(size_override: Vector2 = Vector2.ZERO) -> void :
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var viewport_size: Vector2 = size_override if size_override != Vector2.ZERO else viewport_rect.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var insets: = Vector4.ZERO
	if size_override == Vector2.ZERO and (OS.has_feature("android") or OS.has_feature("ios")):
		var display_safe_area: Rect2i = DisplayServer.get_display_safe_area()
		if display_safe_area.has_area():
			var screen_to_canvas: Transform2D = get_viewport().get_screen_transform().affine_inverse()
			var safe_top_left: Vector2 = screen_to_canvas * Vector2(display_safe_area.position)
			var safe_bottom_right: Vector2 = screen_to_canvas * Vector2(display_safe_area.end)
			insets = Vector4(
				maxf(0.0, safe_top_left.x - viewport_rect.position.x),
				maxf(0.0, safe_top_left.y - viewport_rect.position.y),
				maxf(0.0, viewport_rect.end.x - safe_bottom_right.x),
				maxf(0.0, viewport_rect.end.y - safe_bottom_right.y),
			)
	_apply_responsive_layout(viewport_size, insets)


func apply_iphone_layout_for_test(viewport_size: Vector2) -> Dictionary:
	_apply_responsive_layout(viewport_size, Vector4.ZERO)
	var snapshot: = layout_snapshot(viewport_size)
	snapshot["icons"] = icon_size_snapshot()
	return snapshot


func layout_snapshot(viewport_size: Vector2) -> Dictionary:
	return _layout_metrics(viewport_size, Vector4.ZERO)


func minimap_layout_rect() -> Rect2:
	return _minimap_layout_rect


func onboarding_layout_rect() -> Rect2:
	return _onboarding_layout_rect


func icon_size_snapshot() -> Dictionary:
	return {
		"menu": button_icon_visual_size(menu_button),
		"guide": button_icon_visual_size(guide_button),
		"build": button_icon_visual_size(build_button),
		"bag": button_icon_visual_size(bag_button),
		"context": button_icon_visual_size(context_button),
		"menu_cap": menu_button.get_theme_constant("icon_max_width"),
		"guide_cap": guide_button.get_theme_constant("icon_max_width"),
		"build_cap": build_button.get_theme_constant("icon_max_width"),
		"bag_cap": bag_button.get_theme_constant("icon_max_width"),
		"context_cap": context_button.get_theme_constant("icon_max_width"),
		"gold": gold_icon.size,
	}


func _apply_responsive_layout(viewport_size: Vector2, native_insets: Vector4) -> void :
	var metrics: Dictionary = _layout_metrics(viewport_size, native_insets)
	_iphone_layout_active = bool(metrics.iphone)
	var touch_target: float = float(metrics.touch_target)
	_place(menu_button, Rect2(metrics.menu))
	_place(guide_button, Rect2(metrics.guide))
	_place(build_button, Rect2(metrics.build))
	_place(gold_cluster, Rect2(metrics.gold))
	_place(bag_button, Rect2(metrics.bag))
	_place(bag_count, Rect2(metrics.bag_count))
	_place(objective_chip, Rect2(metrics.objective))
	_place(progression_goal_panel, Rect2(metrics.progression_goal))
	progression_goal_panel.set_mobile_layout(bool(metrics.iphone))
	_place(context_button, Rect2(metrics.context))
	_place(status_panel, Rect2(metrics.status))
	for button in [menu_button, guide_button, build_button]:
		button.custom_minimum_size = Rect2(metrics.menu).size
	menu_button.add_theme_constant_override("icon_max_width", IPHONE_MENU_ICON_MAX if bool(metrics.iphone) else 46)
	for button in [guide_button, build_button]:
		button.add_theme_constant_override("icon_max_width", IPHONE_TOP_ICON_MAX if bool(metrics.iphone) else 42)
	bag_button.custom_minimum_size = Rect2(metrics.bag).size
	bag_button.add_theme_constant_override("icon_max_width", IPHONE_BAG_ICON_MAX if bool(metrics.iphone) else 68)
	context_button.custom_minimum_size = Rect2(metrics.context).size
	context_button.add_theme_constant_override("icon_max_width", _context_icon_max_width())
	context_button.add_theme_font_size_override("font_size", 19 if bool(metrics.iphone) else 12)
	context_button.add_theme_constant_override("h_separation", 7 if bool(metrics.iphone) else 4)
	var gold_icon_size: = IPHONE_GOLD_ICON_SIZE if bool(metrics.iphone) else 32.0
	_place(gold_icon, Rect2(4, (touch_target - gold_icon_size) * 0.5, gold_icon_size, gold_icon_size))
	_place(gold_value, Rect2(58 if bool(metrics.iphone) else 27, 0, 92 if bool(metrics.iphone) else 55, touch_target))
	gold_value.add_theme_font_size_override("font_size", 24 if bool(metrics.iphone) else 14)
	bag_count.add_theme_font_size_override("font_size", 18 if bool(metrics.iphone) else 9)
	objective_title.add_theme_font_size_override("font_size", 22 if bool(metrics.iphone) else 9)
	objective_detail.add_theme_font_size_override("font_size", 20 if bool(metrics.iphone) else 8)
	status_label.add_theme_font_size_override("font_size", 20 if bool(metrics.iphone) else 8)
	_minimap_layout_rect = Rect2(metrics.minimap)
	minimap_layout_changed.emit(_minimap_layout_rect)
	_onboarding_layout_rect = Rect2(metrics.onboarding)
	onboarding_layout_changed.emit(_onboarding_layout_rect)
	queue_redraw()


func _layout_metrics(viewport_size: Vector2, native_insets: Vector4) -> Dictionary:
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	var touch_target: = IPHONE_TOUCH_TARGET if iphone else 48.0
	var gap: = 12.0 if iphone else 8.0
	var left: = maxf(native_insets.x, 116.0 if iphone else 8.0)
	var top: = maxf(native_insets.y, 18.0 if iphone else 8.0)
	var right: = maxf(native_insets.z, 116.0 if iphone else 8.0)
	var bottom: = maxf(native_insets.w, 38.0 if iphone else 12.0)
	var top_button_size: = IPHONE_TOP_BUTTON_SIZE if iphone else touch_target
	var menu_rect: = Rect2(left, top, top_button_size, top_button_size)
	var guide_rect: = Rect2(menu_rect.end.x + gap, top, top_button_size, top_button_size)
	var build_rect: = Rect2(guide_rect.end.x + gap, top, top_button_size, top_button_size)
	var mine_size: = IPHONE_MINE_SIZE if iphone else 112.0
	var mine_right: = maxf(native_insets.z, IPHONE_MINE_RIGHT if iphone else 16.0)
	var mine_bottom: = maxf(native_insets.w, IPHONE_MINE_BOTTOM if iphone else 88.0)
	var mine_rect: = Rect2(
		viewport_size.x - mine_right - mine_size,
		viewport_size.y - mine_bottom - mine_size,
		mine_size,
		mine_size
	)
	var bag_size: = IPHONE_BAG_SIZE if iphone else 80.0
	var action_gap: = IPHONE_ACTION_GAP if iphone else 12.0
	var bag_rect: = Rect2(
		mine_rect.position.x - action_gap - bag_size,
		mine_rect.position.y + (mine_size - bag_size) * 0.5,
		bag_size,
		bag_size
	)
	var gold_width: = 150.0 if iphone else 82.0
	var gold_rect: = Rect2(viewport_size.x - right - gold_width, top, gold_width, touch_target)
	var badge_size: = Vector2(42, 30) if iphone else Vector2(27, 20)
	var bag_count_rect: = Rect2(bag_rect.end.x - badge_size.x + 4, bag_rect.end.y - badge_size.y + 3, badge_size.x, badge_size.y)
	var objective_width: = 660.0 if iphone else 620.0
	var objective_height: = touch_target if iphone else 54.0
	var objective_top: = top if iphone else 62.0
	var objective_rect: = Rect2((viewport_size.x - objective_width) * 0.5, objective_top, objective_width, objective_height)



	var context_size: = IPHONE_CONTEXT_SIZE if iphone else DEFAULT_CONTEXT_SIZE
	var context_rect: = Rect2(
		mine_rect.end.x - context_size.x,
		mine_rect.position.y - action_gap - context_size.y,
		context_size.x,
		context_size.y
	)
	var goal_width: = 340.0 if iphone else 286.0
	var goal_height: = (76.0 + 33.0 * _progression_row_count) if iphone else (62.0 + 27.0 * _progression_row_count)
	if iphone and _progression_row_count >= 5:
		goal_height -= 27.0
	var progression_rect: = Rect2(viewport_size.x - right - goal_width, gold_rect.end.y + 10.0, goal_width, goal_height)
	var minimap_size: = Vector2(246, 136) if iphone else Vector2(184, 106)
	var minimap_rect: = Rect2(progression_rect.position.x - gap - minimap_size.x, progression_rect.position.y, minimap_size.x, minimap_size.y)
	var onboarding_top: = maxf(progression_rect.end.y, minimap_rect.end.y) + 12.0
	var onboarding_bottom: = minf(mine_rect.position.y, bag_rect.position.y) - 12.0
	var onboarding_rect: = Rect2(left, onboarding_top, context_rect.position.x - left - 12.0, maxf(0.0, onboarding_bottom - onboarding_top))
	var status_size: = Vector2(680, 50) if iphone else Vector2(580, 28)
	var status_rect: = Rect2((viewport_size.x - status_size.x) * 0.5, viewport_size.y - bottom - status_size.y, status_size.x, status_size.y)
	return {
		"iphone": iphone,
		"touch_target": touch_target,
		"safe_rect": Rect2(left, top, viewport_size.x - left - right, viewport_size.y - top - bottom),
		"menu": menu_rect,
		"guide": guide_rect,
		"build": build_rect,
		"gold": gold_rect,
		"mine": mine_rect,
		"bag": bag_rect,
		"bag_count": bag_count_rect,
		"objective": objective_rect,
		"progression_goal": progression_rect,
		"minimap": minimap_rect,
		"onboarding": onboarding_rect,
		"context": context_rect,
		"status": status_rect,
	}


func _place(control: Control, rect: Rect2) -> void :
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


func button_icon_visual_size(button: Button) -> Vector2:
	if button == null or button.icon == null:
		return Vector2.ZERO
	var texture_size: = Vector2(button.icon.get_size())
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ZERO
	var image: Image = button.icon.get_image()
	if image == null or image.is_empty():
		return Vector2.ZERO
	var used: Rect2i = image.get_used_rect()
	if not used.has_area():
		return Vector2.ZERO
	var max_width: = float(button.get_theme_constant("icon_max_width"))
	var scale_factor: = minf(max_width / texture_size.x, button.size.y / texture_size.y)
	return Vector2(used.size) * scale_factor


func _context_icon_max_width() -> int:
	if not _iphone_layout_active:
		return 68
	var upper: = _compact_context_caption(_context_label).to_upper()
	if upper == "HOME":
		return IPHONE_CONTEXT_GUIDE_ICON_MAX
	if upper == "SELL":
		return IPHONE_CONTEXT_GOLD_ICON_MAX
	if upper in ["FORGE", "UPGRADE", "POWER", "DELIVER", "LOAD", "BUILD"]:
		return IPHONE_CONTEXT_BUILD_ICON_MAX
	if upper in ["DESCEND", "ASCEND", "RETURN", "EXIT"]:
		return IPHONE_CONTEXT_GUIDE_ICON_MAX
	return IPHONE_SECONDARY_ICON_MAX


func _on_display_orientation_changed(_orientation: int) -> void :
	call_deferred("_apply_platform_safe_area")


func _build_icon_chrome() -> void :
	menu_button = _icon_button("MenuButton", MENU_ICON, "Menu")
	menu_button.offset_left = 8.0
	menu_button.offset_top = 8.0
	menu_button.offset_right = 56.0
	menu_button.offset_bottom = 56.0
	menu_button.pressed.connect( func(): menu_requested.emit())
	add_child(menu_button)

	guide_button = _icon_button("GuideButton", GUIDE_ICON, "Current guide")
	guide_button.offset_left = 64.0
	guide_button.offset_top = 8.0
	guide_button.offset_right = 112.0
	guide_button.offset_bottom = 56.0
	guide_button.pressed.connect(_toggle_objective)
	guide_button.visible = false
	add_child(guide_button)

	build_button = _icon_button("HubBuild", BUILD_ICON, "Build in the Hub")
	build_button.offset_left = 120.0
	build_button.offset_top = 8.0
	build_button.offset_right = 168.0
	build_button.offset_bottom = 56.0
	build_button.pressed.connect( func(): hub_build_requested.emit())
	build_button.visible = false
	add_child(build_button)

	gold_cluster = Control.new()
	gold_cluster.name = "GoldCluster"
	gold_cluster.anchor_left = 1.0
	gold_cluster.anchor_right = 1.0
	gold_cluster.offset_left = -146.0
	gold_cluster.offset_top = 8.0
	gold_cluster.offset_right = -64.0
	gold_cluster.offset_bottom = 56.0
	gold_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(gold_cluster)
	gold_icon = TextureRect.new()
	gold_icon.name = "GoldIcon"
	gold_icon.offset_top = 8.0
	gold_icon.offset_right = 34.0
	gold_icon.offset_bottom = 40.0
	gold_icon.texture = GOLD_ICON
	gold_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gold_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	gold_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gold_cluster.add_child(gold_icon)
	gold_value = _label("0", 14, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_RIGHT)
	gold_value.name = "GoldValue"
	gold_value.offset_left = 27.0
	gold_value.offset_right = 82.0
	gold_value.offset_bottom = 48.0
	_add_text_shadow(gold_value)
	gold_cluster.add_child(gold_value)

	bag_button = _icon_button("BagButton", BAG_ICON, "Bag")
	bag_button.anchor_left = 1.0
	bag_button.anchor_right = 1.0
	bag_button.offset_left = -56.0
	bag_button.offset_top = 8.0
	bag_button.offset_right = -8.0
	bag_button.offset_bottom = 56.0
	bag_button.pressed.connect( func(): bag_requested.emit())
	add_child(bag_button)
	bag_count = _label("0", 9, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_CENTER)
	bag_count.name = "BagCount"
	bag_count.anchor_left = 1.0
	bag_count.anchor_right = 1.0
	bag_count.offset_left = -32.0
	bag_count.offset_top = 37.0
	bag_count.offset_right = -5.0
	bag_count.offset_bottom = 57.0
	_add_text_shadow(bag_count)
	add_child(bag_count)


func _build_objective_popover() -> void :
	objective_chip = PanelContainer.new()
	objective_chip.name = "ObjectivePopover"
	objective_chip.anchor_left = 0.5
	objective_chip.anchor_right = 0.5
	objective_chip.offset_left = -310.0
	objective_chip.offset_top = 62.0
	objective_chip.offset_right = 310.0
	objective_chip.offset_bottom = 116.0
	objective_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_chip.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.055, 0.035, 0.86), Color(0, 0, 0, 0), 11, 0, 8))
	add_child(objective_chip)
	var copy: = VBoxContainer.new()
	copy.add_theme_constant_override("separation", 0)
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_chip.add_child(copy)
	objective_title = _label("", 9, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	objective_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(objective_title)
	objective_detail = _label("", 8, MINT, HORIZONTAL_ALIGNMENT_LEFT)
	objective_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(objective_detail)
	objective_chip.visible = false


func _build_context_action() -> void :
	context_button = Button.new()
	context_button.name = "ContextAction"
	context_button.anchor_left = 1.0
	context_button.anchor_top = 1.0
	context_button.anchor_right = 1.0
	context_button.anchor_bottom = 1.0
	context_button.offset_left = -102.0
	context_button.offset_top = -258.0
	context_button.offset_right = -12.0
	context_button.offset_bottom = -198.0
	context_button.custom_minimum_size = Vector2(90, 60)
	context_button.expand_icon = true
	context_button.add_theme_constant_override("icon_max_width", 34)
	context_button.add_theme_constant_override("h_separation", 2)
	context_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	context_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	context_button.clip_text = true
	_style_context_button(context_button)
	context_button.pressed.connect( func(): context_requested.emit())
	context_button.visible = false
	add_child(context_button)


func _build_status_toast() -> void :
	status_panel = PanelContainer.new()
	status_panel.name = "StatusToast"
	status_panel.anchor_left = 0.5
	status_panel.anchor_top = 1.0
	status_panel.anchor_right = 0.5
	status_panel.anchor_bottom = 1.0
	status_panel.offset_left = -290.0
	status_panel.offset_top = -304.0
	status_panel.offset_right = 290.0
	status_panel.offset_bottom = -276.0
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(status_panel)
	status_label = _label("", 9, Color("f2e7bd"), HORIZONTAL_ALIGNMENT_CENTER)
	status_label.add_theme_color_override("font_outline_color", Color(0.01, 0.018, 0.013, 0.94))
	status_label.add_theme_constant_override("outline_size", 7)
	status_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status_panel.add_child(status_label)
	status_panel.visible = false


func _toggle_objective() -> void :
	if not _objective_available:
		return
	if _objective_open:
		_hide_objective()
		return
	_objective_open = true
	objective_chip.visible = true
	objective_chip.modulate.a = 0.0
	if _objective_tween != null and _objective_tween.is_valid():
		_objective_tween.kill()
	_objective_tween = create_tween()
	_objective_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_objective_tween.tween_property(objective_chip, "modulate:a", 1.0, 0.14)
	_objective_tween.tween_interval(4.4)
	_objective_tween.tween_property(objective_chip, "modulate:a", 0.0, 0.22)
	_objective_tween.tween_callback( func():
		objective_chip.visible = false
		objective_chip.modulate.a = 1.0
		_objective_open = false
	)


func _hide_objective() -> void :
	if _objective_tween != null and _objective_tween.is_valid():
		_objective_tween.kill()
	_objective_open = false
	objective_chip.visible = false
	objective_chip.modulate.a = 1.0


func _compact_context_caption(label: String) -> String:
	var caption: = label.get_slice("\n", 0).strip_edges().to_upper()
	return {
		"SELL ORE": "SELL",
		"LOAD ORE": "LOAD",
		"SEALED": "LOCKED",
		"ATTACH ROPE": "ATTACH",
		"TUNNEL HOME": "HOME",
		"OVERLOAD": "BOOST",
		"STABILIZE": "STEADY",
		"CUSTOMIZE": "CUSTOM",
	}.get(caption, caption)


func _icon_button(node_name: String, texture: Texture2D, tooltip: String) -> Button:
	var button: = Button.new()
	button.name = node_name
	button.custom_minimum_size = Vector2(48, 48)
	button.text = ""
	button.icon = texture
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", 42)
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	_style_icon_button(button)
	return button


func _style_icon_button(button: Button) -> void :
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	button.add_theme_color_override("icon_normal_color", Color.WHITE)
	button.add_theme_color_override("icon_hover_color", Color(1.08, 1.08, 1.08, 1.0))
	button.add_theme_color_override("icon_pressed_color", Color(0.78, 0.9, 0.8, 0.82))
	button.add_theme_color_override("icon_disabled_color", Color(0.46, 0.5, 0.47, 0.58))


func _style_context_button(button: Button) -> void :
	button.focus_mode = Control.FOCUS_NONE
	_style_icon_button(button)
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.018, 0.065, 0.043, 0.9), Color(0.72, 0.58, 0.27, 0.82), 18, 1, 8))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.055, 0.14, 0.085, 0.96), Color(0.94, 0.76, 0.37, 0.96), 18, 2, 8))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.15, 0.18, 0.075, 0.98), Color(1.0, 0.84, 0.48, 1.0), 18, 2, 8))
	button.add_theme_stylebox_override("disabled", _panel_style(Color(0.018, 0.035, 0.028, 0.72), Color(0.33, 0.35, 0.3, 0.62), 18, 1, 8))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", GOLD_BRIGHT)
	button.add_theme_color_override("font_hover_color", Color("fff0c4"))
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.56, 0.58, 0.52, 0.72))
	button.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.013, 0.94))
	button.add_theme_constant_override("outline_size", 5)


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_text_shadow(label: Label) -> void :
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_constant_override("shadow_outline_size", 4)


func _panel_style(fill: Color, border: Color, radius: int, width: int, margin: int) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
