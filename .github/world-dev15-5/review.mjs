import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.5',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname,file=path.resolve(web,'.'+name);
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-wayfarer-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(90000);
const checks=[],messages=[];let failed=null,runtime=null,id=0;
const save=()=>fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(label,predicate,timeout=30000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(150);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
function check(name,ok,details){checks.push({name,passed:!!ok,...details});save();if(!ok)throw Error(name);}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function point(name){const s=await state(),v=page.viewportSize(),r=s.buttons[name];if(!r)throw Error('Missing button '+name);return {x:(r[0]+r[2]/2)/s.viewport[0]*v.width,y:(r[1]+r[3]/2)/s.viewport[1]*v.height};}
async function tap(name){const p=await point(name);await page.touchscreen.tap(p.x,p.y);await delay(250);}
async function touch(type,p){await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});}
async function shot(name){await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});checks.push({name,passed:true,state:await state()});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}
async function hudCheck(label){
 const s=await state(),v=page.viewportSize(),keys=['hud_menu','hud_guide','hud_mole','hud_bag','hud_mine'];
 const rects=keys.map(k=>s.buttons[k]);
 check('larger-gameplay-controls-'+label,rects.every(r=>inside(r,s)&&r[2]/s.viewport[0]*v.width>=60&&r[3]/s.viewport[1]*v.height>=60)&&rects.every((r,i)=>rects.slice(i+1).every(q=>!overlap(r,q))),{buttons:s.buttons,viewport:s.viewport,css:v});
 check('hud-top-and-context-clear-'+label,!overlap(s.buttons.hud_mole,s.hud_gold)&&!overlap(s.hud_gold,s.hud_goal)&&!overlap(s.hud_gold,s.hud_map)&&(!s.hud_context_visible||!overlap(s.hud_context,s.buttons.hud_bag)),{state:s});
 await shot('hud-'+label);
}
async function statTips(){
 for(const [stat,expected] of [['mining','8.1%'],['running','4.2%'],['carrying','9.0%'],['prospecting','No extra loot bonus'],['stamina','75%']]){
  const p=await point('stat_'+stat);await page.mouse.move(p.x,p.y);
  const s=await wait('hover '+stat,s=>s.tooltip_visible&&s.tooltip_id===stat);
  check('hover-stat-'+stat,s.tooltip_text.includes(expected)&&inside(s.tooltip_rect,s),{text:s.tooltip_text,rect:s.tooltip_rect});
  await shot('tooltip-'+stat+'-844');
  await page.mouse.move(10,200);await wait('leave '+stat,s=>!s.tooltip_visible);
 }
}
async function longPressTip(label){
 const p=await point('stat_stamina');await touch('touchStart',p);
 const s=await wait('long press '+label,s=>s.tooltip_visible&&s.tooltip_id==='stamina');
 check('long-press-stat-'+label,inside(s.tooltip_rect,s)&&!overlap(s.tooltip_rect,s.buttons.stat_stamina),{state:s});
 await shot('tooltip-touch-'+label);await delay(900);const q=await point('stat_mining');await touch('touchMove',q);await delay(600);check('held-drag-cancels-tooltip-'+label,!(await state()).tooltip_visible,{});await touch('touchEnd');await wait('release closes tooltip',s=>!s.tooltip_visible);
 await page.touchscreen.tap(p.x,p.y);await delay(700);check('short-tap-has-no-sticky-tooltip-'+label,!(await state()).tooltip_visible,{});
 await touch('touchStart',p);await touch('touchMove',{x:p.x-35,y:p.y});await delay(700);check('drag-cancels-tooltip-'+label,!(await state()).tooltip_visible,{});await touch('touchEnd');
}
async function progressCheck(label){
 const s=await state();
 check('skill-bars-'+label,s.skill_progress.every((p,i)=>{
  const skill=s.skills[i],a=p.level_rect,b=p.xp_rect;
  return p.level_fits&&p.level===String(skill.level)&&p.level_value===skill.level&&Math.abs(p.xp_value-skill.ratio*100)<.001&&!p.numeric_xp&&inside(a,s)&&inside(b,s)&&!overlap(a,b)&&b[1]>a[1]+a[3]&&b[3]<a[3]/2&&Math.abs(a[0]-b[0])<.01&&Math.abs(a[2]-b[2])<.01;
 }),{state:s});
}
async function ready(){return wait('active native game',s=>!s?.menu&&s?.native?.active&&s.native.updates>3);}
async function mine(name){
 const before=await ready(),v=page.viewportSize(),p={x:before.mine_button[0]/before.viewport[0]*v.width,y:before.mine_button[1]/before.viewport[1]*v.height};
 await touch('touchStart',p);
 const hit=await wait(name+' contact',s=>s?.impact>=before.impact+2&&s.health<before.health);
 await touch('touchEnd');await wait(name+' release',s=>!s.mining);
 check(name,hit.impact_target_valid&&hit.skill_xp.mining>before.skill_xp.mining&&hit.stamina<before.stamina+.01,{before,hit});
 await shot(name+'-released');
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('DEV15 fixture loaded',s=>s?.version===version&&s.buttons,240000);
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost()};});
 Object.assign(runtime,{browser:browser.version(),platform:process.platform,video_recording:false});
 check('graphical-mac-renderer',runtime.platform==='darwin'&&runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 await tap('new_game');await ready();await command('surface');
 for (const [width,height,label] of [[844,390,'844'],[667,375,'667'],[900,600,'3-2']]) {
  await page.setViewportSize({width,height});await delay(700);await hudCheck(label);
  await tap('hud_menu');await wait('approved icon opens Skills',s=>s.skills_open&&s.menu);
  check('approved-icon-opens-skills-'+label,!(await state()).developer_tools_visible,{});
  await command('skills_fixture');await progressCheck(label);await shot('skills-open-'+label);await tap('skills_close');await ready();
 }
 await page.setViewportSize({width:844,height:390});await delay(700);
 await tap('hud_menu');await wait('skills for edge cases',s=>s.skills_open);
 await command('skills_edge_fixture');await progressCheck('edges');
 let edge=await state();check('zero-near-full-and-cap',edge.skill_progress[0].level_value===0&&edge.skill_progress[0].xp_value===0&&edge.skill_progress[1].xp_value===99&&edge.skill_progress[2].level_value===100&&edge.skill_progress[2].xp_value===100&&edge.skill_progress[3].level_value===99&&edge.skill_progress[3].xp_value>99,{state:edge});
 await shot('skills-edges-844');await command('skill_level_up');
 edge=await state();check('xp-rollover',edge.skill_progress[1].level_value===1&&edge.skill_progress[1].xp_value===0&&edge.skill_progress[1].level==='1',{state:edge});await shot('skills-rollover-844');
 await command('skills_fixture');await statTips();await longPressTip('844');await tap('skills_close');await ready();
 await command('quarry');await ready();
 let q=await wait('relocated mining approach',s=>s.surface_context==='ore_mountain');
 check('relocated-quarry-and-retired-surface-store',q.quarry_position[0]===812&&q.quarry_position[1]===515&&q.quarry_solid&&q.quarry_approach_clear&&q.wayfarer_sprite_count===0&&q.retired_surface_context!=='speedShop',{state:q});
 await shot('quarry-full-844');await mine('relocated-quarry-mining');
 for(const hp of [120,0]){await command('quarry_stage',{hp});await delay(400);await shot('quarry-stage-'+hp);}
 await command('quarry_stage',{hp:360});
 const walkBefore=await state(),vp=page.viewportSize(),stick={x:vp.width*.23,y:vp.height*.68};
 await touch('touchStart',stick);await touch('touchMove',{x:stick.x+60,y:stick.y+15});
 const moved=await wait('quarry road walking',s=>s.position[0]>walkBefore.position[0]+55);await touch('touchEnd');
 check('road-walkable-after-relocation',moved.position[0]>walkBefore.position[0]+55&&!moved.menu,{before:walkBefore,after:moved});await shot('quarry-road-after-walking');
 await page.setViewportSize({width:667,height:375});await command('quarry');await ready();await shot('quarry-full-667');
 await page.setViewportSize({width:844,height:390});
 for(const mineId of ['mossMine','moonMine','emberMine','starMine']){
  await command('retired_depth_shop',{mine:mineId});await ready();await delay(600);const s=await state();
  check('no-wayfarer-'+mineId,s.phase==='depth'&&s.depth_context!=='depthWayfarer'&&!s.menu,{state:s});await shot('camp-'+mineId);
 }
 await command('moss',{direction:'right'});await ready();await hudCheck('moss-844');
 await mine('touch-mining-after-menu');
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
 console.log('SKILLS_RENDERED_GAMEPLAY_PASSED');
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.CANDIDATE_SOURCE||process.env.GITHUB_SHA,validation_commit:process.env.GITHUB_SHA,version,files,runtime,checks,physical_iphone_verified:false,fixture:'Explicit named fixture; observed UI bounds and the actual joystick movement zone drive browser touch. Comparison progression, fatigue and two explicit mountain damage-stage images are seeded. Retired shop locations are explicit fixtures; mountain mining and road movement use actual touch. New Game, menus, movement and mining use ordinary game paths.'},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
