import {webkit,chromium} from '@playwright/test';
import {PNG} from 'pngjs';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2),browserName=process.env.AUDIT_BROWSER;
fs.mkdirSync(out,{recursive:true});
for(const label of ['baseline','candidate'])for(const [name,want]of Object.entries(JSON.parse(fs.readFileSync(path.join(web,label,'manifest.json'))))){const b=fs.readFileSync(path.join(web,label,name));if(b.length!==want.size||createHash('sha256').update(b).digest('hex')!==want.sha256)throw Error('identity '+label+'/'+name);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n.endsWith('/')?n+'index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await(browserName==='chromium'?chromium:webkit).launch({headless:true,...(browserName==='chromium'?{args:['--use-angle=metal']}: {})});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
const stages=[],poses=[['idle',0,0],['idle',0,Math.PI/2],['idle',0,Math.PI],['idle',0,3*Math.PI/2],['mine',.15,0],['mine',.5,Math.PI/2],['mine',.8,Math.PI]],comparisons=[];
let error=null;
function difference(a,b){const x=PNG.sync.read(a),y=PNG.sync.read(b);if(x.width!==y.width||x.height!==y.height)throw Error('dimensions');let changed=0,max=0,total=0;for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);total+=d;}return {changed,max,mean:total/x.data.length};}
async function run(label,index){
 const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:2,hasTouch:true,isMobile:true});
 await context.addInitScript({path:path.resolve('.github/depth-prepass-audit/depth-trace.js')});
 await context.addInitScript(()=>{
  try{localStorage.setItem('ever_deeper_graphics_dev_v1','2');}catch{}
  const raf=window.requestAnimationFrame,m=window.AUDIT={active:false,calls:0,total_ms:0,max_ms:0,gpu:false,gpu_ns:[],pending:[],disjoint:false};
  const collect=()=>{if(!m.gl||!m.ext)return;while(m.pending.length&&m.gl.getQueryParameter(m.pending[0],m.gl.QUERY_RESULT_AVAILABLE)){const q=m.pending.shift();m.gpu_ns.push(m.gl.getQueryParameter(q,m.gl.QUERY_RESULT));m.gl.deleteQuery(q);}if(m.gl.getParameter(m.ext.GPU_DISJOINT_EXT))m.disjoint=true;};window.AUDIT_COLLECT=collect;
  window.requestAnimationFrame=cb=>raf.call(window,t=>{if(!m.active)return cb(t);let query=null;if(m.gpu&&m.ext){collect();query=m.gl.createQuery();m.gl.beginQuery(m.ext.TIME_ELAPSED_EXT,query);}const start=performance.now();try{return cb(t);}finally{const elapsed=performance.now()-start;m.calls++;m.total_ms+=elapsed;m.max_ms=Math.max(m.max_ms,elapsed);if(query){m.gl.endQuery(m.ext.TIME_ELAPSED_EXT);m.pending.push(query);}}});
  window.AUDIT_NATIVE_RAF=cb=>raf.call(window,cb);
 });
 const page=await context.newPage(),messages=[];let id=0;
 const stage={index,label,windows:[],captures:[],error:null};stages.push(stage);
 page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,index+'-'+label+'-console.log'),messages.join('\n'));});page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
 async function state(){return page.evaluate(()=>window.DEV14_STATE);}
 async function wait(fn){for(let i=0;i<600;i++){const s=await state();if(s?.error||s?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
 async function command(kind,more={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s?.id===wanted);}
 async function measure(seconds,gpu=false){
  if(await page.evaluate(()=>window.VIEWPORT_TRACE.installed))throw Error('GL wrappers still installed during timing');
  await command('begin');const before=await state();
  const raf=await page.evaluate(({ms,gpu})=>new Promise(resolve=>{const m=window.AUDIT;Object.assign(m,{active:true,calls:0,total_ms:0,max_ms:0,gpu,gpu_ns:[],disjoint:false});const rows=[],start=performance.now();let last=start;const tick=now=>{rows.push(now-last);last=now;if(now-start>=ms){m.active=false;resolve({elapsed_ms:now-start,frames:rows.length,intervals_ms:rows,calls:m.calls,total_ms:m.total_ms,max_ms:m.max_ms});}else window.AUDIT_NATIVE_RAF(tick);};window.AUDIT_NATIVE_RAF(tick);}),{ms:seconds*1000,gpu});
  const after=await command('end');await delay(200);const query=await page.evaluate(()=>{window.AUDIT_COLLECT();return{ns:window.AUDIT.gpu_ns,pending:window.AUDIT.pending.length,disjoint:window.AUDIT.disjoint};});
  const a=before.native_info,b=after.native_info;
  if(!b.stable||after.cap!==60||b.updates<=a.updates||b.generations!==a.generations||JSON.stringify(a.lights2d)!==JSON.stringify(b.lights2d)||!b.shadow||b.requested_atlas!==4096||b.depth_prepass!==(label==='baseline'))throw Error('State guard failed');
  stage.windows.push({instrumented_gpu:gpu,before,after,raf,gpu:query,engine_fps:after.result.drawn*1000/after.result.elapsed_ms});
  fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(stages,null,2));
 }
 try{
  await page.goto('http://127.0.0.1:'+server.address().port+'/'+label+'/',{waitUntil:'domcontentloaded',timeout:120000});
  await wait(s=>s?.version==='1.0.0-dev.15.16');await page.mouse.click(25,25);await command('surface_setup');await command('native_setup');await delay(8000);
  stage.runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');window.AUDIT.gl=g;window.AUDIT.ext=g.getExtension('EXT_disjoint_timer_query_webgl2');return{ua:navigator.userAgent,dpr:devicePixelRatio,canvas:[c.width,c.height],gpu_timer:!!window.AUDIT.ext,masked_renderer:g.getParameter(g.RENDERER),renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
  if(stage.runtime.dpr!==2||!/Apple|Metal/.test(stage.runtime.renderer))throw Error('Wrong graphical runtime');
  const s=await state();if(s.native_info.depth_prepass!==(label==='baseline'))throw Error('Startup override not applied '+JSON.stringify(s.native_info));
  await page.evaluate(v=>window.VIEWPORT_TRACE.begin(v),label);await delay(1000);stage.inventory=await page.evaluate(()=>window.VIEWPORT_TRACE.end());
  const rows=stage.inventory.rows,native=rows.filter(r=>r.viewport[2]===400&&r.viewport[3]===400&&Object.values(r.attachments).some(a=>a.kind==='renderbuffer'&&a.storage?.samples===2));
  const depthOnly=native.filter(r=>r.draw_calls&&r.pass_state.color_mask?.every(v=>!v)),color=native.filter(r=>r.draw_calls&&r.pass_state.color_mask?.every(Boolean));
  const shadow=rows.filter(r=>r.viewport[2]===4096&&r.viewport[3]===4096&&r.draw_calls);
  const sum=rows=>rows.reduce((n,r)=>n+r.submitted_elements,0);
  const signature=(rows,buffer)=>rows.every(r=>r.pass_state.depth_test===true&&r.pass_state.depth_func===518&&r.pass_state.rasterizer_discard===false&&JSON.stringify(r.pass_state.draw_buffers)===JSON.stringify([buffer]));
  stage.pass_gate={depth_draws:depthOnly.reduce((n,r)=>n+r.draw_calls,0),color_draws:color.reduce((n,r)=>n+r.draw_calls,0),color_to_shadow_elements:sum(color)/sum(shadow),depth_to_shadow_elements:sum(depthOnly)/sum(shadow),color_depth_write:color.every(r=>r.pass_state.depth_mask===(label==='candidate')),depth_signature:signature(depthOnly,0)&&depthOnly.every(r=>r.pass_state.depth_mask===true),color_signature:signature(color,36064)};
  if(!color.length||!shadow.length||Math.abs(stage.pass_gate.color_to_shadow_elements-1)>.03||Math.abs(stage.pass_gate.depth_to_shadow_elements-(label==='baseline'?1:0))>.03||!stage.pass_gate.color_depth_write||!stage.pass_gate.depth_signature||!stage.pass_gate.color_signature)throw Error('Actual depth-pass gate failed '+JSON.stringify(stage.pass_gate));
  await delay(1500);await measure(15);await page.screenshot({path:path.join(out,index+'-'+label+'-game.png')});
  if(stage.runtime.gpu_timer)await measure(4,true);
  await command('freeze');
  for(let poseIndex=0;poseIndex<poses.length;poseIndex++){
   const [family,phase,angle]=poses[poseIndex];await command('fixed_pose',{family,phase,angle});await delay(150);
   const request=index+'-'+poseIndex;await command('capture',{request});
   await page.waitForFunction(v=>window.DEV14_NATIVE_CAPTURE?.id===v,request,{timeout:10000});
   const capture=await page.evaluate(()=>window.DEV14_NATIVE_CAPTURE),png=Buffer.from(capture.png,'base64');delete capture.png;
   const filename=index+'-'+label+'-pose'+poseIndex+'.png';fs.writeFileSync(path.join(out,filename),png);stage.captures.push({filename,family,phase,angle,...capture});
  }
 }catch(e){stage.error=String(e);try{await page.screenshot({path:path.join(out,index+'-'+label+'-failure.png')});}catch{}throw e;}
 finally{await context.close();}
}
try{
 const sequence=browserName==='webkit'?['baseline','candidate','baseline']:['candidate','baseline','candidate'];
 for(let i=0;i<sequence.length;i++)await run(sequence[i],i);
 for(let p=0;p<poses.length;p++){
  const a=fs.readFileSync(path.join(out,stages[0].captures[p].filename)),b=fs.readFileSync(path.join(out,stages[1].captures[p].filename)),c=fs.readFileSync(path.join(out,stages[2].captures[p].filename));
  comparisons.push({pose:poses[p],candidate:difference(a,b),restored:difference(a,c)});
 }
 fs.copyFileSync(path.join(web,'audit-build.json'),path.join(out,'audit-build.json'));
}catch(e){error=String(e);}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,browser:browserName,purpose:'Startup web depth-prepass-only comparison. Normal FPS has no GL wrappers; inventory and optional GPU-command intervals are separate. No phone claim.',stages,comparisons,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);process.exit(error?1:0);

