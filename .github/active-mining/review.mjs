import {PNG} from 'pngjs';
import {webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [candidate,output]=process.argv.slice(2);const original=candidate;fs.mkdirSync(output,{recursive:true});
const roots={original:path.resolve(original),candidate:path.resolve(candidate)},files={};
for(const [side,root] of Object.entries(roots)){
 files[side]=JSON.parse(fs.readFileSync(path.join(root,'manifest.json')));
 for(const [name,want] of Object.entries(files[side])){
  const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(root,name)))h.update(b);
  if(h.digest('hex')!==want.sha256||fs.statSync(path.join(root,name)).size!==want.size)throw Error('Package identity '+side+'/'+name);
 }
}
const server=http.createServer((req,res)=>{
 const bits=new URL(req.url,'http://localhost').pathname.split('/').filter(Boolean),side=bits.shift(),root=roots[side];
 if(!root){res.writeHead(404).end();return;}
 const file=path.resolve(root,bits.join('/')||'index.html');
 if(!file.startsWith(root+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true}),checks=[],windows=[],captures=[],runtimes=[],messages=[];
const order=['original','original'];
let failed=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,passed,details={}){checks.push({name,passed:!!passed,...details});if(!passed)throw Error(name);}
try{
 for(const [block,side] of order.entries()){
  const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true});
  await context.addInitScript(()=>{
   const probe=window.__stall={active:false,frame:0,stats:{},events:[],callbacks:[],current:0};
   probe.begin=enabled=>{probe.active=enabled;probe.stats={};probe.events=[];probe.callbacks=[];};
   probe.stop=()=>{probe.active=false;return {stats:probe.stats,events:probe.events,callbacks:probe.callbacks}};
   const record=(label,start,extra)=>{
    const ms=performance.now()-start;const s=probe.stats[label]||(probe.stats[label]={calls:0,ms:0,max:0});s.calls++;s.ms+=ms;s.max=Math.max(s.max,ms);
    if(ms>=2&&probe.events.length<10000)probe.events.push({label,start,ms,frame:probe.current,...extra});
   };
   const proto=WebGL2RenderingContext.prototype;
   for(const label of ['fenceSync','getSyncParameter','clientWaitSync','waitSync','checkFramebufferStatus','drawElements','drawArrays','drawElementsInstanced','drawArraysInstanced','bufferData','bufferSubData','getBufferSubData','texImage2D','texSubImage2D','compressedTexImage2D','texStorage2D','readPixels','compileShader','linkProgram','getShaderParameter','getProgramParameter','finish','flush','bindFramebuffer','clear','blitFramebuffer']){
    const original=proto[label];if(typeof original!=='function')continue;
    proto[label]=function(...args){if(!probe.active)return original.apply(this,args);const start=performance.now();try{return original.apply(this,args)}finally{record(label,start)}};
   }
   const grow=WebAssembly.Memory.prototype.grow;
   WebAssembly.Memory.prototype.grow=function(...args){if(!probe.active)return grow.apply(this,args);const start=performance.now(),before=this.buffer.byteLength;try{return grow.apply(this,args)}finally{record('wasm_memory_grow',start,{before,after:this.buffer.byteLength,pages:args[0]})}};
   const raf=window.requestAnimationFrame;
   window.requestAnimationFrame=cb=>raf.call(window,t=>{if(!probe.active)return cb(t);const start=performance.now();probe.current=++probe.frame;try{return cb(t)}finally{const ms=performance.now()-start;if(ms>=25&&probe.callbacks.length<10000)probe.callbacks.push({start,ms,frame:probe.current})}});
  });
  const page=await context.newPage();let id=0;const localMessages=[];
  page.on('console',m=>{localMessages.push(m.type()+': '+m.text());messages.push({block,side,message:m.type()+': '+m.text()})});
  page.on('pageerror',e=>localMessages.push('PAGEERROR '+e.message));
  const state=()=>page.evaluate(()=>window.DEV14_STATE);
  async function wait(label,predicate,timeout=90000){let s;for(let end=Date.now()+timeout;Date.now()<end;){s=await state();if(s?.error||s?.native?.failed)throw Error(label+JSON.stringify(s));if(predicate(s))return s;if(localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error('Runtime '+label);await delay(150)}throw Error(label+' timeout '+JSON.stringify(s));}
  async function command(kind,extra={}){const wanted=++id;await page.evaluate(v=>window.DEV14_COMMAND=JSON.stringify(v),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
  try{
   await page.goto('http://127.0.0.1:'+server.address().port+'/'+side+'/',{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu,180000);
   const runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]}});runtimes.push({side,block,...runtime});
   check('Apple GPU '+block,process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer));check('full resolution '+block,runtime.canvas[0]===2328&&runtime.canvas[1]===1260);
   await command('setup',{mine:'emberMine',cached:true,durable:false,stable:side==='candidate'});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(3000);
   check('version', (await state()).version==='1.0.0-dev.15.10');
   async function parity(tag){
    await command('freeze');await page.mouse.move(0,0);await delay(300);
    const buffers=[];
    for(const enabled of [false,true,false]){
     await command('stable',{enabled});await delay(300);
     const name=block+'-'+tag+'-'+buffers.length+'.png';
     buffers.push(await page.screenshot({path:path.join(output,name),timeout:60000}));captures.push(name);
    }
    const imgs=buffers.map(b=>PNG.sync.read(b));let different=0,max=0;
    for(let i=0;i<imgs[0].data.length;i++){const d=Math.abs(imgs[0].data[i]-imgs[1].data[i]);if(d)different++;max=Math.max(max,d)}
    check('restore exact '+block+'-'+tag,imgs[0].data.equals(imgs[2].data));
    check('stable exact '+block+'-'+tag,different===0,{different,max});
    await command('stable',{enabled:side==='candidate'});await command('unfreeze');
   }
   // Prior run established frozen parity; this run is timing only.
   const before=await state();await page.mouse.move(before.mine_button[0]/before.viewport[0]*776,before.mine_button[1]/before.viewport[1]*420);await page.mouse.down();await command('route');
   for(let index=0;index<6;index++){
    const start=await state();await page.evaluate(enabled=>window.__stall.begin(enabled),block===1);await command('begin',{instrument:true});await delay(15000);const end=await command('end');const browserProfile=await page.evaluate(()=>window.__stall.stop());
    check('active native '+block+'-'+index,end.native.active&&end.result.frames>200);
    windows.push({block,index,side,impacts:end.impact-start.impact,browserProfile,...end.result,native:end.native,position:end.position});fs.writeFileSync(path.join(output,'windows.json'),JSON.stringify(windows,null,2));
   }
   await command('route_stop');await page.mouse.up();await delay(400);
   const group=windows.filter(w=>w.block===block);
   check('real movement '+block,group.reduce((a,w)=>a+w.distance,0)>200);
   check('real excavation '+block,group.reduce((a,w)=>a+w.blocks_removed,0)>=3);
   check('save success '+block,group.every(w=>w.save_error===0));
   await command('freeze');await delay(300);const name=block+'-stall.png';await page.screenshot({path:path.join(output,name)});captures.push(name);
   check('no runtime errors '+block,!localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
  }finally{await context.close();}
 }
}catch(e){failed=String(e.stack||e);console.error(failed);}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,candidate_source:process.env.GITHUB_SHA,original_source:'ab0c12ff579134e0a092946bd92973e4599a073c',repeat:process.env.REPEAT,files,order,runtimes,checks,windows,captures,messages,physical_iphone_verified:false,scope:'DIAGNOSTIC baseline only, first block WebGL observer off and second on; wrapper branches remain in both. Wall clock browser methods and callbacks are NOT GPU times. Memory.grow wrapper cannot see a wasm-internal memory.grow instruction. QA-only DEV15.10 package, measured actual movement and block destruction; shared profiling overhead, fresh contexts ABBA. Candidate only anchors width6 terrain strip keys to the fixed world grid; floor, assets, lights and resolution unchanged. CPU wrapper wall time not GPU time. Save uses isolated fixture namespace. Includes all windows/stalls. No physical phone claim.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;

