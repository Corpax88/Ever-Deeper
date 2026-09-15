from pathlib import Path
p=Path('scripts/world/cave_edge_asset_drawer.gd');s=p.read_text()
s=s.replace('static var _corner_meshes: Dictionary = {}','static var _corner_meshes: Dictionary = {}\nstatic var _edge_meshes: Dictionary = {}\nstatic var _mass_meshes: Dictionary = {}')
# Public edge signatures and forwarding only.
a=s.index('static func draw_mineable_edge');b=s.index('static func draw_mineable_corner',a)
z=s[a:b].replace('modulate: Color = Color.WHITE\n','modulate: Color = Color.WHITE,\n\topen_mask: int = 0\n').replace('\t\tmodulate\n','\t\tmodulate,\n\t\topen_mask\n');s=s[:a]+z+s[b:]
a=s.index('static func _draw_edge');b=s.index('static func _draw_corner',a)
z=s[a:b].replace('modulate: Color\n','modulate: Color,\n\topen_mask: int\n')
z=z.replace('''	canvas.draw_texture_rect_region(texture, destination, source, modulate)
''','''	var join_flags: int = 0
	if open_mask & (1 << ((side + 1) % 4)): join_flags |= 1
	if open_mask & (1 << ((side + 3) % 4)): join_flags |= 2
	if join_flags == 0:
		canvas.draw_texture_rect_region(texture, destination, source, modulate)
	else:
		if not _edge_meshes.has(texture): _edge_meshes[texture] = {}
		var meshes: Dictionary = _edge_meshes[texture]
		var key: = Vector3i(roundi(tile_size), segment, join_flags)
		if not meshes.has(key):
			meshes[key] = _make_edge_mesh(destination, source, Vector2(texture.get_size()), join_flags)
		canvas.draw_mesh(meshes[key], texture, Transform2D.IDENTITY, modulate)
''');s=s[:a]+z+s[b:]
addition='''static func sides_mask(sides: Array) -> int:
	return int(bool(sides[0])) | (int(bool(sides[1])) << 1) | (int(bool(sides[2])) << 2) | (int(bool(sides[3])) << 3)


static func corner_mask(open_mask: int) -> int:
	var result: int = 0
	for corner in 4:
		if open_mask & (1 << corner) and open_mask & (1 << ((corner + 1) % 4)):
			result |= 1 << corner
	return result


static func draw_wall_mass(canvas: CanvasItem, texture: Texture2D, destination: Rect2, source: Rect2, modulate: Color, open_mask: int) -> void:
	var corners: int = corner_mask(open_mask)
	if corners == 0:
		canvas.draw_texture_rect_region(texture, destination, source, modulate)
		return
	if not _mass_meshes.has(texture): _mass_meshes[texture] = {}
	var texture_meshes: Dictionary = _mass_meshes[texture]
	if not texture_meshes.has(source): texture_meshes[source] = {}
	var meshes: Dictionary = texture_meshes[source]
	if not meshes.has(corners):
		meshes[corners] = _make_mass_mesh(source, Vector2(texture.get_size()), corners)
	var transform: = Transform2D(Vector2(destination.size.x, 0.0), Vector2(0.0, destination.size.y), destination.position)
	canvas.draw_mesh(meshes[corners], texture, transform, modulate)


static func _make_edge_mesh(destination: Rect2, source: Rect2, texture_size: Vector2, join_flags: int) -> ArrayMesh:
	var xs: PackedFloat32Array = PackedFloat32Array([0.0, 0.32, 0.68, 1.0])
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	for y in 2:
		for x in 4:
			var position: = Vector2(xs[x], float(y))
			var local: Vector2 = destination.position + position * destination.size
			vertices.append(Vector3(local.x, local.y, 0.0))
			uvs.append((source.position + position * source.size) / texture_size)
			var fade: bool = (x == 0 and join_flags & 1) or (x == 3 and join_flags & 2)
			colors.append(Color(1.0, 1.0, 1.0, 0.0 if fade else 1.0))
	for x in 3:
		indices.append_array(PackedInt32Array([x, x + 1, x + 4, x + 1, x + 5, x + 4]))
	return _mesh_from_arrays(vertices, uvs, colors, indices)


static func _make_mass_mesh(source: Rect2, texture_size: Vector2, corners: int) -> ArrayMesh:
	# This only clips the underlying production rock texture beneath the authored
	# rounded bend. It does not generate replacement terrain art or alter collision.
	var radius: float = 0.38
	var centers: Array[Vector2] = [Vector2(1.0-radius, radius), Vector2(1.0-radius, 1.0-radius), Vector2(radius, 1.0-radius), Vector2(radius, radius)]
	var square_corners: Array[Vector2] = [Vector2(1,0), Vector2(1,1), Vector2(0,1), Vector2(0,0)]
	var points: PackedVector2Array = PackedVector2Array()
	for corner in 4:
		if not corners & (1 << corner):
			points.append(square_corners[corner])
			continue
		for step in 5:
			var angle: float = (float(corner) - 1.0) * PI * 0.5 + float(step) * PI * 0.125
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	for point in points:
		vertices.append(Vector3(point.x, point.y, 0.0))
		uvs.append((source.position + point * source.size) / texture_size)
		colors.append(Color.WHITE)
	return _mesh_from_arrays(vertices, uvs, colors, Geometry2D.triangulate_polygon(points))


static func _mesh_from_arrays(vertices: PackedVector3Array, uvs: PackedVector2Array, colors: PackedColorArray, indices: PackedInt32Array) -> ArrayMesh:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


'''
s=s.replace('static func _edge_midpoint',addition+'static func _edge_midpoint')
# Reuse array-building code in corner implementation.
a=s.index('\tvar arrays: Array = []',s.index('static func _make_corner_mesh'));b=s.index('\n\nstatic func sides_mask',a)
s=s[:a]+'\treturn _mesh_from_arrays(vertices, uvs, colors, indices)\n'+s[b:]
p.write_text(s)

p=Path('scripts/world/mossvein_mine.gd');s=p.read_text()
s=s.replace('regions.append(Rect2(Vector2(run_start, row) * TILE_SIZE, Vector2(col - run_start, 1) * TILE_SIZE))','regions.append(Rect2(Vector2(run_start, row) * TILE_SIZE, Vector2(col - run_start, 1) * TILE_SIZE).grow(TILE_SIZE * 0.16))')
s=s.replace('''		_draw_canvas.draw_texture_rect_region(ROCK_MASS,rect,region,tint)
	if bedrock:''','''		CaveEdgeAssetDrawer.draw_wall_mass(_draw_canvas, ROCK_MASS, rect, region, tint, CaveEdgeAssetDrawer.sides_mask(open_sides))
	if bedrock:''')
s=s.replace('''	for side in 4:
		if bool(open_sides[side]):
			_draw_natural_wall_face(cell, side)''','''	var open_mask: int = CaveEdgeAssetDrawer.sides_mask(open_sides)
	for side in 4:
		if bool(open_sides[side]):
			_draw_natural_wall_face(cell, side, open_mask)''')
s=s.replace('func _draw_natural_wall_face(cell: Vector2i, side: int) -> void :','func _draw_natural_wall_face(cell: Vector2i, side: int, open_mask: int) -> void :')
s=s.replace('_draw_canvas, wall_texture, cell, side, TILE_SIZE, absi(mine_id.hash()) % 11','_draw_canvas, wall_texture, cell, side, TILE_SIZE, absi(mine_id.hash()) % 11, Color.WHITE, open_mask')
s=s.replace('''	var sides: Array[bool] = _mineable_edge_open_sides(cell)
	for side in 4:''','''	var sides: Array[bool] = _mineable_edge_open_sides(cell)
	var open_mask: int = CaveEdgeAssetDrawer.sides_mask(sides)
	for side in 4:''')
s=s.replace('_draw_canvas, bedrock_edge_texture, cell, side, TILE_SIZE, absi(mine_id.hash()) % 11)','_draw_canvas, bedrock_edge_texture, cell, side, TILE_SIZE, absi(mine_id.hash()) % 11, Color.WHITE, open_mask)')
p.write_text(s)

p=Path('scripts/world/endless_descent_world.gd');s=p.read_text()
s=s.replace('''	_draw_canvas.draw_texture_rect_region(texture,rect.grow(0.5),region,tint)
	if _cell_diggable''','''	var open_mask: int = int(_is_floor(cell + Vector2i.UP)) | (int(_is_floor(cell + Vector2i.RIGHT)) << 1) | (int(_is_floor(cell + Vector2i.DOWN)) << 2) | (int(_is_floor(cell + Vector2i.LEFT)) << 3)
	if CaveEdgeAssetDrawer.corner_mask(open_mask) != 0:
		_draw_floor_cell(cell, rect)
	CaveEdgeAssetDrawer.draw_wall_mass(_draw_canvas, texture, rect.grow(0.5), region, tint, open_mask)
	if _cell_diggable''')
s=s.replace('''	for side in 4:
		if bool(open_sides[side]):
			_draw_permanent_wall_face(cell, rect, side)''','''	var open_mask: int = CaveEdgeAssetDrawer.sides_mask(open_sides)
	for side in 4:
		if bool(open_sides[side]):
			_draw_permanent_wall_face(cell, rect, side, open_mask)''')
s=s.replace('func _draw_permanent_wall_face(cell: Vector2i, rect: Rect2, side: int) -> void :','func _draw_permanent_wall_face(cell: Vector2i, rect: Rect2, side: int, open_mask: int) -> void :')
s=s.replace('_draw_canvas, diggable_wall_texture, cell, side, TILE_SIZE, depth_at_position(_cell_center(cell)) % 11)','_draw_canvas, diggable_wall_texture, cell, side, TILE_SIZE, depth_at_position(_cell_center(cell)) % 11, Color.WHITE, open_mask)')
s=s.replace('_draw_canvas, cave_wall_texture, cell, side, TILE_SIZE, depth_at_position(_cell_center(cell)) % 11\n','_draw_canvas, cave_wall_texture, cell, side, TILE_SIZE, depth_at_position(_cell_center(cell)) % 11, Color.WHITE, open_mask\n')
p.write_text(s)

p=Path('scripts/world/depth/rootwound_world.gd');s=p.read_text()
a=s.index('func _draw_terrain_edge_details');b=s.index('func _',a+8)
z=s[a:b].replace('''	for side in 4:''','''	var open_mask: int = CaveEdgeAssetDrawer.sides_mask(open_sides)
	for side in 4:''',1).replace('''				absi(mine_id.hash()) % 11
''','''				absi(mine_id.hash()) % 11,
				Color.WHITE,
				open_mask
''');s=s[:a]+z+s[b:]
a=s.index('func _draw_terrain_top');b=s.index('func _terrain_texture_region',a)
z=s[a:b].replace('''	_draw_canvas.draw_texture_rect_region(ROCK_MASS,rect,region,tint)''','''	var open_mask: int = int(not _visual_is_solid(cell + Vector2i.UP)) | (int(not _visual_is_solid(cell + Vector2i.RIGHT)) << 1) | (int(not _visual_is_solid(cell + Vector2i.DOWN)) << 2) | (int(not _visual_is_solid(cell + Vector2i.LEFT)) << 3)
	CaveEdgeAssetDrawer.draw_wall_mass(_draw_canvas, ROCK_MASS, rect, region, tint, open_mask)''');s=s[:a]+z+s[b:]
p.write_text(s)
