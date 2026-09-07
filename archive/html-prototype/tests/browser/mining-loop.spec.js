const {test,expect}=require('@playwright/test');

const COMPLETE_DROP_PATHS={stone:'assets/drops/stone-drop.png',copper:'assets/drops/copper-drop.png',gold:'assets/drops/gold-drop.png',moonglass:'assets/drops/moonglass-drop.png',starshard:'assets/drops/starshard-drop.png',emberstone:'assets/drops/emberstone-drop.png',sunslag:'assets/drops/sunslag-drop.png',astralite:'assets/drops/astralite-drop.png',crownstone:'assets/drops/crownstone-drop.png',deepstone:'assets/drops/deepstone-drop.png',rootiron:'assets/drops/rootiron-drop.png',ambercore:'assets/drops/ambercore-drop.png',prismite:'assets/drops/prismite-drop.png',lunacore:'assets/drops/lunacore-drop.png',magmaite:'assets/drops/magmaite-drop.png',furnaceheart:'assets/drops/furnaceheart-drop.png',voidglass:'assets/drops/voidglass-drop.png',singularity:'assets/drops/singularity-drop.png',burrowsteel:'assets/drops/burrowsteel-drop.png',phasecrystal:'assets/drops/phasecrystal-drop.png',infernium:'assets/drops/infernium-drop.png'};

const SURFACE_MOONGLASS_RENDERING={
  ground:'assets/surface/moonglass-ground.png',
  crystals:'assets/surface/moonglass-crystals.png',
  bloomBed:'assets/surface/moonglass-bloom-bed.png',
  entrance:'assets/entrances/moonglass-entrance.png',
  gateMark:'assets/surface/moonglass-gate-mark.png',
  emberdeepSeal:'assets/surface/emberdeep-seal.png',
  openBoundaryGatesRemoved:true,
  animatedGateTransition:true,
  smoothMossveinBlend:true,
  backgroundCrystalsDistinct:true,
  chests:{
    crystalCache:{closed:'assets/surface/crystal-cache-closed.png',open:'assets/surface/crystal-cache-open.png'},
    reliquary:{closed:'assets/surface/moonglass-reliquary-closed.png',open:'assets/surface/moonglass-reliquary-open.png'}
  },
  legacyGrid:false,
  legacyDecorations:false,
  legacyChests:false,
  legacyEntrance:false,
  legacyEmberdeepSeal:false
};

const MOONGLASS_RENDERING={
  surfaceGround:'assets/surface/moonglass-ground.png',
  surfaceCrystals:'assets/surface/moonglass-crystals.png',
  bloomBed:'assets/surface/moonglass-bloom-bed.png',
  entrance:'assets/entrances/moonglass-entrance.png',
  gateMark:'assets/surface/moonglass-gate-mark.png',
  emberdeepSeal:'assets/surface/emberdeep-seal.png',
  openBoundaryGatesRemoved:true,
  animatedGateTransition:true,
  smoothMossveinBlend:true,
  backgroundCrystalsDistinct:true,
  chests:{
    crystalCache:{closed:'assets/surface/crystal-cache-closed.png',open:'assets/surface/crystal-cache-open.png'},
    reliquary:{closed:'assets/surface/moonglass-reliquary-closed.png',open:'assets/surface/moonglass-reliquary-open.png'}
  },
  floor:'assets/moonglass/floor.png',
  wall:'assets/moonglass/wall.png',
  routeMarker:'assets/moonglass/route-marker.png',
  pocket:'assets/moonglass/crystal-pocket.png',
  cache:'assets/moonglass/buried-cache.png',
  shrine:'assets/moonglass/mining-rush-shrine.png',
  nodes:{moonglass:'assets/moonglass/moonglass-node.png',starshard:'assets/moonglass/starshard-node.png'},
  wallHints:{moonglass:'assets/moonglass/moonglass-wall.png',starshard:'assets/moonglass/starshard-wall.png'},
  barriers:{moon_prism_gate:'assets/moonglass/prismatic-fault.png',moon_star_lock:'assets/moonglass/starbound-geode.png'},
  drops:{moonglass:'assets/drops/moonglass-drop.png',starshard:'assets/drops/starshard-drop.png'},
  legacySurfaceDecorations:false,
  legacyMineFloor:false,
  legacyMineTerrain:false,
  legacyMineWalls:false,
  legacyBarriers:false,
  legacyPocketRewards:false,
  legacyResourceNodes:false
};

const SURFACE_EMBERDEEP_RENDERING={
  ground:'assets/surface/emberdeep-ground.png',
  slag:'assets/surface/emberdeep-slag-clusters.png',
  faultBed:'assets/surface/emberdeep-fault-bed.png',
  minePath:'assets/surface/emberdeep-mine-path.png',
  minePathBounds:{x:2456,y:772,w:500,h:222},
  minePathRotation:-.105,
  minePathPivot:{x:2956,y:809},
  minePathMouthTarget:{x:2480,y:1015},
  entrance:'assets/entrances/emberdeep-entrance.png',
  entrancePosition:{x:2480,y:970,radius:112},
  entranceFlipped:true,
  gateSeal:'assets/surface/emberdeep-seal.png',
  gateMark:'assets/surface/emberdeep-seal-mark.png',
  animatedGateTransition:true,
  smoothMoonglassBlend:true,
  continuousBlendUnderlay:true,
  backgroundSlagDistinct:true,
  chests:{
    foundry:{closed:'assets/surface/foundry-lockbox-closed.png',open:'assets/surface/foundry-lockbox-open.png'},
    vault:{closed:'assets/surface/ember-vault-closed.png',open:'assets/surface/ember-vault-open.png'}
  },
  legacyGrid:false,
  legacyDecorations:false,
  legacyChests:false,
  legacyEntrance:false,
  legacyGate:false
};

const EMBERDEEP_RENDERING={
  floor:'assets/emberdeep/floor.png',
  wall:'assets/emberdeep/wall.png',
  routeMarker:'assets/emberdeep/route-marker.png',
  pocket:'assets/emberdeep/crystal-pocket.png',
  cache:'assets/emberdeep/buried-cache.png',
  shrine:'assets/emberdeep/mining-rush-shrine.png',
  nodes:{
    emberstone:'assets/emberdeep/emberstone-node.png',
    moonglass:'assets/moonglass/moonglass-node.png',
    sunslag:'assets/emberdeep/sunslag-node.png'
  },
  wallHints:{
    emberstone:'assets/emberdeep/emberstone-wall.png',
    moonglass:'assets/moonglass/moonglass-wall.png',
    sunslag:'assets/emberdeep/sunslag-wall.png'
  },
  barriers:{ember_bulkhead:'assets/emberdeep/cinder-bulkhead.png',ember_crucible_lock:'assets/emberdeep/crucible-seal.png'},
  drops:{emberstone:'assets/drops/emberstone-drop.png',moonglass:'assets/drops/moonglass-drop.png',sunslag:'assets/drops/sunslag-drop.png'},
  legacyMineFloor:false,
  legacyMineTerrain:false,
  legacyMineWalls:false,
  legacyBarriers:false,
  legacyPocketRewards:false,
  legacyResourceNodes:false
};

const MOLTEN_RENDERING={
  floor:'assets/molten/floor.png',
  wall:'assets/molten/wall.png',
  shaft:'assets/molten/depth-portal.png',
  sellStation:'assets/molten/sell-station.png',
  drillForge:'assets/molten/drill-forge.png',
  pocket:'assets/molten/crystal-pocket.png',
  cache:'assets/molten/buried-cache.png',
  shrine:'assets/molten/mining-rush-shrine.png',
  nodes:{
    magmaite:'assets/molten/magmaite-node.png',
    deepstone:'assets/molten/deepstone-node.png',
    furnaceheart:'assets/molten/furnaceheart-node.png',
    infernium:'assets/molten/infernium-node.png'
  },
  wallHints:{
    magmaite:'assets/molten/magmaite-wall.png',
    deepstone:'assets/molten/deepstone-wall.png',
    furnaceheart:'assets/molten/furnaceheart-wall.png',
    infernium:'assets/molten/infernium-wall.png'
  },
  drops:{
    deepstone:'assets/drops/deepstone-drop.png',
    magmaite:'assets/drops/magmaite-drop.png',
    furnaceheart:'assets/drops/furnaceheart-drop.png',
    infernium:'assets/drops/infernium-drop.png'
  },
  legacyFloorDecorations:false,
  legacyTerrainTexture:false,
  legacyDepthShaft:false,
  legacyDepthStations:false,
  legacyPocketRewards:false,
  legacyResourceNodes:false
};

const PRISMATIC_RENDERING={
  floor:'assets/prismatic/floor.png',
  wall:'assets/prismatic/wall.png',
  shaft:'assets/prismatic/depth-portal.png',
  sellStation:'assets/prismatic/sell-station.png',
  drillForge:'assets/prismatic/drill-forge.png',
  pocket:'assets/prismatic/crystal-pocket.png',
  cache:'assets/prismatic/buried-cache.png',
  shrine:'assets/prismatic/mining-rush-shrine.png',
  nodes:{
    prismite:'assets/prismatic/prismite-node.png',
    deepstone:'assets/rootwound/deepstone-node.png',
    lunacore:'assets/prismatic/lunacore-node.png',
    phasecrystal:'assets/prismatic/phasecrystal-node.png'
  },
  wallHints:{
    prismite:'assets/prismatic/prismite-wall.png',
    deepstone:'assets/prismatic/deepstone-wall.png',
    lunacore:'assets/prismatic/lunacore-wall.png',
    phasecrystal:'assets/prismatic/phasecrystal-wall.png'
  },
  drops:{
    deepstone:'assets/drops/deepstone-drop.png',
    prismite:'assets/drops/prismite-drop.png',
    lunacore:'assets/drops/lunacore-drop.png',
    phasecrystal:'assets/drops/phasecrystal-drop.png'
  },
  legacyFloorDecorations:false,
  legacyTerrainTexture:false,
  legacyDepthShaft:false,
  legacyDepthStations:false,
  legacyPocketRewards:false,
  legacyResourceNodes:false
};

const SURFACE_STARFALL_RENDERING={
  ground:'assets/surface/starfall-ground.png',
  shards:'assets/surface/starfall-shard-clusters.png',
  latticeBed:'assets/surface/starfall-lattice-bed.png',
  minePath:'assets/surface/starfall-mine-path.png',
  minePathBounds:{x:3450,y:760,w:650,h:289},
  minePathMouthTarget:{x:3505,y:1000},
  entrance:'assets/entrances/starfall-entrance.png',
  entrancePosition:{x:3505,y:1000,radius:112},
  gateSeal:'assets/surface/starfall-seal.png',
  gateMark:'assets/surface/starfall-seal-mark.png',
  starforge:'assets/surface/starforge-station.png',
  animatedGateTransition:true,
  smoothEmberdeepBlend:true,
  continuousBlendUnderlay:true,
  backgroundShardsDistinct:true,
  chests:{
    astralCache:{closed:'assets/surface/astral-cache-closed.png',open:'assets/surface/astral-cache-open.png'},
    celestialCoffer:{closed:'assets/surface/celestial-coffer-closed.png',open:'assets/surface/celestial-coffer-open.png'}
  },
  legacyGrid:false,
  legacyDecorations:false,
  legacyChests:false,
  legacyEntrance:false,
  legacyGate:false,
  legacyStarforge:false
};

const STARFALL_RENDERING={
  floor:'assets/starfall/floor.png',
  wall:'assets/starfall/wall.png',
  routeMarker:'assets/starfall/route-marker.png',
  pocket:'assets/starfall/crystal-pocket.png',
  cache:'assets/starfall/buried-cache.png',
  shrine:'assets/starfall/mining-rush-shrine.png',
  nodes:{
    astralite:'assets/starfall/astralite-node.png',
    crownstone:'assets/starfall/crownstone-node.png'
  },
  wallHints:{
    astralite:'assets/starfall/astralite-wall.png',
    crownstone:'assets/starfall/crownstone-wall.png'
  },
  barriers:{
    star_bridge_lock:'assets/starfall/astral-bridge-lock.png',
    star_crown_lock:'assets/starfall/crownstone-ward.png'
  },
  drops:{
    astralite:'assets/drops/astralite-drop.png',
    crownstone:'assets/drops/crownstone-drop.png'
  },
  legacyFloor:false,
  legacyTerrain:false,
  legacyWalls:false,
  legacyBarriers:false,
  legacyRewards:false,
  legacyNodes:false
};

const VOIDSTAR_RENDERING={
  floor:'assets/voidstar/floor.png',
  wall:'assets/voidstar/wall.png',
  shaft:'assets/voidstar/depth-portal.png',
  sellStation:'assets/voidstar/sell-station.png',
  drillForge:'assets/voidstar/drill-forge.png',
  pocket:'assets/voidstar/crystal-pocket.png',
  cache:'assets/voidstar/buried-cache.png',
  shrine:'assets/voidstar/mining-rush-shrine.png',
  nodes:{
    voidglass:'assets/voidstar/voidglass-node.png',
    deepstone:'assets/voidstar/deepstone-node.png',
    singularity:'assets/voidstar/singularity-node.png'
  },
  wallHints:{
    voidglass:'assets/voidstar/voidglass-wall.png',
    deepstone:'assets/voidstar/deepstone-wall.png',
    singularity:'assets/voidstar/singularity-wall.png'
  },
  drops:{
    deepstone:'assets/drops/deepstone-drop.png',
    voidglass:'assets/drops/voidglass-drop.png',
    singularity:'assets/drops/singularity-drop.png'
  },
  legacyFloor:false,
  legacyTerrain:false,
  legacyWalls:false,
  legacyRewards:false,
  legacyNodes:false,
  legacyShaft:false,
  legacyStations:false
};

const STARTER_GATE_RENDERING={
  moonglassGate:'assets/surface/moonglass-gate.png',
  moonglassGateMark:'assets/surface/moonglass-gate-mark.png',
  emberdeepSeal:'assets/surface/emberdeep-seal.png',
  emberdeepSealMark:'assets/surface/emberdeep-seal-mark.png',
  starfallSeal:'assets/surface/starfall-seal.png',
  starfallSealMark:'assets/surface/starfall-seal-mark.png',
  renderBounds:{maxWidth:260,maxHeight:238,bottom:110},
  markRenderWidth:300,
  markSourceBounds:{moonglass:{x:14,y:55,w:484,h:222},emberdeep:{x:28,y:6,w:456,h:329},starfall:{x:34,y:54,w:449,h:231}},
  collisionFollowsPaintedCliff:true,
  integratedBoundaryScale:true,
  biomeAlignedPerspective:true,
  northSouthStructure:true,
  westEastPassage:true,
  premiumEnergyBarrier:true,
  duplicateCanvasSeam:false,
  proceduralGateShadow:false,
  animatedMoonglassTransition:true,
  animatedEmberdeepTransition:true,
  animatedStarfallTransition:true,
  activationSequence:['flash','shake','sink'],
  assetSilhouetteFlash:true,
  preSinkShake:true,
  unscaledGroundSink:true,
  collisionLocksUntilSunk:true,
  reducedMotionSafe:true,
  openWorldGatesRemoved:true,
  legacyStarterGate:false
};

function pngPaths(value){
  const paths=[];
  const visit=item=>{
    if(typeof item==='string'&&item.endsWith('.png'))paths.push(item);
    else if(Array.isArray(item))item.forEach(visit);
    else if(item&&typeof item==='object')Object.values(item).forEach(visit);
  };
  visit(value);return[...new Set(paths)];
}

async function inspectPngs(page,paths){
  return page.evaluate(sources=>Promise.all(sources.map(src=>new Promise(resolve=>{
    const image=new Image();
    image.onload=()=>resolve({src,width:image.naturalWidth,height:image.naturalHeight});
    image.onerror=()=>resolve({src,width:0,height:0});
    image.src=src;
  }))),paths);
}

async function freshGame(page){
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  await page.evaluate(()=>window.__everDeeperTest.reset());
  await page.evaluate(()=>window.__everDeeperTest.dismissStartMenu());
  await page.evaluate(()=>window.__everDeeperTest.setTimeScale(12));
}

async function mineCopper(page,count){
  for(let index=0;index<count;index++){
    await page.evaluate(()=>{
      window.__everDeeperTest.restoreRocks();
      window.__everDeeperTest.setPosition(790,300);
    });
    await page.keyboard.down('Space');
    await page.waitForTimeout(430);
    await page.keyboard.up('Space');
  }
}

async function useStation(page,x,y){
  await page.evaluate(({x,y})=>window.__everDeeperTest.setPosition(x,y),{x,y});
  await expect(page.locator('#contextPanel')).toBeVisible();
  await page.locator('#contextButton').click();
}

test('complete mining progression reaches Moonglass Cavern',async({page})=>{
  await freshGame(page);

  await mineCopper(page,5);
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.cargo.copper).toBeGreaterThanOrEqual(5);

  await useStation(page,205,250);
  await useStation(page,455,250);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.pickaxeLevel).toBe(2);
  expect(snapshot.state.gold).toBeGreaterThanOrEqual(0);

  await mineCopper(page,12);
  await useStation(page,205,250);
  await useStation(page,455,250);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.pickaxeLevel).toBe(3);
  expect(snapshot.state.mined.copper).toBeGreaterThanOrEqual(17);

  await mineCopper(page,18);
  await useStation(page,205,250);
  await useStation(page,1045,650);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.areaUnlocked).toBe(true);

  await page.evaluate(()=>window.__everDeeperTest.setPosition(1220,650));
  await expect(page.locator('#areaName')).toHaveText('MOONGLASS CAVERN');
  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.setPosition(1240,350);
  });
  await page.keyboard.down('Space');
  await page.waitForTimeout(250);
  await page.keyboard.up('Space');
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.mined.moonglass).toBeGreaterThanOrEqual(1);
  await expect(page.locator('#objectiveText')).toHaveText('Forge a Moonglass Pickaxe');
});

test('Moonglass progression unlocks Emberdeep and its armored ore',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.grantGold(1000));
  await useStation(page,455,250);
  await useStation(page,455,250);
  await useStation(page,1045,650);
  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.setPosition(1300,350);
  });
  await page.keyboard.down('Space');
  await page.waitForTimeout(260);
  await page.keyboard.up('Space');
  await useStation(page,455,250);

  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.pickaxeLevel).toBe(4);
  expect(snapshot.state.areaUnlocked).toBe(true);

  await useStation(page,2175,650);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.emberdeepUnlocked).toBe(true);

  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.setPosition(2380,335);
  });
  await expect(page.locator('#areaName')).toHaveText('EMBERDEEP FOUNDRY');
  await page.keyboard.down('Space');
  await page.waitForTimeout(520);
  await page.keyboard.up('Space');
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.mined.emberstone).toBeGreaterThanOrEqual(1);
  await expect(page.locator('#objectiveText')).toHaveText('Sell your haul at the Sell Chest');
  await useStation(page,205,250);
  await expect(page.locator('#objectiveText')).toContainText('Mine Emberstone');
  await page.evaluate(()=>{
    window.__everDeeperTest.setPosition(455,250);
    window.__everDeeperTest.interact();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.pickaxeLevel).toBe(4);
  await page.evaluate(()=>window.__everDeeperTest.grantCargo('emberstone',99));
  await expect(page.locator('#objectiveText')).toHaveText('Forge the Ember Pickaxe');
  await expect(page.locator('#objectiveRequirements')).toContainText('100/100');
  await page.evaluate(()=>window.__everDeeperTest.grantGold(650));
  await useStation(page,455,250);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.pickaxeLevel).toBe(5);
  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.setPosition(2700,650);
  });
  await page.waitForTimeout(2400);
  await page.screenshot({path:testInfo.outputPath('emberdeep-foundry.png'),fullPage:true});
  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.emberdeepUnlocked).toBe(true);
  expect(snapshot.state.pickaxeLevel).toBe(5);
});

test('clearing a connected ore vein grants its completion bonus',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.breakVeinRock('copper_run',0);
    window.__everDeeperTest.setPosition(945,1025);
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  let vein=snapshot.veins.find(item=>item.id==='copper_run');
  expect(vein.status).toBe('active');
  expect(vein.broken).toBe(1);
  await expect(page.locator('#objectiveText')).toHaveText('Sell your haul at the Sell Chest');

  await page.evaluate(()=>{
    window.__everDeeperTest.breakVeinRock('copper_run',1);
    window.__everDeeperTest.breakVeinRock('copper_run',2);
    window.__everDeeperTest.collectGroundDrops();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  vein=snapshot.veins.find(item=>item.id==='copper_run');
  expect(vein.status).toBe('completed');
  expect(snapshot.state.veinsCompleted.copper_run).toBe(1);
  expect(snapshot.state.cargo.copper).toBeGreaterThanOrEqual(6);
  expect(snapshot.state.mined.copper).toBeGreaterThanOrEqual(6);
  await page.screenshot({path:testInfo.outputPath('copper-bonus-vein.png'),fullPage:true});
});

test('precision strikes crack Emberstone shell faster than held mining',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.setTimeScale(1);
    window.__everDeeperTest.setPosition(2380,335);
  });
  await page.keyboard.down('Space');
  await page.waitForTimeout(780);
  await page.keyboard.up('Space');
  await page.waitForTimeout(820);
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const heldShell=snapshot.rocks.find(rock=>rock.type==='emberstone').shell;

  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.primePrecision();
  });
  const mine=page.locator('#mineButton');
  await mine.dispatchEvent('pointerdown',{pointerId:41,pointerType:'touch'});
  await mine.dispatchEvent('pointerup',{pointerId:41,pointerType:'touch'});
  await page.waitForTimeout(780);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const precisionShell=snapshot.rocks.find(rock=>rock.type==='emberstone').shell;
  expect(precisionShell).toBeLessThan(heldShell);
});

test('a fresh precision press deals a heavy hit without breaking hold mining',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.setTimeScale(1);
    window.__everDeeperTest.setPosition(250,500);
    window.__everDeeperTest.primePrecision();
  });
  const mine=page.locator('#mineButton');
  await mine.dispatchEvent('pointerdown',{pointerId:21,pointerType:'touch'});
  await mine.dispatchEvent('pointerup',{pointerId:21,pointerType:'touch'});
  await page.waitForTimeout(850);
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const stone=snapshot.rocks.find(rock=>rock.id===1);
  expect(snapshot.state.precisionHits).toBe(1);
  expect(snapshot.focus.streak).toBe(1);
  expect(stone.hp).toBe(1);
  await expect(page.locator('#focusMeter')).toBeVisible();
  await expect(page.locator('#focusCount')).toHaveText('1/5');
});

test('rare ore is counted and sells for its full value',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.grantCargo('gold',1);
    window.__everDeeperTest.grantCargo('starshard',1);
    window.__everDeeperTest.setPosition(205,250);
  });
  await expect(page.locator('#cargoValue')).toHaveText('2');
  await page.locator('#contextButton').click();
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.gold).toBe(102);
  expect(Object.values(snapshot.state.cargo).reduce((sum,value)=>sum+value,0)).toBe(0);
  await expect(page.locator('#goldValue')).toHaveText('102');
});

test('forge explains the concrete mining improvement',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.grantGold(40);
    window.__everDeeperTest.grantCargo('copper',1);
    window.__everDeeperTest.setPosition(205,250);
  });
  await page.locator('#contextButton').click();
  await page.evaluate(()=>window.__everDeeperTest.setPosition(455,250));
  await expect(page.locator('#contextDetail')).toContainText('STONE 3 -> 2 HITS');
  await page.screenshot({path:testInfo.outputPath('forge-comparison.png'),fullPage:true});
});

test('mobile HUD fits and touch mining works',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.setPosition(790,300));
  const mine=page.locator('#mineButton');
  await mine.dispatchEvent('pointerdown',{pointerId:9,pointerType:'touch',clientX:340,clientY:650});
  await page.waitForTimeout(460);
  await mine.dispatchEvent('pointerup',{pointerId:9,pointerType:'touch',clientX:340,clientY:650});

  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.cargo.copper).toBeGreaterThanOrEqual(1);
  const layout=await page.evaluate(()=>({
    scrollWidth:document.documentElement.scrollWidth,
    clientWidth:document.documentElement.clientWidth,
    mine:document.getElementById('mineButton').getBoundingClientRect().toJSON(),
    joystick:document.getElementById('joystick').getBoundingClientRect().toJSON(),
    footer:document.querySelector('.progress-bar').getBoundingClientRect().toJSON()
  }));
  expect(layout.scrollWidth).toBe(layout.clientWidth);
  expect(layout.mine.right).toBeLessThanOrEqual(layout.clientWidth);
  expect(layout.joystick.left).toBeGreaterThanOrEqual(0);
  expect(layout.footer.bottom).toBeLessThanOrEqual((await page.viewportSize()).height);
  await page.screenshot({path:testInfo.outputPath('ever-deeper-iphone.png'),fullPage:true});
});

test('floating joystick appears at any playfield touch and keeps mining independent',async({page})=>{
  await freshGame(page);
  const canvas=page.locator('#gameCanvas'),viewport=page.locator('#viewport'),mine=page.locator('#mineButton');
  const box=await canvas.boundingBox();
  const first={x:box.x+box.width*.24,y:box.y+box.height*.36};
  const second={x:box.x+box.width*.68,y:box.y+box.height*.62};

  await canvas.dispatchEvent('pointerdown',{pointerId:301,pointerType:'touch',button:0,clientX:first.x,clientY:first.y});
  await expect(page.locator('#joystick')).toHaveCSS('opacity','1');
  let joystick=await page.locator('#joystick').evaluate(element=>({active:element.classList.contains('active'),bounds:element.getBoundingClientRect().toJSON()}));
  expect(joystick.active).toBe(true);
  expect(joystick.bounds.x+joystick.bounds.width/2).toBeCloseTo(first.x,0);expect(joystick.bounds.y+joystick.bounds.height/2).toBeCloseTo(first.y,0);

  await viewport.dispatchEvent('pointermove',{pointerId:301,pointerType:'touch',buttons:1,clientX:first.x+70,clientY:first.y-12});
  await mine.dispatchEvent('pointerdown',{pointerId:302,pointerType:'touch',button:0});
  let controls=await page.evaluate(()=>window.__everDeeperTest.snapshot().controls);
  expect(controls).toMatchObject({floatingJoystick:true,activationSurface:'gameCanvas',pressAnywhere:true,independentMinePointer:true,joystickPointer:301,mineHeld:true});
  expect(controls.moveX).toBeGreaterThan(.9);
  await mine.dispatchEvent('pointerup',{pointerId:302,pointerType:'touch',button:0});
  await viewport.dispatchEvent('pointerup',{pointerId:301,pointerType:'touch',button:0,clientX:first.x+70,clientY:first.y-12});
  controls=await page.evaluate(()=>window.__everDeeperTest.snapshot().controls);
  expect(controls).toMatchObject({joystickPointer:null,moveX:0,moveY:0,mineHeld:false});
  await expect(page.locator('#joystick')).not.toHaveClass(/active/);

  await canvas.dispatchEvent('pointerdown',{pointerId:303,pointerType:'touch',button:0,clientX:second.x,clientY:second.y});
  joystick=await page.locator('#joystick').evaluate(element=>({bounds:element.getBoundingClientRect().toJSON()}));
  expect(joystick.bounds.x+joystick.bounds.width/2).toBeCloseTo(second.x,0);expect(joystick.bounds.y+joystick.bounds.height/2).toBeCloseTo(second.y,0);
  await viewport.dispatchEvent('pointerup',{pointerId:303,pointerType:'touch',button:0,clientX:second.x,clientY:second.y});
});

test('mobile controls suppress browser gestures without sticking input',async({page})=>{
  await freshGame(page);
  const gesturePolicy=await page.evaluate(()=>(
    {
      html:getComputedStyle(document.documentElement).touchAction,
      body:getComputedStyle(document.body).touchAction,
      game:getComputedStyle(document.getElementById('game')).touchAction,
      mine:getComputedStyle(document.getElementById('mineButton')).touchAction,
      selectable:getComputedStyle(document.body).userSelect,
      contextMenuAllowed:document.getElementById('game').dispatchEvent(new MouseEvent('contextmenu',{bubbles:true,cancelable:true})),
      doubleClickAllowed:document.getElementById('gameCanvas').dispatchEvent(new MouseEvent('dblclick',{bubbles:true,cancelable:true}))
    }
  ));
  expect(gesturePolicy).toMatchObject({html:'none',body:'none',game:'none',mine:'none',selectable:'none',contextMenuAllowed:false,doubleClickAllowed:false});

  await page.evaluate(()=>window.__everDeeperTest.setPosition(740,300));
  const mine=page.locator('#mineButton');
  for(let index=0;index<2;index++){
    await mine.dispatchEvent('pointerdown',{pointerId:70+index,pointerType:'touch'});
    await mine.dispatchEvent('pointerup',{pointerId:70+index,pointerType:'touch'});
  }
  await page.waitForTimeout(250);
  await expect(mine).not.toHaveClass(/active/);
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.totalSwings).toBeGreaterThanOrEqual(1);
});

test('progress persists after refresh',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.grantGold(200);
    window.__everDeeperTest.setPosition(455,250);
  });
  await page.locator('#contextButton').click();
  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.pickaxeLevel).toBe(2);
  expect(snapshot.state.gold).toBe(170);
});

test('Ember Mastery enforces both Sunslag and gold requirements',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.setPickaxeLevel(5);
    window.__everDeeperTest.setPosition(455,250);
  });
  await expect(page.locator('#contextTitle')).toHaveText('Tempered');
  await expect(page.locator('#contextButton')).toBeDisabled();
  await expect(page.locator('#contextDetail [data-resource="sunslag"] img')).toHaveAttribute('src',/sunslag-drop\.png/);
  await expect(page.locator('#contextDetail')).toContainText('0 / 30');

  await page.evaluate(()=>window.__everDeeperTest.grantGold(450));
  await expect(page.locator('#contextButton')).toBeDisabled();
  await page.evaluate(()=>window.__everDeeperTest.grantCargo('sunslag',30));
  await expect(page.locator('#contextButton')).toBeEnabled();
  await page.locator('#contextButton').click();

  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.emberMastery).toBe(1);
  expect(snapshot.state.cargo.sunslag).toBe(0);
  expect(snapshot.state.gold).toBe(0);
  expect(snapshot.effectivePickaxe).toMatchObject({power:38,cooldown:.215,shellPower:.85,sunslagHits:4});
  await expect(page.locator('#pickaxeName')).toHaveText('Ember Pickaxe +1');
});

test('all five Ember Mastery ranks improve mining and persist',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.setPickaxeLevel(5);
    window.__everDeeperTest.grantCargo('sunslag',250);
    window.__everDeeperTest.grantGold(8650);
    window.__everDeeperTest.setPosition(455,250);
  });

  let previousPower=31;
  let previousCooldown=.23;
  const expectedSunslagHits=[4,3,2,2,1];
  for(let rank=1;rank<=5;rank++){
    await expect(page.locator('#contextButton')).toBeEnabled();
    await page.locator('#contextButton').click();
    const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    expect(snapshot.state.emberMastery).toBe(rank);
    expect(snapshot.effectivePickaxe.power).toBeGreaterThan(previousPower);
    expect(snapshot.effectivePickaxe.cooldown).toBeLessThan(previousCooldown);
    expect(snapshot.effectivePickaxe.sunslagHits).toBe(expectedSunslagHits[rank-1]);
    expect(snapshot.effectivePickaxe.bonusYield).toBeGreaterThan(.22);
    previousPower=snapshot.effectivePickaxe.power;
    previousCooldown=snapshot.effectivePickaxe.cooldown;
  }

  await expect(page.locator('#contextButton')).toBeDisabled();
  await expect(page.locator('#contextButton')).toHaveText('MASTERED');
  await expect(page.locator('#unlockLabel')).toHaveText('OPEN STARFALL DEPTHS');
  await expect(page.locator('#powerValue')).toHaveText('128');
  await expect(page.locator('#heatTutorialShade')).toBeVisible();
  await expect(page.locator('#heatTutorialTitle')).toHaveText('Heat Streak Unlocked');
  await expect(page.locator('.heat-tutorial-card')).toContainText(/UP TO 1\.30x SPEED/);
  await page.locator('#heatTutorialButton').click();
  await expect(page.locator('#heatTutorialShade')).toBeHidden();
  expect((await page.evaluate(()=>window.__everDeeperTest.snapshot())).state.cargo.sunslag).toBe(0);
  await page.screenshot({path:testInfo.outputPath('ember-mastery-complete.png'),fullPage:true});

  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  const persisted=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(persisted.state.emberMastery).toBe(5);
  expect(persisted.effectivePickaxe).toMatchObject({power:128,cooldown:.155,shellPower:1.5,sunslagHits:1});
  expect(persisted.state.heatStreakTutorialSeen).toBe(true);
});

test('Heat Streak rewards continuous mining and resets as soon as mining stops',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.setStarforgeVariant('swift');api.enterMine('mossMine');api.setPosition(180,503);api.setAim(.899,-.438);api.setMoveVector(.899,-.438);api.setMiningHeld(true);
    for(let index=0;index<65;index++)api.step(.1);
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.heatStreak).toMatchObject({unlocked:true,active:true,maxSpeed:1.3,buildSeconds:5});
  expect(snapshot.heatStreak.speedMultiplier).toBeGreaterThan(1.2);
  expect(snapshot.heatStreak.speedMultiplier).toBeLessThanOrEqual(1.3);
  await expect(page.locator('#heatMeter')).toBeVisible();
  await expect(page.locator('#heatValue')).toHaveText(snapshot.heatStreak.speedMultiplier.toFixed(2)+'x');
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.setMiningHeld(false);api.stopMove()});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.heatStreak).toMatchObject({active:false,elapsed:0,progress:0,speedMultiplier:1});
  await expect(page.locator('#heatMeter')).toBeHidden();
});

test('Depth Master breaks Sunslag shell and core with one normal swing',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.setPickaxeLevel(5);
    window.__everDeeperTest.grantMined('sunslag',15);
    window.__everDeeperTest.grantCargo('sunslag',250);
    window.__everDeeperTest.grantGold(8650);
    window.__everDeeperTest.setPosition(455,250);
  });
  for(let rank=1;rank<=5;rank++)await page.locator('#contextButton').click();
  await page.locator('#heatTutorialButton').click();

  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.setPosition(3000,1080);
  });
  const mine=page.locator('#mineButton');
  await mine.dispatchEvent('pointerdown',{pointerId:55,pointerType:'touch'});
  await mine.dispatchEvent('pointerup',{pointerId:55,pointerType:'touch'});
  await page.waitForTimeout(250);

  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const sunslag=snapshot.rocks.find(rock=>rock.type==='sunslag');
  expect(sunslag.broken).toBe(true);
  expect(snapshot.state.mined.sunslag).toBeGreaterThan(15);
});

test('Ember Mastery 5 opens Starfall Depths and its new resource loop persists',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.setPickaxeLevel(5);
    window.__everDeeperTest.grantCargo('sunslag',250);
    window.__everDeeperTest.grantGold(8650);
    window.__everDeeperTest.setPosition(3295,650);
  });

  await expect(page.locator('#contextTitle')).toHaveText('Starfall Depths');
  await expect(page.locator('#contextButton')).toBeDisabled();
  await expect(page.locator('#contextButton')).toHaveText('LOCKED 0/5');

  await page.evaluate(()=>window.__everDeeperTest.setPosition(455,250));
  for(let rank=1;rank<=5;rank++)await page.locator('#contextButton').click();
  await page.locator('#heatTutorialButton').click();
  await page.evaluate(()=>window.__everDeeperTest.setPosition(3295,650));
  await expect(page.locator('#contextButton')).toBeEnabled();
  await expect(page.locator('#contextButton')).toHaveText('OPEN');
  await page.locator('#contextButton').click();

  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.fourthUnlocked).toBe(true);

  await page.evaluate(()=>{
    window.__everDeeperTest.restoreRocks();
    window.__everDeeperTest.setPosition(3505,320);
  });
  await expect(page.locator('#areaName')).toHaveText('STARFALL DEPTHS');
  const mine=page.locator('#mineButton');
  for(let swing=0;swing<3;swing++){
    await mine.dispatchEvent('pointerdown',{pointerId:160+swing,pointerType:'touch'});
    await mine.dispatchEvent('pointerup',{pointerId:160+swing,pointerType:'touch'});
    await page.waitForTimeout(70);
  }
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.discoveredFourth).toBe(true);
  expect(snapshot.state.mined.astralite).toBeGreaterThanOrEqual(1);
  await expect(page.locator('#objectiveText')).toHaveText('Clear the Starfall Lattice');

  await page.evaluate(()=>{
    window.__everDeeperTest.breakVeinRock('starfall_lattice',0);
    window.__everDeeperTest.breakVeinRock('starfall_lattice',1);
    window.__everDeeperTest.breakVeinRock('starfall_lattice',2);
    window.__everDeeperTest.collectGroundDrops();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.veinsCompleted.starfall_lattice).toBe(1);
  expect(snapshot.state.cargo.crownstone).toBeGreaterThanOrEqual(1);
  await page.screenshot({path:testInfo.outputPath('starfall-depths.png'),fullPage:true});

  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.fourthUnlocked).toBe(true);
  expect(snapshot.state.discoveredFourth).toBe(true);
  expect(snapshot.state.mined.astralite).toBeGreaterThanOrEqual(1);
  expect(snapshot.state.cargo.crownstone).toBeGreaterThanOrEqual(1);
});

test('mined resources land in the world, require pickup, and expire cleanly',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.setPosition(650,300);
    window.__everDeeperTest.spawnGroundDrops('copper',3,740,300);
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops).toHaveLength(3);
  expect(snapshot.groundDrops.every(drop=>drop.amount===1)).toBe(true);
  expect(snapshot.state.cargo.copper).toBe(0);
  await page.waitForTimeout(180);
  await page.screenshot({path:testInfo.outputPath('ground-loot.png'),fullPage:true});

  await page.evaluate(()=>window.__everDeeperTest.collectGroundDrops());
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops.length).toBe(0);
  expect(snapshot.state.cargo.copper).toBe(3);

  await page.evaluate(()=>{
    window.__everDeeperTest.setTimeScale(0);
    window.__everDeeperTest.spawnGroundDrops('copper',1,900,500);
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops[0].z).toBeGreaterThan(7);
  const airborneDrop=snapshot.groundDrops[0];
  await page.evaluate(drop=>window.__everDeeperTest.setPosition(drop.x,drop.y),airborneDrop);
  await page.waitForTimeout(35);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops.length).toBe(0);
  expect(snapshot.state.cargo.copper).toBe(4);

  await page.evaluate(()=>{
    window.__everDeeperTest.setTimeScale(1);
    window.__everDeeperTest.spawnGroundDrops('copper',2,900,500);
    window.__everDeeperTest.expireGroundDrops();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops.length).toBe(0);
});

test('goal card yields when the player reaches the top edge',async({page})=>{
  await freshGame(page);
  const centerX=await page.evaluate(()=>window.__everDeeperTest.snapshot().camera.viewWidth/2);
  await page.evaluate(x=>window.__everDeeperTest.setPosition(x,70),centerX);
  await expect(page.locator('#objective')).toHaveClass(/player-overlap/);
  await page.evaluate(x=>window.__everDeeperTest.setPosition(x,320),centerX);
  await expect(page.locator('#objective')).not.toHaveClass(/player-overlap/);
});

test('ground drops stay inside reachable top and right edges',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.spawnGroundDrops('copper',1,-500,-500));
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops.at(-1)).toMatchObject({x:56,y:76});
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.forceGlobalLootSweep();api.enterMine('mossMine');api.spawnGroundDrops('stone',1,999999,999999)});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops.at(-1).x).toBe(snapshot.mine.width-56);
  expect(snapshot.groundDrops.at(-1).y).toBe(snapshot.mine.height-64);
});

test('one global five-minute cleanup clears loose items from every map',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.spawnGroundDrops('copper',2,900,500);api.enterMine('mossMine');api.spawnGroundDrops('stone',3,280,650);
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops).toHaveLength(5);
  expect(snapshot.groundDrops.some(drop=>drop.scene==='surface')).toBe(true);
  expect(snapshot.groundDrops.some(drop=>drop.scene==='mossMine')).toBe(true);
  expect(await page.evaluate(()=>window.__everDeeperTest.forceGlobalLootSweep())).toBe(5);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.groundDrops).toHaveLength(0);
  expect(snapshot.lootSweep.remaining).toBeGreaterThan(299);
});

test('restorative shrines grant temporary Mining Rush instead of full Focus',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const normalCooldown=snapshot.effectivePickaxe.cooldown,shrine=snapshot.mine.discovery.caverns.find(cavern=>cavern.reward.kind==='shrine');
  expect(shrine).toBeTruthy();
  await page.evaluate(shrineData=>{
    const api=window.__everDeeperTest;api.mineTerrainCell(shrineData.boundaryIndex);api.mineTerrainCell(shrineData.boundaryIndex);api.setPosition(shrineData.x,shrineData.y);api.claimPocketReward(shrineData.reward.id);
  },shrine);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.miningRush.timer).toBeGreaterThan(29);
  expect(snapshot.focus.streak).toBe(0);
  expect(snapshot.effectivePickaxe.cooldown).toBeLessThan(normalCooldown);
  await expect(page.locator('#mineHint')).toContainText('RUSH');
});

test('Wayfarer Shop sells persistent movement speed with no level cap',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.grantGold(100000000);api.setPosition(730,220)});
  await expect(page.locator('#contextPanel')).toBeVisible();
  await expect(page.locator('#contextTitle')).toContainText('Movement');
  const before=await page.evaluate(()=>window.__everDeeperTest.snapshot().movement);
  await page.locator('#contextButton').click();
  await page.evaluate(()=>{for(let level=1;level<40;level++)window.__everDeeperTest.buyMovementSpeed();window.__everDeeperTest.save()});
  let movement=await page.evaluate(()=>window.__everDeeperTest.snapshot().movement);
  expect(movement.level).toBe(40);expect(movement.multiplier).toBeGreaterThan(before.multiplier);expect(movement.nextCost).toBeGreaterThan(before.nextCost);
  await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);movement=await page.evaluate(()=>window.__everDeeperTest.snapshot().movement);
  expect(movement.level).toBe(40);expect(movement.multiplier).toBeCloseTo(3.8);
});

test('Starforge crafts and swaps three distinct endgame pickaxes',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.unlockStarfall();
    window.__everDeeperTest.setPickaxeLevel(5);
    window.__everDeeperTest.grantCargo('astralite',600);
    window.__everDeeperTest.grantCargo('crownstone',600);
    window.__everDeeperTest.setPosition(3505,155);
  });
  await expect(page.locator('#contextPanel')).toBeVisible();
  await expect(page.locator('#contextPanel')).toHaveClass(/starforge-open/);
  await expect(page.locator('#contextActions')).toBeHidden();

  const crusher=page.locator('[data-starforge="crusher"]');
  const swift=page.locator('[data-starforge="swift"]');
  const prospector=page.locator('[data-starforge="prospector"]');
  await crusher.click();
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.starforgeVariant).toBe('crusher');
  const crusherStats=snapshot.effectivePickaxe;

  await swift.click();
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.starforgeVariant).toBe('swift');
  expect(snapshot.effectivePickaxe.cooldown).toBeLessThan(crusherStats.cooldown);
  expect(snapshot.effectivePickaxe.power).toBeLessThan(crusherStats.power);

  await prospector.click();
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.starforgeVariant).toBe('prospector');
  expect(snapshot.effectivePickaxe.bonusYield).toBeGreaterThan(crusherStats.bonusYield);
  await expect(page.locator('#pickaxeName')).toHaveText('Crownseeker');
  await page.screenshot({path:testInfo.outputPath('starforge-choices.png'),fullPage:true});

  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.starforgeVariant).toBe('prospector');
  expect(snapshot.state.starforgeUnlocked).toEqual({crusher:true,swift:true,prospector:true});
  await expect(page.locator('#objectiveText')).toHaveText('Find a hidden Depth 2 entrance');
  await expect(page.locator('#unlockLabel')).toHaveText('FIND DEPTH 2 - THE DRILL AGE AWAITS');
});

test('all four regions expose a distinct biome identity without changing the world flow',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.unlockAllAreas());
  await page.evaluate(()=>window.__everDeeperTest.unlockStarfall());
  const regions=[
    [500,'mossvein','MOSSVEIN QUARRY'],[1500,'moonglass','MOONGLASS CAVERN'],
    [2600,'emberdeep','EMBERDEEP FOUNDRY'],[3800,'starfall','STARFALL DEPTHS']
  ];
  for(const [x,id,name] of regions){
    await page.evaluate(position=>window.__everDeeperTest.setPosition(position,650),x);
    await page.waitForTimeout(35);
    expect(await page.evaluate(()=>window.__everDeeperTest.snapshot().biome)).toBe(id);
    await expect(page.locator('#game')).toHaveAttribute('data-biome',id);
    await expect(page.locator('#areaName')).toHaveText(name);
  }
});

test('rapid physical pickups aggregate feedback while preserving every resource',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.spawnGroundDrops('copper',5,330,690);
    window.__everDeeperTest.collectGroundDrops();
  });
  await page.waitForTimeout(20);
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.cargo.copper).toBe(5);
  expect(snapshot.groundDrops).toHaveLength(0);
  expect(snapshot.feedback.floaters.filter(text=>text==='+5 COPPER')).toHaveLength(1);
});

test('Ember Mastery remains readable on an iPhone viewport',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.setPickaxeLevel(5);
    window.__everDeeperTest.grantCargo('sunslag',30);
    window.__everDeeperTest.grantGold(1300);
    window.__everDeeperTest.setPosition(455,250);
  });
  await page.locator('#contextButton').click();
  const layout=await page.evaluate(()=>(
    {
      width:document.documentElement.clientWidth,
      scrollWidth:document.documentElement.scrollWidth,
      panel:document.getElementById('contextPanel').getBoundingClientRect().toJSON(),
      button:document.getElementById('contextButton').getBoundingClientRect().toJSON(),
      footer:document.querySelector('.progress-bar').getBoundingClientRect().toJSON()
    }
  ));
  expect(layout.scrollWidth).toBe(layout.width);
  expect(layout.panel.left).toBeGreaterThanOrEqual(0);
  expect(layout.panel.right).toBeLessThanOrEqual(layout.width);
  expect(layout.button.right).toBeLessThanOrEqual(layout.width);
  expect(layout.footer.right).toBeLessThanOrEqual(layout.width);
  await page.screenshot({path:testInfo.outputPath('ember-mastery-iphone.png'),fullPage:true});
});

test('pickaxe-gated treasure chest opens into physical loot and persists',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.setPosition(885,205));
  await expect(page.locator('#contextTitle')).toHaveText('Ironbound Chest');
  await expect(page.locator('#contextDetail')).toContainText('Requires Iron Pickaxe');
  await expect(page.locator('#contextButton')).toHaveText('LOCKED');
  await expect(page.locator('#contextButton')).toBeDisabled();

  await page.evaluate(()=>window.__everDeeperTest.setPickaxeLevel(2));
  await expect(page.locator('#contextButton')).toHaveText('OPEN');
  await expect(page.locator('#contextButton')).toBeEnabled();
  await page.locator('#contextButton').click();

  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests.moss_ironbound).toBe(true);
  expect(snapshot.groundDrops.filter(drop=>drop.sourceChest==='moss_ironbound')).toHaveLength(3);
  expect(snapshot.state.pendingChestLoot.moss_ironbound).toEqual({coin:75});

  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests.moss_ironbound).toBe(true);
  expect(snapshot.groundDrops.filter(drop=>drop.sourceChest==='moss_ironbound')).toHaveLength(3);

  await page.evaluate(()=>window.__everDeeperTest.collectGroundDrops());
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.gold).toBe(75);
  expect(Object.values(snapshot.state.cargo).reduce((total,amount)=>total+amount,0)).toBe(0);
  expect(snapshot.state.pendingChestLoot.moss_ironbound).toBeUndefined();
});

test('deeper chest tiers require their matching progression milestone',async({page})=>{
  await freshGame(page);
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.chests.find(chest=>chest.id==='moon_reliquary').ready).toBe(false);
  expect(snapshot.chests.find(chest=>chest.id==='ember_vault').ready).toBe(false);
  expect(snapshot.chests.find(chest=>chest.id==='star_coffer').ready).toBe(false);

  await page.evaluate(()=>window.__everDeeperTest.setPickaxeLevel(4));
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.chests.find(chest=>chest.id==='moon_reliquary').ready).toBe(true);
  expect(snapshot.chests.find(chest=>chest.id==='ember_vault').ready).toBe(false);

  await page.evaluate(()=>window.__everDeeperTest.setPickaxeLevel(5));
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.chests.find(chest=>chest.id==='ember_vault').ready).toBe(true);
  expect(snapshot.chests.find(chest=>chest.id==='star_coffer').ready).toBe(false);

  await page.evaluate(()=>{
    window.__everDeeperTest.grantCargo('astralite',200);
    window.__everDeeperTest.grantCargo('crownstone',200);
    window.__everDeeperTest.forgeStarVariant('crusher');
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.chests.find(chest=>chest.id==='star_coffer').ready).toBe(true);
});

test('treasure chest interaction remains readable on iPhone',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.setPosition(600,1110));
  await expect(page.locator('#contextTitle')).toHaveText("Miner's Supply Chest");
  const layout=await page.evaluate(()=>(
    {
      width:document.documentElement.clientWidth,
      scrollWidth:document.documentElement.scrollWidth,
      panel:document.getElementById('contextPanel').getBoundingClientRect().toJSON(),
      button:document.getElementById('contextButton').getBoundingClientRect().toJSON()
    }
  ));
  expect(layout.scrollWidth).toBe(layout.width);
  expect(layout.panel.left).toBeGreaterThanOrEqual(0);
  expect(layout.panel.right).toBeLessThanOrEqual(layout.width);
  expect(layout.button.right).toBeLessThanOrEqual(layout.width);
  await page.screenshot({path:testInfo.outputPath('treasure-chest-iphone.png'),fullPage:true});
});

test('Mossvein Mine supports entry, gated passages, persistence, and exit',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.setPosition(180,830));
  await expect(page.locator('#contextTitle')).toHaveText('Mossvein Mine');
  await page.locator('#contextButton').click();

  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.scene).toBe('mossMine');
  expect(snapshot.biome).toBe('mossMine');
  expect(snapshot.state.mineDiscovered).toBe(true);

  await page.evaluate(()=>{
    window.__everDeeperTest.setTimeScale(1);
    window.__everDeeperTest.setPosition(570,640);
  });
  await page.keyboard.down('ArrowRight');
  await page.waitForTimeout(650);
  await page.keyboard.up('ArrowRight');
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.player.x).toBeLessThan(610);

  await page.evaluate(()=>{
    window.__everDeeperTest.setTimeScale(12);
    window.__everDeeperTest.setPosition(555,640);
  });
  await page.keyboard.down('Space');
  await page.waitForTimeout(1200);
  await page.keyboard.up('Space');
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.clearedMineBarriers.outer_rubble).toBe(true);

  await page.evaluate(()=>window.__everDeeperTest.setPosition(1160,640));
  const ironBefore=await page.evaluate(()=>window.__everDeeperTest.snapshot().rocks.filter(rock=>rock.barrierId==='iron_seam').map(rock=>rock.hp));
  await page.keyboard.down('Space');
  await page.waitForTimeout(300);
  await page.keyboard.up('Space');
  const ironLocked=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(ironLocked.rocks.filter(rock=>rock.barrierId==='iron_seam').map(rock=>rock.hp)).toEqual(ironBefore);

  await page.evaluate(()=>window.__everDeeperTest.setPickaxeLevel(2));
  await page.keyboard.down('Space');
  await page.waitForTimeout(1000);
  await page.keyboard.up('Space');
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.clearedMineBarriers.iron_seam).toBe(true);

  await page.evaluate(()=>{window.__everDeeperTest.setPosition(1535,1010);window.__everDeeperTest.save()});
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.scene).toBe('mossMine');
  expect(snapshot.state.clearedMineBarriers.outer_rubble).toBe(true);
  expect(snapshot.state.clearedMineBarriers.iron_seam).toBe(true);

  await page.evaluate(()=>window.__everDeeperTest.setPosition(145,640));
  await expect(page.locator('#contextTitle')).toHaveText('Return to Mossvein Quarry');
  await page.locator('#contextButton').click();
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.scene).toBe('surface');
  expect(snapshot.biome).toBe('mossvein');
});

test('Mossvein Mine remains readable on an iPhone viewport',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine());
  await page.evaluate(()=>window.__everDeeperTest.setPosition(555,640));
  await expect(page.locator('#areaName')).toHaveText('MOSSVEIN MINE');
  await expect(page.locator('#objectiveText')).toHaveText('Hold MINE near a rock');
  await page.screenshot({path:testInfo.outputPath('mossvein-mine-mobile.png'),fullPage:true});
  await page.evaluate(()=>window.__everDeeperTest.setPosition(145,640));
  await expect(page.locator('#contextTitle')).toHaveText('Return to Mossvein Quarry');
  const layout=await page.evaluate(()=>{
    const panel=document.querySelector('#contextPanel').getBoundingClientRect();
    return{scrollWidth:document.documentElement.scrollWidth,width:innerWidth,panel:{left:panel.left,right:panel.right,bottom:panel.bottom},height:innerHeight};
  });
  expect(layout.scrollWidth).toBeLessThanOrEqual(layout.width);
  expect(layout.panel.left).toBeGreaterThanOrEqual(0);
  expect(layout.panel.right).toBeLessThanOrEqual(layout.width);
  expect(layout.panel.bottom).toBeLessThanOrEqual(layout.height);
});

test('every unlocked surface biome leads to its own mine layout',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.unlockStarfall();
    window.__everDeeperTest.setPickaxeLevel(5);
  });

  const cases=[
    {scene:'moonMine',surface:[1450,850],title:'Moonglass Labyrinth',resource:'moonglass',style:'moon'},
    {scene:'emberMine',surface:[2480,970],title:'Emberdeep Works',resource:'emberstone',style:'ember'},
    {scene:'starMine',surface:[3505,1000],title:'Starfall Hollow',resource:'astralite',style:'star'}
  ];
  const signatures=new Set();

  for(const mine of cases){
    await page.evaluate(([x,y])=>window.__everDeeperTest.setPosition(x,y),mine.surface);
    await expect(page.locator('#contextTitle')).toHaveText(mine.title);
    await page.locator('#contextButton').click();
    await expect(page.locator('#areaName')).toHaveText(mine.title.toUpperCase());

    const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    expect(snapshot.scene).toBe(mine.scene);
    expect(snapshot.mine.style).toBe(mine.style);
    expect(snapshot.mine.barrierIds).toHaveLength(2);
    expect(snapshot.rocks.some(rock=>rock.scene===mine.scene&&rock.type===mine.resource)).toBe(true);
    signatures.add([snapshot.mine.width,snapshot.mine.height,snapshot.mine.solidCount,snapshot.mine.labels.join('|')].join(':'));

    await page.evaluate(()=>window.__everDeeperTest.exitMine());
    expect((await page.evaluate(()=>window.__everDeeperTest.snapshot())).scene).toBe('surface');
  }

  expect(signatures.size).toBe(cases.length);
});

test('physical biome walls keep each opened gate as the only surface passage',async({page})=>{
  await freshGame(page);
  let boundaries=await page.evaluate(()=>window.__everDeeperTest.snapshot().surfaceBoundaries);
  expect(boundaries).toMatchObject({premiumAssets:true,fullHeightAssets:true,naturalAssetOpenings:true,legacyCanvasWalls:false,legacyRectangularGateCuts:false,groundBlendWidth:24,gateOnlyPassage:true,persistentAfterUnlock:true,portalFocus:true});expect(boundaries.walls).toHaveLength(3);expect(Object.values(boundaries.assets)).toEqual(['assets/surface/boundary-mossvein-moonglass.png','assets/surface/boundary-moonglass-emberdeep.png','assets/surface/boundary-emberdeep-starfall.png']);
  const boundaryArt=await page.evaluate(paths=>Promise.all(Object.values(paths).map(src=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve({width:image.naturalWidth,height:image.naturalHeight});image.onerror=()=>resolve({width:0,height:0});image.src=src}))),boundaries.assets);
  expect(boundaryArt.every(asset=>asset.width===1024&&asset.height===1536)).toBe(true);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.setPosition(900,650);api.setMoveVector(1,0);api.step(.6);api.stopMove()});
  expect((await page.evaluate(()=>window.__everDeeperTest.snapshot().player.x))).toBeLessThanOrEqual(950);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.unlockAllAreas();api.unlockStarfall();api.setPosition(1060,650);api.setMoveVector(1,0);api.step(.6);api.stopMove()});
  expect((await page.evaluate(()=>window.__everDeeperTest.snapshot().player.x))).toBeGreaterThan(1110);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.setPosition(1000,220);api.setMoveVector(1,0);api.step(.6);api.stopMove()});
  expect((await page.evaluate(()=>window.__everDeeperTest.snapshot().player.x))).toBeLessThanOrEqual(1026);
});

test('every mine requires its final ore gate before the right-side deep descent',async({page})=>{
  await freshGame(page);await page.evaluate(()=>{window.__everDeeperTest.unlockAllAreas();window.__everDeeperTest.unlockStarfall()});
  for(const scene of ['mossMine','moonMine','emberMine','starMine']){
    await page.evaluate(value=>window.__everDeeperTest.enterMine(value),scene);const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot()),wall=snapshot.mine.deepAccess;
    expect(wall).toMatchObject({x:0,role:'deepAccessWall',barrierId:snapshot.mine.barrierIds.at(-1)});expect(snapshot.mine).toMatchObject({unbreakableWallPremiumAsset:true,mineableTerrainUsesUnbreakableAsset:false,legacyCanvasSolidWalls:false,deepAccessPremiumAsset:true,legacyCanvasDeepAccessFace:false,visibleWallFaces:true});expect(snapshot.mine.deepAccessWallAsset).toBe(snapshot.mine.unbreakableWallAsset);expect(snapshot.mine.deepAccessWallAsset).toMatch(/unbreakable-wall\.png$/);expect(wall.w).toBeLessThan(snapshot.mine.width-52);expect(await page.evaluate(({x,y})=>window.__everDeeperTest.mineCollisionAt(x,y),{x:wall.w-80,y:wall.y+70})).toBe(true);
    const firstCavern=snapshot.mine.discovery.caverns[0];expect(wall.y+wall.h).toBeLessThan(firstCavern.y-firstCavern.ry);await page.evaluate(()=>window.__everDeeperTest.exitMine());
  }
});

test('all mine layouts remain readable and distinct across viewports',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.unlockStarfall();
    window.__everDeeperTest.setPickaxeLevel(5);
  });

  const cases=[
    {scene:'moonMine',position:[790,700]},
    {scene:'emberMine',position:[1080,680]},
    {scene:'starMine',position:[1260,725]}
  ];
  for(const mine of cases){
    await page.evaluate(scene=>window.__everDeeperTest.enterMine(scene),mine.scene);
    await page.evaluate(([x,y])=>window.__everDeeperTest.setPosition(x,y),mine.position);
    const layout=await page.evaluate(()=>({width:innerWidth,height:innerHeight,scrollWidth:document.documentElement.scrollWidth,canvas:document.getElementById('gameCanvas').getBoundingClientRect().toJSON()}));
    expect(layout.scrollWidth).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.width).toBeGreaterThan(0);
    expect(layout.canvas.height).toBeGreaterThan(0);
    await page.screenshot({path:testInfo.outputPath(mine.scene+'-layout.png'),fullPage:true});
    await page.evaluate(()=>window.__everDeeperTest.exitMine());
  }
});

test('mine nodes never respawn inside permanent walls',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.unlockStarfall();
  });

  for(const scene of ['mossMine','moonMine','emberMine','starMine']){
    await page.evaluate(mineScene=>window.__everDeeperTest.enterMine(mineScene),scene);
    const blockedNodes=await page.evaluate(()=>{
      const snapshot=window.__everDeeperTest.snapshot();
      return snapshot.rocks
        .filter(rock=>rock.scene===snapshot.scene&&rock.depth===snapshot.mine.depth&&!rock.barrierId)
        .filter(rock=>snapshot.mine.solids.some(solid=>
          rock.x+42>solid.x&&rock.x-42<solid.x+solid.w&&
          rock.y+42>solid.y&&rock.y-42<solid.y+solid.h
        ))
        .map(rock=>({id:rock.id,type:rock.type,x:rock.x,y:rock.y}));
    });
    expect(blockedNodes).toEqual([]);
    await page.evaluate(()=>window.__everDeeperTest.exitMine());
  }
});

test('every new mine passage can be cleared with the intended pickaxe',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.unlockStarfall();
    window.__everDeeperTest.setPickaxeLevel(5);
  });
  const cases=[
    {scene:'moonMine',mineTime:900,barriers:[['moon_prism_gate',435,695],['moon_star_lock',955,505]]},
    {scene:'emberMine',mineTime:1200,barriers:[['ember_bulkhead',455,625],['ember_crucible_lock',1165,452]]},
    {scene:'starMine',mineTime:3000,barriers:[['star_bridge_lock',800,725],['star_crown_lock',1550,460]]}
  ];

  for(const mine of cases){
    await page.evaluate(scene=>window.__everDeeperTest.enterMine(scene),mine.scene);
    for(const [barrier,x,y] of mine.barriers){
      await page.evaluate(([px,py])=>window.__everDeeperTest.setPosition(px,py),[x,y]);
      await page.keyboard.down('Space');
      await page.waitForTimeout(mine.mineTime);
      await page.keyboard.up('Space');
      expect((await page.evaluate(()=>window.__everDeeperTest.snapshot())).state.clearedMineBarriers[barrier]).toBe(true);
    }
    await page.evaluate(()=>window.__everDeeperTest.exitMine());
  }
});

test('mine terrain can be excavated into a persistent player-made tunnel',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.enterMine('mossMine');
    window.__everDeeperTest.setAim(1,0);
  });
  const before=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(before.mine.terrain.cellCount).toBeGreaterThan(1000);
  expect(before.mine.terrain.target).not.toBeNull();

  await page.keyboard.down('Space');
  await page.waitForTimeout(420);
  await page.keyboard.up('Space');
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.terrain.dugCells).toBeGreaterThan(0);
  expect(snapshot.state.mined.stone).toBeGreaterThan(0);

  const dug=snapshot.mine.terrain.dugCells;
  await page.evaluate(()=>window.__everDeeperTest.save());
  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.scene).toBe('mossMine');
  expect(snapshot.mine.terrain.dugCells).toBe(dug);
});

test('expanded mine depths use lazy terrain chunks and a following camera',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.build).toEqual({version:'0.38.1',name:'UNDERGROUND HUB'});
  expect(snapshot.assetVersion).toBe('03801');
  expect(snapshot.entranceAssetRendering).toEqual({mossMine:true,moonMine:true,emberMine:true,starMine:true});
  expect(snapshot.surfaceAssetRendering).toEqual({mossveinGround:true,mainRoad:{mossvein:'assets/surface/road-mossvein.png',moonglass:'assets/surface/road-moonglass.png',emberdeep:'assets/surface/road-emberdeep.png',starfall:'assets/surface/road-starfall.png'},seamlessBiomeRoad:true,roadCrossfadeWidth:80,mossveinMineApproach:'assets/surface/mossvein-mine-path.png',mossveinMineApproachBounds:{x:125,y:728,w:700,h:200},mossveinMinePosition:{x:180,y:830},branchUnderMainRoad:true,naturalCaveOverlap:true,naturalRoadOverlap:true,legacyBakedMainRoad:false,legacyMossveinGrid:false,legacyMossveinPath:false,legacyMossveinDecorations:false});
  expect(snapshot.starterRendering).toEqual({sellStation:'assets/surface/assay-station.png',forgeStation:'assets/surface/forge-station.png',storageChest:'assets/surface/storage-chest.png',wayfarerShop:'assets/surface/wayfarer-shop.png',treasureClosed:'assets/surface/treasure-cache-closed.png',treasureOpen:'assets/surface/treasure-cache-open.png',groundDrops:COMPLETE_DROP_PATHS,legacyCanvasStations:false,legacyMossveinChests:false,legacyStarterDrops:false});
  expect(snapshot.resourceRendering).toMatchObject({paths:COMPLETE_DROP_PATHS,completeResourceSet:true,sharedWorldAndUiAssets:true,transparentBoundsNormalized:true,nodeAssetCoverage:true,objectiveIcons:true,inventoryIcons:true,storageIcons:true,recipeIcons:true,ledgerIcons:true,croppedGroundDrops:true,legacyCanvasResourceSymbols:false,legacyCanvasResourceDrops:false});
  expect(snapshot.starterGateRendering).toEqual(STARTER_GATE_RENDERING);
  expect(snapshot.discoveryRendering).toEqual({crystalPocketAsset:'assets/mossvein/magic-crystal-pocket.png',cacheAsset:'assets/mossvein/buried-cache.png',shrineAsset:'assets/mossvein/mining-rush-shrine.png',legacyCavernRings:false,legacyMossveinPocketRewards:false,biomeGlow:true,routineDiscoveryText:false,rareDiscoveryText:false});
  expect(snapshot.bonusVeinRendering).toEqual({worldLabels:false,textPrompts:false,sleepingCracks:true,movingReadyPulse:true,radialTimer:true,completionBurst:true});
  expect(snapshot.mineralNodeRenderScale).toBe(.85);
  expect(snapshot.assetRendering).toEqual({stone:['node'],copper:['wall','node'],gold:['wall','node']});
  expect(snapshot.mine.height).toBeGreaterThanOrEqual(5000);
  expect(snapshot.mine.terrain.chunkCells).toBe(16);
  expect(snapshot.mine.terrain.activeChunks).toBeLessThan(snapshot.mine.terrain.totalChunks);

  await page.evaluate(()=>window.__everDeeperTest.setPosition(960,4300));
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.camera.y).toBeGreaterThan(3500);
  expect(snapshot.player.y).toBe(4300);
  expect(snapshot.mine.terrain.target).not.toBeNull();
  expect(snapshot.mine.terrain.activeChunks).toBeLessThan(snapshot.mine.terrain.totalChunks);
});

test('the exact build version is always visible in the game HUD',async({page})=>{
  await freshGame(page);
  await expect(page.locator('#buildVersion')).toHaveText('v0.38.1');
  await expect(page.locator('.brand-logo')).toHaveAttribute('alt','Ever Deeper');
  await expect(page.locator('.brand-logo')).toHaveJSProperty('complete',true);
  await page.locator('#menuButton').click();
  await expect(page.locator('#menuBuildVersion')).toHaveText('EVER DEEPER v0.38.1 · UNDERGROUND HUB');
});

test('premium start menu owns continue, new game, achievements, and settings',async({page})=>{
  await page.goto('/');await page.waitForFunction(()=>window.__everDeeperTest);
  await expect(page.locator('#startScreen')).toBeVisible();
  await expect(page.locator('#continueButton')).toBeDisabled();
  await expect(page.locator('.start-logo')).toHaveAttribute('src','assets/branding/ever-deeper-logo.png?v=03801');
  await page.locator('#startAchievementsButton').click();
  await expect(page.locator('#achievementsPanel')).toBeVisible();
  await expect(page.locator('.menu-tabs')).toBeHidden();
  await page.locator('#resumeButton').click();
  await page.locator('#startSettingsButton').click();
  await expect(page.locator('#settingsPanel')).toBeVisible();
  await expect(page.locator('.menu-tabs')).toBeHidden();
  await page.locator('#resumeButton').click();
  await page.locator('#newGameButton').click();
  await expect(page.locator('#startScreen')).toBeHidden();
  await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);
  await expect(page.locator('#continueButton')).toBeEnabled();
  expect(await page.evaluate(()=>window.__everDeeperTest.snapshot().startMenu)).toMatchObject({visible:true,hasSave:true,actions:['continue','new-game','achievements','settings'],achievementsInPause:false});
});

test('settings opens first and keeps audio choices separate from stats',async({page})=>{
  await freshGame(page);
  await expect(page.locator('#menuButton')).toHaveAttribute('aria-label','Open settings');
  await page.locator('#menuButton').click();
  await expect(page.locator('#menuTitle')).toHaveText('Settings');
  await expect(page.locator('#settingsPanel')).toBeVisible();
  await page.locator('#musicToggle').click();
  await expect(page.locator('#musicToggle')).toHaveAttribute('aria-pressed','false');
  await page.locator('#patchNotesButton').click();
  await expect(page.locator('#menuTitle')).toHaveText('Patch Notes');
  await expect(page.locator('#patchNotesPanel')).toBeVisible();
  const patchNotes=page.locator('.patch-note');
  await expect(patchNotes).toHaveCount(33);
  await expect(page.locator('.patch-note.latest')).toContainText('v0.38.1');
  await expect(page.locator('.patch-note.latest')).toContainText('three-point crown');
  await expect(patchNotes.filter({hasText:'v0.37.4'})).toContainText('same high three-quarter perspective');
  await expect(patchNotes.filter({hasText:'v0.37.4'})).toContainText('west to east');
  await expect(patchNotes.filter({hasText:'v0.37.3'})).toContainText('brief light through its premium silhouette');
  await expect(patchNotes.filter({hasText:'v0.37.2'})).toContainText('dedicated premium mining sheets');
  await expect(patchNotes.filter({hasText:'v0.37.1'})).toContainText('old canvas rings and procedural debris are gone');
  await expect(patchNotes.filter({hasText:'v0.37.0'})).toContainText('premium environmental drift');
  await expect(patchNotes.filter({hasText:'v0.37.0'})).toContainText('Footsteps disturb the ground');
  await expect(patchNotes.filter({has:page.locator('header span',{hasText:/^v0\.35\.11$/})})).toContainText('70 Phase Crystal');
  await expect(patchNotes.filter({hasText:'v0.35.10'})).toContainText('DEEPCORE DRILL REQUIRED');
  await expect(patchNotes.filter({hasText:'v0.35.9'})).toContainText('Eight unreachable Astralite nodes');
  await expect(patchNotes.filter({hasText:'v0.35.8'})).toContainText('30, 40, 50, 60, and 70');
  await expect(patchNotes.filter({hasText:'v0.35.7'})).toContainText('Holding Mine');
  await expect(patchNotes.filter({hasText:'v0.35.6'})).toContainText('painted width');
  await expect(patchNotes.filter({hasText:'v0.35.5'})).toContainText('tink-tink-tink');
  await expect(patchNotes.filter({hasText:'v0.35.4'})).toContainText('complete passage');
  await expect(patchNotes.filter({hasText:'v0.35.3'})).toContainText('natural openings');
  await expect(patchNotes.filter({hasText:'v0.35.2'})).toContainText('unbreakable-wall PNG');
  await expect(patchNotes.filter({has:page.locator('header span',{hasText:/^v0\.35\.1$/})})).toContainText('production PNGs');
  await expect(patchNotes.filter({hasText:'v0.35.0'})).toContainText('Physical biome walls');
  await expect(patchNotes.filter({hasText:'v0.34.7'})).toContainText('Gameplay, balance, progression, controls, and visuals are unchanged');
  await expect(patchNotes.filter({hasText:'v0.34.6'})).toContainText('Reset All Progress');
  await expect(patchNotes.filter({hasText:'v0.34.1'})).toContainText('100 Emberstone');
  await expect(patchNotes.filter({hasText:'v0.34.1'})).toContainText('200 Astralite and 200 Crownstone');
  await expect(page.locator('#resumeButton')).toHaveText('BACK TO SETTINGS');
  await page.locator('#resumeButton').click();
  await expect(page.locator('#settingsPanel')).toBeVisible();
  await page.locator('#statsTab').click();
  await expect(page.locator('#menuTitle')).toHaveText('Stats');
  await expect(page.locator('#statsPanel')).toBeVisible();
  await expect(page.locator('#achievementsTab')).toHaveCount(0);
  await page.reload();
  await page.locator('#continueButton').click();
  await page.locator('#menuButton').click();
  await expect(page.locator('#musicToggle')).toHaveAttribute('aria-pressed','false');
});

test('one text-free visual guide leads to the next action and fades nearby',async({page})=>{
  await freshGame(page);
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'rock',scene:'surface',visible:true}));
  expect(snapshot.markerStyle.bonusVeinRings).toBe(false);
  expect(snapshot.miningFeedbackRendering).toEqual({routineImpactRings:false,routineBreakRings:false,routineImpactParticles:false,routineBreakParticles:false,discoveryCanvasBursts:false,upgradeCanvasRings:false,routineDamageText:false,routineBreakText:false,routinePickupText:false,majorEventTextOnly:true,premiumTerrainResponses:true,dedicatedImpactSheets:true,nonStackingImpactAssets:true,premiumSaleAssets:true,drillVibration:true,drillVibrationMaxOffset:2.05,cameraShake:false});
  await page.evaluate(guide=>window.__everDeeperTest.setPosition(guide.x,guide.y),snapshot.guide);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.guide.visible).toBe(false);
  await page.evaluate(()=>{window.__everDeeperTest.grantMined('stone',1);window.__everDeeperTest.grantCargo('stone',1)});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'sell',scene:'surface'}));
  await expect(page.locator('#objectiveText')).toHaveText('Sell your haul at the Sell Chest');
});

test('each mine hides one persistent random entrance to a contrasting Depth 2',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{window.__everDeeperTest.unlockAllAreas();window.__everDeeperTest.unlockStarfall()});
  for(const scene of ['mossMine','moonMine','emberMine','starMine']){
    await page.evaluate(sceneId=>window.__everDeeperTest.enterMine(sceneId),scene);
    let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    expect(snapshot.depth).toBe(1);
    expect(snapshot.mine.depthEntrance).toMatchObject({scene,discovered:false});
    expect(snapshot.mine.depthEntrance.boundaryIndex).not.toBeNull();
    expect(snapshot.mine.dirt).not.toBe(snapshot.mine.floor);
    const entrance={x:snapshot.mine.depthEntrance.x,y:snapshot.mine.depthEntrance.y};
    expect(await page.evaluate(()=>window.__everDeeperTest.discoverDepthEntrance())).toBe(true);
    if(scene==='starMine')await page.evaluate(()=>{const api=window.__everDeeperTest;api.setPickaxeLevel(5);api.setDrillLevel(3)});
    expect(await page.evaluate(()=>window.__everDeeperTest.enterDepth())).toBe(true);
    snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    expect(snapshot.depth).toBe(2);
    expect(snapshot.mine.terrain.maxHp).toBeGreaterThan(8);
    expect(snapshot.mine.dirt).not.toBe(snapshot.mine.floor);
    expect(snapshot.mine.discovery.deposits.length).toBeGreaterThanOrEqual(14);
    expect(snapshot.mine.discovery.deposits.every(deposit=>deposit.drillGated||Object.values(snapshot.mine.depthResources).includes(deposit.type))).toBe(true);
    expect(snapshot.mine.depthStations).toEqual(expect.objectContaining({sell:expect.any(Object),forge:expect.any(Object)}));
    expect(snapshot.mine.depthEntrance).toMatchObject({...entrance,discovered:true});
    expect(await page.evaluate(()=>window.__everDeeperTest.exitDepth())).toBe(true);
    await page.evaluate(()=>window.__everDeeperTest.exitMine());
  }
});

test('drill-gated materials route progression back through earlier Depth 2 mines',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.unlockAllAreas();api.unlockStarfall();api.enterMine('mossMine');api.discoverDepthEntrance();api.enterDepth();api.setStarforgeVariant('swift');
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const starforgeCooldown=snapshot.effectivePickaxe.cooldown;
  expect(snapshot.mine.depthResources).toEqual({main:'rootiron',secondary:'deepstone',rare:'ambercore'});
  const mossGate=snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='burrowsteel');
  expect(mossGate).toEqual(expect.objectContaining({requiresDrillLevel:1,drillGated:true}));
  expect(snapshot.state.drillGoalScene).toBe('mossMine');
  await expect(page.locator('#objectiveText')).toHaveText('Mine Rootiron for Burrower Drill');
  await expect(page.locator('#objectiveDetail')).toContainText('ROOTWOUND DEPTHS');
  const lockedHit=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),mossGate.id);
  expect(lockedHit.after).toEqual(lockedHit.before);

  await page.evaluate(()=>{const api=window.__everDeeperTest;api.grantGold(5000);api.grantCargo('rootiron',50);api.grantCargo('ambercore',5);api.grantCargo('copper',3);api.sellCargo()});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.cargo).toEqual(expect.objectContaining({rootiron:50,ambercore:5,copper:0}));
  await expect(page.locator('#objectiveDetail')).toHaveText('READY AT ANY DEPTH 2 DRILL FORGE');
  await page.evaluate(()=>window.__everDeeperTest.upgradeDrill());
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.drillLevel).toBe(1);expect(snapshot.effectivePickaxe.name).toBe('Burrower Drill');expect(snapshot.effectivePickaxe.cooldown).toBeLessThan(starforgeCooldown);
  expect(snapshot.toolMode).toBe('drill');
  await expect(page.locator('#mineAction')).toHaveText('DRILL');
  await expect(page.locator('#objectiveText')).toHaveText('Mine Burrowsteel for Pulse Drill');
  const unlockedHit=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),mossGate.id);
  expect(unlockedHit.after).not.toEqual(unlockedHit.before);

  await page.evaluate(()=>{const api=window.__everDeeperTest;api.grantGold(12000);api.grantCargo('burrowsteel',60)});
  await expect(page.locator('#objectiveText')).toHaveText('Mine Prismite for Pulse Drill');
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.exitDepth();api.exitMine();api.enterMine('moonMine');api.discoverDepthEntrance();api.enterDepth();api.grantCargo('prismite',40)});
  await expect(page.locator('#objectiveText')).toHaveText('Mine Lunacore for Pulse Drill');
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.grantCargo('lunacore',4);api.upgradeDrill()});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.drillLevel).toBe(2);expect(snapshot.effectivePickaxe.name).toBe('Pulse Drill');
  const moonGate=snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='phasecrystal');
  expect(moonGate).toEqual(expect.objectContaining({requiresDrillLevel:2,drillGated:true}));
  await expect(page.locator('#objectiveText')).toHaveText('Mine Phase Crystal for Deepcore Drill');
  await expect(page.locator('#objectiveDetail')).toContainText('PRISMATIC DEPTHS');
  const moonHit=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),moonGate.id);
  expect(moonHit.after).not.toEqual(moonHit.before);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.grantCargo('phasecrystal',70);api.exitDepth();api.exitMine();api.enterMine('emberMine');api.discoverDepthEntrance();api.enterDepth()});
  await expect(page.locator('#objectiveText')).toHaveText('Mine Magmaite for Deepcore Drill');
  await expect(page.locator('#objectiveDetail')).toContainText('MOLTEN DEPTHS');
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const emberGate=snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='infernium');
  expect(emberGate).toEqual(expect.objectContaining({requiresDrillLevel:2,drillGated:true}));
  await page.evaluate(()=>window.__everDeeperTest.grantCargo('magmaite',50));
  await expect(page.locator('#objectiveText')).toHaveText('Mine Furnace Heart for Deepcore Drill');
  await page.evaluate(()=>window.__everDeeperTest.grantCargo('furnaceheart',5));
  await expect(page.locator('#objectiveText')).toHaveText('Mine Infernium for Deepcore Drill');
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.grantCargo('infernium',70);api.grantGold(25000);api.upgradeDrill();api.save()});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.drillLevel).toBe(3);expect(snapshot.effectivePickaxe.name).toBe('Deepcore Drill');
  expect(snapshot.goal).toEqual({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'});
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'depth-exit',scene:'emberMine',depth:2,x:snapshot.mine.depthEntrance.x,y:snapshot.mine.depthEntrance.y,color:'#ffd080',closeRadius:108}));
  await expect(page.locator('#objectiveText')).toHaveText('Enter Starfall Hollow');
  await expect(page.locator('#objectiveDetail')).toHaveText('THE FINAL DESCENT AWAITS');
  await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.drillLevel).toBe(3);expect(snapshot.effectivePickaxe.name).toBe('Deepcore Drill');
  expect(snapshot.goal).toEqual({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'});
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'depth-exit',scene:'emberMine',depth:2}));
});
test('terrain strikes produce weighted mining feedback without changing targeting',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.enterMine('mossMine');
    window.__everDeeperTest.setPosition(180,503);
    window.__everDeeperTest.setAim(.899,-.438);
  });
  const target=await page.evaluate(()=>window.__everDeeperTest.snapshot().mine.terrain.target.index);
  await page.evaluate(()=>window.__everDeeperTest.mineOnce());
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.feedback.terrainHitIndex).toBe(target);
  expect(snapshot.feedback.particleCount).toBe(0);
  expect(snapshot.feedback.shake).toBe(0);
  expect(snapshot.feedback.flash).toBe(0);
  expect(snapshot.feedback.hitStop).toBeGreaterThan(0);
  expect(snapshot.mine.terrain.target.index).toBe(target);
});

test('connected discovery veins build to a clear jackpot finish',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  const deposit=await page.evaluate(()=>window.__everDeeperTest.snapshot().mine.discovery.deposits.find(item=>!item.rareFind));
  for(let index=0;index<deposit.size;index++)await page.evaluate(([id,rockIndex])=>window.__everDeeperTest.breakDepositRock(id,rockIndex),[deposit.id,index]);
  const feedback=await page.evaluate(()=>window.__everDeeperTest.snapshot().feedback);
  expect(feedback.lastDepositBeat).toEqual({id:deposit.id,type:deposit.type,broken:deposit.size,total:deposit.size,jackpot:true});
  expect(feedback.floaters).toContain('VEIN CLEARED!');
  expect(feedback.particleCount).toBe(0);
});

test('held movement targets the first blocking terrain cell instead of skipping deeper',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.enterMine('mossMine');
    window.__everDeeperTest.setPosition(180,503);
    window.__everDeeperTest.setAim(.899,-.438);
  });

  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const firstTarget=snapshot.mine.terrain.target;
  expect(firstTarget).not.toBeNull();
  expect(firstTarget.index).toBe(364);

  await page.evaluate(()=>window.__everDeeperTest.mineOnce());
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.terrain.target.index).toBe(firstTarget.index);
  expect(snapshot.mine.terrain.target.hp).toBeLessThan(firstTarget.hp);
});

test('terrain hits trigger bounded satisfaction feedback without changing targeting',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.enterMine('mossMine');
    window.__everDeeperTest.setPosition(180,503);
    window.__everDeeperTest.setAim(.899,-.438);
  });
  const before=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const target=before.mine.terrain.target;
  await page.evaluate(index=>window.__everDeeperTest.mineTerrainCell(index),target.index);
  const after=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(after.feedback.shake).toBe(0);
  expect(after.feedback.flash).toBe(0);
  expect(after.feedback.terrainHitIndex).toBe(target.index);
  expect(after.feedback.particleCount).toBe(0);
  expect(after.mine.terrain.target.index).toBe(target.index);
});

test('resources stay hidden until tunneling exposes their terrain cell',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.enterMine('mossMine');
    window.__everDeeperTest.setPosition(315,936);
    window.__everDeeperTest.setAim(1,0);
  });
  let copper=await page.evaluate(()=>window.__everDeeperTest.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.type==='copper'&&rock.x===465));
  expect(copper.exposed).toBe(false);

  await page.keyboard.down('Space');
  await page.waitForTimeout(1100);
  await page.keyboard.up('Space');
  copper=await page.evaluate(()=>window.__everDeeperTest.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.type==='copper'&&rock.x===465));
  expect(copper.exposed).toBe(true);
});

test('Discovery Pass builds deep connected ore veins and rare finds in every mine',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    window.__everDeeperTest.unlockAllAreas();
    window.__everDeeperTest.unlockStarfall();
  });
  for(const scene of ['mossMine','moonMine','emberMine','starMine']){
    await page.evaluate(sceneId=>window.__everDeeperTest.enterMine(sceneId),scene);
    const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    const veins=snapshot.mine.discovery.deposits.filter(deposit=>!deposit.rareFind&&!deposit.pocketRewardId);
    const rareFinds=snapshot.mine.discovery.deposits.filter(deposit=>deposit.rareFind);
    expect(snapshot.mine.discovery.caverns.length).toBeGreaterThanOrEqual(6);
    expect(veins.length).toBeGreaterThanOrEqual(10);
    expect(veins.every(deposit=>deposit.size>=4&&deposit.size<=10)).toBe(true);
    expect(rareFinds).toHaveLength(2);
    const generated=snapshot.rocks.filter(rock=>rock.scene===scene&&rock.depositId);
    expect(generated.some(rock=>rock.y>1500)).toBe(true);
    expect(generated.filter(rock=>rock.rareFind).every(rock=>!rock.exposed)).toBe(true);
    await page.evaluate(()=>window.__everDeeperTest.exitMine());
  }
});

test('breaking into a hidden chamber reveals its rare find and persists discovery',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const rareFind=snapshot.rocks.find(rock=>rock.scene==='mossMine'&&rock.rareFind);
  const cavern=snapshot.mine.discovery.caverns.find(item=>item.id===rareFind.cavernId);
  expect(cavern.discovered).toBe(false);
  expect(rareFind.exposed).toBe(false);

  await page.evaluate(index=>{
    window.__everDeeperTest.mineTerrainCell(index);
    window.__everDeeperTest.mineTerrainCell(index);
    window.__everDeeperTest.save();
  },cavern.boundaryIndex);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.discovery.caverns.find(item=>item.id===cavern.id).discovered).toBe(true);
  expect(snapshot.rocks.find(rock=>rock.id===rareFind.id).exposed).toBe(true);
  expect(snapshot.feedback.lastDiscovery).toMatchObject({type:rareFind.type,rare:true});
  expect(snapshot.feedback.particleCount).toBe(0);

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.discoveredCaverns[cavern.id]).toBe(true);
  expect(snapshot.rocks.find(rock=>rock.id===rareFind.id).exposed).toBe(true);
});

test('every hidden pocket contains a persistent useful reward',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.discovery.caverns.every(cavern=>cavern.reward&&['cache','crystal','motherlode','shrine'].includes(cavern.reward.kind))).toBe(true);
  const cache=snapshot.mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');
  await page.evaluate(cavern=>{
    window.__everDeeperTest.mineTerrainCell(cavern.boundaryIndex);
    window.__everDeeperTest.mineTerrainCell(cavern.boundaryIndex);
    window.__everDeeperTest.setPosition(cavern.x,cavern.y);
    window.__everDeeperTest.step(.1);
    window.__everDeeperTest.save();
  },cache);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.claimedPocketRewards[cache.reward.id]).toBe(true);
  expect(snapshot.feedback.lastPocketReward).toMatchObject({id:cache.reward.id,kind:'cache'});
  expect(snapshot.feedback.shake).toBe(0);
  expect(snapshot.feedback.flash).toBe(0);
  await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.claimedPocketRewards[cache.reward.id]).toBe(true);
});

test('resource inventory auto-sorts and the base moves between maps without loss',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{window.__everDeeperTest.grantCargo('stone',12);window.__everDeeperTest.grantCargo('copper',7)});
  await page.locator('#inventoryButton').click();
  await expect(page.locator('#inventoryShade')).toBeVisible();
  await expect(page.locator('#inventoryGrid')).toContainText('Stone');
  await expect(page.locator('#inventoryGrid')).toContainText('Copper');
  await page.locator('#autoSortButton').click();
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.cargo.stone+snapshot.state.cargo.copper).toBe(0);
  expect(snapshot.state.base.chests[0].items.stone).toBe(12);
  expect(snapshot.state.base.chests[0].items.copper).toBe(7);
  await page.locator('#inventoryCloseButton').click();

  await page.evaluate(()=>window.__everDeeperTest.setPosition(455,250));
  await expect(page.locator('#contextSecondaryButton')).toBeVisible();
  await page.locator('#contextSecondaryButton').click();
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());expect(snapshot.state.base.forge.packed).toBe(true);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  await page.locator('#inventoryButton').click();
  await page.locator('[data-base-place="forge"]').click();
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.base.forge).toMatchObject({scene:'mossMine',depth:1,packed:false});
  await page.evaluate(()=>window.__everDeeperTest.save());await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.base.forge.scene).toBe('mossMine');expect(snapshot.state.base.chests[0].items.stone).toBe(12);
});

test('Mossvein premium rendering preserves the terrain contract',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.enterMine('mossMine'));
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.visualPass).toBe('mossvein-production-art-v2');
  const art=await page.evaluate(()=>Promise.all(['assets/mossvein/cave-wall.png','assets/mossvein/cave-floor.png'].map(src=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve({src,width:image.naturalWidth,height:image.naturalHeight});image.onerror=()=>resolve({src,width:0,height:0});image.src=src}))));
  expect(art[0]).toMatchObject({width:396,height:283});
  expect(art[1]).toMatchObject({width:512,height:512});
  expect(snapshot.mine.terrain.tileSize).toBe(48);
  expect(snapshot.mine.terrain.target).not.toBeNull();
  const solidBefore=snapshot.mine.terrain.solidCells;
  await page.evaluate(()=>window.__everDeeperTest.mineTerrainCell(window.__everDeeperTest.snapshot().mine.terrain.target.index));
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.visualPass).toBe('mossvein-production-art-v2');
  expect(snapshot.mine.terrain.solidCells).toBeLessThanOrEqual(solidBefore);
});

test('Rootwound Depth 2 uses the complete production asset set',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{window.__everDeeperTest.enterMine('mossMine');window.__everDeeperTest.discoverDepthEntrance();window.__everDeeperTest.enterDepth()});
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine.name).toBe('ROOTWOUND DEPTHS');
  expect(snapshot.mine.visualPass).toBe('rootwound-production-assets-v1');
  expect(snapshot.rootwoundRendering).toEqual({floor:'assets/rootwound/floor.png',wall:'assets/rootwound/wall.png',nodes:['rootiron','deepstone','ambercore','burrowsteel'],rootironWall:'assets/rootwound/rootiron-wall.png',shaft:'assets/rootwound/depth-shaft.png',sellStation:'assets/rootwound/sell-station.png',drillForge:'assets/rootwound/drill-forge.png',legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyResourceNodes:false});
  const paths=Object.values(snapshot.rootwoundRendering).flat().filter(value=>typeof value==='string'&&value.endsWith('.png'));
  const art=await page.evaluate(paths=>Promise.all(paths.map(src=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve({src,width:image.naturalWidth,height:image.naturalHeight});image.onerror=()=>resolve({src,width:0,height:0});image.src=src}))),paths);
  expect(art).toHaveLength(6);
  expect(art.every(asset=>asset.width>=300&&asset.height>=300)).toBe(true);
});

test('real resource art is shared by goals, bags, recipes, stats and world drops',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.grantCargo('stone',1);api.sellCargo();api.unlockAllAreas();api.grantGold(100);api.setPickaxeLevel(4);api.grantMined('moonglass',1);api.grantMined('emberstone',1);api.grantCargo('emberstone',7);api.grantCargo('rootiron',3);api.step(.001);api.openInventory();
  });
  await expect(page.locator('.resource.gold .topbar-resource img')).toHaveAttribute('src',/gold-drop\.png/);
  await expect(page.locator('#objectiveRequirements [data-resource="emberstone"] img')).toHaveAttribute('src',/emberstone-drop\.png/);
  await expect(page.locator('#inventoryGrid [data-resource="emberstone"] img')).toHaveAttribute('src',/emberstone-drop\.png/);
  await expect(page.locator('#inventoryGrid [data-resource="rootiron"] img')).toHaveAttribute('src',/rootiron-drop\.png/);
  expect(await page.locator('.resource-gem').count()).toBe(0);
  await page.locator('#inventoryCloseButton').click();
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.unlockStarfall();api.setPickaxeLevel(5);api.setPosition(3505,155)});
  await expect(page.locator('[data-starforge="crusher"] [data-resource="astralite"] img')).toHaveAttribute('src',/astralite-drop\.png/);
  await expect(page.locator('[data-starforge="crusher"] [data-resource="crownstone"] img')).toHaveAttribute('src',/crownstone-drop\.png/);
  await page.locator('#menuButton').click();await page.locator('#statsTab').click();
  await expect(page.locator('.ledger-resource-label [data-resource="emberstone"] img')).toHaveAttribute('src',/emberstone-drop\.png/);
  const contract=await page.evaluate(()=>window.__everDeeperTest.snapshot().resourceRendering);
  expect(contract).toMatchObject({paths:COMPLETE_DROP_PATHS,completeResourceSet:true,sharedWorldAndUiAssets:true,transparentBoundsNormalized:true,nodeAssetCoverage:true,croppedGroundDrops:true,legacyCanvasResourceSymbols:false,legacyCanvasResourceDrops:false});
});

test('v0.38.1 exposes the complete production contracts and premium walk renderer',async({page})=>{
  await freshGame(page);
  const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.build).toEqual({version:'0.38.1',name:'UNDERGROUND HUB'});
  expect(snapshot.assetVersion).toBe('03801');
  expect(snapshot.surfaceMoonglassRendering).toEqual(SURFACE_MOONGLASS_RENDERING);
  expect(snapshot.surfaceEmberdeepRendering).toEqual(SURFACE_EMBERDEEP_RENDERING);
  expect(snapshot.moonglassRendering).toEqual(MOONGLASS_RENDERING);
  expect(snapshot.emberdeepRendering).toEqual(EMBERDEEP_RENDERING);
  expect(snapshot.prismaticRendering).toEqual(PRISMATIC_RENDERING);
  expect(snapshot.moltenRendering).toEqual(MOLTEN_RENDERING);
  expect(snapshot.surfaceStarfallRendering).toEqual(SURFACE_STARFALL_RENDERING);
  expect(snapshot.starfallRendering).toEqual(STARFALL_RENDERING);
  expect(snapshot.voidstarRendering).toEqual(VOIDSTAR_RENDERING);

  const paths=pngPaths({resources:COMPLETE_DROP_PATHS,surfaceMoonglass:SURFACE_MOONGLASS_RENDERING,surfaceEmberdeep:SURFACE_EMBERDEEP_RENDERING,surfaceStarfall:SURFACE_STARFALL_RENDERING,moonglass:MOONGLASS_RENDERING,emberdeep:EMBERDEEP_RENDERING,starfall:STARFALL_RENDERING,prismatic:PRISMATIC_RENDERING,molten:MOLTEN_RENDERING,voidstar:VOIDSTAR_RENDERING});
  const art=await inspectPngs(page,paths);
  expect(paths.length).toBeGreaterThanOrEqual(95);
  expect(art).toHaveLength(paths.length);
  expect(art.every(asset=>asset.width>=256&&asset.height>=190)).toBe(true);
});

test('Moonglass gate sinks before the mine entrance settles and leaves a permanent mark',async({page})=>{
  await freshGame(page);
  const alignedGates=await inspectPngs(page,['assets/surface/moonglass-gate.png','assets/surface/emberdeep-seal.png','assets/surface/starfall-seal.png']);
  expect(alignedGates.every(asset=>asset.height>asset.width)).toBe(true);
  const stages=await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.startMoonglassGateTransition();api.renderOnce();const start=api.snapshot().moonglassGateTransition,startLocked=api.snapshot().surfaceBoundaries.walls.find(boundary=>boundary.unlockKey==='areaUnlocked').locked;
    api.step(1.35);api.renderOnce();const middle=api.snapshot().moonglassGateTransition;
    api.step(1.2);api.renderOnce();const end=api.snapshot().moonglassGateTransition,endLocked=api.snapshot().surfaceBoundaries.walls.find(boundary=>boundary.unlockKey==='areaUnlocked').locked;
    return{start,middle,end,startLocked,endLocked,contract:api.snapshot().starterGateRendering};
  });
  expect(stages.start).toEqual({active:true,progress:0});
  expect(stages.startLocked).toBe(true);
  expect(stages.middle.active).toBe(true);expect(stages.middle.progress).toBeGreaterThan(0);expect(stages.middle.progress).toBeLessThan(1);
  expect(stages.end).toEqual({active:false,progress:1});
  expect(stages.endLocked).toBe(false);
  expect(stages.contract).toEqual(STARTER_GATE_RENDERING);
});

test('Moonglass surface portal and both bespoke chest states use production art',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.setPickaxeLevel(4);
    api.setPosition(1450,850);
    api.renderOnce();
  });
  await expect(page.locator('#contextTitle')).toHaveText('Moonglass Labyrinth');
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.surfaceMoonglassRendering.entrance).toBe('assets/entrances/moonglass-entrance.png');
  expect(snapshot.chests.find(chest=>chest.id==='moon_cache').opened).toBe(false);
  expect(snapshot.chests.find(chest=>chest.id==='moon_reliquary').opened).toBe(false);
  await page.screenshot({path:testInfo.outputPath('moonglass-portal.png'),fullPage:true});
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.setPosition(1285,1110);
    api.step(.05);
    api.renderOnce();
  });
  await expect(page.locator('#contextTitle')).toHaveText('Crystal Cache');
  await page.screenshot({path:testInfo.outputPath('moonglass-crystal-cache-closed.png'),fullPage:true});

  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.openChest('moon_cache');
    api.openChest('moon_reliquary');
    api.setPosition(2070,215);
    api.step(.05);
    api.renderOnce();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests).toEqual(expect.objectContaining({moon_cache:true,moon_reliquary:true}));
  expect(snapshot.moonglassRendering.chests).toEqual(MOONGLASS_RENDERING.chests);
  await expect(page.locator('#contextPanel')).toBeHidden();
  await page.screenshot({path:testInfo.outputPath('moonglass-reliquary-open.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests).toEqual(expect.objectContaining({moon_cache:true,moon_reliquary:true}));
});

test('Moonglass Labyrinth production barriers and hidden chamber persist',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.setPickaxeLevel(5);
    api.enterMine('moonMine');
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine).toMatchObject({name:'MOONGLASS LABYRINTH',depth:1,visualPass:'moonglass-production-assets-v1'});
  expect(snapshot.mine.barrierIds).toEqual(['moon_prism_gate','moon_star_lock']);
  expect(snapshot.moonglassRendering.barriers).toEqual(MOONGLASS_RENDERING.barriers);

  const rareFind=snapshot.rocks.find(rock=>rock.scene==='moonMine'&&rock.depth===1&&rock.rareFind);
  const cavern=snapshot.mine.discovery.caverns.find(item=>item.id===rareFind.cavernId);
  expect(cavern.discovered).toBe(false);
  expect(rareFind.exposed).toBe(false);
  await page.evaluate(({cavernId})=>{
    const api=window.__everDeeperTest;
    api.clearMineBarrier('moon_prism_gate');
    api.clearMineBarrier('moon_star_lock');
    api.discoverCavern(cavernId);
    api.save();
    api.renderOnce();
  },{cavernId:cavern.id});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.clearedMineBarriers).toEqual(expect.objectContaining({moon_prism_gate:true,moon_star_lock:true}));
  expect(snapshot.mine.discovery.caverns.find(item=>item.id===cavern.id).discovered).toBe(true);
  expect(snapshot.rocks.find(rock=>rock.id===rareFind.id).exposed).toBe(true);
  await page.evaluate(({x,y})=>window.__everDeeperTest.setPosition(x,y),{x:cavern.x,y:cavern.y});
  await page.screenshot({path:testInfo.outputPath('moonglass-hidden-chamber.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.scene).toBe('moonMine');
  expect(snapshot.state.clearedMineBarriers).toEqual(expect.objectContaining({moon_prism_gate:true,moon_star_lock:true}));
  expect(snapshot.state.discoveredCaverns[cavern.id]).toBe(true);
});

test('Prismatic Depths production portal, stations, resources, and Phase Crystal gate survive reload',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.enterMine('moonMine');
    api.discoverDepthEntrance();
    api.enterDepth();
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine).toMatchObject({name:'PRISMATIC DEPTHS',depth:2,visualPass:'prismatic-production-assets-v1'});
  expect(snapshot.mine.depthResources).toEqual({main:'prismite',secondary:'deepstone',rare:'lunacore'});
  expect(snapshot.mine.depthStations).toEqual(expect.objectContaining({sell:expect.any(Object),forge:expect.any(Object)}));
  expect(snapshot.prismaticRendering).toEqual(PRISMATIC_RENDERING);
  expect(snapshot.prismaticRendering.shaft).toBe('assets/prismatic/depth-portal.png');

  const phaseDeposit=snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='phasecrystal');
  expect(phaseDeposit).toEqual(expect.objectContaining({requiresDrillLevel:2,drillGated:true}));
  const lockedAtZero=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),phaseDeposit.id);
  expect(lockedAtZero.after).toEqual(lockedAtZero.before);
  await page.evaluate(()=>window.__everDeeperTest.setDrillLevel(1));
  const lockedAtOne=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),phaseDeposit.id);
  expect(lockedAtOne.after).toEqual(lockedAtOne.before);
  await page.evaluate(()=>window.__everDeeperTest.setDrillLevel(2));
  const unlocked=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),phaseDeposit.id);
  expect(unlocked.after).not.toEqual(unlocked.before);

  await page.evaluate(stations=>{
    const api=window.__everDeeperTest;
    api.setPosition(stations.forge.x,stations.forge.y);
    api.save();
    api.renderOnce();
  },snapshot.mine.depthStations);
  await expect(page.locator('#contextTitle')).toContainText('Drill');
  await page.screenshot({path:testInfo.outputPath('prismatic-depths-forge.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'moonMine',depth:2});
  expect(snapshot.state.drillLevel).toBe(2);
  expect(snapshot.state.discoveredDepthEntrances.moonMine).toBe(true);
  expect(snapshot.mine).toMatchObject({name:'PRISMATIC DEPTHS',visualPass:'prismatic-production-assets-v1'});
  expect(snapshot.prismaticRendering).toEqual(PRISMATIC_RENDERING);
});

test('Moonglass portal and Prismatic Depths remain readable on compact and tall phones',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.unlockAllAreas());
  const sizes=[{name:'compact',width:375,height:667},{name:'tall',width:390,height:844}];
  for(const size of sizes){
    await page.setViewportSize({width:size.width,height:size.height});
    await page.evaluate(()=>{
      const api=window.__everDeeperTest;
      api.setPosition(1450,850);
      api.step(.05);
      api.renderOnce();
    });
    await expect(page.locator('#contextPanel')).toBeVisible();
    await expect(page.locator('#contextTitle')).toHaveText('Moonglass Labyrinth');
    await page.screenshot({path:testInfo.outputPath('moonglass-portal-'+size.name+'-'+size.width+'x'+size.height+'.png'),fullPage:true});

    await page.evaluate(()=>{
      const api=window.__everDeeperTest;
      api.enterMine('moonMine');
      api.discoverDepthEntrance();
      api.enterDepth();
    });
    const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    await page.evaluate(({x,y})=>{
      const api=window.__everDeeperTest;
      api.setPosition(x,y);
      api.step(.05);
      api.renderOnce();
    },snapshot.mine.depthEntrance);
    await expect(page.locator('#areaName')).toHaveText('PRISMATIC DEPTHS');
    await expect(page.locator('#contextPanel')).toBeVisible();
    await expect(page.locator('#contextTitle')).toContainText('Depth 1');
    const layout=await page.evaluate(()=>{
      const canvas=document.getElementById('gameCanvas').getBoundingClientRect();
      const panel=document.getElementById('contextPanel').getBoundingClientRect();
      return{
        width:innerWidth,height:innerHeight,scrollWidth:document.documentElement.scrollWidth,
        canvas:{left:canvas.left,right:canvas.right,top:canvas.top,bottom:canvas.bottom,width:canvas.width,height:canvas.height},
        panel:{left:panel.left,right:panel.right,bottom:panel.bottom}
      };
    });
    expect(layout.scrollWidth).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.left).toBeGreaterThanOrEqual(0);
    expect(layout.canvas.right).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.width).toBeGreaterThan(0);
    expect(layout.canvas.height).toBeGreaterThan(0);
    expect(layout.panel.left).toBeGreaterThanOrEqual(0);
    expect(layout.panel.right).toBeLessThanOrEqual(layout.width);
    expect(layout.panel.bottom).toBeLessThanOrEqual(layout.height);
    await page.screenshot({path:testInfo.outputPath('prismatic-'+size.name+'-'+size.width+'x'+size.height+'.png'),fullPage:true});
    await page.evaluate(()=>{window.__everDeeperTest.exitDepth();window.__everDeeperTest.exitMine()});
  }
});

test('Emberdeep seal sinks through start, middle, and finish before leaving its permanent mark',async({page})=>{
  await freshGame(page);
  const stages=await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.startEmberdeepGateTransition();api.renderOnce();const start=api.snapshot().emberdeepGateTransition;
    api.step(1.35);api.renderOnce();const middle=api.snapshot().emberdeepGateTransition;
    api.step(1.2);api.renderOnce();const end=api.snapshot().emberdeepGateTransition;
    const snapshot=api.snapshot();api.save();
    return{start,middle,end,starterGate:snapshot.starterGateRendering,surface:snapshot.surfaceEmberdeepRendering};
  });
  expect(stages.start).toEqual({active:true,progress:0});
  expect(stages.middle.active).toBe(true);
  expect(stages.middle.progress).toBeGreaterThan(0);
  expect(stages.middle.progress).toBeLessThan(1);
  expect(stages.end).toEqual({active:false,progress:1});
  expect(stages.starterGate).toEqual(STARTER_GATE_RENDERING);
  expect(stages.surface).toEqual(SURFACE_EMBERDEEP_RENDERING);
  expect(stages.surface.gateMark).toBe('assets/surface/emberdeep-seal-mark.png');

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  const reloaded=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(reloaded.state.emberdeepUnlocked).toBe(true);
  expect(reloaded.emberdeepGateTransition).toEqual({active:false,progress:1});
  expect(reloaded.surfaceEmberdeepRendering.gateMark).toBe('assets/surface/emberdeep-seal-mark.png');
});

test('moved Emberdeep entrance and both foundry chest states use production art and persist',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.setPickaxeLevel(5);
    api.setPosition(2480,970);
    api.renderOnce();
  });
  await expect(page.locator('#contextTitle')).toHaveText('Emberdeep Works');
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.surfaceEmberdeepRendering).toEqual(SURFACE_EMBERDEEP_RENDERING);
  expect(snapshot.surfaceEmberdeepRendering.entrancePosition).toEqual({x:2480,y:970,radius:112});
  expect(snapshot.chests.find(chest=>chest.id==='ember_cache')).toMatchObject({x:2720,y:1160,opened:false});
  expect(snapshot.chests.find(chest=>chest.id==='ember_vault')).toMatchObject({x:3250,y:205,opened:false});
  await page.screenshot({path:testInfo.outputPath('emberdeep-entrance-moved.png'),fullPage:true});

  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.setPosition(2720,1160);
    api.step(.05);
    api.renderOnce();
  });
  await expect(page.locator('#contextTitle')).toHaveText('Foundry Lockbox');
  await page.screenshot({path:testInfo.outputPath('foundry-lockbox-closed.png'),fullPage:true});

  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.openChest('ember_cache');
    api.openChest('ember_vault');
    api.setPosition(3250,205);
    api.step(.05);
    api.renderOnce();
    api.save();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests).toEqual(expect.objectContaining({ember_cache:true,ember_vault:true}));
  expect(snapshot.surfaceEmberdeepRendering.chests).toEqual(SURFACE_EMBERDEEP_RENDERING.chests);
  await expect(page.locator('#contextPanel')).toBeHidden();
  await page.screenshot({path:testInfo.outputPath('ember-vault-open.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests).toEqual(expect.objectContaining({ember_cache:true,ember_vault:true}));
  expect(snapshot.chests.find(chest=>chest.id==='ember_cache')).toMatchObject({x:2720,y:1160,opened:true});
  expect(snapshot.chests.find(chest=>chest.id==='ember_vault')).toMatchObject({x:3250,y:205,opened:true});
});

test('Emberdeep Works production barriers and a claimed hidden pocket survive reload',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.setPickaxeLevel(5);
    api.enterMine('emberMine');
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine).toMatchObject({name:'EMBERDEEP WORKS',depth:1,visualPass:'emberdeep-production-assets-v1'});
  expect(snapshot.mine.barrierIds).toEqual(['ember_bulkhead','ember_crucible_lock']);
  expect(snapshot.emberdeepRendering).toEqual(EMBERDEEP_RENDERING);
  const pocket=snapshot.mine.discovery.caverns.find(cavern=>['cache','shrine'].includes(cavern.reward.kind));
  expect(pocket).toBeTruthy();
  expect(pocket.discovered).toBe(false);
  expect(pocket.reward.claimed).toBe(false);

  await page.evaluate(({pocketId,rewardId})=>{
    const api=window.__everDeeperTest;
    api.clearMineBarrier('ember_bulkhead');
    api.clearMineBarrier('ember_crucible_lock');
    api.discoverCavern(pocketId);
    api.claimPocketReward(rewardId);
    api.save();
    api.renderOnce();
  },{pocketId:pocket.id,rewardId:pocket.reward.id});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.clearedMineBarriers).toEqual(expect.objectContaining({ember_bulkhead:true,ember_crucible_lock:true}));
  expect(snapshot.mine.discovery.caverns.find(cavern=>cavern.id===pocket.id)).toMatchObject({discovered:true,reward:{claimed:true}});
  expect(snapshot.state.claimedPocketRewards[pocket.reward.id]).toBe(true);
  await page.evaluate(({x,y})=>window.__everDeeperTest.setPosition(x,y),{x:pocket.x,y:pocket.y});
  await page.screenshot({path:testInfo.outputPath('emberdeep-claimed-pocket.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'emberMine',depth:1});
  expect(snapshot.state.clearedMineBarriers).toEqual(expect.objectContaining({ember_bulkhead:true,ember_crucible_lock:true}));
  expect(snapshot.state.discoveredCaverns[pocket.id]).toBe(true);
  expect(snapshot.state.claimedPocketRewards[pocket.reward.id]).toBe(true);
  expect(snapshot.mine.discovery.caverns.find(cavern=>cavern.id===pocket.id).reward.claimed).toBe(true);
});

test('Molten Depths portal, stations, nodes, and Infernium Drill 2 gate survive reload',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.enterMine('emberMine');
    api.discoverDepthEntrance();
    api.enterDepth();
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine).toMatchObject({name:'MOLTEN DEPTHS',depth:2,visualPass:'molten-production-assets-v1'});
  expect(snapshot.mine.depthResources).toEqual({main:'magmaite',secondary:'deepstone',rare:'furnaceheart'});
  expect(snapshot.mine.depthStations).toEqual(expect.objectContaining({sell:expect.any(Object),forge:expect.any(Object)}));
  expect(snapshot.moltenRendering).toEqual(MOLTEN_RENDERING);
  expect(snapshot.moltenRendering.shaft).toBe('assets/molten/depth-portal.png');
  for(const type of ['magmaite','deepstone','furnaceheart','infernium']){
    expect(snapshot.rocks.some(rock=>rock.scene==='emberMine'&&rock.depth===2&&rock.type===type)).toBe(true);
    expect(snapshot.moltenRendering.nodes[type]).toBe('assets/molten/'+type+'-node.png');
  }

  const infernium=snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='infernium');
  expect(infernium).toEqual(expect.objectContaining({requiresDrillLevel:2,drillGated:true}));
  const lockedAtZero=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),infernium.id);
  expect(lockedAtZero.after).toEqual(lockedAtZero.before);
  await page.evaluate(()=>window.__everDeeperTest.setDrillLevel(1));
  const lockedAtOne=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),infernium.id);
  expect(lockedAtOne.after).toEqual(lockedAtOne.before);
  await page.evaluate(()=>window.__everDeeperTest.setDrillLevel(2));
  const unlocked=await page.evaluate(id=>window.__everDeeperTest.hitDepositRock(id,0),infernium.id);
  expect(unlocked.after).not.toEqual(unlocked.before);

  await page.evaluate(stations=>{
    const api=window.__everDeeperTest;
    api.setPosition(stations.forge.x,stations.forge.y);
    api.save();
    api.renderOnce();
  },snapshot.mine.depthStations);
  await expect(page.locator('#contextTitle')).toContainText('Drill');
  await page.screenshot({path:testInfo.outputPath('molten-depths-drill-forge.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'emberMine',depth:2});
  expect(snapshot.state.drillLevel).toBe(2);
  expect(snapshot.state.discoveredDepthEntrances.emberMine).toBe(true);
  expect(snapshot.mine).toMatchObject({name:'MOLTEN DEPTHS',visualPass:'molten-production-assets-v1'});
  expect(snapshot.moltenRendering).toEqual(MOLTEN_RENDERING);
  expect(snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='infernium')).toEqual(expect.objectContaining({requiresDrillLevel:2,drillGated:true}));
});

test('Emberdeep entrance and Molten Depths remain readable on compact and tall phones',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>window.__everDeeperTest.unlockAllAreas());
  const sizes=[{name:'compact',width:375,height:667},{name:'tall',width:390,height:844}];
  for(const size of sizes){
    await page.setViewportSize({width:size.width,height:size.height});
    await page.evaluate(()=>{
      const api=window.__everDeeperTest;
      api.setPosition(2480,970);
      api.step(.05);
      api.renderOnce();
    });
    await expect(page.locator('#contextPanel')).toBeVisible();
    await expect(page.locator('#contextTitle')).toHaveText('Emberdeep Works');
    await page.screenshot({path:testInfo.outputPath('emberdeep-entrance-'+size.name+'-'+size.width+'x'+size.height+'.png'),fullPage:true});

    await page.evaluate(()=>{
      const api=window.__everDeeperTest;
      api.enterMine('emberMine');
      api.discoverDepthEntrance();
      api.enterDepth();
    });
    const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    await page.evaluate(({x,y})=>{
      const api=window.__everDeeperTest;
      api.setPosition(x,y);
      api.step(.05);
      api.renderOnce();
    },snapshot.mine.depthEntrance);
    await expect(page.locator('#areaName')).toHaveText('MOLTEN DEPTHS');
    await expect(page.locator('#contextPanel')).toBeVisible();
    await expect(page.locator('#contextTitle')).toContainText('Depth 1');
    const layout=await page.evaluate(()=>{
      const canvas=document.getElementById('gameCanvas').getBoundingClientRect();
      const panel=document.getElementById('contextPanel').getBoundingClientRect();
      return{
        width:innerWidth,height:innerHeight,scrollWidth:document.documentElement.scrollWidth,
        canvas:{left:canvas.left,right:canvas.right,top:canvas.top,bottom:canvas.bottom,width:canvas.width,height:canvas.height},
        panel:{left:panel.left,right:panel.right,bottom:panel.bottom}
      };
    });
    expect(layout.scrollWidth).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.left).toBeGreaterThanOrEqual(0);
    expect(layout.canvas.right).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.width).toBeGreaterThan(0);
    expect(layout.canvas.height).toBeGreaterThan(0);
    expect(layout.panel.left).toBeGreaterThanOrEqual(0);
    expect(layout.panel.right).toBeLessThanOrEqual(layout.width);
    expect(layout.panel.bottom).toBeLessThanOrEqual(layout.height);
    await page.screenshot({path:testInfo.outputPath('molten-'+size.name+'-'+size.width+'x'+size.height+'.png'),fullPage:true});
    await page.evaluate(()=>{window.__everDeeperTest.exitDepth();window.__everDeeperTest.exitMine()});
  }
});

test('Starfall seal sinks through start, middle, and finish before leaving its permanent mark',async({page})=>{
  await freshGame(page);
  const stages=await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.startStarfallGateTransition();api.renderOnce();const start=api.snapshot().starfallGateTransition;
    api.step(1.35);api.renderOnce();const middle=api.snapshot().starfallGateTransition;
    api.step(1.2);api.renderOnce();const end=api.snapshot().starfallGateTransition;
    const snapshot=api.snapshot();api.save();
    return{start,middle,end,starterGate:snapshot.starterGateRendering,surface:snapshot.surfaceStarfallRendering};
  });
  expect(stages.start).toEqual({active:true,progress:0});
  expect(stages.middle.active).toBe(true);
  expect(stages.middle.progress).toBeGreaterThan(0);
  expect(stages.middle.progress).toBeLessThan(1);
  expect(stages.end).toEqual({active:false,progress:1});
  expect(stages.starterGate).toEqual(STARTER_GATE_RENDERING);
  expect(stages.surface).toEqual(SURFACE_STARFALL_RENDERING);
  expect(stages.surface.gateMark).toBe('assets/surface/starfall-seal-mark.png');

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  const reloaded=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(reloaded.state.fourthUnlocked).toBe(true);
  expect(reloaded.starfallGateTransition).toEqual({active:false,progress:1});
  expect(reloaded.surfaceStarfallRendering.gateMark).toBe('assets/surface/starfall-seal-mark.png');
});

test('moved Starfall entrance, lattice, Starforge, and both celestial chest states use production art',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.unlockStarfall();
    api.setPickaxeLevel(5);
    api.setStarforgeVariant('crusher');
    api.setPosition(3505,1000);
    api.renderOnce();
  });
  await expect(page.locator('#contextTitle')).toHaveText('Starfall Hollow');
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.surfaceStarfallRendering).toEqual(SURFACE_STARFALL_RENDERING);
  expect(snapshot.surfaceStarfallRendering.minePathBounds).toEqual({x:3450,y:760,w:650,h:289});
  expect(snapshot.surfaceStarfallRendering.minePathMouthTarget).toEqual({x:3505,y:1000});
  expect(snapshot.surfaceStarfallRendering.entrancePosition).toEqual({x:3505,y:1000,radius:112});
  expect(snapshot.rocks).toContainEqual(expect.objectContaining({type:'astralite',x:4100,y:560,veinId:null}));
  expect(snapshot.rocks.filter(rock=>rock.veinId==='starfall_lattice')).toHaveLength(3);
  expect(snapshot.chests.find(chest=>chest.id==='star_cache')).toMatchObject({opened:false});
  expect(snapshot.chests.find(chest=>chest.id==='star_coffer')).toMatchObject({opened:false});
  await page.screenshot({path:testInfo.outputPath('starfall-entrance-path-lattice.png'),fullPage:true});

  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.openChest('star_cache');
    api.openChest('star_coffer');
    api.breakVeinRock('starfall_lattice',0);
    api.breakVeinRock('starfall_lattice',1);
    api.breakVeinRock('starfall_lattice',2);
    api.collectGroundDrops();
    api.save();
    api.renderOnce();
  });
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests).toEqual(expect.objectContaining({star_cache:true,star_coffer:true}));
  expect(snapshot.state.veinsCompleted.starfall_lattice).toBe(1);
  expect(snapshot.surfaceStarfallRendering.chests).toEqual(SURFACE_STARFALL_RENDERING.chests);
  await page.screenshot({path:testInfo.outputPath('starfall-celestial-chests-open.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.openedChests).toEqual(expect.objectContaining({star_cache:true,star_coffer:true}));
  expect(snapshot.state.veinsCompleted.starfall_lattice).toBe(1);
  expect(snapshot.chests.find(chest=>chest.id==='star_cache').opened).toBe(true);
  expect(snapshot.chests.find(chest=>chest.id==='star_coffer').opened).toBe(true);
});

test('Starfall Hollow production barriers and a claimed crystal pocket survive reload',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.unlockStarfall();
    api.setPickaxeLevel(5);
    api.enterMine('starMine');
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine).toMatchObject({name:'STARFALL HOLLOW',depth:1,visualPass:'starfall-production-assets-v1'});
  expect(snapshot.mine.barrierIds).toEqual(['star_bridge_lock','star_crown_lock']);
  expect(snapshot.starfallRendering).toEqual(STARFALL_RENDERING);
  for(const type of ['astralite','crownstone']){
    expect(snapshot.rocks.some(rock=>rock.scene==='starMine'&&rock.depth===1&&rock.type===type)).toBe(true);
    expect(snapshot.starfallRendering.nodes[type]).toBe('assets/starfall/'+type+'-node.png');
  }
  const pocket=snapshot.mine.discovery.caverns.find(cavern=>['cache','shrine'].includes(cavern.reward.kind));
  expect(pocket).toBeTruthy();
  expect(pocket).toMatchObject({discovered:false,reward:{claimed:false}});

  await page.evaluate(({pocketId,rewardId})=>{
    const api=window.__everDeeperTest;
    api.clearMineBarrier('star_bridge_lock');
    api.clearMineBarrier('star_crown_lock');
    api.discoverCavern(pocketId);
    api.claimPocketReward(rewardId);
    api.save();
    api.renderOnce();
  },{pocketId:pocket.id,rewardId:pocket.reward.id});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.clearedMineBarriers).toEqual(expect.objectContaining({star_bridge_lock:true,star_crown_lock:true}));
  expect(snapshot.mine.discovery.caverns.find(cavern=>cavern.id===pocket.id)).toMatchObject({discovered:true,reward:{claimed:true}});
  expect(snapshot.state.claimedPocketRewards[pocket.reward.id]).toBe(true);
  await page.evaluate(({x,y})=>window.__everDeeperTest.setPosition(x,y),{x:pocket.x,y:pocket.y});
  await page.screenshot({path:testInfo.outputPath('starfall-claimed-pocket.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'starMine',depth:1});
  expect(snapshot.state.clearedMineBarriers).toEqual(expect.objectContaining({star_bridge_lock:true,star_crown_lock:true}));
  expect(snapshot.state.discoveredCaverns[pocket.id]).toBe(true);
  expect(snapshot.state.claimedPocketRewards[pocket.reward.id]).toBe(true);
});

test('Voidstar entry requires Deepcore and its portal, stations, and materials survive reload',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.unlockStarfall();
    api.setDrillLevel(2);
    api.enterMine('starMine');
    api.discoverDepthEntrance();
    const entrance=api.snapshot().mine.depthEntrance;
    api.setPosition(entrance.x,entrance.y);
    api.step(.05);
    api.renderOnce();
  });
  await expect(page.locator('#contextTitle')).toHaveText('Voidstar Depths');
  await expect(page.locator('#contextButton')).toBeDisabled();
  await expect(page.locator('#contextButton')).toHaveText('DEEPCORE DRILL REQUIRED');
  await expect(page.locator('#objectiveText')).toContainText(/Deepcore/i);
  expect(await page.evaluate(()=>window.__everDeeperTest.enterDepth())).toBe(false);
  expect(await page.evaluate(()=>window.__everDeeperTest.snapshot())).toMatchObject({scene:'starMine',depth:1,state:{drillLevel:2}});

  await page.evaluate(()=>{const api=window.__everDeeperTest;api.setPickaxeLevel(5);api.setDrillLevel(3)});
  expect(await page.evaluate(()=>window.__everDeeperTest.enterDepth())).toBe(true);
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.mine).toMatchObject({name:'VOIDSTAR DEPTHS',depth:2,visualPass:'voidstar-production-assets-v1'});
  expect(snapshot.mine.depthResources).toEqual({main:'voidglass',secondary:'deepstone',rare:'singularity'});
  expect(snapshot.mine.depthStations).toEqual(expect.objectContaining({sell:expect.any(Object),forge:expect.any(Object)}));
  expect(snapshot.voidstarRendering).toEqual(VOIDSTAR_RENDERING);
  expect(snapshot.voidstarRendering.shaft).toBe('assets/voidstar/depth-portal.png');
  for(const type of ['voidglass','deepstone','singularity']){
    expect(snapshot.rocks.some(rock=>rock.scene==='starMine'&&rock.depth===2&&rock.type===type)).toBe(true);
    expect(snapshot.voidstarRendering.nodes[type]).toBe('assets/voidstar/'+type+'-node.png');
  }

  await page.evaluate(stations=>{
    const api=window.__everDeeperTest;
    api.setPosition(stations.forge.x,stations.forge.y);
    api.save();
    api.renderOnce();
  },snapshot.mine.depthStations);
  await expect(page.locator('#contextTitle')).toContainText('Drill');
  await page.screenshot({path:testInfo.outputPath('voidstar-depths-drill-forge.png'),fullPage:true});

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'starMine',depth:2,state:{drillLevel:3}});
  expect(snapshot.state.discoveredDepthEntrances.starMine).toBe(true);
  expect(snapshot.mine).toMatchObject({name:'VOIDSTAR DEPTHS',visualPass:'voidstar-production-assets-v1'});
  expect(snapshot.voidstarRendering).toEqual(VOIDSTAR_RENDERING);
});

test('Deepcore guidance routes surface to Starfall, an explored shaft to Voidstar, and Depth 2 to Singularity',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.unlockStarfall();
    api.setPickaxeLevel(5);
    api.setDrillLevel(3);
  });

  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.goal).toEqual({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'});
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'mine-entrance',scene:'surface',depth:1,x:3505,y:1000,color:'#f0ddff',closeRadius:112,destination:'starMine'}));
  await expect(page.locator('#objectiveText')).toHaveText('Enter Starfall Hollow');
  await expect(page.locator('#objectiveDetail')).toHaveText('THE FINAL DESCENT AWAITS');

  await page.evaluate(()=>window.__everDeeperTest.enterMine('emberMine'));
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.goal).toEqual({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'});
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'mine-exit',scene:'emberMine',depth:1,x:145,y:1030,color:'#ffc06f',closeRadius:108}));

  await page.evaluate(()=>{const api=window.__everDeeperTest;api.exitMine();api.enterMine('starMine')});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'starMine',depth:1,state:{drillLevel:3,victory:false}});
  expect(snapshot.goal).toEqual({title:'Find the hidden Voidstar entrance',detail:'DIG DEEPER'});
  expect(snapshot.mine.depthEntrance.discovered).toBe(false);
  expect(snapshot.guide).toBeNull();

  await page.evaluate(()=>window.__everDeeperTest.discoverDepthEntrance());
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const shaft={x:snapshot.mine.depthEntrance.x,y:snapshot.mine.depthEntrance.y};
  expect(snapshot.goal).toEqual({title:'Enter Voidstar Depths',detail:'DEEPCORE DRILL READY'});
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'depth-entrance',scene:'starMine',depth:1,x:shaft.x,y:shaft.y,color:'#f2d8ff',closeRadius:108}));
  await expect(page.locator('#objectiveText')).toHaveText('Enter Voidstar Depths');
  await expect(page.locator('#objectiveDetail')).toHaveText('DEEPCORE DRILL READY');

  await page.evaluate(()=>window.__everDeeperTest.enterDepth());
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'starMine',depth:2,state:{drillLevel:3,victory:false}});
  expect(snapshot.goal).toEqual({title:'Mine a Singularity Core',detail:'THE FINAL DISCOVERY'});
  expect(snapshot.progression.finalVictory).toEqual({completed:false,requiresDrill:'Deepcore Drill',resource:'singularity',scene:'starMine',depth:2});
  expect(snapshot.guide).toEqual(expect.objectContaining({kind:'rock',scene:'starMine',depth:2,resource:'singularity',color:'#f3bfff',closeRadius:88}));
  const guidedSingularity=snapshot.rocks.find(rock=>rock.id===snapshot.guide.rockId);
  expect(guidedSingularity).toEqual(expect.objectContaining({type:'singularity',scene:'starMine',depth:2,x:snapshot.guide.x,y:snapshot.guide.y,broken:false}));
  await expect(page.locator('#objectiveText')).toHaveText('Mine a Singularity Core');
  await expect(page.locator('#objectiveDetail')).toHaveText('THE FINAL DISCOVERY');
});

test('Deepcore to Voidstar to the first Singularity completes and persists the final victory',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.unlockStarfall();
    api.setPickaxeLevel(5);
    api.setDrillLevel(3);
    api.enterMine('starMine');
    api.discoverDepthEntrance();
    api.enterDepth();
  });
  let snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'starMine',depth:2,state:{drillLevel:3,victory:false}});
  expect(snapshot.progression.finalVictory).toEqual(expect.objectContaining({completed:false}));
  const singularity=snapshot.mine.discovery.deposits.find(deposit=>deposit.type==='singularity');
  expect(singularity).toBeTruthy();

  await page.evaluate(id=>{
    const api=window.__everDeeperTest;
    api.breakDepositRock(id,0);
    api.collectGroundDrops();
    api.save();
  },singularity.id);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.state.victory).toBe(true);
  expect(snapshot.hub.unlocked).toBe(true);
  expect(snapshot.progression.endgame).toEqual({hubUnlocked:true,hubVisited:false,noPrestigeReset:true,deepElevatorOnline:false});
  expect(snapshot.progression.finalVictory).toEqual(expect.objectContaining({completed:true}));
  expect(snapshot.state.mined.singularity).toBeGreaterThanOrEqual(1);
  await expect(page.locator('#hubTutorialShade')).toBeVisible();
  await expect(page.locator('#hubTutorialTitle')).toHaveText('Underground Hub Unlocked');
  await page.locator('#hubTutorialButton').click();
  await expect(page.locator('#hubTutorialShade')).toBeHidden();

  await page.reload();
  await page.waitForFunction(()=>window.__everDeeperTest);
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot).toMatchObject({scene:'starMine',depth:2,state:{drillLevel:3,victory:true}});
  expect(snapshot.progression.finalVictory).toEqual(expect.objectContaining({completed:true}));
});

test('Underground Hub unlocks, builds by drag, stores resources, lights the room, and persists',async({page})=>{
  await freshGame(page);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.unlockHub();api.grantCargo('stone',30);api.grantGold(1000);const station=api.snapshot().hub.stations.surfaceEntrance;api.setPosition(station.x,station.y);api.step(.03)});
  await expect(page.locator('#contextPanel')).toBeVisible();
  await expect(page.locator('#contextTitle')).toHaveText('Underground Hub');
  await expect(page.locator('#contextButton')).toHaveText('DESCEND');
  await page.locator('#contextButton').click();
  await page.waitForFunction(()=>window.__everDeeperTest.snapshot().scene==='hub');
  let snapshot=await page.evaluate(()=>{const api=window.__everDeeperTest;api.step(.03);api.renderOnce();return api.snapshot()});
  expect(snapshot).toMatchObject({scene:'hub',mine:null,toolMode:'builder',hub:{active:true,visited:true,deepElevatorOnline:false,functionalStorage:true,noPrestigeReset:true}});
  expect(snapshot.goal.title).toBe('Tap BUILD and shape your Hub');
  await expect(page.locator('#areaName')).toHaveText('UNDERGROUND HUB');
  await expect(page.locator('#mineAction')).toHaveText('BUILD');

  await page.locator('#mineButton').click();
  await expect(page.locator('#hubBuildToolbar')).toBeVisible();
  await expect(page.locator('#mineAction')).toHaveText('DONE');
  const toolbarBox=await page.locator('#hubBuildToolbar').boundingBox(),doneBox=await page.locator('#mineButton').boundingBox();
  expect(toolbarBox.x+toolbarBox.width).toBeLessThanOrEqual(doneBox.x+2);
  const pointFor=async(col,row)=>page.evaluate(({col,row})=>{const snapshot=window.__everDeeperTest.snapshot(),grid=snapshot.hub.grid,rect=document.getElementById('gameCanvas').getBoundingClientRect(),scale=rect.width/snapshot.camera.viewWidth;return{x:rect.left+(grid.originX+(col+.5)*grid.tileSize-snapshot.camera.x)*scale,y:rect.top+(grid.originY+(row+.5)*grid.tileSize-snapshot.camera.y)*scale}},{col,row});
  const canvas=page.locator('#gameCanvas'),wallStart=await pointFor(3,4),wallMiddle=await pointFor(4,4),wallEnd=await pointFor(5,4);
  expect(await page.evaluate(points=>points.map(point=>document.elementFromPoint(point.x,point.y)?.id),[wallStart,wallMiddle,wallEnd])).toEqual(['gameCanvas','gameCanvas','gameCanvas']);
  await canvas.dispatchEvent('pointerdown',{pointerId:501,pointerType:'touch',button:0,buttons:1,clientX:wallStart.x,clientY:wallStart.y});
  await canvas.dispatchEvent('pointermove',{pointerId:501,pointerType:'touch',button:0,buttons:1,clientX:wallMiddle.x,clientY:wallMiddle.y});
  await canvas.dispatchEvent('pointermove',{pointerId:501,pointerType:'touch',button:0,buttons:1,clientX:wallEnd.x,clientY:wallEnd.y});
  await canvas.dispatchEvent('pointerup',{pointerId:501,pointerType:'touch',button:0,clientX:wallEnd.x,clientY:wallEnd.y});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.hub.tiles.filter(tile=>tile.kind==='wall')).toHaveLength(3);
  expect(snapshot.state.cargo.stone).toBe(15);
  const wall=snapshot.hub.tiles.find(tile=>tile.col===4&&tile.row===4);expect(await page.evaluate(({x,y})=>window.__everDeeperTest.hubCollisionAt(x,y),wall)).toBe(true);

  await page.locator('#hubBuildLamp').click();const lampPoint=await pointFor(6,4);await canvas.dispatchEvent('pointerdown',{pointerId:502,pointerType:'touch',button:0,buttons:1,clientX:lampPoint.x,clientY:lampPoint.y});await canvas.dispatchEvent('pointerup',{pointerId:502,pointerType:'touch',button:0,clientX:lampPoint.x,clientY:lampPoint.y});
  await page.locator('#hubBuildStorage').click();const storagePoint=await pointFor(7,4);await canvas.dispatchEvent('pointerdown',{pointerId:503,pointerType:'touch',button:0,buttons:1,clientX:storagePoint.x,clientY:storagePoint.y});await canvas.dispatchEvent('pointerup',{pointerId:503,pointerType:'touch',button:0,clientX:storagePoint.x,clientY:storagePoint.y});
  snapshot=await page.evaluate(()=>{const api=window.__everDeeperTest;api.renderOnce();return api.snapshot()});
  expect(snapshot.hub.tiles.filter(tile=>tile.kind==='lamp')).toHaveLength(1);
  expect(snapshot.state.gold).toBe(670);
  expect(snapshot.hub.modules.some(module=>module.kind==='storage')).toBe(true);
  expect(snapshot.lighting.technique).toBe('hub-ambient-lightmap');
  expect(snapshot.lighting.sources.some(source=>source.kind==='hubLamp')).toBe(true);

  await page.locator('#mineButton').click();await expect(page.locator('#hubBuildToolbar')).toBeHidden();
  await page.evaluate(()=>{const api=window.__everDeeperTest,chest=api.snapshot().state.base.chests.find(item=>item.scene==='hub'&&!item.packed);api.setPosition(chest.x,chest.y);api.grantCargo('copper',3);api.autoSort();api.save()});
  snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  const stored=snapshot.state.base.chests.find(chest=>chest.scene==='hub'&&!chest.packed);expect(stored.items.copper).toBe(3);expect(stored.items.stone).toBe(15);
  await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
  expect(snapshot.scene).toBe('hub');expect(snapshot.hub.tiles).toHaveLength(4);expect(snapshot.hub.modules.some(module=>module.id===stored.id)).toBe(true);expect(snapshot.state.base.chests.find(chest=>chest.id===stored.id).items.copper).toBe(3);
  await page.locator('#continueButton').click();await page.evaluate(()=>{const api=window.__everDeeperTest,station=api.snapshot().hub.stations.deepElevator;api.setPosition(station.x,station.y);api.step(.03)});
  await expect(page.locator('#contextTitle')).toHaveText('Endless Descent');await expect(page.locator('#contextButton')).toBeDisabled();await expect(page.locator('#contextButton')).toHaveText('OFFLINE');
});

test('Starfall entrance and Voidstar Depths remain readable on compact and tall phones',async({page},testInfo)=>{
  await freshGame(page);
  await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.unlockAllAreas();
    api.unlockStarfall();
    api.setPickaxeLevel(5);
    api.setDrillLevel(3);
  });
  const sizes=[{name:'compact',width:375,height:667},{name:'tall',width:390,height:844}];
  for(const size of sizes){
    await page.setViewportSize({width:size.width,height:size.height});
    await page.evaluate(()=>{
      const api=window.__everDeeperTest;
      api.setPosition(3505,1000);
      api.step(.05);
      api.renderOnce();
    });
    await expect(page.locator('#contextPanel')).toBeVisible();
    await expect(page.locator('#contextTitle')).toHaveText('Starfall Hollow');
    await page.screenshot({path:testInfo.outputPath('starfall-entrance-'+size.name+'-'+size.width+'x'+size.height+'.png'),fullPage:true});

    await page.evaluate(()=>{
      const api=window.__everDeeperTest;
      api.enterMine('starMine');
      api.discoverDepthEntrance();
      api.enterDepth();
    });
    const snapshot=await page.evaluate(()=>window.__everDeeperTest.snapshot());
    await page.evaluate(({x,y})=>{
      const api=window.__everDeeperTest;
      api.setPosition(x,y);
      api.step(.05);
      api.renderOnce();
    },snapshot.mine.depthEntrance);
    await expect(page.locator('#areaName')).toHaveText('VOIDSTAR DEPTHS');
    await expect(page.locator('#contextPanel')).toBeVisible();
    await expect(page.locator('#contextTitle')).toContainText('Depth 1');
    const layout=await page.evaluate(()=>{
      const canvas=document.getElementById('gameCanvas').getBoundingClientRect();
      const panel=document.getElementById('contextPanel').getBoundingClientRect();
      return{
        width:innerWidth,height:innerHeight,scrollWidth:document.documentElement.scrollWidth,
        canvas:{left:canvas.left,right:canvas.right,top:canvas.top,bottom:canvas.bottom,width:canvas.width,height:canvas.height},
        panel:{left:panel.left,right:panel.right,bottom:panel.bottom}
      };
    });
    expect(layout.scrollWidth).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.left).toBeGreaterThanOrEqual(0);
    expect(layout.canvas.right).toBeLessThanOrEqual(layout.width);
    expect(layout.canvas.width).toBeGreaterThan(0);
    expect(layout.canvas.height).toBeGreaterThan(0);
    expect(layout.panel.left).toBeGreaterThanOrEqual(0);
    expect(layout.panel.right).toBeLessThanOrEqual(layout.width);
    expect(layout.panel.bottom).toBeLessThanOrEqual(layout.height);
    await page.screenshot({path:testInfo.outputPath('voidstar-'+size.name+'-'+size.width+'x'+size.height+'.png'),fullPage:true});
    await page.evaluate(()=>{window.__everDeeperTest.exitDepth();window.__everDeeperTest.exitMine()});
  }
});
