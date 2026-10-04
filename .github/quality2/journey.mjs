import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version=process.env.EXPECTED_VERSION||'1.0.0-dev.15.56';
const files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const hash=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))hash.update(b);
 if(hash.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname,file=path.resolve(web,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/'||name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-skills-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(60000);
const checks=[],messages=[],images=[],failures=[];let runtime=null,id=0;
const report={version,files,source:process.env.GITHUB_SHA,base_source:'befb9eabfc1ff424fe20c4db34eeea19cc8b0301',physical_iphone:false,checks,images,failures};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({...report,runtime},null,2));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(label,predicate,timeout=20000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(100);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
function check(name,ok,details={}){checks.push({name,passed:!!ok,...details});save();if(!ok)throw Error(name);}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function point(name){const s=await state(),v=page.viewportSize(),r=s.buttons[name]||s[name];if(!Array.isArray(r))throw Error('Missing button '+name);return {x:(r[0]+r[2]/2)/s.viewport[0]*v.width,y:(r[1]+r[3]/2)/s.viewport[1]*v.height};}
async function tap(name){const p=await point(name);await page.touchscreen.tap(p.x,p.y);await delay(220);}
async function touch(type,p){await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});}
async function shot(name){
 const name2=name+'.jpg';await page.screenshot({path:path.join(output,name2),quality:94,timeout:30000});
 const s=await state();fs.writeFileSync(path.join(output,name+'.json'),JSON.stringify(s,null,2));
 images.push({file:name2,state:name+'.json',viewport:page.viewportSize(),dpr:2});save();console.log('QUALITY2_CAPTURE',name);
}
async function ready(){return wait('active game',s=>!s?.menu&&!s?.inventory_open&&!s?.shop_open&&s?.game_started&&s.player_controls_enabled&&s.actual_map?.world_active);}
async function walk(direction,predicate,label,vertical=0){
 const s=await state(),jr=s.buttons.joystick,v=page.viewportSize();
 const start={x:(jr[0]+jr[2]*.20)/s.viewport[0]*v.width,y:(jr[1]+jr[3]*.70)/s.viewport[1]*v.height};
 await touch('touchStart',start);await touch('touchMove',{x:start.x+32*direction,y:start.y+32*vertical});
 try{await wait(label,predicate,10000);}finally{await touch('touchEnd',start);}
}
async function group(name,fn){
 try{await fn();checks.push({name,passed:true});}
 catch(e){failures.push({group:name,error:String(e.stack||e)});console.error('GROUP_FAILED',name,e.message);try{await shot('failure-'+name);}catch{}}
 save();
}
async function closeModal(){
 // Parent navigation can expose another modal; inspect each resulting state.
 for(let remaining=6;remaining>0;remaining--){
  const s=await state();
  if(s?.treasury_goal?.open)await tap('treasury_close');
  else if(s?.shop_open)await tap('shop_close');
  else if(s?.mole_open)await tap('mole_close');
  else if(s?.inventory_open)await tap('inventory_close');
  else if(s?.settings_open)await tap('settings_back');
  else if(s?.skills_open)await tap('skills_close');
  else if(s?.menu)await tap('continue');
  else return;
 }
 throw Error('Modal did not return to gameplay');
}
async function heldMineUntil(label,predicate,timeout=25000){
 const p=await point('hud_mine');await touch('touchStart',p);
 try{return await wait(label,predicate,timeout);}finally{await touch('touchEnd',p);}
}
function containsRect(outer,inner,tolerance=.75){
 return Array.isArray(outer)&&Array.isArray(inner)&&outer.length===4&&inner.length===4&&inner[2]>0&&inner[3]>0&&inner[0]>=outer[0]-tolerance&&inner[1]>=outer[1]-tolerance&&inner[0]+inner[2]<=outer[0]+outer[2]+tolerance&&inner[1]+inner[3]<=outer[1]+outer[3]+tolerance;
}
async function conclusionLayout(viewport){
 await page.setViewportSize(viewport);
 let previous='',stableSince=0;
 return wait('conclusion stable layout '+viewport.width,s=>{
  const geometry=s?.quality?.finale?.geometry;
  if(!geometry?.visible||!geometry.viewport||Math.abs(geometry.viewport[2]/geometry.viewport[3]-viewport.width/viewport.height)>.01)return false;
  const fingerprint=JSON.stringify(geometry);
  if(fingerprint!==previous){previous=fingerprint;stableSince=Date.now();return false;}
  return Date.now()-stableSince>=300;
 },5000);
}
async function profile(label,mining=false){
 await ready();await delay(1500);
 let start=null;
 if(mining){start=await point('hud_mine');await touch('touchStart',start);}
 else {
  const s=await state(),r=s.buttons.joystick,v=page.viewportSize();start={x:(r[0]+r[2]*.20)/s.viewport[0]*v.width,y:(r[1]+r[3]*.70)/s.viewport[1]*v.height};
  await touch('touchStart',start);await touch('touchMove',{x:start.x+26,y:start.y});
 }
 try{
  await command('quality_profile',{action:'begin'});
  const browserFrames=await page.evaluate(()=>new Promise(resolve=>{const values=[];let first=0,last=0;function frame(now){if(!first)first=now;if(last)values.push(now-last);last=now;if(now-first<8000)requestAnimationFrame(frame);else resolve(values);}requestAnimationFrame(frame);}));
  await command('quality_profile',{action:'end'});
  const s=await state(),metrics=s.quality.profile;
  check(label+'-representative-window',metrics.seconds>=8&&metrics.frames>100&&s.actual_map.world_active&&!s.menu,{metrics});
  report.performance??=[];report.performance.push({label,metrics,browser_frames_ms:browserFrames,physical_iphone:false});save();
  check(label+'-mac-render-budget',metrics.fps>=45&&metrics.frame_ms.p95<=50&&metrics.frame_ms.over_250ms<=2,{metrics});
 }finally{await touch('touchEnd',start);}
 await shot('performance-'+label);
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('journey ready',s=>s?.version===version&&s?.quality?.journey,180000);
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio,userAgent:navigator.userAgent};});
 check('real-gpu-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 await group('fresh-mine-sell-upgrade-gate',async()=>{
  let s=await state();check('new-run-is-unprogressed',s.quality.journey.pickaxe===1&&s.quality.journey.mined===0&&!s.quality.journey.moonglass_unlocked,{journey:s.quality.journey});
  await command('quality_journey',{step:'entrance'});await wait('real mine entrance context',s=>s.quality.journey.surface_context==='enter:mossMine');await shot('journey-01-mine-entrance');
  await tap('hud_context');await wait('actual mine entry',s=>s.phase==='mine'&&s.actual_map.world_active);await ready();
  await command('quality_journey',{step:'target'});s=await state();
  check('natural-first-target-preserved',s.quality.journey.result.natural_target_found&&s.quality.journey.result.block.hp>0&&s.quality.journey.result.block.role==='resource'&&s.quality.journey.result.block.requires_tool<=s.quality.journey.pickaxe,{target:s.quality.journey.result});
  const mined=s.quality.journey.mined;await shot('journey-02-natural-first-target');
  await heldMineUntil('actual mining breaks natural ore',s=>s.quality.journey.mined>mined);
  // Fresh pickup radius is shorter than mining reach: walk into the real drop.
  await walk(1,s=>Object.values(s.quality.cargo).reduce((a,b)=>a+b,0)>0,'actual movement collects mined cargo');
  s=await state();check('first-swing-earned-skill',s.skill_xp.mining>0,{xp:s.skill_xp,mined:s.quality.journey.mined,cargo:s.quality.cargo});await shot('journey-03-first-earned-ore');
  await command('quality_journey',{step:'exit'});await wait('mine exit available',s=>s.quality.journey.exit_context);await tap('hud_context');await wait('actual surface return',s=>s.phase==='surface');await ready();
  const goldBefore=(await state()).quality.journey.gold;
  await command('quality_journey',{step:'assay_approach'});s=await state();check('assay-starts-outside-trigger',s.quality.journey.surface_context!=='sell',{journey:s.quality.journey});await shot('journey-04-assay-approach');
  await walk(-1,s=>s.quality.journey.surface_context==='sell','real touch enters assay');
  await wait('real automatic assay completes',s=>s.quality.journey.gold>goldBefore&&Object.keys(s.quality.journey.transaction).length===0,20000);
  s=await state();check('earned-ore-converts-to-gold',s.quality.journey.gold>goldBefore,{before:goldBefore,after:s.quality.journey.gold,trigger:'held joystick enters automatic Assay'});await shot('journey-05-first-sale');
  for(const level of [2,3]){
   await command('quality_journey',{step:'forge'});await wait('forge context',s=>s.quality.journey.surface_context==='forge');await tap('hud_context');await wait('forge opens',s=>s.shop_open&&s.quality.commerce.panel_id==='forge');
   s=await state();check('forge-'+level+'-actual-affordability',s.quality.commerce.action_enabled&&s.quality.commerce.selected_affordable,{commerce:s.quality.commerce,fixture:s.quality.journey.result});await shot('journey-06-forge-ready-'+level);
   await tap('shop_primary');await wait('paid forge equips '+level,s=>s.quality.journey.pickaxe===level&&Object.keys(s.quality.journey.transaction).length===0,20000);await ready();await shot('journey-07-forge-complete-'+level);
  }
  await command('quality_journey',{step:'gate'});await wait('locked gate action',s=>s.quality.journey.surface_context==='gate:moonglass');
  s=await state();check('gate-still-locked-before-action',!s.quality.journey.moonglass_unlocked,{journey:s.quality.journey});const gateGold=s.quality.journey.gold;await shot('journey-08-gate-ready');
  await tap('hud_context');await wait('actual gate unlock',s=>s.quality.journey.moonglass_unlocked);s=await state();check('gate-paid-and-opened',s.quality.journey.gold<gateGold,{before:gateGold,after:s.quality.journey.gold});await shot('journey-09-first-frontier');
 });
 await group('actual-touch-finale-to-Deep',async()=>{
  await closeModal();await command('quality_finale',{action:'setup'});await ready();
  let s=await state();check('finale-prerequisites-only',s.phase==='deepheart'&&!s.quality.finale.victory&&!s.quality.finale.conclusion,{finale:s.quality.finale});
  for(const seal of ['mossvein','moonglass','emberdeep','starfall']){
   await command('quality_finale',{action:'seal',seal});await wait('seal context '+seal,s=>s.quality.finale.context==='deepheart_seal:'+seal);
   await heldMineUntil('real mining opens '+seal,s=>s.quality.finale.seal_state[seal].opened,45000);
   s=await state();check(seal+'-opened-by-hits',s.quality.finale.seal_state[seal].hits>0,{seal:s.quality.finale.seal_state[seal]});await shot('finale-seal-'+seal);
  }
  await command('quality_finale',{action:'core'});await wait('core context',s=>s.quality.finale.context==='deepheart_core');await shot('finale-core-ready');
  await tap('hud_context');await wait('real finale conclusion',s=>s.quality.finale.victory&&s.quality.finale.conclusion,20000);
  for(const viewport of [{width:667,height:375},{width:844,height:390},{width:932,height:430}]){
   s=await conclusionLayout(viewport);
   const geometry=s.quality.finale.geometry;
   check('conclusion-pauses-player-'+viewport.width,!s.player_controls_enabled&&s.quality.finale.conclusion,{phase:s.phase});
   check('conclusion-card-contained-'+viewport.width,containsRect(geometry.viewport,geometry.card),{geometry});
   check('conclusion-text-and-stats-contained-'+viewport.width,geometry.labels.length>0&&geometry.labels.every(label=>label.visible&&containsRect(geometry.viewport,label.rect)&&containsRect(geometry.card,label.rect)&&label.visible_lines>=label.lines),{labels:geometry.labels});
   check('conclusion-both-actions-contained-'+viewport.width,geometry.buttons.length===2&&geometry.buttons.every(button=>button.visible&&!button.disabled&&containsRect(geometry.viewport,button.rect)&&containsRect(geometry.card,button.rect)),{buttons:geometry.buttons});
   await shot('finale-conclusion-'+viewport.width);
  }
  await conclusionLayout({width:844,height:390});await tap('conclusion_to_hub');await wait('real conclusion returns Hub',s=>s.phase==='hub'&&!s.quality.finale.conclusion&&s.quality.finale.conclusion_seen);await ready();await shot('finale-returned-Hub');
  await command('quality_finale',{action:'elevator'});await wait('Hub Deep elevator',s=>s.hub_context==='deepElevator');await tap('hud_context');await wait('real elevator reaches Deep',s=>s.phase==='endless');await ready();await shot('finale-first-Deep');
 });
 for(const [label,mine,depth,mining] of [['surface','surface',0,false],['depth','mossMine',2,true],['Deep','endless',1,true]])await group('performance-'+label,async()=>{
  await closeModal();if(mine==='surface')await command('surface');else await command('maps_fixture',{mine,depth});await ready();await profile(label,mining);
 });
 check('runtime-errors-absent',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)),{});
}catch(e){failures.push({group:'startup-or-global',error:String(e.stack||e)});console.error(e);try{await shot('fatal-failure');}catch{}}
finally{report.passed=failures.length===0;report.browser=browser.version();report.fixture_limits='Only player placement and declared purchase gold are seeded in the fresh journey; finale seeds prerequisites and position while seals, activation, conclusion and Deep entry use actual touch; mining targets, damage, mined cargo, sale, equipment upgrades and gate actions execute production code. Performance uses Mac hosted GPU with review observations, not a physical iPhone.';save();await context.close();await browser.close();await new Promise(r=>server.close(r));}
if(failures.length)process.exitCode=1;
