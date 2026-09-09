extends SceneTree
## Opt-in real-time workload; compatible with the immutable 1.0.0-dev.2 PCK.
## Run in an isolated XDG_DATA_HOME (tools/run_rendered_isolated.py does this):
## godot --path PROJECT --script /absolute/tools/review_sustained_mining.gd -- 
##   --output=/absolute/results --fixture=ember_d1 --duration=180
## For an exported build use an empty --path plus --main-pack /absolute/index.pck.
## Also pass --pack-source=/absolute/index.pck to retain/verify package hashes.
## --fixture=all also measures the completed Hub and post-fifth-relic The Deep.
## Headless is only a functional/CPU smoke test; no result certifies an iPhone.

const FIXTURES: Array[String] = ["ember_d1", "hub", "deep_post5"]
const DIRECTIONS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
const WINDOW_SECONDS: float = 10.0
const WORLD_SEED: int = 4608
const ReleaseMenu = preload("res://scripts/ui/premium_menu.gd")
var output: String = ""
var pack_source: String = ""
var pack_hash_before: String = ""
var harness_hash_before: String = ""
var fixture: String = "ember_d1"
var duration: float = 180.0
var main: Node
var state: Node
var world: Node2D
var player: Node2D
var recording: bool = false
var route: Array[Vector2] = []
var route_index: int = 0
var route_loops: int = 0
var route_locked_barriers: Array[Dictionary] = []
var route_rejected_edges: int = 0
var input_vector: Vector2 = Vector2(INF, INF)
var deep_column: float = 0.0
var distance: float = 0.0
var previous_position: Vector2
var picked: Dictionary = {}
var broken: int = 0
var respawned: int = 0
var previous_block_count: int = 0
var windows: Array[Dictionary] = []
var reports: Array[Dictionary] = []
var failed: bool = false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		elif arg.begins_with("--fixture="): fixture = arg.trim_prefix("--fixture=")
		elif arg.begins_with("--duration="): duration = float(arg.trim_prefix("--duration="))
		elif arg.begins_with("--pack-source="): pack_source = arg.trim_prefix("--pack-source=")
		else:
			_fail("Unknown harness argument: " + arg)
			return
	if not output.is_absolute_path() or fixture not in FIXTURES + ["all"] or not is_finite(duration) or duration < 1.0 or duration > 3600.0:
		_fail("Require absolute --output, --fixture=ember_d1|hub|deep_post5|all and duration 1–3600 seconds")
		return
	var packed: bool = FileAccess.file_exists("res://project.binary")
	if packed and pack_source.is_empty():
		_fail("Exported-package review requires --pack-source=/absolute/index.pck")
		return
	if not pack_source.is_empty():
		if not pack_source.is_absolute_path() or not FileAccess.file_exists(pack_source):
			_fail("--pack-source must name an existing absolute PCK path")
			return
		pack_hash_before = FileAccess.get_sha256(pack_source)
		var engine_args: PackedStringArray = OS.get_cmdline_args()
		var pack_index: int = engine_args.find("--main-pack")
		if packed and pack_index >= 0 and pack_index + 1 < engine_args.size():
			if FileAccess.get_sha256(engine_args[pack_index + 1]) != pack_hash_before:
				_fail("--pack-source bytes do not match the mounted --main-pack")
				return
	harness_hash_before = FileAccess.get_sha256(get_script().resource_path)
	DirAccess.make_dir_recursive_absolute(output)
	state = root.get_node("RunState")
	main = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	state.initialize_persistence(output.path_join("isolated-run.json"))
	for frame in 5: await process_frame
	physics_frame.connect(_drive)
	state.resource_collected.connect(_on_pickup)
	state.changed.connect(_on_state_changed)
	var selected: Array[String] = []
	if fixture == "all": selected.assign(FIXTURES)
	else: selected.append(fixture)
	for selected_fixture in selected:
		fixture = selected_fixture
		if not _prepare(): return
		await _settle(3.0)
		if not await _measure(): return
	var pack_hash_after: String = FileAccess.get_sha256(pack_source) if not pack_source.is_empty() else ""
	var harness_hash_after: String = FileAccess.get_sha256(get_script().resource_path)
	if pack_hash_after != pack_hash_before or harness_hash_after != harness_hash_before:
		_fail("PCK or harness changed during review")
		return
	var report: Dictionary = {
		"engine":Engine.get_version_info(), "version":ReleaseMenu.release_version(),
		"runtime":{"version":ReleaseMenu.release_version(),"project_version":ProjectSettings.get_setting("application/config/version"),"dev_build":OS.has_feature("ever_deeper_dev")},
		"package":{"exported":packed,"path":pack_source,"sha256_before":pack_hash_before,"sha256_after":pack_hash_after},
		"harness":{"path":get_script().resource_path,"sha256_before":harness_hash_before,"sha256_after":harness_hash_after},
		"display_driver":DisplayServer.get_name(), "renderer":RenderingServer.get_current_rendering_method(),
		"adapter":RenderingServer.get_video_adapter_name(), "rendered":DisplayServer.get_name() != "headless",
		"physical_iphone":false, "window_pixels":_xy(Vector2(DisplayServer.window_get_size())),
		"logical_viewport":_xy(root.get_visible_rect().size), "world_seed":WORLD_SEED,
		"requested_seconds_per_fixture":duration, "window_seconds":WINDOW_SECONDS,
		"controls":"Synthetic joystick and held mine through Main; normal physics/process timing",
		"fixture_only_repositioning":true, "teleports_during_measurement":0,
		"terrain_replacement":false, "manual_process_steps":false, "fixed_graphics":true,
		"limits":"Native/software rendering and headless CPU checks do not establish browser or physical iPhone performance. TIME_PROCESS is not exclusive script CPU. Short smoke runs do not establish sustained performance.",
		"fixtures":reports,
	}
	_write_json(output.path_join("sustained-mining.json"), report)
	if failed: return
	print("SUSTAINED_MINING_COMPLETE " + JSON.stringify({"fixtures":reports.size(),"rendered":report.rendered,"physical_iphone":false}))
	quit(0)

func _prepare() -> bool:
	main._cancel_held_input()
	main._dev_jump_surface()
	state.reset_run(false)
	state.world_seed = WORLD_SEED
	seed(WORLD_SEED)
	state.overhaul_progress["skills"] = {"lantern":1,"fetch":1,"trailrunner":1,"big_paws":1,"ore_nose":1,"long_beam":1,"shake":1,"teamwork":1,"echo":1,"homeward":1}
	if fixture == "ember_d1":
		state.pickaxe_level = 4
		state.gold = 254
		state.area_unlocked = true
		state.emberdeep_unlocked = true
		state.cargo["emberstone"] = 81
		if not main._dev_jump_mine("emberMine", 1): return _fail("Cannot prepare Emberdeep D1")
		world = main.mine_world
	elif fixture in ["hub", "deep_post5"]:
		main._dev_seed_victory_state()
		if not main._dev_build_all_workshops_state(): return _fail("Cannot build five-workshop fixture")
		var descent: Dictionary = state.endless_descent_status()
		if int(descent.placed_relic_count) != 5 or int(descent.built_workshop_count) != 5:
			return _fail("Completed Hub fixture must contain five placed relics and five built workshops")
		if fixture == "hub":
			if not main._dev_jump_hub(): return _fail("Cannot enter completed Hub")
			world = main.hub_world
			world.restore_position(Vector2(430, 820))
		else:
			if not main._dev_jump_endless(13): return _fail("Cannot enter post-fifth-relic The Deep")
			world = main.endless_world
	player = world.player
	main._apply_global_movement_speed()
	main._refresh_hud()
	main._update_visual_guide()
	main.achievement_toast.clear()
	if main.quick_tutorial != null: main.quick_tutorial.dismiss()
	if not player.moved.is_connected(_on_player_moved): player.moved.connect(_on_player_moved)
	route.clear()
	route_index = 0
	route_loops = 0
	route_locked_barriers.clear()
	route_rejected_edges = 0
	input_vector = Vector2(INF, INF)
	if fixture == "deep_post5":
		deep_column = (floorf(player.global_position.x / 64.0) + 0.5) * 64.0
	else:
		if not _prepare_route(): return false
	return true

func _prepare_route() -> bool:
	# Prepare one cardinal traversal before timing. Every edge is walked through
	# the real collision resolver; a solid D1 cell must actually be mined first.
	var grid_step: float = 48.0
	var dimensions: Vector2i = Vector2i(world.cols, world.rows) if fixture == "ember_d1" else Vector2i(30,20)
	if fixture == "ember_d1":
		# A gate's collision rectangle extends beyond its sparse trigger cells.
		# Exclude the whole closed gate when this actual loadout cannot mine it.
		for value in world.mine.barriers:
			var barrier: Dictionary = value
			if int(barrier.requiresPickaxe) <= int(state.pickaxe_level) or not world._role_has_blocks(String(barrier.id)): continue
			route_locked_barriers.append({"id":String(barrier.id),"requires_tool":int(barrier.requiresPickaxe),
				"rect":Rect2(float(barrier.x),float(barrier.y),float(barrier.w),float(barrier.h))})
	var start: Vector2i = Vector2i(Vector2(player.global_position) / grid_step)
	var center: Vector2 = (Vector2(start) + Vector2.ONE * 0.5) * grid_step
	if fixture == "hub" and world.collision_at(center): return _fail("Hub route starts inside a station")
	world.restore_position(center)
	start = Vector2i(Vector2(player.global_position) / grid_step)
	var visited: Dictionary = {start:true}
	var stack: Array[Vector2i] = [start]
	route.append((Vector2(start) + Vector2.ONE * 0.5) * grid_step)
	while not stack.is_empty():
		var cell: Vector2i = stack.back()
		var advanced: bool = false
		for direction in DIRECTIONS:
			var next: Vector2i = cell + direction
			if visited.has(next) or next.x < 2 or next.y < 2 or next.x >= dimensions.x - 2 or next.y >= dimensions.y - 2:
				continue
			var position: Vector2 = (Vector2(next) + Vector2.ONE * 0.5) * grid_step
			var origin: Vector2 = (Vector2(cell) + Vector2.ONE * 0.5) * grid_step
			if fixture == "ember_d1":
				var block: Dictionary = world.blocks.get(next, {})
				if String(block.get("kind", "")) == "bedrock" or int(block.get("requires_tool", 0)) > int(state.pickaxe_level): continue
				if _edge_hits_locked_barrier(origin, position):
					route_rejected_edges += 1
					continue
			else:
				var blocked: bool = false
				for fraction in [0.25,0.5,0.75,1.0]:
					blocked = blocked or bool(world.collision_at(origin.lerp(position, fraction)))
				if blocked: continue
			visited[next] = true
			stack.append(next)
			route.append(position)
			advanced = true
			break
		if not advanced:
			stack.pop_back()
			if not stack.is_empty(): route.append((Vector2(stack.back()) + Vector2.ONE * 0.5) * grid_step)
	return true if route.size() > 4 else _fail("Insufficient reachable route")

func _edge_hits_locked_barrier(origin: Vector2, destination: Vector2) -> bool:
	# Cardinal segments give a narrow rectangle. Conservatively include the
	# player's radius and 0.5px clearance, including at gate corners.
	var segment: Rect2 = Rect2(origin,destination-origin).abs().grow(0.01)
	for barrier in route_locked_barriers:
		if segment.intersects(Rect2(barrier.rect).grow(float(world.PLAYER_RADIUS) + 0.5)): return true
	return false

func _drive() -> void:
	if not recording: return
	var remaining: Vector2
	if fixture == "deep_post5":
		remaining = Vector2(deep_column - player.global_position.x, 64.0)
	else:
		while player.global_position.distance_to(route[route_index]) < 0.25:
			route_index += 1
			if route_index == route.size():
				route_index = 0
				route_loops += 1
		remaining = route[route_index] - player.global_position
	var motion: Vector2 = Vector2(remaining.x,0) if absf(remaining.x) > 0.1 else Vector2(0,remaining.y)
	var step_distance: float = maxf(0.01, float(player.movement_speed) / float(Engine.physics_ticks_per_second))
	var next_input: Vector2 = (motion / step_distance).limit_length(1.0)
	if not next_input.is_equal_approx(input_vector):
		input_vector = next_input
		main._on_joystick_movement(input_vector)

func _on_player_moved(_position: Vector2) -> void:
	if not recording: return
	var current: Vector2 = _absolute_position()
	distance += previous_position.distance_to(current)
	previous_position = current

func _absolute_position() -> Vector2:
	var position: Vector2 = player.global_position
	if fixture == "deep_post5": position.y += float(world.window_start_depth - 1) * float(world.CHUNK_HEIGHT)
	return position

func _on_pickup(kind: String, amount: int) -> void:
	if recording: picked[kind] = int(picked.get(kind, 0)) + amount

func _on_state_changed() -> void:
	if not recording or fixture != "ember_d1": return
	# O(1) observation at existing state notifications, including natural respawns.
	var count: int = world.blocks.size()
	broken += maxi(0, previous_block_count - count)
	respawned += maxi(0, count - previous_block_count)
	previous_block_count = count

func _measure() -> bool:
	distance = 0.0
	broken = 0
	respawned = 0
	picked.clear()
	windows.clear()
	previous_position = _absolute_position()
	previous_block_count = world.blocks.size() if fixture == "ember_d1" else 0
	var initial: Dictionary = _snapshot()
	_write_json(output.path_join(fixture + "-initial-state.json"), state.serialize())
	await _capture(fixture + "-initial")
	main._set_mine_held(fixture != "hub")
	recording = true
	var started: int = Time.get_ticks_usec()
	var previous: int = started
	var window_start: int = started
	var window_before: Dictionary = initial
	var frame_ms: Array[float] = []
	var draw_counts: Array[float] = []
	var process_ms: Array[float] = []
	var physics_ms: Array[float] = []
	var node_counts: Array[float] = []
	var gpu_mib: Array[float] = []
	var static_mib: Array[float] = []
	var mining_frames: int = 0
	while float(previous - started) / 1000000.0 < duration:
		await process_frame
		var now: int = Time.get_ticks_usec()
		frame_ms.append(float(now - previous) / 1000.0)
		previous = now
		draw_counts.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		process_ms.append(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
		physics_ms.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		node_counts.append(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
		gpu_mib.append(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0)
		static_mib.append(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		if fixture != "hub" and bool(world.get("swing_active" if fixture == "ember_d1" else "mining_active")): mining_frames += 1
		if float(now - window_start) / 1000000.0 < WINDOW_SECONDS and float(now - started) / 1000000.0 < duration: continue
		var after: Dictionary = _snapshot()
		var row: Dictionary = _frame_stats(frame_ms)
		row.merge({"fixture":fixture,"window":windows.size(),"from_seconds":float(window_start-started)/1000000.0,
			"to_seconds":float(now-started)/1000000.0,"complete_10s_window":now-window_start >= 9990000,
			"moved_pixels":float(after.distance)-float(window_before.distance),
			"mined_resources":int(after.total_mined)-int(window_before.total_mined),
			"picked_resources":_delta(after.picked, window_before.picked),
			"broken_cells_or_nodes":int(after.broken)-int(window_before.broken),
			"respawned_cells":int(after.respawned)-int(window_before.respawned),"mining_active_frames":mining_frames,
			"draw_calls":_range(draw_counts),"nodes":_range(node_counts),"gpu_mib":_range(gpu_mib),"static_mib":_range(static_mib),
			"process_monitor_ms":_range(process_ms),"physics_monitor_ms":_range(physics_ms),"state":after,
			"raw":{"frame_ms":frame_ms.duplicate(),"draw_calls":draw_counts.duplicate(),"process_ms":process_ms.duplicate(),
				"physics_ms":physics_ms.duplicate(),"nodes":node_counts.duplicate(),"gpu_mib":gpu_mib.duplicate(),"static_mib":static_mib.duplicate()}})
		row["active_mining_observed"] = int(row.mined_resources) > 0 and int(row.broken_cells_or_nodes) > 0 and float(row.moved_pixels) > 1.0
		windows.append(row)
		print("SUSTAINED_MINING_WINDOW " + JSON.stringify({"fixture":fixture,"window":row.window,"fps":row.average_fps,"p95_ms":row.p95_ms,"mined":row.mined_resources,"moved":row.moved_pixels,"active":row.active_mining_observed}))
		_write_json(output.path_join("%s-window-%02d.json" % [fixture, windows.size()]), row)
		window_start = now
		window_before = after
		frame_ms.clear(); draw_counts.clear(); process_ms.clear(); physics_ms.clear()
		node_counts.clear(); gpu_mib.clear(); static_mib.clear(); mining_frames = 0
	recording = false
	main._cancel_held_input()
	var final: Dictionary = _snapshot()
	var actual_mining: bool = fixture == "hub" or (int(final.total_mined) > int(initial.total_mined) and int(final.broken) > int(initial.broken) and _sum(picked) > 0)
	var progress: bool = float(final.distance) > 48.0 and actual_mining
	var every_window_active: bool = true
	for row in windows:
		if bool(row.complete_10s_window):
			every_window_active = every_window_active and (float(row.moved_pixels) > 1.0 if fixture == "hub" else bool(row.active_mining_observed))
	var sustained_duration: bool = duration >= 180.0 and float(windows[-1].to_seconds) >= 180.0
	var valid_workload: bool = progress and (duration < 180.0 or every_window_active)
	var result: Dictionary = {"fixture":fixture,"initial":initial,"final":final,"windows":windows.duplicate(true),
		"actual_play_progress":progress,"every_full_window_active":every_window_active,"elapsed_180s":sustained_duration,
		"sustained_180s":sustained_duration and valid_workload,"valid_workload":valid_workload,
		"route_points":route.size(),"route_hash":hash(route),"route_loops":route_loops,"source_seed":WORLD_SEED,
		"route_rejected_locked_edges":route_rejected_edges,"route_locked_barriers":_route_barrier_report()}
	reports.append(result)
	_write_json(output.path_join(fixture + "-final-state.json"), state.serialize())
	_write_json(output.path_join(fixture + "-summary.json"), result)
	await _capture(fixture + "-final")
	if not progress: return _fail("Workload made insufficient real mining/movement progress: " + fixture)
	return true if valid_workload else _fail("180s workload includes a full window without actual mining/movement: " + fixture)

func _snapshot() -> Dictionary:
	var broken_count: int = broken
	if fixture == "deep_post5":
		for chunk in state.endless_chunks.values():
			for digit in String(chunk.get("dug", "")): broken_count += _bits("0123456789abcdef".find(digit))
			broken_count += _bits(int(chunk.get("nodes", 0)))
	return {"phase":main.phase,"position":_xy(Vector2(player.global_position)),"absolute_position":_xy(_absolute_position()),
		"distance":distance,"total_mined":state.total_mined_resources(),"mined":state.mined.duplicate(true),
		"cargo":state.cargo.duplicate(true),"picked":picked.duplicate(true),"broken":broken_count,"respawned":respawned,
		"pickaxe_level":state.pickaxe_level,"drill_level":state.drill_level,"starforge_variant":state.starforge_variant,
		"loadout":state.endless_loadout_status(),"skills":Dictionary(state.overhaul_progress.get("skills", {})).duplicate(true),
		"progression_goal":main.premium_hud.progression_goal_snapshot(),
		"route_index":route_index,"route_waypoint":_xy(route[route_index]) if not route.is_empty() else [],
		"mining_target":_target_snapshot(),
		"depth":int(world.current_depth) if fixture == "deep_post5" else 1,"descent":state.endless_descent_status(),
		"memory":{"static_mib":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0,
			"gpu_mib":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576.0,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT)}}

func _target_snapshot() -> Dictionary:
	if fixture != "ember_d1": return {}
	var cell: Vector2i = world.current_target
	var block: Dictionary = world.blocks.get(cell, {})
	return {"cell":[cell.x,cell.y],"kind":String(block.get("kind","")),"role":String(block.get("role","")),
		"requires_tool":int(block.get("requires_tool",0)),"hp":float(block.get("hp",0.0))}

func _route_barrier_report() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for barrier in route_locked_barriers:
		var rect: Rect2 = barrier.rect
		result.append({"id":barrier.id,"requires_tool":barrier.requires_tool,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],
			"player_clearance":float(world.PLAYER_RADIUS) + 0.5})
	return result

func _bits(value: int) -> int:
	var count: int = 0
	while value > 0:
		count += value & 1
		value >>= 1
	return count

func _sum(values: Dictionary) -> int:
	var total: int = 0
	for value in values.values(): total += int(value)
	return total

func _delta(after: Dictionary, before: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in after:
		var amount: int = int(after[key]) - int(before.get(key,0))
		if amount != 0: result[key] = amount
	return result

func _frame_stats(raw: Array[float]) -> Dictionary:
	var sorted: Array[float] = raw.duplicate()
	sorted.sort()
	var sum: float = 0.0
	var slow: int = 0
	for sample in raw:
		sum += sample
		if sample > 33.34: slow += 1
	return {"frames":raw.size(),"average_fps":1000.0 * float(raw.size()) / maxf(0.001,sum),
		"p95_ms":sorted[clampi(ceili(sorted.size()*0.95)-1,0,sorted.size()-1)],
		"p99_ms":sorted[clampi(ceili(sorted.size()*0.99)-1,0,sorted.size()-1)],"max_ms":sorted[-1],"over_33_ms":slow}

func _range(raw: Array[float]) -> Dictionary:
	var sorted: Array[float] = raw.duplicate()
	sorted.sort()
	return {"min":sorted[0],"max":sorted[-1],"p95":sorted[clampi(ceili(sorted.size()*0.95)-1,0,sorted.size()-1)]}

func _xy(value: Vector2) -> Array[float]:
	return [value.x,value.y]

func _settle(seconds: float) -> void:
	var start: int = Time.get_ticks_usec()
	while Time.get_ticks_usec()-start < int(seconds*1000000.0): await process_frame

func _capture(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))

func _write_json(path: String, value: Dictionary) -> void:
	var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		_fail("Cannot write " + path)
		return
	file.store_string(JSON.stringify(value,"\t"))
	file.close()

func _fail(message: String) -> bool:
	failed = true
	push_error("SUSTAINED_MINING_FAILED " + message)
	quit(2)
	return false
