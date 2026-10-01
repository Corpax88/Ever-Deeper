extends Node2D
## Visual packets are reservations only; landing is the sole accounting boundary.
const Ledger = preload("res://scripts/state/treasury_state.gd")
const SIZE: Vector2 = Vector2(1880, 1420)
const ZONE: Vector2 = Vector2(940, 710)
const EXIT: Vector2 = Vector2(70, 710)
const ENTRY: Vector2 = Vector2(240, 710)
const FLIGHT: float = 1.45
const LABEL_FONT = preload("res://assets/ui/fonts/EBGaramond.ttf")
var flight_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var label_canvas: Node2D
var hub: Node2D
var inside: bool = false
var delivering: bool = false
var armed: bool = true
var particles: Array[Dictionary] = []
var batches: Array[Dictionary] = []
var clock: float = 0.0
var next_launch: float = 0.0
var interval: float = 0.06
var launch_order: Array[String] = []
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
var upgrades: int = 0
var upgrade_flashes: Dictionary = {}
var active_kind: String = ""
const UPGRADE_FLASH: float = 0.65

func setup(owner_world: Node2D) -> void:
	hub = owner_world
	flight_rng.randomize()
	visible = false
	particle_canvas = Node2D.new()
	particle_canvas.z_index = 1900
	particle_canvas.draw.connect(_draw_particles)
	add_child(particle_canvas)
	label_canvas = Node2D.new()
	label_canvas.z_index = 1901
	var steel_material: CanvasItemMaterial = CanvasItemMaterial.new()
	steel_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	label_canvas.material = steel_material
	label_canvas.draw.connect(_draw_labels)
	add_child(label_canvas)

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
	# One surrounding ring with a gap for the west passage; keep material IDs stable.
	var angle: float = PI + 0.32 + (TAU - 0.64) * float(index) / float(Ledger.keys().size()-1)
	# Use the room's existing vertical margin for captions below each pedestal.
	return ZONE + Vector2(cos(angle)*735.0, sin(angle)*565.0)

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
	hub.player.configure(ENTRY, SIZE, hub.player.movement_speed, hub._resolve_motion)
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
	hub._configure_player(hub.TREASURY_DOOR + Vector2(-130,0) if move_player else hub.player.global_position)
	hub.player.camera.zoom = saved_zoom
	if move_player:
		hub.player.global_position = hub.TREASURY_DOOR + Vector2(-130, 0)
		hub.player.camera.reset_smoothing()
		hub._on_player_moved(hub.player.global_position)
		RunState.set_location("hub", hub.player.global_position)
	RunState._state_changed()
	hub.queue_redraw()

func stop() -> void:
	cancelled_count += particles.size()
	particles.clear()
	batches.clear()
	launch_order.clear()
	active_kind = ""
	upgrade_flashes.clear()
	delivering = false
	particle_canvas.queue_redraw()

func _refresh_camera() -> void:
	# Match normal hub scale; the player camera follows through the larger room.
	# A little overscan at the walls keeps the hero clear of the fixed corner HUD.
	var camera: Camera2D = hub.player.camera
	camera.zoom = saved_zoom
	var margin: Vector2 = get_viewport_rect().size / camera.zoom * 0.25
	camera.limit_left = -ceili(margin.x)
	camera.limit_top = -ceili(margin.y)
	camera.limit_right = ceili(SIZE.x + margin.x)
	camera.limit_bottom = ceili(SIZE.y + margin.y)

func start() -> void:
	if not inside or delivering: return
	batches.clear()
	launch_order.clear()
	# One bounded queue entry per resource, even with millions of items.
	for kind in Ledger.keys():
		var available: int = mini(Ledger.available(kind), Ledger.MAX_TOTAL - int(RunState.treasury_totals.get(kind,0)))
		if available > 0:
			batches.append({"kind":kind,"amount":available,"portion":clampi(ceili(float(available)/8.0),1,250)})
	if batches.is_empty(): return
	interval = 0.06
	active_kind = ""
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
	if hub.player.global_position.x < 110.0 and absf(hub.player.global_position.y-EXIT.y)<65.0:
		leave()
		return
	var at_zone: bool = hub.player.global_position.distance_to(ZONE) < 85.0
	if not at_zone: armed = true
	if at_zone and armed and not delivering: start()
	for kind in upgrade_flashes.keys():
		upgrade_flashes[kind] = maxf(0.0,float(upgrade_flashes[kind])-maxf(0.0,delta))
		if upgrade_flashes[kind] <= 0.0: upgrade_flashes.erase(kind)
	_update_flash_tints()
	if not delivering:
		particle_canvas.queue_redraw()
		return
	clock += maxf(0.0, delta)
	if not batches.is_empty() and clock >= next_launch and particles.size() < 32:
		# Shuffle a full round of remaining materials: mixed directions without starvation.
		if launch_order.is_empty():
			for batch in batches: launch_order.append(String(batch.kind))
			for i in range(launch_order.size()-1,0,-1):
				var j: int = flight_rng.randi_range(0,i)
				var swap: String = launch_order[i]
				launch_order[i] = launch_order[j]
				launch_order[j] = swap
			if launch_order.size()>1 and launch_order.back()==active_kind:
				var swap: String = launch_order[0]
				launch_order[0] = launch_order[-1]
				launch_order[-1] = swap
		var kind: String = launch_order.pop_back()
		active_kind = kind
		var batch_index: int = 0
		while String(batches[batch_index].kind)!=kind: batch_index += 1
		var batch: Dictionary = batches[batch_index]
		var reserved: int = 0
		for pending in particles:
			if String(pending.kind)==kind: reserved += int(pending.amount)
		var projected: int = int(RunState.treasury_totals.get(kind,0)) + reserved
		var to_boundary: int = 1000 - projected % 1000
		var amount: int = mini(mini(int(batch.amount),int(batch.portion)),to_boundary)
		var packet: Dictionary = {"kind":kind,"amount":amount,"milestone":amount==to_boundary,
			"origin":hub.player.global_position+Vector2(0,-38),"target":bay(Ledger.keys().find(kind))+Vector2(0,-17),"age":0.0}
		_shape_flight(packet)
		particles.append(packet)
		batch.amount = int(batch.amount)-amount
		if int(batch.amount) <= 0: batches.remove_at(batch_index)
		# One visible item per launch, with no burst catch-up after a slow frame.
		next_launch = clock + interval
	var changed: bool = false
	var i: int = 0
	while i < particles.size():
		particles[i].age = float(particles[i].age) + maxf(0.0,delta)
		if float(particles[i].age) >= float(particles[i].get("duration",FLIGHT)):
			var kind: String = String(particles[i].kind)
			var before: int = int(RunState.treasury_totals.get(kind,0))
			var amount: int = Ledger.land(kind, int(particles[i].amount))
			if amount > 0:
				landing_count += 1
				changed = true
				if Ledger.stage(before+amount) > maxi(1,Ledger.stage(before)):
					upgrades += 1
					upgrade_flashes[kind] = UPGRADE_FLASH
					AudioDirector.play_economy("upgrade")
				else:
					AudioDirector.play_pickup(kind, 1)
			particles.remove_at(i)
		else:
			i += 1
	if changed:
		refresh_piles()
		_update_flash_tints()
	if batches.is_empty() and particles.is_empty():
		delivering = false
		hub.message_changed.emit("TREASURY · delivery complete")
	particle_canvas.queue_redraw()

func collision(point: Vector2) -> bool:
	if point.x >= 55 and point.x <= 280 and absf(point.y-EXIT.y)<65: return false
	if ((point-ZONE)/Vector2(860,610)).length_squared()>1.0: return true
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
	# The authored hub floor is clipped to the round chamber, never flattened into a backdrop/mockup.
	var floor: Polygon2D = Polygon2D.new()
	floor.texture = texture("res://assets/hub/hub-floor-v2.png")
	var outline: PackedVector2Array = PackedVector2Array()
	var uv: PackedVector2Array = PackedVector2Array()
	for i in 96:
		var angle: float = TAU*float(i)/96.0
		var point: Vector2 = ZONE+Vector2(cos(angle)*905,sin(angle)*655)
		outline.append(point)
		uv.append(point/SIZE*floor.texture.get_size())
	floor.polygon=outline
	floor.uv=uv
	visual_root.add_child(floor)
	_sprite(texture("res://assets/hub/hub-floor-v2.png"),EXIT+Vector2(75,0),Vector2(220,138),visual_root)
	var wall: Texture2D = texture("res://assets/voidstar/wall.png")
	for i in 64:
		var angle: float = TAU*float(i)/64.0
		if absf(angle-PI)<0.15: continue
		var at: Vector2 = ZONE+Vector2(cos(angle)*905,sin(angle)*655)
		var tangent: Vector2 = Vector2(-sin(angle)*905,cos(angle)*655)
		var segment: Sprite2D = _sprite(wall,at,Vector2(tangent.length()*TAU/64.0+38,100),visual_root)
		segment.rotation=tangent.angle()
	_sprite(texture("res://assets/treasury/delivery-plate-v1.png"),ZONE,Vector2(230,176),visual_root)
	for i in Ledger.keys().size():
		var group: Node2D = Node2D.new()
		group.z_index = 10 + roundi(bay(i).y + 25)
		add_child(group)
		_sprite(texture("res://assets/treasury/alcove-v1.png"),bay(i)+Vector2(0,-33.6),Vector2(100,100),group)
		var contents: Node2D = Node2D.new()
		# Uniform art scaling preserves the authored silhouette and makes room
		# for both caption lines between adjacent alcoves along the sides.
		contents.position = bay(i)*0.2
		contents.scale = Vector2.ONE*0.8
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
		var tier: int = level-1
		var growth: float = float(amount % 1000)/1000.0
		if tier == 0:
			var count: int = 1+mini(6,int(growth*7.0))
			var spread: float = lerpf(9.0,17.0,growth)
			var size: float = lerpf(23.0,34.0,growth)
			for item in count:
				var offset: Vector2 = Vector2(0,-14)
				if item > 0: offset += Vector2.from_angle(float(item)*2.39996)*sqrt(float(item))*spread*0.6
				_sprite(material(kind),bay(i)+offset,Vector2.ONE*size,parent_node)
		else:
			var tex: Texture2D = texture("res://assets/treasury/upgrades/%s-%d.png" % [kind,mini(tier,3)])
			# Authored material-specific forms. Later thousands rearrange a bounded hoard.
			var arrangement: int = maxi(0,tier-3) % 6
			var copies: int = 1+arrangement
			for item in copies:
				var offset: Vector2 = Vector2(0,-24)
				if copies > 1:
					offset += Vector2.from_angle(float(item)*TAU/float(copies)-PI*0.5)*Vector2(25,16)
				var extent: float = lerpf(66.0,84.0,growth) if copies == 1 else lerpf(43.0,54.0,growth)
				var sprite: Sprite2D = _sprite(tex,bay(i)+offset,Vector2.ONE*extent,parent_node)
				if tex != null:
					var ratio: float = extent/maxf(tex.get_width(),tex.get_height())
					sprite.scale=Vector2.ONE*ratio
	queue_redraw()
	label_canvas.queue_redraw()

func _update_flash_tints() -> void:
	for i in display_nodes.size():
		var pulse: float = float(upgrade_flashes.get(String(Ledger.keys()[i]),0.0))/UPGRADE_FLASH
		display_nodes[i].modulate = Color(1.0+pulse*1.5,1.0+pulse*1.2,1.0+pulse*0.7)

func _draw() -> void:
	if not inside: return
	var font: Font = ThemeDB.fallback_font
	draw_string(font,ZONE+Vector2(-160,175),"TREASURY   ·   GOLD HELD: %d" % RunState.gold,HORIZONTAL_ALIGNMENT_LEFT,400,20,Color("f5d890"))
	draw_string(font,ZONE+Vector2(-90,85),"DONATE CARGO + GOLD",HORIZONTAL_ALIGNMENT_LEFT,200,15,Color("efd887"))
	draw_string(font,EXIT+Vector2(-24,48),"HUB",HORIZONTAL_ALIGNMENT_LEFT,70,16,Color("efd887"))

func _steel_text(value: String, at: Vector2, size: int) -> void:
	var width: float = LABEL_FONT.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,size).x
	var start: Vector2 = at-Vector2(width*0.5,0)
	label_canvas.draw_string_outline(LABEL_FONT,start,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,Color("07121e"))
	label_canvas.draw_string(LABEL_FONT,start+Vector2(0,1),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("315d86"))
	label_canvas.draw_string(LABEL_FONT,start-Vector2(0,0.7),value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("e0f3ff"))
	label_canvas.draw_string(LABEL_FONT,start,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("a6cce9"))

func _draw_labels() -> void:
	if not inside: return
	for i in Ledger.keys().size():
		var kind: String = String(Ledger.keys()[i])
		var label: String = "GOLD" if kind == Ledger.WALLET else "GOLD ORE" if kind == "gold" else String(Dictionary(GameData.data.ROCK_TYPES.get(kind,{})).get("label",kind.replace("_"," "))).to_upper()
		var at: Vector2 = bay(i)+Vector2(0,24)
		_steel_text(label,at,16)
		var amount: int = int(RunState.treasury_totals.get(kind,0))
		if amount > 0:
			var value: String = str(amount) if amount < 1000000 else String.num_scientific(float(amount))
			_steel_text(value,at+Vector2(0,14),14)

func _shape_flight(packet: Dictionary) -> void:
	# Each launch is a single item, rather than a three-item pulse.
	var travel: float = flight_rng.randf_range(1.12,1.78)
	# Keep same-material landings in order without stopping the outgoing stream.
	for pending in particles:
		if String(pending.kind)==String(packet.kind):
			travel = maxf(travel,float(pending.duration)-float(pending.age)+interval)
	packet["duration"] = travel
	packet["motes"] = [{"travel":travel,"delay":0.0,"bend":Vector2(flight_rng.randf_range(-115,115),-flight_rng.randf_range(65,205)),"offset":Vector2(flight_rng.randf_range(-13,13),flight_rng.randf_range(-8,6)),"ease":flight_rng.randf_range(0.85,1.18),"size":flight_rng.randf_range(27,36)}]

func _draw_particles() -> void:
	for packet in particles:
		var origin: Vector2 = packet.origin
		var target: Vector2 = packet.target
		var tex: Texture2D = material(String(packet.kind))
		if tex == null: continue
		for mote in packet.motes:
			var age: float = float(packet.age)-float(mote.delay)
			if age < 0.0 or age >= float(mote.travel): continue
			var t: float = pow(clampf(age/float(mote.travel),0.0,1.0),float(mote.ease))
			var end: Vector2 = target+Vector2(mote.offset)
			var control: Vector2 = origin.lerp(end,0.5)+Vector2(mote.bend)
			var at: Vector2 = (1-t)*(1-t)*origin+2*(1-t)*t*control+t*t*end
			var extent: float = float(mote.size)
			particle_canvas.draw_texture_rect(tex,Rect2(at-Vector2.ONE*extent*0.5,Vector2.ONE*extent),false)

func snapshot() -> Dictionary:
	return {"active_kind":active_kind,"packet_kinds":particles.map(func(p: Dictionary): return p.kind),"upgrades":upgrades,"flashes":upgrade_flashes.duplicate(),"camera_zoom":[hub.player.camera.zoom.x,hub.player.camera.zoom.y],"camera_center":[hub.player.camera.get_screen_center_position().x,hub.player.camera.get_screen_center_position().y],"zone":[ZONE.x,ZONE.y],"player":[hub.player.global_position.x,hub.player.global_position.y],"circular":true,"walk_through":true,"inside":inside,"delivering":delivering,"packets":particles.size(),"remaining_batches":batches.size(),"landings":landing_count,"cancelled":cancelled_count,"totals":RunState.treasury_totals.duplicate(true),"wallet":RunState.gold,"cargo":RunState.cargo.duplicate(true),"bay_count":Ledger.keys().size()}


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
