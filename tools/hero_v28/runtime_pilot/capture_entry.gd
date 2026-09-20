extends SceneTree
## Native capture command-line entry; exported trial uses the same Node directly.
func _initialize() -> void:
	root.add_child(load(get_script().resource_path.get_base_dir().path_join("capture_motion.gd")).new())
