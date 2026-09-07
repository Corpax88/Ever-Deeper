class_name CrusherDebris
extends RefCounted




const MAX_CHUNKS: = 0
const LIFE_SECONDS: = 0.3


static func create_burst(_seed_value: int) -> Array[Dictionary]:
	var chunks: Array[Dictionary] = []
	return chunks


static func draw_burst(canvas: CanvasItem, impact: Dictionary, _palette: Array[Color] = []) -> void :
	var life: = maxf(0.001, float(impact.get("life", LIFE_SECONDS)))
	var progress: = clampf(float(impact.get("age", 0.0)) / life, 0.0, 1.0)
	var center: = Vector2(impact.get("position", Vector2.ZERO))
	var effect_alpha: = 1.0 - progress



	var dust_radius: = lerpf(14.0, 88.0, minf(1.0, progress * 2.1))
	for dust_index in range(6):
		var dust_angle: = float(dust_index) * TAU / 6.0 + sin(float(dust_index) * 2.7) * 0.14
		var dust_distance: = dust_radius * lerpf(0.62, 1.0, fposmod(float(dust_index) * 0.37, 1.0))
		var dust_position: = center + Vector2.from_angle(dust_angle) * dust_distance
		var dust_size: = (7.0 + float(dust_index % 3) * 2.8) * effect_alpha
		canvas.draw_circle(dust_position, dust_size, Color(0.24, 0.19, 0.14, effect_alpha * 0.28))

	for crack_index in range(4):
		var crack_direction: = Vector2.from_angle(float(crack_index) * TAU / 4.0 + 0.11)
		var crack_length: = lerpf(16.0, 58.0, minf(1.0, progress * 3.5))
		var bend: = 0.12 if crack_index % 2 == 0 else -0.12
		var crack_mid: = center + crack_direction.rotated(bend) * crack_length * 0.52
		var crack_end: = center + crack_direction * crack_length
		canvas.draw_polyline(
			PackedVector2Array([center + crack_direction * 8.0, crack_mid, crack_end]),
			Color(0.08, 0.06, 0.05, effect_alpha * 0.62),
			2.0
		)
