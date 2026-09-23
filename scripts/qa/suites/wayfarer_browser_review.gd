extends "res://scripts/qa/suites/skills_browser_review.gd"
## Explicit fixtures for the retired stores and relocated Copper Ridge.
func _command(data: Dictionary) -> void:
	if String(data.kind) not in ["quarry", "quarry_stage", "retired_depth_shop"]:
		super._command(data)
		return
	command_id = int(data.id)
	fixture = String(data.kind)
	main._cancel_mine_hold()
	main._on_joystick_movement(Vector2.ZERO)
	Input.action_release("mine")
	if fixture == "quarry":
		main._dev_jump_surface()
		_gear("worn")
		var world: Node2D = main.surface_world
		world.restore_position(world.MOSS_QUARRY_FOCUS)
		world.player.set_facing(Vector2.UP)
	elif fixture == "quarry_stage":
		main.surface_world.ore_mountain_hp = int(data.hp)
		main.surface_world._update_ore_mountain(0.0)
	else:
		main._dev_jump_mine(String(data.mine), 2)
		_gear("worn")
		main.depth_world.restore_position(main.depth_world.wayfarer_position)
	main._refresh_hud()

func _frame() -> void:
	super._frame()
	if sample_clock != 0.0: return
	var world: Node2D = main.surface_world
	var retired: Vector2 = world.MOSS_WAYFARER_POSITION
	var surface_context: String = world._nearest_surface_station_context(retired + Vector2(0, 110))
	var state: Dictionary = {
		"surface_context": main.surface_context,
		"depth_context": main.depth_context,
		"quarry_position": [world.MOSS_ORE_MOUNTAIN_POSITION.x, world.MOSS_ORE_MOUNTAIN_POSITION.y],
		"quarry_solid": world._surface_collides(world.MOSS_ORE_MOUNTAIN_COLLISION_CENTER),
		"quarry_approach_clear": not world._surface_collides(world.MOSS_QUARRY_FOCUS),
		"retired_surface_context": surface_context,
		"wayfarer_sprite_count": _count_store_sprites(world),
		"purchased_speed_level": RunState.movement_speed_level,
		"quarry_hp": world.ore_mountain_hp,
	}
	JavaScriptBridge.eval("Object.assign(window.DEV14_STATE," + JSON.stringify(state) + ")", true)

func _count_store_sprites(node: Node) -> int:
	var count: int = 0
	if node is Sprite2D and node.texture != null and "wayfarer" in node.texture.resource_path:
		count += 1
	for child in node.get_children(): count += _count_store_sprites(child)
	return count
