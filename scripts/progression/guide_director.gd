class_name GuideDirector
extends RefCounted









var locked_objective_id: = ""
var locked_waypoint_id: = ""
var locked_target_key: = ""
var locked_target_position: = Vector2.ZERO


func reset() -> void :
	locked_objective_id = ""
	locked_waypoint_id = ""
	_clear_target()


func resolve(proposal: Dictionary) -> Dictionary:
	if proposal.is_empty() or String(proposal.get("objective_id", "")).is_empty():
		reset()
		return {}

	var objective_id: = String(proposal.objective_id)
	var waypoint_id: = String(proposal.get("waypoint_id", objective_id))
	if objective_id != locked_objective_id:
		locked_objective_id = objective_id
		locked_waypoint_id = waypoint_id
		_clear_target()
	elif waypoint_id != locked_waypoint_id:
		locked_waypoint_id = waypoint_id
		_clear_target()

	var candidates: = _normalized_candidates(Array(proposal.get("candidates", [])))
	var selected: = _candidate_by_key(candidates, locked_target_key)
	if selected.is_empty():
		_clear_target()
		if not candidates.is_empty():
			selected = Dictionary(candidates[0])
			locked_target_key = String(selected.key)
			locked_target_position = Vector2(selected.position)
	else:


		locked_target_position = Vector2(selected.position)

	var result: = proposal.duplicate(true)
	result["objective_id"] = locked_objective_id
	result["waypoint_id"] = locked_waypoint_id
	result["target_key"] = locked_target_key
	result["target_position"] = locked_target_position
	result.erase("candidates")
	return result


func goal_for_state() -> Dictionary:
	if bool(RunState.victory):
		return _endless_goal()
	if bool(RunState.get("singularity_secured")):
		return _deep_elevator_goal()

	if not bool(RunState.area_unlocked):
		if int(RunState.pickaxe_level) < 3:
			return _pickaxe_goal("mossMine")
		return _gate_goal("moonglass", "mossMine", 120, "Open the Moonglass Gate")

	if not bool(RunState.emberdeep_unlocked):
		if int(RunState.pickaxe_level) < 4:
			return _pickaxe_goal("moonMine")
		return _gate_goal("emberdeep", "moonMine", 360, "Break the Emberdeep Seal")

	if not bool(RunState.fourth_unlocked):
		if int(RunState.pickaxe_level) < 5:
			return _pickaxe_goal("emberMine")
		if int(RunState.ember_mastery) < 5:
			return _mastery_goal()
		return _goal(
			"gate:starfall", "gate", "Open the Starfall Master Seal",
			"Depth Mastery 5 has awakened the seal",
			{"world_id": "starfall", "station_id": "starfallGate"}
		)

	if String(RunState.starforge_variant).is_empty():
		return _starforge_goal()
	if RunState.hub_tutorial_pending():
		return _goal(
			"hub:first_visit", "hub", "Inspect the Underground Hub",
			"The Starfall base lift is awake", {"station_id": "hubEntrance"}
		)

	return _drill_goal()


func _endless_goal() -> Dictionary:
	var descent: = Dictionary(RunState.endless_descent_status())
	var carried: = Dictionary(descent.get("carried_relic", {}))
	var carried_id: = String(carried.get("id", ""))
	if not carried_id.is_empty():
		var relic: = Dictionary(RunState.relic_status(carried_id))
		var relic_name: = String(relic.get("display_name", "Relic"))
		if bool(descent.get("active", false)):
			return _goal(
				"endless:haul:%s" % carried_id, "endless_return",
				"Haul the %s home" % relic_name,
				"Bring it back to the Hub · ascend with the rope attached",
				{"relic_id": carried_id}
			)
		return _goal(
			"endless:place:%s" % carried_id, "relic_place",
			"Place the %s in the Museum" % relic_name,
			"Bring it to the open pedestal and set it in place",
			{"station_id": "relicPedestal", "relic_id": carried_id}
		)

	for workshop_id_value in RunState.ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var status: = Dictionary(RunState.workshop_status(workshop_id))
		if not bool(status.get("blueprint_unlocked", false)) or bool(status.get("built", false)):
			continue
		var resource_id: = String(status.get("build_resource", ""))
		var remaining: = int(status.get("remaining", 200))
		var carried_amount: = int(RunState.cargo.get(resource_id, 0))
		var workshop_name: = String(status.get("display_name", workshop_id.capitalize()))
		if bool(status.get("ready_to_build", false)) or ( not bool(descent.get("active", false)) and carried_amount > 0):
			return _goal(
				"endless:workshop:%s" % workshop_id, "workshop",
				"Build the %s" % workshop_name,
				"%d / %d %s delivered" % [
					int(status.get("delivered", 0)), int(status.get("build_cost", 200)),
					resource_id.capitalize(),
				],
				{"station_id": workshop_id, "resource_id": resource_id, "required_amount": remaining}
			)
		if bool(descent.get("active", false)) and carried_amount >= remaining:
			return _goal(
				"endless:return:%s" % workshop_id, "endless_return",
				"Bring %s to the %s" % [resource_id.capitalize(), workshop_name],
				"The fixed workshop site is waiting in the Hub",
				{"station_id": workshop_id, "resource_id": resource_id}
			)
		if bool(descent.get("active", false)):
			return _goal(
				"endless:gather:%s" % workshop_id, "endless_resource",
				"Gather %d %s" % [remaining, resource_id.capitalize()],
				"Explore the Endless Descent until the workshop cost is ready",
				{"station_id": workshop_id, "resource_id": resource_id, "required_amount": remaining}
			)
		return _goal(
			"endless:enter:%s" % workshop_id, "endless_enter",
			"Gather %d %s" % [remaining, resource_id.capitalize()],
			"Take the Deep Elevator into the Endless Descent",
			{"station_id": "deepElevator", "resource_id": resource_id, "required_amount": remaining}
		)

	var next_relic_id: = ""
	for relic_id_value in RunState.ENDLESS_RELIC_IDS:
		var relic_id: = String(relic_id_value)
		if not bool(Dictionary(RunState.relic_status(relic_id)).get("placed", false)):
			next_relic_id = relic_id
			break
	if bool(descent.get("active", false)):
		return _goal(
			"endless:explore:%s" % (next_relic_id if not next_relic_id.is_empty() else "deeper"),
			"endless_explore", "Explore one layer deeper",
			"Search every branch for relics, ruins, and unfamiliar materials",
			{"relic_id": next_relic_id}
		)
	return _goal(
		"endless:enter", "endless_enter", "Enter the Endless Descent",
		"Deepheart opened a passage with no final floor",
		{"station_id": "deepElevator", "relic_id": next_relic_id}
	)


func sellable_value() -> int:
	var protected: = Dictionary(RunState.protected_progress_cargo())
	var result: = 0
	for resource_id_value in RunState.cargo:
		var resource_id: = String(resource_id_value)
		var sellable: = maxi(
			0,
			int(RunState.cargo.get(resource_id, 0)) - int(protected.get(resource_id, 0))
		)
		var rock: = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
		result += sellable * int(rock.get("value", 0))
	return result


func purchase_action(cost: int, recipe_ready: bool = true) -> String:
	if recipe_ready and int(RunState.gold) >= cost:
		return "forge"
	var sale_value: = sellable_value()
	if recipe_ready and sale_value > 0 and int(RunState.gold) + sale_value >= cost:
		return "assay"
	return "mine"


func debug_snapshot() -> Dictionary:
	return {
		"objective_id": locked_objective_id,
		"waypoint_id": locked_waypoint_id,
		"target_key": locked_target_key,
		"target_position": locked_target_position,
	}


func _pickaxe_goal(fallback_mine_id: String) -> Dictionary:
	var next: = Dictionary(RunState.next_pickaxe())
	if next.is_empty():
		return _goal("pickaxe:complete", "mine_resource", "Mine. Sell. Grow stronger.", "The road continues deeper", {"mine_id": fallback_mine_id})
	var next_level: = int(RunState.pickaxe_level) + 1
	var final_level: = Array(GameData.data.PICKAXES).size() - 1
	var required_resource: = "emberstone" if next_level == final_level else ""
	var required_amount: = int(GameData.data.EMBER_PICKAXE_ORE_REQUIRED) if not required_resource.is_empty() else 0
	var resources_ready: = (
		next_level != final_level
		or (
			bool(RunState.emberdeep_unlocked)
			and int(RunState.cargo.get(required_resource, 0)) >= required_amount
		)
	)
	var cost: = int(next.cost)
	var action: = purchase_action(cost, resources_ready)
	var details: = {
		"mine_id": fallback_mine_id,
		"cost": cost,
		"resource_id": required_resource,
		"required_amount": required_amount,
	}
	var detail: = "Gather ore until the upgrade is fully affordable"
	if not resources_ready:
		detail = "Mine %d Emberstone for the final pickaxe" % required_amount
		details["resource_id"] = "emberstone"
	elif action == "assay":
		detail = "Your sellable haul closes the gold gap"
	elif action == "forge":
		detail = "%d gold ready · return to the Forge" % cost
	if action == "forge":
		details["station_id"] = "forge"
	elif action == "assay":
		details["station_id"] = "sell"
	return _goal(
		"pickaxe:%d" % next_level,
		"station" if action in ["forge", "assay"] else "mine_resource",
		"Forge the %s" % String(next.name), detail, details
	)


func _gate_goal(world_id: String, mine_id: String, cost: int, title: String) -> Dictionary:
	var action: = purchase_action(cost, true)
	var details: = {"mine_id": mine_id, "cost": cost, "world_id": world_id}
	var kind: = "mine_resource"
	var detail: = "Gather and sell enough ore for the passage"
	if action == "assay":
		kind = "station"
		details["station_id"] = "sell"
		detail = "Your sellable haul closes the gate cost"
	elif action == "forge":
		kind = "gate"
		details["station_id"] = "gate" if world_id == "moonglass" else "emberGate"
		detail = "%d gold ready · open the passage" % cost
	return _goal("gate:%s" % world_id, kind, title, detail, details)


func _mastery_goal() -> Dictionary:
	var next: = Dictionary(RunState.next_ember_mastery())
	if next.is_empty():
		return _goal("mastery:complete", "gate", "Open the Starfall Master Seal", "Depth Mastery complete", {"station_id": "starfallGate", "world_id": "starfall"})
	var rank: = int(next.rank)
	var sunslag_required: = int(next.sunslag)
	var resources_ready: = int(RunState.cargo.get("sunslag", 0)) >= sunslag_required
	var action: = purchase_action(int(next.gold), resources_ready)
	var details: = {
		"mine_id": "emberMine", "resource_id": "sunslag",
		"required_amount": sunslag_required, "cost": int(next.gold),
	}
	var kind: = "mine_resource"
	var detail: = "Mine %d Sunslag for the reforge" % sunslag_required
	if resources_ready and action == "assay":
		kind = "station"
		details["station_id"] = "sell"
		detail = "Sunslag secured · your haul closes the gold gap"
	elif resources_ready and action == "forge":
		kind = "station"
		details["station_id"] = "forge"
		detail = "Reforge materials ready"
	return _goal("mastery:%d" % rank, kind, "Reforge Ember Mastery %d" % rank, detail, details)


func _starforge_goal() -> Dictionary:
	var missing_resource: = ""
	for resource_id in ["astralite", "crownstone"]:
		if int(RunState.cargo.get(resource_id, 0)) < int(GameData.data.STARFORGE_MATERIAL_REQUIRED):
			missing_resource = resource_id
			break
	if missing_resource.is_empty():
		return _goal(
			"starforge:first", "starforge", "Forge a Starforge Pickaxe",
			"Astralite and Crownstone are ready",
			{"station_id": "starforge", "mine_id": "starMine"}
		)
	return _goal(
		"starforge:first", "mine_resource", "Forge a Starforge Pickaxe",
		"Mine 200 Astralite and 200 Crownstone",
		{
			"mine_id": "starMine", "resource_id": missing_resource,
			"required_amount": int(GameData.data.STARFORGE_MATERIAL_REQUIRED),
		}
	)


func _drill_goal() -> Dictionary:
	var status: = Dictionary(RunState.drill_upgrade_status())
	var reason: = String(status.get("reason", ""))
	if reason == "maximum_level" or Dictionary(status.get("recipe", {})).is_empty():
		if bool(RunState.singularity_secured):
			return _goal("endgame:hub", "hub", "Enter the Underground Hub", "The Starfall lift is awake", {"station_id": "hubEntrance"})
		return _goal(
			"endgame:singularity", "depth_resource", "Mine the Singularity Core",
			"The final discovery waits in Voidstar",
			{"mine_id": "starMine", "resource_id": "singularity"}
		)

	var recipe: = Dictionary(status.get("recipe", {}))
	var drill: = Dictionary(recipe.get("drill", RunState.next_drill()))
	var level: = int(recipe.get("level", int(RunState.drill_level) + 1))
	var title: = "Forge the %s" % String(drill.get("name", "next drill"))
	var missing: = Array(status.get("missing", []))
	if not missing.is_empty():
		var requirement: = Dictionary(missing[0])
		return _goal(
			"drill:%d" % level, "depth_resource", title,
			"Mine %s in %s" % [String(requirement.type).capitalize(), _depth_location(String(requirement.scene))],
			{
				"mine_id": String(requirement.scene), "resource_id": String(requirement.type),
				"required_amount": int(requirement.amount),
			}
		)
	var missing_gold: = int(status.get("missing_gold", 0))
	if missing_gold > 0:
		var mine_id: = String(RunState.drill_goal_scene)
		if mine_id.is_empty():
			mine_id = "mossMine"
		if sellable_value() >= missing_gold:
			return _goal(
				"drill:%d" % level, "assay", title,
				"Your sellable haul closes the drill cost",
				{"mine_id": mine_id, "station_id": "sell"}
			)
		return _goal(
			"drill:%d" % level, "depth_resource", title,
			"Mine sellable ore for %d more gold" % missing_gold,
			{"mine_id": mine_id, "resource_id": ""}
		)
	if bool(status.get("ready", false)):
		var forge_scene: = String(RunState.drill_goal_scene)
		if forge_scene.is_empty():
			forge_scene = "mossMine"
		return _goal(
			"drill:%d" % level, "drill_forge", title,
			"Visit the Drill Forge in %s" % _depth_location(forge_scene),
			{"mine_id": forge_scene, "station_id": "forge"}
		)
	return _goal(
		"drill:%d" % level, "depth_resource", title,
		"Continue gathering materials in the hidden depths",
		{"mine_id": "mossMine", "resource_id": ""}
	)


func _deep_elevator_goal() -> Dictionary:
	var status: = Dictionary(RunState.deep_elevator_status())
	if bool(status.get("powered", false)):
		if bool(RunState.get("final_expedition_begun")):
			var seals: = Dictionary(RunState.deepheart_seal_status())
			var missing_seals: = Array(seals.get("missing", []))
			if not missing_seals.is_empty():
				var seal_id: = String(missing_seals[0])
				var mine_by_world: = {
					"mossvein": "mossMine", "moonglass": "moonMine",
					"emberdeep": "emberMine", "starfall": "starMine",
				}
				return _goal(
					"endgame:seal:%s" % seal_id, "deepheart",
					"Open the %s Deepheart Seal" % seal_id.capitalize(),
					"One seal at a time · %d of %d opened" % [int(seals.get("opened", 0)), int(seals.get("total", 4))],
					{"world_id": seal_id, "mine_id": String(mine_by_world[seal_id])}
				)
			return _goal(
				"endgame:core", "hub_elevator", "Attune the Deepheart Core",
				"All four world seals are open", {"station_id": "deepElevator"}
			)
		return _goal(
			"endgame:final_descent", "hub_elevator", "Begin the Final Descent",
			"The repaired elevator is fully powered", {"station_id": "deepElevator"}
		)
	if bool(status.get("repaired", false)):
		return _goal(
			"endgame:power_elevator", "hub_elevator", "Power the Deep Elevator",
			"Install the secured Singularity Core", {"station_id": "deepElevator"}
		)
	var missing: = Dictionary(status.get("missing", {}))
	var resource_to_mine: = {
		"ambercore": "mossMine",
		"lunacore": "moonMine",
		"furnaceheart": "emberMine",
		"singularity": "starMine",
	}
	var selected_resource: = ""
	var carrying_resource: = false
	for resource_id_value in ["ambercore", "lunacore", "furnaceheart", "singularity"]:
		var resource_id: = String(resource_id_value)
		if int(missing.get(resource_id, 0)) <= 0:
			continue
		if selected_resource.is_empty():
			selected_resource = resource_id
		if int(RunState.cargo.get(resource_id, 0)) > 0:
			selected_resource = resource_id
			carrying_resource = true
			break
	if selected_resource.is_empty():
		return _goal(
			"endgame:repair_elevator", "hub_elevator", "Repair the Deep Elevator",
			"All repair materials have been delivered", {"station_id": "deepElevator"}
		)
	var amount: = int(missing.get(selected_resource, 0))
	var mine_id: = String(resource_to_mine[selected_resource])
	if carrying_resource:
		return _goal(
			"endgame:repair_elevator", "hub_elevator", "Repair the Deep Elevator",
			"Deliver %s to the Hub" % selected_resource.capitalize(),
			{
				"station_id": "deepElevator", "mine_id": mine_id,
				"resource_id": selected_resource, "required_amount": amount,
			}
		)
	return _goal(
		"endgame:repair_elevator", "depth_resource", "Repair the Deep Elevator",
		"Mine %d more %s" % [amount, selected_resource.capitalize()],
		{
			"mine_id": mine_id, "resource_id": selected_resource,
			"required_amount": amount,
		}
	)


func _goal(id: String, kind: String, title: String, detail: String, extra: Dictionary = {}) -> Dictionary:
	var result: = {
		"objective_id": id,
		"kind": kind,
		"title": title,
		"detail": detail,
	}
	result.merge(extra, true)
	return result


func _normalized_candidates(raw: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for value in raw:
		if not value is Dictionary:
			continue
		var candidate: = Dictionary(value)
		var key: = String(candidate.get("key", ""))
		var position_value: Variant = candidate.get("position", Vector2.ZERO)
		if key.is_empty() or not position_value is Vector2:
			continue
		result.append({
			"key": key,
			"position": Vector2(position_value),
			"priority": float(candidate.get("priority", 0.0)),
		})
	result.sort_custom( func(left: Dictionary, right: Dictionary) -> bool:
		var left_priority: = float(left.priority)
		var right_priority: = float(right.priority)
		if not is_equal_approx(left_priority, right_priority):
			return left_priority < right_priority
		return String(left.key) < String(right.key)
	)
	return result


func _candidate_by_key(candidates: Array[Dictionary], key: String) -> Dictionary:
	if key.is_empty():
		return {}
	for candidate in candidates:
		if String(candidate.key) == key:
			return candidate
	return {}


func _clear_target() -> void :
	locked_target_key = ""
	locked_target_position = Vector2.ZERO


func _depth_location(mine_id: String) -> String:
	return {"mossMine":"Rootwound Depths · Mossvein Mine, Depth 2", "moonMine":"Prismatic Depths · Moonglass Labyrinth, Depth 2", "emberMine":"Molten Depths · Emberdeep Works, Depth 2", "starMine":"Voidstar Depths · Starfall Hollow, Depth 2"}.get(mine_id,"Depth 2")
