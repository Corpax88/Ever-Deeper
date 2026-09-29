import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const reference=process.env.NODE_ASSETS_REFERENCE==='1';
const version='1.0.0-dev.15.29',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname,file=path.resolve(web,'.'+name);
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--',flavor==='live'?'--qa-production-browser':'--qa-skills-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
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
async function shot(name){await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});const s=await state();if(s.treasury.inside)check('clear-treasury-hud-'+name,!s.hud_goal_visible,{});checks.push({name,passed:true,state:s});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}

async function ready(){return wait('active game',s=>!s?.menu&&s?.game_started&&s.player_controls_enabled&&((s.native?.active&&s.native.updates>3)||(s.drill_level>0&&s.world_active)));}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('fixture ready',s=>s?.version===version&&s.buttons,180000);
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('graphical-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});


 await command('treasury_fixture');await ready();await shot('01-hub-shop-door');
 await tap('hud_context');await wait('entered treasury',s=>s.treasury.inside);await delay(300);await shot('02-empty-room');
 check('all-resource-bays',(await state()).treasury.bay_count===27,{});
 await command('treasury_zone');
 const observed=await state(),jr=observed.buttons.joystick,vp=page.viewportSize();
 const stick={x:(jr[0]+jr[2]*.20)/observed.viewport[0]*vp.width,y:(jr[1]+jr[3]*.70)/observed.viewport[1]*vp.height};
 await touch('touchStart',stick);await touch('touchMove',{x:stick.x+32,y:stick.y+1});
 await wait('walk onto delivery plate',s=>s.treasury.delivering,8000);await touch('touchEnd',stick);
 const initial={stone:800,copper:400,echo_crystal:180,wallet_gold:2000};
 function conserved(t){return Object.entries(initial).every(([k,n])=>(t.totals[k]||0)+(k==='wallet_gold'?t.wallet:t.cargo[k]||0)===n);}
 await wait('airborne parcels',s=>s.treasury.packets>0);await shot('03-airborne');
 await wait('first resources landed',s=>s.treasury.landings>=2);let partial=(await state()).treasury;
 check('partial-conservation',conserved(partial)&&partial.cargo.stone>0,{partial});await shot('04-partial-delivery');
 await tap('hud_menu');await wait('menu paused',s=>s.skills_open);const paused=(await state()).treasury;await delay(2000);
 check('menu-pauses-delivery',paused.inside&&(await state()).treasury.inside&&JSON.stringify((await state()).treasury.totals)===JSON.stringify(paused.totals),{});
 await tap('skills_close');await wait('menu closed',s=>!s.skills_open);
 await command('treasury_exit_approach');await tap('hud_context');await wait('left treasury',s=>!s.treasury.inside);
 const exited=(await state()).treasury;await delay(1800);
 check('exit-cancels-undelivered',conserved(exited)&&exited.packets===0&&exited.remaining_batches===0&&JSON.stringify(exited.totals)===JSON.stringify((await state()).treasury.totals),{exited});await shot('05-left-with-remainder');
 await command('treasury_door');await tap('hud_context');await wait('returned',s=>s.treasury.inside);
 await command('treasury_save');await command('treasury_restore');let loaded=(await state()).treasury;
 check('save-load-conservation',conserved(loaded)&&JSON.stringify(loaded.totals)===JSON.stringify(exited.totals),{loaded});await shot('06-reloaded-partial');
 await command('treasury_zone');await touch('touchStart',stick);await touch('touchMove',{x:stick.x+32,y:stick.y+1});
 await wait('resume by walking onto plate',s=>s.treasury.delivering,8000);await touch('touchEnd',stick);
 await wait('all deliveries complete',s=>!s.treasury.delivering&&s.treasury.wallet===0,65000);
 let complete=(await state()).treasury;
 check('all-donations-exactly-once',conserved(complete)&&Object.keys(initial).every(k=>complete.totals[k]===initial[k]),{complete});await shot('07-complete');
 await command('treasury_full');await shot('08-mature-all-resources');
 await command('treasury_shop');const wallet=(await state()).treasury.wallet;await tap('hud_context');await delay(400);
 check('hub-shop-earns-gold',(await state()).treasury.wallet>wallet,{});await shot('09-hub-sale');
 for(const event of ['ancient_core','crystal_bloom','unstable_seam']){
  await command('treasury_event',{event});await ready();await delay(300);await shot('event-'+event);
  const before=await state();check('event-active-'+event,before.deep_events.state.kind===event&&before.deep_events.active_here&&before.deep_events.visual_count===15,{event:before.deep_events});
 }
 check('deep-gameplay',true,{scope:'Native core verifies event rewards, expiry, persistence and held mining; rendered event states inspected separately.'});
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,flavor,files,runtime,checks,physical_iphone_verified:false},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
