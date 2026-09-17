extends SceneTree
## Runs the unchanged shipped mole-autonomy suite with fixture-only companions.
const PACK_SHA := "9dfcf913c867e36e6a16f4f5123fd5cce7654cfb435a753f9eb7bca12f574bd9"
var failure := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var overlay := ""
	var game_pack := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--overlay="): overlay = arg.trim_prefix("--overlay=")
		elif arg.begins_with("--game-pack="): game_pack = arg.trim_prefix("--game-pack=")
	if FileAccess.get_sha256(game_pack) != PACK_SHA or not overlay.is_absolute_path():
		push_error("Exact DEV12 package and absolute overlay required")
		quit(2)
		return
	if not ProjectSettings.load_resource_pack(overlay, false):
		quit(3)
		return
	var pilot_script: Script = load("res://tools/companion_spacing_study/pilot_main.gd")
	if pilot_script == null or not pilot_script.can_instantiate():
		quit(4)
		return
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.set_script(pilot_script)
	root.add_child(main)
	current_scene = main
	# Installation is deferred by the shipped _ready owner.
	await process_frame
	for world in [main.surface_world, main.mine_world, main.depth_world, main.hub_world, main.deepheart_world, main.endless_world]:
		var mole: Node = world.get_node("MoleCompanion")
		var selected := "trace_mole.gd" if "--trace-companion" in OS.get_cmdline_user_args() else "pilot_mole.gd"
		if mole.get_script().resource_path != "res://tools/companion_spacing_study/" + selected:
			push_error("Fixture companion missing from actual world")
			quit(5)
			return
	print("COMPANION_INTEGRATION_ALL_SIX_REAL_WORLD_OWNERS_REPLACED")
	# --qa-mole-autonomy is processed by the original deferred launcher. It
	# owns the untouched checks, completion marker and exit code.
