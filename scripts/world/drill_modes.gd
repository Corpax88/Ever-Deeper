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
	var direction: Vector2=world._mining_input_direction()
	if direction.is_zero_approx(): direction=world.player.facing_vector
	var step: Vector2i=Vector2i(int(signf(direction.x)),0) if absf(direction.x)>absf(direction.y) else Vector2i(0,int(signf(direction.y)))
	if step==Vector2i.ZERO: step=Vector2i.RIGHT
	world.player.set_facing(Vector2(step))
	var start: Vector2i=world._world_to_cell(world.player.global_position)
	var cell: Vector2i=start
	var node_index: int=-1
	var found: bool=false
	var reach: int=REACH if mode=="laser" else 2
	for distance in range(0,reach+1):
		cell=start+step*distance
		if not world._cell_diggable(cell) or not RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(cell))): break
		if not world._is_floor(cell):
			found=true
			break
		for i in world.resources.size():
			var ore: Dictionary=world.resources[i]
			if Vector2i(ore.cell)==cell and not bool(ore.mined):
				node_index=i
				found=true
				break
		if found: break
	beam_start=world.player.global_position+Vector2(0,-48)+Vector2(step)*28.0
	beam_end=world._cell_center(cell)+Vector2(0,-48)
	firing=mode=="laser"
	world.player.drill_motion_override=mode=="bore_rush"
	var close_node: bool=node_index>=0 and world.player.global_position.distance_to(world._cell_center(cell))<world.TILE_SIZE*1.2
	world.player.drill_motion=Vector2.ZERO if close_node else Vector2(step)
	# Continuous input steers, but automatic movement waits for the nearby node.
	var key: String=(str(cell)+":"+str(node_index)+":"+str(step)) if found else ""
	if key!=target_key:
		target_key=key
		elapsed=0.0
		initial_hp=int(world.resources[node_index].hp) if node_index>=0 else 1
	if not found:
		queue_redraw()
		return true
	elapsed+=minf(delta,0.05)
	var period: float=0.24 if mode=="laser" else 0.16
	if node_index>=0: period=0.28 if mode=="laser" else 0.20
	# Laser never invokes Crusher, and newly exposed ore starts its own timer.
	if elapsed>=period:
		elapsed=0.0
		if node_index>=0: world._strike_resource(node_index,initial_hp,false)
		else: world._break_diggable_cell(cell)
		world._update_buried_visibility()
		AudioDirector.play_mining("deepstone",true,false)
		impacts+=1
		target_key=""
	if mode=="bore_rush": world.player.set_mining_visual(true,fmod(elapsed/period,1.0),0.0,0.5)
	queue_redraw()
	return true

func _draw() -> void:
	if not world.active or int(RunState.drill_level)<=0: return
	if Goals.active_mod()=="laser" or dev_override=="laser":
		var direction: Vector2=world.player.facing_vector.normalized()
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
