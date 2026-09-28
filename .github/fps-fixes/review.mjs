import {webkit} from '@playwright/test';
import {PNG} from 'pngjs';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';

const [web,out]=process.argv.slice(2),worker=process.env.FIXES_WORKER||'1';
fs.mkdirSync(out,{recursive:true});
for(const label of ['baseline','candidate','release'])for(const [name,want] of Object.entries(JSON.parse(fs.readFileSync(path.join(web,label,'manifest.json'))))){
 const bytes=fs.readFileSync(path.join(web,label,name));
 if(bytes.length!==want.size||createHash('sha256').update(bytes).digest('hex')!==want.sha256)throw Error('identity '+label+'/'+name);
}
const server=http.createServer((req,res)=>{
 const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n.endsWith('/')?n+'index.html':n));
 if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});
 if(f.endsWith('index.html')&&!n.startsWith('/release/'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(f).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const report={source:process.env.GITHUB_SHA,worker,stages:[],pairs:[],checks:[],error:null};
function save(){fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));}
function check(label,passed,data={}){report.checks.push({label,passed,...data});save();if(!passed)throw Error(label+' '+JSON.stringify(data));}
function difference(a,b){const x=PNG.sync.read(a),y=PNG.sync.read(b);if(x.width!==y.width||x.height!==y.height)throw Error('dimensions');let changed=0,max=0;for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);}return{changed,max};}
const poses=[['idle',0,0],['idle',0,Math.PI/2],['idle',0,Math.PI],['idle',0,3*Math.PI/2],['mine',.2,0],['mine',.5,Math.PI/2],['mine',.8,Math.PI]];

async function open(label,purpose){
 const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
 await context.addInitScript(()=>{try{localStorage.setItem('ever_deeper_graphics_dev_v1','3');}catch{}});
 const page=await context.newPage(),messages=[],stage={label,purpose,windows:[],captures:[],error:null},index=report.stages.length;
 report.stages.push(stage);let id=0;
 page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,index+'-'+label+'-console.log'),messages.join('\n'));});
 page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
 const state=()=>page.evaluate(()=>({game:window.DEV14_STATE,fixes:window.FIXES_STATE}));
 async function wait(fn){for(let i=0;i<600;i++){const s=await state();if(s?.game?.error||s?.game?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error('Runtime failure '+JSON.stringify(s)+' '+messages.slice(-8).join('\n'));if(fn(s))return s;await delay(150);}throw Error('Game state timeout');}
 async function command(kind,more={}){fs.appendFileSync(path.join(out,'progress.log'),index+' '+kind+' '+JSON.stringify(more)+'\n');const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s?.game?.id===wanted&&s?.fixes?.id===wanted);}
 async function modes(fbo,audio){await page.evaluate(({fbo,audio})=>{window.EVER_DEEPER_FBO.setEnabled(fbo);window.FPS_FIX_AUDIO.setEnabled(audio);},{fbo,audio});await delay(500);}
 async function setup(scene){
  if(scene==='surface')await command('surface_setup');else await command('fixes_mine',{direction:'up'});
  await command('fixes_center');await command('native_setup');await delay(3000);
  if(scene==='mining'){await page.keyboard.down('Space');await wait(s=>s?.fixes?.mining);await delay(3000);}
 }
 async function measure(scene,mode,seconds){
  const before=await command('begin');
  const apiBefore=await page.evaluate(()=>({fbo:window.EVER_DEEPER_FBO?.snapshot(),audio:window.FPS_FIX_AUDIO?.snapshot()}));
  const raf=await page.evaluate(ms=>new Promise(resolve=>{const rows=[],start=performance.now();let previous=start;function tick(now){rows.push(now-previous);previous=now;if(now-start>=ms)resolve({elapsed_ms:now-start,frames:rows.length,intervals_ms:rows});else requestAnimationFrame(tick);}requestAnimationFrame(tick);}),seconds*1000);
  const after=await command('end'),apiAfter=await page.evaluate(()=>({fbo:window.EVER_DEEPER_FBO?.snapshot(),audio:window.FPS_FIX_AUDIO?.snapshot()}));
  const a=before.game.native_info,b=after.game.native_info;
  check('workload-'+index+'-'+stage.windows.length,!!after.game.native.active&&b.stable&&b.updates>a.updates&&b.generations===a.generations&&b.shadow&&b.size[0]===400&&b.size[1]===400&&b.requested_atlas===4096&&after.fixes.depth_prepass===true&&JSON.stringify(a.lights2d)===JSON.stringify(b.lights2d),{scene});
  if(scene==='mining')check('mining-impacts-'+index+'-'+stage.windows.length,after.fixes.impact>=before.fixes.impact+3&&after.fixes.health<before.fixes.health,{before:before.fixes.impact,after:after.fixes.impact});
  if(apiAfter.fbo){
   const hits=(apiAfter.fbo.hits||0)-(apiBefore.fbo.hits||0),unsafe=(apiAfter.fbo.unsafeFallbacks||0)-(apiBefore.fbo.unsafeFallbacks||0);
   check('fbo-active-'+index+'-'+stage.windows.length,unsafe===0&&(apiAfter.fbo.enabled?hits>0:hits===0),{hits,unsafe,enabled:apiAfter.fbo.enabled,lastFallback:apiAfter.fbo.lastFallback});
   const music=apiAfter.audio.nodes.filter(n=>n.music);
   check('audio-cadence-applied-'+index+'-'+stage.windows.length,music.length>0&&music.every(n=>n.confirmedVersion===n.version&&n.receivedHz===(apiAfter.audio.enabled?60:0)),{music});
  }
  stage.windows.push({scene,mode,before,after,raf,apiBefore,apiAfter,engine_fps:after.game.result.drawn*1000/after.game.result.elapsed_ms});save();
 }
 async function screenshot(label){const filename=index+'-'+stage.label+'-'+label+'.png';await page.screenshot({path:path.join(out,filename)});stage.captures.push({filename,label});return fs.readFileSync(path.join(out,filename));}
 async function nativeCaptures(){
  await command('freeze');
  for(let p=0;p<poses.length;p++){
   const [family,phase,angle]=poses[p];await command('fixed_pose',{family,phase,angle});await delay(180);
   const request=index+'-'+p;await command('capture',{request});await page.waitForFunction(x=>window.DEV14_NATIVE_CAPTURE?.id===x,request);
   const row=await page.evaluate(()=>window.DEV14_NATIVE_CAPTURE),png=Buffer.from(row.png,'base64');delete row.png;
   const filename=index+'-'+label+'-native-'+p+'.png';fs.writeFileSync(path.join(out,filename),png);stage.captures.push({filename,pose:p,...row});
   check('hero-framing-'+index+'-'+p,row.used_rect[0]>0&&row.used_rect[1]>0&&row.used_rect[0]+row.used_rect[2]<400&&row.used_rect[1]+row.used_rect[3]<400,{used_rect:row.used_rect});
  }
  await command('resume');
 }
 try{
  await page.goto('http://127.0.0.1:'+server.address().port+'/'+label+'/',{waitUntil:'domcontentloaded',timeout:120000});
  await wait(s=>s?.game?.version===(label==='baseline'?'1.0.0-dev.15.16':'1.0.0-dev.15.17')&&s.fixes);await page.mouse.click(25,25);await setup('surface');await delay(5000);
  stage.runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return{ua:navigator.userAgent,dpr:devicePixelRatio,canvas:[c.width,c.height],renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
  check('runtime-'+index,stage.runtime.dpr===3&&/Apple|Metal/.test(stage.runtime.renderer),stage.runtime);
 }catch(e){stage.error=String(e);await page.screenshot({path:path.join(out,index+'-startup-failure.png')}).catch(()=>{});await context.close();throw e;}
 return{context,page,stage,state,wait,command,modes,setup,measure,screenshot,nativeCaptures};
}

try{
 const s=await open('candidate','individual-fixes');
 try{
  const order=worker==='1'?['none','fbo','audio','both','both','audio','fbo','none']:['both','audio','fbo','none','none','fbo','audio','both'];
  for(const scene of ['surface','mining']){
   if(scene==='mining')await s.setup(scene);
   for(const mode of order){await s.modes(mode==='fbo'||mode==='both',mode==='audio'||mode==='both');await s.measure(scene,mode,8);}
   await s.page.keyboard.up('Space');await s.wait(x=>!x.fixes.mining);await s.command('freeze');
   await s.modes(false,false);const a=await s.screenshot(scene+'-reference');
   await s.modes(true,true);const b=await s.screenshot(scene+'-fixed');
   await s.modes(false,false);const c=await s.screenshot(scene+'-restored');
   const pair={scene,candidate:difference(a,b),restored:difference(a,c)};report.pairs.push(pair);check('same-frame-'+scene,pair.candidate.max===0&&pair.restored.max===0,pair);await s.command('resume');
  }
  await s.command('surface_setup');await s.command('fixes_center');await s.command('native_setup');
  s.stage.cpu=(await s.command('fixes_cpu')).fixes.result;
  check('cpu-production-parity',s.stage.cpu.exact===true,s.stage.cpu);
  check('full-hero-in-game',s.stage.cpu.framing.fully_inside===true,s.stage.cpu.framing);
  await s.command('fixes_endless');await delay(1500);
  await s.command('fixes_record_start');await s.page.keyboard.down('Space');await delay(4000);
  await s.command('fixes_retarget');await delay(3000);
  await s.page.keyboard.up('Space');await delay(500);
  s.stage.replay=(await s.command('fixes_record_end')).fixes.result;
  check('real-mining-motion-parity',s.stage.replay.exact===true&&s.stage.replay.mining_frames>20&&s.stage.replay.contour_frames>0&&s.stage.replay.impacts>0&&s.stage.replay.retargets>0&&s.stage.replay.cancels>0&&s.stage.replay.clipped_frames===0,s.stage.replay);
  await s.modes(true,true);
  await s.page.setViewportSize({width:820,height:420});await delay(1000);
  await s.page.setViewportSize({width:776,height:420});await delay(1000);
  check('resize-restored',await s.page.evaluate(()=>{const c=document.querySelector('canvas');return c.width===2328&&c.height===1260;}));
  await s.command('pause');check('menu-pause',(await s.state()).fixes.menu===true);await s.command('fixes_menu_resume');
  for(const scene of ['hub','depth','endless','deepheart','surface']){
   await s.command(scene,scene==='endless'?{depth:3,direction:'up',gear:'ember'}:{});await s.command('fixes_center');await delay(900);await s.screenshot('transition-'+scene);
   check('transition-'+scene,(await s.state()).game.native.active===true);
  }
  const before=(await s.state()).fixes.position;await s.page.keyboard.down('ArrowRight');await delay(650);await s.page.keyboard.up('ArrowRight');const after=(await s.state()).fixes.position;
  check('real-walking',Math.hypot(after[0]-before[0],after[1]-before[1])>10,{before,after});
  s.stage.finalApi=await s.page.evaluate(()=>({fbo:window.EVER_DEEPER_FBO.snapshot(),audio:window.FPS_FIX_AUDIO.snapshot()}));
 }catch(e){s.stage.error=String(e);await s.screenshot('failure').catch(()=>{});throw e;}finally{await s.context.close();}

 const sequence=worker==='1'?['baseline','candidate','candidate','baseline']:['candidate','baseline','baseline','candidate'];
 for(const label of sequence){
  const t=await open(label,'original-package-vs-production-fixes');
  try{
   await t.measure('surface','production',12);await t.screenshot('surface-game');await t.nativeCaptures();
   await t.setup('mining');await t.measure('mining','production',12);await t.page.keyboard.up('Space');await t.wait(x=>!x.fixes.mining);await t.screenshot('mining-game');
  }catch(e){t.stage.error=String(e);await t.screenshot('failure').catch(()=>{});throw e;}finally{await t.context.close();}
 }
 const stages=report.stages.filter(s=>s.purpose==='original-package-vs-production-fixes');
 for(let p=0;p<poses.length;p++){
  const reference=stages[0].captures.find(c=>c.pose===p);
  for(const stage of stages.slice(1)){
   const capture=stage.captures.find(c=>c.pose===p),diff=difference(fs.readFileSync(path.join(out,reference.filename)),fs.readFileSync(path.join(out,capture.filename)));
   report.pairs.push({pose:p,reference:reference.filename,candidate:capture.filename,...diff});check('native-image-'+capture.filename,diff.max===0,diff);
  }
 }
 fs.copyFileSync(path.join(web,'build.json'),path.join(out,'build.json'));
}catch(e){report.error=String(e);console.error(e);}
finally{save();await Promise.race([browser.close(),delay(5000)]);server.close();}
process.exitCode=report.error?1:0;
