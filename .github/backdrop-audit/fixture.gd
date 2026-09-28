extends "res://scripts/qa/suites/dev14_review.gd"
const CropProbe = preload("res://scripts/qa/backdrop_crop_probe.gd")
var crop_probe = CropProbe.new()
var crop_state: Dictionary = {}
var measuring: bool = false
var measured_usec: int = 0
var frame_previous: int = 0
var frame_intervals: Array = []
var start_drawn: int = 0
var start_process: int = 0
var start_physics: int = 0
var result: Dictionary = {}
var frozen: Array[Node] = []

func _command(data: Dictionary) -> void:
	command_id = int(data.id)
	fixture = String(data.kind)
	match fixture:
		"surface_setup":
			RunState.reset_run(false)
			RunState.area_unlocked = true
			RunState.emberdeep_unlocked = true
			RunState.fourth_unlocked = true
			main.game_started = true
			main._hide_start_menu()
			main._deactivate_worlds()
			main.phase = "surface"
			_gear("ember")
			main.surface_world.set_active(true)
			main.surface_world.restore_position(Vector2(3130,700))
			main.surface_world.player.camera.position_smoothing_enabled = false
			main.surface_world.player.camera.reset_smoothing()
			main._refresh_hud()
			if main.quick_tutorial != null: main.quick_tutorial.dismiss()
		"crop_setup":
			_require(crop_probe.configure(main.surface_world), "Backdrop setup: "+str(crop_probe.errors))
			crop_state = crop_probe.snapshot()
		"crop":
			_require(crop_probe.set_crop(bool(data.value)), "Backdrop invariants: "+str(crop_probe.snapshot()))
			crop_state = crop_probe.snapshot()
		"position":
			var player: Node = main.surface_world.player
			player.global_position = Vector2(float(data.x),700)
			player.camera.reset_smoothing()
			player.camera.force_update_scroll()
		"cap": Engine.max_fps = int(data.value)
		"begin":
			result.clear()
			frame_intervals.clear()
			measured_usec = Time.get_ticks_usec()
			frame_previous = measured_usec
			start_drawn = Engine.get_frames_drawn()
			start_process = Engine.get_process_frames()
			start_physics = Engine.get_physics_frames()
			measuring = true
		"end":
			measuring = false
			var elapsed: float = float(Time.get_ticks_usec()-measured_usec)/1000.0
			frame_intervals.sort()
			result = {"elapsed_ms":elapsed,"drawn":Engine.get_frames_drawn()-start_drawn,"process":Engine.get_process_frames()-start_process,"physics":Engine.get_physics_frames()-start_physics,"intervals_ms":frame_intervals.duplicate(),"cap":Engine.max_fps}
		"freeze":
			Engine.time_scale = 0.0
			main.get_tree().paused = true
			for node in main.get_tree().root.find_children("*","",true,false):
				if node.can_process() and node.is_processing():
					frozen.append(node)
					node.set_process(false)
		"resume":
			Engine.time_scale = 1.0
			for node in frozen:
				if is_instance_valid(node): node.set_process(true)
			frozen.clear()
			main.get_tree().paused = false
		_: super._command(data)

func _frame() -> void:
	var now: int = Time.get_ticks_usec()
	if measuring:
		frame_intervals.append(float(now-frame_previous)/1000.0)
		frame_previous = now
	var raw: Variant = JavaScriptBridge.eval("window.DEV14_COMMAND||''",true)
	if raw is String and not raw.is_empty():
		JavaScriptBridge.eval("window.DEV14_COMMAND=''",true)
		var data: Variant = JSON.parse_string(raw)
		if data is Dictionary: _command(data)
	if now-previous_usec<200000: return
	previous_usec = now
	JavaScriptBridge.eval("window.DEV14_STATE="+JSON.stringify({"id":command_id,"error":error,"version":main.PremiumMenuScript.release_version(),"phase":main.phase,"cap":Engine.max_fps,"native":main._active_player_node().visual.native_worn_snapshot(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"cpu_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"result":result,"crop":crop_state}),true)

