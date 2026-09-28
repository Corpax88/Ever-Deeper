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
async function state(){return page.evaluate(()=>({game:window.DEV14_STATE,skills:window.SKILL_STATE}));}
async function wait(fn){for(let i=0;i<400;i++){const s=await state();if(s.game?.error||s.game?.native?.failed||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));if(fn(s))return s;await delay(150);}throw Error('timeout');}
async function command(kind,more={}){fs.appendFileSync(path.join(out,'progress.log'),kind+' '+JSON.stringify(more)+'\n');const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...more});return wait(s=>s.game?.id===wanted);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s.game?.version==='1.0.0-dev.15.16');await page.mouse.click(25,25);
 await command('surface_setup');await delay(5000);await command('probe');
 let lastStage=-1;
 const started=Date.now();
 while(Date.now()-started<210000){
  const s=await state();
  if(s.game?.error||messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR/.test(m)))throw Error(JSON.stringify(s));
  if(s.game.probe_stage!==lastStage){lastStage=s.game.probe_stage;await delay(700);await page.screenshot({path:path.join(out,'stage-'+lastStage+'.png')});}
  if(!s.game.probe_running&&s.game.probe?.graphics_restored!==undefined){windows.push({kind:'surface_light_probe',state:s});break;}
  await delay(300);
 }
 const s=await state(),p=s.game.probe;
 if(p.cancelled||!p.graphics_restored||p.rows?.length!==7||p.area!=='surface')throw Error('Probe completion '+JSON.stringify(p));
 if(p.rows[1].pet_lights!==0||p.rows[3].shadows!==0||p.rows[5].lights!==0)throw Error('Isolation failed');
 if(p.final.lights!==p.baseline.lights||p.final.shadows!==p.baseline.shadows)throw Error('Restoration failed');
 await page.screenshot({path:path.join(out,'result.png')});
 fs.copyFileSync(path.join(web,'manifest.json'),path.join(out,'manifest.json'));
 runtime=await page.evaluate(()=>({dpr:devicePixelRatio,ua:navigator.userAgent}));

}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'Full opt-in surface light test, seven stages, exact restoration; no phone FPS claim',runtime,windows,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);
process.exit(error?1:0);
