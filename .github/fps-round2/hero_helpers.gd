# Append to an existing FPS QA suite; all helpers receive the native owner.
# Contact benchmarks intentionally block only the separate diagnostic phase.
# Never include benchmark time in live FPS windows.

func _round2_hero_modes(owner: Node, bind_cache: bool, contact_hoist: bool, profile: bool = false) -> Dictionary:
	owner.rig.qa_round2_bind_cache = bind_cache
	owner.rig.qa_round2_hero_profile = profile
	owner.motion.qa_round2_contact_hoist = contact_hoist
	owner.motion.qa_round2_contact_profile = profile
	owner.rig.qa_round2_bind_calls = 0
	owner.rig.qa_round2_bind_usec = 0
	owner.motion.qa_round2_contact_calls = 0
	owner.motion.qa_round2_contact_usec = 0
	round2_bind_check = owner.rig.qa_round2_compare_bind_matrices(owner.rig.shown)
	return _round2_hero_stats(owner)

func _round2_hero_stats(owner: Node) -> Dictionary:
	return {"bind_cache":owner.rig.qa_round2_bind_cache,"contact_hoist":owner.motion.qa_round2_contact_hoist,
		"bind_calls":owner.rig.qa_round2_bind_calls,"bind_usec":owner.rig.qa_round2_bind_usec,
		"contact_calls":owner.motion.qa_round2_contact_calls,"contact_usec":owner.motion.qa_round2_contact_usec,
		"bounded_transition_frames":owner.motion.bounded_transition_frames,
		"bind_parity":round2_bind_check}

func _round2_contact_result(motion: RefCounted, ok: bool) -> Dictionary:
	return {"ok":ok,"tool":motion.contact_tool,"yaw":motion.contact_yaw,"screen":motion.contact_screen}

func _round2_hero_contact_benchmark(owner: Node, repeats: int = 1) -> Dictionary:
	var motion: RefCounted = owner.motion
	var saved: Dictionary = {"contact_cache":motion.contact_cache,"contact_tool":motion.contact_tool,
		"contact_yaw":motion.contact_yaw,"contact_screen":motion.contact_screen,"errors":motion.errors.duplicate()}
	var center: Vector2 = motion.project(motion.reference_cap)
	var rows: Array = []
	var all_exact: bool = true
	# Synthetic contours exercise the exact search, not gameplay reach rules.
	for case_id in 3:
		var target: Vector2 = center + [Vector2.ZERO,Vector2(34,-18),Vector2(900,900)][case_id]
		var surfaces: Array = []
		for y in 3:
			for x in 4: surfaces.append(target + Vector2(float(x-2)*4.0,float(y-1)*4.0))
		var baseline: Dictionary = {}
		var samples: Array = []
		for iteration in clampi(repeats,1,3):
			# ABBA avoids assigning all later runs to one mode; all caches are cold.
			for candidate in [false,true,true,false]:
				motion.contact_cache = {}
				motion.contact_tool = Transform3D.IDENTITY
				motion.contact_yaw = 0.0
				motion.contact_screen = Vector2.ZERO
				var started: int = Time.get_ticks_usec()
				var ok: bool
				if candidate: ok = motion._qa_round2_contact_hoisted(target,surfaces,false)
				else: ok = motion._qa_round2_contact_original(target,surfaces,false)
				var elapsed: int = Time.get_ticks_usec()-started
				var result: Dictionary = _round2_contact_result(motion,ok)
				if baseline.is_empty(): baseline = result
				var exact: bool = result == baseline
				all_exact = all_exact and exact
				samples.append({"candidate":candidate,"iteration":iteration,"usec":elapsed,"exact":exact,"success":ok})
		rows.append({"case":case_id,"surface_count":surfaces.size(),"candidate_count":surfaces.size()*25*9*19,"samples":samples})
	for key in saved: motion.set(key,saved[key])
	return {"exact":all_exact,"cases":rows,"scope":"cold exhaustive contact search; not sustained FPS"}
