extends "res://tools/profile_premium_render.gd"
## Compare the same frozen native scene, default lighting -> visible texels ->
## default lighting again. No atlas, resampling, quality or shadow changes.
const VISIBLE_PIXELS := preload("res://shaders/lit_visible_pixels.tres")

func _review() -> void:
	_freeze(world)
	main.achievement_toast.clear()
	main.achievement_toast.hide()
	var sections: Array[Dictionary] = []
	for node in world.find_children("*", "Node2D", true, false):
		if node.material == VISIBLE_PIXELS and not node.use_parent_material:
			sections.append({"node":node,"material":node.material})
	assert(not sections.is_empty(), "No production material in the captured scene")
	for entry in sections:
		entry.node.material = null
		entry.node.use_parent_material = true
	await _measure("default_lighting")
	for entry in sections:
		entry.node.material = entry.material
		entry.node.use_parent_material = false
	await _measure("visible_pixels")
	for entry in sections:
		entry.node.material = null
		entry.node.use_parent_material = true
	await _measure("default_restored")
	for entry in sections:
		entry.node.material = entry.material
		entry.node.use_parent_material = false
