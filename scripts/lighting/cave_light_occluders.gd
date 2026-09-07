extends Node2D

# Nearby solid rows become real light occluders. Inactive worlds inherit the
# world's disabled processing; unchanged geometry is reused after mining/motion.
var _clock: float = 0.0
var _signature: int = 0
var _pool: Array[LightOccluder2D] = []
var active_count: int = 0

func _process(delta: float) -> void:
	_clock += delta
	if _clock < 0.16:
		return
	_clock = 0.0
	refresh()

func refresh() -> void:
	var world: Node2D = get_parent()
	var player: Node2D = world.get("player")
	if not is_instance_valid(player) or not world.is_visible_in_tree():
		return
	var tile: float = 64.0 if world.has_method("_is_floor") else 48.0
	var center: Vector2i = Vector2i((player.position / tile).floor())
	var lamp: Node2D = player.get_node_or_null("PremiumHeadlamp")
	var emitter: Vector2i = center
	if lamp != null:
		emitter = Vector2i((world.to_local(lamp.global_position) / tile).floor())
	var companion: Node2D = world.get_node_or_null("MoleCompanion/PremiumHeadlamp")
	var companion_cell: Vector2i = Vector2i(-99999,-99999)
	if companion != null: companion_cell = Vector2i((world.to_local(companion.global_position)/tile).floor())
	var spans: Array[Rect2] = []
	var first: Vector2i = center-Vector2i(13,13)
	var last: Vector2i = center+Vector2i(13,13)
	if companion != null:
		first=first.min(companion_cell-Vector2i(7,7))
		last=last.max(companion_cell+Vector2i(7,7))
	for y in range(first.y,last.y+1):
		var start: int = -100000
		for x in range(first.x,last.x+2):
			var cell: Vector2i = Vector2i(x,y)
			var filled: bool = x <= last.x and cell != emitter and cell != companion_cell and _solid(world,cell)
			if filled and start == -100000:
				start = x
			if not filled and start != -100000:
				spans.append(Rect2(float(start) * tile, float(y) * tile, float(x - start) * tile, tile))
				start = -100000
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
