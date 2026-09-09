class_name CompanionJournal
extends Control

signal closed
signal command_requested(command: String)
const Skills = preload("res://scripts/companion/mole_skills.gd")
const INK = Color("49382c")
const GREEN = Color("536443")
const MUTED = Color("7c6955")
const FONT = preload("res://assets/ui/fonts/DejaVuSans.ttf")
const TITLE = preload("res://assets/ui/fonts/DejaVuSerif-Bold.ttf")
var owner_ui: Node
var paper: TextureRect
var content: Control
var portrait: TextureButton
var title_label: Label
var mood: Label
var points: Label
var tally: Label
var tab: String="together"
var tabs: Array[Button]=[]
var body: Control
var status: Label
var clock: float=0.0
var refresh_clock: float=0.0
var response: String=""
var scroll: ScrollContainer
var notice: Label
const PET_REACTIONS = ["wave", "shy", "clap", "hop", "nuzzle", "tip", "kiss", "dance", "giggle", "hug"]
const PET_MESSAGES = ["A little wave, just for you.", "Aw, you made your buddy blush.", "Tiny paws, big applause!", "Too happy to keep both feet down!", "That is the perfect scratching spot.", "A tip of the helmet. Thank you, friend.", "One little paw-kiss, coming your way.", "You started a happy little dance!", "Hehe! Those paws are ticklish.", "A snug little hug, just for you."]
const PET_DURATIONS = [0.12, 0.16, 0.18, 0.26, 0.28, 0.22, 0.16, 0.16]
var pet_bag: Array[int] = []
var pet_last: int = -1
var pet_reaction: int = -1
var pet_elapsed: float = 0.0
var pet_frames: Array[AtlasTexture] = []
var pet_capture_frame: int = -1

func _next_pet_reaction() -> int:
	if pet_bag.is_empty():
		for i in PET_REACTIONS.size(): pet_bag.append(i)
		pet_bag.shuffle()
		if pet_bag.back() == pet_last:
			var swap: int = pet_bag[0]
			pet_bag[0] = pet_bag.back()
			pet_bag[pet_bag.size()-1] = swap
	return pet_bag.pop_back()

func play_pet_reaction(index: int) -> void:
	if index < 0 or index >= PET_REACTIONS.size(): return
	pet_reaction = index
	pet_last = index
	pet_elapsed = 0.0
	pet_frames.clear()
	var sheet: Texture2D = load("res://assets/companion/reactions/" + PET_REACTIONS[index] + ".png")
	# Sample the original PNG without rescaling or baking altered copies.
	# Wave uses only the near-paw poses so its gesture never swaps arms.
	var order: Array = [0, 1, 2, 4, 2, 4, 6, 7] if index == 0 else [0, 1, 2, 3, 4, 5, 6, 7]
	for frame in order:
		var atlas = AtlasTexture.new()
		atlas.atlas = sheet
		var x: int = roundi(float(int(frame) % 4) * sheet.get_width() / 4.0)
		var y: int = roundi(float(int(frame) / 4) * sheet.get_height() / 2.0)
		var right: int = roundi(float(int(frame) % 4 + 1) * sheet.get_width() / 4.0)
		var bottom: int = roundi(float(int(frame) / 4 + 1) * sheet.get_height() / 2.0)
		atlas.region = Rect2(x, y, right-x, bottom-y)
		atlas.filter_clip = true
		pet_frames.append(atlas)
	portrait.rotation = 0.0
	portrait.position = Vector2(158, 168)
	portrait.texture_normal = pet_frames[0]
	response = PET_MESSAGES[index]
	_update_live()

func _reset_pet_reaction() -> void:
	pet_reaction = -1
	pet_capture_frame = -1
	pet_elapsed = 0.0
	pet_frames.clear()
	portrait.texture_normal = preload("res://assets/companion/mole.png")
	portrait.rotation = 0.0
	portrait.position = Vector2(158, 168)

func _advance_pet_reaction(delta: float) -> void:
	if pet_capture_frame >= 0:
		portrait.texture_normal = pet_frames[clampi(pet_capture_frame, 0, 7)]
		return
	pet_elapsed += maxf(delta, 0.0)
	var end: float = 0.0
	for i in PET_DURATIONS.size():
		end += PET_DURATIONS[i]
		if pet_elapsed < end:
			portrait.texture_normal = pet_frames[i]
			return
	_reset_pet_reaction()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_STOP
	var shade=ColorRect.new()
	shade.color=Color(0.08,0.06,0.035,0.73)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	paper=TextureRect.new()
	paper.texture=preload("res://assets/companion/journal-v1.png")
	paper.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	paper.stretch_mode=TextureRect.STRETCH_SCALE
	paper.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(paper)
	content=Control.new()
	add_child(content)
	title_label=_label(content,"Little paws. Big heart.",30,true)
	portrait=TextureButton.new()
	portrait.name="PetMole"
	portrait.texture_normal=preload("res://assets/companion/mole.png")
	portrait.ignore_texture_size=true
	portrait.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	portrait.tooltip_text="Give your mole a little love"
	portrait.pressed.connect(_pet)
	content.add_child(portrait)
	mood=_label(content,"Your little mining buddy",20,true)
	mood.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	points=_label(content,"",18)
	points.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	tally=_label(content,"",16)
	tally.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for id in ["together","skills","how"]:
		var b=_button(content,{"together":"Together","skills":"Paw skills","how":"How we help"}[id],func(): select_tab(id))
		tabs.append(b)
	var close_button=_button(content,"Close",close_journal)
	close_button.name="CloseJournal"
	body=Control.new()
	content.add_child(body)
	notice=_label(content,"",16)
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(_layout)
	visible=false
	_layout()

func _label(parent: Node,text_value: String,font_size: int,bold: bool=false) -> Label:
	var l=Label.new()
	l.text=text_value
	l.add_theme_font_override("font",TITLE if bold else FONT)
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",INK)
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _style(color: Color) -> StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=color
	s.corner_radius_top_left=17;s.corner_radius_top_right=17;s.corner_radius_bottom_left=17;s.corner_radius_bottom_right=17
	s.border_width_left=2;s.border_width_right=2;s.border_width_top=2;s.border_width_bottom=2
	s.border_color=Color("aa9575")
	s.content_margin_left=16;s.content_margin_right=16;s.content_margin_top=9;s.content_margin_bottom=9
	return s

func _button(parent: Node,text_value: String,callback: Callable) -> Button:
	var b=Button.new()
	b.text=text_value
	b.custom_minimum_size=Vector2(0,75)
	b.add_theme_font_override("font",FONT)
	b.add_theme_font_size_override("font_size",18)
	b.add_theme_color_override("font_color",INK)
	b.add_theme_color_override("font_hover_color",INK)
	b.add_theme_color_override("font_pressed_color",INK)
	b.add_theme_color_override("font_disabled_color",MUTED)
	b.add_theme_stylebox_override("normal",_style(Color("e6d7b7")))
	b.add_theme_stylebox_override("hover",_style(Color("f3e5c7")))
	b.add_theme_stylebox_override("pressed",_style(Color("c4c6a1")))
	b.add_theme_stylebox_override("disabled",_style(Color("d8cbb1")))
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func _layout() -> void:
	if paper==null: return
	var screen: Vector2=get_viewport().get_visible_rect().size
	# Keep the journal in its authored aspect; logical size gives stable mobile targets.
	var factor: float=minf(screen.x/1420.0,screen.y/650.0)
	var origin: Vector2=(screen-Vector2(1420,650)*factor)*0.5
	paper.position=origin
	paper.size=Vector2(1420,650)*factor
	content.position=origin
	content.scale=Vector2.ONE*factor
	content.size=Vector2(1420,650)
	title_label.position=Vector2(180,78);title_label.size=Vector2(900,44)
	portrait.position=Vector2(158,168);portrait.size=Vector2(265,290)
	mood.position=Vector2(165,466);mood.size=Vector2(265,31)
	points.position=Vector2(130,509);points.size=Vector2(315,26)
	tally.position=Vector2(175,545);tally.size=Vector2(250,32)
	for i in tabs.size():
		tabs[i].position=Vector2(494+i*244,130);tabs[i].size=Vector2(228,75)
	var close_button: Button=content.get_node("CloseJournal")
	close_button.position=Vector2(1190,52);close_button.size=Vector2(126,75)
	body.position=Vector2(495,210);body.size=Vector2(808,350)
	notice.position=Vector2(492,566);notice.size=Vector2(808,36)

func is_open() -> bool: return visible

func open_journal() -> void:
	visible=true
	_reset_pet_reaction()
	response=""
	select_tab("together")
	_update_live()

func close_journal() -> void:
	if not visible: return
	visible=false
	_reset_pet_reaction()
	closed.emit()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_journal()
		get_viewport().set_input_as_handled()

func _pet() -> void:
	if not visible or pet_reaction >= 0: return
	play_pet_reaction(_next_pet_reaction())
	var mole: MoleCompanion=owner_ui.active_mole() if owner_ui != null else null
	if mole!=null: mole.pet()
	AudioDirector.play_ui("open")
	_update_live()

func select_tab(id: String) -> void:
	tab=id
	for child in body.get_children(): body.remove_child(child);child.queue_free()
	status=null;scroll=null
	for i in tabs.size():
		var active: bool=["together","skills","how"][i]==tab
		tabs[i].add_theme_stylebox_override("normal",_style(Color("c6cba9") if active else Color("e6d7b7")))
	if tab=="skills": _skills()
	elif tab=="how": _how()
	else: _together()
	_update_live()

func _together() -> void:
	var heading=_label(body,"Your little helper, ready to go.",25,true)
	heading.position=Vector2(0,0)
	var description=_label(body,"I follow, light the way and scoop up loose ore.\nTap the ground to send me somewhere!",19)
	description.position=Vector2(0,42);description.size=Vector2(800,44)
	status=_label(body,"",20,true);status.position=Vector2(0,88);status.size=Vector2(790,28)
	var home_label: String = "Tunnel Home" if RunState.current_scene == "endless" else "Lead me home"
	var definitions=[['fetch','Come here','Always ready'],['shake','Dig together','8-second recharge'],['ore_nose','Find ore','Sniff out a vein'],['homeward',home_label,'Bring your attached relic'],['echo','Find passage','Point the way deeper']]
	for i in definitions.size():
		var row: Array=definitions[i]
		var skill_id: String=row[0]
		var owned: bool=Skills.has_skill(skill_id)
		var b=_button(body,String(row[1]) if owned else String(row[1])+" · learn first",func(): command_requested.emit(skill_id))
		b.name="Command_"+skill_id
		b.position=Vector2((i%2)*406,120+(i/2)*77)
		b.size=Vector2(394,75)
		b.disabled=not owned
		if skill_id=="shake": b.tooltip_text="Tap an ordinary wall, or let me find one nearby."

func _how() -> void:
	var lines=[
		["1. Your shadow with little paws", "I follow and light nearby tunnels automatically. Loose ore goes straight into your backpack."],
		["2. A tap tells me where", "Tap open ground to send me. Drag to move yourself. Learn Earthshaker, then tap an ordinary wall to dig."],
		["3. Learn it once. Feel it every trip.", "'Always helping' skills work on their own. Command buttons live in Together. Mining earns paw points."],
		["4. Watch my little signals", "I tell you when I find, fetch or dig. My portrait shows what I am doing and when Earthshaker is ready."]]
	for i in lines.size():
		var h=_label(body,lines[i][0],21,true);h.position=Vector2(0,i*88)
		var d=_label(body,lines[i][1],17);d.position=Vector2(0,i*88+31);d.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;d.set_deferred("size",Vector2(800,53))

func _skills() -> void:
	scroll=preload("res://scripts/ui/touch_scroll_container.gd").new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",12);scroll.add_child(rows)
	for skill in Skills.SKILLS:
		var card=PanelContainer.new();card.add_theme_stylebox_override("panel",_style(Color("f7edda")));rows.add_child(card)
		var stack=VBoxContainer.new();stack.add_theme_constant_override("separation",6);card.add_child(stack)
		var skill_id: String=skill.id
		var owned: bool=Skills.has_skill(skill_id)
		var passive: bool=skill_id in ["lantern","fetch","trailrunner","big_paws","ore_nose","long_beam","teamwork"]
		_label(stack,String(skill.name)+("   ·   Always helping" if owned and passive else "   ·   Command ready" if owned else ""),21,true)
		var detail=_label(stack,String(skill.detail),17);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.custom_minimum_size.x=725
		if owned: continue
		var prereq: String=String(skill.requires)
		var locked: bool=not prereq.is_empty() and not Skills.has_skill(prereq)
		var enough: bool=RunState.gold>=int(skill.gold) and Skills.bond()>=int(skill.bond)
		var price: String="%d gold + %d paw points" % [int(skill.gold),int(skill.bond)]
		var why: String="Learn "+_skill_name(prereq)+" first" if locked else "Need %d gold · %d paw points" % [maxi(0,int(skill.gold)-RunState.gold),maxi(0,int(skill.bond)-Skills.bond())] if not enough else "Ready to learn"
		var row=HBoxContainer.new();stack.add_child(row)
		var label=_label(row,price+"\n"+why,16);label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var learn=_button(row,"Learn",func(): _learn(skill_id));learn.name="Learn_"+skill_id;learn.custom_minimum_size.x=135;learn.disabled=locked or not enough

func _skill_name(id: String) -> String:
	for skill in Skills.SKILLS:
		if String(skill.id)==id: return String(skill.name)
	return id

func _learn(id: String) -> void:
	var offset: int=scroll.scroll_vertical if scroll!=null else 0
	if Skills.learn(id):
		response=_skill_name(id)+" learned! "+("Try it in Together." if id in ["shake","echo","homeward"] else "Already helping you.")
		AudioDirector.play_economy("upgrade")
		var mole: MoleCompanion=owner_ui.active_mole()
		if mole!=null: mole.pet()
		select_tab("skills")
		if scroll!=null: scroll.set_deferred("scroll_vertical",offset)
	else: AudioDirector.play_blocked()

func _process(delta: float) -> void:
	if not visible: return
	clock+=delta
	if pet_reaction >= 0:
		_advance_pet_reaction(delta)
	else:
		portrait.position.y=168.0+sin(clock*2.3)*2.3
		portrait.rotation=sin(clock*1.1)*0.013
	refresh_clock-=delta
	if refresh_clock<=0.0: refresh_clock=0.20;_update_live()

func _update_live() -> void:
	if not visible or owner_ui==null: return
	var mole: MoleCompanion=owner_ui.active_mole()
	points.text="%d paw points" % Skills.bond()
	mood.text="Loves being with you" if pet_reaction >= 0 else "Your little mining buddy"
	if mole!=null:
		var ore_total: int=0
		var dig_total: int=0
		for world_name in ["surface_world","mine_world","depth_world","hub_world","deepheart_world","endless_world"]:
			var world: Node=owner_ui.main.get(world_name)
			var buddy: MoleCompanion=world.get_node_or_null("MoleCompanion") if world!=null else null
			if buddy!=null: ore_total+=buddy.collected_total;dig_total+=buddy.dug_total
		tally.text="%d fetched · %d dug" % [ore_total,dig_total]
		tally.tooltip_text="Your mole's help this session"
		if status!=null:
			status.text=mole.status_text()
			if Skills.has_skill("shake"): status.text+="  ·  "+("Dig ready" if mole.shake_cooldown<=0.0 else "Dig in %ds" % ceili(mole.shake_cooldown))
		var shake_button=body.get_node_or_null("Command_shake")
		if shake_button!=null and Skills.has_skill("shake"):
			shake_button.disabled=mole.shake_cooldown>0.0
			shake_button.text="Dig together" if mole.shake_cooldown<=0.0 else "Resting paws · %ds" % ceili(mole.shake_cooldown)
	notice.text=response if not response.is_empty() else "10 paw skills · swipe up for more. Mine together to earn paw points." if tab=="skills" else "Tap your buddy for a little love. Mine together to earn paw points."
