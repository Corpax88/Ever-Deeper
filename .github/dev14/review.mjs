import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);
fs.mkdirSync(output,{recursive:true});
const manifest=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(manifest)){
 const file=path.join(web,name),h=createHash('sha256');
 for await(const block of fs.createReadStream(file))h.update(block);
 if(h.digest('hex')!==want.sha256||fs.statSync(file).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname;
 const file=path.resolve(web,'.'+name);
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html'&&url.searchParams.has('qa')){
  const text=fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{
   const config=JSON.parse(raw);config.args=['--','--qa-dev14-review','--expected-version=1.0.0-dev.14.1'];return 'const GODOT_CONFIG = '+JSON.stringify(config)+';';
  });res.end(text);
 }else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page=await context.newPage();page.setDefaultTimeout(120000);
const cdp=await context.newCDPSession(page);
const checks=[],messages=[];let runtime=null,id=0,failed=null;
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>{messages.push('PAGEERROR: '+e.message);fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
const state=()=>page.evaluate(()=>window.DEV14_STATE);
const delay=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(label,predicate,timeout=90000){
 const started=Date.now();let s;
 while(Date.now()-started<timeout){
  s=await state();
  if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));
  if(predicate(s))return s;
  if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|Native Worn .*rejected/.test(m)))throw Error(label+': runtime error (see console.log)');
  await delay(200);
 }
 throw Error(label+' timeout: '+JSON.stringify(s));
}
async function command(kind,extra={}){
 const wanted=++id;await page.evaluate(data=>window.DEV14_COMMAND=JSON.stringify(data),{kind,id:wanted,...extra});
 await wait(kind,s=>s?.id===wanted);
 await delay(500);
 return state();
}
async function capture(name){
 const before=await state();await page.screenshot({path:path.join(output,name+'.png'),timeout:60000});
 const after=await state();checks.push({name,before,after});
 fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));console.log('DEV14_CAPTURE',name);
}
async function nativeReady(){return wait('native ready',s=>s?.native?.active&&s.gear==='worn'&&s.native.updates>3);}
async function mine(name){
 const before=await nativeReady();await page.keyboard.down('Space');
 const hit=await wait(name+' damage',s=>s?.impact>before.impact&&s.health<before.health,30000);
 if(!hit.impact_target_valid||hit.hit_phase<=0||hit.cycle<=0)throw Error(name+' invalid committed contact');
 await capture(name);await page.keyboard.up('Space');
 await wait(name+' release',s=>!s?.mining,10000);
 checks.push({name:name+'-damage',before,hit});
}
try{
 const url='http://127.0.0.1:'+server.address().port;
 await page.goto(url,{waitUntil:'domcontentloaded',timeout:120000});
 await page.waitForFunction(()=>window.everDeeperVersion==='1.0.0-dev.14.1',null,{timeout:240000});
 await delay(1500);await capture('00-normal-dev14-menu');
 runtime=await page.evaluate(()=>{const c=document.querySelector('canvas'),g=c?.getContext('webgl2'),e=g?.getExtension('WEBGL_debug_renderer_info');return {viewport:[innerWidth,innerHeight],dpr:devicePixelRatio,renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g?.isContextLost()};});
 runtime.browser=browser.version();runtime.platform=process.platform;
 if(!runtime.renderer||runtime.lost||/SwiftShader|llvmpipe|software/i.test(runtime.renderer))throw Error('Required graphical Mac renderer unavailable');
 await page.goto(url+'/?qa=1',{waitUntil:'domcontentloaded',timeout:120000});
 await wait('ordinary QA startup',s=>s?.version==='1.0.0-dev.14.1',240000);
 await command('surface_regressions');
 for(const direction of ['up','right','down','left']){
  await command('moss',{direction,rush:direction==='left'});await mine('moss-'+direction);
 }
 await command('moss',{direction:'right',rush:true});
 let start=await nativeReady();await page.keyboard.down('Space');
 let held=await wait('Moss held cycles',s=>s?.swing>=start.swing+2&&s.impact>=start.impact+2,30000);
 checks.push({name:'moss-held-rush',before:start,after:held});
 await page.keyboard.up('Space');await page.keyboard.down('ArrowDown');await delay(500);await page.keyboard.up('ArrowDown');
 await wait('cancel and walk',s=>!s?.mining,10000);await capture('moss-walk-exit');
 for(const direction of ['up','right','down','left']){
  await command('endless',{direction});await mine('endless-'+direction);
 }
 await command('gear',{gear:'iron'});await wait('iron visible',s=>s?.gear==='iron'&&!s.native.active);await capture('iron-restored');
 await command('gear',{gear:'burrower'});await wait('drill visible',s=>s?.gear==='burrower'&&!s.native.active);await capture('drill-restored');
 await command('gear',{gear:'worn',outfit:'deepheart'});await nativeReady();await capture('worn-outfit-reentry');
 for(const world of ['surface','depth','hub','deepheart']){
  await command(world);await nativeReady();const s=await state();if(s.active_rigs!==1)throw Error('Inactive world retains native renderer: '+world);
  await capture(world+'-ordinary');
 }
 await command('surface');await nativeReady();let s=await state();
 const touch={x:s.mine_button[0]/s.viewport[0]*844,y:s.mine_button[1]/s.viewport[1]*390};
 await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{id:7,x:touch.x,y:touch.y,radiusX:5,radiusY:5,force:1}]});
 await wait('touch mining',v=>v?.impact>s.impact&&v.health<s.health,30000);
 await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await wait('touch release',v=>!v?.mining,10000);
 await capture('surface-touch-release');
 await command('pause');await wait('ordinary pause menu',s=>s?.menu===true);await capture('dev14-pause');
 await command('resume');const resumed=await wait('ordinary resume',s=>s?.menu===false&&s.native?.active);await nativeReady();await page.keyboard.down('ArrowDown');await delay(400);await page.keyboard.up('ArrowDown');await wait('resumed input',s=>s?.position[1]>resumed.position[1]+2&&!s.mining);await capture('dev14-resumed');
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|ERROR:/.test(m));if(errors.length)throw Error('Runtime errors: '+errors.slice(0,4).join('\n'));
 console.log('DEV14_RENDERED_GAMEPLAY_PASSED');
}catch(e){failed=String(e.stack||e);console.error(failed);try{await capture('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,version:'1.0.0-dev.14.1',files:manifest,runtime,checks,bootstrap_fixture:'HTML injects only explicit QA launch args. Named non-persistent fixture uses ordinary DEV jumps/equipment, clears queued achievement toasts and exercises real input/menu paths. Main scene and game package bytes unchanged.',physical_iphone_verified:false,continuous_motion_or_fps_certified:false},null,2));
 await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
