extends "res://scripts/qa/suites/one_point_zero.gd"
## Regressions for committed mining cadence, real movement and live equipment.

func run() -> void:
	if not _new_player_to_deep():
		_finish("premium_core")
		return
	main._enter_endless(true, false)
	var world: Node = main.endless_world
	world.set_process(false)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	var mole: Node = world.get_node_or_null("MoleCompanion")
	if mole != null:
		mole.set_process(false)
		mole.set_physics_process(false)
	RunState.starforge_variant = ""
	RunState.drill_level = 0
	RunState.pickaxe_level = 1
	var origin: Vector2 = world.player.global_position
	var center: Vector2i = world._world_to_cell(origin)
	for y in range(-2, 3):
		for x in range(-2, 3):
			world.floor_cells[world._cell_index(center + Vector2i(x, y))] = 1
	for index in world.resources.size():
		world.resources[index].mined = index >= 2
		if index < 2:
			world.resources[index].position = origin + Vector2(40 + index * 28, 0)
			world.resources[index].hp = 1
	world.player.set_facing(Vector2.RIGHT)
	world.player._actual_moving = false
	world.external_mine_held = true
	var duration: float = world._mining_cycle_duration()
	var step: float = 1.0 / 120.0
	var first_hit: float = -1.0
	var second_hit: float = -1.0
	var first_target: String = String(world.resources[0].id)
	var retained: bool = true
	for tick in range(1, ceili(duration * 3.0 / step)):
		world._update_mining(step)
		if bool(world.resources[0].mined) and first_hit < 0.0:
			first_hit = tick * step
		if first_hit >= 0.0 and tick * step < duration - step:
			retained = retained and String(world.mining_target_id) == first_target
		if bool(world.resources[1].mined):
			second_hit = tick * step
			break
	_check(first_hit > 0.0 and second_hit > first_hit, "Held mining actually breaks two adjacent deposits")
	_check(retained, "Destroyed deposit retains the committed follow-through")
	_check(second_hit - first_hit >= duration - step * 1.1, "Adjacent one-hit deposits respect full equipment cadence")
	journey.append({"step": "adjacent ore cadence", "cycle": duration, "first_hit": first_hit, "second_hit": second_hit})
	world._cancel_mining()
	world.resources[1].mined = false
	world.resources[1].hp = 999
	world.player._actual_moving = true
	for tick in 100:
		world._update_mining(step)
	_check(int(world.resources[1].hp) == 999 and not bool(world.mining_active), "Actual walking cancels mining and cannot inflict a moving hit")
	world.player._actual_moving = false
	world.player.external_movement = Vector2.RIGHT
	for tick in 100:
		world._update_mining(step)
	_check(int(world.resources[1].hp) < 999, "Pushing into an immovable wall still permits mining")
	world.external_mine_held = false
	world._update_mining(step)
	_check(not bool(world.mining_active), "Releasing the mining button cancels the committed target")
	world.player.external_movement = Vector2.ZERO
	_check_terrain_cadence(world)
	var visual: Node = world.player.visual
	RunState.endless_outfit = "expedition"
	world.player._update_visual(false)
	_check(String(visual.active_endless_outfit_style) == "expedition", "Direct loadout changes update the rendered outfit")
	_check(float(visual._cloth.get_shader_parameter("recolor")) == 1.0, "Selected outfit enables actual cloth recoloring")
	_check(Color(visual._cloth.get_shader_parameter("cloth_color")).is_equal_approx(Color("226d8a")), "Selected outfit writes the real shader color")
	RunState.endless_outfit = "miner"
	world.player._update_visual(false)
	_check(String(visual.active_endless_outfit_style) == "miner", "Resetting the outfit restores its original colors")
	_check(float(visual._cloth.get_shader_parameter("recolor")) == 0.0, "Original outfit disables actual shader recoloring")
	var lamp: Node = load("res://scripts/lighting/headlamp_beam.gd").new()
	main.add_child(lamp)
	lamp.configure_preview("wide", 1)
	var before: float = float(lamp.effective_range_multiplier)
	lamp.configure_preview("wide", 5)
	_check(float(lamp.effective_range_multiplier) > before, "Same-style lighting level changes invalidate the preview")
	lamp.preview_settings.clear()
	RunState.endless_light_style = "focused"
	lamp.set_direction(Vector2.UP)
	_check(String(lamp.applied_style_id) == "focused", "Leaving preview immediately restores live light style")
	var relic: String = RunState._relic_id_for_workshop("light_lab")
	RunState.endless_relics[relic]["placed"] = true
	RunState.endless_workshops["light_lab"]["built"] = true
	RunState.endless_workshops["light_lab"]["level"] = 1
	lamp.set_direction(Vector2.UP)
	before = float(lamp.effective_range_multiplier)
	var prior_energy: float = float(lamp.effective_energy_multiplier)
	RunState.endless_workshops["light_lab"]["level"] = 5
	lamp.set_direction(Vector2.UP)
	_check(float(lamp.effective_range_multiplier) > before and float(lamp.effective_energy_multiplier) > prior_energy, "Live same-style level change updates cached range and energy without forced refresh")
	RunState.endless_workshops["light_lab"]["built"] = false
	lamp.set_direction(Vector2.UP)
	_check(is_equal_approx(float(lamp.effective_range_multiplier), 1.0), "Reset or unbuilt workshop invalidates cached light effects")
	lamp.queue_free()
	_finish("premium_core")


func _check_terrain_cadence(world: Node) -> void:
	for resource in world.resources:
		resource.mined = true
	var center: Vector2i = world._world_to_cell(world.player.global_position)
	world.player.global_position = world._cell_center(center)
	world.player._actual_moving = false
	world.player.set_facing(Vector2.RIGHT)
	var a: Vector2i = center + Vector2i.RIGHT
	var b: Vector2i = center + Vector2i.ONE
	for cell in [a, b]:
		world.floor_cells[world._cell_index(cell)] = 0
		world.dig_damage[cell] = 519
	world.external_mine_held = true
	var duration: float = world._mining_cycle_duration()
	var step: float = 1.0 / 120.0
	var first: float = -1.0
	var second: float = -1.0
	for tick in range(1, ceili(duration * 3.0 / step)):
		world._update_mining(step)
		if world._is_floor(a) and first < 0.0:
			first = tick * step
		if world._is_floor(b):
			second = tick * step
			break
	_check(first > 0.0 and second > first, "Held mining actually opens two one-hit terrain cells")
	_check(second - first >= duration - step * 1.1, "Successive terrain breaks retain full swing recovery")
	journey.append({"step": "adjacent terrain cadence", "cycle": duration, "first_hit": first, "second_hit": second})
	world._cancel_mining()
	world.floor_cells[world._cell_index(a)] = 0
	world.dig_damage[a] = 0
	world.player.global_position = world._cell_center(a) - Vector2(32 + world.PLAYER_RADIUS + 0.1, 0)
	world.player.external_movement = Vector2.RIGHT
	world.player._physics_process(0.02)
	world.player._physics_process(0.02)
	_check(not bool(world.player._actual_moving), "Real collision stops translation while joystick remains held")
	world._update_mining(duration * 0.2)
	_check(bool(world.mining_active), "Actual blocked joystick permits the mining wind-up")
	world.player.external_movement = Vector2.UP
	world.player._physics_process(0.0)
	world._update_mining(duration * 0.25)
	_check(int(world.dig_damage.get(a, 0)) == 0, "Turning at a blocked corner never damages the stone behind the tool")
	world.player.set_facing(Vector2.RIGHT)
	world.player.external_movement = Vector2.RIGHT
	world._update_mining(duration * 0.1)
	world.player.external_movement = Vector2.LEFT
	world.player._physics_process(0.02)
	world.player.external_movement = Vector2.ZERO
	world.player._physics_process(0.02)
	_check(not bool(world.mining_active), "Movement followed by an idle physics tick still cancels the old swing")
	world.external_mine_held = false
	world._cancel_mining()
