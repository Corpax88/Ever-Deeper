class_name WorldCatalog
extends RefCounted





const WORLD_ORDER: = ["mossvein", "moonglass", "emberdeep", "starfall"]
const MINE_ORDER: = ["mossMine", "moonMine", "emberMine", "starMine"]
const ROAD_CROSSFADE_WIDTH: = 80.0
const GROUND_BLEND_WIDTH: = 24.0
const GATE_TRANSITION_DURATION: = 2.4

const MINE_BY_WORLD: = {
	"mossvein": "mossMine", 
	"moonglass": "moonMine", 
	"emberdeep": "emberMine", 
	"starfall": "starMine", 
}

const WORLD_BY_MINE: = {
	"mossMine": "mossvein", 
	"moonMine": "moonglass", 
	"emberMine": "emberdeep", 
	"starMine": "starfall", 
}




const SURFACE_LAYOUTS: = {
	"mossvein": {
		"ground_asset": "res://assets/surface/mossvein-ground.png", 
		"road_asset": "res://assets/surface/road-mossvein.png", 
		"road_rect": {"x": -40.0, "y": 550.0, "w": 1190.0, "h": 220.0}, 
		"road_flip_x": false, 
		"entrance_asset": "res://assets/entrances/mossvein-entrance.png", 
		"entrance_flip_x": false, 
		"approach": {
			"asset": "res://assets/surface/mossvein-camp-path.png", 
			"rect": {"x": 700.0, "y": 680.0, "w": 175.0, "h": 360.0}, 
			"flip_x": false, 
			"rotation": -0.045, 
			"draw_layer": "under_road", 
		}, 
		"decorations": [], 
		"features": [], 
		"ambient_asset": "res://assets/ambient/mossvein-glowmoth.png", 
		"world_life": {
			"drift": "res://assets/world-life/mossvein-drift.png", 
			"response": "res://assets/world-life/mossvein-response.png", 
			"impact": "res://assets/world-life/mossvein-impact.png", 
		}, 
		"surface_vein_id": "copper_run", 
	}, 
	"moonglass": {
		"ground_asset": "res://assets/surface/moonglass-ground.png", 
		"road_asset": "res://assets/surface/road-moonglass.png", 
		"road_rect": {"x": 1070.0, "y": 590.0, "w": 1190.0, "h": 300.0}, 
		"road_flip_x": true, 
		"entrance_asset": "res://assets/entrances/moonglass-entrance.png", 
		"entrance_flip_x": false, 
		"approach": {}, 
		"decorations": [
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 1185.0, "y": 220.0, "w": 112.0, "h": 48.0, "flip_x": false, "alpha": 0.48}, 
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 1435.0, "y": 185.0, "w": 118.0, "h": 50.0, "flip_x": true, "alpha": 0.5}, 
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 1775.0, "y": 210.0, "w": 122.0, "h": 52.0, "flip_x": false, "alpha": 0.46}, 
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 2110.0, "y": 330.0, "w": 114.0, "h": 48.0, "flip_x": true, "alpha": 0.48}, 
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 1415.0, "y": 1235.0, "w": 118.0, "h": 50.0, "flip_x": true, "alpha": 0.44}, 
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 1885.0, "y": 1170.0, "w": 124.0, "h": 52.0, "flip_x": false, "alpha": 0.46}, 
			{"asset": "res://assets/surface/moonglass-crystals.png", "x": 2160.0, "y": 930.0, "w": 112.0, "h": 48.0, "flip_x": false, "alpha": 0.44}, 
		], 
		"features": [
			{"id": "moonglass_bloom_bed", "asset": "res://assets/surface/moonglass-bloom-bed.png", "x": 1665.0, "y": 572.0, "w": 286.0, "h": 126.0, "alpha": 0.96, "draw_layer": "over_road"}, 
		], 
		"ambient_asset": "res://assets/ambient/moonglass-prism-moth.png", 
		"world_life": {
			"drift": "res://assets/world-life/moonglass-drift.png", 
			"response": "res://assets/world-life/moonglass-response.png", 
			"impact": "res://assets/world-life/moonglass-impact.png", 
		}, 
		"surface_vein_id": "moonglass_bloom", 
	}, 
	"emberdeep": {
		"ground_asset": "res://assets/surface/emberdeep-ground.png", 
		"road_asset": "res://assets/surface/road-emberdeep.png", 
		"road_rect": {"x": 2200.0, "y": 590.0, "w": 1190.0, "h": 300.0}, 
		"road_flip_x": false, 
		"entrance_asset": "res://assets/entrances/emberdeep-entrance.png", 
		"entrance_flip_x": true, 
		"approach": {
			"asset": "res://assets/surface/emberdeep-mine-path.png", 
			"rect": {"x": 2456.0, "y": 772.0, "w": 500.0, "h": 222.0}, 
			"flip_x": true, 
			"rotation": -0.105, 
			"pivot": {"x": 2956.0, "y": 809.0}, 
			"mouth_target": {"x": 2480.0, "y": 1015.0}, 
			"draw_layer": "under_road", 
		}, 
		"decorations": [
			{"asset": "res://assets/surface/emberdeep-slag-clusters.png", "x": 2325.0, "y": 230.0, "w": 118.0, "h": 58.0, "flip_x": false, "alpha": 0.45}, 
			{"asset": "res://assets/surface/emberdeep-slag-clusters.png", "x": 2670.0, "y": 185.0, "w": 126.0, "h": 62.0, "flip_x": true, "alpha": 0.48}, 
			{"asset": "res://assets/surface/emberdeep-slag-clusters.png", "x": 3015.0, "y": 290.0, "w": 120.0, "h": 60.0, "flip_x": false, "alpha": 0.43}, 
			{"asset": "res://assets/surface/emberdeep-slag-clusters.png", "x": 3270.0, "y": 515.0, "w": 132.0, "h": 64.0, "flip_x": true, "alpha": 0.46}, 
			{"asset": "res://assets/surface/emberdeep-slag-clusters.png", "x": 2350.0, "y": 1190.0, "w": 124.0, "h": 62.0, "flip_x": true, "alpha": 0.42}, 
			{"asset": "res://assets/surface/emberdeep-slag-clusters.png", "x": 3120.0, "y": 1180.0, "w": 130.0, "h": 64.0, "flip_x": false, "alpha": 0.44}, 
		], 
		"features": [
			{"id": "ember_fault_bed", "asset": "res://assets/surface/emberdeep-fault-bed.png", "x": 3078.0, "y": 1015.0, "w": 350.0, "h": 154.0, "alpha": 0.98, "draw_layer": "over_road"}, 
		], 
		"ambient_asset": "res://assets/ambient/emberdeep-cinder-skink.png", 
		"world_life": {
			"drift": "res://assets/world-life/emberdeep-drift.png", 
			"response": "res://assets/world-life/emberdeep-response.png", 
			"impact": "res://assets/world-life/emberdeep-impact.png", 
		}, 
		"surface_vein_id": "ember_fault", 
	}, 
	"starfall": {
		"ground_asset": "res://assets/surface/starfall-ground.png", 
		"road_asset": "res://assets/surface/road-starfall.png", 
		"road_rect": {"x": 3320.0, "y": 590.0, "w": 1190.0, "h": 300.0}, 
		"road_flip_x": true, 
		"entrance_asset": "res://assets/entrances/starfall-entrance.png", 
		"entrance_flip_x": false, 
		"approach": {
			"asset": "res://assets/surface/starfall-mine-path.png", 
			"rect": {"x": 3450.0, "y": 760.0, "w": 650.0, "h": 289.0}, 
			"flip_x": false, 
			"rotation": 0.0, 
			"mouth_target": {"x": 3505.0, "y": 1000.0}, 
			"draw_layer": "under_road", 
		}, 
		"decorations": [
			{"asset": "res://assets/surface/starfall-shard-clusters.png", "x": 3415.0, "y": 210.0, "w": 122.0, "h": 62.0, "flip_x": false, "alpha": 0.48}, 
			{"asset": "res://assets/surface/starfall-shard-clusters.png", "x": 3650.0, "y": 180.0, "w": 132.0, "h": 66.0, "flip_x": true, "alpha": 0.5}, 
			{"asset": "res://assets/surface/starfall-shard-clusters.png", "x": 3980.0, "y": 280.0, "w": 126.0, "h": 63.0, "flip_x": false, "alpha": 0.46}, 
			{"asset": "res://assets/surface/starfall-shard-clusters.png", "x": 4325.0, "y": 510.0, "w": 136.0, "h": 68.0, "flip_x": true, "alpha": 0.48}, 
			{"asset": "res://assets/surface/starfall-shard-clusters.png", "x": 3480.0, "y": 1190.0, "w": 124.0, "h": 62.0, "flip_x": true, "alpha": 0.44}, 
			{"asset": "res://assets/surface/starfall-shard-clusters.png", "x": 4230.0, "y": 1170.0, "w": 134.0, "h": 67.0, "flip_x": false, "alpha": 0.46}, 
		], 
		"features": [
			{"id": "starfall_lattice_bed", "asset": "res://assets/surface/starfall-lattice-bed.png", "x": 3810.0, "y": 1038.0, "w": 568.0, "h": 249.0, "alpha": 0.98, "draw_layer": "under_road"}, 
		], 
		"ambient_asset": "res://assets/ambient/starfall-astral-ray.png", 
		"world_life": {
			"drift": "res://assets/world-life/starfall-drift.png", 
			"response": "res://assets/world-life/starfall-response.png", 
			"impact": "res://assets/world-life/starfall-impact.png", 
		}, 
		"surface_vein_id": "starfall_lattice", 
		"station_assets": {
			"starforge": "res://assets/surface/starforge-station.png", 
		}, 
	}, 
}



const ENTRY_GATES: = {
	"moonglass": {
		"context_id": "gate", 
		"station_id": "gate", 
		"unlock_key": "areaUnlocked", 
		"discovery_key": "discoveredSecond", 
		"label": "MOONGLASS GATE", 
		"title": "Moonglass Cavern", 
		"min_pickaxe_level": 3, 
		"min_ember_mastery": 0, 
		"gold_cost_key": "GATE_COST", 
		"gate_asset": "res://assets/surface/moonglass-gate.png", 
		"mark_asset": "res://assets/surface/moonglass-gate-mark.png", 
		"boundary_asset": "res://assets/surface/boundary-mossvein-moonglass.png", 
	}, 
	"emberdeep": {
		"context_id": "emberGate", 
		"station_id": "emberGate", 
		"unlock_key": "emberdeepUnlocked", 
		"discovery_key": "discoveredThird", 
		"label": "EMBERDEEP SEAL", 
		"title": "Emberdeep Foundry", 
		"min_pickaxe_level": 4, 
		"min_ember_mastery": 0, 
		"gold_cost_key": "EMBER_GATE_COST", 
		"gate_asset": "res://assets/surface/emberdeep-seal.png", 
		"mark_asset": "res://assets/surface/emberdeep-seal-mark.png", 
		"boundary_asset": "res://assets/surface/boundary-moonglass-emberdeep.png", 
	}, 
	"starfall": {
		"context_id": "starfallGate", 
		"station_id": "starfallGate", 
		"unlock_key": "fourthUnlocked", 
		"discovery_key": "discoveredFourth", 
		"label": "STARFALL MASTER SEAL", 
		"title": "Starfall Depths", 
		"min_pickaxe_level": 0, 
		"min_ember_mastery": 5, 
		"gold_cost_key": "", 
		"gate_asset": "res://assets/surface/starfall-seal.png", 
		"mark_asset": "res://assets/surface/starfall-seal-mark.png", 
		"boundary_asset": "res://assets/surface/boundary-emberdeep-starfall.png", 
	}, 
}




const DRILL_GATED_RESOURCES: = {
	"mossMine": {"type": "burrowsteel", "requires_drill_level": 1, "vein_count": 4}, 
	"moonMine": {"type": "phasecrystal", "requires_drill_level": 2, "vein_count": 4}, 
	"emberMine": {"type": "infernium", "requires_drill_level": 2, "vein_count": 4}, 
	"starMine": {}, 
}


const MINE_ASSETS: = {
	"mossvein": {
		"depth1": {
			"floor": "res://assets/mossvein/cave-floor.png", 
			"wall": "res://assets/mossvein/cave-edge-loop-v1.png", 
			"corner": "res://assets/mossvein/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png", 
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"pocket": "res://assets/mossvein/magic-crystal-pocket.png", 
			"cache": "res://assets/mossvein/buried-cache.png", 
			"shrine": "res://assets/mossvein/mining-rush-shrine.png", 
			"nodes": {
				"stone": "res://assets/minerals/stone-node.png", 
				"copper": "res://assets/minerals/copper-node.png", 
				"gold": "res://assets/minerals/gold-node.png", 
			}, 
			"wall_hints": {
				"copper": "res://assets/minerals/copper-wall.png", 
				"gold": "res://assets/minerals/gold-wall.png", 
			}, 
			"barriers": {
				"outer_rubble": "res://assets/mossvein/outer-rubble-barrier-v1.png", 
				"iron_seam": "res://assets/mossvein/ironbound-collapse-barrier-v1.png", 
			}, 
		}, 
		"depth2": {
			"floor": "res://assets/rootwound/floor.png", 
			"wall": "res://assets/rootwound/cave-edge-loop-v1.png", 
			"corner": "res://assets/rootwound/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png",
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"portal": "res://assets/rootwound/depth-shaft.png", 
			"sell_station": "res://assets/rootwound/sell-station.png", 
			"drill_forge": "res://assets/rootwound/drill-forge.png", 
			"nodes": {
				"rootiron": "res://assets/rootwound/rootiron-node.png", 
				"deepstone": "res://assets/rootwound/deepstone-node.png", 
				"ambercore": "res://assets/rootwound/ambercore-node.png", 
				"burrowsteel": "res://assets/rootwound/burrowsteel-node.png", 
			}, 
			"wall_hints": {
				"rootiron": "res://assets/rootwound/rootiron-wall.png", 
			}, 
		}, 
	}, 
	"moonglass": {
		"depth1": {
			"floor": "res://assets/moonglass/floor.png", 
			"wall": "res://assets/moonglass/cave-edge-loop-v1.png", 
			"corner": "res://assets/moonglass/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png", 
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"route_marker": "res://assets/moonglass/route-marker.png", 
			"pocket": "res://assets/moonglass/crystal-pocket.png", 
			"cache": "res://assets/moonglass/buried-cache.png", 
			"shrine": "res://assets/moonglass/mining-rush-shrine.png", 
			"nodes": {
				"copper": "res://assets/minerals/copper-node.png", 
				"moonglass": "res://assets/moonglass/moonglass-node.png", 
				"starshard": "res://assets/moonglass/starshard-node.png", 
			}, 
			"wall_hints": {
				"copper": "res://assets/minerals/copper-wall.png", 
				"moonglass": "res://assets/moonglass/moonglass-wall.png", 
				"starshard": "res://assets/moonglass/starshard-wall.png", 
			}, 
			"barriers": {
				"moon_prism_gate": "res://assets/moonglass/prismatic-fault-barrier-v2.png", 
				"moon_star_lock": "res://assets/moonglass/starbound-geode-barrier-v2.png", 
			}, 
		}, 
		"depth2": {
			"floor": "res://assets/prismatic/floor.png", 
			"wall": "res://assets/prismatic/cave-edge-loop-v1.png", 
			"corner": "res://assets/prismatic/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png",
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"portal": "res://assets/prismatic/depth-portal.png", 
			"sell_station": "res://assets/prismatic/sell-station.png", 
			"drill_forge": "res://assets/prismatic/drill-forge.png", 
			"pocket": "res://assets/prismatic/crystal-pocket.png", 
			"cache": "res://assets/prismatic/buried-cache.png", 
			"shrine": "res://assets/prismatic/mining-rush-shrine.png", 
			"nodes": {
				"prismite": "res://assets/prismatic/prismite-node.png", 
				"deepstone": "res://assets/prismatic/deepstone-wall.png", 
				"lunacore": "res://assets/prismatic/lunacore-node.png", 
				"phasecrystal": "res://assets/prismatic/phasecrystal-node.png", 
			}, 
			"wall_hints": {
				"prismite": "res://assets/prismatic/prismite-wall.png", 
				"deepstone": "res://assets/prismatic/deepstone-wall.png", 
				"lunacore": "res://assets/prismatic/lunacore-wall.png", 
				"phasecrystal": "res://assets/prismatic/phasecrystal-wall.png", 
			}, 
		}, 
	}, 
	"emberdeep": {
		"depth1": {
			"floor": "res://assets/emberdeep/floor.png", 
			"wall": "res://assets/emberdeep/cave-edge-loop-v1.png", 
			"corner": "res://assets/emberdeep/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png", 
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"route_marker": "res://assets/emberdeep/route-marker.png", 
			"pocket": "res://assets/emberdeep/crystal-pocket.png", 
			"cache": "res://assets/emberdeep/buried-cache.png", 
			"shrine": "res://assets/emberdeep/mining-rush-shrine.png", 
			"nodes": {
				"moonglass": "res://assets/moonglass/moonglass-node.png", 
				"emberstone": "res://assets/emberdeep/emberstone-node.png", 
				"sunslag": "res://assets/emberdeep/sunslag-node.png", 
			}, 
			"wall_hints": {
				"moonglass": "res://assets/moonglass/moonglass-wall.png", 
				"emberstone": "res://assets/emberdeep/emberstone-wall.png", 
				"sunslag": "res://assets/emberdeep/sunslag-wall.png", 
			}, 
			"barriers": {
				"ember_bulkhead": "res://assets/emberdeep/cinder-bulkhead-barrier-v2.png", 
				"ember_crucible_lock": "res://assets/emberdeep/crucible-seal-barrier-v2.png", 
			}, 
		}, 
		"depth2": {
			"floor": "res://assets/molten/floor.png", 
			"wall": "res://assets/molten/cave-edge-loop-v1.png", 
			"corner": "res://assets/molten/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png",
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"portal": "res://assets/molten/depth-portal.png", 
			"sell_station": "res://assets/molten/sell-station.png", 
			"drill_forge": "res://assets/molten/drill-forge.png", 
			"pocket": "res://assets/molten/crystal-pocket.png", 
			"cache": "res://assets/molten/buried-cache.png", 
			"shrine": "res://assets/molten/mining-rush-shrine.png", 
			"nodes": {
				"magmaite": "res://assets/molten/magmaite-node.png", 
				"deepstone": "res://assets/molten/deepstone-node.png", 
				"furnaceheart": "res://assets/molten/furnaceheart-node.png", 
				"infernium": "res://assets/molten/infernium-node.png", 
			}, 
			"wall_hints": {
				"magmaite": "res://assets/molten/magmaite-wall.png", 
				"deepstone": "res://assets/molten/deepstone-wall.png", 
				"furnaceheart": "res://assets/molten/furnaceheart-wall.png", 
				"infernium": "res://assets/molten/infernium-wall.png", 
			}, 
		}, 
	}, 
	"starfall": {
		"depth1": {
			"floor": "res://assets/starfall/floor.png", 
			"wall": "res://assets/starfall/cave-edge-loop-v1.png", 
			"corner": "res://assets/starfall/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png", 
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"route_marker": "res://assets/starfall/route-marker.png", 
			"pocket": "res://assets/starfall/crystal-pocket.png", 
			"cache": "res://assets/starfall/buried-cache.png", 
			"shrine": "res://assets/starfall/mining-rush-shrine.png", 
			"nodes": {
				"emberstone": "res://assets/emberdeep/emberstone-node.png", 
				"astralite": "res://assets/starfall/astralite-node.png", 
				"crownstone": "res://assets/starfall/crownstone-node.png", 
			}, 
			"wall_hints": {
				"emberstone": "res://assets/emberdeep/emberstone-wall.png", 
				"astralite": "res://assets/starfall/astralite-wall.png", 
				"crownstone": "res://assets/starfall/crownstone-wall.png", 
			}, 
			"barriers": {
				"star_bridge_lock": "res://assets/starfall/astral-bridge-lock-barrier-v2.png", 
				"star_crown_lock": "res://assets/starfall/crownstone-ward-barrier-v2.png", 
			}, 
		}, 
		"depth2": {
			"floor": "res://assets/voidstar/floor.png", 
			"wall": "res://assets/voidstar/cave-edge-loop-v1.png", 
			"corner": "res://assets/voidstar/cave-corner-v1.png",
			"unbreakable_wall": "res://assets/caves/ancient-bedrock-edge-loop-v1.png",
			"unbreakable_corner": "res://assets/caves/ancient-bedrock-corner-v1.png",
			"portal": "res://assets/voidstar/depth-portal.png", 
			"sell_station": "res://assets/voidstar/sell-station.png", 
			"drill_forge": "res://assets/voidstar/drill-forge.png", 
			"pocket": "res://assets/voidstar/crystal-pocket.png", 
			"cache": "res://assets/voidstar/buried-cache.png", 
			"shrine": "res://assets/voidstar/mining-rush-shrine.png", 
			"nodes": {
				"voidglass": "res://assets/voidstar/voidglass-node.png", 
				"deepstone": "res://assets/voidstar/deepstone-node.png", 
				"singularity": "res://assets/voidstar/singularity-node.png", 
			}, 
			"wall_hints": {
				"voidglass": "res://assets/voidstar/voidglass-wall.png", 
				"deepstone": "res://assets/voidstar/deepstone-wall.png", 
				"singularity": "res://assets/voidstar/singularity-wall.png", 
			}, 
		}, 
	}, 
}

const CHEST_ASSETS: = {
	"moss_supply": {"closed": "res://assets/surface/treasure-cache-closed.png", "open": "res://assets/surface/treasure-cache-open.png"}, 
	"moss_ironbound": {"closed": "res://assets/surface/treasure-cache-closed.png", "open": "res://assets/surface/treasure-cache-open.png"}, 
	"moon_cache": {"closed": "res://assets/surface/crystal-cache-closed.png", "open": "res://assets/surface/crystal-cache-open.png"}, 
	"moon_reliquary": {"closed": "res://assets/surface/moonglass-reliquary-closed.png", "open": "res://assets/surface/moonglass-reliquary-open.png"}, 
	"ember_cache": {"closed": "res://assets/surface/foundry-lockbox-closed.png", "open": "res://assets/surface/foundry-lockbox-open.png"}, 
	"ember_vault": {"closed": "res://assets/surface/ember-vault-closed.png", "open": "res://assets/surface/ember-vault-open.png"}, 
	"star_cache": {"closed": "res://assets/surface/astral-cache-closed.png", "open": "res://assets/surface/astral-cache-open.png"}, 
	"star_coffer": {"closed": "res://assets/surface/celestial-coffer-closed.png", "open": "res://assets/surface/celestial-coffer-open.png"}, 
}

var _source: Dictionary


func _init(source_data: Dictionary) -> void :
	_source = source_data
	_validate_source_contract()


func ids() -> Array:
	return WORLD_ORDER.duplicate()


func mine_ids() -> Array:
	return MINE_ORDER.duplicate()


func first_world_id() -> String:
	return String(WORLD_ORDER[0])


func next_world_id(world_id: String) -> String:
	var index: = WORLD_ORDER.find(world_id)
	assert (index >= 0, "Unknown world: %s" % world_id)
	return "" if index >= WORLD_ORDER.size() - 1 else String(WORLD_ORDER[index + 1])


func previous_world_id(world_id: String) -> String:
	var index: = WORLD_ORDER.find(world_id)
	assert (index >= 0, "Unknown world: %s" % world_id)
	return "" if index == 0 else String(WORLD_ORDER[index - 1])


func mine_id_for_world(world_id: String) -> String:
	assert (MINE_BY_WORLD.has(world_id), "Unknown world: %s" % world_id)
	return String(MINE_BY_WORLD[world_id])


func world_id_for_mine(mine_id: String) -> String:
	assert (WORLD_BY_MINE.has(mine_id), "Unknown mine: %s" % mine_id)
	return String(WORLD_BY_MINE[mine_id])


func world_at_surface_x(surface_x: float) -> String:

	if surface_x >= float(_source["WORLD"]["starfallGateX"]):
		return "starfall"
	if surface_x >= float(_source["WORLD"]["emberGateX"]):
		return "emberdeep"
	if surface_x >= float(_source["WORLD"]["gateX"]):
		return "moonglass"
	return "mossvein"


func all_worlds() -> Array:
	var result: Array = []
	for world_id in WORLD_ORDER:
		result.append(world(String(world_id)))
	return result


func world(world_id: String) -> Dictionary:
	assert (MINE_BY_WORLD.has(world_id), "Unknown world: %s" % world_id)
	var index: = WORLD_ORDER.find(world_id)
	var mine_id: = mine_id_for_world(world_id)
	var biome: = Dictionary(_source["BIOMES"][index]).duplicate(true)
	var mine: = Dictionary(_source["MINE_DEFINITIONS"][mine_id]).duplicate(true)
	var surface: = Dictionary(SURFACE_LAYOUTS[world_id]).duplicate(true)
	surface["span"] = {"start": float(biome["start"]), "end": float(biome["end"])}
	surface["ground_blend_width"] = GROUND_BLEND_WIDTH
	surface["road_crossfade_width"] = ROAD_CROSSFADE_WIDTH
	var entry_gate: = _entry_gate(world_id)
	var chests: = _chests_for_world(world_id)
	return {
		"index": index, 
		"id": world_id, 
		"previous_id": previous_world_id(world_id), 
		"next_id": next_world_id(world_id), 
		"biome": biome, 
		"mine_id": mine_id, 
		"mine": mine, 
		"surface": surface, 
		"entry_gate": entry_gate, 
		"depth2_profile": Dictionary(_source["MINE_DEPTH_PROFILES"][mine_id]).duplicate(true), 
		"resources": {
			"depth1": Dictionary(_source["MINE_DISCOVERY_PROFILES"][mine_id]).duplicate(true), 
			"depth2": Dictionary(_source["DEPTH2_RESOURCE_PROFILES"][mine_id]).duplicate(true), 
			"drill_gated": Dictionary(DRILL_GATED_RESOURCES[mine_id]).duplicate(true), 
		}, 
		"surface_vein": _surface_vein(String(surface["surface_vein_id"])), 
		"chests": chests, 
		"mine_assets": Dictionary(MINE_ASSETS[world_id]).duplicate(true), 
	}


func is_world_unlocked(world_id: String, state: Dictionary) -> bool:
	assert (MINE_BY_WORLD.has(world_id), "Unknown world: %s" % world_id)
	if world_id == "mossvein":
		return true
	var gate: Dictionary = ENTRY_GATES[world_id]
	return bool(_state_value(state, String(gate["unlock_key"]), false))


func entry_requirements_met(world_id: String, state: Dictionary) -> bool:
	assert (MINE_BY_WORLD.has(world_id), "Unknown world: %s" % world_id)
	if world_id == "mossvein":
		return true
	var gate: = _entry_gate(world_id)
	var pickaxe_level: = int(_state_value(state, "pickaxeLevel", 1))
	var ember_mastery: = int(_state_value(state, "emberMastery", 0))
	var gold: = int(state.get("gold", 0))
	return (
		pickaxe_level >= int(gate["min_pickaxe_level"])
		and ember_mastery >= int(gate["min_ember_mastery"])
		and gold >= int(gate["gold_cost"])
	)


func asset_paths(world_id: String) -> PackedStringArray:
	var found: = {}
	_collect_asset_paths(world(world_id), found)
	var paths: = PackedStringArray()
	for path in found:
		paths.append(String(path))
	paths.sort()
	return paths


func _entry_gate(world_id: String) -> Dictionary:
	if world_id == "mossvein":
		return {}
	var gate: = Dictionary(ENTRY_GATES[world_id]).duplicate(true)
	var gold_key: = String(gate["gold_cost_key"])
	gate["gold_cost"] = 0 if gold_key.is_empty() else int(_source[gold_key])
	gate["transition_duration"] = GATE_TRANSITION_DURATION
	gate["station"] = Dictionary(_source["STATIONS"][gate["station_id"]]).duplicate(true)
	gate["boundary"] = _boundary_for_world(world_id)
	var pickaxe_level: = int(gate["min_pickaxe_level"])
	gate["required_pickaxe_name"] = "" if pickaxe_level == 0 else String(_source["PICKAXES"][pickaxe_level]["name"])
	return gate


func _boundary_for_world(world_id: String) -> Dictionary:
	for boundary_value in _source["SURFACE_BOUNDARIES"]:
		var boundary: = Dictionary(boundary_value)
		if String(boundary["id"]) == world_id:
			return boundary.duplicate(true)
	assert (false, "Missing surface boundary for world: %s" % world_id)
	return {}


func _surface_vein(vein_id: String) -> Dictionary:
	for vein_value in _source["VEIN_DEFINITIONS"]:
		var vein: = Dictionary(vein_value)
		if String(vein["id"]) == vein_id:
			return vein.duplicate(true)
	assert (false, "Missing surface vein: %s" % vein_id)
	return {}


func _chests_for_world(world_id: String) -> Array:
	var result: Array = []
	for chest_value in _source["CHEST_DEFINITIONS"]:
		var chest: = Dictionary(chest_value)
		if String(chest["biome"]) != world_id:
			continue
		var copy: = chest.duplicate(true)
		copy["assets"] = Dictionary(CHEST_ASSETS[String(chest["id"])]).duplicate(true)
		result.append(copy)
	return result


func _state_value(state: Dictionary, source_key: String, default_value: Variant) -> Variant:
	if state.has(source_key):
		return state[source_key]
	var snake_key: = _camel_to_snake(source_key)
	return state.get(snake_key, default_value)


func _camel_to_snake(value: String) -> String:
	var result: = ""
	for character in value:
		var text: = String(character)
		if text == text.to_upper() and text != text.to_lower():
			result += "_" + text.to_lower()
		else:
			result += text
	return result


func _collect_asset_paths(value: Variant, found: Dictionary) -> void :
	if typeof(value) == TYPE_STRING:
		var text: = String(value)
		if text.begins_with("res://assets/"):
			found[text] = true
	elif typeof(value) == TYPE_DICTIONARY:
		for child in Dictionary(value).values():
			_collect_asset_paths(child, found)
	elif typeof(value) == TYPE_ARRAY:
		for child in Array(value):
			_collect_asset_paths(child, found)


func _validate_source_contract() -> void :
	var required_keys: = [
		"WORLD", "MINE_DEFINITIONS", "MINE_SCENES", "MINE_DEPTH_PROFILES", 
		"DEPTH2_RESOURCE_PROFILES", "BIOMES", "SURFACE_BOUNDARIES", 
		"MINE_DISCOVERY_PROFILES", "PICKAXES", "STATIONS", "CHEST_DEFINITIONS", 
		"VEIN_DEFINITIONS", "GATE_COST", "EMBER_GATE_COST", 
	]
	for key in required_keys:
		assert (_source.has(key), "World catalog source is missing %s" % key)
	assert (_source["BIOMES"].size() == WORLD_ORDER.size())
	assert (_source["MINE_SCENES"].size() == MINE_ORDER.size())
	assert (_source["SURFACE_BOUNDARIES"].size() == WORLD_ORDER.size() - 1)
	for index in WORLD_ORDER.size():
		var world_id: = String(WORLD_ORDER[index])
		var mine_id: = String(MINE_ORDER[index])
		assert (String(_source["BIOMES"][index]["id"]) == world_id)
		assert (String(_source["MINE_SCENES"][index]) == mine_id)
		assert (String(_source["MINE_DEFINITIONS"][mine_id]["id"]) == mine_id)
		assert (String(_source["MINE_DEFINITIONS"][mine_id]["surfaceName"]) == String(_source["BIOMES"][index]["name"]))
		assert (MINE_BY_WORLD[world_id] == mine_id)
	assert (int(_source["WORLD"]["width"]) == 4480)
	assert (int(_source["WORLD"]["height"]) == 1280)
	assert (int(_source["GATE_COST"]) == 120)
	assert (int(_source["EMBER_GATE_COST"]) == 360)
