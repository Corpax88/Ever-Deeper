import {PNG} from 'pngjs';
import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const browserName=process.env.REVIEW_BROWSER||'chromium';
const version='1.0.0-dev.15.9',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
if(JSON.stringify(files)!==JSON.stringify(JSON.parse(fs.readFileSync('.github/resolution-study/manifest.json'))))throw Error('Pinned15.9manifest mismatch');
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
await context.addInitScript(() => {
 // Use the engine's ordinary HiDPI resize path. CSS viewport stays776x420.
 window.__qaRenderDpr=3;
 Object.defineProperty(window,'devicePixelRatio',{configurable:true,get:()=>window.__qaRenderDpr});
});
await context.addInitScript(() => {
 const meter={active:false,available:null,pending:[],rows:[],disjoint:0,armed:false,query:null,gl:null,ext:null,draws:0,tick:0};
 window.__gpuMeter=meter;
 function poll(){
  if(!meter.gl||!meter.ext)return;
  const g=meter.gl,e=meter.ext;
  if(g.getParameter(e.GPU_DISJOINT_EXT)){meter.disjoint++;for(const q of meter.pending)g.deleteQuery(q);meter.pending=[];return;}
  meter.pending=meter.pending.filter(q=>{if(!g.getQueryParameter(q,g.QUERY_RESULT_AVAILABLE))return true;meter.rows.push(g.getQueryParameter(q,g.QUERY_RESULT)/1e6);g.deleteQuery(q);return false;});
 }
 for(const name of ['drawArrays','drawElements','drawArraysInstanced','drawElementsInstanced','drawRangeElements']){
  const original=WebGL2RenderingContext.prototype[name];
  WebGL2RenderingContext.prototype[name]=function(...args){
   if(meter.armed&&this===meter.gl){
    if(!meter.query&&!this.getQuery(meter.ext.TIME_ELAPSED_EXT,this.CURRENT_QUERY)){meter.query=this.createQuery();this.beginQuery(meter.ext.TIME_ELAPSED_EXT,meter.query);}
    meter.draws++;
   }
   return original.apply(this,args);
  };
 }
 const raf=window.requestAnimationFrame;
 window.requestAnimationFrame=function(callback){return raf.call(window,function(t){
  poll();
  if(meter.active&&++meter.tick%3===0&&!meter.armed){
   const g=document.querySelector('canvas')?.getContext('webgl2');
   if(g){meter.gl=g;meter.ext=g.getExtension('EXT_disjoint_timer_query_webgl2');meter.available=!!meter.ext;}
   meter.armed=!!meter.ext;
   try{return callback(t);}finally{
    if(meter.query){meter.gl.endQuery(meter.ext.TIME_ELAPSED_EXT);meter.pending.push(meter.query);meter.query=null;}
    meter.armed=false;
   }
  }
  return callback(t);
 });};
 meter.begin=()=>{meter.rows=[];meter.disjoint=0;meter.draws=0;meter.active=true;};
 meter.stop=()=>{meter.active=false;poll();return {available:meter.available,disjoint:meter.disjoint,draws:meter.draws,values:meter.rows};};
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

const captures=[],phases=[],order=[3,2,1,1,3,2,2,1,3];
let baselineState=null,restoredPixels=null;
async function geometry(){return page.evaluate(()=>{
 const c=document.querySelector('canvas'),g=c.getContext('webgl2'),r=c.getBoundingClientRect();
 return {canvas:[c.width,c.height],drawing_buffer:[g.drawingBufferWidth,g.drawingBufferHeight],css:[r.width,r.height],inner:[innerWidth,innerHeight],dpr:devicePixelRatio};
});}
async function resize(dpr){
 await page.evaluate(value=>{window.__qaRenderDpr=value;window.dispatchEvent(new Event('resize'));},dpr);
 await page.waitForFunction(value=>{const c=document.querySelector('canvas'),g=c?.getContext('webgl2');return c?.width===776*value&&c.height===420*value&&g.drawingBufferWidth===c.width&&g.drawingBufferHeight===c.height;},dpr,{timeout:20000});
 await delay(1800);
 const s=await state(),g=await geometry();
 check('resolution-'+dpr+'-'+checks.length,g.canvas[0]===776*dpr&&g.canvas[1]===420*dpr&&g.css[0]===776&&g.css[1]===420,{geometry:g});
 if(baselineState)check('same-framing-'+checks.length,s.viewport.every((x,i)=>Math.abs(x-baselineState.viewport[i])<0.02)&&s.position.every((x,i)=>Math.abs(x-baselineState.position[i])<0.02),{viewport:s.viewport,position:s.position});
 return g;
}
function save(){fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:'c63aabd3e3e5120579285ce6e8b0b59a75f2727a',experiment_commit:process.env.GITHUB_SHA,version,files,browser:browserName,browser_version:browser.version(),host:process.platform,runtime,checks,windows,order,captures,phases,restoredPixels,baselineState,physical_iphone_verified:false,scope:'Resolution-only diagnostic on unchanged DEV15.9. Same stationary Ember scene, lights on, CSS776x420; actual framebuffer DPR3/2/1, three12s windows each after prewarming. No shader-source patch and no production change.'},null,2));}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});
 await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),vendor:g.getParameter(e?e.UNMASKED_VENDOR_WEBGL:g.VENDOR),user_agent:navigator.userAgent};});
 check('mac-renderer',process.platform==='darwin'&&(browserName==='webkit'||/Apple|Metal/.test(runtime.renderer)),{runtime});
 check('version',(await state()).version===version);
 await command('setup',{mine:'emberMine',cached:true});
 await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(2000);
 baselineState=await state();
 // Warm each framebuffer size before any timing, then retain one frozen scene.
 for(const dpr of [3,2,1,3])await resize(dpr);
 await command('freeze');
 for(const [index,dpr] of [3,2,1,3].entries()){
  const g=await resize(dpr),name='frozen-'+index+'-dpr'+dpr;
  const sha=await shot(name);captures.push({name,sha,geometry:g,state:await state()});
 }
 const a=PNG.sync.read(fs.readFileSync(path.join(output,'frozen-0-dpr3.png'))),b=PNG.sync.read(fs.readFileSync(path.join(output,'frozen-3-dpr3.png')));
 let max=0,changed=0;check('restored-image-size',a.width===b.width&&a.height===b.height);
 for(let i=0;i<a.data.length;i++){const d=Math.abs(a.data[i]-b.data[i]);max=Math.max(max,d);if(d)changed++;}
 restoredPixels={max_channel_difference:max,changed_channels:changed};
 await command('unfreeze');await delay(45000);
 for(const [index,dpr] of order.entries()){
  const geometryBefore=await resize(dpr),before=await state();
  await page.evaluate(()=>window.__gpuMeter.begin());await command('begin');await delay(12000);const ended=await command('end');
  await page.evaluate(()=>window.__gpuMeter.active=false);await delay(400);const gpu=await page.evaluate(()=>window.__gpuMeter.stop());
  const geometryAfter=await geometry();
  check('stationary-'+index,ended.position.every((v,i)=>Math.abs(v-baselineState.position[i])<0.02)&&ended.impact===before.impact&&!ended.mining&&ended.result.frames>200);
  check('resolution-held-'+index,JSON.stringify(geometryBefore)===JSON.stringify(geometryAfter));
  windows.push({index,dpr,geometry:geometryAfter,...ended.result,impacts:ended.impact-before.impact,gpu});save();
  console.log(JSON.stringify({index,dpr,fps:ended.result.frames/ended.result.seconds,p95:ended.result.frame.p95_ms}));
 }
 await resize(3);await page.keyboard.down('ArrowDown');await delay(650);await page.keyboard.up('ArrowDown');const moved=await state();
 check('movement-after-restore',Math.hypot(moved.position[0]-baselineState.position[0],moved.position[1]-baselineState.position[1])>10);
 check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);}finally{save();await browser.close();server.close();}
if(failed)process.exitCode=1;
