extends RefCounted
## Original upgraded tool meshes follow the approved rigid tool bone.
const GEARS: Array[String] = ["worn", "iron", "runed", "moonglass", "ember", "crusher", "comet", "crown"]
const ASSETS: String = "res://assets/native-pickaxes"
var rig: Node
var hero_mesh: MeshInstance3D
var original_mesh: Mesh
var body_mesh: Mesh
var tool: Node3D
var current: String = "worn"
var manifest: Dictionary = {}
var loaded_scenes: Dictionary = {}
var verified: bool = false

func setup(native_rig: Node) -> void:
	rig = native_rig

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.skin != null: return node as MeshInstance3D
	for child in node.get_children():
		var found: MeshInstance3D = _find_mesh(child)
		if found != null: return found
	return null

func _initialize() -> bool:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ASSETS.path_join("runtime-manifest.json")))
	if not parsed is Dictionary or int(parsed.get("schema",0)) != 1: return false
	manifest = parsed
	if FileAccess.get_sha256("res://assets/native-worn/worn-runtime.scn") != String(manifest.body.source_scene_sha256): return false
	var body_path: String = ASSETS.path_join(String(manifest.body.file))
	if FileAccess.get_sha256(body_path) != String(manifest.body.sha256): return false
	hero_mesh = _find_mesh(rig.viewport)
	if hero_mesh == null: return false
	original_mesh = hero_mesh.mesh
	body_mesh = load(body_path) as Mesh
	verified = body_mesh != null
	return verified

func equip(gear: String) -> bool:
	if gear not in GEARS: return false
	if gear == current: return true
	if not verified and not _initialize(): return false
	var next: Node3D
	if gear != "worn":
		if not manifest.tools.has(gear): return false
		var row: Dictionary = manifest.tools[gear]
		var path: String = ASSETS.path_join(String(row.file))
		if not loaded_scenes.has(gear):
			if FileAccess.get_sha256(path) != String(row.sha256): return false
			var packed: PackedScene = load(path) as PackedScene
			if packed == null: return false
			loaded_scenes.clear()
			loaded_scenes[gear] = packed
		next = loaded_scenes[gear].instantiate() as Node3D
		if next == null: return false
	if is_instance_valid(tool): tool.free()
	hero_mesh.mesh = original_mesh if gear == "worn" else body_mesh
	tool = next
	if tool != null: rig.viewport.add_child(tool)
	current = gear
	apply_pose()
	return true

func contact_cap(default_cap: Vector3) -> Vector3:
	return default_cap if current == "worn" else rig._vector(manifest.tools[current].tool_cap_local)

func apply_pose() -> void:
	if not is_instance_valid(tool): return
	var pose: Transform3D = rig.shown.tool
	pose.origin -= rig.root_native
	tool.transform = rig.AXIS * pose * rig.AXIS.affine_inverse()
