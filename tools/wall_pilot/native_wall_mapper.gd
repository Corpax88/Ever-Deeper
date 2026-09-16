extends RefCounted
## Isolated Deep study. All pieces retain their authored up direction and one
## uniform scale. Source phase belongs to the absolute world, never the cell.
## Terminating faces follow the opaque contour of the adjoining native face.
## Rectangular cuts stop underneath real opaque artwork, with no added fades.
## Native vertical-band wrap joins still require actual rendered inspection.

const PROFILE_NAMES: Array[String] = [
	"rootwound", "moonglass", "emberdeep", "voidstar", "mossvein", "bedrock",
]
# Alpha >= 128 medians measured from the existing PNGs. The leg regions include
# four native pixels beyond the measured horizontal alpha bounds.
const PROFILES: Array[Dictionary] = [
	{"edge_height": 66.0, "edge_center": 59.0, "leg_width": 112.0,
		"leg_center": 513.0, "leg_region": Rect2(431, 720, 165, 304)},
	{"edge_height": 100.0, "edge_center": 60.5, "leg_width": 115.0,
		"leg_center": 557.5, "leg_region": Rect2(486, 720, 148, 304)},
	{"edge_height": 57.0, "edge_center": 56.5, "leg_width": 117.5,
		"leg_center": 555.5, "leg_region": Rect2(475, 720, 154, 304)},
	{"edge_height": 55.0, "edge_center": 51.0, "leg_width": 94.0,
		"leg_center": 513.0, "leg_region": Rect2(454, 720, 135, 304)},
	{"edge_height": 104.0, "edge_center": 66.5, "leg_width": 298.0,
		"leg_center": 610.5, "leg_region": Rect2(420, 720, 377, 304)},
	{"edge_height": 205.0, "edge_center": 132.5, "leg_width": 243.0,
		"leg_center": 511.5, "leg_region": Rect2(372, 720, 280, 304)},
]
const CONTOUR_PATH: String = "res://tools/wall_pilot/native_wall_contours.json"
const TANGENT_OVERLAP: float = 0.25
const CORE_INSET: float = 0.75
const CONTOUR_STEP: float = 0.5
static var _contours: Array = []


static func draw_cell(canvas: CanvasItem, strip: Texture2D, corner_texture: Texture2D,
		cell: Vector2i, absolute: Vector2i, open_sides: Array, terminal_kinds: Array,
		tile: float, profile_index: int, bedrock: bool = false) -> void:
	if strip == null or corner_texture == null:
		return
	if _contours.is_empty():
		var measured: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTOUR_PATH))
		_contours = measured.profiles
	var index: int = 5 if bedrock else posmod(profile_index, 5)
	var profile: Dictionary = PROFILES[index]
	var contour: Dictionary = _contours[index]
	var thickness: float = tile * (1.5 if bedrock else 0.75)
	var floor_overlap: float = tile / (8.0 if bedrock else 12.0)
	var bias: float = thickness * 0.5 - floor_overlap
	var local_origin: Vector2 = Vector2(cell) * tile
	var absolute_offset: Vector2 = Vector2(absolute - cell) * tile
	canvas.draw_set_transform(Vector2.ZERO)
	for side in 4:
		if not bool(open_sides[side]): continue
		var ends: Vector2i = terminal_kinds[side]
		if side == 0 or side == 2:
			var center_y: float = local_origin.y + (bias if side == 0 else tile - bias)
			_draw_horizontal(canvas, strip, profile, contour, thickness, bias,
				local_origin, absolute_offset, tile, center_y, ends)
		else:
			var center_x: float = local_origin.x + (tile - bias if side == 1 else bias)
			_draw_vertical(canvas, corner_texture, profile, contour, thickness, bias,
				local_origin, absolute_offset, tile, center_x, ends)


# A terminal is 0 for a continuous run, +1 for a convex turn, -1 for a
# concave turn. Both pieces retain their own uniform UV transform. Only their
# clipping boundary changes, to a measured opaque contour of the other piece.
static func _draw_horizontal(canvas: CanvasItem, texture: Texture2D,
		profile: Dictionary, contour: Dictionary, thickness: float, bias: float,
		local_origin: Vector2, absolute_offset: Vector2, tile: float,
		center_y: float, ends: Vector2i) -> void:
	var native_scale: float = thickness / float(profile.edge_height)
	var top: float = center_y - float(profile.edge_center) * native_scale
	var height: float = texture.get_height() * native_scale
	var steps: int = ceili(height / CONTOUR_STEP) if ends != Vector2i.ZERO else 1
	var left: PackedVector2Array = PackedVector2Array()
	var right: PackedVector2Array = PackedVector2Array()
	for sample in range(steps + 1):
		var y: float = top + height * float(sample) / steps
		var x0: float = local_origin.x - TANGENT_OVERLAP
		var x1: float = local_origin.x + tile + TANGENT_OVERLAP
		if ends.x != 0:
			x0 = _vertical_core_end(profile, contour, thickness, bias,
				local_origin.x, y + absolute_offset.y, true, ends.x)
		if ends.y != 0:
			x1 = _vertical_core_end(profile, contour, thickness, bias,
				local_origin.x + tile, y + absolute_offset.y, false, ends.y)
		if x0 > x1:
			var midpoint: float = (x0 + x1) * 0.5
			x0 = midpoint - 0.001
			x1 = midpoint + 0.001
		left.append(Vector2(x0, y))
		right.append(Vector2(x1, y))
	right.reverse()
	left.append_array(right)
	_draw_wrapped_native(canvas, texture, left, native_scale,
		Vector2(-absolute_offset.x, top), 0, -absolute_offset.x, texture.get_width())


static func _draw_vertical(canvas: CanvasItem, texture: Texture2D,
		profile: Dictionary, contour: Dictionary, thickness: float, bias: float,
		local_origin: Vector2, absolute_offset: Vector2, tile: float,
		center_x: float, ends: Vector2i) -> void:
	var native_scale: float = thickness / float(profile.leg_width)
	var region: Rect2 = Rect2(profile.leg_region)
	var left: float = center_x + (region.position.x - float(profile.leg_center)) * native_scale
	var width: float = region.size.x * native_scale
	var steps: int = ceili(width / CONTOUR_STEP) if ends != Vector2i.ZERO else 1
	var top: PackedVector2Array = PackedVector2Array()
	var bottom: PackedVector2Array = PackedVector2Array()
	for sample in range(steps + 1):
		var x: float = left + width * float(sample) / steps
		var y0: float = local_origin.y - TANGENT_OVERLAP
		var y1: float = local_origin.y + tile + TANGENT_OVERLAP
		if ends.x != 0:
			y0 = _horizontal_core_end(profile, contour, thickness, bias,
				local_origin.y, x + absolute_offset.x, true, ends.x)
		if ends.y != 0:
			y1 = _horizontal_core_end(profile, contour, thickness, bias,
				local_origin.y + tile, x + absolute_offset.x, false, ends.y)
		if y0 > y1:
			var midpoint: float = (y0 + y1) * 0.5
			y0 = midpoint - 0.001
			y1 = midpoint + 0.001
		top.append(Vector2(x, y0))
		bottom.append(Vector2(x, y1))
	bottom.reverse()
	top.append_array(bottom)
	_draw_wrapped_native(canvas, texture, top, native_scale,
		Vector2(left - region.position.x * native_scale, -absolute_offset.y - region.position.y * native_scale),
		1, -absolute_offset.y, region.size.y)


static func _vertical_core_end(profile: Dictionary, contour: Dictionary,
		thickness: float, bias: float, vertex: float, absolute_y: float,
		start: bool, kind: int) -> float:
	var native_scale: float = thickness / float(profile.leg_width)
	var far: bool = not start if kind > 0 else start
	var samples: Array = contour.leg_right if far else contour.leg_left
	var bound: float = _opaque_bound(samples, absolute_y / native_scale, far)
	var center: float = vertex + (bias if start else -bias) * kind
	return center + (bound - float(profile.leg_center)) * native_scale + (-CORE_INSET if far else CORE_INSET)


static func _horizontal_core_end(profile: Dictionary, contour: Dictionary,
		thickness: float, bias: float, vertex: float, absolute_x: float,
		start: bool, kind: int) -> float:
	var native_scale: float = thickness / float(profile.edge_height)
	var far: bool = not start if kind > 0 else start
	var samples: Array = contour.edge_bottom if far else contour.edge_top
	var bound: float = _opaque_bound(samples, absolute_x / native_scale, far)
	var center: float = vertex + (bias if start else -bias) * kind
	return center + (bound - float(profile.edge_center)) * native_scale + (-CORE_INSET if far else CORE_INSET)


static func _opaque_bound(samples: Array, phase: float, far: bool) -> float:
	var first: int = floori(fposmod(phase, samples.size()))
	var second: int = (first + 1) % samples.size()
	# Use the more interior of the two native samples so interpolation cannot
	# expose the adjoining strip's box edge through an alpha fringe.
	return minf(float(samples[first]), float(samples[second])) if far else maxf(float(samples[first]), float(samples[second]))


static func _draw_wrapped_native(canvas: CanvasItem, texture: Texture2D,
		polygon: PackedVector2Array, native_scale: float, texture_origin: Vector2,
		axis: int, wrap_origin: float, source_period: float) -> void:
	var lower: float = INF
	var upper: float = -INF
	for point in polygon:
		lower = minf(lower, point[axis])
		upper = maxf(upper, point[axis])
	var world_period: float = source_period * native_scale
	var first: int = floori((lower - wrap_origin) / world_period)
	var last: int = floori((upper - wrap_origin) / world_period)
	for repeat_index in range(first, last + 1):
		var start: float = wrap_origin + repeat_index * world_period
		var clipped: PackedVector2Array = _clip_axis(polygon, axis, start, true)
		clipped = _clip_axis(clipped, axis, start + world_period, false)
		clipped = _compact_polygon(clipped)
		if clipped.size() < 3 or absf(_polygon_area(clipped)) < 0.01: continue
		var uvs: PackedVector2Array = PackedVector2Array()
		for point in clipped:
			var source: Vector2 = (point - texture_origin) / native_scale
			source[axis] -= repeat_index * source_period
			uvs.append(source / texture.get_size())
		canvas.draw_polygon(clipped, PackedColorArray([Color.WHITE]), uvs, texture)


static func _clip_axis(polygon: PackedVector2Array, axis: int,
		boundary: float, keep_greater: bool) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	if polygon.is_empty(): return result
	var previous: Vector2 = polygon[polygon.size() - 1]
	var previous_inside: bool = previous[axis] >= boundary if keep_greater else previous[axis] <= boundary
	for point in polygon:
		var inside: bool = point[axis] >= boundary if keep_greater else point[axis] <= boundary
		if inside != previous_inside:
			var weight: float = (boundary - previous[axis]) / (point[axis] - previous[axis])
			result.append(previous.lerp(point, weight))
		if inside: result.append(point)
		previous = point
		previous_inside = inside
	return result


static func _compact_polygon(polygon: PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = PackedVector2Array()
	for point in polygon:
		if not result.is_empty() and result[result.size() - 1].distance_squared_to(point) < 0.000001: continue
		while result.size() >= 2:
			var a: Vector2 = result[result.size() - 2]
			var b: Vector2 = result[result.size() - 1]
			if absf((b - a).cross(point - b)) > 0.00001: break
			result.remove_at(result.size() - 1)
		result.append(point)
	if result.size() > 1 and result[0].distance_squared_to(result[result.size() - 1]) < 0.000001:
		result.remove_at(result.size() - 1)
	return result


static func _polygon_area(polygon: PackedVector2Array) -> float:
	var area: float = 0.0
	for index in polygon.size():
		area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	return area * 0.5


static func profile_report(tile: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in PROFILES.size():
		var profile: Dictionary = PROFILES[index]
		var thickness: float = tile * (1.5 if index == 5 else 0.75)
		result.append({
			"name": PROFILE_NAMES[index], "visible_thickness": thickness,
			"edge_scale": thickness / float(profile.edge_height),
			"leg_scale": thickness / float(profile.leg_width),
			"leg_region": str(profile.leg_region), "rotation": 0.0,
			"mirrored_x": false, "mirrored_y": false,
			"join": "adjoining native alpha >= 250 contour; no added fade",
		})
	return result
