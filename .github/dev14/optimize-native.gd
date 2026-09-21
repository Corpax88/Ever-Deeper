extends SceneTree
## Build-time indexed LOD from the approved mesh; retain all selected attributes.
## Skeleton, skin, textures, camera, lighting and animation are unchanged.
const LOD: int = 2
var source_vertices: int = 0
var source_triangles: int = 0
var vertices: int = 0
var triangles: int = 0
var maximum_error: float = 0.0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var folder: String = args[0] if not args.is_empty() else "res://assets/native-worn"
	var output: String = args[1] if args.size() > 1 else folder.path_join("worn-runtime.scn")
	var receipt: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder.path_join("runtime-scene.json")))
	if not _require(bool(receipt.get("geometry_and_bindings_identical",false)), "Optimization requires the verified original scene"): return
	var scene_path: String = folder.path_join("worn-runtime.scn")
	if not _require(FileAccess.get_sha256(scene_path) == receipt.scene_sha256, "Prepared source identity changed"): return
	var actor: Node3D = load(scene_path).instantiate()
	root.add_child(actor)
	var bindings: String = _bindings(actor)
	_optimize(actor)
	if not _require(source_vertices == 1033415 and triangles < 100000, "Unexpected source or reduction"): return
	if not _require(_bindings(actor) == bindings, "Optimization changed skeleton or skin"): return
	var packed := PackedScene.new()
	if not _require(packed.pack(actor) == OK, "Could not pack optimized actor"): return
	if not _require(ResourceSaver.save(packed,output,ResourceSaver.FLAG_COMPRESS) == OK, "Could not save optimized actor"): return
	var check: Node3D = ResourceLoader.load(output,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
	if not _require(_bindings(check) == bindings, "Saved skeleton or skin changed"): return
	receipt.original_scene_sha256 = receipt.scene_sha256
	receipt.scene_sha256 = FileAccess.get_sha256(output)
	receipt.scene_bytes = FileAccess.get_file_as_bytes(output).size()
	receipt.geometry_and_bindings_identical = false
	receipt.animation_and_bindings_preserved = true
	receipt.optimization = {"method":"godot-importer-indexed-lod", "lod":LOD,
		"source_vertices":source_vertices,"source_triangles":source_triangles,
		"vertices":vertices,"triangles":triangles,"maximum_error":maximum_error,
		"bindings_sha256":bindings,"vertex_attributes_preserved":true}
	var file := FileAccess.open(output.get_base_dir().path_join("runtime-scene.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt,"\t"))
	file.close()
	check.free()
	print("NATIVE_LOD_COMPLETE ",JSON.stringify(receipt.optimization))
	quit(0)

func _optimize(node: Node) -> void:
	if node is MeshInstance3D:
		var source: Mesh = node.mesh
		var importer := ImporterMesh.new()
		for surface in source.get_surface_count():
			assert(source.get_blend_shape_count() == 0)
			importer.add_surface(source.surface_get_primitive_type(surface),source.surface_get_arrays(surface))
		importer.generate_lods(25.0,60.0,[])
		var mesh := ArrayMesh.new()
		for surface in importer.get_surface_count():
			var original: Array = source.surface_get_arrays(surface)
			var arrays: Array = importer.get_surface_arrays(surface)
			# Godot may derive split normals while generating LODs. Require the
			# complete original attribute arrays before selecting original vertices.
			assert(var_to_bytes(original) == var_to_bytes(arrays))
			var count: int = arrays[Mesh.ARRAY_VERTEX].size()
			source_vertices += count
			source_triangles += arrays[Mesh.ARRAY_INDEX].size()/3
			assert(importer.get_surface_lod_count(surface) > LOD)
			var indices: PackedInt32Array = importer.get_surface_lod_indices(surface,LOD)
			maximum_error = maxf(maximum_error,importer.get_surface_lod_size(surface,LOD))
			var selected := PackedInt32Array()
			var remap: Dictionary = {}
			var compact_indices := PackedInt32Array()
			for index in indices:
				if not remap.has(index):
					remap[index] = selected.size()
					selected.append(index)
				compact_indices.append(remap[index])
			var compact: Array = []
			compact.resize(Mesh.ARRAY_MAX)
			for slot in Mesh.ARRAY_INDEX:
				if arrays[slot] == null or arrays[slot].is_empty(): continue
				var stride: int = arrays[slot].size()/count
				assert(stride > 0 and arrays[slot].size() == count*stride)
				var values: Variant = arrays[slot].duplicate()
				values.resize(selected.size()*stride)
				for j in selected.size():
					for k in stride: values[j*stride+k] = arrays[slot][selected[j]*stride+k]
				compact[slot] = values
			compact[Mesh.ARRAY_INDEX] = compact_indices
			mesh.add_surface_from_arrays(source.surface_get_primitive_type(surface),compact,[],{},source.surface_get_format(surface))
			vertices += selected.size()
			triangles += indices.size()/3
		node.mesh = mesh
	for child in node.get_children(): _optimize(child)

func _bindings(actor: Node) -> String:
	var rows: Array = []
	_visit(actor,actor,rows)
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(var_to_bytes(rows))
	return hashing.finish().hex_encode()

func _visit(node: Node, actor: Node, rows: Array) -> void:
	var row: Array = [String(actor.get_path_to(node)),node.get_class()]
	if node is Node3D: row.append(node.transform)
	if node is Skeleton3D:
		for i in node.get_bone_count(): row.append([node.get_bone_name(i),node.get_bone_parent(i),node.get_bone_rest(i)])
	if node is MeshInstance3D:
		row.append(String(node.skeleton))
		if node.skin != null:
			for i in node.skin.get_bind_count(): row.append([node.skin.get_bind_bone(i),node.skin.get_bind_name(i),node.skin.get_bind_pose(i)])
	rows.append(row)
	for child in node.get_children(): _visit(child,actor,rows)

func _require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(2)
	return condition
