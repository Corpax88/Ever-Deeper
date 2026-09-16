extends "res://scripts/world/depth/rootwound_world.gd"
## Frozen 0623b63 draw dispatch/fingerprint, opt-in reference only.
## All other runtime behavior is inherited unchanged from the candidate.

func _draw_partitioned_depth(start: Vector2i, finish: Vector2i) -> void:
	lit_draw_sections.begin(self)
	var revision: int = _reference_terrain_draw_fingerprint()
	# Preserve both original passes and exact row/column order, including overlaps.
	for pass_index in 2:
		for row in range(maxi(0, start.y), mini(rows - 1, finish.y) + 1):
			for first_col in range(maxi(0, start.x) / 6 * 6, mini(cols - 1, finish.x) + 1, 6):
				lit_draw_sections.add_cached(Vector3i(row, first_col, pass_index), revision, _draw_terrain_section.bind(row, first_col, mini(first_col + 5, cols - 1), pass_index))
	lit_draw_sections.add(_draw_pocket_landmarks)
	lit_draw_sections.add(_draw_drill_gates)
	lit_draw_sections.add(_draw_resources)
	lit_draw_sections.add(_draw_depth_landmarks)
	for impact in impacts: lit_draw_sections.add(_draw_impact.bind(impact))
	for drop in drops: lit_draw_sections.add(_draw_drop.bind(drop))
	lit_draw_sections.add(_draw_target)
	lit_draw_sections.finish()


func _reference_terrain_draw_fingerprint() -> int:
	# Packed terrain is hashed in native code. Small scalar resource flags cover
	# mineral hints, including respawn/discovery and direct restored-save changes.
	var signature: int = hash(terrain_hp) ^ hash(concealed_cells) ^ mine_id.hash() ^ int(RunState.world_seed)
	for rock in rocks:
		signature = ((signature * 31) ^ int(bool(rock.broken))) & 0x7fffffff
	for cavern in caverns:
		signature = ((signature * 31) ^ int(_cavern_is_discovered(String(cavern.id)))) & 0x7fffffff
	return signature

