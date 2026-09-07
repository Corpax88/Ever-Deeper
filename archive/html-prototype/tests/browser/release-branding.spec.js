const {test,expect}=require('@playwright/test');

test('Ever Deeper release branding is complete and mobile-safe',async({page})=>{
  const pageErrors=[],consoleErrors=[],scriptFailures=[];
  page.on('pageerror',error=>pageErrors.push(error.message));
  page.on('console',message=>{if(message.type()==='error')consoleErrors.push(message.text())});
  page.on('requestfailed',request=>{if(request.resourceType()==='script')scriptFailures.push(request.url()+': '+(request.failure()?.errorText||'request failed'))});
  page.on('response',response=>{if(response.request().resourceType()==='script'&&!response.ok())scriptFailures.push(response.url()+': HTTP '+response.status())});
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  const scripts=await page.locator('script[src]').evaluateAll(elements=>elements.map(script=>({src:script.getAttribute('src'),type:script.type})));
  const gameDataIndex=scripts.findIndex(script=>script.src==='game-data.js?v=03801'),engineIndex=scripts.findIndex(script=>script.src==='script.js?v=03801');
  expect(gameDataIndex).toBeGreaterThanOrEqual(0);expect(engineIndex).toBeGreaterThan(gameDataIndex);
  expect(scripts.every(script=>script.type===''&&script.src.endsWith('?v=03801'))).toBe(true);

  await expect(page).toHaveTitle('Ever Deeper');
  await expect(page.locator('meta[name="application-name"]')).toHaveAttribute('content','Ever Deeper');
  await expect(page.locator('meta[name="apple-mobile-web-app-title"]')).toHaveAttribute('content','Ever Deeper');
  await expect(page.locator('main')).toHaveAttribute('aria-label','Ever Deeper mining game');

  const logo=page.locator('.brand-logo');
  await expect(logo).toBeVisible();
  await expect(logo).toHaveAttribute('alt','Ever Deeper');
  await expect(logo).toHaveAttribute('src','assets/branding/ever-deeper-logo.png?v=03801');
  const logoState=await logo.evaluate(image=>({complete:image.complete,width:image.naturalWidth,height:image.naturalHeight,bounds:image.getBoundingClientRect().toJSON()}));
  expect(logoState).toMatchObject({complete:true,width:800,height:297});
  expect(logoState.bounds.width).toBeGreaterThanOrEqual(124);
  expect(logoState.bounds.right).toBeLessThanOrEqual(await page.evaluate(()=>innerWidth));

  await expect(page.locator('#buildVersion')).toHaveText('v0.38.1');
  await expect(page.locator('#menuBuildVersion')).toHaveText('EVER DEEPER v0.38.1 · UNDERGROUND HUB');
  await expect(page.locator('#toolIcon')).toHaveAttribute('src','assets/tools/pickaxe-worn.png?v=03801');
  await expect(page.locator('#mineToolIcon')).toHaveAttribute('src','assets/tools/pickaxe-worn.png?v=03801');
  await page.evaluate(()=>window.__everDeeperTest.dismissStartMenu());
  await page.evaluate(()=>window.__everDeeperTest.setPosition(455,250));
  await expect(page.locator('#contextPanel')).toBeVisible();
  await expect(page.locator('#contextIconImage')).toHaveAttribute('src',/assets\/surface\/forge-station\.png\?v=03801$/);
  const release=await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.reset();api.save();
    const retired=['deep','forge'].join('');
    return{
      build:api.snapshot().build,
      music:api.snapshot().music.asset,
      retiredMarkup:document.documentElement.innerHTML.toLowerCase().includes(retired),
      retiredStorage:Object.keys(localStorage).some(key=>key.toLowerCase().includes(retired)),
      currentStorage:localStorage.getItem('everDeeperPrototypeV2')!==null
    };
  });
  expect(release).toEqual({
    build:{version:'0.38.1',name:'UNDERGROUND HUB'},
    music:'assets/audio/ever-deeper-drift-loop.mp3',
    retiredMarkup:false,
    retiredStorage:false,
    currentStorage:true
  });
  expect({pageErrors,consoleErrors,scriptFailures}).toEqual({pageErrors:[],consoleErrors:[],scriptFailures:[]});
});

test('all resource symbols use the shared production drop assets',async({page})=>{
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  const contract=await page.evaluate(()=>window.__everDeeperTest.snapshot().resourceRendering);
  expect(Object.keys(contract.paths)).toHaveLength(21);
  expect(contract).toMatchObject({completeResourceSet:true,sharedWorldAndUiAssets:true,transparentBoundsNormalized:true,nodeAssetCoverage:true,objectiveIcons:true,inventoryIcons:true,storageIcons:true,recipeIcons:true,ledgerIcons:true,croppedGroundDrops:true,legacyCanvasResourceSymbols:false,legacyCanvasResourceDrops:false});
  const decoded=await page.evaluate(paths=>Promise.all(Object.values(paths).map(src=>new Promise(resolve=>{const image=new Image();image.onload=()=>resolve({src,width:image.naturalWidth,height:image.naturalHeight});image.onerror=()=>resolve({src,width:0,height:0});image.src=src}))),contract.paths);
  expect(decoded.every(asset=>asset.width===256&&asset.height>=194)).toBe(true);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.reset();api.grantCargo('stone',1);api.sellCargo();api.unlockAllAreas();api.grantGold(100);api.setPickaxeLevel(4);api.grantMined('moonglass',1);api.grantMined('emberstone',1);api.grantCargo('emberstone',7);api.step(.001);api.openInventory()});
  await expect(page.locator('#objectiveRequirements [data-resource="emberstone"] img')).toHaveAttribute('src',/emberstone-drop\.png/);
  await expect(page.locator('#inventoryGrid [data-resource="emberstone"] img')).toHaveAttribute('src',/emberstone-drop\.png/);
  await expect(page.locator('.resource.gold [data-resource="gold"] img')).toHaveAttribute('src',/gold-drop\.png/);
  expect(await page.locator('.resource-gem').count()).toBe(0);
});

test('settings reset starts a fresh expedition and clears achievements',async({page})=>{
  await page.goto('/');await page.waitForFunction(()=>window.__everDeeperTest);
  await page.evaluate(()=>{const api=window.__everDeeperTest;api.dismissStartMenu();api.grantMined('stone',12);api.grantGold(90);api.evaluateAchievements()});
  await page.locator('#menuButton').click();await expect(page.locator('#resetProgressButton')).toBeVisible();page.once('dialog',dialog=>dialog.accept());await page.locator('#resetProgressButton').click();
  const fresh=await page.evaluate(()=>({snapshot:window.__everDeeperTest.snapshot(),achievements:JSON.parse(localStorage.getItem('everDeeperAchievementsV1'))}));
  expect(fresh.snapshot.state.gold).toBe(0);expect(fresh.snapshot.state.mined.stone).toBe(0);expect(fresh.snapshot.state.pickaxeLevel).toBe(1);expect(fresh.snapshot.achievements.count).toBe(0);expect(fresh.snapshot.achievements.active).toBeNull();expect(fresh.achievements.records).toEqual({});await expect(page.locator('#menuShade')).toBeHidden();
});

test('achievement reliquaries settle before FIFO dismissal and persist full records',async({page})=>{
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  const catalog=await page.evaluate(()=>{const achievements=window.__everDeeperTest.snapshot().achievements;return{total:achievements.total,ids:achievements.definitions.map(definition=>definition.id),assets:achievements.definitions.map(definition=>definition.asset),count:achievements.count}});
  expect(catalog.total).toBe(50);expect(new Set(catalog.ids).size).toBe(50);expect(catalog.count).toBe(0);expect(catalog.assets.every((asset,index)=>asset===`assets/achievements/${catalog.ids[index]}.png`)).toBe(true);
  expect(new Set(catalog.assets).size).toBe(50);
  const decodedAssets=await page.evaluate(paths=>Promise.all(paths.map(async src=>{const image=new Image();image.src=src;try{await image.decode();return{src,width:image.naturalWidth,height:image.naturalHeight,decoded:true}}catch{return{src,width:0,height:0,decoded:false}}})),catalog.assets);
  expect(decodedAssets).toHaveLength(50);expect(decodedAssets.every(asset=>asset.decoded&&asset.width===512&&asset.height===512)).toBe(true);

  await page.evaluate(()=>{const api=window.__everDeeperTest;api.dismissStartMenu();api.grantMined('stone',1);api.evaluateAchievements()});
  const popup=page.locator('#achievementPopup');await expect(popup).toBeVisible();await expect(popup).toHaveAttribute('data-achievement','first_chip');await expect(popup).toHaveAttribute('data-settled','false');
  const animationLayers=await popup.evaluate(element=>{const box=element.querySelector('.achievement-popup-box'),image=box.querySelector('img');return{popupTransform:element.style.transform,boxAnimation:getComputedStyle(box).animationName,imageAnimation:getComputedStyle(image).animationName,imageWillChange:getComputedStyle(image).willChange}});
  expect(animationLayers.popupTransform).toContain('translate3d(');expect(animationLayers.boxAnimation).toBe('achievement-reliquary-rise');expect(animationLayers.imageAnimation).toBe('achievement-coin-rise');expect(animationLayers.imageWillChange).toContain('transform');
  await popup.dispatchEvent('click');expect(await page.evaluate(()=>window.__everDeeperTest.snapshot().achievements.active)).toBe('first_chip');
  await page.waitForFunction(()=>window.__everDeeperTest.snapshot().achievements.settled);await expect(popup).toHaveAttribute('data-settled','true');await popup.click();await expect(popup).toBeHidden();await expect(page.locator('#menuShade')).toBeVisible();await expect(page.locator('#menuShade')).toHaveAttribute('data-view','achievements');await expect(page.locator('.achievement-entry[data-achievement="first_chip"]')).toHaveClass(/recently-unlocked/);expect(await page.evaluate(()=>window.__everDeeperTest.snapshot().achievements.highlighted)).toBe('first_chip');await page.locator('#menuCloseButton').click();

  await page.evaluate(()=>{const api=window.__everDeeperTest;api.setPickaxeLevel(3);api.evaluateAchievements()});await expect(popup).toHaveAttribute('data-achievement','ironbound');
  let fifo=await page.evaluate(()=>window.__everDeeperTest.snapshot().achievements);expect(fifo.queue).toEqual(['ironbound','rune_ready']);expect(fifo.settled).toBe(false);
  await page.waitForFunction(()=>window.__everDeeperTest.snapshot().achievements.settled);await page.evaluate(()=>window.__everDeeperTest.dismissAchievement());await expect(popup).toHaveAttribute('data-achievement','rune_ready');
  await page.waitForFunction(()=>window.__everDeeperTest.snapshot().achievements.settled);await page.evaluate(()=>window.__everDeeperTest.dismissAchievement());await expect(popup).toBeHidden();

  const stored=await page.evaluate(()=>JSON.parse(localStorage.getItem('everDeeperAchievementsV1')));expect(Object.keys(stored.records)).toEqual(['first_chip','ironbound','rune_ready']);
  for(const record of Object.values(stored.records)){expect(record).toEqual(expect.objectContaining({reason:expect.any(String),scene:'surface',depth:1,order:expect.any(Number),acknowledged:true}));expect(Number.isFinite(Date.parse(record.timestamp))).toBe(true)}
  await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);await page.locator('#startAchievementsButton').click();await expect(page.locator('#achievementCount')).toHaveText('3 / 50 UNLOCKED');await expect(page.locator('.achievement-entry')).toHaveCount(50);await expect(page.locator('.achievement-entry.unlocked')).toHaveCount(3);await expect(page.locator('[data-achievement="first_chip"] .achievement-copy p')).toContainText('first resource');await expect(page.locator('[data-achievement="first_chip"] .achievement-copy span')).toContainText(/EARNED/);
});

test('Deepcore routes the final expedition through Starfall and into Voidstar',async({page})=>{
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  const route=await page.evaluate(()=>{
    const api=window.__everDeeperTest;
    api.reset();api.unlockAllAreas();api.unlockStarfall();api.setPickaxeLevel(5);api.setDrillLevel(3);
    const surface=api.snapshot();
    api.enterMine('starMine');const searching=api.snapshot();
    api.discoverDepthEntrance();const descent=api.snapshot();
    api.enterDepth();const voidstar=api.snapshot();
    return{
      surface:{goal:surface.goal,guide:surface.guide&&{kind:surface.guide.kind,destination:surface.guide.destination}},
      searching:{goal:searching.goal,guide:searching.guide},
      descent:{goal:descent.goal,guide:descent.guide&&{kind:descent.guide.kind,scene:descent.guide.scene,depth:descent.guide.depth}},
      voidstar:{goal:voidstar.goal,guide:voidstar.guide&&{kind:voidstar.guide.kind,resource:voidstar.guide.resource},visualPass:voidstar.mine.visualPass}
    };
  });
  expect(route.surface).toEqual({goal:{title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'},guide:{kind:'mine-entrance',destination:'starMine'}});
  expect(route.searching).toEqual({goal:{title:'Find the hidden Voidstar entrance',detail:'DIG DEEPER'},guide:null});
  expect(route.descent).toEqual({goal:{title:'Enter Voidstar Depths',detail:'DEEPCORE DRILL READY'},guide:{kind:'depth-entrance',scene:'starMine',depth:1}});
  expect(route.voidstar).toEqual({goal:{title:'Mine a Singularity Core',detail:'THE FINAL DISCOVERY'},guide:{kind:'rock',resource:'singularity'},visualPass:'voidstar-production-assets-v1'});
});

test('premium walk sheets are clean, directional, lazy, and reduced-motion safe',async({page})=>{
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  const initialWalkRequests=await page.evaluate(()=>performance.getEntriesByType('resource').map(entry=>entry.name).filter(name=>name.includes('-walk.png')).map(name=>name.split('/').pop().split('?')[0]));
  expect(initialWalkRequests).toEqual(['miner-b-walk.png']);

  const motion=await page.evaluate(()=>{
    const api=window.__everDeeperTest,rows={down:0,left:1,right:2,up:3},vectors={down:[0,1],left:[-1,0],right:[1,0],up:[0,-1]},samples=[];
    api.reset();api.setPosition(600,700);
    for(const direction of Object.keys(rows)){
      api.setMoveVector(...vectors[direction]);api.step(.08);const player=api.snapshot().player;samples.push({direction:player.direction,moving:player.moving,frame:player.walkFrame,distance:player.walkDistance,row:rows[player.direction]});api.stopMove();api.step(.001);
    }
    return{samples,contract:api.snapshot().characterRendering,stateKeys:Object.keys(api.snapshot().state)};
  });
  expect(motion.samples.map(sample=>sample.direction)).toEqual(['down','left','right','up']);
  expect(motion.samples.every(sample=>sample.moving&&sample.frame>=0&&sample.frame<6&&sample.distance>0)).toBe(true);
  expect(motion.contract.walkGrid).toEqual({columns:6,rows:4,cellSize:256,directions:['down','left','right','up']});
  expect(motion.contract).toMatchObject({directionalWalk:true,distanceDrivenWalk:true,holsteredWalkTools:true,lazyDrillWalkSheets:true,staticMiningFallback:true});
  expect(motion.stateKeys).not.toEqual(expect.arrayContaining(['walkFrame','walkDistance','direction','moving']));

  await page.evaluate(()=>{window.__everDeeperTest.setDrillLevel(2);window.__everDeeperTest.renderOnce()});
  await page.waitForFunction(()=>performance.getEntriesByType('resource').some(entry=>entry.name.includes('miner-b-drill-pulse-walk.png')));
  const activeDrill=await page.evaluate(()=>window.__everDeeperTest.snapshot().characterRendering.activeWalkAsset);
  expect(activeDrill).toBe('assets/characters/miner-b-drill-pulse-walk.png');

  const sheets=['miner-b-walk.png','miner-b-drill-burrower-walk.png','miner-b-drill-pulse-walk.png','miner-b-drill-deepcore-walk.png'];
  const qa=await page.evaluate(async names=>{
    const results=[];
    for(const name of names){
      const image=new Image();image.src='assets/characters/'+name;await image.decode();
      const canvas=document.createElement('canvas');canvas.width=image.naturalWidth;canvas.height=image.naturalHeight;const context=canvas.getContext('2d',{willReadFrequently:true});context.drawImage(image,0,0);const pixels=context.getImageData(0,0,canvas.width,canvas.height).data,frames=[];
      for(let row=0;row<4;row++)for(let col=0;col<6;col++){
        let alphaPixels=0,borderAlpha=0,bottom=-1,hash=2166136261;
        for(let y=0;y<256;y++)for(let x=0;x<256;x++){
          const offset=(((row*256+y)*canvas.width)+(col*256+x))*4,alpha=pixels[offset+3];
          if(alpha>12){alphaPixels++;bottom=Math.max(bottom,y)}
          if(!x||x===255||!y||y===255)borderAlpha=Math.max(borderAlpha,alpha);
          if(x%8===0&&y%8===0){hash^=pixels[offset];hash=Math.imul(hash,16777619);hash^=pixels[offset+1];hash=Math.imul(hash,16777619);hash^=pixels[offset+2];hash=Math.imul(hash,16777619);hash^=alpha;hash=Math.imul(hash,16777619)}
        }
        frames.push({alphaPixels,borderAlpha,bottom,hash:hash>>>0});
      }
      results.push({name,width:image.naturalWidth,height:image.naturalHeight,frames});
    }
    return results;
  },sheets);
  for(const sheet of qa){expect([sheet.width,sheet.height]).toEqual([1536,1024]);expect(sheet.frames).toHaveLength(24);expect(sheet.frames.every(frame=>frame.alphaPixels>4000&&frame.borderAlpha===0&&frame.bottom>=246&&frame.bottom<=250)).toBe(true);for(let row=0;row<4;row++)expect(new Set(sheet.frames.slice(row*6,row*6+6).map(frame=>frame.hash)).size).toBe(6)}

  await page.emulateMedia({reducedMotion:'reduce'});await page.reload();await page.waitForFunction(()=>window.__everDeeperTest);
  const reduced=await page.evaluate(()=>{const api=window.__everDeeperTest;api.reset();api.setPosition(600,700);const before=api.snapshot().player.x;api.setMoveVector(1,0);api.step(.08);const snapshot=api.snapshot();return{before,after:snapshot.player.x,frame:snapshot.player.walkFrame,reduced:snapshot.characterRendering.reducedMotion}});
  expect(reduced).toEqual(expect.objectContaining({frame:0,reduced:true}));expect(reduced.after).toBeGreaterThan(reduced.before);
});

test('premium ambient life is bounded, collision-free, animated, and reduced-motion safe',async({page})=>{
  await page.goto('/');
  await page.waitForFunction(()=>window.__everDeeperTest);
  const assets={mossvein:'assets/ambient/mossvein-glowmoth.png',moonglass:'assets/ambient/moonglass-prism-moth.png',emberdeep:'assets/ambient/emberdeep-cinder-skink.png',starfall:'assets/ambient/starfall-astral-ray.png'};
  const surface=await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.reset();api.dismissStartMenu();const before=api.snapshot(),state=JSON.stringify(before.state);api.renderOnce();const after=api.snapshot();
    return{life:before.ambientLife,stateUnchanged:JSON.stringify(after.state)===state,stateKeys:Object.keys(after.state)};
  });
  expect(surface.life).toMatchObject({frameCount:4,frameSize:256,premiumSpriteSheets:true,trueAnimationFrames:true,deterministicPlacement:true,surfaceMaxVisible:10,mineMaxVisible:6,rareSurfaceCrossings:true,reducedMotionSafe:true,roamingRoutes:true,mineRouteSampling:true,miningReactions:true,continuousReactions:true,restBehavior:true,collisionFree:true,gameplayNeutral:true,proceduralCreaturePrimitives:false,activeProfile:'mossvein',location:'surface',maxVisible:10});
  expect(surface.life.assets).toEqual(assets);expect(surface.life.visible.length).toBeGreaterThan(0);expect(surface.life.visible.length).toBeLessThanOrEqual(10);expect(surface.stateUnchanged).toBe(true);expect(surface.stateKeys).not.toContain('ambientLife');
  const surfaceTravel=await page.evaluate(()=>{const api=window.__everDeeperTest,beforeLife=api.snapshot().ambientLife,before=beforeLife.visible.filter(instance=>!instance.event),positions=Object.fromEntries(before.map(instance=>[instance.id,instance]));let maxTravel=0,restSeen=before.some(instance=>instance.resting&&instance.frame===0);for(let sample=0;sample<16;sample++){api.step(.5);for(const instance of api.snapshot().ambientLife.visible){restSeen||=instance.resting&&instance.frame===0&&(instance.routeProgress===0||instance.routeProgress===1);if(positions[instance.id])maxTravel=Math.max(maxTravel,Math.hypot(instance.x-positions[instance.id].x,instance.y-positions[instance.id].y))}}const life=api.snapshot().ambientLife,target=life.visible.find(instance=>!instance.event&&instance.profile===life.activeProfile);api.setPosition(target.x,target.y);api.setSwingProgress(.2);api.step(.01);const reacted=api.snapshot().ambientLife.visible.find(instance=>instance.id===target.id);api.clearSwing();return{routeLengths:before.map(instance=>Math.hypot(instance.routeX-instance.anchorX,instance.routeY-instance.anchorY)),maxTravel,restSeen,reaction:reacted&&{behavior:reacted.behavior,reacting:reacted.reacting,strength:reacted.reactionStrength}}});
  expect(Math.min(...surfaceTravel.routeLengths)).toBeGreaterThanOrEqual(60);expect(surfaceTravel.maxTravel).toBeGreaterThan(18);expect(surfaceTravel.restSeen).toBe(true);expect(surfaceTravel.reaction).toMatchObject({behavior:'fleeing',reacting:true});expect(surfaceTravel.reaction.strength).toBeGreaterThan(0);

  const sheetQa=await page.evaluate(async paths=>{
    const results=[];
    for(const [profile,src] of Object.entries(paths)){
      const image=new Image();image.src=src;await image.decode();const canvas=document.createElement('canvas');canvas.width=image.naturalWidth;canvas.height=image.naturalHeight;const context=canvas.getContext('2d',{willReadFrequently:true});context.drawImage(image,0,0);const pixels=context.getImageData(0,0,canvas.width,canvas.height).data,frames=[];
      for(let frame=0;frame<4;frame++){
        let alphaPixels=0,transparentPixels=0,borderAlpha=0,hash=2166136261;
        for(let y=0;y<256;y++)for(let x=0;x<256;x++){
          const offset=(y*canvas.width+frame*256+x)*4,alpha=pixels[offset+3];if(alpha>12)alphaPixels++;if(alpha===0)transparentPixels++;if(!x||x===255||!y||y===255)borderAlpha=Math.max(borderAlpha,alpha);
          if(x%4===0&&y%4===0){hash^=pixels[offset];hash=Math.imul(hash,16777619);hash^=pixels[offset+1];hash=Math.imul(hash,16777619);hash^=pixels[offset+2];hash=Math.imul(hash,16777619);hash^=alpha;hash=Math.imul(hash,16777619)}
        }
        frames.push({alphaPixels,transparentPixels,borderAlpha,hash:hash>>>0});
      }
      results.push({profile,src,width:image.naturalWidth,height:image.naturalHeight,frames});
    }
    return results;
  },assets);
  expect(sheetQa).toHaveLength(4);
  for(const sheet of sheetQa){expect([sheet.width,sheet.height]).toEqual([1024,256]);expect(sheet.frames).toHaveLength(4);expect(sheet.frames.every(frame=>frame.alphaPixels>7000&&frame.transparentPixels>38000&&frame.borderAlpha===0)).toBe(true);expect(new Set(sheet.frames.map(frame=>frame.hash)).size).toBe(4)}

  const reduced=await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.setReducedMotion(true);const before=api.snapshot().ambientLife;api.step(2);const after=api.snapshot().ambientLife;api.setReducedMotion(false);return{before,after};
  });
  expect(reduced.after).toMatchObject({reducedMotion:true,event:{enabled:false,active:false}});expect(reduced.after.visible.every(instance=>instance.frame===0&&instance.x===instance.anchorX&&instance.y===instance.anchorY)).toBe(true);expect(reduced.after.visible.map(({id,x,y})=>({id,x,y}))).toEqual(reduced.before.visible.map(({id,x,y})=>({id,x,y})));

  const mines=await page.evaluate(()=>{
    const api=window.__everDeeperTest,results=[];api.unlockAllAreas();api.unlockStarfall();
    for(const scene of ['mossMine','moonMine','emberMine','starMine']){api.enterMine(scene);const life=api.snapshot().ambientLife,positions=Object.fromEntries(life.visible.map(instance=>[instance.id,instance])),blocked=[];let maxTravel=0,restSeen=life.visible.some(instance=>instance.resting&&instance.frame===0);for(let sample=0;sample<14;sample++){api.step(.45);for(const instance of api.snapshot().ambientLife.visible){restSeen||=instance.resting&&instance.frame===0&&(instance.routeProgress===0||instance.routeProgress===1);if(api.mineCollisionAt(instance.x,instance.y))blocked.push(instance.id);if(positions[instance.id])maxTravel=Math.max(maxTravel,Math.hypot(instance.x-positions[instance.id].x,instance.y-positions[instance.id].y))}}const approachTargets=api.snapshot().ambientLife.visible,proximityStable=approachTargets.every(target=>{api.setPosition(target.x,target.y);return api.snapshot().ambientLife.visible.some(instance=>instance.id===target.id)}),target=api.snapshot().ambientLife.visible[0];api.setPosition(target.x,target.y);api.setSwingProgress(.2);api.step(.01);const reacted=api.snapshot().ambientLife.visible.find(instance=>instance.id===target.id);const reactionSafe=!!reacted&&!api.mineCollisionAt(reacted.x,reacted.y);api.step(.35);const beforeRelease=api.snapshot().ambientLife.visible.find(instance=>instance.id===target.id);api.clearSwing();api.step(.01);const recovery=api.snapshot().ambientLife.visible.find(instance=>instance.id===target.id),recoveryJump=recovery&&beforeRelease?Math.hypot(recovery.x-beforeRelease.x,recovery.y-beforeRelease.y):Infinity;api.step(.3);const recoverySafe=api.snapshot().ambientLife.visible.some(instance=>instance.id===target.id&&!api.mineCollisionAt(instance.x,instance.y));results.push({scene,life,blocked,maxTravel,restSeen,proximityStable,reaction:reacted&&reacted.behavior,reactionSafe,recovery:recovery&&recovery.behavior,recoveryJump,recoverySafe});api.step(1.1);api.exitMine()}
    return results;
  });
  const profiles={mossMine:'mossvein',moonMine:'moonglass',emberMine:'emberdeep',starMine:'starfall'};
  for(const mine of mines){expect(mine.life).toMatchObject({activeProfile:profiles[mine.scene],location:`${mine.scene}:1`,maxVisible:6});expect(mine.life.visible.length).toBeGreaterThan(0);expect(mine.life.visible.length).toBeLessThanOrEqual(6);expect(mine.life.visible.every(instance=>instance.profile===profiles[mine.scene]&&instance.asset===assets[profiles[mine.scene]]&&Math.hypot(instance.routeX-instance.anchorX,instance.routeY-instance.anchorY)>=20)).toBe(true);expect(mine.blocked).toEqual([]);expect(mine.maxTravel).toBeGreaterThan(6);expect(mine.restSeen).toBe(true);expect(mine.proximityStable).toBe(true);expect(mine.reaction).toBe('fleeing');expect(mine.reactionSafe).toBe(true);expect(mine.recovery).toBe('returning');expect(mine.recoveryJump).toBeLessThan(4);expect(mine.recoverySafe).toBe(true)}
});

test('premium world life is biome-specific, reactive, world-anchored, and mobile-safe',async({page})=>{
  await page.goto('/');await page.waitForFunction(()=>window.__everDeeperTest);
  const assets={mossvein:{drift:'assets/world-life/mossvein-drift.png',response:'assets/world-life/mossvein-response.png',impact:'assets/world-life/mossvein-impact.png'},moonglass:{drift:'assets/world-life/moonglass-drift.png',response:'assets/world-life/moonglass-response.png',impact:'assets/world-life/moonglass-impact.png'},emberdeep:{drift:'assets/world-life/emberdeep-drift.png',response:'assets/world-life/emberdeep-response.png',impact:'assets/world-life/emberdeep-impact.png'},starfall:{drift:'assets/world-life/starfall-drift.png',response:'assets/world-life/starfall-response.png',impact:'assets/world-life/starfall-impact.png'}};
  const surface=await page.evaluate(()=>{const api=window.__everDeeperTest;api.reset();api.dismissStartMenu();const before=api.snapshot(),state=JSON.stringify(before.state);api.renderOnce();const after=api.snapshot();return{life:before.worldLife,stateUnchanged:JSON.stringify(after.state)===state,stateKeys:Object.keys(after.state)}});
  expect(surface.life).toMatchObject({frameCount:4,frameSize:256,spriteSheetWidth:1024,spriteSheetHeight:256,decodedMemoryBudgetBytes:12582912,premiumSpriteSheets:true,trueAnimationFrames:true,surfaceMaxVisible:4,mineMaxVisible:3,responseMaxVisible:6,worldAnchored:true,deterministicPlacement:true,biomeSpecific:true,footstepResponses:true,miningResponses:true,dedicatedImpactSheets:true,noCircularImpactSilhouettes:true,impactStacking:false,underMineLighting:true,reducedMotionSafe:true,gameplayNeutral:true,proceduralEffectPrimitives:false,activeProfile:'mossvein',location:'surface',maxVisible:4});
  expect(surface.life.assets).toEqual(assets);expect(surface.life.drift.length).toBeGreaterThan(0);expect(surface.life.drift.length).toBeLessThanOrEqual(4);expect(surface.life.responses).toEqual([]);expect(surface.stateUnchanged).toBe(true);expect(surface.stateKeys).not.toContain('worldLife');

  const sheetQa=await page.evaluate(async paths=>{
    const results=[];
    for(const src of Object.values(paths).flatMap(profile=>Object.values(profile))){
      const image=new Image();image.src=src;await image.decode();const canvas=document.createElement('canvas');canvas.width=image.naturalWidth;canvas.height=image.naturalHeight;const context=canvas.getContext('2d',{willReadFrequently:true});context.drawImage(image,0,0);const pixels=context.getImageData(0,0,canvas.width,canvas.height).data,frames=[];
      for(let frame=0;frame<4;frame++){let alphaPixels=0,transparentPixels=0,hash=2166136261;for(let y=0;y<256;y+=2)for(let x=0;x<256;x+=2){const offset=(y*canvas.width+frame*256+x)*4,alpha=pixels[offset+3];if(alpha>12)alphaPixels++;if(alpha===0)transparentPixels++;hash^=pixels[offset];hash=Math.imul(hash,16777619);hash^=pixels[offset+1];hash=Math.imul(hash,16777619);hash^=pixels[offset+2];hash=Math.imul(hash,16777619);hash^=alpha;hash=Math.imul(hash,16777619)}frames.push({alphaPixels,transparentPixels,hash:hash>>>0})}
      results.push({src,width:image.naturalWidth,height:image.naturalHeight,frames});
    }
    return results;
  },assets);
  expect(sheetQa).toHaveLength(12);for(const sheet of sheetQa){expect([sheet.width,sheet.height]).toEqual([1024,256]);const minimumAlpha=sheet.src.includes('-impact.png')?250:500;expect(sheet.frames.every(frame=>frame.alphaPixels>minimumAlpha&&frame.transparentPixels>2500)).toBe(true);expect(new Set(sheet.frames.map(frame=>frame.hash)).size).toBe(4)}

  const reactions=await page.evaluate(()=>{
    const api=window.__everDeeperTest;api.setPosition(600,700);api.setMoveVector(1,0);for(let sample=0;sample<6;sample++)api.step(.05);api.stopMove();const footsteps=api.snapshot().worldLife.responses.filter(item=>item.kind==='footstep');api.unlockAllAreas();api.setPickaxeLevel(5);api.setDrillLevel(3);api.enterMine('mossMine');const mineLife=api.snapshot().worldLife,blocked=mineLife.drift.filter(instance=>api.mineCollisionAt(instance.x,instance.y));api.setPickaxeLevel(1);api.setDrillLevel(0);const deposit=api.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.depositId&&rock.requiredPickaxe<=1&&!rock.requiresDeepTool&&!rock.requiresDrillLevel),hit=api.hitDepositRock(deposit.depositId,0),rock=api.snapshot().rocks.find(item=>item.id===hit.id);api.setPosition(rock.x,rock.y);api.hitDepositRock(deposit.depositId,0);api.hitDepositRock(deposit.depositId,0);const hitResponses=api.snapshot().worldLife.responses.filter(item=>item.kind==='mine');api.breakDepositRock(deposit.depositId,0);const breakResponses=api.snapshot().worldLife.responses.filter(item=>item.kind==='break');return{footsteps,mineLife,blocked,hitResponses,breakResponses};
  });
  expect(reactions.footsteps.some(response=>response.asset===assets.mossvein.response)).toBe(true);expect(reactions.mineLife).toMatchObject({activeProfile:'mossvein',location:'mossMine:1',maxVisible:3});expect(reactions.mineLife.drift.length).toBeGreaterThan(0);expect(reactions.mineLife.drift.length).toBeLessThanOrEqual(3);expect(reactions.blocked).toEqual([]);expect(reactions.hitResponses).toHaveLength(1);expect(reactions.hitResponses[0].asset).toBe(assets.mossvein.impact);expect(reactions.breakResponses).toHaveLength(1);expect(reactions.breakResponses[0].asset).toBe(assets.mossvein.impact);

  const reduced=await page.evaluate(()=>{const api=window.__everDeeperTest;api.setReducedMotion(true);const before=api.snapshot().worldLife;api.step(2);const after=api.snapshot().worldLife;return{before,after}});
  expect(reduced.after.responses).toEqual([]);expect(reduced.after.drift.every(instance=>instance.frame===0&&instance.x===instance.anchorX&&instance.y===instance.anchorY)).toBe(true);expect(reduced.after.drift.map(({id,x,y})=>({id,x,y}))).toEqual(reduced.before.drift.map(({id,x,y})=>({id,x,y})));
});
