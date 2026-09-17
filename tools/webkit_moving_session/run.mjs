import { webkit } from '@playwright/test';
import { promises as fs, createReadStream, openSync, closeSync } from 'node:fs';
import { spawn, execFile } from 'node:child_process';
import { promisify } from 'node:util';
import { fileURLToPath } from 'node:url';
import http from 'node:http';
import path from 'node:path';
import os from 'node:os';
import { hash, decodeSave, summarize } from './codec.mjs';
const exec=promisify(execFile), here=path.dirname(fileURLToPath(import.meta.url));
const SOURCE='8f5680defb9083bbe1e044d39a10612f2186e7f3';
const BRANCH='refs/heads/codex/dev11-webkit-moving-study-20260917';
const IDENTITY='027b128fe5fa70d7814c0f0952ee06549f447afc9769426c3b5696c631579a7a';
const candidate=path.resolve(process.argv[2]||''), output=path.resolve(process.argv[3]||'');
const ocr=process.argv[4];
const write=async(name,value)=>{const p=path.join(output,name);await fs.writeFile(p+'.tmp',JSON.stringify(value,null,2)+'\n');await fs.rename(p+'.tmp',p);};
const stamp=()=>({utc:new Date().toISOString(),monotonic_ms:performance.now()});
const bounded=async(p,ms,label)=>{let timer;try{return await Promise.race([p,new Promise((_,reject)=>{timer=setTimeout(()=>reject(Error(label+' timed out')),ms);})]);}finally{clearTimeout(timer);}};
const pause=ms=>new Promise(resolve=>setTimeout(resolve,ms));
const logs=[],errors=[],actions=[],requests=[];
let server,browserServer,browser,page,context,exitPromise,childExit=null;
const result={schema:1,source:SOURCE,pck_sha256:'5b77b3a219011cb676895e41830c8dab32bec2346db93102c7894a3c084414e9',metric:'engine_loop_callback_cadence',rendered_fps_verified:false,physical_iphone:false,started:stamp(),complete:false};
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
  const action={stage:'swipe_dev',from:{x:180,y:330},to:{x:180,y:185},trusted:false,...stamp()};actions.push(action);
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
    for(let i=1;i<=8;i++){send('touchmove',330-145*i/8);await new Promise(resolve=>setTimeout(resolve,25));}
    send('touchend',185);await frame();
  });
  action.touch_events=await page.evaluate(i=>window.__studyTouches.slice(i),before);
  if(!action.touch_events.some(e=>e.type==='touchmove'&&!e.trusted&&e.target==='canvas'))throw Error('GUI swipe receipt missing');
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
async function sampleOwned(before) {
  const report={attempted:[],status:'not_started',exclusive_gpu_time_available:false,started:stamp()};
  const deadline=performance.now()+30000;
  try {
    const usage=await exec('/usr/bin/sample',[],{timeout:5000}).catch(e=>({stdout:e.stdout||'',stderr:e.stderr||'',code:e.code}));
    await fs.writeFile(path.join(output,'sample-usage.txt'),String(usage.stdout)+String(usage.stderr||''));
    if(!/duration/i.test(usage.stdout+usage.stderr)||!/interval/i.test(usage.stdout+usage.stderr))throw Error('Ordinary sample CLI unavailable');
    const current=await inventory('process-before-sampling'),old=new Set(before.map(x=>x.pid));
    const bundle=path.dirname(webkit.executablePath());
    const selected=[];
    for(const [role,re]of [['webcontent',/WebContent/],['gpu',/(?:WebKit|webkit).*GPU/]]) {
      const candidates=current.filter(x=>!old.has(x.pid)&&x.uid===process.getuid()&&re.test(x.command));
      const owned=[];
      for(const item of candidates) {
        const {stdout}=await exec('/usr/sbin/lsof',['-p',String(item.pid),'-Fn'],{timeout:3000,maxBuffer:5*1024*1024});
        await fs.writeFile(path.join(output,'process-'+item.pid+'-files.txt'),stdout);
        if(stdout.split('\n').some(s=>s.startsWith('n'+bundle+'/')))owned.push(item);
      }
      if(owned.length!==1)throw Error('Ambiguous or unavailable owned '+role+' PID: '+owned.length);
      selected.push({role,...owned[0]});
    }
    await write('sample-owned-processes.json',{bundle,selected,browser_server_pid:browserServer.process().pid});
    for(const item of selected) {
      if(deadline-performance.now()<10000)throw Error('Sampling extension budget exhausted');
      const target=path.join(output,'sample-'+item.role+'.txt');
      const fd=openSync(path.join(output,'sample-'+item.role+'-overhead.log'),'w');
      const row={...item,command:['/usr/bin/time','-l','/usr/bin/sample',String(item.pid),'5','5','-file',target],start:stamp()};
      report.attempted.push(row);
      try {
        row.exit=await new Promise((resolve,reject)=>{
          const child=spawn(row.command[0],row.command.slice(1),{stdio:['ignore',fd,fd],detached:true});
          const timer=setTimeout(()=>{try{process.kill(-child.pid,'SIGKILL');}catch{};row.timeout=true;},Math.min(10000,deadline-performance.now()));
          child.once('error',e=>{clearTimeout(timer);reject(e);});
          child.once('close',(code,signal)=>{clearTimeout(timer);row.signal=signal;resolve(code);});
        });
      }finally{closeSync(fd);row.end=stamp();}
      if(row.exit!==0||row.timeout)throw Error('Ordinary sample failed for '+item.role);
      const text=await fs.readFile(target,'utf8');
      if(!new RegExp('^Process:.*\\['+item.pid+'\\]\\s*$','m').test(text)||!text.includes('Call graph:')||!text.includes('Binary Images:'))throw Error('Sample PID/completeness mismatch');
      row.sha256=hash(text);
    }
    report.status='complete';
  }catch(e){report.status='unavailable_or_failed';report.reason=String(e.stack||e);}
  report.finished=stamp();await write('cpu-sampling.json',report);
  return report;
}
try {
  await fs.mkdir(output,{recursive:true});
  if(process.platform!=='darwin'||process.getuid()===0||process.env.GITHUB_REF!==BRANCH)throw Error('Only authorized ordinary-user Mac study branch may run');
  const request=JSON.parse(await fs.readFile(path.join(here,'REQUEST.json'),'utf8'));
  if(request.sessions!==1||request.source!==SOURCE||!request.preparation_sha)throw Error('Missing one-session authorization');
  const {stdout:parent}=await exec('git',['rev-parse','HEAD^']);
  if(parent.trim()!==request.preparation_sha)throw Error('Request is not the reviewed preparation child');
  const identityBytes=await fs.readFile(path.join(candidate,'artifact-identity.json'));
  if(hash(identityBytes)!==IDENTITY)throw Error('Wrong candidate identity');
  const identity=JSON.parse(identityBytes);
  if(identity.sourceSha!==SOURCE||Object.keys(identity.devFiles).length!==9)throw Error('Wrong nine-file source');
  const verified={};
  for(const [name,v]of Object.entries(identity.devFiles)) {
    const b=await fs.readFile(path.join(candidate,name));
    if(b.length!==v.size||hash(b)!==v.sha256)throw Error('Wrong candidate file '+name);
    verified[name]={bytes:b.length,sha256:hash(b)};
  }
  await write('candidate-verified.json',{identity_sha256:IDENTITY,source:SOURCE,files:verified});
  await fs.copyFile(path.join(candidate,'artifact-identity.json'),path.join(output,'artifact-identity.json'));
  const observer=await fs.readFile(path.join(here,'observer.js'),'utf8');
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
  await context.addInitScript({content:observer});
  page=await context.newPage();page.setDefaultTimeout(15000);
  page.on('console',m=>{const row={type:m.type(),text:m.text(),...stamp()};logs.push(row);if(m.type()==='error'||/SCRIPT ERROR|Parse Error|^ERROR:|Assertion failed|WebGL.*(?:INVALID_|GL_ERROR)/.test(m.text()))errors.push(row);});
  page.on('pageerror',e=>errors.push({page_error:String(e),...stamp()}));
  page.on('crash',()=>errors.push({crash:true,...stamp()}));
  await page.goto('http://127.0.0.1:'+server.address().port+'/index.html',{waitUntil:'domcontentloaded',timeout:60000});
  await page.waitForFunction(()=>window.__webkitMovingStudy?.ready().version==='1.0.0-dev.11'&&window.__webkitMovingStudy.ready().calls>30,null,{timeout:60000});
  checkSurface(await page.evaluate(()=>window.__webkitMovingStudy.surface()));
  await page.bringToFront();
  await page.locator('#canvas').focus();
  await page.locator('#canvas').evaluate(canvas=>{canvas.blur();canvas.focus();});
  await page.evaluate(()=>{
    window.__studyTouches=[];
    for(const type of ['touchstart','touchmove','touchend','touchcancel'])window.addEventListener(type,e=>window.__studyTouches.push({type:e.type,trusted:e.isTrusted,target:e.target.id,time:performance.now(),changed:Array.from(e.changedTouches,t=>({id:t.identifier,x:t.clientX,y:t.clientY}))}),true);
  });
  let rows=await scan('00-start');
  const toggle=findText(rows,'DEVTOOLS');if(!toggle)throw Error('DEV TOOLS label not found');
  await clickLabel(toggle,'open_dev');
  let target=null;
  for(let i=0;i<8;i++) {
    rows=await scan('01-menu-'+i);
    if(!rows.some(x=>normal(x.text).includes('DEVELOPERTOOLS')&&x.confidence>=.6)||!findText(rows,'CLOSEDEV'))throw Error('DEV drawer/title not visually established; navigation stopped');
    target=findText(rows,'ENDLESSLAYER12');
    if(target)break;
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
  await page.keyboard.down('ArrowDown');await page.keyboard.down('Space');
  const raw=await bounded(page.evaluate(()=>window.__webkitMovingStudy.begin()),75000,'60-second engine loop');
  await write('raw-loop.json',raw);
  const summary=summarize(raw);result.timing=summary;await write('loop-summary.json',summary);
  const events=await page.evaluate(()=>window.__webkitMovingStudy.events);
  const starts=events.filter(x=>x.kind==='keydown'&&x.trusted&&['ArrowDown','Space'].includes(x.code));
  if(!starts.some(x=>x.code==='ArrowDown')||!starts.some(x=>x.code==='Space')||!raw.keys_at_end.ArrowDown||!raw.keys_at_end.Space||raw.visibility!=='visible')throw Error('Trusted held input/visibility missing');
  await drawCheck('draw-after');
  if(!summary.meets_callback_budget)result.cpu_sampling=await sampleOwned(before);
  else result.cpu_sampling={status:'not_needed_callback_budget_passed',exclusive_gpu_time_available:false};
  await page.keyboard.up('Space');await page.keyboard.up('ArrowDown');actions.push({stage:'release_real_keys',...stamp()});
  await pause(6000);
  const final=await saveReceipt('save-after'),a=final.document.state;
  const mined=s=>Object.values(s.mined).reduce((total,n)=>total+Math.max(0,n),0);
  const progress={seed_before:b.world_seed,seed_after:a.world_seed,mined_delta:mined(a)-mined(b),swings_delta:a.total_swings-b.total_swings,depth_before:b.endless_descent.current_depth,depth_after:a.endless_descent.current_depth,metres_before:b.endless_descent.deepest_metres,metres_after:a.endless_descent.deepest_metres,anchor_before:b.endless_descent.stream_anchor,anchor_after:a.endless_descent.stream_anchor};
  if(a.world_seed!==b.world_seed||a.location.scene!=='endless'||!a.endless_descent.active||progress.mined_delta<=0||progress.swings_delta<=0||!(progress.depth_after>progress.depth_before||progress.metres_after>progress.metres_before))throw Error('Real mining/descent save proof failed '+JSON.stringify(progress));
  result.progress=progress;
  await scan('03-deep-final');
  result.observer=await page.evaluate(()=>({ready:window.__webkitMovingStudy.ready(),events:window.__webkitMovingStudy.events,restoration:window.__webkitMovingStudy.restore()}));
  if(result.observer.ready.keys.Space||result.observer.ready.keys.ArrowDown)throw Error('Input release events missing');
  const during=result.observer.events.filter(x=>x.time>=raw.started&&x.time<=raw.finished&&['blur','hidden','pagehide','resize','contextlost','engine_callback_changed'].includes(x.kind));
  if(during.length||errors.length)throw Error('Runtime/visibility/GL gate failed '+JSON.stringify({during,errors}));
  result.functional=true;
}catch(e) {
  result.error=String(e.stack||e);process.exitCode=1;
  if(page) {
    await bounded(page.keyboard.up('Space').catch(()=>{}),2000,'release Space').catch(()=>{});
    await bounded(page.keyboard.up('ArrowDown').catch(()=>{}),2000,'release Down').catch(()=>{});
    await bounded(page.evaluate(()=>({partial:window.__webkitMovingStudy?.partial(),ready:window.__webkitMovingStudy?.ready(),events:window.__webkitMovingStudy?.events})).then(x=>write('failure-observer.json',x)),3000,'failure receipt').catch(()=>{});
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
  await write('console.json',{logs,errors});await write('actions.json',actions);await write('http-requests.json',requests);
  await inventory('process-after-browser').catch(e=>{result.process_inventory_error=String(e);});
  await write('result.json',result);
  const manifest={};
  for(const name of await fs.readdir(output))if(name!=='runner.log'&&(await fs.stat(path.join(output,name))).isFile()){const b=await fs.readFile(path.join(output,name));manifest[name]={size:b.length,sha256:hash(b)};}
  await write('file-manifest.json',manifest);
  console.log((result.complete?'WEBKIT_MOVING_SESSION_COMPLETE':'WEBKIT_MOVING_SESSION_FAILED')+' '+JSON.stringify({source:SOURCE,pck:result.pck_sha256,complete:result.complete,metric:result.metric,error:result.error||null}));
}
