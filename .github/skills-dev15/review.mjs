import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
 await tap('new_game');await ready();await shot('01-new-game');
 await command('surface');await mine('02-surface-touch');
 // Actual held virtual joystick: travel, earned XP, drain and release.
 let before=await state(),v=page.viewportSize(),p={x:v.width*.23,y:v.height*.68},r=before.buttons.joystick;
 // FloatingJoystick's full-screen Control accepts movement only inside the
 // left 46%, below 36% height. Its Control center is outside that active zone.
 await touch('touchStart',p);await touch('touchMove',{x:p.x,y:p.y+40});await delay(2500);await touch('touchEnd');
 const moved=await state();check('actual-joystick-trains-and-drains',moved.position[1]>before.position[1]+5&&moved.skill_xp.running>before.skill_xp.running&&moved.stamina<before.stamina,{before,after:moved});
 await delay(2000);const rested=await state();check('active-rest-recovers',rested.stamina>moved.stamina,{before:moved,after:rested});
 await tap('hud_menu');await wait('skills opens',s=>s.skills_open&&s.menu);await shot('03-earned-skills');
 await command('skills_fixture');await shot('04-approved-skills-844');
 before=await state();await delay(1500);let after=await state();check('menu-freezes-stamina-and-training',JSON.stringify(before.skill_xp)===JSON.stringify(after.skill_xp),{before,after});
 await tap('map');await wait('map opens',s=>s.map_open);await shot('05-map-844');
 await page.setViewportSize({width:667,height:375});await delay(700);after=await state();
 check('embedded-map-survives-resize',after.map_rect[0]===32&&after.map_rect[1]===94&&after.map_rect[2]>100&&after.map_rect[3]>100,{after});await shot('06-map-667');
 await tap('skills');await wait('skills returns',s=>s.skills_open&&!s.map_open);await shot('07-approved-skills-667');
 after=await state();r=after.buttons.skills_close;check('small-phone-close-target',r[2]/after.viewport[0]*667>=44&&r[3]/after.viewport[1]*375>=44,{rect:r,viewport:after.viewport});
 await tap('skills_close');await ready();
 await page.setViewportSize({width:844,height:390});await delay(500);
 await tap('hud_menu');await wait('reopen for inventory',s=>s.skills_open);await tap('inventory');await wait('inventory opens',s=>s.inventory_open&&!s.skills_open);await shot('08-inventory');await tap('inventory_close');await wait('inventory closes',s=>!s.inventory_open);await ready();
 await tap('hud_menu');await wait('reopen for settings',s=>s.skills_open);await tap('settings');await wait('settings opens',s=>s.settings_open&&!s.skills_open);await shot('09-settings');await tap('settings_back');await wait('settings back',s=>s.menu&&!s.settings_open);await tap('continue');await ready();
 await command('moss',{direction:'right'});await ready();await command('fatigue_fixture');before=await state();check('fatigue-is-mild',before.effort>=.75&&before.effort<.8,{before});await mine('10-exhausted-moss-touch');
 await command('endless',{direction:'right'});await mine('11-endless-touch');
 await command('moss',{direction:'right'});await ready();await page.keyboard.down('Space');await wait('held mining before menu',s=>s.mining);await tap('hud_menu');await page.keyboard.up('Space');before=await wait('menu cancels held mining',s=>s.skills_open&&!s.mining);await delay(1200);after=await state();check('open-during-mining-pauses-damage',before.health===after.health&&before.skill_xp.mining===after.skill_xp.mining&&before.stamina===after.stamina,{before,after});
 await tap('skills_close');await ready();before=await state();await page.keyboard.down('ArrowDown');await delay(400);await page.keyboard.up('ArrowDown');after=await state();check('resume-restores-movement',after.position[1]>before.position[1]+2&&!after.mining,{before,after});await shot('12-resumed-game');
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
 console.log('SKILLS_RENDERED_GAMEPLAY_PASSED');
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.CANDIDATE_SOURCE||process.env.GITHUB_SHA,validation_commit:process.env.GITHUB_SHA,version,files,runtime,checks,physical_iphone_verified:false,fixture:'Explicit named fixture; observed UI bounds and the actual joystick movement zone drive browser touch. Only comparison progression and fatigue are seeded. New Game, menus, movement and mining use ordinary game paths.'},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
