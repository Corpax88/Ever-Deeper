extends RefCounted
## Stateful rectangle placement only. Feedback owners retain their clocks/input.
const RETAIN_CLEARANCE := 18.0
const PLACEMENT_CLEARANCE := 32.0
const MAX_CANDIDATES := 80
const CROWDED_RETRY_MSEC := 200

var _offset := Vector2.ZERO
var _valid := false
var _last_clear := true
var _last_search_msec := 0
var _previous_rect := Rect2()
var _previous_obstacles: Array[Rect2] = []
var last_reflow: Dictionary = {}


func reset() -> void:
	_valid = false
	last_reflow.clear()


func place(preferred: Vector2, size: Vector2, safe: Rect2, obstacles: Array[Rect2]) -> Vector2:
	var maximum := (safe.end - size).max(safe.position)
	var now := Time.get_ticks_msec()
	if _valid:
		var retained := (preferred + _offset).clamp(safe.position, maximum)
		if is_clear(Rect2(retained, size), obstacles):
			_last_clear = true
			return _remember(retained, size, obstacles)
		for obstacle_index in obstacles.size():
			var expanded := obstacles[obstacle_index].grow(RETAIN_CLEARANCE)
			if Rect2(retained, size).intersects(expanded):
				last_reflow = {"time_msec": now, "previous_rect": _previous_rect, "retained_rect": Rect2(retained, size), "obstacle_index": obstacle_index, "expanded_obstacle": expanded, "previous_expanded_obstacle": _previous_obstacles[obstacle_index].grow(RETAIN_CLEARANCE) if obstacle_index < _previous_obstacles.size() else Rect2()}
				break
		# Reuse the bounded fallback while a crowded viewport has no free slot.
		if not _last_clear and now - _last_search_msec < CROWDED_RETRY_MSEC:
			return _remember(retained, size, obstacles)
	var best := preferred.clamp(safe.position, maximum)
	var candidates: Array[Vector2] = [best]
	var seen: Dictionary = {best.snapped(Vector2.ONE * 0.01): true}
	# Seed coherent positions above/below real blockers before branching.
	for obstacle in obstacles:
		if not obstacle.has_area():
			continue
		for candidate_y in [obstacle.position.y - PLACEMENT_CLEARANCE - size.y, obstacle.end.y + PLACEMENT_CLEARANCE]:
			var position := Vector2(best.x, candidate_y).clamp(safe.position, maximum)
			var key := position.snapped(Vector2.ONE * 0.01)
			if not seen.has(key) and candidates.size() < MAX_CANDIDATES:
				seen[key] = true
				candidates.append(position)
	var best_score := INF
	var best_overlap := INF
	var index := 0
	while index < candidates.size() and index < MAX_CANDIDATES:
		var candidate: Vector2 = candidates[index]
		index += 1
		var rect := Rect2(candidate, size)
		var overlap := 0.0
		var blocking := Rect2()
		for obstacle in obstacles:
			if not obstacle.has_area():
				continue
			# Select with breathing room, retain at the smaller safety margin.
			var expanded := obstacle.grow(PLACEMENT_CLEARANCE)
			var area := rect.intersection(expanded).get_area()
			overlap += area
			if area > 0.0 and not blocking.has_area():
				blocking = expanded
		var score := overlap * 1000000.0 + candidate.distance_squared_to(preferred)
		if score < best_score:
			best = candidate
			best_score = score
			best_overlap = overlap
		if not blocking.has_area():
			continue
		for next in [Vector2(blocking.position.x - size.x, candidate.y), Vector2(blocking.end.x, candidate.y), Vector2(candidate.x, blocking.position.y - size.y), Vector2(candidate.x, blocking.end.y)]:
			var position: Vector2 = Vector2(next).clamp(safe.position, maximum)
			var key := position.snapped(Vector2.ONE * 0.01)
			if not seen.has(key) and candidates.size() < MAX_CANDIDATES:
				seen[key] = true
				candidates.append(position)
	_offset = best - preferred
	_valid = true
	_last_clear = best_overlap <= 0.0
	_last_search_msec = now
	return _remember(best, size, obstacles)


func is_clear(rect: Rect2, obstacles: Array[Rect2]) -> bool:
	for obstacle in obstacles:
		if obstacle.has_area() and rect.intersects(obstacle.grow(RETAIN_CLEARANCE)):
			return false
	return true


func _remember(position: Vector2, size: Vector2, obstacles: Array[Rect2]) -> Vector2:
	_previous_rect = Rect2(position, size)
	_previous_obstacles = obstacles
	return position
