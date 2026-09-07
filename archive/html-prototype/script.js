(function(){
  'use strict';

  const canvas=document.getElementById('gameCanvas');
  const game=document.getElementById('game');
  const ctx=canvas.getContext('2d',{alpha:false});
  const ASSET_VERSION='03801';
  const MOONGLASS_SURFACE_BLEND=24;
  const MOONGLASS_GATE_TRANSITION_DURATION=2.4;
  const EMBERDEEP_SURFACE_BLEND=24;
  const EMBERDEEP_GATE_TRANSITION_DURATION=2.4;
  const STARFALL_SURFACE_BLEND=24;
  const STARFALL_GATE_TRANSITION_DURATION=2.4;
  const DEPTH_PORTAL_RESOURCE_CLEARANCE=136;
  const DEPTH_STATION_RESOURCE_CLEARANCE=132;
  const EMBERDEEP_MINE_PATH_BOUNDS=Object.freeze({x:2456,y:772,w:500,h:222});
  const EMBERDEEP_MINE_PATH_ROTATION=-.105;
  const EMBERDEEP_MINE_PATH_PIVOT=Object.freeze({x:2956,y:809});
  const STARFALL_MINE_PATH_BOUNDS=Object.freeze({x:3450,y:760,w:650,h:289});
  const DEPTH_LAMP_OFFSETS=Object.freeze({default:Object.freeze({x:72,y:22}),emberMine:Object.freeze({x:29,y:-57}),starMine:Object.freeze({x:39,y:-46})});
  const LIGHTING=Object.freeze({
    bufferScale:.34,darknessDepth1:.71,darknessDepth2:.78,
    ambientRadius:148,beamLength:590,beamHalfAngle:.52,beamCoreHalfAngle:.3,
    maxOreLights:16,maxNaturalLights:22,rayStep:20,ambientRays:36,beamRays:34,oreRays:14,
    stoneIntensity:.1,rockOreIntensity:.38,rareRockOreIntensity:.46,wallOreIntensity:.52,rareWallOreIntensity:.58,
    bonusCrystalIntensity:.86,collectedBonusCrystalIntensity:.68,depthLampIntensity:.64
  });
  const lightCanvas=typeof document.createElement==='function'?document.createElement('canvas'):null;
  const lightCtx=lightCanvas&&lightCanvas.getContext?lightCanvas.getContext('2d',{alpha:true}):null;
  let lightingRayChecks=0,lightingOreCount=0,lightingLastSources=[];
  const readableTextQueue=[];
  let readableTextCapture=false;

  function queueReadableText(kind,text,x,y,maxWidth){
    if(!readableTextCapture)return;
    const matrix=typeof ctx.getTransform==='function'?ctx.getTransform():null,transform=matrix?{a:matrix.a,b:matrix.b,c:matrix.c,d:matrix.d,e:matrix.e,f:matrix.f}:null;
    readableTextQueue.push({kind,text,x,y,maxWidth,transform,fillStyle:ctx.fillStyle,strokeStyle:ctx.strokeStyle,font:ctx.font,textAlign:ctx.textAlign,textBaseline:ctx.textBaseline,direction:ctx.direction,globalAlpha:ctx.globalAlpha,lineWidth:ctx.lineWidth,lineCap:ctx.lineCap,lineJoin:ctx.lineJoin,miterLimit:ctx.miterLimit,shadowColor:ctx.shadowColor,shadowBlur:ctx.shadowBlur,shadowOffsetX:ctx.shadowOffsetX,shadowOffsetY:ctx.shadowOffsetY,globalCompositeOperation:ctx.globalCompositeOperation});
  }
  function readableFillText(text,x,y,maxWidth){
    if(maxWidth===undefined)ctx.fillText(text,x,y);else ctx.fillText(text,x,y,maxWidth);
    queueReadableText('fill',text,x,y,maxWidth);
  }
  function readableStrokeText(text,x,y,maxWidth){
    if(maxWidth===undefined)ctx.strokeText(text,x,y);else ctx.strokeText(text,x,y,maxWidth);
    queueReadableText('stroke',text,x,y,maxWidth);
  }
  function drawReadableTextOverlay(){
    for(const item of readableTextQueue){
      ctx.save();if(item.transform)ctx.setTransform(item.transform.a,item.transform.b,item.transform.c,item.transform.d,item.transform.e,item.transform.f);ctx.fillStyle=item.fillStyle;ctx.strokeStyle=item.strokeStyle;ctx.font=item.font;ctx.textAlign=item.textAlign;ctx.textBaseline=item.textBaseline;ctx.direction=item.direction;ctx.globalAlpha=item.globalAlpha;ctx.lineWidth=item.lineWidth;ctx.lineCap=item.lineCap;ctx.lineJoin=item.lineJoin;ctx.miterLimit=item.miterLimit;ctx.shadowColor=item.shadowColor;ctx.shadowBlur=item.shadowBlur;ctx.shadowOffsetX=item.shadowOffsetX;ctx.shadowOffsetY=item.shadowOffsetY;ctx.globalCompositeOperation=item.globalCompositeOperation;
      if(item.kind==='stroke'){if(item.maxWidth===undefined)ctx.strokeText(item.text,item.x,item.y);else ctx.strokeText(item.text,item.x,item.y,item.maxWidth)}else if(item.maxWidth===undefined)ctx.fillText(item.text,item.x,item.y);else ctx.fillText(item.text,item.x,item.y,item.maxWidth);
      ctx.restore();
    }
  }
  const MUSIC_PATH='assets/audio/ever-deeper-drift-loop.mp3?v='+ASSET_VERSION;
  // iOS may ignore HTMLAudioElement volume. The asset itself is mastered at -28 LUFS.
  const MUSIC_VOLUME=1;
  const AUDIO_SETTINGS_KEY='everDeeperAudioSettingsV1';
  const MOSSVEIN_ART={wall:null,floor:null,floorPattern:null};
  const UNBREAKABLE_WALL_ART={mossMine:null,moonMine:null,emberMine:null,starMine:null};
  const UNBREAKABLE_WALL_PATHS=Object.freeze({
    mossMine:'assets/mossvein/unbreakable-wall.png',moonMine:'assets/moonglass/unbreakable-wall.png',
    emberMine:'assets/emberdeep/unbreakable-wall.png',starMine:'assets/starfall/unbreakable-wall.png'
  });
  const SURFACE_ART={mossveinGround:null,mossveinMinePath:null,roads:{},moonglassGround:null,moonglassGroundPattern:null,moonglassCrystals:null,moonglassBloomBed:null,emberdeepGround:null,emberdeepGroundPattern:null,emberdeepSlag:null,emberdeepFaultBed:null,emberdeepMinePath:null,starfallGround:null,starfallGroundPattern:null,starfallShards:null,starfallLatticeBed:null,starfallMinePath:null};
  const MOSSVEIN_MINE_PATH='assets/surface/mossvein-mine-path.png';
  const SURFACE_ROAD_PATHS=Object.freeze({mossvein:'assets/surface/road-mossvein.png',moonglass:'assets/surface/road-moonglass.png',emberdeep:'assets/surface/road-emberdeep.png',starfall:'assets/surface/road-starfall.png'});
  const SURFACE_BOUNDARY_ART={moonglass:null,emberdeep:null,starfall:null};
  const SURFACE_BOUNDARY_PATHS=Object.freeze({
    moonglass:'assets/surface/boundary-mossvein-moonglass.png',
    emberdeep:'assets/surface/boundary-moonglass-emberdeep.png',
    starfall:'assets/surface/boundary-emberdeep-starfall.png'
  });
  const DISCOVERY_ART={crystalPocket:null};
  const STARTER_ART={sellStation:null,forgeStation:null,storageChest:null,wayfarerShop:null,moonglassGate:null,moonglassGateMark:null,emberdeepSeal:null,emberdeepSealMark:null,starfallSeal:null,starfallSealMark:null,starforgeStation:null,treasureClosed:null,treasureOpen:null,drops:{}};
  const STARTER_PATHS=Object.freeze({
    sellStation:'assets/surface/assay-station.png',forgeStation:'assets/surface/forge-station.png',storageChest:'assets/surface/storage-chest.png',wayfarerShop:'assets/surface/wayfarer-shop.png',
    treasureClosed:'assets/surface/treasure-cache-closed.png',treasureOpen:'assets/surface/treasure-cache-open.png',moonglassGate:'assets/surface/moonglass-gate.png',moonglassGateMark:'assets/surface/moonglass-gate-mark.png',emberdeepSeal:'assets/surface/emberdeep-seal.png',emberdeepSealMark:'assets/surface/emberdeep-seal-mark.png',starfallSeal:'assets/surface/starfall-seal.png',starfallSealMark:'assets/surface/starfall-seal-mark.png',starforgeStation:'assets/surface/starforge-station.png'
  });
  const SURFACE_MOONGLASS_PATHS=Object.freeze({
    ground:'assets/surface/moonglass-ground.png',crystals:'assets/surface/moonglass-crystals.png',bloomBed:'assets/surface/moonglass-bloom-bed.png',
    crystalCacheClosed:'assets/surface/crystal-cache-closed.png',crystalCacheOpen:'assets/surface/crystal-cache-open.png',reliquaryClosed:'assets/surface/moonglass-reliquary-closed.png',reliquaryOpen:'assets/surface/moonglass-reliquary-open.png'
  });
  const MOONGLASS_SURFACE_CHEST_ART={moon_cache:{closed:null,open:null},moon_reliquary:{closed:null,open:null}};
  const SURFACE_EMBERDEEP_PATHS=Object.freeze({
    ground:'assets/surface/emberdeep-ground.png',slag:'assets/surface/emberdeep-slag-clusters.png',faultBed:'assets/surface/emberdeep-fault-bed.png',minePath:'assets/surface/emberdeep-mine-path.png',
    foundryClosed:'assets/surface/foundry-lockbox-closed.png',foundryOpen:'assets/surface/foundry-lockbox-open.png',vaultClosed:'assets/surface/ember-vault-closed.png',vaultOpen:'assets/surface/ember-vault-open.png'
  });
  const EMBERDEEP_SURFACE_CHEST_ART={ember_cache:{closed:null,open:null},ember_vault:{closed:null,open:null}};
  const SURFACE_STARFALL_PATHS=Object.freeze({
    ground:'assets/surface/starfall-ground.png',shards:'assets/surface/starfall-shard-clusters.png',latticeBed:'assets/surface/starfall-lattice-bed.png',minePath:'assets/surface/starfall-mine-path.png',
    astralCacheClosed:'assets/surface/astral-cache-closed.png',astralCacheOpen:'assets/surface/astral-cache-open.png',celestialCofferClosed:'assets/surface/celestial-coffer-closed.png',celestialCofferOpen:'assets/surface/celestial-coffer-open.png'
  });
  const STARFALL_SURFACE_CHEST_ART={star_cache:{closed:null,open:null},star_coffer:{closed:null,open:null}};
  const AMBIENT_ART={mossvein:null,moonglass:null,emberdeep:null,starfall:null};
  const AMBIENT_PATHS=Object.freeze({
    mossvein:'assets/ambient/mossvein-glowmoth.png',
    moonglass:'assets/ambient/moonglass-prism-moth.png',
    emberdeep:'assets/ambient/emberdeep-cinder-skink.png',
    starfall:'assets/ambient/starfall-astral-ray.png'
  });
  const AMBIENT_FRAME_COUNT=4,AMBIENT_FRAME_SIZE=256,AMBIENT_SURFACE_MAX_VISIBLE=10,AMBIENT_MINE_MAX_VISIBLE=6;
  const AMBIENT_PROFILES=Object.freeze({
    mossvein:Object.freeze({key:'mossvein',scene:'mossMine',name:'Glowmoth',seed:17011,size:50,fps:7.5,flying:true,glow:'#e7b951'}),
    moonglass:Object.freeze({key:'moonglass',scene:'moonMine',name:'Prism Moth',seed:29021,size:52,fps:7,flying:true,glow:'#72e9ff'}),
    emberdeep:Object.freeze({key:'emberdeep',scene:'emberMine',name:'Cinder Skink',seed:43037,size:58,fps:6,flying:false,directional:true,baseline:[0,5,10,1],glow:'#ff7b3b'}),
    starfall:Object.freeze({key:'starfall',scene:'starMine',name:'Astral Ray',seed:61051,size:56,fps:6.5,flying:true,directional:true,glow:'#aa93ff'})
  });
  const AMBIENT_SCENE_KEYS=Object.freeze({mossMine:'mossvein',moonMine:'moonglass',emberMine:'emberdeep',starMine:'starfall'});
  const AMBIENT_SURFACE_ANCHORS=Object.freeze({
    mossvein:Object.freeze([[120,180],[350,340],[640,150],[870,330],[990,1020],[760,1190],[510,880],[250,1120],[840,760]]),
    moonglass:Object.freeze([[1190,160],[1460,260],[1770,160],[2110,340],[1210,850],[1440,1190],[1870,1120],[2160,920],[1700,720]]),
    emberdeep:Object.freeze([[2320,180],[2670,150],[3010,250],[3280,420],[2350,1120],[2720,850],[3120,1120],[3250,800],[2860,650]]),
    starfall:Object.freeze([[3420,190],[3650,150],[3970,240],[4310,420],[3480,1140],[3760,840],[4230,1120],[4360,760],[4010,650]])
  });
  const WORLD_LIFE_SURFACE_ANCHORS=Object.freeze({
    mossvein:Object.freeze([[155,365],[510,260],[800,520],[950,1035],[450,1120]]),
    moonglass:Object.freeze([[1220,420],[1540,690],[1850,280],[2070,1020],[1450,1160]]),
    emberdeep:Object.freeze([[2370,370],[2700,980],[3040,350],[3250,1040],[2860,690]]),
    starfall:Object.freeze([[3470,400],[3760,1060],[4090,340],[4330,950],[3970,720]])
  });
  const AMBIENT_RENDER_CONTRACT=Object.freeze({
    frameCount:AMBIENT_FRAME_COUNT,frameSize:AMBIENT_FRAME_SIZE,spriteSheetWidth:1024,spriteSheetHeight:256,decodedMemoryBudgetBytes:4194304,premiumSpriteSheets:true,trueAnimationFrames:true,deterministicPlacement:true,
    surfaceMaxVisible:AMBIENT_SURFACE_MAX_VISIBLE,mineMaxVisible:AMBIENT_MINE_MAX_VISIBLE,rareSurfaceCrossings:true,reducedMotionSafe:true,
    roamingRoutes:true,mineRouteSampling:true,miningReactions:true,continuousReactions:true,restBehavior:true,collisionFree:true,gameplayNeutral:true,proceduralCreaturePrimitives:false
  });
  const WORLD_LIFE_ART={drift:{mossvein:null,moonglass:null,emberdeep:null,starfall:null},response:{mossvein:null,moonglass:null,emberdeep:null,starfall:null},impact:{mossvein:null,moonglass:null,emberdeep:null,starfall:null}};
  const WORLD_LIFE_PATHS=Object.freeze({
    mossvein:Object.freeze({drift:'assets/world-life/mossvein-drift.png',response:'assets/world-life/mossvein-response.png',impact:'assets/world-life/mossvein-impact.png'}),
    moonglass:Object.freeze({drift:'assets/world-life/moonglass-drift.png',response:'assets/world-life/moonglass-response.png',impact:'assets/world-life/moonglass-impact.png'}),
    emberdeep:Object.freeze({drift:'assets/world-life/emberdeep-drift.png',response:'assets/world-life/emberdeep-response.png',impact:'assets/world-life/emberdeep-impact.png'}),
    starfall:Object.freeze({drift:'assets/world-life/starfall-drift.png',response:'assets/world-life/starfall-response.png',impact:'assets/world-life/starfall-impact.png'})
  });
  const WORLD_LIFE_FRAME_COUNT=4,WORLD_LIFE_FRAME_SIZE=256,WORLD_LIFE_SURFACE_MAX_VISIBLE=4,WORLD_LIFE_MINE_MAX_VISIBLE=3,WORLD_LIFE_RESPONSE_MAX_VISIBLE=6;
  const WORLD_LIFE_PROFILES=Object.freeze({
    mossvein:Object.freeze({key:'mossvein',seed:70201,driftSize:82,driftFps:2.1,driftAlpha:.24,responseSize:70,responseAlpha:.5}),
    moonglass:Object.freeze({key:'moonglass',seed:81371,driftSize:88,driftFps:1.8,driftAlpha:.27,responseSize:76,responseAlpha:.58}),
    emberdeep:Object.freeze({key:'emberdeep',seed:92413,driftSize:86,driftFps:2.3,driftAlpha:.25,responseSize:78,responseAlpha:.57}),
    starfall:Object.freeze({key:'starfall',seed:103231,driftSize:92,driftFps:1.65,driftAlpha:.28,responseSize:80,responseAlpha:.6})
  });
  const WORLD_LIFE_RENDER_CONTRACT=Object.freeze({
    frameCount:WORLD_LIFE_FRAME_COUNT,frameSize:WORLD_LIFE_FRAME_SIZE,spriteSheetWidth:1024,spriteSheetHeight:256,decodedMemoryBudgetBytes:12582912,premiumSpriteSheets:true,trueAnimationFrames:true,
    surfaceMaxVisible:WORLD_LIFE_SURFACE_MAX_VISIBLE,mineMaxVisible:WORLD_LIFE_MINE_MAX_VISIBLE,responseMaxVisible:WORLD_LIFE_RESPONSE_MAX_VISIBLE,worldAnchored:true,deterministicPlacement:true,biomeSpecific:true,footstepResponses:true,miningResponses:true,dedicatedImpactSheets:true,noCircularImpactSilhouettes:true,impactStacking:false,
    underMineLighting:true,reducedMotionSafe:true,gameplayNeutral:true,proceduralEffectPrimitives:false
  });
  const MINE_ENTRANCE_PATHS=Object.freeze({mossMine:'assets/entrances/mossvein-entrance.png',moonMine:'assets/entrances/moonglass-entrance.png',emberMine:'assets/entrances/emberdeep-entrance.png',starMine:'assets/entrances/starfall-entrance.png',depthLamp:'assets/entrances/depth-work-lamp.png'});
  const MOONGLASS_ART={floor:null,floorPattern:null,wall:null,routeMarker:null,pocket:null,rewards:{cache:null,shrine:null},nodes:{},wallHints:{},barriers:{}};
  const MOONGLASS_PATHS=Object.freeze({
    floor:'assets/moonglass/floor.png',wall:'assets/moonglass/wall.png',routeMarker:'assets/moonglass/route-marker.png',pocket:'assets/moonglass/crystal-pocket.png',cache:'assets/moonglass/buried-cache.png',shrine:'assets/moonglass/mining-rush-shrine.png',
    moonglassNode:'assets/moonglass/moonglass-node.png',starshardNode:'assets/moonglass/starshard-node.png',moonglassWall:'assets/moonglass/moonglass-wall.png',starshardWall:'assets/moonglass/starshard-wall.png',
    prismFault:'assets/moonglass/prismatic-fault.png',starGeode:'assets/moonglass/starbound-geode.png'
  });
  const PRISMATIC_ART={floor:null,floorPattern:null,wall:null,shaft:null,sellStation:null,drillForge:null,pocket:null,rewards:{cache:null,shrine:null},nodes:{},wallHints:{}};
  const PRISMATIC_PATHS=Object.freeze({
    floor:'assets/prismatic/floor.png',wall:'assets/prismatic/wall.png',shaft:'assets/prismatic/depth-portal.png',sellStation:'assets/prismatic/sell-station.png',drillForge:'assets/prismatic/drill-forge.png',pocket:'assets/prismatic/crystal-pocket.png',cache:'assets/prismatic/buried-cache.png',shrine:'assets/prismatic/mining-rush-shrine.png',
    prismiteNode:'assets/prismatic/prismite-node.png',lunacoreNode:'assets/prismatic/lunacore-node.png',phasecrystalNode:'assets/prismatic/phasecrystal-node.png',prismiteWall:'assets/prismatic/prismite-wall.png',deepstoneWall:'assets/prismatic/deepstone-wall.png',lunacoreWall:'assets/prismatic/lunacore-wall.png',phasecrystalWall:'assets/prismatic/phasecrystal-wall.png'
  });
  const EMBERDEEP_ART={floor:null,floorPattern:null,wall:null,routeMarker:null,pocket:null,rewards:{cache:null,shrine:null},nodes:{},wallHints:{},barriers:{}};
  const EMBERDEEP_PATHS=Object.freeze({
    floor:'assets/emberdeep/floor.png',wall:'assets/emberdeep/wall.png',routeMarker:'assets/emberdeep/route-marker.png',pocket:'assets/emberdeep/crystal-pocket.png',cache:'assets/emberdeep/buried-cache.png',shrine:'assets/emberdeep/mining-rush-shrine.png',
    emberstoneNode:'assets/emberdeep/emberstone-node.png',sunslagNode:'assets/emberdeep/sunslag-node.png',emberstoneWall:'assets/emberdeep/emberstone-wall.png',sunslagWall:'assets/emberdeep/sunslag-wall.png',
    cinderBulkhead:'assets/emberdeep/cinder-bulkhead.png',crucibleSeal:'assets/emberdeep/crucible-seal.png'
  });
  const MOLTEN_ART={floor:null,floorPattern:null,wall:null,shaft:null,sellStation:null,drillForge:null,pocket:null,rewards:{cache:null,shrine:null},nodes:{},wallHints:{}};
  const MOLTEN_PATHS=Object.freeze({
    floor:'assets/molten/floor.png',wall:'assets/molten/wall.png',shaft:'assets/molten/depth-portal.png',sellStation:'assets/molten/sell-station.png',drillForge:'assets/molten/drill-forge.png',pocket:'assets/molten/crystal-pocket.png',cache:'assets/molten/buried-cache.png',shrine:'assets/molten/mining-rush-shrine.png',
    magmaiteNode:'assets/molten/magmaite-node.png',deepstoneNode:'assets/molten/deepstone-node.png',furnaceheartNode:'assets/molten/furnaceheart-node.png',inferniumNode:'assets/molten/infernium-node.png',
    magmaiteWall:'assets/molten/magmaite-wall.png',deepstoneWall:'assets/molten/deepstone-wall.png',furnaceheartWall:'assets/molten/furnaceheart-wall.png',inferniumWall:'assets/molten/infernium-wall.png'
  });
  const STARFALL_ART={floor:null,floorPattern:null,wall:null,routeMarker:null,pocket:null,rewards:{cache:null,shrine:null},nodes:{},wallHints:{},barriers:{}};
  const STARFALL_PATHS=Object.freeze({
    floor:'assets/starfall/floor.png',wall:'assets/starfall/wall.png',routeMarker:'assets/starfall/route-marker.png',pocket:'assets/starfall/crystal-pocket.png',cache:'assets/starfall/buried-cache.png',shrine:'assets/starfall/mining-rush-shrine.png',
    astraliteNode:'assets/starfall/astralite-node.png',crownstoneNode:'assets/starfall/crownstone-node.png',astraliteWall:'assets/starfall/astralite-wall.png',crownstoneWall:'assets/starfall/crownstone-wall.png',
    astralBridgeLock:'assets/starfall/astral-bridge-lock.png',crownstoneWard:'assets/starfall/crownstone-ward.png'
  });
  const VOIDSTAR_ART={floor:null,floorPattern:null,wall:null,shaft:null,sellStation:null,drillForge:null,pocket:null,rewards:{cache:null,shrine:null},nodes:{},wallHints:{}};
  const VOIDSTAR_PATHS=Object.freeze({
    floor:'assets/voidstar/floor.png',wall:'assets/voidstar/wall.png',shaft:'assets/voidstar/depth-portal.png',sellStation:'assets/voidstar/sell-station.png',drillForge:'assets/voidstar/drill-forge.png',pocket:'assets/voidstar/crystal-pocket.png',cache:'assets/voidstar/buried-cache.png',shrine:'assets/voidstar/mining-rush-shrine.png',
    voidglassNode:'assets/voidstar/voidglass-node.png',deepstoneNode:'assets/voidstar/deepstone-node.png',singularityNode:'assets/voidstar/singularity-node.png',voidglassWall:'assets/voidstar/voidglass-wall.png',deepstoneWall:'assets/voidstar/deepstone-wall.png',singularityWall:'assets/voidstar/singularity-wall.png'
  });
  const MOSSVEIN_REWARD_ART={cache:null,shrine:null};
  const MOSSVEIN_REWARD_PATHS=Object.freeze({cache:'assets/mossvein/buried-cache.png',shrine:'assets/mossvein/mining-rush-shrine.png'});
  const DROP_PATHS=Object.freeze({
    stone:'assets/drops/stone-drop.png',copper:'assets/drops/copper-drop.png',gold:'assets/drops/gold-drop.png',moonglass:'assets/drops/moonglass-drop.png',starshard:'assets/drops/starshard-drop.png',
    emberstone:'assets/drops/emberstone-drop.png',sunslag:'assets/drops/sunslag-drop.png',astralite:'assets/drops/astralite-drop.png',crownstone:'assets/drops/crownstone-drop.png',
    deepstone:'assets/drops/deepstone-drop.png',rootiron:'assets/drops/rootiron-drop.png',ambercore:'assets/drops/ambercore-drop.png',prismite:'assets/drops/prismite-drop.png',lunacore:'assets/drops/lunacore-drop.png',
    magmaite:'assets/drops/magmaite-drop.png',furnaceheart:'assets/drops/furnaceheart-drop.png',voidglass:'assets/drops/voidglass-drop.png',singularity:'assets/drops/singularity-drop.png',burrowsteel:'assets/drops/burrowsteel-drop.png',
    phasecrystal:'assets/drops/phasecrystal-drop.png',infernium:'assets/drops/infernium-drop.png'
  });
  const RESOURCE_IMAGE_BOUNDS=Object.freeze({
    stone:Object.freeze({x:0,y:0,w:256,h:211}),copper:Object.freeze({x:0,y:0,w:256,h:239}),gold:Object.freeze({x:0,y:0,w:256,h:194}),
    moonglass:Object.freeze({x:9,y:8,w:237,h:240}),starshard:Object.freeze({x:36,y:8,w:183,h:240}),emberstone:Object.freeze({x:39,y:58,w:184,h:132}),sunslag:Object.freeze({x:64,y:50,w:157,h:140}),
    astralite:Object.freeze({x:23,y:22,w:210,h:212}),crownstone:Object.freeze({x:26,y:22,w:203,h:212}),deepstone:Object.freeze({x:8,y:19,w:240,h:218}),rootiron:Object.freeze({x:31,y:22,w:194,h:212}),ambercore:Object.freeze({x:31,y:22,w:193,h:212}),
    prismite:Object.freeze({x:8,y:15,w:240,h:225}),lunacore:Object.freeze({x:15,y:8,w:225,h:240}),magmaite:Object.freeze({x:53,y:37,w:151,h:164}),furnaceheart:Object.freeze({x:55,y:37,w:138,h:170}),
    voidglass:Object.freeze({x:23,y:22,w:209,h:212}),singularity:Object.freeze({x:23,y:22,w:210,h:212}),burrowsteel:Object.freeze({x:22,y:22,w:211,h:212}),phasecrystal:Object.freeze({x:40,y:8,w:175,h:240}),infernium:Object.freeze({x:62,y:24,w:129,h:192})
  });
  const RESOURCE_RENDER_CONTRACT=Object.freeze({
    completeResourceSet:true,sharedWorldAndUiAssets:true,transparentBoundsNormalized:true,nodeAssetCoverage:true,objectiveIcons:true,inventoryIcons:true,storageIcons:true,recipeIcons:true,ledgerIcons:true,
    croppedGroundDrops:true,legacyCanvasResourceSymbols:false,legacyCanvasResourceDrops:false
  });
  const ROOTWOUND_ART={floor:null,floorPattern:null,wall:null,rootironWall:null,shaft:null,sellStation:null,drillForge:null,nodes:{}};
  const ROOTWOUND_PATHS=Object.freeze({
    floor:'assets/rootwound/floor.png',wall:'assets/rootwound/wall.png',rootironWall:'assets/rootwound/rootiron-wall.png',shaft:'assets/rootwound/depth-shaft.png',sellStation:'assets/rootwound/sell-station.png',drillForge:'assets/rootwound/drill-forge.png',
    rootiron:'assets/rootwound/rootiron-node.png',deepstone:'assets/rootwound/deepstone-node.png',ambercore:'assets/rootwound/ambercore-node.png',burrowsteel:'assets/rootwound/burrowsteel-node.png'
  });
  const MINERAL_ART={stone:{wall:null,node:null},copper:{wall:null,node:null},gold:{wall:null,node:null}};
  const MINE_ENTRANCE_ART={mossMine:null,moonMine:null,emberMine:null,starMine:null,depthLamp:null};
  const PLAYER_ART={base:null,tools:{},drillCharacters:{},walkSheets:{}};
  const PLAYER_TOOL_PATHS=Object.freeze({
    'pickaxe-worn':'assets/tools/pickaxe-worn.png','pickaxe-iron':'assets/tools/pickaxe-iron.png','pickaxe-runed':'assets/tools/pickaxe-runed.png','pickaxe-moonglass':'assets/tools/pickaxe-moonglass.png','pickaxe-ember':'assets/tools/pickaxe-ember.png',
    'starforge-crusher':'assets/tools/starforge-crusher.png','starforge-swift':'assets/tools/starforge-swift.png','starforge-prospector':'assets/tools/starforge-prospector.png'
  });
  const UI_TOOL_PATHS=Object.freeze({...PLAYER_TOOL_PATHS,'drill-burrower':'assets/tools/'+'drill-burrower.png','drill-pulse':'assets/tools/'+'drill-pulse.png','drill-deepcore':'assets/tools/'+'drill-deepcore.png'});
  const PLAYER_DRILL_CHARACTER_PATHS=Object.freeze({
    'drill-burrower':'assets/characters/miner-b-drill-burrower.png',
    'drill-pulse':'assets/characters/miner-b-drill-pulse.png',
    'drill-deepcore':'assets/characters/miner-b-drill-deepcore.png'
  });
  const PLAYER_WALK_PATHS=Object.freeze({
    base:'assets/characters/miner-b-walk.png',
    'drill-burrower':'assets/characters/miner-b-drill-burrower-walk.png',
    'drill-pulse':'assets/characters/miner-b-drill-pulse-walk.png',
    'drill-deepcore':'assets/characters/miner-b-drill-deepcore-walk.png'
  });
  const PLAYER_WALK_DIRECTIONS=Object.freeze(['down','left','right','up']);
  const PLAYER_WALK_ROWS=Object.freeze({down:0,left:1,right:2,up:3});
  const PLAYER_WALK_FRAME_BOB=Object.freeze([0,1,0,-1,0,1]);
  const PLAYER_WALK_FRAME_LIFT=Object.freeze([0,1.1,2,0,1.1,2]);
  const PLAYER_WALK_LIGHT_OFFSETS=Object.freeze({down:{x:12,y:-59},left:{x:-13,y:-58},right:{x:13,y:-58},up:{x:0,y:-62}});
  const PLAYER_WALK_TOOL_ANCHORS=Object.freeze({down:{x:-2,y:-33,angle:-.84,flip:false},left:{x:1,y:-34,angle:-.76,flip:false},right:{x:-1,y:-34,angle:-.76,flip:true},up:{x:0,y:-31,angle:-.72,flip:false}});
  const PLAYER_TOOL_RENDER=Object.freeze({
    'pickaxe-worn':{width:82,pivotX:.32,pivotY:.5},'pickaxe-iron':{width:82,pivotX:.32,pivotY:.5},'pickaxe-runed':{width:82,pivotX:.32,pivotY:.5},'pickaxe-moonglass':{width:82,pivotX:.32,pivotY:.5},'pickaxe-ember':{width:82,pivotX:.32,pivotY:.5},
    'starforge-crusher':{width:80,pivotX:.32,pivotY:.5},'starforge-swift':{width:84,pivotX:.32,pivotY:.5},'starforge-prospector':{width:84,pivotX:.32,pivotY:.5}
  });
  const PLAYER_RENDER_CONTRACT=Object.freeze({
    bodyHeight:112,bodyBottom:34,
    gripCrop:Object.freeze({x:246,y:307,w:69,h:101}),
    gripPivot:Object.freeze({x:14,y:24}),
    gripPoint:Object.freeze({x:42,y:50}),
    drillCompositeHeight:112,
    walkColumns:6,walkRows:4,walkCellSize:256,walkRenderSize:120,walkRootY:250,walkFrameDistance:24,walkMaxFramesPerSecond:20,
    walkDirectionHysteresis:1.15,walkContactFrames:Object.freeze([0,3]),
    layeredTools:true,animatedGrip:true,bodyReaction:true,sharedGripAnchor:true,fullDrillComposites:true,legacyDrillLimbCrops:false,
    directionalWalk:true,distanceDrivenWalk:true,holsteredWalkTools:true,lazyDrillWalkSheets:true,staticMiningFallback:true,
    legacyCanvasCharacter:false,legacyCanvasTools:false
  });
  function loadGameImage(src,key){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{
      MOSSVEIN_ART[key]=image;
      if(key==='floor'&&typeof ctx.createPattern==='function')MOSSVEIN_ART.floorPattern=ctx.createPattern(image,'repeat');
    };image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function imageReady(image){return !!image&&image.complete&&image.naturalWidth>0}
  function loadMineralImage(type,kind){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{MINERAL_ART[type][kind]=image};image.src='assets/minerals/'+type+'-'+kind+'.png?v='+ASSET_VERSION;return image;
  }
  function loadMineEntranceImage(scene,src=MINE_ENTRANCE_PATHS[scene]){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{MINE_ENTRANCE_ART[scene]=image};image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadSurfaceImage(src,key,patternKey=null){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{SURFACE_ART[key]=image;if(patternKey&&typeof ctx.createPattern==='function')SURFACE_ART[patternKey]=ctx.createPattern(image,'repeat')};image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadDiscoveryImage(src,key){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{DISCOVERY_ART[key]=image};image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadMappedImage(src,target,key){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{target[key]=image};image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadProductionImage(src,target,key,patternKey=null){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{target[key]=image;if(patternKey&&typeof ctx.createPattern==='function')target[patternKey]=ctx.createPattern(image,'repeat')};image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadRootwoundImage(src,key,node=false){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{
      if(node)ROOTWOUND_ART.nodes[key]=image;else ROOTWOUND_ART[key]=image;
      if(key==='floor'&&typeof ctx.createPattern==='function')ROOTWOUND_ART.floorPattern=ctx.createPattern(image,'repeat');
    };image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadPlayerImage(src,key,kind='base'){
    if(typeof Image==='undefined')return null;
    const image=new Image();image.decoding='async';image.onload=()=>{if(kind==='tool')PLAYER_ART.tools[key]=image;else if(kind==='drillCharacter')PLAYER_ART.drillCharacters[key]=image;else PLAYER_ART.base=image};image.src=src+'?v='+ASSET_VERSION;return image;
  }
  function loadPlayerWalkImage(key){
    if(PLAYER_ART.walkSheets[key]||typeof Image==='undefined')return PLAYER_ART.walkSheets[key]||null;
    const image=new Image();image.decoding='async';PLAYER_ART.walkSheets[key]=image;image.src=PLAYER_WALK_PATHS[key]+'?v='+ASSET_VERSION;return image;
  }
  MOSSVEIN_ART.wall=loadGameImage('assets/mossvein/cave-wall.png','wall');
  MOSSVEIN_ART.floor=loadGameImage('assets/mossvein/cave-floor.png','floor');
  for(const [scene,path] of Object.entries(UNBREAKABLE_WALL_PATHS))UNBREAKABLE_WALL_ART[scene]=loadMappedImage(path,UNBREAKABLE_WALL_ART,scene);
  for(const type of Object.keys(MINERAL_ART)){if(type!=='stone')MINERAL_ART[type].wall=loadMineralImage(type,'wall');MINERAL_ART[type].node=loadMineralImage(type,'node')}
  for(const [scene,path] of Object.entries(MINE_ENTRANCE_PATHS))MINE_ENTRANCE_ART[scene]=loadMineEntranceImage(scene,path);
  SURFACE_ART.mossveinGround=loadSurfaceImage('assets/surface/mossvein-ground.png','mossveinGround');
  SURFACE_ART.mossveinMinePath=loadSurfaceImage(MOSSVEIN_MINE_PATH,'mossveinMinePath');
  for(const [biome,path] of Object.entries(SURFACE_ROAD_PATHS))SURFACE_ART.roads[biome]=loadMappedImage(path,SURFACE_ART.roads,biome);
  for(const [boundary,path] of Object.entries(SURFACE_BOUNDARY_PATHS))SURFACE_BOUNDARY_ART[boundary]=loadMappedImage(path,SURFACE_BOUNDARY_ART,boundary);
  SURFACE_ART.moonglassGround=loadSurfaceImage(SURFACE_MOONGLASS_PATHS.ground,'moonglassGround','moonglassGroundPattern');
  SURFACE_ART.moonglassCrystals=loadSurfaceImage(SURFACE_MOONGLASS_PATHS.crystals,'moonglassCrystals');
  SURFACE_ART.moonglassBloomBed=loadSurfaceImage(SURFACE_MOONGLASS_PATHS.bloomBed,'moonglassBloomBed');
  MOONGLASS_SURFACE_CHEST_ART.moon_cache.closed=loadMappedImage(SURFACE_MOONGLASS_PATHS.crystalCacheClosed,MOONGLASS_SURFACE_CHEST_ART.moon_cache,'closed');
  MOONGLASS_SURFACE_CHEST_ART.moon_cache.open=loadMappedImage(SURFACE_MOONGLASS_PATHS.crystalCacheOpen,MOONGLASS_SURFACE_CHEST_ART.moon_cache,'open');
  MOONGLASS_SURFACE_CHEST_ART.moon_reliquary.closed=loadMappedImage(SURFACE_MOONGLASS_PATHS.reliquaryClosed,MOONGLASS_SURFACE_CHEST_ART.moon_reliquary,'closed');
  MOONGLASS_SURFACE_CHEST_ART.moon_reliquary.open=loadMappedImage(SURFACE_MOONGLASS_PATHS.reliquaryOpen,MOONGLASS_SURFACE_CHEST_ART.moon_reliquary,'open');
  SURFACE_ART.emberdeepGround=loadSurfaceImage(SURFACE_EMBERDEEP_PATHS.ground,'emberdeepGround','emberdeepGroundPattern');
  SURFACE_ART.emberdeepSlag=loadSurfaceImage(SURFACE_EMBERDEEP_PATHS.slag,'emberdeepSlag');
  SURFACE_ART.emberdeepFaultBed=loadSurfaceImage(SURFACE_EMBERDEEP_PATHS.faultBed,'emberdeepFaultBed');
  SURFACE_ART.emberdeepMinePath=loadSurfaceImage(SURFACE_EMBERDEEP_PATHS.minePath,'emberdeepMinePath');
  EMBERDEEP_SURFACE_CHEST_ART.ember_cache.closed=loadMappedImage(SURFACE_EMBERDEEP_PATHS.foundryClosed,EMBERDEEP_SURFACE_CHEST_ART.ember_cache,'closed');
  EMBERDEEP_SURFACE_CHEST_ART.ember_cache.open=loadMappedImage(SURFACE_EMBERDEEP_PATHS.foundryOpen,EMBERDEEP_SURFACE_CHEST_ART.ember_cache,'open');
  EMBERDEEP_SURFACE_CHEST_ART.ember_vault.closed=loadMappedImage(SURFACE_EMBERDEEP_PATHS.vaultClosed,EMBERDEEP_SURFACE_CHEST_ART.ember_vault,'closed');
  EMBERDEEP_SURFACE_CHEST_ART.ember_vault.open=loadMappedImage(SURFACE_EMBERDEEP_PATHS.vaultOpen,EMBERDEEP_SURFACE_CHEST_ART.ember_vault,'open');
  SURFACE_ART.starfallGround=loadSurfaceImage(SURFACE_STARFALL_PATHS.ground,'starfallGround','starfallGroundPattern');
  SURFACE_ART.starfallShards=loadSurfaceImage(SURFACE_STARFALL_PATHS.shards,'starfallShards');
  SURFACE_ART.starfallLatticeBed=loadSurfaceImage(SURFACE_STARFALL_PATHS.latticeBed,'starfallLatticeBed');
  SURFACE_ART.starfallMinePath=loadSurfaceImage(SURFACE_STARFALL_PATHS.minePath,'starfallMinePath');
  STARFALL_SURFACE_CHEST_ART.star_cache.closed=loadMappedImage(SURFACE_STARFALL_PATHS.astralCacheClosed,STARFALL_SURFACE_CHEST_ART.star_cache,'closed');
  STARFALL_SURFACE_CHEST_ART.star_cache.open=loadMappedImage(SURFACE_STARFALL_PATHS.astralCacheOpen,STARFALL_SURFACE_CHEST_ART.star_cache,'open');
  STARFALL_SURFACE_CHEST_ART.star_coffer.closed=loadMappedImage(SURFACE_STARFALL_PATHS.celestialCofferClosed,STARFALL_SURFACE_CHEST_ART.star_coffer,'closed');
  STARFALL_SURFACE_CHEST_ART.star_coffer.open=loadMappedImage(SURFACE_STARFALL_PATHS.celestialCofferOpen,STARFALL_SURFACE_CHEST_ART.star_coffer,'open');
  for(const [biome,path] of Object.entries(AMBIENT_PATHS))AMBIENT_ART[biome]=loadMappedImage(path,AMBIENT_ART,biome);
  for(const [biome,paths] of Object.entries(WORLD_LIFE_PATHS)){
    WORLD_LIFE_ART.drift[biome]=loadMappedImage(paths.drift,WORLD_LIFE_ART.drift,biome);
    WORLD_LIFE_ART.response[biome]=loadMappedImage(paths.response,WORLD_LIFE_ART.response,biome);
    WORLD_LIFE_ART.impact[biome]=loadMappedImage(paths.impact,WORLD_LIFE_ART.impact,biome);
  }
  DISCOVERY_ART.crystalPocket=loadDiscoveryImage('assets/mossvein/magic-crystal-pocket.png','crystalPocket');
  for(const [key,path] of Object.entries(STARTER_PATHS))STARTER_ART[key]=loadMappedImage(path,STARTER_ART,key);
  for(const [key,path] of Object.entries(MOSSVEIN_REWARD_PATHS))MOSSVEIN_REWARD_ART[key]=loadMappedImage(path,MOSSVEIN_REWARD_ART,key);
  for(const [key,path] of Object.entries(DROP_PATHS))STARTER_ART.drops[key]=loadMappedImage(path,STARTER_ART.drops,key);
  for(const [key,path] of Object.entries(ROOTWOUND_PATHS)){const node=['rootiron','deepstone','ambercore','burrowsteel'].includes(key),image=loadRootwoundImage(path,key,node);if(node)ROOTWOUND_ART.nodes[key]=image;else ROOTWOUND_ART[key]=image}
  MOONGLASS_ART.floor=loadProductionImage(MOONGLASS_PATHS.floor,MOONGLASS_ART,'floor','floorPattern');
  for(const [key,path] of [['wall',MOONGLASS_PATHS.wall],['routeMarker',MOONGLASS_PATHS.routeMarker],['pocket',MOONGLASS_PATHS.pocket]])MOONGLASS_ART[key]=loadProductionImage(path,MOONGLASS_ART,key);
  MOONGLASS_ART.rewards.cache=loadProductionImage(MOONGLASS_PATHS.cache,MOONGLASS_ART.rewards,'cache');MOONGLASS_ART.rewards.shrine=loadProductionImage(MOONGLASS_PATHS.shrine,MOONGLASS_ART.rewards,'shrine');
  MOONGLASS_ART.nodes.moonglass=loadProductionImage(MOONGLASS_PATHS.moonglassNode,MOONGLASS_ART.nodes,'moonglass');MOONGLASS_ART.nodes.starshard=loadProductionImage(MOONGLASS_PATHS.starshardNode,MOONGLASS_ART.nodes,'starshard');
  MOONGLASS_ART.wallHints.moonglass=loadProductionImage(MOONGLASS_PATHS.moonglassWall,MOONGLASS_ART.wallHints,'moonglass');MOONGLASS_ART.wallHints.starshard=loadProductionImage(MOONGLASS_PATHS.starshardWall,MOONGLASS_ART.wallHints,'starshard');
  MOONGLASS_ART.barriers.moon_prism_gate=loadProductionImage(MOONGLASS_PATHS.prismFault,MOONGLASS_ART.barriers,'moon_prism_gate');MOONGLASS_ART.barriers.moon_star_lock=loadProductionImage(MOONGLASS_PATHS.starGeode,MOONGLASS_ART.barriers,'moon_star_lock');
  PRISMATIC_ART.floor=loadProductionImage(PRISMATIC_PATHS.floor,PRISMATIC_ART,'floor','floorPattern');
  for(const [key,path] of [['wall',PRISMATIC_PATHS.wall],['shaft',PRISMATIC_PATHS.shaft],['sellStation',PRISMATIC_PATHS.sellStation],['drillForge',PRISMATIC_PATHS.drillForge],['pocket',PRISMATIC_PATHS.pocket]])PRISMATIC_ART[key]=loadProductionImage(path,PRISMATIC_ART,key);
  PRISMATIC_ART.rewards.cache=loadProductionImage(PRISMATIC_PATHS.cache,PRISMATIC_ART.rewards,'cache');PRISMATIC_ART.rewards.shrine=loadProductionImage(PRISMATIC_PATHS.shrine,PRISMATIC_ART.rewards,'shrine');
  PRISMATIC_ART.nodes.prismite=loadProductionImage(PRISMATIC_PATHS.prismiteNode,PRISMATIC_ART.nodes,'prismite');PRISMATIC_ART.nodes.deepstone=ROOTWOUND_ART.nodes.deepstone;PRISMATIC_ART.nodes.lunacore=loadProductionImage(PRISMATIC_PATHS.lunacoreNode,PRISMATIC_ART.nodes,'lunacore');PRISMATIC_ART.nodes.phasecrystal=loadProductionImage(PRISMATIC_PATHS.phasecrystalNode,PRISMATIC_ART.nodes,'phasecrystal');
  for(const [type,path] of [['prismite',PRISMATIC_PATHS.prismiteWall],['deepstone',PRISMATIC_PATHS.deepstoneWall],['lunacore',PRISMATIC_PATHS.lunacoreWall],['phasecrystal',PRISMATIC_PATHS.phasecrystalWall]])PRISMATIC_ART.wallHints[type]=loadProductionImage(path,PRISMATIC_ART.wallHints,type);
  EMBERDEEP_ART.floor=loadProductionImage(EMBERDEEP_PATHS.floor,EMBERDEEP_ART,'floor','floorPattern');
  for(const [key,path] of [['wall',EMBERDEEP_PATHS.wall],['routeMarker',EMBERDEEP_PATHS.routeMarker],['pocket',EMBERDEEP_PATHS.pocket]])EMBERDEEP_ART[key]=loadProductionImage(path,EMBERDEEP_ART,key);
  EMBERDEEP_ART.rewards.cache=loadProductionImage(EMBERDEEP_PATHS.cache,EMBERDEEP_ART.rewards,'cache');EMBERDEEP_ART.rewards.shrine=loadProductionImage(EMBERDEEP_PATHS.shrine,EMBERDEEP_ART.rewards,'shrine');
  EMBERDEEP_ART.nodes.emberstone=loadProductionImage(EMBERDEEP_PATHS.emberstoneNode,EMBERDEEP_ART.nodes,'emberstone');EMBERDEEP_ART.nodes.sunslag=loadProductionImage(EMBERDEEP_PATHS.sunslagNode,EMBERDEEP_ART.nodes,'sunslag');
  EMBERDEEP_ART.wallHints.emberstone=loadProductionImage(EMBERDEEP_PATHS.emberstoneWall,EMBERDEEP_ART.wallHints,'emberstone');EMBERDEEP_ART.wallHints.sunslag=loadProductionImage(EMBERDEEP_PATHS.sunslagWall,EMBERDEEP_ART.wallHints,'sunslag');
  EMBERDEEP_ART.nodes.moonglass=MOONGLASS_ART.nodes.moonglass;EMBERDEEP_ART.wallHints.moonglass=MOONGLASS_ART.wallHints.moonglass;
  EMBERDEEP_ART.barriers.ember_bulkhead=loadProductionImage(EMBERDEEP_PATHS.cinderBulkhead,EMBERDEEP_ART.barriers,'ember_bulkhead');EMBERDEEP_ART.barriers.ember_crucible_lock=loadProductionImage(EMBERDEEP_PATHS.crucibleSeal,EMBERDEEP_ART.barriers,'ember_crucible_lock');
  MOLTEN_ART.floor=loadProductionImage(MOLTEN_PATHS.floor,MOLTEN_ART,'floor','floorPattern');
  for(const [key,path] of [['wall',MOLTEN_PATHS.wall],['shaft',MOLTEN_PATHS.shaft],['sellStation',MOLTEN_PATHS.sellStation],['drillForge',MOLTEN_PATHS.drillForge],['pocket',MOLTEN_PATHS.pocket]])MOLTEN_ART[key]=loadProductionImage(path,MOLTEN_ART,key);
  MOLTEN_ART.rewards.cache=loadProductionImage(MOLTEN_PATHS.cache,MOLTEN_ART.rewards,'cache');MOLTEN_ART.rewards.shrine=loadProductionImage(MOLTEN_PATHS.shrine,MOLTEN_ART.rewards,'shrine');
  for(const [type,path] of [['magmaite',MOLTEN_PATHS.magmaiteNode],['deepstone',MOLTEN_PATHS.deepstoneNode],['furnaceheart',MOLTEN_PATHS.furnaceheartNode],['infernium',MOLTEN_PATHS.inferniumNode]])MOLTEN_ART.nodes[type]=loadProductionImage(path,MOLTEN_ART.nodes,type);
  for(const [type,path] of [['magmaite',MOLTEN_PATHS.magmaiteWall],['deepstone',MOLTEN_PATHS.deepstoneWall],['furnaceheart',MOLTEN_PATHS.furnaceheartWall],['infernium',MOLTEN_PATHS.inferniumWall]])MOLTEN_ART.wallHints[type]=loadProductionImage(path,MOLTEN_ART.wallHints,type);
  STARFALL_ART.floor=loadProductionImage(STARFALL_PATHS.floor,STARFALL_ART,'floor','floorPattern');
  for(const [key,path] of [['wall',STARFALL_PATHS.wall],['routeMarker',STARFALL_PATHS.routeMarker],['pocket',STARFALL_PATHS.pocket]])STARFALL_ART[key]=loadProductionImage(path,STARFALL_ART,key);
  STARFALL_ART.rewards.cache=loadProductionImage(STARFALL_PATHS.cache,STARFALL_ART.rewards,'cache');STARFALL_ART.rewards.shrine=loadProductionImage(STARFALL_PATHS.shrine,STARFALL_ART.rewards,'shrine');
  STARFALL_ART.nodes.astralite=loadProductionImage(STARFALL_PATHS.astraliteNode,STARFALL_ART.nodes,'astralite');STARFALL_ART.nodes.crownstone=loadProductionImage(STARFALL_PATHS.crownstoneNode,STARFALL_ART.nodes,'crownstone');
  STARFALL_ART.wallHints.astralite=loadProductionImage(STARFALL_PATHS.astraliteWall,STARFALL_ART.wallHints,'astralite');STARFALL_ART.wallHints.crownstone=loadProductionImage(STARFALL_PATHS.crownstoneWall,STARFALL_ART.wallHints,'crownstone');
  STARFALL_ART.nodes.emberstone=EMBERDEEP_ART.nodes.emberstone;STARFALL_ART.wallHints.emberstone=EMBERDEEP_ART.wallHints.emberstone;
  STARFALL_ART.barriers.star_bridge_lock=loadProductionImage(STARFALL_PATHS.astralBridgeLock,STARFALL_ART.barriers,'star_bridge_lock');STARFALL_ART.barriers.star_crown_lock=loadProductionImage(STARFALL_PATHS.crownstoneWard,STARFALL_ART.barriers,'star_crown_lock');
  VOIDSTAR_ART.floor=loadProductionImage(VOIDSTAR_PATHS.floor,VOIDSTAR_ART,'floor','floorPattern');
  for(const [key,path] of [['wall',VOIDSTAR_PATHS.wall],['shaft',VOIDSTAR_PATHS.shaft],['sellStation',VOIDSTAR_PATHS.sellStation],['drillForge',VOIDSTAR_PATHS.drillForge],['pocket',VOIDSTAR_PATHS.pocket]])VOIDSTAR_ART[key]=loadProductionImage(path,VOIDSTAR_ART,key);
  VOIDSTAR_ART.rewards.cache=loadProductionImage(VOIDSTAR_PATHS.cache,VOIDSTAR_ART.rewards,'cache');VOIDSTAR_ART.rewards.shrine=loadProductionImage(VOIDSTAR_PATHS.shrine,VOIDSTAR_ART.rewards,'shrine');
  for(const [type,path] of [['voidglass',VOIDSTAR_PATHS.voidglassNode],['deepstone',VOIDSTAR_PATHS.deepstoneNode],['singularity',VOIDSTAR_PATHS.singularityNode]])VOIDSTAR_ART.nodes[type]=loadProductionImage(path,VOIDSTAR_ART.nodes,type);
  for(const [type,path] of [['voidglass',VOIDSTAR_PATHS.voidglassWall],['deepstone',VOIDSTAR_PATHS.deepstoneWall],['singularity',VOIDSTAR_PATHS.singularityWall]])VOIDSTAR_ART.wallHints[type]=loadProductionImage(path,VOIDSTAR_ART.wallHints,type);
  PLAYER_ART.base=loadPlayerImage('assets/characters/miner-b.png','base');
  PLAYER_ART.walkSheets.base=loadPlayerWalkImage('base');
  for(const [key,path] of Object.entries(PLAYER_TOOL_PATHS))PLAYER_ART.tools[key]=loadPlayerImage(path,key,'tool');
  for(const [key,path] of Object.entries(PLAYER_DRILL_CHARACTER_PATHS))PLAYER_ART.drillCharacters[key]=loadPlayerImage(path,key,'drillCharacter');
  const viewport=document.getElementById('viewport');
  const goldValue=document.getElementById('goldValue');
  const cargoValue=document.getElementById('cargoValue');
  const areaName=document.getElementById('areaName');
  const areaBanner=document.getElementById('areaBanner');
  const areaBannerName=document.getElementById('areaBannerName');
  const objective=document.getElementById('objective');
  const objectiveText=document.getElementById('objectiveText');
  const objectiveDetail=document.getElementById('objectiveDetail');
  const objectiveRequirements=document.getElementById('objectiveRequirements');
  const focusMeter=document.getElementById('focusMeter');
  const focusCount=document.getElementById('focusCount');
  const heatMeter=document.getElementById('heatMeter');
  const heatFill=document.getElementById('heatFill');
  const heatValue=document.getElementById('heatValue');
  const contextPanel=document.getElementById('contextPanel');
  const contextIcon=document.getElementById('contextIcon');
  const contextIconImage=document.getElementById('contextIconImage');
  const contextEyebrow=document.getElementById('contextEyebrow');
  const contextTitle=document.getElementById('contextTitle');
  const contextDetail=document.getElementById('contextDetail');
  const contextButton=document.getElementById('contextButton');
  const contextActions=document.getElementById('contextActions');
  const contextSecondaryButton=document.getElementById('contextSecondaryButton');
  const starforgeChoices=document.getElementById('starforgeChoices');
  const mineButton=document.getElementById('mineButton');
  const mineToolIcon=document.getElementById('mineToolIcon');
  const mineAction=document.getElementById('mineAction');
  const mineHint=document.getElementById('mineHint');
  const joystick=document.getElementById('joystick');
  const joystickKnob=document.getElementById('joystickKnob');
  const pickaxeName=document.getElementById('pickaxeName');
  const toolIcon=document.getElementById('toolIcon');
  const toolKind=document.getElementById('toolKind');
  const powerValue=document.getElementById('powerValue');
  const speedValue=document.getElementById('speedValue');
  const unlockFill=document.getElementById('unlockFill');
  const unlockLabel=document.getElementById('unlockLabel');
  const toast=document.getElementById('toast');
  const menuButton=document.getElementById('menuButton');
  const menuShade=document.getElementById('menuShade');
  const menuTitle=document.getElementById('menuTitle');
  const menuCloseButton=document.getElementById('menuCloseButton');
  const settingsTab=document.getElementById('settingsTab');
  const statsTab=document.getElementById('statsTab');
  const settingsPanel=document.getElementById('settingsPanel');
  const statsPanel=document.getElementById('statsPanel');
  const achievementsPanel=document.getElementById('achievementsPanel');
  const patchNotesButton=document.getElementById('patchNotesButton');
  const patchNotesPanel=document.getElementById('patchNotesPanel');
  const patchNotesList=document.getElementById('patchNotesList');
  const achievementCount=document.getElementById('achievementCount');
  const achievementList=document.getElementById('achievementList');
  const achievementPopup=document.getElementById('achievementPopup');
  const achievementPopupImage=document.getElementById('achievementPopupImage');
  const achievementAnnouncement=document.getElementById('achievementAnnouncement');
  const heatTutorialShade=document.getElementById('heatTutorialShade');
  const heatTutorialButton=document.getElementById('heatTutorialButton');
  heatTutorialShade.hidden=true;
  const hubTutorialShade=document.getElementById('hubTutorialShade');
  const hubTutorialButton=document.getElementById('hubTutorialButton');
  const hubBuildToolbar=document.getElementById('hubBuildToolbar');
  const hubBuildHint=document.getElementById('hubBuildHint');
  const hubBuildWall=document.getElementById('hubBuildWall');
  const hubBuildLamp=document.getElementById('hubBuildLamp');
  const hubBuildStorage=document.getElementById('hubBuildStorage');
  const hubBuildErase=document.getElementById('hubBuildErase');
  const hubBuildWallCost=document.getElementById('hubBuildWallCost');
  const hubBuildLampCost=document.getElementById('hubBuildLampCost');
  const hubBuildStorageCost=document.getElementById('hubBuildStorageCost');
  hubTutorialShade.hidden=true;hubBuildToolbar.hidden=true;
  const musicToggle=document.getElementById('musicToggle');
  const effectsToggle=document.getElementById('effectsToggle');
  const resetProgressButton=document.getElementById('resetProgressButton');
  const resumeButton=document.getElementById('resumeButton');
  const startScreen=document.getElementById('startScreen');
  const continueButton=document.getElementById('continueButton');
  const continueDetail=document.getElementById('continueDetail');
  const newGameButton=document.getElementById('newGameButton');
  const startAchievementsButton=document.getElementById('startAchievementsButton');
  const startAchievementsDetail=document.getElementById('startAchievementsDetail');
  const startSettingsButton=document.getElementById('startSettingsButton');
  const inventoryButton=document.getElementById('inventoryButton');
  const inventoryShade=document.getElementById('inventoryShade');
  const inventoryCloseButton=document.getElementById('inventoryCloseButton');
  const inventoryTotal=document.getElementById('inventoryTotal');
  const inventoryTypes=document.getElementById('inventoryTypes');
  const inventoryGrid=document.getElementById('inventoryGrid');
  const autoSortButton=document.getElementById('autoSortButton');
  const autoSortHint=document.getElementById('autoSortHint');
  const buyChestButton=document.getElementById('buyChestButton');
  const buyChestCost=document.getElementById('buyChestCost');
  const baseModuleList=document.getElementById('baseModuleList');

  const BUILD={version:'0.38.1',name:'UNDERGROUND HUB'};
  const PATCH_NOTES=[
    {version:'0.38.1',date:'16 AUG 2026',title:'Crownseeker Reforged',items:['Crownseeker now has a bold three-point crown, a large Crownstone core, and one dark mining beak, making its silhouette unmistakable beside the Ember Pickaxe.','This is a visual reforge only; its stats, recipe, and progression are unchanged.']},
    {version:'0.38.0',date:'16 AUG 2026',title:'Underground Hub',items:['Conquering Voidstar now unlocks a permanent Underground Hub and a new lift in Starfall.','The safe Hub has a touch-first build mode: drag to place stone wall panels, add gold-powered lamps, place functional storage, or remove everything without losing materials.','Hub construction, storage contents, exact placement, and your full expedition persist with no prestige reset. The Deep elevator is installed but remains offline for the next phase.']},
    {version:'0.37.5',date:'16 AUG 2026',title:'Heat Streak',items:['Ember Mastery 5 now unlocks Heat Streak.','Holding Mine through a continuous run gradually accelerates pickaxe mining up to 1.30x speed; releasing Mine resets the bonus.','A one-time unlock tutorial explains the new ability as soon as the final Ember rank is reforged.']},
    {version:'0.37.4',date:'16 AUG 2026',title:'Aligned Gates',items:['All three world gates now use new premium assets painted in the same high three-quarter perspective as their biome cliffs.','Gate structures run north-to-south with the wall while the passage reads clearly from west to east.','The old front-facing silhouette, duplicate canvas light seam, and pasted-on shadow are gone.']},
    {version:'0.37.3',date:'16 AUG 2026',title:'Gate Awakening',items:['Every world gate now answers activation with a brief light through its premium silhouette, then shakes loose before sinking into the ground.','Gates keep their full painted proportions throughout the sequence instead of being squashed flat, and the permanent passage art appears only as the gate clears it.','The passage remains physically locked until the gate is fully below ground; Reduced Motion preserves the readable sink while removing flashes and shaking.']},
    {version:'0.37.2',date:'16 AUG 2026',title:'Mining Clarity',items:['Four dedicated premium mining sheets now throw compact Mossvein chips, Moonglass splinters, Emberdeep fragments, and Starfall shards without circular silhouettes.','Fast drills no longer stack multiple impact animations on the same target.','Routine damage, shell, tunnel, pickup, and partial-vein text has been removed; only meaningful discoveries and completion beats claim the center of the action.']},
    {version:'0.37.1',date:'16 AUG 2026',title:'Premium Impacts',items:['Routine mining now uses only the biome-specific premium response sheets; the old canvas rings and procedural debris are gone.','Redundant canvas bursts were also removed from discoveries, veins, chests, upgrades, gates, pickups, and module placement where sound, text, state changes, or production art already communicate the event.','Sold materials now travel to the exchange as their real premium drop assets instead of generic glowing circles.','Gameplay-critical targeting, health, timed-vein, lighting, and readable text overlays remain unchanged.']},
    {version:'0.37.0',date:'16 AUG 2026',title:'World in Motion',items:['Every biome now has its own premium environmental drift: Mossvein spores, Moonglass wisps, Emberdeep ash, and Starfall void motes.','Footsteps disturb the ground with biome-specific animated reactions instead of generic canvas dust.','Mining and drilling now wake the surrounding terrain with restrained impact responses that remain beneath cave lighting.','All eight new four-frame sprite sheets are world-anchored, deterministic, mobile-budgeted, and Reduced Motion safe.']},
    {version:'0.36.4',date:'16 AUG 2026',title:'Natural Recovery',items:['Startled creatures now flee continuously from their current route position instead of resetting every frame.','Stopping the drill sends each creature smoothly back toward its patrol route without teleporting.','Reaction and recovery motion stays collision-safe in every cave.']},
    {version:'0.36.3',date:'16 AUG 2026',title:'Steady Wildlife',items:['Mine residents closest to the player now keep their render slot as the camera moves.','Approaching an ambient creature can no longer make it disappear and reappear.','Creature limits and collision-safe routes remain unchanged for mobile performance.']},
    {version:'0.36.2',date:'16 AUG 2026',title:'Wild Instincts',items:['Ambient creatures now pause and rest naturally at both ends of their routes.','Nearby mining startles residents into a quick retreat along their safe patrol path.','Resting creatures stop their animation while startled creatures move and flap faster without entering walls.']},
    {version:'0.36.1',date:'16 AUG 2026',title:'Roaming Wilds',items:['Ambient creatures now follow clearly visible routes instead of hovering in place.','Flying creatures patrol broad loops while Cinder Skinks scurry across the ground.','Every cave route is sampled against terrain and permanent walls before movement begins.']},
    {version:'0.36.0',date:'16 AUG 2026',title:'Living Worlds',items:['Four premium animated creatures now inhabit Mossvein, Moonglass, Emberdeep, and Starfall.','Surface trails and caves use deterministic ambient paths, with occasional biome crossings that never alter collision or progression.','Reduced Motion freezes every creature cleanly, while strict draw budgets keep mobile performance steady.']},
    {version:'0.35.11',date:'16 AUG 2026',title:'Drill Age Pacing',items:['The journey from Starforge to Deepcore now spans full expeditions through Rootwound, Prismatic, and Molten Depths.','Burrower now costs 5,000 gold, 50 Rootiron, and 5 Ambercore; Pulse costs 12,000 gold, 60 Burrowsteel, 40 Prismite, and 4 Lunacore.','Deepcore now costs 25,000 gold, 70 Phase Crystal, 50 Magmaite, 5 Furnace Heart, and 70 Infernium.']},
    {version:'0.35.10',date:'16 AUG 2026',title:'Clear Requirement',items:['The locked Voidstar entrance now says DEEPCORE DRILL REQUIRED.','The requirement can no longer be mistaken for a separate material called Deepcore.','Progression and the Deepcore Drill recipe are unchanged.']},
    {version:'0.35.9',date:'16 AUG 2026',title:'Clear Veins',items:['Generated mine veins now keep a full node-width margin from every permanent wall.','Eight unreachable Astralite nodes were removed from the Starfall deep-access wall.','The safety rule applies to every mine without changing vein totals or resource balance.']},
    {version:'0.35.8',date:'16 AUG 2026',title:'Ember Ramp',items:['Ember Mastery Sunslag recipes now rise through 30, 40, 50, 60, and 70.','The full mastery climb now costs 250 Sunslag instead of 500, removing the flat midgame grind.','Power, speed, yield bonuses, gold costs, and Starforge requirements are unchanged.']},
    {version:'0.35.7',date:'16 AUG 2026',title:'Quiet Misses',items:['Holding Mine without a valid target is now silent instead of repeating the empty-hit sound.','A fresh manual press still gives one short miss response so the control never feels broken.','Successful pickaxe tink and drill impact sounds are unchanged.']},
    {version:'0.35.6',date:'16 AUG 2026',title:'Visible Wall Fit',items:['Surface wall collision now matches the actual painted width of each premium boundary PNG.','The oversized invisible strip beside opened gates is removed while the visible cliff remains solid.','Closed gates still block across their full portal footprint.']},
    {version:'0.35.5',date:'15 AUG 2026',title:'Pickaxe Tink',items:['Pickaxe mining now lands with a short, bright metallic tink instead of the previous heavy synthetic impact.','Repeated swings form a clean tink-tink-tink rhythm, while drills retain their separate heavier sound.','Material and pickaxe tier still add subtle pitch variation without muddying the hit.']},
    {version:'0.35.4',date:'15 AUG 2026',title:'Passage Fit',items:['Opened-gate floor marks now fill the complete passage using the visible bounds of their premium PNGs.','Boundary collision now follows each painted cliff edge, so the miner can no longer stand inside the rock face.','Closed gates block across their full visual footprint while remaining easy to approach and open.']},
    {version:'0.35.3',date:'15 AUG 2026',title:'Integrated Gates',items:['Biome boundary PNGs now render their complete hand-painted natural openings instead of hard rectangular crops.','All three premium gates are larger and seated directly inside their matching rock passage.','Gate collision, costs, sinking transitions, and progression are unchanged.']},
    {version:'0.35.2',date:'15 AUG 2026',title:'Bedrock Language',items:['Every first-depth mine now has a dedicated premium unbreakable-wall PNG.','Permanent walls use massive continuous bedrock while mineable terrain keeps smaller chipped forms, damage cracks, and target feedback.','Collision and mine routes are unchanged; the visual rule now matches the gameplay rule.']},
    {version:'0.35.1',date:'15 AUG 2026',title:'Premium Gatewalls',items:['Three dedicated production PNGs now form the world boundaries around their gates.','Deep-access shelves use each mine biome’s existing premium wall art with no procedural face overlay.','World gates remain the only safe passage; gameplay and progression are unchanged.']},
    {version:'0.35.0',date:'15 AUG 2026',title:'Gatebound Depths',items:['Physical biome walls now make each world gate the only surface passage.','Every mine now routes the deep descent behind its final ore barrier.','Stronger wall faces separate open tunnels from solid mountain in every biome.','Achievement reliquaries now spin smoothly on iPhone and settle cleanly.']},
    {version:'0.34.7',date:'15 AUG 2026',title:'Safer Foundations',items:['Static world, balance, equipment, discovery, and achievement data now live in a dedicated module.','Automated guards now lock module order, test contracts, and every static gameplay value.','Gameplay, balance, progression, controls, and visuals are unchanged.']},
    {version:'0.34.6',date:'15 AUG 2026',title:'Fresh Expedition',items:['Reset All Progress is available in Settings again.','The reset clears both the expedition save and every achievement record.']},
    {version:'0.34.5',date:'15 AUG 2026',title:'Achievement Spotlight',items:['Tapping a new achievement now opens the achievement list.','The newly earned record scrolls into view and lights up.']},
    {version:'0.34.4',date:'15 AUG 2026',title:'Readable Cave Text',items:['All cave text now renders above the lighting pass.','Labels remain readable without aiming the mining helmet at them.']},
    {version:'0.34.3',date:'15 AUG 2026',title:'Free-Move Controls',items:['The movement joystick now appears wherever you press in the playfield.','Movement and mining remain independent for smooth two-thumb control.']},
    {version:'0.34.2',date:'15 AUG 2026',title:'News from the Depths',items:['Patch Notes now live inside Settings.','Browse the latest changes without leaving the game.']},
    {version:'0.34.1',date:'15 AUG 2026',title:'Ember & Starforge Pacing',items:['Ember Pickaxe now requires 100 Emberstone.','Each Ember Mastery rank now requires 100 Sunslag.','Each Starforge form requires 200 Astralite and 200 Crownstone.']},
    {version:'0.34.0',date:'15 AUG 2026',title:'Achievement Reliquaries',items:['50 achievements added across the full expedition.','New unlocks appear as spinning reliquaries above the miner.','Every achievement records why, when and where it was earned.']}
  ];
  document.getElementById('buildVersion').textContent='v'+BUILD.version;
  document.getElementById('menuBuildVersion').textContent='EVER DEEPER v'+BUILD.version+' · '+BUILD.name;

  const GAME_DATA=window.EverDeeperGameData;
  if(!GAME_DATA||typeof GAME_DATA!=='object')throw new Error('Ever Deeper requires game-data.js to load before script.js.');
  const {
    WORLD,HUB_WORLD,HUB_GRID,HUB_STATIONS,HUB_BUILD_COSTS,MINE_DEFINITIONS,MINE_SCENES,MINE_DEPTH_PROFILES,DEPTH2_RESOURCE_PROFILES,DEPTH_ROUTE_LABELS,MINE_DIRT_COLORS,BIOMES,SURFACE_BOUNDARIES,
    SAVE_KEY,ACHIEVEMENTS_KEY,GATE_COST,EMBER_GATE_COST,STARFORGE_MATERIAL_REQUIRED,EMBER_PICKAXE_ORE_REQUIRED,GROUND_DROP_LIFETIME,
    LOOT_SWEEP_WARNING_SECONDS,GROUND_DROP_PICKUP_RADIUS,GROUND_DROP_EDGE_X,GROUND_DROP_EDGE_TOP,GROUND_DROP_EDGE_BOTTOM,BASE_MODULE_INTERACT_RADIUS,AUTO_SORT_RADIUS,
    STORAGE_CHEST_CAPACITY,MAX_GROUND_DROPS,EMBER_MASTERY,MINING_RANGE,MINE_TILE_SIZE,MINERAL_NODE_RENDER_SCALE,MINE_CHUNK_CELLS,MINE_TERRAIN_HP,
    PLAYER_SPEED,PLAYER_MOVE_STEP,MOVEMENT_SPEED_GAIN,MINING_RUSH_DURATION,MINING_RUSH_COOLDOWN_MULTIPLIER,ROCK_TYPES,COIN_DROP,MINE_DISCOVERY_PROFILES,seededRandom,
    newWorldSeed,MINE_DISCOVERIES,MINE_DEPTH_DISCOVERIES,discoveriesFor,PICKAXES,STARFORGE_VARIANTS,DRILLS,DRILL_RECIPES,STATIONS,CHEST_DEFINITIONS,CHEST_INTERACT_RADIUS,
    ROCK_LAYOUT,VEIN_DEFINITIONS,VEIN_ROCK_LAYOUT,ACHIEVEMENT_DEFINITIONS,ACHIEVEMENT_BY_ID,ACHIEVEMENT_REASONS
  }=GAME_DATA;

  let width=800,height=600,viewZoom=.86,viewWidth=930,viewHeight=698,dpr=1,lastFrame=0,time=0,timeScale=1,toastTimer=0,bannerTimer=0;
  const reducedMotionQuery=typeof window.matchMedia==='function'?window.matchMedia('(prefers-reduced-motion: reduce)'):null;
  let reducedMotion=!!(reducedMotionQuery&&reducedMotionQuery.matches);
  if(reducedMotionQuery){const updateReducedMotion=event=>{reducedMotion=!!event.matches};if(typeof reducedMotionQuery.addEventListener==='function')reducedMotionQuery.addEventListener('change',updateReducedMotion);else if(typeof reducedMotionQuery.addListener==='function')reducedMotionQuery.addListener(updateReducedMotion)}
  const audioSettings=loadAudioSettings();
  let audioContext=null,audioUnlocked=false,impactNoiseBuffer=null,backgroundMusic=null,musicStarted=false;
  let floaters=[],groundDrops=[],terrainResponses=[];
  let moonglassGateTransition=null,emberdeepGateTransition=null,starfallGateTransition=null;
  let saleMotes=[];
  const AMBIENT_FLEE_DURATION=.68,AMBIENT_RECOVERY_DURATION=1.35;
  const ambientDisturbance={scene:null,depth:1,x:0,y:0,startX:0,startY:0,active:false,startedAt:0,releasedAt:0,activeDuration:0,remaining:0};
  let activeContext=null,uiDirty=true,lastSavedSnapshot='',lastRegion=-1,nextDropId=1,nextTerrainResponseId=1,terrainSaveDelay=0,lootSweepCheck=0,lootSweepWarned30=false,lootSweepWarned10=false,lastTerrainImpactAt=-Infinity;
  const miningFeedback={shake:0,shakeTime:0,flash:0,flashColor:'#ffffff',hitStop:0,terrainHitIndex:-1,terrainHitTime:0,lastDiscovery:null,lastDepositBeat:null,lastPocketReward:null};
  let lastHapticAt=-1;
  const pickupBatch={items:Object.create(null),count:0,quiet:0,x:0,y:0,bestType:null};

  const input={keys:new Set(),moveX:0,moveY:0,joystickPointer:null,joystickOriginX:0,joystickOriginY:0,minePointers:new Set(),mineHeld:false};
  const hubBuild={active:false,selected:'wall',pointerId:null,lastCell:null,changed:false,singlePlaced:false,preview:null};
  const camera={x:0,y:0};
  const player={x:330,y:690,radius:23,facing:1,aimX:1,aimY:0,walk:0,walkPhase:0,walkDistance:0,walkFrame:0,direction:'right',moving:false,swing:null,swingCooldown:0,hitRockId:null,hitTerrainIndex:-1};
  const miningFocus={streak:0,timer:0};
  const miningRush={timer:0,lastSecond:0};
  const HEAT_STREAK_BUILD_SECONDS=5,HEAT_STREAK_MAX_SPEED=1.3;
  const heatStreak={elapsed:0,active:false,lastPercent:-1};
  let loadedExistingSave=false;
  const state=loadState();
  let currentScene=state.location.scene;
  let currentDepth=currentScene==='surface'?1:state.location.depth;
  let achievementProgress=null,achievementQueue=[],activeAchievementId=null,highlightedAchievementId=null,achievementPopupSettled=false,achievementSettleTimer=0,achievementCheckTimer=0,achievementListDirty=true;
  player.x=state.location.x;player.y=state.location.y;
  let displayedGold=state.gold,goldTween=null;
  let depthEntrances=createDepthEntrances();
  const surfaceRocks=ROCK_LAYOUT.concat(VEIN_ROCK_LAYOUT).map((entry,index)=>({
    id:index+1,type:entry[0],x:entry[1],y:entry[2],hp:ROCK_TYPES[entry[0]].hp,maxHp:ROCK_TYPES[entry[0]].hp,
    shell:ROCK_TYPES[entry[0]].shell||0,maxShell:ROCK_TYPES[entry[0]].shell||0,
    scene:'surface',veinId:entry[3]||null,barrierId:null,requiredPickaxe:1,respawn:0,hit:0,broken:false,seed:(index*47)%97,glintTimer:1.5+(index%5)*.48,glintActive:0,bonusYield:0
  }));
  let mineRockIndex=0;
  const mineRocks=MINE_SCENES.flatMap(scene=>{
    const mine=MINE_DEFINITIONS[scene];
    const entries=mine.rocks.map(entry=>({entry,depth:1})).concat(MINE_DISCOVERIES[scene].rocks.map(entry=>({entry,depth:1})),MINE_DEPTH_DISCOVERIES[scene].rocks.map(entry=>({entry,depth:2})));
    return entries.map(wrapper=>{
      const entry=wrapper.entry,depth=wrapper.depth;
      const generated=!Array.isArray(entry),type=generated?entry.type:entry[0],barrierId=generated?null:entry[3]||null;
      const barrier=barrierId?mine.barriers.find(item=>item.id===barrierId):null,index=mineRockIndex++,data=ROCK_TYPES[type],shell=generated?(data.shell||0):0;
      return{id:1000+index,type,x:generated?entry.x:entry[1],y:generated?entry.y:entry[2],hp:data.hp,maxHp:data.hp,
        shell,maxShell:shell,scene,depth,veinId:null,depositId:generated?entry.depositId:null,cavernId:generated?entry.cavernId||null:null,rareFind:generated&&!!entry.rareFind,pocketRewardId:generated?entry.pocketRewardId||null:null,
        barrierId,requiredPickaxe:generated?entry.requiredPickaxe:barrier?barrier.requiresPickaxe:1,requiresDeepTool:generated&&!!entry.requiresDeepTool,requiresDrillLevel:generated?entry.requiresDrillLevel||0:0,
        respawn:0,hit:0,broken:false,seed:(index*53)%97,glintTimer:1.5+(index%5)*.48,glintActive:0,bonusYield:0};
    });
  });
  const rocks=surfaceRocks.concat(mineRocks);
  const rocksByLocation=new Map([['surface:1',surfaceRocks]]);
  for(const scene of MINE_SCENES)for(const depth of [1,2])rocksByLocation.set(scene+':'+depth,mineRocks.filter(rock=>rock.scene===scene&&rock.depth===depth));
  for(const rock of mineRocks)if(rock.barrierId&&state.clearedMineBarriers[rock.barrierId]){rock.broken=true;rock.respawn=Infinity}
  for(const rock of mineRocks)if(rock.pocketRewardId&&state.claimedPocketRewards[rock.pocketRewardId]){rock.broken=true;rock.respawn=Infinity}
  const mineTerrain=Object.fromEntries(MINE_SCENES.map(scene=>[scene,{1:createMineTerrain(scene,1),2:createMineTerrain(scene,2)}]));
  const mineRocksByTerrainCell=new Map(),mineRocksByCavern=new Map();
  for(const rock of mineRocks){
    if(rock.barrierId)continue;
    const terrain=mineTerrain[rock.scene][rock.depth||1],col=Math.floor(rock.x/MINE_TILE_SIZE),row=Math.floor(rock.y/MINE_TILE_SIZE),cellKey=rock.scene+':'+(rock.depth||1)+':'+(row*terrain.cols+col);
    if(!mineRocksByTerrainCell.has(cellKey))mineRocksByTerrainCell.set(cellKey,[]);
    mineRocksByTerrainCell.get(cellKey).push(rock);
    if(rock.cavernId){if(!mineRocksByCavern.has(rock.cavernId))mineRocksByCavern.set(rock.cavernId,[]);mineRocksByCavern.get(rock.cavernId).push(rock)}
  }
  const veins=VEIN_DEFINITIONS.map(definition=>({...definition,status:'idle',timer:0,displaySecond:-1,brokenRockIds:new Set()}));
  const chests=CHEST_DEFINITIONS.map(definition=>({...definition}));
  for(const [chestId,rewards] of Object.entries(state.pendingChestLoot)){
    const chest=chestById(chestId);if(!chest)continue;
    let rewardIndex=0;
    for(const [type,amount] of Object.entries(rewards))spawnGroundDrop(type,amount,chest.x+(rewardIndex++-1)*18,chest.y+18,chestId,'surface');
  }
  for(const scene of MINE_SCENES)for(const depth of [1,2])for(const cavern of discoveriesFor(scene,depth).caverns){
    const reward=cavern.reward,pending=state.pendingPocketLoot[reward.id];if(!pending)continue;
    let rewardIndex=0;for(const [type,amount] of Object.entries(pending))spawnGroundDrop(type,amount,cavern.x+(rewardIndex++-1)*18,cavern.y+12,null,scene,reward.id,depth);
  }
  if(state.nextLootSweepAt<=Date.now())performGlobalLootSweep(false);

  function emptyResourceStore(){return Object.fromEntries(Object.keys(ROCK_TYPES).map(type=>[type,0]))}

  function defaultBaseState(){
    return{
      forge:{id:'forge',kind:'forge',scene:'surface',depth:1,x:STATIONS.forge.x,y:STATIONS.forge.y,packed:false},
      sell:{id:'sell',kind:'sell',scene:'surface',depth:1,x:STATIONS.sell.x,y:STATIONS.sell.y,packed:false},
      chests:[{id:'storage-1',kind:'storage',scene:'surface',depth:1,x:335,y:390,packed:false,items:emptyResourceStore()}],
      nextChestId:2
    };
  }

  function sanitizeBaseState(raw){
    const fallback=defaultBaseState(),source=raw&&typeof raw==='object'?raw:{};
    const sanitizeModule=(value,baseModule)=>{
      const scene=value&&(['surface','hub',...MINE_SCENES].includes(value.scene))?value.scene:baseModule.scene;
      return{...baseModule,scene,depth:scene==='surface'||scene==='hub'?1:value&&value.depth===2?2:1,x:Number(value&&value.x)||baseModule.x,y:Number(value&&value.y)||baseModule.y,packed:!!(value&&value.packed)};
    };
    fallback.forge=sanitizeModule(source.forge,fallback.forge);fallback.sell=sanitizeModule(source.sell,fallback.sell);
    if(Array.isArray(source.chests)&&source.chests.length){
      fallback.chests=source.chests.map((rawChest,index)=>{
        const chest=sanitizeModule(rawChest,{id:'storage-'+(index+1),kind:'storage',scene:'surface',depth:1,x:335,y:390,packed:true}),items=emptyResourceStore();
        for(const type of Object.keys(items))items[type]=Math.max(0,Math.floor(Number(rawChest&&rawChest.items&&rawChest.items[type])||0));
        chest.id=typeof rawChest.id==='string'&&rawChest.id?rawChest.id:'storage-'+(index+1);chest.items=items;return chest;
      });
    }
    fallback.nextChestId=Math.max(fallback.chests.length+1,Math.floor(Number(source.nextChestId)||0),2);return fallback;
  }

  function defaultHubState(){
    return{unlocked:false,visited:false,tutorialSeen:false,buildTutorialSeen:false,surfaceX:HUB_STATIONS.surfaceEntrance.x,surfaceY:HUB_STATIONS.surfaceEntrance.y,tiles:[]};
  }

  function sanitizeHubState(raw,victory=false){
    const source=raw&&typeof raw==='object'?raw:{},hub=defaultHubState(),seen=new Set();
    hub.unlocked=!!victory||source.unlocked===true;hub.visited=source.visited===true;hub.tutorialSeen=source.tutorialSeen===true;hub.buildTutorialSeen=source.buildTutorialSeen===true;
    hub.surfaceX=clamp(Number(source.surfaceX)||HUB_STATIONS.surfaceEntrance.x,52,WORLD.width-52);hub.surfaceY=clamp(Number(source.surfaceY)||HUB_STATIONS.surfaceEntrance.y,70,WORLD.height-58);
    if(Array.isArray(source.tiles))for(const tile of source.tiles){
      const col=Math.floor(Number(tile&&tile.col)),row=Math.floor(Number(tile&&tile.row)),kind=tile&&tile.kind;
      if(!['wall','lamp'].includes(kind)||col<0||row<0||col>=HUB_GRID.cols||row>=HUB_GRID.rows)continue;
      const key=col+':'+row;if(seen.has(key))continue;seen.add(key);hub.tiles.push({col,row,kind});
    }
    return hub;
  }

  function defaultState(){
    return{
      gold:0,pickaxeLevel:1,emberMastery:0,heatStreakTutorialSeen:false,drillLevel:0,drillGoalScene:null,movementSpeedLevel:0,nextLootSweepAt:Date.now()+GROUND_DROP_LIFETIME*1000,areaUnlocked:false,discoveredSecond:false,emberdeepUnlocked:false,discoveredThird:false,fourthUnlocked:false,discoveredFourth:false,victory:false,
      cargo:{stone:0,copper:0,moonglass:0,gold:0,starshard:0,emberstone:0,sunslag:0,astralite:0,crownstone:0,deepstone:0,rootiron:0,ambercore:0,prismite:0,lunacore:0,magmaite:0,furnaceheart:0,voidglass:0,singularity:0,burrowsteel:0,phasecrystal:0,infernium:0},
      mined:{stone:0,copper:0,moonglass:0,gold:0,starshard:0,emberstone:0,sunslag:0,astralite:0,crownstone:0,deepstone:0,rootiron:0,ambercore:0,prismite:0,lunacore:0,magmaite:0,furnaceheart:0,voidglass:0,singularity:0,burrowsteel:0,phasecrystal:0,infernium:0},
      veinsCompleted:{copper_run:0,moonglass_bloom:0,ember_fault:0,starfall_lattice:0},
      starforgeVariant:null,starforgeUnlocked:{crusher:false,swift:false,prospector:false},
      openedChests:{},pendingChestLoot:{},claimedPocketRewards:{},pendingPocketLoot:{},
      clearedMineBarriers:{},terrainDug:{mossMine:[],moonMine:[],emberMine:[],starMine:[],mossMineDepth2:[],moonMineDepth2:[],emberMineDepth2:[],starMineDepth2:[]},discoveredCaverns:{},discoveredDepthEntrances:{},visitedDepths:{},mineDiscovered:false,discoveredMines:{mossMine:false,moonMine:false,emberMine:false,starMine:false},
      base:defaultBaseState(),
      hub:defaultHubState(),
      worldSeed:newWorldSeed(),location:{scene:'surface',depth:1,x:330,y:690,surfaceX:330,surfaceY:690},
      totalGold:0,totalSwings:0,precisionHits:0
    };
  }

  function parseStoredState(serialized){
    try{return JSON.parse(serialized||'null')}catch(error){return null}
  }

  function loadAudioSettings(){
    try{
      const stored=parseStoredState(localStorage.getItem(AUDIO_SETTINGS_KEY));
      return{music:stored&&typeof stored.music==='boolean'?stored.music:true,effects:stored&&typeof stored.effects==='boolean'?stored.effects:true};
    }catch(error){return{music:true,effects:true}}
  }

  function persistAudioSettings(){
    try{localStorage.setItem(AUDIO_SETTINGS_KEY,JSON.stringify(audioSettings))}catch(error){}
  }


  function defaultAchievementProgress(){return{version:1,nextOrder:1,records:{}}}

  function loadAchievementProgress(){
    const fallback=defaultAchievementProgress();
    try{
      const raw=parseStoredState(localStorage.getItem(ACHIEVEMENTS_KEY));if(!raw||typeof raw!=='object')return fallback;
      const source=raw.records&&typeof raw.records==='object'?raw.records:{},records={};let maxOrder=0;
      for(const definition of ACHIEVEMENT_DEFINITIONS){
        const record=source[definition.id];if(!record||typeof record!=='object')continue;
        const parsedTime=Date.parse(record.timestamp),order=Math.max(1,Math.floor(Number(record.order)||maxOrder+1));maxOrder=Math.max(maxOrder,order);
        const retroactive=record.retroactive===true;
        records[definition.id]={id:definition.id,timestamp:Number.isFinite(parsedTime)?new Date(parsedTime).toISOString():new Date().toISOString(),reason:typeof record.reason==='string'&&record.reason?record.reason:ACHIEVEMENT_REASONS[definition.id],scene:retroactive?null:['surface','hub',...MINE_SCENES].includes(record.scene)?record.scene:'surface',depth:retroactive?null:record.depth===2?2:1,order,acknowledged:record.acknowledged===true,retroactive};
      }
      return{version:1,nextOrder:Math.max(maxOrder+1,Math.floor(Number(raw.nextOrder)||1)),records};
    }catch(error){return fallback}
  }

  function persistAchievementProgress(){
    try{localStorage.setItem(ACHIEVEMENTS_KEY,JSON.stringify(achievementProgress))}catch(error){}
  }

  function achievementMetrics(progress=state){
    const totalMined=Object.values(progress.mined).reduce((total,amount)=>total+Math.max(0,Number(amount)||0),0);
    const tilesDug=Object.values(progress.terrainDug).reduce((total,indices)=>total+(Array.isArray(indices)?indices.length:0),0);
    const depthMined=Object.entries(progress.mined).reduce((total,[type,amount])=>total+(ROCK_TYPES[type]&&ROCK_TYPES[type].depth2?Math.max(0,Number(amount)||0):0),0);
    const opened=CHEST_DEFINITIONS.reduce((total,chest)=>total+Number(!!progress.openedChests[chest.id]),0);
    const veinTotal=Object.values(progress.veinsCompleted).reduce((total,count)=>total+Math.max(0,Number(count)||0),0);
    return{totalMined,tilesDug,depthMined,opened,veinTotal};
  }

  function addAchievementRecord(definition,acknowledged,timestamp,retroactive=false){
    if(achievementProgress.records[definition.id])return null;
    const record={id:definition.id,timestamp:timestamp||new Date().toISOString(),reason:ACHIEVEMENT_REASONS[definition.id],scene:retroactive?null:currentScene,depth:retroactive?null:currentScene==='surface'?1:currentDepth,order:achievementProgress.nextOrder++,acknowledged:!!acknowledged,retroactive:!!retroactive};
    achievementProgress.records[definition.id]=record;return record;
  }

  function evaluateAchievements({silent=false,timestamp=null,retroactive=false}={}){
    const metrics=achievementMetrics(),unlocked=[];
    for(const definition of ACHIEVEMENT_DEFINITIONS){
      if(achievementProgress.records[definition.id])continue;
      let earned=false;try{earned=!!definition.predicate(state,metrics)}catch(error){}
      if(!earned)continue;
      const record=addAchievementRecord(definition,silent,timestamp,retroactive);if(!record)continue;
      unlocked.push(definition.id);if(!silent)achievementQueue.push(definition.id);
    }
    if(unlocked.length){persistAchievementProgress();renderAchievementSummary();achievementListDirty=true;if(!silent)syncAchievementPopup()}
    return unlocked;
  }

  function initializeAchievements(){
    if(loadedExistingSave)evaluateAchievements({silent:true,timestamp:new Date().toISOString(),retroactive:true});
    achievementQueue=Object.values(achievementProgress.records).filter(record=>!record.acknowledged).sort((a,b)=>a.order-b.order).map(record=>record.id);
    renderAchievementSummary();syncAchievementPopup();
  }

  function escapeAchievementHtml(value){return String(value).replace(/[&<>"']/g,character=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[character]))}

  function achievementLocationLabel(record){
    if(record.scene==='surface')return'Surface';
    if(record.scene==='hub')return'Underground Hub';
    const mine=MINE_DEFINITIONS[record.scene];return record.depth===2?MINE_DEPTH_PROFILES[record.scene].name:titleCase(mine.name);
  }

  function achievementDateLabel(timestamp){
    const date=new Date(timestamp);if(!Number.isFinite(date.getTime()))return'Unknown date';
    try{return date.toLocaleString(undefined,{year:'numeric',month:'short',day:'numeric',hour:'2-digit',minute:'2-digit'})}catch(error){return date.toISOString().slice(0,16).replace('T',' ')}
  }

  function renderAchievementSummary(){
    const unlocked=Object.keys(achievementProgress.records).length,label=unlocked+' / '+ACHIEVEMENT_DEFINITIONS.length+' UNLOCKED';
    achievementCount.textContent=label;startAchievementsDetail.textContent=label;
  }

  function renderAchievementList(force=false){
    if(!force&&!achievementListDirty)return;
    achievementList.innerHTML=ACHIEVEMENT_DEFINITIONS.map((definition,index)=>{
      const record=achievementProgress.records[definition.id],earned=!!record;
      const status=earned?(record.retroactive?'IMPORTED '+achievementDateLabel(record.timestamp).toUpperCase()+' · PRE-v0.34 SAVE':'EARNED '+achievementDateLabel(record.timestamp).toUpperCase()+' · '+achievementLocationLabel(record).toUpperCase()):'LOCKED · '+definition.category.toUpperCase();
      const detail=earned?(record.retroactive?record.reason+' Exact original unlock time was not recorded.':record.reason):'How to earn: '+definition.description;
      return'<article class="achievement-entry '+(earned?'unlocked':'locked')+'" data-tier="'+definition.tier+'" data-achievement="'+definition.id+'"><div class="achievement-index">'+String(index+1).padStart(2,'0')+'</div><div class="achievement-art"><img src="'+definition.asset+'?v='+ASSET_VERSION+'" alt="" loading="lazy" aria-hidden="true"></div><div class="achievement-copy"><div><h4>'+escapeAchievementHtml(definition.title)+'</h4><span>'+escapeAchievementHtml(status)+'</span></div><p>'+escapeAchievementHtml(detail)+'</p></div></article>';
    }).join('');achievementListDirty=false;
  }

  function canShowAchievementPopup(){return startScreen.hidden&&menuShade.hidden&&inventoryShade.hidden&&heatTutorialShade.hidden&&hubTutorialShade.hidden}

  function positionAchievementPopup(){
    if(achievementPopup.hidden)return;
    const screen=worldToScreen(player.x,player.y),screenWidth=viewport.clientWidth||width,screenHeight=viewport.clientHeight||height;
    const left=clamp(screen.x*viewZoom,58,Math.max(58,screenWidth-58)),top=clamp(screen.y*viewZoom-105,62,Math.max(62,screenHeight-128));
    achievementPopup.style.transform='translate3d('+Math.round(left)+'px,'+Math.round(top)+'px,0) translate(-50%,-50%)';
  }

  function syncAchievementPopup(){
    if(!canShowAchievementPopup()){achievementPopup.hidden=true;return}
    if(activeAchievementId){const wasHidden=achievementPopup.hidden;achievementPopup.hidden=false;if(wasHidden&&!achievementPopupSettled){achievementPopup.classList.remove('spinning');void achievementPopup.offsetWidth;achievementPopup.classList.add('spinning');clearTimeout(achievementSettleTimer);achievementSettleTimer=setTimeout(settleAchievementPopup,reducedMotion?450:2900)}positionAchievementPopup();return}
    while(achievementQueue.length&&achievementProgress.records[achievementQueue[0]]&&achievementProgress.records[achievementQueue[0]].acknowledged)achievementQueue.shift();
    const id=achievementQueue[0],definition=ACHIEVEMENT_BY_ID[id];if(!definition){achievementPopup.hidden=true;return}
    activeAchievementId=id;achievementPopupSettled=false;achievementPopup.dataset.achievement=id;achievementPopup.dataset.settled='false';achievementPopupImage.src=definition.asset+'?v='+ASSET_VERSION;achievementPopup.setAttribute('aria-label',definition.title+' unlocked. Wait for the reliquary to settle.');achievementPopup.setAttribute('aria-disabled','true');
    achievementPopup.hidden=false;achievementPopup.classList.remove('spinning');achievementPopup.classList.remove('settled');void achievementPopup.offsetWidth;achievementPopup.classList.add('spinning');positionAchievementPopup();sound('achievement');
    achievementAnnouncement.textContent=definition.title+' unlocked. '+definition.description;
    clearTimeout(achievementSettleTimer);achievementSettleTimer=setTimeout(settleAchievementPopup,reducedMotion?450:2900);
  }

  function settleAchievementPopup(){
    if(!activeAchievementId||achievementPopupSettled)return false;
    clearTimeout(achievementSettleTimer);achievementSettleTimer=0;achievementPopupSettled=true;achievementPopup.dataset.settled='true';achievementPopup.classList.remove('spinning');achievementPopup.classList.add('settled');achievementPopup.setAttribute('aria-disabled','false');
    const definition=ACHIEVEMENT_BY_ID[activeAchievementId];achievementPopup.setAttribute('aria-label',(definition?definition.title:'Achievement')+' unlocked. Tap to view in achievements.');return true;
  }

  function dismissAchievementPopup(){
    if(!activeAchievementId||!achievementPopupSettled)return false;
    clearTimeout(achievementSettleTimer);achievementSettleTimer=0;
    const record=achievementProgress.records[activeAchievementId];if(record)record.acknowledged=true;
    const dismissed=activeAchievementId;activeAchievementId=null;achievementPopupSettled=false;if(achievementQueue[0]===dismissed)achievementQueue.shift();else achievementQueue=achievementQueue.filter(id=>id!==dismissed);
    achievementPopup.hidden=true;achievementPopup.classList.remove('spinning');achievementPopup.classList.remove('settled');persistAchievementProgress();achievementListDirty=true;sound('coin');syncAchievementPopup();return true;
  }

  function highlightAchievementEntry(id){
    highlightedAchievementId=id;achievementList.dataset.highlightedAchievement=id;
    if(typeof achievementList.querySelectorAll==='function')achievementList.querySelectorAll('.recently-unlocked').forEach(entry=>entry.classList.remove('recently-unlocked'));
    const entry=typeof achievementList.querySelector==='function'?achievementList.querySelector('[data-achievement="'+id+'"]'):null;if(!entry)return false;
    entry.classList.remove('recently-unlocked');void entry.offsetWidth;entry.classList.add('recently-unlocked');
    const reveal=()=>{if(typeof entry.scrollIntoView==='function')entry.scrollIntoView({behavior:reducedMotion?'auto':'smooth',block:'center'})};
    if(typeof requestAnimationFrame==='function')requestAnimationFrame(reveal);else reveal();return true;
  }

  function openAchievementFromPopup(){
    if(!activeAchievementId||!achievementPopupSettled)return false;
    const id=activeAchievementId;showOverlayMenu('achievements','game');if(!dismissAchievementPopup())return false;renderAchievementList(true);highlightAchievementEntry(id);return true;
  }

  function isCompatibleLegacySave(candidate){
    return !!candidate&&typeof candidate==='object'&&Number(candidate.pickaxeLevel)>=1&&candidate.cargo&&candidate.mined&&candidate.terrainDug&&candidate.discoveredMines&&candidate.base;
  }

  function readStoredState(){
    const current=parseStoredState(localStorage.getItem(SAVE_KEY));
    if(current&&typeof current==='object')return current;
    if(typeof localStorage.key!=='function')return null;
    for(let index=0,count=Math.max(0,Number(localStorage.length)||0);index<count;index++){
      const key=localStorage.key(index);
      if(!key||key===SAVE_KEY)continue;
      const serialized=localStorage.getItem(key),candidate=parseStoredState(serialized);
      if(!isCompatibleLegacySave(candidate))continue;
      localStorage.setItem(SAVE_KEY,serialized);
      localStorage.removeItem(key);
      return candidate;
    }
    return null;
  }

  function loadState(){
    try{
      const raw=readStoredState();
      loadedExistingSave=!!raw&&typeof raw==='object';
      if(!loadedExistingSave)return defaultState();
      const base=defaultState();
      base.worldSeed=Number.isInteger(raw.worldSeed)&&raw.worldSeed>0?raw.worldSeed>>>0:base.worldSeed;
      base.gold=Math.max(0,Number(raw.gold)||0);
      base.pickaxeLevel=Math.max(1,Math.min(PICKAXES.length-1,Number(raw.pickaxeLevel)||1));
      base.emberMastery=base.pickaxeLevel===PICKAXES.length-1?Math.max(0,Math.min(EMBER_MASTERY.length-1,Number(raw.emberMastery)||0)):0;
      base.heatStreakTutorialSeen=raw.heatStreakTutorialSeen===true;
      base.drillLevel=Math.max(0,Math.min(DRILLS.length-1,Number(raw.drillLevel)||0));
      base.movementSpeedLevel=Math.max(0,Math.floor(Number(raw.movementSpeedLevel)||0));
      base.nextLootSweepAt=Number.isFinite(Number(raw.nextLootSweepAt))?Number(raw.nextLootSweepAt):base.nextLootSweepAt;
      base.areaUnlocked=!!raw.areaUnlocked;
      base.discoveredSecond=!!raw.discoveredSecond;
      base.emberdeepUnlocked=!!raw.emberdeepUnlocked;
      base.discoveredThird=!!raw.discoveredThird;
      base.fourthUnlocked=!!raw.fourthUnlocked;
      base.discoveredFourth=!!raw.discoveredFourth;
      base.victory=!!raw.victory;
      for(const key of Object.keys(base.cargo)){
        base.cargo[key]=Math.max(0,Number(raw.cargo&&raw.cargo[key])||0);
        base.mined[key]=Math.max(0,Number(raw.mined&&raw.mined[key])||0);
      }
      base.victory=base.victory||base.drillLevel===DRILLS.length-1&&base.mined.singularity>0;
      base.hub=sanitizeHubState(raw.hub,base.victory);
      base.base=sanitizeBaseState(raw.base);
      for(const key of Object.keys(base.veinsCompleted))base.veinsCompleted[key]=Math.max(0,Number(raw.veinsCompleted&&raw.veinsCompleted[key])||0);
      for(const key of Object.keys(base.starforgeUnlocked))base.starforgeUnlocked[key]=!!(raw.starforgeUnlocked&&raw.starforgeUnlocked[key]);
      for(const chest of CHEST_DEFINITIONS){
        base.openedChests[chest.id]=!!(raw.openedChests&&raw.openedChests[chest.id]);
        const pending=raw.pendingChestLoot&&raw.pendingChestLoot[chest.id];
        if(pending&&typeof pending==='object'){
          base.pendingChestLoot[chest.id]={};
          for(const type of Object.keys(base.cargo).concat('coin'))if(Number(pending[type])>0)base.pendingChestLoot[chest.id][type]=Math.floor(Number(pending[type]));
          if(!Object.keys(base.pendingChestLoot[chest.id]).length)delete base.pendingChestLoot[chest.id];
        }
      }
      for(const scene of MINE_SCENES){
        const mine=MINE_DEFINITIONS[scene];
        base.discoveredMines[scene]=!!(raw.discoveredMines&&raw.discoveredMines[scene])||(scene==='mossMine'&&!!raw.mineDiscovered);
        for(const barrier of mine.barriers)base.clearedMineBarriers[barrier.id]=!!(raw.clearedMineBarriers&&raw.clearedMineBarriers[barrier.id]);
        for(const depth of [1,2])for(const cavern of discoveriesFor(scene,depth).caverns){
          base.discoveredCaverns[cavern.id]=!!(raw.discoveredCaverns&&raw.discoveredCaverns[cavern.id]);
          const rewardId=cavern.reward.id;base.claimedPocketRewards[rewardId]=!!(raw.claimedPocketRewards&&raw.claimedPocketRewards[rewardId]);
          const pending=raw.pendingPocketLoot&&raw.pendingPocketLoot[rewardId];
          if(pending&&typeof pending==='object'){
            base.pendingPocketLoot[rewardId]={};
            for(const type of Object.keys(base.cargo))if(Number(pending[type])>0)base.pendingPocketLoot[rewardId][type]=Math.floor(Number(pending[type]));
            if(!Object.keys(base.pendingPocketLoot[rewardId]).length)delete base.pendingPocketLoot[rewardId];
          }
        }
        const terrainCellCount=Math.ceil(mine.width/MINE_TILE_SIZE)*Math.ceil(mine.height/MINE_TILE_SIZE);
        for(const depth of [1,2]){
          const key=terrainStateKey(scene,depth),dug=raw.terrainDug&&raw.terrainDug[key];
          if(Array.isArray(dug))base.terrainDug[key]=[...new Set(dug.map(Number).filter(Number.isInteger).filter(index=>index>=0&&index<terrainCellCount))];
        }
        base.discoveredDepthEntrances[scene]=!!(raw.discoveredDepthEntrances&&raw.discoveredDepthEntrances[scene]);
        base.visitedDepths[scene]=!!(raw.visitedDepths&&raw.visitedDepths[scene]);
      }
      base.drillGoalScene=MINE_SCENES.includes(raw.drillGoalScene)?raw.drillGoalScene:MINE_SCENES.find(scene=>base.visitedDepths[scene])||null;
      base.mineDiscovered=base.discoveredMines.mossMine;
      if(raw.location&&raw.location.scene==='hub'&&base.hub.unlocked){
        base.location.scene='hub';base.location.depth=1;base.location.x=clamp(Number(raw.location.x)||HUB_STATIONS.surfaceLift.x+92,52,HUB_WORLD.width-52);base.location.y=clamp(Number(raw.location.y)||HUB_STATIONS.surfaceLift.y,70,HUB_WORLD.height-58);
      }else if(raw.location&&MINE_SCENES.includes(raw.location.scene)){
        const mine=MINE_DEFINITIONS[raw.location.scene];
        const depthAllowed=raw.location.depth===2&&base.discoveredDepthEntrances[raw.location.scene]&&(raw.location.scene!=='starMine'||base.drillLevel===DRILLS.length-1);
        base.location.scene=mine.unlock(base)?raw.location.scene:'surface';base.location.depth=depthAllowed?2:1;
        base.location.x=clamp(depthAllowed||raw.location.depth!==2?Number(raw.location.x)||mine.entrance.x:mine.entrance.x+85,52,mine.width-52);base.location.y=clamp(depthAllowed||raw.location.depth!==2?Number(raw.location.y)||mine.entrance.y:mine.entrance.y,70,mine.height-58);
      }
      base.location.surfaceX=clamp(Number(raw.location&&raw.location.surfaceX)||330,52,WORLD.width-52);
      base.location.surfaceY=clamp(Number(raw.location&&raw.location.surfaceY)||690,70,WORLD.height-58);
      base.starforgeVariant=base.starforgeUnlocked[raw.starforgeVariant]?raw.starforgeVariant:null;
      base.totalGold=Math.max(0,Number(raw.totalGold)||0);
      base.totalSwings=Math.max(0,Number(raw.totalSwings)||0);
      base.precisionHits=Math.max(0,Number(raw.precisionHits)||0);
      return base;
    }catch(error){loadedExistingSave=false;return defaultState()}
  }

  function saveState(force){
    try{
      state.location.scene=currentScene;state.location.depth=currentScene==='surface'?1:currentDepth;state.location.x=player.x;state.location.y=player.y;
      if(currentScene==='surface'){state.location.surfaceX=player.x;state.location.surfaceY=player.y}
      if(achievementProgress)evaluateAchievements();
      const snapshot=JSON.stringify(state);
      if(force||snapshot!==lastSavedSnapshot){localStorage.setItem(SAVE_KEY,snapshot);lastSavedSnapshot=snapshot}
    }catch(error){}
  }

  function resetProgress(){
    const fresh=defaultState();
    Object.keys(fresh).forEach(key=>state[key]=fresh[key]);
    for(const rock of rocks){rock.hp=rock.maxHp;rock.shell=rock.maxShell;rock.broken=false;rock.respawn=0;rock.hit=0;rock.glintActive=0;rock.glintTimer=1.4+(rock.id%5)*.45;rock.bonusYield=0}
    depthEntrances=createDepthEntrances();rebuildMineTerrain();
    resetVeins();groundDrops.length=0;terrainResponses.length=0;nextDropId=1;nextTerrainResponseId=1;lastTerrainImpactAt=-Infinity;
    pickupBatch.items=Object.create(null);pickupBatch.count=0;pickupBatch.quiet=0;pickupBatch.bestType=null;
    currentScene='surface';currentDepth=1;player.x=330;player.y=690;player.swing=null;player.swingCooldown=0;resetPlayerWalk('right');
    miningFocus.streak=0;miningFocus.timer=0;miningRush.timer=0;miningRush.lastSecond=0;resetHeatStreak();saleMotes.length=0;goldTween=null;displayedGold=0;
    lootSweepCheck=0;lootSweepWarned30=false;lootSweepWarned10=false;moonglassGateTransition=null;emberdeepGateTransition=null;starfallGateTransition=null;
    Object.assign(miningFeedback,{shake:0,shakeTime:0,flash:0,hitStop:0,terrainHitIndex:-1,terrainHitTime:0,lastDiscovery:null,lastDepositBeat:null,lastPocketReward:null});
    setHubBuildMode(false);lastRegion=-1;activeContext=null;menuShade.hidden=true;inventoryShade.hidden=true;heatTutorialShade.hidden=true;hubTutorialShade.hidden=true;uiDirty=true;saveState(true);showToast('A fresh vein awaits.');
  }

  function resetAllProgress(){
    if(!window.confirm('Reset all game progress and achievements? This cannot be undone.'))return false;
    clearTimeout(achievementSettleTimer);achievementSettleTimer=0;achievementProgress=defaultAchievementProgress();achievementQueue=[];activeAchievementId=null;highlightedAchievementId=null;achievementPopupSettled=false;achievementListDirty=true;
    try{localStorage.removeItem(ACHIEVEMENTS_KEY)}catch(error){}achievementPopup.hidden=true;achievementPopup.classList.remove('spinning');achievementPopup.classList.remove('settled');achievementList.dataset.highlightedAchievement='';renderAchievementSummary();
    resetProgress();persistAchievementProgress();loadedExistingSave=true;continueButton.disabled=false;continueDetail.textContent='MOSSVEIN QUARRY';enterGame();return true;
  }

  function resize(){
    const rect=viewport.getBoundingClientRect();
    width=Math.max(1,rect.width);height=Math.max(1,rect.height);
    viewZoom=width<=620?.71:.75;
    viewWidth=width/viewZoom;viewHeight=height/viewZoom;
    dpr=Math.min(2,window.devicePixelRatio||1);
    canvas.width=Math.round(width*dpr);canvas.height=Math.round(height*dpr);
    ctx.setTransform(dpr,0,0,dpr,0,0);
    if(lightCanvas){
      lightCanvas.width=Math.max(1,Math.ceil(viewWidth*LIGHTING.bufferScale));
      lightCanvas.height=Math.max(1,Math.ceil(viewHeight*LIGHTING.bufferScale));
    }
    updateCamera(true);
  }

  function clamp(value,min,max){return Math.max(min,Math.min(max,value))}
  function titleCase(value){return String(value).toLowerCase().replace(/\b\w/g,letter=>letter.toUpperCase())}
  function distance(x1,y1,x2,y2){return Math.hypot(x2-x1,y2-y1)}
  function easeOut(t){return 1-Math.pow(1-clamp(t,0,1),3)}
  function easeInOut(t){t=clamp(t,0,1);return t<.5?2*t*t:1-Math.pow(-2*t+2,2)/2}
  function cargoCount(){return Object.values(state.cargo).reduce((total,amount)=>total+amount,0)}
  function cargoValueTotal(cargo=state.cargo){return Object.keys(cargo).reduce((total,type)=>total+(cargo[type]||0)*ROCK_TYPES[type].value,0)}
  function currentPickaxe(){return PICKAXES[state.pickaxeLevel]}
  function currentMastery(){return EMBER_MASTERY[state.emberMastery]}
  function currentDrill(){return DRILLS[state.drillLevel]||null}
  function currentStarforge(){return !state.drillLevel&&state.starforgeVariant?STARFORGE_VARIANTS[state.starforgeVariant]:null}
  function currentPlayerToolKey(){
    if(state.drillLevel)return['','drill-burrower','drill-pulse','drill-deepcore'][state.drillLevel];
    if(state.starforgeVariant)return'starforge-'+state.starforgeVariant;
    return['','pickaxe-worn','pickaxe-iron','pickaxe-runed','pickaxe-moonglass','pickaxe-ember'][state.pickaxeLevel];
  }
  function currentToolPath(){return UI_TOOL_PATHS[currentPlayerToolKey()]||PLAYER_TOOL_PATHS['pickaxe-worn']}
  function depthUiPaths(scene=currentScene){
    return scene==='mossMine'?ROOTWOUND_PATHS:scene==='moonMine'?PRISMATIC_PATHS:scene==='emberMine'?MOLTEN_PATHS:VOIDSTAR_PATHS;
  }
  function moduleUiPath(kind){return kind==='forge'?STARTER_PATHS.forgeStation:kind==='sell'?STARTER_PATHS.sellStation:STARTER_PATHS.storageChest}
  function contextUiAsset(baseContext){
    if(baseContext)return moduleUiPath(baseContext.kind);
    if(!activeContext)return'';
    if(activeContext.startsWith('mineEntrance:'))return MINE_ENTRANCE_PATHS[activeContext.slice(13)];
    if(activeContext==='mineExit')return MINE_ENTRANCE_PATHS[currentScene];
    if(activeContext==='depthEntrance'||activeContext==='depthExit')return depthUiPaths().shaft;
    if(activeContext==='depthSell')return depthUiPaths().sellStation;
    if(activeContext==='drillForge')return depthUiPaths().drillForge;
    if(activeContext.startsWith('chest:'))return STARTER_PATHS.treasureClosed;
    if(activeContext==='speedShop')return STARTER_PATHS.wayfarerShop;
    if(activeContext==='gate')return STARTER_PATHS.moonglassGate;
    if(activeContext==='emberGate')return STARTER_PATHS.emberdeepSeal;
    if(activeContext==='starfallGate')return STARTER_PATHS.starfallSeal;
    if(activeContext==='starforge')return STARTER_PATHS.starforgeStation;
    if(activeContext==='hubEntrance'||activeContext==='hubExit'||activeContext==='deepElevator')return VOIDSTAR_PATHS.shaft;
    return STARTER_PATHS.forgeStation;
  }
  function activePlayerWalkKey(){return state.drillLevel?currentPlayerToolKey():'base'}
  function activePlayerWalkPath(){return PLAYER_WALK_PATHS[activePlayerWalkKey()]}
  let loadedPlayerWalkKey='base';
  function ensurePlayerWalkSheet(){
    const activeKey=activePlayerWalkKey();
    if(activeKey!==loadedPlayerWalkKey){for(const key of Object.keys(PLAYER_ART.walkSheets))if(key!=='base'&&key!==activeKey)delete PLAYER_ART.walkSheets[key];loadedPlayerWalkKey=activeKey}
    return loadPlayerWalkImage(activeKey);
  }
  function resetPlayerWalk(direction=player.direction){
    player.walk=0;player.walkPhase=0;player.walkDistance=0;player.walkFrame=0;player.direction=PLAYER_WALK_ROWS[direction]===undefined?'right':direction;player.moving=false;
  }
  function hasDeepTool(){return state.drillLevel>0||!!state.starforgeVariant}
  function currentPickaxeName(){const drill=currentDrill(),variant=currentStarforge();return drill?drill.name:variant?variant.name:currentPickaxe().name+(state.emberMastery?' +'+state.emberMastery:'')}
  function currentPower(){const drill=currentDrill();if(drill)return drill.power;const base=state.pickaxeLevel===PICKAXES.length-1?currentMastery().power:currentPickaxe().power,variant=currentStarforge();return variant?Math.round(base*variant.powerMultiplier):base}
  function heatStreakUnlocked(){return state.emberMastery>=5&&!state.drillLevel}
  function heatStreakProgress(){return heatStreakUnlocked()?clamp(heatStreak.elapsed/HEAT_STREAK_BUILD_SECONDS,0,1):0}
  function heatStreakSpeed(){return 1+(HEAT_STREAK_MAX_SPEED-1)*heatStreakProgress()}
  function renderHeatStreak(){
    const progress=heatStreakProgress(),percent=Math.round(progress*100),speed=heatStreakSpeed();
    heatMeter.hidden=!heatStreakUnlocked()||!heatStreak.active||heatStreak.elapsed<.12;
    heatFill.style.width=percent+'%';heatValue.textContent=speed.toFixed(2)+'x';heatMeter.setAttribute('aria-label','Heat Streak '+percent+' percent, mining speed '+speed.toFixed(2)+' times');
    game.dataset.heatActive=progress>0?'true':'false';game.dataset.heatMaxed=progress>=1?'true':'false';
  }
  function resetHeatStreak(){
    const changed=heatStreak.elapsed>0||heatStreak.active;heatStreak.elapsed=0;heatStreak.active=false;heatStreak.lastPercent=-1;if(changed)renderHeatStreak();
  }
  function updateHeatStreak(dt){
    if(!heatStreakUnlocked()||!input.mineHeld){resetHeatStreak();return}
    if(!heatStreak.active)return;
    if(!player.swing&&!nearestRock(MINING_RANGE)&&!nearestTerrainCell(MINING_RANGE))return;
    heatStreak.elapsed=Math.min(HEAT_STREAK_BUILD_SECONDS,heatStreak.elapsed+dt);
    const percent=Math.round(heatStreakProgress()*100);if(percent!==heatStreak.lastPercent){heatStreak.lastPercent=percent;renderHeatStreak()}
  }
  function currentCooldown(){
    const drill=currentDrill(),base=drill?drill.cooldown:state.pickaxeLevel===PICKAXES.length-1?currentMastery().cooldown:currentPickaxe().cooldown,variant=currentStarforge();
    const toolCooldown=!drill&&variant?base*variant.cooldownMultiplier:base;
    return toolCooldown*(miningRush.timer>0?MINING_RUSH_COOLDOWN_MULTIPLIER:1)/heatStreakSpeed();
  }
  function currentShellPower(){const drill=currentDrill();if(drill)return drill.shellPower;const base=state.pickaxeLevel===PICKAXES.length-1?currentMastery().shellPower:.72,variant=currentStarforge();return variant?base*variant.shellMultiplier:base}
  function currentBonusYieldChance(){const drill=currentDrill();if(drill)return drill.yieldBonus;const base=state.pickaxeLevel<4?0:state.pickaxeLevel===PICKAXES.length-1?currentMastery().bonusYield:.22,variant=currentStarforge();return Math.min(.92,base+(variant?variant.yieldBonus:0))}
  function currentPrecisionDelay(){return state.drillLevel?.62:state.pickaxeLevel===PICKAXES.length-1?currentMastery().precisionDelay:1}
  function movementSpeedMultiplier(level=state.movementSpeedLevel){return 1+Math.max(0,level)*MOVEMENT_SPEED_GAIN}
  function movementSpeedCost(level=state.movementSpeedLevel){return Math.round((150+75*level+25*level*level)/10)*10}
  function terrainStateKey(scene,depth=1){return depth===2?scene+'Depth2':scene}
  function inHub(){return currentScene==='hub'}
  function currentMine(){return MINE_DEFINITIONS[currentScene]||null}
  function currentMineVisual(){
    const mine=currentMine();if(!mine)return null;
    return currentDepth===2?{...mine,...MINE_DEPTH_PROFILES[currentScene],style:mine.style+'-deep'}:{...mine,dirt:MINE_DIRT_COLORS[currentScene]};
  }
  function currentWorld(){return inHub()?HUB_WORLD:currentMine()||WORLD}
  function currentRocks(){return rocksByLocation.get(currentScene+':'+currentDepth)||[]}
  function regionIndexAt(x){return x>=WORLD.starfallGateX?3:x>=WORLD.emberGateX?2:x>=WORLD.gateX?1:0}
  function currentBiome(){if(inHub())return{id:'hub',name:'UNDERGROUND HUB',accent:'#70d7bd',detail:'#e1c979'};const mine=currentMineVisual();return mine?{id:currentDepth===2?mine.id+'Depth2':mine.id,name:mine.name,accent:mine.accent,detail:mine.detail}:BIOMES[regionIndexAt(player.x)]}
  function starforgeMastered(){return Object.values(state.starforgeUnlocked).every(Boolean)}
  function nextMastery(){return EMBER_MASTERY[state.emberMastery+1]||null}
  function masteryReady(){const next=nextMastery();return !!next&&state.cargo.sunslag>=next.sunslag&&state.gold>=next.gold}
  function hitsRequired(type,power){return Math.ceil(ROCK_TYPES[type].hp/power)}
  function armoredHitsRequired(type,power,shellPower){
    const data=ROCK_TYPES[type];let shell=data.shell||0,hp=data.hp,hits=0;
    while((shell>0||hp>0)&&hits<100){
      hits++;
      if(shell>0){
        const shellDamage=Math.ceil(power*shellPower),remaining=shellDamage-shell;
        shell=Math.max(0,shell-shellDamage);
        if(shell===0&&remaining>0)hp=Math.max(0,hp-Math.floor(remaining/shellPower));
      }else hp=Math.max(0,hp-power);
    }
    return hits;
  }
  function localReferenceRock(){return state.pickaxeLevel>=4?'emberstone':state.pickaxeLevel>=3?'moonglass':state.mined.copper>0?'copper':'stone'}
  function emberPickaxeReady(){return state.emberdeepUnlocked&&state.cargo.emberstone>=EMBER_PICKAXE_ORE_REQUIRED}
  function veinById(id){return veins.find(vein=>vein.id===id)||null}
  function chestById(id){return chests.find(chest=>chest.id===id)||null}
  function chestRequirementMet(chest){return chest.requires.starforge?!!state.starforgeVariant:state.pickaxeLevel>=chest.requires.pickaxeLevel}
  function lootData(type){return type==='coin'?COIN_DROP:ROCK_TYPES[type]}
  function chestRewardLabel(chest){return Object.entries(chest.rewards).map(([type,amount])=>amount+' '+lootData(type).label).join(' + ')}
  function nearbyChest(){
    if(currentScene!=='surface')return null;
    let nearest=null,best=CHEST_INTERACT_RADIUS;
    for(const chest of chests){
      if(state.openedChests[chest.id])continue;
      const range=distance(player.x,player.y,chest.x,chest.y);
      if(range<=best){best=range;nearest=chest}
    }
    return nearest;
  }
  function resetVeins(){for(const vein of veins){vein.status='idle';vein.timer=0;vein.displaySecond=-1;vein.brokenRockIds.clear()}}

  function mineBarrierById(id){for(const scene of MINE_SCENES){const barrier=MINE_DEFINITIONS[scene].barriers.find(item=>item.id===id);if(barrier)return barrier}return null}
  function mineBarrierCleared(id){return !!state.clearedMineBarriers[id]}
  function activeMineSolids(){const mine=currentMine();return mine&&currentDepth===1?mine.solids.concat(mine.barriers.filter(barrier=>!mineBarrierCleared(barrier.id))):[]}

  function createDepthEntrances(){
    return Object.fromEntries(MINE_SCENES.map(scene=>{
      const mine=MINE_DEFINITIONS[scene],profile=MINE_DISCOVERY_PROFILES[scene],cols=Math.ceil(mine.width/MINE_TILE_SIZE),rows=Math.ceil(mine.height/MINE_TILE_SIZE);
      const random=seededRandom((state.worldSeed^profile.seed^0x9e3779b9)>>>0),caverns=MINE_DISCOVERIES[scene].caverns.concat(MINE_DEPTH_DISCOVERIES[scene].caverns);
      const point=entry=>Array.isArray(entry)?{x:entry[1],y:entry[2]}:entry;
      const depth1Resources=mine.rocks.map(point).concat(MINE_DISCOVERIES[scene].rocks.map(point)),depth2Resources=MINE_DEPTH_DISCOVERIES[scene].rocks.map(point);
      const firstRow=Math.ceil(1700/MINE_TILE_SIZE),usableCols=Math.max(1,cols-6),usableRows=Math.max(1,rows-firstRow-7);
      let col=Math.floor(cols*.5),row=Math.floor(rows*.72),found=false;
      const validCandidate=(candidateCol,candidateRow)=>{
        const x=(candidateCol+.5)*MINE_TILE_SIZE,y=(candidateRow+.5)*MINE_TILE_SIZE;
        const nearCavern=caverns.some(cavern=>Math.pow((x-cavern.x)/(cavern.rx+190),2)+Math.pow((y-cavern.y)/(cavern.ry+190),2)<1);
        const nearStructure=mine.solids.some(item=>x>item.x-150&&x<item.x+item.w+150&&y>item.y-150&&y<item.y+item.h+150)||mine.barriers.some(item=>x>item.x-180&&x<item.x+item.w+180&&y>item.y-180&&y<item.y+item.h+180);
        const stations=[{x:clamp(x-112,70,mine.width-70),y:clamp(y-112,90,mine.height-90)},{x:clamp(x+112,70,mine.width-70),y:clamp(y-112,90,mine.height-90)}];
        const portalBlocked=depth1Resources.concat(depth2Resources).some(resource=>distance(x,y,resource.x,resource.y)<DEPTH_PORTAL_RESOURCE_CLEARANCE);
        const stationBlocked=depth2Resources.some(resource=>stations.some(station=>distance(station.x,station.y,resource.x,resource.y)<DEPTH_STATION_RESOURCE_CLEARANCE));
        return !nearCavern&&!nearStructure&&!portalBlocked&&!stationBlocked&&distance(x,y,mine.entrance.x,mine.entrance.y)>700;
      };
      for(let attempt=0;attempt<240;attempt++){
        const candidateCol=3+Math.floor(random()*usableCols),candidateRow=firstRow+Math.floor(random()*usableRows);
        if(validCandidate(candidateCol,candidateRow)){col=candidateCol;row=candidateRow;found=true;break}
      }
      if(!found){
        const candidateCount=usableCols*usableRows,start=Math.floor(random()*candidateCount);
        for(let step=0;step<candidateCount;step++){
          const index=(start+step)%candidateCount,candidateCol=3+index%usableCols,candidateRow=firstRow+Math.floor(index/usableCols);
          if(validCandidate(candidateCol,candidateRow)){col=candidateCol;row=candidateRow;break}
        }
      }
      return[scene,{id:scene+'_depth_entrance',scene,x:(col+.5)*MINE_TILE_SIZE,y:(row+.5)*MINE_TILE_SIZE,radius:78}];
    }));
  }

  function depthStations(scene=currentScene){
    const entrance=depthEntrances[scene],mine=MINE_DEFINITIONS[scene];
    return{
      sell:{x:clamp(entrance.x-112,70,mine.width-70),y:clamp(entrance.y-112,90,mine.height-90),radius:88},
      forge:{x:clamp(entrance.x+112,70,mine.width-70),y:clamp(entrance.y-112,90,mine.height-90),radius:88}
    };
  }

  function nextDrill(){return DRILLS[state.drillLevel+1]||null}
  function drillCost(){
    const drill=nextDrill(),recipe=DRILL_RECIPES[state.drillLevel+1];
    return drill&&recipe?{gold:recipe.gold,requirements:recipe.requirements.map(requirement=>({...requirement}))}:null;
  }
  function drillReady(){
    const cost=drillCost();if(!cost)return false;
    return (state.drillLevel>0||!!state.starforgeVariant)&&state.gold>=cost.gold&&cost.requirements.every(requirement=>state.cargo[requirement.type]>=requirement.amount);
  }
  function nextMissingDrillRequirement(cost=drillCost()){
    return cost&&cost.requirements.find(requirement=>state.cargo[requirement.type]<requirement.amount)||null;
  }
  function drillRequirementProgress(requirement){
    return ROCK_TYPES[requirement.type].label.toUpperCase()+' '+Math.min(requirement.amount,state.cargo[requirement.type])+'/'+requirement.amount;
  }

  function protectedDrillCargo(){
    const cost=drillCost(),protectedCargo={};
    if(!cost)return protectedCargo;
    for(const requirement of cost.requirements)protectedCargo[requirement.type]=Math.min(requirement.amount,state.cargo[requirement.type]);
    return protectedCargo;
  }

  function currentCraftRequirements(){
    if((state.drillGoalScene||state.drillLevel)&&(state.starforgeVariant||state.drillLevel)){
      const cost=drillCost();return cost?cost.requirements.map(requirement=>({type:requirement.type,amount:requirement.amount})):[];
    }
    if(state.pickaxeLevel===4)return[{type:'emberstone',amount:EMBER_PICKAXE_ORE_REQUIRED}];
    if(state.pickaxeLevel===PICKAXES.length-1&&nextMastery())return[{type:'sunslag',amount:nextMastery().sunslag}];
    if(state.fourthUnlocked&&state.discoveredFourth&&!starforgeMastered()){
      const nextId=Object.keys(STARFORGE_VARIANTS).find(id=>!state.starforgeUnlocked[id]);
      return nextId?Object.entries(STARFORGE_VARIANTS[nextId].cost).map(([type,amount])=>({type,amount})):[];
    }
    return[];
  }

  function protectedProgressCargo(){
    const protectedCargo=protectedDrillCargo();
    for(const requirement of currentCraftRequirements())protectedCargo[requirement.type]=Math.max(protectedCargo[requirement.type]||0,Math.min(requirement.amount,state.cargo[requirement.type]||0));
    return protectedCargo;
  }

  function sellableCargo(){
    const protectedCargo=protectedProgressCargo(),sellable={};
    for(const type of Object.keys(state.cargo))sellable[type]=Math.max(0,state.cargo[type]-(protectedCargo[type]||0));
    return sellable;
  }

  function protectedCargoLabel(){
    return Object.entries(protectedProgressCargo()).filter(([,amount])=>amount>0).map(([type,amount])=>amount+' '+ROCK_TYPES[type].label).join(' + ');
  }

  function hubCellKey(col,row){return col+':'+row}
  function hubCellCenter(col,row){return{x:HUB_GRID.originX+(col+.5)*HUB_GRID.tileSize,y:HUB_GRID.originY+(row+.5)*HUB_GRID.tileSize}}
  function hubCellAtWorld(x,y){
    const col=Math.floor((x-HUB_GRID.originX)/HUB_GRID.tileSize),row=Math.floor((y-HUB_GRID.originY)/HUB_GRID.tileSize);
    return col>=0&&row>=0&&col<HUB_GRID.cols&&row<HUB_GRID.rows?{col,row,key:hubCellKey(col,row)}:null;
  }
  function hubTileAtCell(col,row){return state.hub.tiles.find(tile=>tile.col===col&&tile.row===row)||null}
  function hubModuleAtCell(col,row){
    return allBaseModules().find(module=>{
      if(!moduleIsHere(module))return false;const cell=hubCellAtWorld(module.x,module.y);return cell&&cell.col===col&&cell.row===row;
    })||null;
  }
  function hubOccupantAtCell(col,row){return hubTileAtCell(col,row)||hubModuleAtCell(col,row)}
  function hubWallCollision(x,y){
    if(!inHub())return false;
    for(const tile of state.hub.tiles){
      if(tile.kind!=='wall')continue;const center=hubCellCenter(tile.col,tile.row),half=HUB_GRID.tileSize*.47,nearestX=clamp(x,center.x-half,center.x+half),nearestY=clamp(y,center.y-half,center.y+half);
      if(distance(x,y,nearestX,nearestY)<player.radius)return true;
    }
    return false;
  }
  function nearestFreeHubCell(){
    const preferredX=player.x+player.aimX*86,preferredY=player.y+player.aimY*86,candidates=[];
    for(let row=0;row<HUB_GRID.rows;row++)for(let col=0;col<HUB_GRID.cols;col++){
      if(hubOccupantAtCell(col,row))continue;const center=hubCellCenter(col,row);if(distance(center.x,center.y,player.x,player.y)<68)continue;
      candidates.push({col,row,...center,range:distance(center.x,center.y,preferredX,preferredY)});
    }
    candidates.sort((a,b)=>a.range-b.range);return candidates[0]||null;
  }
  function updateHubBuildControls(){
    const tools={wall:hubBuildWall,lamp:hubBuildLamp,storage:hubBuildStorage,erase:hubBuildErase};
    for(const [kind,button] of Object.entries(tools)){const selected=hubBuild.selected===kind;button.classList.toggle('selected',selected);button.setAttribute('aria-pressed',String(selected))}
    const wallCost=HUB_BUILD_COSTS.wall.amount,lampCost=HUB_BUILD_COSTS.lamp.gold,storageCost=storageChestCost();
    hubBuildWallCost.textContent=wallCost+' STONE';hubBuildLampCost.textContent=lampCost+' GOLD';hubBuildStorageCost.textContent=storageCost+' GOLD';
    hubBuildWall.dataset.affordable=String(state.cargo.stone>=wallCost);hubBuildLamp.dataset.affordable=String(state.gold>=lampCost);hubBuildStorage.dataset.affordable=String(state.gold>=storageCost);
    hubBuildHint.textContent=hubBuild.selected==='wall'?'DRAG TO BUILD · '+state.cargo.stone+' STONE':hubBuild.selected==='lamp'?'TAP A CELL · '+state.gold+' GOLD':hubBuild.selected==='storage'?'TAP A CELL · '+state.gold+' GOLD':'DRAG TO REMOVE · FULL REFUND';
  }
  function selectHubBuildTool(kind){if(!['wall','lamp','storage','erase'].includes(kind))return false;hubBuild.selected=kind;hubBuild.preview=null;updateHubBuildControls();return true}
  function setHubBuildMode(enabled){
    const active=!!enabled&&inHub()&&state.hub.unlocked;if(hubBuild.active===active){if(active)updateHubBuildControls();return active}
    releaseTouchControls();hubBuild.active=active;hubBuild.pointerId=null;hubBuild.lastCell=null;hubBuild.singlePlaced=false;hubBuild.preview=null;hubBuildToolbar.hidden=!active;game.dataset.buildMode=active?'true':'false';activeContext=null;
    if(active&&!state.hub.buildTutorialSeen){state.hub.buildTutorialSeen=true;showToast('Choose a tool, then drag across the floor grid.');saveState(true)}
    if(!active&&hubBuild.changed){hubBuild.changed=false;saveState(true)}
    updateHubBuildControls();uiDirty=true;return active;
  }
  function removeHubCell(col,row){
    const tile=hubTileAtCell(col,row);if(tile){
      state.hub.tiles=state.hub.tiles.filter(item=>item!==tile);
      if(tile.kind==='wall')state.cargo.stone+=HUB_BUILD_COSTS.wall.amount;
      else{const before=state.gold;state.gold+=HUB_BUILD_COSTS.lamp.gold;startGoldCount(before,state.gold)}
      return true;
    }
    const module=hubModuleAtCell(col,row);if(module){module.packed=true;showToast((module.kind==='storage'?'Storage':module.kind==='forge'?'Forge':'Sell Chest')+' packed without loss.');return true}
    return false;
  }
  function placeHubCell(col,row){
    if(hubBuild.selected==='erase')return removeHubCell(col,row);
    if(hubOccupantAtCell(col,row))return false;
    const center=hubCellCenter(col,row);if(distance(center.x,center.y,player.x,player.y)<68)return false;
    if(hubBuild.selected==='wall'){
      const cost=HUB_BUILD_COSTS.wall;if(state.cargo[cost.resource]<cost.amount){showToast('Need '+(cost.amount-state.cargo[cost.resource])+' more Stone.');sound('empty');return false}
      state.cargo[cost.resource]-=cost.amount;state.hub.tiles.push({col,row,kind:'wall'});return true;
    }
    if(hubBuild.selected==='lamp'){
      const cost=HUB_BUILD_COSTS.lamp.gold;if(state.gold<cost){showToast('Need '+(cost-state.gold)+' more gold.');sound('empty');return false}
      const before=state.gold;state.gold-=cost;startGoldCount(before,state.gold);state.hub.tiles.push({col,row,kind:'lamp'});return true;
    }
    const cost=storageChestCost();if(state.gold<cost){showToast('Need '+(cost-state.gold)+' more gold.');sound('empty');return false}
    const before=state.gold,id='storage-'+state.base.nextChestId++;state.gold-=cost;startGoldCount(before,state.gold);state.base.chests.push({id,kind:'storage',scene:'hub',depth:1,x:center.x,y:center.y,packed:false,items:emptyResourceStore()});return true;
  }
  function paintHubAtWorld(x,y){
    if(!hubBuild.active||!inHub())return false;const cell=hubCellAtWorld(x,y);hubBuild.preview=cell;if(!cell||hubBuild.lastCell===cell.key)return false;
    hubBuild.lastCell=cell.key;if(hubBuild.singlePlaced&&['lamp','storage'].includes(hubBuild.selected))return false;
    const changed=placeHubCell(cell.col,cell.row);if(!changed)return false;
    hubBuild.changed=true;if(['lamp','storage'].includes(hubBuild.selected))hubBuild.singlePlaced=true;updateHubBuildControls();uiDirty=true;return true;
  }

  function allBaseModules(){return[state.base.forge,state.base.sell,...state.base.chests]}
  function baseModuleById(id){return allBaseModules().find(module=>module.id===id)||null}
  function moduleIsHere(module){return !!module&&!module.packed&&module.scene===currentScene&&module.depth===currentDepth}
  function canInteractModule(module,range=BASE_MODULE_INTERACT_RADIUS){return moduleIsHere(module)&&distance(player.x,player.y,module.x,module.y)<=range}
  function nearbyStorageChests(range=AUTO_SORT_RADIUS){return state.base.chests.filter(chest=>moduleIsHere(chest)&&distance(player.x,player.y,chest.x,chest.y)<=range)}
  function chestTypeCount(chest){return Object.values(chest.items).filter(amount=>amount>0).length}
  function storageChestCost(){return Math.round(250*Math.pow(1.65,Math.max(0,state.base.chests.length-1))/10)*10}
  function moduleLocationLabel(module){
    if(module.packed)return'PACKED · READY TO PLACE';
    if(module.scene==='surface')return'SURFACE · '+titleCase(BIOMES[regionIndexAt(module.x)].name);
    if(module.scene==='hub')return'UNDERGROUND HUB';
    const mine=MINE_DEFINITIONS[module.scene],name=module.depth===2?MINE_DEPTH_PROFILES[module.scene].name:mine.name;return titleCase(name);
  }
  function nearestBaseModule(){
    let nearest=null,best=BASE_MODULE_INTERACT_RADIUS;
    for(const module of allBaseModules()){
      if(!moduleIsHere(module))continue;const range=distance(player.x,player.y,module.x,module.y);
      if(range<=best){best=range;nearest=module}
    }
    return nearest;
  }
  function findModulePlacement(){
    if(inHub()){const cell=nearestFreeHubCell();return cell?{x:cell.x,y:cell.y}:{x:player.x,y:player.y}}
    const candidates=[[player.aimX*86,player.aimY*86],[0,82],[82,0],[-82,0],[0,-82],[58,58],[-58,58]],world=currentWorld();
    for(const [ox,oy] of candidates){
      const x=clamp(player.x+ox,58,world.width-58),y=clamp(player.y+oy,76,world.height-64);
      if(currentMine()&&collidesWithMine(x,y))continue;
      if(allBaseModules().some(module=>moduleIsHere(module)&&distance(x,y,module.x,module.y)<68))continue;
      return{x,y};
    }
    return{x:player.x,y:player.y};
  }
  function placeBaseModule(id){
    const module=baseModuleById(id);if(!module||!module.packed)return false;
    const placement=findModulePlacement();module.scene=currentScene;module.depth=currentDepth;module.x=placement.x;module.y=placement.y;module.packed=false;
    inventoryShade.hidden=true;activeContext=null;uiDirty=true;sound('upgrade');showToast((module.kind==='storage'?'Storage chest':module.kind==='forge'?'Forge':'Sell Chest')+' placed.');saveState(true);return true;
  }
  function packBaseModule(id){
    const module=baseModuleById(id);if(!module||!canInteractModule(module))return false;
    module.packed=true;activeContext=null;uiDirty=true;sound('pickup',module.kind==='storage'?'gold':'stone');showToast((module.kind==='storage'?'Storage chest':module.kind==='forge'?'Forge':'Sell Chest')+' packed without loss.');saveState(true);if(!inventoryShade.hidden)renderInventory();return true;
  }
  function buyStorageChest(){
    const cost=storageChestCost();if(state.gold<cost){showToast('Need '+(cost-state.gold)+' more gold.');sound('empty');return false}
    const goldBefore=state.gold,id='storage-'+state.base.nextChestId++;state.gold-=cost;state.base.chests.push({id,kind:'storage',scene:currentScene,depth:currentDepth,x:player.x,y:player.y,packed:true,items:emptyResourceStore()});startGoldCount(goldBefore,state.gold);sound('coin');showToast('New 20-type storage chest added to your base.');uiDirty=true;renderInventory();saveState(true);return true;
  }
  function autoSortResources(){
    const chests=nearbyStorageChests(),protectedCargo=protectedProgressCargo();if(!chests.length){showToast('No storage chest nearby.');sound('empty');return 0}
    let moved=0;
    for(const type of Object.keys(state.cargo)){
      let remaining=Math.max(0,state.cargo[type]-(protectedCargo[type]||0));if(!remaining)continue;
      const existing=chests.find(chest=>chest.items[type]>0),target=existing||chests.find(chest=>chestTypeCount(chest)<STORAGE_CHEST_CAPACITY);
      if(!target)continue;target.items[type]+=remaining;state.cargo[type]-=remaining;moved+=remaining;
    }
    if(!moved){showToast('Nothing can be sorted. Upgrade materials stay with you.');sound('empty');return 0}
    sound('pickup','gold');showToast(moved+' resources sorted into nearby chests.');uiDirty=true;renderInventory();saveState(true);return moved;
  }
  function takeAllFromChest(id){
    const chest=baseModuleById(id);if(!chest||chest.kind!=='storage'||!canInteractModule(chest,AUTO_SORT_RADIUS))return false;
    let moved=0;for(const type of Object.keys(chest.items)){const amount=chest.items[type];if(!amount)continue;state.cargo[type]+=amount;chest.items[type]=0;moved+=amount}
    if(!moved){showToast('This chest is empty.');sound('empty');return false}
    sound('pickup','gold');showToast(moved+' resources returned to your inventory.');uiDirty=true;renderInventory();saveState(true);return true;
  }

  function openInventory(){if(hubBuild.active)setHubBuildMode(false);releaseTouchControls();inventoryShade.hidden=false;renderInventory();syncAchievementPopup()}
  function closeInventory(){inventoryShade.hidden=true;syncAchievementPopup()}

  function resourceKey(type){return type==='coin'?'gold':type}
  function resourceIconMarkup(type,className='',label=''){
    const key=resourceKey(type),path=DROP_PATHS[key],bounds=RESOURCE_IMAGE_BOUNDS[key]||{x:0,y:0,w:256,h:256};if(!path)return'';
    const fit=.9,max=Math.max(bounds.w,bounds.h),scale=fit*256/max,left=50-(bounds.x+bounds.w*.5)*fit/max*100,top=50-(bounds.y+bounds.h*.5)*fit/max*100;
    return'<span class="resource-icon'+(className?' '+className:'')+'" data-resource="'+key+'" title="'+(label||titleCase(key))+'" style="--resource-scale:'+scale*100+'%;--resource-left:'+left+'%;--resource-top:'+top+'%"><img src="'+path+'?v='+ASSET_VERSION+'" alt="" aria-hidden="true"></span>';
  }
  function resourceAmountMarkup(type,amount,className=''){
    const data=ROCK_TYPES[type];return'<span class="resource-amount'+(className?' '+className:'')+'">'+resourceIconMarkup(type,'',data?data.label:'')+'<b>'+amount+'</b></span>';
  }
  function resourceRequirementsMarkup(requirements=[],extra=''){
    return'<span class="context-resource-list">'+requirements.map(requirement=>resourceAmountMarkup(requirement.type,Math.min(state.cargo[requirement.type]||0,requirement.amount)+' / '+requirement.amount)).join('')+(extra?'<em>'+extra+'</em>':'')+'</span>';
  }

  function renderInventory(){
    const total=cargoCount(),types=Object.values(state.cargo).filter(amount=>amount>0).length,protectedCargo=protectedProgressCargo();inventoryTotal.textContent=String(total);inventoryTypes.textContent=String(types);
    const entries=Object.entries(state.cargo).filter(([,amount])=>amount>0).sort((a,b)=>Number(ROCK_TYPES[b[0]].rare)-Number(ROCK_TYPES[a[0]].rare)||ROCK_TYPES[a[0]].label.localeCompare(ROCK_TYPES[b[0]].label));
    inventoryGrid.innerHTML=entries.length?entries.map(([type,amount])=>{const data=ROCK_TYPES[type],protectedAmount=protectedCargo[type]||0;return'<div class="inventory-slot'+(protectedAmount?' protected':'')+'">'+resourceIconMarkup(type,'inventory-resource',data.label)+'<span class="inventory-resource-name">'+data.label+'</span><b>'+amount+'</b></div>'}).join(''):'<div class="inventory-slot empty">Resources you pick up will appear here.</div>';
    const nearby=nearbyStorageChests();autoSortButton.disabled=!nearby.length||!total;autoSortHint.textContent=nearby.length?nearby.length+' CHEST'+(nearby.length===1?'':'S')+' NEARBY':'NO CHEST NEARBY';
    const cost=storageChestCost();buyChestCost.textContent=cost+' GOLD';buyChestButton.disabled=state.gold<cost;
    const modules=allBaseModules();baseModuleList.innerHTML=modules.map(module=>{
      const nearbyModule=canInteractModule(module),nearbyStorage=canInteractModule(module,AUTO_SORT_RADIUS),placedHere=moduleIsHere(module),items=module.kind==='storage'?Object.entries(module.items).filter(([,amount])=>amount>0):[];
      const title=module.kind==='forge'?'Forge':module.kind==='sell'?'Sell Chest':'Storage Chest '+(state.base.chests.indexOf(module)+1);
      const contents=module.kind==='storage'?(items.length?items.map(([type,amount])=>resourceAmountMarkup(type,'×'+amount,'storage-resource')).join(''):'Empty · '+chestTypeCount(module)+' / '+STORAGE_CHEST_CAPACITY+' types'):(module.kind==='forge'?'Pickaxe upgrades and Ember Mastery.':'Sell carried resources while protecting upgrade materials.');
      const action=module.packed?'<button data-base-place="'+module.id+'">PLACE HERE</button>':placedHere&&nearbyModule?'<button class="secondary" data-base-pack="'+module.id+'">PACK</button>':'<button disabled>'+moduleLocationLabel(module)+'</button>';
      const take=module.kind==='storage'&&placedHere&&nearbyStorage?'<button data-chest-take="'+module.id+'"'+(items.length?'':' disabled')+'>TAKE ALL</button>':'';
      return'<article class="base-module"><div class="base-module-visual"><img src="'+moduleUiPath(module.kind)+'?v='+ASSET_VERSION+'" alt="" aria-hidden="true"></div><div class="base-module-content"><div class="base-module-head"><h4>'+title+'</h4><small>'+(module.kind==='storage'?chestTypeCount(module)+' / '+STORAGE_CHEST_CAPACITY+' TYPES':'BASE MODULE')+'</small></div><small>'+moduleLocationLabel(module)+'</small><div class="base-module-items">'+contents+'</div><div class="base-module-actions">'+action+take+'</div></div></article>';
    }).join('');
  }

  function guidePoint(kind,scene,depth,x,y,color,closeRadius=96,extra={}){
    return{kind,scene,depth,x,y,color:color||'#fff0ad',closeRadius,...extra};
  }

  function closestGuideRock(scene,depth,types,exposedOnly=false){
    const wanted=new Set(Array.isArray(types)?types:[types]),candidates=(rocksByLocation.get(scene+':'+depth)||[]).filter(rock=>
      wanted.has(rock.type)&&!rock.broken&&!rock.barrierId&&(!exposedOnly||rockIsExposed(rock))&&rock.requiredPickaxe<=state.pickaxeLevel&&(!rock.requiresDeepTool||hasDeepTool())&&(rock.requiresDrillLevel||0)<=state.drillLevel
    );
    if(!candidates.length)return null;
    const sameLocation=currentScene===scene&&currentDepth===depth,origin=sameLocation?player:scene==='surface'?player:depth===2?depthEntrances[scene]:MINE_DEFINITIONS[scene].entrance;
    candidates.sort((a,b)=>distance(origin.x,origin.y,a.x,a.y)-distance(origin.x,origin.y,b.x,b.y));
    const rock=candidates[0],data=ROCK_TYPES[rock.type];
    return guidePoint('rock',scene,depth,rock.x,rock.y,data.edge,88,{rockId:rock.id,resource:rock.type});
  }

  function resourceGuide(type,scene='surface',depth=1){
    const local=closestGuideRock(currentScene,currentDepth,type,currentScene==='surface');
    if(local)return local;
    return closestGuideRock(scene,depth,type,scene==='surface');
  }

  function surfaceStationGuide(kind,station,color){return guidePoint(kind,'surface',1,station.x,station.y,color,station.radius||116)}
  function baseModuleGuide(kind,color){const module=state.base[kind];return module&&!module.packed?guidePoint(kind,module.scene,module.depth,module.x,module.y,color,BASE_MODULE_INTERACT_RADIUS):null}
  function mineEntranceGuide(scene){const mine=MINE_DEFINITIONS[scene];return guidePoint('mine-entrance','surface',1,mine.surfaceEntrance.x,mine.surfaceEntrance.y,mine.detail,mine.surfaceEntrance.radius,{destination:scene})}
  function depthEntranceGuide(scene){const entrance=depthEntrances[scene];return guidePoint(state.discoveredDepthEntrances[scene]?'depth-entrance':'dig-route',scene,1,entrance.x,entrance.y,MINE_DEPTH_PROFILES[scene].detail,108)}
  function depthForgeGuide(scene){const station=depthStations(scene).forge;return guidePoint('drill-forge',scene,2,station.x,station.y,MINE_DEPTH_PROFILES[scene].detail,station.radius)}

  function routeVisualGuide(target){
    if(!target)return null;
    if(currentScene==='surface')return target.scene==='surface'?target:mineEntranceGuide(target.scene);
    if(target.scene==='surface'||target.scene!==currentScene){
      if(currentDepth===2){const entrance=depthEntrances[currentScene];return guidePoint('depth-exit',currentScene,2,entrance.x,entrance.y,currentMineVisual().detail,108)}
      const entrance=currentMine().entrance;return guidePoint('mine-exit',currentScene,1,entrance.x,entrance.y,currentMineVisual().detail,108);
    }
    if(currentDepth!==target.depth){
      if(target.depth===2)return depthEntranceGuide(currentScene);
      const entrance=depthEntrances[currentScene];return guidePoint('depth-exit',currentScene,2,entrance.x,entrance.y,currentMineVisual().detail,108);
    }
    return target;
  }

  function mineForGoldGuide(){
    if(cargoValueTotal(sellableCargo())>0){
      if(currentScene!=='surface'&&currentDepth===2){const station=depthStations().sell;return guidePoint('sell',currentScene,2,station.x,station.y,currentMineVisual().detail,station.radius)}
      return routeVisualGuide(baseModuleGuide('sell','#f4d68a'));
    }
    const localTypes=currentRocks().filter(rock=>!rock.broken&&rockIsExposed(rock)&&rock.requiredPickaxe<=state.pickaxeLevel&&(!rock.requiresDeepTool||hasDeepTool())&&(rock.requiresDrillLevel||0)<=state.drillLevel).map(rock=>rock.type);
    const local=localTypes.length?closestGuideRock(currentScene,currentDepth,localTypes,true):null;
    return local||routeVisualGuide(closestGuideRock('surface',1,['stone','copper','moonglass','emberstone','astralite'],true));
  }

  function purchaseGuide(cost,target){
    if(state.gold>=cost)return routeVisualGuide(target);
    return mineForGoldGuide();
  }

  function starforgeGuide(){
    const nextId=Object.keys(STARFORGE_VARIANTS).find(id=>!state.starforgeUnlocked[id]);
    if(!nextId)return null;
    const variant=STARFORGE_VARIANTS[nextId],missing=Object.entries(variant.cost).find(([type,amount])=>state.cargo[type]<amount);
    if(missing)return routeVisualGuide(resourceGuide(missing[0],'surface',1));
    return routeVisualGuide(surfaceStationGuide('starforge',STATIONS.starforge,'#d9dcff'));
  }

  function visualGuide(){
    if(state.hub.unlocked){
      if(hubBuild.active)return null;
      if(inHub())return guidePoint('deep-elevator','hub',1,HUB_STATIONS.deepElevator.x,HUB_STATIONS.deepElevator.y,'#e1c979',HUB_STATIONS.deepElevator.radius);
      return routeVisualGuide(guidePoint('hub-entrance','surface',1,HUB_STATIONS.surfaceEntrance.x,HUB_STATIONS.surfaceEntrance.y,'#70d7bd',HUB_STATIONS.surfaceEntrance.radius));
    }
    if(state.drillLevel===DRILLS.length-1&&!state.victory){
      if(currentScene!=='starMine')return routeVisualGuide(mineEntranceGuide('starMine'));
      if(currentDepth===2)return routeVisualGuide(resourceGuide('singularity','starMine',2));
      return state.discoveredDepthEntrances.starMine?routeVisualGuide(depthEntranceGuide('starMine')):null;
    }
    if((state.drillGoalScene||state.drillLevel)&&(state.starforgeVariant||state.drillLevel)){
      const drill=nextDrill(),cost=drillCost();if(!drill||!cost)return null;
      const missing=nextMissingDrillRequirement(cost);
      if(missing)return routeVisualGuide(closestGuideRock(missing.scene,2,missing.type,false));
      if(state.gold<cost.gold)return mineForGoldGuide();
      const forgeScene=currentScene!=='surface'&&currentDepth===2?currentScene:state.visitedDepths.mossMine?'mossMine':MINE_SCENES.find(scene=>state.visitedDepths[scene])||'mossMine';
      return routeVisualGuide(depthForgeGuide(forgeScene));
    }
    if(starforgeMastered())return routeVisualGuide(depthEntranceGuide('mossMine'));
    if(state.emberMastery===5&&!state.fourthUnlocked)return routeVisualGuide(surfaceStationGuide('gate',STATIONS.starfallGate,'#d6d8ff'));
    if(state.fourthUnlocked&&!state.discoveredFourth)return routeVisualGuide(mineEntranceGuide('starMine'));
    if(state.discoveredFourth&&state.mined.astralite===0)return routeVisualGuide(resourceGuide('astralite','surface',1));
    if(state.discoveredFourth&&state.veinsCompleted.starfall_lattice===0){
      const vein=veinById('starfall_lattice'),remaining=surfaceRocks.find(rock=>rock.veinId===vein.id&&!rock.broken);
      if(remaining)return routeVisualGuide(guidePoint('rock','surface',1,remaining.x,remaining.y,vein.color,88,{rockId:remaining.id,resource:remaining.type}));
    }
    if(state.discoveredFourth&&state.mined.crownstone===0)return routeVisualGuide(resourceGuide('crownstone','surface',1));
    if(state.discoveredFourth&&!starforgeMastered())return starforgeGuide();
    if(Object.values(state.mined).every(value=>value===0))return routeVisualGuide(closestGuideRock('surface',1,['stone','copper'],true));
    if(state.totalGold===0)return mineForGoldGuide();
    if(state.pickaxeLevel===1)return purchaseGuide(PICKAXES[2].cost,baseModuleGuide('forge','#f2a35d'));
    if(state.pickaxeLevel===2)return purchaseGuide(PICKAXES[3].cost,baseModuleGuide('forge','#f2a35d'));
    if(!state.areaUnlocked){
      if(state.pickaxeLevel<3)return purchaseGuide(PICKAXES[3].cost,baseModuleGuide('forge','#f2a35d'));
      return purchaseGuide(GATE_COST,surfaceStationGuide('gate',STATIONS.gate,'#9ce7e6'));
    }
    if(!state.discoveredSecond)return routeVisualGuide(mineEntranceGuide('moonMine'));
    if(state.mined.moonglass===0)return routeVisualGuide(resourceGuide('moonglass','surface',1));
    if(state.pickaxeLevel===3)return purchaseGuide(PICKAXES[4].cost,baseModuleGuide('forge','#f2a35d'));
    if(!state.emberdeepUnlocked)return purchaseGuide(EMBER_GATE_COST,surfaceStationGuide('gate',STATIONS.emberGate,'#ff9a68'));
    if(!state.discoveredThird)return routeVisualGuide(mineEntranceGuide('emberMine'));
    if(state.mined.emberstone===0||state.pickaxeLevel===4&&state.cargo.emberstone<EMBER_PICKAXE_ORE_REQUIRED)return routeVisualGuide(resourceGuide('emberstone','surface',1));
    if(state.pickaxeLevel===4)return purchaseGuide(PICKAXES[5].cost,baseModuleGuide('forge','#f2a35d'));
    if(state.mined.gold+state.mined.starshard+state.mined.sunslag===0)return routeVisualGuide(resourceGuide('gold','surface',1));
    if(nextMastery()&&state.cargo.sunslag<nextMastery().sunslag)return routeVisualGuide(resourceGuide('sunslag','surface',1));
    if(nextMastery())return purchaseGuide(nextMastery().gold,baseModuleGuide('forge','#f2a35d'));
    return null;
  }

  function createMineTerrain(scene,depth=1){
    const mine=MINE_DEFINITIONS[scene],cols=Math.ceil(mine.width/MINE_TILE_SIZE),rows=Math.ceil(mine.height/MINE_TILE_SIZE);
    const stateKey=terrainStateKey(scene,depth),terrain={scene,depth,stateKey,cols,rows,maxHp:depth===2?MINE_DEPTH_PROFILES[scene].terrainHp:MINE_TERRAIN_HP,chunks:new Map(),cleared:new Set(),dug:new Set(state.terrainDug[stateKey]||[]),caverns:[],depthEntrance:null};
    const clearCell=(col,row)=>{if(col>=0&&row>=0&&col<cols&&row<rows)terrain.cleared.add(row*cols+col)};
    const clearCircle=(x,y,radius)=>{
      const minCol=Math.max(0,Math.floor((x-radius)/MINE_TILE_SIZE)),maxCol=Math.min(cols-1,Math.floor((x+radius)/MINE_TILE_SIZE));
      const minRow=Math.max(0,Math.floor((y-radius)/MINE_TILE_SIZE)),maxRow=Math.min(rows-1,Math.floor((y+radius)/MINE_TILE_SIZE));
      for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++){
        const cx=(col+.5)*MINE_TILE_SIZE,cy=(row+.5)*MINE_TILE_SIZE;if(distance(cx,cy,x,y)<=radius)clearCell(col,row);
      }
    };
    const clearRect=(x,y,w,h)=>{
      const minCol=Math.max(0,Math.floor(x/MINE_TILE_SIZE)),maxCol=Math.min(cols-1,Math.floor((x+w)/MINE_TILE_SIZE));
      const minRow=Math.max(0,Math.floor(y/MINE_TILE_SIZE)),maxRow=Math.min(rows-1,Math.floor((y+h)/MINE_TILE_SIZE));
      for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++)clearCell(col,row);
    };
    const depthEntrance=depthEntrances[scene];
    if(depth===1){
      clearCircle(mine.entrance.x+54,mine.entrance.y,142);
      for(const wall of mine.solids)clearRect(wall.x,wall.y,wall.w,wall.h);
      for(const barrier of mine.barriers)clearRect(barrier.x-125,barrier.y-62,barrier.w+250,barrier.h+124);
    }else clearCircle(depthEntrance.x,depthEntrance.y,215);
    for(const definition of discoveriesFor(scene,depth).caverns){
      const cavern={...definition,cells:[],cellSet:new Set(),boundary:new Set()};
      const minCol=Math.max(0,Math.floor((cavern.x-cavern.rx)/MINE_TILE_SIZE)),maxCol=Math.min(cols-1,Math.floor((cavern.x+cavern.rx)/MINE_TILE_SIZE));
      const minRow=Math.max(0,Math.floor((cavern.y-cavern.ry)/MINE_TILE_SIZE)),maxRow=Math.min(rows-1,Math.floor((cavern.y+cavern.ry)/MINE_TILE_SIZE));
      for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++){
        const x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE;
        if(Math.pow((x-cavern.x)/cavern.rx,2)+Math.pow((y-cavern.y)/cavern.ry,2)>1)continue;
        const index=row*cols+col;cavern.cells.push(index);cavern.cellSet.add(index);clearCell(col,row);
      }
      terrain.caverns.push(cavern);
    }
    for(const cavern of terrain.caverns){
      for(const index of cavern.cells){
        const col=index%cols,row=Math.floor(index/cols);
        for(const [dc,dr] of [[-1,0],[1,0],[0,-1],[0,1]]){
          const nextCol=col+dc,nextRow=row+dr;if(nextCol<0||nextRow<0||nextCol>=cols||nextRow>=rows)continue;
          const nextIndex=nextRow*cols+nextCol;if(!cavern.cellSet.has(nextIndex)&&!terrain.cleared.has(nextIndex))cavern.boundary.add(nextIndex);
        }
      }
      if([...cavern.boundary].some(index=>terrain.dug.has(index)))state.discoveredCaverns[cavern.id]=true;
      delete cavern.cellSet;
    }
    if(depth===1){
      const shaft={...depthEntrance,cells:[],cellSet:new Set(),boundary:new Set()};
      const minCol=Math.max(0,Math.floor((shaft.x-shaft.radius)/MINE_TILE_SIZE)),maxCol=Math.min(cols-1,Math.floor((shaft.x+shaft.radius)/MINE_TILE_SIZE));
      const minRow=Math.max(0,Math.floor((shaft.y-shaft.radius)/MINE_TILE_SIZE)),maxRow=Math.min(rows-1,Math.floor((shaft.y+shaft.radius)/MINE_TILE_SIZE));
      for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++){
        const x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE;if(distance(x,y,shaft.x,shaft.y)>shaft.radius)continue;
        const index=row*cols+col;shaft.cells.push(index);shaft.cellSet.add(index);terrain.cleared.add(index);
      }
      for(const index of shaft.cells){
        const col=index%cols,row=Math.floor(index/cols);
        for(const [dc,dr] of [[-1,0],[1,0],[0,-1],[0,1]]){
          const nextCol=col+dc,nextRow=row+dr;if(nextCol<0||nextRow<0||nextCol>=cols||nextRow>=rows)continue;
          const nextIndex=nextRow*cols+nextCol;if(!shaft.cellSet.has(nextIndex)&&!terrain.cleared.has(nextIndex))shaft.boundary.add(nextIndex);
        }
      }
      if([...shaft.boundary].some(index=>terrain.dug.has(index)))state.discoveredDepthEntrances[scene]=true;
      delete shaft.cellSet;terrain.depthEntrance=shaft;
    }
    return terrain;
  }

  function rebuildMineTerrain(){for(const scene of MINE_SCENES)mineTerrain[scene]={1:createMineTerrain(scene,1),2:createMineTerrain(scene,2)}}
  function currentTerrain(){return mineTerrain[currentScene]&&mineTerrain[currentScene][currentDepth]||null}
  function terrainChunkAt(terrain,col,row){
    const chunkCol=Math.floor(col/MINE_CHUNK_CELLS),chunkRow=Math.floor(row/MINE_CHUNK_CELLS),key=chunkCol+','+chunkRow;
    let chunk=terrain.chunks.get(key);if(chunk)return chunk;
    const types=new Uint8Array(MINE_CHUNK_CELLS*MINE_CHUNK_CELLS),hp=new Uint16Array(types.length);
    for(let localRow=0;localRow<MINE_CHUNK_CELLS;localRow++)for(let localCol=0;localCol<MINE_CHUNK_CELLS;localCol++){
      const worldCol=chunkCol*MINE_CHUNK_CELLS+localCol,worldRow=chunkRow*MINE_CHUNK_CELLS+localRow;
      if(worldCol>=terrain.cols||worldRow>=terrain.rows)continue;
      const index=worldRow*terrain.cols+worldCol,localIndex=localRow*MINE_CHUNK_CELLS+localCol;
      if(!terrain.cleared.has(index)&&!terrain.dug.has(index)){types[localIndex]=1;hp[localIndex]=terrain.maxHp}
    }
    chunk={col:chunkCol,row:chunkRow,types,hp};terrain.chunks.set(key,chunk);return chunk;
  }
  function terrainLocalIndex(col,row){return row%MINE_CHUNK_CELLS*MINE_CHUNK_CELLS+col%MINE_CHUNK_CELLS}
  function terrainTypeAt(terrain,col,row){
    if(!terrain||col<0||row<0||col>=terrain.cols||row>=terrain.rows)return 0;
    return terrainChunkAt(terrain,col,row).types[terrainLocalIndex(col,row)];
  }
  function terrainHpAt(terrain,col,row){
    if(!terrain||col<0||row<0||col>=terrain.cols||row>=terrain.rows)return 0;
    return terrainChunkAt(terrain,col,row).hp[terrainLocalIndex(col,row)];
  }
  function setTerrainCell(terrain,col,row,type,hp){
    const chunk=terrainChunkAt(terrain,col,row),localIndex=terrainLocalIndex(col,row);
    chunk.types[localIndex]=type;chunk.hp[localIndex]=hp;
  }
  function terrainSolidCellCount(terrain){return terrain.cols*terrain.rows-terrain.cleared.size-[...terrain.dug].filter(index=>!terrain.cleared.has(index)).length}
  function terrainCellAt(terrain,x,y){
    if(!terrain)return null;
    const col=Math.floor(x/MINE_TILE_SIZE),row=Math.floor(y/MINE_TILE_SIZE);
    if(col<0||row<0||col>=terrain.cols||row>=terrain.rows)return null;
    const index=row*terrain.cols+col;return{index,col,row,x:(col+.5)*MINE_TILE_SIZE,y:(row+.5)*MINE_TILE_SIZE,type:terrainTypeAt(terrain,col,row),hp:terrainHpAt(terrain,col,row)};
  }
  function cavernIsDiscovered(id){return !!state.discoveredCaverns[id]}
  function discoverCavernFromCell(terrain,index){
    if(!terrain)return null;
    const cavern=terrain.caverns.find(item=>!cavernIsDiscovered(item.id)&&item.boundary.has(index));if(!cavern)return null;
    state.discoveredCaverns[cavern.id]=true;uiDirty=true;return cavern;
  }
  function discoverDepthEntranceFromCell(terrain,index){
    const entrance=terrain&&terrain.depthEntrance;if(!entrance||state.discoveredDepthEntrances[terrain.scene]||!entrance.boundary.has(index))return null;
    state.discoveredDepthEntrances[terrain.scene]=true;uiDirty=true;return entrance;
  }
  function rockIsExposed(rock){
    if(rock.scene==='surface'||rock.barrierId)return true;
    if(rock.cavernId&&!cavernIsDiscovered(rock.cavernId))return false;
    const terrain=mineTerrain[rock.scene]&&mineTerrain[rock.scene][rock.depth||1],cell=terrainCellAt(terrain,rock.x,rock.y);return !cell||cell.type===0;
  }
  function pocketRewardById(id){for(const scene of MINE_SCENES)for(const depth of [1,2])for(const cavern of discoveriesFor(scene,depth).caverns)if(cavern.reward.id===id)return cavern.reward;return null}
  function pocketRewardLabel(reward){
    if(reward.kind==='cache')return Object.entries(reward.rewards).map(([type,amount])=>amount+' '+ROCK_TYPES[type].label).join(' + ');
    if(reward.kind==='shrine')return 'Mining Rush: 55% faster mining for '+MINING_RUSH_DURATION+' seconds';
    return ROCK_TYPES[reward.type].label+' '+(reward.kind==='crystal'?'cluster':'motherlode');
  }
  function activateMiningRush(){
    miningRush.timer=MINING_RUSH_DURATION;miningRush.lastSecond=Math.ceil(miningRush.timer);uiDirty=true;
  }
  function claimPocketReward(cavern){
    const reward=cavern&&cavern.reward;if(!reward||state.claimedPocketRewards[reward.id])return false;
    if(reward.kind==='crystal'||reward.kind==='motherlode')return false;
    state.claimedPocketRewards[reward.id]=true;
    if(reward.kind==='cache'){
      state.pendingPocketLoot[reward.id]={...reward.rewards};let rewardIndex=0;
      for(const [type,amount] of Object.entries(reward.rewards))spawnGroundDrop(type,amount,cavern.x+(rewardIndex++-1)*18,cavern.y+12,null,currentScene,reward.id,currentDepth);
      sound('chest');
    }else{activateMiningRush();sound('unlock')}
    const visual=currentMineVisual();
    floaters.push({x:cavern.x,y:cavern.y-48,text:reward.kind==='cache'?'CACHE OPENED':'MINING RUSH',color:visual.detail,age:0,life:1.35,size:17});
    miningFeedback.lastPocketReward={id:reward.id,kind:reward.kind,label:reward.label};
    showToast(pocketRewardLabel(reward));saveState(true);return true;
  }
  function updatePocketRewards(){
    const terrain=currentTerrain();if(!terrain)return;
    for(const cavern of terrain.caverns){
      if(!cavernIsDiscovered(cavern.id)||state.claimedPocketRewards[cavern.reward.id])continue;
      if(distance(player.x,player.y,cavern.x,cavern.y)<=Math.min(cavern.rx,cavern.ry)*.7)claimPocketReward(cavern);
    }
  }
  function nearestTerrainCell(range){
    const terrain=currentTerrain();if(!terrain)return null;
    const aimLength=Math.hypot(player.aimX,player.aimY)||1,aimX=player.aimX/aimLength,aimY=player.aimY/aimLength;
    const maxTravel=range+MINE_TILE_SIZE*.65-player.radius,step=MINE_TILE_SIZE/12;
    for(let travel=0;travel<=maxTravel;travel+=step){
      const probeX=player.x+aimX*travel,probeY=player.y+aimY*travel;
      const minCol=Math.max(0,Math.floor((probeX-player.radius)/MINE_TILE_SIZE)),maxCol=Math.min(terrain.cols-1,Math.floor((probeX+player.radius)/MINE_TILE_SIZE));
      const minRow=Math.max(0,Math.floor((probeY-player.radius)/MINE_TILE_SIZE)),maxRow=Math.min(terrain.rows-1,Math.floor((probeY+player.radius)/MINE_TILE_SIZE));
      let best=null,bestLateral=Infinity,bestForward=Infinity;
      for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++){
        const index=row*terrain.cols+col,type=terrainTypeAt(terrain,col,row);if(!type)continue;
        const left=col*MINE_TILE_SIZE,top=row*MINE_TILE_SIZE,nearestX=clamp(probeX,left,left+MINE_TILE_SIZE),nearestY=clamp(probeY,top,top+MINE_TILE_SIZE);
        if(distance(probeX,probeY,nearestX,nearestY)>=player.radius)continue;
        const x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE,dx=x-player.x,dy=y-player.y;
        const forward=dx*aimX+dy*aimY,lateral=Math.abs(dx*-aimY+dy*aimX);
        if(lateral<bestLateral-.01||Math.abs(lateral-bestLateral)<.01&&forward<bestForward){
          bestLateral=lateral;bestForward=forward;best={index,col,row,x,y,type,hp:terrainHpAt(terrain,col,row)};
        }
      }
      if(best)return best;
    }
    return null;
  }
  function terrainCollidesCircle(x,y){
    const terrain=currentTerrain();if(!terrain)return false;
    const minCol=Math.max(0,Math.floor((x-player.radius)/MINE_TILE_SIZE)),maxCol=Math.min(terrain.cols-1,Math.floor((x+player.radius)/MINE_TILE_SIZE));
    const minRow=Math.max(0,Math.floor((y-player.radius)/MINE_TILE_SIZE)),maxRow=Math.min(terrain.rows-1,Math.floor((y+player.radius)/MINE_TILE_SIZE));
    for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++){
      if(!terrainTypeAt(terrain,col,row))continue;
      const left=col*MINE_TILE_SIZE,top=row*MINE_TILE_SIZE,nearestX=clamp(x,left,left+MINE_TILE_SIZE),nearestY=clamp(y,top,top+MINE_TILE_SIZE);
      if(distance(x,y,nearestX,nearestY)<player.radius)return true;
    }
    return false;
  }

  function startBackgroundMusic(){
    if(typeof Audio==='undefined')return;
    if(!audioSettings.music){if(backgroundMusic&&!backgroundMusic.paused)backgroundMusic.pause();musicStarted=false;return}
    if(!backgroundMusic){
      backgroundMusic=new Audio(MUSIC_PATH);backgroundMusic.loop=true;backgroundMusic.preload='auto';backgroundMusic.volume=MUSIC_VOLUME;backgroundMusic.playsInline=true;
    }
    if(!backgroundMusic.paused)return;
    const playback=backgroundMusic.play();
    if(playback&&typeof playback.then==='function')playback.then(()=>{musicStarted=true}).catch(()=>{});else musicStarted=true;
  }

  function syncAudioSettingsUI(){
    musicToggle.setAttribute('aria-pressed',String(audioSettings.music));
    effectsToggle.setAttribute('aria-pressed',String(audioSettings.effects));
  }

  function setAudioSetting(kind,enabled){
    if(!Object.prototype.hasOwnProperty.call(audioSettings,kind))return false;
    audioSettings[kind]=!!enabled;persistAudioSettings();syncAudioSettingsUI();
    if(kind==='music'){
      if(audioSettings.music)startBackgroundMusic();
      else{if(backgroundMusic&&!backgroundMusic.paused)backgroundMusic.pause();musicStarted=false}
    }else if(audioSettings.effects&&audioContext&&audioContext.state==='suspended')audioContext.resume();
    return audioSettings[kind];
  }

  function renderPatchNotes(){
    patchNotesList.innerHTML=PATCH_NOTES.map((note,index)=>'<article class="patch-note'+(index===0?' latest':'')+'"><header><div><span>v'+note.version+'</span><time>'+note.date+'</time></div><h4>'+note.title+'</h4></header><ul>'+note.items.map(item=>'<li>'+item+'</li>').join('')+'</ul></article>').join('');
  }

  function syncMenuReturnButton(){
    resumeButton.textContent=menuShade.dataset.view==='patchnotes'?'BACK TO SETTINGS':menuShade.dataset.source==='start'?'BACK TO MAIN MENU':'RETURN TO MINE';
  }

  function setMenuTab(name){
    if(!['settings','stats','achievements','patchnotes'].includes(name))name='settings';
    const tabs={settings:settingsTab,stats:statsTab},panels={settings:settingsPanel,stats:statsPanel};
    for(const [key,tab] of Object.entries(tabs)){const active=key===name;tab.classList.toggle('active',active);tab.setAttribute('aria-selected',String(active));panels[key].hidden=!active}
    achievementsPanel.hidden=name!=='achievements';menuShade.dataset.view=name;
    patchNotesPanel.hidden=name!=='patchnotes';
    menuTitle.textContent=name==='stats'?'Stats':name==='achievements'?'Achievements':name==='patchnotes'?'Patch Notes':'Settings';
    menuCloseButton.setAttribute('aria-label','Close '+menuTitle.textContent.toLowerCase());
    if(name==='stats')updateLedger();else if(name==='achievements')renderAchievementList();else if(name==='patchnotes')renderPatchNotes();
    syncMenuReturnButton();
  }

  function showOverlayMenu(name,source){
    unlockAudio();if(hubBuild.active)setHubBuildMode(false);releaseTouchControls();inventoryShade.hidden=true;menuShade.dataset.source=source;setMenuTab(name);menuShade.hidden=false;syncAchievementPopup();
  }

  function enterGame(){
    unlockAudio();startScreen.hidden=true;menuShade.hidden=true;inventoryShade.hidden=true;lastFrame=0;saveState(true);syncAchievementPopup();if(!maybeShowHeatTutorial())maybeShowHubTutorial();
  }

  function showHeatTutorial(){
    if(!heatStreakUnlocked()||state.heatStreakTutorialSeen||!startScreen.hidden)return false;
    releaseTouchControls();heatTutorialShade.hidden=false;return true;
  }

  function maybeShowHeatTutorial(){return showHeatTutorial()}

  function dismissHeatTutorial(){
    heatTutorialShade.hidden=true;state.heatStreakTutorialSeen=true;saveState(true);lastFrame=0;syncAchievementPopup();maybeShowHubTutorial();return true;
  }

  function showHubTutorial(){
    if(!state.hub.unlocked||state.hub.tutorialSeen||!startScreen.hidden||!heatTutorialShade.hidden)return false;
    releaseTouchControls();setHubBuildMode(false);hubTutorialShade.hidden=false;syncAchievementPopup();return true;
  }

  function maybeShowHubTutorial(){return showHubTutorial()}

  function dismissHubTutorial(){
    hubTutorialShade.hidden=true;state.hub.tutorialSeen=true;saveState(true);lastFrame=0;syncAchievementPopup();return true;
  }

  function startNewGame(){
    if(loadedExistingSave&&!window.confirm('Start a new game and replace your current expedition?'))return;
    resetProgress();loadedExistingSave=true;continueButton.disabled=false;continueDetail.textContent='MOSSVEIN QUARRY';enterGame();
  }

  function unlockAudio(){
    startBackgroundMusic();
    if(audioUnlocked){if(audioContext&&audioContext.state==='suspended')audioContext.resume();return}
    try{
      audioContext=new(window.AudioContext||window.webkitAudioContext)();audioUnlocked=true;
      impactNoiseBuffer=audioContext.createBuffer(1,Math.ceil(audioContext.sampleRate*.22),audioContext.sampleRate);
      const channel=impactNoiseBuffer.getChannelData(0);
      for(let index=0;index<channel.length;index++)channel[index]=(Math.random()*2-1)*Math.pow(1-index/channel.length,1.8);
    }catch(error){}
  }

  function playTone(startFrequency,endFrequency,duration,volume,type,delay){
    const start=audioContext.currentTime+(delay||0),oscillator=audioContext.createOscillator(),gain=audioContext.createGain();
    oscillator.type=type||'triangle';oscillator.frequency.setValueAtTime(startFrequency,start);oscillator.frequency.exponentialRampToValueAtTime(Math.max(20,endFrequency),start+duration);
    gain.gain.setValueAtTime(volume,start);gain.gain.exponentialRampToValueAtTime(.001,start+duration);
    oscillator.connect(gain);gain.connect(audioContext.destination);oscillator.start(start);oscillator.stop(start+duration);
  }

  function playImpactNoise(duration,volume,frequency,delay){
    if(!impactNoiseBuffer)return;
    const start=audioContext.currentTime+(delay||0),source=audioContext.createBufferSource(),filter=audioContext.createBiquadFilter(),gain=audioContext.createGain();
    source.buffer=impactNoiseBuffer;filter.type='lowpass';filter.frequency.setValueAtTime(frequency,start);
    gain.gain.setValueAtTime(volume,start);gain.gain.exponentialRampToValueAtTime(.001,start+duration);
    source.connect(filter);filter.connect(gain);gain.connect(audioContext.destination);source.start(start);source.stop(start+duration);
  }

  function playPickaxeTink(materialTone,emphasis=1,delay=0){
    const pitch=1320+materialTone*.58+(state.pickaxeLevel-1)*42;
    playTone(pitch*1.07,pitch,.058,.052*emphasis,'sine',delay);
    playTone(pitch*1.94,pitch*1.66,.034,.022*emphasis,'triangle',delay+.002);
    playTone(330,235,.044,.012*emphasis,'triangle',delay+.004);
  }

  function miningKick(strength,hapticDuration){
    // Keep impact weight in timing, premium terrain responses and optional haptics without
    // moving or flashing the entire screen during repeated mining.
    miningFeedback.shake=0;
    miningFeedback.shakeTime=0;
    miningFeedback.flash=0;
    // Rapid drills need continuous simulation. Repeated hit-stop at drill speed
    // reads as frame loss even when rendering is holding a steady frame rate.
    if(currentDrill())miningFeedback.hitStop=0;
    else miningFeedback.hitStop=Math.max(miningFeedback.hitStop,strength>=7?.065:strength>=4?.038:.016);
    if(hapticDuration&&navigator.vibrate&&time-lastHapticAt>.065){
      try{navigator.vibrate(hapticDuration);lastHapticAt=time}catch(error){}
    }
  }

  function sound(kind,resourceType,intensity){
    if(!audioSettings.effects||!audioContext)return;
    const materialTone={stone:0,copper:95,moonglass:260,gold:175,starshard:340,emberstone:-25,sunslag:125,astralite:410,crownstone:520}[resourceType]||0;
    if(kind==='precision'){
      playPickaxeTink(materialTone,1.34);playTone(1780+materialTone,2380+materialTone,.075,.026,'sine',.018);
    }else if(kind==='hit'){
      const strength=(state.pickaxeLevel-1)*18;
      if(currentDrill()){playTone(105-strength*.35,52,.1,.09,'triangle');playTone(680+strength+materialTone,230+materialTone*.25,.048,.026,'square',.004);playImpactNoise(.055,.032,1050+strength*8+materialTone,.003)}
      else playPickaxeTink(materialTone);
    }else if(kind==='break'){
      playTone(82,32,.22,.13,'triangle');playTone(310+materialTone,88+materialTone*.25,.13,.042,'square',.008);playImpactNoise(.18,.085,760+materialTone);
    }else if(kind==='coin'){
      playTone(610,920,.13,.075,'triangle');playTone(880,1240,.1,.045,'sine',.055);
    }else if(kind==='chest'){
      playTone(145,92,.18,.085,'triangle');playImpactNoise(.11,.045,720);
      playTone(520,820,.15,.05,'sine',.08);playTone(760,1280,.22,.042,'sine',.16);
    }else if(kind==='upgrade'){
      playTone(250,510,.28,.1,'triangle');playTone(440,900,.32,.065,'sine',.08);
    }else if(kind==='unlock'){
      playTone(155,390,.52,.12,'sine');playTone(245,680,.58,.065,'triangle',.09);
    }else if(kind==='achievement'){
      playTone(330,720,.34,.09,'triangle');playTone(540,1120,.48,.065,'sine',.06);playTone(880,1540,.38,.04,'triangle',.19);
    }else if(kind==='vein'){
      playTone(210,520,.22,.1,'triangle');playTone(420,980,.34,.07,'sine',.06);playTone(720,1320,.2,.04,'triangle',.16);
    }else if(kind==='veinStep'){
      const progress=clamp(Number(intensity)||0,0,1),lift=progress*420;
      playTone(190+materialTone*.2+lift,330+materialTone*.25+lift,.085,.052,'triangle');playTone(420+lift,610+lift,.07,.026,'sine',.025);
    }else if(kind==='jackpot'){
      playTone(180+materialTone*.2,510+materialTone*.25,.22,.105,'triangle');playTone(420+materialTone*.25,940+materialTone*.35,.28,.075,'sine',.055);playTone(680+materialTone*.2,1380+materialTone*.3,.34,.052,'triangle',.13);
    }else if(kind==='discovery'){
      playImpactNoise(.16,.075,920+materialTone,.002);playTone(170,360,.2,.095,'triangle');playTone(480+materialTone,980+materialTone,.3,.07,'sine',.055);playTone(760+materialTone,1480+materialTone,.36,.045,'sine',.13);
    }else if(kind==='pickup'){
      playTone(440+materialTone*.35,820+materialTone*.45,.075,.035,'sine');playTone(690+materialTone*.3,1050+materialTone*.35,.06,.022,'triangle',.035);
    }else{
      playTone(100,72,.085,.04,'square');
    }
  }

  function showToast(message){
    toast.textContent=message;toast.classList.add('show');clearTimeout(toastTimer);
    toastTimer=setTimeout(()=>toast.classList.remove('show'),1450);
  }

  function showAreaBanner(name){
    areaBannerName.textContent=name||'MOONGLASS CAVERN';
    areaBanner.dataset.area=name==='UNDERGROUND HUB'?'hub':name==='STARFALL DEPTHS'?'starfall':name==='EMBERDEEP FOUNDRY'?'ember':name==='MOSSVEIN QUARRY'?'mossvein':'moonglass';
    areaBanner.classList.add('show');clearTimeout(bannerTimer);
    bannerTimer=setTimeout(()=>areaBanner.classList.remove('show'),2200);
  }

  function worldToScreen(x,y){return{x:x-camera.x,y:y-camera.y}}
  function screenToWorld(x,y){return{x:x/viewZoom+camera.x,y:y/viewZoom+camera.y}}

  function colorWithAlpha(color,alpha){
    const value=String(color||'#ffffff').replace('#','');
    const hex=value.length===3?value.split('').map(part=>part+part).join(''):value;
    const number=parseInt(hex.slice(0,6),16);if(!Number.isFinite(number))return'rgba(255,255,255,'+alpha+')';
    return'rgba('+((number>>16)&255)+','+((number>>8)&255)+','+(number&255)+','+alpha+')';
  }

  function lightBlockedAt(x,y,terrain,solids,world){
    lightingRayChecks++;
    if(x<0||y<0||x>=world.width||y>=world.height)return true;
    if(terrain&&terrainTypeAt(terrain,Math.floor(x/MINE_TILE_SIZE),Math.floor(y/MINE_TILE_SIZE)))return true;
    for(const solid of solids)if(x>=solid.x&&x<=solid.x+solid.w&&y>=solid.y&&y<=solid.y+solid.h)return true;
    return false;
  }

  function traceLightDistance(originX,originY,angle,length,terrain,solids,world){
    const dx=Math.cos(angle),dy=Math.sin(angle),step=LIGHTING.rayStep;
    for(let travelled=step;travelled<=length;travelled+=step){
      if(lightBlockedAt(originX+dx*travelled,originY+dy*travelled,terrain,solids,world))return Math.max(5,travelled-step*.3);
    }
    return length;
  }

  function traceLightPolygon(originX,originY,startAngle,angleSpan,rays,length,terrain,solids,world,traceOriginX=originX,traceOriginY=originY){
    const points=[];
    for(let index=0;index<=rays;index++){
      const angle=startAngle+angleSpan*index/rays,reach=traceLightDistance(traceOriginX,traceOriginY,angle,length,terrain,solids,world);
      points.push(worldToScreen(originX+Math.cos(angle)*reach,originY+Math.sin(angle)*reach));
    }
    return points;
  }

  function fillLightPolygon(target,origin,points,fillStyle){
    if(!points.length)return;
    target.beginPath();target.moveTo(origin.x,origin.y);for(const point of points)target.lineTo(point.x,point.y);target.closePath();target.fillStyle=fillStyle;target.fill();
  }

  function visibleNaturalLights(terrain,solids,world){
    const stones=[],ores=[],wallOres=[],landmarks=[],centerX=camera.x+viewWidth*.5,centerY=camera.y+viewHeight*.5;
    const add=(list,kind,worldX,worldY,color,radius,intensity,tint,rays=LIGHTING.oreRays)=>{
      const screen=worldToScreen(worldX,worldY);if(screen.x+radius<0||screen.y+radius<0||screen.x-radius>viewWidth||screen.y-radius>viewHeight)return;
      list.push({kind,worldX,worldY,x:screen.x,y:screen.y,color,radius,intensity,tint,rays});
    };
    for(const rock of currentRocks()){
      if(rock.broken||!rockIsExposed(rock))continue;
      const data=ROCK_TYPES[rock.type],stone=rock.type==='stone'||rock.type==='deepstone';
      if(stone)add(stones,'stone',rock.x,rock.y,data.edge,52,LIGHTING.stoneIntensity,.035,8);
      else add(ores,'rockOre',rock.x,rock.y,data.edge,data.rare?118:data.depth2?104:94,data.rare?LIGHTING.rareRockOreIntensity:LIGHTING.rockOreIntensity,data.rare?.24:.17,data.rare?16:12);
    }
    for(const hint of currentMineralHints()){
      const rock=hint.rock;if(rock.type==='stone'||rock.type==='deepstone')continue;
      const col=hint.index%terrain.cols,row=Math.floor(hint.index/terrain.cols),side=hint.sides[0]||0,direction=[[0,-1],[1,0],[0,1],[-1,0]][side],data=ROCK_TYPES[rock.type];
      const worldX=(col+.5)*MINE_TILE_SIZE+direction[0]*30,worldY=(row+.5)*MINE_TILE_SIZE+direction[1]*30;
      add(wallOres,'wallOre',worldX,worldY,data.edge,data.rare?148:132,data.rare?LIGHTING.rareWallOreIntensity:LIGHTING.wallOreIntensity,data.rare?.3:.23,data.rare?18:14);
    }
    for(const cavern of terrain.caverns){
      if(!cavernIsDiscovered(cavern.id))continue;
      const claimed=!!state.claimedPocketRewards[cavern.reward.id];
      add(landmarks,claimed?'bonusCrystalCollected':'bonusCrystal',cavern.x,cavern.y,currentMineVisual().detail,claimed?205:236,claimed?LIGHTING.collectedBonusCrystalIntensity:LIGHTING.bonusCrystalIntensity,claimed?.28:.4,20);
    }
    if(state.discoveredDepthEntrances[currentScene]){
      const entrance=depthEntrances[currentScene];
      const lampOffset=DEPTH_LAMP_OFFSETS[currentScene]||DEPTH_LAMP_OFFSETS.default;
      add(landmarks,'depthLamp',entrance.x+lampOffset.x,entrance.y+lampOffset.y,'#ffd58a',228,LIGHTING.depthLampIntensity,.25,20);
    }
    const nearest=(list,limit)=>list.sort((a,b)=>((a.worldX-centerX)**2+(a.worldY-centerY)**2)-((b.worldX-centerX)**2+(b.worldY-centerY)**2)).slice(0,limit);
    const lights=[...nearest(landmarks,4),...nearest(wallOres,6),...nearest(ores,8),...nearest(stones,4)].slice(0,LIGHTING.maxNaturalLights);
    for(const light of lights)light.points=traceLightPolygon(light.worldX,light.worldY,-Math.PI,Math.PI*2,light.rays,light.radius,terrain,solids,world);
    return lights;
  }

  function drawMineLighting(){
    if(!lightCtx||!lightCanvas||!currentMine())return;
    const terrain=currentTerrain(),solids=activeMineSolids(),world=currentWorld(),helmet=playerHelmetLightOffsets();
    const aimLength=Math.hypot(player.aimX,player.aimY)||1,dirX=player.aimX/aimLength,dirY=player.aimY/aimLength,angle=Math.atan2(dirY,dirX);
    const originWorld={x:player.x+helmet.x,y:player.y+helmet.y},traceOriginWorld={x:player.x+helmet.traceX,y:player.y+helmet.traceY},origin=worldToScreen(originWorld.x,originWorld.y);
    lightingRayChecks=0;
    const ambientPoints=traceLightPolygon(originWorld.x,originWorld.y,-Math.PI,Math.PI*2,LIGHTING.ambientRays,LIGHTING.ambientRadius,terrain,solids,world,traceOriginWorld.x,traceOriginWorld.y);
    const outerPoints=traceLightPolygon(originWorld.x,originWorld.y,angle-LIGHTING.beamHalfAngle,LIGHTING.beamHalfAngle*2,LIGHTING.beamRays,LIGHTING.beamLength,terrain,solids,world,traceOriginWorld.x,traceOriginWorld.y);
    const corePoints=traceLightPolygon(originWorld.x,originWorld.y,angle-LIGHTING.beamCoreHalfAngle,LIGHTING.beamCoreHalfAngle*2,Math.round(LIGHTING.beamRays*.7),LIGHTING.beamLength*.92,terrain,solids,world,traceOriginWorld.x,traceOriginWorld.y);
    const naturalLights=visibleNaturalLights(terrain,solids,world);lightingLastSources=naturalLights.map(light=>({kind:light.kind,intensity:light.intensity,radius:light.radius,worldX:light.worldX,worldY:light.worldY}));lightingOreCount=naturalLights.filter(light=>light.kind==='rockOre'||light.kind==='wallOre').length;

    lightCtx.setTransform(1,0,0,1,0,0);lightCtx.clearRect(0,0,lightCanvas.width,lightCanvas.height);
    lightCtx.setTransform(LIGHTING.bufferScale,0,0,LIGHTING.bufferScale,0,0);lightCtx.globalCompositeOperation='source-over';
    lightCtx.fillStyle=currentDepth===2?'rgba(1,2,4,'+LIGHTING.darknessDepth2+')':'rgba(2,4,5,'+LIGHTING.darknessDepth1+')';lightCtx.fillRect(0,0,viewWidth,viewHeight);
    lightCtx.globalCompositeOperation='destination-out';
    const ambient=lightCtx.createRadialGradient(origin.x,origin.y,0,origin.x,origin.y,LIGHTING.ambientRadius);ambient.addColorStop(0,'rgba(0,0,0,.98)');ambient.addColorStop(.52,'rgba(0,0,0,.72)');ambient.addColorStop(1,'rgba(0,0,0,0)');fillLightPolygon(lightCtx,origin,ambientPoints,ambient);
    const beamEnd={x:origin.x+dirX*LIGHTING.beamLength,y:origin.y+dirY*LIGHTING.beamLength};
    const outer=lightCtx.createLinearGradient(origin.x,origin.y,beamEnd.x,beamEnd.y);outer.addColorStop(0,'rgba(0,0,0,.44)');outer.addColorStop(.72,'rgba(0,0,0,.3)');outer.addColorStop(1,'rgba(0,0,0,0)');fillLightPolygon(lightCtx,origin,outerPoints,outer);
    const core=lightCtx.createLinearGradient(origin.x,origin.y,beamEnd.x,beamEnd.y);core.addColorStop(0,'rgba(0,0,0,.9)');core.addColorStop(.68,'rgba(0,0,0,.76)');core.addColorStop(1,'rgba(0,0,0,.08)');fillLightPolygon(lightCtx,origin,corePoints,core);
    for(const light of naturalLights){
      const glow=lightCtx.createRadialGradient(light.x,light.y,1,light.x,light.y,light.radius);glow.addColorStop(0,'rgba(0,0,0,'+light.intensity+')');glow.addColorStop(.35,'rgba(0,0,0,'+(light.intensity*.62)+')');glow.addColorStop(1,'rgba(0,0,0,0)');fillLightPolygon(lightCtx,light,light.points,glow);
    }
    lightCtx.globalCompositeOperation='source-over';

    ctx.save();ctx.drawImage(lightCanvas,0,0,lightCanvas.width,lightCanvas.height,0,0,viewWidth,viewHeight);ctx.globalCompositeOperation='screen';
    const warm=ctx.createLinearGradient(origin.x,origin.y,beamEnd.x,beamEnd.y);warm.addColorStop(0,'rgba(255,218,145,.095)');warm.addColorStop(.7,'rgba(255,201,112,.045)');warm.addColorStop(1,'rgba(255,190,95,0)');fillLightPolygon(ctx,origin,corePoints,warm);
    for(const light of naturalLights){
      const tint=ctx.createRadialGradient(light.x,light.y,0,light.x,light.y,light.radius);tint.addColorStop(0,colorWithAlpha(light.color,light.tint));tint.addColorStop(.34,colorWithAlpha(light.color,light.tint*.46));tint.addColorStop(1,colorWithAlpha(light.color,0));fillLightPolygon(ctx,light,light.points,tint);
    }
    const lens=ctx.createRadialGradient(origin.x,origin.y,0,origin.x,origin.y,21);lens.addColorStop(0,'rgba(255,248,201,.95)');lens.addColorStop(.22,'rgba(255,219,139,.52)');lens.addColorStop(1,'rgba(255,192,87,0)');ctx.fillStyle=lens;ctx.fillRect(origin.x-22,origin.y-22,44,44);ctx.restore();
  }

  function playerHelmetLightOffsets(){
    const walking=!player.swing&&!input.mineHeld&&imageReady(PLAYER_ART.walkSheets[activePlayerWalkKey()]);
    if(walking){
      const base=PLAYER_WALK_LIGHT_OFFSETS[player.direction]||PLAYER_WALK_LIGHT_OFFSETS.right,bob=reducedMotion?0:PLAYER_WALK_FRAME_BOB[player.walkFrame]||0;
      return{x:base.x,y:base.y+bob,traceX:base.x*.42,traceY:-12+bob};
    }
    const bob=reducedMotion?0:player.moving?Math.sin(player.walk)*2:Math.sin(time*2.4)*1.2;
    return{x:player.facing*20,y:-58+bob,traceX:player.facing*8,traceY:-12+bob};
  }

  function updateObjectiveOcclusion(){
    const p=worldToScreen(player.x,player.y),playerX=p.x*viewZoom,playerY=p.y*viewZoom;
    const left=(viewport.clientWidth-objective.offsetWidth)/2,top=objective.offsetTop;
    const overlaps=playerX+40>left&&playerX-40<left+objective.offsetWidth&&playerY+34>top&&playerY-64<top+objective.offsetHeight;
    objective.classList.toggle('player-overlap',overlaps);
  }

  function updateCamera(immediate){
    const world=currentWorld();
    const targetX=clamp(player.x-viewWidth*.5,0,Math.max(0,world.width-viewWidth));
    const targetY=clamp(player.y-viewHeight*.5,0,Math.max(0,world.height-viewHeight));
    if(immediate){camera.x=targetX;camera.y=targetY;return}
    camera.x+=(targetX-camera.x)*.105;camera.y+=(targetY-camera.y)*.105;
  }

  function nearestRock(range){
    let best=null,bestDistance=Infinity;
    for(const rock of currentRocks()){
      if(rock.broken||!rockIsExposed(rock))continue;
      const d=distance(player.x,player.y,rock.x,rock.y);
      if(d<bestDistance&&d<=range){bestDistance=d;best=rock}
    }
    return best;
  }

  function startSwing(manualPress){
    if(inHub())return false;
    if(player.swing||player.swingCooldown>0)return false;
    const rock=nearestRock(MINING_RANGE),terrainTarget=rock?null:nearestTerrainCell(MINING_RANGE);
    if(!rock&&!terrainTarget){if(manualPress)sound('empty');if(!input.mineHeld)showToast(currentMine()?'Face the mountain to dig.':'Move closer to a rock.');player.swingCooldown=.16;return false}
    if(heatStreakUnlocked()&&input.mineHeld)heatStreak.active=true;
    if(terrainTarget){
      player.facing=terrainTarget.x>=player.x?1:-1;player.hitRockId=null;player.hitTerrainIndex=terrainTarget.index;
      player.swing={elapsed:0,duration:currentCooldown(),hit:false,precision:false,target:'terrain'};
      state.totalSwings++;uiDirty=true;return true;
    }
    const precision=!!manualPress&&rock.glintActive>0;
    if(precision){
      rock.glintActive=0;rock.glintTimer=(2.3+Math.random()*1.7)*currentPrecisionDelay();rock.bonusYield=1;
      miningFocus.streak=Math.min(5,miningFocus.streak+1);miningFocus.timer=7;
      if(miningFocus.streak===5)floaters.push({x:player.x,y:player.y-62,text:'FOCUS MAX',color:'#ffe69a',age:0,life:1.05,size:15});
      uiDirty=true;
    }else if(manualPress&&miningFocus.streak){
      miningFocus.streak=0;miningFocus.timer=0;uiDirty=true;
    }
    player.facing=rock.x>=player.x?1:-1;player.hitRockId=rock.id;player.hitTerrainIndex=-1;
    player.swing={elapsed:0,duration:currentCooldown(),hit:false,precision,target:'rock'};
    state.totalSwings++;uiDirty=true;return true;
  }

  function hitRock(rock,precision){
    if(!rock||rock.broken)return;
    if(rock.requiresDrillLevel&&state.drillLevel<rock.requiresDrillLevel){
      const required=DRILLS[rock.requiresDrillLevel];rock.hit=.12;sound('empty');
      floaters.push({x:rock.x,y:rock.y-36,text:required.name.toUpperCase()+' REQUIRED',color:required.color,age:0,life:1,size:12});
      showToast(ROCK_TYPES[rock.type].label+' requires the '+required.name+'.');return;
    }
    if(rock.requiresDeepTool&&!hasDeepTool()){
      rock.hit=.12;sound('empty');floaters.push({x:rock.x,y:rock.y-36,text:'STARFORGE REQUIRED',color:'#e8c98b',age:0,life:.9,size:12});return;
    }
    if(rock.requiredPickaxe>state.pickaxeLevel){
      const required=PICKAXES[rock.requiredPickaxe];rock.hit=.12;sound('empty');
      floaters.push({x:rock.x,y:rock.y-36,text:required.name.toUpperCase()+' REQUIRED',color:'#e8c98b',age:0,life:.9,size:12});
      return;
    }
    const power=currentPower(),focusBonus=1+Math.max(0,miningFocus.streak-1)*.06,damage=precision?Math.ceil(power*2.25*focusBonus):power;
    if(rock.shell>0){
      const shellMultiplier=precision?1.7:currentShellPower(),previousShell=rock.shell;
      const shellDamage=Math.ceil(damage*shellMultiplier);
      rock.shell=Math.max(0,rock.shell-shellDamage);
      if(rock.shell===0){
        const overflow=Math.max(0,shellDamage-previousShell),carryDamage=Math.floor(overflow/shellMultiplier);
        if(carryDamage>0)rock.hp=Math.max(0,rock.hp-carryDamage);
        sound('precision',rock.type);
      }
    }else rock.hp=Math.max(0,rock.hp-damage);
    rock.hit=.16;
    sound(precision?'precision':'hit',rock.type);spawnImpact(rock.x,rock.y,precision);
    miningKick(precision?4.8:2.3,precision?18:8);
    if(precision){state.precisionHits++;floaters.push({x:rock.x,y:rock.y-37,text:'PRECISION!',color:'#fff2a6',age:0,life:.9,size:14})}
    if(rock.shell<=0&&rock.hp<=0)breakRock(rock);
  }

  function hitTerrain(index){
    const terrain=currentTerrain(),cellCount=terrain?terrain.cols*terrain.rows:0;if(!terrain||index<0||index>=cellCount)return;
    const col=index%terrain.cols,row=Math.floor(index/terrain.cols),x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE;
    const type=terrainTypeAt(terrain,col,row);if(!type)return;
    if(currentDepth===2&&!hasDeepTool()){
      sound('empty');floaters.push({x,y:y-28,text:'STARFORGE REQUIRED',color:'#e8c98b',age:0,life:.9,size:12});showToast('Depth 2 stone requires a Starforge pickaxe.');return;
    }
    const hp=Math.max(0,terrainHpAt(terrain,col,row)-currentPower());setTerrainCell(terrain,col,row,type,hp);
    miningFeedback.terrainHitIndex=index;miningFeedback.terrainHitTime=.16;
    const visual=currentMineVisual(),tunnelMaterial=currentDepth===2?'deepstone':'stone';spawnImpact(x,y,false);sound('hit',tunnelMaterial);miningKick(hp>0?2.4:4.2,hp>0?8:14);
    if(hp>0)return;
    setTerrainCell(terrain,col,row,0,0);terrain.dug.add(index);
    state.terrainDug[terrain.stateKey].push(index);
    state.mined[tunnelMaterial]++;spawnGroundDrop(tunnelMaterial,1,x,y);spawnBreak(x,y,tunnelMaterial);sound('break',tunnelMaterial);
    const cavern=discoverCavernFromCell(terrain,index);
    const depthEntrance=discoverDepthEntranceFromCell(terrain,index);
    if(cavern){
      floaters.push({x,y:y-48,text:'HIDDEN CHAMBER',color:visual.detail,age:0,life:1.5,size:17});
    }
    if(depthEntrance){
      showAreaBanner('DEPTH 2 ENTRANCE');sound('unlock');miningKick(7,24);
    }
    const cellKey=currentScene+':'+currentDepth+':'+index,candidates=(mineRocksByTerrainCell.get(cellKey)||[]).concat(cavern?mineRocksByCavern.get(cavern.id)||[]:[]);
    const revealed=[...new Set(candidates)].filter(rock=>!rock.broken&&rockIsExposed(rock));
    const primaryReveal=revealed.find(rock=>rock.rareFind)||revealed[0];
    if(revealed.length){
      const rock=primaryReveal,data=ROCK_TYPES[rock.type],label=rock.rareFind?'RARE '+data.label.toUpperCase():rock.depositId?data.label.toUpperCase()+' VEIN':data.label.toUpperCase()+' REVEALED';
      spawnDiscoveryBurst(rock,label);
    }
    if(cavern&&!revealed.length&&!depthEntrance){sound('unlock');miningKick(6,20)}
    terrainSaveDelay=.4;uiDirty=true;
  }

  function breakRock(rock){
    const vein=rock.veinId?veinById(rock.veinId):null;
    rock.broken=true;rock.respawn=rock.barrierId?Infinity:vein?vein.respawn:ROCK_TYPES[rock.type].respawn;
    const yieldAmount=1+rock.bonusYield+(Math.random()<currentBonusYieldChance()?1:0);
    state.mined[rock.type]+=yieldAmount;spawnGroundDrop(rock.type,yieldAmount,rock.x,rock.y);
    if(rock.type==='singularity'&&rock.scene==='starMine'&&rock.depth===2&&currentScene==='starMine'&&currentDepth===2&&state.drillLevel===DRILLS.length-1&&!state.victory){state.victory=true;state.hub.unlocked=true;showToast('Voidstar conquered. The Underground Hub is unlocked.');showHubTutorial()}
    sound('break',rock.type);spawnBreak(rock.x,rock.y,rock.type);miningKick(ROCK_TYPES[rock.type].rare?7:4.6,ROCK_TYPES[rock.type].rare?24:14);rock.bonusYield=0;
    registerDepositBreak(rock);
    if(rock.pocketRewardId)registerPocketDepositBreak(rock);
    if(vein)registerVeinBreak(vein,rock);
    if(rock.barrierId){
      const remaining=mineRocks.some(item=>item.barrierId===rock.barrierId&&!item.broken);
      if(!remaining){
        state.clearedMineBarriers[rock.barrierId]=true;
        const barrier=mineBarrierById(rock.barrierId);sound('unlock');
        floaters.push({x:barrier.x+barrier.w*.5,y:barrier.y+barrier.h*.5-52,text:'PASSAGE OPEN',color:'#ffe2a0',age:0,life:1.3,size:17});
      }
    }
    uiDirty=true;saveState();
  }

  function registerPocketDepositBreak(rock){
    const reward=pocketRewardById(rock.pocketRewardId);if(!reward||state.claimedPocketRewards[reward.id])return;
    const rewardRocks=mineRocks.filter(item=>item.pocketRewardId===reward.id);if(rewardRocks.some(item=>!item.broken))return;
    state.claimedPocketRewards[reward.id]=true;for(const item of rewardRocks)item.respawn=Infinity;
    const bonusType=reward.kind==='crystal'?reward.type:(currentDepth===2?DEPTH2_RESOURCE_PROFILES[currentScene]:MINE_DISCOVERY_PROFILES[currentScene]).main;
    state.pendingPocketLoot[reward.id]={[bonusType]:1};spawnGroundDrop(bonusType,1,rock.x,rock.y,null,currentScene,reward.id);
    sound('jackpot',reward.type);
    floaters.push({x:rock.x,y:rock.y-52,text:reward.kind==='crystal'?'CLUSTER CLEARED':'MOTHERLODE CLEARED',color:'#fff2bd',age:0,life:1.5,size:18});
    miningFeedback.lastPocketReward={id:reward.id,kind:reward.kind,label:reward.label};saveState(true);
  }

  function registerDepositBreak(rock){
    if(!rock.depositId)return;
    const depositRocks=mineRocks.filter(item=>item.depositId===rock.depositId),broken=depositRocks.filter(item=>item.broken).length,total=depositRocks.length,progress=total?broken/total:0;
    miningFeedback.lastDepositBeat={id:rock.depositId,type:rock.type,broken,total,jackpot:broken===total};
    if(broken<total){
      sound('veinStep',rock.type,progress);
      return;
    }
    sound('jackpot',rock.type);
    floaters.push({x:rock.x,y:rock.y-52,text:rock.rareFind?'RARE FIND!':'VEIN CLEARED!',color:'#fff2bd',age:0,life:1.55,size:18});
    miningKick(rock.rareFind?9:7,rock.rareFind?30:24);
  }

  function registerVeinBreak(vein,rock){
    if(vein.status==='idle'){
      vein.status='active';vein.timer=vein.timeLimit;vein.displaySecond=Math.ceil(vein.timer);vein.brokenRockIds.clear();
    }
    if(vein.status!=='active')return;
    vein.brokenRockIds.add(rock.id);
    const veinRocks=rocks.filter(item=>item.veinId===vein.id);
    if(vein.brokenRockIds.size<veinRocks.length)return;
    vein.status='completed';vein.timer=0;vein.displaySecond=-1;state.veinsCompleted[vein.id]++;
    for(const [type,amount] of Object.entries(vein.bonus)){
      state.mined[type]+=amount;
    }
    const center=veinCenter(vein);
    let rewardIndex=0;for(const [type,amount] of Object.entries(vein.bonus))spawnGroundDrop(type,amount,center.x+(rewardIndex++-.5)*22,center.y-5);
    sound('vein',vein.type);uiDirty=true;saveState();
  }

  function veinCenter(vein){
    let x=0,y=0;for(const position of vein.positions){x+=position[0];y+=position[1]}
    return{x:x/vein.positions.length,y:y/vein.positions.length};
  }

  function updateVeins(dt){
    for(const vein of veins){
      if(vein.status==='active'){
        vein.timer=Math.max(0,vein.timer-dt);
        const displaySecond=Math.ceil(vein.timer);
        if(displaySecond!==vein.displaySecond){vein.displaySecond=displaySecond;uiDirty=true}
        if(vein.timer===0){vein.status='failed';vein.displaySecond=-1;uiDirty=true}
      }else if(vein.status!=='idle'){
        const allRestored=rocks.filter(rock=>rock.veinId===vein.id).every(rock=>!rock.broken);
        if(allRestored){vein.status='idle';vein.timer=0;vein.displaySecond=-1;vein.brokenRockIds.clear();uiDirty=true}
      }
    }
  }

  function spawnImpact(x,y,precision){
    spawnTerrainResponse('mine',x,y,precision?1.08:.9);
  }

  function spawnBreak(x,y,type){
    spawnTerrainResponse('break',x,y,1.18);
  }

  function spawnDiscoveryBurst(rock,label){
    const data=ROCK_TYPES[rock.type],rare=!!rock.rareFind||!!data.rare;
    miningFeedback.lastDiscovery={type:rock.type,label,rare};
    sound('discovery',rock.type);miningKick(rare?9:7,rare?30:22);
  }

  function spawnGroundDrop(type,amount,x,y,sourceChest,scene,sourcePocket,depth){
    if(!lootData(type)||amount<=0)return;
    const currency=type==='coin',total=Math.max(1,Math.floor(amount)),count=currency?Math.min(6,Math.max(3,Math.ceil(total/100))):total;
    let remaining=total;
    for(let item=0;item<count;item++){
      if(groundDrops.length>=MAX_GROUND_DROPS){
        let oldestIndex=0;
        for(let index=1;index<groundDrops.length;index++)if(groundDrops[index].age>groundDrops[oldestIndex].age)oldestIndex=index;
        discardGroundDrop(oldestIndex);
      }
      const seed=nextDropId++,angle=(seed*2.399963)%6.283,burst=34+(seed%4)*7;
      const dropScene=scene||currentScene,world=MINE_DEFINITIONS[dropScene]||WORLD;
      const dropAmount=currency?Math.ceil(remaining/(count-item)):1;remaining-=dropAmount;
      groundDrops.push({id:seed,type,amount:dropAmount,x:clamp(x,GROUND_DROP_EDGE_X,world.width-GROUND_DROP_EDGE_X),y:clamp(y,GROUND_DROP_EDGE_TOP,world.height-GROUND_DROP_EDGE_BOTTOM),z:12,vx:Math.cos(angle)*burst,vy:Math.sin(angle)*burst*.58,vz:92+(seed%5)*9,age:0,settled:false,sourceChest:sourceChest||null,sourcePocket:sourcePocket||null,scene:dropScene,depth:dropScene==='surface'?1:depth||currentDepth});
    }
  }

  function discardPendingDrop(drop){
    if(drop.sourceChest&&state.pendingChestLoot[drop.sourceChest]){
      const pending=state.pendingChestLoot[drop.sourceChest];pending[drop.type]=Math.max(0,(pending[drop.type]||0)-drop.amount);if(!pending[drop.type])delete pending[drop.type];if(!Object.keys(pending).length)delete state.pendingChestLoot[drop.sourceChest];
    }
    if(drop.sourcePocket&&state.pendingPocketLoot[drop.sourcePocket]){
      const pending=state.pendingPocketLoot[drop.sourcePocket];pending[drop.type]=Math.max(0,(pending[drop.type]||0)-drop.amount);if(!pending[drop.type])delete pending[drop.type];if(!Object.keys(pending).length)delete state.pendingPocketLoot[drop.sourcePocket];
    }
  }

  function discardGroundDrop(index){const drop=groundDrops[index];if(!drop)return;discardPendingDrop(drop);groundDrops.splice(index,1)}

  function lootSweepRemaining(){return Math.max(0,(state.nextLootSweepAt-Date.now())/1000)}

  function performGlobalLootSweep(announce=true){
    const cleared=groundDrops.length;groundDrops.length=0;state.pendingChestLoot={};state.pendingPocketLoot={};state.nextLootSweepAt=Date.now()+GROUND_DROP_LIFETIME*1000;
    pickupBatch.items=Object.create(null);pickupBatch.count=0;pickupBatch.quiet=0;pickupBatch.bestType=null;
    lootSweepCheck=Date.now()+250;lootSweepWarned30=false;lootSweepWarned10=false;uiDirty=true;
    if(announce)showToast(cleared?'Global cleanup cleared '+cleared+' loose items.':'Global cleanup complete.');
    saveState(true);return cleared;
  }

  function updateLootSweep(){
    const now=Date.now();if(now<lootSweepCheck)return;lootSweepCheck=now+250;
    const remaining=lootSweepRemaining();
    if(remaining<=0){performGlobalLootSweep(true);return}
    if(remaining<=10&&!lootSweepWarned10){lootSweepWarned10=true;showToast('All loose items clear in 10 seconds.');return}
    if(remaining<=LOOT_SWEEP_WARNING_SECONDS&&!lootSweepWarned30){lootSweepWarned30=true;showToast('Global loot cleanup in 30 seconds.')}
  }

  function collectGroundDrop(drop){
    if(drop.type==='coin'){
      const from=displayedGold;state.gold+=drop.amount;state.totalGold+=drop.amount;startGoldCount(from,state.gold);
    }else state.cargo[drop.type]+=drop.amount;
    if(drop.sourceChest&&state.pendingChestLoot[drop.sourceChest]){
      const pending=state.pendingChestLoot[drop.sourceChest];pending[drop.type]=Math.max(0,(pending[drop.type]||0)-drop.amount);
      if(!pending[drop.type])delete pending[drop.type];
      if(!Object.keys(pending).length)delete state.pendingChestLoot[drop.sourceChest];
    }
    if(drop.sourcePocket&&state.pendingPocketLoot[drop.sourcePocket]){
      const pending=state.pendingPocketLoot[drop.sourcePocket];pending[drop.type]=Math.max(0,(pending[drop.type]||0)-drop.amount);
      if(!pending[drop.type])delete pending[drop.type];if(!Object.keys(pending).length)delete state.pendingPocketLoot[drop.sourcePocket];
    }
    pickupBatch.items[drop.type]=(pickupBatch.items[drop.type]||0)+drop.amount;pickupBatch.count+=drop.amount;pickupBatch.quiet=0;
    pickupBatch.x=drop.x;pickupBatch.y=drop.y;
    if(!pickupBatch.bestType||lootData(drop.type).value>lootData(pickupBatch.bestType).value)pickupBatch.bestType=drop.type;
    uiDirty=true;
  }

  function flushPickupBatch(){
    if(!pickupBatch.count)return;
    const entries=Object.keys(pickupBatch.items),best=pickupBatch.bestType||entries[0];
    sound(best==='coin'?'coin':'pickup',best);
    pickupBatch.items=Object.create(null);pickupBatch.count=0;pickupBatch.quiet=0;pickupBatch.bestType=null;
  }

  function updateGroundDrops(dt){
    let collected=false;
    for(let index=groundDrops.length-1;index>=0;index--){
      const drop=groundDrops[index];drop.age+=dt;
      if(drop.scene!==currentScene||drop.depth!==currentDepth)continue;
      if(!drop.settled){
        drop.x+=drop.vx*dt;drop.y+=drop.vy*dt;drop.z+=drop.vz*dt;drop.vz-=330*dt;drop.vx*=Math.pow(.11,dt);drop.vy*=Math.pow(.11,dt);
        if(drop.z<=0){drop.z=0;if(Math.abs(drop.vz)>28){drop.vz=-drop.vz*.27;drop.vx*=.62;drop.vy*=.62}else{drop.vz=0;drop.vx=0;drop.vy=0;drop.settled=true}}
      }
      const world=currentWorld(),safeX=clamp(drop.x,GROUND_DROP_EDGE_X,world.width-GROUND_DROP_EDGE_X),safeY=clamp(drop.y,GROUND_DROP_EDGE_TOP,world.height-GROUND_DROP_EDGE_BOTTOM);
      if(safeX!==drop.x){drop.x=safeX;drop.vx=0}if(safeY!==drop.y){drop.y=safeY;drop.vy=0}
      if(distance(player.x,player.y,drop.x,drop.y)<=GROUND_DROP_PICKUP_RADIUS){collectGroundDrop(drop);groundDrops.splice(index,1);collected=true}
    }
    if(collected)flushPickupBatch();
    else if(pickupBatch.count){pickupBatch.quiet+=dt;if(pickupBatch.quiet>=.075)flushPickupBatch()}
    if(collected)saveState();
  }

  function transitionScene(scene){
    releaseTouchControls();player.swing=null;player.swingCooldown=0;resetPlayerWalk(player.direction);miningFocus.streak=0;miningFocus.timer=0;
    floaters.length=0;saleMotes.length=0;terrainResponses.length=0;lastTerrainImpactAt=-Infinity;activeContext=null;
    if(MINE_SCENES.includes(scene)){
      const mine=MINE_DEFINITIONS[scene];if(!mine.unlock(state))return;
      state.location.surfaceX=player.x;state.location.surfaceY=player.y;currentScene=scene;currentDepth=1;
      player.x=mine.entrance.x+85;player.y=mine.entrance.y;state.discoveredMines[scene]=true;state.mineDiscovered=state.discoveredMines.mossMine;
      showAreaBanner(mine.name);showToast(scene==='starMine'?'The stars vanish above you.':'The mountain closes behind you.');
    }else{
      const previousMine=currentMine();
      currentScene='surface';currentDepth=1;player.x=state.location.surfaceX;player.y=state.location.surfaceY;
      showAreaBanner(previousMine?previousMine.surfaceName:currentBiome().name);showToast('Back beneath the open sky.');
    }
    lastRegion=-1;updateCamera(true);uiDirty=true;sound('unlock');saveState(true);
  }

  function transitionHub(enter=true){
    if(enter){
      if(!state.hub.unlocked||currentScene!=='surface')return false;
      releaseTouchControls();state.hub.surfaceX=player.x;state.hub.surfaceY=player.y;state.location.surfaceX=player.x;state.location.surfaceY=player.y;currentScene='hub';currentDepth=1;player.x=HUB_STATIONS.surfaceLift.x+92;player.y=HUB_STATIONS.surfaceLift.y;state.hub.visited=true;
      showAreaBanner('UNDERGROUND HUB');showToast('A permanent safe room. Nothing here resets your expedition.');
    }else{
      if(!inHub())return false;setHubBuildMode(false);releaseTouchControls();currentScene='surface';currentDepth=1;player.x=clamp(state.hub.surfaceX,52,WORLD.width-52);player.y=clamp(state.hub.surfaceY,70,WORLD.height-58);showAreaBanner('STARFALL DEPTHS');showToast('Back on the Starfall road.');
    }
    player.swing=null;player.swingCooldown=0;resetPlayerWalk(player.direction);floaters.length=0;saleMotes.length=0;terrainResponses.length=0;lastTerrainImpactAt=-Infinity;activeContext=null;lastRegion=-1;updateCamera(true);uiDirty=true;sound('unlock');saveState(true);return true;
  }

  function transitionMineDepth(depth){
    if(!currentMine()||depth!==1&&depth!==2)return false;
    const entrance=depthEntrances[currentScene];
    if(depth===2&&!state.discoveredDepthEntrances[currentScene])return false;
    if(depth===2&&currentScene==='starMine'&&state.drillLevel<DRILLS.length-1){showToast('Master the Deepcore Drill before entering Voidstar Depths.');sound('empty');uiDirty=true;return false}
    releaseTouchControls();player.swing=null;player.swingCooldown=0;resetPlayerWalk(player.direction);floaters.length=0;terrainResponses.length=0;lastTerrainImpactAt=-Infinity;activeContext=null;
    currentDepth=depth;player.x=clamp(entrance.x+92,52,currentMine().width-52);player.y=depth===2?clamp(entrance.y+108,70,currentMine().height-58):entrance.y;
    if(depth===2){
      state.visitedDepths[currentScene]=true;
      if(!state.drillGoalScene)state.drillGoalScene=currentScene;
      showAreaBanner(MINE_DEPTH_PROFILES[currentScene].name);showToast('New materials and the Drill Forge await below.');
    }
    else{showAreaBanner(currentMine().name);showToast('Back in Depth 1.');}
    lastRegion=-1;updateCamera(true);uiDirty=true;sound('unlock');saveState(true);return true;
  }

  function contextAtPlayer(){
    const baseModule=nearestBaseModule();if(baseModule)return'base:'+baseModule.id;
    if(inHub()){
      if(distance(player.x,player.y,HUB_STATIONS.surfaceLift.x,HUB_STATIONS.surfaceLift.y)<=HUB_STATIONS.surfaceLift.radius)return'hubExit';
      if(distance(player.x,player.y,HUB_STATIONS.deepElevator.x,HUB_STATIONS.deepElevator.y)<=HUB_STATIONS.deepElevator.radius)return'deepElevator';
      return null;
    }
    const mine=currentMine();
    if(mine){
      const depthEntrance=depthEntrances[currentScene];
      if(currentDepth===2&&distance(player.x,player.y,depthEntrance.x,depthEntrance.y)<=118)return'depthExit';
      if(currentDepth===2){
        const stations=depthStations();
        if(distance(player.x,player.y,stations.sell.x,stations.sell.y)<=stations.sell.radius)return'depthSell';
        if(distance(player.x,player.y,stations.forge.x,stations.forge.y)<=stations.forge.radius)return'drillForge';
      }
      if(currentDepth===1&&state.discoveredDepthEntrances[currentScene]&&distance(player.x,player.y,depthEntrance.x,depthEntrance.y)<=118)return'depthEntrance';
      if(currentDepth===1&&distance(player.x,player.y,mine.entrance.x,mine.entrance.y)<=118)return'mineExit';
      return null;
    }
    const chest=nearbyChest();if(chest)return'chest:'+chest.id;
    for(const scene of MINE_SCENES){
      const candidate=MINE_DEFINITIONS[scene],entrance=candidate.surfaceEntrance;
      if(candidate.unlock(state)&&distance(player.x,player.y,entrance.x,entrance.y)<=entrance.radius)return'mineEntrance:'+scene;
    }
    if(state.hub.unlocked&&distance(player.x,player.y,HUB_STATIONS.surfaceEntrance.x,HUB_STATIONS.surfaceEntrance.y)<=HUB_STATIONS.surfaceEntrance.radius)return'hubEntrance';
    if(distance(player.x,player.y,STATIONS.speedShop.x,STATIONS.speedShop.y)<=STATIONS.speedShop.radius)return'speedShop';
    if(!state.areaUnlocked&&distance(player.x,player.y,STATIONS.gate.x,STATIONS.gate.y)<=STATIONS.gate.radius)return'gate';
    if(state.areaUnlocked&&!state.emberdeepUnlocked&&distance(player.x,player.y,STATIONS.emberGate.x,STATIONS.emberGate.y)<=STATIONS.emberGate.radius)return'emberGate';
    if(state.emberdeepUnlocked&&!state.fourthUnlocked&&distance(player.x,player.y,STATIONS.starfallGate.x,STATIONS.starfallGate.y)<=STATIONS.starfallGate.radius)return'starfallGate';
    if(state.fourthUnlocked&&distance(player.x,player.y,STATIONS.starforge.x,STATIONS.starforge.y)<=STATIONS.starforge.radius)return'starforge';
    return null;
  }

  function performContext(){
    unlockAudio();
    if(activeContext&&activeContext.startsWith('mineEntrance:'))transitionScene(activeContext.slice(13));
    else if(activeContext==='mineExit')transitionScene('surface');
    else if(activeContext==='depthEntrance')transitionMineDepth(2);
    else if(activeContext==='depthExit')transitionMineDepth(1);
    else if(activeContext==='depthSell')sellCargo(depthStations().sell);
    else if(activeContext==='drillForge')upgradeDrill();
    else if(activeContext&&activeContext.startsWith('base:')){
      const module=baseModuleById(activeContext.slice(5));
      if(module&&module.kind==='forge')upgradePickaxe();else if(module&&module.kind==='sell')sellCargo(module);else if(module&&module.kind==='storage')openInventory();
    }
    else if(activeContext&&activeContext.startsWith('chest:'))openChest(chestById(activeContext.slice(6)));
    else if(activeContext==='speedShop')buyMovementSpeed();
    else if(activeContext==='gate')unlockArea();
    else if(activeContext==='emberGate')unlockEmberdeep();
    else if(activeContext==='starfallGate')unlockStarfall();
    else if(activeContext==='hubEntrance')transitionHub(true);
    else if(activeContext==='hubExit')transitionHub(false);
  }

  function performSecondaryContext(){if(activeContext&&activeContext.startsWith('base:'))packBaseModule(activeContext.slice(5))}

  function openChest(chest){
    if(!chest||state.openedChests[chest.id])return;
    if(!chestRequirementMet(chest)){showToast('Requires '+chest.requires.label+'.');sound('empty');return}
    state.openedChests[chest.id]=true;state.pendingChestLoot[chest.id]={...chest.rewards};
    let rewardIndex=0;
    for(const [type,amount] of Object.entries(chest.rewards))spawnGroundDrop(type,amount,chest.x+(rewardIndex++-1)*18,chest.y+8,chest.id);
    sound('chest');
    floaters.push({x:chest.x,y:chest.y-48,text:'CHEST OPENED',color:'#ffe8a0',age:0,life:1.35,size:18});
    showToast(chestRewardLabel(chest));activeContext=null;uiDirty=true;saveState(true);
  }

  function canForgeStarVariant(id){const variant=STARFORGE_VARIANTS[id];return !!variant&&Object.entries(variant.cost).every(([type,amount])=>state.cargo[type]>=amount)}

  function forgeStarVariant(id){
    const variant=STARFORGE_VARIANTS[id];if(!variant)return;
    if(state.drillLevel){showToast('Your drill has replaced the Starforge pickaxe.');sound('empty');return}
    if(state.starforgeUnlocked[id]){
      state.starforgeVariant=id;showToast(variant.name+' equipped.');sound('upgrade');uiDirty=true;saveState();return;
    }
    if(!canForgeStarVariant(id)){showToast('Need '+Object.entries(variant.cost).map(([type,amount])=>amount+' '+ROCK_TYPES[type].label).join(' + ')+'.');sound('empty');return}
    for(const [type,amount] of Object.entries(variant.cost))state.cargo[type]-=amount;
    const masteredBefore=starforgeMastered();state.starforgeUnlocked[id]=true;state.starforgeVariant=id;
    sound('upgrade');
    for(let i=floaters.length-1;i>=0;i--)if(floaters[i].source==='starforge')floaters.splice(i,1);
    if(!masteredBefore&&starforgeMastered()){
      floaters.push({x:player.x,y:player.y+65,text:'DEPTH MASTERED',color:'#fff2b5',age:0,life:2.1,size:21,source:'starforge'});
      showToast('All three Starforge forms mastered.');
    }else{
      floaters.push({x:player.x,y:player.y+65,text:variant.name.toUpperCase(),color:variant.color,age:0,life:1.6,size:18,source:'starforge'});
      showToast(variant.name+' forged. Return here to swap styles.');
    }
    uiDirty=true;saveState();
  }

  function upgradeDrill(){
    const drill=nextDrill(),cost=drillCost();if(!drill){showToast('Deepcore Drill is fully upgraded.');sound('empty');return}
    if(!state.drillLevel&&!state.starforgeVariant){showToast('A forged Starforge pickaxe is required.');sound('empty');return}
    const missing=nextMissingDrillRequirement(cost);
    if(missing){
      showToast('Mine '+ROCK_TYPES[missing.type].label+' in '+DEPTH_ROUTE_LABELS[missing.scene]+'.');sound('empty');return;
    }
    if(state.gold<cost.gold){showToast('Need '+(cost.gold-state.gold)+' more gold.');sound('empty');return}
    state.gold-=cost.gold;for(const requirement of cost.requirements)state.cargo[requirement.type]-=requirement.amount;state.drillLevel++;settleGoldDisplay();
    sound('upgrade');
    floaters.push({x:player.x,y:player.y-54,text:drill.name.toUpperCase(),color:drill.color,age:0,life:1.7,size:18});
    showToast(drill.name+' forged - new drill-locked materials can now be mined.');uiDirty=true;saveState(true);
  }

  function buyMovementSpeed(){
    const cost=movementSpeedCost();if(state.gold<cost){showToast('Need '+(cost-state.gold)+' more gold.');sound('empty');return false}
    const goldBefore=state.gold;state.gold-=cost;state.movementSpeedLevel++;startGoldCount(goldBefore,state.gold);
    sound('upgrade');
    floaters.push({x:player.x,y:player.y-48,text:'MOVE SPEED '+movementSpeedMultiplier().toFixed(2)+'x',color:'#bff5c7',age:0,life:1.35,size:16});
    showToast('Permanent movement speed increased. No level cap.');uiDirty=true;saveState(true);return true;
  }

  function sellCargo(station=state.base.sell){
    const soldCargo=sellableCargo(),value=cargoValueTotal(soldCargo),protectedCargo=protectedProgressCargo();
    if(value<=0){
      const protectedCount=Object.values(protectedCargo).reduce((total,amount)=>total+amount,0);
      showToast(protectedCount?'Upgrade materials are protected in your backpack.':'Your inventory is empty.');sound('empty');return;
    }
    const goldBefore=state.gold;
    state.gold+=value;state.totalGold+=value;
    startGoldCount(goldBefore,state.gold);spawnSaleMotes(soldCargo,station);
    for(const type of Object.keys(state.cargo))state.cargo[type]-=soldCargo[type]||0;
    sound('coin');floaters.push({x:station.x,y:station.y-45,text:'+'+value+' GOLD',color:'#ffd66e',age:0,life:1.35,size:18});
    const kept=Object.values(protectedCargo).reduce((total,amount)=>total+amount,0);
    showToast('Sold for '+value+' gold.'+(kept?' Upgrade materials kept safe.':''));uiDirty=true;saveState();
  }

  function upgradePickaxe(){
    if(state.pickaxeLevel>=PICKAXES.length-1){reforgeEmberPickaxe();return}
    const next=PICKAXES[state.pickaxeLevel+1];
    if(state.pickaxeLevel===4&&!state.emberdeepUnlocked){showToast('Open Emberdeep Foundry first.');sound('empty');return}
    if(state.pickaxeLevel===4&&state.cargo.emberstone<EMBER_PICKAXE_ORE_REQUIRED){showToast('Collect '+(EMBER_PICKAXE_ORE_REQUIRED-state.cargo.emberstone)+' more Emberstone.');sound('empty');return}
    if(state.gold<next.cost){showToast('Need '+(next.cost-state.gold)+' more gold.');sound('empty');return}
    const referenceType=localReferenceRock(),oldHits=hitsRequired(referenceType,currentPickaxe().power),newHits=hitsRequired(referenceType,next.power);
    state.gold-=next.cost;if(state.pickaxeLevel===4)state.cargo.emberstone-=EMBER_PICKAXE_ORE_REQUIRED;state.pickaxeLevel++;settleGoldDisplay();
    sound('upgrade');
    floaters.push({x:player.x,y:player.y-50,text:PICKAXES[state.pickaxeLevel].name.toUpperCase(),color:'#ffe39a',age:0,life:1.6,size:17});
    showToast(ROCK_TYPES[referenceType].label+': '+oldHits+' hits -> '+newHits+' hits');uiDirty=true;saveState();
  }

  function reforgeEmberPickaxe(){
    const next=nextMastery();
    if(!next){showToast('Ember Mastery is complete.');sound('empty');return}
    if(state.cargo.sunslag<next.sunslag){showToast('Collect '+(next.sunslag-state.cargo.sunslag)+' more Sunslag.');sound('empty');return}
    if(state.gold<next.gold){showToast('Need '+(next.gold-state.gold)+' more gold.');sound('empty');return}
    const oldPower=currentPower(),oldShellPower=currentShellPower();
    state.gold-=next.gold;state.cargo.sunslag-=next.sunslag;state.emberMastery=next.rank;settleGoldDisplay();
    sound('upgrade');
    floaters.push({x:player.x,y:player.y-53,text:'EMBER MASTERY '+next.rank,color:'#ffd38c',age:0,life:1.65,size:18});
    showToast(next.label+' - Power '+oldPower+' -> '+currentPower()+' - Shell '+Math.round(oldShellPower*100)+'% -> '+Math.round(currentShellPower()*100)+'%');uiDirty=true;saveState();
    if(next.rank===5)showHeatTutorial();
  }

  function unlockArea(){
    if(state.pickaxeLevel<3){showToast('A Runed Pickaxe is required.');sound('empty');return}
    if(state.gold<GATE_COST){showToast('Need '+(GATE_COST-state.gold)+' more gold.');sound('empty');return}
    state.gold-=GATE_COST;state.areaUnlocked=true;moonglassGateTransition={elapsed:0,duration:MOONGLASS_GATE_TRANSITION_DURATION};settleGoldDisplay();
    sound('unlock');
    showToast('The Moonglass gate returns to the earth.');uiDirty=true;saveState();
  }

  function unlockEmberdeep(){
    if(state.pickaxeLevel<4){showToast('A Moonglass Pickaxe is required.');sound('empty');return}
    if(state.gold<EMBER_GATE_COST){showToast('Need '+(EMBER_GATE_COST-state.gold)+' more gold.');sound('empty');return}
    state.gold-=EMBER_GATE_COST;state.emberdeepUnlocked=true;emberdeepGateTransition={elapsed:0,duration:EMBERDEEP_GATE_TRANSITION_DURATION};settleGoldDisplay();
    sound('unlock');
    showToast('The Emberdeep seal returns to the forge below.');uiDirty=true;saveState();
  }

  function unlockStarfall(){
    if(state.emberMastery<5){showToast('Depth Mastery 5 is required.');sound('empty');return}
    state.fourthUnlocked=true;starfallGateTransition={elapsed:0,duration:STARFALL_GATE_TRANSITION_DURATION};
    sound('unlock');
    showToast('The Starfall seal returns beneath the road.');uiDirty=true;saveState();
  }

  function updateInputVector(){
    if(hubBuild.active)return{x:0,y:0};
    let x=input.moveX,y=input.moveY;
    if(input.keys.has('ArrowLeft')||input.keys.has('KeyA'))x-=1;
    if(input.keys.has('ArrowRight')||input.keys.has('KeyD'))x+=1;
    if(input.keys.has('ArrowUp')||input.keys.has('KeyW'))y-=1;
    if(input.keys.has('ArrowDown')||input.keys.has('KeyS'))y+=1;
    const length=Math.hypot(x,y);return length>1?{x:x/length,y:y/length}:{x,y};
  }

  function movePlayerBy(dx,dy){
    const startX=player.x,startY=player.y,steps=Math.max(1,Math.ceil(Math.max(Math.abs(dx),Math.abs(dy))/PLAYER_MOVE_STEP)),stepX=dx/steps,stepY=dy/steps,world=currentWorld();
    for(let step=0;step<steps;step++){
      let nx=clamp(player.x+stepX,52,world.width-52),ny=clamp(player.y+stepY,70,world.height-58);
      if(currentScene==='surface'){
        for(const boundary of SURFACE_BOUNDARIES){
          if(state[boundary.unlockKey]&&!activeSurfaceGateTransition(boundary.unlockKey))continue;
          if(player.x<boundary.x&&nx>boundary.x-boundary.lockedGateHalfWidth)nx=boundary.x-boundary.lockedGateHalfWidth;
          if(player.x>boundary.x&&nx<boundary.x+boundary.lockedGateHalfWidth)nx=boundary.x+boundary.lockedGateHalfWidth;
        }
      }
      if(!collidesWithMine(nx,player.y)&&!surfaceBoundaryCollides(nx,player.y)&&!hubWallCollision(nx,player.y))player.x=nx;
      if(!collidesWithMine(player.x,ny)&&!surfaceBoundaryCollides(player.x,ny)&&!hubWallCollision(player.x,ny))player.y=ny;
    }
    const actualX=player.x-startX,actualY=player.y-startY;return{x:actualX,y:actualY,distance:Math.hypot(actualX,actualY)};
  }

  function updatePlayerWalkDirection(dx,dy){
    const ax=Math.abs(dx),ay=Math.abs(dy);if(ax+ay<.001)return;
    const horizontal=player.direction==='left'||player.direction==='right',threshold=PLAYER_RENDER_CONTRACT.walkDirectionHysteresis;
    let useHorizontal;
    if(ax<.001)useHorizontal=false;else if(ay<.001)useHorizontal=true;else useHorizontal=horizontal?ay<=ax*threshold:ax>ay*threshold;
    player.direction=useHorizontal?(dx<0?'left':'right'):(dy<0?'up':'down');
    if(useHorizontal)player.facing=dx<0?-1:1;
  }

  function spawnWalkFootstep(){
    if(inHub())return;
    spawnTerrainResponse('footstep',player.x-player.aimX*5,player.y+25-player.aimY*3,.72);
  }

  function advancePlayerWalk(actualDistance,dt){
    const previousStep=Math.floor(player.walkPhase/3),advance=Math.min(actualDistance/PLAYER_RENDER_CONTRACT.walkFrameDistance,dt*PLAYER_RENDER_CONTRACT.walkMaxFramesPerSecond);
    player.walkDistance+=actualDistance;player.walkPhase+=advance;player.walkFrame=reducedMotion?0:Math.floor(player.walkPhase)%PLAYER_RENDER_CONTRACT.walkColumns;
    player.walk=(player.walkPhase%PLAYER_RENDER_CONTRACT.walkColumns)/PLAYER_RENDER_CONTRACT.walkColumns*Math.PI*2;
    if(Math.floor(player.walkPhase/3)>previousStep)spawnWalkFootstep();
  }

  function settlePlayerWalk(){
    const columns=PLAYER_RENDER_CONTRACT.walkColumns,cycle=Math.floor(player.walkPhase/columns)*columns,phase=player.walkPhase%columns;
    const contact=phase<1.5?cycle:phase<4.5?cycle+PLAYER_RENDER_CONTRACT.walkContactFrames[1]:cycle+columns;
    player.walkPhase=contact;player.walkFrame=reducedMotion?0:contact%columns;player.walk=(contact%columns)/columns*Math.PI*2;
  }

  function collidesWithMine(x,y){
    if(!currentMine())return false;
    if(terrainCollidesCircle(x,y))return true;
    for(const solid of activeMineSolids()){
      const nearestX=clamp(x,solid.x,solid.x+solid.w),nearestY=clamp(y,solid.y,solid.y+solid.h);
      if(distance(x,y,nearestX,nearestY)<player.radius)return true;
    }
    return false;
  }

  function surfaceBoundaryCollides(x,y){
    if(currentScene!=='surface')return false;
    for(const boundary of SURFACE_BOUNDARIES){
      if(x<=boundary.x-boundary.collisionLeft-player.radius||x>=boundary.x+boundary.collisionRight+player.radius)continue;
      if(Math.abs(y-boundary.y)>boundary.gap-player.radius)return true;
    }
    return false;
  }

  function activeSurfaceGateTransition(unlockKey){
    return unlockKey==='areaUnlocked'?moonglassGateTransition:unlockKey==='emberdeepUnlocked'?emberdeepGateTransition:unlockKey==='fourthUnlocked'?starfallGateTransition:null;
  }

  function update(dt){
    updateLootSweep(dt);achievementCheckTimer=Math.max(0,achievementCheckTimer-dt);if(achievementCheckTimer===0){evaluateAchievements();achievementCheckTimer=.12}if(!menuShade.hidden||!inventoryShade.hidden||!heatTutorialShade.hidden||!hubTutorialShade.hidden)return;
    time+=dt;
    updateHeatStreak(dt);
    const ambientMining=!!player.swing||input.mineHeld;
    if(ambientMining){
      if(!ambientDisturbance.active||ambientDisturbance.scene!==currentScene||ambientDisturbance.depth!==currentDepth){ambientDisturbance.scene=currentScene;ambientDisturbance.depth=currentDepth;ambientDisturbance.startX=player.x;ambientDisturbance.startY=player.y;ambientDisturbance.startedAt=time;ambientDisturbance.activeDuration=0}
      ambientDisturbance.active=true;ambientDisturbance.x=player.x;ambientDisturbance.y=player.y;ambientDisturbance.activeDuration=Math.max(0,time-ambientDisturbance.startedAt);ambientDisturbance.remaining=AMBIENT_RECOVERY_DURATION;
    }else if(ambientDisturbance.active){ambientDisturbance.active=false;ambientDisturbance.releasedAt=time;ambientDisturbance.activeDuration=Math.max(0,time-ambientDisturbance.startedAt);ambientDisturbance.remaining=AMBIENT_RECOVERY_DURATION}
    else ambientDisturbance.remaining=Math.max(0,ambientDisturbance.remaining-dt);
    if(moonglassGateTransition){
      moonglassGateTransition.elapsed=Math.min(moonglassGateTransition.duration,moonglassGateTransition.elapsed+dt);
      if(moonglassGateTransition.elapsed>=moonglassGateTransition.duration)moonglassGateTransition=null;
    }
    if(emberdeepGateTransition){
      emberdeepGateTransition.elapsed=Math.min(emberdeepGateTransition.duration,emberdeepGateTransition.elapsed+dt);
      if(emberdeepGateTransition.elapsed>=emberdeepGateTransition.duration)emberdeepGateTransition=null;
    }
    if(starfallGateTransition){
      starfallGateTransition.elapsed=Math.min(starfallGateTransition.duration,starfallGateTransition.elapsed+dt);
      if(starfallGateTransition.elapsed>=starfallGateTransition.duration)starfallGateTransition=null;
    }
    const move=updateInputVector();
    if(Math.abs(move.x)+Math.abs(move.y)>.02){
      const aimLength=Math.hypot(move.x,move.y);if(aimLength>.05){player.aimX=move.x/aimLength;player.aimY=move.y/aimLength}
      const movement=movePlayerBy(move.x*PLAYER_SPEED*movementSpeedMultiplier()*dt,move.y*PLAYER_SPEED*movementSpeedMultiplier()*dt);
      player.moving=movement.distance>.025;
      if(player.moving){updatePlayerWalkDirection(movement.x,movement.y);advancePlayerWalk(movement.distance,dt)}
    }else player.moving=false;
    if(!player.moving)settlePlayerWalk();
    player.swingCooldown=Math.max(0,player.swingCooldown-dt);
    if(miningFocus.timer>0){
      miningFocus.timer=Math.max(0,miningFocus.timer-dt);
      if(miningFocus.timer===0&&miningFocus.streak){miningFocus.streak=0;uiDirty=true}
    }
    if(miningRush.timer>0){
      miningRush.timer=Math.max(0,miningRush.timer-dt);const second=Math.ceil(miningRush.timer);
      if(second!==miningRush.lastSecond){miningRush.lastSecond=second;uiDirty=true}
      if(miningRush.timer===0){showToast('Mining Rush ended.');uiDirty=true}
    }
    if(player.swing){
      player.swing.elapsed+=dt;
      const hitAt=player.swing.duration*.36;
      if(!player.swing.hit&&player.swing.elapsed>=hitAt){
        player.swing.hit=true;
        if(player.swing.target==='terrain')hitTerrain(player.hitTerrainIndex);
        else hitRock(rocks.find(rock=>rock.id===player.hitRockId),player.swing.precision);
      }
      if(player.swing.elapsed>=player.swing.duration){player.swing=null;player.swingCooldown=.02}
    }
    if(input.mineHeld&&!player.swing&&player.swingCooldown<=0)startSwing(false);
    const miningTarget=nearestRock(MINING_RANGE);
    for(const rock of currentRocks()){
      rock.hit=Math.max(0,rock.hit-dt);
      if(rock.broken){
        if(rock.barrierId)continue;
        rock.respawn-=dt;
        if(rock.respawn<=0){rock.broken=false;rock.hp=rock.maxHp;rock.shell=rock.maxShell;rock.respawn=0;rock.glintActive=0;rock.glintTimer=1.6+(rock.id%5)*.52;rock.bonusYield=0}
        continue;
      }
      if(rock.glintActive>0)rock.glintActive=Math.max(0,rock.glintActive-dt);
      else if(miningTarget&&miningTarget.id===rock.id){
        rock.glintTimer-=dt;
        if(rock.glintTimer<=0){rock.glintActive=.72;rock.glintTimer=(2.4+(rock.id%4)*.38)*currentPrecisionDelay()}
      }
    }
    if(currentScene==='surface')updateVeins(dt);else if(currentMine())updatePocketRewards();updateGroundDrops(dt);
    if(terrainSaveDelay>0){terrainSaveDelay=Math.max(0,terrainSaveDelay-dt);if(terrainSaveDelay===0)saveState()}
    updateEffects(dt);updateGoldCount(dt);updateCamera(false);updateObjectiveOcclusion();
    const region=currentScene==='surface'?regionIndexAt(player.x):-1;
    if(region!==lastRegion){lastRegion=region;game.dataset.biome=currentBiome().id;uiDirty=true}
    const nextContext=hubBuild.active?null:contextAtPlayer();
    if(nextContext!==activeContext){activeContext=nextContext;uiDirty=true}
    if(currentScene==='surface'){
      if(!state.discoveredSecond&&player.x>WORLD.gateX+100){state.discoveredSecond=true;showAreaBanner('MOONGLASS CAVERN');sound('unlock');uiDirty=true;saveState()}
      if(!state.discoveredThird&&player.x>WORLD.emberGateX+100){state.discoveredThird=true;showAreaBanner('EMBERDEEP FOUNDRY');sound('unlock');uiDirty=true;saveState()}
      if(!state.discoveredFourth&&player.x>WORLD.starfallGateX+100){state.discoveredFourth=true;showAreaBanner('STARFALL DEPTHS');sound('unlock');uiDirty=true;saveState()}
    }
    positionAchievementPopup();
    if(uiDirty)updateUI();
  }

  function updateEffects(dt){
    for(const floater of floaters){floater.age+=dt;floater.y-=35*dt}
    for(const mote of saleMotes)mote.age+=dt;
    for(const response of terrainResponses)response.age+=dt;
    if(miningFeedback.shakeTime>0){miningFeedback.shakeTime=Math.max(0,miningFeedback.shakeTime-dt);miningFeedback.shake*=Math.pow(.002,dt)}else miningFeedback.shake=0;
    miningFeedback.flash=Math.max(0,miningFeedback.flash-dt*1.9);
    miningFeedback.terrainHitTime=Math.max(0,miningFeedback.terrainHitTime-dt);
    if(miningFeedback.terrainHitTime===0)miningFeedback.terrainHitIndex=-1;
    floaters=floaters.filter(item=>item.age<item.life);saleMotes=saleMotes.filter(item=>item.age<item.life);terrainResponses=terrainResponses.filter(item=>item.age<item.life);
  }

  function startGoldCount(from,to){displayedGold=from;goldTween={from,to,elapsed:0,duration:.72}}
  function settleGoldDisplay(){goldTween=null;displayedGold=state.gold;goldValue.textContent=String(Math.floor(displayedGold))}
  function updateGoldCount(dt){
    if(!goldTween)return;
    goldTween.elapsed+=dt;const progress=easeOut(goldTween.elapsed/goldTween.duration);
    displayedGold=goldTween.from+(goldTween.to-goldTween.from)*progress;goldValue.textContent=String(Math.floor(displayedGold));
    if(goldTween.elapsed>=goldTween.duration)settleGoldDisplay();
  }

  function spawnSaleMotes(soldCargo,station=state.base.sell){
    let moteIndex=0;
    for(const type of Object.keys(soldCargo)){
      const amount=soldCargo[type];if(!amount)continue;
      const count=Math.min(4,Math.max(1,Math.ceil(amount/3)));
      for(let index=0;index<count;index++)saleMotes.push({type,sx:player.x+(index-count/2)*8,sy:player.y-22-index*3,tx:station.x,ty:station.y-20,age:-moteIndex*.045,life:.56,size:ROCK_TYPES[type].rare?27:23});
      moteIndex+=count;
    }
  }

  function trackedRequirements(requirements=[]){
    return requirements.map(requirement=>({type:requirement.type,amount:requirement.amount,current:Math.min(requirement.amount,state.cargo[requirement.type]||0)}));
  }

  function renderObjectiveRequirements(requirements=[]){
    objectiveRequirements.hidden=!requirements.length;
    objectiveRequirements.innerHTML=requirements.map(requirement=>{
      const data=ROCK_TYPES[requirement.type],current=Math.min(requirement.amount,state.cargo[requirement.type]||0);
      return'<div class="objective-requirement" title="'+data.label+'" aria-label="'+data.label+' '+current+' of '+requirement.amount+'">'+resourceIconMarkup(requirement.type,'objective-resource',data.label)+'<b>'+current+'/'+requirement.amount+'</b></div>';
    }).join('');
  }

  function mainGoal(){
    if(state.hub.unlocked){
      const built=state.hub.tiles.length+allBaseModules().filter(module=>moduleIsHere(module)).length;
      if(inHub()&&!built)return{title:'Tap BUILD and shape your Hub',detail:'WALLS · LIGHTS · STORAGE'};
      if(inHub())return{title:'Prepare for The Deep',detail:built+' HUB MODULE'+(built===1?'':'S')+' · ELEVATOR OFFLINE'};
      if(!state.hub.visited)return{title:'Find the Underground Hub',detail:'NEW LIFT IN STARFALL'};
      return{title:'Return to the Underground Hub',detail:'BUILD · STORE · PREPARE'};
    }
    if(state.victory)return{title:'Ever Deeper',detail:'VOIDSTAR CONQUERED'};
    if(currentScene==='starMine'&&currentDepth===2&&state.drillLevel===DRILLS.length-1)return{title:'Mine a Singularity Core',detail:'THE FINAL DISCOVERY'};
    if(currentScene==='starMine'&&currentDepth===1&&state.discoveredDepthEntrances.starMine&&state.drillLevel<DRILLS.length-1)return{title:'Master the Deepcore Drill',detail:'VOIDSTAR DEPTHS AWAITS'};
    if(currentScene==='starMine'&&currentDepth===1&&state.discoveredDepthEntrances.starMine&&state.drillLevel===DRILLS.length-1)return{title:'Enter Voidstar Depths',detail:'DEEPCORE DRILL READY'};
    if(currentScene==='starMine'&&currentDepth===1&&!state.discoveredDepthEntrances.starMine)return{title:'Find the hidden Voidstar entrance',detail:'DIG DEEPER'};
    if(state.drillLevel===DRILLS.length-1)return{title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'};
    if((state.drillGoalScene||state.drillLevel)&&(state.starforgeVariant||state.drillLevel)){
      const drill=nextDrill(),cost=drillCost();
      if(!drill||!cost)return{title:'Deepcore Drill mastered',detail:'THE DRILL AGE IS COMPLETE'};
      const missing=nextMissingDrillRequirement(cost);
      if(missing)return{title:'Mine '+ROCK_TYPES[missing.type].label+' for '+drill.name,detail:DEPTH_ROUTE_LABELS[missing.scene],requirements:trackedRequirements(cost.requirements)};
      const missingGold=Math.max(0,cost.gold-state.gold);
      if(missingGold)return{title:'Earn gold for the '+drill.name,detail:'NEED '+missingGold+' GOLD',requirements:trackedRequirements(cost.requirements)};
      return{title:'Forge the '+drill.name,detail:'READY AT ANY DEPTH 2 DRILL FORGE',requirements:trackedRequirements(cost.requirements)};
    }
    if(state.drillLevel)return{title:state.drillLevel===DRILLS.length-1?'Deepcore Drill mastered':'Find a Depth 2 Drill Forge',detail:''};
    if(starforgeMastered())return{title:'Find a hidden Depth 2 entrance',detail:'THE DRILL AGE AWAITS'};
    if(state.emberMastery===5&&!state.fourthUnlocked)return{title:'Open the Starfall Master Seal',detail:''};
    if(state.fourthUnlocked&&!state.discoveredFourth)return{title:'Enter Starfall Depths',detail:''};
    if(state.discoveredFourth&&state.mined.astralite===0)return{title:'Discover Astralite',detail:''};
    if(state.discoveredFourth&&state.veinsCompleted.starfall_lattice===0)return{title:'Clear the Starfall Lattice',detail:''};
    if(state.discoveredFourth&&state.mined.crownstone===0)return{title:'Find a Crownstone vein',detail:''};
    if(state.discoveredFourth&&!state.starforgeVariant)return{title:'Forge a Starfall Pickaxe',detail:'',requirements:trackedRequirements(currentCraftRequirements())};
    if(state.discoveredFourth&&state.starforgeVariant)return{title:'Forge all three Starforge styles',detail:'',requirements:trackedRequirements(currentCraftRequirements())};
    if(Object.values(state.mined).every(value=>value===0))return{title:'Hold MINE near a rock',detail:''};
    if(state.totalGold===0)return{title:'Sell your haul at the Sell Chest',detail:''};
    if(state.pickaxeLevel===1)return{title:'Forge an Iron Pickaxe',detail:''};
    if(state.pickaxeLevel===2)return{title:'Forge a Runed Pickaxe',detail:''};
    if(!state.areaUnlocked)return{title:'Open the Moonglass Gate',detail:''};
    if(!state.discoveredSecond)return{title:'Enter the new cavern',detail:''};
    if(state.mined.moonglass===0)return{title:'Discover Moonglass',detail:''};
    if(state.pickaxeLevel===3)return{title:'Forge a Moonglass Pickaxe',detail:''};
    if(!state.emberdeepUnlocked)return{title:'Break the Emberdeep Seal',detail:''};
    if(!state.discoveredThird)return{title:'Enter Emberdeep Foundry',detail:''};
    if(state.mined.emberstone===0)return{title:'Crack an Emberstone shell',detail:''};
    if(state.pickaxeLevel===4&&state.cargo.emberstone<EMBER_PICKAXE_ORE_REQUIRED)return{title:'Mine Emberstone',detail:'',requirements:trackedRequirements([{type:'emberstone',amount:EMBER_PICKAXE_ORE_REQUIRED}])};
    if(state.pickaxeLevel===4)return{title:'Forge the Ember Pickaxe',detail:'',requirements:trackedRequirements([{type:'emberstone',amount:EMBER_PICKAXE_ORE_REQUIRED}])};
    if(state.mined.gold+state.mined.starshard+state.mined.sunslag===0)return{title:'Hunt for a rare vein',detail:''};
    if(nextMastery()&&state.cargo.sunslag<nextMastery().sunslag)return{title:'Find Sunslag',detail:'',requirements:trackedRequirements([{type:'sunslag',amount:nextMastery().sunslag}])};
    if(nextMastery())return{title:'Reforge Ember Mastery '+nextMastery().rank,detail:'',requirements:trackedRequirements([{type:'sunslag',amount:nextMastery().sunslag}])};
    return{title:'Mine. Sell. Grow stronger.',detail:''};
  }

  function updateUI(){
    uiDirty=false;
    if(!goldTween){displayedGold=state.gold;goldValue.textContent=String(Math.floor(displayedGold))}cargoValue.textContent=String(cargoCount());
    pickaxeName.textContent=currentPickaxeName();powerValue.textContent=String(currentPower());
    const toolPath=currentToolPath()+'?v='+ASSET_VERSION;if(toolIcon.dataset.asset!==toolPath){toolIcon.dataset.asset=toolPath;toolIcon.src=toolPath;mineToolIcon.src=toolPath}
    game.dataset.pickaxeTier=String(state.pickaxeLevel);
    game.dataset.masteryRank=String(state.emberMastery);
    game.dataset.drillLevel=String(state.drillLevel);
    game.dataset.scene=currentScene;
    const drilling=state.drillLevel>0;
    toolKind.textContent=drilling?'YOUR DRILL':'YOUR PICKAXE';mineAction.textContent=inHub()?(hubBuild.active?'DONE':'BUILD'):drilling?'DRILL':'MINE';mineHint.textContent=inHub()?(hubBuild.active?'TAP':'OPEN'):miningRush.timer>0?'RUSH '+Math.ceil(miningRush.timer)+'s':'HOLD';mineButton.ariaLabel=inHub()?(hubBuild.active?'Finish building':'Open Hub build mode'):drilling?'Drill nearby rock':'Mine nearby rock';
    game.dataset.rushActive=miningRush.timer>0?'true':'false';
    speedValue.textContent=(PICKAXES[1].cooldown/currentCooldown()).toFixed(1)+'x';
    renderHeatStreak();
    const biome=currentBiome();areaName.textContent=biome.name;game.dataset.biome=biome.id;game.style['--biome-accent']=biome.accent;game.style['--biome-detail']=biome.detail;
    let progress=1,label='DEPTH MASTERED';
    if(inHub()){
      const built=state.hub.tiles.length+allBaseModules().filter(module=>moduleIsHere(module)).length;progress=Math.min(1,built/8);label='UNDERGROUND HUB · '+built+' MODULE'+(built===1?'':'S');updateHubBuildControls();
    }
    else if(state.hub.unlocked){progress=1;label='UNDERGROUND HUB UNLOCKED · STARFALL LIFT'}
    else if(currentMine()){
      const mine=currentMine(),cleared=mine.barriers.filter(barrier=>mineBarrierCleared(barrier.id)).length;
      if(currentDepth===2){
        const cost=drillCost();
        if(!hasDeepTool()){progress=0;label='DEPTH 2 - STARFORGE REQUIRED'}
        else if(!cost){progress=1;label='DRILL AGE MASTERED - DEEPCORE TIER 3'}
        else{
          const missing=nextMissingDrillRequirement(cost);
          progress=Math.min(1,state.gold/cost.gold,...cost.requirements.map(requirement=>state.cargo[requirement.type]/requirement.amount));
          label=missing?'NEXT DRILL - '+DEPTH_ROUTE_LABELS[missing.scene]+' - '+drillRequirementProgress(missing):'NEXT DRILL - MATERIALS READY';
        }
      }
      else{progress=cleared/mine.barriers.length;label=mine.name+' - PASSAGES '+cleared+'/'+mine.barriers.length}
    }
    else if(state.drillLevel){progress=state.drillLevel/(DRILLS.length-1);label='DRILL AGE - TIER '+state.drillLevel+'/'+(DRILLS.length-1)}
    else if(starforgeMastered()){progress=1;label='FIND DEPTH 2 - THE DRILL AGE AWAITS'}
    else if(!state.areaUnlocked){progress=Math.min(1,Math.min(state.gold/GATE_COST,state.pickaxeLevel/3));label='MOONGLASS CAVERN'}
    else if(!state.emberdeepUnlocked){progress=Math.min(1,Math.min(state.gold/EMBER_GATE_COST,state.pickaxeLevel/4));label='EMBERDEEP FOUNDRY'}
    else if(state.pickaxeLevel<PICKAXES.length-1){progress=Math.min(1,state.gold/PICKAXES[PICKAXES.length-1].cost,state.cargo.emberstone/EMBER_PICKAXE_ORE_REQUIRED);label='EMBER PICKAXE '+Math.min(EMBER_PICKAXE_ORE_REQUIRED,state.cargo.emberstone)+'/'+EMBER_PICKAXE_ORE_REQUIRED}
    else if(nextMastery()){
      const next=nextMastery();progress=Math.min(1,state.gold/next.gold,state.cargo.sunslag/next.sunslag);label='EMBER MASTERY '+state.emberMastery+'/5 - SUNSLAG '+Math.min(next.sunslag,state.cargo.sunslag)+'/'+next.sunslag;
    }else if(!state.fourthUnlocked){progress=0;label='OPEN STARFALL DEPTHS'}
    else if(!state.starforgeVariant){progress=Math.min(1,state.cargo.astralite/STARFORGE_MATERIAL_REQUIRED,state.cargo.crownstone/STARFORGE_MATERIAL_REQUIRED);label='STARFORGE MATERIALS '+Math.min(STARFORGE_MATERIAL_REQUIRED,state.cargo.astralite)+'/'+STARFORGE_MATERIAL_REQUIRED+' · '+Math.min(STARFORGE_MATERIAL_REQUIRED,state.cargo.crownstone)+'/'+STARFORGE_MATERIAL_REQUIRED}
    else{progress=Object.values(state.starforgeUnlocked).filter(Boolean).length/3;label='STARFORGE FORMS '+Object.values(state.starforgeUnlocked).filter(Boolean).length+'/3'}
    unlockFill.style.width=(progress*100)+'%';unlockLabel.textContent=label;
    objective.hidden=false;
    const goal=mainGoal();objectiveText.textContent=goal.title;objectiveDetail.textContent=goal.detail;objectiveDetail.hidden=!goal.detail;renderObjectiveRequirements(goal.requirements||[]);
    renderContext();updateLedger();
    renderFocus();
  }

  function renderFocus(){
    focusMeter.hidden=miningFocus.streak===0;
    if(!miningFocus.streak)return;
    focusCount.textContent=miningFocus.streak+'/5';focusMeter.classList.toggle('master',miningFocus.streak===5);
    focusMeter.querySelectorAll('i').forEach((pip,index)=>pip.classList.toggle('active',index<miningFocus.streak));
  }

  function renderContext(){
    const baseContext=activeContext&&activeContext.startsWith('base:')?baseModuleById(activeContext.slice(5)):null;
    contextPanel.hidden=!activeContext;
    contextPanel.classList.toggle('starforge-open',activeContext==='starforge');
    contextPanel.classList.toggle('chest-context',!!activeContext&&(activeContext.startsWith('chest:')||baseContext&&baseContext.kind==='storage'));
    contextPanel.classList.toggle('mine-context',['mineExit','depthEntrance','depthExit','depthSell','drillForge','hubEntrance','hubExit','deepElevator'].includes(activeContext)||!!activeContext&&activeContext.startsWith('mineEntrance:'));
    contextButton.hidden=false;contextActions.hidden=activeContext==='starforge';contextSecondaryButton.hidden=!baseContext;starforgeChoices.hidden=activeContext!=='starforge';
    if(!activeContext)return;
    const contextAsset=contextUiAsset(baseContext);contextIcon.dataset.kind=baseContext?baseContext.kind:activeContext.split(':')[0];contextIconImage.src=contextAsset+'?v='+ASSET_VERSION;
    if(activeContext.startsWith('mineEntrance:')){
      const mine=MINE_DEFINITIONS[activeContext.slice(13)];
      contextEyebrow.textContent='DUNGEON ENTRANCE';contextTitle.textContent=titleCase(mine.name);contextDetail.textContent='Explore a unique mine layout, clear permanent passages and uncover richer resources.';contextButton.textContent='ENTER';contextButton.disabled=false;
    }else if(activeContext==='hubEntrance'){
      contextEyebrow.textContent='ENDGAME LIFT';contextTitle.textContent='Underground Hub';contextDetail.textContent='A safe permanent base below Starfall. Your full expedition remains intact.';contextButton.textContent='DESCEND';contextButton.disabled=false;
    }else if(activeContext==='hubExit'){
      contextEyebrow.textContent='SURFACE LIFT';contextTitle.textContent='Return to Starfall';contextDetail.textContent='Every wall, lamp and stored resource remains exactly where you left it.';contextButton.textContent='RISE';contextButton.disabled=false;
    }else if(activeContext==='deepElevator'){
      contextEyebrow.textContent='THE DEEP · PHASE 2';contextTitle.textContent='Endless Descent';contextDetail.textContent='The shaft is installed. Deeper expeditions and rare materials arrive in the next phase.';contextButton.textContent='OFFLINE';contextButton.disabled=true;
    }else if(activeContext==='mineExit'){
      const mine=currentMine();contextEyebrow.textContent='MINE EXIT';contextTitle.textContent='Return to '+titleCase(mine.surfaceName);contextDetail.textContent='Your cargo and cleared passages are preserved.';contextButton.textContent='LEAVE';contextButton.disabled=false;
    }else if(activeContext==='depthEntrance'){
      const voidstarLocked=currentScene==='starMine'&&state.drillLevel<DRILLS.length-1;
      contextEyebrow.textContent='HIDDEN DESCENT';contextTitle.textContent=titleCase(MINE_DEPTH_PROFILES[currentScene].name);contextDetail.textContent=voidstarLocked?'The final depth can only be entered with the Deepcore Drill.':'Depth 2 has harder dirt, richer veins and its own persistent tunnels.';contextButton.textContent=voidstarLocked?'DEEPCORE DRILL REQUIRED':'DESCEND';contextButton.disabled=voidstarLocked;
    }else if(activeContext==='depthExit'){
      contextEyebrow.textContent='RETURN SHAFT';contextTitle.textContent='Return to Depth 1';contextDetail.textContent='This is the only passage between the two depths.';contextButton.textContent='CLIMB';contextButton.disabled=false;
    }else if(activeContext==='depthSell'){
      const value=cargoValueTotal(sellableCargo()),kept=protectedCargoLabel();contextEyebrow.textContent='DEPTH EXCHANGE';contextTitle.textContent=value?value+' gold ready to sell':kept?'Upgrade materials protected':'Sell Depth 2 Materials';contextDetail.textContent=value?(kept?'Keeping '+kept+' for your next upgrade.':'The exchange accepts every mineral.'):kept?'Saved for your next upgrade.':'Your inventory is empty.';contextButton.textContent=value?'SELL SAFE':kept?'PROTECTED':'EMPTY';contextButton.disabled=value<=0;
    }else if(activeContext==='drillForge'){
      const drill=nextDrill(),cost=drillCost();contextEyebrow.textContent='DRILL FORGE · TIER '+state.drillLevel+' / '+(DRILLS.length-1);
      if(!drill){contextTitle.textContent='Deepcore Drill';contextDetail.textContent='Maximum drill speed reached.';contextButton.textContent='MASTERED';contextButton.disabled=true}
      else if(!state.drillLevel&&!state.starforgeVariant){contextTitle.textContent=drill.name;contextDetail.textContent='Bring any forged Starforge pickaxe to begin the Drill Age.';contextButton.textContent='STARFORGE REQUIRED';contextButton.disabled=true}
      else{
        const missing=nextMissingDrillRequirement(cost);
        contextTitle.textContent=drill.name;contextDetail.innerHTML=resourceRequirementsMarkup(cost.requirements,missing?DEPTH_ROUTE_LABELS[missing.scene]:'');
        contextButton.textContent=cost.gold+' GOLD';contextButton.disabled=!drillReady();
      }
    }else if(baseContext&&baseContext.kind==='storage'){
      const types=chestTypeCount(baseContext),total=Object.values(baseContext.items).reduce((sum,amount)=>sum+amount,0);
      contextEyebrow.textContent='STORAGE CHEST · '+types+' / '+STORAGE_CHEST_CAPACITY+' TYPES';contextTitle.textContent=total?total+' resources stored':'Empty Storage Chest';contextDetail.textContent='Open inventory to auto-sort, inspect or take resources.';contextButton.textContent='OPEN';contextButton.disabled=false;contextSecondaryButton.textContent='PACK';contextSecondaryButton.disabled=false;
    }else if(baseContext&&baseContext.kind==='sell'){
      const value=cargoValueTotal(sellableCargo()),kept=protectedCargoLabel();contextEyebrow.textContent='MOVABLE SELL CHEST';contextTitle.textContent=value?value+' gold ready to sell':kept?'Upgrade materials protected':'Sell Resources';contextDetail.textContent=value?(kept?'Keeping '+kept+' for your next upgrade.':'Turn carried resources into gold.'):kept?'Saved for your next upgrade.':'Your inventory is empty.';contextButton.textContent=value?'SELL SAFE':kept?'PROTECTED':'EMPTY';contextButton.disabled=value<=0;contextSecondaryButton.textContent='PACK';contextSecondaryButton.disabled=false;
    }else if(activeContext.startsWith('chest:')){
      const chest=chestById(activeContext.slice(6)),ready=chest&&chestRequirementMet(chest);
      if(!chest)return;
      contextEyebrow.textContent=ready?'DISCOVERED CACHE':'SEALED CACHE';contextTitle.textContent=chest.name;
      contextDetail.textContent=ready?chestRewardLabel(chest):'Requires '+chest.requires.label+' - return when your pickaxe is stronger.';
      contextButton.textContent=ready?'OPEN':'LOCKED';contextButton.disabled=!ready;
    }else if(activeContext==='speedShop'){
      const cost=movementSpeedCost(),current=movementSpeedMultiplier(),next=movementSpeedMultiplier(state.movementSpeedLevel+1);
      contextEyebrow.textContent='WAYFARER SHOP · UPGRADE '+(state.movementSpeedLevel+1);contextTitle.textContent='Movement '+current.toFixed(2)+'x → '+next.toFixed(2)+'x';contextDetail.textContent='Permanent movement speed. Unlimited upgrades with rising prices.';contextButton.textContent=cost+' GOLD';contextButton.disabled=state.gold<cost;
    }else if(baseContext&&baseContext.kind==='forge'){
      if(baseContext){contextSecondaryButton.textContent='PACK';contextSecondaryButton.disabled=false}
      if(state.pickaxeLevel===4){
        const next=PICKAXES[5],currentHits=hitsRequired('emberstone',currentPickaxe().power),nextHits=hitsRequired('emberstone',next.power);
        contextEyebrow.textContent='FORGE UPGRADE - POWER '+currentPickaxe().power+' -> '+next.power;contextTitle.textContent=next.name;
        if(!state.emberdeepUnlocked)contextDetail.textContent='Open Emberdeep Foundry first.';
        else if(!emberPickaxeReady())contextDetail.innerHTML=resourceRequirementsMarkup([{type:'emberstone',amount:EMBER_PICKAXE_ORE_REQUIRED}],currentHits+' → '+nextHits+' HITS');
        else contextDetail.innerHTML=resourceRequirementsMarkup([{type:'emberstone',amount:EMBER_PICKAXE_ORE_REQUIRED}],currentHits+' → '+nextHits+' HITS');
        contextButton.textContent=emberPickaxeReady()?next.cost+' GOLD':'LOCKED '+Math.min(EMBER_PICKAXE_ORE_REQUIRED,state.cargo.emberstone)+'/'+EMBER_PICKAXE_ORE_REQUIRED;
        contextButton.disabled=!emberPickaxeReady()||state.gold<next.cost;return;
      }
      if(state.pickaxeLevel>=PICKAXES.length-1){
        const next=nextMastery();
        if(!next){contextEyebrow.textContent='EMBER MASTERY 5 / 5';contextTitle.textContent='Depth Master';contextDetail.textContent=state.fourthUnlocked?'Starfall Depths is open. Astralite now yields to your pickaxe.':'The Starfall Master Seal waits east of Emberdeep.';contextButton.textContent='MASTERED';contextButton.disabled=true}
        else{
          const oldHits=armoredHitsRequired('sunslag',currentPower(),currentShellPower()),newHits=armoredHitsRequired('sunslag',next.power,next.shellPower);
          contextEyebrow.textContent='REFORGE '+state.emberMastery+' / 5 - POWER '+currentPower()+' -> '+next.power;contextTitle.textContent=next.label;
          contextDetail.innerHTML=resourceRequirementsMarkup([{type:'sunslag',amount:next.sunslag}],oldHits+' → '+newHits+' HITS · YIELD '+Math.round(next.bonusYield*100)+'%');
          contextButton.textContent=state.cargo.sunslag>=next.sunslag?next.gold+' GOLD':'LOCKED '+Math.min(state.cargo.sunslag,next.sunslag)+'/'+next.sunslag;
          contextButton.disabled=!masteryReady();
        }
      }
      else{const next=PICKAXES[state.pickaxeLevel+1],type=localReferenceRock(),currentHits=hitsRequired(type,currentPickaxe().power),nextHits=hitsRequired(type,next.power);contextEyebrow.textContent='FORGE UPGRADE · POWER '+currentPickaxe().power+' -> '+next.power;contextTitle.textContent=next.name;contextDetail.textContent=ROCK_TYPES[type].label.toUpperCase()+' '+currentHits+' -> '+nextHits+' HITS';contextButton.textContent=next.cost+' GOLD';contextButton.disabled=state.gold<next.cost}
    }else if(activeContext==='gate'){
      contextEyebrow.textContent='SEALED PASSAGE';contextTitle.textContent='Moonglass Cavern';contextDetail.textContent=state.pickaxeLevel<3?'Requires a Runed Pickaxe.':'A richer vein waits beyond.';contextButton.textContent=GATE_COST+' GOLD';contextButton.disabled=state.pickaxeLevel<3||state.gold<GATE_COST;
    }else if(activeContext==='emberGate'){
      contextEyebrow.textContent='ANCIENT HEAT SEAL';contextTitle.textContent='Emberdeep Foundry';contextDetail.textContent=state.pickaxeLevel<4?'Requires a Moonglass Pickaxe.':'Precision cracks its armored ore faster.';contextButton.textContent=EMBER_GATE_COST+' GOLD';contextButton.disabled=state.pickaxeLevel<4||state.gold<EMBER_GATE_COST;
    }else if(activeContext==='starfallGate'){
      contextEyebrow.textContent='MASTER SEAL';contextTitle.textContent='Starfall Depths';contextDetail.textContent=state.emberMastery<5?'Requires Ember Mastery 5.':'Your completed Ember Pickaxe can open it.';contextButton.textContent=state.emberMastery<5?'LOCKED '+state.emberMastery+'/5':'OPEN';contextButton.disabled=state.emberMastery<5;
    }else if(activeContext==='starforge'){
      contextEyebrow.textContent='STARFORGE';contextTitle.textContent=state.drillLevel?'Replaced by '+currentDrill().name:state.starforgeVariant?STARFORGE_VARIANTS[state.starforgeVariant].name:'Choose a final craft';contextDetail.textContent=state.drillLevel?'Drills are the permanent Depth 2 progression.':'Crusher hits harder. Comet strikes faster. Crownseeker finds more ore.';
      starforgeChoices.querySelectorAll('button').forEach(button=>{
        const id=button.dataset.starforge,variant=STARFORGE_VARIANTS[id],unlocked=state.starforgeUnlocked[id],selected=state.starforgeVariant===id;
        button.classList.toggle('selected',selected&&!state.drillLevel);button.disabled=!!state.drillLevel||selected;
        button.querySelector('b').textContent=variant.name.toUpperCase();
        const detail=button.querySelector('small');if(selected)detail.textContent='ACTIVE';else if(unlocked)detail.textContent='SELECT';else detail.innerHTML='<span class="starforge-short">'+variant.short+'</span>'+resourceAmountMarkup('astralite',variant.cost.astralite,'starforge-resource')+resourceAmountMarkup('crownstone',variant.cost.crownstone,'starforge-resource');
      });
    }
  }

  function updateLedger(){
    if(!menuShade.dataset.resourceIcons){
      for(const [id,type,label] of [['stoneMined','stone','Stone mined'],['copperMined','copper','Copper mined'],['crystalMined','moonglass','Moonglass mined'],['emberMined','emberstone','Emberstone mined'],['astraliteMined','astralite','Astralite mined']]){
        const value=document.getElementById(id),caption=value&&value.parentElement&&value.parentElement.querySelector('span');if(caption){caption.classList.add('ledger-resource-label');caption.innerHTML=resourceIconMarkup(type,'ledger-resource',label)+'<span>'+label+'</span>'}
      }
      menuShade.dataset.resourceIcons='true';
    }
    document.getElementById('stoneMined').textContent=state.mined.stone;
    document.getElementById('copperMined').textContent=state.mined.copper;
    document.getElementById('crystalMined').textContent=state.mined.moonglass;
    document.getElementById('emberMined').textContent=state.mined.emberstone;
    document.getElementById('astraliteMined').textContent=state.mined.astralite;
    document.getElementById('rareMined').textContent=Object.entries(state.mined).filter(([type])=>ROCK_TYPES[type].rare).reduce((total,[,amount])=>total+amount,0);
    document.getElementById('veinsCleared').textContent=Object.values(state.veinsCompleted).reduce((total,value)=>total+value,0);
    document.getElementById('masteryRank').textContent=state.emberMastery+' / 5';
    document.getElementById('deepestFrontier').textContent=state.discoveredFourth?'Starfall':state.discoveredThird?'Emberdeep':state.discoveredSecond?'Moonglass':'Mossvein';
    document.getElementById('starforgeForms').textContent=Object.values(state.starforgeUnlocked).filter(Boolean).length+' / 3';
    document.getElementById('depthOreMined').textContent=Object.entries(state.mined).filter(([type])=>ROCK_TYPES[type].depth2).reduce((total,[,amount])=>total+amount,0);
    document.getElementById('drillTier').textContent=state.drillLevel+' / '+(DRILLS.length-1);
    document.getElementById('movementSpeed').textContent=movementSpeedMultiplier().toFixed(2)+'x · '+state.movementSpeedLevel;
    document.getElementById('chestsOpened').textContent=Object.values(state.openedChests).filter(Boolean).length+' / '+chests.length;
    const totalMineBarriers=MINE_SCENES.reduce((total,scene)=>total+MINE_DEFINITIONS[scene].barriers.length,0);
    document.getElementById('minePassages').textContent=Object.values(state.clearedMineBarriers).filter(Boolean).length+' / '+totalMineBarriers;
    document.getElementById('totalGold').textContent=state.totalGold;
  }

  function drawHubGround(){
    const left=-camera.x,top=-camera.y;
    ctx.fillStyle='#060b0d';ctx.fillRect(left,top,HUB_WORLD.width,HUB_WORLD.height);
    const floor=ctx.createLinearGradient(0,top,0,top+HUB_WORLD.height);floor.addColorStop(0,'#152323');floor.addColorStop(.5,'#101b1c');floor.addColorStop(1,'#0a1215');ctx.fillStyle=floor;ctx.fillRect(78-camera.x,70-camera.y,HUB_WORLD.width-156,HUB_WORLD.height-132);
    ctx.fillStyle='#26302e';ctx.fillRect(0-camera.x,0-camera.y,HUB_WORLD.width,72);ctx.fillRect(0-camera.x,HUB_WORLD.height-62-camera.y,HUB_WORLD.width,62);ctx.fillRect(0-camera.x,0-camera.y,78,HUB_WORLD.height);ctx.fillRect(HUB_WORLD.width-78-camera.x,0-camera.y,78,HUB_WORLD.height);
    ctx.strokeStyle='rgba(218,188,104,.32)';ctx.lineWidth=3;ctx.strokeRect(90-camera.x,82-camera.y,HUB_WORLD.width-180,HUB_WORLD.height-156);
    const platformX=HUB_GRID.originX-28-camera.x,platformY=HUB_GRID.originY-28-camera.y,platformW=HUB_GRID.cols*HUB_GRID.tileSize+56,platformH=HUB_GRID.rows*HUB_GRID.tileSize+56;
    ctx.fillStyle='rgba(7,14,15,.52)';ctx.fillRect(platformX,platformY,platformW,platformH);ctx.strokeStyle='rgba(104,193,170,.2)';ctx.lineWidth=2;ctx.strokeRect(platformX,platformY,platformW,platformH);
    ctx.strokeStyle='rgba(215,184,97,.38)';ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(HUB_STATIONS.deepElevator.x-22-camera.x,HUB_STATIONS.deepElevator.y+72-camera.y);ctx.lineTo(HUB_STATIONS.surfaceLift.x+44-camera.x,HUB_STATIONS.surfaceLift.y-camera.y);ctx.stroke();ctx.strokeStyle='rgba(72,133,121,.42)';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(HUB_STATIONS.deepElevator.x+22-camera.x,HUB_STATIONS.deepElevator.y+72-camera.y);ctx.lineTo(HUB_STATIONS.surfaceLift.x+70-camera.x,HUB_STATIONS.surfaceLift.y+18-camera.y);ctx.stroke();
    ctx.save();ctx.fillStyle='rgba(234,205,117,.18)';for(let x=144;x<HUB_WORLD.width-120;x+=144)for(let y=122;y<HUB_WORLD.height-98;y+=144){const p=worldToScreen(x,y);ctx.fillRect(p.x-2,p.y-2,4,4)}ctx.restore();
  }

  function drawHubBuildGrid(){
    if(!hubBuild.active)return;const x=HUB_GRID.originX-camera.x,y=HUB_GRID.originY-camera.y,w=HUB_GRID.cols*HUB_GRID.tileSize,h=HUB_GRID.rows*HUB_GRID.tileSize;
    ctx.save();ctx.strokeStyle='rgba(112,221,193,.18)';ctx.lineWidth=1;for(let col=0;col<=HUB_GRID.cols;col++){ctx.beginPath();ctx.moveTo(x+col*HUB_GRID.tileSize,y);ctx.lineTo(x+col*HUB_GRID.tileSize,y+h);ctx.stroke()}for(let row=0;row<=HUB_GRID.rows;row++){ctx.beginPath();ctx.moveTo(x,y+row*HUB_GRID.tileSize);ctx.lineTo(x+w,y+row*HUB_GRID.tileSize);ctx.stroke()}
    if(hubBuild.preview){const p=hubCellCenter(hubBuild.preview.col,hubBuild.preview.row),screen=worldToScreen(p.x,p.y);ctx.fillStyle=hubBuild.selected==='erase'?'rgba(235,107,78,.2)':'rgba(116,235,202,.18)';ctx.strokeStyle=hubBuild.selected==='erase'?'rgba(255,130,96,.8)':'rgba(150,246,217,.82)';ctx.lineWidth=2;ctx.fillRect(screen.x-HUB_GRID.tileSize*.46,screen.y-HUB_GRID.tileSize*.46,HUB_GRID.tileSize*.92,HUB_GRID.tileSize*.92);ctx.strokeRect(screen.x-HUB_GRID.tileSize*.46,screen.y-HUB_GRID.tileSize*.46,HUB_GRID.tileSize*.92,HUB_GRID.tileSize*.92)}ctx.restore();
  }

  function drawHubWallTile(tile){
    const center=hubCellCenter(tile.col,tile.row),p=worldToScreen(center.x,center.y),half=HUB_GRID.tileSize*.44;if(p.x<-60||p.y<-60||p.x>viewWidth+60||p.y>viewHeight+60)return;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.42)';ctx.beginPath();ctx.ellipse(2,half*.76,half*1.03,half*.36,0,0,Math.PI*2);ctx.fill();ctx.fillStyle='#263332';ctx.strokeStyle='#76827a';ctx.lineWidth=2;ctx.fillRect(-half,-half*.72,half*2,half*1.44);ctx.strokeRect(-half,-half*.72,half*2,half*1.44);ctx.fillStyle='#46534f';ctx.beginPath();ctx.moveTo(-half,-half*.72);ctx.lineTo(-half+8,-half);ctx.lineTo(half+6,-half);ctx.lineTo(half,-half*.72);ctx.closePath();ctx.fill();ctx.strokeStyle='rgba(226,198,116,.35)';ctx.beginPath();ctx.moveTo(-half+3,0);ctx.lineTo(half-3,0);ctx.moveTo(0,-half*.68);ctx.lineTo(0,half*.68);ctx.stroke();ctx.restore();
  }

  function drawHubLampTile(tile){
    const center=hubCellCenter(tile.col,tile.row),p=worldToScreen(center.x,center.y);if(p.x<-90||p.y<-90||p.x>viewWidth+90||p.y>viewHeight+90)return;
    ctx.save();ctx.translate(p.x,p.y);const glow=ctx.createRadialGradient(0,-20,1,0,-20,82);glow.addColorStop(0,'rgba(132,255,221,.27)');glow.addColorStop(.4,'rgba(94,218,188,.1)');glow.addColorStop(1,'rgba(80,200,180,0)');ctx.fillStyle=glow;ctx.fillRect(-90,-110,180,180);ctx.fillStyle='rgba(0,0,0,.38)';ctx.beginPath();ctx.ellipse(0,17,20,7,0,0,Math.PI*2);ctx.fill();ctx.fillStyle='#3d4944';ctx.strokeStyle='#b99e58';ctx.lineWidth=2;ctx.beginPath();ctx.ellipse(0,12,15,6,0,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.fillRect(-5,-20,10,31);ctx.beginPath();ctx.moveTo(0,-44);ctx.lineTo(10,-30);ctx.lineTo(6,-16);ctx.lineTo(-6,-16);ctx.lineTo(-10,-30);ctx.closePath();ctx.fillStyle='#82f4d6';ctx.shadowColor='#69e8c6';ctx.shadowBlur=17;ctx.fill();ctx.strokeStyle='#d8f6dc';ctx.stroke();ctx.shadowBlur=0;ctx.restore();
  }

  function drawHubTiles(){
    const ordered=state.hub.tiles.slice().sort((a,b)=>a.row-b.row||a.col-b.col);for(const tile of ordered)if(tile.kind==='wall')drawHubWallTile(tile);else drawHubLampTile(tile);
  }

  function drawHubLift(station,{locked=false,label='',selected=false}={}){
    const p=worldToScreen(station.x,station.y);if(p.x<-130||p.y<-130||p.x>viewWidth+130||p.y>viewHeight+130)return;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.45)';ctx.beginPath();ctx.ellipse(0,43,78,23,0,0,Math.PI*2);ctx.fill();
    if(imageReady(VOIDSTAR_ART.shaft)){const image=VOIDSTAR_ART.shaft,scale=Math.min(178/image.naturalWidth,154/image.naturalHeight),w=image.naturalWidth*scale,h=image.naturalHeight*scale;ctx.drawImage(image,-w*.5,50-h,w,h)}
    else{ctx.fillStyle='#1c2830';ctx.strokeStyle='#b9bded';ctx.lineWidth=3;ctx.beginPath();ctx.roundRect(-60,-62,120,104,12);ctx.fill();ctx.stroke()}
    if(locked){ctx.fillStyle='rgba(6,9,13,.64)';ctx.fillRect(-50,-39,100,74);ctx.strokeStyle='#8b7540';ctx.lineWidth=5;for(let x=-36;x<=36;x+=24){ctx.beginPath();ctx.moveTo(x,-38);ctx.lineTo(x,35);ctx.stroke()}ctx.fillStyle='#d0ae55';ctx.beginPath();ctx.arc(0,-1,8,0,Math.PI*2);ctx.fill()}
    if(selected){ctx.strokeStyle=locked?'#d5b760':'#78e1c5';ctx.globalAlpha=.82;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,-2,82+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke()}
    ctx.fillStyle=locked?'#d8bf78':'#96e4cd';ctx.strokeStyle='rgba(2,5,6,.9)';ctx.lineWidth=3;ctx.textAlign='center';ctx.font='900 9px Georgia';readableStrokeText(label,0,66);readableFillText(label,0,66);ctx.restore();
  }

  function drawHubStations(){
    drawHubLift(HUB_STATIONS.deepElevator,{locked:true,label:'THE DEEP · OFFLINE',selected:activeContext==='deepElevator'});drawHubLift(HUB_STATIONS.surfaceLift,{label:'SURFACE LIFT',selected:activeContext==='hubExit'});
  }

  function drawHubLighting(){
    if(!lightCtx||!lightCanvas)return;const sources=[{kind:'hubPlayer',x:player.x,y:player.y,radius:230,color:'#ffe0a0'},...state.hub.tiles.filter(tile=>tile.kind==='lamp').map(tile=>{const center=hubCellCenter(tile.col,tile.row);return{kind:'hubLamp',x:center.x,y:center.y-18,radius:265,color:'#72e6c7'}}),{kind:'hubLift',x:HUB_STATIONS.surfaceLift.x,y:HUB_STATIONS.surfaceLift.y,radius:210,color:'#72e6c7'},{kind:'deepElevator',x:HUB_STATIONS.deepElevator.x,y:HUB_STATIONS.deepElevator.y,radius:190,color:'#d7bd69'}];
    lightingLastSources=sources.map(source=>({kind:source.kind,intensity:.72,radius:source.radius,worldX:source.x,worldY:source.y}));lightingOreCount=0;
    lightCtx.setTransform(1,0,0,1,0,0);lightCtx.clearRect(0,0,lightCanvas.width,lightCanvas.height);lightCtx.setTransform(LIGHTING.bufferScale,0,0,LIGHTING.bufferScale,0,0);lightCtx.globalCompositeOperation='source-over';lightCtx.fillStyle='rgba(1,5,7,.53)';lightCtx.fillRect(0,0,viewWidth,viewHeight);lightCtx.globalCompositeOperation='destination-out';
    for(const source of sources){const p=worldToScreen(source.x,source.y),glow=lightCtx.createRadialGradient(p.x,p.y,0,p.x,p.y,source.radius);glow.addColorStop(0,'rgba(0,0,0,.94)');glow.addColorStop(.48,'rgba(0,0,0,.62)');glow.addColorStop(1,'rgba(0,0,0,0)');lightCtx.fillStyle=glow;lightCtx.fillRect(p.x-source.radius,p.y-source.radius,source.radius*2,source.radius*2)}
    lightCtx.globalCompositeOperation='source-over';ctx.save();ctx.drawImage(lightCanvas,0,0,lightCanvas.width,lightCanvas.height,0,0,viewWidth,viewHeight);ctx.globalCompositeOperation='screen';for(const source of sources.filter(item=>item.kind==='hubLamp')){const p=worldToScreen(source.x,source.y),tint=ctx.createRadialGradient(p.x,p.y,0,p.x,p.y,source.radius*.68);tint.addColorStop(0,'rgba(94,230,194,.13)');tint.addColorStop(1,'rgba(94,230,194,0)');ctx.fillStyle=tint;ctx.fillRect(p.x-source.radius,p.y-source.radius,source.radius*2,source.radius*2)}ctx.restore();
  }

  function drawHubScene(){
    readableTextCapture=true;drawHubGround();drawHubBuildGrid();drawHubTiles();drawHubStations();drawBaseModules();drawPlayer();readableTextCapture=false;drawHubLighting();drawVisualGuide();drawReadableTextOverlay();
  }

  function draw(){
    readableTextQueue.length=0;readableTextCapture=false;
    ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,width,height);
    ctx.save();ctx.scale(viewZoom,viewZoom);
    if(inHub())drawHubScene();
    else if(currentMine()){
      readableTextCapture=true;drawMineGround();drawMineTerrain();drawWorldLifeDrift();drawAmbientLife();drawMineWalls();
      if(currentDepth===1)drawMineEntrance(false,currentMine());
      if(currentDepth===2||state.discoveredDepthEntrances[currentScene])drawDepthEntrance();
      if(currentDepth===2)drawDepthStations();
      drawBaseModules();drawRocks();drawEffects(false);drawGroundDrops();drawPlayer();drawEffects(true);readableTextCapture=false;drawMineLighting();drawWorldLabels();drawVisualGuide();drawReadableTextOverlay();
    }else{
      lightingLastSources=[];lightingOreCount=0;drawGround();drawBiomeStructure();drawDecorations();drawWorldLifeDrift();drawAmbientLife();drawSurfaceBoundaryWalls();drawStations();drawSurfaceMineEntrances();drawGate();drawVeins();drawRocks();drawChests();drawWorldLabels();drawVisualGuide();drawEffects(false);drawGroundDrops();drawPlayer();drawEffects(true);
    }
    ctx.restore();
  }

  function drawVisualGuide(){
    const guide=visualGuide();if(!guide)return;
    const range=distance(player.x,player.y,guide.x,guide.y),fadeRange=guide.closeRadius+125;
    if(range<=guide.closeRadius)return;
    const proximity=clamp((range-guide.closeRadius)/(fadeRange-guide.closeRadius),0,1),p=worldToScreen(guide.x,guide.y),margin=62;
    const onScreen=p.x>=margin&&p.y>=margin&&p.x<=viewWidth-margin&&p.y<=viewHeight-margin,pulse=.5+.5*Math.sin(time*2.8);
    ctx.save();ctx.globalAlpha=(.48+.22*pulse)*(.35+.65*proximity);
    if(!onScreen){
      const centerX=viewWidth*.5,centerY=viewHeight*.5,dx=p.x-centerX,dy=p.y-centerY;
      const scale=Math.min((viewWidth*.5-margin)/Math.max(1,Math.abs(dx)),(viewHeight*.5-margin)/Math.max(1,Math.abs(dy)));
      const edgeX=centerX+dx*scale,edgeY=centerY+dy*scale,angle=Math.atan2(dy,dx);
      ctx.translate(edgeX,edgeY);ctx.rotate(angle);ctx.strokeStyle=guide.color;ctx.fillStyle=guide.color;ctx.shadowBlur=10+5*pulse;ctx.shadowColor=guide.color;ctx.lineWidth=4;ctx.lineCap='round';ctx.lineJoin='round';
      ctx.beginPath();ctx.moveTo(-14,-10);ctx.lineTo(1,0);ctx.lineTo(-14,10);ctx.stroke();
      ctx.globalAlpha*=.48;ctx.beginPath();ctx.moveTo(-28,-8);ctx.lineTo(-17,0);ctx.lineTo(-28,8);ctx.stroke();ctx.restore();return;
    }
    ctx.translate(p.x,p.y-4);ctx.globalCompositeOperation='lighter';
    const glow=ctx.createRadialGradient(0,0,2,0,0,58+8*pulse);glow.addColorStop(0,'rgba(255,249,205,.42)');glow.addColorStop(.35,'rgba(255,224,135,.16)');glow.addColorStop(1,'rgba(255,214,110,0)');ctx.fillStyle=glow;ctx.fillRect(-72,-72,144,144);
    const beam=ctx.createLinearGradient(0,-82,0,18);beam.addColorStop(0,'rgba(255,246,199,0)');beam.addColorStop(.62,'rgba(255,235,166,.08)');beam.addColorStop(1,'rgba(255,237,170,.28)');ctx.fillStyle=beam;ctx.beginPath();ctx.moveTo(-7-pulse*3,-80);ctx.lineTo(7+pulse*3,-80);ctx.lineTo(20,16);ctx.lineTo(-20,16);ctx.closePath();ctx.fill();
    ctx.strokeStyle=guide.color;ctx.fillStyle='#fff8d7';ctx.shadowBlur=12+8*pulse;ctx.shadowColor=guide.color;ctx.lineWidth=2.5;ctx.lineCap='round';
    ctx.beginPath();ctx.moveTo(-12,0);ctx.lineTo(12,0);ctx.moveTo(0,-12);ctx.lineTo(0,12);ctx.stroke();
    ctx.globalAlpha*=.72;ctx.beginPath();ctx.moveTo(-9,-39);ctx.lineTo(0,-29);ctx.lineTo(9,-39);ctx.stroke();ctx.restore();
  }


  function isMossveinVisual(mine){return !!mine&&String(mine.style).startsWith('moss')}
  function isRootwoundProduction(){return currentScene==='mossMine'&&currentDepth===2}
  function isMoonglassProduction(){return currentScene==='moonMine'&&currentDepth===1}
  function isPrismaticProduction(){return currentScene==='moonMine'&&currentDepth===2}
  function isEmberdeepProduction(){return currentScene==='emberMine'&&currentDepth===1}
  function isMoltenProduction(){return currentScene==='emberMine'&&currentDepth===2}
  function isStarfallProduction(){return currentScene==='starMine'&&currentDepth===1}
  function isVoidstarProduction(){return currentScene==='starMine'&&currentDepth===2}
  function activeMineProductionArt(){return isVoidstarProduction()?VOIDSTAR_ART:isStarfallProduction()?STARFALL_ART:isPrismaticProduction()?PRISMATIC_ART:isMoonglassProduction()?MOONGLASS_ART:isMoltenProduction()?MOLTEN_ART:isEmberdeepProduction()?EMBERDEEP_ART:null}
  function mineVisualPass(){return isVoidstarProduction()?'voidstar-production-assets-v1':isStarfallProduction()?'starfall-production-assets-v1':isMoltenProduction()?'molten-production-assets-v1':isEmberdeepProduction()?'emberdeep-production-assets-v1':isPrismaticProduction()?'prismatic-production-assets-v1':isMoonglassProduction()?'moonglass-production-assets-v1':isRootwoundProduction()?'rootwound-production-assets-v1':isMossveinVisual(currentMineVisual())?'mossvein-production-art-v2':'legacy'}
  function depthOneWallAssetPath(){return UNBREAKABLE_WALL_PATHS[currentScene]||null}

  function visualNoise(x,y,salt=0){
    let value=Math.imul((x|0)+salt*101,374761393)^Math.imul((y|0)-salt*53,668265263);
    value=Math.imul(value^(value>>>13),1274126177);return((value^(value>>>16))>>>0)/4294967295;
  }

  function ambientProfileForLocation(){
    if(inHub())return AMBIENT_PROFILES.starfall;
    const key=currentScene==='surface'?BIOMES[regionIndexAt(player.x)].id:AMBIENT_SCENE_KEYS[currentScene];return AMBIENT_PROFILES[key]||AMBIENT_PROFILES.mossvein;
  }

  function ambientSeed(profile,index,salt=0){
    return seededRandom((state.worldSeed^profile.seed^Math.imul(index+1,2654435761)^salt)>>>0);
  }

  function ambientSurfaceRoute(profile,index,x,y){
    const random=ambientSeed(profile,index,31337),biome=BIOMES.find(item=>item.id===profile.key),direction=random()>.5?1:-1;
    const distanceX=profile.flying?72+random()*54:92+random()*54,distanceY=profile.flying?(30+random()*38)*(random()>.5?1:-1):0;
    let routeX=clamp(x+distanceX*direction,biome.start+54,biome.end-54);if(Math.abs(routeX-x)<60)routeX=clamp(x-distanceX*direction,biome.start+54,biome.end-54);
    return{routeX,routeY:clamp(y+distanceY,66,WORLD.height-66)};
  }

  function ambientRouteBehavior(profile,index,mine,sampleTime=time){
    if(reducedMotion)return{routeProgress:0,resting:true,motionDirection:0,phase:0};
    const random=ambientSeed(profile,index,(mine?currentDepth*3571:0)^19081),restDuration=1.6+random()*1.8,travelDuration=(profile.flying?3.1:2.35)+random()*(profile.flying?1.15:.85),cycleLength=2*(restDuration+travelDuration),elapsed=(sampleTime+random()*cycleLength)%cycleLength;
    if(elapsed<restDuration)return{routeProgress:0,resting:true,motionDirection:0,phase:elapsed/cycleLength};
    if(elapsed<restDuration+travelDuration){const progress=(elapsed-restDuration)/travelDuration;return{routeProgress:easeInOut(progress),resting:false,motionDirection:1,phase:elapsed/cycleLength}}
    if(elapsed<restDuration*2+travelDuration)return{routeProgress:1,resting:true,motionDirection:0,phase:elapsed/cycleLength};
    const progress=(elapsed-restDuration*2-travelDuration)/travelDuration;return{routeProgress:1-easeInOut(progress),resting:false,motionDirection:-1,phase:elapsed/cycleLength};
  }

  function ambientResident(profile,index,x,y,mine=false,route=null){
    const random=ambientSeed(profile,index,mine?currentDepth*7919:0),phase=random()*AMBIENT_FRAME_COUNT,scale=.82+random()*.25,path=route||ambientSurfaceRoute(profile,index,x,y),routeX=path.routeX,routeY=path.routeY,routeBehavior=ambientRouteBehavior(profile,index,mine);
    let routeProgress=routeBehavior.routeProgress,resting=routeBehavior.resting,motionDirection=routeBehavior.motionDirection,reactionStrength=0,reacting=false,recovering=false;
    let worldX=x+(routeX-x)*routeProgress,worldY=y+(routeY-y)*routeProgress,flip=random()>.5;
    const disturbanceMatches=!reducedMotion&&ambientDisturbance.scene===currentScene&&ambientDisturbance.depth===currentDepth&&(ambientDisturbance.active||ambientDisturbance.remaining>0),reactionRadius=profile.flying?270:225,startBehavior=disturbanceMatches?ambientRouteBehavior(profile,index,mine,ambientDisturbance.startedAt):routeBehavior,startProgress=startBehavior.routeProgress,startWorldX=x+(routeX-x)*startProgress,startWorldY=y+(routeY-y)*startProgress,playerDistance=distance(ambientDisturbance.startX,ambientDisturbance.startY,startWorldX,startWorldY);
    if(disturbanceMatches&&playerDistance<reactionRadius){
      const proximity=1-playerDistance/reactionRadius,fleeTarget=distance(ambientDisturbance.startX,ambientDisturbance.startY,routeX,routeY)>distance(ambientDisturbance.startX,ambientDisturbance.startY,x,y)?1:0,fleeAtRelease=easeInOut(clamp(ambientDisturbance.activeDuration/AMBIENT_FLEE_DURATION,0,1)),releaseProgress=startProgress+(fleeTarget-startProgress)*fleeAtRelease;
      if(ambientDisturbance.active){const fleeProgress=easeInOut(clamp((time-ambientDisturbance.startedAt)/AMBIENT_FLEE_DURATION,0,1));routeProgress=startProgress+(fleeTarget-startProgress)*fleeProgress;reactionStrength=proximity*(.35+.65*fleeProgress);reacting=true}
      else{const recoveryProgress=easeInOut(clamp(1-ambientDisturbance.remaining/AMBIENT_RECOVERY_DURATION,0,1));routeProgress=releaseProgress+(routeProgress-releaseProgress)*recoveryProgress;reactionStrength=proximity*(1-recoveryProgress);reacting=ambientDisturbance.remaining>0;recovering=reacting}
      motionDirection=(recovering?routeBehavior.routeProgress:fleeTarget)>routeProgress?1:-1;resting=false;worldX=x+(routeX-x)*routeProgress;worldY=y+(routeY-y)*routeProgress;
    }
    if(!reducedMotion&&profile.flying&&!mine){
      const dx=routeX-x,dy=routeY-y,length=Math.max(1,Math.hypot(dx,dy)),arc=Math.sin(routeProgress*Math.PI)*(reacting?18:12);
      worldX+=-dy/length*arc;worldY+=dx/length*arc;
    }
    if(!reducedMotion&&!profile.flying&&!mine&&!resting)worldY-=Math.abs(Math.sin(time*8+phase))*2.4;
    if(profile.directional&&!reducedMotion)flip=(routeX-x)*(motionDirection||1)<0;
    if(mine&&!ambientMinePointOpenAt(worldX,worldY)){worldX=x;worldY=y}
    const behavior=reducedMotion?'reduced':recovering?'returning':reacting?'fleeing':resting?'resting':'roaming',frame=reducedMotion||resting?0:Math.floor((time*profile.fps*(reacting&&!recovering?1.35:1)+phase)%AMBIENT_FRAME_COUNT);
    return{id:(mine?currentScene+':'+currentDepth:profile.key)+':resident:'+index,profile:profile.key,asset:AMBIENT_PATHS[profile.key],x:worldX,y:worldY,anchorX:x,anchorY:y,routeX,routeY,routeProgress,behaviorPhase:routeBehavior.phase,behavior,resting,reacting,reactionStrength,frame,size:profile.size*scale,flip,event:false};
  }

  function ambientOnScreen(instance,margin=70){
    const p=worldToScreen(instance.x,instance.y);return p.x>=-margin&&p.y>=-margin&&p.x<=viewWidth+margin&&p.y<=viewHeight+margin;
  }

  function ambientRareEventState(){
    const interval=48,duration=6.6,offset=(state.worldSeed%2300)/100,cycle=(time+offset)%interval,enabled=currentScene==='surface'&&!reducedMotion,active=enabled&&cycle<duration;
    return{enabled,active,interval,duration,progress:active?cycle/duration:0,nextIn:active?0:interval-cycle};
  }

  function ambientRareEventInstances(){
    const event=ambientRareEventState();if(!event.active)return[];
    const biome=BIOMES[regionIndexAt(player.x)],profile=AMBIENT_PROFILES[biome.id],reverse=((state.worldSeed^profile.seed)&1)===1,cycle=event.progress*event.duration,travelDuration=5.25,instances=[];
    for(let index=0;index<3;index++){
      const local=(cycle-index*.5)/travelDuration;if(local<0||local>1)continue;
      const progress=reverse?1-local:local,start=biome.start-70,end=biome.end+70,x=start+(end-start)*progress;
      const lane=profile.flying?310+index*145:995+index*18,y=clamp(lane+Math.sin(time*(profile.flying?2.1:5.4)+index)* (profile.flying?18:3),56,WORLD.height-56),phase=index*.83;
      instances.push({id:profile.key+':crossing:'+index,profile:profile.key,asset:AMBIENT_PATHS[profile.key],x,y,anchorX:x,anchorY:y,behavior:'crossing',resting:false,reacting:false,reactionStrength:0,frame:Math.floor((time*profile.fps+phase)%AMBIENT_FRAME_COUNT),size:profile.size*(.82+index*.07),flip:profile.directional?reverse:index%2===1,event:true});
    }
    return instances;
  }

  function surfaceAmbientInstances(){
    const instances=[];
    for(const profile of Object.values(AMBIENT_PROFILES)){
      const anchors=AMBIENT_SURFACE_ANCHORS[profile.key];
      for(let index=0;index<anchors.length;index++){
        const instance=ambientResident(profile,index,anchors[index][0],anchors[index][1]);if(ambientOnScreen(instance))instances.push(instance);
      }
    }
    instances.push(...ambientRareEventInstances().filter(instance=>ambientOnScreen(instance,90)));
    const centerX=camera.x+viewWidth*.5,centerY=camera.y+viewHeight*.5;
    instances.sort((a,b)=>Number(b.event)-Number(a.event)||distance(a.x,a.y,centerX,centerY)-distance(b.x,b.y,centerX,centerY));
    return instances.slice(0,AMBIENT_SURFACE_MAX_VISIBLE);
  }

  function ambientMinePointOpenAt(x,y){
    const terrain=currentTerrain();if(!terrain||x<36||y<36||x>currentMine().width-36||y>currentMine().height-36)return false;
    const concealed=mossveinConcealedCells(terrain),radius=36,minCol=Math.max(0,Math.floor((x-radius)/MINE_TILE_SIZE)),maxCol=Math.min(terrain.cols-1,Math.floor((x+radius)/MINE_TILE_SIZE)),minRow=Math.max(0,Math.floor((y-radius)/MINE_TILE_SIZE)),maxRow=Math.min(terrain.rows-1,Math.floor((y+radius)/MINE_TILE_SIZE));
    for(let row=minRow;row<=maxRow;row++)for(let col=minCol;col<=maxCol;col++){
      const nearestX=clamp(x,(col)*MINE_TILE_SIZE,(col+1)*MINE_TILE_SIZE),nearestY=clamp(y,row*MINE_TILE_SIZE,(row+1)*MINE_TILE_SIZE),index=row*terrain.cols+col;
      if(distance(x,y,nearestX,nearestY)<=radius&&(terrainTypeAt(terrain,col,row)||concealed.has(index)))return false;
    }
    for(const solid of activeMineSolids())if(x+radius>solid.x&&x-radius<solid.x+solid.w&&y+radius>solid.y&&y-radius<solid.y+solid.h)return false;
    for(const rock of currentRocks())if(!rock.broken&&distance(x,y,rock.x,rock.y)<76)return false;
    for(const module of allBaseModules())if(moduleIsHere(module)&&distance(x,y,module.x,module.y)<86)return false;
    for(const cavern of terrain.caverns)if(!state.claimedPocketRewards[cavern.reward.id]&&distance(x,y,cavern.x,cavern.y)<92)return false;
    const mine=currentMine(),entry=currentDepth===1?mine.entrance:depthEntrances[currentScene];if(distance(x,y,entry.x,entry.y)<105)return false;
    const shaft=depthEntrances[currentScene];if(distance(x,y,shaft.x,shaft.y)<112)return false;
    if(currentDepth===2){const stations=depthStations();if(distance(x,y,stations.sell.x,stations.sell.y)<105||distance(x,y,stations.forge.x,stations.forge.y)<105)return false}
    return true;
  }

  function ambientMineSegmentOpen(x,y,routeX,routeY){
    const samples=Math.max(1,Math.ceil(distance(x,y,routeX,routeY)/8));
    for(let sample=1;sample<=samples;sample++){
      const progress=sample/samples;if(!ambientMinePointOpenAt(x+(routeX-x)*progress,y+(routeY-y)*progress))return false;
    }
    return true;
  }

  function ambientMineRoute(profile,id,x,y){
    const candidates=profile.flying?
      [[112,0],[-112,0],[0,112],[0,-112],[84,72],[-84,72],[84,-72],[-84,-72],[72,0],[-72,0],[0,72],[0,-72],[48,0],[-48,0],[0,48],[0,-48],[28,0],[-28,0],[0,28],[0,-28]]:
      [[128,0],[-128,0],[104,0],[-104,0],[88,32],[-88,32],[88,-32],[-88,-32],[72,0],[-72,0],[48,0],[-48,0],[36,0],[-36,0],[28,0],[-28,0]];
    const start=Math.floor(visualNoise(Math.floor(x/MINE_TILE_SIZE),Math.floor(y/MINE_TILE_SIZE),profile.seed+id)*candidates.length);
    for(let offset=0;offset<candidates.length;offset++){
      const vector=candidates[(start+offset)%candidates.length],routeX=x+vector[0],routeY=y+vector[1];
      if(ambientMineSegmentOpen(x,y,routeX,routeY))return{routeX,routeY};
    }
    return{routeX:x,routeY:y};
  }

  function mineAmbientAnchors(terrain,profile){
    const discoveryKey=terrain.caverns.map(cavern=>cavernIsDiscovered(cavern.id)?'1':'0').join('')+(terrain.depthEntrance&&state.discoveredDepthEntrances[currentScene]?'1':'0'),cacheKey=state.worldSeed+':'+profile.key+':'+currentDepth+':'+discoveryKey;
    if(terrain._ambientAnchorKey===cacheKey&&terrain._ambientAnchors)return terrain._ambientAnchors;
    const blockCells=5,anchors=[];
    for(let blockRow=0;blockRow<Math.ceil(terrain.rows/blockCells);blockRow++)for(let blockCol=0;blockCol<Math.ceil(terrain.cols/blockCells);blockCol++){
      const candidates=[];
      for(let localRow=0;localRow<blockCells;localRow++)for(let localCol=0;localCol<blockCells;localCol++){
        const row=blockRow*blockCells+localRow,col=blockCol*blockCells+localCol;if(row>=terrain.rows||col>=terrain.cols)continue;
        candidates.push({row,col,score:visualNoise(col,row,profile.seed+currentDepth*97+(state.worldSeed&1023))});
      }
      candidates.sort((a,b)=>a.score-b.score);
      for(const candidate of candidates){
        const x=(candidate.col+.5)*MINE_TILE_SIZE,y=(candidate.row+.5)*MINE_TILE_SIZE;
        if(!ambientMinePointOpenAt(x,y)||anchors.some(anchor=>distance(anchor.x,anchor.y,x,y)<112))continue;
        const id=blockRow*Math.ceil(terrain.cols/blockCells)+blockCol,route=ambientMineRoute(profile,id,x,y);
        if(distance(x,y,route.routeX,route.routeY)<20)continue;
        anchors.push({id,x,y,routeX:route.routeX,routeY:route.routeY,score:candidate.score});break;
      }
    }
    terrain._ambientAnchorKey=cacheKey;terrain._ambientAnchors=anchors;return anchors;
  }

  function mineAmbientInstances(){
    const terrain=currentTerrain(),profile=ambientProfileForLocation();if(!terrain)return[];
    const visible=mineAmbientAnchors(terrain,profile)
      .filter(anchor=>ambientOnScreen(anchor,150)&&ambientMinePointOpenAt(anchor.x,anchor.y))
      .map(anchor=>({anchor,instance:ambientResident(profile,anchor.id,anchor.x,anchor.y,true,anchor)}))
      .filter(candidate=>ambientOnScreen(candidate.instance,90));
    visible.sort((a,b)=>distance(a.instance.x,a.instance.y,player.x,player.y)-distance(b.instance.x,b.instance.y,player.x,player.y)||a.anchor.score-b.anchor.score);
    return visible.slice(0,AMBIENT_MINE_MAX_VISIBLE).map(candidate=>candidate.instance);
  }

  function ambientVisibleInstances(){return inHub()?[]:currentScene==='surface'?surfaceAmbientInstances():mineAmbientInstances()}

  function ambientLifeSnapshot(){
    const visible=ambientVisibleInstances(),event=ambientRareEventState();
    return{
      ...AMBIENT_RENDER_CONTRACT,assets:{...AMBIENT_PATHS},activeProfile:ambientProfileForLocation().key,
      location:currentScene==='surface'?'surface':currentScene+':'+currentDepth,reducedMotion,
      maxVisible:inHub()?0:currentScene==='surface'?AMBIENT_SURFACE_MAX_VISIBLE:AMBIENT_MINE_MAX_VISIBLE,
      visible:visible.map(instance=>({id:instance.id,profile:instance.profile,asset:instance.asset,x:instance.x,y:instance.y,anchorX:instance.anchorX,anchorY:instance.anchorY,routeX:instance.routeX,routeY:instance.routeY,routeProgress:instance.routeProgress,behaviorPhase:instance.behaviorPhase,behavior:instance.behavior,resting:instance.resting,reacting:instance.reacting,reactionStrength:instance.reactionStrength,frame:instance.frame,size:instance.size,flip:instance.flip,event:instance.event})),
      event
    };
  }

  function drawAmbientLife(){
    for(const instance of ambientVisibleInstances()){
      const image=AMBIENT_ART[instance.profile];if(!imageReady(image))continue;
      const p=worldToScreen(instance.x,instance.y),profile=AMBIENT_PROFILES[instance.profile],size=instance.size,baseline=profile.baseline?.[instance.frame]||0;
      ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=instance.event?.96:.88;
      if(!profile.flying){ctx.fillStyle='rgba(5,4,3,.24)';ctx.beginPath();ctx.ellipse(0,size*.31,size*.29,size*.075,0,0,Math.PI*2);ctx.fill()}
      if(instance.flip)ctx.scale(-1,1);
      ctx.drawImage(image,instance.frame*AMBIENT_FRAME_SIZE,0,AMBIENT_FRAME_SIZE,AMBIENT_FRAME_SIZE,-size*.5,-size*.5+baseline,size,size);ctx.restore();
    }
  }

  function worldLifeBiomeKeyAt(x=player.x){
    if(inHub())return'starfall';
    return currentScene==='surface'?(BIOMES[regionIndexAt(x)]?.id||'mossvein'):(AMBIENT_SCENE_KEYS[currentScene]||'mossvein');
  }

  function worldLifeDriftInstance(profile,index,anchorX,anchorY,mine=false){
    const phase=visualNoise(Math.floor(anchorX/MINE_TILE_SIZE),Math.floor(anchorY/MINE_TILE_SIZE),profile.seed+index)*Math.PI*2,
      cycle=reducedMotion?0:time*(.42+profile.driftFps*.08)+phase,
      x=anchorX+(reducedMotion?0:Math.sin(cycle)*7),y=anchorY+(reducedMotion?0:Math.cos(cycle*.73)*5),
      frame=reducedMotion?0:Math.floor((time*profile.driftFps+phase/Math.PI)%WORLD_LIFE_FRAME_COUNT),
      scale=.84+visualNoise(index,profile.seed,state.worldSeed&255)*.24;
    return{id:(mine?currentScene+':'+currentDepth:profile.key)+':drift:'+index,profile:profile.key,asset:WORLD_LIFE_PATHS[profile.key].drift,x,y,anchorX,anchorY,frame,size:profile.driftSize*scale,alpha:profile.driftAlpha,mine};
  }

  function surfaceWorldLifeDriftInstances(){
    const instances=[],centerX=camera.x+viewWidth*.5,centerY=camera.y+viewHeight*.5;
    for(const profile of Object.values(WORLD_LIFE_PROFILES)){
      const anchors=WORLD_LIFE_SURFACE_ANCHORS[profile.key];
      for(let index=0;index<anchors.length;index++){
        const instance=worldLifeDriftInstance(profile,index,anchors[index][0],anchors[index][1]);if(ambientOnScreen(instance,110))instances.push(instance);
      }
    }
    instances.sort((a,b)=>distance(a.x,a.y,centerX,centerY)-distance(b.x,b.y,centerX,centerY)||a.id.localeCompare(b.id));
    return instances.slice(0,WORLD_LIFE_SURFACE_MAX_VISIBLE);
  }

  function mineWorldLifeDriftInstances(){
    const terrain=currentTerrain(),profile=WORLD_LIFE_PROFILES[worldLifeBiomeKeyAt()];if(!terrain)return[];
    return mineAmbientAnchors(terrain,AMBIENT_PROFILES[profile.key])
      .map(anchor=>({anchor,instance:worldLifeDriftInstance(profile,anchor.id,anchor.x,anchor.y,true)}))
      .filter(candidate=>ambientOnScreen(candidate.instance,120)&&ambientMinePointOpenAt(candidate.instance.x,candidate.instance.y))
      .sort((a,b)=>distance(a.instance.x,a.instance.y,player.x,player.y)-distance(b.instance.x,b.instance.y,player.x,player.y)||a.anchor.score-b.anchor.score)
      .slice(0,WORLD_LIFE_MINE_MAX_VISIBLE).map(candidate=>candidate.instance);
  }

  function worldLifeDriftInstances(){return inHub()?[]:currentScene==='surface'?surfaceWorldLifeDriftInstances():mineWorldLifeDriftInstances()}

  function spawnTerrainResponse(kind,x,y,strength=1){
    if(reducedMotion||inHub())return null;
    if(kind==='mine'){
      if(time-lastTerrainImpactAt<.085||terrainResponses.some(item=>item.scene===currentScene&&item.depth===currentDepth&&item.kind!=='footstep'&&distance(item.x,item.y,x,y)<32))return null;
      lastTerrainImpactAt=time;
    }
    if(kind==='break')terrainResponses=terrainResponses.filter(item=>!(item.scene===currentScene&&item.depth===currentDepth&&item.kind!=='footstep'&&distance(item.x,item.y,x,y)<32));
    const profile=WORLD_LIFE_PROFILES[worldLifeBiomeKeyAt(x)],life=kind==='footstep'?.42:kind==='break'?.48:.34,artKind=kind==='footstep'?'response':'impact',
      response={id:nextTerrainResponseId++,kind,profile:profile.key,asset:WORLD_LIFE_PATHS[profile.key][artKind],scene:currentScene,depth:currentDepth,x,y,age:0,life,strength,rotation:(visualNoise(nextTerrainResponseId,profile.seed,state.worldSeed&511)-.5)*(kind==='footstep'?.18:.24)};
    terrainResponses.push(response);if(terrainResponses.length>WORLD_LIFE_RESPONSE_MAX_VISIBLE)terrainResponses.splice(0,terrainResponses.length-WORLD_LIFE_RESPONSE_MAX_VISIBLE);return response;
  }

  function visibleTerrainResponses(){return terrainResponses.filter(item=>item.scene===currentScene&&item.depth===currentDepth&&ambientOnScreen(item,110))}

  function terrainResponseRenderState(response){
    const progress=clamp(response.age/response.life,0,1),frame=Math.min(WORLD_LIFE_FRAME_COUNT-1,Math.floor(progress*WORLD_LIFE_FRAME_COUNT)),profile=WORLD_LIFE_PROFILES[response.profile],
      size=profile.responseSize*response.strength*(.72+easeOut(progress)*.34),alpha=profile.responseAlpha*(response.kind==='footstep'?.58:1)*Math.sin(progress*Math.PI);
    return{progress,frame,size,alpha};
  }

  function worldLifeSnapshot(){
    const drift=worldLifeDriftInstances(),responses=visibleTerrainResponses();
    return{
      ...WORLD_LIFE_RENDER_CONTRACT,assets:JSON.parse(JSON.stringify(WORLD_LIFE_PATHS)),activeProfile:worldLifeBiomeKeyAt(),location:currentScene==='surface'?'surface':currentScene+':'+currentDepth,reducedMotion,
      maxVisible:inHub()?0:currentScene==='surface'?WORLD_LIFE_SURFACE_MAX_VISIBLE:WORLD_LIFE_MINE_MAX_VISIBLE,
      drift:drift.map(item=>({id:item.id,profile:item.profile,asset:item.asset,x:item.x,y:item.y,anchorX:item.anchorX,anchorY:item.anchorY,frame:item.frame,size:item.size,alpha:item.alpha})),
      responses:responses.map(item=>{const render=terrainResponseRenderState(item);return{id:item.id,kind:item.kind,profile:item.profile,asset:item.asset,x:item.x,y:item.y,age:item.age,life:item.life,frame:render.frame,size:render.size,alpha:render.alpha}})
    };
  }

  function drawWorldLifeDrift(){
    for(const instance of worldLifeDriftInstances()){
      const image=WORLD_LIFE_ART.drift[instance.profile];if(!imageReady(image))continue;
      const p=worldToScreen(instance.x,instance.y),breathe=reducedMotion?1:.92+.08*Math.sin(time*1.25+instance.anchorX*.013);
      ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=instance.alpha*breathe;
      ctx.drawImage(image,instance.frame*WORLD_LIFE_FRAME_SIZE,0,WORLD_LIFE_FRAME_SIZE,WORLD_LIFE_FRAME_SIZE,-instance.size*.5,-instance.size*.5,instance.size,instance.size);ctx.restore();
    }
  }

  function drawTerrainResponses(){
    for(const response of visibleTerrainResponses()){
      const image=WORLD_LIFE_ART[response.kind==='footstep'?'response':'impact'][response.profile];if(!imageReady(image))continue;
      const render=terrainResponseRenderState(response),p=worldToScreen(response.x,response.y);
      ctx.save();ctx.translate(p.x,p.y);ctx.rotate(response.rotation);ctx.globalAlpha=render.alpha;
      ctx.drawImage(image,render.frame*WORLD_LIFE_FRAME_SIZE,0,WORLD_LIFE_FRAME_SIZE,WORLD_LIFE_FRAME_SIZE,-render.size*.5,-render.size*.5,render.size,render.size);ctx.restore();
    }
  }

  function drawMossveinFloorArt(deep){
    const rootwound=deep&&currentScene==='mossMine',image=rootwound?ROOTWOUND_ART.floor:MOSSVEIN_ART.floor;if(!imageReady(image))return false;
    const pattern=(rootwound?ROOTWOUND_ART.floorPattern:MOSSVEIN_ART.floorPattern)||(typeof ctx.createPattern==='function'?ctx.createPattern(image,'repeat'):null);if(!pattern)return false;
    if(rootwound)ROOTWOUND_ART.floorPattern=pattern;else MOSSVEIN_ART.floorPattern=pattern;ctx.save();ctx.globalAlpha=rootwound?1:.72;ctx.fillStyle=pattern;
    ctx.fillRect(camera.x-8,camera.y-8,viewWidth+16,viewHeight+16);ctx.restore();return true;
  }

  function drawMossveinFloorBase(mine){
    const deep=currentDepth===2,rootwound=deep&&currentScene==='mossMine'&&imageReady(ROOTWOUND_ART.floor),base=ctx.createLinearGradient(0,camera.y,0,camera.y+viewHeight);
    base.addColorStop(0,deep?'#1b1713':'#211f19');base.addColorStop(1,deep?'#100e0c':'#151712');
    ctx.fillStyle=base;ctx.fillRect(0,0,mine.width,mine.height);
    const hasArt=drawMossveinFloorArt(deep);
    const ambient=ctx.createRadialGradient(player.x,player.y,35,player.x,player.y,540);
    ambient.addColorStop(0,deep?'rgba(184,119,58,.2)':'rgba(202,149,77,.21)');
    ambient.addColorStop(.42,deep?'rgba(104,65,35,.08)':'rgba(104,84,51,.09)');ambient.addColorStop(1,'rgba(0,0,0,0)');
    ctx.fillStyle=ambient;ctx.fillRect(camera.x-80,camera.y-80,viewWidth+160,viewHeight+160);
    if(hasArt){ctx.fillStyle=rootwound?'rgba(8,5,3,.08)':deep?'rgba(11,8,6,.2)':'rgba(12,15,11,.1)';ctx.fillRect(camera.x-80,camera.y-80,viewWidth+160,viewHeight+160)}
  }

  function drawMossveinFloorDetail(mine){
    const deep=currentDepth===2,spacing=148,startX=Math.max(0,Math.floor(camera.x/spacing)-1)*spacing,endX=Math.min(mine.width,camera.x+viewWidth+spacing);
    const startY=Math.max(0,Math.floor(camera.y/spacing)-1)*spacing,endY=Math.min(mine.height,camera.y+viewHeight+spacing);
    for(let gridY=startY;gridY<=endY;gridY+=spacing)for(let gridX=startX;gridX<=endX;gridX+=spacing){
      const gx=gridX/spacing,gy=gridY/spacing,n=visualNoise(gx,gy,currentDepth+2),n2=visualNoise(gy,gx,17);
      const x=gridX+24+n*96,y=gridY+20+n2*96;
      ctx.save();ctx.translate(x,y);ctx.rotate((n-.5)*1.15);
      if(n>.62){
        ctx.fillStyle=deep?'rgba(103,68,39,.18)':'rgba(73,101,66,.18)';
        ctx.beginPath();ctx.moveTo(-26,-3);ctx.quadraticCurveTo(-12,-16,11,-10);ctx.quadraticCurveTo(31,-4,24,10);ctx.quadraticCurveTo(2,17,-24,8);ctx.closePath();ctx.fill();
        ctx.fillStyle=deep?'rgba(190,124,60,.17)':'rgba(116,151,88,.2)';
        for(let leaf=0;leaf<3;leaf++){ctx.beginPath();ctx.ellipse(-11+leaf*10,-2+(leaf%2)*5,7,2.8,leaf*.48,0,Math.PI*2);ctx.fill()}
      }else{
        ctx.fillStyle=deep?'rgba(102,77,55,.27)':'rgba(105,111,91,.23)';ctx.strokeStyle=deep?'rgba(181,124,72,.16)':'rgba(164,159,123,.14)';ctx.lineWidth=1;
        ctx.beginPath();ctx.moveTo(-13,-4);ctx.lineTo(-4,-11);ctx.lineTo(14,-5);ctx.lineTo(11,7);ctx.lineTo(-9,9);ctx.closePath();ctx.fill();ctx.stroke();
        if(n<.3){ctx.fillStyle=deep?'rgba(134,93,54,.18)':'rgba(59,75,56,.22)';ctx.beginPath();ctx.ellipse(18,11,19,7,.25,0,Math.PI*2);ctx.fill()}
      }
      ctx.restore();
    }
    const crackSpacing=226,startCrackY=Math.max(0,Math.floor(camera.y/crackSpacing)-1)*crackSpacing;
    ctx.strokeStyle=deep?'rgba(161,105,61,.19)':'rgba(109,124,91,.15)';ctx.lineWidth=1.35;ctx.lineCap='round';
    for(let y=startCrackY;y<camera.y+viewHeight+crackSpacing;y+=crackSpacing){
      const band=Math.floor(y/crackSpacing),startCrackX=Math.floor(camera.x/crackSpacing-1)*crackSpacing;
      for(let x=startCrackX;x<camera.x+viewWidth+crackSpacing;x+=crackSpacing){
        const anchor=x+visualNoise(x/crackSpacing,band,9)*96;
        ctx.beginPath();ctx.moveTo(anchor,y);ctx.lineTo(anchor+18,y-8);ctx.lineTo(anchor+31,y+2);ctx.lineTo(anchor+52,y-13);ctx.stroke();
      }
    }
  }

  function mossveinConcealedCells(terrain){
    const cacheKey=terrain.caverns.map(cavern=>cavernIsDiscovered(cavern.id)?'1':'0').join('')+(terrain.depthEntrance&&state.discoveredDepthEntrances[currentScene]?'1':'0');
    if(terrain._mossConcealedKey===cacheKey&&terrain._mossConcealedCells)return terrain._mossConcealedCells;
    const concealed=new Set();
    for(const cavern of terrain.caverns)if(!cavernIsDiscovered(cavern.id))for(const index of cavern.cells)concealed.add(index);
    if(terrain.depthEntrance&&!state.discoveredDepthEntrances[currentScene])for(const index of terrain.depthEntrance.cells)concealed.add(index);
    terrain._mossConcealedKey=cacheKey;terrain._mossConcealedCells=concealed;return concealed;
  }

  function mossveinVisualSolidAt(terrain,concealed,col,row){
    if(col<0||row<0||col>=terrain.cols||row>=terrain.rows)return false;
    return !!terrainTypeAt(terrain,col,row)||concealed.has(row*terrain.cols+col);
  }

  function mineralHintAtTerrainCell(terrain,concealed,col,row){
    if(!terrainTypeAt(terrain,col,row))return null;
    const index=row*terrain.cols+col,key=terrain.scene+':'+terrain.depth+':'+index;
    const candidates=(mineRocksByTerrainCell.get(key)||[]).filter(rock=>!rock.broken&&!rock.barrierId&&!rockIsExposed(rock));
    if(!candidates.length)return null;
    const sides=[
      !mossveinVisualSolidAt(terrain,concealed,col,row-1),
      !mossveinVisualSolidAt(terrain,concealed,col+1,row),
      !mossveinVisualSolidAt(terrain,concealed,col,row+1),
      !mossveinVisualSolidAt(terrain,concealed,col-1,row)
    ].map((open,side)=>open?side:-1).filter(side=>side>=0);
    if(!sides.length)return null;
    const rock=candidates.find(item=>ROCK_TYPES[item.type].rare)||candidates[0];return{index,rock,sides};
  }

  function currentMineralHints(){
    const terrain=currentTerrain(),mine=currentMine();if(!terrain||!isMossveinVisual(mine)&&!activeMineProductionArt())return[];
    const concealed=mossveinConcealedCells(terrain),hints=[];
    for(const rock of currentRocks()){
      if(rock.broken||rock.barrierId||rockIsExposed(rock))continue;
      const cell=terrainCellAt(terrain,rock.x,rock.y),hint=cell&&mineralHintAtTerrainCell(terrain,concealed,cell.col,cell.row);
      if(hint&&hint.rock.id===rock.id)hints.push(hint);
    }
    return hints;
  }

  function drawMossveinTerrainTexture(deep){
    const spacing=126,startX=Math.floor(camera.x/spacing-1)*spacing,endX=camera.x+viewWidth+spacing;
    const startY=Math.floor(camera.y/spacing-1)*spacing,endY=camera.y+viewHeight+spacing;
    for(let gy=startY;gy<=endY;gy+=spacing)for(let gx=startX;gx<=endX;gx+=spacing){
      const cx=gx+visualNoise(gx/spacing,gy/spacing,31)*96,cy=gy+visualNoise(gy/spacing,gx/spacing,37)*94;
      const n=visualNoise(gx/spacing,gy/spacing,43),w=52+n*46,h=29+n*25;
      ctx.save();ctx.translate(cx,cy);ctx.rotate((n-.5)*.7);
      ctx.fillStyle=deep?(n>.5?'rgba(141,91,48,.2)':'rgba(80,57,40,.24)'):(n>.5?'rgba(126,111,72,.2)':'rgba(67,76,57,.24)');
      ctx.beginPath();ctx.moveTo(-w*.55,-h*.08);ctx.quadraticCurveTo(-w*.26,-h*.58,w*.18,-h*.42);ctx.lineTo(w*.55,-h*.04);ctx.quadraticCurveTo(w*.28,h*.52,-w*.18,h*.46);ctx.closePath();ctx.fill();
      ctx.strokeStyle=deep?'rgba(211,145,77,.12)':'rgba(185,174,122,.12)';ctx.lineWidth=1.4;ctx.beginPath();ctx.moveTo(-w*.38,0);ctx.quadraticCurveTo(0,-h*.35,w*.38,-h*.05);ctx.stroke();
      if(!deep&&n>.72){ctx.fillStyle='rgba(91,135,70,.28)';ctx.beginPath();ctx.ellipse(-w*.12,-h*.2,18,4.5,-.15,0,Math.PI*2);ctx.fill()}
      ctx.restore();
    }
    ctx.strokeStyle=deep?'rgba(203,132,69,.095)':'rgba(181,166,111,.085)';ctx.lineWidth=3;ctx.lineCap='round';
    const bandStart=Math.floor(camera.y/310-1)*310;
    for(let y=bandStart;y<camera.y+viewHeight+310;y+=310){const drift=visualNoise(y/310,8,51)*65;ctx.beginPath();ctx.moveTo(camera.x-60,y+drift);ctx.bezierCurveTo(camera.x+viewWidth*.3,y-32+drift,camera.x+viewWidth*.7,y+38+drift,camera.x+viewWidth+60,y-4+drift);ctx.stroke()}
  }

  function drawRootwoundTerrainTexture(){
    const image=ROOTWOUND_ART.floor;if(!imageReady(image))return false;
    const pattern=ROOTWOUND_ART.floorPattern||(typeof ctx.createPattern==='function'?ctx.createPattern(image,'repeat'):null);if(!pattern)return false;
    ROOTWOUND_ART.floorPattern=pattern;ctx.save();ctx.translate(-camera.x,-camera.y);ctx.globalAlpha=.46;ctx.fillStyle=pattern;ctx.fillRect(camera.x-64,camera.y-64,viewWidth+128,viewHeight+128);ctx.globalAlpha=1;ctx.fillStyle='rgba(18,10,7,.48)';ctx.fillRect(camera.x-64,camera.y-64,viewWidth+128,viewHeight+128);ctx.restore();return true;
  }

  function cutMossveinCorner(x,y,corner,deep){
    const size=12;ctx.fillStyle=deep?'#1b1612':'#1a231b';ctx.beginPath();
    if(corner==='tl'){ctx.moveTo(x,y);ctx.lineTo(x+size,y);ctx.quadraticCurveTo(x+3,y+3,x,y+size)}
    else if(corner==='tr'){ctx.moveTo(x+MINE_TILE_SIZE,y);ctx.lineTo(x+MINE_TILE_SIZE-size,y);ctx.quadraticCurveTo(x+MINE_TILE_SIZE-3,y+3,x+MINE_TILE_SIZE,y+size)}
    else if(corner==='br'){ctx.moveTo(x+MINE_TILE_SIZE,y+MINE_TILE_SIZE);ctx.lineTo(x+MINE_TILE_SIZE-size,y+MINE_TILE_SIZE);ctx.quadraticCurveTo(x+MINE_TILE_SIZE-3,y+MINE_TILE_SIZE-3,x+MINE_TILE_SIZE,y+MINE_TILE_SIZE-size)}
    else{ctx.moveTo(x,y+MINE_TILE_SIZE);ctx.lineTo(x+size,y+MINE_TILE_SIZE);ctx.quadraticCurveTo(x+3,y+MINE_TILE_SIZE-3,x,y+MINE_TILE_SIZE-size)}
    ctx.closePath();ctx.fill();
  }

  function drawMossveinEdge(x,y,side,noise,deep,edgeColor=null,detailColor=null){
    const bend=(noise-.5)*12;ctx.beginPath();
    if(side==='top'){ctx.moveTo(x-3,y+1);ctx.quadraticCurveTo(x+MINE_TILE_SIZE*.5,y+bend,x+MINE_TILE_SIZE+3,y+1)}
    else if(side==='right'){ctx.moveTo(x+MINE_TILE_SIZE-1,y-3);ctx.quadraticCurveTo(x+MINE_TILE_SIZE+bend,y+MINE_TILE_SIZE*.5,x+MINE_TILE_SIZE-1,y+MINE_TILE_SIZE+3)}
    else if(side==='bottom'){ctx.moveTo(x+MINE_TILE_SIZE+3,y+MINE_TILE_SIZE-1);ctx.quadraticCurveTo(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE-bend,x-3,y+MINE_TILE_SIZE-1)}
    else{ctx.moveTo(x+1,y+MINE_TILE_SIZE+3);ctx.quadraticCurveTo(x-bend,y+MINE_TILE_SIZE*.5,x+1,y-3)}
    ctx.lineCap='round';ctx.lineJoin='round';ctx.strokeStyle='rgba(0,2,1,.82)';ctx.lineWidth=19;ctx.stroke();
    ctx.strokeStyle=edgeColor?colorWithAlpha(edgeColor,.86):deep?'rgba(112,73,46,.86)':'rgba(65,76,62,.86)';ctx.lineWidth=4.5;ctx.stroke();
    ctx.strokeStyle=detailColor?colorWithAlpha(detailColor,.34):deep?'rgba(225,157,91,.28)':'rgba(190,184,132,.25)';ctx.lineWidth=1.35;ctx.stroke();
  }

  function drawMossveinWallArt(terrain,concealed,visible,deep){
    const image=deep&&isRootwoundProduction()?ROOTWOUND_ART.wall:MOSSVEIN_ART.wall;if(!imageReady(image))return false;
    const placements=[],used=new Set();
    for(const cell of visible){
      if(!cell.actual)continue;
      const {col,row}=cell,open=[
        !mossveinVisualSolidAt(terrain,concealed,col,row-1),
        !mossveinVisualSolidAt(terrain,concealed,col+1,row),
        !mossveinVisualSolidAt(terrain,concealed,col,row+1),
        !mossveinVisualSolidAt(terrain,concealed,col-1,row)
      ];
      for(let side=0;side<4;side++){
        if(!open[side])continue;
        const key=side%2===0?side+':'+row+':'+Math.floor(col/2):side+':'+col+':'+Math.floor(row/2);
        if(used.has(key))continue;used.add(key);placements.push({col,row,side});
      }
    }
    ctx.save();ctx.beginPath();
    for(const cell of visible){if(!cell.actual)continue;const x=cell.col*MINE_TILE_SIZE-camera.x,y=cell.row*MINE_TILE_SIZE-camera.y;ctx.rect(x-10,y-10,MINE_TILE_SIZE+20,MINE_TILE_SIZE+20)}
    ctx.clip();ctx.globalAlpha=deep?1:.98;
    for(const item of placements){
      const n=visualNoise(item.col,item.row,181),rootwound=deep&&isRootwoundProduction(),width=rootwound?176+n*24:164+n*22,height=width*(image.naturalHeight/image.naturalWidth);
      let x=(item.col+.5)*MINE_TILE_SIZE-camera.x,y=(item.row+.5)*MINE_TILE_SIZE-camera.y,rotation=0;
      if(item.side===0){y-=MINE_TILE_SIZE*.36;rotation=Math.PI}
      else if(item.side===1){x+=MINE_TILE_SIZE*.36;rotation=-Math.PI*.5}
      else if(item.side===2){y+=MINE_TILE_SIZE*.36}
      else{x-=MINE_TILE_SIZE*.36;rotation=Math.PI*.5}
      ctx.save();ctx.translate(x,y);ctx.rotate(rotation+(n-.5)*.05);if(n>.52)ctx.scale(-1,1);ctx.drawImage(image,-width*.5,-height*.48,width,height);ctx.restore();
    }
    ctx.restore();return true;
  }

  function drawMossveinDamage(x,y,damage,noise){
    if(damage<=0)return;const stage=Math.max(1,Math.min(3,Math.ceil(damage*3))),cx=x+MINE_TILE_SIZE*.5,cy=y+MINE_TILE_SIZE*.5;
    ctx.strokeStyle='#17130e';ctx.globalAlpha=.62+.1*stage;ctx.lineWidth=1.5+stage*.75;ctx.lineCap='round';ctx.beginPath();
    ctx.moveTo(cx,cy);ctx.lineTo(x+7+noise*9,y+5);ctx.moveTo(cx,cy);ctx.lineTo(x+MINE_TILE_SIZE-6,y+12+noise*12);
    if(stage>=2){ctx.moveTo(cx,cy);ctx.lineTo(x+11,y+MINE_TILE_SIZE-5);ctx.moveTo(cx-2,cy-2);ctx.lineTo(x+5,y+25)}
    if(stage>=3){ctx.moveTo(cx,cy);ctx.lineTo(x+MINE_TILE_SIZE-5,y+MINE_TILE_SIZE-6);ctx.moveTo(cx+6,cy+4);ctx.lineTo(x+MINE_TILE_SIZE-3,y+30)}ctx.stroke();ctx.globalAlpha=1;
  }

  function drawMossveinTarget(x,y){
    const pulse=.5+.5*Math.sin(time*5);ctx.save();ctx.translate(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE*.5);
    ctx.strokeStyle='#f1ca73';ctx.lineWidth=2.2;ctx.lineCap='round';ctx.shadowBlur=8+5*pulse;ctx.shadowColor='#e4b75d';ctx.globalAlpha=.58+.28*pulse;
    ctx.beginPath();ctx.moveTo(-13,-5);ctx.lineTo(-4,-10);ctx.lineTo(2,-2);ctx.lineTo(12,-8);ctx.moveTo(-5,12);ctx.lineTo(1,3);ctx.lineTo(11,7);ctx.stroke();ctx.restore();
  }

  function drawMossveinMineralHint(x,y,side,rock){
    const rootwoundImage=isRootwoundProduction()?(rock.type==='rootiron'&&imageReady(ROOTWOUND_ART.rootironWall)?ROOTWOUND_ART.rootironWall:ROOTWOUND_ART.nodes[rock.type]):null;
    if(imageReady(rootwoundImage)){
      ctx.save();ctx.translate(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE*.5);ctx.rotate(side*Math.PI*.5);
      ctx.beginPath();ctx.rect(-MINE_TILE_SIZE*.5,-MINE_TILE_SIZE*.5,MINE_TILE_SIZE,MINE_TILE_SIZE);ctx.clip();
      const maxHeight=rock.type==='rootiron'?74:58,scale=maxHeight/rootwoundImage.naturalHeight,width=rootwoundImage.naturalWidth*scale,height=rootwoundImage.naturalHeight*scale;
      ctx.drawImage(rootwoundImage,-width*.5,-MINE_TILE_SIZE*.58,width,height);ctx.restore();return;
    }
    const production=MINERAL_ART[rock.type];
    if(production&&production.wall){
      const image=production.wall;if(imageReady(image)){
        ctx.save();ctx.translate(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE*.5);ctx.rotate(side*Math.PI*.5);
        ctx.beginPath();ctx.rect(-MINE_TILE_SIZE*.5,-MINE_TILE_SIZE*.5,MINE_TILE_SIZE,MINE_TILE_SIZE);ctx.clip();ctx.globalAlpha=.88;
        const width=20,height=31;ctx.drawImage(image,-width*.5,-MINE_TILE_SIZE*.5,width,height);ctx.restore();
      }
      return;
    }
    const data=ROCK_TYPES[rock.type],rare=!!data.rare,seed=visualNoise(rock.id,side,211),bend=(seed-.5)*5;
    ctx.save();ctx.translate(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE*.5);ctx.rotate(side*Math.PI*.5);ctx.scale(.8,.8);
    ctx.lineCap='round';ctx.lineJoin='round';ctx.beginPath();
    ctx.moveTo(-17,-24);ctx.bezierCurveTo(-15+bend,-20,-12,-15,-7,-13);ctx.bezierCurveTo(-2,-11,0,-7,6,-6);ctx.quadraticCurveTo(10,-5,14,-1);
    ctx.moveTo(-8,-13);ctx.quadraticCurveTo(-3,-19,4+bend*.4,-19);ctx.moveTo(3,-7);ctx.quadraticCurveTo(8,-12,14,-10+bend*.25);
    ctx.strokeStyle='rgba(3,5,4,.92)';ctx.lineWidth=rare?8:7;ctx.stroke();
    ctx.strokeStyle=data.edge;ctx.lineWidth=rare?3.2:2.65;ctx.shadowColor=data.edge;ctx.shadowBlur=rare?7:3;ctx.globalAlpha=rare?.78:.66;ctx.stroke();ctx.shadowBlur=0;
    const pockets=[[-14,-21,4.2],[-8,-14,3.5],[-1,-10,4.4],[5,-7,3.4],[4,-18,3.2],[12,-9,2.8]];
    for(let chip=0;chip<pockets.length;chip++){
      const pocket=pockets[chip],noise=visualNoise(rock.id+chip*19,side,227),size=pocket[2]*(.82+noise*.38);
      ctx.save();ctx.translate(pocket[0]+(noise-.5)*3,pocket[1]+(visualNoise(chip,rock.id,229)-.5)*2);ctx.rotate((noise-.5)*1.1);
      ctx.fillStyle=data.accent;ctx.strokeStyle=data.edge;ctx.lineWidth=rare?1.55:1.15;ctx.globalAlpha=rare?.86:.7;
      ctx.beginPath();ctx.moveTo(-size*.75,-size*.42);ctx.lineTo(-size*.12,-size);ctx.lineTo(size*.82,-size*.28);ctx.lineTo(size*.62,size*.68);ctx.lineTo(-size*.38,size*.88);ctx.lineTo(-size,size*.15);ctx.closePath();ctx.fill();ctx.stroke();
      ctx.strokeStyle=data.edge;ctx.globalAlpha=.58;ctx.lineWidth=.8;ctx.beginPath();ctx.moveTo(-size*.18,-size*.72);ctx.lineTo(size*.18,size*.48);ctx.stroke();ctx.restore();
    }
    ctx.restore();
  }

  function drawMossveinTerrain(mine,terrain,startCol,endCol,startRow,endRow,target){
    const deep=currentDepth===2,concealed=mossveinConcealedCells(terrain),visible=[];
    for(let row=startRow;row<=endRow;row++)for(let col=startCol;col<=endCol;col++){
      const index=row*terrain.cols+col;if(mossveinVisualSolidAt(terrain,concealed,col,row))visible.push({index,col,row,actual:!!terrainTypeAt(terrain,col,row)});
    }
    ctx.save();ctx.fillStyle=deep?'#211710':'#171b17';ctx.beginPath();
    for(const cell of visible){const x=cell.col*MINE_TILE_SIZE-camera.x,y=cell.row*MINE_TILE_SIZE-camera.y;ctx.rect(x-.7,y-.7,MINE_TILE_SIZE+1.4,MINE_TILE_SIZE+1.4)}
    ctx.fill();ctx.clip();if(!(deep&&isRootwoundProduction()&&drawRootwoundTerrainTexture()))drawMossveinTerrainTexture(deep);ctx.restore();
    for(const cell of visible){
      if(!cell.actual)continue;
      const {index,col,row}=cell,x=col*MINE_TILE_SIZE-camera.x,y=row*MINE_TILE_SIZE-camera.y;
      const top=!mossveinVisualSolidAt(terrain,concealed,col,row-1),right=!mossveinVisualSolidAt(terrain,concealed,col+1,row),bottom=!mossveinVisualSolidAt(terrain,concealed,col,row+1),left=!mossveinVisualSolidAt(terrain,concealed,col-1,row);
      if(top&&left)cutMossveinCorner(x,y,'tl',deep);if(top&&right)cutMossveinCorner(x,y,'tr',deep);if(bottom&&right)cutMossveinCorner(x,y,'br',deep);if(bottom&&left)cutMossveinCorner(x,y,'bl',deep);
      const noise=visualNoise(col,row,deep?67:61);if(top)drawMossveinEdge(x,y,'top',noise,deep);if(right)drawMossveinEdge(x,y,'right',1-noise,deep);if(bottom)drawMossveinEdge(x,y,'bottom',visualNoise(row,col,71),deep);if(left)drawMossveinEdge(x,y,'left',visualNoise(row,col,73),deep);
      drawMossveinDamage(x,y,1-terrainHpAt(terrain,col,row)/terrain.maxHp,noise);
      if(miningFeedback.terrainHitIndex===index&&miningFeedback.terrainHitTime>0){ctx.globalAlpha=miningFeedback.terrainHitTime/.16*.18;ctx.fillStyle=mine.wallEdge;ctx.fillRect(x+2,y+2,MINE_TILE_SIZE-4,MINE_TILE_SIZE-4);ctx.globalAlpha=1}
      if(target&&target.index===index)drawMossveinTarget(x,y);
    }
    drawMossveinWallArt(terrain,concealed,visible,deep);
    for(const cell of visible){
      if(!cell.actual)continue;const hint=mineralHintAtTerrainCell(terrain,concealed,cell.col,cell.row);if(!hint)continue;
      const x=cell.col*MINE_TILE_SIZE-camera.x,y=cell.row*MINE_TILE_SIZE-camera.y;
      for(const side of hint.sides)drawMossveinMineralHint(x,y,side,hint.rock);
    }
  }

  function drawUnbreakableSolidWall(wall,p){
    const productionImage=UNBREAKABLE_WALL_ART[currentScene],fallbackImage=currentScene==='mossMine'?MOSSVEIN_ART.wall:(activeMineProductionArt()&&activeMineProductionArt().wall),image=imageReady(productionImage)?productionImage:fallbackImage;if(!imageReady(image))return;
    const horizontal=wall.w>=wall.h,segmentLong=horizontal?248:238,segmentShort=segmentLong*(image.naturalHeight/image.naturalWidth),longStep=segmentLong*.74,shortStep=segmentShort*.62;
    ctx.save();ctx.translate(p.x,p.y);ctx.beginPath();ctx.rect(0,0,wall.w,wall.h);ctx.clip();
    if(horizontal){
      let row=0;for(let y=-segmentShort*.12;y<wall.h+segmentShort;y+=shortStep,row++)for(let x=-segmentLong*.38-(row%2)*longStep*.5;x<wall.w+segmentLong;x+=longStep){ctx.save();ctx.translate(x+segmentLong*.5,y+segmentShort*.5);if((row+Math.round(x/longStep))%2)ctx.scale(-1,1);ctx.drawImage(image,-segmentLong*.5,-segmentShort*.5,segmentLong,segmentShort);ctx.restore()}
    }else{
      let column=0;for(let x=-segmentShort*.12;x<wall.w+segmentShort;x+=shortStep,column++)for(let y=-segmentLong*.38-(column%2)*longStep*.5;y<wall.h+segmentLong;y+=longStep){ctx.save();ctx.translate(x+segmentShort*.5,y+segmentLong*.5);ctx.rotate(Math.PI*.5);if((column+Math.round(y/longStep))%2)ctx.scale(-1,1);ctx.drawImage(image,-segmentLong*.5,-segmentShort*.5,segmentLong,segmentShort);ctx.restore()}
    }
    ctx.restore();
  }

  function productionFloorPattern(art){
    if(!art||!imageReady(art.floor))return null;
    if(!art.floorPattern&&typeof ctx.createPattern==='function')art.floorPattern=ctx.createPattern(art.floor,'repeat');
    return art.floorPattern;
  }

  function productionFloorOverlay(){
    if(currentScene==='starMine')return currentDepth===2?'rgba(12,4,27,.2)':'rgba(11,8,34,.1)';
    if(currentScene==='emberMine')return currentDepth===2?'rgba(30,5,2,.22)':'rgba(31,8,5,.1)';
    return currentDepth===2?'rgba(7,7,19,.24)':'rgba(5,16,20,.12)';
  }

  function productionTerrainOverlay(){
    if(currentScene==='starMine')return currentDepth===2?'rgba(12,5,30,.55)':'rgba(12,9,39,.49)';
    if(currentScene==='emberMine')return currentDepth===2?'rgba(38,8,3,.51)':'rgba(46,14,8,.47)';
    return isPrismaticProduction()?'rgba(8,5,24,.57)':'rgba(4,22,29,.52)';
  }

  function productionRouteMarkers(){
    if(currentScene==='starMine')return[[310,750,0],[610,750,0],[900,725,0],[1260,725,0],[1650,460,-.38],[1950,460,0]];
    if(currentScene==='emberMine')return[[310,1025,0],[555,630,-.55],[820,675,.06],[1080,680,-.18],[1265,455,-.4],[1545,455,0],[1705,970,.58]];
    return[[350,1180,0],[535,700,-.62],[790,700,0],[1055,500,-.38],[1320,350,-.2],[1530,350,0]];
  }

  function drawMoonProductionFloor(mine){
    const art=activeMineProductionArt(),pattern=productionFloorPattern(art),deep=currentDepth===2;
    ctx.fillStyle=mine.floor;ctx.fillRect(0,0,mine.width,mine.height);
    if(pattern){ctx.save();ctx.fillStyle=pattern;ctx.globalAlpha=deep?.92:.96;ctx.fillRect(0,0,mine.width,mine.height);ctx.globalAlpha=1;ctx.fillStyle=productionFloorOverlay();ctx.fillRect(0,0,mine.width,mine.height);ctx.restore()}
    else if(art&&imageReady(art.floor)){const tileX=Math.floor(camera.x/art.floor.naturalWidth)*art.floor.naturalWidth,tileY=Math.floor(camera.y/art.floor.naturalHeight)*art.floor.naturalHeight;ctx.drawImage(art.floor,tileX,tileY,art.floor.naturalWidth,art.floor.naturalHeight)}
    if(!deep&&imageReady(art.routeMarker)){
      const route=productionRouteMarkers();
      for(const [x,y,rotation] of route){const width=108,height=width*(art.routeMarker.naturalHeight/art.routeMarker.naturalWidth);ctx.save();ctx.translate(x,y);ctx.rotate(rotation);ctx.globalAlpha=.9;ctx.drawImage(art.routeMarker,-width*.5,-height*.5,width,height);ctx.restore()}
    }
  }

  function moonProductionWallHintImage(rock){
    const art=activeMineProductionArt();return art&&art.wallHints?art.wallHints[rock.type]||null:null;
  }

  function drawMoonProductionWallHint(x,y,side,rock){
    const image=moonProductionWallHintImage(rock);if(!imageReady(image)){drawMossveinMineralHint(x,y,side,rock);return}
    ctx.save();ctx.translate(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE*.5);ctx.rotate(side*Math.PI*.5);
    ctx.beginPath();ctx.rect(-MINE_TILE_SIZE*.5,-MINE_TILE_SIZE*.5,MINE_TILE_SIZE,MINE_TILE_SIZE);ctx.clip();
    const maxHeight=['lunacore','phasecrystal','starshard','crownstone','singularity'].includes(rock.type)?76:70,scale=maxHeight/image.naturalHeight,width=image.naturalWidth*scale,height=image.naturalHeight*scale;
    ctx.drawImage(image,-width*.5,-MINE_TILE_SIZE*.59,width,height);ctx.restore();
  }

  function drawMoonProductionWallArt(terrain,concealed,visible,art){
    const image=art&&art.wall;if(!imageReady(image))return false;
    const placements=[],used=new Set();
    for(const cell of visible){
      if(!cell.actual)continue;const {col,row}=cell,open=[!mossveinVisualSolidAt(terrain,concealed,col,row-1),!mossveinVisualSolidAt(terrain,concealed,col+1,row),!mossveinVisualSolidAt(terrain,concealed,col,row+1),!mossveinVisualSolidAt(terrain,concealed,col-1,row)];
      for(let side=0;side<4;side++){if(!open[side])continue;const key=side%2===0?side+':'+row+':'+Math.floor(col/2):side+':'+col+':'+Math.floor(row/2);if(used.has(key))continue;used.add(key);placements.push({col,row,side})}
    }
    ctx.save();ctx.beginPath();for(const cell of visible){if(!cell.actual)continue;ctx.rect(cell.col*MINE_TILE_SIZE-camera.x-10,cell.row*MINE_TILE_SIZE-camera.y-10,MINE_TILE_SIZE+20,MINE_TILE_SIZE+20)}ctx.clip();
    for(const item of placements){
      const salt=currentScene==='starMine'?(currentDepth===2?419:397):currentScene==='emberMine'?(currentDepth===2?359:337):(isPrismaticProduction()?307:281),n=visualNoise(item.col,item.row,salt),width=174+n*26,height=width*(image.naturalHeight/image.naturalWidth);let x=(item.col+.5)*MINE_TILE_SIZE-camera.x,y=(item.row+.5)*MINE_TILE_SIZE-camera.y,rotation=0;
      if(item.side===0){y-=MINE_TILE_SIZE*.36;rotation=Math.PI}else if(item.side===1){x+=MINE_TILE_SIZE*.36;rotation=-Math.PI*.5}else if(item.side===2)y+=MINE_TILE_SIZE*.36;else{x-=MINE_TILE_SIZE*.36;rotation=Math.PI*.5}
      ctx.save();ctx.translate(x,y);ctx.rotate(rotation+(n-.5)*.045);if(n>.53)ctx.scale(-1,1);ctx.drawImage(image,-width*.5,-height*.48,width,height);ctx.restore();
    }
    ctx.restore();return true;
  }

  function drawMoonProductionTarget(x,y,color){
    const pulse=.5+.5*Math.sin(time*5);ctx.save();ctx.translate(x+MINE_TILE_SIZE*.5,y+MINE_TILE_SIZE*.5);ctx.strokeStyle=color;ctx.lineWidth=2.2;ctx.lineCap='round';ctx.shadowBlur=8+5*pulse;ctx.shadowColor=color;ctx.globalAlpha=.58+.28*pulse;
    ctx.beginPath();ctx.moveTo(-13,-5);ctx.lineTo(-4,-10);ctx.lineTo(2,-2);ctx.lineTo(12,-8);ctx.moveTo(-5,12);ctx.lineTo(1,3);ctx.lineTo(11,7);ctx.stroke();ctx.restore();
  }

  function drawMoonProductionTerrain(mine,terrain,startCol,endCol,startRow,endRow,target){
    const art=activeMineProductionArt(),pattern=productionFloorPattern(art),concealed=mossveinConcealedCells(terrain),visible=[];
    for(let row=startRow;row<=endRow;row++)for(let col=startCol;col<=endCol;col++){const index=row*terrain.cols+col;if(mossveinVisualSolidAt(terrain,concealed,col,row))visible.push({index,col,row,actual:!!terrainTypeAt(terrain,col,row)})}
    ctx.save();ctx.fillStyle=mine.dirt||mine.wall;ctx.beginPath();for(const cell of visible)ctx.rect(cell.col*MINE_TILE_SIZE-camera.x-.7,cell.row*MINE_TILE_SIZE-camera.y-.7,MINE_TILE_SIZE+1.4,MINE_TILE_SIZE+1.4);ctx.fill();ctx.clip();
    if(pattern){ctx.save();ctx.translate(-camera.x,-camera.y);ctx.fillStyle=pattern;ctx.globalAlpha=currentDepth===2?.7:.76;ctx.fillRect(camera.x-64,camera.y-64,viewWidth+128,viewHeight+128);ctx.globalAlpha=1;ctx.fillStyle=productionTerrainOverlay();ctx.fillRect(camera.x-64,camera.y-64,viewWidth+128,viewHeight+128);ctx.restore()}ctx.restore();
    for(const cell of visible){
      if(!cell.actual)continue;const {index,col,row}=cell,x=col*MINE_TILE_SIZE-camera.x,y=row*MINE_TILE_SIZE-camera.y,noise=visualNoise(col,row,isPrismaticProduction()?293:271);
      drawMossveinDamage(x,y,1-terrainHpAt(terrain,col,row)/terrain.maxHp,noise);
      if(miningFeedback.terrainHitIndex===index&&miningFeedback.terrainHitTime>0){ctx.globalAlpha=miningFeedback.terrainHitTime/.16*.2;ctx.fillStyle=mine.wallEdge;ctx.fillRect(x+2,y+2,MINE_TILE_SIZE-4,MINE_TILE_SIZE-4);ctx.globalAlpha=1}
      if(target&&target.index===index)drawMoonProductionTarget(x,y,mine.detail);
    }
    drawMoonProductionWallArt(terrain,concealed,visible,art);
    for(const cell of visible){
      if(!cell.actual)continue;const x=cell.col*MINE_TILE_SIZE-camera.x,y=cell.row*MINE_TILE_SIZE-camera.y,noise=visualNoise(cell.col,cell.row,601),open=[!mossveinVisualSolidAt(terrain,concealed,cell.col,cell.row-1),!mossveinVisualSolidAt(terrain,concealed,cell.col+1,cell.row),!mossveinVisualSolidAt(terrain,concealed,cell.col,cell.row+1),!mossveinVisualSolidAt(terrain,concealed,cell.col-1,cell.row)];
      if(open[0])drawMossveinEdge(x,y,'top',noise,currentDepth===2,mine.wallEdge,mine.detail);if(open[1])drawMossveinEdge(x,y,'right',1-noise,currentDepth===2,mine.wallEdge,mine.detail);if(open[2])drawMossveinEdge(x,y,'bottom',visualNoise(cell.row,cell.col,607),currentDepth===2,mine.wallEdge,mine.detail);if(open[3])drawMossveinEdge(x,y,'left',visualNoise(cell.row,cell.col,613),currentDepth===2,mine.wallEdge,mine.detail);
    }
    for(const cell of visible){if(!cell.actual)continue;const hint=mineralHintAtTerrainCell(terrain,concealed,cell.col,cell.row);if(!hint)continue;const x=cell.col*MINE_TILE_SIZE-camera.x,y=cell.row*MINE_TILE_SIZE-camera.y;for(const side of hint.sides)drawMoonProductionWallHint(x,y,side,hint.rock)}
  }

  function drawMoonBarrier(barrier,p,locked){
    const art=activeMineProductionArt(),image=art&&art.barriers&&art.barriers[barrier.id],mine=currentMineVisual();if(!imageReady(image))return false;
    const height=barrier.h+28,width=height*(image.naturalWidth/image.naturalHeight);ctx.save();ctx.translate(p.x+barrier.w*.5,p.y+barrier.h*.5);ctx.fillStyle='rgba(0,0,0,.42)';ctx.beginPath();ctx.ellipse(0,barrier.h*.5-3,Math.min(92,width*.43),14,0,0,Math.PI*2);ctx.fill();ctx.globalAlpha=locked?1:.88;ctx.drawImage(image,-width*.5,-height*.5,width,height);ctx.globalAlpha=1;
    ctx.fillStyle='rgba(4,8,10,.9)';ctx.fillRect(-86,-barrier.h*.5-35,172,24);ctx.strokeStyle=locked?mine.accent:mine.detail;ctx.lineWidth=1;ctx.strokeRect(-86,-barrier.h*.5-35,172,24);ctx.fillStyle=locked?mine.detail:'#fff1cf';ctx.textAlign='center';ctx.font='900 9px Georgia';readableFillText(locked?PICKAXES[barrier.requiresPickaxe].name.toUpperCase()+' REQUIRED':'BREAK: '+barrier.label.toUpperCase(),0,-barrier.h*.5-19);ctx.restore();return true;
  }

  function drawMineGround(){
    const mine=currentMineVisual(),moonProduction=!!activeMineProductionArt();ctx.fillStyle=mine.floor;ctx.fillRect(0,0,viewWidth,viewHeight);
    const origin=worldToScreen(0,0);
    ctx.save();ctx.translate(origin.x,origin.y);
    if(isMossveinVisual(mine))drawMossveinFloorBase(mine);
    else if(moonProduction)drawMoonProductionFloor(mine);
    else{
      ctx.fillStyle=mine.floor;ctx.fillRect(0,0,mine.width,mine.height);
      const glowX=mine.width*.78,glowY=mine.height*.5,glow=ctx.createRadialGradient(glowX,glowY,40,glowX,glowY,Math.max(mine.width,mine.height)*.38);
      glow.addColorStop(0,mine.style==='ember'?'rgba(255,91,34,.18)':mine.style==='moon'?'rgba(92,226,225,.14)':mine.style==='star'?'rgba(163,145,255,.15)':'rgba(166,118,45,.17)');glow.addColorStop(1,'rgba(10,12,14,0)');ctx.fillStyle=glow;ctx.fillRect(0,0,mine.width,mine.height);
    }
    if(isMossveinVisual(mine)){if(!(isRootwoundProduction()&&imageReady(ROOTWOUND_ART.floor)))drawMossveinFloorDetail(mine)}
    else if(!moonProduction){
      ctx.strokeStyle=mine.style==='ember'?'rgba(255,127,69,.055)':mine.style==='star'?'rgba(190,195,255,.05)':mine.style==='moon'?'rgba(115,224,220,.055)':'rgba(198,174,112,.055)';ctx.lineWidth=1;
      for(let x=0;x<=mine.width;x+=80){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,mine.height);ctx.stroke()}
      for(let y=0;y<=mine.height;y+=80){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(mine.width,y);ctx.stroke()}
    }
    if(moonProduction){
      // The complete Moonglass/Prismatic floor and route are production PNGs.
    }else if(currentDepth===2&&!isRootwoundProduction()){
      ctx.strokeStyle=mine.wallEdge;ctx.globalAlpha=.12;ctx.lineWidth=5;
      for(let y=180;y<mine.height;y+=310){ctx.beginPath();ctx.moveTo(40,y);ctx.bezierCurveTo(mine.width*.28,y-70,mine.width*.68,y+75,mine.width-40,y-15);ctx.stroke()}
      ctx.globalAlpha=1;
    }else if(mine.style==='moss'){
      ctx.strokeStyle='#4a3e29';ctx.lineWidth=9;ctx.beginPath();ctx.moveTo(120,650);ctx.lineTo(1800,650);ctx.stroke();ctx.strokeStyle='#a07c43';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(120,641);ctx.lineTo(1800,641);ctx.moveTo(120,659);ctx.lineTo(1800,659);ctx.stroke();ctx.strokeStyle='#55452d';ctx.lineWidth=5;for(let x=140;x<1810;x+=54){ctx.beginPath();ctx.moveTo(x,628);ctx.lineTo(x,672);ctx.stroke()}
    }else if(mine.style==='moon'){
      drawMineRoute([[150,1180],[350,1180],[535,700],[790,700],[1055,500],[1320,350],[1530,350]],'#224e52','#6bc6c3');
      ctx.fillStyle='rgba(107,229,224,.22)';for(let i=0;i<20;i++){const x=90+(i*277)%1500,y=170+(i*193)%1080;ctx.beginPath();ctx.moveTo(x,y-18);ctx.lineTo(x+11,y+8);ctx.lineTo(x-8,y+15);ctx.closePath();ctx.fill()}
    }else if(mine.style==='ember'){
      drawMineRoute([[145,1030],[360,1030],[555,625],[710,625],[1080,680],[1265,450],[1560,450],[1710,980]],'#54261d','#d75b32');
      ctx.strokeStyle='rgba(255,91,35,.55)';ctx.lineWidth=5;for(let x=170;x<mine.width;x+=310){ctx.beginPath();ctx.moveTo(x,145);ctx.lineTo(x+90,mine.height-145);ctx.stroke()}
    }else{
      drawMineRoute([[160,750],[510,750],[900,725],[1260,725],[1650,460],[2020,460]],'#242650','#777fc1');
      ctx.fillStyle='rgba(224,226,255,.6)';for(let i=0;i<55;i++){const x=(i*173)%mine.width,y=(i*271)%mine.height,r=i%9===0?2:1;ctx.fillRect(x,y,r,r)}
    }
    for(const cavern of currentTerrain().caverns){
      if(!cavernIsDiscovered(cavern.id))continue;
      const screenX=origin.x+cavern.x,screenY=origin.y+cavern.y;if(screenX+cavern.rx<-50||screenY+cavern.ry<-50||screenX-cavern.rx>viewWidth+50||screenY-cavern.ry>viewHeight+50)continue;
      ctx.save();ctx.translate(cavern.x,cavern.y);
      const pocket=moonProduction?activeMineProductionArt().pocket:DISCOVERY_ART.crystalPocket,claimed=!!state.claimedPocketRewards[cavern.reward.id];let pocketHeight=Math.min(cavern.ry*1.72,cavern.rx*1.84*(pocket&&pocket.naturalHeight?pocket.naturalHeight/pocket.naturalWidth:.559));
      if(imageReady(pocket)){
        const pocketWidth=pocketHeight*(pocket.naturalWidth/pocket.naturalHeight);ctx.globalAlpha=claimed?.46:1;ctx.shadowColor=mine.detail;ctx.shadowBlur=claimed?4:13;ctx.drawImage(pocket,-pocketWidth/2,-pocketHeight/2,pocketWidth,pocketHeight);ctx.shadowBlur=0;
      }
      ctx.globalAlpha=1;const labelY=-pocketHeight/2-9;ctx.fillStyle='rgba(5,8,7,.84)';ctx.fillRect(-68,labelY-10,136,19);ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 9px Georgia';readableFillText(cavern.name.toUpperCase(),0,labelY+3);ctx.restore();
      drawPocketReward(cavern,origin);
    }
    ctx.restore();
  }

  function drawPocketReward(cavern,origin){
    const mine=currentMineVisual(),reward=cavern.reward,claimed=!!state.claimedPocketRewards[reward.id];
    if(reward.kind==='crystal'||reward.kind==='motherlode')return;
    const x=origin.x+cavern.x,y=origin.y+cavern.y+30;if(x<-70||y<-70||x>viewWidth+70||y>viewHeight+70)return;
    const moonArt=activeMineProductionArt(),production=moonArt?moonArt.rewards[reward.kind]:currentScene==='mossMine'&&MOSSVEIN_REWARD_ART[reward.kind];
    if(imageReady(production)){
      if(claimed)return;
      const maxWidth=reward.kind==='shrine'?120:94,maxHeight=reward.kind==='shrine'?118:76,scale=Math.min(maxWidth/production.naturalWidth,maxHeight/production.naturalHeight),width=production.naturalWidth*scale,height=production.naturalHeight*scale;
      ctx.save();ctx.translate(cavern.x,cavern.y+30);ctx.fillStyle='rgba(0,0,0,.34)';ctx.beginPath();ctx.ellipse(0,35,width*.36,10,0,0,Math.PI*2);ctx.fill();
      if(reward.kind==='shrine'){ctx.shadowColor=mine.detail;ctx.shadowBlur=12}
      ctx.drawImage(production,-width*.5,40-height,width,height);ctx.shadowBlur=0;ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText(reward.label,0,54);ctx.restore();return;
    }
    ctx.save();ctx.translate(cavern.x,cavern.y+30);ctx.globalAlpha=claimed?.34:1;
    if(reward.kind==='cache'){
      ctx.fillStyle=claimed?'#3d3327':'#765329';ctx.strokeStyle=claimed?'#75684e':'#e4bd65';ctx.lineWidth=2;ctx.fillRect(-20,-12,40,25);ctx.strokeRect(-20,-12,40,25);
      ctx.fillStyle=claimed?'#6f6249':'#d6aa4f';ctx.fillRect(-22,-15,44,8);ctx.fillStyle='#1b1710';ctx.fillRect(-3,-8,6,9);
    }else if(reward.kind==='shrine'){
      ctx.strokeStyle=mine.detail;ctx.lineWidth=3;ctx.beginPath();ctx.arc(0,0,20,0,Math.PI*2);ctx.stroke();ctx.beginPath();ctx.moveTo(0,-15);ctx.lineTo(7,0);ctx.lineTo(0,15);ctx.lineTo(-7,0);ctx.closePath();ctx.stroke();
    }else{
      ctx.strokeStyle=ROCK_TYPES[reward.type].edge;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,0,25,0,Math.PI*2);ctx.stroke();
    }
    if(!claimed){ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText(reward.label,0,31)}ctx.restore();
  }

  function drawMineRoute(points,edge,center){
    ctx.lineCap='round';ctx.lineJoin='round';ctx.strokeStyle=edge;ctx.lineWidth=72;ctx.beginPath();ctx.moveTo(points[0][0],points[0][1]);for(let i=1;i<points.length;i++)ctx.lineTo(points[i][0],points[i][1]);ctx.stroke();
    ctx.strokeStyle=center;ctx.globalAlpha=.38;ctx.lineWidth=3;ctx.stroke();ctx.globalAlpha=1;
  }

  function drawMineTerrainCell(mine,index,col,row,damage,targeted){
    const x=col*MINE_TILE_SIZE-camera.x,y=row*MINE_TILE_SIZE-camera.y,seed=(index*37+row*11)%29;
    ctx.fillStyle=mine.dirt||mine.wall;ctx.fillRect(x-.5,y-.5,MINE_TILE_SIZE+1,MINE_TILE_SIZE+1);
    ctx.strokeStyle=mine.wallEdge;ctx.globalAlpha=.28;ctx.lineWidth=1;ctx.beginPath();ctx.moveTo(x+4,y+13+seed%8);ctx.lineTo(x+18+seed%12,y+4);ctx.lineTo(x+MINE_TILE_SIZE-3,y+17+seed%11);ctx.lineTo(x+MINE_TILE_SIZE-9,y+MINE_TILE_SIZE-4);ctx.lineTo(x+9,y+MINE_TILE_SIZE-7);ctx.closePath();ctx.stroke();
    if(damage>0){
      const stage=Math.max(1,Math.min(3,Math.ceil(damage*3))),cx=x+MINE_TILE_SIZE*.5,cy=y+MINE_TILE_SIZE*.5,jitter=seed%7-3;
      ctx.globalAlpha=.52+.15*stage;ctx.strokeStyle='#11120f';ctx.lineWidth=1.2+stage*.7;ctx.lineCap='round';ctx.beginPath();
      ctx.moveTo(cx+jitter,cy);ctx.lineTo(x+8+seed%9,y+6);ctx.moveTo(cx+jitter,cy);ctx.lineTo(x+MINE_TILE_SIZE-7,y+13+seed%12);
      if(stage>=2){ctx.moveTo(cx,cy);ctx.lineTo(x+12,y+MINE_TILE_SIZE-5);ctx.moveTo(cx-4,cy-3);ctx.lineTo(x+7,y+22)}
      if(stage>=3){ctx.moveTo(cx,cy);ctx.lineTo(x+MINE_TILE_SIZE-8,y+MINE_TILE_SIZE-6);ctx.moveTo(cx+7,cy+5);ctx.lineTo(x+MINE_TILE_SIZE-5,y+30)}
      ctx.stroke();
    }
    if(miningFeedback.terrainHitIndex===index&&miningFeedback.terrainHitTime>0){ctx.globalAlpha=miningFeedback.terrainHitTime/.16*.28;ctx.fillStyle=mine.wallEdge;ctx.fillRect(x+1,y+1,MINE_TILE_SIZE-2,MINE_TILE_SIZE-2)}
    if(targeted){ctx.globalAlpha=.72;ctx.strokeStyle=mine.detail;ctx.lineWidth=3;ctx.strokeRect(x+3,y+3,MINE_TILE_SIZE-6,MINE_TILE_SIZE-6)}
    ctx.globalAlpha=1;
  }

  function drawMineTerrain(){
    const mine=currentMineVisual(),terrain=currentTerrain();if(!mine||!terrain)return;
    const startCol=Math.max(0,Math.floor(camera.x/MINE_TILE_SIZE)-1),endCol=Math.min(terrain.cols-1,Math.ceil((camera.x+viewWidth)/MINE_TILE_SIZE)+1);
    const startRow=Math.max(0,Math.floor(camera.y/MINE_TILE_SIZE)-1),endRow=Math.min(terrain.rows-1,Math.ceil((camera.y+viewHeight)/MINE_TILE_SIZE)+1);
    const target=nearestTerrainCell(MINING_RANGE);
    if(isMossveinVisual(mine)){drawMossveinTerrain(mine,terrain,startCol,endCol,startRow,endRow,target);return}
    if(activeMineProductionArt()){drawMoonProductionTerrain(mine,terrain,startCol,endCol,startRow,endRow,target);return}
    const concealed=mossveinConcealedCells(terrain),genericVisible=[];
    for(let row=startRow;row<=endRow;row++)for(let col=startCol;col<=endCol;col++){
      const index=row*terrain.cols+col,type=terrainTypeAt(terrain,col,row);if(!type)continue;
      drawMineTerrainCell(mine,index,col,row,1-terrainHpAt(terrain,col,row)/terrain.maxHp,target&&target.index===index);genericVisible.push({col,row});
    }
    for(const cell of genericVisible){const x=cell.col*MINE_TILE_SIZE-camera.x,y=cell.row*MINE_TILE_SIZE-camera.y,noise=visualNoise(cell.col,cell.row,619),open=[!mossveinVisualSolidAt(terrain,concealed,cell.col,cell.row-1),!mossveinVisualSolidAt(terrain,concealed,cell.col+1,cell.row),!mossveinVisualSolidAt(terrain,concealed,cell.col,cell.row+1),!mossveinVisualSolidAt(terrain,concealed,cell.col-1,cell.row)];if(open[0])drawMossveinEdge(x,y,'top',noise,currentDepth===2,mine.wallEdge,mine.detail);if(open[1])drawMossveinEdge(x,y,'right',1-noise,currentDepth===2,mine.wallEdge,mine.detail);if(open[2])drawMossveinEdge(x,y,'bottom',visualNoise(cell.row,cell.col,631),currentDepth===2,mine.wallEdge,mine.detail);if(open[3])drawMossveinEdge(x,y,'left',visualNoise(cell.row,cell.col,641),currentDepth===2,mine.wallEdge,mine.detail)}
    for(const cavern of terrain.caverns){
      if(cavernIsDiscovered(cavern.id))continue;
      for(const index of cavern.cells){
        const col=index%terrain.cols,row=Math.floor(index/terrain.cols);if(col<startCol||col>endCol||row<startRow||row>endRow)continue;
        drawMineTerrainCell(mine,index,col,row,0,false);
      }
    }
    if(terrain.depthEntrance&&!state.discoveredDepthEntrances[currentScene]){
      for(const index of terrain.depthEntrance.cells){
        const col=index%terrain.cols,row=Math.floor(index/terrain.cols);if(col<startCol||col>endCol||row<startRow||row>endRow)continue;
        drawMineTerrainCell(mine,index,col,row,0,false);
      }
    }
  }

  function drawMineWalls(){
    if(currentDepth===2)return;
    const mine=currentMine();
    for(const wall of mine.solids){
      const p=worldToScreen(wall.x,wall.y);if(p.x>viewWidth+60||p.y>viewHeight+60||p.x+wall.w< -60||p.y+wall.h< -60)continue;
      drawUnbreakableSolidWall(wall,p);
    }
    for(const barrier of mine.barriers){
      if(mineBarrierCleared(barrier.id))continue;
      const p=worldToScreen(barrier.x,barrier.y),locked=state.pickaxeLevel<barrier.requiresPickaxe;
      if(activeMineProductionArt()&&drawMoonBarrier(barrier,p,locked))continue;
      ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(10,12,9,.68)';ctx.fillRect(0,0,barrier.w,barrier.h);
      ctx.strokeStyle=locked?'#98784a':mine.accent;ctx.globalAlpha=.55;ctx.lineWidth=3;ctx.setLineDash([9,7]);ctx.strokeRect(5,5,barrier.w-10,barrier.h-10);ctx.setLineDash([]);ctx.globalAlpha=1;
      ctx.fillStyle='rgba(7,9,7,.88)';ctx.fillRect(-34,-32,barrier.w+68,24);ctx.strokeStyle='#7e673b';ctx.lineWidth=1;ctx.strokeRect(-34,-32,barrier.w+68,24);
      ctx.fillStyle=locked?'#cfb985':'#f0d58d';ctx.textAlign='center';ctx.font='900 9px Georgia';readableFillText(locked?PICKAXES[barrier.requiresPickaxe].name.toUpperCase()+' REQUIRED':'BREAK: '+barrier.label.toUpperCase(),barrier.w*.5,-16);ctx.restore();
    }
  }

  function drawSurfaceMineEntrances(){for(const scene of MINE_SCENES){const mine=MINE_DEFINITIONS[scene];if(mine.unlock(state))drawMineEntrance(true,mine)}}

  function drawDepthEntranceLamp(mine){
    const pulse=.94+Math.sin(time*3.2)*.04,image=MINE_ENTRANCE_ART.depthLamp,offset=DEPTH_LAMP_OFFSETS[currentScene]||DEPTH_LAMP_OFFSETS.default;ctx.save();ctx.translate(offset.x,offset.y);
    if(imageReady(image)){const scale=Math.min(84/image.naturalWidth,58/image.naturalHeight),width=image.naturalWidth*scale,height=image.naturalHeight*scale;ctx.globalAlpha=pulse;ctx.shadowColor='#ffd58a';ctx.shadowBlur=8;ctx.drawImage(image,-width*.5,-height*.5,width,height);ctx.restore();return}
    ctx.rotate(.16);
    ctx.strokeStyle='#6f654e';ctx.lineWidth=3;ctx.beginPath();ctx.arc(0,-7,10,Math.PI*1.06,Math.PI*1.94);ctx.stroke();
    ctx.fillStyle='#302d25';ctx.strokeStyle='#9b8b66';ctx.lineWidth=2;ctx.beginPath();ctx.roundRect(-12,-7,24,27,6);ctx.fill();ctx.stroke();
    ctx.fillStyle='#ffd98b';ctx.shadowColor='#ffd58a';ctx.shadowBlur=15;ctx.globalAlpha=pulse;ctx.beginPath();ctx.roundRect(-7,-2,14,15,4);ctx.fill();ctx.shadowBlur=0;ctx.globalAlpha=1;
    ctx.fillStyle=mine.wallEdge;ctx.fillRect(-10,17,20,5);ctx.restore();
  }

  function drawDepthEntrance(){
    const entrance=depthEntrances[currentScene],mine=currentMineVisual(),p=worldToScreen(entrance.x,entrance.y),selected=activeContext===(currentDepth===2?'depthExit':'depthEntrance');
    if(p.x<-110||p.y<-110||p.x>viewWidth+110||p.y>viewHeight+110)return;
    const production=currentScene==='mossMine'?ROOTWOUND_ART.shaft:currentScene==='moonMine'?PRISMATIC_ART.shaft:currentScene==='emberMine'?MOLTEN_ART.shaft:currentScene==='starMine'?VOIDSTAR_ART.shaft:null;
    if(imageReady(production)){
      const maxWidth=158,maxHeight=138,scale=Math.min(maxWidth/production.naturalWidth,maxHeight/production.naturalHeight),assetWidth=production.naturalWidth*scale,assetHeight=production.naturalHeight*scale;
      ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.4)';ctx.beginPath();ctx.ellipse(0,35,62,19,0,0,Math.PI*2);ctx.fill();ctx.drawImage(production,-assetWidth*.5,40-assetHeight,assetWidth,assetHeight);if(currentScene!=='emberMine'&&currentScene!=='starMine')drawDepthEntranceLamp(mine);
      ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 10px Georgia';readableFillText(currentDepth===2?'RETURN TO DEPTH 1':'DESCEND TO DEPTH 2',0,67);
      if(selected){ctx.strokeStyle=mine.detail;ctx.globalAlpha=.75;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,5,76+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke()}ctx.restore();return;
    }
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.72)';ctx.beginPath();ctx.ellipse(0,12,52,37,0,0,Math.PI*2);ctx.fill();
    ctx.strokeStyle=mine.wallEdge;ctx.lineWidth=5;ctx.beginPath();ctx.ellipse(0,12,54,39,0,0,Math.PI*2);ctx.stroke();
    ctx.strokeStyle='#b88b52';ctx.lineWidth=4;for(const x of [-18,18]){ctx.beginPath();ctx.moveTo(x,-23);ctx.lineTo(x,43);ctx.stroke()}
    ctx.lineWidth=3;for(let y=-14;y<=34;y+=12){ctx.beginPath();ctx.moveTo(-18,y);ctx.lineTo(18,y);ctx.stroke()}
    drawDepthEntranceLamp(mine);
    ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 10px Georgia';readableFillText(currentDepth===2?'RETURN TO DEPTH 1':'DESCEND TO DEPTH 2',0,69);
    if(selected){ctx.strokeStyle=mine.detail;ctx.globalAlpha=.75;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,10,70+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke()}
    ctx.restore();
  }

  function drawMineEntrance(surface,mine){
    const entrance=surface?mine.surfaceEntrance:mine.entrance,p=worldToScreen(entrance.x,entrance.y),selected=activeContext===(surface?'mineEntrance:'+mine.id:'mineExit');
    if(p.x<-120||p.y<-150||p.x>viewWidth+120||p.y>viewHeight+150)return;
    let emergence=1;
    const surfaceTransition=surface?(mine.id==='moonMine'?moonglassGateTransition:mine.id==='emberMine'?emberdeepGateTransition:mine.id==='starMine'?starfallGateTransition:null):null;
    if(surfaceTransition){
      const progress=clamp(surfaceTransition.elapsed/surfaceTransition.duration,0,1),sink=gateActivationPose(progress).sink,raw=clamp((sink-.42)/.58,0,1);emergence=raw*raw*(3-2*raw);
      if(emergence<=0)return;
    }
    ctx.save();ctx.translate(p.x,p.y+(1-emergence)*64);ctx.scale(.74+.26*emergence,.18+.82*emergence);ctx.globalAlpha=emergence;ctx.fillStyle='rgba(0,0,0,.38)';ctx.beginPath();ctx.ellipse(0,42,66,20,0,0,Math.PI*2);ctx.fill();
    const production=MINE_ENTRANCE_ART[mine.id];
    if(imageReady(production)){
      const maxWidth=174,maxHeight=148,scale=Math.min(maxWidth/production.naturalWidth,maxHeight/production.naturalHeight),assetWidth=production.naturalWidth*scale,assetHeight=production.naturalHeight*scale;
      ctx.save();if(surface&&mine.id==='emberMine')ctx.scale(-1,1);ctx.drawImage(production,-assetWidth*.5,45-assetHeight,assetWidth,assetHeight);ctx.restore();
      ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 10px Georgia';readableFillText(surface?mine.name:'RETURN TO '+mine.surfaceName.replace('MOSSVEIN ','').replace('MOONGLASS ','').replace('EMBERDEEP ','').replace('STARFALL ',''),0,65);
      if(selected){ctx.strokeStyle='#f0d58d';ctx.globalAlpha=.75;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,4,82+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke()}
      ctx.restore();return;
    }
    ctx.fillStyle='#34372d';ctx.strokeStyle='#80734f';ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(-58,39);ctx.lineTo(-49,-22);ctx.quadraticCurveTo(0,-86,49,-22);ctx.lineTo(58,39);ctx.closePath();ctx.fill();ctx.stroke();
    const darkness=ctx.createRadialGradient(0,6,5,0,6,48);darkness.addColorStop(0,'#030403');darkness.addColorStop(1,'#151711');ctx.fillStyle=darkness;ctx.beginPath();ctx.moveTo(-39,36);ctx.lineTo(-33,-15);ctx.quadraticCurveTo(0,-58,33,-15);ctx.lineTo(39,36);ctx.closePath();ctx.fill();
    ctx.strokeStyle='#9c7136';ctx.lineWidth=5;for(const x of [-34,34]){ctx.beginPath();ctx.moveTo(x,35);ctx.lineTo(x,-14);ctx.stroke()}ctx.beginPath();ctx.arc(0,-9,34,Math.PI,Math.PI*2);ctx.stroke();
    ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 10px Georgia';readableFillText(surface?mine.name:'RETURN TO '+mine.surfaceName.replace('MOSSVEIN ','').replace('MOONGLASS ','').replace('EMBERDEEP ','').replace('STARFALL ',''),0,61);
    if(selected){ctx.strokeStyle='#f0d58d';ctx.globalAlpha=.75;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,4,72+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke()}
    ctx.restore();
  }

  function drawSurfaceMoonglassGround(){
    const image=SURFACE_ART.moonglassGround;if(!imageReady(image))return false;
    const pattern=SURFACE_ART.moonglassGroundPattern||(typeof ctx.createPattern==='function'?ctx.createPattern(image,'repeat'):null);SURFACE_ART.moonglassGroundPattern=pattern;
    const blendStart=WORLD.gateX-MOONGLASS_SURFACE_BLEND,blendEnd=WORLD.gateX+MOONGLASS_SURFACE_BLEND,biomeEnd=WORLD.emberGateX+(imageReady(SURFACE_ART.emberdeepGround)?EMBERDEEP_SURFACE_BLEND:0),steps=48,stepWidth=(blendEnd-blendStart)/steps;
    ctx.save();ctx.translate(-camera.x,-camera.y);
    if(pattern){
      ctx.fillStyle=pattern;ctx.fillRect(blendEnd,0,biomeEnd-blendEnd,WORLD.height);
      for(let index=0;index<steps;index++){const raw=(index+.5)/steps,alpha=raw*raw*(3-2*raw);ctx.globalAlpha=alpha;ctx.fillRect(blendStart+index*stepWidth,0,stepWidth+1,WORLD.height)}
    }else ctx.drawImage(image,WORLD.gateX,0,WORLD.emberGateX-WORLD.gateX,WORLD.height);
    ctx.globalAlpha=1;ctx.fillStyle='rgba(4,26,31,.12)';ctx.fillRect(blendEnd,0,biomeEnd-blendEnd,WORLD.height);
    for(let index=0;index<steps;index++){const raw=(index+.5)/steps,alpha=raw*raw*(3-2*raw);ctx.globalAlpha=alpha*.12;ctx.fillStyle='#041a1f';ctx.fillRect(blendStart+index*stepWidth,0,stepWidth+1,WORLD.height)}
    ctx.restore();return true;
  }

  function drawSurfaceEmberdeepGround(){
    const image=SURFACE_ART.emberdeepGround;if(!imageReady(image))return false;
    const pattern=SURFACE_ART.emberdeepGroundPattern||(typeof ctx.createPattern==='function'?ctx.createPattern(image,'repeat'):null);SURFACE_ART.emberdeepGroundPattern=pattern;
    const blendStart=WORLD.emberGateX-EMBERDEEP_SURFACE_BLEND,blendEnd=WORLD.emberGateX+EMBERDEEP_SURFACE_BLEND,biomeEnd=WORLD.starfallGateX+(imageReady(SURFACE_ART.starfallGround)?STARFALL_SURFACE_BLEND:0),steps=48,stepWidth=(blendEnd-blendStart)/steps;
    ctx.save();ctx.translate(-camera.x,-camera.y);
    if(pattern){
      ctx.fillStyle=pattern;ctx.fillRect(blendEnd,0,biomeEnd-blendEnd,WORLD.height);
      for(let index=0;index<steps;index++){const raw=(index+.5)/steps,alpha=raw*raw*(3-2*raw);ctx.globalAlpha=alpha;ctx.fillRect(blendStart+index*stepWidth,0,stepWidth+1,WORLD.height)}
    }else ctx.drawImage(image,WORLD.emberGateX,0,WORLD.starfallGateX-WORLD.emberGateX,WORLD.height);
    ctx.globalAlpha=1;ctx.fillStyle='rgba(54,11,5,.13)';ctx.fillRect(blendEnd,0,biomeEnd-blendEnd,WORLD.height);
    for(let index=0;index<steps;index++){const raw=(index+.5)/steps,alpha=raw*raw*(3-2*raw);ctx.globalAlpha=alpha*.13;ctx.fillStyle='#360b05';ctx.fillRect(blendStart+index*stepWidth,0,stepWidth+1,WORLD.height)}
    ctx.restore();return true;
  }

  function drawSurfaceStarfallGround(){
    const image=SURFACE_ART.starfallGround;if(!imageReady(image))return false;
    const pattern=SURFACE_ART.starfallGroundPattern||(typeof ctx.createPattern==='function'?ctx.createPattern(image,'repeat'):null);SURFACE_ART.starfallGroundPattern=pattern;
    const blendStart=WORLD.starfallGateX-STARFALL_SURFACE_BLEND,blendEnd=WORLD.starfallGateX+STARFALL_SURFACE_BLEND,steps=48,stepWidth=(blendEnd-blendStart)/steps;
    ctx.save();ctx.translate(-camera.x,-camera.y);
    if(pattern){
      ctx.fillStyle=pattern;ctx.fillRect(blendEnd,0,WORLD.width-blendEnd,WORLD.height);
      for(let index=0;index<steps;index++){const raw=(index+.5)/steps,alpha=raw*raw*(3-2*raw);ctx.globalAlpha=alpha;ctx.fillRect(blendStart+index*stepWidth,0,stepWidth+1,WORLD.height)}
    }else ctx.drawImage(image,WORLD.starfallGateX,0,WORLD.width-WORLD.starfallGateX,WORLD.height);
    ctx.globalAlpha=1;ctx.fillStyle='rgba(19,10,48,.12)';ctx.fillRect(blendEnd,0,WORLD.width-blendEnd,WORLD.height);
    for(let index=0;index<steps;index++){const raw=(index+.5)/steps,alpha=raw*raw*(3-2*raw);ctx.globalAlpha=alpha*.12;ctx.fillStyle='#130a30';ctx.fillRect(blendStart+index*stepWidth,0,stepWidth+1,WORLD.height)}
    ctx.restore();return true;
  }

  function drawSurfaceProductionAt(image,x,y,maxWidth,maxHeight,flip=false,alpha=1){
    if(!imageReady(image))return;const p=worldToScreen(x,y);if(p.x<-maxWidth||p.y<-maxHeight||p.x>viewWidth+maxWidth||p.y>viewHeight+maxHeight)return;
    const scale=Math.min(maxWidth/image.naturalWidth,maxHeight/image.naturalHeight),width=image.naturalWidth*scale,height=image.naturalHeight*scale;ctx.save();ctx.translate(p.x,p.y);if(flip)ctx.scale(-1,1);ctx.globalAlpha=alpha;ctx.drawImage(image,-width*.5,-height,width,height);ctx.restore();
  }

  function drawMoonglassSurfaceProductionDecor(){
    if(!imageReady(SURFACE_ART.moonglassGround))return;
    const clusters=[[1185,220,112,48,false,.48],[1435,185,118,50,true,.5],[1775,210,122,52,false,.46],[2110,330,114,48,true,.48],[1415,1235,118,50,true,.44],[1885,1170,124,52,false,.46],[2160,930,112,48,false,.44]];
    for(const [x,y,w,h,flip,alpha] of clusters)drawSurfaceProductionAt(SURFACE_ART.moonglassCrystals,x,y,w,h,flip,alpha);
    drawSurfaceProductionAt(SURFACE_ART.moonglassBloomBed,1665,572,286,126,false,.96);
  }

  function drawEmberdeepSurfaceProductionDecor(){
    if(!imageReady(SURFACE_ART.emberdeepGround))return;
    const clusters=[[2325,230,118,58,false,.45],[2670,185,126,62,true,.48],[3015,290,120,60,false,.43],[3270,515,132,64,true,.46],[2350,1190,124,62,true,.42],[3120,1180,130,64,false,.44]];
    for(const [x,y,w,h,flip,alpha] of clusters)drawSurfaceProductionAt(SURFACE_ART.emberdeepSlag,x,y,w,h,flip,alpha);
    drawSurfaceProductionAt(SURFACE_ART.emberdeepFaultBed,3078,1015,350,154,false,.98);
  }

  function drawStarfallSurfaceProductionDecor(){
    if(!imageReady(SURFACE_ART.starfallGround))return;
    const clusters=[[3415,210,122,62,false,.48],[3650,180,132,66,true,.5],[3980,280,126,63,false,.46],[4325,510,136,68,true,.48],[3480,1190,124,62,true,.44],[4230,1170,134,67,false,.46]];
    for(const [x,y,w,h,flip,alpha] of clusters)drawSurfaceProductionAt(SURFACE_ART.starfallShards,x,y,w,h,flip,alpha);
  }

  function drawStarfallLatticeBed(){
    if(!imageReady(SURFACE_ART.starfallGround))return;
    // Scale the bed from its socket centers, not its transparent canvas, so the
    // three timed Astralite nodes sit inside the painted lattice pockets. This
    // pass stays below the road so its upper edge is naturally masked by the
    // untouched Starfall main-road asset.
    drawSurfaceProductionAt(SURFACE_ART.starfallLatticeBed,3810,1038,568,249,false,.98);
  }

  function drawMossveinMineApproach(){
    const image=SURFACE_ART.mossveinMinePath;if(!imageReady(image))return;
    const topLeft=worldToScreen(125,728),width=700,height=200;if(topLeft.x>viewWidth||topLeft.y>viewHeight||topLeft.x+width<0||topLeft.y+height<0)return;
    ctx.drawImage(image,topLeft.x,topLeft.y,width,height);
  }

  function drawEmberdeepMineApproach(){
    const image=SURFACE_ART.emberdeepMinePath;if(!imageReady(image))return;
    const topLeft=worldToScreen(EMBERDEEP_MINE_PATH_BOUNDS.x,EMBERDEEP_MINE_PATH_BOUNDS.y),width=EMBERDEEP_MINE_PATH_BOUNDS.w,height=EMBERDEEP_MINE_PATH_BOUNDS.h;if(topLeft.x>viewWidth||topLeft.y>viewHeight||topLeft.x+width<0||topLeft.y+height<0)return;
    const pivot=worldToScreen(EMBERDEEP_MINE_PATH_PIVOT.x,EMBERDEEP_MINE_PATH_PIVOT.y);
    ctx.save();ctx.translate(pivot.x,pivot.y);ctx.rotate(EMBERDEEP_MINE_PATH_ROTATION);ctx.translate(topLeft.x+width-pivot.x,topLeft.y-pivot.y);ctx.scale(-1,1);ctx.drawImage(image,0,0,width,height);ctx.restore();
  }

  function drawStarfallMineApproach(){
    const image=SURFACE_ART.starfallMinePath;if(!imageReady(image))return;
    const topLeft=worldToScreen(STARFALL_MINE_PATH_BOUNDS.x,STARFALL_MINE_PATH_BOUNDS.y),width=STARFALL_MINE_PATH_BOUNDS.w,height=STARFALL_MINE_PATH_BOUNDS.h;
    if(topLeft.x>viewWidth||topLeft.y>viewHeight||topLeft.x+width<0||topLeft.y+height<0)return;
    ctx.drawImage(image,topLeft.x,topLeft.y,width,height);
  }

  function drawSurfaceRoadImage(image,x,flip,clipLeft=-Infinity,clipRight=Infinity,alpha=1){
    if(!imageReady(image))return;const y=590,width=1190,height=300,p=worldToScreen(x,y);
    if(p.x>viewWidth+width||p.x+width<0||p.y>viewHeight+height||p.y+height<0)return;
    ctx.save();
    if(Number.isFinite(clipLeft)||Number.isFinite(clipRight)){const left=Number.isFinite(clipLeft)?worldToScreen(clipLeft,0).x:-width,right=Number.isFinite(clipRight)?worldToScreen(clipRight,0).x:viewWidth+width;ctx.beginPath();ctx.rect(left,-height,right-left,viewHeight+height*2);ctx.clip()}
    ctx.globalAlpha=alpha;
    if(flip){ctx.translate(p.x+width,p.y);ctx.scale(-1,1);ctx.drawImage(image,0,0,width,height)}else ctx.drawImage(image,p.x,p.y,width,height);
    ctx.restore();
  }

  function drawSurfaceMainRoad(){
    const definitions=[
      {biome:'mossvein',x:-40,flip:false,boundary:null},
      {biome:'moonglass',x:1070,flip:true,boundary:WORLD.gateX},
      {biome:'emberdeep',x:2200,flip:false,boundary:WORLD.emberGateX},
      {biome:'starfall',x:3320,flip:true,boundary:WORLD.starfallGateX}
    ];
    if(!definitions.every(item=>imageReady(SURFACE_ART.roads[item.biome])))return;
    drawSurfaceRoadImage(SURFACE_ART.roads.mossvein,-40,false);
    for(let index=1;index<definitions.length;index++){
      const item=definitions[index],image=SURFACE_ART.roads[item.biome],fadeStart=item.boundary-40,fadeEnd=item.boundary+40;
      drawSurfaceRoadImage(image,item.x,item.flip,fadeEnd,Infinity);
      const strips=8,stripWidth=(fadeEnd-fadeStart)/strips;
      for(let strip=0;strip<strips;strip++){const left=fadeStart+strip*stripWidth,right=left+stripWidth+.5,alpha=(strip+.5)/strips;drawSurfaceRoadImage(image,item.x,item.flip,left,right,alpha)}
    }
  }

  function drawGround(){
    ctx.fillStyle='#273228';ctx.fillRect(0,0,viewWidth,viewHeight);
    const cavernStart=worldToScreen(WORLD.gateX,0).x,emberStart=worldToScreen(WORLD.emberGateX,0).x,starfallStart=worldToScreen(WORLD.starfallGateX,0).x,moonProduction=imageReady(SURFACE_ART.moonglassGround),emberProduction=imageReady(SURFACE_ART.emberdeepGround),starfallProduction=imageReady(SURFACE_ART.starfallGround);
    if(imageReady(SURFACE_ART.mossveinGround)){
      const origin=worldToScreen(0,0),mossWidth=WORLD.gateX+(moonProduction?MOONGLASS_SURFACE_BLEND:0);ctx.drawImage(SURFACE_ART.mossveinGround,origin.x,origin.y,mossWidth,WORLD.height);
    }
    ctx.fillStyle='#261817';ctx.fillRect(emberStart,0,starfallStart-emberStart,viewHeight);
    if(moonProduction)drawSurfaceMoonglassGround();else{ctx.fillStyle='#14282b';ctx.fillRect(cavernStart,0,emberStart-cavernStart,viewHeight)}
    if(emberProduction)drawSurfaceEmberdeepGround();
    if(starfallProduction)drawSurfaceStarfallGround();else{ctx.fillStyle='#17172a';ctx.fillRect(starfallStart,0,viewWidth-starfallStart,viewHeight)}
    if(!emberProduction){const emberBlend=ctx.createLinearGradient(emberStart-110,0,emberStart+110,0);emberBlend.addColorStop(0,'#14282b');emberBlend.addColorStop(1,'#261817');ctx.fillStyle=emberBlend;ctx.fillRect(emberStart-110,0,220,viewHeight)}
    if(!starfallProduction){const starfallBlend=ctx.createLinearGradient(starfallStart-120,0,starfallStart+120,0);starfallBlend.addColorStop(0,'#261817');starfallBlend.addColorStop(1,'#17172a');ctx.fillStyle=starfallBlend;ctx.fillRect(starfallStart-120,0,240,viewHeight)}
    const legacyGridStart=starfallProduction?viewWidth:emberProduction?starfallStart:moonProduction?emberStart:cavernStart;
    if(legacyGridStart<viewWidth){ctx.save();ctx.beginPath();ctx.rect(legacyGridStart,0,viewWidth-legacyGridStart,viewHeight);ctx.clip();ctx.translate(-camera.x%80,-camera.y%80);ctx.strokeStyle='rgba(190,205,165,.045)';ctx.lineWidth=1;
      for(let x=-80;x<viewWidth+80;x+=80){ctx.beginPath();ctx.moveTo(x,0);ctx.lineTo(x,viewHeight+80);ctx.stroke()}
      for(let y=-80;y<viewHeight+80;y+=80){ctx.beginPath();ctx.moveTo(0,y);ctx.lineTo(viewWidth+80,y);ctx.stroke()}ctx.restore()}
    if(!moonProduction){ctx.fillStyle='rgba(75,174,177,.08)';ctx.fillRect(cavernStart,0,emberStart-cavernStart,viewHeight)}
    if(!emberProduction){ctx.fillStyle='rgba(222,76,35,.07)';ctx.fillRect(emberStart,0,starfallStart-emberStart,viewHeight)}
    if(!starfallProduction){ctx.fillStyle='rgba(154,164,255,.075)';ctx.fillRect(starfallStart,0,viewWidth-starfallStart,viewHeight)}
    drawMossveinMineApproach();
    drawEmberdeepMineApproach();
    drawStarfallMineApproach();
    drawStarfallLatticeBed();
    drawSurfaceMainRoad();
  }

  function drawBiomeStructure(){
    ctx.save();ctx.lineCap='round';ctx.lineJoin='round';
    if(!imageReady(SURFACE_ART.moonglassGround)){
      const moonCenter=worldToScreen(1650,670),moonGlow=ctx.createRadialGradient(moonCenter.x,moonCenter.y,20,moonCenter.x,moonCenter.y,360);
      moonGlow.addColorStop(0,'rgba(87,224,221,.12)');moonGlow.addColorStop(.58,'rgba(74,132,146,.055)');moonGlow.addColorStop(1,'rgba(44,82,90,0)');ctx.fillStyle=moonGlow;ctx.fillRect(moonCenter.x-370,moonCenter.y-370,740,740);
      ctx.strokeStyle='rgba(138,231,229,.15)';ctx.lineWidth=3;for(const radius of [190,285]){ctx.beginPath();ctx.arc(moonCenter.x,moonCenter.y,radius,Math.PI*.1,Math.PI*.9);ctx.stroke()}
    }

    const emberVents=[[2450,220],[2850,610],[3190,1060]];
    if(!imageReady(SURFACE_ART.emberdeepGround))for(let index=0;index<emberVents.length;index++){
      const vent=worldToScreen(emberVents[index][0],emberVents[index][1]),pulse=.5+.5*Math.sin(time*2.3+index);
      const heat=ctx.createRadialGradient(vent.x,vent.y,3,vent.x,vent.y,74+pulse*16);heat.addColorStop(0,'rgba(255,187,90,.18)');heat.addColorStop(.35,'rgba(255,92,43,.08)');heat.addColorStop(1,'rgba(255,66,28,0)');ctx.fillStyle=heat;ctx.fillRect(vent.x-95,vent.y-95,190,190);
      ctx.strokeStyle='rgba(255,121,65,'+(.16+pulse*.08)+')';ctx.lineWidth=2;ctx.beginPath();ctx.arc(vent.x,vent.y,24+pulse*5,0,Math.PI*2);ctx.stroke();
    }

    if(!imageReady(SURFACE_ART.starfallGround)){
      const starCenter=worldToScreen(3900,650);ctx.strokeStyle='rgba(202,208,255,.13)';ctx.lineWidth=2;
      for(const radius of [175,315]){ctx.beginPath();ctx.arc(starCenter.x,starCenter.y,radius,0,Math.PI*2);ctx.stroke()}
      for(let index=0;index<14;index++){
        const wx=3420+(index*193)%940,wy=105+(index*271)%1040,p=worldToScreen(wx,wy),twinkle=.28+.22*Math.sin(time*1.8+index);
        ctx.fillStyle='rgba(237,232,255,'+twinkle+')';ctx.beginPath();ctx.arc(p.x,p.y,index%5===0?2.4:1.35,0,Math.PI*2);ctx.fill();
      }
    }
    ctx.restore();
  }

  function drawSurfaceBoundaryAsset(boundary){
    const image=SURFACE_BOUNDARY_ART[boundary.id];if(!imageReady(image))return;
    const width=boundary.renderWidth,x=boundary.x-camera.x-width*.5;if(x>viewWidth+40||x+width< -40)return;
    ctx.drawImage(image,x,-camera.y,width,WORLD.height);
  }

  function drawSurfaceBoundaryWalls(){for(const boundary of SURFACE_BOUNDARIES)drawSurfaceBoundaryAsset(boundary)}

  function drawDecorations(){
    drawMoonglassSurfaceProductionDecor();
    drawEmberdeepSurfaceProductionDecor();
    drawStarfallSurfaceProductionDecor();
    if(!imageReady(SURFACE_ART.moonglassGround)){
      ctx.save();const veins=[[1080,140,1100,450],[1220,110,1340,280],[1880,80,2010,300],[1500,980,1670,1210]];
      ctx.lineWidth=5;ctx.strokeStyle='rgba(105,226,220,.22)';ctx.shadowBlur=12;ctx.shadowColor='#4bd9dd';for(const vein of veins){const a=worldToScreen(vein[0],vein[1]),b=worldToScreen(vein[2],vein[3]);ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo((a.x+b.x)*.5+20,(a.y+b.y)*.5-15);ctx.lineTo(b.x,b.y);ctx.stroke()}ctx.restore();
    }
    if(!imageReady(SURFACE_ART.emberdeepGround)){ctx.save();ctx.lineWidth=4;ctx.strokeStyle='rgba(255,94,47,.28)';ctx.shadowBlur=9;ctx.shadowColor='#ff5f2f';
      const emberCracks=[[2260,120,2420,350],[2500,60,2700,250],[2800,980,3100,1190],[3060,130,3290,410],[2350,1120,2590,940]];
      for(const crack of emberCracks){const a=worldToScreen(crack[0],crack[1]),b=worldToScreen(crack[2],crack[3]);ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo((a.x+b.x)*.5-18,(a.y+b.y)*.5+12);ctx.lineTo(b.x,b.y);ctx.stroke()}ctx.restore()}
    if(!imageReady(SURFACE_ART.starfallGround)){ctx.save();ctx.lineWidth=3;ctx.strokeStyle='rgba(191,199,255,.24)';ctx.shadowBlur=8;ctx.shadowColor='#a9b3ff';
      const starfallLines=[[3390,160,3590,360],[3660,80,3860,280],[3940,1060,4210,890],[4220,120,4430,360],[3480,1110,3740,930]];
      for(const line of starfallLines){const a=worldToScreen(line[0],line[1]),b=worldToScreen(line[2],line[3]),mx=(a.x+b.x)*.5,my=(a.y+b.y)*.5;ctx.beginPath();ctx.moveTo(a.x,a.y);ctx.lineTo(mx+12,my-18);ctx.lineTo(b.x,b.y);ctx.stroke();ctx.fillStyle='rgba(238,232,255,.48)';ctx.beginPath();ctx.arc(mx+12,my-18,2.5,0,Math.PI*2);ctx.fill()}ctx.restore()}
    for(let i=0;i<30;i++){
      const wx=80+(i*227)%2100,wy=90+(i*163)%1090,p=worldToScreen(wx,wy);
      if(wx<WORLD.gateX)continue;
      if(imageReady(SURFACE_ART.moonglassGround)&&wx<WORLD.emberGateX)continue;
      if(p.x<-30||p.y<-30||p.x>viewWidth+30||p.y>viewHeight+30)continue;
      ctx.fillStyle=i%3?'rgba(18,24,18,.48)':'rgba(111,127,92,.17)';ctx.beginPath();ctx.ellipse(p.x,p.y,18+(i%4)*6,7+(i%3)*3,(i*.7)%3,0,Math.PI*2);ctx.fill();
    }
    drawBiomeDetails();
  }

  function drawBiomeDetails(){
    ctx.save();
    if(!imageReady(SURFACE_ART.moonglassGround))for(let i=0;i<15;i++){
      const wx=1190+(i*173)%940,wy=110+(i*211)%1050,p=worldToScreen(wx,wy);
      if(p.x<-35||p.y<-35||p.x>viewWidth+35||p.y>viewHeight+35)continue;
      ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle=i%3?'rgba(91,210,211,.18)':'rgba(188,150,255,.17)';ctx.strokeStyle='rgba(153,239,235,.36)';ctx.lineWidth=1;
      ctx.beginPath();ctx.moveTo(0,-10-(i%3)*3);ctx.lineTo(5,4);ctx.lineTo(0,9);ctx.lineTo(-5,4);ctx.closePath();ctx.fill();ctx.stroke();ctx.restore();
    }
    if(!imageReady(SURFACE_ART.emberdeepGround))for(let i=0;i<18;i++){
      const wx=2290+(i*197)%980,wy=95+(i*233)%1090,p=worldToScreen(wx,wy);
      if(p.x<-35||p.y<-35||p.x>viewWidth+35||p.y>viewHeight+35)continue;
      ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle=i%3?'rgba(72,34,27,.7)':'rgba(255,92,40,.12)';ctx.strokeStyle='rgba(255,126,67,.28)';ctx.lineWidth=1;
      ctx.beginPath();ctx.moveTo(-14,8);ctx.lineTo(-8,-9);ctx.lineTo(2,-14);ctx.lineTo(15,-3);ctx.lineTo(11,10);ctx.closePath();ctx.fill();ctx.stroke();ctx.restore();
    }
    if(!imageReady(SURFACE_ART.starfallGround))for(let i=0;i<18;i++){
      const wx=3410+(i*193)%960,wy=100+(i*227)%1080,p=worldToScreen(wx,wy);
      if(p.x<-35||p.y<-35||p.x>viewWidth+35||p.y>viewHeight+35)continue;
      ctx.save();ctx.translate(p.x,p.y);ctx.rotate((i%9)*.23);ctx.fillStyle=i%4?'rgba(102,108,170,.22)':'rgba(229,218,255,.24)';ctx.strokeStyle='rgba(196,204,255,.38)';ctx.lineWidth=1;
      ctx.beginPath();ctx.moveTo(0,-8-(i%3)*2);ctx.lineTo(4,0);ctx.lineTo(0,8);ctx.lineTo(-4,0);ctx.closePath();ctx.fill();ctx.stroke();ctx.restore();
    }
    ctx.restore();
  }

  function drawStations(){
    drawBaseModules();drawSpeedShop();if(state.fourthUnlocked)drawStarforge();if(state.hub.unlocked)drawHubLift(HUB_STATIONS.surfaceEntrance,{label:'UNDERGROUND HUB',selected:activeContext==='hubEntrance'});
  }

  function drawBaseModules(){
    for(const module of allBaseModules()){
      if(!moduleIsHere(module))continue;
      if(module.kind==='sell')drawSellStation(module);else if(module.kind==='forge')drawForge(module);else drawStorageChest(module);
    }
  }

  function drawDepthStations(){
    const stations=depthStations(),mine=currentMineVisual(),production=currentScene==='mossMine'?ROOTWOUND_ART:currentScene==='moonMine'?PRISMATIC_ART:currentScene==='emberMine'?MOLTEN_ART:currentScene==='starMine'?VOIDSTAR_ART:null;
    if(production&&imageReady(production.sellStation)&&imageReady(production.drillForge)){
      for(const [kind,station,image,label] of [['sell',stations.sell,production.sellStation,'ORE EXCHANGE'],['forge',stations.forge,production.drillForge,'DRILL FORGE']]){
        const p=worldToScreen(station.x,station.y);if(p.x<-100||p.y<-100||p.x>viewWidth+100||p.y>viewHeight+100)continue;
        const maxWidth=132,maxHeight=116,scale=Math.min(maxWidth/image.naturalWidth,maxHeight/image.naturalHeight),assetWidth=image.naturalWidth*scale,assetHeight=image.naturalHeight*scale,selected=activeContext===(kind==='sell'?'depthSell':'drillForge');
        ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.38)';ctx.beginPath();ctx.ellipse(0,38,54,17,0,0,Math.PI*2);ctx.fill();ctx.drawImage(image,-assetWidth*.5,43-assetHeight,assetWidth,assetHeight);
        if(selected){ctx.strokeStyle=mine.detail;ctx.globalAlpha=.72;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,3,66+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke();ctx.globalAlpha=1}
        ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText(label,0,57);ctx.restore();
      }
      return;
    }
    let p=worldToScreen(stations.sell.x,stations.sell.y);
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.38)';ctx.beginPath();ctx.ellipse(0,28,45,15,0,0,Math.PI*2);ctx.fill();ctx.fillStyle='#3d3327';ctx.strokeStyle=mine.detail;ctx.lineWidth=2;ctx.fillRect(-31,-13,62,38);ctx.strokeRect(-31,-13,62,38);ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText('EXCHANGE',0,9);ctx.restore();
    p=worldToScreen(stations.forge.x,stations.forge.y);ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.4)';ctx.beginPath();ctx.ellipse(0,31,48,16,0,0,Math.PI*2);ctx.fill();ctx.fillStyle='#202827';ctx.strokeStyle=currentDrill()?currentDrill().color:mine.detail;ctx.lineWidth=3;ctx.beginPath();ctx.roundRect(-38,-24,76,52,8);ctx.fill();ctx.stroke();
    ctx.save();ctx.rotate(time*.5);ctx.strokeStyle=currentDrill()?currentDrill().color:mine.detail;ctx.lineWidth=4;for(let i=0;i<6;i++){ctx.rotate(Math.PI/3);ctx.beginPath();ctx.moveTo(13,0);ctx.lineTo(28,0);ctx.stroke()}ctx.restore();ctx.fillStyle='#0c1110';ctx.beginPath();ctx.arc(0,0,13,0,Math.PI*2);ctx.fill();ctx.fillStyle=mine.detail;ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText('DRILL FORGE',0,44);ctx.restore();
  }

  function drawProductionWorldAsset(image,maxWidth,maxHeight,bottom){
    if(!imageReady(image))return false;
    const scale=Math.min(maxWidth/image.naturalWidth,maxHeight/image.naturalHeight),width=image.naturalWidth*scale,height=image.naturalHeight*scale;
    ctx.drawImage(image,-width*.5,bottom-height,width,height);return true;
  }

  function drawSellStation(station){
    const p=worldToScreen(station.x,station.y);if(p.x<-100||p.y<-100||p.x>viewWidth+100||p.y>viewHeight+100)return;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.28)';ctx.beginPath();ctx.ellipse(0,32,70,22,0,0,Math.PI*2);ctx.fill();
    if(drawProductionWorldAsset(STARTER_ART.sellStation,150,130,42)){ctx.restore();return}
    ctx.fillStyle='#52341f';ctx.fillRect(-45,-15,88,44);ctx.fillStyle='#9f6d35';ctx.fillRect(-52,-22,102,12);ctx.fillStyle='#c7a35d';ctx.fillRect(-33,-7,64,7);
    ctx.fillStyle='#d7c4a0';ctx.beginPath();ctx.arc(-23,-31,13,0,Math.PI*2);ctx.arc(1,-34,16,0,Math.PI*2);ctx.arc(27,-29,11,0,Math.PI*2);ctx.fill();
    ctx.fillStyle='#161d17';ctx.font='900 9px Georgia';ctx.textAlign='center';readableFillText('ASSAY',0,15);ctx.restore();
  }

  function drawForge(station){
    const p=worldToScreen(station.x,station.y);if(p.x<-100||p.y<-100||p.x>viewWidth+100||p.y>viewHeight+100)return;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.3)';ctx.beginPath();ctx.ellipse(0,37,65,20,0,0,Math.PI*2);ctx.fill();
    if(drawProductionWorldAsset(STARTER_ART.forgeStation,150,132,45)){ctx.restore();return}
    ctx.fillStyle='#3a3f39';ctx.fillRect(-43,-20,86,53);ctx.fillStyle='#222a24';ctx.fillRect(-30,-9,60,30);
    const glow=ctx.createRadialGradient(0,5,2,0,5,35);glow.addColorStop(0,'#fff09b');glow.addColorStop(.35,'#ef7c2f');glow.addColorStop(1,'rgba(190,55,15,0)');ctx.fillStyle=glow;ctx.fillRect(-38,-33,76,76);
    ctx.fillStyle='#f18b35';ctx.beginPath();ctx.moveTo(-20,19);ctx.lineTo(0,-18);ctx.lineTo(22,19);ctx.closePath();ctx.fill();
    ctx.strokeStyle='#d2bb82';ctx.lineWidth=6;ctx.beginPath();ctx.moveTo(32,-25);ctx.lineTo(51,22);ctx.stroke();ctx.restore();
  }

  function drawStorageChest(chest){
    const p=worldToScreen(chest.x,chest.y);if(p.x<-90||p.y<-90||p.x>viewWidth+90||p.y>viewHeight+90)return;
    const types=chestTypeCount(chest),selected=activeContext==='base:'+chest.id;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.32)';ctx.beginPath();ctx.ellipse(0,25,48,15,0,0,Math.PI*2);ctx.fill();
    if(selected){ctx.strokeStyle='#d7e5b1';ctx.globalAlpha=.7;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,0,48,0,Math.PI*2);ctx.stroke();ctx.globalAlpha=1}
    if(drawProductionWorldAsset(STARTER_ART.storageChest,104,78,34)){ctx.fillStyle='#e9d9a6';ctx.strokeStyle='rgba(5,8,6,.9)';ctx.lineWidth=3;ctx.textAlign='center';ctx.font='900 8px Georgia';readableStrokeText(types+'/'+STORAGE_CHEST_CAPACITY,0,45);readableFillText(types+'/'+STORAGE_CHEST_CAPACITY,0,45);ctx.restore();return}
    ctx.fillStyle='#51371f';ctx.strokeStyle='#d1a85b';ctx.lineWidth=3;ctx.beginPath();ctx.roundRect(-37,-15,74,40,6);ctx.fill();ctx.stroke();ctx.fillStyle='#9d6a35';ctx.fillRect(-38,-17,76,12);ctx.fillStyle='#e4c16d';ctx.fillRect(-7,-18,14,24);ctx.fillStyle='#161b16';ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText(types+'/'+STORAGE_CHEST_CAPACITY,0,17);ctx.restore();
  }

  function drawSpeedShop(){
    const p=worldToScreen(STATIONS.speedShop.x,STATIONS.speedShop.y);if(p.x<-100||p.y<-100||p.x>viewWidth+100||p.y>viewHeight+100)return;
    const selected=activeContext==='speedShop',pulse=1+Math.sin(time*3)*.025;
    ctx.save();ctx.translate(p.x,p.y);ctx.scale(pulse,pulse);ctx.fillStyle='rgba(0,0,0,.3)';ctx.beginPath();ctx.ellipse(0,34,62,18,0,0,Math.PI*2);ctx.fill();
    if(selected){ctx.strokeStyle='#c8f6cd';ctx.globalAlpha=.65;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,0,52,0,Math.PI*2);ctx.stroke();ctx.globalAlpha=1}
    if(drawProductionWorldAsset(STARTER_ART.wayfarerShop,142,130,45)){ctx.restore();return}
    ctx.fillStyle='#284631';ctx.strokeStyle='#8ed9a1';ctx.lineWidth=2;ctx.beginPath();ctx.roundRect(-43,-24,86,55,7);ctx.fill();ctx.stroke();
    ctx.fillStyle='#182a1d';ctx.fillRect(-33,-14,66,34);ctx.strokeStyle='#c8f6cd';ctx.lineWidth=5;ctx.lineCap='round';
    for(const side of [-1,1]){ctx.beginPath();ctx.moveTo(side*-20,-5);ctx.lineTo(side*5,-5);ctx.lineTo(side*19,-17);ctx.stroke()}
    ctx.fillStyle='#d8f4d7';ctx.textAlign='center';ctx.font='900 8px Georgia';readableFillText(movementSpeedMultiplier().toFixed(2)+'x',0,16);ctx.restore();
  }

  function drawStarforge(){
    const p=worldToScreen(STATIONS.starforge.x,STATIONS.starforge.y);if(p.x<-100||p.y<-100||p.x>viewWidth+100||p.y>viewHeight+100)return;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,.38)';ctx.beginPath();ctx.ellipse(0,34,68,20,0,0,Math.PI*2);ctx.fill();
    if(imageReady(STARTER_ART.starforgeStation)){
      const variant=currentStarforge(),selected=activeContext==='starforge';if(variant){ctx.shadowColor=variant.color;ctx.shadowBlur=12}
      drawProductionWorldAsset(STARTER_ART.starforgeStation,150,142,46);ctx.shadowBlur=0;
      if(selected){ctx.strokeStyle=variant?variant.color:'#f0d9ff';ctx.globalAlpha=.7;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,2,72+Math.sin(time*4)*2,0,Math.PI*2);ctx.stroke()}ctx.restore();return;
    }
    ctx.fillStyle='#282943';ctx.strokeStyle='#abb5ff';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(-45,23);ctx.lineTo(-35,-18);ctx.lineTo(0,-34);ctx.lineTo(35,-18);ctx.lineTo(45,23);ctx.closePath();ctx.fill();ctx.stroke();
    ctx.save();ctx.rotate(time*.28);ctx.strokeStyle='#d8dcff';ctx.globalAlpha=.72;for(let i=0;i<4;i++){ctx.rotate(Math.PI/2);ctx.beginPath();ctx.moveTo(0,-11);ctx.lineTo(0,-29);ctx.stroke()}ctx.restore();
    const variant=currentStarforge();ctx.fillStyle=variant?variant.color:'#f0d9ff';ctx.shadowBlur=12;ctx.shadowColor=ctx.fillStyle;ctx.beginPath();ctx.moveTo(0,-20);ctx.lineTo(10,0);ctx.lineTo(0,20);ctx.lineTo(-10,0);ctx.closePath();ctx.fill();ctx.restore();
  }

  function drawGroundDrops(){
    const sweepRemaining=lootSweepRemaining();
    for(const drop of groundDrops){
      if(drop.scene!==currentScene||drop.depth!==currentDepth)continue;
      const p=worldToScreen(drop.x,drop.y),data=lootData(drop.type);if(p.x<-40||p.y<-55||p.x>viewWidth+40||p.y>viewHeight+40)continue;
      const fade=sweepRemaining<8?sweepRemaining/8:1,bob=drop.settled?Math.sin(time*3.2+drop.id)*2:0,size=data.rare?9:7,key=resourceKey(drop.type),production=STARTER_ART.drops[key];
      if(!imageReady(production))continue;
      ctx.save();ctx.globalAlpha=fade;ctx.translate(p.x,p.y-drop.z+bob);ctx.fillStyle='rgba(0,0,0,.34)';ctx.beginPath();ctx.ellipse(0,drop.z-bob+7,size+5,4,0,0,Math.PI*2);ctx.fill();
      {
        const bounds=RESOURCE_IMAGE_BOUNDS[key]||{x:0,y:0,w:production.naturalWidth,h:production.naturalHeight},maxWidth=drop.type==='stone'?30:data.rare?35:33,maxHeight=drop.type==='stone'?27:data.rare?32:30,scale=Math.min(maxWidth/bounds.w,maxHeight/bounds.h),assetWidth=bounds.w*scale,assetHeight=bounds.h*scale;
        ctx.shadowBlur=drop.type==='coin'||drop.type==='gold'?8:drop.type==='copper'?4:2;ctx.shadowColor=data.edge;ctx.drawImage(production,bounds.x,bounds.y,bounds.w,bounds.h,-assetWidth*.5,-assetHeight*.72,assetWidth,assetHeight);ctx.shadowBlur=0;
        if(drop.amount>1){ctx.fillStyle='#fff2c8';ctx.strokeStyle='rgba(0,0,0,.8)';ctx.lineWidth=3;ctx.textAlign='center';ctx.font='900 9px Georgia';readableStrokeText('x'+drop.amount,0,-assetHeight*.72-4);readableFillText('x'+drop.amount,0,-assetHeight*.72-4)}ctx.restore();continue;
      }
    }
  }

  function drawGate(){
    const moonProgress=moonglassGateTransition?clamp(moonglassGateTransition.elapsed/moonglassGateTransition.duration,0,1):(state.areaUnlocked?1:0);
    const emberProgress=emberdeepGateTransition?clamp(emberdeepGateTransition.elapsed/emberdeepGateTransition.duration,0,1):(state.emberdeepUnlocked?1:0);
    const starfallProgress=starfallGateTransition?clamp(starfallGateTransition.elapsed/starfallGateTransition.duration,0,1):(state.fourthUnlocked?1:0);
    if(state.areaUnlocked)drawMoonglassGateMark(moonProgress);
    if(!state.areaUnlocked||moonglassGateTransition)drawGateAt(WORLD.gateX,state.areaUnlocked,'#68e8e5','#202720','#576358',STARTER_ART.moonglassGate,moonProgress);
    if(state.emberdeepUnlocked)drawEmberdeepGateMark(emberProgress);
    if(!state.emberdeepUnlocked||emberdeepGateTransition)drawGateAt(WORLD.emberGateX,state.emberdeepUnlocked,'#ff7747','#2b1b18','#75412c',STARTER_ART.emberdeepSeal,emberProgress);
    if(state.fourthUnlocked)drawStarfallGateMark(starfallProgress);
    if(!state.fourthUnlocked||starfallGateTransition)drawGateAt(WORLD.starfallGateX,state.fourthUnlocked,'#c7caff','#1d1e31','#5e6081',STARTER_ART.starfallSeal,starfallProgress);
  }

  const GATE_MARK_RENDERING=Object.freeze({
    width:300,centerY:76,
    moonglass:Object.freeze({x:14,y:55,w:484,h:222,baseAlpha:.25}),
    emberdeep:Object.freeze({x:28,y:6,w:456,h:329,baseAlpha:.2}),
    starfall:Object.freeze({x:34,y:54,w:449,h:231,baseAlpha:.2})
  });

  function gateActivationPose(progress){
    const smooth=value=>value*value*(3-2*value),flash=progress<.16?Math.sin(progress/.16*Math.PI):0,
      shakeIn=smooth(clamp((progress-.08)/.18,0,1)),shakeOut=1-smooth(clamp((progress-.82)/.18,0,1)),sinkRaw=clamp((progress-.34)/.66,0,1),sink=smooth(sinkRaw),shakeStrength=reducedMotion?0:shakeIn*shakeOut*(1-.35*sink);
    return{flash:reducedMotion?0:flash,sink,shakeX:(Math.sin(progress*239)+Math.sin(progress*521)*.42)*3.2*shakeStrength,shakeY:Math.cos(progress*311)*1.15*shakeStrength,phase:progress<.08?'flash':progress<.34?'shake':progress<1?'sink':'complete'};
  }

  function drawGateMark(image,x,progress,variant){
    const p=worldToScreen(x,WORLD.gateY),source=GATE_MARK_RENDERING[variant];if(!imageReady(image)||p.x<-180||p.x>viewWidth+180)return;
    const eased=gateActivationPose(progress).sink,assetWidth=GATE_MARK_RENDERING.width,assetHeight=assetWidth*source.h/source.w;
    ctx.save();ctx.translate(p.x,p.y);ctx.globalAlpha=source.baseAlpha+(1-source.baseAlpha)*eased;ctx.drawImage(image,source.x,source.y,source.w,source.h,-assetWidth*.5,GATE_MARK_RENDERING.centerY-assetHeight*.5,assetWidth,assetHeight);ctx.restore();
  }

  function drawMoonglassGateMark(progress){drawGateMark(STARTER_ART.moonglassGateMark,WORLD.gateX,progress,'moonglass')}
  function drawEmberdeepGateMark(progress){drawGateMark(STARTER_ART.emberdeepSealMark,WORLD.emberGateX,progress,'emberdeep')}
  function drawStarfallGateMark(progress){drawGateMark(STARTER_ART.starfallSealMark,WORLD.starfallGateX,progress,'starfall')}

  function drawGateAt(x,open,glowColor,stoneColor,braceColor,production=null,transitionProgress=0){
    const p=worldToScreen(x,WORLD.gateY);if(p.x<-180||p.x>viewWidth+180)return;
    const transitioning=open&&transitionProgress<1,pose=transitioning?gateActivationPose(transitionProgress):{flash:0,sink:open?1:0,shakeX:0,shakeY:0,phase:open?'complete':'locked'};
    ctx.save();ctx.translate(p.x,p.y);
    if(transitioning){ctx.beginPath();ctx.rect(-180,-260,360,370);ctx.clip();ctx.translate(pose.shakeX,pose.shakeY+pose.sink*238);ctx.globalAlpha=1-clamp((pose.sink-.88)/.12,0,1)}
    if(imageReady(production)){
      drawProductionWorldAsset(production,260,238,110);
      if(pose.flash>0){ctx.save();ctx.globalCompositeOperation='screen';ctx.filter='brightness(2.35) saturate(1.35)';ctx.globalAlpha=pose.flash*.58;drawProductionWorldAsset(production,260,238,110);ctx.restore()}
      ctx.restore();return;
    }
    ctx.fillStyle=stoneColor;ctx.fillRect(-28,-190,56,145);ctx.fillRect(-28,45,56,145);
    ctx.fillStyle=braceColor;for(const y of [-170,-115,-60,60,115,170])ctx.fillRect(-34,y-13,68,25);
    ctx.strokeStyle=open?glowColor+'44':glowColor;ctx.lineWidth=open?2:7;ctx.shadowBlur=open?4:15;ctx.shadowColor=glowColor;
    ctx.beginPath();ctx.moveTo(0,-43);ctx.lineTo(0,43);ctx.stroke();
    if(!open){ctx.lineWidth=3;for(let i=-3;i<=3;i++){ctx.beginPath();ctx.moveTo(-24+i*5,-44);ctx.lineTo(22-i*4,44);ctx.stroke()}}
    ctx.restore();
  }

  function drawVeins(){
    for(const vein of veins){
      const center=veinCenter(vein),screenCenter=worldToScreen(center.x,center.y);
      if(screenCenter.x<-180||screenCenter.y<-180||screenCenter.x>viewWidth+180||screenCenter.y>viewHeight+180)continue;
      const active=vein.status==='active',ready=vein.status==='idle',completed=vein.status==='completed',pulse=.5+.5*Math.sin(time*5);
      const points=vein.positions.map(position=>worldToScreen(position[0],position[1]+9));
      ctx.save();ctx.lineCap='round';ctx.lineJoin='round';ctx.strokeStyle=vein.color;ctx.shadowColor=vein.color;ctx.shadowBlur=active?14:ready?8:completed?11:0;ctx.lineWidth=active?5:completed?4:2.5;ctx.globalAlpha=active?.48+.2*pulse:completed?.28+.12*pulse:ready?.16+.08*pulse:.07;
      ctx.beginPath();points.forEach((point,index)=>index?ctx.lineTo(point.x,point.y):ctx.moveTo(point.x,point.y));ctx.stroke();
      if(ready){
        const travel=(time*.34)%1,segments=points.length-1,scaled=travel*segments,index=Math.min(segments-1,Math.floor(scaled)),local=scaled-index,a=points[index],b=points[index+1],x=a.x+(b.x-a.x)*local,y=a.y+(b.y-a.y)*local;
        const glow=ctx.createRadialGradient(x,y,1,x,y,17);glow.addColorStop(0,'rgba(255,249,205,.95)');glow.addColorStop(.25,vein.color+'c8');glow.addColorStop(1,vein.color+'00');ctx.globalAlpha=.72+.28*pulse;ctx.fillStyle=glow;ctx.beginPath();ctx.arc(x,y,17,0,Math.PI*2);ctx.fill();
      }
      if(active){
        const remaining=clamp(vein.timer/vein.timeLimit,0,1),radius=64;ctx.shadowBlur=12;ctx.lineWidth=5;ctx.globalAlpha=.18;ctx.strokeStyle=vein.color;ctx.beginPath();ctx.arc(screenCenter.x,screenCenter.y+9,radius,0,Math.PI*2);ctx.stroke();ctx.globalAlpha=.88;ctx.beginPath();ctx.arc(screenCenter.x,screenCenter.y+9,radius,-Math.PI*.5,-Math.PI*.5+Math.PI*2*remaining);ctx.stroke();
        const angle=-Math.PI*.5+Math.PI*2*remaining,x=screenCenter.x+Math.cos(angle)*radius,y=screenCenter.y+9+Math.sin(angle)*radius;ctx.fillStyle='#fff3bd';ctx.shadowBlur=16;ctx.beginPath();ctx.arc(x,y,4.5,0,Math.PI*2);ctx.fill();
      }else if(completed){
        ctx.globalAlpha=.28+.25*pulse;ctx.fillStyle=vein.color;ctx.shadowBlur=15;for(let index=0;index<6;index++){const angle=index*Math.PI/3+time*.18,radius=32+(index%2)*17,x=screenCenter.x+Math.cos(angle)*radius,y=screenCenter.y+9+Math.sin(angle)*radius;ctx.beginPath();ctx.arc(x,y,index%2?2:3,0,Math.PI*2);ctx.fill()}
      }
      ctx.restore();
    }
  }

  function drawMineralNodeAsset(rock){
    const rootwoundNode=isRootwoundProduction()?ROOTWOUND_ART.nodes[rock.type]:null;
    if(imageReady(rootwoundNode)){
      const maxWidth=rock.type==='burrowsteel'?86:82,maxHeight=78,scale=Math.min(maxWidth/rootwoundNode.naturalWidth,maxHeight/rootwoundNode.naturalHeight),width=rootwoundNode.naturalWidth*scale,height=rootwoundNode.naturalHeight*scale;
      ctx.drawImage(rootwoundNode,-width*.5,-height*.56,width,height);
      return true;
    }
    const activeArt=activeMineProductionArt(),productionNode=activeArt&&activeArt.nodes[rock.type]||currentScene==='surface'&&(STARFALL_ART.nodes[rock.type]||EMBERDEEP_ART.nodes[rock.type]||MOONGLASS_ART.nodes[rock.type]);
    if(imageReady(productionNode)){
      const maxWidth=ROCK_TYPES[rock.type].rare?88:84,maxHeight=80,scale=Math.min(maxWidth/productionNode.naturalWidth,maxHeight/productionNode.naturalHeight),width=productionNode.naturalWidth*scale,height=productionNode.naturalHeight*scale;
      ctx.drawImage(productionNode,-width*.5,-height*.56,width,height);
      return true;
    }
    const production=MINERAL_ART[rock.type],image=production&&production.node;
    if(imageReady(image)){
      const maxWidth=92*MINERAL_NODE_RENDER_SCALE,maxHeight=82*MINERAL_NODE_RENDER_SCALE,scale=Math.min(maxWidth/image.naturalWidth,maxHeight/image.naturalHeight),width=image.naturalWidth*scale,height=image.naturalHeight*scale;
      ctx.drawImage(image,-width*.5,-height*.56,width,height);return true;
    }
    const pickup=STARTER_ART.drops[rock.type],bounds=RESOURCE_IMAGE_BOUNDS[rock.type];
    if(!imageReady(pickup)||!bounds)return false;
    const maxWidth=ROCK_TYPES[rock.type].rare?88:84,maxHeight=80,scale=Math.min(maxWidth/bounds.w,maxHeight/bounds.h),width=bounds.w*scale,height=bounds.h*scale;
    ctx.drawImage(pickup,bounds.x,bounds.y,bounds.w,bounds.h,-width*.5,-height*.56,width,height);return true;
  }

  function drawChests(){
    for(const chest of chests){
      const p=worldToScreen(chest.x,chest.y);if(p.x<-75||p.y<-80||p.x>viewWidth+75||p.y>viewHeight+80)continue;
      const biome=BIOMES.find(item=>item.id===chest.biome),opened=!!state.openedChests[chest.id],ready=chestRequirementMet(chest);
      const selected=activeContext==='chest:'+chest.id,pulse=1+Math.sin(time*2.4+chest.tier)*.018;
      ctx.save();ctx.translate(p.x,p.y);ctx.scale(pulse,pulse);
      ctx.fillStyle='rgba(0,0,0,.38)';ctx.beginPath();ctx.ellipse(0,25,35,12,0,0,Math.PI*2);ctx.fill();
      if(selected&&!opened){ctx.strokeStyle=ready?'#ffe19a':'#8d8570';ctx.globalAlpha=.72;ctx.lineWidth=2;ctx.beginPath();ctx.arc(0,3,43,0,Math.PI*2);ctx.stroke();ctx.globalAlpha=1}
      const biomeChest=MOONGLASS_SURFACE_CHEST_ART[chest.id]||EMBERDEEP_SURFACE_CHEST_ART[chest.id]||STARFALL_SURFACE_CHEST_ART[chest.id],production=biomeChest?(opened?biomeChest.open:biomeChest.closed):chest.biome==='mossvein'?(opened?STARTER_ART.treasureOpen:STARTER_ART.treasureClosed):null;
      if(imageReady(production)){
        ctx.globalAlpha=opened?0.72:ready?1:.58;drawProductionWorldAsset(production,104,88,35);ctx.globalAlpha=1;
        if(!opened&&!ready){ctx.fillStyle='rgba(8,9,8,.86)';ctx.strokeStyle='#8d846e';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(0,-35,11,0,Math.PI*2);ctx.fill();ctx.stroke();ctx.fillStyle='#bdb49c';ctx.font='900 10px Georgia';ctx.textAlign='center';readableFillText(String(chest.requires.pickaxeLevel||'S'),0,-31)}
        if(!opened&&ready){const sparkle=.45+.35*Math.sin(time*3.1+chest.tier);ctx.strokeStyle='#fff0b1';ctx.globalAlpha=sparkle;ctx.lineWidth=1.5;ctx.beginPath();ctx.moveTo(38,-28);ctx.lineTo(38,-12);ctx.moveTo(30,-20);ctx.lineTo(46,-20);ctx.stroke();ctx.globalAlpha=1}ctx.restore();continue;
      }
      ctx.fillStyle=opened?'#241f19':'#3b2a1b';ctx.strokeStyle=opened?'#786d59':'#c69545';ctx.lineWidth=3;
      ctx.beginPath();ctx.roundRect(-31,-4,62,33,4);ctx.fill();ctx.stroke();
      ctx.fillStyle=opened?'#17130f':'#5b3a22';ctx.strokeStyle=opened?'#716655':'#d3a553';ctx.beginPath();
      if(opened){ctx.moveTo(-30,-5);ctx.lineTo(-24,-34);ctx.lineTo(25,-34);ctx.lineTo(31,-5);ctx.closePath()}
      else ctx.roundRect(-31,-25,62,25,[7,7,2,2]);
      ctx.fill();ctx.stroke();
      ctx.fillStyle=biome.accent;ctx.globalAlpha=opened?.22:ready?.9:.34;ctx.fillRect(-25,5,50,4);ctx.globalAlpha=1;
      ctx.fillStyle='#d7ad58';ctx.fillRect(-4,-7,8,18);ctx.strokeStyle='#4b351a';ctx.lineWidth=1;ctx.strokeRect(-4,-7,8,18);
      ctx.fillStyle=ready||opened?biome.detail:'#675f51';ctx.shadowBlur=ready&&!opened?8:0;ctx.shadowColor=biome.accent;ctx.beginPath();ctx.arc(0,1,3.4,0,Math.PI*2);ctx.fill();ctx.shadowBlur=0;
      for(const side of [-1,1]){ctx.fillStyle='#a97c36';ctx.fillRect(side*22-2,-20,4,44)}
      if(!opened&&!ready){
        ctx.fillStyle='rgba(8,9,8,.82)';ctx.strokeStyle='#8d846e';ctx.lineWidth=1.5;ctx.beginPath();ctx.arc(0,-36,11,0,Math.PI*2);ctx.fill();ctx.stroke();
        ctx.fillStyle='#bdb49c';ctx.font='900 10px Georgia';ctx.textAlign='center';readableFillText(String(chest.requires.pickaxeLevel||'S'),0,-32);
      }
      if(!opened&&ready){
        const sparkle=.45+.35*Math.sin(time*3.1+chest.tier);ctx.strokeStyle='#fff0b1';ctx.globalAlpha=sparkle;ctx.lineWidth=1.5;ctx.beginPath();ctx.moveTo(34,-25);ctx.lineTo(34,-11);ctx.moveTo(27,-18);ctx.lineTo(41,-18);ctx.stroke();ctx.globalAlpha=1;
      }
      ctx.restore();
    }
  }

  function drawRocks(){
    const target=nearestRock(MINING_RANGE);
    for(const rock of currentRocks()){
      if(rock.broken||!rockIsExposed(rock))continue;
      const p=worldToScreen(rock.x,rock.y);if(p.x<-70||p.y<-70||p.x>viewWidth+70||p.y>viewHeight+70)continue;
      const data=ROCK_TYPES[rock.type],pulse=target&&target.id===rock.id?1+Math.sin(time*6)*.025:1;
      ctx.save();ctx.translate(p.x,p.y);ctx.scale(pulse,pulse);
      if(target&&target.id===rock.id){ctx.strokeStyle=data.edge;ctx.globalAlpha=.5;ctx.lineWidth=2;ctx.lineCap='round';for(let corner=0;corner<4;corner++){ctx.save();ctx.rotate(corner*Math.PI*.5);ctx.beginPath();ctx.moveTo(29,-29);ctx.lineTo(39,-29);ctx.lineTo(39,-19);ctx.stroke();ctx.restore()}ctx.globalAlpha=1}
      ctx.fillStyle='rgba(0,0,0,.32)';ctx.beginPath();ctx.ellipse(0,24,37,13,0,0,Math.PI*2);ctx.fill();
      const hitScale=rock.hit>0?1+rock.hit*.22:1;ctx.scale(hitScale,1/hitScale);
      const assetNode=drawMineralNodeAsset(rock);
      if(!assetNode){ctx.restore();continue}
      if(rock.shell>0){ctx.fillStyle='rgba(0,0,0,.62)';ctx.fillRect(-31,-55,62,6);ctx.fillStyle=data.edge;ctx.fillRect(-31,-55,62*(rock.shell/rock.maxShell),6)}
      else if(rock.hp<rock.maxHp){ctx.fillStyle='rgba(0,0,0,.55)';ctx.fillRect(-30,-52,60,5);ctx.fillStyle=data.edge;ctx.fillRect(-30,-52,60*(rock.hp/rock.maxHp),5)}
      if(rock.glintActive>0){
        const flash=rock.glintActive/.72,ox=-11+(rock.seed%21),oy=-19+(rock.seed%13);
        ctx.save();ctx.translate(ox,oy);ctx.rotate(time*4);ctx.globalAlpha=.5+.5*Math.sin(flash*Math.PI);ctx.strokeStyle='#fff7c8';ctx.lineWidth=2;ctx.shadowBlur=8;ctx.shadowColor=data.edge;
        ctx.beginPath();ctx.moveTo(-9,0);ctx.lineTo(9,0);ctx.moveTo(0,-9);ctx.lineTo(0,9);ctx.stroke();ctx.restore();
      }
      ctx.restore();
    }
  }

  function playerRenderPose(){
    const drilling=state.drillLevel>0,activeDrill=drilling&&(!!player.swing||input.mineHeld);
    if(drilling){
      const vibrates=activeDrill&&!reducedMotion,buzzX=vibrates?-.45+Math.sin(time*79)*1.25+Math.sin(time*43)*.35:0,buzzY=vibrates?Math.sin(time*91)*.72:0;
      return{toolAngle:0,armAngle:0,armX:buzzX,armY:buzzY,bodyAngle:vibrates?Math.sin(time*61)*.008:0,bodyY:0,active:activeDrill};
    }
    if(!player.swing)return{toolAngle:-.2,armAngle:0,armX:0,armY:0,bodyAngle:0,bodyY:0,active:false};
    const t=clamp(player.swing.elapsed/player.swing.duration,0,1),idle=-.2,windup=-1.08,strike=.58;
    let toolAngle,drive;
    if(t<.18){const u=easeOut(t/.18);toolAngle=idle+(windup-idle)*u;drive=-u}
    else if(t<.38){const u=easeInOut((t-.18)/.2);toolAngle=windup+(strike-windup)*u;drive=-1+u*2}
    else{const u=easeOut((t-.38)/.62);toolAngle=strike+(idle-strike)*u;drive=1-u}
    return{toolAngle,armAngle:(toolAngle-idle)*.16,armX:drive*1.6,armY:-Math.abs(drive)*.55,bodyAngle:drive*.034,bodyY:-Math.sin(t*Math.PI)*.7,active:true};
  }

  function drawPlayerBaseWithoutGrip(body,bodyX,bodyY,scale,crop){
    ctx.drawImage(body,0,0,body.naturalWidth,crop.y,bodyX,bodyY,body.naturalWidth*scale,crop.y*scale);
    ctx.drawImage(body,0,crop.y,crop.x,crop.h,bodyX,bodyY+crop.y*scale,crop.x*scale,crop.h*scale);
    const rightX=crop.x+crop.w,rightWidth=body.naturalWidth-rightX;
    ctx.drawImage(body,rightX,crop.y,rightWidth,crop.h,bodyX+rightX*scale,bodyY+crop.y*scale,rightWidth*scale,crop.h*scale);
    const lowerY=crop.y+crop.h,lowerHeight=body.naturalHeight-lowerY;
    ctx.drawImage(body,0,lowerY,body.naturalWidth,lowerHeight,bodyX,bodyY+lowerY*scale,body.naturalWidth*scale,lowerHeight*scale);
  }

  function drawHolsteredWalkTool(direction,frame,front){
    if(state.drillLevel)return;
    const drawInFront=direction==='up';if(front!==drawInFront)return;
    const key=currentPlayerToolKey(),asset=PLAYER_ART.tools[key],config=PLAYER_TOOL_RENDER[key];if(!config||!imageReady(asset))return;
    const anchor=PLAYER_WALK_TOOL_ANCHORS[direction]||PLAYER_WALK_TOOL_ANCHORS.right;
    const cycle=frame/PLAYER_RENDER_CONTRACT.walkColumns*Math.PI*2,width=config.width*.86,height=width*(asset.naturalHeight/asset.naturalWidth);
    ctx.save();ctx.translate(anchor.x,anchor.y+Math.sin(cycle)*.65);if(anchor.flip)ctx.scale(-1,1);ctx.rotate(anchor.angle+Math.sin(cycle)*.025);ctx.globalAlpha=drawInFront ? .9 : .96;
    ctx.drawImage(asset,-width*config.pivotX,-height*config.pivotY,width,height);ctx.restore();
  }

  function drawPlayerWalkFrame(p){
    if(player.swing||input.mineHeld)return false;
    const sheet=ensurePlayerWalkSheet();if(!imageReady(sheet))return false;
    const frame=reducedMotion?0:clamp(player.walkFrame,0,PLAYER_RENDER_CONTRACT.walkColumns-1),row=PLAYER_WALK_ROWS[player.direction]??PLAYER_WALK_ROWS.right;
    const size=PLAYER_RENDER_CONTRACT.walkRenderSize,scale=size/PLAYER_RENDER_CONTRACT.walkCellSize,bodyY=PLAYER_RENDER_CONTRACT.bodyBottom-PLAYER_RENDER_CONTRACT.walkRootY*scale,lift=PLAYER_WALK_FRAME_LIFT[frame]||0;
    ctx.save();ctx.translate(p.x,p.y);ctx.fillStyle='rgba(0,0,0,'+(player.moving ? .32 : .34)+')';ctx.beginPath();ctx.ellipse(0,29,33-lift*1.2,11-lift*.45,0,0,Math.PI*2);ctx.fill();
    drawHolsteredWalkTool(player.direction,frame,false);
    ctx.drawImage(sheet,frame*PLAYER_RENDER_CONTRACT.walkCellSize,row*PLAYER_RENDER_CONTRACT.walkCellSize,PLAYER_RENDER_CONTRACT.walkCellSize,PLAYER_RENDER_CONTRACT.walkCellSize,-size*.5,bodyY,size,size);
    drawHolsteredWalkTool(player.direction,frame,true);ctx.restore();return true;
  }

  function drawPlayer(){
    const p=worldToScreen(player.x,player.y);if(drawPlayerWalkFrame(p))return;
    const bob=reducedMotion?0:player.moving?Math.sin(player.walk)*2:Math.sin(time*2.4)*1.2,pose=playerRenderPose();
    ctx.save();ctx.translate(p.x,p.y+bob);ctx.scale(player.facing,1);
    ctx.fillStyle='rgba(0,0,0,.34)';ctx.beginPath();ctx.ellipse(0,29,34,12,0,0,Math.PI*2);ctx.fill();
    if(state.drillLevel>0){
      const body=PLAYER_ART.drillCharacters[currentPlayerToolKey()];
      if(imageReady(body)){
        const height=PLAYER_RENDER_CONTRACT.drillCompositeHeight,width=height*(body.naturalWidth/body.naturalHeight),bottom=PLAYER_RENDER_CONTRACT.bodyBottom;
        ctx.save();ctx.translate(pose.armX,pose.armY);ctx.translate(0,bottom-2);ctx.rotate(pose.bodyAngle);ctx.translate(0,-(bottom-2));ctx.drawImage(body,-width*.5,bottom-height,width,height);ctx.restore();
      }
      ctx.restore();return;
    }
    const body=PLAYER_ART.base;
    if(imageReady(body)){
      const bodyHeight=PLAYER_RENDER_CONTRACT.bodyHeight,scale=bodyHeight/body.naturalHeight,bodyWidth=body.naturalWidth*scale,bodyX=-bodyWidth*.5,bodyY=PLAYER_RENDER_CONTRACT.bodyBottom-bodyHeight,crop=PLAYER_RENDER_CONTRACT.gripCrop,pivot=PLAYER_RENDER_CONTRACT.gripPivot,grip=PLAYER_RENDER_CONTRACT.gripPoint;
      ctx.save();ctx.translate(0,PLAYER_RENDER_CONTRACT.bodyBottom-2);ctx.rotate(pose.bodyAngle);ctx.translate(0,-(PLAYER_RENDER_CONTRACT.bodyBottom-2)+pose.bodyY);
      drawPlayerBaseWithoutGrip(body,bodyX,bodyY,scale,crop);
      const pivotX=bodyX+(crop.x+pivot.x)*scale,pivotY=bodyY+(crop.y+pivot.y)*scale,gripX=(grip.x-pivot.x)*scale,gripY=(grip.y-pivot.y)*scale;
      ctx.save();ctx.translate(pivotX+pose.armX,pivotY+pose.armY);ctx.rotate(pose.armAngle);
      drawPlayerToolLayer(pose,gripX,gripY);
      ctx.drawImage(body,crop.x,crop.y,crop.w,crop.h,-pivot.x*scale,-pivot.y*scale,crop.w*scale,crop.h*scale);
      ctx.restore();ctx.restore();
    }
    ctx.restore();
  }

  function drawPlayerToolLayer(pose,gripX,gripY){
    const key=currentPlayerToolKey(),asset=PLAYER_ART.tools[key],config=PLAYER_TOOL_RENDER[key];
    if(!config||!imageReady(asset))return;
    const width=config.width,height=width*(asset.naturalHeight/asset.naturalWidth);
    ctx.save();ctx.translate(gripX,gripY);ctx.rotate(pose.toolAngle-pose.armAngle);
    ctx.drawImage(asset,-width*config.pivotX,-height*config.pivotY,width,height);
    ctx.restore();
  }

  function drawEffects(front){
    if(!front){
      drawTerrainResponses();
      return;
    }
    for(const mote of saleMotes){
      if(mote.age<0)continue;const t=easeInOut(mote.age/mote.life),wx=mote.sx+(mote.tx-mote.sx)*t,wy=mote.sy+(mote.ty-mote.sy)*t-Math.sin(t*Math.PI)*32,p=worldToScreen(wx,wy);
      const key=resourceKey(mote.type),image=STARTER_ART.drops[key],bounds=RESOURCE_IMAGE_BOUNDS[key];if(!imageReady(image)||!bounds)continue;
      const scale=mote.size/Math.max(bounds.w,bounds.h),assetWidth=bounds.w*scale,assetHeight=bounds.h*scale;
      ctx.save();ctx.globalAlpha=Math.sin(Math.min(1,t)*Math.PI)*.78+.18;ctx.translate(p.x,p.y);ctx.rotate((t-.5)*.5);ctx.drawImage(image,bounds.x,bounds.y,bounds.w,bounds.h,-assetWidth*.5,-assetHeight*.5,assetWidth,assetHeight);ctx.restore();
    }
    for(const floater of floaters){const p=worldToScreen(floater.x,floater.y),t=floater.age/floater.life;ctx.save();ctx.globalAlpha=Math.min(1,(1-t)*2.4);ctx.fillStyle=floater.color;ctx.strokeStyle='rgba(3,5,3,.8)';ctx.lineWidth=3;ctx.textAlign='center';ctx.font='900 '+floater.size+'px Georgia';readableStrokeText(floater.text,p.x,p.y);readableFillText(floater.text,p.x,p.y);ctx.restore()}
  }

  function drawWorldLabels(){
    const mine=currentMine();
    const baseLabels=allBaseModules().filter(module=>moduleIsHere(module)).map(module=>[module.kind==='sell'?'SELL CHEST':module.kind==='forge'?'FORGE':'STORAGE CHEST',module.x,module.y-65,module.kind==='forge'?'#f2a35d':module.kind==='sell'?'#e9cb82':'#a9d7a9']);
    const labels=(mine?(currentDepth===2?[]:mine.labels.slice()):[['WAYFARER SHOP',STATIONS.speedShop.x,STATIONS.speedShop.y-75,'#a9efb6']]).concat(baseLabels);
    if(mine){
      ctx.save();ctx.textAlign='center';ctx.font='900 10px Georgia';
      for(const label of labels){const p=worldToScreen(label[1],label[2]);if(p.x<0||p.x>viewWidth||p.y<0||p.y>viewHeight)continue;ctx.fillStyle='rgba(5,8,5,.72)';ctx.fillRect(p.x-58,p.y-11,116,20);ctx.fillStyle=label[3];readableFillText(label[0],p.x,p.y+3)}ctx.restore();return;
    }
    if(state.fourthUnlocked)labels.push(['STARFORGE',STATIONS.starforge.x,STATIONS.starforge.y-73,'#d9dcff']);
    if(!state.areaUnlocked)labels.push(['MOONGLASS GATE',WORLD.gateX-58,WORLD.gateY-215,'#9ce7e6']);
    if(state.areaUnlocked&&!state.emberdeepUnlocked)labels.push(['EMBERDEEP SEAL',WORLD.emberGateX-58,WORLD.gateY-215,'#ff9a68']);
    if(state.emberdeepUnlocked&&!state.fourthUnlocked)labels.push(['STARFALL MASTER SEAL',WORLD.starfallGateX-65,WORLD.gateY-215,'#d6d8ff']);
    ctx.save();ctx.textAlign='center';ctx.font='900 10px Georgia';
    for(const label of labels){const p=worldToScreen(label[1],label[2]);if(p.x<0||p.x>viewWidth||p.y<0||p.y>viewHeight)continue;ctx.fillStyle='rgba(5,8,5,.72)';ctx.fillRect(p.x-56,p.y-11,112,20);ctx.fillStyle=label[3];readableFillText(label[0],p.x,p.y+3)}ctx.restore();
  }

  function frame(timestamp){
    const raw=Math.min(.05,Math.max(0,(timestamp-lastFrame)/1000||0));lastFrame=timestamp;
    const frozen=Math.min(raw,miningFeedback.hitStop);miningFeedback.hitStop=Math.max(0,miningFeedback.hitStop-frozen);
    if(startScreen.hidden&&menuShade.hidden&&inventoryShade.hidden&&heatTutorialShade.hidden&&hubTutorialShade.hidden)update((raw-frozen)*timeScale);draw();requestAnimationFrame(frame);
  }

  function setJoystickFromEvent(event){
    const dx=event.clientX-input.joystickOriginX,dy=event.clientY-input.joystickOriginY,max=joystick.offsetWidth*.31,length=Math.hypot(dx,dy)||1,scale=Math.min(1,max/length),px=dx*scale,py=dy*scale;
    joystickKnob.style.transform='translate(calc(-50% + '+px+'px),calc(-50% + '+py+'px))';input.moveX=clamp(dx/max,-1,1);input.moveY=clamp(dy/max,-1,1);
  }
  function releaseJoystick(event){
    if(input.joystickPointer!==null&&event.pointerId!==undefined&&event.pointerId!==input.joystickPointer)return;
    input.joystickPointer=null;input.moveX=0;input.moveY=0;joystickKnob.style.transform='translate(-50%,-50%)';joystick.classList.remove('active');
    setTimeout(()=>{if(input.joystickPointer===null){joystick.style.removeProperty('left');joystick.style.removeProperty('top');joystick.style.removeProperty('bottom')}},100);
  }
  function beginFloatingJoystick(event){
    if(event.target!==canvas||hubBuild.active||input.joystickPointer!==null||!startScreen.hidden||!menuShade.hidden||!inventoryShade.hidden||!heatTutorialShade.hidden||!hubTutorialShade.hidden)return;
    if(event.button!==undefined&&event.button!==0)return;
    event.preventDefault();unlockAudio();
    const rect=viewport.getBoundingClientRect(),width=joystick.offsetWidth,height=joystick.offsetHeight;
    input.joystickPointer=event.pointerId;input.joystickOriginX=event.clientX;input.joystickOriginY=event.clientY;input.moveX=0;input.moveY=0;
    joystick.style.left=event.clientX-rect.left-width/2+'px';joystick.style.top=event.clientY-rect.top-height/2+'px';joystick.style.bottom='auto';joystickKnob.style.transform='translate(-50%,-50%)';joystick.classList.add('active');
    try{viewport.setPointerCapture(event.pointerId)}catch(error){}
  }

  viewport.addEventListener('pointerdown',beginFloatingJoystick);
  viewport.addEventListener('pointermove',event=>{if(event.pointerId===input.joystickPointer){event.preventDefault();setJoystickFromEvent(event)}});
  viewport.addEventListener('pointerup',releaseJoystick);viewport.addEventListener('pointercancel',releaseJoystick);viewport.addEventListener('lostpointercapture',releaseJoystick);

  mineButton.addEventListener('pointerdown',event=>{
    event.preventDefault();unlockAudio();if(inHub()){setHubBuildMode(!hubBuild.active);return}input.minePointers.add(event.pointerId);input.mineHeld=true;mineButton.classList.add('active');startSwing(true);
    try{mineButton.setPointerCapture(event.pointerId)}catch(error){}
  });
  function releaseMine(event){input.minePointers.delete(event.pointerId);input.mineHeld=input.minePointers.size>0;if(!input.mineHeld){mineButton.classList.remove('active');resetHeatStreak()}}
  mineButton.addEventListener('pointerup',releaseMine);mineButton.addEventListener('pointercancel',releaseMine);mineButton.addEventListener('lostpointercapture',releaseMine);

  canvas.addEventListener('pointerdown',event=>{
    event.preventDefault();unlockAudio();const rect=canvas.getBoundingClientRect(),world=screenToWorld(event.clientX-rect.left,event.clientY-rect.top);
    if(hubBuild.active&&inHub()){
      if(event.stopPropagation)event.stopPropagation();hubBuild.pointerId=event.pointerId;hubBuild.lastCell=null;hubBuild.singlePlaced=false;paintHubAtWorld(world.x,world.y);try{canvas.setPointerCapture(event.pointerId)}catch(error){}return;
    }
    const rock=rocks.find(item=>!item.broken&&distance(item.x,item.y,world.x,world.y)<48);
    if(rock&&distance(player.x,player.y,rock.x,rock.y)<=MINING_RANGE){player.hitRockId=rock.id;startSwing(true)}
  });
  canvas.addEventListener('pointermove',event=>{if(!hubBuild.active||event.pointerId!==hubBuild.pointerId)return;event.preventDefault();const rect=canvas.getBoundingClientRect(),world=screenToWorld(event.clientX-rect.left,event.clientY-rect.top);paintHubAtWorld(world.x,world.y)});
  function finishHubPaint(event){if(event.pointerId!==undefined&&event.pointerId!==hubBuild.pointerId)return;hubBuild.pointerId=null;hubBuild.lastCell=null;hubBuild.singlePlaced=false;if(hubBuild.changed){hubBuild.changed=false;saveState(true)}}
  canvas.addEventListener('pointerup',finishHubPaint);canvas.addEventListener('pointercancel',finishHubPaint);canvas.addEventListener('lostpointercapture',finishHubPaint);

  // Safari still exposes native zoom/callout gestures around mixed canvas and DOM controls.
  // Keep those gestures outside the game while preserving normal single-pointer controls.
  const preventGameGesture=event=>{if(game.contains(event.target))event.preventDefault()};
  document.addEventListener('gesturestart',preventGameGesture,{passive:false});
  document.addEventListener('gesturechange',preventGameGesture,{passive:false});
  document.addEventListener('gestureend',preventGameGesture,{passive:false});
  document.addEventListener('dblclick',preventGameGesture,{passive:false});
  document.addEventListener('contextmenu',preventGameGesture,{passive:false});
  document.addEventListener('touchmove',event=>{if(event.touches.length>1&&game.contains(event.target))event.preventDefault()},{passive:false});

  function releaseTouchControls(){
    input.minePointers.clear();input.mineHeld=false;mineButton.classList.remove('active');resetHeatStreak();releaseJoystick({});player.moving=false;
  }

  window.addEventListener('keydown',event=>{
    if(['ArrowLeft','ArrowRight','ArrowUp','ArrowDown','Space'].includes(event.code))event.preventDefault();
    unlockAudio();input.keys.add(event.code);
    if(event.code==='Space'){if(inHub()){if(!event.repeat)setHubBuildMode(!hubBuild.active)}else{input.mineHeld=true;mineButton.classList.add('active');if(!event.repeat)startSwing(true)}}
    if(event.code==='KeyE')performContext();
    if(event.code==='Escape'){if(hubBuild.active)setHubBuildMode(false);else if(!inventoryShade.hidden)closeInventory();else if(!menuShade.hidden){menuShade.hidden=true;syncAchievementPopup()}}
  });
  window.addEventListener('keyup',event=>{input.keys.delete(event.code);if(event.code==='Space'&&!inHub()){input.mineHeld=false;mineButton.classList.remove('active');resetHeatStreak()}});
  window.addEventListener('blur',()=>{input.keys.clear();releaseTouchControls()});
  window.addEventListener('pagehide',()=>{releaseTouchControls();if(loadedExistingSave||startScreen.hidden)saveState(true)});
  document.addEventListener('visibilitychange',()=>{
    if(document.hidden){releaseTouchControls();if(loadedExistingSave||startScreen.hidden)saveState(true);if(backgroundMusic&&!backgroundMusic.paused)backgroundMusic.pause()}
    else if(musicStarted)startBackgroundMusic();
  });
  contextButton.addEventListener('click',performContext);
  heatTutorialButton.addEventListener('click',dismissHeatTutorial);
  hubTutorialButton.addEventListener('click',dismissHubTutorial);
  hubBuildWall.addEventListener('click',()=>selectHubBuildTool('wall'));hubBuildLamp.addEventListener('click',()=>selectHubBuildTool('lamp'));hubBuildStorage.addEventListener('click',()=>selectHubBuildTool('storage'));hubBuildErase.addEventListener('click',()=>selectHubBuildTool('erase'));
  contextSecondaryButton.addEventListener('click',performSecondaryContext);
  starforgeChoices.addEventListener('click',event=>{const button=event.target.closest('[data-starforge]');if(button&&!button.disabled){unlockAudio();forgeStarVariant(button.dataset.starforge)}});
  inventoryButton.addEventListener('click',()=>{unlockAudio();releaseTouchControls();menuShade.hidden=true;openInventory()});inventoryCloseButton.addEventListener('click',closeInventory);
  autoSortButton.addEventListener('click',autoSortResources);buyChestButton.addEventListener('click',buyStorageChest);
  baseModuleList.addEventListener('click',event=>{const place=event.target.closest('[data-base-place]'),pack=event.target.closest('[data-base-pack]'),take=event.target.closest('[data-chest-take]');if(place)placeBaseModule(place.dataset.basePlace);else if(pack)packBaseModule(pack.dataset.basePack);else if(take)takeAllFromChest(take.dataset.chestTake)});
  inventoryShade.addEventListener('pointerdown',event=>{if(event.target===inventoryShade)closeInventory()});
  achievementPopup.addEventListener('animationend',event=>{if(event.animationName==='achievement-coin-rise'||event.animationName==='achievement-claim-reveal')settleAchievementPopup()});
  achievementPopup.addEventListener('click',openAchievementFromPopup);
  achievementProgress=loadAchievementProgress();initializeAchievements();
  syncAudioSettingsUI();
  continueButton.disabled=!loadedExistingSave;
  continueDetail.textContent=loadedExistingSave?(currentScene==='surface'?'SURFACE EXPEDITION':inHub()?'UNDERGROUND HUB':currentMine().name):'NO EXPEDITION FOUND';
  continueButton.addEventListener('click',enterGame);newGameButton.addEventListener('click',startNewGame);
  startAchievementsButton.addEventListener('click',()=>showOverlayMenu('achievements','start'));startSettingsButton.addEventListener('click',()=>showOverlayMenu('settings','start'));
  menuButton.addEventListener('click',()=>showOverlayMenu('settings','game'));
  settingsTab.addEventListener('click',()=>setMenuTab('settings'));statsTab.addEventListener('click',()=>setMenuTab('stats'));
  patchNotesButton.addEventListener('click',()=>setMenuTab('patchnotes'));
  resetProgressButton.addEventListener('click',resetAllProgress);
  musicToggle.addEventListener('click',()=>{unlockAudio();setAudioSetting('music',!audioSettings.music)});effectsToggle.addEventListener('click',()=>{unlockAudio();setAudioSetting('effects',!audioSettings.effects)});
  menuCloseButton.addEventListener('click',()=>{menuShade.hidden=true;syncAchievementPopup()});resumeButton.addEventListener('click',()=>{if(menuShade.dataset.view==='patchnotes'){setMenuTab('settings');return}menuShade.hidden=true;syncAchievementPopup()});
  menuShade.addEventListener('pointerdown',event=>{if(event.target===menuShade){menuShade.hidden=true;syncAchievementPopup()}});
  window.addEventListener('resize',resize,{passive:true});

  window.__everDeeperTest={
    snapshot:()=>JSON.parse(JSON.stringify({
      build:BUILD,patchNotes:PATCH_NOTES,state,scene:currentScene,depth:currentDepth,assetVersion:ASSET_VERSION,startMenu:{visible:!startScreen.hidden,hasSave:loadedExistingSave,actions:['continue','new-game','achievements','settings'],achievementsInPause:false},achievements:{storageKey:ACHIEVEMENTS_KEY,total:ACHIEVEMENT_DEFINITIONS.length,count:Object.keys(achievementProgress.records).length,definitions:ACHIEVEMENT_DEFINITIONS.map(({predicate,...definition})=>definition),records:achievementProgress.records,queue:achievementQueue.slice(),active:activeAchievementId,highlighted:highlightedAchievementId,settled:achievementPopupSettled,popupVisible:!achievementPopup.hidden,metrics:achievementMetrics()},music:{asset:MUSIC_PATH.split('?')[0],volume:MUSIC_VOLUME,loop:true,started:musicStarted,enabled:audioSettings.music,effectsEnabled:audioSettings.effects},controls:{floatingJoystick:true,activationSurface:'gameCanvas',pressAnywhere:true,independentMinePointer:true,joystickPointer:input.joystickPointer,moveX:input.moveX,moveY:input.moveY,mineHeld:input.mineHeld},hub:{unlocked:state.hub.unlocked,visited:state.hub.visited,active:inHub(),world:{...HUB_WORLD},grid:{...HUB_GRID},stations:JSON.parse(JSON.stringify(HUB_STATIONS)),costs:{wall:{...HUB_BUILD_COSTS.wall},lamp:{...HUB_BUILD_COSTS.lamp},storage:{gold:storageChestCost()}},tiles:state.hub.tiles.map(tile=>({...tile,...hubCellCenter(tile.col,tile.row)})),modules:allBaseModules().filter(module=>!module.packed&&module.scene==='hub').map(module=>({id:module.id,kind:module.kind,x:module.x,y:module.y})),buildMode:{active:hubBuild.active,selected:hubBuild.selected,touchDrag:true,fullRefund:true},tutorialVisible:!hubTutorialShade.hidden,deepElevatorOnline:false,functionalStorage:true,noPrestigeReset:true,surfaceLiftAsset:VOIDSTAR_PATHS.shaft},ambientLife:ambientLifeSnapshot(),worldLife:worldLifeSnapshot(),resourceRendering:{...RESOURCE_RENDER_CONTRACT,paths:DROP_PATHS,bounds:RESOURCE_IMAGE_BOUNDS},assetRendering:{stone:['node'],copper:['wall','node'],gold:['wall','node']},entranceAssetRendering:{mossMine:true,moonMine:true,emberMine:true,starMine:true},surfaceBoundaries:{walls:SURFACE_BOUNDARIES.map(boundary=>({...boundary,locked:!state[boundary.unlockKey]||!!activeSurfaceGateTransition(boundary.unlockKey)})),assets:SURFACE_BOUNDARY_PATHS,premiumAssets:true,fullHeightAssets:true,naturalAssetOpenings:true,legacyCanvasWalls:false,legacyRectangularGateCuts:false,groundBlendWidth:MOONGLASS_SURFACE_BLEND,gateOnlyPassage:true,persistentAfterUnlock:true,portalFocus:true},surfaceAssetRendering:{mossveinGround:true,mainRoad:SURFACE_ROAD_PATHS,seamlessBiomeRoad:true,roadCrossfadeWidth:80,mossveinMineApproach:MOSSVEIN_MINE_PATH,mossveinMineApproachBounds:{x:125,y:728,w:700,h:200},mossveinMinePosition:{x:180,y:830},branchUnderMainRoad:true,naturalCaveOverlap:true,naturalRoadOverlap:true,legacyBakedMainRoad:false,legacyMossveinGrid:false,legacyMossveinPath:false,legacyMossveinDecorations:false},starterRendering:{sellStation:STARTER_PATHS.sellStation,forgeStation:STARTER_PATHS.forgeStation,storageChest:STARTER_PATHS.storageChest,wayfarerShop:STARTER_PATHS.wayfarerShop,treasureClosed:STARTER_PATHS.treasureClosed,treasureOpen:STARTER_PATHS.treasureOpen,groundDrops:DROP_PATHS,legacyCanvasStations:false,legacyMossveinChests:false,legacyStarterDrops:false},rootwoundRendering:{floor:ROOTWOUND_PATHS.floor,wall:ROOTWOUND_PATHS.wall,nodes:['rootiron','deepstone','ambercore','burrowsteel'],rootironWall:ROOTWOUND_PATHS.rootironWall,shaft:ROOTWOUND_PATHS.shaft,sellStation:ROOTWOUND_PATHS.sellStation,drillForge:ROOTWOUND_PATHS.drillForge,legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyResourceNodes:false},
      surfaceMoonglassRendering:{ground:SURFACE_MOONGLASS_PATHS.ground,crystals:SURFACE_MOONGLASS_PATHS.crystals,bloomBed:SURFACE_MOONGLASS_PATHS.bloomBed,entrance:MINE_ENTRANCE_PATHS.moonMine,gateMark:STARTER_PATHS.moonglassGateMark,emberdeepSeal:STARTER_PATHS.emberdeepSeal,openBoundaryGatesRemoved:true,animatedGateTransition:true,smoothMossveinBlend:true,backgroundCrystalsDistinct:true,chests:{crystalCache:{closed:SURFACE_MOONGLASS_PATHS.crystalCacheClosed,open:SURFACE_MOONGLASS_PATHS.crystalCacheOpen},reliquary:{closed:SURFACE_MOONGLASS_PATHS.reliquaryClosed,open:SURFACE_MOONGLASS_PATHS.reliquaryOpen}},legacyGrid:false,legacyDecorations:false,legacyChests:false,legacyEntrance:false,legacyEmberdeepSeal:false},
      surfaceEmberdeepRendering:{ground:SURFACE_EMBERDEEP_PATHS.ground,slag:SURFACE_EMBERDEEP_PATHS.slag,faultBed:SURFACE_EMBERDEEP_PATHS.faultBed,minePath:SURFACE_EMBERDEEP_PATHS.minePath,minePathBounds:{...EMBERDEEP_MINE_PATH_BOUNDS},minePathRotation:EMBERDEEP_MINE_PATH_ROTATION,minePathPivot:{...EMBERDEEP_MINE_PATH_PIVOT},minePathMouthTarget:{x:2480,y:1015},entrance:MINE_ENTRANCE_PATHS.emberMine,entrancePosition:{...MINE_DEFINITIONS.emberMine.surfaceEntrance},entranceFlipped:true,gateSeal:STARTER_PATHS.emberdeepSeal,gateMark:STARTER_PATHS.emberdeepSealMark,animatedGateTransition:true,smoothMoonglassBlend:true,continuousBlendUnderlay:true,backgroundSlagDistinct:true,chests:{foundry:{closed:SURFACE_EMBERDEEP_PATHS.foundryClosed,open:SURFACE_EMBERDEEP_PATHS.foundryOpen},vault:{closed:SURFACE_EMBERDEEP_PATHS.vaultClosed,open:SURFACE_EMBERDEEP_PATHS.vaultOpen}},legacyGrid:false,legacyDecorations:false,legacyChests:false,legacyEntrance:false,legacyGate:false},
      surfaceStarfallRendering:{ground:SURFACE_STARFALL_PATHS.ground,shards:SURFACE_STARFALL_PATHS.shards,latticeBed:SURFACE_STARFALL_PATHS.latticeBed,minePath:SURFACE_STARFALL_PATHS.minePath,minePathBounds:{...STARFALL_MINE_PATH_BOUNDS},minePathMouthTarget:{x:3505,y:1000},entrance:MINE_ENTRANCE_PATHS.starMine,entrancePosition:{...MINE_DEFINITIONS.starMine.surfaceEntrance},gateSeal:STARTER_PATHS.starfallSeal,gateMark:STARTER_PATHS.starfallSealMark,starforge:STARTER_PATHS.starforgeStation,chests:{astralCache:{closed:SURFACE_STARFALL_PATHS.astralCacheClosed,open:SURFACE_STARFALL_PATHS.astralCacheOpen},celestialCoffer:{closed:SURFACE_STARFALL_PATHS.celestialCofferClosed,open:SURFACE_STARFALL_PATHS.celestialCofferOpen}},animatedGateTransition:true,smoothEmberdeepBlend:true,continuousBlendUnderlay:true,backgroundShardsDistinct:true,legacyGrid:false,legacyDecorations:false,legacyChests:false,legacyEntrance:false,legacyGate:false,legacyStarforge:false},
      moonglassRendering:{surfaceGround:SURFACE_MOONGLASS_PATHS.ground,surfaceCrystals:SURFACE_MOONGLASS_PATHS.crystals,bloomBed:SURFACE_MOONGLASS_PATHS.bloomBed,entrance:MINE_ENTRANCE_PATHS.moonMine,gateMark:STARTER_PATHS.moonglassGateMark,emberdeepSeal:STARTER_PATHS.emberdeepSeal,openBoundaryGatesRemoved:true,animatedGateTransition:true,smoothMossveinBlend:true,backgroundCrystalsDistinct:true,chests:{crystalCache:{closed:SURFACE_MOONGLASS_PATHS.crystalCacheClosed,open:SURFACE_MOONGLASS_PATHS.crystalCacheOpen},reliquary:{closed:SURFACE_MOONGLASS_PATHS.reliquaryClosed,open:SURFACE_MOONGLASS_PATHS.reliquaryOpen}},floor:MOONGLASS_PATHS.floor,wall:MOONGLASS_PATHS.wall,routeMarker:MOONGLASS_PATHS.routeMarker,pocket:MOONGLASS_PATHS.pocket,cache:MOONGLASS_PATHS.cache,shrine:MOONGLASS_PATHS.shrine,nodes:{moonglass:MOONGLASS_PATHS.moonglassNode,starshard:MOONGLASS_PATHS.starshardNode},wallHints:{moonglass:MOONGLASS_PATHS.moonglassWall,starshard:MOONGLASS_PATHS.starshardWall},barriers:{moon_prism_gate:MOONGLASS_PATHS.prismFault,moon_star_lock:MOONGLASS_PATHS.starGeode},drops:{moonglass:DROP_PATHS.moonglass,starshard:DROP_PATHS.starshard},legacySurfaceDecorations:false,legacyMineFloor:false,legacyMineTerrain:false,legacyMineWalls:false,legacyBarriers:false,legacyPocketRewards:false,legacyResourceNodes:false},
      prismaticRendering:{floor:PRISMATIC_PATHS.floor,wall:PRISMATIC_PATHS.wall,shaft:PRISMATIC_PATHS.shaft,sellStation:PRISMATIC_PATHS.sellStation,drillForge:PRISMATIC_PATHS.drillForge,pocket:PRISMATIC_PATHS.pocket,cache:PRISMATIC_PATHS.cache,shrine:PRISMATIC_PATHS.shrine,nodes:{prismite:PRISMATIC_PATHS.prismiteNode,deepstone:ROOTWOUND_PATHS.deepstone,lunacore:PRISMATIC_PATHS.lunacoreNode,phasecrystal:PRISMATIC_PATHS.phasecrystalNode},wallHints:{prismite:PRISMATIC_PATHS.prismiteWall,deepstone:PRISMATIC_PATHS.deepstoneWall,lunacore:PRISMATIC_PATHS.lunacoreWall,phasecrystal:PRISMATIC_PATHS.phasecrystalWall},drops:{deepstone:DROP_PATHS.deepstone,prismite:DROP_PATHS.prismite,lunacore:DROP_PATHS.lunacore,phasecrystal:DROP_PATHS.phasecrystal},legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyPocketRewards:false,legacyResourceNodes:false},
      emberdeepRendering:{floor:EMBERDEEP_PATHS.floor,wall:EMBERDEEP_PATHS.wall,routeMarker:EMBERDEEP_PATHS.routeMarker,pocket:EMBERDEEP_PATHS.pocket,cache:EMBERDEEP_PATHS.cache,shrine:EMBERDEEP_PATHS.shrine,nodes:{emberstone:EMBERDEEP_PATHS.emberstoneNode,moonglass:MOONGLASS_PATHS.moonglassNode,sunslag:EMBERDEEP_PATHS.sunslagNode},wallHints:{emberstone:EMBERDEEP_PATHS.emberstoneWall,moonglass:MOONGLASS_PATHS.moonglassWall,sunslag:EMBERDEEP_PATHS.sunslagWall},barriers:{ember_bulkhead:EMBERDEEP_PATHS.cinderBulkhead,ember_crucible_lock:EMBERDEEP_PATHS.crucibleSeal},drops:{emberstone:DROP_PATHS.emberstone,moonglass:DROP_PATHS.moonglass,sunslag:DROP_PATHS.sunslag},legacyMineFloor:false,legacyMineTerrain:false,legacyMineWalls:false,legacyBarriers:false,legacyPocketRewards:false,legacyResourceNodes:false},
      moltenRendering:{floor:MOLTEN_PATHS.floor,wall:MOLTEN_PATHS.wall,shaft:MOLTEN_PATHS.shaft,sellStation:MOLTEN_PATHS.sellStation,drillForge:MOLTEN_PATHS.drillForge,pocket:MOLTEN_PATHS.pocket,cache:MOLTEN_PATHS.cache,shrine:MOLTEN_PATHS.shrine,nodes:{magmaite:MOLTEN_PATHS.magmaiteNode,deepstone:MOLTEN_PATHS.deepstoneNode,furnaceheart:MOLTEN_PATHS.furnaceheartNode,infernium:MOLTEN_PATHS.inferniumNode},wallHints:{magmaite:MOLTEN_PATHS.magmaiteWall,deepstone:MOLTEN_PATHS.deepstoneWall,furnaceheart:MOLTEN_PATHS.furnaceheartWall,infernium:MOLTEN_PATHS.inferniumWall},drops:{deepstone:DROP_PATHS.deepstone,magmaite:DROP_PATHS.magmaite,furnaceheart:DROP_PATHS.furnaceheart,infernium:DROP_PATHS.infernium},legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyPocketRewards:false,legacyResourceNodes:false},
      starfallRendering:{floor:STARFALL_PATHS.floor,wall:STARFALL_PATHS.wall,routeMarker:STARFALL_PATHS.routeMarker,pocket:STARFALL_PATHS.pocket,cache:STARFALL_PATHS.cache,shrine:STARFALL_PATHS.shrine,nodes:{astralite:STARFALL_PATHS.astraliteNode,crownstone:STARFALL_PATHS.crownstoneNode},wallHints:{astralite:STARFALL_PATHS.astraliteWall,crownstone:STARFALL_PATHS.crownstoneWall},barriers:{star_bridge_lock:STARFALL_PATHS.astralBridgeLock,star_crown_lock:STARFALL_PATHS.crownstoneWard},drops:{astralite:DROP_PATHS.astralite,crownstone:DROP_PATHS.crownstone},legacyFloor:false,legacyTerrain:false,legacyWalls:false,legacyBarriers:false,legacyRewards:false,legacyNodes:false},
      voidstarRendering:{floor:VOIDSTAR_PATHS.floor,wall:VOIDSTAR_PATHS.wall,shaft:VOIDSTAR_PATHS.shaft,sellStation:VOIDSTAR_PATHS.sellStation,drillForge:VOIDSTAR_PATHS.drillForge,pocket:VOIDSTAR_PATHS.pocket,cache:VOIDSTAR_PATHS.cache,shrine:VOIDSTAR_PATHS.shrine,nodes:{voidglass:VOIDSTAR_PATHS.voidglassNode,deepstone:VOIDSTAR_PATHS.deepstoneNode,singularity:VOIDSTAR_PATHS.singularityNode},wallHints:{voidglass:VOIDSTAR_PATHS.voidglassWall,deepstone:VOIDSTAR_PATHS.deepstoneWall,singularity:VOIDSTAR_PATHS.singularityWall},drops:{deepstone:DROP_PATHS.deepstone,voidglass:DROP_PATHS.voidglass,singularity:DROP_PATHS.singularity},legacyFloor:false,legacyTerrain:false,legacyWalls:false,legacyRewards:false,legacyNodes:false,legacyShaft:false,legacyStations:false},
      discoveryRendering:{crystalPocketAsset:'assets/mossvein/magic-crystal-pocket.png',cacheAsset:MOSSVEIN_REWARD_PATHS.cache,shrineAsset:MOSSVEIN_REWARD_PATHS.shrine,legacyCavernRings:false,legacyMossveinPocketRewards:false,biomeGlow:true,routineDiscoveryText:false,rareDiscoveryText:false},bonusVeinRendering:{worldLabels:false,textPrompts:false,sleepingCracks:true,movingReadyPulse:true,radialTimer:true,completionBurst:true},miningFeedbackRendering:{routineImpactRings:false,routineBreakRings:false,routineImpactParticles:false,routineBreakParticles:false,discoveryCanvasBursts:false,upgradeCanvasRings:false,routineDamageText:false,routineBreakText:false,routinePickupText:false,majorEventTextOnly:true,premiumTerrainResponses:true,dedicatedImpactSheets:true,nonStackingImpactAssets:true,premiumSaleAssets:true,drillVibration:true,drillVibrationMaxOffset:2.05,cameraShake:false},characterRendering:{baseAsset:'assets/characters/miner-b.png',activeToolKey:currentPlayerToolKey(),activeRenderAsset:state.drillLevel?PLAYER_DRILL_CHARACTER_PATHS[currentPlayerToolKey()]:PLAYER_TOOL_PATHS[currentPlayerToolKey()],walkSheets:PLAYER_WALK_PATHS,activeWalkAsset:activePlayerWalkPath(),walkGrid:{columns:PLAYER_RENDER_CONTRACT.walkColumns,rows:PLAYER_RENDER_CONTRACT.walkRows,cellSize:PLAYER_RENDER_CONTRACT.walkCellSize,directions:PLAYER_WALK_DIRECTIONS},walkRenderSize:PLAYER_RENDER_CONTRACT.walkRenderSize,toolLayerCount:Object.keys(PLAYER_TOOL_PATHS).length,drillCompositeCount:Object.keys(PLAYER_DRILL_CHARACTER_PATHS).length,gripCrop:PLAYER_RENDER_CONTRACT.gripCrop,gripPivot:PLAYER_RENDER_CONTRACT.gripPivot,gripPoint:PLAYER_RENDER_CONTRACT.gripPoint,layeredTools:PLAYER_RENDER_CONTRACT.layeredTools,animatedGrip:PLAYER_RENDER_CONTRACT.animatedGrip,bodyReaction:PLAYER_RENDER_CONTRACT.bodyReaction,sharedGripAnchor:PLAYER_RENDER_CONTRACT.sharedGripAnchor,fullDrillComposites:PLAYER_RENDER_CONTRACT.fullDrillComposites,directionalWalk:PLAYER_RENDER_CONTRACT.directionalWalk,distanceDrivenWalk:PLAYER_RENDER_CONTRACT.distanceDrivenWalk,holsteredWalkTools:PLAYER_RENDER_CONTRACT.holsteredWalkTools,lazyDrillWalkSheets:PLAYER_RENDER_CONTRACT.lazyDrillWalkSheets,staticMiningFallback:PLAYER_RENDER_CONTRACT.staticMiningFallback,reducedMotion,legacyDrillLimbCrops:PLAYER_RENDER_CONTRACT.legacyDrillLimbCrops,legacyCanvasCharacter:PLAYER_RENDER_CONTRACT.legacyCanvasCharacter,legacyCanvasTools:PLAYER_RENDER_CONTRACT.legacyCanvasTools},mineralNodeRenderScale:MINERAL_NODE_RENDER_SCALE,
      starterGateRendering:{moonglassGate:STARTER_PATHS.moonglassGate,moonglassGateMark:STARTER_PATHS.moonglassGateMark,emberdeepSeal:STARTER_PATHS.emberdeepSeal,emberdeepSealMark:STARTER_PATHS.emberdeepSealMark,starfallSeal:STARTER_PATHS.starfallSeal,starfallSealMark:STARTER_PATHS.starfallSealMark,renderBounds:{maxWidth:260,maxHeight:238,bottom:110},markRenderWidth:GATE_MARK_RENDERING.width,markSourceBounds:{moonglass:{x:14,y:55,w:484,h:222},emberdeep:{x:28,y:6,w:456,h:329},starfall:{x:34,y:54,w:449,h:231}},collisionFollowsPaintedCliff:true,integratedBoundaryScale:true,biomeAlignedPerspective:true,northSouthStructure:true,westEastPassage:true,premiumEnergyBarrier:true,duplicateCanvasSeam:false,proceduralGateShadow:false,animatedMoonglassTransition:true,animatedEmberdeepTransition:true,animatedStarfallTransition:true,activationSequence:['flash','shake','sink'],assetSilhouetteFlash:true,preSinkShake:true,unscaledGroundSink:true,collisionLocksUntilSunk:true,reducedMotionSafe:true,openWorldGatesRemoved:true,legacyStarterGate:false},
      effectivePickaxe:{name:currentPickaxeName(),power:currentPower(),cooldown:currentCooldown(),shellPower:currentShellPower(),bonusYield:currentBonusYieldChance(),emberstoneHits:armoredHitsRequired('emberstone',currentPower(),currentShellPower()),sunslagHits:armoredHitsRequired('sunslag',currentPower(),currentShellPower()),astraliteHits:armoredHitsRequired('astralite',currentPower(),currentShellPower()),depthMainHits:currentMine()&&currentDepth===2?armoredHitsRequired(DEPTH2_RESOURCE_PROFILES[currentScene].main,currentPower(),currentShellPower()):null},
      goal:mainGoal(),progression:{finalVictory:{completed:!!state.victory,requiresDrill:'Deepcore Drill',resource:'singularity',scene:'starMine',depth:2},endgame:{hubUnlocked:state.hub.unlocked,hubVisited:state.hub.visited,noPrestigeReset:true,deepElevatorOnline:false}},guide:(()=>{const guide=visualGuide();return guide?{...guide,distance:distance(player.x,player.y,guide.x,guide.y),visible:distance(player.x,player.y,guide.x,guide.y)>guide.closeRadius}:null})(),markerStyle:{bonusVeinRings:false},toolMode:inHub()?'builder':state.drillLevel?'drill':'pickaxe',protectedCargo:protectedProgressCargo(),sellableCargo:sellableCargo(),movement:{level:state.movementSpeedLevel,multiplier:movementSpeedMultiplier(),nextCost:movementSpeedCost()},miningRush:{...miningRush},heatStreak:{unlocked:heatStreakUnlocked(),active:heatStreak.active,elapsed:heatStreak.elapsed,progress:heatStreakProgress(),speedMultiplier:heatStreakSpeed(),maxSpeed:HEAT_STREAK_MAX_SPEED,buildSeconds:HEAT_STREAK_BUILD_SECONDS,tutorialVisible:!heatTutorialShade.hidden},lootSweep:{remaining:lootSweepRemaining(),nextAt:state.nextLootSweepAt},
      player:{x:player.x,y:player.y,aimX:player.aimX,aimY:player.aimY,direction:player.direction,moving:player.moving,walkFrame:player.walkFrame,walkDistance:player.walkDistance},camera:{x:camera.x,y:camera.y,viewWidth,viewHeight},biome:currentBiome().id,moonglassGateTransition:moonglassGateTransition?{active:true,progress:clamp(moonglassGateTransition.elapsed/moonglassGateTransition.duration,0,1)}:{active:false,progress:state.areaUnlocked?1:0},emberdeepGateTransition:emberdeepGateTransition?{active:true,progress:clamp(emberdeepGateTransition.elapsed/emberdeepGateTransition.duration,0,1)}:{active:false,progress:state.emberdeepUnlocked?1:0},starfallGateTransition:starfallGateTransition?{active:true,progress:clamp(starfallGateTransition.elapsed/starfallGateTransition.duration,0,1)}:{active:false,progress:state.fourthUnlocked?1:0},
      lighting:{enabled:!!lightCtx&&(!!currentMine()||inHub()),technique:inHub()?'hub-ambient-lightmap':'low-resolution-raycast-lightmap',occlusion:!inHub(),readableTextOverlay:true,textPass:'after-lighting',bufferScale:LIGHTING.bufferScale,bufferWidth:lightCanvas?lightCanvas.width:0,bufferHeight:lightCanvas?lightCanvas.height:0,darkness:inHub()?0.53:currentDepth===2?LIGHTING.darknessDepth2:LIGHTING.darknessDepth1,beamLength:LIGHTING.beamLength,beamHalfAngle:LIGHTING.beamHalfAngle,maxOreLights:LIGHTING.maxOreLights,maxNaturalLights:LIGHTING.maxNaturalLights,depthLampAsset:MINE_ENTRANCE_PATHS.depthLamp,oreLights:currentMine()?lightingOreCount:0,naturalLights:currentMine()||inHub()?lightingLastSources.length:0,sources:currentMine()||inHub()?lightingLastSources:[],hierarchy:{stone:LIGHTING.stoneIntensity,rockOre:LIGHTING.rockOreIntensity,rareRockOre:LIGHTING.rareRockOreIntensity,wallOre:LIGHTING.wallOreIntensity,rareWallOre:LIGHTING.rareWallOreIntensity,depthLamp:LIGHTING.depthLampIntensity,bonusCrystalCollected:LIGHTING.collectedBonusCrystalIntensity,bonusCrystal:LIGHTING.bonusCrystalIntensity},rayChecks:currentMine()?lightingRayChecks:0},
      mine:currentMine()?{
        id:currentMine().id,name:currentMineVisual().name,depth:currentDepth,width:currentMine().width,height:currentMine().height,style:currentMineVisual().style,visualPass:mineVisualPass(),dirt:currentMineVisual().dirt,floor:currentMineVisual().floor,solids:currentDepth===1?currentMine().solids:[],solidCount:currentDepth===1?currentMine().solids.length:0,barrierIds:currentDepth===1?currentMine().barriers.map(barrier=>barrier.id):[],deepAccess:currentDepth===1?currentMine().solids.find(solid=>solid.role==='deepAccessWall')||null:null,deepAccessWallAsset:currentDepth===1?depthOneWallAssetPath():null,unbreakableWallAsset:currentDepth===1?depthOneWallAssetPath():null,unbreakableWallPremiumAsset:true,mineableTerrainUsesUnbreakableAsset:false,legacyCanvasSolidWalls:false,deepAccessPremiumAsset:true,legacyCanvasDeepAccessFace:false,visibleWallFaces:true,labels:currentDepth===1?currentMine().labels.map(label=>label[0]):[],
        depthEntrance:{...depthEntrances[currentScene],discovered:!!state.discoveredDepthEntrances[currentScene],boundaryIndex:mineTerrain[currentScene][1].depthEntrance?[...mineTerrain[currentScene][1].depthEntrance.boundary][0]:null,resourceClearance:DEPTH_PORTAL_RESOURCE_CLEARANCE},depthStations:currentDepth===2?{...depthStations(),resourceClearance:DEPTH_STATION_RESOURCE_CLEARANCE}:null,depthResources:currentDepth===2?{...DEPTH2_RESOURCE_PROFILES[currentScene]}:null,
        terrain:{tileSize:MINE_TILE_SIZE,chunkCells:MINE_CHUNK_CELLS,maxHp:currentTerrain().maxHp,totalChunks:Math.ceil(currentTerrain().cols/MINE_CHUNK_CELLS)*Math.ceil(currentTerrain().rows/MINE_CHUNK_CELLS),activeChunks:currentTerrain().chunks.size,cellCount:currentTerrain().cols*currentTerrain().rows,solidCells:terrainSolidCellCount(currentTerrain()),dugCells:state.terrainDug[currentTerrain().stateKey].length,target:nearestTerrainCell(MINING_RANGE),mineralHints:currentMineralHints().map(hint=>({rockId:hint.rock.id,type:hint.rock.type,index:hint.index,sides:hint.sides.slice()}))},
        discovery:{caverns:currentTerrain().caverns.map(cavern=>({id:cavern.id,name:cavern.name,x:cavern.x,y:cavern.y,rx:cavern.rx,ry:cavern.ry,cellCount:cavern.cells.length,boundaryIndex:[...cavern.boundary][0],discovered:cavernIsDiscovered(cavern.id),reward:{...cavern.reward,claimed:!!state.claimedPocketRewards[cavern.reward.id]}})),deposits:discoveriesFor(currentScene,currentDepth).deposits.map(deposit=>({id:deposit.id,type:deposit.type,size:deposit.positions.length,rareFind:!!deposit.rareFind,cavernId:deposit.cavernId||null,pocketRewardId:deposit.pocketRewardId||null,requiresDrillLevel:deposit.requiresDrillLevel||0,drillGated:!!deposit.drillGated}))}
      }:null,
      focus:miningFocus,
      rocks:rocks.map(rock=>({id:rock.id,type:rock.type,x:rock.x,y:rock.y,scene:rock.scene,depth:rock.depth||1,barrierId:rock.barrierId,requiredPickaxe:rock.requiredPickaxe,requiresDeepTool:rock.requiresDeepTool,requiresDrillLevel:rock.requiresDrillLevel||0,veinId:rock.veinId,depositId:rock.depositId,cavernId:rock.cavernId,rareFind:rock.rareFind,pocketRewardId:rock.pocketRewardId,hp:rock.hp,shell:rock.shell,broken:rock.broken,exposed:rockIsExposed(rock)})),
      veins:veins.map(vein=>({id:vein.id,status:vein.status,timer:vein.timer,broken:vein.brokenRockIds.size,total:vein.positions.length})),
      chests:chests.map(chest=>({id:chest.id,name:chest.name,x:chest.x,y:chest.y,ready:chestRequirementMet(chest),opened:!!state.openedChests[chest.id]})),
      groundDrops:groundDrops.map(drop=>({id:drop.id,type:drop.type,amount:drop.amount,x:drop.x,y:drop.y,z:drop.z,age:drop.age,settled:drop.settled,scene:drop.scene,depth:drop.depth,sourceChest:drop.sourceChest,sourcePocket:drop.sourcePocket})),feedback:{floaters:floaters.map(item=>item.text),pickupCount:pickupBatch.count,particleCount:0,shake:miningFeedback.shake,flash:miningFeedback.flash,hitStop:miningFeedback.hitStop,terrainHitIndex:miningFeedback.terrainHitIndex,lastDiscovery:miningFeedback.lastDiscovery,lastDepositBeat:miningFeedback.lastDepositBeat,lastPocketReward:miningFeedback.lastPocketReward},activeContext
    })),
    reset:resetProgress,
    resetAll:resetAllProgress,
    evaluateAchievements:()=>evaluateAchievements(),
    settleAchievement:()=>settleAchievementPopup(),
    dismissAchievement:()=>dismissAchievementPopup(),
    dismissHeatTutorial:()=>dismissHeatTutorial(),
    dismissHubTutorial:()=>dismissHubTutorial(),
    openAchievementPopup:()=>openAchievementFromPopup(),
    openAchievements:()=>showOverlayMenu('achievements','start'),
    dismissStartMenu:enterGame,
    startMusic:()=>{startBackgroundMusic();return backgroundMusic?{src:backgroundMusic.src,volume:backgroundMusic.volume,loop:backgroundMusic.loop,paused:backgroundMusic.paused}:null},
    setAudioSetting:(kind,enabled)=>setAudioSetting(kind,enabled),
    setPosition:(x,y)=>{const world=currentWorld();player.x=clamp(Number(x),52,world.width-52);player.y=clamp(Number(y),70,world.height-58);player.moving=false;updateCamera(true);uiDirty=true},
    surfaceBoundaryBlockedAt:(x,y)=>surfaceBoundaryCollides(Number(x),Number(y)),
    mineCollisionAt:(x,y)=>collidesWithMine(Number(x),Number(y)),
    hubCollisionAt:(x,y)=>hubWallCollision(Number(x),Number(y)),
    setMoveVector:(x,y)=>{input.moveX=clamp(Number(x)||0,-1,1);input.moveY=clamp(Number(y)||0,-1,1);return{x:input.moveX,y:input.moveY}},
    stopMove:()=>{input.moveX=0;input.moveY=0;player.moving=false;return true},
    setMiningHeld:value=>{input.mineHeld=!!value;if(!input.mineHeld)resetHeatStreak();else startSwing(true);return input.mineHeld},
    setReducedMotion:value=>{reducedMotion=!!value;player.walkFrame=reducedMotion?0:Math.floor(player.walkPhase)%PLAYER_RENDER_CONTRACT.walkColumns;if(reducedMotion)terrainResponses.length=0;return reducedMotion},
    setAim:(x,y)=>{const length=Math.hypot(Number(x)||0,Number(y)||0);if(length){player.aimX=Number(x)/length;player.aimY=Number(y)/length;player.facing=player.aimX<0?-1:1}},
    sampleHeadlampRay:()=>{const angle=Math.atan2(player.aimY,player.aimX),helmet=playerHelmetLightOffsets();return traceLightDistance(player.x+helmet.traceX,player.y+helmet.traceY,angle,LIGHTING.beamLength,currentTerrain(),activeMineSolids(),currentWorld())},
    setSwingProgress:value=>{const progress=clamp(Number(value)||0,0,1);player.swing={elapsed:progress,duration:1,hit:false,precision:false,target:'rock'};return{...playerRenderPose()}},
    clearSwing:()=>{player.swing=null;return{...playerRenderPose()}},
    mineOnce:()=>{if(player.swingCooldown>0)update(player.swingCooldown+.001);if(startSwing(true)){update(currentCooldown());update(.021);return true}return false},
    step:seconds=>update(clamp(Number(seconds)||0,0,2)),
    setTimeScale:value=>{timeScale=clamp(Number(value)||1,.25,12)},
    restoreRocks:()=>{for(const rock of rocks){rock.broken=!!(rock.barrierId&&state.clearedMineBarriers[rock.barrierId]||rock.pocketRewardId&&state.claimedPocketRewards[rock.pocketRewardId]);rock.hp=rock.maxHp;rock.shell=rock.maxShell;rock.respawn=rock.broken?Infinity:0;rock.glintActive=0;rock.bonusYield=0}resetVeins();uiDirty=true},
    restoreTerrain:()=>{for(const scene of MINE_SCENES){for(const depth of [1,2]){state.terrainDug[terrainStateKey(scene,depth)]=[];for(const cavern of discoveriesFor(scene,depth).caverns){state.discoveredCaverns[cavern.id]=false;state.claimedPocketRewards[cavern.reward.id]=false;delete state.pendingPocketLoot[cavern.reward.id]}}state.discoveredDepthEntrances[scene]=false;state.visitedDepths[scene]=false}for(const rock of mineRocks)if(rock.pocketRewardId){rock.broken=false;rock.respawn=0;rock.hp=rock.maxHp;rock.shell=rock.maxShell}currentDepth=1;rebuildMineTerrain();uiDirty=true},
    mineTerrainCell:index=>{hitTerrain(Number(index));return terrainTypeAt(currentTerrain(),Number(index)%currentTerrain().cols,Math.floor(Number(index)/currentTerrain().cols))},
    primePrecision:()=>{const rock=nearestRock(MINING_RANGE);if(rock){rock.glintActive=.72;return rock.id}return null},
    grantCargo:(type,amount)=>{if(Object.prototype.hasOwnProperty.call(state.cargo,type)){state.cargo[type]+=Math.max(0,Number(amount)||0);uiDirty=true}},
    grantMined:(type,amount)=>{if(Object.prototype.hasOwnProperty.call(state.mined,type)){state.mined[type]+=Math.max(0,Number(amount)||0);uiDirty=true}},
    breakVeinRock:(veinId,index)=>{const candidates=rocks.filter(rock=>rock.veinId===veinId);const rock=candidates[Math.max(0,Math.min(candidates.length-1,Number(index)||0))];if(rock&&!rock.broken){rock.shell=0;rock.hp=0;breakRock(rock);return rock.id}return null},
    breakDepositRock:(depositId,index)=>{const candidates=rocks.filter(rock=>rock.depositId===depositId);const rock=candidates[Math.max(0,Math.min(candidates.length-1,Number(index)||0))];if(rock&&!rock.broken){rock.shell=0;rock.hp=0;breakRock(rock);return rock.id}return null},
    hitDepositRock:(depositId,index)=>{const candidates=rocks.filter(rock=>rock.depositId===depositId);const rock=candidates[Math.max(0,Math.min(candidates.length-1,Number(index)||0))];if(!rock||rock.broken)return null;const before={hp:rock.hp,shell:rock.shell};hitRock(rock,false);return{id:rock.id,type:rock.type,before,after:{hp:rock.hp,shell:rock.shell},requiresDrillLevel:rock.requiresDrillLevel||0}},
    claimPocketReward:id=>{const terrain=currentTerrain(),cavern=terrain&&terrain.caverns.find(item=>item.reward.id===id);return claimPocketReward(cavern)},
    renderOnce:draw,
    grantGold:amount=>{state.gold+=Math.max(0,Number(amount)||0);uiDirty=true},
    buyMovementSpeed:()=>buyMovementSpeed(),
    activateMiningRush:()=>activateMiningRush(),
    openInventory:()=>openInventory(),
    autoSort:()=>autoSortResources(),
    buyStorageChest:()=>buyStorageChest(),
    placeBaseModule:id=>placeBaseModule(id),
    packBaseModule:id=>packBaseModule(id),
    takeAllFromChest:id=>takeAllFromChest(id),
    setHubBuildMode:value=>setHubBuildMode(value),
    selectHubBuildTool:kind=>selectHubBuildTool(kind),
    placeHubCell:(kind,col,row)=>{if(!inHub()||!selectHubBuildTool(kind))return false;const changed=placeHubCell(Math.floor(Number(col)),Math.floor(Number(row)));if(changed){updateHubBuildControls();uiDirty=true;saveState(true)}return changed},
    removeHubCell:(col,row)=>{if(!inHub())return false;const changed=removeHubCell(Math.floor(Number(col)),Math.floor(Number(row)));if(changed){updateHubBuildControls();uiDirty=true;saveState(true)}return changed},
    setPickaxeLevel:level=>{state.pickaxeLevel=clamp(Math.floor(Number(level)||1),1,PICKAXES.length-1);if(state.pickaxeLevel<PICKAXES.length-1){state.emberMastery=0;state.starforgeVariant=null}uiDirty=true},
    setDrillLevel:level=>{state.drillLevel=clamp(Math.floor(Number(level)||0),0,DRILLS.length-1);resetHeatStreak();ensurePlayerWalkSheet();uiDirty=true},
    startMoonglassGateTransition:()=>{state.areaUnlocked=true;state.discoveredSecond=false;moonglassGateTransition={elapsed:0,duration:MOONGLASS_GATE_TRANSITION_DURATION};uiDirty=true;return true},
    startEmberdeepGateTransition:()=>{state.emberdeepUnlocked=true;state.discoveredThird=false;emberdeepGateTransition={elapsed:0,duration:EMBERDEEP_GATE_TRANSITION_DURATION};uiDirty=true;return true},
    startStarfallGateTransition:()=>{state.fourthUnlocked=true;state.discoveredFourth=false;starfallGateTransition={elapsed:0,duration:STARFALL_GATE_TRANSITION_DURATION};uiDirty=true;return true},
    unlockAllAreas:()=>{state.areaUnlocked=true;state.discoveredSecond=true;state.emberdeepUnlocked=true;state.discoveredThird=true;moonglassGateTransition=null;emberdeepGateTransition=null;uiDirty=true},
    unlockStarfall:()=>{state.fourthUnlocked=true;state.discoveredFourth=true;starfallGateTransition=null;uiDirty=true},
    unlockHub:()=>{state.victory=true;state.hub.unlocked=true;state.hub.tutorialSeen=true;uiDirty=true;saveState(true);return true},
    spawnGroundDrops:(type,amount,x=player.x+80,y=player.y)=>spawnGroundDrop(type,amount,x,y),
    collectGroundDrops:()=>{for(const drop of groundDrops)if(drop.scene===currentScene&&drop.depth===currentDepth){drop.x=player.x;drop.y=player.y;drop.z=0;drop.settled=true}updateGroundDrops(.001);uiDirty=true},
    expireGroundDrops:()=>performGlobalLootSweep(false),
    forceGlobalLootSweep:()=>performGlobalLootSweep(false),
    forgeStarVariant:id=>forgeStarVariant(id),
    setStarforgeVariant:id=>{if(STARFORGE_VARIANTS[id]){state.starforgeUnlocked[id]=true;state.starforgeVariant=id;state.pickaxeLevel=PICKAXES.length-1;state.emberMastery=EMBER_MASTERY.length-1;uiDirty=true;return true}return false},
    upgradeDrill:()=>upgradeDrill(),
    sellCargo:()=>sellCargo(),
    enterMine:(scene='mossMine')=>transitionScene(scene),
    exitMine:()=>transitionScene('surface'),
    enterHub:()=>transitionHub(true),
    exitHub:()=>transitionHub(false),
    clearMineBarrier:id=>{const barrier=mineBarrierById(id);if(!barrier)return false;state.clearedMineBarriers[id]=true;for(const rock of mineRocks)if(rock.barrierId===id){rock.broken=true;rock.respawn=Infinity}uiDirty=true;return true},
    discoverCavern:id=>{const terrain=currentTerrain(),cavern=terrain&&terrain.caverns.find(item=>item.id===id);if(!cavern)return false;state.discoveredCaverns[cavern.id]=true;uiDirty=true;return true},
    discoverDepthEntrance:()=>{const entrance=currentTerrain()&&currentTerrain().depthEntrance;if(!entrance)return false;for(const index of entrance.boundary){while(terrainTypeAt(currentTerrain(),index%currentTerrain().cols,Math.floor(index/currentTerrain().cols)))hitTerrain(index);break}return !!state.discoveredDepthEntrances[currentScene]},
    enterDepth:()=>transitionMineDepth(2),
    exitDepth:()=>transitionMineDepth(1),
    openChest:id=>openChest(chestById(id)),
    interact:performContext,
    save:()=>saveState(true)
  };

  resize();updateUI();if(loadedExistingSave)saveState(true);requestAnimationFrame(frame);
})();
