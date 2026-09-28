extends "res://scripts/qa/suites/fixes_native_base.gd"

const CpuFixture = preload("res://scripts/qa/suites/fixes_cpu_fixture.gd")
var fixes_result: Dictionary = {}
var fixes_clock: int = 0
var fixes_recorder: RefCounted = CpuFixture.new()

func _command(data: Dictionary) -> void:
	command_id = int(data.id)
	match String(data.kind):
		"fixes_cpu": fixes_result = CpuFixture.new().run(main)
		"fixes_record_start": fixes_result = fixes_recorder.record_start(main)
		"fixes_record_end": fixes_result = fixes_recorder.record_finish()
		"fixes_endless":
			super._command({"kind":"endless","id":data.id,"depth":1,"gear":"ember","direction":"up"})
			_fix_endless_target("up")
		"fixes_retarget": _fix_endless_target("right")
		"fixes_mine":
			super._command({"kind":"moss", "id":data.id, "gear":"ember", "direction":String(data.get("direction","up"))})
			var cell: Vector2i = main.mine_world._find_mine_target()
			_require(main.mine_world.blocks.has(cell), "No durable mining target")
			if main.mine_world.blocks.has(cell):
				main.mine_world.blocks[cell].hp = 100000000.0
				main.mine_world.blocks[cell].max_hp = 100000000.0
			_fix_center()
		"fixes_center": _fix_center()
		"fixes_menu_resume":
			main._hide_start_menu()
			main._resume_current_phase()
		"fixed_pose":
			_require(main.get_tree().paused, "Fixed-pose capture must be frozen")
			var owner: Node = main._active_player_node().visual._native_worn
			var pose: Dictionary = owner.motion.sample(String(data.family), float(data.phase))
			pose = owner.motion.rotate_pose(pose, float(data.angle))
			owner.rig.root_native = Vector3.ZERO
			owner.rig.shown = pose.bones
			owner.rig._apply(pose.bones)
			owner.equipment.apply_pose()
		"capture": _capture_native(String(data.request))
		_: super._command(data)

func _fix_endless_target(direction: String) -> void:
	_require(_place_endless(_direction(direction)), "No contour mining target")
	var index: int = main.endless_world._nearest_resource_index()
	_require(index >= 0, "Missing durable contour target")
	if index >= 0: main.endless_world.resources[index].hp = 100000000.0
	_fix_center()

func _fix_center() -> void:
	var player: Node = main._active_player_node()
	player.camera.limit_left = -100000
	player.camera.limit_right = 100000
	player.camera.limit_top = -100000
	player.camera.limit_bottom = 100000
	player.camera.position_smoothing_enabled = false
	player.camera.reset_smoothing()

func _frame() -> void:
	if main.achievement_toast != null: main.achievement_toast.clear()
	super._frame()
	if fixes_recorder.recording: fixes_recorder.record_frame(main,main.get_process_delta_time())
	var now: int = Time.get_ticks_usec()
	if now-fixes_clock<200000: return
	fixes_clock = now
	var player: Node = main._active_player_node()
	var packet: Dictionary = player.animation_packet()
	var point: Vector2 = main.mine_button.get_global_rect().get_center()
	var screen: Vector2 = player.get_global_transform_with_canvas().origin
	var viewport: Vector2 = main.get_viewport().get_visible_rect().size
	JavaScriptBridge.eval("window.FIXES_STATE="+JSON.stringify({"id":command_id,"result":fixes_result,"menu":main.menu_open,"mining":packet.mining,"impact":packet.impact_serial,"swing":packet.swing_serial,"health":_health(),"position":[player.global_position.x,player.global_position.y],"screen":[screen.x,screen.y],"mine_button":[point.x,point.y],"viewport":[viewport.x,viewport.y],"depth_prepass":ProjectSettings.get_setting_with_override("rendering/driver/depth_prepass/enable")}),true)
