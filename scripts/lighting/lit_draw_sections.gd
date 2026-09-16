extends Node2D
## Execute existing drawing functions in bounded CanvasItems, in their original order.
## The world retains all geometry/state ownership; this layer only narrows light culling.
var enabled: bool = true
const VISIBLE_PIXELS_MATERIAL := preload("res://shaders/lit_visible_pixels.tres")
const TERRAIN_RECEIVERS := preload("res://scripts/lighting/terrain_light_receivers.gd")
var receiver_masks_enabled: bool = false
var receiver_masks: Node
var _pool: Array[DrawSection] = []
var _used: int = 0
var _world: Node2D
var _cached: Dictionary = {}
var _recycled: Array[DrawSection] = []
var _epoch: int = 0
var _order: int = 0
var cached_redraws: int = 0
var cached_reuses: int = 0
var profile_draws: bool = false
var draw_callbacks: int = 0
var draw_callback_usec: int = 0
var setup_usec: int = 0
var _setup_started: int = 0

class DrawSection extends Node2D:
	var world: Node2D
	var paint: Callable
	var revision: int = -1
	var seen: int = -1
	var receiver_bounds: Rect2
	var receiver_revision: int = -1

	func _draw() -> void:
		var owner_sections: Node = get_parent()
		var started: int = Time.get_ticks_usec() if owner_sections.profile_draws else 0
		var previous: CanvasItem = world._draw_canvas
		world._draw_canvas = self
		paint.call()
		world._draw_canvas = previous
		if owner_sections.profile_draws:
			owner_sections.draw_callbacks += 1
			owner_sections.draw_callback_usec += Time.get_ticks_usec() - started

func _init() -> void:
	name = "LitDrawSections"
	show_behind_parent = true
	use_parent_material = true

func begin(world: Node2D, deep_receiver_bounds: bool = false) -> void:
	_setup_started = Time.get_ticks_usec() if profile_draws else 0
	_world = world
	if deep_receiver_bounds and receiver_masks == null:
		receiver_masks = TERRAIN_RECEIVERS.new()
		add_child(receiver_masks)
		receiver_masks.configure(world, self)
	if receiver_masks != null: receiver_masks.enabled = receiver_masks_enabled
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
		section.receiver_revision = -1
		_cached[key] = section
	_configure(section, paint, draw_material, 0)
	section.seen = _epoch
	if receiver_masks != null and receiver_masks.enabled and section.receiver_revision != revision:
		section.receiver_bounds = TERRAIN_RECEIVERS.deep_bounds(_world, key.x, key.y, mini(key.y + 3, _world.GRID_SIZE.x - 1), key.z)
		section.receiver_revision = revision
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
	# Keep explicit/inherited world materials intact. Standard lit artwork can
	# reject exact-zero alpha before the renderer evaluates lights and shadows.
	var standard_lighting: bool = draw_material == null and _world.material == null and not _world.use_parent_material
	section.use_parent_material = draw_material == null and not standard_lighting
	section.material = VISIBLE_PIXELS_MATERIAL if standard_lighting else draw_material
	section.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED if draw_material != null else CanvasItem.TEXTURE_REPEAT_PARENT_NODE
	# Cached terrain masks belong to the pre-draw controller while enabled.
	# Reassigning the world mask here would undo every unchanged native mask.
	if receiver_masks == null or not receiver_masks.enabled or section.receiver_revision < 0:
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
	if profile_draws: setup_usec += Time.get_ticks_usec() - _setup_started


func debug_snapshot() -> Dictionary:
	return {"cached": _cached.size(), "recycled": _recycled.size(), "dynamic": _pool.size(), "redraws": cached_redraws, "reuses": cached_reuses, "draw_callbacks": draw_callbacks, "draw_callback_usec": draw_callback_usec, "setup_usec": setup_usec}
