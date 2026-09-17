extends SceneTree
## Real DEV11 world/resources and real section configuration; no pixel claim.
var output: String
var main: Node
var world: Node
var controller: Node
var rows: Array[Dictionary] = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not output.is_absolute_path() or DisplayServer.get_name() != "headless": quit(2); return
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("RunState").initialize_persistence(output.path_join("isolated-save.json"))
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for frame in 5: await process_frame
	root.get_node("RunState").reset_run(false)
	root.get_node("RunState").world_seed = 4608
	seed(4608)
	if not main._dev_jump_endless(12): quit(3); return
	world = main.endless_world
	# This builds the genuine section nodes/bindings without calling any paint
	# outside its legal draw notification. Headless output is never visual QA.
	world._draw_partitioned_deep(Vector2i(16,20), Vector2i(27,31))
	await create_timer(1.0).timeout
	var alpha_parent: Node2D = Node2D.new()
	alpha_parent.name = "OpacityGuardParent"
	main.add_child(alpha_parent)
	world.reparent(alpha_parent, true)
	controller = load("res://tools/floor_blend_pilot/controller.gd").new()
	root.add_child(controller)
	controller.configure(world)
	controller.candidate_enabled = true
	var material: ShaderMaterial = world._floor_materials.values()[0]
	var section: CanvasItem = world.lit_draw_sections._cached[Vector3i(20,16,0)]
	var tint: Color = material.get_shader_parameter("floor_tint")
	var wash: Color = material.get_shader_parameter("floor_wash")
	var adjacent: Texture2D = material.get_shader_parameter("previous_floor")
	var noise: Texture2D = material.get_shader_parameter("boundary_noise")
	_expect("normal-all-opaque", true)
	material.set_shader_parameter("floor_tint", Color(.81,.92,.99,1))
	_expect("opaque-rgb-material", true)
	material.set_shader_parameter("floor_tint", Color(tint, .65))
	_expect("material-alpha-fallback", false)
	material.set_shader_parameter("floor_tint", tint)
	alpha_parent.modulate.a = .65
	_expect("actual-parent-alpha-fallback", false)
	alpha_parent.modulate.a = 1
	world.modulate.a = .65
	_expect("actual-world-alpha-fallback", false)
	world.modulate.a = 1
	world.self_modulate.a = .65
	_expect("actual-world-self-alpha-fallback", false)
	world.self_modulate.a = 1
	world.lit_draw_sections.modulate.a = .65
	_expect("actual-section-owner-alpha-fallback", false)
	world.lit_draw_sections.modulate.a = 1
	section.modulate.a = .65
	_expect("actual-floor-item-alpha-fallback", false)
	section.modulate.a = 1
	section.self_modulate.a = .65
	_expect("actual-floor-item-self-alpha-fallback", false)
	section.self_modulate.a = 1
	world.darkness.color.a = .65
	_expect("actual-canvas-alpha-fallback", false)
	world.darkness.color.a = 1
	material.set_shader_parameter("floor_wash", Color(wash, .4))
	_expect("unproved-wash-fallback", false)
	material.set_shader_parameter("floor_wash", wash)
	material.set_shader_parameter("previous_floor", ImageTexture.create_from_image(adjacent.get_image()))
	_expect("replaced-neighbor-texture-fallback", false)
	material.set_shader_parameter("previous_floor", adjacent)
	material.set_shader_parameter("boundary_noise", null)
	_expect("unproved-noise-fallback", false)
	material.set_shader_parameter("boundary_noise", noise)
	var external: Shader = Shader.new()
	external.code = controller.source_shader.code
	material.shader = external
	_expect("external-shader-fallback", false)
	rows[-1]["external_shader_retained"] = material.shader == external
	material.shader = controller.source_shader
	root.transparent_bg = true
	_expect("transparent-framebuffer-fallback", false)
	root.transparent_bg = false
	var original_paint: Callable = section.paint
	section.paint = world._draw_impact_section.bind({"age":0.0})
	_expect("unknown-floor-paint-fallback", false)
	section.paint = world._draw_terrain_section.bind(20,16,18,0)
	_expect("unproved-floor-paint-bounds-fallback", false)
	section.paint = original_paint
	_expect("restored-opaque-state", true)
	controller.candidate_enabled = false
	controller._before_render()
	var restored: bool = true
	for current in world._floor_materials.values(): restored = restored and current.shader == controller.source_shader
	var passed: int = 0
	for row in rows:
		if row.passed: passed += 1
	var success: bool = passed == rows.size() and restored and bool(rows[13].external_shader_retained)
	FileAccess.open(output.path_join("opacity-guards.json"),FileAccess.WRITE).store_string(JSON.stringify({
		"rows":rows,"passed":passed,"total":rows.size(),"restored_source_shaders":restored,
		"rendered":false,"pixel_or_blend_equivalence_proved":false,
		"controller_sha256":FileAccess.get_sha256("res://tools/floor_blend_pilot/controller.gd"),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),
		"limit":"Headless actual resource/scene alpha guards only. Section setup is genuine; queued paint and framebuffer blend execution are not visually verified."},"\t"))
	print("FLOOR_OPACITY_GUARDS_COMPLETE passed=",passed,"/",rows.size()," restored=",restored)
	quit(0 if success else 4)

func _expect(label: String, eligible: bool) -> void:
	controller._before_render()
	var active: bool = controller.last_material_count > 0
	rows.append({"id":label,"expected_eligible":eligible,"active":active,
		"passed":active == eligible,"snapshot":controller.study_snapshot()})
