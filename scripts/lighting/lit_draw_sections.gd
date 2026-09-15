extends Node2D
## Execute existing drawing functions in bounded CanvasItems, in their original order.
## The world retains all geometry/state ownership; this layer only narrows light culling.
var enabled: bool = true
var _pool: Array[DrawSection] = []
var _used: int = 0
var _world: Node2D
var _cached: Dictionary = {}
var _recycled: Array[DrawSection] = []
var _epoch: int = 0
var _order: int = 0
var cached_redraws: int = 0
var cached_reuses: int = 0

class DrawSection extends Node2D:
	var world: Node2D
	var paint: Callable
	var revision: int = -1
	var seen: int = -1

	func _draw() -> void:
		var previous: CanvasItem = world._draw_canvas
		world._draw_canvas = self
		paint.call()
		world._draw_canvas = previous

func _init() -> void:
	name = "LitDrawSections"
	show_behind_parent = true
	use_parent_material = true

func begin(world: Node2D) -> void:
	_world = world
	_used = 0
	_order = 0
	_epoch += 1
	show()

func add(paint: Callable, draw_material: Material = null, draw_depth: int = 0) -> void:
	if _used == _pool.size():
		var created: DrawSection = DrawSection.new()
		created.use_parent_material = true
		_pool.append(created)
		add_child(created)
	var section: DrawSection = _pool[_used]
	_configure(section, paint, draw_material, draw_depth)
	section.queue_redraw()
	_used += 1


func add_cached(key: Vector3i, revision: int, paint: Callable, draw_material: Material = null) -> void:
	var section: DrawSection = _cached.get(key)
	if section == null:
		section = _recycled.pop_back() if not _recycled.is_empty() else DrawSection.new()
		if section.get_parent() == null: add_child(section)
		section.revision = -1
		_cached[key] = section
	_configure(section, paint, draw_material, 0)
	section.seen = _epoch
	if section.revision != revision:
		section.revision = revision
		section.queue_redraw()
		cached_redraws += 1
	else:
		cached_reuses += 1


func _configure(section: DrawSection, paint: Callable, draw_material: Material, draw_depth: int) -> void:
	section.world = _world
	section.z_index = draw_depth
	section.paint = paint
	section.use_parent_material = draw_material == null
	section.material = draw_material
	section.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if draw_material != null else CanvasItem.TEXTURE_REPEAT_PARENT_NODE
	section.light_mask = _world.light_mask
	section.self_modulate = _world.self_modulate
	section.show()
	# Keep authored overlap order when the camera brings a cached strip back.
	if section.get_index() != _order: move_child(section, _order)
	_order += 1

func finish() -> void:
	for index in range(_used, _pool.size()): _pool[index].hide()
	# Recycle sections outside the visible margin. Long excavation never grows
	# a map-sized cache, and returning strips reuse nodes without allocations.
	for key in _cached.keys():
		var section: DrawSection = _cached[key]
		if section.seen == _epoch: continue
		section.hide()
		_cached.erase(key)
		_recycled.append(section)


func debug_snapshot() -> Dictionary:
	return {"cached": _cached.size(), "recycled": _recycled.size(), "dynamic": _pool.size(), "redraws": cached_redraws, "reuses": cached_reuses}
