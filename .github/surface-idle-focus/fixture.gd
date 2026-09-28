extends "res://scripts/qa/suites/dev14_review.gd"
var hidden_backgrounds: Array[CanvasItem] = []
var background_mode: bool = false
var frozen_nodes: Array[Node] = []

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
		"freeze":
			Engine.time_scale = 0.0
			main.get_tree().paused = true
			for node in main.get_tree().root.find_children("*","",true,false):
				if node.can_process() and node.is_processing():
					frozen_nodes.append(node)
					node.set_process(false)
		"background_off":
			for node in main.surface_world.find_children("*","Sprite2D",true,false):
				var shader: ShaderMaterial = node.material as ShaderMaterial
				if shader != null and shader.shader.resource_path.ends_with("biome_backdrop.gdshader") and node.visible:
					hidden_backgrounds.append(node)
					node.hide()
			if main.surface_world.surface_parallax.visible:
				hidden_backgrounds.append(main.surface_world.surface_parallax)
				main.surface_world.surface_parallax.hide()
			background_mode = true
		"restore":
			for node in hidden_backgrounds: node.show()
			hidden_backgrounds.clear()
			background_mode = false

func _frame() -> void:
	var raw: Variant = JavaScriptBridge.eval("window.DEV14_COMMAND||''",true)
	if raw is String and not raw.is_empty():
		JavaScriptBridge.eval("window.DEV14_COMMAND=''",true)
		var data: Variant = JSON.parse_string(raw)
		if data is Dictionary: _command(data)
	var now: int = Time.get_ticks_usec()
	if now-previous_usec<200000: return
	previous_usec = now
	JavaScriptBridge.eval("window.DEV14_STATE="+JSON.stringify({"id":command_id,"error":error,"version":main.PremiumMenuScript.release_version(),"phase":main.phase,"mode":"background_off" if background_mode else "baseline","hidden":hidden_backgrounds.size(),"native":main.surface_world.player.visual.native_worn_snapshot(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"cpu_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"position":main.surface_world.player.position}),true)
