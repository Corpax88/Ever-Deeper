class_name GuideDirector
extends RefCounted

const ProgressionGoalScript: = preload("res://scripts/progression/progression_goal.gd")









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

	var raw_candidates: = Array(proposal.get("candidates", []))
	# A live locked target keeps its priority until it disappears. Avoid rebuilding
	# and sorting every other ore candidate just to select that same target again.
	var selected: = _retained_candidate(raw_candidates, locked_target_key)
	if selected.is_empty():
		var candidates: = _normalized_candidates(raw_candidates)
		selected = _candidate_by_key(candidates, locked_target_key)
		if selected.is_empty() and not candidates.is_empty():
			selected = Dictionary(candidates[0])
	if selected.is_empty():
		_clear_target()
	else:
		locked_target_key = String(selected.key)
		locked_target_position = Vector2(selected.position)

	# The result does not contain candidates; do not deep-copy that discarded list.
	var result: = proposal.duplicate()
	result.erase("candidates")
	result = result.duplicate(true)
	result["objective_id"] = locked_objective_id
	result["waypoint_id"] = locked_waypoint_id
	result["target_key"] = locked_target_key
	result["target_position"] = locked_target_position
	return result


func goal_for_state(discovery: Dictionary = {}) -> Dictionary:
	var goal: Dictionary = _resolve_goal_for_state()
	# Nearby, actually discovered opportunities take precedence while exploring.
	# Carrying a relic, construction and a chosen resource recipe keep priority.
	if String(goal.get("kind", "")) == "endless_explore" and not discovery.is_empty():
		goal = discovery
	return ProgressionGoalScript.decorate(goal)


func _resolve_goal_for_state() -> Dictionary:
	if bool(RunState.victory):
		return _endless_goal()
	if bool(RunState.get("singularity_secured")):
		return _deep_elevator_goal()

	if not bool(RunState.area_unlocked):
		if int(RunState.pickaxe_level) < 3:
			return _pickaxe_goal("mossMine")
		return _gate_goal("moonglass", "mossMine", int(GameData.data.GATE_COST), "Open the Moonglass Gate")

	if not bool(RunState.emberdeep_unlocked):
		if int(RunState.pickaxe_level) < 4:
			return _pickaxe_goal("moonMine")
		return _gate_goal("emberdeep", "moonMine", int(GameData.data.EMBER_GATE_COST), "Break the Emberdeep Seal")

	if not bool(RunState.fourth_unlocked):
		if int(RunState.pickaxe_level) < 5:
			return _pickaxe_goal("emberMine")
		var required_mastery: int = int(WorldCatalog.ENTRY_GATES.starfall.min_ember_mastery)
		if int(RunState.ember_mastery) < required_mastery:
			return _mastery_goal()
		return _goal(
			"gate:starfall", "gate", "Open the Starfall Master Seal",
			"Ember Mastery %d has awakened the seal" % required_mastery,
			{"world_id": "starfall", "station_id": "starfallGate"}
		)

	if String(RunState.starforge_variant).is_empty():
		return _starforge_goal()
	if RunState.hub_tutorial_pending():
		return _goal(
			"hub:first_visit", "hub", "Inspect the Underground Hub",
			"The Hub entrance is open in Starfall", {"station_id": "hubEntrance"}
		)

	return _drill_goal()


func _endless_goal() -> Dictionary:
	var descent: Dictionary = RunState.endless_descent_status()
	var active: = bool(descent.get("active", false))
	var carried: = Dictionary(descent.get("carried_relic", {}))
	var carried_id: = String(carried.get("id", ""))
	if not carried_id.is_empty():
		var relic: Dictionary = RunState.relic_status(carried_id)
		var relic_name: = String(relic.get("display_name", "Relic"))
		if active:
			var attached: = bool(carried.get("attached", false))
			return _goal(
				"endless:haul:%s" % carried_id, "endless_return",
				"Bring the relic home", relic_name,
				{
					"relic_id": carried_id,
					"hud_action": "Tunnel Home · your mole" if attached else "Attach the rope to the relic",
				}
			)
		return _goal(
			"endless:place:%s" % carried_id, "relic_place",
			"Place the %s" % relic_name, "Place the relic on the Museum pedestal",
			{
				"station_id": "relicPedestal", "relic_id": carried_id,
				"hud_title": "Place your relic", "hud_action": "Museum pedestal · Hub",
			}
		)

	# Each relic earns its physical Hub milestone before the next discovery.
	for workshop_id_value in RunState.ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var status: Dictionary = RunState.workshop_status(workshop_id)
		if bool(status.get("blueprint_unlocked", false)) and not bool(status.get("built", false)):
			return _workshop_goal(workshop_id, status, active, false)

	var next_relic_id: = ""
	for relic_id_value in RunState.ENDLESS_RELIC_IDS:
		var relic_id: = String(relic_id_value)
		if not bool(Dictionary(RunState.relic_status(relic_id)).get("placed", false)):
			next_relic_id = relic_id
			break
	if not next_relic_id.is_empty():
		var milestone: = mini(int(descent.get("placed_relic_count", 0)) + 1, int(descent.get("total_relics", 5)))
		return _goal(
			"endless:explore:%s" % next_relic_id, "endless_explore" if active else "endless_enter",
			"Find relic %d of %d" % [milestone, int(descent.get("total_relics", 5))],
			"Keep mining deeper. Relics expand your Hub.",
			{
				"relic_id": next_relic_id, "station_id": "deepElevator",
				"hud_action": "Mine deeper · The Deep" if active else "Enter The Deep · Hub",
			}
		)

	# Completed Hub: rotate through the least-developed available workshop.
	# Its transaction-owned recipe disappears at its real maximum; mining never does.
	var next_workshop: = ""
	var next_status: Dictionary = {}
	for workshop_id_value in RunState.ENDLESS_WORKSHOP_IDS:
		var workshop_id: = String(workshop_id_value)
		var status: Dictionary = RunState.workshop_status(workshop_id)
		if not bool(status.get("built", false)) or Dictionary(status.get("next_upgrade", {})).is_empty():
			continue
		if next_status.is_empty() or int(status.get("level", 0)) < int(next_status.get("level", 0)):
			next_workshop = workshop_id
			next_status = status
	if not next_workshop.is_empty():
		return _workshop_goal(next_workshop, next_status, active, true)
	return _goal(
		"endless:deeper", "endless_explore" if active else "endless_enter",
		"Keep digging deeper", "Your Hub is complete. The mountain keeps going.",
		{
			"station_id": "deepElevator",
			"hud_action": "Richer seams below" if active else "Return to The Deep · Hub",
		}
	)


func _workshop_goal(workshop_id: String, status: Dictionary, active: bool, upgrading: bool) -> Dictionary:
	if not upgrading and bool(status.get("ready_to_build", false)):
		var workshop_name: String = String(status.get("display_name", workshop_id.capitalize()))
		return _goal(
			"endless:workshop:%s" % workshop_id, "endless_return" if active else "workshop",
			"Awaken the %s" % workshop_name, "Your relic supplies the construction materials",
			{
				"station_id": workshop_id, "workshop_id": workshop_id,
				"hud_title": workshop_name,
				"hud_action": "Tunnel Home · workshop ready" if active else "Awaken · materials supplied",
			}
		)
	var recipe: = Dictionary(status.get("next_upgrade", {})) if upgrading else {}
	var resource_id: = String(recipe.get("resource", status.get("build_resource", "")))
	var required: = int(recipe.get("cost", status.get("remaining", 0)))
	var carried_amount: = int(RunState.cargo.get(resource_id, 0))
	var ready: = carried_amount >= required
	var workshop_name: = String(status.get("display_name", workshop_id.capitalize()))
	var kind: = "endless_resource" if active else "endless_enter"
	var action: = "Mine · The Deep" if active else "Enter The Deep · Hub"
	if active and ready:
		kind = "endless_return"
		action = "Tunnel Home · upgrade ready" if upgrading else "Tunnel Home · materials ready"
	elif not active and (ready or (not upgrading and carried_amount > 0)):
		kind = "workshop"
		action = "Upgrade · Hub" if upgrading else "Build · Hub" if bool(status.get("ready_to_build", false)) else "Deliver materials · Hub"
	return _goal(
		"endless:%s:%s" % ["upgrade" if upgrading else "workshop", workshop_id], kind,
		"Upgrade the %s" % workshop_name if upgrading else "Build the %s" % workshop_name,
		"%s · level %d" % [workshop_name, int(recipe.get("level", 1))] if upgrading else "A permanent home for your discovery",
		{
			"station_id": workshop_id if kind == "workshop" else "deepElevator",
			"workshop_id": workshop_id, "resource_id": resource_id,
			"required_amount": required, "hud_action": action,
			"hud_title": "%s · %d" % [workshop_name, int(recipe.get("level", 1))] if upgrading else workshop_name,
		}
	)


func sellable_value() -> int:
	return int(Dictionary(RunState.assay_sale_snapshot()).get("total", 0))


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
	# The first form is still a player choice. All first-form prices come from
	# the same crafting authority used by the shop, including the guide target.
	var status: Dictionary = RunState.starforge_crafting_status("crusher")
	var recipe: = Dictionary(Dictionary(status.get("variant", {})).get("cost", {}))
	var missing_resource: = ""
	for resource_id in recipe:
		if int(RunState.cargo.get(resource_id, 0)) < int(recipe[resource_id]):
			missing_resource = String(resource_id)
			break
	if missing_resource.is_empty():
		return _goal(
			"starforge:first", "starforge", "Forge a Starforge Pickaxe",
			"Your crafting materials are ready",
			{"station_id": "starforge", "mine_id": "starMine"}
		)
	return _goal(
		"starforge:first", "mine_resource", "Forge a Starforge Pickaxe",
		"Mine Astralite and Crownstone in Starfall",
		{
			"mine_id": "starMine", "resource_id": missing_resource,
			"required_amount": int(recipe.get(missing_resource, 0)),
		}
	)


func _drill_goal() -> Dictionary:
	var status: = Dictionary(RunState.drill_upgrade_status())
	var reason: = String(status.get("reason", ""))
	if reason == "maximum_level" or Dictionary(status.get("recipe", {})).is_empty():
		if bool(RunState.singularity_secured):
			return _goal("endgame:hub", "hub", "Enter the Underground Hub", "The Hub entrance is open in Starfall", {"station_id": "hubEntrance"})
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
			"endgame:final_descent", "hub_elevator", "Enter Deepheart",
			"The Deepheart passage is ready", {"station_id": "deepElevator"}
		)
	if bool(status.get("repaired", false)):
		return _goal(
			"endgame:power_elevator", "hub_elevator", "Awaken the Deepheart Passage",
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
			"endgame:repair_elevator", "hub_elevator", "Restore the Deepheart Passage",
			"All repair materials have been delivered", {"station_id": "deepElevator"}
		)
	var amount: = int(missing.get(selected_resource, 0))
	var mine_id: = String(resource_to_mine[selected_resource])
	if carrying_resource:
		return _goal(
			"endgame:repair_elevator", "hub_elevator", "Restore the Deepheart Passage",
			"Deliver %s to the Hub" % selected_resource.capitalize(),
			{
				"station_id": "deepElevator", "mine_id": mine_id,
				"resource_id": selected_resource, "required_amount": amount,
			}
		)
	return _goal(
		"endgame:repair_elevator", "depth_resource", "Restore the Deepheart Passage",
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


func _retained_candidate(candidates: Array, key: String) -> Dictionary:
	if key.is_empty():
		return {}
	var selected: Dictionary = {}
	for value in candidates:
		if not value is Dictionary or String(value.get("key", "")) != key:
			continue
		if not value.get("position", Vector2.ZERO) is Vector2:
			continue
		# Duplicate keys still use the original priority/tie-breaking rules.
		if not selected.is_empty():
			return {}
		selected = value
	if selected.is_empty():
		return {}
	return {"key": key, "position": Vector2(selected.get("position", Vector2.ZERO))}


func _clear_target() -> void :
	locked_target_key = ""
	locked_target_position = Vector2.ZERO


func _depth_location(mine_id: String) -> String:
	return {"mossMine":"Rootwound Depths · Mossvein Mine, Depth 2", "moonMine":"Prismatic Depths · Moonglass Labyrinth, Depth 2", "emberMine":"Molten Depths · Emberdeep Works, Depth 2", "starMine":"Voidstar Depths · Starfall Hollow, Depth 2"}.get(mine_id,"Depth 2")
