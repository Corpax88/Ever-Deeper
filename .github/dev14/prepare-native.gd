extends SceneTree
## Prepare the unchanged approved mesh before export; avoid runtime GLTF expansion.

func _init() -> void:
	call_deferred("_prepare")

func _prepare() -> void:
	var folder: String = "res://assets/native-worn"
	var source: String = folder.path_join("worn-native-runtime.glb.raw")
	var output: String = folder.path_join("worn-runtime.scn")
	var candidate: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("candidate.json")))
	var source_sha: String = FileAccess.get_sha256(source)
	if not _require(source_sha == String(candidate.files["worn-native-runtime.glb"]), "Approved mesh identity changed"): return
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	if not _require(document.append_from_buffer(FileAccess.get_file_as_bytes(source), folder, state, 0) == OK, "GLTF preparation failed"): return
	var actor: Node3D = document.generate_scene(state) as Node3D
	if not _require(actor != null, "Approved GLTF did not create an actor"): return
	root.add_child(actor)
	var before: Dictionary = _fingerprint(actor)
	if not _require(int(before.vertices) == 1033415, "Unexpected approved geometry"): return
	# Runtime always overrides every mesh material. Omit those unused embedded
	# textures; authored albedo/normal/ORM/response/cloth remain runtime inputs.
	_prepare_ownership(actor, actor)
	var packed := PackedScene.new()
	if not _require(packed.pack(actor) == OK, "Could not pack approved actor"): return
	if not _require(ResourceSaver.save(packed, output, ResourceSaver.FLAG_COMPRESS) == OK, "Could not save prepared actor"): return
	var loaded := ResourceLoader.load(output, "PackedScene", ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
	if not _require(loaded != null, "Prepared scene could not be read"): return
	var check: Node3D = loaded.instantiate() as Node3D
	root.add_child(check)
	var after: Dictionary = _fingerprint(check)
	if not _require(before == after, "Prepared geometry, transforms, skeleton or skin changed"): return
	var receipt: Dictionary = {"status":"complete", "source_sha256":source_sha,
		"scene_sha256":FileAccess.get_sha256(output), "import_flags":0,
		"source_bytes":FileAccess.get_file_as_bytes(source).size(),
		"scene_bytes":FileAccess.get_file_as_bytes(output).size(),
		"source_fingerprint":before, "prepared_fingerprint":after,
		"geometry_and_bindings_identical":true, "overridden_embedded_materials_omitted":true}
	var file := FileAccess.open(folder.path_join("runtime-scene.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "\t"))
	file.close()
	print("NATIVE_SCENE_PREPARED vertices=", before.vertices, " identical=true source_bytes=", receipt.source_bytes, " scene_bytes=", receipt.scene_bytes)
	quit(0)

func _prepare_ownership(node: Node, actor: Node) -> void:
	if node != actor: node.owner = actor
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		for index in instance.mesh.get_surface_count():
			instance.mesh.surface_set_material(index, null)
	for child in node.get_children(): _prepare_ownership(child, actor)

func _fingerprint(actor: Node) -> Dictionary:
	var result: Dictionary = {"vertices":0, "nodes":[]}
	_visit(actor, actor, result)
	return result

func _visit(node: Node, actor: Node, result: Dictionary) -> void:
	var row: Dictionary = {"path":String(actor.get_path_to(node)), "type":node.get_class()}
	if node is Node3D: row.transform = _hash((node as Node3D).transform)
	if node is Skeleton3D:
		var skeleton := node as Skeleton3D
		row.bones = []
		for index in skeleton.get_bone_count():
			row.bones.append([skeleton.get_bone_name(index), skeleton.get_bone_parent(index), _hash(skeleton.get_bone_rest(index))])
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		row.skeleton_path = String(instance.skeleton)
		row.surfaces = []
		for index in instance.mesh.get_surface_count():
			var arrays: Array = instance.mesh.surface_get_arrays(index)
			var hashing := HashingContext.new()
			hashing.start(HashingContext.HASH_SHA256)
			hashing.update(var_to_bytes(arrays))
			row.surfaces.append({"arrays_sha256":hashing.finish().hex_encode(), "primitive":instance.mesh.surface_get_primitive_type(index)})
			result.vertices += arrays[Mesh.ARRAY_VERTEX].size()
		row.binds = []
		if instance.skin != null:
			for index in instance.skin.get_bind_count():
				row.binds.append([instance.skin.get_bind_bone(index), String(instance.skin.get_bind_name(index)), _hash(instance.skin.get_bind_pose(index))])
	result.nodes.append(row)
	for child in node.get_children(): _visit(child, actor, result)

func _hash(value: Variant) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(var_to_bytes(value))
	return hashing.finish().hex_encode()

func _require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(2)
	return condition
