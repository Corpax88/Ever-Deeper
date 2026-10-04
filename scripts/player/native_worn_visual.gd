extends Node
## Ordinary DEV presentation. No world reset, input interception or save changes.
const Rig = preload("res://scripts/player/native_worn/native_rig.gd")
const Motion = preload("res://scripts/player/native_worn/runtime_motion.gd")
const Equipment = preload("res://scripts/player/native_worn/pickaxe_equipment.gd")
const Surface = preload("res://scripts/player/native_worn/contact_surface.gd")
const ClothFit = preload("res://scripts/player/native_worn/cloth_fit.gd")
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
var bore_weight: float = 0.0
var bore_spin: float = 0.0
var mod_active: bool = false

func feedback_screen_rect() -> Rect2:
	# The displayed native viewport includes head, body and equipped tool. Its
	# canvas transform keeps feedback clear through camera zoom and movement.
	if not is_instance_valid(rig) or not rig.is_visible_in_tree(): return Rect2()
	var sprite: Sprite2D = rig.sprite
	if not is_instance_valid(sprite) or sprite.texture == null or not sprite.is_visible_in_tree(): return Rect2()
	return sprite.get_global_transform_with_canvas() * sprite.get_rect()

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
	bore_weight = 0.0
	bore_spin = 0.0
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
	# Preserve the imported rest mesh; fit sleeve deformation to the working
	# armature once per rig generation, before either equipment mesh is shown.
	ClothFit.new().apply(self)
	_refresh_canvas_pass()
	generations += 1
	return true

# Recheck at creation and gear changes; 2D is restored if a tool needs it.
func _refresh_canvas_pass() -> void:
	RenderingServer.viewport_set_disable_2d(rig.viewport.get_viewport_rid(),
		rig.viewport.find_children("*", "CanvasItem", true, false).is_empty())

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
	var owner_world: Node = player.get_parent()
	var modes: Node = owner_world.get("drill_modes")
	mod_active = is_instance_valid(modes) and modes.selected() in modes.five.IDS and owner_world.active
	# Existing native hero and braced tool bone; normal gear resumes on unequip.
	var target_gear: String = "crusher" if mod_active else visual.active_gear
	# Native models are already available; do not show the previous pickaxe
	# while unrelated fallback sprite atlases load after a workshop selection.
	if not mod_active and visual._wanted_gear in Equipment.GEARS:
		target_gear = visual._wanted_gear
	if failed or target_gear not in Equipment.GEARS or not visual.is_visible_in_tree():
		if is_instance_valid(rig): suspend()
		return false
	if not is_instance_valid(rig) and not _start(): return false
	if equipment.current != target_gear:
		bore_weight = 0.0
		bore_spin = 0.0
		if not equipment.equip(target_gear): return _fail("Native pickaxe identity mismatch: " + target_gear)
		_refresh_canvas_pass()
		motion.cap_local = equipment.contact_cap(reference_cap)
		motion.reference_cap = motion.bank.mine[21].bones.tool * motion.cap_local
		motion.contact_cache.clear()
		motion.serial = -1
	var packet: Dictionary = player.animation_packet()
	var bore_active: bool = (equipment.current == "crusher" and player.drill_motion_override or mod_active) and player.control_enabled
	bore_weight = move_toward(bore_weight, 1.0 if bore_active else 0.0, delta / 0.14)
	if bore_active:
		bore_spin = fposmod(bore_spin + delta * TAU * 2.4, TAU)
	else:
		bore_spin = move_toward(wrapf(bore_spin,-PI,PI),0.0,delta*TAU*4.0)
	if bore_active or bore_weight > 0.0:
		# Rush impacts still mine normally, but must not inject a pickaxe swing
		# into the braced two-handed pose. Consume the serial without its pose.
		packet.mining = false
		packet.mining_timing_valid = false
		packet.impact_target_valid = false
	packet.contact_surfaces = _surfaces(packet.target_position, String(packet.target_id)) if bool(packet.target_valid) else []
	if not packet.contact_surfaces.is_empty():
		last_target = packet.target_position
		last_surfaces = packet.contact_surfaces.duplicate()
		last_surface_origin = player.global_position
	packet.impact_surfaces = []
	if Vector2(packet.impact_target_position).is_equal_approx(last_target):
		for point in last_surfaces: packet.impact_surfaces.append(Vector2(point) + last_surface_origin - player.global_position)
	if not motion.advance(delta, packet): return _fail("Native Worn pose rejected: " + str(motion.errors))
	if not motion.bore_pose(bore_weight): return _fail("Bore Rush pose rejected: " + str(motion.errors))
	equipment.apply_pose()
	equipment.apply_bore(bore_active or not is_zero_approx(bore_spin), bore_spin)
	if mod_active and not equipment.verified: equipment._initialize()
	if equipment.verified:
		equipment.hero_mesh.mesh = equipment.body_mesh if mod_active or equipment.current != "worn" else equipment.original_mesh
	if is_instance_valid(equipment.tool): equipment.tool.visible = not mod_active
	rig.set_outfit(visual.OUTFIT_COLORS.get(visual.active_endless_outfit_style, visual.OUTFIT_COLORS.miner), visual.active_endless_outfit_style != "miner")
	updates += 1
	return true

func snapshot() -> Dictionary:
	return {"active":is_instance_valid(rig), "failed":failed, "failure":failure,
		"mod_active":mod_active,"bore_weight":bore_weight,"bore_spin":bore_spin,
		"gear":equipment.current if equipment != null else "", "updates":updates, "generations":generations, "surface_cache":surface_cache.size(),
		"motion":motion.snapshot() if motion != null else {},
		"unreachable_contacts":motion.unreachable_contacts if motion != null else 0}

func mod_anchor() -> Dictionary:
	if not mod_active or not is_instance_valid(rig): return {}
	var pose: Transform3D = rig.shown.tool
	var base: Vector3 = pose * Vector3.ZERO - rig.root_native
	var tip: Vector3 = pose * motion.cap_local - rig.root_native
	var a: Vector2 = rig.sprite.to_global(rig.camera.unproject_position(rig.AXIS * base))
	var b: Vector2 = rig.sprite.to_global(rig.camera.unproject_position(rig.AXIS * tip))
	return {"base":a,"tip":b}
