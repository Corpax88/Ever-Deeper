extends RefCounted



const OPTICAL_BOUNDS: = {
	"stone": Rect2(0, 0, 256, 211),
	"copper": Rect2(0, 0, 256, 239),
	"gold": Rect2(0, 0, 512, 500),
	"moonglass": Rect2(9, 8, 237, 240),
	"starshard": Rect2(36, 8, 183, 240),
	"emberstone": Rect2(39, 58, 184, 132),
	"sunslag": Rect2(64, 50, 157, 140),
	"astralite": Rect2(50, 28, 166, 194),
	"crownstone": Rect2(48, 30, 161, 193),
	"deepstone": Rect2(8, 19, 240, 218),
	"rootiron": Rect2(52, 56, 149, 148),
	"ambercore": Rect2(46, 48, 151, 155),
	"prismite": Rect2(8, 15, 240, 225),
	"lunacore": Rect2(15, 8, 225, 240),
	"magmaite": Rect2(53, 37, 151, 164),
	"furnaceheart": Rect2(55, 37, 138, 170),
	"voidglass": Rect2(41, 31, 181, 189),
	"singularity": Rect2(45, 27, 173, 198),
	"burrowsteel": Rect2(48, 37, 163, 174),
	"phasecrystal": Rect2(40, 8, 175, 240),
	"infernium": Rect2(62, 24, 129, 192),
}

const RARE_RESOURCES: = {
	"gold": true,
	"starshard": true,
	"sunslag": true,
	"crownstone": true,
	"ambercore": true,
	"lunacore": true,
	"furnaceheart": true,
	"singularity": true,
	"phasecrystal": true,
	"infernium": true,
}

const NORMAL_VISIBLE_EXTENT: = 80.0
const RARE_VISIBLE_EXTENT: = 92.0


static func resource_key(kind: String) -> String:
	return "gold" if kind == "coin" else kind


static func is_rare(kind: String) -> bool:
	return RARE_RESOURCES.has(resource_key(kind))


static func visible_extent(kind: String) -> float:
	return RARE_VISIBLE_EXTENT if is_rare(kind) else NORMAL_VISIBLE_EXTENT


static func optical_bounds(kind: String, texture: Texture2D) -> Rect2:
	if texture == null:
		return Rect2()
	var fallback: = Rect2(Vector2.ZERO, Vector2(texture.get_size()))
	var bounds: Rect2 = OPTICAL_BOUNDS.get(resource_key(kind), fallback)
	return bounds


static func texture_scale(kind: String, texture: Texture2D) -> float:
	var bounds: = optical_bounds(kind, texture)
	var longest_visible_edge: = maxf(bounds.size.x, bounds.size.y)
	if longest_visible_edge <= 0.0:
		return 1.0
	return visible_extent(kind) / longest_visible_edge


static func sprite_scale(kind: String, texture: Texture2D) -> Vector2:
	return Vector2.ONE * texture_scale(kind, texture)


static func sprite_offset(kind: String, texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2.ZERO
	var texture_size: = Vector2(texture.get_size())
	return texture_size * 0.5 - optical_bounds(kind, texture).get_center()


static func draw_rect(kind: String, texture: Texture2D, center: Vector2, pulse: float = 1.0) -> Rect2:
	if texture == null:
		return Rect2(center, Vector2.ZERO)
	var scale_factor: = texture_scale(kind, texture) * pulse
	var bounds: = optical_bounds(kind, texture)
	var texture_size: = Vector2(texture.get_size())
	return Rect2(center - bounds.get_center() * scale_factor, texture_size * scale_factor)


static func debug_snapshot() -> Dictionary:
	return {
		"presentation": "sprite_only",
		"normal_visible_extent": NORMAL_VISIBLE_EXTENT,
		"rare_visible_extent": RARE_VISIBLE_EXTENT,
	}
