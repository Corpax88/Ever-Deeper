import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const reference=process.env.NODE_ASSETS_REFERENCE==='1';
const version='1.0.0-dev.15.42',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const h=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))h.update(b);
 if(h.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost'),name=url.pathname==='/'?'/index.html':url.pathname,file=path.resolve(web,'.'+name);
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--',flavor==='live'?'--qa-production-browser':'--qa-skills-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true,});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(90000);
const checks=[],messages=[];let failed=null,runtime=null,id=0;
const save=()=>fs.writeFileSync(path.join(output,'checks.json'),JSON.stringify(checks,null,2));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(label,predicate,timeout=30000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(150);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
function check(name,ok,details){checks.push({name,passed:!!ok,...details});save();if(!ok)throw Error(name);}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function point(name){const s=await state(),v=page.viewportSize(),r=s.buttons[name];if(!r)throw Error('Missing button '+name);return {x:(r[0]+r[2]/2)/s.viewport[0]*v.width,y:(r[1]+r[3]/2)/s.viewport[1]*v.height};}
async function tap(name){const p=await point(name);await page.touchscreen.tap(p.x,p.y);await delay(250);}
async function touch(type,p){await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});}
async function shot(name){await page.screenshot({path:path.join(output,name+'.jpg'),quality:95,timeout:60000});const s=await state();if(s.treasury.inside)check('clear-treasury-hud-'+name,!s.hud_goal_visible,{});checks.push({name,passed:true,state:s});save();console.log('SKILLS_CAPTURE',name);}
function inside(r,s){return r[0]>=0&&r[1]>=0&&r[0]+r[2]<=s.viewport[0]+1&&r[1]+r[3]<=s.viewport[1]+1;}
function overlap(a,b){return a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1];}

async function ready(){return wait('active game',s=>!s?.menu&&s?.game_started&&s.player_controls_enabled&&s.actual_map?.world_active);}
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('fixture ready',s=>s?.version===version&&s.buttons,180000);
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio};});
 check('graphical-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});


 async function walk(direction,predicate,label,vertical=0){
  const s=await state(),jr=s.buttons.joystick,vp=page.viewportSize();
  const start={x:(jr[0]+jr[2]*.20)/s.viewport[0]*vp.width,y:(jr[1]+jr[3]*.70)/s.viewport[1]*vp.height};
  await touch('touchStart',start);await touch('touchMove',{x:start.x+32*direction,y:start.y+32*vertical});
  await wait(label,predicate,10000);await touch('touchEnd',start);
 }
 await command('treasury_fixture');await ready();
 await walk(1,s=>s.treasury.inside,'walk through east doorway');
 for(const amount of [0,56000,100000]){
  await command('treasury_visual',{amount,index:26});await delay(350);await tap('gold_podium');
  await wait('actual podium opens preview',s=>s.treasury_goal.open);
  const s=await state();
  check('art-and-data-'+amount,s.mod_preview.texture_ready&&s.mod_preview.art_visible&&s.mod_preview.title==='RESONANCE'&&s.mod_preview.progress===amount&&s.treasury_goal.claim_disabled===(amount<100000),{});
  check('panel-contained-'+amount,inside(s.mod_preview.panel,s)&&inside(s.mod_preview.source,s),{});
  check('reading-order-'+amount,s.mod_preview.art[1]+s.mod_preview.art[3]<=s.mod_preview.detail[1]&&s.mod_preview.detail[1]+s.mod_preview.detail[3]<=s.mod_preview.bar[1]&&s.buttons.treasury_close[1]+s.buttons.treasury_close[3]<=s.mod_preview.source[1],{});
  await shot('gold-'+amount);await tap('treasury_close');await ready();
 }
 await tap('gold_podium');await wait('full preview opens',s=>s.treasury_goal.open);
 await tap('treasury_claim');await wait('earned mod on',s=>s.treasury_goal.saved.resonance_claimed&&s.resonance.enabled);
 check('claim-preserves-gold',(await state()).treasury.totals.wallet_gold===100000,{});
 await tap('treasury_pin');await wait('goal pinned',s=>s.treasury_goal.saved.pinned==='wallet_gold');await shot('claimed-on');
 await tap('treasury_claim');await wait('toggle off',s=>!s.treasury_goal.saved.resonance_enabled&&!s.resonance.enabled);await shot('claimed-off');
 await tap('treasury_claim');await wait('toggle on again',s=>s.treasury_goal.saved.resonance_enabled&&s.resonance.enabled);
 for(const viewport of [{width:667,height:375},{width:932,height:430},{width:844,height:390}]){
  await page.setViewportSize(viewport);await delay(700);const s=await state();
  for(const name of ['treasury_claim','treasury_pin','treasury_close'])check('touch-contained-'+viewport.width+'-'+name,inside(s.buttons[name],s),{});
  check('no-button-overlap-'+viewport.width,!overlap(s.buttons.treasury_claim,s.buttons.treasury_pin)&&!overlap(s.buttons.treasury_pin,s.buttons.treasury_close),{});
  await shot('mobile-'+viewport.width);
 }
 await tap('treasury_pin');await wait('untracked',s=>s.treasury_goal.saved.pinned==='');
 await tap('treasury_pin');await wait('retracked',s=>s.treasury_goal.saved.pinned==='wallet_gold');
 await tap('treasury_close');await ready();await command('treasury_save');await command('treasury_restore');
 check('save-retains-claim-toggle-pin',(await state()).treasury_goal.saved.resonance_claimed&&(await state()).treasury_goal.saved.resonance_enabled&&(await state()).treasury_goal.saved.pinned==='wallet_gold',{});
 await command('treasury_preview_other');await wait('copper preview',s=>s.treasury_goal.open&&s.treasury_goal.kind==='copper');
 check('other-mod-not-invented',!(await state()).mod_preview.art_visible&&(await state()).mod_preview.title==='COLLECTION',{});await shot('collection-copper');
 await tap('treasury_close');await ready();
 await command('treasury_earned_drill');await ready();
 check('earned-mod-still-active-in-deep',(await state()).resonance.enabled,{});await shot('returned-to-game');
} catch(e){failed=e.stack||String(e);console.error(failed);}
finally{
 await context.close();await browser.close();server.close();
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,failure:failed,version,files,source:process.env.GITHUB_SHA,runtime,checks},null,2));
 if(failed)process.exitCode=1;
}
