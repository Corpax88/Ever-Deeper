class_name HeatStreakRing
extends Control

const GOLD: = Color("d7b45a")
const GOLD_BRIGHT: = Color("ffe3a0")
const EMBER: = Color("ff9a57")

var progress: = 0.0
var active: = false


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 3
	visible = false


func set_heat_streak(next_progress: float, next_active: bool) -> void :
	var clamped: = clampf(next_progress, 0.0, 1.0)
	if is_equal_approx(progress, clamped) and active == next_active:
		return
	progress = clamped
	active = next_active
	visible = active and progress > 0.01
	queue_redraw()


func clear() -> void :
	set_heat_streak(0.0, false)


func debug_snapshot() -> Dictionary:
	return {
		"progress": progress,
		"active": active,
		"visible": visible,
		"transparent": true,
		"text_free": true,
		"mouse_passthrough": mouse_filter == Control.MOUSE_FILTER_IGNORE,
	}


func _draw() -> void :
	if not visible or size.x <= 1.0 or size.y <= 1.0:
		return
	var center: = size * 0.5
	var radius: = minf(size.x, size.y) * 0.5 - 7.0
	var start_angle: = - PI * 0.5
	var end_angle: = start_angle + TAU * progress
	draw_arc(center, radius, 0.0, TAU, 72, Color(GOLD, 0.16), 3.0, true)
	draw_arc(center, radius, start_angle, end_angle, maxi(8, ceili(72.0 * progress)), Color(GOLD, 0.86), 5.0, true)
	if progress >= 0.995:
		draw_arc(center, radius - 5.0, 0.0, TAU, 72, Color(EMBER, 0.3), 3.0, true)
		draw_circle(center + Vector2.UP.rotated(end_angle) * radius, 4.5, GOLD_BRIGHT)
