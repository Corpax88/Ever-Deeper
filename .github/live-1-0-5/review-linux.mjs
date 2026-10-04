import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,legacy]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
let servingLegacy=true;
const version='1.0.5',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname,file=path.resolve(servingLegacy?legacy:web,'.'+name);
 if(!file.startsWith(path.resolve(servingLegacy?legacy:web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-production-browser','--expected-version='+(servingLegacy?'1.0.4':version)];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
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
async function shot(name){await page.screenshot({path:path.join(output,name+'.jpg'),quality:90,timeout:60000});checks.push({name,passed:true,state:await state()});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}

async function ready(){return wait('active game',s=>!s?.menu&&s?.game_started&&s.player_controls_enabled);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('old LIVE fixture ready',s=>s?.version==='1.0.4'&&s.buttons,180000);
 await tap('new_game');await ready();await command('skills_fixture');await command('checkpoint');await delay(1500);
 const oldSave=await state();check('old-live-save-created',oldSave.save_file_present&&oldSave.save_error===0&&!oldSave.dev_feature,{state:oldSave});
 servingLegacy=false;await page.reload({waitUntil:'domcontentloaded',timeout:180000});
 const migrated=await wait('existing LIVE save migrated',s=>s?.version===version&&s.save_available&&s.menu,180000);
 check('existing-live-progress-preserved',migrated.seed===oldSave.seed&&migrated.gold===oldSave.gold&&migrated.skills.every((s,i)=>s.level===oldSave.skills[i].level&&Math.abs(s.ratio-oldSave.skills[i].ratio)<.0001),{oldSave,migrated});
 check('production-flavor',!migrated.dev_feature&&!migrated.dev_menu_present&&!migrated.dev_menu_resource&&!migrated.render_probe_resource&&migrated.save_path==='user://ever_deeper_run_v3.sav'&&migrated.user_dir_name==='Ever Deeper- Godot Production Port'&&!migrated.release_label.includes('DEV'),{state:migrated});
 await shot('production-migrated-menu');await tap('continue');await ready();await shot('production-continued-save');
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('graphical-renderer',runtime.renderer&&!runtime.lost,{runtime});
 await command('surface');
 for(const [width,height] of [[844,390],[667,375],[932,430]]){
  await page.setViewportSize({width,height});await delay(900);
  let s=await state();
  check('hud-layout-'+width,!s.hud_guide_visible&&s.hud_menu_icon==='res://assets/ui/skills/icons/skills-knot-blue-steel-v1.png'&&inside(s.buttons.hud_menu,s)&&inside(s.buttons.hud_mole,s)&&!overlap(s.buttons.hud_menu,s.buttons.hud_mole)&&!overlap(s.buttons.hud_mole,s.hud_gold),{state:s});
  await shot('hud-'+width);
  await tap('hud_menu');await wait('Skills opened',s=>s.skills_open&&s.menu);await shot('skills-'+width);
  await tap('skills_close');await ready();
  await tap('hud_mole');await wait('Mole opened',s=>s.mole_open);await tap('mole_close');await ready();
  check('touch-routes-'+width,!(await state()).hud_guide_visible,{});
 }
 await page.setViewportSize({width:844,height:390});await delay(800);
 await command('moss',{direction:'right',gear:'worn'});await ready();
 let s=await state();check('compass-hidden-in-mine',!s.hud_guide_visible,{});await shot('moss-hud');
 const before=await state(),v=page.viewportSize(),p={x:before.mine_button[0]/before.viewport[0]*v.width,y:before.mine_button[1]/before.viewport[1]*v.height};
 await touch('touchStart',p);const hit=await wait('real mining',s=>s.impact>=before.impact+2&&s.health<before.health);await touch('touchEnd');await wait('release',s=>!s.mining);
 check('mining-after-menu',hit.impact_target_valid,{before,hit});
 await command('checkpoint');await delay(1500);const saved=await state();
 check('production-save-written',saved.save_file_present&&saved.save_error===0,{state:saved});
 await page.reload({waitUntil:'domcontentloaded',timeout:180000});
 const restored=await wait('saved production menu',s=>s?.version===version&&s.save_available&&s.menu,180000);
 check('production-save-reloaded',restored.seed===saved.seed&&restored.gold===saved.gold&&restored.skill_xp.mining===saved.skill_xp.mining&&!restored.dev_menu_present,{saved,restored});
 await tap('continue');await ready();await shot('production-reloaded-game');
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,runtime,checks,platform:'Linux software renderer; loader/migration functional checks only',physical_iphone_verified:false},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
