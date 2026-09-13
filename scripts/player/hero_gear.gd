extends RefCounted
## Matches existing Ever-Deeper item IDs, including legacy Starforge names.
const TOOLS: Array[String] = ["worn", "iron", "runed", "moonglass", "ember", "crusher", "comet", "crown", "burrower", "pulse", "deepcore"]
const DIRECTIONS: Array[String] = ["down", "left", "up", "right"]

static func resolve_tool(pickaxe_level: int, drill_level: int, starforge: String, cosmetic: String = "original") -> String:
	# Workshop appearances select their authored model, independent of tool power.
	match cosmetic:
		"crusher": return "crusher"
		"comet": return "comet"
		"crownseeker": return "crown"
		"deepheart": return "ember"
	if drill_level > 0:
		return ["burrower", "pulse", "deepcore"][clampi(drill_level, 1, 3) - 1]
	match starforge:
		"crusher": return "crusher"
		"swift", "comet": return "comet"
		"prospector", "crown", "crownseeker": return "crown"
	return TOOLS[clampi(pickaxe_level, 1, 5) - 1]

# One shared owner drains every asynchronous request, including rapid equip
# changes and world transitions. Inactive worlds cannot retain pending loads.
static var current_gear: String = ""
static var wanted_gear: String = ""
static var loading_gear: String = ""
static var textures: Dictionary = {}
static var manifest: Dictionary = {}
static var pending: Array[String] = []
static var load_error: String = ""

static func request(gear: String) -> void:
	wanted_gear = gear
	if pending.is_empty() and current_gear != wanted_gear:
		_begin_load()

static func _begin_load() -> void:
	loading_gear = wanted_gear
	load_error = ""
	for direction in DIRECTIONS:
		for suffix in ["", "-cloth"]:
			var path: String = "res://assets/hero/dad/" + loading_gear + "/" + direction + suffix + ".png"
			if not ResourceLoader.exists(path):
				load_error = "Missing hero atlas: " + path
				return
			pending.append(path)
			ResourceLoader.load_threaded_request(path, "Texture2D")

static func poll() -> void:
	if pending.size() != 8: return
	for path in pending:
		var state: = ResourceLoader.load_threaded_get_status(path)
		if state == ResourceLoader.THREAD_LOAD_FAILED:
			load_error = "Failed hero atlas: " + path
			return
		if state != ResourceLoader.THREAD_LOAD_LOADED: return
	var loaded: Dictionary = {}
	for path in pending: loaded[path] = ResourceLoader.load_threaded_get(path)
	pending.clear()
	if wanted_gear != loading_gear:
		loaded.clear()
		_begin_load()
		return
	var file: = FileAccess.open("res://assets/hero/dad/" + loading_gear + "/manifest.json", FileAccess.READ)
	if file == null:
		load_error = "Missing hero manifest: " + loading_gear
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		load_error = "Invalid hero manifest: " + loading_gear
		return
	textures = loaded
	manifest = data
	current_gear = loading_gear
	if wanted_gear != current_gear: _begin_load()
