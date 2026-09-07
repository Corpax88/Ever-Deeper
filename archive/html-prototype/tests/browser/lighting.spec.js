const {test,expect}=require('@playwright/test');

test('caves use an occluded mobile lightmap with a readable natural-light hierarchy',async({page})=>{
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);

  const result=await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.reset();api.enterMine('mossMine');
    let snapshot=api.snapshot(),glowingRock=snapshot.rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.type!=='stone'&&rock.type!=='deepstone'&&!rock.cavernId&&!rock.broken);
    const columns=Math.ceil(snapshot.mine.width/snapshot.mine.terrain.tileSize),cellIndex=Math.floor(glowingRock.y/snapshot.mine.terrain.tileSize)*columns+Math.floor(glowingRock.x/snapshot.mine.terrain.tileSize);
    for(let hit=0;hit<8;hit++)api.mineTerrainCell(cellIndex);api.setPosition(glowingRock.x,glowingRock.y);api.renderOnce();const oreLights=api.snapshot().lighting.oreLights;
    api.setPosition(180,503);api.setAim(.899,-.438);api.renderOnce();
    snapshot=api.snapshot();const target=snapshot.mine.terrain.target;
    for(let index=0;index<12;index++)api.renderOnce();const samples=[];
    for(let index=0;index<30;index++){const started=performance.now();api.renderOnce();samples.push(performance.now()-started)}
    samples.sort((a,b)=>a-b);const lighting=api.snapshot().lighting,blockedDistance=api.sampleHeadlampRay();
    const cache=api.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');for(let hit=0;hit<4&&!api.snapshot().mine.discovery.caverns.find(cavern=>cavern.id===cache.id).discovered;hit++)api.mineTerrainCell(cache.boundaryIndex);api.setPosition(cache.x,cache.y);api.renderOnce();const activeBonus=api.snapshot().lighting.sources.find(source=>source.kind==='bonusCrystal');api.claimPocketReward(cache.reward.id);api.renderOnce();const collectedBonus=api.snapshot().lighting.sources.find(source=>source.kind==='bonusCrystalCollected');
    api.discoverDepthEntrance();const entrance=api.snapshot().mine.depthEntrance;api.setPosition(entrance.x,entrance.y);api.renderOnce();const depthLamp=api.snapshot().lighting.sources.find(source=>source.kind==='depthLamp');
    return{
      lighting,activeBonus,collectedBonus,depthLamp,
      oreLights,
      target:!!target,
      blockedDistance,
      averageMs:samples.reduce((total,value)=>total+value,0)/samples.length,
      p95Ms:samples[Math.floor(samples.length*.95)]
    };
  });

  expect(result.target).toBe(true);
  expect(result.blockedDistance).toBeLessThan(result.lighting.beamLength);
  expect(result.lighting).toMatchObject({enabled:true,technique:'low-resolution-raycast-lightmap',occlusion:true,bufferScale:.34,maxOreLights:16,maxNaturalLights:22,depthLampAsset:'assets/entrances/depth-work-lamp.png'});
  expect(result.lighting.rayChecks).toBeGreaterThan(0);
  expect(result.oreLights).toBeGreaterThan(0);
  expect(result.oreLights).toBeLessThanOrEqual(16);
  expect(result.lighting.naturalLights).toBeGreaterThan(0);
  expect(result.lighting.sources.some(source=>source.kind==='rockOre')).toBe(true);
  expect(result.lighting.hierarchy.stone).toBeLessThan(result.lighting.hierarchy.rockOre);
  expect(result.lighting.hierarchy.rockOre).toBeLessThan(result.lighting.hierarchy.wallOre);
  expect(result.lighting.hierarchy.wallOre).toBeLessThan(result.lighting.hierarchy.depthLamp);
  expect(result.lighting.hierarchy.depthLamp).toBeLessThan(result.lighting.hierarchy.bonusCrystalCollected);
  expect(result.lighting.hierarchy.bonusCrystalCollected).toBeLessThan(result.lighting.hierarchy.bonusCrystal);
  expect(result.activeBonus.intensity).toBe(result.lighting.hierarchy.bonusCrystal);
  expect(result.collectedBonus.intensity).toBe(result.lighting.hierarchy.bonusCrystalCollected);
  expect(result.depthLamp.intensity).toBe(result.lighting.hierarchy.depthLamp);
  expect(result.averageMs).toBeLessThan(25);
  expect(result.p95Ms).toBeLessThan(40);
});
