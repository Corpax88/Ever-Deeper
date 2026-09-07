(function(global){
  'use strict';

  const WORLD={width:4480,height:1280,gateX:1110,emberGateX:2240,starfallGateX:3360,gateY:650,gateHalfGap:118};
  const HUB_WORLD=Object.freeze({width:1440,height:960});
  const HUB_GRID=Object.freeze({tileSize:48,originX:192,originY:240,cols:22,rows:10});
  const HUB_STATIONS=Object.freeze({
    surfaceEntrance:Object.freeze({x:4245,y:650,radius:146}),
    surfaceLift:Object.freeze({x:240,y:820,radius:126}),
    deepElevator:Object.freeze({x:720,y:142,radius:132})
  });
  const HUB_BUILD_COSTS=Object.freeze({
    wall:Object.freeze({resource:'stone',amount:5}),
    lamp:Object.freeze({gold:80})
  });
  const MINE_DEFINITIONS={
    mossMine:{
      id:'mossMine',name:'MOSSVEIN MINE',surfaceName:'MOSSVEIN QUARRY',width:1920,height:5120,entrance:{x:145,y:640},surfaceEntrance:{x:180,y:830,radius:112},
      unlock:()=>true,accent:'#d2a65b',detail:'#e9cf8c',floor:'#1b241c',wall:'#34372e',wallEdge:'#716b4d',style:'moss',finalGoal:'Mine the Gilded Heart',
      solids:[{x:0,y:0,w:1920,h:145},{x:0,y:4975,w:1920,h:145},{x:585,y:145,w:125,h:345},{x:585,y:790,w:125,h:345},{x:1190,y:145,w:125,h:345},{x:1190,y:790,w:125,h:345},{x:0,y:1135,w:1315,h:565,role:'deepAccessWall',barrierId:'iron_seam'}],
      barriers:[{id:'outer_rubble',x:620,y:490,w:76,h:300,requiresPickaxe:1,label:'Loose Rubble',objective:'Break through the loose rubble'},{id:'iron_seam',x:1225,y:490,w:76,h:300,requiresPickaxe:2,label:'Ironbound Collapse'}],
      rocks:[['stone',285,350],['stone',430,530],['stone',260,890],['copper',465,940],['stone',655,590,'outer_rubble'],['stone',655,640,'outer_rubble'],['stone',655,690,'outer_rubble'],['stone',835,335],['copper',930,495],['stone',1040,760],['copper',845,950],['copper',1085,1020],['stone',1260,590,'iron_seam'],['stone',1260,640,'iron_seam'],['stone',1260,690,'iron_seam'],['copper',1450,350],['copper',1650,470],['copper',1435,885],['gold',1680,820],['gold',1535,1010]],
      labels:[['OLD WORKINGS',360,205,'#b8ad82'],['COPPER CHAMBER',945,205,'#dc9c65'],['GILDED HEART',1570,205,'#ffe18a']]
    },
    moonMine:{
      id:'moonMine',name:'MOONGLASS LABYRINTH',surfaceName:'MOONGLASS CAVERN',width:1680,height:5760,entrance:{x:150,y:1180},surfaceEntrance:{x:1450,y:850,radius:112},
      unlock:state=>state.areaUnlocked,accent:'#71e3df',detail:'#c8a7ff',floor:'#10272a',wall:'#18363b',wallEdge:'#4c8d91',style:'moon',finalGoal:'Reach the Starshard Sanctum',
      solids:[{x:0,y:0,w:1680,h:135},{x:0,y:5625,w:1680,h:135},{x:480,y:135,w:110,h:435},{x:480,y:825,w:110,h:480},{x:1000,y:135,w:110,h:230},{x:1000,y:650,w:110,h:655},{x:590,y:1010,w:260,h:85},{x:0,y:1305,w:1110,h:420,role:'deepAccessWall',barrierId:'moon_star_lock'}],
      barriers:[{id:'moon_prism_gate',x:497,y:570,w:76,h:255,requiresPickaxe:3,label:'Prismatic Fault'},{id:'moon_star_lock',x:1017,y:365,w:76,h:285,requiresPickaxe:4,label:'Starbound Geode'}],
      rocks:[['copper',270,1050],['moonglass',335,820],['moonglass',280,420],['moonglass',535,645,'moon_prism_gate'],['moonglass',535,695,'moon_prism_gate'],['moonglass',535,745,'moon_prism_gate'],['moonglass',760,1160],['moonglass',760,760],['moonglass',830,430],['starshard',910,245],['moonglass',1055,455,'moon_star_lock'],['moonglass',1055,505,'moon_star_lock'],['moonglass',1055,555,'moon_star_lock'],['moonglass',1270,310],['moonglass',1420,560],['moonglass',1275,890],['starshard',1445,1120],['starshard',1270,1230]],
      labels:[['LOWER CRYSTALS',300,1260,'#78d9d7'],['REFRACTION HALL',790,700,'#c8a7ff'],['STARSHARD SANCTUM',1335,205,'#efe0ff']]
    },
    emberMine:{
      id:'emberMine',name:'EMBERDEEP WORKS',surfaceName:'EMBERDEEP FOUNDRY',width:1880,height:6400,entrance:{x:145,y:1030},surfaceEntrance:{x:2480,y:970,radius:112},
      unlock:state=>state.emberdeepUnlocked,accent:'#ff7543',detail:'#ffc06f',floor:'#251817',wall:'#39201c',wallEdge:'#8f4b32',style:'ember',finalGoal:'Claim the Sunslag Crucible',
      solids:[{x:0,y:0,w:1880,h:145},{x:0,y:6255,w:1880,h:145},{x:500,y:145,w:110,h:390},{x:500,y:720,w:110,h:415},{x:1210,y:145,w:110,h:215},{x:1210,y:545,w:110,h:590},{x:770,y:360,w:250,h:190},{x:770,y:820,w:250,h:190},{x:0,y:1135,w:1320,h:440,role:'deepAccessWall',barrierId:'ember_crucible_lock'}],
      barriers:[{id:'ember_bulkhead',x:517,y:535,w:76,h:185,requiresPickaxe:4,label:'Cinder Bulkhead'},{id:'ember_crucible_lock',x:1227,y:360,w:76,h:185,requiresPickaxe:5,label:'Crucible Seal'}],
      rocks:[['moonglass',250,930],['emberstone',310,690],['emberstone',300,350],['emberstone',555,575,'ember_bulkhead'],['emberstone',555,625,'ember_bulkhead'],['emberstone',555,675,'ember_bulkhead'],['emberstone',700,1050],['emberstone',720,680],['emberstone',910,680],['emberstone',1100,960],['emberstone',1265,400,'ember_crucible_lock'],['emberstone',1265,452,'ember_crucible_lock'],['emberstone',1265,505,'ember_crucible_lock'],['emberstone',1445,270],['emberstone',1615,470],['emberstone',1475,800],['sunslag',1660,980],['sunslag',1480,1060]],
      labels:[['COOLING TUNNELS',290,1090,'#caa77d'],['FURNACE MAZE',900,700,'#ff8a52'],['SUNSLAG CRUCIBLE',1540,205,'#ffd27d']]
    },
    starMine:{
      id:'starMine',name:'STARFALL HOLLOW',surfaceName:'STARFALL DEPTHS',width:2200,height:7200,entrance:{x:160,y:750},surfaceEntrance:{x:3505,y:1000,radius:112},
      unlock:state=>state.fourthUnlocked,accent:'#b8c3ff',detail:'#f0ddff',floor:'#121329',wall:'#0a0b19',wallEdge:'#5a5f96',style:'star',finalGoal:'Reach the Crownstone Observatory',
      solids:[{x:0,y:0,w:2200,h:135},{x:0,y:7065,w:2200,h:135},{x:700,y:135,w:400,h:490},{x:700,y:825,w:400,h:540},{x:1450,y:135,w:400,h:215},{x:1450,y:570,w:400,h:795},{x:1110,y:1030,w:220,h:335},{x:0,y:1365,w:1850,h:390,role:'deepAccessWall',barrierId:'star_crown_lock'}],
      barriers:[{id:'star_bridge_lock',x:862,y:625,w:76,h:200,requiresPickaxe:5,label:'Astral Bridge Lock'},{id:'star_crown_lock',x:1612,y:350,w:76,h:220,requiresPickaxe:5,label:'Crownstone Ward'}],
      rocks:[['emberstone',300,480],['astralite',360,750],['astralite',315,1050],['astralite',900,675,'star_bridge_lock'],['astralite',900,725,'star_bridge_lock'],['astralite',900,775,'star_bridge_lock'],['astralite',1180,420],['astralite',1260,760],['astralite',1390,1180],['crownstone',1360,250],['astralite',1650,410,'star_crown_lock'],['astralite',1650,460,'star_crown_lock'],['astralite',1650,510,'star_crown_lock'],['astralite',1950,280],['astralite',2020,650],['astralite',1940,1030],['crownstone',2025,1250],['crownstone',1910,1180]],
      labels:[['FALLEN APPROACH',350,205,'#aeb8ee'],['ASTRAL CROSSING',1260,710,'#c9d2ff'],['CROWNSTONE OBSERVATORY',1940,205,'#f1d7ff']]
    }
  };
  const MINE_SCENES=Object.keys(MINE_DEFINITIONS);
  const MINE_DEPTH_PROFILES={
    mossMine:{name:'ROOTWOUND DEPTHS',dirt:'#6b4b2e',floor:'#151b17',wallEdge:'#a2764d',accent:'#d39a58',detail:'#f0c47d',terrainHp:320,seedOffset:41011},
    moonMine:{name:'PRISMATIC DEPTHS',dirt:'#285466',floor:'#0c1b21',wallEdge:'#62a9b7',accent:'#79e4e2',detail:'#d0b8ff',terrainHp:360,seedOffset:52021},
    emberMine:{name:'MOLTEN DEPTHS',dirt:'#6b2f24',floor:'#1a1010',wallEdge:'#c15c38',accent:'#ff7b45',detail:'#ffd080',terrainHp:400,seedOffset:63031},
    starMine:{name:'VOIDSTAR DEPTHS',dirt:'#34365f',floor:'#090a18',wallEdge:'#767cba',accent:'#bfc8ff',detail:'#f2d8ff',terrainHp:440,seedOffset:74041}
  };
  const DEPTH2_RESOURCE_PROFILES={
    mossMine:{main:'rootiron',secondary:'deepstone',rare:'ambercore'},
    moonMine:{main:'prismite',secondary:'deepstone',rare:'lunacore'},
    emberMine:{main:'magmaite',secondary:'deepstone',rare:'furnaceheart'},
    starMine:{main:'voidglass',secondary:'deepstone',rare:'singularity'}
  };
  const DRILL_GATED_RESOURCE_PROFILES={
    mossMine:{type:'burrowsteel',requiresDrillLevel:1,veinCount:4},
    moonMine:{type:'phasecrystal',requiresDrillLevel:2,veinCount:4},
    emberMine:{type:'infernium',requiresDrillLevel:2,veinCount:4}
  };
  const DEPTH_ROUTE_LABELS={mossMine:'ROOTWOUND DEPTHS',moonMine:'PRISMATIC DEPTHS',emberMine:'MOLTEN DEPTHS',starMine:'VOIDSTAR DEPTHS'};
  const MINE_DIRT_COLORS={mossMine:'#4b3d2b',moonMine:'#244d57',emberMine:'#5b2c23',starMine:'#303154'};
  const BIOMES=[
    {id:'mossvein',name:'MOSSVEIN QUARRY',start:0,end:WORLD.gateX,floor:'#273228',accent:'#78b36c',detail:'#a8c48e'},
    {id:'moonglass',name:'MOONGLASS CAVERN',start:WORLD.gateX,end:WORLD.emberGateX,floor:'#14282b',accent:'#65dedb',detail:'#b294ef'},
    {id:'emberdeep',name:'EMBERDEEP FOUNDRY',start:WORLD.emberGateX,end:WORLD.starfallGateX,floor:'#261817',accent:'#ff7543',detail:'#ffbd68'},
    {id:'starfall',name:'STARFALL DEPTHS',start:WORLD.starfallGateX,end:WORLD.width,floor:'#17172a',accent:'#b8c3ff',detail:'#eee4ff'}
  ];
  const SURFACE_BOUNDARIES=Object.freeze([
    Object.freeze({id:'moonglass',x:WORLD.gateX,y:WORLD.gateY,gap:WORLD.gateHalfGap,unlockKey:'areaUnlocked',renderWidth:320,collisionLeft:60,collisionRight:60,lockedGateHalfWidth:160}),
    Object.freeze({id:'emberdeep',x:WORLD.emberGateX,y:WORLD.gateY,gap:WORLD.gateHalfGap,unlockKey:'emberdeepUnlocked',renderWidth:320,collisionLeft:70,collisionRight:69,lockedGateHalfWidth:160}),
    Object.freeze({id:'starfall',x:WORLD.starfallGateX,y:WORLD.gateY,gap:WORLD.gateHalfGap,unlockKey:'fourthUnlocked',renderWidth:320,collisionLeft:73,collisionRight:76,lockedGateHalfWidth:160})
  ]);
  const MATERIAL_FEEDBACK={
    stone:{shape:'chip',gravity:390,spread:1},copper:{shape:'spark',gravity:350,spread:1.05},gold:{shape:'spark',gravity:310,spread:1.12},
    moonglass:{shape:'shard',gravity:245,spread:1.08},starshard:{shape:'shard',gravity:175,spread:1.18},
    emberstone:{shape:'ember',gravity:285,spread:1.12},sunslag:{shape:'ember',gravity:245,spread:1.22},
    astralite:{shape:'star',gravity:115,spread:1.18},crownstone:{shape:'star',gravity:70,spread:1.28},
    deepstone:{shape:'chip',gravity:410,spread:1.08},rootiron:{shape:'spark',gravity:390,spread:1.08},ambercore:{shape:'shard',gravity:250,spread:1.18},
    prismite:{shape:'shard',gravity:210,spread:1.13},lunacore:{shape:'star',gravity:120,spread:1.22},magmaite:{shape:'ember',gravity:270,spread:1.16},
    furnaceheart:{shape:'ember',gravity:180,spread:1.25},voidglass:{shape:'shard',gravity:95,spread:1.2},singularity:{shape:'star',gravity:45,spread:1.3},
    burrowsteel:{shape:'spark',gravity:360,spread:1.16},phasecrystal:{shape:'shard',gravity:150,spread:1.24},infernium:{shape:'ember',gravity:180,spread:1.28}
  };
  const SAVE_KEY='everDeeperPrototypeV2';
  const ACHIEVEMENTS_KEY='everDeeperAchievementsV1';
  const GATE_COST=120;
  const EMBER_GATE_COST=360;
  const STARFORGE_MATERIAL_REQUIRED=200;
  const EMBER_PICKAXE_ORE_REQUIRED=100;
  const EMBER_MASTERY_SUNSLAG_COSTS=Object.freeze([0,30,40,50,60,70]);
  const GROUND_DROP_LIFETIME=300;
  const LOOT_SWEEP_WARNING_SECONDS=30;
  const GROUND_DROP_PICKUP_RADIUS=48;
  const GROUND_DROP_EDGE_X=56;
  const GROUND_DROP_EDGE_TOP=76;
  const GROUND_DROP_EDGE_BOTTOM=64;
  const BASE_MODULE_INTERACT_RADIUS=118;
  const AUTO_SORT_RADIUS=360;
  const STORAGE_CHEST_CAPACITY=20;
  const MAX_GROUND_DROPS=160;
  const MAX_MINING_PARTICLES=260;
  const EMBER_MASTERY=[
    {rank:0,power:31,cooldown:.23,gold:0,sunslag:0,label:'Awakened',shellPower:.72,bonusYield:.22,precisionDelay:1},
    {rank:1,power:38,cooldown:.215,gold:450,sunslag:EMBER_MASTERY_SUNSLAG_COSTS[1],label:'Tempered',shellPower:.85,bonusYield:.27,precisionDelay:.96},
    {rank:2,power:46,cooldown:.20,gold:850,sunslag:EMBER_MASTERY_SUNSLAG_COSTS[2],label:'Kindled',shellPower:1,bonusYield:.32,precisionDelay:.92},
    {rank:3,power:66,cooldown:.185,gold:1450,sunslag:EMBER_MASTERY_SUNSLAG_COSTS[3],label:'Blazing',shellPower:1.15,bonusYield:.38,precisionDelay:.88},
    {rank:4,power:92,cooldown:.17,gold:2300,sunslag:EMBER_MASTERY_SUNSLAG_COSTS[4],label:'Infernal',shellPower:1.3,bonusYield:.45,precisionDelay:.82},
    {rank:5,power:128,cooldown:.155,gold:3600,sunslag:EMBER_MASTERY_SUNSLAG_COSTS[5],label:'Depth Master',shellPower:1.5,bonusYield:.55,precisionDelay:.75}
  ];
  const MINING_RANGE=116;
  const MINE_TILE_SIZE=48;
  const MINERAL_NODE_RENDER_SCALE=.85;
  const MINE_CHUNK_CELLS=16;
  const MINE_TERRAIN_HP=8;
  const PLAYER_SPEED=340;
  const PLAYER_MOVE_STEP=16;
  const MOVEMENT_SPEED_GAIN=.07;
  const MINING_RUSH_DURATION=30;
  const MINING_RUSH_COOLDOWN_MULTIPLIER=.65;
  const ROCK_TYPES={
    stone:{label:'Stone',hp:10,value:2,color:'#88928a',edge:'#cbd0ca',accent:'#68736c',respawn:6},
    copper:{label:'Copper',hp:18,value:7,color:'#8f6546',edge:'#d9955e',accent:'#5d4030',respawn:8},
    moonglass:{label:'Moonglass',hp:42,value:22,color:'#3d8695',edge:'#9ef2ed',accent:'#235365',respawn:10},
    gold:{label:'Gold Vein',hp:28,value:34,color:'#8a6b31',edge:'#ffe17a',accent:'#513d1b',respawn:22,rare:true},
    starshard:{label:'Starshard',hp:58,value:68,color:'#4d477f',edge:'#d6b8ff',accent:'#29284f',respawn:28,rare:true},
    emberstone:{label:'Emberstone',hp:74,shell:32,value:48,color:'#632b22',edge:'#ff9b54',accent:'#321918',respawn:13,armored:true},
    sunslag:{label:'Sunslag Core',hp:92,shell:44,value:118,color:'#6f321a',edge:'#ffd078',accent:'#26110c',respawn:31,rare:true,armored:true},
    astralite:{label:'Astralite',hp:325,shell:72,value:260,color:'#303158',edge:'#b9c7ff',accent:'#17182f',respawn:18,armored:true,starfall:true},
    crownstone:{label:'Crownstone',hp:460,shell:110,value:620,color:'#49355f',edge:'#f4c5ff',accent:'#21172e',respawn:38,rare:true,armored:true,starfall:true},
    deepstone:{label:'Deepstone',hp:145,value:5,color:'#3d4544',edge:'#91a09c',accent:'#252c2b',respawn:10,depth2:true},
    rootiron:{label:'Rootiron',hp:480,shell:95,value:310,color:'#42513b',edge:'#a9ca83',accent:'#232d20',respawn:19,armored:true,depth2:true},
    ambercore:{label:'Ambercore',hp:620,shell:130,value:820,color:'#6e471e',edge:'#ffc667',accent:'#38230f',respawn:42,rare:true,armored:true,depth2:true},
    prismite:{label:'Prismite',hp:540,shell:105,value:380,color:'#285269',edge:'#8df5ff',accent:'#172d3b',respawn:20,armored:true,depth2:true},
    lunacore:{label:'Lunacore',hp:690,shell:145,value:980,color:'#514177',edge:'#e1bdff',accent:'#261e3c',respawn:44,rare:true,armored:true,depth2:true},
    magmaite:{label:'Magmaite',hp:610,shell:125,value:460,color:'#6c2b20',edge:'#ff8c4d',accent:'#341510',respawn:21,armored:true,depth2:true},
    furnaceheart:{label:'Furnace Heart',hp:780,shell:165,value:1180,color:'#7b351b',edge:'#ffdf76',accent:'#351409',respawn:46,rare:true,armored:true,depth2:true},
    voidglass:{label:'Voidglass',hp:710,shell:150,value:560,color:'#27284e',edge:'#b8c7ff',accent:'#111226',respawn:23,armored:true,depth2:true},
    singularity:{label:'Singularity Core',hp:920,shell:210,value:1500,color:'#3d2859',edge:'#f3bfff',accent:'#160c24',respawn:50,rare:true,armored:true,depth2:true},
    burrowsteel:{label:'Burrowsteel',hp:760,shell:180,value:640,color:'#33483c',edge:'#80e0b1',accent:'#16281f',respawn:24,armored:true,depth2:true,drillGated:true},
    phasecrystal:{label:'Phase Crystal',hp:980,shell:235,value:920,color:'#284d70',edge:'#8df4ff',accent:'#13273f',respawn:28,rare:true,armored:true,depth2:true,drillGated:true},
    infernium:{label:'Infernium',hp:1080,shell:260,value:980,color:'#702a1c',edge:'#ff9b55',accent:'#32120b',respawn:28,rare:true,armored:true,depth2:true,drillGated:true}
  };
  const COIN_DROP={label:'Gold',value:10000,color:'#8a5f18',edge:'#ffd978',rare:true,currency:true};
  const MINE_DISCOVERY_PROFILES={
    mossMine:{seed:13579,cavernCount:6,veinCount:11,main:'copper',secondary:'copper',rare:'gold',requiredPickaxe:1,names:['Forgotten Pocket','Rootbound Hollow','Old Prospector Room','Echo Chamber','Buried Camp','Gilded Hollow']},
    moonMine:{seed:24680,cavernCount:7,veinCount:12,main:'moonglass',secondary:'copper',rare:'starshard',requiredPickaxe:3,names:['Prism Pocket','Silent Grotto','Glasswater Hollow','Moonlit Fault','Crystal Nest','Lost Survey','Starshard Grotto']},
    emberMine:{seed:97531,cavernCount:8,veinCount:13,main:'emberstone',secondary:'moonglass',rare:'sunslag',requiredPickaxe:4,names:['Cinder Pocket','Ashen Vault','Collapsed Furnace','Heatwell Hollow','Old Smelter','Burning Grotto','Magma Scar','Crucible Pocket']},
    starMine:{seed:86420,cavernCount:9,veinCount:14,main:'astralite',secondary:'emberstone',rare:'crownstone',requiredPickaxe:5,names:['Fallen Pocket','Silent Orbit','Astral Hollow','Void Grotto','Lost Observatory','Starlight Vault','Crown Scar','Celestial Nest','Last Light Chamber']}
  };
  const POCKET_REWARD_KINDS=['cache','crystal','motherlode','shrine'];

  function seededRandom(seed){
    let value=seed>>>0;return()=>{value=(Math.imul(value,1664525)+1013904223)>>>0;return value/4294967296};
  }

  function newWorldSeed(){
    try{const values=new Uint32Array(1);crypto.getRandomValues(values);return values[0]||1}catch(error){return(Math.floor(Math.random()*4294967295)||1)>>>0}
  }

  function generateMineDiscoveries(scene,depth=1){
    const mine=MINE_DEFINITIONS[scene],profile=MINE_DISCOVERY_PROFILES[scene],random=seededRandom(profile.seed);
    const resources=depth===2?DEPTH2_RESOURCE_PROFILES[scene]:profile;
    const cols=Math.ceil(mine.width/MINE_TILE_SIZE),rows=Math.ceil(mine.height/MINE_TILE_SIZE),caverns=[],deposits=[],rocks=[];
    const depthProfile=MINE_DEPTH_PROFILES[scene],depthPrefix=depth===2?'_depth2':'',cavernCount=profile.cavernCount+(depth===2?2:0),veinCount=profile.veinCount+(depth===2?4:0);
    const depthRandom=depth===2?seededRandom(profile.seed+depthProfile.seedOffset):random;
    const firstDeepRow=Math.ceil((depth===2?700:1500)/MINE_TILE_SIZE),lastDeepRow=rows-7,deepRows=lastDeepRow-firstDeepRow;
    for(let index=0;index<cavernCount;index++){
      const band=(index+.5)/cavernCount,row=Math.round(firstDeepRow+deepRows*band+(depthRandom()-.5)*4);
      const col=4+Math.floor(depthRandom()*Math.max(1,cols-8)),rx=112+Math.floor(depthRandom()*65),ry=82+Math.floor(depthRandom()*52);
      const kind=POCKET_REWARD_KINDS[(index+MINE_SCENES.indexOf(scene))%POCKET_REWARD_KINDS.length];
      const uniqueRewardId=scene+depthPrefix+'_pocket_reward_'+(index+1);
      const reward={id:uniqueRewardId,kind,type:kind==='crystal'?resources.rare:resources.main,label:kind==='cache'?'BURIED CACHE':kind==='crystal'?'CRYSTAL CLUSTER':kind==='motherlode'?'MOTHERLODE':'RESTORATIVE SHRINE'};
      if(kind==='cache'){
        reward.rewards={};reward.rewards[resources.main]=3+MINE_SCENES.indexOf(scene);
        reward.rewards[resources.secondary]=(reward.rewards[resources.secondary]||0)+2;
      }
      const baseName=profile.names[index%profile.names.length];
      caverns.push({id:scene+depthPrefix+'_cavern_'+(index+1),name:depth===2?'Deep '+baseName:baseName,x:(col+.5)*MINE_TILE_SIZE,y:(row+.5)*MINE_TILE_SIZE,rx,ry,reward,depth});
    }
    const insideCavern=(x,y,padding=0)=>caverns.some(cavern=>Math.pow((x-cavern.x)/(cavern.rx+padding),2)+Math.pow((y-cavern.y)/(cavern.ry+padding),2)<1);
    const insidePermanentWall=(x,y,padding=42)=>depth===1&&mine.solids.some(solid=>x+padding>solid.x&&x-padding<solid.x+solid.w&&y+padding>solid.y&&y-padding<solid.y+solid.h);
    const directions=[[1,0],[1,1],[0,1],[-1,1]],occupiedCells=new Set();
    for(let depositIndex=0;depositIndex<veinCount;depositIndex++){
      const rare=(depositIndex+1)%(depth===2?4:5)===0,type=rare?resources.rare:depthRandom()<(depth===2?.28:.18)?resources.secondary:resources.main;
      let positions=[];
      for(let attempt=0;attempt<48&&positions.length<4;attempt++){
        const length=4+Math.floor(depthRandom()*(depth===2?9:7)),direction=directions[Math.floor(depthRandom()*directions.length)];
        const startCol=3+Math.floor(depthRandom()*Math.max(1,cols-7)),startRow=firstDeepRow+Math.floor(depthRandom()*Math.max(1,deepRows-8));
        const candidate=[],used=new Set();
        for(let step=0;step<length;step++){
          const wobble=step>1&&step%3===0?(depthRandom()<.5?-1:1):0;
          const col=Math.max(2,Math.min(cols-3,startCol+direction[0]*step+(direction[1]?wobble:0)));
          const row=Math.max(firstDeepRow,Math.min(rows-3,startRow+direction[1]*step+(direction[0]?wobble:0)));
          const key=col+','+row,x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE;
          if(used.has(key)||occupiedCells.has(key)||insideCavern(x,y,72)||insidePermanentWall(x,y))continue;
          used.add(key);candidate.push([x,y]);
        }
        if(candidate.length>=4)positions=candidate;
      }
      if(positions.length<4)continue;
      const id=scene+depthPrefix+'_vein_'+(depositIndex+1);
      deposits.push({id,type,positions});
      for(const position of positions){
        occupiedCells.add(Math.floor(position[0]/MINE_TILE_SIZE)+','+Math.floor(position[1]/MINE_TILE_SIZE));
        rocks.push({type,x:position[0],y:position[1],depositId:id,requiredPickaxe:Math.min(5,profile.requiredPickaxe+(depth===2?1:0)),requiresDeepTool:depth===2,depth});
      }
    }
    for(let index=0;index<caverns.length;index++){
      const cavern=caverns[index],reward=cavern.reward;
      if(reward.kind==='crystal'||reward.kind==='motherlode'){
        const offsets=reward.kind==='crystal'?[[-50,12],[0,-28],[50,12]]:[[-58,-12],[-30,28],[0,-24],[30,28],[58,-12]];
        const positions=offsets.map(([offsetX,offsetY])=>[(Math.floor((cavern.x+offsetX)/MINE_TILE_SIZE)+.5)*MINE_TILE_SIZE,(Math.floor((cavern.y+offsetY)/MINE_TILE_SIZE)+.5)*MINE_TILE_SIZE]);
        const id=reward.id+'_deposit';
        deposits.push({id,type:reward.type,positions,cavernId:cavern.id,pocketRewardId:reward.id,pocketReward:true});
        for(const position of positions)rocks.push({type:reward.type,x:position[0],y:position[1],depositId:id,cavernId:cavern.id,pocketRewardId:reward.id,pocketReward:true,requiredPickaxe:Math.min(5,profile.requiredPickaxe+(depth===2?1:0)),requiresDeepTool:depth===2,depth});
      }
      if(index!==Math.floor(caverns.length*.45)&&index!==caverns.length-1)continue;
      const id=cavern.id+'_rare_find';
      const x=(Math.floor(cavern.x/MINE_TILE_SIZE)+.5)*MINE_TILE_SIZE,y=(Math.floor(cavern.y/MINE_TILE_SIZE)+.5)*MINE_TILE_SIZE;
      deposits.push({id,type:resources.rare,positions:[[x,y]],rareFind:true,cavernId:cavern.id});
      rocks.push({type:resources.rare,x,y,depositId:id,cavernId:cavern.id,rareFind:true,requiredPickaxe:Math.min(5,profile.requiredPickaxe+(depth===2?1:0)),requiresDeepTool:depth===2,depth});
    }
    const gatedProfile=depth===2?DRILL_GATED_RESOURCE_PROFILES[scene]:null;
    if(gatedProfile){
      for(let gatedIndex=0;gatedIndex<gatedProfile.veinCount;gatedIndex++){
        let positions=[];
        for(let attempt=0;attempt<64&&positions.length<4;attempt++){
          const length=4+Math.floor(depthRandom()*3),horizontal=depthRandom()<.5;
          const startCol=3+Math.floor(depthRandom()*Math.max(1,cols-8)),startRow=firstDeepRow+Math.floor(depthRandom()*Math.max(1,deepRows-8));
          const candidate=[];
          for(let step=0;step<length;step++){
            const col=Math.max(2,Math.min(cols-3,startCol+(horizontal?step:step%2))),row=Math.max(firstDeepRow,Math.min(rows-3,startRow+(horizontal?step%2:step)));
            const key=col+','+row,x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE;
            if(occupiedCells.has(key)||insideCavern(x,y,72)||insidePermanentWall(x,y))continue;
            candidate.push([x,y]);
          }
          if(candidate.length>=4)positions=candidate;
        }
        if(positions.length<4){
          for(let row=firstDeepRow+gatedIndex*5;row<rows-3&&positions.length<4;row++)for(let col=3;col<cols-3&&positions.length<4;col++){
            const key=col+','+row,x=(col+.5)*MINE_TILE_SIZE,y=(row+.5)*MINE_TILE_SIZE;
            if(!occupiedCells.has(key)&&!insideCavern(x,y,72)&&!insidePermanentWall(x,y))positions.push([x,y]);
          }
        }
        if(positions.length<4)continue;
        const id=scene+'_depth2_drill_gate_'+(gatedIndex+1);
        deposits.push({id,type:gatedProfile.type,positions,drillGated:true,requiresDrillLevel:gatedProfile.requiresDrillLevel});
        for(const position of positions){
          occupiedCells.add(Math.floor(position[0]/MINE_TILE_SIZE)+','+Math.floor(position[1]/MINE_TILE_SIZE));
          rocks.push({type:gatedProfile.type,x:position[0],y:position[1],depositId:id,requiredPickaxe:5,requiresDeepTool:true,requiresDrillLevel:gatedProfile.requiresDrillLevel,drillGated:true,depth});
        }
      }
    }
    return{caverns,deposits,rocks};
  }

  const MINE_DISCOVERIES=Object.fromEntries(Object.keys(MINE_DISCOVERY_PROFILES).map(scene=>[scene,generateMineDiscoveries(scene,1)]));
  const MINE_DEPTH_DISCOVERIES=Object.fromEntries(Object.keys(MINE_DISCOVERY_PROFILES).map(scene=>[scene,generateMineDiscoveries(scene,2)]));
  function discoveriesFor(scene,depth=1){return depth===2?MINE_DEPTH_DISCOVERIES[scene]:MINE_DISCOVERIES[scene]}
  const PICKAXES=[
    null,
    {name:'Worn Pickaxe',power:4,cooldown:.72,cost:0},
    {name:'Iron Pickaxe',power:7,cooldown:.54,cost:30},
    {name:'Runed Pickaxe',power:12,cooldown:.40,cost:85},
    {name:'Moonglass Pickaxe',power:20,cooldown:.29,cost:210},
    {name:'Ember Pickaxe',power:31,cooldown:.23,cost:650}
  ];
  const STARFORGE_VARIANTS={
    crusher:{name:'Astral Crusher',short:'Heavy power',cost:{astralite:STARFORGE_MATERIAL_REQUIRED,crownstone:STARFORGE_MATERIAL_REQUIRED},powerMultiplier:1.55,cooldownMultiplier:1.18,shellMultiplier:1.2,yieldBonus:0,color:'#cfd5ff'},
    swift:{name:'Comet Edge',short:'Rapid strikes',cost:{astralite:STARFORGE_MATERIAL_REQUIRED,crownstone:STARFORGE_MATERIAL_REQUIRED},powerMultiplier:1.08,cooldownMultiplier:.58,shellMultiplier:.9,yieldBonus:0,color:'#8ff5ff'},
    prospector:{name:'Crownseeker',short:'Bonus yield',cost:{astralite:STARFORGE_MATERIAL_REQUIRED,crownstone:STARFORGE_MATERIAL_REQUIRED},powerMultiplier:1,cooldownMultiplier:.88,shellMultiplier:1,yieldBonus:.28,color:'#ffe19b'}
  };
  const DRILLS=[
    null,
    {name:'Burrower Drill',power:210,cooldown:.075,shellPower:1.65,yieldBonus:.35,color:'#8fd9bc'},
    {name:'Pulse Drill',power:300,cooldown:.060,shellPower:1.9,yieldBonus:.44,color:'#7defff'},
    {name:'Deepcore Drill',power:430,cooldown:.046,shellPower:2.2,yieldBonus:.56,color:'#ffd47a'}
  ];
  const DRILL_RECIPES=[
    null,
    {gold:5000,requirements:[{scene:'mossMine',type:'rootiron',amount:50},{scene:'mossMine',type:'ambercore',amount:5}]},
    {gold:12000,requirements:[{scene:'mossMine',type:'burrowsteel',amount:60},{scene:'moonMine',type:'prismite',amount:40},{scene:'moonMine',type:'lunacore',amount:4}]},
    {gold:25000,requirements:[{scene:'moonMine',type:'phasecrystal',amount:70},{scene:'emberMine',type:'magmaite',amount:50},{scene:'emberMine',type:'furnaceheart',amount:5},{scene:'emberMine',type:'infernium',amount:70}]}
  ];
  const STATIONS={
    sell:{x:205,y:250,radius:132},
    forge:{x:455,y:250,radius:132},
    speedShop:{x:730,y:220,radius:128},
    gate:{x:1045,y:650,radius:145},
    emberGate:{x:2175,y:650,radius:145},
    starfallGate:{x:3295,y:650,radius:145},
    starforge:{x:3505,y:155,radius:118}
  };
  const CHEST_DEFINITIONS=[
    {id:'moss_supply',name:"Miner's Supply Chest",biome:'mossvein',x:690,y:1110,tier:0,requires:{pickaxeLevel:1,label:'Worn Pickaxe'},rewards:{coin:25}},
    {id:'moss_ironbound',name:'Ironbound Chest',biome:'mossvein',x:980,y:205,tier:1,requires:{pickaxeLevel:2,label:'Iron Pickaxe'},rewards:{coin:75}},
    {id:'moon_cache',name:'Crystal Cache',biome:'moonglass',x:1285,y:1110,tier:1,requires:{pickaxeLevel:3,label:'Runed Pickaxe'},rewards:{coin:100}},
    {id:'moon_reliquary',name:'Moonglass Reliquary',biome:'moonglass',x:2070,y:215,tier:2,requires:{pickaxeLevel:4,label:'Moonglass Pickaxe'},rewards:{coin:200}},
    {id:'ember_cache',name:'Foundry Lockbox',biome:'emberdeep',x:2720,y:1160,tier:2,requires:{pickaxeLevel:4,label:'Moonglass Pickaxe'},rewards:{coin:250}},
    {id:'ember_vault',name:'Ember Vault',biome:'emberdeep',x:3250,y:205,tier:3,requires:{pickaxeLevel:5,label:'Ember Pickaxe'},rewards:{coin:400}},
    {id:'star_cache',name:'Astral Cache',biome:'starfall',x:3650,y:1130,tier:3,requires:{pickaxeLevel:5,label:'Ember Pickaxe'},rewards:{coin:800}},
    {id:'star_coffer',name:'Celestial Coffer',biome:'starfall',x:4370,y:205,tier:4,requires:{starforge:true,label:'Starforge Pickaxe'},rewards:{coin:2000}}
  ];
  const CHEST_INTERACT_RADIUS=108;
  const ROCK_LAYOUT=[
    ['stone',250,535],['stone',425,600],['stone',605,480],['stone',760,520],['stone',890,410],
    ['stone',325,1030],['stone',610,1020],['stone',835,930],['stone',935,880],['stone',510,980],
    ['copper',790,300],['copper',915,565],['copper',205,1050],['copper',710,1010],['copper',430,1060],
    ['gold',560,380],
    ['moonglass',1300,350],['moonglass',1490,530],['moonglass',1730,330],['moonglass',1980,500],
    ['moonglass',1265,950],['moonglass',1510,1010],['moonglass',1790,950],['moonglass',2040,1030],
    ['copper',1180,980],['copper',1880,900],['stone',1600,930],['stone',2100,930],['starshard',1840,1080],
    ['emberstone',2380,335],['emberstone',2580,520],['emberstone',2825,310],['emberstone',3140,470],
    ['emberstone',2290,1010],['emberstone',2480,230],['emberstone',2880,1080],['emberstone',3300,1090],
    ['moonglass',2710,410],['copper',3300,950],['sunslag',2920,1180],
    ['astralite',3505,320],['astralite',3700,520],['astralite',3970,300],['astralite',4240,470],
    ['astralite',4100,560],['astralite',3780,1040],['astralite',4090,960],['astralite',4380,1040],
    ['moonglass',3850,1170],['emberstone',4300,900],['crownstone',4140,1110]
  ];
  const VEIN_DEFINITIONS=[
    {id:'copper_run',type:'copper',timeLimit:16,respawn:28,color:'#e2a36e',bonus:{copper:3},positions:[[875,1085],[945,1025],[1010,1100]]},
    {id:'moonglass_bloom',type:'moonglass',timeLimit:18,respawn:32,color:'#9ef2ed',bonus:{moonglass:2,starshard:1},positions:[[1593,504],[1665,504],[1742,504]]},
    {id:'ember_fault',type:'emberstone',timeLimit:22,respawn:38,color:'#ff9b54',bonus:{emberstone:3,sunslag:1},positions:[[2978,900],[3078,900],[3176,900]]},
    {id:'starfall_lattice',type:'astralite',timeLimit:20,respawn:42,color:'#c4cfff',bonus:{astralite:3,crownstone:1},positions:[[3720,880],[3810,930],[3900,890]]}
  ];
  const VEIN_ROCK_LAYOUT=VEIN_DEFINITIONS.flatMap(vein=>vein.positions.map(position=>[vein.type,position[0],position[1],vein.id]));

  function achievementDefinition(id,title,description,category,tier,predicate){
    return Object.freeze({id,title,description,category,tier,asset:'assets/achievements/'+id+'.png',predicate});
  }
  const ACHIEVEMENT_DEFINITIONS=Object.freeze([
    achievementDefinition('first_chip','First Chip','Mine your first resource.','mining','bronze',(s,m)=>m.totalMined>=1),
    achievementDefinition('first_payday','First Payday','Earn your first gold.','treasure','bronze',s=>s.totalGold>=1),
    achievementDefinition('moon_unsealed','Moon Unsealed','Open the Moonglass Gate.','journey','bronze',s=>s.areaUnlocked),
    achievementDefinition('ember_unsealed','Ember Unsealed','Break the Emberdeep Seal.','journey','silver',s=>s.emberdeepUnlocked),
    achievementDefinition('stars_unsealed','Stars Unsealed','Open the Starfall Master Seal.','journey','gold',s=>s.fourthUnlocked),
    achievementDefinition('four_frontiers','Four Frontiers','Step into Moonglass, Emberdeep, and Starfall.','journey','gold',s=>s.discoveredSecond&&s.discoveredThird&&s.discoveredFourth),
    achievementDefinition('minewalker','Minewalker','Enter all four mines.','journey','gold',s=>MINE_SCENES.every(scene=>s.discoveredMines[scene])),
    achievementDefinition('seasoned_arms','Seasoned Arms','Complete 100 mining swings.','mining','bronze',s=>s.totalSwings>=100),
    achievementDefinition('iron_rhythm','Iron Rhythm','Complete 1,000 mining swings.','mining','gold',s=>s.totalSwings>=1000),
    achievementDefinition('keen_eye','Keen Eye','Land 10 precision hits.','mining','bronze',s=>s.precisionHits>=10),
    achievementDefinition('true_aim','True Aim','Land 100 precision hits.','mining','gold',s=>s.precisionHits>=100),
    achievementDefinition('tunnel_hand','Tunnel Hand','Dig out 100 terrain tiles.','mining','silver',(s,m)=>m.tilesDug>=100),
    achievementDefinition('earth_eater','Earth Eater','Dig out 1,000 terrain tiles.','mining','gold',(s,m)=>m.tilesDug>=1000),
    achievementDefinition('ore_mountain','Ore Mountain','Mine 1,000 resources in total.','mining','gold',(s,m)=>m.totalMined>=1000),
    achievementDefinition('goldspark','Goldspark','Mine your first Gold Vein.','resources','bronze',s=>s.mined.gold>=1),
    achievementDefinition('fallen_star','Fallen Star','Obtain your first Starshard through mining.','resources','silver',s=>s.mined.starshard>=1),
    achievementDefinition('sunstruck','Sunstruck','Obtain your first Sunslag Core through mining.','resources','silver',s=>s.mined.sunslag>=1),
    achievementDefinition('crowned','Crowned','Obtain your first Crownstone through mining.','resources','gold',s=>s.mined.crownstone>=1),
    achievementDefinition('into_the_deep','Into the Deep','Mine your first Deepstone in Depth 2.','depths','silver',s=>s.mined.deepstone>=1),
    achievementDefinition('three_hearts','Three Hearts','Mine Ambercore, Lunacore, and a Furnace Heart.','depths','gold',s=>['ambercore','lunacore','furnaceheart'].every(type=>s.mined[type]>0)),
    achievementDefinition('drillborn_ore','Drillborn Ore','Mine Burrowsteel, Phase Crystal, and Infernium.','depths','gold',s=>['burrowsteel','phasecrystal','infernium'].every(type=>s.mined[type]>0)),
    achievementDefinition('deep_hoard','Deep Hoard','Mine 500 Depth 2 resources.','depths','gold',(s,m)=>m.depthMined>=500),
    achievementDefinition('ironbound','Ironbound','Forge the Iron Pickaxe.','equipment','bronze',s=>s.pickaxeLevel>=2),
    achievementDefinition('rune_ready','Rune Ready','Forge the Runed Pickaxe.','equipment','bronze',s=>s.pickaxeLevel>=3),
    achievementDefinition('moonforged','Moonforged','Forge the Moonglass Pickaxe.','equipment','silver',s=>s.pickaxeLevel>=4),
    achievementDefinition('emberforged','Emberforged','Forge the Ember Pickaxe.','equipment','gold',s=>s.pickaxeLevel>=5),
    achievementDefinition('depth_master','Depth Master','Reach Ember Mastery 5.','equipment','gold',s=>s.emberMastery>=5),
    achievementDefinition('starforged','Starforged','Forge your first Starforge form.','equipment','gold',s=>Object.values(s.starforgeUnlocked).some(Boolean)),
    achievementDefinition('threefold_star','Threefold Star','Forge all three Starforge forms.','equipment','mythic',s=>Object.values(s.starforgeUnlocked).every(Boolean)),
    achievementDefinition('burrower','Burrower','Forge the Burrower Drill.','equipment','silver',s=>s.drillLevel>=1),
    achievementDefinition('pulse_driver','Pulse Driver','Forge the Pulse Drill.','equipment','gold',s=>s.drillLevel>=2),
    achievementDefinition('deepcore','Deepcore','Forge the Deepcore Drill.','equipment','mythic',s=>s.drillLevel>=3),
    achievementDefinition('moss_below','Moss Below','Enter Mossvein Mine.','journey','bronze',s=>s.discoveredMines.mossMine),
    achievementDefinition('glass_below','Glass Below','Enter Moonglass Labyrinth.','journey','silver',s=>s.discoveredMines.moonMine),
    achievementDefinition('fire_below','Fire Below','Enter Emberdeep Works.','journey','silver',s=>s.discoveredMines.emberMine),
    achievementDefinition('stars_below','Stars Below','Enter Starfall Hollow.','journey','gold',s=>s.discoveredMines.starMine),
    achievementDefinition('hidden_descent','Hidden Descent','Uncover a hidden Depth 2 entrance.','depths','silver',s=>MINE_SCENES.some(scene=>s.discoveredDepthEntrances[scene])),
    achievementDefinition('every_depth','Every Depth','Enter Depth 2 in all four mines.','depths','mythic',s=>MINE_SCENES.every(scene=>s.visitedDepths[scene])),
    achievementDefinition('treasure_found','Treasure Found','Open your first surface treasure chest.','treasure','bronze',(s,m)=>m.opened>=1),
    achievementDefinition('cache_hunter','Cache Hunter','Open four surface treasure chests.','treasure','silver',(s,m)=>m.opened>=4),
    achievementDefinition('chestmaster','Chestmaster','Open all eight surface treasure chests.','treasure','gold',s=>CHEST_DEFINITIONS.every(chest=>s.openedChests[chest.id])),
    achievementDefinition('vein_runner','Vein Runner','Complete your first timed surface vein.','veins','bronze',(s,m)=>m.veinTotal>=1),
    achievementDefinition('fourfold_veins','Fourfold Veins','Complete each of the four timed vein types.','veins','gold',s=>VEIN_DEFINITIONS.every(vein=>s.veinsCompleted[vein.id]>0)),
    achievementDefinition('vein_veteran','Vein Veteran','Complete 10 timed surface veins.','veins','gold',(s,m)=>m.veinTotal>=10),
    achievementDefinition('quick_step','Quick Step','Buy your first movement-speed upgrade.','base','bronze',s=>s.movementSpeedLevel>=1),
    achievementDefinition('roadrunner','Roadrunner','Buy 10 movement-speed upgrades.','base','gold',s=>s.movementSpeedLevel>=10),
    achievementDefinition('more_storage','More Storage','Purchase a second storage chest.','base','bronze',s=>s.base.chests.length>=2),
    achievementDefinition('mobile_base','Mobile Base','Place a base module inside any mine.','base','silver',s=>[s.base.forge,s.base.sell,...s.base.chests].some(module=>!module.packed&&MINE_SCENES.includes(module.scene))),
    achievementDefinition('mineral_crown','Mineral Crown','Record at least one of every resource.','resources','mythic',s=>Object.keys(ROCK_TYPES).every(type=>s.mined[type]>0)),
    achievementDefinition('ever_deeper','Ever Deeper','Conquer Voidstar by mining a Singularity Core with the Deepcore Drill.','journey','mythic',s=>s.victory)
  ]);
  const ACHIEVEMENT_BY_ID=Object.freeze(Object.fromEntries(ACHIEVEMENT_DEFINITIONS.map(definition=>[definition.id,definition])));

  const ACHIEVEMENT_REASONS=Object.freeze({
    first_chip:'Mined the first resource of the expedition.',first_payday:'Added the first piece of earned gold to the expedition ledger.',
    moon_unsealed:'Opened the way into Moonglass.',ember_unsealed:'Broke the seal guarding Emberdeep.',stars_unsealed:'Opened the master seal into Starfall.',
    four_frontiers:'Crossed into Moonglass, Emberdeep, and Starfall.',minewalker:'Entered Mossvein, Moonglass, Emberdeep, and Starfall mines.',
    seasoned_arms:'Completed 100 mining swings.',iron_rhythm:'Completed 1,000 mining swings.',keen_eye:'Landed 10 precision hits.',true_aim:'Landed 100 precision hits.',
    tunnel_hand:'Dug out 100 terrain tiles.',earth_eater:'Dug out 1,000 terrain tiles.',ore_mountain:'Mined 1,000 resources in total.',
    goldspark:'Mined the first Gold Vein.',fallen_star:'Mined the first Starshard.',sunstruck:'Mined the first Sunslag Core.',crowned:'Mined the first Crownstone.',
    into_the_deep:'Mined the first piece of Deepstone in Depth 2.',three_hearts:'Mined Ambercore, Lunacore, and a Furnace Heart.',
    drillborn_ore:'Mined Burrowsteel, Phase Crystal, and Infernium.',deep_hoard:'Mined 500 resources found in Depth 2.',
    ironbound:'Forged the Iron Pickaxe.',rune_ready:'Forged the Runed Pickaxe.',moonforged:'Forged the Moonglass Pickaxe.',emberforged:'Forged the Ember Pickaxe.',
    depth_master:'Reached Ember Mastery rank 5.',starforged:'Forged the first Starforge form.',threefold_star:'Forged all three Starforge forms.',
    burrower:'Forged the Burrower Drill.',pulse_driver:'Forged the Pulse Drill.',deepcore:'Forged the Deepcore Drill.',
    moss_below:'Entered Mossvein Mine.',glass_below:'Entered Moonglass Labyrinth.',fire_below:'Entered Emberdeep Works.',stars_below:'Entered Starfall Hollow.',
    hidden_descent:'Uncovered a hidden Depth 2 entrance.',every_depth:'Entered Depth 2 in all four mines.',
    treasure_found:'Opened the first surface treasure chest.',cache_hunter:'Opened four surface treasure chests.',chestmaster:'Opened all eight surface treasure chests.',
    vein_runner:'Completed the first timed surface vein.',fourfold_veins:'Completed all four timed surface vein types.',vein_veteran:'Completed 10 timed surface veins.',
    quick_step:'Bought the first movement-speed upgrade.',roadrunner:'Bought 10 movement-speed upgrades.',more_storage:'Purchased a second storage chest.',
    mobile_base:'Placed a base module inside a mine.',mineral_crown:'Recorded at least one of every mineable resource.',
    ever_deeper:'Mined a Singularity Core in Voidstar with the Deepcore Drill and completed Ever Deeper.'
  });

  global.EverDeeperGameData=Object.freeze({
    WORLD,HUB_WORLD,HUB_GRID,HUB_STATIONS,HUB_BUILD_COSTS,MINE_DEFINITIONS,MINE_SCENES,MINE_DEPTH_PROFILES,DEPTH2_RESOURCE_PROFILES,DEPTH_ROUTE_LABELS,MINE_DIRT_COLORS,BIOMES,SURFACE_BOUNDARIES,MATERIAL_FEEDBACK,
    SAVE_KEY,ACHIEVEMENTS_KEY,GATE_COST,EMBER_GATE_COST,STARFORGE_MATERIAL_REQUIRED,EMBER_PICKAXE_ORE_REQUIRED,EMBER_MASTERY_SUNSLAG_COSTS,
    GROUND_DROP_LIFETIME,LOOT_SWEEP_WARNING_SECONDS,GROUND_DROP_PICKUP_RADIUS,GROUND_DROP_EDGE_X,GROUND_DROP_EDGE_TOP,GROUND_DROP_EDGE_BOTTOM,
    BASE_MODULE_INTERACT_RADIUS,AUTO_SORT_RADIUS,STORAGE_CHEST_CAPACITY,MAX_GROUND_DROPS,MAX_MINING_PARTICLES,EMBER_MASTERY,MINING_RANGE,MINE_TILE_SIZE,
    MINERAL_NODE_RENDER_SCALE,MINE_CHUNK_CELLS,MINE_TERRAIN_HP,PLAYER_SPEED,PLAYER_MOVE_STEP,MOVEMENT_SPEED_GAIN,MINING_RUSH_DURATION,MINING_RUSH_COOLDOWN_MULTIPLIER,
    ROCK_TYPES,COIN_DROP,MINE_DISCOVERY_PROFILES,seededRandom,newWorldSeed,MINE_DISCOVERIES,MINE_DEPTH_DISCOVERIES,discoveriesFor,PICKAXES,STARFORGE_VARIANTS,
    DRILLS,DRILL_RECIPES,STATIONS,CHEST_DEFINITIONS,CHEST_INTERACT_RADIUS,ROCK_LAYOUT,VEIN_DEFINITIONS,VEIN_ROCK_LAYOUT,ACHIEVEMENT_DEFINITIONS,ACHIEVEMENT_BY_ID,ACHIEVEMENT_REASONS
  });
})(window);
