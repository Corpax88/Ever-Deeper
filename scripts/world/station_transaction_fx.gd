class_name StationTransactionFx
extends Node2D





signal transaction_started(transaction_id: int, flow: String, gold_delta_total: int)
signal phase_changed(transaction_id: int, phase: String)
signal progress_changed(
	transaction_id: int,
	overall_progress: float,
	phase: String,
	phase_progress: float
)
signal gold_tick(
	transaction_id: int,
	delta: int,
	cumulative_delta: int,
	total_delta: int
)
signal upgrade_reward_pulse(transaction_id: int, progress: float)
signal transaction_completed(transaction_id: int, flow: String, skipped: bool)

const FLOW_SALE: = "sale"
const FLOW_FORGE: = "forge"

const PHASE_RESOURCES_TO_STATION: = "resources_to_station"
const PHASE_GOLD_TO_WALLET: = "gold_to_wallet"
const PHASE_INPUTS_TO_FORGE: = "inputs_to_forge"
const PHASE_UPGRADE_REWARD: = "upgrade_reward"

const PHASE_KIND_FLIGHT: = "flight"
const PHASE_KIND_PULSE: = "pulse"
const ROLE_BAG: = "bag"
const ROLE_STATION: = "station"
const ROLE_WALLET: = "wallet"

const ABSOLUTE_VISUAL_CAP: = 24
const MAX_PACKETS_PER_BATCH: = 6
const MAX_GOLD_PACKETS: = 8
const MAX_SCHEDULED_RESOURCE_PACKETS: = 96
const DEFAULT_VISUAL_REFRESH_HZ: = 30.0
const MIN_FLIGHT_DURATION: = 0.08

@export_range(4, ABSOLUTE_VISUAL_CAP, 1) var max_visible_sprites: = 16
@export_range(15.0, 60.0, 1.0) var visual_refresh_hz: = DEFAULT_VISUAL_REFRESH_HZ
@export var reduced_motion: = false
@export var default_gold_texture: Texture2D
@export var default_reward_texture: Texture2D
@export var default_resource_size: = Vector2(32.0, 32.0)
@export var default_gold_size: = Vector2(36.0, 30.0)
@export var reward_color: = Color("f4c45f")

var busy: bool:
	get:
		return _active

var active_transaction_id: int:
	get:
		return _transaction_id if _active else -1

var emitted_gold_tick_sum: int:
	get:
		return _gold_delta_emitted

var _pool: Array[Dictionary] = []
var _phases: Array[Dictionary] = []
var _phase_specs: Array[Dictionary] = []
var _options: Dictionary = {}

var _active: = false
var _finishing: = false
var _flow: = ""
var _transaction_id: = -1
var _transaction_counter: = 0
var _transaction_key: Variant
var _last_completed_id: = -1
var _last_completed_flow: = ""
var _last_completed_key: Variant
var _phase_index: = -1
var _phase_name: = ""
var _phase_kind: = ""
var _phase_elapsed: = 0.0
var _phase_duration: = 0.0
var _phase_spawn_window: = 0.0
var _phase_pending_index: = 0
var _phase_completed_value: = 0.0
var _phase_total_value: = 0.0
var _visual_refresh_elapsed: = 0.0
var _speed_multiplier: = 1.0

var _bag_origin: = Vector2.ZERO
var _station_position: = Vector2.ZERO
var _wallet_position: = Vector2.ZERO
var _positions_are_local: = false

var _gold_delta_total: = 0
var _gold_delta_emitted: = 0
var _active_visual_cap: = 16
var _peak_active_visuals: = 0
var _transaction_reduced_motion: = false
var _transaction_draw_hz: = DEFAULT_VISUAL_REFRESH_HZ
var _resource_duration: = 0.52
var _gold_duration: = 0.44
var _reward_duration: = 0.46
var _resource_spawn_window: = 0.22
var _gold_spawn_window: = 0.18
var _pulse_color: = Color("f4c45f")
var _pulse_texture: Texture2D
var _pulse_texture_size: = Vector2(58.0, 58.0)


func _ready() -> void :
	set_process(false)
	_ensure_pool(max_visible_sprites)


func _exit_tree() -> void :
	if _active:
		_finish_transaction(true)


func _notification(what: int) -> void :


	if what == NOTIFICATION_PREDELETE and _active:
		_finish_transaction(true)





func play_sale(
	resources: Array[Dictionary],
	gold_total: int,
	bag_world_origin: Vector2,
	station_world_position: Vector2,
	wallet_world_target: Vector2,
	gold_texture: Texture2D = null,
	options: Dictionary = {}
) -> int:
	var duplicate_id: = _duplicate_transaction_id(FLOW_SALE, options)
	if duplicate_id >= 0:
		return duplicate_id
	if _finishing:
		return -1
	_begin_transaction(
		FLOW_SALE,
		absi(gold_total),
		bag_world_origin,
		station_world_position,
		wallet_world_target,
		options
	)
	var resource_specs: Array[Dictionary] = _build_resource_specs(
		resources,
		ROLE_BAG,
		ROLE_STATION,
		_resource_duration,
		11
	)
	if not resource_specs.is_empty():
		_append_flight_phase(
			PHASE_RESOURCES_TO_STATION,
			resource_specs,
			_resource_spawn_window
		)
	var resolved_gold_texture: Texture2D = gold_texture
	if resolved_gold_texture == null:
		resolved_gold_texture = default_gold_texture
	if _gold_delta_total > 0:
		var gold_specs: Array[Dictionary] = _build_gold_specs(
			_gold_delta_total,
			ROLE_STATION,
			ROLE_WALLET,
			resolved_gold_texture,
			_gold_duration,
			101
		)
		_append_flight_phase(PHASE_GOLD_TO_WALLET, gold_specs, _gold_spawn_window)
	_start_transaction()
	return _transaction_id




func play_forge(
	resources: Array[Dictionary],
	gold_cost: int,
	bag_world_origin: Vector2,
	wallet_world_origin: Vector2,
	station_world_position: Vector2,
	gold_texture: Texture2D = null,
	options: Dictionary = {}
) -> int:
	var duplicate_id: = _duplicate_transaction_id(FLOW_FORGE, options)
	if duplicate_id >= 0:
		return duplicate_id
	if _finishing:
		return -1
	_begin_transaction(
		FLOW_FORGE,
		- absi(gold_cost),
		bag_world_origin,
		station_world_position,
		wallet_world_origin,
		options
	)
	var resource_specs: Array[Dictionary] = _build_resource_specs(
		resources,
		ROLE_BAG,
		ROLE_STATION,
		_resource_duration,
		211
	)
	var resolved_gold_texture: Texture2D = gold_texture
	if resolved_gold_texture == null:
		resolved_gold_texture = default_gold_texture
	var gold_specs: Array[Dictionary] = []
	if _gold_delta_total < 0:
		gold_specs = _build_gold_specs(
			_gold_delta_total,
			ROLE_WALLET,
			ROLE_STATION,
			resolved_gold_texture,
			_gold_duration,
			307
		)
	var input_specs: Array[Dictionary] = _interleave_specs(resource_specs, gold_specs)
	if not input_specs.is_empty():
		_append_flight_phase(
			PHASE_INPUTS_TO_FORGE,
			input_specs,
			maxf(_resource_spawn_window, _gold_spawn_window)
		)
	_phases.append({
		"name": PHASE_UPGRADE_REWARD,
		"kind": PHASE_KIND_PULSE,
		"duration": _reward_duration,
	})
	_start_transaction()
	return _transaction_id





func set_runtime_targets(
	bag_world_origin: Vector2,
	station_world_position: Vector2,
	wallet_world_target: Vector2,
	positions_are_local: bool = false
) -> void :
	_bag_origin = _local_point(bag_world_origin, positions_are_local)
	_station_position = _local_point(station_world_position, positions_are_local)
	_wallet_position = _local_point(wallet_world_target, positions_are_local)
	_refresh_active_targets()




func set_bag_origin(position_value: Vector2, positions_are_local: bool = false) -> void :
	_bag_origin = _local_point(position_value, positions_are_local)


func set_station_target(position_value: Vector2, positions_are_local: bool = false) -> void :
	_station_position = _local_point(position_value, positions_are_local)
	_refresh_active_targets()


func set_wallet_target(position_value: Vector2, positions_are_local: bool = false) -> void :
	_wallet_position = _local_point(position_value, positions_are_local)
	_refresh_active_targets()


func set_reduced_motion(enabled: bool) -> void :

	reduced_motion = enabled




func skip() -> void :
	if not _active or _finishing:
		return
	_finish_transaction(true)



func fast_complete(speed_scale: float = 8.0) -> void :
	if not _active:
		return
	_speed_multiplier = maxf(_speed_multiplier, clampf(speed_scale, 2.0, 64.0))



func complete_immediately() -> void :
	if not _active or _finishing:
		return
	_finish_transaction(false)


func get_emitted_gold_tick_sum() -> int:
	return _gold_delta_emitted


func debug_snapshot() -> Dictionary:
	return {
		"busy": _active,
		"transaction_id": _transaction_id,
		"transaction_key": _transaction_key,
		"last_completed_id": _last_completed_id,
		"last_completed_key": _last_completed_key,
		"flow": _flow,
		"phase": _phase_name,
		"phase_index": _phase_index,
		"phase_count": _phases.size(),
		"active_visuals": _active_visual_count(),
		"pending_visuals": maxi(0, _phase_specs.size() - _phase_pending_index),
		"visual_cap": _active_visual_cap,
		"pool_size": _pool.size(),
		"peak_active_visuals": _peak_active_visuals,
		"gold_delta_total": _gold_delta_total,
		"emitted_gold_tick_sum": _gold_delta_emitted,
		"gold_ticks_exact": _gold_delta_emitted == _gold_delta_total if not _active else true,
		"reduced_motion": _transaction_reduced_motion,
		"visual_refresh_hz": _transaction_draw_hz,
		"per_visual_nodes": false,
		"physics_nodes": 0,
	}


func _process(delta: float) -> void :
	if not _active:
		set_process(false)
		return
	var scaled_delta: = maxf(0.0, delta) * _speed_multiplier
	if _phase_kind == PHASE_KIND_FLIGHT:
		_update_flight_phase(scaled_delta)
	elif _phase_kind == PHASE_KIND_PULSE:
		_update_pulse_phase(scaled_delta)
	if not _active:
		return
	_visual_refresh_elapsed += maxf(0.0, delta)
	var refresh_interval: = 1.0 / maxf(1.0, _transaction_draw_hz)
	if _visual_refresh_elapsed >= refresh_interval:
		_visual_refresh_elapsed = fmod(_visual_refresh_elapsed, refresh_interval)
		var refreshing_id: = _transaction_id
		_emit_progress(false)
		if not _active or _transaction_id != refreshing_id:
			return
		if _phase_kind == PHASE_KIND_PULSE:
			upgrade_reward_pulse.emit(_transaction_id, _current_phase_progress())
			if not _active or _transaction_id != refreshing_id:
				return
		queue_redraw()


func _draw() -> void :
	for slot_index in range(mini(_pool.size(), _active_visual_cap)):
		var visual: Dictionary = _pool[slot_index]
		if bool(visual.get("active", false)):
			_draw_visual(visual)
	if _active and _phase_kind == PHASE_KIND_PULSE:
		_draw_reward_pulse(_current_phase_progress())


func _begin_transaction(
	flow: String,
	gold_delta: int,
	bag_position: Vector2,
	station_position: Vector2,
	wallet_position: Vector2,
	options: Dictionary
) -> void :
	if _active:
		skip()
	_transaction_counter += 1
	_transaction_id = _transaction_counter
	_flow = flow
	_options = options.duplicate(true)
	_transaction_key = _options.get("transaction_key", _transaction_id)
	_positions_are_local = bool(_options.get("positions_are_local", false))
	_bag_origin = _local_point(bag_position, _positions_are_local)
	_station_position = _local_point(station_position, _positions_are_local)
	_wallet_position = _local_point(wallet_position, _positions_are_local)
	_gold_delta_total = gold_delta
	_gold_delta_emitted = 0
	_phases.clear()
	_phase_specs.clear()
	_phase_index = -1
	_phase_name = ""
	_phase_kind = ""
	_phase_elapsed = 0.0
	_phase_duration = 0.0
	_phase_pending_index = 0
	_phase_completed_value = 0.0
	_phase_total_value = 0.0
	_speed_multiplier = 1.0
	_visual_refresh_elapsed = 0.0
	_peak_active_visuals = 0
	_transaction_reduced_motion = bool(_options.get("reduced_motion", reduced_motion))
	_transaction_draw_hz = clampf(
		float(_options.get("visual_refresh_hz", visual_refresh_hz)),
		15.0,
		60.0
	)
	_active_visual_cap = clampi(
		int(_options.get("visual_cap", max_visible_sprites)),
		1,
		ABSOLUTE_VISUAL_CAP
	)
	if _transaction_reduced_motion:
		_active_visual_cap = mini(_active_visual_cap, 6)
	_resource_duration = maxf(
		MIN_FLIGHT_DURATION,
		float(_options.get("resource_duration", 0.22 if _transaction_reduced_motion else 0.52))
	)
	_gold_duration = maxf(
		MIN_FLIGHT_DURATION,
		float(_options.get("gold_duration", 0.2 if _transaction_reduced_motion else 0.44))
	)
	_reward_duration = maxf(
		0.08,
		float(_options.get("reward_duration", 0.22 if _transaction_reduced_motion else 0.46))
	)
	_resource_spawn_window = maxf(
		0.0,
		float(_options.get("resource_spawn_window", 0.03 if _transaction_reduced_motion else 0.22))
	)
	_gold_spawn_window = maxf(
		0.0,
		float(_options.get("gold_spawn_window", 0.02 if _transaction_reduced_motion else 0.18))
	)
	_pulse_color = _option_color("reward_color", reward_color)
	_pulse_texture = _option_texture("reward_texture", default_reward_texture)
	_pulse_texture_size = _option_size("reward_size", Vector2(58.0, 58.0))
	_ensure_pool(_active_visual_cap)
	_clear_visuals()


func _duplicate_transaction_id(flow: String, options: Dictionary) -> int:
	if not options.has("transaction_key"):
		return -1
	var requested_key: Variant = options.get("transaction_key")
	if _active and flow == _flow and requested_key == _transaction_key:
		return _transaction_id
	if flow == _last_completed_flow and requested_key == _last_completed_key:
		return _last_completed_id
	return -1


func _start_transaction() -> void :
	_active = true
	set_process(true)
	var started_id: = _transaction_id
	transaction_started.emit(_transaction_id, _flow, _gold_delta_total)
	if not _active or _transaction_id != started_id:
		return
	_start_phase(0)
	if _active:
		queue_redraw()


func _append_flight_phase(
	phase_name: String,
	specs: Array[Dictionary],
	spawn_window: float
) -> void :
	_phases.append({
		"name": phase_name,
		"kind": PHASE_KIND_FLIGHT,
		"specs": specs,
		"spawn_window": maxf(0.0, spawn_window),
	})


func _start_phase(next_index: int) -> void :
	if not _active:
		return
	_clear_visuals()
	_phase_index = next_index
	if _phase_index >= _phases.size():
		_finish_transaction(false)
		return
	var phase: Dictionary = _phases[_phase_index]
	_phase_name = String(phase.get("name", ""))
	_phase_kind = String(phase.get("kind", ""))
	_phase_elapsed = 0.0
	_phase_pending_index = 0
	_phase_completed_value = 0.0
	_phase_total_value = 0.0
	_phase_specs.clear()
	var started_id: = _transaction_id
	phase_changed.emit(_transaction_id, _phase_name)
	if not _active or _transaction_id != started_id:
		return
	if _phase_kind == PHASE_KIND_FLIGHT:
		var raw_specs: Array = phase.get("specs", [])
		for raw_spec in raw_specs:
			if raw_spec is Dictionary:
				_phase_specs.append(Dictionary(raw_spec).duplicate(true))
		_phase_spawn_window = float(phase.get("spawn_window", 0.0))
		var spec_count: = _phase_specs.size()
		for spec_index in range(spec_count):
			var launch_at: = 0.0
			if spec_count > 1:
				launch_at = float(spec_index) / float(spec_count - 1) * _phase_spawn_window
			_phase_specs[spec_index]["launch_at"] = launch_at
			_phase_total_value += maxf(1.0, float(_phase_specs[spec_index].get("value", 1)))
		_phase_duration = _flight_phase_estimated_duration()
		_activate_due_visuals()
		if _phase_specs.is_empty():
			_start_phase(_phase_index + 1)
			return
	else:
		_phase_duration = maxf(0.08, float(phase.get("duration", _reward_duration)))
		_phase_total_value = 1.0
		upgrade_reward_pulse.emit(_transaction_id, 0.0)
		if not _active or _transaction_id != started_id:
			return
	_emit_progress(true)
	queue_redraw()


func _update_flight_phase(delta: float) -> void :
	var updating_id: = _transaction_id
	_phase_elapsed += delta
	for slot_index in range(mini(_pool.size(), _active_visual_cap)):
		var visual: Dictionary = _pool[slot_index]
		if not bool(visual.get("active", false)):
			continue
		visual["age"] = float(visual.get("age", 0.0)) + delta
		if float(visual.age) >= maxf(MIN_FLIGHT_DURATION, float(visual.get("duration", 0.1))):
			_complete_visual(slot_index)
			if not _active or _transaction_id != updating_id:
				return
	_activate_due_visuals()
	if not _active or _transaction_id != updating_id:
		return
	_peak_active_visuals = maxi(_peak_active_visuals, _active_visual_count())
	if _phase_pending_index >= _phase_specs.size() and _active_visual_count() == 0:
		var completed_phase_id: = _transaction_id
		_emit_progress(true)
		if not _active or _transaction_id != completed_phase_id:
			return
		_start_phase(_phase_index + 1)


func _update_pulse_phase(delta: float) -> void :
	var updating_id: = _transaction_id
	_phase_elapsed += delta
	if _phase_elapsed >= _phase_duration:
		_phase_elapsed = _phase_duration
		upgrade_reward_pulse.emit(_transaction_id, 1.0)
		if not _active or _transaction_id != updating_id:
			return
		_emit_progress(true)
		if not _active or _transaction_id != updating_id:
			return
		_start_phase(_phase_index + 1)


func _activate_due_visuals() -> void :
	var activating_id: = _transaction_id
	while _phase_pending_index < _phase_specs.size():
		if not _active or _transaction_id != activating_id:
			return
		var spec: Dictionary = _phase_specs[_phase_pending_index]
		var launch_at: = float(spec.get("launch_at", 0.0))
		if launch_at > _phase_elapsed:
			return
		var free_slot: = _first_free_slot()
		if free_slot < 0:
			return
		var visual: Dictionary = spec.duplicate(true)
		visual["active"] = true


		visual["age"] = minf(
			maxf(0.0, _phase_elapsed - launch_at),
			1.0 / maxf(15.0, _transaction_draw_hz)
		)
		visual["start"] = _role_position(String(visual.get("start_role", ROLE_BAG)))\
		+ Vector2(visual.get("start_offset", Vector2.ZERO))
		visual["target"] = _role_position(String(visual.get("target_role", ROLE_STATION)))\
		+ Vector2(visual.get("target_offset", Vector2.ZERO))
		_pool[free_slot] = visual
		_phase_pending_index += 1
		if float(visual.age) >= maxf(MIN_FLIGHT_DURATION, float(visual.get("duration", 0.1))):
			_complete_visual(free_slot)
			if not _active or _transaction_id != activating_id:
				return


func _complete_visual(slot_index: int) -> void :
	if slot_index < 0 or slot_index >= _pool.size():
		return
	var visual: Dictionary = _pool[slot_index]
	if not bool(visual.get("active", false)):
		return
	_phase_completed_value += maxf(1.0, float(visual.get("value", 1)))
	var tick_delta: = int(visual.get("gold_tick", 0))
	_pool[slot_index] = {"active": false}
	if tick_delta != 0:
		_emit_gold_tick(tick_delta)


func _finish_transaction(was_skipped: bool) -> void :
	if not _active or _finishing:
		return
	_finishing = true
	_settle_remaining_gold()
	var completed_id: = _transaction_id
	var completed_flow: = _flow
	var completed_key: Variant = _transaction_key
	var completed_phase: = _phase_name
	_clear_visuals()
	_active = false
	_phase_elapsed = _phase_duration
	set_process(false)
	_phase_name = ""
	_phase_kind = ""
	_last_completed_id = completed_id
	_last_completed_flow = completed_flow
	_last_completed_key = completed_key
	progress_changed.emit(completed_id, 1.0, completed_phase, 1.0)
	transaction_completed.emit(completed_id, completed_flow, was_skipped)
	_finishing = false
	queue_redraw()


func _settle_remaining_gold() -> void :
	var remaining: = _gold_delta_total - _gold_delta_emitted
	if remaining != 0:
		_emit_gold_tick(remaining)


func _emit_gold_tick(delta: int) -> void :
	if delta == 0:
		return
	_gold_delta_emitted += delta
	gold_tick.emit(
		_transaction_id,
		delta,
		_gold_delta_emitted,
		_gold_delta_total
	)


func _emit_progress(force: bool) -> void :
	if not _active:
		return
	var phase_progress: = _current_phase_progress()
	var phase_count: = maxi(1, _phases.size())
	var overall: = clampf(
		(float(maxi(0, _phase_index)) + phase_progress) / float(phase_count),
		0.0,
		1.0
	)
	progress_changed.emit(_transaction_id, overall, _phase_name, phase_progress)
	if force:
		queue_redraw()


func _current_phase_progress() -> float:
	if _phase_kind == PHASE_KIND_PULSE:
		return clampf(_phase_elapsed / maxf(0.001, _phase_duration), 0.0, 1.0)
	if _phase_kind != PHASE_KIND_FLIGHT:
		return 0.0
	if _phase_total_value <= 0.0:
		return 1.0
	var presented_value: = _phase_completed_value
	for slot_index in range(mini(_pool.size(), _active_visual_cap)):
		var visual: Dictionary = _pool[slot_index]
		if not bool(visual.get("active", false)):
			continue
		var duration: = maxf(MIN_FLIGHT_DURATION, float(visual.get("duration", 0.1)))
		var travel: = clampf(float(visual.get("age", 0.0)) / duration, 0.0, 1.0)
		presented_value += maxf(1.0, float(visual.get("value", 1))) * travel
	return clampf(presented_value / _phase_total_value, 0.0, 1.0)


func _build_resource_specs(
	resources: Array[Dictionary],
	start_role: String,
	target_role: String,
	duration: float,
	seed_base: int
) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	for batch_index in range(resources.size()):
		if specs.size() >= MAX_SCHEDULED_RESOURCE_PACKETS:
			break
		var batch: Dictionary = resources[batch_index]
		var amount: = maxi(0, int(batch.get("amount", 0)))
		if amount <= 0:
			continue
		var texture: Texture2D = _batch_texture(batch)
		var packet_count: = _packet_count_for_amount(amount, false)
		if batch.has("packet_count"):
			packet_count = clampi(int(batch.packet_count), 1, MAX_PACKETS_PER_BATCH)
		if _transaction_reduced_motion:
			packet_count = 1
		packet_count = mini(packet_count, amount)
		packet_count = mini(packet_count, MAX_SCHEDULED_RESOURCE_PACKETS - specs.size())
		var packet_amounts: Array[int] = _split_amount(amount, packet_count)
		var visual_size: = _batch_size(batch, default_resource_size)
		var tint: = _batch_color(batch, Color.WHITE)
		var resource_id: = String(batch.get("id", batch.get("kind", "resource")))
		for packet_index in range(packet_amounts.size()):
			var seed: = seed_base + batch_index * 37 + packet_index * 13
			specs.append(_make_flight_spec(
				texture,
				visual_size,
				tint,
				resource_id,
				packet_amounts[packet_index],
				start_role,
				target_role,
				duration,
				seed,
				0
			))
	return specs


func _build_gold_specs(
	signed_amount: int,
	start_role: String,
	target_role: String,
	texture: Texture2D,
	duration: float,
	seed_base: int
) -> Array[Dictionary]:
	var specs: Array[Dictionary] = []
	var absolute_amount: = absi(signed_amount)
	if absolute_amount <= 0:
		return specs
	var packet_count: = _packet_count_for_amount(absolute_amount, true)
	if _options.has("gold_packet_count"):
		packet_count = clampi(int(_options.gold_packet_count), 1, MAX_GOLD_PACKETS)
	if _transaction_reduced_motion:
		packet_count = mini(packet_count, 2)
	packet_count = mini(packet_count, absolute_amount)
	var packet_amounts: Array[int] = _split_amount(absolute_amount, packet_count)
	var sign_value: = 1 if signed_amount > 0 else -1
	var visual_size: = _option_size("gold_size", default_gold_size)
	for packet_index in range(packet_amounts.size()):
		var packet_amount: = packet_amounts[packet_index]
		var seed: = seed_base + packet_index * 17
		specs.append(_make_flight_spec(
			texture,
			visual_size,
			Color.WHITE,
			"gold",
			packet_amount,
			start_role,
			target_role,
			duration,
			seed,
			packet_amount * sign_value
		))
	return specs


func _make_flight_spec(
	texture: Texture2D,
	visual_size: Vector2,
	tint: Color,
	resource_id: String,
	amount: int,
	start_role: String,
	target_role: String,
	duration: float,
	seed: int,
	gold_tick_delta: int
) -> Dictionary:
	var start_radius: = 5.0 if _transaction_reduced_motion else 14.0
	var target_radius: = 2.0 if _transaction_reduced_motion else 9.0
	var arc_height: = 0.0 if _transaction_reduced_motion else lerpf(24.0, 48.0, _noise01(seed + 7))
	var lane: = 0.0 if _transaction_reduced_motion else lerpf(-16.0, 16.0, _noise01(seed + 19))
	return {
		"active": false,
		"texture": texture,
		"size": visual_size,
		"tint": tint,
		"resource_id": resource_id,
		"amount": amount,
		"value": maxi(1, amount),
		"gold_tick": gold_tick_delta,
		"start_role": start_role,
		"target_role": target_role,
		"start_offset": _radial_offset(seed, start_radius),
		"target_offset": _radial_offset(seed + 31, target_radius),
		"duration": maxf(MIN_FLIGHT_DURATION, duration * lerpf(0.92, 1.08, _noise01(seed + 43))),
		"arc_height": arc_height,
		"lane": lane,
		"rotation_start": lerpf(-0.22, 0.22, _noise01(seed + 53)),
		"rotation_turns": 0.0 if _transaction_reduced_motion else lerpf(-0.8, 0.8, _noise01(seed + 67)),
	}


func _interleave_specs(
	first: Array[Dictionary],
	second: Array[Dictionary]
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var first_index: = 0
	var second_index: = 0
	while first_index < first.size() or second_index < second.size():
		if first_index < first.size():
			result.append(first[first_index])
			first_index += 1
		if second_index < second.size():
			result.append(second[second_index])
			second_index += 1
	return result


func _packet_count_for_amount(amount: int, gold: bool) -> int:
	if _transaction_reduced_motion:
		return 1
	var count: = 1
	if amount >= 4:
		count = 2
	if amount >= 12:
		count = 3
	if amount >= 36:
		count = 4
	if amount >= 100:
		count = 5
	if amount >= 300:
		count = 6
	if gold and amount >= 1000:
		count = 8
	return mini(count, MAX_GOLD_PACKETS if gold else MAX_PACKETS_PER_BATCH)


func _split_amount(amount: int, count: int) -> Array[int]:
	var result: Array[int] = []
	var safe_count: = clampi(count, 1, maxi(1, amount))
	var base_amount: = floori(float(amount) / float(safe_count))
	var remainder: = amount - base_amount * safe_count
	for index in range(safe_count):
		result.append(base_amount + (1 if index < remainder else 0))
	return result


func _draw_visual(visual: Dictionary) -> void :
	var duration: = maxf(MIN_FLIGHT_DURATION, float(visual.get("duration", 0.1)))
	var travel: = clampf(float(visual.get("age", 0.0)) / duration, 0.0, 1.0)
	var eased: = 1.0 - pow(1.0 - travel, 3.0)
	var start: = Vector2(visual.get("start", Vector2.ZERO))
	var target: = Vector2(visual.get("target", Vector2.ZERO))
	var point: = start.lerp(target, eased)
	if not _transaction_reduced_motion:
		var direction: = target - start
		var normal: = Vector2( - direction.y, direction.x).normalized()
		point += Vector2(0.0, - sin(travel * PI) * float(visual.get("arc_height", 0.0)))
		point += normal * sin(travel * PI) * float(visual.get("lane", 0.0))
	var arrival_scale: = clampf((1.0 - travel) / 0.14, 0.0, 1.0)
	var launch_scale: = clampf(travel / 0.1, 0.0, 1.0)
	var visual_scale: = maxf(0.08, minf(arrival_scale, launch_scale))
	if _transaction_reduced_motion:
		visual_scale = maxf(0.18, 1.0 - travel * 0.35)
	var rotation: = float(visual.get("rotation_start", 0.0))\
	+ float(visual.get("rotation_turns", 0.0)) * TAU * travel
	var size: = Vector2(visual.get("size", default_resource_size))
	var tint: = Color(visual.get("tint", Color.WHITE))
	var texture: Texture2D = visual.get("texture") as Texture2D
	draw_set_transform(point, rotation, Vector2.ONE * visual_scale)
	if texture != null:
		draw_texture_rect(texture, Rect2( - size * 0.5, size), false, tint)
	else:
		_draw_missing_texture_fallback(size, String(visual.get("resource_id", "resource")), tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var amount: = int(visual.get("amount", 1))
	if amount > 1 and visual_scale > 0.25:
		_draw_batch_label(point + Vector2(0.0, size.y * 0.42 + 9.0), amount, tint.a * visual_scale)


func _draw_reward_pulse(progress: float) -> void :
	var pulse: = clampf(progress, 0.0, 1.0)
	var alpha: = sin(pulse * PI)
	if _pulse_texture != null:
		var texture_scale: = lerpf(0.78, 1.08, sin(pulse * PI * 0.5))
		if _transaction_reduced_motion:
			texture_scale = 1.0
		draw_set_transform(_station_position + Vector2(0.0, -14.0), 0.0, Vector2.ONE * texture_scale)
		draw_texture_rect(
			_pulse_texture,
			Rect2( - _pulse_texture_size * 0.5, _pulse_texture_size),
			false,
			Color(1.0, 1.0, 1.0, alpha)
		)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if _transaction_reduced_motion:
		draw_arc(
			_station_position + Vector2(0.0, -14.0),
			34.0,
			0.0,
			TAU,
			32,
			Color(_pulse_color, alpha * 0.62),
			2.4
		)
		return
	var center: = _station_position + Vector2(0.0, -14.0)
	var inner_radius: = lerpf(24.0, 62.0, pulse)
	var outer_radius: = lerpf(16.0, 82.0, pulse)
	draw_arc(center, inner_radius, 0.0, TAU, 40, Color(_pulse_color, alpha * 0.84), 3.0)
	draw_arc(center, outer_radius, 0.0, TAU, 40, Color(_pulse_color, alpha * 0.36), 2.0)
	for ray_index in range(8):
		var angle: = TAU * float(ray_index) / 8.0 + pulse * 0.18
		var ray_start: = center + Vector2.from_angle(angle) * lerpf(22.0, 46.0, pulse)
		var ray_end: = ray_start + Vector2.from_angle(angle) * lerpf(13.0, 4.0, pulse)
		draw_line(ray_start, ray_end, Color(_pulse_color, alpha * 0.58), 2.0)


func _draw_batch_label(position_value: Vector2, amount: int, alpha: float) -> void :
	var font: Font = ThemeDB.fallback_font
	var text_value: = "x%d" % amount
	var width: = 64.0
	var font_size: = 12
	var rect_start: = position_value - Vector2(width * 0.5, 0.0)
	draw_string(
		font,
		rect_start + Vector2(1.0, 1.0),
		text_value,
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		font_size,
		Color(0.03, 0.025, 0.02, clampf(alpha, 0.0, 1.0) * 0.86)
	)
	draw_string(
		font,
		rect_start,
		text_value,
		HORIZONTAL_ALIGNMENT_CENTER,
		width,
		font_size,
		Color(1.0, 0.94, 0.78, clampf(alpha, 0.0, 1.0))
	)


func _draw_missing_texture_fallback(size: Vector2, resource_id: String, tint: Color) -> void :
	if resource_id == "gold":
		draw_rect(Rect2( - size * Vector2(0.44, 0.28), size * Vector2(0.88, 0.56)), Color("f3bd48"), true)
		draw_line( - size * Vector2(0.26, 0.08), size * Vector2(0.26, -0.08), Color("fff1a6"), 2.0)
		return
	var radius: = minf(size.x, size.y) * 0.36
	var points: = PackedVector2Array([
		Vector2(0.0, - radius),
		Vector2(radius, 0.0),
		Vector2(0.0, radius),
		Vector2( - radius, 0.0),
	])
	draw_colored_polygon(points, Color(tint, maxf(0.76, tint.a)))


func _refresh_active_targets() -> void :
	for slot_index in range(mini(_pool.size(), _active_visual_cap)):
		var visual: Dictionary = _pool[slot_index]
		if not bool(visual.get("active", false)):
			continue
		visual["target"] = _role_position(String(visual.get("target_role", ROLE_STATION)))\
		+ Vector2(visual.get("target_offset", Vector2.ZERO))


func _role_position(role: String) -> Vector2:
	match role:
		ROLE_BAG:
			return _bag_origin
		ROLE_WALLET:
			return _wallet_position
		_:
			return _station_position


func _local_point(point: Vector2, already_local: bool) -> Vector2:
	return point if already_local else to_local(point)


func _ensure_pool(required_size: int) -> void :
	var safe_size: = clampi(required_size, 1, ABSOLUTE_VISUAL_CAP)
	while _pool.size() < safe_size:
		_pool.append({"active": false})


func _clear_visuals() -> void :
	for slot_index in range(_pool.size()):
		_pool[slot_index] = {"active": false}


func _first_free_slot() -> int:
	for slot_index in range(mini(_pool.size(), _active_visual_cap)):
		if not bool(_pool[slot_index].get("active", false)):
			return slot_index
	return -1


func _active_visual_count() -> int:
	var count: = 0
	for slot_index in range(mini(_pool.size(), _active_visual_cap)):
		if bool(_pool[slot_index].get("active", false)):
			count += 1
	return count


func _flight_phase_estimated_duration() -> float:
	var longest_duration: = MIN_FLIGHT_DURATION
	for spec in _phase_specs:
		longest_duration = maxf(longest_duration, float(spec.get("duration", MIN_FLIGHT_DURATION)))
	var waves: = ceili(float(_phase_specs.size()) / float(maxi(1, _active_visual_cap)))
	return _phase_spawn_window + longest_duration * float(maxi(1, waves))


func _batch_texture(batch: Dictionary) -> Texture2D:
	var direct_texture: Texture2D = batch.get("texture") as Texture2D
	if direct_texture != null:
		return direct_texture
	var texture_path: = String(batch.get("texture_path", ""))
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		return null
	return ResourceLoader.load(texture_path) as Texture2D


func _batch_size(batch: Dictionary, fallback: Vector2) -> Vector2:
	var value: Variant = batch.get("size", fallback)
	if value is Vector2:
		return Vector2(value)
	if value is float or value is int:
		return Vector2.ONE * maxf(1.0, float(value))
	return fallback


func _batch_color(batch: Dictionary, fallback: Color) -> Color:
	var value: Variant = batch.get("tint", fallback)
	return Color(value) if value is Color else fallback


func _option_size(key: String, fallback: Vector2) -> Vector2:
	var value: Variant = _options.get(key, fallback)
	if value is Vector2:
		return Vector2(value)
	if value is float or value is int:
		return Vector2.ONE * maxf(1.0, float(value))
	return fallback


func _option_color(key: String, fallback: Color) -> Color:
	var value: Variant = _options.get(key, fallback)
	return Color(value) if value is Color else fallback


func _option_texture(key: String, fallback: Texture2D) -> Texture2D:
	var direct_texture: Texture2D = _options.get(key) as Texture2D
	if direct_texture != null:
		return direct_texture
	var texture_path: = String(_options.get("%s_path" % key, ""))
	if not texture_path.is_empty() and ResourceLoader.exists(texture_path):
		return ResourceLoader.load(texture_path) as Texture2D
	return fallback


func _radial_offset(seed: int, radius: float) -> Vector2:
	var angle: = _noise01(seed) * TAU
	var scaled_radius: = radius * lerpf(0.35, 1.0, _noise01(seed + 1))
	return Vector2.from_angle(angle) * scaled_radius


func _noise01(seed: int) -> float:
	var value: = sin(float(seed) * 12.9898 + 78.233) * 43758.5453
	return value - floorf(value)
