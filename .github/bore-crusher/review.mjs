import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const reference=process.env.NODE_ASSETS_REFERENCE==='1';
const version='1.0.0-dev.15.46',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true,});
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
async function shot(name){await page.screenshot({path:path.join(output,name+'.jpg'),quality:95,timeout:60000});const s=await state();if(s.treasury.inside)check('clear-treasury-hud-'+name,!s.hud_goal_visible,{});checks.push({name,passed:true,state:s});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}

async function ready(){return wait('active game',s=>!s?.menu&&s?.game_started&&s.player_controls_enabled&&s.actual_map?.world_active);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('fixture ready',s=>s?.version===version&&s.buttons,180000);
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('graphical-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 for(const resource of ['burrowsteel','prismite']){
  for(const amount of [0,56000,100000]){
   await command('mods_preview',{resource,amount});
   check('claim-gate-'+resource+amount,(await state()).treasury_goal.claim_disabled===(amount<100000),{});
   await shot(resource+'-'+amount);
   await tap('treasury_pin');check('pin-'+resource+amount,(await state()).treasury_goal.saved.pinned===resource,{});
   await tap('treasury_pin');
   if(amount===100000){await tap('treasury_claim');check('claim-'+resource,(await state()).treasury_goal.saved[(resource==='prismite'?'laser':'bore_rush')+'_claimed'],{});await shot(resource+'-claimed');}
   await tap('treasury_close');await ready();
  }
 }
 await command('mods_mining',{mod:'laser'});await ready();await delay(400);
 let s=await state();check('laser-button-visible',s.drill_mods.laser_visible&&inside(s.buttons.laser,s)&&!overlap(s.buttons.laser,s.buttons.hud_mine),{});
 const mine=await point('hud_mine');await touch('touchStart',mine);await delay(900);await shot('laser-mining');await touch('touchEnd',mine);
 s=await state();check('laser-impacts',s.drill_mods.effect.impacts>0,{});
 await tap('laser');check('laser-toggle-off',(await state()).drill_mods.laser_text==='LASER: OFF',{});
 await tap('laser');check('laser-toggle-on',(await state()).drill_mods.laser_text==='LASER: ON',{});
 for(const viewport of [{width:667,height:375},{width:932,height:430}]){
  await page.setViewportSize(viewport);await delay(450);s=await state();check('laser-layout-'+viewport.width,inside(s.buttons.laser,s)&&!overlap(s.buttons.laser,s.buttons.hud_mine)&&!overlap(s.buttons.laser,s.buttons.hud_bag),{});await shot('laser-layout-'+viewport.width);
  await command('mods_preview',{resource:'prismite',amount:100000});await shot('preview-'+viewport.width);await tap('treasury_close');await ready();
 }
 await command('mods_mining',{mod:'bore_rush'});await delay(400);
 const before=(await state()).drill_mods.player;const bore=await point('hud_mine');await touch('touchStart',bore);await delay(1400);await shot('bore-moving');await touch('touchEnd',bore);await delay(150); // QA state is sampled every 100ms; observe the released frame.
 s=await state();check('bore-advances',s.drill_mods.player[0]>before[0]+40,{});const stopped=s.drill_mods.player;await delay(350);s=await state();check('release-stops-bore',Math.hypot(s.drill_mods.player[0]-stopped[0],s.drill_mods.player[1]-stopped[1])<2,{stopped,current:s.drill_mods.player});
 for(const fixture of [{site:false,dx:1,dy:0},{site:false,dx:0,dy:1},{site:true,dx:1,dy:0},{site:true,dx:0,dy:-1}]){
  await command('mods_bore_flow',{...fixture,crusher:true});await ready();await delay(300);
  const begin=(await state()).drill_mods.player,p=await point('hud_mine'),label=(fixture.site?'boost':'offcentre')+'-'+fixture.dx+'-'+fixture.dy;
  await touch('touchStart',p);await delay(450);await shot('bore-'+label);check('crusher-pose-'+label,(await state()).native?.gear==='crusher'&&(await state()).native?.bore_weight>.99,{});await delay(1800);await touch('touchEnd',p);await delay(150);
  const end=(await state()).drill_mods.player,travel=(end[0]-begin[0])*fixture.dx+(end[1]-begin[1])*fixture.dy;
  check('bore-flow-'+label,travel>(fixture.site?260:160),{begin,end,travel});
  await delay(300);const released=(await state()).drill_mods.player;
  check('bore-flow-release-'+label,Math.hypot(released[0]-end[0],released[1]-end[1])<2,{});
 }
 await command('mods_mining',{mod:'laser'});await ready();await delay(300);
 const ls=await state(),jr=ls.buttons.joystick,vp=page.viewportSize();
 const joy={x:(jr[0]+jr[2]*.20)/ls.viewport[0]*vp.width,y:(jr[1]+jr[3]*.70)/ls.viewport[1]*vp.height},fire=await point('hud_mine');
 const fingers=async(type,points)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints:points.map(([id,p])=>({id,...p,radiusX:5,radiusY:5,force:1}))});
 await fingers('touchStart',[[1,joy]]);await fingers('touchStart',[[1,joy],[7,fire]]);
 for(let i=0;i<16;i++){
  const angle=i*Math.PI*2/16,dx=Math.cos(angle),dy=Math.sin(angle);
  await fingers('touchMove',[[1,{x:joy.x+32*dx,y:joy.y+32*dy}],[7,fire]]);await delay(200);
  const effect=(await state()).drill_mods.effect,bx=effect.beam_end[0]-effect.beam_start[0],by=effect.beam_end[1]-effect.beam_start[1],dot=(bx*dx+by*dy)/Math.hypot(bx,by);
  check('laser-touch-angle-'+i,effect.firing&&dot>.98,{dot});
  if([2,6,10,14].includes(i))await shot('laser-analogue-'+i);
 }
 await fingers('touchEnd',[]);await delay(200);check('laser-multitouch-release',!(await state()).drill_mods.effect.firing,{});
 await command('mods_save');const saved=(await state()).treasury_goal.saved;await command('mods_reload');check('save-retains-mods',JSON.stringify(saved)===JSON.stringify((await state()).treasury_goal.saved),{});
} catch(e){failed=e.stack||String(e);console.error(failed);}
finally{
 await context.close();await browser.close();server.close();
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,failure:failed,version,files,source:process.env.GITHUB_SHA,runtime,checks},null,2));
 if(failed)process.exitCode=1;
}
