class_name QuickTutorial
extends Control

signal closed

const GOLD: = Color("e9c86d")
const CREAM: = Color("fff0bd")
const SAVE_PATH: = "user://quick_tutorial.cfg"
const DEV_SAVE_PATH: = "user://quick_tutorial_dev.cfg"
const SEEN_KEY: = "seen_v031"
const DISPLAY_SECONDS: = 9.0
const MINE_ICON: = preload("res://assets/ui/hud-mine-impact-v1.png")
const INTERACT_ICON: = preload("res://assets/ui/hud-interact-v1.png")
const BAG_ICON: = preload("res://assets/ui/bag-premium-v1.png")
const MENU_ICON: = preload("res://assets/ui/hud-menu-v1.png")

var _touch_mode: = false
var _strip: HBoxContainer
var _open_serial: = 0


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 80
	visible = false
	get_viewport().size_changed.connect(_apply_layout)


func has_been_seen() -> bool:
	var config: = ConfigFile.new()
	if config.load(_save_path()) != OK:
		return false
	return bool(config.get_value("tutorial", SEEN_KEY, false))


func open(touch_mode: bool) -> void :
	_touch_mode = touch_mode
	_open_serial += 1
	_rebuild_strip()
	modulate = Color.WHITE
	visible = true
	_apply_layout()
	var serial: = _open_serial
	get_tree().create_timer(DISPLAY_SECONDS, true, false, true).timeout.connect(_begin_fade.bind(serial))


func dismiss() -> void :
	if visible:
		_finish()


func debug_snapshot() -> Dictionary:
	return {
		"visible": visible,
		"touch_mode": _touch_mode,
		"item_count": _strip.get_child_count() if _strip != null else 0,
		"has_background": false,
		"input_blocking": mouse_filter != Control.MOUSE_FILTER_IGNORE,
		"strip_rect": Rect2(_strip.position, _strip.size) if _strip != null else Rect2(),
	}


func _rebuild_strip() -> void :
	if _strip != null:
		_strip.queue_free()
	_strip = HBoxContainer.new()
	_strip.name = "ControlHints"
	_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_strip.alignment = BoxContainer.ALIGNMENT_CENTER
	_strip.add_theme_constant_override("separation", 24)
	add_child(_strip)
	if _touch_mode:
		_add_key_hint("DRAG", "MOVE")
		_add_icon_hint(MINE_ICON, "HOLD TO MINE")
		_add_icon_hint(INTERACT_ICON, "ACTION")
		_add_icon_hint(BAG_ICON, "BAG")
		_add_icon_hint(MENU_ICON, "MENU")
	else:
		_add_key_hint("WASD", "MOVE")
		_add_key_hint("SPACE", "HOLD TO MINE")
		_add_key_hint("E / F", "INTERACT")
		_add_icon_hint(BAG_ICON, "BAG")
		_add_key_hint("ESC", "MENU")


func _add_key_hint(key_text: String, caption: String) -> void :
	var item: = _hint_stack(caption)
	var keycap: = Label.new()
	keycap.text = key_text
	keycap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	keycap.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	keycap.custom_minimum_size = Vector2(104, 62)
	keycap.add_theme_font_size_override("font_size", 18 if key_text.length() <= 5 else 15)
	keycap.add_theme_color_override("font_color", CREAM)
	keycap.add_theme_constant_override("outline_size", 8)
	keycap.add_theme_color_override("font_outline_color", Color(0.005, 0.009, 0.006, 0.92))
	var key_style: = StyleBoxFlat.new()
	key_style.bg_color = Color(0.03, 0.055, 0.038, 0.58)
	key_style.border_color = Color(GOLD, 0.75)
	key_style.set_border_width_all(2)
	key_style.set_corner_radius_all(13)
	keycap.add_theme_stylebox_override("normal", key_style)
	item.add_child(keycap)
	item.move_child(keycap, 0)
	_strip.add_child(item)


func _add_icon_hint(texture: Texture2D, caption: String) -> void :
	var item: = _hint_stack(caption)
	var icon: = TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(72, 62)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(icon)
	item.move_child(icon, 0)
	_strip.add_child(item)


func _hint_stack(caption: String) -> VBoxContainer:
	var item: = VBoxContainer.new()
	item.custom_minimum_size = Vector2(112, 92)
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.add_theme_constant_override("separation", 4)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var caption_label: = Label.new()
	caption_label.name = "Caption"
	caption_label.text = caption
	caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption_label.add_theme_font_size_override("font_size", 13)
	caption_label.add_theme_color_override("font_color", Color("f3e9ca"))
	caption_label.add_theme_constant_override("outline_size", 7)
	caption_label.add_theme_color_override("font_outline_color", Color(0.005, 0.009, 0.006, 0.96))
	caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(caption_label)
	return item


func _apply_layout() -> void :
	if _strip == null:
		return
	var viewport_size: = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var compact: = viewport_size.x < 1000.0
	_strip.add_theme_constant_override("separation", 10 if compact else 24)
	var item_width: = 94.0 if compact else 112.0
	for item in _strip.get_children():
		if item is Control:
			item.custom_minimum_size.x = item_width
	_strip.reset_size()
	_strip.position = Vector2(
		(viewport_size.x - _strip.size.x) * 0.5,
		maxf(22.0, viewport_size.y * 0.16 - _strip.size.y * 0.5)
	)


func _begin_fade(serial: int) -> void :
	if serial != _open_serial or not visible:
		return
	var tween: = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 0.0, 0.55)
	tween.tween_callback(_finish)


func _finish() -> void :
	if not visible:
		return
	_open_serial += 1
	var config: = ConfigFile.new()
	config.set_value("tutorial", SEEN_KEY, true)
	config.save(_save_path())
	visible = false
	modulate = Color.WHITE
	closed.emit()


func _save_path() -> String:
	return DEV_SAVE_PATH if OS.has_feature("ever_deeper_dev") or "--qa-dev-tools" in OS.get_cmdline_user_args() else SAVE_PATH
