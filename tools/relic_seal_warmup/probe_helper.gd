extends SceneTree
## Mechanism diagnostic only: unchanged 9d52 candidate Main plus the isolated seal helper.
## Installation uses Main.ready, immediately after its original _ready returns.
## The candidate Main insertion itself is NOT exercised or approved here.
signal target_observed

const SIZE := Vector2i(1696, 780)
var output := ""
var helper_path := ""
var variant := ""
var main: Node
var helper_weak: WeakRef
var viewport_weak: WeakRef
var sprite_weak: WeakRef
var light_weak: WeakRef
var texture_weak: WeakRef
var material_weak: WeakRef
var shader_weak: WeakRef
var factory_parent: Node2D
var factory_parent_weak: WeakRef
var factory_pad_weak: WeakRef
var factory_material_weak: WeakRef
var original_texture_weak: WeakRef
var world_weak: WeakRef
var helper_id := 0
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var report: Dictionary = {}
var frame_count := 0
var finished := false


func _initialize() -> void:
	_run.call_deferred()


func _process(_delta: float) -> bool:
	frame_count += 1
	if frame_count > 600 and not finished:
		_check(false, "Diagnostic completed within600frames")
		_finish()
	return false


func _check(ok: bool, label: String) -> bool:
	checks.append({"name": label, "passed": ok})
	if not ok:
		failures.append(label)
		print("SEAL_HELPER_ASSERT_FAIL ", label)
	return ok


func _stamp() -> Dictionary:
	return {"process_frames": Engine.get_process_frames(),
		"physics_frames": Engine.get_physics_frames(),
		"frames_drawn": Engine.get_frames_drawn(), "ticks_usec": Time.get_ticks_usec()}


func _scalar_state() -> Dictionary:
	var state: Node = root.get_node("RunState")
	var values: Dictionary = {}
	for property in state.get_script().get_script_property_list():
		var value: Variant = state.get(property.name)
		if typeof(value) in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME]:
			values[String(property.name)] = value
	return values


func _identity(material: ShaderMaterial) -> Dictionary:
	return {"material_instance": material.get_instance_id(),
		"material_rid": material.get_rid().get_id(),
		"shader_instance": material.shader.get_instance_id(),
		"shader_rid": material.shader.get_rid().get_id()}


func _prepare_original_factory() -> void:
	# This is an explicit test-induced call, not an already-visible game pad.
	var world: Node = main.get("endless_world")
	world_weak = weakref(world)
	factory_parent = Node2D.new()
	factory_parent_weak = weakref(factory_parent)
	world.call("_add_site_pad", factory_parent, "OriginalFactoryPad", Vector2.ZERO, Color("7be6d0"))
	var pad: Sprite2D = factory_parent.get_node("OriginalFactoryPad")
	factory_pad_weak = weakref(pad)
	factory_material_weak = weakref(pad.material)
	shader_weak = weakref(pad.material.shader)
	original_texture_weak = weakref(pad.texture)
	report.factory = {"test_induced": true, "detached_parent": not factory_parent.is_inside_tree(),
		"world_instance": world.get_instance_id(), "world_script": world.get_script().resource_path,
		"material": _identity(pad.material), "texture_instance": pad.texture.get_instance_id(),
		"texture_rid": pad.texture.get_rid().get_id(), "texture_path": pad.texture.resource_path,
		"position": [pad.position.x, pad.position.y], "z_index": pad.z_index}
	_check(pad.material.shader.resource_path == "res://shaders/lit_relic_seal.gdshader",
		"Original compiled world factory binds the expected existing shader")


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--helper="): helper_path = arg.trim_prefix("--helper=")
		elif arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
	if not output.is_absolute_path() or not helper_path.is_absolute_path() or variant not in ["lit", "no_light"] or DisplayServer.get_name() == "headless":
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = SIZE
	root.content_scale_size = SIZE
	report = {"schema": 1, "variant": variant, "complete": false,
		"mechanism_only": true, "candidate_main_hook_exercised": false,
		"fps_or_webgl_specialization_claim": false, "physical_iphone": false,
		"helper_path": helper_path, "helper_sha256": FileAccess.get_sha256(helper_path),
		"observer_entry": _stamp(),
		"limits": ["Unchanged 9d52 compiled Main; helper installed by its ready signal after original _ready, not by the candidate source hook.",
			"No input, save, startup pixel parity, gameplay shader reuse or performance acceptance. Native Linux graphics is not WebKit or physical iPhone.",
			"Original factory pad/material are test-induced and freed before first draw; only scalar IDs/WeakRefs remain. Live shader identity after cleanup does not identify which script/resource cache retains it.",
			"The no_light control disables only the helper light before the first draw; all source code stays identical.",
			"Diagnostic readbacks are untimed and can stall rendering. Weak references and scalar IDs do not keep material/shader resources alive."]}
	main = load("res://scenes/main/main.tscn").instantiate()
	report.main_script = main.get_script().resource_path
	main.ready.connect(_install_helper, CONNECT_ONE_SHOT)
	root.add_child(main)
	current_scene = main
	await target_observed
	for frame in 4: await process_frame
	var removed := true
	for ref in [helper_weak, viewport_weak, sprite_weak, light_weak, texture_weak]:
		removed = removed and ref.get_ref() == null
	_check(removed, "Helper nodes and temporary texture are released after normal queue flush")
	var connected := false
	for row in RenderingServer.get_signal_connection_list("frame_post_draw"):
		var callback: Callable = row.callable
		if callback.get_object_id() == helper_id: connected = true
	_check(not connected, "Helper post-draw connection is removed")
	_check(material_weak.get_ref() == null, "Helper-owned material released after normal queue flush")
	_check(factory_parent_weak.get_ref() == null and factory_pad_weak.get_ref() == null and factory_material_weak.get_ref() == null,
		"Factory pad and material remain released during cleanup")
	_check(world_weak.get_ref() != null and shader_weak.get_ref() != null and original_texture_weak.get_ref() != null,
		"Original world and shared shader/texture outlive helper without factory resource keeper")
	if shader_weak.get_ref() != null:
		report.shader_after_cleanup = {"instance": shader_weak.get_ref().get_instance_id(), "rid": shader_weak.get_ref().get_rid().get_id()}
		_check(report.factory.material.shader_instance == report.shader_after_cleanup.instance and report.factory.material.shader_rid == report.shader_after_cleanup.rid,
			"Shared shader scalar IDs/RIDs are unchanged after cleanup")

	report.cleanup = {"stamp": _stamp(), "temporary_objects_released": removed,
		"helper_signal_connected": connected}
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png(output.path_join("menu-after-cleanup.png")) == OK,
		"Actual mobile menu image saved after cleanup")
	_finish()


func _install_helper() -> void:
	report.main_ready = {"stamp": _stamp(), "instance": main.get_instance_id(),
		"path": String(main.get_path()), "script": main.get_script().resource_path}
	report.scalar_state_before_install = _scalar_state()
	# Invoke the actual compiled original factory before loading the helper.
	# Its test-owned pad/material are freed synchronously below, before any await.
	_prepare_original_factory()
	var helper: Node = load(helper_path).new()
	helper_id = helper.get_instance_id()
	helper_weak = weakref(helper)
	helper.ready.connect(_observe_armed, CONNECT_ONE_SHOT)
	main.add_child(helper)
	# Free the factory objects before yielding: they cannot keep the shader alive.
	factory_parent.free()
	factory_parent = null
	report.factory.removed_before_first_await = factory_parent_weak.get_ref() == null and factory_pad_weak.get_ref() == null and factory_material_weak.get_ref() == null
	_check(report.factory.removed_before_first_await, "Test factory pad and material released synchronously before first draw")
	report.scalar_state_after_install = _scalar_state()
	_check(report.scalar_state_before_install == report.scalar_state_after_install,
		"RunState script scalar properties unchanged during synchronous helper installation")


func _observe_armed() -> void:
	var helper: Node = helper_weak.get_ref()
	var viewport: SubViewport = helper.get("_viewport")
	var sprite: Sprite2D = viewport.get_node("SealWarmupSprite")
	var light: PointLight2D = viewport.get_node("SealWarmupLight")
	if variant == "no_light": light.enabled = false
	viewport_weak = weakref(viewport)
	sprite_weak = weakref(sprite)
	light_weak = weakref(light)
	texture_weak = weakref(light.texture)
	material_weak = weakref(sprite.material)
	report.material_before = _identity(sprite.material)
	_check(report.factory.material.shader_instance == report.material_before.shader_instance and report.factory.material.shader_rid == report.material_before.shader_rid and report.factory.material.material_instance != report.material_before.material_instance,
		"Helper shares the original factory shader but owns a distinct temporary material")
	_check(sprite.texture.get_instance_id() == report.factory.texture_instance and sprite.texture.get_rid().get_id() == report.factory.texture_rid,
		"Helper uses the exact original factory texture resource")
	report.armed = {"stamp": _stamp(), "size": [viewport.size.x, viewport.size.y],
		"update_mode": viewport.render_target_update_mode,
		"same_world_as_root": viewport.world_2d == root.world_2d,
		"target_world_canvas": viewport.world_2d.canvas.get_id(),
		"root_world_canvas": root.world_2d.canvas.get_id(),
		"light_enabled": light.enabled, "light_energy": light.energy,
		"light_mask": light.range_item_cull_mask, "sprite_mask": sprite.light_mask,
		"z_min": light.range_z_min, "z_max": light.range_z_max,
		"gui_input_disabled": viewport.gui_disable_input}
	_check(viewport.size == Vector2i(16, 16) and viewport.world_2d != root.world_2d,
		"16x16 target owns an isolated World2D")
	RenderingServer.frame_post_draw.connect(_observe_drawn, CONNECT_ONE_SHOT)


func _observe_drawn() -> void:
	var viewport: SubViewport = viewport_weak.get_ref()
	if not _check(viewport != null, "Target still exists for diagnostic readback after post-draw"):
		target_observed.emit()
		return
	var image := viewport.get_texture().get_image()
	_check(image.get_size() == Vector2i(16, 16), "Actual target image is16x16")
	var visible := 0
	var unsaturated := 0
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a > 0.01:
				visible += 1
				if maxf(pixel.r, maxf(pixel.g, pixel.b)) < 0.95 and maxf(pixel.r, maxf(pixel.g, pixel.b)) > 0.01: unsaturated += 1
	var center := image.get_pixel(8, 8)
	var corner := image.get_pixel(0, 0)
	_check(visible > 0 and unsaturated > 0,
		"Target contains original textured pixels including unsaturated color")
	_check(corner.a < 0.01, "Target clears the exterior to transparent pixels")
	var hash_context := HashingContext.new()
	hash_context.start(HashingContext.HASH_SHA256)
	hash_context.update(image.get_data())
	report.target = {"stamp": _stamp(), "center_rgba": [center.r, center.g, center.b, center.a],
		"corner_rgba": [corner.r, corner.g, corner.b, corner.a],
		"visible_pixels": visible, "unsaturated_pixels": unsaturated,
		"pixel_sha256": hash_context.finish().hex_encode(),
		"update_mode_after_draw": viewport.render_target_update_mode}
	# Godot's getter keeps the requested mode. Only the renderer's internal mode
	# changes to DISABLED; that internal state is not asserted by this fixture.
	_check(viewport.render_target_update_mode == SubViewport.UPDATE_ONCE,
		"Viewport retains the requested one-shot mode after drawing")
	_check(image.save_png(output.path_join("target.png")) == OK, "Actual target PNG saved")
	_check(root.get_texture().get_image().save_png(output.path_join("first-observed-menu.png")) == OK,
		"Actual mobile root image saved with target readback")
	target_observed.emit()


func _finish() -> void:
	if finished: return
	finished = true
	report.complete = failures.is_empty()
	report.checks = checks
	report.failures = failures
	report.finished = _stamp()
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.flush()
	file.close()
	main.queue_free()
	for frame in 4: await process_frame
	print("SEAL_HELPER_DIAGNOSTIC_", "COMPLETE" if failures.is_empty() else "FAILED", " ", variant)
	quit(0 if failures.is_empty() else 1)
