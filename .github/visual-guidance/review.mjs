import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version=process.env.EXPECTED_VERSION||'1.0.0-dev.15.58';
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
 if(name==='/'||name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-skills-browser','--guidance-review','--guidance-persistence','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(60000);
const checks=[],messages=[],images=[],failures=[];let runtime=null,id=0;
const report={version,files,source:process.env.GITHUB_SHA,base_source:'deaa7088d75d473b0c16951bc05f19c4db7800c4',physical_iphone:false,checks,images,failures};
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

async function views(label){
 for(const v of [{width:667,height:375},{width:844,height:390},{width:932,height:430}]){
  await page.setViewportSize(v);await delay(700);const s=await state();
  check(label+'-text-fits-'+v.width,Object.values(s.guidance.texts).every(t=>t.fits),{texts:s.guidance.texts});
  check(label+'-skip-in-view-'+v.width,containsRect([0,0,...s.viewport],s.guidance.skip),{skip:s.guidance.skip});
  await shot(label+'-'+v.width);
 }
 await page.setViewportSize({width:844,height:390});await delay(600);
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('guide fixture ready',s=>s?.version===version&&s?.guidance,180000);
 await tap('new_game');await ready();await wait('first guide',s=>s.guidance.running&&s.guidance.step===0);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio,userAgent:navigator.userAgent};});
 check('actual-Apple-GPU',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 check('touch-help-not-keyboard',(await state()).guidance.touch_mode);
 await views('01-move');
 await delay(11000);check('eleven-seconds-idle-does-not-complete',(await state()).guidance.step===0);
 await page.keyboard.press('Escape');await wait('pause',s=>s.menu);await tap('continue');await ready();
 check('pause-retains-move',(await state()).guidance.step===0);
 await walk(1,s=>s.guidance.step===1,'touch movement completes first task');
 await command('quality_journey',{step:'entrance'});await wait('DESCEND context',s=>s.guidance.context==='DESCEND');
 check('guide-target-and-label-match',(await state()).guidance.world_target==='surface:mine:mossMine'&&(await state()).guidance.goal.action_text==='Tap DESCEND');
 await shot('02-descend');await tap('hud_context');await wait('mine entered',s=>s.phase==='mine'&&s.guidance.step===2);await ready();
 await command('guidance_record_only');await delay(400);check('mined-counter-is-not-pickup',(await state()).guidance.step===2);
 await command('quality_journey',{step:'target'});check('real-generated-ore',(await state()).quality.journey.result.natural_target_found);
 await views('03-mine');
 const before=(await state()).guidance.mined;
 await heldMineUntil('actual mineral breaks',s=>s.guidance.mined>before);
 if(!(await state()).guidance.cargo)await walk(1,s=>s.guidance.cargo>0,'walk collects actual drop');
 await wait('actual pickup reaches Bag task',s=>s.guidance.step===3);
 await views('04-bag');await tap('hud_bag');await wait('Bag teaches without losing progress',s=>s.inventory_open&&s.guidance.step===4&&s.guidance.running);
 await shot('05-open-bag');await tap('inventory_close');await ready();await wait('upgrade lesson returns',s=>s.guidance.visible&&s.guidance.step===4);
 await views('06-upgrade');
 await page.keyboard.press('Escape');await wait('saved menu',s=>s.menu);await delay(1500);
 await page.reload({waitUntil:'domcontentloaded',timeout:180000});await wait('reloaded menu',s=>s?.guidance&&s.menu,180000);await tap('continue');await ready();await wait('persistent exact lesson',s=>s.guidance.step===4&&s.guidance.visible);await shot('07-reloaded-lesson');
 await command('quality_journey',{step:'exit'});await wait('exit',s=>s.quality.journey.exit_context);await tap('hud_context');await wait('surface',s=>s.phase==='surface');
 await command('quality_journey',{step:'forge'});await wait('Forge action and attention handoff',s=>s.guidance.context==='FORGE'&&s.guidance.local_action);await shot('08-forge-handoff');
 await tap('hud_context');await wait('forge shop',s=>s.shop_open);await tap('shop_primary');await wait('earned upgrade',s=>s.guidance.pickaxe===2);await closeModal();await ready();await wait('guide truly completed',s=>!s.guidance.running&&s.guidance.seen);await shot('09-complete');
 await page.keyboard.press('Escape');await wait('settings menu',s=>s.menu);await tap('menu_settings');await tap('settings_controls');await shot('10-replay-entry');await tap('settings_controls');await ready();await wait('voluntary advanced replay',s=>s.guidance.running&&s.guidance.replay&&s.guidance.step===0);
 await command('guidance_resume');await ready();check('advanced-replay-resumes',(await state()).guidance.running&&(await state()).guidance.replay);
 await tap('guidance_skip');await wait('skip complete',s=>!s.guidance.running);check('skip-preserves-expedition',(await state()).guidance.pickaxe===2);
 check('no-runtime-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failures.push({group:'guidance',error:String(e.stack||e)});console.error(e);try{await shot('failure');}catch{}}
report.passed=failures.length===0&&checks.length>0&&checks.every(c=>c.passed);save();
await browser.close();await new Promise(r=>server.close(r));process.exit(report.passed?0:1);
