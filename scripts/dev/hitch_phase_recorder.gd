extends Node
## DIAGNOSTIC ONLY. Fixed numeric buffer; no per-frame hook or timed JSON/file IO.
const CAPACITY: int = 512
const STRIDE: int = 15
const FIELDS: Array[String] = ["kind", "start_usec", "end_usec", "process_frame", "physics_frame", "depth_before", "depth_after", "window_before", "window_after", "requested_depth", "result", "parent", "end_process_frame", "end_physics_frame", "error_code"]
var _data: PackedInt64Array = PackedInt64Array()
var _active: bool = false
var _count: int = 0
var _dropped: int = 0
var _integrity_errors: int = 0
var _parent: int = -1
var _started_usec: int = 0
var _stopped_usec: int = 0
var _callback: JavaScriptObject


func _init() -> void:
	_data.resize(CAPACITY * STRIDE)
	_data.fill(0)


func _ready() -> void:
	if not OS.has_feature("web"):
		return
	_callback = JavaScriptBridge.create_callback(_bridge)
	var browser: JavaScriptObject = JavaScriptBridge.get_interface("window")
	browser.__everDeeperHitchCallback = _callback
	JavaScriptBridge.eval("window.__everDeeperHitchProbe = function(op) { window.__everDeeperHitchReceipt = ''; window.__everDeeperHitchCallback(op); if (!window.__everDeeperHitchReceipt) throw Error('Hitch recorder returned no receipt'); return JSON.parse(window.__everDeeperHitchReceipt); };", true)


func start_capture() -> bool:
	if _active or _parent != -1:
		return false
	_data.fill(0)
	_count = 0
	_dropped = 0
	_integrity_errors = 0
	_parent = -1
	_stopped_usec = 0
	_started_usec = Time.get_ticks_usec()
	_active = true
	return true


func stop_capture() -> bool:
	if not _active:
		return false
	_stopped_usec = Time.get_ticks_usec()
	_active = false
	return _parent == -1


func begin_span(kind: int, depth: int, window_start: int, requested: int = -1) -> int:
	if not _active:
		return -1
	if _count >= CAPACITY:
		_dropped += 1
		return -1
	var tick: int = Time.get_ticks_usec()
	var index: int = _count
	_count += 1
	var offset: int = index * STRIDE
	_data[offset] = kind
	_data[offset + 1] = tick
	_data[offset + 3] = Engine.get_process_frames()
	_data[offset + 4] = Engine.get_physics_frames()
	_data[offset + 5] = depth
	_data[offset + 7] = window_start
	_data[offset + 9] = requested
	_data[offset + 11] = _parent
	_parent = index
	return index


func end_span(index: int, depth: int, window_start: int, result: int = 1, error_code: int = 0) -> void:
	if index < 0:
		return
	var tick: int = Time.get_ticks_usec()
	if not _active or index != _parent or index >= _count:
		_integrity_errors += 1
		return
	var offset: int = index * STRIDE
	_data[offset + 2] = tick
	_data[offset + 6] = depth
	_data[offset + 8] = window_start
	_data[offset + 10] = result
	_data[offset + 12] = Engine.get_process_frames()
	_data[offset + 13] = Engine.get_physics_frames()
	_data[offset + 14] = error_code
	_parent = _data[offset + 11]


func export_capture() -> Dictionary:
	if _active:
		return {"error": "export_while_active"}
	var rows: Array = []
	for index in _count:
		var row: Array = []
		for field in STRIDE:
			row.append(_data[index * STRIDE + field])
		rows.append(row)
	return {"schema": 1, "diagnostic_only": true, "production_base": "8f5680defb9083bbe1e044d39a10612f2186e7f3", "fields": FIELDS, "kinds": {"1": "generate_stream_window", "2": "rebase_stream_window", "3": "save_game"}, "capacity": CAPACITY, "count": _count, "dropped": _dropped, "integrity_errors": _integrity_errors, "open_parent": _parent, "active": _active, "started_usec": _started_usec, "stopped_usec": _stopped_usec, "rows": rows}


func _bridge(args: Array) -> void:
	var receipt: Dictionary
	var operation: String = String(args[0]) if args.size() == 1 else "invalid"
	match operation:
		"clock":
			receipt = {"tick_usec": Time.get_ticks_usec(), "active": _active}
		"start":
			receipt = {"started": start_capture(), "tick_usec": _started_usec, "capacity": CAPACITY}
		"stop":
			receipt = {"stopped": stop_capture(), "tick_usec": _stopped_usec, "open_parent": _parent}
		"export":
			receipt = export_capture()
		_:
			receipt = {"error": "unsupported_diagnostic_operation"}
	var browser: JavaScriptObject = JavaScriptBridge.get_interface("window")
	browser.__everDeeperHitchReceipt = JSON.stringify(receipt)
