extends RefCounted
const Ledger = preload("res://scripts/state/treasury_state.gd")
const Stack = preload("res://scripts/world/treasury_stack.gd")
const Seams = preload("res://scripts/state/treasury_seams.gd")

const MODS: Dictionary = {"wallet_gold":"resonance", "burrowsteel":"bore_rush", "prismite":"laser", "rootiron":"twin_auger", "echo_crystal":"chainbreaker", "phasecrystal":"ricochet", "deep_alloy":"corebreaker", "singularity":"vortex"}
const NAMES: Dictionary = {"resonance":"Resonance", "bore_rush":"Bore Rush", "laser":"Laser", "twin_auger":"Twin Auger", "chainbreaker":"Chainbreaker", "ricochet":"Ricochet", "corebreaker":"Corebreaker", "vortex":"Vortex"}

static func clean(raw: Variant, totals: Dictionary = {}) -> Dictionary:
	var result: Dictionary = {"pinned":"", "laser_mode":false}
	if not raw is Dictionary: raw = {}
	if raw.get("pinned", "") is String and raw.get("pinned", "") in Ledger.keys(): result.pinned = raw.pinned
	var active_found: bool = false
	for id in NAMES:
		result[id+"_claimed"] = raw.get(id+"_claimed",false) is bool and raw.get(id+"_claimed",false)
		result[id+"_enabled"] = not active_found and result[id+"_claimed"] and raw.get(id+"_enabled",false) is bool and raw.get(id+"_enabled",false)
		active_found = active_found or result[id+"_enabled"]
	result.laser_mode = result.laser_enabled and raw.get("laser_mode",false) is bool and raw.get("laser_mode",false)
	var pinned_mod: String = mod_id(String(result.pinned))
	if not pinned_mod.is_empty() and bool(result.get(pinned_mod+"_claimed",false)):
		result.pinned = ""
	if completed_collection(String(result.pinned),totals): result.pinned = ""
	return result

static func completed_collection(kind: String, totals: Dictionary) -> bool:
	return not kind.is_empty() and mod_id(kind).is_empty() and int(totals.get(kind,0)) >= Stack.GOAL

static func retire_completed_collection_pin() -> void:
	if completed_collection(String(RunState.treasury_goals.get("pinned","")),RunState.treasury_totals):
		RunState.treasury_goals.pinned = ""

static func mod_id(kind: String) -> String:
	return String(MODS.get(kind,""))

static func active_mod() -> String:
	for id in NAMES:
		if bool(RunState.treasury_goals.get(id+"_claimed",false)) and bool(RunState.treasury_goals.get(id+"_enabled",false)): return id
	return ""

static func claim(kind: String) -> bool:
	var id: String = mod_id(kind)
	if id.is_empty() or not RunState.victory or int(RunState.treasury_totals.get(kind,0)) < Stack.GOAL or bool(RunState.treasury_goals.get(id+"_claimed",false)): return false
	RunState.treasury_goals[id+"_claimed"] = true
	if String(RunState.treasury_goals.get("pinned","")) == kind:
		RunState.treasury_goals.pinned = ""
	_equip(id)
	RunState.flush_save()
	return true

static func _equip(id: String) -> void:
	for key in NAMES: RunState.treasury_goals[key+"_enabled"] = key==id
	RunState.treasury_goals.laser_mode = id=="laser"
	RunState._state_changed()

static func toggle(kind: String) -> void:
	var id: String = mod_id(kind)
	if id.is_empty() or not bool(RunState.treasury_goals.get(id+"_claimed",false)): return
	_equip("" if active_mod()==id else id)

static func toggle_laser() -> void:
	if active_mod()!="laser": return
	RunState.treasury_goals.laser_mode = not bool(RunState.treasury_goals.get("laser_mode",false))
	RunState._state_changed()

static func label(kind: String) -> String:
	if kind == Ledger.WALLET: return "Gold"
	if kind == "gold": return "Gold ore"
	return String(Dictionary(GameData.data.ROCK_TYPES.get(kind,{})).get("label",kind.replace("_"," ").capitalize()))

static func sources(kind: String) -> String:
	var original: String = _original_sources(kind)
	if _has_rich_vein_goal(kind): return "The Deep · follow the marker; keep descending after changing goals\n" + original
	return original

static func _has_rich_vein_goal(kind: String) -> bool:
	return RunState.victory and Seams.MOD_BY_KIND.has(kind) and not bool(RunState.treasury_goals.get(mod_id(kind)+"_claimed",false))

static func _original_sources(kind: String) -> String:
	if kind == Ledger.WALLET: return "Sell ore at the Hub shop"
	if kind in RunState.ENDLESS_RESOURCE_IDS: return "The Deep · buried veins and caches"
	var places: PackedStringArray = []
	for world_id in WorldCatalog.WORLD_ORDER:
		for depth in ["depth1", "depth2"]:
			var section: Dictionary = WorldCatalog.MINE_ASSETS[world_id][depth]
			if Dictionary(section.get("nodes",{})).has(kind):
				places.append(String(world_id).capitalize() + " · Depth " + depth.right(1))
	return " / ".join(places) if not places.is_empty() else "The Deep"

static func pin(kind: String) -> void:
	if kind not in Ledger.keys() or not RunState.victory: return
	if completed_collection(kind,RunState.treasury_totals): return
	var id: String = mod_id(kind)
	if not id.is_empty() and bool(RunState.treasury_goals.get(id+"_claimed",false)): return
	RunState.treasury_goals.pinned = "" if RunState.treasury_goals.get("pinned", "") == kind else kind
	RunState._state_changed()

static func claim_resonance() -> bool:
	return claim(Ledger.WALLET)

static func toggle_resonance() -> void:
	toggle(Ledger.WALLET)

static func collection_source(kind: String) -> Dictionary:
	# Prefer the current mine when the same material occurs in several areas.
	# The catalog describes real deposits; never substitute an unrelated ore.
	var candidates: Array[Dictionary] = []
	for world_id in WorldCatalog.WORLD_ORDER:
		if not RunState.is_world_unlocked(String(world_id)): continue
		for depth in [1, 2]:
			if depth == 2 and not bool(Dictionary(RunState.depth_entry_status(String(WorldCatalog.MINE_BY_WORLD[world_id]))).get("can_enter", false)): continue
			var section: Dictionary = WorldCatalog.MINE_ASSETS[world_id]["depth%d" % depth]
			if Dictionary(section.get("nodes", {})).has(kind):
				candidates.append({"mine_id":String(WorldCatalog.MINE_BY_WORLD[world_id]), "depth":depth, "area":String(world_id).capitalize(), "resource_id":kind})
	for candidate in candidates:
		if String(candidate.mine_id) == String(RunState.current_scene) and int(candidate.depth) == int(RunState.current_depth): return candidate
	for candidate in candidates:
		if String(candidate.mine_id) == String(RunState.current_scene): return candidate
	return candidates[0] if not candidates.is_empty() else {}

static func _wallet_mining_source() -> Dictionary:
	# Currency comes from sellable ore, not the zero-value Deep materials.
	# Prefer the richest accessible ordinary deposit; do not spend or grant cargo.
	var best: Dictionary = {}
	var best_value: int = 0
	for world_id in WorldCatalog.WORLD_ORDER:
		if not RunState.is_world_unlocked(String(world_id)): continue
		var section: Dictionary = WorldCatalog.MINE_ASSETS[world_id].depth1
		for resource_id in Dictionary(section.nodes):
			var value: int = int(Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {})).get("value", 0))
			if value <= best_value: continue
			best_value = value
			best = {"mine_id":String(WorldCatalog.MINE_BY_WORLD[world_id]), "depth":1, "area":String(world_id).capitalize(), "resource_id":String(resource_id)}
	return best

static func _route(kind: String, delivered: int, held: int) -> Dictionary:
	if delivered >= Stack.GOAL:
		return {"treasury_route":"claim", "hud_action":"Claim mod · your podium"}
	if delivered + held >= Stack.GOAL:
		return {"treasury_route":"donate", "hud_action":"Donate · Treasury plate"}
	if kind == Ledger.WALLET:
		var sale_value: int = int(Dictionary(RunState.assay_sale_snapshot()).get("total", 0))
		if sale_value > 0 and (String(RunState.current_scene) == "hub" or delivered + held + sale_value >= Stack.GOAL):
			return {"treasury_route":"sell", "hud_action":"Sell ore · Hub shop", "sale_value":sale_value}
		var source: Dictionary = _wallet_mining_source()
		if source.is_empty(): return {"treasury_route":"unavailable", "hud_action":"Find sellable ore"}
		source["treasury_route"] = "mine"
		source["hud_action"] = "Mine & sell · " + String(source.area)
		return source
	if _has_rich_vein_goal(kind) or kind in RunState.ENDLESS_RESOURCE_IDS:
		return {"treasury_route":"endless", "hud_action":"Rich veins · The Deep" if _has_rich_vein_goal(kind) else "Mine · The Deep"}
	var source: Dictionary = collection_source(kind)
	if source.is_empty(): return {"treasury_route":"unavailable", "hud_action":"Find an accessible source · " + label(kind)}
	source["treasury_route"] = "mine"
	source["hud_action"] = "Mine · %s Depth %d" % [String(source.area), int(source.depth)]
	return source

static func hud_goal() -> Dictionary:
	var kind: String = String(RunState.treasury_goals.get("pinned",""))
	if kind not in Ledger.keys() or not RunState.victory: return {}
	if completed_collection(kind,RunState.treasury_totals): return {}
	var id: String = mod_id(kind)
	if not id.is_empty() and bool(RunState.treasury_goals.get(id+"_claimed",false)): return {}
	var delivered: int = mini(Stack.GOAL,int(RunState.treasury_totals.get(kind,0)))
	var held: int = Ledger.available(kind)
	var ready: bool = delivered >= Stack.GOAL
	var route: Dictionary = _route(kind, delivered, held)
	var goal: Dictionary = {"objective_id":"treasury:"+kind,"kind":"treasury_goal", "resource_id":kind,
		"title":String(NAMES.get(mod_id(kind),label(kind)+" collection")), "hud_title":String(NAMES.get(mod_id(kind),label(kind)+" collection")),
		"hud_action":String(route.hud_action),"detail":sources(kind),
		"requirements":[{"id":"treasury:"+kind,"resource_id":kind,"name":label(kind),"owned":delivered,"pending_sale":mini(held,Stack.GOAL-delivered),"required":Stack.GOAL,"ready":ready,
		"texture_path":RunState.GOLD_TEXTURE_PATH if kind==Ledger.WALLET else RunState._resource_drop_texture_path(kind)}]}
	goal["treasury_route"] = String(route.treasury_route)
	goal["route_resource_id"] = String(route.get("resource_id", kind))
	goal["mine_id"] = String(route.get("mine_id", ""))
	goal["depth"] = int(route.get("depth", 1))
	return goal
