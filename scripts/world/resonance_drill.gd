extends Node2D
## Earned treasury mod with a separate DEV test override. Charge comes only from actual hero mining hits.
const CHARGE_SECONDS: float = 4.0
const ROWS: int = 12
const HALF_WIDTH: int = 2
const ROW_TIME: float = 0.07
const TAIL: float = 0.5
var world: Node2D
var dev_override: bool = false
var enabled: bool = false
var charge: float = 0.0
var age: float = -1.0
var row: int = 0
var origin: Vector2i
var direction: Vector2i = Vector2i.RIGHT
var rings: Array[Dictionary] = []
var debris: Array[Dictionary] = []
var ring_texture: Texture2D
var stone_texture: Texture2D
var bursts: int = 0
var excavated: int = 0
var clock: float = 0.0
var blocked: bool = false
var exposed_before_burst: Dictionary = {}
var visual_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func setup(owner_world: Node2D) -> void:
	world = owner_world
	z_index = 1900
	visual_rng.seed = 93141
	material = CanvasItemMaterial.new()
	material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED

func set_enabled(value: bool) -> void:
	enabled = value
	if enabled and ring_texture == null:
		var image: Image = Image.load_from_file("res://assets/fx/resonance-ring-v1.png")
		ring_texture = ImageTexture.create_from_image(image)
		stone_texture = load("res://assets/drops/stone-drop.png")
	reset()

func reset() -> void:
	exposed_before_burst.clear()
	charge = 0.0
	age = -1.0
	rings.clear()
	debris.clear()
	queue_redraw()

func on_hit(period: float) -> void:
	if not enabled or age >= 0.0 or int(RunState.drill_level) <= 0: return
	if charge < 1.0:
		charge = minf(1.0, charge + period / CHARGE_SECONDS)
		return
	var facing: Vector2 = world.player.facing_vector
	direction = Vector2i(int(signf(facing.x)),0) if absf(facing.x)>absf(facing.y) else Vector2i(0,int(signf(facing.y)))
	if direction == Vector2i.ZERO: return
	origin = world._world_to_cell(world.player.global_position)
	exposed_before_burst = world._exposed_node_ids()
	age = 0.0
	row = 0
	blocked = false
	charge = 0.0
	bursts += 1
	world.message_changed.emit("RESONANCE · BREAK THROUGH")

func tick(delta: float) -> void:
	if not enabled: return
	if not world.active or not world.player.control_enabled: return
	if int(RunState.drill_level)<=0:
		reset()
		return
	clock += delta
	for list in [rings,debris]:
		for i in range(list.size()-1,-1,-1):
			list[i].age = float(list[i].age)+delta
			if float(list[i].age)>=float(list[i].life): list.remove_at(i)
	if age >= 0.0:
		age += delta
		# At most one five-cell row per frame: no catch-up burst after stalls.
		if not blocked and row < ROWS and age >= row * ROW_TIME:
			_advance_row()
		if (blocked or row>=ROWS) and rings.is_empty(): age = -1.0
	queue_redraw()

func _advance_row() -> void:
	row += 1
	var center: Vector2i = origin + direction * row
	if not world._cell_diggable(center) or not RunState._endless_band_in_reach(world.depth_at_position(world._cell_center(center))):
		blocked = true
		return
	var side: Vector2i = Vector2i(-direction.y,direction.x)
	var count: int = 0
	world._wave_active = true
	world._wave_rewards.clear()
	RunState.begin_state_batch()
	for offset in range(-HALF_WIDTH,HALF_WIDTH+1):
		var cell: Vector2i = center+side*offset
		if world._break_diggable_cell(cell):
			count += 1
			_spawn_debris(world._cell_center(cell))
	# Only ore exposed before this whole burst can be mined.
	# Keep newly uncovered nodes intact through all rows, even if the wave stalls.
	for i in world.resources.size():
		var resource: Dictionary = world.resources[i]
		var offset: Vector2i = Vector2i(resource.cell)-center
		if (offset.x*direction.x+offset.y*direction.y)==0 and absi((offset.x*side.x+offset.y*side.y))<=HALF_WIDTH and world._is_floor(Vector2i(resource.cell)) and not bool(resource.mined) and exposed_before_burst.has(String(resource.id)):
			world._strike_resource(i,int(resource.hp),false)
	RunState.end_state_batch()
	world._wave_active = false
	for key in world._wave_rewards:
		world.resource_mined.emit(String(key).get_slice(":",0),int(world._wave_rewards[key]))
	world._wave_rewards.clear()
	excavated += count
	rings.append({"position":world._cell_center(center),"age":0.0,"life":TAIL,"direction":Vector2(direction)})
	if count>0 and row%3==1: AudioDirector.play_mining("deepstone",true,false)
	world._update_buried_visibility()

func _spawn_debris(point: Vector2) -> void:
	for i in 2:
		if debris.size()>=64: return
		var spread: Vector2 = Vector2(direction).orthogonal()*visual_rng.randf_range(-130.0,130.0)
		debris.append({"position":point,"velocity":Vector2(direction)*visual_rng.randf_range(30.0,110.0)+spread,"age":0.0,"life":visual_rng.randf_range(0.35,0.65),"size":visual_rng.randf_range(14.0,30.0),"spin":visual_rng.randf_range(-4.0,4.0)})

func rebase(shift: Vector2) -> void:
	origin += Vector2i(0,roundi(shift.y/world.TILE_SIZE))
	for list in [rings,debris]:
		for item in list: item.position = Vector2(item.position)+shift

func _draw_ring(point: Vector2, facing: Vector2, size: float, alpha: float) -> void:
	draw_set_transform(point,facing.angle(),Vector2(0.40,0.88))
	draw_texture_rect(ring_texture,Rect2(Vector2.ONE*(-size*0.5),Vector2.ONE*size),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if not enabled or ring_texture == null: return
	if charge>0.0 and int(RunState.drill_level)>0:
		var facing: Vector2 = world.player.facing_vector
		var p: Vector2 = world.player.global_position + facing*30.0 + Vector2(0,-50)
		for i in 3:
			_draw_ring(p+facing*i*12.0,facing,24.0+charge*32.0,charge*(0.65+0.15*sin(clock*12.0+i)))
	for ring in rings:
		var t: float = float(ring.age)/float(ring.life)
		_draw_ring(Vector2(ring.position)+Vector2(0,-22),Vector2(ring.direction),world.TILE_SIZE*5.5*(1.0+t*0.10),pow(1.0-t,1.25)*0.9)
	for chunk in debris:
		var t: float = float(chunk.age)/float(chunk.life)
		var p: Vector2 = Vector2(chunk.position)+Vector2(chunk.velocity)*float(chunk.age)+Vector2(0,-sin(t*PI)*48.0)
		var size: float = float(chunk.size)
		draw_set_transform(p,float(chunk.spin)*t)
		draw_texture_rect(stone_texture,Rect2(Vector2.ONE*(-size*0.5),Vector2.ONE*size),false,Color(0.8,0.94,1.0,1.0-t*t))
	draw_set_transform(Vector2.ZERO)

func snapshot() -> Dictionary:
	return {"enabled":enabled,"charge":charge,"active":age>=0.0,"age":age,"row":row,"bursts":bursts,"excavated":excavated,"rings":rings.size(),"debris":debris.size(),"blocked":blocked,"direction":[direction.x,direction.y]}
