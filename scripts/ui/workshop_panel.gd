class_name WorkshopPanel
extends Control

signal closed
signal action_confirmed(action: String, value: String)
signal preview_changed(action: String, value: String)

const MIN_TOUCH_TARGET: = 52.0
const PANEL_MAX_SIZE: = Vector2(680, 310)
const GOLD: = Color("e5bf69")
const INK: = Color("10151b")

var backdrop: Button
var frame: PanelContainer
var title_label: Label
var detail_label: Label
var equipment_label: Label
var equipment_row: HBoxContainer
var style_label: Label
var style_row: HBoxContainer
var upgrade_button: Button
var equip_button: Button
var style_button: Button
var cancel_button: Button

var _config: Dictionary = {}
var _selected_equipment: = ""
var _selected_style: = ""


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 70
	_build_panel()
	get_viewport().size_changed.connect(_apply_layout)
	visible = false
	call_deferred("_apply_layout")


func open_workshop(config: Dictionary) -> void :
	_config = config.duplicate(true)
	_selected_equipment = String(_config.get("equipment_current", ""))
	_selected_style = String(_config.get("style_current", ""))
	_refresh_contents()
	visible = true
	cancel_button.grab_focus()


func refresh_workshop(config: Dictionary) -> void :
	var keep_equipment: = _selected_equipment
	var keep_style: = _selected_style
	_config = config.duplicate(true)
	var equipment_options: Array = Array(_config.get("equipment_options", []))
	var style_options: Array = Array(_config.get("style_options", []))
	_selected_equipment = keep_equipment if keep_equipment in equipment_options else String(_config.get("equipment_current", ""))
	_selected_style = keep_style if keep_style in style_options else String(_config.get("style_current", ""))
	_refresh_contents()


func close_workshop() -> void :
	if not visible:
		return
	visible = false
	_config.clear()
	_selected_equipment = ""
	_selected_style = ""
	closed.emit()


func is_open() -> bool:
	return visible


func select_preview(category: String, value: String) -> bool:
	var key: = "equipment_options" if category == "equip" else "style_options" if category == "style" else ""
	if not visible or key.is_empty() or value not in Array(_config.get(key, [])):
		return false
	_select_option(category, value)
	return true


func interaction_snapshot() -> Dictionary:
	var touch_targets_valid: = true
	for button in [upgrade_button, equip_button, style_button, cancel_button]:
		if button != null and button.custom_minimum_size.y < 44.0:
			touch_targets_valid = false
	for row in [equipment_row, style_row]:
		if row == null:
			continue
		for child in row.get_children():
			if child is Button and (child as Button).custom_minimum_size.y < 44.0:
				touch_targets_valid = false
	return {
		"open": visible,
		"workshop_id": String(_config.get("workshop_id", "")),
		"selected_equipment": _selected_equipment,
		"selected_style": _selected_style,
		"touch_targets_valid": touch_targets_valid,
		"panel_size": frame.size if frame != null else Vector2.ZERO,
		"iphone_layout": layout_metrics(Vector2(932, 430)),
	}


func layout_metrics(viewport_size: Vector2) -> Dictionary:
	var wide_safe_margin: = 164.0 if viewport_size.x / maxf(1.0, viewport_size.y) >= 1.9 else 32.0
	var panel_size: = Vector2(
		minf(PANEL_MAX_SIZE.x, maxf(520.0, viewport_size.x - wide_safe_margin)),
		minf(PANEL_MAX_SIZE.y, maxf(260.0, viewport_size.y - 24.0))
	)
	return {
		"viewport": viewport_size,
		"safe_margin": wide_safe_margin,
		"panel_size": panel_size,
		"fits_safe_width": panel_size.x <= viewport_size.x - wide_safe_margin,
		"fits_height": panel_size.y <= viewport_size.y - 24.0,
	}


func _build_panel() -> void :
	backdrop = Button.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.focus_mode = Control.FOCUS_NONE
	backdrop.mouse_default_cursor_shape = Control.CURSOR_ARROW
	backdrop.add_theme_stylebox_override("normal", _flat_style(Color(0.01, 0.015, 0.022, 0.32), 0))
	backdrop.add_theme_stylebox_override("hover", _flat_style(Color(0.01, 0.015, 0.022, 0.32), 0))
	backdrop.add_theme_stylebox_override("pressed", _flat_style(Color(0.01, 0.015, 0.022, 0.38), 0))
	backdrop.pressed.connect(close_workshop)
	add_child(backdrop)

	var center: = CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	frame = PanelContainer.new()
	frame.name = "WorkshopFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(frame)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	frame.add_child(margin)

	var body: = VBoxContainer.new()
	body.add_theme_constant_override("separation", 8)
	margin.add_child(body)

	var header: = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	body.add_child(header)
	title_label = Label.new()
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_color_override("font_color", GOLD)
	title_label.add_theme_font_size_override("font_size", 20)
	header.add_child(title_label)
	detail_label = Label.new()
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_label.add_theme_color_override("font_color", Color("c7d2d6"))
	detail_label.add_theme_font_size_override("font_size", 14)
	header.add_child(detail_label)

	equipment_label = _section_label("EQUIPMENT · SELECT A PREVIEW")
	body.add_child(equipment_label)
	equipment_row = HBoxContainer.new()
	equipment_row.add_theme_constant_override("separation", 6)
	body.add_child(equipment_row)

	style_label = _section_label("STATION FINISH · SELECT A PREVIEW")
	body.add_child(style_label)
	style_row = HBoxContainer.new()
	style_row.add_theme_constant_override("separation", 6)
	body.add_child(style_row)

	var footer: = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 8)
	body.add_child(footer)
	upgrade_button = _action_button("UPGRADE")
	equip_button = _action_button("EQUIP SELECTED")
	style_button = _action_button("APPLY FINISH")
	cancel_button = _action_button("CANCEL")
	footer.add_child(upgrade_button)
	footer.add_child(equip_button)
	footer.add_child(style_button)
	footer.add_child(cancel_button)
	upgrade_button.pressed.connect( func(): action_confirmed.emit("upgrade", ""))
	equip_button.pressed.connect( func(): action_confirmed.emit("equip", _selected_equipment))
	style_button.pressed.connect( func(): action_confirmed.emit("style", _selected_style))
	cancel_button.pressed.connect(close_workshop)


func _refresh_contents() -> void :
	var title: = String(_config.get("title", "WORKSHOP"))
	var level: = int(_config.get("level", 1))
	var max_level: = int(_config.get("max_level", 1))
	title_label.text = "%s · LEVEL %d" % [title.to_upper(), level]
	detail_label.text = String(_config.get("detail", "Changes are previewed before they are applied"))

	var equipment_options: Array = Array(_config.get("equipment_options", []))
	_rebuild_option_row(equipment_row, equipment_options, _selected_equipment, "equip")
	equipment_label.visible = not equipment_options.is_empty()
	equipment_row.visible = not equipment_options.is_empty()
	equip_button.visible = equipment_options.size() > 1
	equip_button.disabled = (
		_selected_equipment.is_empty()
		or _selected_equipment == String(_config.get("equipment_current", ""))
	)
	equip_button.text = "EQUIP %s" % _selected_equipment.replace("_", " ").to_upper() if not _selected_equipment.is_empty() else "EQUIP SELECTED"

	var style_options: Array = Array(_config.get("style_options", []))
	_rebuild_option_row(style_row, style_options, _selected_style, "style")
	style_label.visible = not style_options.is_empty()
	style_row.visible = not style_options.is_empty()
	style_button.visible = style_options.size() > 1
	style_button.disabled = (
		_selected_style.is_empty()
		or _selected_style == String(_config.get("style_current", ""))
	)
	style_button.text = "APPLY %s" % _selected_style.replace("_", " ").to_upper() if not _selected_style.is_empty() else "APPLY FINISH"

	var upgrade: Dictionary = Dictionary(_config.get("upgrade", {}))
	upgrade_button.visible = not upgrade.is_empty() and level < max_level
	upgrade_button.disabled = not bool(_config.get("upgrade_ready", false))
	if upgrade_button.visible:
		upgrade_button.text = "UPGRADE L%d · %d %s" % [
			int(upgrade.get("level", level + 1)),
			int(upgrade.get("cost", 0)),
			String(upgrade.get("resource_name", upgrade.get("resource", "MATERIAL"))).replace("_", " ").to_upper(),
		]


func _rebuild_option_row(row: HBoxContainer, options: Array, selected: String, category: String) -> void :
	for child in row.get_children():
		row.remove_child(child)
		child.queue_free()
	var current_key: = "equipment_current" if category == "equip" else "style_current"
	var current: = String(_config.get(current_key, ""))
	for option_value in options:
		var option: = String(option_value)
		var button: = Button.new()
		button.custom_minimum_size = Vector2(0, MIN_TOUCH_TARGET)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.focus_mode = Control.FOCUS_ALL
		button.text = ("PREVIEW · " if option == selected and option != current else "EQUIPPED · " if option == current else "") + option.replace("_", " ").to_upper()
		button.add_theme_font_size_override("font_size", 13)
		button.add_theme_stylebox_override("normal", _option_style(option == selected, false))
		button.add_theme_stylebox_override("hover", _option_style(true, false))
		button.add_theme_stylebox_override("pressed", _option_style(true, true))
		button.add_theme_stylebox_override("focus", _option_style(true, false))
		button.pressed.connect(_select_option.bind(category, option))
		row.add_child(button)


func _select_option(category: String, value: String) -> void :
	if category == "equip":
		_selected_equipment = value
	else:
		_selected_style = value
	preview_changed.emit(category, value)
	_refresh_contents()


func _apply_layout() -> void :
	if frame == null:
		return
	var viewport_size: = get_viewport_rect().size
	frame.custom_minimum_size = Vector2(Dictionary(layout_metrics(viewport_size)).panel_size)


func _unhandled_input(event: InputEvent) -> void :
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_workshop()


func _section_label(text: String) -> Label:
	var label: = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("8fa6ad"))
	label.add_theme_font_size_override("font_size", 12)
	return label


func _action_button(text: String) -> Button:
	var button: = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, MIN_TOUCH_TARGET)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_stylebox_override("normal", _flat_style(Color("243039"), 10))
	button.add_theme_stylebox_override("hover", _flat_style(Color("35474d"), 10))
	button.add_theme_stylebox_override("pressed", _flat_style(Color("4c5d54"), 10))
	button.add_theme_stylebox_override("disabled", _flat_style(Color(0.08, 0.1, 0.12, 0.72), 10))
	return button


func _option_style(selected: bool, pressed: bool) -> StyleBoxFlat:
	var color: = Color("5b5236") if selected else Color("1b252d")
	if pressed:
		color = Color("77683d")
	var style: = _flat_style(color, 9)
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = GOLD if selected else Color("40515a")
	return style


func _panel_style() -> StyleBoxFlat:
	var style: = _flat_style(Color(0.035, 0.055, 0.067, 0.97), 16)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(GOLD, 0.72)
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 12
	return style


func _flat_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 5.0
	style.content_margin_bottom = 5.0
	return style
