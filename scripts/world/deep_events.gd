extends Node2D
## Rare discoveries advance only on newly claimed rock; reload cannot reroll them.
const KINDS: Array[String] = ["ancient_core", "crystal_bloom", "unstable_seam"]
const LIFE: float = 28.0
const RADIUS: float = 420.0
var world: Node2D
var save_clock: float = 0.0
var visual_clock: float = 0.0
var sprite_root: Node2D
var visual_key: String = ""
var emit_clock: float = 0.0

static func clean(raw: Variant) -> Dictionary:
	var source: Dictionary = raw if raw is Dictionary else {}
	var result: Dictionary = {"mined":0,"next":96,"serial":0,"kind":"","remaining":0.0,"x":0,"y":0}
	for key in ["mined","next","serial","x","y"]:
		if source.get(key) is int: result[key] = clampi(int(source[key]),0,2000000000)
	result.next = maxi(int(result.next),1)
	if String(source.get("kind","")) in KINDS:
		result.kind = String(source.kind)
		var remaining: Variant = source.get("remaining",0.0)
		if (remaining is float or remaining is int) and is_finite(float(remaining)):
			result.remaining = clampf(float(remaining),0.0,LIFE)
	return result

func setup(owner_world: Node2D) -> void:
	world = owner_world
	z_index = 1800
	sprite_root = Node2D.new()
	add_child(sprite_root)

func state() -> Dictionary:
	if RunState.deep_events.is_empty(): RunState.deep_events = clean({})
	return RunState.deep_events

func active_here(point: Vector2) -> bool:
	var s: Dictionary = state()
	if String(s.kind).is_empty() or float(s.remaining) <= 0.0: return false
	return point.distance_to(center()) < RADIUS

func center() -> Vector2:
	var s: Dictionary = state()
	var local: Vector2i = Vector2i(int(s.x),int(s.y)) - Vector2i(0,(world.window_start_depth-1)*world.DeepLayout.CHUNK_ROWS)
	return world._cell_center(local)

func on_rock(cell: Vector2i) -> void:
	var s: Dictionary = state()
	s.mined = int(s.mined)+1
	# Active-event mining must not spend the gap before the next discovery.
	if float(s.remaining) > 0.0:
		s.next = maxi(int(s.next)+1,int(s.mined)+1)
		return
	if int(s.mined)<int(s.next): return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = int(RunState.world_seed) ^ (int(s.serial)+1)*73471
	s.kind = KINDS[rng.randi_range(0,KINDS.size()-1)]
	s.serial = int(s.serial)+1
	s.next = int(s.mined)+rng.randi_range(140,260)
	s.remaining = LIFE
	var facing: Vector2 = world.player.facing_vector
	var advance: Vector2i = Vector2i(roundi(facing.x),roundi(facing.y))*3
	var absolute: Vector2i = world.absolute_cell(cell+advance)
	s.x = absolute.x
	s.y = absolute.y
	RunState._queue_autosave()
	world.message_changed.emit({"ancient_core":"ANCIENT CORE · a rich alloy vein awakens", "crystal_bloom":"CRYSTAL BLOOM · crystals surge through the stone", "unstable_seam":"UNSTABLE SEAM · the mountain yields to your drill"}[s.kind])
	_refresh_visuals()

func reward(cell: Vector2i, original: Dictionary) -> Dictionary:
	if not active_here(world._cell_center(cell)): return original
	var s: Dictionary = state()
	var result: Dictionary = original.duplicate(true)
	match String(s.kind):
		"ancient_core":
			result.kind = "deep_alloy"
			result.amount = maxi(3,int(original.amount)*3)
		"crystal_bloom":
			result.kind = "lumenstone" if (cell.x+world.absolute_cell(cell).y)%2==0 else "echo_crystal"
			result.amount = maxi(4,int(original.amount)*4)
	return result

func speed() -> float:
	if not active_here(world.player.global_position): return 1.0
	return 2.0 if String(state().kind)=="unstable_seam" else 1.25

func tick(delta: float) -> void:
	if not world.active:
		visible = false
		return
	visible = true
	var s: Dictionary = state()
	if float(s.remaining)<=0.0:
		if not visual_key.is_empty(): _refresh_visuals()
		return
	# Menus pause events along with mining; no penalty for reading skills.
	if not world.player.control_enabled: return
	s.remaining = maxf(0.0,float(s.remaining)-maxf(0.0,delta))
	visual_clock += delta
	save_clock += delta
	if save_clock>=1.0:
		save_clock=0.0
		RunState._queue_autosave()
	if float(s.remaining)<=0.0:
		s.kind=""
		world.message_changed.emit("The resonance settles · your discoveries remain")
		RunState._queue_autosave()
	_refresh_visuals()
	# Bounded texture effects; no new shadow lights or terrain-wide rebuild.
	var c: Vector2 = center()
	for i in sprite_root.get_child_count():
		var sprite: Sprite2D = sprite_root.get_child(i)
		var offset: Vector2 = sprite.get_meta("offset")
		sprite.position = c+offset
		sprite.visible = not world._is_floor(world._world_to_cell(sprite.position))
		sprite.modulate.a = 0.45+0.2*sin(visual_clock*2.5+i*0.3)

func _refresh_visuals() -> void:
	var s: Dictionary = state()
	var key: String = String(s.kind) if float(s.remaining)>0.0 else ""
	if key==visual_key: return
	visual_key=key
	for child in sprite_root.get_children():
		sprite_root.remove_child(child)
		child.queue_free()
	if key.is_empty(): return
	var path: String = {"ancient_core":"res://assets/endless/relic-forge-heart-v1.png", "crystal_bloom":"res://assets/endless/node-echo-crystal-v1.png", "unstable_seam":"res://assets/endless/node-lumen-shard-v1.png"}[key]
	var tex: Texture2D = load(path)
	for i in 15:
		var sprite: Sprite2D = Sprite2D.new()
		sprite.texture=load("res://assets/endless/node-deep-alloy-v1.png") if key=="ancient_core" and i>0 else tex
		var size: float = 86.0 if i==0 else 43.0+float(i%3)*9.0
		sprite.scale=Vector2.ONE*size/maxf(tex.get_width(),tex.get_height())
		var offset: Vector2 = Vector2.ZERO if i==0 else Vector2.from_angle(i*2.39996)*sqrt(float(i))*83.0
		sprite.set_meta("offset",offset)
		sprite.position=center()+offset
		sprite.visible = not world._is_floor(world._world_to_cell(sprite.position))
		sprite.modulate.a = 0.65
		sprite_root.add_child(sprite)

func snapshot() -> Dictionary:
	return {"state":state().duplicate(true),"speed":speed(),"visual_count":sprite_root.get_child_count(),"active_here":active_here(world.player.global_position)}
