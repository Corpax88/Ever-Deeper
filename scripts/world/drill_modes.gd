extends Node2D
## Earned alternative drill modes. One target per timed impact; no catch-up burst.
const Goals = preload("res://scripts/state/treasury_goals.gd")
const REACH: int = 12
var world: Node2D
var target_key: String = ""
var elapsed: float = 0.0
var initial_hp: int = 1
var firing: bool = false
var beam_start: Vector2
var beam_end: Vector2
var impacts: int = 0
var mode: String = ""
var dev_override: String = ""
var dev_laser_on: bool = true
var emitter: Texture2D
var bore_heading: Vector2 = Vector2.ZERO
var detour: Dictionary = {}

func setup(owner_world: Node2D) -> void:
	world=owner_world
	emitter=ImageTexture.create_from_image(Image.load_from_file("res://assets/ui/mods/laser-emitter-v1.png"))
	z_index=1901
	material=CanvasItemMaterial.new()
	material.light_mode=CanvasItemMaterial.LIGHT_MODE_UNSHADED

func reset() -> void:
	target_key=""
	elapsed=0.0
	firing=false
	bore_heading=Vector2.ZERO
	detour.clear()
	if is_instance_valid(world) and is_instance_valid(world.player):
		world.player.drill_motion_override=false
		world.player.drill_motion=Vector2.ZERO
	queue_redraw()

func selected() -> String:
	var id: String=dev_override if not dev_override.is_empty() else Goals.active_mod()
	if dev_override=="laser": return "laser" if dev_laser_on else ""
	if id=="laser" and not bool(RunState.treasury_goals.get("laser_mode",false)): return ""
	return id if id in ["bore_rush","laser"] else ""

func tick(delta: float) -> bool:
	mode=selected()
	if mode.is_empty():
		reset()
		return false
	var held: bool=world.external_mine_held or Input.is_action_pressed("mine")
	if not held or not world.active or not world.player.control_enabled or int(RunState.drill_level)<=0:
		reset()
		return true
	world._cancel_mining()
	if mode=="bore_rush": return _tick_bore(delta)
	# The hero's four sprite facings are presentation, not the laser's aim.
	var direction: Vector2=world.player.animation_bearing.normalized()
	var intent: Vector2=Vector2(world.player.external_movement)+Input.get_vector("move_left","move_right","move_up","move_down")
	if intent.length_squared()>0.0025: direction=intent.normalized()
	if direction.is_zero_approx(): direction=Vector2.RIGHT
	world.player.set_facing(direction)
	world.player.drill_motion_override=false
	var target: Dictionary=_laser_target(world.player.global_position,direction)
	beam_start=world.player.global_position+Vector2(0,-48)+direction*28.0
	beam_end=world.player.global_position+Vector2(0,-48)+direction*maxf(32.0,float(target.distance))
	firing=true
	var found: bool=target.has("cell")
	var node_index: int=int(target.get("node",-1))
	# Small aim adjustments inside the same target do not restart its damage.
	var key: String=str(target.cell)+":"+str(node_index) if found else ""
	if key!=target_key:
		target_key=key
		elapsed=0.0
		initial_hp=int(world.resources[node_index].hp) if node_index>=0 else 1
	if found:
		elapsed+=minf(delta,0.05)
		var period: float=0.28 if node_index>=0 else 0.24
		if elapsed>=period:
			elapsed=0.0
			if node_index>=0: world._strike_resource(node_index,initial_hp,false)
			else: world._break_diggable_cell(Vector2i(target.cell))
			world._update_buried_visibility()
			AudioDirector.play_mining("deepstone",true,false)
			impacts+=1
			target_key=""
	queue_redraw()
	return true

# Grid traversal follows the exact analogue ray in all 360 degrees. Advance
# both axes at an exact corner so cells merely touched at a point are skipped.
func _laser_target(origin: Vector2,direction: Vector2) -> Dictionary:
	var cell: Vector2i=world._world_to_cell(origin)
	var step: Vector2i=Vector2i(int(signf(direction.x)),int(signf(direction.y)))
	var delta_x: float=absf(world.TILE_SIZE/direction.x) if absf(direction.x)>0.00001 else INF
	var delta_y: float=absf(world.TILE_SIZE/direction.y) if absf(direction.y)>0.00001 else INF
	var edge: Vector2=Vector2(cell+Vector2i(1 if step.x>0 else 0,1 if step.y>0 else 0))*world.TILE_SIZE
	var next_x: float=(edge.x-origin.x)/direction.x if delta_x<INF else INF
	var next_y: float=(edge.y-origin.y)/direction.y if delta_y<INF else INF
	var distance: float=0.0
	var reach: float=REACH*world.TILE_SIZE
	while distance<=reach:
		if not world._cell_diggable(cell) or not RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(cell))): return {"distance":distance}
		if not world._is_floor(cell): return {"cell":cell,"node":-1,"distance":distance}
		for i in world.resources.size():
			var ore: Dictionary=world.resources[i]
			if Vector2i(ore.cell)==cell and not bool(ore.mined):
				return {"cell":cell,"node":i,"distance":distance}
		distance=minf(next_x,next_y)
		var cross_x: bool=next_x<=next_y+0.0001
		var cross_y: bool=next_y<=next_x+0.0001
		if cross_x:
			cell.x+=step.x;next_x+=delta_x
		if cross_y:
			cell.y+=step.y;next_y+=delta_y
	return {"distance":reach}

# Rush owns locomotion; ordinary mining's stationary stance must not own it too.
# Sweep the player's footprint, not only the cell underneath its centre.
func _bore_target(origin: Vector2, direction: Vector2) -> Dictionary:
	var radius: float=world.PLAYER_RADIUS+2.0
	var seen: Dictionary={}
	for distance in range(0,97,8):
		var at: Vector2=origin+direction*float(distance)
		var first: Vector2i=world._world_to_cell(at-Vector2.ONE*radius)
		var last: Vector2i=world._world_to_cell(at+Vector2.ONE*radius)
		for y in range(first.y,last.y+1):
			for x in range(first.x,last.x+1):
				var cell: Vector2i=Vector2i(x,y)
				if seen.has(cell): continue
				var rect: Rect2=Rect2(Vector2(cell)*world.TILE_SIZE,Vector2.ONE*world.TILE_SIZE)
				var nearest: Vector2=at.clamp(rect.position,rect.end)
				if at.distance_squared_to(nearest)>radius*radius: continue
				seen[cell]=true
				if not world._is_floor(cell):
					if not world._cell_diggable(cell) or not RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(cell))):
						return {"blocked":true}
					return {"cell":cell,"node":-1}
		# Grounded ore can extend into the neighbouring row, just like the body.
		var grid: Vector2i=world._world_to_cell(at)
		for y in range(grid.y-2,grid.y+3):
			for x in range(grid.x-2,grid.x+3):
				for prop in world._ground_props.get(Vector2i(x,y),[]):
					var index: int=int(prop.resource)
					if index<0 or bool(world.resources[index].mined): continue
					var local: Vector2=(at-Vector2(prop.center))/(Vector2(prop.radii)+Vector2.ONE*radius)
					if local.length_squared()>=1.0: continue
					var cell: Vector2i=world.resources[index].cell
					if not world._is_floor(cell): continue
					if RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(cell))):
						return {"cell":cell,"node":index}
	return {}

func _bore_direction() -> Vector2:
	var intent: Vector2=Vector2(world.player.external_movement)+Input.get_vector("move_left","move_right","move_up","move_down")
	if intent.length_squared()>0.0025:
		var requested: Vector2=intent.normalized()
		if not bore_heading.is_zero_approx() and requested.dot(bore_heading)<0.95: detour.clear()
		bore_heading=requested
	elif bore_heading.is_zero_approx(): bore_heading=world.player.facing_vector.normalized()
	if bore_heading.is_zero_approx(): bore_heading=Vector2.RIGHT
	var origin: Vector2=world.player.global_position
	var side: Vector2=Vector2(-bore_heading.y,bore_heading.x)
	var radii: Vector2=Vector2(70,27)+Vector2.ONE*(world.PLAYER_RADIUS+14.0)
	if detour.is_empty():
		var best: float=INF
		for site in world.discovery_sites:
			var center: Vector2=Vector2(site.position)+Vector2(0,24)
			var offset: Vector2=center-origin
			var forward: float=offset.dot(bore_heading)
			if forward<0.0 or forward>150.0: continue
			# Intersect the intended travel line with the inflated elliptical base.
			var ray: Vector2=bore_heading/radii
			var relative: Vector2=(origin-center)/radii
			var t: float=maxf(0.0,-relative.dot(ray)/ray.length_squared())
			if (relative+ray*t).length_squared()>=1.0 or forward>=best: continue
			best=forward
			var sign_side: float=1.0 if (origin-center).dot(side)>=0.0 else -1.0
			var extent: float=sqrt(pow(radii.x*side.x,2)+pow(radii.y*side.y,2))
			var waypoint: Vector2=center+side*sign_side*extent
			# Stay away from permanent boundaries when either side is possible.
			if not world._cell_diggable(world._world_to_cell(waypoint)):
				waypoint=center-side*sign_side*extent
			detour={"center":center,"waypoint":waypoint,"passing":false}
	if not detour.is_empty():
		var offset: Vector2=origin-Vector2(detour.center)
		var ahead_extent: float=sqrt(pow(radii.x*bore_heading.x,2)+pow(radii.y*bore_heading.y,2))
		if offset.dot(bore_heading)>ahead_extent:
			detour.clear()
		else:
			var toward: Vector2=Vector2(detour.waypoint)-origin
			if toward.length()<10.0: detour.passing=true
			if not bool(detour.passing):
				# First clear the near side; a direct diagonal to the flank cuts
				# through the ellipse when approaching its broad face.
				var lateral: float=toward.dot(side)
				var forward: float=toward.dot(bore_heading)
				if absf(lateral)>10.0: return (side*signf(lateral)+bore_heading*0.15).normalized()
				if forward>8.0: return bore_heading
				detour.passing=true
	return bore_heading

func _tick_bore(delta: float) -> bool:
	var direction: Vector2=_bore_direction()
	world.player.set_facing(direction)
	world.player.drill_motion_override=true
	world.player.drill_motion=direction
	var target: Dictionary=_bore_target(world.player.global_position,direction)
	if target.has("blocked"):
		world.player.drill_motion=Vector2.ZERO
		target={}
	var key: String=str(target.get("cell",""))+":"+str(target.get("node",-1)) if not target.is_empty() else ""
	if key!=target_key:
		target_key=key
		elapsed=0.0
		initial_hp=int(world.resources[int(target.node)].hp) if int(target.get("node",-1))>=0 else 1
	if target.is_empty():
		world.player.set_mining_visual(false,0.0)
		return true
	elapsed+=minf(delta,0.05)
	var period: float=0.20 if int(target.node)>=0 else 0.16
	if elapsed>=period:
		elapsed=0.0
		if int(target.node)>=0: world._strike_resource(int(target.node),initial_hp,false)
		else: world._break_diggable_cell(Vector2i(target.cell))
		world._update_buried_visibility()
		AudioDirector.play_mining("deepstone",true,false)
		impacts+=1
		target_key=""
	world.player.set_mining_visual(true,fmod(elapsed/period,1.0),0.0,0.5)
	return true

func _draw() -> void:
	if not world.active or int(RunState.drill_level)<=0: return
	if Goals.active_mod()=="laser" or dev_override=="laser":
		var direction: Vector2=world.player.animation_bearing.normalized()
		var at: Vector2=world.player.global_position+Vector2(0,-48)+direction*22.0
		draw_set_transform(at,direction.angle())
		draw_texture_rect(emitter,Rect2(-21,-14,42,24),false)
		draw_set_transform(Vector2.ZERO)
	if not firing: return
	# Bounded unshaded beam, no dynamic lights or wide-area gameplay damage.
	draw_line(beam_start,beam_end,Color(0.08,0.65,1.0,0.16),15.0,true)
	draw_line(beam_start,beam_end,Color(0.2,0.85,1.0,0.65),6.0,true)
	draw_line(beam_start,beam_end,Color(0.88,1.0,1.0),2.0,true)
	draw_circle(beam_end,5.0+sin(elapsed*60.0)*1.5,Color(1.0,0.72,0.25,0.8))

func snapshot() -> Dictionary:
	return {"mode":selected(),"firing":firing,"target":target_key,"elapsed":elapsed,"impacts":impacts,"range":REACH,"beam_start":[beam_start.x,beam_start.y],"beam_end":[beam_end.x,beam_end.y]}
