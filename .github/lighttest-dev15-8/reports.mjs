import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.8',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
const digest=b=>createHash('sha256').update(b).digest('hex');
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const server=http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname,file=path.resolve(web,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-telemetry-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=process.env.REPORT_BROWSER==='webkit' ? await webkit.launch({headless:true}) : await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true});
const page=await context.newPage();page.setDefaultTimeout(90000);
const checks=[],messages=[],windows=[];let failed=null,runtime=null,id=0;
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
function check(name,ok,details={}){checks.push({name,passed:!!ok,...details});fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));if(!ok)throw Error(name);}
async function wait(label,predicate,timeout=60000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(150);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function shot(name){await delay(350);const bytes=await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});return digest(bytes);}
const receiver='https://ever-deeper-spillrapporter.corpax88.chatgpt.site';
let transferred=null, receiverRequests=0;
await context.route(receiver+'/**',async route=>{
 receiverRequests++;
 await route.fulfill({contentType:'text/html',body:`<html><body><h1>Private transfer fixture</h1><p id="status">Receiving</p><script>
 const encoded=location.hash.slice(8).replace(/-/g,'+').replace(/_/g,'/');
 const report=JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(encoded),c=>c.charCodeAt(0))));
 window.receivedReport=report;document.getElementById('status').textContent='Report received';
 window.opener?.postMessage({type:'ever-deeper-report-saved',id:report.id},${JSON.stringify('http://127.0.0.1:'+server.address().port)});
 <\/script></body></html>`});
});
async function button(name){
 await command('report_focus',{button:name});await delay(150);
 const ui=await page.evaluate(()=>window.REPORT_UI),s=await state(),p=ui.buttons[name];
 await page.touchscreen.tap(p[0]/s.viewport[0]*844,p[1]/s.viewport[1]*390);
 await delay(300);
}
async function pending(){return page.evaluate(()=>new Promise((resolve,reject)=>{const r=indexedDB.open('ever-deeper-reports-v1',1);r.onsuccess=()=>{const db=r.result,q=db.transaction('pending').objectStore('pending').get('last');q.onsuccess=()=>{db.close();resolve(q.result)};q.onerror=reject};r.onerror=reject}));}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});
 await wait('menu',s=>s?.menu,180000);
 check('version',(await state()).version===version);
 await command('moss',{gear:'ember',direction:'up'});await delay(1500);
 check('opt-in',!(await page.evaluate(()=>window.everDeeperReports.status())).pending);
 await command('report_menu');await shot('report-controls');await button('SessionReport');
 check('recording-started',(await page.evaluate(()=>window.REPORT_UI)).running,{ui:await page.evaluate(()=>window.REPORT_UI),api:await page.evaluate(()=>window.everDeeperReports.status())});
 const mine=await state();await page.mouse.move(mine.mine_button[0]/mine.viewport[0]*844,mine.mine_button[1]/mine.viewport[1]*390);await page.mouse.down();await delay(11500);await page.mouse.up();await delay(400);
 await shot('recording-gameplay');
 const recorded=await pending();check('real-windows',recorded?.samples.length>=2,{windows:recorded?.samples.length});
 check('real-metrics',recorded.samples.every(w=>w.frames>20&&w.canvas_width===2532&&w.cpu_mean_ms>=0&&w.nodes>100));
 check('actual-mining',recorded.samples.some(w=>w.mining_fraction>0));
 check('no-network-while-playing',receiverRequests===0);
 // A reload preserves the pending data and does not automatically restart recording.
 const oldId=recorded.id;await page.reload({waitUntil:'domcontentloaded'});await wait('reloaded',s=>s?.menu,180000);await delay(500);
 check('recovered-after-reload',(await pending())?.id===oldId);
 check('not-auto-recording',!(await page.evaluate(()=>window.REPORT_UI)).running);
 check('previous-report-protected',!(await page.evaluate(()=>window.everDeeperReports.begin('should-not-replace'))));
 await command('moss',{gear:'ember',direction:'up'});await command('report_menu');
 const popupPromise=context.waitForEvent('page',{timeout:10000});await button('SendReport');const popup=await popupPromise;
 await popup.waitForLoadState('domcontentloaded');transferred=await popup.evaluate(()=>window.receivedReport);
 check('exact-transfer',transferred?.id===oldId&&JSON.stringify(transferred.samples)===JSON.stringify(recorded.samples));
 await delay(500);check('receipt-clears-pending',!(await pending()));
 await shot('report-sent');await popup.close();
 await button('SessionReport');check('new-session-after-receipt',(await page.evaluate(()=>window.REPORT_UI)).running);
 await delay(5600);await command('report_menu');await button('SessionReport');
 check('stopped',!(await page.evaluate(()=>window.REPORT_UI)).running);
 const beforeClear=(await pending()).id;await button('ClearReport');check('clear-needs-confirmation',(await pending()).id===beforeClear);
 await button('ClearReport');check('confirmed-clear',!(await pending()));
 check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)),{tail:messages.slice(-8)});
}catch(e){failed=String(e);console.error(e);try{await shot('failure')}catch{}}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,browser:process.env.REPORT_BROWSER||'chromium',checks,physical_iphone_verified:false,transfer_fixture:true},null,2));
 if(transferred)fs.writeFileSync(path.join(output,'sample-session.json'),JSON.stringify(transferred,null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
