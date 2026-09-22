extends Node
## Ordinary DEV presentation. No world reset, input interception or save changes.
const Rig = preload("res://scripts/player/native_worn/native_rig.gd")
const Motion = preload("res://scripts/player/native_worn/runtime_motion.gd")
const Equipment = preload("res://scripts/player/native_worn/pickaxe_equipment.gd")
const Surface = preload("res://scripts/player/native_worn/contact_surface.gd")
const ASSETS = "res://assets/native-worn"
var visual: Node2D
var player: Node2D
var rig: Node2D
var motion: RefCounted
var equipment: RefCounted
var reference_cap: Vector3
var failed: bool = false
var failure: String = ""
var updates: int = 0
var generations: int = 0
var surface_cache: Dictionary = {}
var last_surfaces: Array = []
var last_target: Vector2 = Vector2.ZERO
var last_surface_origin: Vector2 = Vector2.ZERO
var cached_surface_key: String = ""
var cached_surfaces: Array = []

func setup(owner_visual: Node2D) -> void:
	visual = owner_visual
	player = visual.get_parent()
	visual.visibility_changed.connect(_visibility_changed)

func _visibility_changed() -> void:
	if not visual.is_visible_in_tree(): suspend()

func suspend() -> void:
	if is_instance_valid(rig):
		rig.hide()
		if is_instance_valid(rig.viewport): rig.viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		rig.queue_free()
	rig = null
	motion = null
	equipment = null
	surface_cache.clear()
	last_surfaces.clear()
	cached_surface_key = ""
	cached_surfaces.clear()

func _start() -> bool:
	rig = Rig.new()
	rig.material_view = "baked_response"
	rig.lighting_profile = "native_key_shadow"
	rig.raster_size = 400
	visual.add_child(rig)
	if not rig.configure(ASSETS): return _fail("Native Worn assets could not be loaded")
	motion = Motion.new()
	if not motion.configure(rig, ASSETS.path_join("tasks.json"), ASSETS.path_join("motion.json")):
		return _fail("Native Worn motion identity mismatch")
	reference_cap = motion.cap_local
	equipment = Equipment.new()
	equipment.setup(rig)
	generations += 1
	return true

func _fail(message: String) -> bool:
	failed = true
	failure = message
	push_error(message)
	suspend()
	return false

func _surfaces(target: Vector2, target_id: String) -> Array:
	var query_key: String = target_id + str(target) + str(player.global_position)
	if query_key == cached_surface_key: return cached_surfaces
	var world: Node = player.get_parent()
	var visuals: Variant = world.get("resource_visuals")
	if not visuals is Dictionary: return []
	var root_node: Node2D = visuals.get(target_id) as Node2D
	if not is_instance_valid(root_node): return []
	var sprite: Sprite2D = root_node.get_node_or_null("PremiumNode") as Sprite2D
	if sprite == null or sprite.texture == null: return []
	var key: String = str(sprite.texture.get_rid()) + str(sprite.scale) + str(sprite.position)
	if not surface_cache.has(key):
		if surface_cache.size() >= 32: surface_cache.clear()
		surface_cache[key] = Surface.points(sprite)
	var result: Array = []
	for point in surface_cache[key]: result.append(target - player.global_position + Vector2(point))
	cached_surface_key = query_key
	cached_surfaces = result
	return result

func advance(delta: float) -> bool:
	if failed or visual.active_gear not in Equipment.GEARS or not visual.is_visible_in_tree():
		if is_instance_valid(rig): suspend()
		return false
	if not is_instance_valid(rig) and not _start(): return false
	if equipment.current != visual.active_gear:
		if not equipment.equip(visual.active_gear): return _fail("Native pickaxe identity mismatch: " + visual.active_gear)
		motion.cap_local = equipment.contact_cap(reference_cap)
		motion.reference_cap = motion.bank.mine[21].bones.tool * motion.cap_local
		motion.contact_cache.clear()
		motion.serial = -1
	var packet: Dictionary = player.animation_packet()
	packet.contact_surfaces = _surfaces(packet.target_position, String(packet.target_id)) if bool(packet.target_valid) else []
	if not packet.contact_surfaces.is_empty():
		last_target = packet.target_position
		last_surfaces = packet.contact_surfaces.duplicate()
		last_surface_origin = player.global_position
	packet.impact_surfaces = []
	if Vector2(packet.impact_target_position).is_equal_approx(last_target):
		for point in last_surfaces: packet.impact_surfaces.append(Vector2(point) + last_surface_origin - player.global_position)
	if not motion.advance(delta, packet): return _fail("Native Worn pose rejected: " + str(motion.errors))
	equipment.apply_pose()
	rig.set_outfit(visual.OUTFIT_COLORS.get(visual.active_endless_outfit_style, visual.OUTFIT_COLORS.miner), visual.active_endless_outfit_style != "miner")
	updates += 1
	return true

func snapshot() -> Dictionary:
	return {"active":is_instance_valid(rig), "failed":failed, "failure":failure,
		"gear":equipment.current if equipment != null else "", "updates":updates, "generations":generations, "surface_cache":surface_cache.size(),
		"motion":motion.snapshot() if motion != null else {},
		"unreachable_contacts":motion.unreachable_contacts if motion != null else 0}
