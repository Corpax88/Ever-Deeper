extends Control
var _bar: ProgressBar
var _elapsed: float = 0.0
func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 anchor_left = 0.5
 anchor_right = 0.5
 anchor_top = 1.0
 anchor_bottom = 1.0
 offset_left = -110
 offset_right = 110
 offset_top = -34
 offset_bottom = -16
 _bar = ProgressBar.new()
 _bar.show_percentage = false
 _bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
 _bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 var back = StyleBoxFlat.new()
 back.bg_color = Color(0.08, 0.05, 0.03, 0.88)
 back.border_color = Color("9a6946")
 back.set_border_width_all(1)
 back.set_corner_radius_all(5)
 var fill = StyleBoxFlat.new()
 fill.bg_color = Color("ff9c43")
 fill.set_corner_radius_all(4)
 _bar.add_theme_stylebox_override("background", back)
 _bar.add_theme_stylebox_override("fill", fill)
 add_child(_bar)
 visible = false
func _process(delta: float) -> void:
 _elapsed += delta
 if _elapsed < 0.1: return
 _elapsed = 0.0
 _bar.value = RunState.stamina_value()
 visible = _bar.value < 99.9
 modulate = Color("ff9d78") if _bar.value < 15 else Color.WHITE
