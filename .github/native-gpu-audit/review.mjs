import {webkit,chromium} from '@playwright/test';import {PNG} from 'pngjs';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2),browserName=process.env.AUDIT_BROWSER;fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await (browserName==='chromium'?chromium:webkit).launch({headless:true,...(browserName==='chromium'?{args:['--use-angle=metal']}: {})});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
await context.addInitScript({path:path.resolve('.github/native-gpu-audit/viewport-trace.js')});
await context.addInitScript(({dpr})=>{
 try{localStorage.setItem('ever_deeper_graphics_dev_v1',String(dpr));}catch{}
 const raf=window.requestAnimationFrame;
 const m=window.AUDIT={active:false,calls:0,total_ms:0,max_ms:0,gpu:false,gpu_ns:[],pending:[],disjoint:false};
 const collect=()=>{if(!m.gl||!m.ext)return;while(m.pending.length&&m.gl.getQueryParameter(m.pending[0],m.gl.QUERY_RESULT_AVAILABLE)){const q=m.pending.shift();m.gpu_ns.push(m.gl.getQueryParameter(q,m.gl.QUERY_RESULT));m.gl.deleteQuery(q);}if(m.gl.getParameter(m.ext.GPU_DISJOINT_EXT))m.disjoint=true;};
 window.AUDIT_COLLECT=collect;
 window.requestAnimationFrame=cb=>raf.call(window,t=>{
  if(!m.active)return cb(t);
  let query=null;
  if(m.gpu&&m.ext){collect();query=m.gl.createQuery();m.gl.beginQuery(m.ext.TIME_ELAPSED_EXT,query);}
  const start=performance.now();try{return cb(t);}finally{const elapsed=performance.now()-start;m.calls++;m.total_ms+=elapsed;m.max_ms=Math.max(m.max_ms,elapsed);if(query){m.gl.endQuery(m.ext.TIME_ELAPSED_EXT);m.pending.push(query);}}
 });
 window.AUDIT_NATIVE_RAF=cb=>raf.call(window,cb);
},{dpr:browserName==='webkit'?3:2});
const page=await context.newPage(),messages=[],windows=[],pairs=[],inventories=[];let error=null,id=0,runtime=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,'console.log'),messages.join('\n'));});page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
async function state(){return page.evaluate(()=>window.DEV14_STATE);}
async function wait(fn){for(let i=0;i<400;i++){const s=await state();if(s?.error||s?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){fs.appendFileSync(path.join(out,'progress.log'),kind+' '+JSON.stringify(more)+'\n');const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s?.id===wanted);}
async function measure(mode,seconds,gpu=false){
 await command('native_mode',{value:mode});await delay(1500);await command('begin');const before=await state();
 const raf=await page.evaluate(({ms,gpu})=>new Promise(resolve=>{
  const m=window.AUDIT;Object.assign(m,{active:true,calls:0,total_ms:0,max_ms:0,gpu,gpu_ns:[],disjoint:false});
  const rows=[],start=performance.now();let last=start;
  const tick=now=>{rows.push(now-last);last=now;if(now-start>=ms){m.active=false;resolve({elapsed_ms:now-start,frames:rows.length,intervals_ms:rows,calls:m.calls,total_ms:m.total_ms,max_ms:m.max_ms});}else window.AUDIT_NATIVE_RAF(tick);};window.AUDIT_NATIVE_RAF(tick);
 }),{ms:seconds*1000,gpu});
 const after=await command('end');await delay(200);
 const gpuData=await page.evaluate(()=>{window.AUDIT_COLLECT();return {ns:window.AUDIT.gpu_ns,pending:window.AUDIT.pending.length,disjoint:window.AUDIT.disjoint};});
 const a=before.native_info,b=after.native_info;
 if(!after.native.active||!b.stable||b.mode!==mode||after.cap!==60||b.updates<=a.updates||b.generations!==a.generations||JSON.stringify(a.lights2d)!==JSON.stringify(b.lights2d))throw Error('Native/2D state changed');
 if((mode==='render_off')!==(b.update_mode===0)||(mode==='shadow_off')===b.shadow)throw Error('Wrong native mode');
 windows.push({mode,instrumented_gpu:gpu,before,after,raf,gpu:gpuData,engine_fps:after.result.drawn*1000/after.result.elapsed_ms});fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(windows,null,2));
}
function difference(a,b){const x=PNG.sync.read(a),y=PNG.sync.read(b);if(x.width!==y.width||x.height!==y.height)throw Error('dimensions');let changed=0,max=0,total=0;for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);total+=d;}return {changed,max,mean:total/x.data.length};}
async function inventory(mode){
 await page.evaluate(()=>window.VIEWPORT_TRACE.install());
 await command('native_mode',{value:'atlas2048'});await delay(250);
 await command('native_mode',{value:mode});await delay(750);
 await page.evaluate(v=>window.VIEWPORT_TRACE.begin(v),mode);await delay(1000);
 inventories.push({mode,game:await state(),trace:await page.evaluate(()=>window.VIEWPORT_TRACE.end())});
 fs.writeFileSync(path.join(out,'inventories.json'),JSON.stringify(inventories,null,2));
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s?.version==='1.0.0-dev.15.16');await page.mouse.click(25,25);
 await command('surface_setup');await command('native_setup');await delay(10000);
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');window.AUDIT.gl=g;window.AUDIT.ext=g.getExtension('EXT_disjoint_timer_query_webgl2');return {ua:navigator.userAgent,dpr:devicePixelRatio,canvas:[c.width,c.height],gpu_timer:!!window.AUDIT.ext,renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
 if(runtime.dpr!==(browserName==='webkit'?3:2)||!/Apple|Metal/.test(runtime.renderer))throw Error('Wrong graphical runtime '+JSON.stringify(runtime));
 await page.evaluate(()=>window.VIEWPORT_TRACE.begin('startup_baseline'));await delay(1000);
 inventories.push({mode:'startup_baseline',game:await state(),trace:await page.evaluate(()=>window.VIEWPORT_TRACE.end())});
 for(const mode of ['baseline','shadow_off','baseline','atlas2048','baseline','render_off','baseline']){
  await measure(mode,12);
  if(['shadow_off','render_off'].includes(mode)||windows.length===1)await page.screenshot({path:path.join(out,mode+'.png')});
 }
 if(runtime.gpu_timer)for(const mode of ['baseline','shadow_off','atlas2048','render_off','baseline'])await measure(mode,4,true);
 for(const mode of ['baseline','shadow_off','atlas2048','render_off'])await inventory(mode);
 await command('native_mode',{value:'baseline'});
 for(const direction of ['down','right','up','left']){
  await command('facing',{value:direction});await delay(500);await command('freeze');
  await command('native_mode',{value:'baseline'});await delay(400);const a=await page.screenshot();
  await command('native_mode',{value:'atlas2048'});await delay(400);const b=await page.screenshot({path:path.join(out,'atlas2048-'+direction+'.png')});
  await command('native_mode',{value:'baseline'});await delay(400);const c=await page.screenshot();
  const candidate=difference(a,b),restored=difference(a,c);pairs.push({direction,candidate,restored});fs.writeFileSync(path.join(out,'pairs.json'),JSON.stringify(pairs,null,2));
  if(direction==='down'){fs.writeFileSync(path.join(out,'reference-down.png'),a);fs.writeFileSync(path.join(out,'restored-down.png'),c);}
  if(restored.max!==0)throw Error('Restoration pixel gate '+JSON.stringify(pairs.at(-1)));
  await command('resume');
 }
 fs.copyFileSync(path.join(web,'audit-build.json'),path.join(out,'audit-build.json'));
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,browser:browserName,purpose:'Native shadow/GPU-render isolation; actual game frames, unwrapped timing windows, separate FBO inventory and optional GPU command intervals. No phone claim.',runtime,windows,pairs,inventories,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);process.exit(error?1:0);

