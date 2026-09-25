extends Node
# QA ablation only; never a production lighting mode.
var native_viewports: Array[SubViewport] = []
var empty_2d_disabled: bool = false
var ui: CanvasLayer
var hud: CanvasLayer
var ui_group: Node2D
var parked: SubViewport
var original_custom_viewport: Node
var ui_children: Array[Node] = []
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
	ui = world.get_parent().get_node("CompanionInterface")
	hud = world.get_parent().get_node("HUD")
	original_custom_viewport = ui.custom_viewport
	ui_children.assign(ui.get_children())
	for node in world.find_children("NativeRig200px", "SubViewport", true, false):
		if node.find_children("*", "CanvasItem", true, false).is_empty(): native_viewports.append(node)
	occlusion = world.get_node("CaveLightOccluders")
	process_priority = 100
	for node in world.find_children("*", "PointLight2D", true, false):
		lights.append(node)
		original.append({"enabled":node.enabled,"shadows":node.shadow_enabled,"filter":node.shadow_filter})
	occlusion.set_process(false)
func select(value: String) -> void:
	mode = value
	empty_2d_disabled = value == "no_empty_2d"
	_select_ui(empty_2d_disabled)
	for viewport in native_viewports:
		RenderingServer.viewport_set_disable_2d(viewport.get_viewport_rid(), empty_2d_disabled)
	occlusion.qa_use_occupancy_revision = true
	for i in lights.size():
		var light: PointLight2D = lights[i]
		light.enabled = original[i].enabled
		light.shadow_enabled = original[i].shadows
		light.shadow_filter = original[i].filter
		if mode == "hard_shadows": light.shadow_filter = Light2D.SHADOW_FILTER_NONE
		if mode == "no_shadows": light.shadow_enabled = false
		if mode == "cones_off" and light.name == "HelmetCone": light.enabled = false
		if mode == "bounce_off" and light.name == "HelmetBounce": light.enabled = false
		var fixed: bool = str(light.get_parent().name).begins_with("WorkLight_")
		if mode == "fixed_off" and fixed: light.enabled = false
		if mode == "headlamps_off" and not fixed: light.enabled = false
		if mode == "lights_off": light.enabled = false
	occlusion.refresh()
func _process(_delta: float) -> void:
	# Freeze command stops this node too. Return to instrumented ownership
	# after unfreeze restores processing on the original node.
	occlusion.set_process(false)
	if is_instance_valid(ui_group): ui_group.visible = ui.visible
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
	var native_inventory: Array = []
	for viewport in native_viewports:
		native_inventory.append({"path":str(world.get_path_to(viewport)),"size":viewport.size,"canvas_items":viewport.find_children("*", "CanvasItem", true, false).size(),"update_mode":viewport.render_target_update_mode})
	var commerce: Control = world.get_parent().commerce_panel
	return {"parking_update_mode":parked.render_target_update_mode if is_instance_valid(parked) else -1,"ui_button":_center(ui.button),"ui_close":_center(commerce.close_button),"commerce_open":commerce.is_open(),"ui_combined":is_instance_valid(ui_group),"ui_canvas_detached":is_instance_valid(parked) and ui.custom_viewport == parked,"ui_child_count":ui_group.get_child_count() if is_instance_valid(ui_group) else ui.get_child_count(),"ui_visible":ui.visible,"empty_2d_disabled":empty_2d_disabled,"native_viewports":native_inventory,"mode":mode,"refresh_calls":calls,"refresh_usec":usec,"rebuilds":occlusion.rebuild_count-start_rebuilds,"occluders":occlusion.active_count,"lights":inventory}

func _center(control: Control) -> Array:
	var point: Vector2 = control.get_global_rect().get_center()
	return [point.x, point.y]

func release() -> void:
	set_process(false)
	if is_instance_valid(occlusion):
		select("baseline")
		occlusion.set_process(true)
	queue_free()

func _select_ui(value: bool) -> void:
	if value == is_instance_valid(ui_group): return
	if value:
		# The bounded fixture uses identity screen-space layers and exactly three UI children.
		assert(ui_children.size() == 3 and ui.transform == hud.transform)
		assert(not ui.follow_viewport_enabled and not hud.follow_viewport_enabled)
		assert(original_custom_viewport == null and hud.custom_viewport == null)
		ui_group = Node2D.new()
		ui_group.name = "QASharedCompanionUI"
		ui_group.z_index = 4095
		ui_group.visible = ui.visible
		hud.add_child(ui_group)
		for child in ui_children: child.reparent(ui_group, false)
		# Preserve the controller node/API while removing its now-empty canvas from the live viewport.
		parked = SubViewport.new()
		parked.name = "QADisabledUICanvas"
		parked.size = Vector2i(2,2)
		parked.disable_3d = true
		parked.render_target_update_mode = SubViewport.UPDATE_DISABLED
		world.get_parent().add_child(parked)
		ui.custom_viewport = parked
	else:
		ui.custom_viewport = original_custom_viewport
		for i in ui_children.size():
			ui_children[i].reparent(ui, false)
			ui.move_child(ui_children[i], i)
		ui_group.queue_free()
		ui_group = null
		parked.queue_free()
		parked = null
