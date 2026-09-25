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
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=browserName==='webkit'?await webkit.launch({headless:true}):await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true});
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
const pairs=[],captures=[];
function valid(s,value){
 const c=s.light_cost;return c.mode===(value===0?'baseline':'no_empty_2d')&&c.empty_2d_disabled===(value===1)&&c.native_viewports.length===1&&c.native_viewports.every(v=>v.canvas_items===0)&&c.lights.length===6&&c.lights.every(l=>l.enabled);
}
async function width(value){await command('lightmode',{mode:value===0?'baseline':'no_empty_2d'});await delay(650);check('variant-'+value,valid(await state(),value));}
async function parity(label,retain=false){
 const shots=[];
 for(const w of [0,1,0]){
  await width(w);const bytes=await page.screenshot(),name=label+'-'+shots.length+'-w'+w;
  shots.push({w,bytes,hash:digest(bytes),name});
  if(retain){fs.writeFileSync(path.join(output,name+'.png'),bytes);captures.push(name);}
 }
 const a=PNG.sync.read(shots[0].bytes);
 for(const [i,shot] of shots.entries()){
  if(!i)continue;const b=PNG.sync.read(shot.bytes);let max=0,changed=0,sum=0,over2=0;
  check('image-size-'+label+'-'+i,a.width===b.width&&a.height===b.height);
  for(let k=0;k<a.data.length;k++){let d=Math.abs(a.data[k]-b.data[k]);if(d)changed++;if(d>2)over2++;sum+=d;max=Math.max(max,d);}
  const row={label,variant:shot.w,reference:shots[0].hash,candidate:shot.hash,max_channel_difference:max,changed_channels:changed,mean_channel_difference:sum/a.data.length,channels_over_2:over2,channel_count:a.data.length};pairs.push(row);
  check((shot.w===0?'restored-':'candidate-')+label,max===0,row);
  // Removing an empty canvas pass must preserve every pixel in this fixture.
 }
}
async function measure(scenario,order){
 for(const [index,w] of order.entries()){
  await width(w);await delay(2000);const before=await state();
  await page.evaluate(()=>window.__gpuMeter.begin());await command('begin');await delay(12000);const ended=await command('end');
  await page.evaluate(()=>window.__gpuMeter.active=false);await delay(400);const gpu=await page.evaluate(()=>window.__gpuMeter.stop());
  const impacts=ended.impact-before.impact;
  check(scenario+'-workload-'+index,ended.result.frames>200&&(scenario==='mining'?impacts>=20&&ended.mining:impacts===0&&!ended.mining));
  check(scenario+'-position-'+index,ended.position.every((v,i)=>Math.abs(v-before.position[i])<0.02));
  check('end-state-'+index,valid(ended.result,w));windows.push({scenario,index,variant:w,...ended.result,impacts,gpu});
  console.log(JSON.stringify({scenario,index,variant:w,fps:ended.result.frames/ended.result.seconds,p95:ended.result.frame.p95_ms}));
 }
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});
 check('mac-gpu',process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer),{runtime});check('resolution',runtime.canvas[0]===2328&&runtime.canvas[1]===1260);check('version',(await state()).version===version);
 for(const mine of ['emberMine','mossMine','moonMine','starMine']){
  await command('setup',{mine,cached:true});await wait('native',s=>s?.native?.active&&s.native.updates>3);
  await command('lightmode',{mode:'baseline'});await delay(1000);await command('freeze');
  await parity(mine+'-intact',mine==='emberMine');await command('damage');await command('break');await parity(mine+'-broken');await command('restore');
 }
 await command('setup',{mine:'emberMine',cached:true,durable:true});await wait('native',s=>s?.native?.active&&s.native.updates>3);
 await command('lightmode',{mode:'baseline'});
 for(const w of [1,0,1]){await width(w);await delay(5000);}await delay(30000);
 const order=process.env.REPEAT==='2'?[1,0,0,1,0,1]:[0,1,1,0,1,0];

 const s=await state();await page.mouse.move(s.mine_button[0]/s.viewport[0]*776,s.mine_button[1]/s.viewport[1]*420);await page.mouse.down();await wait('held mining',v=>v.impact>s.impact&&v.mining);await delay(15000);
 await measure('mining',order);await page.mouse.up();await wait('release',v=>!v.mining);
 await width(0);const before=await state();await page.keyboard.down('ArrowDown');await delay(650);await page.keyboard.up('ArrowDown');await delay(300);const after=await state();check('movement-after-restoration',Math.hypot(after.position[0]-before.position[0],after.position[1]-before.position[1])>10);
 await command('freeze');await parity('moved',true);check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,baseline_source:'c63aabd3e3e5120579285ce6e8b0b59a75f2727a',version,files,browser:browserName,repeat:process.env.REPEAT,runtime,checks,windows,pairs,captures,physical_iphone_verified:false,scope:'QA disable ONLY the empty 2D canvas of the existing 3D-only native actor SubViewport. All actor source/assets/animation, 3D rendering, world lights, HUD and resolution unchanged. Occupancy revision in both modes. Exact candidate image parity required. GL synchronization counts verify actual work reduction. No release.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
