class_name EndlessDeepLayout
extends RefCounted
## One coordinate space, streamed in three deterministic, adjacent geology bands.
## Bands are storage/render units: their seams contain ordinary mineable rock.

const CHUNK_COLS: int = 40
const CHUNK_ROWS: int = 22
const ACTIVE_CHUNKS: int = 3
const TILE_SIZE: float = 64.0
const METRES_PER_CELL: float = 2.0
const RESOURCE_IDS: Array[String] = ["lumenstone", "deep_alloy", "memory_silk", "echo_crystal", "waystone"]


static func seed_for(world_seed: int, depth: int) -> int:
	return absi((world_seed * 73856093) ^ ((depth + 1) * 19349663) ^ 1597463007) & 2147483647


static func entrance_column(world_seed: int, depth: int) -> int:
	return 14 + posmod(seed_for(world_seed, depth), 12)


static func generate(world_seed: int, depth: int) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_for(world_seed, depth)
	var cells: PackedByteArray = PackedByteArray()
	cells.resize(CHUNK_COLS * CHUNK_ROWS)
	cells.fill(0)
	var rooms: Array[Dictionary] = []
	var branches: Array[Dictionary] = []
	var route: Array[Vector2i] = []
	for row in [4, 11, 18]:
		var center: Vector2i = Vector2i(rng.randi_range(13, 26), row)
		route.append(center)
		_carve(cells, center, 3)
		rooms.append({"cell": center, "radius": 3, "main": true})
	for index in range(1, route.size()):
		_corridor(cells, route[index - 1], route[index], 1)
	var entrance: Vector2i = Vector2i(entrance_column(world_seed, depth), 0)
	var exit_cell: Vector2i = Vector2i(entrance_column(world_seed, depth + 1), CHUNK_ROWS - 1)
	_corridor(cells, entrance, route[0], 1)
	_corridor(cells, route[-1], exit_cell, 1)
	for index in 4:
		var left: bool = index % 2 == 0
		var center: Vector2i = Vector2i(rng.randi_range(5, 8) if left else rng.randi_range(31, 34), 5 if index < 2 else 17)
		_corridor(cells, route[0 if index < 2 else 2], center, 1)
		_carve(cells, center, 3)
		var room: Dictionary = {"cell": center, "radius": 3, "main": false, "branch": index}
		branches.append(room)
		rooms.append(room)
	# These natural rock bands make digging the route forward mandatory. They are
	# neither timed gates nor tool locks, and can be mined anywhere across the width.
	var contour_phase: float = float(posmod(seed_for(world_seed, depth), 97)) * 0.13
	for col in range(2, CHUNK_COLS - 2):
		var upper: int = 8 + roundi(sin(float(col) * 0.21 + contour_phase))
		var lower: int = 15 + roundi(sin(float(col) * 0.17 - contour_phase))
		for row in [upper, upper + 1, lower]:
			cells[row * CHUNK_COLS + col] = 0
	if depth == 1:
		for col in CHUNK_COLS:
			cells[col] = 0
	return {"cells": cells, "rooms": rooms, "branches": branches, "entrance": entrance, "exit": exit_cell}


static func ore_for_cell(world_seed: int, depth: int, index: int) -> Dictionary:
	var value: int = absi(seed_for(world_seed, depth) ^ (index * 83492791)) & 2147483647
	var richness: float = log(1.0 + float(maxi(1, depth))) / log(2.0)
	var rare: bool = float(value % 1000) < minf(420.0, 95.0 + richness * 27.0)
	var available: int = clampi(2 + depth / 3, 2, RESOURCE_IDS.size())
	var kind: String = RESOURCE_IDS[(value / 1009) % available]
	var amount: int = 1 + floori(richness * 0.7)
	if rare:
		amount *= 4 + (value / 1013) % 3
	return {"kind": kind, "amount": amount, "rare": rare}


static func node_yield(depth: int, variation: int) -> int:
	return 14 + floori(8.0 * log(1.0 + float(maxi(1, depth))) / log(2.0)) + posmod(variation, 7)


static func _carve(cells: PackedByteArray, center: Vector2i, radius: int) -> void:
	for row in range(maxi(0, center.y - radius), mini(CHUNK_ROWS, center.y + radius + 1)):
		for col in range(maxi(2, center.x - radius), mini(CHUNK_COLS - 2, center.x + radius + 1)):
			if Vector2(Vector2i(col, row) - center).length() <= float(radius) + 0.35:
				cells[row * CHUNK_COLS + col] = 1


static func _corridor(cells: PackedByteArray, from: Vector2i, to: Vector2i, radius: int) -> void:
	var cursor: Vector2i = from
	while cursor != to:
		_carve(cells, cursor, radius)
		if cursor.x != to.x:
			cursor.x += signi(to.x - cursor.x)
		else:
			cursor.y += signi(to.y - cursor.y)
	_carve(cells, to, radius)
