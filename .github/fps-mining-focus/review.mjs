import {PNG} from 'pngjs';
import {webkit} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await webkit.launch({headless:true});const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});const page=await context.newPage();
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
 for(const mode of ['reference','candidate','candidate','reference']){
  await command('focus_'+mode);
  await page.keyboard.down('Space');await delay(1500);await command('begin');await delay(300);const before=await state();await delay(10000);const after=await state();await command('end');const ended=await state();
  if(!(after.game.impact>before.game.impact&&after.game.mining))throw Error('no active mining');
  const metrics={};for(const key of ['world','terrain','native','occlusion']){const a=before.focus[key],b=after.focus[key];metrics[key]={calls:b[0]-a[0],total_us:b[1]-a[1],max_us:b[2]};}
  windows.push({mode,before,after,result:ended.game.result,metrics});fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(windows,null,2));
 }
 await command('freeze');
 const pairs=[];
 for(const mutation of ['focus_effects','damage','break','restore']){
  await command('focus_candidate');await command(mutation);await delay(400);
  const a=await page.screenshot({path:path.join(out,mutation+'-candidate.png')});
  await command('focus_reference');await delay(400);
  const b=await page.screenshot({path:path.join(out,mutation+'-reference.png')});
  const x=PNG.sync.read(a),y=PNG.sync.read(b);let max=0,changed=0;
  for(let i=0;i<x.data.length;i++){let d=Math.abs(x.data[i]-y.data[i]);max=Math.max(max,d);if(d)changed++;}
  pairs.push({mutation,max,changed});fs.writeFileSync(path.join(out,'pairs.json'),JSON.stringify(pairs));
  if(max!==0)throw Error('Pixel mismatch '+mutation+' '+max);
 }
 await page.keyboard.up('Space');await page.screenshot({path:path.join(out,'end.png')});
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'Bounded CPU function profile; observer included, no causal FPS or physical phone claim',runtime,windows,error},null,2));await browser.close();server.close();}
if(error)throw Error(error);
