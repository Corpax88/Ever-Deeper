extends SceneTree
## Isolated synchronous save-cost fixture; this does not measure gameplay FPS.

var output_dir: String = "user://save-cost-review"

func _initialize() -> void:
	call_deferred("probe")
func probe() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_dir = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	var save_path: String = output_dir.path_join("isolated-save.sav")
	var state: Node = root.get_node("RunState")
	state.reset_run(false)
	state.world_seed = 23717
	state.singularity_secured = true
	state.deep_elevator_deliveries = state._default_deep_elevator_deliveries(true)
	state.deep_elevator_repaired = true
	state.deep_elevator_powered = true
	state.final_expedition_begun = true
	state.deepheart_seals = state._default_deepheart_seals(true)
	state.victory = true
	state.endless_descent_active = true
	var rows: Array = []
	for count in [3, 100, 1000]:
		state.endless_current_depth = count
		state.endless_deepest_depth = count
		state.endless_chunks.clear()
		for index in count:
			state.endless_chunks[str(index + 1)] = {"dug": "f".repeat(220), "nodes": 2147483647, "sites": 255, "seen": 15}
		var samples: Array = []
		for index in 6:
			var start: int = Time.get_ticks_usec()
			var ok: bool = state.save_game(save_path)
			var elapsed: float = float(Time.get_ticks_usec() - start) / 1000.0
			if not ok:
				print("SAVE_COST_FAILURE ", state.last_save_error)
				quit(2)
				return
			if index > 0:
				samples.append(elapsed)
		rows.append({"fully_dug_bands": count, "file_bytes": FileAccess.get_file_as_bytes(save_path).size(), "milliseconds": samples})
	var result: Dictionary = {"scope": "Native headless scratch filesystem; five warm synchronous saves, not device FPS", "rows": rows, "run_state_sha256": FileAccess.get_sha256("res://scripts/state/run_state.gd"), "terrain_state_sha256": FileAccess.get_sha256("res://scripts/state/endless_terrain_state.gd"), "codec_sha256": FileAccess.get_sha256("res://scripts/state/run_save_codec.gd")}
	var file: FileAccess = FileAccess.open(output_dir.path_join("save-cost.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	print(JSON.stringify(result))
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit()
