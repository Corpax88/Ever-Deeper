extends Node2D
## Locomotion always belongs to the unchanged player controller.
const IDS = ["twin_auger", "chainbreaker", "ricochet", "corebreaker", "vortex"]
var world: Node2D
var mode: String = ""
var target_key: String = ""
var elapsed: float = 0.0
var charge: float = 0.0
var chain: Array = []
var chain_clock: float = 0.0
var chain_from: Vector2
var core_id: String = ""
var core_left: int = 0
var core_clock: float = 0.0
var projectile: Dictionary = {}
var arcs: Array = []
var hit_log: Array = []
var hits: int = 0
var held_last: bool = false
var direction: Vector2 = Vector2.RIGHT
var textures: Dictionary = {}
var core_pulse: float = 0.0
var drop_queue: Array = []
var drop_cursor: int = 0
var flights: Dictionary = {}
var pickup_clock: float = 0.0
var scanned_last: int = 0

func setup(owner_world: Node2D) -> void:
	world = owner_world
	textures["ricochet-projectile"] = ImageTexture.create_from_image(Image.load_from_file("res://assets/ui/mods/ricochet-projectile-tool-v1.png"))
	z_index = 1902
	material = CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func cancel(clear_charge: bool = false) -> void:
	target_key = ""; elapsed = 0.0; chain.clear(); projectile.clear()
	core_id = ""; core_left = 0; arcs.clear(); held_last = false
	if clear_charge: charge = 0.0
	queue_redraw()

func reset() -> void:
	cancel(true); mode = ""; clear_flights()

func tick(delta: float, selected: String, held: bool) -> void:
	if selected != mode:
		reset(); mode = selected
		if not textures.has(mode):
			var path: String = "res://assets/ui/mods/"+mode+"-tool-v1.png"
			if FileAccess.file_exists(path): textures[mode] = ImageTexture.create_from_image(Image.load_from_file(path))
	core_pulse = maxf(0.0,core_pulse-delta)
	for i in range(arcs.size()-1,-1,-1):
		arcs[i].age += delta
		if arcs[i].age>=0.22: arcs.remove_at(i)
	var intent: Vector2 = world.player.external_movement+Input.get_vector("move_left","move_right","move_up","move_down")
	direction = intent.normalized() if intent.length_squared()>0.0025 else world.player.animation_bearing.normalized()
	if direction.is_zero_approx(): direction = Vector2.RIGHT
	if not held or not world.active or not world.player.control_enabled or int(RunState.drill_level)<=0:
		if held_last: cancel()
		queue_redraw(); return
	held_last = true; world.player.set_facing(direction)
	var step: float = minf(delta,0.05)
	_update_chain(step); _update_core(step); _update_projectile(step)
	if not projectile.is_empty() or core_left>0: queue_redraw(); return
	var target: Dictionary = _target(256.0 if mode=="ricochet" else 122.0)
	var key: String = String(target.get("key",""))
	if key!=target_key: target_key = key; elapsed = 0.0
	if target.is_empty(): world.player.set_mining_visual(false,0.0); queue_redraw(); return
	elapsed += step
	var period: float = maxf(0.08,world._mining_cycle_duration())
	world.player.set_mining_visual(true,minf(elapsed/period,1.0),0.0,0.5)
	if elapsed>=period:
		elapsed = 0.0; _impact(target,period); world._update_buried_visibility()
		AudioDirector.play_mining("deepstone",true,false)
	queue_redraw()

func _target(reach: float) -> Dictionary:
	var origin: Vector2 = world.player.global_position
	var best: int = -1
	var distance: float = minf(reach,122.0)
	for i in world.resources.size():
		var node: Dictionary = world.resources[i]
		var offset: Vector2 = Vector2(node.position)-origin
		if bool(node.mined) or not world._is_floor(Vector2i(node.cell)): continue
		if offset.length()>distance or direction.dot(offset.normalized())<0.65: continue
		if not world._clear_mining_line(origin,node.position): continue
		best = i; distance = offset.length()
	if best>=0: return {"node":best,"key":String(world.resources[best].id),"point":Vector2(world.resources[best].position)}
	var ray: Dictionary = world.drill_modes._laser_target(origin,direction)
	if not ray.has("cell") or float(ray.distance)>reach: return {}
	if int(ray.node)>=0:
		if float(ray.distance)>122.0: return {}
		return {"node":int(ray.node),"key":String(world.resources[int(ray.node)].id),"point":Vector2(world.resources[int(ray.node)].position)}
	return {"cell":Vector2i(ray.cell),"key":str(world.absolute_cell(Vector2i(ray.cell))),"point":world._cell_center(Vector2i(ray.cell))}

func _power() -> int:
	return maxi(1,int(world._current_endless_tool().get("power",1)))

func _wall(cell: Vector2i, power: int) -> void:
	if not world._cell_diggable(cell) or world._is_floor(cell): return
	if not RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(cell))): return
	world.dig_damage[cell] = int(world.dig_damage.get(cell,0))+power
	if int(world.dig_damage[cell])>=520: world._break_diggable_cell(cell)
	world.queue_redraw(); hits += 1

func _node(id: String) -> int:
	for i in world.resources.size():
		if String(world.resources[i].id)==id and not bool(world.resources[i].mined) and world._is_floor(Vector2i(world.resources[i].cell)): return i
	return -1

func _hit_node(index: int, kind: String) -> void:
	var id: String = String(world.resources[index].id)
	world._strike_resource(index,_power(),false); hits += 1
	hit_log.append({"id":id,"kind":kind})
	if hit_log.size()>256: hit_log.pop_front()

func _impact(target: Dictionary, period: float) -> void:
	if mode=="ricochet" and target.has("cell"):
		_launch(Vector2i(target.cell)); return
	if target.has("node"):
		var i: int = int(target.node)
		if mode=="corebreaker" and charge>=3.0:
			charge = 0.0; core_id = String(world.resources[i].id); core_left = 3; core_clock = _core_interval()
			_update_core(0.0)
		else:
			if mode=="chainbreaker" and chain.is_empty(): _start_chain(i)
			_hit_node(i,"direct")
			if mode=="corebreaker": charge = minf(3.0,charge+period)
	else:
		var cell: Vector2i = target.cell
		if mode=="twin_auger":
			# Snapshot a single exposed front. Side cutters have parallel approach lanes.
			var cells: Array[Vector2i] = []
			var side: Vector2 = direction.orthogonal()
			for offset in [0,-1,1,-2,2]:
				var candidate: Vector2i = world._world_to_cell(Vector2(target.point)+side*float(offset)*world.TILE_SIZE)
				if cells.has(candidate) or not world._cell_diggable(candidate): continue
				var lane: Vector2 = world.player.global_position+side*float(offset)*world.TILE_SIZE
				if not world._is_floor(world._world_to_cell(lane)): continue
				if not world._clear_mining_line(world.player.global_position,lane): continue
				if world._clear_mining_line(lane,world._cell_center(candidate),true): cells.append(candidate)
			for candidate in cells: _wall(candidate,_power())
		else:
			_wall(cell,_power())
			if mode=="vortex" and String(RunState.starforge_variant)=="crusher": world._apply_crusher_wave(cell,world._current_endless_tool())
		if mode=="corebreaker": charge = minf(3.0,charge+period)

func _start_chain(first: int) -> void:
	chain.clear(); chain_clock = 0.0; chain_from = Vector2(world.resources[first].position)
	var view: Rect2 = world.get_viewport_rect()
	var transform: Transform2D = world.get_viewport().get_canvas_transform()
	# Snapshot ALL eligible IDs; camera movement never changes this queue.
	for node in world.resources:
		if String(node.id)==String(world.resources[first].id) or bool(node.mined): continue
		if world._is_floor(Vector2i(node.cell)) and view.has_point(transform*Vector2(node.position)): chain.append(String(node.id))

func _update_chain(delta: float) -> void:
	if chain.is_empty(): return
	chain_clock += delta
	if chain_clock<0.1: return
	chain_clock = 0.0
	var index: int = _node(String(chain.pop_front()))
	if index<0: return
	var point: Vector2 = world.resources[index].position
	arcs.append({"a":chain_from,"b":point,"age":0.0}); _hit_node(index,"chain"); chain_from = point

func _core_interval() -> float:
	return minf(0.035,world._mining_cycle_duration()*0.4)

func _update_core(delta: float) -> void:
	if core_left<=0: return
	core_clock += delta
	if core_clock<_core_interval(): return
	core_clock = 0.0
	var index: int = _node(core_id)
	if index<0 or world.player.global_position.distance_to(world.resources[index].position)>122.0 or not world._clear_mining_line(world.player.global_position,world.resources[index].position):
		core_left = 0; core_id = ""; return
	_hit_node(index,"core"); core_left -= 1; core_pulse = 0.1
	AudioDirector.play_mining("deepstone",true,false)

func _launch(cell: Vector2i) -> void:
	var eligible: Array[Vector2i] = []
	var center: Vector2i = world._world_to_cell(world.player.global_position)
	for y in range(center.y-7,center.y+8):
		for x in range(center.x-7,center.x+8):
			var at: Vector2i = Vector2i(x,y)
			if world._cell_diggable(at) and not world._is_floor(at) and world._has_floor_neighbor(at): eligible.append(at)
	projectile = {"position":world.player.global_position,"cell":cell,"eligible":eligible,"visited":[],"age":0.0,"origin":world.player.global_position,"end":_contact(cell,world.player.global_position)}

func _contact(cell: Vector2i, from: Vector2) -> Vector2:
	var center: Vector2 = world._cell_center(cell)
	var normal: Vector2 = (from-center).normalized()
	return center+normal*(world.TILE_SIZE*0.5/maxf(absf(normal.x),absf(normal.y))+0.5)

func _update_projectile(delta: float) -> void:
	if projectile.is_empty(): return
	projectile.age += delta
	if float(projectile.age)>0.8: projectile.clear(); return
	var cell: Vector2i = projectile.cell
	var end: Vector2 = projectile.end
	var before: Vector2 = projectile.position
	var after: Vector2 = before.move_toward(end,1200.0*delta)
	if not world._clear_mining_line(before,after,true): projectile.clear(); return
	projectile.position = after
	if before.distance_to(after)>0.0: arcs.append({"a":before,"b":after,"age":0.0})
	if after.distance_to(end)>1.0: return
	_wall(cell,_power()); world._update_buried_visibility(); projectile.visited.append(cell)
	if projectile.visited.size()>=3: projectile.clear(); return
	var next: Vector2i = Vector2i(-1,-1)
	var score: float = INF
	for candidate in projectile.eligible:
		if projectile.visited.has(candidate) or world._is_floor(candidate): continue
		var point: Vector2 = _contact(candidate,after)
		var distance: float = after.distance_to(point)
		if distance>192.0 or distance>=score or not world._clear_mining_line(after,point,true): continue
		next = candidate; score = distance
	if next.x<0: projectile.clear()
	else: projectile.cell = next; projectile.end = _contact(next,after)

func register_drop(key: String) -> void:
	drop_queue.append(key); world.loose_drops[key].vortex_born = pickup_clock

func clear_flights() -> void:
	for key in flights:
		if world.loose_drops.has(key):
			var drop: Dictionary = world.loose_drops[key]
			drop.visual.position = drop.origin
	flights.clear()

func clear_drops() -> void:
	flights.clear(); drop_queue.clear(); drop_cursor = 0

func rebase(shift: Vector2) -> void:
	chain_from += shift
	for arc in arcs: arc.a += shift; arc.b += shift
	if not projectile.is_empty():
		var cells: Vector2i = Vector2i(shift/world.TILE_SIZE)
		projectile.position += shift; projectile.origin += shift; projectile.end += shift; projectile.cell += cells
		for field in ["eligible","visited"]:
			for i in projectile[field].size(): projectile[field][i] += cells

func collect_vortex(delta: float) -> bool:
	if mode!="vortex" or not world.active or not world.player.control_enabled: return false
	pickup_clock += delta; scanned_last = 0
	# Indexed registry + swap removal: at most 32 constant-time candidate steps.
	for i in mini(32,drop_queue.size()):
		if drop_queue.is_empty(): break
		drop_cursor %= drop_queue.size()
		var key: String = String(drop_queue[drop_cursor]); scanned_last += 1
		if not world.loose_drops.has(key):
			drop_queue[drop_cursor] = drop_queue.back(); drop_queue.pop_back(); continue
		drop_cursor += 1
		if flights.size()>=12 or flights.has(key): continue
		var drop: Dictionary = world.loose_drops[key]
		if pickup_clock-float(drop.get("vortex_born",0.0))<0.08: continue
		if drop.visual.position.distance_to(world.player.global_position)>256.0: continue
		if world._clear_mining_line(drop.visual.position,world.player.global_position): flights[key] = 0.0
	var velocity: float = world.player.animation_actual_motion.length()*float(Engine.physics_ticks_per_second)
	var speed: float = maxf(600.0,velocity+400.0)
	for key in flights.keys():
		if not world.loose_drops.has(key): flights.erase(key); continue
		var drop: Dictionary = world.loose_drops[key]
		var sprite: Sprite2D = drop.visual
		flights[key] += delta
		var distance: float = sprite.position.distance_to(world.player.global_position)
		if distance>512.0 or float(flights[key])>1.2 or not world._clear_mining_line(sprite.position,world.player.global_position):
			flights.erase(key); sprite.position = drop.origin; continue
		sprite.position = sprite.position.move_toward(world.player.global_position,speed*minf(delta,0.05))
		if sprite.position.distance_to(world.player.global_position)>18.0: continue
		var collected: Dictionary = RunState.collect_endless_drop(int(drop.depth),String(drop.id))
		if not collected.is_empty(): world.resource_collected.emit(String(collected.kind),int(collected.amount),int(drop.depth))
		if not collected.is_empty() or not RunState.endless_loose_drops(int(drop.depth)).has(String(drop.id)):
			sprite.queue_free(); world.loose_drops.erase(key)
		else: sprite.position = drop.origin
		flights.erase(key)
	return true

func _draw() -> void:
	if mode not in IDS or not world.active: return
	var origin: Vector2 = world.player.global_position+Vector2(0,-45)
	var native: Node = world.player.visual.get("_native_worn")
	var anchor: Dictionary = native.mod_anchor() if is_instance_valid(native) else {}
	if textures.has(mode) and not anchor.is_empty():
		var axis: Vector2 = Vector2(anchor.tip)-Vector2(anchor.base)
		var width: float = clampf(axis.length()*1.6,38.0,82.0)
		var height: float = width*float(textures[mode].get_height())/float(textures[mode].get_width())
		if mode=="corebreaker": width += core_pulse*60.0
		draw_set_transform(anchor.base,axis.angle(),Vector2(1,-1 if axis.x<0 else 1))
		draw_texture_rect(textures[mode],Rect2(Vector2(-width*0.12,-height*0.5),Vector2(width,height)),false)
		draw_set_transform(Vector2.ZERO)
	for arc in arcs:
		var a: Vector2 = Vector2(arc.a)+Vector2(0,-24)
		var b: Vector2 = Vector2(arc.b)+Vector2(0,-24)
		var alpha: float = 1.0-float(arc.age)/0.22
		var color: Color = Color(0.30,0.85,1.0,alpha) if mode=="chainbreaker" else Color(1.0,0.67,0.22,alpha)
		var points: PackedVector2Array = PackedVector2Array()
		for i in 9:
			var t: float = float(i)/8.0
			points.append(a.lerp(b,t)+Vector2(0,-sin(t*PI)*minf(48.0,a.distance_to(b)*0.15)))
		draw_polyline(points,Color(color,alpha*0.2),8.0,true); draw_polyline(points,color,2.0,true)
	if not projectile.is_empty():
		var at: Vector2 = Vector2(projectile.position)+Vector2(0,-24)
		var toward: Vector2 = world._cell_center(projectile.cell)-Vector2(projectile.position)
		draw_set_transform(at,toward.angle()); draw_texture_rect(textures["ricochet-projectile"],Rect2(-18,-9,36,18),false); draw_set_transform(Vector2.ZERO)
	if mode=="corebreaker" and charge>0.0:
		for i in 3: draw_circle(origin+Vector2(-12+i*7,-12),2.5,Color("ffc65a") if charge>=float(i+1) else Color("624a25"))

func snapshot() -> Dictionary:
	return {"flights":flights.size(),"scanned":scanned_last,"mode":mode,"hits":hits,"charge":charge,"chain_pending":chain.size(),"core_left":core_left,"projectile":not projectile.is_empty(),"log":hit_log.duplicate(true)}
