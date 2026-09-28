extends Control
## Small event-driven, noninteractive skill notice using the existing Skills art.
const FONT = preload("res://assets/ui/fonts/EBGaramond.ttf")
const SIZE = Vector2(360, 86)
const DURATION = 3.0
var pending: Array[Dictionary] = []
var active: Dictionary = {}
var elapsed: float = 0.0
var card: Control
var icon: TextureRect
var title: Label
var shown: int = 0

func _ready() -> void:
	name = "SkillLevelToast"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 150
	card = Control.new()
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size = SIZE
	add_child(card)
	icon = TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(12, 20)
	icon.size = Vector2(54, 54)
	card.add_child(icon)
	var heading: Label = _label("SKILL INCREASED", 18)
	heading.position = Vector2(82, 8)
	heading.size = Vector2(270, 24)
	heading.modulate = Color("d8bd85")
	title = _label("", 32)
	title.position = Vector2(82, 31)
	title.size = Vector2(270, 46)
	RunState.miner_skill_increased.connect(_earned)
	RunState.miner_skills_restored.connect(clear)
	get_viewport().size_changed.connect(_layout)
	clear()
	_layout()

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("ffe3a0"))
	label.add_theme_color_override("font_outline_color", Color("21170f"))
	label.add_theme_constant_override("outline_size", 5)
	card.add_child(label)
	return label

func _earned(id: String, level: int) -> void:
	if active.get("id", "") == id:
		active.level = level
		_refresh()
		elapsed = 0.0
		return
	for item in pending:
		if item.id == id:
			item.level = level
			return
	pending.append({"id":id,"level":level})
	if active.is_empty(): _next()

func _next() -> void:
	if pending.is_empty():
		active.clear()
		hide()
		set_process(false)
		return
	active = pending.pop_front()
	elapsed = 0.0
	shown += 1
	_refresh()
	card.modulate.a = 0.0
	set_process(true)
	_process(0.0)

func _refresh() -> void:
	var id: String = active.id
	title.text = "%s  ·  %d" % [id.capitalize(),int(active.level)]
	icon.texture = load("res://assets/ui/skills/icons/"+("bag" if id == "carrying" else id)+".svg")

func clear() -> void:
	pending.clear()
	active.clear()
	elapsed = 0.0
	hide()
	set_process(false)

func _process(delta: float) -> void:
	var main: Node = get_tree().current_scene
	var obstructed: bool = get_tree().paused or not main.game_started or main.menu_open or main.inventory_open or main._shop_panel_is_open()
	if main.miner_skills_panel != null: obstructed = obstructed or main.miner_skills_panel.visible
	visible = not obstructed
	if obstructed: return
	elapsed += delta
	var fade_in: float = smoothstep(0.0, 0.3, elapsed)
	var fade_out: float = 1.0-smoothstep(2.4, DURATION, elapsed)
	card.modulate.a = fade_in*fade_out
	_layout()
	if elapsed >= DURATION: _next()

func _layout() -> void:
	var view: Vector2 = get_viewport_rect().size
	card.position = Vector2((view.x-SIZE.x)*0.5,maxf(22.0,view.y*0.07)+(1.0-smoothstep(0.0,0.3,elapsed))*6.0)

func snapshot() -> Dictionary:
	return {"active":active.duplicate(),"queued":pending.duplicate(true),"visible":visible,"opacity":card.modulate.a,"shown":shown,"rect":[card.position.x,card.position.y,SIZE.x,SIZE.y],"icon_loaded":icon.texture!=null,"text":title.text,"ignores_input":mouse_filter==Control.MOUSE_FILTER_IGNORE}
