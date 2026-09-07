class_name DeepheartWorld
extends Node2D

signal context_changed(context: String)
signal message_changed(message: String)
signal exit_requested
signal finale_completed

const HeadlampBeamScript = preload("res://scripts/lighting/headlamp_beam.gd")

const WORLD_SIZE: = Vector2(2400, 1080)
const WALKABLE_RECT: = Rect2(110, 690, 2180, 178)
const PLAYER_SPAWN: = Vector2(590, 776)
const EXIT_POSITION: = Vector2(440, 770)
const EXIT_RADIUS: = 124.0
const CORE_POSITION: = Vector2(1900, 870)
const CORE_CONTEXT_POSITION: = Vector2(1900, 748)
const CORE_RADIUS: = 176.0
const SEAL_RADIUS: = 142.0
const SEAL_MAX_HP: = 2150
const FINALE_DURATION: = 4.8
const FINALE_REVEAL_HOLD: = 1.6
const FINALE_BUILD_DURATION: = FINALE_DURATION - FINALE_REVEAL_HOLD
const FINALE_FIRST_SEAL_BEAT: = 0.22
const FINALE_SEAL_BEAT_SPACING: = 0.48
const FINALE_SEAL_RAMP: = 0.34
const FINALE_CORE_BUILD_START: = 2.05
const VISUAL_REFRESH_INTERVAL: = 1.0 / 30.0
const BACKGROUND_TEXTURE: = preload("res://assets/deepheart/deepheart-chamber-background.png")
const CORE_TEXTURE: = preload("res://assets/deepheart/deepheart-core-machine.png")
const SEAL_TEXTURES: = {
	"mossvein": preload("res://assets/rootwound/ambercore-node.png"),
	"moonglass": preload("res://assets/prismatic/lunacore-node.png"),
	"emberdeep": preload("res://assets/molten/furnaceheart-node.png"),
	"starfall": preload("res://assets/voidstar/singularity-node.png"),
}
const SEAL_COLORS: = {
	"mossvein": Color("ffc85a"),
	"moonglass": Color("79e9ff"),
	"emberdeep": Color("ff7848"),
	"starfall": Color("bd8cff"),
}
const SEAL_POSITIONS: = {
	"mossvein": Vector2(1425, 752),
	"moonglass": Vector2(1600, 735),
	"emberdeep": Vector2(1780, 735),
	"starfall": Vector2(1960, 752),
}
const SEAL_ORDER: = ["mossvein", "moonglass", "emberdeep", "starfall"]
const SEAL_CORE_INTAKES: = {
	"mossvein": Vector2(1772, 534),
	"moonglass": Vector2(1828, 622),
	"emberdeep": Vector2(1972, 622),
	"starfall": Vector2(2032, 534),
}
const CORE_HEART_POSITION: = Vector2(1900, 516)

@onready var player: CharacterBody2D = $Player
@onready var darkness: CanvasModulate = $Darkness
@onready var world_lights: Node2D = $WorldLights

var active: = false
var active_context: = ""
var external_mine_held: = false
var seal_state: Dictionary = {}
var seal_sprites: Dictionary = {}
var seal_lights: Dictionary = {}
var seal_base_scales: Dictionary = {}
var seal_pedestals: Dictionary = {}
var seal_pedestal_rims: Dictionary = {}
var seal_conduits: Dictionary = {}
var background_sprite: Sprite2D
var core_sprite: Sprite2D
var core_base_scale: = Vector2.ONE
var core_base_position: = Vector2.ZERO
var core_light: PointLight2D
var visual_time: = 0.0
var visual_refresh_elapsed: = VISUAL_REFRESH_INTERVAL
var mining_active: = false
var mining_elapsed: = 0.0
var mining_duration: = 0.66
var mining_hit: = false
var mining_target: = ""
var finale_active: = false
var finale_elapsed: = 0.0
var finale_committed: = false
var finale_stage: = -1
var finale_reveal_announced: = false
var radial_texture: GradientTexture2D
var core_resonance_ring: Line2D
var interior_initialized: = false
var interior_build_count: = 0


func _ready() -> void :
	_configure_player(PLAYER_SPAWN)
	player.set_facing(Vector2.RIGHT)
	player.moved.connect(_on_player_moved)
	player.facing_changed.connect(_on_player_facing_changed)


func _ensure_interior_initialized() -> void :
	if interior_initialized:
		return
	_build_environment()
	_build_seals()
	_build_lighting()
	interior_initialized = true
	interior_build_count += 1
	_restore_finale_state()
	_update_visuals()


func set_active(enabled: bool, entering: bool = false) -> void :
	if enabled:
		_ensure_interior_initialized()
	active = enabled
	visible = enabled
	process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	player.control_enabled = enabled and not finale_active
	player.camera.enabled = enabled
	if enabled:
		player.prepare_visual_cache()
	else:
		player.release_visual_cache()
	external_mine_held = false
	_cancel_mining()
	if not enabled:
		_set_context("")
		return
	_restore_finale_state()
	if entering:
		player.global_position = PLAYER_SPAWN
		player.set_facing(Vector2.RIGHT)
		if RunState.has_method("begin_final_expedition") and not bool(RunState.deep_elevator_status().get("final_expedition_begun", false)):
			RunState.begin_final_expedition()
	player.camera.make_current()
	player.camera.reset_smoothing()
	_update_context(player.global_position)
	message_changed.emit("THE DEEPHEART · four worlds, one final resonance")


func reset_runtime_state() -> void :
	external_mine_held = false
	_cancel_mining()
	finale_active = false
	finale_elapsed = 0.0
	finale_committed = false
	finale_stage = -1
	finale_reveal_announced = false
	visual_time = 0.0
	visual_refresh_elapsed = VISUAL_REFRESH_INTERVAL
	player.modulate = Color.WHITE
	player.control_enabled = active
	_set_context("")
	if not interior_initialized:
		return
	for seal_id_value in SEAL_ORDER:
		seal_state[String(seal_id_value)] = {
			"hp": SEAL_MAX_HP,
			"opened": false,
			"hits": 0,
		}
	_update_visuals()


func set_mine_held(held: bool) -> void :
	external_mine_held = held


func interact() -> bool:
	if not active:
		return false
	match active_context:
		"deepheart_exit":
			exit_requested.emit()
			return true
		"deepheart_core":
			if not _all_seals_open():
				AudioDirector.play_blocked()
				message_changed.emit("Four resonances must reach the Deepheart")
				return false
			_start_finale()
			return true
		_:
			if active_context.begins_with("deepheart_seal:"):
				message_changed.emit("Hold MINE to open this resonance seal")
				return true
	return false


func _process(delta: float) -> void :
	if not active:
		return
	visual_time += maxf(0.0, delta)
	if finale_active:
		_advance_finale(delta)
	else:
		_update_mining(delta)
	visual_refresh_elapsed += maxf(0.0, delta)
	if visual_refresh_elapsed >= VISUAL_REFRESH_INTERVAL:
		visual_refresh_elapsed = fposmod(visual_refresh_elapsed, VISUAL_REFRESH_INTERVAL)
		_update_visuals()


func _build_environment() -> void :
	background_sprite = Sprite2D.new()
	background_sprite.name = "DeepheartChamber"
	background_sprite.texture = BACKGROUND_TEXTURE
	background_sprite.centered = false
	var background_size: = Vector2(BACKGROUND_TEXTURE.get_size())
	var fill_scale: = maxf(WORLD_SIZE.x / background_size.x, WORLD_SIZE.y / background_size.y)
	background_sprite.scale = Vector2.ONE * fill_scale
	background_sprite.position = Vector2(0.0, WORLD_SIZE.y - background_size.y * fill_scale)
	background_sprite.z_index = -20
	background_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background_sprite)

	core_sprite = _create_bottom_anchored_sprite(CORE_TEXTURE, CORE_POSITION, Vector2(810, 690), 4)
	core_sprite.name = "DeepheartCoreMachine"
	core_base_scale = core_sprite.scale
	core_base_position = core_sprite.position


func _build_seals() -> void :
	seal_state.clear()
	for seal_id_value in SEAL_ORDER:
		var seal_id: = String(seal_id_value)
		_build_seal_fixture(seal_id)
		var texture: Texture2D = SEAL_TEXTURES[seal_id]
		var sprite: = Sprite2D.new()
		sprite.name = "%sSeal" % seal_id.capitalize()
		sprite.texture = texture
		sprite.position = Vector2(SEAL_POSITIONS[seal_id])
		var target_size: = 90.0 if seal_id != "starfall" else 96.0
		sprite.scale = Vector2.ONE * (target_size / maxf(float(texture.get_width()), float(texture.get_height())))
		sprite.z_index = 6
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		seal_sprites[seal_id] = sprite
		seal_base_scales[seal_id] = sprite.scale
		seal_state[seal_id] = {"hp": SEAL_MAX_HP, "opened": false, "hits": 0}
	core_resonance_ring = Line2D.new()
	core_resonance_ring.name = "CoreResonanceRing"
	core_resonance_ring.points = _circle_points(CORE_HEART_POSITION, 91.0, 40)
	core_resonance_ring.width = 7.0
	core_resonance_ring.default_color = Color(0.5, 0.94, 1.0, 0.0)
	core_resonance_ring.joint_mode = Line2D.LINE_JOINT_ROUND
	core_resonance_ring.z_index = 5
	add_child(core_resonance_ring)


func _build_seal_fixture(seal_id: String) -> void :
	var seal_position: = Vector2(SEAL_POSITIONS[seal_id])
	var seal_color: = Color(SEAL_COLORS[seal_id])
	var pedestal: = Polygon2D.new()
	pedestal.name = "%sPedestal" % seal_id.capitalize()
	pedestal.polygon = PackedVector2Array([
		seal_position + Vector2(-54, 28),
		seal_position + Vector2(54, 28),
		seal_position + Vector2(68, 72),
		seal_position + Vector2(-68, 72),
	])
	pedestal.color = Color(0.035, 0.055, 0.068, 0.96)
	pedestal.z_index = 5
	add_child(pedestal)
	seal_pedestals[seal_id] = pedestal

	var rim: = Line2D.new()
	rim.name = "%sPedestalRim" % seal_id.capitalize()
	rim.points = PackedVector2Array([
		seal_position + Vector2(-54, 28),
		seal_position + Vector2(54, 28),
		seal_position + Vector2(68, 72),
		seal_position + Vector2(-68, 72),
		seal_position + Vector2(-54, 28),
	])
	rim.width = 4.0
	rim.default_color = Color(seal_color, 0.3)
	rim.joint_mode = Line2D.LINE_JOINT_ROUND
	rim.z_index = 5
	add_child(rim)
	seal_pedestal_rims[seal_id] = rim

	var intake: = Vector2(SEAL_CORE_INTAKES[seal_id])
	var conduit: = Line2D.new()
	conduit.name = "%sConduit" % seal_id.capitalize()
	conduit.points = PackedVector2Array([
		seal_position + Vector2(0, 48),
		seal_position + Vector2(0, 82),
		Vector2(lerpf(seal_position.x, intake.x, 0.58), 822.0),
		intake,
	])
	conduit.width = 9.0
	conduit.default_color = Color(seal_color, 0.08)
	conduit.joint_mode = Line2D.LINE_JOINT_ROUND
	conduit.begin_cap_mode = Line2D.LINE_CAP_ROUND
	conduit.end_cap_mode = Line2D.LINE_CAP_ROUND
	conduit.z_index = 5
	add_child(conduit)
	seal_conduits[seal_id] = conduit


func _build_lighting() -> void :
	radial_texture = _make_radial_texture()
	for seal_id_value in SEAL_ORDER:
		var seal_id: = String(seal_id_value)
		var light: = PointLight2D.new()
		light.name = "%sResonanceLight" % seal_id.capitalize()
		light.position = Vector2(SEAL_POSITIONS[seal_id])
		light.texture = radial_texture
		light.texture_scale = 128.0 / 256.0
		light.energy = 0.34
		light.color = Color(SEAL_COLORS[seal_id])
		world_lights.add_child(light)
		seal_lights[seal_id] = light
	core_light = PointLight2D.new()
	core_light.name = "DeepheartCoreLight"
	core_light.position = CORE_POSITION + Vector2(-45, -210)
	core_light.texture = radial_texture
	core_light.texture_scale = 330.0 / 256.0
	core_light.energy = 0.3
	core_light.color = Color("8feaff")
	world_lights.add_child(core_light)
	var headlamp: = HeadlampBeamScript.new()
	headlamp.name = "PremiumHeadlamp"
	headlamp.position = Vector2(0, -48)
	player.add_child(headlamp)
	headlamp.configure(Color("ffd995"), Vector2(player.facing_vector), 0.0, 620.0)
	if player.camera.has_method("set_cave_headlamp_framing"):
		player.camera.set_cave_headlamp_framing(true, Vector2(player.facing_vector))


func _configure_player(position: Vector2) -> void :
	player.configure(position, WORLD_SIZE, float(GameData.data.PLAYER_SPEED) * RunState.movement_speed_multiplier(), _resolve_motion)


func _resolve_motion(origin: Vector2, motion: Vector2) -> Vector2:
	var result: = origin + motion
	result.x = clampf(result.x, WALKABLE_RECT.position.x, WALKABLE_RECT.end.x)
	result.y = clampf(result.y, WALKABLE_RECT.position.y, WALKABLE_RECT.end.y)
	return result


func _on_player_moved(world_position: Vector2) -> void :
	_update_context(world_position)


func _on_player_facing_changed(direction: Vector2) -> void :
	var headlamp: = player.get_node_or_null("PremiumHeadlamp")
	if headlamp != null and headlamp.has_method("set_direction"):
		headlamp.set_direction(direction)
	if player.camera.has_method("set_headlamp_direction"):
		player.camera.set_headlamp_direction(direction)


func _update_context(world_position: Vector2) -> void :
	if finale_active:
		_set_context("")
		return
	var next: = ""
	if world_position.distance_to(EXIT_POSITION) <= EXIT_RADIUS:
		next = "deepheart_exit"
	else:
		var nearest: = _nearest_closed_seal(world_position)
		if not nearest.is_empty() and world_position.distance_to(Vector2(SEAL_POSITIONS[nearest])) <= _effective_seal_range():
			next = "deepheart_seal:%s" % nearest
		elif world_position.distance_to(CORE_CONTEXT_POSITION) <= CORE_RADIUS:
			next = "deepheart_core"
	_set_context(next)


func _set_context(next: String) -> void :
	if next == active_context:
		return
	active_context = next
	context_changed.emit(active_context)


func _nearest_closed_seal(world_position: Vector2) -> String:
	var best: = ""
	var best_distance: = INF
	for seal_id_value in SEAL_ORDER:
		var seal_id: = String(seal_id_value)
		if bool(Dictionary(seal_state[seal_id]).opened):
			continue
		var distance: = world_position.distance_squared_to(Vector2(SEAL_POSITIONS[seal_id]))
		if distance < best_distance:
			best_distance = distance
			best = seal_id
	return best


func _effective_seal_range() -> float:
	return SEAL_RADIUS * RunState.endless_tool_range_multiplier()


func _update_mining(delta: float) -> void :
	var held: = external_mine_held or Input.is_action_pressed("mine")
	var target: = _nearest_closed_seal(player.global_position)
	if not held or target.is_empty() or player.global_position.distance_to(Vector2(SEAL_POSITIONS[target])) > _effective_seal_range():
		_cancel_mining()
		return
	if not mining_active or mining_target != target:
		mining_active = true
		mining_target = target
		mining_elapsed = 0.0
		mining_hit = false
		mining_duration = _seal_mining_duration(_current_tool())
		player.set_facing((Vector2(SEAL_POSITIONS[target]) - player.global_position).normalized())
	mining_elapsed += maxf(0.0, delta)
	var progress: = clampf(mining_elapsed / maxf(0.001, mining_duration), 0.0, 1.0)
	player.set_mining_visual(true, progress, 0.0, 0.38)
	if not mining_hit and progress >= 0.38:
		mining_hit = true
		_strike_seal(target)
	if progress >= 1.0:
		var overflow: = maxf(0.0, mining_elapsed - mining_duration)
		var next_target: = _nearest_closed_seal(player.global_position)
		if held and not next_target.is_empty() and player.global_position.distance_to(Vector2(SEAL_POSITIONS[next_target])) <= _effective_seal_range():
			mining_active = true
			mining_target = next_target
			mining_duration = _seal_mining_duration(_current_tool())
			mining_elapsed = fposmod(overflow, maxf(0.001, mining_duration))
			mining_hit = false
			player.set_facing((Vector2(SEAL_POSITIONS[next_target]) - player.global_position).normalized())
			player.set_mining_visual(true, mining_elapsed / maxf(0.001, mining_duration), 0.0, 0.38)
		else:
			_cancel_mining()


func _cancel_mining() -> void :
	mining_active = false
	mining_elapsed = 0.0
	mining_hit = false
	mining_target = ""
	if is_instance_valid(player):
		player.set_mining_visual(false)


func _strike_seal(seal_id: String) -> void :
	if not seal_state.has(seal_id):
		return
	var state: = Dictionary(seal_state[seal_id])
	if bool(state.opened):
		return
	state.hits = int(state.hits) + 1
	state.hp = maxi(0, int(state.hp) - maxi(1, int(_current_tool().get("power", 1))))
	var reached_resonance: = int(state.hp) <= 0
	var opened: = false
	if reached_resonance:
		if RunState.has_method("open_deepheart_seal"):
			opened = bool(RunState.open_deepheart_seal(seal_id)) or _canonical_seal_open(seal_id)
		else:
			opened = true
		if not opened:
			state.hp = 1
	state.opened = opened
	seal_state[seal_id] = state
	AudioDirector.play_mining(_seal_resource_id(seal_id), opened, false)
	if reached_resonance and not opened:
		AudioDirector.play_blocked()
		message_changed.emit("The resonance cannot seat until the final descent is ready")
		_cancel_mining()
		return
	if opened:
		AudioDirector.play_discovery(true)
		message_changed.emit("%s RESONANCE OPEN" % seal_id.to_upper())
		_cancel_mining()
		_update_context(player.global_position)
		if _all_seals_open():
			message_changed.emit("THE DEEPHEART IS LISTENING · approach the core")


func _seal_resource_id(seal_id: String) -> String:
	match seal_id:
		"mossvein": return "ambercore"
		"moonglass": return "lunacore"
		"emberdeep": return "furnaceheart"
		_: return "singularity"


func _current_tool() -> Dictionary:
	var drill_level: = clampi(int(RunState.drill_level), 0, int(GameData.data.DRILLS.size()) - 1)
	if drill_level > 0:
		var drill: = Dictionary(GameData.data.DRILLS[drill_level]).duplicate(true)
		if RunState.has_method("attune_tool_with_starforge"):
			return Dictionary(RunState.attune_tool_with_starforge(drill))
		return drill
	var tool: = Dictionary(RunState.current_pickaxe()).duplicate(true)
	var variant_id: = String(RunState.starforge_variant)
	if not variant_id.is_empty() and GameData.data.STARFORGE_VARIANTS.has(variant_id):
		var variant: = Dictionary(GameData.data.STARFORGE_VARIANTS[variant_id])
		tool.power = roundi(float(tool.power) * float(variant.powerMultiplier))
		tool.cooldown = float(tool.cooldown) * float(variant.cooldownMultiplier)
	return RunState.apply_tool_forge_effects(tool)


func _seal_mining_duration(tool: Dictionary) -> float:


	return clampf(float(tool.get("cooldown", 0.72)) * 8.0, 0.3, 0.72)


func _all_seals_open() -> bool:
	for seal_id_value in SEAL_ORDER:
		if not bool(Dictionary(seal_state[String(seal_id_value)]).opened):
			return false
	if RunState.has_method("deepheart_seal_status"):
		var persisted: = Dictionary(RunState.deepheart_seal_status())
		if not bool(persisted.get("all_open", false)):
			return false
		var persisted_seals: = Dictionary(persisted.get("seals", {}))
		for seal_id_value in SEAL_ORDER:
			if not bool(persisted_seals.get(String(seal_id_value), false)):
				return false
	return true


func _canonical_seal_open(seal_id: String) -> bool:
	if not RunState.has_method("deepheart_seal_status"):
		return false
	var persisted: = Dictionary(RunState.deepheart_seal_status())
	return bool(Dictionary(persisted.get("seals", {})).get(seal_id, false))


func _start_finale() -> void :
	if finale_active or finale_committed:
		return
	if not _all_seals_open():
		AudioDirector.play_blocked()
		message_changed.emit("Four canonical resonances must reach the Deepheart")
		return
	finale_active = true
	finale_elapsed = 0.0
	finale_stage = -1
	finale_reveal_announced = false
	player.control_enabled = false
	player.set_mining_visual(false)
	player.modulate = Color.WHITE
	_set_context("")
	AudioDirector.play_transition("depth")
	message_changed.emit("DEEPHEART ATTUNEMENT")


func _advance_finale(delta: float) -> void :
	finale_elapsed = minf(FINALE_DURATION, finale_elapsed + maxf(0.0, delta))
	var next_stage: = -1
	if finale_elapsed >= FINALE_FIRST_SEAL_BEAT:
		next_stage = mini(
			SEAL_ORDER.size() - 1,
			floori((finale_elapsed - FINALE_FIRST_SEAL_BEAT) / FINALE_SEAL_BEAT_SPACING)
		)
	if next_stage > finale_stage:
		finale_stage = next_stage
		var seal_id: = String(SEAL_ORDER[finale_stage])
		AudioDirector.play_mining(_seal_resource_id(seal_id), false, false)
		message_changed.emit("%s CONDUIT RESONATES" % seal_id.to_upper())
	if not finale_reveal_announced and finale_elapsed >= FINALE_BUILD_DURATION:
		finale_reveal_announced = true
		AudioDirector.play_discovery(true)
		message_changed.emit("THE DEEPHEART BEATS AGAIN")
	if finale_elapsed < FINALE_DURATION or finale_committed:
		return
	var completed: = true
	if RunState.has_method("complete_final_expedition"):
		completed = bool(RunState.complete_final_expedition()) or bool(RunState.get("victory"))
	if not completed:
		AudioDirector.play_blocked()
		message_changed.emit("The Deepheart sequence is incomplete")
		finale_active = false
		finale_elapsed = 0.0
		finale_stage = -1
		finale_reveal_announced = false
		player.control_enabled = true
		player.modulate = Color.WHITE
		return
	finale_committed = true
	finale_active = false
	player.control_enabled = true
	player.modulate = Color.WHITE
	message_changed.emit("EVER DEEPER · THE HEART BEATS AGAIN")
	finale_completed.emit()


func _restore_finale_state() -> void :
	var persisted_seals: Dictionary = {}
	if RunState.has_method("deepheart_seal_status"):
		persisted_seals = Dictionary(RunState.deepheart_seal_status().get("seals", {}))
	for seal_id_value in SEAL_ORDER:
		var seal_id: = String(seal_id_value)
		var opened: = bool(persisted_seals.get(seal_id, false))
		var state: = Dictionary(seal_state.get(seal_id, {"hp": SEAL_MAX_HP, "opened": false, "hits": 0}))
		state.opened = opened
		state.hp = 0 if opened else clampi(int(state.get("hp", SEAL_MAX_HP)), 1, SEAL_MAX_HP)
		seal_state[seal_id] = state
	finale_committed = bool(RunState.get("victory"))
	if finale_committed:
		finale_active = false
		finale_elapsed = FINALE_DURATION
		finale_stage = SEAL_ORDER.size() - 1
		finale_reveal_announced = true
	player.modulate = Color.WHITE


func _update_visuals() -> void :
	for index in range(SEAL_ORDER.size()):
		var seal_id: = String(SEAL_ORDER[index])
		var state: = Dictionary(seal_state[seal_id])
		var sprite: Sprite2D = seal_sprites[seal_id]
		var light: PointLight2D = seal_lights[seal_id]
		var pedestal: Polygon2D = seal_pedestals[seal_id]
		var rim: Line2D = seal_pedestal_rims[seal_id]
		var conduit: Line2D = seal_conduits[seal_id]
		var seal_color: = Color(SEAL_COLORS[seal_id])
		var pulse: = 0.5 + 0.5 * sin(visual_time * (2.1 if bool(state.opened) else 4.6) + float(index) * 1.4)
		var hp_ratio: = clampf(float(state.hp) / float(SEAL_MAX_HP), 0.0, 1.0)
		var finale_strength: = _finale_seal_strength(index)
		if bool(state.opened):
			var seated_scale: = 0.86 + pulse * 0.035 + finale_strength * 0.055
			sprite.scale = Vector2(seal_base_scales[seal_id]) * seated_scale
			sprite.modulate = Color(seal_color, 0.56 + pulse * 0.15 + finale_strength * 0.24)
			light.energy = 0.58 + pulse * 0.18 + finale_strength * 0.58
			light.texture_scale = (142.0 + pulse * 16.0 + finale_strength * 28.0) / 256.0
			pedestal.color = Color(0.045 + seal_color.r * 0.045, 0.06 + seal_color.g * 0.045, 0.074 + seal_color.b * 0.045, 0.98)
			rim.default_color = Color(seal_color, 0.48 + finale_strength * 0.42)
			conduit.default_color = Color(seal_color, 0.13 + finale_strength * (0.58 + pulse * 0.18))
			conduit.width = 8.0 + finale_strength * (3.0 + pulse * 2.0)
		else:
			sprite.scale = Vector2(seal_base_scales[seal_id]) * (0.97 + pulse * 0.025)
			sprite.modulate = Color(lerpf(0.72, 1.0, hp_ratio), lerpf(0.74, 1.0, hp_ratio), lerpf(0.78, 1.0, hp_ratio), 1.0)
			light.energy = 0.22 + (1.0 - hp_ratio) * 0.3 + pulse * 0.07
			pedestal.color = Color(0.035, 0.055, 0.068, 0.96)
			rim.default_color = Color(seal_color, 0.22 + (1.0 - hp_ratio) * 0.18)
			conduit.default_color = Color(seal_color, 0.035)
			conduit.width = 8.0
	var opened_ratio: = 0.0
	for seal_id_value in SEAL_ORDER:
		opened_ratio += 0.25 if bool(Dictionary(seal_state[String(seal_id_value)]).opened) else 0.0
	var core_strength: = _finale_core_strength()
	var core_pulse: = 0.5 + 0.5 * sin(visual_time * lerpf(1.35, 3.55, maxf(opened_ratio, core_strength)))
	var scale_gain: = opened_ratio * 0.008 + core_strength * (0.02 + core_pulse * 0.014)
	core_sprite.scale = core_base_scale * (1.0 + scale_gain)
	var texture_size: = Vector2(core_sprite.texture.get_size())
	var growth: = texture_size * core_base_scale * scale_gain
	core_sprite.position = core_base_position - Vector2(growth.x * 0.5, growth.y)
	core_sprite.modulate = Color(
		lerpf(0.88, 0.98, opened_ratio) + core_strength * 0.02,
		lerpf(0.9, 0.98, opened_ratio) + core_strength * 0.02,
		0.94 + core_pulse * 0.035 + core_strength * 0.025,
		1.0
	)
	core_light.energy = 0.28 + opened_ratio * 0.42 + core_strength * 0.9 + core_pulse * 0.1
	core_light.texture_scale = (280.0 + opened_ratio * 100.0 + core_strength * 172.0) / 256.0
	core_resonance_ring.default_color = Color(0.52, 0.94, 1.0, opened_ratio * 0.05 + core_strength * (0.52 + core_pulse * 0.2))
	core_resonance_ring.width = 6.0 + core_strength * (3.0 + core_pulse * 2.0)
	darkness.color = Color(
		lerpf(0.48, 0.72, core_strength),
		lerpf(0.44, 0.66, core_strength),
		lerpf(0.58, 0.79, core_strength),
		1.0
	)
	if finale_active:
		var reveal_fade: = _smooth_progress(2.55, FINALE_BUILD_DURATION, finale_elapsed)
		player.modulate = Color(1.0, 1.0, 1.0, lerpf(1.0, 0.14, reveal_fade))


func _finale_seal_strength(index: int) -> float:
	if finale_committed:
		return 1.0
	if not finale_active:
		return 0.0
	var start: = FINALE_FIRST_SEAL_BEAT + float(index) * FINALE_SEAL_BEAT_SPACING
	return _smooth_progress(start, start + FINALE_SEAL_RAMP, finale_elapsed)


func _finale_core_strength() -> float:
	if finale_committed:
		return 1.0
	if not finale_active:
		return 0.0
	return _smooth_progress(FINALE_CORE_BUILD_START, FINALE_BUILD_DURATION, finale_elapsed)


func _smooth_progress(from: float, to: float, value: float) -> float:
	var linear: = clampf((value - from) / maxf(0.001, to - from), 0.0, 1.0)
	return linear * linear * (3.0 - 2.0 * linear)


func _create_bottom_anchored_sprite(texture: Texture2D, anchor: Vector2, max_size: Vector2, z: int) -> Sprite2D:
	var texture_size: = Vector2(texture.get_size())
	var factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var size: = texture_size * factor
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = anchor - Vector2(size.x * 0.5, size.y)
	sprite.scale = Vector2.ONE * factor
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	return sprite


func _circle_points(center: Vector2, radius: float, segments: int) -> PackedVector2Array:
	var points: = PackedVector2Array()
	for index in range(maxi(8, segments) + 1):
		var angle: = TAU * float(index) / float(maxi(8, segments))
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _make_radial_texture() -> GradientTexture2D:
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.48), Color(1, 1, 1, 0)])
	var texture: = GradientTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func debug_snapshot() -> Dictionary:
	var opened: Array[String] = []
	for seal_id_value in SEAL_ORDER:
		var seal_id: = String(seal_id_value)
		if seal_state.has(seal_id) and bool(Dictionary(seal_state[seal_id]).opened):
			opened.append(seal_id)
	return {
		"initialized": interior_initialized,
		"build_count": interior_build_count,
		"background_asset": BACKGROUND_TEXTURE.resource_path,
		"core_asset": CORE_TEXTURE.resource_path,
		"world_size": WORLD_SIZE,
		"walkable_rect": WALKABLE_RECT,
		"spawn": PLAYER_SPAWN,
		"exit_position": EXIT_POSITION,
		"core_position": CORE_POSITION,
		"seal_order": SEAL_ORDER.duplicate(),
		"seal_positions": SEAL_POSITIONS.duplicate(true),
		"seal_max_hp": SEAL_MAX_HP,
		"seal_mining_range": _effective_seal_range(),
		"seal_fixture_count": seal_pedestals.size(),
		"opened": opened,
		"all_open": interior_initialized and _all_seals_open(),
		"finale_active": finale_active,
		"finale_committed": finale_committed,
		"finale_duration": FINALE_DURATION,
		"finale_reveal_hold": FINALE_REVEAL_HOLD,
		"finale_stage": finale_stage,
		"background_fit": "uniform_aspect_fill_bottom_crop",
		"light_count": world_lights.get_child_count() + 2,
		"collision_language": "visible_catwalk_bounds",
	}
