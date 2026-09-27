import {PNG} from 'pngjs';
import {webkit} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await webkit.launch({headless:true});const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});await context.addInitScript(()=>{
 const p=WebGL2RenderingContext.prototype,m=window.ALLOC_TRACE={active:false,counts:{},images:{},params:{},stacks:{},frames:0},ids=new WeakMap();let seq=0,unit=0;const bound=new Map();
 const id=o=>o?(ids.has(o)?ids.get(o):(ids.set(o,++seq),seq)):0;
 for(const name of ['activeTexture','bindTexture','texImage2D','texStorage2D','createTexture','deleteTexture','createFramebuffer','deleteFramebuffer','framebufferTexture2D','checkFramebufferStatus','getParameter','fenceSync','getSyncParameter']){
  const original=p[name];p[name]=function(...a){
   if(name==='activeTexture')unit=a[0];if(name==='bindTexture')bound.set(unit+':'+a[0],id(a[1]));
   const start=m.active?performance.now():0;const result=original.apply(this,a);
   if(m.active){const c=m.counts[name]??={n:0,ms:0};c.n++;c.ms+=performance.now()-start;
    if(name==='getParameter')m.params[a[0]]=(m.params[a[0]]||0)+1;
    if(name==='texImage2D'){const key=JSON.stringify({args:a.map((x,i)=>i===8?(x===null?'null':typeof x):typeof x==='number'?x:typeof x),texture:bound.get(unit+':'+a[0])});m.images[key]=(m.images[key]||0)+1;}
    if(['texImage2D','checkFramebufferStatus','getParameter'].includes(name)&&!m.stacks[name])m.stacks[name]=new Error().stack;
   }return result;
  };
 }
 const raf=window.requestAnimationFrame;window.requestAnimationFrame=cb=>raf.call(window,t=>{if(m.active)m.frames++;return cb(t)});
});
const page=await context.newPage();
const messages=[],windows=[];let error=null,id=0,runtime=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,'console.log'),messages.join('\n'));});page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
async function state(){return page.evaluate(()=>({game:window.DEV14_STATE,focus:window.FOCUS_STATE}));}
async function wait(fn){for(let i=0;i<400;i++){const s=await state();if(s.game?.error||s.game?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s.game?.id===wanted);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s.game?.version==='1.0.0-dev.15.11');await page.mouse.click(25,25);
 await command('setup',{mine:'starMine',durable:true,cached:true});await wait(s=>s.focus&&s.game?.native?.active);await delay(3000);
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {canvas:[c.width,c.height],dpr:devicePixelRatio,ua:navigator.userAgent,renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):g.getParameter(g.RENDERER)};});
 await page.screenshot({path:path.join(out,'start.png')});
 for(const mode of ['reference']){
  await command('focus_'+mode);
  await page.keyboard.down('Space');await delay(15000);await page.evaluate(()=>window.ALLOC_TRACE.active=true);await command('begin');await delay(300);const before=await state();await delay(10000);const after=await state();await command('end');const ended=await state();
  if(!(after.game.impact>before.game.impact&&after.game.mining))throw Error('no active mining');
  const metrics={};for(const key of ['world','terrain','native','occlusion']){const a=before.focus[key],b=after.focus[key];metrics[key]={calls:b[0]-a[0],total_us:b[1]-a[1],max_us:b[2]};}
  windows.push({mode,before,after,result:ended.game.result,metrics});fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(windows,null,2));
 }
 await page.evaluate(()=>window.ALLOC_TRACE.active=false);fs.writeFileSync(path.join(out,'allocations.json'),JSON.stringify(await page.evaluate(()=>window.ALLOC_TRACE),null,2));
 await page.keyboard.up('Space');await page.screenshot({path:path.join(out,'end.png')});
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'Bounded CPU function profile; observer included, no causal FPS or physical phone claim',runtime,windows,error},null,2));await browser.close();server.close();}
if(error)throw Error(error);
