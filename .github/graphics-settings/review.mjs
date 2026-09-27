import {webkit} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out,flavor]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [n,w] of Object.entries(manifest)){const b=fs.readFileSync(path.join(web,n));if(b.length!==w.size||createHash('sha256').update(b).digest('hex')!==w.sha256)throw Error('identity '+n);}
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname,f=path.resolve(web,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':({'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm'})[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});if(f.endsWith('index.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-graphics'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await webkit.launch({headless:true});const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});const page=await context.newPage();
const report={source:process.env.GITHUB_SHA,flavor,manifest,checks:[],error:null};const errors=[];
page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(/SCRIPT ERROR|Parse Error|^ERROR:/.test(m.text()))errors.push(m.text());});
const delay=ms=>new Promise(r=>setTimeout(r,ms));
async function ready(){await page.waitForFunction(()=>window.GRAPHICS_UI,{timeout:120000});await delay(1000);}
async function tap(key){const u=await page.evaluate(()=>window.GRAPHICS_UI);const q=u.buttons[key];if(!q)throw Error('button '+key);await page.touchscreen.tap(q[0]*776/u.viewport[0],q[1]*420/u.viewport[1]);await delay(800);}
async function check(r,stage){const s=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c.getContext('webgl2');return {dpr:devicePixelRatio,canvas:[c.width,c.height],buffer:[g.drawingBufferWidth,g.drawingBufferHeight],lost:g.isContextLost(),saved:localStorage.getItem(window.everDeeperGraphicsKey),ui:window.GRAPHICS_UI};});if(s.dpr!==r||s.canvas.toString()!==[776*r,420*r].toString()||s.buffer.toString()!==s.canvas.toString()||s.lost||s.ui.selected!==r)throw Error(stage+JSON.stringify(s));report.checks.push({stage,ratio:r,state:s});}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:120000});await ready();await tap('Settings');await check(2,'default');
 for(const r of [1,3,2]){await tap('Graphics'+r);await check(r,'select');await page.screenshot({path:path.join(out,'settings-'+r+'.png')});await page.reload({waitUntil:'domcontentloaded'});await ready();await tap('Settings');await check(r,'persisted');}
 // Storage refusal keeps the selected profile usable during this session.
 await page.evaluate(()=>Storage.prototype.setItem=function(){throw new DOMException('blocked','SecurityError');});await tap('Graphics1');await check(1,'storage-unavailable');await tap('Graphics2');await check(2,'restored');
 await tap('Back');await tap('NewGame');await delay(10000);
 let u=await page.evaluate(()=>window.GRAPHICS_UI);if(u.menu)throw Error('New Game did not enter gameplay');
 const before=u.position;await page.keyboard.down('ArrowRight');await delay(1500);await page.keyboard.up('ArrowRight');u=await page.evaluate(()=>window.GRAPHICS_UI);if(u.position.toString()===before.toString())throw Error('movement after selection');
 report.checks.push({stage:'gameplay-input',before,after:u.position});await page.screenshot({path:path.join(out,'gameplay.png')});
 if(errors.length)throw Error(errors.join('\n'));
}catch(e){report.error=String(e);try{await page.screenshot({path:path.join(out,'failure.png')});}catch{}}
finally{report.errors=errors;fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2));await browser.close();server.close();}
if(report.error)throw Error(report.error);
