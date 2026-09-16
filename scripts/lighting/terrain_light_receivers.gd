extends Node
## Narrow native light assignment only where an entire terrain receiver is
## outside the light's nonzero texture support. Art, shadows and shaders stay native.
## Bit 1 remains the nonterrain contract; bit 20 belongs to fixed floor fields.
const RESERVED_MASK: int = 1 | (1 << 19)
var enabled: bool = false
var _world: Node2D
var _sections: Node
var _lights: Array[Dictionary] = []
var _foreign: Array[Light2D] = []
var _textures: Dictionary = {}
var _collect_pending: bool = true
var _applied: bool = false
var _last_signature: int = 0
var updates: int = 0
var mask_writes: int = 0
var update_usec: int = 0
var last_receivers: int = 0
var last_light_assignments: int = 0
var fallback_reason: String = ""

func configure(world: Node2D, sections: Node) -> void:
	_world = world
	_sections = sections
	RenderingServer.frame_pre_draw.connect(_before_draw)
	get_tree().node_added.connect(_node_added)
	get_tree().node_removed.connect(_node_removed)

func _exit_tree() -> void:
	_restore()

func _node_added(node: Node) -> void:
	if node is Light2D: _collect_pending = true

func _node_removed(node: Node) -> void:
	if node is Light2D: _collect_pending = true

func _restore() -> void:
	for entry in _lights:
		if not is_instance_valid(entry.node): continue
		var light: Light2D = entry.node
		light.range_item_cull_mask &= ~int(entry.bit)
		light.shadow_item_cull_mask &= ~int(entry.bit)
	if is_instance_valid(_sections) and is_instance_valid(_world):
		for section in _sections._cached.values():
			if not is_instance_valid(section): continue
			if section.light_mask != _world.light_mask: section.light_mask = _world.light_mask
	_applied = false
	_last_signature = 0

func _collect() -> void:
	_restore()
	_lights.clear()
	_foreign.clear()
	for id in _textures.keys():
		if _textures[id].texture.get_ref() == null: _textures.erase(id)
	_collect_pending = false
	var used_mask: int = RESERVED_MASK
	# Existing authored masks always win. Never allocate a bit already in use.
	for item in _world.find_children("*", "CanvasItem", true, false):
		used_mask |= item.light_mask
	var candidates: Array[Light2D] = []
	for light in get_tree().root.find_children("*", "Light2D", true, false):
		used_mask |= light.range_item_cull_mask | light.shadow_item_cull_mask
		if _world.is_ancestor_of(light): candidates.append(light)
		else: _foreign.append(light)
	for light in candidates:
		var bit: int = 0
		for index in range(1, 19):
			if not bool(used_mask & (1 << index)):
				bit = 1 << index
				used_mask |= bit
				break
		if bit == 0:
			fallback_reason = "No unused light mask bit."
			_lights.clear()
			return
		_lights.append({"node": light, "bit": bit, "support_key": 0,
			"bounds": Rect2(), "axes": PackedVector2Array(), "limits": PackedFloat64Array()})
	fallback_reason = ""

func _before_draw() -> void:
	if not is_instance_valid(_world) or not is_instance_valid(_sections): return
	if not enabled or _world.light_mask != 1:
		if _applied: _restore()
		return
	if not _world.is_visible_in_tree(): return
	var started: int = Time.get_ticks_usec()
	if _collect_pending: _collect()
	if not fallback_reason.is_empty() and _lights.is_empty(): return
	# A foreign light can affect this canvas too. Preserve the original path
	# instead of silently dropping a light that this owner does not control.
	for light in _foreign:
		if is_instance_valid(light) and light.enabled and light.is_visible_in_tree() and bool(light.range_item_cull_mask & _world.light_mask):
			fallback_reason = "Active foreign light: " + str(light.get_path())
			if _applied: _restore()
			return
	fallback_reason = ""
	var signature: Array = [_sections._epoch, _world.global_transform, _world.material, _world.use_parent_material]
	var active: Array[Dictionary] = []
	for entry in _lights:
		if not is_instance_valid(entry.node): _collect_pending = true; continue
		var light: Light2D = entry.node
		var source_mask: int = light.range_item_cull_mask & ~int(entry.bit)
		var source_shadow_mask: int = light.shadow_item_cull_mask & ~int(entry.bit)
		var target_mask: int = source_mask | int(entry.bit) if bool(source_mask & 1) else source_mask
		var target_shadow: int = source_shadow_mask | int(entry.bit) if bool(source_shadow_mask & 1) else source_shadow_mask
		if light.range_item_cull_mask != target_mask: light.range_item_cull_mask = target_mask
		if light.shadow_item_cull_mask != target_shadow: light.shadow_item_cull_mask = target_shadow
		var visible_now: bool = light.enabled and light.is_visible_in_tree() and bool(source_mask & 1)
		signature.append([light.get_instance_id(), visible_now, target_mask, target_shadow])
		if not visible_now: continue
		if light is PointLight2D:
			if light.texture == null: continue
			var texture_id: int = light.texture.get_instance_id()
			var hull: PackedVector2Array = _texture_hull(light)
			var transform: Transform2D = _world.global_transform.affine_inverse() * light.global_transform
			var key: int = hash([transform, light.offset, light.texture_scale, texture_id, hull])
			signature.append(key)
			if int(entry.support_key) != key:
				entry.support_key = key
				var polygon: PackedVector2Array = []
				for point in hull:
					polygon.append(transform * ((point - light.texture.get_size() * 0.5) * light.texture_scale + light.offset))
				_prepare_support(entry, polygon)
		active.append(entry)
	_applied = true
	var fingerprint: int = hash(signature)
	if fingerprint == _last_signature:
		update_usec += Time.get_ticks_usec() - started
		return
	_last_signature = fingerprint
	last_receivers = 0
	last_light_assignments = 0
	var bounds_masks: Dictionary = {}
	for section in _sections._cached.values():
		if not section.visible: continue
		if not section.receiver_bounds.has_area() or not _supported_material(section):
			if section.light_mask != _world.light_mask: section.light_mask = _world.light_mask
			continue
		last_receivers += 1
		var mask: int = 0
		var assignments: int = 0
		# Floor and mass/detail use the same conservative cell-strip rectangle.
		# Reuse its exact result; projecting rims keep their own larger bounds.
		if bounds_masks.has(section.receiver_bounds):
			var cached: Vector2i = bounds_masks[section.receiver_bounds]
			mask = cached.x
			assignments = cached.y
		else:
			for entry in active:
				if not entry.node is PointLight2D or _intersects(section.receiver_bounds, entry):
					mask |= int(entry.bit)
					assignments += 1
			bounds_masks[section.receiver_bounds] = Vector2i(mask, assignments)
		last_light_assignments += assignments
		if section.light_mask != mask:
			section.light_mask = mask
			mask_writes += 1
	updates += 1
	update_usec += Time.get_ticks_usec() - started

func _supported_material(section: CanvasItem) -> bool:
	if _world.material != null or _world.use_parent_material: return false
	if section.use_parent_material: return false
	if not section.material is ShaderMaterial: return false
	var shader: Shader = section.material.shader
	return shader != null and shader.resource_path in [
		"res://shaders/lit_visible_pixels.gdshader", "res://shaders/lit_floor_composite.gdshader",
		"res://shaders/lit_biome_floor.gdshader"]

func _texture_hull(light: PointLight2D) -> PackedVector2Array:
	var texture: Texture2D = light.texture
	var id: int = texture.get_instance_id()
	if _textures.has(id): return _textures[id].hull
	var size: Vector2 = texture.get_size()
	var hull: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	# Restrict alpha-based culling to the known native helmet textures. Unknown
	# lights keep their full original texture footprint and native shadow behavior.
	var lamp_script: Script = light.get_parent().get_script()
	if lamp_script != null and lamp_script.resource_path == "res://scripts/lighting/headlamp_beam.gd":
		var image: Image = texture.get_image()
		if image != null and not image.is_empty() and not image.has_mipmaps():
			var points: PackedVector2Array = []
			for y in image.get_height():
				var first: int = image.get_width()
				var last: int = -1
				for x in image.get_width():
					if image.get_pixel(x, y).a != 0.0:
						first = mini(first, x)
						last = maxi(last, x)
				if last >= 0:
					# Enclose every nonzero texel plus more than one full source
					# texel of bilinear support. No intensity cutoff or downsampling.
					points.append(Vector2(first - 1, y - 1))
					points.append(Vector2(last + 2, y - 1))
					points.append(Vector2(first - 1, y + 2))
					points.append(Vector2(last + 2, y + 2))
			if not points.is_empty(): hull = Geometry2D.convex_hull(points)
	_textures[id] = {"texture": weakref(texture), "hull": hull}
	texture.changed.connect(_texture_changed.bind(id))
	return hull

func _texture_changed(id: int) -> void:
	if _textures.has(id):
		var texture: Texture2D = _textures[id].texture.get_ref()
		if texture != null and texture.changed.is_connected(_texture_changed.bind(id)):
			texture.changed.disconnect(_texture_changed.bind(id))
		_textures.erase(id)
	_last_signature = 0

func _prepare_support(entry: Dictionary, polygon: PackedVector2Array) -> void:
	var bounds: Rect2 = Rect2(polygon[0], Vector2.ZERO)
	var signed_area: float = 0.0
	for index in polygon.size():
		bounds = bounds.expand(polygon[index])
		signed_area += polygon[index].cross(polygon[(index + 1) % polygon.size()])
	var axes: PackedVector2Array = []
	var limits: PackedFloat64Array = []
	for index in polygon.size():
		var edge: Vector2 = polygon[(index + 1) % polygon.size()] - polygon[index]
		if edge.length_squared() < 0.000001: continue
		var axis: Vector2 = Vector2(edge.y, -edge.x) * (1.0 if signed_area >= 0.0 else -1.0)
		axes.append(axis)
		limits.append(axis.dot(polygon[index]))
	entry.bounds = bounds
	entry.axes = axes
	entry.limits = limits

func _intersects(rect: Rect2, entry: Dictionary) -> bool:
	if not rect.intersects(entry.bounds, true): return false
	var axes: PackedVector2Array = entry.axes
	var limits: PackedFloat64Array = entry.limits
	for index in axes.size():
		var axis: Vector2 = axes[index]
		var minimum: float = axis.dot(rect.position) + minf(0.0, axis.x * rect.size.x) + minf(0.0, axis.y * rect.size.y)
		if minimum > limits[index]: return false
	return true

func debug_snapshot() -> Dictionary:
	return {"enabled": enabled, "applied": _applied, "lights": _lights.size(),
		"receivers": last_receivers, "light_assignments": last_light_assignments,
		"updates": updates, "mask_writes": mask_writes, "update_usec": update_usec,
		"texture_hulls": _textures.size(), "fallback": fallback_reason}

static func deep_bounds(world: Node2D, row: int, first_col: int, last_col: int, pass_index: int) -> Rect2:
	var tile: float = world.TILE_SIZE
	var bounds: Rect2 = Rect2(Vector2(first_col, row) * tile, Vector2(last_col - first_col + 1, 1) * tile)
	# Mass, mineral hints, cracks and floor detail all fit inside their cells.
	if pass_index != 2: return bounds.grow(1.5)
	var result: Rect2 = Rect2()
	for col in range(first_col, last_col + 1):
		var cell: Vector2i = Vector2i(col, row)
		if world._is_floor(cell): continue
		var origin: Vector2 = Vector2(cell) * tile
		var mineable: bool = world._cell_diggable(cell)
		var depth: float = tile if mineable else tile * 2.0
		var inset: float = tile * (10.0 / 48.0 if mineable else 18.0 / 48.0)
		var sides: Array[bool] = []
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]: sides.append(world._is_floor(cell + direction))
		for side in 4:
			if not sides[side]: continue
			var center: Vector2 = origin + [Vector2(tile * 0.5, 0), Vector2(tile, tile * 0.5), Vector2(tile * 0.5, tile), Vector2(0, tile * 0.5)][side]
			var transform: Transform2D = Transform2D([PI, -PI * 0.5, 0.0, PI * 0.5][side], center)
			var rect: Rect2 = transform * Rect2(Vector2(-tile * 0.5, -depth + inset), Vector2(tile, depth))
			result = result.merge(rect) if result.has_area() else rect
		for corner in 4:
			if not sides[corner] or not sides[(corner + 1) % 4]: continue
			var anchor: Vector2 = origin + [Vector2(tile, 0), Vector2(tile, tile), Vector2(0, tile), Vector2.ZERO][corner]
			var bias: float = depth * 0.5 - inset
			var transform: Transform2D = Transform2D([0.0, PI * 0.5, PI, -PI * 0.5][corner], anchor)
			var rect: Rect2 = transform * Rect2(Vector2(-bias, bias) - Vector2.ONE * depth * 1.5, Vector2.ONE * depth * 3.0)
			result = result.merge(rect) if result.has_area() else rect
	return result.grow(1.5) if result.has_area() else result
