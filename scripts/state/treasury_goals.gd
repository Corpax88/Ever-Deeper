extends RefCounted
const Ledger = preload("res://scripts/state/treasury_state.gd")
const Stack = preload("res://scripts/world/treasury_stack.gd")

const MODS: Dictionary = {"wallet_gold":"resonance", "burrowsteel":"bore_rush", "prismite":"laser", "rootiron":"twin_auger", "echo_crystal":"chainbreaker", "phasecrystal":"ricochet", "deep_alloy":"corebreaker", "singularity":"vortex"}
const NAMES: Dictionary = {"resonance":"Resonance", "bore_rush":"Bore Rush", "laser":"Laser", "twin_auger":"Twin Auger", "chainbreaker":"Chainbreaker", "ricochet":"Ricochet", "corebreaker":"Corebreaker", "vortex":"Vortex"}

static func clean(raw: Variant) -> Dictionary:
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
	return result

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
	var id: String = mod_id(kind)
	if not id.is_empty() and bool(RunState.treasury_goals.get(id+"_claimed",false)): return
	RunState.treasury_goals.pinned = "" if RunState.treasury_goals.get("pinned", "") == kind else kind
	RunState._state_changed()

static func claim_resonance() -> bool:
	return claim(Ledger.WALLET)

static func toggle_resonance() -> void:
	toggle(Ledger.WALLET)

static func hud_goal() -> Dictionary:
	var kind: String = String(RunState.treasury_goals.get("pinned",""))
	if kind not in Ledger.keys() or not RunState.victory: return {}
	var id: String = mod_id(kind)
	if not id.is_empty() and bool(RunState.treasury_goals.get(id+"_claimed",false)): return {}
	var delivered: int = mini(Stack.GOAL,int(RunState.treasury_totals.get(kind,0)))
	var held: int = Ledger.available(kind)
	var ready: bool = delivered >= Stack.GOAL
	return {"objective_id":"treasury:"+kind,"kind":"treasury_goal", "resource_id":kind,
		"title":String(NAMES.get(mod_id(kind),label(kind)+" collection")), "hud_title":String(NAMES.get(mod_id(kind),label(kind)+" collection")),
		"hud_action":"Return to your podium" if ready else sources(kind),"detail":sources(kind),
		"requirements":[{"id":"treasury:"+kind,"resource_id":kind,"name":label(kind),"owned":delivered,"pending_sale":mini(held,Stack.GOAL-delivered),"required":Stack.GOAL,"ready":ready,
		"texture_path":RunState.GOLD_TEXTURE_PATH if kind==Ledger.WALLET else RunState._resource_drop_texture_path(kind)}]}
