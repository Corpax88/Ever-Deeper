extends "res://tools/review_premium_session.gd"
## Observe the unchanged real-time route with existing draw timers enabled.
## This tool neither replaces the renderer nor changes production draw settings.
var _sections: Node
var _prior: Dictionary = {}
var _pending: Array[Dictionary] = []
var _identity: Dictionary = {}
var _capture_pending: bool = false
var _sample_index: int = 0

func _process(_delta: float) -> bool:
	if not is_instance_valid(world): return false
	var observer_started: int = Time.get_ticks_usec()
	if not is_instance_valid(_sections):
		_sections = world.lit_draw_sections
		_sections.profile_draws = true
		_prior = _sections.debug_snapshot()
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		_identity = {
			"godot": Engine.get_version_info(),
			"runtime_source": _sha("res://scripts/world/endless_descent_world.gd"),
			"draw_sections_source": _sha("res://scripts/lighting/lit_draw_sections.gd"),
			"route_source": _sha("res://tools/review_premium_session.gd"),
			"observer_source": _sha(get_script().resource_path),
			"source_revision": _source_revision(),
			"profiling_enabled": true,
			"rendered": true,
			"physical_iphone": false,
			"display": DisplayServer.get_name(),
			"renderer": RenderingServer.get_video_adapter_name(),
			"window_pixels": [root.size.x, root.size.y],
			"sampling_limit": "One observer tick per process frame; each window retains the most recent N samples for N workload frames. Timer counters and render times describe completed prior draw work and may straddle one frame at a window boundary. Observed costs include diagnostic overhead; these are not acceptance FPS.",
			"setup_scope": "LitDrawSections.begin through finish, including world terrain fingerprints and section configuration; excludes queued section draw callbacks, which have a separate timer.",
			"timing_limit": "Viewport render CPU and frame setup timings may overlap or include driver waits. They are reported separately and must not be added to process/physics timings as disjoint work.",
		}
		FileAccess.open(output.path_join("diagnosis-identity.json"), FileAccess.WRITE).store_string(JSON.stringify(_identity, "\t"))
		return false
	var snapshot: Dictionary = _sections.debug_snapshot()
	var row: Dictionary = {
		"sample": _sample_index,
		"time_usec": Time.get_ticks_usec(),
		"setup_usec": int(snapshot.setup_usec) - int(_prior.setup_usec),
		"draw_usec": int(snapshot.draw_callback_usec) - int(_prior.draw_callback_usec),
		"draw_callbacks": int(snapshot.draw_callbacks) - int(_prior.draw_callbacks),
		"cached_redraws": int(snapshot.redraws) - int(_prior.redraws),
		"cached_reuses": int(snapshot.reuses) - int(_prior.reuses),
		"cached_nodes": int(snapshot.cached),
		"dynamic_nodes": int(snapshot.dynamic),
		"recycled_nodes": int(snapshot.recycled),
		"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(root.get_viewport_rid()),
		"frame_setup_cpu_ms": RenderingServer.get_frame_setup_time_cpu(),
		"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(root.get_viewport_rid()),
		"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"player": [world.player.position.x, world.player.position.y],
		"mined_resources": state.total_mined_resources(),
		"capture_pending": _capture_pending,
	}
	var occluders: Node = world.get_node_or_null("CaveLightOccluders")
	if occluders != null:
		row["shadow_casters"] = occluders.active_count
		row["occluder_rebuilds"] = occluders.rebuild_count
	row["observer_usec"] = Time.get_ticks_usec() - observer_started
	_pending.append(row)
	_prior = snapshot
	_sample_index += 1
	return false

func _record_window(frames: Array[float], cpu: Array[float], draws: Array[float], elapsed: float, distance: float) -> void:
	# The inherited route owns input and timing. Discard only its warm-up samples.
	var raw_frames: Array[float] = frames.duplicate()
	var observed: Array[Dictionary] = _pending.slice(maxi(0, _pending.size() - frames.size()))
	_pending.clear()
	super._record_window(frames, cpu, draws, elapsed, distance)
	var row: Dictionary = windows[-1]
	row["raw_frame_ms"] = raw_frames
	row["draw_diagnosis"] = _summarize(observed)
	row["profiling_enabled"] = _sections.profile_draws
	row["terrain_cache"] = _sections.debug_snapshot()
	var index: int = windows.size()
	FileAccess.open(output.path_join("draw-samples-%02d.json" % index), FileAccess.WRITE).store_string(JSON.stringify(observed, "\t"))
	FileAccess.open(output.path_join("windows.json"), FileAccess.WRITE).store_string(JSON.stringify(windows, "\t"))
	print("MOVING_DRAW_WINDOW " + JSON.stringify(row.draw_diagnosis))
	_capture_window(index)

func _summarize(samples: Array[Dictionary]) -> Dictionary:
	var result: Dictionary = {"samples": samples.size()}
	for key in ["setup_usec", "draw_usec", "draw_callbacks", "cached_redraws", "cached_reuses", "cached_nodes", "dynamic_nodes", "recycled_nodes", "render_cpu_ms", "frame_setup_cpu_ms", "process_ms", "physics_ms", "draw_calls", "observer_usec", "shadow_casters"]:
		var values: Array[float] = []
		var sum: float = 0.0
		var nonzero: int = 0
		for sample in samples:
			var value: float = float(sample.get(key, 0.0))
			values.append(value)
			sum += value
			if value != 0.0: nonzero += 1
		values.sort()
		result[key] = {"sum": sum, "mean": sum / maxf(1.0, values.size()), "nonzero_frames": nonzero, "p50": _percentile(values, .5), "p95": _percentile(values, .95), "p99": _percentile(values, .99), "max": values[-1] if not values.is_empty() else 0.0}
	var valid_gpu: Array[float] = []
	var invalid_gpu: int = 0
	for sample in samples:
		var value: float = float(sample.render_gpu_ms)
		if not is_finite(value) or value <= 0.0 or value >= 1000.0: invalid_gpu += 1
		else: valid_gpu.append(value)
	valid_gpu.sort()
	result["render_gpu_ms"] = {"supported": invalid_gpu == 0 and not valid_gpu.is_empty(), "invalid_samples": invalid_gpu, "p50_valid": _percentile(valid_gpu, .5), "p95_valid": _percentile(valid_gpu, .95)}
	result["timers_exercised"] = float(result.setup_usec.sum) > 0.0 and float(result.draw_usec.sum) > 0.0 and float(result.draw_callbacks.sum) > 0.0
	return result

func _percentile(values: Array[float], fraction: float) -> float:
	if values.is_empty(): return 0.0
	return values[clampi(ceili(values.size() * fraction) - 1, 0, values.size() - 1)]

func _capture_window(index: int) -> void:
	_capture_pending = true
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var path: String = output.path_join("moving-%02d.png" % index)
	picture.save_png(path)
	FileAccess.open(output.path_join("moving-%02d.json" % index), FileAccess.WRITE).store_string(JSON.stringify({"framebuffer_size": [picture.get_width(), picture.get_height()], "sha256": FileAccess.get_sha256(path), "player": str(world.player.position), "held_mining": world.external_mine_held, "draw_snapshot": _sections.debug_snapshot()}, "\t"))
	_capture_pending = false

func _sha(path: String) -> Dictionary:
	return {"path": path, "sha256": FileAccess.get_sha256(path)}

func _source_revision() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--source-revision="): return arg.trim_prefix("--source-revision=")
	return "unprovided"
