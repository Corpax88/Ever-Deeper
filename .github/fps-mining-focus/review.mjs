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
 await page.keyboard.down('Space');await delay(12000);await page.screenshot({path:path.join(out,'start.png')});
 for(const mode of ['pet_on','pet_off','pet_on']){
  await command('focus_reference');await command(mode);
  await page.keyboard.down('Space');await delay(1500);await command('begin');await delay(300);const before=await state();await delay(20000);const after=await state();await command('end');const ended=await state();
  if(!(after.game.impact>before.game.impact&&after.game.mining))throw Error('no active mining');
  const metrics={};for(const key of ['world','terrain','native','occlusion']){const a=before.focus[key],b=after.focus[key];metrics[key]={calls:b[0]-a[0],total_us:b[1]-a[1],max_us:b[2]};}
  const pet={};for(const key of ['physics','think','move','path','pose']){const a=before.focus.pet[key],b=after.focus.pet[key];pet[key]={calls:b[0]-a[0],total_us:b[1]-a[1],lifetime_max_us:b[2]};}
  if(!after.focus.pet.visible||after.focus.pet.lights.length!==2||after.focus.pet.lights.some(l=>!l.visible||!l.enabled))throw Error('Pet or light hidden');
  if(mode==='pet_off' ? pet.physics.calls!==0||pet.pose.calls===0 : pet.physics.calls===0||pet.think.calls===0)throw Error('AI toggle not exercised');
  windows.push({mode,before,after,result:ended.game.result,metrics,pet});fs.writeFileSync(path.join(out,'partial.json'),JSON.stringify(windows,null,2));
  await page.screenshot({path:path.join(out,windows.length+'-'+mode+'.png')});
 }
 await command('freeze');
 await command('pet_on');await delay(400);const a=await page.screenshot({path:path.join(out,'frozen-on.png')});
 await command('pet_off');await delay(400);const b=await page.screenshot({path:path.join(out,'frozen-off.png')});
 const x=PNG.sync.read(a),y=PNG.sync.read(b);let changed=0;for(let i=0;i<x.data.length;i++)if(x.data[i]!==y.data[i])changed++;
 fs.writeFileSync(path.join(out,'pixels.json'),JSON.stringify({changed}));if(changed)throw Error('AI switch altered rendering');
 await command('pet_on');await page.keyboard.up('Space');
}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'Mole AI on/off/on during actual held mining; visible pet pose and lights retained; Mac only',runtime,windows,error},null,2));await browser.close();server.close();}
if(error)throw Error(error);
