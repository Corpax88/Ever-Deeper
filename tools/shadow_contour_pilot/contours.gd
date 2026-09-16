extends RefCounted
## Study only: exact tile-union boundaries; no drawing or terrain changes.

static func from_spans(spans: Array[Rect2], tile: float) -> Array[PackedVector2Array]:
	var occupied: Dictionary = {}
	var native_vertices: Dictionary = {}
	for rect in spans:
		var begin := Vector2i((rect.position / tile).round())
		var end := Vector2i((rect.end / tile).round())
		for corner in [begin,Vector2i(end.x,begin.y),end,Vector2i(begin.x,end.y)]: native_vertices[corner] = true
		for y in range(begin.y, end.y):
			for x in range(begin.x, end.x): occupied[Vector2i(x, y)] = true
	var starts: Array[Vector2i] = []
	var ends: Array[Vector2i] = []
	var outgoing: Dictionary = {}
	for cell: Vector2i in occupied:
		var corners: Array[Vector2i] = [cell, cell + Vector2i.RIGHT, cell + Vector2i.ONE, cell + Vector2i.DOWN]
		var neighbors: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
		for side in 4:
			if occupied.has(cell + neighbors[side]): continue
			var start: Vector2i = corners[side]
			if not outgoing.has(start): outgoing[start] = []
			outgoing[start].append(starts.size())
			starts.append(start)
			ends.append(corners[(side + 1) % 4])
	var used := PackedByteArray()
	used.resize(starts.size())
	var result: Array[PackedVector2Array] = []
	for first in starts.size():
		if used[first]: continue
		var points: Array[Vector2i] = []
		var edge: int = first
		while true:
			assert(not used[edge], "Boundary edge visited twice")
			used[edge] = 1
			points.append(starts[edge])
			var endpoint: Vector2i = ends[edge]
			if endpoint == starts[first]: break
			var direction: Vector2i = endpoint - starts[edge]
			# At a diagonal touch, turn around the same solid cell instead of
			# joining two components through a point of empty space.
			var preferences: Array[Vector2i] = [Vector2i(-direction.y, direction.x), direction, Vector2i(direction.y, -direction.x), -direction]
			var next: int = -1
			for wanted in preferences:
				for possible: int in outgoing.get(endpoint, []):
					if not used[possible] and ends[possible] - endpoint == wanted:
						next = possible
						break
				if next >= 0: break
			assert(next >= 0, "Boundary must close")
			if next < 0: return []
			edge = next
		for simple: Array in _simple_loops(points):
			var polygon := PackedVector2Array()
			for index in simple.size():
				var incoming: Vector2i = simple[index] - simple[(index - 1 + simple.size()) % simple.size()]
				var leaving: Vector2i = simple[(index + 1) % simple.size()] - simple[index]
				if incoming != leaving or native_vertices.has(simple[index]): polygon.append(Vector2(simple[index]) * tile)
			assert(polygon.size() >= 4 and polygon.size() < 16384, "Bounded orthogonal loop required")
			result.append(polygon)
	return result

static func _simple_loops(points: Array[Vector2i]) -> Array:
	# A hole may touch the outer boundary at one grid vertex. Preserve both
	# closed edge loops without sending a self-touching polygon to Godot.
	var pending: Array = [points]
	var result: Array = []
	while not pending.is_empty():
		var loop: Array = pending.pop_back()
		var seen: Dictionary = {}
		var split := false
		for index in loop.size():
			var point: Vector2i = loop[index]
			if seen.has(point):
				var before: int = seen[point]
				pending.append(loop.slice(before,index))
				pending.append(loop.slice(0,before)+loop.slice(index))
				split = true
				break
			seen[point] = index
		if not split: result.append(loop)
	return result
