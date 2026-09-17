extends "res://scripts/lighting/cave_light_occluders.gd"
## Isolated shadow-submission study. Production rectangle generation is inherited unchanged.
## Bits 15..18 are reserved here; bit 19 belongs to StaticLightField.
const RESERVED: int = 0x78000
var masks_enabled: bool = true
var fallback_reason: String = ""
var eligible_pairs: int = 0
var baseline_pairs: int = 0
var mask_update_usec: int = 0
var total_refresh_usec: int = 0
var _owned: Array[Dictionary] = []
var _tracked_lights: Array[PointLight2D] = []
var _inventory_dirty: bool = true
var _inventory_conflict: bool = false
var _mask_signature: int = 0
var _mask_valid: bool = false

func _ready() -> void:
	super._ready()
	get_tree().node_added.connect(_inventory_changed)
	get_tree().node_removed.connect(_inventory_changed)
	visibility_changed.connect(_visibility_changed)

func _exit_tree() -> void:
	_restore_owned()

func _visibility_changed() -> void:
	if not is_visible_in_tree(): _restore_owned()

func invalidate_mask_inventory() -> void:
	_inventory_dirty = true
	_mask_valid = false

func _inventory_changed(node: Node) -> void:
	if node is CanvasItem and node.get_parent() != self and (node is PointLight2D or node is LightOccluder2D or (node.light_mask & RESERVED) != 0):
		invalidate_mask_inventory()

func _restore_owned() -> void:
	var field: Node = get_parent().get_node_or_null("StaticLightField") if is_instance_valid(get_parent()) else null
	for entry in _owned:
		if is_instance_valid(entry.node):
			entry.node.shadow_item_cull_mask &= ~int(entry.added)
			# A field rebake can snapshot the temporary bit while the study is active.
			# Remove only that bit from the matching saved mask before releasing ownership.
			if field != null:
				for actor in field._actors:
					if actor.node == entry.node: actor.shadow_mask &= ~int(entry.added)
	_owned.clear()
	for caster in _pool: caster.occluder_light_mask = 1
	_mask_valid = false

func _audit_inventory(world: Node2D) -> void:
	_tracked_lights.clear()
	_inventory_conflict = false
	for node in world.find_children("*", "CanvasItem", true, false):
		if node is PointLight2D: _tracked_lights.append(node)
		if (node.light_mask & RESERVED) != 0: _inventory_conflict = true
		if node is LightOccluder2D and node.get_parent() != self and (node.occluder_light_mask & RESERVED) != 0:
			_inventory_conflict = true
	_inventory_dirty = false

func refresh() -> void:
	var refresh_started: int = Time.get_ticks_usec()
	var world: Node2D = get_parent()
	# Rebuild the inherited lamp cache when children change inside the same actor.
	if _inventory_dirty:
		_restore_owned()
		_audit_inventory(world)
		_hero_lamp = null
		_companion_lamp = null
		_input_valid = false
	super.refresh()
	var started: int = Time.get_ticks_usec()
	fallback_reason = ""
	if not masks_enabled or not is_visible_in_tree(): fallback_reason = "disabled"
	elif _inventory_conflict: fallback_reason = "reserved mask collision"
	elif _lamps.size() > 4: fallback_reason = "more than four managed lights"
	for light in _tracked_lights:
		if not is_instance_valid(light): continue
		var owned_bit: int = 0
		for entry in _owned:
			if entry.node == light: owned_bit = int(entry.added)
		if (light.shadow_item_cull_mask & RESERVED & ~owned_bit) != 0:
			fallback_reason = "reserved shadow mask collision"
		if light.enabled and light.shadow_enabled and light.is_visible_in_tree() and not _lamps.has(light):
			fallback_reason = "unmanaged shadow light"
	if not fallback_reason.is_empty():
		_restore_owned()
		mask_update_usec = Time.get_ticks_usec() - started
		total_refresh_usec = Time.get_ticks_usec() - refresh_started
		return
	var tile: float = 64.0 if world.has_method("_is_floor") else 48.0
	var areas: Array[Rect2] = []
	var bits: Array[int] = []
	var key: Array = [_signature, active_count]
	for i in _lamps.size():
		var light: PointLight2D = _lamps[i]
		if not is_instance_valid(light): continue
		var bit: int = 1 << (15 + i)
		var owned: bool = false
		for entry in _owned:
			if entry.node == light: owned = true
		if not owned: _owned.append({"node":light,"added":bit})
		# StaticLightField may restore the original mask after a rebake.
		# Reassert only this study's bit; leave every other mask bit untouched.
		if (light.shadow_item_cull_mask & bit) == 0: light.shadow_item_cull_mask |= bit
		var active: bool = light.enabled and light.shadow_enabled and light.is_visible_in_tree() and (light.shadow_item_cull_mask & 1) != 0
		key.append([light.get_instance_id(), active, light.shadow_item_cull_mask])
		if not active: continue
		var cells: Rect2i = _source_cell_bounds(world, light, tile)
		areas.append(Rect2(Vector2(cells.position) * tile, Vector2(cells.size) * tile))
		bits.append(bit)
		key.append(cells)
	var signature: int = hash(key)
	if _mask_valid and signature == _mask_signature:
		mask_update_usec = Time.get_ticks_usec() - started
		total_refresh_usec = Time.get_ticks_usec() - refresh_started
		return
	_mask_valid = true
	_mask_signature = signature
	eligible_pairs = 0
	baseline_pairs = active_count * areas.size()
	for index in active_count:
		var points: PackedVector2Array = _pool[index].occluder.polygon
		var rect := Rect2(points[0], points[2] - points[0])
		var mask: int = 0
		for light_index in areas.size():
			if rect.intersects(areas[light_index], true):
				mask |= bits[light_index]
				eligible_pairs += 1
		_pool[index].occluder_light_mask = mask
	mask_update_usec = Time.get_ticks_usec() - started
	total_refresh_usec = Time.get_ticks_usec() - refresh_started
