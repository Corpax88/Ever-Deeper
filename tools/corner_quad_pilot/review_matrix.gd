extends SceneTree
## First gate: actual native corner sampling, full-frame A/B/A pixel equality.
const ASSETS: Array[String] = [
	"res://assets/caves/ancient-bedrock-corner-v1.png",
	"res://assets/rootwound/cave-corner-v1.png",
	"res://assets/prismatic/cave-corner-v1.png",
	"res://assets/molten/cave-corner-v1.png",
	"res://assets/voidstar/cave-corner-v1.png",
	"res://assets/mossvein/cave-corner-v2.png",
	"res://assets/moonglass/cave-corner-v1.png",
	"res://assets/emberdeep/cave-corner-v1.png",
]
const COMPACT_ASSETS: Array[String] = [
	"res://assets/mossvein/cave-corner-v2.png",
	"res://assets/moonglass/cave-corner-v1.png",
	"res://assets/emberdeep/cave-corner-v1.png",
	"res://assets/starfall/cave-corner-v1.png",
]
var output: String
var reference_path: String
var candidate
var reference
var stage: Node2D
var quads: Array[Node2D] = []
var lights: Array[PointLight2D] = []
var rows: Array[Dictionary] = []
var failed: bool = false

class CornerCanvas extends Node2D:
	var drawer
	var texture: Texture2D
	var edge_texture: Texture2D
	var corner: int
	var tile_size: float
	var bedrock: bool
	var compact: bool
	func _draw() -> void:
		# Match native join order: adjacent wall faces precede the corner cap.
		var sides: Array = [[0, 1], [1, 2], [2, 3], [3, 0]][corner]
		for side in sides:
			if bedrock:
				drawer.draw_bedrock_edge(self, edge_texture, Vector2i.ZERO, int(side), tile_size, 7)
			else:
				drawer.draw_mineable_edge(self, edge_texture, Vector2i.ZERO, int(side), tile_size, 7)
		if bedrock:
			drawer.draw_bedrock_corner(self, texture, Vector2i.ZERO, corner, tile_size)
		else:
			drawer.draw_mineable_corner(self, texture, Vector2i.ZERO, corner, tile_size, Color.WHITE, compact)

class Backdrop extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0, 0, 1696, 780), Color(0.16, 0.19, 0.22))
		for x in range(0, 1696, 32):
			for y in range(0, 780, 32):
				if (x / 32 + y / 32) % 2 == 0:
					draw_rect(Rect2(x, y, 32, 32), Color(0.21, 0.24, 0.27))

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
		elif argument.begins_with("--reference-script="): reference_path = argument.trim_prefix("--reference-script=")
	if not output.is_absolute_path() or not reference_path.is_absolute_path() or DisplayServer.get_name() == "headless":
		push_error("Rendered output and generated exact-base reference are required")
		quit(2)
		return
	candidate = load("res://scripts/world/cave_edge_asset_drawer.gd")
	reference = load(reference_path)
	if candidate == null or reference == null:
		quit(3)
		return
	root.add_child(Backdrop.new())
	stage = Node2D.new()
	root.add_child(stage)
	for index in 4:
		var quad: CornerCanvas = CornerCanvas.new()
		quad.material = load("res://shaders/lit_visible_pixels.tres")
		quad.corner = index
		stage.add_child(quad)
		quads.append(quad)
	# Bilinear, additive native-style light sampling is exercised without timers.
	var gradient: Gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	var radial: GradientTexture2D = GradientTexture2D.new()
	radial.width = 256
	radial.height = 256
	radial.gradient = gradient
	radial.fill = GradientTexture2D.FILL_RADIAL
	radial.fill_from = Vector2(0.5, 0.5)
	radial.fill_to = Vector2(0.5, 1.0)
	for index in 2:
		var light: PointLight2D = PointLight2D.new()
		light.texture = radial
		light.texture_scale = 3.0
		light.position = Vector2(425 + index * 845, 350)
		light.color = Color(0.9, 0.7, 0.4) if index == 0 else Color(0.4, 0.7, 0.9)
		light.energy = 0.45
		stage.add_child(light)
		lights.append(light)
	for path in ASSETS:
		for tile in [48.0, 64.0]:
			for profile in ["nearest_integer", "linear_fractional", "linear_zoomed_lit"]:
				if not await _case(path, tile, profile, false): return
	for path in COMPACT_ASSETS:
		if not await _case(path, 48.0, "linear_fractional", true): return
	_write_report(true)
	print("CORNER_MATRIX_FINISHED complete=true passed=true cases=", rows.size())
	print("CORNER_MATRIX_COMPLETE")
	quit(0)

func _case(path: String, tile: float, profile: String, compact: bool) -> bool:
	var texture: Texture2D = load(path)
	var edge_path: String = path.replace("corner", "edge-loop")
	var edge_texture: Texture2D = load(edge_path)
	var bedrock: bool = "ancient-bedrock" in path
	var factor: float = 0.91 if profile == "linear_zoomed_lit" else 1.0
	var subpixel: Vector2 = Vector2(0.25, 0.375) if profile != "nearest_integer" else Vector2.ZERO
	var depth: float = tile * (2.0 if bedrock else 1.0)
	var inset: float = tile * ((18.0 if bedrock else 10.0) / 48.0)
	var center_offset: Vector2 = Vector2(-1, 1) * (depth * 0.5 - inset)
	for index in 4:
		var quad: CornerCanvas = quads[index] as CornerCanvas
		quad.texture = texture
		quad.edge_texture = edge_texture
		quad.tile_size = tile
		quad.bedrock = bedrock
		quad.compact = compact
		quad.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if profile == "nearest_integer" else CanvasItem.TEXTURE_FILTER_LINEAR
		quad.scale = Vector2.ONE * factor
		var rotation: float = [0.0, PI * 0.5, PI, -PI * 0.5][index]
		var anchor: Vector2 = [Vector2(tile, 0), Vector2(tile, tile), Vector2(0, tile), Vector2.ZERO][index]
		quad.position = Vector2(212 + index * 424, 390) + subpixel - (anchor + center_offset.rotated(rotation)) * factor
	for light in lights: light.enabled = profile == "linear_zoomed_lit"
	var name: String = path.get_base_dir().get_file() + "_%d_" % int(tile) + profile + ("_compact" if compact else "")
	var first: Image = await _capture(reference, name + "-A")
	var local: Image = await _capture(candidate, name + "-B")
	var restored: Image = await _capture(reference, name + "-A2")
	if first.get_size() != Vector2i(1696, 780) or local.get_size() != Vector2i(1696, 780) or restored.get_size() != Vector2i(1696, 780):
		push_error("Corner matrix requires actual 1696x780 framebuffers")
		failed = true
		_write_report(false)
		quit(5)
		return false
	var equal: bool = first.get_data() == local.get_data()
	var stable: bool = first.get_data() == restored.get_data()
	rows.append({"id":name,"texture":path,"texture_sha256":FileAccess.get_sha256(path),"edge_texture":edge_path,"edge_sha256":FileAccess.get_sha256(edge_path),"tile":tile,"profile":profile,"rotations":4,"compact_join":compact,"equal_rgba":equal,"restored_equal_rgba":stable,"size":str(first.get_size())})
	failed = failed or not equal or not stable
	_write_report(false)
	print("CORNER_MATRIX_CASE ", name, " equal=", equal, " restored_equal=", stable)
	if failed:
		print("CORNER_MATRIX_FINISHED complete=false passed=false first_failed_case=", name)
		quit(4)
		return false
	return true

func _capture(drawer, id: String) -> Image:
	for quad in quads:
		quad.drawer = drawer
		quad.queue_redraw()
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	image.convert(Image.FORMAT_RGBA8)
	image.save_png(output.path_join(id + ".png"))
	return image

func _write_report(complete: bool) -> void:
	var report: Dictionary = {
		"complete":complete,"passed":not failed,"cases":rows,
		"candidate_source_sha256":FileAccess.get_sha256("res://scripts/world/cave_edge_asset_drawer.gd"),
		"reference_source_sha256":FileAccess.get_sha256(reference_path),
		"harness_sha256":FileAccess.get_sha256(get_script().resource_path),
		"renderer":RenderingServer.get_video_adapter_name(),"physical_iphone":false,
		"scope":"Actual corner sampling preflight; integrated worlds and performance remain separate gates.",
	}
	FileAccess.open(output.path_join("matrix.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
