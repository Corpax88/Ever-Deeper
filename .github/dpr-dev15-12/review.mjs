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
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s.game?.version==='1.0.0-dev.15.12');await page.mouse.click(25,25);
 await command('setup',{mine:'starMine',durable:true,cached:true});await delay(3000);
 async function tap(key){const u=await page.evaluate(()=>window.DPR_UI);const q=key==='toggle'?u.toggle:u.buttons[key];await page.touchscreen.tap(q[0]*776/u.viewport[0],q[1]*420/u.viewport[1]);await delay(900);}
 for(const ratio of [3,2,1,3]){
  await tap('toggle');await page.screenshot({path:path.join(out,'menu-'+ratio+'.png')});await tap('Dpr'+ratio);
  const actual=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2');return {canvas:[c.width,c.height],buffer:[g.drawingBufferWidth,g.drawingBufferHeight],dpr:devicePixelRatio,lost:g.isContextLost(),ui:window.DPR_UI};});
  if(actual.dpr!==ratio||actual.canvas[0]!==776*ratio||actual.canvas[1]!==420*ratio||actual.buffer.toString()!==actual.canvas.toString()||actual.lost||actual.ui.open||!actual.ui.meter)throw Error('DPR selection '+JSON.stringify(actual));
  const before=await state();await page.keyboard.down('Space');await delay(2000);await page.keyboard.up('Space');const after=await state();if(after.game.impact<=before.game.impact)throw Error('Mining input after resize');
  windows.push({ratio,actual,mining:true});await page.screenshot({path:path.join(out,'dpr-'+ratio+'.png')});
 }
 await page.reload({waitUntil:'domcontentloaded'});await wait(s=>s.game?.version==='1.0.0-dev.15.12');
 if(await page.evaluate(()=>devicePixelRatio)!==3)throw Error('Reload default');
 runtime=await page.evaluate(()=>({dpr:devicePixelRatio,ua:navigator.userAgent}));

}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'DPR 3/2/1/3 real touch buttons, framebuffer sizes, mining after resize and reload default',runtime,windows,error},null,2));await browser.close();server.close();}
if(error)throw Error(error);
