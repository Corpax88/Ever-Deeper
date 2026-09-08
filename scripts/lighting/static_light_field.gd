extends Node2D
## Cache only fixed, flat, additive lamps. Original nodes remain the reversible reference.
## Moving helmet lights and their occluders continue through the engine's lighting path.
const FLOOR_MASK: int = 1 << 19
const MAX_FIELD_SIZE: int = 2048
const MAX_SOURCES: int = 32
const PROBE_LOCK: StringName = &"fixed_light_probe_lock"

var enabled: bool = true:
	set(value):
		enabled = value
		_apply()
var ready_for_use: bool = false
var baking: bool = false
var generation: int = 0
var bake_count: int = 0
var field_bounds := Rect2()
var normalization: float = 1.0
var _world: Node2D
var _source_root: Node
var _sources: Array[Dictionary] = []
var _actors: Array[Dictionary] = []
var _field: PointLight2D
var _floor_material: ShaderMaterial
var _viewport: SubViewport
var _scheduled: bool = false
var _waiting_for_probe: bool = false
var _applied: bool = false
var _last_visible: bool = false

func _init() -> void:
	name = "StaticLightField"
	process_mode = Node.PROCESS_MODE_ALWAYS

func configure(world: Node2D, source_root: Node) -> void:
	_world = world
	_source_root = source_root
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	generation += 1
	_waiting_for_probe = false
	_restore_sources()
	ready_for_use = false
	baking = false
	if is_instance_valid(_field):
		_field.enabled = false
		_field.texture = null
	if is_instance_valid(_viewport):
		_viewport.queue_free()
		_viewport = null
	if not _scheduled:
		_scheduled = true
		_rebuild.call_deferred()

func _exit_tree() -> void:
	_restore_sources()

func _process(_delta: float) -> void:
	if not is_instance_valid(_world): return
	if _waiting_for_probe and not bool(_world.get_meta(PROBE_LOCK, false)):
		_waiting_for_probe = false
		_rebuild()
	if ready_for_use and enabled and not _applied and not bool(_world.get_meta(PROBE_LOCK, false)):
		_apply()
	if _applied and is_instance_valid(_field):
		var visible_now: bool = _field.enabled and _field.visible
		if visible_now != _last_visible:
			_last_visible = visible_now
			_floor_material.set_shader_parameter("fixed_enabled", visible_now)

func _restore_sources() -> void:
	_applied = false
	for entry in _sources:
		if is_instance_valid(entry.node): entry.node.enabled = entry.enabled
	for entry in _actors:
		if is_instance_valid(entry.node):
			entry.node.range_item_cull_mask = entry.mask
			entry.node.shadow_item_cull_mask = entry.shadow_mask
	_actors.clear()
	if is_instance_valid(_world) and is_instance_valid(_world.lit_floor_chunks): _world.lit_floor_chunks.set_fixed_field(null, 0)
	if is_instance_valid(_field): _field.enabled = false

func _capture_actor(light: PointLight2D) -> void:
	for entry in _actors:
		if entry.node == light: return
	_actors.append({"node":light,"mask":light.range_item_cull_mask,"shadow_mask":light.shadow_item_cull_mask})
	light.range_item_cull_mask |= FLOOR_MASK
	light.shadow_item_cull_mask |= FLOOR_MASK

func _is_actor(light: PointLight2D) -> bool:
	var ancestor: Node = light
	while ancestor != null and ancestor != _world:
		if ancestor.name == "Player" or ancestor.name == "MoleCompanion": return true
		ancestor = ancestor.get_parent()
	return false

func _on_node_added(node: Node) -> void:
	if _applied and node is PointLight2D and _world.is_ancestor_of(node) and _is_actor(node):
		_capture_actor(node)

func _apply() -> void:
	if not is_instance_valid(_world): return
	if not enabled:
		_restore_sources()
		return
	if not ready_for_use or bool(_world.get_meta(PROBE_LOCK, false)): return
	for entry in _sources:
		if not is_instance_valid(entry.node): return
	for entry in _sources: entry.node.enabled = false
	for node in _world.find_children("*", "PointLight2D", true, false):
		if _is_actor(node): _capture_actor(node)
	_field.enabled = true
	_last_visible = true
	_floor_material.set_shader_parameter("fixed_enabled", true)
	_floor_material.set_shader_parameter("ambient", _world.darkness.color)
	_world.lit_floor_chunks.set_fixed_field(_floor_material, FLOOR_MASK)
	_applied = true

func _rebuild() -> void:
	_scheduled = false
	if not is_instance_valid(_source_root) or not is_instance_valid(_world): return
	if DisplayServer.get_name() == "headless": return
	# Never change the source set during an opt-in lighting diagnostic.
	if bool(_world.get_meta(PROBE_LOCK, false)):
		_waiting_for_probe = true
		return
	var revision: int = generation
	_sources.clear()
	field_bounds = Rect2()
	for node in _source_root.find_children("*", "PointLight2D", true, false):
		if not node.enabled: continue
		if node.shadow_enabled or node.blend_mode != Light2D.BLEND_MODE_ADD or node.height != 0.0 or node.range_item_cull_mask != 1:
			return
		if node.range_z_min != -1024 or node.range_z_max != 1024 or node.range_layer_min != 0 or node.range_layer_max != 0:
			return
		# These owners use SDR gradient textures; arbitrary HDR/normal-mapped lamps fall back.
		if not node.texture is GradientTexture2D: return
		if node.texture.gradient == null or node.texture.gradient.interpolation_mode != 0: return
		for color in node.texture.gradient.colors:
			if color.r < 0.0 or color.g < 0.0 or color.b < 0.0 or color.a < 0.0 or color.r > 1.0 or color.g > 1.0 or color.b > 1.0 or color.a > 1.0: return
		var local_transform: Transform2D = _world.global_transform.affine_inverse() * node.global_transform
		var size: Vector2 = node.texture.get_size() * node.texture_scale
		var rect: Rect2 = local_transform * Rect2(node.offset - size * 0.5, size)
		var weight: float = maxf(node.color.r, maxf(node.color.g, node.color.b)) * node.color.a * node.energy
		if weight < 0.0: return
		_sources.append({"node":node,"enabled":node.enabled,"rect":rect,"transform":local_transform,"weight":weight})
		field_bounds = field_bounds.merge(rect) if field_bounds.has_area() else rect
	if _sources.size() < 2 or _sources.size() > MAX_SOURCES: return
	field_bounds = Rect2(field_bounds.position.floor() - Vector2.ONE * 2, field_bounds.end.ceil() - field_bounds.position.floor() + Vector2.ONE * 4)
	var size := Vector2i(field_bounds.size)
	if size.x > MAX_FIELD_SIZE or size.y > MAX_FIELD_SIZE: return
	normalization = _energy_bound()
	# A conservative rectangle-overlap bound avoids a blocking per-pixel CPU scan.
	var viewport := SubViewport.new()
	_viewport = viewport
	viewport.size = size
	viewport.world_2d = World2D.new()
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	viewport.canvas_transform = Transform2D(0.0, -field_bounds.position)
	var background := Polygon2D.new()
	background.polygon = PackedVector2Array([field_bounds.position, Vector2(field_bounds.end.x, field_bounds.position.y), field_bounds.end, Vector2(field_bounds.position.x, field_bounds.end.y)])
	background.color = Color.BLACK
	viewport.add_child(background)
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/static_light_bake.gdshader")
	for entry in _sources:
		var light: PointLight2D = entry.node
		var sprite := Sprite2D.new()
		sprite.texture = light.texture
		sprite.transform = entry.transform
		sprite.scale *= light.texture_scale
		sprite.offset = light.offset / light.texture_scale
		sprite.material = material
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.modulate = Color(light.color.r * light.energy / normalization, light.color.g * light.energy / normalization, light.color.b * light.energy / normalization, light.color.a)
		viewport.add_child(sprite)
	baking = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	if revision != generation or not is_instance_valid(viewport): return
	var image: Image = viewport.get_texture().get_image()
	viewport.queue_free()
	_viewport = null
	baking = false
	if image.is_empty(): return
	if _field == null:
		_field = PointLight2D.new()
		_field.name = "FixedLampField"
		_field.enabled = false
		add_child(_field)
	_field.texture = ImageTexture.create_from_image(image)
	_field.texture_scale = 1.0
	_field.position = field_bounds.get_center()
	_field.energy = normalization
	_floor_material = ShaderMaterial.new()
	_floor_material.shader = preload("res://shaders/lit_floor_fixed_field.gdshader")
	_floor_material.set_shader_parameter("fixed_field", _field.texture)
	_floor_material.set_shader_parameter("fixed_origin", field_bounds.position)
	_floor_material.set_shader_parameter("fixed_inv_size", Vector2.ONE / field_bounds.size)
	_floor_material.set_shader_parameter("fixed_energy", normalization)
	bake_count += 1
	ready_for_use = true
	_apply()

func _energy_bound() -> float:
	var xs: Array[float] = []
	var ys: Array[float] = []
	for entry in _sources:
		xs.append(entry.rect.position.x); xs.append(entry.rect.end.x)
		ys.append(entry.rect.position.y); ys.append(entry.rect.end.y)
	xs.sort(); ys.sort()
	var maximum: float = 1.0
	for xi in range(xs.size() - 1):
		for yi in range(ys.size() - 1):
			var point := Vector2((xs[xi] + xs[xi + 1]) * 0.5, (ys[yi] + ys[yi + 1]) * 0.5)
			var weight: float = 0.0
			for entry in _sources:
				if entry.rect.has_point(point): weight += entry.weight
			maximum = maxf(maximum, weight)
	return ceilf(maximum * 1.01)

func debug_snapshot() -> Dictionary:
	return {"enabled":enabled,"ready":ready_for_use,"applied":_applied,"baking":baking,"sources":_sources.size(),"bake_count":bake_count,"bounds":field_bounds,"normalization":normalization,"texture_size":_field.texture.get_size() if _field != null and _field.texture != null else Vector2.ZERO}
