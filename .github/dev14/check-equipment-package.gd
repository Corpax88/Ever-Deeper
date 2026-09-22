extends SceneTree
func _init() -> void:
	var folder: String = "res://assets/native-pickaxes/"
	for file in ["body-only.res","runtime-manifest.json","iron.scn","runed.scn","moonglass.scn","ember.scn","crusher.scn","comet.scn","crown.scn"]:
		if not FileAccess.file_exists(folder+file):
			push_error("Missing packaged tool resource: "+file);quit(2);return
	for file in ["source-manifest.json","worn.scn","worn.glb.raw","iron.glb.raw","runed.glb.raw","moonglass.glb.raw","ember.glb.raw","crusher.glb.raw","comet.glb.raw","crown.glb.raw"]:
		if FileAccess.file_exists(folder+file):
			push_error("Build-only equipment was exported: "+file);quit(2);return
	print("PICKAXE_PACKAGE_COMPLETE")
	quit(0)
