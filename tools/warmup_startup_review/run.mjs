import { webkit } from '@playwright/test';
import { promises as fs, createReadStream } from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { hash, decodeSave } from './codec.mjs';

const exec = promisify(execFile), here = path.dirname(fileURLToPath(import.meta.url));
const [baseline, candidate, fixturePath, output, ocr] = process.argv.slice(2).map(x => path.resolve(x));
const pins = JSON.parse(await fs.readFile(path.join(here, 'pins.json'), 'utf8'));
const pause = ms => new Promise(resolve => setTimeout(resolve, ms));
const stamp = () => ({utc:new Date().toISOString(),monotonic_ms:performance.now()});
const write = async (root, name, value) => {
  const p=path.join(root,name);await fs.writeFile(p+'.tmp',JSON.stringify(value,null,2)+'\n');await fs.rename(p+'.tmp',p);
};
const bounded = async (p, ms, label) => {
  let timer;try{return await Promise.race([p,new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error(label+' timed out')),ms);})]);}finally{clearTimeout(timer);}
};
const normalized = s => s.toUpperCase().replace(/[^A-Z0-9]/g,'');
const same = (a,b) => JSON.stringify(a)===JSON.stringify(b);
const progress = s => Object.fromEntries(['gold','cargo','mined','total_swings','precision_hits','total_gold_earned','pickaxe_level','drill_level','movement_speed_level','ember_mastery','area_unlocked','emberdeep_unlocked','fourth_unlocked','victory','starforge_unlocked'].map(k=>[k,s[k]]));
function label(rows, text) {
  const found=rows.filter(r=>normalized(r.text)===text&&r.confidence>=.6);
  if(found.length>1)throw Error('Ambiguous label '+text);
  return found[0]??null;
}
async function verifyPackage(kind, directory) {
  const p=pins[kind], bytes=await fs.readFile(path.join(directory,'artifact-identity.json'));
  if(hash(bytes)!==p.identity_sha256)throw Error('Wrong '+kind+' identity');
  const id=JSON.parse(bytes);
  if(id.sourceSha!==p.source||id.runId!==p.run_id||id.runAttempt!=='1'||!same(id.devFiles,p.files)||Object.keys(p.files).length!==9)throw Error('Wrong source/run/files');
  for(const [name,v]of Object.entries(p.files)){
    const b=await fs.readFile(path.join(directory,name));
    if(b.length!==v.size||hash(b)!==v.sha256)throw Error('Changed export '+kind+'/'+name);
  }
  const html=await fs.readFile(path.join(directory,'index.html'),'utf8');
  if(!html.includes('"args":[]')||!html.includes('"focusCanvas":true'))throw Error('Export is not intact ordinary bootstrap');
  return {source:p.source,identity_sha256:hash(bytes),files:p.files};
}
// Read all userfs rows without creating an absent database or changing any row.
async function storage(page, root, name) {
  const raw=await page.evaluate(async()=>{
    const db=await new Promise((resolve,reject)=>{
      const r=indexedDB.open('/userfs');let absent=false;
      r.onupgradeneeded=()=>{absent=true;r.transaction.abort();};
      r.onerror=()=>absent?resolve(null):reject(r.error);
      r.onsuccess=()=>resolve(r.result);
    });
    if(!db)return {database_absent:true,rows:[]};
    try{
      if(!db.objectStoreNames.contains('FILE_DATA'))throw Error('Missing FILE_DATA');
      const tx=db.transaction('FILE_DATA','readonly'),s=tx.objectStore('FILE_DATA');
      const get=r=>new Promise((resolve,reject)=>{r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
      const [keys,values]=await Promise.all([get(s.getAllKeys()),get(s.getAll())]);
      return {database_absent:false,version:db.version,rows:keys.map((key,i)=>({key:String(key),mode:values[i].mode,timestamp:values[i].timestamp?.toISOString(),bytes:values[i].contents?Array.from(new Uint8Array(values[i].contents)):null}))};
    }finally{db.close();}
  });
  const receipt={...raw,observed:stamp()};
  for(const r of receipt.rows)if(r.bytes){r.size=r.bytes.length;r.sha256=hash(Buffer.from(r.bytes));}
  await write(root,name+'.json',receipt);
  const saves=receipt.rows.filter(r=>r.key===pins.fixture.key);
  if(saves.length>1)throw Error('Duplicate primary save');
  if(saves.length){receipt.primary=decodeSave(Buffer.from(saves[0].bytes));await fs.writeFile(path.join(root,name+'.sav'),Buffer.from(saves[0].bytes));}
  return receipt;
}
async function seed(page, bytes) {
  await page.evaluate(async({bytes,key,timestamp})=>{
    const db=await new Promise((resolve,reject)=>{
      const r=indexedDB.open('/userfs',21);
      r.onupgradeneeded=()=>{const s=r.result.createObjectStore('FILE_DATA');s.createIndex('timestamp','timestamp',{unique:false});};
      r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);
    });
    try{await new Promise((resolve,reject)=>{
      const tx=db.transaction('FILE_DATA','readwrite'),s=tx.objectStore('FILE_DATA');
      tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);tx.onabort=()=>reject(tx.error);
      const date=new Date(timestamp),parent=key.slice(0,key.lastIndexOf('/'));
      s.put({timestamp:date,mode:0o40755},parent);
      s.put({timestamp:date,mode:0o100644,contents:new Uint8Array(bytes)},key);
    });}finally{db.close();}
  },{bytes:Array.from(bytes),key:pins.fixture.key,timestamp:pins.fixture.timestamp});
}
function startingState(s) {
  if(!s||s.location.scene!=='surface'||s.location.x!==240||s.location.y!==680||s.location.depth!==1||s.gold!==0||s.pickaxe_level!==1||s.total_swings!==0||Object.values(s.cargo).some(n=>n!==0))throw Error('Expected ordinary Surface defaults/location missing');
}
const sessions=[],requests=[];let server,active=null;
await fs.mkdir(output,{recursive:true});
try{
  if(process.platform!=='darwin'||process.getuid()===0||process.env.GITHUB_REF!=='refs/heads/codex/nonindexed-warmup-package-probe-20260917'||process.env.GITHUB_RUN_ATTEMPT!=='1')throw Error('Wrong host/branch/attempt');
  const request=JSON.parse(await fs.readFile(path.join(here,'REQUEST.json'),'utf8'));
  if(request.sessions!==4||request.probe!=='intact_startup_four_launches_v1'||request.source!==pins.candidate.source||request.baseline_source!==pins.baseline.source||request.diagnostic_only!==true)throw Error('Wrong bounded request');
  const {stdout:parent}=await exec('git',['rev-parse','HEAD^']);
  const {stdout:diff}=await exec('git',['diff-tree','--no-commit-id','--name-status','-r','HEAD']);
  if(parent.trim()!==request.preparation_sha||diff.trim()!=='A\ttools/warmup_startup_review/REQUEST.json')throw Error('Request must be the preparation-only child');
  for(const [name,sha]of Object.entries(pins.helpers))if(hash(await fs.readFile(path.join(here,name)))!==sha)throw Error('Original helper changed: '+name);
  const fixture=await fs.readFile(fixturePath);
  if(fixture.length!==pins.fixture.size||hash(fixture)!==pins.fixture.sha256)throw Error('Wrong unchanged normal-save fixture');
  const fixtureDocument=decodeSave(fixture);startingState(fixtureDocument.state);
  await write(output,'fixture.json',{...pins.fixture,document:fixtureDocument});
  await write(output,'packages-before.json',{baseline:await verifyPackage('baseline',baseline),candidate:await verifyPackage('candidate',candidate)});
  const {stdout:head}=await exec('git',['rev-parse','HEAD']);
  await write(output,'host.json',{study_sha:head.trim(),request,platform:process.platform,release:os.release(),arch:process.arch,uid:process.getuid(),node:process.version,executable:webkit.executablePath(),executable_sha256:hash(await fs.readFile(webkit.executablePath()))});
  const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png','.pck':'application/octet-stream'};
  server=http.createServer((req,res)=>{
    const name=new URL(req.url,'http://localhost').pathname.slice(1)||'index.html';
    requests.push({session:active?.id,name,...stamp()});
    const headers={'Cache-Control':'no-store','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'};
    if(name==='_storage'){res.writeHead(200,{...headers,'Content-Type':'text/html'});res.end('<!doctype html><title>Disposable fixture preparation</title>');return;}
    const v=active&&pins[active.kind].files[name];
    if(!v){res.writeHead(404,headers);res.end();return;}
    res.writeHead(200,{...headers,'Content-Type':mime[path.extname(name)]||'application/octet-stream','Content-Length':v.size});
    createReadStream(path.join(active.directory,name)).pipe(res);
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  const origin='http://127.0.0.1:'+server.address().port;
  for(const saved of [false,true])for(const kind of ['baseline','candidate']){
    const id=kind+'-'+(saved?'saved':'fresh'),root=path.join(output,id);await fs.mkdir(root,{recursive:true});
    active={id,kind,directory:kind==='baseline'?baseline:candidate};
    const result={id,kind,saved,started:stamp(),mechanical_complete:false,visual_parity_accepted:false,early_engine_boundary:'inconclusive; DOM status is not Main/helper or listener timing',mining_release_proven:false};
    const logs=[],errors=[],actions=[],frames=[];let bs,browser,context,page,recording=false,recorder,childExit=null,exitPromise;
    const snapshot=async name=>{const before=stamp();await page.screenshot({path:path.join(root,name+'.png'),animations:'allow',timeout:15000});frames.push({name,before,after:stamp()});};
    const scan=async name=>{await snapshot(name);const {stdout}=await exec(ocr,[path.join(root,name+'.png')],{timeout:20000,maxBuffer:1024*1024});const rows=JSON.parse(stdout);await write(root,name+'-ocr.json',rows);return rows;};
    const key=async(type,name,stage)=>{const before=await page.evaluate(()=>window.__startupReview.events.length);const a={type,key:name,stage,before:stamp()};actions.push(a);await page.keyboard[type](name);a.events=await page.evaluate(n=>window.__startupReview.events.slice(n),before);a.after=stamp();if(!a.events.some(e=>e.type==='key'+(type==='down'?'down':'up')&&e.key===(name==='Space'?' ':name)&&e.trusted&&e.target==='canvas'&&e.active==='canvas'&&e.focused))throw Error('Missing trusted focused canvas '+name+' '+type);await write(root,'actions.json',actions);};
    try{
      bs=await webkit.launchServer({headless:true});
      exitPromise=new Promise(resolve=>bs.process().once('close',(code,signal)=>{childExit={code,signal,...stamp()};resolve(childExit);}));
      browser=await webkit.connect(bs.wsEndpoint());result.browser_version=browser.version();result.browser_pid=bs.process().pid;
      context=await browser.newContext({viewport:{width:848,height:390},deviceScaleFactor:2,isMobile:true,hasTouch:true,
        userAgent:'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/124.0.0.0 Mobile/15E148 Safari/604.1',
        recordVideo:{dir:path.join(root,'video'),size:{width:1696,height:780}}});
      await context.addInitScript({path:path.join(here,'passive.js')});
      page=await context.newPage();page.setDefaultTimeout(15000);
      page.on('console',m=>{const row={type:m.type(),text:m.text(),...stamp()};logs.push(row);if(m.type()==='error'||/SCRIPT ERROR|Parse Error|^ERROR:|Assertion failed|WebGL.*(?:INVALID_|GL_ERROR)/.test(m.text()))errors.push(row);});
      page.on('pageerror',e=>errors.push({page_error:String(e),...stamp()}));page.on('crash',()=>errors.push({crash:true,...stamp()}));
      page.on('requestfailed',r=>errors.push({request_failed:r.url(),failure:r.failure(),...stamp()}));
      page.on('response',r=>{if(r.status()>=400)errors.push({http_status:r.status(),url:r.url(),...stamp()});});
      await page.goto(origin+'/_storage');
      const empty=await storage(page,root,'storage-empty');if(!empty.database_absent)throw Error('Disposable context not empty');
      if(saved)await seed(page,fixture);
      const seeded=await storage(page,root,'storage-prelaunch');
      if(saved&&(seeded.rows.length!==2||seeded.rows.find(r=>r.key===pins.fixture.key)?.sha256!==pins.fixture.sha256))throw Error('Fixture not exact');
      if(!saved&&!seeded.database_absent)throw Error('Fresh context gained a DB');
      await page.goto(origin+'/index.html',{waitUntil:'domcontentloaded',timeout:60000});
      recording=true;recorder=(async()=>{for(let i=0;recording&&i<120;i++){await snapshot('startup-'+String(i).padStart(3,'0'));await pause(150);}if(recording)result.startup_png_limit_reached=true;})().catch(e=>{errors.push({capture_error:String(e)});});
      await page.waitForFunction(()=>typeof window.__startupReview?.status_removed_ms==='number',null,{timeout:60000});
      // Original focusCanvas is used. No focus/blur clearing to rescue missed input.
      await key('down','ArrowRight','early_visible_launch');
      if(!saved){await pause(40);await key('up','ArrowRight','early_visible_release');}
      await pause(700);
      let menu;
      for(let i=0;i<6;i++){
        const rows=await scan('menu-attempt-'+i);
        if(label(rows,'NEWGAME')&&label(rows,'CONTINUE')&&(saved?label(rows,'SURFACEEXPEDITION'):label(rows,'NOEXPEDITIONFOUND'))){menu=rows;break;}
        await pause(500);
      }
      if(!menu)throw Error('Ordinary settled menu state missing');
      await pause(350);const confirmed=await scan('menu-settled');
      for(const text of ['NEWGAME','CONTINUE',saved?'SURFACEEXPEDITION':'NOEXPEDITIONFOUND']){
        const a=label(menu,text),b=label(confirmed,text);if(!a||!b||Math.abs(a.x-b.x)*848>2||Math.abs(a.y-b.y)*390>2)throw Error('Menu labels not stable: '+text);
      }
      if(saved)await key('up','ArrowRight','held_through_settled_menu_release');
      recording=false;await recorder;
      await page.evaluate(()=>{window.__startupReview.frames_stopped=true;});
      const lifecycle=await page.evaluate(()=>window.__startupReview);await write(root,'startup-lifecycle.json',lifecycle);
      result.splash_coverage=lifecycle.splash_seen?'DOM visible/loaded plus retained PNG/video; independent visual confirmation pending':'inconclusive';
      if(lifecycle.overflow)throw Error('Passive recorder overflow');
      const geometry=await page.evaluate(()=>({inner:[innerWidth,innerHeight],dpr:devicePixelRatio,canvas:[document.getElementById('canvas').width,document.getElementById('canvas').height],focus:document.hasFocus(),active:document.activeElement?.id}));
      if(!same(geometry.inner,[848,390])||!same(geometry.canvas,[1696,780])||geometry.dpr!==2||!geometry.focus||geometry.active!=='canvas')throw Error('Wrong actual surface/focus');
      await write(root,'surface.json',geometry);
      const menuStorage=await storage(page,root,'storage-menu');
      if(saved&&menuStorage.rows.find(r=>r.key===pins.fixture.key)?.sha256!==pins.fixture.sha256)throw Error('Saved primary changed before user action');
      if(!saved&&menuStorage.primary)throw Error('Fresh menu already has a saved run');
      const target=label(confirmed,saved?'CONTINUE':'NEWGAME'),point={x:Math.round(target.x*848),y:Math.round(target.y*390)};
      const touchBefore=await page.evaluate(()=>window.__startupReview.events.length);
      const a={stage:saved?'continue':'new_game',target,point,...stamp()};actions.push(a);
      if(await page.evaluate(({x,y})=>document.elementFromPoint(x,y)?.id,point)!=='canvas')throw Error('Menu target is not canvas');
      await page.touchscreen.tap(point.x,point.y);
      a.events=await page.evaluate(n=>window.__startupReview.events.slice(n),touchBefore);
      if(!['touchstart','touchend'].every(t=>a.events.some(e=>e.type===t&&e.trusted&&e.target==='canvas')))throw Error('Trusted menu tap not delivered');
      await write(root,'actions.json',actions);
      await pause(2000);await scan('hud-with-natural-tutorial');
      // The unchanged tutorial fades at 9 s over 0.55 s; do not dismiss it.
      await pause(10000);const hud=await scan('hud-settled');
      if(label(hud,'NEWGAME')||label(hud,'NOEXPEDITIONFOUND')||!label(hud,'DEVTOOLS'))throw Error('Ordinary HUD not established');
      const before=await storage(page,root,'storage-before-movement');startingState(before.primary?.state);
      if(!same(progress(before.primary.state),progress(fixtureDocument.state)))throw Error('First HUD progression differs from declared fixture defaults');
      if(saved&&(!same(progress(before.primary.state),progress(fixtureDocument.state))||before.primary.state.world_seed!==fixtureDocument.state.world_seed))throw Error('Valid save progression/seed changed before movement');
      await key('down','ArrowRight','normal_hold');
      await pause(500);await key('up','ArrowRight','normal_release');
      await snapshot('hud-released');
      let moved;
      for(let i=0;i<12;i++){
        await pause(2000);const s=await storage(page,root,'storage-movement-poll-'+String(i).padStart(2,'0'));
        const x=s.primary?.state?.location?.x;
        if(Number.isFinite(x)&&x!==240){moved=s;break;}
      }
      if(!moved)throw Error('No natural post-movement save within 24 s');
      const location=moved.primary.state.location,dx=location.x-240;
      if(location.scene!=='surface'||Math.abs(location.y-680)>1||dx<100||dx>230)throw Error('Movement outside predeclared clear-lane envelope; possible missed/stuck input or route mismatch');
      result.actual_movement_delta=dx;
      await snapshot('hud-natural-movement-save');
      for(let i=0;i<4;i++){await pause(4000);await snapshot('hud-no-input-'+i);}
      const after=await storage(page,root,'storage-after-release-window');
      if(!same(after.primary?.state.location,location)||!same(progress(after.primary.state),progress(moved.primary.state)))throw Error('Location/progression changed after release window');
      result.release_observation={location,uninterrupted_wait_ms:16000,same_persisted_location:true,same_total_swings:true,new_checkpoint_write_claim:false,visual_stationary_review_pending:true};
      // Focus loss itself cancels input and flushes a save in Main. It cannot
      // substitute for either our release or the natural checkpoint here.
      const final=await page.evaluate(()=>({receipt:window.__startupReview,time_ms:performance.now(),
        focused:document.hasFocus(),active:document.activeElement?.id??null,visibility:document.visibilityState}));
      await write(root,'release-lifecycle.json',final);
      const firstDown=actions.find(a=>a.type==='down').events.find(e=>e.phase==='capture'&&e.type==='keydown').time_ms;
      const normalDown=actions.find(a=>a.stage==='normal_hold').events.find(e=>e.phase==='capture'&&e.type==='keydown').time_ms;
      const receipt=final.receipt;
      if(!receipt||receipt.overflow||!final.focused||final.active!=='canvas'||final.visibility!=='visible')throw Error('Final passive active-state receipt missing or invalid');
      const lateEvents=receipt.events.filter(e=>e.time_ms>=firstDown);
      if(lateEvents.some(e=>['blur','pagehide'].includes(e.type)||e.visibility==='hidden'||e.focused===false||(e.active!==undefined&&e.active!=='canvas')))throw Error('Focus/visibility changed after early press; cancellation/save could mask release');
      const activeSamples=receipt.active_samples.filter(e=>e.time_ms>=firstDown);
      const normalSamples=activeSamples.filter(e=>e.time_ms>=normalDown);
      if(normalSamples.length<16||final.time_ms-normalSamples.at(-1).time_ms>1500||activeSamples.some(e=>!e.focused||e.active!=='canvas'||e.visibility!=='visible'))throw Error('Uninterrupted passive active-state coverage missing');
      result.release_observation.active_state_samples=normalSamples.length;
      result.release_observation.no_focus_visibility_cancellation=true;
      if(errors.length)throw Error('Raw browser errors: '+JSON.stringify(errors));
      result.mechanical_complete=true;
    }catch(e){result.error=String(e.stack??e);}
    finally{
      recording=false;if(recorder)await bounded(recorder,20000,'startup recorder closure').catch(e=>{result.closure_error=String(e);});
      if(page&&!page.isClosed()){
        try{await write(root,'lifecycle-final.json',await page.evaluate(()=>window.__startupReview??null));}catch(e){result.lifecycle_read_error=String(e);}
      }
      if(context)await bounded(context.close(),20000,'context/video closure').catch(e=>{result.closure_error=String(e);});
      if(browser)await bounded(browser.close(),10000,'browser connection closure').catch(e=>{result.closure_error=String(e);});
      if(bs){await bounded(bs.close(),10000,'browser server closure').catch(async e=>{result.closure_error=String(e);await bs.kill();});await bounded(exitPromise,10000,'browser child exit').catch(e=>{result.closure_error=String(e);});}
      result.child_exit=childExit;result.finished=stamp();
      if(result.closure_error||result.lifecycle_read_error||errors.length||!childExit||childExit.code!==0)result.mechanical_complete=false;
      await write(root,'console.json',logs);await write(root,'errors.json',errors);await write(root,'actions.json',actions);await write(root,'frames.json',frames);await write(root,'result.json',result);sessions.push(result);
      await write(output,'sessions.json',sessions);
    }
  }
  await write(output,'packages-after.json',{baseline:await verifyPackage('baseline',baseline),candidate:await verifyPackage('candidate',candidate)});
  if(sessions.length!==4||!sessions.every(s=>s.mechanical_complete))throw Error('One or more of the four bounded launches failed');
  await write(output,'result.json',{complete:true,sessions:4,mechanical_only:true,visual_parity_accepted:false,early_engine_boundary:'inconclusive',performance_claim:false,physical_iphone:false,...stamp()});
  console.log('INTACT_STARTUP_FOUR_LAUNCHES_COMPLETE '+JSON.stringify({sessions:4,mechanical_only:true}));
}catch(e){await write(output,'result.json',{complete:false,error:String(e.stack??e),sessions,finished:stamp()});process.exitCode=1;}
finally{await write(output,'requests.json',requests);if(server)await new Promise(resolve=>server.close(resolve));}
