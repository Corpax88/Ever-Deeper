extends "res://scripts/main.gd"
## Fixture-only installation through the original main owner's one hook.
func _install_mining_companion() -> void:
	var selected := "trace_mole.gd" if "--trace-companion" in OS.get_cmdline_user_args() else "pilot_mole.gd"
	var script: Script = load("res://tools/companion_spacing_study/" + selected)
	for world in [surface_world, mine_world, depth_world, hub_world, deepheart_world, endless_world]:
		var companion: Node2D = script.new()
		companion.name = "MoleCompanion"
		world.add_child(companion)
	var interface: CanvasLayer = load("res://scripts/companion/companion_interface.gd").new()
	interface.name = "CompanionInterface"
	add_child(interface)
