import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.9',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
 await command('light_setup');await delay(1800);
 await command('report_menu');await button('AutoFPSTest');
 await page.waitForFunction(()=>window.LIGHT_TEST_STATE?.running);
 check('depth-one-started',(await state()).phase==='mine'&&(await page.evaluate(()=>window.REPORT_UI)).running);
 await shot('light-test-start');
 if(process.env.REPORT_BROWSER==='webkit'){
  for(let i=0;i<7;i++){await delay(2400);await command('light_advance');}
 }
 await page.waitForFunction(()=>window.LIGHT_TEST_STATE?.result?.graphics_restored===true,null,{timeout:240000});
 await delay(500);
 const light=await page.evaluate(()=>window.LIGHT_TEST_STATE),report=await pending();
 check('completed',!light.running&&!light.result.cancelled&&light.result.rows.length===7);
 check('restored',light.restored&&light.result.graphics_restored);
 check('canvas-unchanged',light.result.baseline.canvas_width===light.result.final.canvas_width&&light.result.baseline.canvas_height===light.result.final.canvas_height);
 check('all-stage-markers',['original','pet_off','restore_pet','shadows_off','restore_shadows','lights_off','restore_lights'].every(stage=>report.events.some(e=>e.kind==='lighttest:settle:'+stage)&&report.events.some(e=>e.kind==='lighttest:measure:'+stage)));
 check('end-marker',report.events.some(e=>e.kind==='lighttest:end:complete'));
 check('no-network-during-test',receiverRequests===0);
 const select=stage=>{
  const begin=report.events.find(e=>e.kind==='lighttest:measure:'+stage);
  const index=report.events.indexOf(begin),end=report.events[index+1]?.seconds??report.duration_s;
  return report.samples.filter(w=>w.seconds-w.window_ms/1000>=begin.seconds-0.002&&w.seconds<=end+0.002);
 };
 check('pet-lights-isolated',select('pet_off').length>0&&select('pet_off').every(w=>w.pet_lights===0&&w.lights>0));
 check('shadows-isolated',select('shadows_off').length>0&&select('shadows_off').every(w=>w.shadows===0&&w.lights>0));
 check('all-lights-isolated',select('lights_off').length>0&&select('lights_off').every(w=>w.lights===0&&w.shadows===0));
 check('original-lights-return',select('restore_lights').some(w=>w.lights>0));
 check('phase-boundaries',report.events.every(e=>e.seconds>=0&&e.seconds<=report.duration_s+0.002)&&report.events.every((e,i)=>i===0||e.seconds>=report.events[i-1].seconds));
 const s=await state(),panel=light.panel;
 check('result-fits',panel[0]>=0&&panel[1]>=0&&panel[0]+panel[2]<=s.viewport[0]+1&&panel[1]+panel[3]<=s.viewport[1]+1,{panel,viewport:s.viewport});
 await shot('light-test-complete');
 check('pending-report-protected',!(await page.evaluate(()=>window.everDeeperReports.begin('overwrite'))));
 const popupPromise=context.waitForEvent('page',{timeout:15000});
 await page.touchscreen.tap(light.send[0]/s.viewport[0]*844,light.send[1]/s.viewport[1]*390);
 const popup=await popupPromise;await popup.waitForLoadState('domcontentloaded');
 transferred=await popup.evaluate(()=>window.receivedReport);
 check('exact-labelled-transfer',transferred?.id===report.id&&JSON.stringify(transferred.events)===JSON.stringify(report.events)&&JSON.stringify(transferred.samples)===JSON.stringify(report.samples));
 await delay(500);check('receipt-clears-report',!(await pending()));await popup.close();
 await command('light_hide');
 // Bounded recovery checks use the real production transition logic with QA-only clock advances.
 for(const [stage,interrupt] of [[1,false],[3,true],[5,false]]){
  await command('report_menu');await button('AutoFPSTest');await page.waitForFunction(()=>window.LIGHT_TEST_STATE?.running);
  for(let i=0;i<stage;i++){await delay(400);await command('light_advance');}
  await command(interrupt?'light_interrupt':'light_cancel');
  await page.waitForFunction(()=>window.LIGHT_TEST_STATE?.result?.graphics_restored===true&&!window.LIGHT_TEST_STATE.running);
  const result=await page.evaluate(()=>window.LIGHT_TEST_STATE);
  check('cancel-restores-'+stage,result.restored&&result.result.cancelled);
  check('cancel-stops-report-'+stage,!(await page.evaluate(()=>window.REPORT_UI)).running);
  await command('light_hide');await page.evaluate(()=>window.everDeeperReports.clear());await delay(300);
 }
 check('no-script-errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)),{tail:messages.slice(-8)});
}catch(e){failed=String(e);console.error(e);try{await shot('failure')}catch{}}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,browser:process.env.REPORT_BROWSER||'chromium',checks,physical_iphone_verified:false,transfer_fixture:true},null,2));
 if(transferred)fs.writeFileSync(path.join(output,'sample-session.json'),JSON.stringify(transferred,null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
