extends Node2D

const DropVisuals = preload("res://scripts/world/drop_visuals.gd")

signal mossvein_entrance_reached
signal context_changed(context: String)
signal message_changed(message: String)

const PLAYER_RADIUS: = 24.0
const BOUNDARY_HALF_WIDTH: = 38.0
const GATE_Y: = 650.0
const GATE_HALF_GAP: = 118.0
const GATE_INTERACTION_RADIUS: = 132.0
const MOSS_MAIN_Y: = 650.0
const MOSS_CAMP_ANCHOR: = Vector2(240, MOSS_MAIN_Y)
const MOSS_QUARRY_FOCUS: = Vector2(550, MOSS_MAIN_Y)
const MOSS_MINE_BRANCH_JUNCTION: = Vector2(650, 680)
const MOSS_MINE_ENTRANCE: = Vector2(930, 900)
const MOSS_MINE_RETURN_POSITION: = Vector2(760, 790)
const DEFAULT_MINE_RETURN_OFFSET: = Vector2(126, 0)
const MOSS_WAYFARER_POSITION: = Vector2(800, 515)
const MOSS_MINE_RAMP_POSITION: = Vector2(620, 576)
const MOSS_MINE_RAMP_SCALE: = Vector2(0.304, 0.463)
const MOSS_RAMP_SOURCE_START: = Vector2(99, 225)
const MOSS_RAMP_SOURCE_END: = Vector2(1020, 700)
const MOSS_MINE_INTERACTION_RADIUS: = 164.0
const LATER_MINE_INTERACTION_RADIUS: = 132.0
const MOSS_GATE_ANCHOR: = Vector2(1110, MOSS_MAIN_Y)
const MOON_PREVIEW_ANCHOR: = Vector2(1240, MOSS_MAIN_Y)
const SURFACE_GATE_MAX_SIZE: = Vector2(220, 210)
const SURFACE_GATE_BOTTOM: = 105.0
const PORTAL_GENERATOR_SOURCE_RECT: = Rect2(181, 25, 150, 150)
const PORTAL_GENERATOR_MAX_SIZE: = Vector2(150, 150)
const PORTAL_GENERATOR_BOTTOM: = -118.0
const PORTAL_CROSSING_DURATION: = 0.42
const MOSS_PORTAL_LANTERN_POSITIONS: = [
	Vector2(1007, 503), Vector2(1180, 577),
]
const MOSS_MAIN_ROUTE: = [
	Vector2(30, 650), Vector2(210, 650), Vector2(410, 650),
	Vector2(620, 650), Vector2(840, 650), Vector2(990, 680), Vector2(1110, MOSS_MAIN_Y),
]
const MOSS_MINE_BRANCH_ROUTE: = [
	MOSS_MINE_BRANCH_JUNCTION,
	Vector2(700, 730),
	Vector2(760, 790),
	Vector2(820, 850),
	Vector2(875, 890),
	MOSS_MINE_ENTRANCE,
]
const LATER_MINE_BRANCH_ROUTES: = {
	"moonMine": [
		Vector2(1259, 651), Vector2(1303, 668), Vector2(1360, 710),
		Vector2(1426, 729), Vector2(1492, 759), Vector2(1558, 802),
		Vector2(1590, 840), Vector2(1590, 875),
	],
	"emberMine": [
		Vector2(2943, 690), Vector2(2943, 771), Vector2(2899, 779), Vector2(2831, 803),
		Vector2(2766, 854), Vector2(2693, 875), Vector2(2619, 886),
		Vector2(2552, 922), Vector2(2491, 961), Vector2(2480, 970),
	],
	"starMine": [
		Vector2(4021, 690), Vector2(4021, 806), Vector2(3931, 910), Vector2(3839, 956),
		Vector2(3742, 981), Vector2(3645, 985), Vector2(3554, 972),
		Vector2(3505, 1000),
	],
}
const LATER_MINE_RETURN_POSITIONS: = {



	"moonMine": Vector2(1515, 805),
	"emberMine": Vector2(2660, 820),
	"starMine": Vector2(3760, 820),
}
const MINE_ENTRANCE_MAX_SIZES: = {
	"mossMine": Vector2(190, 155),
	"moonMine": Vector2(190, 165),
	"emberMine": Vector2(192, 165),
	"starMine": Vector2(196, 165),
}
const MINE_ENTRANCE_BOTTOM_OFFSETS: = {
	"mossMine": 0.0,
	"moonMine": 18.0,
	"emberMine": 18.0,
	"starMine": 30.0,
}
const LATER_MAIN_ROUTES: = {
	"moonglass": [
		Vector2(1110, 650), Vector2(1270, 610), Vector2(1360, 650), Vector2(1540, 654),
		Vector2(1770, 648), Vector2(2010, 642), Vector2(2240, 650),
	],
	"emberdeep": [
		Vector2(2240, 650), Vector2(2460, 644), Vector2(2690, 654),
		Vector2(2910, 648), Vector2(3140, 642), Vector2(3360, 650),
	],
	"starfall": [
		Vector2(3360, 650), Vector2(3580, 644), Vector2(3810, 654),
		Vector2(4030, 648), Vector2(4250, 642), Vector2(4450, 650),
	],
}
const LATER_RESOURCE_ACCESS_ROUTES: = {
	"ember_fault": [
		Vector2(3260, 650), Vector2(3300, 760), Vector2(3290, 880),
		Vector2(3250, 1000), Vector2(3230, 1090), Vector2(3078, 1100), Vector2(2925, 1090),
	],
	"starfall_lattice": [
		Vector2(4250, 650), Vector2(4300, 770), Vector2(4290, 900),
		Vector2(4210, 1010), Vector2(4120, 1080), Vector2(3970, 1130), Vector2(3820, 1080),
	],
}
const MOSS_MAIN_ROUTE_HALF_WIDTH: = 44.0
const MOSS_BRANCH_ROUTE_HALF_WIDTH: = 42.0
const LATER_MAIN_ROUTE_HALF_WIDTH: = 44.0
const LATER_BRANCH_ROUTE_HALF_WIDTH: = 38.0
const RESOURCE_ACCESS_ROUTE_HALF_WIDTH: = 44.0
const MINE_LANDING_RADIUS: = 74.0
const SURFACE_MOTION_SUBSTEP: = 10.0
const SURFACE_ROUTE_STEER_ANGLE_STEP: = 8.0
const SURFACE_ROUTE_STEER_MAX_ANGLE: = 72.0
const SURFACE_ROUTE_STEER_REFINE_STEPS: = 3
const SURFACE_ROUTE_STEER_INPUT_RESET_DOT: = 0.55
const SURFACE_ROUTE_STEER_CENTER_TIE: = 0.5
const SURFACE_ROUTE_STEER_DIRECT_RESET_STEPS: = 10
const SURFACE_ROUTE_NEAREST_MARGIN: = MINE_LANDING_RADIUS + SURFACE_MOTION_SUBSTEP
const MOON_MINE_APPROACH_RECT: = Rect2(1250, 580, 440, 293)
const MOSS_CAMP_TERRACE_RECT: = Rect2(24, 390, 490, 360)
const MOSS_MINE_POCKET_RECT: = Rect2(790, 760, 280, 230)
const MOSS_WALKABLE_BOTTOM: = 1015.0
const PLAYER_START: = Vector2(240, 680)
const MOSS_CAMP_YARD_RECT: = Rect2(20, 370, 480, 330)
const MOSS_CAMP_CONNECTOR_RECT: = Rect2(185, 510, 110, 120)
const MOSS_WAYFARER_ACCESS_RECT: = Rect2(747, 494, 106, 178)
const MOSS_ORE_MOUNTAIN_POSITION: = Vector2(555, 600)
const MOSS_ORE_MOUNTAIN_FOCUS: = MOSS_QUARRY_FOCUS
const MOSS_ORE_MOUNTAIN_COLLISION_CENTER: = Vector2(555, 565)
const MOSS_ORE_MOUNTAIN_COLLISION_HALF_SIZE: = Vector2(198, 51)
const MOSS_ORE_MOUNTAIN_MINING_RANGE: = 132.0
const MOSS_ORE_MOUNTAIN_TARGET_HYSTERESIS: = 22.0
const MOSS_ORE_MOUNTAIN_INPUT_BUFFER: = 0.16
const MOSS_ORE_MOUNTAIN_MAX_HP: = 360
const MOSS_ORE_MOUNTAIN_REGROWTH_SECONDS: = 150.0
const MOSS_ORE_MOUNTAIN_FULL_COPPER_YIELD: = 24.0
const SURFACE_RESOURCE_MOUNTAIN_MAX_HP: = 360
const SURFACE_RESOURCE_MOUNTAIN_REGROWTH_SECONDS: = 150.0
const SURFACE_RESOURCE_MOUNTAIN_FULL_YIELD: = 24.0
const SURFACE_RESOURCE_MOUNTAIN_MINING_RANGE: = 132.0
const SURFACE_RESOURCE_MOUNTAIN_TARGET_HYSTERESIS: = 22.0
const SURFACE_RESOURCE_MOUNTAIN_HIT_DURATION: = 0.18
const SURFACE_RESOURCE_MOUNTAIN_COLLAPSE_DURATION: = 0.72
const MOSS_ENVIRONMENT_TICK: = 1.0 / 30.0
const MOSS_ENVIRONMENT_CULL_HALF_SIZE: = Vector2(430, 520)
const MOSS_GLOWMOTH_FPS: = 7.5
const MOSS_DRIFT_FPS: = 2.1
const LATER_SURFACE_LIFE_FPS: = 7.0
const LATER_SURFACE_DRIFT_FPS: = 2.0
const MOSS_FOOTSTEP_DISTANCE: = 72.0
const MOSS_FOOTSTEP_LIFETIME: = 0.42
const MOSS_MAX_RESPONSES: = 6
const SURFACE_VISUAL_ACTIVE_HALF_SIZE: = Vector2(560, 640)
const PORTAL_VISUAL_ACTIVE_HALF_SIZE: = Vector2(680, 640)
const SURFACE_PASSIVE_TICK: = 0.25
const SURFACE_DYNAMIC_VISUAL_TICK: = 1.0 / 30.0
const MOSS_GLOWMOTH_ANCHORS: = [
	Vector2(120, 180), Vector2(350, 340), Vector2(640, 150),
	Vector2(870, 330), Vector2(990, 1020), Vector2(760, 1190),
	Vector2(510, 880), Vector2(250, 1120), Vector2(840, 760),
]
const MOSS_DRIFT_ANCHORS: = [
	Vector2(155, 365), Vector2(510, 260), Vector2(800, 520),
	Vector2(950, 1035), Vector2(450, 1120),
]
const LATER_SURFACE_LIFE_SPECS: = {
	"moonglass": {
		"kind": "flyer",
		"anchors": [Vector2(1290, 250), Vector2(1510, 350), Vector2(1870, 260), Vector2(2110, 1060), Vector2(1810, 1160)],
		"size": 54.0,
		"color": Color(0.84, 0.96, 1.0, 0.86),
		"route": Vector2(26, 13),
	},
	"emberdeep": {
		"kind": "ground",
		"anchors": [Vector2(2350, 790), Vector2(2600, 845), Vector2(2860, 1080), Vector2(3230, 780)],
		"size": 62.0,
		"color": Color(1.0, 0.83, 0.61, 0.92),
		"route": Vector2(38, 3),
	},
	"starfall": {
		"kind": "flyer",
		"anchors": [Vector2(3460, 270), Vector2(3690, 390), Vector2(4040, 255), Vector2(4290, 1070), Vector2(3930, 1160)],
		"size": 68.0,
		"color": Color(0.91, 0.86, 1.0, 0.88),
		"route": Vector2(34, 16),
	},
}
const LATER_SURFACE_DRIFT_ANCHORS: = {
	"moonglass": [Vector2(1270, 440), Vector2(1570, 190), Vector2(1980, 500), Vector2(2110, 1100)],
	"emberdeep": [Vector2(2340, 470), Vector2(2700, 240), Vector2(3050, 510), Vector2(3250, 1110)],
	"starfall": [Vector2(3450, 460), Vector2(3750, 220), Vector2(4130, 500), Vector2(4380, 1110)],
}
const MOON_BLOOM_ID: = "moonglass_bloom"
const MOON_MOUNTAIN_ID: = "moonglass_mountain"
const MOON_BLOOM_NODE_POSITIONS: = [
	Vector2(1720, 650), Vector2(1820, 700), Vector2(1920, 650),
]
const MOON_BLOOM_CENTER: = Vector2(1820, 666.6667)
const MOON_BLOOM_PLATFORM_TOP_ANCHOR: = Vector2(1820, 748)
const MOON_BLOOM_PLATFORM_UNDERSIDE_ANCHOR: = Vector2(1820, 790)
const MOON_BLOOM_PLATFORM_APPROACH_CENTER: = Vector2(1900, 760)
const MOON_BLOOM_PLATFORM_LANDING_ANCHOR: = Vector2(1960, 770)
const MOON_BLOOM_PLATFORM_ACCESS_ROUTE: = [
	Vector2(1820, 748), Vector2(1900, 760), MOON_BLOOM_PLATFORM_LANDING_ANCHOR,
]
const MOON_BLOOM_NODE_CONTEXT_RADIUS: = 112.0
const MOON_BLOOM_NODE_MAX_HP: = 42
const MOON_BLOOM_TIME_LIMIT: = 18.0
const MOON_BLOOM_RESPAWN_SECONDS: = 32.0
const MOON_BLOOM_BONUS: = {"moonglass": 2, "starshard": 1}
const EMBER_FAULT_ID: = "ember_fault"
const EMBER_MOUNTAIN_ID: = "emberdeep_mountain"
const EMBER_FAULT_NODE_POSITIONS: = [
	Vector2(2925, 1090), Vector2(3078, 1120), Vector2(3230, 1090),
]
const EMBER_FAULT_CENTER: = Vector2(3077.6667, 1100)
const EMBER_FAULT_NODE_MAX_HP: = 74
const EMBER_FAULT_NODE_MAX_SHELL: = 32
const EMBER_FAULT_TIME_LIMIT: = 22.0
const EMBER_FAULT_RESPAWN_SECONDS: = 38.0
const EMBER_FAULT_BONUS: = {"emberstone": 3, "sunslag": 1}
const STARFALL_LATTICE_ID: = "starfall_lattice"
const STAR_MOUNTAIN_ID: = "starfall_mountain"
const STARFALL_LATTICE_NODE_POSITIONS: = [
	Vector2(3820, 1080), Vector2(3970, 1130), Vector2(4120, 1080),
]
const STARFALL_LATTICE_CENTER: = Vector2(3970, 1096.6667)
const STARFALL_LATTICE_NODE_MAX_HP: = 325
const STARFALL_LATTICE_NODE_MAX_SHELL: = 72
const STARFALL_LATTICE_TIME_LIMIT: = 20.0
const STARFALL_LATTICE_RESPAWN_SECONDS: = 42.0
const STARFALL_LATTICE_BONUS: = {"astralite": 3, "crownstone": 1}
const TIMED_SURFACE_NODE_CONTEXT_RADIUS: = 116.0
const STARFALL_HUB_LIFT_POSITION: = Vector2(4245, 650)
const STARFALL_HUB_LIFT_RADIUS: = 146.0
const STARFALL_HUB_APPROACH_RECT: = Rect2(4005, 472, 350, 156)
const ORE_DROP_FLIGHT_DURATION: = 0.62
const ORE_DROP_PICKUP_RADIUS: = 52.0
const ORE_DROP_COLLECT_DURATION: = 0.18
const LOOSE_RESOURCE_LIFETIME: = 50.0
const LOOSE_RESOURCE_FADE_SECONDS: = 3.0
const SURFACE_LOOSE_DROP_SOURCE_LIMIT: = 28
const SURFACE_LOOSE_DROP_TOTAL_LIMIT: = 72
const CHEST_INTERACT_RADIUS: = 108.0
const BASE_MODULE_INTERACT_RADIUS: = 118.0
const SURFACE_STATION_INTERACT_RADIUS: = 112.0
const SURFACE_STATION_APPROACH_OFFSET: = Vector2(0, 140)
const CHEST_DROP_PICKUP_RADIUS: = 132.0
const ORE_DROP_LANDING_OFFSETS: = [
	Vector2(-132, 18), Vector2(132, 18),
	Vector2(-98, 32), Vector2(98, 32),
	Vector2(-162, 50), Vector2(162, 50),
	Vector2(-62, 40), Vector2(62, 40),
	Vector2(-188, 58), Vector2(188, 58),
]
const MOON_DROP_LANDING_OFFSETS: = [
	Vector2(-152, -92), Vector2(-68, -126), Vector2(68, -126), Vector2(152, -92),
	Vector2(-162, 8), Vector2(-88, 104), Vector2(88, 104), Vector2(162, 8),
]

const MOSS_GROUND: = preload("res://assets/surface/mossvein-ground.png")
const MOSS_ENVIRONMENT_DECOR: = preload("res://assets/surface/mossvein-environment-decor.png")
const MOSS_ROOT_HOLLOW: = preload("res://assets/surface/mossvein-root-hollow.png")
const MOSS_MUSHROOM_CLUSTER: = preload("res://assets/surface/mossvein-mushroom-cluster.png")
const MOSS_MINE_RAMP: = preload("res://assets/surface/mossvein-mine-ramp.png")
const MOSS_GLOWMOTH: = preload("res://assets/ambient/mossvein-glowmoth.png")
const MOSS_DRIFT: = preload("res://assets/world-life/mossvein-drift.png")
const MOSS_RESPONSE: = preload("res://assets/world-life/mossvein-response.png")
const LATER_SURFACE_CREATURE_TEXTURES: = {
	"moonglass": preload("res://assets/ambient/moonglass-prism-moth.png"),
	"emberdeep": preload("res://assets/ambient/emberdeep-cinder-skink.png"),
	"starfall": preload("res://assets/ambient/starfall-astral-ray.png"),
}
const LATER_SURFACE_DRIFT_TEXTURES: = {
	"moonglass": preload("res://assets/world-life/moonglass-drift.png"),
	"emberdeep": preload("res://assets/world-life/emberdeep-drift.png"),
	"starfall": preload("res://assets/world-life/starfall-drift.png"),
}
const MOON_GROUND: = preload("res://assets/surface/moonglass-ground.png")
const EMBER_GROUND: = preload("res://assets/surface/emberdeep-ground.png")
const STAR_GROUND: = preload("res://assets/surface/starfall-ground.png")
const ROAD_TEXTURES: = {
	"mossvein": preload("res://assets/surface/road-mossvein.png"),
	"moonglass": preload("res://assets/surface/road-moonglass.png"),
	"emberdeep": preload("res://assets/surface/road-emberdeep.png"),
	"starfall": preload("res://assets/surface/road-starfall.png")
}
const ENTRANCE_TEXTURES: = {
	"mossMine": preload("res://assets/entrances/mossvein-entrance.png"),
	"moonMine": preload("res://assets/entrances/moonglass-entrance.png"),
	"emberMine": preload("res://assets/entrances/emberdeep-entrance.png"),
	"starMine": preload("res://assets/entrances/starfall-entrance.png")
}
const BOUNDARY_TEXTURES: = {
	"moonglass": preload("res://assets/surface/boundary-mossvein-moonglass-open.png"),
	"emberdeep": preload("res://assets/surface/boundary-moonglass-emberdeep.png"),
	"starfall": preload("res://assets/surface/boundary-emberdeep-starfall.png")
}
const LATER_BOUNDARY_SOURCE_RECTS: = {
	"emberdeep": Rect2(192, 0, 297, 1024),
	"starfall": Rect2(186, 0, 318, 1024),
}
const GATE_TEXTURES: = {
	"moonglass": preload("res://assets/surface/moonglass-gate.png"),
	"emberdeep": preload("res://assets/surface/emberdeep-seal.png"),
	"starfall": preload("res://assets/surface/starfall-seal.png")
}
const PORTAL_ARCH_TEXTURES: = {
	"moonglass": preload("res://assets/surface/moonglass-portal-arch-v2.png"),
	"emberdeep": preload("res://assets/surface/emberdeep-portal-arch-v1.png"),
	"starfall": preload("res://assets/surface/starfall-portal-arch-v1.png"),
}
const GATE_MARK_TEXTURES: = {
	"moonglass": preload("res://assets/surface/moonglass-open-threshold.png"),
	"emberdeep": preload("res://assets/surface/emberdeep-seal-mark.png"),
	"starfall": preload("res://assets/surface/starfall-seal-mark.png")
}
const PORTAL_SEAM_COLORS: = {
	"moonglass": {
		"source": Color("82ad62"),
		"destination": Color("69e8ff"),
	},
	"emberdeep": {
		"source": Color("69e8ff"),
		"destination": Color("ff6a2a"),
	},
	"starfall": {
		"source": Color("ff6a2a"),
		"destination": Color("a879ff"),
	},
}
const MOSS_CAMP_YARD: = preload("res://assets/surface/mossvein-camp-yard.png")
const MOSS_CAMP_PATH: = preload("res://assets/surface/mossvein-camp-path.png")
const MOON_MINE_APPROACH: = preload("res://assets/surface/moonglass-mine-approach-v1.png")
const EMBER_BRANCH: = preload("res://assets/surface/emberdeep-mine-path.png")
const STAR_BRANCH: = preload("res://assets/surface/starfall-mine-path.png")
const MOON_CRYSTALS: = preload("res://assets/surface/moonglass-crystals.png")
const MOON_BLOOM: = preload("res://assets/surface/moonglass-bloom-bed.png")
const EMBER_SLAG: = preload("res://assets/surface/emberdeep-slag-clusters.png")
const EMBER_FAULT: = preload("res://assets/surface/emberdeep-fault-bed.png")
const STAR_SHARDS: = preload("res://assets/surface/starfall-shard-clusters.png")
const STAR_LATTICE: = preload("res://assets/surface/starfall-lattice-bed.png")
const STARFORGE_STATION: = preload("res://assets/surface/starforge-station.png")
const STORAGE_CHEST: = preload("res://assets/surface/storage-chest.png")
const WAYFARER_SHOP: = preload("res://assets/surface/wayfarer-shop.png")
const SURFACE_CHEST_TEXTURES: = {
	"moss_supply": {
		"closed": preload("res://assets/surface/treasure-cache-closed.png"),
		"open": preload("res://assets/surface/treasure-cache-open.png"),
	},
	"moss_ironbound": {
		"closed": preload("res://assets/surface/treasure-cache-closed.png"),
		"open": preload("res://assets/surface/treasure-cache-open.png"),
	},
	"moon_cache": {
		"closed": preload("res://assets/surface/crystal-cache-closed.png"),
		"open": preload("res://assets/surface/crystal-cache-open.png"),
	},
	"moon_reliquary": {
		"closed": preload("res://assets/surface/moonglass-reliquary-closed.png"),
		"open": preload("res://assets/surface/moonglass-reliquary-open.png"),
	},
	"ember_cache": {
		"closed": preload("res://assets/surface/foundry-lockbox-closed.png"),
		"open": preload("res://assets/surface/foundry-lockbox-open.png"),
	},
	"ember_vault": {
		"closed": preload("res://assets/surface/ember-vault-closed.png"),
		"open": preload("res://assets/surface/ember-vault-open.png"),
	},
	"star_cache": {
		"closed": preload("res://assets/surface/astral-cache-closed.png"),
		"open": preload("res://assets/surface/astral-cache-open.png"),
	},
	"star_coffer": {
		"closed": preload("res://assets/surface/celestial-coffer-closed.png"),
		"open": preload("res://assets/surface/celestial-coffer-open.png"),
	},
}
const MOSS_ORE_MOUNTAIN: = preload("res://assets/surface/v2/copper-mountain-0.png")
const MOSS_ORE_MOUNTAIN_DAMAGE_1: = preload("res://assets/surface/v2/copper-mountain-1.png")
const MOSS_ORE_MOUNTAIN_DAMAGE_2: = preload("res://assets/surface/v2/copper-mountain-2.png")
const MOSS_ORE_MOUNTAIN_DAMAGE_3: = preload("res://assets/surface/v2/copper-mountain-3.png")
const MOON_ORE_MOUNTAIN: = preload("res://assets/surface/moonglass-ore-mountain-v1.png")
const MOON_ORE_MOUNTAIN_DAMAGE_1: = preload("res://assets/surface/moonglass-ore-mountain-damaged-1.png")
const MOON_ORE_MOUNTAIN_DAMAGE_2: = preload("res://assets/surface/moonglass-ore-mountain-damaged-2.png")
const MOON_ORE_MOUNTAIN_DAMAGE_3: = preload("res://assets/surface/moonglass-ore-mountain-damaged-3.png")
const EMBER_ORE_MOUNTAIN: = preload("res://assets/surface/emberdeep-ore-mountain-v1.png")
const EMBER_ORE_MOUNTAIN_DAMAGE_1: = preload("res://assets/surface/emberdeep-ore-mountain-damaged-1.png")
const EMBER_ORE_MOUNTAIN_DAMAGE_2: = preload("res://assets/surface/emberdeep-ore-mountain-damaged-2.png")
const EMBER_ORE_MOUNTAIN_DAMAGE_3: = preload("res://assets/surface/emberdeep-ore-mountain-damaged-3.png")
const STAR_ORE_MOUNTAIN: = preload("res://assets/surface/starfall-ore-mountain-v1.png")
const STAR_ORE_MOUNTAIN_DAMAGE_1: = preload("res://assets/surface/starfall-ore-mountain-damaged-1.png")
const STAR_ORE_MOUNTAIN_DAMAGE_2: = preload("res://assets/surface/starfall-ore-mountain-damaged-2.png")
const STAR_ORE_MOUNTAIN_DAMAGE_3: = preload("res://assets/surface/starfall-ore-mountain-damaged-3.png")
const COPPER_DROP: = preload("res://assets/drops/copper-drop.png")
const GOLD_DROP: = preload("res://assets/drops/gold-drop-clean-v2.png")
const MOSS_IMPACT: = preload("res://assets/world-life/mossvein-impact.png")
const MOON_BLOOM_NODE: = preload("res://assets/moonglass/moonglass-node.png")
const MOONGLASS_DROP: = preload("res://assets/drops/moonglass-drop.png")
const STARSHARD_DROP: = preload("res://assets/drops/starshard-drop.png")
const MOON_IMPACT: = preload("res://assets/world-life/moonglass-impact.png")
const MOON_RESPONSE: = preload("res://assets/world-life/moonglass-response.png")
const EMBERSTONE_NODE: = preload("res://assets/emberdeep/emberstone-node.png")
const EMBERSTONE_DROP: = preload("res://assets/drops/emberstone-drop.png")
const SUNSLAG_DROP: = preload("res://assets/drops/sunslag-drop.png")
const EMBER_IMPACT: = preload("res://assets/world-life/emberdeep-impact.png")
const EMBER_RESPONSE: = preload("res://assets/world-life/emberdeep-response.png")
const ASTRALITE_NODE: = preload("res://assets/starfall/astralite-node.png")
const ASTRALITE_DROP: = preload("res://assets/drops/astralite-drop.png")
const CROWNSTONE_DROP: = preload("res://assets/drops/crownstone-drop.png")
const STAR_IMPACT: = preload("res://assets/world-life/starfall-impact.png")
const STAR_RESPONSE: = preload("res://assets/world-life/starfall-response.png")
const STARFALL_HUB_LIFT: = preload("res://assets/voidstar/depth-portal.png")
const ORE_MOUNTAIN_CUTOUT_SHADER: = preload("res://shaders/ore_mountain_cutout.gdshader")
const BOUNDARY_CHECKER_CUTOUT_SHADER: = preload("res://shaders/boundary_checker_cutout.gdshader")
const WORLD_TRANSITION_VISUAL_SCENE: = preload("res://scenes/world/world_transition_visual.tscn")
const SURFACE_RESOURCE_MOUNTAIN_IDS: = [
	MOON_MOUNTAIN_ID, EMBER_MOUNTAIN_ID, STAR_MOUNTAIN_ID,
]
const SURFACE_RESOURCE_MOUNTAIN_TEXTURES: = {
	MOON_MOUNTAIN_ID: [MOON_ORE_MOUNTAIN, MOON_ORE_MOUNTAIN_DAMAGE_1, MOON_ORE_MOUNTAIN_DAMAGE_2, MOON_ORE_MOUNTAIN_DAMAGE_3],
	EMBER_MOUNTAIN_ID: [EMBER_ORE_MOUNTAIN, EMBER_ORE_MOUNTAIN_DAMAGE_1, EMBER_ORE_MOUNTAIN_DAMAGE_2, EMBER_ORE_MOUNTAIN_DAMAGE_3],
	STAR_MOUNTAIN_ID: [STAR_ORE_MOUNTAIN, STAR_ORE_MOUNTAIN_DAMAGE_1, STAR_ORE_MOUNTAIN_DAMAGE_2, STAR_ORE_MOUNTAIN_DAMAGE_3],
}
const SURFACE_RESOURCE_MOUNTAIN_COLLISIONS: = {
	MOON_MOUNTAIN_ID: {"center": Vector2(1665, 490), "half_size": Vector2(168, 88)},
	EMBER_MOUNTAIN_ID: {"center": Vector2(2820, 495), "half_size": Vector2(185, 87)},
	STAR_MOUNTAIN_ID: {"center": Vector2(3900, 492), "half_size": Vector2(192, 90)},
}
const SURFACE_RESOURCE_MOUNTAIN_CONFIGS: = {
	MOON_MOUNTAIN_ID: {
		"anchor": Vector2(1665, 635), "max_size": Vector2(420, 275), "unlock": "area_unlocked",
		"primary": "moonglass", "rare": "starshard", "impact": MOON_IMPACT, "response": MOON_RESPONSE,
		"drop_textures": {"moonglass": MOONGLASS_DROP, "starshard": STARSHARD_DROP},
		"label": "Moonglass Mountain",
	},
	EMBER_MOUNTAIN_ID: {
		"anchor": Vector2(2820, 650), "max_size": Vector2(540, 370), "unlock": "emberdeep_unlocked",
		"primary": "emberstone", "rare": "sunslag", "impact": EMBER_IMPACT, "response": EMBER_RESPONSE,
		"drop_textures": {"emberstone": EMBERSTONE_DROP, "sunslag": SUNSLAG_DROP},
		"label": "Emberdeep Mountain",
	},
	STAR_MOUNTAIN_ID: {
		"anchor": Vector2(3900, 650), "max_size": Vector2(560, 390), "unlock": "fourth_unlocked",
		"primary": "astralite", "rare": "crownstone", "impact": STAR_IMPACT, "response": STAR_RESPONSE,
		"drop_textures": {"astralite": ASTRALITE_DROP, "crownstone": CROWNSTONE_DROP},
		"label": "Starfall Mountain",
	},
}


const GROUND_RECTS: = {
	"mossvein": Rect2(0, 0, 1134, 1280),
	"moonglass": Rect2(1110, 0, 1130, 1280),
	"emberdeep": Rect2(2240, 0, 1120, 1280),
	"starfall": Rect2(3360, 0, 1120, 1280)
}
const ROAD_RECTS: = {
	"mossvein": Rect2(-40, 550, 1190, 220),
	"moonglass": Rect2(1070, 525, 1190, 240),
	"emberdeep": Rect2(2200, 525, 1190, 240),
	"starfall": Rect2(3320, 525, 1190, 240)
}
const BOUNDARIES: = [
	{"id": "moonglass", "x": 1110.0, "station": "gate", "unlock_key": "area_unlocked"},
	{"id": "emberdeep", "x": 2240.0, "station": "emberGate", "unlock_key": "emberdeep_unlocked"},
	{"id": "starfall", "x": 3360.0, "station": "starfallGate", "unlock_key": "fourth_unlocked"}
]
const MINE_IDS: = WorldCatalog.MINE_ORDER

@onready var player: CharacterBody2D = $Player
@onready var surface_parallax: SurfaceParallax = $SurfaceParallax

var entrance_position: = Vector2.ZERO
var active_context: = ""
var moss_camp_yard_sprite: Sprite2D
var moss_camp_connector_sprite: Sprite2D
var moss_wayfarer_access_sprite: Sprite2D
var moss_mine_branch_sprite: Sprite2D
var surface_mine_branch_sprites: Dictionary = {}
var surface_mine_branch_backing_sprites: Dictionary = {}
var entrance_nodes: Dictionary = {}
var portal_transitions: Dictionary = {}
var portal_generator_nodes: Dictionary = {}
var boundary_backing_nodes: Dictionary = {}
var gate_unlock_state: Dictionary = {}
var moonglass_transition: WorldTransitionVisual
var ore_mountain_sprite: Sprite2D
var ore_mountain_blend_sprite: Sprite2D
var ore_mountain_base_scale: = Vector2.ONE
var ore_mountain_base_position: = Vector2.ZERO
var ore_mountain_impacts: Array[Dictionary] = []
var ore_mountain_hp: = MOSS_ORE_MOUNTAIN_MAX_HP
var ore_mountain_growth_buffer: = 0.0
var ore_mountain_copper_yield_buffer: = 0.0
var ore_mountain_gold_ready: = true
var ore_mountain_last_growth_unix: = 0
var ore_mountain_hit_flash: = 0.0
var ore_mountain_swing_active: = false
var ore_mountain_swing_elapsed: = 0.0
var ore_mountain_swing_duration: = 0.72
var ore_mountain_swing_hit: = false
var ore_mountain_swing_target: = Vector2(600, 615)
var ore_mountain_input_buffer: = 0.0
var ore_mountain_hit_count: = 0
var ore_drops: Array[Dictionary] = []
var ore_mountain_collapse_elapsed: = 0.0
var ore_mountain_collapse_duration: = 0.72
var gold_glow_texture: GradientTexture2D
var moon_bloom_sprites: Array[Sprite2D] = []
var moon_bloom_glows: Array[Sprite2D] = []
var moon_bloom_base_scales: Array[Vector2] = []
var moon_bloom_nodes: Array[Dictionary] = []
var moon_bloom_status: = "idle"
var moon_bloom_timer: = 0.0
var moon_bloom_completions: = 0
var moon_bloom_updated_unix: = 0
var moon_bloom_swing_active: = false
var moon_bloom_swing_elapsed: = 0.0
var moon_bloom_swing_duration: = 0.72
var moon_bloom_swing_hit: = false
var moon_bloom_target_index: = -1
var moon_bloom_hit_count: = 0
var moon_bloom_visual_time: = 0.0
var moon_bloom_drops: Array[Dictionary] = []
var moon_bloom_effects: Array[Dictionary] = []
var moon_glow_texture: GradientTexture2D
var timed_surface_veins: Dictionary = {}
var surface_resource_mountains: Dictionary = {}
var surface_resource_mountain_impacts: Array[Dictionary] = []
var surface_resource_mountain_drops: Array[Dictionary] = []
var surface_material_sprays: Array[Dictionary] = []
var moon_bloom_platform_nodes: Array[Sprite2D] = []
var timed_surface_glow_textures: Dictionary = {}
var starfall_hub_lift_sprite: Sprite2D
var starfall_hub_lift_glow: Sprite2D
var starfall_hub_lift_base_scale: = Vector2.ONE
var starfall_hub_lift_visual_time: = 0.0
var external_mine_held: = false
var surface_chest_nodes: Dictionary = {}
var surface_storage_nodes: Dictionary = {}
var chest_loot_drops: Array[Dictionary] = []
var chest_visual_state: Dictionary = {}
var storage_visual_signature: = ""
var chest_loot_signature: = ""
var moss_decor_sprites: Array[Sprite2D] = []
var moss_glowmoths: Array[Dictionary] = []
var moss_drifts: Array[Dictionary] = []
var later_surface_creatures: Array[Dictionary] = []
var later_surface_drifts: Array[Dictionary] = []
var moss_footstep_responses: Array[Dictionary] = []
var moss_environment_time: = 0.0
var moss_environment_accumulator: = 0.0
var moss_footstep_distance: = 0.0
var moss_last_footstep_position: = PLAYER_START
var moss_response_serial: = 0
var moss_reduced_motion: = false
var moss_portal_boundary_ridge: Sprite2D
var moss_portal_clearing_nodes: Array[CanvasItem] = []
var moss_portal_glows: Array[Dictionary] = []
var ore_mountain_passive_elapsed: = 0.0
var moon_bloom_passive_elapsed: = 0.0
var timed_surface_passive_elapsed: = {
	EMBER_FAULT_ID: 0.0,
	STARFALL_LATTICE_ID: 0.0,
}
var mobile_active_resource_updates: = 0
var mobile_passive_resource_updates: = 0
var mobile_portal_ticks: = 0
var mobile_portal_ticks_skipped: = 0
var mobile_dynamic_visual_updates: = 0
var mobile_dynamic_visual_updates_skipped: = 0
var surface_route_steer_events: = 0
var surface_last_motion_direction: = Vector2.RIGHT
var surface_route_steer_sign: = 0.0
var surface_route_steer_input_direction: = Vector2.ZERO
var surface_route_direct_steps: = 0
var surface_route_corridors: Array[Dictionary] = []
var surface_route_broadphase_rejects: = 0
var surface_route_segment_checks: = 0
var surface_drop_budget_enforcing: = false
var surface_drop_budget_peak: = 0
var surface_drop_budget_trimmed: = 0
var surface_drop_budget_auto_collected: = 0
var surface_drop_budget_serial: = 0
var surface_drop_budget_trimmed_by_source: Dictionary = {}
var run_state_refresh_pending: = false


func _ready() -> void :
	player.camera.zoom = Vector2.ONE * 0.86
	player.camera.player_screen_y_ratio = 0.68
	entrance_position = _mine_entrance("mossMine")
	_build_surface_route_corridors()
	_build_surface_art()
	_build_mossvein_environment()
	_build_later_surface_life()
	surface_parallax.set_reduced_motion(moss_reduced_motion)
	_build_ore_mountain()
	_build_moonglass_resource()
	_build_timed_surface_resources()
	_build_stations()
	_build_surface_chests()
	_refresh_surface_storage_nodes()
	_build_starfall_hub_lift()
	_build_entrances()
	_build_gates()
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		gate_unlock_state[String(boundary.id)] = _raw_boundary_unlocked(boundary)
	player.configure(PLAYER_START, _world_size(), _movement_speed(), _resolve_motion)
	moss_last_footstep_position = PLAYER_START
	player.moved.connect(_on_player_moved)
	RunState.changed.connect(_on_run_state_changed)
	_refresh_unlock_visibility()
	_evaluate_context(player.global_position)
	queue_redraw()


func _process(delta: float) -> void :
	var safe_delta: = maxf(0.0, delta)
	var now_unix: = int(Time.get_unix_time_from_system())




	for transition_value in portal_transitions.values():
		var transition: WorldTransitionVisual = transition_value as WorldTransitionVisual
		if not is_instance_valid(transition):
			continue


		if transition.needs_runtime_tick(player.global_position, PORTAL_VISUAL_ACTIVE_HALF_SIZE):
			transition._process(safe_delta)
			mobile_portal_ticks += 1
		else:
			mobile_portal_ticks_skipped += 1
	_update_mossvein_environment(safe_delta)
	_update_mobile_surface_resources(safe_delta, now_unix)
	_update_surface_material_sprays(safe_delta)
	_update_chest_loot_drops(safe_delta)
	_update_starfall_hub_lift(safe_delta)


func set_active(enabled: bool) -> void :
	if not enabled and is_node_ready():
		_flush_surface_passive_simulation()
	if enabled:
		_catch_up_ore_mountain()
		_catch_up_surface_resource_mountains()
		_catch_up_moonglass_resource()
		_catch_up_timed_surface_resources()
	visible = enabled
	process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	player.control_enabled = enabled
	player.camera.enabled = enabled
	if enabled:
		player.prepare_visual_cache()
	else:
		player.release_visual_cache()
	external_mine_held = false
	ore_mountain_input_buffer = 0.0
	if enabled:
		if run_state_refresh_pending:
			run_state_refresh_pending = false
			_refresh_from_run_state()
		player.camera.make_current()
		player.camera.reset_smoothing()
		_evaluate_context(player.global_position)


func set_mine_held(held: bool) -> void :
	external_mine_held = held
	if held:
		ore_mountain_input_buffer = MOSS_ORE_MOUNTAIN_INPUT_BUFFER


func return_from_mine(mine_id: String = "mossMine") -> void :
	var entrance: = _mine_entrance(mine_id)
	player.global_position = _mine_return_position(mine_id)
	surface_last_motion_direction = (player.global_position - entrance).normalized()
	_reset_surface_route_steering()
	moss_last_footstep_position = player.global_position
	moss_footstep_distance = 0.0
	player.set_facing((player.global_position - entrance).normalized())
	player.camera.reset_smoothing()
	_reset_portal_transition_observations()
	_evaluate_context(player.global_position)


func _mine_return_position(mine_id: String) -> Vector2:





	var preferred: = (
		MOSS_MINE_RETURN_POSITION
		if mine_id == "mossMine"
		else Vector2(LATER_MINE_RETURN_POSITIONS.get(mine_id, _mine_entrance(mine_id) + DEFAULT_MINE_RETURN_OFFSET))
	)
	preferred = preferred.clamp(
		Vector2.ONE * PLAYER_RADIUS,
		_world_size() - Vector2.ONE * PLAYER_RADIUS
	)
	return _nearest_safe_restore_position(preferred)


func restore_position(position: Vector2) -> void :
	var clamped: = position.clamp(Vector2.ONE * PLAYER_RADIUS, _world_size() - Vector2.ONE * PLAYER_RADIUS)
	player.global_position = _nearest_safe_restore_position(clamped)
	_reset_surface_route_steering()
	moss_last_footstep_position = player.global_position
	moss_footstep_distance = 0.0
	player.camera.reset_smoothing()
	_reset_portal_transition_observations()
	_evaluate_context(player.global_position)


func gate_interaction_position(station_id: String) -> Vector2:
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		if String(boundary.station) == station_id or String(boundary.id) == station_id:
			return Vector2(float(boundary.x), GATE_Y)
	return Vector2.ZERO


func _nearest_safe_restore_position(position: Vector2) -> Vector2:
	if not _surface_collides(position):
		return position
	var route_position: = _nearest_surface_route_point(position)
	if not _surface_collides(route_position):
		return route_position
	for step in range(1, 25):
		var radius: = float(step * 16)
		for sample in range(16):
			var angle: = TAU * float(sample) / 16.0
			var candidate: = (route_position + Vector2.RIGHT.rotated(angle) * radius).clamp(
				Vector2.ONE * PLAYER_RADIUS,
				_world_size() - Vector2.ONE * PLAYER_RADIUS
			)
			if not _surface_collides(candidate):
				return candidate
	return PLAYER_START


func reset_for_new_run() -> void :
	_clear_moss_footstep_responses()
	moss_environment_time = 0.0
	moss_environment_accumulator = 0.0
	moss_footstep_distance = 0.0
	moss_last_footstep_position = PLAYER_START
	moss_response_serial = 0
	ore_mountain_passive_elapsed = 0.0
	moon_bloom_passive_elapsed = 0.0
	timed_surface_passive_elapsed[EMBER_FAULT_ID] = 0.0
	timed_surface_passive_elapsed[STARFALL_LATTICE_ID] = 0.0
	for drop in chest_loot_drops:
		var chest_drop_sprite: Sprite2D = drop.get("sprite")
		if is_instance_valid(chest_drop_sprite):
			chest_drop_sprite.queue_free()
	chest_loot_drops.clear()
	chest_loot_signature = ""
	for drop in ore_drops:
		var sprite: Sprite2D = drop.get("sprite")
		if is_instance_valid(sprite):
			sprite.queue_free()
	ore_drops.clear()
	ore_mountain_hp = MOSS_ORE_MOUNTAIN_MAX_HP
	ore_mountain_growth_buffer = 0.0
	ore_mountain_copper_yield_buffer = 0.0
	ore_mountain_gold_ready = true
	ore_mountain_last_growth_unix = int(Time.get_unix_time_from_system())
	ore_mountain_hit_flash = 0.0
	ore_mountain_hit_count = 0
	ore_mountain_collapse_elapsed = 0.0
	ore_mountain_swing_active = false
	ore_mountain_swing_target = _ore_mountain_hit_point(PLAYER_START)
	ore_mountain_input_buffer = 0.0
	for impact in ore_mountain_impacts:
		var impact_sprite: Sprite2D = impact.get("sprite")
		if is_instance_valid(impact_sprite):
			impact_sprite.queue_free()
	ore_mountain_impacts.clear()
	for drop in moon_bloom_drops:
		var moon_drop_sprite: Sprite2D = drop.get("sprite")
		if is_instance_valid(moon_drop_sprite):
			moon_drop_sprite.queue_free()
	moon_bloom_drops.clear()
	for effect in moon_bloom_effects:
		var moon_effect_sprite: Sprite2D = effect.get("sprite")
		if is_instance_valid(moon_effect_sprite):
			moon_effect_sprite.queue_free()
	moon_bloom_effects.clear()
	for index in range(moon_bloom_nodes.size()):
		moon_bloom_nodes[index].hp = MOON_BLOOM_NODE_MAX_HP
		moon_bloom_nodes[index].respawn = 0.0
	moon_bloom_status = "idle"
	moon_bloom_timer = 0.0
	moon_bloom_completions = 0
	moon_bloom_updated_unix = int(Time.get_unix_time_from_system())
	moon_bloom_hit_count = 0
	moon_bloom_visual_time = 0.0
	moon_bloom_swing_active = false
	moon_bloom_target_index = -1
	for spray_value in surface_material_sprays:
		var spray: Dictionary = spray_value
		var spray_sprite: Sprite2D = spray.get("sprite")
		if is_instance_valid(spray_sprite):
			spray_sprite.queue_free()
	surface_material_sprays.clear()
	_reset_surface_resource_mountains()
	_reset_timed_surface_resources()
	external_mine_held = false
	surface_route_steer_events = 0
	surface_last_motion_direction = Vector2.RIGHT
	_reset_surface_route_steering()
	surface_drop_budget_enforcing = false
	surface_drop_budget_peak = 0
	surface_drop_budget_trimmed = 0
	surface_drop_budget_auto_collected = 0
	surface_drop_budget_serial = 0
	surface_drop_budget_trimmed_by_source.clear()
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		gate_unlock_state[String(boundary.id)] = _raw_boundary_unlocked(boundary)
	player.global_position = PLAYER_START
	player.set_facing(Vector2.RIGHT)
	player.movement_speed = _movement_speed()
	player.set_mining_visual(false)
	player.camera.reset_smoothing()
	_reset_portal_transition_observations()
	chest_visual_state.clear()
	storage_visual_signature = ""
	_refresh_surface_chest_visuals()
	_refresh_surface_storage_nodes()
	_sync_pending_chest_loot_drops()
	_refresh_unlock_visibility()
	_evaluate_context(player.global_position)


func interaction_context() -> String:
	return active_context


func _draw() -> void :


	draw_rect(Rect2(0, 0, 2240, 1280), Color(0.05, 0.09, 0.07, 0.18), true)
	draw_rect(Rect2(2240, 0, 1120, 1280), Color("1e1716"), true)
	draw_rect(Rect2(3360, 0, 1120, 1280), Color("131323"), true)


func _build_surface_art() -> void :
	_build_later_backdrops()
	# Authored terrain owns the visible ground and cliff silhouette.
	# Leave the forest parallax visible below the shelf instead of filling a rectangle.
	var moss_ground: = _create_sprite(MOSS_GROUND, Rect2(0, 280, 1110, 335), 1)
	moss_ground.modulate = Color(0.82, 0.92, 0.8, 0.16)
	var moon_ground: = _create_tiled_ground(MOON_GROUND, Rect2(1110, 280, 1130, 335), 1)
	moon_ground.modulate = Color(0.76, 0.94, 1.0, 0.16)
	_create_tiled_ground(EMBER_GROUND, Rect2(2240,280,1120,335), 1).modulate.a = 0.25
	_create_tiled_ground(STAR_GROUND, Rect2(3360,280,1120,335), 1).modulate.a = 0.25


	_build_mossvein_mine_branch()
	_build_later_mine_branches()
	_build_later_resource_access_paths()
	moss_camp_yard_sprite = _create_sprite(MOSS_CAMP_YARD, MOSS_CAMP_YARD_RECT, 2)
	moss_camp_connector_sprite = _create_sprite(MOSS_CAMP_PATH, MOSS_CAMP_CONNECTOR_RECT, 2)
	moss_wayfarer_access_sprite = _create_sprite(MOSS_CAMP_PATH, MOSS_WAYFARER_ACCESS_RECT, 2)
	moss_wayfarer_access_sprite.name = "MossveinWayfarerAccess"
	moss_wayfarer_access_sprite.modulate = Color(0.92, 0.94, 0.84, 0.98)




	_create_sprite(STAR_BRANCH, STARFALL_HUB_APPROACH_RECT, 2)
	_create_sprite(preload("res://assets/surface/v3/ember-road-shelf.png"), Rect2(2200,425,1220,620),3)
	_create_sprite(preload("res://assets/surface/v3/star-road-shelf.png"), Rect2(3320,425,1220,620),3)
	# Lower exploration terraces support the existing ore challenges and mine ramps.
	_create_sprite(preload("res://assets/surface/v3/ember-road-shelf.png"), Rect2(2200,855,1220,620),1)
	_create_sprite(preload("res://assets/surface/v3/star-road-shelf.png"), Rect2(3320,855,1220,620),1)
	_create_sprite(preload("res://assets/surface/v2/moon-road-shelf.png"), Rect2(1070, 425, 1220, 620), 3)
	_create_sprite(preload("res://assets/surface/v2/moss-road-shelf.png"), Rect2(-40, 425, 1400, 620), 3)
	_build_mossvein_portal_clearing()
	_add_surface_decor()


func _build_mossvein_mine_branch() -> void :
	moss_mine_branch_sprite = Sprite2D.new()
	moss_mine_branch_sprite.name = "MossveinMineBranch"
	moss_mine_branch_sprite.texture = MOSS_MINE_RAMP
	moss_mine_branch_sprite.centered = false
	moss_mine_branch_sprite.position = MOSS_MINE_RAMP_POSITION
	moss_mine_branch_sprite.scale = MOSS_MINE_RAMP_SCALE
	moss_mine_branch_sprite.modulate = Color(0.96, 0.98, 0.92, 1.0)
	moss_mine_branch_sprite.z_index = 4
	moss_mine_branch_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(moss_mine_branch_sprite)
	surface_mine_branch_sprites["mossMine"] = moss_mine_branch_sprite


func _build_later_mine_branches() -> void :
	var moon_backing_rect: = MOON_MINE_APPROACH_RECT.grow(9.0)
	var moon_branch_bank: = _create_sprite(MOON_MINE_APPROACH, moon_backing_rect, 4)
	moon_branch_bank.name = "MoonglassMineBranchBank"
	moon_branch_bank.modulate = Color(0.08, 0.26, 0.29, 0.72)
	surface_mine_branch_backing_sprites["moonMine"] = moon_branch_bank
	var moon_branch: = _create_sprite(MOON_MINE_APPROACH, MOON_MINE_APPROACH_RECT, 4)
	moon_branch.name = "MoonglassMineBranch"
	moon_branch.modulate = Color(0.94, 1.0, 1.0, 1.0)
	surface_mine_branch_sprites["moonMine"] = moon_branch




	var ember_branch: = _create_sprite(EMBER_BRANCH, Rect2(2456, 772, 500, 222), 2, true, -0.105)
	ember_branch.name = "EmberdeepMineBranch"
	surface_mine_branch_sprites["emberMine"] = ember_branch
	var star_branch: = _create_sprite(STAR_BRANCH, Rect2(3450, 760, 650, 289), 2)
	star_branch.name = "StarfallMineBranch"
	surface_mine_branch_sprites["starMine"] = star_branch


func _build_later_resource_access_paths() -> void :
	_create_textured_walk_route(
		Array(LATER_RESOURCE_ACCESS_ROUTES.ember_fault),
		ROAD_TEXTURES.emberdeep,
		124.0,
		"EmberFaultAccess"
	)
	_create_textured_walk_route(
		Array(LATER_RESOURCE_ACCESS_ROUTES.starfall_lattice),
		ROAD_TEXTURES.starfall,
		124.0,
		"StarfallLatticeAccess"
	)


func _create_textured_walk_route(route: Array, texture: Texture2D, width: float, route_name: String) -> void :
	var points: = PackedVector2Array(route)
	var backing: = Line2D.new()
	backing.name = "%sBank" % route_name
	backing.points = points
	backing.width = width + 28.0
	backing.default_color = Color(0.055, 0.085, 0.075, 0.96)
	backing.joint_mode = Line2D.LINE_JOINT_ROUND
	backing.begin_cap_mode = Line2D.LINE_CAP_ROUND
	backing.end_cap_mode = Line2D.LINE_CAP_ROUND
	backing.z_index = 2
	add_child(backing)
	var path: = Line2D.new()
	path.name = route_name
	path.points = points
	path.width = width
	path.texture = texture
	path.texture_mode = Line2D.LINE_TEXTURE_TILE
	path.joint_mode = Line2D.LINE_JOINT_ROUND
	path.begin_cap_mode = Line2D.LINE_CAP_ROUND
	path.end_cap_mode = Line2D.LINE_CAP_ROUND
	path.default_color = Color(0.93, 0.98, 1.0, 1.0)
	path.z_index = 3
	add_child(path)


func _build_ore_mountain() -> void :
	ore_mountain_sprite = _create_world_asset(MOSS_ORE_MOUNTAIN, MOSS_ORE_MOUNTAIN_POSITION, Vector2(450, 405), 30.0, 5)
	var stage_material: = ShaderMaterial.new()
	stage_material.shader = preload("res://shaders/surface_mountain_blend.gdshader")
	stage_material.set_shader_parameter("next_stage", MOSS_ORE_MOUNTAIN)
	ore_mountain_sprite.material = stage_material
	ore_mountain_base_scale = ore_mountain_sprite.scale
	ore_mountain_base_position = ore_mountain_sprite.position
	ore_mountain_blend_sprite = Sprite2D.new()
	ore_mountain_blend_sprite.centered = false
	ore_mountain_blend_sprite.texture = MOSS_ORE_MOUNTAIN
	ore_mountain_blend_sprite.position = ore_mountain_base_position
	ore_mountain_blend_sprite.scale = ore_mountain_base_scale
	ore_mountain_blend_sprite.z_index = 6
	ore_mountain_blend_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ore_mountain_blend_sprite.visible = false
	add_child(ore_mountain_blend_sprite)


func _build_moonglass_resource() -> void :
	moon_bloom_nodes.clear()
	for index in range(MOON_BLOOM_NODE_POSITIONS.size()):
		var position: Vector2 = MOON_BLOOM_NODE_POSITIONS[index]
		var glow: = Sprite2D.new()
		glow.texture = _moon_resource_glow_texture()
		glow.position = position
		glow.scale = Vector2.ONE * (88.0 / float(glow.texture.get_width()))
		glow.modulate = Color(0.3, 0.92, 1.0, 0.3)
		glow.z_index = 5
		add_child(glow)
		moon_bloom_glows.append(glow)
		var sprite: = _create_world_asset(
			MOON_BLOOM_NODE,
			position,
			Vector2(98, 94),
			47.0,
			6
		)
		moon_bloom_sprites.append(sprite)
		moon_bloom_base_scales.append(sprite.scale)
		moon_bloom_nodes.append({
			"position": position,
			"hp": MOON_BLOOM_NODE_MAX_HP,
			"respawn": 0.0,
		})


func _build_timed_surface_resources() -> void :
	timed_surface_veins.clear()
	for vein_id in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		_build_timed_surface_resource(vein_id)


func _build_timed_surface_resource(vein_id: String) -> void :
	var config: = _timed_surface_config(vein_id)
	var line_glow: = Line2D.new()
	line_glow.points = _timed_surface_connection_points(vein_id)
	line_glow.width = 11.0 if vein_id == STARFALL_LATTICE_ID else 13.0
	line_glow.default_color = Color(config.color, 0.18)
	line_glow.antialiased = true
	line_glow.z_index = 5
	add_child(line_glow)
	var line: = Line2D.new()
	line.points = line_glow.points
	line.width = 2.7 if vein_id == STARFALL_LATTICE_ID else 3.4
	line.default_color = Color(config.color, 0.56)
	line.antialiased = true
	line.z_index = 5
	add_child(line)
	var reaction_sprite: = Sprite2D.new()
	reaction_sprite.texture = config.completion_texture
	reaction_sprite.hframes = 4
	reaction_sprite.frame = 0
	reaction_sprite.centered = true
	reaction_sprite.position = Vector2(config.center) + Vector2(0, 12)
	reaction_sprite.scale = Vector2.ONE * ((284.0 if vein_id == STARFALL_LATTICE_ID else 246.0) / 256.0)
	reaction_sprite.modulate = Color(config.color, 0.0)
	reaction_sprite.z_index = 4
	reaction_sprite.visible = false
	add_child(reaction_sprite)
	var sprites: Array[Sprite2D] = []
	var glows: Array[Sprite2D] = []
	var damage_overlays: Array[Sprite2D] = []
	var residue_sprites: Array[Sprite2D] = []
	var base_scales: Array[Vector2] = []
	var nodes: Array[Dictionary] = []
	for position_value in Array(config.positions):
		var position: = Vector2(position_value)
		var node_texture: Texture2D = config.node_texture
		var glow: = Sprite2D.new()
		glow.texture = _timed_surface_glow_texture(vein_id)
		glow.position = position
		glow.scale = Vector2.ONE * (108.0 / float(glow.texture.get_width()))
		glow.modulate = Color(config.color, 0.3)
		glow.z_index = 5
		add_child(glow)
		glows.append(glow)
		var residue: = Sprite2D.new()
		residue.texture = config.completion_texture
		residue.hframes = 4
		residue.frame = 3
		residue.centered = true
		residue.position = position + Vector2(0, 8)
		residue.scale = Vector2.ONE * ((124.0 if vein_id == STARFALL_LATTICE_ID else 108.0) / 256.0)
		residue.modulate = Color(config.color, 0.0)
		residue.z_index = 6
		residue.visible = false
		add_child(residue)
		residue_sprites.append(residue)
		var sprite: = _create_world_asset(
			node_texture,
			position,
			Vector2(98, 94),
			47.0,
			6
		)
		sprites.append(sprite)
		base_scales.append(sprite.scale)
		var damage_overlay: = Sprite2D.new()
		damage_overlay.texture = config.impact_texture
		damage_overlay.hframes = 4
		damage_overlay.frame = 0
		damage_overlay.centered = true
		damage_overlay.position = position
		damage_overlay.scale = Vector2.ONE * ((116.0 if vein_id == STARFALL_LATTICE_ID else 104.0) / 256.0)
		damage_overlay.modulate = Color(config.color, 0.0)
		damage_overlay.z_index = 7
		damage_overlay.visible = false
		add_child(damage_overlay)
		damage_overlays.append(damage_overlay)
		nodes.append({
			"position": position,
			"hp": int(config.max_hp),
			"shell": int(config.max_shell),
			"respawn": 0.0,
		})
	timed_surface_veins[vein_id] = {
		"id": vein_id,
		"nodes": nodes,
		"sprites": sprites,
		"glows": glows,
		"base_scales": base_scales,
		"line": line,
		"line_glow": line_glow,
		"reaction_sprite": reaction_sprite,
		"damage_overlays": damage_overlays,
		"residue_sprites": residue_sprites,
		"status": "idle",
		"timer": 0.0,
		"completions": 0,
		"updated_unix": int(Time.get_unix_time_from_system()),
		"swing_active": false,
		"swing_elapsed": 0.0,
		"swing_duration": 0.72,
		"swing_hit": false,
		"target_index": -1,
		"hit_count": 0,
		"visual_time": 0.0,
		"visual_elapsed": SURFACE_DYNAMIC_VISUAL_TICK,
		"drops": [],
		"effects": [],
		"last_completion_bonus": {},
	}


func _timed_surface_config(vein_id: String) -> Dictionary:
	if vein_id == EMBER_FAULT_ID:
		return {
			"id": EMBER_FAULT_ID,
			"context": "ember_resource",
			"positions": EMBER_FAULT_NODE_POSITIONS,
			"center": EMBER_FAULT_CENTER,
			"max_hp": EMBER_FAULT_NODE_MAX_HP,
			"max_shell": EMBER_FAULT_NODE_MAX_SHELL,
			"time_limit": EMBER_FAULT_TIME_LIMIT,
			"respawn": EMBER_FAULT_RESPAWN_SECONDS,
			"resource": "emberstone",
			"bonus": EMBER_FAULT_BONUS,
			"color": Color("ff9b54"),
			"node_texture": EMBERSTONE_NODE,
			"drop_textures": {"emberstone": EMBERSTONE_DROP, "sunslag": SUNSLAG_DROP},
			"impact_texture": EMBER_IMPACT,
			"completion_texture": EMBER_RESPONSE,
			"reaction": "armored_pressure_fault",
		}
	return {
		"id": STARFALL_LATTICE_ID,
		"context": "starfall_resource",
		"positions": STARFALL_LATTICE_NODE_POSITIONS,
		"center": STARFALL_LATTICE_CENTER,
		"max_hp": STARFALL_LATTICE_NODE_MAX_HP,
		"max_shell": STARFALL_LATTICE_NODE_MAX_SHELL,
		"time_limit": STARFALL_LATTICE_TIME_LIMIT,
		"respawn": STARFALL_LATTICE_RESPAWN_SECONDS,
		"resource": "astralite",
		"bonus": STARFALL_LATTICE_BONUS,
		"color": Color("c4cfff"),
		"node_texture": ASTRALITE_NODE,
		"drop_textures": {"astralite": ASTRALITE_DROP, "crownstone": CROWNSTONE_DROP},
		"impact_texture": STAR_IMPACT,
		"completion_texture": STAR_RESPONSE,
		"reaction": "charged_astral_lattice",
	}


func _timed_surface_connection_points(vein_id: String) -> PackedVector2Array:
	var config: = _timed_surface_config(vein_id)
	var positions: Array = Array(config.positions)
	if vein_id == EMBER_FAULT_ID:
		var first: = Vector2(positions[0]) + Vector2(0, 9)
		var middle: = Vector2(positions[1]) + Vector2(0, 9)
		var last: = Vector2(positions[2]) + Vector2(0, 9)
		return PackedVector2Array([
			first,
			first.lerp(middle, 0.46) + Vector2(0, -7),
			middle,
			middle.lerp(last, 0.54) + Vector2(0, 8),
			last,
		])
	return PackedVector2Array([
		Vector2(positions[0]) + Vector2(0, 9),
		Vector2(positions[1]) + Vector2(0, 9),
		Vector2(positions[2]) + Vector2(0, 9),
		Vector2(positions[0]) + Vector2(0, 9),
	])


func _add_surface_decor() -> void :
	surface_resource_mountains.clear()
	for item in [
		[1185, 220, 112, 48, false, 0.48], [1435, 185, 118, 50, true, 0.5],
		[1775, 210, 122, 52, false, 0.46], [2110, 330, 114, 48, true, 0.48],
		[1415, 1235, 118, 50, true, 0.44], [1885, 1170, 124, 52, false, 0.46]
	]:
		_create_world_asset(MOON_CRYSTALS, Vector2(item[0], item[1]), Vector2(item[2], item[3]), 0.0, 2, item[4], item[5])
	_build_moonglass_resource_platform()
	_build_surface_resource_mountain(MOON_MOUNTAIN_ID, MOON_ORE_MOUNTAIN, 3)
	for item in [
		[2350, 1190, 124, 62, true, 0.42], [3120, 1180, 130, 64, false, 0.44]
	]:
		_create_world_asset(EMBER_SLAG, Vector2(item[0], item[1]), Vector2(item[2], item[3]), 0.0, 2, item[4], item[5])
	_create_world_asset(EMBER_FAULT, EMBER_FAULT_CENTER + Vector2(0, 62), Vector2(350, 154), 0.0, 2)
	_build_surface_resource_mountain(EMBER_MOUNTAIN_ID, EMBER_ORE_MOUNTAIN, 3)
	for item in [
		[3480, 1190, 124, 62, true, 0.44], [4230, 1170, 134, 67, false, 0.46]
	]:
		_create_world_asset(STAR_SHARDS, Vector2(item[0], item[1]), Vector2(item[2], item[3]), 0.0, 2, item[4], item[5])
	_create_world_asset(STAR_LATTICE, STARFALL_LATTICE_CENTER + Vector2(0, 62), Vector2(568, 249), 0.0, 2)
	_build_surface_resource_mountain(STAR_MOUNTAIN_ID, STAR_ORE_MOUNTAIN, 3)


func _build_moonglass_resource_platform() -> void :
	moon_bloom_platform_nodes.clear()







	var approach_angle: = (
		Vector2(MOON_BLOOM_PLATFORM_ACCESS_ROUTE[-1])
		- Vector2(MOON_BLOOM_PLATFORM_ACCESS_ROUTE[0])
	).angle()
	var approach_bank: = _create_centered_sprite(
		ROAD_TEXTURES.moonglass,
		MOON_BLOOM_PLATFORM_APPROACH_CENTER,
		Vector2(190, 115),
		2,
		false,
		approach_angle,
		0.96
	)
	approach_bank.name = "MoonglassBloomApproachBank"
	approach_bank.scale.y *= 1.58
	approach_bank.modulate = Color(0.11, 0.34, 0.38, 0.98)
	moon_bloom_platform_nodes.append(approach_bank)

	var underside: = _create_world_asset(
		MOON_BLOOM,
		MOON_BLOOM_PLATFORM_UNDERSIDE_ANCHOR,
		Vector2(535, 225),
		0.0,
		2,
		false,
		0.98
	)
	underside.name = "MoonglassBloomFloatingUnderside"
	underside.modulate = Color(0.12, 0.32, 0.36, 0.98)
	moon_bloom_platform_nodes.append(underside)

	var approach: = _create_centered_sprite(
		ROAD_TEXTURES.moonglass,
		MOON_BLOOM_PLATFORM_APPROACH_CENTER,
		Vector2(215, 100),
		3,
		false,
		approach_angle,
		1.0
	)
	approach.name = "MoonglassBloomRoadConnection"
	approach.scale.y *= 1.22
	approach.modulate = Color(0.76, 0.96, 1.0, 1.0)
	moon_bloom_platform_nodes.append(approach)

	var landing: = _create_world_asset(
		MOON_CRYSTALS,
		MOON_BLOOM_PLATFORM_LANDING_ANCHOR,
		Vector2(240, 112),
		0.0,
		4,
		false,
		1.0
	)
	landing.name = "MoonglassBloomRoadLanding"
	landing.modulate = Color(0.82, 0.98, 1.0, 1.0)
	moon_bloom_platform_nodes.append(landing)

	var shelf: = _create_world_asset(
		MOON_BLOOM,
		MOON_BLOOM_PLATFORM_TOP_ANCHOR,
		Vector2(500, 190),
		0.0,
		3,
		false,
		1.0
	)
	shelf.name = "MoonglassBloomResonanceShelf"
	shelf.modulate = Color(0.91, 0.98, 1.0, 1.0)
	moon_bloom_platform_nodes.append(shelf)


func _build_surface_resource_mountain(mountain_id: String, texture: Texture2D, z: int) -> void :
	var config: Dictionary = SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]
	var anchor: = Vector2(config.anchor)
	var max_size: = Vector2(config.max_size)
	var texture_size: = Vector2(texture.get_size())
	var scale_factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var display_size: = texture_size * scale_factor
	var root: = Node2D.new()
	root.name = "%sRoot" % mountain_id.to_pascal_case()
	root.position = anchor
	add_child(root)
	var sprite: = _new_surface_resource_mountain_sprite(root, z)
	var blend_sprite: = _new_surface_resource_mountain_sprite(root, z + 1)
	blend_sprite.visible = false
	surface_resource_mountains[mountain_id] = {
		"root": root,
		"sprite": sprite,
		"blend_sprite": blend_sprite,
		"display_size": display_size,
		"base_position": anchor,
		"phase": 0,
		"hp": SURFACE_RESOURCE_MOUNTAIN_MAX_HP,
		"growth_buffer": 0.0,
		"yield_buffer": 0.0,
		"rare_ready": true,
		"last_growth_unix": int(Time.get_unix_time_from_system()),
		"hit_flash": 0.0,
		"hit_elapsed": 0.0,
		"collapse_elapsed": 0.0,
		"visual_elapsed": SURFACE_DYNAMIC_VISUAL_TICK,
		"hit_count": 0,
		"swing_active": false,
		"swing_elapsed": 0.0,
		"swing_duration": 0.72,
		"swing_hit": false,
		"swing_target": _surface_resource_mountain_hit_point(mountain_id, anchor + Vector2.DOWN * 100.0),
	}
	_update_surface_resource_mountain_visual(mountain_id)


func _new_surface_resource_mountain_sprite(root: Node2D, z: int) -> Sprite2D:
	var sprite: = Sprite2D.new()
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = z
	var blend_material: ShaderMaterial=ShaderMaterial.new()
	blend_material.shader=preload("res://shaders/resource_mountain_blend.gdshader")
	sprite.material=blend_material
	root.add_child(sprite)
	return sprite


func _layout_surface_resource_mountain_sprite(
	sprite: Sprite2D, texture: Texture2D, display_size: Vector2, scale_multiplier: Vector2
) -> void :
	sprite.texture = texture
	var rendered_size: = display_size * scale_multiplier
	sprite.scale = rendered_size / Vector2(texture.get_size())
	sprite.position = Vector2( - rendered_size.x * 0.5, - rendered_size.y)


func _update_surface_resource_mountain_visual(mountain_id: String) -> void :
	if not surface_resource_mountains.has(mountain_id):
		return
	var entry: Dictionary = surface_resource_mountains[mountain_id]
	var root: Node2D = entry.root
	var sprite: Sprite2D = entry.sprite
	var blend_sprite: Sprite2D = entry.blend_sprite
	if not is_instance_valid(root) or not is_instance_valid(sprite) or not is_instance_valid(blend_sprite):
		return
	var hit_strength: = clampf(float(entry.hit_elapsed) / SURFACE_RESOURCE_MOUNTAIN_HIT_DURATION, 0.0, 1.0)
	var collapse_strength: = clampf(float(entry.collapse_elapsed) / SURFACE_RESOURCE_MOUNTAIN_COLLAPSE_DURATION, 0.0, 1.0)
	var reaction: = sin((1.0 - hit_strength) * PI) if hit_strength > 0.0 else 0.0
	var scale_multiplier: = Vector2.ONE
	var offset: = Vector2.ZERO
	var rotation_offset: = 0.0
	if mountain_id == MOON_MOUNTAIN_ID:
		scale_multiplier = Vector2(1.0 + reaction * 0.026, 1.0 + reaction * 0.012)
		offset = Vector2(sin((1.0 - hit_strength) * TAU * 3.0) * reaction * 3.5, - reaction * 1.5)
	elif mountain_id == EMBER_MOUNTAIN_ID:
		scale_multiplier = Vector2(1.0 + reaction * 0.012, 1.0 - reaction * 0.022)
		offset = Vector2(sin((1.0 - hit_strength) * TAU * 4.0) * reaction * 2.4, reaction * 2.0)
	else:
		scale_multiplier = Vector2.ONE * (1.0 + reaction * 0.018)
		offset = Vector2(sin((1.0 - hit_strength) * TAU * 2.0) * reaction * 2.2, - reaction * 1.2)
		rotation_offset = sin((1.0 - hit_strength) * PI) * 0.006
	if collapse_strength > 0.0:
		var collapse_progress: = 1.0 - collapse_strength
		offset += Vector2(
			sin(collapse_progress * 73.0) * collapse_strength * 7.0,
			cos(collapse_progress * 91.0) * collapse_strength * 3.0
		)
	root.position = Vector2(entry.base_position) + offset
	root.rotation = rotation_offset
	var hp_ratio: = clampf(
		(float(entry.hp) + float(entry.growth_buffer)) / float(SURFACE_RESOURCE_MOUNTAIN_MAX_HP),
		0.0, 1.0
	)
	var textures: Array = SURFACE_RESOURCE_MOUNTAIN_TEXTURES[mountain_id]
	var stages: Array[Texture2D] = [textures[3], textures[2], textures[1], textures[0]]
	var tint: = Color(1.13, 1.08, 1.02, 1.0) if float(entry.hit_flash) > 0.0 else Color.WHITE
	var display_size: = Vector2(entry.display_size)
	if hp_ratio >= 0.999:
		_layout_surface_resource_mountain_sprite(sprite, stages[3], display_size, scale_multiplier)
		sprite.modulate = tint
		sprite.material.set_shader_parameter("stage_mix",0.0)
		blend_sprite.visible = false
		entry.phase = 0
	else:
		var stage_position: = hp_ratio * 3.0
		var stage_index: = mini(2, floori(stage_position))
		var blend: = smoothstep(0.0, 1.0, stage_position - float(stage_index))
		_layout_surface_resource_mountain_sprite(sprite, stages[stage_index], display_size, scale_multiplier)
		_layout_surface_resource_mountain_sprite(blend_sprite, stages[stage_index + 1], display_size, scale_multiplier)
		sprite.modulate = tint
		sprite.material.set_shader_parameter("next_stage",stages[stage_index+1])
		sprite.material.set_shader_parameter("stage_mix",blend)
		blend_sprite.visible=false
		entry.phase = 3 - stage_index
	surface_resource_mountains[mountain_id] = entry


func _build_mossvein_portal_clearing() -> void :



	moss_portal_clearing_nodes.clear()
	moss_portal_glows.clear()




	# The complete arch and terrain shelf replace the cropped full-height wall.
	# No backdrop rectangle or floating generator remains at this boundary.
	var moon_shoulder: = _create_world_asset(
		MOON_CRYSTALS,
		MOSS_GATE_ANCHOR + Vector2(260, 0),
		Vector2(250, 104),
		137.0,
		4,
		false,
		0.92
	)
	moss_portal_clearing_nodes.append(moon_shoulder)



	for index in range(MOSS_PORTAL_LANTERN_POSITIONS.size()):
		var lantern_position: = Vector2(MOSS_PORTAL_LANTERN_POSITIONS[index])
		var lantern_glow: = _create_portal_glow(
			lantern_position,
			_gold_glow_texture(),
			Vector2(82, 82),
			Color(1.0, 0.72, 0.28, 0.38),
			7
		)
		moss_portal_glows.append({
			"sprite": lantern_glow,
			"anchor": lantern_position,
			"base_alpha": 0.38,
			"phase": float(index) * 1.73,
		})
		moss_portal_clearing_nodes.append(lantern_glow)

	var crystal_glow_position: = MOSS_GATE_ANCHOR + Vector2(112, 0)
	var crystal_glow: = _create_portal_glow(
		crystal_glow_position,
		_moon_resource_glow_texture(),
		Vector2(178, 150),
		Color(0.42, 0.94, 1.0, 0.18),
		5
	)
	moss_portal_glows.append({
		"sprite": crystal_glow,
		"anchor": crystal_glow_position,
		"base_alpha": 0.18,
		"phase": 2.41,
	})
	moss_portal_clearing_nodes.append(crystal_glow)



	var moon_foreground: = _create_world_asset(
		MOON_CRYSTALS,
		MOSS_GATE_ANCHOR + Vector2(292, 0),
		Vector2(188, 78),
		184.0,
		11,
		false,
		0.96
	)
	moss_portal_clearing_nodes.append(moon_foreground)


func _create_atlas_world_asset(
	atlas: Texture2D,
	region: Rect2,
	anchor: Vector2,
	max_size: Vector2,
	bottom: float,
	z: int,
	flip_h: bool = false,
	alpha: float = 1.0
) -> Sprite2D:
	var texture: = AtlasTexture.new()
	texture.atlas = atlas
	texture.region = region
	return _create_world_asset(texture, anchor, max_size, bottom, z, flip_h, alpha)


func _create_portal_glow(
	position: Vector2,
	texture: Texture2D,
	size: Vector2,
	color: Color,
	z: int
) -> Sprite2D:
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.position = position
	sprite.scale = size / Vector2(texture.get_size())
	sprite.modulate = color
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	return sprite


func _build_mossvein_environment() -> void :
	moss_reduced_motion = bool(ProjectSettings.get_setting("accessibility/reduced_motion", false))
	moss_decor_sprites.clear()
	var decor_root: = get_node_or_null("MossveinDecor")
	if decor_root != null:
		for child in decor_root.get_children():
			if child is Sprite2D:
				var sprite: = child as Sprite2D
				sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				moss_decor_sprites.append(sprite)

	moss_glowmoths.clear()
	for index in range(MOSS_GLOWMOTH_ANCHORS.size()):
		var anchor: Vector2 = MOSS_GLOWMOTH_ANCHORS[index]
		var sprite: = Sprite2D.new()
		sprite.texture = MOSS_GLOWMOTH
		sprite.hframes = 4
		sprite.frame = index % 4
		sprite.position = anchor
		sprite.scale = Vector2.ONE * ((46.0 + float(index % 3) * 2.0) / 256.0)
		sprite.modulate = Color(1.0, 0.97, 0.82, 0.88)
		sprite.z_index = 8
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		moss_glowmoths.append({
			"sprite": sprite,
			"anchor": anchor,
			"phase": float(index) * 0.731 + 0.37,
			"route": Vector2(18.0 + float(index % 3) * 6.0, 8.0 + float((index + 1) % 3) * 4.0),
		})

	moss_drifts.clear()
	for index in range(MOSS_DRIFT_ANCHORS.size()):
		var anchor: Vector2 = MOSS_DRIFT_ANCHORS[index]
		var sprite: = Sprite2D.new()
		sprite.texture = MOSS_DRIFT
		sprite.hframes = 4
		sprite.frame = index % 4
		sprite.position = anchor
		sprite.scale = Vector2.ONE * ((76.0 + float(index % 3) * 5.0) / 256.0)
		sprite.modulate = Color(0.84, 1.0, 0.75, 0.22)
		sprite.z_index = 4
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(sprite)
		moss_drifts.append({
			"sprite": sprite,
			"anchor": anchor,
			"phase": float(index) * 1.117 + 0.21,
		})
	_update_mossvein_environment_visuals()


func _build_later_surface_life() -> void :
	for item in later_surface_creatures + later_surface_drifts:
		var old_sprite: Sprite2D = item.get("sprite")
		if is_instance_valid(old_sprite):
			old_sprite.queue_free()
	later_surface_creatures.clear()
	later_surface_drifts.clear()
	for world_id_value in LATER_SURFACE_LIFE_SPECS.keys():
		var world_id: = String(world_id_value)
		var spec: = Dictionary(LATER_SURFACE_LIFE_SPECS[world_id])
		var creature_texture: Texture2D = LATER_SURFACE_CREATURE_TEXTURES[world_id]
		var anchors: = Array(spec.anchors)
		for index in range(anchors.size()):
			var anchor: = Vector2(anchors[index])
			var sprite: = Sprite2D.new()
			sprite.texture = creature_texture
			sprite.hframes = 4
			sprite.frame = index % 4
			sprite.position = anchor
			sprite.scale = Vector2.ONE * (float(spec.size) / 256.0)
			sprite.modulate = Color(spec.color)
			sprite.z_index = 9 if String(spec.kind) == "ground" else 8
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.visible = false
			add_child(sprite)
			later_surface_creatures.append({
				"sprite": sprite,
				"world": world_id,
				"kind": String(spec.kind),
				"anchor": anchor,
				"route": Vector2(spec.route),
				"phase": float(index) * 1.337 + float(world_id.length()) * 0.19,
				"base_alpha": Color(spec.color).a,
			})
		var drift_texture: Texture2D = LATER_SURFACE_DRIFT_TEXTURES[world_id]
		var drift_anchors: = Array(LATER_SURFACE_DRIFT_ANCHORS[world_id])
		for index in range(drift_anchors.size()):
			var anchor: = Vector2(drift_anchors[index])
			var sprite: = Sprite2D.new()
			sprite.texture = drift_texture
			sprite.hframes = 4
			sprite.frame = index % 4
			sprite.position = anchor
			sprite.scale = Vector2.ONE * ((84.0 + float(index % 2) * 8.0) / 256.0)
			sprite.modulate = Color(1, 1, 1, 0.0)
			sprite.z_index = 4
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			sprite.visible = false
			add_child(sprite)
			later_surface_drifts.append({
				"sprite": sprite,
				"world": world_id,
				"anchor": anchor,
				"phase": float(index) * 1.713 + float(world_id.length()) * 0.27,
			})
	_update_later_surface_life_visuals()


func _update_mossvein_environment(delta: float) -> void :
	moss_environment_accumulator += maxf(0.0, delta)
	if moss_environment_accumulator < MOSS_ENVIRONMENT_TICK:
		return
	var step: = moss_environment_accumulator
	moss_environment_accumulator = 0.0
	moss_environment_time += step
	_update_mossvein_environment_visuals()
	_update_later_surface_life_visuals()
	_update_moss_footstep_responses(step)


func _update_mossvein_environment_visuals() -> void :
	var center: = player.global_position if is_instance_valid(player) else PLAYER_START
	for glow_value in moss_portal_glows:
		var glow: Dictionary = Dictionary(glow_value)
		var portal_glow: = glow.get("sprite") as Sprite2D
		if not is_instance_valid(portal_glow):
			continue
		var glow_anchor: = Vector2(glow.get("anchor", MOSS_GATE_ANCHOR))
		portal_glow.visible = _moss_environment_point_visible(glow_anchor, center, 190.0)
		if not portal_glow.visible:
			continue
		var base_alpha: = float(glow.get("base_alpha", 0.2))
		var pulse: = 1.0
		if not moss_reduced_motion:
			pulse = 0.88 + 0.12 * sin(moss_environment_time * 1.72 + float(glow.get("phase", 0.0)))
		portal_glow.modulate.a = base_alpha * pulse
	for item in moss_glowmoths:
		var sprite: Sprite2D = item.sprite
		var anchor: Vector2 = item.anchor
		var on_screen: = _moss_environment_point_visible(anchor, center, 90.0)
		sprite.visible = on_screen
		if not on_screen:
			continue
		var phase: = float(item.phase)
		if moss_reduced_motion:
			sprite.position = anchor
			sprite.frame = 0
			continue
		var route: Vector2 = item.route
		var cycle: = moss_environment_time * 0.78 + phase
		sprite.position = anchor + Vector2(sin(cycle) * route.x, cos(cycle * 0.71) * route.y)
		sprite.frame = posmod(floori(moss_environment_time * MOSS_GLOWMOTH_FPS + phase), 4)
		sprite.flip_h = cos(cycle) < 0.0
		var pulse: = 0.94 + 0.06 * sin(moss_environment_time * 2.2 + phase)
		sprite.modulate.a = 0.88 * pulse

	var visible_drift: Array[Dictionary] = []
	for item in moss_drifts:
		var anchor: Vector2 = item.anchor
		if _moss_environment_point_visible(anchor, center, 120.0):
			visible_drift.append({"item": item, "distance": anchor.distance_squared_to(center)})
	visible_drift.sort_custom( func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	for item in moss_drifts:
		var drift_sprite: Sprite2D = item.sprite
		drift_sprite.visible = false
	for index in range(mini(4, visible_drift.size())):
		var item: Dictionary = visible_drift[index].item
		var sprite: Sprite2D = item.sprite
		var anchor: Vector2 = item.anchor
		var phase: = float(item.phase)
		sprite.visible = true
		if moss_reduced_motion:
			sprite.position = anchor
			sprite.frame = 0
			sprite.modulate.a = 0.19
			continue
		var cycle: = moss_environment_time * 0.58 + phase
		sprite.position = anchor + Vector2(sin(cycle) * 7.0, cos(cycle * 0.73) * 5.0)
		sprite.frame = posmod(floori(moss_environment_time * MOSS_DRIFT_FPS + phase), 4)
		sprite.modulate.a = 0.2 + 0.04 * (0.5 + 0.5 * sin(moss_environment_time * 1.25 + phase))


func _moss_environment_point_visible(point: Vector2, center: Vector2, margin: float) -> bool:
	return (
		absf(point.x - center.x) <= MOSS_ENVIRONMENT_CULL_HALF_SIZE.x + margin
		and absf(point.y - center.y) <= MOSS_ENVIRONMENT_CULL_HALF_SIZE.y + margin
	)


func _update_later_surface_life_visuals() -> void :
	var center: = player.global_position if is_instance_valid(player) else PLAYER_START
	for item in later_surface_creatures:
		var sprite: Sprite2D = item.sprite
		var world_id: = String(item.world)
		var anchor: = Vector2(item.anchor)
		var is_visible: = RunState.is_world_unlocked(world_id) and _moss_environment_point_visible(anchor, center, 110.0)
		sprite.visible = is_visible
		if not is_visible:
			continue
		var phase: = float(item.phase)
		var route: = Vector2(item.route)
		var kind: = String(item.kind)
		if moss_reduced_motion:
			sprite.position = anchor
			sprite.frame = 0
			sprite.modulate.a = float(item.base_alpha) * 0.82
			continue
		var cycle_speed: = 0.68 if kind == "ground" else (0.46 if world_id == "starfall" else 0.72)
		var cycle: = moss_environment_time * cycle_speed + phase
		if kind == "ground":

			sprite.position = anchor + Vector2(sin(cycle) * route.x, absf(sin(cycle * 2.0)) * - route.y)
			sprite.flip_h = cos(cycle) < 0.0
		else:

			sprite.position = anchor + Vector2(sin(cycle) * route.x, cos(cycle * 0.73) * route.y)
			sprite.flip_h = cos(cycle) < 0.0
		sprite.frame = posmod(floori(moss_environment_time * LATER_SURFACE_LIFE_FPS + phase), 4)
		sprite.modulate.a = float(item.base_alpha) * (0.93 + 0.07 * sin(moss_environment_time * 1.9 + phase))

	var visible_drift_by_world: = {"moonglass": 0, "emberdeep": 0, "starfall": 0}
	var ordered_drifts: Array[Dictionary] = []
	for item in later_surface_drifts:
		var anchor: = Vector2(item.anchor)
		var world_id: = String(item.world)
		var sprite: Sprite2D = item.sprite
		sprite.visible = false
		if RunState.is_world_unlocked(world_id) and _moss_environment_point_visible(anchor, center, 140.0):
			ordered_drifts.append({"item": item, "distance": anchor.distance_squared_to(center)})
	ordered_drifts.sort_custom( func(a: Dictionary, b: Dictionary) -> bool: return float(a.distance) < float(b.distance))
	for candidate in ordered_drifts:
		var item: Dictionary = candidate.item
		var world_id: = String(item.world)


		if int(visible_drift_by_world[world_id]) >= 3:
			continue
		visible_drift_by_world[world_id] = int(visible_drift_by_world[world_id]) + 1
		var sprite: Sprite2D = item.sprite
		var anchor: = Vector2(item.anchor)
		var phase: = float(item.phase)
		sprite.visible = true
		if moss_reduced_motion:
			sprite.position = anchor
			sprite.frame = 0
			sprite.modulate.a = 0.13
			continue
		var cycle: = moss_environment_time * 0.46 + phase
		sprite.position = anchor + Vector2(sin(cycle) * 8.0, cos(cycle * 0.77) * 6.0)
		sprite.frame = posmod(floori(moss_environment_time * LATER_SURFACE_DRIFT_FPS + phase), 4)
		sprite.modulate.a = 0.13 + 0.035 * (0.5 + 0.5 * sin(moss_environment_time * 1.1 + phase))


func _spawn_moss_footstep(world_position: Vector2) -> void :
	if moss_reduced_motion or world_position.x > GROUND_RECTS.mossvein.end.x:
		return
	while moss_footstep_responses.size() >= MOSS_MAX_RESPONSES:
		var oldest: Dictionary = moss_footstep_responses.pop_front()
		var oldest_sprite: Sprite2D = oldest.sprite
		if is_instance_valid(oldest_sprite):
			oldest_sprite.queue_free()
	var sprite: = Sprite2D.new()
	sprite.texture = MOSS_RESPONSE
	sprite.hframes = 4
	sprite.position = world_position + Vector2(0, 15)
	sprite.scale = Vector2.ONE * (70.0 / 256.0)
	sprite.rotation = (float(posmod(moss_response_serial * 37, 17)) / 16.0 - 0.5) * 0.18
	sprite.modulate = Color(0.82, 1.0, 0.72, 0.0)
	sprite.z_index = 9
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	moss_footstep_responses.append({"sprite": sprite, "age": 0.0})
	moss_response_serial += 1


func _update_moss_footstep_responses(delta: float) -> void :
	for index in range(moss_footstep_responses.size() - 1, -1, -1):
		var response: Dictionary = moss_footstep_responses[index]
		response.age = float(response.age) + delta
		var progress: = clampf(float(response.age) / MOSS_FOOTSTEP_LIFETIME, 0.0, 1.0)
		var sprite: Sprite2D = response.sprite
		if progress >= 1.0 or not is_instance_valid(sprite):
			if is_instance_valid(sprite):
				sprite.queue_free()
			moss_footstep_responses.remove_at(index)
			continue
		sprite.frame = mini(3, floori(progress * 4.0))
		sprite.modulate.a = 0.29 * sin(progress * PI)
		sprite.scale = Vector2.ONE * (70.0 / 256.0) * lerpf(0.78, 1.06, progress)
		moss_footstep_responses[index] = response


func _clear_moss_footstep_responses() -> void :
	for response in moss_footstep_responses:
		var sprite: Sprite2D = response.sprite
		if is_instance_valid(sprite):
			sprite.queue_free()
	moss_footstep_responses.clear()


func debug_moss_environment_snapshot() -> Dictionary:
	var visible_moths: = 0
	for item in moss_glowmoths:
		var sprite: Sprite2D = item.sprite
		visible_moths += 1 if sprite.visible else 0
	var visible_drift: = 0
	for item in moss_drifts:
		var sprite: Sprite2D = item.sprite
		visible_drift += 1 if sprite.visible else 0
	return {
		"camp_asset": MOSS_CAMP_YARD.resource_path,
		"camp_path_asset": MOSS_CAMP_PATH.resource_path,
		"camp_yard_rect": MOSS_CAMP_YARD_RECT,
		"camp_connector_rect": MOSS_CAMP_CONNECTOR_RECT,
		"decor_asset": MOSS_ENVIRONMENT_DECOR.resource_path,
		"root_hollow_asset": MOSS_ROOT_HOLLOW.resource_path,
		"mushroom_cluster_asset": MOSS_MUSHROOM_CLUSTER.resource_path,
		"glowmoth_asset": MOSS_GLOWMOTH.resource_path,
		"drift_asset": MOSS_DRIFT.resource_path,
		"response_asset": MOSS_RESPONSE.resource_path,
		"decor_count": moss_decor_sprites.size(),
		"glowmoth_count": moss_glowmoths.size(),
		"drift_count": moss_drifts.size(),
		"visible_glowmoths": visible_moths,
		"visible_drift": visible_drift,
		"response_count": moss_footstep_responses.size(),
		"reduced_motion": moss_reduced_motion,
		"collision_neutral": true,
	}


func debug_later_surface_life_snapshot() -> Dictionary:
	var creature_counts: = {"moonglass": 0, "emberdeep": 0, "starfall": 0}
	var drift_counts: = {"moonglass": 0, "emberdeep": 0, "starfall": 0}
	var visible_creatures: = 0
	var visible_drifts: = 0
	for item in later_surface_creatures:
		var world_id: = String(item.world)
		creature_counts[world_id] = int(creature_counts[world_id]) + 1
		var sprite: Sprite2D = item.sprite
		visible_creatures += 1 if sprite.visible else 0
	for item in later_surface_drifts:
		var world_id: = String(item.world)
		drift_counts[world_id] = int(drift_counts[world_id]) + 1
		var sprite: Sprite2D = item.sprite
		visible_drifts += 1 if sprite.visible else 0
	return {
		"creature_assets": {
			"moonglass": LATER_SURFACE_CREATURE_TEXTURES.moonglass.resource_path,
			"emberdeep": LATER_SURFACE_CREATURE_TEXTURES.emberdeep.resource_path,
			"starfall": LATER_SURFACE_CREATURE_TEXTURES.starfall.resource_path,
		},
		"drift_assets": {
			"moonglass": LATER_SURFACE_DRIFT_TEXTURES.moonglass.resource_path,
			"emberdeep": LATER_SURFACE_DRIFT_TEXTURES.emberdeep.resource_path,
			"starfall": LATER_SURFACE_DRIFT_TEXTURES.starfall.resource_path,
		},
		"creature_counts": creature_counts,
		"drift_counts": drift_counts,
		"visible_creatures": visible_creatures,
		"visible_drifts": visible_drifts,
		"max_visible_drift_per_world": 3,
		"culled_offscreen": true,
		"collision_neutral": true,
	}


func _build_stations() -> void :


	_create_station(WAYFARER_SHOP, GameData.station("speedShop"), Vector2(142, 130), 45.0, "WAYFARER", "speedShop")
	_create_station(STARFORGE_STATION, GameData.station("starforge"), Vector2(158, 142), 50.0, "STARFORGE")


func _build_surface_chests() -> void :
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: = String(chest.id)
		assert (SURFACE_CHEST_TEXTURES.has(chest_id), "Missing surface chest art: %s" % chest_id)
		var textures: Dictionary = Dictionary(SURFACE_CHEST_TEXTURES[chest_id])
		var chest_position: = surface_chest_position(chest_id)
		var sprite: = _create_world_asset(
			textures.closed,
			chest_position,
			Vector2(104, 88),
			35.0,
			6
		)
		surface_chest_nodes[chest_id] = sprite
	_refresh_surface_chest_visuals()
	_sync_pending_chest_loot_drops()


func _refresh_surface_chest_visuals() -> void :
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: = String(chest.id)
		if not surface_chest_nodes.has(chest_id):
			continue
		var opened: = RunState.is_surface_chest_opened(chest_id)
		var ready: = _surface_chest_requirement_met(chest)
		var visual_key: = "%s:%s" % [str(opened), str(ready)]
		if String(chest_visual_state.get(chest_id, "")) == visual_key:
			continue
		chest_visual_state[chest_id] = visual_key
		var textures: Dictionary = Dictionary(SURFACE_CHEST_TEXTURES[chest_id])
		var texture: Texture2D = textures.open if opened else textures.closed
		var sprite: Sprite2D = surface_chest_nodes[chest_id]
		var chest_position: = surface_chest_position(chest_id)
		_place_world_asset_sprite(
			sprite,
			texture,
			chest_position,
			Vector2(104, 88),
			35.0
		)
		sprite.modulate = Color(1.0, 1.0, 1.0, 0.72 if opened else 1.0 if ready else 0.58)


func _refresh_surface_storage_nodes() -> void :
	var active_modules: Dictionary = {}
	var signature_rows: Array[String] = []
	for module_value in RunState.all_base_modules():
		var module: Dictionary = Dictionary(module_value)
		if (
			String(module.get("kind", "")) != "storage"
			or bool(module.get("packed", false))
			or String(module.get("scene", "")) != "surface"
			or int(module.get("depth", 1)) != 1
		):
			continue
		var module_id: = String(module.id)
		active_modules[module_id] = module
		signature_rows.append("%s:%.2f:%.2f" % [module_id, float(module.x), float(module.y)])
	signature_rows.sort()
	var signature: = "|".join(signature_rows)
	if signature == storage_visual_signature:
		return
	storage_visual_signature = signature
	for module_id_value in surface_storage_nodes.keys():
		var module_id: = String(module_id_value)
		if active_modules.has(module_id):
			continue
		var stale: Sprite2D = surface_storage_nodes[module_id]
		if is_instance_valid(stale):
			stale.queue_free()
		surface_storage_nodes.erase(module_id)
	for module_id_value in active_modules:
		var module_id: = String(module_id_value)
		var module: Dictionary = Dictionary(active_modules[module_id])
		var sprite: Sprite2D
		if surface_storage_nodes.has(module_id):
			sprite = surface_storage_nodes[module_id]
		else:
			sprite = _create_world_asset(
				STORAGE_CHEST,
				Vector2(float(module.x), float(module.y)),
				Vector2(104, 78),
				34.0,
				5
			)
			surface_storage_nodes[module_id] = sprite
		_place_world_asset_sprite(
			sprite,
			STORAGE_CHEST,
			Vector2(float(module.x), float(module.y)),
			Vector2(104, 78),
			34.0
		)


func _place_world_asset_sprite(
	sprite: Sprite2D,
	texture: Texture2D,
	anchor: Vector2,
	max_size: Vector2,
	bottom: float
) -> void :
	var texture_size: = Vector2(texture.get_size())
	var scale_factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var size: = texture_size * scale_factor
	sprite.texture = texture
	sprite.scale = Vector2.ONE * scale_factor
	sprite.position = anchor + Vector2( - size.x * 0.5, bottom - size.y)


func _surface_chest_requirement_met(chest: Dictionary) -> bool:
	var requirement: Dictionary = Dictionary(chest.get("requires", {}))
	if bool(requirement.get("starforge", false)):
		return not String(RunState.starforge_variant).is_empty()
	return int(RunState.pickaxe_level) >= int(requirement.get("pickaxeLevel", 1))


func _build_starfall_hub_lift() -> void :
	starfall_hub_lift_glow = Sprite2D.new()
	starfall_hub_lift_glow.texture = _timed_surface_glow_texture(STARFALL_LATTICE_ID)
	starfall_hub_lift_glow.position = STARFALL_HUB_LIFT_POSITION + Vector2(0, -18)
	starfall_hub_lift_glow.scale = Vector2.ONE * (246.0 / float(starfall_hub_lift_glow.texture.get_width()))
	starfall_hub_lift_glow.modulate = Color(0.42, 0.52, 1.0, 0.28)
	starfall_hub_lift_glow.z_index = 5
	add_child(starfall_hub_lift_glow)
	starfall_hub_lift_sprite = _create_world_asset(
		STARFALL_HUB_LIFT,
		STARFALL_HUB_LIFT_POSITION,
		Vector2(238, 210),
		78.0,
		6
	)
	starfall_hub_lift_base_scale = starfall_hub_lift_sprite.scale


func _update_starfall_hub_lift(delta: float) -> void :
	if not is_instance_valid(starfall_hub_lift_sprite):
		return
	starfall_hub_lift_visual_time += maxf(0.0, delta)
	var unlocked: = RunState.is_hub_unlocked()
	starfall_hub_lift_sprite.visible = unlocked
	starfall_hub_lift_glow.visible = unlocked
	if not unlocked:
		return
	if not _surface_visual_focus_active(STARFALL_HUB_LIFT_POSITION):
		return
	var pulse: = 0.5 + 0.5 * sin(starfall_hub_lift_visual_time * 2.4)
	starfall_hub_lift_sprite.scale = starfall_hub_lift_base_scale * (1.0 + pulse * 0.012)
	starfall_hub_lift_sprite.modulate = Color(0.94 + pulse * 0.06, 0.95 + pulse * 0.05, 1.0, 1.0)
	starfall_hub_lift_glow.modulate = Color(0.42, 0.52, 1.0, 0.22 + pulse * 0.16)


func _build_entrances() -> void :
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		var mine_data: Dictionary = GameData.mine(mine_id)
		var texture: Texture2D = ENTRANCE_TEXTURES[mine_id]
		var texture_size: = Vector2(texture.get_size())
		var max_size: = Vector2(MINE_ENTRANCE_MAX_SIZES[mine_id])
		var sprite_bottom: = float(MINE_ENTRANCE_BOTTOM_OFFSETS[mine_id])
		var scale_factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
		var size: = texture_size * scale_factor
		var position: = _mine_entrance(mine_id) + Vector2( - size.x * 0.5, sprite_bottom - size.y)
		var sprite: = _create_sprite(texture, Rect2(position, size), 6, mine_id == "emberMine")
		entrance_nodes[mine_id] = sprite
		var label: = _create_label(String(mine_data.name), _mine_entrance(mine_id) + Vector2(-92, 62), Vector2(184, 24), Color(String(mine_data.detail)))
		entrance_nodes["%s_label" % mine_id] = label


func _build_gates() -> void :
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		var gate_id: = String(boundary.id)
		var anchor: = Vector2(float(boundary.x), GATE_Y)
		portal_generator_nodes[gate_id] = _create_authored_arch(anchor, gate_id)
		var palette: Dictionary = Dictionary(PORTAL_SEAM_COLORS[gate_id])
		var transition: WorldTransitionVisual = WORLD_TRANSITION_VISUAL_SCENE.instantiate() as WorldTransitionVisual
		transition.position = anchor
		transition.show_boundary_frame = false
		transition.configure_seam(
			GATE_TEXTURES[gate_id],
			GATE_MARK_TEXTURES[gate_id],
			Color(palette.source),
			Color(palette.destination),
			true
		)
		transition.configure(
			gate_id,
			_raw_boundary_unlocked(boundary),
			moss_reduced_motion,
			PORTAL_CROSSING_DURATION
		)
		transition.set_external_arch_mode(true)
		add_child(transition)
		transition.set_process(false)
		transition.reset_actor_observation(player.global_position)
		portal_transitions[gate_id] = transition
		if gate_id == "moonglass":
			moonglass_transition = transition


func _generated_art_cutout_material() -> ShaderMaterial:
	var material: = ShaderMaterial.new()
	material.shader = ORE_MOUNTAIN_CUTOUT_SHADER
	return material


func _boundary_checker_cutout_material() -> ShaderMaterial:
	var material: = ShaderMaterial.new()
	material.shader = BOUNDARY_CHECKER_CUTOUT_SHADER
	return material


func _refresh_unlock_visibility() -> void :
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		var unlocked: = _is_mine_unlocked(mine_id)
		if entrance_nodes.has(mine_id):
			entrance_nodes[mine_id].visible = unlocked
		if entrance_nodes.has("%s_label" % mine_id):
			entrance_nodes["%s_label" % mine_id].visible = unlocked
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		var gate_id: = String(boundary.id)
		var unlocked: = _raw_boundary_unlocked(boundary)
		_sync_portal_transition(gate_id, unlocked, false)
	var hub_unlocked: = RunState.is_hub_unlocked()
	if is_instance_valid(starfall_hub_lift_sprite):
		starfall_hub_lift_sprite.visible = hub_unlocked
	if is_instance_valid(starfall_hub_lift_glow):
		starfall_hub_lift_glow.visible = hub_unlocked


func _create_tiled_ground(texture: Texture2D, destination: Rect2, z: int) -> TextureRect:
	var rect: = TextureRect.new()
	rect.texture = texture
	rect.position = destination.position
	rect.size = destination.size
	rect.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	rect.stretch_mode = TextureRect.STRETCH_TILE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = z
	add_child(rect)
	return rect


func _create_sprite(texture: Texture2D, destination: Rect2, z: int, flip_h: bool = false, rotation: float = 0.0) -> Sprite2D:
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = destination.position
	sprite.scale = destination.size / Vector2(texture.get_size())
	sprite.flip_h = flip_h
	sprite.rotation = rotation
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	return sprite


func _create_cropped_sprite(
	texture: Texture2D, source_rect: Rect2, full_destination: Rect2, z: int
) -> Sprite2D:
	var source_size: = Vector2(texture.get_size())
	var source_scale: = full_destination.size / source_size
	var cropped_texture: = AtlasTexture.new()
	cropped_texture.atlas = texture
	cropped_texture.region = source_rect
	var cropped_destination: = Rect2(
		full_destination.position + source_rect.position * source_scale,
		source_rect.size * source_scale
	)
	return _create_sprite(cropped_texture, cropped_destination, z)


func _create_centered_sprite(
	texture: Texture2D,
	center: Vector2,
	max_size: Vector2,
	z: int,
	flip_h: bool = false,
	rotation: float = 0.0,
	alpha: float = 1.0
) -> Sprite2D:
	var texture_size: = Vector2(texture.get_size())
	var scale_factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.position = center
	sprite.scale = Vector2.ONE * scale_factor
	sprite.flip_h = flip_h
	sprite.rotation = rotation
	sprite.modulate.a = alpha
	sprite.z_index = z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(sprite)
	return sprite


func _create_station(texture: Texture2D, station_data: Dictionary, max_size: Vector2, bottom: float, label_text: String, station_id: String = "") -> void :
	var position: = _station_position(station_id) if not station_id.is_empty() else Vector2(float(station_data.x), float(station_data.y))
	_create_world_asset(texture, position, max_size, bottom, 5)
	_create_label(label_text, position + Vector2(-65, bottom + 7), Vector2(130, 20), Color("e9d9a6"))


func _create_world_asset(texture: Texture2D, anchor: Vector2, max_size: Vector2, bottom: float, z: int, flip_h: bool = false, alpha: float = 1.0) -> Sprite2D:
	var texture_size: = Vector2(texture.get_size())
	var scale_factor: = minf(max_size.x / texture_size.x, max_size.y / texture_size.y)
	var size: = texture_size * scale_factor
	var sprite: = _create_sprite(texture, Rect2(anchor + Vector2( - size.x * 0.5, bottom - size.y), size), z, flip_h)
	sprite.modulate.a = alpha
	return sprite


func _create_portal_generator(texture: Texture2D, anchor: Vector2) -> Dictionary:
	var generator_texture: = AtlasTexture.new()
	generator_texture.atlas = texture
	generator_texture.region = PORTAL_GENERATOR_SOURCE_RECT
	var source_size: = PORTAL_GENERATOR_SOURCE_RECT.size
	var scale_factor: = minf(
		PORTAL_GENERATOR_MAX_SIZE.x / source_size.x,
		PORTAL_GENERATOR_MAX_SIZE.y / source_size.y
	)
	var size: = source_size * scale_factor
	var top_left: = anchor + Vector2( - size.x * 0.5, PORTAL_GENERATOR_BOTTOM - size.y)
	var sprite: = _create_sprite(generator_texture, Rect2(top_left, size), 6)
	return {
		"sprite": sprite,
		"rect": Rect2(top_left, size),
	}


func _create_label(text: String, position: Vector2, size: Vector2, color: Color) -> Label:
	var label: = Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.add_theme_font_size_override("font_size", 10)
	label.z_index = 7
	add_child(label)
	return label


func _on_player_moved(world_position: Vector2) -> void :
	for transition_value in portal_transitions.values():
		var transition: WorldTransitionVisual = transition_value as WorldTransitionVisual
		if is_instance_valid(transition):
			transition.observe_actor_position(world_position)
	var step_distance: = world_position.distance_to(moss_last_footstep_position)
	moss_last_footstep_position = world_position
	if world_position.x <= GROUND_RECTS.mossvein.end.x:
		moss_footstep_distance += step_distance
		if moss_footstep_distance >= MOSS_FOOTSTEP_DISTANCE:
			moss_footstep_distance = fmod(moss_footstep_distance, MOSS_FOOTSTEP_DISTANCE)
			_spawn_moss_footstep(world_position)
	else:
		moss_footstep_distance = 0.0
	_evaluate_context(world_position)
	if RunState.has_method("set_surface_position"):
		RunState.set_surface_position(world_position)


func _on_run_state_changed() -> void :
	player.movement_speed = _movement_speed()
	if not visible or process_mode == Node.PROCESS_MODE_DISABLED:
		run_state_refresh_pending = true
		return
	_refresh_from_run_state()


func _refresh_from_run_state() -> void :
	_refresh_surface_chest_visuals()
	_refresh_surface_storage_nodes()
	_sync_pending_chest_loot_drops()
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		var gate_id: = String(boundary.id)
		var unlocked: = _raw_boundary_unlocked(boundary)
		var was_unlocked: = bool(gate_unlock_state.get(gate_id, unlocked))
		if unlocked and not was_unlocked:
			_sync_portal_transition(gate_id, true, true)
		gate_unlock_state[gate_id] = unlocked
	_refresh_unlock_visibility()
	_evaluate_context(player.global_position)


func _update_mobile_surface_resources(delta: float, now_unix: int) -> void :
	var moss_active: = (
		active_context == "ore_mountain"
		or _surface_visual_focus_active(MOSS_ORE_MOUNTAIN_FOCUS)
	)
	if moss_active:
		if ore_mountain_passive_elapsed > 0.0:
			_update_ore_mountain_passive(ore_mountain_passive_elapsed, now_unix)
			ore_mountain_passive_elapsed = 0.0
		_update_ore_mountain(delta, now_unix)
		mobile_active_resource_updates += 1
	else:
		ore_mountain_passive_elapsed += delta
		if ore_mountain_passive_elapsed >= SURFACE_PASSIVE_TICK:
			_update_ore_mountain_passive(ore_mountain_passive_elapsed, now_unix)
			ore_mountain_passive_elapsed = 0.0

	var moon_active: = (
		active_context == "moonglass_resource"
		or _surface_visual_focus_active(MOON_BLOOM_CENTER)
	)
	if moon_active:
		if moon_bloom_passive_elapsed > 0.0:
			_update_moonglass_resource_passive(moon_bloom_passive_elapsed, now_unix)
			moon_bloom_passive_elapsed = 0.0
		_update_moonglass_resource(delta, now_unix)
		mobile_active_resource_updates += 1
	else:
		moon_bloom_passive_elapsed += delta
		if moon_bloom_passive_elapsed >= SURFACE_PASSIVE_TICK:
			_update_moonglass_resource_passive(moon_bloom_passive_elapsed, now_unix)
			moon_bloom_passive_elapsed = 0.0

	_update_timed_surface_resources(delta, now_unix)
	_update_surface_resource_mountains(delta, now_unix)


func _update_surface_resource_mountains(delta: float, now_unix: int = -1) -> void :
	_update_surface_resource_mountain_drops(delta)
	_update_surface_resource_mountain_impacts(delta)
	var active_mountain_id: = active_context if SURFACE_RESOURCE_MOUNTAIN_IDS.has(active_context) else ""
	for mountain_id_value in SURFACE_RESOURCE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		if not surface_resource_mountains.has(mountain_id):
			continue
		var entry: Dictionary = surface_resource_mountains[mountain_id]
		entry.hit_flash = maxf(0.0, float(entry.hit_flash) - delta)
		entry.hit_elapsed = maxf(0.0, float(entry.hit_elapsed) - delta)
		entry.collapse_elapsed = maxf(0.0, float(entry.collapse_elapsed) - delta)
		entry.visual_elapsed = float(entry.get("visual_elapsed", SURFACE_DYNAMIC_VISUAL_TICK)) + delta
		if mountain_id != active_mountain_id:
			entry.swing_active = false
			entry.swing_elapsed = 0.0
			entry.swing_hit = false
		surface_resource_mountains[mountain_id] = entry
		_apply_surface_resource_mountain_regrowth(mountain_id, delta)
		entry = surface_resource_mountains[mountain_id]
		entry.last_growth_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
		var visual_active: = (
			mountain_id == active_mountain_id
			or _surface_visual_focus_active(Vector2(Dictionary(SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]).anchor))
			or float(entry.hit_elapsed) > 0.0
			or float(entry.collapse_elapsed) > 0.0
		)
		var visual_tick: = SURFACE_DYNAMIC_VISUAL_TICK if visual_active else SURFACE_PASSIVE_TICK
		var refresh_visual: = float(entry.visual_elapsed) >= visual_tick
		if refresh_visual:
			entry.visual_elapsed = fmod(float(entry.visual_elapsed), visual_tick)
		surface_resource_mountains[mountain_id] = entry
		if refresh_visual:
			_update_surface_resource_mountain_visual(mountain_id)
			mobile_dynamic_visual_updates += 1
		else:
			mobile_dynamic_visual_updates_skipped += 1
	if active_mountain_id.is_empty() or not _surface_resource_mountain_unlocked(active_mountain_id):
		return
	var entry: Dictionary = surface_resource_mountains[active_mountain_id]
	var held: = external_mine_held or Input.is_action_pressed("mine")
	if not bool(entry.swing_active):
		if not held:
			player.set_mining_visual(false)
			return
		entry.swing_active = true
		entry.swing_elapsed = 0.0
		entry.swing_hit = false
		entry.swing_duration = float(_mountain_tool().get("cooldown", 0.72))
		entry.swing_target = _surface_resource_mountain_hit_point(active_mountain_id, player.global_position)
	entry.swing_elapsed = float(entry.swing_elapsed) + delta
	var progress: = clampf(
		float(entry.swing_elapsed) / maxf(0.001, float(entry.swing_duration)),
		0.0, 1.0
	)
	player.set_facing(_ore_mountain_facing_direction(player.global_position, Vector2(entry.swing_target)))
	player.set_mining_visual(true, progress)
	if not bool(entry.swing_hit) and progress >= _tool_strike_progress():
		entry.swing_hit = true
		surface_resource_mountains[active_mountain_id] = entry
		_mine_surface_resource_mountain_once(active_mountain_id)
		entry = surface_resource_mountains[active_mountain_id]
	if float(entry.swing_elapsed) >= float(entry.swing_duration):
		var overflow: = maxf(0.0, float(entry.swing_elapsed) - float(entry.swing_duration))
		entry.swing_active = false
		if held:
			entry.swing_active = true
			entry.swing_duration = float(_mountain_tool().get("cooldown", 0.72))
			entry.swing_elapsed = fposmod(overflow, maxf(0.001, float(entry.swing_duration)))
			entry.swing_hit = false
			entry.swing_target = _surface_resource_mountain_hit_point(active_mountain_id, player.global_position)
			player.set_mining_visual(true, float(entry.swing_elapsed) / maxf(0.001, float(entry.swing_duration)))
		else:
			player.set_mining_visual(false)
	surface_resource_mountains[active_mountain_id] = entry


func _apply_surface_resource_mountain_regrowth(mountain_id: String, delta: float) -> void :
	if delta <= 0.0 or not surface_resource_mountains.has(mountain_id):
		return
	var entry: Dictionary = surface_resource_mountains[mountain_id]
	if int(entry.hp) >= SURFACE_RESOURCE_MOUNTAIN_MAX_HP:
		entry.hp = SURFACE_RESOURCE_MOUNTAIN_MAX_HP
		entry.growth_buffer = 0.0
		entry.rare_ready = true
		surface_resource_mountains[mountain_id] = entry
		return
	entry.growth_buffer = float(entry.growth_buffer) + (
		delta * float(SURFACE_RESOURCE_MOUNTAIN_MAX_HP) / SURFACE_RESOURCE_MOUNTAIN_REGROWTH_SECONDS
	)
	var growth: = floori(float(entry.growth_buffer))
	if growth > 0:
		var applied: = mini(growth, SURFACE_RESOURCE_MOUNTAIN_MAX_HP - int(entry.hp))
		entry.hp = int(entry.hp) + applied
		entry.growth_buffer = float(entry.growth_buffer) - float(applied)
	if int(entry.hp) >= SURFACE_RESOURCE_MOUNTAIN_MAX_HP:
		entry.hp = SURFACE_RESOURCE_MOUNTAIN_MAX_HP
		entry.growth_buffer = 0.0
		entry.rare_ready = true
	surface_resource_mountains[mountain_id] = entry


func _catch_up_surface_resource_mountains() -> void :
	var now: = int(Time.get_unix_time_from_system())
	for mountain_id_value in SURFACE_RESOURCE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		if not surface_resource_mountains.has(mountain_id):
			continue
		var entry: Dictionary = surface_resource_mountains[mountain_id]
		var saved_unix: = int(entry.last_growth_unix)
		if saved_unix > 0:
			_apply_surface_resource_mountain_regrowth(mountain_id, float(maxi(0, now - saved_unix)))
		entry = surface_resource_mountains[mountain_id]
		entry.last_growth_unix = now
		surface_resource_mountains[mountain_id] = entry
		_update_surface_resource_mountain_visual(mountain_id)


func _surface_visual_focus_active(focus: Vector2) -> bool:
	if not is_instance_valid(player):
		return true
	var offset: = player.global_position - focus
	return (
		absf(offset.x) <= SURFACE_VISUAL_ACTIVE_HALF_SIZE.x
		and absf(offset.y) <= SURFACE_VISUAL_ACTIVE_HALF_SIZE.y
	)


func _update_ore_mountain_passive(delta: float, now_unix: int = -1) -> void :
	if delta <= 0.0:
		return
	_update_ore_drops(delta)
	_update_mountain_impacts(delta)
	ore_mountain_hit_flash = maxf(0.0, ore_mountain_hit_flash - delta)
	ore_mountain_collapse_elapsed = maxf(0.0, ore_mountain_collapse_elapsed - delta)
	_apply_ore_mountain_regrowth(delta)
	ore_mountain_last_growth_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	mobile_passive_resource_updates += 1


func _update_ore_mountain(delta: float, now_unix: int = -1) -> void :
	_update_ore_drops(delta)
	_update_mountain_impacts(delta)
	ore_mountain_hit_flash = maxf(0.0, ore_mountain_hit_flash - delta)
	ore_mountain_collapse_elapsed = maxf(0.0, ore_mountain_collapse_elapsed - delta)
	_apply_ore_mountain_regrowth(delta)
	ore_mountain_last_growth_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	var hp_ratio: = clampf(float(ore_mountain_hp) / float(MOSS_ORE_MOUNTAIN_MAX_HP), 0.0, 1.0)
	_update_ore_mountain_visual(hp_ratio)
	var pulse: = 1.0 + (ore_mountain_hit_flash / 0.14) * 0.04 if ore_mountain_hit_flash > 0.0 else 1.0
	ore_mountain_sprite.scale = ore_mountain_base_scale * pulse
	ore_mountain_blend_sprite.scale = ore_mountain_base_scale * pulse
	if ore_mountain_collapse_elapsed > 0.0:
		var collapse_progress: = 1.0 - ore_mountain_collapse_elapsed / ore_mountain_collapse_duration
		var collapse_strength: = (1.0 - collapse_progress) * 8.0
		var collapse_offset: = Vector2(sin(collapse_progress * 73.0) * collapse_strength, cos(collapse_progress * 91.0) * collapse_strength * 0.45)
		ore_mountain_sprite.position = ore_mountain_base_position + collapse_offset
		ore_mountain_blend_sprite.position = ore_mountain_base_position + collapse_offset
	else:
		ore_mountain_sprite.position = ore_mountain_base_position
		ore_mountain_blend_sprite.position = ore_mountain_base_position
	if Input.is_action_just_pressed("mine"):
		ore_mountain_input_buffer = MOSS_ORE_MOUNTAIN_INPUT_BUFFER
	var held: = external_mine_held or Input.is_action_pressed("mine") or ore_mountain_input_buffer > 0.0
	ore_mountain_input_buffer = maxf(0.0, ore_mountain_input_buffer - delta)
	if active_context != "ore_mountain":
		ore_mountain_swing_active = false
		player.set_mining_visual(false)
		return
	if not ore_mountain_swing_active:
		if not held:
			player.set_mining_visual(false)
			return
		ore_mountain_swing_active = true
		ore_mountain_swing_elapsed = 0.0
		ore_mountain_swing_hit = false
		ore_mountain_swing_duration = float(_mountain_tool().get("cooldown", 0.72))
		ore_mountain_swing_target = _ore_mountain_hit_point(player.global_position)
		ore_mountain_input_buffer = 0.0
	player.set_facing(_ore_mountain_facing_direction(player.global_position, ore_mountain_swing_target))
	ore_mountain_swing_elapsed += delta
	var progress: = clampf(ore_mountain_swing_elapsed / ore_mountain_swing_duration, 0.0, 1.0)
	player.set_mining_visual(true, progress)
	if not ore_mountain_swing_hit and progress >= _tool_strike_progress():
		ore_mountain_swing_hit = true
		_mine_ore_mountain_once()
	if ore_mountain_swing_elapsed >= ore_mountain_swing_duration:
		var overflow: = maxf(0.0, ore_mountain_swing_elapsed - ore_mountain_swing_duration)
		ore_mountain_swing_active = false
		if held:
			ore_mountain_swing_active = true
			ore_mountain_swing_duration = float(_mountain_tool().get("cooldown", 0.72))
			ore_mountain_swing_elapsed = fposmod(overflow, maxf(0.001, ore_mountain_swing_duration))
			ore_mountain_swing_hit = false
			ore_mountain_swing_target = _ore_mountain_hit_point(player.global_position)
			player.set_mining_visual(true, ore_mountain_swing_elapsed / maxf(0.001, ore_mountain_swing_duration))
		else:
			player.set_mining_visual(false)


func _update_ore_mountain_visual(hp_ratio: float) -> void :
	var stages: Array[Texture2D] = [
		MOSS_ORE_MOUNTAIN_DAMAGE_3,
		MOSS_ORE_MOUNTAIN_DAMAGE_2,
		MOSS_ORE_MOUNTAIN_DAMAGE_1,
		MOSS_ORE_MOUNTAIN,
	]
	var tint: = Color(1.14, 1.07, 0.98, 1.0) if ore_mountain_hit_flash > 0.0 else Color.WHITE
	if hp_ratio >= 0.999:
		ore_mountain_sprite.texture = stages[3]
		ore_mountain_sprite.modulate = tint
		ore_mountain_sprite.material.set_shader_parameter("stage_mix", 0.0)
		ore_mountain_blend_sprite.visible = false
		return
	var stage_position: = clampf(hp_ratio, 0.0, 1.0) * 3.0
	var stage_index: = mini(2, floori(stage_position))
	var blend: = smoothstep(0.0, 1.0, stage_position - float(stage_index))
	ore_mountain_sprite.texture = stages[stage_index]
	ore_mountain_sprite.modulate = tint
	ore_mountain_sprite.material.set_shader_parameter("next_stage", stages[stage_index + 1])
	ore_mountain_sprite.material.set_shader_parameter("stage_mix", blend)
	ore_mountain_blend_sprite.visible = false


func _apply_ore_mountain_regrowth(delta: float) -> void :
	if delta <= 0.0 or ore_mountain_hp >= MOSS_ORE_MOUNTAIN_MAX_HP:
		if ore_mountain_hp >= MOSS_ORE_MOUNTAIN_MAX_HP:
			ore_mountain_growth_buffer = 0.0
			ore_mountain_gold_ready = true
		return
	ore_mountain_growth_buffer += delta * float(MOSS_ORE_MOUNTAIN_MAX_HP) / MOSS_ORE_MOUNTAIN_REGROWTH_SECONDS
	var growth: = floori(ore_mountain_growth_buffer)
	if growth <= 0:
		return
	var applied: = mini(growth, MOSS_ORE_MOUNTAIN_MAX_HP - ore_mountain_hp)
	ore_mountain_hp += applied
	ore_mountain_growth_buffer -= float(applied)
	if ore_mountain_hp >= MOSS_ORE_MOUNTAIN_MAX_HP:
		ore_mountain_hp = MOSS_ORE_MOUNTAIN_MAX_HP
		ore_mountain_growth_buffer = 0.0
		ore_mountain_gold_ready = true


func _catch_up_ore_mountain() -> void :
	var now: = int(Time.get_unix_time_from_system())
	if ore_mountain_last_growth_unix > 0:
		_apply_ore_mountain_regrowth(float(maxi(0, now - ore_mountain_last_growth_unix)))
	ore_mountain_last_growth_unix = now


func _update_moonglass_resource_passive(delta: float, now_unix: int = -1) -> void :
	if delta <= 0.0:
		return
	_update_moonglass_drops(delta)
	_update_moonglass_effects(delta)
	moon_bloom_visual_time += delta
	_advance_moonglass_bloom(delta)
	moon_bloom_updated_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	mobile_passive_resource_updates += 1


func _update_moonglass_resource(delta: float, now_unix: int = -1) -> void :
	_update_moonglass_drops(delta)
	_update_moonglass_effects(delta)
	moon_bloom_visual_time += delta
	_advance_moonglass_bloom(delta)
	moon_bloom_updated_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	_update_moonglass_visual()
	var held: = external_mine_held or Input.is_action_pressed("mine")
	if active_context != "moonglass_resource":
		moon_bloom_swing_active = false
		moon_bloom_target_index = -1
		if active_context != "ore_mountain":
			player.set_mining_visual(false)
		return
	if not moon_bloom_swing_active:
		if not held:
			player.set_mining_visual(false)
			return
		moon_bloom_target_index = _nearest_moonglass_bloom_node()
		if moon_bloom_target_index < 0:
			player.set_mining_visual(false)
			return
		moon_bloom_swing_active = true
		moon_bloom_swing_elapsed = 0.0
		moon_bloom_swing_hit = false
		moon_bloom_swing_duration = float(_mountain_tool().get("cooldown", 0.72))
		var target_position: = Vector2(moon_bloom_nodes[moon_bloom_target_index].position)
		player.set_facing((target_position - player.global_position).normalized())
	moon_bloom_swing_elapsed += delta
	var progress: = clampf(
		moon_bloom_swing_elapsed / maxf(0.001, moon_bloom_swing_duration),
		0.0,
		1.0
	)
	player.set_mining_visual(true, progress)
	if not moon_bloom_swing_hit and progress >= _tool_strike_progress():
		moon_bloom_swing_hit = true
		_mine_moonglass_resource_once()
	if moon_bloom_swing_elapsed >= moon_bloom_swing_duration:
		var overflow: = maxf(0.0, moon_bloom_swing_elapsed - moon_bloom_swing_duration)
		moon_bloom_swing_active = false
		if held:
			moon_bloom_target_index = _nearest_moonglass_bloom_node()
			if moon_bloom_target_index >= 0:
				moon_bloom_swing_active = true
				moon_bloom_swing_duration = float(_mountain_tool().get("cooldown", 0.72))
				moon_bloom_swing_elapsed = fposmod(overflow, maxf(0.001, moon_bloom_swing_duration))
				moon_bloom_swing_hit = false
				var next_target_position: = Vector2(moon_bloom_nodes[moon_bloom_target_index].position)
				player.set_facing((next_target_position - player.global_position).normalized())
				player.set_mining_visual(true, moon_bloom_swing_elapsed / maxf(0.001, moon_bloom_swing_duration))
			else:
				player.set_mining_visual(false)
		else:
			player.set_mining_visual(false)


func _update_moonglass_visual() -> void :
	var active_energy: = 1.0 - clampf(moon_bloom_timer / MOON_BLOOM_TIME_LIMIT, 0.0, 1.0)
	for index in range(moon_bloom_nodes.size()):
		var node: Dictionary = moon_bloom_nodes[index]
		var intact: = int(node.hp) > 0
		var sprite: Sprite2D = moon_bloom_sprites[index]
		var glow: Sprite2D = moon_bloom_glows[index]
		sprite.visible = intact
		var speed: = 5.4 if moon_bloom_status == "active" else 2.2
		var pulse: = 0.5 + 0.5 * sin(moon_bloom_visual_time * speed + float(index) * 1.7)
		if intact:
			sprite.scale = moon_bloom_base_scales[index] * (1.0 + pulse * 0.035)
			sprite.modulate = Color(0.88, 1.04, 1.08, 1.0)
		glow.visible = true
		glow.scale = Vector2.ONE * (lerpf(80.0, 108.0, pulse) / float(glow.texture.get_width()))
		glow.modulate = Color(
			0.28,
			0.92,
			1.0,
			(0.34 + active_energy * 0.18) * (0.45 + pulse * 0.55) if intact else 0.1
		)


func _advance_moonglass_bloom(delta: float) -> void :
	if delta <= 0.0:
		return
	if moon_bloom_status == "active":
		moon_bloom_timer = maxf(0.0, moon_bloom_timer - delta)
		if moon_bloom_timer <= 0.0:
			moon_bloom_status = "failed"
	for index in range(moon_bloom_nodes.size()):
		var node: Dictionary = moon_bloom_nodes[index]
		if int(node.hp) > 0:
			continue
		node.respawn = maxf(0.0, float(node.respawn) - delta)
		if float(node.respawn) <= 0.0:
			node.hp = MOON_BLOOM_NODE_MAX_HP
			node.respawn = 0.0
		moon_bloom_nodes[index] = node
	if _all_moonglass_bloom_nodes_intact() and moon_bloom_status != "active":
		moon_bloom_status = "idle"
		moon_bloom_timer = 0.0


func _catch_up_moonglass_resource() -> void :
	var now: = int(Time.get_unix_time_from_system())
	if moon_bloom_updated_unix > 0:
		_advance_moonglass_bloom(float(maxi(0, now - moon_bloom_updated_unix)))
	moon_bloom_updated_unix = now


func _mine_moonglass_resource_once() -> void :
	if active_context != "moonglass_resource" or not bool(RunState.area_unlocked):
		return
	if moon_bloom_target_index < 0 or moon_bloom_target_index >= moon_bloom_nodes.size():
		moon_bloom_target_index = _nearest_moonglass_bloom_node()
	if moon_bloom_target_index < 0:
		return
	var node: Dictionary = moon_bloom_nodes[moon_bloom_target_index]
	if int(node.hp) <= 0:
		return
	moon_bloom_hit_count += 1
	_spawn_moonglass_effect(false, Vector2(node.position))
	_spawn_surface_material_spray(MOON_BLOOM_ID, Vector2(node.position))
	var tool: = _mountain_tool()
	node.hp = maxi(0, int(node.hp) - int(tool.get("power", 1)))
	AudioDirector.play_mining("moonglass", int(node.hp) <= 0, false)
	if int(node.hp) > 0:
		moon_bloom_nodes[moon_bloom_target_index] = node
		return
	node.respawn = MOON_BLOOM_RESPAWN_SECONDS
	moon_bloom_nodes[moon_bloom_target_index] = node
	var yield_amount: = 1
	if randf() < clampf(float(tool.get("yield_bonus", 0.0)), 0.0, 0.92):
		yield_amount += 1
	yield_amount *= maxi(1, int(tool.get("yield_multiplier", 1)))
	_spawn_moonglass_drop("moonglass", yield_amount, moon_bloom_hit_count, Vector2(node.position))
	RunState.record_mined("moonglass", yield_amount)
	if moon_bloom_status == "idle":
		moon_bloom_status = "active"
		moon_bloom_timer = MOON_BLOOM_TIME_LIMIT
	if moon_bloom_status == "active" and _all_moonglass_bloom_nodes_broken():
		_emit_moonglass_pulse()
	moon_bloom_target_index = _nearest_moonglass_bloom_node()


func _emit_moonglass_pulse() -> void :
	moon_bloom_status = "completed"
	moon_bloom_timer = 0.0
	moon_bloom_completions += 1
	_spawn_moonglass_effect(true, MOON_BLOOM_CENTER)
	AudioDirector.play_discovery()
	var reward_index: = 0
	for kind_value in MOON_BLOOM_BONUS:
		var kind: = String(kind_value)
		var amount: = int(MOON_BLOOM_BONUS[kind])
		for _piece in range(amount):
			_spawn_moonglass_drop(kind, 1, reward_index, MOON_BLOOM_CENTER)
			reward_index += 1
		RunState.record_mined(kind, amount)


func _nearest_moonglass_bloom_node() -> int:
	var nearest_index: = -1
	var nearest_distance: = INF
	for index in range(moon_bloom_nodes.size()):
		var node: Dictionary = moon_bloom_nodes[index]
		if int(node.hp) <= 0:
			continue
		var distance: = player.global_position.distance_to(Vector2(node.position))
		if distance > _effective_mining_range(MOON_BLOOM_NODE_CONTEXT_RADIUS):
			continue
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index


func _is_near_moonglass_bloom(world_position: Vector2) -> bool:
	for position_value in MOON_BLOOM_NODE_POSITIONS:
		if world_position.distance_to(Vector2(position_value)) <= _effective_mining_range(MOON_BLOOM_NODE_CONTEXT_RADIUS):
			return true
	return false


func _all_moonglass_bloom_nodes_broken() -> bool:
	for node in moon_bloom_nodes:
		if int(Dictionary(node).hp) > 0:
			return false
	return not moon_bloom_nodes.is_empty()


func _all_moonglass_bloom_nodes_intact() -> bool:
	for node in moon_bloom_nodes:
		if int(Dictionary(node).hp) <= 0:
			return false
	return not moon_bloom_nodes.is_empty()


func _spawn_moonglass_drop(
	kind: String,
	amount: int,
	spread_index: int,
	origin: Vector2 = MOON_BLOOM_CENTER
) -> void :
	var texture: Texture2D = STARSHARD_DROP if kind == "starshard" else MOONGLASS_DROP
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = DropVisuals.sprite_offset(kind, texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 10
	sprite.scale = DropVisuals.sprite_scale(kind, texture)
	var landing_offset: Vector2 = MOON_DROP_LANDING_OFFSETS[
		spread_index % MOON_DROP_LANDING_OFFSETS.size()
	] * 0.48
	landing_offset += Vector2(
		float((spread_index * 23) % 21) - 10.0,
		float((spread_index * 31) % 15) - 7.0
	)
	sprite.position = origin + Vector2(
		float((spread_index * 17) % 25) - 12.0,
		-12.0
	)
	add_child(sprite)
	moon_bloom_drops.append({
		"kind": kind,
		"amount": amount,
		"sprite": sprite,
		"base_scale": sprite.scale,
		"launch_position": sprite.position,
		"landing_position": origin + landing_offset,
		"age": 0.0,
		"budget_serial": _next_surface_drop_budget_serial(),
		"collecting": false,
		"collect_elapsed": 0.0,
		"collect_origin": Vector2.ZERO,
		"settled": false,
	})
	_enforce_surface_loose_drop_budget()


func _spawn_moonglass_effect(pulse: bool, origin: Vector2) -> void :
	var sprite: = Sprite2D.new()
	sprite.texture = MOON_RESPONSE if pulse else MOON_IMPACT
	sprite.hframes = 4
	sprite.frame = 0
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 9
	var jitter: = Vector2(
		float((moon_bloom_hit_count * 29) % 21) - 10.0,
		float((moon_bloom_hit_count * 19) % 15) - 7.0
	)
	sprite.position = origin + (Vector2.ZERO if pulse else jitter)
	var target_size: = 286.0 if pulse else 92.0
	sprite.scale = Vector2.ONE * (target_size / 256.0)
	add_child(sprite)
	moon_bloom_effects.append({
		"sprite": sprite,
		"age": 0.0,
		"life": 0.66 if pulse else 0.3,
		"base_scale": sprite.scale,
		"pulse": pulse,
	})


func _update_moonglass_effects(delta: float) -> void :
	for index in range(moon_bloom_effects.size() - 1, -1, -1):
		var effect: Dictionary = moon_bloom_effects[index]
		var sprite: Sprite2D = effect.sprite
		if not is_instance_valid(sprite):
			moon_bloom_effects.remove_at(index)
			continue
		var age: = float(effect.age) + delta
		var progress: = clampf(age / float(effect.life), 0.0, 1.0)
		sprite.frame = mini(3, floori(progress * 4.0))
		var bloom: = sin(progress * PI) * (0.18 if bool(effect.pulse) else 0.08)
		sprite.scale = Vector2(effect.base_scale) * (1.0 + bloom)
		sprite.modulate.a = 1.0 - clampf((progress - 0.68) / 0.32, 0.0, 1.0)
		effect.age = age
		moon_bloom_effects[index] = effect
		if progress >= 1.0:
			sprite.queue_free()
			moon_bloom_effects.remove_at(index)


func _update_moonglass_drops(delta: float) -> void :
	for index in range(moon_bloom_drops.size() - 1, -1, -1):
		var drop: Dictionary = moon_bloom_drops[index]
		var sprite: Sprite2D = drop.sprite
		if not is_instance_valid(sprite):
			moon_bloom_drops.remove_at(index)
			continue
		var age: = float(drop.age) + delta
		if age >= LOOSE_RESOURCE_LIFETIME:
			RunState.add_resource(String(drop.kind), int(drop.amount), false)
			sprite.queue_free()
			moon_bloom_drops.remove_at(index)
			continue
		if bool(drop.collecting):
			var collect_elapsed: = float(drop.collect_elapsed) + delta
			var collect_progress: = clampf(
				collect_elapsed / ORE_DROP_COLLECT_DURATION,
				0.0,
				1.0
			)
			var collect_eased: = collect_progress * collect_progress * (3.0 - 2.0 * collect_progress)
			sprite.global_position = Vector2(drop.collect_origin).lerp(
				player.global_position + Vector2(0, -28),
				collect_eased
			)
			sprite.global_position.y -= sin(collect_progress * PI) * 15.0
			sprite.scale = Vector2(drop.base_scale) * lerpf(1.0, 0.24, collect_eased)
			sprite.modulate.a = 1.0 - clampf((collect_progress - 0.68) / 0.32, 0.0, 1.0)
			drop.collect_elapsed = collect_elapsed
			moon_bloom_drops[index] = drop
			if collect_progress >= 1.0:
				RunState.add_resource(String(drop.kind), int(drop.amount), false)
				AudioDirector.play_pickup(String(drop.kind), int(drop.amount))
				sprite.queue_free()
				moon_bloom_drops.remove_at(index)
			continue
		if age < ORE_DROP_FLIGHT_DURATION:
			var flight_progress: = clampf(age / ORE_DROP_FLIGHT_DURATION, 0.0, 1.0)
			var eased: = 1.0 - pow(1.0 - flight_progress, 2.0)
			sprite.position = Vector2(drop.launch_position).lerp(Vector2(drop.landing_position), eased)
			sprite.position.y -= sin(flight_progress * PI) * 92.0
			sprite.rotation = flight_progress * TAU * (1.4 if index % 2 == 0 else -1.4)
			sprite.scale = Vector2(drop.base_scale) * (1.0 + sin(flight_progress * PI) * 0.22)
		elif not bool(drop.get("settled", false)):
			sprite.position = Vector2(drop.landing_position)
			sprite.rotation = sin(float(index) * 1.9) * 0.17
			sprite.scale = Vector2(drop.base_scale)
			drop.settled = true
		sprite.modulate.a = _loose_resource_alpha(age)
		drop.age = age
		moon_bloom_drops[index] = drop
		if (
			age >= ORE_DROP_FLIGHT_DURATION
			and sprite.global_position.distance_to(player.global_position) <= _ore_drop_pickup_radius()
		):
			drop.collecting = true
			drop.collect_elapsed = 0.0
			drop.collect_origin = sprite.global_position
			moon_bloom_drops[index] = drop


func _update_timed_surface_resources(delta: float, now_unix: int = -1) -> void :
	var active_vein_id: = ""
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		var runtime: Dictionary = timed_surface_veins.get(vein_id, {})
		if runtime.is_empty():
			continue
		var config: = _timed_surface_config(vein_id)
		if active_context != String(config.context):
			runtime.swing_active = false
			runtime.swing_elapsed = 0.0
			runtime.swing_hit = false
			runtime.target_index = -1
			timed_surface_veins[vein_id] = runtime
		var visual_active: = (
			active_context == String(config.context)
			or _surface_visual_focus_active(Vector2(config.center))
		)
		if not visual_active:
			var passive_elapsed: = float(timed_surface_passive_elapsed.get(vein_id, 0.0)) + delta
			if passive_elapsed >= SURFACE_PASSIVE_TICK:
				_update_timed_surface_resource_passive(vein_id, passive_elapsed, now_unix)
				passive_elapsed = 0.0
			timed_surface_passive_elapsed[vein_id] = passive_elapsed
			continue
		var pending_passive: = float(timed_surface_passive_elapsed.get(vein_id, 0.0))
		if pending_passive > 0.0:
			_update_timed_surface_resource_passive(vein_id, pending_passive, now_unix)
			timed_surface_passive_elapsed[vein_id] = 0.0
		_update_timed_surface_drops(vein_id, delta)
		_update_timed_surface_effects(vein_id, delta)
		runtime = timed_surface_veins[vein_id]
		runtime.visual_time = float(runtime.visual_time) + delta
		runtime.visual_elapsed = float(runtime.get("visual_elapsed", SURFACE_DYNAMIC_VISUAL_TICK)) + delta
		timed_surface_veins[vein_id] = runtime
		_advance_timed_surface_resource(vein_id, delta)
		runtime = timed_surface_veins[vein_id]
		runtime.updated_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
		var refresh_visual: = float(runtime.visual_elapsed) >= SURFACE_DYNAMIC_VISUAL_TICK
		if refresh_visual:
			runtime.visual_elapsed = fmod(float(runtime.visual_elapsed), SURFACE_DYNAMIC_VISUAL_TICK)
		timed_surface_veins[vein_id] = runtime
		if refresh_visual:
			_update_timed_surface_visual(vein_id)
			mobile_dynamic_visual_updates += 1
		else:
			mobile_dynamic_visual_updates_skipped += 1
		mobile_active_resource_updates += 1
		if active_context == String(config.context):
			active_vein_id = vein_id
	if active_vein_id.is_empty():
		if active_context != "ore_mountain" and active_context != "moonglass_resource":
			player.set_mining_visual(false)
		return
	var runtime: Dictionary = timed_surface_veins[active_vein_id]
	var held: = external_mine_held or Input.is_action_pressed("mine")
	if not bool(runtime.swing_active):
		if not held:
			player.set_mining_visual(false)
			return
		runtime.target_index = _nearest_timed_surface_node(active_vein_id)
		if int(runtime.target_index) < 0:
			player.set_mining_visual(false)
			timed_surface_veins[active_vein_id] = runtime
			return
		runtime.swing_active = true
		runtime.swing_elapsed = 0.0
		runtime.swing_hit = false
		runtime.swing_duration = float(_mountain_tool().get("cooldown", 0.72))
		var target: Dictionary = Array(runtime.nodes)[int(runtime.target_index)]
		player.set_facing((Vector2(target.position) - player.global_position).normalized())
	runtime.swing_elapsed = float(runtime.swing_elapsed) + delta
	var progress: = clampf(
		float(runtime.swing_elapsed) / maxf(0.001, float(runtime.swing_duration)),
		0.0,
		1.0
	)
	player.set_mining_visual(true, progress)
	if not bool(runtime.swing_hit) and progress >= _tool_strike_progress():
		runtime.swing_hit = true
		timed_surface_veins[active_vein_id] = runtime
		_mine_timed_surface_resource_once(active_vein_id)
		runtime = timed_surface_veins[active_vein_id]
	if float(runtime.swing_elapsed) >= float(runtime.swing_duration):
		var overflow: = maxf(0.0, float(runtime.swing_elapsed) - float(runtime.swing_duration))
		runtime.swing_active = false
		if held:
			runtime.target_index = _nearest_timed_surface_node(active_vein_id)
			if int(runtime.target_index) >= 0:
				runtime.swing_active = true
				runtime.swing_duration = float(_mountain_tool().get("cooldown", 0.72))
				runtime.swing_elapsed = fposmod(overflow, maxf(0.001, float(runtime.swing_duration)))
				runtime.swing_hit = false
				var next_target: Dictionary = Array(runtime.nodes)[int(runtime.target_index)]
				player.set_facing((Vector2(next_target.position) - player.global_position).normalized())
				player.set_mining_visual(true, float(runtime.swing_elapsed) / maxf(0.001, float(runtime.swing_duration)))
			else:
				player.set_mining_visual(false)
		else:
			player.set_mining_visual(false)
	timed_surface_veins[active_vein_id] = runtime


func _update_timed_surface_resource_passive(vein_id: String, delta: float, now_unix: int = -1) -> void :
	if delta <= 0.0 or not timed_surface_veins.has(vein_id):
		return
	_update_timed_surface_drops(vein_id, delta)
	_update_timed_surface_effects(vein_id, delta)
	var runtime: Dictionary = timed_surface_veins[vein_id]
	runtime.visual_time = float(runtime.visual_time) + delta
	timed_surface_veins[vein_id] = runtime
	_advance_timed_surface_resource(vein_id, delta)
	runtime = timed_surface_veins[vein_id]
	runtime.updated_unix = now_unix if now_unix >= 0 else int(Time.get_unix_time_from_system())
	timed_surface_veins[vein_id] = runtime
	mobile_passive_resource_updates += 1


func _advance_timed_surface_resource(vein_id: String, delta: float) -> void :
	if delta <= 0.0 or not timed_surface_veins.has(vein_id):
		return
	var config: = _timed_surface_config(vein_id)
	var runtime: Dictionary = timed_surface_veins[vein_id]
	if String(runtime.status) == "active":
		runtime.timer = maxf(0.0, float(runtime.timer) - delta)
		if float(runtime.timer) <= 0.0:
			runtime.status = "failed"
	var nodes: Array = runtime.nodes
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		if int(node.hp) > 0:
			continue
		node.respawn = maxf(0.0, float(node.respawn) - delta)
		if float(node.respawn) <= 0.0:
			node.hp = int(config.max_hp)
			node.shell = int(config.max_shell)
			node.respawn = 0.0
		nodes[index] = node
	runtime.nodes = nodes
	if _all_timed_surface_nodes_intact_runtime(runtime) and String(runtime.status) != "active":
		runtime.status = "idle"
		runtime.timer = 0.0
	timed_surface_veins[vein_id] = runtime


func _catch_up_timed_surface_resources() -> void :
	var now: = int(Time.get_unix_time_from_system())
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		if not timed_surface_veins.has(vein_id):
			continue
		var runtime: Dictionary = timed_surface_veins[vein_id]
		var updated_unix: = int(runtime.get("updated_unix", 0))
		if updated_unix > 0:
			_advance_timed_surface_resource(vein_id, float(maxi(0, now - updated_unix)))
		runtime = timed_surface_veins[vein_id]
		runtime.updated_unix = now
		timed_surface_veins[vein_id] = runtime


func _mine_timed_surface_resource_once(vein_id: String) -> void :
	if not timed_surface_veins.has(vein_id) or not _timed_surface_resource_unlocked(vein_id):
		return
	var config: = _timed_surface_config(vein_id)
	if active_context != String(config.context):
		return
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var target_index: = int(runtime.target_index)
	if target_index < 0 or target_index >= Array(runtime.nodes).size():
		target_index = _nearest_timed_surface_node(vein_id)
	if target_index < 0:
		return
	var nodes: Array = runtime.nodes
	var node: Dictionary = nodes[target_index]
	if int(node.hp) <= 0:
		return
	var tool: = _mountain_tool()
	var power: = maxi(1, int(tool.get("power", 1)))
	var shell_power: = maxf(0.01, float(tool.get("shell_power", 0.72)))
	var shell_before: = int(node.shell)
	var shell_cracked: = false
	if shell_before > 0:
		var shell_damage: = ceili(float(power) * shell_power)
		node.shell = maxi(0, shell_before - shell_damage)
		if int(node.shell) <= 0:
			shell_cracked = true
			var overflow: = maxi(0, shell_damage - shell_before)
			var carry_damage: = floori(float(overflow) / shell_power)
			if carry_damage > 0:
				node.hp = maxi(0, int(node.hp) - carry_damage)
	else:
		node.hp = maxi(0, int(node.hp) - power)
	runtime.hit_count = int(runtime.hit_count) + 1
	nodes[target_index] = node
	runtime.nodes = nodes
	runtime.target_index = target_index
	timed_surface_veins[vein_id] = runtime
	_spawn_timed_surface_effect(
		vein_id,
		"shell_break" if shell_cracked else "hit",
		Vector2(node.position)
	)
	_spawn_surface_material_spray(vein_id, Vector2(node.position), shell_cracked)
	AudioDirector.play_mining(String(config.resource), int(node.hp) <= 0, shell_before > 0)
	if int(node.hp) > 0:
		return
	node.respawn = float(config.respawn)
	nodes[target_index] = node
	runtime = timed_surface_veins[vein_id]
	runtime.nodes = nodes
	var yield_amount: = 1
	if randf() < clampf(float(tool.get("yield_bonus", 0.0)), 0.0, 0.92):
		yield_amount += 1
	yield_amount *= maxi(1, int(tool.get("yield_multiplier", 1)))
	for piece in range(yield_amount):
		_spawn_timed_surface_drop(
			vein_id,
			String(config.resource),
			1,
			int(runtime.hit_count) + piece,
			Vector2(node.position)
		)
	RunState.record_mined(String(config.resource), yield_amount)
	if String(runtime.status) == "idle":
		runtime.status = "active"
		runtime.timer = float(config.time_limit)
	timed_surface_veins[vein_id] = runtime
	_spawn_timed_surface_effect(vein_id, "node_break", Vector2(node.position))
	if String(runtime.status) == "active" and _all_timed_surface_nodes_broken_runtime(runtime):
		_complete_timed_surface_resource(vein_id)
	runtime = timed_surface_veins[vein_id]
	runtime.target_index = _nearest_timed_surface_node(vein_id)
	timed_surface_veins[vein_id] = runtime


func _complete_timed_surface_resource(vein_id: String) -> void :
	var config: = _timed_surface_config(vein_id)
	var runtime: Dictionary = timed_surface_veins[vein_id]
	if String(runtime.status) != "active":
		return
	runtime.status = "completed"
	runtime.timer = 0.0
	runtime.completions = int(runtime.completions) + 1
	runtime.last_completion_bonus = Dictionary(config.bonus).duplicate(true)
	timed_surface_veins[vein_id] = runtime
	var reward_index: = 0
	for kind_value in Dictionary(config.bonus):
		var kind: = String(kind_value)
		var amount: = int(Dictionary(config.bonus)[kind])
		for piece in range(amount):
			_spawn_timed_surface_drop(
				vein_id,
				kind,
				1,
				reward_index,
				Vector2(config.center)
			)
			reward_index += 1
		RunState.record_mined(kind, amount)
	_spawn_timed_surface_effect(vein_id, "completion", Vector2(config.center))
	AudioDirector.play_discovery()
	if vein_id == EMBER_FAULT_ID:
		for index in range(3):
			_spawn_timed_surface_effect(
				vein_id,
				"cinder_release",
				Vector2(Array(config.positions)[index])
			)
	else:
		for position_value in Array(config.positions):
			_spawn_timed_surface_effect(vein_id, "astral_charge", Vector2(position_value))


func _nearest_timed_surface_node(vein_id: String) -> int:
	if not timed_surface_veins.has(vein_id):
		return -1
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var nearest_index: = -1
	var nearest_distance: = INF
	var nodes: Array = runtime.nodes
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		if int(node.hp) <= 0:
			continue
		var distance: = player.global_position.distance_to(Vector2(node.position))
		if distance <= _effective_mining_range(TIMED_SURFACE_NODE_CONTEXT_RADIUS) and distance < nearest_distance:
			nearest_distance = distance
			nearest_index = index
	return nearest_index


func _is_near_timed_surface_resource(vein_id: String, world_position: Vector2) -> bool:
	var config: = _timed_surface_config(vein_id)
	for position_value in Array(config.positions):
		if world_position.distance_to(Vector2(position_value)) <= _effective_mining_range(TIMED_SURFACE_NODE_CONTEXT_RADIUS):
			return true
	return false


func _timed_surface_resource_unlocked(vein_id: String) -> bool:
	if vein_id == EMBER_FAULT_ID:
		return bool(RunState.emberdeep_unlocked)
	if vein_id == STARFALL_LATTICE_ID:
		return bool(RunState.fourth_unlocked)
	return false


func _all_timed_surface_nodes_broken_runtime(runtime: Dictionary) -> bool:
	var nodes: Array = runtime.nodes
	if nodes.is_empty():
		return false
	for node_value in nodes:
		if int(Dictionary(node_value).hp) > 0:
			return false
	return true


func _all_timed_surface_nodes_intact_runtime(runtime: Dictionary) -> bool:
	var nodes: Array = runtime.nodes
	if nodes.is_empty():
		return false
	for node_value in nodes:
		if int(Dictionary(node_value).hp) <= 0:
			return false
	return true


func _timed_surface_broken_count(runtime: Dictionary) -> int:
	var result: = 0
	for node_value in Array(runtime.nodes):
		if int(Dictionary(node_value).hp) <= 0:
			result += 1
	return result


func _timed_surface_damage_stage(node: Dictionary, config: Dictionary) -> String:
	if int(node.hp) <= 0:
		return "disintegrated"
	var shell: = int(node.shell)
	var shell_ratio: = clampf(float(shell) / maxf(1.0, float(config.max_shell)), 0.0, 1.0)
	if shell_ratio > 0.66:
		return "armored"
	if shell > 0:
		return "shell_strained"
	var hp_ratio: = clampf(float(node.hp) / maxf(1.0, float(config.max_hp)), 0.0, 1.0)
	if hp_ratio > 0.66:
		return "shell_fractured"
	if hp_ratio > 0.33:
		return "core_exposed"
	return "disintegrating"


func _timed_surface_authored_time_phase(vein_id: String, runtime: Dictionary, config: Dictionary) -> String:
	var status: = String(runtime.status)
	if status != "active":
		return status
	var remaining: = clampf(float(runtime.timer) / maxf(0.001, float(config.time_limit)), 0.0, 1.0)
	if vein_id == EMBER_FAULT_ID:
		if remaining > 0.66:
			return "pressure_gathering"
		if remaining > 0.33:
			return "pressure_venting"
		return "pressure_critical"
	if remaining > 0.66:
		return "lattice_awake"
	if remaining > 0.33:
		return "lattice_charged"
	return "lattice_collapsing"


func _update_timed_surface_visual(vein_id: String) -> void :
	if not timed_surface_veins.has(vein_id):
		return
	var config: = _timed_surface_config(vein_id)
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var status: = String(runtime.status)
	var visual_time: = float(runtime.visual_time)
	var pulse: = 0.5 + 0.5 * sin(visual_time * (5.6 if status == "active" else 2.2))
	var broken_count: = _timed_surface_broken_count(runtime)
	var charge: = float(broken_count) / 3.0
	var line: Line2D = runtime.line
	var line_glow: Line2D = runtime.line_glow
	var line_alpha: = 0.16 + pulse * 0.08
	if status == "active":
		line_alpha = 0.42 + pulse * 0.22 + charge * 0.16
	elif status == "completed":
		line_alpha = 0.54 + pulse * 0.3
	elif status == "failed":
		line_alpha = 0.055
	line.modulate = Color(1, 1, 1, line_alpha)
	line_glow.modulate = Color(1, 1, 1, line_alpha * 0.58)
	var desired_line_width: float
	var desired_glow_width: float
	if vein_id == EMBER_FAULT_ID:
		desired_line_width = 3.2 + charge * 2.2
		desired_glow_width = 11.0 + charge * 6.0
	else:
		desired_line_width = 2.5 + charge * 2.7
		desired_glow_width = 9.0 + charge * 8.0
	if not is_equal_approx(line.width, desired_line_width):
		line.width = desired_line_width
	if not is_equal_approx(line_glow.width, desired_glow_width):
		line_glow.width = desired_glow_width
	var remaining: = clampf(float(runtime.timer) / maxf(0.001, float(config.time_limit)), 0.0, 1.0) if status == "active" else 1.0
	var urgency: = 1.0 - remaining if status == "active" else 0.0
	var reaction_sprite: Sprite2D = runtime.reaction_sprite
	reaction_sprite.visible = status in ["active", "completed", "failed"]
	if reaction_sprite.visible:
		if status == "active":
			reaction_sprite.frame = mini(2, floori(urgency * 3.0))
			reaction_sprite.modulate = Color(config.color, 0.11 + urgency * 0.24 + pulse * 0.035)
			reaction_sprite.scale = Vector2.ONE * ((284.0 if vein_id == STARFALL_LATTICE_ID else 246.0) / 256.0) * (0.94 + urgency * 0.1 + pulse * 0.025)
			reaction_sprite.rotation = sin(visual_time * 2.1) * (0.025 if vein_id == STARFALL_LATTICE_ID else 0.008)
		elif status == "completed":
			reaction_sprite.frame = 3
			reaction_sprite.modulate = Color(config.color, 0.2 + pulse * 0.08)
		else:
			reaction_sprite.frame = 3
			reaction_sprite.modulate = Color(config.color, 0.075)
	var nodes: Array = runtime.nodes
	var sprites: Array = runtime.sprites
	var glows: Array = runtime.glows
	var damage_overlays: Array = runtime.damage_overlays
	var residue_sprites: Array = runtime.residue_sprites
	var base_scales: Array = runtime.base_scales
	for index in range(nodes.size()):
		var node: Dictionary = nodes[index]
		var sprite: Sprite2D = sprites[index]
		var glow: Sprite2D = glows[index]
		var damage_overlay: Sprite2D = damage_overlays[index]
		var residue: Sprite2D = residue_sprites[index]
		var intact: = int(node.hp) > 0
		var stage: = _timed_surface_damage_stage(node, config)
		sprite.visible = intact
		glow.visible = true
		var reaction_speed: = lerpf(4.8, 9.2, urgency) if status == "active" else 2.5
		var local_pulse: = 0.5 + 0.5 * sin(visual_time * reaction_speed + float(index) * 1.9)
		damage_overlay.visible = intact and stage != "armored"
		residue.visible = not intact
		if not intact:
			damage_overlay.visible = false
			residue.frame = 3
			residue.modulate = Color(config.color, 0.32 if status == "failed" else 0.5 + local_pulse * 0.16)
			residue.scale = Vector2.ONE * ((124.0 if vein_id == STARFALL_LATTICE_ID else 108.0) / 256.0) * (0.97 + local_pulse * 0.045)
			glow.modulate = Color(config.color, 0.07 if status == "failed" else 0.13 + pulse * 0.08 + urgency * 0.08)
			continue
		residue.visible = false
		var hp_ratio: = clampf(float(node.hp) / float(config.max_hp), 0.0, 1.0)
		var shell_ratio: = clampf(float(node.shell) / float(config.max_shell), 0.0, 1.0)
		var integrity_scale: = lerpf(0.94, 1.0, sqrt(hp_ratio))
		sprite.scale = Vector2(base_scales[index]) * integrity_scale * (1.0 + local_pulse * 0.025)
		if damage_overlay.visible:
			match stage:
				"shell_strained":
					damage_overlay.frame = 0
					damage_overlay.modulate = Color(config.color, 0.18 + local_pulse * 0.07)
				"shell_fractured":
					damage_overlay.frame = 1
					damage_overlay.modulate = Color(config.color, 0.27 + local_pulse * 0.1)
				"core_exposed":
					damage_overlay.frame = 2
					damage_overlay.modulate = Color(config.color, 0.3 + local_pulse * 0.13)
				_:
					damage_overlay.frame = 2
					damage_overlay.modulate = Color(config.color, 0.43 + local_pulse * 0.19)
			damage_overlay.scale = Vector2.ONE * ((116.0 if vein_id == STARFALL_LATTICE_ID else 104.0) / 256.0) * (0.96 + local_pulse * (0.05 if stage == "disintegrating" else 0.025))
		if vein_id == EMBER_FAULT_ID:
			sprite.modulate = Color(
				1.04 + urgency * 0.06,
				lerpf(0.78, 1.0, 1.0 - shell_ratio) - urgency * 0.05,
				lerpf(0.6, 0.88, 1.0 - shell_ratio) - urgency * 0.07,
				lerpf(0.86, 1.0, hp_ratio)
			)
			glow.modulate = Color(1.0, 0.34 + 0.24 * (1.0 - shell_ratio), 0.08, 0.24 + local_pulse * 0.2 + urgency * 0.13)
		else:
			sprite.modulate = Color(
				lerpf(0.8, 1.03, 1.0 - shell_ratio),
				lerpf(0.84, 1.02, 1.0 - shell_ratio),
				1.1,
				lerpf(0.86, 1.0, hp_ratio)
			)
			glow.modulate = Color(0.48, 0.58, 1.0, 0.2 + local_pulse * 0.2 + charge * 0.12 + urgency * 0.11)


func _spawn_timed_surface_drop(
	vein_id: String,
	kind: String,
	amount: int,
	spread_index: int,
	origin: Vector2
) -> void :
	var config: = _timed_surface_config(vein_id)
	var drop_textures: Dictionary = config.drop_textures
	if not drop_textures.has(kind):
		return
	var texture: Texture2D = drop_textures[kind]
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = DropVisuals.sprite_offset(kind, texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 10
	sprite.scale = DropVisuals.sprite_scale(kind, texture)
	var angle: float
	var radius: float
	if vein_id == EMBER_FAULT_ID:
		angle = -2.72 + float((spread_index * 5) % 11) * 0.49
		radius = 52.0 + float((spread_index * 17) % 37)
	else:
		angle = - PI * 0.85 + float((spread_index * 7) % 13) * (TAU / 13.0)
		radius = 62.0 + float((spread_index * 23) % 43)
	var landing_offset: = Vector2(cos(angle) * radius, sin(angle) * radius * 0.58)
	var launch_position: = origin + Vector2(float((spread_index * 19) % 27) - 13.0, -10.0)
	sprite.position = launch_position
	add_child(sprite)
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var drops: Array = runtime.drops
	drops.append({
		"kind": kind,
		"amount": amount,
		"sprite": sprite,
		"base_scale": sprite.scale,
		"launch_position": launch_position,
		"landing_position": origin + landing_offset,
		"age": 0.0,
		"budget_serial": _next_surface_drop_budget_serial(),
		"collecting": false,
		"collect_elapsed": 0.0,
		"collect_origin": Vector2.ZERO,
		"settled": false,
	})
	runtime.drops = drops
	timed_surface_veins[vein_id] = runtime
	_enforce_surface_loose_drop_budget()


func _update_timed_surface_drops(vein_id: String, delta: float) -> void :
	if not timed_surface_veins.has(vein_id):
		return
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var drops: Array = runtime.drops
	for index in range(drops.size() - 1, -1, -1):
		var drop: Dictionary = drops[index]
		var sprite: Sprite2D = drop.sprite
		if not is_instance_valid(sprite):
			drops.remove_at(index)
			continue
		var age: = float(drop.age) + delta
		if age >= LOOSE_RESOURCE_LIFETIME:
			RunState.add_resource(String(drop.kind), int(drop.amount), false)
			sprite.queue_free()
			drops.remove_at(index)
			continue
		if bool(drop.collecting):
			var collect_elapsed: = float(drop.collect_elapsed) + delta
			var collect_progress: = clampf(collect_elapsed / ORE_DROP_COLLECT_DURATION, 0.0, 1.0)
			var eased: = collect_progress * collect_progress * (3.0 - 2.0 * collect_progress)
			sprite.global_position = Vector2(drop.collect_origin).lerp(player.global_position + Vector2(0, -28), eased)
			sprite.global_position.y -= sin(collect_progress * PI) * 16.0
			sprite.scale = Vector2(drop.base_scale) * lerpf(1.0, 0.22, eased)
			sprite.modulate.a = 1.0 - clampf((collect_progress - 0.68) / 0.32, 0.0, 1.0)
			drop.collect_elapsed = collect_elapsed
			drops[index] = drop
			if collect_progress >= 1.0:
				RunState.add_resource(String(drop.kind), int(drop.amount), false)
				AudioDirector.play_pickup(String(drop.kind), int(drop.amount))
				sprite.queue_free()
				drops.remove_at(index)
			continue
		if age < ORE_DROP_FLIGHT_DURATION:
			var flight_progress: = clampf(age / ORE_DROP_FLIGHT_DURATION, 0.0, 1.0)
			var flight_eased: = 1.0 - pow(1.0 - flight_progress, 2.0)
			sprite.position = Vector2(drop.launch_position).lerp(Vector2(drop.landing_position), flight_eased)
			var flight_height: = 86.0 if vein_id == EMBER_FAULT_ID else 112.0
			sprite.position.y -= sin(flight_progress * PI) * flight_height
			sprite.rotation = flight_progress * TAU * (1.7 if index % 2 == 0 else -1.7)
			sprite.scale = Vector2(drop.base_scale) * (1.0 + sin(flight_progress * PI) * 0.24)
		elif not bool(drop.get("settled", false)):
			sprite.position = Vector2(drop.landing_position)
			sprite.rotation = sin(float(index) * 2.1) * 0.16
			sprite.scale = Vector2(drop.base_scale)
			drop.settled = true
		sprite.modulate.a = _loose_resource_alpha(age)
		drop.age = age
		drops[index] = drop
		if age >= ORE_DROP_FLIGHT_DURATION and sprite.global_position.distance_to(player.global_position) <= _ore_drop_pickup_radius():
			drop.collecting = true
			drop.collect_elapsed = 0.0
			drop.collect_origin = sprite.global_position
			drops[index] = drop
	runtime.drops = drops
	timed_surface_veins[vein_id] = runtime


func _spawn_timed_surface_effect(vein_id: String, kind: String, origin: Vector2) -> void :
	var config: = _timed_surface_config(vein_id)
	var completion: = kind == "completion"
	var sprite: = Sprite2D.new()
	var effect_texture: Texture2D = config.completion_texture if completion else config.impact_texture
	sprite.texture = effect_texture
	sprite.hframes = 4
	sprite.frame = 0
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 9
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var jitter: = Vector2(
		float((int(runtime.hit_count) * 29) % 25) - 12.0,
		float((int(runtime.hit_count) * 17) % 17) - 8.0
	)
	sprite.position = origin + (Vector2.ZERO if completion else jitter)
	var target_size: = 98.0
	var life: = 0.32
	match kind:
		"shell_break":
			target_size = 168.0
			life = 0.48
		"node_break":
			target_size = 132.0 if vein_id == EMBER_FAULT_ID else 174.0
			life = 0.46
		"completion":
			target_size = 372.0 if vein_id == EMBER_FAULT_ID else 438.0
			life = 0.82
		"cinder_release":
			target_size = 124.0
			life = 0.54
		"astral_charge":
			target_size = 152.0
			life = 0.62
	sprite.scale = Vector2.ONE * (target_size / 256.0)
	add_child(sprite)
	var effects: Array = runtime.effects
	effects.append({
		"sprite": sprite,
		"age": 0.0,
		"life": life,
		"base_scale": sprite.scale,
		"kind": kind,
	})
	runtime.effects = effects
	timed_surface_veins[vein_id] = runtime


func _update_timed_surface_effects(vein_id: String, delta: float) -> void :
	if not timed_surface_veins.has(vein_id):
		return
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var effects: Array = runtime.effects
	for index in range(effects.size() - 1, -1, -1):
		var effect: Dictionary = effects[index]
		var sprite: Sprite2D = effect.sprite
		if not is_instance_valid(sprite):
			effects.remove_at(index)
			continue
		var age: = float(effect.age) + delta
		var progress: = clampf(age / float(effect.life), 0.0, 1.0)
		sprite.frame = mini(3, floori(progress * 4.0))
		var kind: = String(effect.kind)
		var expansion: = 0.1
		if kind == "completion":
			expansion = 0.34 if vein_id == EMBER_FAULT_ID else 0.46
		elif kind in ["shell_break", "astral_charge"]:
			expansion = 0.22
		sprite.scale = Vector2(effect.base_scale) * lerpf(0.88, 1.0 + expansion, progress)
		if vein_id == STARFALL_LATTICE_ID and kind in ["completion", "astral_charge"]:
			sprite.rotation = sin(progress * PI) * 0.08
		sprite.modulate.a = 1.0 - clampf((progress - 0.64) / 0.36, 0.0, 1.0)
		effect.age = age
		effects[index] = effect
		if progress >= 1.0:
			sprite.queue_free()
			effects.remove_at(index)
	runtime.effects = effects
	timed_surface_veins[vein_id] = runtime


func _spawn_surface_material_spray(resource_id: String, origin: Vector2, heavy: bool = false) -> void :
	var texture: Texture2D = MOONGLASS_DROP
	var tint: = Color(0.64, 0.96, 1.08, 1.0)
	var gravity: = 250.0
	if resource_id == MOON_MOUNTAIN_ID:
		texture = MOONGLASS_DROP
		tint = Color(0.7, 0.98, 1.12, 1.0)
		gravity = 265.0
	elif resource_id in [EMBER_FAULT_ID, EMBER_MOUNTAIN_ID]:
		texture = SUNSLAG_DROP
		tint = Color(1.18, 0.62, 0.22, 1.0)
		gravity = 315.0
	elif resource_id in [STARFALL_LATTICE_ID, STAR_MOUNTAIN_ID]:
		texture = ASTRALITE_DROP
		tint = Color(0.86, 0.76, 1.18, 1.0)
		gravity = 190.0
	var piece_count: = 8 if heavy else 5
	for piece in range(piece_count):
		while surface_material_sprays.size() >= 30:
			var oldest: Dictionary = surface_material_sprays.pop_front()
			var oldest_sprite: Sprite2D = oldest.get("sprite")
			if is_instance_valid(oldest_sprite):
				oldest_sprite.queue_free()
		var sprite: = Sprite2D.new()
		sprite.texture = texture
		sprite.centered = true
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.z_index = 10
		sprite.position = origin + Vector2((piece - piece_count / 2.0) * 3.0, -4.0)
		var target_size: = 10.0 + float((piece * 7 + surface_material_sprays.size()) % 7)
		sprite.scale = Vector2.ONE * (target_size / maxf(1.0, float(texture.get_width())))
		sprite.modulate = tint
		add_child(sprite)
		var spread: = (float(piece) / maxf(1.0, float(piece_count - 1)) - 0.5) * 2.0
		var lift: = 105.0 + float((piece * 23) % 58)
		if resource_id in [EMBER_FAULT_ID, EMBER_MOUNTAIN_ID]:
			lift += 28.0
		elif resource_id in [STARFALL_LATTICE_ID, STAR_MOUNTAIN_ID]:
			lift += 12.0
		surface_material_sprays.append({
			"sprite": sprite,
			"age": 0.0,
			"life": 0.58 if heavy else 0.46,
			"velocity": Vector2(spread * (92.0 if heavy else 68.0), - lift),
			"gravity": gravity,
			"spin": spread * 8.0 + (2.4 if piece % 2 == 0 else -2.4),
			"base_scale": sprite.scale,
		})


func _update_surface_material_sprays(delta: float) -> void :
	for index in range(surface_material_sprays.size() - 1, -1, -1):
		var spray: Dictionary = surface_material_sprays[index]
		var sprite: Sprite2D = spray.get("sprite")
		if not is_instance_valid(sprite):
			surface_material_sprays.remove_at(index)
			continue
		var age: = float(spray.age) + delta
		var life: = maxf(0.01, float(spray.life))
		var progress: = clampf(age / life, 0.0, 1.0)
		var velocity: = Vector2(spray.velocity)
		velocity.y += float(spray.gravity) * delta
		sprite.position += velocity * delta
		sprite.rotation += float(spray.spin) * delta
		sprite.scale = Vector2(spray.base_scale) * lerpf(1.0, 0.35, progress)
		sprite.modulate.a = 1.0 - clampf((progress - 0.58) / 0.42, 0.0, 1.0)
		spray.age = age
		spray.velocity = velocity
		surface_material_sprays[index] = spray
		if progress >= 1.0:
			sprite.queue_free()
			surface_material_sprays.remove_at(index)


func _timed_surface_glow_texture(vein_id: String) -> GradientTexture2D:
	if timed_surface_glow_textures.has(vein_id):
		return timed_surface_glow_textures[vein_id]
	var config: = _timed_surface_config(vein_id)
	var base: = Color(config.color)
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(base.r, base.g, base.b, 0.82),
		Color(base.r, base.g, base.b, 0.42),
		Color(base.r, base.g, base.b, 0.14),
		Color(base.r, base.g, base.b, 0.0),
	])
	var texture: = GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	timed_surface_glow_textures[vein_id] = texture
	return texture


func _reset_timed_surface_resources() -> void :
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		if not timed_surface_veins.has(vein_id):
			continue
		var config: = _timed_surface_config(vein_id)
		var runtime: Dictionary = timed_surface_veins[vein_id]
		for drop_value in Array(runtime.drops):
			var drop: Dictionary = drop_value
			var drop_sprite: Sprite2D = drop.get("sprite")
			if is_instance_valid(drop_sprite):
				drop_sprite.queue_free()
		for effect_value in Array(runtime.effects):
			var effect: Dictionary = effect_value
			var effect_sprite: Sprite2D = effect.get("sprite")
			if is_instance_valid(effect_sprite):
				effect_sprite.queue_free()
		var nodes: Array = runtime.nodes
		for index in range(nodes.size()):
			nodes[index] = {
				"position": Vector2(Array(config.positions)[index]),
				"hp": int(config.max_hp),
				"shell": int(config.max_shell),
				"respawn": 0.0,
			}
		runtime.nodes = nodes
		runtime.status = "idle"
		runtime.timer = 0.0
		runtime.completions = 0
		runtime.updated_unix = int(Time.get_unix_time_from_system())
		runtime.swing_active = false
		runtime.swing_elapsed = 0.0
		runtime.swing_hit = false
		runtime.target_index = -1
		runtime.hit_count = 0
		runtime.visual_time = 0.0
		runtime.visual_elapsed = SURFACE_DYNAMIC_VISUAL_TICK
		runtime.drops = []
		runtime.effects = []
		runtime.last_completion_bonus = {}
		timed_surface_veins[vein_id] = runtime
		_update_timed_surface_visual(vein_id)


func _mine_ore_mountain_once() -> void :
	if active_context != "ore_mountain":
		return
	var active_tool: = _mountain_tool()
	var power: = int(active_tool.get("power", 1))
	var yield_multiplier: = maxi(1, int(active_tool.get("yield_multiplier", 1)))
	var removed_mass: = mini(power, ore_mountain_hp)
	ore_mountain_hp -= removed_mass
	ore_mountain_hit_flash = 0.14
	ore_mountain_hit_count += 1
	_spawn_mountain_impact(false)
	var visual_progress: = 0.38
	if ore_mountain_swing_active:
		visual_progress = clampf(ore_mountain_swing_elapsed / maxf(0.001, ore_mountain_swing_duration), 0.0, 1.0)
	player.set_mining_visual(true, visual_progress, 1.0)
	if removed_mass > 0:
		AudioDirector.play_mining("copper", ore_mountain_hp <= 0, false)
	else:
		AudioDirector.play_blocked()
	if removed_mass > 0:
		ore_mountain_copper_yield_buffer += float(removed_mass) * MOSS_ORE_MOUNTAIN_FULL_COPPER_YIELD / float(MOSS_ORE_MOUNTAIN_MAX_HP)
		var copper_count: = floori(ore_mountain_copper_yield_buffer + 1e-06)
		ore_mountain_copper_yield_buffer -= float(copper_count)
		for _piece in range(copper_count * yield_multiplier):
			_spawn_ore_drop("copper", 1)
	if removed_mass > 0 and ore_mountain_hp <= 0:
		_start_mountain_collapse()
		if ore_mountain_gold_ready:
			_spawn_ore_drop("gold", yield_multiplier)
			ore_mountain_gold_ready = false
		message_changed.emit("Copper Ridge cracked · ore scattered across the path")


func _mine_surface_resource_mountain_once(mountain_id: String) -> void :
	if (
		active_context != mountain_id
		or not surface_resource_mountains.has(mountain_id)
		or not _surface_resource_mountain_unlocked(mountain_id)
	):
		return
	var entry: Dictionary = surface_resource_mountains[mountain_id]
	var config: Dictionary = SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]
	var active_tool: = _mountain_tool()
	var power: = maxi(1, int(active_tool.get("power", 1)))
	var yield_multiplier: = maxi(1, int(active_tool.get("yield_multiplier", 1)))
	var removed_mass: = mini(power, int(entry.hp))
	entry.hp = int(entry.hp) - removed_mass
	entry.hit_flash = 0.14
	entry.hit_elapsed = SURFACE_RESOURCE_MOUNTAIN_HIT_DURATION
	entry.hit_count = int(entry.hit_count) + 1
	surface_resource_mountains[mountain_id] = entry
	_spawn_surface_resource_mountain_impact(mountain_id, false)
	_spawn_surface_material_spray(mountain_id, Vector2(entry.swing_target))
	var visual_progress: = 0.38
	if bool(entry.swing_active):
		visual_progress = clampf(
			float(entry.swing_elapsed) / maxf(0.001, float(entry.swing_duration)),
			0.0, 1.0
		)
	player.set_mining_visual(true, visual_progress, 1.0)
	if removed_mass <= 0:
		AudioDirector.play_blocked()
		_update_surface_resource_mountain_visual(mountain_id)
		return
	AudioDirector.play_mining(String(config.primary), int(entry.hp) <= 0, false)
	entry.yield_buffer = float(entry.yield_buffer) + (
		float(removed_mass) * SURFACE_RESOURCE_MOUNTAIN_FULL_YIELD / float(SURFACE_RESOURCE_MOUNTAIN_MAX_HP)
	)
	var primary_count: = floori(float(entry.yield_buffer) + 1e-06)
	entry.yield_buffer = float(entry.yield_buffer) - float(primary_count)
	surface_resource_mountains[mountain_id] = entry
	for _piece in range(primary_count * yield_multiplier):
		_spawn_surface_resource_mountain_drop(mountain_id, String(config.primary), 1)
	entry = surface_resource_mountains[mountain_id]
	if int(entry.hp) <= 0:
		entry.collapse_elapsed = SURFACE_RESOURCE_MOUNTAIN_COLLAPSE_DURATION
		surface_resource_mountains[mountain_id] = entry
		_spawn_surface_material_spray(mountain_id, Vector2(entry.swing_target), true)
		_spawn_surface_resource_mountain_impact(mountain_id, true, Vector2(-64, -22))
		_spawn_surface_resource_mountain_impact(mountain_id, true, Vector2(62, -34))
		_spawn_surface_resource_mountain_impact(mountain_id, true, Vector2(-12, 34))
		if bool(entry.rare_ready):
			_spawn_surface_resource_mountain_drop(mountain_id, String(config.rare), yield_multiplier)
			entry = surface_resource_mountains[mountain_id]
			entry.rare_ready = false
			surface_resource_mountains[mountain_id] = entry
		message_changed.emit("%s cracked · ore scattered across the path" % String(config.label))
	_update_surface_resource_mountain_visual(mountain_id)


func _spawn_surface_resource_mountain_drop(mountain_id: String, kind: String, amount: int) -> void :
	if not surface_resource_mountains.has(mountain_id):
		return
	var config: Dictionary = SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]
	var textures: Dictionary = config.drop_textures
	if not textures.has(kind):
		return
	var texture: Texture2D = textures[kind]
	var entry: Dictionary = surface_resource_mountains[mountain_id]
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = DropVisuals.sprite_offset(kind, texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 9
	sprite.scale = DropVisuals.sprite_scale(kind, texture)
	var seed: = int(entry.hit_count) + surface_resource_mountain_drops.size() * 3
	var contact: = (
		Vector2(entry.swing_target)
		if bool(entry.swing_active)
		else _surface_resource_mountain_hit_point(mountain_id, player.global_position)
	)
	var collision: Dictionary = SURFACE_RESOURCE_MOUNTAIN_COLLISIONS[mountain_id]
	var outward: = (contact - Vector2(collision.center)).normalized()
	if outward.is_zero_approx():
		outward = Vector2.DOWN
	var tangent: = outward.orthogonal()
	var lateral: = float((seed * 37) % 121) - 60.0
	var landing_position: = contact + outward * (58.0 + float(seed % 4) * 13.0) + tangent * lateral
	for _step in range(8):
		if not _surface_collides(landing_position):
			break
		landing_position += outward * 18.0
	landing_position = landing_position.clamp(Vector2(42, 52), _world_size() - Vector2(42, 46))
	sprite.position = contact + Vector2(float((seed * 23) % 31) - 15.0, -8.0)
	add_child(sprite)
	surface_resource_mountain_drops.append({
		"mountain_id": mountain_id,
		"kind": kind,
		"amount": amount,
		"sprite": sprite,
		"base_scale": sprite.scale,
		"launch_position": sprite.position,
		"landing_position": landing_position,
		"age": 0.0,
		"budget_serial": _next_surface_drop_budget_serial(),
		"collecting": false,
		"collect_elapsed": 0.0,
		"collect_origin": Vector2.ZERO,
		"seed": seed,
		"settled": false,
	})
	_enforce_surface_loose_drop_budget()


func _update_surface_resource_mountain_drops(delta: float) -> void :
	for index in range(surface_resource_mountain_drops.size() - 1, -1, -1):
		var drop: Dictionary = surface_resource_mountain_drops[index]
		var sprite: Sprite2D = drop.sprite
		if not is_instance_valid(sprite):
			surface_resource_mountain_drops.remove_at(index)
			continue
		var age: = float(drop.age) + delta
		if age >= LOOSE_RESOURCE_LIFETIME:
			RunState.add_resource(String(drop.kind), int(drop.amount), true)
			sprite.queue_free()
			surface_resource_mountain_drops.remove_at(index)
			continue
		if bool(drop.collecting):
			var collect_elapsed: = float(drop.collect_elapsed) + delta
			var collect_progress: = clampf(collect_elapsed / ORE_DROP_COLLECT_DURATION, 0.0, 1.0)
			var collect_eased: = collect_progress * collect_progress * (3.0 - 2.0 * collect_progress)
			sprite.global_position = Vector2(drop.collect_origin).lerp(player.global_position + Vector2(0, -28), collect_eased)
			sprite.global_position.y -= sin(collect_progress * PI) * 13.0
			sprite.scale = Vector2(drop.base_scale) * lerpf(1.0, 0.28, collect_eased)
			sprite.modulate.a = 1.0 - clampf((collect_progress - 0.68) / 0.32, 0.0, 1.0)
			drop.collect_elapsed = collect_elapsed
			surface_resource_mountain_drops[index] = drop
			if collect_progress >= 1.0:
				RunState.add_resource(String(drop.kind), int(drop.amount), true)
				AudioDirector.play_pickup(String(drop.kind), int(drop.amount))
				sprite.queue_free()
				surface_resource_mountain_drops.remove_at(index)
			continue
		if age < ORE_DROP_FLIGHT_DURATION:
			var flight_progress: = clampf(age / ORE_DROP_FLIGHT_DURATION, 0.0, 1.0)
			var eased: = 1.0 - pow(1.0 - flight_progress, 2.0)
			sprite.position = Vector2(drop.launch_position).lerp(Vector2(drop.landing_position), eased)
			sprite.position.y -= sin(flight_progress * PI) * 82.0
			sprite.rotation = flight_progress * TAU * (1.25 if int(drop.seed) % 2 == 0 else -1.25)
			sprite.scale = Vector2(drop.base_scale) * (1.0 + sin(flight_progress * PI) * 0.18)
		elif not bool(drop.settled):
			sprite.position = Vector2(drop.landing_position)
			sprite.rotation = sin(float(drop.seed) * 2.1) * 0.14
			sprite.scale = Vector2(drop.base_scale)
			drop.settled = true
		sprite.modulate.a = _loose_resource_alpha(age)
		drop.age = age
		surface_resource_mountain_drops[index] = drop
		if age >= ORE_DROP_FLIGHT_DURATION and sprite.global_position.distance_to(player.global_position) <= _ore_drop_pickup_radius():
			drop.collecting = true
			drop.collect_elapsed = 0.0
			drop.collect_origin = sprite.global_position
			surface_resource_mountain_drops[index] = drop


func _spawn_surface_resource_mountain_impact(
	mountain_id: String, broken: bool, extra_offset: Vector2 = Vector2.ZERO
) -> void :
	if not surface_resource_mountains.has(mountain_id):
		return
	var entry: Dictionary = surface_resource_mountains[mountain_id]
	var config: Dictionary = SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]
	var sprite: = Sprite2D.new()
	sprite.texture = config.response if broken else config.impact
	sprite.hframes = 4
	sprite.frame = 0
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 11
	var contact: = (
		Vector2(entry.swing_target)
		if bool(entry.swing_active)
		else _surface_resource_mountain_hit_point(mountain_id, player.global_position)
	)
	var jitter: = Vector2(float((int(entry.hit_count) * 31) % 25) - 12.0, float((int(entry.hit_count) * 19) % 17) - 8.0)
	sprite.position = contact + jitter + extra_offset
	var target_size: = 132.0 if broken else 82.0
	sprite.scale = Vector2.ONE * (target_size / 256.0)
	add_child(sprite)
	surface_resource_mountain_impacts.append({
		"mountain_id": mountain_id,
		"sprite": sprite,
		"age": 0.0,
		"life": 0.66 if broken else 0.36,
		"base_scale": sprite.scale,
	})


func _update_surface_resource_mountain_impacts(delta: float) -> void :
	for index in range(surface_resource_mountain_impacts.size() - 1, -1, -1):
		var impact: Dictionary = surface_resource_mountain_impacts[index]
		var sprite: Sprite2D = impact.sprite
		if not is_instance_valid(sprite):
			surface_resource_mountain_impacts.remove_at(index)
			continue
		var age: = float(impact.age) + delta
		var progress: = clampf(age / float(impact.life), 0.0, 1.0)
		sprite.frame = mini(3, floori(progress * 4.0))
		sprite.scale = Vector2(impact.base_scale) * lerpf(0.86, 1.18, progress)
		sprite.modulate.a = 1.0 - clampf((progress - 0.66) / 0.34, 0.0, 1.0)
		impact.age = age
		surface_resource_mountain_impacts[index] = impact
		if progress >= 1.0:
			sprite.queue_free()
			surface_resource_mountain_impacts.remove_at(index)


func _spawn_ore_drop(kind: String, amount: int) -> void :
	var texture: Texture2D = GOLD_DROP if kind == "gold" else COPPER_DROP
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = DropVisuals.sprite_offset(kind, texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 9
	sprite.scale = DropVisuals.sprite_scale(kind, texture)
	var spread_index: = ore_mountain_hit_count + ore_drops.size() * 3
	var landing_offset: Vector2 = ORE_DROP_LANDING_OFFSETS[spread_index % ORE_DROP_LANDING_OFFSETS.size()]
	landing_offset += Vector2(float((spread_index * 29) % 25) - 12.0, float((spread_index * 17) % 17) - 8.0)
	var launch_position: = ore_mountain_swing_target if ore_mountain_swing_active else _ore_mountain_hit_point(player.global_position)
	sprite.position = launch_position + Vector2(float((spread_index * 23) % 31) - 15.0, -8.0)
	add_child(sprite)
	ore_drops.append({
		"kind": kind,
		"amount": amount,
		"sprite": sprite,
		"base_scale": sprite.scale,
		"launch_position": sprite.position,
		"landing_position": MOSS_ORE_MOUNTAIN_FOCUS + landing_offset,
		"age": 0.0,
		"budget_serial": _next_surface_drop_budget_serial(),
		"collecting": false,
		"collect_elapsed": 0.0,
		"collect_origin": Vector2.ZERO,
		"settled": false,
	})
	_enforce_surface_loose_drop_budget()


func _sync_pending_chest_loot_drops() -> void :
	var signature_rows: Array[String] = []
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: = String(chest.id)
		var pending: = RunState.pending_chest_reward_loot(chest_id)
		var reward_ids: Array = pending.keys()
		reward_ids.sort()
		for reward_id_value in reward_ids:
			var reward_id: = String(reward_id_value)
			var amount: = int(pending.get(reward_id, 0))
			if amount > 0:
				signature_rows.append("%s:%s:%d" % [chest_id, reward_id, amount])
	var signature: = "|".join(signature_rows)
	if signature == chest_loot_signature:
		return
	chest_loot_signature = signature
	for index in range(chest_loot_drops.size() - 1, -1, -1):
		var drop: Dictionary = chest_loot_drops[index]
		var pending: = RunState.pending_chest_reward_loot(String(drop.chest_id))
		if int(pending.get(String(drop.reward_id), 0)) > 0:
			continue
		var sprite: Sprite2D = drop.sprite
		if is_instance_valid(sprite):
			sprite.queue_free()
		chest_loot_drops.remove_at(index)
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: = String(chest.id)
		var pending: = RunState.pending_chest_reward_loot(chest_id)
		for reward_id_value in pending:
			var reward_id: = String(reward_id_value)
			var pending_amount: = int(pending.get(reward_id, 0))
			var visible_amount: = _visible_chest_drop_amount(chest_id, reward_id)
			if pending_amount > visible_amount:
				_spawn_chest_loot_reward(chest, reward_id, pending_amount - visible_amount)


func _visible_chest_drop_amount(chest_id: String, reward_id: String) -> int:
	var total: = 0
	for drop in chest_loot_drops:
		if String(drop.chest_id) == chest_id and String(drop.reward_id) == reward_id:
			total += int(drop.amount)
	return total


func _spawn_chest_loot_reward(chest: Dictionary, reward_id: String, total_amount: int) -> void :
	if total_amount <= 0:
		return



	var piece_count: = mini(6, maxi(3, ceili(float(total_amount) / 100.0))) if reward_id == "coin" else total_amount
	var remaining: = total_amount
	for piece_index in range(piece_count):
		var piece_amount: = ceili(float(remaining) / float(piece_count - piece_index)) if reward_id == "coin" else 1
		remaining -= piece_amount
		_spawn_chest_loot_piece(chest, reward_id, piece_amount, piece_index, piece_count)


func _spawn_chest_loot_piece(
	chest: Dictionary,
	reward_id: String,
	amount: int,
	piece_index: int,
	piece_count: int
) -> void :
	var texture: Texture2D = GOLD_DROP
	var sprite: = Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = DropVisuals.sprite_offset(reward_id, texture)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 9
	sprite.scale = DropVisuals.sprite_scale(reward_id, texture)
	var chest_position: = Vector2(float(chest.x), float(chest.y))
	var seed: = int(chest.get("tier", 0)) * 41 + piece_index * 17 + piece_count * 7 + int(chest_position.x)
	var angle: = fmod(float(seed) * 2.399963, TAU)
	var radius: = 48.0 + float(seed % 4) * 7.0
	var landing_position: = (
		chest_position + Vector2(cos(angle) * radius, 26.0 + sin(angle) * radius * 0.58)
	).clamp(Vector2(52, 70), _world_size() - Vector2(52, 58))
	sprite.position = chest_position + Vector2(0, -8)
	add_child(sprite)
	chest_loot_drops.append({
		"chest_id": String(chest.id),
		"reward_id": reward_id,
		"amount": amount,
		"sprite": sprite,
		"base_scale": sprite.scale,
		"launch_position": sprite.position,
		"landing_position": landing_position,
		"age": 0.0,
		"budget_serial": _next_surface_drop_budget_serial(),
		"collecting": false,
		"collect_elapsed": 0.0,
		"collect_origin": Vector2.ZERO,
		"seed": seed,
		"settled": false,
	})
	_enforce_surface_loose_drop_budget()


func _update_chest_loot_drops(delta: float) -> void :
	for index in range(chest_loot_drops.size() - 1, -1, -1):
		var drop: Dictionary = chest_loot_drops[index]
		var sprite: Sprite2D = drop.sprite
		if not is_instance_valid(sprite):
			chest_loot_drops.remove_at(index)
			continue
		var age: = float(drop.age) + delta
		if age >= LOOSE_RESOURCE_LIFETIME:
			var expired_chest_id: = String(drop.chest_id)
			var expired_reward_id: = String(drop.reward_id)
			var expired_amount: = int(drop.amount)
			sprite.queue_free()
			chest_loot_drops.remove_at(index)
			var auto_collected: = RunState.collect_chest_loot(expired_chest_id, expired_reward_id, expired_amount)
			if auto_collected > 0:
				AudioDirector.play_pickup("gold" if expired_reward_id == "coin" else expired_reward_id, auto_collected)
			continue
		if bool(drop.collecting):
			var collect_elapsed: = float(drop.collect_elapsed) + delta
			var collect_progress: = clampf(collect_elapsed / ORE_DROP_COLLECT_DURATION, 0.0, 1.0)
			var collect_eased: = collect_progress * collect_progress * (3.0 - 2.0 * collect_progress)
			sprite.global_position = Vector2(drop.collect_origin).lerp(player.global_position + Vector2(0, -28), collect_eased)
			sprite.global_position.y -= sin(collect_progress * PI) * 13.0
			sprite.scale = Vector2(drop.base_scale) * lerpf(1.0, 0.28, collect_eased)
			sprite.modulate.a = 1.0 - clampf((collect_progress - 0.68) / 0.32, 0.0, 1.0)
			drop.collect_elapsed = collect_elapsed
			chest_loot_drops[index] = drop
			if collect_progress >= 1.0:
				var chest_id: = String(drop.chest_id)
				var reward_id: = String(drop.reward_id)
				var amount: = int(drop.amount)
				sprite.queue_free()
				chest_loot_drops.remove_at(index)
				var collected: = RunState.collect_chest_loot(chest_id, reward_id, amount)
				if collected > 0:
					AudioDirector.play_pickup("gold" if reward_id == "coin" else reward_id, collected)
					message_changed.emit("%d GOLD COLLECTED" % collected if reward_id == "coin" else "%s COLLECTED" % reward_id.to_upper())
			continue
		if age < ORE_DROP_FLIGHT_DURATION:
			var flight_progress: = clampf(age / ORE_DROP_FLIGHT_DURATION, 0.0, 1.0)
			var eased: = 1.0 - pow(1.0 - flight_progress, 2.0)
			sprite.position = Vector2(drop.launch_position).lerp(Vector2(drop.landing_position), eased)
			sprite.position.y -= sin(flight_progress * PI) * 76.0
			sprite.rotation = flight_progress * TAU * (1.25 if int(drop.seed) % 2 == 0 else -1.25)
			sprite.scale = Vector2(drop.base_scale) * (1.0 + sin(flight_progress * PI) * 0.18)
		elif not bool(drop.get("settled", false)):
			sprite.position = Vector2(drop.landing_position)
			sprite.rotation = sin(float(drop.seed) * 2.1) * 0.14
			sprite.scale = Vector2(drop.base_scale)
			drop.settled = true
		sprite.modulate.a = _loose_resource_alpha(age)
		drop.age = age
		chest_loot_drops[index] = drop
		if age >= ORE_DROP_FLIGHT_DURATION and sprite.global_position.distance_to(player.global_position) <= CHEST_DROP_PICKUP_RADIUS:
			drop.collecting = true
			drop.collect_elapsed = 0.0
			drop.collect_origin = sprite.global_position
			chest_loot_drops[index] = drop


func _gold_glow_texture() -> GradientTexture2D:
	if is_instance_valid(gold_glow_texture):
		return gold_glow_texture
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.82, 0.26, 0.72),
		Color(1.0, 0.56, 0.08, 0.24),
		Color(1.0, 0.45, 0.0, 0.0),
	])
	gold_glow_texture = GradientTexture2D.new()
	gold_glow_texture.gradient = gradient
	gold_glow_texture.width = 64
	gold_glow_texture.height = 64
	gold_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	gold_glow_texture.fill_from = Vector2(0.5, 0.5)
	gold_glow_texture.fill_to = Vector2(1.0, 0.5)
	return gold_glow_texture


func _moon_resource_glow_texture() -> GradientTexture2D:
	if is_instance_valid(moon_glow_texture):
		return moon_glow_texture
	var gradient: = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 0.72, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.8, 0.98, 1.0, 0.82),
		Color(0.26, 0.9, 1.0, 0.42),
		Color(0.45, 0.28, 1.0, 0.14),
		Color(0.25, 0.18, 0.8, 0.0),
	])
	moon_glow_texture = GradientTexture2D.new()
	moon_glow_texture.gradient = gradient
	moon_glow_texture.width = 128
	moon_glow_texture.height = 128
	moon_glow_texture.fill = GradientTexture2D.FILL_RADIAL
	moon_glow_texture.fill_from = Vector2(0.5, 0.5)
	moon_glow_texture.fill_to = Vector2(1.0, 0.5)
	return moon_glow_texture


func _mountain_tool() -> Dictionary:


	var drill_level: = clampi(
		int(RunState.drill_level),
		0,
		int(GameData.data.DRILLS.size()) - 1
	)
	if drill_level > 0:
		var drill: Dictionary = Dictionary(GameData.data.DRILLS[drill_level]).duplicate(true)
		drill["yield_bonus"] = float(drill.get("yieldBonus", 0.0))
		drill["yield_multiplier"] = 1
		drill["shell_power"] = float(drill.get("shellPower", 0.72))
		return RunState.apply_tool_forge_effects(drill)
	var tool: Dictionary = Dictionary(RunState.current_pickaxe()).duplicate(true)
	var base_yield_bonus: = 0.22 if int(RunState.pickaxe_level) >= 4 else 0.0
	var shell_power: = 0.72
	if int(RunState.pickaxe_level) == int(GameData.data.PICKAXES.size()) - 1:
		var mastery_rows: Array = Array(GameData.data.EMBER_MASTERY)
		var mastery: Dictionary = Dictionary(mastery_rows[
			clampi(int(RunState.ember_mastery), 0, mastery_rows.size() - 1)
		])
		base_yield_bonus = float(mastery.get("bonusYield", base_yield_bonus))
		shell_power = float(mastery.get("shellPower", shell_power))
	tool["yield_bonus"] = base_yield_bonus
	tool["yield_multiplier"] = 1
	tool["shell_power"] = shell_power
	var variant_id: = String(RunState.starforge_variant)
	if not variant_id.is_empty() and GameData.data.STARFORGE_VARIANTS.has(variant_id):
		var variant: Dictionary = Dictionary(GameData.data.STARFORGE_VARIANTS[variant_id])
		tool["name"] = String(variant.name)
		tool["power"] = roundi(float(tool.power) * float(variant.powerMultiplier))
		tool["cooldown"] = float(tool.cooldown) * float(variant.cooldownMultiplier)
		tool["shell_power"] = shell_power * float(variant.get("shellMultiplier", 1.0))
		tool["yield_bonus"] = minf(
			0.92,
			base_yield_bonus + float(variant.get("yieldBonus", 0.0))
		)
		tool["yield_multiplier"] = maxi(1, int(variant.get("yieldMultiplier", 1)))
	return RunState.apply_tool_forge_effects(tool)


func _tool_strike_progress() -> float:
	if int(RunState.drill_level) > 0:
		return 0.2
	match String(RunState.starforge_variant):
		"crusher": return 0.66
		"swift": return 0.28
		"prospector": return 0.42
	return 0.36


func _spawn_mountain_impact(broken: bool, extra_offset: Vector2 = Vector2.ZERO) -> void :
	var sprite: = Sprite2D.new()
	sprite.texture = MOSS_IMPACT
	sprite.hframes = 4
	sprite.frame = 0
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.z_index = 8
	var contact: = ore_mountain_swing_target if ore_mountain_swing_active else _ore_mountain_hit_point(player.global_position)
	var jitter: = Vector2(float((ore_mountain_hit_count * 31) % 25) - 12.0, float((ore_mountain_hit_count * 19) % 17) - 8.0)
	sprite.position = contact + jitter + extra_offset
	var target_size: = 116.0 if broken else 76.0
	sprite.scale = Vector2.ONE * (target_size / 256.0)
	add_child(sprite)
	ore_mountain_impacts.append({
		"sprite": sprite,
		"age": 0.0,
		"life": 0.58 if broken else 0.34,
		"base_scale": sprite.scale,
	})


func _start_mountain_collapse() -> void :
	ore_mountain_collapse_elapsed = ore_mountain_collapse_duration
	ore_mountain_hit_flash = 0.14
	_spawn_mountain_impact(true, Vector2(-74, -18))
	_spawn_mountain_impact(true, Vector2(68, -35))
	_spawn_mountain_impact(true, Vector2(-24, 42))


func _update_mountain_impacts(delta: float) -> void :
	for index in range(ore_mountain_impacts.size() - 1, -1, -1):
		var impact: Dictionary = ore_mountain_impacts[index]
		var sprite: Sprite2D = impact.sprite
		if not is_instance_valid(sprite):
			ore_mountain_impacts.remove_at(index)
			continue
		var age: = float(impact.age) + delta
		var progress: = clampf(age / float(impact.life), 0.0, 1.0)
		sprite.frame = mini(3, floori(progress * 4.0))
		sprite.scale = Vector2(impact.base_scale) * lerpf(0.86, 1.16, progress)
		sprite.modulate.a = 1.0 - clampf((progress - 0.66) / 0.34, 0.0, 1.0)
		impact.age = age
		ore_mountain_impacts[index] = impact
		if progress >= 1.0:
			sprite.queue_free()
			ore_mountain_impacts.remove_at(index)


func _update_ore_drops(delta: float) -> void :
	for index in range(ore_drops.size() - 1, -1, -1):
		var drop: Dictionary = ore_drops[index]
		var sprite: Sprite2D = drop.sprite
		if not is_instance_valid(sprite):
			ore_drops.remove_at(index)
			continue
		var age: = float(drop.age) + delta
		if age >= LOOSE_RESOURCE_LIFETIME:
			RunState.add_resource(String(drop.kind), int(drop.amount), true)
			sprite.queue_free()
			ore_drops.remove_at(index)
			continue
		if bool(drop.collecting):
			var collect_elapsed: = float(drop.collect_elapsed) + delta
			var collect_progress: = clampf(collect_elapsed / ORE_DROP_COLLECT_DURATION, 0.0, 1.0)
			var collect_eased: = collect_progress * collect_progress * (3.0 - 2.0 * collect_progress)
			sprite.global_position = Vector2(drop.collect_origin).lerp(player.global_position + Vector2(0, -28), collect_eased)
			sprite.global_position.y -= sin(collect_progress * PI) * 13.0
			sprite.scale = Vector2(drop.base_scale) * lerpf(1.0, 0.28, collect_eased)
			sprite.modulate.a = 1.0 - clampf((collect_progress - 0.68) / 0.32, 0.0, 1.0)
			drop.collect_elapsed = collect_elapsed
			ore_drops[index] = drop
			if collect_progress >= 1.0:
				RunState.add_resource(String(drop.kind), int(drop.amount), true)
				AudioDirector.play_pickup(String(drop.kind), int(drop.amount))
				sprite.queue_free()
				ore_drops.remove_at(index)
			continue
		if age < ORE_DROP_FLIGHT_DURATION:
			var flight_progress: = clampf(age / ORE_DROP_FLIGHT_DURATION, 0.0, 1.0)
			var eased: = 1.0 - pow(1.0 - flight_progress, 2.0)
			sprite.position = Vector2(drop.launch_position).lerp(Vector2(drop.landing_position), eased)
			sprite.position.y -= sin(flight_progress * PI) * 76.0
			sprite.rotation = flight_progress * TAU * (1.25 if index % 2 == 0 else -1.25)
			sprite.scale = Vector2(drop.base_scale) * (1.0 + sin(flight_progress * PI) * 0.18)
		elif not bool(drop.get("settled", false)):
			sprite.position = Vector2(drop.landing_position)
			sprite.rotation = sin(float(index) * 2.1) * 0.14
			sprite.scale = Vector2(drop.base_scale)
			drop.settled = true
		sprite.modulate.a = _loose_resource_alpha(age)
		drop.age = age
		ore_drops[index] = drop
		if age >= ORE_DROP_FLIGHT_DURATION and sprite.global_position.distance_to(player.global_position) <= _ore_drop_pickup_radius():
			drop.collecting = true
			drop.collect_elapsed = 0.0
			drop.collect_origin = sprite.global_position
			ore_drops[index] = drop


func _loose_resource_alpha(age: float) -> float:
	return clampf(
		(LOOSE_RESOURCE_LIFETIME - age) / LOOSE_RESOURCE_FADE_SECONDS,
		0.0,
		1.0
	)


func _ore_drop_pickup_radius() -> float:
	return RunState.resource_pickup_radius(ORE_DROP_PICKUP_RADIUS)


func _enforce_surface_loose_drop_budget() -> void :
	if surface_drop_budget_enforcing:
		return
	surface_drop_budget_enforcing = true
	while true:
		var candidates: Array[Dictionary] = _surface_drop_budget_candidates()
		var source_counts: Dictionary = {}
		var over_budget_source: = ""
		for candidate_value in candidates:
			var candidate: Dictionary = candidate_value
			var source_id: = String(candidate.source)
			source_counts[source_id] = int(source_counts.get(source_id, 0)) + 1
			if over_budget_source.is_empty() and int(source_counts[source_id]) > SURFACE_LOOSE_DROP_SOURCE_LIMIT:
				over_budget_source = source_id
		if over_budget_source.is_empty():
			break
		var oldest: Dictionary = _oldest_surface_drop_candidate(candidates, over_budget_source)
		if oldest.is_empty() or not _trim_surface_drop_candidate(oldest):
			break
	while true:
		var candidates: Array[Dictionary] = _surface_drop_budget_candidates()
		if candidates.size() <= SURFACE_LOOSE_DROP_TOTAL_LIMIT:
			break
		var oldest: Dictionary = _oldest_surface_drop_candidate(candidates)
		if oldest.is_empty() or not _trim_surface_drop_candidate(oldest):
			break
	var live_count: = _surface_drop_budget_candidates().size()
	surface_drop_budget_peak = maxi(surface_drop_budget_peak, live_count)
	surface_drop_budget_enforcing = false


func _next_surface_drop_budget_serial() -> int:
	surface_drop_budget_serial += 1
	return surface_drop_budget_serial


func _surface_drop_budget_candidates() -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for index in range(ore_drops.size()):
		var drop: Dictionary = ore_drops[index]
		candidates.append(_surface_drop_budget_candidate("ore", "moss_mountain", "", index, drop, candidates.size()))
	for index in range(moon_bloom_drops.size()):
		var drop: Dictionary = moon_bloom_drops[index]
		candidates.append(_surface_drop_budget_candidate("moonglass", "moonglass", "", index, drop, candidates.size()))
	for index in range(surface_resource_mountain_drops.size()):
		var drop: Dictionary = surface_resource_mountain_drops[index]
		var mountain_id: = String(drop.get("mountain_id", "unknown"))
		candidates.append(_surface_drop_budget_candidate(
			"surface_mountain", "mountain:%s" % mountain_id, mountain_id, index, drop, candidates.size()
		))
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		if not timed_surface_veins.has(vein_id):
			continue
		var runtime: Dictionary = timed_surface_veins[vein_id]
		var drops: Array = Array(runtime.get("drops", []))
		for index in range(drops.size()):
			var drop: Dictionary = drops[index]
			candidates.append(_surface_drop_budget_candidate(
				"timed_vein", "vein:%s" % vein_id, vein_id, index, drop, candidates.size()
			))
	for index in range(chest_loot_drops.size()):
		var drop: Dictionary = chest_loot_drops[index]
		var chest_id: = String(drop.get("chest_id", "unknown"))
		candidates.append(_surface_drop_budget_candidate(
			"chest", "chest:%s" % chest_id, chest_id, index, drop, candidates.size()
		))
	return candidates


func _surface_drop_budget_candidate(
	bucket: String,
	source_id: String,
	owner_id: String,
	index: int,
	drop: Dictionary,
	order: int
) -> Dictionary:
	return {
		"bucket": bucket,
		"source": source_id,
		"owner": owner_id,
		"index": index,
		"age": maxf(0.0, float(drop.get("age", 0.0))),
		"serial": int(drop.get("budget_serial", order)),
		"order": order,
	}


func _oldest_surface_drop_candidate(candidates: Array[Dictionary], source_id: String = "") -> Dictionary:
	var oldest: Dictionary = {}
	for candidate_value in candidates:
		var candidate: Dictionary = candidate_value
		if not source_id.is_empty() and String(candidate.source) != source_id:
			continue
		if (
			oldest.is_empty()
			or float(candidate.age) > float(oldest.age)
			or (
				is_equal_approx(float(candidate.age), float(oldest.age))
				and (
					int(candidate.serial) < int(oldest.serial)
					or (
						int(candidate.serial) == int(oldest.serial)
						and int(candidate.order) < int(oldest.order)
					)
				)
			)
		):
			oldest = candidate
	return oldest


func _trim_surface_drop_candidate(candidate: Dictionary) -> bool:
	var bucket: = String(candidate.get("bucket", ""))
	var owner_id: = String(candidate.get("owner", ""))
	var source_id: = String(candidate.get("source", bucket))
	var index: = int(candidate.get("index", -1))
	var drop: Dictionary = {}
	match bucket:
		"ore":
			if index < 0 or index >= ore_drops.size():
				return false
			drop = ore_drops[index]
			ore_drops.remove_at(index)
		"moonglass":
			if index < 0 or index >= moon_bloom_drops.size():
				return false
			drop = moon_bloom_drops[index]
			moon_bloom_drops.remove_at(index)
		"surface_mountain":
			if index < 0 or index >= surface_resource_mountain_drops.size():
				return false
			drop = surface_resource_mountain_drops[index]
			surface_resource_mountain_drops.remove_at(index)
		"timed_vein":
			if not timed_surface_veins.has(owner_id):
				return false
			var runtime: Dictionary = timed_surface_veins[owner_id]
			var drops: Array = Array(runtime.get("drops", []))
			if index < 0 or index >= drops.size():
				return false
			drop = drops[index]
			drops.remove_at(index)
			runtime.drops = drops
			timed_surface_veins[owner_id] = runtime
		"chest":
			if index < 0 or index >= chest_loot_drops.size():
				return false
			drop = chest_loot_drops[index]
			chest_loot_drops.remove_at(index)
		_:
			return false
	var sprite: Sprite2D = drop.get("sprite")
	if is_instance_valid(sprite):
		sprite.visible = false
		sprite.queue_free()
	surface_drop_budget_trimmed += 1
	surface_drop_budget_trimmed_by_source[source_id] = int(surface_drop_budget_trimmed_by_source.get(source_id, 0)) + 1
	var amount: = maxi(0, int(drop.get("amount", 0)))
	if amount <= 0:
		return true
	if bucket == "chest":
		var collected: = RunState.collect_chest_loot(
			String(drop.get("chest_id", owner_id)),
			String(drop.get("reward_id", "")),
			amount
		)
		surface_drop_budget_auto_collected += collected
	else:
		var count_as_mined: = bucket in ["ore", "surface_mountain"]
		RunState.add_resource(String(drop.get("kind", "")), amount, count_as_mined)
		surface_drop_budget_auto_collected += amount
	return true


func surface_loose_drop_budget_snapshot() -> Dictionary:
	var candidates: Array[Dictionary] = _surface_drop_budget_candidates()
	var source_counts: Dictionary = {}
	for candidate_value in candidates:
		var source_id: = String(Dictionary(candidate_value).source)
		source_counts[source_id] = int(source_counts.get(source_id, 0)) + 1
	return {
		"source_limit": SURFACE_LOOSE_DROP_SOURCE_LIMIT,
		"total_limit": SURFACE_LOOSE_DROP_TOTAL_LIMIT,
		"live": candidates.size(),
		"peak": surface_drop_budget_peak,
		"trimmed": surface_drop_budget_trimmed,
		"auto_collected_amount": surface_drop_budget_auto_collected,
		"source_counts": source_counts,
		"trimmed_by_source": surface_drop_budget_trimmed_by_source.duplicate(true),
	}


func assert_surface_loose_drop_budget() -> Dictionary:
	var snapshot: = surface_loose_drop_budget_snapshot()
	assert (int(snapshot.live) <= SURFACE_LOOSE_DROP_TOTAL_LIMIT, "Surface loose-drop total budget exceeded")
	for count_value in Dictionary(snapshot.source_counts).values():
		assert (int(count_value) <= SURFACE_LOOSE_DROP_SOURCE_LIMIT, "Surface loose-drop source budget exceeded")
	assert (int(snapshot.peak) <= SURFACE_LOOSE_DROP_TOTAL_LIMIT, "Surface loose-drop peak escaped its budget")
	return snapshot


func _surface_restored_drop_rows(kind_amounts: Dictionary, kind_order: Array) -> Array[Dictionary]:
	var ordered_kinds: Array[String] = []
	for kind_value in kind_order:
		var kind: = String(kind_value)
		if kind.is_empty() or ordered_kinds.has(kind) or int(kind_amounts.get(kind, 0)) <= 0:
			continue
		ordered_kinds.append(kind)
	var remaining_keys: Array = kind_amounts.keys()
	remaining_keys.sort()
	for kind_value in remaining_keys:
		var kind: = String(kind_value)
		if kind.is_empty() or ordered_kinds.has(kind) or int(kind_amounts.get(kind, 0)) <= 0:
			continue
		ordered_kinds.append(kind)
	if ordered_kinds.is_empty():
		return []
	var total_amount: = 0
	for kind in ordered_kinds:
		total_amount += maxi(0, int(kind_amounts.get(kind, 0)))
	var visual_slots: = mini(total_amount, SURFACE_LOOSE_DROP_SOURCE_LIMIT)
	var visual_counts: Dictionary = {}
	for kind in ordered_kinds:
		if visual_slots <= 0:
			break
		visual_counts[kind] = 1
		visual_slots -= 1
	while visual_slots > 0:
		var assigned: = false
		for kind in ordered_kinds:
			if int(visual_counts.get(kind, 0)) >= int(kind_amounts.get(kind, 0)):
				continue
			visual_counts[kind] = int(visual_counts.get(kind, 0)) + 1
			visual_slots -= 1
			assigned = true
			if visual_slots <= 0:
				break
		if not assigned:
			break
	var rows: Array[Dictionary] = []
	for kind in ordered_kinds:
		var amount_remaining: = maxi(0, int(kind_amounts.get(kind, 0)))
		var visuals_remaining: = int(visual_counts.get(kind, 0))
		while visuals_remaining > 0:
			var piece_amount: = ceili(float(amount_remaining) / float(visuals_remaining))
			rows.append({"kind": kind, "amount": piece_amount})
			amount_remaining -= piece_amount
			visuals_remaining -= 1
	return rows


func _evaluate_context(world_position: Vector2) -> void :
	var next_context: = ""
	var storage_id: = _nearest_surface_storage(world_position)
	if not storage_id.is_empty():
		next_context = "storage:%s" % storage_id
	if next_context.is_empty():
		var chest_id: = _nearest_unopened_surface_chest(world_position)
		if not chest_id.is_empty():
			next_context = "chest:%s" % chest_id
	if (
		next_context.is_empty()
		and
		RunState.is_hub_unlocked()
		and world_position.distance_to(STARFALL_HUB_LIFT_POSITION) <= STARFALL_HUB_LIFT_RADIUS
	):
		next_context = "hubEntrance"
	if next_context.is_empty():
		for mine_id_value in MINE_IDS:
			var mine_id: = String(mine_id_value)
			if not _is_mine_unlocked(mine_id):
				continue




			var radius: = _mine_interaction_radius(mine_id)
			if world_position.distance_to(_mine_entrance(mine_id)) <= radius:
				next_context = "enter:%s" % mine_id
				break
	if next_context.is_empty():
		for boundary_value in BOUNDARIES:
			var boundary: Dictionary = Dictionary(boundary_value)
			if _is_boundary_unlocked(boundary):
				continue
			var gate_position: = gate_interaction_position(String(boundary.station))
			if world_position.distance_to(gate_position) <= GATE_INTERACTION_RADIUS:
				next_context = "gate:%s" % String(boundary.id)
				break
	if next_context.is_empty():
		next_context = _nearest_surface_station_context(world_position)
	if next_context.is_empty():
		next_context = _nearest_surface_mining_context(world_position)
	if next_context == active_context:
		return
	active_context = next_context
	context_changed.emit(active_context)
	if active_context == "enter:mossMine":
		mossvein_entrance_reached.emit()


func _nearest_unopened_surface_chest(world_position: Vector2) -> String:
	var nearest_id: = ""
	var nearest_distance: = CHEST_INTERACT_RADIUS
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: = String(chest.id)
		if RunState.is_surface_chest_opened(chest_id):
			continue
		var distance: = world_position.distance_to(surface_chest_position(chest_id))
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_id = chest_id
	return nearest_id


func _nearest_surface_storage(world_position: Vector2) -> String:
	var nearest_id: = ""
	var nearest_distance: = BASE_MODULE_INTERACT_RADIUS
	for module_value in RunState.all_base_modules():
		var module: Dictionary = Dictionary(module_value)
		if (
			String(module.get("kind", "")) != "storage"
			or bool(module.get("packed", false))
			or String(module.get("scene", "")) != "surface"
			or int(module.get("depth", 1)) != 1
		):
			continue
		var distance: = world_position.distance_to(Vector2(float(module.x), float(module.y)))
		if distance <= nearest_distance:
			nearest_distance = distance
			nearest_id = String(module.id)
	return nearest_id


func _nearest_surface_station_context(world_position: Vector2) -> String:



	var candidates: Array[Dictionary] = [
		{"id": "sell", "position": station_interaction_position("sell"), "radius": SURFACE_STATION_INTERACT_RADIUS},
		{"id": "forge", "position": station_interaction_position("forge"), "radius": SURFACE_STATION_INTERACT_RADIUS},
		{"id": "speedShop", "position": _station_position("speedShop"), "radius": float(GameData.station("speedShop").radius)},
	]
	if RunState.fourth_unlocked:
		candidates.append({
			"id": "starforge",
			"position": _station_position("starforge"),
			"radius": float(GameData.station("starforge").radius),
		})
	var nearest_id: = ""
	var nearest_distance: = INF
	for candidate in candidates:
		var distance: = world_position.distance_to(Vector2(candidate.position))
		if distance <= float(candidate.radius) and distance < nearest_distance:
			nearest_distance = distance
			nearest_id = String(candidate.id)
	return nearest_id


func _resolve_motion(origin: Vector2, motion: Vector2) -> Vector2:
	if motion.length_squared() <= 0.001:
		_reset_surface_route_steering()
		return origin
	var input_direction: = motion.normalized()
	if (
		surface_route_steer_input_direction.length_squared() <= 0.001
		or surface_route_steer_input_direction.dot(input_direction) < SURFACE_ROUTE_STEER_INPUT_RESET_DOT
	):
		surface_route_steer_sign = 0.0
		surface_route_direct_steps = 0
	surface_route_steer_input_direction = input_direction
	var result: = origin
	var step_count: = maxi(1, ceili(motion.length() / SURFACE_MOTION_SUBSTEP))
	var step_motion: = motion / float(step_count)
	for _step in range(step_count):
		var direct_candidate: = result + step_motion
		if not _surface_collides(direct_candidate):
			result = direct_candidate
			surface_route_direct_steps += 1
			if surface_route_direct_steps >= SURFACE_ROUTE_STEER_DIRECT_RESET_STEPS:
				surface_route_steer_sign = 0.0
			continue
		if not _is_on_surface_route(direct_candidate):
			var steered_candidate: = _resolve_surface_route_steer_step(result, step_motion)
			if not steered_candidate.is_equal_approx(result):
				result = steered_candidate
				surface_route_steer_events += 1
				surface_route_direct_steps = 0
				continue
			continue
		result = _resolve_surface_solid_slide_step(result, step_motion)
		surface_route_direct_steps = 0
	var resolved_motion: = result - origin
	if resolved_motion.length_squared() > 0.001:
		surface_last_motion_direction = resolved_motion.normalized()
	return result.clamp(Vector2.ONE * PLAYER_RADIUS, _world_size() - Vector2.ONE * PLAYER_RADIUS)


func _resolve_surface_route_steer_step(origin: Vector2, motion: Vector2) -> Vector2:
	var distance: = motion.length()
	if distance <= 0.001:
		return origin
	var intent: = motion / distance
	var angle_count: = roundi(SURFACE_ROUTE_STEER_MAX_ANGLE / SURFACE_ROUTE_STEER_ANGLE_STEP)
	for angle_index in range(1, angle_count + 1):
		var angle: = deg_to_rad(SURFACE_ROUTE_STEER_ANGLE_STEP * float(angle_index))
		var previous_angle: = deg_to_rad(SURFACE_ROUTE_STEER_ANGLE_STEP * float(angle_index - 1))
		var candidates: Array[Dictionary] = []
		var angle_signs: Array[float] = [-1.0, 1.0]
		if not is_zero_approx(surface_route_steer_sign):
			angle_signs = [surface_route_steer_sign, - surface_route_steer_sign]
		for angle_sign in angle_signs:
			var candidate: = _surface_route_steer_candidate(origin, intent, distance, angle, angle_sign)
			if candidate.is_equal_approx(origin) or _surface_collides(candidate):
				continue
			var refined_angle: = angle
			var invalid_angle: = previous_angle
			for _refine in range(SURFACE_ROUTE_STEER_REFINE_STEPS):
				var test_angle: = (invalid_angle + refined_angle) * 0.5
				var test_candidate: = _surface_route_steer_candidate(origin, intent, distance, test_angle, angle_sign)
				if test_candidate.is_equal_approx(origin) or _surface_collides(test_candidate):
					invalid_angle = test_angle
				else:
					refined_angle = test_angle
					candidate = test_candidate
			if not is_zero_approx(surface_route_steer_sign) and is_equal_approx(angle_sign, surface_route_steer_sign):
				return candidate
			var refined_candidate: = {
				"candidate": candidate,
				"sign": angle_sign,
				"center_distance": candidate.distance_to(_nearest_surface_route_point(candidate)),
			}
			candidates.append(refined_candidate)
		if candidates.size() == 1:
			surface_route_steer_sign = float(Dictionary(candidates[0]).sign)
			return Vector2(Dictionary(candidates[0]).candidate)
		if candidates.size() == 2:
			if not is_zero_approx(surface_route_steer_sign):
				for candidate_value in candidates:
					var signed_candidate: Dictionary = candidate_value
					if is_equal_approx(float(signed_candidate.sign), surface_route_steer_sign):
						return Vector2(signed_candidate.candidate)
			var first: Dictionary = candidates[0]
			var second: Dictionary = candidates[1]
			var center_difference: = float(first.center_distance) - float(second.center_distance)
			if absf(center_difference) <= SURFACE_ROUTE_STEER_CENTER_TIE:
				return origin
			var selected: Dictionary = first if center_difference < 0.0 else second
			surface_route_steer_sign = float(selected.sign)
			return Vector2(selected.candidate)
	return _resolve_surface_route_tangent_step(origin, intent, distance)


func _surface_route_steer_candidate(origin: Vector2, intent: Vector2, distance: float, angle: float, angle_sign: float) -> Vector2:
	var projected_distance: = distance * cos(angle)
	if projected_distance <= 0.001:
		return origin
	var displacement: = intent.rotated(angle * angle_sign) * projected_distance
	if displacement.dot(intent) <= 0.001:
		return origin
	return origin + displacement


func _resolve_surface_route_tangent_step(origin: Vector2, intent: Vector2, distance: float) -> Vector2:
	var natural_tangent: Vector2 = _nearest_surface_route_tangent(origin)
	var directions: Array[Vector2] = []
	if natural_tangent.length_squared() > 0.001:
		directions.append(natural_tangent)
		directions.append( - natural_tangent)
	directions.append(intent.rotated(PI * 0.5))
	directions.append(intent.rotated( - PI * 0.5))
	var continuity: Vector2 = surface_last_motion_direction.normalized()
	var selected: = origin
	var selected_forward: = - INF
	var selected_continuity: = - INF
	var selected_center_distance: = INF
	for direction_value in directions:
		var direction: Vector2 = direction_value.normalized()
		var candidate: Vector2 = origin + direction * distance
		var forward: float = direction.dot(intent)
		if forward < -0.001 or _surface_collides(candidate):
			continue
		var continuity_score: float = direction.dot(continuity)
		var center_distance: float = candidate.distance_to(_nearest_surface_route_point(candidate))
		if (
			forward > selected_forward + 0.001
			or (
				is_equal_approx(forward, selected_forward)
				and (
					continuity_score > selected_continuity + 0.001
					or (
						is_equal_approx(continuity_score, selected_continuity)
						and center_distance < selected_center_distance - SURFACE_ROUTE_STEER_CENTER_TIE
					)
				)
			)
		):
			selected = candidate
			selected_forward = forward
			selected_continuity = continuity_score
			selected_center_distance = center_distance
	if not selected.is_equal_approx(origin):
		var selected_direction: Vector2 = (selected - origin).normalized()
		var cross: float = intent.cross(selected_direction)
		surface_route_steer_sign = 1.0 if cross >= 0.0 else -1.0
	return selected


func _resolve_surface_solid_slide_step(origin: Vector2, motion: Vector2) -> Vector2:
	var candidates: Array[Vector2] = []
	var next_x: = origin + Vector2(motion.x, 0.0)
	if not next_x.is_equal_approx(origin) and not _surface_collides(next_x):
		candidates.append(next_x)
	var next_y: = origin + Vector2(0.0, motion.y)
	if not next_y.is_equal_approx(origin) and not _surface_collides(next_y):
		candidates.append(next_y)
	if candidates.is_empty():
		return origin
	var intent: = motion.normalized()
	var continuity: = surface_last_motion_direction.normalized()
	var selected: Vector2 = candidates[0]
	var selected_forward: float = (selected - origin).dot(intent)
	var selected_continuity: float = (selected - origin).normalized().dot(continuity)
	for candidate_value in candidates.slice(1):
		var candidate: Vector2 = candidate_value
		var forward: float = (candidate - origin).dot(intent)
		var continuity_score: float = (candidate - origin).normalized().dot(continuity)
		if forward > selected_forward + 0.001 or (is_equal_approx(forward, selected_forward) and continuity_score > selected_continuity):
			selected = candidate
			selected_forward = forward
			selected_continuity = continuity_score
	return selected


func _reset_surface_route_steering() -> void :
	surface_route_steer_sign = 0.0
	surface_route_steer_input_direction = Vector2.ZERO
	surface_route_direct_steps = 0


func route_steering_snapshot() -> Dictionary:
	return {
		"enabled": true,
		"angle_step": SURFACE_ROUTE_STEER_ANGLE_STEP,
		"maximum_angle": SURFACE_ROUTE_STEER_MAX_ANGLE,
		"refine_steps": SURFACE_ROUTE_STEER_REFINE_STEPS,
		"projected_speed": true,
		"tangent_fallback": true,
		"never_reverses_input": SURFACE_ROUTE_STEER_MAX_ANGLE < 90.0,
		"visible_solids_remain_blocking": true,
		"events": surface_route_steer_events,
		"corridors": surface_route_corridors.size(),
		"broadphase_rejects": surface_route_broadphase_rejects,
		"segment_checks": surface_route_segment_checks,
		"last_direction": surface_last_motion_direction,
	}


func _surface_collides(position: Vector2) -> bool:
	# Solid feet are registered to the same canvas as the complete gate artwork.
	for boundary in BOUNDARIES:
		var anchor: Vector2 = Vector2(float(boundary.x), GATE_Y)
		for foot in [anchor + Vector2(-82,-42), anchor + Vector2(115,37)]:
			var normalized_foot: Vector2 = (position - Vector2(foot)) / Vector2(58,43)
			if normalized_foot.length_squared() < 1.0:
				return true
	if not _is_on_surface_route(position):
		return true
	if position.x <= MOSS_GATE_ANCHOR.x + BOUNDARY_HALF_WIDTH + PLAYER_RADIUS and position.y > MOSS_WALKABLE_BOTTOM:
		return true





	var mountain_offset: = position - MOSS_ORE_MOUNTAIN_COLLISION_CENTER
	var mountain_collision: = Vector2(
		mountain_offset.x / (MOSS_ORE_MOUNTAIN_COLLISION_HALF_SIZE.x + PLAYER_RADIUS),
		mountain_offset.y / (MOSS_ORE_MOUNTAIN_COLLISION_HALF_SIZE.y + PLAYER_RADIUS)
	)
	if mountain_collision.length_squared() < 1.0:
		return true



	for collision_value in SURFACE_RESOURCE_MOUNTAIN_COLLISIONS.values():
		var collision: Dictionary = collision_value
		var center: = Vector2(collision.center)
		var half_size: = Vector2(collision.half_size)
		var offset: = position - center
		var normalized: = Vector2(
			offset.x / (half_size.x + PLAYER_RADIUS),
			offset.y / (half_size.y + PLAYER_RADIUS)
		)
		if normalized.length_squared() < 1.0:
			return true
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		var boundary_x: = float(boundary.x)
		if absf(position.x - boundary_x) > BOUNDARY_HALF_WIDTH + PLAYER_RADIUS:
			continue
		if not _is_boundary_unlocked(boundary):
			return true
		if absf(position.y - GATE_Y) + PLAYER_RADIUS > GATE_HALF_GAP:
			return true
	return false


func _is_boundary_unlocked(boundary: Dictionary) -> bool:
	var transition: WorldTransitionVisual = portal_transitions.get(String(boundary.id)) as WorldTransitionVisual
	return (
		_raw_boundary_unlocked(boundary)
		and is_instance_valid(transition)
		and transition.is_passage_open()
	)


func _sync_portal_transition(gate_id: String, unlocked: bool, animate_open: bool) -> void :
	var transition: WorldTransitionVisual = portal_transitions.get(gate_id) as WorldTransitionVisual
	if not is_instance_valid(transition):
		return
	var state: = String(transition.debug_snapshot().get("state", "locked"))
	if unlocked:
		if state == "locked":
			transition.set_gate_open(true, animate_open)
	elif state != "locked":
		transition.set_gate_open(false, false)


func _reset_portal_transition_observations() -> void :
	if not is_instance_valid(player):
		return
	for transition_value in portal_transitions.values():
		var transition: WorldTransitionVisual = transition_value as WorldTransitionVisual
		if is_instance_valid(transition):
			transition.reset_actor_observation(player.global_position)


func _raw_boundary_unlocked(boundary: Dictionary) -> bool:
	return bool(RunState.get(String(boundary.unlock_key)))


func _is_mine_unlocked(mine_id: String) -> bool:
	match mine_id:
		"moonMine":
			return bool(RunState.get("area_unlocked"))
		"emberMine":
			return bool(RunState.get("emberdeep_unlocked"))
		"starMine":
			return bool(RunState.get("fourth_unlocked"))
		_:
			return true


func _mine_entrance(mine_id: String) -> Vector2:
	if mine_id == "mossMine":
		return MOSS_MINE_ENTRANCE
	var data: Dictionary = GameData.mine(mine_id).surfaceEntrance
	return Vector2(float(data.x), float(data.y))


func _mine_interaction_radius(mine_id: String) -> float:
	var data_radius: = float(GameData.mine(mine_id).surfaceEntrance.radius)
	if mine_id == "mossMine":
		return maxf(data_radius, MOSS_MINE_INTERACTION_RADIUS)
	return maxf(data_radius, LATER_MINE_INTERACTION_RADIUS)


func _ore_mountain_hit_point(from_position: Vector2) -> Vector2:



	var ray: = from_position - MOSS_ORE_MOUNTAIN_COLLISION_CENTER
	if ray.is_zero_approx():
		ray = Vector2.DOWN
	var ellipse_length: = sqrt(
		pow(ray.x / MOSS_ORE_MOUNTAIN_COLLISION_HALF_SIZE.x, 2.0)
		+ pow(ray.y / MOSS_ORE_MOUNTAIN_COLLISION_HALF_SIZE.y, 2.0)
	)
	if ellipse_length <= 0.001:
		return MOSS_ORE_MOUNTAIN_COLLISION_CENTER + Vector2.DOWN * MOSS_ORE_MOUNTAIN_COLLISION_HALF_SIZE.y
	return MOSS_ORE_MOUNTAIN_COLLISION_CENTER + ray / ellipse_length


func _surface_resource_mountain_hit_point(mountain_id: String, from_position: Vector2) -> Vector2:
	if not SURFACE_RESOURCE_MOUNTAIN_COLLISIONS.has(mountain_id):
		return from_position
	var collision: Dictionary = SURFACE_RESOURCE_MOUNTAIN_COLLISIONS[mountain_id]
	var center: = Vector2(collision.center)
	var half_size: = Vector2(collision.half_size)
	var ray: = from_position - center
	if ray.is_zero_approx():
		ray = Vector2.DOWN
	var ellipse_length: = sqrt(
		pow(ray.x / half_size.x, 2.0)
		+ pow(ray.y / half_size.y, 2.0)
	)
	if ellipse_length <= 0.001:
		return center + Vector2.DOWN * half_size.y
	return center + ray / ellipse_length


func _surface_resource_mountain_unlocked(mountain_id: String) -> bool:
	if not SURFACE_RESOURCE_MOUNTAIN_CONFIGS.has(mountain_id):
		return false
	return bool(RunState.get(String(Dictionary(SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]).unlock)))


func _surface_resource_mountain_distance(mountain_id: String, world_position: Vector2) -> float:
	return world_position.distance_to(_surface_resource_mountain_hit_point(mountain_id, world_position))


func _nearest_surface_mining_context(world_position: Vector2) -> String:
	var candidates: Array[Dictionary] = []
	if _is_near_ore_mountain(world_position):
		candidates.append({
			"context": "ore_mountain",
			"distance": world_position.distance_to(_ore_mountain_hit_point(world_position)),
		})
	if bool(RunState.area_unlocked):
		for node_value in moon_bloom_nodes:
			var node: Dictionary = node_value
			if int(node.hp) <= 0:
				continue
			var distance: = world_position.distance_to(Vector2(node.position))
			if distance <= _effective_mining_range(MOON_BLOOM_NODE_CONTEXT_RADIUS):
				candidates.append({"context": "moonglass_resource", "distance": distance})
		if _surface_resource_mountain_unlocked(MOON_MOUNTAIN_ID):
			var distance: = _surface_resource_mountain_distance(MOON_MOUNTAIN_ID, world_position)
			var reach: = _effective_mining_range(SURFACE_RESOURCE_MOUNTAIN_MINING_RANGE)
			if active_context == MOON_MOUNTAIN_ID:
				reach += SURFACE_RESOURCE_MOUNTAIN_TARGET_HYSTERESIS
			if distance <= reach:
				candidates.append({"context": MOON_MOUNTAIN_ID, "distance": distance})
	if bool(RunState.emberdeep_unlocked):
		var ember_runtime: Dictionary = timed_surface_veins.get(EMBER_FAULT_ID, {})
		for node_value in Array(ember_runtime.get("nodes", [])):
			var node: Dictionary = node_value
			if int(node.hp) <= 0:
				continue
			var distance: = world_position.distance_to(Vector2(node.position))
			if distance <= _effective_mining_range(TIMED_SURFACE_NODE_CONTEXT_RADIUS):
				candidates.append({"context": "ember_resource", "distance": distance})
		if _surface_resource_mountain_unlocked(EMBER_MOUNTAIN_ID):
			var distance: = _surface_resource_mountain_distance(EMBER_MOUNTAIN_ID, world_position)
			var reach: = _effective_mining_range(SURFACE_RESOURCE_MOUNTAIN_MINING_RANGE)
			if active_context == EMBER_MOUNTAIN_ID:
				reach += SURFACE_RESOURCE_MOUNTAIN_TARGET_HYSTERESIS
			if distance <= reach:
				candidates.append({"context": EMBER_MOUNTAIN_ID, "distance": distance})
	if bool(RunState.fourth_unlocked):
		var star_runtime: Dictionary = timed_surface_veins.get(STARFALL_LATTICE_ID, {})
		for node_value in Array(star_runtime.get("nodes", [])):
			var node: Dictionary = node_value
			if int(node.hp) <= 0:
				continue
			var distance: = world_position.distance_to(Vector2(node.position))
			if distance <= _effective_mining_range(TIMED_SURFACE_NODE_CONTEXT_RADIUS):
				candidates.append({"context": "starfall_resource", "distance": distance})
		if _surface_resource_mountain_unlocked(STAR_MOUNTAIN_ID):
			var distance: = _surface_resource_mountain_distance(STAR_MOUNTAIN_ID, world_position)
			var reach: = _effective_mining_range(SURFACE_RESOURCE_MOUNTAIN_MINING_RANGE)
			if active_context == STAR_MOUNTAIN_ID:
				reach += SURFACE_RESOURCE_MOUNTAIN_TARGET_HYSTERESIS
			if distance <= reach:
				candidates.append({"context": STAR_MOUNTAIN_ID, "distance": distance})
	var nearest_context: = ""
	var nearest_distance: = INF
	for candidate in candidates:
		if float(candidate.distance) < nearest_distance:
			nearest_distance = float(candidate.distance)
			nearest_context = String(candidate.context)
	return nearest_context


func _is_near_ore_mountain(world_position: Vector2) -> bool:
	var range: = _effective_mining_range(MOSS_ORE_MOUNTAIN_MINING_RANGE)
	if active_context == "ore_mountain":
		range += MOSS_ORE_MOUNTAIN_TARGET_HYSTERESIS
	return world_position.distance_to(_ore_mountain_hit_point(world_position)) <= range


func _effective_mining_range(base_range: float) -> float:
	return base_range * RunState.endless_tool_range_multiplier()


func _ore_mountain_facing_direction(from_position: Vector2, target_position: Vector2) -> Vector2:



	var toward_target: = target_position - from_position
	if absf(toward_target.x) >= absf(toward_target.y):
		return Vector2.RIGHT if toward_target.x >= 0.0 else Vector2.LEFT
	return Vector2.DOWN if toward_target.y >= 0.0 else Vector2.UP


func _movement_speed() -> float:
	return float(GameData.data.PLAYER_SPEED) * RunState.movement_speed_multiplier()


func _station_position(station_id: String) -> Vector2:
	var editable_station_paths: = {
		"sell": "Flyttbare_Stasjoner/ASSAY_flytt_hele_denne",
		"forge": "Flyttbare_Stasjoner/FORGE_flytt_hele_denne",
	}
	if editable_station_paths.has(station_id):
		var editable_station: = get_node_or_null(String(editable_station_paths[station_id])) as Node2D
		if editable_station != null:
			return editable_station.position
	if station_id == "speedShop":
		return MOSS_WAYFARER_POSITION
	var data: Dictionary = GameData.station(station_id)
	return Vector2(float(data.x), float(data.y))


func surface_chest_position(chest_id: String) -> Vector2:
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		if String(chest.id) == chest_id:
			return Vector2(float(chest.x), float(chest.y))
	return Vector2.ZERO


func station_interaction_position(station_id: String) -> Vector2:


	var position: = _station_position(station_id)
	if station_id in ["sell", "forge"]:
		return position + SURFACE_STATION_APPROACH_OFFSET
	return position


func _is_on_surface_route(position: Vector2) -> bool:
	if MOSS_CAMP_TERRACE_RECT.has_point(position):
		return true
	if MOSS_WAYFARER_ACCESS_RECT.has_point(position):
		return true
	if MOSS_MINE_POCKET_RECT.has_point(position):
		return true
	var moon_platform_offset: = position - MOON_BLOOM_CENTER
	if pow(moon_platform_offset.x / 238.0, 2.0) + pow(moon_platform_offset.y / 82.0, 2.0) <= 1.0:
		return true
	for corridor_value in surface_route_corridors:
		var corridor: Dictionary = corridor_value
		if not Rect2(corridor.bounds).has_point(position):
			surface_route_broadphase_rejects += 1
			continue
		if _distance_to_route(position, Array(corridor.route)) <= float(corridor.half_width):
			return true
	for mine_id_value in MINE_IDS:
		if position.distance_to(_mine_entrance(String(mine_id_value))) <= MINE_LANDING_RADIUS:
			return true
	return false


func _is_on_mossvein_route(position: Vector2) -> bool:
	return (
		MOSS_CAMP_TERRACE_RECT.has_point(position)
		or MOSS_WAYFARER_ACCESS_RECT.has_point(position)
		or MOSS_MINE_POCKET_RECT.has_point(position)
		or _distance_to_route(position, MOSS_MAIN_ROUTE) <= MOSS_MAIN_ROUTE_HALF_WIDTH
		or _distance_to_route(position, MOSS_MINE_BRANCH_ROUTE) <= MOSS_BRANCH_ROUTE_HALF_WIDTH
	)


func _surface_walk_routes() -> Array:
	var routes: Array = [MOSS_MAIN_ROUTE, MOSS_MINE_BRANCH_ROUTE, MOON_BLOOM_PLATFORM_ACCESS_ROUTE]
	for route_value in LATER_MAIN_ROUTES.values():
		routes.append(Array(route_value))
	for route_value in LATER_MINE_BRANCH_ROUTES.values():
		routes.append(Array(route_value))
	for route_value in LATER_RESOURCE_ACCESS_ROUTES.values():
		routes.append(Array(route_value))
	return routes


func _build_surface_route_corridors() -> void :
	surface_route_corridors.clear()
	_append_surface_route_corridor(MOSS_MAIN_ROUTE, MOSS_MAIN_ROUTE_HALF_WIDTH)
	_append_surface_route_corridor(MOSS_MINE_BRANCH_ROUTE, MOSS_BRANCH_ROUTE_HALF_WIDTH)
	_append_surface_route_corridor(MOON_BLOOM_PLATFORM_ACCESS_ROUTE, LATER_BRANCH_ROUTE_HALF_WIDTH)
	for route_value in LATER_MAIN_ROUTES.values():
		_append_surface_route_corridor(Array(route_value), LATER_MAIN_ROUTE_HALF_WIDTH)
	for route_value in LATER_MINE_BRANCH_ROUTES.values():
		_append_surface_route_corridor(Array(route_value), LATER_BRANCH_ROUTE_HALF_WIDTH)
	for route_value in LATER_RESOURCE_ACCESS_ROUTES.values():
		_append_surface_route_corridor(Array(route_value), RESOURCE_ACCESS_ROUTE_HALF_WIDTH)


func _append_surface_route_corridor(route: Array, half_width: float) -> void :
	if route.is_empty():
		return
	var minimum: = Vector2(route[0])
	var maximum: = minimum
	for point_value in route.slice(1):
		var point: = Vector2(point_value)
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	var route_bounds: = Rect2(minimum, maximum - minimum)
	surface_route_corridors.append({
		"route": route,
		"half_width": half_width,
		"route_bounds": route_bounds,
		"bounds": route_bounds.grow(half_width),
		"search_bounds": route_bounds.grow(SURFACE_ROUTE_NEAREST_MARGIN),
	})


func _nearest_surface_route_point(position: Vector2) -> Vector2:
	var nearest: = PLAYER_START
	var nearest_distance: = INF
	var route_upper_bound: = INF
	for corridor_value in surface_route_corridors:
		var corridor: Dictionary = corridor_value
		if not Rect2(corridor.search_bounds).has_point(position):
			continue
		var candidate: = _closest_point_on_route(position, Array(corridor.route))
		route_upper_bound = position.distance_squared_to(candidate)
		break
	for corridor_value in surface_route_corridors:
		var corridor: Dictionary = corridor_value
		if _distance_squared_to_rect(position, Rect2(corridor.route_bounds)) > route_upper_bound:
			surface_route_broadphase_rejects += 1
			continue
		var candidate: = _closest_point_on_route(position, Array(corridor.route))
		var distance: = position.distance_squared_to(candidate)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
			route_upper_bound = minf(route_upper_bound, distance)
	for rect in [
		MOSS_CAMP_TERRACE_RECT, MOSS_WAYFARER_ACCESS_RECT, MOSS_MINE_POCKET_RECT,
	]:
		var walk_rect: = Rect2(rect)
		var candidate: = position.clamp(walk_rect.position, walk_rect.end)
		var distance: = position.distance_squared_to(candidate)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	var moon_offset: = position - MOON_BLOOM_CENTER
	var moon_length: = sqrt(pow(moon_offset.x / 238.0, 2.0) + pow(moon_offset.y / 82.0, 2.0))
	if moon_length > 0.001:
		var moon_candidate: = MOON_BLOOM_CENTER + moon_offset / maxf(1.0, moon_length)
		var moon_distance: = position.distance_squared_to(moon_candidate)
		if moon_distance < nearest_distance:
			nearest = moon_candidate
			nearest_distance = moon_distance
	return nearest.clamp(Vector2.ONE * PLAYER_RADIUS, _world_size() - Vector2.ONE * PLAYER_RADIUS)


func _nearest_surface_route_tangent(position: Vector2) -> Vector2:
	var nearest_tangent: = Vector2.ZERO
	var nearest_distance: = INF
	var route_upper_bound: = INF
	for corridor_value in surface_route_corridors:
		var corridor: Dictionary = corridor_value
		if not Rect2(corridor.search_bounds).has_point(position):
			continue
		var candidate: = _closest_point_on_route(position, Array(corridor.route))
		route_upper_bound = position.distance_squared_to(candidate)
		break
	for corridor_value in surface_route_corridors:
		var corridor: Dictionary = corridor_value
		if _distance_squared_to_rect(position, Rect2(corridor.route_bounds)) > route_upper_bound:
			surface_route_broadphase_rejects += 1
			continue
		var route: Array = Array(corridor.route)
		for index in range(route.size() - 1):
			surface_route_segment_checks += 1
			var start: Vector2 = Vector2(route[index])
			var finish: Vector2 = Vector2(route[index + 1])
			var segment: Vector2 = finish - start
			var length_squared: float = segment.length_squared()
			if length_squared <= 0.001:
				continue
			var factor: float = clampf((position - start).dot(segment) / length_squared, 0.0, 1.0)
			var candidate: Vector2 = start + segment * factor
			var distance: float = position.distance_squared_to(candidate)
			if distance < nearest_distance:
				nearest_distance = distance
				route_upper_bound = minf(route_upper_bound, distance)
				nearest_tangent = segment.normalized()
	return nearest_tangent


func _distance_squared_to_rect(position: Vector2, bounds: Rect2) -> float:
	var nearest: = position.clamp(bounds.position, bounds.end)
	return position.distance_squared_to(nearest)


func _closest_point_on_route(position: Vector2, route: Array) -> Vector2:
	var nearest: = Vector2(route[0]) if not route.is_empty() else PLAYER_START
	var nearest_distance: = INF
	for index in range(route.size() - 1):
		surface_route_segment_checks += 1
		var start: = Vector2(route[index])
		var finish: = Vector2(route[index + 1])
		var segment: = finish - start
		var length_squared: = segment.length_squared()
		var factor: = 0.0 if length_squared <= 0.001 else clampf((position - start).dot(segment) / length_squared, 0.0, 1.0)
		var candidate: = start + segment * factor
		var distance: = position.distance_squared_to(candidate)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _distance_to_route(position: Vector2, route: Array) -> float:
	var nearest: = INF
	for index in range(route.size() - 1):
		surface_route_segment_checks += 1
		var start: = Vector2(route[index])
		var finish: = Vector2(route[index + 1])
		var segment: = finish - start
		var length_squared: = segment.length_squared()
		var factor: = 0.0 if length_squared <= 0.001 else clampf((position - start).dot(segment) / length_squared, 0.0, 1.0)
		nearest = minf(nearest, position.distance_to(start + segment * factor))
	return nearest


func debug_worldflow_snapshot() -> Dictionary:
	var snapshot: = {
		"main_y": MOSS_MAIN_Y,
		"camp_anchor": MOSS_CAMP_ANCHOR,
		"quarry_focus": MOSS_QUARRY_FOCUS,
		"mine_branch_junction": MOSS_MINE_BRANCH_JUNCTION,
		"mine_entrance": MOSS_MINE_ENTRANCE,
		"mine_interaction_radius": MOSS_MINE_INTERACTION_RADIUS,
		"gate_anchor": MOSS_GATE_ANCHOR,
		"moon_preview_anchor": MOON_PREVIEW_ANCHOR,
		"main_route": PackedVector2Array(MOSS_MAIN_ROUTE),
		"mine_branch_route": PackedVector2Array(MOSS_MINE_BRANCH_ROUTE),
		"stations": {
			"assay_visual": _station_position("sell"),
			"assay_interaction": station_interaction_position("sell"),
			"forge_visual": _station_position("forge"),
			"forge_interaction": station_interaction_position("forge"),
			"wayfarer_visual": _station_position("speedShop"),
			"interaction_radius": SURFACE_STATION_INTERACT_RADIUS,
		},
		"assets": {
			"branch": MOSS_MINE_RAMP.resource_path,
			"road": ROAD_TEXTURES.mossvein.resource_path,
			"mountain": MOSS_ORE_MOUNTAIN.resource_path,
			"gate": GATE_TEXTURES.moonglass.resource_path,
			"portal_generator": PORTAL_ARCH_TEXTURES.moonglass.resource_path,
		},
		"portal_clearing": {
			"gate_anchor": MOSS_GATE_ANCHOR,
			"gate_max_size": SURFACE_GATE_MAX_SIZE,
			"gate_bottom": SURFACE_GATE_BOTTOM,
			"generator_source_rect": PORTAL_GENERATOR_SOURCE_RECT,
			"generator_max_size": PORTAL_GENERATOR_MAX_SIZE,
			"generator_bottom": PORTAL_GENERATOR_BOTTOM,
			"seam_gate": true,
			"player_occlusion_split": false,
			"travel_axis": Vector2.RIGHT,
			"lanterns": PackedVector2Array(MOSS_PORTAL_LANTERN_POSITIONS),
			"decor_count": moss_portal_clearing_nodes.size(),
			"collision_neutral": true,
			"road_center_clear": true,
			"boundary_ridge": BOUNDARY_TEXTURES.moonglass.resource_path,
			"boundary_ridge_region": Rect2(300, 0, 424, 1536),
			"boundary_ridge_world_rect": Rect2(900, 0, 420, 1280),
		},
		"terrain_banks": {
			"count": 0,
			"organic_sprite_banks": false,
			"collision_neutral": true,
			"rendering": "authored_road_texture",
		},
		"branch_visual": {
			"texture": MOSS_MINE_RAMP.resource_path,
			"source_start": MOSS_RAMP_SOURCE_START,
			"source_end": MOSS_RAMP_SOURCE_END,
			"world_start": MOSS_MINE_BRANCH_JUNCTION,
			"world_end": MOSS_MINE_ENTRANCE,
			"position": MOSS_MINE_RAMP_POSITION,
			"scale": MOSS_MINE_RAMP_SCALE,
			"rotation": moss_mine_branch_sprite.rotation if is_instance_valid(moss_mine_branch_sprite) else 0.0,
		},
	}
	if is_instance_valid(moonglass_transition):
		snapshot["portal"] = moonglass_transition.debug_snapshot()
	var portal_snapshots: = {}
	for gate_id_value in portal_transitions.keys():
		var gate_id: = String(gate_id_value)
		var transition: WorldTransitionVisual = portal_transitions[gate_id] as WorldTransitionVisual
		if is_instance_valid(transition):
			portal_snapshots[gate_id] = transition.debug_snapshot()
	snapshot["portals"] = portal_snapshots
	if is_instance_valid(surface_parallax):
		snapshot["parallax"] = surface_parallax.debug_snapshot()
	return snapshot


func surface_route_snapshot() -> Dictionary:
	var main_routes: = {
		"mossvein": PackedVector2Array(MOSS_MAIN_ROUTE),
		"moonglass": PackedVector2Array(Array(LATER_MAIN_ROUTES.moonglass)),
		"emberdeep": PackedVector2Array(Array(LATER_MAIN_ROUTES.emberdeep)),
		"starfall": PackedVector2Array(Array(LATER_MAIN_ROUTES.starfall)),
	}

	var branches: = {}
	for mine_id_value in MINE_IDS:
		var mine_id: = String(mine_id_value)
		var route: Array = MOSS_MINE_BRANCH_ROUTE if mine_id == "mossMine" else Array(LATER_MINE_BRANCH_ROUTES[mine_id])
		var sprite: Sprite2D = surface_mine_branch_sprites.get(mine_id)
		var backing: Sprite2D = surface_mine_branch_backing_sprites.get(mine_id)
		var entrance_sprite: Sprite2D = entrance_nodes.get(mine_id)
		var entrance_size: = Vector2.ZERO
		var entrance_rect: = Rect2()
		if is_instance_valid(entrance_sprite) and entrance_sprite.texture != null:
			entrance_size = Vector2(entrance_sprite.texture.get_size()) * entrance_sprite.scale.abs()
			entrance_rect = Rect2(entrance_sprite.position, entrance_size)
		branches[mine_id] = {
			"route": PackedVector2Array(route),
			"entrance": _mine_entrance(mine_id),
			"return_position": _mine_return_position(mine_id),
			"interaction_radius": _mine_interaction_radius(mine_id),
			"asset": String(sprite.texture.resource_path) if is_instance_valid(sprite) and sprite.texture != null else "",
			"visual_present": is_instance_valid(sprite),
			"visual_position": sprite.position if is_instance_valid(sprite) else Vector2.ZERO,
			"visual_rotation": sprite.rotation if is_instance_valid(sprite) else 0.0,
			"backing_present": is_instance_valid(backing),
			"backing_asset": String(backing.texture.resource_path) if is_instance_valid(backing) and backing.texture != null else "",
			"entrance_visual_present": is_instance_valid(entrance_sprite),
			"entrance_visible": entrance_sprite.visible if is_instance_valid(entrance_sprite) else false,
			"entrance_asset": String(entrance_sprite.texture.resource_path) if is_instance_valid(entrance_sprite) and entrance_sprite.texture != null else "",
			"entrance_visual_size": entrance_size,
			"entrance_visual_rect": entrance_rect,
		}

	var boundaries: Array[Dictionary] = []
	for boundary_value in BOUNDARIES:
		var boundary: Dictionary = Dictionary(boundary_value)
		var boundary_id: = String(boundary.id)
		var anchor: = Vector2(float(boundary.x), GATE_Y)
		var station: Dictionary = GameData.station(String(boundary.station))
		var interaction_position: = gate_interaction_position(String(boundary.station))
		var backing: Sprite2D = boundary_backing_nodes.get(boundary_id)
		var transition: WorldTransitionVisual = portal_transitions.get(boundary_id) as WorldTransitionVisual
		var gate_visual_present: = is_instance_valid(transition)
		var gate_visual_rect: = Rect2()
		var seam_rect: = Rect2()
		var overlay_rect: = Rect2()
		var portal_snapshot: = {}
		if is_instance_valid(transition):
			portal_snapshot = transition.debug_snapshot()
			gate_visual_rect = Rect2(portal_snapshot.gate_visual_rect)
			gate_visual_rect.position += anchor
			var seam_size: = Vector2(portal_snapshot.seam_back_size)
			var overlay_size: = Vector2(portal_snapshot.seam_front_size)
			seam_rect = Rect2(anchor - seam_size * 0.5, seam_size)
			overlay_rect = Rect2(anchor - overlay_size * 0.5, overlay_size)
		var generator_rect: = Rect2()
		var generator_present: = portal_generator_nodes.has(boundary_id)
		if generator_present:
			generator_rect = Rect2(Dictionary(portal_generator_nodes[boundary_id]).rect)
		boundaries.append({
			"id": boundary_id,
			"anchor": anchor,
			"station_position": interaction_position,
			"station_radius": GATE_INTERACTION_RADIUS,
			"source_station_position": Vector2(float(station.x), float(station.y)),
			"source_station_radius": float(station.radius),
			"backing_asset": String(BOUNDARY_TEXTURES[boundary_id].resource_path),
			"backing_visual_present": is_instance_valid(backing),
			"gate_asset": String(GATE_TEXTURES[boundary_id].resource_path),
			"mark_asset": String(GATE_MARK_TEXTURES[boundary_id].resource_path),
			"gate_visual_present": gate_visual_present,
			"gate_visual_rect": gate_visual_rect,
			"seam_present": gate_visual_present and bool(portal_snapshot.get("seam_mode", false)),
			"seam_rect": seam_rect,
			"overlay_rect": overlay_rect,
			"seam_palette": PackedColorArray([
				Color(portal_snapshot.get("source_color", Color.WHITE)),
				Color(portal_snapshot.get("destination_color", Color.WHITE)),
			]),
			"transition_debug": portal_snapshot,
			"portal_generator_asset": String(PORTAL_ARCH_TEXTURES[boundary_id].resource_path),
			"portal_generator_source_rect": PORTAL_GENERATOR_SOURCE_RECT,
			"generator_visual_present": generator_present,
			"generator_rect": generator_rect,
			"legacy_arch_present": false,
			"portal_arch_asset": "",
			"portal_arch_rect": Rect2(),
			"player_occlusion_split": false,
			"travel_axis": Vector2.RIGHT,
			"locked": not _is_boundary_unlocked(boundary),
		})

	var chest_rows: Array[Dictionary] = []
	for chest_value in Array(GameData.data.CHEST_DEFINITIONS):
		var chest: Dictionary = Dictionary(chest_value)
		var chest_id: = String(chest.id)
		chest_rows.append({
			"id": chest_id,
			"biome": String(chest.biome),
			"position": surface_chest_position(chest_id),
			"off_main_road": absf(surface_chest_position(chest_id).y - GATE_Y) >= 180.0,
		})

	return {
		"main_routes": main_routes,
		"branches": branches,
		"boundaries": boundaries,
		"chests": chest_rows,
		"stations": {
			"assay": _station_position("sell"),
			"forge": _station_position("forge"),
			"wayfarer": _station_position("speedShop"),
			"camp_pocket": MOSS_CAMP_YARD_RECT,
			"wayfarer_pocket": MOSS_WAYFARER_ACCESS_RECT,
		},
		"collision_contract": {
			"visible_mountain": MOSS_ORE_MOUNTAIN.resource_path,
			"boundary_half_width": BOUNDARY_HALF_WIDTH,
			"gate_y": GATE_Y,
			"gate_half_gap": GATE_HALF_GAP,
			"no_route_mask": false,
			"motion_substep": SURFACE_MOTION_SUBSTEP,
			"main_route_half_width": LATER_MAIN_ROUTE_HALF_WIDTH,
			"mine_route_half_width": LATER_BRANCH_ROUTE_HALF_WIDTH,
		},
	}


func _world_size() -> Vector2:
	var world: Dictionary = GameData.world()
	return Vector2(float(world.width), float(world.height))


func ore_mountain_snapshot() -> Dictionary:
	return {
		"position": MOSS_ORE_MOUNTAIN_POSITION,
		"hit_target": _ore_mountain_hit_point(player.global_position),
		"mining_range": _effective_mining_range(MOSS_ORE_MOUNTAIN_MINING_RANGE),
		"pickup_radius": _ore_drop_pickup_radius(),
		"hp": ore_mountain_hp,
		"max_hp": MOSS_ORE_MOUNTAIN_MAX_HP,
		"reserve": float(ore_mountain_hp) / float(MOSS_ORE_MOUNTAIN_MAX_HP),
		"yield_buffer": ore_mountain_copper_yield_buffer,
		"gold_ready": ore_mountain_gold_ready,
		"mineable": true,
		"regrowth_seconds": MOSS_ORE_MOUNTAIN_REGROWTH_SECONDS,
		"depleted": ore_mountain_hp <= 0,
		"context": active_context,
		"effective_tool": _mountain_tool(),
	}


func moonglass_resource_snapshot() -> Dictionary:
	var drop_kinds: = {"moonglass": 0, "starshard": 0}
	for drop in moon_bloom_drops:
		var kind: = String(drop.get("kind", ""))
		if drop_kinds.has(kind):
			drop_kinds[kind] = int(drop_kinds[kind]) + int(drop.get("amount", 1))
	return {
		"id": MOON_BLOOM_ID,
		"center": MOON_BLOOM_CENTER,
		"positions": MOON_BLOOM_NODE_POSITIONS.duplicate(),
		"nodes": moon_bloom_nodes.duplicate(true),
		"status": moon_bloom_status,
		"timer": moon_bloom_timer,
		"completions": moon_bloom_completions,
		"mineable": bool(RunState.area_unlocked),
		"mechanic": "timed_resonance_trio",
		"time_limit": MOON_BLOOM_TIME_LIMIT,
		"respawn_seconds": MOON_BLOOM_RESPAWN_SECONDS,
		"bonus": MOON_BLOOM_BONUS.duplicate(true),
		"physical_drop_count": moon_bloom_drops.size(),
		"physical_drops": drop_kinds,
		"context": active_context,
		"context_radius": _effective_mining_range(MOON_BLOOM_NODE_CONTEXT_RADIUS),
		"effective_tool": _mountain_tool(),
		"nonblocking": true,
		"road_clearance": ROAD_RECTS.moonglass.position.y - (MOON_BLOOM_CENTER.y + 40.0),
		"platform": {
			"present": moon_bloom_platform_nodes.size() == 5,
			"node_count": moon_bloom_platform_nodes.size(),
			"top_anchor": MOON_BLOOM_PLATFORM_TOP_ANCHOR,
			"underside_anchor": MOON_BLOOM_PLATFORM_UNDERSIDE_ANCHOR,
			"access_route": PackedVector2Array(MOON_BLOOM_PLATFORM_ACCESS_ROUTE),
			"road_touchpoint": Vector2(MOON_BLOOM_PLATFORM_ACCESS_ROUTE[-1]),
			"nonblocking": true,
			"assets": [MOON_BLOOM.resource_path, ROAD_TEXTURES.moonglass.resource_path, MOON_CRYSTALS.resource_path],
		},
		"assets": [
			"res://assets/surface/moonglass-bloom-bed.png",
			"res://assets/moonglass/moonglass-node.png",
			"res://assets/surface/moonglass-ore-mountain-v1.png",
			"res://assets/surface/moonglass-ore-mountain-damaged-1.png",
			"res://assets/surface/moonglass-ore-mountain-damaged-2.png",
			"res://assets/surface/moonglass-ore-mountain-damaged-3.png",
			"res://assets/world-life/moonglass-impact.png",
			"res://assets/world-life/moonglass-response.png",
		],
	}


func ember_resource_snapshot() -> Dictionary:
	return _timed_surface_resource_snapshot(EMBER_FAULT_ID)


func starfall_resource_snapshot() -> Dictionary:
	return _timed_surface_resource_snapshot(STARFALL_LATTICE_ID)


func surface_resource_mountain_snapshot(mountain_id: String) -> Dictionary:
	if not surface_resource_mountains.has(mountain_id):
		return {}
	var entry: Dictionary = surface_resource_mountains[mountain_id]
	var root: Node2D = entry.root
	var sprite: Sprite2D = entry.sprite
	var drop_count: = 0
	for drop_value in surface_resource_mountain_drops:
		if String(Dictionary(drop_value).get("mountain_id", "")) == mountain_id:
			drop_count += 1
	var impact_count: = 0
	for impact_value in surface_resource_mountain_impacts:
		if String(Dictionary(impact_value).get("mountain_id", "")) == mountain_id:
			impact_count += 1
	return {
		"id": mountain_id,
		"position": root.position,
		"base_position": Vector2(entry.base_position),
		"rotation": root.rotation,
		"sprite_position": sprite.position,
		"sprite_scale": sprite.scale,
		"texture": String(sprite.texture.resource_path) if sprite.texture != null else "",
		"texture_size": Vector2(sprite.texture.get_size()) if sprite.texture != null else Vector2.ZERO,
		"display_size": Vector2(entry.display_size),
		"phase": int(entry.phase),
		"phase_count": 4,
		"hp": int(entry.hp),
		"max_hp": SURFACE_RESOURCE_MOUNTAIN_MAX_HP,
		"reserve": (float(entry.hp) + float(entry.growth_buffer)) / float(SURFACE_RESOURCE_MOUNTAIN_MAX_HP),
		"yield_buffer": float(entry.yield_buffer),
		"rare_ready": bool(entry.rare_ready),
		"hit_count": int(entry.hit_count),
		"hit_elapsed": float(entry.hit_elapsed),
		"collapse_elapsed": float(entry.collapse_elapsed),
		"drop_count": drop_count,
		"impact_count": impact_count,
		"collision": Dictionary(SURFACE_RESOURCE_MOUNTAIN_COLLISIONS[mountain_id]).duplicate(true),
		"hit_target": _surface_resource_mountain_hit_point(mountain_id, player.global_position),
		"mining_range": _effective_mining_range(SURFACE_RESOURCE_MOUNTAIN_MINING_RANGE),
		"mineable": _surface_resource_mountain_unlocked(mountain_id),
		"context": active_context,
		"fixed_bottom_center_anchor": true,
		"independent_from_vein": true,
	}


func _timed_surface_resource_snapshot(vein_id: String) -> Dictionary:
	if not timed_surface_veins.has(vein_id):
		return {}
	var config: = _timed_surface_config(vein_id)
	var runtime: Dictionary = timed_surface_veins[vein_id]
	var drop_kinds: = {}
	for kind_value in Dictionary(config.drop_textures).keys():
		drop_kinds[String(kind_value)] = 0
	for drop_value in Array(runtime.drops):
		var drop: Dictionary = drop_value
		var kind: = String(drop.get("kind", ""))
		if drop_kinds.has(kind):
			drop_kinds[kind] = int(drop_kinds[kind]) + int(drop.get("amount", 1))
	var active_effects: Array[String] = []
	for effect_value in Array(runtime.effects):
		active_effects.append(String(Dictionary(effect_value).get("kind", "")))
	var visual_stages: Array[String] = []
	for node_value in Array(runtime.nodes):
		visual_stages.append(_timed_surface_damage_stage(Dictionary(node_value), config))
	var assets: Array[String] = []
	if vein_id == EMBER_FAULT_ID:
		assets = [
			"res://assets/surface/emberdeep-fault-bed.png",
			"res://assets/emberdeep/emberstone-node.png",
			"res://assets/drops/emberstone-drop.png",
			"res://assets/drops/sunslag-drop.png",
			"res://assets/world-life/emberdeep-impact.png",
			"res://assets/world-life/emberdeep-response.png",
		]
	else:
		assets = [
			"res://assets/surface/starfall-lattice-bed.png",
			"res://assets/starfall/astralite-node.png",
			"res://assets/drops/astralite-drop.png",
			"res://assets/drops/crownstone-drop.png",
			"res://assets/world-life/starfall-impact.png",
			"res://assets/world-life/starfall-response.png",
		]
	return {
		"id": vein_id,
		"center": Vector2(config.center),
		"positions": Array(config.positions).duplicate(),
		"nodes": Array(runtime.nodes).duplicate(true),
		"node_max_hp": int(config.max_hp),
		"node_max_shell": int(config.max_shell),
		"status": String(runtime.status),
		"timer": float(runtime.timer),
		"completions": int(runtime.completions),
		"mineable": _timed_surface_resource_unlocked(vein_id),
		"mechanic": "armored_timed_resonance_trio",
		"reaction": String(config.reaction),
		"time_limit": float(config.time_limit),
		"respawn_seconds": float(config.respawn),
		"bonus": Dictionary(config.bonus).duplicate(true),
		"last_completion_bonus": Dictionary(runtime.last_completion_bonus).duplicate(true),
		"physical_drop_count": Array(runtime.drops).size(),
		"physical_drops": drop_kinds,
		"cargo_on_pickup_only": true,
		"mined_on_release": true,
		"context": String(config.context),
		"active_context": active_context,
		"context_radius": _effective_mining_range(TIMED_SURFACE_NODE_CONTEXT_RADIUS),
		"effective_tool": _mountain_tool(),
		"nonblocking": true,
		"health_bar": false,
		"world_explainer_text": false,
		"floating_timer_ring": false,
		"timer_visual": "authored_reaction_frames",
		"damage_visual": "authored_shell_fracture_and_residue",
		"authored_time_phase": _timed_surface_authored_time_phase(vein_id, runtime, config),
		"node_visual_stages": visual_stages,
		"line_points": _timed_surface_connection_points(vein_id),
		"active_effects": active_effects,
		"assets": assets,
	}


func starfall_hub_lift_snapshot() -> Dictionary:
	var unlocked: = RunState.is_hub_unlocked()
	return {
		"position": STARFALL_HUB_LIFT_POSITION,
		"radius": STARFALL_HUB_LIFT_RADIUS,
		"asset": "res://assets/voidstar/depth-portal.png",
		"unlocked": unlocked,
		"visible": is_instance_valid(starfall_hub_lift_sprite) and starfall_hub_lift_sprite.visible,
		"interactive": unlocked,
		"context": "hubEntrance",
		"active_context": active_context,
		"automatic_teleport": false,
		"nonblocking": true,
		"approach": "authored_side_alcove",
		"approach_asset": "res://assets/surface/starfall-mine-path.png",
		"approach_rect": STARFALL_HUB_APPROACH_RECT,
		"interaction_anchor_preserved": true,
	}


func hub_entrance_snapshot() -> Dictionary:
	return starfall_hub_lift_snapshot()


func restore_ore_mountain_state() -> void :
	var budget_trimmed_before_restore: = surface_drop_budget_trimmed
	for drop in ore_drops:
		var old_drop_sprite: Sprite2D = drop.get("sprite")
		if is_instance_valid(old_drop_sprite):
			old_drop_sprite.queue_free()
	ore_drops.clear()
	var now: = int(Time.get_unix_time_from_system())
	var reserve: = clampf(float(RunState.surface_ore_reserve), 0.0, 1.0)
	var saved_unix: = int(RunState.surface_ore_updated_unix)
	if saved_unix > 0:
		reserve = minf(1.0, reserve + float(maxi(0, now - saved_unix)) / MOSS_ORE_MOUNTAIN_REGROWTH_SECONDS)
	var exact_hp: = reserve * float(MOSS_ORE_MOUNTAIN_MAX_HP)
	ore_mountain_hp = clampi(floori(exact_hp), 0, MOSS_ORE_MOUNTAIN_MAX_HP)
	ore_mountain_growth_buffer = exact_hp - float(ore_mountain_hp)
	ore_mountain_copper_yield_buffer = clampf(float(RunState.surface_ore_yield_buffer), 0.0, 0.999999)
	ore_mountain_gold_ready = bool(RunState.surface_ore_gold_ready) or reserve >= 0.999
	ore_mountain_last_growth_unix = now
	var ground_loot: Dictionary = RunState.surface_ore_ground_loot
	for row_value in _surface_restored_drop_rows(ground_loot, ["copper", "gold"]):
		var row: Dictionary = row_value
		_spawn_ore_drop(String(row.kind), int(row.amount))
	for index in range(ore_drops.size()):
		var restored_drop: Dictionary = ore_drops[index]
		restored_drop.age = ORE_DROP_FLIGHT_DURATION
		var restored_sprite: Sprite2D = restored_drop.sprite
		restored_sprite.position = Vector2(restored_drop.landing_position)
		ore_drops[index] = restored_drop
	_update_ore_mountain_visual(reserve)
	_restore_surface_resource_mountain_states()
	_restore_moonglass_resource_state()
	_restore_timed_surface_resource_states()
	if surface_drop_budget_trimmed > budget_trimmed_before_restore:
		persist_ore_mountain_state()


func persist_ore_mountain_state() -> void :
	RunState.begin_state_batch()
	_flush_surface_passive_simulation()
	_catch_up_ore_mountain()
	var ground_loot: = {"copper": 0, "gold": 0}
	for drop in ore_drops:
		var kind: = String(drop.get("kind", ""))
		if ground_loot.has(kind):
			ground_loot[kind] = int(ground_loot[kind]) + int(drop.get("amount", 1))
	RunState.set_surface_ore_state(
		(float(ore_mountain_hp) + ore_mountain_growth_buffer) / float(MOSS_ORE_MOUNTAIN_MAX_HP),
		ore_mountain_copper_yield_buffer,
		ore_mountain_gold_ready,
		ore_mountain_last_growth_unix,
		ground_loot
	)
	_persist_surface_resource_mountain_states()
	_persist_moonglass_resource_state()
	_persist_timed_surface_resource_states()
	RunState.end_state_batch()


func _reset_surface_resource_mountains() -> void :
	for drop_value in surface_resource_mountain_drops:
		var drop_sprite: Sprite2D = Dictionary(drop_value).get("sprite")
		if is_instance_valid(drop_sprite):
			drop_sprite.queue_free()
	surface_resource_mountain_drops.clear()
	for impact_value in surface_resource_mountain_impacts:
		var impact_sprite: Sprite2D = Dictionary(impact_value).get("sprite")
		if is_instance_valid(impact_sprite):
			impact_sprite.queue_free()
	surface_resource_mountain_impacts.clear()
	var now: = int(Time.get_unix_time_from_system())
	for mountain_id_value in SURFACE_RESOURCE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		if not surface_resource_mountains.has(mountain_id):
			continue
		var entry: Dictionary = surface_resource_mountains[mountain_id]
		entry.hp = SURFACE_RESOURCE_MOUNTAIN_MAX_HP
		entry.growth_buffer = 0.0
		entry.yield_buffer = 0.0
		entry.rare_ready = true
		entry.last_growth_unix = now
		entry.hit_flash = 0.0
		entry.hit_elapsed = 0.0
		entry.collapse_elapsed = 0.0
		entry.visual_elapsed = SURFACE_DYNAMIC_VISUAL_TICK
		entry.hit_count = 0
		entry.swing_active = false
		entry.swing_elapsed = 0.0
		entry.swing_hit = false
		var root: Node2D = entry.root
		root.position = Vector2(entry.base_position)
		root.rotation = 0.0
		surface_resource_mountains[mountain_id] = entry
		_update_surface_resource_mountain_visual(mountain_id)


func _restore_surface_resource_mountain_states() -> void :
	for drop_value in surface_resource_mountain_drops:
		var old_drop_sprite: Sprite2D = Dictionary(drop_value).get("sprite")
		if is_instance_valid(old_drop_sprite):
			old_drop_sprite.queue_free()
	surface_resource_mountain_drops.clear()
	for impact_value in surface_resource_mountain_impacts:
		var old_impact_sprite: Sprite2D = Dictionary(impact_value).get("sprite")
		if is_instance_valid(old_impact_sprite):
			old_impact_sprite.queue_free()
	surface_resource_mountain_impacts.clear()
	if not RunState.has_method("surface_mountain_state"):
		_reset_surface_resource_mountains()
		return
	var now: = int(Time.get_unix_time_from_system())
	for mountain_id_value in SURFACE_RESOURCE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		if not surface_resource_mountains.has(mountain_id):
			continue
		var saved_value: Variant = RunState.call("surface_mountain_state", mountain_id)
		var saved: Dictionary = saved_value if saved_value is Dictionary else {}
		var reserve: = clampf(float(saved.get("reserve", 1.0)), 0.0, 1.0)
		var saved_unix: = maxi(0, int(saved.get("updated_unix", 0)))
		if saved_unix > 0:
			reserve = minf(
				1.0,
				reserve + float(maxi(0, now - saved_unix)) / SURFACE_RESOURCE_MOUNTAIN_REGROWTH_SECONDS
			)
		var exact_hp: = reserve * float(SURFACE_RESOURCE_MOUNTAIN_MAX_HP)
		var entry: Dictionary = surface_resource_mountains[mountain_id]
		entry.hp = clampi(floori(exact_hp), 0, SURFACE_RESOURCE_MOUNTAIN_MAX_HP)
		entry.growth_buffer = exact_hp - float(entry.hp)
		entry.yield_buffer = clampf(float(saved.get("yield_buffer", 0.0)), 0.0, 0.999999)
		entry.rare_ready = bool(saved.get("rare_ready", true)) or reserve >= 0.999
		entry.last_growth_unix = now
		entry.hit_flash = 0.0
		entry.hit_elapsed = 0.0
		entry.collapse_elapsed = 0.0
		entry.visual_elapsed = SURFACE_DYNAMIC_VISUAL_TICK
		entry.hit_count = 0
		entry.swing_active = false
		entry.swing_elapsed = 0.0
		entry.swing_hit = false
		var root: Node2D = entry.root
		root.position = Vector2(entry.base_position)
		root.rotation = 0.0
		surface_resource_mountains[mountain_id] = entry
		var config: Dictionary = SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]
		var ground_value: Variant = saved.get("ground_loot", {})
		var ground_loot: Dictionary = ground_value if ground_value is Dictionary else {}
		var kind_order: Array = [String(config.primary), String(config.rare)]
		for row_value in _surface_restored_drop_rows(ground_loot, kind_order):
			var row: Dictionary = row_value
			_spawn_surface_resource_mountain_drop(mountain_id, String(row.kind), int(row.amount))
		_update_surface_resource_mountain_visual(mountain_id)
	for index in range(surface_resource_mountain_drops.size()):
		var restored_drop: Dictionary = surface_resource_mountain_drops[index]
		restored_drop.age = ORE_DROP_FLIGHT_DURATION
		var restored_sprite: Sprite2D = restored_drop.sprite
		restored_sprite.position = Vector2(restored_drop.landing_position)
		restored_drop.settled = true
		surface_resource_mountain_drops[index] = restored_drop


func _persist_surface_resource_mountain_states() -> void :
	if not RunState.has_method("set_surface_mountain_state"):
		return
	_catch_up_surface_resource_mountains()
	for mountain_id_value in SURFACE_RESOURCE_MOUNTAIN_IDS:
		var mountain_id: = String(mountain_id_value)
		if not surface_resource_mountains.has(mountain_id):
			continue
		var entry: Dictionary = surface_resource_mountains[mountain_id]
		var config: Dictionary = SURFACE_RESOURCE_MOUNTAIN_CONFIGS[mountain_id]
		var ground_loot: = {}
		for kind_value in Dictionary(config.drop_textures).keys():
			ground_loot[String(kind_value)] = 0
		for drop_value in surface_resource_mountain_drops:
			var drop: Dictionary = drop_value
			if String(drop.get("mountain_id", "")) != mountain_id:
				continue
			var kind: = String(drop.get("kind", ""))
			if ground_loot.has(kind):
				ground_loot[kind] = int(ground_loot[kind]) + int(drop.get("amount", 1))
		RunState.call(
			"set_surface_mountain_state",
			mountain_id,
			(float(entry.hp) + float(entry.growth_buffer)) / float(SURFACE_RESOURCE_MOUNTAIN_MAX_HP),
			float(entry.yield_buffer),
			bool(entry.rare_ready),
			int(entry.last_growth_unix),
			ground_loot
		)


func _flush_surface_passive_simulation() -> void :
	var now_unix: = int(Time.get_unix_time_from_system())
	if ore_mountain_passive_elapsed > 0.0:
		_update_ore_mountain_passive(ore_mountain_passive_elapsed, now_unix)
		ore_mountain_passive_elapsed = 0.0
	if moon_bloom_passive_elapsed > 0.0:
		_update_moonglass_resource_passive(moon_bloom_passive_elapsed, now_unix)
		moon_bloom_passive_elapsed = 0.0
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		var pending: = float(timed_surface_passive_elapsed.get(vein_id, 0.0))
		if pending > 0.0:
			_update_timed_surface_resource_passive(vein_id, pending, now_unix)
			timed_surface_passive_elapsed[vein_id] = 0.0


func mobile_performance_snapshot() -> Dictionary:
	var drop_budget: = surface_loose_drop_budget_snapshot()
	return {
		"active_half_size": SURFACE_VISUAL_ACTIVE_HALF_SIZE,
		"passive_tick_hz": 1.0 / SURFACE_PASSIVE_TICK,
		"active_resource_updates": mobile_active_resource_updates,
		"passive_resource_updates": mobile_passive_resource_updates,
		"portal_ticks": mobile_portal_ticks,
		"portal_ticks_skipped": mobile_portal_ticks_skipped,
		"portal_visual_hz": WorldTransitionVisual.VISUAL_REFRESH_HZ,
		"portal_visuals_throttled": true,
		"portal_crossing_timing_unthrottled": true,
		"dynamic_visual_hz": 1.0 / SURFACE_DYNAMIC_VISUAL_TICK,
		"dynamic_visual_updates": mobile_dynamic_visual_updates,
		"dynamic_visual_updates_skipped": mobile_dynamic_visual_updates_skipped,
		"offscreen_visual_updates": false,
		"shared_unix_sample_per_frame": true,
		"moss_bank_shader_taps": 5,
		"loose_drop_live": int(drop_budget.live),
		"loose_drop_peak": int(drop_budget.peak),
		"loose_drop_source_limit": int(drop_budget.source_limit),
		"loose_drop_total_limit": int(drop_budget.total_limit),
		"loose_drop_trimmed": int(drop_budget.trimmed),
		"loose_drop_auto_collected_amount": int(drop_budget.auto_collected_amount),
	}


func _restore_moonglass_resource_state() -> void :
	for drop in moon_bloom_drops:
		var old_drop_sprite: Sprite2D = drop.get("sprite")
		if is_instance_valid(old_drop_sprite):
			old_drop_sprite.queue_free()
	moon_bloom_drops.clear()
	for effect in moon_bloom_effects:
		var old_effect_sprite: Sprite2D = effect.get("sprite")
		if is_instance_valid(old_effect_sprite):
			old_effect_sprite.queue_free()
	moon_bloom_effects.clear()
	var saved_nodes: Array = RunState.surface_moonglass_nodes
	for index in range(moon_bloom_nodes.size()):
		var node: Dictionary = moon_bloom_nodes[index]
		if index < saved_nodes.size() and saved_nodes[index] is Dictionary:
			var saved_node: Dictionary = saved_nodes[index]
			node.hp = clampi(int(saved_node.get("hp", MOON_BLOOM_NODE_MAX_HP)), 0, MOON_BLOOM_NODE_MAX_HP)
			node.respawn = clampf(float(saved_node.get("respawn", 0.0)), 0.0, MOON_BLOOM_RESPAWN_SECONDS)
		moon_bloom_nodes[index] = node
	moon_bloom_status = String(RunState.surface_moonglass_vein_status)
	moon_bloom_timer = clampf(float(RunState.surface_moonglass_vein_timer), 0.0, MOON_BLOOM_TIME_LIMIT)
	moon_bloom_completions = maxi(0, int(RunState.surface_moonglass_completions))
	var now: = int(Time.get_unix_time_from_system())
	var saved_unix: = int(RunState.surface_moonglass_updated_unix)
	if saved_unix > 0:
		_advance_moonglass_bloom(float(maxi(0, now - saved_unix)))
	moon_bloom_updated_unix = now
	moon_bloom_target_index = -1
	var ground_loot: Dictionary = RunState.surface_moonglass_ground_loot
	var restored_piece: = 0
	for row_value in _surface_restored_drop_rows(ground_loot, ["moonglass", "starshard"]):
		var row: Dictionary = row_value
		_spawn_moonglass_drop(String(row.kind), int(row.amount), restored_piece, MOON_BLOOM_CENTER)
		restored_piece += 1
	for index in range(moon_bloom_drops.size()):
		var restored_drop: Dictionary = moon_bloom_drops[index]
		restored_drop.age = ORE_DROP_FLIGHT_DURATION
		var restored_sprite: Sprite2D = restored_drop.sprite
		restored_sprite.position = Vector2(restored_drop.landing_position)
		moon_bloom_drops[index] = restored_drop
	_update_moonglass_visual()


func _persist_moonglass_resource_state() -> void :
	_catch_up_moonglass_resource()
	var ground_loot: = {"moonglass": 0, "starshard": 0}
	for drop in moon_bloom_drops:
		var kind: = String(drop.get("kind", ""))
		if ground_loot.has(kind):
			ground_loot[kind] = int(ground_loot[kind]) + int(drop.get("amount", 1))
	var saved_nodes: Array = []
	for node in moon_bloom_nodes:
		saved_nodes.append({
			"hp": int(Dictionary(node).hp),
			"respawn": float(Dictionary(node).respawn),
		})
	RunState.set_surface_moonglass_state(
		saved_nodes,
		moon_bloom_status,
		moon_bloom_timer,
		moon_bloom_completions,
		moon_bloom_updated_unix,
		ground_loot
	)


func _restore_timed_surface_resource_states() -> void :
	if not RunState.has_method("surface_vein_state"):
		return
	var now: = int(Time.get_unix_time_from_system())
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		if not timed_surface_veins.has(vein_id):
			continue
		var config: = _timed_surface_config(vein_id)
		var runtime: Dictionary = timed_surface_veins[vein_id]
		for drop_value in Array(runtime.drops):
			var old_drop_sprite: Sprite2D = Dictionary(drop_value).get("sprite")
			if is_instance_valid(old_drop_sprite):
				old_drop_sprite.queue_free()
		for effect_value in Array(runtime.effects):
			var old_effect_sprite: Sprite2D = Dictionary(effect_value).get("sprite")
			if is_instance_valid(old_effect_sprite):
				old_effect_sprite.queue_free()
		runtime.drops = []
		runtime.effects = []
		var saved_value: Variant = RunState.call("surface_vein_state", vein_id)
		var saved: Dictionary = saved_value if saved_value is Dictionary else {}
		var saved_nodes: Array = Array(saved.get("nodes", []))
		var nodes: Array = runtime.nodes
		for index in range(nodes.size()):
			var node: Dictionary = nodes[index]
			if index < saved_nodes.size() and saved_nodes[index] is Dictionary:
				var saved_node: Dictionary = saved_nodes[index]
				node.hp = clampi(int(saved_node.get("hp", config.max_hp)), 0, int(config.max_hp))
				var default_shell: = 0 if int(node.hp) <= 0 else int(config.max_shell)
				node.shell = clampi(
					int(saved_node.get("shell", default_shell)),
					0,
					int(config.max_shell)
				)
				node.respawn = clampf(
					float(saved_node.get("respawn", 0.0)),
					0.0,
					float(config.respawn)
				)
			node.position = Vector2(Array(config.positions)[index])
			nodes[index] = node
		runtime.nodes = nodes
		runtime.status = String(saved.get("status", "idle"))
		runtime.timer = clampf(float(saved.get("timer", 0.0)), 0.0, float(config.time_limit))
		runtime.completions = maxi(0, int(saved.get("completions", 0)))
		runtime.updated_unix = maxi(0, int(saved.get("updated_unix", 0)))
		runtime.swing_active = false
		runtime.swing_elapsed = 0.0
		runtime.swing_hit = false
		runtime.target_index = -1
		runtime.visual_elapsed = SURFACE_DYNAMIC_VISUAL_TICK
		runtime.last_completion_bonus = {}
		timed_surface_veins[vein_id] = runtime
		var saved_unix: = int(runtime.updated_unix)
		if saved_unix > 0:
			_advance_timed_surface_resource(vein_id, float(maxi(0, now - saved_unix)))
		runtime = timed_surface_veins[vein_id]
		runtime.updated_unix = now
		timed_surface_veins[vein_id] = runtime
		var ground_value: Variant = saved.get("ground_loot", {})
		var ground_loot: Dictionary = ground_value if ground_value is Dictionary else {}
		var restored_piece: = 0
		var kind_order: Array = [String(config.resource)]
		for kind_value in Dictionary(config.drop_textures).keys():
			if not kind_order.has(String(kind_value)):
				kind_order.append(String(kind_value))
		for row_value in _surface_restored_drop_rows(ground_loot, kind_order):
			var row: Dictionary = row_value
			_spawn_timed_surface_drop(
				vein_id,
				String(row.kind),
				int(row.amount),
				restored_piece,
				Vector2(config.center)
			)
			restored_piece += 1
		runtime = timed_surface_veins[vein_id]
		var drops: Array = runtime.drops
		for index in range(drops.size()):
			var restored_drop: Dictionary = drops[index]
			restored_drop.age = ORE_DROP_FLIGHT_DURATION
			var restored_sprite: Sprite2D = restored_drop.sprite
			restored_sprite.position = Vector2(restored_drop.landing_position)
			drops[index] = restored_drop
		runtime.drops = drops
		timed_surface_veins[vein_id] = runtime
		_update_timed_surface_visual(vein_id)


func _persist_timed_surface_resource_states() -> void :
	if not RunState.has_method("set_surface_vein_state"):
		return
	_catch_up_timed_surface_resources()
	for vein_id_value in [EMBER_FAULT_ID, STARFALL_LATTICE_ID]:
		var vein_id: = String(vein_id_value)
		if not timed_surface_veins.has(vein_id):
			continue
		var config: = _timed_surface_config(vein_id)
		var runtime: Dictionary = timed_surface_veins[vein_id]
		var ground_loot: = {}
		for kind_value in Dictionary(config.drop_textures).keys():
			ground_loot[String(kind_value)] = 0
		for drop_value in Array(runtime.drops):
			var drop: Dictionary = drop_value
			var kind: = String(drop.get("kind", ""))
			if ground_loot.has(kind):
				ground_loot[kind] = int(ground_loot[kind]) + int(drop.get("amount", 1))
		var saved_nodes: Array = []
		for node_value in Array(runtime.nodes):
			var node: Dictionary = node_value
			saved_nodes.append({
				"hp": int(node.hp),
				"shell": int(node.shell),
				"respawn": float(node.respawn),
			})
		RunState.call(
			"set_surface_vein_state",
			vein_id,
			saved_nodes,
			String(runtime.status),
			float(runtime.timer),
			int(runtime.completions),
			int(runtime.updated_unix),
			ground_loot
		)


func _create_authored_arch(anchor: Vector2, gate_id: String) -> Dictionary:
	var textures: Dictionary = {"moonglass": preload("res://assets/surface/v2/moonglass-port.png"), "emberdeep": preload("res://assets/surface/v3/ember-port.png"), "starfall": preload("res://assets/surface/v3/star-port.png")}
	var texture: Texture2D = textures[gate_id]
	var rect: = Rect2(anchor + Vector2(-180, -291), Vector2(360, 360))
	var back: = _create_sprite(texture, rect, 7)
	back.name = "MoonglassArchRear"
	var front: = _create_sprite(texture, rect, 12)
	front.name = "MoonglassArchFront"
	for sprite in [back, front]:
		var material: = ShaderMaterial.new()
		material.shader = preload("res://shaders/surface_arch_depth.gdshader")
		material.set_shader_parameter("front_layer", sprite == front)
		sprite.material = material
	return {"sprite": back, "front": front, "rect": rect, "authored_arch": true}


func _companion_surface_drop(candidate: Dictionary) -> Dictionary:
	var index: int=int(candidate.index)
	match String(candidate.bucket):
		"ore": return ore_drops[index]
		"moonglass": return moon_bloom_drops[index]
		"surface_mountain": return surface_resource_mountain_drops[index]
		"timed_vein": return timed_surface_veins[String(candidate.owner)].drops[index]
		"chest": return chest_loot_drops[index]
	return {}

func companion_loot_candidates() -> Array[Dictionary]:
	var result: Array[Dictionary]=[]
	for candidate in _surface_drop_budget_candidates():
		var drop: Dictionary=_companion_surface_drop(candidate)
		if bool(drop.get("collecting",false)): continue
		var point: Vector2=Vector2(drop.get("position",Vector2(INF,INF)))
		var sprite: Sprite2D=drop.get("sprite")
		if is_instance_valid(sprite): point=sprite.global_position
		result.append({"id":str(candidate.serial),"position":point,"age":candidate.age})
	return result

func companion_collect_loot(origin: Vector2, radius: float) -> int:
	var count: int=0
	var candidates: Array[Dictionary]=_surface_drop_budget_candidates()
	candidates.reverse()
	for candidate in candidates:
		var drop: Dictionary=_companion_surface_drop(candidate)
		if bool(drop.get("collecting",false)) or float(drop.get("age",0.0))<0.65: continue
		var sprite: Sprite2D=drop.get("sprite")
		var point: Vector2=sprite.global_position if is_instance_valid(sprite) else Vector2(drop.get("position",Vector2(INF,INF)))
		if origin.distance_to(point)>radius: continue
		var amount: int=int(drop.get("amount",1))
		if _trim_surface_drop_candidate(candidate):
			count+=amount
			AudioDirector.play_pickup(String(drop.kind),amount)
	return count

func companion_ore_target(origin: Vector2) -> Vector2:
	var best: Vector2=_ore_mountain_hit_point(origin)
	var distance: float=minf(650.0,best.distance_to(origin))
	if best.distance_to(origin)>650.0: best=Vector2(INF,INF)
	for id in SURFACE_RESOURCE_MOUNTAIN_IDS:
		if not _surface_resource_mountain_unlocked(id): continue
		var point: Vector2=_surface_resource_mountain_hit_point(id,origin)
		if point.distance_to(origin)<distance:
			best=point
			distance=point.distance_to(origin)
	return best


func _build_later_backdrops() -> void:
	for spec in [
		[preload("res://assets/surface/v3/ember-backdrop.png"),2820.0,2110.0,3470.0,false],
		[preload("res://assets/surface/v3/star-backdrop.png"),3910.0,3290.0,4620.0,true],
	]:
		var backdrop: Sprite2D=_create_sprite(spec[0],Rect2(float(spec[1])-1200.0,-180.0,2400.0,1600.0),0)
		var material: ShaderMaterial=ShaderMaterial.new()
		material.shader=preload("res://shaders/biome_backdrop.gdshader")
		material.set_shader_parameter("left_edge",float(spec[2]))
		material.set_shader_parameter("right_edge",float(spec[3]))
		material.set_shader_parameter("last_biome",bool(spec[4]))
		backdrop.material=material
