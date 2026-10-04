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
async function map(label){
 await tap('hud_map');await wait('expanded map',s=>s.skills_open&&s.map_open);await shot(label+'-expanded-map');
 const s=await state();check(label+'-map-world-data',s.phase==='surface'?s.actual_map.known.length===4:s.phase==='hub'||s.cartography.terrain,{phase:s.phase,cartography:s.cartography});
 await tap('skills_close');await ready();
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('fixture ready',s=>s?.version===version&&s?.quality,180000);
 await shot('000-first-menu-844');
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio,userAgent:navigator.userAgent};});
 check('real-gpu-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 let previous=0;
 for(const second of [0,1,3,6,10]){await delay((second-previous)*1000);await shot('001-first-run-'+second+'s-844');previous=second;}
 // Prove actual held touch moves the unchanged first-run player.
 const before=(await state()).position;
 const s=await state(),v=page.viewportSize(),r=s.buttons.joystick;
 const p={x:(r[0]+r[2]*.20)/s.viewport[0]*v.width,y:(r[1]+r[3]*.70)/s.viewport[1]*v.height};
 await touch('touchStart',p);await touch('touchMove',{x:p.x+36,y:p.y});await delay(700);await touch('touchEnd',p);
 const after=(await state()).position;
 check('first-run-real-touch-movement',Math.hypot(after[0]-before[0],after[1]-before[1])>10,{before,after});await shot('002-first-run-after-touch-844');
 for(const viewport of [{width:844,height:390},{width:667,height:375},{width:932,height:430}]){
  const w=viewport.width;await page.setViewportSize(viewport);await delay(350);
  await group('menus-'+w,async()=>{
   await closeModal();await command('surface');await ready();await shot('surface-'+w);
   await tap('hud_menu');await wait('skills',s=>s.skills_open);await shot('skills-'+w);
   await tap('settings');await wait('settings',s=>s.settings_open);await shot('settings-'+w);
   await tap('settings_back');await wait('settings parent',s=>s.menu&&!s.settings_open);
   if((await state()).skills_open){await shot('settings-return-skills-'+w);await tap('skills_close');await ready();await command('pause');}
   await shot('pause-menu-'+w);
   await tap('menu_achievements');await delay(300);await shot('achievements-'+w);
   await tap('settings_back');await tap('continue');await ready();
   await command('quality_inventory');await tap('hud_bag');await wait('inventory',s=>s.inventory_open);await shot('inventory-full-'+w);
   await tap('inventory_close');await ready();await tap('hud_mole');await wait('mole journal',s=>s.mole_open);await shot('mole-journal-'+w);
   await tap('mole_close');await ready();
  });
  await group('maps-'+w,async()=>{
   await closeModal();await command('treasury_map_first');await ready();await shot('surface-locked-worlds-'+w);await map('surface-locked-'+w);
   await command('treasury_map_all');await command('surface');await ready();await map('surface-unlocked-'+w);
   for(const [mine,depth] of [['mossMine',1],['mossMine',2],['endless',1]]){
    await command('maps_fixture',{mine,depth});await ready();await delay(250);await shot(mine+'-'+depth+'-'+w);await map(mine+'-'+depth+'-'+w);
   }
  });
  await group('commerce-'+w,async()=>{
   await closeModal();
   for(const family of ['forge','starforge','depth_forge']){
    await command('quality_commerce',{family});await wait(family,s=>s.shop_open);await shot('commerce-'+family+'-'+w);await tap('shop_close');await ready();
   }
   for(const station of ['tool_forge','light_lab','wardrobe','lift_workshop']){
    await command('forge_icon_fixture',{station});await ready();await delay(200);await tap('hud_context');await wait(station,s=>s.shop_open);await shot('commerce-'+station+'-'+w);
    await tap('shop_close');await ready();
   }
  });
  await group('treasury-'+w,async()=>{
   await closeModal();await command('treasury_fixture');await ready();await delay(500);await shot('treasury-approach-'+w);
   await walk(1,s=>s.treasury.inside,'treasury enter');await shot('treasury-inside-entry-'+w);
   await tap('hud_menu');await wait('treasury skills',s=>s.skills_open);await tap('map');await wait('treasury map',s=>s.map_open);await shot('treasury-expanded-map-'+w);await tap('skills_close');await ready();
   await command('treasury_zone');await ready();await walk(1,s=>s.treasury.delivering,'delivery start');await delay(450);await shot('treasury-mixed-flight-'+w);
   for(const [index,amount] of [[0,5000],[3,30000],[26,100000]]){await command('treasury_visual',{index,amount});await delay(250);await shot('treasury-podium-'+index+'-'+amount+'-'+w);}
   await tap('gold_podium');await wait('podium goal',s=>s.treasury_goal.open);await shot('treasury-earned-goal-'+w);await tap('treasury_close');await ready();
   await command('quality_exit');await shot('treasury-exit-approach-'+w);await walk(-1,s=>!s.treasury.inside,'treasury exit');await shot('treasury-returned-'+w);
  });
  await group('previews-'+w,async()=>{
   await closeModal();
   for(const resource of ['wallet_gold','burrowsteel','prismite','rootiron','echo_crystal','phasecrystal','deep_alloy','singularity','copper']){
    await command('mods_preview',{resource,amount:100000});await wait('preview '+resource,s=>s.treasury_goal.open);await delay(180);await shot('mod-preview-'+resource+'-'+w);await tap('treasury_close');await ready();
   }
  });
 }
 await group('other-biomes',async()=>{
  await page.setViewportSize({width:844,height:390});await closeModal();
  for(const mine of ['moonMine','emberMine','starMine'])for(const depth of [1,2]){
   await command('maps_fixture',{mine,depth});await ready();await delay(250);await shot(mine+'-'+depth+'-844');await map(mine+'-'+depth+'-844');
  }
 });
 await group('Deepheart-final-sequence',async()=>{
  await page.setViewportSize({width:844,height:390});await closeModal();
  await command('quality_finale',{action:'setup'});await ready();await shot('finale-01-chamber');
  check('finale-starts-uncompleted',!(await state()).quality.finale.victory&&(await state()).quality.finale.world.opened.length===0,{});
  for(const seal of ['mossvein','moonglass','emberdeep','starfall']){
   await command('quality_finale',{action:'seal',seal});await wait('seal context '+seal,s=>s.quality.finale.context==='deepheart_seal:'+seal);
   const mine=await point('hud_mine');await touch('touchStart',mine);
   try{await delay(300);await shot('finale-02-mining-'+seal);await wait('real seal opens '+seal,s=>s.quality.finale.world.opened.includes(seal),20000);}
   finally{await touch('touchEnd',mine);}
  }
  check('all-four-real-seals-open',(await state()).quality.finale.world.all_open,{});
  await command('quality_finale',{action:'core'});await wait('core available',s=>s.quality.finale.context==='deepheart_core');await shot('finale-03-ready-core');
  await tap('hud_context');await wait('finale starts',s=>s.quality.finale.world.finale_active);await shot('finale-04-attunement');await delay(1500);await shot('finale-05-resonance');
  await wait('real victory conclusion',s=>s.quality.finale.conclusion&&s.quality.finale.victory,10000);
  for(const viewport of [{width:844,height:390},{width:667,height:375},{width:932,height:430}]){
   await page.setViewportSize(viewport);await delay(250);const s=await state();
   for(const name of ['conclusion_to_hub','conclusion_stay']){
    const r=s.buttons[name],size=[r[2]*viewport.width/s.viewport[0],r[3]*viewport.height/s.viewport[1]];
    check('conclusion-'+name+'-44-css-'+viewport.width,size.every(x=>x>=43.95),{size});
   }
   await shot('finale-06-conclusion-'+viewport.width);
  }
  await tap('conclusion_to_hub');await wait('real conclusion returns Hub',s=>s.phase==='hub'&&s.quality.finale.conclusion_seen&&!s.quality.finale.conclusion);await ready();await shot('finale-07-hub-return');
  await command('quality_finale',{action:'elevator'});await wait('postgame elevator context',s=>s.hub_context==='deepElevator');await tap('hud_context');
  await wait('real postgame Deep entry',s=>s.phase==='endless'&&s.quality.finale.endless.active);await ready();await shot('finale-08-Deep-unlocked');
 });
 check('runtime-errors-absent',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)),{});
}catch(e){failures.push({group:'startup-or-global',error:String(e.stack||e)});console.error(e);try{await shot('fatal-failure');}catch{}}
finally{report.passed=failures.length===0;report.browser=browser.version();save();await context.close();await browser.close();await new Promise(r=>server.close(r));}
if(failures.length)process.exitCode=1;
