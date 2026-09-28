extends RefCounted
## QA only. Reuses the exact original textures, shader, fades and draw order.
## The parent fixture owns camera movement, animation freezing and timing.

const PARITY_POSITIONS: Array[Vector2] = [
	Vector2(2050, 700), Vector2(2250, 700), Vector2(3130, 700),
	Vector2(3290, 700), Vector2(3470, 700), Vector2(4000, 700),
]
const EXPECTED: Dictionary = {
	"ember-backdrop.png": {"left": 2110.0, "right": 3470.0, "last": false, "x": 1620.0},
	"star-backdrop.png": {"left": 3290.0, "right": 4620.0, "last": true, "x": 2710.0},
}
const EPS: float = 0.002
var rows: Array[Dictionary] = []
var errors: Array[String] = []
var cropped: bool = false

func configure(world: Node2D) -> bool:
	if not rows.is_empty():
		errors.append("Probe already configured")
		return false
	if not world.global_transform.is_equal_approx(Transform2D.IDENTITY):
		errors.append("Unexpected surface world transform")
		return false
	var seen: Dictionary = {}
	for item in world.find_children("*", "Sprite2D", true, false):
		var node: Sprite2D = item as Sprite2D
		if node.texture == null or not node.material is ShaderMaterial:
			continue
		var material: ShaderMaterial = node.material as ShaderMaterial
		if material.shader == null or not material.shader.resource_path.ends_with("/biome_backdrop.gdshader"):
			continue
		var id: String = node.texture.resource_path.get_file()
		if not EXPECTED.has(id) or seen.has(id):
			errors.append("Unexpected or duplicate backdrop: " + id)
			continue
		var expected: Dictionary = EXPECTED[id]
		var size: Vector2 = Vector2(node.texture.get_size())
		var full_rect: Rect2 = Rect2(node.position, size * node.scale)
		if node.get_parent() != world or node.centered or node.flip_h or node.flip_v or node.region_enabled or not node.offset.is_zero_approx() or not is_zero_approx(node.rotation) or not is_zero_approx(node.skew):
			errors.append("Unexpected sprite geometry: " + id)
			continue
		if not full_rect.size.is_equal_approx(Vector2(2400, 1600)) or absf(full_rect.position.x - float(expected.x)) > EPS or absf(full_rect.position.y + 180.0) > EPS:
			errors.append("Unexpected original rectangle: " + id)
			continue
		var left: float = float(material.get_shader_parameter("left_edge"))
		var right: float = float(material.get_shader_parameter("right_edge"))
		var last: bool = bool(material.get_shader_parameter("last_biome"))
		if not is_equal_approx(left, float(expected.left)) or not is_equal_approx(right, float(expected.right)) or last != bool(expected.last):
			errors.append("Unexpected authored fade: " + id)
			continue
		var texel_world_width: float = full_rect.size.x / size.x
		var source_left: float = maxf(0.0, floorf((left - full_rect.position.x) / texel_world_width))
		var source_right: float = size.x if last else minf(size.x, ceilf((right - full_rect.position.x) / texel_world_width))
		var source_rect: Rect2 = Rect2(source_left, 0.0, source_right - source_left, size.y)
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = node.texture
		atlas.region = source_rect
		# Do not clamp filtering at our new edge: sample the original atlas texels.
		atlas.filter_clip = false
		rows.append({
			"id": id, "node": node, "texture": node.texture, "atlas": atlas,
			"position": node.position, "scale": node.scale,
			"material": material, "modulate": node.modulate, "self_modulate": node.self_modulate,
			"z_index": node.z_index, "texture_filter": node.texture_filter,
			"source_rect": source_rect, "full_rect": full_rect,
			"left": left, "right": right, "last": last,
			"texel_world_width": texel_world_width,
		})
		seen[id] = true
	if rows.size() != 2:
		errors.append("Expected exactly two authored backdrops")
	return errors.is_empty()

func set_crop(enabled: bool) -> bool:
	if not errors.is_empty() or rows.size() != 2:
		return false
	for row in rows:
		var node: Sprite2D = row.node
		if not is_instance_valid(node):
			errors.append("Backdrop freed during probe: " + String(row.id))
			return false
		var original_position: Vector2 = row.position
		var original_scale: Vector2 = row.scale
		var source_rect: Rect2 = row.source_rect
		node.texture = row.atlas if enabled else row.texture
		node.position = original_position + source_rect.position * original_scale if enabled else original_position
		node.scale = original_scale
	cropped = enabled
	return bool(snapshot().ok)

func restore() -> bool:
	return set_crop(false)

func snapshot() -> Dictionary:
	var failures: Array[String] = errors.duplicate()
	var geometry: Array[Dictionary] = []
	for row in rows:
		var node: Sprite2D = row.node
		if not is_instance_valid(node):
			failures.append("Missing backdrop: " + String(row.id))
			continue
		var source_rect: Rect2 = row.source_rect
		var original_position: Vector2 = row.position
		var original_scale: Vector2 = row.scale
		var full_rect: Rect2 = row.full_rect
		var crop_rect: Rect2 = Rect2(original_position + source_rect.position * original_scale, source_rect.size * original_scale)
		var positive_left: float = maxf(full_rect.position.x, float(row.left))
		# Last biome has no right fade. Keep its original right edge, not right_edge.
		var positive_right: float = full_rect.end.x if bool(row.last) else minf(full_rect.end.x, float(row.right))
		var encloses: bool = crop_rect.position.x <= positive_left + EPS and crop_rect.end.x >= positive_right - EPS
		var removed_only_zero: bool = crop_rect.position.x >= full_rect.position.x - EPS and crop_rect.end.x <= full_rect.end.x + EPS and encloses
		var rounding_bounded: bool = positive_left - crop_rect.position.x < float(row.texel_world_width) + EPS and crop_rect.end.x - positive_right < float(row.texel_world_width) + EPS
		var current_rect: Rect2 = Rect2(node.position, Vector2(node.texture.get_size()) * node.scale)
		var expected_rect: Rect2 = crop_rect if cropped else full_rect
		var expected_texture: Texture2D = row.atlas if cropped else row.texture
		var unchanged: bool = node.material == row.material and node.modulate == row.modulate and node.self_modulate == row.self_modulate and node.z_index == int(row.z_index) and node.texture_filter == int(row.texture_filter)
		var geometry_matches: bool = current_rect.is_equal_approx(expected_rect) and node.scale == original_scale and node.texture == expected_texture
		var atlas: AtlasTexture = row.atlas
		var texture_reused: bool = atlas.atlas == row.texture and atlas.get_rid() == row.texture.get_rid() and not atlas.filter_clip
		if not removed_only_zero or not rounding_bounded or not geometry_matches or not unchanged or not texture_reused:
			failures.append("Backdrop invariant failed: " + String(row.id))
		geometry.append({
			"id": row.id, "positive_alpha_enclosed": encloses,
			"removed_only_zero": removed_only_zero, "rounding_bounded": rounding_bounded,
			"appearance_properties_unchanged": unchanged, "geometry_matches": geometry_matches,
			"same_texture_rid": texture_reused,
			"full_world_bounds": [full_rect.position.x, full_rect.end.x],
			"crop_world_bounds": [crop_rect.position.x, crop_rect.end.x],
			"positive_alpha_world_bounds": [positive_left, positive_right],
			"source_region": [source_rect.position.x, source_rect.position.y, source_rect.size.x, source_rect.size.y],
			"removed_quad_fraction": 1.0 - crop_rect.size.x / full_rect.size.x,
		})
	return {"ok": failures.is_empty() and rows.size() == 2, "errors": failures, "cropped": cropped, "geometry": geometry}

