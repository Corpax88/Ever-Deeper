extends Control

const INK := Color("fff0ce")
const BACKGROUND := Color("15201e")
const BORDER := Color("c8a46d")
const PADDING := Vector2(19, 13)
const TAIL_HEIGHT := 20.0
const MAX_WIDTH := 440.0
const TOP_INSET := 114.0

var speaker: Node2D
var _speaker_position: Vector2
var _caption: Label
var _paper := StyleBoxFlat.new()
var _tail := Vector2.ZERO
var _below := false
var _remaining := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 25
	_paper.bg_color = BACKGROUND
	_paper.border_color = BORDER
	_paper.set_border_width_all(2)
	_paper.set_corner_radius_all(12)
	_paper.shadow_color = Color(0, 0, 0, 0.32)
	_paper.shadow_size = 4
	_caption = Label.new()
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_font_size_override("font_size", 25)
	_caption.add_theme_color_override("font_color", INK)
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_caption)
	hide()


func speak(actor: Node2D, dialogue: String) -> void:
	dismiss()
	speaker = actor
	_speaker_position = actor.position
	_caption.text = dialogue
	_remaining = clampf(3.0 + float(dialogue.length()) / 15.0, 5.0, 9.0)
	(speaker.get_node("QuestMark") as Label).hide()
	show()
	_reposition()


func follow(delta: float, eligible: bool, player: Node2D) -> void:
	if not visible:
		return
	_remaining -= delta
	if (_remaining <= 0.0 or not eligible or not is_instance_valid(speaker)
			or not speaker.is_visible_in_tree() or speaker.position != _speaker_position
			or not is_instance_valid(player) or player.global_position.distance_to(speaker.global_position) > 180.0):
		dismiss()
		return
	_reposition()


func dismiss() -> void:
	if is_instance_valid(speaker):
		(speaker.get_node("QuestMark") as Label).show()
	speaker = null
	hide()


func _reposition() -> void:
	var screen := get_viewport_rect()
	var tip := speaker.get_global_transform_with_canvas() * Vector2(0, -132)
	var font := _caption.get_theme_font("font")
	var font_size := _caption.get_theme_font_size("font_size")
	var max_width := minf(MAX_WIDTH, screen.size.x - 36.0)
	var width := minf(ceilf(font.get_string_size(_caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x) + PADDING.x * 2.0, max_width)
	_caption.position = PADDING
	_caption.size = Vector2(width - PADDING.x * 2.0, 0)
	size = Vector2(width, _caption.get_line_height() * _caption.get_line_count() + PADDING.y * 2.0)
	var top := screen.position.y + TOP_INSET
	var above := tip.y - TAIL_HEIGHT - size.y
	_below = above < top
	position = Vector2(
		clampf(tip.x - size.x * 0.5, screen.position.x + 18.0, screen.end.x - size.x - 18.0),
		clampf(tip.y + TAIL_HEIGHT if _below else above, top, maxf(top, screen.end.y - size.y - 18.0))
	)
	_tail = tip - position
	queue_redraw()


func _draw() -> void:
	var edge := 1.0 if _below else size.y - 1.0
	var center := clampf(_tail.x, 19.0, size.x - 19.0)
	var left := Vector2(center - 10.0, edge)
	var right := Vector2(center + 10.0, edge)
	draw_colored_polygon(PackedVector2Array([left, _tail, right]), BACKGROUND)
	draw_polyline(PackedVector2Array([left, _tail, right]), BORDER, 2.0, true)
	draw_style_box(_paper, Rect2(Vector2.ZERO, size))
	# Cover the strip of border across the base of the bubble tail.
	draw_line(Vector2(left.x + 1.0, edge), Vector2(right.x - 1.0, edge), BACKGROUND, 3.0)
