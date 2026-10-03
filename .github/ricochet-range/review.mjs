import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const reference=process.env.NODE_ASSETS_REFERENCE==='1';
const version='1.0.0-dev.15.53',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true,});
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

 for(const viewport of [{width:844,height:390},{width:667,height:375},{width:932,height:430}]){
  await page.setViewportSize(viewport);
  await command('mods_preview',{resource:'phasecrystal',amount:100000});await delay(250);
  check('preview-visible-'+viewport.width,(await state()).treasury_goal.open,{});await shot('preview-ricochet-'+viewport.width);
  await tap('treasury_close');await ready();
 }
 await page.setViewportSize({width:844,height:390});
 await command('ricochet_range_fixture');await ready();await delay(300);
 const p=await point('hud_mine'),begin=(await state()).drill_mods.player;
 await shot('range-before');await touch('touchStart',p);
 for(let frame=0;frame<12;frame++){await delay(100);await shot('long-flight-'+String(frame).padStart(2,'0'));}
 await wait('three distant rocks cleared',s=>s?.ricochet?.range_floor?.length===3&&s.ricochet.range_floor.every(Boolean));
 await touch('touchEnd',p);await delay(200);
 let s=await state();check('actual-touch-three-long-range-hits',s.drill_mods.effect.five.hits===3,{effect:s.drill_mods.effect.five,rocks:s.ricochet.range_floor});
 check('no-auto-movement',Math.hypot(s.drill_mods.player[0]-begin[0],s.drill_mods.player[1]-begin[1])<2,{});
 await command('ricochet_range_fixture');await ready();await delay(200);
 await touch('touchStart',p);await wait('projectile in flight',s=>s?.drill_mods?.effect?.five?.projectile);await touch('touchEnd',p);await delay(200);
 const afterRelease=(await state()).drill_mods.effect.five.hits;await delay(500);
 check('release-cancels-long-flight',(await state()).drill_mods.effect.five.hits===afterRelease&&!(await state()).drill_mods.effect.five.projectile,{});
 for(const [skin,gear] of [['crusher','crusher'],['comet','comet'],['crownseeker','crown'],['deepheart','ember']]){
  let s=await command('ricochet_skin',{skin,mod:false});
  check('same-frame-workshop-skin-'+skin,s.ricochet.skin_check.accepted&&s.ricochet.skin_check.shown===gear&&!s.ricochet.skin_check.failed,{skin:s.ricochet.skin_check});await shot('skin-'+skin);
  s=await command('ricochet_skin',{skin,mod:true});
  check('mod-preserves-saved-skin-'+skin,s.ricochet.saved_skin===skin&&s.ricochet.skin_check.mod_active,{skin:s.ricochet.skin_check});
  await shot('mod-'+skin);
  s=await command('ricochet_skin',{skin,mod:false});
  check('immediate-skin-restore-'+skin,s.ricochet.skin_check.shown===gear&&!s.ricochet.skin_check.mod_active,{skin:s.ricochet.skin_check});await shot('restored-'+skin);
 }
 await command('mods_save');await command('mods_reload');
 check('saved-skin-survives-reload',(await state()).ricochet.saved_skin==='deepheart',{});
} catch(e){failed=e.stack||String(e);console.error(failed);}
finally{
 await context.close();await browser.close();server.close();
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,failure:failed,version,files,source:process.env.GITHUB_SHA,runtime,checks},null,2));
 if(failed)process.exitCode=1;
}

