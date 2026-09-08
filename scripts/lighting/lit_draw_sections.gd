extends Node2D
## Execute existing drawing functions in bounded CanvasItems, in their original order.
## The world retains all geometry/state ownership; this layer only narrows light culling.
var enabled: bool = true
var _pool: Array[DrawSection] = []
var _used: int = 0
var _world: Node2D

class DrawSection extends Node2D:
	var world: Node2D
	var paint: Callable

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
	show()

func add(paint: Callable) -> void:
	if _used == _pool.size():
		var created: DrawSection = DrawSection.new()
		created.use_parent_material = true
		_pool.append(created)
		add_child(created)
	var section: DrawSection = _pool[_used]
	section.world = _world
	section.paint = paint
	section.light_mask = _world.light_mask
	section.self_modulate = _world.self_modulate
	section.show()
	section.queue_redraw()
	_used += 1

func finish() -> void:
	for index in range(_used, _pool.size()): _pool[index].hide()
