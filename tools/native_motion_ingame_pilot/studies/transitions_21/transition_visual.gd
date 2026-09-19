extends "res://tools/native_motion_ingame_pilot/studies/transition_19/transition_visual.gd"
## Exact observed edges on the approved20 loop; never chooses a nearby edge.
var _bank: Dictionary = {}
var _edge_atlas: Texture2D
var _edge_name := ""
var _edge_elapsed := 0.0
var _edge_step := -1
var _edge_finished := false
var _edge_events: Array = []
var _loop_hash := ""
var _walk_hash := ""
var _source_hash := ""

func configure(directory: String) -> void:
	super.configure(directory)
	_loop_hash = FileAccess.get_sha256(directory.path_join("atlas.png"))

func configure_walk(directory: String) -> void:
	super.configure_walk(directory)
	_walk_hash = FileAccess.get_sha256(directory.path_join("atlas.png"))

func configure_bank(directory: String) -> void:
	_bank = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("atlas.json")))
	assert(_bank.complete and _bank.flow_atlas_sha256 == _loop_hash and _bank.walk_atlas_sha256 == _walk_hash)
	assert(FileAccess.get_sha256(directory.path_join("atlas.png")) == _bank.atlas_sha256)
	_edge_atlas = ImageTexture.create_from_image(Image.load_from_file(directory.path_join("atlas.png")))
	_source_hash = FileAccess.get_sha256("res://tools/native_motion_ingame_pilot/studies/transitions_21/transition_visual.gd")

func _begin_edge(name: String) -> void:
	_edge_name = name
	_edge_elapsed = 0.0
	_edge_step = 0
	_edge_finished = false
	_edge_events.append({"event":"start","edge":name,"source_cell":study_frame,"legacy_frame":_last_local_frame})
	_walk_active = false
	_walk_settle = false
	_restart_source = -1.0
	_mode = "exact_edge"

func _draw_frame(delta: float) -> void:
	if delta <= 0.0: return
	if _bank.is_empty() or not study_enabled or active_gear != "worn" or active_endless_outfit_style != "miner":
		super._draw_frame(delta)
		return
	if _edge_finished:
		_edge_finished = false
		_edge_name = ""
	if _edge_name.is_empty():
		if _walk_active and _walk_cell == 6 and not moving and not mining and direction_name == "down":
			_begin_edge("interrupt")
		elif _mode == "legacy" and _last_state == "walk" and _last_direction == "up" and _last_local_frame == 15 and not moving and mining and direction_name == "up" and absf(mining_progress-1.0/60.0/.68)<.001:
			_begin_edge("walk-entry")
	if not _edge_name.is_empty():
		var edge: Dictionary = _bank.edges[_edge_name]
		var valid := not moving and direction_name == String(edge.target_direction)
		valid = valid and (mining if String(edge.target_state) == "mine" else not mining)
		if not valid or _impact_pending:
			_edge_events.append({"event":"unsupported_interruption","edge":_edge_name,"step":_edge_step})
			_edge_name = ""
			_mode = "legacy"
		else:
			_edge_elapsed += delta
			_edge_step = clampi(roundi(_edge_elapsed*60.0),0,int(edge.steps))
			var index := int(edge.offset)+_edge_step
			_sprite.texture = _edge_atlas
			_sprite.material = null
			_sprite.region_rect = Rect2(Vector2(index%10,index/10)*160.0,Vector2(160,160))
			_sprite.position = Vector2(0,GROUND_Y)-Vector2(float(_bank.anchor[0]),float(_bank.anchor[1]))
			_sprite.scale = Vector2.ONE
			study_visible = true
			study_impact = false
			study_frame = 200+index
			if _edge_step == int(edge.steps):
				_edge_events.append({"event":"complete","edge":_edge_name})
				_edge_finished = true
				_mode = "mine" if mining else "legacy"
				_shown_progress = mining_progress if mining else 0.0
				_idle_clock = float(edge.get("target_idle_seconds",_idle_clock))
				_last_frame = -1
				_walk_settle = false
			return
	super._draw_frame(delta)

func transition_snapshot() -> Dictionary:
	var result := super.transition_snapshot()
	result["exact_edge"] = _edge_name
	result["exact_edge_step"] = _edge_step
	result["edge_events"] = _edge_events.duplicate(true)
	result["source_sha256"] = _source_hash
	result["scope21"] = "walk19 cell6 to down idle; legacy up-walk cell15 to first mining cycle at60Hz"
	return result
