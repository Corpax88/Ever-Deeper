import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output,flavor]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const reference=process.env.NODE_ASSETS_REFERENCE==='1';
const version='1.0.0-dev.15.38',files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
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
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:3,hasTouch:true,recordVideo:{dir:path.join(output,"video"),size:{width:844,height:390}}});
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

async function ready(){return wait('active game',s=>!s?.menu&&s?.game_started&&s.player_controls_enabled&&((s.native?.active&&s.native.updates>3)||(s.drill_level>0&&s.world_active)));}
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
 await command('treasury_fixture');await ready();await shot('01-hub-shop-door');
 await walk(1,s=>s.treasury.inside,'walk through east doorway');await delay(300);await shot('02-empty-room');
 check('all-resource-bays',(await state()).treasury.bay_count===27,{});
 check('central-delivery-zone',(await state()).treasury.zone[0]===2000&&(await state()).treasury.zone[1]===1600,{});
 await command('treasury_zone');
 await walk(1,s=>s.treasury.delivering,'walk onto central plate');
 const initial={stone:8000,copper:4000,echo_crystal:1800,prismite:2400,starshard:3200,wallet_gold:20000};
 function conserved(t){return Object.entries(initial).every(([k,n])=>(t.totals[k]||0)+(k==='wallet_gold'?t.wallet:t.cargo[k]||0)===n);}
 await wait('mixed continuous stream',s=>new Set(s.treasury.packet_kinds).size>=4);
 check('multiple-materials-simultaneously',new Set((await state()).treasury.packet_kinds).size>=4,{});
 await shot('03-airborne');await delay(350);await shot('flow-02');await delay(350);await shot('flow-03');
 await wait('first resources landed',s=>s.treasury.landings>=2);let partial=(await state()).treasury;
 check('partial-conservation',conserved(partial)&&partial.cargo.stone>0,{partial});await shot('04-partial-delivery');
 await tap('hud_menu');await wait('menu paused',s=>s.skills_open);const paused=(await state()).treasury;await delay(2000);
 check('menu-pauses-delivery',paused.inside&&(await state()).treasury.inside&&JSON.stringify((await state()).treasury.totals)===JSON.stringify(paused.totals),{});
 await tap('skills_close');await wait('menu closed',s=>!s.skills_open);
 await command('treasury_exit_approach');await walk(-1,s=>!s.treasury.inside,'walk back to hub');
 const exited=(await state()).treasury;await delay(1800);
 check('exit-cancels-undelivered',conserved(exited)&&exited.packets===0&&exited.remaining_batches===0&&JSON.stringify(exited.totals)===JSON.stringify((await state()).treasury.totals),{exited});await shot('05-left-with-remainder');
 await command('treasury_door');await walk(1,s=>s.treasury.inside,'walk back into treasury');
 await command('treasury_save');await command('treasury_restore');let loaded=(await state()).treasury;
 check('save-load-conservation',conserved(loaded)&&JSON.stringify(loaded.totals)===JSON.stringify(exited.totals),{loaded});await shot('06-reloaded-partial');
 await command('treasury_zone');await walk(1,s=>s.treasury.delivering,'resume central donation');
 await wait('all deliveries complete',s=>!s.treasury.delivering&&s.treasury.wallet===0,65000);
 let complete=(await state()).treasury;
 check('all-donations-exactly-once',conserved(complete)&&Object.keys(initial).every(k=>complete.totals[k]===initial[k]),{complete});await shot('07-complete');
 await command('treasury_milestones');
 await walk(1,s=>s.treasury.delivering,'start thousand-boundary delivery');
 const upgradesBefore=(await state()).treasury.upgrades;
 await wait('milestone stream mixed',s=>new Set(s.treasury.packet_kinds).size>=2);
 await shot('milestone-mixed');
 await wait('milestone delivery complete',s=>!s.treasury.delivering,15000);
 const milestone=(await state()).treasury;
 check('every-thousand-celebrated',milestone.upgrades-upgradesBefore===3&&milestone.totals.stone===3010&&milestone.totals.copper===20,{milestone});

 for(const amount of [1,556,10000,50000,100000]){
  const indices=amount===100000?Array.from({length:27},(_,i)=>i):[26];
  for(const index of indices){await command('treasury_visual',{amount,index});await delay(200);await shot('stack-'+amount+'-'+index);}
 }
 await command('treasury_visual',{amount:99999,index:26});await delay(300);await tap('gold_podium');
 await wait('actual podium opens goal',s=>s.treasury_goal.open);
 check('incomplete-claim-locked',(await state()).treasury_goal.claim_disabled,{});await shot('goal-locked');
 await tap('treasury_close');await wait('close goal',s=>!s.treasury_goal.open);
 await command('treasury_visual',{amount:100000,index:26});await delay(250);await tap('gold_podium');
 await wait('full goal opens',s=>s.treasury_goal.open&&!s.treasury_goal.claim_disabled);await shot('goal-ready');
 await tap('treasury_claim');await wait('claim earned mod',s=>s.treasury_goal.saved.resonance_claimed&&s.resonance.enabled);
 check('claim-keeps-full-pile',(await state()).treasury.totals.wallet_gold===100000,{});
 await tap('treasury_pin');await wait('goal pinned',s=>s.treasury_goal.saved.pinned==='wallet_gold');await shot('goal-claimed');
 await tap('treasury_claim');await wait('owned mod off',s=>!s.treasury_goal.saved.resonance_enabled&&!s.resonance.enabled);
 await tap('treasury_claim');await wait('owned mod on',s=>s.treasury_goal.saved.resonance_enabled&&s.resonance.enabled);
 await tap('treasury_close');await command('treasury_save');await command('treasury_restore');
 check('claimed-mod-and-pin-survive-save',(await state()).treasury_goal.saved.resonance_claimed&&(await state()).treasury_goal.saved.resonance_enabled&&(await state()).treasury_goal.saved.pinned==='wallet_gold',{});
 await command('treasury_exit_approach');await walk(-1,s=>!s.treasury.inside,'exit completed treasury');
 await command('treasury_map_first');await ready();await delay(500);await shot('goal-pinned-hud');
 await tap('minimap');await wait('tap minimap opens map',s=>s.skills_open&&s.actual_map.expanded);
 check('first-world-three-hidden',(await state()).actual_map.known.join(',')==='true,false,false,false',{});await shot('map-first-world');
 await tap('skills_close');await command('treasury_map_all');await tap('minimap');await wait('all-biomes-map',s=>s.skills_open&&s.actual_map.expanded);
 check('all-four-unlocked-map',(await state()).actual_map.known.every(Boolean),{});await shot('map-all-worlds');
 await tap('skills_close');
 for(const kind of ['scale_depth1','scale_deep']){
  await command(kind,kind==='scale_depth1'?{mine_id:'mossMine'}:{});await ready();await delay(300);
  check('actual-resource-markers-'+kind,(await state()).actual_map.markers>0,{});
  await tap('minimap');await wait('underground-map',s=>s.skills_open&&s.actual_map.expanded);await shot('map-'+kind);await tap('skills_close');
 }
 await command('treasury_earned_drill');await ready();
 check('earned-mod-active-in-deep',(await state()).resonance.enabled,{});
 const drillState=await state(),vp=page.viewportSize(),jr=drillState.buttons.joystick;
 const mineTouch={x:drillState.mine_button[0]/drillState.viewport[0]*vp.width,y:drillState.mine_button[1]/drillState.viewport[1]*vp.height};
 const steerTouch={x:(jr[0]+jr[2]*.2)/drillState.viewport[0]*vp.width,y:(jr[1]+jr[3]*.7)/drillState.viewport[1]*vp.height};
 const dual=(type,points)=>cdp.send('Input.dispatchTouchEvent',{type,touchPoints:points.map((p,i)=>({id:i+1,...p,radiusX:5,radiusY:5,force:1}))});
 const burstsBefore=drillState.resonance.bursts;
 await dual('touchStart',[mineTouch,steerTouch]);await dual('touchMove',[mineTouch,{x:steerTouch.x,y:steerTouch.y+32}]);
 await wait('earned mod charges through mining',s=>s.resonance.charge>.55,30000);await shot('earned-mod-charging');
 await wait('earned mod fires through mining',s=>s.resonance.bursts>burstsBefore,30000);await dual('touchEnd',[]);
 await wait('earned wave excavates',s=>s.resonance.excavated>0,15000);await shot('earned-mod-tunnel');
 const errors=messages.filter(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m));check('no-runtime-errors',errors.length===0,{errors});
}catch(e){failed=String(e.stack||e);console.error(failed);try{await shot('failure');}catch{}}
finally{
 fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({passed:!failed,error:failed,source_commit:process.env.GITHUB_SHA,version,flavor,files,runtime,checks,physical_iphone_verified:false},null,2));
 await context.close();await browser.close();await new Promise(r=>server.close(r));
}
if(failed)process.exitCode=1;
