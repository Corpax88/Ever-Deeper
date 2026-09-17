extends "res://tools/review_premium_session.gd"
## Same sustained input/seed as DEV9, with opt-in caster substitution before warm-up.
const Candidate = preload("res://tools/shadow_mask_pilot/candidate.gd")
var _candidate_mode: bool = false
var _installed: bool = false
var _last_mined: int = 0
var _last_distance: float = 0.0
var _last_elapsed: float = 0.0
var _caster_samples: Array[float] = []
var _mask_samples: Array[float] = []
var _refresh_samples: Array[float] = []

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--caster-masks": _candidate_mode = true
	super._initialize()

func _process(_delta: float) -> bool:
	if not is_instance_valid(world): return false
	if not _installed:
		var original: Node = world.get_node_or_null("CaveLightOccluders")
		if original == null: return false
		if _candidate_mode:
			original.set_process(false)
			original.hide()
			original.name = "RetiredBaselineCasters"
			original.queue_free()
			var candidate: Node = Candidate.new()
			candidate.name = "CaveLightOccluders"
			world.add_child(candidate)
		_installed = true
		_last_mined = state.total_mined_resources()
	var caster: Node = world.get_node("CaveLightOccluders")
	_caster_samples.append(float(caster.active_count))
	if _candidate_mode:
		_mask_samples.append(float(caster.mask_update_usec))
		_refresh_samples.append(float(caster.total_refresh_usec))
	return false

func _record_window(frames: Array[float], cpu: Array[float], draws: Array[float], elapsed: float, distance: float) -> void:
	super._record_window(frames, cpu, draws, elapsed, distance)
	var row: Dictionary = windows[-1]
	row.caster_masks = _candidate_mode
	row.interval_mined_resources = state.total_mined_resources() - _last_mined
	row.interval_distance = distance - _last_distance
	row.actual_interval_seconds = elapsed - _last_elapsed
	_caster_samples.sort()
	_mask_samples.sort()
	_refresh_samples.sort()
	row.casters_p95 = _caster_samples[mini(_caster_samples.size()-1, floori(_caster_samples.size() * .95))] if not _caster_samples.is_empty() else 0
	row.mask_refresh_p95_usec = _mask_samples[mini(_mask_samples.size()-1, floori(_mask_samples.size() * .95))] if not _mask_samples.is_empty() else 0
	row.total_refresh_p95_usec = _refresh_samples[mini(_refresh_samples.size()-1, floori(_refresh_samples.size() * .95))] if not _refresh_samples.is_empty() else 0
	_last_mined = state.total_mined_resources()
	_last_distance = distance
	_last_elapsed = elapsed
	_caster_samples.clear()
	_mask_samples.clear()
	_refresh_samples.clear()
	FileAccess.open(output.path_join("windows.json"), FileAccess.WRITE).store_string(JSON.stringify(windows, "\t"))
