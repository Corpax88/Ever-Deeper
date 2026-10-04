class_name MinimapOverlay
extends Control

const REDRAW_INTERVAL: = 0.1
const IPHONE_LANDSCAPE_ASPECT: = 1.95
const GOLD: = Color("e9c86d")
const INK: = Color("07100b")
const MAP_FILL: = Color(0.025, 0.055, 0.04, 0.16)

var cartography: RefCounted
var _display_world := Rect2()
var expanded: bool = false
var markers: Array = []
var _biome_cards: Array[Control] = []
var _phase: = "surface"
var _location_name: = "SURFACE"
var _player_position: = Vector2.ZERO
var _world_rect: = Rect2(Vector2.ZERO, Vector2(4480, 1280))
var _view_rect: = Rect2()
var _objective_position: = Vector2.ZERO
var _has_objective: = false
var _elapsed: = 0.0
var _redraw_elapsed: = REDRAW_INTERVAL
var _map_rect: = Rect2()
var _panel_style: = StyleBoxFlat.new()
var _premium_hud: Control


func _ready() -> void :
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 24
	_panel_style.bg_color = Color(0.012, 0.026, 0.019, 0.2)
	_panel_style.border_color = Color(GOLD, 0.26)
	_panel_style.set_border_width_all(1)
	_panel_style.set_corner_radius_all(24)
	_premium_hud = get_parent().get_node_or_null("PremiumHud") as Control
	if _premium_hud != null and _premium_hud.has_signal("minimap_layout_changed"):
		_premium_hud.minimap_layout_changed.connect(_place_map)
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()


func set_snapshot(
	phase: String,
	location_name: String,
	player_position: Vector2,
	world_rect: Rect2,
	view_rect: Rect2,
	objective_position: Vector2 = Vector2.ZERO,
	has_objective: bool = false
) -> void :
	_phase = phase
	_location_name = location_name.to_upper()
	_player_position = player_position
	_world_rect = world_rect if world_rect.has_area() else Rect2(Vector2.ZERO, Vector2.ONE)
	_view_rect = view_rect
	_objective_position = objective_position
	_has_objective = has_objective
	visible = true
	queue_redraw()


func hide_map() -> void :
	visible = false


func debug_snapshot() -> Dictionary:
	return {
		"visible": visible,
		"phase": _phase,
		"location": _location_name,
		"map_rect": _map_rect,
		"world_rect": _world_rect,
		"player_inside": _world_rect.has_point(_player_position),
		"redraw_hz": 1.0 / REDRAW_INTERVAL,
		"transparent": true,
		"organic_style": true,
		"overlap_fade": not expanded,
		"terrain": cartography != null and cartography.texture != null,
		"terrain_revision": cartography.revision if cartography != null else 0,
		"display_world": _display_world,
	}


func _process(delta: float) -> void :
	if not visible:
		return
	var target_alpha: = 0.24 if not expanded and _player_overlaps_map() else 1.0
	modulate.a = move_toward(modulate.a, target_alpha, maxf(0.0, delta) * 3.6)
	_elapsed += maxf(0.0, delta)
	_redraw_elapsed += maxf(0.0, delta)
	if _redraw_elapsed >= REDRAW_INTERVAL:
		_redraw_elapsed = fmod(_redraw_elapsed, REDRAW_INTERVAL)
		queue_redraw()


func _apply_layout() -> void :
	if _premium_hud != null and _premium_hud.has_method("minimap_layout_rect"):
		var shared_rect: Rect2 = _premium_hud.minimap_layout_rect()
		if shared_rect.has_area():
			_place_map(shared_rect)
			return
	var viewport_size: = get_viewport_rect().size
	if viewport_size.x <= 1.0 or viewport_size.y <= 1.0:
		return
	var iphone: = viewport_size.x / maxf(viewport_size.y, 1.0) >= IPHONE_LANDSCAPE_ASPECT
	var size: = Vector2(246, 136) if iphone else Vector2(184, 106)
	var right: = 116.0 if iphone else 8.0
	var top: = 126.0 if iphone else 68.0
	_map_rect = Rect2(viewport_size.x - right - size.x, top, size.x, size.y)
	queue_redraw()


func _place_map(map_rect: Rect2) -> void:
	_map_rect = map_rect
	queue_redraw()


func _draw() -> void:
	if _map_rect.size.x <= 1.0: return
	draw_style_box(_panel_style, _map_rect)
	var font := ThemeDB.fallback_font
	draw_string(font, _map_rect.position+Vector2(16,32) if expanded else _map_rect.position+Vector2(13,18),_location_name,HORIZONTAL_ALIGNMENT_LEFT,_map_rect.size.x-(32 if expanded else 26),28 if expanded else 13,Color("e9c86d"))
	var content := Rect2(_map_rect.position+Vector2(10,27),_map_rect.size-Vector2(20,37))
	if expanded:
		_draw_biome_cards()
		content=_expanded_content_rect()
		_draw_legend(font)
	draw_rect(content,Color("101416"))
	var has_terrain: bool = cartography!=null and cartography.texture!=null
	_display_world=_world_rect
	if has_terrain:
		if expanded:
			_display_world=cartography.explored_bounds.grow(cartography.tile*2).intersection(_world_rect)
		else:
			var extent: Vector2=Vector2(28,28*content.size.y/content.size.x)*cartography.tile
			_display_world=Rect2(_player_position-extent*0.5,extent)
	var fitted:=_fit_world_rect(content.grow(-2))
	if has_terrain:
		texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		var shown: Rect2=_display_world.intersection(cartography.bounds)
		var destination:=_world_rect_to_map(shown,fitted)
		draw_texture_rect_region(cartography.texture,destination,Rect2(shown.position/cartography.tile,shown.size/cartography.tile))
	else:
		draw_rect(fitted,Color("263433"))
	draw_rect(content,Color("807362"),false,1)
	for marker in markers:
		var position: Vector2=Vector2(marker.position)
		if not _display_world.has_point(position):
			if String(marker.kind)=="entrance": _draw_edge_marker(position,fitted,Color("cbb7ff"))
			continue
		var at:=_world_to_map(position,fitted)
		if String(marker.kind)=="entrance":
			var radius: float=8.0 if expanded else 4.0
			draw_rect(Rect2(at-Vector2.ONE*(radius+1),Vector2.ONE*(radius+1)*2),INK)
			draw_rect(Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),Color("cbb7ff"),false,2)
		else:
			draw_circle(at,6.5 if expanded else 4,INK)
			draw_circle(at,4.5 if expanded else 2.5,Color("63eee0"))
	if _has_objective:
		if _display_world.has_point(_objective_position): _draw_objective(_world_to_map(_objective_position,fitted))
		else: _draw_edge_marker(_objective_position,fitted,Color("a8e3bc"))
	var player:=_world_to_map(_player_position,fitted)
	draw_circle(player,11 if expanded else 7,INK)
	draw_circle(player,8 if expanded else 4.5,GOLD)
	draw_circle(player,2.5 if expanded else 1.5,Color.WHITE)

func _expanded_rail_width() -> float:
	return clampf(_map_rect.size.x*0.20,180.0,252.0)

func _expanded_content_rect() -> Rect2:
	var rail: float=_expanded_rail_width()
	return Rect2(_map_rect.position+Vector2(rail+28,48),(_map_rect.size-Vector2(rail+44,132)).max(Vector2.ONE*30))

func _draw_edge_marker(position: Vector2, fitted: Rect2, color: Color) -> void:
	var direction: Vector2=(position-_display_world.get_center()).normalized()
	var radius: float=9.0 if expanded else 5.0
	var half:=fitted.size*0.5-Vector2.ONE*(radius+2)
	var length: float=minf(half.x/maxf(absf(direction.x),0.001),half.y/maxf(absf(direction.y),0.001))
	var at:=fitted.get_center()+direction*length
	var side:=direction.orthogonal()*(radius-1)
	draw_colored_polygon(PackedVector2Array([at+direction*radius,at-direction*(radius-1)+side,at-direction*(radius-1)-side]),color)

func _draw_legend(font: Font) -> void:
	var labels: Array=["You","Ore","Entrance","Passage","Wall","Bedrock","Objective","Unknown","Off-map"]
	var colors: Array=[GOLD,Color("63eee0"),Color("cbb7ff"),Color("789491"),Color("55515a"),Color("a9a2ad"),Color("a8e3bc"),Color("101416"),Color("cbb7ff")]
	var content: Rect2=_expanded_content_rect()
	var width: float=content.size.x/5
	for i in labels.size():
		var at:=Vector2(content.position.x+(i%5)*width,_map_rect.end.y-48+(i/5)*34)
		if i==0: draw_circle(at+Vector2(8,-8),8,colors[i])
		elif i==1: draw_circle(at+Vector2(8,-8),4.5,colors[i])
		elif i==2: draw_rect(Rect2(at-Vector2(0,16),Vector2(16,16)),colors[i],false,2)
		elif i==6: _draw_objective(at+Vector2(8,-8))
		elif i==8: draw_colored_polygon(PackedVector2Array([at+Vector2(17,-8),at+Vector2(0,-16),at]),colors[i])
		else: draw_rect(Rect2(at-Vector2(0,16),Vector2(16,16)),colors[i])
		draw_string(font,at+Vector2(25,0),labels[i],HORIZONTAL_ALIGNMENT_LEFT,width-28,26,Color("ded7cc"))

func _fit_world_rect(available: Rect2) -> Rect2:
	var world_aspect: = _display_world.size.x / maxf(_display_world.size.y, 1.0)
	var available_aspect: = available.size.x / maxf(available.size.y, 1.0)
	var size: = available.size
	if world_aspect > available_aspect:
		size.y = size.x / world_aspect
	else:
		size.x = size.y * world_aspect
	return Rect2(available.position + (available.size - size) * 0.5, size)


func _draw_ambient_sparks(rect: Rect2) -> void :
	for index in range(7):
		var seed: = float(index) * 2.37
		var position: = Vector2(
			lerpf(rect.position.x + 5.0, rect.end.x - 5.0, fposmod(seed * 0.31, 1.0)),
			lerpf(rect.position.y + 4.0, rect.end.y - 4.0, fposmod(seed * 0.67, 1.0))
		)
		var pulse: = 0.35 + sin(_elapsed * 1.6 + seed) * 0.2
		draw_circle(position, 1.0 + pulse, Color(GOLD, 0.09 + pulse * 0.12))


func _player_overlaps_map() -> bool:
	if not _view_rect.has_area() or _map_rect.size.x <= 1.0:
		return false
	var normalized: = (_player_position - _view_rect.position) / _view_rect.size
	if normalized.x < 0.0 or normalized.x > 1.0 or normalized.y < 0.0 or normalized.y > 1.0:
		return false
	var screen_position: = normalized * get_viewport_rect().size
	return _map_rect.grow(30.0).has_point(screen_position)


func _draw_objective(position: Vector2) -> void :
	var radius: float=9.0 if expanded else 5.0
	var diamond: = PackedVector2Array([
		position + Vector2(0, -radius),
		position + Vector2(radius, 0),
		position + Vector2(0, radius),
		position + Vector2(-radius, 0),
	])
	draw_colored_polygon(diamond, Color(0.58, 0.95, 0.72, 0.9))
	draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color.WHITE, 1.0)


func _world_to_map(world_position: Vector2, map_rect: Rect2) -> Vector2:
	var normalized: = (world_position - _display_world.position) / _display_world.size
	normalized = normalized.clamp(Vector2.ZERO, Vector2.ONE)
	return map_rect.position + normalized * map_rect.size


func _world_rect_to_map(world_rect: Rect2, map_rect: Rect2) -> Rect2:
	var start: = _world_to_map(world_rect.position, map_rect)
	var finish: = _world_to_map(world_rect.end, map_rect)
	return Rect2(start, finish - start)

func _draw_biome_cards() -> void:
	if _biome_cards.is_empty():
		var blur: Shader = Shader.new()
		blur.code = "shader_type canvas_item; uniform float hidden = 0.0; void fragment(){ vec4 c=texture(TEXTURE,UV); if(hidden>0.5){ c=vec4(0.0); for(int x=-2;x<=2;x++){for(int y=-2;y<=2;y++){c+=texture(TEXTURE,clamp(UV+vec2(float(x),float(y))*0.035,vec2(0.0),vec2(1.0)))/25.0;}} float grey=dot(c.rgb,vec3(0.3,0.59,0.11));c.rgb=mix(c.rgb,vec3(grey),0.65)*0.3; } COLOR=c; }"
		for world_id in WorldCatalog.WORLD_ORDER:
			var card: Control = Control.new()
			card.mouse_filter=Control.MOUSE_FILTER_IGNORE
			add_child(card)
			var picture: TextureRect=TextureRect.new()
			picture.name="Picture"
			picture.texture=load(WorldCatalog.SURFACE_LAYOUTS[world_id].entrance_asset)
			picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.mouse_filter=Control.MOUSE_FILTER_IGNORE
			var veil: ShaderMaterial=ShaderMaterial.new()
			veil.shader=blur
			picture.material=veil
			card.add_child(picture)
			var label: Label=Label.new()
			label.name="Name"
			label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
			label.add_theme_font_size_override("font_size",26)
			label.mouse_filter=Control.MOUSE_FILTER_IGNORE
			card.add_child(label)
			_biome_cards.append(card)
	for i in _biome_cards.size():
		var id: String=WorldCatalog.WORLD_ORDER[i]
		var known: bool = id=="mossvein" or RunState.is_world_unlocked(id)
		var card: Control=_biome_cards[i]
		var width: float=_expanded_rail_width()-12.0
		var height: float=(_map_rect.size.y-66.0)/4.0
		card.position=_map_rect.position+Vector2(10,48+i*height)
		card.size=Vector2(width,height-8)
		card.get_node("Picture").size=Vector2(width,height-43)
		card.get_node("Picture").material.set_shader_parameter("hidden",0.0 if known else 1.0)
		var label: Label=card.get_node("Name")
		label.position=Vector2(0,height-43)
		label.size=Vector2(width,35)
		label.text=id.capitalize() if known else "Undiscovered"
