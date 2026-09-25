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
await context.addInitScript(() => {
 const proto=WebGL2RenderingContext.prototype, originals=new Map();
 for(let node=proto;node&&node!==Object.prototype;node=Object.getPrototypeOf(node)){
  for(const name of Object.getOwnPropertyNames(node)){
   const d=Object.getOwnPropertyDescriptor(node,name);
   if(name!=='constructor'&&typeof d.value==='function'&&!originals.has(name))originals.set(name,{fn:d.value,own:Object.getOwnPropertyDescriptor(proto,name)});
  }
 }
 const meter=window.__cpuMeter={active:false,methods:{},frames:[],nested:0};
 const raf=window.requestAnimationFrame;
 window.requestAnimationFrame=function(cb){return raf.call(window,function(t){
  if(!meter.active)return cb(t);
  const start=performance.now();try{return cb(t);}finally{meter.frames.push(performance.now()-start);}
 });};
 meter.begin=(enabled)=>{
  meter.methods={};meter.frames=[];meter.active=enabled;
  for(const [name,entry]of originals){
   if(enabled)Object.defineProperty(proto,name,{configurable:true,writable:true,value:function(...args){
    const t=performance.now();try{return entry.fn.apply(this,args)}finally{
     const ms=performance.now()-t,row=meter.methods[name]||(meter.methods[name]={calls:0,total_ms:0,max_ms:0,over_1ms:0});
     row.calls++;row.total_ms+=ms;row.max_ms=Math.max(row.max_ms,ms);if(ms>1)row.over_1ms++;
    }
   }});
   else if(entry.own)Object.defineProperty(proto,name,entry.own);else delete proto[name];
  }
 };
 meter.stop=()=>{const result={methods:meter.methods,raf_callback_ms:meter.frames};meter.begin(false);return result;};
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

const captures=[],parity=[];let initial=null;
const modes=['baseline','lights_off'];
async function mode(value){
 const s=await command('lightmode',{mode:value});await delay(1500);
 check('mode-'+value,s.light_cost.mode===value,{lights:s.light_cost.lights});
 const inventory=s.light_cost.lights;
 check('light-groups-'+value,inventory.length===6&&inventory.filter(l=>l.path.startsWith('WorkLight_')).length===2);
 check('light-states-'+value,inventory.every(l=>l.enabled===!(value==='lights_off'||(value==='fixed_off'&&l.path.startsWith('WorkLight_'))||(value==='headlamps_off'&&!l.path.startsWith('WorkLight_')))));
 check('framing-'+value,s.position.every((v,i)=>Math.abs(v-initial.position[i])<0.02)&&s.viewport.every((v,i)=>Math.abs(v-initial.viewport[i])<0.02));
 return s;
}
function identical(a,b,label){
 const x=PNG.sync.read(a),y=PNG.sync.read(b);let changed=0,max=0;
 check('size-'+label,x.width===y.width&&x.height===y.height);
 for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);}
 parity.push({label,max,changed});check(label,max===0);
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});
 check('apple-gpu',process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer),{runtime});check('native-root-size',runtime.canvas[0]===2328&&runtime.canvas[1]===1260);
 await command('setup',{mine:'emberMine',cached:true,durable:true});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(2000);initial=await state();await command('freeze');
 const original=await page.screenshot({path:path.join(output,'original.png')});captures.push({name:'original',state:initial});
 for(const value of modes){
  const s=await mode(value);await delay(500);const png=await page.screenshot();
  if(value==='baseline')identical(original,png,value+'-unchanged-image');
  if(value!=='baseline'){fs.writeFileSync(path.join(output,value+'.png'),png);captures.push({name:value,state:s});}
 }
 await mode('baseline');identical(original,await page.screenshot(),'restored-original');
 await command('unfreeze');for(const value of modes){await mode(value);await delay(2500);}await mode('baseline');await delay(45000);
 const s=await state();await page.mouse.move(s.mine_button[0]/s.viewport[0]*776,s.mine_button[1]/s.viewport[1]*420);await page.mouse.down();await wait('held mining',v=>v.mining&&v.impact>s.impact);await delay(12000);
 // Three balanced blocks; repeat2 reverses each block. Never compare only
 // first cold baseline with later candidate measurements.
 const order=[['baseline',false],['baseline',true],['lights_off',true],['lights_off',false],['lights_off',false],['lights_off',true],['baseline',true],['baseline',false]];
 for(const [index,[value,instrumented]]of order.entries()){
  await mode(value);const before=await state();await command('begin');await page.evaluate(enabled=>window.__cpuMeter.begin(enabled),instrumented);await delay(10000);const ended=await command('end');const profile=await page.evaluate(()=>window.__cpuMeter.stop());const impacts=ended.impact-before.impact;
  check('held-mining-'+index,ended.result.frames>150&&impacts>=20&&ended.mining);
  check('end-light-states-'+index,ended.result.light_cost.lights.every(l=>l.enabled===!(value==='lights_off'||(value==='fixed_off'&&l.path.startsWith('WorkLight_'))||(value==='headlamps_off'&&!l.path.startsWith('WorkLight_')))));
  const cost=ended.result.light_cost;check('refresh-ownership-'+index,cost.refresh_calls>150);
  windows.push({index,mode:value,instrumented,...ended.result,impacts,profile});
  fs.writeFileSync(path.join(output,'windows.json'),JSON.stringify(windows,null,2));
 }
 await page.mouse.up();await wait('release',v=>!v.mining);await mode('baseline');check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,repeat:process.env.REPEAT,runtime,checks,windows,parity,captures,physical_iphone_verified:false,candidate_source:'ef660efba2f17932069fa7cdd85e354fa2a549aa',candidate_run:36109186370,scope:'QA CPU wall-time inside WebGL calls and rAF callbacks. This is NOT GPU elapsed time. Uninstrumented windows retain original GL functions; paired windows estimate instrumentation overhead. Existing exact fixed-light candidate reused without build. Occupancy revision in both light modes; native resolution. No release.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
