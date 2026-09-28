import {webkit,chromium} from '@playwright/test';import {PNG} from 'pngjs';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2),browserName=process.env.AUDIT_BROWSER;fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await (browserName==='chromium'?chromium:webkit).launch({headless:true,...(browserName==='chromium'?{args:['--use-angle=metal']}: {})});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
await context.addInitScript(()=>{
 try{localStorage.setItem('ever_deeper_graphics_dev_v1','3');}catch{}
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
});
const page=await context.newPage(),messages=[],windows=[],pairs=[];let error=null,id=0,runtime=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,'console.log'),messages.join('\n'));});page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
async function state(){return page.evaluate(()=>window.DEV14_STATE);}
async function wait(fn){for(let i=0;i<400;i++){const s=await state();if(s?.error||s?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){fs.appendFileSync(path.join(out,'progress.log'),kind+' '+JSON.stringify(more)+'\n');const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s?.id===wanted);}
async function measure(crop,seconds,gpu=false){
 await command('crop',{value:crop});await delay(1500);await command('begin');const before=await state();
 const raf=await page.evaluate(({ms,gpu})=>new Promise(resolve=>{
  const m=window.AUDIT;Object.assign(m,{active:true,calls:0,total_ms:0,max_ms:0,gpu,gpu_ns:[],disjoint:false});
  const rows=[],start=performance.now();let last=start;
  const tick=now=>{rows.push(now-last);last=now;if(now-start>=ms){m.active=false;resolve({elapsed_ms:now-start,frames:rows.length,intervals_ms:rows,calls:m.calls,total_ms:m.total_ms,max_ms:m.max_ms});}else window.AUDIT_NATIVE_RAF(tick);};window.AUDIT_NATIVE_RAF(tick);
 }),{ms:seconds*1000,gpu});
 const after=await command('end');await delay(200);
 const gpuData=await page.evaluate(()=>{window.AUDIT_COLLECT();return {ns:window.AUDIT.gpu_ns,pending:window.AUDIT.pending.length,disjoint:window.AUDIT.disjoint};});
 if(!after.native.active||!after.crop.ok||after.crop.cropped!==crop||after.cap!==60)throw Error('Render state changed');
 windows.push({crop,instrumented_gpu:gpu,before,after,raf,gpu:gpuData,engine_fps:after.result.drawn*1000/after.result.elapsed_ms});fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(windows,null,2));
}
function difference(a,b){const x=PNG.sync.read(a),y=PNG.sync.read(b);if(x.width!==y.width||x.height!==y.height)throw Error('dimensions');let changed=0,max=0,total=0;for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);total+=d;}return {changed,max,mean:total/x.data.length};}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s?.version==='1.0.0-dev.15.16');await page.mouse.click(25,25);
 await command('surface_setup');await command('crop_setup');await delay(12000);
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');window.AUDIT.gl=g;window.AUDIT.ext=g.getExtension('EXT_disjoint_timer_query_webgl2');return {ua:navigator.userAgent,dpr:devicePixelRatio,canvas:[c.width,c.height],gpu_timer:!!window.AUDIT.ext,renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
 if(runtime.dpr!==3||runtime.canvas[0]!==2328||!/Apple|Metal/.test(runtime.renderer))throw Error('Wrong graphical runtime '+JSON.stringify(runtime));
 for(const crop of (browserName==='webkit'?[false,true,true,false]:[true,false,false,true]))await measure(crop,15);
 if(runtime.gpu_timer)for(const crop of [false,true,false])await measure(crop,4,true);
 await command('freeze');
 for(const x of [2050,2250,3130,3290,3470,4000]){
  await command('position',{x});await command('crop',{value:false});await delay(400);const a=await page.screenshot();
  await command('crop',{value:true});await delay(400);const b=await page.screenshot({path:path.join(out,'candidate-'+x+'.png')});
  await command('crop',{value:false});await delay(400);const c=await page.screenshot();
  const candidate=difference(a,b),restored=difference(a,c);pairs.push({x,candidate,restored});fs.writeFileSync(path.join(out,'pairs.json'),JSON.stringify(pairs,null,2));
  if(x===3130){fs.writeFileSync(path.join(out,'reference-3130.png'),a);fs.writeFileSync(path.join(out,'restored-3130.png'),c);}
  if(restored.max!==0||candidate.max>1)throw Error('Pixel gate '+JSON.stringify(pairs.at(-1)));
 }
 await command('position',{x:3130});await command('resume');await command('crop',{value:false});
 fs.copyFileSync(path.join(web,'audit-build.json'),path.join(out,'audit-build.json'));
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,browser:browserName,purpose:'Reversible zero-alpha backdrop crop, same QualityDPR3 both modes. Actual game frames plus optional GPUquery diagnostic; no phone claim.',runtime,windows,pairs,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);process.exit(error?1:0);
