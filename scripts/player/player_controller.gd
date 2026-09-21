extends CharacterBody2D

signal moved(world_position: Vector2)
signal facing_changed(direction: Vector2)

const LegacyMiningContext = preload("res://scripts/player/legacy_mining_context.gd")

const CELL_SIZE: = 256.0
const FRAME_COUNT: = 6
const FRAME_DISTANCE: = 24.0
const MAX_FRAME_RATE: = 20.0

@onready var visual: Node2D = $Visual
@onready var camera: Camera2D = $Camera2D

var movement_speed: = 340.0
var world_size: = Vector2(4480, 1280)
var direction_name: = "down"
var animation_frame: = 0
var accumulated_distance: = 0.0
var accumulated_time: = 0.0
var facing_vector: = Vector2.DOWN
var external_movement: = Vector2.ZERO
var motion_resolver: = Callable()
var control_enabled: = true
var mining_visual_active: = false
var mining_visual_progress: = 0.0
var mining_visual_recoil: = 0.0
var _mining_impact_serial: int = 0
var _actual_moving: = false
var mining_strike_phase: = -1.0
var _last_strike_phase: = -2.0
var _resolver_idle_synced: = false
var _visual_state_initialized: = false
var _last_visual_direction: = ""
var _last_visual_frame: = -1
var _last_visual_moving: = false
var _last_visual_mining: = false
var _last_visual_progress: = -1.0
var _last_visual_recoil: = -1.0
var _last_visual_pickaxe_level: = -1
var _last_visual_drill_level: = -1
var _last_visual_starforge_variant: = ""
var _last_visual_outfit: = ""
var _last_visual_tool_style: = ""
var physics_tick_count: = 0
var motion_resolver_call_count: = 0
var motion_resolver_idle_skip_count: = 0
var visual_state_update_count: = 0
var visual_state_skip_count: = 0
# Presentation-only inputs. Cardinal facing and authoritative game timing stay
# with their existing owners; a renderer must never infer a new hit from these.
var animation_bearing: Vector2 = Vector2.DOWN
var animation_target_position: Vector2 = Vector2.ZERO
var animation_target_id: String = ""
var animation_target_valid: bool = false
var animation_swing_serial: int = 0
var animation_swing_continuation: bool = false
var animation_cycle_duration: float = 0.0
var animation_actual_motion: Vector2 = Vector2.ZERO
var animation_travelled_distance: float = 0.0
var animation_active: bool = false
var animation_progress: float = 0.0
var animation_hit_phase: float = -1.0
var animation_impact_swing_serial: int = 0
var animation_impact_target: Vector2 = Vector2.ZERO
var animation_impact_bearing: Vector2 = Vector2.DOWN
var animation_impact_target_valid: bool = false
var _legacy_elapsed: float = -1.0
var _legacy_context_active: bool = false
var _legacy_owner: String = ""


func _ready() -> void :
	_ensure_input_actions()


func configure(start_position: Vector2, bounds: Vector2, speed: float, resolver: Callable = Callable()) -> void :
	global_position = start_position
	world_size = bounds
	movement_speed = speed
	motion_resolver = resolver
	_resolver_idle_synced = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = roundi(world_size.x)
	camera.limit_bottom = roundi(world_size.y)
	camera.reset_smoothing()


func _physics_process(delta: float) -> void :
	physics_tick_count += 1
	var movement: = Vector2.ZERO
	if control_enabled:
		movement = (Input.get_vector("move_left", "move_right", "move_up", "move_down") + external_movement).limit_length(1.0)
	if movement.length_squared() > 0.0025:
		_update_aim(movement, true)
	var before: = global_position
	if motion_resolver.is_valid():
		var has_motion_intent: = not movement.is_zero_approx()
		if has_motion_intent or not _resolver_idle_synced:
			global_position = Vector2(motion_resolver.call(global_position, movement * movement_speed * delta))
			motion_resolver_call_count += 1
		else:
			motion_resolver_idle_skip_count += 1
		velocity = Vector2.ZERO
	else:
		velocity = movement * movement_speed
		move_and_slide()
		global_position = global_position.clamp(Vector2(24, 24), world_size - Vector2(24, 24))
	var actual_motion: = global_position - before
	animation_actual_motion = actual_motion
	animation_travelled_distance += actual_motion.length()
	_actual_moving = actual_motion.length_squared() > 0.001
	visual.advance_motion(actual_motion.length(), delta)
	if motion_resolver.is_valid():
		_resolver_idle_synced = movement.is_zero_approx() and actual_motion.length_squared() <= 0.001
	if actual_motion.length_squared() > 0.001:
		_update_walk_direction(actual_motion)
		_advance_animation(actual_motion.length(), delta)
		moved.emit(global_position)
	else:
		animation_frame = 0
		accumulated_distance = 0.0
		accumulated_time = 0.0
	_update_visual(actual_motion.length_squared() > 0.001)
	mining_visual_recoil = maxf(0.0, mining_visual_recoil - delta * 5.5)


func _update_walk_direction(motion: Vector2) -> void :
	if absf(motion.x) > absf(motion.y) * 1.15:
		direction_name = "right" if motion.x > 0.0 else "left"
	elif absf(motion.y) > absf(motion.x) * 1.15:
		direction_name = "down" if motion.y > 0.0 else "up"


func _update_aim(intent: Vector2, from_input: bool = false) -> void :
	set_animation_bearing(intent)
	if absf(intent.x) > absf(intent.y) * 1.15:
		direction_name = "right" if intent.x > 0.0 else "left"
	elif absf(intent.y) > absf(intent.x) * 1.15:
		direction_name = "down" if intent.y > 0.0 else "up"

	var next_facing: = Vector2.DOWN
	match direction_name:
		"left":
			next_facing = Vector2.LEFT
		"right":
			next_facing = Vector2.RIGHT
		"up":
			next_facing = Vector2.UP
	if next_facing == facing_vector:
		return
	if from_input:
		visual.cancel_pending_impact()
	facing_vector = next_facing
	facing_changed.emit(facing_vector)


func _advance_animation(distance: float, delta: float) -> void :
	accumulated_distance += distance
	accumulated_time += delta
	var distance_frames: = floori(accumulated_distance / FRAME_DISTANCE)
	var time_frames: = floori(accumulated_time * MAX_FRAME_RATE)
	var frames: = mini(distance_frames, time_frames)
	if frames <= 0:
		return
	animation_frame = (animation_frame + frames) % FRAME_COUNT
	accumulated_distance -= frames * FRAME_DISTANCE
	accumulated_time -= float(frames) / MAX_FRAME_RATE


func _update_visual(is_moving: bool) -> void :
	var next_progress: = clampf(mining_visual_progress, 0.0, 1.0)
	var next_pickaxe_level: = int(RunState.pickaxe_level)
	var next_drill_level: = int(RunState.drill_level)
	var next_starforge_variant: = String(RunState.starforge_variant)
	var next_outfit: String = RunState.endless_outfit
	var next_tool_style: String = RunState.endless_tool_style
	if (
		_visual_state_initialized
		and direction_name == _last_visual_direction
		and animation_frame == _last_visual_frame
		and is_moving == _last_visual_moving
		and mining_visual_active == _last_visual_mining
		and is_equal_approx(next_progress, _last_visual_progress)
		and is_equal_approx(mining_strike_phase, _last_strike_phase)
		and is_equal_approx(mining_visual_recoil, _last_visual_recoil)
		and next_pickaxe_level == _last_visual_pickaxe_level
		and next_drill_level == _last_visual_drill_level
		and next_starforge_variant == _last_visual_starforge_variant
		and next_outfit == _last_visual_outfit
		and next_tool_style == _last_visual_tool_style
	):
		visual_state_skip_count += 1
		return
	visual.set_state(direction_name, animation_frame, is_moving, mining_visual_active, next_progress, mining_visual_recoil, mining_strike_phase, _mining_impact_serial)
	_visual_state_initialized = true
	_last_visual_direction = direction_name
	_last_visual_frame = animation_frame
	_last_visual_moving = is_moving
	_last_visual_mining = mining_visual_active
	_last_visual_progress = next_progress
	_last_strike_phase = mining_strike_phase
	_last_visual_recoil = mining_visual_recoil
	_last_visual_pickaxe_level = next_pickaxe_level
	_last_visual_drill_level = next_drill_level
	_last_visual_starforge_variant = next_starforge_variant
	_last_visual_outfit = next_outfit
	_last_visual_tool_style = next_tool_style
	visual_state_update_count += 1


func set_mining_visual(active: bool, progress: float = 0.0, recoil: float = 0.0, strike_phase: float = -1.0) -> void :
	var presentation_active: bool = active
	if OS.has_feature("ever_deeper_dev"):
		presentation_active = _update_legacy_mining_context(active)
	if recoil > 0.0:
		_record_mining_presentation_impact()
	mining_strike_phase = strike_phase
	mining_visual_active = active
	animation_active = presentation_active
	animation_progress = clampf(progress, 0.0, 1.0)
	if strike_phase > 0.0: animation_hit_phase = strike_phase
	if not presentation_active: animation_target_valid = false
	mining_visual_progress = progress
	mining_visual_recoil = maxf(mining_visual_recoil, recoil)
	_update_visual(_actual_moving)


func _update_legacy_mining_context(active: bool) -> bool:
	var context: Dictionary = LegacyMiningContext.read(get_parent())
	# Nearby inactive Surface owners also publish false. The committed owner wins.
	if bool(context.get("locked",false)): active = bool(context.active)
	if not active:
		_legacy_context_active = false
		_legacy_elapsed = -1.0
		return false
	if context.is_empty(): return active # Endless already publishes its committed swing.
	if not context.has("target"):
		if context.has("elapsed"): _legacy_elapsed = float(context.elapsed)
		return active
	var owner: String = String(context.get("owner",get_parent().name))
	var next_elapsed: float = context.elapsed
	var same_target: bool = String(context.id) == animation_target_id and Vector2(context.target).is_equal_approx(animation_target_position)
	var wrapped: bool = next_elapsed + 0.000001 < _legacy_elapsed
	if not _legacy_context_active or not animation_target_valid or owner != _legacy_owner or wrapped:
		begin_mining_presentation(context.target, context.id, context.duration, context.hit, _legacy_context_active and owner == _legacy_owner and wrapped and same_target)
	animation_hit_phase = context.hit
	_legacy_owner = owner
	_legacy_elapsed = next_elapsed
	_legacy_context_active = true
	return active


func set_facing(direction: Vector2) -> void :
	if direction.length_squared() <= 0.001:
		return
	_update_aim(direction)
	_update_visual(false)


func set_animation_bearing(direction: Vector2) -> void:
	if direction.is_finite() and direction.length_squared() > .001:
		animation_bearing = direction.normalized()


func begin_mining_presentation(target: Vector2, target_id: String, cycle: float, hit_phase: float, continuation: bool = false) -> void:
	assert(target.is_finite() and is_finite(cycle) and cycle > 0.0)
	assert(hit_phase > 0.0 and hit_phase < 1.0)
	animation_swing_serial += 1
	animation_swing_continuation = continuation and animation_target_valid and target_id == animation_target_id and target.is_equal_approx(animation_target_position)
	animation_target_position = target
	animation_target_id = target_id
	animation_target_valid = true
	animation_cycle_duration = cycle
	animation_active = true
	animation_progress = 0.0
	animation_hit_phase = hit_phase
	set_animation_bearing(target-global_position)


func set_mining_presentation_elapsed(elapsed: float) -> void:
	assert(animation_target_valid and animation_cycle_duration > 0.0)
	animation_progress = clampf(elapsed/animation_cycle_duration, 0.0, 1.0)


func animation_packet() -> Dictionary:
	# Called by opt-in presentation consumers only. A new serial identifies an
	# interrupted/restarted swing even if no intermediate idle frame was drawn.
	return {"physics_tick": physics_tick_count, "world_position": global_position, "actual_motion": animation_actual_motion,
		"travelled_distance": animation_travelled_distance,
		"moving": _actual_moving, "bearing": animation_bearing,
		"mining": animation_active, "progress": animation_progress,
		"hit_phase": animation_hit_phase, "impact_serial": _mining_impact_serial,
		"impact_swing_serial": animation_impact_swing_serial,
		"impact_target_position": animation_impact_target, "impact_bearing": animation_impact_bearing,
		"impact_target_valid": animation_impact_target_valid,
		"swing_serial": animation_swing_serial, "swing_continuation": animation_swing_continuation, "cycle_duration": animation_cycle_duration,
		"mining_timing_valid": animation_target_valid and animation_active,
		"target_valid": animation_target_valid, "target_position": animation_target_position,
		"target_id": animation_target_id}


func set_external_movement(direction: Vector2) -> void :
	external_movement = direction.limit_length(1.0)


func is_actually_moving() -> bool:
	return _actual_moving


func prepare_visual_cache() -> void :
	_visual_state_initialized = false
	if visual.has_method("prepare_visual_cache"):
		visual.prepare_visual_cache()


func release_visual_cache() -> void :
	if visual.has_method("release_visual_cache"):
		visual.release_visual_cache()


func mobile_physics_budget_snapshot() -> Dictionary:
	return {
		"physics_ticks": physics_tick_count,
		"motion_resolver_calls": motion_resolver_call_count,
		"motion_resolver_idle_skips": motion_resolver_idle_skip_count,
		"visual_state_updates": visual_state_update_count,
		"visual_state_skips": visual_state_skip_count,
		"resolver_idle_synced": _resolver_idle_synced,
		"visual_state_cached": _visual_state_initialized,
		"endless_loadout_signature": "%s|%s|%s" % [RunState.endless_light_style, _last_visual_outfit, _last_visual_tool_style],
	}


func _ensure_input_actions() -> void :
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("move_up", [KEY_W, KEY_UP])
	_register_action("move_down", [KEY_S, KEY_DOWN])
	_register_action("mine", [KEY_SPACE])
	_register_action("interact", [KEY_E, KEY_F])


func _register_action(action: StringName, keys: Array[int]) -> void :
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if InputMap.action_get_events(action).size() > 0:
		return
	for keycode in keys:
		var event: = InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action, event)


func record_mining_presentation_impact() -> void:
	if OS.has_feature("ever_deeper_dev"): _record_mining_presentation_impact()


func _record_mining_presentation_impact() -> void:
	_mining_impact_serial += 1
	animation_impact_swing_serial = animation_swing_serial
	animation_impact_target = animation_target_position
	animation_impact_bearing = animation_bearing
	animation_impact_target_valid = animation_target_valid
	# A mine may legally retarget before impact. The damage owner is authoritative.
	if OS.has_feature("ever_deeper_dev"):
		var hit_context: Dictionary = LegacyMiningContext.read(get_parent())
		if hit_context.has("target"):
			animation_impact_target = Vector2(hit_context.target)
			animation_impact_bearing = (animation_impact_target-global_position).normalized()
			animation_impact_target_valid = true
	_visual_state_initialized = false
