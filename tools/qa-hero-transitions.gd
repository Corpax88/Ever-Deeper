extends SceneTree
## Real atlas/state playback audit. This does not certify rendered visual quality.
const Gear = preload("res://scripts/player/hero_gear.gd")
var failures: Array[String] = []
var cases: Array[Dictionary] = []
var output_dir := ""

func _initialize() -> void:
	run.call_deferred()

func check(ok: bool, key: String) -> void:
	if not ok:
		failures.append(key)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output_dir = arg.get_slice("=", 1)
	if output_dir.is_empty():
		push_error("HERO_TRANSITIONS_QA requires --output=<isolated directory>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(output_dir)
	await process_frame
	var state: Node = root.get_node("RunState")
	state.initialize_persistence(output_dir.path_join("isolated-save.json"))
	state.endless_tool_style = "original"
	state.endless_outfit = "miner"
	var player: Node = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	player.set_physics_process(false)
	var visual: Node = player.visual
	visual.set_process(false)
	for gear in Gear.TOOLS:
		state.pickaxe_level = 1
		state.drill_level = 0
		state.starforge_variant = ""
		match gear:
			"iron": state.pickaxe_level = 2
			"runed": state.pickaxe_level = 3
			"moonglass": state.pickaxe_level = 4
			"ember": state.pickaxe_level = 5
			"crusher": state.starforge_variant = "crusher"
			"comet": state.starforge_variant = "swift"
			"crown": state.starforge_variant = "prospector"
			"burrower": state.drill_level = 1
			"pulse": state.drill_level = 2
			"deepcore": state.drill_level = 3
		visual.prepare_visual_cache()
		var deadline := Time.get_ticks_msec() + 15000
		while visual.active_gear != gear and Time.get_ticks_msec() < deadline:
			visual._poll_equipment()
			await process_frame
		if visual.active_gear != gear:
			failures.append(gear + ":load_failed:" + Gear.load_error)
			continue
		var manifest: Dictionary = visual.get("_manifest")
		check(manifest.source == "approved native Gruvepappa v28", gear + ":approved_source")
		check(float(manifest.max_grip_error) < 0.00001, gear + ":native_grip_precision")
		check(int(manifest.states.mine.count) == (96 if gear == "crusher" else 48), gear + ":real_mining_frame_count")
		for direction in Gear.DIRECTIONS:
			var prefix: String = gear + ":" + direction
			visual.set("_recover_phase", -1.0)
			visual.set("_idle_clock", 0.0)
			visual.set("_walk_phase", 0.0)
			visual.set_state(direction, 0, false, false)
			var idle_frame: int = visual.get("_last_frame")
			visual.set("_idle_clock", 0.47)
			visual._draw_frame(0.0)
			check(int(visual.get("_last_frame")) != idle_frame, prefix + ":blink_has_real_pose")
			var walk_frames: Dictionary = {}
			visual.set_state(direction, 0, true, false)
			for tick in 48:
				visual.advance_motion(3.0, 1.0 / 60.0)
				visual._process(1.0 / 60.0)
				walk_frames[visual.get("_last_frame")] = true
			check(walk_frames.size() >= 40, prefix + ":smooth_walk_frames")
			# Stop between contacts, then let the authored walk settle finish.
			visual.advance_motion(41.0, 0.3)
			visual.set_state(direction, 0, false, false)
			for tick in 18:
				visual._process(1.0 / 60.0)
			check(not visual.get("_walk_settle"), prefix + ":walk_settles")
			var hit: float = visual._mechanical_hit_phase()
			var mine_frames: Dictionary = {}
			for tick in 61:
				visual.set_state(direction, 0, false, true, float(tick) / 60.0, 0.0, hit)
				visual._process(1.0 / 60.0)
				mine_frames[visual.get("_last_frame")] = true
			check(mine_frames.size() >= 30, prefix + ":mining_uses_real_motion")
			visual.set_state(direction, 0, false, true, hit, 0.0, hit)
			if manifest.family == "pickaxe":
				var expected: int = int(manifest.states.mine.offset) + roundi(0.55 * int(manifest.states.mine.count))
				check(int(visual.get("_last_frame")) == expected, prefix + ":contact_matches_gameplay")
			for interrupted_phase in [0.2, 0.8]:
				visual.set_state(direction, 0, false, true, interrupted_phase, 0.0, hit)
				visual.set_state(direction, 0, false, false)
				for tick in 30:
					visual._process(1.0 / 60.0)
				check(int(visual.get("_last_frame")) < int(manifest.states.walk.offset), prefix + ":recovery_returns_to_idle:" + str(interrupted_phase))
			var snapshot: Dictionary = visual.tool_visual_snapshot()
			check(int(snapshot.textures_loaded) == 8 and snapshot.direction == direction, prefix + ":direction_and_masks_loaded")
			cases.append({"gear": gear, "direction": direction, "walk_frames": walk_frames.size(), "mining_frames": mine_frames.size()})
	for outfit in ["miner", "expedition", "archivist", "starweave", "deepheart"]:
		state.endless_outfit = outfit
		visual.set_state("down", 0, false, false)
		check(visual.active_endless_outfit_style == outfit, "outfit:" + outfit)
		var cloth: ShaderMaterial = visual.get("_cloth")
		check(is_equal_approx(float(cloth.get_shader_parameter("recolor")), 0.0 if outfit == "miner" else 1.0), "outfit_mask:" + outfit)
	visual.release_visual_cache()
	check(int(visual.tool_visual_snapshot().textures_loaded) == 0, "inactive_world_releases_atlases")
	var report := {"passed": failures.is_empty(), "failures": failures, "engine": Engine.get_version_info().string, "cases": cases, "outfits": 5, "rendered_visual_quality_verified": false, "physical_iphone_fps_verified": false}
	FileAccess.open(output_dir.path_join("hero-transitions.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("HERO_TRANSITIONS_QA passed=%s cases=%d outfits=5 failures=%s" % [str(failures.is_empty()), cases.size(), JSON.stringify(failures)])
	quit(0 if failures.is_empty() else 1)
