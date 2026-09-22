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

var bounded_transition_frames: int = 0

func mix(a: Dictionary, b: Dictionary, weight: float, step: float = -1.0, airborne: bool = false) -> Dictionary:
	var result: Dictionary = super.mix(a,b,weight,step,airborne)
	if step < 0.0 or _rigid(result) or transition_source.is_empty(): return result
	# Very fast earned contacts can produce large measured endpoint velocities.
	# Bound only their extrapolation during a transition; preserve authored poses,
	# transition timing, the rigid tool, hand relationships and gameplay contacts.
	var bounded: Dictionary = super.mix(transition_source,b,weight,step,airborne)
	if not _rigid(bounded): return result # Retain the normal explicit rejection.
	var low: float = 0.0
	var high: float = 1.0
	for attempt in 8:
		var factor: float = (low+high)*0.5
		var source: Dictionary = transition_source.duplicate(true)
		var carried: float = age*pow(1.0-step,2)*factor
		for name in source.bones:
			source.bones[name].origin += Vector3(source_velocity[name])*carried
			var spin: Vector3 = source_angular[name]*carried
			if spin.length() > .000001:
				source.bones[name].basis = Basis(Quaternion(spin.normalized(),spin.length()))*source.bones[name].basis
		var trial: Dictionary = super.mix(source,b,weight,step,airborne)
		if _rigid(trial):
			low = factor
			bounded = trial
		else: high = factor
	bounded_transition_frames += 1
	return bounded

func _rigid(pose: Dictionary) -> bool:
	for transform in pose.bones.values():
		if not Transform3D(transform).is_finite(): return false
	for side in SIDES:
		for family in ["arm","leg"]:
			var chain: Array[Vector3] = _chain(pose.bones,family,side)
			var lengths: Vector2 = Vector2(.36,.35) if family == "arm" else Vector2(.180,.184)
			for segment in 2:
				if absf(chain[segment].distance_to(chain[segment+1])-lengths[segment]) > .00008: return false
	return true

func snapshot() -> Dictionary:
	var result: Dictionary = super.snapshot()
	result.bounded_transition_frames = bounded_transition_frames
	result.max_reach_error_scope = "Includes rejected transition search probes"
	return result
