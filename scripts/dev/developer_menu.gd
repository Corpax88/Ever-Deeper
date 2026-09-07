class_name DeveloperMenu
extends Control

signal command_requested(command: String)

const GOLD: = Color("d7b45a")
const GOLD_BRIGHT: = Color("ffe3a0")
const MINT: = Color("a8e3bc")
const MUTED: = Color("c6d9cb")
const INK: = Color("07120d")
const DEV_RED: = Color("f06b62")
const PANEL_FILL: = Color("081710")
const TOUCH_TARGET_MIN: = 52.0
const RESET_CONFIRM_WINDOW_MSEC: = 4200

class FrameMeter extends Label:
	var samples: Array[float] = []
	var previous_usec: int = 0
	var elapsed_ms: float = 0.0
	var latest: Dictionary = {}
	var history: Array[Dictionary] = []
	var started_msec: int = 0

	func start() -> void:
		samples.clear()
		elapsed_ms = 0.0
		previous_usec = 0
		latest = {}
		history.clear()
		started_msec = Time.get_ticks_msec()
		text = "Measuring FPS…"
		show()
		set_process(true)

	func _process(_delta: float) -> void:
		var now: int = Time.get_ticks_usec()
		if previous_usec == 0:
			previous_usec = now
			return
		var ms: float = float(now - previous_usec) / 1000.0
		previous_usec = now
		samples.append(ms)
		elapsed_ms += ms
		if elapsed_ms < 2000.0: return
		var fps: float = float(samples.size()) * 1000.0 / elapsed_ms
		samples.sort()
		var p95: float = samples[clampi(ceili(samples.size() * 0.95) - 1, 0, samples.size() - 1)]
		var slow: int = 0
		for sample in samples:
			if sample > 33.34: slow += 1
		latest = {"fps": fps, "p95_ms": p95, "max_ms": samples[-1], "slow_frames": slow, "frames": samples.size()}
		var canvas_size: Vector2i = Vector2i(get_viewport().get_texture().get_size())
		var dpr: float = 1.0
		if OS.has_feature("web"):
			# Read dimensions only: never create a GL context or read back pixels.
			var raw: Variant = JavaScriptBridge.eval("JSON.stringify({w:document.getElementById('canvas').width,h:document.getElementById('canvas').height,dpr:window.devicePixelRatio||1})")
			if raw is String:
				var browser: Variant = JSON.parse_string(raw)
				if browser is Dictionary:
					canvas_size = Vector2i(int(browser.w), int(browser.h))
					dpr = float(browser.dpr)
		var cpu_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		var physics_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
		var memory: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
		var video_memory: float = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
		var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		var calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		latest.merge({"meter_revision": 2, "elapsed_seconds": (Time.get_ticks_msec() - started_msec) / 1000.0,
			"cpu_monitor_ms": cpu_ms, "physics_monitor_ms": physics_ms,
			"static_mib": memory, "video_mib": video_memory, "nodes": nodes,
			"draw_calls": calls, "canvas_width": canvas_size.x, "canvas_height": canvas_size.y, "dpr": dpr})
		history.append(latest.duplicate())
		if history.size() > 60: history.pop_front()
		var video_label: String = "%.0f" % video_memory if video_memory > 0.0 else "n/a"
		text = "D2 · %.0fs · %.1f FPS · p95 %.1f ms\nMax %.1f ms · >33 ms: %d · CPU %.1f / Phys %.1f ms\nCanvas %d×%d · DPR %.1f · Draw %d\nMem %.0f MiB · GPU %s MiB · Nodes %d" % [latest.elapsed_seconds, fps, p95, samples[-1], slow, cpu_ms, physics_ms, canvas_size.x, canvas_size.y, dpr, calls, memory, video_label, nodes]
		# Bounded memory-only history; no autosave, network or per-frame logging.
		samples.clear()
		elapsed_ms = 0.0

	func _notification(what: int) -> void:
		if what == NOTIFICATION_APPLICATION_FOCUS_IN:
			previous_usec = 0
			samples.clear()
			elapsed_ms = 0.0

const PRESET_ACTIONS: = [
	{"label": "ALL ZONES\nUNLOCKED", "command": "preset_all_zones"},
	{"label": "HUB\nREADY", "command": "preset_hub"},
	{"label": "DEEPHEART\nREADY", "command": "preset_deepheart"},
	{"label": "ENDLESS\nREADY", "command": "preset_endless"},
]

const LOCATION_ACTIONS: = [
	{"label": "SURFACE", "command": "jump_surface"},
	{"label": "MOSSVEIN MINE · D1", "command": "jump_mossMine_d1"},
	{"label": "ROOTWOUND · D2", "command": "jump_mossMine_d2"},
	{"label": "MOONGLASS MINE · D1", "command": "jump_moonMine_d1"},
	{"label": "PRISMATIC DEPTHS · D2", "command": "jump_moonMine_d2"},
	{"label": "EMBERDEEP MINE · D1", "command": "jump_emberMine_d1"},
	{"label": "MOLTEN DEPTHS · D2", "command": "jump_emberMine_d2"},
	{"label": "STARFALL MINE · D1", "command": "jump_starMine_d1"},
	{"label": "VOIDSTAR DEEP · D2", "command": "jump_starMine_d2"},
	{"label": "HUB", "command": "jump_hub"},
	{"label": "DEEPHEART", "command": "jump_deepheart"},
	{"label": "ENDLESS · LAYER 1", "command": "jump_endless_1"},
	{"label": "ENDLESS · LAYER 12", "command": "jump_endless_12"},
]

const RESOURCE_ACTIONS: = [
	{"label": "+200 EACH\nRESOURCE", "command": "grant_resources_200"},
	{"label": "+10 000\nGOLD", "command": "grant_gold_10000"},
	{"label": "MAX TOOLS\nPICKAXE + DRILL", "command": "grant_max_tools"},
]

const HUB_ACTIONS: = [
	{"label": "ALL RELICS\nRECOVERED", "command": "grant_all_relics"},
	{"label": "BUILD ALL\nWORKSHOPS", "command": "build_all_workshops"},
]

const ALL_COMMAND_IDS: = [
	"reset_dev",
	"preset_all_zones",
	"preset_hub",
	"preset_deepheart",
	"preset_endless",
	"jump_surface",
	"jump_mossMine_d1",
	"jump_mossMine_d2",
	"jump_moonMine_d1",
	"jump_moonMine_d2",
	"jump_emberMine_d1",
	"jump_emberMine_d2",
	"jump_starMine_d1",
	"jump_starMine_d2",
	"jump_hub",
	"jump_deepheart",
	"jump_endless_1",
	"jump_endless_12",
	"grant_resources_200",
	"grant_gold_10000",
	"grant_max_tools",
	"grant_all_relics",
	"build_all_workshops",
]

var toggle_button: Button
var drawer: PanelContainer
var scroll: ScrollContainer
var action_content: VBoxContainer
var status_label: Label
var reset_button: Button
var frame_meter: FrameMeter
var frame_meter_button: Button

var _reset_armed_until_msec: int = 0
var _last_viewport_size: = Vector2.ZERO
var _last_safe_insets: = Vector4.ZERO
var _active_scroll_touch: int = -1
var _scroll_drag_distance: float = 0.0


func _ready() -> void :
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 190
	_build_toggle()
	_build_drawer()
	frame_meter = FrameMeter.new()
	frame_meter.name = "FrameMeter"
	frame_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame_meter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame_meter.add_theme_font_size_override("font_size", 20)
	frame_meter.add_theme_color_override("font_color", Color("fff0c5"))
	frame_meter.add_theme_color_override("font_outline_color", Color("07120d"))
	frame_meter.add_theme_constant_override("outline_size", 5)
	add_child(frame_meter)
	frame_meter.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	frame_meter.position += Vector2(-340, -182)
	frame_meter.size = Vector2(680, 108)
	frame_meter.hide()
	frame_meter.set_process(false)
	get_viewport().size_changed.connect(_apply_platform_safe_area)
	set_process(false)
	call_deferred("_apply_platform_safe_area")


func open_menu() -> void :
	drawer.visible = true
	toggle_button.text = "CLOSE DEV"
	toggle_button.tooltip_text = "Close developer tools"
	_apply_layout(_last_viewport_size, _last_safe_insets)


func close_menu() -> void :
	drawer.visible = false
	toggle_button.text = "DEV TOOLS"
	toggle_button.tooltip_text = "Open developer tools · isolated save"
	_active_scroll_touch = -1
	_scroll_drag_distance = 0.0
	_disarm_reset()


func toggle_menu() -> void :
	if drawer.visible:
		close_menu()
	else:
		open_menu()


func is_open() -> bool:
	return drawer != null and drawer.visible

func toggle_frame_meter() -> void:
	if frame_meter.visible:
		frame_meter.hide()
		frame_meter.set_process(false)
		frame_meter_button.text = "SHOW FPS"
	else:
		frame_meter.start()
		frame_meter_button.text = "HIDE FPS"
	close_menu()


func set_status(message: String, is_error: bool = false) -> void :
	if status_label == null:
		return
	status_label.text = message.to_upper()
	status_label.add_theme_color_override("font_color", DEV_RED if is_error else MINT)


func command_ids() -> PackedStringArray:
	return PackedStringArray(ALL_COMMAND_IDS)


func minimum_touch_targets_are_valid() -> bool:
	if toggle_button == null or toggle_button.custom_minimum_size.y < TOUCH_TARGET_MIN:
		return false
	for child in _all_descendants(action_content):
		if child is Button and (child as Button).custom_minimum_size.y < TOUCH_TARGET_MIN:
			return false
	return true


func apply_iphone_layout_for_test(viewport_size: Vector2) -> Dictionary:
	_apply_layout(viewport_size, Vector4.ZERO)
	return layout_snapshot()


func layout_snapshot() -> Dictionary:
	return {
		"viewport": _last_viewport_size,
		"safe_insets": _last_safe_insets,
		"toggle_rect": Rect2(toggle_button.position, toggle_button.size),
		"drawer_rect": Rect2(drawer.position, drawer.size),
		"open": drawer.visible,
		"command_count": ALL_COMMAND_IDS.size(),
		"touch_targets_valid": minimum_touch_targets_are_valid(),
		"finger_scroll": scroll != null and scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_SHOW_NEVER,
		"button_font_size": 13,
	}


func _process(_delta: float) -> void :
	if _reset_armed_until_msec <= 0:
		set_process(false)
		return
	if Time.get_ticks_msec() >= _reset_armed_until_msec:
		_disarm_reset()


func _build_toggle() -> void :
	toggle_button = Button.new()
	toggle_button.name = "DeveloperToolsToggle"
	toggle_button.text = "DEV TOOLS"
	toggle_button.tooltip_text = "Open developer tools · isolated save"
	toggle_button.custom_minimum_size = Vector2(124, 54)
	toggle_button.focus_mode = Control.FOCUS_NONE
	toggle_button.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle_button.add_theme_font_size_override("font_size", 14)
	toggle_button.add_theme_color_override("font_color", INK)
	toggle_button.add_theme_color_override("font_hover_color", INK)
	toggle_button.add_theme_color_override("font_pressed_color", Color("fff6dc"))
	toggle_button.add_theme_stylebox_override("normal", _panel_style(GOLD, GOLD_BRIGHT, 12, 2, 8))
	toggle_button.add_theme_stylebox_override("hover", _panel_style(GOLD_BRIGHT, Color.WHITE, 12, 2, 8))
	toggle_button.add_theme_stylebox_override("pressed", _panel_style(Color("6f342e"), DEV_RED, 12, 2, 8))
	toggle_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	toggle_button.pressed.connect(toggle_menu)
	add_child(toggle_button)


func _build_drawer() -> void :
	drawer = PanelContainer.new()
	drawer.name = "DeveloperToolsDrawer"
	drawer.mouse_filter = Control.MOUSE_FILTER_STOP
	drawer.add_theme_stylebox_override("panel", _panel_style(PANEL_FILL, GOLD, 16, 2, 10))
	add_child(drawer)

	var margin: = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	drawer.add_child(margin)

	var shell: = VBoxContainer.new()
	shell.add_theme_constant_override("separation", 7)
	margin.add_child(shell)

	var header: = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	shell.add_child(header)

	var heading_stack: = VBoxContainer.new()
	heading_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_stack.add_theme_constant_override("separation", 0)
	header.add_child(heading_stack)

	var title: = _label("DEVELOPER TOOLS", 19, GOLD_BRIGHT)
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_color_override("font_outline_color", Color("030806"))
	heading_stack.add_child(title)

	var isolation: = _label("ISOLATED DEV SAVE · PRODUCTION UNTOUCHED", 12, MUTED)
	heading_stack.add_child(isolation)

	var close_button: = Button.new()
	close_button.name = "CloseDeveloperTools"
	close_button.text = "✕"
	close_button.tooltip_text = "Close developer tools"
	close_button.custom_minimum_size = Vector2(52, 52)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 18)
	close_button.add_theme_color_override("font_color", GOLD_BRIGHT)
	close_button.add_theme_stylebox_override("normal", _panel_style(Color("10251a"), Color(GOLD, 0.56), 10, 1, 4))
	close_button.add_theme_stylebox_override("hover", _panel_style(Color("183626"), GOLD, 10, 1, 4))
	close_button.add_theme_stylebox_override("pressed", _panel_style(Color("4b2824"), DEV_RED, 10, 1, 4))
	close_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	close_button.pressed.connect(close_menu)
	header.add_child(close_button)
	frame_meter_button = _action_button("SHOW FPS", "toggle_fps", false)
	frame_meter_button.name = "ToggleFPS"
	frame_meter_button.remove_meta("dev_command")
	frame_meter_button.custom_minimum_size = Vector2(108, 58)
	frame_meter_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	frame_meter_button.tooltip_text = "Measure frame times while playing"
	frame_meter_button.pressed.connect(toggle_frame_meter)
	header.add_child(frame_meter_button)

	status_label = _label("SWIPE UP OR DOWN · DEV SAVE ONLY", 12, MINT)
	status_label.name = "DeveloperStatus"
	status_label.custom_minimum_size.y = 24
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shell.add_child(status_label)

	var rule: = HSeparator.new()
	rule.add_theme_stylebox_override("separator", _line_style(Color(GOLD, 0.34)))
	shell.add_child(rule)

	scroll = preload("res://scripts/ui/touch_scroll_container.gd").new()
	scroll.name = "DeveloperActionsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED


	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.scroll_deadzone = 3
	scroll.follow_focus = true
	shell.add_child(scroll)

	action_content = VBoxContainer.new()
	action_content.name = "DeveloperActions"
	action_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_content.add_theme_constant_override("separation", 8)
	scroll.add_child(action_content)

	_add_action_category("PROGRESSION PRESETS", PRESET_ACTIONS, true)
	_add_action_category("EXACT LOCATION JUMPS", LOCATION_ACTIONS, true)
	_add_action_category("RESOURCES & TOOLS", RESOURCE_ACTIONS, false)
	_add_action_category("RELICS & HUB", HUB_ACTIONS, false)
	_add_reset_category()
	drawer.visible = false


func _add_action_category(title_text: String, actions: Array, close_after: bool) -> void :
	var title: = _label(title_text, 13, GOLD_BRIGHT)
	title.custom_minimum_size.y = 25
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	action_content.add_child(title)

	var grid: = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	action_content.add_child(grid)

	for action_value in actions:
		var action: Dictionary = action_value
		var label_text: = String(action.get("label", "DEV ACTION"))
		var command: = String(action.get("command", ""))
		var button: = _action_button(label_text, command)
		button.pressed.connect(_on_action_pressed.bind(command, close_after, label_text))
		grid.add_child(button)


func _add_reset_category() -> void :
	var title: = _label("DEV SAVE", 13, Color("ff9f98"))
	title.custom_minimum_size.y = 25
	title.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	action_content.add_child(title)

	reset_button = _action_button("RESET DEV SAVE", "reset_dev", true)
	reset_button.add_theme_color_override("font_color", Color("ffd7d4"))
	reset_button.add_theme_color_override("font_hover_color", Color.WHITE)
	reset_button.add_theme_stylebox_override("normal", _panel_style(Color("2b1514"), Color(DEV_RED, 0.72), 10, 1, 7))
	reset_button.add_theme_stylebox_override("hover", _panel_style(Color("4a201d"), DEV_RED, 10, 2, 7))
	reset_button.add_theme_stylebox_override("pressed", _panel_style(Color("701e19"), Color("ff9b94"), 10, 2, 7))
	reset_button.pressed.connect(_on_reset_pressed)
	action_content.add_child(reset_button)


func _action_button(label_text: String, command: String, full_width: bool = false) -> Button:
	var button: = Button.new()
	button.name = command.to_pascal_case()
	button.text = label_text
	button.tooltip_text = "%s · %s" % [label_text.replace("\n", " "), command]
	button.set_meta("dev_command", command)
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if full_width:
		button.custom_minimum_size.x = 220
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	button.add_theme_color_override("font_color", MINT)
	button.add_theme_color_override("font_hover_color", GOLD_BRIGHT)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color("030806"))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_stylebox_override("normal", _panel_style(Color("0d2619"), Color(GOLD, 0.48), 10, 1, 7))
	button.add_theme_stylebox_override("hover", _panel_style(Color("153824"), GOLD, 10, 2, 7))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("41401b"), GOLD_BRIGHT, 10, 2, 7))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return button


func _on_action_pressed(command: String, close_after: bool, label_text: String) -> void :
	if not ALL_COMMAND_IDS.has(command):
		set_status("UNKNOWN DEV COMMAND · %s" % command, true)
		return
	_disarm_reset()
	set_status("APPLYING · %s" % label_text.replace("\n", " "))
	command_requested.emit(command)
	if close_after:
		close_menu()


func _on_reset_pressed() -> void :
	var now: = Time.get_ticks_msec()
	if _reset_armed_until_msec > now:
		_reset_armed_until_msec = 0
		reset_button.text = "RESETTING DEV SAVE…"
		command_requested.emit("reset_dev")
		close_menu()
		return
	_reset_armed_until_msec = now + RESET_CONFIRM_WINDOW_MSEC
	reset_button.text = "TAP AGAIN TO CONFIRM"
	set_status("RESET ARMED · TAP AGAIN WITHIN 4 SECONDS", true)
	set_process(true)


func _disarm_reset() -> void :
	_reset_armed_until_msec = 0
	set_process(false)
	if reset_button != null:
		reset_button.text = "RESET DEV SAVE"


func _apply_platform_safe_area(size_override: Vector2 = Vector2.ZERO) -> void :
	var viewport_rect: Rect2 = get_viewport().get_visible_rect()
	var viewport_size: Vector2 = size_override if size_override != Vector2.ZERO else viewport_rect.size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var insets: = Vector4.ZERO
	if size_override == Vector2.ZERO and (OS.has_feature("ios") or OS.has_feature("android")):
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
	_apply_layout(viewport_size, insets)


func _apply_layout(viewport_size: Vector2, safe_insets: Vector4) -> void :
	if toggle_button == null or drawer == null:
		return
	_last_viewport_size = viewport_size
	_last_safe_insets = safe_insets
	var outer_gap: = 12.0
	var compact: = viewport_size.y < 520.0
	var toggle_size: = Vector2(116.0 if compact else 132.0, TOUCH_TARGET_MIN if compact else 58.0)
	var origin: = Vector2(safe_insets.x + outer_gap, safe_insets.y + outer_gap)
	toggle_button.position = origin
	toggle_button.size = toggle_size

	var drawer_top: = origin.y + toggle_size.y + 8.0
	var available_width: = maxf(300.0, viewport_size.x - origin.x - safe_insets.z - outer_gap)
	var preferred_width: = viewport_size.x * (0.72 if compact else 0.56)
	var minimum_width: = minf(420.0, available_width)
	var drawer_width: = minf(720.0, minf(available_width, maxf(minimum_width, preferred_width)))
	var available_height: = maxf(210.0, viewport_size.y - drawer_top - safe_insets.w - outer_gap)
	drawer.position = Vector2(origin.x, drawer_top)
	drawer.size = Vector2(drawer_width, available_height)

	var action_height: = 58.0 if compact else 64.0
	for child in _all_descendants(action_content):
		if child is Button and child != reset_button:
			(child as Button).custom_minimum_size.y = action_height
	if reset_button != null:
		reset_button.custom_minimum_size.y = action_height


func _all_descendants(parent: Node) -> Array[Node]:
	var result: Array[Node] = []
	if parent == null:
		return result
	var pending: Array[Node] = [parent]
	while not pending.is_empty():
		var current: Node = pending.pop_back()
		for child in current.get_children():
			result.append(child)
			pending.append(child)
	return result


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label: = Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
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


func _line_style(color: Color) -> StyleBoxLine:
	var style: = StyleBoxLine.new()
	style.color = color
	style.thickness = 1
	return style
