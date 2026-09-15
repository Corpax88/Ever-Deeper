from pathlib import Path
p=Path('scripts/world/cave_edge_asset_drawer.gd')
s=p.read_text()
s=s.replace('const SOURCE_SEGMENT_WIDTH: = 128.0\n', '''const SOURCE_SEGMENT_WIDTH: = 128.0

# Registration measurements of the existing production PNGs: corner arm centre,
# corner arm width, and matching straight-edge alpha centre/width. The transparent
# canvas is not the stone silhouette; treating every 1024px canvas alike shifted
# Mossvein's large boulders and made the narrow crystal corners undersized.
const CORNER_REGISTRATION: = {
	"res://assets/mossvein/cave-corner-v2.png": Vector4(607.25, 409.0, 300.25, 103.0),
	"res://assets/mossvein/permanent-corner-v2.png": Vector4(579.25, 350.25, 298.5, 234.0),
	"res://assets/mossvein/cave-corner-v1.png": Vector4(481.25, 547.75, 105.5, 54.0),
	"res://assets/rootwound/cave-corner-v1.png": Vector4(512.5, 512.0, 111.0, 63.0),
	"res://assets/moonglass/cave-corner-v1.png": Vector4(557.0, 469.75, 118.75, 99.0),
	"res://assets/emberdeep/cave-corner-v1.png": Vector4(554.0, 505.0, 119.0, 55.5),
	"res://assets/starfall/cave-corner-v1.png": Vector4(512.5, 507.75, 112.75, 41.0),
	"res://assets/voidstar/cave-corner-v1.png": Vector4(511.75, 510.0, 90.75, 54.0),
	"res://assets/molten/cave-corner-v1.png": Vector4(519.5, 510.75, 153.75, 87.0),
	"res://assets/prismatic/cave-corner-v1.png": Vector4(509.0, 511.0, 120.5, 103.0),
	"res://assets/caves/ancient-bedrock-corner-v1.png": Vector4(511.75, 540.5, 249.25, 205.0),
}
const EDGE_ALPHA_CENTER: = {
	"res://assets/mossvein/cave-corner-v2.png": 66.5,
	"res://assets/mossvein/permanent-corner-v2.png": 130.0,
	"res://assets/mossvein/cave-corner-v1.png": 52.0,
	"res://assets/rootwound/cave-corner-v1.png": 58.5,
	"res://assets/moonglass/cave-corner-v1.png": 61.5,
	"res://assets/emberdeep/cave-corner-v1.png": 56.75,
	"res://assets/starfall/cave-corner-v1.png": 58.5,
	"res://assets/voidstar/cave-corner-v1.png": 50.0,
	"res://assets/molten/cave-corner-v1.png": 69.5,
	"res://assets/prismatic/cave-corner-v1.png": 59.5,
	"res://assets/caves/ancient-bedrock-corner-v1.png": 132.5,
}
# Geometry is immutable and shared by every occurrence of an authored corner.
# There is one mesh per texture/tile/depth combination, never one node per tile.
static var _corner_meshes: Dictionary = {}
''')
a=s.index('static func _draw_corner(')
b=s.index('\n\nstatic func _edge_midpoint',a)
s=s[:a]+'''static func _draw_corner(
	canvas: CanvasItem,
	texture: Texture2D,
	cell: Vector2i,
	corner: int,
	tile_size: float,
	depth: float,
	inset: float,
	modulate: Color,
	_compact_join: bool
) -> void :
	if texture == null or corner < 0 or corner > 3:
		return
	var key: String = "%s:%s:%s" % [texture.resource_path, tile_size, depth]
	if not _corner_meshes.has(key):
		_corner_meshes[key] = _make_corner_mesh(texture, tile_size, depth, inset)
	var origin: = _corner_anchor(cell, corner, tile_size)
	var rotation: float = float([0.0, PI * 0.5, PI, - PI * 0.5][corner])
	canvas.draw_set_transform(origin, rotation, Vector2.ONE)
	canvas.draw_mesh(_corner_meshes[key], texture, Transform2D.IDENTITY, modulate)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _make_corner_mesh(texture: Texture2D, tile_size: float, depth: float, inset: float) -> ArrayMesh:
	var path: String = texture.resource_path
	var source_height: float = BEDROCK_SOURCE_HEIGHT if depth > tile_size * 1.5 else EDGE_SOURCE_HEIGHT
	var registration: Vector4 = CORNER_REGISTRATION.get(path, Vector4(512.0, 512.0, 128.0, 96.0))
	var scale: float = depth * registration.w / source_height / registration.z
	var edge_center: float = float(EDGE_ALPHA_CENTER.get(path, source_height * 0.5))
	var solid_bias: float = depth - inset - edge_center * depth / source_height
	var source_origin: = Vector2(-solid_bias, solid_bias) - Vector2(registration.x, registration.y) * scale
	var destination: = Rect2(source_origin, Vector2(texture.get_size()) * scale)
	# The original curve and its complete outer alpha silhouette remain intact.
	# Only the two long arms blend back into their matching straight faces. A hard
	# rectangular crop used to bisect live boulders at exactly half a gameplay tile.
	var arm_end: float = tile_size * 0.78
	var blend_start: float = tile_size * 0.34
	var xs: PackedFloat32Array = PackedFloat32Array([maxf(destination.position.x, -arm_end), -blend_start, destination.end.x])
	var ys: PackedFloat32Array = PackedFloat32Array([destination.position.y, blend_start, minf(destination.end.y, arm_end)])
	var vertices: PackedVector3Array = PackedVector3Array()
	var uvs: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()
	var indices: PackedInt32Array = PackedInt32Array()
	for y in 3:
		for x in 3:
			var position: = Vector2(xs[x], ys[y])
			vertices.append(Vector3(position.x, position.y, 0.0))
			uvs.append((position - destination.position) / destination.size)
			colors.append(Color(1.0, 1.0, 1.0, 0.0 if x == 0 or y == 2 else 1.0))
	for y in 2:
		for x in 2:
			var first: int = y * 3 + x
			indices.append_array(PackedInt32Array([first, first + 1, first + 3, first + 1, first + 4, first + 3]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh: = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
''' +s[b:]
p.write_text(s)
