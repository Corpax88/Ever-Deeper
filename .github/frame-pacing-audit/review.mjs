import {webkit} from '@playwright/test';
import {PNG} from 'pngjs';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
await context.addInitScript(()=>{
 const raf=window.requestAnimationFrame;
 window.AUDIT_RAF={active:false,calls:0,total_ms:0,max_ms:0};
 window.requestAnimationFrame=cb=>raf.call(window,t=>{const a=window.AUDIT_RAF;if(!a.active)return cb(t);const start=performance.now();try{return cb(t);}finally{const ms=performance.now()-start;a.calls++;a.total_ms+=ms;a.max_ms=Math.max(a.max_ms,ms);}});
 window.AUDIT_NATIVE_RAF=cb=>raf.call(window,cb);
});
const page=await context.newPage(),messages=[],windows=[],pairs=[];let error=null,id=0,runtime=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
async function state(){return page.evaluate(()=>window.DEV14_STATE);}
async function wait(fn){for(let i=0;i<400;i++){const s=await state();if(s?.error||s?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){fs.appendFileSync(path.join(out,'progress.log'),kind+' '+JSON.stringify(more)+'\n');const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s?.id===wanted);}
async function measure(scene,cap,seconds){
 await command('cap',{value:cap});await delay(1500);await command('begin');
 const before=await state();
 const raf=await page.evaluate(ms=>new Promise(resolve=>{
  window.AUDIT_RAF={active:true,calls:0,total_ms:0,max_ms:0};
  const rows=[];const start=performance.now();let last=start;
  const tick=now=>{rows.push(now-last);last=now;if(now-start>=ms){window.AUDIT_RAF.active=false;resolve({elapsed_ms:now-start,frames:rows.length,intervals_ms:rows,engine_callbacks:{...window.AUDIT_RAF}});}else window.AUDIT_NATIVE_RAF(tick);};window.AUDIT_NATIVE_RAF(tick);
 }),seconds*1000);
 const after=await command('end');
 if(after.cap!==cap||!after.native.active)throw Error('Wrong cap or missing native hero');
 windows.push({scene,cap,before,after,raf,engine_fps:after.result.drawn*1000/after.result.elapsed_ms,raf_fps:raf.frames*1000/raf.elapsed_ms});
 fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(windows,null,2));
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s?.version==='1.0.0-dev.15.16');await page.mouse.click(25,25);
 await command('surface_setup');await delay(5000);
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {ua:navigator.userAgent,dpr:devicePixelRatio,canvas:[c.width,c.height],renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
 await page.screenshot({path:path.join(out,'surface.png')});
 const order=process.env.AUDIT_WORKER==='2'?[0,60,60,0]:[60,0,0,60];
 for(const cap of order)await measure('surface',cap,15);
 await command('freeze');
 for(const cap of [60,0,60]){await command('cap',{value:cap});await delay(400);await page.screenshot({path:path.join(out,'frozen-'+pairs.length+'.png')});pairs.push(cap);}
 const a=PNG.sync.read(fs.readFileSync(path.join(out,'frozen-0.png')));
 for(const i of [1,2]){const b=PNG.sync.read(fs.readFileSync(path.join(out,'frozen-'+i+'.png')));if(!a.data.equals(b.data))throw Error('Frozen visual parity failed '+i);}
 await command('resume');
 for(const scene of ['hub','moss']){
  await command(scene,{direction:'up',gear:'ember'});await delay(2000);
  await page.screenshot({path:path.join(out,scene+'.png')});
  for(const cap of (process.env.AUDIT_WORKER==='2'?[0,60]:[60,0]))await measure(scene,cap,8);
 }
 await command('cap',{value:60});
 fs.copyFileSync(path.join(web,'audit-build.json'),path.join(out,'audit-build.json'));
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,worker:process.env.AUDIT_WORKER,purpose:'Exact DEV15.16 reversible Engine.max_fps60/0 with actual engine-frame and external RAF measurement. Diagnostic only.',runtime,windows,pairs,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);process.exit(error?1:0);
