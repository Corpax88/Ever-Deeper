extends "res://tools/native_motion_ingame_pilot/studies/overhead_swing_18/loop_visual.gd"
## Same-facing ready pose and real-frame cancellation; isolated Worn/up study.
var _mode := "idle"
var _shown_progress := 0.0
var _return_direction := 0.0
var _restart_source := -1.0
var _restart_clock := 0.0
var _walk_atlas: Texture2D
var _walk_anchor := Vector2.ZERO
var _walk_elapsed := 0.0
var _walk_active := false
var _walk_cell := -1
var _unsupported: Array = []

func configure_walk(directory: String) -> void:
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("atlas.json")))
	assert(info.complete and int(info.source_cell) == 31 and is_equal_approx(float(info.duration),.20))
	assert(FileAccess.get_sha256(directory.path_join("atlas.png")) == info.atlas_sha256)
	_walk_atlas = ImageTexture.create_from_image(Image.load_from_file(directory.path_join("atlas.png")))
	_walk_anchor = Vector2(float(info.anchor[0]),float(info.anchor[1]))

func _ready() -> void:
	super._ready()
	# Decide once after all ordinary gameplay/controller state packets.
	process_priority = 1000

func _draw_frame(delta: float) -> void:
	if not study_enabled or study_atlas == null:
		super._draw_frame(delta)
		return
	if delta <= 0.0: return
	if moving and _mode == "mine" and _walk_atlas != null:
		# Exact presented source and ongoing distance clock; never guess a bridge.
		if study_frame == 31 and direction_name == "down" and active_gear == "worn" and active_endless_outfit_style == "miner" and absf(_walk_phase-340.0/60.0/144.0)<.0001:
			_walk_active = true
			_walk_elapsed = 0.0
			_mode = "walk_bridge"
		else:
			_unsupported.append({"cell":study_frame,"direction":direction_name,"walk_phase":_walk_phase})
	if _walk_active:
		_walk_elapsed += delta
		if moving and direction_name == "down" and active_gear == "worn" and active_endless_outfit_style == "miner" and _walk_elapsed <= .200001:
			_walk_cell = clampi(roundi(_walk_elapsed*60.0),0,12)
			study_frame = 100+_walk_cell
			study_visible = true
			study_impact = false
			_sprite.texture = _walk_atlas
			_sprite.material = null
			_sprite.region_rect = Rect2(Vector2(_walk_cell % 10,_walk_cell / 10)*160.0,Vector2(160,160))
			_sprite.position = Vector2(0,GROUND_Y)-_walk_anchor
			_sprite.scale = Vector2.ONE
			return
		_walk_active = false
	if moving or direction_name != "up" or active_gear != "worn" or active_endless_outfit_style != "miner":
		_mode = "legacy"
		_restart_source = -1.0
		study_impact = false
		# Disable the inherited18B substitution too; otherwise unsupported
		# up-facing tools would accidentally display the Worn preview.
		study_enabled = false
		super._draw_frame(delta)
		study_enabled = true
		return
	if _impact_pending and Engine.get_frames_drawn() != _impact_presented_frame:
		_impact_pending = false
	study_impact = _impact_pending
	if mining:
		if _mode == "return":
			_restart_source = _shown_progress
			_restart_clock = 0.0
		_mode = "mine"
		var requested := mining_progress
		if _restart_source >= 0.0:
			_restart_clock += delta
			var weight := smoothstep(0.0, 0.10, _restart_clock)
			# After an actual hit, continue withdrawal forward through ready.
			# Before a hit, retrace preparation without crossing contact.
			requested = lerpf(_restart_source, requested+(1.0 if _restart_source >= .42 else 0.0), weight)
			requested = fposmod(requested,1.0)
			if weight >= 1.0: _restart_source = -1.0
		_shown_progress = .42 if study_impact else requested
		if not study_impact and mining_progress < .42 and not (_restart_source >= .42 and requested >= .42):
			_shown_progress = minf(_shown_progress, .40)
	elif _mode == "mine":
		_mode = "return"
		_return_direction = -1.0 if _shown_progress < .42 else 1.0
		_restart_source = -1.0
	if _mode == "return":
		_shown_progress += _return_direction * delta / .68
		if _shown_progress <= 0.0 or _shown_progress >= .88:
			_shown_progress = 0.0
			_mode = "idle"
	if _mode == "legacy" or _mode == "idle":
		_mode = "idle"
		_shown_progress = 0.0
	study_frame = clampi(roundi(_shown_progress * 50.0), 0, 49)
	study_visible = true
	_sprite.texture = study_atlas
	_sprite.material = null
	_sprite.region_rect = Rect2(Vector2(study_frame % 10, study_frame / 10) * 160.0, Vector2(160, 160))
	_sprite.position = Vector2(0, GROUND_Y) - study_anchor
	_sprite.scale = Vector2.ONE

func transition_snapshot() -> Dictionary:
	return {"mode":_mode,"shown_progress":_shown_progress,"return_direction":_return_direction,
		"restart_blend":_restart_source >= 0.0,"walk_bridge_cell":_walk_cell,
		"walk_bridge_active":_walk_active,"unsupported_walk_requests":_unsupported.duplicate(true),
		"walk_scope":"exact Worn/up cell31 to down, first stride only"}
