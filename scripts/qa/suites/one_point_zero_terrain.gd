extends RefCounted
## Connectivity for a mining world: floor and ordinary mineable rock are valid
## traversal cells; permanent rock is not. The player must spawn on actual floor.

static func connectivity(world: Node) -> Dictionary:
	var spawn: Vector2i = world._world_to_cell(world.player.global_position)
	var reached: Dictionary = {spawn: true}
	var queue: Array[Vector2i] = [spawn]
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		for direction in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + direction
			if reached.has(next) or not world._cell_in_bounds(next):
				continue
			if not world._is_floor(next) and not world._cell_diggable(next):
				continue
			reached[next] = true
			queue.append(next)
	var targets: Array[Vector2] = [Vector2(world.down_shaft_position)]
	for resource in world.resources:
		targets.append(Vector2(resource.position))
	for site in world.discovery_sites:
		targets.append(Vector2(site.position))
	for relic in Array(world.stream_snapshot().get("relics", [])):
		targets.append(Vector2(relic.position))
	var connected: bool = true
	for target in targets:
		connected = connected and reached.has(world._world_to_cell(target))
	return {"spawn_clear": not world.collision_at(world.player.global_position),
		"all_targets_reachable": connected, "target_count": targets.size(),
		"reachable_cells": reached.size()}
