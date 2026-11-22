extends RefCounted

const SKILLS := preload("res://assets/ui/actions/skills.png")
const TALK := preload("res://assets/ui/actions/talk.png")
const DOWN := preload("res://assets/ui/actions/descend.png")
const UP := preload("res://assets/ui/actions/ascend.png")
const EXIT := preload("res://assets/ui/actions/exit.png")
const PORTAL := preload("res://assets/ui/actions/portal.png")
const LOCK := preload("res://assets/ui/actions/lock.png")
const PARCEL := preload("res://assets/ui/actions/parcel.png")
const SEARCH := preload("res://assets/ui/actions/search.png")
const ROPE := preload("res://assets/ui/actions/rope.png")
const RELIC := preload("res://assets/ui/actions/relic.png")
const POWER := preload("res://assets/ui/actions/power.png")
const STEADY := preload("res://assets/ui/actions/steady.png")
const BOOST := preload("res://assets/ui/actions/boost.png")
const TUNE := preload("res://assets/ui/actions/tune.png")
const UPGRADE := preload("res://assets/ui/actions/upgrade.png")
const TREASURY := preload("res://assets/ui/actions/treasury.png")
const HUB := preload("res://assets/ui/actions/hub.png")
const WARDROBE := preload("res://assets/ui/actions/wardrobe.png")
const LANTERN := preload("res://assets/ui/actions/lantern.png")
const ANVIL := preload("res://assets/ui/tool-forge-approved-v1.png")
const TOOLS := preload("res://assets/ui/hud-build-v1.png")
const GOLD := preload("res://assets/ui/gold-bars-v1.png")
const MOLE := preload("res://assets/companion/mole-hud.png")

const BY_ACTION := {
	"TALK": TALK,
	"DESCEND": DOWN, "DEEPER": DOWN, "ASCEND": UP, "EXIT": EXIT, "RETURN": EXIT,
	"OPEN": PORTAL, "SEALED": LOCK,
	"SELL": GOLD, "SELL ORE": GOLD, "SELLING": GOLD,
	"FORGE": ANVIL, "FORGING": ANVIL, "TOOL FORGE": ANVIL,
	"BUILD": TOOLS, "WORKSHOP": TOOLS, "UPGRADE": UPGRADE,
	"DELIVER": PARCEL, "LOAD": PARCEL, "LOAD ORE": PARCEL,
	"BROWSE": SEARCH, "INSPECT": SEARCH,
	"ATTACH ROPE": ROPE, "ATTACH": ROPE, "TUNNELS": PORTAL,
	"PLACE": RELIC, "RELICS": RELIC, "ATTUNE": RELIC, "ATTUNING": RELIC,
	"POWER": POWER, "STABILIZE": STEADY, "OVERLOAD": BOOST, "TUNING": TUNE,
	"TREASURY": TREASURY, "HUB": HUB, "TUNNEL HOME": MOLE, "HOME": MOLE,
	"WARDROBE": WARDROBE, "CUSTOMIZE": WARDROBE, "LIGHT LAB": LANTERN,
}


static func for_action(label: String) -> Texture2D:
	return BY_ACTION.get(label.get_slice("\n", 0).strip_edges().to_upper()) as Texture2D
