extends "res://scripts/qa/suites/dev14_review.gd"
var native_owner: Node
var native_vp: SubViewport
var native_key: DirectionalLight3D
var original_update: int = 0
var original_atlas: int = 0
var requested_atlas: int = 0
var native_mode: String = "baseline"
var owner_id: int = 0
var rig_id: int = 0
var vp_id: int = 0
var light_refs: Array[Node] = []
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
		"native_setup":
			native_owner = main._active_player_node().visual._native_worn
			native_vp = native_owner.rig.viewport
			var keys: Array[Node] = native_vp.find_children("*","DirectionalLight3D",true,false)
			_require(keys.size()==1, "Expected one native key light")
			if keys.size()!=1: return
			native_key = keys[0] as DirectionalLight3D
			_require(native_key.shadow_enabled and native_vp.size==Vector2i(400,400), "Wrong native baseline")
			original_update = native_vp.render_target_update_mode
			original_atlas = int(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/size"))
			requested_atlas = original_atlas
			owner_id = native_owner.get_instance_id()
			rig_id = native_owner.rig.get_instance_id()
			vp_id = native_vp.get_instance_id()
			light_refs = main.surface_world.find_children("*","Light2D",true,false)
		"native_mode":
			native_mode = String(data.value)
			native_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED if native_mode=="render_off" else original_update
			native_key.shadow_enabled = native_mode!="shadow_off"
			requested_atlas = 2048 if native_mode=="atlas2048" else original_atlas
			RenderingServer.directional_shadow_atlas_set_size(requested_atlas, bool(ProjectSettings.get_setting_with_override("rendering/lights_and_shadows/directional_shadow/16_bits")))
		"facing": main.surface_world.player.set_facing(_direction(String(data.value)))
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
	JavaScriptBridge.eval("window.DEV14_STATE="+JSON.stringify({"id":command_id,"error":error,"version":main.PremiumMenuScript.release_version(),"phase":main.phase,"cap":Engine.max_fps,"native":main._active_player_node().visual.native_worn_snapshot(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"cpu_ms":Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,"physics_ms":Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"video_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"result":result,"native_info":_native_info()}),true)

func _native_info() -> Dictionary:
	if not is_instance_valid(native_vp): return {}
	var lights: Array = []
	for node in light_refs:
		lights.append([node.get_instance_id(), node.enabled, node.is_visible_in_tree(), node.shadow_enabled])
	return {"stable":native_owner.get_instance_id()==owner_id and native_owner.rig.get_instance_id()==rig_id and native_vp.get_instance_id()==vp_id,"mode":native_mode,"updates":native_owner.updates,"generations":native_owner.generations,"update_mode":native_vp.render_target_update_mode,"original_update":original_update,"size":[native_vp.size.x,native_vp.size.y],"msaa":native_vp.msaa_3d,"shadow":native_key.shadow_enabled,"key_energy":native_key.light_energy,"key_color":str(native_key.light_color),"original_atlas":original_atlas,"requested_atlas":requested_atlas,"mobile_feature":OS.has_feature("mobile"),"web_ios_feature":OS.has_feature("web_ios"),"lights2d":lights,"shadow_primitives":native_vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"total_primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}

