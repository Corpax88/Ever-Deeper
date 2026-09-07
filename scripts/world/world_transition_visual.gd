class_name WorldTransitionVisual
extends Node2D








signal gate_opening_started(world_id: String)
signal gate_opened(world_id: String)
signal gate_closed(world_id: String)
signal threshold_crossed(world_id: String, direction: Vector2)
signal transition_midpoint(world_id: String, direction: Vector2)
signal transition_completed(world_id: String, direction: Vector2)

enum GateState{
	LOCKED,
	OPENING,
	OPEN,
}

const DEFAULT_GATE_TEXTURE: Texture2D = preload("res://assets/surface/moonglass-gate.png")
const DEFAULT_THRESHOLD_TEXTURE: Texture2D = preload("res://assets/surface/moonglass-open-threshold.png")
const DEFAULT_BOUNDARY_TEXTURE: Texture2D = preload("res://assets/surface/boundary-mossvein-moonglass-open.png")
const CUTOUT_SHADER: Shader = preload("res://shaders/ore_mountain_cutout.gdshader")
const FULL_MOTE_COUNT: = 8
const REDUCED_MOTE_COUNT: = 4
const GATE_MAX_SIZE: = Vector2(220, 210)
const GATE_BOTTOM: = 105.0
const THRESHOLD_MAX_SIZE: = Vector2(300, 110)
const THRESHOLD_BOTTOM: = 80.0
const SEAM_THRESHOLD_MAX_SIZE: = Vector2(84, 76)
const SEAM_BACK_SIZE: = Vector2(24, 184)
const SEAM_FRONT_SIZE: = Vector2(8, 190)
const SEAM_SWEEP_DISTANCE: = 34.0
const CROSSING_PULSE_DURATION: = 0.42
const VISUAL_REFRESH_HZ: = 30.0
const VISUAL_REFRESH_INTERVAL: = 1.0 / VISUAL_REFRESH_HZ
const PLAYER_VISUAL_Z: = 10
const SEAM_BACK_Z: = PLAYER_VISUAL_Z - 1
const SEAM_FRONT_Z: = PLAYER_VISUAL_Z + 2

@export var world_id: = "moonglass"
@export_range(0.2, 4.0, 0.05) var opening_duration: = 1.45
@export_range(0.2, 4.0, 0.05) var transition_duration: = 1.1
@export_range(48.0, 220.0, 1.0) var passage_half_height: = 118.0
@export_range(12.0, 80.0, 1.0) var barrier_half_width: = 38.0
@export_range(4.0, 64.0, 1.0) var crossing_dead_zone: = 14.0
@export var start_open: = false
@export var show_boundary_frame: = true
@export var external_arch_mode: = false
@export var seam_mode: = true
@export var reduced_motion: = false
@export var moss_color: = Color("9bc36d")
@export var moon_color: = Color("69e8ff")
@export var source_color: Color = Color("9bc36d"):
	set(value):
		source_color = value
		moss_color = value
@export var destination_color: Color = Color("69e8ff"):
	set(value):
		destination_color = value
		moon_color = value
@export var gate_texture: Texture2D = DEFAULT_GATE_TEXTURE
@export var threshold_texture: Texture2D = DEFAULT_THRESHOLD_TEXTURE

var gate_state: = GateState.LOCKED
var crossing_active: = false
var opening_progress: = 0.0
var transition_progress: = 0.0

var _opening_elapsed: = 0.0
var _crossing_elapsed: = 0.0
var _crossing_direction: = Vector2.RIGHT
var _last_stable_side: = 0
var _midpoint_emitted: = false
var _visual_time: = 0.0
var _visual_refresh_elapsed: = 0.0
var _runtime_tick_count: = 0
var _visual_refresh_count: = 0

var _boundary_frame: Sprite2D
var _threshold: Sprite2D
var _gate_seal: Sprite2D
var _portal_veil: Sprite2D
var _front_sweep: Sprite2D
var _portal_light: PointLight2D
var _gate_body: StaticBody2D
var _gate_shape: CollisionShape2D
var _mote_layer: Node2D
var _motes: Array[Dictionary] = []
var _gate_base_position: = Vector2.ZERO

static var _shared_light_texture: GradientTexture2D
static var _shared_mote_texture: ImageTexture
static var _shared_veil_texture: ImageTexture


func _ready() -> void :
	_ensure_visual_nodes()


	if gate_state == GateState.LOCKED and start_open:
		gate_state = GateState.OPEN
		opening_progress = 1.0
	_apply_reduced_motion()
	_apply_gate_state_visuals()
	queue_redraw()


func configure(
	configured_world_id: String = "moonglass",
	initially_open: bool = false,
	prefer_reduced_motion: bool = false,
	crossing_seconds: float = 1.1
) -> void :
	world_id = configured_world_id
	start_open = initially_open
	reduced_motion = prefer_reduced_motion
	transition_duration = clampf(crossing_seconds, 0.2, 4.0)
	gate_state = GateState.OPEN if initially_open else GateState.LOCKED
	opening_progress = 1.0 if initially_open else 0.0
	_opening_elapsed = 0.0
	crossing_active = false
	transition_progress = 0.0
	_crossing_elapsed = 0.0
	_last_stable_side = 0
	_visual_refresh_elapsed = 0.0
	if is_node_ready():
		_apply_reduced_motion()
		_apply_gate_state_visuals()
		queue_redraw()


func configure_seam(
	configured_gate_texture: Texture2D,
	configured_threshold_texture: Texture2D,
	configured_source_color: Color,
	configured_destination_color: Color,
	enabled: bool = true
) -> void :

	gate_texture = configured_gate_texture if configured_gate_texture != null else DEFAULT_GATE_TEXTURE
	threshold_texture = configured_threshold_texture if configured_threshold_texture != null else DEFAULT_THRESHOLD_TEXTURE
	source_color = configured_source_color
	destination_color = configured_destination_color
	seam_mode = enabled
	if is_node_ready():
		_sync_configured_style()


func set_gate_open(open: bool, animate: bool = true) -> void :
	_ensure_visual_nodes()
	if open:
		if gate_state == GateState.OPEN or gate_state == GateState.OPENING:
			return
		if animate:
			gate_state = GateState.OPENING
			_opening_elapsed = 0.0
			opening_progress = 0.0
			gate_opening_started.emit(world_id)
		else:
			gate_state = GateState.OPEN
			_opening_elapsed = _effective_opening_duration()
			opening_progress = 1.0
			gate_opened.emit(world_id)
	else:
		if gate_state == GateState.LOCKED:
			return
		gate_state = GateState.LOCKED
		_opening_elapsed = 0.0
		opening_progress = 0.0
		cancel_crossing()
		gate_closed.emit(world_id)
	_apply_gate_state_visuals()
	queue_redraw()


func set_reduced_motion(enabled: bool) -> void :
	reduced_motion = enabled
	if is_node_ready():
		_apply_reduced_motion()
		_apply_gate_state_visuals()


func set_external_arch_mode(enabled: bool) -> void :
	external_arch_mode = enabled
	if is_node_ready():
		_sync_threshold_geometry()
		_sync_veil_geometry()
		_apply_gate_state_visuals()
		queue_redraw()


func blocks_passage() -> bool:
	return gate_state != GateState.OPEN


func is_passage_open() -> bool:
	return gate_state == GateState.OPEN


func needs_runtime_tick(observer_world_position: Vector2, active_half_size: Vector2 = Vector2(680, 640)) -> bool:




	if gate_state == GateState.OPENING or crossing_active:
		return true
	if gate_state != GateState.OPEN or reduced_motion:
		return false
	var local_observer: = to_local(observer_world_position)
	return (
		absf(local_observer.x) <= active_half_size.x
		and absf(local_observer.y) <= active_half_size.y
	)


func blocks_actor_position(world_position: Vector2, actor_radius: float = 0.0) -> bool:
	if not blocks_passage():
		return false
	var local_position: = to_local(world_position)
	return (
		absf(local_position.x) <= barrier_half_width + actor_radius
		and absf(local_position.y) <= passage_half_height + actor_radius
	)


func observe_actor_position(world_position: Vector2) -> void :
	var local_position: = to_local(world_position)
	if absf(local_position.y) > passage_half_height:
		return
	var side: = _stable_side(local_position.x)
	if side == 0:
		return
	if _last_stable_side == 0:
		_last_stable_side = side
		return
	if side == _last_stable_side:
		return
	var prior_side: = _last_stable_side
	_last_stable_side = side
	if not is_passage_open() or crossing_active:
		return
	begin_crossing(Vector2.RIGHT if side > prior_side else Vector2.LEFT)


func begin_crossing(direction: Vector2 = Vector2.RIGHT) -> bool:
	_ensure_visual_nodes()
	if not is_passage_open() or crossing_active:
		return false
	_crossing_direction = Vector2.RIGHT if direction.x >= 0.0 else Vector2.LEFT
	_crossing_elapsed = 0.0
	transition_progress = 0.0
	_midpoint_emitted = false
	crossing_active = true
	threshold_crossed.emit(world_id, _crossing_direction)
	_apply_gate_state_visuals()
	_visual_refresh_elapsed = 0.0
	queue_redraw()
	return true


func cancel_crossing() -> void :
	crossing_active = false
	_crossing_elapsed = 0.0
	transition_progress = 0.0
	_midpoint_emitted = false
	if is_node_ready():
		_apply_gate_state_visuals()
		_visual_refresh_elapsed = 0.0
		queue_redraw()


func reset_actor_observation(world_position: Vector2) -> void :
	var local_position: = to_local(world_position)
	_last_stable_side = _stable_side(local_position.x) if absf(local_position.y) <= passage_half_height else 0


func debug_snapshot() -> Dictionary:
	var visible_motes: = 0
	for mote_value in _motes:
		var mote: Dictionary = Dictionary(mote_value)
		var sprite: = mote.get("sprite") as Sprite2D
		if is_instance_valid(sprite) and sprite.visible:
			visible_motes += 1
	var gate_visual_size: = Vector2.ZERO
	var gate_visual_rect: = Rect2()
	if is_instance_valid(_gate_seal) and _gate_seal.texture != null:
		gate_visual_size = Vector2(_gate_seal.texture.get_size()) * _gate_seal.scale.abs()
		gate_visual_rect = Rect2(_gate_seal.position - gate_visual_size * 0.5, gate_visual_size)
	return {
		"world_id": world_id,
		"state": _state_name(),
		"open": is_passage_open(),
		"blocks": blocks_passage(),
		"opening_progress": opening_progress,
		"crossing": crossing_active,
		"transition_progress": transition_progress,
		"transition_duration": transition_duration,
		"effective_transition_duration": _effective_transition_duration(),
		"reduced_motion": reduced_motion,
		"particle_capacity": _motes.size(),
		"visible_particles": visible_motes,
		"passage_half_height": passage_half_height,
		"barrier_half_width": barrier_half_width,
		"collision_enabled": is_instance_valid(_gate_shape) and not _gate_shape.disabled,
		"external_arch_mode": external_arch_mode,
		"seam_mode": seam_mode,
		"source_color": moss_color,
		"destination_color": moon_color,
		"gate_texture": gate_texture.resource_path if gate_texture != null else "",
		"threshold_texture": threshold_texture.resource_path if threshold_texture != null else "",
		"crossing_pulse_duration": CROSSING_PULSE_DURATION,
		"seam_back_size": _sprite_visual_size(_portal_veil),
		"seam_front_size": _sprite_visual_size(_front_sweep),
		"seam_back_z": _portal_veil.z_index if is_instance_valid(_portal_veil) else SEAM_BACK_Z,
		"seam_front_z": _front_sweep.z_index if is_instance_valid(_front_sweep) else SEAM_FRONT_Z,
		"front_sweep_visible": is_instance_valid(_front_sweep) and _front_sweep.visible,
		"travel_axis": Vector2.RIGHT,
		"gate_visual_size": gate_visual_size,
		"gate_visual_rect": gate_visual_rect,
		"legacy_frame_visible": is_instance_valid(_boundary_frame) and _boundary_frame.visible,
		"legacy_gate_visible": is_instance_valid(_gate_seal) and _gate_seal.visible,
		"runtime_tick_culling": true,
		"runtime_ticks": _runtime_tick_count,
		"visual_refresh_hz": VISUAL_REFRESH_HZ,
		"visual_refreshes": _visual_refresh_count,
		"visual_refresh_throttled": true,
		"crossing_timing_unthrottled": true,
		"owns_progression": false,
	}


func _process(delta: float) -> void :
	_ensure_visual_nodes()
	if gate_state == GateState.LOCKED and not crossing_active:
		return
	var safe_delta: = maxf(0.0, delta)
	_runtime_tick_count += 1
	_visual_time += safe_delta
	_visual_refresh_elapsed += safe_delta
	var force_visual_refresh: = false
	if gate_state == GateState.OPENING:
		_opening_elapsed += safe_delta
		opening_progress = clampf(_opening_elapsed / _effective_opening_duration(), 0.0, 1.0)
		if opening_progress >= 1.0:
			gate_state = GateState.OPEN
			force_visual_refresh = true
			gate_opened.emit(world_id)
	if crossing_active:
		_crossing_elapsed += safe_delta
		transition_progress = clampf(_crossing_elapsed / _effective_transition_duration(), 0.0, 1.0)
		if transition_progress >= 0.5 and not _midpoint_emitted:
			_midpoint_emitted = true
			transition_midpoint.emit(world_id, _crossing_direction)
		if transition_progress >= 1.0:
			crossing_active = false
			force_visual_refresh = true
			transition_completed.emit(world_id, _crossing_direction)
	_refresh_runtime_visuals(force_visual_refresh)


func _refresh_runtime_visuals(force_refresh: bool = false) -> void :
	if not force_refresh and _visual_refresh_elapsed + 1e-05 < VISUAL_REFRESH_INTERVAL:
		return
	var visual_delta: = _visual_refresh_elapsed
	_visual_refresh_elapsed = 0.0 if force_refresh else fmod(visual_delta, VISUAL_REFRESH_INTERVAL)
	_update_motes(visual_delta)
	_apply_gate_state_visuals()
	queue_redraw()
	_visual_refresh_count += 1


func _draw() -> void :




	if not seam_mode and not external_arch_mode:
		var lane_top: = -92.0
		var lane_height: = 184.0
		var strip_width: = 32.0
		for index in range(12):
			var ratio: = float(index) / 11.0
			var strip_color: = moss_color.lerp(moon_color.darkened(0.52), ratio)
			strip_color.a = 0.16 + sin(ratio * PI) * 0.07
			draw_rect(Rect2(-192.0 + strip_width * index, lane_top, strip_width + 1.0, lane_height), strip_color, true)
	if seam_mode and gate_state != GateState.LOCKED:
		var crossing_pulse: = _crossing_pulse()
		var seam_color: = moss_color.lerp(moon_color, 0.56)
		var open_alpha: = (0.12 + crossing_pulse * 0.18) * _smoothstep(opening_progress)
		draw_rect(Rect2(-2.0, -94.0, 4.0, 188.0), Color(seam_color, open_alpha), true)
		draw_line(Vector2(0.0, -89.0), Vector2(0.0, 89.0), Color(destination_color, open_alpha * 0.72), 1.0, true)
	elif gate_state != GateState.LOCKED:
		var crossing_pulse: = _crossing_pulse()
		var aura_alpha: = 0.08 + 0.08 * opening_progress + crossing_pulse * 0.08
		draw_circle(Vector2(0, -4), 106.0 + crossing_pulse * 8.0, Color(moon_color, aura_alpha))


func _ensure_visual_nodes() -> void :
	if is_instance_valid(_gate_seal):
		return
	_boundary_frame = Sprite2D.new()
	_boundary_frame.name = "BoundaryFrame"
	_boundary_frame.texture = DEFAULT_BOUNDARY_TEXTURE
	_boundary_frame.centered = true
	_boundary_frame.position = Vector2(0, -10)
	_boundary_frame.scale = Vector2(320, 1280) / Vector2(DEFAULT_BOUNDARY_TEXTURE.get_size())
	_boundary_frame.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_boundary_frame.z_index = 4
	_boundary_frame.material = _cutout_material()
	add_child(_boundary_frame)

	_threshold = Sprite2D.new()
	_threshold.name = "GroundBlendThreshold"
	_threshold.texture = threshold_texture if threshold_texture != null else DEFAULT_THRESHOLD_TEXTURE
	_threshold.centered = true
	_sync_threshold_geometry()
	_threshold.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_threshold.z_index = 5
	_threshold.material = _cutout_material()
	add_child(_threshold)

	_portal_light = PointLight2D.new()
	_portal_light.name = "PassageLight"
	_portal_light.texture = _light_texture()
	_portal_light.color = moon_color.lightened(0.12)
	_portal_light.texture_scale = 0.62
	_portal_light.energy = 0.0
	_portal_light.position = Vector2(0, -12)
	_portal_light.z_index = 6
	add_child(_portal_light)

	_portal_veil = Sprite2D.new()
	_portal_veil.name = "CrossingVeil"
	_portal_veil.texture = _veil_texture()
	_portal_veil.centered = true
	_portal_veil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portal_veil.modulate = Color(moon_color, 0.0)
	_portal_veil.z_index = SEAM_BACK_Z if seam_mode else 7
	add_child(_portal_veil)
	_sync_veil_geometry()

	_front_sweep = Sprite2D.new()
	_front_sweep.name = "FrontCrossingSweep"
	_front_sweep.texture = _veil_texture()
	_front_sweep.centered = true
	_front_sweep.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_front_sweep.modulate = Color(destination_color, 0.0)
	_front_sweep.z_index = SEAM_FRONT_Z
	_front_sweep.visible = false
	add_child(_front_sweep)
	_sync_veil_geometry()

	_gate_seal = Sprite2D.new()
	_gate_seal.name = "GateSeal"
	_gate_seal.texture = gate_texture if gate_texture != null else DEFAULT_GATE_TEXTURE
	_gate_seal.centered = true
	_fit_sprite(_gate_seal, GATE_MAX_SIZE)
	var gate_height: = _gate_seal.texture.get_height() * _gate_seal.scale.y
	_gate_base_position = Vector2(0, GATE_BOTTOM - gate_height * 0.5)
	_gate_seal.position = _gate_base_position
	_gate_seal.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_gate_seal.z_index = 8
	add_child(_gate_seal)

	_mote_layer = Node2D.new()
	_mote_layer.name = "PortalMotes"
	_mote_layer.z_index = SEAM_FRONT_Z if seam_mode else 9
	add_child(_mote_layer)
	_build_motes()

	_gate_body = StaticBody2D.new()
	_gate_body.name = "PassageBlocker"
	_gate_body.collision_layer = 1
	_gate_body.collision_mask = 1
	_gate_shape = CollisionShape2D.new()
	_gate_shape.name = "CollisionShape2D"
	var shape: = RectangleShape2D.new()
	shape.size = Vector2(barrier_half_width * 2.0, passage_half_height * 2.0)
	_gate_shape.shape = shape
	_gate_body.add_child(_gate_shape)
	add_child(_gate_body)


func _apply_gate_state_visuals() -> void :
	if not is_instance_valid(_gate_seal):
		return
	_boundary_frame.visible = show_boundary_frame and not external_arch_mode
	var opening_eased: = _smoothstep(opening_progress)
	var crossing_pulse: = _crossing_pulse()
	_threshold.visible = gate_state != GateState.LOCKED or external_arch_mode
	var threshold_alpha: = lerpf(0.06, 0.24 if seam_mode else 0.82, opening_eased)
	threshold_alpha += crossing_pulse * (0.16 if seam_mode else 0.0)
	if external_arch_mode and gate_state == GateState.LOCKED:
		threshold_alpha = 0.31
	var threshold_tint: = moss_color.lerp(moon_color, 0.62 + crossing_pulse * 0.26)
	_threshold.modulate = Color(threshold_tint, threshold_alpha)
	_gate_seal.visible = gate_state != GateState.OPEN and not external_arch_mode
	_gate_seal.position = _gate_base_position
	_gate_seal.rotation = 0.0
	_gate_seal.modulate = Color.WHITE
	if gate_state == GateState.OPENING and not external_arch_mode:
		var sink: = _smoothstep(clampf((opening_progress - 0.28) / 0.72, 0.0, 1.0))
		_gate_seal.position += Vector2(0.0, sink * GATE_MAX_SIZE.y)
		_gate_seal.modulate.a = 1.0 - clampf((sink - 0.78) / 0.22, 0.0, 1.0)
	elif gate_state == GateState.OPEN or external_arch_mode:
		_gate_seal.visible = false


	_portal_light.enabled = gate_state != GateState.LOCKED
	_portal_light.energy = ((0.24 + crossing_pulse * 0.42) if seam_mode else (0.58 + crossing_pulse * 0.78)) * opening_eased
	var veil_x: = 0.0
	var sweep_progress: = _crossing_pulse_progress()
	if crossing_active and not seam_mode:
		veil_x = lerpf(-66.0, 66.0, transition_progress)
		if _crossing_direction.x < 0.0:
			veil_x = - veil_x
	_portal_veil.position = Vector2(veil_x, -72.0 if external_arch_mode else 0.0)
	var veil_alpha: = (0.09 + crossing_pulse * (0.16 if reduced_motion else 0.27)) * opening_eased if seam_mode else crossing_pulse * (0.18 if reduced_motion else 0.32)
	if external_arch_mode:
		if gate_state == GateState.LOCKED:
			veil_alpha = 0.48
		elif gate_state == GateState.OPENING:
			veil_alpha = lerpf(0.48, 0.0, opening_eased)
	_portal_veil.modulate = Color(moon_color, veil_alpha)
	if is_instance_valid(_front_sweep):
		var sweep_x: = lerpf( - SEAM_SWEEP_DISTANCE, SEAM_SWEEP_DISTANCE, sweep_progress)
		if _crossing_direction.x < 0.0:
			sweep_x = - sweep_x
		_front_sweep.position = Vector2(sweep_x, -72.0 if external_arch_mode else 0.0)
		_front_sweep.visible = seam_mode and crossing_active and crossing_pulse > 0.001
		_front_sweep.modulate = Color(moss_color.lerp(moon_color, sweep_progress), crossing_pulse * (0.32 if reduced_motion else 0.58))
	_mote_layer.visible = gate_state != GateState.LOCKED
	_gate_shape.disabled = gate_state == GateState.OPEN
	var rectangle: = _gate_shape.shape as RectangleShape2D
	if rectangle != null:
		rectangle.size = Vector2(barrier_half_width * 2.0, passage_half_height * 2.0)


func _sync_veil_geometry() -> void :
	if not is_instance_valid(_portal_veil):
		return
	if seam_mode:
		_portal_veil.scale = (Vector2(68, 180) if external_arch_mode else SEAM_BACK_SIZE) / Vector2(_portal_veil.texture.get_size())
		_portal_veil.z_index = SEAM_BACK_Z
		_portal_light.scale = Vector2(0.32, 0.88)
		if is_instance_valid(_front_sweep):
			_front_sweep.scale = SEAM_FRONT_SIZE / Vector2(_front_sweep.texture.get_size())
			_front_sweep.z_index = SEAM_FRONT_Z
		if is_instance_valid(_mote_layer):
			_mote_layer.z_index = SEAM_FRONT_Z
	elif external_arch_mode:


		_portal_veil.scale = Vector2(104.0, 208.0) / Vector2(_portal_veil.texture.get_size())
	else:
		_portal_veil.scale = Vector2(44.0, 208.0) / Vector2(_portal_veil.texture.get_size())
		_portal_veil.z_index = 7
		_portal_light.scale = Vector2.ONE
		if is_instance_valid(_front_sweep):
			_front_sweep.visible = false
		if is_instance_valid(_mote_layer):
			_mote_layer.z_index = 9


func _sync_threshold_geometry() -> void :
	if not is_instance_valid(_threshold):
		return
	_fit_sprite(_threshold, SEAM_THRESHOLD_MAX_SIZE if seam_mode else THRESHOLD_MAX_SIZE)
	_threshold.position = Vector2(0, THRESHOLD_BOTTOM - _threshold.texture.get_height() * _threshold.scale.y * 0.5)


func _apply_reduced_motion() -> void :
	for index in range(_motes.size()):
		var mote: Dictionary = _motes[index]
		var sprite: = mote.get("sprite") as Sprite2D
		if is_instance_valid(sprite):
			sprite.visible = index < (REDUCED_MOTE_COUNT if reduced_motion else FULL_MOTE_COUNT)


func _build_motes() -> void :
	for child in _mote_layer.get_children():
		_mote_layer.remove_child(child)
		child.queue_free()
	_motes.clear()
	for index in range(FULL_MOTE_COUNT):
		var sprite: = Sprite2D.new()
		sprite.name = "Mote_%02d" % index
		sprite.texture = _mote_texture()
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var seed_ratio: = float((index * 37) % FULL_MOTE_COUNT) / float(FULL_MOTE_COUNT)
		var side: = -1.0 if index % 2 == 0 else 1.0
		var distance_from_seam: = 5.0 + float((index * 7) % 12) if seam_mode else 18.0 + float((index * 19) % 62)
		var start_position: = Vector2(side * distance_from_seam, 88.0 - seed_ratio * 180.0 if seam_mode else 92.0 - seed_ratio * 196.0)
		sprite.position = start_position
		var mote_scale: = 0.28 + float((index * 11) % 7) * 0.035
		sprite.scale = Vector2.ONE * mote_scale
		sprite.modulate = Color(moss_color.lerp(moon_color, 0.62 + 0.38 * seed_ratio), 0.24 + seed_ratio * 0.22 if seam_mode else 0.48 + seed_ratio * 0.34)
		_mote_layer.add_child(sprite)
		_motes.append({
			"sprite": sprite,
			"origin": start_position,
			"phase": float(index) * 1.731,
			"speed": 9.0 + float((index * 13) % 9),
		})


func _update_motes(delta: float) -> void :
	if gate_state == GateState.LOCKED:
		return
	for index in range(_motes.size()):
		var mote: Dictionary = _motes[index]
		var sprite: = mote.get("sprite") as Sprite2D
		if not is_instance_valid(sprite) or not sprite.visible:
			continue
		if reduced_motion:
			sprite.position = Vector2(mote.origin)
			continue
		var position: = sprite.position
		position.y -= float(mote.speed) * delta
		var vertical_limit: = 96.0 if seam_mode else 112.0
		if position.y < - vertical_limit:
			position.y = vertical_limit
			position.x = float(Vector2(mote.origin).x) + sin(_visual_time * 1.4 + float(mote.phase)) * (2.5 if seam_mode else 8.0)
		sprite.position = position
		var crossing_boost: = _crossing_pulse() * 0.28
		var pulse: = (0.3 if seam_mode else 0.72) + sin(_visual_time * 2.2 + float(mote.phase)) * (0.1 if seam_mode else 0.18) + crossing_boost
		sprite.modulate.a = pulse


func _sync_configured_style() -> void :
	if not is_instance_valid(_gate_seal):
		return
	_gate_seal.texture = gate_texture if gate_texture != null else DEFAULT_GATE_TEXTURE
	_sync_gate_geometry()
	_threshold.texture = threshold_texture if threshold_texture != null else DEFAULT_THRESHOLD_TEXTURE
	_sync_threshold_geometry()
	_portal_light.color = moon_color.lightened(0.12)
	_sync_veil_geometry()
	_build_motes()
	_apply_reduced_motion()
	_apply_gate_state_visuals()
	queue_redraw()


func _sync_gate_geometry() -> void :
	if not is_instance_valid(_gate_seal) or _gate_seal.texture == null:
		return
	_fit_sprite(_gate_seal, GATE_MAX_SIZE)
	var gate_height: = _gate_seal.texture.get_height() * _gate_seal.scale.y
	_gate_base_position = Vector2(0.0, GATE_BOTTOM - gate_height * 0.5)


func _crossing_pulse_progress() -> float:
	if not crossing_active:
		return 0.0
	var duration: = minf(CROSSING_PULSE_DURATION, _effective_transition_duration())
	return clampf(_crossing_elapsed / maxf(0.001, duration), 0.0, 1.0)


func _crossing_pulse() -> float:
	if not crossing_active:
		return 0.0
	return sin(_crossing_pulse_progress() * PI)


func _sprite_visual_size(sprite: Sprite2D) -> Vector2:
	if not is_instance_valid(sprite) or sprite.texture == null:
		return Vector2.ZERO
	return Vector2(sprite.texture.get_size()) * sprite.scale.abs()


func _effective_opening_duration() -> float:
	return minf(opening_duration, 0.32) if reduced_motion else opening_duration


func _effective_transition_duration() -> float:
	return minf(transition_duration, 0.38) if reduced_motion else transition_duration


func _stable_side(local_x: float) -> int:
	if local_x < - crossing_dead_zone:
		return -1
	if local_x > crossing_dead_zone:
		return 1
	return 0


func _state_name() -> String:
	match gate_state:
		GateState.OPENING:
			return "opening"
		GateState.OPEN:
			return "open"
		_:
			return "locked"


func _fit_sprite(sprite: Sprite2D, max_size: Vector2) -> void :
	var texture_size: = Vector2(sprite.texture.get_size())
	var factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	sprite.scale = Vector2.ONE * factor


func _cutout_material() -> ShaderMaterial:
	var material: = ShaderMaterial.new()
	material.shader = CUTOUT_SHADER
	return material


func _smoothstep(value: float) -> float:
	var clamped: = clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


static func _light_texture() -> GradientTexture2D:
	if _shared_light_texture != null:
		return _shared_light_texture
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.48, 1.0])
	gradient.colors = PackedColorArray([
		Color(1, 1, 1, 0.92),
		Color(1, 1, 1, 0.34),
		Color(1, 1, 1, 0.0),
	])
	_shared_light_texture = GradientTexture2D.new()
	_shared_light_texture.width = 256
	_shared_light_texture.height = 256
	_shared_light_texture.fill = GradientTexture2D.FILL_RADIAL
	_shared_light_texture.fill_from = Vector2(0.5, 0.5)
	_shared_light_texture.fill_to = Vector2(1.0, 0.5)
	_shared_light_texture.gradient = gradient
	return _shared_light_texture


static func _veil_texture() -> ImageTexture:
	if _shared_veil_texture != null:
		return _shared_veil_texture
	var width: = 128
	var height: = 256
	var image: = Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		var vertical: = float(y) / float(height - 1)
		for x in range(width):
			var horizontal: = float(x) / float(width - 1)
			var nx: = (horizontal - 0.5) * 2.0


			var arch_top: = 0.055 + nx * nx * 0.18
			var top_fade: = clampf((vertical - arch_top) / 0.1, 0.0, 1.0)
			var side_fade: = clampf((1.0 - absf(nx)) / 0.24, 0.0, 1.0)
			var bottom_fade: = clampf((1.0 - vertical) / 0.12, 0.0, 1.0)
			var grain: = 0.72 + 0.18 * sin(horizontal * 41.0 + vertical * 13.0)
			var alpha: = top_fade * side_fade * bottom_fade * grain
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_shared_veil_texture = ImageTexture.create_from_image(image)
	return _shared_veil_texture


static func _mote_texture() -> ImageTexture:
	if _shared_mote_texture != null:
		return _shared_mote_texture
	var image: = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var center: = Vector2(7.5, 7.5)
	for y in range(16):
		for x in range(16):
			var distance: = Vector2(float(x), float(y)).distance_to(center) / 7.5
			var alpha: = pow(clampf(1.0 - distance, 0.0, 1.0), 1.8)
			image.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_shared_mote_texture = ImageTexture.create_from_image(image)
	return _shared_mote_texture
