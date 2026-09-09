class_name ProgressionGoalPanel
extends PanelContainer

## A read-only HUD surface. All children deliberately pass touches to the world.
const TITLE_FONT: = preload("res://assets/ui/fonts/ChakraPetch-SemiBold.ttf")
const GOLD: = Color("ffe3a0")
const MINT: = Color("a8e3bc")
const CREAM: = Color("e7e6d2")

var _title: Label
var _action: Label
var _rows: VBoxContainer
var _row_controls: Dictionary = {}
var _texture_cache: Dictionary = {}
var _goal: Dictionary = {}
var _row_signature: = ""
var _iphone: = false
var _content: VBoxContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: = StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.055, 0.035, 0.76)
	style.set_corner_radius_all(11)
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 9.0
	style.content_margin_bottom = 10.0
	add_theme_stylebox_override("panel", style)
	_content = VBoxContainer.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_theme_constant_override("separation", 3)
	add_child(_content)
	_title = _label(GOLD)
	_title.name = "NextGoal"
	_title.add_theme_font_override("font", TITLE_FONT)
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_content.add_child(_title)
	_action = _label(MINT)
	_action.name = "NextAction"
	_action.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_content.add_child(_action)
	_rows = VBoxContainer.new()
	_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rows.add_theme_constant_override("separation", 1)
	_content.add_child(_rows)
	visible = false
	set_mobile_layout(false)


func present(goal: Dictionary) -> void:
	if _title == null:
		return
	_goal = goal.duplicate(true)
	visible = not goal.is_empty()
	if not visible:
		return
	var title: = String(goal.get("hud_title", goal.get("title", "")))
	var action: = String(goal.get("hud_action", ""))
	if _title.text != title:
		_title.text = title
	if _action.text != action:
		_action.text = action
	_action.visible = not action.is_empty()
	var requirements: = Array(goal.get("requirements", []))
	var keys: PackedStringArray = []
	for value in requirements:
		var row: = Dictionary(value)
		keys.append("%s:%s" % [String(row.get("id", "")), String(row.get("texture_path", ""))])
	var signature: = "|".join(keys)
	if signature != _row_signature:
		_rebuild_rows(requirements)
		_row_signature = signature
	for value in requirements:
		var requirement: = Dictionary(value)
		var id: = String(requirement.get("id", ""))
		if not _row_controls.has(id):
			continue
		var controls: = Dictionary(_row_controls[id])
		var name_label: Label = controls.label
		var counter: Label = controls.counter
		var row_name: = String(requirement.get("name", ""))
		var amount: = "%d / %d" % [int(requirement.get("owned", 0)), int(requirement.get("required", 0))]
		var pending_sale: = int(requirement.get("pending_sale", 0))
		if pending_sale > 0:
			amount = "%d (+%d) / %d" % [int(requirement.get("owned", 0)), pending_sale, int(requirement.get("required", 0))]
		var ready: = bool(requirement.get("ready", false))
		if name_label.text != row_name:
			name_label.text = row_name
		if counter.text != amount:
			counter.text = amount
		if ready != bool(controls.get("ready", not ready)):
			counter.add_theme_color_override("font_color", MINT if ready else GOLD)
			controls["ready"] = ready
			_row_controls[id] = controls
	_rows.visible = not requirements.is_empty()
	_update_action_visibility()


func set_mobile_layout(iphone: bool) -> void:
	_iphone = iphone
	if _title == null:
		return
	_title.add_theme_font_size_override("font_size", 22 if iphone else 18)
	_action.add_theme_font_size_override("font_size", 18 if iphone else 15)
	_update_action_visibility()
	for value in _row_controls.values():
		var controls: = Dictionary(value)
		var icon: TextureRect = controls.icon
		var label: Label = controls.label
		var counter: Label = controls.counter
		icon.custom_minimum_size = Vector2(34, 32) if iphone else Vector2(27, 26)
		label.add_theme_font_size_override("font_size", 18 if iphone else 15)
		counter.add_theme_font_size_override("font_size", 19 if iphone else 16)


func snapshot() -> Dictionary:
	var result: = _goal.duplicate(true)
	var rendered: Array[Dictionary] = []
	for value in Array(_goal.get("requirements", [])):
		var requirement: = Dictionary(value)
		var id: = String(requirement.get("id", ""))
		if _row_controls.has(id):
			var controls: = Dictionary(_row_controls[id])
			rendered.append({"id": id, "text": String(controls.counter.text), "ready": bool(controls.get("ready", false))})
	result["rendered_rows"] = rendered
	result["panel_rect"] = get_global_rect()
	result["visible"] = visible
	result["input_blocking"] = _has_input_blocker(self)
	result["title_text"] = _title.text if _title != null else ""
	result["action_text"] = _action.text if _action != null else ""
	result["action_visible"] = _action.visible if _action != null else false
	return result


func _update_action_visibility() -> void:
	# The final campaign recipe needs five full-size resource rows. Its location
	# subtitle remains in Guide; the compact HUD keeps the title and every cost.
	_action.visible = not _action.text.is_empty() and (not _iphone or Array(_goal.get("requirements", [])).size() < 5)


func _rebuild_rows(requirements: Array) -> void:
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_row_controls.clear()
	for value in requirements:
		var requirement: = Dictionary(value)
		var id: = String(requirement.get("id", ""))
		var row: = HBoxContainer.new()
		row.name = "GoalResource_%s" % String(requirement.get("resource_id", ""))
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 6)
		_rows.add_child(row)
		var icon: = TextureRect.new()
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = _texture(String(requirement.get("texture_path", "")))
		row.add_child(icon)
		var label: = _label(CREAM)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		row.add_child(label)
		var counter: = _label(GOLD)
		counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(counter)
		_row_controls[id] = {"icon": icon, "label": label, "counter": counter}
	set_mobile_layout(_iphone)


func _texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var source: Texture2D = load(path)
	var image: = source.get_image()
	if image != null and not image.is_empty():
		var used: = image.get_used_rect()
		if used.has_area():
			var cropped: = AtlasTexture.new()
			cropped.atlas = source
			cropped.region = Rect2(used)
			_texture_cache[path] = cropped
			return cropped
	_texture_cache[path] = source
	return source


func _label(color: Color) -> Label:
	var label: = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", TITLE_FONT)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label


func _has_input_blocker(node: Node) -> bool:
	if node is Control and node.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		return true
	for child in node.get_children():
		if _has_input_blocker(child):
			return true
	return false
