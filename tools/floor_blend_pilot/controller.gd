extends Node
## Isolated pilot: switch only the existing Deep floor material's blend state.
## Every vertex/fragment/light calculation, texture, command and order is retained.

const WORLD_PATH := "res://scripts/world/endless_descent_world.gd"
const WORLD_SHA256 := "5115995cf0b1b531d51a65af832a9a818f2e14136abee3bc922b2f47fb3667ac"
const SHADER_PATH := "res://shaders/lit_biome_floor.gdshader"
const SHADER_SHA256 := "b45f9fff49a5eeeaa31f12b167290088c99ea36aa652a155df82797695a465c7"
const WASH_ALPHA: float = 0.2800000011920929

var target: Node
var candidate_enabled: bool = false
var source_shader: Shader
var candidate_shader: Shader
var _source_code: String
var _candidate_code: String
var _source_proved: bool = false
var _known_floors: Array[Texture2D] = []
var _image_proofs: Dictionary = {}
var _owned_materials: Dictionary = {}
var _canvas_modulates: Array[CanvasModulate] = []
var last_reasons: PackedStringArray = []
var last_material_count: int = 0
var last_floor_section_count: int = 0
var checks: int = 0
var active_frames: int = 0
var fallback_frames: int = 0
var controller_usec: int = 0

func configure(world: Node) -> void:
	target = world
	source_shader = load(SHADER_PATH)
	_source_code = FileAccess.get_file_as_string(SHADER_PATH)
	_source_proved = FileAccess.get_sha256(WORLD_PATH) == WORLD_SHA256 and FileAccess.get_sha256(SHADER_PATH) == SHADER_SHA256 and target.get_script().resource_path == WORLD_PATH
	_candidate_code = _source_code.replace("shader_type canvas_item;", "shader_type canvas_item;\nrender_mode blend_disabled;")
	candidate_shader = Shader.new()
	candidate_shader.code = _candidate_code
	for path in target.STRATUM_FLOOR_TEXTURE_PATHS:
		_known_floors.append(load(path) as Texture2D)
	for node in get_tree().root.find_children("*", "CanvasModulate", true, false):
		_canvas_modulates.append(node)
	get_tree().node_added.connect(_node_added)
	get_tree().node_removed.connect(_node_removed)
	RenderingServer.frame_pre_draw.connect(_before_render)

func _exit_tree() -> void:
	_restore_owned()
	if RenderingServer.frame_pre_draw.is_connected(_before_render): RenderingServer.frame_pre_draw.disconnect(_before_render)

func _node_added(node: Node) -> void:
	if node is CanvasModulate and not _canvas_modulates.has(node): _canvas_modulates.append(node)

func _node_removed(node: Node) -> void:
	if node is CanvasModulate: _canvas_modulates.erase(node)

func _before_render() -> void:
	var started: int = Time.get_ticks_usec()
	checks += 1
	last_material_count = 0
	last_floor_section_count = 0
	if not candidate_enabled:
		_restore_owned()
		last_reasons = PackedStringArray(["candidate disabled"])
		controller_usec += Time.get_ticks_usec() - started
		return
	last_reasons = opacity_reasons()
	if last_reasons.is_empty():
		for material in target._floor_materials.values():
			_owned_materials[material] = source_shader
			if material.shader != candidate_shader: material.shader = candidate_shader
			last_material_count += 1
		active_frames += 1
	else:
		_restore_owned()
		fallback_frames += 1
	controller_usec += Time.get_ticks_usec() - started

func _restore_owned() -> void:
	for material in _owned_materials:
		# An external material/shader replacement belongs to its caller.
		if is_instance_valid(material) and material.shader == candidate_shader: material.shader = _owned_materials[material]

func opacity_reasons() -> PackedStringArray:
	var reasons: PackedStringArray = []
	if not is_instance_valid(target) or not target.is_inside_tree(): return PackedStringArray(["world unavailable"])
	if not _source_proved or source_shader.code != _source_code or candidate_shader.code != _candidate_code:
		return PackedStringArray(["unproved world or shader source"])
	var viewport: Viewport = target.get_viewport()
	if viewport != get_tree().root or viewport.transparent_bg or viewport.use_hdr_2d:
		reasons.append("unsupported framebuffer alpha or HDR mode")
	if target.get_canvas() != target.get_world_2d().canvas: reasons.append("nonstandard world canvas")
	if not is_instance_valid(target.lit_draw_sections) or not target.lit_draw_sections.enabled:
		return PackedStringArray(["partitioned terrain unavailable"])
	reasons.append_array(_alpha_chain_reasons(target.lit_draw_sections))
	for node in _canvas_modulates:
		if is_instance_valid(node) and node.is_inside_tree() and node.is_visible_in_tree() and node.get_canvas() == target.get_canvas():
			if not _finite_color(node.color) or node.color.a != 1.0: reasons.append("canvas alpha/color: " + str(node.get_path()))
	if target._stratum_texture_cache.size() != _known_floors.size() or _known_floors.size() != 5:
		reasons.append("unproved floor texture set")
	else:
		for index in _known_floors.size():
			var texture: Texture2D = target._stratum_texture_cache[index].floor
			if texture != _known_floors[index] or not bool(_image_proof(texture).get("opaque", false)):
				reasons.append("nonopaque or replaced floor texture: " + str(index))
	var floor_materials: Array = target._floor_materials.values()
	if floor_materials.is_empty(): reasons.append("floor materials not initialized")
	for material in floor_materials:
		if not material is ShaderMaterial or material.shader not in [source_shader, candidate_shader]:
			reasons.append("unknown floor shader")
			continue
		var tint: Variant = material.get_shader_parameter("floor_tint")
		if not tint is Color or not _finite_color(tint) or tint.a != 1.0: reasons.append("floor tint alpha or finite color")
		# Every boundary branch uses these same opaque source textures and wash
		# alpha. Native alpha stays 1; (1 - wash.a) + wash.a produces alpha 1.
		for key in ["floor_wash", "previous_wash", "next_wash"]:
			var wash: Variant = material.get_shader_parameter(key)
			if not wash is Color or not _finite_color(wash) or wash.a != WASH_ALPHA: reasons.append("unproved wash: " + key)
		for key in ["previous_floor", "next_floor"]:
			var texture: Variant = material.get_shader_parameter(key)
			if not texture is Texture2D or not _known_floors.has(texture) or not bool(_image_proof(texture).get("opaque", false)):
				reasons.append("unproved neighbor texture: " + key)
		var noise: Variant = material.get_shader_parameter("boundary_noise")
		if not noise is Texture2D or noise != target._biome_boundary_noise or not bool(_image_proof(noise).get("unorm", false)):
			reasons.append("unproved finite boundary noise")
		for key in ["world_origin_y", "band_start", "band_height"]:
			var value: Variant = material.get_shader_parameter(key)
			if value == null: value = 1408.0 if key == "band_height" else 0.0
			if typeof(value) not in [TYPE_FLOAT, TYPE_INT] or not is_finite(float(value)) or (key == "band_height" and float(value) <= 0.0):
				reasons.append("unproved band coordinate: " + key)
	for key in target.lit_draw_sections._cached:
		if not key is Vector3i or key.z != 0: continue
		var section: Node = target.lit_draw_sections._cached[key]
		if not section.is_visible_in_tree(): continue
		last_floor_section_count += 1
		if section.get_parent() != target.lit_draw_sections or section.use_parent_material or not floor_materials.has(section.material):
			reasons.append("unknown floor section material or parent")
		if not _finite_color(section.modulate) or not _finite_color(section.self_modulate) or section.modulate.a != 1.0 or section.self_modulate.a != 1.0: reasons.append("floor section alpha/color")
		var paint: Callable = section.paint
		var arguments: Array = paint.get_bound_arguments()
		if section.world != target or paint.get_object() != target or paint.get_method() != &"_draw_terrain_section" or arguments != [key.x,key.y,mini(key.y+3,target.GRID_SIZE.x-1),0]:
			reasons.append("unproved floor paint command")
	if last_floor_section_count == 0: reasons.append("no active floor sections")
	return reasons

func _alpha_chain_reasons(item: Node) -> PackedStringArray:
	var reasons: PackedStringArray = []
	var node: Node = item
	while is_instance_valid(node):
		if node is CanvasItem:
			if not _finite_color(node.modulate) or not _finite_color(node.self_modulate) or node.modulate.a != 1.0 or node.self_modulate.a != 1.0: reasons.append("parent/self alpha/color: " + str(node.get_path()))
			var transform: Transform2D = node.get_global_transform_with_canvas()
			if not transform.x.is_finite() or not transform.y.is_finite() or not transform.origin.is_finite(): reasons.append("nonfinite item transform")
		node = node.get_parent()
	return reasons

func _finite_color(color: Color) -> bool:
	return is_finite(color.r) and is_finite(color.g) and is_finite(color.b) and is_finite(color.a)

func _image_proof(texture: Texture2D) -> Dictionary:
	if texture == null: return {}
	if _image_proofs.has(texture): return _image_proofs[texture]
	var result: Dictionary = {"opaque":false,"unorm":false,"size":str(texture.get_size())}
	var callback: Callable = _texture_changed.bind(texture)
	if not texture.changed.is_connected(callback): texture.changed.connect(callback)
	var picture: Image = texture.get_image()
	if picture == null or picture.is_empty(): return result
	if picture.is_compressed() and picture.decompress() != OK: return result
	var format: Image.Format = picture.get_format()
	result["format"] = format
	result.unorm = format in [Image.FORMAT_L8, Image.FORMAT_LA8, Image.FORMAT_R8, Image.FORMAT_RG8, Image.FORMAT_RGB8, Image.FORMAT_RGBA8, Image.FORMAT_RGB565, Image.FORMAT_RGBA4444]
	result.opaque = format in [Image.FORMAT_L8, Image.FORMAT_R8, Image.FORMAT_RG8, Image.FORMAT_RGB8, Image.FORMAT_RGB565]
	if format in [Image.FORMAT_LA8, Image.FORMAT_RGBA8]:
		var stride: int = 2 if format == Image.FORMAT_LA8 else 4
		var bytes: PackedByteArray = picture.get_data()
		result.opaque = true
		for index in range(stride - 1, bytes.size(), stride):
			if bytes[index] != 255: result.opaque = false; break
	_image_proofs[texture] = result
	return result

func _texture_changed(texture: Texture2D) -> void:
	_image_proofs.erase(texture)

func study_snapshot() -> Dictionary:
	return {"candidate":candidate_enabled,"active_materials":last_material_count,
		"floor_sections":last_floor_section_count,"fallback_reasons":last_reasons,
		"checks":checks,"active_frames":active_frames,"fallback_frames":fallback_frames,
		"controller_usec":controller_usec,"source_proved":_source_proved,
		"source_shader_sha256":SHADER_SHA256,"world_sha256":WORLD_SHA256,
		"effect":"Only material blend mode changes. No fragment/vertex/light arithmetic changes."}
