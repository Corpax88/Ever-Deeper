extends Control
## Approved full-resolution portrait, shared by wardrobe cards and the large preview.
const Hero = preload("res://scripts/player/player_visual.gd")
const Portrait = preload("res://assets/hero/dad/wardrobe/crossed-arms-v2.png")
const ClothShader = preload("res://scripts/ui/wardrobe_portrait_cloth.gdshader")
# Transparent padding is excluded from layout; original image bytes remain untouched.
const VISIBLE_BOUNDS: = Rect2(348, 157, 920, 1769)
var outfit: String = "miner"
var _sprite: Sprite2D

func configure(value: String, _animated: bool = false) -> void:
	outfit = value
	if _sprite == null:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_sprite = Sprite2D.new()
		_sprite.texture = Portrait
		_sprite.region_enabled = true
		_sprite.region_filter_clip_enabled = true
		_sprite.region_rect = VISIBLE_BOUNDS
		var cloth: = ShaderMaterial.new()
		cloth.shader = ClothShader
		_sprite.material = cloth
		add_child(_sprite)
		resized.connect(_fit)
	_sprite.material.set_shader_parameter("cloth_color", Hero.OUTFIT_COLORS.get(outfit, Hero.OUTFIT_COLORS.miner))
	_sprite.material.set_shader_parameter("recolor", 0.0 if outfit == "miner" else 1.0)
	_fit()

func _fit() -> void:
	if _sprite == null: return
	_sprite.position = size * 0.5
	_sprite.scale = Vector2.ONE * 0.98 * minf(size.x / VISIBLE_BOUNDS.size.x, size.y / VISIBLE_BOUNDS.size.y)
