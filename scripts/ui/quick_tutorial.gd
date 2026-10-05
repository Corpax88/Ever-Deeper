class_name QuickTutorial
extends Control
## One task at a time, in the existing goal panel. Time never completes a lesson.
signal closed
const GOLD = Color("ffe3a0")
const SAVE_PATH = "user://quick_tutorial.cfg"
const DEV_SAVE_PATH = "user://quick_tutorial_dev.cfg"
const SEEN_KEY = "seen_guidance_v1"
var _touch_mode := false
var _step := 0
var _running := false
var _replay := false
var _advanced := false
var _main: Node
var _premium_hud: Control
var _skip: Button
var _elapsed := 0.0
var _poll := 0.0
var _last_position := Vector2.ZERO
var _last_phase := ""
var _distance := 0.0
var _collected := false
var _paused := false
var _focus := Rect2()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 80
	_main = get_tree().current_scene
	_premium_hud = get_parent().get_node_or_null("PremiumHud")
	_skip = Button.new()
	_skip.text = "SKIP GUIDE"
	_skip.flat = true
	_skip.add_theme_font_size_override("font_size", 20)
	_skip.add_theme_color_override("font_color", Color("c6c8b8"))
	_skip.tooltip_text = "Replay from Settings > Controls"
	_skip.pressed.connect(func(): _finish(true))
	add_child(_skip)
	RunState.resource_collected.connect(_on_resource_collected)
	visible = false

func _save_path() -> String:
	return DEV_SAVE_PATH if OS.has_feature("ever_deeper_dev") or "--qa-dev-tools" in OS.get_cmdline_user_args() else SAVE_PATH

func has_been_seen() -> bool:
	if _paused and _replay: return false
	var config := ConfigFile.new()
	config.load(_save_path())
	# Existing developed expeditions must not be forced through beginner lessons.
	return bool(config.get_value("tutorial", SEEN_KEY, false)) or int(RunState.pickaxe_level) > 1

func reset_for_new_run() -> void:
	_running = false
	visible = false
	_step = 0
	_replay = false
	_paused = false
	_store(false)

func replay(touch_mode: bool) -> void:
	_step = 0
	_replay = true
	_paused = false
	open(touch_mode)

func open(touch_mode: bool) -> void:
	_main = get_tree().current_scene
	_touch_mode = touch_mode
	if not _replay:
		var config := ConfigFile.new()
		config.load(_save_path())
		_step = clampi(int(config.get_value("tutorial", "step", 0)), 0, 4)
	_advanced = int(RunState.pickaxe_level) > 1
	if not _paused: _collected = RunState.cargo_count() > 0 if not _replay else false
	_paused = false
	_distance = 0.0
	_last_phase = String(_main.phase)
	_last_position = _main._active_player_node().global_position
	_elapsed = 0.0
	_running = true
	visible = true
	_refresh()

func dismiss() -> void:
	# Menu interruption retains progress, unlike skipping or completing.
	if _running:
		_paused = true
		_finish(false)

func _on_resource_collected(_kind: String, amount: int) -> void:
	if _running and amount > 0: _collected = true

func on_bag_opened() -> void:
	if _running and _step == 3: _advance()
	visible = false

func keeps_hud_control(control: Control) -> bool:
	if not _running or _main.menu_open or _main.inventory_open or _main._shop_panel_is_open(): return false
	return control == _premium_hud.progression_goal_panel or (_step == 3 and control in [_premium_hud.bag_button, _premium_hud.bag_count])

func routing_goal() -> Dictionary:
	if not is_teaching() or _step not in [1, 2]: return {}
	var phase: String = _main.phase
	return {"objective_id":"learn:mine", "kind":"depth_resource" if phase == "depth" else "mine_resource",
		"mine_id":String(_main.current_mine_id) if phase in ["mine", "depth"] else "mossMine", "title":"Enter a mine"}

func is_teaching() -> bool:
	return _running and visible

func prioritizes_learning() -> bool:
	return is_teaching() and _step < 4

func owns_world_focus() -> bool:
	return is_teaching() and _step in [0, 3]

func goal_override(goal: Dictionary) -> Dictionary:
	if not is_teaching(): return goal
	var result: Dictionary = goal.duplicate(true) if _step == 4 else {}
	var count := 4 if _advanced else 5
	var title: String = ["Move your miner", "Enter the mine", "Collect your first ore", "Check your bag", "Forge Iron Pickaxe"][_step]
	var action := ""
	match _step:
		0: action = "Drag the left side to move" if _touch_mode else "Use WASD / arrows to move"
		1: action = ("Tap DESCEND" if _touch_mode else "Press E / F to enter") if String(_main.surface_context).begins_with("enter:") else ("Follow the gold marker" if String(_main.phase) == "surface" else "Follow the marker back to a mine")
		2: action = ("Hold MINE beside ore" if _touch_mode else "Hold SPACE beside ore") if String(_main.phase) in ["mine", "depth", "endless"] else "Follow the marker to a mine"
		3: action = "Tap BAG to inspect your ore"
		4: action = String(goal.get("hud_action", "Mine & sell · Mossvein"))
	result["objective_id"] = "onboarding:" + str(_step)
	result["hud_title"] = "%d/%d · %s" % [_step + 1, count, title]
	result["title"] = result.hud_title
	result["hud_action"] = action
	return result

func _process(delta: float) -> void:
	if not _running or not is_instance_valid(_main): return
	# Observe Bag before suppressing teaching behind the inventory itself.
	if _step == 3 and bool(_main.inventory_open):
		_advance()
	if not _running: return
	var blocked: bool = _main.menu_open or _main.inventory_open or _main._shop_panel_is_open() or _main.orientation_guard_active or _main.conclusion_overlay.visible
	visible = not blocked
	if blocked: return
	_elapsed += delta
	_poll += delta
	if _poll < 0.1: return
	_poll = 0.0
	var player: Node2D = _main._active_player_node()
	var phase: String = _main.phase
	if player != null:
		var distance := player.global_position.distance_to(_last_position)
		if phase == _last_phase and distance < 100.0: _distance += distance
		_last_position = player.global_position
		_last_phase = phase
	match _step:
		0:
			if _distance >= 80.0: _advance()
		1:
			if phase in ["mine", "depth", "endless"]: _advance()
		2:
			if _collected: _advance()
		4:
			if int(RunState.pickaxe_level) >= 2: _finish(true)
	if _running:
		_refresh()

func _advance() -> void:
	_step += 1
	_elapsed = 0.0
	if _step >= (4 if _advanced else 5):
		_finish(true)
		return
	_store(false)
	_refresh()

func _refresh() -> void:
	if _premium_hud == null: return
	_premium_hud.set_progression_goal(_main._progression_goal())
	var panel: Control = _premium_hud.progression_goal_panel
	_skip.size = Vector2(152, 70)
	_skip.position = Vector2(panel.position.x + panel.size.x - _skip.size.x, panel.position.y + panel.size.y + 8.0)
	_focus = Rect2()
	var control: Control
	match _step:
		0:
			if _touch_mode:
				var view := get_viewport_rect().size
				_focus = Rect2(Vector2(view.x * 0.14, view.y * 0.72), Vector2(144, 112))
		1:
			if String(_main.surface_context).begins_with("enter:"): control = _premium_hud.context_button
		2:
			if String(_main.phase) == "mine" and _main.mine_world.current_target.x >= 0: control = _main.mine_button
			elif String(_main.phase) in ["depth", "endless"]: control = _main.mine_button
		3: control = _premium_hud.bag_button
	if control != null and control.is_visible_in_tree():
		_focus = control.get_global_rect().grow(6.0)
	queue_redraw()

func _draw() -> void:
	if not _focus.has_area(): return
	# Two restrained pulses on step entry, then a steady outline. Never dim the world.
	var alpha := 0.85 + 0.15 * sin(_elapsed * TAU) if _elapsed < 2.0 else 0.85
	draw_style_box(_outline(Color(0.02, 0.025, 0.02, 0.85), 6), _focus)
	draw_style_box(_outline(Color(GOLD, alpha), 2), _focus)

func _outline(color: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color.TRANSPARENT
	box.border_color = color
	box.set_border_width_all(width)
	box.set_corner_radius_all(18)
	return box

func _store(seen: bool) -> void:
	if _replay: return
	var config := ConfigFile.new()
	config.load(_save_path())
	config.set_value("tutorial", SEEN_KEY, seen)
	config.set_value("tutorial", "step", _step)
	config.save(_save_path())

func _finish(mark_seen: bool) -> void:
	_store(mark_seen)
	if mark_seen:
		_paused = false
		_replay = false
	_running = false
	visible = false
	_focus = Rect2()
	if _premium_hud != null: _premium_hud.set_progression_goal(_main._progression_goal())
	closed.emit()

func debug_snapshot() -> Dictionary:
	return {"visible":is_teaching(), "running":_running,"step":_step,"touch_mode":_touch_mode,
		"item_count":1,"has_background":true,"input_blocking":false,
		"strip_rect":_premium_hud.progression_goal_panel.get_global_rect() if _premium_hud != null else Rect2(),
		"focus_rect":_focus,"skip_rect":_skip.get_global_rect(),"replay":_replay}
