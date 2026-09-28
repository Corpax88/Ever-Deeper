extends RefCounted
## QA resources only. Compare the actual production candidate against original
## references. Keep benchmarks/recording outside whole-game timing windows.
const OriginalMotion = preload("res://scripts/qa/suites/fixes_motion_original.gd")
const OriginalPet = preload("res://scripts/qa/suites/fixes_pet_original.gd")
const CandidateMotion = preload("res://scripts/player/native_worn/runtime_motion.gd")
const CandidatePet = preload("res://scripts/companion/mole_companion.gd")

class MotionSink extends Node:
    var source: Node
    var data: Dictionary
    var root_native: Vector3 = Vector3.ZERO
    var shown: Dictionary = {}
    const GROUND_Y: float = 2.8125
    func _matrix(rows: Array) -> Transform3D: return source._matrix(rows)
    func _vector(value: Array) -> Vector3: return source._vector(value)
    func _apply(_pose: Dictionary) -> void: pass

class PathWorld extends Node2D:
    var barrier: bool = false
    var queries: int = 0
    func collision_at(point: Vector2) -> bool:
        queries += 1
        return barrier and Rect2(144,48,48,48).has_point(point)

class PathHero extends Node2D:
    var world_size: Vector2 = Vector2(960,960)

var recording: bool = false
var recorded_owner: Node
var recorded_reference: Dictionary = {}
var recorded_candidate: Dictionary = {}
var recorded: Dictionary = {}
var prior_packet: Dictionary = {}

func _new_motion(script: Script, owner: Node) -> Dictionary:
    var sink := MotionSink.new()
    sink.source = owner.rig
    sink.data = owner.rig.data
    var motion: RefCounted = script.new()
    var ok: bool = motion.configure(sink,"res://assets/native-worn/tasks.json","res://assets/native-worn/motion.json")
    if not ok:
        sink.free()
        return {}
    motion.cap_local = owner.motion.cap_local
    motion.reference_cap = owner.motion.reference_cap
    return {"motion":motion,"sink":sink}

func _release_motion(row: Dictionary) -> void:
    if row.has("sink") and is_instance_valid(row.sink): row.sink.free()
    row.clear()

func _motion_result(motion: RefCounted, ok: bool) -> Dictionary:
    return {"ok":ok,"tool":motion.contact_tool,"yaw":motion.contact_yaw,
        "screen":motion.contact_screen,"cache":motion.contact_cache.duplicate(true),
        "errors":motion.errors.duplicate(),"unreachable":motion.unreachable_contacts,
        "nominal":motion.nominal_contacts}

func _contact_search(owner: Node) -> Dictionary:
    var reference := _new_motion(OriginalMotion,owner)
    var candidate := _new_motion(CandidateMotion,owner)
    if reference.is_empty() or candidate.is_empty():
        _release_motion(reference)
        _release_motion(candidate)
        return {"exact":false,"error":"Motion reference configuration failed"}
    var bank_exact: bool = reference.motion.bank == candidate.motion.bank
    var center: Vector2 = candidate.motion.project(candidate.motion.reference_cap)
    var rows: Array = []
    var exact: bool = bank_exact
    var reference_total: int = 0
    var candidate_total: int = 0
    for case_id in 4:
        var shift: Vector2 = [Vector2.ZERO,Vector2(34,-18),Vector2(900,900),Vector2(-24,6)][case_id]
        var target: Vector2 = center + shift
        var surfaces: Array = []
        if case_id != 3:
            for y in 3:
                for x in 4: surfaces.append(target+Vector2(float(x-2)*4.0,float(y-1)*4.0))
        var expected: Dictionary = {}
        var samples: Array = []
        for is_candidate in [false,true,true,false]:
            var motion: RefCounted = candidate.motion if is_candidate else reference.motion
            motion.contact_cache = {}
            motion.contact_tool = Transform3D.IDENTITY
            motion.contact_yaw = 0.0
            motion.contact_screen = Vector2.ZERO
            motion.unreachable_contacts = 0
            motion.nominal_contacts = 0
            motion.errors.clear()
            var started: int = Time.get_ticks_usec()
            var ok: bool = motion.plan_contact(target,surfaces)
            var elapsed: int = Time.get_ticks_usec()-started
            if is_candidate: candidate_total += elapsed
            else: reference_total += elapsed
            var result := _motion_result(motion,ok)
            if expected.is_empty(): expected = result
            var equal: bool = result == expected
            exact = exact and equal
            samples.append({"candidate":is_candidate,"usec":elapsed,"exact":equal,
                "success":ok,"fallback":motion.unreachable_contacts>0,"cache_entries":motion.contact_cache.size()})
            # An immediate repeated query must preserve the selected contact.
            var hot_ok: bool = motion.plan_contact(target,surfaces)
            var hot_exact: bool = hot_ok == ok and motion.contact_tool == result.tool and motion.contact_yaw == result.yaw and motion.contact_screen == result.screen
            exact = exact and hot_exact
            samples[-1]["hot_exact"] = hot_exact
        rows.append({"case":case_id,"surface_count":surfaces.size(),"samples":samples})
    _release_motion(reference)
    _release_motion(candidate)
    return {"exact":exact,"bank_exact":bank_exact,"rows":rows,"reference_usec":reference_total,
        "candidate_usec":candidate_total,"scope":"Actual production plan_contact; cold/hot search and fallback, helper CPU only"}

func _pet_paths(main: Node) -> Dictionary:
    var world: Node2D = main.surface_world
    var mole: Node2D = world.get_node_or_null("MoleCompanion")
    if not is_instance_valid(mole): return {"exact":false,"error":"Missing surface companion"}
    var reference: Node2D = OriginalPet.new()
    reference.world = world
    reference.hero = world.player
    var position: Vector2 = mole.global_position
    var searches: int = mole.path_searches
    var broadphase: int = world.surface_route_broadphase_rejects
    var segments: int = world.surface_route_segment_checks
    var cases: Array = [
        ["moss_branch",Vector2(650,680),Vector2(760,790)],
        ["moss_quarry",Vector2(700,650),Vector2(900,650)],
        ["moon_bend",Vector2(1190,630),Vector2(1400,650)],
        ["ember_route",Vector2(2880,648),Vector2(3140,642)],
        ["ember_resource",Vector2(3100,650),Vector2(3130,700)],
        ["star_route",Vector2(3540,650),Vector2(3810,654)],
        ["unreachable",Vector2(3100,650),Vector2(3100,440)],
    ]
    var rows: Array = []
    var exact: bool = true
    for test in cases:
        var expected: Array[Vector2] = []
        var samples: Array = []
        for is_candidate in [false,true,true,false]:
            var actor: Node2D = mole if is_candidate else reference
            actor.global_position = test[1]
            var started: int = Time.get_ticks_usec()
            var path: Array[Vector2] = actor._path_to(test[2])
            var elapsed: int = Time.get_ticks_usec()-started
            if samples.is_empty(): expected = path.duplicate()
            var equal: bool = path == expected
            exact = exact and equal
            samples.append({"candidate":is_candidate,"usec":elapsed,"exact":equal,"points":path.size()})
        rows.append({"case":test[0],"samples":samples})
    mole.global_position = position
    mole.path_searches = searches
    world.surface_route_broadphase_rejects = broadphase
    world.surface_route_segment_checks = segments
    reference.free()
    return {"exact":exact,"rows":rows,"scope":"Actual surface collision, exact original/production path arrays"}

func _pet_replan() -> Dictionary:
    var world := PathWorld.new()
    var hero := PathHero.new()
    var reference: Node2D = OriginalPet.new()
    var candidate: Node2D = CandidatePet.new()
    for actor in [reference,candidate]:
        actor.world = world
        actor.hero = hero
        actor.global_position = Vector2(72,72)
    var rows: Array = []
    var paths: Array = []
    var exact: bool = true
    for blocked in [false,true,false]:
        world.barrier = blocked
        world.queries = 0
        var old_path: Array[Vector2] = reference._path_to(Vector2(312,72))
        var old_queries: int = world.queries
        world.queries = 0
        var new_path: Array[Vector2] = candidate._path_to(Vector2(312,72))
        var equal: bool = old_path == new_path
        var fresh: bool = candidate._blocked(Vector2(168,72)) == blocked
        exact = exact and equal and fresh
        paths.append(new_path.duplicate())
        rows.append({"blocked":blocked,"exact":equal,"ordinary_collision_fresh":fresh,
            "original_queries":old_queries,"candidate_queries":world.queries-1,"points":new_path.size()})
    var replanned: bool = paths[0] != paths[1] and paths[0] == paths[2]
    reference.free()
    candidate.free()
    world.free()
    hero.free()
    return {"exact":exact and replanned,"replanned":replanned,"rows":rows,
        "scope":"Same companion instances, obstruction added/removed between searches; no stale cache"}

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
    if not is_instance_valid(owner) or not is_instance_valid(owner.rig):
        return {"exact":false,"error":"Native hero absent"}
    var contact := _contact_search(owner)
    var pet := _pet_paths(main)
    var replan := _pet_replan()
    return {"exact":bool(contact.exact) and bool(pet.exact) and bool(replan.exact),
        "contact":contact,"pet":pet,"replan":replan,"framing":framing(owner),
        "gear":player.visual.active_gear,"scope":"Production methods vs QA-only original references; no physical-phone claim"}

func record_start(main: Node) -> Dictionary:
    record_finish()
    recorded_owner = main._active_player_node().visual._native_worn
    recorded_reference = _new_motion(OriginalMotion,recorded_owner)
    recorded_candidate = _new_motion(CandidateMotion,recorded_owner)
    if recorded_reference.is_empty() or recorded_candidate.is_empty():
        return {"exact":false,"error":"Motion replay configuration failed"}
    for property in recorded_owner.motion.get_property_list():
        if (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) == 0: continue
        var key: String = property.name
        if key == "rig": continue
        for row in [recorded_reference,recorded_candidate]:
            var value: Variant = recorded_owner.motion.get(key)
            row.motion.set(key,value.duplicate(true) if value is Dictionary or value is Array else value)
    recorded = {"exact":true,"frames":0,"mining_frames":0,"contour_frames":0,"swings":0,"impacts":0,"retargets":0,"cancels":0,"clipped_frames":0,"failures":[]}
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
    var old_ok: bool = recorded_reference.motion.advance(delta,packet.duplicate(true))
    var new_ok: bool = recorded_candidate.motion.advance(delta,packet.duplicate(true))
    var equal: bool = old_ok and new_ok and recorded_reference.motion.shown == recorded_candidate.motion.shown and recorded_reference.motion.snapshot() == recorded_candidate.motion.snapshot()
    recorded.exact = recorded.exact and equal
    recorded.frames += 1
    if not equal: recorded.failures.append({"frame":recorded.frames,"old_ok":old_ok,"new_ok":new_ok})
    if packet.mining: recorded.mining_frames += 1
    if not packet.contact_surfaces.is_empty(): recorded.contour_frames += 1
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
    var result: Dictionary = recorded.duplicate(true)
    _release_motion(recorded_reference)
    _release_motion(recorded_candidate)
    prior_packet.clear()
    return result
