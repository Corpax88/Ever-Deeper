from pathlib import Path
p=Path('scripts/world/mossvein_mine.gd')
s=p.read_text().replace('var bedrock_corner_texture: Texture2D\n','var bedrock_corner_texture: Texture2D\nvar bedrock_surface_meshes: Dictionary = {}\n')
s=s.replace('bedrock_surface_texture = null','bedrock_surface_texture = null\n\tbedrock_surface_meshes.clear()')
s=s.replace('''	var base_color: = Color("10130f") if bedrock else Color(String(GameData.data.ROCK_TYPES.get(kind, {"color": mine.wall}).color))
	if role in ["terrain", "resource"]:
		base_color = Color(String(GameData.data.MINE_DIRT_COLORS.get(mine_id, mine.wall)))
	if bedrock:
		# The textured surface is emitted in the final masking pass. This quiet,
		# opaque undercoat prevents a floor-colour seam while that pass is clipped.
		_draw_canvas.draw_rect(rect, Color("111410"), true)
		return
	elif not transparent_resource_surround:''','''	if not transparent_resource_surround or bedrock:''')
s=s.replace('''		_draw_canvas.draw_texture_rect_region(ROCK_MASS,rect,region,tint)

	var seam: Texture2D''','''		_draw_canvas.draw_texture_rect_region(ROCK_MASS,rect,region,tint)
	if bedrock:
		return

	var seam: Texture2D''')
s=s.replace('''	_draw_canvas.draw_texture_rect_region(bedrock_surface_texture, destination, source, Color.WHITE)


func _bedrock_surface_source_rect''','''	var blend_mask: int = 0
	var offsets: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
	for side in 4:
		var neighbour: Vector2i = cell + offsets[side]
		if blocks.has(neighbour) and String(blocks[neighbour].get("kind", "")) != "bedrock":
			blend_mask |= 1 << side
	if blend_mask == 0:
		_draw_canvas.draw_texture_rect_region(bedrock_surface_texture, destination, source, Color.WHITE)
		return
	# Adjacent geology is a material transition within one solid mountain. Blend
	# into the same rock beneath it; an exposed floor edge stays fully opaque.
	var mesh_key: = Vector3i(cell.x, cell.y, blend_mask)
	if not bedrock_surface_meshes.has(mesh_key):
		bedrock_surface_meshes[mesh_key] = _make_bedrock_surface_mesh(destination, source, texture_size, blend_mask)
	_draw_canvas.draw_mesh(bedrock_surface_meshes[mesh_key], bedrock_surface_texture)


func _make_bedrock_surface_mesh(destination: Rect2, source: Rect2, texture_size: Vector2, blend_mask: int) -> ArrayMesh:
	var fade: float = 12.0
	var xs: PackedFloat32Array = PackedFloat32Array([0.0, fade / destination.size.x, 1.0 - fade / destination.size.x, 1.0])
	var ys: PackedFloat32Array = PackedFloat32Array([0.0, fade / destination.size.y, 1.0 - fade / destination.size.y, 1.0])
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	for y in 4:
		for x in 4:
			var position: = Vector2(xs[x], ys[y])
			var world_position: Vector2 = destination.position + position * destination.size
			vertices.append(Vector3(world_position.x, world_position.y, 0.0))
			uvs.append((source.position + position * source.size) / texture_size)
			var seam: bool = (y == 0 and blend_mask & 1) or (x == 3 and blend_mask & 2) or (y == 3 and blend_mask & 4) or (x == 0 and blend_mask & 8)
			colors.append(Color(1.0, 1.0, 1.0, 0.0 if seam else 1.0))
	for y in 3:
		for x in 3:
			var first: int = y * 4 + x
			indices.append_array(PackedInt32Array([first, first + 1, first + 4, first + 1, first + 5, first + 4]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _bedrock_surface_source_rect''')
p.write_text(s)
