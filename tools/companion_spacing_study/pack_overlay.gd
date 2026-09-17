extends SceneTree
## Build a tiny tools-only overlay; never export or modify the game package.
const FILES := ["follow_separation.gd", "pilot_mole.gd", "pilot_main.gd", "trace_mole.gd"]

func _initialize() -> void:
	var source := ""
	var output := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--source="): source = arg.trim_prefix("--source=")
		elif arg.begins_with("--output="): output = arg.trim_prefix("--output=")
	if not source.is_absolute_path() or not output.is_absolute_path():
		quit(2)
		return
	var pack := PCKPacker.new()
	if pack.pck_start(output) != OK:
		quit(3)
		return
	for file in FILES:
		if pack.add_file("res://tools/companion_spacing_study/" + file, source.path_join(file)) != OK:
			quit(4)
			return
	if pack.flush() != OK:
		quit(5)
		return
	print("COMPANION_OVERLAY_PACKED ", FileAccess.get_sha256(output))
	quit(0)
