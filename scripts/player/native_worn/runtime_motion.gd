extends "res://scripts/player/native_worn/task_motion.gd"
## Gameplay keeps its existing reach and hit rules. The renderer never rejects a hit.
var nominal_contacts: int = 0
var unreachable_contacts: int = 0

func plan_contact(target: Vector2, surfaces: Array = [], _record_failure: bool = true) -> bool:
	if not surfaces.is_empty():
		if contact_cache.size() >= 128: contact_cache.clear()
		if super.plan_contact(target, surfaces, false): return true
		unreachable_contacts += 1
	else:
		nominal_contacts += 1
	# Legacy worlds and terrain do not supply an ore contour. Preserve the
	# authored swing and aim it along the actual gameplay bearing in those cases.
	var direction: Vector3 = ground(target)
	contact_yaw = atan2(direction.y, direction.x) - atan2(reference_cap.y, reference_cap.x)
	contact_tool = Transform3D(Basis(Vector3(0, 0, 1), contact_yaw), Vector3.ZERO) * bank.mine[21].bones.tool
	contact_screen = project(contact_tool * cap_local)
	return true
