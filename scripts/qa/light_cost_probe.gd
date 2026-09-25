extends Node
# QA ablation only; never a production lighting mode.
var world: Node2D
var occlusion: Node
var lights: Array[PointLight2D] = []
var original: Array[Dictionary] = []
var mode: String = "baseline"
var calls: int = 0
var usec: int = 0
var start_rebuilds: int = 0
func configure(owner_world: Node2D) -> void:
	world = owner_world
	occlusion = world.get_node("CaveLightOccluders")
	process_priority = 100
	for node in world.find_children("*", "PointLight2D", true, false):
		lights.append(node)
		original.append({"enabled":node.enabled,"shadows":node.shadow_enabled,"filter":node.shadow_filter})
	occlusion.set_process(false)
func select(value: String) -> void:
	mode = value
	occlusion.qa_use_occupancy_keys = value == "occupancy_keys"
	for i in lights.size():
		var light: PointLight2D = lights[i]
		light.enabled = original[i].enabled
		light.shadow_enabled = original[i].shadows
		light.shadow_filter = original[i].filter
		if mode == "hard_shadows": light.shadow_filter = Light2D.SHADOW_FILTER_NONE
		if mode == "no_shadows": light.shadow_enabled = false
		if mode == "cones_off" and light.name == "HelmetCone": light.enabled = false
		if mode == "bounce_off" and light.name == "HelmetBounce": light.enabled = false
		if mode == "lights_off": light.enabled = false
	occlusion.refresh()
func _process(_delta: float) -> void:
	# Freeze command stops this node too. Return to instrumented ownership
	# after unfreeze restores processing on the original node.
	occlusion.set_process(false)
	if mode == "frozen_occluders": return
	var begin: int = Time.get_ticks_usec()
	occlusion.refresh()
	usec += Time.get_ticks_usec() - begin
	calls += 1
func reset() -> void:
	calls = 0
	usec = 0
	start_rebuilds = occlusion.rebuild_count
func snapshot() -> Dictionary:
	var inventory: Array = []
	for light in lights:
		inventory.append({"path":str(world.get_path_to(light)),"enabled":light.enabled,"shadow":light.shadow_enabled,"filter":light.shadow_filter})
	return {"mode":mode,"refresh_calls":calls,"refresh_usec":usec,"rebuilds":occlusion.rebuild_count-start_rebuilds,"occluders":occlusion.active_count,"lights":inventory}

func release() -> void:
	set_process(false)
	if is_instance_valid(occlusion):
		select("baseline")
		occlusion.set_process(true)
	queue_free()
