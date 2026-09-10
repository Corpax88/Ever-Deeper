class_name MoleSkills
extends RefCounted

const SKILLS: Array[Dictionary] = [
	{"id":"lantern","name":"Little Lantern","detail":"A warm helmet beam lights the tunnel beside you.","gold":0,"bond":0,"requires":""},
	{"id":"fetch","name":"Fetch","detail":"Automatically collects nearby loose ore into your backpack and stays close as you move. No commands needed.","gold":0,"bond":0,"requires":""},
	{"id":"trailrunner","name":"Trailrunner","detail":"Runs 60% faster while fetching and following. Faster feet bring ore back sooner.","gold":35,"bond":5,"requires":"fetch"},
	{"id":"big_paws","name":"Big Paws","detail":"Scoops up a whole nearby cluster with more than triple the pickup reach. Works automatically.","gold":60,"bond":10,"requires":"fetch"},
	{"id":"ore_nose","name":"Ore Nose","detail":"Sniffs for exposed ore every 10 seconds while exploring and lights a reachable vein nearby. Returns to help when you start mining.","gold":90,"bond":15,"requires":"big_paws"},
	{"id":"long_beam","name":"Long Beam","detail":"Twice the helmet-light reach, so you can see farther down the tunnel. Always on after learning.","gold":75,"bond":12,"requires":"lantern"},
	{"id":"shake","name":"Earthshaker","detail":"Automatically helps at the wall you are mining: one shake opens up to 2×2 ordinary cells. 8 second recharge. Respects sealed gates and bedrock.","gold":140,"bond":25,"requires":"big_paws"},
	{"id":"teamwork","name":"Teamwork","detail":"Automatically helps with one ordinary wall cell every 2.5 seconds between Earthshaker uses. Stops digging when you do.","gold":210,"bond":35,"requires":"shake"},
	{"id":"echo","name":"Echo Scout","detail":"Automatically points the way deeper as you explore new ground. The hint lasts 20 seconds without interrupting your movement or mining.","gold":170,"bond":25,"requires":"long_beam"},
	{"id":"homeward","name":"Tunnel Home","detail":"Choose when to go home; your mole handles the tunnel and brings your attached relic. Your dig site is saved. Ready when the Deepheart is restored; elsewhere, leads toward the exit.","gold":240,"bond":40,"requires":"echo"},
]

static func has_skill(id: String) -> bool:
	if id == "homeward" and bool(RunState.victory): return true
	return id in ["lantern","fetch"] or int(Dictionary(RunState.overhaul_progress.get("skills",{})).get(id,0)) == 1

static func bond() -> int:
	return int(RunState.overhaul_progress.get("companion_xp",0))

static func earn(amount: int) -> void:
	if amount <= 0: return
	RunState.overhaul_progress["companion_xp"] = mini(10000000,bond() + amount)
	RunState.call("_state_changed")

static func learn(id: String) -> bool:
	if has_skill(id): return false
	for skill in SKILLS:
		if String(skill.id) != id: continue
		if not has_skill(String(skill.requires)) or RunState.gold < int(skill.gold) or bond() < int(skill.bond): return false
		RunState.gold -= int(skill.gold)
		RunState.overhaul_progress["companion_xp"] = bond()-int(skill.bond)
		var learned: Dictionary = RunState.overhaul_progress.get("skills",{})
		learned[id] = 1
		RunState.overhaul_progress["skills"] = learned
		RunState.call("_state_changed")
		return true
	return false

static func config(selected: String = "mole:fetch") -> Dictionary:
	var items: Array = []
	for skill in SKILLS:
		var id: String = String(skill.id)
		var owned: bool = has_skill(id)
		var locked: bool = not String(skill.requires).is_empty() and not has_skill(String(skill.requires))
		var ready: bool = not locked and RunState.gold >= int(skill.gold) and bond() >= int(skill.bond)
		var usable: bool = id in ["fetch","ore_nose","shake","echo","homeward"]
		var labels: Dictionary = {"fetch":"Recall companion","ore_nose":"Scout ore","shake":"Shake nearby wall","echo":"Find passage","homeward":"Tunnel Home" if RunState.current_scene == "endless" else "Lead me home"}
		items.append({
			"id":"mole:"+id,"title":skill.name,"description":skill.detail,
			"texture":"res://assets/companion/mole.png","current":owned,"state_label":"Learned" if owned else "Locked" if locked else "Ready" if ready else "Keep exploring",
			"locked":locked,"locked_reason":"Learn %s first" % String(skill.requires).replace("_"," ").capitalize(),
			"affordable":owned or ready,"action_enabled":usable if owned else ready,
			"action_label":String(labels.get(id,"Learned")) if owned else "Learn skill",
			"costs":[] if owned else [
				{"id":"gold","label":"Gold","owned":RunState.gold,"required":skill.gold,"icon_path":"res://assets/ui/gold-bars-v1.png"},
				{"id":"bond","label":"Bond","owned":bond(),"required":skill.bond,"icon_path":"res://assets/companion/mole-hud.png"}],
			"future_unlock_label":"Companion bond",
			"future_unlock":"%d bond available · earned by collecting ore together" % bond(),
		})
	return {"panel_id":"companion","title":"Your Mining Companion","subtitle":"Skills help automatically · collect ore to earn bond","catalog_label":"Skills","selected_item_id":selected,"items":items}
