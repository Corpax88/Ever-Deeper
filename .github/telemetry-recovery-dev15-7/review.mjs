import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';import path from 'node:path';import http from 'node:http';import {createHash} from 'node:crypto';
const [web,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const html=fs.readFileSync(path.join(web,'index.html'),'utf8'),manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
if(createHash('sha256').update(html).digest('hex')!==manifest['index.html'].sha256)throw Error('Shell identity');
const a=html.indexOf('// DEV opt-in recorder.'),b=html.indexOf('const GODOT_CONFIG = ',a);if(a<0||b<a)throw Error('Recorder missing');
const script=html.slice(a,b),receiver='https://ever-deeper-spillrapporter.corpax88.chatgpt.site';
const server=http.createServer((req,res)=>{res.writeHead(200,{'Content-Type':'text/html'});res.end('<html><body style="background:#0c131b;color:white;font:18px system-ui"><h1>Report transport test</h1><canvas id="canvas"></canvas><script>'+script+'</script></body></html>')});await new Promise(r=>server.listen(0,'127.0.0.1',r));
const origin='http://127.0.0.1:'+server.address().port,checks=[];
function check(name,ok){checks.push({name,passed:!!ok});if(!ok)throw Error(name);}
let failed=null;
for(const [name,engine] of [['chromium',chromium],['webkit',webkit]]){
 const browser=await engine.launch({headless:true}),ctx=await browser.newContext({viewport:{width:844,height:390},hasTouch:true});let mode='ack';
 try {
  await ctx.route(receiver+'/**',async route=>{
   if(mode==='redirect'&&!route.request().url().includes('/signed-in'))return route.fulfill({status:302,headers:{Location:receiver+'/signed-in#ready'}});
   const markup=`<html><body><h1>Receiver fixture</h1><a id="back">Return with receipt</a><script>
     function take(r){window.report=r;document.getElementById('back').href=${JSON.stringify(origin)}+'/#report-received='+r.id;window.opener?.postMessage({type:'ever-deeper-report-saved',id:r.id},${JSON.stringify(origin)});}
     const value=location.hash.startsWith('#report=')?location.hash.slice(8):'';
     if(value)take(JSON.parse(atob(value.replace(/-/g,'+').replace(/_/g,'/'))));
     window.addEventListener('message',e=>{if(e.origin===${JSON.stringify(origin)}&&e.source===window.opener&&e.data.type==='ever-deeper-report')take(e.data.report)});
     if(!value)window.opener?.postMessage({type:'ever-deeper-report-ready'},${JSON.stringify(origin)});
     <\/script></body></html>`;
   await route.fulfill({contentType:'text/html',headers:mode==='no-opener'?{'Cross-Origin-Opener-Policy':'same-origin'}:{},body:markup});
  });
  const page=await ctx.newPage();await page.goto(origin);await page.waitForFunction(()=>window.everDeeperReports?.status().ready);
  async function seed(){await page.evaluate(()=>{const api=window.everDeeperReports;api.clear();if(!api.begin('1.0.0-dev.15.7'))throw Error('begin');api.append({seconds:5,frames:150,window_ms:5000,fps:30});api.finish();});await page.waitForTimeout(150);}
  await seed();
  await page.evaluate(()=>{const original=window.open;window.open=(...args)=>{window.open=original;return null};window.everDeeperReports.send();});
  check(name+'-blocked-popup-link',await page.locator('#report-transfer-link').isVisible());
  await page.screenshot({path:path.join(out,name+'-fallback.png')});
  let pending=ctx.waitForEvent('page');await page.locator('#report-transfer-link').tap();let popup=await pending;await popup.waitForLoadState('domcontentloaded');
  await page.waitForFunction(()=>window.everDeeperReports.status().saved);check(name+'-fallback-acknowledged',!(await page.evaluate(()=>window.everDeeperReports.status().pending)));await popup.close();
  mode='no-opener';await seed();pending=ctx.waitForEvent('page');await page.evaluate(()=>window.everDeeperReports.send());popup=await pending;await popup.waitForLoadState('domcontentloaded');
  // Return-link recovery also covers policies/browsers that remove window.opener.
  await popup.locator('#back').click();await popup.waitForFunction(()=>window.everDeeperReports?.status().ready);
  check(name+'-receipt-return-clears-pending',!(await popup.evaluate(()=>window.everDeeperReports.status().pending)));await popup.close();
  await page.reload();await page.waitForFunction(()=>window.everDeeperReports?.status().ready);
  mode='redirect';await seed();pending=ctx.waitForEvent('page');await page.evaluate(()=>window.everDeeperReports.send());popup=await pending;await popup.waitForLoadState('domcontentloaded');
  await page.waitForFunction(()=>window.everDeeperReports.status().saved);check(name+'-redirect-handshake',!(await page.evaluate(()=>window.everDeeperReports.status().pending)));await popup.close();
  const denied=await ctx.newPage();await denied.addInitScript(()=>Object.defineProperty(window,'indexedDB',{get(){throw Error('Storage denied test')}}));await denied.goto(origin);
  const status=await denied.evaluate(()=>window.everDeeperReports.status());check(name+'-storage-denial-contained',status.ready&&status.storage_error);check(name+'-memory-recording',await denied.evaluate(()=>window.everDeeperReports.begin('1.0.0-dev.15.7')));
 } catch(e){failed=String(e);console.error(e);} finally {await browser.close();}
 if(failed)break;
}
server.close();fs.writeFileSync(path.join(out,'recovery.json'),JSON.stringify({passed:!failed,error:failed,checks,files:manifest,source_commit:process.env.CANDIDATE_SOURCE,version:'1.0.0-dev.15.7',scope:'Exact exported browser script; popup, receipt, simulated redirect and denied-storage contracts. Not real ChatGPT sign-in or physical iPhone proof.'},null,2));
if(failed)process.exitCode=1;
