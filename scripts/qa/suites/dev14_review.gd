extends "res://scripts/qa/qa_context.gd"
## Explicit automated fixture on the ordinary main scene. Never used by normal play.
var command_id: int = 0
var fixture: String = "menu"
var error: String = ""
var sample_clock: float = 0.0
var previous_usec: int = 0
var samples: Array = []
var steering_frame: int = -1
var steering_samples: int = 0
var steering_clipped: int = 0
var steering_margin: int = 400

func run() -> void:
	if not OS.has_feature("ever_deeper_dev") or not OS.has_feature("web"):
		push_error("DEV14 review requires the exported graphical DEV build")
		main.get_tree().quit(2)
		return
	RunState.reset_run(false)
	# Persistence was skipped by automated startup; now exercise normal menu paths.
	main.automated_mode = false
	main._open_start_menu()
	main.get_tree().process_frame.connect(_frame)
	previous_usec = Time.get_ticks_usec()

func _gear(gear: String, outfit: String = "miner") -> void:
	RunState.begin_state_batch()
	RunState.pickaxe_level = int({"worn":1,"iron":2,"runed":3,"moonglass":4,"ember":5}.get(gear,5))
	RunState.set_drill_level(int({"burrower":1,"pulse":2,"deepcore":3}.get(gear,0)))
	RunState.starforge_variant = String({"crusher":"crusher","comet":"swift","crown":"prospector"}.get(gear,""))
	RunState.endless_tool_style = "original"
	RunState.endless_outfit = outfit
	RunState.end_state_batch()
	main._active_player_node()._update_visual(false)

var canvas_observers: Array[Node] = []

func _command(data: Dictionary) -> void:
	command_id = int(data.id)
	var kind: String = data.kind
	if kind in ["canvas_reference", "canvas_candidate", "canvas_resume"]:
		var owner: Node = main._active_player_node().visual._native_worn
		if kind == "canvas_reference":
			Engine.time_scale = 0.0
			main.get_tree().paused = true
			for node in main.get_tree().root.find_children("*", "", true, false):
				if node.can_process() and node.is_processing():
					canvas_observers.append(node)
					node.set_process(false)
			RenderingServer.viewport_set_disable_2d(owner.rig.viewport.get_viewport_rid(), false)
		elif kind == "canvas_candidate": owner._refresh_canvas_pass()
		else:
			Engine.time_scale = 1.0
			for node in canvas_observers:
				if is_instance_valid(node): node.set_process(true)
			canvas_observers.clear()
			main.get_tree().paused = false
		fixture = kind
		return
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	Input.action_release("mine")
	error = ""
	steering_frame = -1
	match kind:
		"steering":
			main._dev_jump_mine("mossMine",1)
			_gear(String(data.get("gear","worn")))
			main.mine_world.restore_position(Vector2(230,640))
			steering_frame = 0
			steering_samples = 0
			steering_clipped = 0
			steering_margin = 400
		"surface_regressions": _surface_regressions()
		"moss":
			main._dev_jump_mine("mossMine", 1)
			_gear(String(data.get("gear","worn")))
			if bool(data.get("rush",false)): main.mine_world.mining_rush_remaining = 20.0
			if not _place_moss(_direction(data.direction)): error = "No ordinary Moss target for " + str(data.direction)
		"endless":
			main._dev_jump_endless(int(data.get("depth",1)))
			_gear(String(data.get("gear","worn")))
			if not _place_endless(_direction(data.direction)): error = "No ordinary Endless target for " + str(data.direction)
		"surface":
			main._dev_jump_surface()
			_gear("worn")
			main.surface_world.restore_position(Vector2(600,700))
			main.surface_world.player.set_facing(Vector2.UP)
		"hub":
			main._dev_jump_hub()
			_gear("worn")
		"depth":
			main._dev_jump_mine("mossMine",2)
			_gear("worn")
		"deepheart":
			main._dev_jump_deepheart()
			_gear("worn")
		"gear": _gear(String(data.gear),String(data.get("outfit","miner")))
		"pause": main._open_start_menu()
		"resume":
			main._hide_start_menu()
			main._resume_current_phase()
	fixture = kind
	main._refresh_hud()
	samples.clear()

func _direction(value: String) -> Vector2:
	return {"up":Vector2.UP,"down":Vector2.DOWN,"left":Vector2.LEFT,"right":Vector2.RIGHT}[value]

func _place_moss(direction: Vector2) -> bool:
	var world: Node2D = main.mine_world
	for cell in world.blocks:
		if not world.blocks[cell] is Dictionary: continue
		if String(world.blocks[cell].get("kind","")) == "bedrock" or int(world.blocks[cell].get("requires_tool",0)) > 1: continue
		for distance in [64.0,80.0,96.0]:
			var position: Vector2 = world._cell_center(cell)-direction*distance
			world.restore_position(position)
			if world.player.global_position.distance_to(position)>2.0: continue
			world.player.set_facing(direction)
			if world._find_mine_target() == cell:
				world.target_dirty = true
				return true
	return false

func _place_endless(direction: Vector2) -> bool:
	var world: Node2D = main.endless_world
	for index in world.resources.size():
		var resource: Dictionary = world.resources[index]
		if bool(resource.mined): continue
		for distance in [54.0,64.0,76.0,90.0]:
			var position: Vector2 = Vector2(resource.position)-direction*distance
			world.restore_position(position)
			if world.player.global_position.distance_to(position)>2.0: continue
			world.player.set_facing(direction)
			if world._nearest_resource_index() == index: return true
	return false

func _health() -> float:
	var total: float = 0.0
	if main.phase == "mine":
		for block in main.mine_world.blocks.values():
			if block is Dictionary: total += float(block.get("hp",0.0))
	elif main.phase == "endless":
		for resource in main.endless_world.resources:
			if not bool(resource.mined): total += float(resource.get("hp",0.0))
	elif main.phase == "surface": total = float(main.surface_world.ore_mountain_hp)
	return total

func _frame() -> void:
	# Fixture unlock bursts must not cover the hero during visual inspection.
	if main.achievement_toast != null: main.achievement_toast.clear()
	var now: int = Time.get_ticks_usec()
	sample_clock += float(now-previous_usec)/1000000.0
	previous_usec = now
	var raw: Variant = JavaScriptBridge.eval("window.DEV14_COMMAND||''",true)
	if raw is String and not raw.is_empty():
		JavaScriptBridge.eval("window.DEV14_COMMAND=''",true)
		var data: Variant = JSON.parse_string(raw)
		if data is Dictionary: _command(data)
	if steering_frame >= 0 and steering_frame < 92:
		if steering_frame >= 20:
			main._on_joystick_movement(Vector2.RIGHT.rotated(.06 if steering_frame % 2 == 0 else -.06))
			var owner: Node = main.mine_world.player.visual._native_worn
			if owner != null and is_instance_valid(owner.rig):
				var rect: Rect2i = owner.rig.viewport.get_texture().get_image().get_used_rect()
				var size: Vector2i = owner.rig.viewport.size
				var margin: int = mini(mini(rect.position.x,rect.position.y),mini(size.x-rect.end.x,size.y-rect.end.y))
				steering_samples += 1
				steering_margin = mini(steering_margin,margin)
				if rect.size == Vector2i.ZERO or margin <= 0: steering_clipped += 1
		steering_frame += 1
		if steering_frame == 92:
			main._on_joystick_movement(Vector2.ZERO)
			_require(steering_samples == 72 and steering_clipped == 0,"Continuous touch steering clipped the hero")
	var native_request: Variant = JavaScriptBridge.eval("window.DEV14_CAPTURE_NATIVE||''",true)
	if native_request is String and not native_request.is_empty():
		JavaScriptBridge.eval("window.DEV14_CAPTURE_NATIVE=''",true)
		_capture_native(native_request)
	if sample_clock < 0.10: return
	sample_clock = 0.0
	var player: Node2D = main._active_player_node()
	var packet: Dictionary = player.animation_packet()
	var native: Dictionary = player.visual.native_worn_snapshot()
	var native_canvas: Dictionary = {}
	if bool(native.get("active", false)):
		var viewport: SubViewport = player.visual._native_worn.rig.viewport
		native_canvas = {"items":viewport.find_children("*", "CanvasItem", true, false).size(), "size":viewport.size, "update_mode":viewport.render_target_update_mode}
	var active_rigs: int = 0
	for world in [main.surface_world,main.mine_world,main.depth_world,main.hub_world,main.deepheart_world,main.endless_world]:
		if bool(world.player.visual.native_worn_snapshot().active): active_rigs += 1
	var point: Vector2 = main.mine_button.get_global_rect().get_center()
	var state: Dictionary = {"id":command_id,"fixture":fixture,"error":error,"version":main.PremiumMenuScript.release_version(),
		"steering":{"done":steering_frame==92,"samples":steering_samples,"clipped":steering_clipped,"margin":steering_margin},
		"render":{"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)},
		"phase":main.phase,"menu":main.menu_open,"persistence_active":main.persistence_active,
		"health":_health(),"position":[player.global_position.x,player.global_position.y],
		"mining":packet.mining,"progress":packet.progress,"hit_phase":packet.hit_phase,"cycle":packet.cycle_duration,
		"target_valid":packet.target_valid,"swing":packet.swing_serial,"impact":packet.impact_serial,"impact_target_valid":packet.impact_target_valid,
		"gear":player.visual.active_gear,"pickaxe_level":int(RunState.pickaxe_level),"drill_level":int(RunState.drill_level),"world_active":bool(player.get_parent().active),"native":native,"native_canvas":native_canvas,"active_rigs":active_rigs,
		"mine_button":[point.x,point.y],"viewport":[main.get_viewport().get_visible_rect().size.x,main.get_viewport().get_visible_rect().size.y]}
	JavaScriptBridge.eval("window.DEV14_STATE="+JSON.stringify(state),true)


func _require(condition: bool, message: String) -> void:
	if not condition:
		error = message
		push_error("DEV14_REGRESSION: " + message)

func _surface_regressions() -> void:
	main._dev_jump_surface()
	_gear("worn")
	RunState.unlock_world("moonglass")
	var world: Node2D = main.surface_world
	var player: Node2D = world.player
	# Reproduce a nearby inactive owner's false followed by active mountain true.
	world.active_context = "moonglass_mountain"
	var mountain: Dictionary = world.surface_resource_mountains[world.active_context]
	mountain.swing_active = true
	mountain.swing_duration = 0.72
	mountain.swing_elapsed = 0.1
	player.set_mining_visual(true,0.1/0.72)
	var serial: int = player.animation_swing_serial
	mountain.swing_elapsed = 0.2
	world._update_moonglass_resource(0.01)
	player.set_mining_visual(true,0.2/0.72)
	_require(player.animation_swing_serial == serial,"Inactive Surface publication restarted the committed swing")
	_require(player.animation_target_valid,"Inactive Surface publication lost committed target")
	mountain.swing_active = false
	player.set_mining_visual(false)
	# Successful node damage must retain its own target through automatic retarget.
	world.active_context = "moonglass_resource"
	world.moon_bloom_swing_active = true
	world.moon_bloom_swing_duration = 0.72
	world.moon_bloom_swing_elapsed = 0.1
	world.moon_bloom_target_index = 0
	world.moon_bloom_nodes[0].hp = 1
	player.set_mining_visual(true,0.1/0.72)
	serial = player.animation_swing_serial
	var target: Vector2 = player.animation_target_position
	var impact: int = int(player.animation_packet().impact_serial)
	world.moon_bloom_swing_elapsed = 0.3
	player.set_mining_visual(true,0.3/0.72)
	world._mine_moonglass_resource_once()
	_require(int(player.animation_packet().impact_serial)==impact+1,"Moon Bloom omitted earned impact")
	world.moon_bloom_swing_elapsed = 0.4
	player.set_mining_visual(true,0.4/0.72)
	_require(player.animation_swing_serial==serial and player.animation_target_position==target,"Moon Bloom redirected committed recovery")
	_require(player.animation_impact_target_valid and player.animation_impact_target==target,"Moon Bloom lost earned target")
	world.moon_bloom_target_index = -1
	world.moon_bloom_swing_elapsed = 0.5
	player.set_mining_visual(true,0.5/0.72)
	_require(player.animation_swing_serial==serial and player.animation_target_valid and player.animation_target_position==target,"Last-node break canceled committed recovery")
	world.moon_bloom_swing_active = false
	player.set_mining_visual(false)
	world.active_context = ""
	main._dev_jump_surface()

func _capture_native(request_id: String) -> void:
	# Capture the actual final viewport after rendering, unobscured by HUD/text.
	# Used only by this explicit nonpersistent exported-game QA suite.
	await RenderingServer.frame_post_draw
	var player: Node2D = main._active_player_node()
	var owner: Node = player.visual._native_worn
	if owner == null or not is_instance_valid(owner.rig): return
	var image: Image = owner.rig.viewport.get_texture().get_image()
	var used: Rect2i = image.get_used_rect()
	var capture: Dictionary = {"id":request_id,"gear":player.visual.active_gear,"native":owner.snapshot(),"used_rect":[used.position.x,used.position.y,used.size.x,used.size.y],"png":Marshalls.raw_to_base64(image.save_png_to_buffer())}
	JavaScriptBridge.eval("window.DEV14_NATIVE_CAPTURE="+JSON.stringify(capture),true)
