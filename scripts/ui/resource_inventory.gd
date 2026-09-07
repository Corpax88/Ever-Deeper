class_name ResourceInventory
extends Control

signal close_requested
signal auto_sort_requested

const DropVisuals = preload("res://scripts/world/drop_visuals.gd")
const GOLD: = Color("d7b45a")
const GOLD_BRIGHT: = Color("ffe3a0")
const MINT: = Color("a8e3bc")
const MUTED: = Color("789384")
const CARD: = Color("0c2117")
const IPHONE_LANDSCAPE_ASPECT: = 1.95

var item_grid: GridContainer
var summary_label: Label
var auto_sort_button: Button
var empty_label: Label
var equipped_icon: TextureRect
var equipped_name: Label
var equipped_stats: Label
var inventory_card: PanelContainer
var close_button: Button
var _cargo: Dictionary = {}
var _protected: Dictionary = {}


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 130
	_build_interface()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")
	visible = false


func open_inventory(cargo: Dictionary, protected: Dictionary, auto_sort_enabled: bool) -> void :
	visible = true
	_refresh(cargo, protected, auto_sort_enabled)
	var close_button: = get_node("Card/Layout/Header/Close") as Button
	close_button.grab_focus()


func refresh_contents(cargo: Dictionary, protected: Dictionary, auto_sort_enabled: bool) -> void :
	_refresh(cargo, protected, auto_sort_enabled)


func close_inventory() -> void :
	visible = false


func _unhandled_key_input(event: InputEvent) -> void :
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_requested.emit()


func _build_interface() -> void :
	var shade: = ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.035, 0.024, 0.91)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	inventory_card = PanelContainer.new()
	var card: = inventory_card
	card.name = "Card"
	card.anchor_left = 0.035
	card.anchor_top = 0.07
	card.anchor_right = 0.965
	card.anchor_bottom = 0.965
	card.offset_left = 0.0
	card.offset_top = 0.0
	card.offset_right = 0.0
	card.offset_bottom = 0.0
	card.add_theme_stylebox_override("panel", _panel_style(Color("07150e"), GOLD, 18, 2, 14))
	add_child(card)

	var layout: = VBoxContainer.new()
	layout.name = "Layout"
	layout.add_theme_constant_override("separation", 10)
	card.add_child(layout)

	var header: = HBoxContainer.new()
	header.name = "Header"
	header.custom_minimum_size.y = 56
	header.add_theme_constant_override("separation", 8)
	layout.add_child(header)

	var titles: = VBoxContainer.new()
	titles.name = "Titles"
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.add_theme_constant_override("separation", 0)
	header.add_child(titles)
	var title: = _label("MINER'S BAG", 21, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	title.name = "Title"
	title.custom_minimum_size.y = 31
	titles.add_child(title)
	var kicker: = _label("EXPEDITION INVENTORY", 11, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	kicker.name = "Kicker"
	titles.add_child(kicker)

	close_button = _button("CLOSE", false)
	close_button.name = "Close"
	close_button.custom_minimum_size = Vector2(82, 48)
	close_button.pressed.connect( func(): close_requested.emit())
	header.add_child(close_button)

	var rule: = ColorRect.new()
	rule.custom_minimum_size.y = 1
	rule.color = Color(GOLD, 0.34)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout.add_child(rule)

	var equipped_card: = PanelContainer.new()
	equipped_card.name = "EquippedTool"
	equipped_card.custom_minimum_size.y = 86
	equipped_card.add_theme_stylebox_override("panel", _panel_style(Color(0.02, 0.075, 0.048, 0.78), Color(GOLD, 0.24), 12, 1, 7))
	layout.add_child(equipped_card)
	var equipped_row: = HBoxContainer.new()
	equipped_row.name = "Row"
	equipped_row.add_theme_constant_override("separation", 9)
	equipped_card.add_child(equipped_row)
	equipped_icon = TextureRect.new()
	equipped_icon.name = "EquippedSprite"
	equipped_icon.custom_minimum_size = Vector2(104, 70)
	equipped_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	equipped_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	equipped_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	equipped_row.add_child(equipped_icon)
	var equipped_copy: = VBoxContainer.new()
	equipped_copy.name = "EquippedCopy"
	equipped_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_copy.add_theme_constant_override("separation", 1)
	equipped_row.add_child(equipped_copy)
	var equipped_kicker: = _label("EQUIPPED", 11, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	equipped_kicker.name = "Kicker"
	equipped_copy.add_child(equipped_kicker)
	equipped_name = _label("WORN PICKAXE", 13, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	equipped_name.name = "EquippedName"
	equipped_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	equipped_copy.add_child(equipped_name)
	equipped_stats = _label("POWER 4  ·  1.4 HITS/SEC", 11, MINT, HORIZONTAL_ALIGNMENT_LEFT)
	equipped_stats.name = "EquippedStats"
	equipped_stats.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	equipped_copy.add_child(equipped_stats)

	var summary_row: = HBoxContainer.new()
	summary_row.custom_minimum_size.y = 50
	summary_row.add_theme_constant_override("separation", 8)
	layout.add_child(summary_row)
	summary_label = _label("POUCH EMPTY", 10, MINT, HORIZONTAL_ALIGNMENT_LEFT)
	summary_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_row.add_child(summary_label)
	auto_sort_button = _button("AUTO-SORT", true)
	auto_sort_button.custom_minimum_size = Vector2(118, 46)
	auto_sort_button.tooltip_text = "Move non-protected materials into a nearby Hub storage chest"
	auto_sort_button.pressed.connect( func(): auto_sort_requested.emit())
	summary_row.add_child(auto_sort_button)

	var protected_note: = _label("GOLD MARKS MATERIALS RESERVED FOR YOUR NEXT UPGRADE", 11, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	protected_note.name = "ProtectedNote"
	protected_note.custom_minimum_size.y = 28
	protected_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(protected_note)

	var scroll: = preload("res://scripts/ui/touch_scroll_container.gd").new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)

	var content: = MarginContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("margin_right", 5)
	scroll.add_child(content)
	item_grid = GridContainer.new()
	item_grid.name = "Items"
	item_grid.columns = 4
	item_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_grid.add_theme_constant_override("h_separation", 8)
	item_grid.add_theme_constant_override("v_separation", 8)
	content.add_child(item_grid)

	empty_label = _label("Your bag is ready for the first haul.", 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	empty_label.name = "Empty"
	empty_label.custom_minimum_size = Vector2(320, 180)
	empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_grid.add_child(empty_label)

	var footer: = _label("Resources stay in your pouch until sold, forged, or stored.", 11, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	footer.name = "Footer"
	footer.custom_minimum_size.y = 32
	footer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(footer)


func _apply_responsive_layout(size_override: Vector2 = Vector2.ZERO) -> void :
	if inventory_card == null:
		return
	var viewport_size: Vector2 = size_override if size_override != Vector2.ZERO else get_viewport().get_visible_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var iphone: = viewport_size.x / viewport_size.y >= IPHONE_LANDSCAPE_ASPECT
	var layout: VBoxContainer = inventory_card.get_node("Layout") as VBoxContainer
	var header: HBoxContainer = inventory_card.get_node("Layout/Header") as HBoxContainer
	var equipped_card: PanelContainer = inventory_card.get_node("Layout/EquippedTool") as PanelContainer
	var summary_row: HBoxContainer = summary_label.get_parent() as HBoxContainer
	var protected_note: Label = inventory_card.get_node("Layout/ProtectedNote") as Label
	var footer: Label = inventory_card.get_node("Layout/Footer") as Label
	var title: Label = inventory_card.get_node("Layout/Header/Titles/Title") as Label
	var kicker: Label = inventory_card.get_node("Layout/Header/Titles/Kicker") as Label
	var equipped_kicker: Label = inventory_card.get_node("Layout/EquippedTool/Row/EquippedCopy/Kicker") as Label
	if iphone:
		_place(inventory_card, Rect2(118, 24, viewport_size.x - 236, viewport_size.y - 48))
		layout.add_theme_constant_override("separation", 8)
		header.custom_minimum_size.y = 76
		close_button.custom_minimum_size = Vector2(132, 86)
		equipped_card.custom_minimum_size.y = 102
		equipped_icon.custom_minimum_size = Vector2(130, 84)
		summary_row.custom_minimum_size.y = 74
		auto_sort_button.custom_minimum_size = Vector2(176, 82)
		protected_note.custom_minimum_size.y = 38
		footer.custom_minimum_size.y = 40
		title.add_theme_font_size_override("font_size", 29)
		kicker.add_theme_font_size_override("font_size", 17)
		close_button.add_theme_font_size_override("font_size", 19)
		equipped_kicker.add_theme_font_size_override("font_size", 17)
		equipped_name.add_theme_font_size_override("font_size", 22)
		equipped_stats.add_theme_font_size_override("font_size", 19)
		summary_label.add_theme_font_size_override("font_size", 19)
		auto_sort_button.add_theme_font_size_override("font_size", 18)
		protected_note.add_theme_font_size_override("font_size", 18)
		footer.add_theme_font_size_override("font_size", 18)
		if is_instance_valid(empty_label):
			empty_label.add_theme_font_size_override("font_size", 22)
			empty_label.custom_minimum_size = Vector2(480, 200)
	else:
		inventory_card.anchor_left = 0.035
		inventory_card.anchor_top = 0.07
		inventory_card.anchor_right = 0.965
		inventory_card.anchor_bottom = 0.965
		inventory_card.offset_left = 0.0
		inventory_card.offset_top = 0.0
		inventory_card.offset_right = 0.0
		inventory_card.offset_bottom = 0.0
		layout.add_theme_constant_override("separation", 10)
		header.custom_minimum_size.y = 56
		close_button.custom_minimum_size = Vector2(82, 48)
		equipped_card.custom_minimum_size.y = 86
		equipped_icon.custom_minimum_size = Vector2(104, 70)
		summary_row.custom_minimum_size.y = 50
		auto_sort_button.custom_minimum_size = Vector2(118, 46)
		protected_note.custom_minimum_size.y = 28
		footer.custom_minimum_size.y = 32
		title.add_theme_font_size_override("font_size", 21)
		kicker.add_theme_font_size_override("font_size", 11)
		close_button.add_theme_font_size_override("font_size", 11)
		equipped_kicker.add_theme_font_size_override("font_size", 11)
		equipped_name.add_theme_font_size_override("font_size", 13)
		equipped_stats.add_theme_font_size_override("font_size", 11)
		summary_label.add_theme_font_size_override("font_size", 12)
		auto_sort_button.add_theme_font_size_override("font_size", 11)
		protected_note.add_theme_font_size_override("font_size", 11)
		footer.add_theme_font_size_override("font_size", 11)
		if is_instance_valid(empty_label):
			empty_label.add_theme_font_size_override("font_size", 13)
			empty_label.custom_minimum_size = Vector2(320, 180)


func apply_iphone_layout_for_test(viewport_size: Vector2) -> Dictionary:
	_apply_responsive_layout(viewport_size)
	return layout_snapshot(viewport_size)


func layout_snapshot(viewport_size: Vector2) -> Dictionary:
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	var card_rect: = Rect2(118, 24, viewport_size.x - 236, viewport_size.y - 48) if iphone else Rect2(viewport_size * Vector2(0.035, 0.07), viewport_size * Vector2(0.93, 0.895))
	return {
		"iphone": iphone,
		"safe_rect": Rect2(110, 18, viewport_size.x - 220, viewport_size.y - 36),
		"card": card_rect,
		"close_height": close_button.custom_minimum_size.y,
		"auto_sort_height": auto_sort_button.custom_minimum_size.y,
		"columns": item_grid.columns,
	}


func minimum_touch_targets_are_valid(minimum_height: float = 44.0) -> bool:
	return close_button.custom_minimum_size.y >= minimum_height and auto_sort_button.custom_minimum_size.y >= minimum_height


func _place(control: Control, rect: Rect2) -> void :
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


func _refresh(cargo: Dictionary, protected: Dictionary, auto_sort_enabled: bool) -> void :
	_cargo = cargo.duplicate(true)
	_protected = protected.duplicate(true)
	_refresh_equipped_tool()
	for child in item_grid.get_children():
		item_grid.remove_child(child)
		child.queue_free()
	var resources: Array[String] = []
	var total: = 0
	for resource_id_value in RunState.RESOURCE_IDS:
		var resource_id: = String(resource_id_value)
		var amount: = maxi(0, int(_cargo.get(resource_id, 0)))
		if amount <= 0:
			continue
		resources.append(resource_id)
		total += amount
	resources.sort_custom( func(left: String, right: String) -> bool:
		var left_rock: = Dictionary(GameData.data.ROCK_TYPES.get(left, {}))
		var right_rock: = Dictionary(GameData.data.ROCK_TYPES.get(right, {}))
		var left_protected: = int(_protected.get(left, 0)) > 0
		var right_protected: = int(_protected.get(right, 0)) > 0
		if left_protected != right_protected:
			return left_protected
		var left_value: = int(left_rock.get("value", 0))
		var right_value: = int(right_rock.get("value", 0))
		if left_value != right_value:
			return left_value > right_value
		return left < right
	)
	for resource_id in resources:
		item_grid.add_child(_resource_card(resource_id, int(_cargo.get(resource_id, 0)), int(_protected.get(resource_id, 0))))
	if resources.is_empty():
		empty_label = _label("Your bag is ready for the first haul.", 22 if _iphone_layout_active() else 13, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty_label.name = "Empty"
		empty_label.custom_minimum_size = Vector2(480, 200) if _iphone_layout_active() else Vector2(320, 180)
		empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		item_grid.add_child(empty_label)
	summary_label.text = "%d ITEMS  ·  %d RESOURCE TYPES" % [total, resources.size()]
	auto_sort_button.visible = auto_sort_enabled
	auto_sort_button.disabled = not auto_sort_enabled or resources.is_empty()


func _refresh_equipped_tool() -> void :
	var tool: = _equipped_tool_snapshot()
	equipped_name.text = String(tool.get("name", "Pickaxe")).to_upper()
	equipped_stats.text = "POWER %s  ·  %s HITS/SEC" % [
		_format_number(float(tool.get("power", 0.0))),
		_format_number(1.0 / maxf(0.001, float(tool.get("cooldown", 1.0)))),
	]
	var texture_path: = String(tool.get("texture", ""))
	equipped_icon.texture = load(texture_path) if ResourceLoader.exists(texture_path) else null


func _equipped_tool_snapshot() -> Dictionary:
	if int(RunState.drill_level) > 0:
		var drill: = Dictionary(RunState.apply_tool_forge_effects(RunState.current_drill()))
		return {
			"name": String(drill.get("name", "Drill")),
			"power": float(drill.get("power", 0.0)),
			"cooldown": float(drill.get("cooldown", 1.0)),
			"texture": "res://assets/tools/%s.png" % ["drill-burrower", "drill-pulse", "drill-deepcore"][clampi(int(RunState.drill_level) - 1, 0, 2)],
		}
	if not String(RunState.starforge_variant).is_empty():
		var variant_id: = String(RunState.starforge_variant)
		var base: = Dictionary(RunState.current_pickaxe())
		var attuned: = Dictionary(RunState.attune_tool_with_starforge(base))
		return {
			"name": String(attuned.get("name", "Starforge Pickaxe")),
			"power": float(attuned.get("power", 0.0)),
			"cooldown": float(attuned.get("cooldown", 1.0)),
			"texture": "res://assets/tools/starforge-%s.png" % variant_id,
		}
	var pickaxe: = Dictionary(RunState.apply_tool_forge_effects(RunState.current_pickaxe()))
	var level_paths: = ["pickaxe-worn", "pickaxe-worn", "pickaxe-iron", "pickaxe-runed", "pickaxe-moonglass", "pickaxe-ember"]
	return {
		"name": String(pickaxe.get("name", "Pickaxe")),
		"power": float(pickaxe.get("power", 0.0)),
		"cooldown": float(pickaxe.get("cooldown", 1.0)),
		"texture": "res://assets/tools/%s.png" % level_paths[clampi(int(RunState.pickaxe_level), 1, 5)],
	}


func _format_number(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return "%d" % roundi(value)
	return "%.1f" % value


func _resource_card(resource_id: String, amount: int, protected_amount: int) -> Control:
	var iphone: = _iphone_layout_active()
	var rock: = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
	var border: = GOLD if protected_amount > 0 else Color(String(rock.get("edge", "#4c6656")), 0.66)
	var card: = PanelContainer.new()
	card.name = "Resource_%s" % resource_id
	card.set_meta("resource_id", resource_id)
	card.custom_minimum_size = Vector2(220, 114) if iphone else Vector2(164, 92)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", _panel_style(CARD, border, 12, 2 if protected_amount > 0 else 1, 8))

	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	card.add_child(row)
	var icon: = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(78, 78) if iphone else Vector2(54, 54)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_path: = "res://assets/drops/%s-drop.png" % resource_id
	if ResourceLoader.exists(icon_path):
		var source_texture: Texture2D = load(icon_path)
		icon.texture = _optically_cropped_drop_texture(resource_id, source_texture)
	row.add_child(icon)

	var copy: = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.add_theme_constant_override("separation", 1)
	row.add_child(copy)
	var name_label: = _label(String(rock.get("label", resource_id)).to_upper(), 18 if iphone else 11, MINT, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(name_label)
	var amount_label: = _label("× %d" % amount, 27 if iphone else 18, GOLD_BRIGHT, HORIZONTAL_ALIGNMENT_LEFT)
	amount_label.name = "Amount"
	copy.add_child(amount_label)
	if protected_amount > 0:
		var badge: = _label("CRAFT %d RESERVED" % protected_amount, 15 if iphone else 10, GOLD, HORIZONTAL_ALIGNMENT_LEFT)
		badge.name = "ProtectedBadge"
		badge.tooltip_text = "This material will not be sold or auto-sorted while your next upgrade needs it."
		copy.add_child(badge)
	else:
		var value: = int(rock.get("value", 0))
		var value_label: = _label("%d GOLD EACH" % value, 15 if iphone else 10, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		copy.add_child(value_label)
	return card


func _optically_cropped_drop_texture(resource_id: String, source_texture: Texture2D) -> Texture2D:
	if source_texture == null:
		return null
	var bounds: Rect2 = DropVisuals.optical_bounds(resource_id, source_texture)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		return source_texture
	var cropped: = AtlasTexture.new()
	cropped.atlas = source_texture
	cropped.region = bounds
	cropped.filter_clip = true
	return cropped


func _button(text_value: String, primary: bool) -> Button:
	var button: = Button.new()
	button.text = text_value
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", GOLD_BRIGHT if primary else MINT)
	button.add_theme_color_override("font_disabled_color", Color("59655d"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("173523") if primary else Color("0d2518"), Color(GOLD, 0.72 if primary else 0.38), 11, 2 if primary else 1, 7))
	button.add_theme_stylebox_override("hover", _panel_style(Color("244a32"), GOLD, 11, 2, 7))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("08170f"), GOLD_BRIGHT, 11, 2, 7))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0, 0, 0, 0), GOLD_BRIGHT, 11, 2, 7))
	return button


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label: = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


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


func _iphone_layout_active() -> bool:
	var viewport_size: = get_viewport().get_visible_rect().size
	return viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
