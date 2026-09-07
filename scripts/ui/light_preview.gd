extends VBoxContainer
## A separate cave viewport uses the real headlamp renderer and current hero.
const Lamp = preload("res://scripts/lighting/headlamp_beam.gd")
var viewport: SubViewport
var lamp: HeadlampBeam
var style: String
var current_level: int
var upgraded_level: int
var showing_level: int
var before_button: Button
var after_button: Button
var _thumbnail: bool = false

func configure(item: Dictionary, thumbnail: bool = false) -> void:
	style = String(item.get("light_preview", "standard"))
	current_level = int(item.get("light_level", 1))
	upgraded_level = int(item.get("compare_level", current_level))
	_thumbnail = thumbnail
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 3)
	if viewport == null: _build()
	if before_button != null:
		before_button.get_parent().visible = upgraded_level > current_level
		before_button.text = "CURRENT · LV %d" % current_level
		after_button.text = "UPGRADED · LV %d" % upgraded_level
	show_level(upgraded_level)

func _build() -> void:
	if not _thumbnail:
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(row)
		before_button = Button.new()
		after_button = Button.new()
		for button in [before_button, after_button]:
			button.custom_minimum_size = Vector2(160, 42)
			button.add_theme_font_size_override("font_size", 16)
			row.add_child(button)
		before_button.pressed.connect(func(): show_level(current_level))
		after_button.pressed.connect(func(): show_level(upgraded_level))
	viewport = SubViewport.new()
	viewport.size = Vector2i(440, 480) if _thumbnail else Vector2i(1100, 1200)
	viewport.world_2d = World2D.new()
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE if _thumbnail else SubViewport.UPDATE_WHEN_VISIBLE
	add_child(viewport)
	var world: Node2D = Node2D.new()
	viewport.add_child(world)
	if _thumbnail: world.scale = Vector2(0.4, 0.4)
	var floor_sprite: Sprite2D = Sprite2D.new()
	floor_sprite.texture = load("res://assets/mossvein/cave-floor.png")
	floor_sprite.centered = false
	floor_sprite.region_enabled = true
	floor_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	floor_sprite.region_rect = Rect2(0, 0, 1100, 1200)
	world.add_child(floor_sprite)
	var ambient: CanvasModulate = CanvasModulate.new()
	ambient.color = Color(0.13, 0.15, 0.16)
	world.add_child(ambient)
	for position_value in [Vector2(380, 600), Vector2(650, 635), Vector2(750, 740)]:
		var ore: Sprite2D = Sprite2D.new()
		ore.texture = load("res://assets/minerals/copper-node.png")
		ore.position = position_value
		ore.scale = Vector2.ONE * 60.0 / ore.texture.get_width()
		world.add_child(ore)
	var holder: Node2D = Node2D.new()
	world.add_child(holder)
	var hero = preload("res://scripts/ui/outfit_preview.gd").new()
	hero.position = Vector2(20, 564)
	hero.size = Vector2(160, 160)
	holder.add_child(hero)
	hero.configure(String(RunState.endless_loadout_status().get("outfit", "miner")), false, "right")
	lamp = Lamp.new()
	lamp.position = Vector2(117, 600)
	holder.add_child(lamp)
	var picture: TextureRect = TextureRect.new()
	picture.texture = viewport.get_texture()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
	picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(picture)

func show_level(level: int) -> void:
	showing_level = level
	lamp.configure_preview(style, level)
	if before_button != null:
		before_button.disabled = level == current_level
		after_button.disabled = level == upgraded_level
	if _thumbnail: viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
