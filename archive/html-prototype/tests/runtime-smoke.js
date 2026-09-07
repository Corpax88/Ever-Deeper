const assert=require('node:assert/strict');
const crypto=require('node:crypto');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');

const repositoryRoot=path.join(__dirname,'..');
const html=fs.readFileSync(path.join(repositoryRoot,'index.html'),'utf8');
const css=fs.readFileSync(path.join(repositoryRoot,'style.css'),'utf8');
const latest=JSON.parse(fs.readFileSync(path.join(repositoryRoot,'version.json'),'utf8'));
const externalScripts=[...html.matchAll(/<script\b([^>]*)\bsrc="([^"]+)"([^>]*)><\/script>/g)].map(match=>({attributes:match[1]+match[3],src:match[2]}));
const scriptSources=externalScripts.map(script=>script.src);
const gameDataScriptIndex=scriptSources.findIndex(src=>src.startsWith('game-data.js?'));
const engineScriptIndex=scriptSources.findIndex(src=>src.startsWith('script.js?'));
assert.ok(gameDataScriptIndex>=0&&engineScriptIndex>gameDataScriptIndex,'game-data.js must load before script.js');
for(const script of externalScripts)assert.doesNotMatch(script.attributes,/\btype\s*=/,'runtime scripts must remain ordered classic scripts');
const source=scriptSources.map(src=>fs.readFileSync(path.join(repositoryRoot,src.split('?')[0]),'utf8')).join('\n');
const gameDataSource=fs.readFileSync(path.join(repositoryRoot,scriptSources[gameDataScriptIndex].split('?')[0]),'utf8');
const gameDataWindow={};
vm.runInNewContext(gameDataSource,{window:gameDataWindow},{filename:'game-data.js'});
function canonicalData(value){
  if(typeof value==='function'||value===undefined)return undefined;
  if(Array.isArray(value))return value.map(canonicalData).filter(item=>item!==undefined);
  if(value&&typeof value==='object')return Object.fromEntries(Object.keys(value).sort().flatMap(key=>{const item=canonicalData(value[key]);return item===undefined?[]:[[key,item]]}));
  return value;
}
const gameDataDigest=crypto.createHash('sha256').update(JSON.stringify(canonicalData(gameDataWindow.EverDeeperGameData))).digest('hex');
assert.equal(gameDataDigest,'e14dd92084b8c07774769a415e1f26c306f5b26214ceee1c39309630154ae883','static gameplay data changed unexpectedly');
assert.equal(JSON.stringify(gameDataWindow.EverDeeperGameData.DRILL_RECIPES),JSON.stringify([null,{gold:5000,requirements:[{scene:'mossMine',type:'rootiron',amount:50},{scene:'mossMine',type:'ambercore',amount:5}]},{gold:12000,requirements:[{scene:'mossMine',type:'burrowsteel',amount:60},{scene:'moonMine',type:'prismite',amount:40},{scene:'moonMine',type:'lunacore',amount:4}]},{gold:25000,requirements:[{scene:'moonMine',type:'phasecrystal',amount:70},{scene:'emberMine',type:'magmaite',amount:50},{scene:'emberMine',type:'furnaceheart',amount:5},{scene:'emberMine',type:'infernium',amount:70}]}]));
for(const scene of gameDataWindow.EverDeeperGameData.MINE_SCENES){
  const mine=gameDataWindow.EverDeeperGameData.MINE_DEFINITIONS[scene];
  const blocked=gameDataWindow.EverDeeperGameData.MINE_DISCOVERIES[scene].rocks.filter(rock=>mine.solids.some(solid=>rock.x+42>solid.x&&rock.x-42<solid.x+solid.w&&rock.y+42>solid.y&&rock.y-42<solid.y+solid.h));
  assert.equal(blocked.length,0,scene+' generated nodes must stay clear of permanent walls');
}
const retiredBrand=['deep','forge'].join('');
const excludedAuditDirectories=new Set(['.git','node_modules','playwright-report','test-results']);
function auditBrandRemoval(directory){
  for(const entry of fs.readdirSync(directory,{withFileTypes:true})){
    if(entry.isDirectory()&&excludedAuditDirectories.has(entry.name))continue;
    const absolute=path.join(directory,entry.name),relative=path.relative(repositoryRoot,absolute);
    assert.ok(!relative.toLowerCase().includes(retiredBrand),'retired brand remains in path: '+relative);
    if(entry.isDirectory())auditBrandRemoval(absolute);
    else if(entry.isFile())assert.ok(!fs.readFileSync(absolute).toString('latin1').toLowerCase().includes(retiredBrand),'retired brand remains in file: '+relative);
  }
}
auditBrandRemoval(repositoryRoot);
assert.doesNotMatch(source,/drawPlayerDrillLayer|drawPlayerCropAtGrip|offhandCrop|drillRearAnchor|assets\/tools\/drill-/);
assert.doesNotMatch(source,/function drawRockBody/,'resource nodes must not retain a procedural canvas body fallback');
assert.doesNotMatch(source,/function drawSurfaceBoundarySegment|function drawDeepAccessWallFace/,'new boundary walls must not retain procedural canvas renderers');
assert.match(source,/function drawSurfaceBoundaryAsset/);assert.match(source,/legacyCanvasWalls:false/);assert.match(source,/legacyCanvasDeepAccessFace:false/);
assert.doesNotMatch(source,/drawSection\(0,gapTop\)|drawSection\(gapBottom,WORLD\.height\)/,'boundary art must not be cut into rectangular gate sections');assert.match(source,/ctx\.drawImage\(image,x,-camera\.y,width,WORLD\.height\)/);
for(const asset of ['boundary-mossvein-moonglass.png','boundary-moonglass-emberdeep.png','boundary-emberdeep-starfall.png'])assert.ok(fs.existsSync(path.join(repositoryRoot,'assets','surface',asset)),asset+' must exist');
for(const [biome,asset] of [['mossvein','unbreakable-wall.png'],['moonglass','unbreakable-wall.png'],['emberdeep','unbreakable-wall.png'],['starfall','unbreakable-wall.png']])assert.ok(fs.existsSync(path.join(repositoryRoot,'assets',biome,asset)),biome+' unbreakable wall must exist');
assert.match(source,/function drawUnbreakableSolidWall/);assert.match(source,/legacyCanvasSolidWalls:false/);
assert.match(source,/function gateActivationPose\(progress\)[\s\S]*progress<\.16[\s\S]*progress-\.34/,'gate activation must stage its flash before the physical sink');
const gateRendererSource=source.match(/function drawGateAt[\s\S]*?function drawVeins/)[0];
assert.match(gateRendererSource,/globalCompositeOperation='screen'[\s\S]*brightness\(2\.35\)/,'gate activation must flash the premium silhouette');
assert.match(gateRendererSource,/pose\.sink\*238/,'gate activation must sink the full-height asset below ground');
assert.doesNotMatch(gateRendererSource,/ctx\.scale\(/,'world gates must never be squashed during activation');
assert.doesNotMatch(gateRendererSource,/ellipse\(0,101/,'premium gates must not receive a procedural canvas shadow');
assert.doesNotMatch(gateRendererSource,/moveTo\(0,-48\)/,'premium gates must own their energy barrier without a duplicate canvas seam');
assert.match(source,/drawMineGround\(\);drawMineTerrain\(\);drawWorldLifeDrift\(\);drawAmbientLife\(\);drawMineWalls\(\)/,'world life must render beneath permanent walls');
assert.match(source,/drawEffects\(false\)[\s\S]*drawMineLighting\(\)/,'terrain responses must remain beneath mine lighting');
assert.match(source,/function drawWorldLifeDrift\([\s\S]*ctx\.drawImage\(image,instance\.frame\*WORLD_LIFE_FRAME_SIZE/);assert.match(source,/function drawTerrainResponses\([\s\S]*ctx\.drawImage\(image,render\.frame\*WORLD_LIFE_FRAME_SIZE/);
assert.match(source,/fullDrillComposites:true,legacyDrillLimbCrops:false/);
assert.match(source,/function playPickaxeTink\(/);assert.match(source,/if\(currentDrill\(\)\).*playImpactNoise[\s\S]*else playPickaxeTink\(materialTone\)/,'pickaxe tink must remain separate from drill impact audio');
assert.match(source,/if\(!rock&&!terrainTarget\)\{if\(manualPress\)sound\('empty'\)/,'held mining misses must stay silent after the initial manual press');
const oreDiscoverySource=source.match(/function spawnDiscoveryBurst[\s\S]*?function spawnGroundDrop/)[0];
assert.doesNotMatch(oreDiscoverySource,/showAreaBanner|floaters\.push/,'ore discovery must stay text-free, including rare finds');
assert.doesNotMatch(source,/rings\.push|addParticle\(|let particles=|let rings=/,'generic procedural ring and particle systems must remain removed');
const miningImpactSource=source.match(/function spawnImpact[\s\S]*?function spawnDiscoveryBurst/)[0],effectRendererSource=source.match(/function drawEffects[\s\S]*?function drawWorldLabels/)[0];
assert.doesNotMatch(miningImpactSource,/beginPath|arc\(|fillRect|particles|rings/,'routine mining must not rebuild procedural canvas feedback');
assert.match(miningImpactSource,/spawnTerrainResponse\('mine'/);assert.match(miningImpactSource,/spawnTerrainResponse\('break'/);
assert.doesNotMatch(miningImpactSource,/floaters\.push/,'routine impacts must not emit damage text');
const miningBeatSource=source.match(/function hitRock[\s\S]*?function registerVeinBreak/)[0],pickupBatchSource=source.match(/function flushPickupBatch[\s\S]*?function updateGroundDrops/)[0];
assert.doesNotMatch(miningBeatSource,/SHELL BROKEN|BREACH \+|TUNNEL OPEN|\+total\+' VEIN'/,'routine mining labels must stay removed');
assert.doesNotMatch(pickupBatchSource,/floaters\.push/,'routine pickups must stay text-free');
assert.match(source,/WORLD_LIFE_ART\[response\.kind==='footstep'\?'response':'impact'\]/,'mining must use dedicated impact art while footsteps retain ground responses');
assert.doesNotMatch(effectRendererSource,/particle|ring|ctx\.arc|ctx\.fillRect/,'the generic effect pass must not render procedural shapes');
assert.match(effectRendererSource,/STARTER_ART\.drops\[key\]/);assert.match(effectRendererSource,/ctx\.drawImage\(image,bounds\.x,bounds\.y,bounds\.w,bounds\.h/,'sale trails must render premium drop PNGs');
assert.equal(latest.version,'03801');
assert.match(html,/version\.json\?t=/);
assert.match(html,/cache:'no-store'/);
assert.match(html,/style\.css\?v=03801/);
assert.match(html,/game-data\.js\?v=03801/);
assert.match(html,/script\.js\?v=03801/);
assert.match(html,/assets\/branding\/ever-deeper-logo\.png\?v=03801/);
assert.match(html,/assets\/characters\/miner-b-walk\.png\?v=03801/);
assert.match(html,/id="toolIcon"[^>]+assets\/tools\/pickaxe-worn\.png\?v=03801/);
assert.match(html,/id="mineToolIcon"[^>]+assets\/tools\/pickaxe-worn\.png\?v=03801/);
assert.match(html,/rel="manifest" href="manifest\.webmanifest\?v=03801"/);
assert.match(source,/const EMBER_PICKAXE_ORE_REQUIRED=100;/);
assert.match(source,/const EMBER_MASTERY_SUNSLAG_COSTS=Object\.freeze\(\[0,30,40,50,60,70\]\);/);
assert.match(source,/const STARFORGE_MATERIAL_REQUIRED=200;/);
assert.match(css,/\.context-panel\{bottom:136px;/);
assert.match(html,/id="startScreen" class="start-screen"/);
assert.match(html,/id="continueButton"/);assert.match(html,/id="newGameButton"/);assert.match(html,/id="startAchievementsButton"/);assert.match(html,/id="startSettingsButton"/);assert.match(html,/id="patchNotesButton"/);assert.match(html,/id="patchNotesPanel"/);assert.match(html,/id="patchNotesList"/);assert.match(html,/id="resetProgressButton"/);
assert.match(source,/const PATCH_NOTES=\[/);assert.match(source,/version:'0\.34\.7'.+title:'Safer Foundations'/);assert.match(css,/\.patch-note\.latest/);assert.match(css,/@keyframes achievement-entry-reveal/);
assert.match(source,/drawMineLighting\(\);drawWorldLabels\(\);drawVisualGuide\(\);drawReadableTextOverlay\(\)/);assert.match(source,/readableTextOverlay:true,textPass:'after-lighting'/);
assert.match(source,/viewport\.addEventListener\('pointerdown',beginFloatingJoystick\)/);assert.match(source,/floatingJoystick:true.+pressAnywhere:true.+independentMinePointer:true/);assert.match(css,/\.joystick\.active\{opacity:1\}/);
assert.doesNotMatch(html,/id="achievementsTab"/);
assert.match(html,/id="achievementPopup"/);assert.match(html,/id="achievementPopupImage"/);assert.match(html,/id="achievementAnnouncement"[^>]+role="status"[^>]+aria-live="polite"/);assert.match(html,/id="achievementCount"/);assert.match(html,/id="achievementList"/);
assert.match(source,/ACHIEVEMENTS_KEY='everDeeperAchievementsV1'/);assert.match(css,/@keyframes achievement-reliquary-rise/);assert.match(css,/@keyframes achievement-coin-rise/);assert.match(css,/rotateY\(5turn\)/);assert.match(css,/\.achievement-popup\.spinning \.achievement-popup-box img\{animation:achievement-coin-rise 2\.65s cubic-bezier/);assert.match(source,/achievementPopup\.style\.transform='translate3d\('/);
const expectedAchievementIds=['first_chip','first_payday','moon_unsealed','ember_unsealed','stars_unsealed','four_frontiers','minewalker','seasoned_arms','iron_rhythm','keen_eye','true_aim','tunnel_hand','earth_eater','ore_mountain','goldspark','fallen_star','sunstruck','crowned','into_the_deep','three_hearts','drillborn_ore','deep_hoard','ironbound','rune_ready','moonforged','emberforged','depth_master','starforged','threefold_star','burrower','pulse_driver','deepcore','moss_below','glass_below','fire_below','stars_below','hidden_descent','every_depth','treasure_found','cache_hunter','chestmaster','vein_runner','fourfold_veins','vein_veteran','quick_step','roadrunner','more_storage','mobile_base','mineral_crown','ever_deeper'];
const declaredAchievementIds=[...source.matchAll(/achievementDefinition\('([^']+)'/g)].map(match=>match[1]);
assert.deepEqual(declaredAchievementIds,expectedAchievementIds);assert.equal(new Set(declaredAchievementIds).size,50);
assert.match(css,/@media \(orientation:landscape\) and \(max-height:620px\)/);
assert.match(css,/#game\{visibility:hidden;pointer-events:none\}/);
assert.match(html,/class="portrait-lock"/);
const manifest=JSON.parse(fs.readFileSync(require('node:path').join(__dirname,'..','manifest.webmanifest'),'utf8'));
assert.equal(manifest.orientation,'portrait');
assert.equal(manifest.display,'standalone');
assert.match(css,/\.resource\.gold\{left:auto\}/);
assert.match(css,/\.resource\.cargo\{right:auto\}/);
assert.match(html,/id="contextIconImage"/);
assert.match(source,/UI_TOOL_PATHS/);
assert.match(source,/function contextUiAsset/);
assert.match(html,/<title>Ever Deeper<\/title>/);
assert.match(source,/MUSIC_PATH='assets\/audio\/ever-deeper-drift-loop\.mp3\?v='/);
assert.match(source,/backgroundMusic\.loop=true/);
assert.match(source,/backgroundMusic\.volume=MUSIC_VOLUME/);
const musicAsset=fs.readFileSync(require('node:path').join(__dirname,'..','assets/audio/ever-deeper-drift-loop.mp3'));
assert.ok(musicAsset.length>100000&&musicAsset.length<2000000,'background music must stay within the mobile audio budget');
const logoAsset=fs.readFileSync(require('node:path').join(__dirname,'..','assets/branding/ever-deeper-logo.png'));
assert.equal(logoAsset.toString('ascii',1,4),'PNG');assert.equal(logoAsset[25],6,'logo must use RGBA');assert.ok(logoAsset.length<300000,'logo exceeds mobile asset budget');
function assertPng(relative,width,height,{alpha=true,maxBytes=250000}={}){
  const png=fs.readFileSync(require('node:path').join(repositoryRoot,relative));
  assert.equal(png.toString('ascii',1,4),'PNG',relative+' must be a PNG');
  assert.equal(png.readUInt32BE(16),width,relative+' has the wrong width');
  assert.equal(png.readUInt32BE(20),height,relative+' has the wrong height');
  const preservesAlpha=[4,6].includes(png[25])||png.includes(Buffer.from('tRNS'));
  assert.equal(preservesAlpha,alpha,relative+(alpha?' must preserve transparency':' must be fully opaque'));
  assert.ok(png.length<maxBytes,relative+' exceeds its '+maxBytes+' byte mobile budget');
}
const achievementAssetBudgetBytes=500000,achievementAssetDigests=new Set();
for(const id of expectedAchievementIds){
  const relative='assets/achievements/'+id+'.png',absolute=require('node:path').join(repositoryRoot,relative);assert.ok(fs.existsSync(absolute),relative+' must exist');const png=fs.readFileSync(absolute);
  assertPng(relative,512,512,{maxBytes:achievementAssetBudgetBytes+1});
  assert.ok(png.length<=achievementAssetBudgetBytes,relative+' exceeds its 500KB mobile budget');
  const digest=require('node:crypto').createHash('sha256').update(png).digest('hex');
  assert.ok(!achievementAssetDigests.has(digest),relative+' duplicates another achievement sprite');achievementAssetDigests.add(digest);
}
assert.equal(achievementAssetDigests.size,50,'every achievement must have its own sprite');
const playerAssets=['assets/characters/miner-b.png','assets/characters/miner-b-drill-burrower.png','assets/characters/miner-b-drill-pulse.png','assets/characters/miner-b-drill-deepcore.png','assets/tools/pickaxe-worn.png','assets/tools/pickaxe-iron.png','assets/tools/pickaxe-runed.png','assets/tools/pickaxe-moonglass.png','assets/tools/pickaxe-ember.png','assets/tools/starforge-crusher.png','assets/tools/starforge-swift.png','assets/tools/starforge-prospector.png'];
for(const relative of playerAssets){const path=require('node:path').join(__dirname,'..',relative),png=fs.readFileSync(path);assert.equal(png.toString('ascii',1,4),'PNG');assert.equal(png[25],6,relative+' must use RGBA');assert.ok(png.length<250000,relative+' exceeds mobile asset budget')}
assertPng('assets/tools/starforge-prospector.png',512,306,{maxBytes:250000});
const crownseekerDigest=require('node:crypto').createHash('sha256').update(fs.readFileSync(require('node:path').join(repositoryRoot,'assets/tools/starforge-prospector.png'))).digest('hex');
const emberPickaxeDigest=require('node:crypto').createHash('sha256').update(fs.readFileSync(require('node:path').join(repositoryRoot,'assets/tools/pickaxe-ember.png'))).digest('hex');
assert.notEqual(crownseekerDigest,emberPickaxeDigest,'Crownseeker must remain visually distinct from the Ember Pickaxe');
const playerWalkAssets=['assets/characters/miner-b-walk.png','assets/characters/miner-b-drill-burrower-walk.png','assets/characters/miner-b-drill-pulse-walk.png','assets/characters/miner-b-drill-deepcore-walk.png'];
for(const relative of playerWalkAssets)assertPng(relative,1536,1024,{maxBytes:1500000});
const ambientAssets={
  mossvein:'assets/ambient/mossvein-glowmoth.png',
  moonglass:'assets/ambient/moonglass-prism-moth.png',
  emberdeep:'assets/ambient/emberdeep-cinder-skink.png',
  starfall:'assets/ambient/starfall-astral-ray.png'
};
let ambientAssetBytes=0;
for(const relative of Object.values(ambientAssets)){
  assertPng(relative,1024,256,{maxBytes:300000});
  ambientAssetBytes+=fs.statSync(path.join(repositoryRoot,relative)).size;
}
assert.ok(ambientAssetBytes<900000,'ambient sprite sheets exceed their combined 900KB mobile budget');
const worldLifeAssets={
  mossvein:{drift:'assets/world-life/mossvein-drift.png',response:'assets/world-life/mossvein-response.png',impact:'assets/world-life/mossvein-impact.png'},
  moonglass:{drift:'assets/world-life/moonglass-drift.png',response:'assets/world-life/moonglass-response.png',impact:'assets/world-life/moonglass-impact.png'},
  emberdeep:{drift:'assets/world-life/emberdeep-drift.png',response:'assets/world-life/emberdeep-response.png',impact:'assets/world-life/emberdeep-impact.png'},
  starfall:{drift:'assets/world-life/starfall-drift.png',response:'assets/world-life/starfall-response.png',impact:'assets/world-life/starfall-impact.png'}
};
let worldLifeAssetBytes=0;
for(const paths of Object.values(worldLifeAssets))for(const relative of Object.values(paths)){assertPng(relative,1024,256,{maxBytes:350000});worldLifeAssetBytes+=fs.statSync(path.join(repositoryRoot,relative)).size}
assert.ok(worldLifeAssetBytes<2400000,'world-life sprite sheets exceed their combined 2.4MB mobile budget');
const pocketAsset=fs.readFileSync(require('node:path').join(__dirname,'..','assets/mossvein/magic-crystal-pocket.png'));
assert.equal(pocketAsset.toString('ascii',1,4),'PNG');assert.ok([4,6].includes(pocketAsset[25])||pocketAsset.includes(Buffer.from('tRNS')),'crystal pocket must preserve alpha');assert.ok(pocketAsset.length<250000,'crystal pocket exceeds mobile asset budget');
const starterProductionAssets=['assets/surface/assay-station.png','assets/surface/forge-station.png','assets/surface/storage-chest.png','assets/surface/wayfarer-shop.png','assets/surface/treasure-cache-closed.png','assets/surface/treasure-cache-open.png','assets/surface/moonglass-gate.png','assets/surface/mossvein-mine-path.png','assets/mossvein/buried-cache.png','assets/mossvein/mining-rush-shrine.png','assets/drops/stone-drop.png','assets/drops/copper-drop.png','assets/drops/gold-drop.png'];
for(const relative of starterProductionAssets){const png=fs.readFileSync(require('node:path').join(__dirname,'..',relative));assert.equal(png.toString('ascii',1,4),'PNG');assert.ok([4,6].includes(png[25])||png.includes(Buffer.from('tRNS')),relative+' must preserve transparency');assert.ok(png.length<180000,relative+' exceeds mobile asset budget')}
assertPng('assets/surface/moonglass-gate.png',475,512,{maxBytes:100000});
const completeDropPaths={stone:'assets/drops/stone-drop.png',copper:'assets/drops/copper-drop.png',gold:'assets/drops/gold-drop.png',moonglass:'assets/drops/moonglass-drop.png',starshard:'assets/drops/starshard-drop.png',emberstone:'assets/drops/emberstone-drop.png',sunslag:'assets/drops/sunslag-drop.png',astralite:'assets/drops/astralite-drop.png',crownstone:'assets/drops/crownstone-drop.png',deepstone:'assets/drops/deepstone-drop.png',rootiron:'assets/drops/rootiron-drop.png',ambercore:'assets/drops/ambercore-drop.png',prismite:'assets/drops/prismite-drop.png',lunacore:'assets/drops/lunacore-drop.png',magmaite:'assets/drops/magmaite-drop.png',furnaceheart:'assets/drops/furnaceheart-drop.png',voidglass:'assets/drops/voidglass-drop.png',singularity:'assets/drops/singularity-drop.png',burrowsteel:'assets/drops/burrowsteel-drop.png',phasecrystal:'assets/drops/phasecrystal-drop.png',infernium:'assets/drops/infernium-drop.png'};
for(const [type,relative] of Object.entries(completeDropPaths)){const dimensions=type==='stone'?[256,211]:type==='copper'?[256,239]:type==='gold'?[256,194]:[256,256];assertPng(relative,dimensions[0],dimensions[1],{maxBytes:180000})}
assertPng('assets/surface/mossvein-mine-path.png',768,341,{maxBytes:100000});
assertPng('assets/surface/mossvein-ground.png',768,886,{alpha:false,maxBytes:450000});
for(const biome of ['mossvein','moonglass','emberdeep','starfall'])assertPng('assets/surface/road-'+biome+'.png',1024,341,{maxBytes:100000});
const rootwoundAssets=['floor.png','wall.png','rootiron-node.png','deepstone-node.png','ambercore-node.png','burrowsteel-node.png','rootiron-wall.png','depth-shaft.png','sell-station.png','drill-forge.png'];
for(const name of rootwoundAssets){const png=fs.readFileSync(require('node:path').join(__dirname,'..','assets/rootwound',name));assert.equal(png.toString('ascii',1,4),'PNG');assert.ok(png.length<250000,name+' exceeds mobile asset budget');if(name!=='floor.png')assert.ok([4,6].includes(png[25])||png.includes(Buffer.from('tRNS')),name+' must preserve transparency')}
const moonglassSurfaceAssets={
  'assets/surface/moonglass-ground.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/surface/moonglass-gate-mark.png':[512,341,{maxBytes:100000}],
  'assets/entrances/depth-work-lamp.png':[512,358,{maxBytes:100000}],
  'assets/surface/moonglass-crystals.png':[512,256,{maxBytes:100000}],
  'assets/surface/moonglass-bloom-bed.png':[640,280,{maxBytes:120000}],
  'assets/surface/crystal-cache-closed.png':[384,334,{maxBytes:120000}],
  'assets/surface/crystal-cache-open.png':[384,350,{maxBytes:120000}],
  'assets/surface/moonglass-reliquary-closed.png':[384,334,{maxBytes:120000}],
  'assets/surface/moonglass-reliquary-open.png':[384,350,{maxBytes:120000}],
  'assets/surface/emberdeep-seal.png':[330,512,{maxBytes:100000}],
  'assets/entrances/moonglass-entrance.png':[512,466,{maxBytes:180000}]
};
const moonglassMineAssets={
  'assets/moonglass/floor.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/moonglass/wall.png':[512,366,{maxBytes:150000}],
  'assets/moonglass/moonglass-node.png':[512,466,{maxBytes:180000}],
  'assets/moonglass/moonglass-wall.png':[341,512,{maxBytes:100000}],
  'assets/moonglass/starshard-node.png':[512,512,{maxBytes:180000}],
  'assets/moonglass/starshard-wall.png':[341,512,{maxBytes:100000}],
  'assets/moonglass/crystal-pocket.png':[640,358,{maxBytes:180000}],
  'assets/moonglass/buried-cache.png':[384,273,{maxBytes:120000}],
  'assets/moonglass/mining-rush-shrine.png':[459,512,{maxBytes:150000}],
  'assets/moonglass/prismatic-fault.png':[384,512,{maxBytes:120000}],
  'assets/moonglass/starbound-geode.png':[384,512,{maxBytes:120000}],
  'assets/moonglass/route-marker.png':[512,256,{maxBytes:120000}]
};
const prismaticAssets={
  'assets/prismatic/floor.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/prismatic/wall.png':[512,366,{maxBytes:120000}],
  'assets/prismatic/prismite-node.png':[512,466,{maxBytes:180000}],
  'assets/prismatic/prismite-wall.png':[341,512,{maxBytes:100000}],
  'assets/prismatic/lunacore-node.png':[512,512,{maxBytes:180000}],
  'assets/prismatic/lunacore-wall.png':[341,512,{maxBytes:100000}],
  'assets/prismatic/phasecrystal-node.png':[512,466,{maxBytes:180000}],
  'assets/prismatic/phasecrystal-wall.png':[341,512,{maxBytes:100000}],
  'assets/prismatic/deepstone-wall.png':[341,512,{maxBytes:100000}],
  'assets/prismatic/depth-portal.png':[512,444,{maxBytes:180000}],
  'assets/prismatic/sell-station.png':[512,455,{maxBytes:180000}],
  'assets/prismatic/drill-forge.png':[512,512,{maxBytes:180000}],
  'assets/prismatic/crystal-pocket.png':[640,358,{maxBytes:180000}],
  'assets/prismatic/buried-cache.png':[384,273,{maxBytes:120000}],
  'assets/prismatic/mining-rush-shrine.png':[459,512,{maxBytes:150000}]
};
const moonglassDropAssets={
  'assets/drops/moonglass-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/starshard-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/deepstone-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/prismite-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/lunacore-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/phasecrystal-drop.png':[256,256,{maxBytes:60000}]
};
const emberdeepSurfaceAssets={
  'assets/surface/emberdeep-ground.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/surface/emberdeep-slag-clusters.png':[512,256,{maxBytes:100000}],
  'assets/surface/emberdeep-fault-bed.png':[640,280,{maxBytes:120000}],
  'assets/surface/emberdeep-mine-path.png':[768,341,{maxBytes:180000}],
  'assets/surface/emberdeep-seal-mark.png':[512,341,{maxBytes:120000}],
  'assets/entrances/emberdeep-entrance.png':[512,466,{maxBytes:180000}],
  'assets/surface/foundry-lockbox-closed.png':[384,334,{maxBytes:140000}],
  'assets/surface/foundry-lockbox-open.png':[384,350,{maxBytes:140000}],
  'assets/surface/ember-vault-closed.png':[384,334,{maxBytes:140000}],
  'assets/surface/ember-vault-open.png':[384,350,{maxBytes:140000}]
};
const emberdeepMineAssets={
  'assets/emberdeep/floor.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/emberdeep/wall.png':[512,366,{maxBytes:150000}],
  'assets/emberdeep/route-marker.png':[512,256,{maxBytes:120000}],
  'assets/emberdeep/crystal-pocket.png':[640,358,{maxBytes:180000}],
  'assets/emberdeep/buried-cache.png':[384,273,{maxBytes:120000}],
  'assets/emberdeep/mining-rush-shrine.png':[459,512,{maxBytes:150000}],
  'assets/emberdeep/emberstone-node.png':[512,466,{maxBytes:180000}],
  'assets/emberdeep/sunslag-node.png':[512,512,{maxBytes:180000}],
  'assets/emberdeep/emberstone-wall.png':[341,512,{maxBytes:100000}],
  'assets/emberdeep/sunslag-wall.png':[341,512,{maxBytes:100000}],
  'assets/emberdeep/cinder-bulkhead.png':[384,512,{maxBytes:140000}],
  'assets/emberdeep/crucible-seal.png':[384,512,{maxBytes:140000}]
};
const moltenAssets={
  'assets/molten/floor.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/molten/wall.png':[512,366,{maxBytes:150000}],
  'assets/molten/depth-portal.png':[512,444,{maxBytes:180000}],
  'assets/molten/sell-station.png':[512,455,{maxBytes:180000}],
  'assets/molten/drill-forge.png':[512,512,{maxBytes:180000}],
  'assets/molten/crystal-pocket.png':[640,358,{maxBytes:180000}],
  'assets/molten/buried-cache.png':[384,273,{maxBytes:120000}],
  'assets/molten/mining-rush-shrine.png':[459,512,{maxBytes:150000}],
  'assets/molten/magmaite-node.png':[512,466,{maxBytes:180000}],
  'assets/molten/deepstone-node.png':[512,457,{maxBytes:180000}],
  'assets/molten/furnaceheart-node.png':[512,512,{maxBytes:180000}],
  'assets/molten/infernium-node.png':[512,466,{maxBytes:180000}],
  'assets/molten/magmaite-wall.png':[341,512,{maxBytes:100000}],
  'assets/molten/deepstone-wall.png':[341,512,{maxBytes:100000}],
  'assets/molten/furnaceheart-wall.png':[341,512,{maxBytes:100000}],
  'assets/molten/infernium-wall.png':[341,512,{maxBytes:100000}]
};
const emberdeepDropAssets={
  'assets/drops/emberstone-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/sunslag-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/magmaite-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/furnaceheart-drop.png':[256,256,{maxBytes:60000}],
  'assets/drops/infernium-drop.png':[256,256,{maxBytes:60000}]
};
const starfallSurfaceAssets={
  'assets/surface/starfall-ground.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/surface/starfall-shard-clusters.png':[512,256,{maxBytes:120000}],
  'assets/surface/starfall-lattice-bed.png':[640,280,{maxBytes:120000}],
  'assets/surface/starfall-mine-path.png':[768,341,{maxBytes:180000}],
  'assets/surface/starfall-seal.png':[376,512,{maxBytes:100000}],
  'assets/surface/starfall-seal-mark.png':[512,341,{maxBytes:120000}],
  'assets/entrances/starfall-entrance.png':[512,466,{maxBytes:180000}],
  'assets/surface/astral-cache-closed.png':[384,334,{maxBytes:140000}],
  'assets/surface/astral-cache-open.png':[384,350,{maxBytes:140000}],
  'assets/surface/celestial-coffer-closed.png':[384,334,{maxBytes:140000}],
  'assets/surface/celestial-coffer-open.png':[384,350,{maxBytes:140000}],
  'assets/surface/starforge-station.png':[512,512,{maxBytes:180000}]
};
const starfallMineAssets={
  'assets/starfall/floor.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/starfall/wall.png':[512,366,{maxBytes:150000}],
  'assets/starfall/route-marker.png':[512,256,{maxBytes:120000}],
  'assets/starfall/crystal-pocket.png':[640,358,{maxBytes:180000}],
  'assets/starfall/buried-cache.png':[384,273,{maxBytes:120000}],
  'assets/starfall/mining-rush-shrine.png':[459,512,{maxBytes:150000}],
  'assets/starfall/astralite-node.png':[512,466,{maxBytes:180000}],
  'assets/starfall/crownstone-node.png':[512,512,{maxBytes:180000}],
  'assets/starfall/astralite-wall.png':[341,512,{maxBytes:100000}],
  'assets/starfall/crownstone-wall.png':[341,512,{maxBytes:100000}],
  'assets/starfall/astral-bridge-lock.png':[384,512,{maxBytes:140000}],
  'assets/starfall/crownstone-ward.png':[384,512,{maxBytes:140000}]
};
const voidstarAssets={
  'assets/voidstar/floor.png':[512,512,{alpha:false,maxBytes:220000}],
  'assets/voidstar/wall.png':[512,366,{maxBytes:150000}],
  'assets/voidstar/depth-portal.png':[512,444,{maxBytes:180000}],
  'assets/voidstar/sell-station.png':[512,455,{maxBytes:180000}],
  'assets/voidstar/drill-forge.png':[512,512,{maxBytes:180000}],
  'assets/voidstar/crystal-pocket.png':[640,358,{maxBytes:180000}],
  'assets/voidstar/buried-cache.png':[384,273,{maxBytes:120000}],
  'assets/voidstar/mining-rush-shrine.png':[459,512,{maxBytes:150000}],
  'assets/voidstar/voidglass-node.png':[512,466,{maxBytes:180000}],
  'assets/voidstar/deepstone-node.png':[512,457,{maxBytes:180000}],
  'assets/voidstar/singularity-node.png':[512,512,{maxBytes:180000}],
  'assets/voidstar/voidglass-wall.png':[341,512,{maxBytes:100000}],
  'assets/voidstar/deepstone-wall.png':[341,512,{maxBytes:100000}],
  'assets/voidstar/singularity-wall.png':[341,512,{maxBytes:100000}]
};
for(const [relative,[assetWidth,assetHeight,options]] of Object.entries({...moonglassSurfaceAssets,...moonglassMineAssets,...prismaticAssets,...moonglassDropAssets,...emberdeepSurfaceAssets,...emberdeepMineAssets,...moltenAssets,...emberdeepDropAssets,...starfallSurfaceAssets,...starfallMineAssets,...voidstarAssets}))assertPng(relative,assetWidth,assetHeight,options);
const storage=new Map();

function createElement(id){
  const classes=new Set(),listeners=new Map(),style={removeProperty(name){delete this[name]}};
  return{
    id,textContent:'',hidden:false,style,dataset:{},disabled:false,clientWidth:390,clientHeight:700,
    get offsetWidth(){return id==='joystick'?104:390},get offsetHeight(){return id==='joystick'?104:700},
    classList:{add:value=>classes.add(value),remove:value=>classes.delete(value),toggle:(value,force)=>force===undefined?(classes.has(value)?classes.delete(value):classes.add(value)):force?classes.add(value):classes.delete(value),contains:value=>classes.has(value)},
    addEventListener(type,listener){if(!listeners.has(type))listeners.set(type,[]);listeners.get(type).push(listener)},
    dispatchEvent(event){if(!event.target)event.target=this;if(!event.preventDefault)event.preventDefault=function(){this.defaultPrevented=true};for(const listener of listeners.get(event.type)||[])listener(event);return!event.defaultPrevented},
    setAttribute(name,value){this[name]=String(value)},setPointerCapture(){},contains(){return true},querySelector(){return null},
    getBoundingClientRect(){const left=Number.parseFloat(style.left)||0,top=Number.parseFloat(style.top)||0,width=this.offsetWidth,height=this.offsetHeight;return{left,top,x:left,y:top,width,height,right:left+width,bottom:top+height}}
  };
}

function createRuntime({failWalkSheets=false,reducedMotion=false}={}){
  const elements=new Map();
  const element=id=>{if(!elements.has(id))elements.set(id,createElement(id));return elements.get(id)};
  const gradient={addColorStop(){}};
  const drawCalls=[];
  const canvasContext=new Proxy({}, {get:(_target,key)=>key==='createLinearGradient'||key==='createRadialGradient'?()=>gradient:key==='measureText'?()=>({width:0}):key==='drawImage'?(image,...args)=>drawCalls.push({src:image.src||'[canvas]',args}):()=>{},set:()=>true});
  element('gameCanvas').getContext=()=>canvasContext;
  const document={hidden:false,getElementById:element,addEventListener(){},createElement:tag=>tag==='canvas'?{width:1,height:1,src:'[lightmap]',getContext:()=>canvasContext}:createElement('dynamic-'+tag)};
  const window={devicePixelRatio:2,addEventListener(){},confirm:()=>true,matchMedia:()=>({matches:reducedMotion,addEventListener(){},addListener(){}})};
  class TestAudio{constructor(src){this.src=src;this.volume=1;this.loop=false;this.paused=true;this.preload='';this.playsInline=false}play(){this.paused=false;return Promise.resolve()}pause(){this.paused=true}}
  class TestImage{constructor(){this.complete=true;this.naturalWidth=512;this.naturalHeight=512;this.decoding='async';this.onload=null;this._src=''}set src(value){this._src=value;if(value.includes('assets/ambient/')||value.includes('assets/world-life/')){this.naturalWidth=1024;this.naturalHeight=256}else if(value.includes('-walk.png')){this.naturalWidth=failWalkSheets?0:1536;this.naturalHeight=failWalkSheets?0:1024;this.complete=!failWalkSheets}else if(value.includes('-drop.png')){this.naturalWidth=256;this.naturalHeight=256}else if(value.includes('magic-crystal-pocket')){this.naturalWidth=640;this.naturalHeight=358}else if(value.includes('miner-b-drill-burrower')){this.naturalWidth=348;this.naturalHeight=512}else if(value.includes('miner-b-drill-pulse')){this.naturalWidth=361;this.naturalHeight=512}else if(value.includes('miner-b-drill-deepcore')){this.naturalWidth=354;this.naturalHeight=512}else if(value.includes('miner-b')){this.naturalWidth=315;this.naturalHeight=512}else this.naturalWidth=512;queueMicrotask(()=>this.onload&&this.onload())}get src(){return this._src}}
  const browserStorage={
    get length(){return storage.size},key:index=>Array.from(storage.keys())[index]??null,
    getItem:key=>storage.has(key)?storage.get(key):null,setItem:(key,value)=>storage.set(key,String(value)),removeItem:key=>storage.delete(key)
  };
  const context={
    window,document,console,
    localStorage:browserStorage,
    requestAnimationFrame(){},setTimeout(){return 1},clearTimeout(){},
    navigator:{vibrate:()=>true},Image:TestImage,Audio:TestAudio
  };
  window.window=window;window.document=document;window.localStorage=context.localStorage;window.requestAnimationFrame=context.requestAnimationFrame;
  vm.runInContext(source,vm.createContext(context),{filename:'script.js'});
  return{api:window.__everDeeperTest,elements,drawCalls};
}

let runtime=createRuntime();
let api=runtime.api;
const expectedApiKeys=[
  'activateMiningRush','autoSort','breakDepositRock','breakVeinRock','buyMovementSpeed','buyStorageChest','claimPocketReward','clearMineBarrier','clearSwing','collectGroundDrops',
  'discoverCavern','discoverDepthEntrance','dismissAchievement','dismissHeatTutorial','dismissHubTutorial','dismissStartMenu','enterDepth','enterHub','enterMine','evaluateAchievements','exitDepth','exitHub','exitMine','expireGroundDrops',
  'forceGlobalLootSweep','forgeStarVariant','grantCargo','grantGold','grantMined','hitDepositRock','hubCollisionAt','interact','mineCollisionAt','mineOnce','mineTerrainCell','openAchievementPopup','openAchievements',
  'openChest','openInventory','packBaseModule','placeBaseModule','placeHubCell','primePrecision','removeHubCell','renderOnce','reset','resetAll','restoreRocks','restoreTerrain','sampleHeadlampRay','save','selectHubBuildTool','sellCargo',
  'setAim','setAudioSetting','setDrillLevel','setHubBuildMode','setMiningHeld','setMoveVector','setPickaxeLevel','setPosition','setReducedMotion','setStarforgeVariant','setSwingProgress','setTimeScale','settleAchievement',
  'snapshot','spawnGroundDrops','startEmberdeepGateTransition','startMoonglassGateTransition','startMusic','startStarfallGateTransition','step','stopMove','surfaceBoundaryBlockedAt','takeAllFromChest','unlockAllAreas',
  'unlockHub','unlockStarfall','upgradeDrill'
];
const expectedSnapshotKeys=[
  'achievements','activeContext','ambientLife','assetRendering','assetVersion','biome','bonusVeinRendering','build','camera','characterRendering','chests','controls','depth','discoveryRendering',
  'effectivePickaxe','emberdeepGateTransition','emberdeepRendering','entranceAssetRendering','feedback','focus','goal','groundDrops','guide','heatStreak','hub','lighting','lootSweep','markerStyle','mine',
  'mineralNodeRenderScale','miningFeedbackRendering','miningRush','moltenRendering','moonglassGateTransition','moonglassRendering','movement','music','patchNotes','player','prismaticRendering',
  'progression','protectedCargo','resourceRendering','rocks','rootwoundRendering','scene','sellableCargo','starfallGateTransition','starfallRendering','startMenu','starterGateRendering',
  'starterRendering','state','surfaceAssetRendering','surfaceBoundaries','surfaceEmberdeepRendering','surfaceMoonglassRendering','surfaceStarfallRendering','toolMode','veins','voidstarRendering','worldLife'
];
assert.deepEqual(Object.keys(api).sort(),expectedApiKeys,'test API contract changed unexpectedly');
assert.deepEqual(Object.keys(api.snapshot()).sort(),expectedSnapshotKeys,'snapshot contract changed unexpectedly');
assert.equal(api.snapshot().build.version,'0.38.1');
assert.equal(api.snapshot().build.name,'UNDERGROUND HUB');
assert.equal(runtime.elements.get('buildVersion').textContent,'v0.38.1');
assert.equal(api.snapshot().assetVersion,'03801');
const patchNotes=api.snapshot().patchNotes,patchNote=version=>patchNotes.find(note=>note.version===version);
assert.match(patchNote('0.38.1').items.join(' '),/three-point crown/);assert.match(patchNote('0.38.0').items.join(' '),/touch-first build mode/);assert.match(patchNote('0.37.5').items.join(' '),/1.30x speed/);
assert.equal(patchNotes.length,33);assert.match(patchNote('0.37.4').items.join(' '),/high three-quarter perspective/);assert.match(patchNote('0.37.4').items.join(' '),/west to east/);assert.match(patchNote('0.37.3').items.join(' '),/premium silhouette/);assert.match(patchNote('0.37.3').items.join(' '),/physically locked/);assert.match(patchNote('0.37.2').items.join(' '),/dedicated premium mining sheets/);assert.match(patchNote('0.37.2').items.join(' '),/Routine damage, shell, tunnel, pickup, and partial-vein text/);assert.match(patchNote('0.37.1').items.join(' '),/old canvas rings and procedural debris are gone/);assert.match(patchNote('0.37.1').items.join(' '),/real premium drop assets/);assert.match(patchNote('0.37.0').items.join(' '),/premium environmental drift/);assert.match(patchNote('0.37.0').items.join(' '),/Footsteps disturb the ground/);assert.match(patchNote('0.36.4').items.join(' '),/flee continuously/);assert.match(patchNote('0.36.3').items.join(' '),/keep their render slot/);assert.match(patchNote('0.36.2').items.join(' '),/pause and rest naturally/);assert.match(patchNote('0.36.2').items.join(' '),/Nearby mining startles residents/);assert.match(patchNote('0.36.1').items.join(' '),/clearly visible routes/);assert.match(patchNote('0.36.1').items.join(' '),/sampled against terrain/);assert.match(patchNote('0.36.0').items.join(' '),/Four premium animated creatures/);assert.match(patchNote('0.36.0').items.join(' '),/Reduced Motion/);assert.match(patchNote('0.35.11').items.join(' '),/70 Phase Crystal/);assert.match(patchNote('0.35.10').items.join(' '),/DEEPCORE DRILL REQUIRED/);assert.match(patchNote('0.35.9').items.join(' '),/Eight unreachable Astralite nodes/);assert.match(patchNote('0.35.8').items.join(' '),/30, 40, 50, 60, and 70/);assert.match(patchNote('0.35.7').items.join(' '),/Holding Mine/);assert.match(patchNote('0.35.7').items.join(' '),/manual press/);assert.match(patchNote('0.35.6').items.join(' '),/painted width/);assert.match(patchNote('0.35.5').items.join(' '),/tink-tink-tink/);assert.match(patchNote('0.35.4').items.join(' '),/complete passage/);assert.match(patchNote('0.35.3').items.join(' '),/natural openings/);assert.match(patchNote('0.35.2').items.join(' '),/unbreakable-wall PNG/);assert.match(patchNote('0.35.1').items.join(' '),/production PNGs/);assert.match(patchNote('0.35.0').items.join(' '),/Physical biome walls/);assert.match(patchNote('0.34.7').items.join(' '),/Gameplay, balance, progression, controls, and visuals are unchanged/);assert.match(patchNote('0.34.6').items.join(' '),/Reset All Progress/);assert.match(patchNote('0.34.1').items.join(' '),/100 Emberstone/);assert.match(patchNote('0.34.1').items.join(' '),/200 Astralite and 200 Crownstone/);assert.equal(api.snapshot().lighting.readableTextOverlay,true);assert.equal(api.snapshot().lighting.textPass,'after-lighting');
assert.equal(JSON.stringify(api.snapshot().startMenu.actions),JSON.stringify(['continue','new-game','achievements','settings']));
assert.equal(api.snapshot().startMenu.achievementsInPause,false);
assert.equal(JSON.stringify(api.snapshot().music),JSON.stringify({asset:'assets/audio/ever-deeper-drift-loop.mp3',volume:1,loop:true,started:false,enabled:true,effectsEnabled:true}));
assert.equal(JSON.stringify(api.startMusic()),JSON.stringify({src:'assets/audio/ever-deeper-drift-loop.mp3?v=03801',volume:1,loop:true,paused:false}));
api.dismissStartMenu();
const viewportElement=runtime.elements.get('viewport'),canvasElement=runtime.elements.get('gameCanvas'),joystickElement=runtime.elements.get('joystick'),mineElement=runtime.elements.get('mineButton');
viewportElement.dispatchEvent({type:'pointerdown',target:canvasElement,pointerId:301,button:0,clientX:120,clientY:260});
assert.equal(joystickElement.classList.contains('active'),true);assert.equal(joystickElement.style.left,'68px');assert.equal(joystickElement.style.top,'208px');
viewportElement.dispatchEvent({type:'pointermove',pointerId:301,clientX:190,clientY:248});mineElement.dispatchEvent({type:'pointerdown',pointerId:302});
assert.equal(JSON.stringify(api.snapshot().controls),JSON.stringify({floatingJoystick:true,activationSurface:'gameCanvas',pressAnywhere:true,independentMinePointer:true,joystickPointer:301,moveX:1,moveY:-12/(104*.31),mineHeld:true}));
mineElement.dispatchEvent({type:'pointerup',pointerId:302});viewportElement.dispatchEvent({type:'pointerup',pointerId:301});
assert.equal(JSON.stringify(api.snapshot().controls),JSON.stringify({floatingJoystick:true,activationSurface:'gameCanvas',pressAnywhere:true,independentMinePointer:true,joystickPointer:null,moveX:0,moveY:0,mineHeld:false}));assert.equal(joystickElement.classList.contains('active'),false);
assert.equal(api.setAudioSetting('music',false),false);assert.equal(api.snapshot().music.enabled,false);assert.equal(api.snapshot().music.started,false);
assert.equal(api.setAudioSetting('effects',false),false);assert.equal(api.snapshot().music.effectsEnabled,false);
assert.equal(api.setAudioSetting('music',true),true);assert.equal(api.setAudioSetting('effects',true),true);
assert.equal(JSON.stringify(api.snapshot().assetRendering),JSON.stringify({stone:['node'],copper:['wall','node'],gold:['wall','node']}));
assert.equal(JSON.stringify(api.snapshot().entranceAssetRendering),JSON.stringify({mossMine:true,moonMine:true,emberMine:true,starMine:true}));
assert.equal(JSON.stringify(api.snapshot().surfaceBoundaries),JSON.stringify({walls:[
  {id:'moonglass',x:1110,y:650,gap:118,unlockKey:'areaUnlocked',renderWidth:320,collisionLeft:60,collisionRight:60,lockedGateHalfWidth:160,locked:true},
  {id:'emberdeep',x:2240,y:650,gap:118,unlockKey:'emberdeepUnlocked',renderWidth:320,collisionLeft:70,collisionRight:69,lockedGateHalfWidth:160,locked:true},
  {id:'starfall',x:3360,y:650,gap:118,unlockKey:'fourthUnlocked',renderWidth:320,collisionLeft:73,collisionRight:76,lockedGateHalfWidth:160,locked:true}
],assets:{moonglass:'assets/surface/boundary-mossvein-moonglass.png',emberdeep:'assets/surface/boundary-moonglass-emberdeep.png',starfall:'assets/surface/boundary-emberdeep-starfall.png'},premiumAssets:true,fullHeightAssets:true,naturalAssetOpenings:true,legacyCanvasWalls:false,legacyRectangularGateCuts:false,groundBlendWidth:24,gateOnlyPassage:true,persistentAfterUnlock:true,portalFocus:true}));
assert.equal(api.surfaceBoundaryBlockedAt(1020,220),false);assert.equal(api.surfaceBoundaryBlockedAt(1040,220),true);assert.equal(api.surfaceBoundaryBlockedAt(1190,220),true);assert.equal(api.surfaceBoundaryBlockedAt(1200,220),false);assert.equal(api.surfaceBoundaryBlockedAt(1110,650),false);
assert.equal(JSON.stringify(api.snapshot().surfaceAssetRendering),JSON.stringify({mossveinGround:true,mainRoad:{mossvein:'assets/surface/road-mossvein.png',moonglass:'assets/surface/road-moonglass.png',emberdeep:'assets/surface/road-emberdeep.png',starfall:'assets/surface/road-starfall.png'},seamlessBiomeRoad:true,roadCrossfadeWidth:80,mossveinMineApproach:'assets/surface/mossvein-mine-path.png',mossveinMineApproachBounds:{x:125,y:728,w:700,h:200},mossveinMinePosition:{x:180,y:830},branchUnderMainRoad:true,naturalCaveOverlap:true,naturalRoadOverlap:true,legacyBakedMainRoad:false,legacyMossveinGrid:false,legacyMossveinPath:false,legacyMossveinDecorations:false}));
assert.equal(JSON.stringify(api.snapshot().starterRendering),JSON.stringify({sellStation:'assets/surface/assay-station.png',forgeStation:'assets/surface/forge-station.png',storageChest:'assets/surface/storage-chest.png',wayfarerShop:'assets/surface/wayfarer-shop.png',treasureClosed:'assets/surface/treasure-cache-closed.png',treasureOpen:'assets/surface/treasure-cache-open.png',groundDrops:completeDropPaths,legacyCanvasStations:false,legacyMossveinChests:false,legacyStarterDrops:false}));
assert.equal(JSON.stringify({...api.snapshot().resourceRendering,paths:undefined,bounds:undefined}),JSON.stringify({completeResourceSet:true,sharedWorldAndUiAssets:true,transparentBoundsNormalized:true,nodeAssetCoverage:true,objectiveIcons:true,inventoryIcons:true,storageIcons:true,recipeIcons:true,ledgerIcons:true,croppedGroundDrops:true,legacyCanvasResourceSymbols:false,legacyCanvasResourceDrops:false}));
assert.equal(JSON.stringify(api.snapshot().resourceRendering.paths),JSON.stringify(completeDropPaths));
assert.equal(JSON.stringify(api.snapshot().starterGateRendering),JSON.stringify({moonglassGate:'assets/surface/moonglass-gate.png',moonglassGateMark:'assets/surface/moonglass-gate-mark.png',emberdeepSeal:'assets/surface/emberdeep-seal.png',emberdeepSealMark:'assets/surface/emberdeep-seal-mark.png',starfallSeal:'assets/surface/starfall-seal.png',starfallSealMark:'assets/surface/starfall-seal-mark.png',renderBounds:{maxWidth:260,maxHeight:238,bottom:110},markRenderWidth:300,markSourceBounds:{moonglass:{x:14,y:55,w:484,h:222},emberdeep:{x:28,y:6,w:456,h:329},starfall:{x:34,y:54,w:449,h:231}},collisionFollowsPaintedCliff:true,integratedBoundaryScale:true,biomeAlignedPerspective:true,northSouthStructure:true,westEastPassage:true,premiumEnergyBarrier:true,duplicateCanvasSeam:false,proceduralGateShadow:false,animatedMoonglassTransition:true,animatedEmberdeepTransition:true,animatedStarfallTransition:true,activationSequence:['flash','shake','sink'],assetSilhouetteFlash:true,preSinkShake:true,unscaledGroundSink:true,collisionLocksUntilSunk:true,reducedMotionSafe:true,openWorldGatesRemoved:true,legacyStarterGate:false}));
const storageBeforeBoundaries=new Map(storage),boundaryRuntime=createRuntime(),boundaryApi=boundaryRuntime.api;boundaryApi.dismissStartMenu();
for(const [x,asset] of [[1110,'boundary-mossvein-moonglass.png'],[2240,'boundary-moonglass-emberdeep.png'],[3360,'boundary-emberdeep-starfall.png']]){boundaryRuntime.drawCalls.length=0;boundaryApi.setPosition(x,650);boundaryApi.renderOnce();assert.ok(boundaryRuntime.drawCalls.some(call=>call.src.includes(asset)),asset+' must render at its world gate')}
boundaryApi.setPosition(900,650);boundaryApi.setMoveVector(1,0);boundaryApi.step(.6);assert.ok(boundaryApi.snapshot().player.x<=950,'locked Moonglass gate must stop outside its visual footprint');
boundaryApi.unlockAllAreas();boundaryApi.setPosition(1060,650);boundaryApi.setMoveVector(1,0);boundaryApi.step(.6);assert.ok(boundaryApi.snapshot().player.x>1110,'opened Moonglass gate must be the passable opening');
boundaryApi.setPosition(1000,220);boundaryApi.setMoveVector(1,0);boundaryApi.step(.6);assert.ok(boundaryApi.snapshot().player.x<=1026,'persistent biome wall must stop at the painted cliff edge after unlock');boundaryApi.stopMove();
boundaryApi.unlockStarfall();
for(const scene of ['mossMine','moonMine','emberMine','starMine']){
  boundaryApi.enterMine(scene);const mineSnapshot=boundaryApi.snapshot().mine,definition=gameDataWindow.EverDeeperGameData.MINE_DEFINITIONS[scene],deepAccess=mineSnapshot.deepAccess,finalBarrier=definition.barriers[definition.barriers.length-1],firstCavern=mineSnapshot.discovery.caverns[0];
  const expectedWall={mossMine:'assets/mossvein/unbreakable-wall.png',moonMine:'assets/moonglass/unbreakable-wall.png',emberMine:'assets/emberdeep/unbreakable-wall.png',starMine:'assets/starfall/unbreakable-wall.png'}[scene];
  assert.ok(deepAccess,scene+' must have a deep-access wall');assert.equal(deepAccess.role,'deepAccessWall');assert.equal(deepAccess.barrierId,finalBarrier.id);assert.equal(deepAccess.x,0);assert.ok(deepAccess.w>=finalBarrier.x+finalBarrier.w,scene+' wall must prevent tunneling below the final ore gate');assert.ok(deepAccess.w<definition.width-52,scene+' must retain a right-side descent');assert.ok(deepAccess.y+deepAccess.h<firstCavern.y-firstCavern.ry,scene+' wall must lead into the first large cavern');assert.equal(mineSnapshot.deepAccessWallAsset,expectedWall);assert.equal(mineSnapshot.unbreakableWallAsset,expectedWall);assert.equal(mineSnapshot.unbreakableWallPremiumAsset,true);assert.equal(mineSnapshot.mineableTerrainUsesUnbreakableAsset,false);assert.equal(mineSnapshot.legacyCanvasSolidWalls,false);assert.equal(mineSnapshot.deepAccessPremiumAsset,true);assert.equal(mineSnapshot.legacyCanvasDeepAccessFace,false);assert.equal(mineSnapshot.visibleWallFaces,true);assert.equal(boundaryApi.mineCollisionAt(deepAccess.w-80,deepAccess.y+70),true);boundaryRuntime.drawCalls.length=0;boundaryApi.setPosition(deepAccess.w-160,deepAccess.y+70);boundaryApi.renderOnce();assert.ok(boundaryRuntime.drawCalls.some(call=>call.src.includes(expectedWall)),scene+' deep wall must render its dedicated unbreakable asset');boundaryApi.exitMine();
}
storage.clear();for(const [key,value] of storageBeforeBoundaries)storage.set(key,value);
assert.equal(JSON.stringify(api.snapshot().rootwoundRendering),JSON.stringify({floor:'assets/rootwound/floor.png',wall:'assets/rootwound/wall.png',nodes:['rootiron','deepstone','ambercore','burrowsteel'],rootironWall:'assets/rootwound/rootiron-wall.png',shaft:'assets/rootwound/depth-shaft.png',sellStation:'assets/rootwound/sell-station.png',drillForge:'assets/rootwound/drill-forge.png',legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyResourceNodes:false}));
const expectedMoonglassRendering={surfaceGround:'assets/surface/moonglass-ground.png',surfaceCrystals:'assets/surface/moonglass-crystals.png',bloomBed:'assets/surface/moonglass-bloom-bed.png',entrance:'assets/entrances/moonglass-entrance.png',gateMark:'assets/surface/moonglass-gate-mark.png',emberdeepSeal:'assets/surface/emberdeep-seal.png',openBoundaryGatesRemoved:true,animatedGateTransition:true,smoothMossveinBlend:true,backgroundCrystalsDistinct:true,chests:{crystalCache:{closed:'assets/surface/crystal-cache-closed.png',open:'assets/surface/crystal-cache-open.png'},reliquary:{closed:'assets/surface/moonglass-reliquary-closed.png',open:'assets/surface/moonglass-reliquary-open.png'}},floor:'assets/moonglass/floor.png',wall:'assets/moonglass/wall.png',routeMarker:'assets/moonglass/route-marker.png',pocket:'assets/moonglass/crystal-pocket.png',cache:'assets/moonglass/buried-cache.png',shrine:'assets/moonglass/mining-rush-shrine.png',nodes:{moonglass:'assets/moonglass/moonglass-node.png',starshard:'assets/moonglass/starshard-node.png'},wallHints:{moonglass:'assets/moonglass/moonglass-wall.png',starshard:'assets/moonglass/starshard-wall.png'},barriers:{moon_prism_gate:'assets/moonglass/prismatic-fault.png',moon_star_lock:'assets/moonglass/starbound-geode.png'},drops:{moonglass:'assets/drops/moonglass-drop.png',starshard:'assets/drops/starshard-drop.png'},legacySurfaceDecorations:false,legacyMineFloor:false,legacyMineTerrain:false,legacyMineWalls:false,legacyBarriers:false,legacyPocketRewards:false,legacyResourceNodes:false};
const expectedPrismaticRendering={floor:'assets/prismatic/floor.png',wall:'assets/prismatic/wall.png',shaft:'assets/prismatic/depth-portal.png',sellStation:'assets/prismatic/sell-station.png',drillForge:'assets/prismatic/drill-forge.png',pocket:'assets/prismatic/crystal-pocket.png',cache:'assets/prismatic/buried-cache.png',shrine:'assets/prismatic/mining-rush-shrine.png',nodes:{prismite:'assets/prismatic/prismite-node.png',deepstone:'assets/rootwound/deepstone-node.png',lunacore:'assets/prismatic/lunacore-node.png',phasecrystal:'assets/prismatic/phasecrystal-node.png'},wallHints:{prismite:'assets/prismatic/prismite-wall.png',deepstone:'assets/prismatic/deepstone-wall.png',lunacore:'assets/prismatic/lunacore-wall.png',phasecrystal:'assets/prismatic/phasecrystal-wall.png'},drops:{deepstone:'assets/drops/deepstone-drop.png',prismite:'assets/drops/prismite-drop.png',lunacore:'assets/drops/lunacore-drop.png',phasecrystal:'assets/drops/phasecrystal-drop.png'},legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyPocketRewards:false,legacyResourceNodes:false};
const expectedSurfaceEmberdeepRendering={ground:'assets/surface/emberdeep-ground.png',slag:'assets/surface/emberdeep-slag-clusters.png',faultBed:'assets/surface/emberdeep-fault-bed.png',minePath:'assets/surface/emberdeep-mine-path.png',minePathBounds:{x:2456,y:772,w:500,h:222},minePathRotation:-.105,minePathPivot:{x:2956,y:809},minePathMouthTarget:{x:2480,y:1015},entrance:'assets/entrances/emberdeep-entrance.png',entrancePosition:{x:2480,y:970,radius:112},entranceFlipped:true,gateSeal:'assets/surface/emberdeep-seal.png',gateMark:'assets/surface/emberdeep-seal-mark.png',animatedGateTransition:true,smoothMoonglassBlend:true,continuousBlendUnderlay:true,backgroundSlagDistinct:true,chests:{foundry:{closed:'assets/surface/foundry-lockbox-closed.png',open:'assets/surface/foundry-lockbox-open.png'},vault:{closed:'assets/surface/ember-vault-closed.png',open:'assets/surface/ember-vault-open.png'}},legacyGrid:false,legacyDecorations:false,legacyChests:false,legacyEntrance:false,legacyGate:false};
const expectedEmberdeepRendering={floor:'assets/emberdeep/floor.png',wall:'assets/emberdeep/wall.png',routeMarker:'assets/emberdeep/route-marker.png',pocket:'assets/emberdeep/crystal-pocket.png',cache:'assets/emberdeep/buried-cache.png',shrine:'assets/emberdeep/mining-rush-shrine.png',nodes:{emberstone:'assets/emberdeep/emberstone-node.png',moonglass:'assets/moonglass/moonglass-node.png',sunslag:'assets/emberdeep/sunslag-node.png'},wallHints:{emberstone:'assets/emberdeep/emberstone-wall.png',moonglass:'assets/moonglass/moonglass-wall.png',sunslag:'assets/emberdeep/sunslag-wall.png'},barriers:{ember_bulkhead:'assets/emberdeep/cinder-bulkhead.png',ember_crucible_lock:'assets/emberdeep/crucible-seal.png'},drops:{emberstone:'assets/drops/emberstone-drop.png',moonglass:'assets/drops/moonglass-drop.png',sunslag:'assets/drops/sunslag-drop.png'},legacyMineFloor:false,legacyMineTerrain:false,legacyMineWalls:false,legacyBarriers:false,legacyPocketRewards:false,legacyResourceNodes:false};
const expectedMoltenRendering={floor:'assets/molten/floor.png',wall:'assets/molten/wall.png',shaft:'assets/molten/depth-portal.png',sellStation:'assets/molten/sell-station.png',drillForge:'assets/molten/drill-forge.png',pocket:'assets/molten/crystal-pocket.png',cache:'assets/molten/buried-cache.png',shrine:'assets/molten/mining-rush-shrine.png',nodes:{magmaite:'assets/molten/magmaite-node.png',deepstone:'assets/molten/deepstone-node.png',furnaceheart:'assets/molten/furnaceheart-node.png',infernium:'assets/molten/infernium-node.png'},wallHints:{magmaite:'assets/molten/magmaite-wall.png',deepstone:'assets/molten/deepstone-wall.png',furnaceheart:'assets/molten/furnaceheart-wall.png',infernium:'assets/molten/infernium-wall.png'},drops:{deepstone:'assets/drops/deepstone-drop.png',magmaite:'assets/drops/magmaite-drop.png',furnaceheart:'assets/drops/furnaceheart-drop.png',infernium:'assets/drops/infernium-drop.png'},legacyFloorDecorations:false,legacyTerrainTexture:false,legacyDepthShaft:false,legacyDepthStations:false,legacyPocketRewards:false,legacyResourceNodes:false};
const expectedSurfaceStarfallRendering={ground:'assets/surface/starfall-ground.png',shards:'assets/surface/starfall-shard-clusters.png',latticeBed:'assets/surface/starfall-lattice-bed.png',minePath:'assets/surface/starfall-mine-path.png',minePathBounds:{x:3450,y:760,w:650,h:289},minePathMouthTarget:{x:3505,y:1000},entrance:'assets/entrances/starfall-entrance.png',entrancePosition:{x:3505,y:1000,radius:112},gateSeal:'assets/surface/starfall-seal.png',gateMark:'assets/surface/starfall-seal-mark.png',starforge:'assets/surface/starforge-station.png',chests:{astralCache:{closed:'assets/surface/astral-cache-closed.png',open:'assets/surface/astral-cache-open.png'},celestialCoffer:{closed:'assets/surface/celestial-coffer-closed.png',open:'assets/surface/celestial-coffer-open.png'}},animatedGateTransition:true,smoothEmberdeepBlend:true,continuousBlendUnderlay:true,backgroundShardsDistinct:true,legacyGrid:false,legacyDecorations:false,legacyChests:false,legacyEntrance:false,legacyGate:false,legacyStarforge:false};
const expectedStarfallRendering={floor:'assets/starfall/floor.png',wall:'assets/starfall/wall.png',routeMarker:'assets/starfall/route-marker.png',pocket:'assets/starfall/crystal-pocket.png',cache:'assets/starfall/buried-cache.png',shrine:'assets/starfall/mining-rush-shrine.png',nodes:{astralite:'assets/starfall/astralite-node.png',crownstone:'assets/starfall/crownstone-node.png'},wallHints:{astralite:'assets/starfall/astralite-wall.png',crownstone:'assets/starfall/crownstone-wall.png'},barriers:{star_bridge_lock:'assets/starfall/astral-bridge-lock.png',star_crown_lock:'assets/starfall/crownstone-ward.png'},drops:{astralite:'assets/drops/astralite-drop.png',crownstone:'assets/drops/crownstone-drop.png'},legacyFloor:false,legacyTerrain:false,legacyWalls:false,legacyBarriers:false,legacyRewards:false,legacyNodes:false};
const expectedVoidstarRendering={floor:'assets/voidstar/floor.png',wall:'assets/voidstar/wall.png',shaft:'assets/voidstar/depth-portal.png',sellStation:'assets/voidstar/sell-station.png',drillForge:'assets/voidstar/drill-forge.png',pocket:'assets/voidstar/crystal-pocket.png',cache:'assets/voidstar/buried-cache.png',shrine:'assets/voidstar/mining-rush-shrine.png',nodes:{voidglass:'assets/voidstar/voidglass-node.png',deepstone:'assets/voidstar/deepstone-node.png',singularity:'assets/voidstar/singularity-node.png'},wallHints:{voidglass:'assets/voidstar/voidglass-wall.png',deepstone:'assets/voidstar/deepstone-wall.png',singularity:'assets/voidstar/singularity-wall.png'},drops:{deepstone:'assets/drops/deepstone-drop.png',voidglass:'assets/drops/voidglass-drop.png',singularity:'assets/drops/singularity-drop.png'},legacyFloor:false,legacyTerrain:false,legacyWalls:false,legacyRewards:false,legacyNodes:false,legacyShaft:false,legacyStations:false};
assert.equal(JSON.stringify(api.snapshot().moonglassRendering),JSON.stringify(expectedMoonglassRendering));
assert.equal(JSON.stringify(api.snapshot().prismaticRendering),JSON.stringify(expectedPrismaticRendering));
assert.equal(JSON.stringify(api.snapshot().surfaceEmberdeepRendering),JSON.stringify(expectedSurfaceEmberdeepRendering));
assert.equal(JSON.stringify(api.snapshot().emberdeepRendering),JSON.stringify(expectedEmberdeepRendering));
assert.equal(JSON.stringify(api.snapshot().moltenRendering),JSON.stringify(expectedMoltenRendering));
assert.equal(JSON.stringify(api.snapshot().surfaceStarfallRendering),JSON.stringify(expectedSurfaceStarfallRendering));
assert.equal(JSON.stringify(api.snapshot().starfallRendering),JSON.stringify(expectedStarfallRendering));
assert.equal(JSON.stringify(api.snapshot().voidstarRendering),JSON.stringify(expectedVoidstarRendering));
assert.equal(JSON.stringify(api.snapshot().discoveryRendering),JSON.stringify({crystalPocketAsset:'assets/mossvein/magic-crystal-pocket.png',cacheAsset:'assets/mossvein/buried-cache.png',shrineAsset:'assets/mossvein/mining-rush-shrine.png',legacyCavernRings:false,legacyMossveinPocketRewards:false,biomeGlow:true,routineDiscoveryText:false,rareDiscoveryText:false}));
assert.equal(JSON.stringify(api.snapshot().miningFeedbackRendering),JSON.stringify({routineImpactRings:false,routineBreakRings:false,routineImpactParticles:false,routineBreakParticles:false,discoveryCanvasBursts:false,upgradeCanvasRings:false,routineDamageText:false,routineBreakText:false,routinePickupText:false,majorEventTextOnly:true,premiumTerrainResponses:true,dedicatedImpactSheets:true,nonStackingImpactAssets:true,premiumSaleAssets:true,drillVibration:true,drillVibrationMaxOffset:2.05,cameraShake:false}));
assert.equal(JSON.stringify(api.snapshot().bonusVeinRendering),JSON.stringify({worldLabels:false,textPrompts:false,sleepingCracks:true,movingReadyPulse:true,radialTimer:true,completionBurst:true}));
assert.doesNotMatch(source,/vein\.label|BONUS VEIN|COOLED/);
assert.equal(JSON.stringify(api.snapshot().characterRendering),JSON.stringify({baseAsset:'assets/characters/miner-b.png',activeToolKey:'pickaxe-worn',activeRenderAsset:'assets/tools/pickaxe-worn.png',walkSheets:{base:'assets/characters/miner-b-walk.png','drill-burrower':'assets/characters/miner-b-drill-burrower-walk.png','drill-pulse':'assets/characters/miner-b-drill-pulse-walk.png','drill-deepcore':'assets/characters/miner-b-drill-deepcore-walk.png'},activeWalkAsset:'assets/characters/miner-b-walk.png',walkGrid:{columns:6,rows:4,cellSize:256,directions:['down','left','right','up']},walkRenderSize:120,toolLayerCount:8,drillCompositeCount:3,gripCrop:{x:246,y:307,w:69,h:101},gripPivot:{x:14,y:24},gripPoint:{x:42,y:50},layeredTools:true,animatedGrip:true,bodyReaction:true,sharedGripAnchor:true,fullDrillComposites:true,directionalWalk:true,distanceDrivenWalk:true,holsteredWalkTools:true,lazyDrillWalkSheets:true,staticMiningFallback:true,reducedMotion:false,legacyDrillLimbCrops:false,legacyCanvasCharacter:false,legacyCanvasTools:false}));
function assertRendered(drawCalls,paths){for(const path of paths)assert.ok(drawCalls.some(call=>call.src.includes(path)),path+' must render')}
function renderAt(testRuntime,testApi,x,y,paths){testApi.setPosition(x,y);testRuntime.drawCalls.length=0;testApi.renderOnce();assertRendered(testRuntime.drawCalls,paths)}
function pointDistance(x1,y1,x2,y2){return Math.hypot(x2-x1,y2-y1)}
function terrainIndexForRock(snapshot,rock){const cols=Math.ceil(snapshot.mine.width/snapshot.mine.terrain.tileSize);return Math.floor(rock.y/snapshot.mine.terrain.tileSize)*cols+Math.floor(rock.x/snapshot.mine.terrain.tileSize)}
function exposeRock(testApi,rock,maxHits=8){for(let hit=0;hit<maxHits&&!testApi.snapshot().rocks.find(item=>item.id===rock.id).exposed;hit++)testApi.mineTerrainCell(terrainIndexForRock(testApi.snapshot(),rock));assert.equal(testApi.snapshot().rocks.find(item=>item.id===rock.id).exposed,true,rock.type+' test node must be exposed')}

const storageBeforeAmbient=new Map(storage);storage.clear();
const ambientRuntime=createRuntime(),ambientApi=ambientRuntime.api;ambientApi.dismissStartMenu();
const ambientContract={frameCount:4,frameSize:256,premiumSpriteSheets:true,trueAnimationFrames:true,deterministicPlacement:true,surfaceMaxVisible:10,mineMaxVisible:6,rareSurfaceCrossings:true,reducedMotionSafe:true,roamingRoutes:true,mineRouteSampling:true,miningReactions:true,continuousReactions:true,restBehavior:true,collisionFree:true,gameplayNeutral:true,proceduralCreaturePrimitives:false};
let ambientSnapshot=ambientApi.snapshot(),ambientLife=ambientSnapshot.ambientLife;
assert.deepEqual(Object.fromEntries(Object.keys(ambientContract).map(key=>[key,ambientLife[key]])),ambientContract);
assert.equal(JSON.stringify(ambientLife.assets),JSON.stringify(ambientAssets));assert.equal(ambientLife.activeProfile,'mossvein');assert.equal(ambientLife.location,'surface');assert.equal(ambientLife.maxVisible,10);
assert.ok(ambientLife.visible.length>0&&ambientLife.visible.length<=10,'surface ambient life must stay visible and capped');assert.ok(ambientLife.visible.every(instance=>Object.values(ambientAssets).includes(instance.asset)&&instance.frame>=0&&instance.frame<4));
const surfaceResidentBefore=new Map(ambientLife.visible.filter(instance=>!instance.event).map(instance=>[instance.id,instance]));assert.ok([...surfaceResidentBefore.values()].every(instance=>pointDistance(instance.anchorX,instance.anchorY,instance.routeX,instance.routeY)>=60),'surface residents must have broad routes');
let surfaceMaxTravel=0,surfaceRestSeen=ambientLife.visible.some(instance=>instance.resting&&instance.frame===0&&(instance.routeProgress===0||instance.routeProgress===1));
for(let sample=0;sample<16;sample++){ambientApi.step(.5);ambientLife=ambientApi.snapshot().ambientLife;surfaceRestSeen||=ambientLife.visible.some(instance=>instance.resting&&instance.frame===0&&(instance.routeProgress===0||instance.routeProgress===1));for(const instance of ambientLife.visible)if(surfaceResidentBefore.has(instance.id))surfaceMaxTravel=Math.max(surfaceMaxTravel,pointDistance(instance.x,instance.y,surfaceResidentBefore.get(instance.id).x,surfaceResidentBefore.get(instance.id).y))}
assert.ok(surfaceMaxTravel>18,'surface residents must visibly travel between rests');assert.equal(surfaceRestSeen,true,'surface residents must stop on a route endpoint and rest');
assert.equal(Object.prototype.hasOwnProperty.call(ambientSnapshot.state,'ambientLife'),false,'ambient life must not leak into gameplay save state');
const gameplayStateBeforeAmbientRender=JSON.stringify(ambientSnapshot.state);ambientRuntime.drawCalls.length=0;ambientApi.renderOnce();
assert.equal(JSON.stringify(ambientApi.snapshot().state),gameplayStateBeforeAmbientRender,'renderOnce must not mutate gameplay state');
let ambientDrawCalls=ambientRuntime.drawCalls.filter(call=>call.src.includes('assets/ambient/'));assert.equal(ambientDrawCalls.length,ambientLife.visible.length,'renderOnce must draw exactly the visible ambient instances');
for(const call of ambientDrawCalls){assert.equal(call.args.length,8,'ambient sprites must use cropped nine-argument drawImage');assert.ok([0,256,512,768].includes(call.args[0]),'ambient sprite crop must select one of four frames');assert.deepEqual(call.args.slice(1,4),[0,256,256],'ambient sprite crop must stay within a 4x256 sheet')}
const ambientSignature=life=>life.visible.map(({id,profile,asset,anchorX,anchorY,routeX,routeY})=>({id,profile,asset,anchorX,anchorY,routeX,routeY}));ambientApi.save();
const ambientReloadRuntime=createRuntime(),ambientReloadApi=ambientReloadRuntime.api;assert.equal(JSON.stringify(ambientSignature(ambientReloadApi.snapshot().ambientLife)),JSON.stringify(ambientSignature(ambientSnapshot.ambientLife)),'ambient placement must be deterministic for a saved world seed');
const worldLifeSignature=life=>life.drift.map(({id,profile,asset,anchorX,anchorY,x,y,size})=>({id,profile,asset,anchorX,anchorY,x,y,size}));assert.equal(JSON.stringify(worldLifeSignature(ambientReloadApi.snapshot().worldLife)),JSON.stringify(worldLifeSignature(ambientSnapshot.worldLife)),'environmental drift placement must be deterministic for a saved world seed');
ambientApi.setReducedMotion(true);const reducedAmbientBefore=ambientApi.snapshot().ambientLife;ambientApi.step(2);const reducedAmbientAfter=ambientApi.snapshot().ambientLife;
assert.equal(reducedAmbientAfter.reducedMotion,true);assert.equal(reducedAmbientAfter.event.enabled,false);assert.equal(reducedAmbientAfter.event.active,false);
assert.ok(reducedAmbientAfter.visible.every(instance=>instance.frame===0&&instance.x===instance.anchorX&&instance.y===instance.anchorY),'reduced motion must freeze sprite frames and resident drift');
assert.equal(JSON.stringify(reducedAmbientAfter.visible.map(({id,x,y})=>({id,x,y}))),JSON.stringify(reducedAmbientBefore.visible.map(({id,x,y})=>({id,x,y}))),'reduced motion ambient placement must remain frozen across time');ambientApi.setReducedMotion(false);
ambientLife=ambientApi.snapshot().ambientLife;const surfaceReactionTarget=ambientLife.visible.find(instance=>!instance.event&&instance.profile===ambientLife.activeProfile);assert.ok(surfaceReactionTarget);ambientApi.setPosition(surfaceReactionTarget.x,surfaceReactionTarget.y);ambientApi.setSwingProgress(.2);ambientApi.step(.01);const surfaceReaction=ambientApi.snapshot().ambientLife.visible.find(instance=>instance.id===surfaceReactionTarget.id);assert.ok(surfaceReaction&&surfaceReaction.reacting&&surfaceReaction.behavior==='fleeing'&&surfaceReaction.reactionStrength>0,'nearby mining must startle a surface resident');ambientApi.clearSwing();ambientApi.setPosition(330,690);
ambientLife=ambientApi.snapshot().ambientLife;
for(let guard=0;!ambientLife.visible.some(instance=>instance.event)&&guard<100;guard++){ambientApi.step(ambientLife.event.active?.12:Math.min(2,ambientLife.event.nextIn+.01));ambientLife=ambientApi.snapshot().ambientLife}
assert.equal(ambientLife.event.active,true,'a deterministic rare surface crossing must become active within one event interval');assert.ok(ambientLife.visible.some(instance=>instance.event),'an active rare crossing must enter the viewport along its fixed world-space route');assert.ok(ambientLife.visible.length<=10,'rare crossings must respect the surface entity cap');
ambientApi.unlockAllAreas();ambientApi.unlockStarfall();
for(const [scene,profile] of Object.entries({mossMine:'mossvein',moonMine:'moonglass',emberMine:'emberdeep',starMine:'starfall'})){
  ambientApi.enterMine(scene);ambientLife=ambientApi.snapshot().ambientLife;
  assert.equal(ambientLife.location,scene+':1');assert.equal(ambientLife.activeProfile,profile);assert.equal(ambientLife.maxVisible,6);assert.ok(ambientLife.visible.length>0&&ambientLife.visible.length<=6,scene+' ambient life must stay visible and capped');
  assert.ok(ambientLife.visible.every(instance=>instance.profile===profile&&instance.asset===ambientAssets[profile]&&!ambientApi.mineCollisionAt(instance.x,instance.y)),scene+' ambient instances must stay in open, reachable cells');
  const mineResidentBefore=new Map(ambientLife.visible.map(instance=>[instance.id,instance]));assert.ok([...mineResidentBefore.values()].every(instance=>pointDistance(instance.anchorX,instance.anchorY,instance.routeX,instance.routeY)>=20),scene+' must provide real patrol routes');let maxMineTravel=0,mineRestSeen=ambientLife.visible.some(instance=>instance.resting&&instance.frame===0);
  for(let sample=0;sample<14;sample++){ambientApi.step(.45);const sampleLife=ambientApi.snapshot().ambientLife;mineRestSeen||=sampleLife.visible.some(instance=>instance.resting&&instance.frame===0&&(instance.routeProgress===0||instance.routeProgress===1));assert.ok(sampleLife.visible.every(instance=>!ambientApi.mineCollisionAt(instance.x,instance.y)),scene+' patrol samples must remain collision-free');for(const instance of sampleLife.visible)if(mineResidentBefore.has(instance.id))maxMineTravel=Math.max(maxMineTravel,pointDistance(instance.x,instance.y,mineResidentBefore.get(instance.id).x,mineResidentBefore.get(instance.id).y))}
  assert.ok(maxMineTravel>6,scene+' residents must visibly patrol between rests');assert.equal(mineRestSeen,true,scene+' residents must rest on safe endpoints');ambientLife=ambientApi.snapshot().ambientLife;
  for(const target of ambientLife.visible){ambientApi.setPosition(target.x,target.y);assert.ok(ambientApi.snapshot().ambientLife.visible.some(instance=>instance.id===target.id),scene+' residents must retain a render slot when approached')}
  ambientLife=ambientApi.snapshot().ambientLife;const mineReactionTarget=ambientLife.visible[0];ambientApi.setPosition(mineReactionTarget.x,mineReactionTarget.y);ambientApi.setSwingProgress(.2);ambientApi.step(.01);const mineReaction=ambientApi.snapshot().ambientLife.visible.find(instance=>instance.id===mineReactionTarget.id);assert.ok(mineReaction&&mineReaction.reacting&&mineReaction.behavior==='fleeing'&&!ambientApi.mineCollisionAt(mineReaction.x,mineReaction.y),scene+' residents must flee nearby mining without crossing a wall');ambientApi.step(.35);const fleeingBeforeRelease=ambientApi.snapshot().ambientLife.visible.find(instance=>instance.id===mineReactionTarget.id);ambientApi.clearSwing();ambientApi.step(.01);const recoveryStart=ambientApi.snapshot().ambientLife.visible.find(instance=>instance.id===mineReactionTarget.id);assert.ok(recoveryStart&&recoveryStart.behavior==='returning'&&pointDistance(recoveryStart.x,recoveryStart.y,fleeingBeforeRelease.x,fleeingBeforeRelease.y)<4,scene+' residents must enter recovery without teleporting');ambientApi.step(.3);const recoveryMotion=ambientApi.snapshot().ambientLife.visible.find(instance=>instance.id===mineReactionTarget.id);assert.ok(recoveryMotion&&recoveryMotion.behavior==='returning'&&!ambientApi.mineCollisionAt(recoveryMotion.x,recoveryMotion.y),scene+' residents must recover smoothly on their safe route');ambientApi.step(1.1);ambientLife=ambientApi.snapshot().ambientLife;
  ambientRuntime.drawCalls.length=0;ambientApi.renderOnce();ambientDrawCalls=ambientRuntime.drawCalls.filter(call=>call.src.includes('assets/ambient/'));assert.equal(ambientDrawCalls.length,ambientLife.visible.length);assert.ok(ambientDrawCalls.every(call=>call.src.includes(ambientAssets[profile])));ambientApi.exitMine();
}
ambientApi.enterMine('starMine');ambientApi.setDrillLevel(3);if(!ambientApi.snapshot().mine.depthEntrance.discovered)assert.equal(ambientApi.discoverDepthEntrance(),true);assert.equal(ambientApi.enterDepth(),true);ambientLife=ambientApi.snapshot().ambientLife;
assert.equal(ambientLife.location,'starMine:2');assert.ok(ambientLife.visible.length>0,'Voidstar must contain ambient residents');for(const target of ambientLife.visible){ambientApi.setPosition(target.x,target.y);assert.ok(ambientApi.snapshot().ambientLife.visible.some(instance=>instance.id===target.id),'Voidstar residents must not disappear when approached')}ambientApi.exitDepth();ambientApi.exitMine();

const worldLifeContract={frameCount:4,frameSize:256,spriteSheetWidth:1024,spriteSheetHeight:256,decodedMemoryBudgetBytes:12582912,premiumSpriteSheets:true,trueAnimationFrames:true,surfaceMaxVisible:4,mineMaxVisible:3,responseMaxVisible:6,worldAnchored:true,deterministicPlacement:true,biomeSpecific:true,footstepResponses:true,miningResponses:true,dedicatedImpactSheets:true,noCircularImpactSilhouettes:true,impactStacking:false,underMineLighting:true,reducedMotionSafe:true,gameplayNeutral:true,proceduralEffectPrimitives:false};
let worldLife=ambientApi.snapshot().worldLife;
assert.deepEqual(Object.fromEntries(Object.keys(worldLifeContract).map(key=>[key,worldLife[key]])),worldLifeContract);assert.equal(JSON.stringify(worldLife.assets),JSON.stringify(worldLifeAssets));assert.equal(worldLife.activeProfile,'mossvein');assert.equal(worldLife.location,'surface');assert.equal(worldLife.maxVisible,4);
assert.ok(worldLife.drift.length>0&&worldLife.drift.length<=4,'surface environmental drift must stay visible and capped');assert.ok(worldLife.drift.every(instance=>instance.asset===worldLifeAssets[instance.profile].drift&&instance.frame>=0&&instance.frame<4));assert.equal(worldLife.responses.length,0);
assert.equal(Object.prototype.hasOwnProperty.call(ambientApi.snapshot().state,'worldLife'),false,'world life must not leak into gameplay save state');
const worldStateBeforeRender=JSON.stringify(ambientApi.snapshot().state);ambientRuntime.drawCalls.length=0;ambientApi.renderOnce();assert.equal(JSON.stringify(ambientApi.snapshot().state),worldStateBeforeRender,'world-life rendering must not mutate gameplay state');
let worldLifeDrawCalls=ambientRuntime.drawCalls.filter(call=>call.src.includes('assets/world-life/'));assert.equal(worldLifeDrawCalls.length,worldLife.drift.length);for(const call of worldLifeDrawCalls){assert.equal(call.args.length,8,'world-life sprites must use cropped nine-argument drawImage');assert.ok([0,256,512,768].includes(call.args[0]));assert.deepEqual(call.args.slice(1,4),[0,256,256])}
ambientApi.setPosition(600,700);ambientApi.setMoveVector(1,0);for(let sample=0;sample<6;sample++)ambientApi.step(.05);ambientApi.stopMove();worldLife=ambientApi.snapshot().worldLife;assert.ok(worldLife.responses.some(response=>response.kind==='footstep'&&response.profile==='mossvein'&&response.asset===worldLifeAssets.mossvein.response),'walking must disturb the biome floor with premium ground art');
ambientApi.unlockAllAreas();ambientApi.setPickaxeLevel(5);ambientApi.setDrillLevel(3);ambientApi.enterMine('mossMine');worldLife=ambientApi.snapshot().worldLife;assert.equal(worldLife.location,'mossMine:1');assert.ok(worldLife.drift.length>0&&worldLife.drift.length<=3);assert.ok(worldLife.drift.every(instance=>instance.profile==='mossvein'&&!ambientApi.mineCollisionAt(instance.x,instance.y)),'mine drift must stay in open cells');
ambientApi.setPickaxeLevel(1);ambientApi.setDrillLevel(0);const responseDeposit=ambientApi.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.depositId&&rock.requiredPickaxe<=1&&!rock.requiresDeepTool&&!rock.requiresDrillLevel);assert.ok(responseDeposit);const hitResult=ambientApi.hitDepositRock(responseDeposit.depositId,0);assert.ok(hitResult);const hitResponseRock=ambientApi.snapshot().rocks.find(rock=>rock.id===hitResult.id);ambientApi.setPosition(hitResponseRock.x,hitResponseRock.y);ambientApi.hitDepositRock(responseDeposit.depositId,0);ambientApi.hitDepositRock(responseDeposit.depositId,0);worldLife=ambientApi.snapshot().worldLife;const mineResponses=worldLife.responses.filter(response=>response.kind==='mine'&&response.profile==='mossvein');assert.equal(mineResponses.length,1,'rapid drill hits must not stack impact sprites on one target');assert.equal(mineResponses[0].asset,worldLifeAssets.mossvein.impact,'mining must use the dedicated biome impact sheet');ambientApi.breakDepositRock(responseDeposit.depositId,0);worldLife=ambientApi.snapshot().worldLife;const breakResponses=worldLife.responses.filter(response=>response.kind==='break');assert.equal(breakResponses.length,1,'a break must replace the nearby hit response instead of stacking');assert.equal(breakResponses[0].asset,worldLifeAssets.mossvein.impact);
ambientApi.setReducedMotion(true);const reducedWorldBefore=ambientApi.snapshot().worldLife;ambientApi.step(2);const reducedWorldAfter=ambientApi.snapshot().worldLife;assert.equal(reducedWorldAfter.reducedMotion,true);assert.equal(reducedWorldAfter.responses.length,0);assert.ok(reducedWorldAfter.drift.every(instance=>instance.frame===0&&instance.x===instance.anchorX&&instance.y===instance.anchorY));assert.equal(JSON.stringify(reducedWorldAfter.drift.map(({id,x,y})=>({id,x,y}))),JSON.stringify(reducedWorldBefore.drift.map(({id,x,y})=>({id,x,y}))));ambientApi.setReducedMotion(false);ambientApi.exitMine();
storage.clear();for(const [key,value] of storageBeforeAmbient)storage.set(key,value);

const storageBeforeAchievements=new Map(storage),achievementRuntime=createRuntime(),achievementApi=achievementRuntime.api;
let achievementSnapshot=achievementApi.snapshot();
assert.equal(achievementSnapshot.achievements.storageKey,'everDeeperAchievementsV1');assert.equal(achievementSnapshot.achievements.total,50);assert.equal(achievementSnapshot.achievements.count,0);
assert.equal(JSON.stringify(achievementSnapshot.achievements.definitions.map(definition=>definition.id)),JSON.stringify(expectedAchievementIds));
assert.ok(achievementSnapshot.achievements.definitions.every(definition=>definition.asset==='assets/achievements/'+definition.id+'.png'&&definition.title&&definition.description&&definition.category&&definition.tier));
achievementApi.dismissStartMenu();achievementApi.grantMined('stone',1);assert.equal(JSON.stringify(achievementApi.evaluateAchievements()),JSON.stringify(['first_chip']));achievementSnapshot=achievementApi.snapshot();
assert.equal(achievementSnapshot.achievements.active,'first_chip');assert.equal(achievementSnapshot.achievements.settled,false);assert.equal(achievementSnapshot.achievements.popupVisible,true);assert.equal(JSON.stringify(achievementSnapshot.achievements.queue),JSON.stringify(['first_chip']));
const firstChipRecord=achievementSnapshot.achievements.records.first_chip;assert.equal(firstChipRecord.id,'first_chip');assert.equal(firstChipRecord.scene,'surface');assert.equal(firstChipRecord.depth,1);assert.equal(firstChipRecord.order,1);assert.equal(firstChipRecord.acknowledged,false);assert.ok(Number.isFinite(Date.parse(firstChipRecord.timestamp)));assert.match(firstChipRecord.reason,/first resource/i);
assert.equal(achievementApi.dismissAchievement(),false);assert.equal(achievementApi.snapshot().achievements.records.first_chip.acknowledged,false);assert.equal(achievementApi.settleAchievement(),true);assert.equal(achievementApi.snapshot().achievements.settled,true);
assert.equal(achievementApi.openAchievementPopup(),true);assert.equal(achievementApi.snapshot().achievements.records.first_chip.acknowledged,true);assert.equal(achievementApi.snapshot().achievements.highlighted,'first_chip');assert.equal(achievementRuntime.elements.get('menuShade').dataset.view,'achievements');assert.equal(achievementRuntime.elements.get('menuShade').hidden,false);assert.equal(achievementRuntime.elements.get('achievementList').dataset.highlightedAchievement,'first_chip');achievementRuntime.elements.get('menuCloseButton').dispatchEvent({type:'click'});
achievementApi.setPickaxeLevel(3);assert.equal(JSON.stringify(achievementApi.evaluateAchievements()),JSON.stringify(['ironbound','rune_ready']));achievementSnapshot=achievementApi.snapshot();
assert.equal(JSON.stringify(achievementSnapshot.achievements.queue),JSON.stringify(['ironbound','rune_ready']));assert.equal(achievementSnapshot.achievements.active,'ironbound');assert.equal(achievementSnapshot.achievements.settled,false);assert.equal(achievementSnapshot.achievements.records.ironbound.order,2);assert.equal(achievementSnapshot.achievements.records.rune_ready.order,3);
assert.equal(achievementApi.dismissAchievement(),false);assert.equal(achievementApi.settleAchievement(),true);assert.equal(achievementApi.dismissAchievement(),true);assert.equal(achievementApi.snapshot().achievements.active,'rune_ready');assert.equal(achievementApi.snapshot().achievements.settled,false);
achievementApi.openAchievements();assert.equal((achievementRuntime.elements.get('achievementList').innerHTML.match(/data-achievement=/g)||[]).length,50);assert.match(achievementRuntime.elements.get('achievementList').innerHTML,/EARNED/);
const persistedAchievementState=JSON.parse(storage.get('everDeeperAchievementsV1'));assert.equal(persistedAchievementState.records.first_chip.acknowledged,true);assert.equal(persistedAchievementState.records.rune_ready.acknowledged,false);

const achievementCatalogBody=source.match(/const ACHIEVEMENT_DEFINITIONS=Object\.freeze\(\[([\s\S]*?)\]\);\s*const ACHIEVEMENT_BY_ID=/);
assert.ok(achievementCatalogBody,'achievement predicates must remain statically testable');
const predicateDefinitions=vm.runInNewContext('['+achievementCatalogBody[1]+']',{
  achievementDefinition:(id,title,description,category,tier,predicate)=>({id,title,description,category,tier,predicate}),
  MINE_SCENES:['mossMine','moonMine','emberMine','starMine'],
  CHEST_DEFINITIONS:['moss_supply','moss_ironbound','moon_cache','moon_reliquary','ember_cache','ember_vault','star_cache','star_coffer'].map(id=>({id})),
  VEIN_DEFINITIONS:['copper_run','moonglass_bloom','ember_fault','starfall_lattice'].map(id=>({id})),
  ROCK_TYPES:Object.fromEntries(Object.keys(completeDropPaths).map(type=>[type,{}]))
});
const predicateById=new Map(predicateDefinitions.map(definition=>[definition.id,definition.predicate]));
function predicateFixture(){
  const mines={mossMine:false,moonMine:false,emberMine:false,starMine:false};
  return{
    state:{totalGold:0,totalSwings:0,precisionHits:0,areaUnlocked:false,emberdeepUnlocked:false,fourthUnlocked:false,discoveredSecond:false,discoveredThird:false,discoveredFourth:false,victory:false,pickaxeLevel:1,emberMastery:0,drillLevel:0,movementSpeedLevel:0,
      mined:Object.fromEntries(Object.keys(completeDropPaths).map(type=>[type,0])),discoveredMines:{...mines},discoveredDepthEntrances:{...mines},visitedDepths:{...mines},openedChests:{},veinsCompleted:{copper_run:0,moonglass_bloom:0,ember_fault:0,starfall_lattice:0},starforgeUnlocked:{crusher:false,swift:false,prospector:false},
      base:{forge:{scene:'surface',packed:false},sell:{scene:'surface',packed:false},chests:[{scene:'surface',packed:false}]}},
    metrics:{totalMined:0,tilesDug:0,depthMined:0,opened:0,veinTotal:0}
  };
}
const setEvery=(object,value)=>{for(const key of Object.keys(object))object[key]=value};
const achievementPredicateBoundaries=[
  ['first_chip',(s,m)=>m.totalMined=1],
  ['first_payday',s=>s.totalGold=1],
  ['moon_unsealed',s=>s.areaUnlocked=true],
  ['ember_unsealed',s=>s.emberdeepUnlocked=true],
  ['stars_unsealed',s=>s.fourthUnlocked=true],
  ['four_frontiers',s=>{s.discoveredSecond=s.discoveredThird=s.discoveredFourth=true},s=>{s.discoveredSecond=s.discoveredThird=true}],
  ['minewalker',s=>setEvery(s.discoveredMines,true),s=>{setEvery(s.discoveredMines,true);s.discoveredMines.starMine=false}],
  ['seasoned_arms',s=>s.totalSwings=100,s=>s.totalSwings=99],
  ['iron_rhythm',s=>s.totalSwings=1000,s=>s.totalSwings=999],
  ['keen_eye',s=>s.precisionHits=10,s=>s.precisionHits=9],
  ['true_aim',s=>s.precisionHits=100,s=>s.precisionHits=99],
  ['tunnel_hand',(s,m)=>m.tilesDug=100,(s,m)=>m.tilesDug=99],
  ['earth_eater',(s,m)=>m.tilesDug=1000,(s,m)=>m.tilesDug=999],
  ['ore_mountain',(s,m)=>m.totalMined=1000,(s,m)=>m.totalMined=999],
  ['goldspark',s=>s.mined.gold=1],
  ['fallen_star',s=>s.mined.starshard=1],
  ['sunstruck',s=>s.mined.sunslag=1],
  ['crowned',s=>s.mined.crownstone=1],
  ['into_the_deep',s=>s.mined.deepstone=1],
  ['three_hearts',s=>{s.mined.ambercore=s.mined.lunacore=s.mined.furnaceheart=1},s=>{s.mined.ambercore=s.mined.lunacore=1}],
  ['drillborn_ore',s=>{s.mined.burrowsteel=s.mined.phasecrystal=s.mined.infernium=1},s=>{s.mined.burrowsteel=s.mined.phasecrystal=1}],
  ['deep_hoard',(s,m)=>m.depthMined=500,(s,m)=>m.depthMined=499],
  ['ironbound',s=>s.pickaxeLevel=2],
  ['rune_ready',s=>s.pickaxeLevel=3,s=>s.pickaxeLevel=2],
  ['moonforged',s=>s.pickaxeLevel=4,s=>s.pickaxeLevel=3],
  ['emberforged',s=>s.pickaxeLevel=5,s=>s.pickaxeLevel=4],
  ['depth_master',s=>s.emberMastery=5,s=>s.emberMastery=4],
  ['starforged',s=>s.starforgeUnlocked.crusher=true],
  ['threefold_star',s=>setEvery(s.starforgeUnlocked,true),s=>{setEvery(s.starforgeUnlocked,true);s.starforgeUnlocked.prospector=false}],
  ['burrower',s=>s.drillLevel=1],
  ['pulse_driver',s=>s.drillLevel=2,s=>s.drillLevel=1],
  ['deepcore',s=>s.drillLevel=3,s=>s.drillLevel=2],
  ['moss_below',s=>s.discoveredMines.mossMine=true],
  ['glass_below',s=>s.discoveredMines.moonMine=true],
  ['fire_below',s=>s.discoveredMines.emberMine=true],
  ['stars_below',s=>s.discoveredMines.starMine=true],
  ['hidden_descent',s=>s.discoveredDepthEntrances.mossMine=true],
  ['every_depth',s=>setEvery(s.visitedDepths,true),s=>{setEvery(s.visitedDepths,true);s.visitedDepths.starMine=false}],
  ['treasure_found',(s,m)=>m.opened=1],
  ['cache_hunter',(s,m)=>m.opened=4,(s,m)=>m.opened=3],
  ['chestmaster',s=>{for(const id of ['moss_supply','moss_ironbound','moon_cache','moon_reliquary','ember_cache','ember_vault','star_cache','star_coffer'])s.openedChests[id]=true},s=>{for(const id of ['moss_supply','moss_ironbound','moon_cache','moon_reliquary','ember_cache','ember_vault','star_cache'])s.openedChests[id]=true}],
  ['vein_runner',(s,m)=>m.veinTotal=1],
  ['fourfold_veins',s=>{for(const id of Object.keys(s.veinsCompleted))s.veinsCompleted[id]=1},s=>{for(const id of ['copper_run','moonglass_bloom','ember_fault'])s.veinsCompleted[id]=1}],
  ['vein_veteran',(s,m)=>m.veinTotal=10,(s,m)=>m.veinTotal=9],
  ['quick_step',s=>s.movementSpeedLevel=1],
  ['roadrunner',s=>s.movementSpeedLevel=10,s=>s.movementSpeedLevel=9],
  ['more_storage',s=>s.base.chests.push({scene:'surface',packed:true})],
  ['mobile_base',s=>s.base.forge.scene='mossMine'],
  ['mineral_crown',s=>setEvery(s.mined,1),s=>{setEvery(s.mined,1);s.mined.infernium=0}],
  ['ever_deeper',s=>s.victory=true]
];
assert.equal(achievementPredicateBoundaries.length,50);assert.deepEqual(achievementPredicateBoundaries.map(([id])=>id),expectedAchievementIds);
for(const [id,crossBoundary,approachBoundary] of achievementPredicateBoundaries){
  const predicate=predicateById.get(id);assert.equal(typeof predicate,'function',id+' predicate must exist');
  const below=predicateFixture();if(approachBoundary)approachBoundary(below.state,below.metrics);assert.equal(Boolean(predicate(below.state,below.metrics)),false,id+' must stay locked below its boundary');
  const atBoundary=predicateFixture();crossBoundary(atBoundary.state,atBoundary.metrics);assert.equal(Boolean(predicate(atBoundary.state,atBoundary.metrics)),true,id+' must unlock at its boundary');
}

const existingExpedition=achievementApi.snapshot().state;storage.clear();storage.set('everDeeperPrototypeV2',JSON.stringify(existingExpedition));const backfillSnapshot=createRuntime().api.snapshot();
assert.equal(backfillSnapshot.achievements.count,3);assert.equal(JSON.stringify(backfillSnapshot.achievements.queue),JSON.stringify([]));assert.equal(backfillSnapshot.achievements.active,null);assert.ok(['first_chip','ironbound','rune_ready'].every(id=>{const record=backfillSnapshot.achievements.records[id];return record.acknowledged&&record.retroactive&&record.scene===null&&record.depth===null}));
assert.equal(achievementApi.resetAll(),true);assert.equal(achievementApi.snapshot().achievements.count,0);assert.equal(achievementApi.snapshot().achievements.active,null);assert.equal(achievementApi.snapshot().state.pickaxeLevel,1);assert.equal(achievementApi.snapshot().state.mined.stone,0);assert.deepEqual(JSON.parse(storage.get('everDeeperAchievementsV1')).records,{});
storage.clear();for(const [key,value] of storageBeforeAchievements)storage.set(key,value);

const storageBeforeMoonglassRendering=new Map(storage),productionRuntime=createRuntime(),productionApi=productionRuntime.api;
productionApi.reset();
const surfaceRoadRocks=productionApi.snapshot().rocks.filter(rock=>rock.scene==='surface');
assert.equal(surfaceRoadRocks.some(rock=>rock.y>=620&&rock.y<=830),false,'main road must remain clear of resource nodes');
assert.equal(surfaceRoadRocks.some(rock=>rock.x>=100&&rock.x<=825&&rock.y>=730&&rock.y<=960),false,'Mossvein branch road must remain clear of resource nodes');
assert.equal(surfaceRoadRocks.some(rock=>Math.hypot(rock.x-1450,rock.y-850)<125),false,'Moonglass entrance must remain clear of resource nodes');
assert.equal(JSON.stringify(surfaceRoadRocks.filter(rock=>rock.veinId==='moonglass_bloom').map(rock=>[rock.x,rock.y])),JSON.stringify([[1593,504],[1665,504],[1742,504]]),'Moonglass Bloom nodes must align with the three platform sockets');
renderAt(productionRuntime,productionApi,180,830,['assets/surface/mossvein-mine-path.png','assets/surface/road-mossvein.png','assets/entrances/mossvein-entrance.png']);
renderAt(productionRuntime,productionApi,1500,720,['assets/surface/road-moonglass.png']);
renderAt(productionRuntime,productionApi,2600,720,['assets/surface/road-emberdeep.png']);
renderAt(productionRuntime,productionApi,3700,720,['assets/surface/road-starfall.png']);
renderAt(productionRuntime,productionApi,2175,650,['assets/surface/moonglass-ground.png','assets/surface/emberdeep-seal.png']);
productionApi.startMoonglassGateTransition();
renderAt(productionRuntime,productionApi,1110,650,['assets/surface/moonglass-gate.png','assets/surface/moonglass-gate-mark.png']);
assert.equal(JSON.stringify(productionApi.snapshot().moonglassGateTransition),JSON.stringify({active:true,progress:0}));
assert.equal(productionApi.snapshot().surfaceBoundaries.walls.find(boundary=>boundary.unlockKey==='areaUnlocked').locked,true,'the passage must stay locked while the gate is moving');
productionApi.step(1.75);
renderAt(productionRuntime,productionApi,1110,650,['assets/surface/moonglass-gate.png','assets/surface/moonglass-gate-mark.png','assets/entrances/moonglass-entrance.png']);
assert.ok(productionApi.snapshot().moonglassGateTransition.progress>.5&&productionApi.snapshot().moonglassGateTransition.progress<1);
productionApi.step(1.2);
renderAt(productionRuntime,productionApi,1110,650,['assets/surface/moonglass-gate-mark.png','assets/entrances/moonglass-entrance.png']);
assert.equal(JSON.stringify(productionApi.snapshot().moonglassGateTransition),JSON.stringify({active:false,progress:1}));
assert.equal(productionApi.snapshot().surfaceBoundaries.walls.find(boundary=>boundary.unlockKey==='areaUnlocked').locked,false,'the passage must open after the gate is fully sunk');
assert.ok(!productionRuntime.drawCalls.some(call=>call.src.includes('assets/surface/moonglass-gate.png')),'the sunk Moonglass gate must leave only its ground mark');
assert.equal(productionRuntime.drawCalls.find(call=>call.src.includes('assets/surface/moonglass-gate-mark.png')).args.at(-2),300,'opened gate mark must fill the premium passage');
productionApi.unlockAllAreas();productionApi.setPickaxeLevel(4);
renderAt(productionRuntime,productionApi,1450,850,['assets/surface/moonglass-ground.png','assets/surface/moonglass-crystals.png','assets/surface/moonglass-gate-mark.png','assets/entrances/moonglass-entrance.png']);
assert.ok(!productionRuntime.drawCalls.some(call=>call.src.includes('assets/surface/moonglass-gate.png')),'opened Moonglass boundary gate must disappear');
renderAt(productionRuntime,productionApi,1665,500,['assets/surface/moonglass-ground.png','assets/surface/moonglass-bloom-bed.png']);
renderAt(productionRuntime,productionApi,2175,650,['assets/surface/moonglass-ground.png']);
assert.ok(!productionRuntime.drawCalls.some(call=>call.src.includes('assets/surface/emberdeep-seal.png')),'opened Emberdeep boundary gate must disappear');
renderAt(productionRuntime,productionApi,1285,1110,['assets/surface/crystal-cache-closed.png']);productionApi.openChest('moon_cache');renderAt(productionRuntime,productionApi,1285,1110,['assets/surface/crystal-cache-open.png']);
renderAt(productionRuntime,productionApi,2070,215,['assets/surface/moonglass-reliquary-closed.png']);productionApi.openChest('moon_reliquary');renderAt(productionRuntime,productionApi,2070,215,['assets/surface/moonglass-reliquary-open.png']);
productionApi.spawnGroundDrops('moonglass',1,1285,1110);productionApi.spawnGroundDrops('starshard',1,1285,1110);renderAt(productionRuntime,productionApi,1285,1110,['assets/drops/moonglass-drop.png','assets/drops/starshard-drop.png']);productionApi.forceGlobalLootSweep();

productionApi.setStarforgeVariant('swift');productionApi.enterMine('moonMine');
assert.equal(productionApi.snapshot().mine.visualPass,'moonglass-production-assets-v1');
renderAt(productionRuntime,productionApi,150,1180,['assets/moonglass/floor.png','assets/entrances/moonglass-entrance.png']);
renderAt(productionRuntime,productionApi,535,690,['assets/moonglass/floor.png','assets/moonglass/wall.png','assets/moonglass/route-marker.png','assets/moonglass/prismatic-fault.png','assets/moonglass/moonglass-node.png']);
renderAt(productionRuntime,productionApi,1055,500,['assets/moonglass/starbound-geode.png']);
let productionSnapshot=productionApi.snapshot(),buriedMoonglass=productionSnapshot.rocks.find(rock=>rock.scene==='moonMine'&&rock.depth===1&&rock.type==='moonglass'&&rock.depositId&&!rock.cavernId&&!rock.exposed);
assert.ok(buriedMoonglass);const moonCols=Math.ceil(productionSnapshot.mine.width/productionSnapshot.mine.terrain.tileSize),moonIndex=terrainIndexForRock(productionSnapshot,buriedMoonglass);
for(const neighbor of [moonIndex-1,moonIndex+1,moonIndex-moonCols,moonIndex+moonCols]){productionApi.mineTerrainCell(neighbor);if(productionApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedMoonglass.id))break}
assert.ok(productionApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedMoonglass.id));renderAt(productionRuntime,productionApi,buriedMoonglass.x,buriedMoonglass.y,['assets/moonglass/moonglass-wall.png']);
exposeRock(productionApi,buriedMoonglass);renderAt(productionRuntime,productionApi,buriedMoonglass.x,buriedMoonglass.y,['assets/moonglass/moonglass-node.png']);
const moonCacheCavern=productionApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');productionApi.mineTerrainCell(moonCacheCavern.boundaryIndex);renderAt(productionRuntime,productionApi,moonCacheCavern.x,moonCacheCavern.y,['assets/moonglass/crystal-pocket.png','assets/moonglass/buried-cache.png']);
const moonShrineCavern=productionApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='shrine');productionApi.mineTerrainCell(moonShrineCavern.boundaryIndex);renderAt(productionRuntime,productionApi,moonShrineCavern.x,moonShrineCavern.y,['assets/moonglass/crystal-pocket.png','assets/moonglass/mining-rush-shrine.png']);

assert.equal(productionApi.discoverDepthEntrance(),true);assert.equal(productionApi.enterDepth(),true);productionApi.setDrillLevel(2);productionSnapshot=productionApi.snapshot();
assert.equal(productionSnapshot.mine.visualPass,'prismatic-production-assets-v1');
assert.equal(JSON.stringify(productionSnapshot.mine.depthResources),JSON.stringify({main:'prismite',secondary:'deepstone',rare:'lunacore'}));
assert.ok(productionSnapshot.mine.discovery.deposits.some(deposit=>deposit.type==='phasecrystal'&&deposit.drillGated&&deposit.requiresDrillLevel===2));
renderAt(productionRuntime,productionApi,productionSnapshot.mine.depthEntrance.x,productionSnapshot.mine.depthEntrance.y,['assets/prismatic/floor.png','assets/prismatic/wall.png','assets/prismatic/depth-portal.png','assets/prismatic/sell-station.png','assets/prismatic/drill-forge.png']);
const buriedPrismite=productionSnapshot.rocks.find(rock=>rock.scene==='moonMine'&&rock.depth===2&&rock.type==='prismite'&&rock.depositId&&!rock.cavernId&&!rock.exposed),prismaticCols=Math.ceil(productionSnapshot.mine.width/productionSnapshot.mine.terrain.tileSize),prismiteIndex=terrainIndexForRock(productionSnapshot,buriedPrismite);
for(const neighbor of [prismiteIndex-1,prismiteIndex+1,prismiteIndex-prismaticCols,prismiteIndex+prismaticCols]){productionApi.mineTerrainCell(neighbor);productionApi.mineTerrainCell(neighbor);if(productionApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedPrismite.id))break}
assert.ok(productionApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedPrismite.id));renderAt(productionRuntime,productionApi,buriedPrismite.x,buriedPrismite.y,['assets/prismatic/prismite-wall.png']);
for(const [type,path] of [['prismite','assets/prismatic/prismite-node.png'],['deepstone','assets/rootwound/deepstone-node.png'],['lunacore','assets/prismatic/lunacore-node.png'],['phasecrystal','assets/prismatic/phasecrystal-node.png']]){const rock=productionApi.snapshot().rocks.find(item=>item.scene==='moonMine'&&item.depth===2&&item.type===type&&item.depositId&&!item.cavernId&&!item.broken);assert.ok(rock,type+' production node is missing');exposeRock(productionApi,rock);renderAt(productionRuntime,productionApi,rock.x,rock.y,[path])}
const prismaticCache=productionApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');productionApi.mineTerrainCell(prismaticCache.boundaryIndex);productionApi.mineTerrainCell(prismaticCache.boundaryIndex);renderAt(productionRuntime,productionApi,prismaticCache.x,prismaticCache.y,['assets/prismatic/crystal-pocket.png','assets/prismatic/buried-cache.png']);
const prismaticShrine=productionApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='shrine');productionApi.mineTerrainCell(prismaticShrine.boundaryIndex);productionApi.mineTerrainCell(prismaticShrine.boundaryIndex);renderAt(productionRuntime,productionApi,prismaticShrine.x,prismaticShrine.y,['assets/prismatic/crystal-pocket.png','assets/prismatic/mining-rush-shrine.png']);
for(const type of ['deepstone','prismite','lunacore','phasecrystal'])productionApi.spawnGroundDrops(type,1,productionApi.snapshot().player.x,productionApi.snapshot().player.y);productionRuntime.drawCalls.length=0;productionApi.renderOnce();assertRendered(productionRuntime.drawCalls,['assets/drops/deepstone-drop.png','assets/drops/prismite-drop.png','assets/drops/lunacore-drop.png','assets/drops/phasecrystal-drop.png']);
storage.clear();for(const [key,value] of storageBeforeMoonglassRendering)storage.set(key,value);

const storageBeforeEmberdeepRendering=new Map(storage),emberRuntime=createRuntime(),emberApi=emberRuntime.api;
emberApi.reset();let emberSnapshot=emberApi.snapshot(),emberSurfaceRocks=emberSnapshot.rocks.filter(rock=>rock.scene==='surface');
assert.equal(emberSurfaceRocks.some(rock=>Math.hypot(rock.x-2480,rock.y-970)<150),false,'Emberdeep entrance must remain clear of resource nodes');
assert.equal(emberSurfaceRocks.some(rock=>rock.x>=2380&&rock.x<=2940&&rock.y>=820&&rock.y<=1050),false,'Emberdeep approach path must remain clear of resource nodes');
assert.equal(JSON.stringify(emberSurfaceRocks.filter(rock=>rock.veinId==='ember_fault').map(rock=>[rock.x,rock.y])),JSON.stringify([[2978,900],[3078,900],[3176,900]]),'Ember Fault nodes must align with the three platform sockets');
renderAt(emberRuntime,emberApi,2175,650,['assets/surface/moonglass-ground.png','assets/surface/emberdeep-ground.png','assets/surface/emberdeep-seal.png']);
emberApi.startEmberdeepGateTransition();renderAt(emberRuntime,emberApi,2240,650,['assets/surface/emberdeep-seal.png','assets/surface/emberdeep-seal-mark.png']);
assert.equal(JSON.stringify(emberApi.snapshot().emberdeepGateTransition),JSON.stringify({active:true,progress:0}));emberApi.step(1.75);
renderAt(emberRuntime,emberApi,2360,780,['assets/surface/emberdeep-seal.png','assets/surface/emberdeep-seal-mark.png','assets/entrances/emberdeep-entrance.png']);
assert.ok(emberApi.snapshot().emberdeepGateTransition.progress>.5&&emberApi.snapshot().emberdeepGateTransition.progress<1);emberApi.step(.8);
renderAt(emberRuntime,emberApi,2360,780,['assets/surface/emberdeep-seal-mark.png','assets/entrances/emberdeep-entrance.png']);
assert.equal(JSON.stringify(emberApi.snapshot().emberdeepGateTransition),JSON.stringify({active:false,progress:1}));assert.ok(!emberRuntime.drawCalls.some(call=>call.src.includes('assets/surface/emberdeep-seal.png')),'the sunk Emberdeep seal must leave only its forge mark');
assert.equal(emberRuntime.drawCalls.find(call=>call.src.includes('assets/surface/emberdeep-seal-mark.png')).args.at(-2),300,'opened Emberdeep mark must fill the premium passage');
emberApi.setPickaxeLevel(5);renderAt(emberRuntime,emberApi,2480,970,['assets/surface/emberdeep-ground.png','assets/surface/emberdeep-mine-path.png','assets/entrances/emberdeep-entrance.png']);
renderAt(emberRuntime,emberApi,3078,900,['assets/surface/emberdeep-fault-bed.png','assets/emberdeep/emberstone-node.png']);
renderAt(emberRuntime,emberApi,2720,1160,['assets/surface/foundry-lockbox-closed.png']);emberApi.openChest('ember_cache');renderAt(emberRuntime,emberApi,2720,1160,['assets/surface/foundry-lockbox-open.png']);
renderAt(emberRuntime,emberApi,3250,205,['assets/surface/ember-vault-closed.png']);emberApi.openChest('ember_vault');renderAt(emberRuntime,emberApi,3250,205,['assets/surface/ember-vault-open.png']);
for(const type of ['emberstone','sunslag'])emberApi.spawnGroundDrops(type,1,2480,970);renderAt(emberRuntime,emberApi,2480,970,['assets/drops/emberstone-drop.png','assets/drops/sunslag-drop.png']);emberApi.forceGlobalLootSweep();

emberApi.enterMine('emberMine');emberSnapshot=emberApi.snapshot();assert.equal(emberSnapshot.mine.visualPass,'emberdeep-production-assets-v1');
renderAt(emberRuntime,emberApi,145,1030,['assets/emberdeep/floor.png','assets/entrances/emberdeep-entrance.png']);
renderAt(emberRuntime,emberApi,555,625,['assets/emberdeep/floor.png','assets/emberdeep/wall.png','assets/emberdeep/route-marker.png','assets/emberdeep/cinder-bulkhead.png','assets/emberdeep/emberstone-node.png']);
renderAt(emberRuntime,emberApi,1265,450,['assets/emberdeep/crucible-seal.png']);
let buriedEmber=emberApi.snapshot().rocks.find(rock=>rock.scene==='emberMine'&&rock.depth===1&&rock.type==='emberstone'&&rock.depositId&&!rock.cavernId&&!rock.exposed);assert.ok(buriedEmber);const emberCols=Math.ceil(emberSnapshot.mine.width/emberSnapshot.mine.terrain.tileSize),emberIndex=terrainIndexForRock(emberSnapshot,buriedEmber);
for(const neighbor of [emberIndex-1,emberIndex+1,emberIndex-emberCols,emberIndex+emberCols]){for(let hit=0;hit<4;hit++)emberApi.mineTerrainCell(neighbor);if(emberApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedEmber.id))break}assert.ok(emberApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedEmber.id));renderAt(emberRuntime,emberApi,buriedEmber.x,buriedEmber.y,['assets/emberdeep/emberstone-wall.png']);let emberNaturalLight=emberApi.snapshot().lighting.sources.find(source=>source.kind==='wallOre');assert.ok(emberNaturalLight);assert.ok(emberNaturalLight.intensity>=emberApi.snapshot().lighting.hierarchy.wallOre);exposeRock(emberApi,buriedEmber);renderAt(emberRuntime,emberApi,buriedEmber.x,buriedEmber.y,['assets/emberdeep/emberstone-node.png']);emberNaturalLight=emberApi.snapshot().lighting.sources.find(source=>source.kind==='rockOre');assert.ok(emberNaturalLight);
const emberCacheCavern=emberApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');emberApi.mineTerrainCell(emberCacheCavern.boundaryIndex);renderAt(emberRuntime,emberApi,emberCacheCavern.x,emberCacheCavern.y,['assets/emberdeep/crystal-pocket.png','assets/emberdeep/buried-cache.png']);
const emberShrineCavern=emberApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='shrine');emberApi.mineTerrainCell(emberShrineCavern.boundaryIndex);renderAt(emberRuntime,emberApi,emberShrineCavern.x,emberShrineCavern.y,['assets/emberdeep/crystal-pocket.png','assets/emberdeep/mining-rush-shrine.png']);
assert.equal(emberApi.discoverDepthEntrance(),true);assert.equal(emberApi.enterDepth(),true);emberApi.setDrillLevel(2);emberSnapshot=emberApi.snapshot();assert.equal(emberSnapshot.mine.visualPass,'molten-production-assets-v1');assert.equal(JSON.stringify(emberSnapshot.mine.depthResources),JSON.stringify({main:'magmaite',secondary:'deepstone',rare:'furnaceheart'}));assert.ok(emberSnapshot.mine.discovery.deposits.some(deposit=>deposit.type==='infernium'&&deposit.drillGated&&deposit.requiresDrillLevel===2));
renderAt(emberRuntime,emberApi,emberSnapshot.mine.depthEntrance.x,emberSnapshot.mine.depthEntrance.y,['assets/molten/floor.png','assets/molten/wall.png','assets/molten/depth-portal.png','assets/molten/sell-station.png','assets/molten/drill-forge.png']);const moltenLamp=emberApi.snapshot().lighting.sources.find(source=>source.kind==='depthLamp');assert.ok(moltenLamp);assert.equal(moltenLamp.intensity,emberApi.snapshot().lighting.hierarchy.depthLamp);assert.equal(moltenLamp.worldX,emberSnapshot.mine.depthEntrance.x+29);assert.equal(moltenLamp.worldY,emberSnapshot.mine.depthEntrance.y-57);
for(const [type,path] of [['magmaite','assets/molten/magmaite-node.png'],['deepstone','assets/molten/deepstone-node.png'],['furnaceheart','assets/molten/furnaceheart-node.png'],['infernium','assets/molten/infernium-node.png']]){const rock=emberApi.snapshot().rocks.find(item=>item.scene==='emberMine'&&item.depth===2&&item.type===type&&item.depositId&&!item.cavernId&&!item.broken);assert.ok(rock,type+' production node is missing');exposeRock(emberApi,rock);renderAt(emberRuntime,emberApi,rock.x,rock.y,[path])}
const moltenRareLight=emberApi.snapshot().lighting.sources.find(source=>source.kind==='rareRockOre'||source.kind==='rockOre');assert.ok(moltenRareLight);const moltenBenchmarkStarted=process.hrtime.bigint();for(let frame=0;frame<90;frame++)emberApi.renderOnce();const moltenAverageMs=Number(process.hrtime.bigint()-moltenBenchmarkStarted)/1e6/90;assert.ok(moltenAverageMs<16.7,'Molten lighting render budget exceeded: '+moltenAverageMs.toFixed(2)+'ms');
for(const type of ['deepstone','magmaite','furnaceheart','infernium'])emberApi.spawnGroundDrops(type,1,emberApi.snapshot().player.x,emberApi.snapshot().player.y);emberRuntime.drawCalls.length=0;emberApi.renderOnce();assertRendered(emberRuntime.drawCalls,['assets/drops/deepstone-drop.png','assets/drops/magmaite-drop.png','assets/drops/furnaceheart-drop.png','assets/drops/infernium-drop.png']);
emberApi.clearMineBarrier('ember_bulkhead');emberApi.save();const emberReload=createRuntime().api;assert.equal(emberReload.snapshot().state.clearedMineBarriers.ember_bulkhead,true);assert.equal(emberReload.snapshot().state.emberdeepUnlocked,true);assert.equal(emberReload.snapshot().surfaceEmberdeepRendering.gateMark,'assets/surface/emberdeep-seal-mark.png');
for(const seed of [2481359640,1044298914]){
  storage.clear();storage.set('everDeeperPrototypeV2',JSON.stringify({worldSeed:seed}));const seededApi=createRuntime().api;seededApi.unlockAllAreas();seededApi.enterMine('emberMine');let seededSnapshot=seededApi.snapshot(),entrance=seededSnapshot.mine.depthEntrance;
  for(const rock of seededSnapshot.rocks.filter(item=>item.scene==='emberMine'&&item.depth===1&&!item.barrierId))assert.ok(Math.hypot(rock.x-entrance.x,rock.y-entrance.y)>=entrance.resourceClearance,'Depth 1 portal overlaps '+rock.type+' for seed '+seed);
  seededApi.discoverDepthEntrance();seededApi.enterDepth();seededSnapshot=seededApi.snapshot();entrance=seededSnapshot.mine.depthEntrance;const stations=seededSnapshot.mine.depthStations;
  for(const rock of seededSnapshot.rocks.filter(item=>item.scene==='emberMine'&&item.depth===2)){
    assert.ok(Math.hypot(rock.x-entrance.x,rock.y-entrance.y)>=entrance.resourceClearance,'Molten portal overlaps '+rock.type+' for seed '+seed);
    for(const station of [stations.sell,stations.forge])assert.ok(Math.hypot(rock.x-station.x,rock.y-station.y)>=stations.resourceClearance,'Molten station overlaps '+rock.type+' for seed '+seed);
  }
}
storage.clear();for(const [key,value] of storageBeforeEmberdeepRendering)storage.set(key,value);

const storageBeforeStarfallRendering=new Map(storage),starfallRuntime=createRuntime(),starfallApi=starfallRuntime.api;
starfallApi.reset();let starfallSnapshot=starfallApi.snapshot(),starfallSurfaceRocks=starfallSnapshot.rocks.filter(rock=>rock.scene==='surface');
assert.equal(starfallSurfaceRocks.some(rock=>Math.hypot(rock.x-3505,rock.y-1000)<150),false,'Starfall entrance must remain clear of resource nodes');
assert.ok(starfallSurfaceRocks.some(rock=>rock.type==='astralite'&&!rock.veinId&&rock.x===4100&&rock.y===560),'the relocated Astralite node must stay clear of the cave branch and lattice');
assert.equal(JSON.stringify(starfallSurfaceRocks.filter(rock=>rock.veinId==='starfall_lattice').map(rock=>[rock.x,rock.y])),JSON.stringify([[3720,880],[3810,930],[3900,890]]),'Starfall Lattice nodes must align with the three astral sockets');
starfallApi.startStarfallGateTransition();renderAt(starfallRuntime,starfallApi,3360,650,['assets/surface/starfall-seal.png','assets/surface/starfall-seal-mark.png']);
assert.equal(JSON.stringify(starfallApi.snapshot().starfallGateTransition),JSON.stringify({active:true,progress:0}));starfallApi.step(1.75);
renderAt(starfallRuntime,starfallApi,3440,780,['assets/surface/starfall-seal.png','assets/surface/starfall-seal-mark.png','assets/entrances/starfall-entrance.png']);
assert.ok(starfallApi.snapshot().starfallGateTransition.progress>.5&&starfallApi.snapshot().starfallGateTransition.progress<1);starfallApi.step(.8);
renderAt(starfallRuntime,starfallApi,3505,1000,['assets/surface/starfall-seal-mark.png','assets/surface/starfall-ground.png','assets/surface/starfall-mine-path.png','assets/entrances/starfall-entrance.png']);
assert.equal(JSON.stringify(starfallApi.snapshot().starfallGateTransition),JSON.stringify({active:false,progress:1}));assert.ok(!starfallRuntime.drawCalls.some(call=>call.src.includes('assets/surface/starfall-seal.png')),'the sunk Starfall seal must leave only its astral mark');
assert.equal(starfallRuntime.drawCalls.find(call=>call.src.includes('assets/surface/starfall-seal-mark.png')).args.at(-2),300,'opened Starfall mark must fill the premium passage');
renderAt(starfallRuntime,starfallApi,3810,930,['assets/surface/starfall-ground.png','assets/surface/starfall-lattice-bed.png','assets/starfall/astralite-node.png']);
renderAt(starfallRuntime,starfallApi,3505,155,['assets/surface/starforge-station.png']);
starfallSnapshot=starfallApi.snapshot();const astralCache=starfallSnapshot.chests.find(chest=>chest.id==='star_cache'),celestialCoffer=starfallSnapshot.chests.find(chest=>chest.id==='star_coffer');
starfallApi.setPickaxeLevel(5);
renderAt(starfallRuntime,starfallApi,astralCache.x,astralCache.y,['assets/surface/astral-cache-closed.png']);starfallApi.openChest('star_cache');renderAt(starfallRuntime,starfallApi,astralCache.x,astralCache.y,['assets/surface/astral-cache-open.png']);
starfallApi.setStarforgeVariant('crusher');renderAt(starfallRuntime,starfallApi,celestialCoffer.x,celestialCoffer.y,['assets/surface/celestial-coffer-closed.png']);starfallApi.openChest('star_coffer');renderAt(starfallRuntime,starfallApi,celestialCoffer.x,celestialCoffer.y,['assets/surface/celestial-coffer-open.png']);

starfallApi.enterMine('starMine');starfallSnapshot=starfallApi.snapshot();assert.equal(starfallSnapshot.mine.visualPass,'starfall-production-assets-v1');
renderAt(starfallRuntime,starfallApi,160,750,['assets/starfall/floor.png','assets/entrances/starfall-entrance.png']);
renderAt(starfallRuntime,starfallApi,900,725,['assets/starfall/floor.png','assets/starfall/wall.png','assets/starfall/route-marker.png','assets/starfall/astral-bridge-lock.png','assets/starfall/astralite-node.png']);
renderAt(starfallRuntime,starfallApi,1650,460,['assets/starfall/crownstone-ward.png']);
let buriedAstralite=starfallSnapshot.rocks.find(rock=>rock.scene==='starMine'&&rock.depth===1&&rock.type==='astralite'&&rock.depositId&&!rock.cavernId&&!rock.exposed);assert.ok(buriedAstralite);const starfallCols=Math.ceil(starfallSnapshot.mine.width/starfallSnapshot.mine.terrain.tileSize),astraliteIndex=terrainIndexForRock(starfallSnapshot,buriedAstralite);
for(const neighbor of [astraliteIndex-1,astraliteIndex+1,astraliteIndex-starfallCols,astraliteIndex+starfallCols]){for(let hit=0;hit<4;hit++)starfallApi.mineTerrainCell(neighbor);if(starfallApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedAstralite.id))break}assert.ok(starfallApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedAstralite.id));renderAt(starfallRuntime,starfallApi,buriedAstralite.x,buriedAstralite.y,['assets/starfall/astralite-wall.png']);exposeRock(starfallApi,buriedAstralite);renderAt(starfallRuntime,starfallApi,buriedAstralite.x,buriedAstralite.y,['assets/starfall/astralite-node.png']);
const starfallCache=starfallApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');starfallApi.mineTerrainCell(starfallCache.boundaryIndex);renderAt(starfallRuntime,starfallApi,starfallCache.x,starfallCache.y,['assets/starfall/crystal-pocket.png','assets/starfall/buried-cache.png']);
const starfallShrine=starfallApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='shrine');starfallApi.mineTerrainCell(starfallShrine.boundaryIndex);renderAt(starfallRuntime,starfallApi,starfallShrine.x,starfallShrine.y,['assets/starfall/crystal-pocket.png','assets/starfall/mining-rush-shrine.png']);

assert.equal(starfallApi.discoverDepthEntrance(),true);starfallApi.setDrillLevel(2);starfallSnapshot=starfallApi.snapshot();starfallApi.setPosition(starfallSnapshot.mine.depthEntrance.x,starfallSnapshot.mine.depthEntrance.y);starfallApi.step(.05);
assert.equal(starfallRuntime.elements.get('contextTitle').textContent,'Voidstar Depths');assert.equal(starfallRuntime.elements.get('contextButton').disabled,true);assert.equal(starfallRuntime.elements.get('contextButton').textContent,'DEEPCORE DRILL REQUIRED');assert.match(starfallRuntime.elements.get('objectiveText').textContent,/Deepcore/i);assert.equal(starfallApi.enterDepth(),false);assert.equal(starfallApi.snapshot().depth,1);
starfallApi.setDrillLevel(3);assert.equal(starfallApi.enterDepth(),true);starfallSnapshot=starfallApi.snapshot();assert.equal(starfallSnapshot.mine.visualPass,'voidstar-production-assets-v1');assert.equal(JSON.stringify(starfallSnapshot.mine.depthResources),JSON.stringify({main:'voidglass',secondary:'deepstone',rare:'singularity'}));
renderAt(starfallRuntime,starfallApi,starfallSnapshot.mine.depthEntrance.x,starfallSnapshot.mine.depthEntrance.y,['assets/voidstar/floor.png','assets/voidstar/wall.png','assets/voidstar/depth-portal.png','assets/voidstar/sell-station.png','assets/voidstar/drill-forge.png']);
for(const [type,path] of [['voidglass','assets/voidstar/voidglass-node.png'],['deepstone','assets/voidstar/deepstone-node.png'],['singularity','assets/voidstar/singularity-node.png']]){const rock=starfallApi.snapshot().rocks.find(item=>item.scene==='starMine'&&item.depth===2&&item.type===type&&item.depositId&&!item.cavernId&&!item.broken);assert.ok(rock,type+' production node is missing');exposeRock(starfallApi,rock);renderAt(starfallRuntime,starfallApi,rock.x,rock.y,[path])}
assert.equal(starfallApi.snapshot().state.victory,false);assert.equal(starfallApi.snapshot().progression.finalVictory.completed,false);
const singularity=starfallApi.snapshot().mine.discovery.deposits.find(deposit=>deposit.type==='singularity');assert.ok(singularity);starfallApi.breakDepositRock(singularity.id,0);starfallApi.collectGroundDrops();starfallApi.save();starfallSnapshot=starfallApi.snapshot();assert.equal(starfallSnapshot.state.victory,true);assert.equal(starfallSnapshot.progression.finalVictory.completed,true);
const starfallReload=createRuntime().api;assert.equal(starfallReload.snapshot().state.victory,true);assert.equal(starfallReload.snapshot().progression.finalVictory.completed,true);assert.equal(starfallReload.snapshot().surfaceStarfallRendering.gateMark,'assets/surface/starfall-seal-mark.png');
storage.clear();for(const [key,value] of storageBeforeStarfallRendering)storage.set(key,value);

api.setPosition(455,350);runtime.drawCalls.length=0;api.renderOnce();
for(const asset of ['assay-station.png','forge-station.png','storage-chest.png','wayfarer-shop.png'])assert.ok(runtime.drawCalls.some(call=>call.src.includes(asset)),asset+' must render in the starter place');
for(const type of ['stone','copper','gold'])api.spawnGroundDrops(type,1,455,350);
runtime.drawCalls.length=0;api.renderOnce();for(const type of ['stone','copper','gold'])assert.ok(runtime.drawCalls.some(call=>call.src.includes(type+'-drop.png')),type+' drop asset must render');
for(const type of Object.keys(completeDropPaths).filter(type=>!['stone','copper','gold'].includes(type)))api.spawnGroundDrops(type,1,455,350);
runtime.drawCalls.length=0;api.renderOnce();assertRendered(runtime.drawCalls,Object.values(completeDropPaths));const emberstoneDropCall=runtime.drawCalls.find(call=>call.src.includes('emberstone-drop.png'));assert.deepEqual(emberstoneDropCall.args.slice(0,4),[39,58,184,132]);assert.equal(emberstoneDropCall.args.length,8,'resource drops must use cropped nine-argument drawImage calls');api.forceGlobalLootSweep();
api.setPickaxeLevel(2);api.setPosition(980,205);runtime.drawCalls.length=0;api.renderOnce();assert.ok(runtime.drawCalls.some(call=>call.src.includes('treasure-cache-closed.png')));
api.openChest('moss_ironbound');assert.equal(api.snapshot().state.openedChests.moss_ironbound,true);runtime.drawCalls.length=0;api.renderOnce();assert.ok(runtime.drawCalls.some(call=>call.src.includes('treasure-cache-open.png')));api.reset();
api.setPosition(1045,650);runtime.drawCalls.length=0;api.renderOnce();assert.ok(runtime.drawCalls.some(call=>call.src.includes('moonglass-gate.png')));api.reset();
const pickaxeKeys=['pickaxe-worn','pickaxe-iron','pickaxe-runed','pickaxe-moonglass','pickaxe-ember'];
function activeWalkCall(path){const calls=runtime.drawCalls.filter(call=>call.src.includes(path));assert.equal(calls.length,1,path+' must draw one clipped walk frame');assert.equal(calls[0].args.length,8);return calls[0]}
function assertPickaxeWalk(key){runtime.drawCalls.length=0;api.renderOnce();activeWalkCall('assets/characters/miner-b-walk.png');assert.equal(runtime.drawCalls.filter(call=>call.src.includes('assets/characters/miner-b.png')&&!call.src.includes('-walk.png')).length,0);const tools=runtime.drawCalls.filter(call=>call.src.includes('assets/tools/'));assert.equal(tools.length,1);assert.ok(tools[0].src.includes(key+'.png'))}
function assertDrillWalk(key){runtime.drawCalls.length=0;api.renderOnce();activeWalkCall('assets/characters/miner-b-'+key+'-walk.png');assert.equal(runtime.drawCalls.filter(call=>call.src.includes('assets/tools/')).length,0);assert.equal(runtime.drawCalls.filter(call=>call.src.includes('assets/characters/miner-b-'+key+'.png')).length,0)}
function assertStaticPickaxeLayers(key){runtime.drawCalls.length=0;api.renderOnce();assert.equal(runtime.drawCalls.filter(call=>call.src.includes('assets/characters/miner-b.png')&&!call.src.includes('-walk.png')).length,5);const tools=runtime.drawCalls.filter(call=>call.src.includes('assets/tools/'));assert.equal(tools.length,1);assert.ok(tools[0].src.includes(key+'.png'));assert.equal(runtime.drawCalls.some(call=>call.src.includes('-walk.png')),false)}
function assertStaticDrillComposite(key){runtime.drawCalls.length=0;api.renderOnce();const composites=runtime.drawCalls.filter(call=>call.src.includes('assets/characters/miner-b-'+key+'.png'));assert.equal(composites.length,1);assert.equal(runtime.drawCalls.filter(call=>call.src.includes('assets/tools/')).length,0);assert.equal(runtime.drawCalls.some(call=>call.src.includes('-walk.png')),false)}
for(let level=1;level<=5;level++){api.setDrillLevel(0);api.setPickaxeLevel(level);assert.equal(api.snapshot().characterRendering.activeToolKey,pickaxeKeys[level-1]);assertPickaxeWalk(pickaxeKeys[level-1])}
for(const variant of ['crusher','swift','prospector']){api.setDrillLevel(0);api.setStarforgeVariant(variant);assert.equal(api.snapshot().characterRendering.activeToolKey,'starforge-'+variant);assertPickaxeWalk('starforge-'+variant)}
for(const [level,key] of [[1,'drill-burrower'],[2,'drill-pulse'],[3,'drill-deepcore']]){api.setDrillLevel(level);assert.equal(api.snapshot().characterRendering.activeToolKey,key);assert.equal(api.snapshot().characterRendering.activeRenderAsset,'assets/characters/miner-b-'+key+'.png');assert.equal(api.snapshot().characterRendering.activeWalkAsset,'assets/characters/miner-b-'+key+'-walk.png');assertDrillWalk(key)}
api.setDrillLevel(0);api.setPickaxeLevel(1);
let pose=api.clearSwing();assert.equal(JSON.stringify(pose),JSON.stringify({toolAngle:-.2,armAngle:0,armX:0,armY:0,bodyAngle:0,bodyY:0,active:false}));
pose=api.setSwingProgress(.18);assert.ok(pose.toolAngle<-.99);assert.ok(pose.armAngle<-.12);assert.ok(pose.armX<0);assert.ok(pose.bodyAngle<0);assertStaticPickaxeLayers('pickaxe-worn');
pose=api.setSwingProgress(.38);assert.ok(pose.toolAngle>.5);assert.ok(pose.armAngle>.1);assert.ok(pose.armX>0);assert.ok(pose.bodyAngle>0);assertStaticPickaxeLayers('pickaxe-worn');
api.setDrillLevel(3);pose=api.setSwingProgress(.2);assert.equal(pose.toolAngle,0);assert.ok(pose.armX<0);assert.equal(pose.active,true);assertStaticDrillComposite('drill-deepcore');
api.setReducedMotion(true);pose=api.setSwingProgress(.2);assert.equal(JSON.stringify({armX:pose.armX,armY:pose.armY,bodyAngle:pose.bodyAngle}),JSON.stringify({armX:0,armY:0,bodyAngle:0}),'reduced motion suppresses high-frequency drill vibration');api.setReducedMotion(false);
api.clearSwing();api.setDrillLevel(0);

const directionRows={down:0,left:1,right:2,up:3},vectors={down:[0,1],left:[-1,0],right:[1,0],up:[0,-1]};
api.reset();api.setPosition(600,700);
for(const direction of Object.keys(directionRows)){
  api.setMoveVector(...vectors[direction]);const distanceBefore=api.snapshot().player.walkDistance;api.step(.08);const walking=api.snapshot().player;
  assert.equal(walking.direction,direction);assert.equal(walking.moving,true);assert.ok(walking.walkDistance>distanceBefore);assert.ok(walking.walkFrame>=0&&walking.walkFrame<6);
  runtime.drawCalls.length=0;api.renderOnce();const call=activeWalkCall('assets/characters/miner-b-walk.png');assert.equal(call.args[0],walking.walkFrame*256);assert.equal(call.args[1],directionRows[direction]*256);assert.deepEqual(call.args.slice(2,4),[256,256]);api.stopMove();api.step(.001);
}
api.reset();api.setPosition(600,700);api.setMoveVector(1,0);api.step(.2);assert.equal(api.snapshot().player.walkFrame,2);api.stopMove();api.step(.001);assert.equal(api.snapshot().player.walkFrame,3,'stopping settles on the nearest planted-foot contact');api.setMoveVector(1,0);api.step(.02);assert.ok(api.snapshot().player.walkFrame>=3,'resuming from contact must not rewind a leg frame');api.stopMove();
api.setMoveVector(1,0);api.step(.02);api.setMoveVector(1,1);api.step(.04);assert.equal(api.snapshot().player.direction,'right','equal diagonal keeps the current horizontal direction');api.setMoveVector(.4,1);api.step(.04);assert.equal(api.snapshot().player.direction,'down','direction hysteresis yields only when the other axis clearly wins');api.stopMove();
api.setPosition(52,500);const blockedDistance=api.snapshot().player.walkDistance;api.setMoveVector(-1,0);api.step(.12);assert.equal(api.snapshot().player.moving,false);assert.equal(api.snapshot().player.walkDistance,blockedDistance,'blocked input must not animate planted boots');api.stopMove();
api.setPosition(600,700);api.setReducedMotion(true);api.setMoveVector(1,0);const reducedX=api.snapshot().player.x;api.step(.08);assert.ok(api.snapshot().player.x>reducedX,'reduced motion must not stop movement');assert.equal(api.snapshot().player.walkFrame,0);runtime.drawCalls.length=0;api.renderOnce();assert.equal(activeWalkCall('assets/characters/miner-b-walk.png').args[0],0);api.stopMove();api.setReducedMotion(false);
const failedWalkRuntime=createRuntime({failWalkSheets:true}),failedWalkApi=failedWalkRuntime.api;failedWalkRuntime.drawCalls.length=0;failedWalkApi.renderOnce();assert.equal(failedWalkRuntime.drawCalls.filter(call=>call.src.includes('assets/characters/miner-b.png')&&!call.src.includes('-walk.png')).length,5,'static character must remain the loading/error fallback');assert.equal(failedWalkRuntime.drawCalls.some(call=>call.src.includes('assets/tools/pickaxe-worn.png')),true);
api.reset();
assert.equal(api.snapshot().mineralNodeRenderScale,.85);
assert.equal(api.snapshot().lighting.enabled,false);
let openingGuide=api.snapshot().guide;
assert.equal(openingGuide.kind,'rock');assert.equal(openingGuide.scene,'surface');assert.equal(openingGuide.visible,true);
api.setPosition(openingGuide.x,openingGuide.y);assert.equal(api.snapshot().guide.visible,false);
assert.equal(api.snapshot().markerStyle.bonusVeinRings,false);api.reset();

api.unlockAllAreas();api.unlockStarfall();api.enterMine('starMine');
let fallenPocket=api.snapshot().mine.discovery.caverns.find(item=>item.name==='Fallen Pocket');
api.mineTerrainCell(fallenPocket.boundaryIndex);api.mineTerrainCell(fallenPocket.boundaryIndex);
api.setPosition(fallenPocket.x,fallenPocket.y);
runtime.drawCalls.length=0;assert.doesNotThrow(()=>api.renderOnce());
assert.equal(runtime.drawCalls.filter(call=>call.src.includes('assets/starfall/crystal-pocket.png')).length,1);
api.claimPocketReward(fallenPocket.reward.id);
assert.equal(api.snapshot().state.claimedPocketRewards[fallenPocket.reward.id],true);
api.exitMine();

const storageBeforeLighting=new Map(storage),lightingRuntime=createRuntime(),lightingApi=lightingRuntime.api;lightingApi.enterMine('mossMine');
let glowingRock=lightingApi.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.type!=='stone'&&rock.type!=='deepstone'&&!rock.cavernId&&!rock.broken);
assert.ok(glowingRock);const lightMine=lightingApi.snapshot().mine,lightCols=Math.ceil(lightMine.width/lightMine.terrain.tileSize),lightIndex=Math.floor(glowingRock.y/lightMine.terrain.tileSize)*lightCols+Math.floor(glowingRock.x/lightMine.terrain.tileSize);
for(let hit=0;hit<8;hit++)lightingApi.mineTerrainCell(lightIndex);glowingRock=lightingApi.snapshot().rocks.find(rock=>rock.id===glowingRock.id);assert.equal(glowingRock.exposed,true);lightingApi.setPosition(glowingRock.x,glowingRock.y);lightingApi.renderOnce();
const caveLighting=lightingApi.snapshot().lighting;
assert.equal(JSON.stringify({enabled:caveLighting.enabled,technique:caveLighting.technique,occlusion:caveLighting.occlusion,bufferScale:caveLighting.bufferScale,maxOreLights:caveLighting.maxOreLights,maxNaturalLights:caveLighting.maxNaturalLights}),JSON.stringify({enabled:true,technique:'low-resolution-raycast-lightmap',occlusion:true,bufferScale:.34,maxOreLights:16,maxNaturalLights:22}));
assert.ok(caveLighting.bufferWidth>0&&caveLighting.bufferHeight>0);assert.ok(caveLighting.oreLights>0&&caveLighting.oreLights<=16);assert.ok(caveLighting.naturalLights>0&&caveLighting.naturalLights<=22);assert.ok(caveLighting.sources.some(source=>source.kind==='rockOre'));assert.ok(caveLighting.rayChecks>0);
assert.ok(caveLighting.hierarchy.stone<caveLighting.hierarchy.rockOre&&caveLighting.hierarchy.rockOre<caveLighting.hierarchy.wallOre);
assert.ok(caveLighting.hierarchy.wallOre<caveLighting.hierarchy.depthLamp&&caveLighting.hierarchy.depthLamp<caveLighting.hierarchy.bonusCrystalCollected&&caveLighting.hierarchy.bonusCrystalCollected<caveLighting.hierarchy.bonusCrystal);
const naturallyLitStone=lightingApi.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.type==='stone'&&!rock.broken&&!rock.barrierId);assert.ok(naturallyLitStone);exposeRock(lightingApi,naturallyLitStone);lightingApi.setPosition(naturallyLitStone.x,naturallyLitStone.y);lightingApi.renderOnce();const stoneLight=lightingApi.snapshot().lighting.sources.find(source=>source.kind==='stone');assert.ok(stoneLight);assert.equal(stoneLight.intensity,caveLighting.hierarchy.stone);
let wallOre=lightingApi.snapshot().rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.depositId&&!rock.cavernId&&!rock.exposed&&!rock.broken);assert.ok(wallOre);const wallCols=Math.ceil(lightMine.width/lightMine.terrain.tileSize),wallIndex=Math.floor(wallOre.y/lightMine.terrain.tileSize)*wallCols+Math.floor(wallOre.x/lightMine.terrain.tileSize);for(const neighbor of [wallIndex-1,wallIndex+1,wallIndex-wallCols,wallIndex+wallCols]){lightingApi.mineTerrainCell(neighbor);lightingApi.mineTerrainCell(neighbor);if(lightingApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===wallOre.id))break}assert.ok(lightingApi.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===wallOre.id));lightingApi.setPosition(wallOre.x,wallOre.y);lightingApi.renderOnce();const wallLight=lightingApi.snapshot().lighting.sources.find(source=>source.kind==='wallOre');assert.ok(wallLight);assert.ok(wallLight.intensity>=caveLighting.hierarchy.wallOre);
const lightingBenchmarkStarted=process.hrtime.bigint();for(let frame=0;frame<90;frame++)lightingApi.renderOnce();const lightingAverageMs=Number(process.hrtime.bigint()-lightingBenchmarkStarted)/1e6/90;assert.ok(lightingAverageMs<16.7,'lighting render budget exceeded: '+lightingAverageMs.toFixed(2)+'ms');
const litCache=lightingApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.reward.kind==='cache');for(let hit=0;hit<4&&!lightingApi.snapshot().mine.discovery.caverns.find(cavern=>cavern.id===litCache.id).discovered;hit++)lightingApi.mineTerrainCell(litCache.boundaryIndex);lightingApi.setPosition(litCache.x,litCache.y);lightingApi.renderOnce();
let bonusLight=lightingApi.snapshot().lighting.sources.find(source=>source.kind==='bonusCrystal');assert.ok(bonusLight);assert.equal(bonusLight.intensity,caveLighting.hierarchy.bonusCrystal);assert.equal(lightingApi.claimPocketReward(litCache.reward.id),true);lightingApi.renderOnce();
bonusLight=lightingApi.snapshot().lighting.sources.find(source=>source.kind==='bonusCrystalCollected');assert.ok(bonusLight);assert.equal(bonusLight.intensity,caveLighting.hierarchy.bonusCrystalCollected);
assert.equal(lightingApi.discoverDepthEntrance(),true);const litEntrance=lightingApi.snapshot().mine.depthEntrance;lightingApi.setPosition(litEntrance.x,litEntrance.y);lightingRuntime.drawCalls.length=0;lightingApi.renderOnce();const lampLight=lightingApi.snapshot().lighting.sources.find(source=>source.kind==='depthLamp');assert.ok(lampLight);assert.equal(lampLight.intensity,caveLighting.hierarchy.depthLamp);assert.equal(lightingApi.snapshot().lighting.depthLampAsset,'assets/entrances/depth-work-lamp.png');assertRendered(lightingRuntime.drawCalls,['assets/entrances/depth-work-lamp.png']);
storage.clear();for(const [key,value] of storageBeforeLighting)storage.set(key,value);
api.enterMine('mossMine');
assert.equal(api.snapshot().mine.visualPass,'mossvein-production-art-v2');
api.setPosition(180,503);api.setAim(.899,-.438);
let before=api.snapshot(),target=before.mine.terrain.target;
assert.ok(target);
assert.ok(api.sampleHeadlampRay()<caveLighting.beamLength);
api.mineTerrainCell(target.index);
let after=api.snapshot();
assert.equal(after.mine.terrain.target.index,target.index);
assert.ok(after.mine.terrain.target.hp<target.hp);
assert.equal(after.feedback.terrainHitIndex,target.index);
assert.equal(after.feedback.shake,0);
assert.equal(after.feedback.flash,0);
assert.equal(after.feedback.particleCount,0);

const buriedMineral=after.rocks.find(rock=>rock.scene==='mossMine'&&rock.depth===1&&rock.depositId&&!rock.cavernId&&!rock.exposed);
assert.ok(buriedMineral);
const buriedCol=Math.floor(buriedMineral.x/48),buriedRow=Math.floor(buriedMineral.y/48),buriedIndex=buriedRow*after.mine.terrain.cellCount/(Math.ceil(after.mine.height/48))+buriedCol;
for(const neighbor of [buriedIndex-1,buriedIndex+1,buriedIndex-Math.ceil(after.mine.width/48),buriedIndex+Math.ceil(after.mine.width/48)]){
  api.mineTerrainCell(neighbor);api.mineTerrainCell(neighbor);
  if(api.snapshot().mine.terrain.mineralHints.some(hint=>hint.rockId===buriedMineral.id))break;
}
after=api.snapshot();const seam=after.mine.terrain.mineralHints.find(hint=>hint.rockId===buriedMineral.id);
assert.ok(seam);assert.equal(seam.type,buriedMineral.type);assert.ok(seam.sides.length>=1);assert.equal(after.rocks.find(rock=>rock.id===buriedMineral.id).exposed,false);

const deposit=after.mine.discovery.deposits.find(item=>!item.rareFind);
for(let index=0;index<deposit.size;index++)api.breakDepositRock(deposit.id,index);
after=api.snapshot();
assert.equal(after.feedback.lastDepositBeat.id,deposit.id);
assert.equal(after.feedback.lastDepositBeat.type,deposit.type);
assert.equal(after.feedback.lastDepositBeat.broken,deposit.size);
assert.equal(after.feedback.lastDepositBeat.total,deposit.size);
assert.equal(after.feedback.lastDepositBeat.jackpot,true);
assert.ok(after.feedback.floaters.includes('VEIN CLEARED!'));
assert.equal(after.feedback.particleCount,0);

api.restoreTerrain();
before=api.snapshot();
const cacheCavern=before.mine.discovery.caverns.find(item=>item.reward.kind==='cache');
assert.ok(before.mine.discovery.caverns.every(item=>['cache','crystal','motherlode','shrine'].includes(item.reward.kind)));
const cargoBefore=Object.values(before.state.cargo).reduce((total,amount)=>total+amount,0);
api.mineTerrainCell(cacheCavern.boundaryIndex);api.mineTerrainCell(cacheCavern.boundaryIndex);
api.setPosition(cacheCavern.x,cacheCavern.y);runtime.drawCalls.length=0;api.renderOnce();assert.ok(runtime.drawCalls.some(call=>call.src.includes('assets/mossvein/buried-cache.png')));
api.claimPocketReward(cacheCavern.reward.id);api.save();
after=api.snapshot();
assert.equal(after.mine.discovery.caverns.find(item=>item.id===cacheCavern.id).reward.claimed,true);
assert.equal(after.feedback.lastPocketReward.kind,'cache');
assert.ok(Object.values(after.state.cargo).reduce((total,amount)=>total+amount,0)>cargoBefore||after.groundDrops.some(drop=>drop.sourcePocket===cacheCavern.reward.id));
const shrineCavern=after.mine.discovery.caverns.find(item=>item.reward.kind==='shrine');
api.mineTerrainCell(shrineCavern.boundaryIndex);api.mineTerrainCell(shrineCavern.boundaryIndex);api.setPosition(shrineCavern.x,shrineCavern.y);runtime.drawCalls.length=0;api.renderOnce();assert.ok(runtime.drawCalls.some(call=>call.src.includes('assets/mossvein/mining-rush-shrine.png')));

const motherlodeCavern=after.mine.discovery.caverns.find(item=>item.reward.kind==='motherlode');
api.mineTerrainCell(motherlodeCavern.boundaryIndex);api.mineTerrainCell(motherlodeCavern.boundaryIndex);
const motherlodeDeposit=api.snapshot().mine.discovery.deposits.find(item=>item.pocketRewardId===motherlodeCavern.reward.id);
for(let index=0;index<motherlodeDeposit.size;index++)api.breakDepositRock(motherlodeDeposit.id,index);
after=api.snapshot();
assert.equal(after.state.claimedPocketRewards[motherlodeCavern.reward.id],true);
assert.equal(after.feedback.lastPocketReward.kind,'motherlode');
assert.ok(after.rocks.filter(rock=>rock.pocketRewardId===motherlodeCavern.reward.id).every(rock=>rock.broken));

before=api.snapshot();
const rareFind=before.rocks.find(rock=>rock.scene==='mossMine'&&rock.rareFind);
const cavern=before.mine.discovery.caverns.find(item=>item.id===rareFind.cavernId);
api.mineTerrainCell(cavern.boundaryIndex);api.mineTerrainCell(cavern.boundaryIndex);api.save();
after=api.snapshot();
assert.equal(after.mine.discovery.caverns.find(item=>item.id===cavern.id).discovered,true);
assert.equal(after.rocks.find(rock=>rock.id===rareFind.id).exposed,true);
assert.equal(after.feedback.lastDiscovery.type,rareFind.type);
assert.equal(after.feedback.lastDiscovery.rare,true);
assert.equal(after.feedback.particleCount,0);

runtime=createRuntime();
after=runtime.api.snapshot();
assert.equal(after.scene,'mossMine');
assert.equal(after.state.discoveredCaverns[cavern.id],true);
assert.equal(after.state.claimedPocketRewards[cacheCavern.reward.id],true);

api=runtime.api;api.restoreTerrain();
before=api.snapshot();
const hiddenDescent={...before.mine.depthEntrance};
assert.equal(hiddenDescent.discovered,false);
assert.ok(hiddenDescent.boundaryIndex>=0);
assert.notEqual(before.mine.dirt,before.mine.floor);
assert.equal(api.discoverDepthEntrance(),true);
after=api.snapshot();
assert.equal(after.state.discoveredDepthEntrances.mossMine,true);
assert.equal(api.enterDepth(),true);
after=api.snapshot();
assert.equal(after.depth,2);
assert.equal(after.mine.depth,2);
assert.equal(after.mine.name,'ROOTWOUND DEPTHS');
assert.equal(after.mine.visualPass,'rootwound-production-assets-v1');
runtime.drawCalls.length=0;api.renderOnce();
for(const asset of ['wall.png','depth-shaft.png','sell-station.png','drill-forge.png'])assert.ok(runtime.drawCalls.some(call=>call.src.includes('assets/rootwound/'+asset)),asset+' must render in Rootwound');
assert.equal(after.mine.terrain.maxHp,320);
assert.notEqual(after.mine.dirt,after.mine.floor);
assert.ok(after.mine.discovery.deposits.length>before.mine.discovery.deposits.length);
assert.ok(after.rocks.filter(rock=>rock.scene==='mossMine'&&rock.depth===2&&rock.depositId).length>0);
assert.equal(after.mine.depthResources.main,'rootiron');assert.equal(after.mine.depthResources.secondary,'deepstone');assert.equal(after.mine.depthResources.rare,'ambercore');
const mossGate=after.mine.discovery.deposits.find(deposit=>deposit.type==='burrowsteel');
assert.ok(mossGate);assert.equal(mossGate.requiresDrillLevel,1);assert.equal(mossGate.drillGated,true);
assert.ok(after.mine.discovery.deposits.every(deposit=>['rootiron','deepstone','ambercore','burrowsteel'].includes(deposit.type)));
assert.ok(after.rocks.filter(rock=>rock.scene==='mossMine'&&rock.depth===2&&rock.depositId).every(rock=>rock.requiresDeepTool));
assert.ok(after.mine.depthStations.sell&&after.mine.depthStations.forge);

const depthAim=after.mine.depthEntrance.x<after.mine.width/2?1:-1;api.setPosition(after.mine.depthEntrance.x+depthAim*185,after.mine.depthEntrance.y);api.setAim(depthAim,0);before=api.snapshot();target=before.mine.terrain.target;assert.ok(target);
api.mineTerrainCell(target.index);assert.equal(api.snapshot().mine.terrain.target.hp,target.hp);
api.setStarforgeVariant('swift');
const starforgeCooldown=api.snapshot().effectivePickaxe.cooldown;
api.mineTerrainCell(target.index);assert.ok(api.snapshot().mine.terrain.target.hp<target.hp);
after=api.snapshot();assert.equal(after.state.drillGoalScene,'mossMine');assert.equal(after.goal.title,'Mine Rootiron for Burrower Drill');assert.ok(after.goal.detail.includes('ROOTWOUND DEPTHS'));
assert.equal(after.guide.kind,'rock');assert.equal(after.guide.resource,'rootiron');assert.equal(after.guide.scene,'mossMine');assert.equal(after.guide.depth,2);
let gatedHit=api.hitDepositRock(mossGate.id,0);assert.deepEqual(gatedHit.after,gatedHit.before);
const lockedGoal=JSON.stringify(after.goal);assert.equal(api.exitDepth(),true);api.setPosition(720,900);assert.equal(JSON.stringify(api.snapshot().goal),lockedGoal);assert.equal(api.enterDepth(),true);
api.grantGold(5000);api.grantCargo('rootiron',50);api.grantCargo('ambercore',5);api.grantCargo('copper',3);
after=api.snapshot();assert.equal(after.goal.detail,'READY AT ANY DEPTH 2 DRILL FORGE');assert.equal(after.protectedCargo.rootiron,50);assert.equal(after.protectedCargo.ambercore,5);assert.equal(after.sellableCargo.copper,3);
api.sellCargo();after=api.snapshot();assert.equal(after.state.cargo.rootiron,50);assert.equal(after.state.cargo.ambercore,5);assert.equal(after.state.cargo.copper,0);
assert.equal(after.guide.kind,'drill-forge');assert.equal(after.guide.scene,'mossMine');assert.equal(after.guide.depth,2);
const drillForge=api.snapshot().mine.depthStations.forge;api.setPosition(drillForge.x,drillForge.y);api.upgradeDrill();after=api.snapshot();
assert.equal(after.state.drillLevel,1);assert.equal(after.effectivePickaxe.name,'Burrower Drill');assert.ok(after.effectivePickaxe.cooldown<starforgeCooldown);assert.equal(after.toolMode,'drill');assert.equal(after.goal.title,'Mine Burrowsteel for Pulse Drill');
gatedHit=api.hitDepositRock(mossGate.id,0);assert.notDeepEqual(gatedHit.after,gatedHit.before);
assert.equal(api.snapshot().feedback.hitStop,0);
api.grantGold(12000);api.grantCargo('burrowsteel',60);api.grantCargo('copper',2);api.sellCargo();after=api.snapshot();
assert.equal(after.state.cargo.burrowsteel,60);assert.equal(after.state.cargo.copper,0);assert.equal(after.goal.title,'Mine Prismite for Pulse Drill');
assert.equal(after.guide.kind,'depth-exit');assert.equal(after.guide.scene,'mossMine');assert.equal(after.guide.depth,2);api.save();

runtime=createRuntime();api=runtime.api;after=api.snapshot();
assert.equal(after.scene,'mossMine');assert.equal(after.depth,2);assert.equal(after.mine.depthEntrance.x,hiddenDescent.x);assert.equal(after.mine.depthEntrance.y,hiddenDescent.y);
assert.equal(after.state.discoveredDepthEntrances.mossMine,true);assert.equal(after.state.drillLevel,1);
assert.equal(api.exitDepth(),true);assert.equal(api.snapshot().guide.kind,'mine-exit');api.exitMine();api.unlockAllAreas();api.unlockStarfall();
assert.equal(api.snapshot().guide.kind,'mine-entrance');assert.equal(api.snapshot().guide.destination,'moonMine');

api.enterMine('moonMine');if(!api.snapshot().mine.depthEntrance.discovered)assert.equal(api.discoverDepthEntrance(),true);assert.equal(api.enterDepth(),true);
api.grantCargo('prismite',40);after=api.snapshot();assert.equal(after.goal.title,'Mine Lunacore for Pulse Drill');
api.grantCargo('lunacore',4);after=api.snapshot();assert.equal(after.goal.detail,'READY AT ANY DEPTH 2 DRILL FORGE');api.upgradeDrill();after=api.snapshot();assert.equal(after.state.drillLevel,2);assert.equal(after.effectivePickaxe.name,'Pulse Drill');assert.equal(after.goal.title,'Mine Phase Crystal for Deepcore Drill');
after=api.snapshot();const moonGate=after.mine.discovery.deposits.find(deposit=>deposit.type==='phasecrystal');
assert.ok(moonGate);assert.equal(moonGate.requiresDrillLevel,2);gatedHit=api.hitDepositRock(moonGate.id,0);assert.notDeepEqual(gatedHit.after,gatedHit.before);
api.grantCargo('phasecrystal',70);api.grantCargo('copper',2);api.sellCargo();after=api.snapshot();
assert.equal(after.state.cargo.phasecrystal,70);assert.equal(after.state.cargo.copper,0);assert.equal(after.goal.title,'Mine Magmaite for Deepcore Drill');
assert.equal(api.exitDepth(),true);api.exitMine();

api.enterMine('emberMine');if(!api.snapshot().mine.depthEntrance.discovered)assert.equal(api.discoverDepthEntrance(),true);assert.equal(api.enterDepth(),true);
after=api.snapshot();const emberGate=after.mine.discovery.deposits.find(deposit=>deposit.type==='infernium');
assert.ok(emberGate);assert.equal(emberGate.requiresDrillLevel,2);gatedHit=api.hitDepositRock(emberGate.id,0);assert.notDeepEqual(gatedHit.after,gatedHit.before);
api.grantCargo('magmaite',50);after=api.snapshot();assert.equal(after.goal.title,'Mine Furnace Heart for Deepcore Drill');
api.grantCargo('furnaceheart',5);after=api.snapshot();assert.equal(after.goal.title,'Mine Infernium for Deepcore Drill');
api.grantCargo('infernium',70);api.grantGold(25000);after=api.snapshot();assert.equal(after.goal.detail,'READY AT ANY DEPTH 2 DRILL FORGE');
api.upgradeDrill();after=api.snapshot();assert.equal(after.state.drillLevel,3);assert.equal(after.effectivePickaxe.name,'Deepcore Drill');assert.equal(JSON.stringify(after.goal),JSON.stringify({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'}));
let {distance:emberDepthRouteDistance,visible:emberDepthRouteVisible,...emberDepthRoute}=after.guide;assert.equal(JSON.stringify(emberDepthRoute),JSON.stringify({kind:'depth-exit',scene:'emberMine',depth:2,x:after.mine.depthEntrance.x,y:after.mine.depthEntrance.y,color:'#ffd080',closeRadius:108}));assert.ok(emberDepthRouteDistance>108);assert.equal(emberDepthRouteVisible,true);api.save();

runtime=createRuntime();api=runtime.api;after=api.snapshot();assert.equal(after.state.drillLevel,3);assert.equal(after.effectivePickaxe.name,'Deepcore Drill');assert.equal(JSON.stringify(after.goal),JSON.stringify({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'}));assert.equal(after.guide.kind,'depth-exit');assert.equal(after.guide.scene,'emberMine');assert.equal(after.guide.depth,2);
assert.equal(api.exitDepth(),true);after=api.snapshot();let {distance:emberMineRouteDistance,visible:emberMineRouteVisible,...emberMineRoute}=after.guide;assert.equal(JSON.stringify(emberMineRoute),JSON.stringify({kind:'mine-exit',scene:'emberMine',depth:1,x:145,y:1030,color:'#ffc06f',closeRadius:108}));assert.ok(emberMineRouteDistance>=0);assert.equal(typeof emberMineRouteVisible,'boolean');
api.exitMine();after=api.snapshot();assert.equal(JSON.stringify(after.goal),JSON.stringify({title:'Enter Starfall Hollow',detail:'THE FINAL DESCENT AWAITS'}));let {distance:surfaceStarfallDistance,visible:surfaceStarfallVisible,...surfaceStarfallGuide}=after.guide;assert.equal(JSON.stringify(surfaceStarfallGuide),JSON.stringify({kind:'mine-entrance',scene:'surface',depth:1,x:3505,y:1000,color:'#f0ddff',closeRadius:112,destination:'starMine'}));assert.ok(surfaceStarfallDistance>112);assert.equal(surfaceStarfallVisible,true);

api.enterMine('starMine');after=api.snapshot();assert.equal(JSON.stringify(after.goal),JSON.stringify({title:'Find the hidden Voidstar entrance',detail:'DIG DEEPER'}));assert.equal(after.mine.depthEntrance.discovered,false);assert.equal(after.guide,null);
const voidstarEntrance={x:after.mine.depthEntrance.x,y:after.mine.depthEntrance.y};assert.equal(api.discoverDepthEntrance(),true);after=api.snapshot();assert.equal(JSON.stringify(after.goal),JSON.stringify({title:'Enter Voidstar Depths',detail:'DEEPCORE DRILL READY'}));let {distance:voidstarEntranceDistance,visible:voidstarEntranceVisible,...voidstarEntranceGuide}=after.guide;assert.equal(JSON.stringify(voidstarEntranceGuide),JSON.stringify({kind:'depth-entrance',scene:'starMine',depth:1,x:voidstarEntrance.x,y:voidstarEntrance.y,color:'#f2d8ff',closeRadius:108}));assert.ok(voidstarEntranceDistance>=0);assert.equal(typeof voidstarEntranceVisible,'boolean');
assert.equal(api.enterDepth(),true);after=api.snapshot();assert.equal(JSON.stringify(after.goal),JSON.stringify({title:'Mine a Singularity Core',detail:'THE FINAL DISCOVERY'}));assert.equal(JSON.stringify(after.progression.finalVictory),JSON.stringify({completed:false,requiresDrill:'Deepcore Drill',resource:'singularity',scene:'starMine',depth:2}));assert.equal(after.guide.kind,'rock');assert.equal(after.guide.scene,'starMine');assert.equal(after.guide.depth,2);assert.equal(after.guide.resource,'singularity');assert.equal(after.guide.color,'#f3bfff');assert.equal(after.guide.closeRadius,88);const guidedSingularity=after.rocks.find(rock=>rock.id===after.guide.rockId);assert.ok(guidedSingularity);assert.equal(guidedSingularity.type,'singularity');assert.equal(guidedSingularity.x,after.guide.x);assert.equal(guidedSingularity.y,after.guide.y);assert.equal(api.exitDepth(),true);api.exitMine();
const gatedByScene={mossMine:'burrowsteel',moonMine:'phasecrystal',emberMine:'infernium'};
for(const scene of ['mossMine','moonMine','emberMine','starMine']){
  api.enterMine(scene);before=api.snapshot();
  assert.equal(before.mine.depthEntrance.scene,scene);assert.notEqual(before.mine.dirt,before.mine.floor);
  if(!before.mine.depthEntrance.discovered)assert.equal(api.discoverDepthEntrance(),true);
  assert.equal(api.enterDepth(),true);after=api.snapshot();
  assert.equal(after.depth,2);assert.ok(after.mine.terrain.maxHp>=320);
  assert.ok(after.mine.discovery.deposits.every(deposit=>Object.values(after.mine.depthResources).includes(deposit.type)||deposit.drillGated));
  if(gatedByScene[scene])assert.ok(after.mine.discovery.deposits.some(deposit=>deposit.type===gatedByScene[scene]));
  else assert.equal(after.mine.discovery.deposits.some(deposit=>deposit.drillGated),false);
  assert.notEqual(after.mine.dirt,after.mine.floor);assert.doesNotThrow(()=>api.renderOnce());
  assert.equal(api.exitDepth(),true);api.exitMine();
}

const movementBefore=api.snapshot().movement;
api.grantGold(10000000);
for(let level=0;level<25;level++)assert.equal(api.buyMovementSpeed(),true);
after=api.snapshot();assert.equal(after.movement.level,movementBefore.level+25);assert.ok(after.movement.multiplier>movementBefore.multiplier);assert.ok(after.movement.nextCost>movementBefore.nextCost);
const normalCooldown=after.effectivePickaxe.cooldown;api.activateMiningRush();after=api.snapshot();assert.equal(after.miningRush.timer,30);assert.ok(after.effectivePickaxe.cooldown<normalCooldown);
api.spawnGroundDrops('copper',1,-500,-500);after=api.snapshot();let edgeDrop=after.groundDrops.at(-1);assert.equal(edgeDrop.x,56);assert.equal(edgeDrop.y,76);api.forceGlobalLootSweep();
api.enterMine('mossMine');before=api.snapshot();api.spawnGroundDrops('stone',1,999999,999999);after=api.snapshot();edgeDrop=after.groundDrops.at(-1);assert.equal(edgeDrop.x,before.mine.width-56);assert.equal(edgeDrop.y,before.mine.height-64);api.forceGlobalLootSweep();api.exitMine();
after=api.snapshot();const dropsBefore=after.groundDrops.length;api.spawnGroundDrops('copper',2,800,500);api.enterMine('mossMine');api.spawnGroundDrops('stone',3,280,650);assert.equal(api.snapshot().groundDrops.length,dropsBefore+5);
assert.equal(api.forceGlobalLootSweep(),dropsBefore+5);after=api.snapshot();assert.equal(after.groundDrops.length,0);assert.ok(after.lootSweep.remaining>299);api.save();
runtime=createRuntime();after=runtime.api.snapshot();assert.equal(after.movement.level,movementBefore.level+25);assert.ok(after.movement.multiplier>1);
api=runtime.api;api.reset();before=api.snapshot();
assert.equal(before.state.base.chests.length,1);assert.equal(before.state.base.chests[0].packed,false);assert.equal(Object.values(before.state.base.chests[0].items).reduce((total,amount)=>total+amount,0),0);
for(const type of Object.keys(before.state.cargo))api.grantCargo(type,1);
api.grantCargo('rootiron',8);api.grantCargo('ambercore',1);
assert.equal(api.autoSort(),19);after=api.snapshot();
assert.equal(Object.values(after.state.base.chests[0].items).filter(amount=>amount>0).length,19);assert.equal(Object.values(after.state.cargo).reduce((total,amount)=>total+amount,0),11);
api.grantCargo('rootiron',42);assert.equal(api.autoSort(),1);after=api.snapshot();assert.equal(Object.values(after.state.base.chests[0].items).filter(amount=>amount>0).length,20);assert.equal(Object.values(after.state.cargo).reduce((total,amount)=>total+amount,0),52);
api.grantGold(1000);assert.equal(api.buyStorageChest(),true);after=api.snapshot();
const secondChest=after.state.base.chests[1];assert.equal(secondChest.packed,true);assert.equal(api.placeBaseModule(secondChest.id),true);api.grantCargo('ambercore',4);assert.equal(api.autoSort(),1);after=api.snapshot();assert.equal(Object.values(after.state.cargo).reduce((total,amount)=>total+amount,0),55);
const forge={...after.state.base.forge};api.setPosition(forge.x,forge.y);assert.equal(api.packBaseModule('forge'),true);api.enterMine('mossMine');assert.equal(api.placeBaseModule('forge'),true);after=api.snapshot();assert.equal(after.state.base.forge.scene,'mossMine');assert.equal(after.state.base.forge.packed,false);
const movedChest={...after.state.base.chests[1]};api.exitMine();api.setPosition(movedChest.x,movedChest.y);assert.equal(api.packBaseModule(movedChest.id),true);api.enterMine('mossMine');assert.equal(api.placeBaseModule(movedChest.id),true);api.save();
runtime=createRuntime();after=runtime.api.snapshot();assert.equal(after.state.base.forge.scene,'mossMine');assert.equal(after.state.base.chests.find(chest=>chest.id===movedChest.id).scene,'mossMine');assert.equal(Object.values(after.state.base.chests[0].items).reduce((total,amount)=>total+amount,0),20);

api=runtime.api;api.reset();api.openChest('moss_supply');api.collectGroundDrops();api.unlockAllAreas();api.setPickaxeLevel(4);api.grantGold(625);api.grantMined('moonglass',1);api.grantMined('emberstone',1);api.grantCargo('emberstone',99);api.setPosition(455,250);api.step(.01);api.interact();after=api.snapshot();
assert.equal(after.state.pickaxeLevel,4);assert.equal(JSON.stringify(after.goal.requirements),JSON.stringify([{type:'emberstone',amount:100,current:99}]));assert.equal(after.protectedCargo.emberstone,99);
api.grantCargo('emberstone',1);api.interact();after=api.snapshot();assert.equal(after.state.pickaxeLevel,5);assert.equal(after.state.cargo.emberstone,0);
api.grantGold(450);api.grantCargo('sunslag',29);api.interact();assert.equal(api.snapshot().state.emberMastery,0);api.grantCargo('sunslag',1);api.interact();after=api.snapshot();assert.equal(after.state.emberMastery,1);assert.equal(after.state.cargo.sunslag,0);

api.reset();api.unlockStarfall();api.grantCargo('astralite',199);api.grantCargo('crownstone',199);api.forgeStarVariant('crusher');assert.equal(api.snapshot().state.starforgeVariant,null);
api.grantCargo('astralite',1);api.grantCargo('crownstone',1);api.forgeStarVariant('crusher');after=api.snapshot();assert.equal(after.state.starforgeVariant,'crusher');assert.equal(after.state.cargo.astralite,0);assert.equal(after.state.cargo.crownstone,0);

api.reset();api.setPickaxeLevel(2);api.openChest('moss_ironbound');after=api.snapshot();assert.equal(JSON.stringify(after.state.pendingChestLoot.moss_ironbound),JSON.stringify({coin:75}));assert.equal(after.groundDrops.filter(drop=>drop.sourceChest==='moss_ironbound').length,3);
api.collectGroundDrops();after=api.snapshot();assert.equal(after.state.gold,75);assert.equal(Object.values(after.state.cargo).reduce((total,amount)=>total+amount,0),0);assert.equal(after.state.pendingChestLoot.moss_ironbound,undefined);

api.reset();api.setStarforgeVariant('swift');api.enterMine('mossMine');api.setPosition(180,503);api.setAim(.899,-.438);api.setMiningHeld(true);for(let index=0;index<8;index++)api.step(.05);
assert.equal(api.snapshot().heatStreak.unlocked,true);assert.ok(api.snapshot().heatStreak.speedMultiplier>1,'continuous mining must build Heat Streak speed');
api.setMiningHeld(false);assert.equal(JSON.stringify({active:api.snapshot().heatStreak.active,elapsed:api.snapshot().heatStreak.elapsed,speedMultiplier:api.snapshot().heatStreak.speedMultiplier}),JSON.stringify({active:false,elapsed:0,speedMultiplier:1}));

const storageBeforeHub=new Map(storage);storage.clear();const hubRuntime=createRuntime(),hubApi=hubRuntime.api;hubApi.dismissStartMenu();
assert.equal(hubApi.snapshot().hub.unlocked,false);hubApi.unlockHub();let hubSnapshot=hubApi.snapshot();assert.equal(hubSnapshot.state.victory,true);assert.equal(hubSnapshot.hub.unlocked,true);assert.equal(hubSnapshot.progression.endgame.noPrestigeReset,true);assert.equal(hubSnapshot.goal.title,'Find the Underground Hub');
hubApi.setPosition(hubSnapshot.hub.stations.surfaceEntrance.x,hubSnapshot.hub.stations.surfaceEntrance.y);hubApi.step(.02);assert.equal(hubApi.snapshot().activeContext,'hubEntrance');assert.equal(hubRuntime.elements.get('contextTitle').textContent,'Underground Hub');hubRuntime.drawCalls.length=0;hubApi.renderOnce();assert.ok(hubRuntime.drawCalls.some(call=>call.src.includes('assets/voidstar/depth-portal.png')),'the Starfall Hub lift must use the production portal asset');
assert.equal(hubApi.enterHub(),true);hubApi.step(.02);hubSnapshot=hubApi.snapshot();assert.equal(hubSnapshot.scene,'hub');assert.equal(hubSnapshot.mine,null);assert.equal(hubSnapshot.hub.active,true);assert.equal(hubSnapshot.hub.visited,true);assert.equal(hubSnapshot.toolMode,'builder');assert.equal(hubSnapshot.ambientLife.visible.length,0);assert.equal(hubSnapshot.worldLife.drift.length,0);assert.equal(hubRuntime.elements.get('areaName').textContent,'UNDERGROUND HUB');assert.equal(hubRuntime.elements.get('mineAction').textContent,'BUILD');
hubRuntime.drawCalls.length=0;hubApi.renderOnce();assert.ok(hubRuntime.drawCalls.some(call=>call.src.includes('assets/voidstar/depth-portal.png')),'both Hub elevators must render from the production shaft asset');assert.equal(hubApi.setHubBuildMode(true),true);hubApi.step(.01);assert.equal(hubApi.snapshot().hub.buildMode.active,true);assert.equal(hubRuntime.elements.get('hubBuildToolbar').hidden,false);assert.equal(hubRuntime.elements.get('mineAction').textContent,'DONE');assert.equal(hubApi.setHubBuildMode(false),false);
hubApi.grantCargo('stone',20);hubApi.grantGold(1000);assert.equal(hubApi.placeHubCell('wall',12,5),true);hubSnapshot=hubApi.snapshot();const hubWall=hubSnapshot.hub.tiles.find(tile=>tile.kind==='wall');assert.equal(hubSnapshot.state.cargo.stone,15);assert.equal(hubApi.hubCollisionAt(hubWall.x,hubWall.y),true);hubApi.setPosition(hubWall.x-80,hubWall.y);hubApi.setMoveVector(1,0);hubApi.step(.5);hubApi.stopMove();assert.ok(hubApi.snapshot().player.x<hubWall.x,'Hub walls must block walking');
assert.equal(hubApi.placeHubCell('lamp',13,5),true);assert.equal(hubApi.snapshot().state.gold,920);assert.equal(hubApi.placeHubCell('storage',14,5),true);hubSnapshot=hubApi.snapshot();assert.equal(hubSnapshot.state.gold,670);const hubChest=hubSnapshot.state.base.chests.find(chest=>chest.scene==='hub'&&!chest.packed);assert.ok(hubChest);hubApi.setPosition(hubChest.x,hubChest.y);hubApi.grantCargo('copper',3);assert.equal(hubApi.autoSort(),18);hubSnapshot=hubApi.snapshot();assert.equal(hubSnapshot.state.base.chests.find(chest=>chest.id===hubChest.id).items.copper,3);assert.equal(hubSnapshot.state.base.chests.find(chest=>chest.id===hubChest.id).items.stone,15);hubApi.save();
const reloadedHubRuntime=createRuntime(),reloadedHubApi=reloadedHubRuntime.api;hubSnapshot=reloadedHubApi.snapshot();assert.equal(hubSnapshot.scene,'hub');assert.equal(hubSnapshot.hub.tiles.length,2);assert.equal(hubSnapshot.hub.modules.some(module=>module.id===hubChest.id),true);reloadedHubApi.dismissStartMenu();assert.equal(reloadedHubApi.removeHubCell(12,5),true);assert.equal(reloadedHubApi.snapshot().state.cargo.stone,5);assert.equal(reloadedHubApi.removeHubCell(13,5),true);assert.equal(reloadedHubApi.snapshot().state.gold,750);assert.equal(reloadedHubApi.removeHubCell(14,5),true);hubSnapshot=reloadedHubApi.snapshot();assert.equal(hubSnapshot.state.base.chests.find(chest=>chest.id===hubChest.id).packed,true);assert.equal(hubSnapshot.state.base.chests.find(chest=>chest.id===hubChest.id).items.copper,3);
reloadedHubApi.setPosition(hubSnapshot.hub.stations.deepElevator.x,hubSnapshot.hub.stations.deepElevator.y);reloadedHubApi.step(.02);assert.equal(reloadedHubApi.snapshot().activeContext,'deepElevator');assert.equal(reloadedHubRuntime.elements.get('contextButton').disabled,true);assert.equal(reloadedHubRuntime.elements.get('contextButton').textContent,'OFFLINE');assert.equal(reloadedHubApi.exitHub(),true);assert.equal(reloadedHubApi.snapshot().scene,'surface');storage.clear();for(const [key,value] of storageBeforeHub)storage.set(key,value);

const migrationState={...after.state,gold:424242};
storage.clear();storage.set('retiredMiningPrototypeSave',JSON.stringify(migrationState));runtime=createRuntime();after=runtime.api.snapshot();
assert.equal(after.state.gold,424242);assert.equal(storage.has('retiredMiningPrototypeSave'),false);assert.equal(storage.has('everDeeperPrototypeV2'),true);
console.log('Runtime smoke passed: Ever Deeper branding; four-world production rendering; Heat Streak; Underground Hub building, storage, lighting, collision, and persistence; final progression; save migration; and reload. Light pass '+lightingAverageMs.toFixed(2)+'ms average.');
