extends RefCounted
## Bounded native task-space pilot. Does not bypass native_rig's reference guard.
## Carries the tool and released hand separately; solves actual rigid limb lengths.
const SIDES = ["R", "L"]
var rig: Node
var metadata: Dictionary
var bank: Dictionary = {}
var shown: Dictionary = {}
var older: Dictionary = {}
var transition_source: Dictionary = {}
var source_velocity: Dictionary = {}
var source_angular: Dictionary = {}
var mode := "idle"
var yaw := 0.0
var phase := 0.0
var age := 1.0
var duration := .12
var gait := 0.0
var serial := -1
var impact_serial := -1
var physics_tick := -1
var previous_position := Vector2.ZERO
var travelled := 0.0
var root_position := Vector3.ZERO
var screen_to_ground := Transform2D.IDENTITY
var cap_local := Vector3.ZERO
var reference_cap := Vector3.ZERO
var contact_tool := Transform3D.IDENTITY
var contact_yaw := 0.0
var contact_screen := Vector2.ZERO
var contact_cache: Dictionary = {}
var aim_ready := false
var errors: Array[String] = []
var max_reach_error := 0.0
var max_grip_error := 0.0
var max_contact_pixels := 0.0
var max_tool_retarget := 0.0
var transitions := 0
var previous_delta := 1.0/60.0
var transition_airborne := false

func configure(native_rig: Node, path: String, reference_path: String) -> bool:
	rig = native_rig
	metadata = JSON.parse_string(FileAccess.get_file_as_string(path))
	if metadata.get("scope") != "isolated-native-motion-pilot": return false
	if metadata.reference_sha256 != FileAccess.get_sha256(reference_path): return false
	for family in metadata.samples:
		bank[family] = []
		for row in metadata.samples[family]:
			var pose: Dictionary = {"bones": {}, "release": float(row.support_release), "contacts": row.contacts}
			for name in row.bones: pose.bones[name] = rig._matrix(row.bones[name])
			bank[family].append(pose)
	cap_local = rig._vector(metadata.tool_cap_local)
	reference_cap = rig._vector(metadata.reference_contact)
	var camera_native: Transform3D = rig._matrix(rig.data.camera.world_matrix)
	var native_to_camera: Basis = camera_native.basis.transposed()
	var pixels := 160.0 / float(rig.data.camera.ortho_size)
	var x := native_to_camera * Vector3.RIGHT
	var y := native_to_camera * Vector3.UP
	screen_to_ground = Transform2D(Vector2(x.x,-x.y)*pixels,Vector2(y.x,-y.y)*pixels,Vector2.ZERO).affine_inverse()
	gait = float(metadata.flat_entry_phase)
	return true

func ground(displacement: Vector2) -> Vector3:
	var value := screen_to_ground * displacement
	return Vector3(value.x,value.y,0)

func project(point: Vector3) -> Vector2:
	var camera_native: Transform3D = rig._matrix(rig.data.camera.world_matrix)
	var p: Vector3 = camera_native.basis.transposed()*point
	return Vector2(p.x,-p.y)*(160.0/float(rig.data.camera.ortho_size))+Vector2(0,rig.GROUND_Y)

func _transform(a: Transform3D,b: Transform3D,w: float) -> Transform3D:
	return Transform3D(Basis(a.basis.get_rotation_quaternion().slerp(b.basis.get_rotation_quaternion(),w)),a.origin.lerp(b.origin,w))

func _smooth(t: float) -> float:
	t = clampf(t,0,1)
	return t*t*t*(10+t*(-15+6*t))

func _spin(a: Basis,b: Basis,seconds: float) -> Vector3:
	var q := a.get_rotation_quaternion()*b.get_rotation_quaternion().inverse()
	if q.w < 0: q = Quaternion(-q.x,-q.y,-q.z,-q.w)
	return Vector3.ZERO if q.get_angle() < .000001 else q.get_axis()*q.get_angle()/maxf(seconds,.000001)

func _chain(b: Dictionary,family: String,side: String) -> Array[Vector3]:
	if family == "arm": return [b["upper."+side].origin,b["lower."+side].origin,b["hand."+side].origin]
	return [b["thigh."+side].origin,b["shin."+side].origin,b["foot."+side].origin]

func _frame(chain: Array[Vector3],segment: int = -1) -> Basis:
	var axis := (chain[2]-chain[0]).normalized()
	var radial := chain[1]-chain[0]
	radial = (radial-axis*radial.dot(axis)).normalized()
	if segment < 0: return Basis(axis,radial,axis.cross(radial)).orthonormalized()
	var y := (chain[segment+1]-chain[segment]).normalized()
	var z := (chain[1]-chain[0]).cross(chain[2]-chain[1]).normalized()
	return Basis(y.cross(z),y,z).orthonormalized()

func _solve_chain(b: Dictionary,a: Dictionary,c: Dictionary,w: float,family: String,side: String) -> void:
	var ca := _chain(a,family,side)
	var cb := _chain(c,family,side)
	var current := _chain(b,family,side)
	var lengths := Vector2(.36,.35) if family == "arm" else Vector2(.180,.184)
	var distance := current[0].distance_to(current[2])
	max_reach_error = maxf(max_reach_error,maxf(distance-lengths.x-lengths.y,absf(lengths.x-lengths.y)-distance))
	var axis := (current[2]-current[0]).normalized()
	var frame := Basis(_frame(ca).get_rotation_quaternion().slerp(_frame(cb).get_rotation_quaternion(),w))
	var radial := Basis(Quaternion(frame.x,axis)) * frame.y
	# Quaternion transport can leave a small axial component at fractional
	# poses. The rigid two-link construction requires a unit perpendicular.
	radial = (radial-axis*radial.dot(axis)).normalized()
	var safe := clampf(distance,absf(lengths.x-lengths.y)+.000001,lengths.x+lengths.y-.000001)
	var along := (safe*safe+lengths.x*lengths.x-lengths.y*lengths.y)/(2*safe)
	current[1] = current[0]+axis*along+radial*sqrt(maxf(0,lengths.x*lengths.x-along*along))
	var prefixes := ["upper.","lower."] if family == "arm" else ["thigh.","shin."]
	for j in 2:
		var name: String = prefixes[j]+side
		var ra: Basis = _frame(ca,j).transposed()*a[name].basis
		var rb: Basis = _frame(cb,j).transposed()*c[name].basis
		var roll := Basis(ra.get_rotation_quaternion().slerp(rb.get_rotation_quaternion(),w))
		b[name] = Transform3D(_frame(current,j)*roll,current[j])

func mix(a: Dictionary,b: Dictionary,w: float,step: float = -1.0,airborne: bool = false) -> Dictionary:
	if w <= .0000001: return a.duplicate(true)
	if w >= .9999999: return b.duplicate(true)
	var out: Dictionary = {"bones":{},"release":lerpf(a.release,b.release,w),"contacts":b.contacts}
	var bones: Dictionary = out.bones
	for name in a.bones: bones[name] = _transform(a.bones[name],b.bones[name],w)
	for side in SIDES:
		var hand: String = "hand."+side
		var relative_a: Transform3D = a.bones.tool.affine_inverse()*a.bones[hand]
		var relative_b: Transform3D = b.bones.tool.affine_inverse()*b.bones[hand]
		var on_tool: Transform3D = bones.tool*_transform(relative_a,relative_b,w)
		if side == "R": bones[hand] = on_tool
		else:
			var local_a: Transform3D = a.bones.body.affine_inverse()*a.bones[hand]
			var local_b: Transform3D = b.bones.body.affine_inverse()*b.bones[hand]
			var free: Transform3D = bones.body*_transform(local_a,local_b,w)
			bones[hand] = _transform(on_tool,free,float(out.release))
		var shoulder_a: Vector3 = a.bones.body.affine_inverse()*a.bones["upper."+side].origin
		var shoulder_b: Vector3 = b.bones.body.affine_inverse()*b.bones["upper."+side].origin
		bones["upper."+side].origin = bones.body*shoulder_a.lerp(shoulder_b,w)
		if step >= 0:
			var at := step if airborne else clampf(step*2.0 if side == "L" else step*2.0-1.0,0,1)
			bones["foot."+side] = _transform(a.bones["foot."+side],b.bones["foot."+side],_smooth(at))
			bones["foot."+side].origin.z += (.065 if airborne else .045)*sin(PI*at)
	# Fit the pelvis over the two actual ankle endpoints before rigid-leg IK.
	var dip := 0.0
	for side in SIDES:
		var hip: Vector3 = bones["thigh."+side].origin
		var foot: Vector3 = bones["foot."+side].origin
		var horizontal := Vector2(hip.x-foot.x,hip.y-foot.y).length()
		if horizontal < .3639: dip = minf(dip,foot.z+sqrt(.3639*.3639-horizontal*horizontal)-hip.z)
	if dip < 0:
		for name in bones:
			if not name.begins_with("foot."): bones[name].origin.z += dip
	for side in SIDES:
		_solve_chain(bones,a.bones,b.bones,w,"arm",side)
		_solve_chain(bones,a.bones,b.bones,w,"leg",side)
	return out

func sample(family: String,at: float) -> Dictionary:
	var rows: Array = bank[family]
	var fractional := fposmod(at,1.0)*rows.size()
	var lo := int(floor(fractional))
	return mix(rows[lo],rows[(lo+1)%rows.size()],fractional-lo)

func rotate_pose(pose: Dictionary,angle: float,translation: Vector3 = Vector3.ZERO) -> Dictionary:
	var result: Dictionary = pose.duplicate(true)
	var transform := Transform3D(Basis(Vector3(0,0,1),angle),translation)
	for name in result.bones: result.bones[name] = transform*result.bones[name]
	return result

func plan_contact(screen_target: Vector2, surfaces: Array = [], record_failure: bool = true) -> bool:
	# Search a bounded family of genuine tool pitches/heights. The ray's screen
	# location stays exact; candidate scoring does not move the gameplay root.
	var contact: Dictionary = bank.mine[21]
	var hand_local: Transform3D = contact.bones.tool.affine_inverse()*contact.bones["hand.R"]
	var best := INF
	var best_tool := Transform3D.IDENTITY
	var best_yaw := 0.0
	var points: Array = [screen_target] if surfaces.is_empty() else surfaces.duplicate()
	var cache_key := str(screen_target)+str(points)
	if contact_cache.has(cache_key):
		var cached: Dictionary = contact_cache[cache_key]
		contact_tool = cached.tool
		contact_yaw = cached.yaw
		contact_screen = cached.screen
		return true
	var ground_target := ground(screen_target)
	var rough_yaw := atan2(ground_target.y,ground_target.x)-atan2(reference_cap.y,reference_cap.x)
	var prediction := project(Basis(Vector3(0,0,1),rough_yaw)*reference_cap)
	points.sort_custom(func(a,b): return Vector2(a).distance_squared_to(prediction) < Vector2(b).distance_squared_to(prediction))
	points = points.slice(0,mini(12,points.size()))
	for surface in points:
		for iz in 25:
			var height := .055+float(iz)*.05
			var z_projection := project(Vector3(0,0,height))
			var point := ground(Vector2(surface)-z_projection)+Vector3(0,0,height)
			var angle := atan2(point.y,point.x)-atan2(reference_cap.y,reference_cap.x)
			var rotation := Basis(Vector3(0,0,1),angle)
			var nominal: Transform3D = Transform3D(rotation,Vector3.ZERO)*contact.bones.tool
			var shoulder: Vector3 = rotation*contact.bones["upper.R"].origin
			var horizontal := Vector3(point.x,point.y,0).normalized()
			var pitch_axis := Vector3(0,0,1).cross(horizontal)
			for iy in 9:
				var swivel := deg_to_rad(float(iy-4)*15.)
				var swivel_basis := Basis(Vector3(0,0,1),swivel)*nominal.basis
				for ip in 19:
					var pitch := deg_to_rad(float(ip)*5.0)
					var tool := Transform3D(Basis(pitch_axis,pitch)*swivel_basis,Vector3.ZERO)
					tool.origin = point-tool.basis*cap_local
					var hand := tool*hand_local
					var reach := shoulder.distance_to(hand.origin)
					if reach > .698 or reach < .07 or hand.origin.z < .24: continue
					var score := nominal.origin.distance_squared_to(tool.origin)+pitch*pitch*.08+swivel*swivel*.08+pow(height-reference_cap.z,2)*.03
					if score < best:
						best = score
						best_tool = tool
						best_yaw = angle
						contact_screen = surface
	if not is_finite(best):
		if record_failure: errors.append("No reachable native contact for " + str(screen_target))
		return false
	contact_tool = best_tool
	contact_yaw = best_yaw
	contact_cache[cache_key] = {"tool":contact_tool,"yaw":contact_yaw,"screen":contact_screen}
	return true

func aimed(at: float) -> Dictionary:
	var result := rotate_pose(sample("mine",at),contact_yaw)
	var weight := _smooth((at-.30)/.12)*(1.0-_smooth((at-.445)/.30))
	if weight < .000001: return result
	var reference: Transform3D = Transform3D(Basis(Vector3(0,0,1),contact_yaw),Vector3.ZERO)*bank.mine[21].bones.tool
	var correction := contact_tool*reference.affine_inverse()
	var tool: Transform3D = result.bones.tool
	var changed := _transform(tool,correction*tool,weight)
	var hand_relative: Transform3D = tool.affine_inverse()*result.bones["hand.R"]
	# During retargeted approach/withdrawal the original moving shoulder can
	# leave the interpolated wrist outside its reach. Project the rigid tool,
	# never a bone endpoint independently. Accepted contact plans stay inside.
	var shoulder: Vector3 = result.bones["upper.R"].origin
	var wrist: Vector3 = changed*hand_relative.origin
	var reach := shoulder.distance_to(wrist)
	if reach > .698:
		var correction_position := shoulder+(wrist-shoulder).normalized()*.698-wrist
		max_tool_retarget = maxf(max_tool_retarget,correction_position.length())
		changed.origin += correction_position
	var before: Dictionary = result.bones.duplicate(true)
	result.bones.tool = changed
	result.bones["hand.R"] = changed*hand_relative
	_solve_chain(result.bones,before,before,0,"arm","R")
	return result

func _world(pose: Dictionary) -> Dictionary:
	var result := pose.duplicate(true)
	for name in result.bones: result.bones[name].origin += root_position
	return result

func advance(delta: float,packet: Dictionary) -> bool:
	if delta <= 0: return true
	var position: Vector2 = packet.world_position
	if physics_tick < 0:
		previous_position = position
		travelled = float(packet.travelled_distance)
	var displacement := position-previous_position
	root_position += ground(displacement)
	previous_position = position
	var distance := maxf(0,float(packet.travelled_distance)-travelled)
	travelled = float(packet.travelled_distance)
	physics_tick = int(packet.physics_tick)
	var next: String = "walk" if packet.moving else "mine" if packet.mining and packet.mining_timing_valid else "idle"
	var next_yaw := yaw
	if next != "mine":
		var direction := ground(packet.bearing)
		var canonical: Vector3 = rig._vector(metadata.ground_per_pixel)
		next_yaw = atan2(direction.y,direction.x)-atan2(canonical.y,canonical.x)
	var new_swing: bool = next == "mine" and int(packet.swing_serial) != serial
	if new_swing:
		aim_ready = plan_contact(packet.target_position-position,packet.get("contact_surfaces",[]))
		if not aim_ready: return false
		serial = int(packet.swing_serial)
		next_yaw = contact_yaw
	var continued: bool = new_swing and next == mode and bool(packet.get("swing_continuation",false))
	# Touch bearings change continuously. Restarting an unfinished turn at age
	# zero pins the displayed world pose while the viewport follows the player,
	# eventually clipping the entire hero. Retarget the existing turn until its
	# original deadline; genuine action changes still own a fresh transition.
	var action_changed := next != mode or (new_swing and not continued)
	var turn_changed := absf(angle_difference(yaw,next_yaw)) > .035
	var changed := action_changed or (turn_changed and age >= duration)
	if changed: transition_airborne = next == "walk" or mode == "walk" or absf(angle_difference(yaw,next_yaw)) > .35
	mode = next
	yaw = next_yaw
	if mode == "mine":
		var clock_progress: float = float(packet.progress)
		var clock_hit: float = clampf(float(packet.hit_phase), 0.01, 0.99)
		phase = clock_progress / clock_hit * 0.42 if clock_progress <= clock_hit else 0.42 + (clock_progress - clock_hit) / (1.0 - clock_hit) * 0.58
	elif mode == "walk":
		gait = fposmod(gait+distance/float(metadata.stride_pixels),1)
		phase = gait
	else: phase = fposmod(phase+delta/3.6,1)
	var wanted := _world(aimed(phase) if mode == "mine" and aim_ready else rotate_pose(sample(mode,phase),yaw))
	if shown.is_empty():
		shown = wanted.duplicate(true)
		older = shown.duplicate(true)
	if changed:
		transition_source = shown.duplicate(true)
		source_velocity.clear()
		source_angular.clear()
		for name in shown.bones:
			source_velocity[name] = (shown.bones[name].origin-older.bones[name].origin)/previous_delta
			source_angular[name] = _spin(shown.bones[name].basis,older.bones[name].basis,previous_delta)
		age = 0.0
		duration = .12
		if mode == "mine": duration = minf(duration,maxf(.001,(float(packet.hit_phase)-float(packet.progress))*float(packet.cycle_duration)*.65))
		transitions += 1
	var displayed := wanted
	if age < duration:
		var source := transition_source.duplicate(true)
		var u := clampf(age/duration,0,1)
		# Carry the measured incoming endpoint velocities; fade them smoothly.
		var carried := age*pow(1-u,2)
		for name in source.bones:
			source.bones[name].origin += Vector3(source_velocity[name])*carried
			var spin: Vector3 = source_angular[name]*carried
			if spin.length() > .000001: source.bones[name].basis = Basis(Quaternion(spin.normalized(),spin.length()))*source.bones[name].basis
		displayed = mix(source,wanted,_smooth(u),u,transition_airborne)
	var new_impact := int(packet.impact_serial) != impact_serial and impact_serial >= 0
	impact_serial = int(packet.impact_serial)
	if new_impact and packet.impact_target_valid:
		# Earned contact is rendered with its own retained target, even if a new
		# swing or cancel arrived in the same physics frame.
		var saved_tool := contact_tool
		var saved_yaw := contact_yaw
		var saved_screen := contact_screen
		if not plan_contact(packet.impact_target_position-position,packet.get("impact_surfaces",[])): return false
		displayed = _world(aimed(.42))
		var actual := project(displayed.bones.tool*cap_local-root_position)
		max_contact_pixels = maxf(max_contact_pixels,actual.distance_to(contact_screen))
		var old_contact: bool = int(packet.get("impact_swing_serial",serial)) != serial or mode != "mine"
		if old_contact:
			contact_tool = saved_tool
			contact_yaw = saved_yaw
			contact_screen = saved_screen
		# A same-swing earned retarget owns its entire recovery, not one frame.
		if age < duration or old_contact:
			# The rendered contact becomes the source of the still-pending plan.
			# Keep the original deadline, and do not resume a pre-contact source.
			duration = maxf(.001,duration-age) if age < duration else .12
			if mode == "mine": duration = minf(duration,maxf(.001,(float(packet.hit_phase)-float(packet.progress))*float(packet.cycle_duration)*.65))
			age = 0.0
			transition_source = displayed.duplicate(true)
			for name in displayed.bones:
				source_velocity[name] = (displayed.bones[name].origin-shown.bones[name].origin)/delta
				source_angular[name] = _spin(displayed.bones[name].basis,shown.bones[name].basis,delta)
	older = shown
	shown = displayed
	age += delta
	previous_delta = delta
	# An infeasible pose is evidence of a failed pilot, never a displayed rig
	# with disconnected bones. Keep the last valid render until the harness exits.
	for transform in shown.bones.values():
		if not Transform3D(transform).is_finite():
			errors.append("Rejected non-finite native transform")
			return false
	for side in SIDES:
		for family in ["arm","leg"]:
			var chain := _chain(shown.bones,family,side)
			var lengths := Vector2(.36,.35) if family == "arm" else Vector2(.180,.184)
			for segment in 2:
				var error := absf(chain[segment].distance_to(chain[segment+1])-lengths[segment])
				if error > .0001:
					errors.append("Rejected disconnected " + family + side + " segment " + str(segment) + " error " + str(error))
					return false
	rig.root_native = root_position
	rig.shown = shown.bones
	rig._apply(shown.bones)
	return true

func snapshot() -> Dictionary:
	return {"mode":mode,"phase":phase,"yaw":yaw,"age":age,"duration":duration,
		"swing_serial":serial,"transitions":transitions,"aim_ready":aim_ready,
		"max_reach_error":max_reach_error,"max_contact_pixels":max_contact_pixels,"max_tool_retarget":max_tool_retarget,
		"support_release":shown.get("release",0),"errors":errors.duplicate()}
