import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version='1.0.0-dev.15.7',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-fps-review'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(90000);
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
async function parity(label){
 await command('reference');const reference=await shot(label+'-reference');
 await command('cached');const candidate=await shot(label+'-cached');
 await command('reference'); const restored=await shot(label+'-restored-reference');
 check('restored-parity-'+label,reference===restored,{reference,candidate,restored});
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});
 await wait('menu',s=>s?.menu,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e.UNMASKED_RENDERER_WEBGL),user_agent:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});
 check('apple-gpu',/Apple|Metal/.test(runtime.renderer),{runtime});
 check('version',(await state()).version===version);
 // Same game/geometry, frozen at the same simulation instant, original versus cache.
 for(const mine of ['emberMine','mossMine','moonMine','starMine']){
  await command('setup',{mine});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(1600);
  await command('freeze');await parity(mine+'-intact');
  await command('damage');await parity(mine+'-damaged');
  await command('break');await parity(mine+'-broken');
  await command('restore');await parity(mine+'-restored');
 }
 // Equal real held-mining workload, fixed seed/target, reference-candidate-reference.
 // Setup and screenshots are outside every timed window. No redraw-only synthetic FPS.
 for(const [label,cached] of [['reference-a',false],['cached',true],['reference-b',false]]){
  await command('setup',{mine:'emberMine',cached,durable:true});await wait('native',s=>s?.native?.active&&s.native.updates>3);await delay(2500);
  const before=await state(),p={x:before.mine_button[0]/before.viewport[0]*844,y:before.mine_button[1]/before.viewport[1]*390};
  await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});
  await wait('mining contact',s=>s?.impact>before.impact);await delay(1500);
  await command('begin');await delay(18000);const ended=await command('end');
  await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait('release',s=>!s.mining);
  windows.push({label,cached,...ended.result,impacts:ended.impact-before.impact});
  check('held-mining-'+label,ended.impact>=before.impact+8&&ended.result.frames>200,{result:windows.at(-1)});
  await shot('mining-'+label);
 }
 const perSecond=w=>(w.sections.draw_callback_usec+w.sections.setup_usec)/w.seconds;
 const candidate=windows[1],reference=Math.min(perSecond(windows[0]),perSecond(windows[2]));
 check('measurement-complete',candidate.frames>200,{reference_usec_per_second:reference,cached_usec_per_second:perSecond(candidate),reduction:1-perSecond(candidate)/reference});
 check('floor-draws-reduced',candidate.draw_calls < Math.min(windows[0].draw_calls,windows[2].draw_calls),{draw_calls:windows.map(w=>w.draw_calls)});
 await command('setup',{mine:'emberMine',cached:true});await delay(1000);
 const a=await state();await page.keyboard.down('ArrowDown');await delay(650);await page.keyboard.up('ArrowDown');const b=await state();
 check('movement-after-mining',Math.hypot(a.position[0]-b.position[0],a.position[1]-b.position[1])>10,{a:a.position,b:b.position});
 await command('freeze');await parity('ember-after-camera-move');
}catch(e){failed=String(e);console.error(e);}finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,runtime,checks,windows,physical_iphone_verified:false,scope:'Depth-one terrain cache; same-package original A/B/A held mining and exact frozen full-frame parity. No claim of physical iPhone 60 FPS or proven cause of recorded 250ms stall.'},null,2));
 await browser.close();server.close();
}
if(failed)process.exitCode=1;
