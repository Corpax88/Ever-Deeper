var study_route: Array[Vector2i] = []
var study_targets: Array[Dictionary] = []
var study_previous_mined: int = 0
var study_previous_removed: int = 0
var study_previous_distance: float = 0.0
var study_actual_elapsed: float = 0.0
var study_planner_calls: int = 0
var study_planner_usec: int = 0
var study_planner_max_usec: int = 0
var study_input: Vector2 = Vector2(INF, INF)
var study_route_failed: bool = false

func _study_drive(_elapsed: float) -> void:
	main._set_mine_held(true)
	var point: Vector2 = world.player.global_position
	while not study_route.is_empty() and point.distance_to(world._cell_center(study_route[0])) <= 6.0:
		study_route.remove_at(0)
	if study_route.is_empty():
		var began: int = Time.get_ticks_usec()
		_study_plan(world._world_to_cell(point))
		var cost: int = Time.get_ticks_usec() - began
		study_planner_calls += 1
		study_planner_usec += cost
		study_planner_max_usec = maxi(study_planner_max_usec, cost)
	if study_route.is_empty():
		study_route_failed = true
		main._on_joystick_movement(Vector2.ZERO)
		return
	var remaining: Vector2 = world._cell_center(study_route[0]) - point
	# Follow cardinal cell-center routes, with proportional input near a turn.
	# The ordinary controller resolves every movement and collision.
	var motion: Vector2 = Vector2(remaining.x, 0) if absf(remaining.x) > 4.0 else Vector2(0, remaining.y)
	var input: Vector2 = (motion / maxf(24.0, float(world.player.movement_speed) * 0.10)).limit_length(1.0)
	if not input.is_equal_approx(study_input):
		study_input = input
		main._on_joystick_movement(study_input)

func _study_plan(start: Vector2i) -> void:
	var frontier: Array[Vector2i] = [start]
	var parents: Dictionary = {start:start}
	var cursor: int = 0
	while cursor < frontier.size() and cursor < 4096:
		var cell: Vector2i = frontier[cursor]
		cursor += 1
		for offset in [Vector2i.DOWN, Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP]:
			var next: Vector2i = cell + offset
			if not world._cell_in_bounds(next) or world._terrain_is_bedrock(next): continue
			if _study_mineable_wall(next):
				var chain: Array[Vector2i] = [cell]
				var at: Vector2i = cell
				while at != start:
					at = Vector2i(parents[at])
					chain.append(at)
				chain.reverse()
				# Existing floor is followed before aiming/moving into the live wall.
				chain.append(next)
				study_route = chain
				study_targets.append({"cell":str(next), "start":str(start), "hp":int(world.terrain_hp[world._cell_index(next)]), "mined_before":state.total_mined_resources()})
				return
			if parents.has(next) or world._visual_is_solid(next) or world._player_collides(world._cell_center(next)): continue
			parents[next] = cell
			frontier.append(next)

func _study_mineable_wall(cell: Vector2i) -> bool:
	if int(world.terrain_hp[world._cell_index(cell)]) <= 0: return false
	# Avoid aiming this ordinary-wall workload through a locked ore deposit.
	for index in Array(world.rocks_by_cell.get(cell, [])):
		if not bool(world.rocks[int(index)].broken): return false
	return true

func _study_removed_cells() -> int:
	var count: int = 0
	for hp in world.terrain_hp:
		if int(hp) <= 0: count += 1
	return count

func _study_window(row: Dictionary, raw_intervals: Array[float]) -> void:
	var seconds_actual: float = 0.0
	for value in raw_intervals: seconds_actual += value / 1000.0
	study_actual_elapsed += seconds_actual
	var mined_now: int = state.total_mined_resources()
	var removed_now: int = _study_removed_cells()
	row["intervals_ms"] = raw_intervals
	row["actual_seconds"] = seconds_actual
	row["actual_elapsed"] = study_actual_elapsed
	row["distance_delta"] = float(row.distance) - study_previous_distance
	row["mined_delta"] = mined_now - study_previous_mined
	row["removed_delta"] = removed_now - study_previous_removed
	row["valid_workload"] = float(row.distance_delta) > 48.0 and int(row.mined_delta) > 0 and int(row.removed_delta) > 0 and not study_route_failed
	row["terrain_hash"] = hash(world.terrain_hp)
	row["player"] = str(world.player.global_position)
	row["planner_calls"] = study_planner_calls
	row["planner_usec"] = study_planner_usec
	row["planner_max_usec"] = study_planner_max_usec
	row["terrain_cache"] = world.lit_draw_sections.debug_snapshot()
	study_previous_distance = float(row.distance)
	study_previous_mined = mined_now
	study_previous_removed = removed_now
