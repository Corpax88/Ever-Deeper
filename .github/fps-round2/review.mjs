import {webkit} from '@playwright/test';import {PNG} from 'pngjs';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2),worker=process.env.AUDIT_WORKER||'1';fs.mkdirSync(out,{recursive:true});
for(const [n,w] of Object.entries(JSON.parse(fs.readFileSync(path.join(web,'manifest.json'))))){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await webkit.launch({headless:true});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
await context.addInitScript({path:path.resolve('.github/fps-round2/fbo-trace.js')});
if(fs.existsSync('.github/fps-round2/audio-trace.js'))await context.addInitScript({path:path.resolve('.github/fps-round2/audio-trace.js')});
await context.addInitScript(()=>{try{localStorage.setItem('ever_deeper_graphics_dev_v1','3');}catch{}window.R2_NATIVE_RAF=window.requestAnimationFrame.bind(window);});
const page=await context.newPage(),messages=[],windows=[],pairs=[],benchmarks={};let error=null,id=0,runtime=null,fbo=null,audio=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,'console.log'),messages.join('\n'));});page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
async function state(){return page.evaluate(()=>({dev:window.DEV14_STATE,r2:window.ROUND2_STATE}));}
async function wait(fn){for(let i=0;i<450;i++){const s=await state();if(s?.dev?.error||s?.dev?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error('Runtime failure '+JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){fs.appendFileSync(path.join(out,'progress.log'),kind+' '+JSON.stringify(more)+'\n');const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s?.dev?.id===wanted&&s?.r2?.id===wanted);}
function save(){fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify({windows,pairs,benchmarks,fbo,audio},null,2));}
function difference(a,b){const x=PNG.sync.read(a),y=PNG.sync.read(b);if(x.width!==y.width||x.height!==y.height)throw Error('dimensions');let changed=0,max=0;for(let i=0;i<x.data.length;i++){const d=Math.abs(x.data[i]-y.data[i]);if(d)changed++;max=Math.max(max,d);}return {changed,max};}
async function measure(label,candidate,seconds=8,walking=false){
 if(walking){await command('r2_walk_setup');await delay(800);}
 await command('r2_modes',{bind:candidate,contact:false,path:candidate,profile:true});await delay(800);
 if(walking)await page.keyboard.down('ArrowRight');
 await command('begin');const before=await state();
 const raf=await page.evaluate(ms=>new Promise(resolve=>{const rows=[],start=performance.now();let last=start;const tick=now=>{rows.push(now-last);last=now;if(now-start>=ms)resolve({elapsed_ms:now-start,frames:rows.length,intervals_ms:rows});else window.R2_NATIVE_RAF(tick);};window.R2_NATIVE_RAF(tick);}),seconds*1000);
 const after=await command('end');if(walking)await page.keyboard.up('ArrowRight');
 if(!after.dev.native.active||after.r2.hero.bind_cache!==candidate||!after.r2.hero.bind_parity.exact||after.r2.hero.bind_calls<=before.r2.hero.bind_calls||after.dev.result.drawn<=0)throw Error('Invalid measured workload '+JSON.stringify(after));
 if(walking&&Math.abs(after.r2.position[0]-before.r2.position[0])<10)throw Error('Walking input did not move player');
 windows.push({label,candidate,before,after,raf,engine_fps:after.dev.result.drawn*1000/after.dev.result.elapsed_ms});save();
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s?.dev?.version==='1.0.0-dev.15.16'&&s.r2);await page.mouse.click(25,25);
 await command('surface_setup');await command('native_setup');await delay(8000);
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {ua:navigator.userAgent,dpr:devicePixelRatio,canvas:[c.width,c.height],renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
 if(runtime.dpr!==3||!/Apple|Metal/.test(runtime.renderer))throw Error('Wrong graphical runtime '+JSON.stringify(runtime));
 await page.screenshot({path:path.join(out,'surface-baseline.png')});
 await page.evaluate(()=>{window.FBO_AUDIT.begin('surface_idle',true);if(window.AUDIO_POSITION_AUDIT)window.AUDIO_POSITION_AUDIT.begin('surface_music');});await delay(5000);
 fbo=await page.evaluate(()=>window.FBO_AUDIT.end());audio=await page.evaluate(()=>window.AUDIO_POSITION_AUDIT?.end?.()||null);await page.evaluate(()=>{window.FBO_AUDIT.uninstall();window.AUDIO_POSITION_AUDIT?.uninstall?.();});save();
 const order=worker==='2'?[true,false,false,true]:[false,true,true,false];
 for(const candidate of order)await measure('surface-idle',candidate,8);
 for(const candidate of order)await measure('surface-walking',candidate,6,true);
 await command('freeze');
 benchmarks.bind=(await command('r2_bind_bench')).r2.result;if(!benchmarks.bind.parity?.exact)throw Error('Bind output differs');save();
 benchmarks.contact=(await command('r2_contact')).r2.result;if(!benchmarks.contact.exact)throw Error('Contact output differs');save();
 benchmarks.world=(await command('r2_world')).r2.result;if(!benchmarks.world.all_paths_equal||!benchmarks.world.all_cache_lifetimes_empty)throw Error('Path output/lifetime differs');save();
 await command('resume');
 for(const direction of ['down','right','up','left']){
  await command('facing',{value:direction});await delay(400);await command('freeze');
  await command('r2_modes',{bind:false,path:false,profile:false});await command('r2_apply');await delay(200);const a=await page.screenshot();
  await command('r2_modes',{bind:true,path:true,profile:false});await command('r2_apply');await delay(200);const b=await page.screenshot({path:path.join(out,'candidate-'+direction+'.png')});
  await command('r2_modes',{bind:false,path:false,profile:false});await command('r2_apply');await delay(200);const c=await page.screenshot();
  pairs.push({direction,candidate:difference(a,b),restored:difference(a,c)});save();if(pairs.at(-1).candidate.max!==0||pairs.at(-1).restored.max!==0)throw Error('Frozen image differs '+direction);
  if(direction==='down'){fs.writeFileSync(path.join(out,'reference-down.png'),a);fs.writeFileSync(path.join(out,'restored-down.png'),c);}
  await command('resume');
 }
 await command('r2_modes',{bind:false,path:false,profile:false});await page.screenshot({path:path.join(out,'restored-live.png')});
 fs.copyFileSync(path.join(web,'audit-build.json'),path.join(out,'audit-build.json'));
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,worker,purpose:'Three distinct same-source CPU candidates and read-only FBO profile. No prepass change; helper timing, instrumented live windows, frozen parity; no physical phone or production acceptance.',runtime,windows,pairs,benchmarks,fbo,audio,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);process.exit(error?1:0);
