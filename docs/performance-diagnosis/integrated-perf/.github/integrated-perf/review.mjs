import {webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [original,candidate,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
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
const order=process.env.REPEAT==='2'?['candidate','original','original','candidate']:['original','candidate','candidate','original'];
let failed=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,passed,details={}){checks.push({name,passed:!!passed,...details});if(!passed)throw Error(name);}
try{
 for(const [block,side] of order.entries()){
  const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true});
  await context.addInitScript(()=>{
   const m=window.__meter={active:false,counts:{},raf:0};
   for(const name of ['fenceSync','getSyncParameter','checkFramebufferStatus']){const fn=WebGL2RenderingContext.prototype[name];WebGL2RenderingContext.prototype[name]=function(...args){if(m.active)m.counts[name]=(m.counts[name]||0)+1;return fn.apply(this,args)}}
   const raf=window.requestAnimationFrame;window.requestAnimationFrame=cb=>raf.call(window,t=>{if(m.active)m.raf++;return cb(t)});
   m.begin=()=>{m.counts={};m.raf=0;m.active=true};m.stop=()=>{m.active=false;return {counts:m.counts,raf:m.raf,scope:'Counts only, not GPU time'}};
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
   await command('setup',{mine:'emberMine',cached:true,durable:true});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(5000);
   const before=await state();await page.mouse.move(before.mine_button[0]/before.viewport[0]*776,before.mine_button[1]/before.viewport[1]*420);await page.mouse.down();await wait('held mine',s=>s.mining&&s.impact>before.impact);await delay(30000);
   for(let index=0;index<3;index++){
    const start=await state();await page.evaluate(()=>window.__meter.begin());await command('begin');await delay(15000);const end=await command('end');const gpu=await page.evaluate(()=>window.__meter.stop());
    const impacts=end.impact-start.impact;check('workload '+block+'-'+index,end.mining&&end.native.active&&end.result.frames>200&&impacts>=25);check('position '+block+'-'+index,end.position.every((p,i)=>Math.abs(p-start.position[i])<0.02));
    const renders=gpu.counts.checkFramebufferStatus,expected=side==='original'?4:3;check('sync '+block+'-'+index,renders>200&&gpu.counts.fenceSync===expected*renders&&gpu.counts.getSyncParameter===expected*renders,{gpu});
    windows.push({block,index,side,impacts,...end.result,gpu,native:end.native,position:end.position});fs.writeFileSync(path.join(output,'windows.json'),JSON.stringify(windows,null,2));
   }
   await page.mouse.up();await wait('released',s=>!s.mining);await command('freeze');await delay(400);const name=block+'-'+side;await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});captures.push(name);
   check('no runtime errors '+block,!localMessages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
  }finally{await context.close();}
 }
}catch(e){failed=String(e.stack||e);console.error(failed);}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,candidate_source:process.env.CANDIDATE_SOURCE,original_source:'c63aabd3e3e5120579285ce6e8b0b59a75f2727a',repeat:process.env.REPEAT,files,order,runtimes,checks,windows,captures,messages,physical_iphone_verified:false,scope:'Actual unchanged DEV15.9 package versus integrated occupancy/native candidate. Fresh context per block, 30s held-mining warmup then three15s windows; balanced ABBA/BAAB across Mac workers. Full resolution/lighting/assets retained. Synchronization wrappers have the same overhead per call; the candidate makes fewer calls. This is not GPU time. Windows within a block are correlated. No UI consolidation.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
