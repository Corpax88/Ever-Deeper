extends Control
## Uses the production hero frame and clothing mask without changing the loadout.
const Hero = preload("res://scripts/player/player_visual.gd")
const Gear = preload("res://scripts/player/hero_gear.gd")
var outfit: String = "miner"
var animate: bool = false
var _sprite: Sprite2D
var _manifest: Dictionary = {}
var _clock: float = 0.0
var _cell: Vector2 = Vector2(160, 160)

func configure(value: String, animated: bool = false) -> void:
	outfit = value
	animate = animated
	if _sprite == null:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_sprite = Sprite2D.new()
		_sprite.region_enabled = true
		_sprite.region_filter_clip_enabled = true
		add_child(_sprite)
		resized.connect(_fit)
	var status: Dictionary = RunState.endless_loadout_status()
	var gear: String = Gear.resolve_tool(RunState.pickaxe_level, RunState.drill_level, RunState.starforge_variant, String(status.get("tool", "original")))
	var root: String = Hero.ROOT + gear + "/"
	_manifest = JSON.parse_string(FileAccess.get_file_as_string(root + "manifest.json"))
	_cell = Vector2(_manifest.cell[0], _manifest.cell[1])
	_sprite.texture = load(root + "down.png")
	var cloth: ShaderMaterial = ShaderMaterial.new()
	cloth.shader = Hero.ClothShader
	cloth.set_shader_parameter("cloth_mask", load(root + "down-cloth.png"))
	cloth.set_shader_parameter("cloth_color", Hero.OUTFIT_COLORS.get(outfit, Hero.OUTFIT_COLORS.miner))
	cloth.set_shader_parameter("recolor", 0.0 if outfit == "miner" else 1.0)
	_sprite.material = cloth
	_frame(0)
	_fit()
	set_process(animate)

func _fit() -> void:
	if _sprite == null: return
	_sprite.position = size * 0.5
	_sprite.scale = Vector2.ONE * 1.2 * minf(size.x / _cell.x, size.y / _cell.y)

func _process(delta: float) -> void:
	if not is_visible_in_tree() or _manifest.is_empty(): return
	_clock = fposmod(_clock + delta, 3.6)
	var index: int = 0
	for i in Array(_manifest.states.idle.times).size():
		if float(_manifest.states.idle.times[i]) <= _clock: index = i
	_frame(index)

func _frame(index: int) -> void:
	var columns: int = int(_manifest.columns)
	_sprite.region_rect = Rect2(Vector2(index % columns, index / columns) * _cell, _cell)
