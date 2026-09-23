extends SceneTree
var copied: int = 0
func _init() -> void:
 var args = OS.get_cmdline_user_args()
 if args.size() != 2 or not ProjectSettings.load_resource_pack(args[0]):
  quit(2)
  return
 for folder in ["assets/native-worn", "assets/native-pickaxes"]:
  copy_dir("res://" + folder, args[1].path_join(folder))
 print("NATIVE_REUSE_COMPLETE ", copied)
 quit(0)
func copy_dir(source: String, destination: String) -> void:
 DirAccess.make_dir_recursive_absolute(destination)
 for file in DirAccess.get_files_at(source):
  var out = FileAccess.open(destination.path_join(file), FileAccess.WRITE)
  out.store_buffer(FileAccess.get_file_as_bytes(source.path_join(file)))
  out.close()
  copied += 1
 for folder in DirAccess.get_directories_at(source):
  copy_dir(source.path_join(folder), destination.path_join(folder))
