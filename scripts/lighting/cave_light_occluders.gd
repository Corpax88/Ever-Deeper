extends Node2D

# Shadow coverage follows actual light footprints, including upgraded lamps.
# Geometry is reused until coverage, an emitter cell or terrain changes.
var _signature: int = 0
var _input_signature: int = 0
var _input_valid: bool = false
var _lamps: Array[PointLight2D] = []
var _hero_lamp: Node2D
var _companion_lamp: Node2D
var _pool: Array[LightOccluder2D] = []
var active_count: int = 0
var row_span_count: int = 0
var scanned_cells: int = 0
var rebuild_count: int = 0

func _ready() -> void:
	# Run after world/camera/companion motion, before this frame is rendered.
	process_priority = 100

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	var world: Node2D = get_parent()
	var player: Node2D = world.get("player")
	if not is_instance_valid(player) or not world.is_visible_in_tree():
		return
	var tile: float = 64.0 if world.has_method("_is_floor") else 48.0
	var lamp: Node2D = player.get_node_or_null("PremiumHeadlamp")
	var companion: Node2D = world.get_node_or_null("MoleCompanion/PremiumHeadlamp")
	if lamp != _hero_lamp or companion != _companion_lamp:
		_hero_lamp = lamp
		_companion_lamp = companion
		_lamps.clear()
		for source in [lamp, companion]:
			if source == null: continue
			for child in source.get_children():
				if child is PointLight2D: _lamps.append(child)
	var coverage: Array[Rect2i] = []
	var emitters: Array[Vector2i] = []
	for light in _lamps:
		if not is_instance_valid(light) or not light.enabled or not light.shadow_enabled or not light.is_visible_in_tree(): continue
		coverage.append(_source_cell_bounds(world, light, tile))
		var origin: Vector2i = Vector2i((world.to_local(light.global_position) / tile).floor())
		if not emitters.has(origin): emitters.append(origin)
	var terrain: int
	if world.has_method("_is_floor"):
		terrain = hash(world.floor_cells)
	elif world.has_method("_terrain_draw_fingerprint"):
		terrain = world._terrain_draw_fingerprint()
	elif not world.has_method("_terrain_is_solid") and world.has_method("_terrain_occupancy_revision"):
		# This matches _solid(): only block occupancy affects these shadows.
		terrain = world._terrain_occupancy_revision()
	else:
		terrain = hash(world.blocks)
	var input_signature: int = hash(coverage) ^ hash(emitters) ^ terrain
	if _input_valid and input_signature == _input_signature: return
	_input_valid = true
	_input_signature = input_signature
	rebuild_count += 1
	# Union only the covered row intervals. A distant companion never creates
	# a huge scan across the empty space between the two light sources.
	var row_intervals: Dictionary = {}
	for area in coverage:
		for y in range(area.position.y, area.end.y):
			if not row_intervals.has(y): row_intervals[y] = []
			row_intervals[y].append(Vector2i(area.position.x, area.end.x))
	var ys: Array = row_intervals.keys()
	ys.sort()
	var spans: Array[Rect2] = []
	scanned_cells = 0
	for y in ys:
		var intervals: Array = row_intervals[y]
		intervals.sort_custom(func(a: Vector2i, b: Vector2i): return a.x < b.x)
		var merged: Array[Vector2i] = []
		for interval in intervals:
			if not merged.is_empty() and interval.x <= merged[-1].y:
				merged[-1].y = maxi(merged[-1].y, interval.y)
			else: merged.append(interval)
		for interval in merged:
			var start: int = -100000
			for x in range(interval.x, interval.y + 1):
				var cell: Vector2i = Vector2i(x, y)
				var filled: bool = x < interval.y and not emitters.has(cell) and _solid(world, cell)
				if x < interval.y: scanned_cells += 1
				if filled and start == -100000: start = x
				if not filled and start != -100000:
					spans.append(Rect2(float(start) * tile, float(y) * tile, float(x - start) * tile, tile))
					start = -100000
	row_span_count = spans.size()
	spans = _merge_vertical_spans(spans)
	var signature: int = hash(spans)
	if signature == _signature:
		return
	_signature = signature
	while _pool.size() < spans.size():
		var occluder: LightOccluder2D = LightOccluder2D.new()
		occluder.occluder = OccluderPolygon2D.new()
		_pool.append(occluder)
		add_child(occluder)
	active_count = spans.size()
	for i in _pool.size():
		_pool[i].visible = i < spans.size()
		if i >= spans.size():
			continue
		var r: Rect2 = spans[i]
		_pool[i].occluder.polygon = PackedVector2Array([r.position, Vector2(r.end.x,r.position.y),r.end,Vector2(r.position.x,r.end.y)])


func _source_cell_bounds(world: Node2D, light: PointLight2D, tile: float) -> Rect2i:
	var size: Vector2 = light.texture.get_size() * light.texture_scale
	var transform: Transform2D = world.global_transform.affine_inverse() * light.global_transform
	var bounds: Rect2 = transform * Rect2(light.offset - size * 0.5, size)
	# Include the emitter-to-receiver segment and a full tile for PCF filtering.
	bounds = bounds.expand(transform.origin).grow(tile)
	var first: Vector2i = Vector2i((bounds.position / tile).floor())
	var last: Vector2i = Vector2i((bounds.end / tile).ceil())
	return Rect2i(first, last - first)


func _merge_vertical_spans(rows: Array[Rect2]) -> Array[Rect2]:
	# Adjacent rectangles with the same horizontal interval describe the same
	# solid silhouette. Remove their internal edges from every shadow pass.
	var merged: Array[Rect2] = []
	var tails: Dictionary = {}
	for rect in rows:
		var key: Vector2 = Vector2(rect.position.x, rect.size.x)
		var index: int = int(tails.get(key, -1))
		if index >= 0 and is_equal_approx(merged[index].end.y, rect.position.y):
			merged[index].size.y += rect.size.y
		else:
			tails[key] = merged.size()
			merged.append(rect)
	return merged

func _solid(world: Node, cell: Vector2i) -> bool:
	if world.has_method("_terrain_is_solid"):
		for index in Array(world.get("rocks_by_cell").get(cell,[])):
			var rock: Dictionary=world.get("rocks")[int(index)]
			if bool(rock.drill_gated) and not bool(rock.broken): return true
		return bool(world.call("_terrain_is_solid",cell))
	if world.has_method("_is_floor"):
		return not bool(world.call("_is_floor",cell))
	var blocks: Dictionary = world.get("blocks")
	return blocks.has(cell)

