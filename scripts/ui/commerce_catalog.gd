class_name CommerceCatalog
extends RefCounted

const GOLD_ICON: = "res://assets/ui/gold-bars-v1.png"
const WORKSHOP_TEXTURES: = {
	"tool_forge": "res://assets/endless/workshop-tool-forge-v1.png",
	"light_lab": "res://assets/endless/workshop-light-lab-v1.png",
	"wardrobe": "res://assets/endless/workshop-wardrobe-v1.png",
	"treasure_chamber": "res://assets/endless/treasure-chamber-v1.png",
	"lift_workshop": "res://assets/endless/workshop-lift-v1.png",
}
const ENDLESS_RESOURCE_TEXTURES: = {
	"deep_alloy": "res://assets/endless/node-deep-alloy-v1.png",
	"lumenstone": "res://assets/endless/node-lumen-shard-v1.png",
	"memory_silk": "res://assets/endless/node-memory-silk-v1.png",
	"echo_crystal": "res://assets/endless/node-echo-crystal-v1.png",
	"waystone": "res://assets/endless/node-waystone-v1.png",
}
const TOOL_TEXTURES: = {
	"original": "res://assets/tools/drill-deepcore.png",
	"crusher": "res://assets/tools/starforge-crusher.png",
	"comet": "res://assets/tools/starforge-swift.png",
	"crownseeker": "res://assets/tools/starforge-prospector.png",
	"deepheart": "res://assets/tools/pickaxe-ember.png",
}
const STARFORGE_TEXTURES: = {
	"crusher": "res://assets/tools/starforge-crusher.png",
	"swift": "res://assets/tools/starforge-swift.png",
	"prospector": "res://assets/tools/starforge-prospector.png",
}
const STARFORGE_TRAITS: = {
	"crusher": "Slow strikes. Colossal impacts.",
	"swift": "Comet speed. Relentless strikes.",
	"prospector": "Every discovery. Twice the reward.",
}


static func forge_config(snapshot: Dictionary) -> Dictionary:
	var next: Dictionary = Dictionary(snapshot.get("next", {}))
	if next.is_empty():
		var current: Dictionary = Dictionary(snapshot.get("current", {}))
		return {
			"panel_id": "forge", "title": "Mossvein Forge",
			"subtitle": "Every strike began here", "catalog_label": "Forging",
			"primary_action_visible": false,
			"items": [{
				"id": "forge:complete", "title": String(current.get("name", "Forge Complete")),
				"subtitle": "All surface forging complete", "texture": String(current.get("texture_path", "")),
				"current": true, "affordable": true, "action_enabled": false,
				"action_label": "Forge mastered", "footer_text": "Surface forge complete",
				"future_unlock_label": "Next step",
				"future_unlock": "The Starforge and Drill Age now carry your progression.",
				"total": {"label": "Forge", "value": "Mastered", "ready": true},
			}],
		}
	var costs: Array = []
	for requirement_value in Array(Dictionary(snapshot.get("cost", {})).get("requirements", [])):
		var requirement: Dictionary = Dictionary(requirement_value)
		costs.append(_cost(
			String(requirement.get("kind", "material")),
			String(requirement.get("name", "Material")),
			int(requirement.get("owned", 0)), int(requirement.get("required", 0)),
			String(requirement.get("texture_path", ""))
		))
	var stats: Array = []
	for stat_value in Array(snapshot.get("stats", [])):
		var stat: Dictionary = Dictionary(stat_value)
		var stat_id: = String(stat.get("id", ""))
		stats.append({
			"id": stat_id, "label": String(stat.get("label", stat_id)),
			"current": _forge_stat_value(stat_id, stat.get("current", 0)),
			"next": _forge_stat_value(stat_id, stat.get("next", 0)),
		})
	var purchase_kind: = String(snapshot.get("purchase_kind", "pickaxe"))
	var lock_reason: = "Open Emberdeep Foundry before forging this pickaxe." if String(snapshot.get("lock_reason", "")) == "emberdeep_locked" else ""
	return {
		"panel_id": "forge", "title": "Mossvein Forge",
		"subtitle": "Inspect the change before the hammer falls", "catalog_label": "Next Upgrade",
		"selected_item_id": "forge:%s" % purchase_kind,
		"items": [{
			"id": "forge:%s" % purchase_kind,
			"title": String(next.get("name", "Next Upgrade")),
			"subtitle": "Depth Mastery" if purchase_kind == "ember_mastery" else "Pickaxe Upgrade",
			"description": "A permanent upgrade. Materials and gold are transferred into the forge when confirmed.",
			"texture": String(next.get("texture_path", "")),
			"stats": stats, "costs": costs,
			"affordable": bool(snapshot.get("ready", false)),
			"locked": bool(snapshot.get("locked", false)),
			"locked_reason": lock_reason, "disabled_reason": lock_reason,
			"action_label": "Forge upgrade",
			"future_unlock": "The forged tool is equipped immediately.",
			"total": {"label": "Recipe", "value": "Ready" if bool(snapshot.get("ready", false)) else "Incomplete", "ready": bool(snapshot.get("ready", false))},
		}],
	}


static func wayfarer_config() -> Dictionary:
	var level: = int(RunState.movement_speed_level)
	var cost: = int(RunState.movement_speed_upgrade_cost())
	var owned: = int(RunState.gold)
	return {
		"panel_id": "wayfarer", "title": "Wayfarer",
		"subtitle": "Permanent travel tuning - no level cap", "catalog_label": "Movement",
		"items": [{
			"id": "wayfarer:speed", "title": "Wayfarer Tune %d" % (level + 1),
			"subtitle": "Permanent movement speed", "texture": "res://assets/surface/v3/wayfarer-boots.png",
			"description": "Makes every road, mine and return trip faster without changing mining balance.",
			"stats": [{
				"id": "speed", "label": "MOVEMENT",
				"current": "%.2fx" % RunState.movement_speed_multiplier(),
				"next": "%.2fx" % RunState.movement_speed_multiplier(level + 1),
			}],
			"costs": [_cost("gold", "Gold", owned, cost, GOLD_ICON)],
			"affordable": owned >= cost, "action_label": "Tune boots",
			"future_unlock": "Unlimited tuning: the next level appears after every purchase.",
			"total": {"label": "Price", "value": "%d gold" % cost, "ready": owned >= cost},
		}],
	}


static func starforge_config() -> Dictionary:
	var items: Array = []
	for variant_value in RunState.STARFORGE_VARIANT_IDS:
		var variant_id: = String(variant_value)
		var status: Dictionary = Dictionary(RunState.starforge_crafting_status(variant_id))
		var variant: Dictionary = Dictionary(status.get("variant", GameData.data.STARFORGE_VARIANTS[variant_id]))
		var equipped: = String(RunState.starforge_variant) == variant_id
		var unlocked: = bool(RunState.starforge_unlocked.get(variant_id, false))
		var status_reason: = String(status.get("reason", ""))
		var world_locked: = status_reason == "starfall_locked"
		var costs: Array = []
		if not unlocked:
			for resource_value in Dictionary(variant.get("cost", {})):
				var resource_id: = String(resource_value)
				var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
				costs.append(_cost(
					resource_id, String(rock.get("label", resource_id.capitalize())),
					int(RunState.cargo.get(resource_id, 0)), int(Dictionary(variant.cost).get(resource_id, 0)),
					_resource_texture(resource_id)
				))
		var stats: = _starforge_stats(variant_id, variant)
		var available: = bool(status.get("ready", false)) or bool(status.get("can_equip", false))
		var state_value: = (
			"ACTIVE" if equipped else
			"OWNED" if unlocked else
			"READY" if available else
			"LOCKED" if world_locked else
			"MATERIALS"
		)
		items.append({
			"id": "starforge:%s" % variant_id, "title": String(variant.get("name", variant_id.capitalize())),
			"subtitle": String(variant.get("short", "Starforge form")),
			"description": String(STARFORGE_TRAITS.get(variant_id, variant.get("short", ""))),
			"texture": String(STARFORGE_TEXTURES.get(variant_id, "")),
			"stats": stats, "costs": costs, "equipped": equipped,
			"locked": world_locked, "locked_reason": "Open the Starfall Master Seal to power this forge.",
			"affordable": available, "action_enabled": not equipped,
			"action_label": "Active core" if equipped else "Equip core" if unlocked else "Forge core",
			"footer_text": "This core is active" if equipped else "Ready to attune",
			"future_unlock": "Its signature trait remains active after upgrading to a drill.",
			"total": {"label": "STATUS", "value": state_value, "ready": unlocked or available},
		})
	return {
		"panel_id": "starforge", "title": "Starforge",
		"subtitle": "Forge a mining identity - switch freely between owned cores", "catalog_label": "Attunements",
		"selected_item_id": "starforge:%s" % String(RunState.starforge_variant),
		"items": items,
	}


static func workshop_config(workshop_id: String, status: Dictionary, selection: Dictionary) -> Dictionary:
	if workshop_id == "wardrobe":
		return _wardrobe_config(status, selection)
	if workshop_id == "light_lab":
		return _light_lab_config(status, selection)
	var title: = String(status.get("display_name", workshop_id.capitalize()))
	var level: = int(status.get("level", 1))
	var max_level: = int(status.get("max_level", 1))
	var items: Array = []
	var upgrade: Dictionary = Dictionary(status.get("next_upgrade", {}))
	if not upgrade.is_empty():
		var resource_id: = String(upgrade.get("resource", ""))
		var cost: = int(upgrade.get("cost", 0))
		items.append({
			"id": "workshop:upgrade", "title": "%s Level %d" % [title, int(upgrade.get("level", level + 1))],
			"subtitle": _workshop_upgrade_subtitle(workshop_id), "texture": String(WORKSHOP_TEXTURES.get(workshop_id, "")),
			"description": _workshop_description(workshop_id),
			"stats": _workshop_stats(workshop_id, level, level + 1),
			"costs": [_cost(resource_id, _resource_name(resource_id), int(RunState.cargo.get(resource_id, 0)), cost, _resource_texture(resource_id))],
			"affordable": bool(status.get("ready_to_upgrade", false)), "action_label": "Upgrade workshop",
			"future_unlock": _workshop_level_unlock(workshop_id, level + 1),
			"total": {"label": "Level", "value": "%d > %d" % [level, level + 1], "ready": bool(status.get("ready_to_upgrade", false))},
		})
	elif max_level <= 1:
		items.append({
			"id": "workshop:inspect", "title": title, "subtitle": "Complete Hub expansion",
			"texture": String(WORKSHOP_TEXTURES.get(workshop_id, "")), "current": true,
			"description": _workshop_description(workshop_id), "stats": _workshop_inspection_stats(workshop_id),
			"affordable": true, "action_enabled": false,
			"action_label": "Complete", "footer_text": "Permanent effect active",
			"total": {"label": "Status", "value": "Complete", "ready": true},
		})
	var options: Array = _all_workshop_options(workshop_id)
	var current: = String(selection.get("current", ""))
	for index in range(options.size()):
		var option: = String(options[index])
		var unlock_level: = index + 1
		items.append({
			"id": "workshop:equip:%s" % option, "title": option.replace("_", " ").capitalize(),
			"subtitle": _workshop_option_subtitle(workshop_id, option),
			"texture": _workshop_option_texture(workshop_id, option),
			"equipped": option == current, "locked": unlock_level > level,
			"affordable": unlock_level <= level, "action_enabled": option != current,
			"locked_reason": "Upgrade %s to level %d." % [title, unlock_level],
			"action_label": "Equipped" if option == current else "Equip",
			"footer_text": "Current loadout" if option == current else "Ready to equip",
			"future_unlock_label": "Unlock requirement" if unlock_level > level else "Loadout note",
			"future_unlock": "Unlocked at workshop level %d." % unlock_level if unlock_level > level else _workshop_option_note(workshop_id),
			"total": {"label": "Loadout", "value": "Equipped" if option == current else "Level %d" % unlock_level, "ready": unlock_level <= level},
		})


	var styles: Array = [] if max_level <= 1 else Array(RunState.ENDLESS_WORKSHOP_STYLE_IDS).slice(0, max_level)
	var current_style: = String(status.get("style", "original"))
	for index in range(styles.size()):
		var style_id: = String(styles[index])
		var unlock_level: = index + 1
		items.append({
			"id": "workshop:style:%s" % style_id, "title": "%s Finish" % style_id.capitalize(),
			"subtitle": "Workshop appearance", "texture": String(WORKSHOP_TEXTURES.get(workshop_id, "")),
			"equipped": style_id == current_style, "locked": unlock_level > level,
			"affordable": unlock_level <= level, "action_enabled": style_id != current_style,
			"locked_reason": "Upgrade %s to level %d." % [title, unlock_level],
			"action_label": "Applied" if style_id == current_style else "Apply finish",
			"footer_text": "Current workshop finish" if style_id == current_style else "Ready to apply",
			"future_unlock_label": "Unlock requirement" if unlock_level > level else "Finish note",
			"future_unlock": "Unlocked at workshop level %d." % unlock_level if unlock_level > level else "Appearance only - workshop power comes from its level.",
			"total": {"label": "Finish", "value": "Applied" if style_id == current_style else "Level %d" % unlock_level, "ready": unlock_level <= level},
		})
	var preferred_item_id: = "workshop:upgrade" if not upgrade.is_empty() else (
		"workshop:equip:%s" % current if not current.is_empty() and not options.is_empty() else "workshop:inspect"
	)
	return {
		"panel_id": "workshop:%s" % workshop_id, "title": title,
		"subtitle": "Level %d / %d - inspect upgrades and future unlocks" % [level, max_level],
		"catalog_label": "Workshop", "items": items,
		"selected_item_id": preferred_item_id,
		"primary_action_visible": not (max_level <= 1 and upgrade.is_empty()),
	}


static func _cost(id: String, label: String, owned: int, required: int, icon_path: String) -> Dictionary:
	return {
		"id": id, "label": label, "owned": maxi(0, owned), "required": maxi(0, required),
		"missing": maxi(0, required - owned), "icon_path": icon_path,
	}


static func _forge_stat_value(stat_id: String, raw: Variant) -> String:
	var value: = float(raw)
	match stat_id:
		"cooldown", "precision_delay": return "%.2fs" % value
		"yield_bonus": return "+%d%%" % roundi(value * 100.0)
		"shell_power": return "%.2fx" % value
	return "%d" % roundi(value)


static func _starforge_stats(variant_id: String, variant: Dictionary) -> Array:
	var stats: Array = [
		{"id": "power", "label": "POWER", "current": "1.00x", "next": "%.2fx" % float(variant.get("powerMultiplier", 1.0))},
		{"id": "speed", "label": "STRIKE TIME", "current": "1.00x", "next": "%.2fx" % float(variant.get("cooldownMultiplier", 1.0))},
	]
	if variant_id == "crusher":
		stats.append({"id": "area", "label": "IMPACT AREA", "current": "1×1", "next": "5×5"})
	elif variant_id == "prospector":
		stats.append({"id": "yield", "label": "RESOURCE YIELD", "current": "1x", "next": "%dx" % int(variant.get("yieldMultiplier", 2))})
	else:
		stats.append({"id": "identity", "label": "PROFILE", "current": "Standard", "next": "Comet"})
	return stats


static func _workshop_stats(workshop_id: String, current_level: int, next_level: int) -> Array:
	var current: Dictionary = RunState.workshop_effects_at_level(workshop_id, current_level)
	var next: Dictionary = RunState.workshop_effects_at_level(workshop_id, next_level)
	match workshop_id:
		"tool_forge":
			return [
				_effect_stat("TOOL POWER", current, next, "power"),
				_effect_stat("TOOL SPEED", current, next, "speed"),
				_effect_stat("MINING REACH", current, next, "reach"),
			]
		"light_lab":
			return [
				_effect_stat("LIGHT RANGE", current, next, "light_range"),
				_effect_stat("BRIGHTNESS", current, next, "light_energy"),
			]
		"wardrobe":
			return [{"label": "OUTFIT SLOTS", "current": current_level, "next": next_level}]
	return []


static func _effect_stat(label: String, current: Dictionary, next: Dictionary, key: String) -> Dictionary:
	return {
		"label": label,
		"current": "%d%%" % roundi(float(current.get(key, 1.0)) * 100.0),
		"next": "%d%%" % roundi(float(next.get(key, 1.0)) * 100.0),
	}


static func _workshop_inspection_stats(workshop_id: String) -> Array:
	if workshop_id == "treasure_chamber":
		var status: Dictionary = RunState.endless_descent_status()
		var before: Dictionary = RunState.workshop_effects_at_level(workshop_id, 0)
		var after: Dictionary = RunState.workshop_effects_at_level(workshop_id, 1)
		var pickup_radius: = float(RunState.resource_pickup_radius())
		var baseline_radius: = maxf(1.0, pickup_radius - float(after.get("pickup_bonus", 0.0)))
		return [
			_effect_stat("SITE CACHE YIELD", before, after, "cache_yield"),
			{"label": "PICKUP REACH", "current": "100%", "next": "%d%%" % roundi(pickup_radius / baseline_radius * 100.0)},
			{"label": "RELICS ARCHIVED", "current": int(status.get("placed_relic_count", 0)), "next": int(status.get("total_relics", 5))},
		]
	if workshop_id == "lift_workshop":
		var before: Dictionary = RunState.workshop_effects_at_level(workshop_id, 0)
		var after: Dictionary = RunState.workshop_effects_at_level(workshop_id, 1)
		return [{
			"label": "TUNNEL HOME PREPARATION",
			"current": "%.2fs" % float(before.get("tunnel_duration", 0.0)),
			"next": "%.2fs" % float(after.get("tunnel_duration", 0.0)),
		}]
	return []


static func _all_workshop_options(workshop_id: String) -> Array:
	match workshop_id:
		"tool_forge": return Array(RunState.ENDLESS_TOOL_STYLE_IDS)
		"light_lab": return Array(RunState.ENDLESS_LIGHT_STYLE_IDS)
		"wardrobe": return Array(RunState.ENDLESS_OUTFIT_IDS)
	return []


static func _workshop_option_texture(workshop_id: String, option: String) -> String:
	if workshop_id == "tool_forge":
		return String(TOOL_TEXTURES.get(option, WORKSHOP_TEXTURES.get(workshop_id, "")))

	return String(WORKSHOP_TEXTURES.get(workshop_id, ""))


static func _workshop_option_subtitle(workshop_id: String, option: String) -> String:
	match workshop_id:
		"tool_forge": return "Deep mining tool appearance"
		"light_lab": return _light_style_description(option)
		"wardrobe": return "Expedition outfit"
	return "Workshop selection"


static func _workshop_option_note(workshop_id: String) -> String:
	match workshop_id:
		"tool_forge": return "Appearance only - power, speed and mining reach come from workshop level."
		"light_lab": return "Beam shape and color change; range and energy come from workshop level."
		"wardrobe": return "Appearance only - outfits do not alter mining balance."
	return "Workshop loadout selection."


static func _light_style_description(option: String) -> String:
	return {
		"standard": "Balanced neutral headlamp beam",
		"focused": "Narrow warm headlamp beam",
		"wide": "Broad cool headlamp beam",
		"prismatic": "Wide violet headlamp beam",
		"deepheart": "Focused golden headlamp beam",
	}.get(option, "Headlamp beam: %s" % option.capitalize())


static func _workshop_description(workshop_id: String) -> String:
	match workshop_id:
		"tool_forge": return "Break tougher rock, strike faster and reach farther with every mining tool."
		"light_lab": return "Extends the headlamp and strengthens its response in the deepest darkness."
		"wardrobe": return "Unlocks complete expedition silhouettes without changing combat balance."
		"treasure_chamber": return "Draws loose discoveries in from farther away and makes every site cache more rewarding."
		"lift_workshop": return "Your mole prepares Tunnel Home faster. Resume mining where your last expedition ended."
	return "Permanent Hub workshop."


static func _workshop_upgrade_subtitle(workshop_id: String) -> String:
	return {
		"tool_forge": "Stronger strikes. Faster mining.", "light_lab": "Reveal more of the mountain",
		"wardrobe": "Unlock another expedition outfit",
	}.get(workshop_id, "Permanent workshop upgrade")


static func _workshop_level_unlock(workshop_id: String, level: int) -> String:
	var options: = _all_workshop_options(workshop_id)
	if level > 0 and level <= options.size():
		return "Level %d unlocks %s." % [level, String(options[level - 1]).replace("_", " ").capitalize()]
	return "Level %d strengthens the workshop effect." % level


static func _resource_name(resource_id: String) -> String:
	var rock: Dictionary = Dictionary(GameData.data.ROCK_TYPES.get(resource_id, {}))
	return String(rock.get("label", resource_id.replace("_", " ").capitalize()))


static func _resource_texture(resource_id: String) -> String:
	var path: = "res://assets/drops/%s-drop.png" % resource_id
	if ResourceLoader.exists(path):
		return path
	var fallback: = String(ENDLESS_RESOURCE_TEXTURES.get(resource_id, ""))
	return fallback if not fallback.is_empty() and ResourceLoader.exists(fallback) else ""


static func depth_forge_config(mine_id: String) -> Dictionary:
	var status: Dictionary=RunState.drill_upgrade_status()
	var recipe: Dictionary=status.get("recipe",{})
	var next: Dictionary=recipe.get("drill",RunState.next_drill())
	var current: Dictionary=RunState.current_drill()
	if current.is_empty():
		current=RunState.current_pickaxe()
	current=RunState.attune_tool_with_starforge(current)
	var next_stats: Dictionary=RunState.attune_tool_with_starforge(next)
	var costs: Array=[]
	if not recipe.is_empty():
		costs.append(_cost("gold","Gold",RunState.gold,int(recipe.get("gold",0)),GOLD_ICON))
		for requirement in Array(recipe.get("requirements",[])):
			var kind: String=String(requirement.type)
			costs.append(_cost(kind,_resource_name(kind),int(RunState.cargo.get(kind,0)),int(requirement.amount),_resource_texture(kind)))
	var names: Dictionary={"mossMine":"Rootwound","moonMine":"Prismatic","emberMine":"Molten","starMine":"Voidstar"}
	var title: String=String(next.get("name","Deepcore Mastered"))
	var level: int=int(recipe.get("level",RunState.drill_level))
	var texture: String=["res://assets/tools/pickaxe-ember.png","res://assets/tools/drill-burrower.png","res://assets/tools/drill-pulse.png","res://assets/tools/drill-deepcore.png"][clampi(level,0,3)]
	var ready: bool=bool(status.get("ready",false))
	return {"panel_id":"tool_forge","title":"%s Drill Forge" % String(names.get(mine_id,"Depth 2")),"subtitle":"Tools for the deeper tunnels","catalog_label":"Next drill","items":[{
		"id":"depth:drill","title":title,"texture":texture,
		"description":"All three drills forged. Your selected Starforge core stays active." if next.is_empty() else "A permanent drill upgrade. The selected Starforge core stays active.",
		"stats":[] if next.is_empty() else [{"id":"power","label":"POWER","current":str(current.get("power",1)),"next":str(next_stats.get("power",1))},{"id":"cooldown","label":"STRIKE TIME","current":"%.2fs" % float(current.get("cooldown",0.72)),"next":"%.2fs" % float(next_stats.get("cooldown",0.72))}],
		"costs":costs,"affordable":ready or next.is_empty(),"current":next.is_empty(),"state_label":"Mastered" if next.is_empty() else "", "action_enabled":ready,"action_label":"Forge drill" if not next.is_empty() else "Mastered",
		"locked":not RunState.has_deep_tool(),"locked_reason":"Forge a Starforge core first",
		"future_unlock":"A stronger drill opens the next sealed passage" if not next.is_empty() else "Explore Voidstar for the Singularity Core",
	}]}


static func _wardrobe_config(status: Dictionary, selection: Dictionary) -> Dictionary:
	var level: int = int(status.get("level", 1))
	var current: String = String(selection.get("current", "miner"))
	var names: Array[String] = ["Miner Green", "Expedition Blue", "Archivist Sand", "Starweave Violet", "Deepheart Red"]
	var descriptions: Array[String] = [
		"The original forest-green mining clothes.",
		"Ocean-blue clothes for your next expedition.",
		"Muted sand-colored clothes for the relic collector.",
		"Violet clothes inspired by Starfall crystals.",
		"Deep red clothes inspired by the heart of the mine.",
	]
	var items: Array = []
	for i in RunState.ENDLESS_OUTFIT_IDS.size():
		var outfit: String = String(RunState.ENDLESS_OUTFIT_IDS[i])
		var locked: bool = i + 1 > level
		var next: bool = i == level
		var worn: bool = outfit == current
		var item: Dictionary = {
			"id": "workshop:equip:" + outfit,
			"title": names[i], "subtitle": "Clothing color · cosmetic only",
			"outfit_preview": outfit,
			"description": descriptions[i],
			"equipped": worn, "locked": locked, "affordable": not locked,
			"action_enabled": not worn, "action_label": "Wearing" if worn else "Wear outfit",
			"locked_reason": "Unlock earlier colors first. Requires Wardrobe level %d." % (i + 1),
			"footer_text": "Currently wearing" if worn else "Free to switch" if not locked else "Not unlocked",
			"future_unlock_label": "Unlock requirement" if locked and not next else "Your outfit",
			"future_unlock": "Unlock earlier colors first. Requires Wardrobe level %d." % (i + 1) if locked and not next else "Changes clothing color only. Your helmet, glasses, tool and mining stats stay the same.",
			"total": {"label": "Outfit", "value": "Wearing" if worn else "Owned" if not locked else "Level %d" % (i + 1), "ready": not locked},
		}
		# The next color is also the upgrade: one card, one real unlock, no duplicate entry.
		if next:
			var upgrade: Dictionary = Dictionary(status.get("next_upgrade", {}))
			if not upgrade.is_empty():
				var resource: String = String(upgrade.resource)
				item.merge({
					"id": "workshop:upgrade", "locked": false,
					"subtitle": "Unlock this clothing color · Wardrobe level %d" % (i + 1),
					"equipped": false, "action_enabled": true,
					"affordable": bool(status.get("ready_to_upgrade", false)),
					"action_label": "Unlock outfit", "footer_text": "Unlocks permanently · then tap Wear outfit",
					"costs": [_cost(resource, _resource_name(resource), int(RunState.cargo.get(resource, 0)), int(upgrade.cost), _resource_texture(resource))],
					"total": {"label": "Wardrobe", "value": "%d > %d" % [level, i + 1], "ready": bool(status.get("ready_to_upgrade", false))},
				}, true)
		items.append(item)
	return {
		"panel_id": "workshop:wardrobe", "title": "Wardrobe",
		"subtitle": "%d / 5 colors unlocked · Preview, then wear" % level,
		"catalog_label": "Clothing colors", "items": items,
		"selected_item_id": "workshop:equip:" + current,
		"primary_action_visible": true,
	}


static func _light_lab_config(status: Dictionary, selection: Dictionary) -> Dictionary:
	var level: int = int(status.get("level", 1))
	var current: String = String(selection.get("current", "standard"))
	var items: Array = []
	var upgrade: Dictionary = Dictionary(status.get("next_upgrade", {}))
	if not upgrade.is_empty():
		var resource: String = String(upgrade.resource)
		items.append({
			"id": "workshop:upgrade", "title": "Brighter, farther light",
			"description": "Upgrade every beam. Compare Current and Upgraded in the cave preview.",
			"light_preview": current, "light_level": level, "compare_level": level + 1,
			"stats": _workshop_stats("light_lab", level, level + 1),
			"costs": [_cost(resource, _resource_name(resource), int(RunState.cargo.get(resource, 0)), int(upgrade.cost), _resource_texture(resource))],
			"affordable": bool(status.get("ready_to_upgrade", false)), "action_label": "Upgrade light",
			"future_unlock_label": "Also unlocks",
			"future_unlock": _workshop_level_unlock("light_lab", level + 1),
		})
	var notes: Dictionary = {
		"standard": "Balanced beam for everyday mining.",
		"focused": "24% narrower than Standard, with a warmer tint. Same reach and brightness.",
		"wide": "28% wider than Standard, with a cooler tint. Same reach and brightness.",
		"prismatic": "10% wider than Standard, with a violet tint. Same reach and brightness.",
		"deepheart": "8% narrower than Standard, with a golden tint. Same reach and brightness.",
	}
	for i in RunState.ENDLESS_LIGHT_STYLE_IDS.size():
		var style: String = String(RunState.ENDLESS_LIGHT_STYLE_IDS[i])
		var locked: bool = i + 1 > level
		items.append({
			"id": "workshop:equip:" + style, "title": style.capitalize(),
			"description": String(notes[style]), "light_preview": style, "light_level": level,
			"equipped": style == current, "locked": locked,
			"affordable": not locked, "action_enabled": style != current,
			"action_label": "Equipped" if style == current else "Use beam",
			"future_unlock_label": "Unlock requirement" if locked else "Your lamp · Level %d" % level,
			"future_unlock": "Upgrade Light Lab to level %d to use this beam." % (i + 1) if locked else "Range +%d%% · Brightness +%d%%. Owned beams are free to switch." % [roundi((RunState.light_range_for_level(level)-1)*100), roundi((RunState.light_energy_for_level(level)-1)*100)],
		})
	return {"panel_id": "workshop:light_lab", "title": "Light Lab", "subtitle": "Level %d / 5 · Preview your headlamp in the cave" % level, "catalog_label": "Headlamp beams", "items": items, "selected_item_id": "workshop:equip:" + current}
