extends RefCounted
# Shared cartography: real terrain, remembered discovery, one cached texture.
const STEPS = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const FLOOR = Color("789491")
const ROCK = Color("55515a")
const BEDROCK = Color("a9a2ad")
var texture: ImageTexture
var image: Image
var bounds := Rect2()
var explored_bounds := Rect2()
var tile := 48.0
var area := ""
var offset := Vector2i.ZERO
var dims := Vector2i.ZERO
var revision := 0
var _world: Node
var _phase: String
var _known: Dictionary = {}
var _seed := -1
var _state_identity: Dictionary = {}

static func clean(raw: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not raw is Dictionary: return result
	for key in raw:
		if not String(key).begins_with("mine:") and not String(key).begins_with("depth:") and key != "endless": continue
		if not raw[key] is Dictionary: continue
		var cells: Dictionary = {}
		for cell in raw[key]:
			var parts: PackedStringArray = String(cell).split(":")
			if parts.size()!=2 or not parts[0].is_valid_int() or not parts[1].is_valid_int(): continue
			if int(parts[0])<0 or int(parts[0])>1024 or int(parts[1])<0 or int(parts[1])>10000000: continue
			cells[String(cell)] = true
			if cells.size()>=100000: break
		result[String(key)] = cells
		if result.size()>=16: break
	return result

func update(world: Node, phase: String, player: Vector2) -> void:
	if phase not in ["mine", "depth", "endless"]:
		area=""
		texture=null
		return
	_world=world
	_phase=phase
	var next_area: String = "endless" if phase=="endless" else phase+":"+String(world.mine_id)
	var next_offset: Vector2i = world.absolute_cell(Vector2i.ZERO) if phase=="endless" else Vector2i.ZERO
	var next_dims: Vector2i = world.GRID_SIZE if phase=="endless" else Vector2i(world.cols,world.rows)
	tile=float(world.TILE_SIZE)
	var rebuild: bool = next_area!=area or next_offset!=offset or next_dims!=dims or _seed!=RunState.world_seed or not is_same(_state_identity,RunState.map_explored)
	area=next_area
	offset=next_offset
	dims=next_dims
	_seed=RunState.world_seed
	_state_identity=RunState.map_explored
	if not RunState.map_explored.has(area): RunState.map_explored[area]={}
	_known=RunState.map_explored[area]
	bounds=Rect2(Vector2.ZERO,Vector2(dims)*tile)
	if rebuild:
		image=Image.create(dims.x,dims.y,false,Image.FORMAT_RGBA8)
		image.fill(Color("101416"))
		explored_bounds=Rect2()
		for key in _known:
			var parts: PackedStringArray=String(key).split(":")
			var cell:=Vector2i(int(parts[0]),int(parts[1]))-offset
			if _inside(cell): _paint(world,phase,cell)
	# Bounded flood follows nearby connected floor; cannot see through rock.
	var origin:=Vector2i((player/tile).floor())
	var queue: Array[Vector2i]=[origin]
	var visited: Dictionary={origin:true}
	var cursor:=0
	var changed:=rebuild
	var newly_seen:=false
	while cursor<queue.size():
		var cell: Vector2i=queue[cursor]
		cursor+=1
		if not _inside(cell): continue
		var absolute: Vector2i=cell+offset
		var key: String="%d:%d" % [absolute.x,absolute.y]
		if not _known.has(key):
			_known[key]=true
			newly_seen=true
		changed=_paint(world,phase,cell) or changed
		if _kind(world,phase,cell)!=0: continue
		for step in STEPS:
			var neighbor: Vector2i=cell+step
			if not visited.has(neighbor) and Vector2(neighbor-origin).length()<=10:
				visited[neighbor]=true
				queue.append(neighbor)
	if changed:
		if texture==null or rebuild: texture=ImageTexture.create_from_image(image)
		else: texture.update(image)
		revision+=1
	if newly_seen: RunState._queue_autosave()

func _inside(cell: Vector2i) -> bool:
	return cell.x>=0 and cell.y>=0 and cell.x<dims.x and cell.y<dims.y

func _kind(world: Node, phase: String, cell: Vector2i) -> int:
	if phase=="mine":
		var index: int=cell.y*dims.x+cell.x
		if world.concealed_cavern_cells.has(index) and not RunState.is_cavern_discovered(String(world.concealed_cavern_cells[index])): return 1
		if not world.blocks.has(cell): return 0
		return 2 if String(world.blocks[cell].kind)=="bedrock" else 1
	if phase=="depth":
		if world._terrain_is_bedrock(cell): return 2
		return 1 if world._visual_is_solid(cell) else 0
	if world._is_floor(cell): return 0
	return 1 if world._cell_diggable(cell) else 2

func _paint(world: Node, phase: String, cell: Vector2i) -> bool:
	var color: Color=[FLOOR,ROCK,BEDROCK][_kind(world,phase,cell)]
	var rect:=Rect2(Vector2(cell)*tile,Vector2.ONE*tile)
	explored_bounds=explored_bounds.merge(rect) if explored_bounds.has_area() else rect
	if image.get_pixelv(cell)==color: return false
	image.set_pixelv(cell,color)
	return true

func discovered(position: Vector2) -> bool:
	if texture==null: return true
	var cell:=Vector2i((position/tile).floor())+offset
	return _known.has("%d:%d" % [cell.x,cell.y])

func refresh_known() -> void:
	if texture==null or not is_instance_valid(_world): return
	var changed:=false
	for key in _known:
		var parts: PackedStringArray=String(key).split(":")
		var cell:=Vector2i(int(parts[0]),int(parts[1]))-offset
		if _inside(cell): changed=_paint(_world,_phase,cell) or changed
	if changed:
		texture.update(image)
		revision+=1
