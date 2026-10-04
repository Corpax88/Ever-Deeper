extends Node2D
## Locomotion always belongs to the unchanged player controller.
const IDS = ["twin_auger", "chainbreaker", "ricochet", "corebreaker", "vortex"]
const RICOCHET_REACH: float = 512.0
const RICOCHET_BOUNCE_REACH: float = 384.0
const RICOCHET_SPEED: float = 1200.0
const RICOCHET_LIFETIME: float = (RICOCHET_REACH+RICOCHET_BOUNCE_REACH*2.0)/RICOCHET_SPEED+0.25
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
# Presentation state never drives damage, rewards or player displacement.
var core_pulse: float = 0.0
var motion_clock: float = 0.0
var deployment: float = 0.0
var kick: float = 0.0
var rings: Array = []
var chips: Array = []
var ring_texture: Texture2D
var stone_texture: Texture2D
var twin_meshes: Dictionary = {}
var visual_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var drop_queue: Array = []
var drop_cursor: int = 0
var flights: Dictionary = {}
var pickup_clock: float = 0.0
var scanned_last: int = 0

func setup(owner_world: Node2D) -> void:
	world = owner_world
	visual_rng.seed = 71549
	ring_texture = ImageTexture.create_from_image(Image.load_from_file("res://assets/fx/resonance-ring-v1.png"))
	stone_texture = load("res://assets/drops/stone-drop.png")
	textures["ricochet-projectile"] = ImageTexture.create_from_image(Image.load_from_file("res://assets/ui/mods/ricochet-projectile-tool-v1.png"))
	z_index = 1902
	material = CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func cancel(clear_charge: bool = false) -> void:
	target_key = ""; elapsed = 0.0; chain.clear(); projectile.clear()
	core_id = ""; core_left = 0; arcs.clear(); held_last = false
	if clear_charge:
		charge = 0.0; rings.clear(); chips.clear(); deployment = 0.0; kick = 0.0; core_pulse = 0.0
	queue_redraw()

func reset() -> void:
	cancel(true); mode = ""; clear_flights()

func tick(delta: float, selected: String, held: bool) -> void:
	if selected != mode:
		reset(); mode = selected
		if not textures.has(mode):
			var path: String = "res://assets/ui/mods/"+mode+"-tool-v1.png"
			if FileAccess.file_exists(path): textures[mode] = ImageTexture.create_from_image(Image.load_from_file(path))
	# World does not tick during menus. No independent timer survives pause.
	motion_clock += minf(delta,0.05)
	deployment = move_toward(deployment,1.0 if held and world.active and world.player.control_enabled else 0.0,minf(delta,0.05)/0.22)
	kick = maxf(0.0,kick-delta*7.0)
	core_pulse = maxf(0.0,core_pulse-delta)
	for list in [rings,chips]:
		for i in range(list.size()-1,-1,-1):
			list[i].age += delta
			if list[i].age>=list[i].life: list.remove_at(i)
	for i in range(arcs.size()-1,-1,-1):
		arcs[i].age += delta
		if arcs[i].age>=0.38: arcs.remove_at(i)
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
	var target: Dictionary = _target(RICOCHET_REACH if mode=="ricochet" else 122.0)
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
	var point: Vector2 = world.resources[index].position
	world._strike_resource(index,_power(),false); hits += 1
	if kind=="chain": _burst(point,75.0,3)
	elif kind=="core": _burst(point,110.0,5)
	hit_log.append({"id":id,"kind":kind})
	if hit_log.size()>256: hit_log.pop_front()

func _impact(target: Dictionary, period: float) -> void:
	kick = 1.0
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
		if mode=="chainbreaker" and chain.is_empty():
			_start_chain_at(world._cell_center(cell),"",world.absolute_cell(cell))
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
			for candidate in cells:
				_wall(candidate,_power())
				_spawn_chips(world._cell_center(candidate),2)
			if not cells.is_empty(): _burst(Vector2(target.point),90.0,0)
		else:
			_wall(cell,_power())
			if mode=="vortex" and String(RunState.starforge_variant)=="crusher": world._apply_crusher_wave(cell,world._current_endless_tool())
		if mode=="corebreaker": charge = minf(3.0,charge+period)

func _start_chain(first: int) -> void:
	_start_chain_at(Vector2(world.resources[first].position),String(world.resources[first].id))

func _start_chain_at(point: Vector2, first_id: String = "", first_cell: Vector2i = Vector2i(-1,-1)) -> void:
	chain.clear(); chain_clock = 0.0; chain_from = point
	_add_arc(world.player.global_position,chain_from)
	_burst(chain_from,80.0,3)
	var view: Rect2 = world.get_viewport_rect()
	var transform: Transform2D = world.get_viewport().get_canvas_transform()
	# Snapshot exposed ore and the visible rock front BEFORE the initiating hit.
	# Newly revealed ore needs a later attack. Stable IDs/absolute cells survive rebases.
	for node in world.resources:
		if String(node.id)==first_id or bool(node.mined): continue
		if world._is_floor(Vector2i(node.cell)) and view.has_point(transform*Vector2(node.position)): chain.append(String(node.id))
	var bounds: Rect2 = transform.affine_inverse()*view
	var low: Vector2i = world._world_to_cell(bounds.position)-Vector2i.ONE
	var high: Vector2i = world._world_to_cell(bounds.end)+Vector2i.ONE
	for y in range(maxi(0,low.y),mini(world.GRID_SIZE.y-1,high.y)+1):
		for x in range(maxi(0,low.x),mini(world.GRID_SIZE.x-1,high.x)+1):
			var cell: Vector2i = Vector2i(x,y)
			if world.absolute_cell(cell)==first_cell or not _chain_rock(cell): continue
			if view.has_point(transform*world._cell_center(cell)): chain.append(world.absolute_cell(cell))

func _chain_rock(cell: Vector2i) -> bool:
	return world._cell_diggable(cell) and not world._is_floor(cell) and world._has_floor_neighbor(cell) and RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(cell)))

func _update_chain(delta: float) -> void:
	if chain.is_empty(): return
	chain_clock += delta
	if chain_clock<0.1: return
	chain_clock = 0.0
	# Nearby hops make the mixed chain readable; each snapshotted target is hit once.
	var best: int = -1
	var distance: float = INF
	var point: Vector2
	for i in range(chain.size()-1,-1,-1):
		if chain[i] is Vector2i:
			var cell: Vector2i = chain[i]-world.absolute_cell(Vector2i.ZERO)
			if not _chain_rock(cell): chain.remove_at(i); continue
		else:
			var index: int = _node(String(chain[i]))
			if index<0: chain.remove_at(i); continue
	# Invalid entries were removed above; select from the surviving stable queue.
	for i in chain.size():
		var candidate: Vector2 = world._cell_center(chain[i]-world.absolute_cell(Vector2i.ZERO)) if chain[i] is Vector2i else Vector2(world.resources[_node(String(chain[i]))].position)
		var next_distance: float = chain_from.distance_squared_to(candidate)
		if next_distance<distance: best = i; distance = next_distance; point = candidate
	if best<0: return
	var target = chain[best]
	chain.remove_at(best)
	_add_arc(chain_from,point)
	if target is Vector2i:
		_wall(target-world.absolute_cell(Vector2i.ZERO),_power())
		_burst(point,75.0,3); world._update_buried_visibility()
	else: _hit_node(_node(String(target)),"chain")
	chain_from = point

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
	_hit_node(index,"core"); core_left -= 1; core_pulse = 0.14; kick = 1.0
	AudioDirector.play_mining("deepstone",true,false)

func _launch(cell: Vector2i) -> void:
	var eligible: Array[Vector2i] = []
	var center: Vector2i = world._world_to_cell(world.player.global_position)
	# Snapshot the whole possible three-contact route, including long bounces.
	var radius: int = ceili((RICOCHET_REACH+RICOCHET_BOUNCE_REACH*2.0)/world.TILE_SIZE)+1
	for y in range(maxi(0,center.y-radius),mini(world.GRID_SIZE.y-1,center.y+radius)+1):
		for x in range(maxi(0,center.x-radius),mini(world.GRID_SIZE.x-1,center.x+radius)+1):
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
	if float(projectile.age)>RICOCHET_LIFETIME: projectile.clear(); return
	var cell: Vector2i = projectile.cell
	var end: Vector2 = projectile.end
	var before: Vector2 = projectile.position
	var after: Vector2 = before.move_toward(end,RICOCHET_SPEED*delta)
	if not world._clear_mining_line(before,after,true): projectile.clear(); return
	projectile.position = after
	if before.distance_to(after)>0.0: _add_arc(before,after)
	if after.distance_to(end)>1.0: return
	_wall(cell,_power()); _burst(after,85.0,5); world._update_buried_visibility(); projectile.visited.append(cell)
	if projectile.visited.size()>=3: projectile.clear(); return
	var next: Vector2i = Vector2i(-1,-1)
	var score: float = INF
	for candidate in projectile.eligible:
		if projectile.visited.has(candidate) or world._is_floor(candidate): continue
		var point: Vector2 = _contact(candidate,after)
		var distance: float = after.distance_to(point)
		if distance>RICOCHET_BOUNCE_REACH or distance>=score or not world._clear_mining_line(after,point,true): continue
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
	for list in [rings,chips]:
		for item in list: item.position += shift
	if not projectile.is_empty():
		var cells: Vector2i = Vector2i(shift/world.TILE_SIZE)
		projectile.position += shift; projectile.origin += shift; projectile.end += shift; projectile.cell += cells
		for field in ["eligible","visited"]:
			for i in projectile[field].size(): projectile[field][i] += cells

func collect_vortex(delta: float) -> bool:
	if mode!="vortex" or not world.active or not world.player.control_enabled: return false
	pickup_clock += delta; scanned_last = 0
	var pickup_radius: float = world.loose_drop_pickup_radius(256.0)
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
		if drop.visual.position.distance_to(world.player.global_position)>pickup_radius: continue
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
		var radial: Vector2 = (world.player.global_position-sprite.position).normalized()
		var curl: float = minf(0.8,distance/100.0)
		var heading: Vector2 = (radial+radial.orthogonal()*curl).normalized()
		var travel: float = speed*minf(delta,0.05)
		var next: Vector2 = world.player.global_position if distance<=travel else sprite.position+heading*travel
		# Curvature must never turn an otherwise valid pickup through a wall.
		if not world._clear_mining_line(sprite.position,next): next = sprite.position.move_toward(world.player.global_position,travel)
		sprite.position = next
		if sprite.position.distance_to(world.player.global_position)>18.0: continue
		var collected: Dictionary = RunState.collect_endless_drop(int(drop.depth),String(drop.id))
		if not collected.is_empty(): world.resource_collected.emit(String(collected.kind),int(collected.amount),int(drop.depth))
		if not collected.is_empty() or not RunState.endless_loose_drops(int(drop.depth)).has(String(drop.id)):
			sprite.queue_free(); world.loose_drops.erase(key)
		else: sprite.position = drop.origin
		flights.erase(key)
	return true

func _add_arc(a: Vector2, b: Vector2) -> void:
	# Bounded visual history; every Chainbreaker target still receives its hit.
	if arcs.size()>=48: arcs.pop_front()
	arcs.append({"a":a,"b":b,"age":0.0})

func _spawn_chips(point: Vector2, count: int) -> void:
	for i in count:
		if chips.size()>=48: break
		chips.append({"position":point,"velocity":Vector2(visual_rng.randf_range(-120.0,120.0),visual_rng.randf_range(-70.0,100.0)),"age":0.0,"life":0.48,"size":visual_rng.randf_range(12.0,24.0),"spin":visual_rng.randf_range(-5.0,5.0)})

func _burst(point: Vector2, size: float, count: int) -> void:
	if rings.size()>=18: rings.pop_front()
	rings.append({"position":point,"age":0.0,"life":0.38,"size":size})
	_spawn_chips(point,count)

func _ring(point: Vector2, size: Vector2, angle: float, alpha: float) -> void:
	draw_set_transform(point,angle)
	draw_texture_rect(ring_texture,Rect2(-size*0.5,size),false,Color(1,1,1,clampf(alpha,0.0,1.0)))
	draw_set_transform(Vector2.ZERO)

func _floor_ring(point: Vector2, size: float, angle: float, alpha: float) -> void:
	# Spin in the floor plane, then project; never rotate the flattened ellipse upright.
	var flatten: Transform2D = Transform2D(Vector2(1,0),Vector2(0,0.58),point)
	draw_set_transform_matrix(flatten*Transform2D(angle,Vector2.ZERO))
	draw_texture_rect(ring_texture,Rect2(Vector2.ONE*(-size*0.5),Vector2.ONE*size),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func _tool_piece(rect: Rect2, width: float, base: Vector2, angle: float, shift: Vector2 = Vector2.ZERO, turn: float = 0.0, roll: float = 1.0) -> void:
	var texture: Texture2D = textures[mode]
	var size: Vector2 = texture.get_size()
	var scale: float = width/size.x
	var source: Rect2 = Rect2(rect.position*size,rect.size*size)
	var pos: Vector2 = (source.position-Vector2(size.x*0.12,size.y*0.5))*scale
	var extent: Vector2 = source.size*scale
	var pivot: Vector2 = Vector2(0,extent.y*0.5)
	var flip: float = -1.0 if cos(angle)<0.0 else 1.0
	var local: Vector2 = pos+pivot+shift
	local.y *= flip
	draw_set_transform(base+local.rotated(angle),angle+turn*flip,Vector2(1,flip*roll))
	draw_texture_rect_region(texture,Rect2(-pivot,extent),source)
	draw_set_transform(Vector2.ZERO)

func _twin_mesh(opened: float, phase: float) -> ArrayMesh:
	# One continuous UV surface: tubes bend with their cutters, never tear apart.
	# 221 vertices and <=84 cached phases; no per-frame image loading or lights.
	var size: Vector2 = textures["twin_auger"].get_size()
	var vertices: PackedVector3Array = PackedVector3Array()
	var uv: PackedVector2Array = PackedVector2Array()
	var indices: PackedInt32Array = PackedInt32Array()
	var columns: int = 16
	var rows: int = 12
	for y in rows+1:
		for x in columns+1:
			var q: Vector2 = Vector2(float(x)/columns,float(y)/rows)
			var p: Vector2 = (q-Vector2(0.12,0.5))*size
			var side: float = smoothstep(0.10,0.28,absf(q.y-0.5))*signf(q.y-0.5)
			p.y += side*opened*size.x*0.11*smoothstep(0.30,0.72,q.x)
			var center: float = 0.20 if q.y<0.34 else (0.80 if q.y>0.66 else 0.50)
			var spin: float = sin(phase+center*10.0)
			p.y -= (q.y-center)*size.y*opened*(0.28+0.28*spin)*smoothstep(0.71,0.92,q.x)
			vertices.append(Vector3(p.x,p.y,0)); uv.append(q)
	for y in rows:
		for x in columns:
			var at: int = y*(columns+1)+x
			indices.append_array(PackedInt32Array([at,at+1,at+columns+1,at+1,at+columns+2,at+columns+1]))
	var arrays: Array = []; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices; arrays[Mesh.ARRAY_TEX_UV]=uv; arrays[Mesh.ARRAY_INDEX]=indices
	var mesh: ArrayMesh = ArrayMesh.new(); mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

func _draw_tool(anchor: Dictionary) -> void:
	var axis: Vector2 = Vector2(anchor.tip)-Vector2(anchor.base)
	var angle: float = axis.angle()
	var width: float = clampf(axis.length()*2.1,56.0,110.0)
	var base: Vector2 = Vector2(anchor.base)-axis.normalized()*kick*3.0
	var turn: float = motion_clock*TAU*8.0
	if mode=="twin_auger":
		var phase: int = int(fposmod(turn,TAU)/TAU*12.0)
		var opened: int = roundi(deployment*6.0)
		var mesh_key: int = opened*12+phase
		if not twin_meshes.has(mesh_key): twin_meshes[mesh_key] = _twin_mesh(float(opened)/6.0,float(phase)/12.0*TAU)
		var size: Vector2 = textures[mode].get_size()
		var flip: float = -1.0 if cos(angle)<0.0 else 1.0
		draw_set_transform(base,angle,Vector2(width/size.x,width/size.x*flip))
		draw_mesh(twin_meshes[mesh_key],textures[mode])
		draw_set_transform(Vector2.ZERO)
	elif mode=="corebreaker":
		_tool_piece(Rect2(0,0,0.55,1),width,base,angle)
		var stroke: float = sin(clampf(core_pulse/0.14,0.0,1.0)*PI)*(-20.0)
		_tool_piece(Rect2(0.55,0,0.45,1),width,base,angle,Vector2(stroke,0))
		if charge>0.0:
			for i in 3:
				var strength: float = clampf(charge-float(i),0.0,1.0)
				_ring(base+axis.normalized()*(20+i*9),Vector2(12,24+strength*14),angle,strength*(0.50+sin(motion_clock*9+i)*0.15))
	else:
		_tool_piece(Rect2(0,0,1,1),width,base,angle)
		if deployment>0.0 and mode in ["chainbreaker","vortex"]:
			_ring(base+axis.normalized()*width*0.45,Vector2(16,36+sin(motion_clock*12)*4),angle,deployment*0.8)

func _draw() -> void:
	if mode not in IDS or not world.active: return
	var origin: Vector2 = world.player.global_position
	# The vortex is a textured rotating intake. It does not add dynamic lights.
	if mode=="vortex" and (deployment>0.0 or not flights.is_empty()):
		var intensity: float = maxf(deployment*0.32,minf(1.0,float(flights.size())/3.0))
		for i in 3:
			var size: float = 80.0+i*44.0
			_floor_ring(origin+Vector2(0,-15),size,motion_clock*(1.5+i*0.25),intensity*(0.48-i*0.1))
		for key in flights:
			if not world.loose_drops.has(key): continue
			var p: Vector2 = world.loose_drops[key].visual.position
			_ring(p+Vector2(0,-8),Vector2(26,18),motion_clock*4,0.65)
	var native: Node = world.player.visual.get("_native_worn")
	var anchor: Dictionary = native.mod_anchor() if is_instance_valid(native) else {}
	if textures.has(mode) and not anchor.is_empty(): _draw_tool(anchor)
	for arc in arcs:
		var a: Vector2 = Vector2(arc.a)+Vector2(0,-24)
		var b: Vector2 = Vector2(arc.b)+Vector2(0,-24)
		var age: float = float(arc.age)
		var alpha: float = pow(maxf(0.0,1.0-age/0.38),1.3)
		var chain_effect: bool = mode=="chainbreaker"
		var color: Color = Color(0.30,0.85,1.0,alpha) if chain_effect else Color(1.0,0.75,0.32,alpha)
		var points: PackedVector2Array = PackedVector2Array()
		for i in 17:
			var t: float = float(i)/16.0
			var jitter: float = sin(float(i)*2.7+floor(motion_clock*24.0))*5.0*sin(t*PI) if chain_effect else 0.0
			points.append(a.lerp(b,t)+Vector2(jitter,-sin(t*PI)*minf(65.0,a.distance_to(b)*0.20)))
		draw_polyline(points,Color(color,alpha*0.18),16.0,true)
		draw_polyline(points,color,4.5,true)
		draw_polyline(points,Color(1,1,0.92,alpha*0.9),1.5,true)
		if chain_effect:
			var head: float = minf(1.0,age/0.10)
			var at: Vector2 = a.lerp(b,head)+Vector2(0,-sin(head*PI)*minf(65.0,a.distance_to(b)*0.20))
			_ring(at,Vector2(37,37),motion_clock*7,alpha)
	if not projectile.is_empty():
		var at: Vector2 = Vector2(projectile.position)+Vector2(0,-24)
		var toward: Vector2 = world._cell_center(projectile.cell)-Vector2(projectile.position)
		_ring(at,Vector2(36,26),toward.angle(),0.75)
		draw_set_transform(at,toward.angle(),Vector2(1,0.82+0.18*sin(motion_clock*65)))
		draw_texture_rect(textures["ricochet-projectile"],Rect2(-26,-13,52,26),false)
		draw_set_transform(Vector2.ZERO)
	for ring in rings:
		var t: float = float(ring.age)/float(ring.life)
		var size: float = float(ring.size)*(0.40+t*0.85)
		_ring(Vector2(ring.position)+Vector2(0,-20),Vector2(size,size*0.65),t*0.4,(1.0-t)*0.9)
	for chip in chips:
		var t: float = float(chip.age)/float(chip.life)
		var point: Vector2 = Vector2(chip.position)+Vector2(chip.velocity)*float(chip.age)+Vector2(0,-sin(t*PI)*42.0)
		var size: float = float(chip.size)
		draw_set_transform(point,float(chip.spin)*t)
		draw_texture_rect(stone_texture,Rect2(Vector2.ONE*(-size*0.5),Vector2.ONE*size),false,Color(1,1,1,1-t*t))
	draw_set_transform(Vector2.ZERO)

func snapshot() -> Dictionary:
	return {"visual_clock":motion_clock,"deployment":deployment,"rings":rings.size(),"chips":chips.size(),"arcs":arcs.size(),"flights":flights.size(),"scanned":scanned_last,"mode":mode,"hits":hits,"charge":charge,"chain_pending":chain.size(),"core_left":core_left,"projectile":not projectile.is_empty(),"log":hit_log.duplicate(true)}
