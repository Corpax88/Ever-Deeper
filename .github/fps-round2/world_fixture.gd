extends RefCounted
## QA-only synchronous comparison; call after surface_setup on isolated QA save.
## Load as e.g. load("res://scripts/qa/world_cpu_fixture.gd").new().run(main).
## This is helper CPU, not end-to-end FPS. No frames yield inside the experiment.

func run(main: Node) -> Dictionary:
	var world: Node2D = main.surface_world
	var mole: Node2D = world.get_node_or_null("MoleCompanion")
	if not is_instance_valid(mole) or not mole.has_method("qa_world_snapshot"):
		return {"error": "Patched companion absent"}
	var original_position: Vector2 = mole.global_position
	var original_enabled: bool = mole.qa_world_cache_enabled
	var original_searches: int = mole.path_searches
	var original_rejects: int = world.surface_route_broadphase_rejects
	var original_segments: int = world.surface_route_segment_checks
	# Ordinary route bends, mine approach, resource approach, and one expected
	# unreachable goal. All cases retain the player's actual world unlock state.
	var cases: Array = [
		["moss_branch", Vector2(650, 680), Vector2(760, 790)],
		["moss_quarry", Vector2(700, 650), Vector2(900, 650)],
		["moon_bend", Vector2(1190, 630), Vector2(1400, 650)],
		["ember_route", Vector2(2880, 648), Vector2(3140, 642)],
		["ember_resource", Vector2(3100, 650), Vector2(3130, 700)],
		["star_route", Vector2(3540, 650), Vector2(3810, 654)],
		["unreachable", Vector2(3100, 650), Vector2(3100, 440)],
	]
	var rows: Array = []
	var all_equal: bool = true
	var all_empty_after_search: bool = true
	for test in cases:
		mole.global_position = test[1]
		var reference: Array[Vector2] = []
		var samples: Array = []
		# A/B/B/A limits one-direction warmup drift; all results are retained.
		for enabled in [false, true, true, false]:
			mole.qa_world_cache_enabled = enabled
			mole.qa_world_reset_counters()
			var path: Array[Vector2] = mole._path_to(test[2])
			var snapshot: Dictionary = mole.qa_world_snapshot()
			if samples.is_empty(): reference = path.duplicate()
			var equal: bool = path == reference
			all_equal = all_equal and equal
			all_empty_after_search = all_empty_after_search and int(snapshot.cache_entries_after_search) == 0 and not bool(snapshot.search_active)
			snapshot["same_path"] = equal
			snapshot["points"] = path.size()
			samples.append(snapshot)
		rows.append({"case": test[0], "start": test[1], "target": test[2], "samples": samples})
	mole.global_position = original_position
	mole.qa_world_cache_enabled = original_enabled
	mole.path_searches = original_searches
	world.surface_route_broadphase_rejects = original_rejects
	world.surface_route_segment_checks = original_segments
	mole.qa_world_reset_counters()
	return {"scope": "Synchronous original path search with per-search exact-point cache A/B/B/A; helper CPU only", "all_paths_equal": all_equal, "all_cache_lifetimes_empty": all_empty_after_search, "rows": rows}
