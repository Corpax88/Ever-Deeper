class_name ProgressionGoal
extends RefCounted

## Presentation only: the transaction owners supply every recipe and price.
## A delivered material still counts after it leaves the player's pouch.
static func decorate(goal: Dictionary) -> Dictionary:
	if goal.is_empty():
		return {}
	var result: = goal.duplicate(true)
	var objective_id: = String(goal.get("objective_id", ""))
	var rows: Array[Dictionary] = []
	if objective_id.begins_with("pickaxe:") or objective_id.begins_with("mastery:"):
		var kind: = "ember_mastery" if objective_id.begins_with("mastery:") else "pickaxe"
		var snapshot: Dictionary = RunState.forge_purchase_snapshot(kind)
		for value in Array(Dictionary(snapshot.get("cost", {})).get("requirements", [])):
			var cost: = Dictionary(value)
			rows.append(_row(String(cost.get("kind", "")), int(cost.get("required", 0)), 0, String(cost.get("kind", "")) == "gold"))
	elif objective_id.begins_with("gate:"):
		var world_id: = String(goal.get("world_id", ""))
		var price: = int(GameData.data.get("GATE_COST", 0)) if world_id == "moonglass" else int(GameData.data.get("EMBER_GATE_COST", 0)) if world_id == "emberdeep" else 0
		if price > 0:
			rows.append(_row("gold", price, 0, true))
	elif objective_id.begins_with("starforge:"):
		var status: Dictionary = RunState.starforge_crafting_status("crusher")
		var recipe: = Dictionary(Dictionary(status.get("variant", {})).get("cost", {}))
		for resource_id in recipe:
			rows.append(_row(String(resource_id), int(recipe[resource_id])))
	elif objective_id.begins_with("drill:"):
		var recipe: Dictionary = RunState.next_drill_recipe()
		for value in Array(recipe.get("requirements", [])):
			var requirement: = Dictionary(value)
			rows.append(_row(String(requirement.get("type", "")), int(requirement.get("amount", 0))))
		if int(recipe.get("gold", 0)) > 0:
			rows.append(_row("gold", int(recipe.gold), 0, true))
	elif objective_id == "endgame:repair_elevator":
		var status: Dictionary = RunState.deep_elevator_status()
		var recipe: = Dictionary(status.get("recipe", {}))
		var delivered: = Dictionary(status.get("deliveries", {}))
		for resource_id in recipe:
			rows.append(_row(String(resource_id), int(recipe[resource_id]), int(delivered.get(resource_id, 0))))
	elif not String(goal.get("workshop_id", "")).is_empty():
		var status: Dictionary = RunState.workshop_status(String(goal.workshop_id))
		if bool(status.get("built", false)):
			var recipe: = Dictionary(status.get("next_upgrade", {}))
			if not recipe.is_empty():
				rows.append(_row(String(recipe.get("resource", "")), int(recipe.get("cost", 0))))
		else:
			rows.append(_row(String(status.get("build_resource", "")), int(status.get("build_cost", 0)), int(status.get("delivered", 0))))
	result["requirements"] = rows
	var ready: = not rows.is_empty()
	for row in rows:
		ready = ready and bool(row.ready)
	result["requirements_ready"] = ready
	result["hud_title"] = _short_title(goal)
	result["hud_action"] = _action(goal)
	return result


static func _row(resource_id: String, required: int, delivered: int = 0, currency: bool = false) -> Dictionary:
	var in_pouch: = int(RunState.gold) if currency else int(RunState.cargo.get(resource_id, 0))
	var rock: = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
	var icon_path: = "res://assets/ui/gold-bars-v1.png" if currency else "res://assets/drops/%s-drop.png" % resource_id
	if not ResourceLoader.exists(icon_path):
		icon_path = String(RunState.RESOURCE_TEXTURE_FALLBACKS.get(resource_id, ""))
	var owned: = maxi(0, in_pouch) + maxi(0, delivered)
	var haul_value: = int(Dictionary(RunState.assay_sale_snapshot()).get("total", 0)) if currency and owned < required else 0
	return {
		"id": "currency:gold" if currency else "resource:%s" % resource_id,
		"resource_id": resource_id,
		"name": "Gold" if currency else String(rock.get("label", resource_id.capitalize())),
		"texture_path": icon_path,
		"owned": owned,
		"pending_sale": haul_value,
		"in_pouch": maxi(0, in_pouch),
		"delivered": maxi(0, delivered),
		"required": maxi(0, required),
		"ready": owned >= required,
		"is_currency": currency,
	}


static func _short_title(goal: Dictionary) -> String:
	var title: = String(goal.get("hud_title", goal.get("title", "")))
	for prefix in ["Forge the ", "Forge a ", "Open the ", "Break the ", "Build the ", "Upgrade the ", "Restore the ", "Awaken the "]:
		if title.begins_with(prefix):
			return title.trim_prefix(prefix)
	return title


static func _action(goal: Dictionary) -> String:
	if goal.has("hud_action"):
		return String(goal.hud_action)
	var kind: = String(goal.get("kind", ""))
	var station: = String(goal.get("station_id", ""))
	var resource: = String(goal.get("resource_id", ""))
	var mine_id: = String(goal.get("mine_id", "mossMine"))
	var area: String = {"mossMine": "Mossvein", "moonMine": "Moonglass", "emberMine": "Emberdeep", "starMine": "Starfall"}.get(mine_id, "Mossvein")
	match kind:
		"station", "assay":
			return "Sell ore · %s" % area if station == "sell" else "Visit the Forge"
		"gate":
			return "Open the passage"
		"mine_resource":
			return "Mine & sell · %s" % area if resource.is_empty() else "Mine · %s" % area
		"depth_resource":
			return "Mine · %s Depth 2" % area
		"drill_forge":
			return "Drill Forge · %s Depth 2" % area
		"starforge":
			return "Choose a pickaxe · Starforge"
		"hub":
			return "Enter the Hub · Starfall"
		"hub_elevator":
			return "Deepheart passage · Hub"
		"deepheart":
			return "Follow the sealed path"
	return String(goal.get("detail", ""))
