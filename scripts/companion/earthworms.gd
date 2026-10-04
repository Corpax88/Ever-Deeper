extends Node2D
## One small imagegen PNG, animated by crawling motion and body compression.
const ASSET = "res://assets/companion/earthworm-v1.png"
const MAX_WORMS: int = 3
var mole: Node2D
var texture: Texture2D
var region: Rect2
var worms: Array[Sprite2D] = []
var spawn_clock: float = 5.0
var rng := RandomNumberGenerator.new()
var eaten: int = 0
var spawned: int = 0

func _ready() -> void:
	name="Earthworms"
	rng.randomize()
	var picture := Image.new()
	if picture.load_png_from_buffer(FileAccess.get_file_as_bytes(ASSET)) != OK: return
	region=Rect2(picture.get_used_rect())
	texture=ImageTexture.create_from_image(picture)
	spawn_clock=rng.randf_range(4.0,8.0)

func reset_for_new_run() -> void:
	for worm in worms:
		if is_instance_valid(worm):
			remove_child(worm)
			worm.queue_free()
	worms.clear()
	spawn_clock=rng.randf_range(4.0,8.0)
	eaten=0
	spawned=0

func controller() -> Node:
	return get_tree().current_scene.get_node_or_null("CompanionInterface")

func boost_remaining() -> float:
	var ui: Node=controller()
	return float(ui.worm_power_remaining) if ui!=null else 0.0

func tick(delta: float) -> void:
	if texture==null: return
	spawn_clock-=delta
	if spawn_clock<=0.0:
		spawn_clock=rng.randf_range(18.0,32.0)
		if worms.size()<MAX_WORMS and spawn_nearby()==null: spawn_clock=3.0
	for i in range(worms.size()-1,-1,-1):
		var worm: Sprite2D=worms[i]
		if not is_instance_valid(worm):
			worms.remove_at(i)
			continue
		var age: float=float(worm.get_meta("age"))+delta
		worm.set_meta("age",age)
		if age>90.0 or worm.global_position.distance_to(mole.hero.global_position)>800.0:
			worm.queue_free()
			worms.remove_at(i)
			continue
		var direction: Vector2=worm.get_meta("direction")
		var phase: float=age*7.0+float(worm.get_meta("phase"))
		var step: Vector2=direction*delta*(3.0+2.0*maxf(0.0,sin(phase)))
		if mole._segment_clear(worm.global_position,worm.global_position+step):
			worm.global_position+=step
		else:
			direction=-direction
			worm.set_meta("direction",direction)
		worm.rotation=direction.angle()+sin(phase)*0.07
		worm.scale=Vector2(1.0+sin(phase)*0.13,1.0-sin(phase)*0.10)*(28.0/region.size.x)
		if mole.world.has_method("actor_draw_depth"): worm.z_index=mole.world.actor_draw_depth(worm.position)-1
		if mole.mode=="worm" and mole.eating_worm==worm and mole.action!="eat": mole.destination=worm.global_position

func spawn_nearby() -> Sprite2D:
	for i in 16:
		var p: Vector2=mole.global_position+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(65.0,155.0)
		if mole._blocked(p) or not mole._segment_clear(mole.global_position,p): continue
		return spawn_at(p)
	# Narrow tunnels still need common worms: try safe short offsets too.
	var phase: float=rng.randf()*TAU
	for radius in [40.0,24.0]:
		for i in 16:
			var p: Vector2=mole.global_position+Vector2.from_angle(phase+float(i)*TAU/16.0)*radius
			if not mole._blocked(p) and mole._segment_clear(mole.global_position,p): return spawn_at(p)
	return null

func spawn_at(point: Vector2) -> Sprite2D:
	if texture==null or mole._blocked(point) or worms.size()>=MAX_WORMS: return null
	var worm := Sprite2D.new()
	worm.texture=texture
	worm.region_enabled=true
	worm.region_rect=region
	worm.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	worm.scale=Vector2.ONE*(28.0/region.size.x)
	worm.set_meta("age",0.0)
	worm.set_meta("direction",Vector2.from_angle(rng.randf()*TAU))
	worm.set_meta("phase",rng.randf()*TAU)
	add_child(worm)
	worm.global_position=point
	worm.z_index=8
	worms.append(worm)
	spawned+=1
	return worm

func nearest(point: Vector2) -> Node2D:
	var best: Node2D=null
	var distance: float=180.0
	for worm in worms:
		if not is_instance_valid(worm) or float(worm.get_meta("age"))<2.5: continue
		var d: float=point.distance_to(worm.global_position)
		if d<distance and mole._segment_clear(point,worm.global_position):
			best=worm
			distance=d
	return best

func eat(worm: Node2D) -> void:
	if not worms.has(worm) or mole.global_position.distance_to(worm.global_position)>20.0: return
	var ui: Node=controller()
	if ui==null: return
	ui.worm_power_remaining=20.0
	eaten+=1
	worms.erase(worm)
	worm.queue_free()

func rebase(offset: Vector2) -> void:
	for worm in worms:
		if is_instance_valid(worm): worm.global_position+=offset

func snapshot() -> Dictionary:
	var positions: Array=[]
	for worm in worms:
		if is_instance_valid(worm): positions.append([worm.global_position.x,worm.global_position.y,float(worm.get_meta("age")),worm.scale.x,worm.rotation])
	return {"count":worms.size(),"spawned":spawned,"eaten":eaten,"boost":boost_remaining(),"spawn_clock":spawn_clock,"positions":positions,"width":28.0}
