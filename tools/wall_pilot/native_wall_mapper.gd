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
	{"edge_height": 66.0, "edge_center": 59.0, "leg_width": 113.0,
		"leg_center": 513.25, "leg_region": Rect2(429, 669, 169, 352)},
	{"edge_height": 100.0, "edge_center": 60.5, "leg_width": 115.0,
		"leg_center": 557.5, "leg_region": Rect2(486, 720, 148, 304)},
	{"edge_height": 57.0, "edge_center": 56.5, "leg_width": 117.5,
		"leg_center": 555.5, "leg_region": Rect2(475, 720, 154, 304)},
	{"edge_height": 55.0, "edge_center": 51.0, "leg_width": 93.0,
		"leg_center": 511.5, "leg_region": Rect2(449, 670, 142, 320)},
	{"edge_height": 104.0, "edge_center": 66.5, "leg_width": 298.0,
		"leg_center": 610.5, "leg_region": Rect2(420, 720, 377, 304)},
	{"edge_height": 205.0, "edge_center": 132.5, "leg_width": 243.0,
		"leg_center": 511.5, "leg_region": Rect2(362, 708, 291, 316)},
]
const CONTOUR_PATH: String = "res://tools/wall_pilot/native_wall_contours.json"
const TANGENT_OVERLAP: float = 0.25
const CORE_INSET: float = 0.75
const CONTOUR_STEP: float = 0.5
static var _contours: Array = []


static func _ensure_contours() -> void:
	if not _contours.is_empty(): return
	var measured: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CONTOUR_PATH))
	_contours = measured.profiles


static func _visible_thickness(tile: float, bedrock: bool) -> float:
	# The 55px bedrock median keeps both maximum opaque native face spans below
	# one 64px solid. It retains heavier native facets than the 48px mineable rim.
	return tile * (55.0 / 64.0 if bedrock else 0.75)


static func draw_cell(canvas: CanvasItem, strip: Texture2D, corner_texture: Texture2D,
		cell: Vector2i, absolute: Vector2i, open_sides: Array, terminal_kinds: Array,
		tile: float, profile_index: int, bedrock: bool = false,
		transition: Dictionary = {}) -> void:
	if strip == null or corner_texture == null:
		return
	_ensure_contours()
	var index: int = 5 if bedrock else posmod(profile_index, 5)
	var profile: Dictionary = PROFILES[index]
	var contour: Dictionary = _contours[index]
	var thickness: float = _visible_thickness(tile, bedrock)
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
				local_origin, absolute_offset, tile, center_x, ends, transition)


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
		Vector2(-absolute_offset.x, top), 0, -absolute_offset.x, texture.get_width(),
		float(profile.edge_height) > 128.0)


static func _draw_vertical(canvas: CanvasItem, texture: Texture2D,
		profile: Dictionary, contour: Dictionary, thickness: float, bias: float,
		local_origin: Vector2, absolute_offset: Vector2, tile: float,
		center_x: float, ends: Vector2i, transition: Dictionary) -> void:
	var native_scale: float = thickness / float(profile.leg_width)
	var region: Rect2 = Rect2(profile.leg_region)
	var left: float = center_x + (region.position.x - float(profile.leg_center)) * native_scale
	var width: float = region.size.x * native_scale
	var steps: int = ceili(width / CONTOUR_STEP) if ends != Vector2i.ZERO or not transition.is_empty() else 1
	var transition_samples: Array[float] = []
	if not transition.is_empty():
		transition_samples = _transition_samples(left, left + width, absolute_offset.x)
	if not transition_samples.is_empty(): steps = transition_samples.size() - 1
	var top: PackedVector2Array = PackedVector2Array()
	var bottom: PackedVector2Array = PackedVector2Array()
	for sample in range(steps + 1):
		var x: float = transition_samples[sample] if not transition_samples.is_empty() else left + width * float(sample) / steps
		var y0: float = local_origin.y - TANGENT_OVERLAP
		var y1: float = local_origin.y + tile + TANGENT_OVERLAP
		if ends.x != 0:
			y0 = _horizontal_core_end(profile, contour, thickness, bias,
				local_origin.y, x + absolute_offset.x, true, ends.x)
		if ends.y != 0:
			y1 = _horizontal_core_end(profile, contour, thickness, bias,
				local_origin.y + tile, x + absolute_offset.x, false, ends.y)
		if not transition.is_empty():
			var seam: float = _transition_y(float(transition.boundary_y),
				x + absolute_offset.x, int(transition.next_profile), tile)
			if bool(transition.at_start) and ends.x == 0:
				y0 = seam - TANGENT_OVERLAP
			elif not bool(transition.at_start) and ends.y == 0:
				y1 = seam + TANGENT_OVERLAP
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
		1, -absolute_offset.y, region.size.y, float(profile.edge_height) > 128.0)


# Both adjacent materials and the native wall mass use this same absolute
# contour. The canonical half-pixel X grid also makes their mesh boundaries
# match between samples; differing source widths cannot create mask cracks.
static func _transition_y(boundary_y: float, absolute_x: float,
		next_profile: int, tile: float) -> float:
	_ensure_contours()
	var profile: Dictionary = PROFILES[posmod(next_profile, 5)]
	var contour: Dictionary = _contours[posmod(next_profile, 5)]
	var native_scale: float = tile * 0.75 / float(profile.edge_height)
	var grid_x: float = floorf(absolute_x / CONTOUR_STEP) * CONTOUR_STEP
	var a: float = _opaque_bound(contour.edge_top, grid_x / native_scale, false)
	var b: float = _opaque_bound(contour.edge_top, (grid_x + CONTOUR_STEP) / native_scale, false)
	var native_y: float = lerpf(a, b, (absolute_x - grid_x) / CONTOUR_STEP)
	return boundary_y + (native_y - float(contour.edge_top_anchor)) * native_scale


static func _transition_samples(start: float, end: float,
		absolute_offset: float) -> Array[float]:
	var samples: Array[float] = [start]
	var first: int = ceili((start + absolute_offset) / CONTOUR_STEP)
	var last: int = floori((end + absolute_offset) / CONTOUR_STEP)
	for index in range(first, last + 1):
		var value: float = index * CONTOUR_STEP - absolute_offset
		if value > start + 0.0001 and value < end - 0.0001: samples.append(value)
	samples.append(end)
	return samples


static func draw_mass_transition(canvas: CanvasItem, texture: Texture2D,
		rect: Rect2, source: Rect2, upper_tint: Color, lower_tint: Color,
		boundary_y: float, absolute_x_offset: float, next_profile: int, tile: float) -> void:
	var samples: Array[float] = _transition_samples(rect.position.x, rect.end.x, absolute_x_offset)
	var contour: PackedVector2Array = PackedVector2Array()
	for x in samples:
		var point: Vector2 = Vector2(x, _transition_y(boundary_y, x + absolute_x_offset, next_profile, tile))
		if not contour.is_empty():
			var previous: Vector2 = contour[contour.size() - 1]
			var weights: Array[float] = []
			if not is_equal_approx(point.y, previous.y):
				for row_y in [rect.position.y, rect.end.y]:
					var weight: float = (row_y - previous.y) / (point.y - previous.y)
					if weight > 0.0 and weight < 1.0: weights.append(weight)
			weights.sort()
			for weight in weights: contour.append(previous.lerp(point, weight))
		contour.append(point)
	_draw_mass_region(canvas, texture, rect, source, contour, upper_tint, true)
	_draw_mass_region(canvas, texture, rect, source, contour, lower_tint, false)


static func _draw_mass_region(canvas: CanvasItem, texture: Texture2D,
		rect: Rect2, source: Rect2, contour: PackedVector2Array,
		tint: Color, upper: bool) -> void:
	var base_y: float = rect.position.y if upper else rect.end.y
	var run: PackedVector2Array = PackedVector2Array()
	for index in range(contour.size() - 1):
		var a: Vector2 = contour[index]
		var b: Vector2 = contour[index + 1]
		var visible_a: bool = a.y > base_y if upper else a.y < base_y
		var visible_b: bool = b.y > base_y if upper else b.y < base_y
		if visible_a and run.is_empty():
			run.append(Vector2(a.x, clampf(a.y, rect.position.y, rect.end.y)))
		if visible_a != visible_b:
			var crossing: Vector2 = a.lerp(b, (base_y - a.y) / (b.y - a.y))
			if visible_a:
				run.append(crossing)
				_paint_mass_run(canvas, texture, rect, source, run, base_y, tint)
				run.clear()
			else:
				run.append(crossing)
		if visible_b:
			run.append(Vector2(b.x, clampf(b.y, rect.position.y, rect.end.y)))
	if not run.is_empty(): _paint_mass_run(canvas, texture, rect, source, run, base_y, tint)


static func _paint_mass_run(canvas: CanvasItem, texture: Texture2D,
		rect: Rect2, source: Rect2, run: PackedVector2Array,
		base_y: float, tint: Color) -> void:
	if run.size() < 2: return
	# A native contour can touch the clipping row more than once. That creates
	# zero-width connections that Godot's polygon triangulator rejects. Explicit
	# monotone trapezoids preserve exactly the same contour and uniform UV map.
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	for index in range(run.size() - 1):
		var a: Vector2 = run[index]
		var b: Vector2 = run[index + 1]
		var points: PackedVector2Array = PackedVector2Array([
			Vector2(a.x, base_y), a, b, Vector2(b.x, base_y)])
		var first: int = vertices.size()
		for point in points:
			vertices.append(Vector3(point.x, point.y, 0.0))
			uvs.append((source.position + (point - rect.position) / rect.size * source.size) / texture.get_size())
		if absf((points[1] - points[0]).cross(points[2] - points[0])) > 0.000001:
			indices.append_array(PackedInt32Array([first, first + 1, first + 2]))
		if absf((points[2] - points[0]).cross(points[3] - points[0])) > 0.000001:
			indices.append_array(PackedInt32Array([first, first + 2, first + 3]))
	_submit_native_mesh(canvas, texture, vertices, uvs, indices, tint)


static func _submit_native_mesh(canvas: CanvasItem, texture: Texture2D,
		vertices: PackedVector3Array, uvs: PackedVector2Array,
		indices: PackedInt32Array, tint: Color) -> void:
	if indices.is_empty(): return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: ArrayMesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	# Retain resources for the lifetime of this cached CanvasItem's draw commands.
	# The owning Deep draw callback clears this bounded list on its next redraw.
	var retained: Array = canvas.get_meta("wall_study_native_meshes", [])
	retained.append(mesh)
	canvas.set_meta("wall_study_native_meshes", retained)
	canvas.draw_mesh(mesh, texture, Transform2D.IDENTITY, tint)


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
		axis: int, wrap_origin: float, source_period: float,
		explicit_strips: bool = false) -> void:
	if explicit_strips:
		_draw_wrapped_strips(canvas, texture, polygon, native_scale, texture_origin,
			axis, wrap_origin, source_period)
		return
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


static func _draw_wrapped_strips(canvas: CanvasItem, texture: Texture2D,
		polygon: PackedVector2Array, native_scale: float, texture_origin: Vector2,
		axis: int, wrap_origin: float, source_period: float) -> void:
	# Narrow bedrock cells can have multiple tiny pinches after native wrapping.
	# Each pair of matching contour samples defines a convex trapezoid; split
	# that trapezoid at UV wraps before making explicit triangles. No artwork,
	# silhouette samples, opacity, or UV scale is changed by this decomposition.
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var count: int = polygon.size()
	var world_period: float = source_period * native_scale
	for sample in range(count / 2 - 1):
		var quad: PackedVector2Array = PackedVector2Array([
			polygon[sample], polygon[sample + 1],
			polygon[count - 2 - sample], polygon[count - 1 - sample]])
		var lower: float = INF
		var upper: float = -INF
		for point in quad:
			lower = minf(lower, point[axis])
			upper = maxf(upper, point[axis])
		var first_repeat: int = floori((lower - wrap_origin) / world_period)
		var last_repeat: int = floori((upper - wrap_origin) / world_period)
		for repeat_index in range(first_repeat, last_repeat + 1):
			var start: float = wrap_origin + repeat_index * world_period
			var clipped: PackedVector2Array = _clip_axis(quad, axis, start, true)
			clipped = _compact_polygon(_clip_axis(clipped, axis, start + world_period, false))
			if clipped.size() < 3: continue
			var first_vertex: int = vertices.size()
			for point in clipped:
				vertices.append(Vector3(point.x, point.y, 0.0))
				var source: Vector2 = (point - texture_origin) / native_scale
				source[axis] -= repeat_index * source_period
				uvs.append(source / texture.get_size())
			for corner_index in range(1, clipped.size() - 1):
				if absf((clipped[corner_index] - clipped[0]).cross(clipped[corner_index + 1] - clipped[0])) < 0.000001: continue
				indices.append_array(PackedInt32Array([
					first_vertex, first_vertex + corner_index, first_vertex + corner_index + 1]))
	_submit_native_mesh(canvas, texture, vertices, uvs, indices, Color.WHITE)


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
		var thickness: float = _visible_thickness(tile, index == 5)
		result.append({
			"name": PROFILE_NAMES[index], "visible_thickness": thickness,
			"edge_scale": thickness / float(profile.edge_height),
			"leg_scale": thickness / float(profile.leg_width),
			"leg_region": str(profile.leg_region), "rotation": 0.0,
			"mirrored_x": false, "mirrored_y": false,
			"join": "adjoining native alpha >= 250 contour; no added fade",
		})
	return result
