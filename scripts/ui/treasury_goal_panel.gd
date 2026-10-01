extends Control
## Reuses the existing Skills art. State owner alone authorizes claims.
const Goals = preload("res://scripts/state/treasury_goals.gd")
const Stack = preload("res://scripts/world/treasury_stack.gd")
const FONT = preload("res://assets/ui/fonts/EBGaramond.ttf")
var main: Node
var kind: String = ""
var panel: Control
var heading: Label
var progress: Label
var detail: Label
var source: Label
var pin_button: Button
var claim_button: Button
var close_button: Button

func setup(owner_main: Node) -> void:
	main = owner_main
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 115
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0,0,0,0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	panel = Control.new()

	var frame: NinePatchRect=NinePatchRect.new()
	var atlas: AtlasTexture=AtlasTexture.new()
	atlas.atlas=load("res://assets/ui/skills/iron-panel-v1.png")
	atlas.region=Rect2(25,33,1095,1276)
	frame.texture=atlas
	frame.scale=Vector2.ONE*0.36
	frame.patch_margin_left=174;frame.patch_margin_right=174;frame.patch_margin_top=174;frame.patch_margin_bottom=174
	frame.mouse_filter=Control.MOUSE_FILTER_IGNORE

	panel.add_child(frame)
	panel.resized.connect(func(): frame.size=panel.size/0.36)
	center.add_child(panel)
	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation",8)
	panel.add_child(content)
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left=36;content.offset_right=-36;content.offset_top=28;content.offset_bottom=-28
	heading = _label(content,28)
	progress = _label(content,25)
	detail = _label(content,20)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	source = _label(content,17)
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pin_button = _button(content,"TRACK GOAL",func(): Goals.pin(kind); refresh())
	claim_button = _button(content,"CLAIM RESONANCE",_claim)
	close_button = _button(content,"CLOSE",close_panel)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _label(parent_node: Node, size: int) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_override("font",FONT)
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("c5e2f3"))
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	parent_node.add_child(label)
	return label

func _button(parent_node: Node, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text=text
	button.custom_minimum_size.y=48
	button.add_theme_font_size_override("font_size",18)
	button.pressed.connect(action)
	parent_node.add_child(button)
	return button

func _layout() -> void:
	panel.custom_minimum_size=Vector2(minf(650,get_viewport_rect().size.x-80),minf(460,get_viewport_rect().size.y-30))

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
	progress.text="%d / %d delivered" % [mini(stored,Stack.GOAL),Stack.GOAL]
	source.text="Find it: "+Goals.sources(kind)
	detail.text="Fill this podium, one piece at a time."
	claim_button.visible=kind==Goals.Ledger.WALLET
	if claim_button.visible:
		detail.text="RESONANCE · Charge by mining with a drill in The Deep, then release a five-wide, twelve-row wave."
		var claimed: bool=bool(RunState.treasury_goals.get("resonance_claimed",false))
		claim_button.text=("RESONANCE: ON" if bool(RunState.treasury_goals.get("resonance_enabled",false)) else "RESONANCE: OFF") if claimed else "CLAIM RESONANCE" if stored>=Stack.GOAL else "RESONANCE · FILL PODIUM TO UNLOCK"
		claim_button.disabled=not claimed and stored<Stack.GOAL
	elif stored>=Stack.GOAL:
		detail.text="COLLECTION COMPLETE"
	pin_button.text="UNTRACK GOAL" if RunState.treasury_goals.get("pinned","")==kind else "TRACK GOAL"

func _claim() -> void:
	if bool(RunState.treasury_goals.get("resonance_claimed",false)): Goals.toggle_resonance()
	else: Goals.claim_resonance()
	main.endless_world.resonance_drill.dev_override=false
	main.endless_world.resonance_drill.set_enabled(bool(RunState.treasury_goals.get("resonance_enabled",false)))
	refresh()

func close_panel() -> void:
	hide()
	main._continue_from_menu()
