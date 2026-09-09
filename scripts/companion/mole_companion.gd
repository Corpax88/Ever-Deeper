class_name MoleCompanion
extends Node2D

const Skills = preload("res://scripts/companion/mole_skills.gd")
const WALK: Texture2D = preload("res://assets/companion/walk.png")
const PICKUP: Texture2D = preload("res://assets/companion/pickup.png")
const SHAKE: Texture2D = preload("res://assets/companion/shake.png")
var world: Node2D
var hero: Node2D
var sprite: Sprite2D
var lamp: HeadlampBeam
var mode: String = "follow"
var facing: Vector2 = Vector2.DOWN
var destination: Vector2 = Vector2.ZERO
var task_point: Vector2 = Vector2.ZERO
var loot_id: String = ""
var action: String = "idle"
var animation_clock: float = 0.0
var action_clock: float = 0.0
var think_clock: float = 0.0
var shake_cooldown: float = 0.0
var assist_cooldown: float = 0.0
var was_active: bool = false
var route: Array[Vector2] = []
var route_goal: Vector2 = Vector2(INF,INF)
var moving: bool = false
var marker: Sprite2D
var marker_time: float = 0.0
var collected_total: int = 0
var dug_total: int = 0
var feeling: String = "Right beside you"
var feedback: String = ""
var feedback_time: float = 0.0
var bubble: Label
var hold_time: float = 0.0
var sniff_clock: float = 3.0
var last_sniff: Vector2 = Vector2(INF,INF)
var guide_kind: String = ""
var guide_point: Vector2 = Vector2(INF,INF)
var guide_time: float = 0.0
var idle_clock: float = 0.0
var assist_action: bool = false
var failed_loot: Dictionary = {}


func _ready() -> void:
	world = get_parent()
	hero = world.get("player")
	z_index = 9
	sprite = Sprite2D.new()
	sprite.texture = WALK
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.scale = Vector2.ONE * (74.0/256.0)
	sprite.offset = Vector2(0,-114)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	lamp = HeadlampBeam.new()
	lamp.name = "PremiumHeadlamp"
	lamp.position = Vector2(0,-59)
	lamp.base_energy = 0.72
	add_child(lamp)
	lamp.configure(Color("ffe0a0"),facing,0.0,220.0)
	lamp.beam_light.energy = 0.72
	marker = Sprite2D.new()
	marker.texture = preload("res://assets/ui/hud-guide-v1.png")
	marker.scale = Vector2.ONE * (30.0/float(marker.texture.get_width()))
	marker.z_index = 11
	marker.visible = false
	world.add_child.call_deferred(marker)
	bubble = Label.new()
	bubble.position = Vector2(-90,-130)
	bubble.z_index=30
	bubble.size = Vector2(180,28)
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.add_theme_font_size_override("font_size",15)
	bubble.add_theme_color_override("font_color",Color("fff0c5"))
	bubble.add_theme_color_override("font_outline_color",Color("422d25"))
	bubble.add_theme_constant_override("outline_size",5)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bubble)
	visible = false

func _physics_process(delta: float) -> void:
	var live: bool = is_instance_valid(hero) and world.is_visible_in_tree() and (world.has_method("_surface_collides") or bool(world.get("active")))
	visible = live
	if not live:
		was_active = false
		if is_instance_valid(marker): marker.visible=false
		return
	if not was_active or global_position.distance_to(hero.global_position)>1000.0:
		_spawn_beside_hero()
	was_active = true
	if failed_loot.size()>80: failed_loot.clear()
	if action == "tunnel":
		action_clock += delta
		animation_clock += delta
		bubble.visible = true
		bubble.text = "I'll dig us home!"
		_draw_pose()
		return
	if not bool(hero.get("control_enabled")):
		_draw_pose()
		return
	feedback_time = maxf(0.0,feedback_time-delta)
	bubble.visible = feedback_time>0.0
	bubble.text = feedback
	bubble.position.y = -130.0 - sin(minf(feedback_time,1.0)*PI)*5.0
	guide_time = maxf(0.0,guide_time-delta)
	if guide_time<=0.0: guide_kind=""
	hold_time += delta if mode=="hold" else 0.0
	idle_clock += delta if action=="idle" else 0.0
	shake_cooldown = maxf(0.0,shake_cooldown-delta)
	assist_cooldown = maxf(0.0,assist_cooldown-delta)
	marker_time = maxf(0.0,marker_time-delta)
	if is_instance_valid(marker): marker.visible = marker_time>0.0
	animation_clock += delta
	if not bool(hero.get("control_enabled")):
		_draw_pose()
		return
	if action in ["pickup","shake"]:
		_update_action(delta)
		_draw_pose()
		return
	think_clock -= delta
	if think_clock<=0.0:
		think_clock=0.30
		_think()
	if action in ["pickup","shake"]:
		_draw_pose()
		return
	moving = false
	var stop_radius: float = 50.0 if mode=="follow" else 9.0
	if global_position.distance_to(destination)>stop_radius:
		_move(delta)
	elif mode=="fetch":
		action="pickup"
		action_clock=0.0
	elif mode=="dig":
		_begin_shake()
	elif mode in ["command","scout","homeward"]:
		mode="hold"
		hold_time=0.0
		_react("Here we are!",2.0)
	if action not in ["pickup","shake"]:
		action = "walk" if moving else "idle"
	_draw_pose()

func _spawn_beside_hero() -> void:
	global_position = hero.global_position
	for offset in [Vector2(-46,28),Vector2(46,28),Vector2(0,48),Vector2(0,-48),Vector2.ZERO]:
		if not _blocked(hero.global_position+offset):
			global_position=hero.global_position+offset
			break
	failed_loot.clear()
	last_sniff=Vector2(INF,INF)
	guide_time=0.0
	guide_kind=""
	recall()

func recall() -> void:
	mode="follow"
	action="idle"
	loot_id=""
	assist_action=false
	route.clear()
	route_goal=Vector2(INF,INF)


func begin_tunnel_home() -> void:
	_spawn_beside_hero()
	was_active = true
	action = "tunnel"
	action_clock = 0.0
	_react("I'll dig us home!", 1.2)


func rebase_world(offset: Vector2) -> void:
	# Every remembered destination shares the world's floating local origin.
	global_position += offset
	destination += offset
	task_point += offset
	if is_finite(route_goal.x): route_goal += offset
	if is_finite(guide_point.x): guide_point += offset
	if is_finite(last_sniff.x): last_sniff += offset
	for index in range(route.size()): route[index] += offset
	if is_instance_valid(marker): marker.global_position += offset
	destination=hero.global_position

func command(point: Vector2) -> bool:
	if point.distance_to(hero.global_position)>680.0:
		_react("A little closer?",2.2)
		return false
	if _blocked(point):
		if not Skills.has_skill("shake") or shake_cooldown>0.0 or not world.has_method("companion_can_dig") or not world.call("companion_can_dig",point):
			_react("Learning to dig!" if not Skills.has_skill("shake") else "Resting paws: %ds" % ceili(shake_cooldown) if shake_cooldown>0.0 else "Too tough for my paws",2.4)
			return false
		var landing: Vector2 = _nearby_floor(point)
		if not is_finite(landing.x):
			_react("Need an open path",2.0)
			return false
		destination=landing
		task_point=point
		mode="dig"
	else:
		destination=point
		mode="command"
	action="idle"
	loot_id=""
	route.clear()
	route_goal=Vector2(INF,INF)
	_ping(point)
	_react("Digging time!" if mode=="dig" else "On my way!",1.8)
	return true

func _think() -> void:
	var range_value: float = 440.0 if Skills.has_skill("long_beam") else 220.0
	if lamp.base_beam_length != range_value: lamp.configure(Color("ffe0a0"),facing,0.0,range_value)
	if mode in ["follow","fetch","hold"] and Skills.has_skill("teamwork") and assist_cooldown<=0.0 and world.has_method("companion_can_dig") and (world.get("external_mine_held") == true or Input.is_action_pressed("mine")):
		var point: Vector2 = hero.global_position+Vector2(hero.get("facing_vector"))*52.0
		if global_position.distance_to(point)<170.0 and world.has_method("companion_can_dig") and bool(world.call("companion_can_dig",point)):
			assist_action=true
			assist_cooldown=2.5
			action="shake"
			action_clock=0.0
			task_point=point
			facing=(point-global_position).normalized()
			return
	if mode=="hold" and (hold_time>6.0 or hero.global_position.distance_to(global_position)>300.0): recall()
	sniff_clock-=0.30
	if Skills.has_skill("ore_nose") and sniff_clock<=0.0 and mode in ["follow","hold"]:
		sniff_clock=10.0
		if world.has_method("companion_ore_target"):
			var ore: Vector2=world.call("companion_ore_target",global_position)
			if is_finite(ore.x) and (not is_finite(last_sniff.x) or ore.distance_to(last_sniff)>16.0):
				last_sniff=ore
				guide_kind="ore_nose"
				guide_point=ore
				guide_time=12.0
				_ping(ore)
				_react("Sniff sniff... ore!",2.4)
	if mode=="fetch":
		var found: bool = false
		for drop in _loot():
			if String(drop.id)==loot_id:
				destination=Vector2(drop.position)
				found=true
				break
		if not found: recall()
	if mode in ["follow","hold"]:
		if mode=="follow": destination=hero.global_position
		var best: float = 440.0 if Skills.has_skill("ore_nose") else 280.0
		for drop in _loot():
			var distance: float = global_position.distance_to(Vector2(drop.position))
			if int(failed_loot.get(String(drop.id),0))<Time.get_ticks_msec() and distance<best and float(drop.get("age",1.0))>0.15 and not _blocked(Vector2(drop.position)):
				best=distance
				loot_id=String(drop.id)
				destination=Vector2(drop.position)
				mode="fetch"

func _loot() -> Array:
	return world.call("companion_loot_candidates") if world.has_method("companion_loot_candidates") else []

func _begin_shake() -> void:
	if shake_cooldown>0.0:
		recall()
		return
	action="shake"
	action_clock=0.0
	facing=(task_point-global_position).normalized()

func shake_nearby() -> bool:
	if not Skills.has_skill("shake") or shake_cooldown>0.0: return false
	var best: Vector2=Vector2(INF,INF)
	var distance: float=INF
	for y in range(-3,4):
		for x in range(-3,4):
			var point: Vector2=hero.global_position+Vector2(x,y)*40.0
			if world.has_method("companion_can_dig") and world.call("companion_can_dig",point) and is_finite(_nearby_floor(point).x):
				var score: float=point.distance_to(hero.global_position)
				if score<distance: best=point; distance=score
	if not is_finite(best.x):
		_react("Tap an ordinary wall",2.4)
		return false
	return command(best)

func _update_action(delta: float) -> void:
	var previous: float = action_clock
	action_clock += delta
	if action=="pickup" and previous<0.50 and action_clock>=0.50:
		var radius: float = 100.0 if Skills.has_skill("big_paws") else 32.0
		var collected: int = int(world.call("companion_collect_loot",global_position,radius)) if world.has_method("companion_collect_loot") else 0
		collected_total += collected
		Skills.earn(collected)
		if collected>0: _react("Got %d! +%d paws" % [collected,collected],2.2)
		elif not loot_id.is_empty(): failed_loot[loot_id]=Time.get_ticks_msec()+10000
	if action=="shake" and (mode=="dig" or assist_action) and previous<0.44 and action_clock>=0.44:
		var count: int = int(world.call("companion_dig",task_point,not assist_action)) if world.has_method("companion_dig") else 0
		dug_total+=count
		if not assist_action: shake_cooldown=8.0 if count>0 else 1.0
		if count>0:
			_react("Teamwork!" if assist_action else "%d blocks!" % count,2.2)
			AudioDirector.play_mining("stone",true,false)
	if action_clock>=(0.72 if action=="pickup" else 0.84): recall()

func _draw_pose() -> void:
	var row: int = 1 if absf(facing.x)>absf(facing.y) and facing.x>0 else 3 if absf(facing.x)>absf(facing.y) else 0 if facing.y>=0 else 2
	var frame: int = 0
	sprite.texture=WALK
	if action=="walk": frame=int(animation_clock*8.0)%4
	elif action=="pickup":
		sprite.texture=PICKUP
		frame=mini(3,int(action_clock/0.18))
	elif action in ["shake", "tunnel"]:
		sprite.texture=SHAKE
		frame=int(action_clock/0.21)%4 if action=="tunnel" else mini(3,int(action_clock/0.21))
	sprite.frame=row*4+frame
	# Small whole-body gestures layer over the existing authored directional frames.
	var breath: float=sin(animation_clock*2.6)*0.016 if action=="idle" else 0.0
	var happy: float=maxf(0.0,sin(feedback_time*9.0))*2.0 if feedback_time>0.0 else 0.0
	sprite.scale=Vector2(1.0-breath*0.4,1.0+breath)*(74.0/256.0)
	sprite.position.y=-happy
	sprite.rotation=sin(animation_clock*2.0)*0.035 if action=="idle" and fmod(idle_clock,9.0)>6.5 else 0.0
	# Helmet light follows the lamp in each real directional frame.
	lamp.position=Vector2(10 if row==1 else -10 if row==3 else 0,-56 if row!=2 else -61)
	if action=="pickup" and frame in [1,2]: lamp.position.y+=16.0
	lamp.set_direction(facing)

func _blocked(point: Vector2) -> bool:
	var bounds: Vector2=hero.get("world_size")
	if point.x<24.0 or point.y<24.0 or point.x>bounds.x-24.0 or point.y>bounds.y-24.0: return true
	if world.has_method("collision_at"): return bool(world.call("collision_at",point))
	if world.has_method("_surface_collides"): return bool(world.call("_surface_collides",point))
	if world.has_method("_player_collides"): return bool(world.call("_player_collides",point))
	if world.has_method("_resolve_motion"):
		var resolved: Vector2 = world.call("_resolve_motion",point,Vector2.ZERO)
		return resolved.distance_to(point)>0.5
	return false

func _segment_clear(a: Vector2,b: Vector2) -> bool:
	var steps: int = maxi(1,ceili(a.distance_to(b)/12.0))
	for i in range(1,steps+1):
		if _blocked(a.lerp(b,float(i)/float(steps))): return false
	return true

func _nearby_floor(point: Vector2) -> Vector2:
	var best: Vector2 = Vector2(INF,INF)
	var score: float = INF
	for offset in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
		var candidate: Vector2 = point+offset*48.0
		if not _blocked(candidate) and candidate.distance_to(global_position)<score:
			best=candidate
			score=candidate.distance_to(global_position)
	return best

func _move(delta: float) -> void:
	var next: Vector2 = destination
	if not _segment_clear(global_position,destination):
		if route.is_empty() or route_goal.distance_to(destination)>30.0:
			route=_path_to(destination)
			route_goal=destination
		if route.is_empty():
			if mode!="follow":
				if mode=="fetch": failed_loot[loot_id]=Time.get_ticks_msec()+10000
				_react("Need an open path",2.0)
				recall()
			return
		while not route.is_empty() and global_position.distance_to(route[0])<0.5: route.pop_front()
		if route.is_empty(): return
		next=route[0]
	else: route.clear()
	if mode=="homeward" and global_position.distance_to(hero.global_position)>175.0:
		feeling="Waiting for you"
		return
	var speed: float = 280.0*(1.60 if Skills.has_skill("trailrunner") else 1.0)
	if mode=="follow" and global_position.distance_to(hero.global_position)>240.0: speed=maxf(speed,580.0)
	var offset: Vector2 = next-global_position
	var step: Vector2 = offset.limit_length(speed*delta)
	if not _segment_clear(global_position,global_position+step):
		route.clear()
		return
	if step.length_squared()>0.01:
		global_position+=step
		facing=offset.normalized()
		moving=true

func _path_to(point: Vector2) -> Array[Vector2]:
	var tile: float = 64.0 if world.has_method("_is_floor") else 48.0
	var start: Vector2i = Vector2i((global_position/tile).floor())
	var goal: Vector2i = Vector2i((point/tile).floor())
	var frontier: Array[Vector2i] = [start]
	var came: Dictionary = {start:start}
	var cursor: int = 0
	var found: bool = false
	while cursor<frontier.size() and cursor<2600:
		var cell: Vector2i = frontier[cursor]
		cursor+=1
		if cell==goal:
			found=true
			break
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var candidate: Vector2i = cell+offset
			var center: Vector2 = (Vector2(candidate)+Vector2(0.5,0.5))*tile
			if came.has(candidate) or candidate.x<0 or candidate.y<0: continue
			if _blocked(center): continue
			if not _segment_clear((Vector2(cell)+Vector2(0.5,0.5))*tile,center): continue
			came[candidate]=cell
			frontier.append(candidate)
	var result: Array[Vector2] = []
	if not found: return result
	var cell: Vector2i = goal
	while cell!=start:
		result.push_front((Vector2(cell)+Vector2(0.5,0.5))*tile)
		cell=Vector2i(came[cell])
	var start_center: Vector2=(Vector2(start)+Vector2(0.5,0.5))*tile
	if global_position.distance_to(start_center)>0.5 and _segment_clear(global_position,start_center): result.push_front(start_center)
	result.append(point)
	return result

func scout(kind: String) -> bool:
	if not Skills.has_skill(kind): return false
	var point: Vector2 = Vector2(INF,INF)
	if kind=="ore_nose" and world.has_method("companion_ore_target"):
		point=world.call("companion_ore_target",global_position)
	elif kind in ["echo","homeward"]:
		if world.has_method("prepare_tunnel_home"):
			point=world.call("guide_target","return" if kind=="homeward" else "deeper")
		elif world.has_method("_is_floor"): point=world.get("up_shaft_position") if kind=="homeward" else world.get("down_shaft_position")
		elif world.has_method("_terrain_is_solid"): point=world.call("entry_spawn") if kind=="homeward" else world.get("depth_entrance")
		elif world.has_method("_entry_spawn"):
			point=world.call("_entry_spawn") if kind=="homeward" else world.get("depth_entrance")
		elif world.has_method("guide_target"): point=world.call("guide_target","hubEntrance")
	if not is_finite(point.x): return false
	guide_kind=kind
	guide_point=point
	guide_time=20.0 if kind!="homeward" else 120.0
	_ping(point)
	_react("This way home!" if kind=="homeward" else "A way deeper!" if kind=="echo" else "I smell ore!",2.5)
	facing=(point-global_position).normalized()
	if kind=="echo":
		mode="hold"
		destination=global_position
		return true
	if _blocked(point): point=_nearby_floor(point)
	if not is_finite(point.x): return false
	destination=point
	mode="homeward" if kind=="homeward" else "scout"
	route.clear()
	route_goal=Vector2(INF,INF)
	return true

func _ping(point: Vector2) -> void:
	if not is_instance_valid(marker): return
	marker.global_position=point+Vector2(0,-25)
	marker_time=20.0
	marker.visible=true

func debug_snapshot() -> Dictionary:
	return {"mode":mode,"action":action,"position":global_position,"destination":destination,"collected":collected_total,"dug":dug_total,"frame":sprite.frame,"light":lamp.debug_snapshot(),"shake_cooldown":shake_cooldown}

func _react(message: String, duration: float=2.0) -> void:
	feedback=message
	feedback_time=duration

func pet() -> void:
	_react("Happy little paws!",2.5)

func status_text() -> String:
	if action=="pickup": return "Scooping up ore"
	if action=="shake": return "Helping you dig!" if assist_action else "Earthshaker!"
	match mode:
		"fetch": return "Fetching loose ore"
		"dig": return "Off to dig"
		"command": return "On my way"
		"scout": return "Following my nose"
		"homeward": return "Waiting for you" if global_position.distance_to(hero.global_position)>175.0 else "Leading you home"
		"hold": return "Lighting this spot"
	return "Right beside you"

func direction_hint() -> String:
	if guide_time<=0.0 or not is_finite(guide_point.x): return ""
	var offset: Vector2=guide_point-hero.global_position
	var arrow: String="Right" if absf(offset.x)>absf(offset.y) and offset.x>0 else "Left" if absf(offset.x)>absf(offset.y) else "Down" if offset.y>0 else "Up"
	return ("Ore" if guide_kind=="ore_nose" else "Home" if guide_kind=="homeward" else "Passage")+" · "+arrow+" · "+str(roundi(offset.length()/48.0))+" steps"
