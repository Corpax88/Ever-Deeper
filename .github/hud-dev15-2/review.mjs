import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.2',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname,file=path.resolve(web,'.'+name);
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-skills-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
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
  await shot('skills-open-'+label);await tap('skills_close');await ready();
 }
 await page.setViewportSize({width:844,height:390});await delay(700);
 await command('moss',{direction:'right'});await ready();await hudCheck('moss-844');
 await mine('touch-mining-after-menu');
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
 console.log('SKILLS_RENDERED_GAMEPLAY_PASSED');
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.CANDIDATE_SOURCE||process.env.GITHUB_SHA,validation_commit:process.env.GITHUB_SHA,version,files,runtime,checks,physical_iphone_verified:false,fixture:'Explicit named fixture; observed UI bounds and the actual joystick movement zone drive browser touch. Only comparison progression and fatigue are seeded. New Game, menus, movement and mining use ordinary game paths.'},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
