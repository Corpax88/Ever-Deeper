import {webkit} from '@playwright/test';import fs from 'node:fs';import path from 'node:path';import http from 'node:http';
const [root,out]=process.argv.slice(2);fs.mkdirSync(out,{recursive:true});
const server=http.createServer((req,res)=>{const f=path.resolve(root,'.'+(req.url==='/'?'/index.html':req.url));if(!f.startsWith(path.resolve(root)+'/')||!fs.existsSync(f)){res.writeHead(404).end();return;}res.setHeader('Content-Type',f.endsWith('.js')?'application/javascript':f.endsWith('.wasm')?'application/wasm':f.endsWith('.html')?'text/html':'application/octet-stream');
 if(f.endsWith('.html'))res.end(fs.readFileSync(f,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,s)=>{const c=JSON.parse(s);c.args=['--','--qa-telemetry-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));else fs.createReadStream(f).pipe(res);});
await new Promise(r=>server.listen(0,'127.0.0.1',r));const browser=await webkit.launch();const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2});const page=await context.newPage();const errors=[];page.on('pageerror',e=>errors.push(String(e)));
const rows=[];let id=0;
try{
 await page.goto('http://127.0.0.1:'+server.address().port);await page.waitForFunction(()=>window.DEV14_STATE?.menu,{},{timeout:180000});
 await page.evaluate(x=>window.DEV14_COMMAND=JSON.stringify({id:x,kind:'moss',gear:'ember',direction:'up'}),++id);await page.waitForFunction(x=>window.DEV14_STATE?.id===x,id);
 await page.waitForTimeout(1500);
 for(const enabled of [false,true,true,false]){
  const row=await page.evaluate(async enabled=>{const d=window.everDeeperDiagnostics;if(enabled)d.start();else d.stop();const times=[];let prev=0;const started=performance.now();await new Promise(resolve=>{function tick(t){if(prev)times.push(t-prev);prev=t;if(performance.now()-started<8000)requestAnimationFrame(tick);else resolve();}requestAnimationFrame(tick);});const diagnostics=enabled?d.snapshot():null;d.stop();return {enabled,seconds:(performance.now()-started)/1000,fps:1000*times.length/times.reduce((a,b)=>a+b,0),max:Math.max(...times),diagnostics};},enabled);rows.push(row);
 }
 await page.screenshot({path:path.join(out,'actual-game.png')});
 if(errors.length)throw Error(errors.join('\n'));
 if(!rows.filter(r=>r.enabled).every(r=>r.diagnostics?.callback_ms?.[0]>20))throw Error('No engine-frame coverage');
 console.log('OBSERVER_ABBA_COMPLETE',JSON.stringify(rows.map(({enabled,fps,max})=>({enabled,fps,max}))));
}finally{fs.writeFileSync(path.join(out,'report.json'),JSON.stringify({browser:browser.version(),rows,errors,physical_iphone:false,note:'8-second ABBA windows retained; drift and observer effects are not a phone FPS prediction.'},null,2));await browser.close();server.close();}
