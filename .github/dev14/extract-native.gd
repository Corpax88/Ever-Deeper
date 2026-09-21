extends SceneTree
const SOURCE = "res://assets/native-flow-trial/"
const FILES = ["candidate.json", "motion.json", "tasks.json", "worn-native-runtime.glb.raw", "albedo.png.raw", "normal.png.raw", "orm.png.raw", "cloth.png.raw", "component-response/response.png.raw", "component-response/report.json", "transfer-albedo/report.json"]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not ProjectSettings.load_resource_pack(args[0]):
		push_error("Expected reviewed Worn PCK and destination")
		quit(2)
		return
	for name in FILES:
		var input := SOURCE + name
		if not FileAccess.file_exists(input):
			push_error("Missing approved native input " + name)
			quit(2)
			return
		var target := args[1].path_join(name)
		DirAccess.make_dir_recursive_absolute(target.get_base_dir())
		var bytes := FileAccess.get_file_as_bytes(input)
		var output := FileAccess.open(target, FileAccess.WRITE)
		if output == null:
			quit(2)
			return
		output.store_buffer(bytes)
		output.close()
	print("DEV14_NATIVE_INPUTS_REUSED files=", FILES.size())
	quit(0)
