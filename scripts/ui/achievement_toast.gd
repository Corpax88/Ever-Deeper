class_name AchievementToast
extends Control

signal activated(id: String)

const TOUCH_TARGET_MIN: = 96.0
const TOAST_SIZE: = Vector2(520.0, 120.0)
const ICON_SIZE: = Vector2(104.0, 104.0)
const ICON_GAP: = 18.0
const SAFE_MARGIN: = 18.0
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const IPHONE_SIDE_INSET: = 116.0
const IPHONE_BOTTOM_INSET: = 38.0
const SPIN_SECONDS: = 0.92
const HOLD_SECONDS: = 3.0
const FADE_SECONDS: = 0.55
const SPIN_TURNS: = 2.0
const GOLD: = Color("ffe3a0")
const OUTLINE: = Color(0.01, 0.018, 0.013, 0.96)

enum Phase{
	IDLE,
	SPIN,
	HOLD,
	FADE,
}

var _queue: Array[Dictionary] = []
var _active_definition: Dictionary = {}
var _phase: = Phase.IDLE
var _phase_elapsed: = 0.0
var _screen_anchor: = Vector2(0.5, 0.24)
var _anchor_is_normalized: = true
var _last_safe_rect: = Rect2()

var _toast: Control
var _activation_target: Button
var _icon: TextureRect
var _title: Label
var _icon_rest_position: = Vector2.ZERO


func _init() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 145
	_build_interface()
	get_viewport().size_changed.connect(_apply_safe_layout)
	_apply_safe_layout()
	if not _queue.is_empty():
		_start_next()


func show_achievement(definition: Dictionary) -> void :
	var id: = String(definition.get("id", "")).strip_edges()
	if id.is_empty():
		return
	_queue.append(definition.duplicate(true))
	if is_inside_tree() and _phase == Phase.IDLE:
		_start_next()


func set_screen_anchor(screen_anchor: Vector2) -> void :
	_screen_anchor = screen_anchor
	_anchor_is_normalized = (
		screen_anchor.x >= 0.0
		and screen_anchor.x <= 1.0
		and screen_anchor.y >= 0.0
		and screen_anchor.y <= 1.0
	)
	if is_inside_tree() and _toast != null:
		_apply_safe_layout()


func dismiss() -> void :
	if _phase == Phase.IDLE:
		return
	_finish_current()


func clear() -> void :
	_queue.clear()
	_active_definition.clear()
	_phase = Phase.IDLE
	_phase_elapsed = 0.0
	if _toast != null:
		_toast.visible = false
		_toast.modulate = Color.WHITE
	_reset_icon_transform()


func debug_snapshot() -> Dictionary:
	var queued_ids: Array[String] = []
	for definition in _queue:
		queued_ids.append(String(definition.get("id", "")))
	var touch_size: = Vector2.ZERO if _activation_target == null else _activation_target.size
	var icon_scale_x: = 1.0 if _icon == null else _icon.scale.x
	return {
		"transparent": true,
		"has_panel": false,
		"has_background": false,
		"presentation": "achievement_png_and_title",
		"process_always": process_mode == Node.PROCESS_MODE_ALWAYS,
		"active": _phase != Phase.IDLE,
		"active_id": String(_active_definition.get("id", "")),
		"active_title": String(_active_definition.get("title", "")),
		"asset": _asset_path(_active_definition),
		"icon_loaded": _icon != null and _icon.texture != null,
		"phase": _phase_name(),
		"phase_elapsed": _phase_elapsed,
		"queue_size": _queue.size(),
		"queued_ids": queued_ids,
		"screen_anchor": _screen_anchor,
		"anchor_mode": "normalized" if _anchor_is_normalized else "logical_pixels",
		"safe_rect": _last_safe_rect,
		"toast_rect": Rect2() if _toast == null else Rect2(_toast.position, _toast.size),
		"touch_target": touch_size,
		"minimum_touch_target": TOUCH_TARGET_MIN,
		"touch_target_valid": touch_size.x >= TOUCH_TARGET_MIN and touch_size.y >= TOUCH_TARGET_MIN,
		"icon_scale_x": icon_scale_x,
		"upright": absf(icon_scale_x - 1.0) <= 0.001,
		"spin_seconds": SPIN_SECONDS,
		"hold_seconds": HOLD_SECONDS,
		"fade_seconds": FADE_SECONDS,
	}


func minimum_touch_target_is_valid() -> bool:
	return (
		_activation_target != null
		and _activation_target.size.x >= TOUCH_TARGET_MIN
		and _activation_target.size.y >= TOUCH_TARGET_MIN
	)


func is_presenting() -> bool:
	return _phase != Phase.IDLE


func apply_layout_for_test(viewport_size: Vector2, safe_insets: Vector4 = Vector4.ZERO) -> Dictionary:
	_build_interface()
	_apply_layout(viewport_size, safe_insets)
	return debug_snapshot()


func _build_interface() -> void :
	if _toast != null:
		return

	_toast = Control.new()
	_toast.name = "AchievementToastContent"
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.clip_contents = false
	_toast.visible = false
	add_child(_toast)

	_activation_target = Button.new()
	_activation_target.name = "ActivationTarget"
	_activation_target.text = ""
	_activation_target.flat = true
	_activation_target.focus_mode = Control.FOCUS_NONE
	_activation_target.mouse_filter = Control.MOUSE_FILTER_STOP
	_activation_target.custom_minimum_size = TOAST_SIZE
	_activation_target.tooltip_text = "Open achievements"
	for style_name in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
		_activation_target.add_theme_stylebox_override(style_name, StyleBoxEmpty.new())
	_activation_target.pressed.connect(_on_activation_pressed)
	_toast.add_child(_activation_target)

	_icon = TextureRect.new()
	_icon.name = "AchievementIcon"
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.add_child(_icon)

	_title = Label.new()
	_title.name = "AchievementTitle"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title.add_theme_font_size_override("font_size", 27)
	_title.add_theme_color_override("font_color", GOLD)
	_title.add_theme_color_override("font_outline_color", OUTLINE)
	_title.add_theme_constant_override("outline_size", 7)
	_toast.add_child(_title)


func _process(delta: float) -> void :
	if _phase == Phase.IDLE:
		return
	_phase_elapsed += maxf(0.0, delta)
	match _phase:
		Phase.SPIN:
			_update_spin()
			if _phase_elapsed >= SPIN_SECONDS:
				_phase = Phase.HOLD
				_phase_elapsed = 0.0
				_reset_icon_transform()
				_title.modulate.a = 1.0
		Phase.HOLD:
			if _phase_elapsed >= HOLD_SECONDS:
				_phase = Phase.FADE
				_phase_elapsed = 0.0
		Phase.FADE:
			var progress: = clampf(_phase_elapsed / FADE_SECONDS, 0.0, 1.0)
			_toast.modulate.a = 1.0 - smoothstep(0.0, 1.0, progress)
			if _phase_elapsed >= FADE_SECONDS:
				_finish_current()


func _start_next() -> void :
	if _queue.is_empty():
		_active_definition.clear()
		_phase = Phase.IDLE
		_phase_elapsed = 0.0
		if _toast != null:
			_toast.visible = false
		return
	_build_interface()
	_active_definition = _queue.pop_front()
	_phase = Phase.SPIN
	_phase_elapsed = 0.0
	_title.text = String(_active_definition.get("title", "ACHIEVEMENT")).to_upper()
	_title.modulate.a = 0.0
	_icon.texture = _load_icon(_active_definition)
	_icon.visible = _icon.texture != null
	_activation_target.tooltip_text = "Open achievement · %s" % String(_active_definition.get("title", "Achievement"))
	_toast.visible = true
	_toast.modulate = Color.WHITE
	_apply_safe_layout()
	_update_spin()


func _finish_current() -> void :
	_active_definition.clear()
	_phase = Phase.IDLE
	_phase_elapsed = 0.0
	if _toast != null:
		_toast.visible = false
		_toast.modulate = Color.WHITE
	_reset_icon_transform()
	if not _queue.is_empty():
		_start_next()


func _update_spin() -> void :
	var progress: = clampf(_phase_elapsed / SPIN_SECONDS, 0.0, 1.0)
	var eased: = 1.0 - pow(1.0 - progress, 3.0)
	var angle: = eased * TAU * SPIN_TURNS
	var horizontal_scale: = cos(angle)
	if absf(horizontal_scale) < 0.055:
		horizontal_scale = 0.055 if horizontal_scale >= 0.0 else -0.055
	_icon.scale = Vector2(horizontal_scale, 1.0 + sin(progress * PI) * 0.05)
	_icon.rotation = sin(angle) * 0.035
	_icon.position = _icon_rest_position + Vector2(0.0, - sin(progress * PI) * 13.0)
	_title.modulate.a = smoothstep(0.16, 0.56, progress)


func _reset_icon_transform() -> void :
	if _icon == null:
		return
	_icon.scale = Vector2.ONE
	_icon.rotation = 0.0
	_icon.position = _icon_rest_position


func _on_activation_pressed() -> void :
	if _phase == Phase.IDLE:
		return
	var id: = String(_active_definition.get("id", ""))
	if not id.is_empty():
		activated.emit(id)


func _load_icon(definition: Dictionary) -> Texture2D:
	var path: = _asset_path(definition)
	if path.is_empty() or not path.to_lower().ends_with(".png") or not ResourceLoader.exists(path):
		return null
	var resource: = ResourceLoader.load(path)
	return resource as Texture2D


func _asset_path(definition: Dictionary) -> String:
	var path: = String(definition.get("asset", "")).strip_edges()
	if path.is_empty():
		return ""
	if path.begins_with("res://"):
		return path
	return "res://%s" % path.trim_prefix("/")


func _apply_safe_layout() -> void :
	if _toast == null or not is_inside_tree():
		return
	var viewport_rect: = get_viewport().get_visible_rect()
	if viewport_rect.size.x <= 1.0 or viewport_rect.size.y <= 1.0:
		return
	_apply_layout(viewport_rect.size, _native_safe_insets(viewport_rect))


func _apply_layout(viewport_size: Vector2, native_insets: Vector4) -> void :
	if _toast == null or viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	_last_safe_rect = _safe_rect_for_viewport(viewport_size, native_insets)
	var toast_size: = Vector2(
		minf(TOAST_SIZE.x, _last_safe_rect.size.x),
		minf(TOAST_SIZE.y, _last_safe_rect.size.y)
	)
	toast_size.x = maxf(minf(TOUCH_TARGET_MIN, _last_safe_rect.size.x), toast_size.x)
	toast_size.y = maxf(minf(TOUCH_TARGET_MIN, _last_safe_rect.size.y), toast_size.y)
	var desired_center: = _screen_anchor
	if _anchor_is_normalized:
		desired_center = viewport_size * _screen_anchor
	var desired_position: = desired_center - toast_size * 0.5
	var max_position: = _last_safe_rect.end - toast_size
	desired_position.x = clampf(desired_position.x, _last_safe_rect.position.x, max_position.x)
	desired_position.y = clampf(desired_position.y, _last_safe_rect.position.y, max_position.y)
	_place(_toast, Rect2(desired_position, toast_size))
	_place(_activation_target, Rect2(Vector2.ZERO, toast_size))
	_activation_target.custom_minimum_size = toast_size

	var icon_side: = minf(ICON_SIZE.x, toast_size.y)
	_icon_rest_position = Vector2(0.0, (toast_size.y - icon_side) * 0.5)
	_place(_icon, Rect2(_icon_rest_position, Vector2(icon_side, icon_side)))
	_icon.pivot_offset = Vector2(icon_side, icon_side) * 0.5
	var title_left: = icon_side + ICON_GAP
	_place(_title, Rect2(title_left, 0.0, maxf(0.0, toast_size.x - title_left), toast_size.y))
	if _phase != Phase.SPIN:
		_reset_icon_transform()


func _safe_rect_for_viewport(viewport_size: Vector2, native_insets: Vector4) -> Rect2:
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	var left: = maxf(native_insets.x, IPHONE_SIDE_INSET if iphone else SAFE_MARGIN)
	var top: = maxf(native_insets.y, SAFE_MARGIN)
	var right: = maxf(native_insets.z, IPHONE_SIDE_INSET if iphone else SAFE_MARGIN)
	var bottom: = maxf(native_insets.w, IPHONE_BOTTOM_INSET if iphone else SAFE_MARGIN)
	if left + right >= viewport_size.x:
		left = 0.0
		right = 0.0
	if top + bottom >= viewport_size.y:
		top = 0.0
		bottom = 0.0
	return Rect2(left, top, viewport_size.x - left - right, viewport_size.y - top - bottom)


func _native_safe_insets(viewport_rect: Rect2) -> Vector4:
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		return Vector4.ZERO
	var display_safe_area: = DisplayServer.get_display_safe_area()
	if not display_safe_area.has_area():
		return Vector4.ZERO
	var screen_to_canvas: = get_viewport().get_screen_transform().affine_inverse()
	var safe_top_left: = screen_to_canvas * Vector2(display_safe_area.position)
	var safe_bottom_right: = screen_to_canvas * Vector2(display_safe_area.end)
	return Vector4(
		maxf(0.0, safe_top_left.x - viewport_rect.position.x),
		maxf(0.0, safe_top_left.y - viewport_rect.position.y),
		maxf(0.0, viewport_rect.end.x - safe_bottom_right.x),
		maxf(0.0, viewport_rect.end.y - safe_bottom_right.y),
	)


func _place(control: Control, rect: Rect2) -> void :
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 0.0
	control.anchor_bottom = 0.0
	control.offset_left = rect.position.x
	control.offset_top = rect.position.y
	control.offset_right = rect.end.x
	control.offset_bottom = rect.end.y


func _phase_name() -> String:
	match _phase:
		Phase.SPIN:
			return "spin"
		Phase.HOLD:
			return "hold"
		Phase.FADE:
			return "fade"
	return "idle"
