class_name RootwoundLayout
extends RefCounted



const MINE_ID: = "mossMine"
const TILE_SIZE: = 48.0
const PORTAL_RESOURCE_CLEARANCE: = 136.0
const STATION_RESOURCE_CLEARANCE: = 168.0
const STATION_HALF_SEPARATION: = 168.0
const STATION_VERTICAL_OFFSET: = 148.0
const PORTAL_RADIUS: = 78.0
const UINT32_MASK: = 4294967295
const GOLDEN_RATIO_SEED: = 2654435769


static func depth_entrance(data: Dictionary, world_seed: int, mine_id: String = MINE_ID) -> Vector2:
	var mine: Dictionary = Dictionary(data.MINE_DEFINITIONS[mine_id])
	var discovery_profile: Dictionary = Dictionary(data.MINE_DISCOVERY_PROFILES[mine_id])
	var depth_one: Dictionary = Dictionary(data.MINE_DISCOVERIES[mine_id])
	var depth_two: Dictionary = Dictionary(data.MINE_DEPTH_DISCOVERIES[mine_id])
	var cols: = ceili(float(mine.width) / TILE_SIZE)
	var rows: = ceili(float(mine.height) / TILE_SIZE)
	var random_state: = [
		(int(world_seed) ^ int(discovery_profile.seed) ^ GOLDEN_RATIO_SEED) & UINT32_MASK
	]
	var caverns: Array = Array(depth_one.caverns).duplicate(true)
	caverns.append_array(Array(depth_two.caverns).duplicate(true))
	var depth_one_resources: = _resource_points(Array(mine.rocks))
	depth_one_resources.append_array(_resource_points(Array(depth_one.rocks)))
	var depth_two_resources: = _resource_points(Array(depth_two.rocks))
	var first_row: = ceili(1700.0 / TILE_SIZE)
	var usable_cols: = maxi(1, cols - 6)
	var usable_rows: = maxi(1, rows - first_row - 7)
	var selected_col: = floori(float(cols) * 0.5)
	var selected_row: = floori(float(rows) * 0.72)
	var found: = false

	for _attempt in 240:
		var candidate_col: = 3 + floori(_next_random(random_state) * float(usable_cols))
		var candidate_row: = first_row + floori(_next_random(random_state) * float(usable_rows))
		if _valid_candidate(
			candidate_col,
			candidate_row,
			mine,
			caverns,
			depth_one_resources,
			depth_two_resources
		):
			selected_col = candidate_col
			selected_row = candidate_row
			found = true
			break

	if not found:
		var candidate_count: = usable_cols * usable_rows
		var start: = floori(_next_random(random_state) * float(candidate_count))
		for step in candidate_count:
			var index: = (start + step) % candidate_count
			var candidate_col: = 3 + index % usable_cols
			var candidate_row: = first_row + floori(float(index) / float(usable_cols))
			if _valid_candidate(
				candidate_col,
				candidate_row,
				mine,
				caverns,
				depth_one_resources,
				depth_two_resources
			):
				selected_col = candidate_col
				selected_row = candidate_row
				break

	return Vector2(
		(float(selected_col) + 0.5) * TILE_SIZE,
		(float(selected_row) + 0.5) * TILE_SIZE
	)


static func stations(data: Dictionary, entrance: Vector2, mine_id: String = MINE_ID) -> Dictionary:
	var mine: Dictionary = Dictionary(data.MINE_DEFINITIONS[mine_id])
	var station_center_x: = clampf(
		entrance.x,
		STATION_HALF_SEPARATION + 120.0,
		float(mine.width) - STATION_HALF_SEPARATION - 120.0
	)
	var station_y: = clampf(entrance.y - STATION_VERTICAL_OFFSET, 110.0, float(mine.height) - 110.0)
	return {
		"sell": {
			"x": station_center_x - STATION_HALF_SEPARATION,
			"y": station_y,
			"radius": 104.0,
		},
		"forge": {
			"x": station_center_x + STATION_HALF_SEPARATION,
			"y": station_y,
			"radius": 104.0,
		},
	}


static func entry_spawn(data: Dictionary, entrance: Vector2, mine_id: String = MINE_ID) -> Vector2:
	var mine: Dictionary = Dictionary(data.MINE_DEFINITIONS[mine_id])
	return Vector2(
		clampf(entrance.x + 92.0, 52.0, float(mine.width) - 52.0),
		clampf(entrance.y + 108.0, 70.0, float(mine.height) - 58.0)
	)


static func _next_random(state: Array) -> float:
	state[0] = (int(state[0]) * 1664525 + 1013904223) & UINT32_MASK
	return float(state[0]) / 4294967300.0


static func _resource_points(entries: Array) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for entry_value in entries:
		if entry_value is Array:
			var entry: Array = Array(entry_value)
			points.append(Vector2(float(entry[1]), float(entry[2])))
		else:
			var entry: Dictionary = Dictionary(entry_value)
			points.append(Vector2(float(entry.x), float(entry.y)))
	return points


static func _valid_candidate(
	col: int,
	row: int,
	mine: Dictionary,
	caverns: Array,
	depth_one_resources: Array[Vector2],
	depth_two_resources: Array[Vector2]
) -> bool:
	var point: = Vector2((float(col) + 0.5) * TILE_SIZE, (float(row) + 0.5) * TILE_SIZE)
	for cavern_value in caverns:
		var cavern: Dictionary = Dictionary(cavern_value)
		var normalized: = (
			pow((point.x - float(cavern.x)) / (float(cavern.rx) + 190.0), 2.0)
			+ pow((point.y - float(cavern.y)) / (float(cavern.ry) + 190.0), 2.0)
		)
		if normalized < 1.0:
			return false

	for solid_value in mine.solids:
		var solid: Dictionary = Dictionary(solid_value)
		if (
			point.x > float(solid.x) - 150.0
			and point.x < float(solid.x) + float(solid.w) + 150.0
			and point.y > float(solid.y) - 150.0
			and point.y < float(solid.y) + float(solid.h) + 150.0
		):
			return false

	for barrier_value in mine.barriers:
		var barrier: Dictionary = Dictionary(barrier_value)
		if (
			point.x > float(barrier.x) - 180.0
			and point.x < float(barrier.x) + float(barrier.w) + 180.0
			and point.y > float(barrier.y) - 180.0
			and point.y < float(barrier.y) + float(barrier.h) + 180.0
		):
			return false

	for resource_position in depth_one_resources:
		if point.distance_to(resource_position) < PORTAL_RESOURCE_CLEARANCE:
			return false
	for resource_position in depth_two_resources:
		if point.distance_to(resource_position) < PORTAL_RESOURCE_CLEARANCE:
			return false

	var station_center_x: = clampf(
		point.x,
		STATION_HALF_SEPARATION + 120.0,
		float(mine.width) - STATION_HALF_SEPARATION - 120.0
	)
	var station_y: = clampf(point.y - STATION_VERTICAL_OFFSET, 110.0, float(mine.height) - 110.0)
	var station_positions: = [
		Vector2(
			station_center_x - STATION_HALF_SEPARATION,
			station_y
		),
		Vector2(
			station_center_x + STATION_HALF_SEPARATION,
			station_y
		),
	]
	for resource_position in depth_two_resources:
		for station_position in station_positions:
			if station_position.distance_to(resource_position) < STATION_RESOURCE_CLEARANCE:
				return false

	var mine_entrance: = Vector2(float(mine.entrance.x), float(mine.entrance.y))
	return point.distance_to(mine_entrance) > 700.0
