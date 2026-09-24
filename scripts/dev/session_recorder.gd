extends Node
## DEV only, passive five-second windows. No graphics or gameplay mutations.
signal changed
var game: Node
var running := false
var previous := 0
var total_ms := 0.0
var elapsed_ms := 0.0
var frames: Array[float] = []
var cpu_total := 0.0
var cpu_max := 0.0
var physics_total := 0.0
var moving := 0
var mining := 0
var menu_frames := 0
var context_key := ""
var context: Dictionary = {}
var tracked_player: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)
	game = get_tree().current_scene

func start() -> bool:
	if running or not OS.has_feature("ever_deeper_dev") or not OS.has_feature("web"): return false
	var ok: Variant = JavaScriptBridge.eval("window.everDeeperReports?.begin(" + JSON.stringify(preload("res://scripts/ui/premium_menu.gd").release_version()) + ") || false")
	if ok != true: return false
	running = true
	total_ms = 0.0
	_reset_window()
	context_key = ""
	set_process(true)
	changed.emit()
	return true

func stop(reason: String = "stopped") -> void:
	if not running: return
	_flush()
	running = false
	set_process(false)
	JavaScriptBridge.eval("window.everDeeperReports?.finish(" + JSON.stringify(reason) + ")")
	changed.emit()

func _reset_window() -> void:
	previous = 0
	elapsed_ms = 0.0
	frames.clear()
	cpu_total = 0.0
	cpu_max = 0.0
	physics_total = 0.0
	moving = 0
	mining = 0
	menu_frames = 0

func _notification(what: int) -> void:
	if not running: return
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		stop("app_interrupted")

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var key := "%s:%s:%d" % [game.phase, game.current_mine_id, RunState.current_depth]
	if key != context_key:
		_flush()
		context_key = key
		context = {"phase":String(game.phase), "mine":String(game.current_mine_id), "depth":maxi(0, RunState.current_depth)}
		tracked_player = game._active_player_node()
		_reset_window()
	if previous == 0:
		previous = now
		return
	var ms := float(now - previous) / 1000.0
	previous = now
	frames.append(ms)
	elapsed_ms += ms
	total_ms += ms
	var cpu := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	cpu_total += cpu
	cpu_max = maxf(cpu_max, cpu)
	physics_total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var player: Node = tracked_player
	if is_instance_valid(player):
		if player.is_actually_moving(): moving += 1
		if bool(player.animation_active): mining += 1
	if bool(game.menu_open) or game.developer_menu.is_open(): menu_frames += 1
	if elapsed_ms >= 5000.0 or frames.size() >= 1800: _flush()
	if total_ms >= 600000.0: stop("ten_minute_limit")

func _flush() -> void:
	if frames.is_empty(): return
	frames.sort()
	var count := frames.size()
	var slow := 0
	for ms in frames:
		if ms > 33.34: slow += 1
	var row := context.duplicate()
	row.merge({"seconds":total_ms / 1000.0, "window_ms":elapsed_ms, "frames":count,
		"fps":count * 1000.0 / maxf(0.01, elapsed_ms), "p95_ms":frames[clampi(ceili(count * 0.95) - 1, 0, count - 1)],
		"max_ms":frames[-1], "slow_frames":slow, "cpu_mean_ms":cpu_total / count, "cpu_max_ms":cpu_max,
		"physics_mean_ms":physics_total / count, "moving_fraction":float(moving) / count,
		"mining_fraction":float(mining) / count, "menu_fraction":float(menu_frames) / count,
		"draw_calls":int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)),
		"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"video_mib":maxf(0.0, Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0),
		"tool":"", "lights":0, "shadows":0, "pet_lights":0, "drops":0})
	var player: Node = tracked_player
	if is_instance_valid(player):
		row.tool = String(player.visual.active_gear)
		var world: Node = player.get_parent()
		for light in world.find_children("*", "Light2D", true, false):
			if not light.enabled or not light.is_visible_in_tree(): continue
			row.lights += 1
			if light.shadow_enabled: row.shadows += 1
			var ancestor: Node = light
			while ancestor != null and ancestor != world:
				if ancestor.name == "MoleCompanion":
					row.pet_lights += 1
					break
				ancestor = ancestor.get_parent()
		# Only read drops on worlds that declare them; never read the save dictionary.
		if String(context.get("phase", "")) in ["mine", "depth"]:
			var drops_value: Variant = world.get("drops")
			if drops_value is Array: row.drops = drops_value.size()
	var accepted: Variant = JavaScriptBridge.eval("window.everDeeperReports?.append(" + JSON.stringify(row) + ") || false")
	var last_tick := previous
	_reset_window()
	previous = last_tick
	if accepted != true:
		running = false
		set_process(false)
		changed.emit()
