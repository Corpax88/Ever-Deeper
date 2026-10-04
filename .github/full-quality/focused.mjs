import {chromium} from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {createHash} from 'node:crypto';
const [web,output]=process.argv.slice(2);fs.mkdirSync(output,{recursive:true});
const version=process.env.EXPECTED_VERSION||'1.0.0-dev.15.54';
const files=JSON.parse(fs.readFileSync(path.join(web,'manifest.json')));
for(const [name,want] of Object.entries(files)){
 const hash=createHash('sha256');for await(const b of fs.createReadStream(path.join(web,name)))hash.update(b);
 if(hash.digest('hex')!==want.sha256||fs.statSync(path.join(web,name)).size!==want.size)throw Error('Candidate identity: '+name);
}
const mime={'.html':'text/html','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png'};
const server=http.createServer((req,res)=>{
 const name=new URL(req.url,'http://localhost').pathname,file=path.resolve(web,'.'+(name==='/'?'/index.html':name));
 if(!file.startsWith(path.resolve(web)+path.sep)||!fs.existsSync(file)){res.writeHead(404).end();return;}
 res.writeHead(200,{'Content-Type':mime[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});
 if(name==='/'||name==='/index.html')res.end(fs.readFileSync(file,'utf8').replace(/const GODOT_CONFIG = (\{[^\r\n]+\});/,(_,raw)=>{const c=JSON.parse(raw);c.args=['--','--qa-skills-browser','--expected-version='+version];return 'const GODOT_CONFIG = '+JSON.stringify(c)+';';}));
 else fs.createReadStream(file).pipe(res);
});
await new Promise(r=>server.listen(0,'127.0.0.1',r));
const browser=await chromium.launch({headless:true,args:['--use-gl=angle','--use-angle=metal','--enable-gpu']});
const context=await browser.newContext({viewport:{width:844,height:390},deviceScaleFactor:2,hasTouch:true});
const page=await context.newPage(),cdp=await context.newCDPSession(page);page.setDefaultTimeout(60000);
const checks=[],messages=[],images=[],failures=[];let runtime=null,id=0;
const report={version,files,source:process.env.GITHUB_SHA,base_source:'be3a698e0ad8bedb91e877b9932a7bb05b80684a',physical_iphone:false,checks,images,failures};
const save=()=>fs.writeFileSync(path.join(output,'report.json'),JSON.stringify({...report,runtime},null,2));
page.on('console',m=>{messages.push(m.type()+': '+m.text());fs.writeFileSync(path.join(output,'console.log'),messages.join('\n'));});
page.on('pageerror',e=>messages.push('PAGEERROR: '+e.message));
const state=()=>page.evaluate(()=>window.DEV14_STATE),delay=ms=>new Promise(r=>setTimeout(r,ms));
async function wait(label,predicate,timeout=20000){
 const start=Date.now();let s;
 while(Date.now()-start<timeout){s=await state();if(s?.error||s?.native?.failed)throw Error(label+': '+JSON.stringify(s));if(predicate(s))return s;if(messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)))throw Error(label+': runtime error');await delay(100);}
 throw Error(label+' timeout: '+JSON.stringify(s));
}
function check(name,ok,details={}){checks.push({name,passed:!!ok,...details});save();if(!ok)throw Error(name);}
async function command(kind,extra={}){const wanted=++id;await page.evaluate(d=>window.DEV14_COMMAND=JSON.stringify(d),{kind,id:wanted,...extra});return wait(kind,s=>s?.id===wanted);}
async function point(name){const s=await state(),v=page.viewportSize(),r=s.buttons[name]||s[name];if(!Array.isArray(r))throw Error('Missing button '+name);return {x:(r[0]+r[2]/2)/s.viewport[0]*v.width,y:(r[1]+r[3]/2)/s.viewport[1]*v.height};}
async function tap(name){const p=await point(name);await page.touchscreen.tap(p.x,p.y);await delay(220);}
async function touch(type,p){await cdp.send('Input.dispatchTouchEvent',{type,touchPoints:type==='touchEnd'?[]:[{id:7,...p,radiusX:5,radiusY:5,force:1}]});}
async function shot(name){
 const name2=name+'.jpg';await page.screenshot({path:path.join(output,name2),quality:94,timeout:30000});
 const s=await state();fs.writeFileSync(path.join(output,name+'.json'),JSON.stringify(s,null,2));
 images.push({file:name2,state:name+'.json',viewport:page.viewportSize(),dpr:2});save();console.log('FULL_QUALITY_CAPTURE',name);
}
async function ready(){return wait('active game',s=>!s?.menu&&!s?.inventory_open&&!s?.shop_open&&s?.game_started&&s.player_controls_enabled&&s.actual_map?.world_active);}
async function walk(direction,predicate,label,vertical=0){
 const s=await state(),jr=s.buttons.joystick,v=page.viewportSize();
 const start={x:(jr[0]+jr[2]*.20)/s.viewport[0]*v.width,y:(jr[1]+jr[3]*.70)/s.viewport[1]*v.height};
 await touch('touchStart',start);await touch('touchMove',{x:start.x+32*direction,y:start.y+32*vertical});
 try{await wait(label,predicate,10000);}finally{await touch('touchEnd',start);}
}
async function group(name,fn){
 try{await fn();checks.push({name,passed:true});}
 catch(e){failures.push({group:name,error:String(e.stack||e)});console.error('GROUP_FAILED',name,e.message);try{await shot('failure-'+name);}catch{}}
 save();
}
async function closeModal(){
 // Parent navigation can expose another modal; inspect each resulting state.
 for(let remaining=6;remaining>0;remaining--){
  const s=await state();
  if(s?.treasury_goal?.open)await tap('treasury_close');
  else if(s?.shop_open)await tap('shop_close');
  else if(s?.mole_open)await tap('mole_close');
  else if(s?.inventory_open)await tap('inventory_close');
  else if(s?.settings_open)await tap('settings_back');
  else if(s?.skills_open)await tap('skills_close');
  else if(s?.menu)await tap('continue');
  else return;
 }
 throw Error('Modal did not return to gameplay');
}
async function map(label){
 await tap('hud_map');await wait('expanded map',s=>s.skills_open&&s.map_open);await shot(label+'-expanded-map');
 const s=await state();check(label+'-map-world-data',s.phase==='surface'?s.actual_map.known.length===4:s.phase==='hub'||s.cartography.terrain,{phase:s.phase,cartography:s.cartography});
 await tap('skills_close');await ready();
}
function cssRect(rect,s){const v=page.viewportSize();return [rect[0]*v.width/s.viewport[0],rect[1]*v.height/s.viewport[1],rect[2]*v.width/s.viewport[0],rect[3]*v.height/s.viewport[1]];}
function contains(a,b){return b[0]>=a[0]-.75&&b[1]>=a[1]-.75&&b[0]+b[2]<=a[0]+a[2]+.75&&b[1]+b[3]<=a[1]+a[3]+.75;}
function overlap(a,b){return a[0]<b[0]+b[2]-.75&&a[0]+a[2]>b[0]+.75&&a[1]<b[1]+b[3]-.75&&a[1]+a[3]>b[1]+.75;}
function previewGeometry(label,s){
 const g=s.quality.geometry.preview,v=page.viewportSize(),screen=[0,0,v.width,v.height];
 const panel=cssRect(g.panel,s),controls=[];
 check(label+'-panel-onscreen',contains(screen,panel),{panel,screen});
 for(const name of ['claim','pin','close']){
  if(!g[name].visible)continue;const rect=cssRect(g[name].rect,s);controls.push({name,rect});
  check(label+'-'+name+'-44-css-pixels',rect[2]>=43.95&&rect[3]>=43.95,{rect});
  check(label+'-'+name+'-inside',contains(panel,rect),{rect,panel});
 }
 for(let a=0;a<controls.length;a++)for(let b=a+1;b<controls.length;b++)check(label+'-'+controls[a].name+'-'+controls[b].name+'-separate',!overlap(controls[a].rect,controls[b].rect),{controls});
 for(const name of ['detail','source','title']){
  const text=g[name],rect=cssRect(text.rect,s),font=text.font_viewport*v.height/s.viewport[1];
  check(label+'-'+name+'-inside',contains(panel,rect),{rect,panel});
  check(label+'-'+name+'-readable',font>=13.8,{font,text:text.text});
  check(label+'-'+name+'-unclipped',text.visible_lines>=text.lines,{text});
 }
}
const mods={wallet_gold:'resonance',burrowsteel:'bore_rush',prismite:'laser',rootiron:'twin_auger',echo_crystal:'chainbreaker',phasecrystal:'ricochet',deep_alloy:'corebreaker',singularity:'vortex'};
try{
 await page.goto('http://127.0.0.1:'+server.address().port,{waitUntil:'domcontentloaded',timeout:180000});
 await wait('focused fixture ready',s=>s?.version===version&&s?.quality?.geometry,180000);
 await tap('new_game');await ready();
 runtime=await page.evaluate(()=>{const g=document.querySelector('canvas').getContext('webgl2'),e=g.getExtension('WEBGL_debug_renderer_info');return {renderer:e?g.getParameter(e.UNMASKED_RENDERER_WEBGL):null,lost:g.isContextLost(),dpr:devicePixelRatio,userAgent:navigator.userAgent};});
 check('real-gpu-renderer',runtime.renderer&&!runtime.lost&&!/SwiftShader|llvmpipe|software/i.test(runtime.renderer),{runtime});
 for(const viewport of [{width:844,height:390},{width:667,height:375},{width:932,height:430}]){
  const width=viewport.width;await page.setViewportSize(viewport);await delay(250);
  await group('navigation-'+width,async()=>{
   await closeModal();await command('surface');await ready();
   await tap('hud_menu');await wait('Skills parent',s=>s.skills_open);
   await tap('inventory');await wait('Skills inventory',s=>s.inventory_open&&!s.menu);
   check('inventory-world-paused-'+width,!(await state()).player_controls_enabled,{});
   await tap('inventory_close');await wait('inventory returns Skills',s=>s.skills_open&&s.menu&&!s.inventory_open);await shot('inventory-return-skills-'+width);
   await tap('settings');await wait('Skills settings',s=>s.settings_open);
   if((await state()).buttons.settings_controls){
    await tap('settings_controls');await wait('controls',s=>s.quality.menu_detail_title==='CONTROLS');await shot('controls-'+width);
    const s=await state(),g=s.quality.geometry.menu,back=cssRect(g.back,s),panel=cssRect(g.panel,s);
    check('controls-back-44-css-'+width,back[2]>=43.95&&back[3]>=43.95,{back});
    for(const [index,label] of g.labels.entries()){
     const rect=cssRect(label.rect,s),font=label.font_viewport*viewport.height/s.viewport[1];
     check('controls-copy-readable-'+index+'-'+width,font>=12&&contains(panel,rect)&&label.visible_lines>=label.lines,{rect,font,text:label.text});
    }
    await tap('settings_back');await wait('controls returns settings',s=>s.quality.menu_detail_title==='SETTINGS');
   }
   await tap('settings_back');await wait('settings returns Skills',s=>s.skills_open&&!s.settings_open);await shot('settings-return-skills-'+width);
   await tap('skills_close');await ready();
  });
  await group('achievement-focus-'+width,async()=>{
   await closeModal();await command('surface');await ready();
   for(const [index,label] of [[0,'early'],[22,'middle'],[28,'threefold-star'],[-1,'last']]){
    await command('quality_achievement',{index});
    await wait('achievement toast',s=>s.quality.geometry.achievement.toast.visible);
    if(width===844)await shot('achievement-'+label+'-toast-'+width);
    await tap('achievement_toast');
    await wait('highlighted achievement',s=>{const a=s.quality.geometry.achievement;return a.detail_visible&&a.highlighted===a.result.requested&&a.row.length===4;});
    await delay(350);
    const s=await state(),a=s.quality.geometry.achievement,row=cssRect(a.row,s),scroll=cssRect(a.scroll,s);
    check('achievement-'+label+'-row-visible-'+width,contains(scroll,row),{row,scroll,id:a.highlighted,scroll_value:a.scroll_value});
    check('achievement-'+label+'-world-paused-'+width,!s.player_controls_enabled,{phase:s.phase});
    await shot('achievement-'+label+'-focused-'+width);
    await tap('settings_back');await wait('ledger Back returns pause',s=>s.quality.geometry.achievement.main_visible&&!s.quality.geometry.achievement.detail_visible);
    await tap('continue');await ready();
   }
   await command('quality_achievement',{index:28,cancel:true});await delay(450);
   const a=(await state()).quality.geometry.achievement;
   check('achievement-Back-before-deferred-'+width,a.result.cancelled_before_deferred&&a.main_visible&&!a.detail_visible&&a.highlighted===''&&a.row.length===0,{achievement:a,fixture:'Back signal before deferred focus'});
   await tap('continue');await ready();
  });
  await group('feedback-placement-'+width,async()=>{
   await closeModal();await command('quality_boundary');await ready();await delay(250);
   const edge=await state();check('north-boundary-native-hero-visible-'+width,edge.quality.feedback.hero.length>0&&edge.quality.feedback.hero.every(r=>contains([0,0,viewport.width,viewport.height],cssRect(r,edge))),{hero:edge.quality.feedback.hero});await shot('north-boundary-hero-'+width);
   await command('maps_fixture',{mine:'endless',depth:1});await ready();
   await command('quality_feedback');await delay(450);
   let s=await state(),f=s.quality.feedback;await shot('feedback-simultaneous-'+width);
   check('feedback-native-hero-bounds-'+width,f.hero.length>0,{hero:f.hero});
   check('feedback-three-visible-pickups-'+width,f.pickups.length===3,{pickup:f.pickup});
   const notices=f.pickups.map(r=>cssRect(r,s));
   if(f.skill.visible)notices.push(cssRect(f.skill_rect,s));
   if(f.toast.visible)notices.push(cssRect(f.toast_rect,s));
   for(const [index,rect] of notices.entries()){
    check('feedback-'+index+'-onscreen-'+width,contains(cssRect(f.safe_rect,s),rect),{rect,safe:f.safe_rect});
    for(const hero of f.hero)check('feedback-'+index+'-clear-hero-'+width,!overlap(rect,cssRect(hero,s)),{rect,hero});
   }
   for(let i=0;i<notices.length;i++)for(let j=i+1;j<notices.length;j++)check('feedback-'+i+'-'+j+'-separate-'+width,!overlap(notices[i],notices[j]),{notices});
   check('feedback-toast-clear-or-queued-'+width,f.toast.visible?f.toast.placement_clear:f.toast.active&&f.toast.suspended,{toast:f.toast});
   await tap('hud_map');await wait('feedback map modal',s=>s.skills_open&&s.map_open);s=await state();f=s.quality.feedback;
   check('feedback-notices-suspended-on-map-'+width,!f.toast.visible&&!f.skill.visible&&f.toast.active,{toast:f.toast,skill:f.skill});await shot('feedback-suspended-map-'+width);
   await tap('skills_close');await ready();await command('quality_feedback',{clear:true});
  });
  await group('journal-controls-'+width,async()=>{
   await closeModal();await command('surface');await ready();await tap('hud_mole');await wait('journal',s=>s.mole_open);
   for(const [index,tab] of [[1,'skills'],[2,'how'],[0,'together']]){
    await tap('mole_tab_'+index);await wait('journal '+tab,s=>s.quality.geometry.journal.tab===tab);await shot('journal-'+tab+'-'+width);
   }
   let s=await state(),g=s.quality.geometry.journal;
   const paper=cssRect(g.paper,s),body=cssRect(g.body,s),mood=cssRect(g.mood.rect,s),notice=cssRect(g.notice.rect,s);
   check('journal-copy-fits-paper-'+width,contains(paper,mood)&&contains(paper,notice)&&g.mood.visible_lines>=g.mood.lines&&g.notice.visible_lines>=g.notice.lines,{paper,mood,notice});
   check('journal-copy-separate-'+width,!overlap(mood,body)&&!overlap(notice,body),{mood,notice,body});
   for(const [name,button] of Object.entries(g.commands)){
    const rect=cssRect(button.rect,s);check('journal-'+name+'-44-css-'+width,rect[2]>=43.95&&rect[3]>=43.95,{rect});
   }
   check('journal-status-present-'+width,!!g.status,{status:g.status});
   const fetch=g.commands.Command_fetch,rect=cssRect(fetch.rect,s);check('journal-come-here-ready-'+width,!fetch.disabled,{fetch});
   await page.touchscreen.tap(rect[0]+rect[2]/2,rect[1]+rect[3]/2);await wait('command closes journal',s=>!s.mole_open);await ready();
   check('journal-command-releases-input-'+width,!(await state()).mine_input_held,{});
  });
  await group('goal-lines-'+width,async()=>{
   await closeModal();
   for(const scenario of ['early','recipe','pinned']){
    await command('quality_goal',{scenario});await ready();await delay(300);
    const s=await state(),g=s.quality.geometry.goal,rect=cssRect(g.rect,s),action=cssRect(g.action.rect,s);
    await shot('goal-'+scenario+'-'+width);
    check('goal-'+scenario+'-'+width+'-visible-action',g.action.visible&&g.action.text.length>0&&g.snapshot.action_visible,{goal:g});
    check('goal-'+scenario+'-'+width+'-fits',contains([0,0,viewport.width,viewport.height],rect)&&contains(rect,action)&&g.action.visible_lines>=g.action.lines,{rect,action});
    check('goal-'+scenario+'-'+width+'-passthrough',!g.snapshot.input_blocking,{goal:g.snapshot});
    for(const [name,item] of Object.entries(s.quality.geometry.controls))if(item.visible)check('goal-'+scenario+'-'+width+'-separate-'+name,!overlap(rect,cssRect(item.rect,s)),{rect,control:cssRect(item.rect,s)});
    await page.touchscreen.tap(rect[0]+rect[2]/2,rect[1]+rect[3]/2);await delay(180);
    check('goal-'+scenario+'-'+width+'-tap-keeps-playing',!(await state()).menu&&(await state()).player_controls_enabled,{});
    if(scenario==='recipe')check('actual-multi-resource-recipe-'+width,g.snapshot.requirements.length>=2,{requirements:g.snapshot.requirements});
    if(scenario==='pinned')check('actual-pinned-source-'+width,g.snapshot.resource_id==='prismite'&&['Moonglass · Depth 2','The Deep · rich veins in new ground'].includes(g.action.text),{action:g.action.text});
   }
  });
  await group('mod-actions-'+width,async()=>{
   await closeModal();
   for(const [resource,mod] of Object.entries(mods)){
    for(const amount of [0,56000,100000]){
     await command('quality_preview_state',{resource,amount});await wait('preview',s=>s.treasury_goal.open);await delay(150);
     let s=await state();const label=resource+'-'+amount+'-'+width;
     previewGeometry(label,s);
     check(label+'-claim-authority',s.treasury_goal.claim_disabled===(amount<100000),{goal:s.treasury_goal});
     if(amount===100000||resource==='wallet_gold')await shot(label);
     if(amount===100000){
      await tap('treasury_pin');await wait('pin stored',s=>s.treasury_goal.saved.pinned===resource);
      await tap('treasury_claim');await wait('earned mod',s=>s.treasury_goal.saved[mod+'_claimed']&&s.treasury_goal.saved[mod+'_enabled']);
      s=await state();check(label+'-completed-pin-cleared',s.treasury_goal.saved.pinned!==resource&&s.quality.geometry.preview.pin.disabled,{goals:s.treasury_goal.saved});
      await shot(resource+'-claimed-on-'+width);
      await tap('treasury_claim');await wait('mod toggle off',s=>!s.treasury_goal.saved[mod+'_enabled']);
      await command('mods_save');await command('mods_reload');
      check(label+'-saved-off-state',(await state()).treasury_goal.saved[mod+'_claimed']&&!(await state()).treasury_goal.saved[mod+'_enabled'],{});
      await tap('treasury_claim');await wait('mod toggle on',s=>s.treasury_goal.saved[mod+'_enabled']);
     }
     await tap('treasury_close');await ready();
    }
   }
   await command('quality_preview_state',{resource:'copper',amount:100000});await wait('generic goal',s=>s.treasury_goal.open);await delay(150);
   const s=await state();previewGeometry('copper-'+width,s);check('generic-copper-no-claim-'+width,!s.quality.geometry.preview.claim.visible,{});check('generic-complete-cannot-repin-'+width,s.quality.geometry.preview.pin.disabled&&s.treasury_goal.saved.pinned!=='copper',{goals:s.treasury_goal.saved});await shot('copper-complete-'+width);
   await tap('treasury_close');await ready();
  });
  await group('full-map-'+width,async()=>{
   await closeModal();
   for(const [mine,depth] of [['surface',0],['mossMine',1],['mossMine',2],['endless',1],['hub',0]]){
    if(mine==='surface')await command('treasury_map_first');else if(mine==='hub')await command('hub');else await command('maps_fixture',{mine,depth});
    await ready();await tap('hud_map');await wait('map opens',s=>s.map_open&&s.skills_open);await delay(200);
    let s=await state(),g=s.quality.geometry.skills,r=cssRect(g.plate,s);
    check(mine+'-'+depth+'-'+width+'-full-width',r[2]>=viewport.width*.78,{plate:r});
    check(mine+'-'+depth+'-'+width+'-portrait-hidden',!g.portrait_visible,{geometry:g});
    check(mine+'-'+depth+'-'+width+'-map-onscreen',contains([0,0,viewport.width,viewport.height],cssRect(g.map_rect,s)),{geometry:g});
    await shot('focused-map-'+mine+'-'+depth+'-'+width);
    await tap('skills');await wait('skills restored',s=>!s.map_open&&s.skills_open);s=await state();
    check(mine+'-'+depth+'-'+width+'-skills-art-restored',s.quality.geometry.skills.portrait_visible,{});
    await tap('map');await wait('map reopens',s=>s.map_open&&s.skills_open);await tap('skills_close');await ready();
   }
   await command('treasury_map_first');await ready();await tap('hud_map');await wait('locked surface map',s=>s.map_open);
   let s=await state(),snapshot=s.quality.geometry.skills.map_snapshot;
   check('surface-locked-routes-'+width,snapshot.phase==='surface'&&snapshot.navigation_routes===2&&snapshot.navigation_areas===3,{snapshot});
   await shot('surface-authored-locked-'+width);await tap('skills_close');await ready();
   await command('treasury_map_all');await command('surface');await ready();await tap('hud_map');await wait('unlocked surface map',s=>s.map_open);
   s=await state();snapshot=s.quality.geometry.skills.map_snapshot;
   check('surface-unlocked-routes-'+width,snapshot.phase==='surface'&&snapshot.navigation_routes===11,{snapshot});
   await shot('surface-authored-unlocked-'+width);await tap('skills_close');await ready();
   await command('treasury_fixture');await ready();await walk(1,s=>s.treasury.inside,'treasury enter');
   for(const distant of [false,true]){
    if(distant)await command('treasury_visual',{index:26,amount:100000});
    await tap('hud_menu');await wait('treasury Skills',s=>s.skills_open);await tap('map');await wait('treasury fresh map',s=>s.map_open);
    s=await state();snapshot=s.quality.geometry.skills.map_snapshot;
    check('treasury-map-live-'+distant+'-'+width,snapshot.phase==='treasury'&&snapshot.marker_count===29&&snapshot.navigation_areas===1&&snapshot.navigation_routes===0&&!snapshot.terrain&&snapshot.player_inside,{snapshot});
    await shot('treasury-fresh-map-'+(distant?'distant':'entry')+'-'+width);
    await tap('skills');await wait('treasury Skills restored',s=>s.skills_open&&!s.map_open);await tap('skills_close');await ready();
   }
  });
 }
 check('runtime-errors-absent',!messages.some(m=>/SCRIPT ERROR|Parse Error|PAGEERROR|^error: ERROR:/.test(m)),{});
}catch(e){failures.push({group:'startup-or-global',error:String(e.stack||e)});console.error(e);try{await shot('fatal-failure');}catch{}}
finally{report.passed=failures.length===0;report.browser=browser.version();save();await context.close();await browser.close();await new Promise(r=>server.close(r));}
if(failures.length)process.exitCode=1;
