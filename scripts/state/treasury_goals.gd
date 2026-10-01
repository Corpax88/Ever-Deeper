extends RefCounted
const Ledger = preload("res://scripts/state/treasury_state.gd")
const Stack = preload("res://scripts/world/treasury_stack.gd")

static func clean(raw: Variant) -> Dictionary:
	var result: Dictionary = {"pinned":"", "resonance_claimed":false, "resonance_enabled":false}
	if not raw is Dictionary: return result
	if raw.get("pinned", "") is String and raw.get("pinned", "") in Ledger.keys(): result.pinned = raw.pinned
	result.resonance_claimed = raw.get("resonance_claimed", false) is bool and raw.get("resonance_claimed", false)
	result.resonance_enabled = result.resonance_claimed and raw.get("resonance_enabled", false) is bool and raw.get("resonance_enabled", false)
	return result

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
	RunState.treasury_goals.pinned = "" if RunState.treasury_goals.get("pinned", "") == kind else kind
	RunState._state_changed()

static func claim_resonance() -> bool:
	if not RunState.victory or int(RunState.treasury_totals.get(Ledger.WALLET,0)) < Stack.GOAL or bool(RunState.treasury_goals.get("resonance_claimed",false)): return false
	# Claim is additive: existing deposited value and the completed display remain intact.
	RunState.treasury_goals.resonance_claimed = true
	RunState.treasury_goals.resonance_enabled = true
	RunState._state_changed()
	RunState.flush_save()
	return true

static func toggle_resonance() -> void:
	if not bool(RunState.treasury_goals.get("resonance_claimed",false)): return
	RunState.treasury_goals.resonance_enabled = not bool(RunState.treasury_goals.get("resonance_enabled",false))
	RunState._state_changed()

static func hud_goal() -> Dictionary:
	var kind: String = String(RunState.treasury_goals.get("pinned",""))
	if kind not in Ledger.keys() or not RunState.victory: return {}
	var delivered: int = mini(Stack.GOAL,int(RunState.treasury_totals.get(kind,0)))
	var held: int = Ledger.available(kind)
	var ready: bool = delivered >= Stack.GOAL
	return {"objective_id":"treasury:"+kind,"kind":"treasury_goal", "resource_id":kind,
		"title":"Resonance" if kind==Ledger.WALLET else label(kind)+" collection", "hud_title":"Resonance" if kind==Ledger.WALLET else label(kind)+" collection",
		"hud_action":"Return to your podium" if ready else sources(kind),"detail":sources(kind),
		"requirements":[{"id":"treasury:"+kind,"resource_id":kind,"name":label(kind),"owned":delivered,"pending_sale":mini(held,Stack.GOAL-delivered),"required":Stack.GOAL,"ready":ready,
		"texture_path":RunState.GOLD_TEXTURE_PATH if kind==Ledger.WALLET else RunState._resource_drop_texture_path(kind)}]}
