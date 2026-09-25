import {PNG} from 'pngjs';
import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const browserName=process.env.REVIEW_BROWSER||'chromium';
const version='1.0.0-dev.15.9',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));

const digest=b=>createHash('sha256').update(b).digest('hex');
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const server=http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname,file=path.resolve(web,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-dev14-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=browserName==='webkit'?await webkit.launch({headless:true}):await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
await context.addInitScript(()=>{
 const meter=window.__gpuMeter={active:false,counts:{},raf:0};
 for(const name of ['fenceSync','getSyncParameter','checkFramebufferStatus']){
  const fn=WebGL2RenderingContext.prototype[name];
  WebGL2RenderingContext.prototype[name]=function(...args){if(meter.active)meter.counts[name]=(meter.counts[name]||0)+1;return fn.apply(this,args);};
 }
 const raf=window.requestAnimationFrame;
 window.requestAnimationFrame=cb=>raf.call(window,t=>{if(meter.active)meter.raf++;return cb(t)});
 meter.begin=()=>{meter.counts={};meter.raf=0;meter.active=true;};
 meter.stop=()=>{meter.active=false;return {counts:meter.counts,raf:meter.raf,scope:'Call counts only, not GPU time'};};
});
const page=await context.newPage();page.setDefaultTimeout(90000);
const checks=[],messages=[],windows=[];let failed=null,runtime=null,id=0;
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,ok,details={}){checks.push({name,passed:!!ok,...details});fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));if(!ok)throw Error(name);}
async function wait(label,predicate,timeout=60000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(150);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function shot(name){await delay(350);const bytes=await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});return digest(bytes);}
const pairs=[],captures=[],inventories=[];
async function nativeReady(gear){return wait('native '+gear,s=>s?.native?.active&&s.native.gear===gear&&s.native.updates>3);}
async function observeProduction(label){
 await delay(650);await page.evaluate(()=>window.__gpuMeter.begin());await delay(1000);const gpu=await page.evaluate(()=>window.__gpuMeter.stop());const s=await state();inventories.push({label,mode:'automatic-production',state:s,gpu});
 const n=gpu.counts.checkFramebufferStatus;
 check('automatic-native-'+label,s.active_rigs===1&&s.native_canvas.items===0&&s.native_canvas.size==='(400, 400)'&&s.native_canvas.update_mode===4,{native:s.native,native_canvas:s.native_canvas});
 check('automatic-sync-'+label,n>10&&gpu.counts.fenceSync===3*n&&gpu.counts.getSyncParameter===3*n,{gpu});return s;
}
async function parity(label){
 await observeProduction(label);
 const shots=[];
 for(const mode of ['canvas_reference','canvas_candidate','canvas_reference']){
  await command(mode);await delay(650);const bytes=await page.screenshot(),name=label+'-'+shots.length;
  fs.writeFileSync(path.join(output,name+'.png'),bytes);captures.push(name);shots.push(bytes);
  await page.evaluate(()=>window.__gpuMeter.begin());await delay(1000);const counts=await page.evaluate(()=>window.__gpuMeter.stop());
  const s=await state();inventories.push({label,mode,state:s,gpu:counts});
  check('native-inventory-'+label+'-'+mode,s.active_rigs===1&&s.native_canvas.items===0&&s.native_canvas.size==='(400, 400)'&&s.native_canvas.update_mode===4);
  const n=counts.counts.checkFramebufferStatus,expected=mode==='canvas_candidate'?3:4;
  check('sync-pairs-'+label+'-'+mode,n>10&&counts.counts.fenceSync===expected*n&&counts.counts.getSyncParameter===expected*n,{counts});
 }
 const a=PNG.sync.read(shots[0]);
 for(let i=1;i<shots.length;i++){
  const b=PNG.sync.read(shots[i]);check('size-'+label+'-'+i,a.width===b.width&&a.height===b.height);
  let max=0,changed=0;for(let n=0;n<a.data.length;n++){const d=Math.abs(a.data[n]-b.data[n]);max=Math.max(max,d);if(d)changed++;}
  const row={label,index:i,max,changed,reference:digest(shots[0]),candidate:digest(shots[i])};pairs.push(row);check('pixels-'+label+'-'+i,max===0,row);
 }
 await command('canvas_candidate');await command('canvas_resume');
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});
 check('apple-gpu',process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer),{runtime});
 for(const gear of ['worn','iron','runed','moonglass','ember','crusher','comet','crown']){
  await command('moss',{direction:'right',gear});const before=await nativeReady(gear);
  await page.keyboard.down('Space');await wait('mining '+gear,s=>s.impact>before.impact&&s.health<before.health);await page.keyboard.up('Space');await wait('release',s=>!s.mining);await delay(650);
  await parity(gear);
 }
 const prior=await state();let priorUpdates=prior.native.updates;
 for(const gear of ['worn','iron','runed','moonglass','ember','crusher','comet','crown']){
  await command('gear',{gear});await nativeReady(gear);const s=await observeProduction('in-place-'+gear);
  check('same-rig-'+gear,s.native.generations===prior.native.generations&&s.native.updates>priorUpdates,{before:prior.native,after:s.native});priorUpdates=s.native.updates;
 }
 await command('gear',{gear:'burrower'});await wait('drill',s=>s.gear==='burrower'&&!s.native.active);await shot('drill');captures.push('drill');
 await command('gear',{gear:'worn',outfit:'deepheart'});await nativeReady('worn');await parity('worn-reentry');
 for(const phase of ['surface','depth','hub','deepheart']){await command(phase);await nativeReady('worn');await parity(phase);}
 await command('pause');await wait('pause menu',s=>s.menu);await shot('pause');captures.push('pause');
 await command('resume');const before=await nativeReady('worn');await page.keyboard.down('ArrowDown');await delay(600);await page.keyboard.up('ArrowDown');await wait('resume movement',s=>Math.hypot(s.position[0]-before.position[0],s.position[1]-before.position[1])>2);await observeProduction('resumed');await shot('resumed');captures.push('resumed');
 check('no-runtime-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);try{await shot('failure')}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,runtime,checks,pairs,captures,inventories,physical_iphone_verified:false,scope:'Integrated occupancy revision and production native viewport lifecycle. All eight tools, drill reentry, worlds, pause/resume. Canvas toggles are explicit QA only; original/candidate/restored images require exact equality. No UI consolidation. Synchronization counts, not GPU time.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
