extends RefCounted
## Reads the existing swing owner at its visual publication point, before damage.
## This does not choose targets, advance clocks, apply hits or change controls.
static func read(world: Node) -> Dictionary:
	var id: String = String(world.name)
	match id:
		"MossveinMine":
			if world.current_target.x < 0 or world.current_target.y < 0: return {}
			return _packet(world._cell_center(world.current_target), str(world.current_target), world.swing_elapsed, world.swing_duration, world._tool_strike_progress())
		"RootwoundWorld":
			if world.current_target_kind == "rock":
				var index: int = world.current_target_rock
				if index < 0 or index >= world.rocks.size(): return {}
				return _packet(Vector2(world.rocks[index].position), "rock:" + str(index), world.swing_elapsed, world.swing_duration, world._tool_strike_progress())
			if world.current_target_kind.is_empty() or world.current_target_cell.x < 0 or world.current_target_cell.y < 0: return {}
			return _packet(world._cell_center(world.current_target_cell), str(world.current_target_cell), world.swing_elapsed, world.swing_duration, world._tool_strike_progress())
		"DeepheartWorld":
			if not world.SEAL_POSITIONS.has(world.mining_target): return {}
			return _packet(Vector2(world.SEAL_POSITIONS[world.mining_target]), world.mining_target, world.mining_elapsed, world.mining_duration, 0.38)
		"SurfaceWorld":
			var context: String = world.active_context
			var hit: float = world._tool_strike_progress()
			if context == "ore_mountain":
				return _locked(_packet(world.ore_mountain_swing_target, context, world.ore_mountain_swing_elapsed, world.ore_mountain_swing_duration, hit),world.ore_mountain_swing_active,context)
			if context == "moonglass_resource":
				return _locked(_node_packet(world.moon_bloom_nodes, world.moon_bloom_target_index, context, world.moon_bloom_swing_elapsed, world.moon_bloom_swing_duration, hit),world.moon_bloom_swing_active,context)
			if world.surface_resource_mountains.has(context):
				var mountain: Dictionary = world.surface_resource_mountains[context]
				return _locked(_packet(Vector2(mountain.swing_target), context, mountain.swing_elapsed, mountain.swing_duration, hit),bool(mountain.swing_active),context)
			for vein_id in world.timed_surface_veins:
				if context != String(world._timed_surface_config(vein_id).context): continue
				var vein: Dictionary = world.timed_surface_veins[vein_id]
				return _locked(_node_packet(vein.nodes, vein.target_index, vein_id, vein.swing_elapsed, vein.swing_duration, hit),bool(vein.swing_active),context)
	return {}

static func _node_packet(nodes: Array, index: int, id: String, elapsed: float, duration: float, hit: float) -> Dictionary:
	if index < 0 or index >= nodes.size(): return {"elapsed":elapsed}
	return _packet(Vector2(nodes[index].position), id + ":" + str(index), elapsed, duration, hit)

static func _packet(target: Vector2, id: String, elapsed: float, duration: float, hit: float) -> Dictionary:
	if not target.is_finite() or duration <= 0.0 or hit <= 0.0 or hit >= 1.0: return {}
	return {"target":target, "id":id, "elapsed":elapsed, "duration":duration, "hit":hit}

static func _locked(packet: Dictionary, active: bool, owner: String) -> Dictionary:
	packet.owner = owner
	packet.locked = true
	packet.active = active
	return packet
