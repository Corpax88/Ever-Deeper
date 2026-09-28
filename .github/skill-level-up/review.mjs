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
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await wait(s=>s.game?.version==='1.0.0-dev.15.15');await page.mouse.click(25,25);
 const check=(ok,why)=>{if(!ok)throw Error(why);};
 await command('skill_setup');
 let s=await state();check(!s.skills.toast.visible&&s.skills.events.length===0,'No startup notification');
 await page.keyboard.down('Space');
 await wait(s=>s.skills?.toast.active.id==='mining'&&s.skills.toast.opacity>.9);
 const before=await state();await delay(700);const mining=await state();await page.keyboard.up('Space');
 check(mining.game.impact>before.game.impact,'Mining continues while notice visible');
 check(mining.skills.events.filter(e=>e.id==='mining').length===1,'One event per earned level');
 check(mining.skills.toast.icon_loaded&&mining.skills.toast.ignores_input&&mining.skills.toast.clear_of_hud,'Icon, input and HUD clearance');
 await page.screenshot({path:path.join(out,'mining-level-up.png')});windows.push({kind:'mining',before,after:mining});
 await wait(s=>!s.skills?.toast.visible);windows.push({kind:'auto-dismiss',state:await state()});
 await command('skill_burst');await delay(500);s=await state();
 check(s.skills.toast.active.id==='running'&&s.skills.toast.active.level===2&&s.skills.toast.queued.length===2,'Merge and queue simultaneous levels');
 await page.screenshot({path:path.join(out,'running-level-up.png')});windows.push({kind:'burst',state:s});
 await command('skill_pause');await delay(300);s=await state();check(!s.skills.toast.visible&&s.game.menu,'Hidden over menu');
 await command('skill_resume');await wait(s=>s.skills?.toast.visible);windows.push({kind:'resume',state:await state()});
 for(const id of ['carrying','prospecting']){
  await wait(s=>s.skills?.toast.active.id===id&&s.skills.toast.opacity>.9);s=await state();check(s.skills.toast.icon_loaded,'Icon '+id);
  await page.screenshot({path:path.join(out,id+'-level-up.png')});windows.push({kind:id,state:s});
 }
 const eventsBefore=(await state()).skills.events.length;await command('skill_load');await delay(400);s=await state();
 check(s.skills.events.length===eventsBefore&&!s.skills.toast.visible&&s.skills.toast.queued.length===0,'Save load must not replay old levels');windows.push({kind:'load',state:s});
 await command('skill_cap');await wait(s=>s.skills?.toast.active.level===100&&s.skills.toast.opacity>.9);s=await state();
 check(s.skills.events.length===eventsBefore+1,'One highest-level event; none at cap');
 await page.screenshot({path:path.join(out,'level-100.png')});windows.push({kind:'cap',state:s});
 fs.copyFileSync(path.join(web,'manifest.json'),path.join(out,'manifest.json'));
 runtime=await page.evaluate(()=>({dpr:devicePixelRatio,ua:navigator.userAgent}));

}catch(e){error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({source:process.env.GITHUB_SHA,purpose:'Actual mining level-up, queue, pause, save-load suppression and cap',runtime,windows,error},null,2));await Promise.race([browser.close(),delay(5000)]);server.close();}
if(error)console.error(error);
process.exit(error?1:0);
