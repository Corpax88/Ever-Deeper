class_name CommercePanel
extends Control

signal action_confirmed(item_id: String)
signal closed
signal selection_changed(item_id: String)


class ForgedChrome:
	extends Control

	var accent: = Color("e66a22")
	var premium_style: StyleBoxTexture

	func _ready() -> void :
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(false)

	func set_accent(value: Color) -> void :
		accent = value
		queue_redraw()

	func set_forge_texture(value: Texture2D) -> void :
		if value == null:
			premium_style = null
			queue_redraw()
			return
		premium_style = StyleBoxTexture.new()
		premium_style.texture = value
		var texture_size: = value.get_size()
		premium_style.region_rect = Rect2(texture_size * Vector2(0.006, 0.012), texture_size * Vector2(0.988, 0.976))
		premium_style.texture_margin_left = texture_size.x * 0.125
		premium_style.texture_margin_top = texture_size.y * 0.1875
		premium_style.texture_margin_right = texture_size.x * 0.125
		premium_style.texture_margin_bottom = texture_size.y * 0.1875
		premium_style.content_margin_left = 0.0
		premium_style.content_margin_top = 0.0
		premium_style.content_margin_right = 0.0
		premium_style.content_margin_bottom = 0.0
		premium_style.draw_center = false
		premium_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		premium_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
		queue_redraw()

	func _notification(what: int) -> void :
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void :
		if size.x < 40.0 or size.y < 40.0:
			return
		if premium_style != null:
			draw_style_box(premium_style, Rect2(Vector2.ZERO, size))
			return
		var iron_high: = Color("9a9188")
		var iron_mid: = Color("4b4848")
		var iron_dark: = Color("161619")
		var outer: = Rect2(Vector2(5, 5), size - Vector2(10, 10))
		draw_rect(outer, iron_dark, false, 8.0, true)
		draw_rect(outer.grow(-4), iron_high, false, 2.0, true)
		draw_rect(outer.grow(-10), iron_mid, false, 3.0, true)
		draw_rect(outer.grow(-15), Color(accent, 0.42), false, 1.5, true)
		var arm: = minf(58.0, size.y * 0.12)
		var p: = 17.0
		var corner_lines: Array[PackedVector2Array] = [
			PackedVector2Array([Vector2(p, p + arm), Vector2(p, p), Vector2(p + arm, p)]),
			PackedVector2Array([Vector2(size.x - p - arm, p), Vector2(size.x - p, p), Vector2(size.x - p, p + arm)]),
			PackedVector2Array([Vector2(p, size.y - p - arm), Vector2(p, size.y - p), Vector2(p + arm, size.y - p)]),
			PackedVector2Array([Vector2(size.x - p - arm, size.y - p), Vector2(size.x - p, size.y - p), Vector2(size.x - p, size.y - p - arm)]),
		]
		for line in corner_lines:
			draw_polyline(line, iron_high, 5.0, true)
			draw_polyline(line, iron_dark, 1.5, true)
		for rivet_position in [Vector2(p, p), Vector2(size.x - p, p), Vector2(p, size.y - p), Vector2(size.x - p, size.y - p)]:
			draw_circle(rivet_position, 7.0, Color("080809"), true, -1.0, true)
			draw_circle(rivet_position, 4.0, iron_mid, true, -1.0, true)
			draw_circle(rivet_position - Vector2(1.2, 1.2), 1.5, iron_high, true, -1.0, true)
		for corner in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			_draw_corner_bracket(corner, iron_dark, iron_mid, iron_high)
		var slot_half: = minf(92.0, size.x * 0.08)
		draw_line(Vector2(size.x * 0.5 - slot_half, 14), Vector2(size.x * 0.5 + slot_half, 14), Color(accent, 0.92), 4.0, true)
		draw_line(Vector2(size.x * 0.5 - slot_half * 0.65, size.y - 14), Vector2(size.x * 0.5 + slot_half * 0.65, size.y - 14), Color(accent, 0.55), 2.0, true)

	func _draw_corner_bracket(direction: Vector2, iron_dark: Color, iron_mid: Color, iron_high: Color) -> void :
		var base: PackedVector2Array = PackedVector2Array([
			Vector2(7, 7), Vector2(62, 7), Vector2(49, 20),
			Vector2(23, 20), Vector2(23, 49), Vector2(7, 64),
		])
		var points: = PackedVector2Array()
		for point in base:
			points.append(Vector2(point.x if direction.x > 0 else size.x - point.x, point.y if direction.y > 0 else size.y - point.y))
		draw_colored_polygon(points, iron_dark)
		var outline: = points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, iron_mid, 5.0, true)
		draw_polyline(outline, iron_high, 1.2, true)
		var rivet: = Vector2(18 if direction.x > 0 else size.x - 18, 18 if direction.y > 0 else size.y - 18)
		draw_circle(rivet, 6.0, Color("070708"), true, -1.0, true)
		draw_circle(rivet, 3.4, iron_mid, true, -1.0, true)


class ForgedMedallion:
	extends Control

	var accent: = Color("e66a22")
	var premium_texture: Texture2D

	func _ready() -> void :
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_accent(value: Color) -> void :
		accent = value
		queue_redraw()

	func set_forge_texture(value: Texture2D) -> void :
		premium_texture = value
		queue_redraw()

	func _notification(what: int) -> void :
		if what == NOTIFICATION_RESIZED:
			queue_redraw()

	func _draw() -> void :
		var extent: = minf(size.x, size.y)
		if extent < 40.0:
			return
		if premium_texture != null:
			var premium_rect: = Rect2((size - Vector2(extent, extent)) * 0.5, Vector2(extent, extent))
			draw_texture_rect(premium_texture, premium_rect, false)
			return
		var center: = size * 0.5
		var radius: = extent * 0.42
		draw_circle(center + Vector2(0, 8), radius + 15.0, Color(0, 0, 0, 0.68), true, -1.0, true)
		draw_circle(center, radius + 11.0, Color("111113"), true, -1.0, true)
		draw_arc(center, radius + 9.0, 0, TAU, 96, Color("958c82"), 5.0, true)
		draw_arc(center, radius + 2.0, 0, TAU, 96, Color("3c3a3b"), 5.0, true)
		draw_arc(center, radius - 3.0, 0, TAU, 96, Color(accent, 0.88), 3.0, true)
		draw_circle(center, radius - 8.0, Color("09090a"), true, -1.0, true)
		draw_circle(center, radius * 0.72, Color(accent, 0.065), true, -1.0, true)
		draw_line(center + Vector2( - radius * 0.58, radius * 0.58), center + Vector2(radius * 0.58, - radius * 0.58), Color("262427"), 10.0, true)
		draw_line(center + Vector2( - radius * 0.58, - radius * 0.58), center + Vector2(radius * 0.58, radius * 0.58), Color("1b1a1c"), 8.0, true)
		for direction in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
			var rivet_position: Vector2 = center + Vector2(direction) * (radius + 2.0)
			draw_circle(rivet_position, 7.0, Color("070708"), true, -1.0, true)
			draw_circle(rivet_position, 3.8, Color("81786f"), true, -1.0, true)


const MIN_TOUCH_TARGET: = 52.0
const IPHONE_LANDSCAPE_ASPECT: = 1.9
const IPHONE_TOUCH_TARGET: = 86.0
const IPHONE_FONT_SCALE: = 2.0
const IPHONE_PANEL_MAX_SIZE: = Vector2(1340, 650)
const IPHONE_CARD_MIN_WIDTH: = 330.0
const PANEL_MAX_SIZE: = Vector2(1120, 630)
const CARD_MIN_WIDTH: = 244.0
const DISPLAY_FONT: = preload("res://assets/ui/fonts/DejaVuSerif-Bold.ttf")
const BODY_FONT: = preload("res://assets/ui/fonts/DejaVuSans.ttf")
const MOSSVEIN_FRAME: = preload("res://assets/ui/commerce/mossvein-frame-v1.png")
const MOSSVEIN_PLATE: = preload("res://assets/ui/commerce/mossvein-plate-v1.png")
const MOSSVEIN_ACTION: = preload("res://assets/ui/commerce/mossvein-action-v1.png")
const MOSSVEIN_MEDALLION: = preload("res://assets/ui/commerce/mossvein-medallion-v1.png")

const IVORY: = Color("eee2cf")
const STEEL: = Color("b8b7b2")
const MUTED: = Color("858482")
const DANGER: = Color("d86c5f")
const INK: = Color("090a0b")
const FRAME: = Color("111214")
const SURFACE: = Color("18191b")
const SURFACE_RAISED: = Color("222326")
const CARD: = Color("1b1c1f")
const IRON_EDGE: = Color("45464a")
const IRON_MID: = Color("625d5a")
const IRON_HIGH: = Color("9a9188")
const PANEL_THEMES: = {
	"forge": {"accent": Color("e66a22"), "bright": Color("ffb25f"), "deep": Color("57230d")},
	"wayfarer": {"accent": Color("bd7240"), "bright": Color("efb47d"), "deep": Color("442719")},
	"starforge": {"accent": Color("735ba8"), "bright": Color("c2adeb"), "deep": Color("2a2046")},
	"tool_forge": {"accent": Color("b95932"), "bright": Color("e9a277"), "deep": Color("421e13")},
	"light_lab": {"accent": Color("4f86a2"), "bright": Color("a9d3e3"), "deep": Color("18313d")},
	"wardrobe": {"accent": Color("8f3d4c"), "bright": Color("d98b9b"), "deep": Color("37151e")},
	"treasure_chamber": {"accent": Color("b1782d"), "bright": Color("e8bd72"), "deep": Color("432b12")},
	"lift_workshop": {"accent": Color("8f6b4f"), "bright": Color("d0aa86"), "deep": Color("38271c")},
}

var backdrop: Button
var frame: PanelContainer
var inner_frame: PanelContainer
var safe_margin: MarginContainer
var metal_fill: ColorRect
var metal_material: ShaderMaterial
var chrome_overlay: ForgedChrome
var body: VBoxContainer
var header_plate: PanelContainer
var header: HBoxContainer
var title_plaque: PanelContainer
var close_slot: HBoxContainer
var accent_line: ColorRect
var title_label: Label
var subtitle_label: Label
var close_button: Button

var commerce_body: HBoxContainer
var catalog_pane: VBoxContainer
var page_navigation: HBoxContainer
var page_label: Label
var previous_button: Button
var next_button: Button
var catalog_scroll: ScrollContainer
var catalog_strip: HBoxContainer
var hero_well: PanelContainer
var hero_medallion: ForgedMedallion
var hero_icon: TextureRect
var hero_state_plate: PanelContainer
var hero_state_label: Label

var overview_panel: PanelContainer
var overview_scroll: ScrollContainer
var overview_content: VBoxContainer
var overview_heading: Label
var total_panel: PanelContainer
var total_label: Label
var total_value: Label

var footer: HBoxContainer
var footer_summary: Label
var footer_spacer: Control
var cancel_button: Button
var primary_button: Button

var _config: Dictionary = {}
var _items: Array = []
var _selected_item_id: = ""
var _selected_card: Button
var _layout_viewport_size: = Vector2.ZERO
var _visual_theme_id: = "forge"
var _accent: = Color("e66a22")
var _accent_bright: = Color("ffb25f")
var _accent_deep: = Color("57230d")


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 210
	_build_interface()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	visible = false
	call_deferred("_apply_responsive_layout")



func open_commerce(config: Dictionary) -> void :
	_config = config.duplicate(true)
	_items = _valid_items(Array(_config.get("items", [])))
	_selected_item_id = _initial_selection(String(_config.get("selected_item_id", "")))
	_refresh_all()
	visible = true
	_apply_responsive_layout()
	if primary_button != null and not primary_button.disabled:
		primary_button.grab_focus()
	elif cancel_button != null:
		cancel_button.grab_focus()


func refresh_commerce(config: Dictionary) -> void :
	var previous_selection: = _selected_item_id
	_config = config.duplicate(true)
	_items = _valid_items(Array(_config.get("items", [])))
	_selected_item_id = previous_selection if _has_item(previous_selection) else _initial_selection(String(_config.get("selected_item_id", "")))
	_refresh_all()
	_apply_responsive_layout()



func refresh(config: Dictionary) -> void :
	refresh_commerce(config)


func close_commerce() -> void :
	if not visible:
		return
	visible = false
	_config.clear()
	_items.clear()
	_selected_item_id = ""
	_selected_card = null
	closed.emit()


func is_open() -> bool:
	return visible


func selected_item_id() -> String:
	return _selected_item_id


func selected_item() -> Dictionary:
	return _item_by_id(_selected_item_id).duplicate(true)




func select_item(item_id: String) -> bool:
	if not visible or not _has_item(item_id):
		return false
	_select_item(item_id)
	return true


func interaction_snapshot() -> Dictionary:
	var item: = _item_by_id(_selected_item_id)
	var viewport_size: = _layout_viewport_size if _layout_viewport_size != Vector2.ZERO else get_viewport_rect().size
	var metrics: = layout_metrics(viewport_size)
	var required_touch_target: = _touch_target_for(metrics)
	return {
		"open": visible,
		"panel_id": String(_config.get("panel_id", "")),
		"visual_theme": _visual_theme_id,
		"selected_item_id": _selected_item_id,
		"item_count": _items.size(),
		"selected_locked": bool(item.get("locked", false)),
		"selected_affordable": _is_affordable(item),
		"action_enabled": primary_button != null and not primary_button.disabled,
		"touch_targets_valid": minimum_touch_targets_are_valid(required_touch_target),
		"touch_target_required": required_touch_target,
		"touch_target_rendered_minimum": _minimum_rendered_touch_target_dimension(),
		"catalog_horizontal_scroll": catalog_scroll != null and catalog_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED,
		"overview_vertical_scroll": overview_scroll != null and overview_scroll.vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED,
		"catalog_scroll_mode": catalog_scroll.horizontal_scroll_mode if catalog_scroll != null else -1,
		"overview_scroll_mode": overview_scroll.vertical_scroll_mode if overview_scroll != null else -1,
		"catalog_scroll_x": catalog_scroll.scroll_horizontal if catalog_scroll != null else 0,
		"overview_scroll_y": overview_scroll.scroll_vertical if overview_scroll != null else 0,
		"primary_rect": primary_button.get_global_rect() if primary_button != null else Rect2(),
		"cancel_rect": cancel_button.get_global_rect() if cancel_button != null else Rect2(),
		"safe_rect": Rect2(metrics.get("safe_rect", Rect2())),
		"panel_rect": Rect2(metrics.get("panel_rect", Rect2())),
		"minimum_font_size": _minimum_visible_font_size(),
		"panel_size": frame.size if frame != null else Vector2.ZERO,
	}


func layout_metrics(viewport_size: Vector2) -> Dictionary:
	var aspect: = viewport_size.x / maxf(1.0, viewport_size.y)
	var iphone_landscape: = aspect >= IPHONE_LANDSCAPE_ASPECT
	var side_margin: = 110.0 if iphone_landscape else 28.0
	var vertical_margin: = 18.0 if viewport_size.y <= 500.0 else 30.0
	var panel_max_size: = IPHONE_PANEL_MAX_SIZE if iphone_landscape else PANEL_MAX_SIZE
	var available: = Vector2(
		maxf(520.0, viewport_size.x - side_margin * 2.0),
		maxf(330.0, viewport_size.y - vertical_margin * 2.0)
	)
	var panel_size: = Vector2(
		minf(panel_max_size.x, available.x),
		minf(panel_max_size.y, available.y)
	)
	var position: = (viewport_size - panel_size) * 0.5
	return {
		"viewport": viewport_size,
		"iphone_landscape": iphone_landscape,
		"panel_rect": Rect2(position, panel_size),
		"safe_rect": Rect2(side_margin, vertical_margin, viewport_size.x - side_margin * 2.0, viewport_size.y - vertical_margin * 2.0),
		"safe_side_margin": side_margin,
		"fits_width": panel_size.x <= viewport_size.x - side_margin * 2.0 + 0.1,
		"fits_height": panel_size.y <= viewport_size.y - vertical_margin * 2.0 + 0.1,
	}


func minimum_touch_targets_are_valid(minimum_height: float = -1.0) -> bool:
	var required_height: = minimum_height
	if required_height <= 0.0:
		var viewport_size: = _layout_viewport_size if _layout_viewport_size != Vector2.ZERO else get_viewport_rect().size
		required_height = _touch_target_for(layout_metrics(viewport_size))
	for button in [close_button, previous_button, next_button, cancel_button, primary_button]:
		if button != null and (button.custom_minimum_size.x < required_height or button.custom_minimum_size.y < required_height):
			return false
	if catalog_strip != null:
		for child in catalog_strip.get_children():
			if child is Button and (child as Button).custom_minimum_size.y < required_height:
				return false
	return true


func _minimum_rendered_touch_target_dimension() -> float:
	var minimum: = INF
	for button in [close_button, previous_button, next_button, cancel_button, primary_button]:
		if button != null and button.visible:
			minimum = minf(minimum, minf(button.size.x, button.size.y))
	if catalog_strip != null:
		for child in catalog_strip.get_children():
			if child is Button and child.visible:
				minimum = minf(minimum, minf((child as Button).size.x, (child as Button).size.y))
	return 0.0 if is_inf(minimum) else minimum


func _build_interface() -> void :
	backdrop = Button.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.focus_mode = Control.FOCUS_NONE
	backdrop.mouse_default_cursor_shape = Control.CURSOR_ARROW
	backdrop.add_theme_stylebox_override("normal", _flat_style(Color(0.004, 0.004, 0.005, 0.91), 0))
	backdrop.add_theme_stylebox_override("hover", _flat_style(Color(0.004, 0.004, 0.005, 0.91), 0))
	backdrop.add_theme_stylebox_override("pressed", _flat_style(Color(0.004, 0.004, 0.005, 0.94), 0))
	backdrop.pressed.connect(_on_backdrop_pressed)
	add_child(backdrop)

	frame = PanelContainer.new()
	frame.name = "CommerceFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_STOP
	frame.add_theme_stylebox_override("panel", _frame_style())
	add_child(frame)

	metal_fill = ColorRect.new()
	metal_fill.name = "BrushedMetal"
	metal_fill.color = Color.WHITE
	metal_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	metal_material = _metal_shader_material()
	metal_fill.material = metal_material
	frame.add_child(metal_fill)

	inner_frame = PanelContainer.new()
	inner_frame.name = "InnerFrame"
	inner_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner_frame.add_theme_stylebox_override("panel", _inner_frame_style())
	frame.add_child(inner_frame)

	safe_margin = MarginContainer.new()
	safe_margin.name = "SafeMargin"
	safe_margin.add_theme_constant_override("margin_left", 25)
	safe_margin.add_theme_constant_override("margin_right", 25)
	safe_margin.add_theme_constant_override("margin_top", 23)
	safe_margin.add_theme_constant_override("margin_bottom", 22)
	inner_frame.add_child(safe_margin)

	body = VBoxContainer.new()
	body.name = "Body"
	body.add_theme_constant_override("separation", 8)
	safe_margin.add_child(body)

	_build_header()
	accent_line = ColorRect.new()
	accent_line.name = "ForgeGlow"
	accent_line.custom_minimum_size.y = 2
	accent_line.color = Color(_accent, 0.78)
	accent_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(accent_line)
	_build_commerce_body()
	_build_footer()

	chrome_overlay = ForgedChrome.new()
	chrome_overlay.name = "ForgedChrome"
	chrome_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chrome_overlay.z_index = 4
	frame.add_child(chrome_overlay)


func _build_header() -> void :
	header_plate = PanelContainer.new()
	header_plate.name = "HeaderPlate"
	header_plate.add_theme_stylebox_override("panel", _header_style())
	body.add_child(header_plate)

	header = HBoxContainer.new()
	header.name = "Header"
	header.z_index = 5
	header.custom_minimum_size.y = 64
	header.add_theme_constant_override("separation", 12)
	header_plate.add_child(header)

	var balance_spacer: = Control.new()
	balance_spacer.name = "CloseBalance"
	balance_spacer.custom_minimum_size.x = MIN_TOUCH_TARGET
	balance_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	balance_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(balance_spacer)

	title_plaque = PanelContainer.new()
	title_plaque.name = "TitlePlaque"
	title_plaque.custom_minimum_size.x = 430
	title_plaque.add_theme_stylebox_override("panel", _header_title_style())
	header.add_child(title_plaque)
	var titles: = VBoxContainer.new()
	titles.name = "Titles"
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_theme_constant_override("separation", 4)
	title_plaque.add_child(titles)
	title_label = _label("Shop", 21, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true)
	title_label.name = "Title"
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(title_label)
	subtitle_label = _label("Select an item to inspect", 10, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	subtitle_label.name = "Subtitle"
	subtitle_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	titles.add_child(subtitle_label)

	close_slot = HBoxContainer.new()
	close_slot.name = "CloseSlot"
	close_slot.custom_minimum_size.x = MIN_TOUCH_TARGET
	close_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_slot.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(close_slot)
	close_button = _button("X", false)
	close_button.name = "Close"
	close_button.custom_minimum_size = Vector2(MIN_TOUCH_TARGET, MIN_TOUCH_TARGET)
	close_button.pressed.connect(close_commerce)
	close_slot.add_child(close_button)


func _build_commerce_body() -> void :
	commerce_body = HBoxContainer.new()
	commerce_body.name = "CommerceBody"
	commerce_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	commerce_body.add_theme_constant_override("separation", 18)
	body.add_child(commerce_body)

	catalog_pane = VBoxContainer.new()
	catalog_pane.name = "Catalog"
	catalog_pane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_pane.add_theme_constant_override("separation", 6)
	commerce_body.add_child(catalog_pane)

	page_navigation = HBoxContainer.new()
	page_navigation.name = "PageNavigation"
	page_navigation.custom_minimum_size.y = MIN_TOUCH_TARGET
	page_navigation.add_theme_constant_override("separation", 6)
	catalog_pane.add_child(page_navigation)
	page_label = _label("Catalog", 11, _accent_bright, HORIZONTAL_ALIGNMENT_LEFT, true)
	page_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_navigation.add_child(page_label)
	previous_button = _button("<", false)
	previous_button.name = "Previous"
	previous_button.custom_minimum_size = Vector2(68, MIN_TOUCH_TARGET)
	previous_button.pressed.connect(_change_selection.bind(-1))
	page_navigation.add_child(previous_button)
	next_button = _button(">", false)
	next_button.name = "Next"
	next_button.custom_minimum_size = Vector2(68, MIN_TOUCH_TARGET)
	next_button.pressed.connect(_change_selection.bind(1))
	page_navigation.add_child(next_button)

	hero_well = PanelContainer.new()
	hero_well.name = "HeroWell"
	hero_well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hero_well.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hero_well.add_theme_stylebox_override("panel", _hero_well_style())
	catalog_pane.add_child(hero_well)
	var hero_center: = CenterContainer.new()
	hero_center.name = "HeroCenter"
	hero_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_well.add_child(hero_center)
	hero_medallion = ForgedMedallion.new()
	hero_medallion.name = "HeroMedallion"
	hero_medallion.custom_minimum_size = Vector2(300, 300)
	hero_medallion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_center.add_child(hero_medallion)
	hero_icon = TextureRect.new()
	hero_icon.name = "HeroIcon"
	hero_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	hero_icon.offset_left = 12
	hero_icon.offset_top = 12
	hero_icon.offset_right = -12
	hero_icon.offset_bottom = -12
	hero_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_icon.resized.connect(_update_hero_icon_pivot)
	hero_medallion.add_child(hero_icon)
	hero_state_plate = PanelContainer.new()
	hero_state_plate.name = "StatePlate"
	hero_state_plate.anchor_left = 0.25
	hero_state_plate.anchor_top = 0.8
	hero_state_plate.anchor_right = 0.75
	hero_state_plate.anchor_bottom = 0.96
	hero_state_plate.add_theme_stylebox_override("panel", _title_plate_style())
	hero_state_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_medallion.add_child(hero_state_plate)
	hero_state_label = _label("Ready", 10, _accent_bright, HORIZONTAL_ALIGNMENT_CENTER, true)
	hero_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hero_state_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hero_state_plate.add_child(hero_state_label)

	catalog_scroll = ScrollContainer.new()
	catalog_scroll.name = "CatalogScroll"
	catalog_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_scroll.custom_minimum_size.y = 96
	catalog_scroll.size_flags_vertical = Control.SIZE_SHRINK_END
	catalog_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	catalog_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	catalog_scroll.follow_focus = true
	catalog_pane.add_child(catalog_scroll)
	catalog_strip = HBoxContainer.new()
	catalog_strip.name = "ItemCards"
	catalog_strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	catalog_strip.size_flags_vertical = Control.SIZE_FILL
	catalog_strip.add_theme_constant_override("separation", 8)
	catalog_scroll.add_child(catalog_strip)

	overview_panel = PanelContainer.new()
	overview_panel.name = "Overview"
	overview_panel.custom_minimum_size.x = 410
	overview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overview_panel.add_theme_stylebox_override("panel", _overview_panel_style())
	commerce_body.add_child(overview_panel)
	var overview_layout: = VBoxContainer.new()
	overview_layout.name = "Layout"
	overview_layout.add_theme_constant_override("separation", 7)
	overview_panel.add_child(overview_layout)
	overview_heading = _label("Details", 12, _accent_bright, HORIZONTAL_ALIGNMENT_LEFT, true)
	overview_heading.name = "Heading"
	overview_heading.visible = false
	overview_layout.add_child(overview_heading)
	overview_scroll = ScrollContainer.new()
	overview_scroll.name = "DetailsScroll"
	overview_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	overview_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overview_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	overview_scroll.follow_focus = true
	overview_layout.add_child(overview_scroll)
	var overview_margin: = MarginContainer.new()
	overview_margin.name = "DetailsMargin"
	overview_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_margin.add_theme_constant_override("margin_right", 5)
	overview_scroll.add_child(overview_margin)
	overview_content = VBoxContainer.new()
	overview_content.name = "Details"
	overview_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	overview_content.add_theme_constant_override("separation", 8)
	overview_margin.add_child(overview_content)

	total_panel = PanelContainer.new()
	total_panel.name = "Total"
	total_panel.custom_minimum_size.y = MIN_TOUCH_TARGET
	total_panel.add_theme_stylebox_override("panel", _forged_plate_style(SURFACE_RAISED, Color(_accent, 0.65), 10))
	overview_layout.add_child(total_panel)
	var total_row: = HBoxContainer.new()
	total_row.add_theme_constant_override("separation", 8)
	total_panel.add_child(total_row)
	total_label = _label("Total", 11, STEEL, HORIZONTAL_ALIGNMENT_LEFT, true)
	total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	total_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_row.add_child(total_label)
	total_value = _label("-", 17, _accent_bright, HORIZONTAL_ALIGNMENT_RIGHT, true)
	total_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	total_row.add_child(total_value)


func _build_footer() -> void :
	footer = HBoxContainer.new()
	footer.name = "Footer"
	footer.z_index = 5
	footer.custom_minimum_size.y = 64
	footer.add_theme_constant_override("separation", 8)
	body.add_child(footer)
	footer_summary = _label("Select an item", 12, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	footer_summary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_summary.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer_summary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_child(footer_summary)
	footer_spacer = Control.new()
	footer_spacer.name = "ActionSpacer"
	footer_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_child(footer_spacer)
	cancel_button = _button("Cancel", false)
	cancel_button.name = "Cancel"
	cancel_button.custom_minimum_size = Vector2(132, 64)
	cancel_button.pressed.connect(close_commerce)
	footer.add_child(cancel_button)
	primary_button = _button("Select", true)
	primary_button.name = "PrimaryAction"
	primary_button.custom_minimum_size = Vector2(248, 64)
	primary_button.pressed.connect(_confirm_selected)
	footer.add_child(primary_button)


func _resolve_visual_theme() -> void :
	var panel_id: = String(_config.get("panel_id", "forge"))
	_visual_theme_id = panel_id.trim_prefix("workshop:") if panel_id.begins_with("workshop:") else panel_id
	if not PANEL_THEMES.has(_visual_theme_id):
		_visual_theme_id = "forge"
	var colors: Dictionary = Dictionary(PANEL_THEMES.get(_visual_theme_id, PANEL_THEMES.get("forge", {})))
	_accent = Color(colors.get("accent", Color("e66a22")))
	_accent_bright = Color(colors.get("bright", Color("ffb25f")))
	_accent_deep = Color(colors.get("deep", Color("57230d")))


func _apply_backdrop_style() -> void :
	var normal_alpha: = 0.74 if _visual_theme_id == "forge" else 0.91
	var pressed_alpha: = 0.79 if _visual_theme_id == "forge" else 0.94
	var normal_style: = _flat_style(Color(0.004, 0.004, 0.005, normal_alpha), 0)
	backdrop.add_theme_stylebox_override("normal", normal_style)
	backdrop.add_theme_stylebox_override("hover", normal_style)
	backdrop.add_theme_stylebox_override("pressed", _flat_style(Color(0.004, 0.004, 0.005, pressed_alpha), 0))


func _apply_visual_theme() -> void :
	_apply_backdrop_style()
	frame.add_theme_stylebox_override("panel", _frame_style())
	inner_frame.add_theme_stylebox_override("panel", _inner_frame_style())
	header_plate.add_theme_stylebox_override("panel", _header_style())
	title_plaque.add_theme_stylebox_override("panel", _header_title_style())
	accent_line.color = Color(_accent, 0.78)
	overview_panel.add_theme_stylebox_override("panel", _overview_panel_style())
	hero_well.add_theme_stylebox_override("panel", _hero_well_style())
	hero_medallion.set_accent(_accent)
	hero_medallion.set_forge_texture(MOSSVEIN_MEDALLION if _visual_theme_id == "forge" else null)
	hero_state_plate.add_theme_stylebox_override("panel", _title_plate_style())
	chrome_overlay.set_accent(_accent)
	chrome_overlay.set_forge_texture(MOSSVEIN_FRAME if _visual_theme_id == "forge" else null)
	metal_material.set_shader_parameter("accent_color", _accent)
	title_label.add_theme_color_override("font_color", IVORY)
	title_label.add_theme_color_override("font_outline_color", Color(INK, 0.9))
	title_label.add_theme_constant_override("outline_size", 2)
	subtitle_label.add_theme_color_override("font_color", MUTED)
	page_label.add_theme_color_override("font_color", _accent_bright)
	overview_heading.add_theme_color_override("font_color", _accent_bright)
	footer_summary.add_theme_color_override("font_color", MUTED)
	_style_button(close_button, false)
	_style_close_button(close_button)
	_style_button(previous_button, false)
	_style_button(next_button, false)
	_style_button(cancel_button, false)
	_style_button(primary_button, true)


func _refresh_all() -> void :
	_resolve_visual_theme()
	_apply_visual_theme()
	title_label.text = _display_text(String(_config.get("title", "Shop")))
	subtitle_label.text = _display_text(String(_config.get("subtitle", "Select an item to inspect")))
	cancel_button.text = _display_text(String(_config.get("cancel_label", "Cancel")))
	primary_button.visible = bool(_config.get("primary_action_visible", true))
	overview_heading.text = _display_text(String(_config.get("overview_title", "Details")))
	page_navigation.visible = _items.size() > 1
	catalog_scroll.visible = _items.size() > 1
	footer_summary.visible = _items.size() > 1
	footer_spacer.visible = _items.size() <= 1
	hero_state_plate.visible = _items.size() > 1
	_rebuild_cards()
	_refresh_showcase(_item_by_id(_selected_item_id))
	_refresh_overview()
	_refresh_navigation()


func _rebuild_cards() -> void :
	_selected_card = null
	for child in catalog_strip.get_children():
		catalog_strip.remove_child(child)
		child.queue_free()
	if _items.size() > 1:
		for item_value in _items:
			var item: Dictionary = item_value
			var card: = _item_card(item)
			catalog_strip.add_child(card)
			if String(item.get("id", "")) == _selected_item_id:
				_selected_card = card
	if _items.is_empty() and catalog_scroll.visible:
		var empty: = _label(_display_text(String(_config.get("empty_text", "Nothing available yet"))), 15, MUTED, HORIZONTAL_ALIGNMENT_CENTER)
		empty.custom_minimum_size = Vector2(CARD_MIN_WIDTH, 120)
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		catalog_strip.add_child(empty)
	call_deferred("_ensure_selected_visible")


func _refresh_showcase(item: Dictionary) -> void :
	if item.is_empty():
		hero_icon.texture = null
		hero_icon.rotation = 0.0
		hero_state_label.text = _display_text(String(_config.get("empty_text", "Nothing available")))
		hero_state_label.add_theme_color_override("font_color", MUTED)
		return
	hero_icon.texture = _item_texture(item)
	hero_icon.modulate = Color(1, 1, 1, 0.38) if bool(item.get("locked", false)) else Color.WHITE
	var texture_path: = String(item.get("texture", item.get("icon_path", "")))
	hero_icon.rotation = deg_to_rad(-40.0) if "/tools/" in texture_path or String(item.get("id", "")).begins_with("forge:") else 0.0
	hero_state_label.text = _state_text(item)
	hero_state_label.add_theme_color_override("font_color", _state_color(item))
	call_deferred("_update_hero_icon_pivot")


func _item_card(item: Dictionary) -> Button:
	var item_id: = String(item.get("id", ""))
	var selected: = item_id == _selected_item_id
	var button: = Button.new()
	button.name = "Item_%s" % item_id.validate_node_name()
	button.set_meta("item_id", item_id)
	button.custom_minimum_size = Vector2(150, 76)
	button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	button.size_flags_vertical = Control.SIZE_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = true
	button.tooltip_text = String(item.get("title", item_id))
	button.add_theme_stylebox_override("normal", _card_style(item, selected, false))
	button.add_theme_stylebox_override("hover", _card_style(item, true, false))
	button.add_theme_stylebox_override("pressed", _card_style(item, true, true))
	button.add_theme_stylebox_override("focus", _card_style(item, true, false))
	button.pressed.connect(_select_item.bind(item_id))

	var margin: = MarginContainer.new()
	margin.name = "Inset"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 9)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_bottom", 7)
	button.add_child(margin)
	var row: = HBoxContainer.new()
	row.name = "CardRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var icon_slot: = PanelContainer.new()
	icon_slot.name = "IconPlate"
	icon_slot.custom_minimum_size = Vector2(58, 58)
	icon_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_slot.add_theme_stylebox_override("panel", _forged_plate_style(Color("0b0b0c"), Color(_accent, 0.55), 5))
	row.add_child(icon_slot)
	var icon: = TextureRect.new()
	icon.name = "Icon"
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = _item_texture(item)
	icon.modulate = Color(1, 1, 1, 0.4) if bool(item.get("locked", false)) else Color.WHITE
	icon_slot.add_child(icon)

	var copy: = VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.alignment = BoxContainer.ALIGNMENT_CENTER
	copy.add_theme_constant_override("separation", 2)
	row.add_child(copy)
	var state: = _label(_state_text(item), 10, _state_color(item), HORIZONTAL_ALIGNMENT_LEFT, true)
	state.mouse_filter = Control.MOUSE_FILTER_IGNORE
	state.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(state)
	var item_title: = _label(_display_text(String(item.get("title", item_id))), 13, IVORY, HORIZONTAL_ALIGNMENT_LEFT, true)
	item_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(item_title)
	return button


func _refresh_overview() -> void :
	total_panel.visible = true
	for child in overview_content.get_children():
		overview_content.remove_child(child)
		child.queue_free()
	var item: = _item_by_id(_selected_item_id)
	if item.is_empty():
		var summary: = _display_text(String(_config.get("overview_text", _config.get("empty_text", "Nothing available yet"))))
		var summary_label: = _label(summary, 13, STEEL if _config.has("overview_text") else MUTED, HORIZONTAL_ALIGNMENT_LEFT)
		summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		overview_content.add_child(summary_label)
		_add_progress_overview(_config)
		_set_total("Total", "-", false)
		if _config.has("total"):
			var empty_total: Variant = _config.get("total", {})
			if empty_total is Dictionary:
				_set_total(String(Dictionary(empty_total).get("label", "Total")), String(Dictionary(empty_total).get("value", "-")), bool(Dictionary(empty_total).get("ready", true)))
			else:
				_set_total(String(_config.get("total_label", "Total")), String(empty_total), true)
		primary_button.text = _display_text(String(_config.get("primary_label", "Select")))
		primary_button.disabled = true
		footer_summary.text = _display_text(String(_config.get("footer_text", "No item selected")))
		return

	var single_item: = _items.size() == 1
	var stats: Array = Array(item.get("stats", []))
	var costs: Array = Array(item.get("costs", []))
	if not single_item:
		var status: = _label(_state_text(item), 10, _state_color(item), HORIZONTAL_ALIGNMENT_CENTER, true)
		overview_content.add_child(status)
	overview_content.add_child(_overview_title_plate(_display_text(String(item.get("title", _selected_item_id)))))
	var description: = String(item.get("description", item.get("subtitle", "")))
	if not description.is_empty() and ( not single_item or (stats.is_empty() and costs.is_empty())):
		var description_label: = _label(description, 10, STEEL, HORIZONTAL_ALIGNMENT_CENTER)
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.max_lines_visible = 2
		description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		overview_content.add_child(description_label)
	_add_progress_overview(item)

	var disabled_reason: = _item_disabled_reason(item)
	if not disabled_reason.is_empty():
		var error_label: = _label(disabled_reason, 11, DANGER, HORIZONTAL_ALIGNMENT_LEFT)
		error_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		overview_content.add_child(error_label)

	if not stats.is_empty():
		if single_item and stats[0] is Dictionary:
			overview_content.add_child(_hero_stat_panel(Dictionary(stats[0])))
			for stat_index in range(1, stats.size()):
				if stats[stat_index] is Dictionary:
					overview_content.add_child(_stat_row(Dictionary(stats[stat_index])))
		else:
			overview_content.add_child(_section_label(String(item.get("stats_label", "Current > Next"))))
			for stat_value in stats:
				if stat_value is Dictionary:
					overview_content.add_child(_stat_row(Dictionary(stat_value)))

	if not costs.is_empty():
		if not single_item:
			overview_content.add_child(_section_label(String(item.get("costs_label", "Cost"))))
		for cost_value in costs:
			if cost_value is Dictionary:
				overview_content.add_child(_cost_row(Dictionary(cost_value)))

	var future_unlock: = String(item.get("future_unlock", item.get("unlock_teaser", "")))
	if not future_unlock.is_empty() and ( not single_item or bool(item.get("locked", false))):
		overview_content.add_child(_section_label(String(item.get("future_unlock_label", "Next unlock"))))
		var teaser_plate: = PanelContainer.new()
		teaser_plate.add_theme_stylebox_override("panel", _forged_plate_style(Color("111214"), IRON_EDGE, 7))
		var teaser: = _label(future_unlock, 10, STEEL, HORIZONTAL_ALIGNMENT_LEFT)
		teaser.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		teaser.max_lines_visible = 2
		teaser.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		teaser_plate.add_child(teaser)
		overview_content.add_child(teaser_plate)

	_refresh_total(item)
	total_panel.visible = not single_item or costs.is_empty()
	_refresh_primary_action(item)
	footer_summary.text = _footer_text(item)
	call_deferred("_reset_overview_scroll")


func _overview_title_plate(title_text: String) -> PanelContainer:
	var plate: = PanelContainer.new()
	plate.custom_minimum_size.y = 58
	plate.add_theme_stylebox_override("panel", _title_plate_style())
	var label: = _label(title_text, 19, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	plate.add_child(label)
	return plate


func _hero_stat_panel(stat: Dictionary) -> PanelContainer:
	var plate: = PanelContainer.new()
	plate.custom_minimum_size.y = 108
	plate.add_theme_stylebox_override("panel", _forged_plate_style(Color("111214"), IRON_MID, 10))
	var stack: = VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation", 1)
	plate.add_child(stack)
	var stat_name: = _label(_display_text(String(stat.get("label", stat.get("id", "Power")))), 10, STEEL, HORIZONTAL_ALIGNMENT_CENTER, true)
	stack.add_child(stat_name)
	var values: = HBoxContainer.new()
	values.alignment = BoxContainer.ALIGNMENT_CENTER
	values.add_theme_constant_override("separation", 18)
	stack.add_child(values)
	var decimals: = int(stat.get("decimals", -1))
	var current_text: = _value_text(stat.get("current", "-"), decimals)
	var next_text: = _value_text(stat.get("next", current_text), decimals)
	var suffix: = String(stat.get("suffix", ""))
	values.add_child(_label("%s%s" % [current_text, suffix], 28, IVORY, HORIZONTAL_ALIGNMENT_CENTER, true))
	values.add_child(_label(">", 21, _accent_bright, HORIZONTAL_ALIGNMENT_CENTER, true))
	values.add_child(_label("%s%s" % [next_text, suffix], 28, _accent_bright, HORIZONTAL_ALIGNMENT_CENTER, true))
	return plate


func _stat_row(stat: Dictionary) -> Control:
	var row_panel: = PanelContainer.new()
	row_panel.custom_minimum_size.y = 38
	row_panel.add_theme_stylebox_override("panel", _forged_plate_style(SURFACE_RAISED, IRON_EDGE, 7))
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)
	var name_label: = _label(_display_text(String(stat.get("label", stat.get("id", "Stat")))), 11, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var decimals: = int(stat.get("decimals", -1))
	var current_text: = _value_text(stat.get("current", "-"), decimals)
	var next_text: = _value_text(stat.get("next", current_text), decimals)
	var suffix: = String(stat.get("suffix", ""))
	var value: = _label("%s%s  >  %s%s" % [current_text, suffix, next_text, suffix], 13, _accent_bright, HORIZONTAL_ALIGNMENT_RIGHT, true)
	row.add_child(value)
	return row_panel


func _cost_row(cost: Dictionary) -> Control:
	var row_panel: = PanelContainer.new()
	row_panel.custom_minimum_size.y = 52
	var missing: = _cost_missing(cost)
	row_panel.add_theme_stylebox_override("panel", _forged_plate_style(SURFACE_RAISED, IRON_MID if missing <= 0 else Color(DANGER, 0.68), 9))
	var row: = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)
	var icon_texture: = _texture_from_value(cost.get("icon", cost.get("icon_path", "")))
	if icon_texture != null:
		var icon: = TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 36)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = icon_texture
		row.add_child(icon)
	var owned: = maxi(0, int(cost.get("owned", 0)))
	var required: = maxi(0, int(cost.get("required", cost.get("amount", 0))))
	var name_label: = _label(_display_text(String(cost.get("label", cost.get("id", "Material")))), 11, STEEL, HORIZONTAL_ALIGNMENT_LEFT, true)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var amount: = _label("%d / %d" % [owned, required], 15, _accent_bright if missing <= 0 else DANGER, HORIZONTAL_ALIGNMENT_RIGHT, true)
	row.add_child(amount)
	var missing_label: = _label("✓" if missing <= 0 else "%d missing" % missing, 18 if missing <= 0 else 10, _accent_bright if missing <= 0 else DANGER, HORIZONTAL_ALIGNMENT_RIGHT)
	missing_label.custom_minimum_size.x = 38 if missing <= 0 else 68
	row.add_child(missing_label)
	return row_panel


func _refresh_total(item: Dictionary) -> void :
	var total_value_config: Variant = item.get("total", _config.get("total", {}))
	if total_value_config is Dictionary:
		var total: Dictionary = total_value_config
		_set_total(
			String(total.get("label", "TOTAL")),
			String(total.get("value", _derived_total_value(item))),
			bool(total.get("ready", _is_affordable(item)))
		)
		return
	if not String(total_value_config).is_empty():
		_set_total(String(item.get("total_label", _config.get("total_label", "TOTAL"))), String(total_value_config), _is_affordable(item))
		return
	_set_total(String(item.get("total_label", _config.get("total_label", "TOTAL"))), _derived_total_value(item), _is_affordable(item))


func _set_total(label_text: String, value_text: String, ready: bool) -> void :
	total_label.text = _display_text(label_text)
	total_value.text = _display_text(value_text)
	total_value.add_theme_color_override("font_color", _accent_bright if ready else DANGER)
	total_panel.add_theme_stylebox_override("panel", _forged_plate_style(_accent_deep.darkened(0.35) if ready else Color("241516"), Color(_accent if ready else DANGER, 0.9), 10))


func _refresh_primary_action(item: Dictionary) -> void :
	primary_button.text = _display_text(String(item.get("action_label", _config.get("primary_label", "Select"))))
	primary_button.disabled = not _action_is_enabled(item)
	if bool(item.get("locked", false)):
		primary_button.text = _display_text(String(item.get("locked_action_label", _config.get("locked_action_label", "Locked"))))
	elif not _is_affordable(item):
		primary_button.text = _display_text(String(item.get("missing_action_label", _config.get("missing_action_label", "Missing materials"))))
	elif not _item_disabled_reason(item).is_empty():
		primary_button.text = _display_text(String(item.get("disabled_action_label", _config.get("disabled_action_label", "Unavailable"))))


func _refresh_navigation() -> void :
	var index: = _selected_index()
	var count: = _items.size()
	var has_pages: = count > 1
	page_navigation.visible = has_pages
	catalog_scroll.visible = has_pages
	page_label.text = (
		"%s  -  %d / %d" % [_display_text(String(_config.get("catalog_label", "Catalog"))), maxi(0, index + 1), count]
		if has_pages
		else _display_text(String(_config.get("catalog_label", "Catalog")))
	)
	previous_button.visible = has_pages
	next_button.visible = has_pages
	previous_button.disabled = index <= 0
	next_button.disabled = index < 0 or index >= count - 1


func _select_item(item_id: String) -> void :
	if not _has_item(item_id) or item_id == _selected_item_id:
		return
	_selected_item_id = item_id
	_rebuild_cards()
	_refresh_showcase(_item_by_id(_selected_item_id))
	_refresh_overview()
	_refresh_navigation()
	_apply_responsive_layout()
	selection_changed.emit(item_id)


func _change_selection(offset: int) -> void :
	var index: = _selected_index()
	var next_index: = clampi(index + offset, 0, _items.size() - 1)
	if next_index >= 0 and next_index < _items.size():
		_select_item(String(Dictionary(_items[next_index]).get("id", "")))


func _confirm_selected() -> void :
	var item: = _item_by_id(_selected_item_id)
	if item.is_empty() or not _action_is_enabled(item):
		return
	action_confirmed.emit(_selected_item_id)
	if bool(_config.get("close_on_confirm", false)):
		close_commerce()


func _on_backdrop_pressed() -> void :
	if bool(_config.get("backdrop_closes", true)):
		close_commerce()


func _unhandled_input(event: InputEvent) -> void :
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_commerce()


func _apply_responsive_layout(size_override: Vector2 = Vector2.ZERO) -> void :
	if frame == null:
		return
	var viewport_size: = size_override if size_override != Vector2.ZERO else get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_layout_viewport_size = viewport_size
	var metrics: = layout_metrics(viewport_size)
	_place(frame, Rect2(metrics.get("panel_rect", Rect2())))
	var compact: = viewport_size.y <= 500.0
	var iphone_landscape: = bool(metrics.get("iphone_landscape", false))
	var touch_target: = _touch_target_for(metrics)
	var panel_width: = Rect2(metrics.get("panel_rect", Rect2())).size.x
	var single_item: = _items.size() == 1
	safe_margin.add_theme_constant_override(
		"margin_bottom", 32 if _visual_theme_id == "forge" and iphone_landscape else 22
	)
	overview_panel.custom_minimum_size.x = (
		clampf(panel_width * (0.46 if single_item else 0.42), 470.0, 590.0)
		if iphone_landscape
		else clampf(panel_width * (0.44 if single_item else 0.4), 330.0, 470.0)
	)
	header.custom_minimum_size.y = touch_target if iphone_landscape else (58.0 if compact else 68.0)
	footer.custom_minimum_size.y = touch_target if iphone_landscape else (58.0 if compact else 66.0)
	page_navigation.custom_minimum_size.y = touch_target
	close_button.custom_minimum_size = Vector2(touch_target, touch_target) if iphone_landscape else Vector2(60, MIN_TOUCH_TARGET if compact else 60)
	title_plaque.custom_minimum_size.x = 590.0 if iphone_landscape else 430.0
	var balance_spacer: Control = header.get_node_or_null("CloseBalance") as Control
	if balance_spacer != null:
		balance_spacer.custom_minimum_size.x = close_button.custom_minimum_size.x
	close_slot.custom_minimum_size.x = close_button.custom_minimum_size.x
	previous_button.custom_minimum_size = Vector2(touch_target, touch_target) if iphone_landscape else Vector2(60, MIN_TOUCH_TARGET)
	next_button.custom_minimum_size = Vector2(touch_target, touch_target) if iphone_landscape else Vector2(60, MIN_TOUCH_TARGET)
	cancel_button.custom_minimum_size = Vector2(168, touch_target) if iphone_landscape else Vector2(132, 58 if compact else 64)
	primary_button.custom_minimum_size = Vector2(318, touch_target) if iphone_landscape else Vector2(248, 58 if compact else 64)
	total_panel.custom_minimum_size.y = touch_target if iphone_landscape else MIN_TOUCH_TARGET
	var hero_extent: = 372.0 if iphone_landscape and single_item and _visual_theme_id == "forge" else 390.0 if iphone_landscape and single_item else 168.0 if iphone_landscape else 320.0 if single_item else 190.0
	hero_medallion.custom_minimum_size = Vector2(hero_extent, hero_extent)
	var hero_icon_inset: = hero_extent * 0.11 if _visual_theme_id == "forge" else 12.0
	hero_icon.offset_left = hero_icon_inset
	hero_icon.offset_top = hero_icon_inset
	hero_icon.offset_right = -hero_icon_inset
	hero_icon.offset_bottom = -hero_icon_inset
	catalog_scroll.custom_minimum_size.y = 104.0 if iphone_landscape else 82.0
	_apply_card_touch_targets(touch_target, iphone_landscape)
	_apply_font_scale(self, IPHONE_FONT_SCALE if iphone_landscape else (1.2 if compact else 1.0))


func _touch_target_for(metrics: Dictionary) -> float:
	return IPHONE_TOUCH_TARGET if bool(metrics.get("iphone_landscape", false)) else MIN_TOUCH_TARGET


func _apply_card_touch_targets(touch_target: float, iphone_landscape: bool) -> void :
	if catalog_strip == null:
		return
	for child in catalog_strip.get_children():
		if child is Button:
			var card: Button = child as Button
			card.custom_minimum_size = Vector2(
				190.0 if iphone_landscape else 150.0,
				maxf(touch_target, 94.0) if iphone_landscape else 76.0
			)
			var icon_plate: Control = card.get_node_or_null("Inset/CardRow/IconPlate") as Control
			if icon_plate != null:
				var icon_extent: = 76.0 if iphone_landscape else 58.0
				icon_plate.custom_minimum_size = Vector2(icon_extent, icon_extent)


func apply_landscape_layout_for_test(viewport_size: Vector2) -> Dictionary:
	_apply_responsive_layout(viewport_size)
	return layout_metrics(viewport_size)


func _ensure_selected_visible() -> void :
	if is_instance_valid(_selected_card) and catalog_scroll != null:
		catalog_scroll.ensure_control_visible(_selected_card)


func _update_hero_icon_pivot() -> void :
	if hero_icon != null:
		hero_icon.pivot_offset = hero_icon.size * 0.5


func _reset_overview_scroll() -> void :
	if overview_scroll != null:
		overview_scroll.scroll_vertical = 0


func _apply_font_scale(node: Node, scale: float) -> void :
	if node is Label or node is Button:
		var control: Control = node as Control
		if not control.has_meta("commerce_base_font_size"):
			control.set_meta("commerce_base_font_size", control.get_theme_font_size("font_size"))
		var base_size: = int(control.get_meta("commerce_base_font_size", 12))
		control.add_theme_font_size_override("font_size", maxi(10, roundi(float(base_size) * scale)))
	for child in node.get_children():
		_apply_font_scale(child, scale)


func _minimum_visible_font_size() -> int:
	var minimum: = 1000
	var pending: Array[Node] = [self]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is Label or node is Button:
			var control: Control = node as Control
			if control.visible:
				minimum = mini(minimum, control.get_theme_font_size("font_size"))
		for child in node.get_children():
			pending.append(child)
	return 0 if minimum == 1000 else minimum


func _initial_selection(preferred: String) -> String:
	if _has_item(preferred):
		return preferred
	for item_value in _items:
		var item: Dictionary = item_value
		if bool(item.get("equipped", false)) or bool(item.get("current", false)):
			return String(item.get("id", ""))
	if not _items.is_empty():
		return String(Dictionary(_items[0]).get("id", ""))
	return ""


func _valid_items(values: Array) -> Array:
	var valid: Array = []
	var seen: Dictionary = {}
	for value in values:
		if not value is Dictionary:
			continue
		var item: Dictionary = Dictionary(value).duplicate(true)
		var item_id: = String(item.get("id", ""))
		if item_id.is_empty() or seen.has(item_id):
			continue
		seen[item_id] = true
		valid.append(item)
	return valid


func _has_item(item_id: String) -> bool:
	return not item_id.is_empty() and not _item_by_id(item_id).is_empty()


func _item_by_id(item_id: String) -> Dictionary:
	for item_value in _items:
		var item: Dictionary = item_value
		if String(item.get("id", "")) == item_id:
			return item
	return {}


func _selected_index() -> int:
	for index in _items.size():
		if String(Dictionary(_items[index]).get("id", "")) == _selected_item_id:
			return index
	return -1


func _action_is_enabled(item: Dictionary) -> bool:
	if item.is_empty() or bool(item.get("locked", false)) or not _is_affordable(item) or not _item_disabled_reason(item).is_empty():
		return false
	return bool(item.get("action_enabled", true))


func _is_affordable(item: Dictionary) -> bool:
	if item.has("affordable"):
		return bool(item.get("affordable", false))
	for cost_value in Array(item.get("costs", [])):
		if cost_value is Dictionary and _cost_missing(Dictionary(cost_value)) > 0:
			return false
	return true


func _cost_missing(cost: Dictionary) -> int:
	if cost.has("missing"):
		return maxi(0, int(cost.get("missing", 0)))
	return maxi(0, int(cost.get("required", cost.get("amount", 0))) - int(cost.get("owned", 0)))


func _state_text(item: Dictionary) -> String:
	var override: = String(item.get("state_label", ""))
	if not override.is_empty():
		return _display_text(override)
	var states: Array[String] = []
	var equipped: = bool(item.get("equipped", false))
	var current: = bool(item.get("current", false))
	if equipped:
		states.append("Equipped")
	if current:
		states.append("Current")
	if bool(item.get("locked", false)):
		states.append("Locked")
	elif not equipped and not current and ( not bool(item.get("action_enabled", true)) or not _item_disabled_reason(item).is_empty()):
		states.append("Unavailable")
	elif not equipped and not current and _is_affordable(item):
		states.append("Ready")
	elif not equipped and not current:
		states.append("Materials missing")
	return "  -  ".join(states)


func _state_color(item: Dictionary) -> Color:
	if bool(item.get("locked", false)):
		return MUTED
	if bool(item.get("equipped", false)) or bool(item.get("current", false)):
		return _accent_bright
	return _accent_bright if _is_affordable(item) else DANGER


func _cost_color(item: Dictionary) -> Color:
	return MUTED if bool(item.get("locked", false)) else _accent_bright if _is_affordable(item) else DANGER


func _card_stat_text(item: Dictionary) -> String:
	var stats: Array = Array(item.get("stats", []))
	if stats.is_empty() or not stats[0] is Dictionary:
		return _display_text(String(item.get("stat_summary", "")))
	var stat: Dictionary = stats[0]
	var decimals: = int(stat.get("decimals", -1))
	var current_text: = _value_text(stat.get("current", "-"), decimals)
	var next_text: = _value_text(stat.get("next", current_text), decimals)
	var suffix: = String(stat.get("suffix", ""))
	return "%s  %s%s > %s%s" % [_display_text(String(stat.get("label", stat.get("id", "Stat")))), current_text, suffix, next_text, suffix]


func _card_cost_text(item: Dictionary) -> String:
	var costs: Array = Array(item.get("costs", []))
	if costs.is_empty():
		return _display_text(String(item.get("cost_summary", "No cost")))
	var total_missing: = 0
	var ready_count: = 0
	for cost_value in costs:
		if not cost_value is Dictionary:
			continue
		var missing: = _cost_missing(Dictionary(cost_value))
		total_missing += missing
		if missing <= 0:
			ready_count += 1
	if costs.size() == 1 and costs[0] is Dictionary:
		var cost: Dictionary = costs[0]
		return "%s  %d / %d" % [
			_display_text(String(cost.get("label", cost.get("id", "Cost")))),
			maxi(0, int(cost.get("owned", 0))),
			maxi(0, int(cost.get("required", cost.get("amount", 0)))),
		]
	return "%d / %d costs ready" % [ready_count, costs.size()] if total_missing <= 0 else "%d missing  -  %d / %d ready" % [total_missing, ready_count, costs.size()]


func _derived_total_value(item: Dictionary) -> String:
	var costs: Array = Array(item.get("costs", []))
	if costs.is_empty():
		return String(item.get("total_text", "Ready"))
	var total_required: = 0
	var total_owned: = 0
	var total_missing: = 0
	for cost_value in costs:
		if not cost_value is Dictionary:
			continue
		var cost: Dictionary = cost_value
		total_required += maxi(0, int(cost.get("required", cost.get("amount", 0))))
		total_owned += maxi(0, int(cost.get("owned", 0)))
		total_missing += _cost_missing(cost)
	if costs.size() == 1:
		return "%d / %d" % [total_owned, total_required]
	return "Ready" if total_missing <= 0 else "%d missing" % total_missing


func _footer_text(item: Dictionary) -> String:
	var disabled_reason: = _item_disabled_reason(item)
	if not disabled_reason.is_empty():
		return _display_text(disabled_reason)
	if bool(item.get("locked", false)):
		return _display_text(String(item.get("locked_reason", item.get("future_unlock", "Locked"))))
	if not _is_affordable(item):
		return _card_cost_text(item)
	return _display_text(String(item.get("footer_text", _config.get("ready_text", "Ready to confirm"))))


func _item_disabled_reason(item: Dictionary) -> String:
	var error: = String(item.get("error", ""))
	return error if not error.is_empty() else String(item.get("disabled_reason", ""))


func _add_progress_overview(source: Dictionary) -> void :
	var progress: Variant = source.get("progress", {})
	if not progress is Dictionary or Dictionary(progress).is_empty():
		return
	var data: Dictionary = progress
	var label_text: = _display_text(String(data.get("label", "Progress")))
	var current: = maxf(0.0, float(data.get("current", 0.0)))
	var target: = maxf(0.0, float(data.get("target", 0.0)))
	var display: = String(data.get("text", "%s / %s" % [_value_text(current), _value_text(target)]))
	var progress_row: = HBoxContainer.new()
	progress_row.custom_minimum_size.y = 24
	var progress_name: = _label(label_text, 10, MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	progress_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(progress_name)
	progress_row.add_child(_label(display, 11, _accent_bright, HORIZONTAL_ALIGNMENT_RIGHT, true))
	overview_content.add_child(progress_row)
	var bar: = ProgressBar.new()
	bar.custom_minimum_size.y = 12
	bar.min_value = 0.0
	bar.max_value = maxf(1.0, target)
	bar.value = minf(current, bar.max_value)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_theme_stylebox_override("background", _panel_style(Color("101113"), IRON_EDGE, 5, 1, 1))
	bar.add_theme_stylebox_override("fill", _panel_style(_accent_deep, _accent, 5, 1, 1))
	overview_content.add_child(bar)


func _item_texture(item: Dictionary) -> Texture2D:
	return _texture_from_value(item.get("texture", item.get("icon", item.get("icon_path", ""))))


func _texture_from_value(value: Variant) -> Texture2D:
	if value is Texture2D:
		return value
	var path: = String(value)
	if not path.is_empty() and ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is Texture2D:
			return resource
	return null


func _value_text(value: Variant, decimals: int = -1) -> String:
	if value is float:
		var number: = float(value)
		if decimals >= 0:
			return String.num(number, decimals)
		return "%d" % roundi(number) if is_equal_approx(number, roundf(number)) else "%.1f" % number
	return str(value)


func _card_style(item: Dictionary, selected: bool, pressed: bool) -> StyleBox:
	if _visual_theme_id == "forge":
		var premium_tint: = Color("8f8b88")
		if bool(item.get("locked", false)):
			premium_tint = Color("69686b")
		elif pressed:
			premium_tint = Color("9a674c")
		elif selected:
			premium_tint = Color("ffe0b5")
		return _mossvein_plate_style(7, premium_tint)
	var background: = SURFACE_RAISED if selected else CARD
	if bool(item.get("locked", false)):
		background = Color("151517")
	if pressed:
		background = _accent_deep
	var border: = _accent if selected else IRON_MID
	if bool(item.get("locked", false)) and not selected:
		border = Color("343438")
	return _forged_plate_style(background, border, 7, 3 if selected else 2)


func _section_label(text_value: String) -> Label:
	var label: = _label(_display_text(text_value), 10, _accent_bright, HORIZONTAL_ALIGNMENT_LEFT, true)
	label.custom_minimum_size.y = 20
	return label


func _button(text_value: String, primary: bool) -> Button:
	var button: = Button.new()
	button.text = text_value
	button.add_theme_font_override("font", DISPLAY_FONT if primary else BODY_FONT)
	button.add_theme_font_size_override("font_size", 15 if primary else 12)
	_style_button(button, primary)
	return button


func _style_button(button: Button, primary: bool) -> void :
	button.add_theme_color_override("font_color", IVORY if primary else STEEL)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("aaa6a1") if _visual_theme_id == "forge" else Color("626166"))
	if _visual_theme_id == "forge":
		button.add_theme_color_override("font_outline_color", Color(INK, 0.94))
		button.add_theme_constant_override("outline_size", 2)
		button.add_theme_stylebox_override("normal", _mossvein_action_style(10, Color("fff0e2")) if primary else _mossvein_plate_style(10, Color("d2cec8")))
		button.add_theme_stylebox_override("hover", _mossvein_action_style(10, Color.WHITE) if primary else _mossvein_plate_style(10, Color("f2e4d1")))
		button.add_theme_stylebox_override("pressed", _mossvein_action_style(10, Color("9c7055")) if primary else _mossvein_plate_style(10, Color("82726a")))
		button.add_theme_stylebox_override("focus", _mossvein_action_style(10, Color("fff1dc")) if primary else _mossvein_plate_style(10, Color("ffd3a3")))
		button.add_theme_stylebox_override("disabled", _mossvein_plate_style(10, Color("858286") if primary else Color("68686c")))
		return
	button.remove_theme_color_override("font_outline_color")
	button.remove_theme_constant_override("outline_size")
	button.add_theme_stylebox_override("normal", _button_style(_accent_deep.darkened(0.12) if primary else SURFACE_RAISED, _accent if primary else IRON_MID, 3 if primary else 2, primary))
	button.add_theme_stylebox_override("hover", _button_style(_accent.darkened(0.34) if primary else Color("2b2c30"), _accent_bright if primary else IRON_HIGH, 3, primary))
	button.add_theme_stylebox_override("pressed", _button_style(_accent_deep.darkened(0.24) if primary else Color("121315"), _accent_bright, 3, primary))
	button.add_theme_stylebox_override("focus", _button_style(_accent_deep.darkened(0.2) if primary else Color("191a1c"), _accent_bright, 3, primary))
	button.add_theme_stylebox_override("disabled", _button_style(Color("121315"), Color("34353a"), 2, false))


func _style_close_button(button: Button) -> void :
	button.add_theme_font_override("font", DISPLAY_FONT)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_stylebox_override("normal", _round_style(Color("202125"), IRON_MID, 3, 7))
	button.add_theme_stylebox_override("hover", _round_style(Color("2b2c30"), IRON_HIGH, 3, 7))
	button.add_theme_stylebox_override("pressed", _round_style(Color("101113"), _accent_bright, 3, 7))
	button.add_theme_stylebox_override("focus", _round_style(Color("202125"), _accent_bright, 3, 7))
	button.add_theme_stylebox_override("disabled", _round_style(Color("131416"), Color("34353a"), 2, 7))


func _label(text_value: String, font_size: int, color: Color, alignment: HorizontalAlignment, display_font: bool = false) -> Label:
	var label: = Label.new()
	label.text = text_value
	label.horizontal_alignment = alignment
	label.add_theme_font_override("font", DISPLAY_FONT if display_font else BODY_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	if display_font:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.92))
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_constant_override("shadow_outline_size", 2)
	return label


func _display_text(text_value: String) -> String:
	var clean: = text_value.strip_edges()
	if clean.is_empty():
		return clean
	return clean.to_lower().capitalize() if clean == clean.to_upper() else clean


func _panel_style(background: Color, border: Color, radius: int, border_width: int, padding: int) -> StyleBoxFlat:
	var style: = _flat_style(background, radius)
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.content_margin_left = float(padding)
	style.content_margin_right = float(padding)
	style.content_margin_top = float(padding)
	style.content_margin_bottom = float(padding)
	return style


func _forged_plate_style(background: Color, border: Color, padding: int, border_width: int = 2) -> StyleBox:
	var style: = _panel_style(background, border, 5, border_width, padding)
	style.shadow_color = Color(0, 0, 0, 0.72)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _overview_panel_style() -> StyleBox:
	if _visual_theme_id == "forge":
		return _mossvein_plate_style(16, Color("d7d0c8"))
	return _forged_plate_style(SURFACE, IRON_MID, 12)


func _mossvein_texture_style(texture: Texture2D, region_ratio: Rect2, margin_ratio: Vector4, padding: int, tint: Color, draw_center: bool = true) -> StyleBoxTexture:
	var texture_size: = texture.get_size()
	var style: = StyleBoxTexture.new()
	style.texture = texture
	style.region_rect = Rect2(texture_size * region_ratio.position, texture_size * region_ratio.size)
	style.texture_margin_left = texture_size.x * margin_ratio.x
	style.texture_margin_top = texture_size.y * margin_ratio.y
	style.texture_margin_right = texture_size.x * margin_ratio.z
	style.texture_margin_bottom = texture_size.y * margin_ratio.w
	style.content_margin_left = float(padding)
	style.content_margin_top = float(padding)
	style.content_margin_right = float(padding)
	style.content_margin_bottom = float(padding)
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	style.modulate_color = tint
	style.draw_center = draw_center
	return style


func _mossvein_plate_style(padding: int, tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _mossvein_texture_style(
		MOSSVEIN_PLATE,
		Rect2(0.016, 0.14, 0.968, 0.72),
		Vector4(0.10, 0.125, 0.10, 0.125),
		padding,
		tint
	)


func _mossvein_action_style(padding: int, tint: Color = Color.WHITE) -> StyleBoxTexture:
	return _mossvein_texture_style(
		MOSSVEIN_ACTION,
		Rect2(0.012, 0.145, 0.976, 0.70),
		Vector4(0.105, 0.14, 0.105, 0.14),
		padding,
		tint
	)


func _button_style(background: Color, border: Color, border_width: int, glow: bool) -> StyleBoxFlat:
	var style: = _panel_style(background, border, 5, border_width, 10)
	style.shadow_color = Color(border, 0.35) if glow else Color(0, 0, 0, 0.68)
	style.shadow_size = 9 if glow else 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _round_style(background: Color, border: Color, border_width: int, padding: int) -> StyleBoxFlat:
	var style: = _panel_style(background, border, 128, border_width, padding)
	style.corner_detail = 16
	style.shadow_color = Color(0, 0, 0, 0.75)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _inner_frame_style() -> StyleBoxFlat:
	var style: = _panel_style(Color(0.025, 0.026, 0.029, 0.9), Color("373639"), 5, 4, 0)
	style.border_width_top = 5
	style.border_width_bottom = 5
	return style


func _hero_well_style() -> StyleBox:
	if _visual_theme_id == "forge":
		return _mossvein_plate_style(11, Color("d2cbc3"))
	var style: StyleBoxFlat = _forged_plate_style(Color(0.018, 0.018, 0.02, 0.96), IRON_MID, 11, 3) as StyleBoxFlat
	style.shadow_color = Color(0, 0, 0, 0.88)
	style.shadow_size = 11
	return style


func _title_plate_style() -> StyleBox:
	if _visual_theme_id == "forge":
		return _mossvein_plate_style(9, Color("e4d6c6"))
	var style: StyleBoxFlat = _forged_plate_style(Color("171719"), IRON_MID, 9, 3) as StyleBoxFlat
	style.border_width_top = 3
	style.shadow_color = Color(0, 0, 0, 0.84)
	style.shadow_size = 7
	return style


func _metal_shader_material() -> ShaderMaterial:
	var shader: = Shader.new()
	shader.code = "\nshader_type canvas_item;\nuniform vec4 accent_color : source_color = vec4(0.90, 0.42, 0.13, 1.0);\n\nfloat hash(vec2 p) {\n\treturn fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);\n}\n\nvoid fragment() {\n\tvec2 uv = UV;\n\tfloat grain = hash(vec2(floor(uv.x * 940.0), floor(uv.y * 220.0)));\n\tfloat horizontal = sin(uv.y * 820.0 + grain * 5.0) * 0.015;\n\tfloat broad = sin(uv.y * 34.0) * 0.010;\n\tfloat vignette = 1.0 - smoothstep(0.18, 0.78, distance(uv, vec2(0.5)));\n\tvec3 iron = vec3(0.055, 0.057, 0.061) + horizontal + broad + grain * 0.012;\n\tiron += accent_color.rgb * (0.012 + 0.018 * vignette);\n\tCOLOR = vec4(iron, 1.0);\n}\n"


















	var material: = ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("accent_color", _accent)
	return material


func _frame_style() -> StyleBoxFlat:
	var style: = _panel_style(FRAME, Color("201f21"), 8, 8, 0)
	style.border_width_top = 9
	style.border_width_bottom = 9
	style.shadow_color = Color(0, 0, 0, 0.94)
	style.shadow_size = 24
	style.shadow_offset = Vector2(0, 10)
	return style


func _header_style() -> StyleBoxFlat:
	var style: = _panel_style(Color(0.02, 0.02, 0.022, 0.2), Color(0, 0, 0, 0), 0, 0, 0)
	return style


func _header_title_style() -> StyleBox:
	if _visual_theme_id == "forge":
		return _mossvein_plate_style(4, Color("eee1d1"))
	var style: StyleBoxFlat = _forged_plate_style(Color("18181a"), IRON_MID, 6, 3) as StyleBoxFlat
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.shadow_color = Color(0, 0, 0, 0.9)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 4)
	return style


func _flat_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: = StyleBoxFlat.new()
	style.bg_color = color
	style.corner_detail = 1
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style


func _place(control: Control, rect: Rect2) -> void :
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y
