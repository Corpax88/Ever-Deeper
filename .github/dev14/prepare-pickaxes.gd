extends SceneTree
## Remove only the rigid original tool; retain every other vertex attribute.
const FOLDER: String = "res://assets/native-pickaxes"
const SOURCE: String = "res://assets/native-worn/worn-runtime.scn"
var removed: int = 0
var retained: int = 0

func _init() -> void:
	call_deferred("_run")

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D and node.skin != null: return node
	for child in node.get_children():
		var found: MeshInstance3D = _find_mesh(child)
		if found != null: return found
	return null

func _run() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FOLDER.path_join("source-manifest.json")))
	var actor: Node3D = load(SOURCE).instantiate()
	var instance: MeshInstance3D = _find_mesh(actor)
	if not _require(instance != null,"Missing native skinned mesh"): return
	var bind: int = -1
	for i in instance.skin.get_bind_count():
		if instance.skin.get_bind_name(i) == &"tool":
			if not _require(bind == -1,"Duplicate tool binding"): return
			bind = i
	if not _require(bind >= 0,"Missing tool binding"): return
	var body := ArrayMesh.new()
	for surface in instance.mesh.get_surface_count():
		var arrays: Array = instance.mesh.surface_get_arrays(surface)
		var before: Array = arrays.duplicate(true)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var count: int = arrays[Mesh.ARRAY_VERTEX].size()
		var stride: int = bones.size()/count
		var rigid := PackedByteArray(); rigid.resize(count)
		for i in count:
			var weight: float = 0.0
			for j in stride:
				if bones[i*stride+j] == bind: weight += weights[i*stride+j]
			if not _require(weight < .00001 or weight > .99999,"Tool blended with hero body"): return
			rigid[i] = 1 if weight > .99999 else 0
		var original: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var indices := PackedInt32Array()
		for i in range(0,original.size(),3):
			var total: int = rigid[original[i]]+rigid[original[i+1]]+rigid[original[i+2]]
			if not _require(total == 0 or total == 3,"Triangle crosses tool/body boundary"): return
			if total == 3: removed += 1
			else:
				indices.append_array(original.slice(i,i+3)); retained += 1
		arrays[Mesh.ARRAY_INDEX] = indices
		for slot in Mesh.ARRAY_INDEX:
			if not _require(var_to_bytes(arrays[slot]) == var_to_bytes(before[slot]),"Body vertex attributes changed"): return
		body.add_surface_from_arrays(instance.mesh.surface_get_primitive_type(surface),arrays,[],{},instance.mesh.surface_get_format(surface))
	if not _require(removed == 2256 and retained == 84397,"Unexpected body/tool triangle counts"): return
	var body_path: String = FOLDER.path_join("body-only.res")
	if not _require(ResourceSaver.save(body,body_path,ResourceSaver.FLAG_COMPRESS) == OK,"Could not save original body"): return
	var receipt: Dictionary = {"schema":1,"body":{"file":"body-only.res","sha256":FileAccess.get_sha256(body_path),"source_scene_sha256":FileAccess.get_sha256(SOURCE),"removed_tool_triangles":removed,"retained_triangles":retained,"vertex_attributes_unchanged":true},"tools":{},"source_manifest_sha256":FileAccess.get_sha256(FOLDER.path_join("source-manifest.json"))}
	for gear in ["iron","runed","moonglass","ember","crusher","comet","crown"]:
		var row: Dictionary = source.tools[gear]
		var path: String = FOLDER.path_join(row.file)
		if not _require(FileAccess.get_sha256(path) == String(row.sha256),"Original tool hash mismatch: "+gear): return
		var doc := GLTFDocument.new(); var state := GLTFState.new()
		if not _require(doc.append_from_buffer(FileAccess.get_file_as_bytes(path),FOLDER,state,0) == OK,"Could not import "+gear): return
		var tool: Node3D = doc.generate_scene(state)
		if not _require(tool != null,"Missing imported tool"): return
		_ownership(tool,tool)
		var packed := PackedScene.new()
		if not _require(packed.pack(tool) == OK,"Could not pack "+gear): return
		var target: String = FOLDER.path_join(gear+".scn")
		if not _require(ResourceSaver.save(packed,target,ResourceSaver.FLAG_COMPRESS) == OK,"Could not save "+gear): return
		receipt.tools[gear] = {"file":gear+".scn","sha256":FileAccess.get_sha256(target),"tool_cap_local":row.tool_cap_local,"source_sha256":row.sha256}
		tool.free()
	var file := FileAccess.open(FOLDER.path_join("runtime-manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt,"\t"));file.close()
	actor.free()
	print("NATIVE_PICKAXES_PREPARED ",JSON.stringify(receipt.body))
	quit(0)

func _ownership(node: Node, actor: Node) -> void:
	if node != actor: node.owner = actor
	for child in node.get_children(): _ownership(child,actor)

func _require(condition: bool,message: String) -> bool:
	if not condition:
		push_error(message)
		quit(2)
	return condition
