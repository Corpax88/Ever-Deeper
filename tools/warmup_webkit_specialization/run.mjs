import { webkit } from '@playwright/test';
import { promises as fs, createReadStream } from 'node:fs';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import http from 'node:http';
import path from 'node:path';
import os from 'node:os';
import { hash, decodeSave, summarize } from './codec.mjs';
import { analyzeResources } from './resources.mjs';
import { analyzeIdentity } from './identity.mjs';
import { classifyPreNavigation, validateMenuBoundary } from './pre_navigation.mjs';
const exec=promisify(execFile), here=path.dirname(fileURLToPath(import.meta.url));
const SOURCE='5e48e4e1c256bd60aef1c4ba94110ccb1ac802b9';
const BRANCH='refs/heads/codex/warmup-webkit-specialization-20260917';
const IDENTITY='de678655bb6249ab33d8d25abdbe5de256f5c28ccb811b5d7cfa686ccb50d497';
const candidate=path.resolve(process.argv[2]||''), output=path.resolve(process.argv[3]||'');
const ocr=process.argv[4];
const write=async(name,value)=>{const p=path.join(output,name);await fs.writeFile(p+'.tmp',JSON.stringify(value,null,2)+'\n');await fs.rename(p+'.tmp',p);};
const stamp=()=>({utc:new Date().toISOString(),monotonic_ms:performance.now()});
const bounded=async(p,ms,label)=>{let timer;try{return await Promise.race([p,new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error(label+' timed out')),ms);})]);}finally{clearTimeout(timer);}};
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
const logs=[],errors=[],actions=[],requests=[],navigationUrls=[];
let server,browserServer,browser,page,context,exitPromise,childExit=null;
const result={schema:1,source:SOURCE,diagnostic_only:true,pck_sha256:null,metric:'engine_loop_callback_cadence',claim_scope:'pre-navigation API history through resources.stop only',helper_attribution:false,cache_hit_or_status_boolean_proven:false,rendered_fps_verified:false,physical_iphone:false,started:stamp(),complete:false};
async function inventory(label) {
  const command=['-axo','pid=,ppid=,uid=,etime=,comm='];
  const {stdout}=await exec('/bin/ps',command,{timeout:5000,maxBuffer:4*1024*1024});
  await fs.writeFile(path.join(output,label+'.txt'),stdout);
  return stdout.trim().split('\n').map(line=>{const m=/^\s*(\d+)\s+(\d+)\s+(\d+)\s+(\S+)\s+(.+)$/.exec(line);return m?{pid:+m[1],ppid:+m[2],uid:+m[3],elapsed:m[4],command:m[5]}:null;}).filter(Boolean);
}
async function scan(label) {
  const png=path.join(output,label+'.png');
  await page.screenshot({path:png,animations:'allow',timeout:15000});
  const {stdout}=await exec(ocr,[png],{timeout:20000,maxBuffer:1024*1024});
  const rows=JSON.parse(stdout);await write(label+'-ocr.json',rows);
  return rows;
}
const normal=s=>s.toUpperCase().replace(/[^A-Z0-9]/g,'');
function findText(rows,needle) {
  const match=rows.filter(x=>normal(x.text)===needle&&x.confidence>=.6);
  if(match.length>1)throw Error('Ambiguous UI label '+needle);
  return match[0]||null;
}
function findDevToggle(rows) {
  const exact=rows.filter(x=>normal(x.text)==='DEVTOOLS');
  if(exact.length>1)throw Error('Ambiguous exact DEV toggle');
  const row=exact[0];if(!row||row.confidence<.5)return null;
  const x=row.x*848,y=row.y*390;
  // _apply_layout follows PremiumHud below its menu row; retained CSS button69..148/75..110.
  if(x<88||x>130||y<82||y>104)return null;
  return row;
}
function findDeepTarget(rows) {
  // Exact existing label, independently seen in two retained originals at0.5.
  // Keep the generic0.6 guards; this target also requires a second settled image.
  const exact=rows.filter(x=>normal(x.text)==='ENDLESSLAYER12');
  if(exact.length>1)throw Error('Ambiguous exact Layer12 target');
  const row=exact[0];if(!row||row.confidence<.5)return null;
  const x=row.x*848,y=row.y*390;
  // Retained actual scroll area:CSS x83–485/y190–371, left button column83–281.
  // The inset keeps the whole approximately38px-tall button safely visible.
  if(x<100||x>264||y<210||y>350)return null;
  return row;
}
async function clickLabel(row,label) {
  const point={x:Math.round(row.x*848),y:Math.round(row.y*390)};
  const geometry=await page.evaluate(({x,y})=>{
    const c=document.getElementById('canvas'),r=c.getBoundingClientRect(),v=window.visualViewport;
    return {inner:[innerWidth,innerHeight],dpr:devicePixelRatio,canvas:{x:r.x,y:r.y,width:r.width,height:r.height},visual:v?{x:v.offsetLeft,y:v.offsetTop,width:v.width,height:v.height,scale:v.scale}:null,
      target:document.elementFromPoint(x,y)?.id,active:document.activeElement?.id,focus:document.hasFocus(),touch_index:window.__studyTouches.length};
  },point);
  if(geometry.target!=='canvas'||geometry.active!=='canvas'||!geometry.focus)throw Error('Canvas focus/hit target missing before '+label+' '+JSON.stringify(geometry));
  const action={stage:label,text:row.text,confidence:row.confidence,point,geometry,...stamp()};actions.push(action);
  await page.touchscreen.tap(point.x,point.y);
  await page.evaluate(()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve))));
  action.touch_events=await page.evaluate(i=>window.__studyTouches.slice(i),geometry.touch_index);
  if(!['touchstart','touchend'].every(type=>action.touch_events.some(e=>e.type===type&&e.trusted&&e.target==='canvas')))throw Error('Trusted canvas tap receipt missing for '+label);
  await pause(400);
}
// Exact frame-spaced WebKit GUI-touch path already used by capture-web.mjs.
// This untimed swipe is a DOM TouchEvent and explicitly is not trusted input.
async function swipeDrawer() {
  const action={stage:'swipe_dev',from:{x:180,y:330},to:{x:180,y:230},stationary_hold_ms:250,trusted:false,...stamp()};actions.push(action);
  const before=await page.evaluate(()=>window.__studyTouches.length);
  await page.evaluate(async()=>{
    const canvas=document.getElementById('canvas');
    const frame=()=>new Promise(resolve=>requestAnimationFrame(()=>requestAnimationFrame(resolve)));
    const send=(type,y)=>{
      const ended=type==='touchend';
      const data={identifier:12,target:canvas,clientX:180,clientY:y,pageX:180+scrollX,pageY:y+scrollY,screenX:180,screenY:y,radiusX:3,radiusY:3,rotationAngle:0,force:ended?0:1};
      let touch=data;if(typeof Touch==='function'){try{touch=new Touch(data);}catch{}}
      const active=ended?[]:[touch];let event;
      if(typeof TouchEvent==='function'){try{event=new TouchEvent(type,{bubbles:true,cancelable:true,touches:active,targetTouches:active,changedTouches:[touch]});}catch{}}
      if(!event){const list=items=>Object.defineProperty(items,'item',{value:i=>items[i]??null});event=new Event(type,{bubbles:true,cancelable:true});Object.defineProperties(event,{touches:{value:list([...active])},targetTouches:{value:list([...active])},changedTouches:{value:list([touch])}});}
      canvas.dispatchEvent(event);
    };
    send('touchstart',330);await frame();
    for(let i=1;i<=8;i++){send('touchmove',330-100*i/8);await new Promise(resolve=>setTimeout(resolve,40));}
    // TouchScrollContainer coasts only if the last move is <120 ms before release.
    // Let the engine consume that move, then hold still to use its normal stop path.
    await frame();await new Promise(resolve=>setTimeout(resolve,250));await frame();
    send('touchend',230);await frame();
  });
  action.touch_events=await page.evaluate(i=>window.__studyTouches.slice(i),before);
  if(!action.touch_events.some(e=>e.type==='touchmove'&&!e.trusted&&e.target==='canvas'))throw Error('GUI swipe receipt missing');
  const lastMove=action.touch_events.findLast(e=>e.type==='touchmove'),release=action.touch_events.findLast(e=>e.type==='touchend');
  if(!release||release.time-lastMove.time<200)throw Error('Stationary scroll-release hold missing');
  await pause(350);
}
async function saveReceipt(label) {
  const remote=await page.evaluate(async()=> {
    const db=await new Promise((resolve,reject)=>{
      const r=indexedDB.open('/userfs');
      r.onupgradeneeded=()=>{r.transaction.abort();reject(Error('Persistent userfs DB absent'));};
      r.onerror=()=>reject(Error('Cannot read persistent userfs'));
      r.onsuccess=()=>resolve(r.result);
    });
    try {
      if(!db.objectStoreNames.contains('FILE_DATA'))throw Error('FILE_DATA store missing');
      const tx=db.transaction('FILE_DATA','readonly'),store=tx.objectStore('FILE_DATA');
      const request=r=>new Promise((resolve,reject)=>{r.onsuccess=()=>resolve(r.result);r.onerror=()=>reject(r.error);});
      const [keys,values]=await Promise.all([request(store.getAllKeys()),request(store.getAll())]);
      const rows=keys.map((key,i)=>({key:String(key),value:values[i]})).filter(x=>x.key.endsWith('/ever_deeper_dev_run_v3.sav'));
      if(rows.length!==1)throw Error('Expected one committed DEV save: '+JSON.stringify(keys));
      const {key,value}=rows[0];
      return {key,timestamp:String(value.timestamp),bytes:Array.from(new Uint8Array(value.contents)),visibility:document.visibilityState};
    }finally{db.close();}
  });
  const bytes=Buffer.from(remote.bytes),document=decodeSave(bytes);
  await fs.writeFile(path.join(output,label+'.sav'),bytes);
  const receipt={key:remote.key,timestamp:remote.timestamp,bytes:bytes.length,sha256:hash(bytes),document,...stamp()};
  await write(label+'.json',receipt);return receipt;
}
function checkSurface(s) {
  if(s.css.width!==848||s.css.height!==390||s.canvas.width!==1696||s.canvas.height!==780||s.buffer.width!==1696||s.buffer.height!==780||s.dpr!==2)throw Error('Actual canvas/DPR mismatch '+JSON.stringify(s));
}
async function drawCheck(label) {
  const r=await bounded(page.evaluate(()=>window.__webkitMovingStudy.census()),10000,label);
  checkSurface(r.canvas);
  if(!r.all_restored||!r.rows.every(x=>x.restored)||!r.rows.some(x=>x.draw_calls>0))throw Error('Missing actual/restored draw evidence');
  await write(label+'.json',r);return r;
}
try {
  await fs.mkdir(output,{recursive:true});
  if(process.platform!=='darwin'||process.getuid()===0||process.env.GITHUB_REF!==BRANCH)throw Error('Only authorized ordinary-user Mac study branch may run');
  if(process.env.GITHUB_RUN_ATTEMPT!=='1')throw Error('No automatic second workflow attempt is authorized');
  const request=JSON.parse(await fs.readFile(path.join(here,'REQUEST.json'),'utf8'));
  if(request.sessions!==1||request.source!==SOURCE||request.diagnostic_only!==true||request.probe!=='pre_navigation_full_shader_history_v1'||request.candidate_identity_sha256!==IDENTITY||!request.preparation_sha)throw Error('Missing one-session authorization');
  const {stdout:parent}=await exec('git',['rev-parse','HEAD^']);
  if(parent.trim()!==request.preparation_sha)throw Error('Request is not the reviewed preparation child');
  const {stdout:requestDiff}=await exec('git',['diff-tree','--no-commit-id','--name-status','-r','HEAD']);
  if(requestDiff.trim()!=='A\ttools/warmup_webkit_specialization/REQUEST.json')throw Error('Request child changes more than its new request file');
  const identityBytes=await fs.readFile(path.join(candidate,'artifact-identity.json'));
  if(!/^[a-f0-9]{64}$/.test(IDENTITY||'')||hash(identityBytes)!==IDENTITY)throw Error('Wrong candidate identity');
  const identity=JSON.parse(identityBytes);
  if(identity.sourceSha!==SOURCE||identity.runId!=='35248670186'||Object.keys(identity.devFiles).length!==9)throw Error('Wrong nine-file source');
  const verified={};
  for(const [name,v]of Object.entries(identity.devFiles)) {
    const b=await fs.readFile(path.join(candidate,name));
    if(b.length!==v.size||hash(b)!==v.sha256)throw Error('Wrong candidate file '+name);
    verified[name]={bytes:b.length,sha256:hash(b)};
  }
  result.pck_sha256=verified['index.pck'].sha256;result.unchanged_export=true;
  if(result.pck_sha256!=='44888defe3c4a39751fc5d470faf425951f122ebffd358dac04502157429088b')throw Error('Wrong exact full warmup candidate PCK');
  await write('candidate-verified.json',{identity_sha256:IDENTITY,source:SOURCE,files:verified});
  await fs.copyFile(path.join(candidate,'artifact-identity.json'),path.join(output,'artifact-identity.json'));
  const observer=await fs.readFile(path.join(here,'observer.js'),'utf8');
  const resourceProbe=await fs.readFile(path.join(here,'resources.js'),'utf8');
  if(hash(observer)!=='35db05eed667a6b95ec235d2b0673ea2ddf48cf7ccfa84ef193ed04ba0bf4424')throw Error('Raw observer changed');
  const files=await fs.readdir(here),sourceHashes={};
  for(const name of files)if((await fs.stat(path.join(here,name))).isFile())sourceHashes[name]=hash(await fs.readFile(path.join(here,name)));
  const {stdout:head}=await exec('git',['rev-parse','HEAD']);
  await write('host.json',{source:SOURCE,study_sha:head.trim(),request,source_hashes:sourceHashes,platform:process.platform,arch:process.arch,release:os.release(),uid:process.getuid(),node:process.version,playwright_executable:webkit.executablePath(),launcher_sha256:hash(await fs.readFile(webkit.executablePath())),...stamp()});
  const before=await inventory('process-before-browser');
  const mime={'.html':'text/html; charset=utf-8','.js':'application/javascript','.wasm':'application/wasm','.png':'image/png','.pck':'application/octet-stream'};
  server=http.createServer((req,res)=>{
    const name=new URL(req.url,'http://localhost').pathname.slice(1)||'index.html';
    requests.push({name,...stamp()});
    if(!Object.hasOwn(identity.devFiles,name)){res.writeHead(404);res.end();return;}
    res.writeHead(200,{'Content-Type':mime[path.extname(name)]||'application/octet-stream','Content-Length':identity.devFiles[name].size,'Cache-Control':'no-store','Cross-Origin-Opener-Policy':'same-origin','Cross-Origin-Embedder-Policy':'require-corp'});
    createReadStream(path.join(candidate,name)).pipe(res);
  });
  await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
  browserServer=await webkit.launchServer({headless:true});
  exitPromise=new Promise(resolve=>browserServer.process().once('close',(code,signal)=>{childExit={code,signal,...stamp()};resolve(childExit);}));
  browser=await webkit.connect(browserServer.wsEndpoint());
  result.browser_version=browser.version();result.browser_server_pid=browserServer.process().pid;
  context=await browser.newContext({viewport:{width:848,height:390},deviceScaleFactor:2,isMobile:true,hasTouch:true,
    userAgent:'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/124.0.0.0 Mobile/15E148 Safari/604.1'});
  // One init script fixes ordering: resource getContext wraps observer, which wraps native.
  await context.addInitScript({content:observer+'\n'+resourceProbe});
  page=await context.newPage();page.setDefaultTimeout(15000);
  page.on('framenavigated',frame=>{if(frame===page.mainFrame())navigationUrls.push(frame.url());});
  page.on('console',m=>{const row={type:m.type(),text:m.text(),...stamp()};logs.push(row);if(m.type()==='error'||/SCRIPT ERROR|Parse Error|^ERROR:|Assertion failed|WebGL.*(?:INVALID_|GL_ERROR)/.test(m.text()))errors.push(row);});
  page.on('pageerror',e=>errors.push({page_error:String(e),...stamp()}));
  page.on('crash',()=>errors.push({crash:true,...stamp()}));
  await page.goto('http://127.0.0.1:'+server.address().port+'/index.html',{waitUntil:'domcontentloaded',timeout:60000});
  await page.waitForFunction(()=>window.__webkitMovingStudy?.ready().version==='1.0.0-dev.13'&&window.__webkitMovingStudy.ready().calls>30,null,{timeout:60000});
  checkSurface(await page.evaluate(()=>window.__webkitMovingStudy.surface()));
  await page.bringToFront();
  await page.locator('#canvas').focus();
  await page.locator('#canvas').evaluate(canvas=>{canvas.blur();canvas.focus();});
  await page.evaluate(()=>{
    window.__studyTouches=[];
    for(const type of ['touchstart','touchmove','touchend','touchcancel'])window.addEventListener(type,e=>window.__studyTouches.push({type:e.type,trusted:e.isTrusted,target:e.target.id,time:performance.now(),changed:Array.from(e.changedTouches,t=>({id:t.identifier,x:t.clientX,y:t.clientY}))}),true);
  });
  let rows=await scan('00-start');
  const startReady=await page.evaluate(()=>window.__webkitMovingStudy.ready());
  const newGame=findText(rows,'NEWGAME');
  if(!newGame||!findText(rows,'NOEXPEDITIONFOUND'))throw Error('Fresh ordinary start-menu state not established');
  // PRE_NAVIGATION_RECEIPT_BEGIN: scalar original-recorder state, no GL query.
  const menuBoundary=await page.evaluate(actionCount=>({
    resource:window.__webkitResourceProbe.ready(),observer:window.__webkitMovingStudy.ready(),
    touches:window.__studyTouches,events:window.__webkitMovingStudy.events,
    action_count:actionCount,now_ms:performance.now()
  }),actions.length);
  await write('pre-navigation-boundary.json',menuBoundary);
  validateMenuBoundary(menuBoundary);
  // PRE_NAVIGATION_RECEIPT_END
  await clickLabel(newGame,'start_new_game');
  await pause(5000);
  rows=await scan('00-surface');
  const startModalVisible=items=>items.some(x=>x.confidence>=.6&&['NEWGAME','NOEXPEDITIONFOUND','THEDEPTHSARECALLING','BEGINAFRESHDESCENT'].includes(normal(x.text)));
  if(startModalVisible(rows))throw Error('Start modal labels remain after NEW GAME');
  let toggle=findDevToggle(rows);
  if(!toggle)throw Error('Exact DEV toggle is not established in the surface button bounds');
  await pause(350);
  const surfaceConfirmed=await scan('00-surface-confirm');
  const toggleConfirmed=findDevToggle(surfaceConfirmed);
  if(startModalVisible(surfaceConfirmed)||!toggleConfirmed||Math.abs(toggleConfirmed.x-toggle.x)*848>2||Math.abs(toggleConfirmed.y-toggle.y)*390>2)throw Error('Surface/DEV toggle not stable in second settled original');
  await write('dev-toggle-target.json',{first_image:'00-surface.png',second_image:'00-surface-confirm.png',first:toggle,second:toggleConfirmed,center_css_inset:{left:88,right:130,top:82,bottom:104},maximum_center_delta_css:2,generic_confidence_unchanged:.6,...stamp()});
  toggle=toggleConfirmed;
  const surface=await saveReceipt('save-surface');
  if(surface.document.state.location.scene!=='surface'||surface.document.state.endless_descent.active)throw Error('Ordinary surface save not established');
  const surfaceReady=await page.evaluate(()=>window.__webkitMovingStudy.ready());
  if(surfaceReady.calls<=startReady.calls||surfaceReady.hidden)throw Error('Visible engine loop did not advance during NEW GAME navigation');
  await write('surface-entry.json',{modal_labels_absent:true,dev_toggle_visible:true,scene:surface.document.state.location.scene,start_ready:startReady,surface_ready:surfaceReady,timing_started:false,...stamp()});
  await clickLabel(toggle,'open_dev');
  let target=null;
  for(let i=0;i<8;i++) {
    rows=await scan('01-menu-'+i);
    if(!rows.some(x=>normal(x.text).includes('DEVELOPERTOOLS')&&x.confidence>=.6)||!findText(rows,'CLOSEDEV'))throw Error('DEV drawer/title not visually established; navigation stopped');
    target=findDeepTarget(rows);
    if(target) {
      await pause(350);
      const confirmedRows=await scan('01-menu-'+i+'-confirm');
      if(!confirmedRows.some(x=>normal(x.text).includes('DEVELOPERTOOLS')&&x.confidence>=.6)||!findText(confirmedRows,'CLOSEDEV'))throw Error('DEV drawer changed during target confirmation');
      const confirmed=findDeepTarget(confirmedRows);
      if(!confirmed||Math.abs(confirmed.x-target.x)*848>2||Math.abs(confirmed.y-target.y)*390>2)throw Error('Exact Layer12 target not stable in second settled original');
      await write('deep-target.json',{first_image:'01-menu-'+i+'.png',second_image:'01-menu-'+i+'-confirm.png',first:target,second:confirmed,scroll_css_bounds:{left:83,right:485,top:190,bottom:371},target_css_inset:{left:100,right:264,top:210,bottom:350},maximum_center_delta_css:2,generic_confidence_unchanged:.6,...stamp()});
      target=confirmed;break;
    }
    if(i===7)break;
    await swipeDrawer();
  }
  if(!target)throw Error('Deep 12 label not found in bounded normal menu navigation');
  await clickLabel(target,'jump_deep_12');
  await pause(5000);
  const baseline=await saveReceipt('save-before');
  const b=baseline.document.state;
  if(b.location.scene!=='endless'||!b.endless_descent.active||b.endless_descent.current_depth!==12)throw Error('Persisted Deep-12 entry missing');
  if(b.endless_descent.light_style!=='standard'||b.endless_descent.outfit!=='miner'||b.endless_descent.tool_style!=='original')throw Error('Unexpected baseline loadout');
  await drawCheck('draw-before');
  const entry=await scan('02-deep-entry');
  if(findText(entry,'CLOSEDEV')||!entry.some(x=>normal(x.text).includes('THEDEEP')))throw Error('Actual Deep entry not visually established');
  await pause(4000);
  actions.push({stage:'begin_real_keys',...stamp()});
  await write('resource-ready.json',await page.evaluate(()=>window.__webkitResourceProbe.ready()));
  const clockBefore=await page.evaluate(()=>window.__webkitResourceProbe.clock());
  await page.keyboard.down('ArrowDown');await page.keyboard.down('Space');
  const measurement=await bounded(page.evaluate(async()=>{
    const start=window.__webkitResourceProbe.start();
    const raw=await window.__webkitMovingStudy.begin();
    const stop=window.__webkitResourceProbe.stop();
    const clockAfter=window.__webkitResourceProbe.clock();
    return {start,raw,stop,clockAfter,capture:window.__webkitResourceProbe.capture()};
  }),75000,'60-second engine loop and selected resource calls');
  const {raw,capture,stop,start,clockAfter}=measurement;
  await write('raw-loop.json',raw);await write('resource-capture.json',capture);
  await write('resource-start-stop.json',{start,stop});
  await write('resource-clocks.json',{before:clockBefore,after:clockAfter});
  if(!stop.was_active||stop.dropped||stop.error_mask)throw Error('Resource recorder completion gate failed');
  const resourceAnalysis=analyzeResources(capture,raw,{before:clockBefore,after:clockAfter});
  await write('resource-analysis.json',resourceAnalysis);
  const identityAnalysis=analyzeIdentity(capture);
  await write('shader-identity-analysis.json',identityAnalysis);
  result.shader_identity={shader_count:identityAnalysis.shader_count,program_count:identityAnalysis.program_count,source_count:identityAnalysis.sources.length,metadata_events:identityAnalysis.event_count,timed_program_status:identityAnalysis.timed_program_status,overhead_bearing:true,no_extra_gl_queries:true};
  result.resources={records:capture.count,dropped:capture.dropped,error_mask:capture.error_mask,
    per_method:resourceAnalysis.per_method,window_selected_union_ms:resourceAnalysis.window_selected_union_ms,
    selected_in_callbacks_union_ms:resourceAnalysis.selected_in_callbacks_union_ms,
    outside_selected_calls_ms:resourceAnalysis.outside_selected_calls_ms,hitches:resourceAnalysis.hitches,
    overhead_bearing:true,exclusive_gpu_time:false};
  const summary=summarize(raw);result.timing=summary;await write('loop-summary.json',summary);
  const events=await page.evaluate(()=>window.__webkitMovingStudy.events);
  const starts=events.filter(x=>x.kind==='keydown'&&x.trusted&&['ArrowDown','Space'].includes(x.code));
  if(!starts.some(x=>x.code==='ArrowDown')||!starts.some(x=>x.code==='Space')||!raw.keys_at_end.ArrowDown||!raw.keys_at_end.Space||raw.visibility!=='visible')throw Error('Trusted held input/visibility missing');
  await drawCheck('draw-after');
  result.cpu_sampling={status:'not_part_of_bounded_resource_probe',exclusive_gpu_time_available:false};
  await page.keyboard.up('Space');await page.keyboard.up('ArrowDown');actions.push({stage:'release_real_keys',...stamp()});
  await pause(6000);
  const final=await saveReceipt('save-after'),a=final.document.state;
  const mined=s=>Object.values(s.mined).reduce((total,n)=>total+Math.max(0,n),0);
  const progress={seed_before:b.world_seed,seed_after:a.world_seed,mined_delta:mined(a)-mined(b),swings_delta:a.total_swings-b.total_swings,depth_before:b.endless_descent.current_depth,depth_after:a.endless_descent.current_depth,metres_before:b.endless_descent.deepest_metres,metres_after:a.endless_descent.deepest_metres,anchor_before:b.endless_descent.stream_anchor,anchor_after:a.endless_descent.stream_anchor};
  if(a.world_seed!==b.world_seed||a.location.scene!=='endless'||!a.endless_descent.active||progress.mined_delta<=0||progress.swings_delta<=0||!(progress.depth_after>progress.depth_before||progress.metres_after>progress.metres_before))throw Error('Real mining/descent save proof failed '+JSON.stringify(progress));
  result.progress=progress;
  await scan('03-deep-final');
  result.resource_restoration=await page.evaluate(()=>window.__webkitResourceProbe.restore());
  if(!result.resource_restoration.all_methods_restored||!result.resource_restoration.descriptors_restored||
     !result.resource_restoration.get_context_restored_to_observer||result.resource_restoration.method_count!==9||result.resource_restoration.error_mask)throw Error('Resource method restoration failed');
  result.observer=await page.evaluate(()=>({ready:window.__webkitMovingStudy.ready(),events:window.__webkitMovingStudy.events,restoration:window.__webkitMovingStudy.restore()}));
  if(!result.observer.restoration.raf_restored||!result.observer.restoration.get_context_restored)throw Error('Raw observer restoration failed');
  if(result.observer.ready.keys.Space||result.observer.ready.keys.ArrowDown)throw Error('Input release events missing');
  const during=result.observer.events.filter(x=>x.time>=raw.started&&x.time<=raw.finished&&['blur','hidden','pagehide','resize','contextlost','engine_callback_changed'].includes(x.kind));
  if(during.length||errors.length)throw Error('Runtime/visibility/GL gate failed '+JSON.stringify({during,errors}));
  result.pre_navigation_shader_history=classifyPreNavigation(capture,menuBoundary,{
    events:result.observer.events,observer:result.observer.ready,
    resource_restoration:result.resource_restoration,observer_restoration:result.observer.restoration,
    navigation_urls:navigationUrls,expected_url:'http://127.0.0.1:'+server.address().port+'/index.html'
  });
  await write('pre-navigation-shader-history.json',result.pre_navigation_shader_history);
  result.functional=true;
}catch(e) {
  result.error=String(e.stack||e);process.exitCode=1;
  if(page) {
    await bounded(page.keyboard.up('Space').catch(()=>{}),2000,'release Space').catch(()=>{});
    await bounded(page.keyboard.up('ArrowDown').catch(()=>{}),2000,'release Down').catch(()=>{});
    await bounded(page.evaluate(()=>({partial:window.__webkitMovingStudy?.partial(),ready:window.__webkitMovingStudy?.ready(),events:window.__webkitMovingStudy?.events})).then(x=>write('failure-observer.json',x)),3000,'failure receipt').catch(()=>{});
    await bounded(page.evaluate(()=>{const p=window.__webkitResourceProbe;if(!p)return null;const stop=p.stop(),capture=p.capture(),restoration=p.restore();return {stop,capture,restoration};}).then(x=>write('failure-resources.json',x)),3000,'failure resource receipt').catch(()=>{});
    await bounded(page.screenshot({path:path.join(output,'failure.png'),timeout:5000}),6000,'failure capture').catch(()=>{});
  }
}finally {
  if(browser)await bounded(browser.close(),10000,'browser close').catch(e=>{result.cleanup_error=String(e);process.exitCode=1;});
  if(browserServer)await bounded(browserServer.close(),10000,'server close').catch(e=>{result.cleanup_error=String(e);process.exitCode=1;});
  if(exitPromise)await bounded(exitPromise,3000,'browser process exit').catch(e=>{result.cleanup_error=String(e);process.exitCode=1;});
  if(server)await new Promise(resolve=>server.close(resolve));
  result.browser_exit=childExit;
  if(result.functional && (!childExit||childExit.code!==0||childExit.signal||result.cleanup_error)){result.error='Browser exit/cleanup gate failed';process.exitCode=1;}
  result.finished=stamp();result.complete=!!result.functional&&!result.error;
  await write('navigation-urls.json',navigationUrls);
  await write('console.json',{logs,errors});await write('actions.json',actions);await write('http-requests.json',requests);
  await inventory('process-after-browser').catch(e=>{result.process_inventory_error=String(e);});
  await write('result.json',result);
  const manifest={};
  for(const name of await fs.readdir(output))if(name!=='runner.log'&&(await fs.stat(path.join(output,name))).isFile()){const b=await fs.readFile(path.join(output,name));manifest[name]={size:b.length,sha256:hash(b)};}
  await write('file-manifest.json',manifest);
  console.log((result.complete?'WARMUP_PRE_NAVIGATION_IDENTITY_COMPLETE':'WARMUP_PRE_NAVIGATION_IDENTITY_FAILED')+' '+JSON.stringify({source:SOURCE,pck:result.pck_sha256,complete:result.complete,metric:result.metric,error:result.error||null}));
}
