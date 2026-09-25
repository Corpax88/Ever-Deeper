import {PNG} from 'pngjs';
import {chromium,webkit} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const browserName=process.env.REVIEW_BROWSER||'chromium';
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
 if(file.endsWith('index.html'))res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-skills-browser'];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=browserName==='webkit'?await webkit.launch({headless:true}):await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:776,height:420},deviceScaleFactor:3,hasTouch:true,isMobile:true});
await context.addInitScript(()=>{
 const meter=window.__gpuMeter={active:false,counts:{},raf:0};
 for(const name of ['fenceSync','getSyncParameter','checkFramebufferStatus']){
  const fn=WebGL2RenderingContext.prototype[name];
  WebGL2RenderingContext.prototype[name]=function(...args){if(meter.active)meter.counts[name]=(meter.counts[name]||0)+1;return fn.apply(this,args);};
 }
 const raf=window.requestAnimationFrame;
 window.requestAnimationFrame=cb=>raf.call(window,t=>{if(meter.active)meter.raf++;return cb(t)});
 meter.begin=()=>{meter.counts={};meter.raf=0;meter.active=true;};
 meter.stop=()=>{meter.active=false;return {counts:meter.counts,raf:meter.raf,scope:'Call counts only, not GPU time'};};
});
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

const pairs=[],captures=[],inventories=[];
async function tap(name){const s=await state(),r=s.buttons[name];check('target '+name,Array.isArray(r)&&r[2]>0&&r[3]>0);await page.touchscreen.tap((r[0]+r[2]/2)/s.viewport[0]*(await page.viewportSize()).width,(r[1]+r[3]/2)/s.viewport[1]*(await page.viewportSize()).height);await page.mouse.move(1,1);await delay(350);}
async function parity(label){
 await command('shared_freeze');const shots=[];
 for(const mode of ['shared_candidate','shared_reference','shared_candidate']){
  await command(mode);await page.mouse.move(1,1);await delay(650);
  const bytes=await page.screenshot(),name=label+'-'+shots.length;fs.writeFileSync(path.join(output,name+'.png'),bytes);shots.push(bytes);captures.push(name);
  await page.evaluate(()=>window.__gpuMeter.begin());await delay(700);const gpu=await page.evaluate(()=>window.__gpuMeter.stop()),n=gpu.counts.checkFramebufferStatus,expected=mode==='shared_reference'?3:2;
  check('sync '+label+' '+mode,n>5&&gpu.counts.fenceSync===expected*n&&gpu.counts.getSyncParameter===expected*n,{gpu});inventories.push({label,mode,state:await state(),gpu});
 }
 const a=PNG.sync.read(shots[0]);for(let i=1;i<3;i++){const b=PNG.sync.read(shots[i]);let max=0,changed=0;check('size '+label,a.width===b.width&&a.height===b.height);for(let n=0;n<a.data.length;n++){const d=Math.abs(a.data[n]-b.data[n]);max=Math.max(max,d);if(d)changed++;}const row={label,index:i,max,changed};pairs.push(row);check('pixels '+label+' '+i,max===0,row);}
 await command('shared_resume');
}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:90000});await wait('menu',s=>s?.menu&&s?.buttons,180000);
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:g.getParameter(e?e.UNMASKED_RENDERER_WEBGL:g.RENDERER),browser:navigator.userAgent,dpr:devicePixelRatio,canvas:[g.canvas.width,g.canvas.height]};});check('Apple GPU',process.platform==='darwin'&&/Apple|Metal/.test(runtime.renderer));
 await tap('new_game');await wait('new game',s=>!s.menu&&s.native?.active);
 for(const viewport of [{width:776,height:420},{width:667,height:375},{width:900,height:600}]){
  await page.setViewportSize(viewport);await delay(1000);const tag=viewport.width+'x'+viewport.height;
  check('single owned UI '+tag,(await state()).shared_ui_roots===1);
  await parity(tag+'-hud');await tap('hud_mole');await wait('journal open',s=>s.mole_open);
  for(let i=0;i<3;i++){await tap('mole_tab_'+i);await wait('tab '+i,s=>s.journal_tab===['together','skills','how'][i]);await parity(tag+'-tab'+i);}
  await tap('mole_close');await wait('touch close',s=>!s.mole_open);
  await tap('hud_mole');await wait('reopen',s=>s.mole_open);await page.keyboard.press('Escape');await wait('ui_cancel close',s=>!s.mole_open&&!s.menu);
  await tap('hud_bag');await wait('inventory open',s=>s.inventory_open);await shot(tag+'-inventory');captures.push(tag+'-inventory');await tap('inventory_close');await wait('inventory close',s=>!s.inventory_open);
  await command('pause');await wait('pause',s=>s.menu);await tap('continue');await wait('continue',s=>!s.menu&&s.native?.active);
 }
 await command('deepheart');await wait('Deepheart',s=>s.native?.active);await command('shared_presentation_on');await wait('hidden once',s=>!s.shared_ui_visible&&s.shared_ui_saved===1);await shot('presentation-hidden');captures.push('presentation-hidden');
 await command('shared_presentation_off');await wait('restored',s=>s.shared_ui_visible&&s.shared_ui_saved===0);await tap('hud_mole');await wait('journal after presentation',s=>s.mole_open);await shot('presentation-restored-journal');captures.push('presentation-restored-journal');await tap('mole_close');
 await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind:'shared_reload',id:++id});await delay(1000);await wait('scene reload menu',s=>s?.menu&&s?.shared_ui_roots===1,180000);await tap('new_game');await wait('scene reload game',s=>!s.menu&&s.native?.active);await tap('hud_mole');await wait('reloaded journal',s=>s.mole_open);await shot('scene-reloaded-journal');captures.push('scene-reloaded-journal');await tap('mole_close');
 check('no runtime errors',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)));
}catch(e){failed=String(e);console.error(e);try{await shot('failure')}catch{}}
finally{fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,files,runtime,checks,pairs,captures,inventories,physical_iphone_verified:false,scope:'Production shared HUD topology: real touch journal tabs/close, ui_cancel, three sizes, inventory, pause, Deepheart hide/restore, actual scene reload. Explicit original layer topology A/B/A isolates visual parity; native empty canvas remains disabled in both modes. No FPS claim.'},null,2));await browser.close();server.close();}
if(failed)process.exitCode=1;
