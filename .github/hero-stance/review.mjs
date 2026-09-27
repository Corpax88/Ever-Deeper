import {PNG} from 'pngjs';
import {webkit} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await webkit.launch({headless:true});const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true,recordVideo:{dir:out,size:{width:776,height:420}}});const page=await context.newPage();
const messages=[],windows=[];let error=null,id=0,runtime=null;
const delay=ms=>new Promise(r=>setTimeout(r,ms));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(out,'console.log'),messages.join('\n'));});page.on('pageerror',e=>messages.push('PAGEERROR '+e.message));
async function state(){return page.evaluate(()=>({game:window.DEV14_STATE,focus:window.FOCUS_STATE}));}
async function wait(fn){for(let i=0;i<400;i++){const s=await state();if(s.game?.error||s.game?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s.game?.id===wanted);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s.game?.version==='1.0.0-dev.15.13');await page.mouse.click(25,25);
 for(const direction of ['right','left','up','down']){
  await command('stance_setup',{direction});await delay(1200);await page.keyboard.down('Space');await delay(2500);const before=await state();await delay(1500);const after=await state();await page.keyboard.up('Space');
  if(!after.game.native.active||after.game.impact<=before.game.impact)throw Error('Actual mining '+direction);
  windows.push({direction,before,after});await command('freeze');
  const pos=await page.evaluate(()=>window.STANCE_SCREEN),x=pos[0]*776/pos[2],y=pos[1]*420/pos[3];
  const clip={x:Math.max(0,x-100),y:Math.max(0,y-175),width:200,height:Math.min(205,420-Math.max(0,y-175))};
  for(const phase of [.20,.42,.70])for(const reference of [true,false]){
   await command('stance_pose',{phase,reference});await delay(180);
   await page.screenshot({path:path.join(out,direction+'-'+phase+'-'+(reference?'original':'aligned')+'.png'),clip});
  }
  await command('unfreeze');
 }
 runtime=await page.evaluate(()=>({dpr:devicePixelRatio,ua:navigator.userAgent}));

}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'Four-direction actual mining and fixed-phase original/aligned native poses',runtime,windows,error},null,2));await browser.close();server.close();}
if(error)throw Error(error);
