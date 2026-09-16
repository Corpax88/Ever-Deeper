@tool
class_name FlatPolygon2D
extends Node2D
## Solid, untextured polygons use CanvasItem commands, preserving their geometry.
## Godot 4.7.2's Polygon2D mesh-index update binds an index buffer as ARRAY_BUFFER,
## which WebGL rejects on repeated drawing. This avoids that update path.

@export var polygon: PackedVector2Array = PackedVector2Array():
	set(value):
		polygon = value
		queue_redraw()

@export var color: Color = Color.WHITE:
	set(value):
		if color == value: return
		color = value
		queue_redraw()

func _draw() -> void:
	if polygon.size() >= 3:
		# Polygon2D packs mesh colors as clamped, truncated RGBA8. Preserve that
		# opacity/color precision when the CanvasItem path accepts float colors.
		var mesh_color := Color(
			float(int(clampf(color.r * 255.0, 0.0, 255.0))) / 255.0,
			float(int(clampf(color.g * 255.0, 0.0, 255.0))) / 255.0,
			float(int(clampf(color.b * 255.0, 0.0, 255.0))) / 255.0,
			float(int(clampf(color.a * 255.0, 0.0, 255.0))) / 255.0)
		draw_colored_polygon(polygon, mesh_color)
