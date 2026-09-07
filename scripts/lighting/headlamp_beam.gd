class_name HeadlampBeam
extends Node2D







const BEAM_TEXTURE_SIZE: = Vector2i(256, 256)
const BEAM_HALF_ANGLE: = 0.4

static var _shared_beam_texture: ImageTexture

var preview_settings: Dictionary = {}

var beam_light: PointLight2D
var base_light_color: = Color.WHITE
var base_beam_length: = 500.0
var base_energy: float = 1.08
var applied_workshop_signature: = ""
var applied_style_id: = "standard"
var effective_range_multiplier: = 1.0
var effective_energy_multiplier: = 1.0
var effective_width_multiplier: = 1.0


func configure(
	light_color: Color,
	direction: Vector2 = Vector2.RIGHT,
	_ambient_radius: float = 0.0,
	beam_length: float = 500.0
) -> void :
	if beam_light == null:
		beam_light = PointLight2D.new()
		beam_light.name = "HelmetCone"
		beam_light.texture = _beam_texture()
		beam_light.energy = 1.08
		beam_light.offset = Vector2.ZERO
		beam_light.shadow_enabled = true
		beam_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		beam_light.shadow_filter_smooth = 2.5
		add_child(beam_light)
	_ensure_bounce(light_color)
	_ensure_occlusion()
	base_light_color = light_color
	base_beam_length = maxf(1.0, beam_length)
	_apply_endless_workshop_effects(true)
	set_direction(direction)


func set_direction(direction: Vector2) -> void :
	if direction.length_squared() <= 0.001:
		return
	_apply_endless_workshop_effects()
	rotation = direction.angle()


func refresh_workshop_effects() -> void :
	_apply_endless_workshop_effects(true)


func _apply_endless_workshop_effects(force: bool = false) -> void :
	if beam_light == null:
		return
	var settings: = _endless_light_settings()
	var signature: = "%s|%.3f|%.3f" % [
		String(settings.style),
		float(settings.range_multiplier),
		float(settings.energy_multiplier),
	]
	if not force and signature == applied_workshop_signature:
		return
	applied_workshop_signature = signature
	applied_style_id = String(settings.style)
	effective_range_multiplier = float(settings.range_multiplier)
	effective_energy_multiplier = float(settings.energy_multiplier)
	effective_width_multiplier = _style_width_multiplier(applied_style_id)
	beam_light.color = _styled_light_color(base_light_color.lightened(0.16), applied_style_id)
	beam_light.energy = base_energy * effective_energy_multiplier
	beam_light.texture_scale = (
		base_beam_length * effective_range_multiplier / (float(BEAM_TEXTURE_SIZE.x) * 0.5)
	)
	beam_light.scale = Vector2(1.0, effective_width_multiplier)


func _endless_light_settings() -> Dictionary:
	if not preview_settings.is_empty(): return preview_settings.duplicate()
	var style_id: = "standard"
	var range_multiplier: = 1.0
	var energy_multiplier: = 1.0
	if RunState.has_method("endless_loadout_status"):
		var raw_loadout: Variant = RunState.call("endless_loadout_status")
		if raw_loadout is Dictionary:
			style_id = String(Dictionary(raw_loadout).get("light", "standard"))
	if RunState.has_method("endless_light_range_multiplier"):
		range_multiplier = clampf(
			float(RunState.call("endless_light_range_multiplier")), 1.0, 1.4
		)
	if RunState.has_method("endless_light_energy_multiplier"):
		energy_multiplier = clampf(
			float(RunState.call("endless_light_energy_multiplier")), 1.0, 1.3
		)
	if style_id not in ["standard", "focused", "wide", "prismatic", "deepheart"]:
		style_id = "standard"
	return {
		"style": style_id,
		"range_multiplier": range_multiplier,
		"energy_multiplier": energy_multiplier,
	}


func _styled_light_color(color: Color, style_id: String) -> Color:
	match style_id:
		"focused":
			return color.lerp(Color("fff1c2"), 0.34)
		"wide":
			return color.lerp(Color("bdeaff"), 0.38)
		"prismatic":
			return color.lerp(Color("dfc4ff"), 0.46)
		"deepheart":
			return color.lerp(Color("ffca63"), 0.5)
	return color


func _style_width_multiplier(style_id: String) -> float:
	match style_id:
		"focused":
			return 0.76
		"wide":
			return 1.28
		"prismatic":
			return 1.1
		"deepheart":
			return 0.92
	return 1.0


static func _beam_texture() -> ImageTexture:
	if _shared_beam_texture != null:
		return _shared_beam_texture
	var image: = Image.create(BEAM_TEXTURE_SIZE.x, BEAM_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	var half_height: float = float(BEAM_TEXTURE_SIZE.y) * 0.5
	for y in BEAM_TEXTURE_SIZE.y:
		for x in BEAM_TEXTURE_SIZE.x:
			var forward: float = float(x) - half_height
			var radial: float = Vector2(forward, float(y) - half_height).length() / half_height
			var angle: float = absf(atan2(float(y) - half_height, forward))
			var cone: float = 1.0 - smoothstep(BEAM_HALF_ANGLE * 0.55, BEAM_HALF_ANGLE * 1.3, angle)
			var distance_fade: float = pow(maxf(0.0, 1.0 - radial), 1.15)
			var value: float = cone * distance_fade if forward > 0.0 else 0.0
			image.set_pixel(x, y, Color(value, value, value, 1.0) if value > 0.01 else Color.TRANSPARENT)

	_shared_beam_texture = ImageTexture.create_from_image(image)
	return _shared_beam_texture


func debug_snapshot() -> Dictionary:
	var image: = _beam_texture().get_image()
	var border_alpha_max: = 0.0
	for x in BEAM_TEXTURE_SIZE.x:
		border_alpha_max = maxf(border_alpha_max, image.get_pixel(x, 0).a)
		border_alpha_max = maxf(border_alpha_max, image.get_pixel(x, BEAM_TEXTURE_SIZE.y - 1).a)
	for y in BEAM_TEXTURE_SIZE.y:
		border_alpha_max = maxf(border_alpha_max, image.get_pixel(0, y).a)
		border_alpha_max = maxf(border_alpha_max, image.get_pixel(BEAM_TEXTURE_SIZE.x - 1, y).a)
	return {
		"light_count": find_children("*", "PointLight2D", true, false).size(),
		"cone_only": false,
		"occluded": beam_light != null and beam_light.shadow_enabled,
		"origin_centered": beam_light != null and beam_light.offset == Vector2.ZERO,
		"texture_size": BEAM_TEXTURE_SIZE,
		"half_angle": BEAM_HALF_ANGLE,
		"border_alpha_max": border_alpha_max,
		"beam_length": float(beam_light.texture_scale) * float(BEAM_TEXTURE_SIZE.x) * 0.5 if beam_light != null else 0.0,
		"energy": beam_light.energy if beam_light != null else 0.0,
		"style": applied_style_id,
		"range_multiplier": effective_range_multiplier,
		"energy_multiplier": effective_energy_multiplier,
		"width_multiplier": effective_width_multiplier,
		"rotation": rotation,
	}


func _ensure_bounce(tint: Color) -> void:
	if get_node_or_null("HelmetBounce") != null:
		return
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, Color(1,1,1,0.5))
	gradient.set_color(1, Color(1,1,1,0))
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5,0.5)
	texture.fill_to = Vector2(1,0.5)
	var bounce: PointLight2D = PointLight2D.new()
	bounce.name = "HelmetBounce"
	bounce.texture = texture
	bounce.texture_scale = 1.7
	bounce.energy = 0.42
	bounce.color = tint.lightened(0.3)
	bounce.shadow_enabled = true
	bounce.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	add_child(bounce)


func _ensure_occlusion() -> void:
	var world: Node = get_parent().get_parent()
	if world.get_node_or_null("CaveLightOccluders") != null:
		return
	if world.has_method("_terrain_is_solid") or world.has_method("_is_floor") or world.get("blocks") is Dictionary:
		var occlusion: Node2D = load("res://scripts/lighting/cave_light_occluders.gd").new()
		occlusion.name = "CaveLightOccluders"
		world.add_child(occlusion)


func configure_preview(style: String, level: int) -> void:
	preview_settings = {"style": style, "range_multiplier": RunState.light_range_for_level(level), "energy_multiplier": RunState.light_energy_for_level(level)}
	configure(Color("ffd58a"), Vector2.RIGHT, 0.0, 600.0)
