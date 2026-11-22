extends RefCounted

const SPRITE := preload("res://assets/surface/painted/mara.png")
const WorldCatalog := preload("res://scripts/world/world_catalog.gd")
const CAMP := Vector2(445, 629)
const MOON := Vector2(1930, 657)
const EMBER := Vector2(3060, 634)
const STAR := Vector2(4180, 635)
const HUB := Vector2(560, 765)
const HEART := Vector2(685, 804)
const APPROACH := Vector2(-31, 48)
const TALK_RADIUS := 58.0
const GOLD := Color("ffd768")
const GRAY := Color("b7b7b7")

var current: Dictionary = {}
var actors: Dictionary = {}
var _last_presentation: Array = []


func install(worlds: Dictionary) -> void:
	for phase in worlds:
		var actor := Node2D.new()
		actor.name = "Mara"
		actor.hide()
		var art := Sprite2D.new()
		art.texture = SPRITE
		art.centered = false
		art.scale = Vector2.ONE * minf(110.0 / SPRITE.get_width(), 143.0 / SPRITE.get_height())
		var size := Vector2(SPRITE.get_size()) * art.scale.x
		art.position = Vector2(-size.x * 0.5, -size.y)
		actor.add_child(art)
		var quest_mark := Label.new()
		var unshaded := CanvasItemMaterial.new()
		unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		quest_mark.material = unshaded
		quest_mark.name = "QuestMark"
		quest_mark.position = Vector2(-35, -184)
		quest_mark.size = Vector2(70, 42)
		quest_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quest_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		quest_mark.add_theme_font_size_override("font_size", 42)
		quest_mark.add_theme_color_override("font_outline_color", Color("211b17"))
		quest_mark.add_theme_constant_override("outline_size", 6)
		actor.add_child(quest_mark)
		worlds[phase].add_child(actor)
		actors[phase] = actor


func refresh() -> void:
	current = _next_quest()
	var phase := String(current.get("phase", ""))
	var presentation := [phase, current.get("position"), marker_text(), marker_color()]
	if presentation == _last_presentation:
		return
	_last_presentation = presentation
	for world_phase in actors:
		var actor: Node2D = actors[world_phase]
		actor.visible = world_phase == phase
		if not actor.visible:
			continue
		actor.position = current.position
		var world := actor.get_parent()
		actor.z_index = world.actor_draw_depth(actor.position) if world.has_method("actor_draw_depth") else 20
		var marker: Label = actor.get_node("QuestMark")
		marker.text = marker_text()
		marker.add_theme_color_override("font_color", marker_color())


func marker_text() -> String:
	if current.get("id") == "first_haul":
		return "!" if RunState.camp_quest == RunState.CampQuest.OFFER else "?"
	return "" if current.is_empty() or accepted() else "!"


func marker_color() -> Color:
	if current.get("id") == "first_haul" and RunState.camp_quest == RunState.CampQuest.ACTIVE:
		return GRAY
	return GOLD


func accepted() -> bool:
	return bool(RunState.mara_quests_seen.get(current.get("id", ""), false))


func approach() -> Vector2:
	var position := Vector2(current.get("position", CAMP))
	return position + (APPROACH if position == CAMP else Vector2(-31, 28))


func _quest(id: String, phase: String, position: Vector2, title: String, dialogue: String, mine: String = "") -> Dictionary:
	return {"id": id, "phase": phase, "position": position, "title": title, "dialogue": dialogue, "mine": mine}


func _next_quest() -> Dictionary:
	if RunState.camp_quest != RunState.CampQuest.COMPLETE:
		if RunState.camp_quest != RunState.CampQuest.OFFER or RunState.pickaxe_level == 1:
			return _quest("first_haul", "surface", CAMP, "First Haul", "")
	if RunState.pickaxe_level < 2:
		return _quest("forge", "surface", CAMP, "A Better Pickaxe", "Sell ore, then buy an Iron Pickaxe at the forge.")
	if RunState.victory:
		return _endless_quest()
	if RunState.final_expedition_begun:
		return _quest("deepheart", "deepheart", HEART, "Wake the Deepheart", "Mine the four seals, then attune the core.")
	if RunState.singularity_secured:
		return _quest("elevator", "hub", HUB, "Restore the Deep Lift", "Bring cores to the lift, power it, and enter Deepheart.")
	# An entrance is taught when it first becomes visible in any mine.
	if not RunState.visited_depths.values().has(true):
		for mine in RunState.discovered_depth_entrances:
			if not bool(RunState.depth_entry_status(mine).get("can_enter", false)):
				continue
			var location: Vector2 = {"mossMine": CAMP, "moonMine": MOON, "emberMine": EMBER, "starMine": STAR}.get(mine, CAMP)
			return _quest("shaft", "surface", location, "The Hidden Descent", "A shaft opened in the mine. Find it and use DESCEND.", String(mine))
	if not RunState.area_unlocked:
		return _quest("moonglass", "surface", CAMP, "Open Moonglass", "Forge the Runed Pickaxe, then bring the gate fee to Moonglass.")
	if not RunState.emberdeep_unlocked:
		return _quest("emberdeep", "surface", MOON, "Open Emberdeep", "Forge the Moonglass Pickaxe to open Emberdeep.")
	if not RunState.fourth_unlocked:
		var required := int(WorldCatalog.ENTRY_GATES.starfall.min_ember_mastery)
		if RunState.pickaxe_level >= 5 and RunState.ember_mastery < required:
			return _quest("mastery", "surface", EMBER, "Ember Mastery", "Mine Sunslag and reforge your Ember Pickaxe to earn Mastery.")
		return _quest("starfall", "surface", EMBER, "Reach Starfall", "The Starfall seal needs the Ember Pickaxe and Mastery.")
	if String(RunState.starforge_variant).is_empty():
		return _quest("starforge", "surface", STAR, "Choose a Starforge Tool", "Bring Astralite and Crownstone to the Starforge.")
	if RunState.hub_tutorial_pending():
		return _quest("hub", "surface", STAR, "Find the Hub", "Take Starfall's lift to your base below.")
	if RunState.drill_level == 0:
		return _quest("drill", "hub", HUB, "Forge Your First Drill", "Mine in Depth 2, then use the Drill Forge.")
	return _quest("singularity", "hub", HUB, "The Singularity Core", "Upgrade your drill for the Singularity Core in Voidstar.")


func _endless_quest() -> Dictionary:
	if RunState.endless_deepest_depth == 0:
		return _quest("the_deep", "hub", HUB, "Enter The Deep", "Take the Hub lift to The Deep. Dig down to find relics.")
	for workshop in RunState.ENDLESS_WORKSHOP_IDS:
		var status := RunState.workshop_status(workshop)
		if bool(status.get("blueprint_unlocked", false)) and not bool(status.get("built", false)):
			return _quest("workshop:" + String(workshop), "hub", HUB, "Build the " + String(status.display_name), "Your relic revealed a workshop. Bring it materials.")
	var first_relic: String = RunState.ENDLESS_RELIC_IDS[0]
	if not bool(RunState.relic_status(first_relic).get("placed", false)):
		return _quest("first_relic", "hub", HUB, "Bring Home a Relic", "Find a relic. Attach the rope and Tunnel Home.")
	return {}
