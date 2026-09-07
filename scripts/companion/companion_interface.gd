extends CanvasLayer

const Skills = preload("res://scripts/companion/mole_skills.gd")
var main: Node
var journal: CompanionJournal
var activity: Label
var button: TextureButton
var touch_start: Vector2 = Vector2(INF,INF)
var touch_index: int = -1
var gesture_dragged: bool = false
var last_world_identity: String=""
var last_touch_msec: int=-10000
var web_cancel_callback: JavaScriptObject
var web_canceled_touches: Dictionary={}

func _ready() -> void:
	main=get_parent()
	layer=18
	button=TextureButton.new()
	button.name="CompanionPortrait"
	button.texture_normal=preload("res://assets/companion/mole-hud.png")
	button.ignore_texture_size=true
	button.stretch_mode=TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.tooltip_text="Mining companion · skills and commands"
	button.pressed.connect(open_skills)
	add_child(button)
	journal=preload("res://scripts/companion/companion_journal.gd").new()
	journal.name="CompanionJournal"
	journal.owner_ui=self
	add_child(journal)
	journal.closed.connect(main._on_commerce_closed)
	journal.command_requested.connect(_command_skill)
	activity=Label.new()
	activity.mouse_filter=Control.MOUSE_FILTER_IGNORE
	activity.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	activity.add_theme_font_size_override("font_size",16)
	activity.add_theme_color_override("font_color",Color("fff0c5"))
	activity.add_theme_color_override("font_outline_color",Color("38261e"))
	activity.add_theme_constant_override("outline_size",5)
	add_child(activity)
	# Empty ground belongs to the movement pad; let the regular GUI reserve buttons.
	main.movement_pad.gui_input.connect(_on_world_gui_input)
	# Web maps touchcancel to an ordinary release. Keep the browser's cancellation.
	if OS.has_feature("web"):
		web_cancel_callback=JavaScriptBridge.create_callback(_on_web_touch_cancel)
		JavaScriptBridge.get_interface("window").addEventListener("touchcancel",web_cancel_callback,true)
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	var size: Vector2=get_viewport().get_visible_rect().size
	var mobile: bool=size.x/maxf(1.0,size.y)>1.9
	var extent: float=90.0 if mobile else 52.0
	button.position=Vector2(440.0 if mobile else 184.0,18.0 if mobile else 8.0)
	button.size=Vector2.ONE*extent
	activity.position=button.position+Vector2(extent+10,12)
	activity.size=Vector2(230 if mobile else 150,72)
	activity.add_theme_font_size_override("font_size",16 if mobile else 12)

func _process(_delta: float) -> void:
	var identity: String=String(main.phase)+":"+String(main.current_mine_id)+":"+str(RunState.endless_current_depth)
	if identity!=last_world_identity:
		last_world_identity=identity
		touch_index=-1
		touch_start=Vector2(INF,INF)
		var mole: MoleCompanion=active_mole()
		if mole!=null: mole.call_deferred("_spawn_beside_hero")
	button.visible=bool(main.game_started) and not bool(main.menu_open) and not bool(main.inventory_open) and not bool(main.conclusion_overlay.visible) and not main.call("_shop_panel_is_open") and not bool(main.orientation_guard_active)

	activity.visible=button.visible
	var active: MoleCompanion=active_mole()
	if active!=null and activity.visible:
		var next_text: String=active.direction_hint()
		if next_text.is_empty(): next_text=active.status_text()
		if Skills.has_skill("shake"): next_text+="\n"+("Dig ready" if active.shake_cooldown<=0.0 else "Dig in %ds" % ceili(active.shake_cooldown))
		if activity.text!=next_text: activity.text=next_text

func active_mole() -> MoleCompanion:
	var world: Node=main.get(String(main.phase)+"_world")
	return world.get_node_or_null("MoleCompanion") if is_instance_valid(world) else null

func open_skills() -> void:
	main.call("_open_commerce",Skills.config(),"companion")

func _command_skill(skill: String) -> void:
	if not Skills.has_skill(skill): return
	var mole: MoleCompanion=active_mole()
	if mole==null: return
	journal.close_journal()
	match skill:
		"fetch":
			mole.recall()
			mole.call("_react","Right beside you!",2.0)
		"shake":
			if not mole.shake_nearby(): mole.call("_react","Tap an ordinary wall",2.4)
		"ore_nose","echo","homeward":
			if not mole.scout(skill): mole.call("_react","Nothing reachable yet",2.4)

func _on_web_touch_cancel(arguments: Array) -> void:
	var changed: JavaScriptObject=arguments[0].changedTouches
	for index in range(int(changed.length)):
		web_canceled_touches[int(changed.item(index).identifier)]=true

func _ground_input_enabled() -> bool:
	return button.visible and not main.call("_shop_panel_is_open") and not bool(main.menu_open) and not bool(main.inventory_open) and main.movement_pad.is_visible_in_tree() and not bool(main.movement_pad.build_mode) and (main.developer_menu==null or not main.developer_menu.is_open())

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		last_touch_msec=Time.get_ticks_msec()
	if not _ground_input_enabled():
		touch_index=-1
		touch_start=Vector2(INF,INF)
		web_canceled_touches.clear()
	elif event is InputEventScreenTouch and not event.pressed and event.index!=touch_index:
		web_canceled_touches.erase(event.index)

func _on_world_gui_input(event: InputEvent) -> void:
	_unhandled_input(event)

func _unhandled_input(event: InputEvent) -> void:
	if not _ground_input_enabled(): return
	# Ignore the emulated mouse stream while a real finger owns the gesture.
	if (event is InputEventMouseButton or event is InputEventMouseMotion) and (touch_index>=0 or Time.get_ticks_msec()-last_touch_msec<750): return
	var point: Vector2
	var released: bool=false
	if event is InputEventScreenTouch:
		if event.pressed:
			if touch_index>=0: return
			touch_start=event.position
			touch_index=event.index
			gesture_dragged=false
			return
		var canceled: bool=event.canceled or web_canceled_touches.has(event.index)
		web_canceled_touches.erase(event.index)
		if event.index!=touch_index: return
		touch_index=-1
		point=event.position
		released=not canceled and not gesture_dragged and point.distance_to(touch_start)<16.0
	elif event is InputEventScreenDrag:
		if event.index==touch_index and event.position.distance_to(touch_start)>=16.0: gesture_dragged=true
		return
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			touch_start=event.position
			gesture_dragged=false
			return
		point=event.position
		released=not gesture_dragged and point.distance_to(touch_start)<16.0
	elif event is InputEventMouseMotion:
		if event.position.distance_to(touch_start)>=16.0: gesture_dragged=true
		return
	else: return
	touch_start=Vector2(INF,INF)
	if not released: return
	var mole: MoleCompanion=active_mole()
	if mole==null: return
	var world_point: Vector2=mole.world.get_canvas_transform().affine_inverse()*point
	# Do not consume the release: the joystick must also stop the hero.
	mole.command(world_point)
