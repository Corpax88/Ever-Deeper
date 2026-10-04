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
 if(name==='/'||name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-skills-browser','--quality-mod-persistence','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
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
function assertMod(label,skin,earned){
 return state().then(s=>{
  const m=s.quality.mod;
  check(label,m.skin===skin&&m.forge_level===5&&m.selected==='ricochet'&&m.native.active&&m.native.mod_active&&!m.native.failed&&!m.sprite_visible&&!m.tool_visible&&m.five_mode==='ricochet'&&(!earned||m.saved==='ricochet'),{live:m});
 });
}
async function observe(label,skin,earned){
 for(let i=0;i<4;i++){await delay(160);await assertMod(label+'-'+i,skin,earned);}
}
async function circleAndFire(label,skin,earned){
 const s=await state(),r=s.buttons.joystick,v=page.viewportSize();
 const joy={x:(r[0]+r[2]*.20)/s.viewport[0]*v.width,y:(r[1]+r[3]*.70)/s.viewport[1]*v.height},fire=await point('hud_mine');
 const fingers=async(type,points)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints:points.map(([id,p])=>({id,...p,radiusX:5,radiusY:5,force:1}))});
 try{
  await fingers('touchStart',[[1,joy]]);await fingers('touchStart',[[1,joy],[7,fire]]);
  for(let i=0;i<16;i++){
   const angle=i*Math.PI*2/16;
   await fingers('touchMove',[[1,{x:joy.x+32*Math.cos(angle),y:joy.y+32*Math.sin(angle)}],[7,fire]]);
   await delay(180);await assertMod(label+'-turn-'+i,skin,earned);
   if(i===4||i===12)await shot(label+'-turn-'+i);
  }
 }finally{await fingers('touchEnd',[]);}
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('isolated persistent fixture',s=>s?.version===version&&s?.quality?.mod,180000);
 check('fresh-isolated-save',!(await state()).quality.mod.save_available,{live:(await state()).quality.mod});
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('real-gpu-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 await command('quality_mod_setup');await ready();
 const setup=(await state()).quality.mod.result;
 check('real-built-and-paid-forge',setup.built&&setup.forge_level===5&&setup.upgrades.length===4&&setup.upgrades.every(r=>r.ok),{setup});
 for(const earned of [false,true]){
  if(earned){await command('quality_mod_action',{action:'earned'});await ready();}
  for(const skin of ['comet','crusher','crownseeker','deepheart']){
   const label=(earned?'earned-':'dev-')+skin;
   await command('quality_mod_skin',{skin});
   const result=(await state()).quality.mod.result;
   check(label+'-selection-accepted-and-saved',result.accepted&&result.saved&&result.requested===skin&&result.stored===skin,{result});
   await observe(label+'-idle',skin,earned);await shot(label+'-idle');
   await circleAndFire(label,skin,earned);await observe(label+'-release',skin,earned);
   await shot(label+'-released');
   await command('quality_mod_action',{action:'pause'});await command('quality_mod_action',{action:'resume'});await ready();
   await observe(label+'-resume',skin,earned);
   await command('quality_mod_action',{action:'travel'});await ready();
   await observe(label+'-travel',skin,earned);await shot(label+'-travel');
  }
 }
 // Retain the actual boundary observation, then move normally to an interior
 // checkpoint so the reload/unequip captures show the complete hero.
 await shot('earned-before-interior-checkpoint');
 {
  const s=await state(),r=s.buttons.joystick,v=page.viewportSize();
  const joy={x:(r[0]+r[2]*.20)/s.viewport[0]*v.width,y:(r[1]+r[3]*.70)/s.viewport[1]*v.height};
  await touch('touchStart',joy);await touch('touchMove',{x:joy.x,y:joy.y+32});
  try{await wait('walk to interior checkpoint',s=>s.position[1]>=360,10000);}finally{await touch('touchEnd',joy);}
  await delay(450);const framed=await state(),p=framed.quality.mod.hero_screen;
  check('saved-checkpoint-hero-in-frame',p[0]>100&&p[0]<framed.viewport[0]-100&&p[1]>140&&p[1]<framed.viewport[1]-70,{position:framed.position,hero_screen:p});
 }
 await command('quality_mod_action',{action:'checkpoint'});
 check('earned-checkpoint-committed',(await state()).quality.mod.result.saved,{live:(await state()).quality.mod});
 await delay(1800);
 await page.reload({waitUntil:'domcontentloaded',timeout:180000});
 await wait('reloaded-persistent-menu',s=>s?.menu&&s?.quality?.mod,180000);
 const loaded=(await state()).quality.mod;
 check('reload-restored-real-skin-and-earned-mod',loaded.save_available&&loaded.skin==='deepheart'&&loaded.saved==='ricochet'&&['loaded','recovered_backup'].includes(loaded.load_status),{live:loaded});
 await tap('continue');await ready();await observe('earned-reloaded','deepheart',true);await shot('earned-reloaded');
 await command('quality_mod_action',{action:'unequip'});
 await wait('normal workshop tool restored',s=>s?.quality?.mod?.selected===''&&s.quality.mod.native.active&&!s.quality.mod.native.mod_active&&s.quality.mod.tool_visible);
 const off=(await state()).quality.mod;
 check('unequip-restores-selected-workshop-tool',off.skin==='deepheart'&&off.native.gear==='ember'&&off.saved==='',{live:off});
 await shot('normal-deepheart-restored');
 check('runtime-errors-absent',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)),{});
}catch(e){failures.push({group:'ricochet-lifecycle',error:String(e.stack||e)});console.error(e);try{await shot('ricochet-lifecycle-failure');}catch{}}
finally{report.passed=failures.length===0;report.browser=browser.version();save();await context.close();await browser.close();await new Promise(r=>server.close(r));}
if(failures.length)process.exitCode=1;
