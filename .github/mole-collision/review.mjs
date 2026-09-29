import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.25',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
async function shot(name){await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});checks.push({name,passed:true,state:await state()});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}

async function ready(){return wait('active game',s=>!s?.menu&&s?.game_started&&s.player_controls_enabled&&((s.native?.active&&s.native.updates>3)||(s.drill_level>0&&s.world_active)));}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('fixture ready',s=>s?.version===version&&s.buttons,180000);
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('graphical-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 for(const scenario of ['moss_ore','moss_wall','depth_ore','endless_ore','surface']){
  await command('mole_fixture',{scenario});await ready();await delay(600);
  let before=await state();
  check('target-'+scenario,before.work.remaining&&Object.values(before.work.checks).every(Boolean),{work:before.work});
  const v=page.viewportSize(),p={x:before.work.target[0]/before.viewport[0]*v.width,y:before.work.target[1]/before.viewport[1]*v.height};
  check('target-on-screen-'+scenario,p.x>0&&p.y>0&&p.x<v.width&&p.y<v.height,{p});
  await page.touchscreen.tap(p.x,p.y);
  await wait('mole starts '+scenario,s=>s.work?.mole.action==='work',15000);
  before=await state();const expectedHits=scenario==='surface'?Math.ceil(before.health/before.work.power):3;let started=Date.now();await delay(850);
  check('no-instant-break-'+scenario,(await state()).work.remaining&&(await state()).work.mole.work_hits===0,{});
  await wait('mole finishes '+scenario,s=>!s.work.remaining,40000);
  const after=await state();
  check('mined-while-hero-idle-'+scenario,after.work.mole.work_hits===expectedHits&&!after.mining&&after.impact===before.impact&&after.skill_xp.mining===before.skill_xp.mining,{before,after,expectedHits,elapsed:Date.now()-started});
  await shot('mole-finished-'+scenario);
 }
 await command('mole_fixture',{scenario:'moss_ore'});await ready();await delay(500);
 let before=await state(),v=page.viewportSize();
 await page.touchscreen.tap(before.work.target[0]/before.viewport[0]*v.width,before.work.target[1]/before.viewport[1]*v.height);
 await wait('manual job started',s=>s.work.mole.action==='work');await shot('mole-mining');
 await tap('hud_menu');await wait('menu pauses companion',s=>s.skills_open);const paused=await state();await delay(2400);
 check('menu-pauses-job',(await state()).work.mole.work_hits===paused.work.mole.work_hits,{});
 await tap('skills_close');await ready();const stop=(await state()).work.cancel,sv=page.viewportSize(),ss=await state();await page.touchscreen.tap(stop[0]/ss.viewport[0]*sv.width,stop[1]/ss.viewport[1]*sv.height);await delay(300);const recalled=await state();await delay(2600);
 check('ground-tap-stops-job',(await state()).work.mole.mode!=='work'&&(await state()).work.mole.work_hits===recalled.work.mole.work_hits&& (await state()).work.remaining,{});
 await command('mole_fixture',{scenario:'moss_ore'});await ready();await delay(400);before=await state();v=page.viewportSize();
 const mine={x:before.mine_button[0]/before.viewport[0]*v.width,y:before.mine_button[1]/before.viewport[1]*v.height},start=Date.now();
 await touch('touchStart',mine);await wait('hero finishes same ore',s=>!s.work.remaining);await touch('touchEnd');
 check('hero-faster',Date.now()-start<before.work.period*3000&& (await state()).skill_xp.mining>before.skill_xp.mining,{heroMs:Date.now()-start,moleMinimumMs:before.work.period*3000});await shot('hero-mining');
 await command('mole_fixture',{scenario:'moss_wall'});await ready();await delay(500);
 await command('mole_shake');await wait('Earthshaker still fires',s=>s.work.mole.shake_cooldown>0,10000);
 check('earthshaker-preserved',(await state()).work.mole.work_hits===0,{});
 await command('mole_fixture',{scenario:'moss_ore'});await ready();await command('mole_auto');
 await wait('automatic work preserved',s=>s.work.mole.work_hits>=2,25000);
 check('automatic-work-preserved',!(await state()).mining,{});
 for(const mine_id of ['mossMine','moonMine','emberMine','starMine']){
  await command('ore_respawn_fixture',{mine_id});await ready();
  const trapped=await state();
  check('respawn-collision-'+mine_id,Object.keys(trapped.ore_escape.checks).length===8&&Object.values(trapped.ore_escape.checks).every(Boolean),{fixture:trapped.ore_escape});
  await shot('respawn-under-mole-'+mine_id);
  await command('ore_escape');await wait('walk out of respawn '+mine_id,s=>s.ore_escape.remaining<10,12000);
  const escaped=await state();check('escaped-'+mine_id,escaped.ore_escape.distance>90,{escaped:escaped.ore_escape});
  await shot('escaped-'+mine_id);
 }
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,flavor,files,runtime,checks,physical_iphone_verified:false},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;

