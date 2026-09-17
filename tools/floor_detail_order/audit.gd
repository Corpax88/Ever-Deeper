extends RefCounted
## Source-bound geometry and command-family audit; this does not count GL draws.

static func detail_quad(offset: Vector2) -> PackedVector2Array:
	var first: Vector2 = offset - Vector2(7,2)
	var last: Vector2 = offset + Vector2(8,3)
	# Godot 4.7.2 canvas_item_add_line, width 2, antialiased=false.
	var perpendicular: Vector2 = (first-last).orthogonal().normalized()
	return PackedVector2Array([first+perpendicular,first-perpendicular,last-perpendicular,last+perpendicular])

static func bounds(points: PackedVector2Array) -> Rect2:
	var box: Rect2 = Rect2(points[0],Vector2.ZERO)
	for point in points: box = box.expand(point)
	return box

static func detail(world: Node, cell: Vector2i) -> Dictionary:
	var absolute: Vector2i = world.absolute_cell(cell)
	var key: int = absi(absolute.x*92821+absolute.y*68917+world._seed_for_depth(world.depth_at_position(world._cell_center(cell)))*3)
	if key % 5 != 0: return {}
	var offset: Vector2 = Vector2(float(10+key%39),float(11+(key/7)%37))
	return {"cell":cell,"bounds":Rect2(Vector2(cell)*world.TILE_SIZE+bounds(detail_quad(offset)).position,bounds(detail_quad(offset)).size)}

static func geometry_proof() -> Dictionary:
	var enclosing: Rect2 = Rect2(0,0,64,64)
	var minimum_gap: float = INF
	var checks: int = 0
	var ok: bool = true
	# Every possible offset, more than the correlated key residues can realize.
	for x in range(10,49):
		for y in range(11,48):
			var line: Rect2 = bounds(detail_quad(Vector2(x,y)))
			ok = ok and enclosing.encloses(line)
			for relative in [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)]:
				var rock: Rect2 = Rect2(relative*64,Vector2(64,64)).grow(.5)
				ok = ok and not line.intersects(rock,true)
				checks += 1
			minimum_gap = minf(minimum_gap,minf(line.position.x-.5,63.5-line.end.x))
	# For damage lines, the engine clamps its miter factor to 3 and uses a
	# 1.25px feather. Authored width <=3, compensated width <=3. Overbound every
	# join/cap by 3*(3/2+1.25)=8.25px. Damage vertices span x10..56,y12..51:
	# the resulting rectangle stays inside the rock's existing 0.5px grow.
	var damage_bound: Rect2 = Rect2(10,12,46,39).grow(8.25)
	var rock_bound: Rect2 = enclosing.grow(.5)
	var damage_inside: bool = rock_bound.encloses(damage_bound)
	# Negative control: the same intersection predicate rejects genuine overlap.
	var overlap_rejected: bool = bounds(detail_quad(Vector2(20,20))).intersects(enclosing,true)
	return {"passed":ok and damage_inside and overlap_rejected,"line_offsets":39*37,"adjacent_checks":checks,
		"minimum_horizontal_gap_pixels":minimum_gap,"damage_bound":str(damage_bound),"damage_inside_rock_bound":damage_inside,
		"negative_overlap_rejected":overlap_rejected,"engine_miter_limit":3.0,"engine_feather":1.25,
		"limit":"Geometry bounds only; frozen raster parity remains mandatory."}

static func _runs(commands: Array[String]) -> int:
	var total: int = 0
	var previous: String = ""
	for command in commands:
		if command != previous or command.begins_with("polygon:"): total += 1
		previous = command
	return total

static func inventory(world: Node, first: Vector2i, last: Vector2i) -> Dictionary:
	var all_a: Array[String] = []
	var all_b: Array[String] = []
	var isolated_a: int = 0
	var isolated_b: int = 0
	var eligible_lines: int = 0
	var crossed_solid_commands: int = 0
	var overlap_count: int = 0
	var changed_sections: int = 0
	var strip_count: int = 0
	for row in range(first.y,last.y+1):
		for start in range(first.x/4*4,last.x+1,4):
			var a: Array[String] = []
			var solid: Array[String] = []
			var floor: Array[String] = []
			var earlier_lines: Array[Dictionary] = []
			for column in range(start,mini(start+4,world.GRID_SIZE.x)):
				var cell: Vector2i = Vector2i(column,row)
				if world._is_floor(cell):
					var line: Dictionary = detail(world,cell)
					if line.is_empty(): continue
					eligible_lines += 1
					a.append("primitive:floor-detail")
					floor.append("primitive:floor-detail")
					earlier_lines.append(line)
				else:
					var commands: Array[String] = ["rectangle:native-rock"]
					if world._cell_diggable(cell) and world._has_floor_neighbor(cell):
						var reward: Dictionary = world.DeepLayout.ore_for_cell(int(world.get_node("/root/RunState").world_seed),world.depth_at_position(world._cell_center(cell)),world._chunk_cell_index(cell))
						if bool(reward.rare): commands.append("rectangle:ore:"+String(reward.kind))
					if int(world.dig_damage.get(cell,0))>0:
						commands.append_array(["polygon:damage-center","polygon:damage-left","polygon:damage-right"])
					a.append_array(commands)
					solid.append_array(commands)
					var solid_bounds: Rect2 = Rect2(Vector2(cell)*64,Vector2(64,64)).grow(.5)
					for line in earlier_lines:
						crossed_solid_commands += commands.size()
						if line.bounds.intersects(solid_bounds,true): overlap_count += 1
			var b: Array[String] = solid.duplicate()
			b.append_array(floor)
			if a != b: changed_sections += 1
			isolated_a += _runs(a)
			isolated_b += _runs(b)
			all_a.append_array(a)
			all_b.append_array(b)
			strip_count += 1
	return {"first_cell":str(first),"last_cell":str(last),"strips":strip_count,"changed_sections":changed_sections,
		"floor_lines":eligible_lines,"crossed_solid_commands":crossed_solid_commands,"overlaps":overlap_count,
		"concatenated_runs_a":_runs(all_a),"concatenated_runs_b":_runs(all_b),
		"isolated_strip_runs_a":isolated_a,"isolated_strip_runs_b":isolated_b,
		"concatenated_reduction":_runs(all_a)-_runs(all_b),"isolated_reduction":isolated_a-isolated_b,
		"limit":"Command-family model, not actual renderer draws. Real light-specialization/material/clipping splits require rendered counters. Rare ore conservatively counts its authored texture command."}
