extends Node2D
## Visual packets are reservations only; landing is the sole accounting boundary.
const Ledger = preload("res://scripts/state/treasury_state.gd")
const SIZE: Vector2 = Vector2(1440, 960)
const ZONE: Vector2 = Vector2(740, 788)
const EXIT: Vector2 = Vector2(145, 794)
const ENTRY: Vector2 = Vector2(285, 790)
const FLIGHT: float = 1.45
var hub: Node2D
var inside: bool = false
var delivering: bool = false
var armed: bool = true
var particles: Array[Dictionary] = []
var batches: Array[Dictionary] = []
var clock: float = 0.0
var next_launch: float = 0.0
var interval: float = 0.45
var landing_count: int = 0
var cancelled_count: int = 0
var textures: Dictionary = {}
var display_nodes: Array[Node2D] = []
var saved_zoom: Vector2 = Vector2.ONE
var visual_root: Node2D
var particle_canvas: Node2D
var initialized: bool = false
var last_totals: Dictionary = {}
var hidden_hud: Array[Dictionary] = []

func setup(owner_world: Node2D) -> void:
	hub = owner_world
	visible = false
	particle_canvas = Node2D.new()
	particle_canvas.z_index = 1900
	particle_canvas.draw.connect(_draw_particles)
	add_child(particle_canvas)

func texture(path: String) -> Texture2D:
	if textures.has(path): return textures[path]
	var result: Texture2D
	if path.begins_with("res://assets/treasury/"):
		var im: Image = Image.load_from_file(path)
		if im != null: result = ImageTexture.create_from_image(im)
	elif ResourceLoader.exists(path): result = load(path) as Texture2D
	textures[path] = result
	return result

func material(kind: String) -> Texture2D:
	if kind == Ledger.WALLET:
		return texture("res://assets/ui/gold-bars-v1.png") if ResourceLoader.exists("res://assets/ui/gold-bars-v1.png") else texture(RunState._resource_drop_texture_path("gold"))
	return texture(RunState._resource_drop_texture_path(kind))

func bay(index: int) -> Vector2:
	return Vector2(164 + (index % 9) * 139, 218 + (index / 9) * 212)

func enter() -> void:
	if inside or not RunState.victory: return
	inside = true
	RunState.treasury_inside = true
	visible = true
	var main: Node=hub.get_parent()
	for item in [main.premium_hud.progression_goal_panel, main.premium_hud.bag_button, main.premium_hud.bag_count, main.premium_hud.status_panel, main.premium_hud.gold_cluster, main.get_node("CompanionInterface").ui_root]:
		hidden_hud.append({"node":item,"visible":item.visible})
	apply_hud()
	saved_zoom = hub.player.camera.zoom
	_refresh_camera()
	if not initialized: _build_visuals()
	refresh_piles()
	hub.world_lights.visible = false
	hub.lit_floor_chunks.hide()
	hub.lit_draw_sections.hide()
	hub.player.global_position = ENTRY
	hub.player.camera.reset_smoothing()
	hub._on_player_moved(ENTRY)
	hub.queue_redraw()
	RunState.set_location("hub", ENTRY)
	RunState._state_changed()
	hub.message_changed.emit("TREASURY · step onto the brass plate to donate · leaving keeps undelivered cargo")

func leave(move_player: bool = true) -> void:
	stop()
	inside = false
	RunState.treasury_inside = false
	visible = false
	for saved in hidden_hud:
		if is_instance_valid(saved.node): saved.node.visible=bool(saved.visible)
	hidden_hud.clear()
	hub.get_parent().premium_hud._apply_platform_safe_area()
	armed = true
	hub.world_lights.visible = true
	hub.lit_floor_chunks.show()
	hub.lit_draw_sections.show()
	hub.player.camera.zoom = saved_zoom
	if move_player:
		hub.player.global_position = hub.TREASURY_DOOR + Vector2(-95, 0)
		hub.player.camera.reset_smoothing()
		hub._on_player_moved(hub.player.global_position)
		RunState.set_location("hub", hub.player.global_position)
	RunState._state_changed()
	hub.queue_redraw()

func stop() -> void:
	cancelled_count += particles.size()
	particles.clear()
	batches.clear()
	delivering = false
	particle_canvas.queue_redraw()

func _refresh_camera() -> void:
	var vp: Vector2 = get_viewport_rect().size
	var factor: float = minf(vp.x / SIZE.x, vp.y / SIZE.y)
	hub.player.camera.zoom = Vector2.ONE * factor

func start() -> void:
	if not inside or delivering: return
	batches.clear()
	var total: int = 0
	for kind in Ledger.keys():
		var available: int = Ledger.available(kind)
		if available <= 0: continue
		var count: int = mini(8, available)
		var remaining: int = available
		for i in count:
			var amount: int = ceili(float(remaining) / float(count-i))
			batches.append({"kind": kind, "amount": amount})
			remaining -= amount
		total += available
	if batches.is_empty(): return
	# Long celebratory delivery scales with variety; draw cost remains bounded.
	var duration: float = clampf(9.0 + sqrt(float(total)) * 0.04 + batches.size() * 0.06, 10.0, 26.0)
	interval = maxf(0.13, duration / float(batches.size()))
	clock = 0.0
	next_launch = 0.0
	delivering = true
	armed = false
	hub.message_changed.emit("TREASURY · cargo and gold are donated only as they land")

func tick(delta: float) -> void:
	if not inside: return
	_refresh_camera()
	if not hub.active:
		stop()
		return
	# Menus pause the celebration and prohibit landing during blocked controls.
	if not hub.player.control_enabled: return
	var at_zone: bool = hub.player.global_position.distance_to(ZONE) < 85.0
	if not at_zone: armed = true
	if at_zone and armed and not delivering: start()
	if not delivering: return
	clock += maxf(0.0, delta)
	if not batches.is_empty() and clock >= next_launch and particles.size() < 16:
		var packet: Dictionary = batches.pop_front()
		packet["origin"] = hub.player.global_position + Vector2(0,-38)
		packet["target"] = bay(Ledger.keys().find(packet.kind)) + Vector2(0,-17)
		packet["age"] = 0.0
		particles.append(packet)
		next_launch = clock + interval
	var changed: bool = false
	for i in range(particles.size()-1,-1,-1):
		particles[i].age = float(particles[i].age) + maxf(0.0,delta)
		if float(particles[i].age) >= FLIGHT:
			var amount: int = Ledger.land(String(particles[i].kind), int(particles[i].amount))
			if amount > 0:
				landing_count += 1
				changed = true
				AudioDirector.play_pickup(String(particles[i].kind), 1)
			particles.remove_at(i)
	if changed: refresh_piles()
	if batches.is_empty() and particles.is_empty():
		delivering = false
		hub.message_changed.emit("TREASURY · delivery complete")
	particle_canvas.queue_redraw()

func collision(point: Vector2) -> bool:
	if point.x < 112 or point.x > 1328 or point.y < 125 or point.y > 838: return true
	for i in Ledger.keys().size():
		var p: Vector2 = bay(i)
		if Rect2(p+Vector2(-57,-80),Vector2(114,115)).has_point(point): return true
	return false

func safe_position(point: Vector2) -> Vector2:
	return point if not collision(point) else ENTRY

func _sprite(tex: Texture2D, at: Vector2, size: Vector2, parent_node: Node2D) -> Sprite2D:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = tex
	sprite.position = at
	if tex != null: sprite.scale = size / tex.get_size()
	parent_node.add_child(sprite)
	return sprite

func _build_visuals() -> void:
	initialized = true
	visual_root = Node2D.new()
	visual_root.z_index = -1
	visual_root.draw.connect(func(): visual_root.draw_rect(Rect2(Vector2(-3000,-3000),Vector2(7500,7500)),Color("08090e")))
	add_child(visual_root)
	_sprite(texture("res://assets/hub/hub-floor-v2.png"), SIZE * 0.5, SIZE, visual_root)
	var wall: Texture2D = texture("res://assets/voidstar/wall.png")
	for x in [180,540,900,1260]:
		_sprite(wall,Vector2(x,25),Vector2(400,100),visual_root)
		var bottom: Sprite2D = _sprite(wall,Vector2(x,935),Vector2(400,100),visual_root)
		bottom.rotation = PI
	for y in [200,500,790]:
		var left: Sprite2D = _sprite(wall,Vector2(25,y),Vector2(340,100),visual_root)
		left.rotation = -PI/2
		var right: Sprite2D = _sprite(wall,Vector2(1415,y),Vector2(340,100),visual_root)
		right.rotation = PI/2
	_sprite(texture("res://assets/treasury/delivery-plate-v1.png"),ZONE,Vector2(230,176),visual_root)
	_sprite(texture("res://assets/voidstar/depth-portal.png"),EXIT+Vector2(0,-45),Vector2(130,150),visual_root)
	for i in Ledger.keys().size():
		var group: Node2D = Node2D.new()
		group.z_index = 10 + roundi(bay(i).y + 25)
		add_child(group)
		_sprite(texture("res://assets/treasury/alcove-v1.png"),bay(i)+Vector2(0,-42),Vector2(137,137),group)
		var contents: Node2D = Node2D.new()
		group.add_child(contents)
		display_nodes.append(contents)
	queue_redraw()

func refresh_piles() -> void:
	if not initialized: return
	for i in Ledger.keys().size():
		var kind: String = String(Ledger.keys()[i])
		var amount: int = int(RunState.treasury_totals.get(kind,0))
		if last_totals.get(kind,-1) == amount: continue
		last_totals[kind] = amount
		var parent_node: Node2D = display_nodes[i]
		for child in parent_node.get_children():
			parent_node.remove_child(child)
			child.queue_free()
		var level: int = Ledger.stage(amount)
		if level == 0: continue
		var tex: Texture2D = material(kind)
		var count: int = [0,1,3,5,7][level]
		for item in count:
			var offset: Vector2 = Vector2(0,-15)
			if item > 0: offset += Vector2.from_angle(float(item)*2.39996)*sqrt(float(item))*10.0
			var size: float = [0.0,30.0,33.0,38.0,43.0][level]
			_sprite(tex,bay(i)+offset,Vector2.ONE*size,parent_node)
		# At mature stages a larger specimen replaces the loose central piece.
		if level == 4:
			_sprite(specimen(kind),bay(i)+Vector2(0,-46),Vector2(62,74),parent_node)
	queue_redraw()

func _draw() -> void:
	if not inside: return
	var font: Font = ThemeDB.fallback_font
	draw_string(font,Vector2(400,895),"TREASURY   ·   GOLD HELD: %d" % RunState.gold,HORIZONTAL_ALIGNMENT_LEFT,800,24,Color("f5d890"))
	for i in Ledger.keys().size():
		var kind: String = String(Ledger.keys()[i])
		var label: String = "GOLD" if kind == Ledger.WALLET else "GOLD ORE" if kind == "gold" else String(Dictionary(GameData.data.ROCK_TYPES.get(kind,{})).get("label",kind.replace("_"," "))).to_upper()
		var at: Vector2 = bay(i)+Vector2(0,51)
		var width: float = font.get_string_size(label,HORIZONTAL_ALIGNMENT_LEFT,-1,11).x
		draw_string(font,at-Vector2(width*0.5,0),label,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("ead7a0"))
		var amount: int = int(RunState.treasury_totals.get(kind,0))
		if amount > 0:
			var value: String = str(amount) if amount < 1000000 else String.num_scientific(float(amount))
			draw_string(font,at+Vector2(-35,15),value,HORIZONTAL_ALIGNMENT_LEFT,90,12,Color("fff1c8"))
	draw_string(font,ZONE+Vector2(-90,85),"DONATE CARGO + GOLD",HORIZONTAL_ALIGNMENT_LEFT,200,15,Color("efd887"))
	draw_string(font,EXIT+Vector2(-24,48),"HUB",HORIZONTAL_ALIGNMENT_LEFT,70,16,Color("efd887"))

func _draw_particles() -> void:
	for packet in particles:
		var t: float = clampf(float(packet.age)/FLIGHT,0.0,1.0)
		var origin: Vector2 = packet.origin
		var target: Vector2 = packet.target
		var control: Vector2 = origin.lerp(target,0.5)+Vector2(0,-150)
		var at: Vector2 = (1-t)*(1-t)*origin+2*(1-t)*t*control+t*t*target
		var tex: Texture2D = material(String(packet.kind))
		if tex == null: continue
		for mote in 3:
			var offset: Vector2 = Vector2(mote*14,-mote*8)
			particle_canvas.draw_texture_rect(tex,Rect2(at+offset-Vector2.ONE*18,Vector2.ONE*36),false)

func snapshot() -> Dictionary:
	return {"inside":inside,"delivering":delivering,"packets":particles.size(),"remaining_batches":batches.size(),"landings":landing_count,"cancelled":cancelled_count,"totals":RunState.treasury_totals.duplicate(true),"wallet":RunState.gold,"cargo":RunState.cargo.duplicate(true),"bay_count":Ledger.keys().size()}


func specimen(kind: String) -> Texture2D:
	if kind == Ledger.WALLET: return material(kind)
	for world_id in WorldCatalog.MINE_ASSETS:
		var world_assets: Dictionary=WorldCatalog.MINE_ASSETS[world_id]
		for depth_id in world_assets:
			var section: Variant=world_assets[depth_id]
			if section is Dictionary:
				var nodes: Dictionary=section.get("nodes",{})
				if nodes.has(kind): return texture(String(nodes[kind]))
	return material(kind)


func apply_hud() -> void:
	if not inside: return
	for saved in hidden_hud:
		if is_instance_valid(saved.node): saved.node.hide()
	var main: Node=hub.get_parent()
	main.premium_hud.context_button.position=Vector2(20,get_viewport_rect().size.y-190)
