extends RefCounted
## QA only. No recorder, reference implementation or timer enters production.
const OriginalMotion = preload("res://scripts/qa/suites/fixes_v2_motion_original.gd")
const CandidateMotion = preload("res://scripts/player/native_worn/runtime_motion.gd")
const IMMUTABLE_STATE = ["bank", "metadata", "original_mining_poses", "aligned_mining_poses"]

class MotionSink extends Node:
    var source: Node
    var data: Dictionary
    var root_native: Vector3 = Vector3.ZERO
    var shown: Dictionary = {}
    const GROUND_Y: float = 2.8125
    func _matrix(rows: Array) -> Transform3D: return source._matrix(rows)
    func _vector(value: Array) -> Vector3: return source._vector(value)
    func _apply(_pose: Dictionary) -> void: pass

var recording: bool = false
var recorded_owner: Node
var recorded_reference: Dictionary = {}
var recorded_candidate: Dictionary = {}
var recorded: Dictionary = {}
var prior_packet: Dictionary = {}
var recorded_seed: Dictionary = {}
var recorded_final: Dictionary = {}
var recorded_packets: Array = []

func _new_motion(script: Script, owner: Node) -> Dictionary:
    var sink := MotionSink.new()
    sink.source = owner.rig
    sink.data = owner.rig.data
    var motion: RefCounted = script.new()
    if not motion.configure(sink,"res://assets/native-worn/tasks.json","res://assets/native-worn/motion.json"):
        sink.free()
        return {}
    motion.cap_local = owner.motion.cap_local
    motion.reference_cap = owner.motion.reference_cap
    return {"motion":motion,"sink":sink}

func _release_motion(row: Dictionary) -> void:
    if row.has("sink") and is_instance_valid(row.sink): row.sink.free()
    row.clear()

func _state(motion: RefCounted) -> Dictionary:
    var result: Dictionary = {}
    for property in motion.get_property_list():
        if (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0: continue
        var key: String = property.name
        if key == "rig": continue
        var value: Variant = motion.get(key)
        result[key] = value.duplicate(true) if value is Dictionary or value is Array else value
    return result

func _restore(motion: RefCounted, state: Dictionary) -> void:
    for key in state:
        var value: Variant = state[key]
        motion.set(key,value.duplicate(true) if value is Dictionary or value is Array else value)

func _differences(reference: RefCounted, candidate: RefCounted, include_immutable: bool = false) -> Array[String]:
    var result: Array[String] = []
    for property in reference.get_property_list():
        if (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0: continue
        var key: String = property.name
        if key == "rig" or (not include_immutable and key in IMMUTABLE_STATE): continue
        if reference.get(key) != candidate.get(key): result.append(key)
    return result

func _immutable_equal(motion: RefCounted, seed: Dictionary) -> bool:
    for key in IMMUTABLE_STATE:
        if motion.get(key) != seed[key]: return false
    return true

func _mutate_pose(pose: Dictionary) -> void:
    pose.bones.body.origin += Vector3(9,8,7)
    pose.bones["qa_added"] = Transform3D.IDENTITY
    pose.contacts["R"] = not bool(pose.contacts.get("R",false))
    pose.contacts["qa_added"] = {"nested":[1,2,3]}
    pose.release = -123.0

func _sample_parity(owner: Node) -> Dictionary:
    var reference := _new_motion(OriginalMotion,owner)
    var candidate := _new_motion(CandidateMotion,owner)
    if reference.is_empty() or candidate.is_empty():
        _release_motion(reference)
        _release_motion(candidate)
        return {"exact":false,"error":"Motion configuration failed"}
    var original_seed := _state(reference.motion)
    var candidate_seed := _state(candidate.motion)
    var failures: Array = []
    var cases: int = 0
    var aimed_cases: int = 0
    var roots: Array[Vector3] = [Vector3.ZERO,Vector3(2.3,-4.8,.7),Vector3(-1.1,8.9,-.3)]
    var angles: Array[float] = [0.0,.73,-2.28]
    # Includes both deep-copy endpoint branches and the fractional mix branch.
    for family in ["idle","walk","mine"]:
        var count: int = candidate.motion.bank[family].size()
        for row in count:
            for fraction in [0.0,0.00000001,.37,.99999995]:
                var at: float = (float(row)+fraction)/float(count)
                var angle: float = angles[cases%angles.size()]
                var translation := Vector3(.1,-.2,.3)
                var old_pose: Dictionary = reference.motion.rotate_pose(reference.motion.sample(family,at),angle,translation)
                var new_pose: Dictionary = candidate.motion._rotate_fresh_sample(family,at,angle,translation)
                var equal: bool = old_pose == new_pose
                reference.motion.root_position = roots[cases%roots.size()]
                candidate.motion.root_position = reference.motion.root_position
                var old_world: Dictionary = reference.motion._world(old_pose)
                var new_world: Dictionary = candidate.motion._world_owned(new_pose)
                equal = equal and old_world == new_world
                if not equal: failures.append({"kind":"sample","family":family,"row":row,"fraction":fraction})
                cases += 1
    var target: Vector2 = reference.motion.project(reference.motion.reference_cap)+Vector2(13,-7)
    var old_ok: bool = reference.motion.plan_contact(target)
    var new_ok: bool = candidate.motion.plan_contact(target)
    if not old_ok or not new_ok: failures.append({"kind":"nominal_contact"})
    for at in [0.0,.12,.30,.301,.419,.42,.421,.445,.62,.99,1.0]:
        var old_pose: Dictionary = reference.motion.aimed(at)
        var new_pose: Dictionary = candidate.motion.aimed(at)
        if old_pose != new_pose: failures.append({"kind":"aimed","phase":at})
        var old_world: Dictionary = reference.motion._world(old_pose)
        var new_world: Dictionary = candidate.motion._world_owned(new_pose)
        if old_world != new_world: failures.append({"kind":"aimed_world","phase":at})
        aimed_cases += 1
    var differences := _differences(reference.motion,candidate.motion,true)
    var immutable: bool = _immutable_equal(reference.motion,original_seed) and _immutable_equal(candidate.motion,candidate_seed)
    _release_motion(reference)
    _release_motion(candidate)
    return {"exact":failures.is_empty() and differences.is_empty() and immutable,"sample_cases":cases,
        "aimed_cases":aimed_cases,"immutable_bank_and_metadata":immutable,"state_differences":differences,"failures":failures}

func _alias_mutations(owner: Node) -> Dictionary:
    var candidate := _new_motion(CandidateMotion,owner)
    if candidate.is_empty(): return {"exact":false,"error":"Motion configuration failed"}
    var motion: RefCounted = candidate.motion
    var seed := _state(motion)
    var failures: Array = []
    var cases: int = 0
    # Mutating one result must not reach a second result, a bank pose, or a
    # retained display/transition snapshot, including nested contacts.
    motion.shown = motion._rotate_fresh_sample("idle",.13,.2)
    motion.older = motion.shown.duplicate(true)
    motion.transition_source = motion.shown.duplicate(true)
    var persistent := {"shown":motion.shown.duplicate(true),"older":motion.older.duplicate(true),
        "transition_source":motion.transition_source.duplicate(true)}
    for family in ["idle","walk","mine"]:
        var count: int = motion.bank[family].size()
        for fraction in [0.0,0.00000001,.37,.99999995]:
            var at: float = (3.0+fraction)/float(count)
            var first: Dictionary = motion._rotate_fresh_sample(family,at,.91)
            var second: Dictionary = motion._rotate_fresh_sample(family,at,.91)
            var second_before: Dictionary = second.duplicate(true)
            _mutate_pose(first)
            if second != second_before: failures.append({"kind":"fresh_result_alias","family":family,"fraction":fraction})
            var owned_world: Dictionary = motion._world_owned(second)
            _mutate_pose(owned_world)
            cases += 1
    motion.plan_contact(motion.project(motion.reference_cap)+Vector2(13,-7))
    for at in [.12,.42,.62]:
        var first: Dictionary = motion.aimed(at)
        var second: Dictionary = motion.aimed(at)
        var second_before: Dictionary = second.duplicate(true)
        _mutate_pose(first)
        if second != second_before: failures.append({"kind":"aimed_result_alias","phase":at})
        _mutate_pose(motion._world_owned(second))
        cases += 1
    for key in persistent:
        if motion.get(key) != persistent[key]: failures.append({"kind":"retained_pose_mutated","property":key})
    # The public copy APIs still accept caller-owned dictionaries with arbitrary
    # nested data. Their old independence contract must remain intact.
    var caller: Dictionary = {"bones":{"body":Transform3D.IDENTITY},"contacts":{"R":true,"nested":{"array":[1,2]}},
        "release":.2,"extra":{"nested":[1,2]}}
    var caller_before := caller.duplicate(true)
    var rotated: Dictionary = motion.rotate_pose(caller,.33,Vector3(1,2,3))
    var rotated_before := rotated.duplicate(true)
    var world: Dictionary = motion._world(rotated)
    _mutate_pose(world)
    world.contacts.nested.array[0] = 99
    world.extra.nested[0] = 99
    if caller != caller_before or rotated != rotated_before: failures.append({"kind":"public_copy_contract"})
    var immutable: bool = _immutable_equal(motion,seed)
    _release_motion(candidate)
    return {"exact":failures.is_empty() and immutable,"fresh_mutation_cases":cases,"public_copy_contract":caller == caller_before and rotated == rotated_before,
        "immutable_bank_and_metadata":immutable,"failures":failures}

func framing(owner: Node) -> Dictionary:
    var sprite: Sprite2D = owner.rig.sprite
    var rect: Rect2 = sprite.get_rect()
    var screen: Transform2D = sprite.get_global_transform_with_canvas()
    var bounds := Rect2(screen*rect.position,Vector2.ZERO)
    for point in [rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)]:
        bounds = bounds.expand(screen*point)
    var viewport: Rect2 = sprite.get_viewport_rect()
    return {"fully_inside":viewport.grow(-8).encloses(bounds),"hero_rect":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y],
        "viewport":[viewport.size.x,viewport.size.y]}

func run(main: Node) -> Dictionary:
    var player: Node = main._active_player_node()
    var owner: Node = player.visual._native_worn
    if not is_instance_valid(owner) or not is_instance_valid(owner.rig): return {"exact":false,"error":"Native hero absent"}
    var samples := _sample_parity(owner)
    var aliases := _alias_mutations(owner)
    return {"exact":bool(samples.exact) and bool(aliases.exact),"samples":samples,"aliases":aliases,
        "framing":framing(owner),"gear":player.visual.active_gear,
        "scope":"Unmodified public motion vs production owned-pose path; exact dictionaries and mutation isolation"}

func record_start(main: Node) -> Dictionary:
    record_finish()
    recorded_packets.clear()
    recorded_seed.clear()
    recorded_final.clear()
    recorded_owner = main._active_player_node().visual._native_worn
    recorded_reference = _new_motion(OriginalMotion,recorded_owner)
    recorded_candidate = _new_motion(CandidateMotion,recorded_owner)
    if recorded_reference.is_empty() or recorded_candidate.is_empty():
        _release_motion(recorded_reference)
        _release_motion(recorded_candidate)
        return {"exact":false,"error":"Motion replay configuration failed"}
    recorded_seed = _state(recorded_owner.motion)
    _restore(recorded_reference.motion,recorded_seed)
    _restore(recorded_candidate.motion,recorded_seed)
    recorded = {"exact":true,"frames":0,"idle_frames":0,"walking_frames":0,"mining_frames":0,"contour_frames":0,"target_ids":[],
        "transition_frames":0,"swings":0,"impacts":0,"retargets":0,"cancels":0,"clipped_frames":0,"failures":[]}
    prior_packet.clear()
    recording = true
    return recorded.duplicate(true)

func record_frame(main: Node, delta: float) -> void:
    if not recording or delta <= 0.0: return
    var player: Node = main._active_player_node()
    if player.visual._native_worn != recorded_owner:
        recorded.exact = false
        recorded.failures.append("Native owner changed during replay")
        recording = false
        return
    var packet: Dictionary = player.animation_packet()
    packet.contact_surfaces = recorded_owner._surfaces(packet.target_position,String(packet.target_id)) if bool(packet.target_valid) else []
    packet.impact_surfaces = []
    if Vector2(packet.impact_target_position).is_equal_approx(recorded_owner.last_target):
        for point in recorded_owner.last_surfaces:
            packet.impact_surfaces.append(Vector2(point)+recorded_owner.last_surface_origin-player.global_position)
    recorded_packets.append({"delta":delta,"packet":packet.duplicate(true)})
    var old_ok: bool = recorded_reference.motion.advance(delta,packet.duplicate(true))
    var new_ok: bool = recorded_candidate.motion.advance(delta,packet.duplicate(true))
    var differences := _differences(recorded_reference.motion,recorded_candidate.motion)
    var sinks_exact: bool = recorded_reference.sink.root_native == recorded_candidate.sink.root_native and recorded_reference.sink.shown == recorded_candidate.sink.shown
    var equal: bool = old_ok and new_ok and differences.is_empty() and sinks_exact
    recorded.exact = recorded.exact and equal
    recorded.frames += 1
    if not equal: recorded.failures.append({"frame":recorded.frames,"old_ok":old_ok,"new_ok":new_ok,"properties":differences,"sinks_exact":sinks_exact})
    var target_id := String(packet.get("target_id",""))
    if packet.mining and packet.target_valid and not target_id.is_empty() and not recorded.target_ids.has(target_id):
        recorded.target_ids.append(target_id)
    if packet.mining: recorded.mining_frames += 1
    elif packet.moving: recorded.walking_frames += 1
    else: recorded.idle_frames += 1
    if not packet.contact_surfaces.is_empty(): recorded.contour_frames += 1
    if recorded_candidate.motion.age < recorded_candidate.motion.duration: recorded.transition_frames += 1
    if not framing(recorded_owner).fully_inside: recorded.clipped_frames += 1
    if not prior_packet.is_empty():
        if int(packet.swing_serial) != int(prior_packet.swing_serial):
            recorded.swings += 1
            if packet.target_id != prior_packet.target_id or packet.target_position != prior_packet.target_position: recorded.retargets += 1
        if int(packet.impact_serial) != int(prior_packet.impact_serial): recorded.impacts += 1
        if prior_packet.mining and not packet.mining: recorded.cancels += 1
    prior_packet = packet

func record_finish() -> Dictionary:
    recording = false
    if not recorded_reference.is_empty() and not recorded_candidate.is_empty():
        var immutable: bool = _immutable_equal(recorded_reference.motion,recorded_seed) and _immutable_equal(recorded_candidate.motion,recorded_seed)
        recorded.immutable_bank_and_metadata = immutable
        recorded.exact = recorded.exact and immutable
        recorded_final = _state(recorded_reference.motion)
    var result := recorded.duplicate(true)
    _release_motion(recorded_reference)
    _release_motion(recorded_candidate)
    prior_packet.clear()
    return result

func benchmark_recorded(repeats: int = 1) -> Dictionary:
    if recording or recorded_packets.is_empty() or recorded_final.is_empty():
        return {"exact":false,"error":"Finish a real-input recording first"}
    if not is_instance_valid(recorded_owner) or not is_instance_valid(recorded_owner.rig):
        return {"exact":false,"error":"Recorded rig was replaced before helper benchmark"}
    var reference := _new_motion(OriginalMotion,recorded_owner)
    var candidate := _new_motion(CandidateMotion,recorded_owner)
    if reference.is_empty() or candidate.is_empty():
        _release_motion(reference)
        _release_motion(candidate)
        return {"exact":false,"error":"Benchmark configuration failed"}
    var packets_before: Array = recorded_packets.duplicate(true)
    var samples: Array = []
    var exact: bool = true
    var reference_total: int = 0
    var candidate_total: int = 0
    for repeat_index in maxi(1,repeats):
        for is_candidate in [false,true,true,false]:
            var motion: RefCounted = candidate.motion if is_candidate else reference.motion
            _restore(motion,recorded_seed)
            var ok: bool = true
            var started: int = Time.get_ticks_usec()
            for frame in recorded_packets:
                if not motion.advance(frame.delta,frame.packet): ok = false
            var elapsed: int = Time.get_ticks_usec()-started
            var equal: bool = ok and _state(motion) == recorded_final
            exact = exact and equal
            if is_candidate: candidate_total += elapsed
            else: reference_total += elapsed
            samples.append({"repeat":repeat_index,"candidate":is_candidate,"usec":elapsed,"exact":equal,"frames":recorded_packets.size()})
    var packets_unchanged: bool = recorded_packets == packets_before
    _release_motion(reference)
    _release_motion(candidate)
    return {"exact":exact and packets_unchanged,"samples":samples,"reference_usec":reference_total,"candidate_usec":candidate_total,
        "packets_unchanged":packets_unchanged,"frames_per_sample":recorded_packets.size(),
        "scope":"ABBA full native advance CPU, same recorded packets and initial state, sink rig; not game FPS or GPU time"}
