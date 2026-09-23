extends Control
## Approved 22 September Skills menu. All text, controls and progress are live.
signal close_requested
signal inventory_requested
signal settings_requested
signal map_requested

const ART = "res://assets/ui/skills/"
const FONT = preload("res://assets/ui/fonts/EBGaramond.ttf")
const CREAM = Color("f3d5b5")
const COPPER = Color("d49063")
const ORANGE = Color("ff9c43")
var root: Control
var backdrop: TextureRect
var portrait: TextureRect
var plate: Control
var title: Label
var location_plate: Control
var location: Label
var depth: Label
var resources: Control
var resource_labels: Array[Label] = []
var nav: Array[Button] = []
var close_button: Button
var rows: Array[Dictionary] = []
var stamina_row: Dictionary
var map_view: Control
var _textures: Dictionary = {}
var _elapsed: float = 0.0
var _map_active: bool = false
var stat_tip: Control
var _tip_title: Label
var _tip_body: Label
var _tip_id: String = ""
var _tip_owner: Control
var _tip_delay: float = 0.0
var _tip_touch: int = -1
var _tip_touch_start: Vector2
var _last_touch_msec: int = -10000

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 110
	root = Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	backdrop = _image(root, "mine-backdrop-v1.png")
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait = _image(root, "miner-mole-portrait-v1.png")
	portrait.texture = _atlas("miner-mole-portrait-v1.png", Rect2(175, 8, 943, 1230))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	location_plate = _frame(root, false)
	var location_icon: TextureRect = _image(location_plate, "icons/location.svg")
	location_icon.position = Vector2(20, 17)
	location_icon.size = Vector2(50, 50)
	depth = _label(location_plate, "", 29)
	depth.position = Vector2(80, 10)
	depth.size = Vector2(156, 35)
	location = _label(location_plate, "", 27)
	location.modulate = COPPER
	location.position = Vector2(80, 43)
	location.size = Vector2(160, 32)
	for id in ["bag", "skills", "map", "settings"]:
		var button: Button = _button(root, id)
		nav.append(button)
		nav[0].tooltip_text = "Inventory"
	nav[1].tooltip_text = "Skills"
	nav[2].tooltip_text = "Map"
	nav[3].tooltip_text = "Settings"
	nav[0].pressed.connect(func(): inventory_requested.emit())
	nav[1].pressed.connect(show_skills)
	nav[2].pressed.connect(func(): map_requested.emit())
	nav[3].pressed.connect(func(): settings_requested.emit())
	resources = _frame(root, false)
	var drop_paths: Array[String] = ["res://assets/drops/copper-drop.png", "res://assets/drops/ambercore-drop.png", "res://assets/drops/lunacore-drop.png"]
	for i in 3:
		var icon: TextureRect = _image(resources, "")
		icon.texture = load(drop_paths[i])
		icon.position = Vector2(12 + 104 * i, 16)
		icon.size = Vector2(36, 42)
		var count: Label = _label(resources, "0", 25)
		count.position = Vector2(50 + 104 * i, 18)
		count.size = Vector2(58, 38)
		resource_labels.append(count)
	close_button = _button(root, "close")
	close_button.tooltip_text = "Return to mine"
	close_button.pressed.connect(func(): close_requested.emit())
	plate = _frame(root, true)
	title = _label(plate, "Skills", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for id in ["mining", "running", "carrying", "prospecting"]:
		rows.append(_make_row(plate, id))
	stamina_row = _make_row(plate, "stamina")
	stamina_row.level.visible = false
	stat_tip = _frame(root, false)
	stat_tip.name = "StatTooltip"
	stat_tip.z_index = 5
	stat_tip.get_node("InsetShade").color = Color("1e1713")
	_tip_title = _label(stat_tip, "", 34)
	_tip_body = _label(stat_tip, "", 28)
	_tip_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_body.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	stat_tip.hide()
	visibility_changed.connect(_hide_stat_tip)
	get_viewport().size_changed.connect(_layout)
	visible = false
	_layout()

func open_panel() -> void:
	move_to_front()
	visible = true
	show_skills()
	refresh()
	_layout()
	close_button.grab_focus()

func close_panel() -> void:
	visible = false

func show_skills() -> void:
	_hide_stat_tip()
	_map_active = false
	if is_instance_valid(map_view): map_view.queue_free()
	map_view = null
	title.text = "Skills"
	for row in rows: row.node.visible = true
	stamina_row.node.visible = true
	_select_tab(1)
	_layout()

func show_map(source: Control) -> void:
	if not is_instance_valid(source): return
	show_skills()
	_map_active = true
	title.text = "Map"
	for row in rows: row.node.visible = false
	stamina_row.node.visible = false
	map_view = load("res://scripts/ui/minimap_overlay.gd").new()
	plate.add_child(map_view)
	map_view.z_index = 1
	map_view.get_viewport().size_changed.disconnect(map_view._apply_layout)
	map_view.set_process(false)
	map_view.set_snapshot(source._phase, source._location_name, source._player_position,
		source._world_rect, source._view_rect, source._objective_position, source._has_objective)
	map_view._panel_style.bg_color = Color("201a17")
	_select_tab(2)
	_layout()

func _process(delta: float) -> void:
	if not visible: return
	if is_instance_valid(_tip_owner) and not stat_tip.visible:
		_tip_delay -= delta
		if _tip_delay <= 0.0: _show_stat_tip()
	_elapsed += delta
	if _elapsed >= 0.2:
		_elapsed = 0.0
		refresh()

func refresh() -> void:
	var data: Array = RunState.miner_skill_rows()
	for i in data.size():
		var info: Dictionary = data[i]
		rows[i].level.text = str(info.level)
		rows[i].bar.value = float(info.ratio) * 100.0
		rows[i].xp.text = "100 / 100" if info.maxed else "%d / %d" % [info.xp, info.next]
	stamina_row.bar.value = RunState.stamina_value()
	stamina_row.xp.text = "%d / 100" % ceili(RunState.stamina_value())
	var ids: Array[String] = ["copper", "ambercore", "lunacore"]
	for i in 3: resource_labels[i].text = _compact(int(RunState.cargo.get(ids[i], 0)))
	var scene: String = String(RunState.current_scene)
	var current_depth: int = int(RunState.current_depth)
	if scene == "endless":
		current_depth = int(RunState.endless_current_depth)
		location.text = "The Deep"
	elif scene in RunState.MINE_IDS:
		location.text = String(GameData.mine(scene).get("name", scene)).replace(" MINE", "").replace(" Mine", "").capitalize()
	else:
		location.text = {"surface": "Surface", "hub": "Base Hub", "deepheart": "Deepheart"}.get(scene, "Mossvein")
	depth.text = "Depth %d" % current_depth if scene != "surface" and scene != "hub" else "Ever-Deeper"

func _layout() -> void:
	if root == null: return
	_hide_stat_tip()
	var viewport_size: Vector2 = get_viewport_rect().size
	var square: bool = viewport_size.x / maxf(1.0, viewport_size.y) < 1.5
	var design_height: float = 1254.0 if square else 720.0
	var zoom: float = viewport_size.y / design_height
	root.scale = Vector2.ONE * zoom
	root.size = viewport_size / zoom
	var w: float = root.size.x
	var h: float = root.size.y
	backdrop.size = root.size
	location_plate.position = Vector2(26 if square else 58, 18)
	_size_frame(location_plate, Vector2(245, 88))
	var nav_size: float = 88.0
	for i in 4:
		nav[i].position = Vector2(w * 0.5 - 182 + i * 94, 18)
		nav[i].size = Vector2.ONE * nav_size
	resources.position = Vector2(w - 436, 23)
	_size_frame(resources, Vector2(330, 78))
	close_button.position = Vector2(w - 100, 18)
	close_button.size = Vector2(88, 88)
	if square:
		portrait.position = Vector2(w * 0.105, 476)
		portrait.size = Vector2(w * 0.46, 634)
		plate.position = Vector2(w * 0.575, 482)
		_size_frame(plate, Vector2(w * 0.408, 610))
	else:
		portrait.position = Vector2(w * 0.105, 132)
		portrait.size = Vector2(w * 0.395, 557)
		plate.position = Vector2(w * 0.532, 135)
		_size_frame(plate, Vector2(w * 0.42, 548))
	var pw: float = plate.size.x
	var ph: float = plate.size.y
	title.position = Vector2(64, 22)
	title.size = Vector2(pw - 128, 56)
	var row_height: float = (ph - 200.0) / 4.0
	for i in 4:
		_layout_row(rows[i], Rect2(24, 86 + i * row_height, pw - 48, row_height - 3))
	_layout_row(stamina_row, Rect2(24, ph - 110, pw - 48, 88))
	if is_instance_valid(map_view):
		map_view._map_rect = Rect2(32, 94, pw - 64, ph - 130)
		map_view.queue_redraw()

func _make_row(parent: Control, id: String) -> Dictionary:
	var node: Control = _frame(parent, false)
	node.name = id.capitalize()
	node.mouse_filter = Control.MOUSE_FILTER_STOP
	node.focus_mode = Control.FOCUS_ALL
	node.mouse_default_cursor_shape = Control.CURSOR_HELP
	node.mouse_entered.connect(func():
		if Time.get_ticks_msec() - _last_touch_msec > 750: _queue_stat_tip(id, node, 0.35)
	)
	node.mouse_exited.connect(func():
		if _tip_touch < 0 and _tip_owner == node: _hide_stat_tip()
	)
	node.focus_entered.connect(func():
		if Time.get_ticks_msec() - _last_touch_msec > 750: _queue_stat_tip(id, node, 0.0)
	)
	node.focus_exited.connect(func():
		if _tip_owner == node: _hide_stat_tip()
	)
	var icon: TextureRect = _image(node, "icons/" + ("bag" if id == "carrying" else id) + ".svg")
	var tile: Control = _frame(node, false)
	tile.name = "IconFrame"
	node.move_child(tile, 1)
	var label: Label = _label(node, id.capitalize(), 30)
	var level: Label = _label(node, "0", 35)
	level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var xp: Label = _label(node, "0 / 100", 22)
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color("130e0c")
	track.border_color = Color("70503c")
	track.set_border_width_all(1)
	track.set_corner_radius_all(5)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = ORANGE
	fill.border_color = Color("ffbd79")
	fill.set_border_width_all(1)
	fill.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", track)
	bar.add_theme_stylebox_override("fill", fill)
	node.add_child(bar)
	return {"node": node, "icon": icon, "label": label, "level": level, "xp": xp, "bar": bar}

func _layout_row(row: Dictionary, rect: Rect2) -> void:
	row.node.position = rect.position
	_size_frame(row.node, rect.size)
	var h: float = rect.size.y
	var tile: Control = row.node.get_node("IconFrame")
	tile.position = Vector2(10, 8)
	_size_frame(tile, Vector2.ONE * (h - 16))
	row.icon.position = Vector2(21, 18)
	row.icon.size = Vector2(h - 37, h - 37)
	var x: float = h + 9
	row.label.position = Vector2(x, 2)
	row.label.size = Vector2(rect.size.x - x - 76, 40)
	row.level.position = Vector2(rect.size.x - 69, 3)
	row.level.size = Vector2(49, 42)
	row.bar.position = Vector2(x, h * 0.46)
	row.bar.size = Vector2(rect.size.x - x - 79, 17)
	row.xp.position = Vector2(x, h * 0.46 + 14)
	row.xp.size = Vector2(rect.size.x - x - 38, 26)

func _select_tab(index: int) -> void:
	for i in nav.size():
		nav[i].modulate = Color(1.15, 1.02, 0.76) if i == index else Color(0.90, 0.87, 0.84)
		nav[i].set_pressed_no_signal(i == index)

func _frame(parent: Control, iron: bool) -> Control:
	var node: Control = Control.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	var frame: NinePatchRect = NinePatchRect.new()
	frame.name = "Frame"
	frame.texture = _atlas("iron-panel-v1.png", Rect2(25, 33, 1095, 1276)) if iron else _atlas("copper-button-v1.png", Rect2(104, 128, 1044, 982))
	frame.scale = Vector2.ONE * (0.36 if iron else 0.075)
	frame.patch_margin_left = 174 if iron else 160
	frame.patch_margin_right = 174 if iron else 160
	frame.patch_margin_top = 174 if iron else 160
	frame.patch_margin_bottom = 174 if iron else 160
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not iron: frame.modulate = Color(0.62, 0.56, 0.53)
	node.add_child(frame)
	var shade: ColorRect = ColorRect.new()
	shade.name = "InsetShade"
	shade.color = Color(0.04, 0.025, 0.02, 0.32 if iron else 0.48)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.add_child(shade)
	return node

func _size_frame(node: Control, target: Vector2) -> void:
	node.size = target
	var frame: NinePatchRect = node.get_node("Frame")
	frame.size = target / frame.scale
	var shade: ColorRect = node.get_node("InsetShade")
	shade.position = Vector2(18, 18)
	shade.size = (target - Vector2(36, 36)).max(Vector2.ZERO)

func _button(parent: Control, id: String) -> Button:
	var button: Button = Button.new()
	button.name = id.capitalize() + "Button"
	button.toggle_mode = id == "skills" or id == "map"
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	var focus: StyleBoxFlat = StyleBoxFlat.new()
	focus.bg_color = Color(1.0, 0.6, 0.25, 0.12)
	focus.border_color = ORANGE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(10)
	button.add_theme_stylebox_override("focus", focus)
	parent.add_child(button)
	var frame: TextureRect = _image(button, "")
	frame.texture = _atlas("copper-button-v1.png", Rect2(104, 128, 1044, 982))
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var icon: TextureRect = _image(button, "icons/" + id + ".svg")
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 22
	icon.offset_top = 21
	icon.offset_right = -22
	icon.offset_bottom = -21
	return button

func _image(parent: Control, file: String) -> TextureRect:
	var node: TextureRect = TextureRect.new()
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not file.is_empty(): node.texture = _texture(file)
	parent.add_child(node)
	return node

func _texture(file: String) -> Texture2D:
	if not _textures.has(file): _textures[file] = load(ART + file)
	return _textures[file]

func _atlas(file: String, region: Rect2) -> AtlasTexture:
	var texture: AtlasTexture = AtlasTexture.new()
	texture.atlas = _texture(file)
	texture.region = region
	texture.filter_clip = true
	return texture

func _label(parent: Control, text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", CREAM)
	label.add_theme_color_override("font_shadow_color", Color("130b07"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	parent.add_child(label)
	return label

func _compact(value: int) -> String:
	return "%.1fk" % (value / 1000.0) if value >= 10000 else str(value)

func _input(event: InputEvent) -> void:
	if not visible: return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		_last_touch_msec = Time.get_ticks_msec()
	if event is InputEventScreenTouch:
		if event.pressed:
			if _tip_touch >= 0: return
			_hide_stat_tip()
			if _map_active: return
			for row in rows + [stamina_row]:
				if row.node.get_global_rect().has_point(event.position):
					_queue_stat_tip(String(row.node.name).to_lower(), row.node, 0.45)
					_tip_touch = event.index
					_tip_touch_start = event.position
					return
		elif event.index == _tip_touch:
			_hide_stat_tip()
	elif event is InputEventScreenDrag and event.index == _tip_touch:
		if event.position.distance_to(_tip_touch_start) > 20.0 * root.scale.x:
			_hide_stat_tip()

func _queue_stat_tip(id: String, target: Control, delay: float) -> void:
	_hide_stat_tip()
	_tip_id = id
	_tip_owner = target
	_tip_delay = delay

func _hide_stat_tip() -> void:
	if is_instance_valid(stat_tip): stat_tip.hide()
	_tip_owner = null
	_tip_id = ""
	_tip_touch = -1

func _show_stat_tip() -> void:
	if not is_instance_valid(_tip_owner) or not _tip_owner.is_visible_in_tree():
		_hide_stat_tip()
		return
	_tip_title.text = _tip_id.capitalize()
	var level: int = RunState.miner_skill_level(_tip_id) if _tip_id != "stamina" else 0
	match _tip_id:
		"mining":
			_tip_body.text = "Train by mining rock.\nMining uses %.1f%% less stamina at your level.\nMaximum reduction: 30%%." % (level * 0.3)
		"running":
			_tip_body.text = "Train by walking or running.\nMovement uses %.1f%% less stamina at your level.\nMaximum reduction: 30%%." % (level * 0.3)
		"carrying":
			_tip_body.text = "Train by moving with items in your bag.\nThe extra stamina cost of carrying is %.1f%% lower.\nMaximum reduction: 50%%." % (level * 0.5)
		"prospecting":
			_tip_body.text = "Gain XP for every resource mined.\nTracks your prospecting experience.\nNo extra loot bonus yet."
		"stamina":
			_tip_body.text = "Used while moving and mining.\nRest without moving or mining to recover.\nBelow 15, movement and mining power gradually fall to 75%."
	var width: float = minf(440.0, root.size.x - 40.0)
	_tip_title.position = Vector2(24, 18)
	_tip_title.size = Vector2(width - 48, 44)
	_tip_body.position = Vector2(24, 66)
	_tip_body.size = Vector2(width - 48, 0)
	var height: float = _tip_body.get_minimum_size().y + 90.0
	_size_frame(stat_tip, Vector2(width, height))
	# Keep the hovered row and held finger clear. The popup stays on screen.
	var anchor: Rect2 = Rect2(_tip_owner.global_position / root.scale, _tip_owner.size)
	var x: float = plate.position.x - width - 18.0
	if x < 16.0: x = root.size.x - width - 16.0
	stat_tip.position = Vector2(clampf(x, 16.0, root.size.x - width - 16.0),
		clampf(anchor.get_center().y - height * 0.5, 116.0, root.size.y - height - 16.0))
	stat_tip.show()

func tooltip_snapshot() -> Dictionary:
	return {"visible": stat_tip.visible, "id": _tip_id, "text": _tip_body.text,
		"rect": stat_tip.get_global_rect()}

func debug_snapshot() -> Dictionary:
	return {"visible": visible, "map": _map_active, "skills": RunState.miner_skill_rows(),
		"stamina": RunState.stamina_value(), "plate": plate.get_global_rect(),
		"close": close_button.get_global_rect(), "skills_button": nav[1].get_global_rect()}
