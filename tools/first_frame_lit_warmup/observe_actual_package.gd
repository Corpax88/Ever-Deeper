extends SceneTree
## Passive native observation of the intact candidate's compiled Main hook.
## No helper loading/replacement, QA flag, input, game-state or cleanup mutation.
signal target_observed

const SIZE := Vector2i(1696, 780)
const MAIN_SCRIPT := "res://scripts/main.gd"
const HELPER_SCRIPT := "res://scripts/lighting/first_frame_lit_warmup.gd"
const OWNER_SCRIPT := "res://scripts/lighting/lit_draw_sections.gd"
var output := ""
var main: Node
var helper_weak: WeakRef
var viewport_weak: WeakRef
var triangle_weak: WeakRef
var light_weak: WeakRef
var texture_weak: WeakRef
var owner_weak: WeakRef
var helper_id := 0
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var events: Array[Dictionary] = []
var report: Dictionary = {}
var frames := 0
var finished := false


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	frames += 1
	if frames > 600 and not finished:
		_check(false, "Observer completed within 600 frames")
		_finish()
	return false


func _check(ok: bool, label: String) -> bool:
	checks.append({"name": label, "passed": ok})
	if not ok:
		failures.append(label)
		print("ACTUAL_WARMUP_ASSERT_FAIL ", label)
	return ok


func _event(label: String) -> void:
	events.append({"label": label, "process_frames": Engine.get_process_frames(),
		"physics_frames": Engine.get_physics_frames(), "frames_drawn": Engine.get_frames_drawn(),
		"ticks_usec": Time.get_ticks_usec()})


func _identity(material: ShaderMaterial) -> Dictionary:
	return {"material_instance": material.get_instance_id(), "material_rid": material.get_rid().get_id(),
		"shader_instance": material.shader.get_instance_id(), "shader_rid": material.shader.get_rid().get_id()}


func _owner(node: Node) -> Node:
	var script: Script = node.get_script()
	if script != null and script.resource_path == OWNER_SCRIPT: return node
	for child in node.get_children():
		var found := _owner(child)
		if found != null: return found
	return null


func _owner_identity(node: Node) -> Dictionary:
	var material: ShaderMaterial = node.get_script().get_script_constant_map()["VISIBLE_PIXELS_MATERIAL"]
	return {"node_instance": node.get_instance_id(), "node_path": String(node.get_path()),
		"script_path": node.get_script().resource_path, "material": _identity(material)}


func _compiled_identity(logical: String) -> Dictionary:
	var remap := logical + ".remap"
	var config := ConfigFile.new()
	var status := config.load(remap)
	if not _check(status == OK, "Compiled remap exists: " + logical): return {}
	var target: String = config.get_value("remap", "path", "")
	if not _check(target.begins_with("res://.godot/") and target.ends_with(".gdc") and FileAccess.file_exists(target),
		"Remap points to compiled package script: " + logical): return {}
	return {"logical": logical, "remap": remap, "remap_sha256": FileAccess.get_sha256(remap),
		"compiled": target, "compiled_sha256": FileAccess.get_sha256(target)}


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_absolute_path() or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = SIZE
	root.content_scale_size = SIZE
	report = {"schema": 1, "complete": false, "candidate_main_hook_exercised": false,
		"passive_compiled_package_observation": true, "physical_iphone": false,
		"limits": ["Native observer entry instantiates intact compiled Main with normal autoloads; this is not intact browser bootstrap.",
			"No helper source injection, game/input/save mutation or forced cleanup. Readbacks can stall rendering and are untimed.",
			"No normal startup pixel parity, WebGL specialization, World2D destruction, speedup or physical-device claim."]}
	report.compiled_resources = [_compiled_identity(MAIN_SCRIPT), _compiled_identity(HELPER_SCRIPT), _compiled_identity(OWNER_SCRIPT)]
	node_added.connect(_watch_added)
	main = load("res://scenes/main/main.tscn").instantiate()
	_check(main.get_script().resource_path == MAIN_SCRIPT, "Actual Main uses its logical compiled package resource")
	main.ready.connect(_main_ready, CONNECT_ONE_SHOT)
	root.add_child(main)
	current_scene = main
	await target_observed
	for frame in 4: await process_frame
	var removed := true
	for ref in [helper_weak, viewport_weak, triangle_weak, light_weak, texture_weak]:
		removed = removed and ref != null and ref.get_ref() == null
	_check(removed, "Actual helper nodes and temporary texture leave after ordinary queue flush")
	var connected := false
	for row in RenderingServer.get_signal_connection_list("frame_post_draw"):
		var callback: Callable = row.callable
		if callback.get_object_id() == helper_id: connected = true
	_check(not connected, "Actual helper post-draw callback is gone")
	var original_owner: Node = owner_weak.get_ref() if owner_weak != null else null
	if _check(original_owner != null and original_owner.is_inside_tree(), "Original game material owner remains in the real Main tree"):
		report.owner_after_cleanup = _owner_identity(original_owner)
		_check(report.owner_before == report.owner_after_cleanup, "Same original owner still owns identical material and shader IDs/RIDs")
	_event("cleanup")
	report.cleanup = {"temporary_objects_released": removed, "helper_signal_connected": connected}
	var labels: Array[String] = []
	for event in events: labels.append(event.label)
	_check(labels == ["helper_added", "helper_ready", "main_ready", "target_post_draw", "cleanup"],
		"Compiled Main hook and draw/cleanup have the expected observed order")
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join("root-after-cleanup.png")) == OK,
		"Actual root image saved after ordinary cleanup")
	_finish()


func _watch_added(node: Node) -> void:
	var script: Script = node.get_script()
	if script == null or script.resource_path != HELPER_SCRIPT or node.get_class() != "Node": return
	_check(helper_weak == null, "Exactly one compiled helper is added")
	_check(node.get_parent() == main, "The real Main adds the helper as its child")
	helper_weak = weakref(node)
	helper_id = node.get_instance_id()
	_event("helper_added")
	node.ready.connect(_helper_ready, CONNECT_ONE_SHOT)


func _helper_ready() -> void:
	_event("helper_ready")
	var helper: Node = helper_weak.get_ref()
	var viewport: SubViewport = helper.get("_viewport")
	var triangle: Node2D = viewport.get_node("LitWarmupPolygon")
	var light: PointLight2D = viewport.get_node("LitWarmupLight")
	viewport_weak = weakref(viewport)
	triangle_weak = weakref(triangle)
	light_weak = weakref(light)
	texture_weak = weakref(light.texture)
	var original_owner := _owner(main)
	if _check(original_owner != null, "Original shared-material owner exists before Main.ready"):
		owner_weak = weakref(original_owner)
		report.owner_before = _owner_identity(original_owner)
		report.helper_material = _identity(triangle.material)
		_check(report.owner_before.material == report.helper_material, "Compiled helper and original owner share exact material/shader IDs")
	report.armed = {"size": [viewport.size.x, viewport.size.y], "update_mode": viewport.render_target_update_mode,
		"same_world_as_root": viewport.world_2d == root.world_2d, "light_enabled": light.enabled,
		"light_energy": light.energy, "light_mask": light.range_item_cull_mask, "triangle_mask": triangle.light_mask,
		"gui_input_disabled": viewport.gui_disable_input, "handle_input_locally": viewport.handle_input_locally}
	_check(viewport.size == Vector2i(16, 16) and viewport.world_2d != root.world_2d,
		"Actual target is a separate 16 by 16 World2D")
	_check(viewport.render_target_update_mode == SubViewport.UPDATE_ONCE and light.enabled,
		"Actual compiled helper requested one lit update")
	_check(viewport.gui_disable_input and not viewport.handle_input_locally, "Actual target does not handle GUI input")
	RenderingServer.frame_post_draw.connect(_drawn, CONNECT_ONE_SHOT)


func _main_ready() -> void:
	_event("main_ready")
	report.candidate_main_hook_exercised = _check(helper_weak != null and helper_weak.get_ref() != null and
		events.size() == 3 and events[1].label == "helper_ready",
		"Compiled helper was already ready when Main.ready fired")


func _drawn() -> void:
	_event("target_post_draw")
	var viewport: SubViewport = viewport_weak.get_ref()
	if _check(viewport != null, "Actual target exists for passive post-draw observation"):
		var image := viewport.get_texture().get_image()
		_check(image.get_size() == Vector2i(16, 16), "Actual target has the expected dimensions")
		var opaque := 0
		var correct := true
		for y in 16:
			for x in 16:
				var color := image.get_pixel(x, y)
				if x >= 2 and x < 14 and y >= 2 and y < 14:
					opaque += 1
					correct = correct and color.to_rgba32() == Color8(76, 76, 76, 255).to_rgba32()
				else: correct = correct and color.a == 0.0
		report.target = {"opaque": opaque, "exact_expected_lit_pixels": correct}
		_check(opaque == 144 and correct, "Actual compiled target matches the accepted 144 lit pixels and transparent exterior")
		_check(image.save_png(output.path_join("actual-target.png")) == OK, "Actual target PNG saved")
		_check(root.get_texture().get_image().save_png(output.path_join("root-first-observed.png")) == OK, "Actual first observed root PNG saved")
	target_observed.emit()


func _finish() -> void:
	if finished: return
	finished = true
	report.complete = failures.is_empty()
	report.checks = checks
	report.failures = failures
	report.events = events
	var path := output.path_join("result.json")
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.flush()
	file.close()
	DirAccess.rename_absolute(path + ".tmp", path)
	print("ACTUAL_WARMUP_PACKAGE_", "COMPLETE" if failures.is_empty() else "FAILED")
	quit(0 if failures.is_empty() else 1)
