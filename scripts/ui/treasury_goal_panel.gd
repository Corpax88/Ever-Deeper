extends Control
## Approved Pappa Hammer mod preview. State owner alone authorizes claims.
const Goals = preload("res://scripts/state/treasury_goals.gd")
const Stack = preload("res://scripts/world/treasury_stack.gd")
const Catalog = preload("res://scripts/ui/mod_preview_catalog.gd")
const FONT = preload("res://assets/ui/fonts/EBGaramond.ttf")
const DESIGN = Vector2(1000,720)
var main: Node
var kind: String = ""
var panel: Control
var heading: Label
var title: Label
var progress: Label
var detail: Label
var source: Label
var preview: TextureRect
var preview_back: TextureRect
var progress_bar: ProgressBar
var pin_button: Button
var claim_button: Button
var close_button: Button
var _textures: Dictionary = {}

func setup(owner_main: Node) -> void:
	main = owner_main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 160
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0,0,0,0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	panel = Control.new()
	panel.size=DESIGN
	add_child(panel)
	var frame: NinePatchRect=NinePatchRect.new()
	var atlas: AtlasTexture=AtlasTexture.new()
	atlas.atlas=load("res://assets/ui/skills/iron-panel-v1.png")
	atlas.region=Rect2(25,33,1095,1276)
	frame.texture=atlas
	frame.scale=Vector2.ONE*0.32
	frame.size=DESIGN/0.32
	frame.patch_margin_left=174;frame.patch_margin_right=174;frame.patch_margin_top=174;frame.patch_margin_bottom=174
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(frame)
	heading = _label(27,Rect2(48,29,904,36))
	title = _label(66,Rect2(45,60,910,82))
	title.add_theme_color_override("font_color",Color("d6efff"))
	title.add_theme_color_override("font_outline_color",Color("32566d"))
	title.add_theme_constant_override("outline_size",3)
	title.add_theme_color_override("font_shadow_color",Color("070f17"))
	title.add_theme_constant_override("shadow_offset_y",3)
	preview_back=TextureRect.new()
	preview_back.texture=load("res://assets/ui/skills/mine-backdrop-v1.png")
	preview_back.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview_back.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview_back.modulate=Color(0.37,0.37,0.4,1)
	preview_back.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(preview_back)
	_place(preview_back,Rect2(44,146,912,240))
	preview=TextureRect.new()
	preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(preview)
	_place(preview,Rect2(48,146,904,240))
	detail = _label(25,Rect2(52,391,896,40))
	detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	progress_bar=ProgressBar.new()
	progress_bar.show_percentage=false
	progress_bar.max_value=Stack.GOAL
	progress_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var track: StyleBoxFlat=StyleBoxFlat.new()
	track.bg_color=Color("21150a");track.border_color=Color("b58435")
	track.set_border_width_all(2);track.set_corner_radius_all(5)
	var fill: StyleBoxFlat=StyleBoxFlat.new()
	fill.bg_color=Color("edb940");fill.border_color=Color("fff0a1")
	fill.set_border_width_all(2);fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background",track)
	progress_bar.add_theme_stylebox_override("fill",fill)
	panel.add_child(progress_bar)
	_place(progress_bar,Rect2(86,438,828,18))
	progress = _label(27,Rect2(55,463,890,34))
	claim_button = _button("CLAIM RESONANCE",Rect2(230,501,540,62),_claim,true)
	pin_button = _button("TRACK GOAL",Rect2(267,569,466,46),func(): Goals.pin(kind); refresh())
	close_button = _button("CLOSE",Rect2(277,621,446,40),close_panel)
	source = _label(20,Rect2(55,666,890,27))
	source.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _place(control: Control, rect: Rect2) -> void:
	control.position=rect.position
	control.size=rect.size

func _label(font_size: int, rect: Rect2) -> Label:
	var label: Label=Label.new()
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",font_size)
	label.add_theme_color_override("font_color",Color("c5e2f3"))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	_place(label,rect)
	return label

func _png(path: String) -> Texture2D:
	if not _textures.has(path):
		var image: Image=Image.new()
		if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK: return null
		_textures[path]=ImageTexture.create_from_image(image)
	return _textures[path]

func _button(text: String, rect: Rect2, action: Callable, primary: bool=false) -> Button:
	var button: Button=Button.new()
	button.text=text
	button.add_theme_font_override("font",FONT)
	button.add_theme_font_size_override("font_size",30 if primary else 25)
	for state in ["normal","hover","pressed","disabled"]:
		button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	var frame: NinePatchRect=NinePatchRect.new()
	var atlas: AtlasTexture=AtlasTexture.new()
	atlas.atlas=_png("res://assets/ui/mods/gold-button-v1.png") if primary else load("res://assets/ui/skills/copper-button-v1.png")
	atlas.region=Rect2(42,184,2088,328) if primary else Rect2(104,128,1044,982)
	frame.texture=atlas
	var frame_scale: float=0.18 if primary else 0.07
	frame.scale=Vector2.ONE*frame_scale
	frame.size=rect.size/frame_scale
	frame.patch_margin_left=100 if primary else 174
	frame.patch_margin_right=frame.patch_margin_left
	frame.patch_margin_top=28 if primary else 174
	frame.patch_margin_bottom=frame.patch_margin_top
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	frame.show_behind_parent=true
	button.add_child(frame)
	button.set_meta("frame",frame)
	button.mouse_entered.connect(func(): if not button.disabled: frame.modulate=Color(1.12,1.12,1.12))
	button.mouse_exited.connect(func(): frame.modulate=Color(0.45,0.45,0.45) if button.disabled else Color.WHITE)
	button.button_down.connect(func(): frame.modulate=Color(0.78,0.78,0.78))
	button.button_up.connect(func(): frame.modulate=Color.WHITE)
	button.add_theme_color_override("font_color",Color("25180d") if primary else Color("e0dfdc"))
	button.add_theme_color_override("font_hover_color",Color("25180d") if primary else Color.WHITE)
	button.add_theme_color_override("font_pressed_color",Color("25180d") if primary else Color.WHITE)
	button.add_theme_color_override("font_disabled_color",Color("e5d3ad"))
	button.pressed.connect(action)
	panel.add_child(button)
	_place(button,rect)
	return button

func _layout() -> void:
	var viewport_size: Vector2=get_viewport_rect().size
	var zoom: float=minf((viewport_size.x-32.0)/DESIGN.x,(viewport_size.y-24.0)/DESIGN.y)
	panel.scale=Vector2.ONE*zoom
	panel.position=(viewport_size-DESIGN*zoom)*0.5

func open_goal(resource: String) -> void:
	if resource not in Goals.Ledger.keys() or main.menu_open: return
	main._open_start_menu()
	if not main.menu_open: return
	main.premium_menu.hide()
	kind=resource
	refresh()
	show()

func refresh() -> void:
	heading.text=Goals.label(kind).to_upper()+" · TREASURY"
	var stored: int=int(RunState.treasury_totals.get(kind,0))
	progress.text="%s / %s delivered" % [_number(mini(stored,Stack.GOAL)),_number(Stack.GOAL)]
	progress_bar.value=clampi(stored,0,Stack.GOAL)
	source.text="Find it: "+Goals.sources(kind)
	var data: Dictionary=Catalog.preview(kind)
	preview.visible=not data.is_empty()
	preview_back.visible=preview.visible
	title.text=String(data.get("title","COLLECTION"))
	detail.text=String(data.get("description","Fill this podium, one piece at a time."))
	if preview.visible: preview.texture=_png(String(data.art))
	claim_button.visible=kind==Goals.Ledger.WALLET
	if claim_button.visible:
		var claimed: bool=bool(RunState.treasury_goals.get("resonance_claimed",false))
		claim_button.text=("RESONANCE: ON" if bool(RunState.treasury_goals.get("resonance_enabled",false)) else "RESONANCE: OFF") if claimed else "CLAIM RESONANCE" if stored>=Stack.GOAL else "FILL PODIUM TO UNLOCK"
		claim_button.disabled=not claimed and stored<Stack.GOAL
		claim_button.get_meta("frame").modulate=Color(0.45,0.45,0.45) if claim_button.disabled else Color.WHITE
	elif stored>=Stack.GOAL:
		detail.text="COLLECTION COMPLETE"
	# Unspecified future rewards keep the existing collection view; no invented mod.
	if data.is_empty():
		_place(detail,Rect2(70,238,860,100))
	else:
		_place(detail,Rect2(52,391,896,40))
	pin_button.text="UNTRACK GOAL" if RunState.treasury_goals.get("pinned","")==kind else "TRACK GOAL"

func _number(value: int) -> String:
	var digits: String=str(value)
	var result: String=""
	for i in digits.length():
		if i>0 and (digits.length()-i)%3==0: result+=","
		result+=digits[i]
	return result

func _claim() -> void:
	if bool(RunState.treasury_goals.get("resonance_claimed",false)): Goals.toggle_resonance()
	else: Goals.claim_resonance()
	main.endless_world.resonance_drill.dev_override=false
	main.endless_world.resonance_drill.set_enabled(bool(RunState.treasury_goals.get("resonance_enabled",false)))
	refresh()

func close_panel() -> void:
	hide()
	main._continue_from_menu()
