extends "res://scripts/qa/suites/dev14_review.gd"
## Explicit nonpersistent DEV fixture. Reference uses the original draw path.
const QAProfile = preload("res://qa_profile.gd")
var route_active: bool = false
var route_started: int = 0
var travelled: float = 0.0
var moving_frames: int = 0
var mining_frames: int = 0
var route_last: Vector2
var initial_blocks: int = 0
var trace: Array = []
var profiling: bool = false
var frame_times: Array[float] = []
var cpu_times: Array[float] = []
var elapsed_start: int = 0
var last_tick: int = 0
var last_result: Dictionary = {}
var edits: Dictionary = {}
var paused_observers: Array[Node] = []

func _command(data: Dictionary) -> void:
	command_id = int(data.id)
	fixture = String(data.kind)
	var world: Node2D = main.mine_world
	match fixture:
		"setup":
			route_active = false
			RunState.initialize_persistence("user://qa_active_mining.sav")
			_restore_observers()
			main.get_tree().paused = false
			main._cancel_mine_hold()
			RunState.reset_run(false)
			RunState.world_seed = 4608
			seed(4608)
			main._dev_jump_mine(String(data.get("mine", "emberMine")), 1)
			_gear("ember")
			_require(_place_moss(Vector2.RIGHT), "No accessible mining target")
			world.player.camera.position_smoothing_enabled = false
			world.player.camera.reset_smoothing()
			world.cache_terrain_draws = true
			world.lit_draw_sections.reject_transparent_pixels = not bool(data.get("cached", true))
			world.lit_draw_sections.profile_draws = true
			if bool(data.get("durable", false)):
				var cell: Vector2i = world._find_mine_target()
				world.blocks[cell].hp = 100000
				world.blocks[cell].max_hp = 100000
			world.qa_stable_strips = bool(data.get("stable", false))
			world.queue_redraw()
			main._refresh_hud()
			for node in world.find_children("PremiumHeadlamp", "", true, false):
				node.preview_settings.clear()
				node.refresh_workshop_effects()
		"route":
			route_active = true
			route_started = Time.get_ticks_usec()
			route_last = world.player.position
		"route_stop":
			route_active = false
			main._on_joystick_movement(Vector2.ZERO)
		"stable":
			world.qa_stable_strips = bool(data.enabled)
			world.queue_redraw()
		"freeze":
			# Pause-independent UI tweens also need zero delta for identical frames.
			Engine.time_scale = 0.0
			main.get_tree().paused = true
			# Minimap and guide pulse even while paused. Stop their clocks too;
			# preserve every pixel instead of masking/tolerating animated regions.
			for node in main.get_tree().root.find_children("*", "", true, false):
				if node.can_process() and node.is_processing():
					paused_observers.append(node)
					node.set_process(false)
		"reference", "cached":
			world.lit_draw_sections.reject_transparent_pixels = fixture == "reference"
			world.queue_redraw()
		"style":
			for node in world.find_children("PremiumHeadlamp", "", true, false):
				node.preview_settings = {"style":String(data.style),"range_multiplier":2.0,"energy_multiplier":1.5}
				node.refresh_workshop_effects()
			world.get_node("CaveLightOccluders").refresh()
			world.queue_redraw()
		"damage":
			var cell: Vector2i = world._find_mine_target()
			edits = {"cell":cell,"block":world.blocks[cell].duplicate(true),"void":world.mineable_edge_void_cells.has(cell)}
			world.blocks[cell].hp = 1
			world.queue_redraw()
		"break":
			world._erase_block(edits.cell)
			world.mineable_edge_void_cells[edits.cell] = true
			world.queue_redraw()
		"restore":
			world._set_block(edits.cell, edits.block.duplicate(true))
			if not edits.void: world.mineable_edge_void_cells.erase(edits.cell)
			world.queue_redraw()
		"begin":
			main.get_tree().paused = false
			frame_times.clear()
			cpu_times.clear()
			world.lit_draw_sections.draw_callbacks = 0
			world.lit_draw_sections.draw_callback_usec = 0
			world.lit_draw_sections.setup_usec = 0
			world.lit_draw_sections.cached_redraws = 0
			world.lit_draw_sections.cached_reuses = 0
			elapsed_start = Time.get_ticks_usec()
			last_tick = elapsed_start
			travelled = 0.0
			moving_frames = 0
			mining_frames = 0
			trace.clear()
			initial_blocks = world.blocks.size()
			QAProfile.reset()
			QAProfile.enabled = bool(data.get("instrument", true))
			profiling = true
		"end":
			profiling = false
			QAProfile.enabled = false
			last_result = {"frames":frame_times.size(),"seconds":float(Time.get_ticks_usec()-elapsed_start)/1000000.0,"frame":_stats(frame_times),"cpu":_stats(cpu_times),"sections":world.lit_draw_sections.debug_snapshot(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"profile":QAProfile.stats.duplicate(true),"events":QAProfile.events.duplicate(true),"trace":trace.duplicate(),"distance":travelled,"moving_frames":moving_frames,"mining_frames":mining_frames,"blocks_removed":initial_blocks-world.blocks.size(),"save_error":RunState.last_save_error}
		"unfreeze":
			_restore_observers()
			main.get_tree().paused = false

func _restore_observers() -> void:
	Engine.time_scale = 1.0
	for node in paused_observers:
		if is_instance_valid(node): node.set_process(true)
	paused_observers.clear()

func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {}
	var ordered: Array[float] = values.duplicate()
	ordered.sort()
	var sum: float = 0.0
	var slow: int = 0
	for value in values:
		sum += value
		if value > 33.333: slow += 1
	return {"mean_ms":sum/values.size(),"p95_ms":ordered[mini(ordered.size()-1,int(ordered.size()*0.95))],"max_ms":ordered.back(),"over_33_ms":slow}

func _frame() -> void:
	var now: int = Time.get_ticks_usec()
	if route_active and not main.get_tree().paused:
		var t: float = fposmod(float(now-route_started)/1000000.0, 90.0)
		var direction: Vector2 = Vector2.RIGHT if t < 25.0 else (Vector2.LEFT if t < 35.0 else (Vector2.DOWN if t < 65.0 else (Vector2.UP if t < 75.0 else Vector2.RIGHT)))
		main._on_joystick_movement(direction)
	if profiling:
		var p: Node2D = main.mine_world.player
		travelled += p.position.distance_to(route_last)
		route_last = p.position
		if p.is_actually_moving(): moving_frames += 1
		if bool(p.animation_active): mining_frames += 1
		trace.append([Engine.get_process_frames(),now,float(now-last_tick)/1000.0,p.position.x,p.position.y,main.mine_world.blocks.size()])
		frame_times.append(float(now-last_tick)/1000.0)
		cpu_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		last_tick = now
	var raw: Variant = JavaScriptBridge.eval("window.DEV14_COMMAND||''",true)
	if raw is String and not raw.is_empty():
		JavaScriptBridge.eval("window.DEV14_COMMAND=''",true)
		var data: Variant = JSON.parse_string(raw)
		if data is Dictionary: _command(data)
	# Keep observer cost small and equal in reference/candidate windows.
	if now - previous_usec < 200000: return
	previous_usec = now
	var world: Node2D = main.mine_world
	var player: Node2D = main._active_player_node()
	var packet: Dictionary = player.animation_packet()
	var point: Vector2 = main.mine_button.get_global_rect().get_center()
	JavaScriptBridge.eval("window.DEV14_STATE="+JSON.stringify({"id":command_id,"error":error,"fixture":fixture,"version":main.PremiumMenuScript.release_version(),"phase":main.phase,"menu":main.menu_open,"native":player.visual.native_worn_snapshot(),"impact":packet.impact_serial,"mining":packet.mining,"position":[player.position.x,player.position.y],"result":last_result,"sections":world.lit_draw_sections.debug_snapshot(),"mine_button":[point.x,point.y],"viewport":[main.get_viewport().get_visible_rect().size.x,main.get_viewport().get_visible_rect().size.y]}),true)

