extends Control
## Opt-in, bounded and reversible. Never writes gameplay state or diagnostic settings to saves.
signal completed(report: Dictionary)
const STAGES = [
	{"id":"original", "title":"Original", "seconds":40.0},
	{"id":"pet_off", "title":"Pet lights off", "seconds":10.0},
	{"id":"restore_pet", "title":"Restored", "seconds":10.0},
	{"id":"shadows_off", "title":"Shadows off", "seconds":10.0},
	{"id":"restore_shadows", "title":"Restored", "seconds":10.0},
	{"id":"lights_off", "title":"All lights off", "seconds":10.0},
	{"id":"restore_lights", "title":"Restored", "seconds":10.0},
	{"id":"half_resolution", "title":"Half resolution", "seconds":10.0},
	{"id":"restore_resolution", "title":"Restored", "seconds":10.0},
]
var game: Node
var world: Node2D
var running := false
var start_error := ""
var stage_index := -1
var result: Dictionary = {}
var rows: Array[Dictionary] = []
var baseline: Dictionary = {}
var lights: Array[Dictionary] = []
var samples: Array[Vector2] = []
var early: Dictionary = {}
var stage_started := 0
var started := 0
var previous := 0
var last_ui := 0
var original_window := Vector2i.ZERO
var phase := ""
var mine_id := ""
var browser: Dictionary = {}
var status_panel: PanelContainer
var result_panel: PanelContainer
var status_label: Label
var cancel_button: Button
var result_box: VBoxContainer
var _ui_unit := 1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	get_viewport().size_changed.connect(_layout)
	set_process(false)
	hide()

func start(main: Node) -> bool:
	start_error = ""
	if running or not OS.has_feature("ever_deeper_dev"):
		start_error = "Diagnostic unavailable or already running"; return false
	game = main
	phase = String(game.get("phase"))
	mine_id = String(game.get("current_mine_id"))
	if phase not in ["hub", "depth"] or (phase == "depth" and int(RunState.current_depth) != 2):
		start_error = "Start in the hub or Depth 2"; return false
	world = game.get("hub_world" if phase == "hub" else "depth_world")
	if world == null:
		start_error = "Wait for the area to load"; return false
	if OS.has_feature("web"):
		var begin_status: Variant = JavaScriptBridge.eval("JSON.stringify(!!(window.everDeeperRenderProbe && window.everDeeperRenderProbe.begin()))")
		if begin_status != "true":
			start_error = "Open the latest DEV page and keep it visible"
			return false
	lights.clear()
	for node in world.find_children("*", "Light2D", true, false):
		var pet_light := false
		var ancestor: Node = node
		while ancestor != world and ancestor != null:
			if ancestor.name == "MoleCompanion": pet_light = true
			ancestor = ancestor.get_parent()
		lights.append({"node":node, "enabled":node.enabled, "shadow":node.shadow_enabled, "pet":pet_light})
	original_window = DisplayServer.window_get_size()
	rows.clear()
	early = {}
	result = {}
	stage_index = -1
	started = Time.get_ticks_usec()
	running = true
	baseline = _snapshot()
	result_panel.hide()
	status_panel.show()
	show()
	_layout()
	set_process(true)
	_next_stage()
	return true

func cancel(reason: String = "Cancelled") -> void:
	if running: _finish(reason)

func _notification(what: int) -> void:
	if running and what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		cancel("App interrupted")

func _exit_tree() -> void:
	if running:
		_restore()
		if OS.has_feature("web"): JavaScriptBridge.eval("window.everDeeperRenderProbe?.cancel('Diagnostic closed')")

func _process(_delta: float) -> void:
	if not running: return
	if not is_instance_valid(world) or String(game.get("phase")) != phase or String(game.get("current_mine_id")) != mine_id or (phase == "depth" and int(RunState.current_depth) != 2) or bool(game.get("menu_open")):
		cancel("Area or menu changed"); return
	var now := Time.get_ticks_usec()
	var elapsed := float(now - stage_started) / 1000000.0
	if previous > 0 and elapsed >= 2.0:
		samples.append(Vector2(float(now), float(now - previous) / 1000.0))
		if samples.size() > 4096: samples = samples.slice(512)
	previous = now
	if stage_index == 0 and elapsed >= 10.0 and early.is_empty(): early = _measurement()
	if now - last_ui >= 250000:
		last_ui = now
		browser = _browser_snapshot()
		if not String(browser.get("abort_reason", "")).is_empty():
			cancel(String(browser.abort_reason)); return
		status_label.text = "FPS TEST · %d/%d · %s\nStand still · %ds left in this step" % [stage_index + 1, STAGES.size(), STAGES[stage_index].title, maxi(0, ceili(float(STAGES[stage_index].seconds) - elapsed))]
	if elapsed >= float(STAGES[stage_index].seconds):
		var row := _measurement()
		row["stage"] = STAGES[stage_index].id
		row["title"] = STAGES[stage_index].title
		row["elapsed_seconds"] = float(now - started) / 1000000.0
		rows.append(row)
		_next_stage()

func _next_stage() -> void:
	_restore_lights()
	stage_index += 1
	if stage_index == STAGES.size():
		_finish(""); return
	var id: String = STAGES[stage_index].id
	for entry in lights:
		var light: Light2D = entry.node
		if not is_instance_valid(light): continue
		if id == "pet_off" and bool(entry.pet): light.enabled = false
		if id == "lights_off": light.enabled = false
		if id == "shadows_off": light.shadow_enabled = false
	if OS.has_feature("web"):
		var stage_status: Variant = JavaScriptBridge.eval("JSON.stringify(window.everDeeperRenderProbe.stage(%s))" % ("0.5" if id == "half_resolution" else "1"))
		if stage_status != "true":
			cancel("Browser diagnostic stopped"); return
	else:
		get_window().size = original_window / 2 if id == "half_resolution" else original_window
	samples.clear()
	stage_started = Time.get_ticks_usec()
	previous = 0
	last_ui = 0

func _restore_lights() -> void:
	for entry in lights:
		if is_instance_valid(entry.node):
			entry.node.enabled = entry.enabled
			entry.node.shadow_enabled = entry.shadow

func _restore() -> void:
	_restore_lights()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.everDeeperRenderProbe?.cancel('')")
	elif original_window != Vector2i.ZERO:
		get_window().size = original_window

func settings_restored() -> bool:
	for entry in lights:
		if is_instance_valid(entry.node) and (entry.node.enabled != entry.enabled or entry.node.shadow_enabled != entry.shadow): return false
	if OS.has_feature("web"):
		var info := _browser_snapshot()
		var expected := Vector2(roundf(float(info.get("css_width", 0)) * float(info.get("dpr", 1))), roundf(float(info.get("css_height", 0)) * float(info.get("dpr", 1))))
		return is_equal_approx(float(info.get("scale", 0.0)), 1.0) and Vector2(float(info.get("width", 0)), float(info.get("height", 0))) == expected
	return DisplayServer.window_get_size() == original_window

func _finish(reason: String) -> void:
	running = false
	set_process(false)
	_restore()
	result = {"revision":1, "version":"0.46.9-dev.5", "area":phase, "mine":game.get("current_mine_id"),
		"cancelled":not reason.is_empty(), "reason":reason, "duration_seconds":float(Time.get_ticks_usec() - started) / 1000000.0,
		"baseline":baseline, "early":early, "rows":rows.duplicate(true), "web":OS.has_feature("web"), "settings_saved":false}
	_finalize.call_deferred()

func _finalize() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	result["graphics_restored"] = settings_restored()
	result["final"] = _snapshot()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.everDeeperRenderProbe.finish(" + JSON.stringify(result) + ")")
	status_panel.hide()
	_show_result()
	completed.emit(result)

func _browser_snapshot() -> Dictionary:
	if not OS.has_feature("web"): return {}
	var raw: Variant = JavaScriptBridge.eval("JSON.stringify(window.everDeeperRenderProbe?.snapshot() || {})")
	if raw is String:
		var value: Variant = JSON.parse_string(raw)
		if value is Dictionary: return value
	return {}

func _snapshot() -> Dictionary:
	var info := _browser_snapshot()
	var size := DisplayServer.window_get_size()
	var enabled := 0
	var shadows := 0
	var pet := 0
	for entry in lights:
		if is_instance_valid(entry.node) and entry.node.enabled:
			enabled += 1
			if entry.node.shadow_enabled: shadows += 1
			if entry.pet: pet += 1
	return {"canvas_width":int(info.get("width", size.x)), "canvas_height":int(info.get("height", size.y)),
		"dpr":float(info.get("dpr", 1)), "raf_fps":float(info.get("raf_fps", 0)), "raf_frames":int(info.get("raf_frames", 0)),
		"raf_p95_ms":float(info.get("raf_p95_ms", 0)), "lights":enabled, "shadows":shadows, "pet_lights":pet,
		"cpu_ms":Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))}

func _measurement() -> Dictionary:
	var values: Array[float] = []
	var cutoff := float(Time.get_ticks_usec() - 8000000)
	var total := 0.0
	for sample in samples:
		if sample.x >= cutoff:
			values.append(sample.y)
			total += sample.y
	values.sort()
	var data := _snapshot()
	data["frames"] = values.size()
	data["fps"] = values.size() * 1000.0 / total if total > 0 else 0.0
	data["p95_ms"] = values[clampi(ceili(values.size() * 0.95) - 1, 0, values.size() - 1)] if not values.is_empty() else 0.0
	return data

func _label(text_value: String, font_size: int = 16) -> Label:
	var label := Label.new()
	label.text = text_value
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color("fff0c5"))
	label.add_theme_font_size_override("font_size", roundi(font_size * _ui_unit))
	return label

func _button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(110, 48) * _ui_unit
	button.add_theme_font_size_override("font_size", roundi(16 * _ui_unit))
	return button

func _panel() -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("081710ee")
	style.border_color = Color("d7b45a")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	return panel

func _build_ui() -> void:
	status_panel = _panel()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	status_panel.add_child(row)
	status_label = _label("FPS TEST")
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(status_label)
	cancel_button = _button("CANCEL")
	cancel_button.pressed.connect(cancel)
	row.add_child(cancel_button)
	result_panel = _panel()
	result_box = VBoxContainer.new()
	result_panel.add_child(result_box)
	result_panel.hide()

func _layout() -> void:
	if status_panel == null: return
	var view := get_viewport().get_visible_rect().size
	var info := _browser_snapshot()
	var css_height := float(info.get("css_height", DisplayServer.window_get_size().y))
	_ui_unit = view.y / maxf(1.0, css_height)
	var width := minf(view.x - 32 * _ui_unit, 620 * _ui_unit)
	status_label.add_theme_font_size_override("font_size", roundi(15 * _ui_unit))
	cancel_button.custom_minimum_size = Vector2(104, 48) * _ui_unit
	cancel_button.add_theme_font_size_override("font_size", roundi(15 * _ui_unit))
	status_panel.size = Vector2(width, 64 * _ui_unit)
	status_panel.position = Vector2((view.x - width) / 2.0, view.y - status_panel.size.y - 12 * _ui_unit)
	result_panel.size.x = width
	result_panel.position = Vector2((view.x - width) / 2.0, maxf(6 * _ui_unit, (view.y - result_panel.size.y) / 2.0))

func _show_result() -> void:
	for child in result_box.get_children():
		result_box.remove_child(child)
		child.queue_free()
	_layout()
	result_box.add_theme_constant_override("separation", roundi(3 * _ui_unit))
	result_box.add_child(_label("FPS TEST · " + String(result.version), 18))
	result_box.add_child(_label("%s · Start %.1f FPS · %ds" % ["HUB" if phase == "hub" else "DEPTH 2", float(early.get("fps", 0)), roundi(float(result.duration_seconds))], 13))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", roundi(18 * _ui_unit))
	grid.add_theme_constant_override("v_separation", roundi(2 * _ui_unit))
	result_box.add_child(grid)
	for text_value in ["STEP", "FPS", "RAF", "P95 ms"]: grid.add_child(_label(text_value, 13))
	for row in rows:
		var stage_label := _label(String(row.title), 14)
		stage_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(stage_label)
		for text_value in ["%.1f" % row.fps, "%.1f" % row.raf_fps if row.raf_frames > 0 else "—", "%.0f" % row.p95_ms]: grid.add_child(_label(text_value, 14))
	var message := "Original graphics restored · Send a screenshot"
	if bool(result.cancelled): message = String(result.reason) + " · Graphics restored"
	if not bool(result.graphics_restored): message = "Restoration failed · Reload the page"
	result_box.add_child(_label(message, 13))
	var close := _button("CLOSE")
	close.pressed.connect(hide)
	result_box.add_child(close)
	result_panel.show()
	_recenter_result.call_deferred()

func _recenter_result() -> void:
	result_panel.size.y = result_panel.get_combined_minimum_size().y
	_layout()
