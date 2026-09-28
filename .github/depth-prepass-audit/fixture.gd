extends "res://scripts/qa/suites/native_audit_base.gd"

func _command(data: Dictionary) -> void:
	match String(data.kind):
		"fixed_pose":
			command_id = int(data.id)
			_require(main.get_tree().paused, "Fixed-pose capture must be frozen")
			var pose: Dictionary = native_owner.motion.sample(String(data.family), float(data.phase))
			pose = native_owner.motion.rotate_pose(pose, float(data.angle))
			native_owner.rig.root_native = Vector3.ZERO
			native_owner.rig.shown = pose.bones
			native_owner.rig._apply(pose.bones)
			native_owner.equipment.apply_pose()
		"capture":
			command_id = int(data.id)
			_capture_native(String(data.request))
		_: super._command(data)

func _frame() -> void:
	if main.achievement_toast != null: main.achievement_toast.clear()
	super._frame()

func _native_info() -> Dictionary:
	var row: Dictionary = super._native_info()
	row.depth_prepass = ProjectSettings.get_setting_with_override("rendering/driver/depth_prepass/enable")
	return row
