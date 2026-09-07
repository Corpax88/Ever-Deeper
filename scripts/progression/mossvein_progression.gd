class_name MossveinProgression
extends RefCounted








const MINE_ID: = "mossMine"
const MINE_IDS: = ["mossMine", "moonMine", "emberMine", "starMine"]
const DEPTH_ONE: = 1
const ROOTWOUND_DEPTH: = 2
const MINING_RUSH_DURATION: = 30.0

var _source: Dictionary
var _pocket_index: Dictionary = {}
var _cavern_index: Dictionary = {}
var _depth_access_by_mine: Dictionary = {}
var _surface_chest_index: Dictionary = {}


func _init(source_data: Dictionary) -> void :
	_source = source_data
	_build_indexes()
	_validate_source_contract()


func rootwound_profile() -> Dictionary:
	return depth_profile(MINE_ID)


func depth_profile(mine_id: String) -> Dictionary:
	if not MINE_IDS.has(mine_id):
		return {}
	var gated: = _drill_gated_profile(mine_id)
	return {
		"mine_id": mine_id,
		"depth": ROOTWOUND_DEPTH,
		"name": String(_source.MINE_DEPTH_PROFILES[mine_id].name),
		"terrain_hp": int(_source.MINE_DEPTH_PROFILES[mine_id].terrainHp),
		"resources": Dictionary(_source.DEPTH2_RESOURCE_PROFILES[mine_id]).duplicate(true),
		"drill_gated": gated,
	}


func cavern_ids(depth: int, mine_id: String = MINE_ID) -> Array:
	var result: Array = []
	for cavern_id in _cavern_index:
		var cavern: Dictionary = _cavern_index[cavern_id]
		if int(cavern.depth) == depth and String(cavern.mine_id) == mine_id:
			result.append(String(cavern_id))
	result.sort()
	return result


func pocket_reward_ids(depth: int, mine_id: String = MINE_ID) -> Array:
	var result: Array = []
	for reward_id in _pocket_index:
		var definition: Dictionary = _pocket_index[reward_id]
		if int(definition.depth) == depth and String(definition.mine_id) == mine_id:
			result.append(String(reward_id))
	result.sort()
	return result


func has_cavern(cavern_id: String) -> bool:
	return _cavern_index.has(cavern_id)


func has_pocket_reward(reward_id: String) -> bool:
	return _pocket_index.has(reward_id)


func pocket_reward(reward_id: String) -> Dictionary:
	return Dictionary(_pocket_index.get(reward_id, {})).duplicate(true)


func pocket_claim_plan(reward_id: String, deposit_cleared: bool = false) -> Dictionary:
	var definition: = pocket_reward(reward_id)
	if definition.is_empty():
		return {"ok": false, "reason": "unknown_reward"}
	var reward: Dictionary = definition.reward
	var kind: = String(reward.kind)
	if (kind == "crystal" or kind == "motherlode") and not deposit_cleared:
		return {
			"ok": false,
			"reason": "deposit_required",
			"reward_id": reward_id,
			"cavern_id": String(definition.cavern_id),
			"mine_id": String(definition.mine_id),
		}
	var pending_loot: Dictionary = {}
	var mining_rush_seconds: = 0.0
	match kind:
		"cache":
			for resource_id in Dictionary(reward.get("rewards", {})):
				pending_loot[String(resource_id)] = int(reward.rewards[resource_id])
		"crystal", "motherlode":
			pending_loot[String(reward.type)] = 1
		"shrine":
			mining_rush_seconds = MINING_RUSH_DURATION
		_:
			return {"ok": false, "reason": "unsupported_reward"}
	return {
		"ok": true,
		"reason": "ready",
		"reward_id": reward_id,
		"cavern_id": String(definition.cavern_id),
		"mine_id": String(definition.mine_id),
		"depth": int(definition.depth),
		"kind": kind,
		"label": String(reward.label),
		"pending_loot": pending_loot,
		"mining_rush_seconds": mining_rush_seconds,
	}


func depth_entry_status(entrance_discovered: bool, mine_id: String = MINE_ID) -> Dictionary:
	if not MINE_IDS.has(mine_id):
		return {
			"can_enter": false,
			"reason": "unknown_mine",
			"mine_id": mine_id,
			"depth": ROOTWOUND_DEPTH,
		}
	return {
		"can_enter": entrance_discovered,
		"reason": "ready" if entrance_discovered else "entrance_hidden",
		"mine_id": mine_id,
		"depth": ROOTWOUND_DEPTH,
		"name": String(_source.MINE_DEPTH_PROFILES[mine_id].name),
	}


func resource_access(
	resource_id: String,
	pickaxe_level: int,
	has_deep_tool: bool,
	drill_level: int
) -> Dictionary:
	return depth_resource_access(MINE_ID, resource_id, pickaxe_level, has_deep_tool, drill_level)


func depth_resource_access(
	mine_id: String,
	resource_id: String,
	pickaxe_level: int,
	has_deep_tool: bool,
	drill_level: int
) -> Dictionary:
	if not MINE_IDS.has(mine_id):
		return {
			"known": false,
			"can_mine": false,
			"reason": "unknown_mine",
			"mine_id": mine_id,
			"resource_id": resource_id,
		}
	var mine_access: Dictionary = Dictionary(_depth_access_by_mine.get(mine_id, {}))
	if not mine_access.has(resource_id):
		return {
			"known": false,
			"can_mine": false,
			"reason": "unknown_resource",
			"mine_id": mine_id,
			"resource_id": resource_id,
		}
	var rule: Dictionary = Dictionary(mine_access[resource_id]).duplicate(true)
	var reason: = "ready"
	if drill_level < int(rule.requires_drill_level):
		reason = "drill_required"
	elif bool(rule.requires_deep_tool) and not has_deep_tool:
		reason = "deep_tool_required"
	elif pickaxe_level < int(rule.required_pickaxe):
		reason = "pickaxe_required"
	rule["known"] = true
	rule["can_mine"] = reason == "ready"
	rule["reason"] = reason
	rule["mine_id"] = mine_id
	return rule


func current_drill(drill_level: int) -> Dictionary:
	var drills: Array = Array(_source.DRILLS)
	if drill_level <= 0 or drill_level >= drills.size():
		return {}
	return Dictionary(drills[drill_level]).duplicate(true)


func next_drill(drill_level: int) -> Dictionary:
	return current_drill(drill_level + 1)


func next_drill_recipe(drill_level: int) -> Dictionary:
	var recipes: Array = Array(_source.DRILL_RECIPES)
	var next_level: = drill_level + 1
	if next_level <= 0 or next_level >= recipes.size() or recipes[next_level] == null:
		return {}
	var result: Dictionary = Dictionary(recipes[next_level]).duplicate(true)
	result["gold"] = int(result.gold)
	var normalized_requirements: Array = []
	for requirement_value in Array(result.requirements):
		var requirement: Dictionary = Dictionary(requirement_value).duplicate(true)
		requirement["amount"] = int(requirement.amount)
		normalized_requirements.append(requirement)
	result["requirements"] = normalized_requirements
	result["level"] = next_level
	result["drill"] = current_drill(next_level)
	return result


func drill_upgrade_status(
	drill_level: int,
	gold: int,
	cargo: Dictionary,
	has_starforge: bool
) -> Dictionary:
	var recipe: = next_drill_recipe(drill_level)
	if recipe.is_empty():
		return {"ready": false, "reason": "maximum_level", "missing": []}
	if drill_level == 0 and not has_starforge:
		return {
			"ready": false,
			"reason": "starforge_required",
			"recipe": recipe,
			"missing": [],
		}
	var missing: Array = []
	for requirement_value in Array(recipe.requirements):
		var requirement: Dictionary = requirement_value
		var owned: = int(cargo.get(String(requirement.type), 0))
		if owned < int(requirement.amount):
			var row: = requirement.duplicate(true)
			row["owned"] = owned
			row["missing"] = int(requirement.amount) - owned
			missing.append(row)
	if not missing.is_empty():
		return {
			"ready": false,
			"reason": "materials_required",
			"recipe": recipe,
			"missing": missing,
		}
	var missing_gold: = maxi(0, int(recipe.gold) - gold)
	if missing_gold > 0:
		return {
			"ready": false,
			"reason": "gold_required",
			"recipe": recipe,
			"missing": [],
			"missing_gold": missing_gold,
		}
	return {
		"ready": true,
		"reason": "ready",
		"recipe": recipe,
		"missing": [],
		"missing_gold": 0,
	}


func protected_drill_cargo(drill_level: int, cargo: Dictionary) -> Dictionary:
	var recipe: = next_drill_recipe(drill_level)
	var result: Dictionary = {}
	if recipe.is_empty():
		return result
	for requirement_value in Array(recipe.requirements):
		var requirement: Dictionary = requirement_value
		var resource_id: = String(requirement.type)
		result[resource_id] = mini(int(requirement.amount), int(cargo.get(resource_id, 0)))
	return result


func starforge_variant(variant_id: String) -> Dictionary:
	if not Dictionary(_source.STARFORGE_VARIANTS).has(variant_id):
		return {}
	var result: Dictionary = Dictionary(_source.STARFORGE_VARIANTS[variant_id]).duplicate(true)
	result["id"] = variant_id
	result["cost"] = _normalized_reward_store(Dictionary(result.cost))
	return result


func starforge_crafting_status(
	variant_id: String,
	cargo: Dictionary,
	is_unlocked: bool,
	_drill_level: int,
	station_available: bool
) -> Dictionary:
	var variant: = starforge_variant(variant_id)
	if variant.is_empty():
		return {"ready": false, "can_equip": false, "reason": "unknown_variant"}
	if not station_available:
		return {
			"ready": false,
			"can_equip": false,
			"reason": "starfall_locked",
			"variant": variant,
		}
	if is_unlocked:
		return {
			"ready": false,
			"can_equip": true,
			"reason": "already_unlocked",
			"variant": variant,
			"missing": [],
		}
	var missing: Array = []
	for resource_id in Dictionary(variant.cost):
		var required: = int(variant.cost[resource_id])
		var owned: = int(cargo.get(resource_id, 0))
		if owned < required:
			missing.append({
				"type": String(resource_id),
				"amount": required,
				"owned": owned,
				"missing": required - owned,
			})
	return {
		"ready": missing.is_empty(),
		"can_equip": false,
		"reason": "ready" if missing.is_empty() else "materials_required",
		"variant": variant,
		"missing": missing,
	}


func surface_chest_ids() -> Array:
	var result: Array = _surface_chest_index.keys()
	result.sort()
	return result


func surface_chest_claim_plan(
	chest_id: String,
	pickaxe_level: int,
	has_starforge: bool
) -> Dictionary:
	if not _surface_chest_index.has(chest_id):
		return {"ok": false, "reason": "unknown_chest"}
	var chest: Dictionary = Dictionary(_surface_chest_index[chest_id]).duplicate(true)
	var requirement: Dictionary = chest.requires
	if bool(requirement.get("starforge", false)) and not has_starforge:
		return {"ok": false, "reason": "starforge_required", "chest": chest}
	if pickaxe_level < int(requirement.get("pickaxeLevel", 1)):
		return {"ok": false, "reason": "pickaxe_required", "chest": chest}
	return {
		"ok": true,
		"reason": "ready",
		"chest": chest,
		"pending_loot": _normalized_reward_store(Dictionary(chest.rewards)),
	}


func _build_indexes() -> void :
	for mine_id in MINE_IDS:
		for depth in [DEPTH_ONE, ROOTWOUND_DEPTH]:
			var discoveries_key: = "MINE_DISCOVERIES" if depth == DEPTH_ONE else "MINE_DEPTH_DISCOVERIES"
			var discoveries: Dictionary = _source[discoveries_key][mine_id]
			for cavern_value in Array(discoveries.caverns):
				var cavern: Dictionary = Dictionary(cavern_value).duplicate(true)
				var cavern_id: = String(cavern.id)
				var reward: Dictionary = cavern.reward
				_cavern_index[cavern_id] = {
					"id": cavern_id,
					"mine_id": mine_id,
					"depth": depth,
					"reward_id": String(reward.id),
				}
				_pocket_index[String(reward.id)] = {
					"mine_id": mine_id,
					"cavern_id": cavern_id,
					"depth": depth,
					"reward": reward.duplicate(true),
				}

		var mine_access: Dictionary = {}
		var discovery_profile: Dictionary = _source.MINE_DISCOVERY_PROFILES[mine_id]
		var default_required_pickaxe: = mini(5, int(discovery_profile.requiredPickaxe) + 1)
		var base_profile: Dictionary = _source.DEPTH2_RESOURCE_PROFILES[mine_id]
		for profile_key in ["main", "secondary", "rare"]:
			var profile_resource_id: = String(base_profile[profile_key])
			mine_access[profile_resource_id] = {
				"resource_id": profile_resource_id,
				"required_pickaxe": default_required_pickaxe,
				"requires_deep_tool": true,
				"requires_drill_level": 0,
			}
		for rock_value in Array(_source.MINE_DEPTH_DISCOVERIES[mine_id].rocks):
			var rock: Dictionary = rock_value
			var resource_id: = String(rock.type)
			var rule: Dictionary = mine_access.get(resource_id, {
				"resource_id": resource_id,
				"required_pickaxe": int(rock.get("requiredPickaxe", default_required_pickaxe)),
				"requires_deep_tool": bool(rock.get("requiresDeepTool", true)),
				"requires_drill_level": int(rock.get("requiresDrillLevel", 0)),
			})
			rule["required_pickaxe"] = maxi(
				int(rule.required_pickaxe),
				int(rock.get("requiredPickaxe", default_required_pickaxe))
			)
			rule["requires_deep_tool"] = (
				bool(rule.requires_deep_tool) or bool(rock.get("requiresDeepTool", false))
			)
			rule["requires_drill_level"] = maxi(
				int(rule.requires_drill_level),
				int(rock.get("requiresDrillLevel", 0))
			)
			mine_access[resource_id] = rule
		_depth_access_by_mine[mine_id] = mine_access

	for chest_value in Array(_source.CHEST_DEFINITIONS):
		var chest: Dictionary = chest_value

		_surface_chest_index[String(chest.id)] = chest.duplicate(true)


func _normalized_reward_store(raw: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for reward_id in raw:
		result[String(reward_id)] = int(raw[reward_id])
	return result


func _drill_gated_profile(mine_id: String) -> Dictionary:
	var types: Array = []
	for deposit_value in Array(_source.MINE_DEPTH_DISCOVERIES[mine_id].deposits):
		var deposit: Dictionary = deposit_value
		if not bool(deposit.get("drillGated", false)):
			continue
		var resource_id: = String(deposit.type)
		if not types.has(resource_id):
			types.append(resource_id)
	if types.is_empty():
		return {}
	types.sort()
	var gated_resource_id: = String(types[0])
	var access: Dictionary = Dictionary(_depth_access_by_mine[mine_id]).get(gated_resource_id, {})
	return {
		"type": gated_resource_id,
		"requires_drill_level": int(access.get("requires_drill_level", 0)),
		"vein_count": _count_drill_gated_veins(mine_id),
	}


func _count_drill_gated_veins(mine_id: String = MINE_ID) -> int:
	var ids: Dictionary = {}
	for deposit_value in Array(_source.MINE_DEPTH_DISCOVERIES[mine_id].deposits):
		var deposit: Dictionary = deposit_value
		if bool(deposit.get("drillGated", false)):
			ids[String(deposit.id)] = true
	return ids.size()


func _validate_source_contract() -> void :
	for key in [
		"MINE_DEPTH_PROFILES", "DEPTH2_RESOURCE_PROFILES", "MINE_DISCOVERY_PROFILES",
		"MINE_DISCOVERIES", "MINE_DEPTH_DISCOVERIES", "DRILLS", "DRILL_RECIPES",
		"STARFORGE_VARIANTS", "CHEST_DEFINITIONS",
	]:
		assert (_source.has(key), "Mine progression source is missing %s" % key)
	assert (String(_source.MINE_DEPTH_PROFILES[MINE_ID].name) == "ROOTWOUND DEPTHS")
	assert (int(_source.MINE_DEPTH_PROFILES[MINE_ID].terrainHp) == 320)
	assert (String(_source.DEPTH2_RESOURCE_PROFILES[MINE_ID].main) == "rootiron")
	assert (String(_source.DEPTH2_RESOURCE_PROFILES[MINE_ID].secondary) == "deepstone")
	assert (String(_source.DEPTH2_RESOURCE_PROFILES[MINE_ID].rare) == "ambercore")
	assert (cavern_ids(DEPTH_ONE).size() == 6)
	assert (cavern_ids(ROOTWOUND_DEPTH).size() == 8)
	assert (_count_drill_gated_veins() == 4)
	for variant_id in ["crusher", "swift", "prospector"]:
		var variant: = starforge_variant(variant_id)
		assert (int(variant.cost.astralite) == 200)
		assert (int(variant.cost.crownstone) == 200)
	var burrower: = next_drill_recipe(0)
	assert (String(burrower.drill.name) == "Burrower Drill")
	assert (int(burrower.gold) == 5000)

	var prismatic: = depth_profile("moonMine")
	assert (String(prismatic.name) == "PRISMATIC DEPTHS")
	assert (int(prismatic.terrain_hp) == 360)
	assert (String(prismatic.resources.main) == "prismite")
	assert (String(prismatic.resources.secondary) == "deepstone")
	assert (String(prismatic.resources.rare) == "lunacore")
	assert (String(prismatic.drill_gated.type) == "phasecrystal")
	assert (int(prismatic.drill_gated.requires_drill_level) == 2)
	assert (int(prismatic.drill_gated.vein_count) == 4)
	assert (cavern_ids(ROOTWOUND_DEPTH, "moonMine").size() == 9)
	var pulse: = next_drill_recipe(1)
	assert (String(pulse.drill.name) == "Pulse Drill")
	assert (int(pulse.gold) == 12000)
	assert (Array(pulse.requirements) == [
		{"scene": "mossMine", "type": "burrowsteel", "amount": 60},
		{"scene": "moonMine", "type": "prismite", "amount": 40},
		{"scene": "moonMine", "type": "lunacore", "amount": 4},
	])
