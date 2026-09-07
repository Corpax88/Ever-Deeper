extends CharacterBody2D

signal moved(world_position: Vector2)
signal facing_changed(direction: Vector2)

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
var _last_visual_endless_loadout_signature: = ""
var physics_tick_count: = 0
var motion_resolver_call_count: = 0
var motion_resolver_idle_skip_count: = 0
var visual_state_update_count: = 0
var visual_state_skip_count: = 0


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
		_update_aim(movement)
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


func _update_aim(intent: Vector2) -> void :
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
	var next_endless_loadout_signature: = _endless_loadout_signature()
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
		and next_endless_loadout_signature == _last_visual_endless_loadout_signature
	):
		visual_state_skip_count += 1
		return
	visual.set_state(direction_name, animation_frame, is_moving, mining_visual_active, next_progress, mining_visual_recoil, mining_strike_phase)
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
	_last_visual_endless_loadout_signature = next_endless_loadout_signature
	visual_state_update_count += 1


func _endless_loadout_signature() -> String:
	if not RunState.has_method("endless_loadout_status"):
		return "standard|miner|original"
	var raw_status: Variant = RunState.call("endless_loadout_status")
	if not raw_status is Dictionary:
		return "standard|miner|original"
	var status: Dictionary = raw_status
	return "%s|%s|%s" % [
		String(status.get("light", "standard")),
		String(status.get("outfit", "miner")),
		String(status.get("tool", "original")),
	]


func set_mining_visual(active: bool, progress: float = 0.0, recoil: float = 0.0, strike_phase: float = -1.0) -> void :
	mining_strike_phase = strike_phase
	mining_visual_active = active
	mining_visual_progress = progress
	mining_visual_recoil = maxf(mining_visual_recoil, recoil)
	_update_visual(_actual_moving)


func set_facing(direction: Vector2) -> void :
	if direction.length_squared() <= 0.001:
		return
	_update_aim(direction)
	_update_visual(false)


func set_external_movement(direction: Vector2) -> void :
	external_movement = direction.limit_length(1.0)


func prepare_visual_cache() -> void :
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
		"endless_loadout_signature": _last_visual_endless_loadout_signature,
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
