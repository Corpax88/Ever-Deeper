extends "res://scripts/qa/qa_context.gd"
## Journey performance checks moved intact from main.gd.
const JOURNEY_PERFORMANCE_MATURE_DUG_CELLS: = 1500
const JOURNEY_PERFORMANCE_MAX_FRAME_MS: = 250.0
const JOURNEY_PERFORMANCE_MAX_SAVE_BYTES: = 3 * 1024 * 1024
const JOURNEY_PERFORMANCE_MAX_SAVE_MS: = 100.0
const JOURNEY_PERFORMANCE_MAX_STATIC_BYTES: = 256 * 1024 * 1024
const JOURNEY_PERFORMANCE_MAX_TRANSITION_MS: = 500.0
const JOURNEY_PERFORMANCE_MIN_PREFLIGHT_FPS: = 45.0
const JOURNEY_PERFORMANCE_P95_LIMIT_MS: = 35.0
const JOURNEY_PERFORMANCE_SAMPLE_SECONDS: = 2.5
const JOURNEY_PERFORMANCE_WARMUP_SECONDS: = 0.75

var fixtures: RefCounted

func _init(game: Node, launch_session: Node) -> void:
	super(game, launch_session)
	fixtures = preload("res://scripts/qa/suites/world_fixtures.gd").new(game, launch_session)


func _run_journey_performance_qa() -> void :
	DisplayServer.window_set_title("Ever Deeper · Full Journey Performance QA")
	main.game_started = true
	assert (
		int(ProjectSettings.get_setting("application/run/max_fps", 0)) == 60,
		"The mobile release must keep its 60 FPS ceiling"
	)
	var rows: Array[Dictionary] = []
	var transition_started: int
	var transition_ms: float

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_surface_camp()
	for world_id_value in ["moonglass", "emberdeep", "starfall"]:
		RunState.unlock_world(String(world_id_value))
	main.surface_world.restore_position(Vector2(main.surface_world.MOSS_WAYFARER_POSITION))
	main.surface_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("surface_wayfarer", transition_ms))

	transition_started = Time.get_ticks_usec()
	main.surface_world.restore_position(Vector2(1070, 650))
	main.surface_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("surface_moss_moon_seam", transition_ms))

	transition_started = Time.get_ticks_usec()
	main.surface_world.restore_position(Vector2(3300, 650))
	main.surface_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("surface_late_worlds", transition_ms))
	main.surface_world.player.set_external_movement(Vector2.ZERO)

	for mine_id_value in main.MINE_IDS:
		var mine_id= String(mine_id_value)
		transition_started = Time.get_ticks_usec()
		_prepare_journey_mine_performance(mine_id)
		transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
		rows.append( await _measure_journey_performance_stage("%s_depth_1" % mine_id, transition_ms))
		main.mine_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_rootwound("starforge")
	main.depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("rootwound_depth_2", transition_ms))
	main.depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_prismatic()
	main.depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("prismatic_depth_2", transition_ms))
	main.depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_endgame_depth("emberMine", 2)
	main.depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("molten_depth_2", transition_ms))
	main.depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_endgame_depth("starMine", 3)
	main.depth_world.player.set_external_movement(Vector2.LEFT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("voidstar_depth_2", transition_ms))
	main.depth_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_hub()
	main.hub_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("base_hub", transition_ms))
	main.hub_world.player.set_external_movement(Vector2.ZERO)

	transition_started = Time.get_ticks_usec()
	fixtures._start_qa_deepheart()
	main.deepheart_world.player.set_external_movement(Vector2.RIGHT)
	transition_ms = float(Time.get_ticks_usec() - transition_started) / 1000.0
	rows.append( await _measure_journey_performance_stage("deepheart", transition_ms))
	main.deepheart_world.player.set_external_movement(Vector2.ZERO)

	var surface_budget: Dictionary = main.surface_world.mobile_performance_snapshot()
	assert (int(surface_budget.get("moss_bank_shader_taps", 99)) <= 5)
	var surface_drop_budget: Dictionary = main.surface_world.assert_surface_loose_drop_budget()
	assert (int(surface_drop_budget.get("live", 999)) <= int(surface_drop_budget.get("total_limit", 0)))
	var hub_belt_budget: Dictionary = main.hub_world.belt_performance_snapshot()
	assert (is_equal_approx(float(hub_belt_budget.get("visual_hz", 0.0)), 30.0))
	assert (int(hub_belt_budget.get("max_draw_packets", 999)) <= 48)
	var mine_lighting: Dictionary = main.mine_world.lighting_snapshot()
	assert (int(mine_lighting.get("visible_count", 999)) <= int(mine_lighting.get("max_visible", 0)))
	var depth_lighting: Dictionary = main.depth_world.lighting_snapshot()
	assert (int(depth_lighting.get("active_count", 999)) <= int(depth_lighting.get("max_active", 0)))
	var save_budget: Dictionary = _measure_journey_mature_save()
	assert (float(save_budget.save_ms) <= JOURNEY_PERFORMANCE_MAX_SAVE_MS)
	assert (int(save_budget.bytes) <= JOURNEY_PERFORMANCE_MAX_SAVE_BYTES)

	var worst_p95_ms= 0.0
	var worst_frame_ms= 0.0
	var slow_frame_total= 0
	var max_static_bytes= 0
	for row in rows:
		worst_p95_ms = maxf(worst_p95_ms, float(row.p95_ms))
		worst_frame_ms = maxf(worst_frame_ms, float(row.max_ms))
		slow_frame_total += int(row.slow_frames)
		max_static_bytes = maxi(max_static_bytes, int(row.static_bytes))
		assert (
			float(row.average_fps) >= JOURNEY_PERFORMANCE_MIN_PREFLIGHT_FPS,
			"%s fell below the native preflight floor" % String(row.stage)
		)
		assert (
			float(row.p95_ms) <= JOURNEY_PERFORMANCE_P95_LIMIT_MS,
			"%s exceeded the p95 frame budget" % String(row.stage)
		)
		assert (
			float(row.max_ms) <= JOURNEY_PERFORMANCE_MAX_FRAME_MS,
			"%s produced a catastrophic render stall" % String(row.stage)
		)
		assert (
			float(row.transition_ms) <= JOURNEY_PERFORMANCE_MAX_TRANSITION_MS,
			"%s transition exceeded the cold-load budget" % String(row.stage)
		)
	assert (max_static_bytes <= JOURNEY_PERFORMANCE_MAX_STATIC_BYTES)
	print(
		"EVER_DEEPER_JOURNEY_PERFORMANCE_OK stages=%d target_fps=60 worst_p95_ms=%.2f max_frame_ms=%.2f slow_frames=%d max_static_mib=%.1f mature_save_ms=%.2f mature_save_kib=%.1f"
		%[
			rows.size(), worst_p95_ms, worst_frame_ms, slow_frame_total,
			float(max_static_bytes) / (1024.0 * 1024.0),
			float(save_budget.save_ms), float(save_budget.bytes) / 1024.0,
		]
	)
	main.get_tree().quit(0)


func _prepare_journey_mine_performance(mine_id: String) -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	RunState.unlock_world(String(main.WORLD_BY_MINE[mine_id]))
	main._enter_mine(mine_id, false, false)
	main.mine_world.restore_position(Vector2(300, 624))
	main.mine_world.player.set_facing(Vector2.RIGHT)
	main.mine_world.player.camera.position_smoothing_enabled = false
	main.mine_world.player.camera.reset_smoothing()
	main.mine_world.player.set_external_movement(Vector2.RIGHT)


func _measure_journey_performance_stage(stage: String, transition_ms: float) -> Dictionary:
	await main.get_tree().create_timer(JOURNEY_PERFORMANCE_WARMUP_SECONDS).timeout
	var frame_times_ms: Array[float] = []
	var previous_usec= Time.get_ticks_usec()
	var deadline_usec= previous_usec + int(JOURNEY_PERFORMANCE_SAMPLE_SECONDS * 1000000.0)
	while Time.get_ticks_usec() < deadline_usec:
		await main.get_tree().process_frame
		var now_usec= Time.get_ticks_usec()
		frame_times_ms.append(float(now_usec - previous_usec) / 1000.0)
		previous_usec = now_usec
	var stats: Dictionary = _journey_performance_frame_stats(frame_times_ms)
	stats["stage"] = stage
	stats["transition_ms"] = transition_ms
	stats["static_bytes"] = int(Performance.get_monitor(Performance.MEMORY_STATIC))
	print(
		"EVER_DEEPER_PERFORMANCE_STAGE stage=%s average_fps=%.1f p95_ms=%.2f p99_ms=%.2f max_ms=%.2f slow_frames=%d transition_ms=%.2f static_mib=%.1f"
		%[
			stage, float(stats.average_fps), float(stats.p95_ms), float(stats.p99_ms),
			float(stats.max_ms), int(stats.slow_frames), transition_ms,
			float(stats.static_bytes) / (1024.0 * 1024.0),
		]
	)
	return stats


func _journey_performance_frame_stats(samples_ms: Array[float]) -> Dictionary:
	assert ( not samples_ms.is_empty())
	var sorted_samples: Array[float] = samples_ms.duplicate()
	sorted_samples.sort()
	var total_ms= 0.0
	var slow_frames= 0
	for sample_ms in samples_ms:
		total_ms += sample_ms
		if sample_ms > 33.34:
			slow_frames += 1
	var average_ms= total_ms / float(samples_ms.size())
	return {
		"average_fps": 1000.0 / maxf(0.001, average_ms),
		"p95_ms": _journey_percentile(sorted_samples, 0.95),
		"p99_ms": _journey_percentile(sorted_samples, 0.99),
		"max_ms": float(sorted_samples[-1]),
		"slow_frames": slow_frames,
		"frames": samples_ms.size(),
	}


func _journey_percentile(sorted_samples: Array[float], percentile: float) -> float:
	var index= clampi(ceili(float(sorted_samples.size()) * percentile) - 1, 0, sorted_samples.size() - 1)
	return float(sorted_samples[index])


func _measure_journey_mature_save() -> Dictionary:
	RunState.begin_state_batch()
	for mine_id_value in main.MINE_IDS:
		var mine_id= String(mine_id_value)
		for depth in [1, 2]:
			for cell_index in range(JOURNEY_PERFORMANCE_MATURE_DUG_CELLS):
				RunState.mark_terrain_dug(mine_id, cell_index, depth)
	RunState.end_state_batch()
	assert ( not RunState.mark_terrain_dug("mossMine", JOURNEY_PERFORMANCE_MATURE_DUG_CELLS - 1, 1))
	var save_path= "user://journey-performance-mature-save-%d.json" % Time.get_ticks_usec()
	var save_started= Time.get_ticks_usec()
	assert (RunState.save_game(save_path), "Mature journey save failed")
	var save_ms= float(Time.get_ticks_usec() - save_started) / 1000.0
	var save_file= FileAccess.open(save_path, FileAccess.READ)
	assert (save_file != null, "Mature journey save could not be reopened")
	var save_bytes= save_file.get_length()
	save_file = null
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print(
		"EVER_DEEPER_MATURE_SAVE_OK cells=%d save_ms=%.2f bytes=%d"
		%[main.MINE_IDS.size() * 2 * JOURNEY_PERFORMANCE_MATURE_DUG_CELLS, save_ms, save_bytes]
	)
	return {"save_ms": save_ms, "bytes": save_bytes}

