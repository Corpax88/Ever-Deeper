extends "res://scripts/qa/qa_context.gd"
## Crusher checks moved intact from main.gd.


func _run_crusher_impact_qa() -> void :
	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	main.mine_world.load_mine("mossMine")
	var tool= Dictionary(main.mine_world._current_tool())
	if not _crusher_impact_qa_require(
		String(RunState.starforge_variant) == "crusher"
		and float(tool.get("cooldown", 0.0)) > float(RunState.current_pickaxe().get("cooldown", 0.0)) * 2.0,
		"slow_powerful_profile"
	):
		return

	var center= Vector2i(20, 20)
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			main.mine_world.blocks[center + Vector2i(x_offset, y_offset)] = main.mine_world._make_block("stone", 999, 0, "terrain")
	main.mine_world._apply_crusher_shockwave(center, tool)
	var affected= 0
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var cell= center + Vector2i(x_offset, y_offset)
			if cell != center and int(Dictionary(main.mine_world.blocks[cell]).get("hp", 999)) < 999:
				affected += 1
	if not _crusher_impact_qa_require(affected == 24, "full_5x5_footprint"):
		return


	if not _crusher_impact_qa_require(
		main.mine_world.drops.is_empty() and RunState.mine_loose_loot("mossMine", 1).is_empty(),
		"non_break_has_no_resource_bundles"
	):
		return




	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			main.mine_world.blocks[center + Vector2i(x_offset, y_offset)] = main.mine_world._make_block("stone", 1, 0, "terrain")
	var origin: Vector2 = main.mine_world._cell_center(center)
	var child_count_before: int = main.mine_world.get_child_count()
	main.mine_world._spawn_drop(center, "stone", 1, origin)
	main.mine_world._apply_crusher_shockwave(center, tool)
	var visual_total= 0
	var visible_bundles= 0
	var directions= Vector4.ZERO
	var visual_by_id: Dictionary = {}
	for drop_value in main.mine_world.drops:
		var drop: Dictionary = Dictionary(drop_value)
		if not bool(drop.get("crusher_bundle", false)):
			continue
		if not bool(drop.get("visual_suppressed", false)):
			visible_bundles += 1
		var amount= int(drop.get("amount", 0))
		var persistent_id= String(drop.get("persistent_id", ""))
		visual_total += amount
		visual_by_id[persistent_id] = {"kind": String(drop.get("kind", "")), "amount": amount}
		var velocity= Vector2(drop.get("velocity", Vector2.ZERO))
		directions.x += 1.0 if velocity.x < -0.01 else 0.0
		directions.y += 1.0 if velocity.x > 0.01 else 0.0
		directions.z += 1.0 if velocity.y < -0.01 else 0.0
		directions.w += 1.0 if velocity.y > 0.01 else 0.0
	var persistent_total= 0
	var persistence_matches= true
	for stored_value in RunState.mine_loose_loot("mossMine", 1):
		var stored: Dictionary = Dictionary(stored_value)
		var stored_id= String(stored.get("id", ""))
		persistent_total += int(stored.get("amount", 0))
		persistence_matches = (
			persistence_matches
			and visual_by_id.has(stored_id)
			and String(Dictionary(visual_by_id[stored_id]).kind) == String(stored.get("kind", ""))
			and int(Dictionary(visual_by_id[stored_id]).amount) == int(stored.get("amount", 0))
		)
	if not _crusher_impact_qa_require(
		visual_total == 25
		and persistent_total == 25
		and persistence_matches
		and visible_bundles >= 4 and visible_bundles <= 12
		and directions.x > 0.0 and directions.y > 0.0 and directions.z > 0.0 and directions.w > 0.0
		and main.mine_world.get_child_count() == child_count_before,
		"real_radial_bundles_accounted"
	):
		return



	var sector_zero_index= -1
	for index in main.mine_world.drops.size():
		if int(main.mine_world.drops[index].get("crusher_sector", -1)) == 0:
			sector_zero_index = index
			break
	if not _crusher_impact_qa_require(sector_zero_index >= 0, "radial_sector_zero"):
		return
	var merge_id= String(main.mine_world.drops[sector_zero_index].persistent_id)
	var merge_amount= int(main.mine_world.drops[sector_zero_index].amount)
	main.mine_world.drops[sector_zero_index].age = 0.149
	var count_before_merge: int = main.mine_world.drops.size()
	main.mine_world._spawn_drop(center + Vector2i(2, 0), "stone", 1, origin)
	if not _crusher_impact_qa_require(
		main.mine_world.drops.size() == count_before_merge
		and String(main.mine_world.drops[sector_zero_index].persistent_id) == merge_id
		and int(main.mine_world.drops[sector_zero_index].amount) == merge_amount + 1,
		"merge_at_0149"
	):
		return
	main.mine_world.drops[sector_zero_index].age = 0.151
	main.mine_world._spawn_drop(center + Vector2i(2, 0), "stone", 1, origin)
	if not _crusher_impact_qa_require(main.mine_world.drops.size() == count_before_merge + 1, "new_bundle_at_0151"):
		return

	var pickup_radii: Array[float] = []
	for drill_level in range(4):
		RunState.drill_level = drill_level
		pickup_radii.append(RunState.resource_pickup_radius(48.0))
	if not _crusher_impact_qa_require(
		pickup_radii == [48.0, 80.0, 112.0, 144.0]
		and is_equal_approx(RunState.resource_pickup_radius(48.0, "singularity"), 48.0)
		and is_equal_approx(RunState.resource_pickup_radius(52.0), 148.0),
		"drill_pickup_range"
	):
		return
	RunState.drill_level = 1
	var crusher_bundle_snapshot: Array[Dictionary] = main.mine_world.drops.duplicate(true)
	main.mine_world.drops.clear()
	var magnet_target: Vector2 = main.mine_world.player.global_position + Vector2(100.0, -24.0)
	main.mine_world.drops.append({
		"kind": "stone",
		"amount": 1,
		"position": magnet_target,
		"velocity": Vector2.ZERO,
		"age": 0.2,
		"pocket_reward_id": "",
		"persistent_id": "",
		"settled_persisted": true,
	})
	main.mine_world._update_drops(1.0 / 60.0)
	var basic_distance: float = Vector2(main.mine_world.drops[0].position).distance_to(
		main.mine_world.player.global_position + Vector2(0, -24)
	)
	RunState.drill_level = 2
	main.mine_world._update_drops(1.0 / 60.0)
	var drill_distance: float = Vector2(main.mine_world.drops[0].position).distance_to(
		main.mine_world.player.global_position + Vector2(0, -24)
	)
	if not _crusher_impact_qa_require(
		is_equal_approx(basic_distance, 100.0) and drill_distance < basic_distance,
		"drill_pickup_magnet"
	):
		return
	main.mine_world.drops.assign(crusher_bundle_snapshot)
	RunState.drill_level = 3
	var drill_tool= Dictionary(main.mine_world._current_tool())
	var drill_impact= {
		"style": main.mine_world._tool_impact_style(drill_tool),
		"broken": true,
	}
	main.mine_world._attach_crusher_debris(drill_impact, center)
	if not _crusher_impact_qa_require(
		bool(drill_tool.get("is_drill", false))
		and String(drill_impact.style) == "drill"
		and bool(drill_impact.get("crusher_force", false))
		and not drill_impact.has("crusher_chunks"),
		"crusher_attunes_drill_visual"
	):
		return



	var generated_total= 27
	var stress_kinds= ["stone", "copper", "gold"]
	for event_index in range(600):
		for drop_index in main.mine_world.drops.size():
			if bool(main.mine_world.drops[drop_index].get("crusher_bundle", false)):
				main.mine_world.drops[drop_index].age = maxf(0.151, float(main.mine_world.drops[drop_index].age))
		var sector= event_index % 8
		var offset= Vector2.from_angle(float(sector) * TAU / 8.0) * 96.0
		var spawn_cell: Vector2i = main.mine_world._world_to_cell(origin + offset)
		main.mine_world._spawn_drop(spawn_cell, String(stress_kinds[event_index % stress_kinds.size()]), 1, origin)
		generated_total += 1
		if not _crusher_impact_qa_require(
			main.mine_world._visible_crusher_bundle_count() <= 12
			and main.mine_world.get_child_count() == child_count_before,
			"super_drill_bundle_cap"
		):
			return
	for drop_index in main.mine_world.drops.size():
		if bool(main.mine_world.drops[drop_index].get("crusher_bundle", false)):
			main.mine_world.drops[drop_index].age = 1.0
			main.mine_world.drops[drop_index].crusher_flight_age = 1.0
	main.mine_world._spawn_drop(center + Vector2i(2, 0), "stone", 1, origin)
	generated_total += 1
	var relaunched_without_lifetime_reset= false
	for drop in main.mine_world.drops:
		relaunched_without_lifetime_reset = (
			relaunched_without_lifetime_reset
			or (
				bool(drop.get("crusher_bundle", false))
				and float(drop.get("age", 0.0)) >= 1.0
				and is_zero_approx(float(drop.get("crusher_flight_age", -1.0)))
			)
		)
	if not _crusher_impact_qa_require(
		relaunched_without_lifetime_reset,
		"capped_merge_relaunches_before_magnet"
	):
		return
	visual_total = 0
	for drop in main.mine_world.drops:
		visual_total += int(drop.get("amount", 0))
	persistent_total = 0
	for stored in RunState.mine_loose_loot("mossMine", 1):
		persistent_total += int(Dictionary(stored).get("amount", 0))
	if not _crusher_impact_qa_require(
		visual_total == generated_total and persistent_total == generated_total,
		"super_drill_exact_accounting"
	):
		return



	main.mine_world._restore_persistent_loose_loot()
	var restored_total= 0
	for restored_drop in main.mine_world.drops:
		restored_total += int(restored_drop.get("amount", 0))
	if not _crusher_impact_qa_require(restored_total == generated_total, "reload_preserves_total"):
		return
	main.mine_world.player.global_position = origin
	var collect_position= origin + Vector2(0, -24)
	for drop_index in main.mine_world.drops.size():
		main.mine_world.drops[drop_index].position = collect_position
		main.mine_world.drops[drop_index].velocity = Vector2.ZERO
		main.mine_world.drops[drop_index].age = 1.0
		RunState.update_mine_loose_loot_position(
			"mossMine", 1, String(main.mine_world.drops[drop_index].persistent_id), collect_position
		)
	main.mine_world._update_drops(1.0 / 60.0)
	var cargo_total= 0
	for resource_value in stress_kinds:
		cargo_total += int(RunState.cargo.get(String(resource_value), 0))
	if not _crusher_impact_qa_require(
		main.mine_world.drops.is_empty()
		and RunState.mine_loose_loot("mossMine", 1).is_empty()
		and cargo_total == generated_total,
		"magnet_collection_exact"
	):
		return

	main.mine_world.impacts.clear()
	main.mine_world.impacts.append({
		"position": main.mine_world._cell_center(center),
		"age": 0.0,
		"life": 0.3,
		"broken": true,
		"style": "crusher",
		"crusher_force": true,
	})
	main.mine_world._update_impacts(0.31)
	if not _crusher_impact_qa_require(
		main.mine_world.impacts.is_empty() and main.mine_world.drops.is_empty(),
		"short_force_cleanup"
	):
		return


	RunState.reset_run(false)
	RunState.pickaxe_level = 5
	RunState.ember_mastery = 5
	RunState.set_starforge_variant("crusher")
	main.depth_world.load_depth("mossMine")
	main.depth_world.drops.clear()
	var depth_center= Vector2i(24, 24)
	for y_offset in range(-2, 3):
		for x_offset in range(-2, 3):
			var depth_cell= depth_center + Vector2i(x_offset, y_offset)
			var depth_index: int = main.depth_world._cell_index(depth_cell)
			main.depth_world.dug_indices.erase(depth_index)
			main.depth_world.terrain_hp[depth_index] = 1
	main.depth_world._apply_depth_crusher_wave(depth_center, Dictionary(main.depth_world._current_tool()))
	var depth_visual_total= 0
	var depth_visible_bundles= 0
	var depth_kinds_valid= true
	for depth_drop_value in main.depth_world.drops:
		var depth_drop: Dictionary = Dictionary(depth_drop_value)
		depth_visual_total += int(depth_drop.get("amount", 0))
		depth_kinds_valid = depth_kinds_valid and String(depth_drop.get("kind", "")) == "deepstone"
		if not bool(depth_drop.get("visual_suppressed", false)):
			depth_visible_bundles += 1
	var depth_persistent_total= 0
	for depth_stored_value in RunState.mine_loose_loot("mossMine", 2):
		depth_persistent_total += int(Dictionary(depth_stored_value).get("amount", 0))
	if not _crusher_impact_qa_require(
		depth_visual_total == 24
		and depth_persistent_total == 24
		and depth_kinds_valid
		and depth_visible_bundles >= 4 and depth_visible_bundles <= 12,
		"depth_two_bundle_parity"
	):
		return
	print("EVER_DEEPER_CRUSHER_IMPACT_OK footprint=5x5 real_loot=true sectors=8 bundles_max=12 merge_window=0.15 arc=true drill_stress=600 accounting=exact depth2=true pickup=48/80/112/144 singularity=48 cleanup=0.30")
	main.get_tree().quit(0)


func _crusher_impact_qa_require(condition: bool, step: String) -> bool:
	if condition:
		return true
	push_error("EVER_DEEPER_CRUSHER_IMPACT_FAIL step=%s" % step)
	main.get_tree().quit(7)
	return false

