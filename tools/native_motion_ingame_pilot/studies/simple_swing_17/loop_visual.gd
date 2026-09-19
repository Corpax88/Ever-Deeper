extends "res://scripts/player/player_visual.gd"
## Isolated repeated-strike preview. Entry/exit remain explicitly unaccepted.
var study_atlas: Texture2D
var study_anchor := Vector2.ZERO
var study_enabled := false
var study_frame := -1
var study_impact := false
var study_visible := false

func configure(directory: String) -> void:
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("atlas.json")))
	assert(FileAccess.get_sha256(directory.path_join("atlas.png")) == info.atlas_sha256)
	study_atlas = ImageTexture.create_from_image(Image.load_from_file(directory.path_join("atlas.png")))
	study_anchor = Vector2(float(info.anchor[0]), float(info.anchor[1]))

func _draw_frame(delta: float) -> void:
	if not study_enabled or study_atlas == null or not mining or moving or direction_name != "up":
		if study_visible:
			_last_frame = -1
			study_visible = false
			_sprite.material = _cloth
		super._draw_frame(delta)
		return
	if _impact_pending and Engine.get_frames_drawn() != _impact_presented_frame:
		_impact_pending = false
	study_impact = _impact_pending
	study_frame = 21 if study_impact else clampi(roundi(mining_progress * 50.0), 0, 49)
	if not study_impact and mining_progress < .42:
		study_frame = mini(study_frame, 20)
	study_visible = true
	_sprite.texture = study_atlas
	_sprite.material = null
	_sprite.region_rect = Rect2(Vector2(study_frame % 10, study_frame / 10) * 160.0, Vector2(160, 160))
	_sprite.position = Vector2(0, GROUND_Y) - study_anchor
	_sprite.scale = Vector2.ONE
