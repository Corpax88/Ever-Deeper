extends "res://scripts/qa/suites/dev14_review.gd"
## Explicit nonpersistent DEV fixture. Reference uses the original draw path.
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
			world.queue_redraw()
			main._refresh_hud()
			for node in world.find_children("PremiumHeadlamp", "", true, false):
				node.preview_settings.clear()
				node.refresh_workshop_effects()
		"strip":
			world.terrain_strip_width = clampi(int(data.width), 1, 6)
			world.terrain_draw_generation += 1
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
			world.blocks.erase(edits.cell)
			world.mineable_edge_void_cells[edits.cell] = true
			world.queue_redraw()
		"restore":
			world.blocks[edits.cell] = edits.block.duplicate(true)
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
			profiling = true
		"end":
			profiling = false
			last_result = {"frames":frame_times.size(),"seconds":float(Time.get_ticks_usec()-elapsed_start)/1000000.0,"frame":_stats(frame_times),"cpu":_stats(cpu_times),"sections":world.lit_draw_sections.debug_snapshot(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
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
	if profiling:
		frame_times.append(float(now-last_tick)/1000.0)
		cpu_times.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000.0)
		last_tick = now
	if main.achievement_toast != null: main.achievement_toast.clear()
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
	JavaScriptBridge.eval("window.DEV14_STATE="+JSON.stringify({"id":command_id,"error":error,"fixture":fixture,"version":main.PremiumMenuScript.release_version(),"phase":main.phase,"menu":main.menu_open,"native":player.visual.native_worn_snapshot(),"impact":packet.impact_serial,"mining":packet.mining,"position":[player.position.x,player.position.y],"result":last_result,"sections":world.lit_draw_sections.debug_snapshot(),"mine_button":[point.x,point.y],"strip_width":world.terrain_strip_width,"viewport":[main.get_viewport().get_visible_rect().size.x,main.get_viewport().get_visible_rect().size.y]}),true)

