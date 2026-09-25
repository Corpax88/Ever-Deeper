import {webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
import {execFileSync} from 'node:child_process';
const [root,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const expectedVersion=process.env.EXPECTED_VERSION||'1.0.0-dev.14';
const files=JSON.parse(fs.readFileSync(path.join(root,'manifest.json')));
for(const [name,want] of Object.entries(files)){const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(root,name)))h.update(b);if(h.digest('hex')!==want.sha256)throw Error('Candidate identity: '+name);}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{const n=new URL(req.url,'http://localhost').pathname;const f=path.resolve(root,'.'+(n==='/'?'/index.html':n));if(!f.startsWith(path.resolve(root)+path.sep)||!fs.existsSync(f)){res.writeHead(404).end();return;}res.writeHead(200,{'Content-Type':mime[path.extname(f)]||'application/octet-stream','Cache-Control':'no-store'});fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const report={kind:'ordinary-startup',source_commit:process.env.CANDIDATE_SOURCE||'9989805a329373af6c19dc5cde21e23205d87ea5',version:expectedVersion,files,normal_startup:true,fixture_args:[],physical_iphone:false,events:[],samples:[],memory:[],images:[]};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify(report,null,2));
const browser=await webkit.launch({headless:true});report.browser=browser.version();
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,isMobile:true,hasTouch:true});
await context.addInitScript(()=>{
 const M=WebAssembly.Memory;window.__startupMemories=[];
 WebAssembly.Memory=new Proxy(M,{construct(target,args){const m=Reflect.construct(target,args);window.__startupMemories.push(m);return m;}});
 window.__startupFrames=0;function tick(){window.__startupFrames++;requestAnimationFrame(tick);}requestAnimationFrame(tick);
});
const page=await context.newPage();page.setDefaultTimeout(90000);
page.on('console',m=>{if(/error|warning/.test(m.type())||/Godot|WebGL|memory/i.test(m.text()))report.events.push({event:m.type(),text:m.text().slice(0,1500),at:Date.now()});save();});
page.on('pageerror',e=>{report.events.push({event:'pageerror',text:e.message,at:Date.now()});save();});
page.on('crash',()=>{report.crashed=true;save();});
page.on('framenavigated',f=>{if(f===page.mainFrame()){report.events.push({event:'navigation',url:f.url(),at:Date.now()});save();}});
let monitor;
function memory(stage){const rows=execFileSync('ps',['-axo','pid=,rss=,comm='],{encoding:'utf8'}).split('\n').filter(x=>/ms-playwright.*WebKit\.(WebContent|GPU)/.test(x));report.memory.push({stage,at:Date.now(),processes:rows});save();}
async function sample(stage){
 const state=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c?.getContext('webgl2'),e=g?.getExtension('WEBGL_debug_renderer_info');return {version:window.everDeeperVersion,frames:window.__startupFrames,wasm_bytes:(window.__startupMemories||[]).map(m=>m.buffer.byteLength),renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g?.isContextLost(),viewport:[innerWidth,innerHeight],dpr:devicePixelRatio};});
 const processes=execFileSync('ps',['-axo','pid=,rss=,comm='],{encoding:'utf8'}).split('\n').filter(x=>/WebKit|MiniBrowser/.test(x));
 report.samples.push({stage,at:Date.now(),...state,processes});save();return state;
}
async function shot(name){await page.screenshot({path:path.join(output,name+'.png'),timeout:30000});report.images.push(name+'.png');save();}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await page.waitForFunction(v=>window.everDeeperVersion===v,expectedVersion,{timeout:180000});
 await page.waitForTimeout(1200);await sample('menu');await shot('01-ordinary-menu');
 monitor=setInterval(()=>memory('startup'),500);
 // Actual New Game button from the current responsive menu, without QA startup.
 await page.touchscreen.tap(615,138);
 for(let i=0;i<30;i++){await page.waitForTimeout(500);await sample('new-game-'+i);}
 await shot('02-after-new-game');
 await page.keyboard.press('Escape');await page.waitForTimeout(500);await shot('03-after-escape');
 // Reload preserves the test browser's newly created save. Exercise the actual
 // New Game confirmation path shown in the user's recording, without fixtures.
 await page.reload({waitUntil:'domcontentloaded',timeout:180000});
 await page.waitForFunction(v=>window.everDeeperVersion===v,expectedVersion,{timeout:180000});
 await page.waitForTimeout(1200);await shot('04-saved-run-menu');
 await page.touchscreen.tap(615,138);await page.waitForTimeout(500);await shot('05-new-game-confirmation');
 await page.touchscreen.tap(515,260);
 for(let i=0;i<20;i++){await page.waitForTimeout(500);await sample('confirmed-new-game-'+i);}
 await shot('06-confirmed-new-game');
 const navigations=report.events.filter(e=>e.event==='navigation');
 if(navigations.length!==2)throw Error('Unexpected navigation or page restart during New Game');
 if(report.events.some(e=>e.event==='pageerror'||/SCRIPT ERROR|^ERROR:/.test(e.text||'')))throw Error('Runtime startup error');
 report.completed_observation=true;
 console.log('STARTUP_OBSERVATION_COMPLETE inspect actual screenshots and memory samples');
}catch(e){report.failure=String(e.stack||e);console.error(report.failure);try{await shot('failure');}catch{}}
finally{clearInterval(monitor);save();await browser.close();await new Promise(r=>server.close(r));}
if(report.failure||report.crashed)process.exitCode=1;

