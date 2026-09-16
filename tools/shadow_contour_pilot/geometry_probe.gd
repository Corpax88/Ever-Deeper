extends SceneTree
const Contours = preload("res://tools/shadow_contour_pilot/contours.gd")

func _initialize() -> void:
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if output.is_empty(): quit(2); return
	var cases: Array = []
	# Every 3x3 topology: all diagonal contacts, cavities and concave corners.
	for mask in 512:
		var spans: Array[Rect2] = []
		var cells: Array = []
		for index in 9:
			if mask & (1 << index):
				var x: int = index % 3 - 2
				var y: int = index / 3 - 2
				spans.append(Rect2(x * 64, y * 64, 64, 64))
				cells.append([x,y])
		var polygons: Array = []
		for polygon in Contours.from_spans(spans,64.0):
			var points: Array = []
			for point in polygon: points.append([point.x,point.y])
			polygons.append(points)
		cases.append({"mask":mask,"cells":cells,"polygons":polygons})
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify({"cases":cases}))
	print("CONTOUR_GEOMETRY_COMPLETE cases=512")
	quit()
