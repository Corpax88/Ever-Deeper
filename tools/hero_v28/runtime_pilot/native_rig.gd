extends Node2D
## Isolated native-derived rig candidate. It never replaces production assets.
## Bone math stays in the original Blender frame until the final bind transform.

const AXIS: Transform3D = Transform3D(Basis(Vector3.RIGHT, Vector3(0, 0, -1), Vector3.UP), Vector3.ZERO)
const SIDES: Array[String] = ["R", "L"]
const BLEND_SECONDS: float = 0.075
var viewport: SubViewport
var sprite: Sprite2D
var skeleton: Skeleton3D
var camera: Camera3D
var data: Dictionary
var curves: Dictionary = {}
var rest: Dictionary = {}
var indices: Dictionary = {}
var imported_rest: Dictionary = {}
var mapping: Transform3D
var mapping_inverse: Transform3D
var hand_local: Dictionary = {}
var shoulder_local: Dictionary = {}
var heading: Basis
var ground_vector: Vector3
var root_native: Vector3 = Vector3.ZERO
var offset: Vector3 = Vector3.ZERO
var shown: Dictionary = {}
var older: Dictionary = {}
var residuals: Dictionary = {}
var blend_elapsed: float = BLEND_SECONDS
var state: String = "idle"
var phase: float = 0.0
var gait_phase: float = 0.0
var since_walk: float = 10.0
var prior_position: Vector2
var position_ready: bool = false
var plants: Dictionary = {}
var release_phase: float = -1.0
var release_offset: Vector3
var last_phase: float = 0.0
var maximum_reach_correction: float = 0.0
var maximum_grip_error: float = 0.0
var maximum_unreachable: float = 0.0
var maximum_air_retarget: float = 0.0
var reach_detail: Dictionary = {}
var transitions: int = 0
var material_view: String = "baked"
var clip_range: Vector2 = Vector2(.01, 100.0)
var import_flags: int = 0
var surface_formats: Array[int] = []
var raster_size: int = 200
var shadow_diagnostic: bool = false
var lighting_profile: String = "legacy"
var response_sha256: String = ""


func configure(candidate: String, pose_only: bool = false) -> bool:
	if material_view not in ["baked", "clay", "baked_no_normal", "albedo", "baked_response", "baked_shader_control"]: return false
	if clip_range.x <= 0.0 or clip_range.y <= clip_range.x: return false
	if import_flags not in [0, 8, 64, 72]: return false
	if raster_size not in [200, 400]: return false
	if lighting_profile not in ["legacy", "native_soft", "native_area", "native_balanced"]: return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(candidate.path_join("motion.json")))
	if not parsed is Dictionary: return false
	data = parsed
	if String(data.gear) != "worn": return false
	if String(data.direction) != "right" and String(data.get("action", "")) != "approved_flow20_reference": return false
	for name in Dictionary(data.rest): rest[name] = _matrix(data.rest[name])
	for side in SIDES: hand_local[side] = _matrix(data.hand_local[side])
	heading = _matrix(data.heading).basis
	ground_vector = _vector(data.ground_per_pixel)
	for mode in Dictionary(data.samples):
		curves[mode] = []
		for record in Array(data.samples[mode]):
			var bones: Dictionary = {}
			for name in Dictionary(record.bones): bones[name] = _matrix(record.bones[name])
			curves[mode].append({"phase": float(record.phase), "bones": bones})
	var neutral: Dictionary = curves.idle[0].bones
	for side in SIDES:
		shoulder_local[side] = Transform3D(neutral.body).affine_inverse() * Transform3D(neutral["upper."+side]).origin
	if pose_only:
		set_reference_pose("idle", 0.0)
		return true
	var receipt = JSON.parse_string(FileAccess.get_file_as_string(candidate.path_join("candidate.json")))
	if not receipt is Dictionary or not receipt.get("files") is Dictionary: return false
	for file_name in ["worn-native-runtime.glb", "motion.json", "albedo.png", "normal.png", "orm.png", "cloth.png"]:
		var expected_hash: String = String(receipt.files.get(file_name, ""))
		if expected_hash.length() != 64 or not FileAccess.file_exists(candidate.path_join(file_name)) or FileAccess.get_sha256(candidate.path_join(file_name)) != expected_hash:
			push_error("Native candidate file identity mismatch: " + file_name)
			return false
	viewport = SubViewport.new()
	viewport.name = "NativeRig200px"
	viewport.size = Vector2i(raster_size, raster_size)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_2X
	add_child(viewport)
	var document: GLTFDocument = GLTFDocument.new()
	var gltf: GLTFState = GLTFState.new()
	if document.append_from_file(candidate.path_join("worn-native-runtime.glb"), gltf, import_flags) != OK: return false
	var actor: Node3D = document.generate_scene(gltf) as Node3D
	if actor == null: return false
	viewport.add_child(actor)
	skeleton = _find_skeleton(actor)
	if skeleton == null: return false
	var material: StandardMaterial3D = StandardMaterial3D.new()
	# Preserve the exported native material's authored double-sided state.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_texture = _texture(candidate.path_join("albedo.png"))
	material.normal_enabled = material_view not in ["baked_no_normal", "albedo"]
	material.normal_texture = _texture(candidate.path_join("normal.png"))
	var orm: Texture2D = _texture(candidate.path_join("orm.png"))
	material.ao_enabled = true
	material.ao_texture = orm
	material.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	material.ao_light_affect = .35 if lighting_profile != "legacy" else 0.0
	material.roughness_texture = orm
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.metallic_texture = orm
	material.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	material.metallic = 1.0
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if material_view == "albedo":
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if material_view == "clay":
		material.albedo_texture = null
		material.normal_enabled = false
		material.ao_enabled = false
		material.roughness_texture = null
		material.metallic_texture = null
		material.albedo_color = Color(.5, .5, .5)
		material.roughness = .8
		material.metallic = 0.0
	if material_view in ["baked_response", "baked_shader_control"]:
		var response_path: String = candidate.path_join("component-response/response.png")
		var response_receipt = JSON.parse_string(FileAccess.get_file_as_string(candidate.path_join("component-response/report.json")))
		if not response_receipt is Dictionary or response_receipt.get("status") != "complete": return false
		response_sha256 = FileAccess.get_sha256(response_path)
		if response_sha256 != String(response_receipt.outputs.response.png_sha256): return false
		if String(response_receipt.albedo_report_sha256) != FileAccess.get_sha256(candidate.path_join("transfer-albedo/report.json")): return false
		var surface: ShaderMaterial = ShaderMaterial.new()
		surface.shader = load("res://tools/hero_v28/runtime_pilot/native_surface.gdshader")
		surface.set_shader_parameter("albedo_map", material.albedo_texture)
		surface.set_shader_parameter("normal_map", material.normal_texture)
		surface.set_shader_parameter("orm_map", orm)
		surface.set_shader_parameter("response_map", _texture(response_path))
		surface.set_shader_parameter("native_response", material_view == "baked_response")
		surface.set_shader_parameter("ao_direct", material.ao_light_affect)
		_set_material(actor, surface)
	else:
		_set_material(actor, material)
	mapping = skeleton.global_transform.affine_inverse() * AXIS
	mapping_inverse = mapping.affine_inverse()
	for index in skeleton.get_bone_count():
		var name: String = skeleton.get_bone_name(index)
		indices[name] = index
		imported_rest[name] = skeleton.get_bone_global_rest(index)
	for name in rest:
		if not indices.has(name):
			push_error("Native runtime skeleton lost source bone " + String(name))
			return false
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(data.camera.ortho_size)
	camera.near = clip_range.x
	camera.far = clip_range.y
	viewport.add_child(camera)
	camera.global_transform = AXIS * _matrix(data.camera.world_matrix)
	camera.make_current()
	var environment: WorldEnvironment = WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color(.42, .45, .51)
	environment.environment.ambient_light_energy = .35
	if lighting_profile != "legacy":
		# Original v28 world background is scene-linear RGB(.13,.15,.20), .23.
		environment.environment.ambient_light_color = Color(.13, .15, .20).linear_to_srgb()
		environment.environment.ambient_light_energy = .23
		environment.environment.adjustment_enabled = true
		environment.environment.adjustment_contrast = 1.15
	if lighting_profile in ["native_area", "native_balanced"]:
		# Bounded Compatibility diagnostic: real area highlights plus dynamic
		# cavity shading. Area shadows are unsupported in this renderer.
		environment.environment.ssao_enabled = true
		environment.environment.ssao_radius = .22
		environment.environment.ssao_intensity = 1.0
		environment.environment.ssao_light_affect = .5
		environment.environment.ssao_ao_channel_affect = .25
	if lighting_profile == "native_balanced":
		environment.environment.adjustment_enabled = false
		environment.environment.tonemap_exposure = .5
		environment.environment.tonemap_agx_contrast = 1.5
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_AGX
	viewport.add_child(environment)
	# Native area-light positions/colors. Shadowless omni approximation is an
	# explicit fidelity risk assessed against the genuine Cycles PNG references.
	if data.has("lights"):
		var strongest: float = 0.0
		for row in Array(data.lights): strongest = maxf(strongest, float(row.energy))
		for row in Array(data.lights):
			var rgb: Array = row.color
			_light(_vector(row.position), Color(float(rgb[0]), float(rgb[1]), float(rgb[2])),
				2.8 * float(row.energy) / maxf(strongest, 0.001), String(row.name))
	else:
		_light(Vector3(-4.8826499, 2.5317445, 4.7), Color(1, .89, .75), 2.8, "Native warm key")
		_light(Vector3(-2.1371870, -4.2086143, 3.0), Color(.72, .82, 1), .75, "Native cool fill")
		_light(Vector3(2.4824247, -.9041944, 3.8), Color(1, .8, .58), 1.65, "Native brass rim")
	sprite = Sprite2D.new()
	sprite.centered = false
	sprite.texture = viewport.get_texture()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = Vector2.ONE * (.8 * 200.0 / float(raster_size))
	add_child(sprite)
	var anchor: Vector2 = camera.unproject_position(Vector3.ZERO)
	sprite.position = Vector2(0, 2.8125) - anchor * sprite.scale
	set_reference_pose("idle", 0.0)
	return true


func _light(native_position: Vector3, color: Color, energy: float, label: String) -> void:
	if lighting_profile in ["native_area", "native_balanced"]:
		var area: AreaLight3D = AreaLight3D.new()
		area.name = label
		var diameter: float = 2.0 if label == "warm large key" else 3.0 if label == "soft cool fill" else 1.7
		# Equal-area rectangle for the native disk. This is an approximation,
		# not a claim of matching the native disk's complete BRDF integration.
		area.area_size = Vector2.ONE * diameter * sqrt(PI) * .5
		area.area_normalize_energy = true
		area.area_range = 20.0
		area.area_attenuation = 2.0
		area.light_color = color.linear_to_srgb()
		area.light_energy = energy * 32.0
		viewport.add_child(area)
		area.position = AXIS * native_position
		area.look_at(AXIS * Vector3(0, 0, 1.0))
		return
	var light: OmniLight3D = OmniLight3D.new()
	light.name = label
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 20.0
	light.omni_attenuation = 0.0
	light.shadow_enabled = shadow_diagnostic and label == "warm large key"
	if lighting_profile == "native_soft":
		# Native disks:2.0m key,3.0m fill,1.7m rim. Positional light_size
		# broadens specular highlights; Compatibility uses filtered map shadows.
		var diameter: float = 2.0 if label == "warm large key" else 3.0 if label == "soft cool fill" else 1.7
		light.light_color = color.linear_to_srgb()
		light.light_size = diameter * .5
		light.light_energy = energy * 32.0
		light.omni_attenuation = 2.0
		light.shadow_enabled = label == "warm large key"
		light.omni_shadow_mode = OmniLight3D.SHADOW_CUBE
		light.shadow_bias = .02
		light.shadow_normal_bias = .03
		light.shadow_blur = 2.0
	viewport.add_child(light)
	light.position = AXIS * native_position


func _texture(path: String) -> Texture2D:
	var picture: Image = Image.load_from_file(path)
	if picture == null or picture.is_empty(): return null
	picture.generate_mipmaps()
	return ImageTexture.create_from_image(picture)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D: return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null: return found
	return null


func _set_material(node: Node, material: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = material
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow_diagnostic or lighting_profile == "native_soft" else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for index in node.mesh.get_surface_count():
			surface_formats.append(node.mesh.surface_get_format(index))
	for child in node.get_children(): _set_material(child, material)


func reference_pose_error() -> float:
	var maximum: float = 0.0
	for name in shown:
		var expected: Transform3D = mapping * Transform3D(shown[name]) * Transform3D(rest[name]).affine_inverse() * mapping_inverse * Transform3D(imported_rest[name])
		var actual: Transform3D = skeleton.get_bone_global_pose(int(indices[name]))
		maximum = maxf(maximum, expected.origin.distance_to(actual.origin))
		for column in 3:
			maximum = maxf(maximum, expected.basis[column].distance_to(actual.basis[column]))
	return maximum


func _matrix(rows: Array) -> Transform3D:
	return Transform3D(Basis(Vector3(float(rows[0][0]), float(rows[1][0]), float(rows[2][0])),
		Vector3(float(rows[0][1]), float(rows[1][1]), float(rows[2][1])),
		Vector3(float(rows[0][2]), float(rows[1][2]), float(rows[2][2]))),
		Vector3(float(rows[0][3]), float(rows[1][3]), float(rows[2][3])))


func _vector(value: Array) -> Vector3:
	return Vector3(float(value[0]), float(value[1]), float(value[2]))


func sample(mode: String, at: float) -> Dictionary:
	var records: Array = curves[mode]
	var q: float = fposmod(at, 1.0)
	var lower: int = records.size() - 1
	for index in records.size():
		if float(records[index].phase) > q:
			lower = index - 1
			break
	var upper: int = (lower + 1) % records.size()
	var a: Dictionary = records[lower]
	var b: Dictionary = records[upper]
	var span: float = float(b.phase) - float(a.phase)
	if upper == 0: span += 1.0
	var weight: float = (q - float(a.phase)) / maxf(span, .000001)
	var result: Dictionary = {}
	for name in rest:
		var first: Transform3D = a.bones[name]
		var second: Transform3D = b.bones[name]
		result[name] = Transform3D(Basis(first.basis.get_rotation_quaternion().slerp(second.basis.get_rotation_quaternion(), weight)), first.origin.lerp(second.origin, weight))
	return result


func set_reference_pose(mode: String, at: float) -> void:
	state = mode
	phase = at
	gait_phase = float(data.flat_entry_phase)
	since_walk = 10.0
	root_native = Vector3.ZERO
	offset = Vector3.ZERO
	residuals.clear()
	plants.clear()
	position_ready = false
	blend_elapsed = BLEND_SECONDS
	shown = sample(mode, at)
	older = shown.duplicate()
	_apply(shown)


func reset_motion(world_position: Vector2) -> void:
	set_reference_pose("idle", 0.0)
	prior_position = world_position
	position_ready = true


func _apply(pose: Dictionary) -> void:
	if skeleton == null: return
	# Global pose setter computes the matching parent-local pose. The relative
	# native bind delta preserves imported glTF bone-axis conventions.
	for index in skeleton.get_bone_count():
		var name: String = skeleton.get_bone_name(index)
		if not pose.has(name): continue
		var native: Transform3D = pose[name]
		native.origin -= root_native
		var delta: Transform3D = native * Transform3D(rest[name]).affine_inverse()
		skeleton.set_bone_global_pose(index, mapping * delta * mapping_inverse * Transform3D(imported_rest[name]))


func advance(delta: float, world_position: Vector2, next_state: String, mining_progress: float = 0.0, cycle: float = .68, hit: float = .42) -> void:
	if bool(data.get("reference_only", false)):
		push_error("Flow20 reference payload has no approved runtime transition solver")
		return
	if not position_ready: reset_motion(world_position)
	var displacement: Vector2 = world_position - prior_position
	prior_position = world_position
	var travelled: float = displacement.length()
	root_native += ground_vector * displacement.x
	var root_velocity: Vector3 = ground_vector * displacement.x / maxf(delta, .000001)
	var changed: bool = next_state != state
	if changed:
		if next_state == "walk":
			# Short interruptions preserve travelled gait distance. Restarting the
			# same support foot for every input burst can drag a planted foot while
			# the authoritative controller keeps advancing.
			if since_walk >= .20:
				gait_phase = float(data.flat_entry_phase) + (.5 if plants.has("L") and not plants.has("R") else 0.0)
			release_phase = -1.0
		elif next_state != "walk" and state == "walk":
			var destination: Dictionary = sample(next_state, 0.0)
			for side in SIDES:
				if plants.has(side):
					var foot: Transform3D = shown["foot." + side]
					var current_roll: float = _foot_roll(foot, side)
					var settled: Vector3 = foot.origin + heading * Vector3(0, -_roll_distance(current_roll, 0.0), 0)
					offset = settled - root_native - Transform3D(destination["foot." + side]).origin
					offset.z = 0.0
					break
		if next_state == "idle": phase = 0.0
		state = next_state
	var rate: float
	if state == "walk":
		gait_phase = fposmod(gait_phase + travelled / float(data.stride_pixels), 1.0)
		phase = gait_phase
		since_walk = 0.0
		rate = travelled / maxf(delta, .000001) / float(data.stride_pixels)
	elif state == "mine":
		phase = mining_progress / hit * .55 if mining_progress <= hit else .55 + (mining_progress-hit) / (1.0-hit) * .45
		rate = .55 / (cycle*hit) if mining_progress <= hit else .45 / (cycle*(1.0-hit))
	else:
		phase = fposmod(phase + delta / 3.6, 1.0)
		rate = 1.0 / 3.6
	if state != "walk": since_walk += delta
	if state == "walk" and not offset.is_zero_approx() and blend_elapsed >= BLEND_SECONDS:
		_release_offset()
	var wanted: Dictionary = _world_sample(state, phase, root_native + offset)
	if changed:
		var future: Dictionary = _world_sample(state, phase + rate*.0001, root_native + offset + root_velocity*.0001)
		_begin_transition(wanted, future, delta)
	var displayed: Dictionary = {}
	var u: float = clampf(blend_elapsed / BLEND_SECONDS, 0.0, 1.0)
	var value_decay: float = 1.0 - _smoother(u)
	var velocity_decay: float = u - 6.0*pow(u, 3) + 8.0*pow(u, 4) - 3.0*pow(u, 5)
	for name in rest:
		var value: Transform3D = wanted[name]
		if u < 1.0 and residuals.has(name):
			var residual: Dictionary = residuals[name]
			value.origin += Vector3(residual.position)*value_decay + Vector3(residual.velocity)*BLEND_SECONDS*velocity_decay
			var spin: Vector3 = Vector3(residual.rotation)*value_decay + Vector3(residual.angular)*BLEND_SECONDS*velocity_decay
			if spin.length_squared() > 0.0000000001: value.basis = Basis(Quaternion(spin.normalized(), spin.length())) * value.basis
		displayed[name] = value
	_constrain(displayed)
	older = shown
	shown = displayed
	_apply(shown)
	blend_elapsed += delta
	last_phase = phase


func _world_sample(mode: String, at: float, translation: Vector3) -> Dictionary:
	var result: Dictionary = sample(mode, at)
	for name in result:
		var value: Transform3D = result[name]
		value.origin += translation
		result[name] = value
	return result


func _rotation_vector(quaternion: Quaternion) -> Vector3:
	var q: Quaternion = quaternion.normalized()
	if q.w < 0.0: q = Quaternion(-q.x, -q.y, -q.z, -q.w)
	var angle: float = q.get_angle()
	return Vector3.ZERO if absf(angle) < .000001 else q.get_axis() * angle


func _begin_transition(wanted: Dictionary, future: Dictionary, delta: float) -> void:
	residuals.clear()
	for name in rest:
		var source: Transform3D = shown[name]
		var before: Transform3D = older[name]
		var target: Transform3D = wanted[name]
		var after: Transform3D = future[name]
		var source_q: Quaternion = source.basis.get_rotation_quaternion()
		var target_q: Quaternion = target.basis.get_rotation_quaternion()
		residuals[name] = {"position": source.origin - target.origin,
			"velocity": (source.origin-before.origin)/maxf(delta, .000001) - (after.origin-target.origin)/.0001,
			"rotation": _rotation_vector(source_q * target_q.inverse()),
			"angular": _rotation_vector(source_q * before.basis.get_rotation_quaternion().inverse()) / maxf(delta, .000001)
				- _rotation_vector(after.basis.get_rotation_quaternion() * target_q.inverse())/.0001}
	blend_elapsed = 0.0
	transitions += 1


func _smoother(u: float) -> float:
	u = clampf(u, 0.0, 1.0)
	return u*u*u*(10.0 + u*(-15.0 + 6.0*u))


func _release_offset() -> void:
	var support_end: float = 16.0 / 88.0
	for start in [support_end, .5 + support_end]:
		if last_phase <= start and phase > start:
			release_phase = start
			release_offset = offset
	if release_phase < 0.0: return
	var end: float = .5 if release_phase < .5 else 1.0
	var at: float = phase + (1.0 if phase < release_phase else 0.0)
	offset = release_offset * (1.0-_smoother((at-release_phase)/(end-release_phase)))
	if at >= end:
		offset = Vector3.ZERO
		release_phase = -1.0


func _foot_roll(foot: Transform3D, side: String) -> float:
	var local: Basis = heading.transposed() * foot.basis * Transform3D(rest["foot."+side]).basis.inverse()
	return atan2(local.y.z, local.y.y)


func _sole_height(angle: float) -> float:
	var minimum: float = INF
	for point in Array(data.boot_hull): minimum = minf(minimum, float(point[0])*sin(angle) + float(point[1])*cos(angle))
	return float(data.ground) - minimum


func _roll_distance(a: float, b: float) -> float:
	if is_equal_approx(a, b): return 0.0
	var lo: float = minf(a, b)
	var hi: float = maxf(a, b)
	var cuts: Array[float] = [lo, hi]
	var hull: Array = data.boot_hull
	for index in hull.size():
		var first: Array = hull[index]
		var second: Array = hull[(index+1) % hull.size()]
		var angle: float = atan2(-(float(second[1])-float(first[1])), float(second[0])-float(first[0]))
		for turn in range(-3, 4):
			var cut: float = angle + float(turn)*PI
			if lo < cut and cut < hi: cuts.append(cut)
	cuts.sort()
	var total: float = 0.0
	for index in range(cuts.size()-1):
		var start: float = cuts[index]
		var end: float = cuts[index+1]
		var midpoint: float = (start+end)*.5
		var vertex: Vector2
		var height: float = INF
		for point in hull:
			var y: float = float(point[0])
			var z: float = float(point[1])
			var value: float = y*sin(midpoint)+z*cos(midpoint)
			if value < height:
				height = value
				vertex = Vector2(y, z)
		total += vertex.x*(cos(end)-cos(start))-vertex.y*(sin(end)-sin(start))
	return total if b > a else -total


func _constrain(pose: Dictionary) -> void:
	var expected: Dictionary = {"R": true, "L": true}
	if state == "walk":
		expected = {"R": phase < 16.0/88.0, "L": phase >= .5 and phase < .5+16.0/88.0}
	var lower_body: float = 0.0
	for side in SIDES:
		var foot_name: String = "foot." + side
		var foot: Transform3D = pose[foot_name]
		var angle: float = _foot_roll(foot, side)
		var support: float = _sole_height(angle)
		if not expected[side]: plants.erase(side)
		if bool(expected[side]) and not plants.has(side) and foot.origin.z <= support + .008:
			plants[side] = {"ankle": foot.origin, "roll": angle}
		if plants.has(side):
			var previous: Dictionary = plants[side]
			foot.origin = Vector3(previous.ankle) + heading * Vector3(0, -_roll_distance(float(previous.roll), angle), 0)
			foot.origin.z = support
			plants[side] = {"ankle": foot.origin, "roll": angle}
		else:
			foot.origin.z = maxf(foot.origin.z, support)
		var hip: Vector3 = Transform3D(pose["thigh."+side]).origin
		if not plants.has(side) and hip.distance_to(foot.origin) > .3638:
			# A free ankle can be retargeted to the actual leg's reach sphere.
			# Planted contacts never use this projection or slide with the root.
			var reachable: Vector3 = hip + (foot.origin-hip).normalized()*.3638
			reachable.z = maxf(reachable.z, support)
			maximum_air_retarget = maxf(maximum_air_retarget, reachable.distance_to(foot.origin))
			foot.origin = reachable
		pose[foot_name] = foot
		var horizontal: float = Vector2(hip.x-foot.origin.x, hip.y-foot.origin.y).length()
		if horizontal < .3638:
			lower_body = minf(lower_body, foot.origin.z + sqrt(.3638*.3638-horizontal*horizontal) - hip.z)
	maximum_reach_correction = maxf(maximum_reach_correction, -lower_body)
	if lower_body < 0.0:
		for name in pose:
			if String(name).begins_with("foot.") or String(name).begins_with("shin."): continue
			var value: Transform3D = pose[name]
			value.origin.z += lower_body
			pose[name] = value
	for side in SIDES:
		var hip: Vector3 = Transform3D(pose["thigh."+side]).origin
		var ankle: Vector3 = Transform3D(pose["foot."+side]).origin
		var pole: Vector3 = Transform3D(pose["shin."+side]).origin
		var knee: Vector3 = _solve(hip, ankle, pole, .180, .184, "leg."+side)
		pose["thigh."+side] = _segment("thigh."+side, hip, knee)
		pose["shin."+side] = _segment("shin."+side, knee, ankle)
	for side in SIDES:
		var hand: Transform3D = Transform3D(pose.tool) * Transform3D(hand_local[side])
		var shoulder: Vector3 = Transform3D(pose.body) * Vector3(shoulder_local[side])
		var pole: Vector3 = Transform3D(pose["lower."+side]).origin
		var elbow: Vector3 = _solve(shoulder, hand.origin, pole, .36, .35, "arm."+side)
		pose["upper."+side] = _segment("upper."+side, shoulder, elbow)
		pose["lower."+side] = _segment("lower."+side, elbow, hand.origin)
		pose["hand."+side] = hand


func _solve(a: Vector3, c: Vector3, pole: Vector3, upper: float, lower: float, limb: String) -> Vector3:
	var distance: float = a.distance_to(c)
	var excess: float = maxf(distance-(upper+lower), absf(upper-lower)-distance)
	if excess > maximum_unreachable:
		maximum_unreachable = excess
		reach_detail = {"limb": limb, "state": state, "phase": phase, "blend_elapsed": blend_elapsed,
			"start": [a.x, a.y, a.z], "end": [c.x, c.y, c.z], "distance": distance}
	var safe_distance: float = clampf(distance, absf(upper-lower)+.00001, upper+lower-.00001)
	var axis: Vector3 = (c-a).normalized()
	var radial: Vector3 = pole-a
	radial = (radial-axis*axis.dot(radial)).normalized()
	if radial.length_squared() < .1: radial = axis.cross(Vector3.RIGHT).normalized()
	var along: float = (upper*upper-lower*lower+safe_distance*safe_distance)/(2.0*safe_distance)
	return a + axis*along + radial*sqrt(maxf(0.0, upper*upper-along*along))


func _segment(name: String, a: Vector3, b: Vector3) -> Transform3D:
	var original: Transform3D = rest[name]
	var before: Vector3 = _vector(data.tails[name])-original.origin
	var rotate: Basis = Basis(Quaternion(before.normalized(), (b-a).normalized()))
	return Transform3D(rotate * original.basis, a)


func snapshot() -> Dictionary:
	var result: Dictionary = {"state": state, "phase": phase, "transitions": transitions,
		"blend_elapsed": blend_elapsed, "visual_offset_native": [offset.x, offset.y, offset.z],
		"reach_correction_max": maximum_reach_correction, "unreachable_max": maximum_unreachable,
		"airborne_retarget_max": maximum_air_retarget,
		"reach_detail": reach_detail, "contacts": plants.keys(), "bones": {}}
	for name in ["body", "tool", "foot.R", "foot.L"]:
		var value: Transform3D = shown[name]
		result.bones[name] = [value.origin.x, value.origin.y, value.origin.z]
	return result
